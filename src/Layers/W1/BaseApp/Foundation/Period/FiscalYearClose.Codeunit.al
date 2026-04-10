// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

codeunit 6 "Fiscal Year-Close"
{
    TableNo = "Accounting Period";

    trigger OnRun()
    begin
        AccountingPeriod.Copy(Rec);
        Code();
        Rec := AccountingPeriod;
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriod2: Record "Accounting Period";
        AccountingPeriod3: Record "Accounting Period";
        FiscalYearStartDate: Date;
        FiscalYearEndDate: Date;

#pragma warning disable AA0074
        Text001: Label 'You must create a new fiscal year before you can close the old year.';
#pragma warning disable AA0470
        Text002: Label 'This function closes the fiscal year from %1 to %2. ';
#pragma warning restore AA0470
        Text003: Label 'Once the fiscal year is closed it cannot be opened again, and the periods in the fiscal year cannot be changed.\\';
        Text004: Label 'Do you want to close the fiscal year?';
#pragma warning restore AA0074

    local procedure "Code"()
    begin
        AccountingPeriod2.SetRange(Closed, false);
        AccountingPeriod2.Find('-');

        FiscalYearStartDate := AccountingPeriod2."Starting Date";
        AccountingPeriod := AccountingPeriod2;
        AccountingPeriod.TestField("New Fiscal Year", true);

        AccountingPeriod2.SetRange("New Fiscal Year", true);
        if AccountingPeriod2.Find('>') then begin
            FiscalYearEndDate := CalcDate('<-1D>', AccountingPeriod2."Starting Date");

            AccountingPeriod3 := AccountingPeriod2;
            AccountingPeriod2.SetRange("New Fiscal Year");
            AccountingPeriod2.Find('<');
        end else
            Error(Text001);

        if not
            Confirm(
                Text002 +
                Text003 +
                Text004, false,
                FiscalYearStartDate, FiscalYearEndDate)
        then
            exit;

        AccountingPeriod.Reset();

        AccountingPeriod.SetRange("Starting Date", FiscalYearStartDate, AccountingPeriod2."Starting Date");
        AccountingPeriod.ModifyAll(Closed, true);

        AccountingPeriod.SetRange("Starting Date", FiscalYearStartDate, AccountingPeriod3."Starting Date");
        AccountingPeriod.ModifyAll("Date Locked", true);

        AccountingPeriod.Reset();

        OnAfterCode(AccountingPeriod, AccountingPeriod2, AccountingPeriod3);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var AccountingPeriod: Record "Accounting Period"; var AccountingPeriod2: Record "Accounting Period"; var AccountingPeriod3: Record "Accounting Period")
    begin
    end;
}

