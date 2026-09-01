// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Threading;
using System.Utilities;

codeunit 148151 "FR E-Invoice Message Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    Permissions = tabledata "Cust. Ledger Entry" = rimd,
                  tabledata "Detailed Cust. Ledg. Entry" = rimd,
                  tabledata "E-Document" = rimd,
                  tabledata "E-Document Service" = rimd,
                  tabledata "E-Document Service Status" = rimd,
                  tabledata "E-Doc. Payment Occurrence" = rimd,
                  tabledata "FR E-Invoice Message" = rimd,
                  tabledata "FR E-Invoice Message VAT" = r,
                  tabledata "General Ledger Setup" = rm,
                  tabledata "Company Information" = rm,
                  tabledata "Sales Invoice Header" = rimd,
                  tabledata "Sales Invoice Line" = rimd,
                  tabledata "VAT Entry" = rimd;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    procedure PaymentApplicationCreatesCollectedPayload()
    var
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Payload: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Applying a payment to an approved French E-Document creates a Collected message
        Initialize();

        // [GIVEN] An approved outgoing French E-Document with an applied customer payment
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment application is processed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] One Collected lifecycle message and one generic payment occurrence are created with the expected payload
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 1);
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
        EDocPaymentOccurrence.FindFirst();
        Assert.AreEqual(120, EDocPaymentOccurrence.Amount, 'The generic applied occurrence must carry a positive amount.');
        FREInvoiceMessage.FindFirst();
        Payload := BuildMessagePayload(EDocument, FREInvoiceMessage);
        AssertPayloadStatus(Payload, '212');
        AssertPayloadAmount(Payload, 120, 'EUR');
        AssertPayloadDateFormat(Payload, '204');
    end;

    [Test]
    procedure PaymentApplicationForClearedDocumentCreatesCollected()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Applying a payment to a cleared French E-Document creates a Collected message
        Initialize();

        // [GIVEN] A cleared outgoing French E-Document with an applied customer payment
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Cleared);

        // [WHEN] The payment application is processed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] One Collected lifecycle message is created for the E-Document
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 1);
    end;

    [Test]
    procedure PostedPaymentCreatesDurableOccurrence()
    var
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Posting an applied customer payment creates a durable payment occurrence
        Initialize();

        // [GIVEN] A posted sales invoice represented by an approved French E-Document
        CreatePostedPaymentScenario(EDocument, DetailedCustLedgEntry);

        // [WHEN] The customer payment is posted by the scenario

        // [THEN] Posting succeeds and the subscriber persists one payment occurrence
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange("Source Occurrence ID", DetailedCustLedgEntry.SystemId);
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
    end;

    [Test]
    procedure PaymentApplicationForSentDocumentDoesNotCreateCollected()
    var
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Applying a payment to a sent French E-Document does not create a Collected message
        Initialize();

        // [GIVEN] A sent outgoing French E-Document with an applied customer payment
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Sent);

        // [WHEN] The payment application is processed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] The generic payment occurrence is created but no French lifecycle message is created
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 0);
    end;

    [Test]
    procedure PaymentLifecycleFailureDoesNotBlockApplicationAndCanBeRetried()
    var
        CompanyInformation: Record "Company Information";
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Invalid optional lifecycle configuration does not block a payment and its occurrence can be retried
        Initialize();

        // [GIVEN] An eligible French payment whose issuer registration number is invalid
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);
        CompanyInformation.Get();
        CompanyInformation."Registration No." := 'INVALID';
        CompanyInformation.Modify();

        // [WHEN] The payment application is processed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] The payment occurrence remains persisted and no incomplete French message is created
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
        EDocPaymentOccurrence.FindFirst();
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 0);

        // [WHEN] The configuration is repaired and the persisted occurrence is retried
        EnsureCompanyInformation();
        RunPaymentOccurrence(EDocPaymentOccurrence);

        // [THEN] The French lifecycle message is created from the original occurrence
        Assert.RecordCount(FREInvoiceMessage, 1);
    end;

    [Test]
    procedure PaymentUnapplicationCreatesLinkedNegativeCollected()
    var
        EDocument: Record "E-Document";
        CollectedMessage: Record "FR E-Invoice Message";
        AppliedOccurrence: Record "E-Doc. Payment Occurrence";
        NegativeMessage: Record "FR E-Invoice Message";
        ReversedOccurrence: Record "E-Doc. Payment Occurrence";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Payload: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Unapplying a payment creates a negative Collected message linked to the original
        Initialize();

        // [GIVEN] An approved E-Document with a Collected message
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);
        CollectedMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedMessage.SetRange(Type, CollectedMessage.Type::Collected);
        CollectedMessage.FindFirst();
        CreateDetailedLedgerEntry(NewDetailedCustLedgEntry, DetailedCustLedgEntry."Cust. Ledger Entry No.", DetailedCustLedgEntry."Applied Cust. Ledger Entry No.", -120);

        // [WHEN] The payment is unapplied
        ProcessPaymentUnapplication(EDocument, DetailedCustLedgEntry, NewDetailedCustLedgEntry);

        // [THEN] A Negative Collected message linked to the original is created;
        NegativeMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        NegativeMessage.SetRange(Type, NegativeMessage.Type::"Negative Collected");
        NegativeMessage.FindFirst();
        Assert.AreEqual(CollectedMessage."Entry No.", NegativeMessage."Original Entry No.", 'The reversal must link to the original occurrence.');
        Assert.AreEqual(-CollectedMessage.Amount, NegativeMessage.Amount, 'The reversal amount must negate the original amount.');
        AppliedOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        AppliedOccurrence.SetRange(Type, AppliedOccurrence.Type::Applied);
        AppliedOccurrence.FindFirst();
        ReversedOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        ReversedOccurrence.SetRange(Type, ReversedOccurrence.Type::Reversed);
        ReversedOccurrence.FindFirst();
        Assert.AreEqual(AppliedOccurrence."Entry No.", ReversedOccurrence."Original Occurrence Entry No.", 'The generic reversal must link to its applied occurrence.');
        Assert.AreEqual(-AppliedOccurrence.Amount, ReversedOccurrence.Amount, 'The generic reversal must negate the applied amount.');
        Payload := BuildMessagePayload(EDocument, NegativeMessage);
        AssertPayloadAmount(Payload, -120, 'EUR');
    end;

    [Test]
    procedure RefusalCreatesStatusAndReasonPayload()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
        Payload: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Refusing an invoice creates a lifecycle message with status 210 and reason code
        Initialize();

        // [GIVEN] An incoming French E-Document
        CreateIncomingEDocument(EDocument);

        // [WHEN] The invoice is refused with a reason
        FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'PRICE', 'The amount is incorrect.');

        // [THEN] A refusal message with status 210 and the reason code is queued
        FindMessage(FREInvoiceMessage, EDocument, "FR E-Invoice Message Type"::Refused);
        Assert.AreEqual("E-Doc. Response Type"::Refused, EDocumentMessageAPI.GetMessageResponseType(FREInvoiceMessage."E-Document Message Entry No."), 'The child message must be Refused.');
        Payload := BuildMessagePayload(EDocument, FREInvoiceMessage);
        AssertPayloadStatus(Payload, '210');
        AssertPayloadReasonCode(Payload, 'PRICE');
    end;

    [Test]
    procedure RefusalWithoutReasonCreatesStatusWithoutReasonElements()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
        Payload: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A buyer can refuse an invoice without providing a reason
        Initialize();

        // [GIVEN] An incoming French purchase invoice
        CreateIncomingEDocument(EDocument);

        // [WHEN] The invoice is refused without a reason code or description
        FREInvoiceMessageMgt.RefuseInvoice(EDocument, '', '');

        // [THEN] The refusal payload has status 210 without empty reason elements
        FindMessage(FREInvoiceMessage, EDocument, "FR E-Invoice Message Type"::Refused);
        Payload := BuildMessagePayload(EDocument, FREInvoiceMessage);
        AssertPayloadStatus(Payload, '210');
        AssertPayloadHasNoReason(Payload);
    end;

    [Test]
    procedure PaymentApplicationReplayIsIdempotent()
    var
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Processing the same payment application twice is idempotent
        Initialize();

        // [GIVEN] An approved French E-Document with an applied payment
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment application is processed twice
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] Only one payment occurrence and one Collected message exist;
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 1);
    end;

    [Test]
    procedure CollectedMessageFreezesSenderPlatform()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] A Collected message retains the sender-platform identity captured from its service
        Initialize();

        // [GIVEN] An eligible payment and a French service with sender-platform identity
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment is processed and the service identity is subsequently changed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);
        EDocumentService.Get(EDocument.Service);
        EDocumentService."FR Sender Platform ID" := 'CHANGED-PLATFORM';
        EDocumentService."FR Sender Platform Scheme" := '9999';
        EDocumentService."FR Sender Platform Name" := 'Changed Platform';
        EDocumentService.Modify();

        // [THEN] The message retains the original platform values
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        FREInvoiceMessage.FindFirst();
        Assert.AreEqual('TEST-PLATFORM', FREInvoiceMessage."Sender Platform ID", 'The sender-platform ID must be frozen at capture.');
        Assert.AreEqual('0238', FREInvoiceMessage."Sender Platform Scheme", 'The sender-platform scheme must be frozen at capture.');
        Assert.AreEqual('Test Platform', FREInvoiceMessage."Sender Platform Name", 'The sender-platform name must be frozen at capture.');
        Assert.AreEqual(EDocument."Document Date", FREInvoiceMessage."Invoice Issue Date", 'The invoice issue date must be frozen at capture.');
        Assert.AreEqual(EDocument."Clearance Date", FREInvoiceMessage."Invoice Receipt At", 'The platform receipt time must be frozen at capture.');
        Assert.AreEqual('123456789', FREInvoiceMessage."Invoice Issuer ID", 'The invoice issuer ID must be frozen at capture.');
        Assert.AreEqual('0002', FREInvoiceMessage."Invoice Issuer Scheme", 'The invoice issuer scheme must identify SIREN.');
        Assert.AreEqual('FR Test Issuer', FREInvoiceMessage."Invoice Issuer Name", 'The invoice issuer name must be frozen at capture.');
    end;

    [Test]
    procedure CollectedMessageEmitsCompletePPFContext()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Payload: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] A Collected message emits the complete PPF platform context
        Initialize();

        // [GIVEN] An eligible payment and a French service with sender-platform identity
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment is processed and its lifecycle payload is built
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        FREInvoiceMessage.FindFirst();
        Payload := BuildMessagePayload(EDocument, FREInvoiceMessage);

        // [THEN] The payload contains the PPF profile, sender, issuer, recipient, and invoice dates
        AssertPayloadPPFContext(Payload, EDocument);
    end;

    [Test]
    procedure CollectedMessageAllowsMissingSenderPlatformIdentity()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] A Collected message supports a service without optional sender-platform identity
        Initialize();

        // [GIVEN] An eligible payment whose service has no sender-platform ID
        CreatePaymentScenarioWithoutSenderPlatform(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment is processed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] The message is created with no frozen platform identity
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        FREInvoiceMessage.FindFirst();
        Assert.AreEqual('', FREInvoiceMessage."Sender Platform ID", 'The optional sender-platform ID must remain blank.');
    end;

    [Test]
    procedure CollectedMessageWithoutPlatformUsesCDVProfile()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Payload: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] A Collected message without platform identity retains the CDV profile
        Initialize();

        // [GIVEN] An eligible payment whose service has no sender-platform identity
        CreatePaymentScenarioWithoutSenderPlatform(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment is processed and its lifecycle payload is built
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        FREInvoiceMessage.FindFirst();
        Payload := BuildMessagePayload(EDocument, FREInvoiceMessage);

        // [THEN] The payload uses the CDV profile and does not contain PPF trade parties
        AssertPayloadCDVContext(Payload);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SingleRateFullPaymentCreatesOneVATRow()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Payload: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Single-rate full payment creates one frozen VAT row summing to reportable amount
        Initialize();

        // [GIVEN] An approved French E-Document with unrealized VAT at 20% and a full payment applied
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment application is processed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] One VAT row is created with amount equal to the message amount and the XML includes amount and rate
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        FREInvoiceMessage.FindFirst();
        FREInvoiceMessageVAT.SetRange("Message Entry No.", FREInvoiceMessage."Entry No.");
        Assert.RecordCount(FREInvoiceMessageVAT, 1);
        FREInvoiceMessageVAT.FindFirst();
        Assert.AreEqual(FREInvoiceMessage.Amount, FREInvoiceMessageVAT.Amount, 'VAT row amount must equal message amount.');
        Assert.AreEqual(20, FREInvoiceMessageVAT."VAT %", 'VAT rate must match the posting setup.');
        Assert.AreEqual('S', Format(FREInvoiceMessageVAT."VAT Category Code"), 'VAT category must be standard.');
        Payload := BuildMessagePayload(EDocument, FREInvoiceMessage);
        AssertPayloadVATCharacteristic(Payload, FREInvoiceMessage.Amount, 20);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SingleRatePartialPaymentAllocatesPartialAmount()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Single-rate partial payment allocates partial amount
        Initialize();

        // [GIVEN] An approved French E-Document with unrealized VAT at 20% and a partial payment of 60 applied
        CreatePaymentScenarioWithAmount(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved, 60);

        // [WHEN] The payment application is processed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] The message amount and VAT row reflect the partial payment
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        FREInvoiceMessage.FindFirst();
        Assert.AreEqual(60, FREInvoiceMessage.Amount, 'Message amount must equal the partial payment.');
        FREInvoiceMessageVAT.SetRange("Message Entry No.", FREInvoiceMessage."Entry No.");
        Assert.RecordCount(FREInvoiceMessageVAT, 1);
        FREInvoiceMessageVAT.FindFirst();
        Assert.AreEqual(60, FREInvoiceMessageVAT.Amount, 'VAT row must carry the full partial payment.');
    end;

    [Test]
    procedure MixedInvoiceReportsProportionalEligibleShare()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Mixed invoice with unrealized and realized VAT reports only proportional eligible share
        Initialize();

        // [GIVEN] An invoice with one unrealized-VAT line (20%, gross 120) and one realized-VAT line (10%, gross 110), full payment of 230
        CreateMixedVATPaymentScenario(EDocument, DetailedCustLedgEntry);
        Commit();
        // [WHEN] The payment application is processed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] The message amount reflects only the eligible gross share
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        FREInvoiceMessage.FindFirst();
        Assert.AreEqual(120, FREInvoiceMessage.Amount, 'Amount must reflect only the eligible gross share.');
        FREInvoiceMessageVAT.SetRange("Message Entry No.", FREInvoiceMessage."Entry No.");
        Assert.RecordCount(FREInvoiceMessageVAT, 1);
        FREInvoiceMessageVAT.FindFirst();
        Assert.AreEqual(20, FREInvoiceMessageVAT."VAT %", 'Only the unrealized VAT rate must appear.');
    end;

    [Test]
    procedure MultiRatePaymentWithRoundingStoresExactSum()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        VATRowSum: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Multiple eligible VAT rates with rounding residue sum exactly to message amount
        Initialize();

        // [GIVEN] An invoice with three unrealized VAT rates (10%, 20%, 7%) and a partial payment of 99 causing rounding residue
        CreateMultiRatePaymentScenario(EDocument, DetailedCustLedgEntry);
        Commit();
        // [WHEN] The payment application is processed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] The sum of VAT rows equals the message amount deterministically
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        FREInvoiceMessage.FindFirst();
        FREInvoiceMessageVAT.SetRange("Message Entry No.", FREInvoiceMessage."Entry No.");
        Assert.RecordCount(FREInvoiceMessageVAT, 3);
        FREInvoiceMessageVAT.FindSet();
        repeat
            VATRowSum += FREInvoiceMessageVAT.Amount;
        until FREInvoiceMessageVAT.Next() = 0;
        Assert.AreEqual(FREInvoiceMessage.Amount, VATRowSum, 'Sum of VAT rows must equal message amount deterministically.');
    end;

    [Test]
    procedure InvoiceWithoutUnrealizedVATCreatesNoCollected()
    var
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Invoice without unrealized VAT keeps generic payment occurrence but creates no FR Collected message
        Initialize();

        // [GIVEN] An approved French E-Document with ordinary (non-unrealized) VAT and an applied payment
        CreateNormalVATPaymentScenario(EDocument, DetailedCustLedgEntry);

        // [WHEN] The payment application is processed
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] A generic payment occurrence exists but no Collected message is created
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 0);
    end;

    [Test]
    procedure ReversalCopiesFrozenRowsWithNegatedValues()
    var
        CompanyInformation: Record "Company Information";
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        CollectedMessage: Record "FR E-Invoice Message";
        NegativeMessage: Record "FR E-Invoice Message";
        OriginalVAT: Record "FR E-Invoice Message VAT";
        ReversalVAT: Record "FR E-Invoice Message VAT";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Reversal copies original frozen rows with negated values even if VAT setup changes after original
        Initialize();

        // [GIVEN] A collected message with a frozen VAT breakdown
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);
        CollectedMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedMessage.SetRange(Type, CollectedMessage.Type::Collected);
        CollectedMessage.FindFirst();
        OriginalVAT.SetRange("Message Entry No.", CollectedMessage."Entry No.");
        OriginalVAT.FindFirst();

        // [GIVEN] VAT and sender-platform setup are changed after the original message
        SalesInvoiceLine.SetRange("Document No.", EDocument."Document No.");
        SalesInvoiceLine.FindFirst();
        VATPostingSetup.Get(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group");
        VATPostingSetup."Tax Category" := 'Z';
        VATPostingSetup.Modify();
        EDocumentService.Get(EDocument.Service);
        EDocumentService."FR Sender Platform ID" := 'CHANGED-PLATFORM';
        EDocumentService."FR Sender Platform Scheme" := '9999';
        EDocumentService."FR Sender Platform Name" := 'Changed Platform';
        EDocumentService.Modify();
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '987654321';
        CompanyInformation.Name := 'Changed Issuer';
        CompanyInformation.Modify();

        // [WHEN] The payment is unapplied
        CreateDetailedLedgerEntry(NewDetailedCustLedgEntry, DetailedCustLedgEntry."Cust. Ledger Entry No.", DetailedCustLedgEntry."Applied Cust. Ledger Entry No.", -120);
        ProcessPaymentUnapplication(EDocument, DetailedCustLedgEntry, NewDetailedCustLedgEntry);

        // [THEN] The reversal has the original frozen rate and negated amount
        NegativeMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        NegativeMessage.SetRange(Type, NegativeMessage.Type::"Negative Collected");
        NegativeMessage.FindFirst();
        Assert.AreEqual(-CollectedMessage.Amount, NegativeMessage.Amount, 'Reversal amount must negate the original.');
        Assert.IsTrue(NegativeMessage.Amount < 0, 'Reversal message amount must be negative.');
        ReversalVAT.SetRange("Message Entry No.", NegativeMessage."Entry No.");
        ReversalVAT.FindFirst();
        Assert.AreEqual(-OriginalVAT.Amount, ReversalVAT.Amount, 'Reversal VAT amount must negate the original.');
        Assert.AreEqual(OriginalVAT."VAT %", ReversalVAT."VAT %", 'Reversal must use frozen original rate not current setup.');
        Assert.AreEqual('S', Format(OriginalVAT."VAT Category Code"), 'Original category must be the original value.');
        Assert.AreEqual(OriginalVAT."VAT Category Code", ReversalVAT."VAT Category Code", 'Reversal must preserve frozen original category.');
        Assert.AreEqual(CollectedMessage."Sender Platform ID", NegativeMessage."Sender Platform ID", 'Reversal must preserve the original sender-platform ID.');
        Assert.AreEqual(CollectedMessage."Sender Platform Scheme", NegativeMessage."Sender Platform Scheme", 'Reversal must preserve the original sender-platform scheme.');
        Assert.AreEqual(CollectedMessage."Sender Platform Name", NegativeMessage."Sender Platform Name", 'Reversal must preserve the original sender-platform name.');
        Assert.AreEqual(CollectedMessage."Invoice Issue Date", NegativeMessage."Invoice Issue Date", 'Reversal must preserve the original invoice issue date.');
        Assert.AreEqual(CollectedMessage."Invoice Receipt At", NegativeMessage."Invoice Receipt At", 'Reversal must preserve the original platform receipt time.');
        Assert.AreEqual(CollectedMessage."Invoice Issuer ID", NegativeMessage."Invoice Issuer ID", 'Reversal must preserve the original invoice issuer ID.');
        Assert.AreEqual(CollectedMessage."Invoice Issuer Scheme", NegativeMessage."Invoice Issuer Scheme", 'Reversal must preserve the original invoice issuer scheme.');
        Assert.AreEqual(CollectedMessage."Invoice Issuer Name", NegativeMessage."Invoice Issuer Name", 'Reversal must preserve the original invoice issuer name.');
    end;

    [Test]
    procedure ReplayDoesNotDuplicateAllocationRows()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Replay is idempotent and does not duplicate allocation rows
        Initialize();

        // [GIVEN] An approved French E-Document with unrealized VAT
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment application is processed twice
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);
        ProcessPaymentApplication(EDocument, DetailedCustLedgEntry);

        // [THEN] Only one message and one VAT row exist
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 1);
        FREInvoiceMessage.FindFirst();
        FREInvoiceMessageVAT.SetRange("Message Entry No.", FREInvoiceMessage."Entry No.");
        Assert.RecordCount(FREInvoiceMessageVAT, 1);
    end;

    [Test]
    procedure IncomingMessageForOutgoingDocumentIsCorrelatedAndDeduplicated()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocumentID: Text[250];
        ExternalMessageID: Text[250];
        FirstMessageEntryNo: Integer;
        DuplicateMessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] An incoming lifecycle message is correlated to its E-Document and deduplicated by external ID
        Initialize();

        // [GIVEN] An outgoing E-Document with a registered external document reference
        CreateOutgoingEDocument(EDocument);
        ExternalDocumentID := RegisterExternalDocumentReference(EDocument);
        ExternalMessageID := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ExternalMessageID));
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');

        // [WHEN] The same incoming message is received twice
        FirstMessageEntryNo := EDocumentMessageAPI.CreateIncomingMessage(
            EDocument.Service, ExternalDocumentID, ExternalMessageID, "E-Document Message Type"::"FR Invoice Lifecycle",
            "E-Doc. Response Type"::Refused, CurrentDateTime(), TempBlob);
        DuplicateMessageEntryNo := EDocumentMessageAPI.CreateIncomingMessage(
            EDocument.Service, ExternalDocumentID, ExternalMessageID, "E-Document Message Type"::"FR Invoice Lifecycle",
            "E-Doc. Response Type"::Refused, CurrentDateTime(), TempBlob);

        // [THEN] The incoming message is persisted and deduplicated
        Assert.AreNotEqual(0, FirstMessageEntryNo, 'The incoming lifecycle message must be persisted.');
        Assert.AreEqual(FirstMessageEntryNo, DuplicateMessageEntryNo, 'The external message ID must deduplicate repeated delivery.');
    end;

    [Test]
    procedure IncomingMessageRequiresRegisteredDocumentReference()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Creating an incoming message fails when the external document reference is not registered
        Initialize();

        // [GIVEN] An incoming E-Document without a registered external document reference
        CreateIncomingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');

        // [WHEN] An incoming message with an unregistered external document ID is created
        asserterror EDocumentMessageAPI.CreateIncomingMessage(
            EDocument.Service, CopyStr(Format(CreateGuid()), 1, 250), CopyStr(Format(CreateGuid()), 1, 250),
            "E-Document Message Type"::"FR Invoice Lifecycle", "E-Doc. Response Type"::Refused, CurrentDateTime(), TempBlob);

        // [THEN] An error about unregistered reference is raised
        Assert.ExpectedError('is not registered');
    end;

    [Test]
    procedure BuyerAcceptanceQueuesStatus205()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
        Payload: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Accepting an invoice queues an Accepted message with status 205
        Initialize();

        // [GIVEN] An incoming French E-Document
        CreateIncomingEDocument(EDocument);

        // [WHEN] The invoice is accepted
        FREInvoiceMessageMgt.AcceptInvoice(EDocument);

        // [THEN] An Accepted message with status 205 is queued
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Accepted);
        Assert.RecordCount(FREInvoiceMessage, 1);
        FREInvoiceMessage.FindFirst();
        Assert.AreEqual("E-Doc. Response Type"::Accepted, EDocumentMessageAPI.GetMessageResponseType(FREInvoiceMessage."E-Document Message Entry No."), 'The child message must be Accepted.');
        Payload := BuildMessagePayload(EDocument, FREInvoiceMessage);
        AssertPayloadStatus(Payload, '205');
    end;

    [Test]
    procedure BuyerResponseCannotBeRepeated()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A buyer response cannot follow a previous acceptance
        Initialize();

        // [GIVEN] An incoming E-Document that has been accepted
        CreateIncomingEDocument(EDocument);
        FREInvoiceMessageMgt.AcceptInvoice(EDocument);

        // [WHEN] A refusal is attempted after acceptance
        asserterror FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'OTHER', 'Changed my mind.');

        // [THEN] An error about duplicate buyer response is raised;
        Assert.ExpectedError('already has a buyer response');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure BuyerResponseCannotBeRepeatedAfterRefusal()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A buyer response cannot follow a previous refusal
        Initialize();

        // [GIVEN] An incoming E-Document that has been refused
        CreateIncomingEDocument(EDocument);
        FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'OTHER', 'Not accepted.');

        // [WHEN] An acceptance is attempted after refusal
        asserterror FREInvoiceMessageMgt.AcceptInvoice(EDocument);

        // [THEN] An error about duplicate buyer response is raised;
        Assert.ExpectedError('already has a buyer response');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveSubmittedPersistsNormalizedMessage()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
        ExternalMsgID: Text[250];
        ReceivedAt: DateTime;
        FREntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Receiving a Submitted lifecycle message persists a normalized FR message
        Initialize();

        // [GIVEN] An outgoing E-Document with a registered external document reference and a Submitted lifecycle payload
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        ReceivedAt := CreateDateTime(20260101D, 120000T);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Submitted', '', ''));

        // [WHEN] The Submitted lifecycle message is received
        FREntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, ReceivedAt, TempBlob);

        // [THEN] The FR message is persisted with Submitted type and correct metadata
        FREInvoiceMessage.Get(FREntryNo);
        Assert.AreEqual(FREInvoiceMessage.Type::Submitted, FREInvoiceMessage.Type, 'FR type must be Submitted.');
        Assert.AreEqual(ExternalMsgID, FREInvoiceMessage."External Message ID", 'External message ID must be stored.');
        Assert.AreEqual(ReceivedAt, FREInvoiceMessage."Received At", 'Received timestamp must be persisted.');
        Assert.AreEqual("E-Document Direction"::Incoming, EDocumentMessageAPI.GetMessageDirection(FREInvoiceMessage."E-Document Message Entry No."), 'Generic message must be Incoming.');
        Assert.AreEqual("E-Doc. Message Status"::Received, EDocumentMessageAPI.GetMessageStatus(FREInvoiceMessage."E-Document Message Entry No."), 'Generic message status must be Received.');
        Assert.AreEqual("E-Doc. Response Type"::Submitted, EDocumentMessageAPI.GetMessageResponseType(FREInvoiceMessage."E-Document Message Entry No."), 'Generic response must be Submitted.');
    end;

    [Test]
    procedure ReceiveAcceptedPersistsNormalizedMessage()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
        ExternalMsgID: Text[250];
        FREntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Receiving an Accepted lifecycle message persists a normalized FR message
        Initialize();

        // [GIVEN] An outgoing E-Document with a received Submitted status and an Accepted lifecycle payload
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Submitted', '', '');
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", '205', '', ''));

        // [WHEN] The Accepted lifecycle message is received
        FREntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);

        // [THEN] The FR message is persisted with Accepted type
        FREInvoiceMessage.Get(FREntryNo);
        Assert.AreEqual(FREInvoiceMessage.Type::Accepted, FREInvoiceMessage.Type, 'FR type must be Accepted.');
        Assert.AreEqual("E-Doc. Response Type"::Accepted, EDocumentMessageAPI.GetMessageResponseType(FREInvoiceMessage."E-Document Message Entry No."), 'Generic response must be Accepted.');
    end;

    [Test]
    procedure ReceiveTechnicalRejectedPersistsReason()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
        ExternalMsgID: Text[250];
        FREntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Receiving a Technical Rejected lifecycle message persists the reason code and description
        Initialize();

        // [GIVEN] An outgoing E-Document with a received Submitted status and a Rejected lifecycle payload with reason
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Submitted', '', '');
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Rejetée', 'SCHEMA', 'Schema validation failed'));

        // [WHEN] The Rejected lifecycle message is received
        FREntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);

        // [THEN] The FR message is persisted with Technical Rejected type and reason
        FREInvoiceMessage.Get(FREntryNo);
        Assert.AreEqual(FREInvoiceMessage.Type::"Technical Rejected", FREInvoiceMessage.Type, 'FR type must be Technical Rejected.');
        Assert.AreEqual('SCHEMA', Format(FREInvoiceMessage."Reason Code"), 'Reason code must be persisted.');
        Assert.AreEqual('Schema validation failed', FREInvoiceMessage."Reason Description", 'Reason description must be persisted.');
        Assert.AreEqual("E-Doc. Response Type"::Rejected, EDocumentMessageAPI.GetMessageResponseType(FREInvoiceMessage."E-Document Message Entry No."), 'Generic response must be Rejected.');
    end;

    [Test]
    procedure ReceiveMessageIsIdempotent()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
        ExternalMsgID: Text[250];
        FirstEntryNo: Integer;
        SecondEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Receiving the same lifecycle message twice returns the same entry
        Initialize();

        // [GIVEN] An outgoing E-Document with a registered external document reference
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Submitted', '', ''));

        // [WHEN] The same lifecycle message is received twice
        FirstEntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Submitted', '', ''));
        SecondEntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);

        // [THEN] The same FR entry is returned and only one Submitted message exists
        Assert.AreEqual(FirstEntryNo, SecondEntryNo, 'Same external message ID must return same FR entry.');
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Submitted);
        Assert.RecordCount(FREInvoiceMessage, 1);
    end;

    [Test]
    procedure ReceiveMessageRejectsInvalidXml()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Receiving a lifecycle message with invalid XML raises an error
        Initialize();

        // [GIVEN] An outgoing E-Document with a registered reference and invalid XML payload
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('not xml at all');

        // [WHEN] The invalid message is received
        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        // [THEN] An error about invalid XML is raised;
        Assert.ExpectedError('not valid XML');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveMessageRejectsUnsupportedStatus()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Receiving a lifecycle message with an unsupported status raises an error
        Initialize();

        // [GIVEN] An outgoing E-Document with a lifecycle payload containing an unknown status
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Unknown', '', ''));

        // [WHEN] The message with unsupported status is received
        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        // [THEN] An error about unsupported status is raised;
        Assert.ExpectedError('is not supported');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveMessageRejectsInvoiceMismatch()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Receiving a lifecycle message whose invoice ID does not match the E-Document raises an error
        Initialize();

        // [GIVEN] An outgoing E-Document with a lifecycle payload referencing a different invoice
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml('WRONG-INVOICE-ID', 'Submitted', '', ''));

        // [WHEN] The mismatched message is received
        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        // [THEN] An error about invoice ID mismatch is raised;
        Assert.ExpectedError('does not match');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveTechnicalRejectedRequiresReasonCode()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A Technical Rejected message without a reason code is rejected
        Initialize();

        // [GIVEN] An outgoing E-Document with a Rejected lifecycle payload missing the reason code
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Rejected', '', 'Something went wrong'));

        // [WHEN] The Rejected message without reason code is received
        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        // [THEN] An error about missing reason code is raised;
        Assert.ExpectedError('reason code is required');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveTechnicalRejectedRequiresReasonDescription()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A Technical Rejected message without a reason description is rejected
        Initialize();

        // [GIVEN] An outgoing E-Document with a Rejected lifecycle payload missing the reason description
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Rejected', 'SCHEMA', ''));

        // [WHEN] The Rejected message without reason description is received
        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        // [THEN] An error about missing reason description is raised;
        Assert.ExpectedError('reason description is required');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveSubmittedThenRefusedIsValid()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        ExternalDocID: Text[250];
        FREntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A Refused status follows a Submitted status.
        Initialize();

        // [GIVEN] Outgoing E-Document "ED" with a received Submitted status
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Submitted', '', '');

        // [WHEN] A Refused status is received
        FREntryNo := ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Refused', '', '');

        // [THEN] The Refused status is persisted
        FREInvoiceMessage.Get(FREntryNo);
        Assert.AreEqual(FREInvoiceMessage.Type::Refused, FREInvoiceMessage.Type, 'FR type must be Refused.');
    end;

    [Test]
    procedure ReceiveSubmittedThenTechnicalRejectedIsValid()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        ExternalDocID: Text[250];
        FREntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A Technical Rejected status follows a Submitted status.
        Initialize();

        // [GIVEN] Outgoing E-Document "ED" with a received Submitted status
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Submitted', '', '');

        // [WHEN] A Technical Rejected status is received
        FREntryNo := ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Rejected', 'SCHEMA', 'Schema validation failed');

        // [THEN] The Technical Rejected status is persisted
        FREInvoiceMessage.Get(FREntryNo);
        Assert.AreEqual(FREInvoiceMessage.Type::"Technical Rejected", FREInvoiceMessage.Type, 'FR type must be Technical Rejected.');
    end;

    [Test]
    procedure ReceiveResponseBeforeSubmittedIsRejected()
    var
        EDocument: Record "E-Document";
        ExternalDocID: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A terminal response cannot be the first lifecycle status.
        Initialize();

        // [GIVEN] Outgoing E-Document "ED" without a lifecycle status
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);

        // [WHEN] An Accepted status is received
        asserterror ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Accepted', '', '');

        // [THEN] The transition is rejected
        Assert.ExpectedError('cannot change from no previous status to Accepted');
    end;

    [Test]
    procedure ReceiveDuplicateSubmittedIsRejected()
    var
        EDocument: Record "E-Document";
        ExternalDocID: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Submitted cannot be received twice with different external message IDs.
        Initialize();

        // [GIVEN] Outgoing E-Document "ED" with a received Submitted status
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Submitted', '', '');

        // [WHEN] Another Submitted status is received
        asserterror ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Submitted', '', '');

        // [THEN] The duplicate status is rejected
        Assert.ExpectedError('cannot change from Submitted to Submitted');
    end;

    [Test]
    procedure ReceiveStatusAfterTerminalStatusIsRejected()
    var
        EDocument: Record "E-Document";
        ExternalDocID: Text[250];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] No status can follow a terminal lifecycle response.
        Initialize();

        // [GIVEN] Outgoing E-Document "ED" with Submitted and Refused statuses
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := RegisterExternalDocumentReference(EDocument);
        ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Submitted', '', '');
        ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Refused', '', '');

        // [WHEN] An Accepted status is received
        asserterror ReceiveLifecycleMessage(EDocument, ExternalDocID, 'Accepted', '', '');

        // [THEN] The transition from the terminal status is rejected
        Assert.ExpectedError('cannot change from Refused to Accepted');
    end;

    [Test]
    procedure CompletePPFProfileIsValid()
    var
        FREInvoiceProfileValidator: Codeunit "FR E-Invoice Profile Validator";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A complete PPF lifecycle payload satisfies profile validation.
        Initialize();

        // [GIVEN] A complete PPF lifecycle document
        XmlDocument.ReadFrom(BuildPPFValidationXml(PPFProfileID(), true, 'WK', '0238', '102'), XmlDoc);

        // [WHEN] The PPF profile is validated
        FREInvoiceProfileValidator.Validate(XmlDoc, true);

        // [THEN] No validation error occurs
    end;

    [Test]
    procedure PPFProfileRejectsMismatchedLifecycleStatusName()
    var
        FREInvoiceProfileValidator: Codeunit "FR E-Invoice Profile Validator";
        XmlDoc: XmlDocument;
        ValidationXml: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 637593] A lifecycle status code must use its official French status name.
        Initialize();

        // [GIVEN] A PPF lifecycle document with status code 210 and the name for status 205
        ValidationXml := BuildPPFValidationXml(PPFProfileID(), true, 'WK', '0238', '102');
        ValidationXml := ValidationXml.Replace('<ram:ProcessConditionCode>205</ram:ProcessConditionCode>', '<ram:ProcessConditionCode>210</ram:ProcessConditionCode>');
        XmlDocument.ReadFrom(ValidationXml, XmlDoc);

        // [WHEN] The PPF profile is validated
        asserterror FREInvoiceProfileValidator.Validate(XmlDoc, true);

        // [THEN] The mismatched lifecycle status name is rejected
        Assert.ExpectedError('must have value Refusée instead of Approuvée');
    end;

    [Test]
    procedure PPFCollectedProfileRequiresVATBreakdown()
    var
        FREInvoiceProfileValidator: Codeunit "FR E-Invoice Profile Validator";
        XmlDoc: XmlDocument;
        ValidationXml: Text;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 637593] A collected lifecycle status requires its CDAR amount and VAT structure.
        Initialize();

        // [GIVEN] A PPF collected lifecycle document without a VAT characteristic
        ValidationXml := BuildPPFValidationXml(PPFProfileID(), true, 'WK', '0238', '102');
        ValidationXml := ValidationXml.Replace('<ram:ProcessConditionCode>205</ram:ProcessConditionCode><ram:ProcessCondition>Approuvée</ram:ProcessCondition>', '<ram:ProcessConditionCode>212</ram:ProcessConditionCode><ram:ProcessCondition>Encaissée</ram:ProcessCondition>');
        XmlDocument.ReadFrom(ValidationXml, XmlDoc);

        // [WHEN] The PPF profile is validated
        asserterror FREInvoiceProfileValidator.Validate(XmlDoc, true);

        // [THEN] The missing collected VAT characteristic is rejected
        Assert.ExpectedError('SpecifiedDocumentCharacteristic');
    end;

    [Test]
    procedure PPFProfileRejectsWrongProfileID()
    var
        FREInvoiceProfileValidator: Codeunit "FR E-Invoice Profile Validator";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A PPF lifecycle payload must declare the PPF profile.
        Initialize();

        // [GIVEN] A PPF lifecycle document with the CDV profile ID
        XmlDocument.ReadFrom(BuildPPFValidationXml(CDVProfileID(), true, 'WK', '0238', '102'), XmlDoc);

        // [WHEN] The PPF profile is validated
        asserterror FREInvoiceProfileValidator.Validate(XmlDoc, true);

        // [THEN] The incorrect profile ID is rejected
        Assert.ExpectedError('must have value ' + PPFProfileID());
    end;

    [Test]
    procedure PPFProfileRequiresSenderTradeParty()
    var
        FREInvoiceProfileValidator: Codeunit "FR E-Invoice Profile Validator";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A PPF lifecycle payload requires the sender platform party.
        Initialize();

        // [GIVEN] A PPF lifecycle document without a sender platform party
        XmlDocument.ReadFrom(BuildPPFValidationXml(PPFProfileID(), false, 'WK', '0238', '102'), XmlDoc);

        // [WHEN] The PPF profile is validated
        asserterror FREInvoiceProfileValidator.Validate(XmlDoc, true);

        // [THEN] The missing sender platform is rejected
        Assert.ExpectedError('SenderTradeParty');
    end;

    [Test]
    procedure PPFProfileRejectsWrongRecipientScheme()
    var
        FREInvoiceProfileValidator: Codeunit "FR E-Invoice Profile Validator";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] The PPF recipient must use scheme 0238.
        Initialize();

        // [GIVEN] A PPF lifecycle document with the wrong recipient scheme
        XmlDocument.ReadFrom(BuildPPFValidationXml(PPFProfileID(), true, 'WK', '9999', '102'), XmlDoc);

        // [WHEN] The PPF profile is validated
        asserterror FREInvoiceProfileValidator.Validate(XmlDoc, true);

        // [THEN] The incorrect recipient scheme is rejected
        Assert.ExpectedError('must have value 0238 instead of 9999');
    end;

    [Test]
    procedure PPFProfileRejectsWrongSenderRole()
    var
        FREInvoiceProfileValidator: Codeunit "FR E-Invoice Profile Validator";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] The sender platform must use role WK.
        Initialize();

        // [GIVEN] A PPF lifecycle document with the wrong sender role
        XmlDocument.ReadFrom(BuildPPFValidationXml(PPFProfileID(), true, 'XX', '0238', '102'), XmlDoc);

        // [WHEN] The PPF profile is validated
        asserterror FREInvoiceProfileValidator.Validate(XmlDoc, true);

        // [THEN] The incorrect sender role is rejected
        Assert.ExpectedError('must have value WK instead of XX');
    end;

    [Test]
    procedure PPFProfileRejectsWrongInvoiceDateFormat()
    var
        FREInvoiceProfileValidator: Codeunit "FR E-Invoice Profile Validator";
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] The PPF invoice issue date must use format 102.
        Initialize();

        // [GIVEN] A PPF lifecycle document with the wrong invoice date format
        XmlDocument.ReadFrom(BuildPPFValidationXml(PPFProfileID(), true, 'WK', '0238', '204'), XmlDoc);

        // [WHEN] The PPF profile is validated
        asserterror FREInvoiceProfileValidator.Validate(XmlDoc, true);

        // [THEN] The incorrect date format is rejected
        Assert.ExpectedError('must have value 102 instead of 204');
    end;

    [Test]
    procedure BuilderRejectsIncomingOnlyStatus()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageBuilder: Codeunit "FR E-Invoice Message Builder";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Building a message with an incoming-only status raises a masked internal error
        Initialize();

        // [GIVEN] An incoming E-Document with a Submitted lifecycle message
        CreateIncomingEDocument(EDocument);
        FREInvoiceMessage.Init();
        FREInvoiceMessage."E-Document Entry No." := EDocument."Entry No";
        FREInvoiceMessage.Type := FREInvoiceMessage.Type::Submitted;
        FREInvoiceMessage."Source Occurrence ID" := CreateGuid();
        FREInvoiceMessage."Event Date" := Today();
        FREInvoiceMessage."Created At" := CurrentDateTime();
        FREInvoiceMessage.Insert();

        // [WHEN] The message builder attempts to build the message
        asserterror FREInvoiceMessageBuilder.BuildMessage(EDocument, FREInvoiceMessage, TempBlob);

        // [THEN] The internal error is masked;
        Assert.ExpectedError('An error has occurred.');
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure BuildLifecycleXml(InvoiceID: Text; Status: Text; ReasonCode: Text; ReasonDescription: Text): Text
    var
        XmlText: TextBuilder;
    begin
        XmlText.Append('<LifecycleMessage>');
        XmlText.Append('<InvoiceID>');
        XmlText.Append(InvoiceID);
        XmlText.Append('</InvoiceID>');
        XmlText.Append('<Status>');
        XmlText.Append(Status);
        XmlText.Append('</Status>');
        if ReasonCode <> '' then begin
            XmlText.Append('<ReasonCode>');
            XmlText.Append(ReasonCode);
            XmlText.Append('</ReasonCode>');
        end;
        if ReasonDescription <> '' then begin
            XmlText.Append('<ReasonDescription>');
            XmlText.Append(ReasonDescription);
            XmlText.Append('</ReasonDescription>');
        end;
        XmlText.Append('</LifecycleMessage>');
        exit(XmlText.ToText());
    end;

    local procedure ReceiveLifecycleMessage(EDocument: Record "E-Document"; ExternalDocID: Text[250]; Status: Text; ReasonCode: Text; ReasonDescription: Text): Integer
    var
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", Status, ReasonCode, ReasonDescription));
        exit(FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob));
    end;

    local procedure RegisterExternalDocumentReference(EDocument: Record "E-Document") ExternalDocumentID: Text[250]
    var
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        ExternalDocumentID := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ExternalDocumentID));
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocumentID);
    end;

    local procedure BuildPPFValidationXml(ProfileID: Text; IncludeSender: Boolean; SenderRole: Text; RecipientScheme: Text; InvoiceDateFormat: Text): Text
    var
        XmlText: TextBuilder;
    begin
        XmlText.Append('<rsm:CrossDomainAcknowledgementAndResponse xmlns:rsm="urn:un:unece:uncefact:data:standard:CrossDomainAcknowledgementAndResponse:100" xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100" xmlns:qdt="urn:un:unece:uncefact:data:standard:QualifiedDataType:100" xmlns:udt="urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100">');
        XmlText.Append('<rsm:ExchangedDocumentContext><ram:GuidelineSpecifiedDocumentContextParameter><ram:ID>');
        XmlText.Append(ProfileID);
        XmlText.Append('</ram:ID></ram:GuidelineSpecifiedDocumentContextParameter></rsm:ExchangedDocumentContext>');
        XmlText.Append('<rsm:ExchangedDocument><ram:ID>MESSAGE-ID</ram:ID><ram:IssueDateTime><udt:DateTimeString format="204">20260821120000</udt:DateTimeString></ram:IssueDateTime>');
        if IncludeSender then begin
            XmlText.Append('<ram:SenderTradeParty><ram:GlobalID schemeID="0238">SENDER</ram:GlobalID><ram:RoleCode>');
            XmlText.Append(SenderRole);
            XmlText.Append('</ram:RoleCode></ram:SenderTradeParty>');
        end;
        XmlText.Append('<ram:IssuerTradeParty><ram:GlobalID schemeID="0002">123456789</ram:GlobalID><ram:RoleCode>SE</ram:RoleCode></ram:IssuerTradeParty>');
        XmlText.Append('<ram:RecipientTradeParty><ram:GlobalID schemeID="');
        XmlText.Append(RecipientScheme);
        XmlText.Append('">9998</ram:GlobalID><ram:RoleCode>DFH</ram:RoleCode></ram:RecipientTradeParty></rsm:ExchangedDocument>');
        XmlText.Append('<rsm:AcknowledgementDocument><ram:TypeCode>23</ram:TypeCode><ram:IssueDateTime><udt:DateTimeString format="204">20260821000000</udt:DateTimeString></ram:IssueDateTime>');
        XmlText.Append('<ram:ReferenceReferencedDocument><ram:IssuerAssignedID>INVOICE</ram:IssuerAssignedID><ram:StatusCode>47</ram:StatusCode><ram:TypeCode>380</ram:TypeCode>');
        XmlText.Append('<ram:ReceiptDateTime><udt:DateTimeString format="204">20260821120000</udt:DateTimeString></ram:ReceiptDateTime><ram:ReferenceTypeCode>');
        XmlText.Append(PPFProfileID());
        XmlText.Append('</ram:ReferenceTypeCode><ram:FormattedIssueDateTime><qdt:DateTimeString format="');
        XmlText.Append(InvoiceDateFormat);
        XmlText.Append('">20260821</qdt:DateTimeString></ram:FormattedIssueDateTime><ram:ProcessConditionCode>205</ram:ProcessConditionCode><ram:ProcessCondition>Approuvée</ram:ProcessCondition>');
        XmlText.Append('</ram:ReferenceReferencedDocument></rsm:AcknowledgementDocument></rsm:CrossDomainAcknowledgementAndResponse>');
        exit(XmlText.ToText());
    end;

    local procedure PPFProfileID(): Text
    begin
        exit('urn.cpro.gouv.fr:1p0:CDV:einvoicingF2');
    end;

    local procedure CDVProfileID(): Text
    begin
        exit('urn.cpro.gouv.fr:1p0:CDV:invoice');
    end;

    local procedure FindMessage(var FREInvoiceMessage: Record "FR E-Invoice Message"; EDocument: Record "E-Document"; MessageType: Enum "FR E-Invoice Message Type")
    begin
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, MessageType);
        FREInvoiceMessage.FindFirst();
    end;

    local procedure BuildMessagePayload(EDocument: Record "E-Document"; FREInvoiceMessage: Record "FR E-Invoice Message") Payload: Text
    var
        FREInvoiceMessageBuilder: Codeunit "FR E-Invoice Message Builder";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        PayloadLine: Text;
    begin
        FREInvoiceMessageBuilder.BuildMessage(EDocument, FREInvoiceMessage, TempBlob);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        while not InStream.EOS do begin
            InStream.ReadText(PayloadLine);
            Payload += PayloadLine;
        end;
    end;

    local procedure AssertPayloadAmount(Payload: Text; ExpectedAmount: Decimal; ExpectedCurrencyCode: Code[10])
    var
        XmlDoc: XmlDocument;
        AmountNode: XmlNode;
        CurrencyCodeNode: XmlNode;
        ActualAmount: Decimal;
    begin
        Assert.IsTrue(XmlDocument.ReadFrom(Payload, XmlDoc), 'The payload must be valid XML.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ValueAmount"]', AmountNode), 'The payload must contain a value amount.');
        Assert.IsTrue(Evaluate(ActualAmount, AmountNode.AsXmlElement().InnerText(), 9), 'The payload value amount must be a valid XML decimal.');
        Assert.AreEqual(ExpectedAmount, ActualAmount, 'The payload value amount is incorrect.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ValueAmount"]/@currencyID', CurrencyCodeNode), 'The payload value amount must contain a currency.');
        Assert.AreEqual(ExpectedCurrencyCode, CurrencyCodeNode.AsXmlAttribute().Value(), 'The payload currency is incorrect.');
    end;

    local procedure AssertPayloadStatus(Payload: Text; ExpectedStatus: Text)
    var
        XmlDoc: XmlDocument;
        StatusNode: XmlNode;
    begin
        Assert.IsTrue(XmlDocument.ReadFrom(Payload, XmlDoc), 'The payload must be valid XML.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ProcessConditionCode"]', StatusNode), 'The payload must contain a status.');
        Assert.AreEqual(ExpectedStatus, StatusNode.AsXmlElement().InnerText(), 'The payload status is incorrect.');
    end;

    local procedure AssertPayloadDateFormat(Payload: Text; ExpectedFormat: Text)
    var
        XmlDoc: XmlDocument;
        DateFormatNode: XmlNode;
    begin
        Assert.IsTrue(XmlDocument.ReadFrom(Payload, XmlDoc), 'The payload must be valid XML.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="DateTimeString"]/@format', DateFormatNode), 'The payload must contain an event date format.');
        Assert.AreEqual(ExpectedFormat, DateFormatNode.AsXmlAttribute().Value(), 'The payload event date format is incorrect.');
    end;

    local procedure AssertPayloadReasonCode(Payload: Text; ExpectedReasonCode: Text)
    var
        XmlDoc: XmlDocument;
        ReasonCodeNode: XmlNode;
    begin
        Assert.IsTrue(XmlDocument.ReadFrom(Payload, XmlDoc), 'The payload must be valid XML.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ReasonCode"]', ReasonCodeNode), 'The payload must contain a reason code.');
        Assert.AreEqual(ExpectedReasonCode, ReasonCodeNode.AsXmlElement().InnerText(), 'The payload reason code is incorrect.');
    end;

    local procedure AssertPayloadHasNoReason(Payload: Text)
    var
        XmlDoc: XmlDocument;
        ReasonNode: XmlNode;
    begin
        Assert.IsTrue(XmlDocument.ReadFrom(Payload, XmlDoc), 'The payload must be valid XML.');
        Assert.IsFalse(XmlDoc.SelectSingleNode('//*[local-name()="SpecifiedDocumentStatus"]', ReasonNode), 'The payload must not contain a document status when no refusal reason is provided.');
        Assert.IsFalse(XmlDoc.SelectSingleNode('//*[local-name()="ReasonCode"]', ReasonNode), 'The payload must not contain an empty reason code.');
        Assert.IsFalse(XmlDoc.SelectSingleNode('//*[local-name()="Reason"]', ReasonNode), 'The payload must not contain an empty reason description.');
    end;

    local procedure AssertPayloadVATCharacteristic(Payload: Text; ExpectedAmount: Decimal; ExpectedVATRate: Decimal)
    var
        XmlDoc: XmlDocument;
        AmountNode: XmlNode;
        RateNode: XmlNode;
        ActualAmount: Decimal;
        ActualRate: Decimal;
    begin
        Assert.IsTrue(XmlDocument.ReadFrom(Payload, XmlDoc), 'The payload must be valid XML.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ValueAmount"]', AmountNode), 'The payload must contain a value amount.');
        Assert.IsTrue(Evaluate(ActualAmount, AmountNode.AsXmlElement().InnerText(), 9), 'The characteristic amount must be valid.');
        Assert.AreEqual(ExpectedAmount, ActualAmount, 'The characteristic amount is incorrect.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ValuePercent"]', RateNode), 'The payload must contain a value percent.');
        Assert.IsTrue(Evaluate(ActualRate, RateNode.AsXmlElement().InnerText(), 9), 'The characteristic rate must be valid.');
        Assert.AreEqual(ExpectedVATRate, ActualRate, 'The characteristic VAT rate is incorrect.');
    end;

    local procedure AssertPayloadPPFContext(Payload: Text; EDocument: Record "E-Document")
    var
        XmlDoc: XmlDocument;
        XmlNode: XmlNode;
    begin
        Assert.IsTrue(XmlDocument.ReadFrom(Payload, XmlDoc), 'The payload must be valid XML.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="GuidelineSpecifiedDocumentContextParameter"]/*[local-name()="ID"]', XmlNode), 'The payload must contain a guideline profile.');
        Assert.AreEqual('urn.cpro.gouv.fr:1p0:CDV:einvoicingF2', XmlNode.AsXmlElement().InnerText(), 'The payload must use the PPF invoice profile.');
        AssertTradeParty(XmlDoc, 'SenderTradeParty', 'TEST-PLATFORM', '0238', 'Test Platform', 'WK');
        AssertTradeParty(XmlDoc, 'IssuerTradeParty', '123456789', '0002', 'FR Test Issuer', 'SE');
        AssertTradeParty(XmlDoc, 'RecipientTradeParty', '9998', '0238', 'PPF', 'DFH');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ReceiptDateTime"]', XmlNode), 'The payload must contain the platform receipt time.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="FormattedIssueDateTime"]/*[local-name()="DateTimeString"]', XmlNode), 'The payload must contain the invoice issue date.');
        Assert.AreEqual(Format(EDocument."Document Date", 0, '<Year4><Month,2><Day,2>'), XmlNode.AsXmlElement().InnerText(), 'The invoice issue date is incorrect.');
    end;

    local procedure AssertPayloadCDVContext(Payload: Text)
    var
        XmlDoc: XmlDocument;
        XmlNode: XmlNode;
    begin
        Assert.IsTrue(XmlDocument.ReadFrom(Payload, XmlDoc), 'The payload must be valid XML.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="GuidelineSpecifiedDocumentContextParameter"]/*[local-name()="ID"]', XmlNode), 'The payload must contain a guideline profile.');
        Assert.AreEqual('urn.cpro.gouv.fr:1p0:CDV:invoice', XmlNode.AsXmlElement().InnerText(), 'The payload must use the CDV invoice profile.');
        Assert.IsFalse(XmlDoc.SelectSingleNode('//*[local-name()="SenderTradeParty"]', XmlNode), 'The CDV payload must not contain a sender platform party.');
        Assert.IsFalse(XmlDoc.SelectSingleNode('//*[local-name()="RecipientTradeParty"]', XmlNode), 'The CDV payload must not contain a PPF recipient party.');
    end;

    local procedure AssertTradeParty(XmlDoc: XmlDocument; ElementName: Text; ExpectedID: Text; ExpectedScheme: Text; ExpectedName: Text; ExpectedRole: Text)
    var
        SchemeNode: XmlNode;
        XmlNode: XmlNode;
        PartyPath: Text;
        PartyPathTok: Label '//*[local-name()="ExchangedDocument"]/*[local-name()="%1"]', Locked = true;
    begin
        PartyPath := StrSubstNo(PartyPathTok, ElementName);
        Assert.IsTrue(XmlDoc.SelectSingleNode(PartyPath + '/*[local-name()="GlobalID"]', XmlNode), 'The payload must contain the expected trade-party ID.');
        Assert.AreEqual(ExpectedID, XmlNode.AsXmlElement().InnerText(), 'The trade-party ID is incorrect.');
        Assert.IsTrue(XmlDoc.SelectSingleNode(PartyPath + '/*[local-name()="GlobalID"]/@schemeID', SchemeNode), 'The trade-party ID must contain a scheme.');
        Assert.AreEqual(ExpectedScheme, SchemeNode.AsXmlAttribute().Value(), 'The trade-party scheme is incorrect.');
        Assert.IsTrue(XmlDoc.SelectSingleNode(PartyPath + '/*[local-name()="Name"]', XmlNode), 'The payload must contain the expected trade-party name.');
        Assert.AreEqual(ExpectedName, XmlNode.AsXmlElement().InnerText(), 'The trade-party name is incorrect.');
        Assert.IsTrue(XmlDoc.SelectSingleNode(PartyPath + '/*[local-name()="RoleCode"]', XmlNode), 'The payload must contain the expected trade-party role.');
        Assert.AreEqual(ExpectedRole, XmlNode.AsXmlElement().InnerText(), 'The trade-party role is incorrect.');
    end;

    local procedure Initialize()
    var
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        EDocPaymentOccurrence.DeleteAll();
        FREInvoiceMessage.DeleteAll();
        EnsureService();
        EnsureCompanyInformation();
        GeneralLedgerSetup.Get();
        if not GeneralLedgerSetup."Unrealized VAT" then begin
            GeneralLedgerSetup."Unrealized VAT" := true;
            GeneralLedgerSetup.Modify();
        end;
    end;

    local procedure EnsureCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation.Name := 'FR Test Issuer';
        CompanyInformation.Modify();
    end;

    local procedure EnsureService()
    var
        EDocumentService: Record "E-Document Service";
    begin
        if not EDocumentService.Get('FR-MESSAGE') then begin
            EDocumentService.Init();
            EDocumentService.Code := 'FR-MESSAGE';
            EDocumentService.Insert();
        end;
        EDocumentService."Document Format" := EDocumentService."Document Format"::"Peppol BIS 3.0 FR";
        EDocumentService."FR Sender Platform ID" := 'TEST-PLATFORM';
        EDocumentService."FR Sender Platform Scheme" := '0238';
        EDocumentService."FR Sender Platform Name" := 'Test Platform';
        EDocumentService.Modify();
    end;

    local procedure CreateIncomingEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(EDocument."Document No."));
        EDocument.Direction := EDocument.Direction::Incoming;
        EDocument."Document Type" := EDocument."Document Type"::"Purchase Invoice";
        EDocument.Service := 'FR-MESSAGE';
        EDocument.Insert();
    end;

    local procedure CreateOutgoingEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(EDocument."Document No."));
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Service := 'FR-MESSAGE';
        EDocument.Insert();
    end;

    local procedure CreatePaymentScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; ServiceStatus: Enum "E-Document Service Status")
    begin
        CreatePaymentScenarioWithAmount(EDocument, DetailedCustLedgEntry, ServiceStatus, 120);
    end;

    local procedure CreatePaymentScenarioWithoutSenderPlatform(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; ServiceStatus: Enum "E-Document Service Status")
    var
        EDocumentService: Record "E-Document Service";
    begin
        EDocumentService.Get('FR-MESSAGE');
        Clear(EDocumentService."FR Sender Platform ID");
        EDocumentService.Modify();
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, ServiceStatus);
    end;

    local procedure CreatePaymentScenarioWithAmount(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; ServiceStatus: Enum "E-Document Service Status"; PaymentAmount: Decimal)
    var
        Customer: Record Customer;
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedInvoiceNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::Percentage;
        VATPostingSetup."Sales VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Tax Category" := 'S';
        VATPostingSetup.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        PostedInvoiceNo := CopyStr(Format(CreateGuid()), 1, MaxStrLen(PostedInvoiceNo));
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := PostedInvoiceNo;
        SalesInvoiceHeader."Bill-to Customer No." := Customer."No.";
        SalesInvoiceHeader."Posting Date" := WorkDate();
        SalesInvoiceHeader."Document Date" := WorkDate();
        SalesInvoiceHeader.Insert();
        SalesInvoiceLine.Init();
        SalesInvoiceLine."Document No." := PostedInvoiceNo;
        SalesInvoiceLine."Line No." := 10000;
        SalesInvoiceLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesInvoiceLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        SalesInvoiceLine.Insert();

        InvoiceCustLedgerEntry.Init();
        InvoiceCustLedgerEntry."Entry No." := GetNextCustLedgerEntryNo();
        InvoiceCustLedgerEntry."Customer No." := Customer."No.";
        InvoiceCustLedgerEntry."Posting Date" := WorkDate();
        InvoiceCustLedgerEntry."Document Type" := InvoiceCustLedgerEntry."Document Type"::Invoice;
        InvoiceCustLedgerEntry."Document No." := PostedInvoiceNo;
        InvoiceCustLedgerEntry."Transaction No." := InvoiceCustLedgerEntry."Entry No.";
        InvoiceCustLedgerEntry.Insert();
        PaymentCustLedgerEntry.Init();
        PaymentCustLedgerEntry."Entry No." := GetNextCustLedgerEntryNo();
        PaymentCustLedgerEntry."Customer No." := Customer."No.";
        PaymentCustLedgerEntry."Posting Date" := WorkDate();
        PaymentCustLedgerEntry."Document Type" := PaymentCustLedgerEntry."Document Type"::Payment;
        PaymentCustLedgerEntry."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(PaymentCustLedgerEntry."Document No."));
        PaymentCustLedgerEntry.Insert();
        CreateDetailedLedgerEntry(DetailedCustLedgEntry, InvoiceCustLedgerEntry."Entry No.", PaymentCustLedgerEntry."Entry No.", -PaymentAmount);

        VATEntry.Init();
        VATEntry."Entry No." := GetNextVATEntryNo();
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."Document No." := PostedInvoiceNo;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."Transaction No." := InvoiceCustLedgerEntry."Transaction No.";
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Normal VAT";
        VATEntry.Base := -100;
        VATEntry.Amount := -20;
        VATEntry."Unrealized Base" := -100;
        VATEntry."Unrealized Amount" := -20;
        VATEntry.Insert();

        EDocument.Init();
        EDocument."Document No." := PostedInvoiceNo;
        EDocument."Document Record ID" := SalesInvoiceHeader.RecordId;
        EDocument."Posting Date" := SalesInvoiceHeader."Posting Date";
        EDocument."Document Date" := SalesInvoiceHeader."Document Date";
        EDocument."Clearance Date" := CurrentDateTime();
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Service := 'FR-MESSAGE';
        EDocument.Insert();
        CreateServiceStatus(EDocument, ServiceStatus);
    end;

    local procedure CreatePostedPaymentScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedInvoiceNo: Code[20];
    begin
        EDocumentService.Get('FR-MESSAGE');
        Clear(EDocumentService."Document Format");
        EDocumentService.Modify();
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::Percentage;
        VATPostingSetup."Sales VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Tax Category" := 'S';
        VATPostingSetup.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PrepareCustomerForPosting(Customer);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        PrepareSalesHeaderForPosting(SalesHeader);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale), 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        EDocumentService."Document Format" := EDocumentService."Document Format"::"Peppol BIS 3.0 FR";
        EDocumentService.Modify();
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        EDocument.Init();
        EDocument."Document No." := PostedInvoiceNo;
        EDocument."Document Record ID" := SalesInvoiceHeader.RecordId;
        EDocument."Posting Date" := SalesInvoiceHeader."Posting Date";
        EDocument."Document Date" := SalesInvoiceHeader."Document Date";
        EDocument."Clearance Date" := CurrentDateTime();
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Service := 'FR-MESSAGE';
        EDocument.Insert();
        CreateServiceStatus(EDocument, "E-Document Service Status"::Approved);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -120);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PostedInvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindApplicationDetailedEntry(DetailedCustLedgEntry, PostedInvoiceNo);
    end;

    local procedure PrepareCustomerForPosting(var Customer: Record Customer)
    begin
        Customer.Validate(Address, 'Test Address');
        Customer.Validate(City, 'Paris');
        Customer.Validate("Post Code", '75001');
        Customer.Validate("Country/Region Code", 'FR');
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo('FR');
    end;

    local procedure PrepareSalesHeaderForPosting(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Bill-to Address", 'Test Address');
        SalesHeader.Validate("Bill-to City", 'Paris');
        SalesHeader.Validate("Bill-to Post Code", '75001');
        SalesHeader.Validate("Bill-to Country/Region Code", 'FR');
        SalesHeader.Validate("Ship-to Address", 'Test Address');
        SalesHeader.Validate("Ship-to City", 'Paris');
        SalesHeader.Validate("Ship-to Post Code", '75001');
        SalesHeader.Validate("Ship-to Country/Region Code", 'FR');
        SalesHeader.Validate("Your Reference", 'FR-BUYER-REF');
        SalesHeader.Modify(true);
    end;

    local procedure FindApplicationDetailedEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; InvoiceDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", InvoiceDocNo);
        CustLedgerEntry.FindFirst();
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Initial Document Type", DetailedCustLedgEntry."Initial Document Type"::Invoice);
        DetailedCustLedgEntry.SetFilter(Amount, '<%1', 0);
        DetailedCustLedgEntry.FindLast();
    end;

    local procedure CreateMixedVATPaymentScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        CreatePaymentScenarioWithAmount(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved, 230);
        CreateVATEntryForScenario(EDocument, 10, false);
    end;

    local procedure CreateMultiRatePaymentScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        CreatePaymentScenarioWithAmount(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved, 99);
        CreateVATEntryForScenario(EDocument, 10, true);
        CreateVATEntryForScenario(EDocument, 7, true);
    end;

    local procedure CreateVATEntryForScenario(EDocument: Record "E-Document"; VATPercent: Decimal; UnrealizedVAT: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        SalesInvoiceLine.SetRange("Document No.", EDocument."Document No.");
        SalesInvoiceLine.FindFirst();
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPercent);
        VATPostingSetup.Rename(SalesInvoiceLine."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        if UnrealizedVAT then begin
            VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::Percentage;
            VATPostingSetup."Sales VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        end;
        VATPostingSetup."Tax Category" := 'S';
        VATPostingSetup.Modify(true);

        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", EDocument."Document No.");
        CustLedgerEntry.FindFirst();
        VATEntry.Init();
        VATEntry."Entry No." := GetNextVATEntryNo();
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."Document No." := EDocument."Document No.";
        VATEntry."Posting Date" := EDocument."Posting Date";
        VATEntry."Transaction No." := CustLedgerEntry."Transaction No.";
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Normal VAT";
        VATEntry.Base := -100;
        VATEntry.Amount := -VATPercent;
        if UnrealizedVAT then begin
            VATEntry."Unrealized Base" := VATEntry.Base;
            VATEntry."Unrealized Amount" := VATEntry.Amount;
        end;
        VATEntry.Insert();
    end;

    local procedure CreateNormalVATPaymentScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        VATEntry: Record "VAT Entry";
    begin
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);
        VATEntry.SetRange("Document No.", EDocument."Document No.");
        VATEntry.FindFirst();
        VATEntry."Unrealized Base" := 0;
        VATEntry."Unrealized Amount" := 0;
        VATEntry.Modify();
    end;

    local procedure CreateServiceStatus(EDocument: Record "E-Document"; ServiceStatus: Enum "E-Document Service Status")
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        EDocumentServiceStatus.Init();
        EDocumentServiceStatus."E-Document Entry No" := EDocument."Entry No";
        EDocumentServiceStatus."E-Document Service Code" := EDocument.Service;
        EDocumentServiceStatus.Status := ServiceStatus;
        EDocumentServiceStatus.Insert();
    end;

    local procedure CreateDetailedLedgerEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; InvoiceEntryNo: Integer; PaymentEntryNo: Integer; Amount: Decimal)
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := GetNextDetailedLedgerEntryNo();
        DetailedCustLedgEntry."Cust. Ledger Entry No." := InvoiceEntryNo;
        DetailedCustLedgEntry."Applied Cust. Ledger Entry No." := PaymentEntryNo;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::Application;
        DetailedCustLedgEntry."Initial Document Type" := DetailedCustLedgEntry."Initial Document Type"::Invoice;
        DetailedCustLedgEntry.Amount := Amount;
        DetailedCustLedgEntry."Currency Code" := 'EUR';
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry.Insert();
    end;

    local procedure ProcessPaymentApplication(EDocument: Record "E-Document"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        EDocPaymentOccurrenceMgt.ProcessApplication(DetailedCustLedgEntry);

        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        EDocPaymentOccurrence.SetRange("Source Occurrence ID", DetailedCustLedgEntry.SystemId);
        EDocPaymentOccurrence.FindFirst();
        RunPaymentOccurrence(EDocPaymentOccurrence);
    end;

    local procedure ProcessPaymentUnapplication(EDocument: Record "E-Document"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
    begin
        EDocPaymentOccurrenceMgt.ProcessUnapplication(DetailedCustLedgEntry, NewDetailedCustLedgEntry);

        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Reversed);
        EDocPaymentOccurrence.SetRange("Source Occurrence ID", NewDetailedCustLedgEntry.SystemId);
        EDocPaymentOccurrence.FindFirst();
        RunPaymentOccurrence(EDocPaymentOccurrence);
    end;

    local procedure RunPaymentOccurrence(EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry."Record ID to Process" := EDocPaymentOccurrence.RecordId;
        Codeunit.Run(Codeunit::"E-Doc. Payment Occurrence Mgt.", JobQueueEntry);
    end;

    local procedure GetNextDetailedLedgerEntryNo(): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if DetailedCustLedgEntry.FindLast() then
            exit(DetailedCustLedgEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure GetNextCustLedgerEntryNo(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetFilter("Entry No.", '<0');
        if CustLedgerEntry.FindFirst() then
            exit(CustLedgerEntry."Entry No." - 1);
        exit(-1);
    end;

    local procedure GetNextVATEntryNo(): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        if VATEntry.FindLast() then
            exit(VATEntry."Entry No." + 1);
        exit(1);
    end;
}