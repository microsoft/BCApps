// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Service.Item;
using System.Utilities;

table 5996 "Standard Service Code"
{
    Caption = 'Standard Service Code';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Standard Service Codes";
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
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if not Currency.Get("Currency Code") then
                    Currency.InitRoundingPrecision();
                if not Currency2.Get(xRec."Currency Code") then
                    Currency2.InitRoundingPrecision();

                if Currency."Amount Rounding Precision" <> Currency2."Amount Rounding Precision" then begin
                    StdServiceLine.Reset();
                    StdServiceLine.SetRange("Standard Service Code", Code);
                    StdServiceLine.SetRange(Type, StdServiceLine.Type::"G/L Account");
                    StdServiceLine.SetFilter("Amount Excl. VAT", '<>%1', 0);
                    if StdServiceLine.Find('-') then begin
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text001, FieldCaption("Currency Code"), StdServiceLine.FieldCaption("Amount Excl. VAT"),
                               FieldCaption("Currency Code")), true)
                        then
                            Error(Text002);
                        repeat
                            StdServiceLine."Amount Excl. VAT" :=
                              Round(StdServiceLine."Amount Excl. VAT", Currency."Amount Rounding Precision");
                            StdServiceLine.Modify();
                        until StdServiceLine.Next() = 0;
                    end;
                end;
                Modify();
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
    begin
        StdServiceLine.Reset();
        StdServiceLine.SetRange("Standard Service Code", Code);
        StdServiceLine.DeleteAll(true);

        StdServItemGroup.Reset();
        StdServItemGroup.SetRange(Code, Code);
        StdServItemGroup.DeleteAll();
    end;

    trigger OnInsert()
    begin
        if not StdServItemGroup.Get('', Code) then begin
            StdServItemGroup.Init();
            StdServItemGroup.Code := Code;
            StdServItemGroup.Insert();
        end;
    end;

    var
        StdServItemGroup: Record "Standard Service Item Gr. Code";
        StdServiceLine: Record "Standard Service Line";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'If you change the %1, the %2 will be rounded according to the new %3.';
#pragma warning restore AA0470
        Text002: Label 'The update has been interrupted to respect the warning.';
#pragma warning disable AA0470
        Text003: Label '%1 of the standard service code must be equal to %2 on the %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure InsertServiceLines(ServiceHeader: Record "Service Header")
    var
        Currency: Record Currency;
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        StdServCode: Record "Standard Service Code";
        StdServLine: Record "Standard Service Line";
        StdServItemGrCode: Record "Standard Service Item Gr. Code";
        StdServItemGrCodesForm: Page "Standard Serv. Item Gr. Codes";
        Factor: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertServiceLines(ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        ServiceHeader.TestField("No.");
        ServiceHeader.TestField("Document Type");

        Clear(StdServItemGrCodesForm);
        StdServItemGrCode.Reset();
        StdServItemGrCodesForm.SetRecord(StdServItemGrCode);
        StdServItemGrCodesForm.SetTableView(StdServItemGrCode);
        StdServItemGrCodesForm.LookupMode := true;

        if not (StdServItemGrCodesForm.RunModal() = ACTION::LookupOK) then
            exit;
        StdServItemGrCodesForm.GetRecord(StdServItemGrCode);

        if StdServCode.Get(StdServItemGrCode.Code) then begin
            StdServCode.TestField(Code);
            if StdServCode."Currency Code" <> ServiceHeader."Currency Code" then
                Error(
                  Text003,
                  StdServCode.FieldCaption("Currency Code"),
                  ServiceHeader.FieldCaption("Currency Code"), ServiceHeader.TableCaption());
            StdServLine.SetRange("Standard Service Code", StdServCode.Code);
            Currency.Initialize(StdServCode."Currency Code");
            ServLine."Document Type" := ServiceHeader."Document Type";
            ServLine."Document No." := ServiceHeader."No.";
            ServLine.SetRange("Document Type", ServiceHeader."Document Type");
            ServLine.SetRange("Document No.", ServiceHeader."No.");
            if ServHeader."Prices Including VAT" then
                Factor := 1
            else
                Factor := 0;
            ServLine.LockTable();
            StdServLine.LockTable();
            if StdServLine.Find('-') then
                repeat
                    ServLine.Init();
                    ServLine."Line No." := 0;
                    ServLine.Validate(Type, StdServLine.Type);
                    if StdServLine.Type = StdServLine.Type::" " then begin
                        ServLine.Validate("No.", StdServLine."No.");
                        ServLine.Description := StdServLine.Description
                    end else
                        if not StdServLine.EmptyLine() then begin
                            StdServLine.TestField("No.");
                            ServLine.Validate("No.", StdServLine."No.");
                            if StdServLine."Variant Code" <> '' then
                                ServLine.Validate("Variant Code", StdServLine."Variant Code");
                            ServLine.Validate(Quantity, StdServLine.Quantity);
                            if StdServLine."Unit of Measure Code" <> '' then
                                ServLine.Validate("Unit of Measure Code", StdServLine."Unit of Measure Code");
                            ServLine.Description := StdServLine.Description;
                            if StdServLine.Type = StdServLine.Type::"G/L Account" then
                                ServLine.Validate(
                                  "Unit Price",
                                  Round(
                                    StdServLine."Amount Excl. VAT" *
                                    (ServLine."VAT %" / 100 * Factor + 1), Currency."Unit-Amount Rounding Precision"));
                        end;
                    ServLine."Dimension Set ID" := StdServLine."Dimension Set ID";
                    if StdServLine.InsertLine() then begin
                        ServLine."Line No." := ServLine.GetLineNo();
                        OnBeforeInsertServLine(ServLine);
                        ServLine.Insert(true);
                        InsertExtendedText(ServLine);
                    end;
                until StdServLine.Next() = 0;
        end;
    end;

    procedure InsertExtendedText(ServLine: Record "Service Line")
    var
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
    begin
        if ServiceTransferExtText.ServCheckIfAnyExtText(ServLine, false) then
            ServiceTransferExtText.InsertServExtText(ServLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServLine(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServiceLines(ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
}

