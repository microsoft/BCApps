#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Utilities;
using System.IO;
using System.Utilities;

/// <summary>
/// Generates standard trial balance report displaying account balances and period movements.
/// Shows opening balances, period debits/credits, and closing balances for comprehensive G/L account analysis.
/// </summary>
/// <remarks>
/// Data source: G/L Account table with balance calculations and period filtering capabilities.
/// Used for financial statement preparation, account reconciliation, and period-end procedures.
/// Supports filtering by account types, date ranges, and global dimensions for customized trial balance reporting.
/// </remarks>
report 10022 "Trial Balance"
{
    // This report is copied from 10011 GL - Fin Stm. Even though it does not and
    // cannot use the Percent To Total feature, nevertheless for maintainability and
    // ease of conversion, the 4 Percent To Total columns are still within the array,
    // even though the user can NEVER select them. These are columns 2, 4, 6 & 8.
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/TrialBalance.rdlc';
    AdditionalSearchTerms = 'year closing,close accounting period,close fiscal year';
    ApplicationArea = Basic, Suite;
    Caption = 'Trial Balance';
    UsageCategory = ReportsAndAnalysis;
    DataAccessIntent = ReadOnly;
    ObsoleteState = Pending;
    ObsoleteReason = 'This report has been replaced by the report Trial Balance (Excel). This report will be removed in a future release.';
    ObsoleteTag = '28.0';

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Budget Filter";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(Time; Time)
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(PrintToExcel; PrintToExcel)
            {
            }
            column(PageHeaderCondition; ((not PrintToExcel) and ((LineType = LineType::"9-Point") or (LineType = LineType::"9-Point Rounded"))))
            {
            }
            column(UseAddRptCurr; UseAddRptCurr)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(GLAccountFilter; GLAccountFilter)
            {
            }
            column(NoofBlankLines_GLAccount; "G/L Account"."No. of Blank Lines")
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(TblCaptionGLAccountFilter; "G/L Account".TableCaption + ': ' + GLAccountFilter)
            {
            }
            column(ColumnHead1; ColumnHead[1])
            {
            }
            column(ColumnHead2; ColumnHead[2])
            {
            }
            column(ConditionGLAccountHeader6; ((LineType = LineType::"9-Point") and not PrintToExcel))
            {
            }
            column(ColumnHead3; ColumnHead[3])
            {
            }
            column(ConditionGLAccountHeader7; ((LineType = LineType::"9-Point Rounded") and not PrintToExcel))
            {
            }
            column(ColumnHead4; ColumnHead[4])
            {
            }
            column(ConditionGLAccountHeader8; ((LineType = LineType::"8-Point") and not PrintToExcel))
            {
            }
            column(ConditionGLAccountHeader9; ((LineType = LineType::"8-Point Rounded") and not PrintToExcel))
            {
            }
            column(ColumnHead5; ColumnHead[5])
            {
            }
            column(ColumnHead6; ColumnHead[6])
            {
            }
            column(ConditionGLAccountHeader10; ((LineType = LineType::"7-Point") and not PrintToExcel))
            {
            }
            column(ColumnHead7; ColumnHead[7])
            {
            }
            column(ColumnHead8; ColumnHead[8])
            {
            }
            column(ConditionGLAccountHeader11; ((LineType = LineType::"7-Point Rounded") and not PrintToExcel))
            {
            }
            column(No_GLAccount; "No.")
            {
            }
            column(TrialBalanceCaption; TrialBalanceCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(NoCaption_GLAccount; FieldCaption("No."))
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(DescriptionLine1; DescriptionLine1)
                {
                }
                column(IntegerBody1Condition; (((LineType = LineType::"9-Point") or (LineType = LineType::"9-Point Rounded")) and (DescriptionLine1 <> '') and not PrintToExcel and NumbersToPrint()))
                {
                }
                column(DescriptionLine2; DescriptionLine2)
                {
                }
                column(GLAccountNo; "G/L Account"."No.")
                {
                }
                column(IntegerBody2Condition; (((LineType = LineType::"9-Point") or (LineType = LineType::"9-Point Rounded")) and ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and ("G/L Account".Totaling = '') and not PrintToExcel))
                {
                }
                column(IntegerBody3Condition; (((LineType = LineType::"8-Point") or (LineType = LineType::"8-Point Rounded")) and (DescriptionLine1 <> '') and not PrintToExcel))
                {
                }
                column(IntegerBody4Condition; (((LineType = LineType::"8-Point") or (LineType = LineType::"8-Point Rounded")) and ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and ("G/L Account".Totaling = '') and not PrintToExcel))
                {
                }
                column(IntegerBody5Condition; (((LineType = LineType::"7-Point") or (LineType = LineType::"7-Point Rounded")) and (DescriptionLine1 <> '') and not PrintToExcel))
                {
                }
                column(IntegerBody6Condition; (((LineType = LineType::"7-Point") or (LineType = LineType::"7-Point Rounded")) and ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and ("G/L Account".Totaling = '') and not PrintToExcel))
                {
                }
                column(PrintAmt1; PrintAmount[1])
                {
                }
                column(PrintAmt2; PrintAmount[2])
                {
                }
                column(IntegerBody7Condition; ((LineType = LineType::"9-Point") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(PrintAmt3; PrintAmount[3])
                {
                }
                column(IntegerBody8Condition; ((LineType = LineType::"9-Point Rounded") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(PrintAmt4; PrintAmount[4])
                {
                }
                column(IntegerBody9Condition; ((LineType = LineType::"8-Point") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(IntegerBody10Condition; ((LineType = LineType::"8-Point Rounded") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(PrintAmt5; PrintAmount[5])
                {
                }
                column(PrintAmt6; PrintAmount[6])
                {
                }
                column(IntegerBody11Condition; ((LineType = LineType::"7-Point") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(PrintAmt7; PrintAmount[7])
                {
                }
                column(PrintAmt8; PrintAmount[8])
                {
                }
                column(IntegerBody12Condition; ((LineType = LineType::"7-Point Rounded") and NumbersToPrint() and not PrintToExcel))
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if PrintToExcel then
                        MakeExcelDataBody();
                end;

                trigger OnPostDataItem()
                begin
                    if "G/L Account"."New Page" and not PrintToExcel then
                        PageGroupNo := PageGroupNo + 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(DescriptionLine2);
                Clear(DescriptionLine1);
                Clear(WorkAmount);
                if ("Account Type" = "Account Type"::Posting) or
                   (Totaling <> '')
                then begin
                    SetRange("Date Filter", FromDate, ToDate);
                    if UseAddRptCurr then begin
                        CalcFields("Additional-Currency Net Change", "Add.-Currency Balance at Date");
                        WorkAmount[1] := "Additional-Currency Net Change";
                        WorkAmount[7] := "Add.-Currency Balance at Date";
                    end else begin
                        CalcFields("Net Change", "Balance at Date");
                        WorkAmount[1] := "Net Change";
                        WorkAmount[7] := "Balance at Date";
                    end;
                    if Show = Show::Budget then begin
                        CalcFields("Budgeted Amount", "Budget at Date");
                        WorkAmount[3] := "Budgeted Amount";
                        WorkAmount[9] := "Budget at Date";
                    end else begin
                        SetRange("Date Filter", PriorFromDate, PriorToDate);
                        if UseAddRptCurr then begin
                            CalcFields("Additional-Currency Net Change", "Add.-Currency Balance at Date");
                            WorkAmount[3] := "Additional-Currency Net Change";
                            WorkAmount[9] := "Add.-Currency Balance at Date";
                        end else begin
                            CalcFields("Net Change", "Balance at Date");
                            WorkAmount[3] := "Net Change";
                            WorkAmount[9] := "Balance at Date";
                        end;
                    end;
                    if ColumnFlags[5] or ColumnFlags[6] then
                        WorkAmount[5] := WorkAmount[1] - WorkAmount[3];
                    if ColumnFlags[6] and (WorkAmount[3] <> 0.0) then
                        WorkAmount[6] := WorkAmount[5] / WorkAmount[3] * 100.0;
                    if ColumnFlags[11] or ColumnFlags[12] then
                        WorkAmount[11] := WorkAmount[7] - WorkAmount[9];
                    if ColumnFlags[12] and (WorkAmount[9] <> 0.0) then
                        WorkAmount[12] := WorkAmount[11] / WorkAmount[9] * 100.0;
                end;
                /* Handle the description */
                DescriptionLine2 := PadStr('', Indentation) + Name;
                ParagraphHandling.SplitPrintLine(DescriptionLine2, DescriptionLine1, MaxDescWidth, PointSize);
                /* Format the numbers (if any) */
                if NumbersToPrint() then begin
                    /* format the individual numbers, first numerically */
                    for i := 1 to 12 do
                        if RoundTo = RoundTo::Dollars then
                            WorkAmount[i] := Round(WorkAmount[i], 1)
                        else
                            if RoundTo = RoundTo::Thousands then begin
                                if i mod 2 = 0 then  // percents
                                    WorkAmount[i] := Round(WorkAmount[i], 1)
                                else                 // amounts
                                    WorkAmount[i] := Round(WorkAmount[i] / 1000, 1);
                            end else                                     // to nearest penny
                                WorkAmount[i] := Round(WorkAmount[i], 0.01);
                    /* now format the strings */
                    for i := 1 to 12 do begin
                        PrintAmount[i] := Format(WorkAmount[i]);
                        if RoundTo = RoundTo::Pennies then begin   // add decimal places if necessary
                            j := StrPos(PrintAmount[i], '.');
                            if j = 0 then
                                PrintAmount[i] := PrintAmount[i] + '.00'
                            else
                                if j = StrLen(PrintAmount[i]) - 1 then
                                    PrintAmount[i] := PrintAmount[i] + '0';
                        end;
                        if i mod 2 = 0 then    // percents
                            PrintAmount[i] := PrintAmount[i] + '%';
                    end;
                    /* final trick, compress the columns so only those the user wants are seen */
                    CompressColumns(PrintAmount);
                end;

            end;

            trigger OnPreDataItem()
            begin
                if IsEmpty() then
                    Error(MissingGLAccountErr);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'About Trial Balance (Obsolete)';
        AboutText = 'View a snapshot of your chart of accounts with a balance at date and net change in the specified period.** This report is obsolete and will be removed in a future release.** Please refer to the report documentation for alternative ways to retrieve this information.';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ShowComaprison; Show)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Comparison';
                        OptionCaption = 'Last Year,Budget';
                        ToolTip = 'Specifies if figures either from the prior year or for the defined budget are included.';
                    }
                    group("Select Report Columns")
                    {
                        Caption = 'Select Report Columns';
                        field(ActualChange; ColumnFlags[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Actual Changes';
                            ToolTip = 'Specifies that a column is added that shows the actual net change.';

                            trigger OnValidate()
                            begin
                                TestNumColumns();
                            end;
                        }
                        field(ComparisonChanges; ColumnFlags[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Comparison Changes';
                            ToolTip = 'Specifies if you want to include the net changes from the selected period.';

                            trigger OnValidate()
                            begin
                                TestNumColumns();
                            end;
                        }
                        field("ColumnFlags[5]"; ColumnFlags[5])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Variance in Changes';
                            ToolTip = 'Specifies if you want to include a column that shows the change variance. The variance is calculated by subtracting the budget or prior year amounts over the period defined from the actual amounts.';

                            trigger OnValidate()
                            begin
                                TestNumColumns();
                            end;
                        }
                        field("ColumnFlags[6]"; ColumnFlags[6])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '% Variance in Changes';
                            ToolTip = 'Specifies that a column is inserted that shows the percentage of variance in balances. The variance is calculated by dividing the variance by the actual amounts.';

                            trigger OnValidate()
                            begin
                                TestNumColumns();
                            end;
                        }
                        field(ActualBalances; ColumnFlags[7])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Actual Balances';
                            ToolTip = 'Specifies that a column is added that shows the actual balance.';

                            trigger OnValidate()
                            begin
                                TestNumColumns();
                            end;
                        }
                        field(ComparisonBalances; ColumnFlags[9])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Comparison Balances';
                            ToolTip = 'Specifies if you want to include the balance from the selected period.';

                            trigger OnValidate()
                            begin
                                TestNumColumns();
                            end;
                        }
                        field("ColumnFlags[11]"; ColumnFlags[11])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Variance in Balances';
                            ToolTip = 'Specifies if you want to include a column that shows the balance variance. The variance is calculated by subtracting the budget or prior year amounts over the period defined from the actual amounts.';

                            trigger OnValidate()
                            begin
                                TestNumColumns();
                            end;
                        }
                        field("ColumnFlags[12]"; ColumnFlags[12])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = '% Variance in Balances';
                            ToolTip = 'Specifies that a column is inserted that shows the percentage of variance in balances. The variance is calculated by dividing the variance by the actual amounts.';

                            trigger OnValidate()
                            begin
                                TestNumColumns();
                            end;
                        }
                    }
                    field(RoundTo; RoundTo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Round to';
                        OptionCaption = 'Pennies,Dollars,Thousands';
                        ToolTip = 'Specifies if you want the results in the report to be rounded to the nearest penny (hundredth of a unit), dollar (unit), or thousand dollars (units). The results are in US dollars, unless you use an additional reporting currency.';

                        trigger OnValidate()
                        begin
                            if RoundTo = RoundTo::Thousands then
                                ThousandsRoundToOnValidate();
                            if RoundTo = RoundTo::Dollars then
                                DollarsRoundToOnValidate();
                            if RoundTo = RoundTo::Pennies then
                                PenniesRoundToOnValidate();
                        end;
                    }
                    field(SkipZeros; SkipZeros)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Skip Accounts with all zero Amounts';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the report to be generated with all of the accounts, including those with zero amounts. Otherwise, those accounts will be excluded.';
                    }
                    field(UseAdditionalReportingCurrency; UseAddRptCurr)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Use Additional Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want all amounts to be printed by using the additional reporting currency. If you do not select the check box, then all amounts will be printed in US dollars.';
                    }
                    field(PrintToExcel; PrintToExcel)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print to Excel';
                        ToolTip = 'Specifies if you want to export the data to an Excel spreadsheet for additional analysis or formatting before printing.';

                        trigger OnValidate()
                        begin
                            TestNumColumns();
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if PrintToExcel then
            CreateExcelbook();
    end;

    trigger OnPreReport()
    begin
        "G/L Account".SecurityFiltering(SecurityFilter::Filtered);
        CompanyInformation.Get();
        /* Set up format-dependent variables */
        case NumColumns() of
            0:
                Error(Text000);
            1, 2:
                if RoundTo = RoundTo::Pennies then
                    LineType := LineType::"9-Point"
                else
                    LineType := LineType::"9-Point Rounded";
            3:
                if RoundTo = RoundTo::Pennies then
                    LineType := LineType::"8-Point"
                else
                    LineType := LineType::"9-Point Rounded";
            4:
                if RoundTo = RoundTo::Pennies then
                    LineType := LineType::"8-Point"
                else
                    LineType := LineType::"8-Point Rounded";
            5, 6:
                if RoundTo = RoundTo::Pennies then
                    LineType := LineType::"7-Point"
                else
                    LineType := LineType::"7-Point Rounded";
            7, 8:
                if (RoundTo = RoundTo::Pennies) and not PrintToExcel then
                    Error(Text001)
                else
                    LineType := LineType::"7-Point Rounded";
            else
                Error(Text002);
        end;
        if RoundTo = RoundTo::Pennies then
            ExcelAmtFormat := '#,##0.00'
        else
            ExcelAmtFormat := '#,##0';

        case LineType of
            LineType::"9-Point", LineType::"9-Point Rounded":
                begin
                    MaxDescWidth := 67;
                    PointSize := 9;
                end;
            LineType::"8-Point", LineType::"8-Point Rounded":
                begin
                    MaxDescWidth := 52;
                    PointSize := 8;
                end;
            LineType::"7-Point", LineType::"7-Point Rounded":
                begin
                    MaxDescWidth := 33;
                    PointSize := 7;
                end;
            else
                Error(Text003);
        end;
        /* set up the date ranges */
        FromDate := "G/L Account".GetRangeMin("Date Filter");
        ToDate := "G/L Account".GetRangeMax("Date Filter");
        PriorFromDate := CalcDate('<-1Y>', NormalDate(FromDate) + 1) - 1;
        PriorToDate := CalcDate('<-1Y>', NormalDate(ToDate) + 1) - 1;
        if FromDate <> NormalDate(FromDate) then
            PriorFromDate := ClosingDate(PriorFromDate);
        if ToDate <> NormalDate(ToDate) then
            PriorToDate := ClosingDate(PriorToDate);
        "G/L Account".SetRange("Date Filter");       // since it is in the title, it does
        GLAccountFilter := "G/L Account".GetFilters(); // not have to be in the filter string
        /* set up header texts
           Note: Since these texts are built up piece by piece, it would do no good to
                 attempt to translate the individual pieces. Therefore, these texts have
                 not been placed into text constants.
        */
        Clear(PeriodText);
        Clear(ColumnHead);
        /* Period Headings */
        if ColumnFlags[7] then begin                              // YTD
            PeriodText := 'As of ' + Format(ToDate, 0, 4);
            if ColumnFlags[9] then
                if Show = Show::Budget then                           // Budget
                    PeriodText := 'Actual vs Budget a' + DelStr(PeriodText, 1, 1)
                else                                                  // Prior YTD
                    PeriodText := PeriodText + ' and ' + Format(Date2DMY(PriorToDate, 3));
        end else
            if ColumnFlags[9] then begin
                if Show = Show::Budget then                             // Budget
                    PeriodText := 'Budget as of ' + Format(ToDate, 0, 4)
                else                                                    // Prior YTD
                    PeriodText := 'As of ' + Format(PriorToDate, 0, 4);
            end else
                if ColumnFlags[1] then begin                     // PTD
                    PeriodText := 'Changes ';
                    if ColumnFlags[3] and (Show = Show::Budget) then        // Budget
                        PeriodText := PeriodText + 'and Budgeted Changes ';
                    PeriodText := PeriodText + 'from '
                      + Format(FromDate, 0, 4)
                      + ' to '
                      + Format(ToDate, 0, 4);
                    if ColumnFlags[3] and (Show = Show::"Last Year") then   // Prior PTD
                        PeriodText := PeriodText + ' and from '
                          + Format(PriorFromDate, 0, 4)
                          + ' to '
                          + Format(PriorToDate, 0, 4);
                end else
                    if ColumnFlags[3] then begin                     // PTD
                        if Show = Show::Budget then                           // Budget
                            PeriodText := 'Budgeted '
                        else                                                    // Prior PTD
                            PeriodText := '';
                        PeriodText := PeriodText + 'Changes from ';
                        if Show = Show::Budget then                           // Budget
                            PeriodText := PeriodText + Format(FromDate, 0, 4)
                              + ' to '
                              + Format(ToDate, 0, 4)
                        else                                                    // Prior PTD
                            PeriodText := PeriodText + Format(PriorFromDate, 0, 4)
                              + ' to '
                              + Format(PriorToDate, 0, 4);
                    end;
        if UseAddRptCurr then begin
            GLSetup.Get();
            Currency.Get(GLSetup."Additional Reporting Currency");
            SubTitle := StrSubstNo(Text004, Currency.Description);
        end;

        /* Column Headings */
        if Show = Show::Budget then
            ColumnHead[3] := Text005
        else
            ColumnHead[3] := Text006;
        ColumnHead[9] := ColumnHead[3];
        ColumnHead[5] := Text007;
        ColumnHead[6] := Text008;
        ColumnHead[11] := Text009;
        ColumnHead[12] := Text010;
        ColumnHead[1] := Text011;
        ColumnHead[7] := Text012;
        ColumnHead[3] := ColumnHead[3] + Text011;
        ColumnHead[9] := ColumnHead[9] + Text012;
        if RoundTo = RoundTo::Thousands then
            for i := 1 to 12 do
                if i mod 2 = 1 then
                    ColumnHead[i] := ColumnHead[i] + Text013;
        CompressColumns(ColumnHead);
        if PrintToExcel then
            MakeExcelInfo();

    end;

    var
        CompanyInformation: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        ExcelBuf: Record "Excel Buffer" temporary;
        ParagraphHandling: Codeunit "Paragraph Handling";
        PeriodText: Text[120];
        SubTitle: Text[132];
        SkipZeros: Boolean;
        UseAddRptCurr: Boolean;
        PrintToExcel: Boolean;
        Show: Option "Last Year",Budget;
        RoundTo: Option Pennies,Dollars,Thousands;
        LineType: Option "9-Point","9-Point Rounded","8-Point","8-Point Rounded","7-Point","7-Point Rounded";
        ColumnFlags: array[12] of Boolean;
        ColumnHead: array[12] of Text[50];
        PrintAmount: array[12] of Text[30];
        WorkAmount: array[12] of Decimal;
        FromDate: Date;
        ToDate: Date;
        PriorFromDate: Date;
        PriorToDate: Date;
        DescriptionLine2: Text[100];
        DescriptionLine1: Text[80];
        MaxDescWidth: Integer;
        PointSize: Integer;
        j: Integer;
        i: Integer;
#pragma warning disable AA0074
        Text000: Label 'You must select at least one Report Column.';
        Text001: Label 'If you want more than 6 Report Columns you must round to Dollars or Thousands.';
        Text002: Label 'You may select a maximum of 8 Report Columns.';
        Text003: Label 'Program Bug.';
        Text004: Label 'Amounts are in %1';
        Text005: Label 'Budgeted, ';
        Text006: Label 'Last Year, ';
        Text007: Label 'Change Variance';
        Text008: Label 'Change % Variance';
        Text009: Label 'Balance Variance';
        Text010: Label 'Balance % Variance';
        Text011: Label 'Net Change';
        Text012: Label 'Balance';
        Text013: Label ' (Thousands)';
        Text101: Label 'Data';
        Text102: Label 'Trial Balance';
        Text103: Label 'Company Name';
        Text104: Label 'Report No.';
        Text105: Label 'Report Name';
        Text106: Label 'User ID';
        Text107: Label 'Date / Time';
        Text108: Label 'G/L Account Filters';
        Text109: Label 'Sub-Title';
        Text110: Label 'Amounts are in';
        Text111: Label 'our Functional Currency';
#pragma warning restore AA0074
        ExcelAmtFormat: Text[30];
        PageGroupNo: Integer;
        TrialBalanceCaptionLbl: Label 'Trial Balance';
        PageCaptionLbl: Label 'Page';
        NameCaptionLbl: Label 'Name';
        MissingGLAccountErr: Label 'No G/L account exists within the specified filter.';

    protected var
        GLAccountFilter: Text;

    procedure NumColumns() NumCol: Integer
    var
        i: Integer;
    begin
        /* Counts the Number of Columns that the user selected */
        NumCol := 0;
        for i := 1 to ArrayLen(ColumnFlags) do
            if ColumnFlags[i] then
                NumCol := NumCol + 1;
        exit(NumCol);

    end;

    procedure TestNumColumns()
    begin
        if NumColumns() > 8 then
            Error(Text002);
        if (NumColumns() > 6) and (RoundTo = RoundTo::Pennies) and not PrintToExcel then
            Error(Text001);
    end;

    procedure NumbersToPrint(): Boolean
    var
        i: Integer;
    begin
        /* Returns whether any numbers are available to be printed this time */
        if ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and
           ("G/L Account".Totaling = '')
        then
            exit(false);
        if ("G/L Account"."Account Type" = "G/L Account"."Account Type"::Posting) and SkipZeros then begin
            for i := 1 to ArrayLen(ColumnFlags) do
                if (WorkAmount[i] <> 0.0) and ColumnFlags[i] then
                    exit(true);
            exit(false);
        end;
        exit(true);

    end;

    procedure CompressColumns(var StringArray: array[12] of Text[30])
    var
        i: Integer;
        j: Integer;
    begin
        /* Moves all active columns together */
        j := 0;
        for i := 1 to ArrayLen(ColumnFlags) do
            if ColumnFlags[i] then begin
                j := j + 1;
                StringArray[j] := StringArray[i];
            end;
        for i := j + 1 to ArrayLen(ColumnFlags) do
            StringArray[i] := '';

    end;

    local procedure MakeExcelInfo()
    begin
        ExcelBuf.SetUseInfoSheet();
        ExcelBuf.AddInfoColumn(Format(Text103), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(CompanyInformation.Name, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text105), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Format(Text102), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text104), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(REPORT::"Trial Balance", false, false, false, false, '', ExcelBuf."Cell Type"::Number);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text106), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(UserId, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text107), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Today, false, false, false, false, '', ExcelBuf."Cell Type"::Date);
        ExcelBuf.AddInfoColumn(Time, false, false, false, false, '', ExcelBuf."Cell Type"::Time);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text108), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(GLAccountFilter, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text109), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(PeriodText, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text110), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        if UseAddRptCurr then
            ExcelBuf.AddInfoColumn(Currency.Description, false, false, false, false, '', ExcelBuf."Cell Type"::Text)
        else
            ExcelBuf.AddInfoColumn(Format(Text111), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.ClearNewRow();
        MakeExcelDataHeader();
    end;

    local procedure MakeExcelDataHeader()
    var
        i: Integer;
    begin
        ExcelBuf.NewRow();
        ExcelBuf.AddColumn("G/L Account".FieldCaption("No."), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddColumn("G/L Account".FieldCaption(Name), false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
        for i := 1 to NumColumns() do
            ExcelBuf.AddColumn(ColumnHead[i], false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
    end;

    local procedure MakeExcelDataBody()
    var
        Percentage: Decimal;
    begin
        if NumbersToPrint() or
           (("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and
            ("G/L Account".Totaling = ''))
        then begin
            ExcelBuf.NewRow();
            if ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and
               ("G/L Account".Totaling = '')
            then begin
                ExcelBuf.AddColumn("G/L Account"."No.", false, '', true, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(
                  PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name, false, '', true, false, false, '', ExcelBuf."Cell Type"::Text);
            end else begin
                ExcelBuf.AddColumn("G/L Account"."No.", false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
                ExcelBuf.AddColumn(
                  PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name, false, '', false, false, false, '', ExcelBuf."Cell Type"::Text);
            end;
            if NumbersToPrint() then
                for i := 1 to NumColumns() do
                    if StrPos(PrintAmount[i], '%') <> 0 then begin
                        // fix for exporting % values
                        Evaluate(Percentage, DelChr(PrintAmount[i], '=', '%'));
                        Percentage := Percentage / 100;
                        ExcelBuf.AddColumn(Percentage, false, '', false, false, false, ExcelAmtFormat + '%', ExcelBuf."Cell Type"::Number)
                    end else
                        ExcelBuf.AddColumn(PrintAmount[i], false, '', false, false, false, ExcelAmtFormat, ExcelBuf."Cell Type"::Number);
        end;
    end;

    local procedure CreateExcelbook()
    begin
        ExcelBuf.CreateBookAndOpenExcel('', Text101, Text102, CompanyName, UserId);
        Error('');
    end;

    local procedure PenniesRoundToOnValidate()
    begin
        TestNumColumns();
    end;

    local procedure DollarsRoundToOnValidate()
    begin
        TestNumColumns();
    end;

    local procedure ThousandsRoundToOnValidate()
    begin
        TestNumColumns();
    end;
}

#endif