// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;

codeunit 139790 "E-Doc. Purch. Order Exp. Test"
{
    Subtype = Test;

    var
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        EDocImplState: Codeunit "E-Doc. Impl. State";
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        IncorrectValueErr: Label 'Incorrect value found';
        ResendOrderQst: Label 'This purchase order was already sent electronically. The receiver may reject the resend as a duplicate. Do you want to continue?';

    [Test]
    procedure ReleaseOfPurchaseOrderCreatesEDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [FEATURE] [E-Document] [Processing]
        // [SCENARIO] Releasing a Purchase Order with e-document sending profile creates an E-Document

        // [GIVEN] Standard purchase scenario with vendor having a document sending profile
        Initialize();

        // [GIVEN] A purchase order with a line
        LibraryLowerPermission.SetO365BusFull();
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);

        EDocument.SetRange("Document Record ID", PurchaseHeader.RecordId());
        Assert.RecordIsEmpty(EDocument);

        // [WHEN] The purchase order is released
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [THEN] An E-Document is created with correct field values
        EDocument.SetRange("Document Record ID", PurchaseHeader.RecordId());
        Assert.RecordIsNotEmpty(EDocument);
        EDocument.FindFirst();

        Assert.AreEqual(Enum::"E-Document Type"::"Purchase Order", EDocument."Document Type", IncorrectValueErr);
        Assert.AreEqual(PurchaseHeader."No.", EDocument."Document No.", IncorrectValueErr);
        Assert.AreEqual(Enum::"E-Document Source Type"::Vendor, EDocument."Source Type", IncorrectValueErr);
        Assert.AreEqual(PurchaseHeader."Pay-to Vendor No.", EDocument."Bill-to/Pay-to No.", IncorrectValueErr);
        Assert.AreEqual(PurchaseHeader."Pay-to Name", EDocument."Bill-to/Pay-to Name", IncorrectValueErr);
        Assert.AreEqual(Enum::"E-Document Direction"::Outgoing, EDocument.Direction, IncorrectValueErr);
    end;

    [Test]
    procedure CannotDeletePurchaseOrderWithActiveEDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        ExpectedErr: Text;
        UnexpectedMessageErr: Label 'The actual message is: [%1], while the expected message is: [%2].', Comment = '%1 - Last error message, %2 - expected message';
    begin
        // [FEATURE] [E-Document] [Processing]
        // [SCENARIO] Attempting to delete a Purchase Order that has a linked E-Document in non-Canceled status raises an error

        // [GIVEN] Standard setup
        Initialize();

        // [GIVEN] A released purchase order with a linked E-Document
        LibraryLowerPermission.SetO365BusFull();
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);
        EDocument.SetRange("Document Record ID", PurchaseHeader.RecordId());
        Assert.RecordIsNotEmpty(EDocument);

        // [WHEN] Attempting to delete the purchase order
        // [THEN] An error is raised because the E-Document is not in Canceled status
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.PerformManualReopen(PurchaseHeader);
        asserterror PurchaseHeader.Delete(true);

        ExpectedErr := 'You cannot delete a purchase order that is linked to an active e-document.';
        Assert.IsTrue(StrPos(GetLastErrorText, ExpectedErr) > 0,
            StrSubstNo(UnexpectedMessageErr, GetLastErrorText, ExpectedErr));
    end;

    [Test]
    procedure CanDeletePurchaseOrderWithCanceledEDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [FEATURE] [E-Document] [Processing]
        // [SCENARIO] Deleting a Purchase Order whose linked E-Document has Status = Canceled succeeds

        // [GIVEN] Standard setup
        Initialize();

        // [GIVEN] A released purchase order with a linked E-Document
        LibraryLowerPermission.SetO365BusFull();
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);
        EDocument.SetRange("Document Record ID", PurchaseHeader.RecordId());
        EDocument.FindFirst();

        // [GIVEN] The E-Document status is set to Canceled
        EDocument.Validate(Status, Enum::"E-Document Status"::Canceled);
        EDocument.Modify(true);

        // [WHEN] The purchase order is deleted
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.PerformManualReopen(PurchaseHeader);
        PurchaseHeader.Delete(true);

        // [THEN] The purchase order is deleted successfully
        Assert.IsFalse(PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No."), 'Purchase Order should be deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ReleasingChangedOrderAfterExportAsksForConfirmation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Releasing a purchase order again after its e-document was exported warns the user that the receiver may reject the resend.

        // [GIVEN] A released purchase order whose e-document was exported
        Initialize();
        LibraryLowerPermission.SetO365BusFull();
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [GIVEN] The order is reopened and the quantity is changed
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.PerformManualReopen(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate(Quantity, 5);
        PurchaseLine.Modify(true);

        // [WHEN] The order is released again
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [THEN] The user was asked to confirm the resend and the order is released
        Assert.AreEqual(ResendOrderQst, LibraryVariableStorage.DequeueText(), 'The user should be warned that the order was already sent.');
        LibraryVariableStorage.AssertEmpty();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(PurchaseHeader.Status::Released, PurchaseHeader.Status, 'The purchase order should be released when the resend is confirmed.');
    end;

    [Test]
    procedure FirstReleaseOfPurchaseOrderDoesNotAskForConfirmation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Releasing a purchase order for the first time sends nothing twice, so no resend confirmation is shown.

        // [GIVEN] A purchase order that was never sent
        Initialize();
        LibraryLowerPermission.SetO365BusFull();
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);

        // [WHEN] The order is released
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [THEN] The order is released without a confirmation
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(PurchaseHeader.Status::Released, PurchaseHeader.Status, 'The first release should not ask for a confirmation.');
    end;

    [Test]
    procedure ReleasingOrderAgainAfterFailedExportDoesNotAskForConfirmation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Releasing again after the export failed is a retry, so no resend confirmation is shown.

        // [GIVEN] A released purchase order whose export failed
        Initialize();
        EDocImplState.SetThrowLoggedError();
        BindSubscription(EDocImplState);
        LibraryLowerPermission.SetO365BusFull();
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);
        UnbindSubscription(EDocImplState);

        // [WHEN] The order is reopened and released again
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.PerformManualReopen(PurchaseHeader);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [THEN] The order is released without a confirmation
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(PurchaseHeader.Status::Released, PurchaseHeader.Status, 'A retry after a failed export should not ask for a confirmation.');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ReleasingChangedOrderAsksForConfirmationAfterLaterExportError()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A status that changes after a successful export does not hide the earlier send, so the resend is still confirmed.

        // [GIVEN] A released purchase order whose e-document was exported
        Initialize();
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [GIVEN] The service status later moves away from the exported state
        EDocument.SetRange("Document Record ID", PurchaseHeader.RecordId());
        EDocument.FindFirst();
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        EDocumentServiceStatus.FindFirst();
        EDocumentServiceStatus.Status := Enum::"E-Document Service Status"::"Export Error";
        EDocumentServiceStatus.Modify();

        // [WHEN] The order is reopened, changed and released again
        LibraryLowerPermission.SetO365BusFull();
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.PerformManualReopen(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate(Quantity, 5);
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [THEN] The user was still asked to confirm the resend
        Assert.AreEqual(ResendOrderQst, LibraryVariableStorage.DequeueText(), 'A later status must not hide an earlier successful send.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure DecliningConfirmationStopsReleaseOfChangedOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Declining the resend confirmation stops the release so that no duplicate document is produced.

        // [GIVEN] A released purchase order whose e-document was exported
        Initialize();
        LibraryLowerPermission.SetO365BusFull();
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [GIVEN] The order is reopened and the quantity is changed
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.PerformManualReopen(PurchaseHeader);
        PurchaseLine.Find();
        PurchaseLine.Validate(Quantity, 5);
        PurchaseLine.Modify(true);

        // [WHEN] The order is released again and the user declines
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        asserterror ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [THEN] The release was stopped by the resend confirmation
        Assert.ExpectedErrorCode('Dialog');
        Assert.AreEqual(ResendOrderQst, LibraryVariableStorage.DequeueText(), 'The release should be stopped by the resend confirmation.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure InternalReleaseOfSentOrderDoesNotAskForConfirmation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Posting and warehouse documents reopen and release the order on their own, so that path must not stop for a resend confirmation.

        // [GIVEN] A released purchase order whose e-document was exported
        Initialize();
        LibraryLowerPermission.SetO365BusFull();
        LibraryEDoc.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        ReleasePurchaseDocument.PerformManualRelease(PurchaseHeader);

        // [GIVEN] The order is reopened
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.PerformManualReopen(PurchaseHeader);

        // [WHEN] The order is released again through the path that posting and warehouse documents use
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        ReleasePurchaseDocument.ReleasePurchaseHeader(PurchaseHeader, false);

        // [THEN] No confirmation was raised and the order is released
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.AreEqual(PurchaseHeader.Status::Released, PurchaseHeader.Status, 'An internal release must not stop for a resend confirmation.');
    end;

    local procedure Initialize()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryVariableStorage.Clear();
        Clear(EDocImplState);

        if IsInitialized then
            exit;

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock);

        // Setup vendor with document sending profile for purchase order export
        LibraryPurchase.CreateVendor(Vendor);
        DocumentSendingProfile.FindLast();
        Vendor."Document Sending Profile" := DocumentSendingProfile.Code;
        Vendor.Modify(true);

        LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Order");
        LibraryPurchase.SetOrderNoSeriesInSetup();

        IsInitialized := true;
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;
}
