// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Reminder;
using System.Reflection;
using System.Threading;

permissionset 8125 "Report Filename Mgr."
{
    // For administrators who manage patterns and setup. Other users do not need it: naming reads
    // patterns and setup under inherent permissions (Report Filename Mgt.TryResolve).

    Assignable = true;
    Caption = 'Report Filename Manager', MaxLength = 30;

    Permissions =
        tabledata "Report Filename Pattern" = RIMD,
        table "Report Filename Pattern" = X,
        tabledata "Report Filename Setup" = RIMD,
        table "Report Filename Setup" = X,
        tabledata "Report Filename Plh. Buffer" = RIMD,
        table "Report Filename Plh. Buffer" = X,
        tabledata "Report Filename Table Buffer" = RIMD,
        table "Report Filename Table Buffer" = X,
        tabledata "Report Filename Record Buffer" = RIMD,
        table "Report Filename Record Buffer" = X,
        tabledata "Report Filename Route Buffer" = RIMD,
        table "Report Filename Route Buffer" = X,
        tabledata "Report Data Items" = R,
        tabledata "Report Metadata" = R,
        tabledata Field = R,
        tabledata "Table Metadata" = R,
        tabledata "Company Information" = R,
        tabledata "Report Selections" = R,
        // Decimal places when an amount placeholder is formatted in the document's currency.
        tabledata Currency = R,
        // Decimal places for amounts in local currency.
        tabledata "General Ledger Setup" = R,
        // The one document whose total the total placeholder computes (CalculateTotalIncludingVAT)
        // rather than reads from a field. Related tables a placeholder reads are not listed: they
        // are read with the producing user's permissions.
        tabledata "Issued Reminder Header" = R,
        // The scheduled route stores the name on the Report Inbox row after Base Application inserts
        // it, and at download reads it and marks the row read.
        tabledata "Report Inbox" = RIM,
        // Read by Issued Reminder Header.CalculateTotalIncludingVAT.
        tabledata "Issued Reminder Line" = R,
        // Read to tell whether Reminder Communication names a reminder from its attachment text,
        // when naming and in Test Pattern (Report Filename Mgt.IsNamedByReminderCommunication).
        tabledata "Reminder Level" = R,
        tabledata "Reminder Terms" = R,
        tabledata "Reminder Attachment Text" = R,
        tabledata Customer = R,
        tabledata "Job Queue Entry" = R,
        codeunit "Report Filename Mgt." = X,
        codeunit "Report Filename Subscribers" = X,
        codeunit "Report Filename Context" = X,
        codeunit "Report Filename Preview Mgt." = X,
        codeunit "Report Filename Plh. Mgt." = X,
        codeunit "Report Filename Company Plh." = X,
        codeunit "Report Filename Created Plh." = X,
        codeunit "Report Filename User Plh." = X,
        codeunit "Report Filename Report Plh." = X,
        codeunit "Report Filename Total Plh." = X,
        codeunit "Report Filename Doc. Kind Plh." = X,
        codeunit "Report Filename Period Plh." = X,
        codeunit "Report Filename Inbox Mgt." = X,
        codeunit "Report Filename Inbox Sub." = X,
        // Subscribers use SkipOnMissingPermission = false, so without this printing a financial
        // report fails instead of skipping the naming.
        codeunit "Report Filename Fin. Rep. Sub." = X,
        codeunit "Report Filename Guided Exp." = X,
        page "Report Filename Patterns" = X,
        page "Report Filename Setup" = X,
        page "Report Filename Pattern Card" = X,
        page "Report Filename Preview" = X,
        page "Report Filename Placeholders" = X,
        page "Report Filename Report Lookup" = X,
        page "Report Filename Table Lookup" = X,
        page "Report Filename Field Lookup" = X,
        page "Report Filename Routes" = X,
        page "Report Filename Test" = X,
        page "Report Filename Record Lookup" = X;
}
