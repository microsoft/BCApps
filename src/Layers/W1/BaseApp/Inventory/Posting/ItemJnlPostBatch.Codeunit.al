// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Posting;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using System.Utilities;

codeunit 23 "Item Jnl.-Post Batch"
{
    Permissions = TableData "Item Journal Batch" = rimd,
                  TableData "Warehouse Register" = r,
                  TableData "Value Entry" = rm;
    TableNo = "Item Journal Line";
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);

        ItemJnlLine.Copy(Rec);
        ItemJnlLine.SetAutoCalcFields();
        Code();
        Rec := ItemJnlLine;

        OnAfterOnRun(Rec);
    end;

    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemReg: Record "Item Register";
        GLSetup: Record "General Ledger Setup";
        InvtSetup: Record "Inventory Setup";
        AccountingPeriod: Record "Accounting Period";
        Location: Record Location;
        ItemJnlCheckLine: Codeunit "Item Jnl.-Check Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        WMSMgmt: Codeunit "WMS Management";
        WhseJnlPostLine: Codeunit "Whse. Jnl.-Register Line";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
        Window: Dialog;
        ItemsToAdjust: List of [Code[20]];
        PostponedValueEntries: List of [Integer];
        ItemRegNo: Integer;
        WhseRegNo: Integer;
        StartLineNo: Integer;
        NoOfRecords: Integer;
        LineCount: Integer;
        LastDocNo: Code[20];
        LastDocNo2: Code[20];
        LastPostedDocNo: Code[20];
        WhseTransaction: Boolean;
        PhysInvtCount: Boolean;
        SuppressCommit: Boolean;
        WindowIsOpen: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Journal Batch Name    #1##########\\';
        Text002: Label 'Checking lines        #2######\';
        Text003: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@\';
        Text004: Label 'Updating lines        #5###### @6@@@@@@@@@@@@@';
        Text005: Label 'Posting lines         #3###### @4@@@@@@@@@@@@@\';
        Text008: Label 'There are new postings made in the period you want to revalue item no. %1.\';
#pragma warning restore AA0470
        Text009: Label 'You must calculate the inventory value again.';
#pragma warning disable AA0470
        Text010: Label 'One or more reservation entries exist for the item with %1 = %2, %3 = %4, %5 = %6 which may be disrupted if you post this negative adjustment. Do you want to continue?', Comment = 'One or more reservation entries exist for the item with Item No. = 1000, Location Code = BLUE, Variant Code = NEW which may be disrupted if you post this negative adjustment. Do you want to continue?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure "Code"()
    var
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
        OldEntryType: Enum "Item Ledger Entry Type";
        RaiseError: Boolean;
    begin
        OnBeforeCode(ItemJnlLine, ItemLedgEntry);

        ItemJnlLine.ReadIsolation(IsolationLevel::UpdLock);
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");

        ItemJnlTemplate.Get(ItemJnlLine."Journal Template Name");
        ItemJnlBatch.Get(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        OnBeforeRaiseExceedLengthError(ItemJnlBatch, RaiseError);

        if ItemJnlTemplate.Recurring then begin
            ItemJnlLine.SetRange("Posting Date", 0D, WorkDate());
            ItemJnlLine.SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate());
        end;

        if not ItemJnlLine.Find('=><') then begin
            ItemJnlLine."Line No." := 0;
            if not SuppressCommit then
                Commit();
            exit;
        end;

        OpenProgressDialog();

        CheckItemAvailability(ItemJnlLine);

        CheckLines(ItemJnlLine);
        GLSetup.SetLoadFields("Amount Rounding Precision");
        GLSetup.Get();

        if InvtSetup.UseLegacyPosting() then begin
            // Find next register no.
            ItemLedgEntry.LockTable();
            if ItemLedgEntry.FindLast() then;

            ItemReg.LockTable();
            ItemRegNo := ItemReg.GetLastEntryNo() + 1;
        end;

        Clear(PostponedValueEntries);
        BindSubscription(this); // To set ItemRegNo or WhseRegNo if an entry is created and collect value entries for GLPosting

        PhysInvtCount := false;
        // Post lines
        OnCodeOnBeforePostLines(ItemJnlLine, NoOfRecords);
        LineCount := 0;
        OldEntryType := ItemJnlLine."Entry Type";
        PostLines(ItemJnlLine, PhysInvtCountMgt);
        // Copy register no. and current journal batch name to item journal
        if InvtSetup.UseLegacyPosting() then
            if not ItemReg.FindLast() or (ItemReg."No." <> ItemRegNo) then
                ItemRegNo := 0;

        UnBindSubscription(this);

        OnAfterCopyRegNos(ItemJnlLine, ItemRegNo, WhseRegNo);

        ItemJnlLine.Init();

        ItemJnlLine."Line No." := ItemRegNo;
        if ItemJnlLine."Line No." = 0 then
            ItemJnlLine."Line No." := WhseRegNo;

        ItemJnlPostLine.PostDeferredValueEntriesToGL(PostponedValueEntries);

        MakeInventoryAdjustment();

        // Update/delete lines
        OnBeforeUpdateDeleteLines(ItemJnlLine, ItemRegNo);
        if ItemJnlLine."Line No." <> 0 then begin
            if ItemJnlTemplate.Recurring then
                HandleRecurringLine(ItemJnlLine)
            else
                HandleNonRecurringLine(ItemJnlLine, OldEntryType);
            NoSeriesBatch.SaveState();
        end;

        if PhysInvtCount then
            PhysInvtCountMgt.UpdateItemSKUListPhysInvtCount();

        OnAfterPostJnlLines(ItemJnlBatch, ItemJnlLine, ItemRegNo, WhseRegNo, WindowIsOpen);

        if WindowIsOpen then
            Window.Close();
        if not SuppressCommit then
            Commit();
        Clear(ItemJnlCheckLine);
        Clear(ItemJnlPostLine);
        Clear(WhseJnlPostLine);
        Clear(InvtAdjmtHandler);

        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);

        OnAfterUpdateAnalysisViews(ItemReg);

        if not SuppressCommit then
            Commit();

        OnAfterCode(ItemJnlLine, ItemJnlBatch, ItemRegNo, WhseRegNo);
    end;

    local procedure OpenProgressDialog()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenProgressDialog(ItemJnlLine, Window, WindowIsOpen, IsHandled);
        if IsHandled then
            exit;

        if not GuiAllowed() then
            exit;

        if ItemJnlTemplate.Recurring then
            Window.Open(
              Text001 +
              Text002 +
              Text003 +
              Text004)
        else
            Window.Open(
              Text001 +
              Text002 +
              Text005);

        Window.Update(1, ItemJnlLine."Journal Batch Name");
        WindowIsOpen := true;
    end;

    local procedure CheckLines(var ItemJnlLine: Record "Item Journal Line")
    var
        InventorySetup: Record "Inventory Setup";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        IsHandled: Boolean;
    begin
        OnBeforeCheckLines(ItemJnlLine, WindowIsOpen);

        LineCount := 0;
        StartLineNo := ItemJnlLine."Line No.";
        repeat
            LineCount := LineCount + 1;
            if WindowIsOpen then
                Window.Update(2, LineCount);
            CheckRecurringLine(ItemJnlLine);

            IsHandled := false;
            OnBeforeCheckJnlLine(ItemJnlLine, SuppressCommit, IsHandled);
            if not IsHandled then
                if ((ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and (ItemJnlLine."Item Charge No." = '')) or
                    ((ItemJnlLine."Invoiced Quantity" <> 0) and (ItemJnlLine.Amount <> 0))
                then begin
                    ItemJnlCheckLine.RunCheck(ItemJnlLine);

                    if (ItemJnlLine.Quantity <> 0) and
                        (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and (ItemJnlLine."Item Charge No." = '')
                    then
                        CheckWMSBin(ItemJnlLine);

                    if (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::Revaluation) and
                        (ItemJnlLine."Inventory Value Per" = ItemJnlLine."Inventory Value Per"::" ") and ItemJnlLine."Partial Revaluation"
                    then
                        CheckRemainingQty(ItemJnlLine."Applies-to Entry", ItemJnlLine."Posting Date");

                    OnAfterCheckJnlLine(ItemJnlLine, SuppressCommit);
                end;

            if ItemJnlLine.Next() = 0 then
                ItemJnlLine.FindFirst();
        until ItemJnlLine."Line No." = StartLineNo;
        NoOfRecords := LineCount;
        if NoOfRecords > 0 then 
            if not InventorySetup.UseLegacyPosting() then begin
                SequenceNoMgt.AllocateSeqNoBuffer(Database::"Item Ledger Entry", NoOfRecords);
                SequenceNoMgt.AllocateSeqNoBuffer(Database::"Value Entry", NoOfRecords);
        end;

        OnAfterCheckLines(ItemJnlLine);
    end;

    local procedure PostLines(var ItemJnlLine: Record "Item Journal Line"; var PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemJnlLineLoop: Record "Item Journal Line";
        OriginalQuantity: Decimal;
        OriginalQuantityBase: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforePostLines(ItemJnlLine, ItemRegNo, WhseRegNo);

        LastDocNo := '';
        LastDocNo2 := '';
        LastPostedDocNo := '';

        ItemJnlLineLoop.Copy(ItemJnlLine);
        if InvtSetup.UseLegacyPosting() then
            ItemJnlLineLoop.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.")
        else
            ItemJnlLineLoop.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Document No.", "Item No.", "Location Code", "Bin Code", "Line No.");
        ItemJnlLineLoop.FindSet();
        repeat
            ItemJnlLine := ItemJnlLineLoop;
            if not ItemJnlLine.EmptyLine() and (ItemJnlBatch."No. Series" <> '') and (ItemJnlLine."Document No." <> LastDocNo2) then
                ItemJnlLine.TestField("Document No.", NoSeriesBatch.GetNextNo(ItemJnlBatch."No. Series", ItemJnlLine."Posting Date"));
            if not ItemJnlLine.EmptyLine() then
                LastDocNo2 := ItemJnlLine."Document No.";

            if (ItemJnlBatch."Posting No. Series" <> '') and (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::Revaluation) then
                ItemJnlLine."Posting No. Series" := ItemJnlBatch."Posting No. Series";

            MakeRecurringTexts(ItemJnlLine);
            ConstructPostingNumber(ItemJnlLine);

            IsHandled := false;
            OnBeforeOnPostLinesOnBeforePostLineUpdateItemTracking(ItemJnlLine, IsHandled);
            if not IsHandled then
                UpdateItemTracking(ItemJnlLine);

            OnPostLinesOnBeforePostLine(ItemJnlLine, SuppressCommit, WindowIsOpen);

            if ItemJnlLine."Inventory Value Per" <> ItemJnlLine."Inventory Value Per"::" " then
                ItemJnlPostSumLine(ItemJnlLine)
            else
                if ((ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and (ItemJnlLine."Item Charge No." = '')) or
                    ((ItemJnlLine."Invoiced Quantity" <> 0) and (ItemJnlLine.Amount <> 0))
                then begin
                    LineCount := LineCount + 1;
                    if WindowIsOpen then begin
                        Window.Update(3, LineCount);
                        Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
                    end;

                    IsHandled := false;
                    OnBeforePostJnlLine(ItemJnlLine, SuppressCommit, IsHandled);
                    if not IsHandled then begin
                        OriginalQuantity := ItemJnlLine.Quantity;
                        OriginalQuantityBase := ItemJnlLine."Quantity (Base)";
                        if not ItemJnlPostLine.RunWithCheck(ItemJnlLine) then
                            ItemJnlPostLine.CheckItemTracking(ItemJnlLine);

                        OnHandleWhsePutAwayForProdOutput(ItemJnlLine);

                        if ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Revaluation then begin
                            ItemJnlPostLine.CollectTrackingSpecification(TempTrackingSpecification);
                            OnPostLinesBeforePostWhseJnlLine(ItemJnlLine, SuppressCommit);
                            PostWhseJnlLine(ItemJnlLine, OriginalQuantity, OriginalQuantityBase, TempTrackingSpecification);
                            OnPostLinesOnAfterPostWhseJnlLine(ItemJnlLine, SuppressCommit);
                        end;
                    end;
                end;

            OnPostLinesOnAfterPostLine(ItemJnlLine, SuppressCommit);

            if IsPhysInvtCount(ItemJnlTemplate, ItemJnlLine."Phys Invt Counting Period Code", ItemJnlLine."Phys Invt Counting Period Type") then begin
                if not PhysInvtCount then begin
                    PhysInvtCountMgt.InitTempItemSKUList();
                    PhysInvtCount := true;
                end;
                PhysInvtCountMgt.AddToTempItemSKUList(
                    ItemJnlLine."Item No.", ItemJnlLine."Location Code", ItemJnlLine."Variant Code", ItemJnlLine."Phys Invt Counting Period Type");
            end;
        until ItemJnlLineLoop.Next() = 0;

        OnAfterPostLines(ItemJnlLine, ItemRegNo, WhseRegNo);
    end;

    local procedure HandleRecurringLine(var ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlLine2: Record "Item Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleRecurringLine(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        LineCount := 0;
        ItemJnlLine2.CopyFilters(ItemJnlLine);
        ItemJnlLine2.FindSet();
        repeat
            OnHandleRecurringLineOnBeforeItemJnlLine2Loop(ItemJnlLine, ItemJnlLine2, WindowIsOpen);
            LineCount := LineCount + 1;
            if WindowIsOpen then begin
                Window.Update(5, LineCount);
                Window.Update(6, Round(LineCount / NoOfRecords * 10000, 1));
            end;
            if ItemJnlLine2."Posting Date" <> 0D then
                ItemJnlLine2.Validate("Posting Date", CalcDate(ItemJnlLine2."Recurring Frequency", ItemJnlLine2."Posting Date"));
            if (ItemJnlLine2."Recurring Method" = ItemJnlLine2."Recurring Method"::Variable) and
               (ItemJnlLine2."Item No." <> '')
            then begin
                ItemJnlLine2.Quantity := 0;
                ItemJnlLine2."Invoiced Quantity" := 0;
                ItemJnlLine2.Amount := 0;
            end;
            OnHandleRecurringLineOnBeforeItemJnlLineModify(ItemJnlLine2);
            ItemJnlLine2.Modify();
        until ItemJnlLine2.Next() = 0;
    end;

    local procedure HandleNonRecurringLine(var ItemJnlLine: Record "Item Journal Line"; OldEntryType: Enum "Item Ledger Entry Type")
    var
        ItemJnlLine2: Record "Item Journal Line";
        ItemJnlLine3: Record "Item Journal Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        IncrBatchName: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandleNonRecurringLine(ItemJnlLine, IsHandled, OldEntryType);
        if IsHandled then
            exit;

        ItemJnlLine2.CopyFilters(ItemJnlLine);
        ItemJnlLine2.SetFilter("Item No.", '<>%1', '');
        if ItemJnlLine2.FindLast() then;
        // Remember the last line
        ItemJnlLine2."Entry Type" := OldEntryType;

        ItemJnlLine3.Copy(ItemJnlLine);
        OnHandleNonRecurringLineOnAfterCopyItemJnlLine3(ItemJnlLine, ItemJnlLine3);
        RecordLinkManagement.RemoveLinks(ItemJnlLine3);
        ItemJnlLine3.DeleteAll();
        ItemJnlLine3.Reset();
        ItemJnlLine3.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine3.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        if ItemJnlTemplate."Increment Batch Name" then
            if not ItemJnlLine3.FindLast() then begin
                IncrBatchName := IncStr(ItemJnlLine."Journal Batch Name") <> '';
                OnBeforeIncrBatchName(ItemJnlLine, IncrBatchName);
                if IncrBatchName then begin
                    ItemJnlBatch.Delete();
                    IsHandled := false;
                    OnHandleNonRecurringLineOnBeforeSetItemJnlBatchName(ItemJnlTemplate, IsHandled);
                    if not IsHandled then
                        ItemJnlBatch.Name := IncStr(ItemJnlLine."Journal Batch Name");
                    if ItemJnlBatch.Insert() then;
                    ItemJnlLine."Journal Batch Name" := ItemJnlBatch.Name;
                end;
            end;

        OnHandleNonRecurringLineOnInsertNewLine(ItemJnlLine3);

        ItemJnlLine3.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        if (ItemJnlBatch."No. Series" = '') and not ItemJnlLine3.FindLast() and
           not (ItemJnlLine2."Entry Type" in [ItemJnlLine2."Entry Type"::Consumption, ItemJnlLine2."Entry Type"::Output])
        then begin
            ItemJnlLine3.Init();
            ItemJnlLine3."Journal Template Name" := ItemJnlLine."Journal Template Name";
            ItemJnlLine3."Journal Batch Name" := ItemJnlLine."Journal Batch Name";
            ItemJnlLine3."Line No." := 10000;
            ItemJnlLine3.Insert();
            ItemJnlLine3.SetUpNewLine(ItemJnlLine2);
            ItemJnlLine3.Modify();
            OnHandleNonRecurringLineOnAfterItemJnlLineModify(ItemJnlLine3);
        end;
    end;

    local procedure ConstructPostingNumber(var ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeConstructPostingNumber(ItemJnlLine, ItemJnlBatch, LastDocNo, LastPostedDocNo, IsHandled);
        if IsHandled then
            exit;

        if ItemJnlLine."Posting No. Series" = '' then
            ItemJnlLine."Posting No. Series" := ItemJnlBatch."No. Series"
        else
            if not ItemJnlLine.EmptyLine() then
                if ItemJnlLine."Document No." = LastDocNo then
                    ItemJnlLine."Document No." := LastPostedDocNo
                else begin
                    LastDocNo := ItemJnlLine."Document No.";
                    ItemJnlLine."Document No." := NoSeriesBatch.GetNextNo(ItemJnlLine."Posting No. Series", ItemJnlLine."Posting Date");
                    LastPostedDocNo := ItemJnlLine."Document No.";
                end;

        OnAfterConstructPostingNumber(ItemJnlLine);
    end;

    local procedure CheckRecurringLine(var ItemJnlLine2: Record "Item Journal Line")
    var
        NULDF: DateFormula;
    begin
        if ItemJnlLine2."Item No." <> '' then
            if ItemJnlTemplate.Recurring then begin
                ItemJnlLine2.TestField("Recurring Method");
                ItemJnlLine2.TestField("Recurring Frequency");
                if ItemJnlLine2."Recurring Method" = ItemJnlLine2."Recurring Method"::Variable then
                    ItemJnlLine2.TestField(Quantity);
            end else begin
                Clear(NULDF);
                ItemJnlLine2.TestField("Recurring Method", 0);
                ItemJnlLine2.TestField("Recurring Frequency", NULDF);
            end;
    end;

    local procedure MakeRecurringTexts(var ItemJnlLine2: Record "Item Journal Line")
    begin
        if (ItemJnlLine2."Item No." <> '') and (ItemJnlLine2."Recurring Method" <> 0) then
            AccountingPeriod.MakeRecurringTexts(ItemJnlLine2."Posting Date", ItemJnlLine2."Document No.", ItemJnlLine2.Description);
    end;

    local procedure ItemJnlPostSumLine(ItemJnlLine4: Record "Item Journal Line")
    var
        Item: Record Item;
        ItemLedgEntry4: Record "Item Ledger Entry";
        ItemLedgEntry5: Record "Item Ledger Entry";
        Remainder: Decimal;
        RemAmountToDistribute: Decimal;
        RemQuantity: Decimal;
        DistributeCosts: Boolean;
        IncludeExpectedCost: Boolean;
        PostingDate: Date;
        IsLastEntry: Boolean;
        ThrowPostingsExistError, IsHandled : Boolean;
    begin
        IsHandled := false;
        OnBeforeItemJournalPostSumLine(ItemJnlLine, ItemJnlLine4, LineCount, WindowIsOpen, Window, NoOfRecords, ItemJnlPostLine, IsHandled);
        if IsHandled then
            exit;

        DistributeCosts := true;
        RemAmountToDistribute := ItemJnlLine.Amount;
        RemQuantity := ItemJnlLine.Quantity;
        if ItemJnlLine.Amount <> 0 then begin
            LineCount := LineCount + 1;
            if WindowIsOpen then begin
                Window.Update(3, LineCount);
                Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
            end;
            Item.Get(ItemJnlLine4."Item No.");
            OnItemJnlPostSumLineOnAfterGetItem(Item, ItemJnlLine4);
            IncludeExpectedCost :=
                (Item."Costing Method" = Item."Costing Method"::Standard) and
                (ItemJnlLine4."Inventory Value Per" <> ItemJnlLine4."Inventory Value Per"::" ");
            ItemLedgEntry4.Reset();
            ItemLedgEntry4.SetCurrentKey("Item No.", Positive, "Location Code", "Variant Code");
            ItemLedgEntry4.SetRange("Item No.", ItemJnlLine."Item No.");
            ItemLedgEntry4.SetRange(Positive, true);
            PostingDate := ItemJnlLine."Posting Date";

            if (ItemJnlLine4."Location Code" <> '') or
               (ItemJnlLine4."Inventory Value Per" in
                [ItemJnlLine."Inventory Value Per"::Location,
                 ItemJnlLine4."Inventory Value Per"::"Location and Variant"])
            then
                ItemLedgEntry4.SetRange("Location Code", ItemJnlLine."Location Code");
            if (ItemJnlLine."Variant Code" <> '') or
               (ItemJnlLine4."Inventory Value Per" in
                [ItemJnlLine."Inventory Value Per"::Variant,
                 ItemJnlLine4."Inventory Value Per"::"Location and Variant"])
            then
                ItemLedgEntry4.SetRange("Variant Code", ItemJnlLine."Variant Code");
            if ItemLedgEntry4.FindSet() then
                repeat
                    OnItemJnlPostSumLineOnBeforeIncludeEntry(ItemJnlLine4, ItemLedgEntry4, IncludeExpectedCost);
                    if IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) then begin
                        ItemLedgEntry5 := ItemLedgEntry4;

                        ItemJnlLine4."Entry Type" := ItemLedgEntry4."Entry Type";
                        ItemJnlLine4.Quantity := ItemLedgEntry4.CalculateRemQuantity(ItemLedgEntry4."Entry No.", ItemJnlLine."Posting Date");

                        ItemJnlLine4."Quantity (Base)" := ItemJnlLine4.Quantity;
                        ItemJnlLine4."Invoiced Quantity" := ItemJnlLine4.Quantity;
                        ItemJnlLine4."Invoiced Qty. (Base)" := ItemJnlLine4.Quantity;
                        ItemJnlLine4."Location Code" := ItemLedgEntry4."Location Code";
                        ItemJnlLine4."Variant Code" := ItemLedgEntry4."Variant Code";
                        ItemJnlLine4."Applies-to Entry" := ItemLedgEntry4."Entry No.";
                        ItemJnlLine4."Source No." := ItemLedgEntry4."Source No.";
                        ItemJnlLine4."Order Type" := ItemLedgEntry4."Order Type";
                        ItemJnlLine4."Order No." := ItemLedgEntry4."Order No.";
                        ItemJnlLine4."Order Line No." := ItemLedgEntry4."Order Line No.";

                        if ItemJnlLine4.Quantity <> 0 then begin
                            ItemJnlLine4.Amount :=
                              ItemJnlLine."Inventory Value (Revalued)" * ItemJnlLine4.Quantity /
                              ItemJnlLine.Quantity -
                              Round(
                                ItemLedgEntry4.CalculateRemInventoryValue(
                                  ItemLedgEntry4."Entry No.", ItemLedgEntry4.Quantity, ItemJnlLine4.Quantity,
                                  IncludeExpectedCost and not ItemLedgEntry4."Completely Invoiced", PostingDate),
                                GLSetup."Amount Rounding Precision") + Remainder;

                            RemQuantity := RemQuantity - ItemJnlLine4.Quantity;

                            if RemQuantity = 0 then begin
                                if ItemLedgEntry4.Next() > 0 then
                                    repeat
                                        if IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) then begin
                                            RemQuantity := ItemLedgEntry4.CalculateRemQuantity(ItemLedgEntry4."Entry No.", ItemJnlLine."Posting Date");
                                            ThrowPostingsExistError := RemQuantity > 0;
                                            OnItemJnlPostSumLineOnAfterCalcThrowPostingsExistError(ItemJnlLine, RemQuantity, ThrowPostingsExistError);
                                            if ThrowPostingsExistError then
                                                Error(Text008 + Text009, ItemJnlLine4."Item No.");
                                        end;
                                    until ItemLedgEntry4.Next() = 0;

                                ItemJnlLine4.Amount := RemAmountToDistribute;
                                DistributeCosts := false;
                            end else begin
                                repeat
                                    IsLastEntry := ItemLedgEntry4.Next() = 0;
                                until IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) or IsLastEntry;
                                if IsLastEntry or (RemQuantity < 0) then
                                    Error(Text008 + Text009, ItemJnlLine4."Item No.");
                                Remainder := ItemJnlLine4.Amount - Round(ItemJnlLine4.Amount, GLSetup."Amount Rounding Precision");
                                ItemJnlLine4.Amount := Round(ItemJnlLine4.Amount, GLSetup."Amount Rounding Precision");
                                RemAmountToDistribute := RemAmountToDistribute - ItemJnlLine4.Amount;
                            end;
                            ItemJnlLine4."Unit Cost" := ItemJnlLine4.Amount / ItemJnlLine4.Quantity;

                            OnItemJnlPostSumLineOnBeforeCalcAppliedAmount(ItemJnlLine4, ItemLedgEntry4);
                            if ItemJnlLine4.Amount <> 0 then begin
                                if IncludeExpectedCost and not ItemLedgEntry5."Completely Invoiced" then
                                    ItemJnlLine4."Applied Amount" := Round(
                                        ItemJnlLine4.Amount * (ItemLedgEntry5.Quantity - ItemLedgEntry5."Invoiced Quantity") /
                                        ItemLedgEntry5.Quantity,
                                        GLSetup."Amount Rounding Precision")
                                else
                                    ItemJnlLine4."Applied Amount" := 0;
                                OnBeforeItemJnlPostSumLine(ItemJnlLine4, ItemLedgEntry4);
                                ItemJnlPostLine.RunWithCheck(ItemJnlLine4);
                            end;
                        end else begin
                            repeat
                                IsLastEntry := ItemLedgEntry4.Next() = 0;
                            until IncludeEntryInCalc(ItemLedgEntry4, PostingDate, IncludeExpectedCost) or IsLastEntry;
                            if IsLastEntry then
                                Error(Text008 + Text009, ItemJnlLine4."Item No.");
                        end;
                    end else
                        DistributeCosts := ItemLedgEntry4.Next() <> 0;
                until not DistributeCosts;

            if ItemJnlLine."Update Standard Cost" then
                UpdateStdCost();
        end;

        OnAfterItemJnlPostSumLine(ItemJnlLine);
    end;

    local procedure IncludeEntryInCalc(ItemLedgEntry: Record "Item Ledger Entry"; PostingDate: Date; IncludeExpectedCost: Boolean): Boolean
    begin
        if IncludeExpectedCost then
            exit(ItemLedgEntry."Posting Date" in [0D .. PostingDate]);
        exit(ItemLedgEntry."Completely Invoiced" and (ItemLedgEntry."Last Invoice Date" in [0D .. PostingDate]));
    end;

    local procedure UpdateStdCost()
    var
        SKU: Record "Stockkeeping Unit";
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if InventorySetup."Average Cost Calc. Type" = InventorySetup."Average Cost Calc. Type"::Item then
            UpdateItemStdCost()
        else
            if SKU.Get(ItemJnlLine."Location Code", ItemJnlLine."Item No.", ItemJnlLine."Variant Code") then
                UpdateSKUStdCost(SKU)
            else
                UpdateItemStdCost();
    end;

    local procedure UpdateItemStdCost()
    var
        Item: Record Item;
    begin
        Item.Get(ItemJnlLine."Item No.");
        Item.Validate("Standard Cost", ItemJnlLine."Unit Cost (Revalued)");
        SetItemSingleLevelCosts(Item, ItemJnlLine);
        SetItemRolledUpCosts(Item, ItemJnlLine);
        Item."Last Unit Cost Calc. Date" := ItemJnlLine."Posting Date";
        Item.Modify();
    end;

    local procedure UpdateSKUStdCost(var SKU: Record "Stockkeeping Unit")
    begin
        SKU.Validate("Standard Cost", ItemJnlLine."Unit Cost (Revalued)");
        SetSKUSingleLevelCosts(SKU, ItemJnlLine);
        SetSKURolledUpCosts(SKU, ItemJnlLine);
        OnAfterUpdateStdCostSKUValidate(ItemJnlLine, SKU);
        SKU.Modify();
    end;

    local procedure CheckRemainingQty(AppliesToEntryNo: Integer; PostingDate: Date)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RemainingQty: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeCheckRemainingQty(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;
        RemainingQty := ItemLedgerEntry.CalculateRemQuantity(AppliesToEntryNo, PostingDate);

        if RemainingQty <> ItemJnlLine.Quantity then
            Error(Text008 + Text009, ItemJnlLine."Item No.");
    end;

    procedure PostWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; OriginalQuantity: Decimal; OriginalQuantityBase: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    var
        Item: Record Item;
        ItemJnlTemplateType: Option;
        IsHandled: Boolean;
    begin
        Item.SetLoadFields(Type);
        if Item.Get(ItemJnlLine."Item No.") then
            if Item.IsNonInventoriableType() then
                exit;

        ItemJnlLine.Quantity := OriginalQuantity;
        ItemJnlLine."Quantity (Base)" := OriginalQuantityBase;
        GetLocation(ItemJnlLine."Location Code");
        ItemJnlTemplateType := ItemJnlTemplate.Type.AsInteger();
        IsHandled := false;
        OnPostWhseJnlLineOnBeforeCreateWhseJnlLines(ItemJnlLine, ItemJnlTemplateType, IsHandled);
        if IsHandled then
            exit;
        if not (ItemJnlLine."Entry Type" in [ItemJnlLine."Entry Type"::Consumption, ItemJnlLine."Entry Type"::Output]) then
            PostWhseJnlLines(ItemJnlLine, TempTrackingSpecification, "Item Journal Template Type".FromInteger(ItemJnlTemplateType), false);

        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then begin
            GetLocation(ItemJnlLine."New Location Code");
            PostWhseJnlLines(ItemJnlLine, TempTrackingSpecification, "Item Journal Template Type".FromInteger(ItemJnlTemplateType), true);
        end;
    end;

    local procedure PostWhseJnlLines(ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemJnlTemplateType: Enum "Item Journal Template Type"; ToTransfer: Boolean)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostWhseJnlLines(ItemJnlLine, TempTrackingSpecification, ItemJnlTemplateType, ToTransfer, IsHandled);
        if IsHandled then
            exit;

        if Location."Bin Mandatory" then
            if WMSMgmt.CreateWhseJnlLine(ItemJnlLine, ItemJnlTemplateType.AsInteger(), WhseJnlLine, ToTransfer) then begin
                ItemTrackingMgt.SplitWhseJnlLine(WhseJnlLine, TempWhseJnlLine, TempTrackingSpecification, ToTransfer);
                if TempWhseJnlLine.FindSet() then
                    repeat
                        WMSMgmt.CheckWhseJnlLine(TempWhseJnlLine, 1, 0, ToTransfer);
                        IsHandled := false;
                        OnBeforeWhseJnlPostLineRun(ItemJnlLine, TempWhseJnlLine, IsHandled);
                        if not IsHandled then
                            WhseJnlPostLine.Run(TempWhseJnlLine);
                    until TempWhseJnlLine.Next() = 0;
                OnAfterPostWhseJnlLine(ItemJnlLine, SuppressCommit);
            end;
    end;

    local procedure CheckWMSBin(ItemJnlLine: Record "Item Journal Line")
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWMSBin(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if Item.Get(ItemJnlLine."Item No.") then
            if Item.IsNonInventoriableType() then
                exit;

        GetLocation(ItemJnlLine."Location Code");
        if Location."Bin Mandatory" then
            WhseTransaction := true;
        case ItemJnlLine."Entry Type" of
            ItemJnlLine."Entry Type"::Purchase, ItemJnlLine."Entry Type"::Sale,
            ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemJnlLine."Entry Type"::"Negative Adjmt.":
                if Location."Directed Put-away and Pick" then
                    WMSMgmt.CheckAdjmtBin(
                        Location, ItemJnlLine.Quantity,
                        (ItemJnlLine."Entry Type" in
                        [ItemJnlLine."Entry Type"::Purchase,
                        ItemJnlLine."Entry Type"::"Positive Adjmt."]));
            ItemJnlLine."Entry Type"::Transfer:
                begin
                    if Location."Directed Put-away and Pick" then
                        WMSMgmt.CheckAdjmtBin(Location, -ItemJnlLine.Quantity, false);
                    GetLocation(ItemJnlLine."New Location Code");
                    if Location."Directed Put-away and Pick" then
                        WMSMgmt.CheckAdjmtBin(Location, ItemJnlLine.Quantity, true);
                    if Location."Bin Mandatory" then
                        WhseTransaction := true;
                end;
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);

        OnAfterGetLocation(Location, ItemJnlLine);
    end;

    procedure GetWhseRegNo(): Integer
    begin
        exit(WhseRegNo);
    end;

    procedure GetItemRegNo(): Integer
    begin
        exit(ItemRegNo);
    end;

    local procedure IsPhysInvtCount(ItemJnlTemplate2: Record "Item Journal Template"; PhysInvtCountingPeriodCode: Code[10]; PhysInvtCountingPeriodType: Option " ",Item,SKU): Boolean
    begin
        exit(
          (ItemJnlTemplate2.Type = ItemJnlTemplate2.Type::"Phys. Inventory") and
          (PhysInvtCountingPeriodType <> PhysInvtCountingPeriodType::" ") and
          (PhysInvtCountingPeriodCode <> ''));
    end;

    local procedure CheckItemAvailability(var ItemJnlLine: Record "Item Journal Line")
    var
        Item: Record Item;
        TempSKU: Record "Stockkeeping Unit" temporary;
        ItemJnlLine2: Record "Item Journal Line";
        ConfirmManagement: Codeunit "Confirm Management";
        QtyinItemJnlLine: Decimal;
        AvailableQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemAvailabilityHandled(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine2.CopyFilters(ItemJnlLine);
        if ItemJnlLine2.FindSet() then
            repeat
                if ItemJnlLine2.IsNotInternalWhseMovement() then
                    if not TempSKU.Get(ItemJnlLine2."Location Code", ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code") then
                        InsertTempSKU(TempSKU, ItemJnlLine2);
                OnBeforeCheckItemAvailability(ItemJnlLine2, TempSKU);
            until ItemJnlLine2.Next() = 0;

        if TempSKU.FindSet() then
            repeat
                QtyinItemJnlLine := CalcRequiredQty(TempSKU, ItemJnlLine2);
                if QtyinItemJnlLine < 0 then begin
                    Item.Get(TempSKU."Item No.");
                    Item.SetFilter("Location Filter", TempSKU."Location Code");
                    Item.SetFilter("Variant Filter", TempSKU."Variant Code");
                    Item.CalcFields("Reserved Qty. on Inventory", "Net Change");
                    AvailableQty := Item."Net Change" - Item."Reserved Qty. on Inventory";
                    OnCheckItemAvailabilityOnAfterSetAvailableQty(TempSKU, ItemJnlLine2, AvailableQty);

                    if (Item."Reserved Qty. on Inventory" > 0) and (AvailableQty < Abs(QtyinItemJnlLine)) and not InvtSetup."Prevent Negative Inventory" then
                        if not ConfirmManagement.GetResponseOrDefault(
                            StrSubstNo(
                                Text010, TempSKU.FieldCaption("Item No."), TempSKU."Item No.", TempSKU.FieldCaption("Location Code"),
                                TempSKU."Location Code", TempSKU.FieldCaption("Variant Code"), TempSKU."Variant Code"), true)
                        then
                            Error('');
                end;
            until TempSKU.Next() = 0;
    end;

    local procedure InsertTempSKU(var TempSKU: Record "Stockkeeping Unit" temporary; ItemJnlLine: Record "Item Journal Line")
    begin
        TempSKU.Init();
        TempSKU."Location Code" := ItemJnlLine."Location Code";
        TempSKU."Item No." := ItemJnlLine."Item No.";
        TempSKU."Variant Code" := ItemJnlLine."Variant Code";
        OnBeforeInsertTempSKU(TempSKU, ItemJnlLine);
        TempSKU.Insert();
    end;

    local procedure CalcRequiredQty(TempSKU: Record "Stockkeeping Unit" temporary; var ItemJnlLine: Record "Item Journal Line"): Decimal
    var
        SignFactor: Integer;
        QtyinItemJnlLine: Decimal;
    begin
        QtyinItemJnlLine := 0;
        ItemJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Item No.", "Location Code", "Variant Code");
        ItemJnlLine.SetRange("Item No.", TempSKU."Item No.");
        ItemJnlLine.SetRange("Location Code", TempSKU."Location Code");
        ItemJnlLine.SetRange("Variant Code", TempSKU."Variant Code");
        ItemJnlLine.FindSet();
        repeat
            if (ItemJnlLine."Entry Type" in
                [ItemJnlLine."Entry Type"::Sale,
                 ItemJnlLine."Entry Type"::"Negative Adjmt.",
                 ItemJnlLine."Entry Type"::Consumption]) or
               (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer)
            then
                SignFactor := -1
            else
                SignFactor := 1;
            QtyinItemJnlLine += ItemJnlLine."Quantity (Base)" * SignFactor;
        until ItemJnlLine.Next() = 0;
        exit(QtyinItemJnlLine);
    end;

    local procedure SetItemSingleLevelCosts(var Item: Record Item; ItemJournalLine: Record "Item Journal Line")
    begin
        Item."Single-Level Material Cost" := ItemJournalLine."Single-Level Material Cost";
        Item."Single-Level Capacity Cost" := ItemJournalLine."Single-Level Capacity Cost";
        Item."Single-Level Subcontrd. Cost" := ItemJournalLine."Single-Level Subcontrd. Cost";
        Item."Single-Level Cap. Ovhd Cost" := ItemJournalLine."Single-Level Cap. Ovhd Cost";
        Item."Single-Level Mfg. Ovhd Cost" := ItemJournalLine."Single-Level Mfg. Ovhd Cost";
        Item."Single-Lvl Mat. Non-Invt. Cost" := ItemJournalLine."Single-Lvl Mat. Non-Invt. Cost";
    end;

    local procedure SetItemRolledUpCosts(var Item: Record Item; ItemJournalLine: Record "Item Journal Line")
    begin
        Item."Rolled-up Material Cost" := ItemJournalLine."Rolled-up Material Cost";
        Item."Rolled-up Capacity Cost" := ItemJournalLine."Rolled-up Capacity Cost";
        Item."Rolled-up Subcontracted Cost" := ItemJournalLine."Rolled-up Subcontracted Cost";
        Item."Rolled-up Mfg. Ovhd Cost" := ItemJournalLine."Rolled-up Mfg. Ovhd Cost";
        Item."Rolled-up Cap. Overhead Cost" := ItemJournalLine."Rolled-up Cap. Overhead Cost";
        Item."Rolled-up Mat. Non-Invt. Cost" := ItemJournalLine."Rolled-up Mat. Non-Invt. Cost";
    end;

    local procedure SetSKUSingleLevelCosts(var SKU: Record "Stockkeeping Unit"; ItemJournalLine: Record "Item Journal Line")
    begin
        SKU."Single-Level Material Cost" := ItemJournalLine."Single-Level Material Cost";
        SKU."Single-Level Capacity Cost" := ItemJournalLine."Single-Level Capacity Cost";
        SKU."Single-Level Subcontrd. Cost" := ItemJournalLine."Single-Level Subcontrd. Cost";
        SKU."Single-Level Cap. Ovhd Cost" := ItemJournalLine."Single-Level Cap. Ovhd Cost";
        SKU."Single-Level Mfg. Ovhd Cost" := ItemJournalLine."Single-Level Mfg. Ovhd Cost";
        SKU."Single-Lvl Mat. Non-Invt. Cost" := ItemJournalLine."Single-Lvl Mat. Non-Invt. Cost";
    end;

    local procedure SetSKURolledUpCosts(var SKU: Record "Stockkeeping Unit"; ItemJournalLine: Record "Item Journal Line")
    begin
        SKU."Rolled-up Material Cost" := ItemJournalLine."Rolled-up Material Cost";
        SKU."Rolled-up Capacity Cost" := ItemJournalLine."Rolled-up Capacity Cost";
        SKU."Rolled-up Subcontracted Cost" := ItemJournalLine."Rolled-up Subcontracted Cost";
        SKU."Rolled-up Mfg. Ovhd Cost" := ItemJournalLine."Rolled-up Mfg. Ovhd Cost";
        SKU."Rolled-up Cap. Overhead Cost" := ItemJournalLine."Rolled-up Cap. Overhead Cost";
        SKU."Rolled-up Mat. Non-Invt. Cost" := ItemJournalLine."Rolled-up Mat. Non-Invt. Cost";
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure UpdateItemTracking(var ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateItemTracking(ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJnlBatch."Item Tracking on Lines" then
            ItemJournalLine.CreateItemTrackingLines(false);
        ItemJournalLine.ClearTracking();
        ItemJournalLine.ClearDates();
    end;

    local procedure MakeInventoryAdjustment()
    begin
        InvtAdjmtHandler.MakeAutomaticInventoryAdjustment(ItemsToAdjust);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnBeforePostValueEntryToGL', '', false, false)]
    local procedure OnBeforePostValueEntryToGL(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
        if InvtSetup.UseLegacyPosting() then
            exit;
        PostponedValueEntries.Add(ValueEntry."Entry No.");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertItemLedgEntry', '', false, false)]
    local procedure OnAfterInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer; GlobalValueEntry: Record "Value Entry"; TransferItem: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
        if ItemLedgerEntry."Item Register No." <> 0 then
            ItemRegNo := ItemLedgerEntry."Item Register No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertValueEntry', '', false, false)]
    local procedure OnAfterInsertValueEntry(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
        if ValueEntry."Item Register No." <> 0 then
            ItemRegNo := ValueEntry."Item Register No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertPhysInventoryEntry', '', false, false)]
    local procedure OnAfterInsertPhysInventoryEntry(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        if PhysInventoryLedgerEntry."Item Register No." <> 0 then
            ItemRegNo := PhysInventoryLedgerEntry."Item Register No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterInsertCapLedgEntry', '', false, false)]
    local procedure OnAfterInsertCapLedgEntry(var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        if CapLedgEntry."Item Register No." <> 0 then
            ItemRegNo := CapLedgEntry."Item Register No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register Line", 'OnAfterInsertWhseEntry', '', false, false)]
    local procedure OnAfterInsertWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        if WarehouseEntry."Warehouse Register No." <> 0 then
            WhseRegNo := WarehouseEntry."Warehouse Register No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem', '', false, false)]
    local procedure OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem(var Item2: Record Item)
    begin
        if InvtSetup.UseLegacyPosting() then
            exit;

        if not ItemsToAdjust.Contains(Item2."No.") then
            ItemsToAdjust.Add(Item2."No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckLines(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckJnlLine(var ItemJournalLine: Record "Item Journal Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; ItemRegNo: Integer; WhseRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConstructPostingNumber(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyRegNos(var ItemJournalLine: Record "Item Journal Line"; var ItemRegNo: Integer; var WhseRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLocation(var Location: Record Location; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemJnlPostSumLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(var ItemJournalLine: Record "Item Journal Line"; var ItemRegNo: Integer; var WhseRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostLines(var ItemJournalLine: Record "Item Journal Line"; var ItemRegNo: Integer; var WhseRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostJnlLines(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemRegNo: Integer; WhseRegNo: Integer; var WindowIsOpen: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostWhseJnlLine(ItemJournalLine: Record "Item Journal Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateAnalysisViews(var ItemRegister: Record "Item Register")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailability(var ItemJournalLine: Record "Item Journal Line"; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemAvailabilityHandled(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLines(var ItemJnlLine: Record "Item Journal Line"; var WindowIsOpen: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWMSBin(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenProgressDialog(var ItemJnlLine: Record "Item Journal Line"; var Window: Dialog; var WindowIsOpen: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostWhseJnlLines(ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemJnlTemplateType: Enum "Item Journal Template Type"; ToTransfer: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRaiseExceedLengthError(var ItemJournalBatch: Record "Item Journal Batch"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseJnlPostLineRun(ItemJournalLine: Record "Item Journal Line"; var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterPostWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesBeforePostWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; CommitIsSuppressed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleNonRecurringLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean; var OldEntryType: Enum "Item Ledger Entry Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleRecurringLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIncrBatchName(var ItemJournalLine: Record "Item Journal Line"; var IncrBatchName: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemJnlPostSumLine(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDeleteLines(var ItemJournalLine: Record "Item Journal Line"; ItemRegNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforePostLines(var ItemJournalLine: Record "Item Journal Line"; var NoOfRecords: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleNonRecurringLineOnInsertNewLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostSumLineOnAfterGetItem(var Item: Record Item; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostSumLineOnAfterCalcThrowPostingsExistError(var ItemJournalLine: Record "Item Journal Line"; RemQuantity: Decimal; var ThrowPostingsExistError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostSumLineOnBeforeIncludeEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; var IncludeExpectedCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostSumLineOnBeforeCalcAppliedAmount(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterPostLine(var ItemJournalLine: Record "Item Journal Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforePostLine(var ItemJournalLine: Record "Item Journal Line"; var SuppressCommit: Boolean; var WindowIsOpen: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostWhseJnlLineOnBeforeCreateWhseJnlLines(ItemJournalLine: Record "Item Journal Line"; var ItemJnlTemplateType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleRecurringLineOnBeforeItemJnlLineModify(var ItemJournalLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleRecurringLineOnBeforeItemJnlLine2Loop(var ItemJnlLine: Record "Item Journal Line"; var ItemJnlLine2: Record "Item Journal Line"; var WindowIsOpen: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempSKU(var TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; ItemJournalLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleNonRecurringLineOnAfterItemJnlLineModify(var ItemJournalLine: Record "Item Journal Line");
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeSelfReservedQty(SKU: Record "Stockkeeping Unit"; ItemJnlLine2: Record "Item Journal Line"; var Result: Decimal; var IsHandled: Boolean)
    begin
        OnBeforeSelfReservedQty(SKU, ItemJnlLine2, Result, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostBatch', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelfReservedQty(SKU: Record "Stockkeeping Unit"; ItemJnlLine: Record "Item Journal Line"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnHandleNonRecurringLineOnBeforeSetItemJnlBatchName(ItemJnlTemplate: Record "Item Journal Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleNonRecurringLineOnAfterCopyItemJnlLine3(var ItemJournalLine: Record "Item Journal Line"; var ItemJournalLine3: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJnlLine(var ItemJournalLine: Record "Item Journal Line"; SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostJnlLine(var ItemJournalLine: Record "Item Journal Line"; SuppressCommit: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConstructPostingNumber(var ItemJournalLine: Record "Item Journal Line"; ItemJnlBatch: Record "Item Journal Batch"; var LastDocNo: Code[20]; var LastPostedDocNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemTracking(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemJournalPostSumLine(var ItemJnlLine: Record "Item Journal Line"; var ItemJnlLine4: Record "Item Journal Line"; var LineCount: Integer; WindowIsOpen: Boolean; var Window: Dialog; NoOfRecords: Integer; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPostLinesOnBeforePostLineUpdateItemTracking(var ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateStdCostSKUValidate(var ItemJnlLine: Record "Item Journal Line"; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckRemainingQty(var ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnHandleWhsePutAwayForProdOutput(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [InternalEvent(false)]
    local procedure OnCheckItemAvailabilityOnAfterSetAvailableQty(var TempSKU: Record "Stockkeeping Unit" temporary; var ItemJnlLine: Record "Item Journal Line"; var AvailableQty: Decimal)
    begin
    end;
}

