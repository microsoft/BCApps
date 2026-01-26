// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Period;
using System.Utilities;

codeunit 10862 "Fiscal Year-FiscalClose"
{
    TableNo = "Accounting Period";

    trigger OnRun()
    begin
        AccountingPeriod.Copy(Rec);
        Code();
        Rec := AccountingPeriod;
    end;

    var
        Text001: Label 'You must create a new fiscal year before you can fiscally close the old year.';
        Text002: Label 'This function fiscally closes the fiscal year from %1 to %2. ';
        Text003: Label 'Make sure to make a backup of the database before fiscally closing the fiscal year, because once the fiscal year is fiscally closed it cannot be opened again and no G/L entries can be posted anymore on a fiscally closed fiscal year.\\';
        Text004: Label 'Do you want to fiscally close the fiscal year?';
        Text006: Label 'To fiscally close the fiscal year from %1 to %2, you must first post or delete all unposted general journal lines for this fiscal year.\\%3=''%4'',%5=''%6'',%7=''%8''.';
        Text007: Label 'The Income Statement G/L accounts are not balanced at date %1. Please run the batch job Close Income Statement again before fiscally closing the fiscal year from %2 to %3.';
        AccountingPeriod: Record "Accounting Period";
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;
        Text008: Label 'The fiscal year from %1 to %2 must first be closed before it can be fiscally closed.';
        Text009: Label 'Fiscally Closed';
        Text010: Label 'Fiscally Open';

    local procedure "Code"()
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange("Fiscally Closed", false);
        AccountingPeriod.FindFirst();
        // define FY starting and ending date
        FiscalYearStartDate := AccountingPeriod."Starting Date";
        if AccountingPeriod.Find('>') then begin
            FiscalYearEndDate := CalcDate('<-1D>', AccountingPeriod."Starting Date");
            AccountingPeriod.Find('<');
        end else
            Error(Text001);
        // check last period in fiscal year
        AccountingPeriod.SetRange("New Fiscal Year");
        AccountingPeriod.SetRange("Fiscally Closed");
        if AccountingPeriod.Find('<') then
            if not AccountingPeriod."Fiscally Closed" then begin
                FiscalYearEndDate := CalcDate('<-1D>', FiscalYearStartDate);
                AccountingPeriod.SetRange("New Fiscal Year", true);
                AccountingPeriod.SetRange("Fiscally Closed", true);
                AccountingPeriod.FindLast();
                FiscalYearStartDate := AccountingPeriod."Starting Date"
            end else
                AccountingPeriod.Find('>');

        if not AccountingPeriod.Closed then
            Error(Text008, FiscalYearStartDate, FiscalYearEndDate);

        CheckGeneralJournal();
        CheckClosingEntries();

        if not
           Confirm(
             Text002 +
             Text003 +
             Text004, false,
             FiscalYearStartDate, FiscalYearEndDate)
        then
            exit;

        AccountingPeriod.Reset();

        AccountingPeriod.SetRange("Starting Date", FiscalYearStartDate, FiscalYearEndDate);
        AccountingPeriod.SetRange("Fiscally Closed", false);

        AccountingPeriod.ModifyAll("Fiscal Closing Date", Today);
        AccountingPeriod.ModifyAll("Fiscally Closed", true);
#if not CLEAN28
        // update allowed posting range
        AccountingPeriod.UpdateGLSetup(FiscalYearEndDate);
        AccountingPeriod.UpdateUserSetup(FiscalYearEndDate);
#endif

        AccountingPeriod.Reset();
    end;

    [Scope('OnPrem')]
    procedure CheckGeneralJournal()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetFilter("Posting Date", '%1..%2', FiscalYearStartDate, FiscalYearEndDate);
        if GenJnlLine.FindFirst() then
            Error(
              Text006,
              FiscalYearStartDate, FiscalYearEndDate,
              GenJnlLine.FieldCaption("Journal Template Name"), GenJnlLine."Journal Template Name",
              GenJnlLine.FieldCaption("Journal Batch Name"), GenJnlLine."Journal Batch Name",
              GenJnlLine.FieldCaption("Line No."), GenJnlLine."Line No.");
    end;

    [Scope('OnPrem')]
    procedure CheckClosingEntries()
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Date Filter", FiscalYearStartDate, ClosingDate(FiscalYearEndDate));
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
        if GLAccount.Find('-') then
            repeat
                GLAccount.CalcFields("Net Change");
                if GLAccount."Net Change" <> 0 then
                    Error(Text007,
                      ClosingDate(FiscalYearEndDate),
                      FiscalYearStartDate, FiscalYearEndDate);
            until GLAccount.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckFiscalYearStatus(PeriodRange: Text[30]): Text[30]
    var
        AccountingPeriod: Record "Accounting Period";
        Date: Record Date;
    begin
        Date.SetRange("Period Type", Date."Period Type"::Date);
        Date.SetFilter("Period Start", PeriodRange);
        Date.FindLast();
        AccountingPeriod.SetFilter("Starting Date", '<=%1', Date."Period Start");
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.FindLast();
        if AccountingPeriod."Fiscally Closed" then
            exit(Text009);

        exit(Text010);
    end;
}

