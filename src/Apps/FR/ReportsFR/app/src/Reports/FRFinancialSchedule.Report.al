// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;

report 10854 "FR Financial Schedule"
{
    ApplicationArea = Basic, Suite;
    DefaultLayout = RDLC;
    RDLCLayout = './src/Reports/FRFinancialSchedule.rdlc';
    Caption = 'FR Account Schedule';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("FR Acc. Schedule Name"; "FR Financial Schedule Name")
        {
            DataItemTableView = sorting(Name);
            RequestFilterFields = Name;
            column(FR_Acc__Schedule_Name_Name; Name)
            {
            }
            dataitem("FR Acc. Schedule Line"; "FR Financial Schedule Line")
            {
                DataItemLink = "Schedule Name" = field(Name);
                DataItemTableView = sorting("Schedule Name", "Line No.");
                RequestFilterFields = "Date Filter", "Dimension 1 Filter", "Dimension 2 Filter", "Date Filter 2";
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(Text10801___PeriodText; PeriodCaptionTxt + PeriodText)
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(USERID; UserId)
                {
                }
                column(FR_Acc__Schedule_Name__Name; "FR Acc. Schedule Name".Name)
                {
                }
                column(FR_Acc__Schedule_Line__TABLECAPTION__________AccSchedLineFilter; TableCaption + ': ' + AccSchedLineFilter)
                {
                }
                column(AccSchedLineFilter; AccSchedLineFilter)
                {
                }
                column(FR_Acc__Schedule_Name___Caption_Column_1_; "FR Acc. Schedule Name"."Caption Column 1")
                {
                }
                column(Previous_Period; PeriodText2)
                {
                }
                column(FR_Acc__Schedule_Name___Caption_Column_Previous_Year_; "FR Acc. Schedule Name"."Caption Column Previous Year")
                {
                }
                column(FR_Acc__Schedule_Name___Caption_Column_2_; "FR Acc. Schedule Name"."Caption Column 2")
                {
                }
                column(FR_Acc__Schedule_Name___Caption_Column_3_; "FR Acc. Schedule Name"."Caption Column 3")
                {
                }
                column(EmptyString; '')
                {
                }
                column(EmptyString_Control26; '')
                {
                }
                column(EmptyString_Control27; '')
                {
                }
                column(FR_Acc__Schedule_Line_Description; Description)
                {
                }
                column(Sign_TotalNetChange; Sign * TotalNetChange)
                {
                }
                column(Previous_Period_Control20; Sign * TotalPreviousYear)
                {
                }
                column(Sign_TotalNetChange2; -Sign * TotalNetChange2)
                {
                }
                column(Sign_TotalCurrentYear; Sign * TotalCurrentYear)
                {
                }
                column(Previous_Period_Control23; Realized)
                {
                }
                column(PageGroupNo; PageGroupNo)
                {
                }
                column(FR_Acc__Schedule_Line_Schedule_Name; "Schedule Name")
                {
                }
                column(FR_Acc__Schedule_Line_Line_No_; "Line No.")
                {
                }
                column(Account_ScheduleCaption; Account_ScheduleCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(FR_Acc__Schedule_Name__NameCaption; FR_Acc__Schedule_Name__NameCaptionLbl)
                {
                }
                column(FR_Acc__Schedule_Line_DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Previous_Period_Control23Caption; Previous_Period_Control23CaptionLbl)
                {
                }
                column(Comptes_NCaption; Comptes_NCaptionLbl)
                {
                }

                trigger OnPreDataItem()
                begin
                    InitializeExecutionFilters();
                end;

                trigger OnAfterGetRecord()
                begin
                    TotalNetChange := 0;
                    TotalNetChange2 := 0;
                    TotalNetChangePrevious := 0;
                    TotalNetChange2Previous := 0;
                    TotalPreviousYear := 0;
                    CalcSchedLineTotal("FR Acc. Schedule Line", 0, TotalNetChange, TotalNetChange2);
                    SetFilter("Date Filter", PeriodText2);
                    TotalCurrentYear := TotalNetChange + TotalNetChange2;
                    CalcSchedLineTotal("FR Acc. Schedule Line", 0, TotalNetChangePrevious, TotalNetChange2Previous);
                    TotalPreviousYear := TotalNetChangePrevious + TotalNetChange2Previous;
                    SetFilter("Date Filter", PeriodText);
                    if TotalPreviousYear <> 0 then
                        Realized := (TotalNetChange + TotalNetChange2) / TotalPreviousYear * 100
                    else
                        Realized := 0;
                    if "FR Acc. Schedule Name"."Caption Column 1" = '' then
                        TotalNetChange := 0;
                    if "FR Acc. Schedule Name"."Caption Column 2" = '' then
                        TotalNetChange2 := 0;

                    case "Calculate with" of
                        "Calculate with"::Sign:
                            Sign := 1;
                        "Calculate with"::"Opposite Sign":
                            Sign := -1;
                    end;
                    PageGroupNo := NextPageGroupNo;
                    if "New Page" then
                        NextPageGroupNo := PageGroupNo + 1;
                end;
            }

            trigger OnPreDataItem()
            begin
#if not CLEAN30
#pragma warning disable AL0432
                if LegacyHeaderContext.GetFilters() <> '' then
                    "FR Acc. Schedule Name".SetView(LegacyHeaderContext.GetView(false));
                if LegacyLineContext.GetFilter("Schedule Name") <> '' then
                    LegacyLineContext.CopyFilter("Schedule Name", "FR Acc. Schedule Name".Name);
#pragma warning restore AL0432
#endif
                PageGroupNo := 1;
                NextPageGroupNo := 1;
            end;
        }
#if not CLEAN30
#pragma warning disable AL0432, AS0105
        // Native old-ID calls apply SetTableView after substitution; retain table-compatible context dataitems.
        dataitem(LegacyHeaderContext; "FR Acc. Schedule Name")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Use FR Financial Schedule Name records when running this report. Legacy report-call context is no longer needed.';
            ObsoleteTag = '30.0';

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
        dataitem(LegacyLineContext; "FR Acc. Schedule Line")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Use FR Financial Schedule Line records when running this report. Legacy report-call context is no longer needed.';
            ObsoleteTag = '30.0';

            trigger OnPreDataItem()
            begin
                CurrReport.Break();
            end;
        }
#pragma warning restore AL0432, AS0105
#endif
    }

    requestpage
    {

        layout
        {
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
        FinancialScheduleMgt: Codeunit "FR Financial Schedule Mgt.";
    begin
        FinancialScheduleMgt.EnsureAvailable();
        GLAcc.SecurityFiltering(SecurityFilter::Filtered);
        GLAcc2.SecurityFiltering(SecurityFilter::Filtered);
    end;

    local procedure InitializeExecutionFilters()
    begin
#if not CLEAN30
#pragma warning disable AL0432
        if LegacyLineContext.GetFilters() <> '' then
            "FR Acc. Schedule Line".SetView(LegacyLineContext.GetView(false));
        if LegacyLineContext.GetFilter("Date Filter") <> '' then
            LegacyLineContext.CopyFilter("Date Filter", "FR Acc. Schedule Line"."Date Filter");
        if LegacyLineContext.GetFilter("Date Filter 2") <> '' then
            LegacyLineContext.CopyFilter("Date Filter 2", "FR Acc. Schedule Line"."Date Filter 2");
        if LegacyLineContext.GetFilter("Dimension 1 Filter") <> '' then
            LegacyLineContext.CopyFilter("Dimension 1 Filter", "FR Acc. Schedule Line"."Dimension 1 Filter");
        if LegacyLineContext.GetFilter("Dimension 2 Filter") <> '' then
            LegacyLineContext.CopyFilter("Dimension 2 Filter", "FR Acc. Schedule Line"."Dimension 2 Filter");
        if LegacyLineContext.GetFilter("Business Unit Filter") <> '' then
            LegacyLineContext.CopyFilter("Business Unit Filter", "FR Acc. Schedule Line"."Business Unit Filter");
        if LegacyLineContext.GetFilter("Budget Filter") <> '' then
            LegacyLineContext.CopyFilter("Budget Filter", "FR Acc. Schedule Line"."Budget Filter");
#pragma warning restore AL0432
#endif
        AccSchedLineFilter := "FR Acc. Schedule Line".GetFilters();
        PeriodText := "FR Acc. Schedule Line".GetFilter("Date Filter");
        if "FR Acc. Schedule Line".GetFilter("Date Filter 2") = '' then
            if PeriodText <> '' then
                "FR Acc. Schedule Line".SetRange(
                  "Date Filter 2", CalcDateYearBefore("FR Acc. Schedule Line".GetRangeMin("Date Filter")),
                  CalcDateYearBefore("FR Acc. Schedule Line".GetRangeMax("Date Filter")));
        PeriodText2 := "FR Acc. Schedule Line".GetFilter("Date Filter 2");
    end;

    var
        GLAcc: Record "G/L Account";
        GLAcc2: Record "G/L Account";
        PeriodCaptionTxt: Label 'Period: ';
        PeriodText: Text;
        PeriodText2: Text;
        AccSchedLineFilter: Text;
        TotalNetChange: Decimal;
        TotalNetChange2: Decimal;
        TotalNetChangePrevious: Decimal;
        TotalNetChange2Previous: Decimal;
        TotalCurrentYear: Decimal;
        TotalPreviousYear: Decimal;
        Realized: Decimal;
        Sign: Integer;
        TotalingType: Option " ",Debitor,Creditor;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        Account_ScheduleCaptionLbl: Label 'Account Schedule';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        FR_Acc__Schedule_Name__NameCaptionLbl: Label 'FR Acc. Schedule Name';
        Previous_Period_Control23CaptionLbl: Label 'Realized (%)';
        Comptes_NCaptionLbl: Label 'Comptes N';
        RecursiveTotalErr: Label 'French financial schedule row %1 exceeds the maximum nesting depth of six. Check the row references for a cycle or shorten the chain.', Comment = '%1 = schedule row number';

    local procedure CalcGLAccTotal(var GLAccount: Record "G/L Account"; var TotalAmount: Decimal; SelectionType: Option " ",Debitor,Creditor)
    begin
        if GLAccount.Find('-') then
            repeat
                GLAccount.CalcFields("Net Change");
                if (SelectionType = SelectionType::" ") or
                   ((SelectionType = SelectionType::Debitor) and (GLAccount."Net Change" > 0)) or
                   ((SelectionType = SelectionType::Creditor) and (GLAccount."Net Change" < 0))
                then
                    TotalAmount := TotalAmount + GLAccount."Net Change";
            until GLAccount.Next() = 0;
    end;

    procedure CalcSchedLineTotal(var SourceLine: Record "FR Financial Schedule Line"; Level: Integer; var PrimaryTotal: Decimal; var SecondaryTotal: Decimal): Boolean
    var
        AccSchedLine2: Record "FR Financial Schedule Line";
    begin
        AccSchedLine2.Copy(SourceLine);
        GLAcc.SecurityFiltering(SecurityFilter::Filtered);
        GLAcc2.SecurityFiltering(SecurityFilter::Filtered);
        if AccSchedLine2.Totaling <> '' then
            if AccSchedLine2."Totaling Type" = AccSchedLine2."Totaling Type"::Rows then begin
                if Level >= 6 then
                    Error(RecursiveTotalErr, AccSchedLine2."Row No.");
                Level := Level + 1;
                AccSchedLine2.SetRange("Schedule Name", AccSchedLine2."Schedule Name");
                AccSchedLine2.SetFilter("Row No.", AccSchedLine2.Totaling);
                if AccSchedLine2.Find('-') then
                    repeat
                        CalcSchedLineTotal(AccSchedLine2, Level, PrimaryTotal, SecondaryTotal);
                    until AccSchedLine2.Next() = 0;
            end else begin
                AccSchedLine2.CopyFilter("Date Filter", GLAcc."Date Filter");
                AccSchedLine2.CopyFilter("Business Unit Filter", GLAcc."Business Unit Filter");
                AccSchedLine2.CopyFilter("Dimension 1 Filter", GLAcc."Global Dimension 1 Filter");
                AccSchedLine2.CopyFilter("Dimension 2 Filter", GLAcc."Global Dimension 2 Filter");
                case AccSchedLine2."Totaling Type" of
                    AccSchedLine2."Totaling Type"::"Posting Accounts":
                        begin
                            GLAcc.SetFilter("No.", AccSchedLine2.Totaling);
                            GLAcc.SetRange("Account Type", GLAcc."Account Type"::Posting);
                            CalcGLAccTotal(GLAcc, PrimaryTotal, TotalingType::" ");
                            CalcSchedLineDebitCredit(GLAcc, AccSchedLine2, PrimaryTotal);
                            if AccSchedLine2."Totaling 2" <> '' then begin
                                AccSchedLine2.CopyFilter("Date Filter", GLAcc2."Date Filter");
                                AccSchedLine2.CopyFilter("Business Unit Filter", GLAcc2."Business Unit Filter");
                                AccSchedLine2.CopyFilter("Dimension 1 Filter", GLAcc2."Global Dimension 1 Filter");
                                AccSchedLine2.CopyFilter("Dimension 2 Filter", GLAcc2."Global Dimension 2 Filter");
                                GLAcc2.SetFilter("No.", AccSchedLine2."Totaling 2");
                                GLAcc2.SetRange("Account Type", GLAcc2."Account Type"::Posting);
                                CalcGLAccTotal(GLAcc2, SecondaryTotal, TotalingType::" ");
                            end;
                        end;
                    AccSchedLine2."Totaling Type"::"Total Accounts":
                        begin
                            GLAcc.SetFilter("No.", AccSchedLine2.Totaling);
                            GLAcc.SetFilter("Account Type", '<>%1', GLAcc."Account Type"::Posting);
                            CalcGLAccTotal(GLAcc, PrimaryTotal, TotalingType::" ");
                        end;
                end;
            end;

        exit(true);
    end;

    procedure CalcSchedLineDebitCredit(var GLAcc3: Record "G/L Account"; AccSchedLine2: Record "FR Financial Schedule Line"; var TotalAmount: Decimal)
    begin
        if AccSchedLine2."Totaling Debtor" <> '' then begin
            GLAcc3.SetFilter("No.", AccSchedLine2."Totaling Debtor");
            GLAcc3.SetRange("Account Type", GLAcc3."Account Type"::Posting);
            CalcGLAccTotal(GLAcc3, TotalAmount, TotalingType::Debitor);
        end;
        if AccSchedLine2."Totaling Creditor" <> '' then begin
            GLAcc3.SetFilter("No.", AccSchedLine2."Totaling Creditor");
            GLAcc3.SetRange("Account Type", GLAcc3."Account Type"::Posting);
            CalcGLAccTotal(GLAcc3, TotalAmount, TotalingType::Creditor);
        end;
    end;

    local procedure CalcDateYearBefore(AccScheduleLineDate: Date): Date
    var
        PreviousDate: Date;
    begin
        if AccScheduleLineDate = 0D then
            exit(0D);
        PreviousDate := CalcDate('<-1Y>', NormalDate(AccScheduleLineDate));
        if AccScheduleLineDate <> NormalDate(AccScheduleLineDate) then
            exit(ClosingDate(PreviousDate));
        exit(PreviousDate);
    end;
}
