// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Formats;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

codeunit 148145 "Export E-Reporting Tests"
{
    Subtype = Test;
    Permissions = tabledata "E-Document" = rimd,
                  tabledata "E-Document Service" = rimd,
                  tabledata "E-Document Service Status" = rimd,
                  tabledata "VAT Entry" = rimd,
                  tabledata "VAT Posting Setup" = rimd,
                  tabledata "VAT Business Posting Group" = rimd,
                  tabledata "VAT Product Posting Group" = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [E-Reporting FR E-document]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        XmlNamespaceTrsTok: Label 'transaction', Locked = true;
        TransactionsXPathFormatTok: Label '/trs:Transactions[%1]/', Locked = true;
        TaxSubtotalXPathFormatTok: Label '/trs:TaxSubtotal[%1]/', Locked = true;

    #region Export
    [Test]
    procedure ExportSalesInvoiceB2CCreatesTransactionInXML()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Sales invoice with B2C customer produces correct Transactions XML node
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Customer "C" with B2C transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"B2C");

        // [GIVEN] E-Document "ED" for Sales Invoice with VAT Entry
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -1000, -200, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains one Transactions node with correct values
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 1);
        VerifyTransactionNode(TempBlob, 0, 'Business-to-consumer', '1000', '200', '1');
        VerifyTaxSubtotalNode(TempBlob, 0, '20', '1000', '200');
    end;

    [Test]
    procedure ExportPurchaseInvoiceCrossBorderCreatesTransactionInXML()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Purchase invoice with Cross-Border B2B vendor produces correct XML
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Vendor "V" with Cross-Border B2B transaction type
        VendorNo := CreateVendorWithTransType("FR E-Reporting Trans. Type"::"Cross-Border B2B");

        // [GIVEN] E-Document "ED" for Purchase Invoice with VAT Entry
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Purchase Invoice");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Purchase, "Gen. Journal Document Type"::Invoice, VendorNo, 500, 100, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains one Transactions node with correct purchase amounts
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 1);
        VerifyTransactionNode(TempBlob, 0, 'Cross-border business-to-business', '500', '100', '1');
    end;

    [Test]
    procedure ExportSalesCreditMemoReversesBaseAmountSign()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Sales credit memo produces positive base/VAT amounts due to sign reversal
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Customer "C" with B2C transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"B2C");

        // [GIVEN] E-Document "ED" for Sales Credit Memo with VAT Entry (negative base for credit memo)
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Sales Credit Memo");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::"Credit Memo", CustomerNo, 800, 160, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains amounts with reversed sign (positive for sales credit)
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 1);
        VerifyTransactionNode(TempBlob, 0, 'Business-to-consumer', '-800', '-160', '1');
    end;

    [Test]
    procedure ExportPurchaseCreditMemoKeepsPositiveAmount()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        VendorNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Purchase credit memo keeps original amount sign (no reversal for purchases)
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Vendor "V" with Export transaction type
        VendorNo := CreateVendorWithTransType("FR E-Reporting Trans. Type"::"Export");

        // [GIVEN] E-Document "ED" for Purchase Credit Memo with VAT Entry
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Purchase Credit Memo");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Purchase, "Gen. Journal Document Type"::"Credit Memo", VendorNo, -600, -120, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML keeps original purchase amounts without sign reversal
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 1);
        VerifyTransactionNode(TempBlob, 0, 'Exports outside of EU', '-600', '-120', '1');
    end;

    [Test]
    procedure ExportMultipleInvoicesSameTypeAggregated()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo1: Code[20];
        DocumentNo2: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Two sales invoices with same customer type aggregate into single Transactions
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Customer "C" with Intra-Community transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"Intra-Community");

        // [GIVEN] Two E-Documents "ED1" and "ED2" for Sales Invoices with VAT Entries
        PostingDate := WorkDate();
        DocumentNo1 := LibraryUtility.GenerateGUID();
        DocumentNo2 := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo1, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo1, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -1000, -200, VATBusPostingGroup, VATProdPostingGroup);
        CreateEDocument(EDocument, DocumentNo2, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo2, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -500, -100, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called with both E-Documents
        EDocument.Reset();
        EDocument.SetFilter("Document No.", '%1|%2', DocumentNo1, DocumentNo2);
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains one Transactions node with summed amounts and count=2
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 1);
        VerifyTransactionNode(TempBlob, 0, 'Intra-community deliveries and acquisitions', '1500', '300', '2');
    end;

    [Test]
    procedure ExportDifferentTransTypeCreatesSeparateTransactions()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo1: Code[20];
        CustomerNo2: Code[20];
        DocumentNo1: Code[20];
        DocumentNo2: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Two invoices with different transaction types create separate Transactions nodes
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Customer "C1" with B2C and Customer "C2" with Export transaction type
        CustomerNo1 := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"B2C");
        CustomerNo2 := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"Export");

        // [GIVEN] Two E-Documents "ED1" and "ED2" for different customers
        PostingDate := WorkDate();
        DocumentNo1 := LibraryUtility.GenerateGUID();
        DocumentNo2 := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo1, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo1, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo1, -1000, -200, VATBusPostingGroup, VATProdPostingGroup);
        CreateEDocument(EDocument, DocumentNo2, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo2, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo2, -500, -100, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called with both E-Documents
        EDocument.Reset();
        EDocument.SetFilter("Document No.", '%1|%2', DocumentNo1, DocumentNo2);
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains two separate Transactions nodes
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 2);
    end;

    [Test]
    procedure ExportMultipleVATRatesCreateTaxSubtotals()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup1: Code[20];
        VATProdPostingGroup2: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Invoice with different VAT rates produces multiple TaxSubtotal elements
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% and 10% rates
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup1 := LibraryUtility.GenerateGUID();
        VATProdPostingGroup2 := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup1, 20);
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup2, 10);

        // [GIVEN] Customer "C" with B2C transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"B2C");

        // [GIVEN] E-Document "ED" with two VAT Entries at different rates (20% and 10%)
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -1000, -200, VATBusPostingGroup, VATProdPostingGroup1);
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -500, -50, VATBusPostingGroup, VATProdPostingGroup2);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains one Transactions node with two TaxSubtotal children
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 1);
        VerifyTransactionNode(TempBlob, 0, 'Business-to-consumer', '1500', '250', '1');
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:TaxSubtotal', 2);
    end;

    [Test]
    procedure ExportForeignCurrencyUsedInTransactionsCurrency()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] VAT Entry with source currency code uses that in TransactionsCurrency
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Customer "C" with B2C transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"B2C");

        // [GIVEN] E-Document "ED" with VAT Entry having source currency USD
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntryWithCurrency(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -1000, -200, 'USD', VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] TransactionsCurrency element contains USD
        Assert.AreEqual('USD', GetNodeByPathFromBlob(TempBlob, '//trs:Transactions/trs:TransactionsCurrency'), 'Incorrect value for TransactionsCurrency');
    end;

    [Test]
    procedure ExportLCYUsedWhenNoSourceCurrency()
    var
        EDocument: Record "E-Document";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] VAT Entry without source currency code falls back to LCY Code
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] General Ledger Setup with LCY Code "EUR"
        GeneralLedgerSetup.Get();

        // [GIVEN] Customer "C" with Overseas Territory transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"Overseas Territory");

        // [GIVEN] E-Document "ED" with VAT Entry having blank source currency
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -1000, -200, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] TransactionsCurrency element contains the LCY Code from General Ledger Setup
        Assert.AreEqual(GeneralLedgerSetup."LCY Code", GetNodeByPathFromBlob(TempBlob, '//trs:Transactions/trs:TransactionsCurrency'), 'Incorrect value for TransactionsCurrency');
    end;

    [Test]
    procedure ExportBlankTransTypeExcludedFromXML()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Customer with blank transaction type produces no Transactions node
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Customer "C" with blank transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::" ");

        // [GIVEN] E-Document "ED" for Sales Invoice with VAT Entry
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -1000, -200, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains no Transactions node
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 0);
    end;

    [Test]
    procedure ExportCustomerNotFoundExcludedFromXML()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] VAT Entry with non-existing Bill-to/Pay-to No. is excluded
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] E-Document "ED" with VAT Entry referencing non-existing customer
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, 'NONEXIST', -1000, -200, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains no Transactions node
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 0);
    end;

    [Test]
    procedure ExportZeroBaseProducesZeroVATRate()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] VAT Posting Setup with VAT %=0 results in VAT rate of 0%
        Initialize();

        // [GIVEN] VAT Posting Setup with 0% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 0);

        // [GIVEN] Customer "C" with B2C transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"B2C");

        // [GIVEN] E-Document "ED" with VAT Entry having non-zero Base
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -1000, 0, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] TaxPercent in TaxSubtotal is 0
        Assert.AreEqual('0', GetNodeByPathFromBlob(TempBlob, '//trs:Transactions/trs:TaxSubtotal/trs:TaxPercent'), 'Incorrect value for TaxPercent');
    end;

    [Test]
    procedure ExportReportPeriodDerivedFromEDocumentDates()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo1: Code[20];
        DocumentNo2: Code[20];
        EarlyDate: Date;
        LateDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] ReportPeriod uses earliest and latest posting dates from E-Documents
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Customer "C" with B2C transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"B2C");

        // [GIVEN] Two E-Documents with different posting dates
        EarlyDate := CalcDate('<-1M>', WorkDate());
        LateDate := WorkDate();
        DocumentNo1 := LibraryUtility.GenerateGUID();
        DocumentNo2 := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo1, EarlyDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo1, EarlyDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -1000, -200, VATBusPostingGroup, VATProdPostingGroup);
        CreateEDocument(EDocument, DocumentNo2, LateDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo2, LateDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -500, -100, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called with both E-Documents
        EDocument.Reset();
        EDocument.SetFilter("Document No.", '%1|%2', DocumentNo1, DocumentNo2);
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] ReportPeriod StartDate and EndDate match earliest and latest posting dates
        Assert.AreEqual(FormatDate(EarlyDate), GetNodeByPathFromBlob(TempBlob, '//trs:ReportPeriod/trs:StartDate'), 'Incorrect value for StartDate');
        Assert.AreEqual(FormatDate(LateDate), GetNodeByPathFromBlob(TempBlob, '//trs:ReportPeriod/trs:EndDate'), 'Incorrect value for EndDate');
    end;

    [Test]
    procedure ExportServiceInvoiceB2CCreatesTransactionInXML()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Service invoice with B2C customer produces correct Transactions XML node
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Customer "C" with B2C transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"B2C");

        // [GIVEN] E-Document "ED" for Service Invoice with VAT Entry
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Service Invoice");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -1000, -200, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains one Transactions node with correct values
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 1);
        VerifyTransactionNode(TempBlob, 0, 'Business-to-consumer', '1000', '200', '1');
        VerifyTaxSubtotalNode(TempBlob, 0, '20', '1000', '200');
    end;

    [Test]
    procedure ExportServiceCreditMemoReversesBaseAmountSign()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Service credit memo produces amounts with reversed sign due to GetSignedAmount
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Customer "C" with Export transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"Export");

        // [GIVEN] E-Document "ED" for Service Credit Memo with VAT Entry
        PostingDate := WorkDate();
        DocumentNo := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo, PostingDate, "E-Document Type"::"Service Credit Memo");
        CreateVATEntry(DocumentNo, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::"Credit Memo", CustomerNo, 800, 160, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains amounts with reversed sign
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 1);
        VerifyTransactionNode(TempBlob, 0, 'Exports outside of EU', '-800', '-160', '1');
    end;

    [Test]
    procedure ExportServiceInvoiceAggregatesWithSalesInvoice()
    var
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        CustomerNo: Code[20];
        DocumentNo1: Code[20];
        DocumentNo2: Code[20];
        PostingDate: Date;
        VATBusPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Service invoice and sales invoice with same customer type aggregate into single Transactions
        Initialize();

        // [GIVEN] VAT Posting Setup with 20% rate
        VATBusPostingGroup := LibraryUtility.GenerateGUID();
        VATProdPostingGroup := LibraryUtility.GenerateGUID();
        CreateVATPostingSetup(VATBusPostingGroup, VATProdPostingGroup, 20);

        // [GIVEN] Customer "C" with Intra-Community transaction type
        CustomerNo := CreateCustomerWithTransType("FR E-Reporting Trans. Type"::"Intra-Community");

        // [GIVEN] E-Document "ED1" for Sales Invoice and "ED2" for Service Invoice with same customer
        PostingDate := WorkDate();
        DocumentNo1 := LibraryUtility.GenerateGUID();
        DocumentNo2 := LibraryUtility.GenerateGUID();
        CreateEDocument(EDocument, DocumentNo1, PostingDate, "E-Document Type"::"Sales Invoice");
        CreateVATEntry(DocumentNo1, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -1000, -200, VATBusPostingGroup, VATProdPostingGroup);
        CreateEDocument(EDocument, DocumentNo2, PostingDate, "E-Document Type"::"Service Invoice");
        CreateVATEntry(DocumentNo2, PostingDate, "General Posting Type"::Sale, "Gen. Journal Document Type"::Invoice, CustomerNo, -500, -100, VATBusPostingGroup, VATProdPostingGroup);

        // [WHEN] CreateBatchXML is called with both E-Documents
        EDocument.Reset();
        EDocument.SetFilter("Document No.", '%1|%2', DocumentNo1, DocumentNo2);
        CreateBatchXML(EDocument, TempBlob);

        // [THEN] XML contains one Transactions node with summed amounts and count=2
        InitXmlReader(TempBlob);
        LibraryXPathXMLReader.VerifyNodeCountByXPath('//trs:Transactions', 1);
        VerifyTransactionNode(TempBlob, 0, 'Intra-community deliveries and acquisitions', '1500', '300', '2');
    end;
    #endregion

    #region ClearanceStatus
    [Test]
    procedure ApprovedStatusSetsClearanceDate()
    var
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Approved status sets Clearance Date to non-zero DateTime
        Initialize();

        // [GIVEN] E-Document Service with E-Reporting FR format
        // [GIVEN] E-Document linked to the service
        CreateEDocumentService('ERFR-APPR', "E-Document Format"::"E-Reporting FR");
        CreateEDocumentWithService(EDocument, 'ERFR-APPR');

        // [GIVEN] E-Document Service Status with Approved status
        CreateEDocumentServiceStatus(EDocument."Entry No", 'ERFR-APPR', "E-Document Service Status"::Approved);

        // [WHEN] E-Document is modified
        EDocument.Modify(true);

        // [THEN] Clearance Date is set to non-zero DateTime
        EDocument.Get(EDocument."Entry No");
        Assert.AreNotEqual(0DT, EDocument."Clearance Date", 'Clearance Date should be non-zero after Approved status');
    end;

    [Test]
    procedure ClearedStatusSetsClearanceDate()
    var
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Cleared status sets Clearance Date to non-zero DateTime
        Initialize();

        // [GIVEN] E-Document Service with E-Reporting FR format
        // [GIVEN] E-Document linked to the service
        CreateEDocumentService('ERFR-CLR', "E-Document Format"::"E-Reporting FR");
        CreateEDocumentWithService(EDocument, 'ERFR-CLR');

        // [GIVEN] E-Document Service Status with Cleared status
        CreateEDocumentServiceStatus(EDocument."Entry No", 'ERFR-CLR', "E-Document Service Status"::Cleared);

        // [WHEN] E-Document is modified
        EDocument.Modify(true);

        // [THEN] Clearance Date is set to non-zero DateTime
        EDocument.Get(EDocument."Entry No");
        Assert.AreNotEqual(0DT, EDocument."Clearance Date", 'Clearance Date should be non-zero after Cleared status');
    end;

    [Test]
    procedure RejectedStatusBlanksClearanceDate()
    var
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Rejected status resets a non-zero Clearance Date to 0DT
        Initialize();

        // [GIVEN] E-Document Service with E-Reporting FR format
        // [GIVEN] E-Document linked to the service with non-zero Clearance Date
        CreateEDocumentService('ERFR-REJ', "E-Document Format"::"E-Reporting FR");
        CreateEDocumentWithService(EDocument, 'ERFR-REJ');
        EDocument."Clearance Date" := CurrentDateTime();
        EDocument.Modify(false);

        // [GIVEN] E-Document Service Status with Rejected status
        CreateEDocumentServiceStatus(EDocument."Entry No", 'ERFR-REJ', "E-Document Service Status"::Rejected);

        // [WHEN] E-Document is modified
        EDocument.Modify(true);

        // [THEN] Clearance Date is reset to 0DT
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(0DT, EDocument."Clearance Date", 'Clearance Date should be 0DT after Rejected status');
    end;

    [Test]
    procedure NotClearedStatusBlanksClearanceDate()
    var
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] "Not Cleared" status resets a non-zero Clearance Date to 0DT
        Initialize();

        // [GIVEN] E-Document Service with E-Reporting FR format
        // [GIVEN] E-Document linked to the service with non-zero Clearance Date
        CreateEDocumentService('ERFR-NCLR', "E-Document Format"::"E-Reporting FR");
        CreateEDocumentWithService(EDocument, 'ERFR-NCLR');
        EDocument."Clearance Date" := CurrentDateTime();
        EDocument.Modify(false);

        // [GIVEN] E-Document Service Status with Not Cleared status
        CreateEDocumentServiceStatus(EDocument."Entry No", 'ERFR-NCLR', "E-Document Service Status"::"Not Cleared");

        // [WHEN] E-Document is modified
        EDocument.Modify(true);

        // [THEN] Clearance Date is reset to 0DT
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(0DT, EDocument."Clearance Date", 'Clearance Date should be 0DT after Not Cleared status');
    end;

    [Test]
    procedure NonEReportingFRFormatIgnoredOnModify()
    var
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Service with different format leaves Clearance Date unchanged (0DT)
        Initialize();

        // [GIVEN] E-Document Service with non-E-Reporting FR format
        // [GIVEN] E-Document linked to the service
        CreateEDocumentService('ERFR-OTH', "E-Document Format"::"Data Exchange");
        CreateEDocumentWithService(EDocument, 'ERFR-OTH');

        // [GIVEN] E-Document Service Status with Approved status
        CreateEDocumentServiceStatus(EDocument."Entry No", 'ERFR-OTH', "E-Document Service Status"::Approved);

        // [WHEN] E-Document is modified
        EDocument.Modify(true);

        // [THEN] Clearance Date remains 0DT
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(0DT, EDocument."Clearance Date", 'Clearance Date should remain 0DT for non-E-Reporting FR format');
    end;

    [Test]
    procedure BlankServiceIgnoredOnModify()
    var
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] E-Document with blank Service leaves Clearance Date unchanged (0DT)
        Initialize();

        // [GIVEN] E-Document with blank Service
        EDocument.Init();
        EDocument."Entry No" := 0;
        EDocument.Service := '';
        EDocument.Insert();

        // [WHEN] E-Document is modified
        EDocument.Modify(true);

        // [THEN] Clearance Date remains 0DT
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(0DT, EDocument."Clearance Date", 'Clearance Date should remain 0DT for blank Service');
    end;
    #endregion

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Export E-Reporting Tests");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Export E-Reporting Tests");

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SaveCompanyInformation();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Export E-Reporting Tests");
    end;

    local procedure CreateCustomerWithTransType(TransType: Enum "FR E-Reporting Trans. Type"): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."FR E-Reporting Trans. Type" := TransType;
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithTransType(TransType: Enum "FR E-Reporting Trans. Type"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."FR E-Reporting Trans. Type" := TransType;
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreateEDocument(var EDocument: Record "E-Document"; DocumentNo: Code[20]; PostingDate: Date; DocumentType: Enum "E-Document Type")
    begin
        EDocument.Init();
        EDocument."Entry No" := 0;
        EDocument."Document No." := DocumentNo;
        EDocument."Posting Date" := PostingDate;
        EDocument."Document Type" := DocumentType;
        EDocument.Insert();
        EDocument.SetRecFilter();
    end;

    local procedure CreateVATEntry(DocumentNo: Code[20]; PostingDate: Date; VATType: Enum "General Posting Type"; DocumentType: Enum "Gen. Journal Document Type"; BillToPayToNo: Code[20]; Base: Decimal; Amount: Decimal; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
        CreateVATEntryWithCurrency(DocumentNo, PostingDate, VATType, DocumentType, BillToPayToNo, Base, Amount, '', VATBusPostingGroup, VATProdPostingGroup);
    end;

    local procedure CreateVATEntryWithCurrency(DocumentNo: Code[20]; PostingDate: Date; VATType: Enum "General Posting Type"; DocumentType: Enum "Gen. Journal Document Type"; BillToPayToNo: Code[20]; Base: Decimal; Amount: Decimal; SourceCurrencyCode: Code[10]; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        VATEntry: Record "VAT Entry";
        EntryNo: Integer;
    begin
        VATEntry.Reset();
        if VATEntry.FindLast() then
            EntryNo := VATEntry."Entry No." + 1
        else
            EntryNo := 1;

        VATEntry.Init();
        VATEntry."Entry No." := EntryNo;
        VATEntry."Document No." := DocumentNo;
        VATEntry."Posting Date" := PostingDate;
        VATEntry.Type := VATType;
        VATEntry."Document Type" := DocumentType;
        VATEntry."Bill-to/Pay-to No." := BillToPayToNo;
        VATEntry.Base := Base;
        VATEntry.Amount := Amount;
        VATEntry."Source Currency Code" := SourceCurrencyCode;
        VATEntry."VAT Bus. Posting Group" := VATBusPostingGroup;
        VATEntry."VAT Prod. Posting Group" := VATProdPostingGroup;
        VATEntry.Insert();
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; VATPercent: Decimal)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create the backing posting groups so the fabricated VAT Posting Setup is not orphaned.
        // Otherwise LibraryERM.FindVATPostingSetupInvt (used by LibrarySales.CreateCustomer) can pick up
        // a setup whose VAT Business Posting Group does not exist, breaking customer creation in other tests.
        if not VATBusinessPostingGroup.Get(VATBusPostingGroup) then begin
            VATBusinessPostingGroup.Init();
            VATBusinessPostingGroup.Code := VATBusPostingGroup;
            VATBusinessPostingGroup.Insert();
        end;
        if not VATProductPostingGroup.Get(VATProdPostingGroup) then begin
            VATProductPostingGroup.Init();
            VATProductPostingGroup.Code := VATProdPostingGroup;
            VATProductPostingGroup.Insert();
        end;
        VATPostingSetup.Init();
        VATPostingSetup."VAT Bus. Posting Group" := VATBusPostingGroup;
        VATPostingSetup."VAT Prod. Posting Group" := VATProdPostingGroup;
        VATPostingSetup."VAT %" := VATPercent;
        VATPostingSetup.Insert();
    end;

    local procedure CreateBatchXML(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob")
    var
        ExportEReporting: Codeunit "Export E-Reporting";
    begin
        ExportEReporting.CreateBatchXML(EDocument, TempBlob);
    end;

    local procedure InitXmlReader(var TempBlob: Codeunit "Temp Blob")
    begin
        LibraryXPathXMLReader.InitializeWithBlob(TempBlob, XmlNamespaceTrsTok);
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('trs', XmlNamespaceTrsTok);
    end;

    local procedure VerifyTransactionNode(var TempBlob: Codeunit "Temp Blob"; Index: Integer; ExpectedCategoryCode: Text; ExpectedTaxExclAmount: Text; ExpectedTaxTotal: Text; ExpectedCount: Text)
    begin
        Assert.AreEqual(ExpectedCategoryCode, GetNodeByPathWithIndexFromBlob(TempBlob, '//trs:Transactions/trs:CategoryCode', Index), 'Incorrect value for CategoryCode');
        Assert.AreEqual(ExpectedTaxExclAmount, GetNodeByPathWithIndexFromBlob(TempBlob, '//trs:Transactions/trs:TaxExclusiveAmount', Index), 'Incorrect value for TaxExclusiveAmount');
        Assert.AreEqual(ExpectedTaxTotal, GetNodeByPathWithIndexFromBlob(TempBlob, '//trs:Transactions/trs:TaxTotal', Index), 'Incorrect value for TaxTotal');
        Assert.AreEqual(ExpectedCount, GetNodeByPathWithIndexFromBlob(TempBlob, '//trs:Transactions/trs:TransactionsCount', Index), 'Incorrect value for TransactionsCount');
    end;

    local procedure VerifyTaxSubtotalNode(var TempBlob: Codeunit "Temp Blob"; Index: Integer; ExpectedTaxPercent: Text; ExpectedTaxableAmount: Text; ExpectedTaxTotal: Text)
    begin
        Assert.AreEqual(ExpectedTaxPercent, GetNodeByPathWithIndexFromBlob(TempBlob, '//trs:Transactions/trs:TaxSubtotal/trs:TaxPercent', Index), 'Incorrect value for TaxPercent');
        Assert.AreEqual(ExpectedTaxableAmount, GetNodeByPathWithIndexFromBlob(TempBlob, '//trs:Transactions/trs:TaxSubtotal/trs:TaxableAmount', Index), 'Incorrect value for TaxableAmount');
        Assert.AreEqual(ExpectedTaxTotal, GetNodeByPathWithIndexFromBlob(TempBlob, '//trs:Transactions/trs:TaxSubtotal/trs:TaxTotal', Index), 'Incorrect value for TaxTotal');
    end;

    local procedure GetNodeByPathFromBlob(var TempBlob: Codeunit "Temp Blob"; XPath: Text): Text
    var
        XmlDoc: XmlDocument;
        FileInStream: InStream;
    begin
        TempBlob.CreateInStream(FileInStream);
        XmlDocument.ReadFrom(FileInStream, XmlDoc);
        exit(GetNodeByPath(XmlDoc, XPath));
    end;

    local procedure GetNodeByPathWithIndexFromBlob(var TempBlob: Codeunit "Temp Blob"; XPath: Text; Index: Integer): Text
    var
        XmlDoc: XmlDocument;
        FileInStream: InStream;
    begin
        TempBlob.CreateInStream(FileInStream);
        XmlDocument.ReadFrom(FileInStream, XmlDoc);
        exit(GetNodeByPathWithIndex(XmlDoc, XPath, Index));
    end;

    local procedure GetNodeByPath(XmlDoc: XmlDocument; XPath: Text): Text
    begin
        exit(GetNodeByPathWithIndex(XmlDoc, XPath, 0));
    end;

    local procedure GetNodeByPathWithIndex(XmlDoc: XmlDocument; XPath: Text; Index: Integer): Text
    var
        NamespaceMgr: XmlNamespaceManager;
        FoundNode: XmlNode;
        AdjustedXPath: Text;
    begin
        NamespaceMgr.NameTable(XmlDoc.NameTable());
        NamespaceMgr.AddNamespace('trs', XmlNamespaceTrsTok);

        AdjustedXPath := AddXPathIndex(XPath, Index + 1);
        if XmlDoc.SelectSingleNode(AdjustedXPath, NamespaceMgr, FoundNode) then
            exit(FoundNode.AsXmlElement().InnerText());

        exit('');
    end;

    local procedure AddXPathIndex(XPath: Text; OneBasedIndex: Integer): Text
    begin
        if XPath.Contains('/trs:Transactions/') then
            exit(XPath.Replace('/trs:Transactions/', StrSubstNo(TransactionsXPathFormatTok, OneBasedIndex)));
        if XPath.Contains('/trs:TaxSubtotal/') then
            exit(XPath.Replace('/trs:TaxSubtotal/', StrSubstNo(TaxSubtotalXPathFormatTok, OneBasedIndex)));
        exit(XPath);
    end;

    local procedure CreateEDocumentService(ServiceCode: Code[20]; DocumentFormat: Enum "E-Document Format")
    var
        EDocumentService: Record "E-Document Service";
    begin
        if EDocumentService.Get(ServiceCode) then
            exit;
        EDocumentService.Init();
        EDocumentService.Code := ServiceCode;
        EDocumentService."Document Format" := DocumentFormat;
        EDocumentService.Insert();
    end;

    local procedure CreateEDocumentWithService(var EDocument: Record "E-Document"; ServiceCode: Code[20])
    begin
        EDocument.Init();
        EDocument."Entry No" := 0;
        EDocument.Service := ServiceCode;
        EDocument.Insert();
    end;

    local procedure CreateEDocumentServiceStatus(EDocumentEntryNo: Integer; ServiceCode: Code[20]; Status: Enum "E-Document Service Status")
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        EDocumentServiceStatus.Init();
        EDocumentServiceStatus."E-Document Entry No" := EDocumentEntryNo;
        EDocumentServiceStatus."E-Document Service Code" := ServiceCode;
        EDocumentServiceStatus.Status := Status;
        EDocumentServiceStatus.Insert();
    end;

    local procedure FormatDate(VarDate: Date): Text
    begin
        exit(Format(VarDate, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;
}
