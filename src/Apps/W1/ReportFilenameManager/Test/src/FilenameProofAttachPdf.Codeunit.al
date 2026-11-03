// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.History;

codeunit 149522 "Filename Proof Attach PDF"
{
    // Calls Attach as PDF for real, isolated so a render failing on company setup cannot end the
    // proof; the name is decided before anything is stored. SaveAsDocumentAttachment carries no
    // Scope, so unlike Send to Disk it can be driven from AL on any target.

    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        ReportSelections: Record "Report Selections";
        RecordVariant: Variant;
    begin
        // A Variant carries the record's filters, not just its row: without this the route renders
        // every invoice the caller's filter lets through.
        Rec.SetRecFilter();
        RecordVariant := Rec;

        ReportSelections.SaveAsDocumentAttachment(
            Enum::"Report Selection Usage"::"S.Invoice".AsInteger(), RecordVariant, Rec."No.", Rec."Bill-to Customer No.", false);
    end;
}
