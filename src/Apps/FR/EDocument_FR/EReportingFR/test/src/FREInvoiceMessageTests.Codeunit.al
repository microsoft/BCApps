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
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
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
                  tabledata "Sales Invoice Header" = rimd;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        MessageSenderMock: Codeunit "FR E-Doc. Msg. Sender Mock";

    [Test]
    procedure PaymentApplicationSendsCollected()
    var
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Applying a payment to an approved French E-Document creates a Collected message
        Initialize();

        // [GIVEN] An approved outgoing French E-Document with an applied customer payment
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment application is processed
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

        // [THEN] One Collected lifecycle message and one generic payment occurrence are created and the message can be sent
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 1);
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
        EDocPaymentOccurrence.FindFirst();
        Assert.AreEqual(120, EDocPaymentOccurrence.Amount, 'The generic applied occurrence must carry a positive amount.');
        Assert.AreEqual(0, MessageSenderMock.GetSendCount(), 'Payment posting must queue the message without invoking the connector.');
        FREInvoiceMessage.FindFirst();
        SendMessage(FREInvoiceMessage);
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'One Collected message must be sent.');
        AssertPayloadStatus(MessageSenderMock.GetLastPayload(), '212');
        AssertPayloadAmount(MessageSenderMock.GetLastPayload(), 120, 'EUR');
        AssertPayloadDateFormat(MessageSenderMock.GetLastPayload(), '204');
    end;

    [Test]
    procedure PaymentApplicationForClearedDocumentCreatesCollected()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Applying a payment to a cleared French E-Document creates a Collected message
        Initialize();

        // [GIVEN] A cleared outgoing French E-Document with an applied customer payment
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Cleared);

        // [WHEN] The payment application is processed
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

        // [THEN] One Collected lifecycle message is created for the E-Document
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 1);
    end;

    [Test]
    procedure PaymentApplicationForSentDocumentDoesNotCreateCollected()
    var
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Applying a payment to a sent French E-Document does not create a Collected message
        Initialize();

        // [GIVEN] A sent outgoing French E-Document with an applied customer payment
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Sent);

        // [WHEN] The payment application is processed
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

        // [THEN] The generic payment occurrence is created but no French lifecycle message is created
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocPaymentOccurrence.SetRange(Type, EDocPaymentOccurrence.Type::Applied);
        Assert.RecordCount(EDocPaymentOccurrence, 1);
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 0);
    end;

    [Test]
    procedure PaymentUnapplicationSendsLinkedNegativeCollected()
    var
        EDocument: Record "E-Document";
        CollectedMessage: Record "FR E-Invoice Message";
        AppliedOccurrence: Record "E-Doc. Payment Occurrence";
        NegativeMessage: Record "FR E-Invoice Message";
        ReversedOccurrence: Record "E-Doc. Payment Occurrence";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);
        CollectedMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedMessage.SetRange(Type, CollectedMessage.Type::Collected);
        CollectedMessage.FindFirst();
        SendMessage(CollectedMessage);
        CreateDetailedLedgerEntry(NewDetailedCustLedgEntry, DetailedCustLedgEntry."Cust. Ledger Entry No.", DetailedCustLedgEntry."Applied Cust. Ledger Entry No.", -120);

        FREInvoiceMessageMgt.ProcessUnapplication(DetailedCustLedgEntry, NewDetailedCustLedgEntry);

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
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'Unapplication must queue the reversal without invoking the connector.');
        SendMessage(NegativeMessage);
        Assert.AreEqual(2, MessageSenderMock.GetSendCount(), 'Collected and Negative Collected messages must be sent.');
        AssertPayloadAmount(MessageSenderMock.GetLastPayload(), -120, 'EUR');
    end;

    [Test]
    procedure RefusalSendsStatusAndReason()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);

        FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'PRICE', 'The amount is incorrect.');

        Assert.AreEqual(0, MessageSenderMock.GetSendCount(), 'Refusal must queue the message without invoking the connector.');
        SendFirstMessage(EDocument, "FR E-Invoice Message Type"::Refused);
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'One refusal message must be sent.');
        Assert.AreEqual("E-Doc. Response Type"::Refused, MessageSenderMock.GetLastResponseType(), 'The child message must be Refused.');
        AssertPayloadStatus(MessageSenderMock.GetLastPayload(), '210');
        AssertPayloadReasonCode(MessageSenderMock.GetLastPayload(), 'PRICE');
    end;

    [Test]
    procedure RefusalWithoutReasonSendsStatusWithoutReasonElements()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A buyer can refuse an invoice without providing a reason
        Initialize();

        // [GIVEN] An incoming French purchase invoice
        CreateIncomingEDocument(EDocument);

        // [WHEN] The invoice is refused without a reason code or description
        FREInvoiceMessageMgt.RefuseInvoice(EDocument, '', '');
        SendFirstMessage(EDocument, "FR E-Invoice Message Type"::Refused);

        // [THEN] The refusal status is sent without empty reason elements
        AssertPayloadStatus(MessageSenderMock.GetLastPayload(), '210');
        AssertPayloadHasNoReason(MessageSenderMock.GetLastPayload());
    end;

    [Test]
    procedure MessageSenderMustReportSuccess()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        MessageEntryNo: Integer;
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');
        MessageEntryNo := EDocumentMessageAPI.CreateMessage(
            EDocument, "E-Document Message Type"::"FR Invoice Lifecycle", "E-Doc. Response Type"::Refused, TempBlob);
        MessageSenderMock.SetReportSuccess(false);

        asserterror EDocumentMessageAPI.SendMessage(MessageEntryNo);

        Assert.ExpectedError('could not be sent');
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'The connector must be invoked before its missing success result is rejected.');
    end;

    [Test]
    procedure PaymentApplicationReplayIsIdempotent()
    var
        EDocument: Record "E-Document";
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

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
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] A Collected message retains the sender-platform identity captured from its service
        Initialize();

        // [GIVEN] An eligible payment and a French service with sender-platform identity
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment is processed and the service identity is subsequently changed
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);
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
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] A Collected message emits the complete PPF platform context
        Initialize();

        // [GIVEN] An eligible payment and a French service with sender-platform identity
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment is processed and its lifecycle message is sent
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        FREInvoiceMessage.FindFirst();
        SendMessage(FREInvoiceMessage);

        // [THEN] The payload contains the PPF profile, sender, issuer, recipient, and invoice dates
        AssertPayloadPPFContext(MessageSenderMock.GetLastPayload(), EDocument);
    end;

    [Test]
    procedure CollectedMessageAllowsMissingSenderPlatformIdentity()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] A Collected message supports a service without optional sender-platform identity
        Initialize();

        // [GIVEN] An eligible payment whose service has no sender-platform ID
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);
        EDocumentService.Get(EDocument.Service);
        Clear(EDocumentService."FR Sender Platform ID");
        EDocumentService.Modify();

        // [WHEN] The payment is processed
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

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
        EDocumentService: Record "E-Document Service";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] A Collected message without platform identity retains the CDV profile
        Initialize();

        // [GIVEN] An eligible payment whose service has no sender-platform identity
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);
        EDocumentService.Get(EDocument.Service);
        Clear(EDocumentService."FR Sender Platform ID");
        EDocumentService.Modify();

        // [WHEN] The payment is processed and its lifecycle message is sent
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        FREInvoiceMessage.FindFirst();
        SendMessage(FREInvoiceMessage);

        // [THEN] The payload uses the CDV profile and does not contain PPF trade parties
        AssertPayloadCDVContext(MessageSenderMock.GetLastPayload());
    end;

    [Test]
    procedure SingleRateFullPaymentCreatesOneVATRow()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Single-rate full payment creates one frozen VAT row summing to reportable amount
        Initialize();

        // [GIVEN] An approved French E-Document with unrealized VAT at 20% and a full payment applied
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment application is processed
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

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
        SendMessage(FREInvoiceMessage);
        AssertPayloadVATCharacteristic(MessageSenderMock.GetLastPayload(), FREInvoiceMessage.Amount, 20);
    end;

    [Test]
    procedure SingleRatePartialPaymentAllocatesPartialAmount()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageVAT: Record "FR E-Invoice Message VAT";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Single-rate partial payment allocates partial amount
        Initialize();

        // [GIVEN] An approved French E-Document with unrealized VAT at 20% and a partial payment of 60 applied
        CreatePaymentScenarioWithAmount(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved, 60);

        // [WHEN] The payment application is processed
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

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
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Mixed invoice with unrealized and realized VAT reports only proportional eligible share
        Initialize();

        // [GIVEN] An invoice with one unrealized-VAT line (20%, gross 120) and one realized-VAT line (10%, gross 110), full payment of 230
        CreateMixedVATPaymentScenario(EDocument, DetailedCustLedgEntry);

        // [WHEN] The payment application is processed
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

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
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
        VATRowSum: Decimal;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Multiple eligible VAT rates with rounding residue sum exactly to message amount
        Initialize();

        // [GIVEN] An invoice with three unrealized VAT rates (10%, 20%, 7%) and a partial payment of 99 causing rounding residue
        CreateMultiRatePaymentScenario(EDocument, DetailedCustLedgEntry);

        // [WHEN] The payment application is processed
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

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
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Invoice without unrealized VAT keeps generic payment occurrence but creates no FR Collected message
        Initialize();

        // [GIVEN] An approved French E-Document with ordinary (non-unrealized) VAT and an applied payment
        CreateNormalVATPaymentScenario(EDocument, DetailedCustLedgEntry);

        // [WHEN] The payment application is processed
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

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
        VATPostingSetup: Record "VAT Posting Setup";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Reversal copies original frozen rows with negated values even if VAT setup changes after original
        Initialize();

        // [GIVEN] A collected message with a frozen VAT breakdown
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);
        CollectedMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedMessage.SetRange(Type, CollectedMessage.Type::Collected);
        CollectedMessage.FindFirst();
        SendMessage(CollectedMessage);
        OriginalVAT.SetRange("Message Entry No.", CollectedMessage."Entry No.");
        OriginalVAT.FindFirst();

        // [GIVEN] VAT and sender-platform setup are changed after the original message
        VATPostingSetup.SetRange("Tax Category", 'S');
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.FindFirst();
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
        FREInvoiceMessageMgt.ProcessUnapplication(DetailedCustLedgEntry, NewDetailedCustLedgEntry);

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
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO 647421] Replay is idempotent and does not duplicate allocation rows
        Initialize();

        // [GIVEN] An approved French E-Document with unrealized VAT
        CreatePaymentScenario(EDocument, DetailedCustLedgEntry, "E-Document Service Status"::Approved);

        // [WHEN] The payment application is processed twice
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);
        FREInvoiceMessageMgt.ProcessApplication(DetailedCustLedgEntry);

        // [THEN] Only one message and one VAT row exist
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Collected);
        Assert.RecordCount(FREInvoiceMessage, 1);
        FREInvoiceMessage.FindFirst();
        FREInvoiceMessageVAT.SetRange("Message Entry No.", FREInvoiceMessage."Entry No.");
        Assert.RecordCount(FREInvoiceMessageVAT, 1);
    end;

    [Test]
    procedure IncomingMessageIsCorrelatedAndDeduplicated()
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
        Initialize();
        CreateIncomingEDocument(EDocument);
        ExternalDocumentID := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ExternalDocumentID));
        ExternalMessageID := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ExternalMessageID));
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocumentID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');

        FirstMessageEntryNo := EDocumentMessageAPI.CreateIncomingMessage(
            EDocument.Service, ExternalDocumentID, ExternalMessageID, "E-Document Message Type"::"FR Invoice Lifecycle",
            "E-Doc. Response Type"::Refused, CurrentDateTime(), TempBlob);
        DuplicateMessageEntryNo := EDocumentMessageAPI.CreateIncomingMessage(
            EDocument.Service, ExternalDocumentID, ExternalMessageID, "E-Document Message Type"::"FR Invoice Lifecycle",
            "E-Doc. Response Type"::Refused, CurrentDateTime(), TempBlob);

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
        Initialize();
        CreateIncomingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');

        asserterror EDocumentMessageAPI.CreateIncomingMessage(
            EDocument.Service, CopyStr(Format(CreateGuid()), 1, 250), CopyStr(Format(CreateGuid()), 1, 250),
            "E-Document Message Type"::"FR Invoice Lifecycle", "E-Doc. Response Type"::Refused, CurrentDateTime(), TempBlob);

        Assert.ExpectedError('is not registered');
    end;

    [Test]
    procedure BuyerAcceptanceQueuesAndSendsStatus205()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);

        FREInvoiceMessageMgt.AcceptInvoice(EDocument);

        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Accepted);
        Assert.RecordCount(FREInvoiceMessage, 1);
        Assert.AreEqual(0, MessageSenderMock.GetSendCount(), 'Acceptance must queue the message without invoking the connector.');
        SendFirstMessage(EDocument, "FR E-Invoice Message Type"::Accepted);
        Assert.AreEqual(1, MessageSenderMock.GetSendCount(), 'One Accepted message must be sent.');
        Assert.AreEqual("E-Doc. Response Type"::Accepted, MessageSenderMock.GetLastResponseType(), 'The child message must be Accepted.');
        AssertPayloadStatus(MessageSenderMock.GetLastPayload(), '205');
    end;

    [Test]
    procedure BuyerResponseCannotBeRepeated()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);

        FREInvoiceMessageMgt.AcceptInvoice(EDocument);
        asserterror FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'OTHER', 'Changed my mind.');
        Assert.ExpectedError('already has a buyer response');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure BuyerResponseCannotBeRepeatedAfterRefusal()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessageMgt: Codeunit "FR E-Invoice Message Mgt.";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);

        FREInvoiceMessageMgt.RefuseInvoice(EDocument, 'OTHER', 'Not accepted.');
        asserterror FREInvoiceMessageMgt.AcceptInvoice(EDocument);
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
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        ReceivedAt := CreateDateTime(20260101D, 120000T);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Submitted', '', ''));

        FREntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, ReceivedAt, TempBlob);

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
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", '205', '', ''));

        FREntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);

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
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Rejetée', 'SCHEMA', 'Schema validation failed'));

        FREntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);

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
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
        ExternalMsgID: Text[250];
        FirstEntryNo: Integer;
        SecondEntryNo: Integer;
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        ExternalMsgID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Submitted', '', ''));

        FirstEntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Submitted', '', ''));
        SecondEntryNo := FREInvoiceMessageAPI.ReceiveMessage(EDocument.Service, ExternalDocID, ExternalMsgID, CurrentDateTime(), TempBlob);

        Assert.AreEqual(FirstEntryNo, SecondEntryNo, 'Same external message ID must return same FR entry.');
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, FREInvoiceMessage.Type::Submitted);
        Assert.RecordCount(FREInvoiceMessage, 1);
    end;

    [Test]
    procedure ReceiveMessageRejectsInvalidXml()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('not xml at all');

        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        Assert.ExpectedError('not valid XML');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveMessageRejectsUnsupportedStatus()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Unknown', '', ''));

        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        Assert.ExpectedError('is not supported');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveMessageRejectsInvoiceMismatch()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml('WRONG-INVOICE-ID', 'Submitted', '', ''));

        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        Assert.ExpectedError('does not match');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveTechnicalRejectedRequiresReasonCode()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Rejected', '', 'Something went wrong'));

        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        Assert.ExpectedError('reason code is required');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure ReceiveTechnicalRejectedRequiresReasonDescription()
    var
        EDocument: Record "E-Document";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceMessageAPI: Codeunit "FR E-Invoice Message API";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        ExternalDocID: Text[250];
    begin
        Initialize();
        CreateOutgoingEDocument(EDocument);
        ExternalDocID := CopyStr(Format(CreateGuid()), 1, 250);
        EDocumentMessageAPI.RegisterExternalDocumentReference(EDocument, EDocument.Service, ExternalDocID);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(BuildLifecycleXml(EDocument."Document No.", 'Rejected', 'SCHEMA', ''));

        asserterror FREInvoiceMessageAPI.ReceiveMessage(
            EDocument.Service, ExternalDocID, CopyStr(Format(CreateGuid()), 1, 250), CurrentDateTime(), TempBlob);

        Assert.ExpectedError('reason description is required');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    procedure BuilderRejectsIncomingOnlyStatus()
    var
        EDocument: Record "E-Document";
        FREInvoiceMessage: Record "FR E-Invoice Message";
        FREInvoiceMessageBuilder: Codeunit "FR E-Invoice Message Builder";
        TempBlob: Codeunit "Temp Blob";
    begin
        Initialize();
        CreateIncomingEDocument(EDocument);
        FREInvoiceMessage.Init();
        FREInvoiceMessage."E-Document Entry No." := EDocument."Entry No";
        FREInvoiceMessage.Type := FREInvoiceMessage.Type::Submitted;
        FREInvoiceMessage."Source Occurrence ID" := CreateGuid();
        FREInvoiceMessage."Event Date" := Today();
        FREInvoiceMessage."Created At" := CurrentDateTime();
        FREInvoiceMessage.Insert();

        asserterror FREInvoiceMessageBuilder.BuildMessage(EDocument, FREInvoiceMessage, TempBlob);

        Assert.ExpectedError('cannot be sent');
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

    local procedure SendFirstMessage(EDocument: Record "E-Document"; MessageType: Enum "FR E-Invoice Message Type")
    var
        FREInvoiceMessage: Record "FR E-Invoice Message";
    begin
        FREInvoiceMessage.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceMessage.SetRange(Type, MessageType);
        FREInvoiceMessage.FindFirst();
        SendMessage(FREInvoiceMessage);
    end;

    local procedure SendMessage(FREInvoiceMessage: Record "FR E-Invoice Message")
    var
        EDocumentMessageAPI: Codeunit "E-Document Message API";
    begin
        EDocumentMessageAPI.SendMessage(FREInvoiceMessage."E-Document Message Entry No.");
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
    begin
        PartyPath := StrSubstNo('//*[local-name()="ExchangedDocument"]/*[local-name()="%1"]', ElementName);
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
        MessageSenderMock.Reset();
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
        if not EDocumentService.Get('FR-MESSAGE-MOCK') then begin
            EDocumentService.Init();
            EDocumentService.Code := 'FR-MESSAGE-MOCK';
            EDocumentService."Document Format" := EDocumentService."Document Format"::"Peppol BIS 3.0 FR";
            EDocumentService."Service Integration V2" := EDocumentService."Service Integration V2"::"FR Message Mock";
            EDocumentService.Insert();
        end;
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
        EDocument.Service := 'FR-MESSAGE-MOCK';
        EDocument.Insert();
    end;

    local procedure CreateOutgoingEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Document No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(EDocument."Document No."));
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Service := 'FR-MESSAGE-MOCK';
        EDocument.Insert();
    end;

    local procedure CreatePaymentScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; ServiceStatus: Enum "E-Document Service Status")
    begin
        CreatePaymentScenarioWithAmount(EDocument, DetailedCustLedgEntry, ServiceStatus, 120);
    end;

    local procedure CreatePaymentScenarioWithAmount(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; ServiceStatus: Enum "E-Document Service Status"; PaymentAmount: Decimal)
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
        EDocumentService.Get('FR-MESSAGE-MOCK');
        EDocumentService."Document Format" := EDocumentService."Document Format"::Mock;
        EDocumentService.Modify();
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::Percentage;
        VATPostingSetup."Sales VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Tax Category" := 'S';
        VATPostingSetup.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
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
        EDocument.Service := 'FR-MESSAGE-MOCK';
        EDocument.Insert();
        CreateServiceStatus(EDocument, ServiceStatus);

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine,
            GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -PaymentAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PostedInvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        FindApplicationDetailedEntry(DetailedCustLedgEntry, PostedInvoiceNo);
    end;

    local procedure CreateMixedVATPaymentScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        UnrealizedVATSetup: Record "VAT Posting Setup";
        NormalVATSetup: Record "VAT Posting Setup";
        PostedInvoiceNo: Code[20];
    begin
        EDocumentService.Get('FR-MESSAGE-MOCK');
        EDocumentService."Document Format" := EDocumentService."Document Format"::Mock;
        EDocumentService.Modify();
        LibraryERM.CreateVATPostingSetupWithAccounts(UnrealizedVATSetup, UnrealizedVATSetup."VAT Calculation Type"::"Normal VAT", 20);
        UnrealizedVATSetup."Unrealized VAT Type" := UnrealizedVATSetup."Unrealized VAT Type"::Percentage;
        UnrealizedVATSetup."Sales VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        UnrealizedVATSetup."Tax Category" := 'S';
        UnrealizedVATSetup.Modify(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(NormalVATSetup, NormalVATSetup."VAT Calculation Type"::"Normal VAT", 10);
        NormalVATSetup.Rename(UnrealizedVATSetup."VAT Bus. Posting Group", NormalVATSetup."VAT Prod. Posting Group");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", UnrealizedVATSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(UnrealizedVATSetup, "General Posting Type"::Sale), 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(NormalVATSetup, "General Posting Type"::Sale), 1);
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
        EDocument.Service := 'FR-MESSAGE-MOCK';
        EDocument.Insert();
        CreateServiceStatus(EDocument, "E-Document Service Status"::Approved);

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine,
            GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -230);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PostedInvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindApplicationDetailedEntry(DetailedCustLedgEntry, PostedInvoiceNo);
    end;

    local procedure CreateMultiRatePaymentScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        Customer: Record Customer;
        EDocumentService: Record "E-Document Service";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        VATSetup10: Record "VAT Posting Setup";
        VATSetup20: Record "VAT Posting Setup";
        VATSetup7: Record "VAT Posting Setup";
        PostedInvoiceNo: Code[20];
    begin
        EDocumentService.Get('FR-MESSAGE-MOCK');
        EDocumentService."Document Format" := EDocumentService."Document Format"::Mock;
        EDocumentService.Modify();
        LibraryERM.CreateVATPostingSetupWithAccounts(VATSetup20, VATSetup20."VAT Calculation Type"::"Normal VAT", 20);
        VATSetup20."Unrealized VAT Type" := VATSetup20."Unrealized VAT Type"::Percentage;
        VATSetup20."Sales VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATSetup20."Tax Category" := 'S';
        VATSetup20.Modify(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATSetup10, VATSetup10."VAT Calculation Type"::"Normal VAT", 10);
        VATSetup10.Rename(VATSetup20."VAT Bus. Posting Group", VATSetup10."VAT Prod. Posting Group");
        VATSetup10."Unrealized VAT Type" := VATSetup10."Unrealized VAT Type"::Percentage;
        VATSetup10."Sales VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATSetup10."Tax Category" := 'S';
        VATSetup10.Modify(true);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATSetup7, VATSetup7."VAT Calculation Type"::"Normal VAT", 7);
        VATSetup7.Rename(VATSetup20."VAT Bus. Posting Group", VATSetup7."VAT Prod. Posting Group");
        VATSetup7."Unrealized VAT Type" := VATSetup7."Unrealized VAT Type"::Percentage;
        VATSetup7."Sales VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATSetup7."Tax Category" := 'S';
        VATSetup7.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATSetup20."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATSetup20, "General Posting Type"::Sale), 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATSetup10, "General Posting Type"::Sale), 1);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATSetup7, "General Posting Type"::Sale), 1);
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
        EDocument.Service := 'FR-MESSAGE-MOCK';
        EDocument.Insert();
        CreateServiceStatus(EDocument, "E-Document Service Status"::Approved);

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine,
            GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -99);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PostedInvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindApplicationDetailedEntry(DetailedCustLedgEntry, PostedInvoiceNo);
    end;

    local procedure CreateNormalVATPaymentScenario(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
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
        EDocumentService.Get('FR-MESSAGE-MOCK');
        EDocumentService."Document Format" := EDocumentService."Document Format"::Mock;
        EDocumentService.Modify();
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
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
        EDocument.Service := 'FR-MESSAGE-MOCK';
        EDocument.Insert();
        CreateServiceStatus(EDocument, "E-Document Service Status"::Approved);

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine,
            GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -110);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PostedInvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        FindApplicationDetailedEntry(DetailedCustLedgEntry, PostedInvoiceNo);
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

    local procedure GetNextDetailedLedgerEntryNo(): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if DetailedCustLedgEntry.FindLast() then
            exit(DetailedCustLedgEntry."Entry No." + 1);
        exit(1);
    end;
}