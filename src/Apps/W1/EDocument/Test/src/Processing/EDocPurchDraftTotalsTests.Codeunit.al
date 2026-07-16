// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;

codeunit 135648 "E-Doc Purch Draft Totals Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;

    var
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";

    [Test]
    procedure AddSubTotalMismatchNotificationPersistsRecord()
    var
        EDocumentNotificationRec: Record "E-Document Notification";
        EDocumentNotification: Codeunit "E-Document Notification";
        EntryNo: Integer;
    begin
        // [SCENARIO] Adding a Sub Total Mismatch notification persists exactly one record for the user + e-document
        // [GIVEN] A clean notification table for a given entry no
        EntryNo := 909091;
        EDocumentNotificationRec.SetRange("E-Document Entry No.", EntryNo);
        EDocumentNotificationRec.DeleteAll();

        // [WHEN] Adding the notification twice (idempotent)
        EDocumentNotification.AddSubTotalMismatchNotification(EntryNo);
        EDocumentNotification.AddSubTotalMismatchNotification(EntryNo);

        // [THEN] Exactly one record of type Sub Total Mismatch exists
        EDocumentNotificationRec.SetRange("E-Document Entry No.", EntryNo);
        EDocumentNotificationRec.SetRange(Type, "E-Document Notification Type"::"Sub Total Mismatch");
        Assert.RecordCount(EDocumentNotificationRec, 1);

        // Cleanup
        EDocumentNotificationRec.SetRange(Type);
        EDocumentNotificationRec.DeleteAll();
    end;

    [Test]
    procedure RemoveSubTotalMismatchNotificationDeletesRecord()
    var
        EDocumentNotificationRec: Record "E-Document Notification";
        EDocumentNotification: Codeunit "E-Document Notification";
        EntryNo: Integer;
    begin
        // [SCENARIO] Removing the notification deletes the persisted record (totals re-converged)
        // [GIVEN] A persisted Sub Total Mismatch notification
        EntryNo := 909092;
        EDocumentNotificationRec.SetRange("E-Document Entry No.", EntryNo);
        EDocumentNotificationRec.DeleteAll();
        EDocumentNotification.AddSubTotalMismatchNotification(EntryNo);

        // [WHEN] Removing it
        EDocumentNotification.RemoveSubTotalMismatchNotification(EntryNo);

        // [THEN] No record remains for that entry no
        EDocumentNotificationRec.SetRange("E-Document Entry No.", EntryNo);
        Assert.RecordIsEmpty(EDocumentNotificationRec);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure EditingLineDoesNotOverwriteHeaderSubTotal()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
        HeaderSubTotalBefore: Decimal;
        HeaderTotalBefore: Decimal;
    begin
        // [SCENARIO] Editing a draft line no longer overwrites the extracted header Sub Total / Total
        // [GIVEN] An inbound e-document with header Sub Total intentionally different from the sum of the lines
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Sub Total" := 1000;
        EDocumentPurchaseHeader.Total := 1000;
        EDocumentPurchaseHeader.Insert();

        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."Line No." := 10000;
        EDocumentPurchaseLine.Description := 'Totals test line';
        EDocumentPurchaseLine.Quantity := 1;
        EDocumentPurchaseLine."Unit Price" := 500;
        EDocumentPurchaseLine.Insert();

        HeaderSubTotalBefore := EDocumentPurchaseHeader."Sub Total";
        HeaderTotalBefore := EDocumentPurchaseHeader.Total;

        // [WHEN] Editing the line quantity on the draft page
        EDocumentPurchaseDraft.OpenEdit();
        EDocumentPurchaseDraft.GoToRecord(EDocument);
        EDocumentPurchaseDraft.Lines.First();
        EDocumentPurchaseDraft.Lines.Quantity.SetValue(3);
        EDocumentPurchaseDraft.Close();
        EDocumentPurchaseHeader.Get(EDocument."Entry No");

        // [THEN] The header Sub Total / Total are unchanged (no overwrite from the sum of the lines)
        Assert.AreEqual(HeaderSubTotalBefore, EDocumentPurchaseHeader."Sub Total", 'Header Sub Total must not be overwritten by the sum of the lines.');
        Assert.AreEqual(HeaderTotalBefore, EDocumentPurchaseHeader.Total, 'Header Total must not be overwritten by the sum of the lines.');
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        exit(true);
    end;
}
