// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Ledger;
using System.Reflection;

codeunit 7150 "Update Item Analysis View"
{
    Permissions = TableData "Item Analysis View" = rm,
                  TableData "Item Analysis View Filter" = r,
                  TableData "Item Analysis View Entry" = rimd,
                  TableData "Item Analysis View Budg. Entry" = rimd;
    TableNo = "Item Analysis View";

    trigger OnRun()
    begin
        if Rec.Code <> '' then begin
            InitLastEntryNo();
            Rec.LockTable();
            Rec.Find();
            UpdateOne(Rec, 2, Rec."Last Entry No." < LastValueEntryNo - 1000);
        end;
    end;

    var
        ItemAnalysisView: Record "Item Analysis View";
        GLSetup: Record "General Ledger Setup";
        ValueEntry: Record "Value Entry";
        ItemBudgetEntry: Record "Item Budget Entry";
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisViewBudgetEntry: Record "Item Analysis View Budg. Entry";
        ItemAnalysisViewFilter: Record "Item Analysis View Filter";
        TempItemAnalysisViewEntry: Record "Item Analysis View Entry" temporary;
        TempItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry" temporary;
        TempDimBuf: Record "Dimension Buffer" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        TempDimEntryBuffer: Record "Dimension Entry Buffer" temporary;
        ItemAnalysisViewSource: Query "Item Analysis View Source";
        Window: Dialog;
        FilterIsInitialized: Boolean;
        FiltersExist: Boolean;
        PrevPostingDate: Date;
        PrevCalculatedPostingDate: Date;
        NoOfEntries: Integer;
        ShowProgressWindow: Boolean;
        WinLastEntryNo: Integer;
        WinUpdateCounter: Integer;
        WinTotalCounter: Integer;
        WinTime0: Time;
        WinTime1: Time;
        WinTime2: Time;
        LastValueEntryNo: Integer;
        LastItemBudgetEntryNo: Integer;
        LastEntryNoIsInitialized: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'Analysis View     #1############################\\';
        Text006: Label 'Updating table    #2############################\';
        Text007: Label 'Speed: (Entries/s)#4########\';
        Text008: Label 'Average Speed     #5########';
        Text009: Label '#6############### @3@@@@@@@@@@@@@@@@@@@@@@@@@@@@\\';
#pragma warning restore AA0470
        Text010: Label 'Summarizing';
        Text011: Label 'Updating Database';
#pragma warning restore AA0074

    procedure InitLastEntryNo()
    begin
        ValueEntry.Reset();
        ItemBudgetEntry.Reset();
        if LastEntryNoIsInitialized then
            exit;
        if ValueEntry.FindLast() then
            LastValueEntryNo := ValueEntry."Entry No.";
        if ItemBudgetEntry.FindLast() then
            LastItemBudgetEntryNo := ItemBudgetEntry."Entry No.";
        LastEntryNoIsInitialized := true;
    end;

    procedure UpdateAll(Which: Option "Ledger Entries","Budget Entries",Both; DirectlyFromPosting: Boolean)
    var
        ItemAnalysisView2: Record "Item Analysis View";
        IsHandled: Boolean;
        SessionNo: integer;
    begin
        if not ItemAnalysisView2.WritePermission() then
            exit;

        IsHandled := false;
        OnBeforeUpdateAll(IsHandled);
        if IsHandled then
            exit;

        ItemAnalysisView2.ReadIsolation(IsolationLevel::ReadUncommitted);
        ItemAnalysisView2.SetRange(Blocked, false);
        if DirectlyFromPosting then
            ItemAnalysisView2.SetRange("Update on Posting", true);

        if ItemAnalysisView2.IsEmpty() then
            exit;

        if GuiAllowed() and DirectlyFromPosting and TaskScheduler.CanCreateTask() then
            StartSession(SessionNo, Codeunit::"Update Item Analysis View Bck.")
        else
            UpdateAll(ItemAnalysisView2, Which, DirectlyFromPosting);

    end;

    procedure UpdateAll(var ItemAnalysisView2: Record "Item Analysis View"; Which: Option "Ledger Entries","Budget Entries",Both; DirectlyFromPosting: Boolean)
    begin
        InitLastEntryNo();

        if DirectlyFromPosting then
            ItemAnalysisView2.SetFilter("Last Entry No.", '<%1', LastValueEntryNo);

        ItemAnalysisView2.LockTable();
        if ItemAnalysisView2.FindSet() then
            repeat
                UpdateOne(ItemAnalysisView2, Which, ItemAnalysisView2."Last Entry No." < LastValueEntryNo - 1000);
            until ItemAnalysisView2.Next() = 0;

        OnAfterUpdateAll(Which, DirectlyFromPosting);
    end;

    procedure Update(var NewItemAnalysisView: Record "Item Analysis View"; Which: Option "Ledger Entries","Budget Entries",Both; ShowWindow: Boolean)
    begin
        NewItemAnalysisView.LockTable();
        NewItemAnalysisView.Find();
        UpdateOne(NewItemAnalysisView, Which, ShowWindow);
    end;

    local procedure UpdateOne(var NewItemAnalysisView: Record "Item Analysis View"; Which: Option "Ledger Entries","Budget Entries",Both; ShowWindow: Boolean)
    var
        Updated: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateOne(NewItemAnalysisView, ItemAnalysisView, Which, ShowWindow, LastValueEntryNo, LastItemBudgetEntryNo, IsHandled);
        if IsHandled then
            exit;

        ItemAnalysisView := NewItemAnalysisView;
        ItemAnalysisView.TestField(Blocked, false);
        ShowProgressWindow := ShowWindow;
        if ShowProgressWindow then
            InitWindow();

        if Which in [Which::"Ledger Entries", Which::Both] then
            if LastValueEntryNo > ItemAnalysisView."Last Entry No." then begin
                if ShowProgressWindow then
                    UpdateWindowHeader(DATABASE::"Item Analysis View Entry", ValueEntry."Entry No.");
                UpdateEntries();
                ItemAnalysisView."Last Entry No." := LastValueEntryNo;
                Updated := true;
            end;

        if (Which in [Which::"Budget Entries", Which::Both]) and
           ItemAnalysisView."Include Budgets"
        then
            if LastItemBudgetEntryNo > ItemAnalysisView."Last Budget Entry No." then begin
                if ShowProgressWindow then
                    UpdateWindowHeader(DATABASE::"Item Analysis View Budg. Entry", ItemBudgetEntry."Entry No.");
                ItemBudgetEntry.Reset();
                ItemBudgetEntry.SetRange("Analysis Area", ItemAnalysisView."Analysis Area");
                ItemBudgetEntry.SetRange("Entry No.", ItemAnalysisView."Last Budget Entry No." + 1, LastItemBudgetEntryNo);
                UpdateBudgetEntries(ItemAnalysisView."Last Budget Entry No." + 1);
                ItemAnalysisView."Last Budget Entry No." := LastItemBudgetEntryNo;
                Updated := true;
            end;

        if Updated then begin
            ItemAnalysisView."Last Date Updated" := Today;
            ItemAnalysisView.Modify();
        end;
        if ShowProgressWindow then
            Window.Close();
    end;

    local procedure UpdateEntries()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProgressIndicator: Integer;
    begin
        GLSetup.Get();
        FilterIsInitialized := false;
        ItemAnalysisViewSource.SetRange(AnalysisArea, ItemAnalysisView."Analysis Area");
        ItemAnalysisViewSource.SetRange(AnalysisViewCode, ItemAnalysisView.Code);
        ItemAnalysisViewSource.SetRange(EntryNo, ItemAnalysisView."Last Entry No." + 1, LastValueEntryNo);
        if ItemAnalysisView."Item Filter" <> '' then
            ItemAnalysisViewSource.SetFilter(ItemNo, ItemAnalysisView."Item Filter");
        if ItemAnalysisView."Location Filter" <> '' then
            ItemAnalysisViewSource.SetFilter(LocationCode, ItemAnalysisView."Location Filter");
        OnUpdateEntriesOnAfterSetFilters(ItemAnalysisView);
        ItemAnalysisViewSource.Open();

        while ItemAnalysisViewSource.Read() do begin
            ProgressIndicator := ProgressIndicator + 1;
            if DimSetIDInFilter(ItemAnalysisViewSource.DimensionSetID, ItemAnalysisView) then begin
                UpdateAnalysisViewEntry(ItemAnalysisViewSource.DimVal1, ItemAnalysisViewSource.DimVal2, ItemAnalysisViewSource.DimVal3, ItemAnalysisViewSource.ItemLedgerEntryType);
                if (ItemAnalysisView."Analysis Area" = ItemAnalysisView."Analysis Area"::Sales) and
                   (ItemAnalysisViewSource.ItemLedgerEntryType = ItemAnalysisViewSource.ItemLedgerEntryType::Purchase) and
                   (ItemAnalysisViewSource.CostAmountNonInvtbl <> 0) and
                   (ItemAnalysisViewSource.ItemChargeNo <> '')
                then begin
                    // purchase invoice for item charge can belong to sales - Cost Amount (Non-Invtbl.)
                    ItemLedgerEntry.Get(ItemAnalysisViewSource.ItemLedgerEntryNo);
                    if ItemLedgerEntry."Entry Type" = ItemLedgerEntry."Entry Type"::Sale then
                        UpdateAnalysisViewEntry(ItemAnalysisViewSource.DimVal1, ItemAnalysisViewSource.DimVal2, ItemAnalysisViewSource.DimVal3, ItemAnalysisViewSource.ItemLedgerEntryType::Sale);
                end;
            end;
            if ShowProgressWindow then
                UpdateWindowCounter(ProgressIndicator);
        end;
        ItemAnalysisViewSource.Close();

        if ShowProgressWindow then
            UpdateWindowCounter(ProgressIndicator);
        FlushAnalysisViewEntry();
    end;

    local procedure UpdateBudgetEntries(DeleteFromEntry: Integer)
    begin
        ItemAnalysisViewBudgetEntry.SetRange("Analysis Area", ItemAnalysisView."Analysis Area");
        ItemAnalysisViewBudgetEntry.SetRange("Analysis View Code", ItemAnalysisView.Code);
        ItemAnalysisViewBudgetEntry.SetFilter("Entry No.", '>%1', DeleteFromEntry);
        ItemAnalysisViewBudgetEntry.DeleteAll();
        ItemAnalysisViewBudgetEntry.Reset();

        if ItemAnalysisView."Item Filter" <> '' then
            ItemBudgetEntry.SetFilter("Item No.", ItemAnalysisView."Item Filter");
        if ItemAnalysisView."Location Filter" <> '' then
            ItemBudgetEntry.SetFilter("Location Code", ItemAnalysisView."Location Filter");
        if ItemBudgetEntry.IsEmpty() then
            exit;
        ItemBudgetEntry.FindSet(true);

        repeat
            if DimSetIDInFilter(ItemBudgetEntry."Dimension Set ID", ItemAnalysisView) then
                UpdateAnalysisViewBudgetEntry(
                  GetDimVal(ItemAnalysisView."Dimension 1 Code", ItemBudgetEntry."Dimension Set ID"),
                  GetDimVal(ItemAnalysisView."Dimension 2 Code", ItemBudgetEntry."Dimension Set ID"),
                  GetDimVal(ItemAnalysisView."Dimension 3 Code", ItemBudgetEntry."Dimension Set ID"));
            if ShowProgressWindow then
                UpdateWindowCounter(ItemBudgetEntry."Entry No.");
        until ItemBudgetEntry.Next() = 0;
        if ShowProgressWindow then
            UpdateWindowCounter(ItemBudgetEntry."Entry No.");
        FlushAnalysisViewBudgetEntry();
    end;

    local procedure UpdateAnalysisViewEntry(DimValue1: Code[20]; DimValue2: Code[20]; DimValue3: Code[20]; EntryType: Enum "Item Ledger Entry Type")
    var
        PostingDate: Date;
        EntryNo: Integer;
        IsHandled: Boolean;
    begin
        PostingDate := ItemAnalysisViewSource.PostingDate;
        if PostingDate < ItemAnalysisView."Starting Date" then begin
            PostingDate := ItemAnalysisView."Starting Date" - 1;
            EntryNo := 0;
        end else begin
            PostingDate := CalculatePeriodStart(PostingDate, ItemAnalysisView."Date Compression");
            if PostingDate < ItemAnalysisView."Starting Date" then
                PostingDate := ItemAnalysisView."Starting Date";
            if ItemAnalysisView."Date Compression" <> ItemAnalysisView."Date Compression"::None then
                EntryNo := 0;
        end;
        TempItemAnalysisViewEntry.Init();
        TempItemAnalysisViewEntry."Analysis Area" := ItemAnalysisView."Analysis Area";
        TempItemAnalysisViewEntry."Analysis View Code" := ItemAnalysisView.Code;
        TempItemAnalysisViewEntry."Item No." := ItemAnalysisViewSource.ItemNo;
        TempItemAnalysisViewEntry."Source Type" := ItemAnalysisViewSource.SourceType;
        TempItemAnalysisViewEntry."Source No." := ItemAnalysisViewSource.SourceNo;
        TempItemAnalysisViewEntry."Entry Type" := ItemAnalysisViewSource.EntryType;
        TempItemAnalysisViewEntry."Item Ledger Entry Type" := EntryType;

        TempItemAnalysisViewEntry."Location Code" := ItemAnalysisViewSource.LocationCode;
        TempItemAnalysisViewEntry."Posting Date" := PostingDate;
        TempItemAnalysisViewEntry."Dimension 1 Value Code" := DimValue1;
        TempItemAnalysisViewEntry."Dimension 2 Value Code" := DimValue2;
        TempItemAnalysisViewEntry."Dimension 3 Value Code" := DimValue3;
        TempItemAnalysisViewEntry."Entry No." := EntryNo;

        OnAfterInitializeTempItemAnalysisViewEntry(TempItemAnalysisViewEntry, ItemAnalysisView, ItemAnalysisViewSource, ValueEntry, IsHandled);
        if IsHandled then
            exit;

        if TempItemAnalysisViewEntry.Find() then begin
            if (ItemAnalysisViewSource.EntryType = ItemAnalysisViewSource.EntryType::"Direct Cost") and
               (ItemAnalysisViewSource.ItemChargeNo = '')
            then
                AddValue(TempItemAnalysisViewEntry.Quantity, ItemAnalysisViewSource.ILEQuantity);
            AddValue(TempItemAnalysisViewEntry."Invoiced Quantity", ItemAnalysisViewSource.InvoicedQuantity);

            AddValue(TempItemAnalysisViewEntry."Sales Amount (Actual)", ItemAnalysisViewSource.SalesAmountActual);
            AddValue(TempItemAnalysisViewEntry."Cost Amount (Actual)", ItemAnalysisViewSource.CostAmountActual);
            AddValue(TempItemAnalysisViewEntry."Cost Amount (Non-Invtbl.)", ItemAnalysisViewSource.CostAmountNonInvtbl);

            AddValue(TempItemAnalysisViewEntry."Sales Amount (Expected)", ItemAnalysisViewSource.SalesAmountExpected);
            AddValue(TempItemAnalysisViewEntry."Cost Amount (Expected)", ItemAnalysisViewSource.CostAmountExpected);
            OnUpdateAnalysisViewEntryOnBeforeModifyTempItemAnalysisViewEntry(TempItemAnalysisViewEntry, ItemAnalysisViewSource, ValueEntry, ItemAnalysisView);
            TempItemAnalysisViewEntry.Modify();
        end else begin
            if (ItemAnalysisViewSource.EntryType = ItemAnalysisViewSource.EntryType::"Direct Cost") and
               (ItemAnalysisViewSource.ItemChargeNo = '')
            then
                TempItemAnalysisViewEntry.Quantity := ItemAnalysisViewSource.ILEQuantity;
            TempItemAnalysisViewEntry."Invoiced Quantity" := ItemAnalysisViewSource.InvoicedQuantity;

            TempItemAnalysisViewEntry."Sales Amount (Actual)" := ItemAnalysisViewSource.SalesAmountActual;
            TempItemAnalysisViewEntry."Cost Amount (Actual)" := ItemAnalysisViewSource.CostAmountActual;
            TempItemAnalysisViewEntry."Cost Amount (Non-Invtbl.)" := ItemAnalysisViewSource.CostAmountNonInvtbl;

            TempItemAnalysisViewEntry."Sales Amount (Expected)" := ItemAnalysisViewSource.SalesAmountExpected;
            TempItemAnalysisViewEntry."Cost Amount (Expected)" := ItemAnalysisViewSource.CostAmountExpected;
            OnUpdateAnalysisViewEntryOnBeforeInsertTempItemAnalysisViewEntry(TempItemAnalysisViewEntry, ItemAnalysisViewSource, ValueEntry, ItemAnalysisView);
            TempItemAnalysisViewEntry.Insert();
            NoOfEntries := NoOfEntries + 1;
        end;
        if NoOfEntries >= 10000 then
            FlushAnalysisViewEntry();
    end;

    local procedure UpdateAnalysisViewBudgetEntry(DimValue1: Code[20]; DimValue2: Code[20]; DimValue3: Code[20])
    begin
        TempItemAnalysisViewBudgEntry."Analysis Area" := ItemAnalysisView."Analysis Area";
        TempItemAnalysisViewBudgEntry."Analysis View Code" := ItemAnalysisView.Code;
        TempItemAnalysisViewBudgEntry."Budget Name" := ItemBudgetEntry."Budget Name";
        TempItemAnalysisViewBudgEntry."Location Code" := ItemBudgetEntry."Location Code";
        TempItemAnalysisViewBudgEntry."Item No." := ItemBudgetEntry."Item No.";
        TempItemAnalysisViewBudgEntry."Source Type" := ItemBudgetEntry."Source Type";
        TempItemAnalysisViewBudgEntry."Source No." := ItemBudgetEntry."Source No.";

        if ItemBudgetEntry.Date < ItemAnalysisView."Starting Date" then
            TempItemAnalysisViewBudgEntry."Posting Date" := ItemAnalysisView."Starting Date" - 1
        else begin
            TempItemAnalysisViewBudgEntry."Posting Date" :=
              CalculatePeriodStart(ItemBudgetEntry.Date, ItemAnalysisView."Date Compression");
            if TempItemAnalysisViewBudgEntry."Posting Date" < ItemAnalysisView."Starting Date" then
                TempItemAnalysisViewBudgEntry."Posting Date" := ItemAnalysisView."Starting Date";
        end;
        TempItemAnalysisViewBudgEntry."Dimension 1 Value Code" := DimValue1;
        TempItemAnalysisViewBudgEntry."Dimension 2 Value Code" := DimValue2;
        TempItemAnalysisViewBudgEntry."Dimension 3 Value Code" := DimValue3;
        TempItemAnalysisViewBudgEntry."Entry No." := ItemBudgetEntry."Entry No.";
        OnUpdateAnalysisViewBudgetEntryOnAfterInitTempItemAnalysisViewBudgEntry(TempItemAnalysisViewBudgEntry, ItemBudgetEntry, ItemAnalysisView);

        if TempItemAnalysisViewBudgEntry.Find() then begin
            AddValue(TempItemAnalysisViewBudgEntry."Sales Amount", ItemBudgetEntry."Sales Amount");
            AddValue(TempItemAnalysisViewBudgEntry."Cost Amount", ItemBudgetEntry."Cost Amount");
            AddValue(TempItemAnalysisViewBudgEntry.Quantity, ItemBudgetEntry.Quantity);
            TempItemAnalysisViewBudgEntry.Modify();
        end else begin
            TempItemAnalysisViewBudgEntry."Sales Amount" := ItemBudgetEntry."Sales Amount";
            TempItemAnalysisViewBudgEntry."Cost Amount" := ItemBudgetEntry."Cost Amount";
            TempItemAnalysisViewBudgEntry.Quantity := ItemBudgetEntry.Quantity;
            TempItemAnalysisViewBudgEntry.Insert();
            NoOfEntries := NoOfEntries + 1;
        end;
        if NoOfEntries >= 10000 then
            FlushAnalysisViewBudgetEntry();
    end;

    local procedure CalculatePeriodStart(PostingDate: Date; DateCompression: Integer): Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if PostingDate = ClosingDate(PostingDate) then
            exit(PostingDate);

        case DateCompression of
            ItemAnalysisView."Date Compression"::Week:
                PostingDate := CalcDate('<CW+1D-1W>', PostingDate);
            ItemAnalysisView."Date Compression"::Month:
                PostingDate := CalcDate('<CM+1D-1M>', PostingDate);
            ItemAnalysisView."Date Compression"::Quarter:
                PostingDate := CalcDate('<CQ+1D-1Q>', PostingDate);
            ItemAnalysisView."Date Compression"::Year:
                PostingDate := CalcDate('<CY+1D-1Y>', PostingDate);
            ItemAnalysisView."Date Compression"::Period:
                begin
                    if PostingDate <> PrevPostingDate then begin
                        PrevPostingDate := PostingDate;
                        AccountingPeriod.SetRange("Starting Date", 0D, PostingDate);
                        if AccountingPeriod.FindLast() then
                            PrevCalculatedPostingDate := AccountingPeriod."Starting Date"
                        else
                            PrevCalculatedPostingDate := PostingDate;
                    end;
                    PostingDate := PrevCalculatedPostingDate;
                end;
        end;
        exit(PostingDate);
    end;

    local procedure FlushAnalysisViewEntry()
    begin
        if ShowProgressWindow then
            Window.Update(6, Text011);
        if TempItemAnalysisViewEntry.FindSet() then
            repeat
                ItemAnalysisViewEntry.Init();
                ItemAnalysisViewEntry := TempItemAnalysisViewEntry;

                if ((ItemAnalysisView."Analysis Area" = ItemAnalysisView."Analysis Area"::Sales) and
                    ((ItemAnalysisViewEntry."Item Ledger Entry Type" <> ItemAnalysisViewEntry."Item Ledger Entry Type"::Sale) or
                     (ItemAnalysisViewEntry."Entry Type" = ItemAnalysisViewEntry."Entry Type"::Revaluation))) or
                   ((ItemAnalysisView."Analysis Area" = ItemAnalysisView."Analysis Area"::Purchase) and
                    (ItemAnalysisViewEntry."Item Ledger Entry Type" <> ItemAnalysisViewEntry."Item Ledger Entry Type"::Purchase)) or
                   ((ItemAnalysisView."Analysis Area" = ItemAnalysisView."Analysis Area"::Inventory) and
                    (ItemAnalysisViewEntry."Item Ledger Entry Type" = ItemAnalysisViewEntry."Item Ledger Entry Type"::" "))
                then begin
                    if ItemAnalysisViewEntry.Find() then
                        ItemAnalysisViewEntry.Delete();
                end else
                    if not ItemAnalysisViewEntry.Insert() then begin
                        ItemAnalysisViewEntry.Find();
                        AddValue(ItemAnalysisViewEntry.Quantity, TempItemAnalysisViewEntry.Quantity);
                        AddValue(ItemAnalysisViewEntry."Invoiced Quantity", TempItemAnalysisViewEntry."Invoiced Quantity");

                        AddValue(ItemAnalysisViewEntry."Sales Amount (Actual)", TempItemAnalysisViewEntry."Sales Amount (Actual)");
                        AddValue(ItemAnalysisViewEntry."Cost Amount (Actual)", TempItemAnalysisViewEntry."Cost Amount (Actual)");
                        AddValue(ItemAnalysisViewEntry."Cost Amount (Non-Invtbl.)", TempItemAnalysisViewEntry."Cost Amount (Non-Invtbl.)");

                        AddValue(ItemAnalysisViewEntry."Sales Amount (Expected)", TempItemAnalysisViewEntry."Sales Amount (Expected)");
                        AddValue(ItemAnalysisViewEntry."Cost Amount (Expected)", TempItemAnalysisViewEntry."Cost Amount (Expected)");
                        OnFlushAnalysisViewEntryOnBeforeModifyItemAnalysisViewEntry(ItemAnalysisViewEntry, TempItemAnalysisViewEntry);
                        ItemAnalysisViewEntry.Modify();
                    end;
            until TempItemAnalysisViewEntry.Next() = 0;
        TempItemAnalysisViewEntry.DeleteAll();
        NoOfEntries := 0;
        if ShowProgressWindow then
            Window.Update(6, Text010);
    end;

    local procedure FlushAnalysisViewBudgetEntry()
    var
        IsHandled: Boolean;
    begin
        OnBeforeFlushAnalysisViewBudgetEntry(TempItemAnalysisViewBudgEntry, ShowProgressWindow, IsHandled);
        if IsHandled then
            exit;

        if ShowProgressWindow then
            Window.Update(6, Text011);
        if TempItemAnalysisViewBudgEntry.FindSet() then
            repeat
                ItemAnalysisViewBudgetEntry.Init();
                ItemAnalysisViewBudgetEntry := TempItemAnalysisViewBudgEntry;
                if not ItemAnalysisViewBudgetEntry.Insert() then begin
                    ItemAnalysisViewBudgetEntry.Find();
                    AddValue(ItemAnalysisViewBudgetEntry."Sales Amount", TempItemAnalysisViewBudgEntry."Sales Amount");
                    AddValue(ItemAnalysisViewBudgetEntry."Sales Amount", TempItemAnalysisViewBudgEntry."Cost Amount");
                    AddValue(ItemAnalysisViewBudgetEntry."Sales Amount", TempItemAnalysisViewBudgEntry.Quantity);
                    ItemAnalysisViewBudgetEntry.Modify();
                end;
            until TempItemAnalysisViewBudgEntry.Next() = 0;
        TempItemAnalysisViewBudgEntry.DeleteAll();
        NoOfEntries := 0;
        if ShowProgressWindow then
            Window.Update(6, Text010);
    end;

    local procedure GetDimVal(DimCode: Code[20]; DimSetID: Integer): Code[20]
    begin
        if TempDimSetEntry.Get(DimSetID, DimCode) then
            exit(TempDimSetEntry."Dimension Value Code");
        if DimSetEntry.Get(DimSetID, DimCode) then
            TempDimSetEntry := DimSetEntry
        else begin
            TempDimSetEntry."Dimension Set ID" := DimSetID;
            TempDimSetEntry."Dimension Code" := DimCode;
            TempDimSetEntry."Dimension Value Code" := '';
        end;
        TempDimSetEntry.Insert();
        exit(TempDimSetEntry."Dimension Value Code");
    end;

    local procedure InitWindow()
    begin
        Window.Open(
          Text005 +
          Text006 +
          Text009 +
          Text007 +
          Text008);
        Window.Update(6, Text010);
    end;

    local procedure UpdateWindowCounter(EntryNo: Integer)
    begin
        WinUpdateCounter := WinUpdateCounter + 1;
        WinTime2 := Time;
        if (WinTime2 > WinTime1 + 1000) or (EntryNo = WinLastEntryNo) then begin
            if WinLastEntryNo <> 0 then
                Window.Update(3, Round(EntryNo / WinLastEntryNo * 10000, 1));
            WinTotalCounter := WinTotalCounter + WinUpdateCounter;
            if WinTime2 <> WinTime1 then
                Window.Update(4, Round(WinUpdateCounter * (1000 / (WinTime2 - WinTime1)), 1));
            if WinTime2 <> WinTime0 then
                Window.Update(5, Round(WinTotalCounter * (1000 / (WinTime2 - WinTime0)), 1));
            WinTime1 := WinTime2;
            WinUpdateCounter := 0;
        end;
    end;

    local procedure UpdateWindowHeader(TableID: Integer; EntryNo: Integer)
    var
        AllObj: Record AllObj;
    begin
        WinLastEntryNo := EntryNo;
        WinTotalCounter := 0;
        AllObj.Get(AllObj."Object Type"::Table, TableID);
        Window.Update(1, ItemAnalysisView.Code);
        Window.Update(2, AllObj."Object Name");
        Window.Update(3, 0);
        Window.Update(4, 0);
        Window.Update(5, 0);
        WinTime0 := Time;
        WinTime1 := WinTime0;
        WinTime2 := WinTime0;
    end;

    procedure SetLastBudgetEntryNo(NewLastBudgetEntryNo: Integer)
    var
        ItemAnalysisView2: Record "Item Analysis View";
    begin
        ItemAnalysisView.SetRange("Last Budget Entry No.", NewLastBudgetEntryNo + 1, 2147483647);
        ItemAnalysisView.SetRange("Include Budgets", true);
        if ItemAnalysisView.FindSet(true) then
            repeat
                ItemAnalysisView2 := ItemAnalysisView;
                ItemAnalysisView2."Last Budget Entry No." := NewLastBudgetEntryNo;
                ItemAnalysisView2.Modify();
            until ItemAnalysisView.Next() = 0;
    end;

    local procedure AddValue(var ToValue: Decimal; FromValue: Decimal)
    begin
        ToValue := ToValue + FromValue;
    end;

    local procedure IsValueIncludedInFilter(DimValue: Code[20]; DimFilter: Code[250]): Boolean
    begin
        TempDimBuf.Reset();
        TempDimBuf.DeleteAll();
        TempDimBuf.Init();
        TempDimBuf."Dimension Value Code" := DimValue;
        TempDimBuf.Insert();
        TempDimBuf.SetFilter(TempDimBuf."Dimension Value Code", DimFilter);
        exit(TempDimBuf.FindFirst());
    end;

    procedure DimSetIDInFilter(DimSetID: Integer; var ItemAnalysisView: Record "Item Analysis View"): Boolean
    var
        InFilters: Boolean;
    begin
        if not FilterIsInitialized then begin
            TempDimEntryBuffer.DeleteAll();
            FilterIsInitialized := true;
            ItemAnalysisViewFilter.SetRange("Analysis Area", ItemAnalysisView."Analysis Area");
            ItemAnalysisViewFilter.SetRange("Analysis View Code", ItemAnalysisView.Code);
            FiltersExist := not ItemAnalysisViewFilter.IsEmpty();
        end;

        if not FiltersExist then
            exit(true);

        if TempDimEntryBuffer.Get(DimSetID) then  // cashed value?
            exit(TempDimEntryBuffer."Dimension Entry No." <> 0);

        InFilters := true;
        if ItemAnalysisViewFilter.FindSet() then
            repeat
                if DimSetEntry.Get(DimSetID, ItemAnalysisViewFilter."Dimension Code") then
                    InFilters :=
                      InFilters and
                      IsValueIncludedInFilter(
                        DimSetEntry."Dimension Value Code", ItemAnalysisViewFilter."Dimension Value Filter")
                else
                    InFilters :=
                      InFilters and IsValueIncludedInFilter('', ItemAnalysisViewFilter."Dimension Value Filter");
            until (ItemAnalysisViewFilter.Next() = 0) or not InFilters;
        TempDimEntryBuffer."No." := DimSetID;
        if InFilters then
            TempDimEntryBuffer."Dimension Entry No." := 1
        else
            TempDimEntryBuffer."Dimension Entry No." := 0;
        TempDimEntryBuffer.Insert();
        exit(InFilters);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAll(Which: Option "Ledger Entries","Budget Entries",Both; DirectlyFromPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeTempItemAnalysisViewEntry(var TempItemAnalysisViewEntry: Record "Item Analysis View Entry" temporary; ItemAnalysisView: Record "Item Analysis View"; var ItemAnalysisViewSource: Query "Item Analysis View Source"; var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAnalysisViewEntryOnBeforeInsertTempItemAnalysisViewEntry(var TempItemAnalysisViewEntry: Record "Item Analysis View Entry" temporary; var ItemAnalysisViewSource: Query "Item Analysis View Source"; var ValueEntry: Record "Value Entry"; var ItemAnalysisView: Record "Item Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAnalysisViewEntryOnBeforeModifyTempItemAnalysisViewEntry(var TempItemAnalysisViewEntry: Record "Item Analysis View Entry" temporary; var ItemAnalysisViewSource: Query "Item Analysis View Source"; var ValueEntry: Record "Value Entry"; var ItemAnalysisView: Record "Item Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAll(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFlushAnalysisViewEntryOnBeforeModifyItemAnalysisViewEntry(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; var TempItemAnalysisViewEntry: Record "Item Analysis View Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateEntriesOnAfterSetFilters(var ItemAnalysisView: Record "Item Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAnalysisViewBudgetEntryOnAfterInitTempItemAnalysisViewBudgEntry(var ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry"; var ItemBudgetEntry: Record "Item Budget Entry"; var ItemAnalysisView: Record "Item Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateOne(var NewItemAnalysisView: Record "Item Analysis View"; var ItemAnalysisView: Record "Item Analysis View"; Which: Option "Ledger Entries","Budget Entries",Both; var ShowWindow: Boolean; var LastValueEntryEntryNo: Integer; var LastItemBudgetEntryNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFlushAnalysisViewBudgetEntry(var TempItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry" temporary; ShowProgressWindow: Boolean; var IsHandled: Boolean)
    begin
    end;
}

