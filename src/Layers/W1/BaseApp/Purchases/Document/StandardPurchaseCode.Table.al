// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.Currency;
using System.Utilities;

table 173 "Standard Purchase Code"
{
    Caption = 'Standard Purchase Code';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Standard Purchase Codes";
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
                StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if not Currency.Get("Currency Code") then
                    Currency.InitRoundingPrecision();
                if not Currency2.Get(xRec."Currency Code") then
                    Currency2.InitRoundingPrecision();

                if Currency."Amount Rounding Precision" <> Currency2."Amount Rounding Precision" then begin
                    StdPurchLine.Reset();
                    StdPurchLine.SetRange("Standard Purchase Code", Code);
                    StdPurchLine.SetRange(Type, StdPurchLine.Type::"G/L Account");
                    StdPurchLine.SetFilter("Amount Excl. VAT", '<>%1', 0);
                    if StdPurchLine.Find('-') then begin
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text001, FieldCaption("Currency Code"), StdPurchLine.FieldCaption("Amount Excl. VAT"),
                               FieldCaption("Currency Code")), true)
                        then
                            Error(Text002);
                        repeat
                            StdPurchLine."Amount Excl. VAT" :=
                              Round(StdPurchLine."Amount Excl. VAT", Currency."Amount Rounding Precision");
                            StdPurchLine.Modify();
                        until StdPurchLine.Next() = 0;
                    end;
                end;

                StandardVendorPurchaseCode.SetRange(Code, Code);
                StandardVendorPurchaseCode.ModifyAll("Currency Code", "Currency Code");
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
        StdVendorPurchCode.Reset();
        StdVendorPurchCode.SetRange(Code, Code);
        if not StdVendorPurchCode.IsEmpty() then
            if not ConfirmManagement.GetResponseOrDefault(
                StrSubstNo(StdPurchCodeDeletionQst, rec.Code, StdVendorPurchCode.TableCaption()), true) then
                Error('');
        StdPurchLine.Reset();
        StdPurchLine.SetRange("Standard Purchase Code", Code);
        StdPurchLine.DeleteAll(true);

        StdVendorPurchCode.DeleteAll(true);
    end;

    var
        StdPurchLine: Record "Standard Purchase Line";
        StdVendorPurchCode: Record "Standard Vendor Purchase Code";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'If you change the %1, the %2 will be rounded according to the new %3.';
#pragma warning restore AA0470
        Text002: Label 'The update has been interrupted to respect the warning.';
#pragma warning restore AA0074
        StdPurchCodeDeletionQst: Label 'If you delete the code %1, the related records in the %2 table will also be deleted. Do you want to continue?', Comment = '%1=Standard Purchase Code, %3=Table Caption';
}

