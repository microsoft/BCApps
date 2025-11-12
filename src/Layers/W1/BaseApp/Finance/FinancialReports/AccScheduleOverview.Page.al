// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Forecast;
using Microsoft.CostAccounting.Account;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Reflection;
using System.Telemetry;
using System.Text;

page 490 "Acc. Schedule Overview"
{
    AboutTitle = 'About financial report';
    AboutText = 'On this page, you can run a financial report and see data based on filter values. You can also export the data to Excel or get a PDF version (or print it). When the page is in "Edit mode", you can also change the report definition, such as the choice of column and row definitions used.';
    Caption = 'Financial Report';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SaveValues = true;
    ShowFilter = false;
    SourceTable = "Acc. Schedule Line";
    RefreshOnActivate = true;
    UsageCategory = None;

    layout
    {
        area(content)
        {
#if not CLEAN26
            field(Title; FinancialReportSummaryTxt)
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
                Caption = 'Financial Report';
                Editable = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'This field is no longer required and will be removed in a future release.';
                ObsoleteTag = '26.0';
                ShowCaption = false;
                Style = Strong;
                Tooltip = 'Financial report details.';
            }
#endif
            group(General)
            {
                Caption = 'Options';
                Visible = (not ViewOnlyMode or (ViewLayout = "Financial Report View Layout"::"Show All"));

                field(FinancialReportName; TempFinancialReport.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Caption = 'Name';
                    Tooltip = 'Specifies the name (code) of the financial report.';
                    trigger OnAssistEdit()
                    begin
                        Page.RunModal(Page::"Financial Reports");
                    end;
                }

                field(FinancialReportDesc; TempFinancialReport.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Display Title';
                    Editable = not ViewOnlyMode;
                    ToolTip = 'Specifies a title of the financial report. The text is shown as a title on the final report when you run it to get a PDF or to print it.';
                }

                field(CurrentSchedName; TempFinancialReport."Financial Report Row Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = (not ViewOnlyMode or (ViewLayout = "Financial Report View Layout"::"Show All"));
                    Caption = 'Row Definition';
                    Importance = Additional;
                    Lookup = true;
                    LookupPageID = "Account Schedule Names";
                    ToolTip = 'Specifies the name (code) of the row definition to be used for the report.';
                    AboutTitle = 'About row definition';
                    AboutText = 'Change the row definition of the report. You can use the built-in row definitions, or create your own';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FinancialReportRowGroup: Text[10];
                        Result: Boolean;
                    begin
                        FinancialReportRowGroup := CopyStr(Text, 1, MaxStrLen(FinancialReportRowGroup));
                        Result := AccSchedManagement.LookupName(TempFinancialReport."Financial Report Row Group", FinancialReportRowGroup);
                        TempFinancialReport."Financial Report Row Group" := FinancialReportRowGroup;
                        Text := TempFinancialReport."Financial Report Row Group";
                        CurrentSchedNameOnAfterValidate();
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        AccSchedManagement.CheckName(TempFinancialReport."Financial Report Row Group");
                        CurrentSchedNameOnAfterValidate();
                    end;
                }
                field(CurrentColumnName; TempFinancialReport."Financial Report Column Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = (not ViewOnlyMode or (ViewLayout = "Financial Report View Layout"::"Show All"));
                    Caption = 'Column Definition';
                    Importance = Additional;
                    Lookup = true;
                    LookupPageId = "Column Layout Names";
                    ToolTip = 'Specifies the name (code) of the column definition to be used for the report.';
                    AboutTitle = 'About column definition';
                    AboutText = 'Change the column definition of the report. You can use the built-in column definitions, or create your own.';
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FinancialReportColumnGroup: Text[10];
                        Result: Boolean;
                    begin
                        FinancialReportColumnGroup := CopyStr(Text, 1, MaxStrLen(FinancialReportColumnGroup));
                        Result := AccSchedManagement.LookupColumnName(TempFinancialReport."Financial Report Column Group", FinancialReportColumnGroup);
                        TempFinancialReport."Financial Report Column Group" := FinancialReportColumnGroup;
                        // Every change to FinancialReportTemp."Financial Report Column Group" must be kept in sync with CurrentColumnName
                        CurrentColumnName := TempFinancialReport."Financial Report Column Group";
                        Text := TempFinancialReport."Financial Report Column Group";
                        CurrentColumnNameOnAfterValidate();
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        AccSchedManagement.CheckColumnName(TempFinancialReport."Financial Report Column Group");
                        // Every change to FinancialReportTemp."Financial Report Column Group" must be kept in sync with CurrentColumnName
                        CurrentColumnName := TempFinancialReport."Financial Report Column Group";
                        CurrentColumnNameOnAfterValidate();
                    end;
                }
                field(SheetDefinitionName; TempFinancialReport.SheetDefinition)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sheet Definition';
                    Editable = (not ViewOnlyMode or (ViewLayout = "Financial Report View Layout"::"Show All"));
                    Importance = Additional;
                    TableRelation = "Sheet Definition Name";
                    ToolTip = 'Specifies the name (code) of the sheet definition to be used for the report.';

                    trigger OnAfterLookup(Selected: RecordRef)
                    var
                        SheetDefName: Record "Sheet Definition Name";
                    begin
                        SheetDefName := Selected;
                        TempFinancialReport.SheetDefinition := SheetDefName.Name;
                        if not ViewOnlyMode then
                            SaveStateToFinancialReport();
                    end;

                    trigger OnValidate()
                    begin
                        if not ViewOnlyMode then
                            SaveStateToFinancialReport();
                    end;
                }
                field(UseAmtsInAddCurr; TempFinancialReport.UseAmountsInAddCurrency)
                {
                    ApplicationArea = Suite;
                    Caption = 'Show Amounts in Add. Reporting Currency';
                    MultiLine = true;
                    ToolTip = 'Specifies if the reported amounts are shown in the additional reporting currency.';
                    Visible = UseAmtsInAddCurrVisible;

                    trigger OnValidate()
                    begin
                        // Every change to FinancialReportTemp.UseAmountsInAddCurrency must be kept in sync with UseAmtsInAddCurr
                        UseAmtsInAddCurr := TempFinancialReport.UseAmountsInAddCurrency;
                        CurrPage.Update();
                    end;
                }
#if not CLEAN28
                field(NegativeAmountFormat; TempFinancialReport.NegativeAmountFormat)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Negative Amount Format';
                    Importance = Additional;
                    ToolTip = 'Specifies how negative amounts are displayed on the financial report.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This has been replaced by the NegativeAmountFormatDefault field.';
                    ObsoleteTag = '28.0';
                    Visible = not FinancialReportDefaultsEnabled;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
#endif
                field(NegativeAmountFormatDefault; TempFinancialReport.NegativeAmountFormatDefault)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Negative Amount Format';
                    Importance = Additional;
                    ToolTip = 'Specifies how negative amounts are displayed on the financial report.';
#if not CLEAN28
                    Visible = FinancialReportDefaultsEnabled;
#endif

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
#if not CLEAN28
                field(PeriodType; TempFinancialReport.PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    Importance = Promoted;
                    ToolTip = 'Specifies by which period amounts are displayed.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This has been replaced by the PeriodTypeDefault field.';
                    ObsoleteTag = '28.0';
                    Visible = not FinancialReportDefaultsEnabled;

                    trigger OnValidate()
                    begin
                        AccSchedManagement.FindPeriod(Rec, '', TempFinancialReport.PeriodType);
                        DateFilter := Rec.GetFilter("Date Filter");
                        UpdateColumnCaptions();
                        CurrPage.Update();
                    end;
                }
#endif
                field(PeriodTypeDefault; TempFinancialReport.PeriodTypeDefault)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    Importance = Promoted;
                    ToolTip = 'Specifies by which period amounts are displayed.';
#if not CLEAN28
                    Visible = FinancialReportDefaultsEnabled;
#endif

                    trigger OnValidate()
                    begin
                        AccSchedManagement.FindPeriod(Rec, '', TempFinancialReport.GetEffectivePeriodType());
                        DateFilter := Rec.GetFilter("Date Filter");
                        CurrPage.Update();
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(DateFilter);
                        Rec.SetFilter("Date Filter", DateFilter);
                        DateFilter := Rec.GetFilter("Date Filter");
                        TempFinancialReport.DateFilter := DateFilter;
                        UpdateColumnCaptions();
                        CurrPage.Update();
                    end;
                }
                field(StartDateFilterFormula; TempFinancialReport.StartDateFilterFormula)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start Date Filter Formula';
                    ToolTip = 'Specifies the date formula used to automatically calculate the start date of the date filter.';
                    Visible = not ViewOnlyMode;

                    trigger OnValidate()
                    begin
                        ValidateStartEndDateFilterFormula();
                    end;
                }
                field(EndDateFilterFormula; TempFinancialReport.EndDateFilterFormula)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'End Date Filter Formula';
                    ToolTip = 'Specifies the date formula used to automatically calculate the end date of the date filter.';
                    Visible = not ViewOnlyMode;

                    trigger OnValidate()
                    begin
                        ValidateStartEndDateFilterFormula();
                    end;
                }
                field(DateFilterPeriodFormula; TempFinancialReport.DateFilterPeriodFormula)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter Period Formula';
                    ToolTip = 'Specifies the period formula used to automatically calculate the date filter.';
                    Importance = Additional;
                    Visible = not ViewOnlyMode;

                    trigger OnValidate()
                    begin
                        ValidateDateFilterPeriodFormula();
                    end;
                }
                field(ShowLinesWithShowNo; TempFinancialReport.ShowLinesWithShowNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All Lines';
                    Importance = Additional;
                    ToolTip = 'Specifies whether the page should display all lines, including lines where No is chosen in the Show field, as well as lines with values outside the range to be displayed. Those lines are still not included in the printed report.';

                    trigger OnValidate()
                    begin
                        ApplyShowFilter();
                        CurrPage.Update();
                    end;
                }
                field(ExcelTemplateCode; TempFinancialReport."Excel Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Default Excel Layout';
                    Importance = Additional;
                    ToolTip = 'Specifies the Excel layout that will be used when exporting to Excel.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        FinReportExcelTemplate: Record "Fin. Report Excel Template";
                        FinReportExcelTemplates: Page "Fin. Report Excel Templates";
                    begin
                        FinReportExcelTemplates.SetSource(TempFinancialReport, Rec);
                        FinReportExcelTemplates.LookupMode(true);
                        if FinReportExcelTemplates.RunModal() = Action::LookupOK then begin
                            FinReportExcelTemplates.GetRecord(FinReportExcelTemplate);
                            TempFinancialReport."Excel Template Code" := FinReportExcelTemplate.Code;
                            Text := FinReportExcelTemplate.Code;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    var
                        FinReportExcelTemplate: Record "Fin. Report Excel Template";
                    begin
                        if TempFinancialReport."Excel Template Code" <> '' then
                            FinReportExcelTemplate.Get(TempFinancialReport.Name, TempFinancialReport."Excel Template Code");
                    end;
                }
                field(LogoPositionDefault; TempFinancialReport.LogoPositionDefault)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Logo Position';
                    ToolTip = 'Specifies how your company logo is displayed on the financial report.';
                    Visible = not ViewOnlyMode;

                    trigger OnValidate()
                    begin
                        SaveStateToFinancialReport();
                        CurrPage.Update();
                    end;
                }
                field(InternalDescription; TempFinancialReport."Internal Description")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Internal Description';
                    ToolTip = 'Specifies the internal description of this financial report.';
                    MultiLine = true;
                    Editable = not ViewOnlyMode;
                }
            }
            group(IntroductoryParagraphGroup)
            {
                Caption = 'Introductory paragraph';
                Visible = ViewOnlyMode and (IntroductoryParagraph <> '');

                field(IntroductoryParagraph; IntroductoryParagraph)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    ToolTip = 'Specifies the Introductory paragraph displayed on the Financial Report, when it is printed to PDF or exported to Excel.';
                    MultiLine = true;
                    Editable = false;
                }
            }
            group("Dimension Filters")
            {
                Caption = 'Dimensions';
                Visible = ((ViewLayout <> "Financial Report View Layout"::"Show None") or (not ViewOnlyMode));
                field(Dim1Filter; TempFinancialReport.Dim1Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = FormGetCaptionClass(1);
                    Caption = 'Dimension 1 Filter';
                    Enabled = Dim1FilterEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the Dimension 1 for which entries will be shown in the matrix window.';
                    Visible = Dim1FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimValue: Record "Dimension Value";
                        Result: Boolean;
                    begin
                        Result := DimValue.LookUpDimFilter(AnalysisView."Dimension 1 Code", Text);
                        SetDimFilters(1, CopyStr(Text, 1, MaxStrLen(TempFinancialReport.Dim1Filter)));
                        TempFinancialReport.Dim1Filter := CopyStr(Text, 1, MaxStrLen(TempFinancialReport.Dim1Filter));
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        SetDimFilters(1, TempFinancialReport.Dim1Filter);
                    end;
                }
                field(Dim2Filter; TempFinancialReport.Dim2Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = FormGetCaptionClass(2);
                    Caption = 'Dimension 2 Filter';
                    Enabled = Dim2FilterEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the Dimension 2 for which entries will be shown in the matrix window.';
                    Visible = Dim2FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimValue: Record "Dimension Value";
                        Result: Boolean;
                    begin
                        Result := DimValue.LookUpDimFilter(AnalysisView."Dimension 2 Code", Text);
                        SetDimFilters(2, CopyStr(Text, 1, MaxStrLen(TempFinancialReport.Dim2Filter)));
                        TempFinancialReport.Dim2Filter := CopyStr(Text, 1, MaxStrLen(TempFinancialReport.Dim2Filter));
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        SetDimFilters(2, TempFinancialReport.Dim2Filter);
                    end;
                }
                field(Dim3Filter; TempFinancialReport.Dim3Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = FormGetCaptionClass(3);
                    Caption = 'Dimension 3 Filter';
                    Enabled = Dim3FilterEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the Dimension 3 for which entries will be shown in the matrix window.';
                    Visible = Dim3FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimValue: Record "Dimension Value";
                        Result: Boolean;
                    begin
                        Result := DimValue.LookUpDimFilter(AnalysisView."Dimension 3 Code", Text);
                        SetDimFilters(3, CopyStr(Text, 1, MaxStrLen(TempFinancialReport.Dim1Filter)));
                        TempFinancialReport.Dim3Filter := CopyStr(Text, 1, MaxStrLen(TempFinancialReport.Dim3Filter));
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        SetDimFilters(3, TempFinancialReport.Dim3Filter);
                    end;
                }
                field(Dim4Filter; TempFinancialReport.Dim4Filter)
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = FormGetCaptionClass(4);
                    Caption = 'Dimension 4 Filter';
                    Enabled = Dim4FilterEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the Dimension 4 for which entries will be shown in the matrix window.';
                    Visible = Dim4FilterEnable;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimValue: Record "Dimension Value";
                        Result: Boolean;
                    begin
                        Result := DimValue.LookUpDimFilter(AnalysisView."Dimension 4 Code", Text);
                        SetDimFilters(4, CopyStr(Text, 1, MaxStrLen(TempFinancialReport.Dim1Filter)));
                        TempFinancialReport.Dim4Filter := CopyStr(Text, 1, MaxStrLen(TempFinancialReport.Dim4Filter));
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        SetDimFilters(4, TempFinancialReport.Dim4Filter);
                    end;
                }
                field(CostCenterFilter; TempFinancialReport.CostCenterFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Center Filter';
                    Importance = Additional;
                    ToolTip = 'Specifies a cost center for which you want to view account amounts.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostCenter: Record "Cost Center";
                        Result: Boolean;
                    begin
                        Result := CostCenter.LookupCostCenterFilter(Text);
                        TempFinancialReport.CostCenterFilter := CopyStr(Text, 1, MaxStrLen(TempFinancialReport.CostCenterFilter));
                        ValidateCostCenterFilter();
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCostCenterFilter();
                    end;
                }
                field(CostObjectFilter; TempFinancialReport.CostObjectFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Object Filter';
                    Importance = Additional;
                    ToolTip = 'Specifies a cost object for which you want to view account amounts.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CostObject: Record "Cost Object";
                        Result: Boolean;
                    begin
                        Result := CostObject.LookupCostObjectFilter(Text);
                        TempFinancialReport.CostObjectFilter := CopyStr(Text, 1, MaxStrLen(TempFinancialReport.CostObjectFilter));
                        ValidateCostObjectFilter();
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCostObjectFilter();
                    end;
                }
                field(CashFlowFilter; TempFinancialReport.CashFlowFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Cash Flow Filter';
                    Importance = Additional;
                    ToolTip = 'Specifies a dimension filter for the cash flow, for which you want to view account amounts.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CashFlowForecast: Record "Cash Flow Forecast";
                        Result: Boolean;
                    begin
                        Result := CashFlowForecast.LookupCashFlowFilter(Text);
                        TempFinancialReport.CashFlowFilter := CopyStr(Text, 1, MaxStrLen(TempFinancialReport.CashFlowFilter));
                        ValidateCashFlowFilter();
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCashFlowFilter();
                    end;
                }
                field("G/LBudgetFilter"; TempFinancialReport.GLBudgetFilter)
                {
                    ApplicationArea = Suite;
                    Caption = 'G/L Budget Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for a general ledger budget that the account schedule line will be filtered on.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Result: Boolean;
                    begin
                        Result := Rec.LookupGLBudgetFilter(Text);
                        TempFinancialReport.GLBudgetFilter := CopyStr(Text, 1, MaxStrLen(TempFinancialReport.GLBudgetFilter));
                        ValidateGLBudgetFilter();
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateGLBudgetFilter();
                    end;
                }
                field(CostBudgetFilter; TempFinancialReport.CostBudgetFilter)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Cost Budget Filter';
                    Importance = Additional;
                    ToolTip = 'Specifies a code for a cost budget that the account schedule line will be filtered on.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Result: Boolean;
                    begin
                        Result := Rec.LookupCostBudgetFilter(Text);
                        TempFinancialReport.CostBudgetFilter := CopyStr(Text, 1, MaxStrLen(TempFinancialReport.CostBudgetFilter));
                        ValidateCostBudgetFilter();
                        exit(Result);
                    end;

                    trigger OnValidate()
                    begin
                        ValidateCostBudgetFilter();
                    end;
                }
            }
            repeater(Control48)
            {
                Editable = false;
                IndentationColumn = Rec.Indentation;
                IndentationControls = Description;
                ShowCaption = false;
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = Rec.Bold;
                    ToolTip = 'Specifies text that will appear on the account schedule line.';
                }
                field(ColumnValues1; ColumnValues[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(1);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[1];
                    StyleExpr = ColumnStyle1;

                    trigger OnDrillDown()
                    begin
                        DrillDown(1);
                    end;
                }
                field(ColumnValues2; ColumnValues[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(2);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[2];
                    StyleExpr = ColumnStyle2;
                    Visible = NoOfColumns >= 2;

                    trigger OnDrillDown()
                    begin
                        DrillDown(2);
                    end;
                }
                field(ColumnValues3; ColumnValues[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(3);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[3];
                    StyleExpr = ColumnStyle3;
                    Visible = NoOfColumns >= 3;

                    trigger OnDrillDown()
                    begin
                        DrillDown(3);
                    end;
                }
                field(ColumnValues4; ColumnValues[4])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(4);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[4];
                    StyleExpr = ColumnStyle4;
                    Visible = NoOfColumns >= 4;

                    trigger OnDrillDown()
                    begin
                        DrillDown(4);
                    end;
                }
                field(ColumnValues5; ColumnValues[5])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(5);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[5];
                    StyleExpr = ColumnStyle5;
                    Visible = NoOfColumns >= 5;

                    trigger OnDrillDown()
                    begin
                        DrillDown(5);
                    end;
                }
                field(ColumnValues6; ColumnValues[6])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(6);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[6];
                    StyleExpr = ColumnStyle6;
                    Visible = NoOfColumns >= 6;

                    trigger OnDrillDown()
                    begin
                        DrillDown(6);
                    end;
                }
                field(ColumnValues7; ColumnValues[7])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(7);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[7];
                    StyleExpr = ColumnStyle7;
                    Visible = NoOfColumns >= 7;

                    trigger OnDrillDown()
                    begin
                        DrillDown(7);
                    end;
                }
                field(ColumnValues8; ColumnValues[8])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(8);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[8];
                    StyleExpr = ColumnStyle8;
                    Visible = NoOfColumns >= 8;

                    trigger OnDrillDown()
                    begin
                        DrillDown(8);
                    end;
                }
                field(ColumnValues9; ColumnValues[9])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(9);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[9];
                    StyleExpr = ColumnStyle9;
                    Visible = NoOfColumns >= 9;

                    trigger OnDrillDown()
                    begin
                        DrillDown(9);
                    end;
                }
                field(ColumnValues10; ColumnValues[10])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(10);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[10];
                    StyleExpr = ColumnStyle10;
                    Visible = NoOfColumns >= 10;

                    trigger OnDrillDown()
                    begin
                        DrillDown(10);
                    end;
                }
                field(ColumnValues11; ColumnValues[11])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(11);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[11];
                    StyleExpr = ColumnStyle11;
                    Visible = NoOfColumns >= 11;

                    trigger OnDrillDown()
                    begin
                        DrillDown(11);
                    end;
                }
                field(ColumnValues12; ColumnValues[12])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(12);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[12];
                    StyleExpr = ColumnStyle12;
                    Visible = NoOfColumns >= 12;

                    trigger OnDrillDown()
                    begin
                        DrillDown(12);
                    end;
                }
                field(ColumnValues13; ColumnValues[13])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(13);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[13];
                    StyleExpr = ColumnStyle13;
                    Visible = NoOfColumns >= 13;
                    ToolTip = 'Column title';

                    trigger OnDrillDown()
                    begin
                        DrillDown(13);
                    end;
                }
                field(ColumnValues14; ColumnValues[14])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(14);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[14];
                    StyleExpr = ColumnStyle14;
                    Visible = NoOfColumns >= 14;
                    ToolTip = 'Column title';

                    trigger OnDrillDown()
                    begin
                        DrillDown(14);
                    end;
                }
                field(ColumnValues15; ColumnValues[15])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr(15);
                    AutoFormatType = 11;
                    BlankZero = true;
                    CaptionClass = '3,' + ColumnCaptions[15];
                    StyleExpr = ColumnStyle15;
                    Visible = NoOfColumns >= 15;
                    ToolTip = 'Column title';

                    trigger OnDrillDown()
                    begin
                        DrillDown(15);
                    end;
                }
            }
            group(ClosingParagraphGroup)
            {
                Caption = 'Closing paragraph';
                Visible = ViewOnlyMode and (ClosingParagraph <> '');

                field(ClosingParagraph; ClosingParagraph)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    ToolTip = 'Specifies the closing paragraph displayed on the Financial Report, when it is printed to PDF or exported to Excel.';
                    MultiLine = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Get a PDF or print the financial report. A print request window opens where you can specify what to include in the PDF/print-out.';

                trigger OnAction()
                var
                    AccSched: Report "Account Schedule";
                    DateFilter2: Text;
                    GLBudgetFilter2: Text;
                    BusUnitFilter: Text;
                    CostBudgetFilter2: Text;
                    IsHandled: Boolean;
                begin
                    IsHandled := false;
                    OnBeforePrint(Rec, TempFinancialReport."Financial Report Column Group", IsHandled, TempFinancialReport);
                    if IsHandled then
                        exit;
                    if TempFinancialReport.Name <> '' then
                        AccSched.SetFinancialReportName(TempFinancialReport.Name);
                    if TempFinancialReport."Financial Report Row Group" <> '' then
                        AccSched.SetAccSchedName(TempFinancialReport."Financial Report Row Group");
                    if TempFinancialReport."Financial Report Column Group" <> '' then
                        AccSched.SetColumnLayoutName(TempFinancialReport."Financial Report Column Group");
                    if TempFinancialReport.SheetDefinition <> '' then
                        AccSched.SetSheetDefName(TempFinancialReport.SheetDefinition);
                    DateFilter2 := Rec.GetFilter("Date Filter");
                    GLBudgetFilter2 := Rec.GetFilter("G/L Budget Filter");
                    CostBudgetFilter2 := Rec.GetFilter("Cost Budget Filter");
                    BusUnitFilter := Rec.GetFilter("Business Unit Filter");
                    AccSched.SetFilters(
                        DateFilter2, GLBudgetFilter2, CostBudgetFilter2, BusUnitFilter,
                        TempFinancialReport.Dim1Filter, TempFinancialReport.Dim2Filter, TempFinancialReport.Dim3Filter, TempFinancialReport.Dim4Filter, TempFinancialReport.CashFlowFilter,
                        TempFinancialReport.GetEffectiveNegativeAmountFormat());
                    AccSched.Run();
                end;
            }
            action(PreviousColumn)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Column';
                Image = PreviousRecord;
                ToolTip = 'Go to the previous column.';

                trigger OnAction()
                begin
                    AdjustColumnOffset(-1);
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    AccSchedManagement.FindPeriod(Rec, '>=', TempFinancialReport.GetEffectivePeriodType());
                    DateFilter := Rec.GetFilter("Date Filter");
                    UpdateColumnCaptions();
                end;
            }
            action(PreviousPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    AccSchedManagement.FindPeriod(Rec, '<=', TempFinancialReport.GetEffectivePeriodType());
                    DateFilter := Rec.GetFilter("Date Filter");
                    UpdateColumnCaptions();
                end;
            }
            action(NextColumn)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Column';
                Image = NextRecord;
                ToolTip = 'Go to the next column.';

                trigger OnAction()
                begin
                    AdjustColumnOffset(1);
                end;
            }
            action(Recalculate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recalculate';
                Image = Refresh;
                ToolTip = 'Update the financial report data based on recent changes.';

                trigger OnAction()
                begin
                    AccSchedManagement.ForceRecalculate(true);
                end;
            }
            action(RestoreFinRepFilters)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Revert to defaults';
                Image = Restore;
                ToolTip = 'Restore the user defined filters to the default filters stored on the financial report';
                Visible = ViewOnlyMode;

                trigger OnAction()
                begin
                    RestoreFinancialReportUserFilters();
                end;
            }
            action(EditDefinition)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit report definition';
                Image = Edit;
                ToolTip = 'Edit the report definition for all users';
                Enabled = ViewOnlyMode;

                trigger OnAction()
                var
                    AccScheduleOverview: Page "Acc. Schedule Overview";
                begin
                    CurrPage.Close();
                    AccScheduleOverview.SetViewOnlyMode(false);
                    AccScheduleOverview.SetFinancialReportName(TempFinancialReport.Name);
                    AccScheduleOverview.Run();
                end;
            }
            action(EditRowDefinition)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit row definition';
                Image = Edit;
                ToolTip = 'Edit the row definition of this financial report.';

                trigger OnAction()
                var
                    AccSchedule: Page "Account Schedule";
                begin
                    AccSchedule.SetAccSchedName(TempFinancialReport."Financial Report Row Group");
                    AccSchedule.Run();
                end;
            }
            action(EditColumnDefinition)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit column definition';
                Image = Edit;
                ToolTip = 'Create or edit the column definition of this financial report.';

                trigger OnAction()
                var
                    ColumnLayout: Page "Column Layout";
                begin
                    ColumnLayout.SetColumnLayoutName(TempFinancialReport."Financial Report Column Group");
                    ColumnLayout.Run();
                end;
            }
            action(EditSheetDefinition)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit sheet definition';
                Image = Edit;
                ToolTip = 'Edit the sheet definition of this financial report.';

                trigger OnAction()
                var
                    SheetDefLine: Record "Sheet Definition Line";
                begin
                    TempFinancialReport.TestField(SheetDefinition);
                    SheetDefLine.SetRange(Name, TempFinancialReport.SheetDefinition);
                    Page.Run(0, SheetDefLine);
                end;
            }
            action(EditIntroductoryClosingParagraph)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit introductory/closing paragraphs';
                Image = Edit;
                ToolTip = 'Edit the introductory and closing paragraphs of this financial report.';

                trigger OnAction()
                var
                    EditFinancialReportText: Page "Edit Financial Report Text";
                begin
                    EditFinancialReportText.SetText(IntroductoryParagraph, ClosingParagraph);
                    if EditFinancialReportText.RunModal() = Action::Ok then begin
                        EditFinancialReportText.GetText(IntroductoryParagraph, ClosingParagraph);
                        SaveStateToFinancialReport();
                    end;
                end;
            }

            group(DisplayOptions)
            {
                Caption = 'Show';
                Enabled = ViewOnlyMode;
                AboutTitle = 'Toggle between different display options in view mode';
                AboutText = 'From this menu, select one of three view options. The first option None will hide everything besides the sheet. The second option Show Filters will show the dimension filters and the sheet. The third option All will show the Options for Row, Column and Periods and the dimension filters';

                action(DisplayNone)
                {
                    Caption = 'Hide options';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the page should be viewed with no filter options displayed';
                    Enabled = ViewLayout <> "Financial Report View Layout"::"Show None";
                    Image = ClearFilter;
                    trigger OnAction()
                    begin
                        ViewLayout := "Financial Report View Layout"::"Show None";
                        CurrPage.Update(false);
                    end;
                }
                action(DisplayFiltersOnly)
                {
                    Caption = 'Show filters';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the page should be viewed with dimension filter options displayed';
                    Enabled = ViewLayout <> "Financial Report View Layout"::"Show Filters Only";
                    Image = Filter;
                    trigger OnAction()
                    begin
                        ViewLayout := "Financial Report View Layout"::"Show Filters Only";
                        CurrPage.Update(false);
                    end;
                }
                action(DisplayAll)
                {
                    Caption = 'Show all options';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the page should be viewed with options and dimension filters';
                    Enabled = ViewLayout <> "Financial Report View Layout"::"Show All";
                    Image = FilterLines;
                    trigger OnAction()
                    begin
                        ViewLayout := "Financial Report View Layout"::"Show All";
                        CurrPage.Update(false);
                    end;
                }
            }
            action(Schedules)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Schedules';
                ToolTip = 'View or edit schedules for this financial report. This allows you to schedule the financial report to be exported or emailed on a regular basis. You can also customize the filters and recipients for each schedule.';
                Image = CheckList;

                trigger OnAction()
                var
                    FinancialReportSchedule: Record "Financial Report Schedule";
                begin
                    FinancialReportSchedule.SetRange("Financial Report Name", TempFinancialReport.Name);
                    Page.Run(0, FinancialReportSchedule);
                end;
            }

            group(Excel)
            {
                Caption = 'Excel';
                group("Export to Excel")
                {
                    Caption = 'Export to Excel';
                    Image = ExportToExcel;
                    action(ExportToExcel)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Open in Excel (using layout)';
                        ToolTip = 'Open the financial report in a new Excel workbook. This will use the default Excel layout specified on the financial report.';
                        Image = ExportToExcel;

                        trigger OnAction()
                        var
                            FinReportExcelTemplate: Record "Fin. Report Excel Template";
                            ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
                        begin
                            ExportAccSchedToExcel.SetOptions(
                                Rec, TempFinancialReport."Financial Report Column Group", TempFinancialReport.UseAmountsInAddCurrency,
                                TempFinancialReport.Name, TempFinancialReport.SheetDefinition);
                            if TempFinancialReport."Excel Template Code" <> '' then begin
                                FinReportExcelTemplate.Get(TempFinancialReport.Name, TempFinancialReport."Excel Template Code");
                                ExportAccSchedToExcel.SetUseExistingTemplate(FinReportExcelTemplate);
                            end;
                            ExportAccSchedToExcel.Run();
                        end;
                    }
                    action(ExcelTemplates)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Excel Layouts';
                        ToolTip = 'View or edit Excel layout for this financial report.';
                        Image = Report;

                        trigger OnAction()
                        var
                            FinReportExcelTemplates: Page "Fin. Report Excel Templates";
                        begin
                            FinReportExcelTemplates.SetSource(TempFinancialReport, Rec);
                            FinReportExcelTemplates.Run();
                        end;
                    }
#if not CLEAN26
                    action("Create New Document")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create New Excel template';
                        Image = ExportToExcel;
                        ToolTip = 'Open the financial report in a new Excel workbook. This creates an Excel workbook on your device that you can use as a template for an Excel version of the report. This feature has been replaced by Excel Layouts and will be removed in a future release.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Replaced by Export to Excel and the Financial Report Excel Layout feature.';
                        ObsoleteTag = '26.0';

                        trigger OnAction()
                        var
                            ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
                        begin
                            ExportAccSchedToExcel.SetOptions(
                                Rec, TempFinancialReport."Financial Report Column Group", TempFinancialReport.UseAmountsInAddCurrency,
                                TempFinancialReport.Name, TempFinancialReport.SheetDefinition);
                            ExportAccSchedToExcel.Run();
                        end;
                    }
                    action("Update Existing Document")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update Excel template with data';
                        Image = ExportToExcel;
                        ToolTip = 'Upload an Excel template workbook and get an updated Excel workbook downloaded it to your device. You must specify the template workbook that you want to update. This feature has been replaced by Excel Layouts and will be removed in a future release.';
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Replaced by Excel Templates and the Financial Report Excel Layout feature.';
                        ObsoleteTag = '26.0';

                        trigger OnAction()
                        var
                            ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
                        begin
                            ExportAccSchedToExcel.SetOptions(
                                Rec, TempFinancialReport."Financial Report Column Group", TempFinancialReport.UseAmountsInAddCurrency,
                                TempFinancialReport.Name, TempFinancialReport.SheetDefinition);
                            ExportAccSchedToExcel.SetUpdateExistingWorksheet(true);
                            ExportAccSchedToExcel.Run();
                        end;
                    }
#endif
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Recalculate_Promoted; Recalculate)
                {
                }
                actionref(RestoreFinRepFilters_Promoted; RestoreFinRepFilters)
                {
                }
            }
            group(DisplayPromoted)
            {
                Caption = 'Show';
                ShowAs = SplitButton;
                actionref(ShowNone_Promoted; DisplayNone)
                {
                }
                actionref(ShowFiltersOnly_Promoted; DisplayFiltersOnly)
                {
                }
                actionref(ShowAll_Promoted; DisplayAll)
                {
                }
            }

            group(Category_Category4)
            {
                Caption = 'Column', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(PreviousColumn_Promoted; PreviousColumn)
                {
                }
                actionref(NextColumn_Promoted; NextColumn)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Period', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(PreviousPeriod_Promoted; PreviousPeriod)
                {
                }
                actionref(NextPeriod_Promoted; NextPeriod)
                {
                }
            }
            group("Category_Export to Excel")
            {
                Caption = 'Export to Excel/Print';

                actionref(ExportToExcel_Promoted; ExportToExcel)
                {
                }
#if not CLEAN26
#pragma warning disable AL0432
                actionref("Create New Document_Promoted"; "Create New Document")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Export to Excel and the Financial Report Excel Layout feature.';
                    ObsoleteTag = '26.0';
                }
                actionref("Update Existing Document_Promoted"; "Update Existing Document")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Replaced by Export to Excel and the Financial Report Excel Layout feature.';
                    ObsoleteTag = '26.0';
                }
#pragma warning restore AL0432
#endif
                actionref(Print_Promoted; Print)
                {
                }
            }
            group(Category_Definitions)
            {
                Caption = 'Definitions';
                actionref(EditDefinition_Promoted; EditDefinition)
                {
                }
                actionref(EditRowDefinition_Promoted; EditRowDefinition)
                {
                }
                actionref(EditColumnDefinition_Promoted; EditColumnDefinition)
                {
                }
                actionref(EditSheetDefinition_Promoted; EditSheetDefinition)
                {
                }
                actionref(EditIntroductoryClosingParagraph_Promoted; EditIntroductoryClosingParagraph)
                {
                }
                actionref(ExcelTemplates_Promoted; ExcelTemplates)
                {
                }
                actionref(Schedules_Promoted; Schedules)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnClosePage()
    begin
        // In View mode without a Financial report, the page closes without saving anything
        if ViewOnlyMode and (TempFinancialReport.Name = '') then
            exit;
        // In Edit mode changes are saved to the corresponding FinancialReport and the filters for this user are removed
        if not ViewOnlyMode then begin
            if not StateHasUserChanges() then
                exit;
            SaveStateToFinancialReport();
            RemoveUserFilters();
            exit;
        end;
        // In View mode with a Financial Report, if the user made changes, we save the changes made by the user to user filters
        if StateHasUserChanges() then
            SaveStateToUserFilters();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(MarkAndFilterRowsOnFind(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        LoadColumns();
    end;

    trigger OnInit()
    begin
        Dim4FilterEnable := true;
        Dim3FilterEnable := true;
        Dim2FilterEnable := true;
        Dim1FilterEnable := true;
    end;

    trigger OnOpenPage()
    begin
        Clear(Rec);
        Clear(TempFinancialReport);
        ViewLayout := ViewLayout::"Show All";
        ReloadPage();
        LogUsageTelemetry();
#if not CLEAN28
        FinancialReportDefaultsEnabled := FeatureFinancialReportDef.IsDefaultsFeatureEnabled();
#endif
    end;

    var
        // Filters set in this page
        // Helper records keeping computed state of the page
        AccSchedName: Record "Acc. Schedule Name";
        GLSetup: Record "General Ledger Setup";
        // Helper codeunits
        MatrixMgt: Codeunit "Matrix Management";
        DimensionManagement: Codeunit DimensionManagement;
        FinReportMgt: Codeunit "Financial Report Mgt.";
#if not CLEAN28
#pragma warning disable AL0432
        FeatureFinancialReportDef: Codeunit "Feature - Fin. Report Default";
#pragma warning restore AL0432
#endif
        // Filter set in this page
        DateFilter: Text;
        // Helper page state variables
        ViewLayout: Enum "Financial Report View Layout";
        ViewOnlyModeSet: Boolean;
#if not CLEAN26
        FinancialReportSummaryTxt: Text;
#endif
        ColumnLayoutArr: array[15] of Record "Column Layout";
        ColumnValues: array[15] of Decimal;
        ColumnCaptions: array[15] of Text;
        UseAmtsInAddCurrVisible: Boolean;
        NoOfColumns: Integer;
        ColumnOffset: Integer;
        // Constants
        Text000Tok: Label 'DEFAULT', MaxLength = 10;
#pragma warning disable AA0470
        Text005Tok: Label '1,6,,Dimension %1 Filter';
#pragma warning restore AA0470
#pragma warning disable AA0074
        EditModeMessage: Label 'All changes made to this page are persistent and visible to all users immediately';
#pragma warning restore AA0074
        PageRunEventTxt: Label 'Financial Report run on-screen: %1', Comment = '%1 = financial report name', Locked = true;
        // Other page state
        Dim1FilterEnable: Boolean;
        Dim2FilterEnable: Boolean;
        Dim3FilterEnable: Boolean;
        Dim4FilterEnable: Boolean;
        ColumnStyle1: Text;
        ColumnStyle2: Text;
        ColumnStyle3: Text;
        ColumnStyle4: Text;
        ColumnStyle5: Text;
        ColumnStyle6: Text;
        ColumnStyle7: Text;
        ColumnStyle8: Text;
        ColumnStyle9: Text;
        ColumnStyle10: Text;
        ColumnStyle11: Text;
        ColumnStyle12: Text;
        ColumnStyle13: Text;
        ColumnStyle14: Text;
        ColumnStyle15: Text;
        IntroductoryParagraph, ClosingParagraph : Text;
#if not CLEAN28
        FinancialReportDefaultsEnabled: Boolean;
#endif

    protected var
        AnalysisView: Record "Analysis View";
        TempColumnLayout: Record "Column Layout" temporary;
        TempFinancialReport: Record "Financial Report" temporary;
        AccSchedManagement: Codeunit AccSchedManagement;
        // These variables are unused but kept in sync for retrocompatibility purposes
        FinancialReportCode: Code[10];
        CurrentColumnName: Code[10];
        UseAmtsInAddCurr: Boolean;
        // Page setup variables: Set by the user through public procedures to alter the OnOpen of this page
        NewCurrentSchedName: Code[10];
        NewCurrentColumnName: Code[10];
        ModifiedPeriodType: Enum "Analysis Period Type";
        ViewOnlyMode: Boolean;

    procedure SetFinancialReportName(NewFinancialReport: Code[10])
    begin
        FinancialReportCode := NewFinancialReport;
    end;

    procedure SetColumnDefinition(ColumnLayoutName: Code[10])
    begin
        NewCurrentColumnName := ColumnLayoutName;
    end;

    procedure SetAccSchedName(NewAccSchedName: Code[10])
    begin
        NewCurrentSchedName := NewAccSchedName;
    end;

    procedure SetPeriodType(NewPeriodType: Option)
    begin
        ModifiedPeriodType := "Analysis Period Type".FromInteger(NewPeriodType);
    end;

    procedure SetViewOnlyMode(NewViewOnlyMode: Boolean)
    begin
        ViewOnlyMode := NewViewOnlyMode;
        ViewOnlyModeSet := true;
    end;

    local procedure MarkAndFilterRowsOnFind(Which: Text): Boolean
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        SelectedRecordMarked: Boolean;
        ColumnNo: Integer;
    begin
        Rec.MarkedOnly(false);
        AccScheduleLine := Rec;
        if not TempFinancialReport.ShowLinesWithShowNo then begin
            if Rec.FindSet() then
                repeat
                    if Rec.Show = Rec.Show::Yes then
                        Rec.Mark(true)
                    else begin
                        Rec.Mark(false);
                        LoadColumns();
                        ColumnNo := 1;
                        while ColumnNo <= ArrayLen(ColumnValues) do begin
                            ColumnValues[ColumnNo] *= Rec."Show Opposite Sign" ? -1 : 1;
                            case Rec.Show of
                                Rec.Show::"If Any Column Not Zero":
                                    if ColumnValues[ColumnNo] <> 0 then
                                        Rec.Mark(true);
                                Rec.Show::"When Positive Balance":
                                    if ColumnValues[ColumnNo] > 0 then
                                        Rec.Mark(true);
                                Rec.Show::"When Negative Balance":
                                    if ColumnValues[ColumnNo] < 0 then
                                        Rec.Mark(true);
                            end;
                            if Rec.Mark() then
                                ColumnNo := ArrayLen(ColumnValues);
                            ColumnNo += 1;
                        end;
                    end;
                    if Rec.Mark() and (AccScheduleLine.SystemId = Rec.SystemId) then
                        SelectedRecordMarked := true;
                until Rec.Next() = 0
            else
                exit(false);

            Rec.MarkedOnly(true);
            if SelectedRecordMarked then
                Rec := AccScheduleLine;
        end;
        exit(Rec.Find(Which));
    end;

    local procedure ReloadPage()
    var
        EditModeNotification: Notification;
    begin
        EditModeNotification.Message := EditModeMessage;
        EditModeNotification.Scope := NotificationScope::LocalScope;
        if not ViewOnlyModeSet then
            ViewOnlyMode := true;
        if not ViewOnlyMode then
            EditModeNotification.Send();
        LoadPageState();
    end;

    protected procedure LoadPageState()
    var
        IsHandled: Boolean;
    begin
        GLSetup.Get();
        UseAmtsInAddCurrVisible := GLSetup."Additional Reporting Currency" <> '';
        if FinancialReportCode = '' then
            FinancialReportCode := TempFinancialReport.Name;

        // `FinancialReportTemp` contains the state of the filters the user interacts with
        // `LoadFinancialReportFiltersOrDefault` loads this temporary record considering user overriden filters (if any).
        LoadFinancialReportFiltersOrDefault(TempFinancialReport);

        // Afterwards, we update all page state variables 
        SetFinancialReportTxt();

        IsHandled := false;
        Rec.SetLoadFields("Row No.", "Description", "Totaling", "Totaling Type", "Dimension 1 Totaling", "Dimension 2 Totaling", "Dimension 3 Totaling", "Dimension 4 Totaling", Bold, "Show Opposite Sign", "Row Type", "Amount Type");
        OnLoadPageStateOnBeforeCopyColumnsToTemp(CurrentColumnName, TempColumnLayout, TempFinancialReport."Financial Report Row Group", Rec, IsHandled);
        if not IsHandled then begin
            AccSchedManagement.CopyColumnsToTemp(TempFinancialReport."Financial Report Column Group", TempColumnLayout);
            AccSchedManagement.OpenSchedule(TempFinancialReport."Financial Report Row Group", Rec);
        end;
        AccSchedManagement.OpenColumns(TempFinancialReport."Financial Report Column Group", TempColumnLayout);
        AccSchedManagement.CheckAnalysisView(TempFinancialReport."Financial Report Row Group", TempFinancialReport."Financial Report Column Group", true);
        SetLoadedDimFilters();
        SetLoadedOtherFilters();

        if AccSchedName.Get(TempFinancialReport."Financial Report Row Group") then
            if AccSchedName."Analysis View Name" <> '' then
                AnalysisView.Get(AccSchedName."Analysis View Name")
            else begin
                Clear(AnalysisView);
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;

        FinReportMgt.CalcAccScheduleLineDateFilter(TempFinancialReport, Rec);
        ApplyShowFilter();
        UpdateDimFilterControls();
        DateFilter := Rec.GetFilter("Date Filter");
        UpdateColumnCaptions();
        OnBeforeCurrentColumnNameOnAfterValidate(TempFinancialReport."Financial Report Column Group");
        OnAfterOnOpenPage(Rec, TempFinancialReport."Financial Report Column Group");
    end;

    local procedure LoadColumns()
    var
        ColumnNo: Integer;
    begin
        Clear(ColumnValues);

        if (Rec.Totaling = '') or (not TempColumnLayout.FindSet()) or (Rec."Schedule Name" <> TempFinancialReport."Financial Report Row Group") then
            exit;

        repeat
            ColumnNo := ColumnNo + 1;
            if (ColumnNo > ColumnOffset) and (ColumnNo - ColumnOffset <= ArrayLen(ColumnValues)) then begin
                ColumnValues[ColumnNo - ColumnOffset] :=
                  RoundIfNotNone(
                    MatrixMgt.RoundAmount(
                      AccSchedManagement.CalcCell(Rec, TempColumnLayout, TempFinancialReport.UseAmountsInAddCurrency),
                      TempColumnLayout."Rounding Factor"),
                    TempColumnLayout."Rounding Factor");
                OnOnAfterGetRecordOnAfterAssignColumnValue(ColumnValues, ColumnNo, ColumnOffset, TempColumnLayout, TempFinancialReport.UseAmountsInAddCurrency);
                ColumnLayoutArr[ColumnNo - ColumnOffset] := TempColumnLayout;
                GetStyle(ColumnNo - ColumnOffset, Rec."Line No.", TempColumnLayout."Line No.");
            end;
        until TempColumnLayout.Next() = 0;
        AccSchedManagement.ForceRecalculate(false);
    end;

    local procedure ValidateStartEndDateFilterFormula()
    begin
        if (Format(TempFinancialReport.StartDateFilterFormula) = '') and
            (Format(TempFinancialReport.EndDateFilterFormula) = '')
        then
            exit;
        Clear(TempFinancialReport.DateFilterPeriodFormula);
        Clear(TempFinancialReport.DateFilterPeriodFormulaLID);
        CalcDateFilterAndUpdate();
    end;

    local procedure ValidateDateFilterPeriodFormula()
    var
        PeriodFormulaParser: Codeunit "Period Formula Parser";
    begin
        if TempFinancialReport.DateFilterPeriodFormula = '' then
            exit;
        PeriodFormulaParser.ValidatePeriodFormula(
            TempFinancialReport.DateFilterPeriodFormula, TempFinancialReport.DateFilterPeriodFormulaLID);
        Clear(TempFinancialReport.StartDateFilterFormula);
        Clear(TempFinancialReport.EndDateFilterFormula);
        CalcDateFilterAndUpdate();
    end;

    local procedure CalcDateFilterAndUpdate()
    begin
        FinReportMgt.CalcAccScheduleLineDateFilter(TempFinancialReport, Rec);
        DateFilter := Rec.GetFilter("Date Filter");
        UpdateColumnCaptions();
        CurrPage.Update();
    end;

    local procedure LoadFinancialReportFilters(FinancialReportCode: Code[10]; var FinancialReportToLoadTemp: Record "Financial Report" temporary): Boolean
    var
        FinancialReport: Record "Financial Report";
        FinancialReportUserFilters: Record "Financial Report User Filters";
        Field: Record "Field";
        RecordRefFinancialReport: RecordRef;
        RecordRefUserFilters: RecordRef;
        FieldRefFinancialReport: FieldRef;
        FieldRefUserFilters: FieldRef;
        UserIDCode: Code[50];
    begin
        if not FinancialReport.Get(FinancialReportCode) then
            exit(false);
        // Transfer filters from FinancialReport
        FinancialReportToLoadTemp.Init();
        FinancialReportToLoadTemp.TransferFields(FinancialReport);
        IntroductoryParagraph := FinancialReport.GetIntroductoryParagraph();
        ClosingParagraph := FinancialReport.GetClosingParagraph();
        if not ViewOnlyMode then
            exit(true);
        UserIDCode := CopyStr(UserId(), 1, MaxStrLen(UserIDCode));
        if not FinancialReportUserFilters.Get(UserIDCode, FinancialReport.Name) then
            exit(true);
        // Override custom user filters
        Field.SetRange(TableNo, Database::"Financial Report User Filters");
        Field.SetFilter("No.", '<>%1', FinancialReportUserFilters.FieldNo("User ID"));
        Field.SetFilter("No.", '<>%1 & <>%2 & < %3', FinancialReportUserFilters.FieldNo("User ID"), FinancialReportUserFilters.FieldNo("Financial Report Name"), 2000000000);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        RecordRefUserFilters.GetTable(FinancialReportUserFilters);
        if Field.FindSet() then
            repeat
                // We go through each of the user filter fields
                FieldRefUserFilters := RecordRefUserFilters.Field(Field."No.");
                if FieldRefNotBlank(FieldRefUserFilters) then begin
                    // If it is not empty we set the corresponding value in FinancialReportToLoadTemp
                    RecordRefFinancialReport.GetTable(FinancialReportToLoadTemp);
                    FieldRefFinancialReport := RecordRefFinancialReport.Field(Field."No.");
                    FieldRefFinancialReport.Value(FieldRefUserFilters.Value);
                    RecordRefFinancialReport.SetTable(FinancialReportToLoadTemp);
                end
            until Field.Next() = 0;
        RecordRefFinancialReport.Close();
        RecordRefUserFilters.Close();
        exit(true);
    end;

    local procedure LoadFinancialReportFiltersOrDefault(var FinancialReportToLoadTemp: Record "Financial Report" temporary)
    begin
        LoadFinancialReportFiltersOrDefault(FinancialReportCode, FinancialReportToLoadTemp);
    end;

    local procedure LoadFinancialReportFiltersOrDefault(FinancialReportToLoadCode: Code[10]; var FinancialReportToLoadTemp: Record "Financial Report" temporary)
    var
        FinancialReportLoaded: Boolean;
    begin
        // Every filter the user interacts with in this page is kept in FinancialReportTemp
        FinancialReportLoaded := LoadFinancialReportFilters(FinancialReportToLoadCode, FinancialReportToLoadTemp);
        if not FinancialReportLoaded then begin
            // If no financial report is set, view mode is forced
            ViewOnlyMode := true;
            FinancialReportToLoadTemp.Init();
            // We get values from the other page setup variables
            if NewCurrentSchedName = '' then
                NewCurrentSchedName := CopyStr(Text000Tok, 1, 10);
            if NewCurrentColumnName = '' then
                NewCurrentColumnName := CopyStr(Text000Tok, 1, 10);

            FinancialReportToLoadTemp."Financial Report Row Group" := NewCurrentSchedName;
            FinancialReportToLoadTemp."Financial Report Column Group" := NewCurrentColumnName;
            // (Every change to FinancialReportTemp."Financial Report Column Group" must be kept in sync with CurrentColumnName)
            CurrentColumnName := NewCurrentColumnName;

#if not CLEAN28
            if not FeatureFinancialReportDef.IsDefaultsFeatureEnabled() then
                FinancialReportToLoadTemp.PeriodType := ModifiedPeriodType
            else
#endif
            FinancialReportToLoadTemp.PeriodTypeDefault := "Financial Report Period Type".FromInteger(ModifiedPeriodType.AsInteger());
            FinancialReportToLoadTemp.UseAmountsInAddCurrency := false;
            // (Every change to FinancialReportTemp.UseAmountsInAddCurrency must be kept in sync with UseAmtsInAddCurr)
            UseAmtsInAddCurr := false;
        end;
        // Default values
        if FinancialReportToLoadTemp."Financial Report Column Group" = '' then begin
            FinancialReportToLoadTemp."Financial Report Column Group" := CopyStr(Text000Tok, 1, 10);
            // (Every change to FinancialReportTemp."Financial Report Column Group" must be kept in sync with CurrentColumnName)
            CurrentColumnName := CopyStr(Text000Tok, 1, 10);
        end;
    end;

    local procedure RestoreFinancialReportUserFilters()
    var
        FinancialReportUserFilters: Record "Financial Report User Filters";
        UserIDCode: Code[50];
    begin
        UserIDCode := CopyStr(UserId(), 1, MaxStrLen(UserIDCode));

        if FinancialReportUserFilters.Get(UserIDCode, TempFinancialReport.Name) then
            FinancialReportUserFilters.Delete();
        LoadPageState();
    end;

#if not CLEAN26
    local procedure AddSummaryPart(var SummaryTxt: Text; PartTxt: Text)
    begin
        if PartTxt = '' then
            exit;
        if SummaryTxt <> '' then
            SummaryTxt += ' - ';
        SummaryTxt += PartTxt;
    end;
#endif

    local procedure SetFinancialReportTxt()
    var
        CurrentPageCaption: Text;
    begin
        if TempFinancialReport.Description <> '' then
            CurrentPageCaption := StrSubstNo('%1 (%2)', TempFinancialReport.Description, TempFinancialReport.Name)
        else
            CurrentPageCaption := TempFinancialReport.Name;
        CurrPage.Caption(CurrentPageCaption);
#if not CLEAN26
        FinancialReportSummaryTxt := '';
        AddSummaryPart(FinancialReportSummaryTxt, TempFinancialReport.Name);
        AddSummaryPart(FinancialReportSummaryTxt, TempFinancialReport.Description);
        AddSummaryPart(FinancialReportSummaryTxt, TempFinancialReport."Financial Report Row Group");
        AddSummaryPart(FinancialReportSummaryTxt, TempFinancialReport."Financial Report Column Group");
#endif
    end;

    [TryFunction]
    local procedure FieldRefNotBlank(FieldRef: FieldRef)
    begin
        FieldRef.TestField();
    end;

    local procedure ValidateCostCenterFilter()
    var
        CurrentCostCenterFilter: Text;
        CurrentDim1Filter: Text;
    begin
        if TempFinancialReport.CostCenterFilter = '' then
            Rec.SetRange("Cost Center Filter")
        else
            Rec.SetFilter("Cost Center Filter", TempFinancialReport.CostCenterFilter);
        CurrentCostCenterFilter := TempFinancialReport.CostCenterFilter;
        CurrentDim1Filter := TempFinancialReport.Dim1Filter;
        OnAfterValidateCostCenterFilter(Rec, CurrentCostCenterFilter, CurrentDim1Filter);
        TempFinancialReport.CostCenterFilter := CopyStr(CurrentCostCenterFilter, 1, MaxStrLen(TempFinancialReport.CostCenterFilter));
        TempFinancialReport.Dim1Filter := CopyStr(CurrentDim1Filter, 1, MaxStrLen(TempFinancialReport.Dim1Filter));
    end;

    local procedure ValidateCostObjectFilter()
    var
        CurrentCostObjectFilter: Text;
        CurrentDim2Filter: Text;
    begin
        if TempFinancialReport.CostObjectFilter = '' then
            Rec.SetRange("Cost Object Filter")
        else
            Rec.SetFilter("Cost Object Filter", TempFinancialReport.CostObjectFilter);
        CurrentCostObjectFilter := TempFinancialReport.CostObjectFilter;
        CurrentDim2Filter := TempFinancialReport.Dim2Filter;
        OnAfterValidateCostObjectFilter(Rec, CurrentCostObjectFilter, CurrentDim2Filter);
        TempFinancialReport.CostObjectFilter := CopyStr(CurrentCostObjectFilter, 1, MaxStrLen(TempFinancialReport.CostObjectFilter));
        TempFinancialReport.Dim2Filter := CopyStr(CurrentDim2Filter, 1, MaxStrLen(TempFinancialReport.Dim2Filter));
        CurrPage.Update();
    end;

    local procedure ValidateCashFlowFilter()
    begin
        if TempFinancialReport.CashFlowFilter = '' then
            Rec.SetRange("Cash Flow Forecast Filter")
        else
            Rec.SetFilter("Cash Flow Forecast Filter", TempFinancialReport.CashFlowFilter);
        CurrPage.Update();
    end;

    local procedure ValidateGLBudgetFilter()
    begin
        if TempFinancialReport.GLBudgetFilter = '' then
            Rec.SetRange("G/L Budget Filter")
        else
            Rec.SetFilter("G/L Budget Filter", TempFinancialReport.GLBudgetFilter);
        CurrPage.Update();
    end;

    local procedure ValidateCostBudgetFilter()
    begin
        if TempFinancialReport.CostBudgetFilter = '' then
            Rec.SetRange("Cost Budget Filter")
        else
            Rec.SetFilter("Cost Budget Filter", TempFinancialReport.CostBudgetFilter);
        CurrPage.Update();
    end;

    local procedure SetLoadedDimFilters()
    begin
        SetDimFilters(1, TempFinancialReport.Dim1Filter);
        SetDimFilters(2, TempFinancialReport.Dim2Filter);
        SetDimFilters(3, TempFinancialReport.Dim3Filter);
        SetDimFilters(4, TempFinancialReport.Dim4Filter);
    end;

    local procedure SetLoadedOtherFilters()
    begin
        ValidateGLBudgetFilter();
        ValidateCashFlowFilter();
        ValidateCostBudgetFilter();
        ValidateCostCenterFilter();
        ValidateCostObjectFilter();
    end;

    procedure SetDimFilters(DimNo: Integer; DimValueFilter: Text)
    var
        CurrentCostCenterFilter: Text;
        CurrentCostObjectFilter: Text;
        CurrentCostBudgetFilter: Text;
        CurrentCashFlowFilter: Text;
        CurrentGLBudgetFilter: Text;
    begin
        case DimNo of
            1:
                if DimValueFilter = '' then
                    Rec.SetRange("Dimension 1 Filter")
                else begin
                    DimensionManagement.ResolveDimValueFilter(DimValueFilter, AnalysisView."Dimension 1 Code");
                    Rec.SetFilter("Dimension 1 Filter", DimValueFilter);
                end;
            2:
                if DimValueFilter = '' then
                    Rec.SetRange("Dimension 2 Filter")
                else begin
                    DimensionManagement.ResolveDimValueFilter(DimValueFilter, AnalysisView."Dimension 2 Code");
                    Rec.SetFilter("Dimension 2 Filter", DimValueFilter);
                end;
            3:
                if DimValueFilter = '' then
                    Rec.SetRange("Dimension 3 Filter")
                else begin
                    DimensionManagement.ResolveDimValueFilter(DimValueFilter, AnalysisView."Dimension 3 Code");
                    Rec.SetFilter("Dimension 3 Filter", DimValueFilter);
                end;
            4:
                if DimValueFilter = '' then
                    Rec.SetRange("Dimension 4 Filter")
                else begin
                    DimensionManagement.ResolveDimValueFilter(DimValueFilter, AnalysisView."Dimension 4 Code");
                    Rec.SetFilter("Dimension 4 Filter", DimValueFilter);
                end;
        end;
        CurrentCostCenterFilter := TempFinancialReport.CostCenterFilter;
        CurrentCostObjectFilter := TempFinancialReport.CostObjectFilter;
        CurrentCostBudgetFilter := TempFinancialReport.CostBudgetFilter;
        CurrentGLBudgetFilter := TempFinancialReport.GLBudgetFilter;
        CurrentCashFlowFilter := TempFinancialReport.CashFlowFilter;
        OnAfterSetDimFilters(
            Rec, DimNo, DimValueFilter, CurrentCostCenterFilter, CurrentCostObjectFilter, CurrentCostBudgetFilter,
            CurrentGLBudgetFilter, CurrentCashFlowFilter, AnalysisView, TempFinancialReport);

        TempFinancialReport.CostCenterFilter := CopyStr(CurrentCostCenterFilter, 1, MaxStrLen(TempFinancialReport.CostCenterFilter));
        TempFinancialReport.CostObjectFilter := CopyStr(CurrentCostObjectFilter, 1, MaxStrLen(TempFinancialReport.CostObjectFilter));
        TempFinancialReport.CostBudgetFilter := CopyStr(CurrentCostBudgetFilter, 1, MaxStrLen(TempFinancialReport.CostBudgetFilter));
        TempFinancialReport.GLBudgetFilter := CopyStr(CurrentGLBudgetFilter, 1, MaxStrLen(TempFinancialReport.GLBudgetFilter));
        TempFinancialReport.CashFlowFilter := CopyStr(CurrentCashFlowFilter, 1, MaxStrLen(TempFinancialReport.CashFlowFilter));

        CurrPage.Update();
    end;

    local procedure FormGetCaptionClass(DimNo: Integer) Result: Text[250]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCaptionClass(AnalysisView, DimNo, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case DimNo of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 1 Code");

                    exit(StrSubstNo(Text005Tok, DimNo));
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 2 Code");

                    exit(StrSubstNo(Text005Tok, DimNo));
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 3 Code");

                    exit(StrSubstNo(Text005Tok, DimNo));
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 4 Code");

                    exit(StrSubstNo(Text005Tok, DimNo));
                end;
            5:
                exit(Rec.FieldCaption("Date Filter"));
            6:
                exit(Rec.FieldCaption("Cash Flow Forecast Filter"));
        end;
    end;

    local procedure DrillDown(ColumnNo: Integer)
    var
        PeriodTypeOpt: Option;
    begin
        TempColumnLayout := ColumnLayoutArr[ColumnNo];
        AccSchedManagement.DrillDownFromOverviewPage(TempColumnLayout, Rec, TempFinancialReport.GetEffectivePeriodType().AsInteger());
        PeriodTypeOpt := TempFinancialReport.GetEffectivePeriodType().AsInteger();
        OnAfterDrillDown(ColumnNo, TempColumnLayout, PeriodTypeOpt);
#if not CLEAN28
        if not FeatureFinancialReportDef.IsDefaultsFeatureEnabled() then
            TempFinancialReport.PeriodType := "Analysis Period Type".FromInteger(PeriodTypeOpt)
        else
#endif
        TempFinancialReport.PeriodTypeDefault := "Financial Report Period Type".FromInteger(PeriodTypeOpt);
    end;

    protected procedure UpdateColumnCaptions()
    var
#if not CLEAN27
        ColumnCaptions80: array[15] of Text[80];
#endif
        ColumnNo: Integer;
        i: Integer;
        IsHandled: Boolean;
    begin
#if not CLEAN27
#pragma warning disable AL0432
        for i := 1 to ArrayLen(ColumnCaptions) do
            ColumnCaptions80[i] := CopyStr(ColumnCaptions[i], 1, MaxStrLen(ColumnCaptions80[i]));
        OnBeforeUpdateColumnCaptions(ColumnCaptions80, ColumnOffset, TempColumnLayout, NoOfColumns, IsHandled);
        if IsHandled then begin
            for i := 1 to ArrayLen(ColumnCaptions80) do
                ColumnCaptions[i] := ColumnCaptions80[i];
            exit;
        end;
#pragma warning restore AL0432
#else
        IsHandled := false;
        OnBeforeUpdateColumnCaptions(ColumnCaptions, ColumnOffset, TempColumnLayout, NoOfColumns, IsHandled);
        if IsHandled then
            exit;
#endif

        Clear(ColumnCaptions);
        if TempColumnLayout.FindSet() then
            repeat
                ColumnNo := ColumnNo + 1;
                if (ColumnNo > ColumnOffset) and (ColumnNo - ColumnOffset <= ArrayLen(ColumnCaptions)) then
                    ColumnCaptions[ColumnNo - ColumnOffset] := AccSchedManagement.CalcColumnHeader(Rec, TempColumnLayout);
            until (ColumnNo - ColumnOffset = ArrayLen(ColumnCaptions)) or (TempColumnLayout.Next() = 0);
        // Set unused columns to blank to prevent RTC to display control ID as caption
        for i := ColumnNo - ColumnOffset + 1 to ArrayLen(ColumnCaptions) do
            ColumnCaptions[i] := ' ';
        NoOfColumns := ColumnNo;
    end;

    local procedure AdjustColumnOffset(Delta: Integer)
    var
        OldColumnOffset: Integer;
    begin
        OldColumnOffset := ColumnOffset;
        ColumnOffset := ColumnOffset + Delta;
        if ColumnOffset + ArrayLen(ColumnLayoutArr) > TempColumnLayout.Count then
            ColumnOffset := TempColumnLayout.Count - ArrayLen(ColumnLayoutArr);
        if ColumnOffset < 0 then
            ColumnOffset := 0;
        if ColumnOffset <> OldColumnOffset then begin
            UpdateColumnCaptions();
            CurrPage.Update(false);
        end;
    end;

    local procedure SaveStateToFinancialReport()
    var
        FinancialReport: Record "Financial Report";
    begin
        if not FinancialReport.Get(TempFinancialReport.Name) then
            exit;
        FinancialReport.TransferFields(TempFinancialReport, false);
        FinancialReport.SetIntroductionParagraph(IntroductoryParagraph);
        FinancialReport.SetClosingParagraph(ClosingParagraph);
        FinancialReport.Modify();
    end;

    local procedure RemoveUserFilters()
    var
        FinancialReportUserFilters: Record "Financial Report User Filters";
        UserIDCode: Code[50];
    begin
        UserIDCode := CopyStr(UserId(), 1, MaxStrLen(UserIDCode));
        if not FinancialReportUserFilters.Get(UserIDCode, TempFinancialReport.Name) then
            exit;
        FinancialReportUserFilters.Delete();
    end;

    local procedure BlankFieldRef(var TargetFieldRef: FieldRef)
    begin
        if (TargetFieldRef.Type = TargetFieldRef.Type::Code) or
           (TargetFieldRef.Type = TargetFieldRef.Type::Text)
        then begin
            TargetFieldRef.Value('');
            exit;
        end;
        if TargetFieldRef.Type = TargetFieldRef.Type::Boolean then begin
            TargetFieldRef.Value(false);
            exit;
        end;
        if TargetFieldRef.Type = TargetFieldRef.Type::Integer then begin
            TargetFieldRef.Value(0);
            exit;
        end;

    end;

    local procedure SaveStateToUserFilters()
    var
        FinancialReportUserFilters: Record "Financial Report User Filters";
        FinancialReport: Record "Financial Report";
        Field: Record "Field";
        RecordRefFinancialReport: RecordRef;
        RecordRefUserFilters: RecordRef;
        RecordRefFinancialReportTemp: RecordRef;
        FieldRefFinancialReport: FieldRef;
        FieldRefUserFilters: FieldRef;
        FieldRefFinancialReportTemp: FieldRef;
        UserIDCode: Code[50];
        FiltersAreDifferent: Boolean;
    begin
        if not FinancialReport.Get(TempFinancialReport.Name) then
            exit; // This condition should be unreachable through OnClose as the user is not able to modify Name
        UserIDCode := CopyStr(UserId(), 1, MaxStrLen(UserIDCode));
        if not FinancialReportUserFilters.Get(UserIDCode, TempFinancialReport.Name) then begin
            FinancialReportUserFilters.Init();
            FinancialReportUserFilters."Financial Report Name" := TempFinancialReport.Name;
            FinancialReportUserFilters."User ID" := UserIDCode;
            FinancialReportUserFilters.Insert();
            Commit();
        end;
        // We only tranfer values to `FinancialReportUserFilters` if they differ from the
        // value stored in the original definition of the corresponding `FinancialReport`.
        // If they are the same, we blank them
        RecordRefFinancialReport.GetTable(FinancialReport);
        RecordRefUserFilters.GetTable(FinancialReportUserFilters);
        RecordRefFinancialReportTemp.GetTable(TempFinancialReport);
        Field.SetRange(TableNo, Database::"Financial Report User Filters");
        Field.SetFilter("No.", '<>%1 & <>%2 & < %3', FinancialReportUserFilters.FieldNo("User ID"), FinancialReportUserFilters.FieldNo("Financial Report Name"), 2000000000);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        FiltersAreDifferent := false;
        if Field.FindSet() then
            repeat
                FieldRefFinancialReport := RecordRefFinancialReport.Field(Field."No.");
                FieldRefUserFilters := RecordRefUserFilters.Field(Field."No.");
                FieldRefFinancialReportTemp := RecordRefFinancialReportTemp.Field(Field."No.");
                // If the values modified in the page are different to the ones stored in the financial report
                // we store the modified value in the user filters
                if FieldRefFinancialReportTemp.Value <> FieldRefFinancialReport.Value then begin
                    FieldRefUserFilters.Value(FieldRefFinancialReportTemp.Value);
                    FiltersAreDifferent := true;
                end
                else // if they are the same, we blank such field in the user filters
                    BlankFieldRef(FieldRefUserFilters);
            until Field.Next() = 0;
        RecordRefUserFilters.Modify();
        RecordRefFinancialReport.Close();
        RecordRefUserFilters.Close();
        RecordRefFinancialReportTemp.Close();
        if FiltersAreDifferent then
            exit;
        Commit();
        if FinancialReportUserFilters.Get(UserIDCode, TempFinancialReport.Name) then
            FinancialReportUserFilters.Delete();
    end;

    local procedure StateHasUserChanges(): Boolean
    var
        TempOriginalFinancialReport: Record "Financial Report" temporary;
        Field: Record "Field";
        RecordRefFinancialReport: RecordRef;
        RecordRefOriginalFinancialReport: RecordRef;
        FieldRefFinancialReport: FieldRef;
        FieldRefOriginalFinancialReport: FieldRef;
    begin
        // To determine whether changes were made, we load the original definition
        LoadFinancialReportFiltersOrDefault(TempFinancialReport.Name, TempOriginalFinancialReport);
        Field.SetRange(TableNo, Database::"Financial Report");
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        RecordRefOriginalFinancialReport.GetTable(TempOriginalFinancialReport);
        RecordRefFinancialReport.GetTable(TempFinancialReport);
        // And then we compare each field of the current `FinancialReportTemp`
        if Field.FindSet() then
            repeat
                FieldRefOriginalFinancialReport := RecordRefOriginalFinancialReport.Field(Field."No.");
                FieldRefFinancialReport := RecordRefFinancialReport.Field(Field."No.");
                // If there is any of those different, the user made a change
                if FieldRefFinancialReport.Value <> FieldRefOriginalFinancialReport.Value then begin
                    RecordRefFinancialReport.Close();
                    RecordRefOriginalFinancialReport.Close();
                    exit(true);
                end;
            until Field.Next() = 0;
        RecordRefFinancialReport.Close();
        RecordRefOriginalFinancialReport.Close();
        exit(false);
    end;

    local procedure ApplyShowFilter()
    begin
        if not TempFinancialReport.ShowLinesWithShowNo then
            Rec.SetFilter(Show, '<>%1', Rec.Show::No)
        else
            Rec.SetRange(Show);
    end;

    local procedure UpdateDimFilterControls()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDimFilterControls(Rec, AnalysisView, IsHandled);
        if IsHandled then
            exit;

        TempFinancialReport.Dim1Filter := CopyStr(Rec.GetFilter("Dimension 1 Filter"), 1, MaxStrLen(TempFinancialReport.Dim1Filter));
        TempFinancialReport.Dim2Filter := CopyStr(Rec.GetFilter("Dimension 2 Filter"), 1, MaxStrLen(TempFinancialReport.Dim2Filter));
        TempFinancialReport.Dim3Filter := CopyStr(Rec.GetFilter("Dimension 3 Filter"), 1, MaxStrLen(TempFinancialReport.Dim3Filter));
        TempFinancialReport.Dim4Filter := CopyStr(Rec.GetFilter("Dimension 4 Filter"), 1, MaxStrLen(TempFinancialReport.Dim4Filter));
        Dim1FilterEnable := AnalysisView."Dimension 1 Code" <> '';
        Dim2FilterEnable := AnalysisView."Dimension 2 Code" <> '';
        Dim3FilterEnable := AnalysisView."Dimension 3 Code" <> '';
        Dim4FilterEnable := AnalysisView."Dimension 4 Code" <> '';
        OnAfterUpdateDimFilterControls(Dim4FilterEnable);
    end;

    local procedure CurrentSchedNameOnAfterValidate()
    var
        AccSchedName2: Record "Acc. Schedule Name";
        PrevAnalysisView: Record "Analysis View";
    begin
        AccSchedManagement.SetName(TempFinancialReport."Financial Report Row Group", Rec);
        AccSchedManagement.SetAnalysisViewRead(false);
        AccSchedManagement.CheckAnalysisView(TempFinancialReport."Financial Report Row Group", TempFinancialReport."Financial Report Column Group", true);

        if AccSchedName2."Analysis View Name" <> AnalysisView.Code then begin
            PrevAnalysisView := AnalysisView;
            if AccSchedName2."Analysis View Name" <> '' then
                AnalysisView.Get(AccSchedName2."Analysis View Name")
            else begin
                Clear(AnalysisView);
                AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
            if PrevAnalysisView."Dimension 1 Code" <> AnalysisView."Dimension 1 Code" then
                Rec.SetRange("Dimension 1 Filter");
            if PrevAnalysisView."Dimension 2 Code" <> AnalysisView."Dimension 2 Code" then
                Rec.SetRange("Dimension 2 Filter");
            if PrevAnalysisView."Dimension 3 Code" <> AnalysisView."Dimension 3 Code" then
                Rec.SetRange("Dimension 3 Filter");
            if PrevAnalysisView."Dimension 4 Code" <> AnalysisView."Dimension 4 Code" then
                Rec.SetRange("Dimension 4 Filter");
        end;
        UpdateDimFilterControls();
        TempFinancialReport.CostCenterFilter := '';
        TempFinancialReport.CostObjectFilter := '';
        TempFinancialReport.CashFlowFilter := '';
        TempFinancialReport.GLBudgetFilter := '';
        TempFinancialReport.CostBudgetFilter := '';

        if not ViewOnlyMode then
            SaveStateToFinancialReport();

        CurrPage.Update(false);
    end;

    protected procedure CurrentColumnNameOnAfterValidate()
    begin
        OnBeforeCurrentColumnNameOnAfterValidate(TempFinancialReport."Financial Report Column Group");

        AccSchedManagement.CopyColumnsToTemp(TempFinancialReport."Financial Report Column Group", TempColumnLayout);
        AccSchedManagement.SetColumnName(TempFinancialReport."Financial Report Column Group", TempColumnLayout);
        AccSchedManagement.SetAnalysisViewRead(false);
        AccSchedManagement.CheckAnalysisView(TempFinancialReport."Financial Report Row Group", TempFinancialReport."Financial Report Column Group", true);
        ColumnOffset := 0;
        UpdateColumnCaptions();
        CurrPage.Update(false);

        if not ViewOnlyMode then
            SaveStateToFinancialReport();
    end;

    procedure FormatStr(ColumnNo: Integer): Text
    var
        AddCurrency: Boolean;
        Result: Text;
        IsHandled: Boolean;
    begin
        GLSetup.Get();
        AddCurrency := TempFinancialReport.UseAmountsInAddCurrency and (GLSetup."Additional Reporting Currency" <> '');
        OnAfterFormatStr(ColumnLayoutArr, UseAmtsInAddCurr, ColumnNo, TempFinancialReport.GetEffectiveNegativeAmountFormat(), Result, IsHandled);
        if IsHandled then
            exit(Result);
        exit(MatrixMgt.FormatRoundingFactor(ColumnLayoutArr[ColumnNo]."Rounding Factor", UseAmtsInAddCurr, TempFinancialReport.GetEffectiveNegativeAmountFormat()));
    end;

    procedure RoundIfNotNone(Value: Decimal; RoundingFactor: Enum "Analysis Rounding Factor"): Decimal
    begin
        if RoundingFactor <> RoundingFactor::None then
            exit(Value);

        exit(Round(Value));
    end;

    local procedure GetStyle(ColumnNo: Integer; RowLineNo: Integer; ColumnLineNo: Integer)
    var
        ColumnStyle: Text;
        ErrorType: Option "None","Division by Zero","Period Error",Both;
    begin
        AccSchedManagement.CalcFieldError(ErrorType, RowLineNo, ColumnLineNo);
        if ErrorType > ErrorType::None then
            ColumnStyle := 'Unfavorable'
        else
            if Rec.Bold then
                ColumnStyle := 'Strong'
            else
                ColumnStyle := 'Standard';

        OnGetStyleOnBeforeAssignColumnStyle(Rec, ColumnNo, RowLineNo, ColumnLineNo, ColumnStyle, ColumnValues);

        case ColumnNo of
            1:
                ColumnStyle1 := ColumnStyle;
            2:
                ColumnStyle2 := ColumnStyle;
            3:
                ColumnStyle3 := ColumnStyle;
            4:
                ColumnStyle4 := ColumnStyle;
            5:
                ColumnStyle5 := ColumnStyle;
            6:
                ColumnStyle6 := ColumnStyle;
            7:
                ColumnStyle7 := ColumnStyle;
            8:
                ColumnStyle8 := ColumnStyle;
            9:
                ColumnStyle9 := ColumnStyle;
            10:
                ColumnStyle10 := ColumnStyle;
            11:
                ColumnStyle11 := ColumnStyle;
            12:
                ColumnStyle12 := ColumnStyle;
            13:
                ColumnStyle13 := ColumnStyle;
            14:
                ColumnStyle14 := ColumnStyle;
            15:
                ColumnStyle15 := ColumnStyle;
        end;
    end;

    local procedure LogUsageTelemetry()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('ReportDefinitionCode', TempFinancialReport.Name);
        TelemetryDimensions.Add('RowDefinitionCode', TempFinancialReport."Financial Report Row Group");
        TelemetryDimensions.Add('ColumnDefinitionCode', TempFinancialReport."Financial Report Column Group");
        TelemetryDimensions.Add('DateFilter', DateFilter);
        TelemetryDimensions.Add('GLBudgetFilter', TempFinancialReport.GLBudgetFilter);
        TelemetryDimensions.Add('CostBudgetFilter', TempFinancialReport.CostBudgetFilter);
        TelemetryDimensions.Add('Dim1Filter', TempFinancialReport.Dim1Filter);
        TelemetryDimensions.Add('Dim2Filter', TempFinancialReport.Dim2Filter);
        TelemetryDimensions.Add('Dim3Filter', TempFinancialReport.Dim3Filter);
        TelemetryDimensions.Add('Dim4Filter', TempFinancialReport.Dim4Filter);

        FeatureTelemetry.LogUsage('0000OKU', 'Financial Report', StrSubstNo(PageRunEventTxt, TempFinancialReport.Name), TelemetryDimensions);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDimFilters(var AccScheduleLine: Record "Acc. Schedule Line"; var DimNo: Integer; var DimValueFilter: Text; var CostCenterFilter: Text; var CostObjectFilter: Text; var CurrentCostBudgetFilter: Text; var CurrentGLBudgetFilter: Text; var CurrentCashFlowFilter: Text; AnalysisView: Record "Analysis View"; var TempFinancialReport: Record "Financial Report" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCostCenterFilter(var AccScheduleLine: Record "Acc. Schedule Line"; var CostCenterFilter: Text; var Dim1Filter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCostObjectFilter(var AccScheduleLine: Record "Acc. Schedule Line"; var CostObjectFilter: Text; var Dim2Filter: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateDimFilterControls(var Dim4FilterEnable: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterDrillDown(ColumnNo: Integer; var TempColumnLayout: Record "Column Layout" temporary; var PeriodType: Option)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var AccScheduleLine: Record "Acc. Schedule Line"; var CurrentColumnName: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnOnAfterGetRecordOnAfterAssignColumnValue(var ColumnValues: array[15] of Decimal; var ColumnNo: Integer; var ColumnOffset: Integer; var TempColumnLayout: Record "Column Layout" temporary; var UseAmtsInAddCurr: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrint(var AccScheduleLine: Record "Acc. Schedule Line"; ColumnLayoutName: Code[10]; var IsHandled: Boolean; var TempFinancialReport: Record "Financial Report" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCurrentColumnNameOnAfterValidate(var CurrentColumnName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCaptionClass(AnalysisView: Record "Analysis View"; DimNo: Integer; var Result: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
#if not CLEAN27
    [Obsolete('The ColumnCaptions parameter will be changed to array[15] of Text in a future release.', '27.0')]
    local procedure OnBeforeUpdateColumnCaptions(var ColumnCaptions: array[15] of Text[80]; ColumnOffset: Integer; var TempColumnLayout: Record "Column Layout" temporary; NoOfColumns: Integer; var IsHandled: Boolean)
#else
    local procedure OnBeforeUpdateColumnCaptions(var ColumnCaptions: array[15] of Text; ColumnOffset: Integer; var TempColumnLayout: Record "Column Layout" temporary; NoOfColumns: Integer; var IsHandled: Boolean)
#endif
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDimFilterControls(var AccScheduleLine: Record "Acc. Schedule Line"; AnalysisView: Record "Analysis View"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetStyleOnBeforeAssignColumnStyle(AccScheduleLine: Record "Acc. Schedule Line"; ColumnNo: Integer; RowLineNo: Integer; ColumnLineNo: Integer; var ColumnStyle: Text; ColumnValues: array[15] of Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFormatStr(ColumnLayoutArr: array[15] of Record "Column Layout"; UseAmtsInAddCurr: Boolean; ColumnNo: Integer; NegativeAmountFormatting: Enum "Analysis Negative Format"; var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadPageStateOnBeforeCopyColumnsToTemp(CurrentColumnName: Code[10]; var TempColumnLayout: Record "Column Layout" temporary; var CurrentSchedName: Code[10]; var AccScheduleLine: Record "Acc. Schedule Line"; var IsHandled: Boolean)
    begin
    end;
}
