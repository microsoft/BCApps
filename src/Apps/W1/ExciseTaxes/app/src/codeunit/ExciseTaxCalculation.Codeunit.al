// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Sustainability.ExciseTax;

codeunit 7412 "Excise Tax Calculation"
{
    Permissions = tabledata "Item Ledger Entry" = rm,
                  tabledata "FA Ledger Entry" = rm;

    var
        NoExciseJournalBatchFoundErr: Label 'No Excise journal batch found for tax type %1.', Comment = '%1 = Excise Tax Type Code';
        ExciseTaxDescriptionLbl: Label 'Excise Tax for %1 - %2', Comment = '%1 = Excise Tax Type Code, %2 = Description', MaxLength = 100;

    procedure UpdateItemLedgerEntryExciseTaxInfo(ExciseTaxesTransactionLog: Record "Sust. Excise Taxes Trans. Log")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ExciseTaxesTransactionLog."Item Ledger Entry No." = 0 then
            exit;

        ItemLedgerEntry.SetLoadFields("Excise Tax Posted");
        if not ItemLedgerEntry.Get(ExciseTaxesTransactionLog."Item Ledger Entry No.") then
            exit;

        ItemLedgerEntry."Excise Tax Posted" := true;
        ItemLedgerEntry.Modify();
    end;

    procedure UpdateFALedgerEntryExciseTaxInfo(ExciseTaxesTransactionLog: Record "Sust. Excise Taxes Trans. Log")
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        if ExciseTaxesTransactionLog."FA Ledger Entry No." = 0 then
            exit;

        FALedgerEntry.SetLoadFields("Excise Tax Posted");
        if not FALedgerEntry.Get(ExciseTaxesTransactionLog."FA Ledger Entry No.") then
            exit;

        FALedgerEntry."Excise Tax Posted" := true;
        FALedgerEntry.Modify();
    end;

    procedure IsExciseTaxEntry(var ExciseJnlLine: Record "Sust. Excise Jnl. Line"): Boolean
    var
        ExciseJnlBatch: Record "Sust. Excise Journal Batch";
    begin
        ExciseJnlBatch.SetLoadFields(Type);
        if ExciseJnlBatch.Get(ExciseJnlLine."Journal Template Name", ExciseJnlLine."Journal Batch Name") then
            if ExciseJnlBatch.Type = ExciseJnlBatch.Type::Excises then
                exit(true);

        exit(false);
    end;

    procedure ProcessTaxTypeItemsWithFilter(TaxTypeCode: Code[20]; StartingDate: Date; EndingDate: Date; ItemFilter: Text[250]; PostingDate: Date)
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("Excise Tax Type");
        Item.SetRange("Excise Tax Type", TaxTypeCode);
        if ItemFilter <> '' then
            Item.SetFilter("No.", ItemFilter);
        if not Item.FindSet() then
            exit;

        repeat
            ProcessEntryTypesForSource(Item."No.", "Sust. Excise Jnl. Source Type"::Item, Item."Excise Tax Type", StartingDate, EndingDate, PostingDate);
        until Item.Next() = 0;
    end;

    procedure ProcessFATaxTypeItemsWithFilter(TaxTypeCode: Code[20]; StartingDate: Date; EndingDate: Date; FixedAssetFilter: Text[250]; PostingDate: Date)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetLoadFields("Excise Tax Type");
        if FixedAssetFilter <> '' then
            FixedAsset.SetFilter("No.", FixedAssetFilter);

        FixedAsset.SetRange("Excise Tax Type", TaxTypeCode);
        if not FixedAsset.FindSet() then
            exit;

        repeat
            if FixedAsset."Excise Tax Type" <> '' then
                ProcessEntryTypesForSource(FixedAsset."No.", "Sust. Excise Jnl. Source Type"::"Fixed Asset", FixedAsset."Excise Tax Type", StartingDate, EndingDate, PostingDate);
        until FixedAsset.Next() = 0;
    end;

    procedure GetExciseBatchForTaxType(var ExciseJnlBatch: Record "Sust. Excise Journal Batch"; TaxType: Code[20]; ShowBatchError: Boolean)
    begin
        ExciseJnlBatch.SetRange("Excise Tax Type Filter", TaxType);
        ExciseJnlBatch.SetRange(Type, ExciseJnlBatch.Type::Excises);
        if not ExciseJnlBatch.FindFirst() and ShowBatchError then
            Error(NoExciseJournalBatchFoundErr, TaxType);
    end;

    local procedure GetQtyForTaxCalculation(SourceType: Enum "Sust. Excise Jnl. Source Type"; SourceNo: Code[20]): Decimal
    begin
        case SourceType of
            SourceType::Item:
                exit(GetQtyForExciseTaxForItem(SourceNo));
            SourceType::"Fixed Asset":
                exit(GetQtyForExciseTaxForFA(SourceNo));
            else
                exit(0);
        end;
    end;

    local procedure GetTaxRateForSource(TaxTypeCode: Code[20]; SourceType: Enum "Sust. Excise Jnl. Source Type"; SourceNo: Code[20]; EffectiveDate: Date): Decimal
    var
        ExciseTaxItemFARate: Record "Excise Tax Item/FA Rate";
        TaxRate: Decimal;
        ExciseSourceType: Enum "Excise Source Type";
    begin
        ExciseSourceType := ExciseTaxItemFARate.ConvertSustSourceTypeToExciseSourceType(SourceType);
        if ExciseTaxItemFARate.GetEffectiveTaxRate(TaxTypeCode, ExciseSourceType, SourceNo, EffectiveDate, TaxRate) then
            exit(TaxRate);

        exit(0);
    end;

    local procedure CalculateTaxAmount(TaxRatePer: Decimal; Quantity: Decimal; QtyForTax: Decimal): Decimal
    begin
        if (TaxRatePer = 0) or (Quantity = 0) or (QtyForTax = 0) then
            exit(0);

        exit((TaxRatePer / 100) * Quantity * QtyForTax);
    end;

    local procedure GetQtyForExciseTaxForItem(ItemNo: Code[20]): Decimal
    var
        Item: Record Item;
    begin
        Item.SetLoadFields("Qty for Excise Tax");
        if not Item.Get(ItemNo) then
            exit(0);

        exit(Item."Qty for Excise Tax");
    end;

    local procedure GetQtyForExciseTaxForFA(FANo: Code[20]): Decimal
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetLoadFields("Qty for Excise Tax");
        if not FixedAsset.Get(FANo) then
            exit(0);

        exit(FixedAsset."Qty for Excise Tax");
    end;

    local procedure GetLastLineNo(TemplateName: Code[10]; BatchName: Code[10]): Integer
    var
        ExciseJnlLine: Record "Sust. Excise Jnl. Line";
    begin
        ExciseJnlLine.SetRange("Journal Template Name", TemplateName);
        ExciseJnlLine.SetRange("Journal Batch Name", BatchName);
        if ExciseJnlLine.FindLast() then
            exit(ExciseJnlLine."Line No." + 10000);

        exit(10000);
    end;

    local procedure ProcessEntryTypesForSource(SourceNo: Code[20]; SourceType: Enum "Sust. Excise Jnl. Source Type"; TaxType: Code[20]; StartingDate: Date; EndingDate: Date; PostingDate: Date)
    var
        ExciseTaxEntryPermission: Record "Excise Tax Entry Permission";
        TempExciseEntryPermission: Record "Excise Tax Entry Permission" temporary;
    begin
        ExciseTaxEntryPermission.GetAllowedEntryTypes(TaxType, TempExciseEntryPermission);
        if not TempExciseEntryPermission.FindSet() then
            exit;

        repeat
            GetQuantityForSourceEntryType(TaxType, SourceNo, SourceType, TempExciseEntryPermission."Excise Entry Type", StartingDate, EndingDate, PostingDate);
        until TempExciseEntryPermission.Next() = 0;
    end;

    local procedure GetQuantityForSourceEntryType(TaxType: Code[20]; SourceNo: Code[20]; SourceType: Enum "Sust. Excise Jnl. Source Type"; EntryType: Enum "Excise Entry Type"; StartingDate: Date; EndingDate: Date; PostingDate: Date)
    begin
        case SourceType of
            "Sust. Excise Jnl. Source Type"::Item:
                ProcessItemLedgerEntriesForTax(TaxType, SourceNo, EntryType, StartingDate, EndingDate, PostingDate);
            "Sust. Excise Jnl. Source Type"::"Fixed Asset":
                ProcessFALedgerEntriesForTax(TaxType, SourceNo, EntryType, StartingDate, EndingDate, PostingDate);
        end;
    end;

    local procedure ProcessItemLedgerEntriesForTax(TaxType: Code[20]; ItemNo: Code[20]; EntryType: Enum "Excise Entry Type"; StartingDate: Date; EndingDate: Date; PostingDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ExciseJnlLine: Record "Sust. Excise Jnl. Line";
        ExciseJnlBatch: Record "Sust. Excise Journal Batch";
        LineNo: Integer;
        QtyForTax: Decimal;
        TaxRate: Decimal;
    begin
        GetExciseBatchForTaxType(ExciseJnlBatch, TaxType, true);
        if ExciseJnlBatch.IsEmpty() then
            exit;

        LineNo := GetLastLineNo(ExciseJnlBatch."Journal Template Name", ExciseJnlBatch.Name);
        TaxRate := GetTaxRateForSource(TaxType, ExciseJnlLine."Source Type"::Item, ItemNo, PostingDate);
        QtyForTax := GetQtyForTaxCalculation(ExciseJnlLine."Source Type"::Item, ItemNo);

        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Posting Date", StartingDate, EndingDate);
        ItemLedgerEntry.SetRange("Excise Tax Posted", false);
        SetFilterOnILEEntryType(EntryType, ItemLedgerEntry);
        if ItemLedgerEntry.FindSet() then
            repeat
                InitializeExciseJournalLine(ExciseJnlLine, ExciseJnlBatch, PostingDate, LineNo);
                UpdateILEDetailsInExciseJnlLine(ExciseJnlLine, ItemLedgerEntry, TaxType, EntryType, TaxRate, QtyForTax);
                ExciseJnlLine.Insert(true);
                LineNo += 10000;
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure ProcessFALedgerEntriesForTax(TaxType: Code[20]; FANo: Code[20]; EntryType: Enum "Excise Entry Type"; FromDate: Date; ToDate: Date; PostingDate: Date)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        ExciseJnlLine: Record "Sust. Excise Jnl. Line";
        ExciseJnlBatch: Record "Sust. Excise Journal Batch";
        LineNo: Integer;
        TaxRate: Decimal;
        QtyForTax: Decimal;
    begin
        if EntryType <> EntryType::Purchase then
            exit;

        GetExciseBatchForTaxType(ExciseJnlBatch, TaxType, true);
        if ExciseJnlBatch.IsEmpty() then
            exit;

        LineNo := GetLastLineNo(ExciseJnlBatch."Journal Template Name", ExciseJnlBatch.Name);
        TaxRate := GetTaxRateForSource(TaxType, ExciseJnlLine."Source Type"::"Fixed Asset", FANo, PostingDate);
        QtyForTax := GetQtyForTaxCalculation(ExciseJnlLine."Source Type"::"Fixed Asset", FANo);

        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("Posting Date", FromDate, ToDate);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FALedgerEntry.SetRange("Excise Tax Posted", false);
        if FALedgerEntry.FindSet() then
            repeat
                InitializeExciseJournalLine(ExciseJnlLine, ExciseJnlBatch, PostingDate, LineNo);
                UpdateFALedgerEntriesDetailsInExciseJnlLine(ExciseJnlLine, FALedgerEntry, TaxType, EntryType, TaxRate, QtyForTax);
                ExciseJnlLine.Insert(true);
                LineNo += 10000;
            until FALedgerEntry.Next() = 0;
    end;

    local procedure GetPartnerDetailFromILE(ItemLedgerEntry: Record "Item Ledger Entry"; var PartnerType: Enum "Sust. Excise Jnl. Partner Type"; var PartnerNo: Code[20])
    begin
        case ItemLedgerEntry."Source Type" of
            ItemLedgerEntry."Source Type"::Customer:
                begin
                    PartnerType := PartnerType::Customer;
                    PartnerNo := ItemLedgerEntry."Source No.";
                end;
            ItemLedgerEntry."Source Type"::Vendor:
                begin
                    PartnerType := PartnerType::Vendor;
                    PartnerNo := ItemLedgerEntry."Source No.";
                end;
            else begin
                PartnerType := PartnerType::" ";
                PartnerNo := '';
            end;
        end;
    end;

    local procedure SetFilterOnILEEntryType(EntryType: Enum "Excise Entry Type"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        case EntryType of
            "Excise Entry Type"::Purchase:
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
            "Excise Entry Type"::Sale:
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
            "Excise Entry Type"::"Positive Adjmt.":
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
            "Excise Entry Type"::"Negative Adjmt.":
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Negative Adjmt.");
            "Excise Entry Type"::Output:
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
            "Excise Entry Type"::"Assembly Output":
                ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Output");
        end;
    end;

    local procedure GetPartnerNo(FALedgerEntry: Record "FA Ledger Entry"): Code[20]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if FALedgerEntry."Document Type" <> FALedgerEntry."Document Type"::Invoice then
            exit;

        VendorLedgerEntry.SetRange("Document No.", FALedgerEntry."Document No.");
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        if VendorLedgerEntry.FindFirst() then
            exit(VendorLedgerEntry."Vendor No.");
    end;

    local procedure InitializeExciseJournalLine(var ExciseJnlLine: Record "Sust. Excise Jnl. Line"; ExciseJnlBatch: Record "Sust. Excise Journal Batch"; PostingDate: Date; LineNo: Integer);
    var
        NoSeriesBatch: Codeunit "No. Series - Batch";
    begin
        ExciseJnlLine.Init();
        ExciseJnlLine."Journal Template Name" := ExciseJnlBatch."Journal Template Name";
        ExciseJnlLine."Journal Batch Name" := ExciseJnlBatch.Name;
        ExciseJnlLine."Line No." := LineNo;
        ExciseJnlLine."Posting Date" := PostingDate;
        ExciseJnlLine."Document No." := NoSeriesBatch.GetNextNo(ExciseJnlBatch."No Series", ExciseJnlLine."Posting Date");
        ExciseJnlLine."Document Type" := ExciseJnlLine."Document Type"::Journal;
    end;

    local procedure UpdateILEDetailsInExciseJnlLine(var ExciseJnlLine: Record "Sust. Excise Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry"; TaxType: Code[20]; EntryType: Enum "Excise Entry Type"; TaxRate: Decimal; QtyForTax: Decimal)
    var
        Item: Record Item;
        PartnerType: Enum "Sust. Excise Jnl. Partner Type";
        PartnerNo: Code[20];
    begin
        Item.SetLoadFields("Excise Tax UOM");
        Item.Get(ItemLedgerEntry."Item No.");

        GetPartnerDetailFromILE(ItemLedgerEntry, PartnerType, PartnerNo);
        ExciseJnlLine.Description := ItemLedgerEntry.Description;
        if ExciseJnlLine.Description = '' then
            ExciseJnlLine.Description := StrSubstNo(ExciseTaxDescriptionLbl, TaxType, ItemLedgerEntry."Item No.");

        ExciseJnlLine."Excise Tax Type" := TaxType;
        ExciseJnlLine."Excise Entry Type" := EntryType;
        ExciseJnlLine."Excise Tax UOM" := Item."Excise Tax UOM";
        ExciseJnlLine.Validate("Partner Type", PartnerType);
        ExciseJnlLine.Validate("Partner No.", PartnerNo);
        ExciseJnlLine.Validate("Source Type", ExciseJnlLine."Source Type"::Item);
        ExciseJnlLine.Validate("Source No.", ItemLedgerEntry."Item No.");
        ExciseJnlLine."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        ExciseJnlLine."Tax Rate %" := TaxRate;
        ExciseJnlLine.Quantity := Abs(ItemLedgerEntry.Quantity);
        ExciseJnlLine."Tax Amount" := CalculateTaxAmount(ExciseJnlLine."Tax Rate %", ExciseJnlLine.Quantity, QtyForTax);
    end;

    local procedure UpdateFALedgerEntriesDetailsInExciseJnlLine(var ExciseJnlLine: Record "Sust. Excise Jnl. Line"; FALedgerEntry: Record "FA Ledger Entry"; TaxType: Code[20]; EntryType: Enum "Excise Entry Type"; TaxRate: Decimal; QtyForTax: Decimal)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetLoadFields("Excise Tax UOM");
        FixedAsset.Get(FALedgerEntry."FA No.");

        ExciseJnlLine.Description := FALedgerEntry.Description;
        if ExciseJnlLine.Description = '' then
            ExciseJnlLine.Description := StrSubstNo(ExciseTaxDescriptionLbl, TaxType, FALedgerEntry."FA No.");

        ExciseJnlLine."Excise Tax Type" := TaxType;
        ExciseJnlLine."Excise Entry Type" := EntryType;
        ExciseJnlLine."Excise Tax UOM" := FixedAsset."Excise Tax UOM";
        ExciseJnlLine.Validate("Partner Type", ExciseJnlLine."Partner Type"::Vendor);
        ExciseJnlLine.Validate("Partner No.", GetPartnerNo(FALedgerEntry));
        ExciseJnlLine.Validate("Source Type", ExciseJnlLine."Source Type"::"Fixed Asset");
        ExciseJnlLine.Validate("Source No.", FALedgerEntry."FA No.");
        ExciseJnlLine."FA Ledger Entry No." := FALedgerEntry."Entry No.";
        ExciseJnlLine."Tax Rate %" := TaxRate;
        ExciseJnlLine.Quantity := 1;
        ExciseJnlLine."Tax Amount" := CalculateTaxAmount(ExciseJnlLine."Tax Rate %", ExciseJnlLine.Quantity, QtyForTax);
    end;
}