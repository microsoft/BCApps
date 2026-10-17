// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50177 "Filename Proof Send Disk Many"
{
    // Calls Send to Disk for a selection of several invoices, the way a Document Sending Profile does
    // when every selected invoice belongs to one customer: one call, the whole selection, one PDF.
    //
    // Deliberately NOT narrowed with SetRecFilter, unlike Filename Proof Send Disk. The caller's
    // filter is the selection, and keeping it is the point.

    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        ReportSelections: Record "Report Selections";
        RecordVariant: Variant;
    begin
        RecordVariant := Rec;
        ReportSelections.SendToDiskForCust(
            Enum::"Report Selection Usage"::"S.Invoice", RecordVariant, Rec."No.", DocumentNameTok, Rec."Bill-to Customer No.");
    end;

    var
        DocumentNameTok: Label 'Invoice', Locked = true;
}
