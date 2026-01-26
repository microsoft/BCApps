// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.Payables;
using System.Utilities;

report 10814 "Vendor Journal"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Reports/VendorJournal.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor Journal';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Date; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Period Type", "Period Start";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column("Page"; StrSubstNo(Text007, ''))
            {
            }
            column(PrintedBy; StrSubstNo(Text006, ''))
            {
            }
            column(VendLedgEntryTableCaptionFilter; "Vendor Ledger Entry".TableCaption + ': ' + Filter)
            {
            }
            column("Filter"; Filter)
            {
            }
            column(SourceCodeTableCaptionFilter2; SourceCode.TableCaption + ': ' + Filter2)
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
            column(PeriodType_Date; "Period Type")
            {
            }
            column(PeriodStart_Date; "Period Start")
            {
            }
            column(VendorJnlCaption; VendorJnlCaptionLbl)
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DocNoCaption; DocNoCaptionLbl)
            {
            }
            column(VendorNoCaption; VendorNoCaptionLbl)
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(PmtDiscDateCaption; PmtDiscDateCaptionLbl)
            {
            }
            column(PmtDiscRcdLCYCaption; PmtDiscRcdLCYCaptionLbl)
            {
            }
            column(DescCaption; DescCaptionLbl)
            {
            }
            column(CurrCodeCaption; CurrCodeCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
            {
            }
            column(DebitLCYCaption; DebitLCYCaptionLbl)
            {
            }
            column(CreditLCYCaption; CreditLCYCaptionLbl)
            {
            }
            column(GrandTotalCaption; GrandTotalCaptionLbl)
            {
            }
            dataitem(SourceCode; "Source Code")
            {
                DataItemTableView = sorting(Code);
                PrintOnlyIfDetail = true;
                RequestFilterFields = "Code";
                column(DatePeriodType; Date."Period Type")
                {
                }
                column(DatePeriodNameYearString; Date."Period Name" + YearString)
                {
                }
                column(DateRecNo; DateRecNo)
                {
                }
                column(Code_SourceCode; Code)
                {
                }
                column(Desc_SourceCode; Description)
                {
                }
                column(PeriodTypeNo; PeriodTypeNo)
                {
                }
                dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
                {
                    DataItemLink = "Source Code" = field(Code);
                    DataItemTableView = sorting("Source Code", "Posting Date");
                    column(SourceCode2Code; SourceCode2.Code)
                    {
                    }
                    column(SourceCode2Desc; SourceCode2.Description)
                    {
                    }
                    column(DebitAmtLCY_VendLedgEntry; "Debit Amount (LCY)")
                    {
                    }
                    column(CreditAmtLCY_VendLedgEntry; "Credit Amount (LCY)")
                    {
                    }
                    column(PostingDateFormatted_VendLedgEntry; Format("Posting Date"))
                    {
                    }
                    column(DocNo_VendLedgEntry; "Document No.")
                    {
                    }
                    column(VendorNo_VendLedgEntry; "Vendor No.")
                    {
                    }
                    column(DueDateFormatted_VendLedgEntry; Format("Due Date"))
                    {
                    }
                    column(PmtDiscountDateFormatted_VendLedgEntry; Format("Pmt. Discount Date"))
                    {
                    }
                    column(PmtDiscRcdLCY_VendLedgEntry; "Pmt. Disc. Rcd.(LCY)")
                    {
                    }
                    column(Desc_VendLedgEntry; Description)
                    {
                    }
                    column(CurrCode_VendLedgEntry; "Currency Code")
                    {
                    }
                    column(DebitAmt_VendLedgEntry; "Debit Amount")
                    {
                    }
                    column(CreditAmt_VendLedgEntry; "Credit Amount")
                    {
                    }
                    column(EntryNo_VendLedgEntry; "Entry No.")
                    {
                    }
                    column(SourceCode_VendLedgEntry; "Source Code")
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
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
        VendorJnlCaptionLbl: Label 'Vendor Journal';
        PostingDateCaptionLbl: Label 'Posting Date';
        DocNoCaptionLbl: Label 'Document No.';
        VendorNoCaptionLbl: Label 'Vendor No.';
        DueDateCaptionLbl: Label 'Due Date';
        PmtDiscDateCaptionLbl: Label 'Pmt. Discount Date';
        PmtDiscRcdLCYCaptionLbl: Label 'Pmt. Disc. Rcd.(LCY)';
        DescCaptionLbl: Label 'Description';
        CurrCodeCaptionLbl: Label 'Currency Code';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        DebitLCYCaptionLbl: Label 'Debit (LCY)';
        CreditLCYCaptionLbl: Label 'Credit (LCY)';
        GrandTotalCaptionLbl: Label 'Grand Total :';
        TotalCaptionLbl: Label 'Total';
}

