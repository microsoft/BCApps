// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Foundation.Attachment;
using System.IO;
using System.Utilities;

// Temporary bridge until the Agent Framework can attach the source PDF to an outcome itself.
codeunit 3319 "PA Outcome PDF Attachment"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Document Attachment" = RI;

    var
        AttachmentNameLbl: Label 'Payables Agent %1 - %2', Comment = '%1 = task entry number, %2 = source PDF file name without extension';

    internal procedure AttachSourcePdf(StoredTask: Record "Payables Agent Task"; Outcome: RecordId)
    var
        DocumentAttachment: Record "Document Attachment";
        FileManagement: Codeunit "File Management";
        Pdf: Codeunit "Temp Blob";
        OutcomeRef: RecordRef;
        PdfStream: InStream;
        FileName: Text;
        BaseName: Text;
    begin
        if not StoredTask."File Content".HasValue() then
            exit;

        OutcomeRef.Get(Outcome);
        // The task ID disambiguates PDFs from different tasks and makes repeat registration idempotent.
        BaseName := FileManagement.GetFileNameWithoutExtension(StoredTask."File Name");
        FileName := CopyStr(StrSubstNo(AttachmentNameLbl, StoredTask."Entry No.", BaseName), 1, 246) + '.pdf';
        DocumentAttachment.InitFieldsFromRecRef(OutcomeRef);
        DocumentAttachment.SetRange("Table ID", DocumentAttachment."Table ID");
        DocumentAttachment.SetRange("No.", DocumentAttachment."No.");
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type");
        DocumentAttachment.SetRange("Line No.", DocumentAttachment."Line No.");
        DocumentAttachment.SetRange("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(FileName), 1, MaxStrLen(DocumentAttachment."File Name")));
        DocumentAttachment.SetRange("File Extension", 'pdf');
        if not DocumentAttachment.IsEmpty() then
            exit;

        StoredTask.GetFileContent(Pdf);
        Pdf.CreateInStream(PdfStream);
        Clear(DocumentAttachment);
        DocumentAttachment.SaveAttachmentFromStream(PdfStream, OutcomeRef, FileName, false);
    end;
}
