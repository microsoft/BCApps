// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.History;

codeunit 149521 "Filename Proof Send Disk"
{
    // Calls the real Send to Disk route, isolated so a failing client download cannot end the proof;
    // the name is decided before the download. SendToDiskForCust is Scope = 'OnPrem', which is why
    // the test app targets OnPrem.

    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        ReportSelections: Record "Report Selections";
        RecordVariant: Variant;
    begin
        // A Variant carries the record's filters; without this every filtered invoice is rendered.
        Rec.SetRecFilter();
        RecordVariant := Rec;
        ReportSelections.SendToDiskForCust(
            Enum::"Report Selection Usage"::"S.Invoice", RecordVariant, Rec."No.", DocumentNameTok, Rec."Bill-to Customer No.");
    end;

    var
        // Part of Base Application's own file name, which the pattern must replace.
        DocumentNameTok: Label 'Invoice', Locked = true;
}
