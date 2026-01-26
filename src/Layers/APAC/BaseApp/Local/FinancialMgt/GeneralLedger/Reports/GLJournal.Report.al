// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using System.Utilities;

report 28160 "G/L Journal"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/GeneralLedger/Reports/GLJournal.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Journal';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Date; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start") where("Period Type" = const(Month));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Period Start";
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GLEntryTableCaptionFilter; "G/L Entry".TableCaption + ': ' + Filter)
            {
            }
            column(FiscalYearStatusText; FiscalYearStatusText)
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
            column(GLJournalCaption; G_L_JournalCaptionLbl)
            {
            }
            column(CodeCaption; CodeCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(DebitCaption; DebitCaptionLbl)
            {
            }
            column(CreditCaption; CreditCaptionLbl)
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
                column(DatePeriodType; Date."Period Type")
                {
                }
                column(DatePeriodYearFormatted; Date."Period Name" + ' ' + Format(Year))
                {
                }
                column(SourceCode_Code; Code)
                {
                }
                dataitem("G/L Entry"; "G/L Entry")
                {
                    DataItemLink = "Source Code" = field(Code);
                    DataItemTableView = sorting("Source Code", "Posting Date");
                    column(SourceCode; SourceCode.Code)
                    {
                    }
                    column(SourceCodeDescription; SourceCode.Description)
                    {
                    }
                    column(DebitAmt_GLEntry; "Debit Amount")
                    {
                    }
                    column(CreditAmt_GLEntry; "Credit Amount")
                    {
                    }
                    column(No_GLEntry; "Entry No.")
                    {
                    }
                    column(DocumentNo_GLEntry; "Document No.")
                    {
                    }
                    column(SourceCode_GLEntry; "Source Code")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        DebitTotal := DebitTotal + "Debit Amount";
                        CreditTotal := CreditTotal + "Credit Amount";
                    end;

                    trigger OnPreDataItem()
                    begin
                        // IF StartDate > Date."Period Start" THEN
                        // Date."Period Start" := StartDate;
                        // IF EndDate < Date."Period End" THEN
                        // Date."Period End" := EndDate;
                        SetRange("Posting Date", Date."Period Start", Date."Period End");
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                Year := Date2DMY("Period End", 3);
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Period Start") = '' then
                    Error(Text001, FieldCaption("Period Start"));
                if CopyStr(GetFilter("Period Start"), 1, 1) = '.' then
                    Error(Text002);
                StartDate := GetRangeMin("Period Start");
                // FiltreDateCalc.VerifMonthPeriod(GETFILTER(Date."Period Start"));
                PreviousEndDate := ClosingDate(StartDate - 1);
                FiltreDateCalc.CreateFiscalYearFilter(TextDate, TextDate, StartDate, 0);
                TextDate := ConvertStr(TextDate, '.', ',');
                // FiltreDateCalc.VerifiyDateFilter(TextDate);
                TextDate := CopyStr(TextDate, 1, 8);
                Evaluate(PreviousStartDate, TextDate);

                // IF COPYSTR(GETFILTER("Period Start"),STRLEN(GETFILTER("Period Start")),1) = '.' THEN
                // EndDate := 0D
                // else
                // EndDate := GETRANGEMAX("Period Start");
                // IF EndDate = StartDate THEN
                // EndDate := FiltreDateCalc.ReturnEndingPeriod(StartDate, Date."Period Type"::Month);
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
        PageCaption = 'Page';
        UserCaption = 'Printed by %1';
    }

    trigger OnPreReport()
    begin
        Filter := Date.GetFilters();
    end;

    var
        FiltreDateCalc: Codeunit "DateFilter-Calc";
        StartDate: Date;
        PreviousStartDate: Date;
        PreviousEndDate: Date;
        TextDate: Text[30];
        DebitTotal: Decimal;
        CreditTotal: Decimal;
        "Filter": Text[250];
        Year: Integer;
        FiscalYearStatusText: Text[80];
        Text001: Label 'You must fill in the %1 field.';
        Text002: Label 'You must specify a Starting Date.';
        G_L_JournalCaptionLbl: Label 'G/L Journal';
        CodeCaptionLbl: Label 'Code';
        DescriptionCaptionLbl: Label 'Description';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        Grand_Total__CaptionLbl: Label 'Grand Total :';
}

