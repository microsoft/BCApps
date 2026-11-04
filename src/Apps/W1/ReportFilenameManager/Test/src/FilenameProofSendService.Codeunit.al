// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.History;

codeunit 149545 "Filename Proof Send Service"
{
    // Sends an invoice through the electronic document service, isolated: with no service set up the
    // send fails, after SendElectronically has built and named the file.

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
