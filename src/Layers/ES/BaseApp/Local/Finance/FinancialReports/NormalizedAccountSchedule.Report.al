// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using System.Utilities;

report 10717 "Normalized Account Schedule"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/FinancialReports/NormalizedAccountSchedule.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Normalized Account Schedule';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfo_Name_________CompanyInfo__Name_2_; CompanyInfo.Name + ' ' + CompanyInfo."Name 2")
            {
            }
            column(CompanyInfo_Address________CompanyInfo__Address_2_; CompanyInfo.Address + ' ' + CompanyInfo."Address 2")
            {
            }
            column(CompanyInfo_City; CompanyInfo.City)
            {
            }
            column(CompanyInfo__Post_Code_; CompanyInfo."Post Code")
            {
            }
            column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
            {
            }
            column(CompanyInfo_County; CompanyInfo.County)
            {
            }
            column(CompanyInfo__CNAE_Description_; CompanyInfo."CNAE Description")
            {
            }
            column(CompanyInfo__Industrial_Classification_; CompanyInfo."Industrial Classification")
            {
            }
            column(NoOfPages; NoOfPages)
            {
            }
            column(DATE2DMY_CloseDate_3_; Date2DMY(CloseDate, 3))
            {
            }
            column(DATE2DMY_CloseDate_2_; Date2DMY(CloseDate, 2))
            {
            }
            column(DATE2DMY_CloseDate_1_; Date2DMY(CloseDate, 1))
            {
            }
            column(Personnel_1_; Personnel[1])
            {
            }
            column(Personnel_3_; Personnel[3])
            {
            }
            column(Personnel_2_; Personnel[2])
            {
            }
            column(Personnel_4_; Personnel[4])
            {
            }
            column(Integer_Number; Number)
            {
            }

            trigger OnPreDataItem()
            begin
                if not GeneralIdData then
                    CurrReport.Break();

                NextPageGroupNo := 0;
            end;
        }
        dataitem("Acc. Schedule Name"; "Acc. Schedule Name")
        {
            RequestFilterFields = Name;
            column(Acc__Schedule_Name_Name; Name)
            {
            }
            dataitem("Acc. Schedule Line"; "Acc. Schedule Line")
            {
                DataItemLink = "Schedule Name" = field(Name);
                DataItemTableView = sorting("Schedule Name", "Line No.");
                RequestFilterFields = "Date Filter", "Dimension 1 Filter", "Dimension 2 Filter";
                column(DisplayText_1_; DisplayText[1])
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(DisplayText_2_; DisplayText[2])
                {
                }
                column(DisplayText_3_; DisplayText[3])
                {
                }
                column(CompName_1_; CompName[1])
                {
                }
                column(DisplayText_4_; DisplayText[4])
                {
                }
                column(CompanyInfo__VAT_Registration_No___Control1100023; CompanyInfo."VAT Registration No.")
                {
                }
                column(CompName_2_; CompName[2])
                {
                }
                column(DisplayText_5_; DisplayText[5])
                {
                }
                column(FiscalYearTxt1; FiscalYearTxt1)
                {
                }
                column(DisplayText_6_; DisplayText[6])
                {
                }
                column(DisplayText_6__Control1100028; DisplayText[6])
                {
                }
                column(FiscalYearTxt2; FiscalYearTxt2)
                {
                }
                column(Acc__Schedule_Line__Underline; "Acc. Schedule Line".Underline)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(ShowLine_TRUE_FALSE_FALSE_; ShowLine(true, false, false))
                {
                }
                column(ShowLine_TRUE_TRUE_FALSE_; ShowLine(true, true, false))
                {
                }
                column(ShowLine_TRUE_FALSE_TRUE_; ShowLine(true, false, true))
                {
                }
                column(ShowLine_TRUE_TRUE_TRUE_; ShowLine(true, true, true))
                {
                }
                column(ShowLine_FALSE_FALSE_FALSE_; ShowLine(false, false, false))
                {
                }
                column(ShowLine_FALSE_TRUE_FALSE_; ShowLine(false, true, false))
                {
                }
                column(ShowLine_FALSE_FALSE_TRUE_; ShowLine(false, false, true))
                {
                }
                column(ShowLine_FALSE_TRUE_TRUE_; ShowLine(false, true, true))
                {
                }
                column(AccSchLine__Line_No__; "Acc. Schedule Line"."Line No.")
                {
                }
                column(GeneralIdData; GeneralIdData)
                {
                }
                column(PageNONO; PageNONO)
                {
                }
                column(ColumnValuesAsText_2_; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_1_; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Line_Description; Description)
                {
                }
                column(Acc__Schedule_Line_Description_Control1100033; Description)
                {
                }
                column(ColumnValuesAsText_1__Control1100034; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2__Control1100035; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Line_Description_Control1100036; Description)
                {
                }
                column(ColumnValuesAsText_1__Control1100037; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2__Control1100038; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Line_Description_Control1100039; Description)
                {
                }
                column(ColumnValuesAsText_1__Control1100040; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2__Control1100041; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2__Control1100042; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_1__Control1100043; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Line_Description_Control1100044; Description)
                {
                }
                column(Acc__Schedule_Line_Description_Control1100045; Description)
                {
                }
                column(ColumnValuesAsText_1__Control1100046; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2__Control1100047; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Line_Description_Control1100048; Description)
                {
                }
                column(ColumnValuesAsText_1__Control1100049; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2__Control1100050; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Line_Description_Control1100051; Description)
                {
                }
                column(ColumnValuesAsText_1__Control1100052; ColumnValuesAsText[1])
                {
                    AutoCalcField = false;
                }
                column(ColumnValuesAsText_2__Control1100053; ColumnValuesAsText[2])
                {
                    AutoCalcField = false;
                }
                column(Acc__Schedule_Line_Schedule_Name; "Schedule Name")
                {
                }

                trigger OnAfterGetRecord()
                var
                    AccScheduleLine: Record "Acc. Schedule Line";
                begin
                    PageNONO += 1;
                    if not UsePreprintedForm then begin
                        DisplayText[1] := UpperCase("Acc. Schedule Name".Description);
                        DisplayText[3] := Text1100006;
                        DisplayText[4] := Text1100007;
                        DisplayText[6] := Text1100008;

                        DisplayText[5] := UpperCase(Format("Acc. Schedule Line".Type));
                        if PageNONO = 1 then begin
                            DisplayText[2] := "Acc. Schedule Line".TableCaption + ': ' + AccSchedLineFilter;
                            if PrintAmountsInAddCurrency then
                                HeaderText := Text1100003 + GLSetup."Additional Reporting Currency"
                            else begin
                                GLSetup.TestField("LCY Code");
                                HeaderText := Text1100003 + GLSetup."LCY Code";
                            end;
                        end else begin
                            DisplayText[2] := '';
                            HeaderText := '';
                        end;
                    end else begin
                        HeaderText := '';
                        DisplayText[1] := '';
                        DisplayText[2] := '';
                        DisplayText[3] := '';
                        DisplayText[4] := '';
                        DisplayText[5] := '';
                        DisplayText[6] := '';
                    end;

                    PageGroupNo := NextPageGroupNo;
                    if "Acc. Schedule Line"."New Page" then begin
                        AccScheduleLine := "Acc. Schedule Line";
                        if AccScheduleLine.Next() <> 0 then
                            DisplayText[5] := UpperCase(Format(AccScheduleLine.Type));
                        NextPageGroupNo += 1;
                    end;

                    for i := 1 to MaxColumnsDisplayed do begin
                        ColumnValuesDisplayed[i] := 0;
                        ColumnValuesAsText[i] := '';
                    end;

                    if UsePreprintedForm then
                        Description := ''
                    else
                        Description := PadStr('', Indentation * 2) + Description;
                end;

                trigger OnPreDataItem()
                begin
                    NextPageGroupNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Standardized, true);
            end;

            trigger OnPreDataItem()
            begin
                if "Acc. Schedule Name".GetRangeMin(Name) <> "Acc. Schedule Name".GetRangeMax(Name) then
                    Error(Text1100004);
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
                    field(UsePreprintedForm; UsePreprintedForm)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Preprinted Form';
                        ToolTip = 'Specifies if you want to print the Normalized Account Schedule on preprinted stationary.';
                    }
                    field(GeneralIdData; GeneralIdData)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print General';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to print the general Account Schedule.';
                    }
                    field("Personnel[1]"; Personnel[1])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Permanent Wage-earning Employees in Fiscal Year';
                        MultiLine = true;
                        ToolTip = 'Specifies the number of permanent wage earning employees for the fiscal year.';
                    }
                    field("Personnel[2]"; Personnel[2])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Wage-earning Employees in Previous year';
                        MultiLine = true;
                        ToolTip = 'Specifies the number of wage earning employees for the previous year.';
                    }
                    field("Personnel[3]"; Personnel[3])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Temporary Wage-earner Employees in Fiscal Year';
                        MultiLine = true;
                        ToolTip = 'Specifies the number of temporary wage earning employees for the current fiscal year.';
                    }
                    field("Personnel[4]"; Personnel[4])
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Temporary Wage-earner Employees in Previous Year';
                        MultiLine = true;
                        ToolTip = 'Specifies the number of temporary wage earning employees for the previous year.';
                    }
                    field(NoOfPages; NoOfPages)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Total No. of pages presented in the Mercantile Registry';
                        MultiLine = true;
                        ToolTip = 'Specifies the number of pages that are included in the Mercantile Registry.';
                    }
                    field(CloseDate; CloseDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closing date to which the annual accounts refer to';
                        MultiLine = true;
                        NotBlank = true;
                        ToolTip = 'Specifies the closing date that refers to the annual accounts.';
                    }
                    field(PrintAmountsInAddCurrency; PrintAmountsInAddCurrency)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Currency';
                        ToolTip = 'Specifies if amounts in the additional currency are included.';
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

    trigger OnPreReport()
    var
        FinancialReport: Record "Financial Report";
        LocalColumnLayoutName: Record "Column Layout Name";
    begin
        if GeneralIdData and (CloseDate = 0D) then
            Error(Text1100000);

        CompanyInfo.Get();
        SplitCompanyName(CompanyInfo, CompName);

        "Acc. Schedule Name".Find('-');
        if FinancialReport.Get("Acc. Schedule Name".Name) then
            ColumnLayoutName := FinancialReport."Financial Report Column Group"
        else
            if LocalColumnLayoutName.FindFirst() then
                ColumnLayoutName := LocalColumnLayoutName.Name;
        // AccSchedManagement.SetAccSchedName(PrintAmountsInAddCurrency);
        InitAccSched();
        GLSetup.Get();
    end;

    var
        CompanyInfo: Record "Company Information";
        ColLayoutTmp: Record "Column Layout" temporary;
        GLSetup: Record "General Ledger Setup";
        AccSchedManagement: Codeunit AccSchedManagement;
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
        UsePreprintedForm: Boolean;
        AccSchedLineFilter: Text[250];
        FiscalYearTxt1: Text[30];
        FiscalYearTxt2: Text[30];
        CompName: array[2] of Text[50];
        HeaderText: Text[30];
        CloseDate: Date;
        Personnel: array[4] of Integer;
        NoOfPages: Integer;
        GeneralIdData: Boolean;
        TokenPointer: Integer;
        ColumnValuesDisplayed: array[5] of Decimal;
        ColumnValuesAsText: array[5] of Text[30];
        MaxColumnsDisplayed: Integer;
        i: Integer;
        StartDate: Date;
        EndDate: Date;
        FiscalStartDate: Date;
        ColumnLayoutName: Code[10];
        ShowDivideError: Boolean;
        PrintAmountsInAddCurrency: Boolean;
        DisplayText: array[6] of Text[505];
        Text1100000: Label 'Closing dates must be specified in G/L Accounts.';
        Text1100001: Label '* ERROR *';
        Text1100003: Label 'All amounts are in ';
        Text1100004: Label 'Select a unique Account Schedule';
        Text1100006: Label 'Personal Tax Number';
        Text1100007: Label 'UNIQUE COMPANY NAME';
        Text1100008: Label 'FISCAL YEAR';
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        PageNONO: Integer;

    [Scope('OnPrem')]
    procedure SplitCompanyName(var CompanyInfo2: Record "Company Information"; var Line: array[2] of Text[132])
    var
        FullName: Text[101];
        NewToken: Text[50];
        FullLine: Boolean;
        NoMoreTokens: Boolean;
    begin
        FullName := CopyStr(CompanyInfo2.Name + ' ' + CompanyInfo2."Name 2", 1, 100);
        FullLine := false;
        NoMoreTokens := false;
        Token(FullName, Line[1]);
        repeat
            Token(FullName, NewToken);
            if NewToken = '' then
                NoMoreTokens := true
            else
                if StrLen(Line[1] + NewToken) + 1 > MaxStrLen(CompName[1])
                then begin
                    FullLine := true;
                    Line[2] := NewToken;
                end else
                    Line[1] := Line[1] + ' ' + NewToken;
        until NoMoreTokens or FullLine;

        if FullLine then begin
            FullLine := false;
            repeat
                Token(FullName, NewToken);
                if NewToken = '' then
                    NoMoreTokens := true
                else
                    if StrLen(Line[2] + NewToken) + 1 > MaxStrLen(CompName[2]) then
                        FullLine := true
                    else
                        Line[2] := Line[2] + ' ' + NewToken;
            until NoMoreTokens or FullLine;
        end;
    end;

    [Scope('OnPrem')]
    procedure Token(String: Text[132]; var Token: Text[132])
    var
        Character: Text[30];
    begin
        Token := '';
        repeat
            TokenPointer := TokenPointer + 1;
            Character := CopyStr(String, TokenPointer, 1);
        until Character <> ' ';
        while (Character <> ' ') and (Character <> '') do begin
            Token := Token + Character;
            TokenPointer := TokenPointer + 1;
            Character := CopyStr(String, TokenPointer, 1);
        end;
    end;

    [Scope('OnPrem')]
    procedure InitAccSched()
    begin
        StartDate := "Acc. Schedule Line".GetRangeMin("Date Filter");
        EndDate := "Acc. Schedule Line".GetRangeMax("Date Filter");
        FiscalStartDate := AccountingPeriodMgt.FindFiscalYear(EndDate);
        FiscalYearTxt1 := Format(Date2DMY(CalcDate('<1Y-1D>', FiscalStartDate), 3));
        FiscalYearTxt2 := Format(Date2DMY(CalcDate('<-1D>', FiscalStartDate), 3));
        if UsePreprintedForm then begin
            FiscalYearTxt1 := CopyStr(FiscalYearTxt1, 4);
            FiscalYearTxt2 := CopyStr(FiscalYearTxt2, 4);
        end;

        MaxColumnsDisplayed := ArrayLen(ColumnValuesDisplayed);
        AccSchedLineFilter := "Acc. Schedule Line".GetFilters();
        AccSchedManagement.CopyColumnsToTemp(ColumnLayoutName, ColLayoutTmp);
    end;

    [Scope('OnPrem')]
    procedure CalcColumns(): Boolean
    var
        NonZero: Boolean;
    begin
        NonZero := false;
        ColLayoutTmp.SetRange("Column Layout Name", ColumnLayoutName);
        i := 0;
        if ColLayoutTmp.Find('-') then
            repeat
                if ColLayoutTmp.Show <> ColLayoutTmp.Show::Never then begin
                    i := i + 1;
                    ColumnValuesDisplayed[i] := AccSchedManagement.CalcCell("Acc. Schedule Line", ColLayoutTmp, PrintAmountsInAddCurrency);
                    if AccSchedManagement.GetDivisionError() then begin
                        if ShowDivideError then
                            ColumnValuesAsText[i] := Text1100001
                        else
                            ColumnValuesAsText[i] := '';
                    end else begin
                        NonZero := NonZero or (ColumnValuesDisplayed[i] <> 0);
                        ColumnValuesAsText[i] :=
                          AccSchedManagement.FormatCellAsText(ColLayoutTmp, ColumnValuesDisplayed[i], PrintAmountsInAddCurrency);
                    end;
                end;
            until (i >= MaxColumnsDisplayed) or (ColLayoutTmp.Next() = 0);
        exit(NonZero);
    end;

    [Scope('OnPrem')]
    procedure ShowLine(Opc: Boolean; Bold: Boolean; Italic: Boolean): Boolean
    var
        NonZero: Boolean;
        PrintLine: Boolean;
    begin
        NonZero := false;

        if "Acc. Schedule Line".Show = "Acc. Schedule Line".Show::No then
            exit(false);
        if "Acc. Schedule Line".Bold <> Bold then
            exit(false);
        if "Acc. Schedule Line".Italic <> Italic then
            exit(false);

        if Opc = false then begin
            PrintLine := ("Acc. Schedule Line".Show in ["Acc. Schedule Line".Show::"When Positive Balance"]);
            if PrintLine then
                NonZero := CalcColumns();
            exit(PrintLine);
        end;
        PrintLine := not ("Acc. Schedule Line".Show in ["Acc. Schedule Line".Show::No,
                                                        "Acc. Schedule Line".Show::"When Positive Balance"]);
        if PrintLine then begin
            NonZero := CalcColumns();
            if "Acc. Schedule Line".Show = "Acc. Schedule Line".Show::"If Any Column Not Zero" then
                PrintLine := NonZero;
            exit(PrintLine);
        end;

        exit(true);
    end;
}

