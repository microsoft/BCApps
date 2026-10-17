// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
interface "Report Filename Placeholder"
{
    // One implementation per computed value. Section 5 of the design specifies this as the
    // extension point: adding a value an administrator can put in a pattern is an enum
    // extension plus one codeunit, with no change to the manager, the table or the pages.
    //
    // Two names, and both are needed. CanonicalName is what the pattern's binding records, so
    // it must never change with language or the stored binding would stop resolving.
    // DisplayName is what Available Placeholders offers and what an administrator may type, so it is
    // translated - a pattern has to be authorable in the language it is read in.

    /// <summary>
    /// The language-invariant name recorded in a pattern's binding. Never translated.
    /// </summary>
    /// <returns>The canonical name.</returns>
    procedure CanonicalName(): Text;

    /// <summary>
    /// The name shown in Available Placeholders and accepted when a pattern is written.
    /// </summary>
    /// <returns>The name in the current language.</returns>
    procedure DisplayName(): Text;

    /// <summary>
    /// What the value is derived from, in the words of somebody setting the pattern up.
    /// </summary>
    /// <returns>A short description.</returns>
    procedure Description(): Text;

    /// <summary>
    /// Whether this value can be worked out for a pattern on the given table.
    /// Available Placeholders asks before offering the placeholder, so an administrator is never handed a value
    /// that would decline the moment it was used: [Total Incl. VAT] means nothing on a
    /// customer or an item, and offering it there made the picker's own promise false.
    /// </summary>
    /// <param name="TableNo">The table the pattern applies to, or zero when the pattern is tied to no table at all.</param>
    /// <returns>True when the value could be worked out for that table.</returns>
    procedure IsTableSupported(TableNo: Integer): Boolean;

    /// <summary>
    /// Whether this value still means something when the run covers more than one record.
    ///
    /// A run produces one file however many records it covered, so every value in its name has
    /// to be true of the whole run. The company, the user, the date the file was made and the
    /// report's own caption are one value however many records were printed. A document total
    /// is not: three invoices have three totals and no one of them is the run's, so a pattern
    /// using it declines rather than putting one invoice's figure on a file holding three.
    ///
    /// The picker asks so that it can say what becomes of the value, rather than offering it
    /// and letting the administrator find out when a report runs.
    ///
    /// Adding this to the interface breaks any partner implementation that does not declare it.
    /// That cost is accepted: a placeholder that cannot say whether it speaks for a run of many is a
    /// placeholder this design cannot describe honestly, and leaving it undeclared would mean guessing
    /// on the partner's behalf.
    /// </summary>
    /// <returns>True when the value is one value for the whole run.</returns>
    procedure SpeaksForARunOfManyRecords(): Boolean;

    /// <summary>
    /// The shape this value takes, for a placeholder whose real value cannot be worked out without a
    /// document. The picker resolves a computed value for real where it can - the company name
    /// and today's date need no document - and falls back to this where it cannot, so the
    /// Example column is complete instead of blank on the one row that needs a document.
    ///
    /// A shape, never a plausible-looking figure off a real record: that is the whole point of
    /// not reading one.
    /// </summary>
    /// <returns>An example of the form the value takes, or blank when the value always resolves.</returns>
    procedure ExampleWithoutDocument(): Text;

    /// <summary>
    /// Resolves the value for one document.
    /// </summary>
    /// <param name="Pattern">The pattern being applied, which carries the formatting choices.</param>
    /// <param name="ReportId">The report being delivered.</param>
    /// <param name="DocumentRecRef">The document the file is about.</param>
    /// <param name="LanguageCode">The document's resolved language. Anything with a translated or region-dependent form must use this rather than the session's, or the same document would be named differently by two people.</param>
    /// <param name="PlaceholderValue">Receives the value.</param>
    /// <returns>True when the value resolved. False makes the whole pattern decline, so the caller keeps the name it already had.</returns>
    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean;
}
