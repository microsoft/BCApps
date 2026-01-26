// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 10813 "Customer Journal"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Reports/CustomerJournal.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Journal';
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
            column(STRSUBSTNO_Text006_USERID_; StrSubstNo(Text006, UserId))
            {
            }
            column(STRSUBSTNO_Text007____; StrSubstNo(Text007, ''))
            {
            }
            column(UserCaption; StrSubstNo(Text006, ''))
            {
            }
            column(Cust__Ledger_Entry__TABLECAPTION__________Filter; "Cust. Ledger Entry".TableCaption + ': ' + Filter)
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
            column(Customer_JournalCaption; Customer_JournalCaptionLbl)
            {
            }
            column(Posting_DateCaption; Posting_DateCaptionLbl)
            {
            }
            column(Document_No_Caption; Document_No_CaptionLbl)
            {
            }
            column(Customer_No_Caption; Customer_No_CaptionLbl)
            {
            }
            column(Due_DateCaption; Due_DateCaptionLbl)
            {
            }
            column(Pmt__Discount_DateCaption; Pmt__Discount_DateCaptionLbl)
            {
            }
            column(Pmt__Disc__Given__LCY_Caption; Pmt__Disc__Given__LCY_CaptionLbl)
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
                column(Date__Period_Name____YearString; Date."Period Name" + YearString)
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
                dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
                {
                    DataItemLink = "Source Code" = field(Code);
                    DataItemTableView = sorting("Source Code", "Posting Date");
                    column(SourceCode2_Code; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2_Description; SourceCode2.Description)
                    {
                    }
                    column(Cust__Ledger_Entry__Debit_Amount__LCY__; "Debit Amount (LCY)")
                    {
                    }
                    column(Cust__Ledger_Entry__Credit_Amount__LCY__; "Credit Amount (LCY)")
                    {
                    }
                    column(Cust__Ledger_Entry__Posting_Date_; Format("Posting Date"))
                    {
                    }
                    column(Cust__Ledger_Entry__Document_No__; "Document No.")
                    {
                    }
                    column(Cust__Ledger_Entry__Customer_No__; "Customer No.")
                    {
                    }
                    column(Cust__Ledger_Entry__Due_Date_; Format("Due Date"))
                    {
                    }
                    column(Cust__Ledger_Entry__Pmt__Discount_Date_; Format("Pmt. Discount Date"))
                    {
                    }
                    column(Cust__Ledger_Entry__Pmt__Disc__Given__LCY__; "Pmt. Disc. Given (LCY)")
                    {
                    }
                    column(Cust__Ledger_Entry_Description; Description)
                    {
                    }
                    column(Cust__Ledger_Entry__Currency_Code_; "Currency Code")
                    {
                    }
                    column(Cust__Ledger_Entry__Debit_Amount_; "Debit Amount")
                    {
                    }
                    column(Cust__Ledger_Entry__Credit_Amount_; "Credit Amount")
                    {
                    }
                    column(Cust__Ledger_Entry__Debit_Amount__LCY___Control1120096; "Debit Amount (LCY)")
                    {
                    }
                    column(Cust__Ledger_Entry__Credit_Amount__LCY___Control1120099; "Credit Amount (LCY)")
                    {
                    }
                    column(SourceCode2_Code_Control1120101; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2_Description_Control1120103; SourceCode2.Description)
                    {
                    }
                    column(Cust__Ledger_Entry__Debit_Amount__LCY___Control1120107; "Debit Amount (LCY)")
                    {
                    }
                    column(Cust__Ledger_Entry__Credit_Amount__LCY___Control1120109; "Credit Amount (LCY)")
                    {
                    }
                    column(SourceCode2_Code_Control1120111; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2_Description_Control1120113; SourceCode2.Description)
                    {
                    }
                    column(Cust__Ledger_Entry__Debit_Amount__LCY___Control1120117; "Debit Amount (LCY)")
                    {
                    }
                    column(Cust__Ledger_Entry__Credit_Amount__LCY___Control1120119; "Credit Amount (LCY)")
                    {
                    }
                    column(Cust__Ledger_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(Cust__Ledger_Entry_Source_Code; "Source Code")
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }
                    column(TotalCaption_Control1120105; TotalCaption_Control1120105Lbl)
                    {
                    }
                    column(TotalCaption_Control1120115; TotalCaption_Control1120115Lbl)
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
                YearString := '';
                if Date."Period Type" <> Date."Period Type"::Year then begin
                    Year := Date2DMY("Period End", 3);
                    YearString := ' ' + Format(Year);
                end;
                if Finished then
                    CurrReport.Break();
                DateRecNo += 1;
            end;

            trigger OnPreDataItem()
            var
                Period: Record Date;
            begin
                if GetFilter("Period Type") = '' then
                    Error(Text004, FieldCaption("Period Type"));
                if GetFilter("Period Start") = '' then
                    Error(Text004, FieldCaption("Period Start"));
                if CopyStr(GetFilter("Period Start"), 1, 1) = '.' then
                    Error(Text005);
                StartDate := GetRangeMin("Period Start");
                CopyFilter("Period Type", Period."Period Type");
                Period.SetRange("Period Start", StartDate);
                if not Period.FindFirst() then
                    Error(Text008, StartDate, GetFilter("Period Type"));
                FiltreDateCalc.CreateFiscalYearFilter(TextDate, TextDate, StartDate, 0);
                TextDate := ConvertStr(TextDate, '.', ',');
                FiltreDateCalc.VerifiyDateFilter(TextDate);
                TextDate := CopyStr(TextDate, 1, 8);
                Evaluate(PreviousStartDate, TextDate);
                if CopyStr(GetFilter("Period Start"), StrLen(GetFilter("Period Start")), 1) = '.' then
                    EndDate := 0D
                else
                    EndDate := GetRangeMax("Period Start");
                if EndDate = StartDate then
                    EndDate := FiltreDateCalc.ReturnEndingPeriod(StartDate, Date.GetRangeMin("Period Type"));
                Clear(Period);
                CopyFilter("Period Type", Period."Period Type");
                Period.SetRange("Period End", ClosingDate(EndDate));
                if not Period.FindFirst() then
                    Error(Text009, EndDate, GetFilter("Period Type"));
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
        Text004: Label 'You must fill in the %1 field.';
        Text005: Label 'You must specify a Starting Date.';
        Text006: Label 'Printed by %1';
        Text007: Label 'Page %1';
        SourceCode2: Record "Source Code";
        FiltreDateCalc: Codeunit "DateFilter-Calc";
        StartDate: Date;
        EndDate: Date;
        PreviousStartDate: Date;
        TextDate: Text;
        DebitTotal: Decimal;
        CreditTotal: Decimal;
        Filter2: Text;
        SortingBy: Option "Posting Date","Document No.";
        "Filter": Text;
        Text008: Label 'The selected starting date %1 is not the start of a %2.';
        Text009: Label 'The selected ending date %1 is not the end of a %2.';
        Year: Integer;
        YearString: Text;
        Finished: Boolean;
        PeriodTypeNo: Integer;
        DateRecNo: Integer;
        Customer_JournalCaptionLbl: Label 'Customer Journal';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Document_No_CaptionLbl: Label 'Document No.';
        Customer_No_CaptionLbl: Label 'Customer No.';
        Due_DateCaptionLbl: Label 'Due Date';
        Pmt__Discount_DateCaptionLbl: Label 'Pmt. Discount Date';
        Pmt__Disc__Given__LCY_CaptionLbl: Label 'Pmt. Disc. Given (LCY)';
        DescriptionCaptionLbl: Label 'Description';
        Currency_CodeCaptionLbl: Label 'Currency Code';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        Debit__LCY_CaptionLbl: Label 'Debit (LCY)';
        Credit__LCY_CaptionLbl: Label 'Credit (LCY)';
        Grand_Total__CaptionLbl: Label 'Grand Total :';
        TotalCaptionLbl: Label 'Total';
        TotalCaption_Control1120105Lbl: Label 'Total';
        TotalCaption_Control1120115Lbl: Label 'Total';
}

