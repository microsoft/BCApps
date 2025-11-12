// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Posting;

using Microsoft.Assembly.Document;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Journal;

codeunit 22 "Item Jnl.-Post Line"
{
    Permissions = TableData Item = rimd,
                  TableData "Item Ledger Entry" = rimd,
                  TableData "Item Register" = rimd,
                  TableData "Phys. Inventory Ledger Entry" = rimd,
                  TableData "Item Application Entry" = rimd,
#if not CLEAN28
                  TableData Microsoft.Manufacturing.Document."Prod. Order Capacity Need" = rimd,
#endif
                  TableData "Stockkeeping Unit" = rimd,
                  TableData "Value Entry" = rimd,
                  TableData "Avg. Cost Adjmt. Entry Point" = rim,
                  TableData "Post Value Entry to G/L" = ri,
                  TableData Microsoft.Manufacturing.Capacity."Capacity Ledger Entry" = rimd,
                  TableData "Inventory Adjmt. Entry (Order)" = rim,
                  TableData "Job Planning Line" = r;

    TableNo = "Item Journal Line";

    trigger OnRun()
    begin
        GetGLSetup();
        RunWithCheck(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        NewLocation: Record Location;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        GlobalItemLedgEntry: Record "Item Ledger Entry";
        OldItemLedgEntry: Record "Item Ledger Entry";
        ItemReg: Record "Item Register";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlLineOrigin: Record "Item Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GenPostingSetup: Record "General Posting Setup";
        ItemApplnEntry: Record "Item Application Entry";
        GlobalValueEntry: Record "Value Entry";
        DirCostValueEntry: Record "Value Entry";
        SKU: Record "Stockkeeping Unit";
        CurrExchRate: Record "Currency Exchange Rate";
        GlobalItemTrackingCode: Record "Item Tracking Code";
        GlobalItemTrackingSetup: Record "Item Tracking Setup";
        TempSplitItemJnlLine: Record "Item Journal Line" temporary;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempValueEntryRelation: Record "Value Entry Relation" temporary;
        TempItemEntryRelation: Record "Item Entry Relation" temporary;
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        TempTouchedItemLedgerEntries: Record "Item Ledger Entry" temporary;
        TempItemApplnEntryHistory: Record "Item Application Entry History" temporary;
        PrevAppliedItemLedgEntry: Record "Item Ledger Entry";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        ItemJnlCheckLine: Codeunit "Item Jnl.-Check Line";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ItemJnlLineReserve: Codeunit "Item Jnl. Line-Reserve";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        InventoryPostingToGL: Codeunit "Inventory Posting To G/L";
        AvgCostEntryPointHandler: Codeunit "Avg. Cost Entry Point Handler";
        ACYMgt: Codeunit "Additional-Currency Management";
        ItemLedgEntryNo: Integer;
        PhysInvtEntryNo: Integer;
        CapLedgEntryNo: Integer;
        ValueEntryNo: Integer;
        ItemApplnEntryNo: Integer;
        TotalAppliedQty: Decimal;
        OverheadAmount: Decimal;
        VarianceAmount: Decimal;
        OverheadAmountACY: Decimal;
        VarianceAmountACY: Decimal;
        QtyPerUnitOfMeasure: Decimal;
        RoundingResidualAmount: Decimal;
        RoundingResidualAmountACY: Decimal;
        InvtSetupRead: Boolean;
        GLSetupRead: Boolean;
        SKUExists: Boolean;
        AverageTransfer: Boolean;
        PostponeReservationHandling: Boolean;
        ProdOrderCompModified: Boolean;
        VarianceRequired: Boolean;
        LastOperation: Boolean;
        DisableItemTracking: Boolean;
        CalledFromInvtPutawayPick: Boolean;
        CalledFromAdjustment: Boolean;
        PostToGL: Boolean;
        IsServUndoConsumption: Boolean;
        SkipRetrieveItemTracking: Boolean;
        SkipApplicationCheck: Boolean;
        CalledFromApplicationWorksheet: Boolean;
        SkipSerialNoQtyValidation: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Reserved item %1 is not on inventory.';
        Text004: Label 'is too low';
        TrackingSpecificationMissingErr: Label 'Tracking Specification is missing.';
        Text012: Label 'Item %1 must be reserved.';
        Text014: Label 'Serial No. %1 is already on inventory.';
        SerialNoRequiredErr: Label 'You must assign a serial number for item %1.', Comment = '%1 - Item No.';
        LotNoRequiredErr: Label 'You must assign a lot number for item %1.', Comment = '%1 - Item No.';
        LineNoTxt: Label ' Line No. = ''%1''.', Comment = '%1 - Line No.';
        Text017: Label ' is before the posting date.';
        Text018: Label 'Item Tracking Serial No. %1 Lot No. %2 for Item No. %3 Variant %4 cannot be fully applied.';
        Text022: Label 'You cannot apply %1 to %2 on the same item %3 on Production Order %4.';
        Text100: Label 'Fatal error when retrieving Tracking Specification.';
        Text99000000: Label 'must not be filled out when reservations exist';
        CannotUnapplyCorrEntryErr: Label 'Entries applied to a Correction entry cannot be unapplied.';
        CannotUnapplyItemLedgEntryErr: Label 'You cannot proceed with the posting as it will result in negative inventory for item %1. \Item ledger entry %2 cannot be left unapplied.', Comment = '%1 - Item no., %2 - Item ledger entry no.';
        Text023: Label 'Entries applied to an Outbound Transfer cannot be unapplied.';
        Text024: Label 'Entries applied to a Drop Shipment Order cannot be unapplied.';
        Text027: Label 'A fixed application was not unapplied and this prevented the reapplication. Use the Application Worksheet to remove the applications.';
        Text01: Label 'Checking for open entries.';
        Text029: Label '%1 %2 for %3 %4 is reserved for %5.';
        Text030: Label 'The quantity that you are trying to invoice is larger than the quantity in the item ledger with the entry number %1.';
        Text033: Label 'Quantity must be -1, 0 or 1 when Serial No. is stated.';
        PostToGlLbl: Label 'Posting to G/L    #1#####', Comment = '%1 is an integer value';
#pragma warning restore AA0074
#pragma warning restore AA0470

    /// <summary>
    /// Posts the provided item journal line. The line is copied to a global variable. A check is performed to ensure the Item and Variant are not blocked.
    /// </summary>
    /// <param name="ItemJnlLine2">Item journal line to post.</param>
    /// <returns>True if item journal line was posted, otherwise false.</returns>
    procedure RunWithCheck(var ItemJnlLine2: Record "Item Journal Line"): Boolean
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        TrackingSpecExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunWithCheck(ItemJnlLine2, CalledFromAdjustment, CalledFromInvtPutawayPick, CalledFromApplicationWorksheet, PostponeReservationHandling, IsHandled);
        if IsHandled then
            exit;
        if ItemReg."No." = 0 then  // first time in this transaction?
            SequenceNoMgt.ClearSequenceNoCheck();

        PrepareItem(ItemJnlLine2);
        TrackingSpecExists := ItemTrackingMgt.RetrieveItemTracking(ItemJnlLine2, TempTrackingSpecification);
        OnRunWithCheckOnAfterRetrieveItemTracking(ItemJnlLine2, TempTrackingSpecification, TrackingSpecExists, PostponeReservationHandling);
        exit(PostSplitJnlLine(ItemJnlLine2, TrackingSpecExists));
    end;

    /// <summary>
    /// Posts the item journal line. Item journal lines are split before posting based on item tracking specification.
    /// </summary>
    /// <param name="ItemJnlLine2">Item journal line to post.</param>
    /// <param name="ReservationEntry">Return value: Get the set of reservation entries used in posting.</param>
    /// <returns>True if item journal line was posted, otherwise false.</returns>
    procedure RunPostWithReservation(var ItemJnlLine2: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry") ItemJournalLinePosted: Boolean
    var
        TrackingSpecExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunPostWithReservation(ItemJnlLine2, ReservationEntry, ItemJournalLinePosted, IsHandled);
        if IsHandled then
            exit(ItemJournalLinePosted);

        PrepareItem(ItemJnlLine2);

        ReservationEntry.Reset();
        TrackingSpecExists :=
          ItemTrackingMgt.RetrieveItemTrackingFromReservEntry(ItemJnlLine2, ReservationEntry, TempTrackingSpecification);

        exit(PostSplitJnlLine(ItemJnlLine2, TrackingSpecExists));
    end;

    local procedure "Code"()
    var
        xItemLedgEntryNo: Integer;
        xItemApplnEntryNo: Integer;
        xValueEntryNo: Integer;
        IsHandled: Boolean;
    begin
        xItemLedgEntryNo := ItemLedgEntryNo;
        xItemApplnEntryNo := ItemApplnEntryNo;
        xValueEntryNo := ValueEntryNo;
        OnBeforePostItemJnlLine(ItemJnlLine, CalledFromAdjustment, CalledFromInvtPutawayPick, ItemReg, ItemLedgEntryNo, ValueEntryNo, ItemApplnEntryNo);
        ValidateSequenceNo(ItemLedgEntryNo, xItemLedgEntryNo, Database::"Item Ledger Entry");
        ValidateSequenceNo(ItemApplnEntryNo, xItemApplnEntryNo, Database::"Item Application Entry");
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");

        if ItemJnlLine.EmptyLine() and not ItemJnlLine.Correction and not ItemJnlLine.Adjustment then
            if not ItemJnlLine.IsValueEntryForDeletedItem() then
                exit;

        ItemJnlCheckLine.SetCalledFromInvtPutawayPick(CalledFromInvtPutawayPick);
        ItemJnlCheckLine.SetCalledFromAdjustment(CalledFromAdjustment);

        OnCodeOnBeforeRunCheck(ItemJnlCheckLine, ItemJnlLine);
        ItemJnlCheckLine.RunCheck(ItemJnlLine);
        OnCodeOnAfterRunCheck(ItemJnlLine);

        if ItemJnlLine."Document Date" = 0D then
            ItemJnlLine."Document Date" := ItemJnlLine."Posting Date";

        if ItemJnlLine."VAT Reporting Date" = 0D then
            ItemJnlLine."VAT Reporting Date" := GLSetup.GetVATDate(ItemJnlLine."Posting Date", ItemJnlLine."Document Date");

        if (ItemLedgEntryNo = 0) and InvtSetup.UseLegacyPosting() then begin
            GlobalItemLedgEntry.LockTable();
            ItemLedgEntryNo := GlobalItemLedgEntry.GetLastEntryNo();
            GlobalItemLedgEntry."Entry No." := ItemLedgEntryNo;
        end;
        InitValueEntryNo();

        GetInvtSetup();
        if not CalledFromAdjustment then
            PostToGL := InvtSetup."Automatic Cost Posting";
        OnCheckPostingCostToGL(PostToGL);

        IsHandled := false;
        OnCodeOnBeforeCheckItemTracking(ItemJnlLine, DisableItemTracking, IsHandled, TempTrackingSpecification, GlobalItemTrackingSetup);
        if not IsHandled then
            if GlobalItemTrackingSetup.TrackingRequired() and (ItemJnlLine."Quantity (Base)" <> 0) and
               (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and
               not DisableItemTracking and not ItemJnlLine.Adjustment and
               not ItemJnlLine.Subcontracting and not ItemJnlLine.IsAssemblyResourceConsumpLine()
            then
                CheckItemTracking(ItemJnlLine);

        if ItemJnlLine.Correction and not ItemJnlLine.Subcontracting then
            UndoQuantityPosting();

        if (ItemJnlLine."Entry Type" in
            [ItemJnlLine."Entry Type"::Consumption, ItemJnlLine."Entry Type"::Output, ItemJnlLine."Entry Type"::"Assembly Consumption", ItemJnlLine."Entry Type"::"Assembly Output"]) and
           not (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::Revaluation) and
           not ItemJnlLine.OnlyStopTime()
        then begin
            case ItemJnlLine."Entry Type" of
                ItemJnlLine."Entry Type"::"Assembly Consumption", ItemJnlLine."Entry Type"::"Assembly Output":
                    ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Assembly);
                ItemJnlLine."Entry Type"::Consumption, ItemJnlLine."Entry Type"::Output:
                    ItemJnlLine.TestField("Order Type", ItemJnlLine."Order Type"::Production);
            end;

            IsHandled := false;
            OnCodeOnBeforeTestOrder(ItemJnlLine, IsHandled);
            if not IsHandled then begin
                ItemJnlLine.TestField("Order No.");
                if ItemJnlLine.IsAssemblyOutputLine() then
                    ItemJnlLine.TestField("Order Line No.", 0)
                else
                    ItemJnlLine.TestField("Order Line No.");
            end;
        end;

        GetGeneralPostingSetup(ItemJnlLine);

        if ItemJnlLine."Qty. per Unit of Measure" = 0 then
            ItemJnlLine."Qty. per Unit of Measure" := 1;
        if ItemJnlLine."Qty. per Cap. Unit of Measure" = 0 then
            ItemJnlLine."Qty. per Cap. Unit of Measure" := 1;

        OnCodeOnBeforeSetQuantity(ItemJnlLine);

        ItemJnlLine.Quantity := ItemJnlLine."Quantity (Base)";
        ItemJnlLine."Invoiced Quantity" := ItemJnlLine."Invoiced Qty. (Base)";

        if not ItemJnlLine.Subcontracting and
           ((ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Output) or
            ItemJnlLine.IsAssemblyResourceConsumpLine())
        then
            QtyPerUnitOfMeasure := ItemJnlLine."Qty. per Cap. Unit of Measure"
        else
            QtyPerUnitOfMeasure := ItemJnlLine."Qty. per Unit of Measure";

        OnCodeOnAfterCalcQtyPerUnitOfMeasure(ItemJnlLine, ItemJnlLine.Subcontracting, QtyPerUnitOfMeasure);

        RoundingResidualAmount := 0;
        RoundingResidualAmountACY := 0;
        RoundingResidualAmount := ItemJnlLine.Quantity *
          (ItemJnlLine."Unit Cost" / QtyPerUnitOfMeasure - Round(ItemJnlLine."Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision"));
        RoundingResidualAmountACY := ItemJnlLine.Quantity *
          (ItemJnlLine."Unit Cost (ACY)" / QtyPerUnitOfMeasure - Round(ItemJnlLine."Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision"));

        ItemJnlLine."Unit Amount" := Round(
            ItemJnlLine."Unit Amount" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
        ItemJnlLine."Unit Cost" := Round(
            ItemJnlLine."Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
        ItemJnlLine."Unit Cost (ACY)" := Round(
            ItemJnlLine."Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision");

        OverheadAmount := 0;
        VarianceAmount := 0;
        OverheadAmountACY := 0;
        VarianceAmountACY := 0;
        VarianceRequired := false;
        LastOperation := false;

        OnBeforePostLineByEntryType(ItemJnlLine, CalledFromAdjustment, CalledFromInvtPutawayPick);

        case true of
            ItemJnlLine.IsAssemblyResourceConsumpLine():
                PostAssemblyResourceConsump();
            ItemJnlLine.Adjustment,
            ItemJnlLine."Value Entry Type" in [ItemJnlLine."Value Entry Type"::Rounding, ItemJnlLine."Value Entry Type"::Revaluation],
            ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Assembly Consumption",
            ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Assembly Output":
                PostItem();
            ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Consumption:
                PostConsumption(ItemJnlLine);
            ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Output:
                PostOutput(ItemJnlLine);
            not ItemJnlLine.Correction:
                PostItem();
        end;
        // Entry no. is returned to shipment/receipt
        if ItemJnlLine.Subcontracting then
            ItemJnlLine."Item Shpt. Entry No." := CapLedgEntryNo
        else
            ItemJnlLine."Item Shpt. Entry No." := GlobalItemLedgEntry."Entry No.";

        xItemLedgEntryNo := ItemLedgEntryNo;
        xItemApplnEntryNo := ItemApplnEntryNo;
        xValueEntryNo := ValueEntryNo;
        OnAfterPostItemJnlLine(ItemJnlLine, GlobalItemLedgEntry, ValueEntryNo, InventoryPostingToGL, CalledFromAdjustment, CalledFromInvtPutawayPick, ItemReg, ItemLedgEntryNo, ItemApplnEntryNo, WhseJnlRegisterLine);
        ValidateSequenceNo(ItemLedgEntryNo, xItemLedgEntryNo, Database::"Item Ledger Entry");
        ValidateSequenceNo(ItemApplnEntryNo, xItemApplnEntryNo, Database::"Item Application Entry");
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");
    end;

    /// <summary>
    /// Splits the item journal line into multiple lines based on item tracking specification and posts them.
    /// <remarks>
    /// After posting, corrects the valuation date of output entries in the item ledger 
    /// based on the maximum consumption valuation date.
    /// </remarks>
    /// </summary>
    /// <param name="ItemJnlLineToPost">Item journal line to post.</param>
    /// <param name="TrackingSpecExists">True, if item tracking exists, otherwise false.</param>
    /// <returns>True if item journal line was posted, otherwise false.</returns>
    procedure PostSplitJnlLine(var ItemJnlLineToPost: Record "Item Journal Line"; TrackingSpecExists: Boolean): Boolean
    var
        PostItemJnlLine: Boolean;
    begin
        PostItemJnlLine := SetupSplitJnlLine(ItemJnlLineToPost, TrackingSpecExists);
        if not PostItemJnlLine then
            PostItemJnlLine := IsNotInternalWhseMovement(ItemJnlLineToPost);

        OnPostSplitJnlLineOnBeforeSplitJnlLine(ItemJnlLine, ItemJnlLineToPost, PostItemJnlLine, DisableItemTracking);

        while SplitItemJnlLine(ItemJnlLine, PostItemJnlLine) do
            if PostItemJnlLine then
                Code();

        OnPostSplitJnlLineOnAfterCode(ItemJnlLine, ItemJnlLineToPost, PostItemJnlLine, TempTrackingSpecification, DisableItemTracking);
        Clear(PrevAppliedItemLedgEntry);
        ItemJnlLineToPost := ItemJnlLine;
        CorrectOutputValuationDate(GlobalItemLedgEntry);
        RedoApplications();

        OnAfterPostSplitJnlLine(ItemJnlLineToPost, TempTrackingSpecification);

        exit(PostItemJnlLine);
    end;

    local procedure PostConsumption(var ItemJnlLine2: Record "Item Journal Line")
    begin
        OnPostConsumption(ItemJnlLine2, GlobalItemTrackingSetup, TempSplitItemJnlLine, ProdOrderCompModified, ItemLedgEntryNo);
    end;

    local procedure PostOutput(var ItemJnlLine2: Record "Item Journal Line")
    begin
        OnPostOutput(ItemJnlLine2, GlobalItemTrackingSetup, GlobalItemTrackingCode, GlobalItemLedgEntry, LastOperation);
    end;

    /// <summary>
    /// Updates item journal line with information from the item or SKU and posts it creating item ledger, 
    /// value and item application entries.
    /// </summary>
    procedure PostItem()
    begin
        PostItem(ItemJnlLine);
    end;

    procedure PostItem(var ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItem(ItemJnlLine, IsHandled, CalledFromAdjustment);
        if IsHandled then
            exit;

        SKUExists := SKU.Get(ItemJnlLine."Location Code", ItemJnlLine."Item No.", ItemJnlLine."Variant Code");
        IsHandled := false;
        OnPostItemOnAfterGetSKU(ItemJnlLine, SKUExists, IsHandled);
        if not IsHandled then
            if ItemJnlLine."Item Shpt. Entry No." <> 0 then
                if not CheckIfReservationEntryForJobExist() then begin
                    ItemJnlLine."Location Code" := '';
                    ItemJnlLine."Variant Code" := '';
                end;

        if GetItem(ItemJnlLine."Item No.", false) then
            CheckIfItemIsBlocked();
        if GetItemVariant(ItemJnlLine."Item No.", ItemJnlLine."Variant Code", false) then
            CheckIfItemVariantIsBlocked();

        OnPostItemOnBeforeCheckInventoryPostingGroup(ItemJnlLine, CalledFromAdjustment, Item, GlobalItemTrackingCode);
        if (ItemJnlLine."Inventory Posting Group" = '') and (Item.Type = Item.Type::Inventory) then begin
            Item.TestField("Inventory Posting Group");
            ItemJnlLine."Inventory Posting Group" := Item."Inventory Posting Group";
        end;

        OnPostItemOnBeforeSetAverageTransfer(ItemJnlLine, CalledFromAdjustment);
        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer) and
           (Item."Costing Method" = Item."Costing Method"::Average) and
           (ItemJnlLine."Applies-to Entry" = 0)
        then begin
            AverageTransfer := true;
            TotalAppliedQty := 0;
        end else
            AverageTransfer := false;

        IsHandled := false;
        OnPostItemOnBeforeTransferReservFromJobPlanningLine(ItemJnlLine, IsHandled, AverageTransfer);
        if not IsHandled then
            if ItemJnlLine."Job Contract Entry No." <> 0 then
                TransReserveFromJobPlanningLine(ItemJnlLine."Job Contract Entry No.", ItemJnlLine);

        if Item."Costing Method" = Item."Costing Method"::Standard then begin
            OnPostItemOnAfterCheckCostingMethodStandard(Item, ItemJnlLine);
            ItemJnlLine."Overhead Rate" := Item."Overhead Rate";
            ItemJnlLine."Indirect Cost %" := Item."Indirect Cost %";
        end;

        if (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::"Direct Cost") or
           (ItemJnlLine."Item Charge No." <> '')
        then begin
            ItemJnlLine."Overhead Rate" := 0;
            ItemJnlLine."Indirect Cost %" := 0;
        end;

        if (ItemJnlLine.Quantity <> 0) and
           (ItemJnlLine."Item Charge No." = '') and
           not (ItemJnlLine."Value Entry Type" in [ItemJnlLine."Value Entry Type"::Revaluation, ItemJnlLine."Value Entry Type"::Rounding]) and
           not ItemJnlLine.Adjustment
        then
            ItemQtyPosting()
        else
            if (ItemJnlLine."Invoiced Quantity" <> 0) or ItemJnlLine.Adjustment or
               IsInterimRevaluation()
            then begin
                if ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost" then begin
                    if Item.Type <> Item.Type::"Non-Inventory" then begin
                        IsHandled := false;
                        OnPostItemOnBeforeGetGlobalLedgerEntry(ItemJnlLine, IsHandled);
                        if not IsHandled then
                            GlobalItemLedgEntry.Get(ItemJnlLine."Item Shpt. Entry No.")
                    end else
                        if not GlobalItemLedgEntry.Get(ItemJnlLine."Item Shpt. Entry No.") then
                            exit;
                end else
                    GlobalItemLedgEntry.Get(ItemJnlLine."Applies-to Entry");
                CorrectOutputValuationDate(GlobalItemLedgEntry);
                InitValueEntry(GlobalValueEntry, GlobalItemLedgEntry);
            end;
        CheckRunItemValuePosting();

        OnPostItemOnBeforeUpdateUnitCost(ItemJnlLine, GlobalItemLedgEntry);

        UpdateUnitCost(GlobalValueEntry);

        OnAfterPostItem(ItemJnlLine, CalledFromAdjustment);
    end;

    internal procedure CalcDirAndIndirCostAmts(var DirCostAmt: Decimal; var IndirCostAmt: Decimal; CapQty: Decimal; var ItemJournalLine: Record "Item Journal Line")
    var
        CostAmt: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcDirAndIndirCostAmts(ItemJournalLine, DirCostAmt, IndirCostAmt, CapQty, IsHandled);
        if IsHandled then
            exit;

        CostAmt := CapQty * ItemJournalLine."Unit Cost";
        if ItemJournalLine.Subcontracting then
            CostAmt += RoundingResidualAmount;
        CostAmt := Round(CostAmt);
        DirCostAmt := Round((CostAmt - CapQty * ItemJournalLine."Overhead Rate") / (1 + ItemJournalLine."Indirect Cost %" / 100));
        IndirCostAmt := CostAmt - DirCostAmt;
    end;

    internal procedure InsertCapLedgEntry(var ItemJnlLine: Record "Item Journal Line"; var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; Qty: Decimal; InvdQty: Decimal)
    var
        IsHandled: Boolean;
    begin
        OnBeforeProcedureInsertCapLedgEntry(ItemJnlLine, CapLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if InvtSetup.UseLegacyPosting() then begin
            if CapLedgEntryNo = 0 then begin
                CapLedgEntry.LockTable();
                CapLedgEntryNo := CapLedgEntry.GetLastEntryNo();
            end;
            CapLedgEntryNo += 1;
        end else
            CapLedgEntryNo := CapLedgEntry.GetNextEntryNo();

        CapLedgEntry.Init();
        CapLedgEntry."Entry No." := CapLedgEntryNo;

        CapLedgEntry.Type := ItemJnlLine.Type;
        CapLedgEntry."No." := ItemJnlLine."No.";
        CapLedgEntry.Description := ItemJnlLine.Description;
        CapLedgEntry.Subcontracting := ItemJnlLine.Subcontracting;

        CapLedgEntry.Quantity := Qty;
        CapLedgEntry."Invoiced Quantity" := InvdQty;
        CapLedgEntry."Completely Invoiced" := CapLedgEntry."Invoiced Quantity" = CapLedgEntry.Quantity;

        if ItemJnlLine."Unit Cost Calculation" = ItemJnlLine."Unit Cost Calculation"::Time then begin
            CapLedgEntry."Cap. Unit of Measure Code" := ItemJnlLine."Cap. Unit of Measure Code";
            CapLedgEntry."Qty. per Cap. Unit of Measure" := ItemJnlLine."Qty. per Cap. Unit of Measure";
        end;

        CapLedgEntry."Item No." := ItemJnlLine."Item No.";
        CapLedgEntry."Variant Code" := ItemJnlLine."Variant Code";
        CapLedgEntry."Unit of Measure Code" := ItemJnlLine."Unit of Measure Code";
        CapLedgEntry."Qty. per Unit of Measure" := ItemJnlLine."Qty. per Unit of Measure";

        CapLedgEntry."Order Type" := ItemJnlLine."Order Type";
        CapLedgEntry."Order No." := ItemJnlLine."Order No.";
        CapLedgEntry."Order Line No." := ItemJnlLine."Order Line No.";

        CapLedgEntry."Posting Date" := ItemJnlLine."Posting Date";
        CapLedgEntry."Document Date" := ItemJnlLine."Document Date";
        CapLedgEntry."Document No." := ItemJnlLine."Document No.";
        CapLedgEntry."External Document No." := ItemJnlLine."External Document No.";
        CapLedgEntry."Global Dimension 1 Code" := ItemJnlLine."Shortcut Dimension 1 Code";
        CapLedgEntry."Global Dimension 2 Code" := ItemJnlLine."Shortcut Dimension 2 Code";
        CapLedgEntry."Dimension Set ID" := ItemJnlLine."Dimension Set ID";

        OnBeforeInsertCapLedgEntry(CapLedgEntry, ItemJnlLine, LastOperation);

        InsertItemReg(0, 0, 0, CapLedgEntry."Entry No.");
        CapLedgEntry."Item Register No." := ItemReg."No.";
        CapLedgEntry.Insert(true);

        OnAfterInsertCapLedgEntry(CapLedgEntry, ItemJnlLine);
    end;

    procedure InsertCapValueEntry(var ItemJournalLine: Record "Item Journal Line"; var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; ValueEntryType: Enum "Cost Entry Type"; ValuedQty: Decimal; InvdQty: Decimal; AdjdCost: Decimal)
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        OnBeforeInsertCapValueEntryProcedure(ItemJournalLine, ValueEntryType, ValuedQty, InvdQty, AdjdCost);

        if (InvdQty = 0) and (AdjdCost = 0) then
            exit;

        ValueEntryNo := GetNextValueEntryNo(ValueEntryNo);

        ValueEntry.Init();
        ValueEntry."Entry No." := ValueEntryNo;
        ValueEntry."Capacity Ledger Entry No." := CapLedgEntry."Entry No.";
        ValueEntry."Entry Type" := ValueEntryType;
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::" ";

        ValueEntry.Type := ItemJournalLine.Type;
        ValueEntry."No." := ItemJournalLine."No.";
        ValueEntry.Description := ItemJournalLine.Description;
        ValueEntry."Order Type" := ItemJournalLine."Order Type";
        ValueEntry."Order No." := ItemJournalLine."Order No.";
        ValueEntry."Order Line No." := ItemJournalLine."Order Line No.";
        ValueEntry."Source Type" := ItemJournalLine."Source Type";
        ValueEntry."Source No." := GetSourceNo(ItemJournalLine);
        ValueEntry."Invoiced Quantity" := InvdQty;
        ValueEntry."Valued Quantity" := ValuedQty;

        ValueEntry."Cost Amount (Actual)" := AdjdCost;
        ValueEntry."Cost Amount (Actual) (ACY)" := ACYMgt.CalcACYAmt(AdjdCost, ItemJournalLine."Posting Date", false);
        OnInsertCapValueEntryOnAfterUpdateCostAmounts(ValueEntry, ItemJournalLine);

        ValueEntry."Cost per Unit" :=
          CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
        ValueEntry."Cost per Unit (ACY)" :=
          CalcCostPerUnit(ValueEntry."Cost Amount (Actual) (ACY)", ValueEntry."Valued Quantity", true);
        ValueEntry.Inventoriable := true;

        if ItemJournalLine.Type = ItemJournalLine.Type::Resource then
            ItemJournalLine.TestField("Inventory Posting Group", '')
        else
            ItemJournalLine.TestField("Inventory Posting Group");
        ValueEntry."Inventory Posting Group" := ItemJournalLine."Inventory Posting Group";
        ValueEntry."Gen. Bus. Posting Group" := ItemJournalLine."Gen. Bus. Posting Group";
        ValueEntry."Gen. Prod. Posting Group" := ItemJournalLine."Gen. Prod. Posting Group";

        ValueEntry."Posting Date" := ItemJournalLine."Posting Date";
        ValueEntry."Valuation Date" := ItemJournalLine."Posting Date";
        ValueEntry."Source No." := GetSourceNo(ItemJournalLine);
        ValueEntry."Document Type" := ItemJournalLine."Document Type";
        if ValueEntry."Expected Cost" or (ItemJournalLine."Invoice No." = '') then
            ValueEntry."Document No." := ItemJournalLine."Document No."
        else begin
            ValueEntry."Document No." := ItemJournalLine."Invoice No.";
            if ItemJournalLine."Document Type" in
               [ItemJournalLine."Document Type"::"Purchase Receipt", ItemJournalLine."Document Type"::"Purchase Return Shipment",
                ItemJournalLine."Document Type"::"Sales Shipment", ItemJournalLine."Document Type"::"Sales Return Receipt",
                ItemJournalLine."Document Type"::"Service Shipment"]
            then
                ValueEntry."Document Type" := Enum::"Item Ledger Document Type".FromInteger(ItemJournalLine."Document Type".AsInteger() + 1);
        end;
        ValueEntry."Document Line No." := ItemJournalLine."Document Line No.";
        ValueEntry."Document Date" := ItemJournalLine."Document Date";
        ValueEntry."External Document No." := ItemJournalLine."External Document No.";
        ValueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ValueEntry."User ID"));
        ValueEntry."Source Code" := ItemJournalLine."Source Code";
        ValueEntry."Reason Code" := ItemJournalLine."Reason Code";
        ValueEntry."Journal Batch Name" := ItemJournalLine."Journal Batch Name";

        ValueEntry."Global Dimension 1 Code" := ItemJournalLine."Shortcut Dimension 1 Code";
        ValueEntry."Global Dimension 2 Code" := ItemJournalLine."Shortcut Dimension 2 Code";
        ValueEntry."Dimension Set ID" := ItemJournalLine."Dimension Set ID";

        OnBeforeInsertCapValueEntry(ValueEntry, ItemJournalLine);

        IsHandled := false;
        OnInsertCapValueEntryOnBeforeInventoryPostingToGL(ValueEntry, IsHandled, PostToGL);
        if not IsHandled then begin
            InventoryPostingToGL.SetRunOnlyCheck(true, not InvtSetup."Automatic Cost Posting", false);
            PostInvtBuffer(ValueEntry);
        end;

        InsertItemReg(0, 0, ValueEntry."Entry No.", 0);
        ValueEntry."Item Register No." := ItemReg."No.";
        ValueEntry.Insert(true);

        OnAfterInsertCapValueEntry(ValueEntry, ItemJournalLine);

        UpdateAdjmtProperties(ValueEntry, CapLedgEntry."Posting Date");

        InsertPostValueEntryToGL(ValueEntry);
        if Item."Item Tracking Code" <> '' then begin
            TempValueEntryRelation.Init();
            TempValueEntryRelation."Value Entry No." := ValueEntry."Entry No.";
            TempValueEntryRelation.Insert();
        end;
        OnInsertCapValueEntryOnAfterInsertValueEntryRelation(ValueEntry, ItemJournalLine, TempValueEntryRelation);

        if (ItemJournalLine."Item Shpt. Entry No." <> 0) and
           (ValueEntryType = ItemJournalLine."Value Entry Type"::"Direct Cost")
        then begin
            CapLedgEntry."Invoiced Quantity" := CapLedgEntry."Invoiced Quantity" + ItemJournalLine."Invoiced Quantity";
            CapLedgEntry."Completely Invoiced" := CapLedgEntry."Invoiced Quantity" = CapLedgEntry.Quantity;
            OnInsertCapValueEntryOnBeforeCapLedgEntryModify(CapLedgEntry, ItemJournalLine);
            CapLedgEntry.Modify();
        end;

        OnInsertCapValueEntryOnAfterUpdateCapLedgEntry(ValueEntry, ItemJournalLine);
    end;

    /// <summary>
    /// Posts the current item journal line in the global ItemJnlLine buffer, creating item ledger, value and application entries.
    /// It checks if the quantity and invoiced quantity of the item journal line are different. If they are, 
    /// it tests if the invoiced quantity is zero and raises an error otherwise.
    /// Inserts an item ledger entry and a value entry from the item journal line information.
    /// </summary>
    procedure ItemQtyPosting()
    var
        IsReserved: Boolean;
        InsertItemLedgEntryNeeded: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeItemQtyPosting(ItemJnlLine, CalledFromAdjustment, IsHandled);
        if isHandled then
            exit;

        if ItemJnlLine.Quantity <> ItemJnlLine."Invoiced Quantity" then
            ItemJnlLine.TestField("Invoiced Quantity", 0);
        ItemJnlLine.TestField("Item Shpt. Entry No.", 0);

        InitItemLedgEntry(GlobalItemLedgEntry);
        InitValueEntry(GlobalValueEntry, GlobalItemLedgEntry);

        if Item.Type = Item.Type::Inventory then begin
            GlobalItemLedgEntry."Remaining Quantity" := GlobalItemLedgEntry.Quantity;
            GlobalItemLedgEntry.Open := GlobalItemLedgEntry."Remaining Quantity" <> 0;
        end else begin
            GlobalItemLedgEntry."Remaining Quantity" := 0;
            GlobalItemLedgEntry.Open := false;
        end;
        GlobalItemLedgEntry.Positive := GlobalItemLedgEntry.Quantity > 0;
        if GlobalItemLedgEntry."Entry Type" = GlobalItemLedgEntry."Entry Type"::Transfer then
            GlobalItemLedgEntry."Completely Invoiced" := true;

        if GlobalItemLedgEntry.Quantity > 0 then
            if GlobalItemLedgEntry."Entry Type" <> GlobalItemLedgEntry."Entry Type"::Transfer then
                IsReserved :=
                  ItemJnlLineReserve.TransferItemJnlToItemLedgEntry(
                    ItemJnlLine, GlobalItemLedgEntry, ItemJnlLine."Quantity (Base)", true);

        OnItemQtyPostingOnBeforeApplyItemLedgEntry(ItemJnlLine, GlobalItemLedgEntry);
        ApplyItemLedgEntry(GlobalItemLedgEntry, OldItemLedgEntry, GlobalValueEntry, false);
        UpdateReservationEntryForNonInventoriableItem();
        CheckApplFromInProduction(GlobalItemLedgEntry, ItemJnlLine."Applies-from Entry");
        AutoTrack(GlobalItemLedgEntry, IsReserved);

        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer) and AverageTransfer then
            InsertTransferEntry(GlobalItemLedgEntry, OldItemLedgEntry, TotalAppliedQty);

        OnItemQtyPostingOnAfterInsertTransferEntry(
            ItemJnlLine, AverageTransfer, GlobalItemLedgEntry, OldItemLedgEntry, TotalAppliedQty, TempItemEntryRelation, GlobalValueEntry);

        if ItemJnlLine."Entry Type" in [ItemJnlLine."Entry Type"::"Assembly Output", ItemJnlLine."Entry Type"::"Assembly Consumption"] then
            InsertAsmItemEntryRelation(GlobalItemLedgEntry);

        InsertItemLedgEntryNeeded := (not ItemJnlLine."Phys. Inventory") or (ItemJnlLine.Quantity <> 0);
        OnItemQtyPostingOnAfterCalcInsertItemLedgEntryNeeded(ItemJnlLine, InsertItemLedgEntryNeeded);
        if InsertItemLedgEntryNeeded then begin
            InsertItemLedgEntry(GlobalItemLedgEntry, false);
            OnItemQtyPostingOnBeforeInsertApplEntry(GlobalItemLedgEntry, ItemJnlLine);
            if GlobalItemLedgEntry.Positive then
                InsertApplEntry(
                  GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry."Entry No.",
                  ItemJnlLine."Applies-from Entry", 0, GlobalItemLedgEntry."Posting Date",
                  GlobalItemLedgEntry.Quantity, true);
            OnItemQtyPostingOnAfterInsertApplEntry(ItemJnlLine, TempSplitItemJnlLine, GlobalItemLedgEntry);
        end;
        OnAfterItemQtyPosting(ItemJnlLine);
    end;

    local procedure CheckRunItemValuePosting()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckRunItemValuePosting(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ((ItemJnlLine.Quantity <> 0) or (ItemJnlLine."Invoiced Quantity" <> 0)) and
                not (ItemJnlLine.Adjustment and (ItemJnlLine.Amount = 0) and (ItemJnlLine."Amount (ACY)" = 0))
        then
            ItemValuePosting();
    end;

    local procedure CheckIfItemIsBlocked()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfItemIsBlocked(ItemJnlLine, CalledFromAdjustment, IsHandled);
        if IsHandled then
            exit;

        if not CalledFromAdjustment then
            ItemJnlLine.DisplayErrorIfItemIsBlocked(Item);
        Item.CheckBlockedByApplWorksheet();
    end;

    local procedure CheckIfItemVariantIsBlocked()
    begin
        if not CalledFromAdjustment then
            ItemJnlLine.DisplayErrorIfItemVariantIsBlocked(ItemVariant);
    end;

    /// <summary>
    /// Posts balance of expected cost reversal if it's expected by item's costing method.
    /// </summary>
    /// <remarks>
    /// If a balance is expected from a cost reversal based on the item's costing method and the properties of the 
    /// item journal line then the procedure inserts a balance expected cost reversal entry for a value entry.
    /// </remarks>
    procedure ItemValuePosting()
    var
        xValueEntryNo: Integer;
        IsCostNotTracedDirectly: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeItemValuePosting(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and
           (ItemJnlLine."Item Charge No." = '') and
           not ItemJnlLine.Adjustment
        then
            if (ItemJnlLine.Quantity = 0) and (ItemJnlLine."Invoiced Quantity" <> 0) then begin
                if (GlobalValueEntry."Invoiced Quantity" < 0) and
                   (Item."Costing Method" = Item."Costing Method"::Average)
                then
                    ValuateAppliedAvgEntry(GlobalValueEntry, Item);
            end else
                if (GlobalValueEntry."Valued Quantity" < 0) and (ItemJnlLine."Entry Type" <> ItemJnlLine."Entry Type"::Transfer) then
                    if Item."Costing Method" = Item."Costing Method"::Average then
                        ValuateAppliedAvgEntry(GlobalValueEntry, Item);

        IsHandled := false;
        OnItemValuePostingOnBeforeInsertValueEntry(ItemJnlLine, IsHandled);
        if not IsHandled then
            InsertValueEntry(GlobalValueEntry, GlobalItemLedgEntry, false);

        xValueEntryNo := ValueEntryNo;
        OnItemValuePostingOnAfterInsertValueEntry(GlobalValueEntry, GlobalItemLedgEntry, ValueEntryNo);
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");

        IsCostNotTracedDirectly := (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::"Direct Cost") or (ItemJnlLine."Item Charge No." <> '');
        OnItemValuePostingOnAfterCalcIsCostNotTracedDirectly(ItemJnlLine, IsCostNotTracedDirectly);
        if IsCostNotTracedDirectly then begin
            if (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Rounding) and (not ItemJnlLine.Adjustment) then begin
                if GlobalItemLedgEntry.Positive then
                    GlobalItemLedgEntry.Modify();
                IsHandled := false;
                xValueEntryNo := ValueEntryNo;
                OnItemValuePostingOnBeforeInsertOHValueEntry(ItemJnlLine, GlobalValueEntry, GlobalItemLedgEntry, ValueEntryNo, IsHandled, VarianceAmount, VarianceAmountACY, OverheadAmount, OverheadAmountACY);
                ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");
                if not IsHandled then
                    if ((GlobalValueEntry."Valued Quantity" > 0) or
                        ((ItemJnlLine."Applies-to Entry" <> 0) and (ItemJnlLine."Entry Type" in [ItemJnlLine."Entry Type"::Purchase, ItemJnlLine."Entry Type"::"Assembly Output"]))) and
                       (OverheadAmount <> 0)
                    then
                        InsertOHValueEntry(GlobalValueEntry, OverheadAmount, OverheadAmountACY);
                if (Item."Costing Method" = Item."Costing Method"::Standard) and
                   (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Purchase) and
                   (GlobalValueEntry."Entry Type" <> GlobalValueEntry."Entry Type"::Revaluation)
                then
                    InsertVarValueEntry(
                      GlobalValueEntry,
                      -GlobalValueEntry."Cost Amount (Actual)" + OverheadAmount,
                      -(GlobalValueEntry."Cost Amount (Actual) (ACY)" + OverheadAmountACY));
            end;
        end else begin
            if IsBalanceExpectedCostFromRev(ItemJnlLine) then
                InsertBalanceExpCostRevEntry(GlobalValueEntry);

            IsHandled := false;
            xValueEntryNo := ValueEntryNo;
            OnItemValuePostingOnBeforeInsertOHValueEntry(ItemJnlLine, GlobalValueEntry, GlobalItemLedgEntry, ValueEntryNo, IsHandled, VarianceAmount, VarianceAmountACY, OverheadAmount, OverheadAmountACY);
            ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");
            if not IsHandled then
                if ((GlobalValueEntry."Valued Quantity" > 0) or
                    ((ItemJnlLine."Applies-to Entry" <> 0) and (ItemJnlLine."Entry Type" in [ItemJnlLine."Entry Type"::Purchase, ItemJnlLine."Entry Type"::"Assembly Output"]))) and
                   (OverheadAmount <> 0)
                then
                    InsertOHValueEntry(GlobalValueEntry, OverheadAmount, OverheadAmountACY);

            if ((GlobalValueEntry."Valued Quantity" > 0) or (ItemJnlLine."Applies-to Entry" <> 0)) and
               (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Purchase) and
               (Item."Costing Method" = Item."Costing Method"::Standard) and
               (Round(VarianceAmount, GLSetup."Amount Rounding Precision") <> 0) or
               VarianceRequired
            then
                InsertVarValueEntry(GlobalValueEntry, VarianceAmount, VarianceAmountACY);
        end;
        if (GlobalValueEntry."Valued Quantity" < 0) and
           (GlobalItemLedgEntry.Quantity = GlobalItemLedgEntry."Invoiced Quantity")
        then
            UpdateItemApplnEntry(GlobalValueEntry."Item Ledger Entry No.", ItemJnlLine."Posting Date");

        OnAfterItemValuePosting(GlobalValueEntry, ItemJnlLine, Item);
    end;

#if not CLEAN27
    /// <summary>
    /// Posts the consumption of the component in a production order. 
    /// </summary>
    /// <param name="ProdOrder">Production order being posted.</param>
    /// <param name="ProdOrderLine">Production order line being posted.</param>
    /// <param name="ProdOrderComp">Production order component to post.</param>
    /// <param name="ProdOrderRoutingLine">Production order routing line. This record is only used on events.</param>
    /// <param name="OldItemJnlLine">Previous item journal line from which new one will be initialized.</param>
    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    procedure PostFlushedConsumption(ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line")
    var
        MfgItemJnlPostLine: Codeunit "Mfg. Item Jnl.-Post Line";
        ItemJnlPostLine: Variant;
    begin
        ItemJnlPostLine := this;
        MfgItemJnlPostLine.PostFlushedConsumption(
            ItemJnlLine, ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine, ItemJnlPostLine);
    end;
#endif

    internal procedure PostFlushedConsumptionItemJnlLine(var ItemJnlLine2: Record "Item Journal Line"; CombinedDimSetID: Integer)
    var
#if not CLEAN27
        ProdOrder: Record Microsoft.Manufacturing.Document."Production Order";
        ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line";
        ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component";
#endif
        PostItemJnlLine: Boolean;
        DimsAreTaken: Boolean;
        TrackingSpecExists: Boolean;
    begin
        PrepareItem(ItemJnlLine2);
        TrackingSpecExists := ItemTrackingMgt.RetrieveItemTracking(ItemJnlLine2, TempTrackingSpecification);

        OnPostFlushedConsumptionItemJnlLineOnBeforeSetupSplitJnlLine(ItemJnlLine2, TempTrackingSpecification, TrackingSpecExists);
#if not CLEAN27
        ProdOrder.Get(ProdOrder.Status::Released, ItemJnlLine2."Order No.");
        ProdOrderLine.Get(ProdOrder.Status::Released, ItemJnlLine2."Order No.", ItemJnlLine2."Order Line No.");
        ProdOrderComp.Get(ProdOrder.Status::Released, ItemJnlLine2."Order No.", ItemJnlLine2."Order Line No.", ItemJnlLine2."Prod. Order Comp. Line No.");
        OnPostFlushedConsumpOnBeforeSetupSplitJnlLine(ItemJnlLine2, ProdOrder, ProdOrderLine, ProdOrderComp, TempTrackingSpecification, TrackingSpecExists);
#endif
        PostItemJnlLine := SetupSplitJnlLine(ItemJnlLine2, TrackingSpecExists);

        while SplitItemJnlLine(ItemJnlLine2, PostItemJnlLine) do begin
            ItemJnlLine2.CheckTrackingIfRequiredNotBlank(GlobalItemTrackingSetup);

            if not DimsAreTaken then begin
                ItemJnlLine2."Dimension Set ID" := CombinedDimSetID;
                OnPostFlushedConsumptionItemJnlLineOnAfterSetDimensionSetID(ItemJnlLine);
#if not CLEAN27
                OnPostFlushedConsumptionOnAfterSetDimensionSetID(ItemJnlLine, ProdOrderLine);
#endif
                DimsAreTaken := true;
            end;
            ItemJnlCheckLine.RunCheck(ItemJnlLine2);
            ProdOrderCompModified := true;
            ItemJnlLine2.Quantity := ItemJnlLine2."Quantity (Base)";
            ItemJnlLine2."Invoiced Quantity" := ItemJnlLine2."Invoiced Qty. (Base)";
            QtyPerUnitOfMeasure := ItemJnlLine2."Qty. per Unit of Measure";

            ItemJnlLine2."Unit Amount" := Round(
                ItemJnlLine2."Unit Amount" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
            ItemJnlLine2."Unit Cost" := Round(
                ItemJnlLine2."Unit Cost" / QtyPerUnitOfMeasure, GLSetup."Unit-Amount Rounding Precision");
            ItemJnlLine2."Unit Cost (ACY)" := Round(
                ItemJnlLine2."Unit Cost (ACY)" / QtyPerUnitOfMeasure, Currency."Unit-Amount Rounding Precision");
            PostConsumption(ItemJnlLine2);
        end;
    end;

    /// <summary>
    /// Updates the unit cost on item and SKU for the last direct cost from the value entry.
    /// </summary>
    /// <param name="ValueEntry">Value entry to calculate unit cost from.</param>
    procedure UpdateUnitCost(ValueEntry: Record "Value Entry")
    var
        ItemCostMgt: Codeunit ItemCostManagement;
        LastDirectCost: Decimal;
        TotalAmount: Decimal;
        IsHandled: Boolean;
        UpdateSKU: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCost(ValueEntry, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        if (ValueEntry."Valued Quantity" > 0) and not (ValueEntry."Expected Cost" or ItemJnlLine.Adjustment) then begin
            Item.ReadIsolation(IsolationLevel::UpdLock);
            if not Item.Find() then
                exit;

            if ValueEntry.IsInbound() and
               ((ValueEntry."Cost Amount (Actual)" + ValueEntry."Discount Amount" > 0) or Item.IsNonInventoriableType()) and
               (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and
               (ItemJnlLine."Item Charge No." = '') and not Item."Inventory Value Zero"
            then begin
                TotalAmount := ItemJnlLine.Amount + ItemJnlLine."Discount Amount";
                IsHandled := false;
                OnUpdateUnitCostOnBeforeCalculateLastDirectCost(TotalAmount, ItemJnlLine, ValueEntry, Item, IsHandled);
                if not IsHandled then
                    LastDirectCost := Round(TotalAmount / ValueEntry."Valued Quantity", GLSetup."Unit-Amount Rounding Precision")
            end;

            if ValueEntry."Drop Shipment" then begin
                if LastDirectCost <> 0 then begin
                    Item."Last Direct Cost" := LastDirectCost;
                    OnUpdateUnitCostOnAfterAssignLastDirectCost(ValueEntry, Item, LastDirectCost);
                    Item.Modify();
                    ItemCostMgt.SetProperties(false, ValueEntry."Invoiced Quantity");
                    ItemCostMgt.FindUpdateUnitCostSKU(Item, ValueEntry."Location Code", ValueEntry."Variant Code", true, LastDirectCost);
                end;
            end else begin
                UpdateSKU := true;
                OnUpdateUnitCostOnBeforeUpdateUnitCost(ItemJnlLine, ValueEntry, Item, UpdateSKU);
                ItemCostMgt.SetProperties(false, ValueEntry."Invoiced Quantity");
                ItemCostMgt.UpdateUnitCost(Item, ValueEntry."Location Code", ValueEntry."Variant Code", LastDirectCost, 0, UpdateSKU, true, false, 0);
            end;
        end;
        OnAfterUpdateUnitCost(ValueEntry, LastDirectCost, ItemJnlLine, Item);
    end;

    /// <summary>
    /// Unapplies the provided item application entry.
    /// </summary>
    /// <remarks>
    /// Entries applied to an outbound transfer and drop shipment order cannot be unapplied.
    /// </remarks>
    /// <param name="ItemApplnEntry">Item application entry to unapply.</param>
    procedure UnApply(ItemApplnEntry: Record "Item Application Entry")
    var
        ItemLedgEntry1: Record "Item Ledger Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        CostItemLedgEntry: Record "Item Ledger Entry";
        InventoryPeriod: Record "Inventory Period";
        Valuationdate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUnApply(ItemApplnEntry, IsHandled);
        if IsHandled then
            exit;

        if not InventoryPeriod.IsValidDate(ItemApplnEntry."Posting Date") then
            InventoryPeriod.ShowError(ItemApplnEntry."Posting Date");

        // If we can't get both entries then the application is not a real application or a date compression might have been done
        ItemLedgEntry1.Get(ItemApplnEntry."Inbound Item Entry No.");
        ItemLedgEntry2.Get(ItemApplnEntry."Outbound Item Entry No.");

        if ItemApplnEntry."Item Ledger Entry No." = ItemApplnEntry."Inbound Item Entry No." then
            CheckItemCorrection(ItemLedgEntry1);
        if ItemApplnEntry."Item Ledger Entry No." = ItemApplnEntry."Outbound Item Entry No." then
            CheckItemCorrection(ItemLedgEntry2);

        if ItemLedgEntry1."Drop Shipment" and ItemLedgEntry2."Drop Shipment" then
            Error(Text024);

        if ItemLedgEntry2."Entry Type" = ItemLedgEntry2."Entry Type"::Transfer then
            Error(Text023);

        ItemApplnEntry.TestField("Transferred-from Entry No.", 0);

        // We won't allow deletion of applications for deleted items
        GetItem(ItemLedgEntry1."Item No.", true);
        CostItemLedgEntry.Get(ItemApplnEntry.CostReceiver()); // costreceiver

        OnUnApplyOnBeforeUpdateItemLedgerEntries(ItemLedgEntry1, ItemLedgEntry2, ItemApplnEntry);

        if ItemLedgEntry1."Applies-to Entry" = ItemLedgEntry2."Entry No." then
            ItemLedgEntry1."Applies-to Entry" := 0;

        if ItemLedgEntry2."Applies-to Entry" = ItemLedgEntry1."Entry No." then
            ItemLedgEntry2."Applies-to Entry" := 0;

        // only if real/quantity application
        if not ItemApplnEntry.CostApplication() then begin
            ItemLedgEntry1."Remaining Quantity" := ItemLedgEntry1."Remaining Quantity" - ItemApplnEntry.Quantity;
            ItemLedgEntry1.Open := ItemLedgEntry1."Remaining Quantity" <> 0;
            ItemLedgEntry1.Modify();

            ItemLedgEntry2."Remaining Quantity" := ItemLedgEntry2."Remaining Quantity" + ItemApplnEntry.Quantity;
            ItemLedgEntry2.Open := ItemLedgEntry2."Remaining Quantity" <> 0;
            ItemLedgEntry2.Modify();
        end else begin
            ItemLedgEntry2."Shipped Qty. Not Returned" := ItemLedgEntry2."Shipped Qty. Not Returned" - Abs(ItemApplnEntry.Quantity);
            if Abs(ItemLedgEntry2."Shipped Qty. Not Returned") > Abs(ItemLedgEntry2.Quantity) then
                ItemLedgEntry2.FieldError("Shipped Qty. Not Returned", Text004); // Assert - should never happen
            ItemLedgEntry2.Modify();

            OnUnApplyOnBeforeInsertApplEntry(ItemApplnEntry);
            // If cost application we need to insert a 0 application instead if there is none before
            if ItemApplnEntry.Quantity > 0 then
                if not ZeroApplication(ItemApplnEntry."Item Ledger Entry No.") then
                    InsertApplEntry(
                      ItemApplnEntry."Item Ledger Entry No.", ItemApplnEntry."Inbound Item Entry No.",
                      0, 0, ItemApplnEntry."Posting Date", ItemApplnEntry.Quantity, true);
        end;

        if Item."Costing Method" = Item."Costing Method"::Average then
            if not ItemApplnEntry.Fixed() then
                UpdateValuedByAverageCost(CostItemLedgEntry."Entry No.", true);

        ItemApplnEntry.InsertHistory();
        TouchEntry(ItemApplnEntry."Inbound Item Entry No.");
        SaveTouchedEntry(ItemApplnEntry."Inbound Item Entry No.", true);
        if ItemApplnEntry."Outbound Item Entry No." <> 0 then begin
            TouchEntry(ItemApplnEntry."Outbound Item Entry No.");
            SaveTouchedEntry(ItemApplnEntry."Inbound Item Entry No.", false);
        end;

        OnUnApplyOnBeforeItemApplnEntryDelete(ItemApplnEntry);
        ItemApplnEntry.Delete();

        Valuationdate := GetMaxAppliedValuationdate(CostItemLedgEntry);
        if Valuationdate = 0D then
            Valuationdate := CostItemLedgEntry."Posting Date"
        else
            Valuationdate := max(CostItemLedgEntry."Posting Date", Valuationdate);

        SetValuationDateAllValueEntrie(CostItemLedgEntry."Entry No.", Valuationdate, false);

        UpdateLinkedValuationUnapply(Valuationdate, CostItemLedgEntry."Entry No.", CostItemLedgEntry.Positive);
    end;

    /// <summary>
    /// Reapplies item ledger entries.
    /// </summary>
    /// <param name="ItemLedgEntry">Item ledger entry to reaplly.</param>
    /// <param name="ApplyWith">Apply to item ledger entry no.</param>
    procedure ReApply(ItemLedgEntry: Record "Item Ledger Entry"; ApplyWith: Integer)
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        InventoryPeriod: Record "Inventory Period";
        CostApplication: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReApply(ItemLedgEntry, ApplyWith, IsHandled);
        if IsHandled then
            exit;

        GetItem(ItemLedgEntry."Item No.", true);

        if not InventoryPeriod.IsValidDate(ItemLedgEntry."Posting Date") then
            InventoryPeriod.ShowError(ItemLedgEntry."Posting Date");

        GlobalItemTrackingCode.Code := Item."Item Tracking Code";
        OnReApplyOnBeforeGetItemTrackingSetup(Item, GlobalItemTrackingCode);
        ItemTrackingMgt.GetItemTrackingSetup(
            GlobalItemTrackingCode, ItemJnlLine."Entry Type",
            ItemJnlLine.Signed(ItemJnlLine."Quantity (Base)") > 0, GlobalItemTrackingSetup);

        TotalAppliedQty := 0;
        CostApplication := false;
        if ApplyWith <> 0 then begin
            ItemLedgEntry2.Get(ApplyWith);
            if ItemLedgEntry2.Quantity > 0 then begin
                // Switch around so ItemLedgEntry is positive and ItemLedgEntry2 is negative
                OldItemLedgEntry := ItemLedgEntry;
                ItemLedgEntry := ItemLedgEntry2;
                ItemLedgEntry2 := OldItemLedgEntry;
            end;

            OnReApplyOnBeforeStartApply(ItemLedgEntry, ItemLedgEntry2);

            if not ((ItemLedgEntry.Quantity > 0) and // not(Costprovider(ItemLedgEntry))
                    ((ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::Purchase) or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::"Positive Adjmt.") or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::Output) or
                     (ItemLedgEntry."Entry Type" = ItemLedgEntry2."Entry Type"::"Assembly Output"))
                    )
            then
                CostApplication := true;
            if (ItemLedgEntry."Remaining Quantity" <> 0) and (ItemLedgEntry2."Remaining Quantity" <> 0) then
                CostApplication := false;
            if CostApplication then
                CostApply(ItemLedgEntry, ItemLedgEntry2)
            else begin
                CreateItemJnlLineFromEntry(ItemLedgEntry2, ItemLedgEntry2."Remaining Quantity", ItemJnlLine);
                if ApplyWith = ItemLedgEntry2."Entry No." then
                    ItemLedgEntry2."Applies-to Entry" := ItemLedgEntry."Entry No."
                else
                    ItemLedgEntry2."Applies-to Entry" := ApplyWith;
                ItemJnlLine."Applies-to Entry" := ItemLedgEntry2."Applies-to Entry";
                GlobalItemLedgEntry := ItemLedgEntry2;
                ApplyItemLedgEntry(ItemLedgEntry2, OldItemLedgEntry, ValueEntry, false);
                TouchItemEntryCost(ItemLedgEntry2, false);
                ItemLedgEntry2.Modify();
                EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry2);
                IsHandled := false;
                OnReApplyOnBeforeUpdateLinkedValuationDate(ValueEntry, IsHandled);
                if not IsHandled then begin
                    GetValuationDate(ValueEntry, ItemLedgEntry);
                    UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
                end;
            end;

            if ItemApplnEntry.Fixed() and (ItemApplnEntry.CostReceiver() <> 0) then
                if GetItem(ItemLedgEntry."Item No.", false) then
                    if Item."Costing Method" = Item."Costing Method"::Average then
                        UpdateValuedByAverageCost(ItemApplnEntry.CostReceiver(), false);
        end else begin  // ApplyWith is 0
            ItemLedgEntry."Applies-to Entry" := ApplyWith;
            CreateItemJnlLineFromEntry(ItemLedgEntry, ItemLedgEntry."Remaining Quantity", ItemJnlLine);
            ItemJnlLine."Applies-to Entry" := ItemLedgEntry."Applies-to Entry";
            GlobalItemLedgEntry := ItemLedgEntry;
            ApplyItemLedgEntry(ItemLedgEntry, OldItemLedgEntry, ValueEntry, false);
            TouchItemEntryCost(ItemLedgEntry, false);
            ItemLedgEntry.Modify();
            EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry);
            IsHandled := false;
            OnReApplyOnBeforeUpdateLinkedValuationDate(ValueEntry, IsHandled);
            if not IsHandled then begin
                GetValuationDate(ValueEntry, ItemLedgEntry);
                UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
            end;
        end;
    end;

    local procedure CostApply(var ItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry2: Record "Item Ledger Entry")
    var
        ApplyWithItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        if ItemLedgEntry.Quantity > 0 then begin
            GlobalItemLedgEntry := ItemLedgEntry;
            ApplyWithItemLedgEntry := ItemLedgEntry2;
        end
        else begin
            GlobalItemLedgEntry := ItemLedgEntry2;
            ApplyWithItemLedgEntry := ItemLedgEntry;
        end;
        if not ItemApplnEntry.CheckIsCyclicalLoop(ApplyWithItemLedgEntry, GlobalItemLedgEntry) then begin
            CreateItemJnlLineFromEntry(GlobalItemLedgEntry, GlobalItemLedgEntry.Quantity, ItemJnlLine);
            OnCostApplyOnBeforeInsertApplEntry(GlobalItemLedgEntry, ApplyWithItemLedgEntry);
            InsertApplEntry(
              GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry."Entry No.",
              ApplyWithItemLedgEntry."Entry No.", 0, GlobalItemLedgEntry."Posting Date",
              GlobalItemLedgEntry.Quantity, true);
            UpdateOutboundItemLedgEntry(ApplyWithItemLedgEntry."Entry No.");
            OldItemLedgEntry.Get(ApplyWithItemLedgEntry."Entry No.");
            EnsureValueEntryLoaded(ValueEntry, GlobalItemLedgEntry);
            ItemJnlLine."Applies-from Entry" := ApplyWithItemLedgEntry."Entry No.";
            GetAppliedFromValues(ValueEntry);
            SetValuationDateAllValueEntrie(GlobalItemLedgEntry."Entry No.", ValueEntry."Valuation Date", false);
            UpdateLinkedValuationDate(ValueEntry."Valuation Date", GlobalItemLedgEntry."Entry No.", GlobalItemLedgEntry.Positive);
            TouchItemEntryCost(ItemLedgEntry2, false);
        end;
    end;

    local procedure ZeroApplication(EntryNo: Integer): Boolean
    var
        Application: Record "Item Application Entry";
    begin
        Application.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.");
        Application.SetRange("Item Ledger Entry No.", EntryNo);
        Application.SetRange("Inbound Item Entry No.", EntryNo);
        Application.SetRange("Outbound Item Entry No.", 0);
        exit(not Application.IsEmpty);
    end;

    /// <summary>
    /// Applies an item ledger entry to another item ledger entry.
    /// </summary>
    /// <remarks>
    /// Usually used in inventory management where you want to match an incoming item ledger entry (like a purchase) 
    /// with an outgoing item ledger entry (like a sale).
    /// </remarks>
    /// <param name="ItemLedgEntry">
    /// Item Ledger entry to apply. If this is a cost application, the entry is marked as applied entry to adjust.
    /// </param>
    /// <param name="OldItemLedgEntry"> Return value: Item ledger entry the to-apply entry is applied to. </param>
    /// <param name="ValueEntry">Return value: Value entry with updated valuation date.</param>
    /// <param name="CausedByTransfer">Is caused by a transfer.</param>
    procedure ApplyItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; CausedByTransfer: Boolean)
    var
        ItemLedgEntry2: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        AppliesFromItemLedgEntry: Record "Item Ledger Entry";
        EntryFindMethod: Text[1];
        AppliedQty: Decimal;
        FirstReservation: Boolean;
        FirstApplication: Boolean;
        StartApplication: Boolean;
        UseReservationApplication: Boolean;
        IsHandled: Boolean;
        SkipReservationCheck: Boolean;
    begin
        OnBeforeApplyItemLedgEntry(ItemLedgEntry, OldItemLedgEntry, ValueEntry, CausedByTransfer, IsHandled, ItemJnlLine, ItemApplnEntryNo);
        if IsHandled then
            exit;

        if (ItemLedgEntry."Remaining Quantity" = 0) or
           (ItemLedgEntry."Drop Shipment" and (ItemLedgEntry."Applies-to Entry" = 0)) or
           ((Item."Costing Method" = Item."Costing Method"::Specific) and ItemLedgEntry.Positive) or
           (ItemJnlLine."Direct Transfer" and (ItemLedgEntry."Location Code" = '') and ItemLedgEntry.Positive)
        then
            exit;

        Clear(OldItemLedgEntry);
        ItemLedgEntry2.ReadIsolation(IsolationLevel::ReadUnCommitted);
        FirstReservation := true;
        FirstApplication := true;
        StartApplication := false;
        repeat
            if ItemJnlLine."Assemble to Order" then
                VerifyItemJnlLineAsembleToOrder(ItemJnlLine)
            else
                VerifyItemJnlLineApplication(ItemJnlLine, ItemLedgEntry);

            if not CausedByTransfer and not PostponeReservationHandling then begin
                if Item."Costing Method" = Item."Costing Method"::Specific then
                    ItemJnlLine.TestField("Serial No.");

                SkipReservationCheck := //posting together with PO
                    (ItemJnlLine."Document Type" = ItemJnlLine."Document Type"::"Purchase Receipt")
                    and (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Negative Adjmt.")
                    and (ItemJnlLine."Job No." <> '');

                IsHandled := false;
                OnApplyItemLedgEntryOnBeforeFirstReservationSetFilters(ItemJnlLine, StartApplication, FirstReservation, IsHandled);
                if not IsHandled then
                    if FirstReservation then begin
                        FirstReservation := false;
                        ReservEntry.Reset();
                        ReservEntry.SetCurrentKey(
                          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
                          "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
                        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
                        ItemJnlLine.SetReservationFilters(ReservEntry);
                        ReservEntry.SetRange("Item No.", ItemJnlLine."Item No.");
                    end;

                if TempTrackingSpecification.IsEmpty() then
                    if ItemJnlLine."Document Type" = ItemJnlLine."Document Type"::"Direct Transfer" then
                        if ItemLedgEntry.Quantity < 0 then
                            ReservEntry.SetRange(Positive, false)
                        else
                            ReservEntry.SetRange(Positive, true);

                if not SkipReservationCheck then
                    UseReservationApplication := FindReservationEntryWithAdditionalCheckForAssemblyItem(ReservEntry);

                IsHandled := false;
                OnApplyItemLedgEntryOnBeforeCloseSurplusTrackingEntry(ItemJnlLine, StartApplication, UseReservationApplication, IsHandled);
                if not IsHandled then
                    if not UseReservationApplication then begin // No reservations exist
                        ReservEntry.SetRange(
                          "Reservation Status", ReservEntry."Reservation Status"::Tracking,
                          ReservEntry."Reservation Status"::Prospect);
                        if ReservEntry.FindSet() then
                            repeat
                                ReservEngineMgt.CloseSurplusTrackingEntry(ReservEntry);
                            until ReservEntry.Next() = 0;
                        StartApplication := true;
                    end;

                if UseReservationApplication then begin
                    ReservEntry2.SetLoadFields("Source Type", "Source Ref. No.", "Item No.", "Quantity (Base)");
                    OnApplyItemLedgEntryOnAfterSetLoadFieldsOnReservEntry(ReservEntry2);
                    ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
                    if ReservEntry2."Source Type" <> DATABASE::"Item Ledger Entry" then
                        if ItemLedgEntry.Quantity < 0 then
                            Error(Text003, ReservEntry."Item No.");
                    OldItemLedgEntry.Get(ReservEntry2."Source Ref. No.");
                    if ItemLedgEntry.Quantity < 0 then
                        if OldItemLedgEntry."Remaining Quantity" < ReservEntry2."Quantity (Base)" then
                            Error(Text003, ReservEntry2."Item No.");

                    OldItemLedgEntry.TestField("Item No.", ItemJnlLine."Item No.");
                    OldItemLedgEntry.TestField("Variant Code", ItemJnlLine."Variant Code");
                    OldItemLedgEntry.TestField("Location Code", ItemJnlLine."Location Code");
                    OnApplyItemLedgEntryOnBeforeCloseReservEntry(OldItemLedgEntry, ItemJnlLine, ItemLedgEntry, ReservEntry);
                    ReservEngineMgt.CloseReservEntry(ReservEntry, false, false);
                    OnApplyItemLedgEntryOnAfterCloseReservEntry(OldItemLedgEntry, ItemJnlLine, ItemLedgEntry, ReservEntry);
                    OldItemLedgEntry.CalcReservedQuantity();
                    AppliedQty := -Abs(ReservEntry."Quantity (Base)");
                end;
            end else
                StartApplication := true;

            OnApplyItemLedgEntryOnBeforeStartApplication(ItemLedgEntry, OldItemLedgEntry, StartApplication, AppliedQty, Item, ItemJnlLine);

            if StartApplication then begin
                ItemLedgEntry.CalcReservedQuantity();
                if ItemLedgEntry."Applies-to Entry" <> 0 then begin
                    if FirstApplication then begin
                        FirstApplication := false;
                        OldItemLedgEntry.Get(ItemLedgEntry."Applies-to Entry");
                        TestFirstApplyItemLedgEntry(OldItemLedgEntry, ItemLedgEntry);
                        OnApplyItemLedgEntryOnAfterTestFirstApplyItemLedgEntry(OldItemLedgEntry, ItemLedgEntry);
                    end else
                        exit;
                end else
                    if FindOpenItemLedgEntryToApply(ItemLedgEntry2, ItemLedgEntry, FirstApplication, EntryFindMethod) then
                        OldItemLedgEntry.Copy(ItemLedgEntry2)
                    else
                        exit;

                OldItemLedgEntry.CalcReservedQuantity();
                OnAfterApplyItemLedgEntryOnBeforeCalcAppliedQty(OldItemLedgEntry, ItemLedgEntry);

                if Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") >
                   Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")
                then
                    AppliedQty := ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity"
                else begin
                    AppliedQty := -(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity");
                    if AppliedQty = 0 then
                        AppliedQty := UpdateAppliedQtyIfConsumptionEntry(ItemLedgEntry, OldItemLedgEntry);
                end;

                OnApplyItemLedgEntryOnAfterCalcAppliedQty(OldItemLedgEntry, ItemLedgEntry, AppliedQty);

                if (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Transfer) and not ItemLedgEntry.Positive then
                    if OldItemLedgEntry.EntryNoHasSameSign(ItemLedgEntry."Entry No.") and (OldItemLedgEntry."Entry No." > ItemLedgEntry."Entry No.") and (ItemLedgEntry."Entry No." >= 0) and not ItemLedgEntry.Positive or
                        not OldItemLedgEntry.EntryNoHasSameSign(ItemLedgEntry."Entry No.") and ((OldItemLedgEntry.SystemId > ItemLedgEntry.SystemId) and not IsNullGuid(ItemLedgEntry.SystemId) or IsNullGuid(OldItemLedgEntry.SystemId)) // Preview?
                    then
                        AppliedQty := 0;

                if (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
                   (OldItemLedgEntry."Order No." <> '')
                then
                    if not AllowProdApplication(OldItemLedgEntry, ItemLedgEntry) then
                        AppliedQty := 0;
                if ItemJnlLine."Applies-from Entry" <> 0 then begin
                    AppliesFromItemLedgEntry.Get(ItemJnlLine."Applies-from Entry");
                    if ItemApplnEntry.CheckIsCyclicalLoop(AppliesFromItemLedgEntry, OldItemLedgEntry) then
                        AppliedQty := 0;
                end;
                OnApplyItemLedgEntryOnAfterSetAppliedQtyZero(OldItemLedgEntry, ItemLedgEntry, AppliedQty, ItemJnlLine);
            end;

            CheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry, PrevAppliedItemLedgEntry, AppliedQty);

            if AppliedQty <> 0 then begin
                if not OldItemLedgEntry.Positive and
                   (OldItemLedgEntry."Remaining Quantity" = -AppliedQty) and
                   (OldItemLedgEntry."Entry No." = ItemLedgEntry."Applies-to Entry")
                then begin
                    OldValueEntry.SetCurrentKey("Item Ledger Entry No.");
                    OldValueEntry.SetRange("Item Ledger Entry No.", OldItemLedgEntry."Entry No.");
                    if OldValueEntry.Find('-') then
                        repeat
                            if OldValueEntry."Valued By Average Cost" then begin
                                OldValueEntry."Valued By Average Cost" := false;
                                OldValueEntry.Modify();
                            end;
                        until OldValueEntry.Next() = 0;
                end;

                UpdateOldItemLedgerEntryRemainingQuantity(OldItemLedgEntry, AppliedQty);

                if ItemLedgEntry.Positive then begin
                    OnApplyItemLedgEntryOnItemLedgEntryPositiveOnBeforeInsertApplEntry(OldItemLedgEntry, ItemLedgEntry, GlobalItemLedgEntry, AppliedQty);
                    if ItemLedgEntry."Posting Date" >= OldItemLedgEntry."Posting Date" then
                        InsertApplEntry(
                          OldItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
                          OldItemLedgEntry."Entry No.", 0, ItemLedgEntry."Posting Date", -AppliedQty, false)
                    else
                        InsertApplEntry(
                          OldItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
                          OldItemLedgEntry."Entry No.", 0, OldItemLedgEntry."Posting Date", -AppliedQty, false);

                    if ItemApplnEntry."Cost Application" then
                        ItemLedgEntry."Applied Entry to Adjust" := true;
                end else begin
                    OnApplyItemLedgEntryOnBeforeCheckApplyEntry(OldItemLedgEntry);

                    CheckPostingDateWithExpirationDate(ItemLedgEntry);

                    OnApplyItemLedgEntryOnBeforeInsertApplEntry(ItemLedgEntry, ItemJnlLine, OldItemLedgEntry, GlobalItemLedgEntry, AppliedQty);

                    InsertApplEntry(
                      ItemLedgEntry."Entry No.", OldItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.", 0,
                      ItemLedgEntry."Posting Date", AppliedQty, true);

                    if ItemApplnEntry."Cost Application" then
                        OldItemLedgEntry."Applied Entry to Adjust" := true;
                end;

                OnApplyItemLedgEntryOnBeforeOldItemLedgEntryModify(ItemLedgEntry, OldItemLedgEntry, ItemJnlLine, AverageTransfer);
                OldItemLedgEntry.Modify();
                AutoTrack(OldItemLedgEntry, true);

                EnsureValueEntryLoaded(ValueEntry, ItemLedgEntry);
                IsHandled := false;
                OnApplyItemLedgEntryOnBeforeGetValuationDate(ValueEntry, IsHandled);
                if not IsHandled then
                    GetValuationDate(ValueEntry, OldItemLedgEntry);

                if (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Transfer) and
                   (AppliedQty < 0) and
                   not CausedByTransfer and
                   not ItemLedgEntry.Correction
                then begin
                    if ItemLedgEntry."Completely Invoiced" then
                        ItemLedgEntry."Completely Invoiced" := OldItemLedgEntry."Completely Invoiced";
                    if AverageTransfer then
                        TotalAppliedQty := TotalAppliedQty + AppliedQty
                    else
                        InsertTransferEntry(ItemLedgEntry, OldItemLedgEntry, AppliedQty);
                end;

                UpdateItemLedgerEntryRemainingQuantity(ItemLedgEntry, AppliedQty, OldItemLedgEntry, CausedByTransfer);

                ItemLedgEntry.CalcReservedQuantity();
                if ItemLedgEntry."Remaining Quantity" + ItemLedgEntry."Reserved Quantity" = 0 then
                    exit;
            end;
            OnApplyItemLedgEntryOnApplicationLoop(ItemLedgEntry);
        until false;
    end;

    local procedure FindReservationEntryWithAdditionalCheckForAssemblyItem(var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        if not ReservEntry.FindFirst() then
            exit(false);

        if AssemblyReservationEntryMismatchWithItemJnlLine(ReservEntry) then
            exit(false);

        exit(true);
    end;

    local procedure AssemblyReservationEntryMismatchWithItemJnlLine(var ReservEntry: Record "Reservation Entry"): Boolean
    var
        ReservEntry2: Record "Reservation Entry";
        ItemRec: Record Item;
    begin
        ReservEntry2.SetLoadFields("Source Type", "Source Subtype");
        ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
        if ItemRec.Get(ReservEntry2."Item No.") then
            if not (ItemRec."Assembly Policy" = ItemRec."Assembly Policy"::"Assemble-to-Stock") then
                if (ReservEntry2."Source Type" = Database::"Assembly Header") and (ReservEntry2."Source Subtype" = 1)
                      and (not ItemJnlLine."Assemble to Order") then
                    exit(true);
    end;

    local procedure UpdateReservationEntryForNonInventoriableItem()
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if Item.IsInventoriableType() then
            exit;

        ReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Reservation Status");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ItemJnlLine.SetReservationFilters(ReservationEntry);
        ReservationEntry.SetRange("Item No.", ItemJnlLine."Item No.");

        if not ReservationEntry.IsEmpty() then
            exit;

        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Tracking, ReservationEntry."Reservation Status"::Prospect);
        if ReservationEntry.FindSet() then
            repeat
                ReservEngineMgt.CloseSurplusTrackingEntry(ReservationEntry);
            until ReservationEntry.Next() = 0;
    end;

    local procedure UpdateItemLedgerEntryRemainingQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"; AppliedQty: Decimal; var OldItemLedgEntry: Record "Item Ledger Entry"; CausedByTransfer: Boolean)
    begin
        OnBeforeUpdateItemLedgerEntryRemainingQuantity(ItemLedgerEntry, OldItemLedgEntry, AppliedQty, CausedByTransfer, AverageTransfer);

        ItemLedgerEntry."Remaining Quantity" := ItemLedgerEntry."Remaining Quantity" - AppliedQty;
        ItemLedgerEntry.Open := ItemLedgerEntry."Remaining Quantity" <> 0;

        OnAfterUpdateItemLedgerEntryRemainingQuantity(ItemLedgerEntry, AppliedQty);
    end;

    local procedure CheckPostingDateWithExpirationDate(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingDateWithExpirationDate(ItemLedgEntry, GlobalItemTrackingCode, OldItemLedgEntry, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        if GlobalItemTrackingCode."Strict Expiration Posting" and (OldItemLedgEntry."Expiration Date" <> 0D) and
           not ItemLedgEntry.Correction and
           not (ItemLedgEntry."Document Type" in
                [ItemLedgEntry."Document Type"::"Purchase Return Shipment", ItemLedgEntry."Document Type"::"Purchase Credit Memo"])
        then
            if ItemLedgEntry."Posting Date" > OldItemLedgEntry."Expiration Date" then
                if (ItemLedgEntry."Entry Type" <> ItemLedgEntry."Entry Type"::"Negative Adjmt.") and
                   not ItemJnlLine.IsReclass(ItemJnlLine)
                then
                    OldItemLedgEntry.FieldError("Expiration Date", Text017);
    end;

    local procedure ApplyItemLedgEntrySetFilters(var ToItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code")
    var
        Location: Record Location;
        ItemTrackingSetup2: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeApplyItemLedgEntrySetFilters(ToItemLedgEntry, FromItemLedgEntry, ItemTrackingCode, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingSetup2.CopyTrackingFromItemTrackingCodeSpecificTracking(ItemTrackingCode);
        ItemTrackingSetup2.CopyTrackingFromItemLedgerEntry(FromItemLedgEntry);

        if (FromItemLedgEntry."Serial No." <> '') and (ItemTrackingSetup2."Serial No. Required") then
            ToItemLedgEntry.SetCurrentKey("Serial No.", "Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Entry No.")
        else
            ToItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Entry No.");
        ToItemLedgEntry.SetRange("Item No.", FromItemLedgEntry."Item No.");
        ToItemLedgEntry.SetRange(Open, true);
        ToItemLedgEntry.SetRange("Variant Code", FromItemLedgEntry."Variant Code");
        ToItemLedgEntry.SetRange(Positive, not FromItemLedgEntry.Positive);
        ToItemLedgEntry.SetRange("Location Code", FromItemLedgEntry."Location Code");
        if FromItemLedgEntry."Job Purchase" then begin
            ToItemLedgEntry.SetRange("Job No.", FromItemLedgEntry."Job No.");
            ToItemLedgEntry.SetRange("Job Task No.", FromItemLedgEntry."Job Task No.");
            ToItemLedgEntry.SetRange("Document Type", FromItemLedgEntry."Document Type");
            ToItemLedgEntry.SetRange("Document No.", FromItemLedgEntry."Document No.");
        end;

        ToItemLedgEntry.SetTrackingFilterFromItemTrackingSetupIfRequired(ItemTrackingSetup2);
        if (Location.Get(FromItemLedgEntry."Location Code") and Location."Use As In-Transit") or
           (FromItemLedgEntry."Location Code" = '') and
           (FromItemLedgEntry."Document Type" = FromItemLedgEntry."Document Type"::"Transfer Receipt")
        then begin
            ToItemLedgEntry.SetRange("Order Type", FromItemLedgEntry."Order Type"::Transfer);
            ToItemLedgEntry.SetRange("Order No.", FromItemLedgEntry."Order No.");
        end;

        OnAfterApplyItemLedgEntrySetFilters(ToItemLedgEntry, FromItemLedgEntry, ItemJnlLine);
    end;

    local procedure TestFirstApplyItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestFirstApplyItemLedgEntry(OldItemLedgEntry, ItemLedgEntry, ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        OldItemLedgEntry.TestField("Item No.", ItemLedgEntry."Item No.");
        OldItemLedgEntry.TestField("Variant Code", ItemLedgEntry."Variant Code");
        OldItemLedgEntry.TestField(Positive, not ItemLedgEntry.Positive);
        OldItemLedgEntry.TestField("Location Code", ItemLedgEntry."Location Code");
        if Location.Get(ItemLedgEntry."Location Code") then
            if Location."Use As In-Transit" then begin
                OldItemLedgEntry.TestField("Order Type", OldItemLedgEntry."Order Type"::Transfer);
                OldItemLedgEntry.TestField("Order No.", ItemLedgEntry."Order No.");
            end;

        TestFirstApplyItemLedgerEntryTracking(ItemLedgEntry, OldItemLedgEntry, GlobalItemTrackingCode);

        IsHandled := false;
        OnTestFirstApplyItemLedgEntryOnBeforeTestFields(OldItemLedgEntry, ItemLedgEntry, ItemJnlLine, IsHandled);
        if not IsHandled then
            if not (OldItemLedgEntry.Open and
                    (Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") >=
                     Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")))
            then
                if (Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") <=
                    Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity"))
                then begin
                    if not MoveApplication(ItemLedgEntry, OldItemLedgEntry) then
                        OldItemLedgEntry.FieldError("Remaining Quantity", Text004);
                end else
                    OldItemLedgEntry.TestField(Open, true);

        OnTestFirstApplyItemLedgEntryOnAfterTestFields(ItemLedgEntry, OldItemLedgEntry, ItemJnlLine);

        OldItemLedgEntry.CalcReservedQuantity();
        CheckApplication(ItemLedgEntry, OldItemLedgEntry);


        IsHandled := false;
        OnTestFirstApplyItemLedgEntryOnBeforeReservationPreventsApplication(OldItemLedgEntry, ItemLedgEntry, IsHandled);
        if not IsHandled then
            if Abs(OldItemLedgEntry."Remaining Quantity") <= Abs(OldItemLedgEntry."Reserved Quantity") then
                ReservationPreventsApplication(ItemLedgEntry."Applies-to Entry", ItemLedgEntry."Item No.", OldItemLedgEntry);

        if (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
           (OldItemLedgEntry."Order No." <> '')
        then
            if not AllowProdApplication(OldItemLedgEntry, ItemLedgEntry) then
                Error(
                  Text022,
                  ItemLedgEntry."Entry Type", OldItemLedgEntry."Entry Type", OldItemLedgEntry."Item No.", OldItemLedgEntry."Order No.");
    end;

    local procedure FindOpenItemLedgEntryToApply(var OpenItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"; var FirstApplication: Boolean; var EntryFindMethod: Text[1]): Boolean
    begin
        if FirstApplication then begin
            FirstApplication := false;
            ApplyItemLedgEntrySetFilters(OpenItemLedgEntry, ItemLedgEntry, GlobalItemTrackingCode);

            if Item."Costing Method" = Item."Costing Method"::LIFO then
                EntryFindMethod := '+'
            else
                EntryFindMethod := '-';

            exit(OpenItemLedgEntry.Find(EntryFindMethod));
        end else
            case EntryFindMethod of
                '-':
                    exit(OpenItemLedgEntry.Next() <> 0);
                '+':
                    exit(OpenItemLedgEntry.Next(-1) <> 0);
            end;
    end;

    local procedure TestFirstApplyItemLedgerEntryTracking(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code");
    begin
        if ItemTrackingCode."SN Specific Tracking" then
            OldItemLedgEntry.TestField("Serial No.", ItemLedgEntry."Serial No.");
        if ItemLedgEntry."Drop Shipment" and (OldItemLedgEntry."Serial No." <> '') then
            OldItemLedgEntry.TestField("Serial No.", ItemLedgEntry."Serial No.");

        if ItemTrackingCode."Lot Specific Tracking" then
            OldItemLedgEntry.TestField("Lot No.", ItemLedgEntry."Lot No.");
        if ItemLedgEntry."Drop Shipment" and (OldItemLedgEntry."Lot No." <> '') then
            OldItemLedgEntry.TestField("Lot No.", ItemLedgEntry."Lot No.");

        OnAfterTestFirstApplyItemLedgerEntryTracking(ItemLedgEntry, OldItemLedgEntry, ItemTrackingCode);
    end;

    local procedure UpdateOldItemLedgerEntryRemainingQuantity(var OldItemLedgerEntry: Record "Item Ledger Entry"; AppliedQty: Decimal)
    begin
        OldItemLedgerEntry."Remaining Quantity" := OldItemLedgerEntry."Remaining Quantity" + AppliedQty;
        OldItemLedgerEntry.Open := OldItemLedgerEntry."Remaining Quantity" <> 0;

        OnAfterUpdateOldItemLedgerEntryRemainingQuantity(OldItemLedgerEntry, AppliedQty, GlobalItemLedgEntry, AverageTransfer);
    end;

    local procedure EnsureValueEntryLoaded(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ValueEntry.ReadIsolation(IsolationLevel::ReadUnCommitted);
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntry."Entry No.");
        if ValueEntry.FindFirst() then;
    end;

    local procedure AllowProdApplication(OldItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"): Boolean
    var
        AllowApplication: Boolean;
    begin
        AllowApplication :=
          (OldItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type") or
          (OldItemLedgEntry."Order No." <> ItemLedgEntry."Order No.") or
          ((OldItemLedgEntry."Order No." = ItemLedgEntry."Order No.") and
           (OldItemLedgEntry."Order Line No." <> ItemLedgEntry."Order Line No."));

        OnBeforeAllowProdApplication(OldItemLedgEntry, ItemLedgEntry, AllowApplication);
        exit(AllowApplication);
    end;

    local procedure InitValueEntryNo()
    begin
        if ValueEntryNo <> 0 then
            exit;
        if not InvtSetup.UseLegacyPosting() then
            exit;
        GlobalValueEntry.LockTable();
        ValueEntryNo := GlobalValueEntry.GetLastEntryNo();
    end;

    local procedure InsertTransferEntry(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal)
    var
        NewItemLedgEntry: Record "Item Ledger Entry";
        NewValueEntry: Record "Value Entry";
        ItemLedgEntry2: Record "Item Ledger Entry";
        xValueEntryNo: Integer;
        IsReserved: Boolean;
        IsHandled: Boolean;
    begin
        InitItemLedgEntry(NewItemLedgEntry);
        NewItemLedgEntry."Applies-to Entry" := 0;
        NewItemLedgEntry.Quantity := -AppliedQty;
        NewItemLedgEntry."Invoiced Quantity" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry."Remaining Quantity" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry.Open := NewItemLedgEntry."Remaining Quantity" <> 0;
        NewItemLedgEntry.Positive := NewItemLedgEntry."Remaining Quantity" > 0;
        NewItemLedgEntry."Location Code" := ItemJnlLine."New Location Code";
        NewItemLedgEntry."Country/Region Code" := ItemJnlLine."Country/Region Code";
        InsertCountryCode(NewItemLedgEntry, ItemLedgEntry);
        NewItemLedgEntry.CopyTrackingFromNewItemJnlLine(ItemJnlLine);
        NewItemLedgEntry."Expiration Date" := ItemJnlLine."New Item Expiration Date";
        IsHandled := false;
        OnInsertTransferEntryOnTransferValues(NewItemLedgEntry, OldItemLedgEntry, ItemLedgEntry, ItemJnlLine, TempItemEntryRelation, IsHandled);
        if not IsHandled then
            if Item."Item Tracking Code" <> '' then begin
                TempItemEntryRelation."Item Entry No." := NewItemLedgEntry."Entry No.";
                // Save Entry No. in a global variable
                TempItemEntryRelation.CopyTrackingFromItemLedgEntry(NewItemLedgEntry);
                OnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, NewItemLedgEntry);
                TempItemEntryRelation.Insert();
            end;
        OnInsertTransferEntryOnBeforeInitTransValueEntry(TempItemEntryRelation, NewItemLedgEntry, Item);
        InitTransValueEntry(NewValueEntry, NewItemLedgEntry);

        OnInsertTransferEntryOnBeforeInsertApplEntry(NewItemLedgEntry, ItemLedgEntry);
        if AverageTransfer then begin
            InsertApplEntry(
              NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
              0, NewItemLedgEntry."Posting Date", NewItemLedgEntry.Quantity, true);
            NewItemLedgEntry."Completely Invoiced" := ItemLedgEntry."Completely Invoiced";
        end else begin
            InsertApplEntry(
              NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.", ItemLedgEntry."Entry No.",
              OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date", NewItemLedgEntry.Quantity, true);
            NewItemLedgEntry."Completely Invoiced" := OldItemLedgEntry."Completely Invoiced";
        end;

        IsHandled := false;
        OnInsertTransferEntryOnBeforeCalcIsReserved(ItemJnlLine, TempTrackingSpecification, NewItemLedgEntry, ItemLedgEntry, IsReserved, IsHandled);
        if not IsHandled then
            if NewItemLedgEntry.Quantity > 0 then
                IsReserved :=
                    ItemJnlLineReserve.TransferItemJnlToItemLedgEntry(
                        ItemJnlLine, NewItemLedgEntry, NewItemLedgEntry."Remaining Quantity", true);

        ApplyItemLedgEntry(NewItemLedgEntry, ItemLedgEntry2, NewValueEntry, true);
        AutoTrack(NewItemLedgEntry, IsReserved);

        OnBeforeInsertTransferEntry(NewItemLedgEntry, OldItemLedgEntry, ItemJnlLine);

        InsertItemLedgEntry(NewItemLedgEntry, true);
        InsertValueEntry(NewValueEntry, NewItemLedgEntry, true);

        UpdateUnitCost(NewValueEntry);

        xValueEntryNo := ValueEntryNo;
        OnAfterInsertTransferEntry(ItemJnlLine, NewItemLedgEntry, OldItemLedgEntry, NewValueEntry, ValueEntryNo);
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");
    end;

    /// <summary>
    /// Initializes the item ledger entry record from the global item journal line variable.
    /// </summary>
    /// <param name="ItemLedgEntry">Return value: Initialized item ledger entry.</param>
    procedure InitItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry")
    var
        xItemLedgEntryNo: Integer;
    begin
        ItemLedgEntryNo := GetNextItemLedgerEntryNo(ItemLedgEntryNo);

        ItemLedgEntry.Init();
        ItemLedgEntry."Entry No." := ItemLedgEntryNo;
        ItemLedgEntry."Item No." := ItemJnlLine."Item No.";
        ItemLedgEntry."Posting Date" := ItemJnlLine."Posting Date";
        ItemLedgEntry."Document Date" := ItemJnlLine."Document Date";
        ItemLedgEntry."Entry Type" := ItemJnlLine."Entry Type";
        ItemLedgEntry."Source No." := ItemJnlLine."Source No.";
        ItemLedgEntry."Document No." := ItemJnlLine."Document No.";
        ItemLedgEntry."Document Type" := ItemJnlLine."Document Type";
        ItemLedgEntry."Document Line No." := ItemJnlLine."Document Line No.";
        ItemLedgEntry."Order Type" := ItemJnlLine."Order Type";
        ItemLedgEntry."Order No." := ItemJnlLine."Order No.";
        ItemLedgEntry."Order Line No." := ItemJnlLine."Order Line No.";
        ItemLedgEntry."External Document No." := ItemJnlLine."External Document No.";
        ItemLedgEntry.Description := ItemJnlLine.Description;
        ItemLedgEntry."Location Code" := ItemJnlLine."Location Code";
        ItemLedgEntry."Applies-to Entry" := ItemJnlLine."Applies-to Entry";
        ItemLedgEntry."Source Type" := ItemJnlLine."Source Type";
        ItemLedgEntry."Transaction Type" := ItemJnlLine."Transaction Type";
        ItemLedgEntry."Transport Method" := ItemJnlLine."Transport Method";
        ItemLedgEntry."Country/Region Code" := ItemJnlLine."Country/Region Code";
        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer) and (ItemJnlLine."New Location Code" <> '') then begin
            if NewLocation.Code <> ItemJnlLine."New Location Code" then
                NewLocation.Get(ItemJnlLine."New Location Code");
            ItemLedgEntry."Country/Region Code" := NewLocation."Country/Region Code";
        end;
        ItemLedgEntry."Entry/Exit Point" := ItemJnlLine."Entry/Exit Point";
        ItemLedgEntry.Area := ItemJnlLine."Area";
        ItemLedgEntry."Transaction Specification" := ItemJnlLine."Transaction Specification";
        ItemLedgEntry."Drop Shipment" := ItemJnlLine."Drop Shipment";
        ItemLedgEntry."Assemble to Order" := ItemJnlLine."Assemble to Order";
        ItemLedgEntry."No. Series" := ItemJnlLine."Posting No. Series";
        GetInvtSetup();
        if (ItemLedgEntry.Description = Item.Description) and not InvtSetup."Copy Item Descr. to Entries" then
            ItemLedgEntry.Description := '';
        ItemLedgEntry."Variant Code" := ItemJnlLine."Variant Code";
        ItemLedgEntry."Unit of Measure Code" := ItemJnlLine."Unit of Measure Code";
        ItemLedgEntry."Qty. per Unit of Measure" := ItemJnlLine."Qty. per Unit of Measure";
        ItemLedgEntry."Derived from Blanket Order" := ItemJnlLine."Derived from Blanket Order";
        ItemLedgEntry."Item Reference No." := ItemJnlLine."Item Reference No.";
        ItemLedgEntry."Originally Ordered No." := ItemJnlLine."Originally Ordered No.";
        ItemLedgEntry."Originally Ordered Var. Code" := ItemJnlLine."Originally Ordered Var. Code";
        ItemLedgEntry."Out-of-Stock Substitution" := ItemJnlLine."Out-of-Stock Substitution";
        ItemLedgEntry."Item Category Code" := ItemJnlLine."Item Category Code";
        ItemLedgEntry.Nonstock := ItemJnlLine.Nonstock;
        ItemLedgEntry."Purchasing Code" := ItemJnlLine."Purchasing Code";
        ItemLedgEntry."Return Reason Code" := ItemJnlLine."Return Reason Code";
        ItemLedgEntry."Job No." := ItemJnlLine."Job No.";
        ItemLedgEntry."Job Task No." := ItemJnlLine."Job Task No.";
        ItemLedgEntry."Job Purchase" := ItemJnlLine."Job Purchase";
        ItemLedgEntry.CopyTrackingFromItemJnlLine(ItemJnlLine);
        ItemLedgEntry."Warranty Date" := ItemJnlLine."Warranty Date";
        ItemLedgEntry."Expiration Date" := ItemJnlLine."Item Expiration Date";
        ItemLedgEntry."Shpt. Method Code" := ItemJnlLine."Shpt. Method Code";

        ItemLedgEntry.Correction := ItemJnlLine.Correction;

        if ItemJnlLine."Entry Type" in
           [ItemJnlLine."Entry Type"::Sale,
            ItemJnlLine."Entry Type"::"Negative Adjmt.",
            ItemJnlLine."Entry Type"::Transfer,
            ItemJnlLine."Entry Type"::Consumption,
            ItemJnlLine."Entry Type"::"Assembly Consumption"]
        then begin
            ItemLedgEntry.Quantity := -ItemJnlLine.Quantity;
            ItemLedgEntry."Invoiced Quantity" := -ItemJnlLine."Invoiced Quantity";
        end else begin
            ItemLedgEntry.Quantity := ItemJnlLine.Quantity;
            ItemLedgEntry."Invoiced Quantity" := ItemJnlLine."Invoiced Quantity";
        end;
        if (ItemLedgEntry.Quantity < 0) and (ItemJnlLine."Entry Type" <> ItemJnlLine."Entry Type"::Transfer) then
            ItemLedgEntry."Shipped Qty. Not Returned" := ItemLedgEntry.Quantity;

        xItemLedgEntryNo := ItemLedgEntryNo;
        OnAfterInitItemLedgEntry(ItemLedgEntry, ItemJnlLine, ItemLedgEntryNo);
        ValidateSequenceNo(ItemLedgEntryNo, xItemLedgEntryNo, Database::"Item Ledger Entry");
    end;

    /// <summary>
    /// Creates an item ledger entry record with information from the global journal line.
    /// </summary>
    /// <remarks>
    /// If there is insufficient quantity of the item on the inventory, an error is raised.
    /// Inserts or update an item register record.
    /// </remarks>
    /// <param name="ItemLedgEntry">Return value: Created item ledger entry.</param>
    /// <param name="TransferItem">If true, new dimension information will be set.</param>
    procedure InsertItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry"; TransferItem: Boolean)
    var
        xItemLedgEntryNo: Integer;
        xItemApplnEntryNo: Integer;
        xValueEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertItemLedgEntryProcedure(ItemLedgEntry, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        if ItemLedgEntry.Open then begin
            IsHandled := false;
            OnInsertItemLedgEntryOnBeforeVerifyOnInventory(ItemJnlLine, ItemLedgEntry, IsHandled);
            if not IsHandled then
                ItemLedgEntry.VerifyOnInventory();

            IsHandled := false;
            OnInsertItemLedgEntryOnCheckItemTracking(ItemJnlLine, ItemLedgEntry, GlobalItemTrackingCode, IsHandled);
            if not IsHandled then
                if not ((ItemJnlLine."Document Type" in [ItemJnlLine."Document Type"::"Purchase Return Shipment", ItemJnlLine."Document Type"::"Purchase Receipt"]) and
                        (ItemJnlLine."Job No." <> ''))
                then
                    if (ItemLedgEntry.Quantity < 0) and GlobalItemTrackingCode.IsSpecific() then
                        Error(Text018, ItemJnlLine."Serial No.", ItemJnlLine."Lot No.", ItemJnlLine."Item No.", ItemJnlLine."Variant Code");

            if GlobalItemTrackingCode."SN Specific Tracking" then begin
                if ItemLedgEntry.Quantity > 0 then
                    CheckItemSerialNo(ItemJnlLine);

                IsHandled := false;
                OnInsertItemLedgEntryOnBeforeSNQtyCheck(ItemJnlLine, IsHandled);
                if not IsHandled then
                    if not (ItemLedgEntry.Quantity in [-1, 0, 1]) then
                        Error(Text033);
            end;

            if (ItemJnlLine."Document Type" <> ItemJnlLine."Document Type"::"Purchase Return Shipment") and (ItemJnlLine."Job No." = '') then
                if (Item.Reserve = Item.Reserve::Always) and (ItemLedgEntry.Quantity < 0) then begin
                    IsHandled := false;
                    OnInsertItemLedgEntryOnBeforeReservationError(ItemJnlLine, ItemLedgEntry, IsHandled, Location);
                    if not IsHandled then
                        Error(Text012, ItemLedgEntry."Item No.");
                end;
        end;

        if IsWarehouseReclassification(ItemJnlLine) then begin
            ItemLedgEntry."Global Dimension 1 Code" := OldItemLedgEntry."Global Dimension 1 Code";
            ItemLedgEntry."Global Dimension 2 Code" := OldItemLedgEntry."Global Dimension 2 Code";
            ItemLedgEntry."Dimension Set ID" := OldItemLedgEntry."Dimension Set ID"
        end else
            if TransferItem then begin
                ItemLedgEntry."Global Dimension 1 Code" := ItemJnlLine."New Shortcut Dimension 1 Code";
                ItemLedgEntry."Global Dimension 2 Code" := ItemJnlLine."New Shortcut Dimension 2 Code";
                ItemLedgEntry."Dimension Set ID" := ItemJnlLine."New Dimension Set ID";
            end else begin
                ItemLedgEntry."Global Dimension 1 Code" := ItemJnlLine."Shortcut Dimension 1 Code";
                ItemLedgEntry."Global Dimension 2 Code" := ItemJnlLine."Shortcut Dimension 2 Code";
                ItemLedgEntry."Dimension Set ID" := ItemJnlLine."Dimension Set ID";
            end;

        if not (ItemJnlLine."Entry Type" in [ItemJnlLine."Entry Type"::Transfer, ItemJnlLine."Entry Type"::Output]) and
           (ItemLedgEntry.Quantity = ItemLedgEntry."Invoiced Quantity")
        then
            ItemLedgEntry."Completely Invoiced" := true;

        if (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and (ItemJnlLine."Item Charge No." = '') and
           (ItemJnlLine."Invoiced Quantity" <> 0) and (ItemJnlLine."Posting Date" > ItemLedgEntry."Last Invoice Date")
        then
            ItemLedgEntry."Last Invoice Date" := ItemJnlLine."Posting Date";

        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Consumption then
            ItemLedgEntry."Applied Entry to Adjust" := true;

        if ItemJnlLine."Job No." <> '' then begin
            ItemLedgEntry."Job No." := ItemJnlLine."Job No.";
            ItemLedgEntry."Job Task No." := ItemJnlLine."Job Task No.";
            ItemLedgEntry."Order Line No." := ItemJnlLine."Job Contract Entry No.";
        end;

        ItemLedgEntry.UpdateItemTracking();

        OnBeforeInsertItemLedgEntry(ItemLedgEntry, ItemJnlLine, TransferItem, OldItemLedgEntry, ItemJnlLineOrigin);

        InsertItemReg(ItemLedgEntry."Entry No.", 0, 0, 0);
        ItemLedgEntry."Item Register No." := ItemReg."No.";
        ItemLedgEntry.Insert(true);

        xItemLedgEntryNo := ItemLedgEntryNo;
        xItemApplnEntryNo := ItemApplnEntryNo;
        xValueEntryNo := ValueEntryNo;
        OnAfterInsertItemLedgEntry(ItemLedgEntry, ItemJnlLine, ItemLedgEntryNo, ValueEntryNo, ItemApplnEntryNo, GlobalValueEntry, TransferItem, InventoryPostingToGL, OldItemLedgEntry);
        ValidateSequenceNo(ItemLedgEntryNo, xItemLedgEntryNo, Database::"Item Ledger Entry");
        ValidateSequenceNo(ItemApplnEntryNo, xItemApplnEntryNo, Database::"Item Application Entry");
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");
    end;

    local procedure InsertItemReg(ItemLedgEntryNo: Integer; PhysInvtEntryNo: Integer; ValueEntryNo: Integer; CapLedgEntryNo: Integer)
    begin
        if ItemReg."No." = 0 then begin
            ItemReg."No." := ItemReg.GetNextEntryNo(InvtSetup.UseLegacyPosting());
            ItemReg.Init();
            ItemReg."From Entry No." := ItemLedgEntryNo;
            ItemReg."To Entry No." := ItemLedgEntryNo;
            ItemReg."From Phys. Inventory Entry No." := PhysInvtEntryNo;
            ItemReg."To Phys. Inventory Entry No." := PhysInvtEntryNo;
            ItemReg."From Value Entry No." := ValueEntryNo;
            ItemReg."To Value Entry No." := ValueEntryNo;
            ItemReg."From Capacity Entry No." := CapLedgEntryNo;
            ItemReg."To Capacity Entry No." := CapLedgEntryNo;
            ItemReg."Creation Date" := Today;
            ItemReg."Creation Time" := Time;
            ItemReg."Source Code" := ItemJnlLine."Source Code";
            ItemReg."Journal Batch Name" := ItemJnlLine."Journal Batch Name";
            ItemReg."User ID" := CopyStr(UserId(), 1, MaxStrLen(ItemReg."User ID"));
            OnInsertItemRegOnBeforeItemRegInsert(ItemReg, ItemJnlLine);
            ItemReg.Insert();
        end else begin
            if ((ItemLedgEntryNo < ItemReg."From Entry No.") and (ItemLedgEntryNo <> 0)) or
               ((ItemReg."From Entry No." = 0) and (ItemLedgEntryNo <> 0))
            then
                ItemReg."From Entry No." := ItemLedgEntryNo;
            if ItemLedgEntryNo > ItemReg."To Entry No." then
                ItemReg."To Entry No." := ItemLedgEntryNo;

            if ((PhysInvtEntryNo < ItemReg."From Phys. Inventory Entry No.") and (PhysInvtEntryNo <> 0)) or
               ((ItemReg."From Phys. Inventory Entry No." = 0) and (PhysInvtEntryNo <> 0))
            then
                ItemReg."From Phys. Inventory Entry No." := PhysInvtEntryNo;
            if PhysInvtEntryNo > ItemReg."To Phys. Inventory Entry No." then
                ItemReg."To Phys. Inventory Entry No." := PhysInvtEntryNo;

            if ((ValueEntryNo < ItemReg."From Value Entry No.") and (ValueEntryNo <> 0)) or
               ((ItemReg."From Value Entry No." = 0) and (ValueEntryNo <> 0))
            then
                ItemReg."From Value Entry No." := ValueEntryNo;
            if ValueEntryNo > ItemReg."To Value Entry No." then
                ItemReg."To Value Entry No." := ValueEntryNo;
            if ((CapLedgEntryNo < ItemReg."From Capacity Entry No.") and (CapLedgEntryNo <> 0)) or
               ((ItemReg."From Capacity Entry No." = 0) and (CapLedgEntryNo <> 0))
            then
                ItemReg."From Capacity Entry No." := CapLedgEntryNo;
            if CapLedgEntryNo > ItemReg."To Capacity Entry No." then
                ItemReg."To Capacity Entry No." := CapLedgEntryNo;

            ItemReg.Modify();
        end;
    end;

    local procedure GetNextValueEntryNo(CurrValueEntryNo: Integer): Integer
    begin
        if InvtSetup.UseLegacyPosting() then
            exit(CurrValueEntryNo + 1);
        exit(GlobalValueEntry.GetNextEntryNo());
    end;

    local procedure GetNextItemLedgerEntryNo(CurrEntryNo: Integer): Integer
    begin
        if InvtSetup.UseLegacyPosting() then
            exit(CurrEntryNo + 1);
        exit(GlobalItemLedgEntry.GetNextEntryNo());
    end;

    /// <summary>
    /// Inserts a physical inventory ledger entry based on a given item journal line.
    /// </summary>
    /// <param name="ItemJournalLine">Item journal line to insert from.</param>
    procedure InsertPhysInventoryEntry(var ItemJournalLine: Record "Item Journal Line")
    var
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertPhysInventoryEntry(ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        if InvtSetup.UseLegacyPosting() then begin
            if PhysInvtEntryNo = 0 then begin
                PhysInvtLedgEntry.LockTable();
                PhysInvtEntryNo := PhysInvtLedgEntry.GetLastEntryNo();
            end;
            PhysInvtEntryNo := PhysInvtEntryNo + 1;
        end else
            PhysInvtEntryNo := PhysInvtLedgEntry.GetNextEntryNo();

        PhysInvtLedgEntry.Init();
        PhysInvtLedgEntry."Entry No." := PhysInvtEntryNo;
        PhysInvtLedgEntry."Item No." := ItemJournalLine."Item No.";
        PhysInvtLedgEntry."Posting Date" := ItemJournalLine."Posting Date";
        PhysInvtLedgEntry."Document Date" := ItemJournalLine."Document Date";
        PhysInvtLedgEntry."Entry Type" := ItemJournalLine."Entry Type";
        PhysInvtLedgEntry."Document No." := ItemJournalLine."Document No.";
        PhysInvtLedgEntry."External Document No." := ItemJournalLine."External Document No.";
        PhysInvtLedgEntry.Description := ItemJournalLine.Description;
        PhysInvtLedgEntry."Location Code" := ItemJournalLine."Location Code";
        PhysInvtLedgEntry."Inventory Posting Group" := ItemJournalLine."Inventory Posting Group";
        PhysInvtLedgEntry."Unit Cost" := ItemJournalLine."Unit Cost";
        PhysInvtLedgEntry.Amount := ItemJournalLine.Amount;
        PhysInvtLedgEntry."Salespers./Purch. Code" := ItemJournalLine."Salespers./Purch. Code";
        PhysInvtLedgEntry."Source Code" := ItemJournalLine."Source Code";
        PhysInvtLedgEntry."Global Dimension 1 Code" := ItemJournalLine."Shortcut Dimension 1 Code";
        PhysInvtLedgEntry."Global Dimension 2 Code" := ItemJournalLine."Shortcut Dimension 2 Code";
        PhysInvtLedgEntry."Dimension Set ID" := ItemJournalLine."Dimension Set ID";
        PhysInvtLedgEntry."Journal Batch Name" := ItemJournalLine."Journal Batch Name";
        PhysInvtLedgEntry."Reason Code" := ItemJournalLine."Reason Code";
        PhysInvtLedgEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(PhysInvtLedgEntry."User ID"));
        PhysInvtLedgEntry."No. Series" := ItemJournalLine."Posting No. Series";
        GetInvtSetup();
        if (PhysInvtLedgEntry.Description = Item.Description) and not InvtSetup."Copy Item Descr. to Entries" then
            PhysInvtLedgEntry.Description := '';
        PhysInvtLedgEntry."Variant Code" := ItemJournalLine."Variant Code";
        PhysInvtLedgEntry."Unit of Measure Code" := ItemJournalLine."Unit of Measure Code";

        PhysInvtLedgEntry.Quantity := ItemJournalLine.Quantity;
        PhysInvtLedgEntry."Unit Amount" := ItemJournalLine."Unit Amount";
        PhysInvtLedgEntry."Qty. (Calculated)" := ItemJournalLine."Qty. (Calculated)";
        PhysInvtLedgEntry."Qty. (Phys. Inventory)" := ItemJournalLine."Qty. (Phys. Inventory)";
        PhysInvtLedgEntry."Last Item Ledger Entry No." := ItemJournalLine."Last Item Ledger Entry No.";

        PhysInvtLedgEntry."Phys Invt Counting Period Code" :=
          ItemJournalLine."Phys Invt Counting Period Code";
        PhysInvtLedgEntry."Phys Invt Counting Period Type" :=
          ItemJournalLine."Phys Invt Counting Period Type";

        OnBeforeInsertPhysInvtLedgEntry(PhysInvtLedgEntry, ItemJournalLine, ItemJnlLine);

        InsertItemReg(0, PhysInvtLedgEntry."Entry No.", 0, 0);
        PhysInvtLedgEntry."Item Register No." := ItemReg."No.";
        PhysInvtLedgEntry.Insert(true);

        OnAfterInsertPhysInventoryEntry(PhysInvtLedgEntry, ItemJnlLineOrigin);
    end;

    /// <summary>
    /// Posts inventory transactions to the general ledger based on the provided value entry.
    /// </summary>
    /// <param name="ValueEntry">Value entry to post from.</param>
    procedure PostInventoryToGL(var ValueEntry: Record "Value Entry")
    var
        IsHandled: Boolean;
    begin
        if Item."No." <> ValueEntry."Item No." then
            Item.Get(ValueEntry."Item No.");

        IsHandled := false;
        OnBeforePostInventoryToGL(ValueEntry, IsHandled, ItemJnlLine, PostToGL, CalledFromAdjustment, Item."Inventory Value Zero");
        if IsHandled then
            exit;

        if not ValueEntry.Inventoriable or
           not CalledFromAdjustment and Item."Inventory Value Zero" or
           CalledFromAdjustment and not PostToGL
        then
            exit;

        IsHandled := false;
        OnBeforePostValueEntryToGL(ValueEntry, IsHandled);
        if IsHandled then
            exit;
        PostValueEntryToGL(ValueEntry);
    end;

    /// <summary>
    /// Posts inventory transactions to the general ledger based on the provided value entry.
    /// </summary>
    /// <param name="ValueEntry">Value entry to post from.</param>
    internal procedure PostValueEntryToGL(var ValueEntry: Record "Value Entry")
    begin
        InventoryPostingToGL.SetRunOnlyCheck(true, not PostToGL, false);
        OnPostInventoryToGLOnBeforePostInvtBuffer(InventoryPostingToGL, PostToGL);
        PostInvtBuffer(ValueEntry);
        OnPostInventoryToGLOnAfterPostInvtBuffer(ValueEntry);

        if ValueEntry."Expected Cost" then begin
            if (ValueEntry."Cost Amount (Expected)" = 0) and (ValueEntry."Cost Amount (Expected) (ACY)" = 0) then
                SetValueEntry(ValueEntry, 1, 1, false)
            else
                SetValueEntry(ValueEntry, ValueEntry."Cost Amount (Expected)", ValueEntry."Cost Amount (Expected) (ACY)", false);
            InventoryPostingToGL.SetRunOnlyCheck(true, true, false);
            PostInvtBuffer(ValueEntry);
            SetValueEntry(ValueEntry, 0, 0, true);
        end else
            if (ValueEntry."Cost Amount (Actual)" = 0) and (ValueEntry."Cost Amount (Actual) (ACY)" = 0) then begin
                SetValueEntry(ValueEntry, 1, 1, false);
                InventoryPostingToGL.SetRunOnlyCheck(true, true, false);
                PostInvtBuffer(ValueEntry);
                SetValueEntry(ValueEntry, 0, 0, false);
            end;

        OnAfterPostInventoryToGL(ValueEntry);
    end;

    local procedure SetValueEntry(var ValueEntry: Record "Value Entry"; CostAmtActual: Decimal; CostAmtActACY: Decimal; ExpectedCost: Boolean)
    begin
        ValueEntry."Cost Amount (Actual)" := CostAmtActual;
        ValueEntry."Cost Amount (Actual) (ACY)" := CostAmtActACY;
        ValueEntry."Expected Cost" := ExpectedCost;
    end;

    /// <summary>
    /// Creates an item application entry.
    /// </summary>
    /// <remarks>
    /// If the item is non-inventoriable, procedure is not executed.
    /// </remarks>
    /// <param name="ItemLedgEntryNo">Item ledger entry no.</param>
    /// <param name="InboundItemEntry">Inbound item ledger entry no.</param>
    /// <param name="OutboundItemEntry">Outbound item ledger entry no.</param>
    /// <param name="TransferedFromEntryNo">Transferred-from entry no.</param>
    /// <param name="PostingDate">Item ledger entry posting date.</param>
    /// <param name="Quantity">Item ledger entry quantity.</param>
    /// <param name="CostToApply">If true, then cost application will be set to true.</param>
    procedure InsertApplEntry(ItemLedgEntryNo: Integer; InboundItemEntry: Integer; OutboundItemEntry: Integer; TransferedFromEntryNo: Integer; PostingDate: Date; Quantity: Decimal; CostToApply: Boolean)
    var
        ApplItemLedgEntry: Record "Item Ledger Entry";
        OldItemApplnEntry: Record "Item Application Entry";
        ItemApplHistoryEntry: Record "Item Application Entry History";
        ItemApplnEntryExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertApplEntry(
            ItemLedgEntryNo, InboundItemEntry, OutboundItemEntry, TransferedFromEntryNo, PostingDate, Quantity, CostToApply, IsHandled);
        if IsHandled then
            exit;

        if Item.IsNonInventoriableType() then
            exit;

        if (ItemApplnEntryNo = 0) and InvtSetup.UseLegacyPosting() then begin
            ItemApplnEntry.Reset();
            ItemApplnEntry.LockTable();
            ItemApplnEntryNo := ItemApplnEntry.GetLastEntryNo();
            if ItemApplnEntryNo > 0 then begin
                ItemApplHistoryEntry.Reset();
                ItemApplHistoryEntry.LockTable();
                ItemApplHistoryEntry.SetCurrentKey("Entry No.");
                if ItemApplHistoryEntry.FindLast() then
                    if ItemApplHistoryEntry."Entry No." > ItemApplnEntryNo then
                        ItemApplnEntryNo := ItemApplHistoryEntry."Entry No.";
            end else
                ItemApplnEntryNo := 0;
        end;

        if Quantity < 0 then begin
            OldItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            OldItemApplnEntry.SetRange("Inbound Item Entry No.", InboundItemEntry);
            OldItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
            OldItemApplnEntry.SetRange("Outbound Item Entry No.", OutboundItemEntry);
            if OldItemApplnEntry.FindFirst() then begin
                ItemApplnEntry := OldItemApplnEntry;
                ItemApplnEntry.Quantity := ItemApplnEntry.Quantity + Quantity;
                ItemApplnEntry."Last Modified Date" := CurrentDateTime;
                ItemApplnEntry."Last Modified By User" := UserId;

                OnInsertApplEntryOnBeforeModify(ItemApplnEntry);

                ItemApplnEntry.Modify();
                ItemApplnEntryExists := true;
            end;
        end;

        if not ItemApplnEntryExists then begin
            if InvtSetup.UseLegacyPosting() then
                ItemApplnEntryNo := ItemApplnEntryNo + 1
            else
                ItemApplnEntryNo := ItemApplnEntry.GetNextEntryNo();
            ItemApplnEntry.Init();
            ItemApplnEntry."Entry No." := ItemApplnEntryNo;
            ItemApplnEntry."Item Ledger Entry No." := ItemLedgEntryNo;
            ItemApplnEntry."Inbound Item Entry No." := InboundItemEntry;
            ItemApplnEntry."Outbound Item Entry No." := OutboundItemEntry;
            ItemApplnEntry."Transferred-from Entry No." := TransferedFromEntryNo;
            ItemApplnEntry.Quantity := Quantity;
            ItemApplnEntry."Posting Date" := PostingDate;
            ItemApplnEntry."Output Completely Invd. Date" := GetOutputComplInvcdDate(ItemApplnEntry);

            if AverageTransfer then begin
                if (Quantity > 0) or (ItemJnlLine."Document Type" = ItemJnlLine."Document Type"::"Transfer Receipt") then
                    ItemApplnEntry."Cost Application" :=
                      ItemApplnEntry.IsOutbndItemApplEntryCostApplication(ItemLedgEntryNo) and IsNotValuedByAverageCost(ItemLedgEntryNo);
            end else
                case true of
                    Item."Costing Method" <> Item."Costing Method"::Average,
                  ItemJnlLine.Correction and (ItemJnlLine."Document Type" = ItemJnlLine."Document Type"::"Posted Assembly"):
                        ItemApplnEntry."Cost Application" := true;
                    ItemJnlLine.Correction:
                        begin
                            if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Output) and (ItemJnlLine."Order Type" = ItemJnlLine."Order Type"::Production) and ItemJnlLine.Subcontracting then
                                ApplItemLedgEntry := GlobalItemLedgEntry
                            else
                                ApplItemLedgEntry.Get(ItemApplnEntry."Item Ledger Entry No.");
                            ItemApplnEntry."Cost Application" :=
                              (ApplItemLedgEntry.Quantity > 0) or (ApplItemLedgEntry."Applies-to Entry" <> 0);
                        end;
                    else
                        if (ItemJnlLine."Applies-to Entry" <> 0) or
                           (CostToApply and ItemJnlLine.IsInbound())
                        then
                            ItemApplnEntry."Cost Application" := true;
                end;

            ItemApplnEntry."Creation Date" := CurrentDateTime;
            ItemApplnEntry."Created By User" := UserId;
            OnBeforeItemApplnEntryInsert(ItemApplnEntry, GlobalItemLedgEntry, OldItemLedgEntry, ItemApplnEntryNo);
            ItemApplnEntry.Insert(true);
            OnAfterItemApplnEntryInsert(ItemApplnEntry, GlobalItemLedgEntry, OldItemLedgEntry);
        end;
    end;

    local procedure UpdateItemApplnEntry(ItemLedgEntryNo: Integer; PostingDate: Date)
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        ItemApplnEntry.SetRange("Output Completely Invd. Date", 0D);
        OnUpdateItemApplnEntryOnAfterFilterItemApplicationEntry(ItemApplnEntry);
        if not ItemApplnEntry.IsEmpty() then
            ItemApplnEntry.ModifyAll("Output Completely Invd. Date", PostingDate);
    end;

    local procedure GetOutputComplInvcdDate(ItemApplnEntry: Record "Item Application Entry"): Date
    var
        OutbndItemLedgEntry: Record "Item Ledger Entry";
    begin
        if ItemApplnEntry.Quantity > 0 then
            exit(ItemApplnEntry."Posting Date");
        if OutbndItemLedgEntry.Get(ItemApplnEntry."Outbound Item Entry No.") then
            if OutbndItemLedgEntry."Completely Invoiced" then
                exit(OutbndItemLedgEntry."Last Invoice Date");
    end;

    local procedure InitValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        CalcUnitCost: Boolean;
        InvoicedQuantityNotEmpty: Boolean;
        CostAmt: Decimal;
        CostAmtACY: Decimal;
        xValueEntryNo: Integer;
    begin
        xValueEntryNo := ValueEntryNo;
        OnBeforeInitValueEntry(ValueEntry, ValueEntryNo, ItemJnlLine);
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");

        ValueEntryNo := GetNextValueEntryNo(ValueEntryNo);
        ValueEntry.Init();
        ValueEntry."Entry No." := ValueEntryNo;
        if ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::Variance then
            ValueEntry."Variance Type" := ItemJnlLine."Variance Type";
        ValueEntry."Item Ledger Entry No." := ItemLedgerEntry."Entry No.";
        ValueEntry."Item No." := ItemJnlLine."Item No.";
        ValueEntry."Item Charge No." := ItemJnlLine."Item Charge No.";
        ValueEntry."Order Type" := ItemLedgerEntry."Order Type";
        ValueEntry."Order No." := ItemLedgerEntry."Order No.";
        ValueEntry."Order Line No." := ItemLedgerEntry."Order Line No.";
        ValueEntry."Item Ledger Entry Type" := ItemJnlLine."Entry Type";
        ValueEntry.Type := ItemJnlLine.Type;
        ValueEntry."Posting Date" := ItemJnlLine."Posting Date";
        ValueEntry."VAT Reporting Date" := ItemJnlLine."VAT Reporting Date";
        if ItemJnlLine."Partial Revaluation" then
            ValueEntry."Partial Revaluation" := true;

        OnInitValueEntryOnAfterAssignFields(ValueEntry, ItemLedgerEntry, ItemJnlLine);

        if (ItemLedgerEntry.Quantity > 0) or
            (ItemLedgerEntry."Invoiced Quantity" > 0) or
            ((ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and (ItemJnlLine."Item Charge No." = '')) or
            (ItemJnlLine."Entry Type" in [ItemJnlLine."Entry Type"::Output, ItemJnlLine."Entry Type"::"Assembly Output"]) or
            ItemJnlLine.Adjustment
        then
            ValueEntry.Inventoriable := Item.Type = Item.Type::Inventory;

        OnInitValueEntryOnAfterSetValueEntryInventoriable(ValueEntry, ItemJnlLine);

        if ((ItemJnlLine.Quantity = 0) and (ItemJnlLine."Invoiced Quantity" <> 0)) or
            (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::"Direct Cost") or
            (ItemJnlLine."Item Charge No." <> '') or ItemJnlLine.Adjustment
        then begin
            GetLastDirectCostValEntry(ValueEntry."Item Ledger Entry No.");
            if ValueEntry.Inventoriable and (ItemJnlLine."Item Charge No." = '') then
                ValueEntry."Valued By Average Cost" := DirCostValueEntry."Valued By Average Cost";
        end;

        case true of
            ((ItemJnlLine.Quantity = 0) and (ItemJnlLine."Invoiced Quantity" <> 0)) or
            ((ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and (ItemJnlLine."Item Charge No." <> '')) or
            ItemJnlLine.Adjustment or (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::Rounding):
                ValueEntry."Valuation Date" := DirCostValueEntry."Valuation Date";
            (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::Revaluation):
                if ItemJnlLine."Posting Date" < DirCostValueEntry."Valuation Date" then
                    ValueEntry."Valuation Date" := DirCostValueEntry."Valuation Date"
                else
                    ValueEntry."Valuation Date" := ItemJnlLine."Posting Date";
            (ItemLedgerEntry.Quantity > 0) and (ItemJnlLine."Applies-from Entry" <> 0):
                GetAppliedFromValues(ValueEntry);
            else
                ValueEntry."Valuation Date" := ItemJnlLine."Posting Date";
        end;

        GetInvtSetup();
        if (ItemJnlLine.Description = Item.Description) and not InvtSetup."Copy Item Descr. to Entries" then
            ValueEntry.Description := ''
        else
            ValueEntry.Description := ItemJnlLine.Description;

        SetValueEntrySourceFieldsFromItemJnlLine(ValueEntry, ItemJnlLine);
        if (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and (ItemJnlLine."Item Charge No." = '') then
            ValueEntry."Inventory Posting Group" := ItemJnlLine."Inventory Posting Group"
        else
            ValueEntry."Inventory Posting Group" := DirCostValueEntry."Inventory Posting Group";
        ValueEntry."Source Posting Group" := ItemJnlLine."Source Posting Group";
        ValueEntry."Salespers./Purch. Code" := ItemJnlLine."Salespers./Purch. Code";
        ValueEntry."Location Code" := ItemLedgerEntry."Location Code";
        ValueEntry."Variant Code" := ItemLedgerEntry."Variant Code";
        ValueEntry."Journal Batch Name" := ItemJnlLine."Journal Batch Name";
        ValueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(ValueEntry."User ID"));
        ValueEntry."Drop Shipment" := ItemJnlLine."Drop Shipment";
        ValueEntry."Reason Code" := ItemJnlLine."Reason Code";
        ValueEntry."Return Reason Code" := ItemJnlLine."Return Reason Code";
        ValueEntry."External Document No." := ItemJnlLine."External Document No.";
        ValueEntry."Document Date" := ItemJnlLine."Document Date";
        ValueEntry."Gen. Bus. Posting Group" := ItemJnlLine."Gen. Bus. Posting Group";
        ValueEntry."Gen. Prod. Posting Group" := ItemJnlLine."Gen. Prod. Posting Group";
        ValueEntry."Discount Amount" := ItemJnlLine."Discount Amount";
        ValueEntry."Entry Type" := ItemJnlLine."Value Entry Type";
        if ItemJnlLine."Job No." <> '' then begin
            ValueEntry."Job No." := ItemJnlLine."Job No.";
            ValueEntry."Job Task No." := ItemJnlLine."Job Task No.";
        end;
        InvoicedQuantityNotEmpty := ItemJnlLine."Invoiced Quantity" <> 0;
        OnInitValueEntryOnAfterCalcInvoicedQuantityNotEmpty(ItemJnlLine, InvoicedQuantityNotEmpty);
        if InvoicedQuantityNotEmpty then begin
            ValueEntry."Valued Quantity" := ItemJnlLine."Invoiced Quantity";
            if (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and
                (ItemJnlLine."Item Charge No." = '')
            then
                if (ItemJnlLine."Entry Type" <> ItemJnlLine."Entry Type"::Output) or
                    (ItemLedgerEntry."Invoiced Quantity" = 0)
                then
                    ValueEntry."Invoiced Quantity" := ItemJnlLine."Invoiced Quantity";
            ValueEntry."Expected Cost" := false;
        end else begin
            ValueEntry."Valued Quantity" := ItemJnlLine.Quantity;
            ValueEntry."Expected Cost" := ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Revaluation;
        end;

        ValueEntry."Document Type" := ItemJnlLine."Document Type";
        if ValueEntry."Expected Cost" or (ItemJnlLine."Invoice No." = '') then
            ValueEntry."Document No." := ItemJnlLine."Document No."
        else begin
            ValueEntry."Document No." := ItemJnlLine."Invoice No.";
            if ItemJnlLine."Document Type" in [
                                    ItemJnlLine."Document Type"::"Purchase Receipt", ItemJnlLine."Document Type"::"Purchase Return Shipment",
                                    ItemJnlLine."Document Type"::"Sales Shipment", ItemJnlLine."Document Type"::"Sales Return Receipt",
                                    ItemJnlLine."Document Type"::"Service Shipment"]
            then
                ValueEntry."Document Type" := Enum::"Item Ledger Document Type".FromInteger(ItemJnlLine."Document Type".AsInteger() + 1);
        end;
        OnInitValueEntryOnBeforeSetDocumentLineNo(ItemJnlLine, ItemLedgerEntry, ValueEntry);
        ValueEntry."Document Line No." := ItemJnlLine."Document Line No.";

        if ItemJnlLine.Adjustment then begin
            ValueEntry."Invoiced Quantity" := 0;
            ValueEntry."Applies-to Entry" := ItemJnlLine."Applies-to Value Entry";
            ValueEntry.Adjustment := true;
        end;

        if ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Rounding then begin
            if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Output) and
                (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Revaluation)
            then begin
                CostAmt := ItemJnlLine.Amount;
                CostAmtACY := ItemJnlLine."Amount (ACY)";
            end else begin
                ValueEntry."Cost per Unit" := RetrieveCostPerUnit(ItemJnlLine, SKU, SKUExists);
                if GLSetup."Additional Reporting Currency" <> '' then
                    ValueEntry."Cost per Unit (ACY)" := RetrieveCostPerUnitACY(ValueEntry."Cost per Unit");

                if (ValueEntry."Valued Quantity" > 0) and
                    (ValueEntry."Item Ledger Entry Type" in [ValueEntry."Item Ledger Entry Type"::Purchase,
                                                            ValueEntry."Item Ledger Entry Type"::"Assembly Output"]) and
                    (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
                    not ItemJnlLine.Adjustment
                then begin
                    if Item."Costing Method" = Item."Costing Method"::Standard then
                        ItemJnlLine."Unit Cost" := ValueEntry."Cost per Unit";
                    CalcPosShares(
                        CostAmt, OverheadAmount, VarianceAmount, CostAmtACY, OverheadAmountACY, VarianceAmountACY,
                        CalcUnitCost, (Item."Costing Method" = Item."Costing Method"::Standard) and
                        (not ValueEntry."Expected Cost"), ValueEntry."Expected Cost");
                    if (OverheadAmount <> 0) or
                        (Round(VarianceAmount, GLSetup."Amount Rounding Precision") <> 0) or
                        CalcUnitCost or ValueEntry."Expected Cost"
                    then begin
                        ValueEntry."Cost per Unit" :=
                            CalcCostPerUnit(CostAmt, ValueEntry."Valued Quantity", false);

                        if GLSetup."Additional Reporting Currency" <> '' then
                            ValueEntry."Cost per Unit (ACY)" :=
                                CalcCostPerUnit(CostAmtACY, ValueEntry."Valued Quantity", true);
                    end;
                end else
                    if not ItemJnlLine.Adjustment then
                        CalcOutboundCostAmt(ValueEntry, CostAmt, CostAmtACY)
                    else begin
                        CostAmt := ItemJnlLine.Amount;
                        CostAmtACY := ItemJnlLine."Amount (ACY)";
                    end;

                if (ItemJnlLine."Invoiced Quantity" < 0) and (ItemJnlLine."Applies-to Entry" <> 0) and
                    (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Purchase) and (ItemJnlLine."Item Charge No." = '') and
                    (ValueEntry."Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost")
                then begin
                    CalcPurchCorrShares(OverheadAmount, OverheadAmountACY, VarianceAmount, VarianceAmountACY);
                    SetCostAmountAndCostAmountFCYOnSameCostPerUnit(ItemJnlLine, CostAmt, CostAmtACY);
                    OnAfterCalcPurchCorrShares(
                        ValueEntry, ItemJnlLine, OverheadAmount, OverheadAmountACY, VarianceAmount, VarianceAmountACY);
                end;
            end;
            OnInitValueEntryOnAfterCalcDirestCost(CostAmt, VarianceAmount, Item, ItemJnlLine, ValueEntry, CostAmtACY, VarianceAmountACY);
        end else begin
            CostAmt := ItemJnlLine."Unit Cost";
            CostAmtACY := ItemJnlLine."Unit Cost (ACY)";
        end;

        if (ValueEntry."Entry Type" <> ValueEntry."Entry Type"::Revaluation) and not ItemJnlLine.Adjustment then
            if (ValueEntry."Item Ledger Entry Type" in
                [ValueEntry."Item Ledger Entry Type"::Sale,
                    ValueEntry."Item Ledger Entry Type"::"Negative Adjmt.",
                    ValueEntry."Item Ledger Entry Type"::Consumption,
                    ValueEntry."Item Ledger Entry Type"::"Assembly Consumption"]) or
                ((ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Transfer) and
                (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and (ItemJnlLine."Item Charge No." = ''))
            then begin
                ValueEntry."Valued Quantity" := -ValueEntry."Valued Quantity";
                ValueEntry."Invoiced Quantity" := -ValueEntry."Invoiced Quantity";
                if ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Transfer then
                    ValueEntry."Discount Amount" := 0
                else
                    ValueEntry."Discount Amount" := -ValueEntry."Discount Amount";

                if ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Rounding then begin
                    CostAmt := -CostAmt;
                    CostAmtACY := -CostAmtACY;
                end;
            end;
        if not ItemJnlLine.Adjustment then
            if Item."Inventory Value Zero" or
                ((ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer) and
                (ValueEntry."Valued Quantity" < 0) and not AverageTransfer) or
                ((ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Sale) and
                (ItemJnlLine."Item Charge No." <> ''))
            then begin
                CostAmt := 0;
                CostAmtACY := 0;
                ValueEntry."Cost per Unit" := 0;
                ValueEntry."Cost per Unit (ACY)" := 0;
                OnInitValueEntryOnAfterNotAdjustmentCheckClearCostAmount(ValueEntry, ItemJnlLine);
            end;

        case true of
            (not ValueEntry."Expected Cost") and ValueEntry.Inventoriable and
            IsInterimRevaluation():
                begin
                    ValueEntry."Cost Amount (Expected)" := Round(CostAmt * ItemJnlLine."Applied Amount" / ItemJnlLine.Amount);
                    ValueEntry."Cost Amount (Expected) (ACY)" := Round(CostAmtACY * ItemJnlLine."Applied Amount" / ItemJnlLine.Amount,
                        Currency."Amount Rounding Precision");

                    CostAmt := Round(CostAmt);
                    CostAmtACY := Round(CostAmtACY, Currency."Amount Rounding Precision");
                    ValueEntry."Cost Amount (Actual)" := CostAmt - ValueEntry."Cost Amount (Expected)";
                    ValueEntry."Cost Amount (Actual) (ACY)" := CostAmtACY - ValueEntry."Cost Amount (Expected) (ACY)";
                end;
            (not ValueEntry."Expected Cost") and ValueEntry.Inventoriable:
                begin
                    if not ItemJnlLine.Adjustment and (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") then
                        case ItemJnlLine."Entry Type" of
                            ItemJnlLine."Entry Type"::Sale:
                                ValueEntry."Sales Amount (Actual)" := ItemJnlLine.Amount;
                            ItemJnlLine."Entry Type"::Purchase:
                                ValueEntry."Purchase Amount (Actual)" := ItemJnlLine.Amount;
                        end;
                    ValueEntry."Cost Amount (Actual)" := CostAmt;
                    ValueEntry."Cost Amount (Actual) (ACY)" := CostAmtACY;
                end;
            ValueEntry."Expected Cost" and ValueEntry.Inventoriable:
                begin
                    if not ItemJnlLine.Adjustment then
                        case ItemJnlLine."Entry Type" of
                            ItemJnlLine."Entry Type"::Sale:
                                ValueEntry."Sales Amount (Expected)" := ItemJnlLine.Amount;
                            ItemJnlLine."Entry Type"::Purchase:
                                ValueEntry."Purchase Amount (Expected)" := ItemJnlLine.Amount;
                        end;
                    ValueEntry."Cost Amount (Expected)" := CostAmt;
                    ValueEntry."Cost Amount (Expected) (ACY)" := CostAmtACY;
                end;
            (not ValueEntry."Expected Cost") and (not ValueEntry.Inventoriable):
                if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Sale then begin
                    ValueEntry."Sales Amount (Actual)" := ItemJnlLine.Amount;
                    if Item.IsNonInventoriableType() then begin
                        ValueEntry."Cost Amount (Non-Invtbl.)" := CostAmt;
                        ValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := CostAmtACY;
                    end else begin
                        ValueEntry."Cost per Unit" := 0;
                        ValueEntry."Cost per Unit (ACY)" := 0;
                    end;
                end else begin
                    if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Purchase then
                        ValueEntry."Purchase Amount (Actual)" := ItemJnlLine.Amount;
                    ValueEntry."Cost Amount (Non-Invtbl.)" := CostAmt;
                    ValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := CostAmtACY;
                end;
        end;

        OnInitValueEntryOnBeforeRoundAmtValueEntry(ValueEntry, ItemJnlLine);

        RoundAmtValueEntry(ValueEntry);

        xValueEntryNo := ValueEntryNo;
        OnAfterInitValueEntry(ValueEntry, ItemJnlLine, ValueEntryNo, ItemLedgerEntry);
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");
    end;

    local procedure SetValueEntrySourceFieldsFromItemJnlLine(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
        OnBeforeSetValueEntrySourceFieldsFromItemJnlLine(ValueEntry, ItemJournalLine);

        ValueEntry."Source Code" := ItemJournalLine."Source Code";
        ValueEntry."Source Type" := ItemJournalLine."Source Type";
        ValueEntry."Source No." := GetSourceNo(ItemJournalLine);
    end;

    local procedure CalcOutboundCostAmt(ValueEntry: Record "Value Entry"; var CostAmt: Decimal; var CostAmtACY: Decimal)
    begin
        if ItemJnlLine."Item Charge No." <> '' then begin
            CostAmt := ItemJnlLine.Amount;
            if GLSetup."Additional Reporting Currency" <> '' then
                CostAmtACY := ACYMgt.CalcACYAmt(CostAmt, ValueEntry."Posting Date", false);
        end else begin
            if IsNondeductibleAndUseItemCost() then begin
                CostAmt := ItemJnlLine.Amount;
                CostAmtACY := ACYMgt.CalcACYAmt(CostAmt, ValueEntry."Posting Date", false);
            end
            else begin
                CostAmt :=
                  ValueEntry."Cost per Unit" * ValueEntry."Valued Quantity";
                CostAmtACY :=
                  ValueEntry."Cost per Unit (ACY)" * ValueEntry."Valued Quantity";
            end;
            if MustConsiderUnitCostRoundingOnRevaluation(ItemJnlLine) then begin
                CostAmt += RoundingResidualAmount;
                CostAmtACY += RoundingResidualAmountACY;
            end;
        end;
    end;

    /// <summary>
    /// Inserts the value entry for an item ledger entry and posts it to the general ledger.
    /// </summary>
    /// <remarks>
    /// Updates item ledger entry based on a value entry.
    /// Posts value entry information to the general ledger.
    /// Inserts or updates item register record based on a value entry.
    /// </remarks>
    /// <param name="ValueEntry">Return value: Inserted value entry record.</param>
    /// <param name="ItemLedgEntry">Return value: Item ledger entry to insert value entry for.</param>
    /// <param name="TransferItem">
    /// If true, global dimension codes and dimension set ID will be changed to new shorcut dimension values 
    /// instead of shortcut dimension values. A new shortcut dimension on an item journal line refers to adding a 
    /// new dimension specifically for item-related entries, providing additional flexibility and analysis capabilities 
    /// within the context of item transactions.
    /// </param>
    procedure InsertValueEntry(var ValueEntry: Record "Value Entry"; var ItemLedgEntry: Record "Item Ledger Entry"; TransferItem: Boolean)
    var
        InvdValueEntry: Record "Value Entry";
        InvoicedQty: Decimal;
        xValueEntryNo: Integer;
        ShouldCalcExpectedCost: Boolean;
    begin
        OnBeforeInsertValueEntryProcedure(ItemLedgEntry, ItemJnlLine);
        if IsWarehouseReclassification(ItemJnlLine) then begin
            ValueEntry."Dimension Set ID" := OldItemLedgEntry."Dimension Set ID";
            ValueEntry."Global Dimension 1 Code" := OldItemLedgEntry."Global Dimension 1 Code";
            ValueEntry."Global Dimension 2 Code" := OldItemLedgEntry."Global Dimension 2 Code";
        end else
            if TransferItem then begin
                ValueEntry."Global Dimension 1 Code" := ItemJnlLine."New Shortcut Dimension 1 Code";
                ValueEntry."Global Dimension 2 Code" := ItemJnlLine."New Shortcut Dimension 2 Code";
                ValueEntry."Dimension Set ID" := ItemJnlLine."New Dimension Set ID";
            end else
                if (GlobalValueEntry."Entry Type" = GlobalValueEntry."Entry Type"::"Direct Cost") and
                   (GlobalValueEntry."Item Charge No." <> '') and
                   (ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance)
                then begin
                    GetLastDirectCostValEntry(ValueEntry."Item Ledger Entry No.");
                    ValueEntry."Gen. Prod. Posting Group" := DirCostValueEntry."Gen. Prod. Posting Group";
                    MoveValEntryDimToValEntryDim(ValueEntry, DirCostValueEntry);
                end else begin
                    ValueEntry."Global Dimension 1 Code" := ItemJnlLine."Shortcut Dimension 1 Code";
                    ValueEntry."Global Dimension 2 Code" := ItemJnlLine."Shortcut Dimension 2 Code";
                    ValueEntry."Dimension Set ID" := ItemJnlLine."Dimension Set ID";
                end;
        OnInsertValueEntryOnBeforeRoundAmtValueEntry(ValueEntry, ItemLedgEntry, ItemJnlLine, TransferItem);
        RoundAmtValueEntry(ValueEntry);

        if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Rounding then begin
            ValueEntry."Valued Quantity" := ItemLedgEntry.Quantity;
            ValueEntry."Invoiced Quantity" := 0;
            ValueEntry."Cost per Unit" := 0;
            ValueEntry."Sales Amount (Actual)" := 0;
            ValueEntry."Purchase Amount (Actual)" := 0;
            ValueEntry."Cost per Unit (ACY)" := 0;
            ValueEntry."Item Ledger Entry Quantity" := 0;
        end else begin
            if IsFirstValueEntry(ValueEntry."Item Ledger Entry No.") then
                ValueEntry."Item Ledger Entry Quantity" := ValueEntry."Valued Quantity"
            else
                ValueEntry."Item Ledger Entry Quantity" := 0;
            RecalculateCostPerUnit(ValueEntry, ItemLedgEntry);
            if UpdateItemLedgEntry(ValueEntry, ItemLedgEntry) then
                ItemLedgEntry.Modify();
        end;

        ShouldCalcExpectedCost :=
            ((ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
                (ValueEntry."Item Charge No." = '')) and
            (((ItemJnlLine.Quantity = 0) and (ItemJnlLine."Invoiced Quantity" <> 0)) or
                (ItemJnlLine.Adjustment and not ValueEntry."Expected Cost")) and
            not ExpectedCostPosted(ValueEntry);
        OnInsertValueEntryOnBeforeCalcExpectedCost(ItemJnlLine, ItemLedgEntry, ValueEntry, TransferItem, InventoryPostingToGL, ShouldCalcExpectedCost);
        if ShouldCalcExpectedCost then begin
            if ValueEntry."Invoiced Quantity" = 0 then begin
                if InvdValueEntry.Get(ValueEntry."Applies-to Entry") then
                    InvoicedQty := InvdValueEntry."Invoiced Quantity"
                else
                    InvoicedQty := ValueEntry."Valued Quantity";
            end else
                InvoicedQty := ValueEntry."Invoiced Quantity";
            CalcExpectedCost(
              ValueEntry,
              ItemLedgEntry."Entry No.",
              InvoicedQty,
              ItemLedgEntry.Quantity,
              ValueEntry."Cost Amount (Expected)",
              ValueEntry."Cost Amount (Expected) (ACY)",
              ValueEntry."Sales Amount (Expected)",
              ValueEntry."Purchase Amount (Expected)",
              ItemLedgEntry.Quantity = ItemLedgEntry."Invoiced Quantity");
        end;

        xValueEntryNo := ValueEntryNo;
        OnBeforeInsertValueEntry(ValueEntry, ItemJnlLine, ItemLedgEntry, ValueEntryNo, InventoryPostingToGL, CalledFromAdjustment, OldItemLedgEntry, Item, TransferItem, GlobalValueEntry);
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");

        PostInventoryToGL(ValueEntry);

        InsertItemReg(0, 0, ValueEntry."Entry No.", 0);
        ValueEntry."Item Register No." := ItemReg."No.";
        ValueEntry.Insert(true);

        xValueEntryNo := ValueEntryNo;
        OnAfterInsertValueEntry(ValueEntry, ItemJnlLine, ItemLedgEntry, ValueEntryNo);
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");

        ItemApplnEntry.SetOutboundsNotUpdated(ItemLedgEntry);

        UpdateAdjmtProperties(ValueEntry, ItemLedgEntry."Posting Date");

        OnInsertValueEntryOnBeforeInsertPostValueEntryToGL(ValueEntry);
        InsertPostValueEntryToGL(ValueEntry);
        OnInsertValueEntryOnAfterInsertPostValueEntryToGL(ValueEntry);

        if Item."Item Tracking Code" <> '' then begin
            TempValueEntryRelation.Init();
            TempValueEntryRelation."Value Entry No." := ValueEntry."Entry No.";
            TempValueEntryRelation.Insert();
        end;
        OnInsertValueEntryOnAfterTempValueEntryRelationInsert(ValueEntry, ItemJnlLine, TempValueEntryRelation);
    end;

    local procedure RecalculateCostPerUnit(var ValueEntry: Record "Value Entry"; var ItemLedgEntry: Record "Item Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecalculateCostPerUnit(ValueEntry, ItemJnlLine, ItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if ValueEntry."Cost per Unit" = 0 then begin
            ValueEntry."Cost per Unit" :=
              CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
            ValueEntry."Cost per Unit (ACY)" :=
              CalcCostPerUnit(ValueEntry."Cost Amount (Actual) (ACY)", ValueEntry."Valued Quantity", true);
        end else begin
            ValueEntry."Cost per Unit" := Round(
                ValueEntry."Cost per Unit", GLSetup."Unit-Amount Rounding Precision");
            ValueEntry."Cost per Unit (ACY)" := Round(
                ValueEntry."Cost per Unit (ACY)", Currency."Unit-Amount Rounding Precision");
            if ItemJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency" then
                if ValueEntry."Expected Cost" then
                    ValueEntry."Cost per Unit" :=
                      CalcCostPerUnit(ValueEntry."Cost Amount (Expected)", ValueEntry."Valued Quantity", false)
                else
                    if ValueEntry."Entry Type" = ValueEntry."Entry Type"::Revaluation then
                        ValueEntry."Cost per Unit" :=
                          CalcCostPerUnit(ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)",
                            ValueEntry."Valued Quantity", false)
                    else
                        if not ValueEntry.Inventoriable and (ValueEntry."Item Charge No." = '') then
                            ValueEntry."Cost per Unit" :=
                                CalcCostPerUnit(ValueEntry."Cost Amount (Non-Invtbl.)", ValueEntry."Valued Quantity", false)
                        else
                            ValueEntry."Cost per Unit" :=
                              CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
        end;
    end;

    local procedure InsertOHValueEntry(ValueEntry: Record "Value Entry"; OverheadAmount: Decimal; OverheadAmountACY: Decimal)
    var
        xValueEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertOHValueEntry(ValueEntry, Item, OverheadAmount, OverheadAmountACY, IsHandled);
        if IsHandled then
            exit;

        if Item."Inventory Value Zero" or not ValueEntry.Inventoriable then
            exit;

        ValueEntryNo := GetNextValueEntryNo(ValueEntryNo);

        ValueEntry."Entry No." := ValueEntryNo;
        ValueEntry."Item Charge No." := '';
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::"Indirect Cost";
        ValueEntry.Description := '';
        ValueEntry."Cost per Unit" := 0;
        ValueEntry."Cost per Unit (ACY)" := 0;
        ValueEntry."Cost Posted to G/L" := 0;
        ValueEntry."Cost Posted to G/L (ACY)" := 0;
        ValueEntry."Invoiced Quantity" := 0;
        ValueEntry."Sales Amount (Actual)" := 0;
        ValueEntry."Sales Amount (Expected)" := 0;
        ValueEntry."Purchase Amount (Actual)" := 0;
        ValueEntry."Purchase Amount (Expected)" := 0;
        ValueEntry."Discount Amount" := 0;
        ValueEntry."Cost Amount (Actual)" := OverheadAmount;
        ValueEntry."Cost Amount (Expected)" := 0;
        ValueEntry."Cost Amount (Expected) (ACY)" := 0;

        if GLSetup."Additional Reporting Currency" <> '' then
            ValueEntry."Cost Amount (Actual) (ACY)" :=
              Round(OverheadAmountACY, Currency."Amount Rounding Precision");

        IsHandled := false;
        xValueEntryNo := ValueEntryNo;
        OnInsertOHValueEntryOnBeforeInsertValueEntry(ValueEntry, ItemJnlLine, IsHandled, GlobalItemLedgEntry, ValueEntryNo);
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");
        if not IsHandled then
            InsertValueEntry(ValueEntry, GlobalItemLedgEntry, false);

        OnAfterInsertOHValueEntry(ValueEntry, Item, OverheadAmount, OverheadAmountACY);
    end;

    local procedure InsertVarValueEntry(ValueEntry: Record "Value Entry"; VarianceAmount: Decimal; VarianceAmountACY: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertVarValueEntry(ValueEntry, Item, VarianceAmount, VarianceAmountACY, IsHandled);
        if IsHandled then
            exit;

        if (not ValueEntry.Inventoriable) or Item."Inventory Value Zero" then
            exit;
        if (VarianceAmount = 0) and (VarianceAmountACY = 0) then
            exit;

        ValueEntryNo := GetNextValueEntryNo(ValueEntryNo);

        ValueEntry."Entry No." := ValueEntryNo;
        ValueEntry."Item Charge No." := '';
        ValueEntry."Entry Type" := ValueEntry."Entry Type"::Variance;
        ValueEntry.Description := '';
        ValueEntry."Cost Posted to G/L" := 0;
        ValueEntry."Cost Posted to G/L (ACY)" := 0;
        ValueEntry."Invoiced Quantity" := 0;
        ValueEntry."Sales Amount (Actual)" := 0;
        ValueEntry."Sales Amount (Expected)" := 0;
        ValueEntry."Purchase Amount (Actual)" := 0;
        ValueEntry."Purchase Amount (Expected)" := 0;
        ValueEntry."Discount Amount" := 0;
        ValueEntry."Cost Amount (Actual)" := VarianceAmount;
        ValueEntry."Cost Amount (Expected)" := 0;
        ValueEntry."Cost Amount (Expected) (ACY)" := 0;
        ValueEntry."Variance Type" := ValueEntry."Variance Type"::Purchase;
        OnInsertVarValueEntryOnAfterInitValueEntryFields(ValueEntry);

        if GLSetup."Additional Reporting Currency" <> '' then
            if Round(VarianceAmount, GLSetup."Amount Rounding Precision") =
               Round(-GlobalValueEntry."Cost Amount (Actual)", GLSetup."Amount Rounding Precision")
            then
                ValueEntry."Cost Amount (Actual) (ACY)" := -GlobalValueEntry."Cost Amount (Actual) (ACY)"
            else
                ValueEntry."Cost Amount (Actual) (ACY)" :=
                  Round(VarianceAmountACY, Currency."Amount Rounding Precision");

        ValueEntry."Cost per Unit" :=
          CalcCostPerUnit(ValueEntry."Cost Amount (Actual)", ValueEntry."Valued Quantity", false);
        ValueEntry."Cost per Unit (ACY)" :=
          CalcCostPerUnit(ValueEntry."Cost Amount (Actual) (ACY)", ValueEntry."Valued Quantity", true);

        InsertValueEntry(ValueEntry, GlobalItemLedgEntry, false);
    end;

    local procedure UpdateItemLedgEntry(ValueEntry: Record "Value Entry"; var ItemLedgEntry: Record "Item Ledger Entry") ModifyEntry: Boolean
    var
        IsHandled: Boolean;
    begin
        if not (ValueEntry."Entry Type" in
                [ValueEntry."Entry Type"::Variance,
                 ValueEntry."Entry Type"::"Indirect Cost",
                 ValueEntry."Entry Type"::Rounding])
        then begin
            IsHandled := false;
            OnUpdateItemLedgEntryOnBeforeUpdateAvgCostAdjmtBuffer(ItemLedgEntry, ValueEntry."Valuation Date", IsHandled);
            if not IsHandled then
                if ValueEntry.Inventoriable and (not ItemJnlLine.Adjustment or (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::"Assembly Output")) then
                    UpdateAvgCostAdjmtBuffer(ItemLedgEntry, ValueEntry."Valuation Date");

            if (ItemLedgEntry.Positive or ItemLedgEntry."Job Purchase") and
               (ItemLedgEntry.Quantity <> ItemLedgEntry."Remaining Quantity") and not ItemLedgEntry."Applied Entry to Adjust" and
               (Item.Type = Item.Type::Inventory) and
               (not CalledFromAdjustment or AppliedEntriesToReadjust(ItemLedgEntry))
            then begin
                ItemLedgEntry."Applied Entry to Adjust" := true;
                ModifyEntry := true;
                OnUpdateItemLedgerEntryOnAfterSetAppliedEntryToAdjust(ItemLedgEntry);
            end;

            if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Direct Cost") and
               (ItemJnlLine."Item Charge No." = '') and
               (ItemJnlLine.Quantity = 0) and (ValueEntry."Invoiced Quantity" <> 0)
            then begin
                if ValueEntry."Invoiced Quantity" <> 0 then begin
                    ItemLedgEntry."Invoiced Quantity" := ItemLedgEntry."Invoiced Quantity" + ValueEntry."Invoiced Quantity";
                    CheckInvoicedQuantity(ItemLedgEntry, ValueEntry, ModifyEntry);
                end;

                if (ItemLedgEntry."Entry Type" <> ItemLedgEntry."Entry Type"::Output) and
                   (ItemLedgEntry."Invoiced Quantity" = ItemLedgEntry.Quantity) and
                   not ItemLedgEntry."Completely Invoiced"
                then begin
                    ItemLedgEntry."Completely Invoiced" := true;
                    ModifyEntry := true;
                end;

                if ItemLedgEntry."Last Invoice Date" < ValueEntry."Posting Date" then begin
                    ItemLedgEntry."Last Invoice Date" := ValueEntry."Posting Date";
                    ModifyEntry := true;
                end;
            end;
            IsHandled := false;
            OnUpdateItemLedgEntryOnBeforeUpdateOutboundItemLedgEntry(ValueEntry, IsHandled, ItemJnlLine);
            if not IsHandled then
                if ItemJnlLine."Applies-from Entry" <> 0 then
                    UpdateOutboundItemLedgEntry(ItemJnlLine."Applies-from Entry");
        end;

        exit(ModifyEntry);
    end;

    local procedure UpdateAvgCostAdjmtBuffer(OldItemLedgEntry: Record "Item Ledger Entry"; ValuationDate: Date)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Init();
        ValueEntry."Item No." := OldItemLedgEntry."Item No.";
        ValueEntry."Valuation Date" := ValuationDate;
        ValueEntry."Location Code" := OldItemLedgEntry."Location Code";
        ValueEntry."Variant Code" := OldItemLedgEntry."Variant Code";
        OnUpdateAvgCostAdjmtBufferOnAfterSetValueEntry(ValueEntry, OldItemLedgEntry);

        AvgCostEntryPointHandler.LockBuffer();
        AvgCostEntryPointHandler.UpdateValuationDate(ValueEntry);

        OnAfterUpdateAvgCostAdjmtBuffer(OldItemLedgEntry, ValueEntry, ValuationDate);
    end;

    local procedure UpdateOutboundItemLedgEntry(OutboundItemEntryNo: Integer)
    var
        OutboundItemLedgEntry: Record "Item Ledger Entry";
    begin
        OutboundItemLedgEntry.Get(OutboundItemEntryNo);
        if OutboundItemLedgEntry.Quantity > 0 then
            OutboundItemLedgEntry.FieldError(Quantity);
        if GlobalItemLedgEntry.Quantity < 0 then
            GlobalItemLedgEntry.FieldError(Quantity);

        OutboundItemLedgEntry."Shipped Qty. Not Returned" := OutboundItemLedgEntry."Shipped Qty. Not Returned" + Abs(ItemJnlLine.Quantity);
        if OutboundItemLedgEntry."Shipped Qty. Not Returned" > 0 then
            OutboundItemLedgEntry.FieldError("Shipped Qty. Not Returned", Text004);
        OutboundItemLedgEntry."Applied Entry to Adjust" := true;
        OutboundItemLedgEntry.Modify();
    end;

    /// <summary>
    /// Initializes a value entry record for a transfer item ledger entry.
    /// Calculates the cost amounts and adjusted cost based on whether the average transfer is being used.
    /// </summary>
    /// <param name="ValueEntry">Return value: Initialized value entry.</param>
    /// <param name="ItemLedgEntry">Item ledger entry to initialize value entry from.</param>
    procedure InitTransValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    var
        AdjCostInvoicedLCY: Decimal;
        AdjCostInvoicedACY: Decimal;
        DiscountAmount: Decimal;
        IsHandled: Boolean;
    begin
        InitValueEntry(ValueEntry, ItemLedgEntry);
        OnInitTransValueEntryOnAfterInitValueEntry(ValueEntry, ItemLedgEntry);
        ValueEntry."Valued Quantity" := ItemLedgEntry.Quantity;
        ValueEntry."Invoiced Quantity" := ValueEntry."Valued Quantity";
        ValueEntry."Location Code" := ItemLedgEntry."Location Code";
        ValueEntry."Valuation Date" := GlobalValueEntry."Valuation Date";
        if AverageTransfer then begin
            ValuateAppliedAvgEntry(GlobalValueEntry, Item);
            OnInitTransValueEntryOnBeforeCalcCostAmounts(GlobalValueEntry, ValueEntry, GlobalItemTrackingSetup, IsHandled);
            if not IsHandled then begin
                ValueEntry."Cost Amount (Actual)" := -GlobalValueEntry."Cost Amount (Actual)";
                ValueEntry."Cost Amount (Actual) (ACY)" := -GlobalValueEntry."Cost Amount (Actual) (ACY)";
            end;
            ValueEntry."Cost per Unit" := 0;
            ValueEntry."Cost per Unit (ACY)" := 0;
            ValueEntry."Valued By Average Cost" :=
                not (ItemLedgEntry.Positive or
                    (ValueEntry."Document Type" = ValueEntry."Document Type"::"Transfer Receipt"));
        end else begin
            IsHandled := false;
            OnInitTransValueEntryOnBeforeCalcAdjustedCost(OldItemLedgEntry, ValueEntry, AdjCostInvoicedLCY, AdjCostInvoicedACY, DiscountAmount, IsHandled);
            if not IsHandled then begin
                CalcAdjustedCost(
                    OldItemLedgEntry, ValueEntry."Valued Quantity",
                    AdjCostInvoicedLCY, AdjCostInvoicedACY, DiscountAmount);
                ValueEntry."Cost Amount (Actual)" := AdjCostInvoicedLCY;
                ValueEntry."Cost Amount (Actual) (ACY)" := AdjCostInvoicedACY;
                ValueEntry."Cost per Unit" := 0;
                ValueEntry."Cost per Unit (ACY)" := 0;
            end;

            GlobalValueEntry."Cost Amount (Actual)" := GlobalValueEntry."Cost Amount (Actual)" - ValueEntry."Cost Amount (Actual)";
            if GLSetup."Additional Reporting Currency" <> '' then
                GlobalValueEntry."Cost Amount (Actual) (ACY)" :=
                    CurrExchRate.ExchangeAmtLCYToFCY(
                    ValueEntry."Posting Date", GLSetup."Additional Reporting Currency",
                    Round(GlobalValueEntry."Cost Amount (Actual)", GLSetup."Amount Rounding Precision"),
                    CurrExchRate.ExchangeRate(
                        ValueEntry."Posting Date", GLSetup."Additional Reporting Currency"));
        end;

        GlobalValueEntry."Discount Amount" := 0;
        ValueEntry."Discount Amount" := 0;
        GlobalValueEntry."Cost per Unit" := 0;
        GlobalValueEntry."Cost per Unit (ACY)" := 0;
    end;

    local procedure ValuateAppliedAvgEntry(var ValueEntry: Record "Value Entry"; Item: Record Item)
    begin
        if (ItemJnlLine."Applies-to Entry" = 0) and
            (ValueEntry."Item Ledger Entry Type" <> ValueEntry."Item Ledger Entry Type"::Output)
        then begin
            if (ItemJnlLine.Quantity = 0) and (ItemJnlLine."Invoiced Quantity" <> 0) then begin
                GetLastDirectCostValEntry(ValueEntry."Item Ledger Entry No.");
                ValueEntry."Valued By Average Cost" := DirCostValueEntry."Valued By Average Cost";
            end else
                ValueEntry."Valued By Average Cost" := not (ValueEntry."Document Type" = ValueEntry."Document Type"::"Transfer Receipt");

            if Item."Inventory Value Zero" then begin
                ValueEntry."Cost per Unit" := 0;
                ValueEntry."Cost per Unit (ACY)" := 0;
            end else begin
                if ValueEntry."Item Ledger Entry Type" = ValueEntry."Item Ledger Entry Type"::Transfer then begin
                    if SKUExists and (InvtSetup."Average Cost Calc. Type" <> InvtSetup."Average Cost Calc. Type"::Item) then
                        ValueEntry."Cost per Unit" := SKU."Unit Cost"
                    else
                        ValueEntry."Cost per Unit" := Item."Unit Cost";
                end else
                    ValueEntry."Cost per Unit" := ItemJnlLine."Unit Cost";

                OnValuateAppliedAvgEntryOnAfterSetCostPerUnit(ValueEntry, ItemJnlLine, InvtSetup, SKU, SKUExists, Item);

                if GLSetup."Additional Reporting Currency" <> '' then
                    if (ItemJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency") and
                       (ValueEntry."Item Ledger Entry Type" <> ValueEntry."Item Ledger Entry Type"::Transfer)
                    then
                        ValueEntry."Cost per Unit (ACY)" := ItemJnlLine."Unit Cost (ACY)"
                    else
                        ValueEntry."Cost per Unit (ACY)" :=
                          Round(
                            CurrExchRate.ExchangeAmtLCYToFCY(
                              ValueEntry."Posting Date", GLSetup."Additional Reporting Currency", ValueEntry."Cost per Unit",
                              CurrExchRate.ExchangeRate(
                                ValueEntry."Posting Date", GLSetup."Additional Reporting Currency")),
                            Currency."Unit-Amount Rounding Precision");
            end;

            OnValuateAppliedAvgEntryOnAfterUpdateCostAmounts(ValueEntry, ItemJnlLine);

            if ValueEntry."Expected Cost" then begin
                ValueEntry."Cost Amount (Expected)" := ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit";
                ValueEntry."Cost Amount (Expected) (ACY)" := ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit (ACY)";
            end else begin
                ValueEntry."Cost Amount (Actual)" := ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit";
                ValueEntry."Cost Amount (Actual) (ACY)" := ValueEntry."Valued Quantity" * ValueEntry."Cost per Unit (ACY)";
            end;
        end;

        OnAfterValuateAppliedAvgEntry(ValueEntry, ItemJnlLine)
    end;

    local procedure CalcAdjustedCost(PosItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal; var AdjustedCostLCY: Decimal; var AdjustedCostACY: Decimal; var DiscountAmount: Decimal)
    var
        PosValueEntry: Record "Value Entry";
    begin
        AdjustedCostLCY := 0;
        AdjustedCostACY := 0;
        DiscountAmount := 0;
        PosValueEntry.SetCurrentKey("Item Ledger Entry No.");
        PosValueEntry.SetRange("Item Ledger Entry No.", PosItemLedgEntry."Entry No.");
        PosValueEntry.FindSet();
        repeat
            if PosValueEntry."Partial Revaluation" then begin
                AdjustedCostLCY := AdjustedCostLCY +
                  PosValueEntry."Cost Amount (Actual)" / PosValueEntry."Valued Quantity" * PosItemLedgEntry.Quantity;
                AdjustedCostACY := AdjustedCostACY +
                  PosValueEntry."Cost Amount (Actual) (ACY)" / PosValueEntry."Valued Quantity" * PosItemLedgEntry.Quantity;
            end else begin
                AdjustedCostLCY := AdjustedCostLCY + PosValueEntry."Cost Amount (Actual)" + PosValueEntry."Cost Amount (Expected)";
                AdjustedCostACY := AdjustedCostACY + PosValueEntry."Cost Amount (Actual) (ACY)" + PosValueEntry."Cost Amount (Expected) (ACY)";
                DiscountAmount := DiscountAmount - PosValueEntry."Discount Amount";
            end;
        until PosValueEntry.Next() = 0;

        AdjustedCostLCY := AdjustedCostLCY * AppliedQty / PosItemLedgEntry.Quantity;
        AdjustedCostACY := AdjustedCostACY * AppliedQty / PosItemLedgEntry.Quantity;
        DiscountAmount := DiscountAmount * AppliedQty / PosItemLedgEntry.Quantity;
        OnAfterCalcAdjustedCost(ItemJnlLine, AdjustedCostLCY, AdjustedCostACY);
    end;

    local procedure GetMaxValuationDate(ItemLedgerEntry: Record "Item Ledger Entry"): Date
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type", "Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntry."Entry No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        if not ValueEntry.FindLast() then begin
            ValueEntry.SetRange("Entry Type");
            ValueEntry.FindLast();
        end;
        exit(ValueEntry."Valuation Date");
    end;

    local procedure GetValuationDate(var ValueEntry: Record "Value Entry"; OldItemLedgEntry: Record "Item Ledger Entry")
    var
        OldValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetValuationDate(OldItemLedgEntry, OldValueEntry."Valuation Date", IsHandled);
        if IsHandled then
            exit;

        OldValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type", "Entry No.");
        OldValueEntry.SetRange("Item Ledger Entry No.", OldItemLedgEntry."Entry No.");
        OldValueEntry.SetRange("Entry Type", OldValueEntry."Entry Type"::Revaluation);
        OnGetValuationDateOnAfterOldValueEntrySetFilters(OldValueEntry, ValueEntry, OldItemLedgEntry);
        if not OldValueEntry.FindLast() then begin
            OldValueEntry.SetRange("Entry Type");
            IsHandled := false;
            OnGetValuationDateOnBeforeFindOldValueEntry(OldValueEntry, IsHandled);
            if IsHandled then
                exit;
            OldValueEntry.FindLast();
        end;
        if OldItemLedgEntry.Positive then begin
            if (ValueEntry."Posting Date" < OldValueEntry."Valuation Date") or
               (ItemJnlLine."Applies-to Entry" <> 0)
            then begin
                ValueEntry."Valuation Date" := OldValueEntry."Valuation Date";
                SetValuationDateAllValueEntrie(
                  ValueEntry."Item Ledger Entry No.",
                  OldValueEntry."Valuation Date",
                  ItemJnlLine."Applies-to Entry" <> 0)
            end else
                if ValueEntry."Valuation Date" <= ValueEntry."Posting Date" then begin
                    ValueEntry."Valuation Date" := ValueEntry."Posting Date";
                    SetValuationDateAllValueEntrie(
                      ValueEntry."Item Ledger Entry No.",
                      ValueEntry."Posting Date",
                      ItemJnlLine."Applies-to Entry" <> 0)
                end
        end else
            if OldValueEntry."Valuation Date" < ValueEntry."Valuation Date" then begin
                UpdateAvgCostAdjmtBuffer(OldItemLedgEntry, OldValueEntry."Valuation Date");
                OldValueEntry.ModifyAll("Valuation Date", ValueEntry."Valuation Date");
                UpdateLinkedValuationDate(ValueEntry."Valuation Date", OldItemLedgEntry."Entry No.", OldItemLedgEntry.Positive);
            end;
    end;

    local procedure UpdateLinkedValuationDate(FromValuationDate: Date; FromItemledgEntryNo: Integer; FromInbound: Boolean)
    var
        ToItemApplnEntry: Record "Item Application Entry";
        ValuationDate: Date;
        ValuationDateFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateLinkedValuationDate(GlobalItemLedgEntry, FromItemledgEntryNo, IsHandled);
        if IsHandled then
            exit;

        if FromInbound then begin
            ToItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            ToItemApplnEntry.SetRange("Inbound Item Entry No.", FromItemledgEntryNo);
            ToItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
        end else begin
            ToItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
            ToItemApplnEntry.SetRange("Outbound Item Entry No.", FromItemledgEntryNo);
        end;
        ToItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', FromItemledgEntryNo);
        if not FromInbound then
            ToItemApplnEntry.SetFilter("Inbound Item Entry No.", '<>%1', 0);
        if ToItemApplnEntry.FindSet() then
            repeat
                if not ValuationDateFound then begin
                    GetLastDirectCostValEntry(ToItemApplnEntry."Inbound Item Entry No.");
                    ValuationDate := DirCostValueEntry."Valuation Date";
                    ValuationDateFound := true;
                end;
                if ValuationDate < FromValuationDate then begin
                    UpdateValuationDate(FromValuationDate, ToItemApplnEntry."Item Ledger Entry No.", FromInbound);
                    UpdateLinkedValuationDate(FromValuationDate, ToItemApplnEntry."Item Ledger Entry No.", not FromInbound);
                end;
            until ToItemApplnEntry.Next() = 0;
    end;

    local procedure UpdateLinkedValuationUnapply(FromValuationDate: Date; FromItemLedgEntryNo: Integer; FromInbound: Boolean)
    var
        ToItemApplnEntry: Record "Item Application Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if FromInbound then begin
            ToItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            ToItemApplnEntry.SetRange("Inbound Item Entry No.", FromItemLedgEntryNo);
            ToItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
        end else begin
            ToItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
            ToItemApplnEntry.SetRange("Outbound Item Entry No.", FromItemLedgEntryNo);
        end;
        ToItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', FromItemLedgEntryNo);
        if ToItemApplnEntry.Find('-') then
            repeat
                if FromInbound or (ToItemApplnEntry."Inbound Item Entry No." <> 0) then begin
                    GetLastDirectCostValEntry(ToItemApplnEntry."Inbound Item Entry No.");
                    if DirCostValueEntry."Valuation Date" < FromValuationDate then begin
                        UpdateValuationDate(FromValuationDate, ToItemApplnEntry."Item Ledger Entry No.", FromInbound);
                        UpdateLinkedValuationUnapply(FromValuationDate, ToItemApplnEntry."Item Ledger Entry No.", not FromInbound);
                    end
                    else begin
                        ItemLedgerEntry.Get(ToItemApplnEntry."Inbound Item Entry No.");
                        FromValuationDate := GetMaxAppliedValuationdate(ItemLedgerEntry);
                        if FromValuationDate < DirCostValueEntry."Valuation Date" then begin
                            UpdateValuationDate(FromValuationDate, ItemLedgerEntry."Entry No.", FromInbound);
                            UpdateLinkedValuationUnapply(FromValuationDate, ItemLedgerEntry."Entry No.", not FromInbound);
                        end;
                    end;
                end;
            until ToItemApplnEntry.Next() = 0;
    end;

    local procedure UpdateValuationDate(FromValuationDate: Date; FromItemLedgEntryNo: Integer; FromInbound: Boolean)
    var
        ToValueEntry2: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateValuationDate(GlobalItemLedgEntry, FromItemLedgEntryNo, IsHandled);
        if IsHandled then
            exit;

        ToValueEntry2.SetCurrentKey("Item Ledger Entry No.");
        ToValueEntry2.SetRange("Item Ledger Entry No.", FromItemLedgEntryNo);
        ToValueEntry2.Find('-');
        if FromInbound then begin
            if ToValueEntry2."Valuation Date" < FromValuationDate then
                ToValueEntry2.ModifyAll("Valuation Date", FromValuationDate);
        end else
            repeat
                if ToValueEntry2."Entry Type" = ToValueEntry2."Entry Type"::Revaluation then begin
                    if ToValueEntry2."Valuation Date" < FromValuationDate then begin
                        ToValueEntry2."Valuation Date" := FromValuationDate;
                        ToValueEntry2.Modify();
                    end;
                end else begin
                    ToValueEntry2."Valuation Date" := FromValuationDate;
                    ToValueEntry2.Modify();
                end;
            until ToValueEntry2.Next() = 0;
    end;

    local procedure CreateItemJnlLineFromEntry(ItemLedgEntry: Record "Item Ledger Entry"; NewQuantity: Decimal; var ItemJnlLine: Record "Item Journal Line")
    begin
        Clear(ItemJnlLine);
        ItemJnlLine."Entry Type" := ItemLedgEntry."Entry Type";
        ItemJnlLine.Quantity := ItemJnlLine.Signed(NewQuantity);
        ItemJnlLine."Item No." := ItemLedgEntry."Item No.";
        ItemJnlLine.CopyTrackingFromItemLedgEntry(ItemLedgEntry);

        OnAfterCreateItemJnlLineFromEntry(ItemJnlLine, ItemLedgEntry);
    end;

    local procedure GetAppliedFromValues(var ValueEntry: Record "Value Entry")
    var
        NegValueEntry: Record "Value Entry";
    begin
        NegValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type", "Entry No.");
        NegValueEntry.SetRange("Item Ledger Entry No.", ItemJnlLine."Applies-from Entry");
        NegValueEntry.SetRange("Entry Type", NegValueEntry."Entry Type"::Revaluation);
        OnBeforeFindNegValueEntry(NegValueEntry);
        if not NegValueEntry.FindLast() then begin
            NegValueEntry.SetRange("Entry Type");
            NegValueEntry.FindLast();
        end;

        if NegValueEntry."Valuation Date" > ValueEntry."Posting Date" then
            ValueEntry."Valuation Date" := NegValueEntry."Valuation Date"
        else
            ValueEntry."Valuation Date" := ItemJnlLine."Posting Date";

        OnAfterGetAppliedFromValues(ValueEntry, NegValueEntry);
    end;

    local procedure RoundAmtValueEntry(var ValueEntry: Record "Value Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoundAmtValueEntry(ValueEntry, Currency, Item, IsHandled);
        if IsHandled then
            exit;

        ValueEntry."Sales Amount (Actual)" := Round(ValueEntry."Sales Amount (Actual)");
        ValueEntry."Sales Amount (Expected)" := Round(ValueEntry."Sales Amount (Expected)");
        ValueEntry."Purchase Amount (Actual)" := Round(ValueEntry."Purchase Amount (Actual)");
        ValueEntry."Purchase Amount (Expected)" := Round(ValueEntry."Purchase Amount (Expected)");
        ValueEntry."Discount Amount" := Round(ValueEntry."Discount Amount");
        ValueEntry."Cost Amount (Actual)" := Round(ValueEntry."Cost Amount (Actual)");
        ValueEntry."Cost Amount (Expected)" := Round(ValueEntry."Cost Amount (Expected)");
        ValueEntry."Cost Amount (Non-Invtbl.)" := Round(ValueEntry."Cost Amount (Non-Invtbl.)");
        ValueEntry."Cost Amount (Actual) (ACY)" := Round(ValueEntry."Cost Amount (Actual) (ACY)", Currency."Amount Rounding Precision");
        ValueEntry."Cost Amount (Expected) (ACY)" := Round(ValueEntry."Cost Amount (Expected) (ACY)", Currency."Amount Rounding Precision");
        ValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := Round(ValueEntry."Cost Amount (Non-Invtbl.)(ACY)", Currency."Amount Rounding Precision");
    end;

    local procedure RetrieveCostPerUnit(ItemJnlLine: Record "Item Journal Line"; SKU: Record "Stockkeeping Unit"; SKUExists: Boolean): Decimal
    var
        UnitCost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRetrieveCostPerUnit(ItemJnlLine, SKU, SKUExists, UnitCost, IsHandled);
        if IsHandled then
            exit(UnitCost);

        if (Item."Costing Method" = Item."Costing Method"::Standard) and
            (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and
            (ItemJnlLine."Item Charge No." = '') and
            (ItemJnlLine."Applies-from Entry" = 0) and
            not ItemJnlLine.Adjustment
        then begin
            if SKUExists then
                exit(SKU."Unit Cost");
            exit(Item."Unit Cost");
        end;
        exit(ItemJnlLine."Unit Cost");
    end;

    local procedure RetrieveCostPerUnitACY(CostPerUnit: Decimal): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostingDate: Date;
    begin
        if ItemJnlLine.Adjustment or (ItemJnlLine."Source Currency Code" = GLSetup."Additional Reporting Currency") and
           ((Item."Costing Method" <> Item."Costing Method"::Standard) or
            ((ItemJnlLine."Discount Amount" = 0) and (ItemJnlLine."Indirect Cost %" = 0) and (ItemJnlLine."Overhead Rate" = 0)))
        then
            exit(ItemJnlLine."Unit Cost (ACY)");
        if (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::Revaluation) and ItemLedgerEntry.Get(ItemJnlLine."Applies-to Entry") then
            PostingDate := ItemLedgerEntry."Posting Date"
        else
            PostingDate := ItemJnlLine."Posting Date";
        exit(Round(CurrExchRate.ExchangeAmtLCYToFCY(
              PostingDate, GLSetup."Additional Reporting Currency",
              CostPerUnit, CurrExchRate.ExchangeRate(
                PostingDate, GLSetup."Additional Reporting Currency")),
            Currency."Unit-Amount Rounding Precision"));
    end;

    local procedure CalcCostPerUnit(Cost: Decimal; Quantity: Decimal; IsACY: Boolean): Decimal
    var
        RndgPrec: Decimal;
    begin
        GetGLSetup();

        if IsACY then
            RndgPrec := Currency."Unit-Amount Rounding Precision"
        else
            RndgPrec := GLSetup."Unit-Amount Rounding Precision";

        if Quantity <> 0 then
            exit(Round(Cost / Quantity, RndgPrec));
        exit(0);
    end;

    local procedure CalcPosShares(var DirCost: Decimal; var OvhdCost: Decimal; var PurchVar: Decimal; var DirCostACY: Decimal; var OvhdCostACY: Decimal; var PurchVarACY: Decimal; var CalcUnitCost: Boolean; CalcPurchVar: Boolean; Expected: Boolean)
    var
        CostCalcMgt: Codeunit "Cost Calculation Management";
    begin
        if Expected then begin
            DirCost := ItemJnlLine."Unit Cost" * ItemJnlLine.Quantity + RoundingResidualAmount;
            PurchVar := 0;
            PurchVarACY := 0;
            OvhdCost := 0;
            OvhdCostACY := 0;
        end else begin
            OvhdCost :=
              Round(
                CostCalcMgt.CalcOvhdCost(
                  ItemJnlLine.Amount, ItemJnlLine."Indirect Cost %", ItemJnlLine."Overhead Rate", ItemJnlLine."Invoiced Quantity"),
                GLSetup."Amount Rounding Precision");
            DirCost := ItemJnlLine.Amount;
            if CalcPurchVar then
                PurchVar := ItemJnlLine."Unit Cost" * ItemJnlLine."Invoiced Quantity" - DirCost - OvhdCost
            else begin
                PurchVar := 0;
                PurchVarACY := 0;
            end;
        end;

        if GLSetup."Additional Reporting Currency" <> '' then begin
            DirCostACY := ACYMgt.CalcACYAmt(DirCost, ItemJnlLine."Posting Date", false);
            OvhdCostACY := ACYMgt.CalcACYAmt(OvhdCost, ItemJnlLine."Posting Date", false);
            ItemJnlLine."Unit Cost (ACY)" :=
              Round(
                CurrExchRate.ExchangeAmtLCYToFCY(
                  ItemJnlLine."Posting Date", GLSetup."Additional Reporting Currency", ItemJnlLine."Unit Cost",
                  CurrExchRate.ExchangeRate(
                    ItemJnlLine."Posting Date", GLSetup."Additional Reporting Currency")),
                Currency."Unit-Amount Rounding Precision");
            PurchVarACY := ItemJnlLine."Unit Cost (ACY)" * ItemJnlLine."Invoiced Quantity" - DirCostACY - OvhdCostACY;
        end;
        CalcUnitCost := (DirCost <> 0) and (ItemJnlLine."Unit Cost" = 0);

        OnAfterCalcPosShares(ItemJnlLine, DirCost, OvhdCost, PurchVar, DirCostACY, OvhdCostACY, PurchVarACY, CalcUnitCost, CalcPurchVar, Expected, GlobalItemLedgEntry);
    end;

    local procedure CalcPurchCorrShares(var OverheadAmount: Decimal; var OverheadAmountACY: Decimal; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal)
    var
        OldItemLedgEntry: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        CostAmt: Decimal;
        CostAmtACY: Decimal;
    begin
        OldItemLedgEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        OldValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        OldValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        OldValueEntry.SetRange("Item Ledger Entry No.", ItemJnlLine."Applies-to Entry");
        OldValueEntry.SetRange("Entry Type", OldValueEntry."Entry Type"::"Indirect Cost");
        OldValueEntry.SetRange("Partial Revaluation", false);
        OldValueEntry.CalcSums("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
        CostAmt := OldValueEntry."Cost Amount (Actual)";
        CostAmtACY := OldValueEntry."Cost Amount (Actual) (ACY)";
        if (CostAmt <> 0) or (CostAmtACY <> 0) then begin
            OldItemLedgEntry.Get(ItemJnlLine."Applies-to Entry");
            OverheadAmount := Round(
                CostAmt / OldItemLedgEntry."Invoiced Quantity" * ItemJnlLine."Invoiced Quantity",
                GLSetup."Amount Rounding Precision");
            OverheadAmountACY := Round(
                CostAmtACY / OldItemLedgEntry."Invoiced Quantity" * ItemJnlLine."Invoiced Quantity",
                Currency."Unit-Amount Rounding Precision");
            if Item."Costing Method" = Item."Costing Method"::Standard then begin
                VarianceAmount := -OverheadAmount;
                VarianceAmountACY := -OverheadAmountACY;
            end else begin
                VarianceAmount := 0;
                VarianceAmountACY := 0;
            end;
        end else
            if Item."Costing Method" = Item."Costing Method"::Standard then begin
                OldValueEntry.SetRange("Partial Revaluation");
                OldValueEntry.SetRange("Entry Type", OldValueEntry."Entry Type"::Variance);
                VarianceRequired := not OldValueEntry.IsEmpty();
            end;
    end;

    local procedure GetLastDirectCostValEntry(ItemLedgEntryNo: Integer)
    var
        Found: Boolean;
    begin
        if ItemLedgEntryNo = DirCostValueEntry."Item Ledger Entry No." then
            exit;
        DirCostValueEntry.Reset();
        DirCostValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type", "Entry No.");
        DirCostValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        DirCostValueEntry.SetRange("Entry Type", DirCostValueEntry."Entry Type"::"Direct Cost");
        DirCostValueEntry.SetFilter("Item Charge No.", '%1', '');
        OnGetLastDirectCostValEntryOnBeforeFindDirCostValueEntry(DirCostValueEntry);
        Found := DirCostValueEntry.FindLast();
        DirCostValueEntry.SetRange("Item Charge No.");
        if not Found then
            DirCostValueEntry.FindLast();
    end;

    local procedure IsFirstValueEntry(ItemLedgEntryNo: Integer): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        exit(ValueEntry.IsEmpty);
    end;

    local procedure CalcExpectedCost(var InvdValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer; InvoicedQty: Decimal; Quantity: Decimal; var ExpectedCost: Decimal; var ExpectedCostACY: Decimal; var ExpectedSalesAmt: Decimal; var ExpectedPurchAmt: Decimal; CalcReminder: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ExpectedCost := 0;
        ExpectedCostACY := 0;
        ExpectedSalesAmt := 0;
        ExpectedPurchAmt := 0;

        ValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        ValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        ValueEntry.SetFilter("Entry Type", '<>%1', ValueEntry."Entry Type"::Revaluation);
        OnCalcExpectedCostOnBeforeFindValueEntry(
          ValueEntry, ItemLedgEntryNo, InvoicedQty, Quantity, ExpectedCost, ExpectedCostACY, ExpectedSalesAmt, ExpectedPurchAmt, CalcReminder, InvdValueEntry, ItemJnlLine);
        if ValueEntry.FindSet() and ValueEntry."Expected Cost" then
            if CalcReminder then begin
                ValueEntry.CalcSums(
                  "Cost Amount (Expected)", "Cost Amount (Expected) (ACY)",
                  "Sales Amount (Expected)", "Purchase Amount (Expected)");
                ExpectedCost := -ValueEntry."Cost Amount (Expected)";
                ExpectedCostACY := -ValueEntry."Cost Amount (Expected) (ACY)";
                if not CalledFromAdjustment then begin
                    ExpectedSalesAmt := -ValueEntry."Sales Amount (Expected)";
                    ExpectedPurchAmt := -ValueEntry."Purchase Amount (Expected)";
                end
            end else
                if InvdValueEntry.Adjustment and
                   (InvdValueEntry."Entry Type" = InvdValueEntry."Entry Type"::"Direct Cost")
                then begin
                    ExpectedCost := -InvdValueEntry."Cost Amount (Actual)";
                    ExpectedCostACY := -InvdValueEntry."Cost Amount (Actual) (ACY)";
                    if not CalledFromAdjustment then begin
                        ExpectedSalesAmt := -InvdValueEntry."Sales Amount (Actual)";
                        ExpectedPurchAmt := -InvdValueEntry."Purchase Amount (Actual)";
                    end
                end else begin
                    repeat
                        if ValueEntry."Expected Cost" and not ValueEntry.Adjustment then begin
                            ExpectedCost := ExpectedCost + ValueEntry."Cost Amount (Expected)";
                            ExpectedCostACY := ExpectedCostACY + ValueEntry."Cost Amount (Expected) (ACY)";
                            if not CalledFromAdjustment then begin
                                ExpectedSalesAmt := ExpectedSalesAmt + ValueEntry."Sales Amount (Expected)";
                                ExpectedPurchAmt := ExpectedPurchAmt + ValueEntry."Purchase Amount (Expected)";
                            end;
                        end;
                    until ValueEntry.Next() = 0;
                    ExpectedCost :=
                      CalcExpCostToBalance(ExpectedCost, InvoicedQty, Quantity, GLSetup."Amount Rounding Precision");
                    ExpectedCostACY :=
                      CalcExpCostToBalance(ExpectedCostACY, InvoicedQty, Quantity, Currency."Amount Rounding Precision");
                    if not CalledFromAdjustment then begin
                        ExpectedSalesAmt :=
                          CalcExpCostToBalance(ExpectedSalesAmt, InvoicedQty, Quantity, GLSetup."Amount Rounding Precision");
                        ExpectedPurchAmt :=
                          CalcExpCostToBalance(ExpectedPurchAmt, InvoicedQty, Quantity, GLSetup."Amount Rounding Precision");
                    end;
                end;

        OnAfterCalcExpectedCost(ValueEntry, ItemLedgEntryNo, ExpectedCost, ExpectedCostACY, ExpectedSalesAmt, ExpectedPurchAmt)
    end;

    local procedure CalcExpCostToBalance(ExpectedCost: Decimal; InvoicedQty: Decimal; Quantity: Decimal; RoundPrecision: Decimal): Decimal
    begin
        exit(-Round(InvoicedQty / Quantity * ExpectedCost, RoundPrecision));
    end;

    local procedure MoveValEntryDimToValEntryDim(var ToValueEntry: Record "Value Entry"; FromValueEntry: Record "Value Entry")
    begin
        ToValueEntry."Global Dimension 1 Code" := FromValueEntry."Global Dimension 1 Code";
        ToValueEntry."Global Dimension 2 Code" := FromValueEntry."Global Dimension 2 Code";
        ToValueEntry."Dimension Set ID" := FromValueEntry."Dimension Set ID";
        OnAfterMoveValEntryDimToValEntryDim(ToValueEntry, FromValueEntry);
    end;

    /// <summary>
    /// Updates reservation entries for the item ledger entry based on item order tracking requirements.
    /// </summary>
    /// <remarks>
    /// If IsReserved parameter is false, and item doesn't have a tracking policy, reservations are not updated.
    /// </remarks>
    /// <param name="ItemLedgEntryRec">Item ledger entry to update reservation entries for.</param>
    /// <param name="IsReserved">Indicates if the item ledger entry is reserved. </param>
    procedure AutoTrack(var ItemLedgEntryRec: Record "Item Ledger Entry"; IsReserved: Boolean)
    var
        ReservMgt: Codeunit "Reservation Management";
    begin
        if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then begin
            if not IsReserved then
                exit;

            // Ensure that Item Tracking is not left on the item ledger entry:
            ReservMgt.SetReservSource(ItemLedgEntryRec);
            ReservMgt.SetItemTrackingHandling(1);
            ReservMgt.ClearSurplus();
            exit;
        end;

        ReservMgt.SetReservSource(ItemLedgEntryRec);
        ReservMgt.SetItemTrackingHandling(1);
        ReservMgt.DeleteReservEntries(false, ItemLedgEntryRec."Remaining Quantity");
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ItemLedgEntryRec."Remaining Quantity");
    end;

    /// <summary>
    /// Sets the value of the global flag PostponeReservationHandling.
    /// </summary>
    /// <remarks>
    /// Used to skip reservation handling functionality.
    /// </remarks>
    /// <param name="Postpone">The new value to set.</param>
    procedure SetPostponeReservationHandling(Postpone: Boolean)
    begin
        // Used when posting Transfer Order receipts
        PostponeReservationHandling := Postpone;
    end;

    local procedure SetupSplitJnlLine(var ItemJnlLine2: Record "Item Journal Line"; TrackingSpecExists: Boolean): Boolean
    var
        LateBindingMgt: Codeunit "Late Binding Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        NonDistrQuantity: Decimal;
        NonDistrAmount: Decimal;
        NonDistrAmountACY: Decimal;
        NonDistrDiscountAmount: Decimal;
        SignFactor: Integer;
        CalcWarrantyDate: Date;
        CalcExpirationDate: Date;
        Invoice: Boolean;
        ExpirationDateChecked: Boolean;
        PostItemJnlLine: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeSetupSplitJnlLineProcedure(ItemJnlLine2, TrackingSpecExists, CalledFromAdjustment);

        ItemJnlLineOrigin := ItemJnlLine2;
        TempSplitItemJnlLine.Reset();
        TempSplitItemJnlLine.DeleteAll();

        DisableItemTracking := false;
        OnSetupSplitJnlLineOnSetDisableItemTracking(ItemJnlLine2, DisableItemTracking);
        Invoice := ItemJnlLine2."Invoiced Qty. (Base)" <> 0;

        if (ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer) and PostponeReservationHandling then
            SignFactor := 1
        else
            SignFactor := ItemJnlLine2.Signed(1);

        GlobalItemTrackingCode.Code := Item."Item Tracking Code";
        OnSetupSplitJnlLineOnBeforeGetItemTrackingSetup(ItemJnlLine2, TrackingSpecExists, CalledFromAdjustment, Item, GlobalItemTrackingCode);
        ItemTrackingMgt.GetItemTrackingSetup(
            GlobalItemTrackingCode, ItemJnlLine."Entry Type",
            ItemJnlLine.Signed(ItemJnlLine."Quantity (Base)") > 0, GlobalItemTrackingSetup);

        OnSetupSplitJnlLineOnAfterGetItemTrackingSetup(GlobalItemTrackingCode, ItemJnlLine2, GlobalItemTrackingSetup, ItemJnlLine);

        if Item."Costing Method" = Item."Costing Method"::Specific then begin
            Item.TestField("Item Tracking Code");
            GlobalItemTrackingCode.TestField("SN Specific Tracking", true);
        end;

        OnBeforeSetupSplitJnlLine(ItemJnlLine2, TrackingSpecExists, TempTrackingSpecification);

        if not ItemJnlLine2.Correction and (ItemJnlLine2."Quantity (Base)" <> 0) and TrackingSpecExists then begin
            if DisableItemTracking then begin
                if not TempTrackingSpecification.IsEmpty() then
                    OnSetupSplitJnlLineOnCheckOperationNo(ItemJnlLine2);
            end else begin
                if TempTrackingSpecification.IsEmpty() then
                    Error(Text100);

                CheckItemTrackingIsEmpty(ItemJnlLine2);

                if Format(GlobalItemTrackingCode."Warranty Date Formula") <> '' then
                    CalcWarrantyDate := CalcDate(GlobalItemTrackingCode."Warranty Date Formula", ItemJnlLine2."Document Date");

                IsHandled := false;
                OnBeforeCalcExpirationDate(ItemJnlLine2, CalcExpirationDate, IsHandled, Item);
                if not IsHandled then
                    if Format(Item."Expiration Calculation") <> '' then
                        CalcExpirationDate := CalcDate(Item."Expiration Calculation", ItemJnlLine2."Document Date");

                IsHandled := false;
                OnSetupSplitJnlLineOnBeforeReallocateTrkgSpecification(GlobalItemTrackingCode, TempTrackingSpecification, ItemJnlLine2, SignFactor, IsHandled);
                if not IsHandled then
                    if SignFactor * ItemJnlLine2.Quantity < 0 then // Demand
                        if GlobalItemTrackingCode."SN Specific Tracking" or GlobalItemTrackingCode."Lot Specific Tracking" then
                            LateBindingMgt.ReallocateTrkgSpecification(TempTrackingSpecification);

                TempTrackingSpecification.CalcSums(
                  "Qty. to Handle (Base)", "Qty. to Invoice (Base)", "Qty. to Handle", "Qty. to Invoice");
                TempTrackingSpecification.TestFieldError(TempTrackingSpecification.FieldCaption("Qty. to Handle (Base)"),
                  TempTrackingSpecification."Qty. to Handle (Base)", SignFactor * ItemJnlLine2."Quantity (Base)");

                if Invoice then
                    TempTrackingSpecification.TestFieldError(TempTrackingSpecification.FieldCaption("Qty. to Invoice (Base)"),
                      TempTrackingSpecification."Qty. to Invoice (Base)", SignFactor * ItemJnlLine2."Invoiced Qty. (Base)");

                OnSetupSplitJnlLineOnBeforeCalcNonDistrQuantity(TempTrackingSpecification, ItemJnlLine2, Invoice, SignFactor);
                NonDistrQuantity :=
                    UOMMgt.CalcQtyFromBase(
                        ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", ItemJnlLine2."Unit of Measure Code",
                        UOMMgt.RoundQty(
                            UOMMgt.CalcBaseQty(
                                ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", ItemJnlLine2."Unit of Measure Code",
                                ItemJnlLine2.Quantity, ItemJnlLine2."Qty. per Unit of Measure")),
                    ItemJnlLine2."Qty. per Unit of Measure");
                NonDistrAmount := ItemJnlLine2.Amount;
                NonDistrAmountACY := ItemJnlLine2."Amount (ACY)";
                NonDistrDiscountAmount := ItemJnlLine2."Discount Amount";

                OnSetupSplitJnlLineOnBeforeSplitTempLines(TempSplitItemJnlLine, TempTrackingSpecification);

                TempTrackingSpecification.FindSet();
                repeat
                    if GlobalItemTrackingCode."Man. Warranty Date Entry Reqd." then
                        TempTrackingSpecification.TestField("Warranty Date");

                    OnSetupSplitJnlLineOnBeforeCheckUseExpirationDates(ItemJnlLine2, TempTrackingSpecification, Item, CalcExpirationDate);
                    if GlobalItemTrackingCode."Use Expiration Dates" then
                        CheckExpirationDate(ItemJnlLine2, SignFactor, CalcExpirationDate, ExpirationDateChecked);
                    OnSetupSplitJnlLineOnAfterCheckExpirationDate(ItemJnlLine2, TempTrackingSpecification, Item);

                    CheckItemTrackingInformation(
                        ItemJnlLine2, TempTrackingSpecification, SignFactor, GlobalItemTrackingCode, GlobalItemTrackingSetup);

                    if TempTrackingSpecification."Warranty Date" = 0D then
                        TempTrackingSpecification."Warranty Date" := CalcWarrantyDate;

                    TempTrackingSpecification.Modify();
                    TempSplitItemJnlLine := ItemJnlLine2;
                    PostItemJnlLine :=
                      PostItemJnlLine or
                      SetupTempSplitItemJnlLine(
                        ItemJnlLine2, SignFactor, NonDistrQuantity, NonDistrAmount,
                        NonDistrAmountACY, NonDistrDiscountAmount, Invoice);
                    OnSetupSplitJnlLineOnAfterSetupTempSplitItemJnlLine(ItemJnlLine2, TempSplitItemJnlLine, TempTrackingSpecification);
                until TempTrackingSpecification.Next() = 0;
            end;
        end else
            InsertTempSplitItemJnlLine(ItemJnlLine2, PostItemJnlLine);

        OnAfterSetupSplitJnlLine(
            ItemJnlLine2, TempSplitItemJnlLine, ItemJnlLineOrigin, TempTrackingSpecification,
            TrackingSpecExists, CalledFromAdjustment, PostponeReservationHandling, PostItemJnlLine);
        exit(PostItemJnlLine);
    end;

    local procedure InsertTempSplitItemJnlLine(ItemJnlLine2: Record "Item Journal Line"; var PostItemJnlLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertTempSplitItemJnlLine(ItemJnlLine2, IsServUndoConsumption, PostponeReservationHandling, TempSplitItemJnlLine, IsHandled, PostItemJnlLine);
        if IsHandled then
            exit;

        TempSplitItemJnlLine := ItemJnlLine2;
        TempSplitItemJnlLine.Insert();

        OnAfterInsertTempSplitItemJnlLine(TempSplitItemJnlLine, ItemJnlLine2)
    end;

    local procedure SplitItemJnlLine(var ItemJnlLine2: Record "Item Journal Line"; PostItemJnlLine: Boolean): Boolean
    var
        FreeEntryNo: Integer;
        JnlLineNo: Integer;
        SignFactor: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnSplitItemJnlLineOnBeforeTracking(
            ItemJnlLine2, PostItemJnlLine, TempTrackingSpecification, GlobalItemLedgEntry, TempItemEntryRelation,
            PostponeReservationHandling, SignFactor, IsHandled);
        if not IsHandled then
            if (ItemJnlLine2."Quantity (Base)" <> 0) and ItemJnlLine2.TrackingExists() then begin
                if (ItemJnlLine2."Entry Type" in
                    [ItemJnlLine2."Entry Type"::Sale,
                    ItemJnlLine2."Entry Type"::"Negative Adjmt.",
                    ItemJnlLine2."Entry Type"::Consumption,
                    ItemJnlLine2."Entry Type"::"Assembly Consumption"]) or
                ((ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer) and
                    not PostponeReservationHandling)
                then
                    SignFactor := -1
                else
                    SignFactor := 1;

                TempTrackingSpecification.SetTrackingFilterFromItemJnlLine(ItemJnlLine2);
                if TempTrackingSpecification.FindFirst() then begin
                    FreeEntryNo := TempTrackingSpecification."Entry No.";
                    TempTrackingSpecification.Delete();
                    ItemJnlLine2.CheckTrackingEqualTrackingSpecification(TempTrackingSpecification);
                    TempTrackingSpecification."Quantity (Base)" := SignFactor * ItemJnlLine2."Quantity (Base)";
                    TempTrackingSpecification."Quantity Handled (Base)" := SignFactor * ItemJnlLine2."Quantity (Base)";
                    TempTrackingSpecification."Quantity actual Handled (Base)" := SignFactor * ItemJnlLine2."Quantity (Base)";
                    TempTrackingSpecification."Quantity Invoiced (Base)" := SignFactor * ItemJnlLine2."Invoiced Qty. (Base)";
                    TempTrackingSpecification."Qty. to Invoice (Base)" :=
                    SignFactor * (ItemJnlLine2."Quantity (Base)" - ItemJnlLine2."Invoiced Qty. (Base)");
                    TempTrackingSpecification."Qty. to Handle (Base)" := 0;
                    TempTrackingSpecification."Qty. to Handle" := 0;
                    TempTrackingSpecification."Qty. to Invoice" :=
                    SignFactor * (ItemJnlLine2.Quantity - ItemJnlLine2."Invoiced Quantity");
                    TempTrackingSpecification."Item Ledger Entry No." := GlobalItemLedgEntry."Entry No.";
                    TempTrackingSpecification."Transfer Item Entry No." := TempItemEntryRelation."Item Entry No.";
                    OnSplitItemJnlLineOnBeforePostItemJnlLine(TempTrackingSpecification, GlobalItemLedgEntry);
                    if PostItemJnlLine then
                        TempTrackingSpecification."Entry No." := TempTrackingSpecification."Item Ledger Entry No.";
                    OnSplitItemJnlLineOnBeforeInsertTempTrkgSpecification(TempTrackingSpecification, ItemJnlLine2, SignFactor);
                    InsertTempTrkgSpecification(FreeEntryNo);
                end else
                    if (ItemJnlLine2."Item Charge No." = '') and (ItemJnlLine2."Job No." = '') then
                        if not ItemJnlLine2.Correction then begin // Undo quantity posting
                            IsHandled := false;
                            OnBeforeTrackingSpecificationMissingErr(ItemJnlLine2, IsHandled);
                            if not IsHandled then
                                Error(TrackingSpecificationMissingErr);
                        end;
            end;

        if TempSplitItemJnlLine.FindFirst() then begin
            JnlLineNo := ItemJnlLine2."Line No.";
            ItemJnlLine2 := TempSplitItemJnlLine;
            ItemJnlLine2."Line No." := JnlLineNo;
            TempSplitItemJnlLine.Delete();
            OnSplitItemJnlLineOnAfterDeleteTempSplitItemJnlLine(ItemJnlLine2, CalledFromAdjustment);
            exit(true);
        end;
        if ItemJnlLine."Phys. Inventory" then
            InsertPhysInventoryEntry(ItemJnlLineOrigin);
        exit(false);
    end;

    /// <summary>
    /// Copies all tracking specification lines from the global variable to the parameter, overriding all existing lines. 
    /// After the transfer, all lines are deleted from the global record set.
    /// </summary>
    /// <remakrs>
    /// Global and the provided target tracking specification record set is deleted.
    /// </remakrs>
    /// <param name="TargetTrackingSpecification">Return value: Copied tracking specification lines.</param>
    /// <returns>True if any tracking specifications were transferred, otherwise false.</returns>
    procedure CollectTrackingSpecification(var TargetTrackingSpecification: Record "Tracking Specification" temporary) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        OnBeforeCollectTrackingSpecification(TempTrackingSpecification, TargetTrackingSpecification, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempTrackingSpecification.Reset();
        TargetTrackingSpecification.Reset();
        TargetTrackingSpecification.DeleteAll();

        if TempTrackingSpecification.FindSet() then
            repeat
                TargetTrackingSpecification := TempTrackingSpecification;
                TargetTrackingSpecification.Insert();
            until TempTrackingSpecification.Next() = 0
        else
            exit(false);

        TempTrackingSpecification.DeleteAll();

        exit(true);
    end;

    /// <summary>
    /// Copies all value entry relation lines from the global variable to the parameter, overriding all existing lines. 
    /// After the transfer, all lines are deleted from the global record set.
    /// </summary>
    /// <remakrs>
    /// Global value entry relation record set is deleted after the transfer.
    /// </remakrs>
    /// <param name="TargetValueEntryRelation">Return value: Copied value entry relations lines.</param>
    /// <param name="RowId">Unique identifier text of a line that will be used in source rowId field.</param>
    /// <returns>True if any value entry relations were transferred, otherwise false.</returns>
    procedure CollectValueEntryRelation(var TargetValueEntryRelation: Record "Value Entry Relation" temporary; RowId: Text[250]) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCollectValueEntryRelation(TempValueEntryRelation, TargetValueEntryRelation, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempValueEntryRelation.Reset();
        TargetValueEntryRelation.Reset();

        if TempValueEntryRelation.FindSet() then
            repeat
                TargetValueEntryRelation := TempValueEntryRelation;
                TargetValueEntryRelation."Source RowId" := RowId;
                TargetValueEntryRelation.Insert();
            until TempValueEntryRelation.Next() = 0
        else
            exit(false);

        TempValueEntryRelation.DeleteAll();

        exit(true);
    end;

    /// <summary>
    /// Copies all item entry relation lines from the global variable to the parameter, overriding all existing lines. 
    /// After the transfer, all lines are deleted from the global record set.
    /// </summary>
    /// <remakrs>
    /// Global item entry relation record set is deleted after the transfer.
    /// </remakrs>
    /// <param name="TargetItemEntryRelation">Return value: Copied item entry relation lines.</param>
    /// <returns>True if any item entry relation lines were transferred, otherwise false.</returns>
    procedure CollectItemEntryRelation(var TargetItemEntryRelation: Record "Item Entry Relation" temporary) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCollectItemEntryRelation(TempItemEntryRelation, TargetItemEntryRelation, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempItemEntryRelation.Reset();
        TargetItemEntryRelation.Reset();

        if TempItemEntryRelation.FindSet() then
            repeat
                TargetItemEntryRelation := TempItemEntryRelation;
                TargetItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0
        else
            exit(false);

        TempItemEntryRelation.DeleteAll();

        exit(true);
    end;

    local procedure CheckExpirationDate(var ItemJnlLine2: Record "Item Journal Line"; SignFactor: Integer; CalcExpirationDate: Date; var ExpirationDateChecked: Boolean)
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        ExistingExpirationDate: Date;
        EntriesExist: Boolean;
        SumOfEntries: Decimal;
        SumLot: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckExpirationDate(
          ItemJnlLine2, TempTrackingSpecification, SignFactor, CalcExpirationDate, ExpirationDateChecked, IsHandled);
        if IsHandled then
            exit;

        ExistingExpirationDate :=
          ItemTrackingMgt.ExistingExpirationDate(TempTrackingSpecification, true, EntriesExist);

        if not (EntriesExist or ExpirationDateChecked) then begin
            ItemTrackingMgt.TestExpDateOnTrackingSpec(TempTrackingSpecification);
            ExpirationDateChecked := true;
        end;
        IsHandled := false;
        OnCheckExpirationDateOnBeforeAssignExpirationDate(TempTrackingSpecification, ExistingExpirationDate, IsHandled);
        if not IsHandled then
            if ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer then
                if TempTrackingSpecification."Expiration Date" = 0D then
                    TempTrackingSpecification."Expiration Date" := ExistingExpirationDate;

        // Supply
        if SignFactor * ItemJnlLine2.Quantity > 0 then begin        // Only expiration dates on supply.
            if not (ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer) then
                if GlobalItemTrackingCode."Man. Expir. Date Entry Reqd." then begin
                    if ItemJnlLine2."Phys. Inventory" and (ExistingExpirationDate <> 0D) then
                        TempTrackingSpecification."Expiration Date" := ExistingExpirationDate;
                    if not TempTrackingSpecification.Correction then
                        if TempTrackingSpecification."Appl.-from Item Entry" = 0 then
                            TempTrackingSpecification.TestField("Expiration Date");
                end;

            if CalcExpirationDate <> 0D then
                if ExistingExpirationDate <> 0D then
                    CalcExpirationDate := ExistingExpirationDate;

            if ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer then
                if TempTrackingSpecification."New Expiration Date" = 0D then
                    TempTrackingSpecification."New Expiration Date" := ExistingExpirationDate;

            if TempTrackingSpecification."Expiration Date" = 0D then
                TempTrackingSpecification."Expiration Date" := CalcExpirationDate;

            OnCheckExpirationDateOnBeforeTestFieldExpirationDate(TempTrackingSpecification, EntriesExist, ExistingExpirationDate);
            if EntriesExist then
                TempTrackingSpecification.TestField("Expiration Date", ExistingExpirationDate);

            if (ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer) and (ItemJnlLine2."Order Type" = ItemJnlLine2."Order Type"::Transfer) then begin
                GetExistingExpirationDateFromILE(ItemTrackingSetup, ExistingExpirationDate, SumOfEntries);

                if TempTrackingSpecification."New Serial No." <> '' then
                    SumLot := SignFactor * ItemTrackingMgt.SumNewLotOnTrackingSpec(TempTrackingSpecification)
                else
                    SumLot := SignFactor * TempTrackingSpecification."Quantity (Base)";

                if (SumOfEntries > 0) and
                   ((SumOfEntries <> SumLot) or (TempTrackingSpecification."New Lot No." <> TempTrackingSpecification."Lot No."))
                then
                    TempTrackingSpecification.TestField("New Expiration Date", ExistingExpirationDate);
            end;
        end else   // Demand
            if ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer then begin
                GetExistingExpirationDateFromILE(ItemTrackingSetup, ExistingExpirationDate, SumOfEntries);

                if (ItemJnlLine2."Order Type" = ItemJnlLine2."Order Type"::Transfer) and
                   (ItemJnlLine2."Order No." <> '')
                then
                    if TempTrackingSpecification."New Expiration Date" = 0D then
                        TempTrackingSpecification."New Expiration Date" := ExistingExpirationDate;

                if (TempTrackingSpecification."New Lot No." <> '') and
                   ((ItemJnlLine2."Order Type" <> ItemJnlLine2."Order Type"::Transfer) or
                    (ItemJnlLine2."Order No." = ''))
                then begin
                    if TempTrackingSpecification."New Serial No." <> '' then
                        SumLot := SignFactor * ItemTrackingMgt.SumNewLotOnTrackingSpec(TempTrackingSpecification)
                    else
                        SumLot := SignFactor * TempTrackingSpecification."Quantity (Base)";
                    OnCheckExpirationDateOnAfterCalcSumLot(SumLot, SignFactor, TempTrackingSpecification);
                    if (SumOfEntries > 0) and
                       ((SumOfEntries <> SumLot) or (TempTrackingSpecification."New Lot No." <> TempTrackingSpecification."Lot No.")
                       or (TempTrackingSpecification."New Package No." <> TempTrackingSpecification."Package No."))
                    then
                        TempTrackingSpecification.TestField("New Expiration Date", ExistingExpirationDate);
                    ItemTrackingMgt.TestExpDateOnTrackingSpecNew(TempTrackingSpecification);
                end;
            end;

        if (ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer) and
           ((ItemJnlLine2."Order Type" <> ItemJnlLine2."Order Type"::Transfer) or
            (ItemJnlLine2."Order No." = ''))
        then
            if GlobalItemTrackingCode."Man. Expir. Date Entry Reqd." then
                TempTrackingSpecification.TestField("New Expiration Date");
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            if GLSetup."Additional Reporting Currency" <> '' then begin
                Currency.Get(GLSetup."Additional Reporting Currency");
                Currency.TestField("Unit-Amount Rounding Precision");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;
        GLSetupRead := true;

        OnAfterGetGLSetup(GLSetup);
    end;

    local procedure GetGeneralPostingSetup(ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetGeneralPostingSetup(ItemJournalLine, GenPostingSetup, PostToGL, IsHandled);
        if IsHandled then
            exit;

        if (ItemJournalLine."Gen. Bus. Posting Group" <> GenPostingSetup."Gen. Bus. Posting Group") or
            (ItemJournalLine."Gen. Prod. Posting Group" <> GenPostingSetup."Gen. Prod. Posting Group")
        then begin
            GenPostingSetup.Get(ItemJournalLine."Gen. Bus. Posting Group", ItemJournalLine."Gen. Prod. Posting Group");
            GenPostingSetup.TestField(Blocked, false);
        end;
    end;

    local procedure GetInvtSetup()
    begin
        if not InvtSetupRead then begin
            InvtSetup.Get();
            SourceCodeSetup.Get();
        end;
        InvtSetupRead := true;
    end;

    local procedure UndoQuantityPosting()
    var
        OldItemLedgEntry: Record "Item Ledger Entry";
        OldItemLedgEntry2: Record "Item Ledger Entry";
        NewItemLedgEntry: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        NewValueEntry: Record "Value Entry";
        IsReserved: Boolean;
        IsHandled: Boolean;
        ShouldInsertCorrValueEntries: Boolean;
        ShouldCheckItem: Boolean;
    begin
        IsHandled := false;
        OnBeforeUndoQuantityPosting(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJnlLine."Entry Type" in [ItemJnlLine."Entry Type"::"Assembly Consumption",
                                        ItemJnlLine."Entry Type"::"Assembly Output"]
        then
            exit;

        if ItemJnlLine."Applies-to Entry" <> 0 then begin
            OldItemLedgEntry.Get(ItemJnlLine."Applies-to Entry");

            IsHandled := false;
            OnUndoQuantityPostingOnBeforeCheckPositive(ItemJnlLine, OldItemLedgEntry, IsHandled);
            if not IsHandled then
                if not OldItemLedgEntry.Positive then
                    ItemJnlLine."Applies-from Entry" := ItemJnlLine."Applies-to Entry";
        end else
            OldItemLedgEntry.Get(ItemJnlLine."Applies-from Entry");

        if GetItem(OldItemLedgEntry."Item No.", false) then begin
            ShouldCheckItem := true;
            OnUndoQuantityPostingOnBeforeCheckItem(Item, OldItemLedgEntry, ShouldCheckItem);
            if ShouldCheckItem then begin
                Item.TestField(Blocked, false);
                Item.CheckBlockedByApplWorksheet();

                if GetItemVariant(OldItemLedgEntry."Item No.", OldItemLedgEntry."Variant Code", false) then
                    ItemVariant.TestField(Blocked, false);
            end;
        end;

        ItemJnlLine."Item No." := OldItemLedgEntry."Item No.";

        OnUndoQuantityPostingOnBeforeInitCorrItemLedgEntry(ItemJnlLine, OldItemLedgEntry);
        InitCorrItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry);   // also inserts
        OnUndoQuantityPostingOnAfterInitCorrItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry);

        if Item.IsNonInventoriableType() then begin
            NewItemLedgEntry."Remaining Quantity" := 0;
            NewItemLedgEntry.Open := false;
        end;

        OnUndoQuantityPostingOnAfterInsertItemReg(ItemJnlLine, OldItemLedgEntry, NewItemLedgEntry);
        GlobalItemLedgEntry := NewItemLedgEntry;

        CalcILEExpectedAmount(OldValueEntry, OldItemLedgEntry."Entry No.");
        if OldValueEntry.Inventoriable then
            AvgCostEntryPointHandler.UpdateValuationDate(OldValueEntry);

        ShouldInsertCorrValueEntries := OldItemLedgEntry."Invoiced Quantity" = 0;
        OnUndoQuantityPostingOnAfterCalcShouldInsertCorrValueEntry(OldItemLedgEntry, ShouldInsertCorrValueEntries);
        if ShouldInsertCorrValueEntries then begin
            IsHandled := false;
            OnUndoQuantityPostingOnBeforeInsertCorrOldItemLedgEntry(OldItemLedgEntry, IsHandled);
            if not IsHandled then
                InsertCorrValueEntry(
                OldValueEntry, NewValueEntry, OldItemLedgEntry, OldValueEntry."Document Line No.", 1,
                0, OldItemLedgEntry.Quantity);
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, ItemJnlLine."Document Line No.", -1,
              NewItemLedgEntry.Quantity, 0);
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, ItemJnlLine."Document Line No.", -1,
              0, NewItemLedgEntry.Quantity);
        end else
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, ItemJnlLine."Document Line No.", -1,
              NewItemLedgEntry.Quantity, NewItemLedgEntry.Quantity);

        OnUndoQuantityPostingOnBeforeUpdateOldItemLedgEntry(OldValueEntry, NewItemLedgEntry, NewValueEntry, ItemJnlLine);
        UpdateOldItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry."Posting Date");
        UpdateItemApplnEntry(OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date");
        OnUndoQuantityPostingOnAfterUpdateItemApplnEntry(ItemJnlLine, OldItemLedgEntry, NewItemLedgEntry, NewValueEntry, InventoryPostingToGL);

        if GlobalItemLedgEntry.Quantity > 0 then
            IsReserved :=
              ItemJnlLineReserve.TransferItemJnlToItemLedgEntry(
                ItemJnlLine, GlobalItemLedgEntry, ItemJnlLine."Quantity (Base)", true);

        if not ItemJnlLine.IsATOCorrection() then begin
            ApplyItemLedgEntry(NewItemLedgEntry, OldItemLedgEntry2, NewValueEntry, false);
            OnUndoQuantityPostingOnBeforeAutoTrack(NewItemLedgEntry);
            AutoTrack(NewItemLedgEntry, IsReserved);
            OnUndoQuantityPostingOnAfterAutoTrack(NewItemLedgEntry, NewValueEntry, ItemJnlLine, Item);
        end;

        NewItemLedgEntry.Modify();
        UpdateAdjmtProperties(NewValueEntry, NewItemLedgEntry."Posting Date");

        OnUndoQuantityPostingOnBeforeInsertApplEntry(NewItemLedgEntry, OldItemLedgEntry, GlobalItemLedgEntry);
        if NewItemLedgEntry.Positive then begin
            UpdateOrigAppliedFromEntry(OldItemLedgEntry."Entry No.");
            OldItemLedgEntry.SetAppliedEntryToAdjust(true);
            InsertApplEntry(
              NewItemLedgEntry."Entry No.", NewItemLedgEntry."Entry No.",
              OldItemLedgEntry."Entry No.", 0, NewItemLedgEntry."Posting Date",
              -OldItemLedgEntry.Quantity, false);
        end;
        OnAfterUndoQuantityPosting(NewItemLedgEntry, ItemJnlLine);
    end;

    /// <summary>
    /// Undoes the value entry posting of an item ledger entry with a job number.
    /// </summary>
    /// <param name="OldItemLedgEntryNo">Inbound item ledger entry number.</param>
    /// <param name="NewItemLedgEntryNo">Outbound item ledger entry number.</param>
    procedure UndoValuePostingWithJob(OldItemLedgEntryNo: Integer; NewItemLedgEntryNo: Integer)
    var
        OldItemLedgEntry: Record "Item Ledger Entry";
        NewItemLedgEntry: Record "Item Ledger Entry";
        OldValueEntry: Record "Value Entry";
        NewValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUndoValuePostingWithJob(OldItemLedgEntryNo, NewItemLedgEntryNo, IsHandled);
        if IsHandled then
            exit;

        OldItemLedgEntry.Get(OldItemLedgEntryNo);
        NewItemLedgEntry.Get(NewItemLedgEntryNo);
        InitValueEntryNo();

        if OldItemLedgEntry."Invoiced Quantity" = 0 then begin
            CalcILEExpectedAmount(OldValueEntry, OldItemLedgEntry."Entry No.");
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, OldItemLedgEntry, OldValueEntry."Document Line No.", 1,
              0, OldItemLedgEntry.Quantity);

            CalcILEExpectedAmount(OldValueEntry, NewItemLedgEntry."Entry No.");
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, NewItemLedgEntry."Document Line No.", 1,
              0, NewItemLedgEntry.Quantity);
        end else
            InsertCorrValueEntry(
              OldValueEntry, NewValueEntry, NewItemLedgEntry, NewItemLedgEntry."Document Line No.", -1,
              NewItemLedgEntry.Quantity, NewItemLedgEntry.Quantity);

        UpdateOldItemLedgEntry(OldItemLedgEntry, NewItemLedgEntry."Posting Date");
        UpdateOldItemLedgEntry(NewItemLedgEntry, NewItemLedgEntry."Posting Date");
        UpdateItemApplnEntry(OldItemLedgEntry."Entry No.", NewItemLedgEntry."Posting Date");

        NewItemLedgEntry.Modify();
        UpdateAdjmtProperties(NewValueEntry, NewItemLedgEntry."Posting Date");

        if NewItemLedgEntry.Positive then
            UpdateOrigAppliedFromEntry(OldItemLedgEntry."Entry No.");
    end;

    local procedure InitCorrItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; var NewItemLedgEntry: Record "Item Ledger Entry")
    var
        EntriesExist: Boolean;
    begin
        if OldItemLedgEntry."Entry Type" = OldItemLedgEntry."Entry Type"::Sale then
            if (OldItemLedgEntry."Serial No." <> '') and (OldItemLedgEntry."Serial No." = ItemJnlLine."Serial No.") and
                ((-OldItemLedgEntry.Quantity) > 0)
            then
                CheckItemSerialNoForCorrILE(ItemJnlLine);

        ItemLedgEntryNo := GetNextItemLedgerEntryNo(ItemLedgEntryNo);
        NewItemLedgEntry := OldItemLedgEntry;
        ItemTrackingMgt.RetrieveAppliedExpirationDate(NewItemLedgEntry);
        OnInitCorrItemLedgEntryOnAfterRetrieveAppliedExpirationDate(NewItemLedgEntry);

        NewItemLedgEntry."Entry No." := ItemLedgEntryNo;
        NewItemLedgEntry.Quantity := -OldItemLedgEntry.Quantity;
        NewItemLedgEntry."Remaining Quantity" := -OldItemLedgEntry.Quantity;
        if NewItemLedgEntry.Quantity > 0 then
            NewItemLedgEntry."Shipped Qty. Not Returned" := 0
        else
            NewItemLedgEntry."Shipped Qty. Not Returned" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry."Invoiced Quantity" := NewItemLedgEntry.Quantity;
        NewItemLedgEntry.Positive := NewItemLedgEntry."Remaining Quantity" > 0;
        NewItemLedgEntry.Open := NewItemLedgEntry."Remaining Quantity" <> 0;
        NewItemLedgEntry."Completely Invoiced" := true;
        NewItemLedgEntry."Last Invoice Date" := NewItemLedgEntry."Posting Date";
        NewItemLedgEntry.Correction := true;
        NewItemLedgEntry."Document Line No." := ItemJnlLine."Document Line No.";
        if OldItemLedgEntry.Positive then
            NewItemLedgEntry."Applies-to Entry" := OldItemLedgEntry."Entry No."
        else
            NewItemLedgEntry."Applies-to Entry" := 0;

        InsertItemReg(NewItemLedgEntry."Entry No.", 0, 0, 0);
        NewItemLedgEntry."Item Register No." := ItemReg."No.";

        OnBeforeInsertCorrItemLedgEntry(NewItemLedgEntry, OldItemLedgEntry, ItemJnlLine);
        NewItemLedgEntry.Insert(true);
        OnAfterInsertCorrItemLedgEntry(NewItemLedgEntry, ItemJnlLine, OldItemLedgEntry);

        if NewItemLedgEntry."Item Tracking" <> NewItemLedgEntry."Item Tracking"::None then
            ItemTrackingMgt.ExistingExpirationDate(NewItemLedgEntry, true, EntriesExist);

        OnAfterInitCorrItemLedgEntry(NewItemLedgEntry, EntriesExist);
    end;

    local procedure UpdateOldItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; LastInvoiceDate: Date)
    begin
        OldItemLedgEntry."Completely Invoiced" := true;
        OldItemLedgEntry."Last Invoice Date" := LastInvoiceDate;
        OldItemLedgEntry."Invoiced Quantity" := OldItemLedgEntry.Quantity;
        OldItemLedgEntry."Shipped Qty. Not Returned" := 0;
        OnBeforeOldItemLedgEntryModify(OldItemLedgEntry);
        OldItemLedgEntry.Modify();
    end;

    local procedure InsertCorrValueEntry(OldValueEntry: Record "Value Entry"; var NewValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry"; DocumentLineNo: Integer; Sign: Integer; QtyToShip: Decimal; QtyToInvoice: Decimal)
    var
        xValueEntryNo: Integer;
    begin
        ValueEntryNo := GetNextValueEntryNo(ValueEntryNo);

        NewValueEntry := OldValueEntry;
        xValueEntryNo := ValueEntryNo;
        OnInsertCorrValueEntryOnAfterAssignNewValueEntry(GlobalItemLedgEntry, OldValueEntry, NewValueEntry, ItemJnlLine, ItemLedgEntry, ValueEntryNo);
        if (ValueEntryNo <> xValueEntryNo) and not InvtSetup.UseLegacyPosting() then begin
            ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");
            ValueEntryNo := GetNextValueEntryNo(ValueEntryNo);
        end;
        NewValueEntry."Entry No." := ValueEntryNo;
        NewValueEntry."Item Ledger Entry No." := ItemLedgEntry."Entry No.";
        NewValueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(NewValueEntry."User ID"));
        NewValueEntry."Valued Quantity" := Sign * OldValueEntry."Valued Quantity";
        NewValueEntry."Document Line No." := DocumentLineNo;
        NewValueEntry."Item Ledger Entry Quantity" := QtyToShip;
        NewValueEntry."Invoiced Quantity" := QtyToInvoice;
        NewValueEntry."Expected Cost" := QtyToInvoice = 0;
        if not NewValueEntry."Expected Cost" then begin
            NewValueEntry."Cost Amount (Expected)" := -Sign * OldValueEntry."Cost Amount (Expected)";
            NewValueEntry."Cost Amount (Expected) (ACY)" := -Sign * OldValueEntry."Cost Amount (Expected) (ACY)";
            if QtyToShip = 0 then begin
                NewValueEntry."Cost Amount (Actual)" := Sign * OldValueEntry."Cost Amount (Expected)";
                NewValueEntry."Cost Amount (Actual) (ACY)" := Sign * OldValueEntry."Cost Amount (Expected) (ACY)";
            end else begin
                NewValueEntry."Cost Amount (Actual)" := -NewValueEntry."Cost Amount (Actual)";
                NewValueEntry."Cost Amount (Actual) (ACY)" := -NewValueEntry."Cost Amount (Actual) (ACY)";
            end;
            NewValueEntry."Purchase Amount (Expected)" := -Sign * OldValueEntry."Purchase Amount (Expected)";
            NewValueEntry."Sales Amount (Expected)" := -Sign * OldValueEntry."Sales Amount (Expected)";
        end else begin
            NewValueEntry."Cost Amount (Expected)" := -OldValueEntry."Cost Amount (Expected)";
            NewValueEntry."Cost Amount (Expected) (ACY)" := -OldValueEntry."Cost Amount (Expected) (ACY)";
            NewValueEntry."Cost Amount (Actual)" := 0;
            NewValueEntry."Cost Amount (Actual) (ACY)" := 0;
            NewValueEntry."Sales Amount (Expected)" := -OldValueEntry."Sales Amount (Expected)";
            NewValueEntry."Purchase Amount (Expected)" := -OldValueEntry."Purchase Amount (Expected)";
        end;

        NewValueEntry."Purchase Amount (Actual)" := 0;
        NewValueEntry."Sales Amount (Actual)" := 0;
        NewValueEntry."Cost Amount (Non-Invtbl.)" := Sign * OldValueEntry."Cost Amount (Non-Invtbl.)";
        NewValueEntry."Cost Amount (Non-Invtbl.)(ACY)" := Sign * OldValueEntry."Cost Amount (Non-Invtbl.)(ACY)";
        NewValueEntry."Cost Posted to G/L" := 0;
        NewValueEntry."Cost Posted to G/L (ACY)" := 0;
        NewValueEntry."Expected Cost Posted to G/L" := 0;
        NewValueEntry."Exp. Cost Posted to G/L (ACY)" := 0;

        xValueEntryNo := ValueEntryNo;
        OnBeforeInsertCorrValueEntry(NewValueEntry, OldValueEntry, ItemJnlLine, Sign, CalledFromAdjustment, ItemLedgEntry, ValueEntryNo, InventoryPostingToGL);
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");

        PostInventoryToGL(NewValueEntry);

        InsertItemReg(0, 0, NewValueEntry."Entry No.", 0);
        NewValueEntry."Item Register No." := ItemReg."No.";
        NewValueEntry.Insert(true);

        xValueEntryNo := ValueEntryNo;
        OnAfterInsertCorrValueEntry(NewValueEntry, ItemJnlLine, ItemLedgEntry, ValueEntryNo);
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");

        ItemApplnEntry.SetOutboundsNotUpdated(ItemLedgEntry);

        UpdateAdjmtProperties(NewValueEntry, ItemLedgEntry."Posting Date");

        InsertPostValueEntryToGL(NewValueEntry);
    end;

    local procedure UpdateOrigAppliedFromEntry(OldItemLedgEntryNo: Integer)
    var
        ItemApplEntry: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemApplEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
        ItemApplEntry.SetRange("Outbound Item Entry No.", OldItemLedgEntryNo);
        ItemApplEntry.SetFilter("Item Ledger Entry No.", '<>%1', OldItemLedgEntryNo);
        if ItemApplEntry.FindSet() then
            repeat
                if ItemLedgEntry.Get(ItemApplEntry."Inbound Item Entry No.") and
                   not ItemLedgEntry."Applied Entry to Adjust"
                then begin
                    ItemLedgEntry."Applied Entry to Adjust" := true;
                    ItemLedgEntry.Modify();
                end;
                OnUpdateOrigAppliedFromEntryOnItemApplEntryLoop(ItemLedgEntry, ItemApplEntry);
            until ItemApplEntry.Next() = 0;
    end;

    local procedure GetItem(ItemNo: Code[20]; Unconditionally: Boolean): Boolean
    var
        HasGotItem: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItem(Item, ItemNo, Unconditionally, HasGotItem, IsHandled);
        if IsHandled then
            exit(HasGotItem);

        Item.ReadIsolation(IsolationLevel::ReadUncommitted);
        if not Unconditionally then
            exit(Item.Get(ItemNo))
        else
            Item.Get(ItemNo);
        exit(true);
    end;

    local procedure GetItemVariant(ItemNo: Code[20]; VariantCode: Code[10]; Unconditionally: Boolean): Boolean
    var
        ReturnValue: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeGetItemVariant(ItemVariant, ItemNo, VariantCode, Unconditionally, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if VariantCode = '' then begin
            Clear(ItemVariant);
            exit(false);
        end;

        if not Unconditionally then
            exit(ItemVariant.Get(ItemNo, VariantCode))
        else
            ItemVariant.Get(ItemNo, VariantCode);
        exit(true);
    end;

    local procedure CheckItemAndItemVariant(ItemNo: Code[20]; VariantCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemAndItemVariant(ItemNo, VariantCode, Item, ItemVariant, IsHandled);
        if IsHandled then
            exit;

        if GetItem(ItemNo, false) then begin
            if not CalledFromAdjustment then
                Item.TestField(Blocked, false);
            OnCheckItemOnAfterGetItem(Item, ItemJnlLine, CalledFromAdjustment);

            if GetItemVariant(ItemNo, VariantCode, false) then begin
                if not CalledFromAdjustment then
                    ItemVariant.TestField(Blocked, false);
                OnCheckItemVariantOnAfterGetItemVariant(ItemVariant, ItemJnlLine, CalledFromAdjustment);
            end else
                ItemVariant.Init();
        end else
            Item.Init();

        OnAfterCheckItemAndVariant(ItemJnlLine, CalledFromAdjustment);
    end;

    /// <summary>
    /// Checks the tracking information of an item journal. If serial, lot or package numbers are required but are missing, an error is thrown.
    /// </summary>
    /// <remarks>
    /// If the journal line is a transfer, it also checks for new serial, lot and package numbers to be assigned during the posting.
    /// </remarks>
#if not CLEAN27
    [Obsolete('Replaced by same procedure with parameters ItemJnlLine', '27.0')]
    procedure CheckItemTracking()
    begin
        CheckItemTracking(ItemJnlLine);
    end;
#endif

    procedure CheckItemTracking(var ItemJnlLine2: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTracking(ItemJnlLine2, GlobalItemTrackingSetup, IsHandled, TempTrackingSpecification);
        if IsHandled then
            exit;

        if GlobalItemTrackingSetup."Serial No. Required" and (ItemJnlLine2."Serial No." = '') then
            Error(GetTextStringWithLineNo(SerialNoRequiredErr, ItemJnlLine2."Item No.", ItemJnlLine2."Line No."));
        if GlobalItemTrackingSetup."Lot No. Required" and (ItemJnlLine2."Lot No." = '') then
            Error(GetTextStringWithLineNo(LotNoRequiredErr, ItemJnlLine2."Item No.", ItemJnlLine2."Line No."));

        IsHandled := false;
        OnCheckItemTrackingOnAfterCheckRequiredTrackingNos(ItemJnlLine2, GlobalItemTrackingSetup, IsHandled);
        if not IsHandled then
            if ItemJnlLine2."Entry Type" = ItemJnlLine2."Entry Type"::Transfer then
                ItemJnlLine2.CheckNewTrackingIfRequired(GlobalItemTrackingSetup);

        OnAfterCheckItemTracking(ItemJnlLine2, GlobalItemTrackingSetup, GlobalItemTrackingCode);
    end;

    local procedure CheckItemTrackingInformation(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; SignFactor: Decimal; ItemTrackingCode: Record "Item Tracking Code"; ItemTrackingSetup: Record "Item Tracking Setup")
    var
        SerialNoInfo: Record "Serial No. Information";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingInformation(ItemJnlLine2, TrackingSpecification, ItemTrackingSetup, SignFactor, ItemTrackingCode, IsHandled, GlobalItemTrackingCode);
        if IsHandled then
            exit;

        if ItemTrackingCode."Create SN Info on Posting" then
            ItemTrackingMgt.CreateSerialNoInformation(TrackingSpecification);

        IsHandled := false;
        OnCheckItemTrackingInformationOnBeforeTestFields(ItemTrackingSetup, TrackingSpecification, ItemJnlLine2, IsHandled);
        if not IsHandled then
            if ItemTrackingSetup."Serial No. Info Required" then begin
                SerialNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Serial No.");
                SerialNoInfo.TestField(Blocked, false);
                if TrackingSpecification."New Serial No." <> '' then begin
                    SerialNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Serial No.");
                    SerialNoInfo.TestField(Blocked, false);
                end;
            end else begin
                if SerialNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Serial No.") then
                    SerialNoInfo.TestField(Blocked, false);
                if TrackingSpecification."New Serial No." <> '' then
                    if SerialNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Serial No.") then
                        SerialNoInfo.TestField(Blocked, false);
            end;

        if ItemTrackingCode."Create Lot No. Info on posting" then
            ItemTrackingMgt.CreateLotNoInformation(TrackingSpecification);

        CheckLotNoInfoNotBlocked(ItemTrackingSetup, ItemJnlLine2, TrackingSpecification);

        OnAfterCheckItemTrackingInformation(ItemJnlLine2, TrackingSpecification, ItemTrackingSetup, Item);
    end;

    local procedure CheckLotNoInfoNotBlocked(ItemTrackingSetup: Record "Item Tracking Setup"; var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification")
    var
        LotNoInfo: Record "Lot No. Information";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLotNoInfoNotBlocked(ItemJnlLine2, IsHandled, ItemTrackingSetup, TrackingSpecification);
        if IsHandled then
            exit;

        if ItemTrackingSetup."Lot No. Info Required" then begin
            LotNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Lot No.");
            LotNoInfo.TestField(Blocked, false);
            if TrackingSpecification."New Lot No." <> '' then begin
                LotNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Lot No.");
                LotNoInfo.TestField(Blocked, false);
            end;
        end else begin
            if LotNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."Lot No.") then
                LotNoInfo.TestField(Blocked, false);
            if TrackingSpecification."New Lot No." <> '' then
                if LotNoInfo.Get(ItemJnlLine2."Item No.", ItemJnlLine2."Variant Code", TrackingSpecification."New Lot No.") then
                    LotNoInfo.TestField(Blocked, false);
        end;
    end;

    local procedure CheckItemTrackingIsEmpty(ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemTrackingIsEmpty(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine.CheckTrackingIsEmpty();
        ItemJnlLine.CheckNewTrackingIsEmpty();
    end;

    local procedure CheckItemSerialNo(ItemJnlLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSerialNo(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if SkipSerialNoQtyValidation then
            exit;

        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then begin
            if ItemTrackingMgt.FindInInventory(ItemJnlLine."Item No.", ItemJnlLine."Variant Code", ItemJnlLine."New Serial No.") then
                Error(Text014, ItemJnlLine."New Serial No.")
        end else
            if ItemTrackingMgt.FindInInventory(ItemJnlLine."Item No.", ItemJnlLine."Variant Code", ItemJnlLine."Serial No.") then
                Error(Text014, ItemJnlLine."Serial No.");
    end;

    local procedure CheckItemCorrection(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        RaiseError: Boolean;
    begin
        RaiseError := ItemLedgerEntry.Correction;
        OnBeforeCheckItemCorrection(ItemLedgerEntry, RaiseError);
        if RaiseError then
            Error(CannotUnapplyCorrEntryErr);
    end;

    local procedure InsertTempTrkgSpecification(FreeEntryNo: Integer)
    var
        TempTrackingSpecification2: Record "Tracking Specification" temporary;
    begin
        if not TempTrackingSpecification.Insert() then begin
            TempTrackingSpecification2 := TempTrackingSpecification;
            TempTrackingSpecification.Get(TempTrackingSpecification2."Item Ledger Entry No.");
            TempTrackingSpecification.Delete();
            TempTrackingSpecification."Entry No." := FreeEntryNo;
            TempTrackingSpecification.Insert();
            TempTrackingSpecification := TempTrackingSpecification2;
            TempTrackingSpecification.Insert();
        end;
    end;

    local procedure IsNotInternalWhseMovement(ItemJnlLine: Record "Item Journal Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsNotInternalWhseMovement(ItemJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(ItemJnlLine.IsNotInternalWhseMovement());
    end;

    /// <summary>
    /// Sets the value of the global flag CalledFromInvtPutawayPick.
    /// </summary>
    /// <param name="NewCalledFromInvtPutawayPick">The new value to set.</param>
    procedure SetCalledFromInvtPutawayPick(NewCalledFromInvtPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := NewCalledFromInvtPutawayPick;
    end;

    /// <summary>
    /// Sets the values of the global flags CalledFromAdjustment and PostToGL.
    /// </summary>
    /// <param name="NewCalledFromAdjustment">The new value to set.</param>
    /// <param name="NewPostToGL">The new value to set.</param>
    procedure SetCalledFromAdjustment(NewCalledFromAdjustment: Boolean; NewPostToGL: Boolean)
    begin
        OnBeforeSetCalledFromAdjustment(CalledFromAdjustment);

        CalledFromAdjustment := NewCalledFromAdjustment;
        PostToGL := NewPostToGL;
    end;

    internal procedure GetPostToGL(): Boolean
    begin
        exit(PostToGL);
    end;

#if not CLEAN27
    /// <summary>
    /// Determines if the next operation number exists on the provided production order routing line.
    /// </summary>
    /// <param name="ProdOrderRtngLine">Production order routing line to check.</param>
    /// <returns>True if next operation number exists, otherwise false.</returns>
    [Obsolete('Moved to table ProdOrderRoutingLine', '27.0')]
    procedure NextOperationExist(var ProdOrderRtngLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"): Boolean
    begin
        OnBeforeNextOperationExist(ProdOrderRtngLine);
        exit(ProdOrderRtngLine."Next Operation No." <> '');
    end;
#endif

    local procedure UpdateAdjmtProperties(ValueEntry: Record "Value Entry"; OriginalPostingDate: Date)
    begin
        SetAdjmtProperties(
            ValueEntry."Item No.", ValueEntry."Item Ledger Entry Type", ValueEntry.Adjustment,
            ValueEntry."Order Type", ValueEntry."Order No.", ValueEntry."Order Line No.", OriginalPostingDate, ValueEntry."Valuation Date");

        OnAfterUpdateAdjmtProp(ValueEntry, OriginalPostingDate);
    end;

    local procedure SetAdjmtProperties(ItemNo: Code[20]; ItemLedgEntryType: Enum "Item Ledger Entry Type"; Adjustment: Boolean; OrderType: Enum "Inventory Order Type"; OrderNo: Code[20]; OrderLineNo: Integer; OriginalPostingDate: Date; ValuationDate: Date)
    begin
        SetItemAdjmtProperties(ItemNo, ItemLedgEntryType, Adjustment, OriginalPostingDate, ValuationDate);
        SetOrderAdjmtProperties(ItemLedgEntryType, OrderType, OrderNo, OrderLineNo, OriginalPostingDate, ValuationDate);
    end;

    local procedure SetItemAdjmtProperties(ItemNo: Code[20]; ItemLedgEntryType: Enum "Item Ledger Entry Type"; Adjustment: Boolean; OriginalPostingDate: Date; ValuationDate: Date)
    var
        Item2: Record Item;
        ValueEntry: Record "Value Entry";
        ModifyItem: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetItemAdjmtProperties(ItemNo, ItemLedgEntryType, Adjustment, OriginalPostingDate, ValuationDate, IsHandled);
        if IsHandled then
            exit;

        if ItemLedgEntryType = ValueEntry."Item Ledger Entry Type"::" " then
            exit;
        if Adjustment then
            if not (ItemLedgEntryType in [ValueEntry."Item Ledger Entry Type"::Output,
                                          ValueEntry."Item Ledger Entry Type"::"Assembly Output"])
            then
                exit;

        if Item2.Get(ItemNo) and (Item2."Allow Online Adjustment" or Item2."Cost is Adjusted") and (Item2.Type = Item2.Type::Inventory) then begin
            Item2.LockTable();
            if Item2."Cost is Adjusted" then begin
                Item2."Cost is Adjusted" := false;
                ModifyItem := true;
            end;
            if Item2."Allow Online Adjustment" then begin
                if Item2."Costing Method" = Item2."Costing Method"::Average then
                    Item2."Allow Online Adjustment" := AllowAdjmtOnPosting(ValuationDate)
                else
                    Item2."Allow Online Adjustment" := AllowAdjmtOnPosting(OriginalPostingDate);
                ModifyItem := ModifyItem or not Item2."Allow Online Adjustment";
            end;
            OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem(Item2, ModifyItem);
            if ModifyItem then
                Item2.Modify();
        end;
    end;

    local procedure SetOrderAdjmtProperties(ItemLedgEntryType: Enum "Item Ledger Entry Type"; OrderType: Enum "Inventory Order Type"; OrderNo: Code[20]; OrderLineNo: Integer; OriginalPostingDate: Date; ValuationDate: Date)
    var
        ValueEntry: Record "Value Entry";
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        AssemblyHeader: Record "Assembly Header";
        ModifyOrderAdjmt: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetOrderAdjmtProperties(
            ItemLedgEntryType.AsInteger(), OrderType.AsInteger(), OrderNo, OrderLineNo, OriginalPostingDate, ValuationDate, IsHandled, ItemJnlLine);
        if IsHandled then
            exit;

        if not (OrderType in [ValueEntry."Order Type"::Production,
                              ValueEntry."Order Type"::Assembly])
        then
            exit;

        if ItemLedgEntryType in [ValueEntry."Item Ledger Entry Type"::Output,
                                 ValueEntry."Item Ledger Entry Type"::"Assembly Output"]
        then
            exit;

        if not InventoryAdjmtEntryOrder.Get(OrderType, OrderNo, OrderLineNo) then
            case OrderType of
                InventoryAdjmtEntryOrder."Order Type"::Production:
                    begin
                        OnSetOrderAdjmtPropertiesForProduction(InventoryAdjmtEntryOrder, OrderNo, OrderLineNo);
                        SetOrderAdjmtProperties(ItemLedgEntryType, OrderType, OrderNo, OrderLineNo, OriginalPostingDate, ValuationDate);
                    end;
                InventoryAdjmtEntryOrder."Order Type"::Assembly:
                    begin
                        if OrderLineNo = 0 then begin
                            AssemblyHeader.SetLoadFields("Item No.");
                            AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, OrderNo);
                            InventoryAdjmtEntryOrder.SetAsmOrder(AssemblyHeader);
                        end;
                        SetOrderAdjmtProperties(ItemLedgEntryType, OrderType, OrderNo, 0, OriginalPostingDate, ValuationDate);
                    end;
            end
        else
            if InventoryAdjmtEntryOrder."Allow Online Adjustment" or InventoryAdjmtEntryOrder."Cost is Adjusted" then begin
                InventoryAdjmtEntryOrder.LockTable();
                IsHandled := false;
                OnSetOrderAdjmtPropertiesOnBeforeSetCostIsAdjusted(InventoryAdjmtEntryOrder, ModifyOrderAdjmt, IsHandled, OriginalPostingDate);
                if not IsHandled then
                    if InventoryAdjmtEntryOrder."Cost is Adjusted" then begin
                        InventoryAdjmtEntryOrder."Cost is Adjusted" := false;
                        ModifyOrderAdjmt := true;
                    end;
                IsHandled := false;
                OnSetOrderAdjmtPropertiesOnBeforeSetAllowOnlineAdjustment(InventoryAdjmtEntryOrder, ModifyOrderAdjmt, IsHandled, OriginalPostingDate);
                if not IsHandled then
                    if InventoryAdjmtEntryOrder."Allow Online Adjustment" then begin
                        InventoryAdjmtEntryOrder."Allow Online Adjustment" := AllowAdjmtOnPosting(OriginalPostingDate);
                        ModifyOrderAdjmt := ModifyOrderAdjmt or not InventoryAdjmtEntryOrder."Allow Online Adjustment";
                    end;
                if ModifyOrderAdjmt then
                    InventoryAdjmtEntryOrder.Modify();
            end;
    end;

    /// <summary>
    /// Determines if an adjustment is allowed on a given posting date based on the automatic cost adjustment setting 
    /// in the inventory setup.
    /// </summary>
    /// <param name="TheDate">The date to check.</param>
    /// <returns>True if adjustment is allowed, otherwise false.</returns>
    procedure AllowAdjmtOnPosting(TheDate: Date): Boolean
    begin
        GetInvtSetup();

        case InvtSetup."Automatic Cost Adjustment" of
            InvtSetup."Automatic Cost Adjustment"::Never:
                exit(false);
            InvtSetup."Automatic Cost Adjustment"::Day:
                exit(TheDate >= CalcDate('<-1D>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Week:
                exit(TheDate >= CalcDate('<-1W>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Month:
                exit(TheDate >= CalcDate('<-1M>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Quarter:
                exit(TheDate >= CalcDate('<-1Q>', WorkDate()));
            InvtSetup."Automatic Cost Adjustment"::Year:
                exit(TheDate >= CalcDate('<-1Y>', WorkDate()));
            else
                exit(true);
        end;
    end;

    local procedure InsertBalanceExpCostRevEntry(ValueEntry: Record "Value Entry")
    var
        ValueEntry2: Record "Value Entry";
        ValueEntry3: Record "Value Entry";
        RevExpCostToBalance: Decimal;
        RevExpCostToBalanceACY: Decimal;
        xValueEntryNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        xValueEntryNo := ValueEntryNo;
        OnBeforeInsertBalanceExpCostRevEntry(GlobalItemLedgEntry, ValueEntry, ValueEntryNo, GLSetup, Currency, GLSetupRead, IsHandled);
        ValidateSequenceNo(ValueEntryNo, xValueEntryNo, Database::"Value Entry");
        if IsHandled then
            exit;

        if GlobalItemLedgEntry.Quantity - (GlobalItemLedgEntry."Invoiced Quantity" - ValueEntry."Invoiced Quantity") = 0 then
            exit;

        ValueEntry2.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry2.SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
        ValueEntry2.SetRange("Entry Type", ValueEntry2."Entry Type"::Revaluation);
        ValueEntry2.SetRange("Applies-to Entry", 0);
        if ValueEntry2.FindSet() then
            repeat
                CalcRevExpCostToBalance(ValueEntry2, ValueEntry."Invoiced Quantity", RevExpCostToBalance, RevExpCostToBalanceACY);
                if (RevExpCostToBalance <> 0) or (RevExpCostToBalanceACY <> 0) then begin
                    ValueEntryNo := GetNextValueEntryNo(ValueEntryNo);
                    ValueEntry3 := ValueEntry;
                    ValueEntry3."Entry No." := ValueEntryNo;
                    ValueEntry3."Item Charge No." := '';
                    ValueEntry3."Entry Type" := ValueEntry."Entry Type"::Revaluation;
                    ValueEntry3."Valuation Date" := ValueEntry2."Valuation Date";
                    ValueEntry3.Description := '';
                    ValueEntry3."Applies-to Entry" := ValueEntry2."Entry No.";
                    ValueEntry3."Cost Amount (Expected)" := RevExpCostToBalance;
                    ValueEntry3."Cost Amount (Expected) (ACY)" := RevExpCostToBalanceACY;
                    ValueEntry3."Valued Quantity" := ValueEntry2."Valued Quantity";
                    ValueEntry3."Cost per Unit" := CalcCostPerUnit(RevExpCostToBalance, ValueEntry."Valued Quantity", false);
                    ValueEntry3."Cost per Unit (ACY)" := CalcCostPerUnit(RevExpCostToBalanceACY, ValueEntry."Valued Quantity", true);
                    ValueEntry3."Cost Posted to G/L" := 0;
                    ValueEntry3."Cost Posted to G/L (ACY)" := 0;
                    ValueEntry3."Expected Cost Posted to G/L" := 0;
                    ValueEntry3."Exp. Cost Posted to G/L (ACY)" := 0;
                    ValueEntry3."Invoiced Quantity" := 0;
                    ValueEntry3."Sales Amount (Actual)" := 0;
                    ValueEntry3."Purchase Amount (Actual)" := 0;
                    ValueEntry3."Discount Amount" := 0;
                    ValueEntry3."Cost Amount (Actual)" := 0;
                    ValueEntry3."Cost Amount (Actual) (ACY)" := 0;
                    ValueEntry3."Sales Amount (Expected)" := 0;
                    ValueEntry3."Purchase Amount (Expected)" := 0;
                    InsertValueEntry(ValueEntry3, GlobalItemLedgEntry, false);
                end;
            until ValueEntry2.Next() = 0;
    end;

    local procedure IsBalanceExpectedCostFromRev(ItemJnlLine2: Record "Item Journal Line"): Boolean
    begin
        exit((Item."Costing Method" = Item."Costing Method"::Standard) and
              (((ItemJnlLine2.Quantity = 0) and (ItemJnlLine2."Invoiced Quantity" <> 0)) or
               (ItemJnlLine2.Adjustment and not GlobalValueEntry."Expected Cost")));
    end;

    local procedure CalcRevExpCostToBalance(ValueEntry: Record "Value Entry"; InvdQty: Decimal; var RevExpCostToBalance: Decimal; var RevExpCostToBalanceACY: Decimal)
    var
        ValueEntry2: Record "Value Entry";
        OldExpectedQty: Decimal;
    begin
        RevExpCostToBalance := -ValueEntry."Cost Amount (Expected)";
        RevExpCostToBalanceACY := -ValueEntry."Cost Amount (Expected) (ACY)";
        OldExpectedQty := GlobalItemLedgEntry.Quantity;
        ValueEntry2.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        ValueEntry2.SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
        if GlobalItemLedgEntry.Quantity <> GlobalItemLedgEntry."Invoiced Quantity" then begin
            ValueEntry2.SetRange("Entry Type", ValueEntry2."Entry Type"::"Direct Cost");
            if ValueEntry."Entry No." >= 0 then
                ValueEntry2.SetFilter("Entry No.", '<%1', ValueEntry."Entry No.")
            else
                if not IsNullGuid(ValueEntry.SystemID) then
                    ValueEntry2.SetFilter(SystemID, '<%1', ValueEntry.SystemID);  // Preview?
            ValueEntry2.SetRange("Item Charge No.", '');
            ValueEntry2.CalcSums("Invoiced Quantity");
            OldExpectedQty -= ValueEntry2."Invoiced Quantity";
            RevExpCostToBalance := Round(RevExpCostToBalance * InvdQty / OldExpectedQty, GLSetup."Amount Rounding Precision");
            RevExpCostToBalanceACY := Round(RevExpCostToBalanceACY * InvdQty / OldExpectedQty, Currency."Amount Rounding Precision");
        end else begin
            ValueEntry2.SetRange("Entry Type", ValueEntry2."Entry Type"::Revaluation);
            ValueEntry2.SetRange("Applies-to Entry", ValueEntry."Entry No.");
            ValueEntry2.CalcSums("Cost Amount (Expected)", "Cost Amount (Expected) (ACY)");
            RevExpCostToBalance -= ValueEntry2."Cost Amount (Expected)";
            RevExpCostToBalanceACY -= ValueEntry2."Cost Amount (Expected) (ACY)";
        end;
    end;

    local procedure IsInterimRevaluation() Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsInterimRevaluation(ItemJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit((ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::Revaluation) and (ItemJnlLine.Quantity <> 0));
    end;

    local procedure InsertPostValueEntryToGL(ValueEntry: Record "Value Entry")
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
    begin
        if IsPostToGL(ValueEntry) then begin
            PostValueEntryToGL.Init();
            PostValueEntryToGL."Value Entry No." := ValueEntry."Entry No.";
            PostValueEntryToGL."Item No." := ValueEntry."Item No.";
            PostValueEntryToGL."Posting Date" := ValueEntry."Posting Date";
            OnInsertPostValueEntryToGLOnAfterTransferFields(PostValueEntryToGL, ValueEntry);
            PostValueEntryToGL.Insert();
        end;

        OnAfterInsertPostValueEntryToGL(ValueEntry);
    end;

    local procedure IsPostToGL(ValueEntry: Record "Value Entry") Result: Boolean
    begin
        GetInvtSetup();
        Result :=
            ValueEntry.Inventoriable and not PostToGL and
            (((not ValueEntry."Expected Cost") and ((ValueEntry."Cost Amount (Actual)" <> 0) or (ValueEntry."Cost Amount (Actual) (ACY)" <> 0))) or
            (InvtSetup."Expected Cost Posting to G/L" and ((ValueEntry."Cost Amount (Expected)" <> 0) or (ValueEntry."Cost Amount (Expected) (ACY)" <> 0))));

        OnAfterIsPostToGL(ValueEntry, Result, PostToGL);
    end;

    local procedure IsWarehouseReclassification(ItemJournalLine: Record "Item Journal Line"): Boolean
    begin
        exit(ItemJournalLine."Warehouse Adjustment" and (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::Transfer));
    end;

    local procedure IsNotValuedByAverageCost(CostItemLedgEntryNo: Integer): Boolean
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", CostItemLedgEntryNo);
        ValueEntry.SetRange("Valued By Average Cost", true);
        exit(ValueEntry.IsEmpty());
    end;

    local procedure MoveApplication(var ItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"): Boolean
    var
        ItemApplicationEntry: Record "Item Application Entry";
        Enough: Boolean;
        FixedApplication: Boolean;
    begin
        OnBeforeMoveApplication(ItemLedgerEntry, OldItemLedgerEntry);

        FixedApplication := false;
        OldItemLedgerEntry.TestField(Positive, true);

        if (OldItemLedgerEntry."Remaining Quantity" < Abs(ItemLedgerEntry.Quantity)) and
           (OldItemLedgerEntry."Remaining Quantity" < OldItemLedgerEntry.Quantity)
        then begin
            Enough := false;
            ItemApplicationEntry.Reset();
            ItemApplicationEntry.SetCurrentKey("Inbound Item Entry No.");
            ItemApplicationEntry.SetRange("Inbound Item Entry No.", ItemLedgerEntry."Applies-to Entry");
            ItemApplicationEntry.SetFilter("Outbound Item Entry No.", '<>0');

            if ItemApplicationEntry.FindSet() then
                repeat
                    if not ItemApplicationEntry.Fixed() then begin
                        UnApply(ItemApplicationEntry);
                        OldItemLedgerEntry.Get(OldItemLedgerEntry."Entry No.");
                        OldItemLedgerEntry.CalcReservedQuantity();
                        Enough :=
                          Abs(OldItemLedgerEntry."Remaining Quantity" - OldItemLedgerEntry."Reserved Quantity") >=
                          Abs(ItemLedgerEntry."Remaining Quantity");
                    end else
                        FixedApplication := true;
                until (ItemApplicationEntry.Next() = 0) or Enough
            else
                exit(false);
            // no applications found that could be undone
            OnAfterMoveApplication(ItemLedgerEntry, OldItemLedgerEntry, Enough);
            if not Enough and FixedApplication then
                ShowFixedApplicationError();
            exit(Enough);
        end;
        exit(true);
    end;

    local procedure CheckApplication(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckApplication(ItemLedgEntry, OldItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if SkipApplicationCheck then begin
            SkipApplicationCheck := false;
            exit;
        end;

        IsHandled := false;
        OnCheckApplicationOnBeforeRemainingQtyError(OldItemLedgEntry, ItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if Abs(OldItemLedgEntry."Remaining Quantity" - OldItemLedgEntry."Reserved Quantity") <
           Abs(ItemLedgEntry."Remaining Quantity" - ItemLedgEntry."Reserved Quantity")
        then
            OldItemLedgEntry.FieldError("Remaining Quantity", Text004)
    end;

    local procedure CheckApplFromInProduction(var GlobalItemLedgerEntry: Record "Item Ledger Entry"; AppliesFRomEntryNo: Integer)
    var
        OldItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if AppliesFRomEntryNo = 0 then
            exit;

        if (GlobalItemLedgerEntry."Order Type" = GlobalItemLedgerEntry."Order Type"::Production) and (GlobalItemLedgerEntry."Order No." <> '') then begin
            OldItemLedgerEntry.Get(AppliesFRomEntryNo);
            if not AllowProdApplication(OldItemLedgerEntry, GlobalItemLedgEntry) then
                Error(
                  Text022,
                  OldItemLedgerEntry."Entry Type",
                  GlobalItemLedgerEntry."Entry Type",
                  GlobalItemLedgerEntry."Item No.",
                  GlobalItemLedgerEntry."Order No.");

            if ItemApplnEntry.CheckIsCyclicalLoop(GlobalItemLedgerEntry, OldItemLedgerEntry) then
                Error(
                  Text022,
                  OldItemLedgerEntry."Entry Type",
                  GlobalItemLedgerEntry."Entry Type",
                  GlobalItemLedgerEntry."Item No.",
                  GlobalItemLedgerEntry."Order No.");
        end;
    end;

    /// <summary>
    /// Reapplies all touched item ledger entries with remaining quantity, and deletes them afterwards.
    /// </summary>
    /// <remarks>
    /// Touched item ledger entries are entries that have been marked or identified in some way during the posting process.
    /// </remarks>
    procedure RedoApplications()
    var
        TouchedItemLedgEntry: Record "Item Ledger Entry";
        DialogWindow: Dialog;
        "Count": Integer;
        t: Integer;
    begin
        TempTouchedItemLedgerEntries.SetCurrentKey("Item No.", Open, "Variant Code", Positive, "Location Code", "Posting Date", "Entry No.");
        if TempTouchedItemLedgerEntries.Find('-') then begin
            DialogWindow.Open(Text01 +
              '@1@@@@@@@@@@@@@@@@@@@@@@@');
            Count := TempTouchedItemLedgerEntries.Count();
            t := 0;

            repeat
                t := t + 1;
                DialogWindow.Update(1, Round(t * 10000 / Count, 1));
                TouchedItemLedgEntry.Get(TempTouchedItemLedgerEntries."Entry No.");
                if TouchedItemLedgEntry."Remaining Quantity" <> 0 then begin
                    ReApply(TouchedItemLedgEntry, 0);
                    TouchedItemLedgEntry.Get(TempTouchedItemLedgerEntries."Entry No.");
                end;
            until TempTouchedItemLedgerEntries.Next() = 0;
            if AnyTouchedEntries() then
                VerifyTouchedOnInventory();
            TempTouchedItemLedgerEntries.DeleteAll();
            DeleteTouchedEntries();
            DialogWindow.Close();
        end;
    end;

    local procedure UpdateValuedByAverageCost(CostItemLedgEntryNo: Integer; ValuedByAverage: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        if CostItemLedgEntryNo = 0 then
            exit;

        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", CostItemLedgEntryNo);
        ValueEntry.SetRange(Inventoriable, true);
        ValueEntry.SetRange("Valued By Average Cost", not ValuedByAverage);
        ValueEntry.ModifyAll("Valued By Average Cost", ValuedByAverage);
    end;

    /// <summary>
    /// Performs an inventory cost adjustment based on the automatic cost adjustment setting in the inventory setup.
    /// </summary>
    procedure CostAdjust()
    var
        InvtSetup: Record "Inventory Setup";
        InventoryPeriod: Record "Inventory Period";
        InventoryAdjustmentHandler: Codeunit "Inventory Adjustment Handler";
        Opendate: Date;
    begin
        InvtSetup.Get();
        InventoryPeriod.IsValidDate(Opendate);
        if InvtSetup."Automatic Cost Adjustment" <> InvtSetup."Automatic Cost Adjustment"::Never then begin
            if Opendate <> 0D then
                Opendate := CalcDate('<+1D>', Opendate);

            InventoryAdjustmentHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
        end;
    end;

    /// <summary>
    /// Marks an item ledger entry as touched by inserting it into a global buffer.
    /// </summary>
    /// <param name="EntryNo">Item ledger entry to mark.</param>
    procedure TouchEntry(EntryNo: Integer)
    var
        TouchedItemLedgEntry: Record "Item Ledger Entry";
    begin
        TouchedItemLedgEntry.Get(EntryNo);
        TempTouchedItemLedgerEntries := TouchedItemLedgEntry;
        if not TempTouchedItemLedgerEntries.Insert() then;
    end;

    local procedure TouchItemEntryCost(var ItemLedgerEntry: Record "Item Ledger Entry"; IsAdjustment: Boolean)
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTouchItemEntryCost(ItemLedgerEntry, ItemJnlLine, IsAdjustment, IsHandled);
        if IsHandled then
            exit;

        ItemLedgerEntry."Applied Entry to Adjust" := true;
        SetAdjmtProperties(
          ItemLedgerEntry."Item No.", ItemLedgerEntry."Entry Type", IsAdjustment, ItemLedgerEntry."Order Type", ItemLedgerEntry."Order No.", ItemLedgerEntry."Order Line No.", ItemLedgerEntry."Posting Date", ItemLedgerEntry."Posting Date");

        OnTouchItemEntryCostOnAfterAfterSetAdjmtProp(ItemLedgerEntry, IsAdjustment);

        if not IsAdjustment then begin
            EnsureValueEntryLoaded(ValueEntry, ItemLedgerEntry);
            AvgCostEntryPointHandler.UpdateValuationDate(ValueEntry);
        end;
    end;

    /// <summary>
    /// Determines if there are any temporary touched item ledger entries on the global record set.
    /// </summary>
    /// <returns>True if touched entires exists, otherwise false.</returns>
    procedure AnyTouchedEntries(): Boolean
    begin
        exit(TempTouchedItemLedgerEntries.Find('-'));
    end;

    local procedure GetMaxAppliedValuationdate(ItemLedgerEntry: Record "Item Ledger Entry"): Date
    var
        ToItemApplnEntry: Record "Item Application Entry";
        FromItemledgEntryNo: Integer;
        FromInbound: Boolean;
        MaxDate: Date;
        NewDate: Date;
    begin
        FromInbound := ItemLedgerEntry.Positive;
        FromItemledgEntryNo := ItemLedgerEntry."Entry No.";
        if FromInbound then begin
            ToItemApplnEntry.SetCurrentKey("Inbound Item Entry No.", "Item Ledger Entry No.", "Outbound Item Entry No.");
            ToItemApplnEntry.SetRange("Inbound Item Entry No.", FromItemledgEntryNo);
            ToItemApplnEntry.SetFilter("Outbound Item Entry No.", '<>%1', 0);
            ToItemApplnEntry.SetFilter(Quantity, '>%1', 0);
        end else begin
            ToItemApplnEntry.SetCurrentKey("Outbound Item Entry No.", "Item Ledger Entry No.");
            ToItemApplnEntry.SetRange("Outbound Item Entry No.", FromItemledgEntryNo);
            ToItemApplnEntry.SetFilter(Quantity, '<%1', 0);
        end;
        if ToItemApplnEntry.FindSet() then begin
            MaxDate := 0D;
            repeat
                if FromInbound then
                    ItemLedgerEntry.Get(ToItemApplnEntry."Outbound Item Entry No.")
                else
                    ItemLedgerEntry.Get(ToItemApplnEntry."Inbound Item Entry No.");
                NewDate := GetMaxValuationDate(ItemLedgerEntry);
                MaxDate := max(NewDate, MaxDate);
            until ToItemApplnEntry.Next() = 0
        end;
        exit(MaxDate);
    end;

    local procedure "Max"(Date1: Date; Date2: Date): Date
    begin
        if Date1 > Date2 then
            exit(Date1);
        exit(Date2);
    end;

    /// <summary>
    /// Sets the valuation date of all value entry records associated with a given item ledger entry no. to a given date.
    /// </summary>
    /// <remarks>
    /// The date is modified if the valuation date is not equal to the posting date, or if it's less than the given date, 
    /// or if it's greater than the given date and the application is fixed.
    /// </remarks>
    /// <param name="ItemLedgerEntryNo">Item ledger entry no. to find value entries for.</param>
    /// <param name="ValuationDate">Valuation date to set.</param>
    /// <param name="FixedApplication">Indicates if it's a fixed application.</param>
    procedure SetValuationDateAllValueEntrie(ItemLedgerEntryNo: Integer; ValuationDate: Date; FixedApplication: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Reset();
        ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        if ValueEntry.FindSet() then
            repeat
                if (ValueEntry."Valuation Date" <> ValueEntry."Posting Date") or
                   (ValueEntry."Valuation Date" < ValuationDate) or
                   ((ValueEntry."Valuation Date" > ValuationDate) and FixedApplication)
                then begin
                    ValueEntry."Valuation Date" := ValuationDate;
                    ValueEntry.Modify();
                end;
            until ValueEntry.Next() = 0;
    end;

    /// <summary>
    /// Sets the value of the global flag IsServUndoConsumption.
    /// </summary>
    /// <param name="Value">The new value to set.</param>
    procedure SetServUndoConsumption(Value: Boolean)
    begin
        IsServUndoConsumption := Value;
    end;

    /// <summary>
    /// Sets the value of the global flag ProdOrderCompModified.
    /// </summary>
    /// <param name="ProdOrderCompIsModified">The new value to set.</param>
    procedure SetProdOrderCompModified(ProdOrderCompIsModified: Boolean)
    begin
        ProdOrderCompModified := ProdOrderCompIsModified;
    end;

    /// <summary>
    /// Updates the country/region on the new item ledger entry based on the new or existing item ledger entry's location.
    /// </summary>
    /// <param name="NewItemLedgEntry">Return value: New item ledger entry with updated coutnry/region code.</param>
    /// <param name="ItemLedgEntry">Existing item ledger entry.</param>
    procedure InsertCountryCode(var NewItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        if ItemLedgEntry."Location Code" = '' then
            exit;
        if NewItemLedgEntry."Location Code" = '' then begin
            Location.Get(ItemLedgEntry."Location Code");
            NewItemLedgEntry."Country/Region Code" := Location."Country/Region Code";
        end else begin
            Location.Get(NewItemLedgEntry."Location Code");
            if not Location."Use As In-Transit" then begin
                Location.Get(ItemLedgEntry."Location Code");
                if not Location."Use As In-Transit" then
                    NewItemLedgEntry."Country/Region Code" := Location."Country/Region Code";
            end;
        end;
    end;

    local procedure ReservationPreventsApplication(ApplicationEntry: Integer; ItemNo: Code[20]; ReservationsEntry: Record "Item Ledger Entry")
    var
        ReservationEntries: Record "Reservation Entry";
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReserveItemLedgEntry: Codeunit "Item Ledger Entry-Reserve";
    begin
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservationEntries, true);
        ReserveItemLedgEntry.FilterReservFor(ReservationEntries, ReservationsEntry);
        if ReservationEntries.FindFirst() then;
        Error(
          Text029,
          ReservationsEntry.FieldCaption("Applies-to Entry"),
          ApplicationEntry,
          Item.FieldCaption("No."),
          ItemNo,
          ReservEngineMgt.CreateForText(ReservationEntries));
    end;

    local procedure CorrectOutputValuationDate(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        TempValueEntry: Record "Value Entry" temporary;
        ValuationDate: Date;
        ShouldExit: Boolean;
    begin
        OnCorrectOutputValuationDateOnCheckProduction(ItemLedgerEntry, TempValueEntry, ValuationDate, ShouldExit);
        if ShouldExit then
            exit;

        UpdateOutputEntryAndChain(TempValueEntry, ValuationDate);
    end;

    local procedure UpdateOutputEntryAndChain(var TempValueEntry: Record "Value Entry" temporary; ValuationDate: Date)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntryNo: Integer;
    begin
        TempValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type");
        if TempValueEntry.Find('-') then
            repeat
                ValueEntry.Get(TempValueEntry."Entry No.");
                if ValueEntry."Valuation Date" < ValuationDate then begin
                    if ItemLedgerEntryNo <> TempValueEntry."Item Ledger Entry No." then begin
                        ItemLedgerEntryNo := TempValueEntry."Item Ledger Entry No.";
                        UpdateLinkedValuationDate(ValuationDate, ItemLedgerEntryNo, true);
                    end;

                    ValueEntry."Valuation Date" := ValuationDate;
                    ValueEntry.Modify();
                    if ValueEntry."Entry No." = DirCostValueEntry."Entry No." then
                        DirCostValueEntry := ValueEntry;
                end;
            until TempValueEntry.Next() = 0;
    end;

    local procedure GetSourceNo(ItemJnlLine: Record "Item Journal Line") Result: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceNo(ItemJnlLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ItemJnlLine."Job No." = '' then
            if ItemJnlLine."Invoice-to Source No." <> '' then
                exit(ItemJnlLine."Invoice-to Source No.");
        exit(ItemJnlLine."Source No.");
    end;

    local procedure PostAssemblyResourceConsump()
    var
        CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry";
        DirCostAmt: Decimal;
        IndirCostAmt: Decimal;
    begin
        InsertCapLedgEntry(ItemJnlLine, CapLedgEntry, ItemJnlLine.Quantity, ItemJnlLine.Quantity);
        CalcDirAndIndirCostAmts(DirCostAmt, IndirCostAmt, ItemJnlLine.Quantity, ItemJnlLine);

        InsertCapValueEntry(ItemJnlLine, CapLedgEntry, ItemJnlLine."Value Entry Type"::"Direct Cost", ItemJnlLine.Quantity, ItemJnlLine.Quantity, DirCostAmt);
        InsertCapValueEntry(ItemJnlLine, CapLedgEntry, ItemJnlLine."Value Entry Type"::"Indirect Cost", ItemJnlLine.Quantity, 0, IndirCostAmt);
    end;

    local procedure InsertAsmItemEntryRelation(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        GetItem(ItemLedgerEntry."Item No.", true);
        if Item."Item Tracking Code" <> '' then begin
            TempItemEntryRelation."Item Entry No." := ItemLedgerEntry."Entry No.";
            TempItemEntryRelation.CopyTrackingFromItemLedgEntry(ItemLedgerEntry);
            OnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, ItemLedgerEntry);
            TempItemEntryRelation.Insert();
        end;
    end;

    local procedure TransReserveFromJobPlanningLine(FromJobContractEntryNo: Integer; ToItemJnlLine: Record "Item Journal Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", FromJobContractEntryNo);
        JobPlanningLine.FindFirst();

        TempJobPlanningLine := JobPlanningLine;
        if not TempJobPlanningLine.Insert() then
            TempJobPlanningLine.Find();

        if TempJobPlanningLine."Remaining Qty. (Base)" >= ToItemJnlLine."Quantity (Base)" then
            TempJobPlanningLine."Remaining Qty. (Base)" := TempJobPlanningLine."Remaining Qty. (Base)" - ToItemJnlLine."Quantity (Base)"
        else
            TempJobPlanningLine."Remaining Qty. (Base)" := 0;
        TempJobPlanningLine.Modify();
        JobPlanningLineReserve.TransferJobLineToItemJnlLine(TempJobPlanningLine, ToItemJnlLine, ToItemJnlLine."Quantity (Base)");
    end;

    /// <summary>
    /// Splits a journal line based on the current global tracking specification line and stores it into a global buffer.
    /// </summary>
    /// <param name="ItemJnlLine2">Item journal line to split.</param>
    /// <param name="SignFactor">Sign factor to multiply all amounts with.</param>
    /// <param name="NonDistrQuantity">Total quantity used for determining the splitting factor.</param>
    /// <param name="NonDistrAmount">Total amount to split and set.</param>
    /// <param name="NonDistrAmountACY">Total Amount (ACY) to split and set.</param>
    /// <param name="NonDistrDiscountAmount">Discount amount to split and set.</param>
    /// <param name="Invoice">Indicates if journal line was already invoiced.</param>
    /// <returns>True if created split item journal line needs to be posted, otherwise false.</returns>
    procedure SetupTempSplitItemJnlLine(ItemJnlLine2: Record "Item Journal Line"; SignFactor: Integer; var NonDistrQuantity: Decimal; var NonDistrAmount: Decimal; var NonDistrAmountACY: Decimal; var NonDistrDiscountAmount: Decimal; Invoice: Boolean): Boolean
    var
        FloatingFactor: Decimal;
        PostItemJnlLine: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeSetupTempSplitItemJnlLine(ItemJnlLine2, SignFactor, NonDistrQuantity, NonDistrAmount, NonDistrAmountACY, NonDistrDiscountAmount, Invoice, IsHandled);
        if isHandled then
            exit;
        TempSplitItemJnlLine."Quantity (Base)" := SignFactor * TempTrackingSpecification."Qty. to Handle (Base)";
        TempSplitItemJnlLine.Quantity := SignFactor * TempTrackingSpecification."Qty. to Handle";
        if Invoice then begin
            TempSplitItemJnlLine."Invoiced Quantity" := SignFactor * TempTrackingSpecification."Qty. to Invoice";
            TempSplitItemJnlLine."Invoiced Qty. (Base)" := SignFactor * TempTrackingSpecification."Qty. to Invoice (Base)";
        end;

        if ItemJnlLine2."Phys. Inventory" then
            TempSplitItemJnlLine."Qty. (Phys. Inventory)" := TempSplitItemJnlLine."Qty. (Calculated)" + SignFactor * TempSplitItemJnlLine."Quantity (Base)";

        OnAfterSetupTempSplitItemJnlLineSetQty(TempSplitItemJnlLine, ItemJnlLine2, SignFactor, TempTrackingSpecification);

        FloatingFactor := TempSplitItemJnlLine.Quantity / NonDistrQuantity;
        if FloatingFactor < 1 then begin
            TempSplitItemJnlLine.Amount := Round(NonDistrAmount * FloatingFactor, GLSetup."Amount Rounding Precision");
            TempSplitItemJnlLine."Amount (ACY)" := Round(NonDistrAmountACY * FloatingFactor, Currency."Amount Rounding Precision");
            TempSplitItemJnlLine."Discount Amount" := Round(NonDistrDiscountAmount * FloatingFactor, GLSetup."Amount Rounding Precision");
            NonDistrAmount := NonDistrAmount - TempSplitItemJnlLine.Amount;
            NonDistrAmountACY := NonDistrAmountACY - TempSplitItemJnlLine."Amount (ACY)";
            NonDistrDiscountAmount := NonDistrDiscountAmount - TempSplitItemJnlLine."Discount Amount";
            NonDistrQuantity := NonDistrQuantity - TempSplitItemJnlLine.Quantity;
            OnSetupTempSplitItemJnlLineOnAfterDeductNonDistr(TempSplitItemJnlLine);
        end else begin
            // the last record
            TempSplitItemJnlLine.Amount := NonDistrAmount;
            TempSplitItemJnlLine."Amount (ACY)" := NonDistrAmountACY;
            TempSplitItemJnlLine."Discount Amount" := NonDistrDiscountAmount;
        end;

        if Round(TempSplitItemJnlLine."Unit Amount" * TempSplitItemJnlLine.Quantity, GLSetup."Amount Rounding Precision") <> TempSplitItemJnlLine.Amount then
            if (TempSplitItemJnlLine."Unit Amount" = TempSplitItemJnlLine."Unit Cost") and (TempSplitItemJnlLine."Unit Cost" <> 0) then begin
                TempSplitItemJnlLine."Unit Amount" := Round(TempSplitItemJnlLine.Amount / TempSplitItemJnlLine.Quantity, 0.00001);
                TempSplitItemJnlLine."Unit Cost" := Round(TempSplitItemJnlLine.Amount / TempSplitItemJnlLine.Quantity, 0.00001);
                TempSplitItemJnlLine."Unit Cost (ACY)" := Round(TempSplitItemJnlLine."Amount (ACY)" / TempSplitItemJnlLine.Quantity, 0.00001);
            end else
                TempSplitItemJnlLine."Unit Amount" := Round(TempSplitItemJnlLine.Amount / TempSplitItemJnlLine.Quantity, 0.00001);

        TempSplitItemJnlLine.CopyTrackingFromSpec(TempTrackingSpecification);
        TempSplitItemJnlLine."Item Expiration Date" := TempTrackingSpecification."Expiration Date";
        TempSplitItemJnlLine.CopyNewTrackingFromNewSpec(TempTrackingSpecification);
        TempSplitItemJnlLine."New Item Expiration Date" := TempTrackingSpecification."New Expiration Date";

        OnSetupTempSplitItemJnlLineOnBeforeCalcPostItemJnlLine(TempSplitItemJnlLine, TempTrackingSpecification);
        PostItemJnlLine := not TempSplitItemJnlLine.HasSameNewTracking() or (TempSplitItemJnlLine."Item Expiration Date" <> TempSplitItemJnlLine."New Item Expiration Date");
        OnSetupTempSplitItemJnlLineOnAfterCalcPostItemJnlLine(TempSplitItemJnlLine, TempTrackingSpecification, PostItemJnlLine);

        TempSplitItemJnlLine."Warranty Date" := TempTrackingSpecification."Warranty Date";

        TempSplitItemJnlLine."Line No." := TempTrackingSpecification."Entry No.";

        if TempTrackingSpecification.Correction or TempSplitItemJnlLine."Drop Shipment" or IsServUndoConsumption then
            TempSplitItemJnlLine."Applies-to Entry" := TempTrackingSpecification."Item Ledger Entry No."
        else
            TempSplitItemJnlLine."Applies-to Entry" := TempTrackingSpecification."Appl.-to Item Entry";
        TempSplitItemJnlLine."Applies-from Entry" := TempTrackingSpecification."Appl.-from Item Entry";

        OnBeforeInsertSetupTempSplitItemJnlLine(TempTrackingSpecification, TempSplitItemJnlLine, PostItemJnlLine, ItemJnlLine2, SignFactor, FloatingFactor);

        TempSplitItemJnlLine.Insert();

        exit(PostItemJnlLine);
    end;

    local procedure PostInvtBuffer(var ValueEntry: Record "Value Entry")
    begin
        if InventoryPostingToGL.BufferInvtPosting(ValueEntry) then begin
            OnPostInvtBufferOnAfterBufferInvtPosting(ValueEntry);
            GetInvtSetup();
            GetGLSetup();
            if GLSetup."Journal Templ. Name Mandatory" then
                InventoryPostingToGL.SetGenJnlBatch(
                    InvtSetup."Invt. Cost Jnl. Template Name", InvtSetup."Invt. Cost Jnl. Batch Name");
            InventoryPostingToGL.PostInvtPostBufPerEntry(ValueEntry);
        end;
    end;

    local procedure VerifyTouchedOnInventory()
    var
        ItemLedgEntryApplied: Record "Item Ledger Entry";
    begin
        TempTouchedItemLedgerEntries.FindSet();
        repeat
            ItemLedgEntryApplied.Get(TempTouchedItemLedgerEntries."Entry No.");
            ItemLedgEntryApplied.VerifyOnInventory(
                StrSubstNo(CannotUnapplyItemLedgEntryErr, ItemLedgEntryApplied."Item No.", ItemLedgEntryApplied."Entry No."));
        until TempTouchedItemLedgerEntries.Next() = 0;
    end;

    local procedure CheckIsCyclicalLoop(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; var PrevAppliedItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    var
        PrevProcessedProdOrder: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry, PrevAppliedItemLedgEntry, AppliedQty, IsHandled);
        if IsHandled then
            exit;

        PrevProcessedProdOrder :=
          (ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Consumption) and
          (OldItemLedgEntry."Entry Type" = OldItemLedgEntry."Entry Type"::Output) and
          (ItemLedgEntry."Order Type" = ItemLedgEntry."Order Type"::Production) and
          EntriesInTheSameOrder(OldItemLedgEntry, PrevAppliedItemLedgEntry);

        if not PrevProcessedProdOrder then
            if AppliedQty <> 0 then
                if ItemLedgEntry.Positive then begin
                    if ItemApplnEntry.CheckIsCyclicalLoop(ItemLedgEntry, OldItemLedgEntry) then
                        AppliedQty := 0;
                end else
                    if ItemApplnEntry.CheckIsCyclicalLoop(OldItemLedgEntry, ItemLedgEntry) then
                        AppliedQty := 0;

        if AppliedQty <> 0 then
            PrevAppliedItemLedgEntry := OldItemLedgEntry;
    end;

    local procedure EntriesInTheSameOrder(OldItemLedgEntry: Record "Item Ledger Entry"; PrevAppliedItemLedgEntry: Record "Item Ledger Entry"): Boolean
    begin
        exit(
          (PrevAppliedItemLedgEntry."Order Type" = PrevAppliedItemLedgEntry."Order Type"::Production) and
          (OldItemLedgEntry."Order Type" = OldItemLedgEntry."Order Type"::Production) and
          (OldItemLedgEntry."Order No." = PrevAppliedItemLedgEntry."Order No.") and
          (OldItemLedgEntry."Order Line No." = PrevAppliedItemLedgEntry."Order Line No."));
    end;

    local procedure MustConsiderUnitCostRoundingOnRevaluation(ItemJournalLine: Record "Item Journal Line"): Boolean
    begin
        exit(
          (ItemJournalLine."Value Entry Type" = ItemJournalLine."Value Entry Type"::Revaluation) and
          (GetItem(ItemJournalLine."Item No.", false) and (Item."Costing Method" = Item."Costing Method"::Average) or
           (ItemJournalLine."Applies-to Entry" <> 0)));
    end;

    local procedure UpdateAppliedQtyIfConsumptionEntry(ItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"): Decimal
    begin
        if ItemLedgerEntry."Entry Type" <> ItemLedgerEntry."Entry Type"::Consumption then
            exit(0);

        if (ItemLedgerEntry."Remaining Quantity" + OldItemLedgerEntry."Remaining Quantity") > 0 then
            exit(0);

        exit(GetUpdatedAppliedQtyForConsumption(OldItemLedgerEntry, ItemLedgerEntry));
    end;

    procedure RunOnPublishPostingInventoryToGL()
    begin
        OnPublishPostingInventoryToGL(ItemJnlLine, InventoryPostingToGL);
    end;

    local procedure CheckIfReservationEntryForJobExist(): Boolean
    var
        JobPlanningLine: Record "Job Planning Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        JobPlanningLine.SetCurrentKey("Job Contract Entry No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", ItemJnlLine."Job Contract Entry No.");
        if not JobPlanningLine.FindFirst() then
            exit(false);

        exit(JobPlanningLineReserve.FindReservEntry(JobPlanningLine, ReservationEntry));
    end;

    local procedure GetUpdatedAppliedQtyForConsumption(OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry") AppliedQty: Decimal
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationEntry2: Record "Reservation Entry";
        SourceType: Integer;
    begin
        if OldItemLedgerEntry."Reserved Quantity" = 0 then
            exit(0);

        ReservationEntry.SetLoadFields("Entry No.", Positive, "Source Type", "Source Ref. No.");
        ReservationEntry.SetRange("Source Type", Database::"Item Ledger Entry");
        ReservationEntry.SetRange("Source Ref. No.", OldItemLedgerEntry."Entry No.");
        if ReservationEntry.FindFirst() then
            if ReservationEntry2.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive) then
                SourceType := ReservationEntry2."Source Type";

        case SourceType of
            Database::"Sales Line":
                AppliedQty := -Abs(OldItemLedgerEntry."Remaining Quantity" - OldItemLedgerEntry."Reserved Quantity");
            else
                AppliedQty := -Abs(OldItemLedgerEntry."Reserved Quantity");
        end;

        OnAfterGetUpdatedAppliedQtyForConsumption(OldItemLedgerEntry, ItemLedgerEntry, ReservationEntry2, SourceType, AppliedQty);
    end;

    procedure PostDeferredValueEntriesToGL(PostponedValueEntries: List of [Integer])
    var
        ValueEntry: Record "Value Entry";
        ValueEntryUpdate: Record "Value Entry";
        Window: Dialog;
        EntryNo: Integer;
        FromEntryNo: Integer;
        ToEntryNo: Integer;
    begin
        if PostponedValueEntries.Count = 0 then
            exit;
        if GuiAllowed then
            Window.Open(PostToGlLbl);
        FromEntryNo := 2100000000;
        ToEntryNo := -2100000000;
        // to find the range of postponed value entries
        foreach EntryNo in PostponedValueEntries do begin
            if EntryNo < FromEntryNo then
                FromEntryNo := EntryNo;
            if EntryNo > ToEntryNo then
                ToEntryNo := EntryNo;
        end;

        ValueEntryUpdate.ReadIsolation(IsolationLevel::UpdLock);
        ValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);  // we already locked the ones we need to update
        ValueEntry.SetRange("Entry No.", FromEntryNo, ToEntryNo);
        EntryNo := 0;
        if ValueEntry.FindSet() then
            repeat
                if PostponedValueEntries.Contains(ValueEntry."Entry No.") then begin
                    PostponedValueEntries.Remove(ValueEntry."Entry No.");
                    EntryNo += 1;
                    if GuiAllowed then
                        Window.Update(1, EntryNo);
                    ValueEntryUpdate := ValueEntry;
                    PostValueEntryToGL(ValueEntryUpdate);
                    ValueEntryUpdate.Modify();
                end;
            until ValueEntry.Next() = 0;
        if GuiAllowed then
            Window.Close();
    end;

    local procedure IsNondeductibleAndUseItemCost(): Boolean
    var
        VATSetup: Record "VAT Setup";
    begin
        if (VATSetup.Get()) and (VATSetup."Enable Non-Deductible VAT") and
           (VATSetup."Use For Item Cost") and
           (Item."Costing Method" <> Item."Costing Method"::Standard) and
           (ItemJnlLine."Value Entry Type" = ItemJnlLine."Value Entry Type"::"Direct Cost") and
           (ItemJnlLine."Item Charge No." = '') and
           (ItemJnlLine."Applies-from Entry" = 0) and
           not ItemJnlLine.Adjustment and (ItemJnlLine."Document Type" <> ItemJnlLine."Document Type"::"Inventory Receipt") then
            exit(true);

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAllowProdApplication(OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; var AllowApplication: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyItemLedgEntry(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; CausedByTransfer: Boolean; var Handled: Boolean; ItemJnlLine: Record "Item Journal Line"; var ItemApplnEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyItemLedgEntrySetFilters(var ToItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckApplication(ItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExpirationDate(var ItemJournalLine: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; SignFactor: Integer; CalcExpirationDate: Date; var ExpirationDateChecked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLotNoInfoNotBlocked(var ItemJnlLine2: Record "Item Journal Line"; var IsHandled: Boolean; var ItemTrackingSetup: Record "Item Tracking Setup"; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemCorrection(ItemLedgerEntry: Record "Item Ledger Entry"; var RaiseError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTracking(var ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingInformation(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; var ItemTrackingSetup: Record "Item Tracking Setup"; var SignFactor: Decimal; var ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean; var GlobalItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAppliedEntriesToReadjust(ItemLedgEntry: Record "Item Ledger Entry"; var Readjust: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAdjustedCost(var ItemJournalLine: Record "Item Journal Line"; var AdjustedCostLCY: Decimal; var AdjustedCostACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTracking(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup"; GlobalItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTrackingInformation(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitCorrItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; EntriesExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfItemIsBlocked(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckRunItemValuePosting(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJnlLineFromEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTempSplitItemJnlLine(var TempSplitItemJournalLine: Record "Item Journal Line" temporary; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertApplEntry(var ItemLedgEntryNo: Integer; var InboundItemEntry: Integer; var OutboundItemEntry: Integer; var TransferedFromEntryNo: Integer; var PostingDate: Date; var Quantity: Decimal; var CostToApply: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransferEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterFlushOperation(var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ItemJnlLine: Record "Item Journal Line");
    begin
        OnAfterFlushOperation(ProdOrder, ProdOrderLine, ItemJnlLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFlushOperation(var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ItemJnlLine: Record "Item Journal Line");
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItem(var Item: Record Item; ItemNo: Code[20]; Unconditionally: Boolean; var HasGotItem: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemVariant(var ItemVariant: Record "Item Variant"; ItemNo: Code[20]; VariantCode: Code[10]; Unconditionally: Boolean; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceNo(ItemJournalLine: Record "Item Journal Line"; var Result: Code[20]; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterPostFlushedConsump(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line")
    begin
        OnAfterPostFlushedConsump(ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostFlushedConsump(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnAfterPostConsumption(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ItemJnlLine2: Record "Item Journal Line");
    begin
        OnAfterPostConsumption(ProdOrderComp, ItemJnlLine2);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostConsumption(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line");
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPhysInvtLedgEntry(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; LastSplitItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitItemLedgEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer; GlobalValueEntry: Record "Value Entry"; TransferItem: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; TransferItem: Boolean; OldItemLedgEntry: Record "Item Ledger Entry"; ItemJournalLineOrigin: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertItemLedgEntryProcedure(var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertValueEntry(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertValueEntry(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; CalledFromAdjustment: Boolean; var OldItemLedgEntry: Record "Item Ledger Entry"; var Item: Record Item; TransferItem: Boolean; var GlobalValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertValueEntryProcedure(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitValueEntry(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; var ValueEntryNo: Integer; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCapLedgEntry(var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCapLedgEntry(var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; LastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCapValueEntry(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCapValueEntryProcedure(ItemJournalLine: Record "Item Journal Line"; ValueEntryType: Enum "Cost Entry Type"; var ValuedQty: Decimal; var InvdQty: Decimal; var AdjdCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCapValueEntry(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCorrItemLedgEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCorrItemLedgEntry(var NewItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCorrValueEntry(var NewValueEntry: Record "Value Entry"; OldValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; Sign: Integer; CalledFromAdjustment: Boolean; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertCorrValueEntry(var NewValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeInsertConsumpEntry(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; QtyBase: Decimal; var ModifyProdOrderComp: Boolean; var ItemJnlLine: Record "Item Journal Line"; var TempSplitItemJnlLine: Record "Item Journal Line" temporary)
    begin
        OnBeforeInsertConsumpEntry(ProdOrderComponent, QtyBase, ModifyProdOrderComp, ItemJnlLine, TempSplitItemJnlLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertConsumpEntry(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; QtyBase: Decimal; var ModifyProdOrderComp: Boolean; var ItemJnlLine: Record "Item Journal Line"; var TempSplitItemJnlLine: Record "Item Journal Line" temporary)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemApplnEntryInsert(var ItemApplicationEntry: Record "Item Application Entry"; GlobalItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterItemQtyPosting(ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemApplnEntryInsert(var ItemApplicationEntry: Record "Item Application Entry"; GlobalItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemApplnEntryNo: Integer)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeNextOperationExist(var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line")
    begin
        OnBeforeNextOperationExist(ProdOrderRoutingLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeNextOperationExist(var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItem(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean; var ItemRegister: Record "Item Register"; var ItemLedgEntryNo: Integer; var ValueEntryNo: Integer; var ItemApplnEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetValueEntrySourceFieldsFromItemJnlLine(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean; var ItemRegister: Record "Item Register"; var ItemLedgEntryNo: Integer; var ItemApplnEntryNo: Integer; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterPostOutput(var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
        OnAfterPostOutput(ItemLedgerEntry, ProdOrderLine, ItemJournalLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterPostOutput(var ItemLedgerEntry: Record "Item Ledger Entry"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputOnBeforeProdOrderRtngLineModify(var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; var LastOperation: Boolean)
    begin
        OnPostOutputOnBeforeProdOrderRtngLineModify(ProdOrderRoutingLine, ProdOrderLine, ItemJournalLine, LastOperation);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeProdOrderRtngLineModify(var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; var LastOperation: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputOnAfterProdOrderRtngLineSetFilters(var ProdOrderRtngLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line")
    begin
        OnPostOutputOnAfterProdOrderRtngLineSetFilters(ProdOrderRtngLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterProdOrderRtngLineSetFilters(var ProdOrderRtngLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCheckPostingCostToGL(var PostCostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckExpirationDateOnBeforeTestFieldExpirationDate(var TempTrackingSpecification: Record "Tracking Specification" temporary; var EntriesExist: Boolean; var ExistingExpirationDate: Date);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSetupTempSplitItemJnlLine(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempItemJournalLine: Record "Item Journal Line" temporary; var PostItemJnlLine: Boolean; var ItemJournalLine2: Record "Item Journal Line"; SignFactor: Integer; FloatingFactor: Decimal)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeFlushOperation(var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ItemJnlLine: Record "Item Journal Line"; LastOperation: Boolean);
    begin
        OnBeforeFlushOperation(ProdOrder, ProdOrderLine, ItemJnlLine, LastOperation);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(true, false)]
    local procedure OnBeforeFlushOperation(var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ItemJnlLine: Record "Item Journal Line"; LastOperation: Boolean);
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforePostFlushedConsumpItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        OnBeforePostFlushedConsumpItemJnlLine(ItemJournalLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFlushedConsumpItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOldItemLedgerEntryRemainingQuantity(var OldItemLedgerEntry: Record "Item Ledger Entry"; AppliedQuantity: Decimal; var GlobalItemLedgEntry: Record "Item Ledger Entry"; var AverageTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateItemLedgerEntryRemainingQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"; AppliedQuantity: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterItemValuePosting(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeSplitTempLines(var TempSplitItemJournalLine: Record "Item Journal Line" temporary; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnAfterCheckExpirationDate(var ItemJnlLine2: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeCheckUseExpirationDates(var ItemJnlLine2: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; Item: Record Item; var CalcExpirationDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnAfterGetItemTrackingSetup(ItemTrackingCode: Record "Item Tracking Code"; ItemJnlLine: Record "Item Journal Line"; var ItemTrackingSetup: Record "Item Tracking Setup"; GlobalItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeGetItemTrackingSetup(var ItemJnlLine2: Record "Item Journal Line"; TrackingSpecExists: Boolean; CalledFromAdjustment: Boolean; var Item: Record Item; var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [InternalEvent(false)]
    local procedure OnSetupSplitJnlLineOnSetDisableItemTracking(var ItemJournalLine: Record "Item Journal Line"; var DisableItemTracking: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnSetupSplitJnlLineOnCheckOperationNo(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnAfterSetupTempSplitItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var TempSplitItemJournalLine: Record "Item Journal Line" temporary; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcExpectedCost(var ValueEntry: Record "Value Entry"; ItemLedgerEntryNo: Integer; var ExpectedCost: Decimal; var ExpectedCostACY: Decimal; var ExpectedSalesAmt: Decimal; var ExpectedPurchAmt: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPurchCorrShares(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; var OverheadAmount: Decimal; var OverheadAmountACY: Decimal; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPosShares(var ItemJournalLine: Record "Item Journal Line"; var DirCost: Decimal; var OvhdCost: Decimal; var PurchVar: Decimal; var DirCostACY: Decimal; var OvhdCostACY: Decimal; var PurchVarACY: Decimal; var CalcUnitCost: Boolean; CalcPurchVar: Boolean; Expected: Boolean; GlobalItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertOHValueEntry(var ValueEntry: Record "Value Entry"; var Item: Record Item; var OverheadAmount: Decimal; var OverheadAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupTempSplitItemJnlLineSetQty(var TempSplitItemJnlLine: Record "Item Journal Line" temporary; ItemJournalLine: Record "Item Journal Line"; SignFactor: Integer; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAdjmtProp(var ValueEntry: Record "Value Entry"; OriginalPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCost(ValueEntry: Record "Value Entry"; LastDirectCost: Decimal; ItemJournalLine: Record "Item Journal Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDirAndIndirCostAmts(var ItemJournalLine: Record "Item Journal Line"; var DirCostAmt: Decimal; var IndirCostAmt: Decimal; CapQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcExpirationDate(var ItemJnlLine: Record "Item Journal Line"; var ExpirationDate: Date; var IsHandled: Boolean; Item: Record Item)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeCallFlushOperation(var ItemJnlLine2: Record "Item Journal Line"; var ShouldFlushOperation: Boolean);
    begin
        OnBeforeCallFlushOperation(ItemJnlLine2, ShouldFlushOperation);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallFlushOperation(var ItemJnlLine: Record "Item Journal Line"; var ShouldFlushOperation: Boolean);
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNo(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemTrackingIsEmpty(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIsCyclicalLoop(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; var PrevAppliedItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforePostFlushedConsump(ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean);
    begin
        OnBeforePostFlushedConsump(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFlushedConsump(ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean);
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInitValueEntry(var ValueEntry: Record "Value Entry"; var ValueEntryNo: Integer; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOHValueEntry(var ValueEntry: Record "Value Entry"; var Item: Record Item; var OverheadAmount: Decimal; var OverheadAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertVarValueEntry(var ValueEntry: Record "Value Entry"; var Item: Record Item; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempSplitItemJnlLine(ItemJournalLine: Record "Item Journal Line"; IsServUndoConsumption: Boolean; PostponeReservationHandling: Boolean; var TempSplitItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; var PostItemJnlLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMoveApplication(var ItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOldItemLedgEntryModify(var OldItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLineByEntryType(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeProdOrderCompModify(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ItemJournalLine: Record "Item Journal Line")
    begin
        OnBeforeProdOrderCompModify(ProdOrderComponent, ItemJournalLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderCompModify(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeProdOrderLineModify(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ItemJournalLine: Record "Item Journal Line"; ItemLedgEntryNo: Integer)
    begin
        OnBeforeProdOrderLineModify(ProdOrderLine, ItemJournalLine, ItemLedgEntryNo);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderLineModify(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ItemJournalLine: Record "Item Journal Line"; ItemLedgEntryNo: Integer)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundAmtValueEntry(var ValueEntry: Record "Value Entry"; Currency: Record Currency; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveCostPerUnit(ItemJournalLine: Record "Item Journal Line"; SKU: Record "Stockkeeping Unit"; SKUExists: Boolean; var UnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRunWithCheck(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean; CalledFromInvtPutawayPick: Boolean; CalledFromApplicationWorksheet: Boolean; PostponeReservationHandling: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempItemEntryRelationInsert(var TempItemEntryRelation: Record "Item Entry Relation" temporary; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestFirstApplyItemLedgEntry(var OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTrackingSpecificationMissingErr(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetOrderAdjmtProperties(ItemLedgEntryType: Option; OrderType: Option; OrderNo: Code[20]; OrderLineNo: Integer; OriginalPostingDate: Date; ValuationDate: Date; var IsHandled: Boolean; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupSplitJnlLine(var ItemJnlLine2: Record "Item Journal Line"; var TrackingSpecExists: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

#if not CLEAN28
    [Obsolete('This event is no longer used.', '28.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyInvoicedQty(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; ValueEntry: Record "Value Entry")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyItemJnlLineAsembleToOrder(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUndoQuantityPosting(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeUpdateProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; ReTrack: Boolean)
    begin
        OnBeforeUpdateProdOrderLine(ProdOrderLine, ItemJournalLine, ReTrack);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ItemJournalLine: Record "Item Journal Line"; ReTrack: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateItemLedgerEntryRemainingQuantity(var ItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; AppliedQty: Decimal; CausedByTransfer: Boolean; AverageTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnAfterCloseReservEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeCloseReservEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeStartApplication(var ItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var StartApplication: Boolean; var AppliedQty: Decimal; var Item: Record Item; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyItemLedgEntrySetFilters(var ItemLedgerEntry2: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyItemLedgEntryOnBeforeCalcAppliedQty(var OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveValEntryDimToValEntryDim(var ToValueEntry: Record "Value Entry"; FromValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertTransferEntry(var ItemJournalLine: Record "Item Journal Line"; NewItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; NewValueEntry: Record "Value Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostItem(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostSplitJnlLine(var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareItem(var ItemJnlLineToPost: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUndoQuantityPosting(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterUpdateProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ReTrack: Boolean; var ItemJournalLine: Record "Item Journal Line")
    begin
        OnAfterUpdateProdOrderLine(ProdOrderLine, ReTrack, ItemJournalLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ReTrack: Boolean; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnAfterInsertConsumpEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; QtyBase: Decimal; PostWhseJnlLine: Boolean; var ItemJnlLine: Record "Item Journal Line"; ItemLedgEntryNo: Integer)
    begin
        OnAfterInsertConsumpEntry(WarehouseJournalLine, ProdOrderComponent, QtyBase, PostWhseJnlLine, ItemJnlLine, ItemLedgEntryNo);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertConsumpEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; QtyBase: Decimal; PostWhseJnlLine: Boolean; var ItemJnlLine: Record "Item Journal Line"; ItemLedgEntryNo: Integer)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnApplyCapNeedOnAfterSetFilters(var ProdOrderCapNeed: Record Microsoft.Manufacturing.Document."Prod. Order Capacity Need"; ItemJnlLine: Record "Item Journal Line");
    begin
        OnApplyCapNeedOnAfterSetFilters(ProdOrderCapNeed, ItemJnlLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnApplyCapNeedOnAfterSetFilters(var ProdOrderCapNeed: Record Microsoft.Manufacturing.Document."Prod. Order Capacity Need"; ItemJnlLine: Record "Item Journal Line");
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnAfterCalcAppliedQty(OldItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnAfterSetAppliedQtyZero(OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemLedgerEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeCheckApplyEntry(var OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeInsertApplEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var OldItemLedgEntry: Record "Item Ledger Entry"; var GlobalItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeOldItemLedgEntryModify(var ItemLedgerEntry: Record "Item Ledger Entry"; var OldItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var AverageTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCollectTrackingSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TargetTrackingSpecification: Record "Tracking Specification" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcExpectedCostOnBeforeFindValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer; InvoicedQty: Decimal; Quantity: Decimal; var ExpectedCost: Decimal; var ExpectedCostACY: Decimal; var ExpectedSalesAmt: Decimal; var ExpectedPurchAmt: Decimal; CalcReminder: Boolean; var InvdValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcILEExpectedAmountOnBeforeCalcCostAmounts(var OldValueEntry2: Record "Value Entry"; var OldValueEntry: Record "Value Entry"; ItemLedgEntryNo: Integer)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnCorrectOutputValuationDateOnBeforeCheckProdOrder(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
        OnCorrectOutputValuationDateOnBeforeCheckProdOrder(ItemLedgerEntry, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCorrectOutputValuationDateOnBeforeCheckProdOrder(ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnFlushOperationOnAfterProdOrderCompSetFilters(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; OldItemJournalLine: Record "Item Journal Line"; var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line")
    begin
        OnFlushOperationOnAfterProdOrderCompSetFilters(ProdOrderComponent, OldItemJournalLine, ProdOrderRoutingLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFlushOperationOnAfterProdOrderCompSetFilters(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; OldItemJournalLine: Record "Item Journal Line"; var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnFlushOperationOnBeforeCheckRoutingLinkCode(var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var ItemJournalLine: Record "Item Journal Line"; LastOperation: Boolean)
    begin
        OnFlushOperationOnBeforeCheckRoutingLinkCode(ProductionOrder, ProdOrderLine, ProdOrderRoutingLine, ItemJournalLine, LastOperation);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(true, false)]
    local procedure OnFlushOperationOnBeforeCheckRoutingLinkCode(var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var ItemJournalLine: Record "Item Journal Line"; LastOperation: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetValuationDateOnAfterOldValueEntrySetFilters(var OldValueEntry: Record "Value Entry"; ValueEntry: Record "Value Entry"; OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetValuationDateOnBeforeFindOldValueEntry(var OldValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTransValueEntryOnAfterInitValueEntry(var ValueEntry: Record "Value Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterNotAdjustmentCheckClearCostAmount(var ValueEntry: Record "Value Entry"; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterSetValueEntryInventoriable(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnBeforeRoundAmtValueEntry(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterAssignFields(var ValueEntry: Record "Value Entry"; ItemLedgEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterCalcInvoicedQuantityNotEmpty(var ItemJournalLine: Record "Item Journal Line"; var InvoicedQuantityNotEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnAfterCalcDirestCost(var CostAmt: Decimal; var VarianceAmount: Decimal; Item: Record Item; ItemJournalLine: Record "Item Journal Line"; ValueEntry: Record "Value Entry"; var CostAmtACY: Decimal; var VarianceAmountACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPostValueEntryToGLOnAfterTransferFields(var PostValueEntryToGL: Record "Post Value Entry to G/L"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransferEntryOnTransferValues(var NewItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var TempItemEntryRelation: Record "Item Entry Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCapValueEntryOnAfterUpdateCostAmounts(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnInsertConsumpEntryOnBeforePostItem(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; PostWhseJnlLine: Boolean; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        OnInsertConsumpEntryOnBeforePostItem(ItemJournalLine, ProdOrderComponent, PostWhseJnlLine, WarehouseJournalLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumpEntryOnBeforePostItem(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; PostWhseJnlLine: Boolean; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnInsertOHValueEntryOnBeforeInsertValueEntry(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean; var GlobalItemLedgEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnAfterCalcInsertItemLedgEntryNeeded(var ItemJournalLine: Record "Item Journal Line"; var InsertItemLedgEntryNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnBeforeApplyItemLedgEntry(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemValuePostingOnAfterInsertValueEntry(var ValueEntry: Record "Value Entry"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemValuePostingOnAfterCalcIsCostNotTracedDirectly(var ItemJnlLine: Record "Item Journal Line"; var IsCostNotTracedDirectly: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLedgEntryOnBeforeReservationError(var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLedgEntryOnBeforeSNQtyCheck(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemRegOnBeforeItemRegInsert(var ItemRegister: Record "Item Register"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValuateAppliedAvgEntryOnAfterSetCostPerUnit(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line"; InventorySetup: Record "Inventory Setup"; SKU: Record "Stockkeeping Unit"; SKUExists: Boolean; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValuateAppliedAvgEntryOnAfterUpdateCostAmounts(var ValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnPostFlushedConsumpOnAfterCalcQtyToPost(ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ActOutputQtyBase: Decimal; var QtyToPost: Decimal; var OldItemJournalLine: Record "Item Journal Line"; var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var CompItem: Record Item)
    begin
        OnPostFlushedConsumpOnAfterCalcQtyToPost(ProductionOrder, ProdOrderLine, ProdOrderComponent, ActOutputQtyBase, QtyToPost, OldItemJournalLine, ProdOrderRoutingLine, CompItem);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnAfterCalcQtyToPost(ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ActOutputQtyBase: Decimal; var QtyToPost: Decimal; var OldItemJournalLine: Record "Item Journal Line"; var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; var CompItem: Record Item)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostFlushedConsumpOnAfterCopyProdOrderFieldsToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var OldItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; CompItem: record Item)
    begin
        OnPostFlushedConsumpOnAfterCopyProdOrderFieldsToItemJnlLine(ItemJournalLine, OldItemJournalLine, ProdOrderLine, ProdOrderComponent, CompItem);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnAfterCopyProdOrderFieldsToItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; var OldItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; CompItem: record Item)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostFlushedConsumptionOnBeforeCalcQtyToPost(ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var OutputQtyBase: Decimal)
    begin
        OnPostFlushedConsumptionOnBeforeCalcQtyToPost(ProdOrder, ProdOrderLine, ProdOrderComp, ProdOrderRoutingLine, OldItemJnlLine, OutputQtyBase);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumptionOnBeforeCalcQtyToPost(ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var OutputQtyBase: Decimal)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostFlushedConsumpOnBeforeProdOrderCompReserveTransferPOCompToItemJnlLine(ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnPostFlushedConsumpOnBeforeProdOrderCompReserveTransferPOCompToItemJnlLine(ItemJournalLine, ProdOrderComponent);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnBeforeProdOrderCompReserveTransferPOCompToItemJnlLine(ItemJournalLine: Record "Item Journal Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostFlushedConsumpOnBeforeSetupSplitJnlLine(var ItemJournalLine: Record "Item Journal Line"; var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecExists: Boolean)
    begin
        OnPostFlushedConsumpOnBeforeSetupSplitJnlLine(ItemJournalLine, ProdOrder, ProdOrderLine, ProdOrderComp, TempTrackingSpecification, TrackingSpecExists);
    end;

    [Obsolete('Replaced by event OnPostFlushedConsumptionItemJnlLineOnBeforeSetupSplitJnlLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumpOnBeforeSetupSplitJnlLine(var ItemJournalLine: Record "Item Journal Line"; var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecExists: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumptionItemJnlLineOnBeforeSetupSplitJnlLine(var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecExists: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnPostFlushedConsumptionOnAfterSetDimensionSetID(ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        OnPostFlushedConsumptionOnAfterSetDimensionSetID(ItemJournalLine, ProdOrderLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumptionOnAfterSetDimensionSetID(ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostFlushedConsumptionItemJnlLineOnAfterSetDimensionSetID(ItemJournalLine: Record "Item Journal Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnPostConsumptionOnAfterInsertEntry(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnPostConsumptionOnAfterInsertEntry(ProdOrderComponent);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnAfterInsertEntry(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostConsumptionOnAfterFindProdOrderComp(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnPostConsumptionOnAfterFindProdOrderComp(ProdOrderComp);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnAfterFindProdOrderComp(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostConsumptionOnAfterCalcNewRemainingQty(ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var NewRemainingQuantity: Decimal; QtyToPost: Decimal)
    begin
        OnPostConsumptionOnAfterCalcNewRemainingQty(ProdOrderComponent, NewRemainingQuantity, QtyToPost);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnAfterCalcNewRemainingQty(ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var NewRemainingQuantity: Decimal; QtyToPost: Decimal)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostConsumptionOnBeforeCheckOrderType(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
        OnPostConsumptionOnBeforeCheckOrderType(ProdOrderComponent, ItemJournalLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeCheckOrderType(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostConsumptionOnBeforeFindSetProdOrderComp(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ItemJournalLine: Record "Item Journal Line")
    begin
        OnPostConsumptionOnBeforeFindSetProdOrderComp(ProdOrderComponent, ItemJournalLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeFindSetProdOrderComp(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnAfterGetSKU(var ItemJnlLine: Record "Item Journal Line"; var SKUExists: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeCheckInventoryPostingGroup(var ItemJnlLine: Record "Item Journal Line"; var CalledFromAdjustment: Boolean; var Item: Record Item; var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeUpdateUnitCost(var ItemJnlLine: Record "Item Journal Line"; GlobalItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnPostOutputOnAfterInsertCapLedgEntry(ItemJournalLine: Record "Item Journal Line"; var SkipPost: Boolean)
    begin
        OnPostOutputOnAfterInsertCapLedgEntry(ItemJournalLine, SkipPost);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterInsertCapLedgEntry(ItemJournalLine: Record "Item Journal Line"; var SkipPost: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputOnAfterInsertCostValueEntries(ItemJournalLine: Record "Item Journal Line"; var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; CalledFromAdjustment: Boolean; PostToGL: Boolean)
    begin
        OnPostOutputOnAfterInsertCostValueEntries(ItemJournalLine, CapLedgEntry, CalledFromAdjustment, PostToGL);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterInsertCostValueEntries(ItemJournalLine: Record "Item Journal Line"; var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; CalledFromAdjustment: Boolean; PostToGL: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputOnAfterSetMfgUnitCost(var ItemJournalLine: Record "Item Journal Line"; var MfgUnitCost: Decimal; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        OnPostOutputOnAfterSetMfgUnitCost(ItemJournalLine, MfgUnitCost, ProdOrderLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterSetMfgUnitCost(var ItemJournalLine: Record "Item Journal Line"; var MfgUnitCost: Decimal; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputOnAfterUpdateAmounts(var ItemJournalLine: Record "Item Journal Line")
    begin
        OnPostOutputOnAfterUpdateAmounts(ItemJournalLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterUpdateAmounts(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputOnAfterUpdateProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; var GlobalItemLedgEntry: Record "Item Ledger Entry");
    begin
        OnPostOutputOnAfterUpdateProdOrderLine(ItemJournalLine, WhseJnlLine, GlobalItemLedgEntry);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterUpdateProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; var WhseJnlLine: Record "Warehouse Journal Line"; var GlobalItemLedgEntry: Record "Item Ledger Entry");
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputOnBeforeUpdateProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
        OnPostOutputOnBeforeUpdateProdOrderLine(ItemJournalLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeUpdateProdOrderLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputOnAfterCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        OnPostOutputOnAfterCreateWhseJnlLine(ItemJournalLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnAfterCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputOnBeforeCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; var PostWhseJnlLine: Boolean)
    begin
        OnPostOutputOnBeforeCreateWhseJnlLine(ItemJournalLine, PostWhseJnlLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line"; var PostWhseJnlLine: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputOnBeforePostItem(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var IsHandled: Boolean)
    begin
        OnPostOutputOnBeforePostItem(ItemJournalLine, ProdOrderLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforePostItem(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostSplitJnlLineOnBeforeSplitJnlLine(var ItemJournalLine: Record "Item Journal Line"; var ItemJournalLineToPost: Record "Item Journal Line"; var PostItemJournalLine: Boolean; DisableItemTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReApplyOnBeforeStartApply(var ItemLedgerEntry: Record "Item Ledger Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReApplyOnBeforeGetItemTrackingSetup(var Item: Record Item; var ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetOrderAdjmtPropertiesOnBeforeSetCostIsAdjusted(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ModifyOrderAdjmt: Boolean; var IsHandled: Boolean; OriginalPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetOrderAdjmtPropertiesOnBeforeSetAllowOnlineAdjustment(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var ModifyOrderAdjmt: Boolean; var IsHandled: Boolean; OriginalPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeReallocateTrkgSpecification(var ItemTrackingCode: Record "Item Tracking Code"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemJnlLine: Record "Item Journal Line"; var SignFactor: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupSplitJnlLineOnBeforeCalcNonDistrQuantity(var TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemJournalLine: Record "Item Journal Line"; Invoice: Boolean; SignFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitItemJnlLineOnBeforeTracking(
        var ItemJnlLine2: Record "Item Journal Line"; var PostItemJnlLine: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary;
        var GlobalItemLedgEntry: Record "Item Ledger Entry"; var TempItemEntryRelation: Record "Item Entry Relation" temporary;
        var PostponeReservationHandling: Boolean; var SignFactor: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestFirstApplyItemLedgEntryOnAfterTestFields(ItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestFirstApplyItemLedgerEntryTracking(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTouchItemEntryCostOnAfterAfterSetAdjmtProp(var ItemLedgerEntry: Record "Item Ledger Entry"; IsAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnApplyOnBeforeUpdateItemLedgerEntries(var ItemLedgerEntry1: Record "Item Ledger Entry"; var ItemLedgerEntry2: Record "Item Ledger Entry"; ItemApplnEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnApplyOnBeforeItemApplnEntryDelete(var ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeCalculateLastDirectCost(var TotalAmount: Decimal; ItemJournalLine: Record "Item Journal Line"; ValueEntry: Record "Value Entry"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnBeforeUpdateUnitCost(ItemJournalLine: Record "Item Journal Line"; ValueEntry: Record "Value Entry"; var Item: Record Item; var UpdateSKU: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostInventoryToGL(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line"; PostToGL: Boolean; CalledFromAdjustment: Boolean; ItemInventoryValueZero: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostValueEntryToGL(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostInventoryToGL(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSplitJnlLineOnAfterCode(var ItemJournalLine: Record "Item Journal Line"; var ItemJournalLineToPost: Record "Item Journal Line"; var PostItemJournalLine: Boolean; var TempTrackingSpecification: Record "Tracking Specification" temporary; DisableItemTracking: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterCalcCapQty(var ItemJnlLine: Record "Item Journal Line"; var CapQty: Decimal)
    begin
        OnAfterCalcCapQty(ItemJnlLine, CapQty);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCapQty(var ItemJnlLine: Record "Item Journal Line"; var CapQty: Decimal)
    begin
    end;
#endif

    /// <summary>
    /// Prepares provided item journal line for posting and copies it to the global ItemJnlLine record.
    /// </summary>
    /// <remarks>
    /// If General Ledger Setup has additional reporting currency record, that record is retrieved 
    /// and mandatory fields are checked. Checks if an item and its variant are blocked and retrieve their records 
    /// if they are not.
    /// </remarks>
    /// <param name="ItemJnlLineToPost">Item journal line to prepare.</param>
    procedure PrepareItem(var ItemJnlLineToPost: Record "Item Journal Line")
    begin
        ItemJnlLine.Copy(ItemJnlLineToPost);

        GetGLSetup();
        GetInvtSetup();
        CheckItemAndItemVariant(ItemJnlLineToPost."Item No.", ItemJnlLineToPost."Variant Code");

        OnAfterPrepareItem(ItemJnlLineToPost);
    end;

    /// <summary>
    /// Sets the value of the global flag SkipApplicationCheck.
    /// </summary>
    /// <remarks>
    /// If true, then application check is not executed when an item ledger entry is applied to another item ledger entry.
    /// </remarks>
    /// <param name="NewValue">The new value to set.</param>
    procedure SetSkipApplicationCheck(NewValue: Boolean)
    begin
        SkipApplicationCheck := NewValue;
    end;

    /// <summary>
    /// Logs the application of an item ledger entry by creating a new item application entry record and 
    /// adding it to the global temporary item application entry history record set.
    /// </summary>
    /// <param name="ApplyItemLedgEntry">Inbound item ledger entry record.</param>
    /// <param name="AppliedItemLedgEntry">Applied item ledger entry record.</param>
    procedure LogApply(ApplyItemLedgEntry: Record "Item Ledger Entry"; AppliedItemLedgEntry: Record "Item Ledger Entry")
    var
        ItemApplnEntry: Record "Item Application Entry";
    begin
        ItemApplnEntry.Init();
        if AppliedItemLedgEntry.Quantity > 0 then begin
            ItemApplnEntry."Item Ledger Entry No." := ApplyItemLedgEntry."Entry No.";
            ItemApplnEntry."Inbound Item Entry No." := AppliedItemLedgEntry."Entry No.";
            ItemApplnEntry."Outbound Item Entry No." := ApplyItemLedgEntry."Entry No.";
        end else begin
            ItemApplnEntry."Item Ledger Entry No." := AppliedItemLedgEntry."Entry No.";
            ItemApplnEntry."Inbound Item Entry No." := ApplyItemLedgEntry."Entry No.";
            ItemApplnEntry."Outbound Item Entry No." := AppliedItemLedgEntry."Entry No.";
        end;
        AddToApplicationLog(ItemApplnEntry, true);
    end;

    /// <summary>
    /// Logs un-application of an item ledger entry to the global temporary item application entry history record set 
    /// with cost application set to false.
    /// </summary>
    /// <param name="ItemApplnEntry">Item application entry to log.</param>
    procedure LogUnapply(ItemApplnEntry: Record "Item Application Entry")
    begin
        AddToApplicationLog(ItemApplnEntry, false);
    end;

    local procedure AddToApplicationLog(ItemApplnEntry: Record "Item Application Entry"; IsApplication: Boolean)
    begin
        if TempItemApplnEntryHistory.FindLast() then;
        TempItemApplnEntryHistory."Primary Entry No." += 1;

        TempItemApplnEntryHistory."Item Ledger Entry No." := ItemApplnEntry."Item Ledger Entry No.";
        TempItemApplnEntryHistory."Inbound Item Entry No." := ItemApplnEntry."Inbound Item Entry No.";
        TempItemApplnEntryHistory."Outbound Item Entry No." := ItemApplnEntry."Outbound Item Entry No.";

        TempItemApplnEntryHistory."Cost Application" := IsApplication;
        TempItemApplnEntryHistory.Insert();
    end;

    /// <summary>
    /// Clears the global item application entry history temporary record set.
    /// </summary>
    procedure ClearApplicationLog()
    begin
        TempItemApplnEntryHistory.DeleteAll();
    end;

    /// <summary>
    /// Undoes the applications of item ledger entries based on the records in the global 
    /// item application entry history temporary record set.
    /// </summary>
    /// <remarks>
    /// Used during undo manual changes action on application worksheet page.
    /// </remarks>
    procedure UndoApplications()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemApplnEntry: Record "Item Application Entry";
    begin
        TempItemApplnEntryHistory.Ascending(false);
        if TempItemApplnEntryHistory.FindSet() then
            repeat
                if TempItemApplnEntryHistory."Cost Application" then begin
                    ItemApplnEntry.SetRange("Inbound Item Entry No.", TempItemApplnEntryHistory."Inbound Item Entry No.");
                    ItemApplnEntry.SetRange("Outbound Item Entry No.", TempItemApplnEntryHistory."Outbound Item Entry No.");
                    ItemApplnEntry.FindFirst();
                    UnApply(ItemApplnEntry);
                end else begin
                    ItemLedgEntry.Get(TempItemApplnEntryHistory."Item Ledger Entry No.");
                    SetSkipApplicationCheck(true);
                    ReApply(ItemLedgEntry, TempItemApplnEntryHistory."Inbound Item Entry No.");
                end;
            until TempItemApplnEntryHistory.Next() = 0;
        ClearApplicationLog();
        TempItemApplnEntryHistory.Ascending(true);
    end;

    /// <summary>
    /// Returns whether the global item application entry history record set is empty.
    /// </summary>
    /// <returns>True if item application entry history record set is empty, otherwise false.</returns>
    procedure ApplicationLogIsEmpty(): Boolean
    begin
        exit(TempItemApplnEntryHistory.IsEmpty);
    end;

    local procedure AppliedEntriesToReadjust(ItemLedgEntry: Record "Item Ledger Entry") Readjust: Boolean
    begin
        Readjust := ItemLedgEntry."Entry Type" in [ItemLedgEntry."Entry Type"::Output, ItemLedgEntry."Entry Type"::"Assembly Output"];

        OnAfterAppliedEntriesToReadjust(ItemLedgEntry, Readjust);
    end;

    local procedure GetTextStringWithLineNo(BasicTextString: Text; ItemNo: Code[20]; LineNo: Integer): Text
    begin
        if LineNo = 0 then
            exit(StrSubstNo(BasicTextString, ItemNo));
        exit(StrSubstNo(BasicTextString, ItemNo) + StrSubstNo(LineNoTxt, LineNo));
    end;

    /// <summary>
    /// Returns the value of the global flag CalledFromAdjustment.
    /// </summary>
    /// <returns>The value of the global flag CalledFromAdjustment.</returns>
    procedure GetCalledFromAdjustment(): Boolean
    begin
        exit(CalledFromAdjustment);
    end;

    /// <summary>
    /// Returns the value of the global flag CalledFromInvtPutawayPick.
    /// </summary>
    /// <returns>The value of the global flag CalledFromInvtPutawayPick.</returns>
    procedure GetCalledFromInvtPutawayPick(): Boolean
    begin
        exit(CalledFromInvtPutawayPick);
    end;

    /// <summary>
    /// Sets the value of the global flag CalledFromApplicationWorksheet.
    /// </summary>
    /// <remarks>
    /// If false, then touched entries are not tracked.
    /// </remarks>
    /// <param name="IsCalledFromApplicationWorksheet">The new value to set.</param>
    procedure SetCalledFromApplicationWorksheet(IsCalledFromApplicationWorksheet: Boolean)
    begin
        CalledFromApplicationWorksheet := IsCalledFromApplicationWorksheet;
    end;

    local procedure SaveTouchedEntry(ItemLedgerEntryNo: Integer; IsInbound: Boolean)
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
        NextEntryNo: Integer;
    begin
        if not CalledFromApplicationWorksheet then
            exit;

        NextEntryNo := ItemApplicationEntryHistory.GetNextEntryNo();

        ItemApplicationEntryHistory.Init();
        ItemApplicationEntryHistory."Primary Entry No." := NextEntryNo;
        ItemApplicationEntryHistory."Entry No." := 0;
        ItemApplicationEntryHistory."Item Ledger Entry No." := ItemLedgerEntryNo;
        if IsInbound then
            ItemApplicationEntryHistory."Inbound Item Entry No." := ItemLedgerEntryNo
        else
            ItemApplicationEntryHistory."Outbound Item Entry No." := ItemLedgerEntryNo;
        ItemApplicationEntryHistory."Creation Date" := CurrentDateTime;
        ItemApplicationEntryHistory."Created By User" := UserId;
        ItemApplicationEntryHistory.Insert(true);
    end;

    /// <summary>
    /// Marks the entries that were previously modified by the current user as touched. Items of these entries are added to TempItem.
    /// </summary>
    /// <remarks>
    /// Used when opening the application worksheet.
    /// </remarks>
    /// <param name="TempItem">Return value: A collection of items of touched entries.</param>
    procedure RestoreTouchedEntries(var TempItem: Record Item temporary)
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemApplicationEntryHistory.SetRange("Entry No.", 0);
        ItemApplicationEntryHistory.SetRange("Created By User", UpperCase(UserId));
        if ItemApplicationEntryHistory.FindSet() then
            repeat
                TouchEntry(ItemApplicationEntryHistory."Item Ledger Entry No.");

                ItemLedgerEntry.Get(ItemApplicationEntryHistory."Item Ledger Entry No.");
                TempItem."No." := ItemLedgerEntry."Item No.";
                if TempItem.Insert() then;
            until ItemApplicationEntryHistory.Next() = 0;
    end;

    local procedure DeleteTouchedEntries()
    var
        ItemApplicationEntryHistory: Record "Item Application Entry History";
    begin
        if not CalledFromApplicationWorksheet then
            exit;

        ItemApplicationEntryHistory.SetRange("Entry No.", 0);
        ItemApplicationEntryHistory.SetRange("Created By User", UpperCase(UserId));
        ItemApplicationEntryHistory.DeleteAll();
    end;

    local procedure VerifyItemJnlLineAsembleToOrder(var ItemJournalLine: Record "Item Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyItemJnlLineAsembleToOrder(ItemJournalLine, IsHandled);
        if IsHandled then
            exit;

        ItemJournalLine.TestField("Applies-to Entry");

        ItemJournalLine.CalcReservedQuantity();
        ItemJournalLine.TestField("Reserved Qty. (Base)");
    end;

    local procedure VerifyItemJnlLineApplication(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        SkipError: Boolean;
    begin
        if ItemJournalLine."Applies-to Entry" = 0 then
            exit;

        ItemJournalLine.CalcReservedQuantity();
        if ItemJournalLine."Reserved Qty. (Base)" <> 0 then begin
            SkipError := //posting together with PO
                (ItemJournalLine."Document Type" = ItemJournalLine."Document Type"::"Purchase Receipt")
                and (ItemJournalLine."Entry Type" = ItemJournalLine."Entry Type"::"Negative Adjmt.")
                and (ItemJournalLine."Job No." <> '');

            if not SkipError then
                ItemLedgerEntry.FieldError("Applies-to Entry", Text99000000);
        end;
    end;

    local procedure CalcILEExpectedAmount(var OldValueEntry: Record "Value Entry"; ItemLedgerEntryNo: Integer)
    var
        OldValueEntry2: Record "Value Entry";
    begin
        OldValueEntry.FindFirstValueEntryByItemLedgerEntryNo(ItemLedgerEntryNo);
        OldValueEntry2.Copy(OldValueEntry);
        OldValueEntry2.ReadIsolation(IsolationLevel::ReadUnCommitted);
        OldValueEntry2.SetFilter("Entry No.", '<>%1', OldValueEntry."Entry No.");
        OnCalcILEExpectedAmountOnBeforeCalcCostAmounts(OldValueEntry2, OldValueEntry, ItemLedgEntryNo);
        OldValueEntry2.CalcSums("Cost Amount (Expected)", "Cost Amount (Expected) (ACY)");
        OldValueEntry."Cost Amount (Expected)" += OldValueEntry2."Cost Amount (Expected)";
        OldValueEntry."Cost Amount (Expected) (ACY)" += OldValueEntry2."Cost Amount (Expected) (ACY)";
    end;

    local procedure ExpectedCostPosted(ValueEntry: Record "Value Entry"): Boolean
    var
        PostedExpCostValueEntry: Record "Value Entry";
    begin
        if not ValueEntry.Adjustment or (ValueEntry."Applies-to Entry" = 0) then
            exit(false);
        PostedExpCostValueEntry.SetRange("Item Ledger Entry No.", ValueEntry."Item Ledger Entry No.");
        PostedExpCostValueEntry.SetRange("Applies-to Entry", ValueEntry."Applies-to Entry");
        PostedExpCostValueEntry.SetRange("Expected Cost", true);
        exit(not PostedExpCostValueEntry.IsEmpty);
    end;

    /// <summary>
    /// Sets the value of the global flag SkipSerialNoQtyValidation.
    /// </summary>
    /// <remarks>
    /// If true and item tracking code has serial number specific tracking enabled, it skips the checks.
    /// Enabled serial number specific tracking ensures that items are accurately traced with specific serial or lot numbers 
    /// both backward and forward in the supply chain, which is crucial for quality assurance and product recalls.
    /// </remarks>
    /// <param name="NewSkipSerialNoQtyValidation">The new value to set.</param>
    procedure SetSkipSerialNoQtyValidation(NewSkipSerialNoQtyValidation: Boolean)
    begin
        SkipSerialNoQtyValidation := NewSkipSerialNoQtyValidation;
    end;

    local procedure CheckInvoicedQuantity(ItemLedgEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"; var ModifyEntry: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInvoicedQuantity(ItemLedgEntry, ValueEntry, ModifyEntry, IsHandled);
        if IsHandled then
            exit;

        if Abs(ItemLedgEntry."Invoiced Quantity") > Abs(ItemLedgEntry.Quantity) then
            Error(Text030, ItemLedgEntry."Entry No.");
        ModifyEntry := true;
    end;

    local procedure ShowFixedApplicationError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowFixedApplicationError(IsHandled);
        if IsHandled then
            exit;

        Error(Text027);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Item Ledger Entry", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Item Ledger Entry", 'r')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Value Entry", 'r')]
    local procedure ValidateSequenceNo(LedgEntryNo: Integer; xLedgEntryNo: Integer; TableNo: Integer)
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if LedgEntryNo = xLedgEntryNo then
            exit;
        if InvtSetup.UseLegacyPosting() then
            exit;
        SequenceNoMgt.ValidateSeqNo(TableNo);
    end;

    /// <summary>
    /// Marks the inbound item ledger entries that are applied to a specific outbound item ledger entry for adjustment.
    /// </summary>
    /// <param name="OutboundItemLedgerEntryNo">Outbound item ledger entry no.</param>
    procedure MarkAppliedInboundItemEntriesForAdjustment(OutboundItemLedgerEntryNo: Integer)
    var
        InboundItemLedgerEntry: Record "Item Ledger Entry";
        ItemApplicationEntry: Record "Item Application Entry";
    begin
        if ItemApplicationEntry.GetInboundEntriesTheOutbndEntryAppliedTo(OutboundItemLedgerEntryNo) then
            repeat
                InboundItemLedgerEntry.SetLoadFields("Applied Entry to Adjust");
                InboundItemLedgerEntry.Get(ItemApplicationEntry."Inbound Item Entry No.");
                InboundItemLedgerEntry.SetAppliedEntryToAdjust(true);
            until ItemApplicationEntry.Next() = 0;
    end;

    local procedure CheckItemSerialNoForCorrILE(ItemJnlLine2: Record "Item Journal Line")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if SkipSerialNoQtyValidation then
            exit;

        ItemLedgerEntry.SetLoadFields(Quantity);
        ItemLedgerEntry.SetRange("Item No.", ItemJnlLine2."Item No.");
        ItemLedgerEntry.SetRange("Variant Code", ItemJnlLine2."Variant Code");
        ItemLedgerEntry.SetTrackingFilterFromItemJournalLine(ItemJnlLine2);
        ItemLedgerEntry.CalcSums(Quantity);
        if ItemLedgerEntry.Quantity > 0 then
            Error(Text014, ItemJnlLine2."Serial No.");
    end;

    local procedure GetExistingExpirationDateFromILE(var ItemTrackingSetup: Record "Item Tracking Setup"; var ExistingExpirationDate: Date; var SumOfEntries: Decimal)
    begin
        ItemTrackingSetup.CopyTrackingFromNewTrackingSpec(TempTrackingSpecification);
        ExistingExpirationDate :=
          ItemTrackingMgt.ExistingExpirationDateAndQty(
            TempTrackingSpecification."Item No.", TempTrackingSpecification."Variant Code",
            ItemTrackingSetup, SumOfEntries);

        if ((ExistingExpirationDate = 0D) and (SumOfEntries = 0)) and
           ((TempTrackingSpecification."New Lot No." = TempTrackingSpecification."Lot No.") and
            (TempTrackingSpecification."New Package No." <> TempTrackingSpecification."Package No."))
        then begin
            ItemTrackingSetup.CopyTrackingFromTrackingSpec(TempTrackingSpecification);
            ExistingExpirationDate := ItemTrackingMgt.ExistingExpirationDateAndQty(
              TempTrackingSpecification."Item No.", TempTrackingSpecification."Variant Code",
              ItemTrackingSetup, SumOfEntries);
            if (ExistingExpirationDate = 0D) and (SumOfEntries > 0) then
                SumOfEntries := 0;
        end;
    end;

    local procedure CheckCostPerUnitInValueEntry(ItemJournalLine: Record "Item Journal Line"): Boolean
    var
        OldValueEntry: Record "Value Entry";
    begin
        if ItemJournalLine."Source Currency Code" = '' then
            exit;

        if not (ItemJournalLine."Document Type" in [ItemJournalLine."Document Type"::"Purchase Credit Memo", ItemJournalLine."Document Type"::"Purchase Return Shipment"]) then
            exit;

        OldValueEntry.SetLoadFields("Cost per Unit", "Valued Quantity", "Discount Amount");
        OldValueEntry.SetCurrentKey("Item Ledger Entry No.", "Entry Type", "Item Ledger Entry Type");
        OldValueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        OldValueEntry.SetRange("Item Ledger Entry No.", ItemJournalLine."Applies-to Entry");
        OldValueEntry.SetRange("Entry Type", OldValueEntry."Entry Type"::"Direct Cost");
        OldValueEntry.SetRange("Item Ledger Entry Type", OldValueEntry."Item Ledger Entry Type"::Purchase);
        if OldValueEntry.FindFirst() then
            exit(OldValueEntry."Cost per Unit" = ItemJournalLine."Unit Cost");

        exit(false);
    end;

    local procedure SetCostAmountAndCostAmountFCYOnSameCostPerUnit(ItemJournalLine: Record "Item Journal Line"; var CostAmt: Decimal; var CostAmtACY: Decimal)
    begin
        if not CheckCostPerUnitInValueEntry(ItemJournalLine) then
            exit;

        CostAmt := ItemJnlLine.Amount;
        CostAmtACY := ItemJnlLine."Amount (ACY)";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sequence No. Mgt.", 'OnPreviewableLedgerEntry', '', false, false)]
    local procedure OnPreviewableLedgerEntry(TableNo: Integer; var IsPreviewable: Boolean)
    begin
        if TableNo in [Database::"Item Ledger Entry", Database::"Item Register", Database::"Value Entry",
                       Database::Microsoft.Manufacturing.Capacity."Capacity Ledger Entry", Database::"Phys. Inventory Ledger Entry",
                       Database::"Item Application Entry", Database::"Item Application Entry History"]
        then
            IsPreviewable := true;
    end;

    internal procedure RestoreTempSplitItemJnlLine(var TempSplitItemJnlLineFrom: Record "Item Journal Line" temporary)
    begin
        TempSplitItemJnlLine.Reset();
        TempSplitItemJnlLine.DeleteAll();
        if TempSplitItemJnlLineFrom.FindSet() then
            repeat
                TempSplitItemJnlLine := TempSplitItemJnlLineFrom;
                TempSplitItemJnlLine.Insert();
            until TempSplitItemJnlLineFrom.Next() = 0;
    end;

    internal procedure SaveTempSplitItemJnlLine(var TempSplitItemJnlLineTo: Record "Item Journal Line" temporary)
    begin
        TempSplitItemJnlLine.Reset();
        if TempSplitItemJnlLine.FindSet() then
            repeat
                TempSplitItemJnlLineTo := TempSplitItemJnlLine;
                TempSplitItemJnlLineTo.Insert();
            until TempSplitItemJnlLine.Next() = 0;
    end;

    internal procedure RestoreTempTrackingSpecification(var TempTrackingSpecificationFrom: Record "Tracking Specification" temporary)
    begin
        TempSplitItemJnlLine.Reset();
        TempSplitItemJnlLine.DeleteAll();
        if TempTrackingSpecificationFrom.FindSet() then
            repeat
                TempTrackingSpecification := TempTrackingSpecificationFrom;
                TempTrackingSpecification.Insert();
            until TempTrackingSpecificationFrom.Next() = 0;
    end;

    internal procedure SaveTempTrackingSpecification(var TempTrackingSpecificationTo: Record "Tracking Specification" temporary)
    begin
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindSet() then
            repeat
                TempTrackingSpecificationTo := TempTrackingSpecification;
                TempTrackingSpecificationTo.Insert();
            until TempTrackingSpecification.Next() = 0;
    end;

    internal procedure GetItemLedgerEntryNo(): Integer
    begin
        exit(ItemLedgEntryNo);
    end;

    internal procedure RegisterWhseJnlLine(var WhseJnlLine: Record "Warehouse Journal Line")
    begin
        WhseJnlRegisterLine.RegisterWhseJnlLine(WhseJnlLine);
    end;

    internal procedure GetSkipRetrieveItemTracking(): Boolean
    begin
        exit(SkipRetrieveItemTracking);
    end;

    internal procedure SetSkipRetrieveItemTracking(NewSkipRetrieveItemTracking: Boolean)
    begin
        SkipRetrieveItemTracking := NewSkipRetrieveItemTracking;
    end;

    internal procedure SetGlobalItemTrackingCode(ItemTrackingCode: Record "Item Tracking Code")
    begin
        GlobalItemTrackingCode := ItemTrackingCode;
    end;

    internal procedure SetGlobalItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        GlobalItemTrackingSetup := ItemTrackingSetup;
    end;

#if not CLEAN28
    [Obsolete('This event is no longer used.', '28.0')]
    [IntegrationEvent(false, false)]
    local procedure OnVerifyInvoicedQtyOnAfterGetSalesShipmentHeader(ItemLedgEntry2: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAppliedFromValues(var ValueEntry: Record "Value Entry"; NegValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPhysInventoryEntry(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPostValueEntryToGL(ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPostToGL(ValueEntry: Record "Value Entry"; var Result: Boolean; PostToGL: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterCheckItemTrackingOfComp(TempHandlingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line")
    begin
        OnAfterCheckItemTrackingOfComp(TempHandlingSpecification, ItemJnlLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTrackingOfComp(TempHandlingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeGetOutputProdOrder(var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
        OnBeforeGetOutputProdOrder(ProdOrder, ItemJnlLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOutputProdOrder(var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeGetOutputProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
        OnBeforeGetOutputProdOrderLine(ProdOrderLine, ItemJnlLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOutputProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeGetProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; OrderNo: Code[20]; OrderLineNo: Integer; var IsHandled: Boolean)
    begin
        OnBeforeGetProdOrderLine(ProdOrderLine, OrderNo, OrderLineNo, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; OrderNo: Code[20]; OrderLineNo: Integer; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeGetProdOrderRoutingLine(var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
        OnBeforeGetProdOrderRoutingLine(ProdOrderRoutingLine, OldItemJnlLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderRoutingLine(var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; OldItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsNotInternalWhseMovement(ItemJnlLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsInterimRevaluation(ItemJnlLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDateWithExpirationDate(var ItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code"; OldItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemValuePosting(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforePostOutput(var ItemJnlLine: Record "Item Journal Line")
    begin
        OnBeforePostOutput(ItemJnlLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostOutput(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforePostOutputUpdateProdOrderRtngLine(var ProdOrderRtngLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
        OnBeforePostOutputUpdateProdOrderRtngLine(ProdOrderRtngLine, ItemJnlLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostOutputUpdateProdOrderRtngLine(var ProdOrderRtngLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnCalcCapLedgerEntriesSetupRunTimeOnAfterCapLedgerEntrySetFilters(var CapLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
        OnCalcCapLedgerEntriesSetupRunTimeOnAfterCapLedgerEntrySetFilters(CapLedgerEntry, ItemJnlLine);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCalcCapLedgerEntriesSetupRunTimeOnAfterCapLedgerEntrySetFilters(var CapLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCheckExpirationDateOnAfterCalcSumLot(var SumLot: Decimal; SignFactor: Integer; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckExpirationDateOnBeforeAssignExpirationDate(var TempTrackingSpecification: Record "Tracking Specification" temporary; ExistingExpirationDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitItemJnlLineOnBeforeInsertTempTrkgSpecification(var TempTrackingSpecification: Record "Tracking Specification" temporary; ItemJnlLine2: Record "Item Journal Line"; SignFactor: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTransValueEntryOnBeforeCalcCostAmounts(GlobalValueEntry: Record "Value Entry"; var ValueEntry: Record "Value Entry"; ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertValueEntryOnBeforeCalcExpectedCost(var ItemJnlLine: Record "Item Journal Line"; var ItemLedgEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; TransferItemPBln: Boolean; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; var ShouldCalcExpectedCost: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertValueEntryOnBeforeRoundAmtValueEntry(var ValueEntry: Record "Value Entry"; var ItemLedgEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line"; TransferItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertVarValueEntryOnAfterInitValueEntryFields(var ValueEntry: record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLedgEntryOnBeforeVerifyOnInventory(ItemJnlLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertItemLedgEntryOnCheckItemTracking(ItemJnlLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCapValueEntryOnAfterUpdateCapLedgEntry(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCapValueEntryOnAfterInsertValueEntryRelation(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line"; var TempValueEntryRelation: Record "Value Entry Relation" temporary)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnInsertCapValueEntryOnBeforeCapLedgEntryModify(var CapLedgEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeGetGlobalLedgerEntry(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateCostPerUnit(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line"; var ItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCalledFromAdjustment(CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransferEntryOnBeforeInitTransValueEntry(var TempItemEntryRelation: Record "Item Entry Relation"; var NewItemLedgEntry: Record "Item Ledger Entry"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitCorrItemLedgEntryOnAfterRetrieveAppliedExpirationDate(var NewItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitItemJnlLineOnBeforePostItemJnlLine(var TempTrackingSpecification: Record "Tracking Specification"; var GlobalItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitItemJnlLineOnAfterDeleteTempSplitItemJnlLine(ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertValueEntryOnAfterTempValueEntryRelationInsert(var ValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line"; var TempValueEntryRelation: Record "Value Entry Relation");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnAfterAssignLastDirectCost(var ValueEntry: Record "Value Entry"; var Item: Record Item; LastDirectCost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnAfterInsertApplEntry(var ItemJnlLine: Record "Item Journal Line"; var TempSplitItemJnlLine: Record "Item Journal Line" temporary; var GlobalItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnBeforeInsertApplEntry(var GlobalItemLedgEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUnApplyOnBeforeInsertApplEntry(var ItemApplnEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCostApplyOnBeforeInsertApplEntry(var GlobalItemLedgEntry: Record "Item Ledger Entry"; var ApplyWithItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnItemLedgEntryPositiveOnBeforeInsertApplEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; var ItemLedgEntry: Record "Item Ledger Entry"; var GlobalItemLedgEntry: Record "Item Ledger Entry"; var AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransferEntryOnBeforeInsertApplEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertApplEntryOnBeforeModify(var ItemApplicationEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeInitCorrItemLedgEntry(var ItemJnlLine: Record "Item Journal Line"; var OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnAfterInitCorrItemLedgEntry(var OldItemLedgEntry: Record "Item Ledger Entry"; var NewItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnAfterUpdateItemApplnEntry(var ItemJnlLine: Record "Item Journal Line"; OldItemLedgEntry: Record "Item Ledger Entry"; NewItemLedgEntry: Record "Item Ledger Entry"; NewValueEntry: Record "Value Entry"; InventoryPostingToGL: Codeunit "Inventory Posting To G/L")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeUpdateOldItemLedgEntry(var OldValueEntry2: Record "Value Entry"; var NewItemLedgEntry: Record "Item Ledger Entry"; var NewValueEntry: Record "Value Entry"; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeInsertApplEntry(var NewItemLedgEntry: Record "Item Ledger Entry"; var OldItemLedgEntry: Record "Item Ledger Entry"; var GlobalItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupSplitJnlLine(var ItemJnlLine2: Record "Item Journal Line"; var TempSplitItemJnlLine: Record "Item Journal Line"; var ItemJnlLineOrigin: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification"; TrackingSpecExists: Boolean; CalledFromAdjustment: Boolean; PostponeReservationHandling: Boolean; var PostItemJnlLine: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeFirstReservationSetFilters(var ItemJnlLine: Record "Item Journal Line"; var StartApplication: Boolean; FirstReservation: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeCloseSurplusTrackingEntry(ItemJnlLine: Record "Item Journal Line"; var StartApplication: Boolean; var UseReservationApplication: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPhysInventoryEntry(var ItemJnlLineOrigin: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnItemValuePostingOnBeforeInsertOHValueEntry(var ItemJnlLine: Record "Item Journal Line"; var GlobalValueEntry: Record "Value Entry"; var GlobalItemLedgEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer; var IsHandled: Boolean; var VarianceAmount: Decimal; var VarianceAmountACY: Decimal; var OverheadAmount: Decimal; var OverheadAmountACY: Decimal)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnPostConsumptionOnBeforeCalcRemQtyToPostThisLine(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification"; RemQtyToPost: Decimal; UseItemTrackingApplication: Boolean; LastLoop: Boolean; var IsHandled: Boolean)
    begin
        OnPostConsumptionOnBeforeCalcRemQtyToPostThisLine(ProdOrderComp, ItemJnlLine, TempHandlingSpecification, RemQtyToPost, UseItemTrackingApplication, LastLoop, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeCalcRemQtyToPostThisLine(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line"; var TempHandlingSpecification: Record "Tracking Specification"; RemQtyToPost: Decimal; UseItemTrackingApplication: Boolean; LastLoop: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostConsumptionOnBeforeCalcRemainingQuantity(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line"; var NewRemainingQty: Decimal; var QtyToPost: Decimal; var IsHandled: Boolean; var RemQtyToPost: Decimal)
    begin
        OnPostConsumptionOnBeforeCalcRemainingQuantity(ProdOrderComp, ItemJnlLine, NewRemainingQty, QtyToPost, IsHandled, RemQtyToPost);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnBeforeCalcRemainingQuantity(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ItemJnlLine: Record "Item Journal Line"; var NewRemainingQty: Decimal; var QtyToPost: Decimal; var IsHandled: Boolean; var RemQtyToPost: Decimal)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostConsumptionOnRemQtyToPostOnBeforeInsertConsumpEntry(var ItemJnlLine: Record "Item Journal Line"; var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnPostConsumptionOnRemQtyToPostOnBeforeInsertConsumpEntry(ItemJnlLine, ProdOrderComponent);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionOnRemQtyToPostOnBeforeInsertConsumpEntry(var ItemJnlLine: Record "Item Journal Line"; var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnSetItemAdjmtPropertiesOnBeforeCheckModifyItem(var Item2: Record Item; var ModifyItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupTempSplitItemJnlLineOnAfterCalcPostItemJnlLine(var TempSplitItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var PostItemJnlLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCheckItemTracking(var ItemJnlLine: Record "Item Journal Line"; DisableItemTracking: Boolean; var IsHandled: Boolean; var TempTrackingSpecification: Record "Tracking Specification"; var ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvoicedQuantity(ItemLedgEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"; var ModifyEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateOrigAppliedFromEntryOnItemApplEntryLoop(var ItemLedgEntry: Record "Item Ledger Entry"; ItemApplEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemLedgEntryOnBeforeUpdateOutboundItemLedgEntry(ValueEntry: Record "Value Entry"; var IsHandled: Boolean; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnApplicationLoop(var ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeSetAverageTransfer(var ItemJnlLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTouchItemEntryCost(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line"; IsAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnApply(var ItemApplnEntry: Record "Item Application Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupSplitJnlLineProcedure(var ItemJnlLine2: Record "Item Journal Line"; TrackingSpecExists: Boolean; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowFixedApplicationError(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnBeforeTransferReservFromJobPlanningLine(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean; var AverageTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunWithCheckOnAfterRetrieveItemTracking(var ItemJournalLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification"; var TrackingSpecExists: Boolean; PostponeReservationHandling: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrackingOnAfterCheckRequiredTrackingNos(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCapValueEntryOnBeforeInventoryPostingToGL(ValueEntry: Record "Value Entry"; var IsHandled: Boolean; PostToGL: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforePostOutputForProdOrder(var ItemJnlLine: Record "Item Journal Line"; var LastOperation: Boolean; var IsHandled: Boolean)
    begin
        OnBeforePostOutputForProdOrder(ItemJnlLine, LastOperation, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostOutputForProdOrder(var ItemJnlLine: Record "Item Journal Line"; var LastOperation: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPostItemOnAfterCheckCostingMethodStandard(var Item: Record Item; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateLinkedValuationDate(GlobalItemLedgEntry: Record "Item Ledger Entry"; FromItemledgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInventoryToGLOnAfterPostInvtBuffer(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeTestOrder(ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInvtBufferOnAfterBufferInvtPosting(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcQtyPerUnitOfMeasure(var ItemJnlLine: Record "Item Journal Line"; Subcontracting: Boolean; var QtyPerUnitOfMeasure: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertValueEntryOnBeforeInsertPostValueEntryToGL(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemQtyPostingOnAfterInsertTransferEntry(var ItemJnlLine: Record "Item Journal Line"; AverageTransfer: Boolean; GlobalItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; TotalAppliedQty: Decimal; var TempItemEntryRelation: Record "Item Entry Relation"; var GlobalValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertValueEntryOnAfterInsertPostValueEntryToGL(var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateValuationDate(GlobalItemLedgEntry: Record "Item Ledger Entry"; FromItemLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeSetQuantity(var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemTrackingInformationOnBeforeTestFields(ItemTrackingSetup: Record "Item Tracking Setup"; TrackingSpecification: Record "Tracking Specification"; ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostInventoryToGLOnBeforePostInvtBuffer(var InventoryPostingToGL: Codeunit "Inventory Posting To G/L"; PostToGL: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransferEntryOnBeforeCalcIsReserved(ItemJnlLine: Record "Item Journal Line"; var TempTrackingSpecification: Record "Tracking Specification"; NewItemLedgEntry: Record "Item Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"; var IsReserved: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupTempSplitItemJnlLineOnBeforeCalcPostItemJnlLine(var TempSplitItemJnlLine: Record "Item Journal Line"; TempTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [InternalEvent(false)]
    local procedure OnSetupTempSplitItemJnlLineOnAfterDeductNonDistr(var TempSplitItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeRunCheck(var ItemJnlCheckLine: Codeunit "Item Jnl.-Check Line"; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeInsertCorrOldItemLedgEntry(OldItemLedgEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeReservationExists(ItemJnlLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeReservationExists(ItemJnlLine, Result, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeReservationExists(ItemJnlLine: Record "Item Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnAfterCalcShouldInsertCorrValueEntry(OldItemLedgEntry: Record "Item Ledger Entry"; var ShouldInsertCorrValueEntries: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnPostOutputOnBeforeGetMfgAmounts(var ItemJnlLine: Record "Item Journal Line"; ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean)
    begin
        OnPostOutputOnBeforeGetMfgAmounts(ItemJnlLine, ProdOrder, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputOnBeforeGetMfgAmounts(var ItemJnlLine: Record "Item Journal Line"; ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAvgCostAdjmtBufferOnAfterSetValueEntry(var ValueEntry: Record "Value Entry"; OldItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGeneralPostingSetup(ItemJournalLine: Record "Item Journal Line"; var GeneralPostingSetup: Record "General Posting Setup"; PostToGl: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemOnAfterGetItem(Item: Record Item; ItemJnlLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemVariantOnAfterGetItemVariant(ItemVariant: Record "Item Variant"; ItemJnlLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMoveApplication(var ItemLedgerEntry: Record "Item Ledger Entry"; OldItemLedgerEntry: Record "Item Ledger Entry"; var Enough: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitValueEntryOnBeforeSetDocumentLineNo(ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnCorrectOutputValuationDateOnBeforeValueEntryFindSet(var ValueEntry: Record "Value Entry")
    begin
        OnCorrectOutputValuationDateOnBeforeValueEntryFindSet(ValueEntry);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCorrectOutputValuationDateOnBeforeValueEntryFindSet(var ValueEntry: Record "Value Entry")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnAfterTestFirstApplyItemLedgEntry(OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertBalanceExpCostRevEntry(var GlobalItemLedgEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"; var ValueEntryNo: Integer; var GLSetup: Record "General Ledger Setup"; var Currency: Record Currency; var GLSetupRead: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnAfterAutoTrack(var NewItemLedgEntry: Record "Item Ledger Entry"; var NewValueEntry: Record "Value Entry"; ItemJnlLine: Record "Item Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTransValueEntryOnBeforeCalcAdjustedCost(OldItemLedgEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; var AdjCostInvoicedLCY: Decimal; var AdjCostInvoicedACY: Decimal; var DiscountAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetLastDirectCostValEntryOnBeforeFindDirCostValueEntry(var DirCostValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNegValueEntry(var NegValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestFirstApplyItemLedgEntryOnBeforeTestFields(var OldItemLedgerEntry: Record "Item Ledger Entry"; var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestFirstApplyItemLedgEntryOnBeforeReservationPreventsApplication(OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValuateAppliedAvgEntry(var ValueEntry: Record "Value Entry"; ItemJournalLine: Record "Item Journal Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeCheckPositive(var ItemJournalLine: Record "Item Journal Line"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeAutoTrack(var NewItemLedgerEntry: Record "Item Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckApplicationOnBeforeRemainingQtyError(OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnAfterInsertItemReg(var ItemJournalLine: Record "Item Journal Line"; var OldItemLedgerEntry: Record "Item Ledger Entry"; var NewItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCorrValueEntryOnAfterAssignNewValueEntry(GlobalItemLedgerEntry: Record "Item Ledger Entry"; var OldValueEntry: Record "Value Entry"; var NewValueEntry: Record "Value Entry"; var ItemJournalLine: Record "Item Journal Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetItemAdjmtProperties(ItemNo: Code[20]; ItemLedgEntryType: Enum "Item Ledger Entry Type"; Adjustment: Boolean; OriginalPostingDate: Date; ValuationDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckItemAndItemVariant(ItemNo: Code[20]; VariantCode: Code[10]; var Item: Record Item; var ItemVariant: Record "Item Variant"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemValuePostingOnBeforeInsertValueEntry(ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemLedgerEntryOnAfterSetAppliedEntryToAdjust(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAvgCostAdjmtBuffer(var OldItemLedgerEntry: Record "Item Ledger Entry"; var ValueEntry: Record "Value Entry"; var ValuationDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemAndVariant(var ItemJournalLine: Record "Item Journal Line"; CalledFromAdjustment: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnPostOutputOnBeforeInsertCostValueEntries(var ItemJournalLine: Record "Item Journal Line"; var CapacityLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; var ValuedQty: Decimal; var DirCostAmt: Decimal; var IndirCostAmt: Decimal)
    begin
        OnPostOutputOnBeforeInsertCostValueEntries(ItemJournalLine, CapacityLedgerEntry, ValuedQty, DirCostAmt, IndirCostAmt);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(true, false)]
    local procedure OnPostOutputOnBeforeInsertCostValueEntries(var ItemJournalLine: Record "Item Journal Line"; var CapacityLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; var ValuedQty: Decimal; var DirCostAmt: Decimal; var IndirCostAmt: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemApplnEntryOnAfterFilterItemApplicationEntry(var ItemApplnEntry: Record "Item Application Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnAfterSetLoadFieldsOnReservEntry(var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPublishPostingInventoryToGL(ItemJournalLine: Record "Item Journal Line"; var InventoryPostingToGL: Codeunit "Inventory Posting To G/L")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeOnApplyCapNeed(var ItemJnlLine: Record "Item Journal Line"; var PostedSetupTime: Decimal; var PostedRunTime: Decimal; var IsHandled: Boolean)
    begin
        OnBeforeOnApplyCapNeed(ItemJnlLine, PostedSetupTime, PostedRunTime, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnApplyCapNeed(var ItemJnlLine: Record "Item Journal Line"; var PostedSetupTime: Decimal; var PostedRunTime: Decimal; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnPostOutputForProdOrderOnAfterApplyCapNeed(var ItemJnlLine: Record "Item Journal Line"; var ValuedQty: Decimal)
    begin
        OnPostOutputForProdOrderOnAfterApplyCapNeed(ItemJnlLine, ValuedQty);
    end;

    [Obsolete('Moved to codeunit MfgItemJnlPostLine', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPostOutputForProdOrderOnAfterApplyCapNeed(var ItemJnlLine: Record "Item Journal Line"; var ValuedQty: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReApply(ItemLedgerEntry: Record "Item Ledger Entry"; ApplyWith: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPostWithReservation(var ItemJournalLine: Record "Item Journal Line"; var ReservationEntry: Record "Reservation Entry"; var ItemJournalLinePosted: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCollectItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; var TargetItemEntryRelation: Record "Item Entry Relation" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCollectValueEntryRelation(var TempValueEntryRelation: Record "Value Entry Relation" temporary; var TargetValueEntryRelation: Record "Value Entry Relation" temporary; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUndoValuePostingWithJob(OldItemLedgEntryNo: Integer; NewItemLedgEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcedureInsertCapLedgEntry(var ItemJournalLine: Record "Item Journal Line"; var CapacityLedgerEntry: Record Microsoft.Manufacturing.Capacity."Capacity Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterRunCheck(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemQtyPosting(var ItemJnlLine: Record "Item Journal Line"; var CalledFromAdjustment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetupTempSplitItemJnlLine(var ItemJnlLine2: Record "Item Journal Line"; var SignFactor: Integer; var NonDistrQuantity: Decimal; var NonDistrAmount: Decimal; var NonDistrAmountACY: Decimal; var NonDistrDiscountAmount: Decimal; var Invoice: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUndoQuantityPostingOnBeforeCheckItem(Item: Record Item; ItemLedgerEntry: Record "Item Ledger Entry"; var ShouldCheckItem: Boolean)
    begin
    end;

    [InternalEvent(true)]
    local procedure OnPostConsumption(
        var ItemJnlLine: Record "Item Journal Line"; GlobalItemTrackingSetup: Record "Item Tracking Setup"; var TempSplitItemJnlLine: Record "Item Journal Line" temporary; var ProdOrderCompModified: Boolean; ItemLedgEntryNo: Integer)
    begin
    end;

    [InternalEvent(true)]
    local procedure OnPostOutput(
        var ItemJnlLine: Record "Item Journal Line"; GlobalItemTrackingSetup: Record "Item Tracking Setup"; GlobalItemTrackingCode: Record "Item Tracking Code"; var GlobalItemLedgerEntry: Record "Item Ledger Entry"; var LastOperation: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnSetOrderAdjmtPropertiesForProduction(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OrderNo: Code[20]; OrderLineNo: Integer)
    begin
    end;

    [InternalEvent(true)]
    local procedure OnCorrectOutputValuationDateOnCheckProduction(ItemLedgerEntry: Record "Item Ledger Entry"; var TempValueEntry: Record "Value Entry" temporary; var ValuationDate: Date; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUpdatedAppliedQtyForConsumption(OldItemLedgerEntry: Record "Item Ledger Entry"; ItemLedgerEntry: Record "Item Ledger Entry"; ReservationEntry2: Record "Reservation Entry"; SourceType: Integer; var AppliedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReApplyOnBeforeUpdateLinkedValuationDate(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyItemLedgEntryOnBeforeGetValuationDate(var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateItemLedgEntryOnBeforeUpdateAvgCostAdjmtBuffer(ItemLedgerEntry: Record "Item Ledger Entry"; ValuationDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetValuationDate(OldItemLedgerEntry: Record "Item Ledger Entry"; OldValuationDate: Date; var IsHandled: Boolean)
    begin
    end;
}

