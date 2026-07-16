// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Purchases.Vendor;

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
        // [FEATURE] [AI test]
        // [SCENARIO] Adding a Sub Total Mismatch notification persists exactly one record for the user + e-document
        Initialize();

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
        // [FEATURE] [AI test]
        // [SCENARIO] Removing the notification deletes the persisted record (totals re-converged)
        Initialize();

        // [GIVEN] A persisted Sub Total Mismatch notification
        EntryNo := 909092;
        EDocumentNotificationRec.SetRange("E-Document Entry No.", EntryNo);
        EDocumentNotificationRec.DeleteAll();
        EDocumentNotification.AddSubTotalMismatchNotification(EntryNo);

        // [GIVEN] The notification was actually persisted
        EDocumentNotificationRec.SetRange("E-Document Entry No.", EntryNo);
        EDocumentNotificationRec.SetRange(Type, "E-Document Notification Type"::"Sub Total Mismatch");
        Assert.RecordCount(EDocumentNotificationRec, 1);

        // [WHEN] Removing it
        EDocumentNotification.RemoveSubTotalMismatchNotification(EntryNo);

        // [THEN] No record remains for that entry no
        EDocumentNotificationRec.SetRange("E-Document Entry No.", EntryNo);
        EDocumentNotificationRec.SetRange(Type);
        Assert.RecordIsEmpty(EDocumentNotificationRec);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure EditingLineDoesNotOverwriteHeaderSubTotal()
    var
        EDocument: Record "E-Document";
        EDocumentNotificationRec: Record "E-Document Notification";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor: Record Vendor;
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
        HeaderSubTotalBefore: Decimal;
        HeaderTotalBefore: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Editing a draft line no longer overwrites the extracted header Sub Total / Total
        Initialize();

        // [GIVEN] An inbound e-document with header Sub Total intentionally different from the sum of the lines
        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock, Enum::"E-Document Import Process"::"Version 2.0");
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

        EDocumentNotificationRec.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocumentNotificationRec.SetRange(Type, "E-Document Notification Type"::"Sub Total Mismatch");
        EDocumentNotificationRec.DeleteAll();
        EDocumentPurchaseLine.Delete();
        EDocumentPurchaseHeader.Delete();
        EDocument.Delete();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure AddingLineTriggersSubTotalMismatchNotification()
    var
        EDocument: Record "E-Document";
        EDocumentNotificationRec: Record "E-Document Notification";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        Vendor: Record Vendor;
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Adding a new draft line that makes the sum of the lines diverge from the header Sub Total shows the Sub Total Mismatch notification
        Initialize();

        // [GIVEN] An inbound e-document "E" whose header Sub Total (1000) matches its single line (1000)
        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock, Enum::"E-Document Import Process"::"Version 2.0");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Sub Total" := 1000;
        EDocumentPurchaseHeader.Total := 1000;
        EDocumentPurchaseHeader.Insert();

        EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseLine."Line No." := 10000;
        EDocumentPurchaseLine.Description := 'Matching line';
        EDocumentPurchaseLine.Quantity := 1;
        EDocumentPurchaseLine."Unit Price" := 1000;
        EDocumentPurchaseLine.Insert();

        // [GIVEN] The purchase draft page is open on "E" while the header Sub Total still matches the sum of the lines
        EDocumentPurchaseDraft.OpenEdit();
        EDocumentPurchaseDraft.GoToRecord(EDocument);
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'No Sub Total Mismatch notification should exist before adding the line.');

        // [WHEN] Adding a new line of 500 so the sum of the lines (1500) no longer matches the header Sub Total (1000)
        EDocumentPurchaseDraft.Lines.New();
        EDocumentPurchaseDraft.Lines.Description.SetValue('Added line');
        EDocumentPurchaseDraft.Lines.Quantity.SetValue(1);
        EDocumentPurchaseDraft.Lines."Direct Unit Cost".SetValue(500);
        // Leave the new row so it is committed and the totals are re-evaluated against the persisted lines
        EDocumentPurchaseDraft.Lines.First();
        EDocumentPurchaseDraft.Close();

        // [THEN] The Sub Total Mismatch notification is shown (SendNotificationHandler) and persisted for "E"
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A Sub Total Mismatch notification should exist after adding the line.');

        // Cleanup
        EDocumentNotificationRec.DeleteAll();
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocumentPurchaseLine.DeleteAll();
        EDocumentPurchaseHeader.Delete();
        EDocument.Delete();
    end;

    [Test]
    procedure DifferenceEqualToToleranceDoesNotCreateNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A Sub Total difference equal to the rounding tolerance does not create a notification
        Initialize();

        // [GIVEN] An inbound e-document "E" with one line whose subtotal differs from the header by exactly 0.01
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument."Entry No", 10000, 1, 1000.01);

        // [WHEN] Opening the purchase draft for "E"
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);

        // [THEN] No Sub Total Mismatch notification is persisted because the difference equals the one-line tolerance
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A difference equal to the tolerance must not create a notification.');
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure HeaderSubtotalAboveLinesBeyondToleranceCreatesNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A header Sub Total above the lines by more than the tolerance creates a notification
        Initialize();

        // [GIVEN] An inbound e-document "E" with header Sub Total 1000.02 and line subtotal 1000
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000.02);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument."Entry No", 10000, 1, 1000);

        // [WHEN] Opening the purchase draft for "E"
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);

        // [THEN] One Sub Total Mismatch notification is persisted for "E"
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A header subtotal above the lines beyond tolerance must create a notification.');

        // [THEN] The extracted header totals remain unchanged
        VerifyHeaderTotals(EDocumentPurchaseHeader, 1000.02, 1000.02);
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure LinesSubtotalAboveHeaderBeyondToleranceCreatesNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A lines Sub Total above the header by more than the tolerance creates a notification
        Initialize();

        // [GIVEN] An inbound e-document "E" with header Sub Total 1000 and line subtotal 1000.02
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument."Entry No", 10000, 1, 1000.02);

        // [WHEN] Opening the purchase draft for "E"
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);

        // [THEN] One Sub Total Mismatch notification is persisted for "E"
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A lines subtotal above the header beyond tolerance must create a notification.');

        // [THEN] The extracted header totals remain unchanged
        VerifyHeaderTotals(EDocumentPurchaseHeader, 1000, 1000);
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    procedure MultipleLinesUsePerLineRoundingAndAccumulatedTolerance()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Multiple lines use per-line currency rounding and accumulate the allowed tolerance
        Initialize();

        // [GIVEN] An inbound e-document "E" with two lines that each round from 500.004 to 500
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000.02);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument."Entry No", 10000, 1, 500.004);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument."Entry No", 20000, 1, 500.004);

        // [WHEN] Opening the purchase draft for "E"
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);

        // [THEN] No notification is persisted because the 0.02 difference equals the two-line tolerance
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A difference equal to the accumulated tolerance must not create a notification.');
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure EditingLineToReconcileSubtotalRemovesMismatchNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Editing a line so its subtotal matches the header removes the mismatch notification
        Initialize();

        // [GIVEN] An inbound e-document "E" with header Sub Total 1000, line subtotal 1000.02, and a mismatch notification
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument."Entry No", 10000, 1, 1000.02);
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A Sub Total Mismatch notification must exist before reconciling the line.');

        // [WHEN] Changing the line direct unit cost to 1000
        EDocumentPurchaseDraft.Lines."Direct Unit Cost".SetValue(1000);
        EDocumentPurchaseDraft.Close();
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);

        // [THEN] The Sub Total Mismatch notification is removed
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'The Sub Total Mismatch notification must be removed after reconciling the line.');

        // [THEN] The extracted header totals remain unchanged
        VerifyHeaderTotals(EDocumentPurchaseHeader, 1000, 1000);
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure DeletingLineReevaluatesMismatchWithoutChangingHeaderTotals()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Deleting a line re-evaluates the mismatch without changing the extracted header totals
        Initialize();

        // [GIVEN] An inbound e-document "E" with header Sub Total 1000 matching two lines of 500
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument."Entry No", 10000, 1, 500);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument."Entry No", 20000, 1, 500);
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'No Sub Total Mismatch notification should exist before deleting the line.');

        // [WHEN] Deleting the second line
        EDocumentPurchaseLine.Delete();
        EDocumentPurchaseDraft.Close();
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);

        // [THEN] One Sub Total Mismatch notification is persisted for "E"
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'Deleting a line must create a Sub Total Mismatch notification.');

        // [THEN] The extracted header totals remain unchanged
        VerifyHeaderTotals(EDocumentPurchaseHeader, 1000, 1000);
        EDocumentPurchaseDraft.Close();
    end;

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentNotificationRec: Record "E-Document Notification";
    begin
        EDocumentNotificationRec.SetRange(Type, "E-Document Notification Type"::"Sub Total Mismatch");
        EDocumentNotificationRec.SetRange("User Id", UserId());
        EDocumentNotificationRec.DeleteAll();
        EDocumentPurchaseLine.DeleteAll();
        EDocumentPurchaseHeader.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocument.DeleteAll();
    end;

    local procedure CreatePurchaseDraft(var EDocument: Record "E-Document"; var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; HeaderSubTotal: Decimal)
    var
        Vendor: Record Vendor;
    begin
        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock, Enum::"E-Document Import Process"::"Version 2.0");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader."Sub Total" := HeaderSubTotal;
        EDocumentPurchaseHeader.Total := HeaderSubTotal;
        EDocumentPurchaseHeader.Insert();
    end;

    local procedure CreatePurchaseLine(var EDocumentPurchaseLine: Record "E-Document Purchase Line"; EDocumentEntryNo: Integer; LineNo: Integer; Quantity: Decimal; UnitPrice: Decimal)
    begin
        Clear(EDocumentPurchaseLine);
        EDocumentPurchaseLine."E-Document Entry No." := EDocumentEntryNo;
        EDocumentPurchaseLine."Line No." := LineNo;
        EDocumentPurchaseLine.Description := 'Totals test line';
        EDocumentPurchaseLine.Quantity := Quantity;
        EDocumentPurchaseLine."Unit Price" := UnitPrice;
        EDocumentPurchaseLine.Insert();
    end;

    local procedure OpenPurchaseDraft(var EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft"; EDocument: Record "E-Document")
    begin
        EDocumentPurchaseDraft.OpenEdit();
        EDocumentPurchaseDraft.GoToRecord(EDocument);
        EDocumentPurchaseDraft.Lines.First();
    end;

    local procedure CountSubTotalMismatchNotifications(EDocumentEntryNo: Integer): Integer
    var
        EDocumentNotificationRec: Record "E-Document Notification";
    begin
        EDocumentNotificationRec.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotificationRec.SetRange(Type, "E-Document Notification Type"::"Sub Total Mismatch");
        EDocumentNotificationRec.SetRange("User Id", UserId());
        exit(EDocumentNotificationRec.Count());
    end;

    local procedure VerifyHeaderTotals(var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; ExpectedSubTotal: Decimal; ExpectedTotal: Decimal)
    begin
        EDocumentPurchaseHeader.Get(EDocumentPurchaseHeader."E-Document Entry No.");
        Assert.AreEqual(ExpectedSubTotal, EDocumentPurchaseHeader."Sub Total", 'Header Sub Total must not be changed by line edits.');
        Assert.AreEqual(ExpectedTotal, EDocumentPurchaseHeader.Total, 'Header Total must not be changed by line edits.');
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
        exit(true);
    end;
}
