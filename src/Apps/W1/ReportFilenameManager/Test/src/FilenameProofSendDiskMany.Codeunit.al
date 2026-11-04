// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.History;

codeunit 149527 "Filename Proof Send Disk Many"
{
    // Calls Send to Disk for several invoices of one customer in one call, as a Document Sending
    // Profile does. Deliberately not narrowed with SetRecFilter: the caller's filter is the selection.

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
