// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.GeneralLedger.Account;

report 10811 "FR Account Schedule"
{
    ApplicationArea = Basic, Suite;
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/FinancialReports/FRAccountSchedule.rdlc';
    Caption = 'FR Account Schedule';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("FR Acc. Schedule Name"; "FR Acc. Schedule Name")
        {
            DataItemTableView = sorting(Name);
            RequestFilterFields = Name;
            column(FR_Acc__Schedule_Name_Name; Name)
            {
            }
            dataitem("FR Acc. Schedule Line"; "FR Acc. Schedule Line")
            {
                DataItemLink = "Schedule Name" = field(Name);
                DataItemTableView = sorting("Schedule Name", "Line No.");
                RequestFilterFields = "Date Filter", "Dimension 1 Filter", "Dimension 2 Filter", "Date Filter 2";
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(Text10801___PeriodText; Text10801 + PeriodText)
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
                PageGroupNo := 1;
                NextPageGroupNo := 1;
            end;
        }
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
    begin
        AccSchedLineFilter := "FR Acc. Schedule Line".GetFilters();
        PeriodText := "FR Acc. Schedule Line".GetFilter("Date Filter");
        if "FR Acc. Schedule Line".GetFilter("Date Filter 2") = '' then
            if Format("FR Acc. Schedule Line".GetFilter("Date Filter"), 1) = '.' then
                "FR Acc. Schedule Line".SetFilter(
                  "Date Filter 2", '..' + Format(CalcDateYearBefore("FR Acc. Schedule Line".GetRangeMax("Date Filter"))))
            else
                "FR Acc. Schedule Line".SetFilter(
                  "Date Filter 2", Format(CalcDateYearBefore("FR Acc. Schedule Line".GetRangeMin("Date Filter"))) + '..' +
                  Format(CalcDateYearBefore("FR Acc. Schedule Line".GetRangeMax("Date Filter"))));
        PeriodText2 := "FR Acc. Schedule Line".GetFilter("Date Filter 2");
    end;

    var
        Text10801: Label 'Period: ';
        GLAcc: Record "G/L Account";
        GLAcc2: Record "G/L Account";
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

    local procedure CalcGLAccTotal(var GLAccount: Record "G/L Account"; var TotalAmount: Decimal; TotalingType: Option " ",Debitor,Creditor)
    begin
        if GLAccount.Find('-') then
            repeat
                GLAccount.CalcFields("Net Change");
                if (TotalingType = TotalingType::" ") or
                   ((TotalingType = TotalingType::Debitor) and (GLAccount."Net Change" > 0)) or
                   ((TotalingType = TotalingType::Creditor) and (GLAccount."Net Change" < 0))
                then
                    TotalAmount := TotalAmount + GLAccount."Net Change";
            until GLAccount.Next() = 0;
    end;

    local procedure CalcSchedLineTotal(AccSchedLine2: Record "FR Acc. Schedule Line"; Level: Integer; var TotalNetChange: Decimal; var TotalNetChange2: Decimal): Boolean
    var
        RowNo: array[6] of Code[10];
        ErrorText: Text;
        i: Integer;
    begin
        if AccSchedLine2.Totaling <> '' then
            if AccSchedLine2."Totaling Type" = AccSchedLine2."Totaling Type"::Rows then begin
                if Level >= ArrayLen(RowNo) then
                    exit(false);
                Level := Level + 1;
                RowNo[Level] := AccSchedLine2."Row No.";
                AccSchedLine2.SetRange("Schedule Name", AccSchedLine2."Schedule Name");
                AccSchedLine2.SetFilter("Row No.", AccSchedLine2.Totaling);
                if AccSchedLine2.Find('-') then
                    repeat
                        if not CalcSchedLineTotal(AccSchedLine2, Level, TotalNetChange, TotalNetChange2) then begin
                            if Level > 1 then
                                exit(false);
                            for i := 1 to ArrayLen(RowNo) do
                                ErrorText := ErrorText + RowNo[i] + ' => ';
                            ErrorText := ErrorText + '...';
                            AccSchedLine2.FieldError("Row No.", ErrorText);
                        end;
                    until AccSchedLine2.Next() = 0;
            end else begin
                "FR Acc. Schedule Line".CopyFilter("Date Filter", GLAcc."Date Filter");
                "FR Acc. Schedule Line".CopyFilter("Business Unit Filter", GLAcc."Business Unit Filter");
                "FR Acc. Schedule Line".CopyFilter("Dimension 1 Filter", GLAcc."Global Dimension 1 Filter");
                "FR Acc. Schedule Line".CopyFilter("Dimension 2 Filter", GLAcc."Global Dimension 2 Filter");
                case AccSchedLine2."Totaling Type" of
                    AccSchedLine2."Totaling Type"::"Posting Accounts":
                        begin
                            GLAcc.SetFilter("No.", AccSchedLine2.Totaling);
                            GLAcc.SetRange("Account Type", GLAcc."Account Type"::Posting);
                            CalcGLAccTotal(GLAcc, TotalNetChange, TotalingType::" ");
                            CalcSchedLineDebitCredit(GLAcc, AccSchedLine2, TotalNetChange);
                            if AccSchedLine2."Totaling 2" <> '' then begin
                                "FR Acc. Schedule Line".CopyFilter("Date Filter", GLAcc2."Date Filter");
                                "FR Acc. Schedule Line".CopyFilter("Business Unit Filter", GLAcc2."Business Unit Filter");
                                "FR Acc. Schedule Line".CopyFilter("Dimension 1 Filter", GLAcc2."Global Dimension 1 Filter");
                                "FR Acc. Schedule Line".CopyFilter("Dimension 2 Filter", GLAcc2."Global Dimension 2 Filter");
                                GLAcc2.SetFilter("No.", AccSchedLine2."Totaling 2");
                                GLAcc2.SetRange("Account Type", GLAcc2."Account Type"::Posting);
                                CalcGLAccTotal(GLAcc2, TotalNetChange2, TotalingType::" ");
                            end;
                        end;
                    AccSchedLine2."Totaling Type"::"Total Accounts":
                        begin
                            GLAcc.SetFilter("No.", AccSchedLine2.Totaling);
                            GLAcc.SetFilter("Account Type", '<>%1', GLAcc."Account Type"::Posting);
                            CalcGLAccTotal(GLAcc, TotalNetChange, TotalingType::" ");
                        end;
                end;
            end;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CalcSchedLineDebitCredit(var GLAcc3: Record "G/L Account"; AccSchedLine2: Record "FR Acc. Schedule Line"; var TotalAmount: Decimal)
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
    begin
        exit(CalcDate('<-1Y>', AccScheduleLineDate));
    end;
}

