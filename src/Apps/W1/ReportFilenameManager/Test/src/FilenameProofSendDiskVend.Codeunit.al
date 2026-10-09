// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50174 "Filename Proof Send Disk Vend"
{
    // Calls the real Send to Disk route for a vendor document, isolated so its failure cannot end
    // the proof - the twin of Filename Proof Send Disk. The route ends in a client download, which a
    // session without a client may not be able to complete; the name is decided before that.
    //
    // Report Selections.SendToDiskForVend is Scope = 'OnPrem', like its customer twin.

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
