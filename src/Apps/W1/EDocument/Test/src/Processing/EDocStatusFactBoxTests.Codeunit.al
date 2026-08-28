// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;

codeunit 139899 "E-Doc. Status FactBox Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;
        StatusFactBoxTooManyRowsErr: Label 'E-Document FactBox has more rows than expected.';

    #region Tests
    [Test]
    procedure StatusFactBoxShowsEDocumentOnPurchaseOrder()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
        PurchaseOrderPage: TestPage "Purchase Order";
        StatusFactBoxShouldHaveRowErr: Label 'E-Document FactBox should show a row for a purchase order that has a linked e-document.';
    begin
        //[SCENARIO] Opening a purchase order that has one linked outbound e-document shows one row in the E-Document FactBox.

        //[GIVEN] Clean e-document tables.
        this.Initialize();
        //[GIVEN] A purchase order for a new vendor.
        this.LibraryPurchase.CreateVendor(Vendor);
        this.LibraryEDocument.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        //[GIVEN] One outbound e-document is linked to the purchase order.
        this.InsertEDocumentForRecord(EDocument, PurchaseHeader.RecordId(), "E-Document Direction"::Outgoing);

        //[WHEN] The purchase order card is opened.
        PurchaseOrderPage.OpenView();
        PurchaseOrderPage.GoToRecord(PurchaseHeader);

        //[THEN] The E-Document FactBox shows exactly one row.
        this.Assert.IsTrue(PurchaseOrderPage.EDocStatusFactBox.First(), StatusFactBoxShouldHaveRowErr);
        this.Assert.IsFalse(PurchaseOrderPage.EDocStatusFactBox.Next(), StatusFactBoxTooManyRowsErr);
        PurchaseOrderPage.Close();
    end;

    [Test]
    procedure StatusFactBoxEmptyOnPurchaseOrderWithoutEDocument()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderPage: TestPage "Purchase Order";
        StatusFactBoxShouldBeEmptyErr: Label 'E-Document FactBox should be empty for a purchase order with no linked e-document.';
    begin
        //[SCENARIO] Opening a purchase order that has no linked e-document leaves the E-Document FactBox empty.

        //[GIVEN] Clean e-document tables.
        this.Initialize();
        //[GIVEN] A purchase order with no linked e-document.
        this.LibraryPurchase.CreateVendor(Vendor);
        this.LibraryEDocument.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);

        //[WHEN] The purchase order card is opened.
        PurchaseOrderPage.OpenView();
        PurchaseOrderPage.GoToRecord(PurchaseHeader);

        //[THEN] The E-Document FactBox is empty.
        this.Assert.IsFalse(PurchaseOrderPage.EDocStatusFactBox.First(), StatusFactBoxShouldBeEmptyErr);
        PurchaseOrderPage.Close();
    end;

    [Test]
    procedure MessagesFactBoxShowsMessagesForOutboundEDocument()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        PurchaseOrderPage: TestPage "Purchase Order";
        MessagesFactBoxShouldHaveRowErr: Label 'Messages FactBox should show a row for the outbound e-document linked to the purchase order.';
    begin
        //[SCENARIO] Messages FactBox shows a row for the outbound e-document linked to the purchase order.

        //[GIVEN] Clean e-document tables.
        this.Initialize();
        //[GIVEN] A purchase order for a new vendor.
        this.LibraryPurchase.CreateVendor(Vendor);
        this.LibraryEDocument.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        //[GIVEN] An outbound e-document with one message is linked to the purchase order.
        this.InsertEDocumentForRecord(EDocument, PurchaseHeader.RecordId(), "E-Document Direction"::Outgoing);
        this.InsertEDocumentMessage(EDocMessage, EDocument."Entry No");

        //[WHEN] The purchase order card is opened.
        PurchaseOrderPage.OpenView();
        PurchaseOrderPage.GoToRecord(PurchaseHeader);

        //[THEN] The Messages FactBox shows the message.
        this.Assert.IsTrue(PurchaseOrderPage.EDocMessages.First(), MessagesFactBoxShouldHaveRowErr);
        PurchaseOrderPage.Close();
    end;

    [Test]
    procedure MessagesFactBoxEmptyWhenPurchaseOrderHasNoOutboundEDocument()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        PurchaseOrderPage: TestPage "Purchase Order";
        MessagesFactBoxShouldBeEmptyErr: Label 'Messages FactBox should be empty when the purchase order has no outbound e-document.';
    begin
        //[SCENARIO] Messages FactBox is empty when only an inbound e-document exists for the purchase order.

        //[GIVEN] Clean e-document tables.
        this.Initialize();
        //[GIVEN] A purchase order for a new vendor.
        this.LibraryPurchase.CreateVendor(Vendor);
        this.LibraryEDocument.CreatePurchaseOrderWithLine(Vendor, PurchaseHeader, PurchaseLine, 1);
        //[GIVEN] Only an incoming e-document with a message exists, no outbound.
        this.InsertEDocumentForRecord(EDocument, PurchaseHeader.RecordId(), "E-Document Direction"::Incoming);
        this.InsertEDocumentMessage(EDocMessage, EDocument."Entry No");

        //[WHEN] The purchase order card is opened.
        PurchaseOrderPage.OpenView();
        PurchaseOrderPage.GoToRecord(PurchaseHeader);

        //[THEN] The Messages FactBox is empty because it only surfaces messages for the outbound e-document.
        this.Assert.IsFalse(PurchaseOrderPage.EDocMessages.First(), MessagesFactBoxShouldBeEmptyErr);
        PurchaseOrderPage.Close();
    end;
    #endregion

    #region Initialize
    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
    begin
        this.LibraryLowerPermission.SetOutsideO365Scope();
        EDocMessage.DeleteAll(false);
        EDocument.DeleteAll(false);

        if this.IsInitialized then
            exit;
        this.EnsurePurchasesSetupOrderNos();
        this.IsInitialized := true;
    end;

    local procedure EnsurePurchasesSetupOrderNos()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Order Nos." <> '' then
            exit;
        PurchasesPayablesSetup.Validate("Order Nos.", this.LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;
    #endregion

    #region Given
    local procedure InsertEDocumentForRecord(var EDocument: Record "E-Document"; RecId: RecordId; Direction: Enum "E-Document Direction")
    begin
        EDocument.Init();
        EDocument."Document Record ID" := RecId;
        EDocument.Direction := Direction;
        EDocument.Insert(false);
    end;

    local procedure InsertEDocumentMessage(var EDocMessage: Record "E-Document Message"; EDocumentEntryNo: Integer)
    begin
        EDocMessage.Init();
        EDocMessage."E-Document Entry No." := EDocumentEntryNo;
        EDocMessage.Insert(false);
    end;
    #endregion
}