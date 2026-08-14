// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.Currency;
using Microsoft.Purchases.Vendor;

codeunit 135648 "E-Doc Purch Draft Totals Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryUtility: Codeunit "Library - Utility";
        ExpectedNotificationId: Guid;
        ExpectedNotificationEntryNo: Integer;
        SentNotificationCount: Integer;

    [Test]
    procedure AddSubTotalMismatchNotificationPersistsRecord()
    var
        EDocumentNotification: Codeunit "E-Document Notification";
        EntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Adding a Sub Total Mismatch notification persists exactly one record for the user + e-document
        Initialize();

        // [GIVEN] A clean notification table for a given entry no
        EntryNo := 909091;

        // [WHEN] Adding the notification twice (idempotent)
        EDocumentNotification.AddSubTotalMismatchNotification(EntryNo);
        EDocumentNotification.AddSubTotalMismatchNotification(EntryNo);

        // [THEN] Exactly one record of type Sub Total Mismatch exists
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EntryNo), 'Exactly one Sub Total Mismatch notification must exist.');
    end;

    [Test]
    procedure RemoveSubTotalMismatchNotificationDeletesRecord()
    var
        EDocumentNotification: Codeunit "E-Document Notification";
        EntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Removing the notification deletes the persisted record (totals re-converged)
        Initialize();

        // [GIVEN] A persisted Sub Total Mismatch notification
        EntryNo := 909092;
        EDocumentNotification.AddSubTotalMismatchNotification(EntryNo);

        // [GIVEN] The notification was actually persisted
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EntryNo), 'The Sub Total Mismatch notification must exist before removal.');

        // [WHEN] Removing it
        EDocumentNotification.RemoveSubTotalMismatchNotification(EntryNo);

        // [THEN] No record remains for that entry no
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EntryNo), 'The Sub Total Mismatch notification must be removed.');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure EditingLineDoesNotOverwriteHeaderSubTotal()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Editing a draft line no longer overwrites the extracted header Sub Total / Total
        Initialize();

        // [GIVEN] An inbound e-document with header Sub Total intentionally different from the sum of the lines
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);

        // [WHEN] Editing the line quantity on the draft page
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        EDocumentPurchaseDraft.Lines.Quantity.SetValue(3);
        EDocumentPurchaseDraft.Close();

        // [THEN] The header Sub Total / Total are unchanged (no overwrite from the sum of the lines)
        VerifyHeaderTotals(EDocumentPurchaseHeader, 1000, 1000);
        VerifySubTotalMismatchNotificationShown();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure AddingLineTriggersSubTotalMismatchNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Adding a new draft line that makes the sum of the lines diverge from the header Sub Total shows the Sub Total Mismatch notification
        Initialize();

        // [GIVEN] An inbound e-document "E" whose header Sub Total (1000) matches its single line (1000)
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 1000);

        // [GIVEN] The purchase draft page is open on "E" while the header Sub Total still matches the sum of the lines
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
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
        VerifySubTotalMismatchNotificationShown();
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
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 1000.01);

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
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 1000);

        // [WHEN] Opening the purchase draft for "E"
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);

        // [THEN] One Sub Total Mismatch notification is persisted for "E"
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A header subtotal above the lines beyond tolerance must create a notification.');
        VerifySubTotalMismatchNotificationShown();

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
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 1000.02);

        // [WHEN] Opening the purchase draft for "E"
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);

        // [THEN] One Sub Total Mismatch notification is persisted for "E"
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A lines subtotal above the header beyond tolerance must create a notification.');
        VerifySubTotalMismatchNotificationShown();

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
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500.004);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500.004);

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
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 1000.02);
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A Sub Total Mismatch notification must exist before reconciling the line.');
        VerifySubTotalMismatchNotificationShown();

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
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'No Sub Total Mismatch notification should exist before deleting the line.');

        // [WHEN] Deleting the second line
        EDocumentPurchaseLine.Delete();
        EDocumentPurchaseDraft.Close();
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);

        // [THEN] One Sub Total Mismatch notification is persisted for "E"
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'Deleting a line must create a Sub Total Mismatch notification.');
        VerifySubTotalMismatchNotificationShown();

        // [THEN] The extracted header totals remain unchanged
        VerifyHeaderTotals(EDocumentPurchaseHeader, 1000, 1000);
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    procedure DismissedNotificationSuppressesSubTotalMismatchNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [SCENARIO] When the notification is marked dismissed, opening the draft (OnAfterGetRecord) does not re-show the mismatch notification
        Initialize();

        // [GIVEN] A draft with header Sub Total 1000 and a single line subtotal 500 (mismatch beyond tolerance)
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);

        // [GIVEN] The notification row is already marked as dismissed for the user
        SetSubTotalMismatchDismissed(EDocument."Entry No", true);

        // [WHEN] Opening the purchase draft (fires OnAfterGetRecord repeatedly)
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);

        // [THEN] No Sub Total Mismatch notification is persisted while dismissed
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A dismissed header must suppress the Sub Total Mismatch notification.');
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure EditingAmountReArmsDismissedSubTotalMismatchNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [SCENARIO] Editing a line amount while dismissed re-arms and re-shows the mismatch notification
        Initialize();

        // [GIVEN] A draft with header Sub Total 1000, one line subtotal 500 (mismatch), marked as dismissed
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);
        SetSubTotalMismatchDismissed(EDocument."Entry No", true);

        // [GIVEN] The draft is open and the notification is suppressed
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'The notification must be suppressed before the amount edit.');

        // [WHEN] Editing the line quantity to 3 (lines subtotal 1500, still a mismatch)
        EDocumentPurchaseDraft.Lines.Quantity.SetValue(3);

        // [THEN] The notification is shown again and the dismissed state is cleared
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'Editing an amount must re-arm and re-show the mismatch notification.');
        Assert.IsFalse(GetSubTotalMismatchDismissed(EDocument."Entry No"), 'Editing an amount must clear the dismissed state.');
        VerifySubTotalMismatchNotificationShown();
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    procedure DismissActionMarksNotificationDismissed()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentNotification: Codeunit "E-Document Notification";
        DismissNotification: Notification;
    begin
        // [SCENARIO] Invoking the Dismiss action marks the persisted notification as dismissed (row is kept, not deleted)
        Initialize();

        // [GIVEN] A draft with a persisted Sub Total Mismatch notification
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);
        EDocumentNotification.AddSubTotalMismatchNotification(EDocument."Entry No");
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'The notification must be shown before dismissing.');

        // [WHEN] The Dismiss action runs
        DismissNotification := BuildSubTotalMismatchNotification(EDocument."Entry No");
        EDocumentNotification.DismissSubTotalMismatchNotification(DismissNotification);

        // [THEN] The notification is no longer shown but the row persists marked as dismissed
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'Dismissing must stop showing the notification.');
        Assert.IsTrue(GetSubTotalMismatchDismissed(EDocument."Entry No"), 'Dismissing must mark the notification as dismissed.');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure HeaderSubTotalEditBeyondToleranceCreatesMismatchNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Editing the header Amount Excl. VAT so it diverges from the lines creates and shows the mismatch notification
        Initialize();

        // [GIVEN] An inbound e-document "E" whose header Sub Total (1000) matches its single line (1000)
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 1000);

        // [GIVEN] The purchase draft page is open on "E" without a mismatch
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'No Sub Total Mismatch notification should exist before the header edit.');

        // [WHEN] Setting the header Amount Excl. VAT to 1500
        EDocumentPurchaseDraft."Amount Excl. VAT".SetValue(1500);

        // [THEN] The Sub Total Mismatch notification is persisted and shown for "E"
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'Editing the header Sub Total beyond the tolerance must create a notification.');
        VerifySubTotalMismatchNotificationShown();

        // [THEN] The edited header totals are kept
        VerifyHeaderTotals(EDocumentPurchaseHeader, 1500, 1500);
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure HeaderSubTotalEditToMatchLinesRemovesMismatchNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Editing the header Amount Excl. VAT so it matches the lines removes the mismatch notification
        Initialize();

        // [GIVEN] An inbound e-document "E" with header Sub Total 1500 and a single line of 1000
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1500);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 1000);

        // [GIVEN] The purchase draft page is open on "E" and the mismatch notification was shown
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A Sub Total Mismatch notification must exist before the header edit.');
        VerifySubTotalMismatchNotificationShown();

        // [WHEN] Setting the header Amount Excl. VAT to 1000
        EDocumentPurchaseDraft."Amount Excl. VAT".SetValue(1000);

        // [THEN] The Sub Total Mismatch notification is removed for "E"
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'Reconciling the header Sub Total must remove the notification.');

        // [THEN] The edited header totals are kept
        VerifyHeaderTotals(EDocumentPurchaseHeader, 1000, 1000);
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure HeaderSubTotalEditReArmsDismissedMismatchNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Editing the header Amount Excl. VAT re-arms a previously dismissed mismatch notification
        Initialize();

        // [GIVEN] An inbound e-document "E" with header Sub Total 1000, a single line of 500, and a dismissed notification
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);
        SetSubTotalMismatchDismissed(EDocument."Entry No", true);

        // [GIVEN] The purchase draft page is open on "E" and the notification is suppressed
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'The notification must be suppressed before the header edit.');

        // [WHEN] Setting the header Amount Excl. VAT to 1500 (lines subtotal 500, still a mismatch)
        EDocumentPurchaseDraft."Amount Excl. VAT".SetValue(1500);

        // [THEN] The notification is shown again and the dismissed state is cleared
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'Editing the header Sub Total must re-arm and re-show the mismatch notification.');
        Assert.IsFalse(GetSubTotalMismatchDismissed(EDocument."Entry No"), 'Editing the header Sub Total must clear the dismissed state.');
        VerifySubTotalMismatchNotificationShown();
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure CurrencyCodeEditToCoarserRoundingRemovesMismatchNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Changing the header Currency Code to a currency with a coarser rounding precision widens the tolerance and removes the mismatch notification
        Initialize();

        // [GIVEN] A currency "C" with Amount Rounding Precision 1
        CurrencyCode := CreateCurrencyWithRoundingPrecision(1);

        // [GIVEN] An inbound e-document "E" in local currency with header Sub Total 1000.5 and a single line of 1000
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000.5);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 1000);

        // [GIVEN] The purchase draft page is open on "E" and the mismatch notification was shown for the 0.01 tolerance
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A Sub Total Mismatch notification must exist in local currency.');
        VerifySubTotalMismatchNotificationShown();

        // [WHEN] Setting the header Currency Code to "C"
        EDocumentPurchaseDraft."Currency Code".SetValue(CurrencyCode);

        // [THEN] The 0.5 difference is within the one-line tolerance of 1 and the notification is removed
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A coarser rounding precision must widen the tolerance and remove the notification.');
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure CurrencyCodeEditToFinerRoundingCreatesMismatchNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Changing the header Currency Code to local currency narrows the tolerance and creates the mismatch notification
        Initialize();

        // [GIVEN] A currency "C" with Amount Rounding Precision 1
        CurrencyCode := CreateCurrencyWithRoundingPrecision(1);

        // [GIVEN] An inbound e-document "E" in "C" with header Sub Total 1000.5 and a single line of 1000
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000.5);
        SetHeaderCurrencyCode(EDocumentPurchaseHeader, CurrencyCode);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 1000);

        // [GIVEN] The purchase draft page is open on "E" without a mismatch because the tolerance is 1
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'No Sub Total Mismatch notification should exist for the coarse rounding precision.');

        // [WHEN] Clearing the header Currency Code so local currency rounding applies
        EDocumentPurchaseDraft."Currency Code".SetValue('');

        // [THEN] The 0.5 difference exceeds the one-line tolerance of 0.01 and the notification is shown
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A finer rounding precision must narrow the tolerance and create the notification.');
        VerifySubTotalMismatchNotificationShown();
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure LineDeletionEvaluationExcludesDeletedLineAndCreatesNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentNotification: Codeunit "E-Document Notification";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] The line deletion evaluation, as run by the subform OnDeleteRecord trigger, excludes the line being deleted while it is still persisted
        Initialize();

        // [GIVEN] An inbound e-document "E" with header Sub Total 1000 matching two lines "L1" and "L2" of 500
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'No Sub Total Mismatch notification should exist while the lines match the header.');

        // [WHEN] Evaluating the mismatch for "L2" as deleted, before the row is removed from the database
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        EDocumentNotification.RefreshAndShowSubTotalMismatchAfterLineDeletion(EDocumentPurchaseLine);

        // [THEN] The remaining line subtotal of 500 no longer matches the header and the notification is shown
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'Deleting a line must exclude it from the lines subtotal and create a notification.');
        VerifySubTotalMismatchNotificationShown();

        // [THEN] The extracted header totals remain unchanged
        VerifyHeaderTotals(EDocumentPurchaseHeader, 1000, 1000);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure LineDeletionEvaluationReconcilingSubTotalRemovesNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentNotification: Codeunit "E-Document Notification";
        EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Deleting the line that caused the divergence removes the mismatch notification
        Initialize();

        // [GIVEN] An inbound e-document "E" with header Sub Total 1000 and lines "L1" of 1000 and "L2" of 500
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);

        // [GIVEN] The purchase draft page is open on "E" and the mismatch notification was shown
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        OpenPurchaseDraft(EDocumentPurchaseDraft, EDocument);
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'A Sub Total Mismatch notification must exist before deleting the line.');
        VerifySubTotalMismatchNotificationShown();

        // [WHEN] Evaluating the mismatch for "L2" as deleted
        EDocumentNotification.RefreshAndShowSubTotalMismatchAfterLineDeletion(EDocumentPurchaseLine);

        // [THEN] The remaining line subtotal of 1000 matches the header and the notification is removed
        Assert.AreEqual(0, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'Deleting the diverging line must remove the notification.');

        // [THEN] The extracted header totals remain unchanged
        VerifyHeaderTotals(EDocumentPurchaseHeader, 1000, 1000);
        EDocumentPurchaseDraft.Close();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure DismissVendorMatchNotificationKeepsRowMarkedDismissed()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentNotification: Codeunit "E-Document Notification";
        DismissNotification: Notification;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Dismissing the Vendor Matched By Name Not Address notification keeps the row and marks it as dismissed
        Initialize();

        // [GIVEN] An inbound e-document "E" with a Vendor Matched By Name Not Address notification
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        EDocumentNotification.AddVendorMatchedByNameNotAddressNotification(EDocument."Entry No");

        // [GIVEN] The notification is sent for "E"
        ExpectVendorMatchNotification(EDocument."Entry No");
        EDocumentNotification.SendPurchaseDocumentDraftNotifications(EDocument."Entry No");
        VerifyNotificationSentCount(1);

        // [WHEN] The Dismiss action runs
        DismissNotification := BuildVendorMatchNotification(EDocument."Entry No");
        EDocumentNotification.DismissVendorMatchedByNameNotAddressNotification(DismissNotification);

        // [THEN] The row is kept and marked as dismissed
        Assert.AreEqual(1, CountVendorMatchNotificationRows(EDocument."Entry No"), 'Dismissing must keep the persisted notification row.');
        Assert.IsTrue(GetVendorMatchDismissed(EDocument."Entry No"), 'Dismissing must mark the notification as dismissed.');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure DismissedVendorMatchNotificationIsNotSentAgain()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentNotification: Codeunit "E-Document Notification";
        DismissNotification: Notification;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A dismissed Vendor Matched By Name Not Address notification is not sent again when the draft notifications are sent
        Initialize();

        // [GIVEN] An inbound e-document "E" with a Vendor Matched By Name Not Address notification that was sent once
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        EDocumentNotification.AddVendorMatchedByNameNotAddressNotification(EDocument."Entry No");
        ExpectVendorMatchNotification(EDocument."Entry No");
        EDocumentNotification.SendPurchaseDocumentDraftNotifications(EDocument."Entry No");
        VerifyNotificationSentCount(1);

        // [GIVEN] The user dismissed the notification
        DismissNotification := BuildVendorMatchNotification(EDocument."Entry No");
        EDocumentNotification.DismissVendorMatchedByNameNotAddressNotification(DismissNotification);

        // [WHEN] Sending the purchase draft notifications for "E" again
        EDocumentNotification.SendPurchaseDocumentDraftNotifications(EDocument."Entry No");

        // [THEN] The notification is not sent a second time
        VerifyNotificationSentCount(1);
    end;

    [Test]
    procedure RefreshSubTotalMismatchPersistsWithoutShowingNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentNotification: Codeunit "E-Document Notification";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Refreshing the Sub Total mismatch state persists the notification without showing it
        Initialize();

        // [GIVEN] An inbound e-document "E" with header Sub Total 1000 and a single line of 500
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);

        // [WHEN] Refreshing the Sub Total mismatch state, with no notification handler registered
        EDocumentNotification.RefreshSubTotalMismatch(EDocumentPurchaseHeader);

        // [THEN] The notification is persisted, and nothing was shown - a shown notification would fail this test as unhandled
        Assert.AreEqual(1, CountSubTotalMismatchNotifications(EDocument."Entry No"), 'Refreshing must persist the Sub Total Mismatch notification.');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    procedure OnlyHeaderEditRefreshReArmsDismissedNotification()
    var
        EDocument: Record "E-Document";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentNotification: Codeunit "E-Document Notification";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A plain refresh keeps a dismissal, while a refresh after a header edit re-arms it
        Initialize();

        // [GIVEN] An inbound e-document "E" whose header Sub Total 1000 does not match its single line of 500
        CreatePurchaseDraft(EDocument, EDocumentPurchaseHeader, 1000);
        CreatePurchaseLine(EDocumentPurchaseLine, EDocument, 1, 500);

        // [GIVEN] The user dismissed the Sub Total Mismatch notification for "E"
        SetSubTotalMismatchDismissed(EDocument."Entry No", true);

        // [WHEN] Refreshing the state without an amount edit
        EDocumentNotification.RefreshSubTotalMismatch(EDocumentPurchaseHeader);

        // [THEN] The notification stays dismissed
        Assert.IsTrue(GetSubTotalMismatchDismissed(EDocument."Entry No"), 'A plain refresh must not re-arm a dismissed notification.');

        // [WHEN] Refreshing after a header amount edit
        ExpectSubTotalMismatchNotification(EDocument."Entry No");
        EDocumentNotification.RefreshAndShowSubTotalMismatchAfterHeaderEdit(EDocumentPurchaseHeader);

        // [THEN] The notification is re-armed and shown again
        Assert.IsFalse(GetSubTotalMismatchDismissed(EDocument."Entry No"), 'A refresh after a header edit must re-arm a dismissed notification.');
        VerifySubTotalMismatchNotificationShown();
    end;

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        EDocumentNotificationRec: Record "E-Document Notification";
    begin
        Clear(ExpectedNotificationId);
        ExpectedNotificationEntryNo := 0;
        SentNotificationCount := 0;

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

        EDocumentPurchaseHeader := LibraryEDoc.MockPurchaseDraftPrepared(EDocument);
        EDocumentPurchaseHeader."Sub Total" := HeaderSubTotal;
        EDocumentPurchaseHeader."Total VAT" := 0;
        EDocumentPurchaseHeader.Total := HeaderSubTotal;
        EDocumentPurchaseHeader.Modify();
    end;

    local procedure CreatePurchaseLine(var EDocumentPurchaseLine: Record "E-Document Purchase Line"; EDocument: Record "E-Document"; Quantity: Decimal; UnitPrice: Decimal)
    begin
        EDocumentPurchaseLine := LibraryEDoc.InsertPurchaseDraftLine(EDocument);
        EDocumentPurchaseLine.Description := 'Totals test line';
        EDocumentPurchaseLine.Quantity := Quantity;
        EDocumentPurchaseLine."Unit Price" := UnitPrice;
        EDocumentPurchaseLine.Modify();
    end;

    local procedure OpenPurchaseDraft(var EDocumentPurchaseDraft: TestPage "E-Document Purchase Draft"; EDocument: Record "E-Document")
    begin
        // The page must be opened on the e-document so that OnOpenPage, which re-evaluates the
        // Sub Total mismatch, runs with the record instead of an initialized one.
        EDocumentPurchaseDraft.Trap();
        Page.Run(Page::"E-Document Purchase Draft", EDocument);
        EDocumentPurchaseDraft.Lines.First();
    end;

    local procedure CreateCurrencyWithRoundingPrecision(RoundingPrecision: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        // The Code validation raises the base application missing exchange rates notification, which would reach the shared notification handler.
        Currency.Init();
        Currency.Code := CopyStr(LibraryUtility.GenerateRandomCode(Currency.FieldNo(Code), Database::Currency), 1, MaxStrLen(Currency.Code));
        Currency."Amount Rounding Precision" := RoundingPrecision;
        Currency."Unit-Amount Rounding Precision" := RoundingPrecision;
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure SetHeaderCurrencyCode(var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; CurrencyCode: Code[10])
    begin
        EDocumentPurchaseHeader."Currency Code" := CurrencyCode;
        EDocumentPurchaseHeader.Modify();
    end;

    local procedure CountSubTotalMismatchNotifications(EDocumentEntryNo: Integer): Integer
    var
        EDocumentNotificationRec: Record "E-Document Notification";
    begin
        EDocumentNotificationRec.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotificationRec.SetRange(Type, "E-Document Notification Type"::"Sub Total Mismatch");
        EDocumentNotificationRec.SetRange("User Id", UserId());
        EDocumentNotificationRec.SetRange(Dismissed, false);
        exit(EDocumentNotificationRec.Count());
    end;

    local procedure VerifyHeaderTotals(var EDocumentPurchaseHeader: Record "E-Document Purchase Header"; ExpectedSubTotal: Decimal; ExpectedTotal: Decimal)
    begin
        EDocumentPurchaseHeader.Get(EDocumentPurchaseHeader."E-Document Entry No.");
        Assert.AreEqual(ExpectedSubTotal, EDocumentPurchaseHeader."Sub Total", 'Header Sub Total must not be changed by line edits.');
        Assert.AreEqual(ExpectedTotal, EDocumentPurchaseHeader.Total, 'Header Total must not be changed by line edits.');
    end;

    local procedure GetSubTotalMismatchDismissed(EDocumentEntryNo: Integer): Boolean
    var
        EDocumentNotificationRec: Record "E-Document Notification";
    begin
        if EDocumentNotificationRec.Get(EDocumentEntryNo, SubTotalMismatchNotificationId(), UserId()) then
            exit(EDocumentNotificationRec.Dismissed);
        exit(false);
    end;

    local procedure SetSubTotalMismatchDismissed(EDocumentEntryNo: Integer; Dismissed: Boolean)
    var
        EDocumentNotificationRec: Record "E-Document Notification";
    begin
        if not EDocumentNotificationRec.Get(EDocumentEntryNo, SubTotalMismatchNotificationId(), UserId()) then begin
            EDocumentNotificationRec.Init();
            EDocumentNotificationRec."E-Document Entry No." := EDocumentEntryNo;
            EDocumentNotificationRec.ID := SubTotalMismatchNotificationId();
            EDocumentNotificationRec."User Id" := UserId();
            EDocumentNotificationRec.Type := "E-Document Notification Type"::"Sub Total Mismatch";
            EDocumentNotificationRec.Insert();
        end;
        EDocumentNotificationRec.Dismissed := Dismissed;
        EDocumentNotificationRec.Modify();
    end;

    local procedure SubTotalMismatchNotificationId(): Guid
    begin
        exit('a1e6c0d2-3b4f-4c8a-9d1e-2f7b6a5c4d3e');
    end;

    local procedure BuildSubTotalMismatchNotification(EDocumentEntryNo: Integer) Notification: Notification
    var
        EDocumentNotificationRec: Record "E-Document Notification";
    begin
        Notification.SetData(EDocumentNotificationRec.FieldName("E-Document Entry No."), Format(EDocumentEntryNo));
        Notification.SetData(EDocumentNotificationRec.FieldName(ID), SubTotalMismatchNotificationId());
    end;

    local procedure ExpectSubTotalMismatchNotification(EDocumentEntryNo: Integer)
    begin
        ExpectedNotificationId := SubTotalMismatchNotificationId();
        ExpectedNotificationEntryNo := EDocumentEntryNo;
        SentNotificationCount := 0;
    end;

    local procedure VerifySubTotalMismatchNotificationShown()
    begin
        Assert.IsTrue(SentNotificationCount > 0, 'The Sub Total Mismatch notification must be shown.');
    end;

    local procedure VerifyNotificationSentCount(ExpectedCount: Integer)
    begin
        Assert.AreEqual(ExpectedCount, SentNotificationCount, 'The notification was sent an unexpected number of times.');
    end;

    local procedure VendorMatchNotificationId(): Guid
    begin
        exit('bc0d8537-8e8d-4d94-a07a-a5a54c729d2a');
    end;

    local procedure CountVendorMatchNotificationRows(EDocumentEntryNo: Integer): Integer
    var
        EDocumentNotificationRec: Record "E-Document Notification";
    begin
        EDocumentNotificationRec.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocumentNotificationRec.SetRange(Type, "E-Document Notification Type"::"Vendor Matched By Name Not Address");
        EDocumentNotificationRec.SetRange("User Id", UserId());
        exit(EDocumentNotificationRec.Count());
    end;

    local procedure GetVendorMatchDismissed(EDocumentEntryNo: Integer): Boolean
    var
        EDocumentNotificationRec: Record "E-Document Notification";
    begin
        if EDocumentNotificationRec.Get(EDocumentEntryNo, VendorMatchNotificationId(), UserId()) then
            exit(EDocumentNotificationRec.Dismissed);
        exit(false);
    end;

    local procedure BuildVendorMatchNotification(EDocumentEntryNo: Integer) Notification: Notification
    var
        EDocumentNotificationRec: Record "E-Document Notification";
    begin
        Notification.SetData(EDocumentNotificationRec.FieldName("E-Document Entry No."), Format(EDocumentEntryNo));
        Notification.SetData(EDocumentNotificationRec.FieldName(ID), VendorMatchNotificationId());
    end;

    local procedure ExpectVendorMatchNotification(EDocumentEntryNo: Integer)
    begin
        ExpectedNotificationId := VendorMatchNotificationId();
        ExpectedNotificationEntryNo := EDocumentEntryNo;
        SentNotificationCount := 0;
    end;

    [SendNotificationHandler]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        EDocumentNotificationRec: Record "E-Document Notification";
        ActualEntryNo: Integer;
    begin
        SentNotificationCount += 1;
        Assert.AreEqual(ExpectedNotificationId, Notification.Id, 'An unexpected notification was shown.');
        Assert.AreEqual(Format(ExpectedNotificationId), Notification.GetData(EDocumentNotificationRec.FieldName(ID)), 'The notification carries an unexpected ID.');
        Evaluate(ActualEntryNo, Notification.GetData(EDocumentNotificationRec.FieldName("E-Document Entry No.")));
        Assert.AreEqual(ExpectedNotificationEntryNo, ActualEntryNo, 'The notification was shown for an unexpected e-document.');
        exit(true);
    end;
}
