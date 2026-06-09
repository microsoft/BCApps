// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Attachment;
using System.Utilities;

codeunit 139896 "E-Doc. Attachment Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    Permissions = tabledata "E-Document" = rimd,
                  tabledata "Document Attachment" = rimd;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure UploadAttachmentToEDocSetsEDocFields()
    var
        EDocument: Record "E-Document";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStream: OutStream;
        InStream: InStream;
    begin
        // [FEATURE] [E-Document] [Attachment]
        // [SCENARIO] Bug 619590: When uploading an attachment to an E-Document via the factbox,
        // the Document Attachment record must have "E-Document Attachment" = true and
        // "E-Document Entry No." set. Without OnBeforeInsertAttachment subscriber, these
        // fields are not populated and the attachment won't appear in the factbox.

        // [GIVEN] An E-Document record exists
        EDocument.Init();
        EDocument."Document Type" := "E-Document Type"::"Purchase Invoice";
        EDocument.Direction := "E-Document Direction"::Incoming;
        EDocument.Insert(true);

        // [GIVEN] A RecRef pointing to the E-Document
        // (In the real flow, OnAfterGetRecRefFail constructs this from the factbox SubPageLink filters)
        RecRef.GetTable(EDocument);

        // [WHEN] We save an attachment via SaveAttachmentFromStream (same path as factbox upload)
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('Test attachment content for bug 619590');
        TempBlob.CreateInStream(InStream);
        DocumentAttachment.Init();
        DocumentAttachment.SaveAttachmentFromStream(InStream, RecRef, 'test-edoc-attachment.txt');

        // [THEN] The Document Attachment is created with Table ID = E-Document
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"E-Document");
        DocumentAttachment.SetRange("No.", Format(EDocument."Entry No"));
        DocumentAttachment.FindFirst();

        // [THEN] E-Document fields are set by the OnBeforeInsertAttachment subscriber
        Assert.IsTrue(DocumentAttachment."E-Document Attachment",
            'E-Document Attachment should be true — OnBeforeInsertAttachment subscriber must set this field');
        Assert.AreEqual(EDocument."Entry No", DocumentAttachment."E-Document Entry No.",
            'E-Document Entry No. should match the E-Document — OnBeforeInsertAttachment subscriber must set this field');
    end;

    [Test]
    procedure GetRefTableReturnsFalseForTableIdZero()
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        RecRef: RecordRef;
    begin
        // [FEATURE] [E-Document] [Attachment]
        // [SCENARIO] Bug 619590: Verify precondition — GetRefTable returns false when Table ID = 0
        // This is the state of Rec in the factbox when no attachments exist (SubPageLink
        // does not set Table ID).

        // [GIVEN] A Document Attachment with Table ID = 0
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := 0;

        // [WHEN] GetRefTable is called
        // [THEN] It returns false because Table ID = 0 is not handled
        Assert.IsFalse(
            DocumentAttachmentMgmt.GetRefTable(RecRef, DocumentAttachment),
            'GetRefTable should return false for Table ID = 0');
    end;
}
