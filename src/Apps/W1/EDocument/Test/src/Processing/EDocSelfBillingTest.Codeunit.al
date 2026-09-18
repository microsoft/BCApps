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
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 139791 "E-Doc. Self-Billing Test"
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
    procedure EligibilityRequiresAgreementAndBothParticipants()
    var
        EDocumentSubscribers: Codeunit "E-Document Subscribers";
    begin
        // [FEATURE] [E-Document] [Self-Billing]
        // [SCENARIO] IsEligibleForSelfBilling requires the vendor agreement flag AND both the
        // vendor's and the company's participant IDs to be registered — any one missing disqualifies.

        // [GIVEN] A vendor with no self-billing agreement and no participants — reset both
        // explicitly rather than relying on default/absent state. Initialize()'s own cleanup only
        // runs once per session (guarded by IsInitialized), so if an earlier test in this run
        // already posted a self-billed invoice for this same vendor, that posting COMMITTED
        // (BC posting routines always commit internally) and permanently persisted both the
        // agreement flag and the participant rows — this test must not assume they're absent.
        Initialize();
        SetSelfBillingAgreement(Vendor, false);
        ClearParticipants();

        // [THEN] Not eligible: agreement off, no participants
        Assert.IsFalse(EDocumentSubscribers.IsEligibleForSelfBilling(Vendor."No."), IncorrectValueErr);

        // [GIVEN] Agreement on, but still no participants
        SetSelfBillingAgreement(Vendor, true);
        // [THEN] Still not eligible
        Assert.IsFalse(EDocumentSubscribers.IsEligibleForSelfBilling(Vendor."No."), IncorrectValueErr);

        // [GIVEN] Only the vendor participant registered (company participant still missing)
        InsertParticipant(Enum::"E-Document Source Type"::Vendor, Vendor."No.");
        // [THEN] Still not eligible
        Assert.IsFalse(EDocumentSubscribers.IsEligibleForSelfBilling(Vendor."No."), IncorrectValueErr);

        // [GIVEN] The company participant is registered too
        InsertParticipant(Enum::"E-Document Source Type"::Company, '');
        // [THEN] Now eligible
        Assert.IsTrue(EDocumentSubscribers.IsEligibleForSelfBilling(Vendor."No."), IncorrectValueErr);

        // [GIVEN] Agreement turned back off
        SetSelfBillingAgreement(Vendor, false);
        // [THEN] Not eligible even with both participants present
        Assert.IsFalse(EDocumentSubscribers.IsEligibleForSelfBilling(Vendor."No."), IncorrectValueErr);
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
        ServiceParticipant: Record "Service Participant";
        LibraryEDoc: Codeunit "Library - E-Document";
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

        // Setup vendor with document sending profile for self-billed purchase invoice export
        LibraryPurchase.CreateVendor(Vendor);
        DocumentSendingProfile.FindLast();
        Vendor."Document Sending Profile" := DocumentSendingProfile.Code;
        Vendor.Modify(true);

        LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Self-Billed Purchase Invoice");
        LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo");

        IsInitialized := true;
    end;
}
