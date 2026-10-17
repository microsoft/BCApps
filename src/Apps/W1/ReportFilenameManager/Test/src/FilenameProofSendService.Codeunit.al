// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50195 "Filename Proof Send Service"
{
    // Sends an invoice through a Document Sending Profile whose Electronic Document option is the
    // electronic document service, isolated so its failure cannot end the proof.
    //
    // No service is set up in a test company, so the send fails - after Electronic Document Format.
    // SendElectronically has built the file and handed its name on, which is what Filename Proof Elec.
    // Doc. reads.

    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        FilenameProofElecDoc: Codeunit "Filename Proof Elec. Doc.";
        RecordVariant: Variant;
    begin
        Rec.SetRecFilter();
        DocumentSendingProfile.Init();
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::"Through Document Exchange Service";
        DocumentSendingProfile."Electronic Format" := FilenameProofElecDoc.ElectronicFormatCode();
        RecordVariant := Rec;
        DocumentSendingProfile.Send(
            Enum::"Report Selection Usage"::"S.Invoice".AsInteger(), RecordVariant, Rec."No.", Rec."Bill-to Customer No.", DocumentNameTok,
            Rec.FieldNo("Bill-to Customer No."), Rec.FieldNo("No."));
    end;

    var
        DocumentNameTok: Label 'Invoice', Locked = true;
}
