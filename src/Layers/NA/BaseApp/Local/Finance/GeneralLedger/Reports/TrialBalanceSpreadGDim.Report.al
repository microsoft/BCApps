// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Utilities;
using System.IO;
using System.Utilities;

report 10025 "Trial Balance, Spread G. Dim."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/TrialBalanceSpreadGDim.rdlc';
    ApplicationArea = Suite;
    Caption = 'Trial Balance, Spread Global Dimension';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Account Type", "Date Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Budget Filter";
            column(Dimension_Name_________Text011; Dimension.Name + ' ' + Text011)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(PrintToExcel; PrintToExcel)
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
            column(G_L_Account__G_L_Account___No__of_Blank_Lines_; "G/L Account"."No. of Blank Lines")
            {
            }
            column(PageHeaderCondition; ((not PrintToExcel) and ((LineType = LineType::"9-Point") or (LineType = LineType::"9-Point Rounded"))))
            {
            }
            column(Dimension_Name_________Text011_Control1011; Dimension.Name + ' ' + Text011)
            {
            }
            column(FORMAT_TODAY_0_4__Control1012; Format(Today, 0, 4))
            {
            }
            column(TIME_Control1013; Time)
            {
            }
            column(CompanyInformation_Name_Control1014; CompanyInformation.Name)
            {
            }
            column(USERID_Control1017; UserId)
            {
            }
            column(PeriodText_Control1018; PeriodText)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(G_L_Account__TABLECAPTION__________GLAccountFilter; "G/L Account".TableCaption + ': ' + GLAccountFilter)
            {
            }
            column(ColumnHead_1_; ColumnHead[1])
            {
            }
            column(ColumnHead_2_; ColumnHead[2])
            {
            }
            column(Condition_GLAccount_Header_6; ((LineType = LineType::"9-Point") and not PrintToExcel))
            {
            }
            column(ColumnHead_1__Control41; ColumnHead[1])
            {
            }
            column(ColumnHead_2__Control42; ColumnHead[2])
            {
            }
            column(ColumnHead_3_; ColumnHead[3])
            {
            }
            column(Condition_GLAccount_Header_7; ((LineType = LineType::"9-Point Rounded") and not PrintToExcel))
            {
            }
            column(ColumnHead_1__Control85; ColumnHead[1])
            {
            }
            column(ColumnHead_2__Control86; ColumnHead[2])
            {
            }
            column(ColumnHead_3__Control87; ColumnHead[3])
            {
            }
            column(ColumnHead_4_; ColumnHead[4])
            {
            }
            column(Condition_GLAccount_Header_8; ((LineType = LineType::"8-Point") and not PrintToExcel))
            {
            }
            column(ColumnHead_1__Control89; ColumnHead[1])
            {
            }
            column(ColumnHead_2__Control90; ColumnHead[2])
            {
            }
            column(ColumnHead_3__Control91; ColumnHead[3])
            {
            }
            column(ColumnHead_4__Control92; ColumnHead[4])
            {
            }
            column(Condition_GLAccount_Header_9; ((LineType = LineType::"8-Point Rounded") and not PrintToExcel))
            {
            }
            column(ColumnHead_1__Control192; ColumnHead[1])
            {
            }
            column(ColumnHead_2__Control193; ColumnHead[2])
            {
            }
            column(ColumnHead_3__Control194; ColumnHead[3])
            {
            }
            column(ColumnHead_4__Control195; ColumnHead[4])
            {
            }
            column(ColumnHead_5_; ColumnHead[5])
            {
            }
            column(ColumnHead_6_; ColumnHead[6])
            {
            }
            column(Condition_GLAccount_Header_10; ((LineType = LineType::"7-Point") and not PrintToExcel))
            {
            }
            column(ColumnHead_1__Control198; ColumnHead[1])
            {
            }
            column(ColumnHead_2__Control199; ColumnHead[2])
            {
            }
            column(ColumnHead_3__Control200; ColumnHead[3])
            {
            }
            column(ColumnHead_4__Control201; ColumnHead[4])
            {
            }
            column(ColumnHead_5__Control202; ColumnHead[5])
            {
            }
            column(ColumnHead_6__Control203; ColumnHead[6])
            {
            }
            column(ColumnHead_7_; ColumnHead[7])
            {
            }
            column(ColumnHead_8_; ColumnHead[8])
            {
            }
            column(Condition_GLAccount_Header_11; ((LineType = LineType::"7-Point Rounded") and not PrintToExcel))
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Account___No___Control18Caption; FieldCaption("No."))
            {
            }
            column(DescriptionLine2_Control10Caption; DescriptionLine2_Control10CaptionLbl)
            {
            }
            column(G_L_Account___No___Control18Caption_Control39; FieldCaption("No."))
            {
            }
            column(DescriptionLine2_Control10Caption_Control40; DescriptionLine2_Control10Caption_Control40Lbl)
            {
            }
            column(G_L_Account___No___Control16Caption; FieldCaption("No."))
            {
            }
            column(DescriptionLine2_Control51Caption; DescriptionLine2_Control51CaptionLbl)
            {
            }
            column(G_L_Account___No___Control16Caption_Control33; FieldCaption("No."))
            {
            }
            column(DescriptionLine2_Control51Caption_Control34; DescriptionLine2_Control51Caption_Control34Lbl)
            {
            }
            column(G_L_Account___No___Control7Caption; FieldCaption("No."))
            {
            }
            column(DescriptionLine2_Control100Caption; DescriptionLine2_Control100CaptionLbl)
            {
            }
            column(G_L_Account___No___Control7Caption_Control29; FieldCaption("No."))
            {
            }
            column(DescriptionLine2_Control100Caption_Control30; DescriptionLine2_Control100Caption_Control30Lbl)
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
                column(Integer_Body_1_Condition; (((LineType = LineType::"9-Point") or (LineType = LineType::"9-Point Rounded")) and (DescriptionLine1 <> '') and not PrintToExcel))
                {
                }
                column(DescriptionLine2; DescriptionLine2)
                {
                }
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(Integer_Body_2_Condition; (((LineType = LineType::"9-Point") or (LineType = LineType::"9-Point Rounded")) and ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and ("G/L Account".Totaling = '') and not PrintToExcel))
                {
                }
                column(DescriptionLine1_Control61; DescriptionLine1)
                {
                }
                column(Integer_Body_3_Condition; (((LineType = LineType::"8-Point") or (LineType = LineType::"8-Point Rounded")) and (DescriptionLine1 <> '') and not PrintToExcel))
                {
                }
                column(DescriptionLine2_Control62; DescriptionLine2)
                {
                }
                column(G_L_Account___No___Control19; "G/L Account"."No.")
                {
                }
                column(Integer_Body_4_Condition; (((LineType = LineType::"8-Point") or (LineType = LineType::"8-Point Rounded")) and ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and ("G/L Account".Totaling = '') and not PrintToExcel))
                {
                }
                column(DescriptionLine1_Control116; DescriptionLine1)
                {
                }
                column(Integer_Body_5_Condition; (((LineType = LineType::"7-Point") or (LineType = LineType::"7-Point Rounded")) and (DescriptionLine1 <> '') and not PrintToExcel))
                {
                }
                column(DescriptionLine2_Control117; DescriptionLine2)
                {
                }
                column(G_L_Account___No___Control5; "G/L Account"."No.")
                {
                }
                column(Integer_Body_6_Condition; (((LineType = LineType::"7-Point") or (LineType = LineType::"7-Point Rounded")) and ("G/L Account"."Account Type" <> "G/L Account"."Account Type"::Posting) and ("G/L Account".Totaling = '') and not PrintToExcel))
                {
                }
                column(PrintAmount_1_; PrintAmount[1])
                {
                }
                column(PrintAmount_2_; PrintAmount[2])
                {
                }
                column(DescriptionLine2_Control10; DescriptionLine2)
                {
                }
                column(G_L_Account___No___Control18; "G/L Account"."No.")
                {
                }
                column(Integer_Body_7_Condition; ((LineType = LineType::"9-Point") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(DescriptionLine2_Control25; DescriptionLine2)
                {
                }
                column(PrintAmount_1__Control26; PrintAmount[1])
                {
                }
                column(PrintAmount_2__Control27; PrintAmount[2])
                {
                }
                column(PrintAmount_3_; PrintAmount[3])
                {
                }
                column(G_L_Account___No___Control17; "G/L Account"."No.")
                {
                }
                column(Integer_Body_8_Condition; ((LineType = LineType::"9-Point Rounded") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(DescriptionLine2_Control51; DescriptionLine2)
                {
                }
                column(PrintAmount_1__Control52; PrintAmount[1])
                {
                }
                column(PrintAmount_2__Control53; PrintAmount[2])
                {
                }
                column(PrintAmount_3__Control54; PrintAmount[3])
                {
                }
                column(PrintAmount_4_; PrintAmount[4])
                {
                }
                column(G_L_Account___No___Control16; "G/L Account"."No.")
                {
                }
                column(Integer_Body_9_Condition; ((LineType = LineType::"8-Point") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(DescriptionLine2_Control56; DescriptionLine2)
                {
                }
                column(PrintAmount_1__Control57; PrintAmount[1])
                {
                }
                column(PrintAmount_2__Control58; PrintAmount[2])
                {
                }
                column(PrintAmount_3__Control59; PrintAmount[3])
                {
                }
                column(PrintAmount_4__Control60; PrintAmount[4])
                {
                }
                column(G_L_Account___No___Control11; "G/L Account"."No.")
                {
                }
                column(Integer_Body_10_Condition; ((LineType = LineType::"8-Point Rounded") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(DescriptionLine2_Control100; DescriptionLine2)
                {
                }
                column(PrintAmount_1__Control101; PrintAmount[1])
                {
                }
                column(PrintAmount_2__Control102; PrintAmount[2])
                {
                }
                column(PrintAmount_3__Control103; PrintAmount[3])
                {
                }
                column(PrintAmount_4__Control104; PrintAmount[4])
                {
                }
                column(PrintAmount_5_; PrintAmount[5])
                {
                }
                column(PrintAmount_6_; PrintAmount[6])
                {
                }
                column(G_L_Account___No___Control7; "G/L Account"."No.")
                {
                }
                column(Integer_Body_11_Condition; ((LineType = LineType::"7-Point") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(DescriptionLine2_Control107; DescriptionLine2)
                {
                }
                column(PrintAmount_1__Control108; PrintAmount[1])
                {
                }
                column(PrintAmount_2__Control109; PrintAmount[2])
                {
                }
                column(PrintAmount_3__Control110; PrintAmount[3])
                {
                }
                column(PrintAmount_4__Control111; PrintAmount[4])
                {
                }
                column(PrintAmount_5__Control112; PrintAmount[5])
                {
                }
                column(PrintAmount_6__Control113; PrintAmount[6])
                {
                }
                column(PrintAmount_7_; PrintAmount[7])
                {
                }
                column(PrintAmount_8_; PrintAmount[8])
                {
                }
                column(G_L_Account___No___Control6; "G/L Account"."No.")
                {
                }
                column(Integer_Body_12_Condition; ((LineType = LineType::"7-Point Rounded") and NumbersToPrint() and not PrintToExcel))
                {
                }
                column(Integer_Number; Number)
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
                Clear(PrintAmount);
                if ("Account Type" = "Account Type"::Posting) or
                   (Totaling <> '')
                then begin
                    case AmountType of
                        AmountType::"Actual Change", AmountType::"Budget Change":
                            SetRange("Date Filter", FromDate, ToDate);
                        AmountType::"Actual Balance", AmountType::"Budget Balance":
                            SetRange("Date Filter", 0D, ToDate);
                        AmountType::"Last Year Change":
                            SetRange("Date Filter", PriorFromDate, PriorToDate);
                        AmountType::"Last Year Balance":
                            SetRange("Date Filter", 0D, PriorToDate);
                    end;
                    for i := 1 to MaxColumns() do
                        if (i = 1) or (ColumnFilter[i] <> '') then begin
                            if DimCode = GLSetup."Global Dimension 1 Code" then
                                SetFilter("Global Dimension 1 Filter", ColumnFilter[i])
                            else
                                SetFilter("Global Dimension 2 Filter", ColumnFilter[i]);
                            case AmountType of
                                AmountType::"Actual Change", AmountType::"Last Year Change":
                                    if UseAddRptCurr then begin
                                        CalcFields("Additional-Currency Net Change");
                                        WorkAmount[i] := "Additional-Currency Net Change";
                                    end else begin
                                        CalcFields("Net Change");
                                        WorkAmount[i] := "Net Change";
                                    end;
                                AmountType::"Actual Balance", AmountType::"Last Year Balance":
                                    if UseAddRptCurr then begin
                                        CalcFields("Add.-Currency Balance at Date");
                                        WorkAmount[i] := "Add.-Currency Balance at Date";
                                    end else begin
                                        CalcFields("Balance at Date");
                                        WorkAmount[i] := "Balance at Date";
                                    end;
                                AmountType::"Budget Change":
                                    begin
                                        CalcFields("Budgeted Amount");
                                        WorkAmount[i] := "Budgeted Amount";
                                    end;
                                AmountType::"Budget Balance":
                                    begin
                                        CalcFields("Budget at Date");
                                        WorkAmount[i] := "Budget at Date";
                                    end;
                            end;
                        end;
                end;
                /* Handle the description */
                DescriptionLine2 := PadStr('', Indentation) + Name;
                ParagraphHandling.SplitPrintLine(DescriptionLine2, DescriptionLine1, MaxDescWidth, PointSize);
                /* Format the numbers (if any) */
                if NumbersToPrint() then begin
                    /* format the individual numbers, first numerically */
                    for i := 1 to MaxColumns() do
                        case RoundTo of
                            RoundTo::Dollars:
                                WorkAmount[i] := Round(WorkAmount[i], 1);
                            RoundTo::Thousands:
                                WorkAmount[i] := Round(WorkAmount[i] / 1000, 1);
                            RoundTo::Pennies:
                                WorkAmount[i] := Round(WorkAmount[i], 0.01);
                        end;

                    /* now format the strings */
                    for i := 1 to MaxColumns() do
                        if WorkAmount[i] <> 0 then begin
                            PrintAmount[i] := Format(WorkAmount[i]);
                            if RoundTo = RoundTo::Pennies then begin   // add decimal places if necessary
                                j := StrPos(PrintAmount[i], '.');
                                if j = 0 then
                                    PrintAmount[i] := PrintAmount[i] + '.00'
                                else
                                    if j = StrLen(PrintAmount[i]) - 1 then
                                        PrintAmount[i] := PrintAmount[i] + '0';
                            end;
                        end;
                end;

            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DimCode; DimCode)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Select Global Dimension';
                        ToolTip = 'Specifies that the report includes global dimensions.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(0, Dimension) = ACTION::LookupOK then begin
                                Text := Dimension.Code;
                                exit(true);
                            end;
                            exit(false);
                        end;

                        trigger OnValidate()
                        begin
                            Dimension.Get(DimCode);
                            if (DimCode <> GLSetup."Global Dimension 1 Code") and
                               (DimCode <> GLSetup."Global Dimension 2 Code")
                            then
                                Error(Text013);
                        end;
                    }
                    field(SelectReportAmount; AmountType)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Select Report Amount';
                        OptionCaption = 'Actual Change,Budget Change,Last Year Change,Actual Balance,Budget Balance,Last Year Balance';
                        ToolTip = 'Specifies that the report includes amounts.';
                    }
                    field(RoundTo; RoundTo)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Round to';
                        OptionCaption = 'Pennies,Dollars,Thousands';
                        ToolTip = 'Specifies if you want the results in the report to be rounded to the nearest penny (hundredth of a unit), dollar (unit), or thousand dollars (units). The results are in US dollars, unless you use an additional reporting currency.';
                    }
                    field(SkipZeros; SkipZeros)
                    {
                        ApplicationArea = Suite;
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
                        ApplicationArea = Suite;
                        Caption = 'Print to Excel';
                        ToolTip = 'Specifies if you want to export the data to an Excel spreadsheet for additional analysis or formatting before printing.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GLSetup.Get();
            Dimension.Reset();
            if DimCode <> '' then
                if not Dimension.Get(DimCode) then;
            Dimension.FilterGroup(8);
            if (GLSetup."Global Dimension 1 Code" <> '') and
               (GLSetup."Global Dimension 2 Code" <> '')
            then
                Dimension.SetFilter(Code, '%1|%2', GLSetup."Global Dimension 1 Code", GLSetup."Global Dimension 2 Code")
            else
                if GLSetup."Global Dimension 1 Code" <> '' then
                    Dimension.SetRange(Code, GLSetup."Global Dimension 1 Code")
                else
                    if GLSetup."Global Dimension 2 Code" <> '' then
                        Dimension.SetRange(Code, GLSetup."Global Dimension 2 Code")
                    else
                        Error(Text012);
            Dimension.FilterGroup(0);
        end;
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
        CompanyInformation.Get();
        GLSetup.Get();
        /* Set up format-dependent variables */
        case NumColumns() of
            0, 1:
                Error(Text000, Dimension.Name);
            2:
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
                if PrintToExcel then
                    LineType := LineType::"7-Point"
                else
                    if RoundTo = RoundTo::Pennies then
                        Error(Text001, Dimension.Name)
                    else
                        LineType := LineType::"7-Point Rounded";
            9 .. ArrayLen(WorkAmount):
                if PrintToExcel then
                    LineType := LineType::"7-Point"
                else
                    if DimCode = GLSetup."Global Dimension 1 Code" then
                        Error(Text014, Dimension.Name, "G/L Account".FieldCaption("Global Dimension 1 Filter"))
                    else
                        Error(Text014, Dimension.Name, "G/L Account".FieldCaption("Global Dimension 2 Filter"));
            else
                if DimCode = GLSetup."Global Dimension 1 Code" then
                    Error(Text002, Dimension.Name, "G/L Account".FieldCaption("Global Dimension 1 Filter"))
                else
                    Error(Text002, Dimension.Name, "G/L Account".FieldCaption("Global Dimension 2 Filter"));
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
        "G/L Account".SetRange("Date Filter");       // since these are in the titles, they
        if not PrintToExcel then begin               // do not have to be in the filter string
            "G/L Account".SetRange("Global Dimension 1 Filter");
            "G/L Account".SetRange("Global Dimension 2 Filter");
        end;
        GLAccountFilter := "G/L Account".GetFilters();
        /* set up header texts
           Note: Since these texts are built up piece by piece, it would do not good to
                 attempt to translate the individual pieces. Therefore, these texts have
                 not been placed into text constats.
        */
        Clear(PeriodText);
        Clear(ColumnHead);
        /* Period Headings */
        case AmountType of
            AmountType::"Actual Change":
                PeriodText := 'Changes from ' + Format(FromDate, 0, 4)
                  + ' to '
                  + Format(ToDate, 0, 4);
            AmountType::"Budget Change":
                PeriodText := 'Budgeted Changes from ' + Format(FromDate, 0, 4)
                  + ' to '
                  + Format(ToDate, 0, 4);
            AmountType::"Last Year Change":
                PeriodText := 'Changes from ' + Format(PriorFromDate, 0, 4)
                  + ' to '
                  + Format(PriorToDate, 0, 4);
            AmountType::"Actual Balance":
                PeriodText := 'As of ' + Format(ToDate, 0, 4);
            AmountType::"Budget Balance":
                PeriodText := 'Budget as of ' + Format(ToDate, 0, 4);
            AmountType::"Last Year Balance":
                PeriodText := 'As of ' + Format(PriorToDate, 0, 4);
        end;
        if UseAddRptCurr then begin
            GLSetup.Get();
            Currency.Get(GLSetup."Additional Reporting Currency");
            SubTitle := StrSubstNo(Text008, Currency.Description);
        end;

        /* Column Headings */
        ColumnHead[1] := 'Total';
        for i := 2 to MaxColumns() do
            ColumnHead[i] := ColumnFilter[i];
        if RoundTo = RoundTo::Thousands then
            for i := 1 to MaxColumns() do
                if ColumnHead[i] <> '' then
                    ColumnHead[i] := ColumnHead[i] + Text009;

        if PrintToExcel then
            MakeExcelInfo();

    end;

    var
        CompanyInformation: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        Dimension: Record Dimension;
        ExcelBuf: Record "Excel Buffer" temporary;
        ParagraphHandling: Codeunit "Paragraph Handling";
        DimCode: Code[20];
        PeriodText: Text[120];
        GLAccountFilter: Text;
        ColumnFilter: array[250] of Text[120];
        SubTitle: Text[132];
        SkipZeros: Boolean;
        UseAddRptCurr: Boolean;
        PrintToExcel: Boolean;
        AmountType: Option "Actual Change","Budget Change","Last Year Change","Actual Balance","Budget Balance","Last Year Balance";
        RoundTo: Option Pennies,Dollars,Thousands;
        LineType: Option "9-Point","9-Point Rounded","8-Point","8-Point Rounded","7-Point","7-Point Rounded";
        ColumnHead: array[250] of Text[120];
        PrintAmount: array[250] of Text[30];
        WorkAmount: array[250] of Decimal;
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
        Text000: Label 'You must select at least one %1.';
        Text001: Label 'If you want more than 5 values for %1, you must round to Dollars or Thousands.';
        Text002: Label 'You must select no more than 7 values for %1. Try another %2.';
        Text003: Label 'Program Bug.';
        Text008: Label 'Amounts are in %1';
        Text009: Label ' (Thousands)';
        Text010: Label 'Too many values for %1 were selected. Try another %2.';
        Text011: Label 'Trial Balance';
        Text012: Label 'There are no Global Dimensions set up in General Ledger Setup. This report can only be used with Global Dimensions.';
        Text013: Label 'You must select a Global Dimension that has been set up in General Ledger Setup.';
        Text014: Label 'You must select no more than 7 values for %1. Try another %2 or select "Print to Excel".';
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
        ExcelAmtFormat: Text[30];
        PageGroupNo: Integer;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        DescriptionLine2_Control10CaptionLbl: Label 'Name';
        DescriptionLine2_Control10Caption_Control40Lbl: Label 'Name';
        DescriptionLine2_Control51CaptionLbl: Label 'Name';
        DescriptionLine2_Control51Caption_Control34Lbl: Label 'Name';
        DescriptionLine2_Control100CaptionLbl: Label 'Name';
        DescriptionLine2_Control100Caption_Control30Lbl: Label 'Name';

    procedure NumColumns() NumCol: Integer
    var
        DimValue: Record "Dimension Value";
    begin
        /* Counts the Number of Columns (Departments) that the user selected */
        Clear(ColumnFilter);
        NumCol := 1;
        if DimCode = GLSetup."Global Dimension 1 Code" then
            ColumnFilter[1] := "G/L Account".GetFilter("Global Dimension 1 Filter")
        else
            if DimCode = GLSetup."Global Dimension 2 Code" then
                ColumnFilter[1] := "G/L Account".GetFilter("Global Dimension 2 Filter")
            else
                Error(Text013);
        DimValue.SetRange("Dimension Code", DimCode);
        DimValue.SetFilter(Code, ColumnFilter[1]);
        if DimValue.Find('-') then
            repeat
                NumCol := NumCol + 1;
                if NumCol > MaxColumns() then begin
                    if DimCode = GLSetup."Global Dimension 1 Code" then
                        Error(Text010,
                          DimValue.TableCaption,
                          "G/L Account".FieldCaption("Global Dimension 1 Filter"));

                    Error(Text010,
                      DimValue.TableCaption,
                      "G/L Account".FieldCaption("Global Dimension 2 Filter"));
                end;
                ColumnFilter[NumCol] := DimValue.Code;
            until DimValue.Next() = 0;
        exit(NumCol);

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
            for i := 1 to ArrayLen(WorkAmount) do
                if WorkAmount[i] <> 0.0 then
                    exit(true);
            exit(false);
        end;
        exit(true);

    end;

    local procedure MaxColumns(): Integer
    begin
        if PrintToExcel then
            exit(ArrayLen(WorkAmount));

        exit(8);
    end;

    local procedure MakeExcelInfo()
    begin
        ExcelBuf.SetUseInfoSheet();
        ExcelBuf.AddInfoColumn(Format(Text103), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(CompanyInformation.Name, false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text105), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(Format(Dimension.Name + ' ' + Text102), false, false, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.NewRow();
        ExcelBuf.AddInfoColumn(Format(Text104), false, true, false, false, '', ExcelBuf."Cell Type"::Text);
        ExcelBuf.AddInfoColumn(REPORT::"Trial Balance, Spread G. Dim.", false, false, false, false, '', ExcelBuf."Cell Type"::Number);
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
        for i := 1 to MaxColumns() do
            if (i = 1) or (ColumnFilter[i] <> '') then
                ExcelBuf.AddColumn(ColumnHead[i], false, '', true, false, true, '', ExcelBuf."Cell Type"::Text);
    end;

    local procedure MakeExcelDataBody()
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
                for i := 1 to MaxColumns() do
                    if (i = 1) or (ColumnFilter[i] <> '') then
                        ExcelBuf.AddColumn(Format(WorkAmount[i]), false, '', false, false, false, ExcelAmtFormat, ExcelBuf."Cell Type"::Number);
        end;
    end;

    local procedure CreateExcelbook()
    begin
        ExcelBuf.CreateBookAndOpenExcel('', Text101, Dimension.Name + ' ' + Text102, CompanyName, UserId);
        Error('');
    end;
}

