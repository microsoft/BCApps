// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Sustainability.ExciseTax;

codeunit 7412 "Excise Tax Calculation"
{
    Permissions = tabledata "Item Ledger Entry" = rm,
                  tabledata "FA Ledger Entry" = rm;

    var
        ExciseJournalBatch: Record "Sust. Excise Journal Batch";

    internal procedure UpdateItemLedgerEntryExciseTaxInfo(ExciseTaxesTransactionLog: Record "Sust. Excise Taxes Trans. Log")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ExciseTaxesTransactionLog."Item Ledger Entry No." = 0 then
            exit;

        ItemLedgerEntry.SetLoadFields("Excise Tax Posted", "Item No.", "Entry Type");
        ItemLedgerEntry.Get(ExciseTaxesTransactionLog."Item Ledger Entry No.");
        if not AllExciseTaxesPostedForItemLedgerEntry(ItemLedgerEntry, ExciseTaxesTransactionLog."Excise Tax Type") then
            exit;

        ItemLedgerEntry."Excise Tax Posted" := true;
        ItemLedgerEntry.Modify();
    end;

    internal procedure UpdateFALedgerEntryExciseTaxInfo(ExciseTaxesTransactionLog: Record "Sust. Excise Taxes Trans. Log")
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        if ExciseTaxesTransactionLog."FA Ledger Entry No." = 0 then
            exit;

        FALedgerEntry.SetLoadFields("Excise Tax Posted");
        FALedgerEntry.Get(ExciseTaxesTransactionLog."FA Ledger Entry No.");
        FALedgerEntry."Excise Tax Posted" := true;
        FALedgerEntry.Modify();
    end;

    internal procedure IsExciseTaxEntry(var ExciseJnlLine: Record "Sust. Excise Jnl. Line"): Boolean
    var
        ExciseJnlBatch: Record "Sust. Excise Journal Batch";
    begin
        ExciseJnlBatch.SetLoadFields(Type);
        if ExciseJnlBatch.Get(ExciseJnlLine."Journal Template Name", ExciseJnlLine."Journal Batch Name") then
            if ExciseJnlBatch.Type = ExciseJnlBatch.Type::Excises then
                exit(true);
    end;

    internal procedure CreateExciseJournalLineForItem(TaxTypeCode: Code[20]; StartingDate: Date; EndingDate: Date; ItemFilter: Text[250]; PostingDate: Date)
    var
        ItemExciseTax: Record "Item Excise Tax";
    begin
        ItemExciseTax.SetRange("Excise Tax Type Code", TaxTypeCode);
        if ItemFilter <> '' then
            ItemExciseTax.SetFilter("Item No.", ItemFilter);

        if ItemExciseTax.FindSet() then
            repeat
                ProcessEntryTypesForSource(ItemExciseTax."Item No.", "Sust. Excise Jnl. Source Type"::Item, TaxTypeCode, StartingDate, EndingDate, PostingDate);
            until ItemExciseTax.Next() = 0;
    end;

    internal procedure CreateExciseJournalLineForFixedAsset(TaxTypeCode: Code[20]; StartingDate: Date; EndingDate: Date; FixedAssetFilter: Text[250]; PostingDate: Date)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset.SetLoadFields("Excise Tax Type");
        if FixedAssetFilter <> '' then
            FixedAsset.SetFilter("No.", FixedAssetFilter);

        FixedAsset.SetRange("Excise Tax Type", TaxTypeCode);
        if FixedAsset.FindSet() then
            repeat
                if FixedAsset."Excise Tax Type" <> '' then
                    ProcessEntryTypesForSource(FixedAsset."No.", "Sust. Excise Jnl. Source Type"::"Fixed Asset", FixedAsset."Excise Tax Type", StartingDate, EndingDate, PostingDate);
            until FixedAsset.Next() = 0;
    end;

    internal procedure SetExciseJournalBatch(var ExciseJnlBatch: Record "Sust. Excise Journal Batch")
    begin
        ExciseJournalBatch := ExciseJnlBatch;
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

        if SourceType = SourceType::"Fixed Asset" then
            TempExciseEntryPermission.SetRange("Excise Entry Type", TempExciseEntryPermission."Excise Entry Type"::Purchase);

        if not TempExciseEntryPermission.FindSet() then
            exit;

        repeat
            CreateExciseJournalLineForItemAndFixedAsset(TaxType, SourceNo, SourceType, TempExciseEntryPermission."Excise Entry Type", StartingDate, EndingDate, PostingDate);
        until TempExciseEntryPermission.Next() = 0;
    end;

    local procedure CreateExciseJournalLineForItemAndFixedAsset(TaxType: Code[20]; SourceNo: Code[20]; SourceType: Enum "Sust. Excise Jnl. Source Type"; EntryType: Enum "Excise Entry Type"; StartingDate: Date; EndingDate: Date; PostingDate: Date)
    begin
        case SourceType of
            "Sust. Excise Jnl. Source Type"::Item:
                CreateExciseJournalLineForItem(TaxType, SourceNo, EntryType, StartingDate, EndingDate, PostingDate);
            "Sust. Excise Jnl. Source Type"::"Fixed Asset":
                CreateExciseJournalLineForFixedAsset(TaxType, SourceNo, EntryType, StartingDate, EndingDate, PostingDate);
        end;
    end;

    local procedure CreateExciseJournalLineForItem(TaxType: Code[20]; ItemNo: Code[20]; EntryType: Enum "Excise Entry Type"; StartingDate: Date; EndingDate: Date; PostingDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ExciseJnlLine: Record "Sust. Excise Jnl. Line";
        LineNo: Integer;
    begin
        ExciseJournalBatch.TestField("Journal Template Name");
        ExciseJournalBatch.TestField(Type, ExciseJournalBatch.Type::Excises);

        LineNo := GetLastLineNo(ExciseJournalBatch."Journal Template Name", ExciseJournalBatch.Name);

        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Posting Date", StartingDate, EndingDate);
        ItemLedgerEntry.SetRange("Excise Tax Posted", false);
        SetFilterOnILEEntryType(EntryType, ItemLedgerEntry);
        if ItemLedgerEntry.FindSet() then
            repeat
                if not ExciseJournalLineExist(ItemLedgerEntry, TaxType) and not ExciseTaxPostedInTransLog(ItemLedgerEntry, TaxType) then begin
                    InitializeExciseJournalLine(ExciseJnlLine, ExciseJournalBatch, PostingDate, LineNo);
                    UpdateExciseJournalLineFromItemLedgerEntry(ExciseJnlLine, ItemLedgerEntry, TaxType, EntryType);
                    OnBeforeInsertExciseJournalLineForItem(ExciseJnlLine, ItemLedgerEntry);
                    ExciseJnlLine.Insert(true);
                    OnAfterInsertExciseJournalLineForItem(ExciseJnlLine, ItemLedgerEntry);
                    LineNo += 10000;
                end;
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure CreateExciseJournalLineForFixedAsset(TaxType: Code[20]; FANo: Code[20]; EntryType: Enum "Excise Entry Type"; FromDate: Date; ToDate: Date; PostingDate: Date)
    var
        FALedgerEntry: Record "FA Ledger Entry";
        ExciseJnlLine: Record "Sust. Excise Jnl. Line";
        LineNo: Integer;
    begin
        ExciseJournalBatch.TestField("Journal Template Name");
        ExciseJournalBatch.TestField(Type, ExciseJournalBatch.Type::Excises);

        LineNo := GetLastLineNo(ExciseJournalBatch."Journal Template Name", ExciseJournalBatch.Name);

        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("Posting Date", FromDate, ToDate);
        FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
        FALedgerEntry.SetRange("Excise Tax Posted", false);
        if FALedgerEntry.FindSet() then
            repeat
                if not ExciseJournalLineExist(FALedgerEntry) then begin
                    InitializeExciseJournalLine(ExciseJnlLine, ExciseJournalBatch, PostingDate, LineNo);
                    UpdateExciseJournalLineFromFALedgerEntry(ExciseJnlLine, FALedgerEntry, TaxType, EntryType);
                    OnBeforeInsertExciseJournalLineForFixedAsset(ExciseJnlLine, FALedgerEntry);
                    ExciseJnlLine.Insert(true);
                    OnAfterInsertExciseJournalLineForFixedAsset(ExciseJnlLine, FALedgerEntry);
                    LineNo += 10000;
                end;
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
        ExciseJnlLine."Source Code" := ExciseJnlBatch."Source Code";
        ExciseJnlLine."Reason Code" := ExciseJnlBatch."Reason Code";
    end;

    local procedure UpdateExciseJournalLineFromItemLedgerEntry(var ExciseJnlLine: Record "Sust. Excise Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry"; TaxType: Code[20]; EntryType: Enum "Excise Entry Type")
    var
        PartnerType: Enum "Sust. Excise Jnl. Partner Type";
        PartnerNo: Code[20];
    begin
        GetPartnerDetailFromILE(ItemLedgerEntry, PartnerType, PartnerNo);
        if ItemLedgerEntry.Description = '' then
            ExciseJnlLine.Description := ExciseJournalBatch.Description
        else
            ExciseJnlLine.Description := ItemLedgerEntry.Description;

        ExciseJnlLine."Excise Tax Type" := TaxType;
        ExciseJnlLine."Excise Entry Type" := EntryType;

        case EntryType of
            EntryType::Purchase,
            EntryType::Sale,
            EntryType::"Positive Adjmt.",
            EntryType::"Negative Adjmt.":
                case ItemLedgerEntry."Document Type" of
                    ItemLedgerEntry."Document Type"::"Purchase Invoice",
                    ItemLedgerEntry."Document Type"::"Purchase Receipt",
                    ItemLedgerEntry."Document Type"::"Sales Invoice",
                    ItemLedgerEntry."Document Type"::"Sales Shipment":
                        ExciseJnlLine.Validate("Document Type", ExciseJnlLine."Document Type"::Invoice);
                    ItemLedgerEntry."Document Type"::"Purchase Credit Memo",
                    ItemLedgerEntry."Document Type"::"Purchase Return Shipment",
                    ItemLedgerEntry."Document Type"::"Sales Credit Memo",
                    ItemLedgerEntry."Document Type"::"Sales Return Receipt":
                        ExciseJnlLine.Validate("Document Type", ExciseJnlLine."Document Type"::"Credit Memo");
                    else
                        ExciseJnlLine.Validate("Document Type", ExciseJnlLine."Document Type"::Journal);
                end;
            EntryType::Output:
                ExciseJnlLine.Validate("Document Type", ExciseJnlLine."Document Type"::"Production Order");
            EntryType::"Assembly Output":
                ExciseJnlLine.Validate("Document Type", ExciseJnlLine."Document Type"::"Assembly Order");
        end;

        ExciseJnlLine.Validate("Partner Type", PartnerType);
        ExciseJnlLine.Validate("Partner No.", PartnerNo);
        ExciseJnlLine.Validate("Country/Region Code", ItemLedgerEntry."Country/Region Code");
        ExciseJnlLine.Validate("Source Type", ExciseJnlLine."Source Type"::Item);
        ExciseJnlLine.Validate("Source No.", ItemLedgerEntry."Item No.");
        ExciseJnlLine.Validate("Item Category Code", ItemLedgerEntry."Item Category Code");
        ExciseJnlLine.Validate("Source Qty.", Abs(ItemLedgerEntry.Quantity));
        if RequiresTaxableAmount(ExciseJnlLine) then
            ExciseJnlLine.Validate("Excise Taxable Amount", GetTaxableAmountFromItemLedgerEntry(ItemLedgerEntry));
        OnAfterUpdateExciseJournalLineFromItemLedgerEntry(ExciseJnlLine, ItemLedgerEntry);
        ExciseJnlLine."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
    end;

    local procedure UpdateExciseJournalLineFromFALedgerEntry(var ExciseJnlLine: Record "Sust. Excise Jnl. Line"; FALedgerEntry: Record "FA Ledger Entry"; TaxType: Code[20]; EntryType: Enum "Excise Entry Type")
    begin
        if FALedgerEntry.Description = '' then
            ExciseJnlLine.Description := ExciseJournalBatch.Description
        else
            ExciseJnlLine.Description := FALedgerEntry.Description;
        ExciseJnlLine."Excise Tax Type" := TaxType;
        ExciseJnlLine."Excise Entry Type" := EntryType;

        case FALedgerEntry."Document Type" of
            FALedgerEntry."Document Type"::Invoice:
                begin
                    ExciseJnlLine.Validate("Document Type", ExciseJnlLine."Document Type"::Invoice);
                    UpdateExciseJournalFromPurchaseInvoice(ExciseJnlLine, FALedgerEntry."Document No.");
                end;
            FALedgerEntry."Document Type"::"Credit Memo":
                begin
                    ExciseJnlLine.Validate("Document Type", ExciseJnlLine."Document Type"::"Credit Memo");
                    UpdateExciseJournalFromPurchaseCreditMemo(ExciseJnlLine, FALedgerEntry."Document No.");
                end;
            else
                ExciseJnlLine.Validate("Document Type", ExciseJnlLine."Document Type"::Journal);
        end;

        ExciseJnlLine.Validate("Source Type", ExciseJnlLine."Source Type"::"Fixed Asset");
        ExciseJnlLine.Validate("Source No.", FALedgerEntry."FA No.");
        ExciseJnlLine.Validate("Source Qty.", 1);
        if RequiresTaxableAmount(ExciseJnlLine) then
            ExciseJnlLine.Validate("Excise Taxable Amount", Abs(FALedgerEntry.Amount));
        ExciseJnlLine."FA Ledger Entry No." := FALedgerEntry."Entry No.";
    end;

    local procedure RequiresTaxableAmount(ExciseJnlLine: Record "Sust. Excise Jnl. Line"): Boolean
    begin
        exit(ExciseJnlLine."Excise Calculation Type" in ["Excise Calculation Type"::"Ad valorem", "Excise Calculation Type"::Hybrid]);
    end;

    // The taxable value of an item ledger entry is taken from its value entries: the invoiced sales or purchase
    // amount when the entry has one, otherwise the inventory cost.
    local procedure GetTaxableAmountFromItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    begin
        case ItemLedgerEntry."Entry Type" of
            ItemLedgerEntry."Entry Type"::Sale:
                begin
                    ItemLedgerEntry.CalcFields("Sales Amount (Actual)");
                    if ItemLedgerEntry."Sales Amount (Actual)" <> 0 then
                        exit(Abs(ItemLedgerEntry."Sales Amount (Actual)"));
                end;
            ItemLedgerEntry."Entry Type"::Purchase:
                begin
                    ItemLedgerEntry.CalcFields("Purchase Amount (Actual)");
                    if ItemLedgerEntry."Purchase Amount (Actual)" <> 0 then
                        exit(Abs(ItemLedgerEntry."Purchase Amount (Actual)"));
                end;
        end;

        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Expected)");
        if ItemLedgerEntry."Cost Amount (Actual)" <> 0 then
            exit(Abs(ItemLedgerEntry."Cost Amount (Actual)"));

        exit(Abs(ItemLedgerEntry."Cost Amount (Expected)"));
    end;

    local procedure UpdateExciseJournalFromPurchaseInvoice(var SustExciseJournalLine: Record "Sust. Excise Jnl. Line"; DocumentNo: Code[20])
    var
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
    begin
        PurchaseInvoiceHeader.SetLoadFields("Buy-from Vendor No.", "Buy-from Country/Region Code");
        if not PurchaseInvoiceHeader.Get(DocumentNo) then
            exit;

        SustExciseJournalLine.Validate("Partner Type", SustExciseJournalLine."Partner Type"::Vendor);
        SustExciseJournalLine.Validate("Partner No.", PurchaseInvoiceHeader."Buy-from Vendor No.");
        SustExciseJournalLine.Validate("Country/Region Code", PurchaseInvoiceHeader."Buy-from Country/Region Code");
    end;

    local procedure UpdateExciseJournalFromPurchaseCreditMemo(var SustExciseJournalLine: Record "Sust. Excise Jnl. Line"; DocumentNo: Code[20])
    var
        PurchaseCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchaseCrMemoHeader.SetLoadFields("Buy-from Vendor No.", "Buy-from Country/Region Code");
        if not PurchaseCrMemoHeader.Get(DocumentNo) then
            exit;

        SustExciseJournalLine.Validate("Partner Type", SustExciseJournalLine."Partner Type"::Vendor);
        SustExciseJournalLine.Validate("Partner No.", PurchaseCrMemoHeader."Buy-from Vendor No.");
        SustExciseJournalLine.Validate("Country/Region Code", PurchaseCrMemoHeader."Buy-from Country/Region Code");
    end;

    local procedure ExciseJournalLineExist(ItemLedgerEntry: Record "Item Ledger Entry"; TaxType: Code[20]): Boolean
    var
        ExciseJournalLine: Record "Sust. Excise Jnl. Line";
    begin
        ExciseJournalLine.SetLoadFields("Item Ledger Entry No.");
        ExciseJournalLine.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ExciseJournalLine.SetRange("Excise Tax Type", TaxType);
        if not ExciseJournalLine.IsEmpty() then
            exit(true);
    end;

    local procedure ExciseJournalLineExist(FALedgerEntry: Record "FA Ledger Entry"): Boolean
    var
        ExciseJournalLine: Record "Sust. Excise Jnl. Line";
    begin
        ExciseJournalLine.SetLoadFields("FA Ledger Entry No.");
        ExciseJournalLine.SetRange("FA Ledger Entry No.", FALedgerEntry."Entry No.");
        if not ExciseJournalLine.IsEmpty() then
            exit(true);
    end;

    local procedure ExciseTaxPostedInTransLog(ItemLedgerEntry: Record "Item Ledger Entry"; TaxType: Code[20]): Boolean
    var
        ExciseTaxesTransactionLog: Record "Sust. Excise Taxes Trans. Log";
    begin
        ExciseTaxesTransactionLog.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ExciseTaxesTransactionLog.SetRange("Excise Tax Type", TaxType);
        exit(not ExciseTaxesTransactionLog.IsEmpty());
    end;

    local procedure ExciseTaxTypeEnabled(TaxTypeCode: Code[20]): Boolean
    var
        ExciseTaxType: Record "Excise Tax Type";
    begin
        ExciseTaxType.SetLoadFields(Enabled);
        if ExciseTaxType.Get(TaxTypeCode) then
            exit(ExciseTaxType.Enabled);
    end;

    local procedure AllExciseTaxesPostedForItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry"; CurrentTaxType: Code[20]): Boolean
    var
        ItemExciseTax: Record "Item Excise Tax";
        ExciseTaxEntryPermission: Record "Excise Tax Entry Permission";
        ExciseEntryType: Enum "Excise Entry Type";
        HasApplicableTaxType: Boolean;
    begin
        if not GetExciseEntryTypeFromItemLedgerEntry(ItemLedgerEntry, ExciseEntryType) then
            exit(false);

        ItemExciseTax.SetLoadFields("Excise Tax Type Code");
        ItemExciseTax.SetRange("Item No.", ItemLedgerEntry."Item No.");
        if ItemExciseTax.FindSet() then
            repeat
                // Only enabled tax types allowed for this entry's type ever produce a line for it, so the
                // flag can be set once all of those are posted; disabled or not-allowed types must not block it.
                if ExciseTaxTypeEnabled(ItemExciseTax."Excise Tax Type Code") and
                   ExciseTaxEntryPermission.IsEntryTypeAllowed(ItemExciseTax."Excise Tax Type Code", ExciseEntryType)
                then begin
                    HasApplicableTaxType := true;
                    // Treat the tax type currently being posted as posted: it triggered this check and its
                    // transaction log entry may not be committed yet, so skip the redundant lookup for it.
                    if (ItemExciseTax."Excise Tax Type Code" <> CurrentTaxType) and
                       not ExciseTaxPostedInTransLog(ItemLedgerEntry, ItemExciseTax."Excise Tax Type Code")
                    then
                        exit(false);
                end;
            until ItemExciseTax.Next() = 0;

        exit(HasApplicableTaxType);
    end;

    local procedure GetExciseEntryTypeFromItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry"; var ExciseEntryType: Enum "Excise Entry Type"): Boolean
    begin
        case ItemLedgerEntry."Entry Type" of
            ItemLedgerEntry."Entry Type"::Purchase:
                ExciseEntryType := ExciseEntryType::Purchase;
            ItemLedgerEntry."Entry Type"::Sale:
                ExciseEntryType := ExciseEntryType::Sale;
            ItemLedgerEntry."Entry Type"::"Positive Adjmt.":
                ExciseEntryType := ExciseEntryType::"Positive Adjmt.";
            ItemLedgerEntry."Entry Type"::"Negative Adjmt.":
                ExciseEntryType := ExciseEntryType::"Negative Adjmt.";
            ItemLedgerEntry."Entry Type"::Output:
                ExciseEntryType := ExciseEntryType::Output;
            ItemLedgerEntry."Entry Type"::"Assembly Output":
                ExciseEntryType := ExciseEntryType::"Assembly Output";
            else
                exit(false);
        end;
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExciseJournalLineForItem(var ExciseJournalLine: Record "Sust. Excise Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertExciseJournalLineForItem(var ExciseJournalLine: Record "Sust. Excise Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateExciseJournalLineFromItemLedgerEntry(var ExciseJournalLine: Record "Sust. Excise Jnl. Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExciseJournalLineForFixedAsset(var ExciseJournalLine: Record "Sust. Excise Jnl. Line"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertExciseJournalLineForFixedAsset(var ExciseJournalLine: Record "Sust. Excise Jnl. Line"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;
}