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
using System.Automation;
using System.Utilities;

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
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryWorkflow: Codeunit "Library - Workflow";
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

    [Test]
    procedure FutureFormatPostsInvoiceWithoutParticipants()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] Format "F" initiates and exports a non-UBL self-bill without participant rows.
        Initialize();

        // [GIVEN] V has a self-billing agreement and F has an explicit setup policy and outgoing capabilities.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");

        // [WHEN] PI is posted.
        PurchInvHeader.Get(PostSelfBillingInvoice());

        // [THEN] One self-billed E-Document contains F's native seller and pay-to facts.
        VerifySelfBillingExport(PurchInvHeader.RecordId(), Enum::"E-Document Type"::"Self-Billed Purchase Invoice", '');
    end;

    [Test]
    procedure FutureFormatPostsAppliedCreditWithoutParticipants()
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] Format "F" exports an applied self-billed credit without participant rows.
        Initialize();

        // [GIVEN] V uses F and has posted self-billed invoice PI.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        InvoiceNo := PostSelfBillingInvoice();

        // [WHEN] PC is posted against PI.
        PurchCrMemoHeader := PostPurchaseCreditMemo(InvoiceNo);

        // [THEN] F exports the credit and resolves PI through the public Core contract.
        VerifySelfBillingExport(PurchCrMemoHeader.RecordId(), Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo", InvoiceNo);
    end;

    [Test]
    [HandlerFunctions('EDocumentCreatedMessageHandler')]
    procedure FutureFormatManuallyCreatesInvoiceWithoutParticipants()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] The existing invoice action uses the configured format policy and prevents duplicates.
        Initialize();

        // [GIVEN] PI has no E-Document because legacy format L has no participants.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        PurchInvHeader.Get(PostSelfBillingInvoice());
        VerifyNoSelfBillingDocument(PurchInvHeader.RecordId());
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.GoToRecord(PurchInvHeader);
        Assert.IsTrue(PostedPurchaseInvoice.CreateEDocument.Enabled(), 'The explicit format policy must enable creation.');

        // [WHEN] The existing self-billing action is invoked.
        PostedPurchaseInvoice.CreateEDocument.Invoke();
        PostedPurchaseInvoice.GoToRecord(PurchInvHeader);

        // [THEN] F exports PI once and the duplicate guard disables the action.
        VerifySelfBillingExport(PurchInvHeader.RecordId(), Enum::"E-Document Type"::"Self-Billed Purchase Invoice", '');
        Assert.IsFalse(PostedPurchaseInvoice.CreateEDocument.Enabled(), 'A second E-Document must not be enabled.');
        PostedPurchaseInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('EDocumentCreatedMessageHandler')]
    procedure FutureFormatManuallyCreatesCreditWithoutParticipants()
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] The existing credit action permits an explicit participant-free format policy.
        Initialize();

        // [GIVEN] Applied PC has no E-Document because L has no participants.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        InvoiceNo := PostSelfBillingInvoice();
        PurchCrMemoHeader := PostPurchaseCreditMemo(InvoiceNo);
        VerifyNoSelfBillingDocument(PurchCrMemoHeader.RecordId());
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        PostedPurchaseCreditMemo.OpenView();
        PostedPurchaseCreditMemo.GoToRecord(PurchCrMemoHeader);
        Assert.IsTrue(PostedPurchaseCreditMemo.CreateEDocument.Enabled(), 'The explicit format policy must enable credit creation.');

        // [WHEN] The existing self-billing action is invoked.
        PostedPurchaseCreditMemo.CreateEDocument.Invoke();

        // [THEN] F exports PC with the applied invoice reference.
        VerifySelfBillingExport(PurchCrMemoHeader.RecordId(), Enum::"E-Document Type"::"Self-Billed Purch. Cr. Memo", InvoiceNo);
        PostedPurchaseCreditMemo.Close();
    end;

    [Test]
    procedure FutureFormatStillRequiresOutgoingCapability()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        SupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] An accepting policy cannot bypass an incoming-only capability.
        Initialize();

        // [GIVEN] F accepts setup but PI is configured only for incoming processing.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Self-Billed Purchase Invoice");
        SupportedType.Direction := SupportedType.Direction::Incoming;
        SupportedType.Modify();

        // [WHEN] PI is posted.
        PurchInvHeader.Get(PostSelfBillingInvoice());

        // [THEN] No outgoing E-Document is created.
        VerifyNoSelfBillingDocument(PurchInvHeader.RecordId());
    end;

    [Test]
    procedure FutureFormatRequiresExplicitCapability()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        SupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] A setup policy does not implicitly opt a service into self-billing.
        Initialize();

        // [GIVEN] F has no self-billed invoice capability row.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        SupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Self-Billed Purchase Invoice");
        SupportedType.Delete();

        // [WHEN] PI is posted.
        PurchInvHeader.Get(PostSelfBillingInvoice());

        // [THEN] No outgoing E-Document is created.
        VerifyNoSelfBillingDocument(PurchInvHeader.RecordId());
    end;

    [Test]
    procedure FuturePolicyCannotBypassExportEvaluator()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] An accepting format policy does not replace the service export evaluator.
        Initialize();

        // [GIVEN] F accepts setup but its service evaluator rejects export.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        EDocumentService."Export Eligibility Evaluator" := Enum::"Export Eligibility Evaluator"::"Self-Billing Veto Mock";
        EDocumentService.Modify(true);

        // [WHEN] PI is posted.
        PurchInvHeader.Get(PostSelfBillingInvoice());

        // [THEN] No E-Document is created.
        VerifyNoSelfBillingDocument(PurchInvHeader.RecordId());
    end;

    [Test]
    procedure DeniedPolicyIsAppliedWithLegacyParticipantsPresent()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] The legacy posting fast path cannot bypass a format's service setup policy.
        Initialize();

        // [GIVEN] Both legacy participants exist but F explicitly rejects its service setup.
        SetSelfBillingAgreement(Vendor, true);
        SeedParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Denied Mock");

        // [WHEN] PI is posted.
        PurchInvHeader.Get(PostSelfBillingInvoice());

        // [THEN] The service is excluded and no E-Document is created.
        VerifyNoSelfBillingDocument(PurchInvHeader.RecordId());
    end;

    [Test]
    procedure FutureServiceDoesNotActivateLegacyWorkflowService()
    var
        EDocument: Record "E-Document";
        LegacyService: Record "E-Document Service";
        ServiceStatus: Record "E-Document Service Status";
        DocumentSendingProfile: Record "Document Sending Profile";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] F cannot activate participant-dependent L in the same posting/workflow pipeline.
        Initialize();

        // [GIVEN] F and L share a workflow, but neither company nor V has participants.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        LibraryWorkflow.DisableAllWorkflows();
        LegacyService.Get(LibraryEDocument.CreateService(Enum::"Service Integration"::Mock));
        LibraryEDocument.AddEDocServiceSupportedType(LegacyService, Enum::"E-Document Type"::"Self-Billed Purchase Invoice");
        DocumentSendingProfile.Get(Vendor."Document Sending Profile");
        DocumentSendingProfile."Electronic Service Flow" :=
            LibraryEDocument.CreateFlowWithServices(DocumentSendingProfile.Code, EDocumentService.Code, LegacyService.Code);
        DocumentSendingProfile.Modify(true);

        // [WHEN] PI is posted and the existing created-flow job runs.
        PurchInvHeader.Get(PostSelfBillingInvoice());
        EDocument.SetRange("Document Record ID", PurchInvHeader.RecordId());
        EDocument.FindFirst();
        LibraryEDocument.RunEDocumentJobQueue(EDocument);

        // [THEN] Only F has a service status; the workflow cannot export L later.
        ServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        Assert.RecordCount(ServiceStatus, 1);
        ServiceStatus.SetRange("E-Document Service Code", LegacyService.Code);
        Assert.RecordIsEmpty(ServiceStatus);
    end;

    [Test]
    procedure ReExportDoesNotReapplyInitiationPolicy()
    var
        EDocument: Record "E-Document";
        PurchInvHeader: Record "Purch. Inv. Header";
        EDocExport: Codeunit "E-Doc. Export";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] Changing initiation setup does not add a new gate to an existing export retry.
        Initialize();

        // [GIVEN] F already exported PI, then its setup policy becomes rejecting.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        PurchInvHeader.Get(PostSelfBillingInvoice());
        EDocument.SetRange("Document Record ID", PurchInvHeader.RecordId());
        EDocument.FindFirst();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Denied Mock");

        // [WHEN] The existing raw retry API runs.
        EDocExport.Recreate(EDocument, EDocumentService);

        // [THEN] Native source validity still holds and PI can be exported.
        VerifySelfBillingExport(PurchInvHeader.RecordId(), Enum::"E-Document Type"::"Self-Billed Purchase Invoice", '');
    end;

    [Test]
    procedure InvalidRetryUsesExistingExportErrorBoundary()
    var
        EDocument: Record "E-Document";
        PurchInvHeader: Record "Purch. Inv. Header";
        ServiceStatus: Record "E-Document Service Status";
        EDocExport: Codeunit "E-Doc. Export";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] An invalid native source produces Export Error rather than bypassing normal logging.
        Initialize();

        // [GIVEN] PI was exported by F but its native flag no longer matches the stored E-Document type.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        PurchInvHeader.Get(PostSelfBillingInvoice());
        EDocument.SetRange("Document Record ID", PurchInvHeader.RecordId());
        EDocument.FindFirst();
        LibraryLowerPermission.SetOutsideO365Scope();
        PurchInvHeader."Self-Billing Invoice" := false;
        PurchInvHeader.Modify();

        // [WHEN] The existing raw retry API runs.
        EDocExport.Recreate(EDocument, EDocumentService);

        // [THEN] The guarded dispatch reports the failure using the normal service/document statuses.
        ServiceStatus.Get(EDocument."Entry No", EDocumentService.Code);
        Assert.AreEqual(ServiceStatus.Status::"Export Error", ServiceStatus.Status, IncorrectValueErr);
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(EDocument.Status::Error, EDocument.Status, IncorrectValueErr);
    end;

    [Test]
    procedure FuturePolicyCannotQualifyOrdinaryInvoiceOrItsCredit()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] An accepting format policy cannot turn ordinary purchases into self-bills.
        Initialize();

        // [GIVEN] F accepts setup, but PI is an ordinary purchase invoice.
        SetSelfBillingAgreement(Vendor, false);
        ClearParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        PurchInvHeader.Get(PostSelfBillingInvoice());

        // [WHEN] PC is posted against ordinary PI.
        PurchCrMemoHeader := PostPurchaseCreditMemo(PurchInvHeader."No.");

        // [THEN] Neither native source qualifies despite the permissive policy.
        VerifyNoSelfBillingDocument(PurchInvHeader.RecordId());
        VerifyNoSelfBillingDocument(PurchCrMemoHeader.RecordId());
    end;

    [Test]
    procedure FuturePolicyCannotQualifyUnappliedCredit()
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] A participant-free policy cannot bypass the original-invoice requirement.
        Initialize();

        // [GIVEN] V has a self-billing agreement and F accepts setup.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");

        // [WHEN] PC is posted without an applied invoice.
        PurchCrMemoHeader := PostPurchaseCreditMemo('');

        // [THEN] Native source validity prevents initiation.
        VerifyNoSelfBillingDocument(PurchCrMemoHeader.RecordId());
    end;

    [Test]
    procedure ExplicitInitiationPreservesDisabledWorkflowError()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        Workflow: Record Workflow;
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        // [FEATURE] [E-Document] [Self-Billing] [AI test 1.0]
        // [SCENARIO 637647] Explicit creation retains the existing selected-workflow validation error.
        Initialize();

        // [GIVEN] PI has no E-Document and its selected workflow is disabled after choosing F.
        SetSelfBillingAgreement(Vendor, true);
        ClearParticipants();
        PurchInvHeader.Get(PostSelfBillingInvoice());
        SetDocumentFormat(Enum::"E-Document Format"::"Self-Billing Mock");
        DocumentSendingProfile.Get(Vendor."Document Sending Profile");
        Workflow.Get(DocumentSendingProfile."Electronic Service Flow");
        Workflow.Enabled := false;
        Workflow.Modify(true);

        // [WHEN] Explicit manual initiation is attempted.
        asserterror EDocumentProcessing.CreateSelfBilledEDocumentFromPostedPage(PurchInvHeader, Enum::"E-Document Type"::"Self-Billed Purchase Invoice");

        // [THEN] The selected configuration error is not silently treated as a successful export.
        Assert.ExpectedError(Workflow.FieldCaption(Enabled));
        Assert.ExpectedErrorCode('TestField');
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
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        if IsInitialized then begin
            EDocumentService.Get(EDocumentService.Code);
            Vendor.Get(Vendor."No.");
            exit;
        end;

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

        // Keep the shared fixture when a later test error rolls back its transaction.
        Commit();
        IsInitialized := true;
    end;

    local procedure SetDocumentFormat(DocumentFormat: Enum "E-Document Format")
    begin
        EDocumentService.Get(EDocumentService.Code);
        EDocumentService.Validate("Document Format", DocumentFormat);
        EDocumentService.Modify(true);
    end;

    local procedure VerifySelfBillingExport(SourceRecordId: RecordId; DocumentType: Enum "E-Document Type"; OriginalInvoiceNo: Code[20])
    var
        EDocument: Record "E-Document";
        ServiceStatus: Record "E-Document Service Status";
        EDocumentLog: Codeunit "E-Document Log";
        TempBlob: Codeunit "Temp Blob";
        Payload: JsonObject;
        Token: JsonToken;
    begin
        EDocument.SetRange("Document Record ID", SourceRecordId);
        Assert.RecordCount(EDocument, 1);
        EDocument.FindFirst();
        Assert.AreEqual(DocumentType, EDocument."Document Type", IncorrectValueErr);
        ServiceStatus.Get(EDocument."Entry No", EDocumentService.Code);
        Assert.AreEqual(ServiceStatus.Status::Exported, ServiceStatus.Status, IncorrectValueErr);
        Assert.IsTrue(EDocumentLog.GetDocumentBlobFromLog(EDocument, EDocumentService, TempBlob, ServiceStatus.Status::Exported), 'An export log with the payload is required.');
        Payload.ReadFrom(TempBlob.CreateInStream(TextEncoding::UTF8));
        Payload.Get('service', Token);
        Assert.AreEqual(EDocumentService.Code, Token.AsValue().AsText(), IncorrectValueErr);
        Payload.Get('seller', Token);
        Assert.AreEqual(Vendor."No.", Token.AsValue().AsText(), IncorrectValueErr);
        Payload.Get('payTo', Token);
        Assert.AreEqual(Vendor."No.", Token.AsValue().AsText(), IncorrectValueErr);
        Payload.Get('documentType', Token);
        Assert.AreEqual(DocumentType.AsInteger(), Token.AsValue().AsInteger(), IncorrectValueErr);
        if OriginalInvoiceNo <> '' then begin
            Payload.Get('originalInvoice', Token);
            Assert.AreEqual(OriginalInvoiceNo, Token.AsValue().AsText(), IncorrectValueErr);
        end;
    end;

    local procedure VerifyNoSelfBillingDocument(SourceRecordId: RecordId)
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetRange("Document Record ID", SourceRecordId);
        Assert.RecordIsEmpty(EDocument);
    end;

    local procedure PostPurchaseCreditMemo(InvoiceNo: Code[20]) PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr."
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryLowerPermission.SetO365BusFull();
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, Enum::"Purchase Document Type"::"Credit Memo", Vendor."No.", CreateItem(), 1, '', 0D);
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.Validate("Applies-to Doc. No.", InvoiceNo);
        PurchaseHeader.Modify(true);
        PurchCrMemoHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
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

    [MessageHandler]
    procedure EDocumentCreatedMessageHandler(MessageText: Text[1024])
    begin
    end;
}
