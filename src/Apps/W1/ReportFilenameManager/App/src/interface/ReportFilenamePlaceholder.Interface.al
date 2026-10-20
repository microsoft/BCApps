// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

interface "Report Filename Placeholder"
{
    // One implementation per computed value: adding a placeholder is an enum extension plus one codeunit.

    /// <summary>
    /// The language-invariant name recorded in a pattern's binding. Never translated, or stored bindings stop resolving.
    /// </summary>
    procedure CanonicalName(): Text;

    /// <summary>
    /// The translated name shown in Available Placeholders and accepted when a pattern is written.
    /// </summary>
    procedure DisplayName(): Text;

    procedure Description(): Text;

    /// <summary>
    /// Whether the value can be worked out for a pattern on the given table. Available Placeholders
    /// only offers placeholders that return true.
    /// </summary>
    /// <param name="TableNo">Zero when the pattern is tied to no table.</param>
    procedure IsTableSupported(TableNo: Integer): Boolean;

    /// <summary>
    /// Whether the value is one value for a run covering many records (company, user, date) rather
    /// than per document (a document total). Used for the picker and the card's examples; at run time
    /// TryResolve itself must decline a multi-record run when this is false.
    /// Adding a method without a default body here breaks every partner implementation (AppSourceCop AS0066).
    /// </summary>
    procedure SpeaksForARunOfManyRecords(): Boolean;

    /// <summary>
    /// The shape of the value, shown in the picker's Example column when it cannot be resolved without a document.
    /// Never a real record's value.
    /// </summary>
    /// <returns>Blank when the value always resolves without a document.</returns>
    procedure ExampleWithoutDocument(): Text;

    /// <summary>
    /// Resolves the value for one document.
    /// </summary>
    /// <param name="LanguageCode">The document's resolved language; use it rather than the session's for anything translated or region-dependent.</param>
    /// <returns>False makes the whole pattern decline, so the caller keeps the name it already had.</returns>
    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean;
}
