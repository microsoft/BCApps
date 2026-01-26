// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

report 11311 "VAT Statement Summary"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/VAT/VATStatementSummary.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Declaration Summary Report';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("VAT Statement Name"; "VAT Statement Name")
        {
            DataItemTableView = sorting("Statement Template Name", Name);
            RequestFilterFields = "Statement Template Name", Name;
            column(VAT_Statement_Name_Statement_Template_Name; "Statement Template Name")
            {
            }
            column(VAT_Statement_Name_Name; Name)
            {
            }
            dataitem("VAT Statement Line"; "VAT Statement Line")
            {
                DataItemLink = "Statement Template Name" = field("Statement Template Name"), "Statement Name" = field(Name);
                DataItemTableView = sorting("Statement Template Name", "Statement Name") where("Print on Official VAT Form" = const(true));
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(Heading; Heading)
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(USERID; UserId)
                {
                }
                column(VAT_Statement_Name___Statement_Template_Name_; "VAT Statement Name"."Statement Template Name")
                {
                }
                column(VAT_Statement_Name__Name; "VAT Statement Name".Name)
                {
                }
                column(HeaderText; HeaderText)
                {
                }
                column(PrintInIntegers; PrintInIntegers)
                {
                }
                column(UseAmtsInAddCurr; UseAmtsInAddCurr)
                {
                }
                column(STRSUBSTNO_Text11306_GLSetup__Additional_Reporting_Currency__; StrSubstNo(Text11306, GLSetup."Additional Reporting Currency"))
                {
                }
                column(Selection; Selection)
                {
                }
                column(Selection___Open_and_Closed_; Selection = Selection::"Open and Closed")
                {
                }
                column(Selection___Selection__Closed; Selection = Selection::Closed)
                {
                }
                column(Selection_IN__Selection__Closed_Selection___Open_and_Closed__; Selection in [Selection::Closed, Selection::"Open and Closed"])
                {
                }
                column(VAT_Statement_Line__TABLECAPTION__________VATStmtLineFilter; "VAT Statement Line".TableCaption + ': ' + VATStmtLineFilter)
                {
                }
                column(VATStmtLineFilter; VATStmtLineFilter)
                {
                }
                column(DateName_1__; DateName[1])
                {
                }
                column(DateName_2__; DateName[2])
                {
                }
                column(DateName_4__; DateName[4])
                {
                }
                column(DateName_3__; DateName[3])
                {
                }
                column(DateName_8__; DateName[8])
                {
                }
                column(DateName_7__; DateName[7])
                {
                }
                column(DateName_6__; DateName[6])
                {
                }
                column(DateName_5__; DateName[5])
                {
                }
                column(DateName_12__; DateName[12])
                {
                }
                column(DateName_11__; DateName[11])
                {
                }
                column(DateName_10__; DateName[10])
                {
                }
                column(DateName_9__; DateName[9])
                {
                }
                column(DateName_13__; DateName[13])
                {
                }
                column(VAT_Statement_Line__Row_No__; "Row No.")
                {
                }
                column(VAT_Statement_Line_Description; Description)
                {
                }
                column(TotalAmount_4_; TotalAmount[4])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_5_; TotalAmount[5])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_6_; TotalAmount[6])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_2_; TotalAmount[2])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_3_; TotalAmount[3])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_1_; TotalAmount[1])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_8_; TotalAmount[8])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_9_; TotalAmount[9])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_7_; TotalAmount[7])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_10_; TotalAmount[10])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_11_; TotalAmount[11])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_12_; TotalAmount[12])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(TotalAmount_13_; TotalAmount[13])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(VAT_Statement_SummaryCaption; VAT_Statement_SummaryCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(VAT_Statement_Name___Statement_Template_Name_Caption; VAT_Statement_Name___Statement_Template_Name_CaptionLbl)
                {
                }
                column(VAT_Statement_Name__NameCaption; VAT_Statement_Name__NameCaptionLbl)
                {
                }
                column(Amounts_are_in_whole_LCYs_Caption; Amounts_are_in_whole_LCYs_CaptionLbl)
                {
                }
                column(The_report_includes_all_VAT_entries_Caption; The_report_includes_all_VAT_entries_CaptionLbl)
                {
                }
                column(The_report_includes_only_closed_VAT_entries_Caption; The_report_includes_only_closed_VAT_entries_CaptionLbl)
                {
                }
                column(VAT_Statement_Line__Row_No__Caption; FieldCaption("Row No."))
                {
                }
                column(VAT_Statement_Line_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(VAT_Statement_Line_Statement_Template_Name; "Statement Template Name")
                {
                }
                column(VAT_Statement_Line_Statement_Name; "Statement Name")
                {
                }
                column(VAT_Statement_Line_Line_No_; "Line No.")
                {
                }

                trigger OnAfterGetRecord()
                var
                    CorrectionAmount: array[12] of Decimal;
                    Dummy: Decimal;
                begin
                    Clear(TotalAmount[NoOfPeriods + 1]);
                    for i := 1 to NoOfPeriods do begin
                        SetFilter("Date Filter", DateFilter[i]);
                        Clear(VATStatement);
                        VATStatement.InitializeRequest(
                          "VAT Statement Name", "VAT Statement Line", Selection,
                          PeriodSelection::"Within Period", PrintInIntegers, UseAmtsInAddCurr);
                        VATStatement.CalcLineTotal("VAT Statement Line", TotalAmount[i], CorrectionAmount[i], Dummy, '', 0);
                        if PrintInIntegers then begin
                            TotalAmount[i] := Round(TotalAmount[i], 1, '<');
                            CorrectionAmount[i] := Round(CorrectionAmount[i], 1, '<');
                        end;
                        TotalAmount[i] := TotalAmount[i] + CorrectionAmount[i];
                        if "Print with" = "Print with"::"Opposite Sign" then
                            TotalAmount[i] := -TotalAmount[i];
                        TotalAmount[NoOfPeriods + 1] := TotalAmount[NoOfPeriods + 1] + TotalAmount[i];

                        Clear(No);
                        if "Row No." <> '' then
                            if Evaluate(No, "Row No.") then
                                if No in [1 .. 99] then
                                    Row[No, i] := TotalAmount[i];
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if UseAmtsInAddCurr then
                        HeaderText := Text11305 + GLSetup."Additional Reporting Currency"
                    else begin
                        GLSetup.TestField("LCY Code");
                        HeaderText := Text11305 + GLSetup."LCY Code";
                    end;
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 .. 14));
                column(VAT_Statement_Name__Name_Control35; "VAT Statement Name".Name)
                {
                }
                column(COMPANYNAME_Control36; COMPANYPROPERTY.DisplayName())
                {
                }
                column(VAT_Statement_Name___Statement_Template_Name__Control37; "VAT Statement Name"."Statement Template Name")
                {
                }
                column(Heading_Control38; Heading)
                {
                }
                column(USERID_Control68; UserId)
                {
                }
                column(FORMAT_TODAY_0_4__Control72; Format(Today, 0, 4))
                {
                }
                column(DateName_1___Control55; DateName[1])
                {
                }
                column(DateName_2___Control57; DateName[2])
                {
                }
                column(DateName_4___Control58; DateName[4])
                {
                }
                column(DateName_3___Control59; DateName[3])
                {
                }
                column(DateName_8___Control60; DateName[8])
                {
                }
                column(DateName_7___Control61; DateName[7])
                {
                }
                column(DateName_6___Control62; DateName[6])
                {
                }
                column(DateName_5___Control63; DateName[5])
                {
                }
                column(DateName_9___Control64; DateName[9])
                {
                }
                column(DateName_10___Control65; DateName[10])
                {
                }
                column(DateName_11___Control66; DateName[11])
                {
                }
                column(DateName_12___Control67; DateName[12])
                {
                    AutoFormatExpression = GetCurrency();
                    AutoFormatType = 1;
                }
                column(Control_Number_; Control[Number])
                {
                }
                column(Checklist_Number_2_; Checklist[Number, 2])
                {
                }
                column(Checklist_Number_1_; Checklist[Number, 1])
                {
                }
                column(Checklist_Number_3_; Checklist[Number, 3])
                {
                }
                column(Checklist_Number_4_; Checklist[Number, 4])
                {
                }
                column(Checklist_Number_8_; Checklist[Number, 8])
                {
                }
                column(Checklist_Number_7_; Checklist[Number, 7])
                {
                }
                column(Checklist_Number_6_; Checklist[Number, 6])
                {
                }
                column(Checklist_Number_5_; Checklist[Number, 5])
                {
                }
                column(Checklist_Number_12_; Checklist[Number, 12])
                {
                }
                column(Checklist_Number_11_; Checklist[Number, 11])
                {
                }
                column(Checklist_Number_10_; Checklist[Number, 10])
                {
                }
                column(Checklist_Number_9_; Checklist[Number, 9])
                {
                }
                column(VAT_Statement_Logical_ControlsCaption; VAT_Statement_Logical_ControlsCaptionLbl)
                {
                }
                column(VAT_Statement_Name___Statement_Template_Name__Control37Caption; VAT_Statement_Name___Statement_Template_Name__Control37CaptionLbl)
                {
                }
                column(VAT_Statement_Name__Name_Control35Caption; VAT_Statement_Name__Name_Control35CaptionLbl)
                {
                }
                column(Description_of_controlCaption; Description_of_controlCaptionLbl)
                {
                }
                column(Integer_Number; Number)
                {
                }

                trigger OnPreDataItem()
                begin
                    if not ReportErrors then
                        CurrReport.Break();

                    VATLogicalControls.CheckForErrors(NoOfPeriods, Row, ErrorMargin, December, Control, Checklist);

                    Clear(DateName[NoOfPeriods + 1]);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(Row);
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
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
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        NotBlank = true;
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(NoOfPeriods; NoOfPeriods)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'No. of Periods';
                        MaxValue = 12;
                        MinValue = 1;
                        ToolTip = 'Specifies the number of periods to be included in the report. The length of the periods is determined by the length of the periods in the Accounting Period table.';
                    }
                    field(ReportErrors; ReportErrors)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Logical Controls';
                        ToolTip = 'Specifies if you want to perform the logical checks on the VAT rows and print the results of the checks.';
                    }
                    field(Selection; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include VAT Entries';
                        ToolTip = 'Specifies the VAT entries to be included in the report. You can choose between Open, Closed and Open and Closed.';
                    }
                    field(PrintInIntegers; PrintInIntegers)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Round to Whole Numbers';
                        ToolTip = 'Specifies if you want the amounts in the report to be rounded to whole numbers.';
                    }
                    field(UseAmtsInAddCurr; UseAmtsInAddCurr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Amounts in Add. Reporting Currency';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want the amounts to be printed in the additional reporting currency. If you leave this check box empty, the amounts will be printed in LCY.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if (StartDate = 0D) or (NoOfPeriods = 0) then begin
                StartDate := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
                NoOfPeriods := 12;
                ReportErrors := true;
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if ReportErrors then begin
            GLSetup.Get();
            if UseAmtsInAddCurr then
                ReportingCurr := GLSetup."Additional Reporting Currency"
            else
                ReportingCurr := GLSetup."LCY Code";
            case ReportingCurr of
                BEFTok:
                    ErrorMargin := 2500;
                EURTok:
                    ErrorMargin := 61.97;
                else
                    ErrorMargin := 0;
            end;
        end;

        Calender."Period Start" := StartDate;
        PeriodType := PeriodType::"Accounting Period";

        for i := 1 to NoOfPeriods do begin
            if i <> 1 then
                PeriodPageManagement.NextDate(1, Calender, PeriodType)
            else
                if not PeriodPageManagement.FindDate('=', Calender, PeriodType) then begin
                    PeriodType := PeriodType::Month;
                    if not PeriodPageManagement.FindDate('=', Calender, PeriodType) then
                        Error(Text11301);
                end;

            DateName[i] := PeriodPageManagement.CreatePeriodFormat(PeriodType, Calender."Period Start");
            DateFilter[i] := Format(Calender."Period Start") + '..' + Format(Calender."Period End");

            AccountingPeriod.Reset();
            AccountingPeriod.SetRange("Starting Date", Calender."Period Start");
            AccountingPeriod.SetRange(Name, Calender."Period Name");
            if AccountingPeriod.FindFirst() then
                DateName[i] := AccountingPeriod.Name;

            if Date2DMY(Calender."Period End", 2) = 12 then
                December := i;
        end;

        DateName[NoOfPeriods + 1] := Text11303;
        VATStmtLineFilter := "VAT Statement Line".GetFilters();
        Heading := Text11304 + Format(StartDate) + '..' + Format(Calender."Period End");
    end;

    var
        BEFTok: Label 'BEF';
        EURTok: Label 'EUR';
        Text11301: Label 'Unable to find period.';
        Text11303: Label 'Total';
        Text11304: Label 'Period: ';
        Text11305: Label 'All amounts are in ';
        Text11306: Label 'Amounts are in whole %1.';
        GLSetup: Record "General Ledger Setup";
        AccountingPeriod: Record "Accounting Period";
        Calender: Record Date;
        VATStatement: Report "VAT Statement";
        PeriodPageManagement: Codeunit PeriodPageManagement;
        VATLogicalControls: Codeunit VATLogicalTests;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        PeriodType: Enum "Analysis Period Type";
        PrintInIntegers: Boolean;
        TotalAmount: array[13] of Decimal;
        VATStmtLineFilter: Text[250];
        Heading: Text[50];
        UseAmtsInAddCurr: Boolean;
        HeaderText: Text[50];
        StartDate: Date;
        No: Integer;
        NoOfPeriods: Integer;
        i: Integer;
        DateName: array[13] of Text[20];
        DateFilter: array[12] of Text[30];
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        Checklist: array[14, 12] of Text[30];
        December: Integer;
        ReportingCurr: Code[10];
        ErrorMargin: Decimal;
        ReportErrors: Boolean;
        VAT_Statement_SummaryCaptionLbl: Label 'VAT Statement Summary';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        VAT_Statement_Name___Statement_Template_Name_CaptionLbl: Label 'VAT Statement Template';
        VAT_Statement_Name__NameCaptionLbl: Label 'VAT Statement Name';
        Amounts_are_in_whole_LCYs_CaptionLbl: Label 'Amounts are in whole LCYs.';
        The_report_includes_all_VAT_entries_CaptionLbl: Label 'The report includes all VAT entries.';
        The_report_includes_only_closed_VAT_entries_CaptionLbl: Label 'The report includes only closed VAT entries.';
        VAT_Statement_Logical_ControlsCaptionLbl: Label 'VAT Statement Logical Controls';
        VAT_Statement_Name___Statement_Template_Name__Control37CaptionLbl: Label 'VAT Statement Template';
        VAT_Statement_Name__Name_Control35CaptionLbl: Label 'VAT Statement Name';
        Description_of_controlCaptionLbl: Label 'Description of control';

    local procedure GetCurrency(): Code[10]
    begin
        if UseAmtsInAddCurr then
            exit(GLSetup."Additional Reporting Currency");

        exit('');
    end;
}

