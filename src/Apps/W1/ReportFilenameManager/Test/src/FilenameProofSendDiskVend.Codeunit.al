// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.History;

codeunit 149524 "Filename Proof Send Disk Vend"
{
    // Vendor twin of Filename Proof Send Disk, isolated so a failing client download cannot end
    // the proof. SendToDiskForVend is Scope = 'OnPrem'.

    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    var
        ReportSelections: Record "Report Selections";
        RecordVariant: Variant;
    begin
        Rec.SetRecFilter();
        RecordVariant := Rec;
        ReportSelections.SendToDiskForVend(
            Enum::"Report Selection Usage"::"P.Invoice", RecordVariant, Rec."No.", DocumentNameTok, Rec."Pay-to Vendor No.");
    end;

    var
        DocumentNameTok: Label 'Invoice', Locked = true;
}
