// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using System.Utilities;

table 170 "Standard Sales Code"
{
    Caption = 'Standard Sales Code';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Standard Sales Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;

            trigger OnValidate()
            var
                Currency: Record Currency;
                Currency2: Record Currency;
                StandardCustomerSalesCode: Record "Standard Customer Sales Code";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if not Currency.Get("Currency Code") then
                    Currency.InitRoundingPrecision();
                if not Currency2.Get(xRec."Currency Code") then
                    Currency2.InitRoundingPrecision();

                if Currency."Amount Rounding Precision" <> Currency2."Amount Rounding Precision" then begin
                    StdSalesLine.Reset();
                    StdSalesLine.SetRange("Standard Sales Code", Code);
                    StdSalesLine.SetRange(Type, StdSalesLine.Type::"G/L Account");
                    StdSalesLine.SetFilter("Amount Excl. VAT", '<>%1', 0);
                    if StdSalesLine.Find('-') then begin
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text001, FieldCaption("Currency Code"), StdSalesLine.FieldCaption("Amount Excl. VAT"),
                               FieldCaption("Currency Code")), true)
                        then
                            Error(Text002);
                        repeat
                            StdSalesLine."Amount Excl. VAT" :=
                              Round(StdSalesLine."Amount Excl. VAT", Currency."Amount Rounding Precision");
                            StdSalesLine.Modify();
                        until StdSalesLine.Next() = 0;
                    end;
                end;

                StandardCustomerSalesCode.SetRange(Code, Code);
                StandardCustomerSalesCode.ModifyAll("Currency Code", "Currency Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        StdCustomerSalesCode.Reset();
        StdCustomerSalesCode.SetRange(Code, Code);
        if not StdCustomerSalesCode.IsEmpty() then
            if not ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(StdSalesCodeDeletionQst, rec.Code, StdCustomerSalesCode.TableCaption()), true) then
                Error('');

        StdSalesLine.Reset();
        StdSalesLine.SetRange("Standard Sales Code", Code);
        StdSalesLine.DeleteAll(true);

        StdCustomerSalesCode.DeleteAll(true);
    end;

    var
        StdSalesLine: Record "Standard Sales Line";
        StdCustomerSalesCode: Record "Standard Customer Sales Code";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'If you change the %1, the %2 will be rounded according to the new %3.';
#pragma warning restore AA0470
        Text002: Label 'The update has been interrupted to respect the warning.';
#pragma warning restore AA0074
        StdSalesCodeDeletionQst: Label 'If you delete the code %1, the related records in the %2 table will also be deleted. Do you want to continue?', Comment = '%1=Standard Sales Code, %2=Table Caption';
}

