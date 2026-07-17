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
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        EDocHelpers: Codeunit "EDoc. Helpers";
        IsInitialized: Boolean;

    [Test]
    procedure CheckSIRENNotEmptyRaisesErrorWhenEmpty()
    var
        CompanyInformation: Record "Company Information";
        OriginalRegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRENNotEmpty raises error when Registration No. is blank

        // [GIVEN] Company Information with blank Registration No.
        CompanyInformation.Get();
        OriginalRegistrationNo := CompanyInformation."Registration No.";
        CompanyInformation."Registration No." := '';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRENNotEmpty is called
        // [THEN] Error is raised
        asserterror EDocHelpers.CheckSIRENNotEmpty();
        Assert.ExpectedError('Registration No. must be specified in Company Information for French e-invoicing.');

        // Cleanup
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

        // [GIVEN] Company Information with blank SIRET No.
        CompanyInformation.Get();
        OriginalSIRETNo := CompanyInformation."SIRET No.";
        CompanyInformation."SIRET No." := '';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRETNotEmpty is called
        // [THEN] Error is raised
        asserterror EDocHelpers.CheckSIRETNotEmpty();
        Assert.ExpectedError('SIRET No. must be specified in Company Information for French e-invoicing.');

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := OriginalSIRETNo;
        CompanyInformation.Modify();
    end;

    [Test]
    procedure CheckSIRENNotEmptyDoesNotErrorWhenRegistrationNoPresent()
    var
        CompanyInformation: Record "Company Information";
        OriginalRegistrationNo: Text[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRENNotEmpty succeeds when Registration No. is set

        // [GIVEN] Company Information with Registration No. set
        CompanyInformation.Get();
        OriginalRegistrationNo := CompanyInformation."Registration No.";
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRENNotEmpty is called
        // [THEN] No error is raised
        EDocHelpers.CheckSIRENNotEmpty();

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."Registration No." := CopyStr(OriginalRegistrationNo, 1, MaxStrLen(CompanyInformation."Registration No."));
        CompanyInformation.Modify();
    end;

    [Test]
    procedure CheckSIRETNotEmptyDoesNotErrorWhenSIRETPresent()
    var
        CompanyInformation: Record "Company Information";
        OriginalSIRETNo: Code[14];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] CheckSIRETNotEmpty succeeds when SIRET No. is set

        // [GIVEN] Company Information with SIRET No. set
        CompanyInformation.Get();
        OriginalSIRETNo := CompanyInformation."SIRET No.";
        CompanyInformation."SIRET No." := '12345678901234';
        CompanyInformation.Modify();

        // [WHEN] CheckSIRETNotEmpty is called
        // [THEN] No error is raised
        EDocHelpers.CheckSIRETNotEmpty();

        // Cleanup
        CompanyInformation.Get();
        CompanyInformation."SIRET No." := OriginalSIRETNo;
        CompanyInformation.Modify();
    end;

    [Test]
    procedure CaptureCollectedOccurrenceCreatesCapturedLifecycle()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        SourceOccurrenceID: Guid;
    begin
        // [SCENARIO] A payment application is captured as an immutable Collected lifecycle occurrence
        CreateEDocument(EDocument);
        SourceOccurrenceID := CreateGuid();

        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        Assert.AreEqual(EDocument."Entry No", FREInvoiceLifecycle."E-Document Entry No.", 'The e-document entry must be retained.');
        Assert.AreEqual(1250, FREInvoiceLifecycle."Reported Amount", 'The reported amount must be retained.');
        Assert.AreEqual('EUR', FREInvoiceLifecycle."Currency Code", 'The currency code must be retained.');
        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::Captured, FREInvoiceLifecycle."Processing Status", 'A new occurrence must be captured.');
        Assert.IsTrue(FREInvoiceLifecycle."Created At" <> 0DT, 'The creation timestamp must be populated.');
    end;

    [Test]
    procedure CaptureCollectedOccurrenceUsesLCYForBlankCurrency()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        GeneralLedgerSetup: Record "General Ledger Setup";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] A local-currency payment occurrence stores the configured LCY code
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."LCY Code" = '' then begin
            GeneralLedgerSetup."LCY Code" := 'EUR';
            GeneralLedgerSetup.Modify(true);
        end;
        CreateEDocument(EDocument);

        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, '', WorkDate(), 0, 0, 0, 0);

        Assert.AreEqual(GeneralLedgerSetup."LCY Code", FREInvoiceLifecycle."Currency Code", 'A blank ledger currency must resolve to the LCY code.');
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
        // [SCENARIO] Replaying the same payment event does not create a duplicate occurrence
        CreateEDocument(EDocument);
        SourceOccurrenceID := CreateGuid();
        FirstLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        ReplayedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        Assert.AreEqual(FirstLifecycle."Entry No.", ReplayedLifecycle."Entry No.", 'An identical replay must return the existing occurrence.');
    end;

    [Test]
    procedure CaptureCollectedOccurrenceRejectsConflictingReplay()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        SourceOccurrenceID: Guid;
    begin
        // [SCENARIO] A replay with the same identity but different regulatory values is rejected
        CreateEDocument(EDocument);
        SourceOccurrenceID := CreateGuid();
        FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        asserterror FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, SourceOccurrenceID,
            1200, 'EUR', WorkDate(), 0, 0, 0, 0);

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
        // [SCENARIO] Unapplication creates a separate Negative Collected occurrence linked to Collected
        CreateEDocument(EDocument);
        CollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        NegativeCollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::"Negative Collected", CreateGuid(),
            -1250, 'EUR', WorkDate(), 0, 0, 0, CollectedLifecycle."Entry No.");

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
        // [SCENARIO] Negative Collected cannot reverse a different amount than its original occurrence
        CreateEDocument(EDocument);
        CollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        asserterror FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::"Negative Collected", CreateGuid(),
            -1200, 'EUR', WorkDate(), 0, 0, 0, CollectedLifecycle."Entry No.");

        Assert.ExpectedError('A Negative Collected occurrence must exactly reverse the reported amount of the original Collected occurrence.');
    end;

    [Test]
    procedure CapturedOccurrenceRejectsRegulatoryValueChanges()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Captured regulatory values cannot be changed in place
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);

        FREInvoiceLifecycle."Reported Amount" := 1200;
        asserterror FREInvoiceLifecycle.Modify();

        Assert.ExpectedError('The regulatory identity and values of a French electronic invoice lifecycle occurrence cannot be changed.');

        FREInvoiceLifecycle.Get(FREInvoiceLifecycle."Entry No.");
        FREInvoiceLifecycle."Sender Platform ID" := 'CHANGED';
        asserterror FREInvoiceLifecycle.Modify();

        Assert.ExpectedError('The regulatory identity and values of a French electronic invoice lifecycle occurrence cannot be changed.');
    end;

    [Test]
    procedure DetailedApplicationCapturesCollectedForFREInvoice()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Applying a payment to a French electronic invoice captures a Collected occurrence
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();
        Assert.AreEqual(FREInvoiceLifecycle."Lifecycle Status"::Collected, FREInvoiceLifecycle."Lifecycle Status", 'A payment application must create a Collected occurrence.');
        Assert.AreEqual(1250, FREInvoiceLifecycle."Reported Amount", 'The collected amount must be positive.');
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
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        XmlDoc: XmlDocument;
        XmlNode: XmlNode;
    begin
        // [SCENARIO] A real French invoice occurrence creates the PPF einvoicingF2 lifecycle envelope
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();

        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);

        EDocMessageMgt.GetMessageBlob(FREInvoiceLifecycle."E-Document Message Entry No.", TempBlob);
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
        // [SCENARIO] Multiple invoice VAT entries with the same rate create one lifecycle amount
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        SetInvoiceVATRate(EDocument."Document No.", 20, false);

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

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
        // [SCENARIO] A zero-rated invoice retains VAT rate zero in the lifecycle breakdown
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        SetInvoiceVATRate(EDocument."Document No.", 0, true);

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

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
        // [SCENARIO] Foreign-currency VAT allocation uses that currency's rounding precision and preserves the remainder
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        CurrencyCode := CopyStr(CreateGuid(), 1, MaxStrLen(CurrencyCode));
        Currency.Code := CurrencyCode;
        Currency."Amount Rounding Precision" := 0.05;
        Currency.Insert();
        DetailedCustLedgEntry.Amount := -1000.03;
        DetailedCustLedgEntry."Currency Code" := CurrencyCode;
        DetailedCustLedgEntry.Modify();
        SetInvoiceVATCurrency(EDocument."Document No.", CurrencyCode);

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

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
        // [SCENARIO] A French lifecycle occurrence is not retained when its posted invoice has no VAT breakdown
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        VATEntry.SetRange("Document No.", EDocument."Document No.");
        VATEntry.DeleteAll();

        asserterror FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        Assert.ExpectedError('A VAT breakdown could not be determined for posted sales invoice');
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.RecordIsEmpty(FREInvoiceLifecycle);
    end;

    [Test]
    procedure DetailedApplicationRejectsMissingSenderPlatformSetup()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] A PPF lifecycle occurrence is not retained when the sender platform identity is incomplete
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        EDocumentService.Get(EDocument.Service);
        Clear(EDocumentService."FR Sender Platform ID");
        EDocumentService.Modify();

        asserterror FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        Assert.ExpectedError('FR Sender Platform ID must have a value');
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.RecordIsEmpty(FREInvoiceLifecycle);
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
        // [SCENARIO] A lifecycle occurrence is not retained when a posted VAT entry has no matching setup
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        VATEntry.SetRange("Document No.", EDocument."Document No.");
        VATEntry.FindFirst();
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
        VATPostingSetup.Delete();

        asserterror FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        Assert.ExpectedError('VAT Posting Setup does not exist');
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.RecordIsEmpty(FREInvoiceLifecycle);
    end;

    [Test]
    procedure LifecycleOccurrenceAndVATBreakdownRejectDeletion()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Captured lifecycle occurrences and their VAT rows cannot be deleted
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);
        CreateLifecycleVATBreakdown(FREInvoiceLifecycle, 20, 1250);

        asserterror FREInvoiceLifecycle.Delete();
        Assert.ExpectedError('A French electronic invoice lifecycle occurrence cannot be deleted.');
        FREInvoiceLifecycleVAT.Get(FREInvoiceLifecycle."Entry No.", 10000);
        asserterror FREInvoiceLifecycleVAT.Delete();
        Assert.ExpectedError('A French electronic invoice lifecycle VAT breakdown cannot be changed.');
    end;

    [Test]
    procedure DetailedApplicationIgnoresNonFREInvoice()
    var
        EDocument: Record "E-Document";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Applying a payment to an electronic invoice in a non-French format creates no French lifecycle occurrence
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"PEPPOL BIS 3.0");

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

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
        // [SCENARIO] Replaying an application whose lifecycle message exists does not requeue the occurrence
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.FindFirst();
        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);
        MessageEntryNo := FREInvoiceLifecycle."E-Document Message Entry No.";

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

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
        // [SCENARIO] Replaying an application while message creation is queued does not duplicate the occurrence
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

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
        // [SCENARIO] Applying a payment creates an occurrence for every eligible E-Document of the invoice
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Factur-X FR");
        CreateAdditionalEDocument(AdditionalEDocument, EDocument);

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);

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
        // [SCENARIO] Unapplying a captured payment creates an exact linked Negative Collected occurrence
        CreatePostedInvoiceApplication(EDocument, DetailedCustLedgEntry, "E-Document Format"::"Peppol BIS 3.0 FR");
        FREInvoiceLifecycleMgt.ProcessDetailedLedgerApplication(DetailedCustLedgEntry);
        CollectedLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        CollectedLifecycle.FindFirst();
        CreateUnapplicationDetail(NewDetailedCustLedgEntry, DetailedCustLedgEntry);

        FREInvoiceLifecycleMgt.ProcessDetailedLedgerUnapplication(DetailedCustLedgEntry, NewDetailedCustLedgEntry);

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
            Assert.AreEqual(CollectedLifecycleVAT."Currency Code", NegativeCollectedLifecycleVAT."Currency Code", 'The reversal must retain the currency of each VAT-rate amount.');
        until CollectedLifecycleVAT.Next() = 0;
    end;

    [Test]
    procedure CreateLifecycleMessageStoresPayloadThroughEDocumentMessageMgt()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        XmlDoc: XmlDocument;
        AmountElement: XmlElement;
        AmountNode: XmlNode;
        ProfileNode: XmlNode;
        StatusNode: XmlNode;
        VATPercentNode: XmlNode;
    begin
        // [SCENARIO] A captured occurrence creates and links a PR 8698 E-Document Message payload
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);
        CreateLifecycleVATBreakdown(FREInvoiceLifecycle, 20, 1250);

        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);

        Assert.IsTrue(FREInvoiceLifecycle."E-Document Message Entry No." <> 0, 'The lifecycle occurrence must link to the created E-Document Message.');
        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::"Message Created", FREInvoiceLifecycle."Processing Status", 'The occurrence must record successful message creation.');
        EDocMessageMgt.GetMessageBlob(FREInvoiceLifecycle."E-Document Message Entry No.", TempBlob);
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
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ValueAmount"]', AmountNode), 'The payload must contain the collected amount.');
        AmountElement := AmountNode.AsXmlElement();
        Assert.AreEqual('EUR', AmountElement.GetAttribute('currencyID').Value(), 'The collected amount must identify its currency.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ValuePercent"]', VATPercentNode), 'The payload must contain the VAT percentage.');
        Assert.AreEqual('20', VATPercentNode.AsXmlElement().InnerText(), 'The payload must retain the frozen VAT percentage.');
    end;

    [Test]
    procedure CreateLifecycleMessageIsIdempotent()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        MessageEntryNo: Integer;
    begin
        // [SCENARIO] Retrying message creation does not create or link a second message
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);
        CreateLifecycleVATBreakdown(FREInvoiceLifecycle, 20, 1250);
        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);
        MessageEntryNo := FREInvoiceLifecycle."E-Document Message Entry No.";

        FREInvoiceLifecycleMgt.CreateLifecycleMessage(FREInvoiceLifecycle);

        Assert.AreEqual(MessageEntryNo, FREInvoiceLifecycle."E-Document Message Entry No.", 'A retry must retain the existing message link.');
    end;

    [Test]
    procedure CreateNegativeCollectedMessageUses212AndNegativeAmount()
    var
        EDocument: Record "E-Document";
        CollectedLifecycle: Record "FR E-Invoice Lifecycle";
        NegativeCollectedLifecycle: Record "FR E-Invoice Lifecycle";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        XmlDoc: XmlDocument;
        AmountNode: XmlNode;
        StatusNode: XmlNode;
    begin
        // [SCENARIO] A Negative Collected occurrence uses status 212 with a negative collected amount
        CreateEDocument(EDocument);
        CollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);
        CreateLifecycleVATBreakdown(CollectedLifecycle, 20, 1250);
        NegativeCollectedLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::"Negative Collected", CreateGuid(),
            -1250, 'EUR', WorkDate() + 1, 0, 0, 0, CollectedLifecycle."Entry No.");
        CreateLifecycleVATBreakdown(NegativeCollectedLifecycle, 20, -1250);

        FREInvoiceLifecycleMgt.CreateLifecycleMessage(NegativeCollectedLifecycle);

        EDocMessageMgt.GetMessageBlob(NegativeCollectedLifecycle."E-Document Message Entry No.", TempBlob);
        TempBlob.CreateInStream(InStream);
        XmlDocument.ReadFrom(InStream, XmlDoc);
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ProcessConditionCode"]', StatusNode), 'The payload must contain the lifecycle status.');
        Assert.AreEqual('212', StatusNode.AsXmlElement().InnerText(), 'An unapplication must retain the Encaissée status code.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('//*[local-name()="ValueAmount"]', AmountNode), 'The payload must contain the collected amount.');
        Assert.AreEqual('-1250', AmountNode.AsXmlElement().InnerText(), 'An unapplication must report a negative collected amount.');
    end;

    [Test]
    procedure RetryFailedLifecycleMessageQueuesOccurrence()
    var
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
    begin
        // [SCENARIO] Retrying failed message creation queues the occurrence and clears its error
        CreateEDocument(EDocument);
        FREInvoiceLifecycle := FREInvoiceLifecycleMgt.CapturePaymentOccurrence(
            EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, CreateGuid(),
            1250, 'EUR', WorkDate(), 0, 0, 0, 0);
        FREInvoiceLifecycle."Processing Status" := FREInvoiceLifecycle."Processing Status"::Failed;
        FREInvoiceLifecycle."Last Error" := 'Message creation failed.';
        FREInvoiceLifecycle.Modify();

        FREInvoiceLifecycleMgt.RetryLifecycleMessage(FREInvoiceLifecycle);

        Assert.AreEqual(FREInvoiceLifecycle."Processing Status"::Queued, FREInvoiceLifecycle."Processing Status", 'A retry must queue the occurrence.');
        Assert.AreEqual('', FREInvoiceLifecycle."Last Error", 'A retry must clear the previous error.');
    end;

    [Test]
    procedure PostedPaymentApplicationCreatesCollectedLifecycle()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        EDocument: Record "E-Document";
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Posting a payment applied to a Factur-X FR sales invoice creates a Collected lifecycle occurrence
        Initialize();

        // [GIVEN] A posted sales invoice "SI" with an outgoing Factur-X FR E-Document
        LibrarySales.CreateSalesInvoice(SalesHeader);
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
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Identification Tests");
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
        EDocument."Document Date" := WorkDate();
        EDocument."Clearance Date" := CurrentDateTime();
        EDocument.Insert();
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
    begin
        AdditionalEDocument.Init();
        AdditionalEDocument."Document Record ID" := EDocument."Document Record ID";
        AdditionalEDocument."Document No." := EDocument."Document No.";
        AdditionalEDocument."Document Type" := EDocument."Document Type";
        AdditionalEDocument.Direction := EDocument.Direction;
        AdditionalEDocument.Service := EDocument.Service;
        AdditionalEDocument.Insert();
    end;

    local procedure CreatePostedInvoiceApplication(var EDocument: Record "E-Document"; var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EDocumentFormat: Enum "E-Document Format")
    var
        EDocumentService: Record "E-Document Service";
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
        EDocument."Clearance Date" := CurrentDateTime();
        EDocument.Insert();

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
        FREInvoiceLifecycleVAT."Currency Code" := FREInvoiceLifecycle."Currency Code";
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
        CompanyInformation."Registration No." := '123456789';
        CompanyInformation.Modify();
    end;

    local procedure AssertXmlValue(XmlDoc: XmlDocument; XPath: Text; ExpectedValue: Text)
    var
        XmlNode: XmlNode;
    begin
        Assert.IsTrue(XmlDoc.SelectSingleNode(XPath, XmlNode), StrSubstNo('The payload must contain XML node %1.', XPath));
        Assert.AreEqual(ExpectedValue, XmlNode.AsXmlElement().InnerText(), StrSubstNo('The XML node %1 has an unexpected value.', XPath));
    end;

    local procedure AssertXmlAttribute(XmlDoc: XmlDocument; XPath: Text; AttributeName: Text; ExpectedValue: Text)
    var
        XmlAttribute: XmlAttribute;
        XmlNode: XmlNode;
    begin
        Assert.IsTrue(XmlDoc.SelectSingleNode(XPath, XmlNode), StrSubstNo('The payload must contain XML node %1.', XPath));
        Assert.IsTrue(XmlNode.AsXmlElement().Attributes().Get(AttributeName, XmlAttribute), StrSubstNo('The XML node %1 must contain attribute %2.', XPath, AttributeName));
        Assert.AreEqual(ExpectedValue, XmlAttribute.Value(), StrSubstNo('The XML attribute %1 on node %2 has an unexpected value.', AttributeName, XPath));
    end;
}
