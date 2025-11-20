// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Purchases.Vendor;

table 175 "Standard Vendor Purchase Code"
{
    Caption = 'Standard Vendor Purchase Code';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = "Standard Purchase Code";

            trigger OnValidate()
            var
                StdPurchCode: Record "Standard Purchase Code";
            begin
                if Code = '' then
                    exit;
                StdPurchCode.Get(Code);
                Description := StdPurchCode.Description;
                "Currency Code" := StdPurchCode."Currency Code";
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(15; "Insert Rec. Lines On Quotes"; Option)
        {
            Caption = 'Insert Rec. Lines On Quotes';
            DataClassification = SystemMetadata;
            OptionCaption = 'Manual,Automatic,Always Ask';
            OptionMembers = Manual,Automatic,"Always Ask";
        }
        field(16; "Insert Rec. Lines On Orders"; Option)
        {
            Caption = 'Insert Rec. Lines On Orders';
            DataClassification = SystemMetadata;
            OptionCaption = 'Manual,Automatic,Always Ask';
            OptionMembers = Manual,Automatic,"Always Ask";
        }
        field(17; "Insert Rec. Lines On Invoices"; Option)
        {
            Caption = 'Insert Rec. Lines On Invoices';
            DataClassification = SystemMetadata;
            OptionCaption = 'Manual,Automatic,Always Ask';
            OptionMembers = Manual,Automatic,"Always Ask";
        }
        field(18; "Insert Rec. Lines On Cr. Memos"; Option)
        {
            Caption = 'Insert Rec. Lines On Cr. Memos';
            DataClassification = SystemMetadata;
            OptionCaption = 'Manual,Automatic,Always Ask';
            OptionMembers = Manual,Automatic,"Always Ask";
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Code")
        {
            Clustered = true;
        }
        key(Key2; Code, "Currency Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(RenameErr);
    end;

    var
        RenameErr: Label 'You cannot rename the line.';

    procedure InsertPurchLines(PurchHeader: Record "Purchase Header")
    var
        StdVendPurchCode: Record "Standard Vendor Purchase Code";
        StdVendPurchCodes: Page "Standard Vendor Purchase Codes";
        IsHandled: Boolean;
    begin
        PurchHeader.TestField("No.");
        PurchHeader.TestField("Buy-from Vendor No.");

        StdVendPurchCode.FilterGroup := 2;
        StdVendPurchCode.SetRange("Vendor No.", PurchHeader."Buy-from Vendor No.");
        StdVendPurchCode.FilterGroup := 0;

        IsHandled := false;
        OnInsertPurchLinesOnBeforeApplyStdVendPurchCodes(StdVendPurchCode, IsHandled, PurchHeader);
        if not IsHandled then begin
            StdVendPurchCodes.SetTableView(StdVendPurchCode);
            StdVendPurchCodes.LookupMode(true);
            if StdVendPurchCodes.RunModal() = ACTION::LookupOK then begin
                StdVendPurchCodes.GetSelected(StdVendPurchCode);
                if StdVendPurchCode.FindSet() then
                    repeat
                        ApplyStdCodesToPurchaseLines(PurchHeader, StdVendPurchCode);
                    until StdVendPurchCode.Next() = 0;
            end;
        end;
    end;

    procedure ApplyStdCodesToPurchaseLines(PurchHeader: Record "Purchase Header"; StdVendPurchCode: Record "Standard Vendor Purchase Code")
    var
        Currency: Record Currency;
        PurchLine: Record "Purchase Line";
        StdPurchLine: Record "Standard Purchase Line";
        StdPurchCode: Record "Standard Purchase Code";
        Factor: Integer;
    begin
        Currency.Initialize(PurchHeader."Currency Code");

        StdVendPurchCode.TestField(Code);
        StdVendPurchCode.TestField("Vendor No.", PurchHeader."Buy-from Vendor No.");
        StdPurchCode.Get(StdVendPurchCode.Code);
        StdPurchCode.TestField("Currency Code", PurchHeader."Currency Code");
        StdPurchLine.SetRange("Standard Purchase Code", StdVendPurchCode.Code);

        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        if PurchHeader."Prices Including VAT" then
            Factor := 1
        else
            Factor := 0;

        OnApplyStdCodesToPurchaseLinesOnBeforeStdPurchLineFind(Rec, StdPurchLine, PurchLine, PurchHeader, StdPurchCode);
        PurchLine.LockTable();
        StdPurchLine.LockTable();
        if StdPurchLine.Find('-') then
            repeat
                PurchLine.Init();
                PurchLine.SetPurchHeader(PurchHeader);
                PurchLine."Line No." := 0;
                PurchLine.Validate(Type, StdPurchLine.Type);
                if StdPurchLine.Type = StdPurchLine.Type::" " then begin
                    PurchLine.Validate("No.", StdPurchLine."No.");
                    PurchLine.Description := StdPurchLine.Description;
                    PurchLine."Buy-from Vendor No." := PurchHeader."Buy-from Vendor No.";
                end else
                    if not StdPurchLine.EmptyLine() then begin
                        StdPurchLine.TestField("No.");
                        PurchLine.Validate("No.", StdPurchLine."No.");
                        if StdPurchLine."Variant Code" <> '' then
                            PurchLine.Validate("Variant Code", StdPurchLine."Variant Code");
                        PurchLine.Validate(Quantity, StdPurchLine.Quantity);
                        if StdPurchLine."Unit of Measure Code" <> '' then
                            PurchLine.Validate("Unit of Measure Code", StdPurchLine."Unit of Measure Code");
                        if StdPurchLine.Description <> '' then
                            PurchLine.Validate(Description, StdPurchLine.Description);
                        if (StdPurchLine.Type = StdPurchLine.Type::"G/L Account") or
                           (StdPurchLine.Type = StdPurchLine.Type::"Charge (Item)")
                        then
                            PurchLine.Validate(
                              "Direct Unit Cost",
                              Round(StdPurchLine."Amount Excl. VAT" *
                                (PurchLine."VAT %" / 100 * Factor + 1), Currency."Unit-Amount Rounding Precision"));
                    end;

                PurchLine."Shortcut Dimension 1 Code" := StdPurchLine."Shortcut Dimension 1 Code";
                PurchLine."Shortcut Dimension 2 Code" := StdPurchLine."Shortcut Dimension 2 Code";

                CombineDimensions(PurchLine, StdPurchLine);
                OnBeforeApplyStdCodesToPurchaseLines(PurchLine, StdPurchLine);
                if StdPurchLine.InsertLine() then begin
                    PurchLine."Line No." := GetNextLineNo(PurchLine);
                    PurchLine.Insert(true);
                    OnApplyStdCodesToPurchaseLinesOnAfterPurchLineInsert(PurchLine, PurchHeader, StdPurchLine);
                    InsertExtendedText(PurchLine, PurchHeader);
                end;
            until StdPurchLine.Next() = 0;

        OnAfterApplyStdCodesToPurchaseLines(Rec, StdPurchLine, PurchLine, PurchHeader, StdPurchCode);
    end;

    local procedure CombineDimensions(var PurchaseLine: Record "Purchase Line"; StdPurchaseLine: Record "Standard Purchase Line")
    var
        DimensionManagement: Codeunit DimensionManagement;
        DimensionSetIDArr: array[10] of Integer;
    begin
        DimensionSetIDArr[1] := PurchaseLine."Dimension Set ID";
        DimensionSetIDArr[2] := StdPurchaseLine."Dimension Set ID";

        PurchaseLine."Dimension Set ID" :=
          DimensionManagement.GetCombinedDimensionSetID(
            DimensionSetIDArr, PurchaseLine."Shortcut Dimension 1 Code", PurchaseLine."Shortcut Dimension 2 Code");

        OnAfterCombineDimensions(PurchaseLine, StdPurchaseLine);
    end;

    procedure InsertExtendedText(PurchLine: Record "Purchase Line")
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        if PurchLine.Type = PurchLine.Type::" " then
            exit;
        if TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, false) then
            TransferExtendedText.InsertPurchExtText(PurchLine);
    end;

    procedure InsertExtendedText(PurchLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        if TransferExtendedText.PurchCheckIfAnyExtText(PurchLine, false, PurchaseHeader) then
            TransferExtendedText.InsertPurchExtText(PurchLine);
    end;

    procedure GetNextLineNo(PurchLine: Record "Purchase Line"): Integer
    begin
        PurchLine.SetRange("Document Type", PurchLine."Document Type");
        PurchLine.SetRange("Document No.", PurchLine."Document No.");
        if PurchLine.FindLast() then
            exit(PurchLine."Line No." + 10000);

        exit(10000);
    end;

    procedure SetFilterByAutomaticAndAlwaysAskCodes(PurchaseHeader: Record "Purchase Header")
    begin
        SetRange("Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        SetRange("Currency Code", PurchaseHeader."Currency Code");
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Quote:
                SetFilter("Insert Rec. Lines On Quotes", '<>%1', "Insert Rec. Lines On Quotes"::Manual);
            PurchaseHeader."Document Type"::Order:
                SetFilter("Insert Rec. Lines On Orders", '<>%1', "Insert Rec. Lines On Orders"::Manual);
            PurchaseHeader."Document Type"::Invoice:
                SetFilter("Insert Rec. Lines On Invoices", '<>%1', "Insert Rec. Lines On Invoices"::Manual);
            PurchaseHeader."Document Type"::"Credit Memo":
                SetFilter("Insert Rec. Lines On Cr. Memos", '<>%1', "Insert Rec. Lines On Cr. Memos"::Manual);
        end;
        OnAfterSetFilterByAutomaticAndAlwaysAskCodes(Rec, PurchaseHeader);
    end;

    procedure IsInsertRecurringLinesOnDocumentAutomatic(PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Quote:
                exit("Insert Rec. Lines On Quotes" = "Insert Rec. Lines On Quotes"::Automatic);
            PurchaseHeader."Document Type"::Order:
                exit("Insert Rec. Lines On Orders" = "Insert Rec. Lines On Orders"::Automatic);
            PurchaseHeader."Document Type"::Invoice:
                exit("Insert Rec. Lines On Invoices" = "Insert Rec. Lines On Invoices"::Automatic);
            PurchaseHeader."Document Type"::"Credit Memo":
                exit("Insert Rec. Lines On Cr. Memos" = "Insert Rec. Lines On Cr. Memos"::Automatic);
            else
                exit(false);
        end;
    end;

    procedure ShouldAutoInsertRecurringLinesOnDocument(PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Quote:
                exit("Insert Rec. Lines On Quotes" <> "Insert Rec. Lines On Quotes"::Manual);
            PurchaseHeader."Document Type"::Order:
                exit("Insert Rec. Lines On Orders" <> "Insert Rec. Lines On Orders"::Manual);
            PurchaseHeader."Document Type"::Invoice:
                exit("Insert Rec. Lines On Invoices" <> "Insert Rec. Lines On Invoices"::Manual);
            PurchaseHeader."Document Type"::"Credit Memo":
                exit("Insert Rec. Lines On Cr. Memos" <> "Insert Rec. Lines On Cr. Memos"::Manual);
            else
                exit(false);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyStdCodesToPurchaseLines(var PurchLine: Record "Purchase Line"; StdPurchLine: Record "Standard Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCombineDimensions(var PurchaseLine: Record "Purchase Line"; StdPurchaseLine: Record "Standard Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyStdCodesToPurchaseLines(var StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code"; var StandardPurchaseLine: Record "Standard Purchase Line"; var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; StandardPurchaseCode: Record "Standard Purchase Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyStdCodesToPurchaseLinesOnBeforeStdPurchLineFind(var StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code"; var StandardPurchaseLine: Record "Standard Purchase Line"; var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; StandardPurchaseCode: Record "Standard Purchase Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyStdCodesToPurchaseLinesOnAfterPurchLineInsert(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var StandardPurchaseLine: Record "Standard Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPurchLinesOnBeforeApplyStdVendPurchCodes(var StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code"; var IsHandled: Boolean; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterByAutomaticAndAlwaysAskCodes(var StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

