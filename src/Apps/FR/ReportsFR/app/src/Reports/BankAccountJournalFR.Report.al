// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using System.Utilities;

report 10826 "Bank Account Journal FR"
{
    DefaultLayout = RDLC;
    RDLCLayout = './src/Reports/BankAccountJournalFR.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account Journal';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Date; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Period Type", "Period Start";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text006_USERID_; StrSubstNo(Text006Lbl, UserId))
            {
            }
            column(STRSUBSTNO_Text007____; StrSubstNo(Text007Lbl, ''))
            {
            }
            column(STRSUBSTNO_Text006____; StrSubstNo(Text006Lbl, ''))
            {
            }
            column(Bank_Account_Ledger_Entry__TABLECAPTION__________Filter; "Bank Account Ledger Entry".TableCaption + ': ' + Filter)
            {
            }
            column("Filter"; Filter)
            {
            }
            column(SourceCode_TABLECAPTION__________Filter2; SourceCode.TableCaption + ': ' + Filter2)
            {
            }
            column(Filter2; Filter2)
            {
            }
            column(DebitTotal; DebitTotal)
            {
            }
            column(CreditTotal; CreditTotal)
            {
            }
            column(Date_Period_Type; "Period Type")
            {
            }
            column(Date_Period_Start; "Period Start")
            {
            }
            column(Bank_Account_JournalCaption; Bank_Account_JournalCaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(Bank_Account_No_Caption; Bank_Account_No_CaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Currency_CodeCaption; Currency_CodeCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(Debit__LCY_Caption; Debit__LCY_CaptionLbl)
            {
            }
            column(Credit__LCY_Caption; Credit__LCY_CaptionLbl)
            {
            }
            column(Grand_Total__Caption; Grand_Total__CaptionLbl)
            {
            }
            dataitem(SourceCode; "Source Code")
            {
                DataItemTableView = sorting(Code);
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Code";
                column(Date__Period_Type_; Date."Period Type")
                {
                }
                column(Date__Period_Name_; Date."Period Name")
                {
                }
                column(DateRecNo; DateRecNo)
                {
                }
                column(SourceCode_Code; Code)
                {
                }
                column(SourceCode_Description; Description)
                {
                }
                column(PeriodTypeNo; PeriodTypeNo)
                {
                }
                dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
                {
                    DataItemLink = "Source Code" = field(Code);
                    DataItemTableView = sorting("Source Code", "Posting Date");
                    column(SourceCode2_Code; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2_Description; SourceCode2.Description)
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Debit_Amount__LCY__; "Debit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Credit_Amount__LCY__; "Credit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Bank_Account_No__; "Bank Account No.")
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Description; Description)
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Currency_Code_; "Currency Code")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Debit_Amount_; "Debit Amount")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Credit_Amount_; "Credit Amount")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Debit_Amount__LCY___Control1120081; "Debit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Credit_Amount__LCY___Control1120084; "Credit Amount (LCY)")
                    {
                    }
                    column(SourceCode2_Code_Control1120086; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2_Description_Control1120088; SourceCode2.Description)
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Debit_Amount__LCY___Control1120092; "Debit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Credit_Amount__LCY___Control1120094; "Credit Amount (LCY)")
                    {
                    }
                    column(SourceCode2_Code_Control1120096; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2_Description_Control1120098; SourceCode2.Description)
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Debit_Amount__LCY___Control1120102; "Debit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry__Credit_Amount__LCY___Control1120104; "Credit Amount (LCY)")
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Bank_Account_Ledger_Entry_Source_Code; "Source Code")
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }
                    column(TotalCaption_Control1120090; TotalCaption_Control1120090Lbl)
                    {
                    }
                    column(TotalCaption_Control1120100; TotalCaption_Control1120100Lbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        DebitTotal := DebitTotal + "Debit Amount (LCY)";
                        CreditTotal := CreditTotal + "Credit Amount (LCY)";
                    end;

                    trigger OnPostDataItem()
                    begin
                        if Date."Period Type" = Date."Period Type"::Date then
                            Finished := true;
                    end;

                    trigger OnPreDataItem()
                    begin
                        case SortingBy of
                            SortingBy::"Posting Date":
                                SetCurrentKey("Source Code", "Posting Date", "Document No.");
                            SortingBy::"Document No.":
                                SetCurrentKey("Source Code", "Document No.", "Posting Date");
                        end;

                        if StartDate > Date."Period Start" then
                            Date."Period Start" := StartDate;
                        if EndDate < Date."Period End" then
                            Date."Period End" := EndDate;
                        if Date."Period Type" <> Date."Period Type"::Date then
                            SetRange("Posting Date", Date."Period Start", Date."Period End")
                        else
                            SetRange("Posting Date", StartDate, EndDate);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    SourceCode2 := SourceCode;
                    PeriodTypeNo := Date."Period Type";
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Finished then
                    CurrReport.Break();
                DateRecNo += 1;
            end;

            trigger OnPreDataItem()
            var
                Period: Record Date;
            begin
                if GetFilter("Period Type") = '' then
                    Error(Text004Lbl, FieldCaption("Period Type"));
                if GetFilter("Period Start") = '' then
                    Error(Text004Lbl, FieldCaption("Period Start"));
                if CopyStr(GetFilter("Period Start"), 1, 1) = '.' then
                    Error(Text005Lbl);
                StartDate := GetRangeMin("Period Start");
                CopyFilter("Period Type", Period."Period Type");
                Period.SetRange("Period Start", StartDate);
                if not Period.FindFirst() then
                    Error(Text008Lbl, StartDate, GetFilter("Period Type"));
                FiltreDateCalc.CreateFiscalYearFilter(TextDate, TextDate, StartDate, 0);
                TextDate := ConvertStr(TextDate, '.', ',');
                FiltreDateCalc.VerifiyDateFilter(TextDate);
                TextDate := CopyStr(TextDate, 1, 8);
                if CopyStr(GetFilter("Period Start"), StrLen(GetFilter("Period Start")), 1) = '.' then
                    EndDate := 0D
                else
                    EndDate := GetRangeMax("Period Start");
                if EndDate = StartDate then
                    EndDate := FiltreDateCalc.ReturnEndingPeriod(StartDate, Date.GetRangeMin("Period Type"));
                Clear(Period);
                CopyFilter("Period Type", Period."Period Type");
                Period.SetRange("Period End", ClosingDate(EndDate));
#pragma warning disable AA0175
                if not Period.FindFirst() then
#pragma warning restore AA0175
                    Error(Text009Lbl, EndDate, GetFilter("Period Type"));
                DateRecNo := 0;
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
                    field("Posting Date"; SortingBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorted by';
                        OptionCaption = 'Posting Date,Document No.';
                        ToolTip = 'Specifies criteria for arranging information in the report.';
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
    begin
        Filter := Date.GetFilters();
        Filter2 := SourceCode.GetFilters();
    end;

    var
        SourceCode2: Record "Source Code";
        FiltreDateCalc: Codeunit "DateFilter-Calc";
        StartDate: Date;
        EndDate: Date;
        TextDate: Text[30];
        DebitTotal: Decimal;
        CreditTotal: Decimal;
        Filter2: Text;
        SortingBy: Option "Posting Date","Document No.";
        "Filter": Text;
        Text004Lbl: Label 'You must fill in the %1 field.', Comment = '%1 = Period';
        Text005Lbl: Label 'You must specify a Starting Date.';
        Text006Lbl: Label 'Printed by %1', Comment = '%1 = User ID';
        Text007Lbl: Label 'Page %1', Comment = '%1 = Page';
        Text008Lbl: Label 'The selected starting date %1 is not the start of a %2.', Comment = '%1 = Start Date, %2 = Period Type';
        Text009Lbl: Label 'The selected ending date %1 is not the end of a %2.', Comment = '%1 = End Date, %2 = Period Type';
        Finished: Boolean;
        PeriodTypeNo: Integer;
        DateRecNo: Integer;
        Bank_Account_JournalCaptionLbl: Label 'Bank Account Journal';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Document_No_CaptionLbl: Label 'Document No.';
        Bank_Account_No_CaptionLbl: Label 'Bank Account No.';
        DescriptionCaptionLbl: Label 'Description';
        Currency_CodeCaptionLbl: Label 'Currency Code';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        Debit__LCY_CaptionLbl: Label 'Debit (LCY)';
        Credit__LCY_CaptionLbl: Label 'Credit (LCY)';
        Grand_Total__CaptionLbl: Label 'Grand Total :';
        TotalCaptionLbl: Label 'Total';
        TotalCaption_Control1120090Lbl: Label 'Total';
        TotalCaption_Control1120100Lbl: Label 'Total';
}
