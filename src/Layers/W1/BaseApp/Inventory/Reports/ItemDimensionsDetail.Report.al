// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using System.Text;
using System.Utilities;

report 7150 "Item Dimensions - Detail"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemDimensionsDetail.rdlc';
    ApplicationArea = Dimensions;
    Caption = 'Item Dimensions - Detail';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Item Analysis View"; "Item Analysis View")
        {
            DataItemTableView = sorting("Analysis Area", Code);
            column(ViewLastUpdatedText; ViewLastUpdatedText)
            {
            }
            column(Name_ItemAnalysisView; Name)
            {
            }
            column(Code_ItemAnalysisView; Code)
            {
            }
            column(DateFilter; DateFilter)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(DimFilterText; DimFilterText)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(AnalysisViewCaption; AnalysisViewCaptionLbl)
            {
            }
            column(LastDateUpdatedCaption; LastDateUpdatedCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(ItemDimsDetailCptn; ItemDimsDetailCptnLbl)
            {
            }
            column(FiltersCaption; FiltersCaptionLbl)
            {
            }
            column(CostAmtCaption; CostAmtCaptionLbl)
            {
            }
            column(SalesAmtCaption; SalesAmtCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(ItemNoCaption; ItemNoCaptionLbl)
            {
            }
            column(EntryNoCaption; EntryNoCaptionLbl)
            {
            }
            column(QuantityCaption; QuantityCaptionLbl)
            {
            }
            dataitem(Level1; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(DimValCode1; DimValCode[1])
                {
                }
                column(DimCode1; DimCode[1])
                {
                }
                column(DimValName1; DimValName[1])
                {
                }
                dataitem(Level2; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(DimValCode2; DimValCode[2])
                    {
                    }
                    column(DimCode2; DimCode[2])
                    {
                    }
                    column(DimValName2; DimValName[2])
                    {
                    }
                    column(TempValueEntryItemNo; TempValueEntry."Item No.")
                    {
                    }
                    column(TempValueEntryPostingDate; Format(TempValueEntry."Posting Date"))
                    {
                    }
                    column(TempValueEntryDescription; TempValueEntry.Description)
                    {
                    }
                    column(TempValEntrySaleAmtActExp; TempValueEntry."Sales Amount (Actual)" + TempValueEntry."Sales Amount (Expected)")
                    {
                    }
                    column(TVECostAmtActExpNonInvtbl; TempValueEntry."Cost Amount (Actual)" + TempValueEntry."Cost Amount (Expected)" + TempValueEntry."Cost Amount (Non-Invtbl.)")
                    {
                    }
                    column(TempValueEntryEntryNo; TempValueEntry."Entry No.")
                    {
                    }
                    column(TempValueEntryValuedQty; TempValueEntry."Valued Quantity")
                    {
                        DecimalPlaces = 0 : 5;
                    }
                    dataitem(Level3; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(DimValCode3; DimValCode[3])
                        {
                        }
                        column(DimCode3; DimCode[3])
                        {
                        }
                        column(DimValName3; DimValName[3])
                        {
                        }
                        dataitem(Level4; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(DimValCode4; DimValCode[4])
                            {
                            }
                            column(DimCode4; DimCode[4])
                            {
                            }
                            column(DimValName4; DimValName[4])
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if DimCode[4] <> '' then begin
                                    if not CalcLine(4) and not PrintEmptyLines then
                                        CurrReport.Skip();
                                end else
                                    if not PrintDetail(4) then
                                        CurrReport.Break();
                            end;

                            trigger OnPreDataItem()
                            begin
                                if DimCode[3] = '' then
                                    CurrReport.Break();
                                FindFirstDim[4] := true;
                                FindFirstValueEntry[4] := true;
                            end;
                        }
                        dataitem(Level3e; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = const(1));
                            column(SalesAmtTotal3; SalesAmtTotal[3])
                            {
                                AutoFormatType = 1;
                            }
                            column(CostAmtTotal3; CostAmtTotal[3])
                            {
                                AutoFormatType = 1;
                            }
                            column(QtyTotal3; QtyTotal[3])
                            {
                                AutoFormatType = 1;
                                DecimalPlaces = 0 : 5;
                            }

                            trigger OnPostDataItem()
                            begin
                                SalesAmtTotal[3] := 0;
                                CostAmtTotal[3] := 0;
                                QtyTotal[3] := 0;
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if DimCode[3] <> '' then begin
                                if not CalcLine(3) and not PrintEmptyLines then
                                    CurrReport.Skip();
                            end else
                                if not PrintDetail(3) then
                                    CurrReport.Break();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if DimCode[2] = '' then
                                CurrReport.Break();
                            FindFirstDim[3] := true;
                            FindFirstValueEntry[3] := true;
                        end;
                    }
                    dataitem(Level2e; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(SalesAmtTotal2; SalesAmtTotal[2])
                        {
                            AutoFormatType = 1;
                        }
                        column(CostAmtTotal2; CostAmtTotal[2])
                        {
                            AutoFormatType = 1;
                        }
                        column(QtyTotal2; QtyTotal[2])
                        {
                            AutoFormatType = 1;
                            DecimalPlaces = 0 : 5;
                        }

                        trigger OnPostDataItem()
                        begin
                            SalesAmtTotal[2] := 0;
                            CostAmtTotal[2] := 0;
                            QtyTotal[2] := 0;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if DimCode[2] <> '' then begin
                            if not CalcLine(2) and not PrintEmptyLines then
                                CurrReport.Skip();
                        end else
                            if not PrintDetail(2) then
                                CurrReport.Break();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if DimCode[1] = '' then
                            CurrReport.Break();
                        FindFirstDim[2] := true;
                        FindFirstValueEntry[2] := true;
                    end;
                }
                dataitem(Level1e; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CostAmtTotal1; CostAmtTotal[1])
                    {
                        AutoFormatType = 1;
                    }
                    column(SalesAmtTotal1; SalesAmtTotal[1])
                    {
                        AutoFormatType = 1;
                    }
                    column(QtyTotal1; QtyTotal[1])
                    {
                        AutoFormatType = 1;
                        DecimalPlaces = 0 : 5;
                    }

                    trigger OnPostDataItem()
                    begin
                        SalesAmtTotal[1] := 0;
                        CostAmtTotal[1] := 0;
                        QtyTotal[1] := 0;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not CalcLine(1) and not PrintEmptyLines then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if DimCode[1] = '' then
                        CurrReport.Break();
                    FindFirstDim[1] := true;
                    FindFirstValueEntry[1] := true;
                end;
            }

            trigger OnAfterGetRecord()
            var
                AccountingPeriod: Record "Accounting Period";
                i: Integer;
                StartDate: Date;
                EndDate: Date;
                ThisFilter: Text[250];
            begin
                if "Last Date Updated" <> 0D then
                    ViewLastUpdatedText :=
                      StrSubstNo('%1', "Last Date Updated")
                else
                    ViewLastUpdatedText := Text004;

                ItemAnalysisViewEntry.Reset();
                ItemAnalysisViewEntry.SetRange("Analysis Area", "Analysis Area");
                ItemAnalysisViewEntry.SetRange("Analysis View Code", Code);
                ItemAnalysisViewEntry.SetFilter("Posting Date", DateFilter);
                StartDate := ItemAnalysisViewEntry.GetRangeMin("Posting Date");
                EndDate := ItemAnalysisViewEntry.GetRangeMax("Posting Date");
                case "Date Compression" of
                    "Date Compression"::Week:
                        begin
                            StartDate := CalcDate('<CW+1D-1W>', StartDate);
                            EndDate := ClosingDate(CalcDate('<CW>', EndDate));
                        end;
                    "Date Compression"::Month:
                        begin
                            StartDate := CalcDate('<CM+1D-1M>', StartDate);
                            EndDate := ClosingDate(CalcDate('<CM>', EndDate));
                        end;
                    "Date Compression"::Quarter:
                        begin
                            StartDate := CalcDate('<CQ+1D-1Q>', StartDate);
                            EndDate := ClosingDate(CalcDate('<CQ>', EndDate));
                        end;
                    "Date Compression"::Year:
                        begin
                            StartDate := CalcDate('<CY+1D-1Y>', StartDate);
                            EndDate := ClosingDate(CalcDate('<CY>', EndDate));
                        end;
                    "Date Compression"::Period:
                        begin
                            AccountingPeriod.SetRange("Starting Date", 0D, StartDate);
                            if AccountingPeriod.Find('+') then
                                StartDate := AccountingPeriod."Starting Date";
                            AccountingPeriod.SetRange("Starting Date", EndDate, DMY2Date(31, 12, 9999));
                            if AccountingPeriod.Find('-') then
                                if AccountingPeriod.Next() <> 0 then
                                    EndDate := ClosingDate(AccountingPeriod."Starting Date" - 1);
                        end;
                end;
                ItemAnalysisViewEntry.SetRange("Posting Date", StartDate, EndDate);

                ItemAnalysisViewEntry.FilterGroup(2);
                TempAnalysisSelectedDim.Reset();
                TempAnalysisSelectedDim.SetCurrentKey(
                  "User ID", "Object Type", "Object ID", "Analysis Area", "Analysis View Code", Level);
                TempAnalysisSelectedDim.SetFilter("Dimension Value Filter", '<>%1', '');
                DimFilterText := '';
                if TempAnalysisSelectedDim.Find('-') then
                    repeat
                        ThisFilter := '';
                        if DimFilterText <> '' then
                            ThisFilter := ', ';
                        ThisFilter :=
                          ThisFilter +
                          TempAnalysisSelectedDim."Dimension Code" + ': ' +
                          TempAnalysisSelectedDim."Dimension Value Filter";
                        if StrLen(DimFilterText) + StrLen(ThisFilter) <= 250 then
                            DimFilterText := DimFilterText + ThisFilter;
                        SetItemAnalysisViewEntryFilter(
                          TempAnalysisSelectedDim."Dimension Code", TempAnalysisSelectedDim."Dimension Value Filter");
                    until TempAnalysisSelectedDim.Next() = 0;
                ItemAnalysisViewEntry.FilterGroup(0);

                TempAnalysisSelectedDim.Reset();
                TempAnalysisSelectedDim.SetCurrentKey(
                  "User ID", "Object Type", "Object ID", "Analysis Area", "Analysis View Code", Level);
                TempAnalysisSelectedDim.SetFilter(Level, '<>%1', TempAnalysisSelectedDim.Level::" ");
                i := 1;
                if TempAnalysisSelectedDim.Find('-') then
                    repeat
                        DimCode[i] := TempAnalysisSelectedDim."Dimension Code";
                        LevelFilter[i] := TempAnalysisSelectedDim."Dimension Value Filter";
                        i := i + 1;
                    until (TempAnalysisSelectedDim.Next() = 0) or (i > 3);
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Analysis Area", AnalysisArea);
                SetRange(Code, ItemAnalysisViewCode);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Item Dimensions - Detail';
        AboutText = 'Build a grouping of dimensions for each permutation of dimension values, defined through a hierarchy of dimension levels from an analysis view, and list all GL entries for each group.';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(AnalysisArea; AnalysisArea)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Analysis Area';
                        ToolTip = 'Specifies if the analysis area is set up in the Sales, Purchasing, or Inventory application area.';

                        trigger OnValidate()
                        begin
                            ItemAnalysisViewCode := '';
                            UpdateColumnDim();
                        end;
                    }
                    field(AnalysisViewCode; ItemAnalysisViewCode)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Analysis View Code';
                        ToolTip = 'Specifies the code for the analysis view that the filter belongs to.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ItemAnalysisView: Record "Item Analysis View";
                        begin
                            ItemAnalysisView.FilterGroup := 2;
                            ItemAnalysisView.SetRange("Analysis Area", AnalysisArea);
                            ItemAnalysisView.FilterGroup := 0;
                            if PAGE.RunModal(0, ItemAnalysisView) = ACTION::LookupOK then begin
                                Text := ItemAnalysisView.Code;
                                UpdateColumnDim();
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        var
                            ItemAnalysisView: Record "Item Analysis View";
                        begin
                            if ItemAnalysisViewCode <> '' then
                                ItemAnalysisView.Get(AnalysisArea, ItemAnalysisViewCode);
                            UpdateColumnDim();
                        end;
                    }
                    field(IncludeDimensions; ColumnDim)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Include Dimensions';
                        Editable = false;
                        ToolTip = 'Specifies the dimensions that you want to include in the report. You can only select dimensions included in the analysis view that you selected in the Analysis View field.';

                        trigger OnAssistEdit()
                        begin
                            AnalysisDimSelectionBuf.SetDimSelectionLevel(
                              3, REPORT::"Item Dimensions - Detail", AnalysisArea.AsInteger(), ItemAnalysisViewCode, ColumnDim);
                        end;
                    }
                    field(DateFilterCtrl; DateFilter)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Date Filter';
                        ToolTip = 'Specifies a filter, that will filter entries by date. You can enter a particular date or a time interval.';

                        trigger OnValidate()
                        var
                            FilterTokens: Codeunit "Filter Tokens";
                        begin
                            FilterTokens.MakeDateFilter(DateFilter);
                            TempItem.SetFilter("Date Filter", DateFilter);
                            DateFilter := TempItem.GetFilter("Date Filter");
                        end;
                    }
                    field(PrintEmptyLines; PrintEmptyLines)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Print Empty Lines';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the report to include dimensions and dimension values that have a balance equal to zero.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            UpdateColumnDim();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        AnalysisSelectedDim: Record "Analysis Selected Dimension";
    begin
        if ItemAnalysisViewCode = '' then
            Error(Text000);

        if DateFilter = '' then
            Error(Text001);

        AnalysisDimSelectionBuf.CompareDimText(
          3, REPORT::"Item Dimensions - Detail", AnalysisArea.AsInteger(), ItemAnalysisViewCode, ColumnDim, Text002);

        TempAnalysisSelectedDim.Reset();
        TempAnalysisSelectedDim.SetFilter("Dimension Value Filter", '<>%1', '');
        TempAnalysisSelectedDim.SetFilter("Dimension Code", TempItem.TableCaption());
        if TempAnalysisSelectedDim.Find('-') then
            Item.SetFilter("No.", TempAnalysisSelectedDim."Dimension Value Filter");
        if Item.Find('-') then
            repeat
                TempItem.Init();
                TempItem := Item;
                TempItem.Insert();
            until Item.Next() = 0;

        TempLocation.Init();
        TempLocation.Insert();
        TempAnalysisSelectedDim.SetFilter("Dimension Code", Location.TableCaption());
        if TempAnalysisSelectedDim.Find('-') then
            Location.SetFilter(Code, TempAnalysisSelectedDim."Dimension Value Filter");
        if Location.Find('-') then
            repeat
                TempLocation.Init();
                TempLocation := Location;
                TempLocation.Insert();
            until Location.Next() = 0;

        AnalysisSelectedDim.GetSelectedDim(
          UserId, 3, REPORT::"Item Dimensions - Detail", AnalysisArea.AsInteger(), ItemAnalysisViewCode, TempAnalysisSelectedDim);
        TempAnalysisSelectedDim.Reset();
        TempAnalysisSelectedDim.SetCurrentKey(
          "User ID", "Object Type", "Object ID", "Analysis Area", "Analysis View Code", Level);
        TempAnalysisSelectedDim.SetFilter(Level, '<>%1', TempAnalysisSelectedDim.Level::" ");
        DimVal.SetRange("Dimension Value Type", DimVal."Dimension Value Type"::Standard);
        if TempAnalysisSelectedDim.Find('-') then
            repeat
                TempDimVal.Init();
                TempDimVal.Code := '';
                TempDimVal."Dimension Code" := TempAnalysisSelectedDim."Dimension Code";
                TempDimVal.Name := Text003;
                TempDimVal.Insert();
                DimVal.SetRange("Dimension Code", TempAnalysisSelectedDim."Dimension Code");
                if TempAnalysisSelectedDim."Dimension Value Filter" <> '' then
                    DimVal.SetFilter(Code, TempAnalysisSelectedDim."Dimension Value Filter")
                else
                    DimVal.SetRange(Code);
                if DimVal.Find('-') then
                    repeat
                        TempDimVal.Init();
                        TempDimVal := DimVal;
                        TempDimVal.Insert();
                    until DimVal.Next() = 0;
            until TempAnalysisSelectedDim.Next() = 0;
    end;

    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        TempAnalysisSelectedDim: Record "Analysis Selected Dimension" temporary;
        Item: Record Item;
        Location: Record Location;
        DimVal: Record "Dimension Value";
        TempValueEntry: Record "Value Entry" temporary;
        TempItem: Record Item temporary;
        TempLocation: Record Location temporary;
        TempDimVal: Record "Dimension Value" temporary;
        AnalysisDimSelectionBuf: Record "Analysis Dim. Selection Buffer";
        PrintEmptyLines: Boolean;
        ViewLastUpdatedText: Text[30];
        ColumnDim: Text[250];
        AnalysisArea: Enum "Analysis Area Type";
        ItemAnalysisViewCode: Code[10];
        DateFilter: Text;
        FindFirstDim: array[4] of Boolean;
        FindFirstValueEntry: array[4] of Boolean;
        DimCode: array[4] of Text[30];
        DimValCode: array[4] of Code[20];
        DimValName: array[4] of Text[100];
        LevelFilter: array[3] of Text[250];
        SalesAmtTotal: array[3] of Decimal;
        CostAmtTotal: array[3] of Decimal;
        QtyTotal: array[3] of Decimal;
        DimFilterText: Text[250];

#pragma warning disable AA0074
        Text000: Label 'Enter an analysis view code.';
        Text001: Label 'Enter a date filter.';
        Text002: Label 'Include Dimensions';
        Text003: Label '(no dimension value)';
        Text004: Label 'Not updated';
        Text014: Label '(no location code)';
#pragma warning restore AA0074
        PeriodCaptionLbl: Label 'Period';
        AnalysisViewCaptionLbl: Label 'Analysis View';
        LastDateUpdatedCaptionLbl: Label 'Last Date Updated';
        PageCaptionLbl: Label 'Page';
        ItemDimsDetailCptnLbl: Label 'Item Dimensions - Detail';
        FiltersCaptionLbl: Label 'Filters';
        CostAmtCaptionLbl: Label 'Cost Amount';
        SalesAmtCaptionLbl: Label 'Sales Amount';
        DescriptionCaptionLbl: Label 'Description';
        PostingDateCaptionLbl: Label 'Posting Date';
        ItemNoCaptionLbl: Label 'Item No.';
        EntryNoCaptionLbl: Label 'Entry No.';
        QuantityCaptionLbl: Label 'Quantity';

    local procedure CalcLine(Level: Integer): Boolean
    var
        HasEntries: Boolean;
        i: Integer;
    begin
        if Level < 3 then
            for i := Level + 1 to 3 do
                SetItemAnalysisViewEntryFilter(DimCode[i], '*');
        if Iteration(
             FindFirstDim[Level], DimCode[Level], DimValCode[Level], DimValName[Level], LevelFilter[Level])
        then begin
            SetItemAnalysisViewEntryFilter(DimCode[Level], DimValCode[Level]);
            HasEntries := ItemAnalysisViewEntry.Find('-');
        end else
            CurrReport.Break();
        exit(HasEntries);
    end;

    local procedure PrintDetail(Level: Integer): Boolean
    var
        ItemAViewEntryToValueEntries: Codeunit ItemAViewEntryToValueEntries;
    begin
        if FindFirstValueEntry[Level] then begin
            FindFirstValueEntry[Level] := false;
            TempValueEntry.Reset();
            TempValueEntry.DeleteAll();
            if ItemAnalysisViewEntry.Find('-') then
                repeat
                    ItemAViewEntryToValueEntries.GetValueEntries(ItemAnalysisViewEntry, TempValueEntry);
                until ItemAnalysisViewEntry.Next() = 0;
            TempValueEntry.SetCurrentKey("Item No.", "Posting Date");
            TempValueEntry.SetFilter("Posting Date", DateFilter);
            if not TempValueEntry.Find('-') then
                exit(false);
        end else
            if TempValueEntry.Next() = 0 then
                exit(false);
        if Level > 1 then
            CalcTotalValues(Level - 1);
        exit(true);
    end;

    local procedure CalcTotalValues(Level: Integer)
    var
        i: Integer;
    begin
        for i := 1 to Level do begin
            SalesAmtTotal[i] :=
              SalesAmtTotal[i] +
              TempValueEntry."Sales Amount (Actual)" +
              TempValueEntry."Sales Amount (Expected)";
            CostAmtTotal[i] :=
              CostAmtTotal[i] +
              TempValueEntry."Cost Amount (Actual)" +
              TempValueEntry."Cost Amount (Expected)" +
              TempValueEntry."Cost Amount (Non-Invtbl.)";
            QtyTotal[i] :=
              QtyTotal[i] +
              TempValueEntry."Valued Quantity";
        end;
    end;

    local procedure UpdateColumnDim()
    var
        AnalysisSelectedDim: Record "Analysis Selected Dimension";
        TempAnalysisDimSelectionBuf: Record "Analysis Dim. Selection Buffer" temporary;
        ItemAnalysisView: Record "Item Analysis View";
    begin
        ItemAnalysisView.CopyAnalysisViewFilters(3, REPORT::"Item Dimensions - Detail", AnalysisArea.AsInteger(), ItemAnalysisViewCode);
        ColumnDim := '';
        AnalysisSelectedDim.SetRange("User ID", UserId);
        AnalysisSelectedDim.SetRange("Object Type", 3);
        AnalysisSelectedDim.SetRange("Object ID", REPORT::"Item Dimensions - Detail");
        AnalysisSelectedDim.SetRange("Analysis Area", AnalysisArea);
        AnalysisSelectedDim.SetRange("Analysis View Code", ItemAnalysisViewCode);
        if AnalysisSelectedDim.Find('-') then begin
            repeat
                TempAnalysisDimSelectionBuf.Init();
                TempAnalysisDimSelectionBuf.Code := AnalysisSelectedDim."Dimension Code";
                TempAnalysisDimSelectionBuf.Selected := true;
                TempAnalysisDimSelectionBuf."Dimension Value Filter" := AnalysisSelectedDim."Dimension Value Filter";
                TempAnalysisDimSelectionBuf.Level := AnalysisSelectedDim.Level;
                TempAnalysisDimSelectionBuf.Insert();
            until AnalysisSelectedDim.Next() = 0;
            TempAnalysisDimSelectionBuf.SetDimSelection(
              3, REPORT::"Item Dimensions - Detail", AnalysisArea.AsInteger(), ItemAnalysisViewCode, ColumnDim, TempAnalysisDimSelectionBuf);
        end;
    end;

    local procedure Iteration(var FindFirstRec: Boolean; IterationDimCode: Text[30]; var IterationDimValCode: Code[20]; var IterationDimValName: Text[100]; IterationFilter: Text[250]): Boolean
    var
        SearchResult: Boolean;
    begin
        case IterationDimCode of
            TempItem.TableCaption:
                begin
                    TempItem.Reset();
                    TempItem.SetFilter("No.", IterationFilter);
                    if FindFirstRec then
                        SearchResult := TempItem.Find('-')
                    else
                        if TempItem.Get(IterationDimValCode) then
                            SearchResult := TempItem.Next() <> 0;
                    if SearchResult then begin
                        IterationDimValCode := TempItem."No.";
                        IterationDimValName := TempItem.Description;
                    end;
                end;
            TempLocation.TableCaption:
                begin
                    TempLocation.Reset();
                    TempLocation.SetFilter(Code, IterationFilter);
                    if FindFirstRec then
                        SearchResult := TempLocation.Find('-')
                    else
                        if TempLocation.Get(IterationDimValCode) then
                            SearchResult := TempLocation.Next() <> 0;
                    if SearchResult then begin
                        IterationDimValCode := TempLocation.Code;
                        if TempLocation.Code <> '' then
                            IterationDimValName := TempLocation.Name
                        else
                            IterationDimValName := Text014;
                    end;
                end;
            else begin
                TempDimVal.Reset();
                TempDimVal.SetRange("Dimension Code", IterationDimCode);
                TempDimVal.SetFilter(Code, IterationFilter);
                if FindFirstRec then
                    SearchResult := TempDimVal.Find('-')
                else
                    if TempDimVal.Get(IterationDimCode, IterationDimValCode) then
                        SearchResult := TempDimVal.Next() <> 0;
                if SearchResult then begin
                    IterationDimValCode := TempDimVal.Code;
                    IterationDimValName := TempDimVal.Name;
                end;
            end;
        end;
        if not SearchResult then begin
            IterationDimValCode := '';
            IterationDimValName := '';
        end;
        FindFirstRec := false;
        exit(SearchResult);
    end;

    local procedure SetItemAnalysisViewEntryFilter(ItemAnalysisViewDimCode: Text[30]; ItemAnalysisViewFilter: Text[250])
    begin
        if ItemAnalysisViewFilter = '' then
            ItemAnalysisViewFilter := '''''';
        case ItemAnalysisViewDimCode of
            TempItem.TableCaption:
                if ItemAnalysisViewFilter = '*' then
                    ItemAnalysisViewEntry.SetRange("Item No.")
                else
                    ItemAnalysisViewEntry.SetFilter("Item No.", ItemAnalysisViewFilter);
            TempLocation.TableCaption:
                if ItemAnalysisViewFilter = '*' then
                    ItemAnalysisViewEntry.SetRange("Location Code")
                else
                    ItemAnalysisViewEntry.SetFilter("Location Code", ItemAnalysisViewFilter);
            "Item Analysis View"."Dimension 1 Code":
                if ItemAnalysisViewFilter = '*' then
                    ItemAnalysisViewEntry.SetRange("Dimension 1 Value Code")
                else
                    ItemAnalysisViewEntry.SetFilter("Dimension 1 Value Code", ItemAnalysisViewFilter);
            "Item Analysis View"."Dimension 2 Code":
                if ItemAnalysisViewFilter = '*' then
                    ItemAnalysisViewEntry.SetRange("Dimension 2 Value Code")
                else
                    ItemAnalysisViewEntry.SetFilter("Dimension 2 Value Code", ItemAnalysisViewFilter);
            "Item Analysis View"."Dimension 3 Code":
                if ItemAnalysisViewFilter = '*' then
                    ItemAnalysisViewEntry.SetRange("Dimension 3 Value Code")
                else
                    ItemAnalysisViewEntry.SetFilter("Dimension 3 Value Code", ItemAnalysisViewFilter);
        end;
    end;
}

