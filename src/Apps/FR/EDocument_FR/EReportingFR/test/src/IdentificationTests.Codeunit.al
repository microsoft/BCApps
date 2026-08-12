// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Utilities;

codeunit 148146 "Identification Tests"
{
    Subtype = Test;
    Permissions = tabledata "Company Information" = rimd,
                  tabledata "E-Document" = rimd,
                  tabledata "E-Document Service" = rimd,
                  tabledata "E-Document Service Status" = rimd,
                  tabledata "General Ledger Setup" = rimd,
                  tabledata "Sales Invoice Header" = rimd,
                  tabledata "Cust. Ledger Entry" = rimd,
                  tabledata "Detailed Cust. Ledg. Entry" = rimd,
                  tabledata "FR E-Invoice Lifecycle" = rimd,
                  tabledata "FR E-Invoice Lifecycle VAT" = rimd,
                  tabledata "VAT Entry" = rimd,
                  tabledata "VAT Posting Setup" = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [FR Identification]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        EDocHelpers: Codeunit "EDoc. Helpers";
        ImmutableLifecycleErr: Label 'The regulatory identity and values of a French electronic invoice lifecycle occurrence cannot be changed.', Locked = true;
        ImmutableLifecycleVATErr: Label 'A French electronic invoice lifecycle VAT breakdown cannot be changed.', Locked = true;
        WorkerFailureErr: Label 'Lifecycle worker test failure.', Locked = true;
        XmlNodeMissingErr: Label 'The payload must contain XML node %1.', Comment = '%1 = XML path', Locked = true;
        XmlNodeValueErr: Label 'The XML node %1 has an unexpected value.', Comment = '%1 = XML path', Locked = true;
        XmlAttributeMissingErr: Label 'The XML node %1 must contain attribute %2.', Comment = '%1 = XML path, %2 = attribute name', Locked = true;
        XmlAttributeValueErr: Label 'The XML attribute %1 on node %2 has an unexpected value.', Comment = '%1 = attribute name, %2 = XML path', Locked = true;
        IsInitialized: Boolean;

    [Test]
    procedure CheckSIRENNotEmptyRaisesErrorWhenEmpty()
    var
        CompanyInformation: Record "Company Information";
        OriginalRegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRENNotEmpty raises error when Registration No. is blank
        Initialize();

        // [GIVEN] Company Information with blank Registration No.
        CompanyInformation.Get();
        OriginalRegistrationNo := CompanyInformation."Registration No.";
        CompanyInformation."Registration No." := '';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRENNotEmpty is called
        // [THEN] Error is raised
        asserterror EDocHelpers.CheckSIRENNotEmpty();
        Assert.ExpectedError('Registration No. must be specified in Company Information for French e-invoicing.');

        CompanyInformation.Get();
        CompanyInformation."Registration No." := CopyStr(OriginalRegistrationNo, 1, MaxStrLen(CompanyInformation."Registration No."));
        CompanyInformation.Modify();
    end;

    [Test]
    procedure CheckSIRETNotEmptyRaisesErrorWhenEmpty()
    var
        CompanyInformation: Record "Company Information";
        OriginalSIRETNo: Code[14];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRETNotEmpty raises error when SIRET is blank
        Initialize();

        // [GIVEN] Company Information with blank SIRET No.
        CompanyInformation.Get();
        OriginalSIRETNo := CompanyInformation."SIRET No.";
        CompanyInformation."SIRET No." := '';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRETNotEmpty is called
        // [THEN] Error is raised
        asserterror EDocHelpers.CheckSIRETNotEmpty();
        Assert.ExpectedError('SIRET No. must be specified in Company Information for French e-invoicing.');

        CompanyInformation.Get();
        CompanyInformation."SIRET No." := OriginalSIRETNo;
        CompanyInformation.Modify();
    end;

    [Test]
    procedure CheckSIRENNotEmptyDoesNotErrorWhenRegistrationNoPresent()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRENNotEmpty succeeds when Registration No. is set
        Initialize();

        // [GIVEN] Company Information with Registration No. set
        CompanyInformation.Get();
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRENNotEmpty is called
        // [THEN] No error is raised
        EDocHelpers.CheckSIRENNotEmpty();
    end;

    [Test]
    procedure CheckSIRETNotEmptyDoesNotErrorWhenSIRETPresent()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRETNotEmpty succeeds when SIRET No. is set
        Initialize();

        // [GIVEN] Company Information with SIRET No. set
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := '12345678901234';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRETNotEmpty is called
        // [THEN] No error is raised
        EDocHelpers.CheckSIRETNotEmpty();
    end;

    [Test]
    procedure CaptureCollectedOccurrenceCreatesCapturedLifecycle()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        SourceOccurrenceID: Guid;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A payment application is captured as an immutable Collected lifecycle occurrence
        Initialize();

        // [GIVEN] An E-Document "ED" and a source occurrence ID
        CreateEDocument(EDocument);
        SourceOccurrenceID := CreateGuid();

        // [WHEN] A Collected lifecycle occurrence is captured for "ED"
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        // [THEN] The lifecycle occurrence retains its regulatory values and is Captured
        Assert.AreEqual(EDocument."Entry No", FREInvoiceLifecycle."E-Document Entry No.", 'The e-document entry must be retained.');
        Assert.AreEqual(1250, FREInvoiceLifecycle."Reported Amount", 'The reported amount must be retained.');
        Assert.AreEqual('EUR', FREInvoiceLifecycle."Currency Code", 'A foreign currency code must be retained.');
        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::Captured, FREInvoiceLifecycle."Processing Status", 'A new occurrence must be captured.');
        Assert.IsTrue(FREInvoiceLifecycle."Created At" <> 0DT, 'The creation timestamp must be populated.');
    end;

    [Test]
    procedure CaptureCollectedOccurrenceKeepsBlankCurrencyForLCY()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A local-currency payment occurrence keeps the Business Central blank currency representation
        Initialize();

        // [GIVEN] An E-Document "ED" in a company with LCY configured
        CreateEDocument(EDocument);

        // [WHEN] A Collected lifecycle occurrence is captured with blank currency
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, '', WorkDate(), 0, 0, 0, 0);

        // [THEN] The lifecycle currency remains blank
        Assert.AreEqual('', FREInvoiceLifecycle."Currency Code", 'Local currency must remain blank on the lifecycle record.');
    end;

    [Test]
    procedure CaptureCollectedOccurrenceReplayReturnsExistingLifecycle()
    var
        EDocument: Record "E-Document";
        FirstLifecycle: Record "FR E-Invoice Lifecycle";
        ReplayedLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        SourceOccurrenceID: Guid;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Replaying the same payment event does not create a duplicate occurrence
        Initialize();

        // [GIVEN] A Collected occurrence for E-Document "ED"
        CreateEDocument(EDocument);
        SourceOccurrenceID := CreateGuid();
        FirstLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        // [WHEN] The same source occurrence is captured again
        ReplayedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        // [THEN] The original lifecycle occurrence is returned
        Assert.AreEqual(FirstLifecycle."Entry No.", ReplayedLifecycle."Entry No.", 'An identical replay must return the existing occurrence.');
    end;

    [Test]
    procedure CaptureCollectedOccurrenceRejectsConflictingReplay()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        SourceOccurrenceID: Guid;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A replay with the same identity but different regulatory values is rejected
        Initialize();

        // [GIVEN] A Collected occurrence for E-Document "ED"
        CreateEDocument(EDocument);
        SourceOccurrenceID := CreateGuid();
        FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        // [WHEN] The same source occurrence is captured with a different amount
        asserterror FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1200, 'EUR', WorkDate(), 0, 0, 0, 0);

        // [THEN] A conflicting replay error is raised
        Assert.ExpectedError('The payment lifecycle occurrence was already captured with different values.');
    end;

    [Test]
    procedure CaptureNegativeCollectedLinksExactReversal()
    var
        EDocument: Record "E-Document";
        CollectedLifecycle: Record "FR E-Invoice Lifecycle";
        NegativeCollectedLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Unapplication creates a separate Negative Collected occurrence linked to Collected
        Initialize();

        // [GIVEN] A Collected occurrence for E-Document "ED"
        CreateEDocument(EDocument);
        CollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        // [WHEN] A matching Negative Collected occurrence is captured
        NegativeCollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::"Negative Collected", CreateGuid(),
            -1250, 'EUR', WorkDate(), 0, 0, 0, CollectedLifecycle."Entry No.");

        // [THEN] The reversal is linked and exactly negates the original amount
        Assert.AreEqual(CollectedLifecycle."Entry No.", NegativeCollectedLifecycle."Original Occurrence Entry No.", 'The reversal must reference the Collected occurrence.');
        Assert.AreEqual(-CollectedLifecycle."Reported Amount", NegativeCollectedLifecycle."Reported Amount", 'The reversal must negate the original amount.');
    end;

    [Test]
    procedure CaptureNegativeCollectedRejectsDifferentAmount()
    var
        EDocument: Record "E-Document";
        CollectedLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Negative Collected cannot reverse a different amount than its original occurrence
        Initialize();

        // [GIVEN] A Collected occurrence for E-Document "ED"
        CreateEDocument(EDocument);
        CollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        // [WHEN] A Negative Collected occurrence is captured with a different amount
        asserterror FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::"Negative Collected", CreateGuid(),
            -1200, 'EUR', WorkDate(), 0, 0, 0, CollectedLifecycle."Entry No.");

        // [THEN] An exact reversal error is raised
        Assert.ExpectedError('A Negative Collected occurrence must exactly reverse the reported amount of the original Collected occurrence.');
    end;

    [Test]
    procedure CaptureNegativeCollectedRejectsMissingOriginalOccurrence()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Negative Collected cannot reference an original occurrence that does not exist
        Initialize();

        // [GIVEN] An E-Document without a Collected occurrence
        CreateEDocument(EDocument);

        // [WHEN] A Negative Collected occurrence references a nonexistent original occurrence
        asserterror FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::"Negative Collected", CreateGuid(),
            -1250, 'EUR', WorkDate(), 0, 0, 0, 999999);

        // [THEN] The orphan reversal is rejected
        Assert.ExpectedError('The original Collected occurrence does not exist.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CapturedOccurrenceRejectsRegulatoryValueChanges()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Captured regulatory values cannot be changed in place
        Initialize();

        // [GIVEN] A committed Collected occurrence for E-Document "ED"
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);
        Commit();

        // [WHEN] The reported amount is changed
        FREInvoiceLifecycle."Reported Amount" := 1200;
        asserterror FREInvoiceLifecycle.Modify(true);

        // [THEN] The change is rejected
        Assert.ExpectedError('The regulatory identity and values of a French electronic invoice lifecycle occurrence cannot be changed.');

        // [WHEN] The sender platform ID is changed
        FREInvoiceLifecycle.Get(FREInvoiceLifecycle."Entry No.");
        FREInvoiceLifecycle."Sender Platform ID" := 'CHANGED';
        asserterror FREInvoiceLifecycle.Modify(true);

        // [THEN] The change is rejected
        Assert.ExpectedError('The regulatory identity and values of a French electronic invoice lifecycle occurrence cannot be changed.');
    end;

    [Test]
    procedure SenderPlatformSchemeDefaultsTo0238()
    var
        EDocumentService: Record "E-Document Service";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] French lifecycle setup defaults the sender platform identifier scheme to 0238
        Initialize();

        // [WHEN] A new E-Document Service is initialized
        EDocumentService.Init();

        // [THEN] The sender platform scheme defaults to 0238
        Assert.AreEqual('0238', EDocumentService."FR Sender Platform Scheme", 'The sender platform scheme must default to 0238.');
    end;

    [Test]
    procedure DetailedApplicationCapturesCollectedForFREInvoice()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Applying a payment to a French electronic invoice captures a Collected occurrence
        Initialize();

        // [GIVEN] A payment application for French E-Invoice "ED"
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");

        // [WHEN] The detailed ledger application is processed
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [THEN] A Collected occurrence retains the source and invoice values
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();
        Assert.AreEqual(FREInvoiceLifecycle."Lifecycle Status"::Collected, FREInvoiceLifecycle."Lifecycle Status", 'A payment application must create a Collected occurrence.');
        Assert.AreEqual(-DetailedCustLedgEntry.Amount, FREInvoiceLifecycle."Reported Amount", 'The reported amount must equal the negated detailed ledger entry amount.');
        Assert.IsTrue(FREInvoiceLifecycle."Reported Amount" > 0, 'The collected amount must be positive.');
        Assert.AreEqual(DetailedCustLedgEntry."Entry No.", FREInvoiceLifecycle."Detailed Ledger Entry No.", 'The source detail entry must be retained.');
        Assert.AreEqual(DetailedCustLedgEntry.SystemId, FREInvoiceLifecycle."Source Occurrence ID", 'The detail entry system ID must identify the occurrence.');
        Assert.AreEqual(EDocument."Document Date", FREInvoiceLifecycle."Invoice Issue Date", 'The invoice issue date must be frozen at capture.');
        Assert.AreEqual(EDocument."Clearance Date", FREInvoiceLifecycle."Invoice Receipt At", 'The PPF receipt timestamp must be frozen at capture.');
        Assert.AreEqual('PLATFORM-ID', FREInvoiceLifecycle."Sender Platform ID", 'The sender platform identifier must be frozen at capture.');
        Assert.AreEqual('123456789', FREInvoiceLifecycle."Invoice Issuer ID", 'The seller SIREN must be frozen at capture.');
    end;

    [Test]
    procedure DetailedApplicationCreatesPPFLifecycleMessage()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        XmlDoc: XmlDocument;
        XmlNode: XmlNode;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A real French invoice occurrence creates the PPF einvoicingF2 lifecycle envelope
        Initialize();

        // [GIVEN] A captured occurrence for French E-Invoice "ED"
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();

        // [WHEN] The lifecycle message is created
        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);

        // [THEN] The payload contains the PPF einvoicingF2 envelope values
        EDocumentMessageAPI.GetMessageBlob(FREInvoiceLifecycle."E-Document Message Entry No.", TempBlob);
        TempBlob.CreateInStream(InStream);
        XmlDocument.ReadFrom(InStream, XmlDoc);
        AssertXmlValue(XmlDoc, '//*[local-name()="GuidelineSpecifiedDocumentContextParameter"]/*[local-name()="ID"]', 'urn.cpro.gouv.fr:1p0:CDV:einvoicingF2');
        AssertXmlValue(XmlDoc, '//*[local-name()="SenderTradeParty"]/*[local-name()="GlobalID"]', 'PLATFORM-ID');
        AssertXmlAttribute(XmlDoc, '//*[local-name()="SenderTradeParty"]/*[local-name()="GlobalID"]', 'schemeID', '0238');
        AssertXmlValue(XmlDoc, '//*[local-name()="SenderTradeParty"]/*[local-name()="RoleCode"]', 'WK');
        AssertXmlValue(XmlDoc, '//*[local-name()="ExchangedDocument"]/*[local-name()="IssuerTradeParty"]/*[local-name()="GlobalID"]', '123456789');
        AssertXmlAttribute(XmlDoc, '//*[local-name()="ExchangedDocument"]/*[local-name()="IssuerTradeParty"]/*[local-name()="GlobalID"]', 'schemeID', '0002');
        AssertXmlValue(XmlDoc, '//*[local-name()="ExchangedDocument"]/*[local-name()="IssuerTradeParty"]/*[local-name()="RoleCode"]', 'SE');
        AssertXmlValue(XmlDoc, '//*[local-name()="RecipientTradeParty"]/*[local-name()="GlobalID"]', '9998');
        AssertXmlAttribute(XmlDoc, '//*[local-name()="RecipientTradeParty"]/*[local-name()="GlobalID"]', 'schemeID', '0238');
        AssertXmlValue(XmlDoc, '//*[local-name()="RecipientTradeParty"]/*[local-name()="RoleCode"]', 'DFH');
        AssertXmlValue(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ReferenceTypeCode"]', 'urn.cpro.gouv.fr:1p0:CDV:einvoicingF2');
        AssertXmlValue(
            XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ReceiptDateTime"]/*[local-name()="DateTimeString"]',
            Format(EDocument."Clearance Date", 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
        AssertXmlAttribute(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="ReceiptDateTime"]/*[local-name()="DateTimeString"]', 'format', '204');
        AssertXmlValue(
            XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="FormattedIssueDateTime"]/*[local-name()="DateTimeString"]',
            Format(EDocument."Document Date", 0, '<Year4><Month,2><Day,2>'));
        AssertXmlAttribute(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="FormattedIssueDateTime"]/*[local-name()="DateTimeString"]', 'format', '102');
        AssertXmlValue(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="IssuerTradeParty"]/*[local-name()="GlobalID"]', '123456789');
        AssertXmlAttribute(XmlDoc, '//*[local-name()="ReferenceReferencedDocument"]/*[local-name()="IssuerTradeParty"]/*[local-name()="GlobalID"]', 'schemeID', '0002');
        Assert.IsFalse(XmlDoc.SelectSingleNode('//*[local-name()="BusinessProcessSpecifiedDocumentContextParameter"]', XmlNode), 'The PPF profile must not contain the generic REGULATED business process context.');
    end;

    [Test]
    procedure DetailedApplicationAggregatesVATEntriesWithSameRate()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Multiple invoice VAT entries with the same rate create one lifecycle amount
        Initialize();

        // [GIVEN] A French E-Invoice "ED" with multiple VAT entries at 20 percent
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        SetInvoiceVATRate(EDocument."Document No.", 20, false);

        // [WHEN] The detailed ledger application is processed
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [THEN] One aggregated VAT breakdown line is captured
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();
        FREInvoiceLifecycleVAT.SetRange("Lifecycle Entry No.", FREInvoiceLifecycle."Entry No.");
        Assert.RecordCount(FREInvoiceLifecycleVAT, 1);
        FREInvoiceLifecycleVAT.FindFirst();
        Assert.AreEqual(20, FREInvoiceLifecycleVAT."VAT %", 'The aggregated lifecycle amount must retain the common VAT rate.');
        Assert.AreEqual(1000, FREInvoiceLifecycleVAT."Reported Amount", 'The aggregated lifecycle amount must equal the collected amount.');
    end;

    [Test]
    procedure DetailedApplicationSupportsZeroRatedVAT()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A zero-rated invoice retains VAT rate zero in the lifecycle breakdown
        Initialize();

        // [GIVEN] A French E-Invoice "ED" with zero-rated VAT
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        SetInvoiceVATRate(EDocument."Document No.", 0, true);

        // [WHEN] The detailed ledger application is processed
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [THEN] One zero-rated VAT breakdown line is captured
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();
        FREInvoiceLifecycleVAT.SetRange("Lifecycle Entry No.", FREInvoiceLifecycle."Entry No.");
        Assert.RecordCount(FREInvoiceLifecycleVAT, 1);
        FREInvoiceLifecycleVAT.FindFirst();
        Assert.AreEqual(0, FREInvoiceLifecycleVAT."VAT %", 'The lifecycle breakdown must retain the zero VAT rate.');
        Assert.AreEqual(1000, FREInvoiceLifecycleVAT."Reported Amount", 'The zero-rated lifecycle amount must equal the collected amount.');
    end;

    [Test]
    procedure DetailedApplicationUsesForeignCurrencyRoundingPrecision()
    var
        Currency: Record Currency;
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Foreign-currency VAT allocation uses that currency's rounding precision and preserves the remainder
        Initialize();

        // [GIVEN] A French E-Invoice "ED" paid in a currency with 0.05 rounding precision
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        CurrencyCode := CopyStr(CreateGuid(), 1, MaxStrLen(CurrencyCode));
        Currency.Code := CurrencyCode;
        Currency."Amount Rounding Precision" := 0.05;
        Currency.Insert();
        DetailedCustLedgEntry.Amount := -1000.03;
        DetailedCustLedgEntry."Currency Code" := CurrencyCode;
        DetailedCustLedgEntry.Modify();
        SetInvoiceVATCurrency(EDocument."Document No.", CurrencyCode);

        // [WHEN] The detailed ledger application is processed
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [THEN] VAT is rounded by currency and the final line retains the remainder
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();
        FREInvoiceLifecycleVAT.SetRange("Lifecycle Entry No.", FREInvoiceLifecycle."Entry No.");
        FREInvoiceLifecycleVAT.SetRange("VAT %", 20);
        FREInvoiceLifecycleVAT.FindFirst();
        Assert.AreEqual(480, FREInvoiceLifecycleVAT."Reported Amount", 'The first VAT amount must use the foreign currency rounding precision.');
        FREInvoiceLifecycleVAT.SetRange("VAT %", 10);
        FREInvoiceLifecycleVAT.FindFirst();
        Assert.AreEqual(520.03, FREInvoiceLifecycleVAT."Reported Amount", 'The final VAT amount must retain the exact allocation remainder.');
    end;

    [Test]
    procedure DetailedApplicationRejectsMissingVATBreakdown()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        VATEntry: Record "VAT Entry";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A French lifecycle occurrence is not retained when its posted invoice has no VAT breakdown
        Initialize();

        // [GIVEN] A French E-Invoice "ED" whose VAT entries were deleted
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        VATEntry.SetRange("Document No.", EDocument."Document No.");
        VATEntry.DeleteAll();

        // [WHEN] The detailed ledger application is processed
        asserterror FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [THEN] A missing VAT breakdown error is raised and no occurrence remains
        Assert.ExpectedError('A VAT breakdown could not be determined for posted sales invoice');
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.RecordIsEmpty(FREInvoiceLifecycle);
    end;

    [Test]
    procedure DetailedApplicationWithoutSenderPlatformCreatesCDVLifecycleMessage()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        XmlDoc: XmlDocument;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A production payment flow without a configured sender platform creates the general CDV profile
        Initialize();

        // [GIVEN] A captured French E-Invoice occurrence without a sender platform ID
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        EDocumentService.Get(EDocument.Service);
        Clear(EDocumentService."FR Sender Platform ID");
        EDocumentService.Modify();

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();
        Assert.AreEqual('', FREInvoiceLifecycle."Sender Platform ID", 'The general CDV profile must not retain PPF sender information.');

        // [WHEN] The lifecycle message is created
        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);

        // [THEN] The payload uses the general CDV invoice profile
        EDocumentMessageAPI.GetMessageBlob(FREInvoiceLifecycle."E-Document Message Entry No.", TempBlob);
        TempBlob.CreateInStream(InStream);
        XmlDocument.ReadFrom(InStream, XmlDoc);
        AssertXmlValue(XmlDoc, '//*[local-name()="GuidelineSpecifiedDocumentContextParameter"]/*[local-name()="ID"]', 'urn.cpro.gouv.fr:1p0:CDV:invoice');
    end;

    [Test]
    procedure DetailedApplicationRejectsMissingVATPostingSetup()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A lifecycle occurrence is not retained when a posted VAT entry has no matching setup
        Initialize();

        // [GIVEN] A French E-Invoice "ED" whose VAT Posting Setup was deleted
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        VATEntry.SetRange("Document No.", EDocument."Document No.");
        VATEntry.FindFirst();
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        VATPostingSetup.Delete();

        // [WHEN] The detailed ledger application is processed
        asserterror FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [THEN] A missing setup error is raised and no occurrence remains
        Assert.ExpectedError('VAT Posting Setup does not exist');
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.RecordIsEmpty(FREInvoiceLifecycle);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure LifecycleOccurrenceAndVATBreakdownRejectDeletion()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Captured lifecycle occurrences and their VAT rows cannot be deleted
        Initialize();

        // [GIVEN] A committed lifecycle occurrence with a VAT breakdown
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);
        CreateLifecycleVATBreakdown(FREInvoiceLifecycle, 20, 1250);
        Commit();

        // [WHEN] The VAT breakdown line is deleted
        FREInvoiceLifecycleVAT.Get(FREInvoiceLifecycle."Entry No.", 10000);
        asserterror FREInvoiceLifecycleVAT.Delete(true);

        // [THEN] The deletion is rejected
        Assert.ExpectedError(ImmutableLifecycleVATErr);

        // [WHEN] The lifecycle occurrence is renamed
        asserterror FREInvoiceLifecycle.Rename(FREInvoiceLifecycle."Entry No." + 1);

        // [THEN] The rename is rejected
        Assert.ExpectedError(ImmutableLifecycleErr);

        // [WHEN] The lifecycle occurrence is deleted
        asserterror FREInvoiceLifecycle.Delete(true);

        // [THEN] The deletion is rejected
        Assert.ExpectedError(ImmutableLifecycleErr);
    end;

    [Test]
    procedure DetailedApplicationIgnoresNonFREInvoice()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Applying a payment to an electronic invoice in a non-French format creates no French lifecycle occurrence
        Initialize();

        // [GIVEN] A payment application for non-French E-Invoice "ED"
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"PEPPOL BIS 3.0");

        // [WHEN] The detailed ledger application is processed
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [THEN] No French lifecycle occurrence is created
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.RecordIsEmpty(FREInvoiceLifecycle);
    end;

    [Test]
    procedure DetailedApplicationReplayDoesNotRequeueCreatedMessage()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Replaying an application whose lifecycle message exists does not requeue the occurrence
        Initialize();

        // [GIVEN] A processed application with an existing lifecycle message
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();
        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);
        MessageEntryNo := FREInvoiceLifecycle."E-Document Message Entry No.";

        // [WHEN] The detailed ledger application is replayed
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [THEN] The occurrence remains Message Created and retains its message link
        FREInvoiceLifecycle.Get(FREInvoiceLifecycle."Entry No.");
        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::"Message Created", FREInvoiceLifecycle."Processing Status", 'A replay must not requeue an occurrence whose message exists.');
        Assert.AreEqual(MessageEntryNo, FREInvoiceLifecycle."E-Document Message Entry No.", 'A replay must retain the existing message link.');
    end;

    [Test]
    procedure DetailedApplicationReplayDoesNotDuplicateQueuedOccurrence()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Replaying an application while message creation is queued does not duplicate the occurrence
        Initialize();

        // [GIVEN] A processed application with a queued lifecycle occurrence
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [WHEN] The detailed ledger application is replayed
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [THEN] One queued occurrence remains
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.RecordCount(FREInvoiceLifecycle, 1);
        FREInvoiceLifecycle.FindFirst();
        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::Queued, FREInvoiceLifecycle."Processing Status", 'A replay must retain the queued status.');
    end;

    [Test]
    procedure DetailedApplicationCapturesOccurrenceForEachFREDocument()
    var
        EDocument: Record "E-Document";
        AdditionalEDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Applying a payment creates an occurrence for every eligible E-Document of the invoice
        Initialize();

        // [GIVEN] A payment application with two eligible French E-Documents
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        CreateAdditionalEDocument(AdditionalEDocument, EDocument);

        // [WHEN] The detailed ledger application is processed
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        // [THEN] One occurrence is captured for each E-Document
        FREInvoiceLifecycle.SetRange("Source Occurrence ID", DetailedCustLedgEntry.SystemId);
        Assert.RecordCount(FREInvoiceLifecycle, 2);
    end;

    [Test]
    procedure DetailedUnapplicationCapturesLinkedNegativeCollected()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CollectedLifecycle: Record "FR E-Invoice Lifecycle";
        NegativeCollectedLifecycle: Record "FR E-Invoice Lifecycle";
        CollectedLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        NegativeCollectedLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Unapplying a captured payment creates an exact linked Negative Collected occurrence
        Initialize();

        // [GIVEN] A captured payment application with a corresponding unapplication detail
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Peppol BIS 3.0 FR");
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);
        CollectedLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedLifecycle.FindFirst();
        CreateUnapplicationDetail(NewDetailedCustLedgEntry, DetailedCustLedgEntry);

        // [WHEN] The detailed ledger unapplication is processed
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerUnapplication(DetailedCustLedgEntry, NewDetailedCustLedgEntry);

        // [THEN] A linked Negative Collected occurrence exactly reverses the amount and VAT breakdown
        NegativeCollectedLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        NegativeCollectedLifecycle.SetRange("Lifecycle Status", NegativeCollectedLifecycle."Lifecycle Status"::"Negative Collected");
        NegativeCollectedLifecycle.FindFirst();
        Assert.AreEqual(-CollectedLifecycle."Reported Amount", NegativeCollectedLifecycle."Reported Amount", 'The unapplication must exactly negate the collected amount.');
        Assert.AreEqual(CollectedLifecycle."Entry No.", NegativeCollectedLifecycle."Original Occurrence Entry No.", 'The unapplication must reference the Collected occurrence.');
        Assert.AreEqual(NewDetailedCustLedgEntry."Entry No.", NegativeCollectedLifecycle."Detailed Ledger Entry No.", 'The unapplication detail entry must be retained.');
        CollectedLifecycleVAT.SetRange("Lifecycle Entry No.", CollectedLifecycle."Entry No.");
        Assert.RecordCount(CollectedLifecycleVAT, 2);
        CollectedLifecycleVAT.SetRange("VAT %", 20);
        CollectedLifecycleVAT.FindFirst();
        Assert.AreEqual(480, CollectedLifecycleVAT."Reported Amount", 'The payment amount must be allocated proportionally to the 20% VAT gross amount.');
        CollectedLifecycleVAT.SetRange("VAT %", 10);
        CollectedLifecycleVAT.FindFirst();
        Assert.AreEqual(520, CollectedLifecycleVAT."Reported Amount", 'The payment remainder must be allocated to the 10% VAT gross amount.');
        CollectedLifecycleVAT.SetRange("VAT %");
        CollectedLifecycleVAT.FindSet();
        repeat
            NegativeCollectedLifecycleVAT.Get(NegativeCollectedLifecycle."Entry No.", CollectedLifecycleVAT."Line No.");
            Assert.AreEqual(CollectedLifecycleVAT."VAT %", NegativeCollectedLifecycleVAT."VAT %", 'The reversal must retain each VAT rate.');
            Assert.AreEqual(-CollectedLifecycleVAT."Reported Amount", NegativeCollectedLifecycleVAT."Reported Amount", 'The reversal must exactly negate each VAT-rate amount.');
        until CollectedLifecycleVAT.Next() = 0;
    end;

    [Test]
    procedure CreateLifecycleMessageStoresPayloadThroughEDocumentMessageMgt()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        XmlDoc: XmlDocument;
        ProfileNode: XmlNode;
        StatusNode: XmlNode;
        VATPercentNode: XmlNode;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A captured occurrence creates and links a PR 8698 E-Document Message payload
        Initialize();

        // [GIVEN] A Collected occurrence with a VAT breakdown
        CreateEDocument(EDocument);
        CreatePaymentCustLedgerEntry(PaymentCustLedgerEntry, 'EUR');
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, PaymentCustLedgerEntry."Entry No.", 0, 0);
        CreateLifecycleVATBreakdown(FREInvoiceLifecycle, 20, 1250);

        // [WHEN] The lifecycle message is created
        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);

        // [THEN] The linked E-Document Message contains the expected lifecycle payload
        Assert.IsTrue(FREInvoiceLifecycle."E-Document Message Entry No." <> 0, 'The lifecycle occurrence must link to the created E-Document Message.');
        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::"Message Created", FREInvoiceLifecycle."Processing Status", 'The occurrence must record successful message creation.');
        EDocumentMessageAPI.GetMessageBlob(FREInvoiceLifecycle."E-Document Message Entry No.", TempBlob);
        TempBlob.CreateInStream(InStream);
        XmlDocument.ReadFrom(InStream, XmlDoc);
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ProcessConditionCode"]', StatusNode), 'The payload must contain the lifecycle status.');
        Assert.AreEqual('212', StatusNode.AsXmlElement().InnerText(), 'The payload must map Collected to the French Encaissée status code.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="SpecifiedDocumentCharacteristic"]/*[local-name()="TypeCode"]', StatusNode), 'The payload must qualify the reported amount.');
        Assert.AreEqual('MEN', StatusNode.AsXmlElement().InnerText(), 'The payload must qualify the amount as Montant encaissé.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="GuidelineSpecifiedDocumentContextParameter"]/*[local-name()="ID"]', ProfileNode), 'The payload must identify the French invoice lifecycle profile.');
        Assert.AreEqual('urn.cpro.gouv.fr:1p0:CDV:invoice', ProfileNode.AsXmlElement().InnerText(), 'The payload must use the general French invoice lifecycle profile.');
        AssertXmlValue(XmlDoc, '//*[local-name()="BusinessProcessSpecifiedDocumentContextParameter"]/*[local-name()="ID"]', 'REGULATED');
        Assert.IsFalse(XmlDoc.SelectSingleNode('//*[local-name()="SenderTradeParty"]', ProfileNode), 'The general lifecycle profile must not contain PPF sender information.');
        Assert.IsFalse(XmlDoc.SelectSingleNode('//*[local-name()="RecipientTradeParty"]', ProfileNode), 'The general lifecycle profile must not contain the PPF recipient.');
        AssertXmlAttribute(XmlDoc, '//*[local-name()="ValueAmount"]', 'currencyID', 'EUR');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ValuePercent"]', VATPercentNode), 'The payload must contain the VAT percentage.');
        Assert.AreEqual('20', VATPercentNode.AsXmlElement().InnerText(), 'The payload must retain the frozen VAT percentage.');
    end;

    [Test]
    procedure CreateLifecycleMessageIsIdempotent()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Retrying message creation does not create or link a second message
        Initialize();

        // [GIVEN] A Collected occurrence with an existing lifecycle message
        CreateEDocument(EDocument);
        CreatePaymentCustLedgerEntry(PaymentCustLedgerEntry, 'EUR');
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, PaymentCustLedgerEntry."Entry No.", 0, 0);
        CreateLifecycleVATBreakdown(FREInvoiceLifecycle, 20, 1250);
        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);
        MessageEntryNo := FREInvoiceLifecycle."E-Document Message Entry No.";

        // [WHEN] Lifecycle message creation is retried
        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);

        // [THEN] The original message link is retained
        Assert.AreEqual(MessageEntryNo, FREInvoiceLifecycle."E-Document Message Entry No.", 'A retry must retain the existing message link.');
    end;

    [Test]
    procedure CreateNegativeCollectedMessageUses212AndNegativeAmount()
    var
        EDocument: Record "E-Document";
        CollectedLifecycle: Record "FR E-Invoice Lifecycle";
        NegativeCollectedLifecycle: Record "FR E-Invoice Lifecycle";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        EDocumentMessageAPI: Codeunit "E-Document Message API";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        XmlDoc: XmlDocument;
        AmountNode: XmlNode;
        StatusNode: XmlNode;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] A Negative Collected occurrence uses status 212 with a negative collected amount
        Initialize();

        // [GIVEN] A Negative Collected occurrence with a VAT breakdown
        CreateEDocument(EDocument);
        CreatePaymentCustLedgerEntry(PaymentCustLedgerEntry, 'EUR');
        CollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, PaymentCustLedgerEntry."Entry No.", 0, 0);
        CreateLifecycleVATBreakdown(CollectedLifecycle, 20, 1250);
        NegativeCollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::"Negative Collected", CreateGuid(),
            -1250, 'EUR', WorkDate() + 1, 0, PaymentCustLedgerEntry."Entry No.", 0, CollectedLifecycle."Entry No.");
        CreateLifecycleVATBreakdown(NegativeCollectedLifecycle, 20, -1250);

        // [WHEN] The Negative Collected lifecycle message is created
        FREInvoiceLifecycleMgt.CreateLifecycleMessage(NegativeCollectedLifecycle);

        // [THEN] The payload uses status 212 and reports a negative amount
        EDocumentMessageAPI.GetMessageBlob(NegativeCollectedLifecycle."E-Document Message Entry No.", TempBlob);
        TempBlob.CreateInStream(InStream);
        XmlDocument.ReadFrom(InStream, XmlDoc);
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ProcessConditionCode"]', StatusNode), 'The payload must contain the lifecycle status.');
        Assert.AreEqual('212', StatusNode.AsXmlElement().InnerText(), 'An unapplication must retain the Encaissée status code.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ValueAmount"]', AmountNode), 'The payload must contain the collected amount.');
        Assert.AreEqual(
            Format(NegativeCollectedLifecycle."Reported Amount", 0, '<Precision,2:2><Standard Format,9>'),
            AmountNode.AsXmlElement().InnerText(), 'An unapplication must report a negative collected amount.');
    end;

    [Test]
    procedure RetryFailedLifecycleMessageQueuesOccurrence()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Retrying failed message creation queues the occurrence and clears its error
        Initialize();

        // [GIVEN] A failed lifecycle occurrence with a stored error
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);
        FREInvoiceLifecycle."Processing Status" := FREInvoiceLifecycle."Processing Status"::Failed;
        FREInvoiceLifecycle."Last Error" := 'Message creation failed.';
        FREInvoiceLifecycle.Modify();

        // [WHEN] The lifecycle message is retried
        FREInvoiceLifecycleMgt.RetryLifecycleMessage(FREInvoiceLifecycle);

        // [THEN] The occurrence is queued and its previous error is cleared
        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::Queued, FREInvoiceLifecycle."Processing Status", 'A retry must queue the occurrence.');
        Assert.AreEqual('', FREInvoiceLifecycle."Last Error", 'A retry must clear the previous error.');
    end;

    [Test]
    procedure LifecycleWorkerCreatesQueuedMessage()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        FREInvoiceLifecycleWorker: Codeunit "FR E-Invoice Lifecycle Worker";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] The background worker creates a message for a queued lifecycle occurrence
        Initialize();

        // [GIVEN] A queued lifecycle occurrence with a VAT breakdown
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);
        CreateLifecycleVATBreakdown(FREInvoiceLifecycle, 20, 1250);
        FREInvoiceLifecycle."Processing Status" := FREInvoiceLifecycle."Processing Status"::Queued;
        FREInvoiceLifecycle.Modify();

        // [WHEN] The lifecycle worker runs
        FREInvoiceLifecycleWorker.Run(FREInvoiceLifecycle);

        // [THEN] The occurrence is linked to a created E-Document Message
        FREInvoiceLifecycle.Get(FREInvoiceLifecycle."Entry No.");
        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::"Message Created", FREInvoiceLifecycle."Processing Status", 'The worker must create the queued lifecycle message.');
        Assert.IsTrue(FREInvoiceLifecycle."E-Document Message Entry No." <> 0, 'The worker must link the created E-Document message.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure LifecycleErrorHandlerStoresTaskError()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleError: Codeunit "FR E-Invoice Lifecycle Error";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] The background error handler marks a queued occurrence failed and stores the task error
        Initialize();

        // [GIVEN] A committed queued lifecycle occurrence and a task error
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);
        FREInvoiceLifecycle."Processing Status" := FREInvoiceLifecycle."Processing Status"::Queued;
        FREInvoiceLifecycle.Modify();
        Commit();
        asserterror Error(WorkerFailureErr);
        Assert.ExpectedError(WorkerFailureErr);

        // [WHEN] The lifecycle error handler runs
        FREInvoiceLifecycleError.Run(FREInvoiceLifecycle);

        // [THEN] The occurrence is Failed and retains the task error
        FREInvoiceLifecycle.Get(FREInvoiceLifecycle."Entry No.");
        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::Failed, FREInvoiceLifecycle."Processing Status", 'The error handler must mark the queued lifecycle occurrence as failed.');
        Assert.ExpectedMessage(WorkerFailureErr, FREInvoiceLifecycle."Last Error");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PostedPaymentApplicationCreatesCollectedLifecycle()
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        VATEntry: Record "VAT Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Posting a payment applied to a Factur-X FR sales invoice creates a Collected lifecycle occurrence
        Initialize();

        // [GIVEN] Clean customer ledger and VAT entries
        DetailedCustLedgEntry.DeleteAll();
        CustLedgerEntry.DeleteAll();
        VATEntry.DeleteAll();

        // [GIVEN] A posted sales invoice "SI" with an outgoing Factur-X FR E-Document
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        Location.Code := SalesLine."Location Code";
        LibraryInventory.UpdateInventoryPostingSetup(Location);
        if not GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group") then
            LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo('FR');
        Customer.Modify(true);
        SalesHeader.Validate("Your Reference", 'FR-BUYER-REF');
        SalesHeader.Validate("Bill-to Address", '123 Rue de Paris');
        SalesHeader.Validate("Bill-to City", 'Paris');
        SalesHeader.Validate("Bill-to Post Code", '75001');
        SalesHeader.Validate("Ship-to Address", SalesHeader."Bill-to Address");
        SalesHeader.Validate("Ship-to City", SalesHeader."Bill-to City");
        SalesHeader.Validate("Ship-to Post Code", SalesHeader."Bill-to Post Code");
        SalesHeader.Modify(true);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PostedDocNo);
        CreateFRFacturXEDocument(EDocument, SalesInvoiceHeader);

        // [GIVEN] The remaining amount on the invoice customer ledger entry for "SI"
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", PostedDocNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");

        // [WHEN] A customer payment is posted and applied to "SI"
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
            SalesHeader."Sell-to Customer No.", -CustLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] A Collected lifecycle occurrence is created from the actual posted Detailed Cust. Ledg. Entry
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.SetRange("Lifecycle Status", FREInvoiceLifecycle."Lifecycle Status"::Collected);
        FREInvoiceLifecycle.FindFirst();
        DetailedCustLedgEntry.Get(FREInvoiceLifecycle."Detailed Ledger Entry No.");
        Assert.AreEqual("FR E-Invoice Lifecycle Status"::Collected, FREInvoiceLifecycle."Lifecycle Status", 'The lifecycle status must be Collected.');
        Assert.AreEqual(-DetailedCustLedgEntry.Amount, FREInvoiceLifecycle."Reported Amount", 'The reported amount must equal the negated DCLE amount.');
        Assert.IsTrue(FREInvoiceLifecycle."Reported Amount" > 0, 'The collected amount must be positive.');
        Assert.AreEqual(DetailedCustLedgEntry."Posting Date", FREInvoiceLifecycle."Event Date", 'The event date must match the DCLE posting date.');
        Assert.AreEqual(DetailedCustLedgEntry.SystemId, FREInvoiceLifecycle."Source Occurrence ID", 'The source occurrence ID must match the DCLE system ID.');
        FREInvoiceLifecycleVAT.SetRange("Lifecycle Entry No.", FREInvoiceLifecycle."Entry No.");
        FREInvoiceLifecycleVAT.CalcSums("Reported Amount");
        Assert.AreEqual(FREInvoiceLifecycle."Reported Amount", FREInvoiceLifecycleVAT."Reported Amount", 'The VAT breakdown must equal the collected amount.');
    end;

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Identification Tests");
        CompanyInformation.Get();
        CompanyInformation.Validate("Registration No.", '123456789');
        CompanyInformation.Validate("SIRET No.", '12345678901234');
        CompanyInformation.Modify(true);
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Identification Tests");

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = '' then begin
            GeneralLedgerSetup."LCY Code" := 'EUR';
            GeneralLedgerSetup.Modify(true);
        end;

        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            DATABASE::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Posted Invoice Nos."));

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Identification Tests");
    end;

    local procedure CreateFRFacturXEDocument(var EDocument: Record "E-Document"; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        EDocumentService.Code := CopyStr(CreateGuid(), 1, MaxStrLen(EDocumentService.Code));
        EDocumentService."Document Format" := "E-Document Format"::"Factur-X FR";
        ConfigurePPFService(EDocumentService);
        EDocumentService.Insert();

        EDocument.Init();
        EDocument."Document Record ID" := SalesInvoiceHeader.RecordId;
        EDocument."Document No." := SalesInvoiceHeader."No.";
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Service := EDocumentService.Code;
        EDocument."Document Date" := SalesInvoiceHeader."Posting Date";
        EDocument."Clearance Date" := CurrentDateTime();
        EDocument.Insert();

        EDocumentServiceStatus."E-Document Entry No" := EDocument."Entry No";
        EDocumentServiceStatus."E-Document Service Code" := EDocumentService.Code;
        EDocumentServiceStatus.Status := EDocumentServiceStatus.Status::Approved;
        EDocumentServiceStatus.Insert();
    end;

    local procedure CreateEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Document No." := CopyStr(CreateGuid(), 1, MaxStrLen(EDocument."Document No."));
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Insert();
    end;

    local procedure CreateAdditionalEDocument(var AdditionalEDocument: Record "E-Document"; EDocument: Record "E-Document")
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        AdditionalEDocument.Init();
        AdditionalEDocument."Document Record ID" := EDocument."Document Record ID";
        AdditionalEDocument."Document No." := EDocument."Document No.";
        AdditionalEDocument."Document Type" := EDocument."Document Type";
        AdditionalEDocument.Direction := EDocument.Direction;
        AdditionalEDocument.Service := EDocument.Service;
        AdditionalEDocument."Document Date" := EDocument."Document Date";
        AdditionalEDocument."Clearance Date" := EDocument."Clearance Date";
        AdditionalEDocument.Insert();

        EDocumentServiceStatus."E-Document Entry No" := AdditionalEDocument."Entry No";
        EDocumentServiceStatus."E-Document Service Code" := AdditionalEDocument.Service;
        EDocumentServiceStatus.Status := EDocumentServiceStatus.Status::Approved;
        EDocumentServiceStatus.Insert();
    end;

    local procedure CreatePostedInvoiceApplication(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EDocumentFormat: Enum "E-Document Format")
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        DocumentNo := CopyStr(CreateGuid(), 1, MaxStrLen(DocumentNo));
        SalesInvoiceHeader."No." := DocumentNo;
        SalesInvoiceHeader.Insert();

        EDocumentService.Code := CopyStr(CreateGuid(), 1, MaxStrLen(EDocumentService.Code));
        EDocumentService."Document Format" := EDocumentFormat;
        ConfigurePPFService(EDocumentService);
        EDocumentService.Insert();

        EDocument."Document Record ID" := SalesInvoiceHeader.RecordId;
        EDocument."Document No." := DocumentNo;
        EDocument."Document Type" := EDocument."Document Type"::"Sales Invoice";
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Service := EDocumentService.Code;
        EDocument."Document Date" := WorkDate();
        EDocument.Insert();

        EDocumentServiceStatus."E-Document Entry No" := EDocument."Entry No";
        EDocumentServiceStatus."E-Document Service Code" := EDocument.Service;
        EDocumentServiceStatus.Status := EDocumentServiceStatus.Status::Approved;
        EDocumentServiceStatus.Insert();
        EDocument.Validate(Status, EDocument.Status::Processed);
        EDocument.Modify(true);

        InvoiceCustLedgerEntry."Entry No." := GetNextCustLedgerEntryNo();
        InvoiceCustLedgerEntry."Document Type" := InvoiceCustLedgerEntry."Document Type"::Invoice;
        InvoiceCustLedgerEntry."Document No." := DocumentNo;
        InvoiceCustLedgerEntry."Posting Date" := WorkDate();
        InvoiceCustLedgerEntry."Transaction No." := InvoiceCustLedgerEntry."Entry No.";
        InvoiceCustLedgerEntry.Insert();

        VATBusPostingGroup := CopyStr(CreateGuid(), 1, MaxStrLen(VATBusPostingGroup));
        VATProdPostingGroup := CopyStr(CreateGuid(), 1, MaxStrLen(VATProdPostingGroup));
        VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGroup;
        VATPostingSetup."VAT Prod. Posting Group" := VATProdPostingGroup;
        VATPostingSetup."VAT %" := 20;
        VATPostingSetup.Insert();

        VATEntry."Entry No." := GetNextVATEntryNo();
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."Document No." := DocumentNo;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."Transaction No." := InvoiceCustLedgerEntry."Transaction No.";
        VATEntry."VAT Bus. Posting Group" := VATBusPostingGroup;
        VATEntry."VAT Prod. Posting Group" := VATProdPostingGroup;
        VATEntry."Source Currency Code" := 'EUR';
        VATEntry."Source Currency VAT Base" := -500;
        VATEntry."Source Currency VAT Amount" := -100;
        VATEntry.Insert();

        Clear(VATPostingSetup);
        VATBusPostingGroup := CopyStr(CreateGuid(), 1, MaxStrLen(VATBusPostingGroup));
        VATProdPostingGroup := CopyStr(CreateGuid(), 1, MaxStrLen(VATProdPostingGroup));
        VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGroup;
        VATPostingSetup."VAT Prod. Posting Group" := VATProdPostingGroup;
        VATPostingSetup."VAT %" := 10;
        VATPostingSetup.Insert();

        Clear(VATEntry);
        VATEntry."Entry No." := GetNextVATEntryNo();
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."Document No." := DocumentNo;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."Transaction No." := InvoiceCustLedgerEntry."Transaction No.";
        VATEntry."VAT Bus. Posting Group" := VATBusPostingGroup;
        VATEntry."VAT Prod. Posting Group" := VATProdPostingGroup;
        VATEntry."Source Currency Code" := 'EUR';
        VATEntry."Source Currency VAT Base" := -590.91;
        VATEntry."Source Currency VAT Amount" := -59.09;
        VATEntry.Insert();

        PaymentCustLedgerEntry."Entry No." := InvoiceCustLedgerEntry."Entry No." + 1;
        PaymentCustLedgerEntry."Document Type" := PaymentCustLedgerEntry."Document Type"::Payment;
        PaymentCustLedgerEntry."Document No." := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentCustLedgerEntry."Document No."));
        PaymentCustLedgerEntry.Insert();

        DetailedCustLedgEntry."Entry No." := GetNextDetailedCustLedgerEntryNo();
        DetailedCustLedgEntry."Cust. Ledger Entry No." := InvoiceCustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Applied Cust. Ledger Entry No." := PaymentCustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::Application;
        DetailedCustLedgEntry."Initial Document Type" := DetailedCustLedgEntry."Initial Document Type"::Invoice;
        DetailedCustLedgEntry.Amount := -1000;
        DetailedCustLedgEntry."Currency Code" := 'EUR';
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry.Insert(true);
    end;

    local procedure CreateUnapplicationDetail(var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        NewDetailedCustLedgEntry := DetailedCustLedgEntry;
        NewDetailedCustLedgEntry."Entry No." := GetNextDetailedCustLedgerEntryNo();
        NewDetailedCustLedgEntry.Amount := -DetailedCustLedgEntry.Amount;
        NewDetailedCustLedgEntry."Posting Date" := WorkDate() + 1;
        NewDetailedCustLedgEntry.Unapplied := true;
        NewDetailedCustLedgEntry."Unapplied by Entry No." := DetailedCustLedgEntry."Entry No.";
        NewDetailedCustLedgEntry.Insert(true);
    end;

    local procedure GetNextCustLedgerEntryNo(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then
            exit(CustLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure GetNextDetailedCustLedgerEntryNo(): Integer
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if DetailedCustLedgEntry.FindLast() then
            exit(DetailedCustLedgEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure CreatePaymentCustLedgerEntry(var PaymentCustLedgerEntry: Record "Cust. Ledger Entry"; CurrencyCode: Code[10])
    begin
        PaymentCustLedgerEntry."Entry No." := GetNextCustLedgerEntryNo();
        PaymentCustLedgerEntry."Document Type" := PaymentCustLedgerEntry."Document Type"::Payment;
        PaymentCustLedgerEntry."Document No." := CopyStr(CreateGuid(), 1, MaxStrLen(PaymentCustLedgerEntry."Document No."));
        PaymentCustLedgerEntry."Currency Code" := CurrencyCode;
        PaymentCustLedgerEntry.Insert();
    end;

    local procedure GetNextVATEntryNo(): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        if VATEntry.FindLast() then
            exit(VATEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure CreateLifecycleVATBreakdown(FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"; VATRate: Decimal; ReportedAmount: Decimal)
    var
        FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
    begin
        FREInvoiceLifecycleVAT."Lifecycle Entry No." := FREInvoiceLifecycle."Entry No.";
        FREInvoiceLifecycleVAT."Line No." := 10000;
        FREInvoiceLifecycleVAT."VAT %" := VATRate;
        FREInvoiceLifecycleVAT."Reported Amount" := ReportedAmount;
        FREInvoiceLifecycleVAT.Insert();
    end;

    local procedure SetInvoiceVATRate(DocumentNo: Code[20]; VATRate: Decimal; ClearVATAmount: Boolean)
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
        repeat
            VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
            VATPostingSetup."VAT %" := VATRate;
            VATPostingSetup.Modify();
            if ClearVATAmount then begin
                VATEntry."Source Currency VAT Amount" := 0;
                VATEntry.Modify();
            end;
        until VATEntry.Next() = 0;
    end;

    local procedure SetInvoiceVATCurrency(DocumentNo: Code[20]; CurrencyCode: Code[10])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
        repeat
            VATEntry."Source Currency Code" := CurrencyCode;
            VATEntry.Modify();
        until VATEntry.Next() = 0;
    end;

    local procedure ConfigurePPFService(var EDocumentService: Record "E-Document Service")
    var
        CompanyInformation: Record "Company Information";
    begin
        EDocumentService."FR Sender Platform ID" := 'PLATFORM-ID';
        EDocumentService."FR Sender Platform Scheme" := '0238';
        EDocumentService."FR Sender Platform Name" := 'Test Approved Platform';
        CompanyInformation.Get();
        CompanyInformation.Name := 'Test Company';
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation.Modify();
    end;

    local procedure AssertXmlValue(XmlDoc: XmlDocument; XPath: Text; ExpectedValue: Text)
    var
        XmlNode: XmlNode;
    begin
        Assert.IsTrue(XmlDoc.SelectSingleNode(XPath, XmlNode), StrSubstNo(XmlNodeMissingErr, XPath));
        Assert.AreEqual(ExpectedValue, XmlNode.AsXmlElement().InnerText(), StrSubstNo(XmlNodeValueErr, XPath));
    end;

    local procedure AssertXmlAttribute(XmlDoc: XmlDocument; XPath: Text; AttributeName: Text; ExpectedValue: Text)
    var
        XmlAttribute: XmlAttribute;
        XmlNode: XmlNode;
    begin
        Assert.IsTrue(XmlDoc.SelectSingleNode(XPath, XmlNode), StrSubstNo(XmlNodeMissingErr, XPath));
        Assert.IsTrue(XmlNode.AsXmlElement().Attributes().Get(AttributeName, XmlAttribute), StrSubstNo(XmlAttributeMissingErr, XPath, AttributeName));
        Assert.AreEqual(ExpectedValue, XmlAttribute.Value(), StrSubstNo(XmlAttributeValueErr, AttributeName, XPath));
    end;
}
