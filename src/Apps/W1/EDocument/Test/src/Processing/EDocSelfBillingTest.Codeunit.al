// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Service.Participant;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 139783 "E-Doc. Self-Billing Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    Permissions = tabledata "Service Participant" = rimd;

    var
        EDocumentService: Record "E-Document Service";
        Vendor: Record Vendor;
        Assert: Codeunit Assert;
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        LibraryPurchase: Codeunit "Library - Purchase";
        IsInitialized: Boolean;
        IncorrectValueErr: Label 'Incorrect value found';

    [Test]
    procedure PostingInvoiceForSelfBillingVendorSetsSelfBilledType()
    var
        EDocument: Record "E-Document";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [E-Document] [Self-Billing]
        // [SCENARIO] Posting a purchase invoice for a vendor with a self-billing agreement and
        // registered participant IDs auto-creates an outbound e-document with the self-billed type.

        // [GIVEN] A vendor with a self-billing agreement and both participant IDs registered
        Initialize();
        SetSelfBillingAgreement(Vendor, true);
        SeedParticipants();

        LibraryLowerPermission.SetO365BusFull();
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, Enum::"Purchase Document Type"::Invoice, Vendor."No.", CreateItem(), 1, '', 0D);

        // [WHEN] The purchase invoice is posted
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        PurchInvHeader.Get(DocumentNo);

        // [THEN] An outbound e-document is created with the self-billed purchase invoice type
        EDocument.SetRange("Document Record ID", PurchInvHeader.RecordId());
        Assert.RecordIsNotEmpty(EDocument);
        EDocument.FindFirst();

        Assert.AreEqual(Enum::"E-Document Type"::"Self-Billed Purchase Invoice", EDocument."Document Type", IncorrectValueErr);
        Assert.AreEqual(Enum::"E-Document Direction"::Outgoing, EDocument.Direction, IncorrectValueErr);
        Assert.AreEqual(Vendor."No.", EDocument."Bill-to/Pay-to No.", IncorrectValueErr);
    end;

    [Test]
    procedure PostingInvoiceForNormalVendorIsUnaffected()
    var
        EDocument: Record "E-Document";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [E-Document] [Self-Billing]
        // [SCENARIO] Regression: posting a purchase invoice for a vendor WITHOUT a self-billing
        // agreement behaves exactly as before this feature — no outbound e-document is created.

        // [GIVEN] A vendor with no self-billing agreement — reset explicitly rather than relying
        // on default state, since the global Vendor var can carry a prior test's in-memory value
        Initialize();
        SetSelfBillingAgreement(Vendor, false);

        LibraryLowerPermission.SetO365BusFull();
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, Enum::"Purchase Document Type"::Invoice, Vendor."No.", CreateItem(), 1, '', 0D);

        // [WHEN] The purchase invoice is posted
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        PurchInvHeader.Get(DocumentNo);

        // [THEN] No e-document is auto-created for this posted invoice
        EDocument.SetRange("Document Record ID", PurchInvHeader.RecordId());
        Assert.RecordIsEmpty(EDocument);
    end;

    [Test]
    procedure EligibilityRequiresSelfBilledDocumentAndBothParticipants()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocumentSubscribers: Codeunit "E-Document Subscribers";
    begin
        // [FEATURE] [E-Document] [Self-Billing]
        // [SCENARIO] IsEligibleForSelfBilling requires the posted document to be self-billed AND both the
        // vendor's and the company's participant IDs to be registered — any one missing disqualifies.

        // [GIVEN] No participants — reset explicitly rather than relying on absent state. Initialize()'s
        // own cleanup only runs once per session (guarded by IsInitialized), and an earlier test in this
        // run may have committed participant rows through posting.
        Initialize();
        ClearParticipants();

        // [GIVEN] A posted invoice for the vendor that is not a self-billing invoice
        PurchInvHeader."Buy-from Vendor No." := Vendor."No.";

        // [THEN] Not eligible: not self-billed, no participants
        Assert.IsFalse(EDocumentSubscribers.IsEligibleForSelfBilling(PurchInvHeader), IncorrectValueErr);

        // [GIVEN] The invoice is a self-billing invoice, but still no participants
        PurchInvHeader."Self-Billing Invoice" := true;
        // [THEN] Still not eligible
        Assert.IsFalse(EDocumentSubscribers.IsEligibleForSelfBilling(PurchInvHeader), IncorrectValueErr);

        // [GIVEN] Only the vendor participant registered (company participant still missing)
        InsertParticipant(Enum::"E-Document Source Type"::Vendor, Vendor."No.");
        // [THEN] Still not eligible
        Assert.IsFalse(EDocumentSubscribers.IsEligibleForSelfBilling(PurchInvHeader), IncorrectValueErr);

        // [GIVEN] The company participant is registered too
        InsertParticipant(Enum::"E-Document Source Type"::Company, '');
        // [THEN] Now eligible
        Assert.IsTrue(EDocumentSubscribers.IsEligibleForSelfBilling(PurchInvHeader), IncorrectValueErr);

        // [GIVEN] The invoice is not a self-billing invoice
        PurchInvHeader."Self-Billing Invoice" := false;
        // [THEN] Not eligible even with both participants present
        Assert.IsFalse(EDocumentSubscribers.IsEligibleForSelfBilling(PurchInvHeader), IncorrectValueErr);

        // [GIVEN] A posted credit memo for the vendor that is not applied to any invoice
        PurchCrMemoHdr."Buy-from Vendor No." := Vendor."No.";
        // [THEN] Not eligible even with both participants present
        Assert.IsFalse(EDocumentSubscribers.IsEligibleForSelfBilling(PurchCrMemoHdr), IncorrectValueErr);
    end;

    [Test]
    procedure ChangingVendorAgreementAfterPostingDoesNotChangeEligibility()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocumentSubscribers: Codeunit "E-Document Subscribers";
    begin
        // [FEATURE] [E-Document] [Self-Billing]
        // [SCENARIO] Eligibility is driven by the posted document, not by the vendor's current
        // "Self-Billing Agreement", which can change after the document is posted.

        // [GIVEN] A self-billing invoice posted for a vendor with a self-billing agreement
        Initialize();
        SetSelfBillingAgreement(Vendor, true);
        SeedParticipants();
        PurchInvHeader.Get(PostSelfBillingInvoice());

        // [WHEN] The vendor's self-billing agreement is turned off after posting
        LibraryLowerPermission.SetOutsideO365Scope();
        SetSelfBillingAgreement(Vendor, false);

        // [THEN] The posted invoice is still eligible for self-billing
        Assert.IsTrue(PurchInvHeader."Self-Billing Invoice", IncorrectValueErr);
        Assert.IsTrue(EDocumentSubscribers.IsEligibleForSelfBilling(PurchInvHeader), IncorrectValueErr);
    end;

    [Test]
    procedure PostingCreditMemoAppliedToSelfBillingInvoiceSetsSelfBilledType()
    var
        EDocument: Record "E-Document";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [E-Document] [Self-Billing]
        // [SCENARIO] Posting a purchase credit memo applied to a posted self-billing invoice
        // auto-creates an outbound e-document with the self-billed credit memo type.

        // [GIVEN] A self-billing invoice posted for a vendor with a self-billing agreement and both participant IDs
        Initialize();
        SetSelfBillingAgreement(Vendor, true);
        SeedParticipants();
        InvoiceNo := PostSelfBillingInvoice();

        // [GIVEN] A purchase credit memo applied to that invoice
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, Enum::"Purchase Document Type"::"Credit Memo", Vendor."No.", CreateItem(), 1, '', 0D);
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.Validate("Applies-to Doc. No.", InvoiceNo);
        PurchaseHeader.Modify(true);

        // [WHEN] The purchase credit memo is posted
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        PurchCrMemoHdr.Get(DocumentNo);

        // [THEN] An outbound e-document is created with the self-billed purchase credit memo type
        EDocument.SetRange("Document Record ID", PurchCrMemoHdr.RecordId());
        Assert.RecordIsNotEmpty(EDocument);
        EDocument.FindFirst();
        Assert.AreEqual(Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo", EDocument."Document Type", IncorrectValueErr);
    end;

    [Test]
    procedure PostingUnappliedCreditMemoIsNotSelfBilled()
    var
        EDocument: Record "E-Document";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [E-Document] [Self-Billing]
        // [SCENARIO] A purchase credit memo not applied to a self-billing invoice is not self-billed, even when
        // the vendor has a self-billing agreement — the vendor flag is not used to decide for credit memos.

        // [GIVEN] A vendor with a self-billing agreement and both participant IDs registered
        Initialize();
        SetSelfBillingAgreement(Vendor, true);
        SeedParticipants();

        LibraryLowerPermission.SetO365BusFull();
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, Enum::"Purchase Document Type"::"Credit Memo", Vendor."No.", CreateItem(), 1, '', 0D);

        // [WHEN] The purchase credit memo is posted without being applied to an invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        PurchCrMemoHdr.Get(DocumentNo);

        // [THEN] No e-document is auto-created for this posted credit memo
        EDocument.SetRange("Document Record ID", PurchCrMemoHdr.RecordId());
        Assert.RecordIsEmpty(EDocument);
    end;

    local procedure PostSelfBillingInvoice(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryLowerPermission.SetO365BusFull();
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, Enum::"Purchase Document Type"::Invoice, Vendor."No.", CreateItem(), 1, '', 0D);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure SetSelfBillingAgreement(var VendorToUpdate: Record Vendor; Agreement: Boolean)
    begin
        VendorToUpdate."Self-Billing Agreement" := Agreement;
        VendorToUpdate.Modify(true);
    end;

    local procedure SeedParticipants()
    begin
        InsertParticipant(Enum::"E-Document Source Type"::Vendor, Vendor."No.");
        InsertParticipant(Enum::"E-Document Source Type"::Company, '');
    end;

    local procedure InsertParticipant(ParticipantType: Enum "E-Document Source Type"; ParticipantNo: Code[20])
    var
        ServiceParticipant: Record "Service Participant";
    begin
        if ServiceParticipant.Get(EDocumentService.Code, ParticipantType, ParticipantNo) then
            ServiceParticipant.Delete();
        ServiceParticipant.Init();
        ServiceParticipant.Service := EDocumentService.Code;
        ServiceParticipant."Participant Type" := ParticipantType;
        ServiceParticipant.Participant := ParticipantNo;
        ServiceParticipant."Participant Identifier" := '1234567890128';
        ServiceParticipant.Insert(true);
    end;

    local procedure ClearParticipants()
    var
        ServiceParticipant: Record "Service Participant";
    begin
        ServiceParticipant.SetRange("Participant Type", Enum::"E-Document Source Type"::Vendor);
        ServiceParticipant.SetRange(Participant, Vendor."No.");
        ServiceParticipant.DeleteAll();

        ServiceParticipant.SetRange("Participant Type", Enum::"E-Document Source Type"::Company);
        ServiceParticipant.SetRange(Participant, '');
        ServiceParticipant.DeleteAll();
    end;

    local procedure Initialize()
    var
        Customer: Record Customer;
        DocumentSendingProfile: Record "Document Sending Profile";
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        BlankLocation: Record Location;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ServiceParticipant: Record "Service Participant";
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();

        if IsInitialized then
            exit;

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        ServiceParticipant.DeleteAll();
        EDocumentService.DeleteAll();

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock);

        // Setup vendor with document sending profile for self-billed purchase invoice export,
        // and a self-billing number series that posting requires once the agreement is enabled
        LibraryPurchase.CreateVendor(Vendor);
        DocumentSendingProfile.FindLast();
        Vendor."Document Sending Profile" := DocumentSendingProfile.Code;
        Vendor.Validate("Self-Billing Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        Vendor.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Posted Self-Billing Inv. Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        LibraryInventory.UpdateInventoryPostingSetup(BlankLocation);

        LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Self-Billed Purchase Invoice");
        LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo");

        IsInitialized := true;
    end;
}
