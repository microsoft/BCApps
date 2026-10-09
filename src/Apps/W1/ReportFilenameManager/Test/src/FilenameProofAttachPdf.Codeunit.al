// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50172 "Filename Proof Attach PDF"
{
    // Calls Attach as PDF for real, isolated so that a render failing on company setup this proof
    // does not control cannot end the proof. The name is decided before anything is stored, so
    // whatever happens after is not the verdict.
    //
    // Report Selections.SaveAsDocumentAttachment carries no Scope, so unlike Send to Disk this
    // route can be driven from AL on any target - which is why it is the one route on the
    // Print/Send menu that can be proven without a person clicking it.

    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        ReportSelections: Record "Report Selections";
        RecordVariant: Variant;
    begin
        // Narrowed to this one document first. A Variant carries the record's FILTERS, not just
        // the row it sits on, and the caller's reference is filtered only to "has a customer" -
        // so without this the route renders every posted invoice in the company and Base
        // Application stops it at 200 documents. Measured: that is exactly how it failed first.
        Rec.SetRecFilter();
        RecordVariant := Rec;

        // The usage is declared as an Integer here, not as the enum, so it is converted
        // deliberately rather than left to an implicit conversion the compiler warns about.
        ReportSelections.SaveAsDocumentAttachment(
            Enum::"Report Selection Usage"::"S.Invoice".AsInteger(), RecordVariant, Rec."No.", Rec."Bill-to Customer No.", false);
    end;
}
