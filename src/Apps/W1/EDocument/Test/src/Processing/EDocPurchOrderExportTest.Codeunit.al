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

codeunit 139897 "E-Doc. Purch. Order Exp. Test"
{
    Subtype = Test;

    var
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        IncorrectValueErr: Label 'Incorrect value found';

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
        Assert.ExpectedTestFieldError(EDocument.FieldCaption(Status), Format(Enum::"E-Document Status"::Canceled));
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

    local procedure Initialize()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();

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
        Vendor."VAT Bus. Posting Group" := Vendor."VAT Bus. Posting Group";
        Vendor.Modify(true);

        LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Order");
        LibraryPurchase.SetOrderNoSeriesInSetup();

        IsInitialized := true;
    end;
}
