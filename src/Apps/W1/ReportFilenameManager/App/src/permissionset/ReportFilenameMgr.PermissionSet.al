// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
permissionset 50110 "Report Filename Mgr."
{
    // For the people who manage file names: create and change patterns, turn the feature on or
    // off, and set the maximum file name length.
    //
    // Nobody else needs it. Every user who prints, emails or sends a report runs this feature's
    // naming, and that code reads the patterns and the setup under inherent permissions of its own
    // (Report Filename Mgt.TryResolve) - so an ordinary user is named by a pattern without holding
    // this set and without being able to open or change a pattern.
    //
    // This stays in the shipped app, as the app's own assignable set for the objects it ships.
    //
    // The metadata tables are listed because setting a pattern up reads them to work out what a
    // report is about and which fields it can be named from.

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
        // Read by Auto Format when an amount placeholder is formatted with the document's currency.
        tabledata Currency = R,
        // The company's decimal places, used when a document is in local currency.
        tabledata "General Ledger Setup" = R,
        // The one document type whose total including VAT Base Application computes rather
        // than stores. A placeholder that reaches one relation away reads whatever table the
        // document points at, which cannot be listed here: those reads happen under the
        // permissions of whoever is producing the file, and a placeholder the user cannot read
        // makes the pattern decline, leaving the file with the name it would have had.
        tabledata "Issued Reminder Header" = R,
        // The scheduled route inserts the Report Inbox row itself, carrying the name it
        // resolved, and reads it back when the entry is downloaded.
        tabledata "Report Inbox" = RIM,
        // Read by CalculateTotalIncludingVAT on the Total Incl. VAT path, and by the scheduled
        // route when it asks the job queue entry what the report was scheduled with.
        tabledata "Issued Reminder Line" = R,
        // Whether Base Application names a reminder itself, from its attachment text, which Test
        // Pattern reports: the level, the terms, the text, and the customer for its language.
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
        // Every subscriber in this app is declared with SkipOnMissingPermission = false, which
        // raises an error rather than skipping the call. A user who may print a financial report
        // but cannot execute this codeunit would therefore get an error out of Base Application's
        // own print action - so leaving it out does not degrade the feature, it breaks printing.
        codeunit "Report Filename Fin. Rep. Sub." = X,
        codeunit "Report Filename Guided Exp." = X,
        page "Report Filename Patterns" = X,
        page "Report Filename Setup" = X,
        page "Report Filename Pattern Card" = X,
        page "Report Filename Preview" = X,
        page "Report Filename Placeholders" = X,
        // The four lookups the pattern card opens. Without these a non-SUPER administrator
        // cannot set the report, the table, the language field or the output routes at all -
        // which is everything on the card that is chosen rather than typed.
        page "Report Filename Report Lookup" = X,
        page "Report Filename Table Lookup" = X,
        page "Report Filename Field Lookup" = X,
        page "Report Filename Routes" = X,
        // Test Pattern and the fallback record picker it opens. Both were added after this set
        // was first written and were missing from it, so Test Pattern could not be opened at all
        // by anyone who was not SUPER.
        page "Report Filename Test" = X,
        page "Report Filename Record Lookup" = X;
}
