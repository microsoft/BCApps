// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Utilities;

codeunit 7153 "Item Analysis Management"
{

    trigger OnRun()
    begin
    end;

    var
        PrevItemAnalysisView: Record "Item Analysis View";
        MatrixMgt: Codeunit "Matrix Management";

#pragma warning disable AA0074
        Text000: Label 'Period';
        Text001: Label '<Sign><Integer Thousand><Decimals,2>', Locked = true;
#pragma warning disable AA0470
        Text003: Label '%1 is not a valid line definition.';
        Text004: Label '%1 is not a valid column definition.';
#pragma warning restore AA0470
        Text005: Label '1,6,,Dimension 1 Filter';
        Text006: Label '1,6,,Dimension 2 Filter';
        Text007: Label '1,6,,Dimension 3 Filter';
        Text008: Label 'DEFAULT';
        Text009: Label 'Default analysis view';
#pragma warning restore AA0074

    local procedure DimCodeNotAllowed(DimCode: Text[30]; ItemAnalysisView: Record "Item Analysis View") Result: Boolean
    var
        Item: Record Item;
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDimCodeNotAllowed(DimCode, ItemAnalysisView, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(
          not (UpperCase(DimCode) in
               [UpperCase(Item.TableCaption()),
                UpperCase(Location.TableCaption()),
                UpperCase(Text000),
                ItemAnalysisView."Dimension 1 Code",
                ItemAnalysisView."Dimension 2 Code",
                ItemAnalysisView."Dimension 3 Code",
                '']));
    end;

    local procedure DimCodeToType(DimCode: Text[30]; ItemAnalysisView: Record "Item Analysis View") Result: Enum "Item Analysis Dimension Type"
    var
        Location: Record Location;
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDimCodeToType(DimCode, ItemAnalysisView, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case DimCode of
            Item.TableCaption():
                exit(Enum::"Item Analysis Dimension Type"::Item);
            Text000:
                exit(Enum::"Item Analysis Dimension Type"::Period);
            Location.TableCaption():
                exit(Enum::"Item Analysis Dimension Type"::Location);
            ItemAnalysisView."Dimension 1 Code":
                exit(Enum::"Item Analysis Dimension Type"::"Dimension 1");
            ItemAnalysisView."Dimension 2 Code":
                exit(Enum::"Item Analysis Dimension Type"::"Dimension 2");
            ItemAnalysisView."Dimension 3 Code":
                exit(Enum::"Item Analysis Dimension Type"::"Dimension 3");
            else
                exit(Enum::"Item Analysis Dimension Type"::Undefined);
        end;
    end;

    local procedure CopyItemToBuf(var Item: Record Item; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Item."No.";
        DimCodeBuf.Name := Item.Description;
    end;

    local procedure CopyPeriodToBuf(var Period: Record Date; var DimCodeBuf: Record "Dimension Code Buffer"; DateFilter: Text[30])
    var
        Period2: Record Date;
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Format(Period."Period Start");
        DimCodeBuf."Period Start" := Period."Period Start";
        DimCodeBuf."Period End" := Period."Period End";
        if DateFilter <> '' then begin
            Period2.SetFilter("Period End", DateFilter);
            if Period2.GetRangeMax("Period End") < DimCodeBuf."Period End" then
                DimCodeBuf."Period End" := Period2.GetRangeMax("Period End");
        end;
        DimCodeBuf.Name := Period."Period Name";

        OnAfterCopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
    end;

    local procedure CopyLocationToBuf(var Location: Record Location; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := Location.Code;
        DimCodeBuf.Name := Location.Name;
    end;

    local procedure CopyDimValueToBuf(var DimVal: Record "Dimension Value"; var DimCodeBuf: Record "Dimension Code Buffer")
    begin
        DimCodeBuf.Init();
        DimCodeBuf.Code := DimVal.Code;
        DimCodeBuf.Name := DimVal.Name;
        DimCodeBuf.Totaling := DimVal.Totaling;
        DimCodeBuf.Indentation := DimVal.Indentation;
        DimCodeBuf."Show in Bold" :=
          DimVal."Dimension Value Type" <> DimVal."Dimension Value Type"::Standard;
    end;

    local procedure FilterItemAnalyViewEntry(var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var ItemAnalysisViewEntry: Record "Item Analysis View Entry")
    begin
        ItemStatisticsBuffer.CopyFilter("Analysis Area Filter", ItemAnalysisViewEntry."Analysis Area");
        ItemStatisticsBuffer.CopyFilter("Analysis View Filter", ItemAnalysisViewEntry."Analysis View Code");

        if ItemStatisticsBuffer.GetFilter("Item Filter") <> '' then
            ItemStatisticsBuffer.CopyFilter("Item Filter", ItemAnalysisViewEntry."Item No.");

        if ItemStatisticsBuffer.GetFilter("Date Filter") <> '' then
            ItemStatisticsBuffer.CopyFilter("Date Filter", ItemAnalysisViewEntry."Posting Date");

        if ItemStatisticsBuffer.GetFilter("Location Filter") <> '' then
            ItemStatisticsBuffer.CopyFilter("Location Filter", ItemAnalysisViewEntry."Location Code");

        if ItemStatisticsBuffer.GetFilter("Dimension 1 Filter") <> '' then
            ItemStatisticsBuffer.CopyFilter("Dimension 1 Filter", ItemAnalysisViewEntry."Dimension 1 Value Code");

        if ItemStatisticsBuffer.GetFilter("Dimension 2 Filter") <> '' then
            ItemStatisticsBuffer.CopyFilter("Dimension 2 Filter", ItemAnalysisViewEntry."Dimension 2 Value Code");

        if ItemStatisticsBuffer.GetFilter("Dimension 3 Filter") <> '' then
            ItemStatisticsBuffer.CopyFilter("Dimension 3 Filter", ItemAnalysisViewEntry."Dimension 3 Value Code");

        OnAfterFilterItemAnalyViewEntry(ItemStatisticsBuffer, ItemAnalysisViewEntry);
    end;

    local procedure FilterItemAnalyViewBudgEntry(var ItemStatisticsBuf: Record "Item Statistics Buffer"; var ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry")
    begin
        ItemStatisticsBuf.CopyFilter("Analysis Area Filter", ItemAnalysisViewBudgEntry."Analysis Area");
        ItemStatisticsBuf.CopyFilter("Analysis View Filter", ItemAnalysisViewBudgEntry."Analysis View Code");
        ItemStatisticsBuf.CopyFilter("Budget Filter", ItemAnalysisViewBudgEntry."Budget Name");

        if ItemStatisticsBuf.GetFilter("Item Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Item Filter", ItemAnalysisViewBudgEntry."Item No.");

        if ItemStatisticsBuf.GetFilter("Location Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Location Filter", ItemAnalysisViewBudgEntry."Location Code");

        if ItemStatisticsBuf.GetFilter("Date Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Date Filter", ItemAnalysisViewBudgEntry."Posting Date");

        if ItemStatisticsBuf.GetFilter("Dimension 1 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Dimension 1 Filter", ItemAnalysisViewBudgEntry."Dimension 1 Value Code");

        if ItemStatisticsBuf.GetFilter("Dimension 2 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Dimension 2 Filter", ItemAnalysisViewBudgEntry."Dimension 2 Value Code");

        if ItemStatisticsBuf.GetFilter("Dimension 3 Filter") <> '' then
            ItemStatisticsBuf.CopyFilter("Dimension 3 Filter", ItemAnalysisViewBudgEntry."Dimension 3 Value Code");

        OnAfterFilterItemAnalyViewBudgEntry(ItemStatisticsBuf, ItemAnalysisViewBudgEntry);
    end;

    local procedure SetDimFilters(var ItemStatisticsBuffer: Record "Item Statistics Buffer"; DimType: Enum "Item Analysis Dimension Type"; DimCodeBuf: Record "Dimension Code Buffer")
    begin
        case DimType of
            DimType::Item:
                ItemStatisticsBuffer.SetRange("Item Filter", DimCodeBuf.Code);
            DimType::Period:
                ItemStatisticsBuffer.SetRange("Date Filter", DimCodeBuf."Period Start", DimCodeBuf."Period End");
            DimType::Location:
                ItemStatisticsBuffer.SetRange("Location Filter", DimCodeBuf.Code);
            DimType::"Dimension 1":
                if DimCodeBuf.Totaling <> '' then
                    ItemStatisticsBuffer.SetFilter("Dimension 1 Filter", DimCodeBuf.Totaling)
                else
                    ItemStatisticsBuffer.SetRange("Dimension 1 Filter", DimCodeBuf.Code);
            DimType::"Dimension 2":
                if DimCodeBuf.Totaling <> '' then
                    ItemStatisticsBuffer.SetFilter("Dimension 2 Filter", DimCodeBuf.Totaling)
                else
                    ItemStatisticsBuffer.SetRange("Dimension 2 Filter", DimCodeBuf.Code);
            DimType::"Dimension 3":
                if DimCodeBuf.Totaling <> '' then
                    ItemStatisticsBuffer.SetFilter("Dimension 3 Filter", DimCodeBuf.Totaling)
                else
                    ItemStatisticsBuffer.SetRange("Dimension 3 Filter", DimCodeBuf.Code);
        end;

        OnAfterSetDimFilters(ItemStatisticsBuffer, DimType, DimCodeBuf);
    end;

    procedure SetBufferFilters(CurrentAnalysisArea: Enum "Analysis Area Type"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentAnalysisViewCode: Code[10]; ItemFilter: Text; LocationFilter: Text; DateFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; BudgetFilter: Text)
    begin
        ItemStatisticsBuffer.Reset();
        ItemStatisticsBuffer.SetRange("Analysis Area Filter", CurrentAnalysisArea);
        ItemStatisticsBuffer.SetRange("Analysis View Filter", CurrentAnalysisViewCode);

        if ItemFilter <> '' then
            ItemStatisticsBuffer.SetFilter("Item Filter", ItemFilter);
        if LocationFilter <> '' then
            ItemStatisticsBuffer.SetFilter("Location Filter", LocationFilter);
        if DateFilter <> '' then
            ItemStatisticsBuffer.SetFilter("Date Filter", DateFilter);
        if Dim1Filter <> '' then
            ItemStatisticsBuffer.SetFilter("Dimension 1 Filter", Dim1Filter);
        if Dim2Filter <> '' then
            ItemStatisticsBuffer.SetFilter("Dimension 2 Filter", Dim2Filter);
        if Dim3Filter <> '' then
            ItemStatisticsBuffer.SetFilter("Dimension 3 Filter", Dim3Filter);
        if BudgetFilter <> '' then
            ItemStatisticsBuffer.SetFilter("Budget Filter", BudgetFilter);

        OnAfterSetCommonFilters(CurrentAnalysisArea, ItemStatisticsBuffer, CurrentAnalysisViewCode);
    end;

    procedure AnalysisViewSelection(CurrentAnalysisArea: Option; var CurrentItemAnalysisViewCode: Code[10]; var ItemAnalysisView: Record "Item Analysis View"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var Dim1Filter: Code[250]; var Dim2Filter: Code[250]; var Dim3Filter: Code[250])
    begin
        if not ItemAnalysisView.Get(CurrentAnalysisArea, CurrentItemAnalysisViewCode) then begin
            ItemAnalysisView.FilterGroup := 2;
            ItemAnalysisView.SetRange("Analysis Area", CurrentAnalysisArea);
            ItemAnalysisView.FilterGroup := 0;
            if not ItemAnalysisView.Find('-') then begin
                ItemAnalysisView.Init();
                ItemAnalysisView."Analysis Area" := "Analysis Area Type".FromInteger(CurrentAnalysisArea);
                ItemAnalysisView.Code := Text008;
                ItemAnalysisView.Name := Text009;
                ItemAnalysisView.Insert(true);
            end;
            CurrentItemAnalysisViewCode := ItemAnalysisView.Code;
        end;

        SetItemAnalysisView(
          CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
          Dim1Filter, Dim2Filter, Dim3Filter);
    end;

    procedure CheckAnalysisView(CurrentAnalysisArea: Option; CurrentItemAnalysisViewCode: Code[10]; var ItemAnalysisView: Record "Item Analysis View")
    begin
        ItemAnalysisView.Get(CurrentAnalysisArea, CurrentItemAnalysisViewCode);
    end;

    procedure SetItemAnalysisView(CurrentAnalysisArea: Option; CurrentItemAnalysisViewCode: Code[10]; var ItemAnalysisView: Record "Item Analysis View"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var Dim1Filter: Code[250]; var Dim2Filter: Code[250]; var Dim3Filter: Code[250])
    begin
        ItemStatisticsBuffer.SetRange("Analysis Area Filter", CurrentAnalysisArea);
        ItemStatisticsBuffer.SetRange("Analysis View Filter", CurrentItemAnalysisViewCode);

        if PrevItemAnalysisView.Code <> '' then begin
            if ItemAnalysisView."Dimension 1 Code" <> PrevItemAnalysisView."Dimension 1 Code" then
                Dim1Filter := '';
            if ItemAnalysisView."Dimension 2 Code" <> PrevItemAnalysisView."Dimension 2 Code" then
                Dim2Filter := '';
            if ItemAnalysisView."Dimension 3 Code" <> PrevItemAnalysisView."Dimension 3 Code" then
                Dim3Filter := '';
        end;
        ItemStatisticsBuffer.SetFilter("Dimension 1 Filter", Dim1Filter);
        ItemStatisticsBuffer.SetFilter("Dimension 2 Filter", Dim2Filter);
        ItemStatisticsBuffer.SetFilter("Dimension 3 Filter", Dim3Filter);

        PrevItemAnalysisView := ItemAnalysisView;

        OnAfterSetItemAnalysisView(CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode);
    end;

    procedure LookupItemAnalysisView(CurrentAnalysisArea: Option; var CurrentItemAnalysisViewCode: Code[10]; var ItemAnalysisView: Record "Item Analysis View"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var Dim1Filter: Code[250]; var Dim2Filter: Code[250]; var Dim3Filter: Code[250])
    var
        ItemAnalysisView2: Record "Item Analysis View";
    begin
        ItemAnalysisView2.Copy(ItemAnalysisView);
        ItemAnalysisView2.FilterGroup := 2;
        ItemAnalysisView2.SetRange("Analysis Area", CurrentAnalysisArea);
        ItemAnalysisView2.FilterGroup := 0;
        if PAGE.RunModal(0, ItemAnalysisView2) = ACTION::LookupOK then begin
            ItemAnalysisView := ItemAnalysisView2;
            CurrentItemAnalysisViewCode := ItemAnalysisView.Code;
            SetItemAnalysisView(
              CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
              Dim1Filter, Dim2Filter, Dim3Filter);
        end else
            AnalysisViewSelection(
              CurrentAnalysisArea, CurrentItemAnalysisViewCode, ItemAnalysisView, ItemStatisticsBuffer,
              Dim1Filter, Dim2Filter, Dim3Filter);
    end;

    procedure LookupDimCode(DimType: Enum "Item Analysis Dimension Type"; DimCode: Text[30]; "Code": Text[30])
    var
        Item: Record Item;
        Location: Record Location;
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        case DimType of
            DimType::Item:
                begin
                    Item.Get(Code);
                    PAGE.RunModal(0, Item);
                end;
            DimType::Period:
                ;
            DimType::Location:
                begin
                    Location.Get(Code);
                    PAGE.RunModal(0, Location);
                end;
            DimType::"Dimension 1",
            DimType::"Dimension 2",
            DimType::"Dimension 3":
                begin
                    DimVal.SetRange("Dimension Code", DimCode);
                    DimVal.Get(DimCode, Code);
                    Clear(DimValList);
                    DimValList.SetTableView(DimVal);
                    DimValList.SetRecord(DimVal);
                    DimValList.RunModal();
                end;
        end;

        OnAfterLookupDimCode(DimType, DimCode, Code);
    end;

    procedure LookUpDimFilter(Dim: Code[20]; var Text: Text): Boolean
    var
        DimVal: Record "Dimension Value";
        DimValList: Page "Dimension Value List";
    begin
        if Dim = '' then
            exit(false);
        DimValList.LookupMode(true);
        DimVal.SetRange("Dimension Code", Dim);
        DimValList.SetTableView(DimVal);
        if DimValList.RunModal() = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter();
            exit(true);
        end;
    end;

    procedure DrillDownAmount(CurrentAnalysisArea: Enum "Analysis Area Type"; ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10]; ItemFilter: Text; LocationFilter: Text; DateFilter: Text; Dim1Filter: Text; Dim2Filter: Text; Dim3Filter: Text; BudgetFilter: Text; LineDimType: Enum "Item Analysis Dimension Type"; LineDimCodeBuf: Record "Dimension Code Buffer"; ColDimType: Enum "Item Analysis Dimension Type"; ColDimCodeBuf: Record "Dimension Code Buffer"; SetColumnFilter: Boolean; ValueType: Enum "Item Analysis Value Type"; ShowActualBudget: Enum "Item Analysis Show Type")
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        ItemAnalysisViewBudgetEntry: Record "Item Analysis View Budg. Entry";
    begin
        SetBufferFilters(
          CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
          ItemFilter, LocationFilter, DateFilter, Dim1Filter, Dim2Filter, Dim3Filter, BudgetFilter);
        SetDimFilters(ItemStatisticsBuffer, LineDimType, LineDimCodeBuf);
        if SetColumnFilter then
            SetDimFilters(ItemStatisticsBuffer, ColDimType, ColDimCodeBuf);

        case ShowActualBudget of
            ShowActualBudget::"Actual Amounts",
            ShowActualBudget::Variance,
            ShowActualBudget::"Variance%",
            ShowActualBudget::"Index%":
                begin
                    FilterItemAnalyViewEntry(ItemStatisticsBuffer, ItemAnalysisViewEntry);
                    case ValueType of
                        ValueType::"Sales Amount":
                            PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry."Sales Amount (Actual)");
                        ValueType::"Cost Amount":
                            PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry."Cost Amount (Actual)");
                        ValueType::Quantity:
                            PAGE.Run(0, ItemAnalysisViewEntry, ItemAnalysisViewEntry.Quantity);
                    end;
                end;
            ShowActualBudget::"Budgeted Amounts":
                begin
                    FilterItemAnalyViewBudgEntry(ItemStatisticsBuffer, ItemAnalysisViewBudgetEntry);
                    case ValueType of
                        ValueType::"Sales Amount":
                            PAGE.Run(0, ItemAnalysisViewBudgetEntry, ItemAnalysisViewBudgetEntry."Sales Amount");
                        ValueType::"Cost Amount":
                            PAGE.Run(0, ItemAnalysisViewBudgetEntry, ItemAnalysisViewBudgetEntry."Cost Amount");
                        ValueType::Quantity:
                            PAGE.Run(0, ItemAnalysisViewBudgetEntry, ItemAnalysisViewBudgetEntry.Quantity);
                    end;
                end;
        end;

        OnAfterDrillDownAmount(ItemAnalysisViewEntry, ItemStatisticsBuffer, ValueType, ShowActualBudget);
    end;

    procedure SetLineAndColumnDim(ItemAnalysisView: Record "Item Analysis View"; var LineDimCode: Text[30]; var LineDimType: Enum "Item Analysis Dimension Type"; var ColumnDimCode: Text[30]; var ColumnDimType: Enum "Item Analysis Dimension Type")
    var
        Item: Record Item;
    begin
        if (LineDimCode = '') and (ColumnDimCode = '') then begin
            LineDimCode := Item.TableCaption();
            ColumnDimCode := Text000;
        end;

        OnBeforeSetLineAndColumnDim(ItemAnalysisView, LineDimCode, LineDimType, ColumnDimCode, ColumnDimType);

        LineDimType := DimCodeToType(LineDimCode, ItemAnalysisView);
        ColumnDimType := DimCodeToType(ColumnDimCode, ItemAnalysisView);

        OnAfterSetLineAndColumnDim(ItemAnalysisView, LineDimCode, LineDimType, ColumnDimCode, ColumnDimType);
    end;

    procedure GetDimSelection(OldDimSelCode: Text[30]; var ItemAnalysisView: Record "Item Analysis View"): Text[30]
    var
        Item: Record Item;
        Location: Record Location;
        DimSelection: Page "Dimension Selection";
    begin
        DimSelection.InsertDimSelBuf(false, Item.TableCaption(), Item.TableCaption());
        DimSelection.InsertDimSelBuf(false, Location.TableCaption(), Location.TableCaption());
        DimSelection.InsertDimSelBuf(false, Text000, Text000);
        if ItemAnalysisView."Dimension 1 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemAnalysisView."Dimension 1 Code", '');
        if ItemAnalysisView."Dimension 2 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemAnalysisView."Dimension 2 Code", '');
        if ItemAnalysisView."Dimension 3 Code" <> '' then
            DimSelection.InsertDimSelBuf(false, ItemAnalysisView."Dimension 3 Code", '');

        OnGetDimSelectionOnBeforeDimSelectionRunModal(DimSelection, ItemAnalysisView);
        DimSelection.LookupMode := true;
        if DimSelection.RunModal() = ACTION::LookupOK then
            exit(DimSelection.GetDimSelCode());
        exit(OldDimSelCode);
    end;

    procedure ValidateLineDimTypeAndCode(ItemAnalysisView: Record "Item Analysis View"; var LineDimCode: Text[30]; var LineDimType: Enum "Item Analysis Dimension Type"; ColumnDimType: Enum "Item Analysis Dimension Type"; var InternalDateFilter: Text; var DateFilter: Text; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var PeriodInitialized: Boolean)
    begin
        if DimCodeNotAllowed(LineDimCode, ItemAnalysisView) then begin
            Message(Text003, LineDimCode);
            LineDimCode := '';
        end;
        LineDimType := DimCodeToType(LineDimCode, ItemAnalysisView);
        InternalDateFilter := ItemStatisticsBuffer.GetFilter("Date Filter");
        if (LineDimType <> LineDimType::Period) and (ColumnDimType <> ColumnDimType::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure ValidateColumnDimTypeAndCode(ItemAnalysisView: Record "Item Analysis View"; var ColumnDimCode: Text[30]; var ColumnDimType: Enum "Item Analysis Dimension Type"; LineDimType: Enum "Item Analysis Dimension Type"; var InternalDateFilter: Text; var DateFilter: Text; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var PeriodInitialized: Boolean)
    begin
        if DimCodeNotAllowed(ColumnDimCode, ItemAnalysisView) then begin
            Message(Text004, ColumnDimCode);
            ColumnDimCode := '';
        end;
        ColumnDimType := DimCodeToType(ColumnDimCode, ItemAnalysisView);
        InternalDateFilter := ItemStatisticsBuffer.GetFilter("Date Filter");
        if (ColumnDimType <> ColumnDimType::Period) and (LineDimType <> LineDimType::Period) then begin
            DateFilter := InternalDateFilter;
            if StrPos(DateFilter, '&') > 1 then
                DateFilter := CopyStr(DateFilter, 1, StrPos(DateFilter, '&') - 1);
        end else
            PeriodInitialized := false;
    end;

    procedure FormatToAmount(var AmountAsText: Text[250]; RoundingFactor: Enum "Analysis Rounding Factor")
    var
        Amount: Decimal;
    begin
        if (AmountAsText = '') or (RoundingFactor = RoundingFactor::None) then
            exit;
        Evaluate(Amount, AmountAsText);
        Amount := MatrixMgt.RoundAmount(Amount, RoundingFactor);
        if Amount = 0 then
            AmountAsText := ''
        else
            case RoundingFactor of
                RoundingFactor::"1":
                    AmountAsText := Format(Amount);
                RoundingFactor::"1000", RoundingFactor::"1000000":
                    AmountAsText := Format(Amount, 0, Text001);
            end;
    end;

    procedure FindRecord(var ItemAnalysisView: Record "Item Analysis View"; DimType: Enum "Item Analysis Dimension Type"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; ItemFilter: Code[250]; LocationFilter: Code[250]; PeriodType: Enum "Analysis Period Type"; var DateFilter: Text[30]; var PeriodInitialized: Boolean; InternalDateFilter: Text[30]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]): Boolean
    var
        Item: Record Item;
        Location: Record Location;
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
        Found: Boolean;
    begin
        OnBeforeFindRecord(DimType, DimVal);
        case DimType of
            DimType::Item:
                begin
                    Item."No." := DimCodeBuf.Code;
                    if ItemFilter <> '' then
                        Item.SetFilter("No.", ItemFilter);
                    Found := Item.Find(Which);
                    if Found then
                        CopyItemToBuf(Item, DimCodeBuf);
                end;
            DimType::Period:
                begin
                    if not PeriodInitialized then
                        DateFilter := '';
                    PeriodInitialized := true;
                    Period."Period Start" := DimCodeBuf."Period Start";
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter)
                    else
                        if InternalDateFilter <> '' then
                            Period.SetFilter("Period Start", InternalDateFilter);
                    Found := PeriodPageMgt.FindDate(Which, Period, PeriodType);
                    if Found then
                        CopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
                end;
            DimType::Location:
                begin
                    Location.Code := CopyStr(DimCodeBuf.Code, 1, MaxStrLen(Location.Code));
                    if LocationFilter <> '' then
                        Location.SetFilter(Code, LocationFilter);
                    Found := Location.Find(Which);
                    if Found then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
            DimType::"Dimension 1":
                begin
                    if Dim1Filter <> '' then
                        DimVal.SetFilter(Code, Dim1Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Dimension 2":
                begin
                    if Dim2Filter <> '' then
                        DimVal.SetFilter(Code, Dim2Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Dimension 3":
                begin
                    if Dim3Filter <> '' then
                        DimVal.SetFilter(Code, Dim3Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    Found := DimVal.Find(Which);
                    if Found then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            else
                OnFindRecordCaseElse(ItemAnalysisView, DimType, DimCodeBuf, Which, ItemFilter, Found);
        end;
        exit(Found);
    end;

    procedure NextRecord(var ItemAnalysisView: Record "Item Analysis View"; DimType: Enum "Item Analysis Dimension Type"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; ItemFilter: Code[250]; LocationFilter: Code[250]; PeriodType: Enum "Analysis Period Type"; DateFilter: Text[30]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]): Integer
    var
        Item: Record Item;
        Location: Record Location;
        Period: Record Date;
        DimVal: Record "Dimension Value";
        PeriodPageMgt: Codeunit PeriodPageManagement;
        ResultSteps: Integer;
    begin
        OnBeforeNextRecord(DimType, DimVal);
        case DimType of
            DimType::Item:
                begin
                    Item."No." := DimCodeBuf.Code;
                    if ItemFilter <> '' then
                        Item.SetFilter("No.", ItemFilter);
                    ResultSteps := Item.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyItemToBuf(Item, DimCodeBuf);
                end;
            DimType::Period:
                begin
                    if DateFilter <> '' then
                        Period.SetFilter("Period Start", DateFilter);
                    Period."Period Start" := DimCodeBuf."Period Start";
                    ResultSteps := PeriodPageMgt.NextDate(Steps, Period, PeriodType);
                    if ResultSteps <> 0 then
                        CopyPeriodToBuf(Period, DimCodeBuf, DateFilter);
                end;
            DimType::Location:
                begin
                    Location.Code := CopyStr(DimCodeBuf.Code, 1, MaxStrLen(Location.Code));
                    if LocationFilter <> '' then
                        Location.SetFilter(Code, LocationFilter);
                    ResultSteps := Location.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyLocationToBuf(Location, DimCodeBuf);
                end;
            DimType::"Dimension 1":
                begin
                    if Dim1Filter <> '' then
                        DimVal.SetFilter(Code, Dim1Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 1 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Dimension 2":
                begin
                    if Dim2Filter <> '' then
                        DimVal.SetFilter(Code, Dim2Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 2 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            DimType::"Dimension 3":
                begin
                    if Dim3Filter <> '' then
                        DimVal.SetFilter(Code, Dim3Filter);
                    DimVal."Dimension Code" := ItemAnalysisView."Dimension 3 Code";
                    DimVal.SetRange("Dimension Code", DimVal."Dimension Code");
                    DimVal.Code := DimCodeBuf.Code;
                    ResultSteps := DimVal.Next(Steps);
                    if ResultSteps <> 0 then
                        CopyDimValueToBuf(DimVal, DimCodeBuf);
                end;
            else
                OnNextRecordOnCaseElse(ItemAnalysisView, DimType, DimCodeBuf, Steps, ItemFilter, ResultSteps);
        end;
        exit(ResultSteps);
    end;

    procedure GetCaptionClass(AnalysisViewDimType: Integer; ItemAnalysisView: Record "Item Analysis View"): Text[250]
    begin
        case AnalysisViewDimType of
            1:
                begin
                    if ItemAnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + ItemAnalysisView."Dimension 1 Code");
                    exit(Text005);
                end;
            2:
                begin
                    if ItemAnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + ItemAnalysisView."Dimension 2 Code");
                    exit(Text006);
                end;
            3:
                begin
                    if ItemAnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + ItemAnalysisView."Dimension 3 Code");
                    exit(Text007);
                end;
        end;
    end;

    procedure CalculateAmount(ValueType: Enum "Item Analysis Value Type"; SetColumnFilter: Boolean; CurrentAnalysisArea: Enum "Analysis Area Type"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10]; ItemFilter: Code[250]; LocationFilter: Code[250]; DateFilter: Text[30]; BudgetFilter: Code[250]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; LineDimType: Enum "Item Analysis Dimension Type"; LineDimCodeBuf: Record "Dimension Code Buffer"; ColDimType: Enum "Item Analysis Dimension Type"; ColDimCodeBuf: Record "Dimension Code Buffer"; ShowActualBudget: Enum "Item Analysis Show Type"): Decimal
    var
        Amount: Decimal;
        ActualAmt: Decimal;
        BudgetAmt: Decimal;
    begin
        case ShowActualBudget of
            ShowActualBudget::"Actual Amounts":
                Amount :=
                  CalcActualAmount(
                    ValueType, SetColumnFilter,
                    CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                    ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                    Dim1Filter, Dim2Filter, Dim3Filter,
                    LineDimType, LineDimCodeBuf,
                    ColDimType, ColDimCodeBuf);
            ShowActualBudget::"Budgeted Amounts":
                Amount :=
                  CalcBudgetAmount(
                    ValueType, SetColumnFilter,
                    CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                    ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                    Dim1Filter, Dim2Filter, Dim3Filter,
                    LineDimType, LineDimCodeBuf,
                    ColDimType, ColDimCodeBuf);
            ShowActualBudget::Variance:
                begin
                    ActualAmt :=
                      CalcActualAmount(
                        ValueType, SetColumnFilter,
                        CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                        Dim1Filter, Dim2Filter, Dim3Filter,
                        LineDimType, LineDimCodeBuf,
                        ColDimType, ColDimCodeBuf);
                    BudgetAmt :=
                      CalcBudgetAmount(
                        ValueType, SetColumnFilter,
                        CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                        Dim1Filter, Dim2Filter, Dim3Filter,
                        LineDimType, LineDimCodeBuf,
                        ColDimType, ColDimCodeBuf);
                    Amount := ActualAmt - BudgetAmt;
                end;
            ShowActualBudget::"Variance%":
                begin
                    Amount :=
                      CalcBudgetAmount(
                        ValueType, SetColumnFilter,
                        CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                        Dim1Filter, Dim2Filter, Dim3Filter,
                        LineDimType, LineDimCodeBuf,
                        ColDimType, ColDimCodeBuf);
                    if Amount <> 0 then begin
                        ActualAmt :=
                          CalcActualAmount(
                            ValueType, SetColumnFilter,
                            CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                            ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                            Dim1Filter, Dim2Filter, Dim3Filter,
                            LineDimType, LineDimCodeBuf,
                            ColDimType, ColDimCodeBuf);
                        Amount := Round(100 * (ActualAmt - Amount) / Amount);
                    end;
                end;
            ShowActualBudget::"Index%":
                begin
                    Amount :=
                      CalcBudgetAmount(
                        ValueType, SetColumnFilter,
                        CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                        Dim1Filter, Dim2Filter, Dim3Filter,
                        LineDimType, LineDimCodeBuf,
                        ColDimType, ColDimCodeBuf);
                    ActualAmt :=
                      CalcActualAmount(
                        ValueType, SetColumnFilter,
                        CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
                        ItemFilter, LocationFilter, DateFilter, BudgetFilter,
                        Dim1Filter, Dim2Filter, Dim3Filter,
                        LineDimType, LineDimCodeBuf,
                        ColDimType, ColDimCodeBuf);
                    if Amount <> 0 then
                        Amount := Round(100 * ActualAmt / Amount);
                end;
        end;

        OnAfterCalcActualAmount(ValueType.AsInteger(), ItemStatisticsBuffer, CurrentItemAnalysisViewCode, Amount);
        exit(Amount);
    end;

    local procedure CalcActualAmount(ValueType: Enum "Item Analysis Value Type"; SetColumnFilter: Boolean; CurrentAnalysisArea: Enum "Analysis Area Type"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10]; ItemFilter: Code[250]; LocationFilter: Code[250]; DateFilter: Text[30]; BudgetFilter: Code[250]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; LineDimType: Enum "Item Analysis Dimension Type"; LineDimCodeBuf: Record "Dimension Code Buffer"; ColDimType: Enum "Item Analysis Dimension Type"; ColDimCodeBuf: Record "Dimension Code Buffer"): Decimal
    var
        Amount: Decimal;
    begin
        SetBufferFilters(
          CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
          ItemFilter, LocationFilter, DateFilter, Dim1Filter, Dim2Filter, Dim3Filter, BudgetFilter);

        SetDimFilters(ItemStatisticsBuffer, LineDimType, LineDimCodeBuf);
        if SetColumnFilter then
            SetDimFilters(ItemStatisticsBuffer, ColDimType, ColDimCodeBuf)
        else
            case ColDimType of
                ColDimType::"Dimension 1":
                    ItemStatisticsBuffer.SetRange("Dimension 1 Filter");
                ColDimType::"Dimension 2":
                    ItemStatisticsBuffer.SetRange("Dimension 2 Filter");
                ColDimType::"Dimension 3":
                    ItemStatisticsBuffer.SetRange("Dimension 3 Filter");
            end;

        case ValueType of
            ValueType::"Sales Amount":
                begin
                    ItemStatisticsBuffer.CalcFields("Analysis - Sales Amt. (Actual)", "Analysis - Sales Amt. (Exp)");
                    Amount :=
                      ItemStatisticsBuffer."Analysis - Sales Amt. (Actual)" +
                      ItemStatisticsBuffer."Analysis - Sales Amt. (Exp)";
                end;
            ValueType::"Cost Amount":
                begin
                    ItemStatisticsBuffer.CalcFields(
                      "Analysis - Cost Amt. (Actual)",
                      "Analysis - Cost Amt. (Exp)",
                      "Analysis CostAmt.(Non-Invtbl.)");
                    Amount :=
                      ItemStatisticsBuffer."Analysis - Cost Amt. (Actual)" +
                      ItemStatisticsBuffer."Analysis - Cost Amt. (Exp)" +
                      ItemStatisticsBuffer."Analysis CostAmt.(Non-Invtbl.)";
                end;
            ValueType::Quantity:
                begin
                    ItemStatisticsBuffer.CalcFields("Analysis - Quantity");
                    Amount := ItemStatisticsBuffer."Analysis - Quantity";
                end;
        end;

        exit(Amount);
    end;

    local procedure CalcBudgetAmount(ValueType: Enum "Item Analysis Value Type"; SetColumnFilter: Boolean; CurrentAnalysisArea: Enum "Analysis Area Type"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10]; ItemFilter: Code[250]; LocationFilter: Code[250]; DateFilter: Text[30]; BudgetFilter: Code[250]; Dim1Filter: Code[250]; Dim2Filter: Code[250]; Dim3Filter: Code[250]; LineDimType: Enum "Item Analysis Dimension Type"; LineDimCodeBuf: Record "Dimension Code Buffer"; ColDimType: Enum "Item Analysis Dimension Type"; ColDimCodeBuf: Record "Dimension Code Buffer"): Decimal
    var
        Amount: Decimal;
    begin
        SetBufferFilters(
          CurrentAnalysisArea, ItemStatisticsBuffer, CurrentItemAnalysisViewCode,
          ItemFilter, LocationFilter, DateFilter, Dim1Filter, Dim2Filter, Dim3Filter, BudgetFilter);

        SetDimFilters(ItemStatisticsBuffer, LineDimType, LineDimCodeBuf);
        if SetColumnFilter then
            SetDimFilters(ItemStatisticsBuffer, ColDimType, ColDimCodeBuf);

        case ValueType of
            ValueType::"Sales Amount":
                begin
                    ItemStatisticsBuffer.CalcFields("Analysis - Budgeted Sales Amt.");
                    Amount := ItemStatisticsBuffer."Analysis - Budgeted Sales Amt.";
                end;
            ValueType::"Cost Amount":
                begin
                    ItemStatisticsBuffer.CalcFields("Analysis - Budgeted Cost Amt.");
                    Amount := ItemStatisticsBuffer."Analysis - Budgeted Cost Amt.";
                end;
            ValueType::Quantity:
                begin
                    ItemStatisticsBuffer.CalcFields("Analysis - Budgeted Quantity");
                    Amount := ItemStatisticsBuffer."Analysis - Budgeted Quantity";
                end;
            else
                OnCalcBudgetAmountOnValueTypeCaseElse(ValueType, ItemStatisticsBuffer, CurrentItemAnalysisViewCode, Amount);
        end;

        exit(Amount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLineAndColumnDim(ItemAnalysisView: Record "Item Analysis View"; var LineDimCode: Text[30]; var LineDimType: Enum "Item Analysis Dimension Type"; var ColumnDimCode: Text[30]; var ColumnDimType: Enum "Item Analysis Dimension Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLineAndColumnDim(ItemAnalysisView: Record "Item Analysis View"; var LineDimCode: Text[30]; var LineDimType: Enum "Item Analysis Dimension Type"; var ColumnDimCode: Text[30]; var ColumnDimType: Enum "Item Analysis Dimension Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemAnalysisView(CurrentAnalysisArea: Option; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcActualAmount(ValueType: Option "Sales Amount","Cost Amount",Quantity; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10]; var Amount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupDimCode(DimType: Enum "Item Analysis Dimension Type"; DimCode: Text[30]; "Code": Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCommonFilters(CurrentAnalysisArea: Enum "Analysis Area Type"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentAnalysisViewCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDimFilters(var ItemStatisticsBuffer: Record "Item Statistics Buffer"; DimType: Enum "Item Analysis Dimension Type"; DimCodeBuffer: Record "Dimension Code Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterItemAnalyViewEntry(var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var ItemAnalysisViewEntry: Record "Item Analysis View Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterItemAnalyViewBudgEntry(var ItemStatisticsBuffer: Record "Item Statistics Buffer"; var ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDimCodeToType(DimCode: Text[30]; ItemAnalysisView: Record "Item Analysis View"; var Result: Enum "Item Analysis Dimension Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDimCodeNotAllowed(DimCode: Text[30]; ItemAnalysisView: Record "Item Analysis View"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecord(DimType: Enum "Item Analysis Dimension Type"; var DimensionValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNextRecord(DimType: Enum "Item Analysis Dimension Type"; var DimensionValue: Record "Dimension Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordCaseElse(ItemAnalysisView: Record "Item Analysis View"; DimType: Enum "Item Analysis Dimension Type"; var DimCodeBuf: Record "Dimension Code Buffer"; Which: Text[250]; ItemFilter: Code[250]; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDimSelectionOnBeforeDimSelectionRunModal(var DimSelection: Page "Dimension Selection"; var ItemAnalysisView: Record "Item Analysis View")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNextRecordOnCaseElse(ItemAnalysisView: Record "Item Analysis View"; DimType: Enum "Item Analysis Dimension Type"; var DimCodeBuf: Record "Dimension Code Buffer"; Steps: Integer; ItemFilter: Code[250]; var ResultSteps: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyPeriodToBuf(var Period: Record Date; var DimensionCodeBuffer: Record "Dimension Code Buffer"; DateFilter: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDrillDownAmount(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; ItemStatisticsBuffer: Record "Item Statistics Buffer"; ItemAnalysisValueType: Enum "Item Analysis Value Type"; ItemAnalysisShowType: Enum "Item Analysis Show Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcBudgetAmountOnValueTypeCaseElse(ItemAnalysisValueType: Enum "Item Analysis Value Type"; var ItemStatisticsBuffer: Record "Item Statistics Buffer"; CurrentItemAnalysisViewCode: Code[10]; var Amount: Decimal)
    begin
    end;
}

