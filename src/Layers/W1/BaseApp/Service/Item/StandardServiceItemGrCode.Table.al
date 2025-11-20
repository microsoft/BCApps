// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Service.Document;

table 5998 "Standard Service Item Gr. Code"
{
    Caption = 'Standard Service Item Gr. Code';
    DataCaptionFields = "Service Item Group Code";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Service Item Group Code"; Code[10])
        {
            Caption = 'Service Item Group Code';
            TableRelation = "Service Item Group";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = "Standard Service Code";
        }
        field(3; Description; Text[100])
        {
            CalcFormula = lookup("Standard Service Code".Description where(Code = field(Code)));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Service Item Group Code", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;
    end;

    var
        StdServCode: Record "Standard Service Code";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 of the standard service code must be equal to %2 on the %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure InsertServiceLines(ServItemLine: Record "Service Item Line")
    var
        Currency: Record Currency;
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        StdServLine: Record "Standard Service Line";
        StdServItemGrCode: Record "Standard Service Item Gr. Code";
        StdServItemGrCodesForm: Page "Standard Serv. Item Gr. Codes";
        Factor: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertServiceLines(ServItemLine, IsHandled);
        if IsHandled then
            exit;

        ServItemLine.TestField("Line No.");

        Clear(StdServItemGrCodesForm);
        StdServItemGrCode.Reset();
        if ServItemLine."Service Item Group Code" <> '' then
            StdServItemGrCode.SetRange("Service Item Group Code", ServItemLine."Service Item Group Code");
        StdServItemGrCodesForm.SetRecord(StdServItemGrCode);
        StdServItemGrCodesForm.SetTableView(StdServItemGrCode);
        StdServItemGrCodesForm.LookupMode := true;

        if not (StdServItemGrCodesForm.RunModal() = ACTION::LookupOK) then
            exit;
        StdServItemGrCodesForm.GetRecord(StdServItemGrCode);
        StdServItemGrCode.TestField(Code);
        StdServCode.Get(StdServItemGrCode.Code);

        StdServCode.TestField(Code);
        ServHeader.Get(ServItemLine."Document Type", ServItemLine."Document No.");
        if StdServCode."Currency Code" <> ServHeader."Currency Code" then
            Error(
              Text001,
              StdServCode.FieldCaption("Currency Code"),
              ServHeader.FieldCaption("Currency Code"), ServHeader.TableCaption());
        StdServLine.SetRange("Standard Service Code", StdServCode.Code);
        Currency.Initialize(StdServCode."Currency Code");
        ServLine."Document Type" := ServItemLine."Document Type";
        ServLine."Document No." := ServItemLine."Document No.";
        ServLine.SetRange("Document Type", ServItemLine."Document Type");
        ServLine.SetRange("Document No.", ServItemLine."Document No.");
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
                if ServHeader."Link Service to Service Item" then
                    ServLine.Validate("Service Item Line No.", ServItemLine."Line No.");
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
                        IsHandled := false;
                        OnInsertServiceLinesOnBeforeSetDescriptionForLineWithTypeInLoop(ServLine, StdServLine, IsHandled);
                        if not IsHandled then
                            ServLine.Description := StdServLine.Description;
                        if StdServLine.Type = StdServLine.Type::"G/L Account" then
                            ServLine.Validate(
                              "Unit Price",
                              Round(StdServLine."Amount Excl. VAT" *
                                (ServLine."VAT %" / 100 * Factor + 1), Currency."Unit-Amount Rounding Precision"));
                        OnInsertServiceLinesOnAfterCalcUnitPrice(ServLine, StdServLine);
                    end;

                ServLine."Shortcut Dimension 1 Code" := StdServLine."Shortcut Dimension 1 Code";
                ServLine."Shortcut Dimension 2 Code" := StdServLine."Shortcut Dimension 2 Code";

                CombineDimensions(ServLine, StdServLine);

                if StdServLine.InsertLine() then begin
                    ServLine."Line No." := ServLine.GetLineNo();
                    OnBeforeInsertServLine(ServLine);
                    ServLine.Insert(true);

                    if ServLine.Type = ServLine.Type::Item then
                        if ServLine.Reserve = ServLine.Reserve::Always then
                            ServLine.AutoReserve(false);

                    InsertExtendedText(ServLine);
                end;
            until StdServLine.Next() = 0;
    end;

    procedure InsertExtendedText(ServLine: Record "Service Line")
    var
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
    begin
        if ServiceTransferExtText.ServCheckIfAnyExtText(ServLine, false) then
            ServiceTransferExtText.InsertServExtText(ServLine);
    end;

    local procedure CombineDimensions(var ServLine: Record "Service Line"; StdServLine: Record "Standard Service Line")
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        DimensionSetIDArr[1] := ServLine."Dimension Set ID";
        DimensionSetIDArr[2] := StdServLine."Dimension Set ID";

        ServLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, ServLine."Shortcut Dimension 1 Code", ServLine."Shortcut Dimension 2 Code");

        OnAfterCombineDimensions(ServLine, StdServLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCombineDimensions(var ServLine: Record "Service Line"; StdServLine: Record "Standard Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServLine(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var StandardServiceItemGrCode: Record "Standard Service Item Gr. Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertServiceLines(ServItemLine: Record "Service Item Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServiceLinesOnAfterCalcUnitPrice(var ServiceLine: Record "Service Line"; var StdServLine: Record "Standard Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServiceLinesOnBeforeSetDescriptionForLineWithTypeInLoop(var ServiceLine: Record "Service Line"; StandardServiceLine: Record "Standard Service Line"; var IsHandled: Boolean)
    begin
    end;
}

