// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using System.Text;
using System.Utilities;

report 7151 "Item Dimensions - Total"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Reports/ItemDimensionsTotal.rdlc';
    ApplicationArea = Dimensions;
    Caption = 'Item Dimensions - Total';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Item Analysis View"; "Item Analysis View")
        {
            DataItemTableView = sorting("Analysis Area", Code);
            column(ViewLastUpdatedText; ViewLastUpdatedText)
            {
            }
            column(ItemAnalysisViewName; Name)
            {
            }
            column(AnalysisColumnTemplate; AnalysisColumnTemplate)
            {
            }
            column(ItemAnalysisViewCode; Code)
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
            column(Header5; Header[5])
            {
            }
            column(Header4; Header[4])
            {
            }
            column(Header3; Header[3])
            {
            }
            column(Header2; Header[2])
            {
            }
            column(Header1; Header[1])
            {
            }
            column(RoundingHeader5; RoundingHeader[5])
            {
                AutoCalcField = false;
            }
            column(RoundingHeader4; RoundingHeader[4])
            {
                AutoCalcField = false;
            }
            column(RoundingHeader3; RoundingHeader[3])
            {
                AutoCalcField = false;
            }
            column(RoundingHeader2; RoundingHeader[2])
            {
                AutoCalcField = false;
            }
            column(RoundingHeader1; RoundingHeader[1])
            {
                AutoCalcField = false;
            }
            column(ColumnTemplateCaption; ColumnTemplateCaptionLbl)
            {
            }
            column(PeriodCaption; PeriodCaptionLbl)
            {
            }
            column(AnalysisViewCaption; AnalysisViewCaptionLbl)
            {
            }
            column(LastUpdatedCaption; LastUpdatedCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(ItemDimensionsTotalCaption; ItemDimensionsTotalCaptionLbl)
            {
            }
            column(FiltersCaption; FiltersCaptionLbl)
            {
            }
            column(DimensionValueCaption; DimensionValueCaptionLbl)
            {
            }
            column(DimensionCaption; DimensionCaptionLbl)
            {
            }
            dataitem(Level1; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(ColumnValuesAsText51; ColumnValuesAsText[5, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText41; ColumnValuesAsText[4, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText31; ColumnValuesAsText[3, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText21; ColumnValuesAsText[2, 1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText11; ColumnValuesAsText[1, 1])
                {
                    AutoCalcField = false;
                }
                column(DimCode1; DimCode[1])
                {
                }
                column(DimValNameIndent12Name1; PadStr('', DimValNameIndent[1] * 2) + DimValName[1])
                {
                }
                column(Level1Body1ShowOutput; not (ShowBold[1] or (DimCode[2] <> '')))
                {
                }
                column(DimValCode1; DimValCode[1])
                {
                }
                column(Level1Body2ShowOutput; ShowBold[1] and (DimCode[2] = ''))
                {
                }
                column(Level1Body3ShowOutput; DimCode[2] <> '')
                {
                }
                dataitem(Level2; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ColumnValuesAsText52; ColumnValuesAsText[5, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText42; ColumnValuesAsText[4, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText32; ColumnValuesAsText[3, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText22; ColumnValuesAsText[2, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText12; ColumnValuesAsText[1, 2])
                    {
                        AutoCalcField = false;
                    }
                    column(DimValCode2; DimValCode[2])
                    {
                    }
                    column(DimCode2; DimCode[2])
                    {
                    }
                    column(DimValNmeIndnt22DimValNme2; PadStr('', DimValNameIndent[2] * 2) + DimValName[2])
                    {
                    }
                    column(Level2Body1ShowOutput; not (ShowBold[2] or (DimCode[3] <> '')))
                    {
                    }
                    column(Level2Body2ShowOutput; ShowBold[2] and (DimCode[3] = ''))
                    {
                    }
                    column(Level2Body3ShowOutput; DimCode[3] <> '')
                    {
                    }
                    dataitem(Level3; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ColumnValuesAsText53; ColumnValuesAsText[5, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText43; ColumnValuesAsText[4, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText33; ColumnValuesAsText[3, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText23; ColumnValuesAsText[2, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText13; ColumnValuesAsText[1, 3])
                        {
                            AutoCalcField = false;
                        }
                        column(DimValCode3; DimValCode[3])
                        {
                        }
                        column(DimCode3; DimCode[3])
                        {
                        }
                        column(DimValNmeIndnt32DimValNme3; PadStr('', DimValNameIndent[3] * 2) + DimValName[3])
                        {
                        }
                        column(Level3Body1ShowOutput; not (ShowBold[3] or (DimCode[4] <> '')))
                        {
                        }
                        column(Level3Body2ShowOutput; ShowBold[3] and (DimCode[4] = ''))
                        {
                        }
                        column(Level3Body3ShowOutput; DimCode[4] <> '')
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if not CalcLine(3) and not PrintEmptyLines then
                                CurrReport.Skip();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if DimCode[3] = '' then
                                CurrReport.Break();
                            FindFirstDim[3] := true;
                        end;
                    }
                    dataitem(Level2e; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(DimValNmeIndnt22DimValNme21; PadStr('', DimValNameIndent[2] * 2) + DimValName[2])
                        {
                        }
                        column(DimValCode2_Level2e; DimValCode[2])
                        {
                        }
                        column(ColumnValuesAsText12_Level2e; ColumnValuesAsText[1, 2])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText22_level2e; ColumnValuesAsText[2, 2])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText32_Level2e; ColumnValuesAsText[3, 2])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText42_Level2e; ColumnValuesAsText[4, 2])
                        {
                            AutoCalcField = false;
                        }
                        column(ColumnValuesAsText52_Level2e; ColumnValuesAsText[5, 2])
                        {
                            AutoCalcField = false;
                        }
                        column(DimCode2_Level2e; DimCode[2])
                        {
                        }
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not CalcLine(2) and not PrintEmptyLines then
                            CurrReport.Skip();
                    end;

                    trigger OnPreDataItem()
                    begin
                        if DimCode[2] = '' then
                            CurrReport.Break();
                        FindFirstDim[2] := true;
                    end;
                }
                dataitem(Level1e; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(DimValNmeIndnt12DimValNme12; PadStr('', DimValNameIndent[1] * 2) + DimValName[1])
                    {
                    }
                    column(DimValCode1_Level1e; DimValCode[1])
                    {
                    }
                    column(ColumnValuesAsText11_Level1e; ColumnValuesAsText[1, 1])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText21_Level1e; ColumnValuesAsText[2, 1])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText31_Level1e; ColumnValuesAsText[3, 1])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText41_Level1e; ColumnValuesAsText[4, 1])
                    {
                        AutoCalcField = false;
                    }
                    column(ColumnValuesAsText51_Level1e; ColumnValuesAsText[5, 1])
                    {
                        AutoCalcField = false;
                    }
                    column(DimCode1_Level1e; DimCode[1])
                    {
                    }
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
                end;
            }

            trigger OnAfterGetRecord()
            var
                i: Integer;
                ThisFilter: Text[250];
            begin
                if "Last Date Updated" <> 0D then
                    ViewLastUpdatedText :=
                      StrSubstNo('%1', "Last Date Updated")
                else
                    ViewLastUpdatedText := Text005;

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
                        SetAnalysisLineFilter(
                          TempAnalysisSelectedDim."Dimension Code", TempAnalysisSelectedDim."Dimension Value Filter", true, '');
                    until TempAnalysisSelectedDim.Next() = 0;

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
                    until (TempAnalysisSelectedDim.Next() = 0) or (i > 4);

                MaxColumnsDisplayed := ArrayLen(ColumnValuesDisplayed);
                NoOfCols := 0;
                AnalysisReportMgt.CopyColumnsToTemp(AnalysisLine, AnalysisColumnTemplate, TempAnalysisColumn);
                i := 0;
                if TempAnalysisColumn.Find('-') then begin
                    repeat
                        if TempAnalysisColumn.Show <> TempAnalysisColumn.Show::Never then begin
                            i := i + 1;
                            if i <= MaxColumnsDisplayed then begin
                                Header[i] := TempAnalysisColumn."Column Header";
                                RoundingHeader[i] := '';
                                if TempAnalysisColumn."Rounding Factor" in [TempAnalysisColumn."Rounding Factor"::"1000", TempAnalysisColumn."Rounding Factor"::"1000000"] then
                                    case TempAnalysisColumn."Rounding Factor" of
                                        TempAnalysisColumn."Rounding Factor"::"1000":
                                            RoundingHeader[i] := Text006;
                                        TempAnalysisColumn."Rounding Factor"::"1000000":
                                            RoundingHeader[i] := Text007;
                                    end;
                            end;
                        end;
                        NoOfCols := NoOfCols + 1;
                    until (i >= MaxColumnsDisplayed) or (TempAnalysisColumn.Next() = 0);
                    MaxColumnsDisplayed := i;
                end;
            end;

            trigger OnPreDataItem()
            begin
                Commit();
                SetRange("Analysis Area", AnalysisArea);
                SetRange(Code, ItemAnalysisViewCode);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Item Dimensions - Total';
        AboutText = 'Build a grouping of dimensions for each permutation of dimension values, defined through a hierarchy of dimension levels from an analysis view. View a total of inventory transactions for each group, with the ability to extend this to show user-defined period buckets, with different parameters, from item actual or budget entries.';
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
                        ToolTip = 'Specifies is the analysis area for the report is set up in the Sales, Purchasing, or Inventory application area.';

                        trigger OnValidate()
                        begin
                            ItemAnalysisViewCode := '';
                            UpdateColumnDim();
                            AnalysisColumnTemplate := '';
                            ItemBudgetName := '';
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
                              3, REPORT::"Item Dimensions - Total", AnalysisArea.AsInteger(), ItemAnalysisViewCode, ColumnDim);
                        end;
                    }
                    field(ColumnTemplate; AnalysisColumnTemplate)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Column Template';
                        ToolTip = 'Specifies the column template you want to use on the report. To select among the column templates you have set up, click the AssistButton to the right of the field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if AnalysisReportMgt.LookupAnalysisColumnName(AnalysisArea, AnalysisColumnTemplate) then begin
                                Text := AnalysisColumnTemplate;
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            AnalysisReportMgt.GetColumnTemplate(AnalysisArea.AsInteger(), AnalysisColumnTemplate);
                        end;
                    }
                    field(DateFilter; DateFilter)
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
                    field(ItemBudgetName; ItemBudgetName)
                    {
                        ApplicationArea = ItemBudget;
                        Caption = 'Item Budget Name';
                        ToolTip = 'Specifies the name of the budget to be shown in the window.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ItemBudgetNameTmp: Record "Item Budget Name";
                        begin
                            ItemBudgetNameTmp.FilterGroup := 2;
                            ItemBudgetNameTmp.SetRange("Analysis Area", AnalysisArea);
                            ItemBudgetNameTmp.FilterGroup := 0;
                            if PAGE.RunModal(0, ItemBudgetNameTmp) = ACTION::LookupOK then begin
                                Text := ItemBudgetNameTmp.Name;
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        var
                            ItemBudgetNameTmp: Record "Item Budget Name";
                        begin
                            if ItemBudgetName <> '' then
                                ItemBudgetNameTmp.Get(AnalysisArea, ItemBudgetName);
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
            if AnalysisColumnTemplateHidden <> '' then
                AnalysisColumnTemplate := AnalysisColumnTemplateHidden;

            UpdateColumnDim();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisSelectedDim: Record "Analysis Selected Dimension";
        TempEscapeFilterItem: Record "Item" temporary;
    begin
        if ItemAnalysisViewCode = '' then
            Error(Text000);

        if AnalysisColumnTemplate = '' then
            Error(Text001);

        if DateFilter = '' then
            Error(Text002);

        AnalysisDimSelectionBuf.CompareDimText(
          3, REPORT::"Item Dimensions - Total", AnalysisArea.AsInteger(), ItemAnalysisViewCode, ColumnDim, Text003);
        AnalysisSelectedDim.GetSelectedDim(
          UserId, 3, REPORT::"Item Dimensions - Total", AnalysisArea.AsInteger(), ItemAnalysisViewCode, TempAnalysisSelectedDim);

        TempAnalysisSelectedDim.Reset();
        TempAnalysisSelectedDim.SetFilter("Dimension Value Filter", '<>%1', '');
        TempAnalysisSelectedDim.SetFilter("Dimension Code", TempItem.TableCaption());
        if TempAnalysisSelectedDim.Find('-') then
            Item.SetFilter("No.", TempAnalysisSelectedDim."Dimension Value Filter");
        if Item.Find('-') then begin
            ItemRange := Item."No.";
            repeat
                TempItem.Init();
                TempItem := Item;
                TempItem.Insert();
            until Item.Next() = 0;

            if TempAnalysisSelectedDim.FindFirst() and (TempAnalysisSelectedDim."Dimension Value Filter" <> '') then
                ItemRange := TempAnalysisSelectedDim."Dimension Value Filter"
            else begin
                TempEscapeFilterItem.SetRange("No.", ItemRange, Item."No.");
                ItemRange := TempEscapeFilterItem.GetFilter("No.");
            end;
        end;

        TempLocation.Init();
        TempLocation.Insert();
        TempAnalysisSelectedDim.SetFilter("Dimension Code", TempLocation.TableCaption());
        if TempAnalysisSelectedDim.Find('-') then
            Location.SetFilter(Code, TempAnalysisSelectedDim."Dimension Value Filter");
        if Location.Find('-') then
            repeat
                TempLocation.Init();
                TempLocation := Location;
                TempLocation.Insert();
            until Location.Next() = 0;

        TempAnalysisSelectedDim.Reset();
        TempAnalysisSelectedDim.SetCurrentKey(
          "User ID", "Object Type", "Object ID", "Analysis Area", "Analysis View Code", Level);
        TempAnalysisSelectedDim.SetFilter(Level, '<>%1', TempAnalysisSelectedDim.Level::" ");
        if TempAnalysisSelectedDim.Find('-') then
            repeat
                TempDimVal.Init();
                TempDimVal.Code := '';
                TempDimVal."Dimension Code" := TempAnalysisSelectedDim."Dimension Code";
                TempDimVal.Name := Text004;
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

        AnalysisLineTemplate."Analysis Area" := AnalysisArea;
        AnalysisLineTemplate."Item Analysis View Code" := ItemAnalysisViewCode;
        AnalysisReportMgt.SetAnalysisLineTemplate(AnalysisLineTemplate);
        InitAnalysisLine();
    end;

    var
        AnalysisLine: Record "Analysis Line";
        TempAnalysisSelectedDim: Record "Analysis Selected Dimension" temporary;
        Item: Record Item;
        Location: Record Location;
        DimVal: Record "Dimension Value";
        TempItem: Record Item temporary;
        TempLocation: Record Location temporary;
        TempDimVal: Record "Dimension Value" temporary;
        TempAnalysisColumn: Record "Analysis Column" temporary;
        AnalysisDimSelectionBuf: Record "Analysis Dim. Selection Buffer";
        AnalysisReportMgt: Codeunit "Analysis Report Management";
        MatrixMgt: Codeunit "Matrix Management";
        AnalysisColumnTemplate: Code[10];
        AnalysisColumnTemplateHidden: Code[10];
        ItemBudgetName: Code[10];
        PrintEmptyLines: Boolean;
        ItemRange: Code[250];
        ColumnValuesDisplayed: array[5] of Decimal;
        ColumnValuesAsText: array[5, 4] of Text[30];
        Header: array[5] of Text[50];
        RoundingHeader: array[5] of Text[30];
        MaxColumnsDisplayed: Integer;
        NoOfCols: Integer;
        ViewLastUpdatedText: Text[30];
        ColumnDim: Text[250];
        AnalysisArea: Enum "Analysis Area Type";
        ItemAnalysisViewCode: Code[10];
        DateFilter: Text;
        FindFirstDim: array[4] of Boolean;
        DimCode: array[4] of Text[30];
        DimValCode: array[3] of Code[20];
        DimValName: array[3] of Text[100];
        DimValNameIndent: array[3] of Integer;
        ShowBold: array[3] of Boolean;
        LevelFilter: array[3] of Text[250];
        DimFilterText: Text[250];
        PrintEndTotals: array[50] of Boolean;
        ItemFilterSet: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Enter an analysis view code.';
        Text001: Label 'Enter a column template.';
        Text002: Label 'Enter a date filter.';
        Text003: Label 'Include Dimensions';
        Text004: Label '(no dimension value)';
        Text005: Label 'Not updated';
        Text006: Label '(Thousands)';
        Text007: Label '(Millions)';
        Text009: Label '(no location code)';
#pragma warning restore AA0074
        ColumnTemplateCaptionLbl: Label 'Column Template';
        PeriodCaptionLbl: Label 'Period';
        AnalysisViewCaptionLbl: Label 'Analysis View';
        LastUpdatedCaptionLbl: Label 'Last Date Updated';
        PageNoCaptionLbl: Label 'Page';
        ItemDimensionsTotalCaptionLbl: Label 'Item Dimensions - Total';
        FiltersCaptionLbl: Label 'Filters';
        DimensionValueCaptionLbl: Label 'Dimension Value';
        DimensionCaptionLbl: Label 'Dimension';

    local procedure CalcLine(Level: Integer): Boolean
    var
        Totaling: Text[250];
        Indentation: Integer;
        PostingType: Option Standard,Heading,Total,"Begin-Total","End-Total";
        LowestLevel: Boolean;
        ThisDimValCode: Code[20];
        ThisDimValName: Text[100];
        ThisTotaling: Text[250];
        ThisIndentation: Integer;
        ThisPostingType: Option Standard,Heading,Total,"Begin-Total","End-Total";
        LineNo: Integer;
        HasValue: Boolean;
        More: Boolean;
        i: Integer;
    begin
        if Iteration(
             FindFirstDim[Level], DimCode[Level], DimValCode[Level], DimValName[Level], LevelFilter[Level],
             Totaling, Indentation, PostingType)
        then begin
            if Level = 3 then
                LowestLevel := true
            else
                LowestLevel := DimCode[Level + 1] = '';

            if not PrintEmptyLines and not LowestLevel then begin
                SetAnalysisLineFilter(DimCode[Level], DimValCode[Level], true, Totaling);
                HasValue := TestCalcLine(Level + 1, true);
            end;

            ShowBold[Level] := not LowestLevel or (PostingType <> PostingType::Standard);

            if LowestLevel then
                DimValNameIndent[Level] := Indentation
            else begin
                DimValNameIndent[Level] := 0;
                Clear(PrintEndTotals);
                i := Level + 1;
                while i <= ArrayLen(DimCode) do begin
                    if DimCode[i] <> '' then
                        if LevelFilter[i] <> '' then
                            SetAnalysisLineFilter(DimCode[i], LevelFilter[i], true, '')
                        else
                            SetAnalysisLineFilter(DimCode[i], '', false, '');
                    i := i + 1;
                end;
            end;

            // Check if begin-total should be printed...
            if not PrintEmptyLines and LowestLevel and (PostingType = PostingType::"Begin-Total") then begin
                LineNo := AnalysisLine."Line No.";
                ThisDimValCode := DimValCode[Level];
                ThisTotaling := Totaling;
                ThisIndentation := 999999999;
                More := true;
                SetAnalysisLineFilter(DimCode[Level], ThisDimValCode, true, ThisTotaling);
                HasValue := CalcColumns(0);
                while More and not HasValue and (ThisIndentation > Indentation) do begin
                    More :=
                      Iteration(
                        FindFirstDim[Level], DimCode[Level], ThisDimValCode, ThisDimValName, LevelFilter[Level],
                        ThisTotaling, ThisIndentation, ThisPostingType);
                    if More then begin
                        SetAnalysisLineFilter(DimCode[Level], ThisDimValCode, true, ThisTotaling);
                        HasValue := CalcColumns(0);
                    end;
                end;
                AnalysisLine."Line No." := LineNo;
                PrintEndTotals[Indentation + 1] := HasValue;
            end;

            // Check if end-total should be printed...
            if not PrintEmptyLines and LowestLevel and (PostingType = PostingType::"End-Total") then begin
                HasValue := PrintEndTotals[Indentation + 1];
                PrintEndTotals[Indentation + 1] := false;
            end;

            SetAnalysisLineFilter(DimCode[Level], DimValCode[Level], true, Totaling);
            for i := 1 to MaxColumnsDisplayed do begin
                ColumnValuesDisplayed[i] := 0;
                ColumnValuesAsText[i, Level] := '';
            end;

            exit(HasValue or CalcColumns(Level));
        end;
        CurrReport.Break();
    end;

    local procedure TestCalcLine(Level: Integer; ThisFindFirstDim: Boolean): Boolean
    var
        Totaling: Text[250];
        LowestLevel: Boolean;
        ThisDimValName: Text[100];
        ThisIndentation: Integer;
        ThisPostingType: Option Standard,Heading,Total,"Begin-Total","End-Total";
        HasValue: Boolean;
        More: Boolean;
        TryNext: Boolean;
    begin
        FindFirstDim[Level] := ThisFindFirstDim;

        TryNext := true;
        while TryNext and not HasValue do begin
            TryNext := false;
            Clear(Totaling);
            Clear(LowestLevel);
            Clear(ThisDimValName);
            Clear(ThisIndentation);
            Clear(ThisPostingType);

            if Iteration(
                 FindFirstDim[Level], DimCode[Level], DimValCode[Level], ThisDimValName, LevelFilter[Level],
                 Totaling, ThisIndentation, ThisPostingType)
            then begin
                if Level = 3 then
                    LowestLevel := true
                else
                    LowestLevel := DimCode[Level + 1] = '';

                if LowestLevel then begin
                    More := true;
                    SetAnalysisLineFilter(DimCode[Level], DimValCode[Level], true, Totaling);
                    HasValue := CalcColumns(0);
                    while More and not HasValue do begin
                        More :=
                          Iteration(
                            FindFirstDim[Level], DimCode[Level], DimValCode[Level], ThisDimValName, LevelFilter[Level],
                            Totaling, ThisIndentation, ThisPostingType);
                        if More then begin
                            SetAnalysisLineFilter(DimCode[Level], DimValCode[Level], true, Totaling);
                            HasValue := CalcColumns(0);
                        end;
                    end;
                end else begin
                    HasValue := TestCalcLine(Level + 1, true);
                    TryNext := not HasValue;
                end;
            end else
                HasValue := false;
        end;
        exit(HasValue);
    end;

    local procedure CalcColumns(Level: Integer): Boolean
    var
        NonZero: Boolean;
        i: Integer;
        Finished: Boolean;
    begin
        NonZero := false;
        if not ItemFilterSet then
            AnalysisLine.Range := ItemRange;

        TempAnalysisColumn.SetRange("Analysis Column Template", AnalysisColumnTemplate);
        i := 0;
        if TempAnalysisColumn.Find('-') then
            repeat
                if TempAnalysisColumn.Show <> TempAnalysisColumn.Show::Never then begin
                    i := i + 1;
                    AnalysisLine."Line No." := AnalysisLine."Line No." + 1;
                    ColumnValuesDisplayed[i] :=
                      AnalysisReportMgt.CalcCell(AnalysisLine, TempAnalysisColumn, false);
                    NonZero :=
                      NonZero or (ColumnValuesDisplayed[i] <> 0) and
                      (TempAnalysisColumn."Column Type" <> TempAnalysisColumn."Column Type"::Formula);
                    if Level > 0 then
                        ColumnValuesAsText[i, Level] :=
                          MatrixMgt.FormatAmount(ColumnValuesDisplayed[i], TempAnalysisColumn."Rounding Factor", false);
                end;
                Finished := (NonZero and (Level = 0)) or (i >= MaxColumnsDisplayed) or (TempAnalysisColumn.Next() = 0);
            until Finished;
        exit(NonZero);
    end;

    local procedure UpdateColumnDim()
    var
        AnalysisSelectedDim: Record "Analysis Selected Dimension";
        TempAnalysisDimSelectionBuf: Record "Analysis Dim. Selection Buffer" temporary;
        ItemAnalysisView: Record "Item Analysis View";
    begin
        ItemAnalysisView.CopyAnalysisViewFilters(3, REPORT::"Item Dimensions - Total", AnalysisArea.AsInteger(), ItemAnalysisViewCode);
        ColumnDim := '';
        AnalysisSelectedDim.SetRange("User ID", UserId);
        AnalysisSelectedDim.SetRange("Object Type", 3);
        AnalysisSelectedDim.SetRange("Object ID", REPORT::"Item Dimensions - Total");
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
              3, REPORT::"Item Dimensions - Total", AnalysisArea.AsInteger(), ItemAnalysisViewCode, ColumnDim, TempAnalysisDimSelectionBuf);
        end;
    end;

    local procedure Iteration(var FindFirstRec: Boolean; IterationDimCode: Text[30]; var IterationDimValCode: Code[20]; var IterationDimValName: Text[100]; IterationFilter: Text[250]; var IterationTotaling: Text[250]; var IterationIndentation: Integer; var IterationPostingType: Option Standard,Heading,Total,"Begin-Total","End-Total"): Boolean
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
                        IterationDimValName := CopyStr(TempItem.Description, 1, MaxStrLen(IterationDimValName));
                        IterationIndentation := 0;
                        IterationPostingType := 0;
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
                            IterationDimValName := CopyStr(TempLocation.Name, 1, MaxStrLen(IterationDimValName))
                        else
                            IterationDimValName := CopyStr(Text009, 1, MaxStrLen(IterationDimValName));
                        IterationIndentation := 0;
                        IterationPostingType := 0;
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
                    IterationTotaling := TempDimVal.Totaling;
                    IterationIndentation := TempDimVal.Indentation;
                    IterationPostingType := TempDimVal."Dimension Value Type";
                end;
            end;
        end;
        if not SearchResult then begin
            IterationDimValCode := '';
            IterationDimValName := '';
            IterationTotaling := '';
            IterationIndentation := 0;
            IterationPostingType := 0;
        end;
        FindFirstRec := false;
        exit(SearchResult);
    end;

    local procedure SetAnalysisLineFilter(AnalysisViewDimCode: Text[30]; AnalysisViewFilter: Text[250]; SetFilter: Boolean; Totaling: Text[250])
    var
        TempAnalysisLine: Record "Analysis Line" temporary;
    begin
        if Totaling <> '' then
            AnalysisViewFilter := Totaling;
        if SetFilter and (AnalysisViewFilter = '') then
            AnalysisViewFilter := '''''';
        case AnalysisViewDimCode of
            TempItem.TableCaption:
                begin
                    ItemFilterSet := SetFilter;
                    if SetFilter then begin
                        TempAnalysisLine.SetFilter(Range, '%1', AnalysisViewFilter);
                        AnalysisLine.Range := TempAnalysisLine.GetFilter(Range);
                    end
                    else
                        AnalysisLine.Range := ItemRange;
                end;
            TempLocation.TableCaption:
                if SetFilter then
                    AnalysisLine.SetFilter("Location Filter", AnalysisViewFilter)
                else
                    AnalysisLine.SetRange("Location Filter");
            "Item Analysis View"."Dimension 1 Code":
                if SetFilter then
                    AnalysisLine."Dimension 1 Totaling" := AnalysisViewFilter
                else
                    AnalysisLine."Dimension 1 Totaling" := '';
            "Item Analysis View"."Dimension 2 Code":
                if SetFilter then
                    AnalysisLine."Dimension 2 Totaling" := AnalysisViewFilter
                else
                    AnalysisLine."Dimension 2 Totaling" := '';
            "Item Analysis View"."Dimension 3 Code":
                if SetFilter then
                    AnalysisLine."Dimension 3 Totaling" := AnalysisViewFilter
                else
                    AnalysisLine."Dimension 3 Totaling" := '';
        end;
    end;

    local procedure InitAnalysisLine()
    begin
        AnalysisLine.Init();
        AnalysisLine."Analysis Area" := AnalysisArea;
        AnalysisLine.SetRange("Analysis Area", AnalysisArea);
        AnalysisLine.SetFilter("Date Filter", DateFilter);
        if ItemBudgetName <> '' then
            AnalysisLine.SetRange("Item Budget Filter", ItemBudgetName);
    end;
}

