codeunit 134154 "ERM Intercompany III"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Intercompany]
        IsInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        Assert: Codeunit Assert;
        SalesDocType: Enum "Sales Document Type";
        PurchaseDocType: Enum "Purchase Document Type";
        ICTransactionDocType: Enum "IC Transaction Document Type";
        ICPartnerRefType: Enum "IC Partner Reference Type";
        IsInitialized: Boolean;
        SendAgainQst: Label '%1 %2 has already been sent to intercompany partner %3. Resending it will create a duplicate %1 for them. Do you want to send it again?';
        AcceptAgainQst: Label '%1 %2 has already been received from intercompany partner %3. Accepting it again will create a duplicate %1. Do you want to accept the %1?';
        InsufficientQtyErr: Label 'You have insufficient quantity of Item';

    [Test]
    [HandlerFunctions('ComfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure TestConfirmNoDoesNotOpenIntercompanySetupWhenSetupIsMissing()
    var
        ICSetup: Record "IC Setup";
        ICPartnerList: TestPage "IC Partner List";
    begin
        // [SCENARIO ] When Intercompany Setup is missing, opening the Intercompany Partners page opens up a confirmation to setup intercompany information. Invoking No on the
        // confirmation does not open up the Intercompany Setup page
        Initialize();

        // [GIVEN] Company Information where IC Partner Code = ''
        ICSetup.Get();
        ICSetup.Validate("IC Partner Code", '');
        ICSetup.Modify(true);

        // [WHEN] Intercompany Partners page is not opened
        asserterror ICPartnerList.OpenEdit();

        // [THEN] Verification is that the ConfirmHandler is hit and the ICSetup page is not
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoConfirmWhenIntercompanySetupExists()
    var
        ICSetup: Record "IC Setup";
        ICPartnerList: TestPage "IC Partner List";
    begin
        // [SCENARIO ] When Intercompany Setup exists, opening the Intercompany Partners page
        // does not open up a confirmation but opens Intercompany Partners page.
        Initialize();

        // [GIVEN] Company Information where IC Partner Code <> ''
        ICSetup.Get();
        ICSetup.Validate("IC Partner Code", CopyStr(
            LibraryUtility.GenerateRandomCode(ICSetup.FieldNo("IC Partner Code"), DATABASE::"Company Information"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Company Information", ICSetup.FieldNo("IC Partner Code"))));
        ICSetup.Modify(true);

        // [WHEN] Intercompany Partners page is opened
        ICPartnerList.OpenEdit();

        // [THEN] Verification is that the ConfirmHandler is not hit
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesDocumentFromICSalesDocWithDimension()
    var
        DimensionValue: array[5] of Record "Dimension Value";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales] [Dimensions]
        // [SCENARIO 227855] Sales Order should contains merged Dimension Set from Customer and IC inbox
        Initialize();

        // [GIVEN] Dimensions and Dimension Values:
        // [GIVEN] Dimension "D1" with Dimension Value "DV1"
        // [GIVEN] Dimension "D2" with Dimension Values "DV2-1" and "DV2-1"
        // [GIVEN] Dimension "D3" with Dimension Value "DV3"
        // [GIVEN] Dimension "D4" with Dimension Value "DV4"
        CreateSetOfDimValues(DimensionValue);

        // [GIVEN] Customer with Default Dimensions:
        // [GIVEN] Dimension - "D1" and "Dimension Value" - "DV1"
        // [GIVEN] Dimension - "D2" and "Dimension Value" - "DV2-1"
        CustomerNo := CreateCustomerWithDefaultDimensions(DimensionValue);

        // [GIVEN] IC Inbox Sales Order with
        // [GIVEN] Dimensions of Sales Header
        // [GIVEN] Dimension - "D2" and "Dimension Value" - "DV2-2"
        // [GIVEN] Dimension - "D3" and "Dimension Value" - "DV3"
        // [GIVEN] Dimensions of Sales Line
        // [GIVEN] Dimension - "D4" and "Dimension Value" - "DV4"
        MockICInboxSalesOrder(ICInboxSalesHeader, DimensionValue, CustomerNo);

        // [WHEN] Invoke CreateSalesDocument
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());

        // [THEN] Created Sales Order has dimensions:
        // [THEN] Sales header:
        // [THEN] Dimension "D1" with Dimension Value "DV1"
        // [THEN] Dimension "D2" with Dimension Value "DV2-2"
        // [THEN] Dimension "D3" with Dimension Value "DV3"
        // [THEN] Sales Line:
        // [THEN] Dimensions are same as in the header and
        // [THEN] Dimension "D4" with Dimension Value "DV4"
        VerifySalesDocDimSet(DimensionValue, CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePurchDocumentFromICPurchDocWithDimension()
    var
        DimensionValue: array[5] of Record "Dimension Value";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Dimensions]
        // [SCENARIO 227855] Purchase Order should contains merged Dimension Set from Vendor and IC inbox
        Initialize();

        // [GIVEN] Dimensions and Dimension Values:
        // [GIVEN] Dimension "D1" with Dimension Value "DV1"
        // [GIVEN] Dimension "D2" with Dimension Values "DV2-1" and "DV2-2"
        // [GIVEN] Dimension "D3" with Dimension Value "DV3"
        // [GIVEN] Dimension "D4" with Dimension Value "DV4"
        CreateSetOfDimValues(DimensionValue);

        // [GIVEN] Vendor with Default Dimensions:
        // [GIVEN] Dimension - "D1" and "Dimension Value" - "DV1"
        // [GIVEN] Dimension - "D2" and "Dimension Value" - "DV2-1"
        VendorNo := CreateVendorWithDefaultDimensions(DimensionValue);

        // [GIVEN] IC Inbox Purchase Order with
        // [GIVEN] Dimensions of Purchase Header
        // [GIVEN] Dimension - "D2" and "Dimension Value" - "DV2-2"
        // [GIVEN] Dimension - "D3" and "Dimension Value" - "DV3"
        // [GIVEN] Dimensions of Purchase Line
        // [GIVEN] Dimension - "D4" and "Dimension Value" - "DV4"
        MockICInboxPurchOrder(ICInboxPurchaseHeader, DimensionValue, VendorNo);

        // [WHEN] Invoke CreatePurchDocument
        ICInboxOutboxMgt.CreatePurchDocument(ICInboxPurchaseHeader, false, WorkDate());

        // [THEN] Created Purchase Order has dimensions:
        // [THEN] Purchase header:
        // [THEN] Dimension "D1" with Dimension Value "DV1"
        // [THEN] Dimension "D2" with Dimension Value "DV2-2"
        // [THEN] Dimension "D3" with Dimension Value "DV3"
        // [THEN] Purchase Line:
        // [THEN] Dimensions are same as in the header and
        // [THEN] Dimension "D4" with Dimension Value "DV4"
        VerifyPurchDocDimSet(DimensionValue, VendorNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CreateICDimValuesFromDimValuesWithBeginEndTotalAndZeroIndentation()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ExpectedIndentation: array[6] of Integer;
    begin
        // [FEATURE] [Indentation] [Dimensions]
        // [SCENARIO 273581] Create IC Dimension Values from Dimension Values with Begin-Total/End-Total types and zero indentation.
        Initialize();

        // [GIVEN] Dimension Values of Begin-Total and End-Total types with nested Dimension Values. All records have zero Indentation.
        CreateDimValuesBeginEndTotalZeroIndentation(DimensionValue, ExpectedIndentation);

        // [WHEN] Create IC Dimension Values from Dimension Values.
        RunCopyICDimensionsFromDimensions();

        // [THEN] Indentation of nested IC Dimension Values is greater than zero. Indentation of children is 1 greater than the parent's indentation.
        VerifyIndentationICDimensionValuesAfterCopy(DimensionValue, ExpectedIndentation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoSendWorksForMultilineTransactions()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        ICGLAccount: Record "IC G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICSetup: Record "IC Setup";
        ICPartnerCode: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Journal] [Post]
        // [SCENARIO 279681] User can post a multi-line IC transaction with Auto-send enabled
        Initialize();

        // [GIVEN] An IC journal batch, IC Partner Code, IC G/L Account, DocumentNo and an amount
        ICPartnerCode := CreateICPartnerWithInbox();
        LibraryERM.CreateICGLAccount(ICGLAccount);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Intercompany);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        Amount := LibraryRandom.RandDec(1000, 2);
        DocumentNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Auto Send Transactions was enabled
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify();

        // [GIVEN] 2 IC General journal lines for 1 Document No
        CreateICGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bal. Account Type"::"G/L Account", '', ICGLAccount."No.", Amount, DocumentNo);
        CreateICGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"IC Partner", ICPartnerCode,
          GenJournalLine."Bal. Account Type"::"G/L Account", '', '', -Amount, DocumentNo);

        // [WHEN] Posting journal batch
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Outbox transaction created by posting is Handled by auto send
        HandledICOutboxTrans.SetRange("Document No.", DocumentNo);
        Assert.RecordIsNotEmpty(HandledICOutboxTrans);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingGenJournalLineDoesntCallIntercompanyCodeunitOnNonICLine()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CodeCoverage: Record "Code Coverage";
    begin
        // [FEATURE] [Journal] [Post]
        // [SCENARIO 290373] When posting non-InterCompany Gen. Journal Line - Codeunit "IC Outbox Export" is not called
        Initialize();
        CodeCoverageMgt.StopApplicationCoverage();

        // [GIVEN] A non-InterCompany General Journal Batch
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // [GIVEN] A Gen. Journal Line in this Journal Batch
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNoWithDirectPosting(), GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNoWithDirectPosting(), LibraryRandom.RandDec(1000, 2));

        // [WHEN] Post this Gen. Journal Line
        CodeCoverageMgt.StartApplicationCoverage();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] Codeunit "IC Outbox Export" is not called
        Assert.AreEqual(
          0, CodeCoverageMgt.GetNoOfHitsCoverageForObject(CodeCoverage."Object Type"::Codeunit, CODEUNIT::"IC Outbox Export", ''),
          'IC Outbox Export was called');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryOfPostedSalesInvoice()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice] [Post]
        // [SCENARIO 305580] Posting Sales Invoice with non-default Bill-to Customer with IC Partner Code results in Ledger Entry having the same IC Partner Code
        Initialize();

        // [GIVEN] Customer "X" with IC Partner Code "Y".
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("IC Partner Code", LibraryERM.CreateICPartnerNo());
        Customer.Modify(true);

        // [GIVEN] Sales Invoice with non-default Bill-to Customer "Y".
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Bill-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [WHEN] Sales Invoice is posted.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Ledger Entry has IC Partner Code "Y".
        CustLedgerEntry.SetRange("Document No.", PostedDocumentNo);
        CustLedgerEntry.FindFirst();
        Assert.AreEqual(Customer."IC Partner Code", CustLedgerEntry."IC Partner Code", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryOfPostedSalesInvoice()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase Invoice] [Post]
        // [SCENARIO 305580] Posting Purchase Invoice with non-default Pay-to Vendor with IC Partner Code results in Ledger Entry having the same IC Partner Code
        Initialize();

        // [GIVEN] Vendor "X" with IC Partner Code "Y".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("IC Partner Code", LibraryERM.CreateICPartnerNo());
        Vendor.Modify(true);

        // [GIVEN] Sales Invoice with non-default Bill-to Customer "Y".
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Pay-to Vendor No.", Vendor."No.");
        PurchaseHeader.Modify(true);

        // [WHEN] Purchase Invoice is posted.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, false);

        // [THEN] Ledger Entry has IC Partner Code "Y".
        VendorLedgerEntry.SetRange("Document No.", PostedDocumentNo);
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(Vendor."IC Partner Code", VendorLedgerEntry."IC Partner Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryDescriptionWhenPostSalesDocumentWithPostingDescription()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 349615] Post Sales Document with "Posting Description" when IC Partner is set for Sales Line.
        Initialize();

        // [GIVEN] Sales Invoice with nonempty "Posting Description". Sales Line with IC Partner.
        CreateSalesDocumentWithGLAccount(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);
        UpdatePostingDescriptionOnSalesHeader(SalesHeader, LibraryUtility.GenerateGUID());
        UpdateICInfoOnSalesLine(SalesLine, CreateICPartnerWithInbox());

        // [WHEN] Post Sales Invoice.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] GL Entry with "Bal. Account No." = IC Partner Code have Description = "Posting Description" of Sales Invoice.
        VerifyGLEntryDescriptionICPartner(
            PostedDocumentNo, SalesHeader."Document Type"::Invoice, SalesLine."IC Partner Code", SalesHeader."Posting Description");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryDescriptionWhenPostSalesDocumentWithBlankPostingDescription()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
        ExpectedDescription: Text[100];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 349615] Post Sales Document with blank "Posting Description" when IC Partner is set for Sales Line.
        Initialize();

        // [GIVEN] Customer with Name = "CN".
        // [GIVEN] Sales Invoice for Customer "CN" with blank "Posting Description". Sales Line with IC Partner.
        CreateSalesDocumentWithGLAccount(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice);
        UpdatePostingDescriptionOnSalesHeader(SalesHeader, '');
        UpdateICInfoOnSalesLine(SalesLine, CreateICPartnerWithInbox());

        // [WHEN] Post Sales Invoice. Posted Sales Invoice No. = "PI".
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] GL Entry with "Bal. Account No." = IC Partner Code has Description = "Invo. PI/CN".
        ExpectedDescription := StrSubstNo('Invo. %1/%2', PostedDocumentNo, SalesHeader."Bill-to Name");
        VerifyGLEntryDescriptionICPartner(
            PostedDocumentNo, SalesHeader."Document Type"::Invoice, SalesLine."IC Partner Code", ExpectedDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryDescriptionWhenPostPurchaseDocumentWithPostingDescription()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 349615] Post Purchase Document with "Posting Description" when IC Partner is set for Purchase Line.
        Initialize();

        // [GIVEN] Purchase Invoice with nonempty "Posting Description". Purchase Line with IC Partner.
        CreatePurchaseDocumentWithGLAccount(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);
        UpdatePostingDescriptionOnPurchaseHeader(PurchaseHeader, LibraryUtility.GenerateGUID());
        UpdateICInfoOnPurchaseLine(PurchaseLine, CreateICPartnerWithInbox());

        // [WHEN] Post Purchase Invoice.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] GL Entry with "Bal. Account No." = IC Partner Code have Description = "Posting Description" of Purchase Invoice.
        VerifyGLEntryDescriptionICPartner(
            PostedDocumentNo, PurchaseHeader."Document Type"::Invoice, PurchaseLine."IC Partner Code", PurchaseHeader."Posting Description");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryDescriptionWhenPostPurchaseDocumentWithBlankPostingDescription()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        ExpectedDescription: Text[100];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 349615] Post Purchase Document with blank "Posting Description" when IC Partner is set for Purchase Line.
        Initialize();

        // [GIVEN] Vendor with Name = "VN".
        // [GIVEN] Purchase Invoice for Vendor "VN" with blank "Posting Description" and "Vendor Invoice No." = "VI".
        // [GIVEN] Purchase Line with IC Partner.
        CreatePurchaseDocumentWithGLAccount(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice);
        UpdatePostingDescriptionOnPurchaseHeader(PurchaseHeader, '');
        UpdateICInfoOnPurchaseLine(PurchaseLine, CreateICPartnerWithInbox());

        // [WHEN] Post Purchase Invoice.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] GL Entry with "Bal. Account No." = IC Partner Code has Description = "Inv. VI/VN".
        ExpectedDescription := StrSubstNo('Inv. %1/%2', PurchaseHeader."Vendor Invoice No.", PurchaseHeader."Pay-to Name");
        VerifyGLEntryDescriptionICPartner(
            PostedDocumentNo, PurchaseHeader."Document Type"::Invoice, PurchaseLine."IC Partner Code", ExpectedDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyShipmentFieldsInOutboxExportFile()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        ICSetup: Record "IC Setup";
        FileManagement: Codeunit "File Management";
        ICOutboxImpExp: XMLport "IC Outbox Imp/Exp";
        OutStream: OutStream;
        TempFile: File;
        FileName: Text;
    begin
        // [FEATURE] [XML] [Export]
        // [SCENARIO 352224] When exporting IC Outbox transaction to file Order No. field of header and shipment fields of line are exported
        Initialize();

        // [GIVEN] Company information has intercompany code
        ICSetup.Get();
        ICSetup.Validate("IC Partner Code", LibraryUtility.GenerateGUID());
        ICSetup.Modify();

        // [GIVEN] IC Outbox Transaction
        MockICOutboxTrans(ICOutboxTransaction);

        // [GIVEN] IC Outbox sales header linked to transaction
        MockICOutboxSalesHeader(ICOutboxSalesHeader, ICOutboxTransaction);

        // [GIVEN] IC Outbox sales line linked to IC Outbox Sales Header
        MockICOutboxSalesLine(ICOutboxSalesLine, ICOutboxSalesHeader);

        // [WHEN] Export Outbox transaction with header and line
        FileName := FileManagement.ServerTempFileName('.xml');
        TempFile.Create(FileName);
        TempFile.CreateOutStream(OutStream);
        ICOutboxTransaction.SetRange("Transaction No.", ICOutboxTransaction."Transaction No.");
        ICOutboxImpExp.SetICOutboxTrans(ICOutboxTransaction);
        ICOutboxImpExp.SetDestination(OutStream);
        ICOutboxImpExp.Export();
        TempFile.Close();

        LibraryXMLRead.Initialize(FileName);
        // [THEN] OrderNo field is exported for header
        Assert.AreEqual(
          ICOutboxSalesHeader."Order No.",
          LibraryXMLRead.GetAttributeValueInSubtree('ICTransactions', 'ICOutBoxSalesHdr', 'OrderNo'), 'Order No must have a value');

        // [THEN] Shipment fields are exported for line
        Assert.AreEqual(
          ICOutboxSalesLine."Shipment No.",
          LibraryXMLRead.GetAttributeValueInSubtree('ICTransactions', 'ICOutBoxSalesLine', 'ShipmentNo'),
          'Shipment No must have a value');
        Assert.AreEqual(
          Format(ICOutboxSalesLine."Shipment Line No."),
          LibraryXMLRead.GetAttributeValueInSubtree('ICTransactions', 'ICOutBoxSalesLine', 'ShipmentLineNo'),
          'Shipment Line No must have a value');

        // Clean-up
        FileManagement.DeleteServerFile(FileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineReservedQuantityWhenCustomerReserveAlways()
    var
        Customer: Record Customer;
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ReserveMethod: Enum "Reserve Method";
        ICPartnerRefType: Enum "IC Partner Reference Type";
        ItemNo: Code[20];
        LineNo: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 360306] Create Sales Order from IC Inbox Transaction in case Customer has Reserve = Always.
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        CreateAndPostPurchaseOrder(ItemNo);

        // [GIVEN] Customer with Reserve = Always and IC Partner Code "ICP1".
        // [GIVEN] IC Inbox Transaction with Sales Order type for IC Partner "ICP1".
        // [GIVEN] IC Indox Transaction has linked IC Inbox Sales Line with "IC Partner Ref. Type" = "Item", Quantity = "Q1" > 0.
        CreateCustomerWithICPartner(Customer);
        UpdateReserveOnCustomer(Customer, ReserveMethod::Always);
        MockICInboxSalesHeader(ICInboxSalesHeader, Customer."No.");
        LineNo := MockICInboxSalesLine(ICInboxSalesHeader, ICPartnerRefType::Item, ItemNo);
        ICInboxSalesLine.Get(
            ICInboxSalesHeader."IC Transaction No.", ICInboxSalesHeader."IC Partner Code",
            ICInboxSalesHeader."Transaction Source", LineNo);

        // [WHEN] Create Sales Order from IC Inbox Transaction.
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());

        // [THEN] Sales Order with line is created. Sales Line has Quantity = "Q1", Reserved Quantity = "Q1".
        VerifyReservedQuantityOnSalesLine(Customer."No.", ICInboxSalesLine.Quantity, ICInboxSalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineReservedQuantityWhenCustomerReserveOptional()
    var
        Customer: Record Customer;
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ReserveMethod: Enum "Reserve Method";
        ICPartnerRefType: Enum "IC Partner Reference Type";
        ItemNo: Code[20];
        LineNo: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 360306] Create Sales Order from IC Inbox Transaction in case Customer has Reserve = Optional.
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        CreateAndPostPurchaseOrder(ItemNo);

        // [GIVEN] Customer with Reserve = Optional and IC Partner Code "ICP1".
        // [GIVEN] IC Inbox Transaction with Sales Order type for IC Partner "ICP1".
        // [GIVEN] IC Indox Transaction has linked IC Inbox Sales Line with "IC Partner Ref. Type" = "Item", Quantity = "Q1".
        CreateCustomerWithICPartner(Customer);
        UpdateReserveOnCustomer(Customer, ReserveMethod::Optional);
        MockICInboxSalesHeader(ICInboxSalesHeader, Customer."No.");
        LineNo := MockICInboxSalesLine(ICInboxSalesHeader, ICPartnerRefType::Item, ItemNo);
        ICInboxSalesLine.Get(
            ICInboxSalesHeader."IC Transaction No.", ICInboxSalesHeader."IC Partner Code",
            ICInboxSalesHeader."Transaction Source", LineNo);

        // [WHEN] Create Sales Order from IC Inbox Transaction.
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());

        // [THEN] Sales Order with line is created. Sales Line has Quantity = "Q1", Reserved Quantity = 0.
        VerifyReservedQuantityOnSalesLine(Customer."No.", ICInboxSalesLine.Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineNonItemTypeReservedQuantityWhenCustomerReserveAlways()
    var
        Customer: Record Customer;
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICGLAccount: Record "IC G/L Account";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ReserveMethod: Enum "Reserve Method";
        ICPartnerRefType: Enum "IC Partner Reference Type";
        LineNo: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 360306] Create Sales Order with G/L Account type line from IC Inbox Transaction in case Customer has Reserve = Always.
        Initialize();
        LibraryERM.CreateICGLAccount(ICGLAccount);

        // [GIVEN] Customer with Reserve = Always and IC Partner Code "ICP1".
        // [GIVEN] IC Inbox Transaction with Sales Order type for IC Partner "ICP1".
        // [GIVEN] IC Indox Transaction has linked IC Inbox Sales Line with "IC Partner Ref. Type" = "G/L Account", Quantity = "Q1".
        CreateCustomerWithICPartner(Customer);
        UpdateReserveOnCustomer(Customer, ReserveMethod::Always);
        MockICInboxSalesHeader(ICInboxSalesHeader, Customer."No.");
        LineNo := MockICInboxSalesLine(ICInboxSalesHeader, ICPartnerRefType::"G/L Account", ICGLAccount."No.");
        ICInboxSalesLine.Get(
            ICInboxSalesHeader."IC Transaction No.", ICInboxSalesHeader."IC Partner Code",
            ICInboxSalesHeader."Transaction Source", LineNo);

        // [WHEN] Create Sales Order from IC Inbox Transaction.
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());

        // [THEN] Sales Order with line is created. Sales Line has Quantity = "Q1", Reserved Quantity = 0.
        VerifyReservedQuantityOnSalesLine(Customer."No.", ICInboxSalesLine.Quantity, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTheSendICDocumentWorkCorrectlyForPurchaseOrder()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICSetup: Record "IC Setup";
        PurchaseHeader: Record "Purchase Header";
        ICPartner: Record "IC Partner";
        Vendor: Record Vendor;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 366071] Create Purchase Order and send as IC Document
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Auto Send Transactions was enabled
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify();

        ICOutboxTransaction.DeleteAll();

        // [GIVEN] IC Parthner with Customer No.
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.Validate("Buy-from IC Partner Code", ICPartnerCode);
        PurchaseHeader.Validate("Send IC Document", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Set IC Parthner Code for created Vendor
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.Validate("IC Partner Code", ICPartnerCode);
        Vendor.Modify(true);

        // [WHEN] Sent Intercompany Purchase Order
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [THEN] Outbox transaction created by posting is Handled by auto send
        HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::Order);
        HandledICOutboxTrans.SetRange("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Purchase Document");
        HandledICOutboxTrans.SetRange("Document No.", PurchaseHeader."No.");
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTrans.FindFirst();
        Assert.RecordCount(HandledICOutboxTrans, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendPurchaseOrderMoreThanOnceConfirmNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        PurchaseHeader: Record "Purchase Header";
        Customer: Record Customer;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 403295] Create Purchase Order and send as IC Document, then send the same document again. Reply No to confirm question.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Purchase Order "PO" for Vendor with IC Partner.
        CreatePurchaseDocumentForICPartnerVendor(PurchaseHeader, PurchaseDocType::Order, ICPartnerCode, false, 0);

        // [GIVEN] Sent Intercompany Purchase Order.
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        Commit();

        // [WHEN] Send the same document again. Reply No to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(false);
        asserterror ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [THEN] Confirm with question "Order PO has already been sent ... Do you want to send it again?" was shown.
        // [THEN] Sending process was interrupted with Error('').
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::Order, PurchaseHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        // [THEN] Handled IC Outbox contains only one record for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Purchase Document", ICTransactionDocType::Order, PurchaseHeader."No.", ICPartnerCode, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTheSendICDocumentWorkCorrectlyForPurchaseInvoice()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICSetup: Record "IC Setup";
        PurchaseHeader: Record "Purchase Header";
        ICPartner: Record "IC Partner";
        Vendor: Record Vendor;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 366071] Create Purchase Invoice and send as IC Document
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Auto Send Transactions was enabled
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] IC Parthner with Customer No.
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Buy-from IC Partner Code", ICPartnerCode);
        PurchaseHeader.Validate("Send IC Document", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Set IC Parthner Code for created Vendor
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.Validate("IC Partner Code", ICPartnerCode);
        Vendor.Modify(true);

        // [WHEN] Sent Intercompany Purchase Invoice
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [THEN] Outbox transaction created by posting is Handled by auto send
        HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::Invoice);
        HandledICOutboxTrans.SetRange("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Purchase Document");
        HandledICOutboxTrans.SetRange("Document No.", PurchaseHeader."No.");
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTrans.FindFirst();
        Assert.RecordCount(HandledICOutboxTrans, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendPurchaseInvoiceMoreThanOnceConfirmNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        PurchaseHeader: Record "Purchase Header";
        Customer: Record Customer;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 403295] Create Purchase Invoice and send as IC Document, then send the same document again. Reply No to confirm question.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Purchase Invoice "PI" for Vendor with IC Partner.
        CreatePurchaseDocumentForICPartnerVendor(PurchaseHeader, PurchaseDocType::Invoice, ICPartnerCode, false, 0);

        // [GIVEN] Sent Intercompany Purchase Invoice.
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        Commit();

        // [WHEN] Send the same document again. Reply No to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(false);
        asserterror ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [THEN] Confirm with question "Invoice PI has already been sent ... Do you want to send it again?" was shown.
        // [THEN] Sending process was interrupted with Error('').
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::Invoice, PurchaseHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        // [THEN] Handled IC Outbox contains only one record for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Purchase Document", ICTransactionDocType::Invoice, PurchaseHeader."No.", ICPartnerCode, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTheSendICDocumentWorkCorrectlyForPurchaseCrMemo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICSetup: Record "IC Setup";
        PurchaseHeader: Record "Purchase Header";
        ICPartner: Record "IC Partner";
        Vendor: Record Vendor;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 366071] Create Purchase Cr. Memo and send as IC Document
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Auto Send Transactions was enabled
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] IC Parthner with Customer No.
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Purchase Cr. Memo
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        PurchaseHeader.Validate("Buy-from IC Partner Code", ICPartnerCode);
        PurchaseHeader.Validate("Send IC Document", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Set IC Parthner Code for created Vendor
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.Validate("IC Partner Code", ICPartnerCode);
        Vendor.Modify(true);

        // [WHEN] Sent Intercompany Purchase Cr. Memo
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [THEN] Outbox transaction created by posting is Handled by auto send
        HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::"Credit Memo");
        HandledICOutboxTrans.SetRange("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Purchase Document");
        HandledICOutboxTrans.SetRange("Document No.", PurchaseHeader."No.");
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTrans.FindFirst();
        Assert.RecordCount(HandledICOutboxTrans, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendPurchaseCrMemoMoreThanOnceConfirmNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        PurchaseHeader: Record "Purchase Header";
        Customer: Record Customer;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 403295] Create Purchase Credit Memo and send as IC Document, then send the same document again. Reply No to confirm question.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Purchase Credit Memo "PCM" for Vendor with IC Partner.
        CreatePurchaseDocumentForICPartnerVendor(PurchaseHeader, PurchaseDocType::"Credit Memo", ICPartnerCode, false, 0);

        // [GIVEN] Sent Intercompany Purchase Credit Memo.
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        Commit();

        // [WHEN] Send the same document again. Reply No to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(false);
        asserterror ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [THEN] Confirm with question "Credit Memo PCM has already been sent ... Do you want to send it again?" was shown.
        // [THEN] Sending process was interrupted with Error('').
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::"Credit Memo", PurchaseHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        // [THEN] Handled IC Outbox contains only one record for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Purchase Document", ICTransactionDocType::"Credit Memo", PurchaseHeader."No.", ICPartnerCode, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTheSendICDocumentWorkCorrectlyForPurchaseReturnOrder()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICSetup: Record "IC Setup";
        PurchaseHeader: Record "Purchase Header";
        ICPartner: Record "IC Partner";
        Vendor: Record Vendor;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 366071] Create Purchase Return Order and send as IC Document
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Auto Send Transactions was enabled
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] IC Parthner with Customer No.
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Customer No.", LibrarySales.CreateCustomerNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Purchase Return Order
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader);
        PurchaseHeader.Validate("Buy-from IC Partner Code", ICPartnerCode);
        PurchaseHeader.Validate("Send IC Document", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Set IC Parthner Code for created Vendor
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.Validate("IC Partner Code", ICPartnerCode);
        Vendor.Modify(true);

        // [WHEN] Sent Intercompany Purchase Return Order
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [THEN] Outbox transaction created by posting is Handled by auto send
        HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::"Return Order");
        HandledICOutboxTrans.SetRange("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Purchase Document");
        HandledICOutboxTrans.SetRange("Document No.", PurchaseHeader."No.");
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTrans.FindFirst();
        Assert.RecordCount(HandledICOutboxTrans, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendPurchaseReturnOrderMoreThanOnceConfirmNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        PurchaseHeader: Record "Purchase Header";
        Customer: Record Customer;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 403295] Create Purchase Return Order and send as IC Document, then send the same document again. Reply No to confirm question.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Purchase Return Order "PRO" for Vendor with IC Partner.
        CreatePurchaseDocumentForICPartnerVendor(PurchaseHeader, PurchaseDocType::"Return Order", ICPartnerCode, false, 0);

        // [GIVEN] Sent Intercompany Purchase Return Order.
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        Commit();

        // [WHEN] Send the same document again. Reply No to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(false);
        asserterror ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [THEN] Confirm with question "Return Order PRO has already been sent ... Do you want to send it again?" was shown.
        // [THEN] Sending process was interrupted with Error('').
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::"Return Order", PurchaseHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        // [THEN] Handled IC Outbox contains only one record for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Purchase Document", ICTransactionDocType::"Return Order", PurchaseHeader."No.", ICPartnerCode, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTheSendICDocumentWorkCorrectlyForSalesOrder()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICSetup: Record "IC Setup";
        SalesHeader: Record "Sales Header";
        ICPartner: Record "IC Partner";
        Customer: Record Customer;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 366071] Create Sales Order and send as IC Document
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Auto Send Transactions was enabled
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] IC Parthner with Vendor No.
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Sales Order
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Validate("Sell-to IC Partner Code", ICPartnerCode);
        SalesHeader.Validate("Send IC Document", true);
        SalesHeader.Modify(true);

        // [GIVEN] Set IC Parthner Code for created Customer
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);

        // [WHEN] Sent Intercompany Sales Order
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [THEN] Outbox transaction created by posting is Handled by auto send
        HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::Order);
        HandledICOutboxTrans.SetRange("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Sales Document");
        HandledICOutboxTrans.SetRange("Document No.", SalesHeader."No.");
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTrans.FindFirst();
        Assert.RecordCount(HandledICOutboxTrans, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendSalesOrderMoreThanOnceConfirmNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 403295] Create Sales Order and send as IC Document, then send the same document again. Reply No to confirm question.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Order "SO" for Customer with IC Partner.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::Order, ICPartnerCode);

        // [GIVEN] Sent Intercompany Sales Order.
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);
        Commit();

        // [WHEN] Send the same document again. Reply No to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(false);
        asserterror ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [THEN] Confirm with question "Order SO has already been sent ... Do you want to send it again?" was shown.
        // [THEN] Sending process was interrupted with Error('').
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::Order, SalesHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        // [THEN] Handled IC Outbox contains only one record for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Sales Document", ICTransactionDocType::Order, SalesHeader."No.", ICPartnerCode, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTheSendICDocumentWorkCorrectlyForSalesInvoice()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICSetup: Record "IC Setup";
        SalesHeader: Record "Sales Header";
        ICPartner: Record "IC Partner";
        Customer: Record Customer;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 366071] Create Sales Invoice and send as IC Document
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Auto Send Transactions was enabled
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] IC Parthner with Vendor No.
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Sales Invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Sell-to IC Partner Code", ICPartnerCode);
        SalesHeader.Validate("Send IC Document", true);
        SalesHeader.Modify(true);

        // [GIVEN] Set IC Parthner Code for created Customer
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);

        // [WHEN] Sent Intercompany Sales Invoice
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [THEN] Outbox transaction created by posting is Handled by auto send
        HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::Invoice);
        HandledICOutboxTrans.SetRange("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Sales Document");
        HandledICOutboxTrans.SetRange("Document No.", SalesHeader."No.");
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTrans.FindFirst();
        Assert.RecordCount(HandledICOutboxTrans, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendSalesInvoiceMoreThanOnceConfirmNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 403295] Create Sales Invoice and send as IC Document, then send the same document again. Reply No to confirm question.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Invoice "SI" for Customer with IC Partner.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::Invoice, ICPartnerCode);

        // [GIVEN] Sent Intercompany Sales Invoice.
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);
        Commit();

        // [WHEN] Send the same document again. Reply No to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(false);
        asserterror ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [THEN] Confirm with question "Invoice SI has already been sent ... Do you want to send it again?" was shown.
        // [THEN] Sending process was interrupted with Error('').
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::Invoice, SalesHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        // [THEN] Handled IC Outbox contains only one record for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Sales Document", ICTransactionDocType::Invoice, SalesHeader."No.", ICPartnerCode, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTheSendICDocumentWorkCorrectlyForSalesCrMemo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICSetup: Record "IC Setup";
        SalesHeader: Record "Sales Header";
        ICPartner: Record "IC Partner";
        Customer: Record Customer;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 366071] Create Sales Cr. Memo and send as IC Document
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Auto Send Transactions was enabled
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] IC Parthner with Vendor No.
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Sales Cr. Memo
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        SalesHeader.Validate("Sell-to IC Partner Code", ICPartnerCode);
        SalesHeader.Validate("Send IC Document", true);
        SalesHeader.Modify(true);

        // [GIVEN] Set IC Parthner Code for created Customer
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);

        // [WHEN] Sent Intercompany Sales Cr. Memo
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [THEN] Outbox transaction created by posting is Handled by auto send
        HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::"Credit Memo");
        HandledICOutboxTrans.SetRange("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Sales Document");
        HandledICOutboxTrans.SetRange("Document No.", SalesHeader."No.");
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTrans.FindFirst();
        Assert.RecordCount(HandledICOutboxTrans, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendSalesCrMemoMoreThanOnceConfirmNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 403295] Create Sales Credit Memo and send as IC Document, then send the same document again. Reply No to confirm question.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Credit Memo "SCM" for Customer with IC Partner.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::"Credit Memo", ICPartnerCode);

        // [GIVEN] Sent Intercompany Sales Credit Memo.
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);
        Commit();

        // [WHEN] Send the same document again. Reply No to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(false);
        asserterror ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [THEN] Confirm with question "Credit Memo SCM has already been sent ... Do you want to send it again?" was shown.
        // [THEN] Sending process was interrupted with Error('').
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::"Credit Memo", SalesHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        // [THEN] Handled IC Outbox contains only one record for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Sales Document", ICTransactionDocType::"Credit Memo", SalesHeader."No.", ICPartnerCode, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTheSendICDocumentWorkCorrectlyForSalesReturnOrder()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICSetup: Record "IC Setup";
        SalesHeader: Record "Sales Header";
        ICPartner: Record "IC Partner";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 366071] Create Sales Return Order and send as IC Document
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Auto Send Transactions was enabled
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] IC Parthner with Vendor No.
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Sales Return Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesHeader.Validate("Sell-to IC Partner Code", ICPartnerCode);
        SalesHeader.Validate("Send IC Document", true);
        SalesHeader.Modify(true);

        // [GIVEN] Set IC Parthner Code for created Customer
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);

        // [WHEN] Sent Intercompany Sales Return Order
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [THEN] Outbox transaction created by posting is Handled by auto send
        HandledICOutboxTrans.SetRange("Document Type", HandledICOutboxTrans."Document Type"::"Return Order");
        HandledICOutboxTrans.SetRange("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Sales Document");
        HandledICOutboxTrans.SetRange("Document No.", SalesHeader."No.");
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTrans.FindFirst();
        Assert.RecordCount(HandledICOutboxTrans, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendSalesReturnOrderMoreThanOnceConfirmNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 403295] Create Sales Return Order and send as IC Document, then send the same document again. Reply No to confirm question.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Return Order "SRO" for Customer with IC Partner.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::"Return Order", ICPartnerCode);

        // [GIVEN] Sent Intercompany Sales Return Order.
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);
        Commit();

        // [WHEN] Send the same document again. Reply No to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(false);
        asserterror ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [THEN] Confirm with question "Return Order SRO has already been sent ... Do you want to send it again?" was shown.
        // [THEN] Sending process was interrupted with Error('').
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::"Return Order", SalesHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        // [THEN] Handled IC Outbox contains only one record for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Sales Document", ICTransactionDocType::"Return Order", SalesHeader."No.", ICPartnerCode, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateOutboxSalesDocTransCopiesICItemReferenceNo()
    var
        Customer: Record Customer;
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
        ReferenceNo: Code[50];
    begin
        // [FEATURE] [Item Reference] [UT]
        // [SCENARIO 390071] ICInboxOutboxMgt CreateOutboxSalesDocTrans transfers IC Item Reference No from lines to IC lines
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Created Sales Order ready for IC sending
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesHeader.Validate("Sell-to IC Partner Code", ICPartnerCode);
        SalesHeader.Validate("Send IC Document", true);
        SalesHeader.Modify(true);

        // [GIVEN] Set IC Partner Code for created Customer
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);

        // [GIVEN] Sales Item line has Item Refence No = X
        ReferenceNo := CreateItemReference(SalesLine."No.", '', "Item Reference Type"::Customer, SalesHeader."Sell-to Customer No.", LibraryUtility.GenerateGUID());
        SalesLine.Validate("Item Reference No.", ReferenceNo);
        SalesLine.Modify();

        // [WHEN] CreateOutboxSalesDocTrans is called on header
        ICInboxOutboxMgt.CreateOutboxSalesDocTrans(SalesHeader, false, false);

        // [THEN] IC Outbox Sales Line has "IC Item Reference No." = 'X'
        ICOutboxSalesLine.SetRange("IC Partner Code", ICPartnerCode);
        ICOutboxSalesLine.FindFirst();
        ICOutboxSalesLine.TestField("IC Item Reference No.", SalesLine."Item Reference No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateOutboxPurchDocTransCopiesICItemReferenceNo()
    var
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
        ReferenceNo: Code[50];
    begin
        // [FEATURE] [Item Reference] [UT]
        // [SCENARIO 390071] ICInboxOutboxMgt CreateOutboxPurchDocTrans transfers IC Item Reference No from lines to IC lines
        Initialize();

        // [GIVEN] An IC Partner
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Created Purchase Order ready for IC sending
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseHeader.Validate("Buy-from IC Partner Code", ICPartnerCode);
        PurchaseHeader.Validate("Send IC Document", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Set IC Partner Code for created Vendor
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.Validate("IC Partner Code", ICPartnerCode);
        Vendor.Modify(true);

        // [GIVEN] Sales Item line has "Item Refence No."" = 'X'
        ReferenceNo := CreateItemReference(PurchaseLine."No.", '', "Item Reference Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", LibraryUtility.GenerateGUID());
        PurchaseLine.Validate("Item Reference No.", ReferenceNo);
        PurchaseLine.Modify();

        // [WHEN] CreateOutboxPurchDocTrans is called on header
        ICInboxOutboxMgt.CreateOutboxPurchDocTrans(PurchaseHeader, false, false);

        // [THEN] IC Outbox Purchase Line has "IC Item Reference No." = 'X'
        ICOutboxPurchaseLine.SetRange("IC Partner Code", ICPartnerCode);
        ICOutboxPurchaseLine.FindFirst();
        ICOutboxPurchaseLine.TestField("IC Item Reference No.", PurchaseLine."Item Reference No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendSalesOrderMoreThanOnceConfirmYes()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 403295] Create Sales Order and send as IC Document, then send the same document again. Reply Yes to confirm question.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Order "SO" for Customer with IC Partner.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::Order, ICPartnerCode);

        // [GIVEN] Sent Intercompany Sales Order.
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [WHEN] Send the same document again. Reply Yes to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(true);
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);

        // [THEN] Confirm with question "Order SO has already been sent ... Do you want to send it again?" was shown.
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::Order, SalesHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());

        // [THEN] Handled IC Outbox contains two records for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Sales Document", ICTransactionDocType::Order, SalesHeader."No.", ICPartnerCode, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendPurchaseOrderMoreThanOnceConfirmYes()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        PurchaseHeader: Record "Purchase Header";
        Customer: Record Customer;
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 403295] Create Purchase Order and send as IC Document, then send the same document again. Reply Yes to confirm question.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Purchase Order "PO" for Vendor with IC Partner.
        CreatePurchaseDocumentForICPartnerVendor(PurchaseHeader, PurchaseDocType::Order, ICPartnerCode, false, 0);

        // [GIVEN] Sent Intercompany Purchase Order.
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [WHEN] Send the same document again. Reply Yes to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(true);
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [THEN] Confirm with question "Order PO has already been sent ... Do you want to send it again?" was shown.
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::Order, PurchaseHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());

        // [THEN] Handled IC Outbox contains two records for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Purchase Document", ICTransactionDocType::Order, PurchaseHeader."No.", ICPartnerCode, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendPurchaseInvoiceFromICOutboxMoreThanOnceConfirmYes()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: array[2] of Record "IC Outbox Transaction";
        ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
        Customer: Record Customer;
        ICOutboxTransactions: TestPage "IC Outbox Transactions";
        ICPartnerCode: Code[20];
        DocumentNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 403295] Send Purchase Invoice twice as IC Document with Auto Send Transactions disabled, then send this invoice twice from IC Outbox. Reply Yes to confirm question.
        Initialize();
        ICOutboxTransaction[1].DeleteAll();

        // [GIVEN] Auto Send Transactions is disabled.
        UpdateAutoSendTransactionsOnCompanyInfo(false);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Two transactions in IC Outbox for the same Purchase Invoice "PI".
        DocumentNo := LibraryUtility.GenerateGUID();
        VendorNo := LibraryPurchase.CreateVendorNo();
        MockICOutboxTransaction(ICOutboxTransaction[1], ICPartnerCode, ICOutboxTransaction[1]."IC Source Type"::"Purchase Document", ICTransactionDocType::Invoice, DocumentNo);
        MockICOutboxPurchaseDocument(ICOutboxPurchaseHeader, ICOutboxTransaction[1], VendorNo, 10, 100);
        MockICOutboxTransaction(ICOutboxTransaction[2], ICPartnerCode, ICOutboxTransaction[2]."IC Source Type"::"Purchase Document", ICTransactionDocType::Invoice, DocumentNo);
        MockICOutboxPurchaseDocument(ICOutboxPurchaseHeader, ICOutboxTransaction[2], VendorNo, 10, 100);

        // [GIVEN] One of the transactions is sent.
        ICOutboxTransactions.OpenEdit();
        ICOutboxTransactions.Filter.SetFilter("Transaction No.", Format(ICOutboxTransaction[1]."Transaction No."));
        ICOutboxTransactions.SendToICPartner.Invoke();

        // [WHEN] Send the second transaction. Reply Yes to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(true);
        ICOutboxTransactions.Filter.SetFilter("Transaction No.", Format(ICOutboxTransaction[2]."Transaction No."));
        ICOutboxTransactions.SendToICPartner.Invoke();

        // [THEN] Confirm with question "Invoice PI has already been sent ... Do you want to send it again?" was shown.
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::Invoice, ICOutboxPurchaseHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());

        // [THEN] Handled IC Outbox contains two records for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Purchase Document", ICTransactionDocType::Invoice, ICOutboxPurchaseHeader."No.", ICPartnerCode, 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure SendPurchaseInvoiceFromICOutboxMoreThanOnceConfirmNo()
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICOutboxTransaction: array[2] of Record "IC Outbox Transaction";
        ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
        Customer: Record Customer;
        ICOutboxTransactions: TestPage "IC Outbox Transactions";
        ICPartnerCode: Code[20];
        DocumentNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 403295] Send Purchase Invoice twice as IC Document with Auto Send Transactions disabled, then send this invoice twice from IC Outbox. Reply No to confirm question.
        Initialize();
        ICOutboxTransaction[1].DeleteAll();

        // [GIVEN] Auto Send Transactions is disabled.
        UpdateAutoSendTransactionsOnCompanyInfo(false);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Two transactions in IC Outbox for the same Purchase Invoice "PI".
        DocumentNo := LibraryUtility.GenerateGUID();
        VendorNo := LibraryPurchase.CreateVendorNo();
        MockICOutboxTransaction(ICOutboxTransaction[1], ICPartnerCode, ICOutboxTransaction[1]."IC Source Type"::"Purchase Document", ICTransactionDocType::Invoice, DocumentNo);
        MockICOutboxPurchaseDocument(ICOutboxPurchaseHeader, ICOutboxTransaction[1], VendorNo, 10, 100);
        MockICOutboxTransaction(ICOutboxTransaction[2], ICPartnerCode, ICOutboxTransaction[2]."IC Source Type"::"Purchase Document", ICTransactionDocType::Invoice, DocumentNo);
        MockICOutboxPurchaseDocument(ICOutboxPurchaseHeader, ICOutboxTransaction[2], VendorNo, 10, 100);

        // [GIVEN] One of the transactions is sent.
        ICOutboxTransactions.OpenEdit();
        ICOutboxTransactions.Filter.SetFilter("Transaction No.", Format(ICOutboxTransaction[1]."Transaction No."));
        ICOutboxTransactions.SendToICPartner.Invoke();
        Commit();

        // [WHEN] Send the second transaction. Reply No to confirm question "Do you want to send it again?".
        LibraryVariableStorage.Enqueue(false);
        ICOutboxTransactions.Filter.SetFilter("Transaction No.", Format(ICOutboxTransaction[2]."Transaction No."));
        ICOutboxTransactions.SendToICPartner.Invoke();

        // [THEN] Confirm with question "Invoice PI has already been sent ... Do you want to send it again?" was shown.
        Assert.ExpectedConfirm(
            StrSubstNo(SendAgainQst, ICTransactionDocType::Invoice, ICOutboxPurchaseHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        // [THEN] Handled IC Outbox contains one record for this document.
        VerifyHandledICOutboxTransCount(
            HandledICOutboxTrans."IC Source Type"::"Purchase Document", ICTransactionDocType::Invoice, ICOutboxPurchaseHeader."No.", ICPartnerCode, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure AcceptSalesInvoiceFromICInboxMoreThanOnceConfirmYes()
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        ICInboxTransaction: array[2] of Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        Vendor: Record Vendor;
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        ICPartnerCode: Code[20];
        DocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 403295] Receive Sales Invoice twice as IC Document, then accept this invoice twice from IC Inbox. Reply Yes to confirm question.
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        ICInboxTransaction[1].DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Two transactions in IC Inbox for the same Sales Invoice "SI".
        DocumentNo := LibraryUtility.GenerateGUID();
        CustomerNo := LibrarySales.CreateCustomerNo();
        MockICInboxTransaction(ICInboxTransaction[1], ICPartnerCode, ICInboxTransaction[1]."IC Source Type"::"Sales Document", ICTransactionDocType::Invoice, DocumentNo);
        MockICInboxSalesDocument(ICInboxSalesHeader, ICInboxTransaction[1], CustomerNo, 10, 100);
        MockICInboxTransaction(ICInboxTransaction[2], ICPartnerCode, ICInboxTransaction[2]."IC Source Type"::"Sales Document", ICTransactionDocType::Invoice, DocumentNo);
        MockICInboxSalesDocument(ICInboxSalesHeader, ICInboxTransaction[2], CustomerNo, 10, 100);

        // [GIVEN] One of the transactions is accepted.
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction[1]."Transaction No."));
        ICInboxTransactions.Accept.Invoke();

        // [WHEN] Accept the second transaction. Reply Yes to confirm question "Do you want to accept the Invoice?".
        LibraryVariableStorage.Enqueue(true);
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction[2]."Transaction No."));
        ICInboxTransactions.Accept.Invoke();

        // [THEN] Confirm with question "Invoice SI has already been received ... Do you want to accept the Invoice?" was shown.
        Assert.ExpectedConfirm(
            StrSubstNo(AcceptAgainQst, ICTransactionDocType::Invoice, ICInboxSalesHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());

        // [THEN] Handled IC Inbox contains two records for this document.
        VerifyHandledICInboxTransCount(
            HandledICInboxTrans."IC Source Type"::"Sales Document", ICTransactionDocType::Invoice, ICInboxSalesHeader."No.", ICPartnerCode, 2);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerEnqueueQuestion')]
    procedure AcceptSalesInvoiceFromICInboxMoreThanOnceConfirmNo()
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        ICInboxTransaction: array[2] of Record "IC Inbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        Vendor: Record Vendor;
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        ICPartnerCode: Code[20];
        DocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 403295] Receive Sales Invoice twice as IC Document, then accept this invoice twice from IC Inbox. Reply No to confirm question.
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        ICInboxTransaction[1].DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Two transactions in IC Inbox for the same Sales Invoice "SI".
        DocumentNo := LibraryUtility.GenerateGUID();
        CustomerNo := LibrarySales.CreateCustomerNo();
        MockICInboxTransaction(ICInboxTransaction[1], ICPartnerCode, ICInboxTransaction[1]."IC Source Type"::"Sales Document", ICTransactionDocType::Invoice, DocumentNo);
        MockICInboxSalesDocument(ICInboxSalesHeader, ICInboxTransaction[1], CustomerNo, 10, 100);
        MockICInboxTransaction(ICInboxTransaction[2], ICPartnerCode, ICInboxTransaction[2]."IC Source Type"::"Sales Document", ICTransactionDocType::Invoice, DocumentNo);
        MockICInboxSalesDocument(ICInboxSalesHeader, ICInboxTransaction[2], CustomerNo, 10, 100);

        // [GIVEN] One of the transactions is accepted.
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction[1]."Transaction No."));
        ICInboxTransactions.Accept.Invoke();
        Commit();

        // [WHEN] Accept the second transaction. Reply No to confirm question "Do you want to accept the Invoice?".
        LibraryVariableStorage.Enqueue(false);
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction[2]."Transaction No."));
        ICInboxTransactions.Accept.Invoke();

        // [THEN] Confirm with question "Invoice SI has already been received ... Do you want to accept the Invoice?" was shown.
        Assert.ExpectedConfirm(
            StrSubstNo(AcceptAgainQst, ICTransactionDocType::Invoice, ICInboxSalesHeader."No.", ICPartnerCode), LibraryVariableStorage.DequeueText());
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('');

        // [THEN] Handled IC Inbox contains one record for this document.
        VerifyHandledICInboxTransCount(
            HandledICInboxTrans."IC Source Type"::"Sales Document", ICTransactionDocType::Invoice, ICInboxSalesHeader."No.", ICPartnerCode, 1);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPostAutoSendTransactionSkipSendOnError()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICSetup: Record "IC Setup";
        SalesHeader: Record "Sales Header";
        ICPartner: Record "IC Partner";
        Customer: Record Customer;
        InventorySetup: Record "Inventory Setup";
        ERMIntercompanyIII: Codeunit "ERM Intercompany III";
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 407832] Auto. Send Transaction should not send IC doc ignoring error
        Initialize();

        // [GIVEN] An IC Partner Code
        ICPartnerCode := CreateICPartnerWithInbox();

        // [GIVEN] Auto Send Transactions was enabled
        ICSetup.Get();
        ICSetup."Auto. Send Transactions" := true;
        ICSetup."IC Partner Code" := ICPartnerCode;
        ICSetup.Modify();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Inventory Setup with Prevent Negative Inventory = true
        InventorySetup.Get();
        InventorySetup.Validate("Prevent Negative Inventory", true);
        InventorySetup.Modify();

        // [GIVEN] IC Partner with Vendor No.
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        ICPartner.Modify(true);

        // [GIVEN] Created Sales Order
        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Validate("Sell-to IC Partner Code", ICPartnerCode);
        SalesHeader.Validate("Send IC Document", true);
        SalesHeader.Modify(true);

        // [GIVEN] Set IC Partner Code for created Customer
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);

        // [WHEN] Post Sales Order with Ship = true, Post = false.
        BindSubscription(ERMIntercompanyIII);
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Error message appears about insufficient quantity
        // event OnBeforeSendICDocument should not be called
        Assert.ExpectedError(InsufficientQtyErr);
        UnbindSubscription(ERMIntercompanyIII);
    end;

    [Test]
    procedure PostSalesOrderWhenQtyToShipZero()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 403295] Post Sales Order for IC Customer when Qty to Ship = Qty to Invoice = 0 for some lines.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Order "SO" with two lines for Customer with IC Partner.
        // [GIVEN] Qty to Ship/Invoice = Quantity = 10 for Sales Line "SL1".
        // [GIVEN] Qty to Ship/Invoice = 0 and Quantity = 30 for Sales Line "SL2".
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::Order, ICPartnerCode);
        LibrarySales.FindFirstSalesLine(SalesLine[1], SalesHeader);
        LibrarySales.CreateSalesLine(
            SalesLine[2], SalesHeader, SalesLine[2].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(30, 40, 2));
        UpdateQtyToShipOnSalesLine(SalesLine[2]."Document Type", SalesLine[2]."Document No.", SalesLine[2]."Line No.", 0);

        // [WHEN] Post Sales Order with Ship and Invoice options.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Transaction for Sales Order is created in IC Outbox. It has two lines with Quantity 10 and 30 respectively.
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document",
            ICTransactionDocType::Order, SalesHeader."No.", ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);
        VerifyICOutboxSalesLineCount(ICOutboxTransaction, 2);
        VerifyICOutboxSalesLineQty(ICOutboxTransaction, ICPartnerRefType::Item, SalesLine[1]."No.", SalesLine[1].Quantity);
        VerifyICOutboxSalesLineQty(ICOutboxTransaction, ICPartnerRefType::Item, SalesLine[2]."No.", SalesLine[2].Quantity);

        // [THEN] Transaction for Sales Invoice is created in IC Outbox. It has one line for "SL1" with Quantity = 10.
        PostedInvoiceNo := FindLastSalesInvoiceHeaderNo(SalesHeader."No.");
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document",
            ICTransactionDocType::Invoice, PostedInvoiceNo, ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);
        VerifyICOutboxSalesLineCount(ICOutboxTransaction, 1);
        VerifyICOutboxSalesLineQty(ICOutboxTransaction, ICPartnerRefType::Item, SalesLine[1]."No.", SalesLine[1].Quantity);

        // [WHEN] Set Qty to Ship/Invoice = 30 for "SL2" and post Sales Order again with Ship and Invoice options.
        UpdateQtyToShipOnSalesLine(SalesLine[2]."Document Type", SalesLine[2]."Document No.", SalesLine[2]."Line No.", SalesLine[2].Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Transaction for Sales Invoice is created in IC Outbox. It has one line for "SL2" with Quantity = 30.
        PostedInvoiceNo := FindLastSalesInvoiceHeaderNo(SalesHeader."No.");
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document",
            ICTransactionDocType::Invoice, PostedInvoiceNo, ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);
        VerifyICOutboxSalesLineCount(ICOutboxTransaction, 1);
        VerifyICOutboxSalesLineQty(ICOutboxTransaction, ICPartnerRefType::Item, SalesLine[2]."No.", SalesLine[2].Quantity);
    end;

    [Test]
    procedure PostSalesReturnOrderWhenQtyToReceiveZero()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 403295] Post Sales Return Order for IC Customer when Return Qty to Receive = Qty to Invoice = 0 for some lines.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Return Order "SRO" with two lines for Customer with IC Partner.
        // [GIVEN] Qty to Receive/Invoice = Quantity = 10 for Sales Line "SL1".
        // [GIVEN] Qty to Receive/Invoice = 0 and Quantity = 30 for Sales Line "SL2".
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::"Return Order", ICPartnerCode);
        LibrarySales.FindFirstSalesLine(SalesLine[1], SalesHeader);
        LibrarySales.CreateSalesLine(
            SalesLine[2], SalesHeader, SalesLine[2].Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(30, 40, 2));
        UpdateReturnQtyToReceiveOnSalesLine(SalesLine[2]."Document Type", SalesLine[2]."Document No.", SalesLine[2]."Line No.", 0);

        // [WHEN] Post Sales Return Order with Receive and Invoice options.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Transaction for Sales Return Order is created in IC Outbox. It has two lines with Quantity 10 and 30 respectively.
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document",
            ICTransactionDocType::"Return Order", SalesHeader."No.", ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);
        VerifyICOutboxSalesLineCount(ICOutboxTransaction, 2);
        VerifyICOutboxSalesLineQty(ICOutboxTransaction, ICPartnerRefType::Item, SalesLine[1]."No.", SalesLine[1].Quantity);
        VerifyICOutboxSalesLineQty(ICOutboxTransaction, ICPartnerRefType::Item, SalesLine[2]."No.", SalesLine[2].Quantity);

        // [THEN] Transaction for Sales Credit Memo is created in IC Outbox. It has one line for "SL1" with Quantity = 10.
        PostedCrMemoNo := FindLastSalesCrMemoHeaderNo(SalesHeader."No.");
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document",
            ICTransactionDocType::"Credit Memo", PostedCrMemoNo, ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);
        VerifyICOutboxSalesLineCount(ICOutboxTransaction, 1);
        VerifyICOutboxSalesLineQty(ICOutboxTransaction, ICPartnerRefType::Item, SalesLine[1]."No.", SalesLine[1].Quantity);

        // [WHEN] Set Qty to Receive/Invoice = 30 for "SL2" and post Sales Order again with Receive and Invoice options.
        UpdateReturnQtyToReceiveOnSalesLine(SalesLine[2]."Document Type", SalesLine[2]."Document No.", SalesLine[2]."Line No.", SalesLine[2].Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Transaction for Sales Credit Memo is created in IC Outbox. It has one line for "SL2" with Quantity = 30.
        PostedCrMemoNo := FindLastSalesCrMemoHeaderNo(SalesHeader."No.");
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document",
            ICTransactionDocType::"Credit Memo", PostedCrMemoNo, ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);
        VerifyICOutboxSalesLineCount(ICOutboxTransaction, 1);
        VerifyICOutboxSalesLineQty(ICOutboxTransaction, ICPartnerRefType::Item, SalesLine[2]."No.", SalesLine[2].Quantity);
    end;

    [Test]
    procedure PostSalesOrderWhenICDirectionIncoming()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 409079] Post Sales Order for IC Customer when IC Direction = Incoming.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Order for Customer with IC Partner. IC Direction = Incoming.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::Order, ICPartnerCode);
        UpdateICDirectionOnSalesHeader(SalesHeader, SalesHeader."IC Direction"::Incoming);
        SalesHeader.TestField("Sell-to IC Partner Code");
        SalesHeader.TestField("Bill-to IC Partner Code");

        // [WHEN] Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Transaction for Sales Order is not created in IC Outbox.
        Assert.RecordIsEmpty(ICOutboxTransaction);
    end;

    [Test]
    procedure PostSalesOrderWhenICDirectionOutgoing()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 409079] Post Sales Order for IC Customer when IC Direction = Outgoing.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Order for Customer with IC Partner. IC Direction = Outgoing.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::Order, ICPartnerCode);
        UpdateICDirectionOnSalesHeader(SalesHeader, SalesHeader."IC Direction"::Outgoing);
        SalesHeader.TestField("Sell-to IC Partner Code");
        SalesHeader.TestField("Bill-to IC Partner Code");

        // [WHEN] Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Transaction for Sales Order is created in IC Outbox.
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document",
            ICTransactionDocType::Order, SalesHeader."No.", ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);

        // [THEN] Transaction for Sales Invoice is created in IC Outbox.
        PostedInvoiceNo := FindLastSalesInvoiceHeaderNo(SalesHeader."No.");
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document",
            ICTransactionDocType::Invoice, PostedInvoiceNo, ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure PostSalesOrderWhenBillToICPartnerEmpty()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 409079] Post Sales Order for IC Customer when "Bill-to IC Partner Code" = ''.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Order for Customer with IC Partner. Bill-to Customer No. is set to another Customer without IC Partner.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::Order, ICPartnerCode);
        UpdateBillToCustomerNoOnSalesHeader(SalesHeader, LibrarySales.CreateCustomerNo());
        SalesHeader.TestField("Sell-to IC Partner Code");
        SalesHeader.TestField("Bill-to IC Partner Code", '');

        // [WHEN] Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Transaction for Sales Order is not created in IC Outbox.
        Assert.RecordIsEmpty(ICOutboxTransaction);
    end;

    [Test]
    procedure PostSalesReturnOrderWhenICDirectionIncoming()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 409079] Post Sales Return Order for IC Customer when IC Direction = Incoming.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Return Order for Customer with IC Partner. IC Direction = Incoming.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::"Return Order", ICPartnerCode);
        UpdateICDirectionOnSalesHeader(SalesHeader, SalesHeader."IC Direction"::Incoming);
        SalesHeader.TestField("Sell-to IC Partner Code");
        SalesHeader.TestField("Bill-to IC Partner Code");

        // [WHEN] Post Sales Return Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Transaction for Sales Return Order is not created in IC Outbox.
        Assert.RecordIsEmpty(ICOutboxTransaction);
    end;

    [Test]
    procedure PostSalesReturnOrderWhenICDirectionOutgoing()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
        PostedCrMemoNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 409079] Post Sales Return Order for IC Customer when IC Direction = Outgoing.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Return Order for Customer with IC Partner. IC Direction = Outgoing.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::"Return Order", ICPartnerCode);
        UpdateICDirectionOnSalesHeader(SalesHeader, SalesHeader."IC Direction"::Outgoing);
        SalesHeader.TestField("Sell-to IC Partner Code");
        SalesHeader.TestField("Bill-to IC Partner Code");

        // [WHEN] Post Sales Return Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Transaction for Sales Return Order is created in IC Outbox.
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document",
            ICTransactionDocType::"Return Order", SalesHeader."No.", ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);

        // [THEN] Transaction for Sales Credit Memo is created in IC Outbox.
        PostedCrMemoNo := FindLastSalesCrMemoHeaderNo(SalesHeader."No.");
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document",
            ICTransactionDocType::"Credit Memo", PostedCrMemoNo, ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure PostSalesReturnOrderWhenBillToICPartnerEmpty()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        SalesHeader: Record "Sales Header";
        Vendor: Record Vendor;
        ICPartnerCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 409079] Post Sales Return Order for IC Customer when "Bill-to IC Partner Code" = ''.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Return Order for Customer with IC Partner. Bill-to Customer No. is set to another Customer without IC Partner.
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::"Return Order", ICPartnerCode);
        UpdateBillToCustomerNoOnSalesHeader(SalesHeader, LibrarySales.CreateCustomerNo());
        SalesHeader.TestField("Sell-to IC Partner Code");
        SalesHeader.TestField("Bill-to IC Partner Code", '');

        // [WHEN] Post Sales Return Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Transaction for Sales Return Order is not created in IC Outbox.
        Assert.RecordIsEmpty(ICOutboxTransaction);
    end;

    [Test]
    procedure CreateICSetupUI()
    var
        ICSetup: Record "IC Setup";
        IntercompanySetup: TestPage "Intercompany Setup";
    begin
        // [SCENARIO 290460] Create IC setup via "Intercompany Setup" page
        Initialize();

        // [GIVEN] IC setup does not exist
        if ICSetup.Get() then
            ICSetup.Delete();

        // [WHEN] Open "Intercompany Setup" page and fill "IC Partner Code" field
        IntercompanySetup.OpenEdit();
        IntercompanySetup."IC Partner Code".SetValue('abc');
        IntercompanySetup.Close();

        // [THEN] "IC Setup" record exists
        ICSetup.Get();
        // [THEN] "IC Partner Code" = 'abc'
        ICSetup.TestField("IC Partner Code", 'abc');
    end;

    [Test]
    procedure AutoAcceptICGenJnlTransactionUT()
    var
        ICSetup: Record "IC Setup";
        GenJournalLine: Record "Gen. Journal Line";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxJnlLine: Record "IC Inbox Jnl. Line";
        ICGLAccount: Record "IC G/L Account";
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 290460] Intercompany general journal line created when IC setup has filled in default intercompany template and batch
        Initialize();

        // [GIVEN] IC Setup with filled in default intercompany template and batch
        CreateICSetup(ICSetup);
        // [GIVEN] One dummy intercompany inbox transaction and journal line
        ICPartnerCode := LibraryERM.CreateICPartnerNo();
        CreateDummyCInboxTransaction(ICInboxTransaction, ICPartnerCode);
        CreateDummyICInboxJnlLine(ICInboxJnlLine, ICGLAccount, ICPartnerCode);

        // [WHEN] Run report "Complete IC Inbox Action"
        Report.Run(Report::"Complete IC Inbox Action", false, false, ICInboxTransaction);

        // [THEN] One general journal line is created
        GenJournalLine.SetRange("Journal Template Name", ICSetup."Default IC Gen. Jnl. Template");
        GenJournalLine.SetRange("Journal Batch Name", ICSetup."Default IC Gen. Jnl. Batch");
        Assert.RecordCount(GenJournalLine, 1);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Account No.", ICGLAccount."Map-to G/L Acc. No.");
    end;

    [Test]
    procedure SendRejectedICTransactionWhenAutoAcceptTransactionIsSet()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        Customer: Record Customer;
        PurchaseHeader: Record "Purchase Header";
        ScheduledTask: Record "Scheduled Task";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        ICOutboxTransactions: TestPage "IC Outbox Transactions";
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 413433] Send to IC Partner outbox transaction that is rejected by current company when Auto Accept Transactions is set on IC Partner.
        Initialize();
        ICOutboxTransaction.DeleteAll();
        ICInboxTransaction.DeleteAll();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Purchase Order "PO" for Vendor with IC Partner.
        CreatePurchaseDocumentForICPartnerVendor(PurchaseHeader, PurchaseDocType::Order, ICPartnerCode, false, 0);

        // [GIVEN] Sent Intercompany Purchase Order. IC Inbox Transaction "A" for Sales Order is created.
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [GIVEN] Open Intercompany Inbox Transactions page, Return to Partner IC transaction "A".
        // [GIVEN] IC Outbox Transaction "B" for Sales Order is created. Transaction Source is "Rejected by Current Company".
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("IC Partner Code", ICPartnerCode);
        ICInboxTransactions."Return to IC Partner".Invoke();
        Commit();

        // [GIVEN] Auto Accept Transactions is set for IC Partner.
        UpdateAutoAcceptTransOnICPartner(ICPartnerCode, true);

        // [GIVEN] Open Intercompany Outbox Transactions page, Send to IC Partner IC transaction "B".
        HandledICInboxTrans.DeleteAll();    // to prevent possible duplicates as transactions are sent within one company
        ICOutboxTransactions.OpenEdit();
        ICOutboxTransactions.Filter.SetFilter("IC Partner Code", ICPartnerCode);
        ICOutboxTransactions.SendToICPartner.Invoke();
        Commit();

        // [THEN] IC Inbox Transaction "C" for Purchase Order is created. Transaction Source is "Returned by Partner".
        ICInboxTransaction.SetRange("IC Partner Code", ICPartnerCode);
        ICInboxTransaction.FindFirst();
        ICInboxTransaction.TestField("Transaction Source", ICInboxTransaction."Transaction Source"::"Returned by Partner");
        ICInboxTransaction.TestField("IC Source Type", ICInboxTransaction."IC Source Type"::"Purchase Document");
        ICInboxTransaction.TestField("Document Type", "IC Transaction Document Type"::Order);

        // [THEN] Handled IC Inbox Transaction record is not created.
        HandledICInboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        Assert.RecordIsEmpty(HandledICInboxTrans);

        // [THEN] Scheduled task for accepting transaction "C" is not created.
        ScheduledTask.SetRange("Run Codeunit", Codeunit::"IC Inbox Outbox Subscribers");
        ScheduledTask.SetRange("Failure Codeunit", 0);
        ScheduledTask.SetRange("Is Ready", true);
        ScheduledTask.SetRange(Record, ICInboxTransaction.RecordId);
        Assert.RecordIsEmpty(ScheduledTask);

        // tear down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    procedure SendICTransactionWhenAutoAcceptTransactionIsSet()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        ICInboxTransaction: Record "IC Inbox Transaction";
        Customer: Record Customer;
        PurchaseHeader: Record "Purchase Header";
        JobQueueEntry: Record "Job Queue Entry";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 413433] Send to IC Partner outbox transaction that is created by current company when Auto Accept Transactions is set on IC Partner.
        Initialize();
        ICOutboxTransaction.DeleteAll();
        ICInboxTransaction.DeleteAll();
        LibraryApplicationArea.EnableEssentialSetup();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(false);

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        // [GIVEN] Auto Accept Transactions is set for IC Partner.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);
        UpdateAutoAcceptTransOnICPartner(ICPartnerCode, true);

        // [GIVEN] Purchase Order "PO" for Vendor with IC Partner.
        CreatePurchaseDocumentForICPartnerVendor(PurchaseHeader, PurchaseDocType::Order, ICPartnerCode, false, 0);

        // [WHEN] Send Intercompany Purchase Order.
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        Commit();

        // [THEN] IC Outbox Transaction "A" for Purchase Order is created. Transaction Source is "Created by Current Company".
        // [THEN] Transaction "A" is automatically sent and Handled IC Outbox Transaction "A" is created.
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTrans.FindFirst();
        HandledICOutboxTrans.TestField("Transaction Source", HandledICOutboxTrans."Transaction Source"::"Created by Current Company");
        HandledICOutboxTrans.TestField("IC Source Type", HandledICOutboxTrans."IC Source Type"::"Purchase Document");

        // [THEN] IC Inbox Transaction for Sales Order is created and then Scheduled Task for accepting it is created.
        ICInboxTransaction.SetRange("IC Partner Code", ICPartnerCode);
        ICInboxTransaction.FindFirst();
        ICInboxTransaction.TestField("Transaction Source", ICInboxTransaction."Transaction Source"::"Created by Partner");
        ICInboxTransaction.TestField("IC Source Type", ICInboxTransaction."IC Source Type"::"Sales Document");
        ICInboxTransaction.TestField("Document Type", "IC Transaction Document Type"::Order);

        // [THEN] We cannot check if Handled IC Indox Transaction is created, because it is created by Scheduled Task.
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"IC Inbox Outbox Subs. Runner");
        Assert.RecordCount(JobQueueEntry, 1);

        // tear down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewPageHandler')]
    procedure ICGenJnlPostingPreviewSkipFileCreation()
    var
        ICSetup: Record "IC Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ICGLAccount: Record "IC G/L Account";
        ICPartner: Record "IC Partner";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        // [SCENARIO 415998] Intercompany transaction .xml file should not be created when preview posting of intercompany general journal
        Initialize();

        // [GIVEN] IC Setup, "IC Inbox Type"::"File Location"
        // [GIVEN] IC Partner, "Inbox Type"::"File Location"
        CreateFileLocationICSetup(ICSetup);
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner.Validate("Inbox Type", ICPartner."Inbox Type"::"File Location");
        ICPartner.Validate("Inbox Details", ICSetup."IC Inbox Details");
        ICPartner.Modify(true);
        // [GIVEN] Intercompany general journal line
        LibraryERM.CreateICGLAccount(ICGLAccount);
        GenJournalBatch.Get(ICSetup."Default IC Gen. Jnl. Template", ICSetup."Default IC Gen. Jnl. Batch");
        CreateICGeneralJournalLine(
            GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine."Bal. Account Type"::"IC Partner", ICPartner.Code, ICGLAccount."No.", 100, LibraryUtility.GenerateGUID());
        GenJournalLine.SetRange("Journal Template Name", ICSetup."Default IC Gen. Jnl. Template");
        GenJournalLine.SetRange("Journal Batch Name", ICSetup."Default IC Gen. Jnl. Batch");
        GenJournalLine.FindFirst();
        Commit();

        // [WHEN] Preview posting of intercompany general journal
        asserterror GenJnlPost.Preview(GenJournalLine);

        // [THEN] Intercompany transaction file does not exist
        FileName := StrSubstNo('%1\%2_1.xml', ICPartner."Inbox Details", ICPartner.Code);
        Assert.IsFalse(FileManagement.ServerFileExists(FileName), 'IC transaction file should not exist on preview.');
    end;

    [Test]
    procedure Description2SetOnHandledICOutboxPurchaseLine()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        Customer: Record Customer;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 414124] Description 2 of Handled IC Outbox Purchase Line after sending Purchase Order with Description 2 of Purchase Line set.
        Initialize();
        ICOutboxTransaction.DeleteAll();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Purchase Order "PO" with one Purchase Line for Vendor with IC Partner.
        // [GIVEN] Purchase Line has "Description 2" = "A".
        CreatePurchaseDocumentForICPartnerVendor(PurchaseHeader, PurchaseDocType::Order, ICPartnerCode, false, 0);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        UpdateDescription2OnPurchaseLine(PurchaseLine, LibraryUtility.GenerateGUID());

        // [WHEN] Send Intercompany Purchase Order.
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        Commit();

        // [THEN] Transaction for Purchase Order is created in Handled IC Outbox. It has one line with Description 2 = "A".
        FindHandledICOutboxTransaction(
            HandledICOutboxTrans, HandledICOutboxTrans."IC Source Type"::"Purchase Document",
            ICTransactionDocType::Order, PurchaseHeader."No.", ICPartnerCode);
        VerifyHandledICOutboxPurchLineDescription2(HandledICOutboxTrans, ICPartnerRefType::Item, PurchaseLine."No.", PurchaseLine."Description 2");

        // tear down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    procedure Description2BlankOnHandledICOutboxPurchaseLine()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        Customer: Record Customer;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 414124] Description 2 of Handled IC Outbox Purchase Line after sending Purchase Order with blank Description 2 of Purchase Line.
        Initialize();
        ICOutboxTransaction.DeleteAll();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Purchase Order "PO" with one Purchase Line for Vendor with IC Partner.
        // [GIVEN] Purchase Line has blank "Description 2".
        CreatePurchaseDocumentForICPartnerVendor(PurchaseHeader, PurchaseDocType::Order, ICPartnerCode, false, 0);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        UpdateDescription2OnPurchaseLine(PurchaseLine, '');

        // [WHEN] Send Intercompany Purchase Order.
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        Commit();

        // [THEN] Transaction for Purchase Order is created in Handled IC Outbox. It has one line with blank Description 2.
        FindHandledICOutboxTransaction(
            HandledICOutboxTrans, HandledICOutboxTrans."IC Source Type"::"Purchase Document",
            ICTransactionDocType::Order, PurchaseHeader."No.", ICPartnerCode);
        VerifyHandledICOutboxPurchLineDescription2(HandledICOutboxTrans, ICPartnerRefType::Item, PurchaseLine."No.", '');

        // tear down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    procedure Description2SetOnHandledICOutboxSalesLine()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 414124] Description 2 of Handled IC Outbox Sales Line after sending Sales Order with Description 2 of Sales Line set.
        Initialize();
        ICOutboxTransaction.DeleteAll();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Order "SO" with one Sales Line for Customer with IC Partner.
        // [GIVEN] Sales Line has "Description 2" = "A".
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::Order, ICPartnerCode);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        UpdateDescription2OnSalesLine(SalesLine, LibraryUtility.GenerateGUID());

        // [WHEN] Send Intercompany Sales Order.
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);
        Commit();

        // [THEN] Transaction for Sales Order is created in Handled IC Outbox. It has one line with Description 2 = "A".
        FindHandledICOutboxTransaction(
            HandledICOutboxTrans, HandledICOutboxTrans."IC Source Type"::"Sales Document",
            ICTransactionDocType::Order, SalesHeader."No.", ICPartnerCode);
        VerifyHandledICOutboxSalesLineDescription2(HandledICOutboxTrans, ICPartnerRefType::Item, SalesLine."No.", SalesLine."Description 2");

        // tear down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    procedure Description2BlankOnHandledICOutboxSalesLine()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        Vendor: Record Vendor;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 414124] Description 2 of Handled IC Outbox Sales Line after sending Sales Order with blank Description 2 of Sales Line.
        Initialize();
        ICOutboxTransaction.DeleteAll();
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] Auto Send Transactions is enabled.
        UpdateAutoSendTransactionsOnCompanyInfo(true);

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Order "SO" with one Sales Line for Customer with IC Partner.
        // [GIVEN] Sales Line has blank "Description 2".
        CreateSalesDocumentForICPartnerCustomer(SalesHeader, SalesDocType::Order, ICPartnerCode);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        UpdateDescription2OnSalesLine(SalesLine, '');

        // [WHEN] Send Intercompany Sales Order.
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);
        Commit();

        // [THEN] Transaction for Sales Order is created in Handled IC Outbox. It has one line with blank Description 2.
        FindHandledICOutboxTransaction(
            HandledICOutboxTrans, HandledICOutboxTrans."IC Source Type"::"Sales Document",
            ICTransactionDocType::Order, SalesHeader."No.", ICPartnerCode);
        VerifyHandledICOutboxSalesLineDescription2(HandledICOutboxTrans, ICPartnerRefType::Item, SalesLine."No.", '');

        // tear down
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    procedure ICSalesLineCommentTypeWhenPostSalesInvoice()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        Description: array[3] of Text[100];
        ICPartnerCode: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 422513] IC Sales Lines with Type Comment (blank) when post Sales Invoice for IC Customer.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Invoice with three lines for Customer with IC Partner.
        // [GIVEN] First and third Sales Lines have Type " " and Description "D1" / "D2" (Quantity = 0).
        // [GIVEN] Second Sales Line has Type "Item" and Quantity 10.
        LibraryInventory.CreateItem(Item);
        Description[1] := LibraryUtility.GenerateGUID();
        Description[2] := Item.Description;
        Description[3] := LibraryUtility.GenerateGUID();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocType::Invoice, Customer."No.");
        CreateSalesLineCommentType(SalesLine[1], SalesHeader, Description[1]);
        CreateSalesLineItemType(SalesLine[2], SalesHeader, Item."No.");
        CreateSalesLineCommentType(SalesLine[3], SalesHeader, Description[3]);

        // [WHEN] Post Sales Invoice.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Transaction for Sales Invoice is created in IC Outbox. It has three lines - first and third with blank Type, second with Item Type.
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document", ICTransactionDocType::Invoice, PostedInvoiceNo, ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);
        VerifyICOutboxSalesLineCount(ICOutboxTransaction, 3);
        VerifyICOutboxSalesLineTypeAndNoByLineNo(ICOutboxTransaction, SalesLine[1]."Line No.", ICPartnerRefType::" ", '', Description[1]);
        VerifyICOutboxSalesLineTypeAndNoByLineNo(ICOutboxTransaction, SalesLine[2]."Line No.", ICPartnerRefType::Item, Item."No.", Description[2]);
        VerifyICOutboxSalesLineTypeAndNoByLineNo(ICOutboxTransaction, SalesLine[3]."Line No.", ICPartnerRefType::" ", '', Description[3]);
    end;

    [Test]
    procedure ICSalesLineCommentTypeWhenPostSalesCreditMemo()
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        Description: array[3] of Text[100];
        ICPartnerCode: Code[20];
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 422513] IC Sales Lines with Type Comment (blank) when post Sales Credit Memo for IC Customer.
        Initialize();
        ICOutboxTransaction.DeleteAll();

        // [GIVEN] Vendor with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Sales Credit Memo with three lines for Customer with IC Partner.
        // [GIVEN] First and third Sales Lines have Type " " and Description "D1" / "D2" (Quantity = 0).
        // [GIVEN] Second Sales Line has Type "Item" and Quantity 10.
        LibraryInventory.CreateItem(Item);
        Description[1] := LibraryUtility.GenerateGUID();
        Description[2] := Item.Description;
        Description[3] := LibraryUtility.GenerateGUID();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocType::"Credit Memo", Customer."No.");
        CreateSalesLineCommentType(SalesLine[1], SalesHeader, Description[1]);
        CreateSalesLineItemType(SalesLine[2], SalesHeader, Item."No.");
        CreateSalesLineCommentType(SalesLine[3], SalesHeader, Description[3]);

        // [WHEN] Post Sales Credit Memo.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Transaction for Sales Credit Memo is created in IC Outbox. It has three lines - first and third with blank Type, second with Item Type.
        FindICOutboxTransaction(
            ICOutboxTransaction, ICOutboxTransaction."IC Source Type"::"Sales Document", ICTransactionDocType::"Credit Memo", PostedInvoiceNo, ICPartnerCode);
        Assert.RecordIsNotEmpty(ICOutboxTransaction);
        VerifyICOutboxSalesLineCount(ICOutboxTransaction, 3);
        VerifyICOutboxSalesLineTypeAndNoByLineNo(ICOutboxTransaction, SalesLine[1]."Line No.", ICPartnerRefType::" ", '', Description[1]);
        VerifyICOutboxSalesLineTypeAndNoByLineNo(ICOutboxTransaction, SalesLine[2]."Line No.", ICPartnerRefType::Item, Item."No.", Description[2]);
        VerifyICOutboxSalesLineTypeAndNoByLineNo(ICOutboxTransaction, SalesLine[3]."Line No.", ICPartnerRefType::" ", '', Description[3]);
    end;

    [Test]
    procedure ICNavigateFromIncomingSalesOrderLine()
    var
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        ICInboxTransaction: Record "IC Inbox Transaction";
        Customer: Record Customer;
        HandledICInboxTransactions: TestPage "Handled IC Inbox Transactions";
        SalesOrder: TestPage "Sales Order";
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        TransactionSource: Option "Returned by Partner","Created by Partner";
        DocumentNo: Code[20];
        ICPartnerCode: Code[20];
        TransactionNo: Integer;
    begin
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        CleanupIC(true, false, true, false);
        CreateCustomerWithICPartner(Customer);
        ICPartnerCode := Customer."IC Partner Code";

        // [GIVEN] A sales order received on IC Inbox.
        DocumentNo := LibraryUtility.GenerateGUID();
        MockICInboxTransaction(ICInboxTransaction, ICPartnerCode, ICInboxTransaction."IC Source Type"::"Sales Document", ICInboxTransaction."Document Type"::Order, DocumentNo);
        MockICInboxSalesDocument(ICInboxSalesHeader, ICInboxTransaction, Customer."No.", 10, 100);
        GetICTransactionKeyValues(ICInboxTransaction, TransactionNo, ICPartnerCode, TransactionSource);
        // [GIVEN] The Sales Order was accepted
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction."Transaction No."));
        ICInboxTransactions.Accept.Invoke();
        Commit();
        // [WHEN] Navigating from HandledInbox for this transaction
        HandledICInboxTrans.Get(TransactionNo, ICPartnerCode, TransactionSource, Enum::"IC Transaction Document Type"::Order);
        HandledICInboxTransactions.OpenEdit();
        HandledICInboxTransactions.GoToRecord(HandledICInboxTrans);
        SalesOrder.Trap();
        HandledICInboxTransactions.GoToDocument.Invoke();
        // [THEN] It should open the Sales Order
        SalesOrder."External Document No.".AssertEquals(ICInboxSalesHeader."No.");
        // Cleanup
        CleanupIC(true, false, true, false);
    end;

    [Test]
    procedure ICNavigateFromSalesInvoiceLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ICOutboxTransactions: TestPage "IC Outbox Transactions";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        DocumentNo: Code[20];
        ICPartnerCode: Code[20];
    begin
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        CleanupIC(false, true, true, false);
        CreateCustomerWithICPartner(Customer);
        ICPartnerCode := Customer."IC Partner Code";

        // [GIVEN] A posted sales invoice to an IC customer
        DocumentNo := LibraryUtility.GenerateGUID();
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [GIVEN] The posted sales invoice IC transaction should be on the Outbox
        ICOutboxTransactions.OpenEdit();
        // [WHEN] Navigating from Outbox for this transaction
        PostedSalesInvoice.Trap();
        ICOutboxTransactions.GoToDocument.Invoke();
        // [THEN] It should open the Posted Sales Invoice
        PostedSalesInvoice."Pre-Assigned No.".AssertEquals(SalesHeader."No.");

        // Cleanup
        CleanupIC(false, true, true, false);
    end;

    [Test]
    procedure ICNavigateFromOutgoingSalesOrderLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICOutboxTransactions: TestPage "IC Outbox Transactions";
        SalesOrder: TestPage "Sales Order";
        ICPartnerCode: Code[20];
    begin
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        CleanupIC(false, true, true, false);
        CreateCustomerWithICPartner(Customer);
        ICPartnerCode := Customer."IC Partner Code";
        // [GIVEN] A Sales Order sent to an IC Partner
        LibrarySales.CreateSalesOrderForCustomerNo(SalesHeader, Customer."No.");
        SalesHeader.SetHideValidationDialog(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        ICInboxOutboxMgt.SendSalesDoc(SalesHeader, false);
        // [WHEN] Running GotoDocument from IC Outbox
        ICOutboxTransactions.OpenEdit();
        SalesOrder.Trap();
        ICOutboxTransactions.GoToDocument.Invoke();
        // [THEN] The SalesOrder should open
        SalesOrder."No.".AssertEquals(SalesHeader."No.");
        CleanupIC(false, true, true, false);
    end;

    [Test]
    procedure ICNavigateFromIncomingPurchaseOrderLine()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        Vendor: Record Vendor;
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        HandledICInboxTransactions: TestPage "Handled IC Inbox Transactions";
        PurchaseOrder: TestPage "Purchase Order";
        TransactionSource: Option "Returned by Partner","Created by Partner";
        ICPartnerCode: Code[20];
        DocumentNo: Code[20];
        TransactionNo: Integer;
    begin
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        CleanupIC(true, false, false, true);
        CreateVendorWithICPartner(Vendor);
        ICPartnerCode := Vendor."IC Partner Code";
        // [GIVEN] A purchase order received as an IC transaction
        DocumentNo := LibraryUtility.GenerateGUID();
        MockICInboxTransaction(ICInboxTransaction, ICPartnerCode, ICInboxTransaction."IC Source Type"::"Purchase Document", ICInboxTransaction."Document Type"::Order, DocumentNo);
        MockICInboxPurchaseDocument(ICInboxPurchaseHeader, ICInboxTransaction, Vendor."No.", 100);
        GetICTransactionKeyValues(ICInboxTransaction, TransactionNo, ICPartnerCode, TransactionSource);
        // [GIVEN] the purchase order was accepted
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction."Transaction No."));
        ICInboxTransactions.Accept.Invoke();
        Commit();
        // [WHEN] Navigating from Handled Inbox to its related document
        HandledICInboxTrans.Get(TransactionNo, ICPartnerCode, TransactionSource, Enum::"IC Transaction Document Type"::Order);
        HandledICInboxTransactions.OpenEdit();
        HandledICInboxTransactions.GoToRecord(HandledICInboxTrans);
        PurchaseOrder.Trap();
        HandledICInboxTransactions.GoToDocument.Invoke();
        // [THEN] We should open the purchase order
        PurchaseOrder."Vendor Order No.".AssertEquals(ICInboxPurchaseHeader."No.");
        CleanupIC(true, false, false, true);
    end;

    [Test]
    procedure ICNavigateFromPurchaseInvoiceLine()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        Vendor: Record Vendor;
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        HandledICInboxTransactions: TestPage "Handled IC Inbox Transactions";
        PurchaseInvoice: TestPage "Purchase Invoice";
        TransactionSource: Option "Returned by Partner","Created by Partner";
        ICPartnerCode: Code[20];
        DocumentNo: Code[20];
        TransactionNo: Integer;
    begin
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        CleanupIC(true, false, false, true);
        CreateVendorWithICPartner(Vendor);
        ICPartnerCode := Vendor."IC Partner Code";

        // [GIVEN] A purchase invoice received as an IC transaction
        DocumentNo := LibraryUtility.GenerateGUID();
        MockICInboxTransaction(ICInboxTransaction, ICPartnerCode, ICInboxTransaction."IC Source Type"::"Purchase Document", ICInboxTransaction."Document Type"::Invoice, DocumentNo);
        MockICInboxPurchaseDocument(ICInboxPurchaseHeader, ICInboxTransaction, Vendor."No.", 100);
        GetICTransactionKeyValues(ICInboxTransaction, TransactionNo, ICPartnerCode, TransactionSource);
        // [GIVEN] the purchase invoice was accepted
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction."Transaction No."));
        ICInboxTransactions.Accept.Invoke();
        Commit();
        // [WHEN] Navigating from Handled Inbox to its related document
        HandledICInboxTrans.Get(TransactionNo, ICPartnerCode, TransactionSource, Enum::"IC Transaction Document Type"::Invoice);
        HandledICInboxTransactions.OpenEdit();
        HandledICInboxTransactions.GoToRecord(HandledICInboxTrans);
        PurchaseInvoice.Trap();
        HandledICInboxTransactions.GoToDocument.Invoke();

        // [THEN] We should open the purchase invoice
        PurchaseInvoice."Vendor Invoice No.".AssertEquals(ICInboxPurchaseHeader."No.");
        CleanupIC(true, false, false, true);
    end;

    [Test]
    procedure ICNavigateFromOutgoingPurchaseOrderLine()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICOutboxTransactions: TestPage "IC Outbox Transactions";
        PurchaseOrder: TestPage "Purchase Order";
        ICPartnerCode: Code[20];
    begin
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        CleanupIC(false, true, false, true);
        CreateVendorWithICPartner(Vendor);
        ICPartnerCode := Vendor."IC Partner Code";
        // [GIVEN] A Sales Order sent to an IC Partner
        LibraryPurchase.CreatePurchaseOrderForVendorNo(PurchaseHeader, Vendor."No.");
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);
        // [WHEN] Running GotoDocument from IC Outbox
        ICOutboxTransactions.OpenEdit();
        PurchaseOrder.Trap();
        ICOutboxTransactions.GoToDocument.Invoke();
        // [THEN] The SalesOrder should open
        PurchaseOrder."No.".AssertEquals(PurchaseHeader."No.");
        CleanupIC(false, true, false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure RejectICSalesOrder()
    var
        Customer: Record Customer;
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxTransaction: Record "IC Inbox Transaction";
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        DimensionValue: array[5] of Record "Dimension Value";
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        SalesOrderPage: TestPage "Sales Order";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] An IC inbox transaction of type sales order was accepted and created. It is then rejected by that company 
        Initialize();
        CleanupIC(true, true, false, false);
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] A customer configured as IC Partner
        CreateSetOfDimValues(DimensionValue);
        CustomerNo := CreateCustomerWithDefaultDimensions(DimensionValue);
        Customer.Get(CustomerNo);
        // [GIVEN] A sales order IC inbox transaction
        DocumentNo := LibraryUtility.GenerateGUID();
        MockICInboxSalesOrder(ICInboxSalesHeader, DimensionValue, CustomerNo);
        MockICInboxTransaction(ICInboxTransaction, Customer."IC Partner Code", ICInboxTransaction."IC Source Type"::"Sales Document", ICInboxTransaction."Document Type"::Order, DocumentNo);
        ICInboxSalesHeader."IC Transaction No." := ICInboxTransaction."Transaction No.";
        ICInboxSalesHeader.Modify();
        ICInboxSalesHeader.Rename(ICInboxSalesHeader."IC Transaction No.", ICInboxSalesHeader."IC Partner Code", ICInboxSalesHeader."Transaction Source"::"Created by Partner");
        // [GIVEN] The sales order was accepted and created
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction."Transaction No."));
        ICInboxTransactions.Accept.Invoke();

        // [WHEN] Running the action in the sales order page "Reject IC Order"
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();
        SalesOrderPage.OpenView();
        SalesOrderPage.GoToRecord(SalesHeader);
        SalesOrderPage."Reject IC Sales Order".Invoke();
        Commit();

        // [THEN] The Sales Order is removed
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Assert.IsTrue(SalesHeader.IsEmpty(), 'The sales order should be removed after rejection');
        // [THEN] An IC outbox rejection transaction is created
        ICOutboxTransaction.SetRange("Document No.", DocumentNo);
        ICOutboxTransaction.SetRange("Transaction Source", ICOutboxTransaction."Transaction Source"::"Rejected by Current Company");
        Assert.AreEqual(1, ICOutboxTransaction.Count(), 'There should be 1 rejection being created as an outbox transaction');

        CleanupIC(true, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure RejectICPurchaseOrder()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        PurchaseOrderPage: TestPage "Purchase Order";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] An IC inbox transaction of type purchase order was accepted and created. It is then rejected by that company 
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        CleanupIC(true, true, false, false);
        CreateVendorWithICPartner(Vendor);
        DocumentNo := LibraryUtility.GenerateGUID();
        // [GIVEN] A purchase order IC inbox transaction
        MockICInboxTransaction(ICInboxTransaction, Vendor."IC Partner Code", ICInboxTransaction."IC Source Type"::"Purchase Document", ICInboxTransaction."Document Type"::Order, DocumentNo);
        MockICInboxPurchaseDocument(ICInboxPurchaseHeader, ICInboxTransaction, Vendor."No.", 100);
        // [GIVEN] The purchase order was accepted and created
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction."Transaction No."));
        ICInboxTransactions.Accept.Invoke();
        Commit();

        // [WHEN] Running the action in the purchase order page "Reject IC Order"
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseOrderPage.OpenView();
        PurchaseOrderPage.GoToRecord(PurchaseHeader);
        PurchaseOrderPage."Reject IC Purchase Order".Invoke();
        Commit();

        // [THEN] The Purchase Order is removed
        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.IsTrue(PurchaseHeader.IsEmpty(), 'The purchase order should be removed after rejection');
        // [THEN] An IC outbox rejection transaction is created
        ICOutboxTransaction.SetRange("Document No.", DocumentNo);
        ICOutboxTransaction.SetRange("Transaction Source", ICOutboxTransaction."Transaction Source"::"Rejected by Current Company");
        Assert.AreEqual(1, ICOutboxTransaction.Count(), 'There should be 1 rejection being created as an outbox transaction');

        CleanupIC(true, true, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure RejectICSalesInvoice()
    var
        Customer: Record Customer;
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxTransaction: Record "IC Inbox Transaction";
        SalesHeader: Record "Sales Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        DimensionValue: array[5] of Record "Dimension Value";
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        SalesInvoicePage: TestPage "Sales Invoice";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO] An IC inbox transaction of type sales invoice was accepted and created. It is then rejected by that company 
        Initialize();
        CleanupIC(true, true, false, false);
        LibraryApplicationArea.EnableEssentialSetup();

        // [GIVEN] A customer configured as IC Partner
        CreateSetOfDimValues(DimensionValue);
        CustomerNo := CreateCustomerWithDefaultDimensions(DimensionValue);
        Customer.Get(CustomerNo);
        // [GIVEN] A sales invoice IC inbox transaction
        DocumentNo := LibraryUtility.GenerateGUID();
        MockICInboxTransaction(ICInboxTransaction, Customer."IC Partner Code", ICInboxTransaction."IC Source Type"::"Sales Document", ICInboxTransaction."Document Type"::Invoice, DocumentNo);
        MockICInboxSalesDocument(ICInboxSalesHeader, ICInboxTransaction, CustomerNo, 5, 300);
        // [GIVEN] The sales invoice was accepted and created
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction."Transaction No."));
        ICInboxTransactions.Accept.Invoke();

        // [WHEN] Running the action in the sales invoice page "Reject IC invoice"
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();
        SalesInvoicePage.OpenView();
        SalesInvoicePage.GoToRecord(SalesHeader);
        SalesInvoicePage."Reject IC Sales Invoice".Invoke();
        Commit();

        // [THEN] The Sales Invoice is removed
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Assert.IsTrue(SalesHeader.IsEmpty(), 'The sales invoice should be removed after rejection');
        // [THEN] An IC outbox rejection transaction is created
        ICOutboxTransaction.SetRange("Document No.", DocumentNo);
        ICOutboxTransaction.SetRange("Transaction Source", ICOutboxTransaction."Transaction Source"::"Rejected by Current Company");
        Assert.AreEqual(1, ICOutboxTransaction.Count(), 'There should be 1 rejection being created as an outbox transaction');

        CleanupIC(true, true, false, false);
    end;


    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure RejectICPurchaseInvoice()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] An IC inbox transaction of type purchase invoice was accepted and created. It is then rejected by that company 
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        CleanupIC(true, true, false, false);
        CreateVendorWithICPartner(Vendor);
        DocumentNo := LibraryUtility.GenerateGUID();
        // [GIVEN] A purchase invoice IC inbox transaction
        MockICInboxTransaction(ICInboxTransaction, Vendor."IC Partner Code", ICInboxTransaction."IC Source Type"::"Purchase Document", ICInboxTransaction."Document Type"::Invoice, DocumentNo);
        MockICInboxPurchaseDocument(ICInboxPurchaseHeader, ICInboxTransaction, Vendor."No.", 100);
        // [GIVEN] The purchase invoice was accepted and created
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("Transaction No.", Format(ICInboxTransaction."Transaction No."));
        ICInboxTransactions.Accept.Invoke();
        Commit();

        // [WHEN] Running the action in the purchase invoice page "Reject IC Invoice"
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();
        PurchaseInvoicePage.OpenView();
        PurchaseInvoicePage.GoToRecord(PurchaseHeader);
        PurchaseInvoicePage."Reject IC Purchase Invoice".Invoke();
        Commit();

        // [THEN] The Purchase Invoice is removed
        PurchaseHeader.Reset();
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::invoice);
        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        Assert.IsTrue(PurchaseHeader.IsEmpty(), 'The purchase invoice should be removed after rejection');
        // [THEN] An IC outbox rejection transaction is created
        ICOutboxTransaction.SetRange("Document No.", DocumentNo);
        ICOutboxTransaction.SetRange("Transaction Source", ICOutboxTransaction."Transaction Source"::"Rejected by Current Company");
        Assert.AreEqual(1, ICOutboxTransaction.Count(), 'There should be 1 rejection being created as an outbox transaction');

        CleanupIC(true, true, false, false);
    end;

    [Scope('OnPrem')]
    procedure VerifyICReferenceDocNoOnSalesHeader()
    var
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [SCENARIO 450015] Verify no Error message "The length of the string is X, but it must be less than or equal to 20 characters." when posting Warehouse Shipment from an IC Sales Order
        Initialize();

        // [GIVEN] Create Loctaion with require shipment will be true.
        LibraryWarehouse.CreateLocationWMS(Location, false, false, false, false, true);
        UpdateNoSeries();

        // [GIVEN] Create customer with Location Code
        CreateCustomerWithICPartner(Customer);
        Customer.Validate("Location Code", Location.Code);
        Customer.Modify();

        // [GIVEN] Create Mock record in IC Inbox SalesHedaer Table.
        MockICInboxSalesHeader(ICInboxSalesHeader, Customer."No.");
        MockICInboxSalesLine(ICInboxSalesHeader, ICPartnerRefType::Item, LibraryInventory.CreateItemNo());

        // [THEN] Create Sales Order from Inbox SalesHeader table.
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());

        // Update External document no to maxlength for checking length error.
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();
        SalesHeader.Validate("External Document No.",
        CopyStr(
            LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("External Document No."), DATABASE::"Sales Header"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Sales Header", SalesHeader.FieldNo("External Document No."))));
        SalesHeader.Modify();

        // [VERIFY] Verify document no wiil be same as IC Inbox document no.
        Assert.AreEqual(ICInboxSalesHeader."No.", SalesHeader."IC Reference Document No.", '');

        // [WHEN] Getting Sales Line to create warehouse Shipmentg
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();

        // [THEN] Create some inventory to post the warehouse shipment.
        CreateItemJournalLinePositiveAdjustment(SalesLine."No.", LibraryRandom.RandIntInRange(10, 20), Location.Code);

        // [THEN] Create and post the warehouse shipment
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        CreateAndRegisterPick(SalesLine."No.", Customer."Location Code");
        PostWarehouseShipmentLine(SalesHeader."No.", SalesLine."Line No.");

        // [GIVEN] Getting the Sales Shipment document which is posted from Warehosue shipment
        SalesShipmentHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesShipmentHeader.FindFirst();

        // [VERIFY] The document will be posted successfully and have the External documentg no.
        Assert.AreEqual(SalesHeader."External Document No.", SalesShipmentHeader."External Document No.", '');
    end;

    [Test]
    procedure VerifySalesOrderIsCreatedFromICInboxForLineDiscountOver50AndPricesIncludingVATinICPurchaseOrder()
    var
        Customer: Record Customer;
        PurchaseHeader: Record "Purchase Header";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        ICInboxTransactions: TestPage "IC Inbox Transactions";
        ICOutboxTransactions: TestPage "IC Outbox Transactions";
        ICPartnerCode: Code[20];
    begin
        // [SCENARIO 462965] Verify Sales Order is created from IC inbox for line discount over 50% and Prices Including VAT in IC Purchase Order
        Initialize();
        ICOutboxTransaction.DeleteAll();
        ICInboxTransaction.DeleteAll();

        // [GIVEN] Customer with IC Partner. This IC Partner is also set in Company Information.
        ICPartnerCode := CreateICPartnerWithInbox();
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode);

        // [GIVEN] Purchase Order "PO" for Vendor with IC Partner.
        CreatePurchaseDocumentForICPartnerVendor(PurchaseHeader, PurchaseDocType::Order, ICPartnerCode, true, 55);

        // [GIVEN] Sent Intercompany Purchase Order. IC Inbox Transaction "A" for Sales Order is created.
        ICInboxOutboxMgt.SendPurchDoc(PurchaseHeader, false);

        // [GIVEN] Open Intercompany Outbox Transactions page, and send PO to IC partner
        ICOutboxTransactions.OpenEdit();
        ICOutboxTransactions.Filter.SetFilter("IC Partner Code", ICPartnerCode);
        ICOutboxTransactions.SendToICPartner.Invoke();

        // [GIVEN] IC Outbox Transaction "B" for Sales Order is created.
        ICInboxTransactions.OpenEdit();
        ICInboxTransactions.Filter.SetFilter("IC Partner Code", ICPartnerCode);
        ICInboxTransactions.Accept.Invoke();

        // [WHEN] Create Sales Order from IC Inbox Transaction
        LibraryVariableStorage.Enqueue(ICPartnerCode);
        ICInboxTransactions."Complete Line Actions".Invoke();

        // [THEN] Verify Sales Order is created with Line Discount from Purchase Order
        VerifySalesOrder(PurchaseHeader, 55);
    end;

    [Test]
    procedure IncomingSalesOrderPostedSendsInvoice()
    var
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        DimensionValue: array[5] of Record "Dimension Value";
    begin
        // [SCENARIO] A sales order received from intercompany is posted.
        Initialize();
        ICOutboxTransaction.DeleteAll();
        ICInboxTransaction.DeleteAll();

        CreateCustomerWithICPartner(Customer);
        CreateSetOfDimValues(DimensionValue);
        // [GIVEN] A sales order received from intercompany is accepted
        MockICInboxSalesOrder(ICInboxSalesHeader, DimensionValue, Customer."No.");
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeader.FindFirst();
        SalesHeader."Due Date" := WorkDate();
        // [WHEN] The sales order is posted
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [THEN] The sales invoice is sent back to the originating company
        ICOutboxTransaction.SetRange("Document Type", ICOutboxTransaction."Document Type"::Invoice);
        ICOutboxTransaction.SetRange("IC Source Type", ICOutboxTransaction."IC Source Type"::"Sales Document");
        Assert.IsTrue(ICOutboxTransaction.FindFirst(), 'When a sales order received from intercompany is posted it should be sent back as an invoice to the originating company');
        ICOutboxTransaction.DeleteAll();
        ICInboxTransaction.DeleteAll();
    end;

    [Test]
    procedure IncomingSalesOrderWithDiscountIncludingVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        DimensionValue: array[5] of Record "Dimension Value";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] A sales order with a discount amount and prices including VAT is received from intercompany. The amounts are preserved
        // [GIVEN] A customer
        Initialize();
        CreateSetOfDimValues(DimensionValue);
        CustomerNo := CreateCustomerWithDefaultDimensions(DimensionValue);
        // [GIVEN] A sales order with a discount amount and prices including VAT
        MockICInboxSalesOrder(ICInboxSalesHeader, DimensionValue, CustomerNo);
        ICInboxSalesHeader."Prices Including VAT" := true;
        ICInboxSalesHeader.Modify();
        // [GIVEN] A sales line for that order with a discount
        ICInboxSalesLine.SetRange("IC Transaction No.", ICInboxSalesHeader."IC Transaction No.");
        ICInboxSalesLine.SetRange("IC Partner Code", ICInboxSalesHeader."IC Partner Code");
        ICInboxSalesLine.SetRange("Transaction Source", ICInboxSalesHeader."Transaction Source");
        ICInboxSalesLine.FindFirst();
        // [WHEN] Received from IC
        ICInboxSalesLine."Line Discount %" := 70;
        ICInboxSalesLine."Line Discount Amount" := 700;
        ICInboxSalesLine."Unit Price" := 1000;
        ICInboxSalesLine."Line Amount" := 300;
        ICInboxSalesLine."Amount Including VAT" := 300;
        ICInboxSalesLine.Quantity := 1;
        ICInboxSalesLine.Modify();
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());
        // [THEN] The amounts are preserved
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        Assert.AreEqual(70, SalesLine."Line Discount %", 'When a sales order with a discount amount and prices including VAT is received from intercompany, the discount % should be preserved');
        Assert.AreEqual(700, SalesLine."Line Discount Amount", 'When a sales order with a discount amount and prices including VAT is received from intercompany, the discount amount should be preserved');
        Assert.AreEqual(1000, SalesLine."Unit Price", 'When a sales order with a discount amount and prices including VAT is received from intercompany, the unit price should be preserved');
        Assert.AreEqual(300, SalesLine."Line Amount", 'When a sales order with a discount amount and prices including VAT is received from intercompany, the line amount should be preserved');
        Assert.AreEqual(300, SalesLine."Amount Including VAT", 'When a sales order with a discount amount and prices including VAT is received from intercompany, the amount including VAT should be preserved');
    end;

    [Test]
    procedure IncomingSalesOrderWithDiscountExcludingVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
        DimensionValue: array[5] of Record "Dimension Value";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] A sales order with a discount amount is received from intercompany. The amounts are preserved
        // [GIVEN] A customer
        Initialize();
        CreateSetOfDimValues(DimensionValue);
        CustomerNo := CreateCustomerWithDefaultDimensions(DimensionValue);
        // [GIVEN] A sales order with a discount amount 
        MockICInboxSalesOrder(ICInboxSalesHeader, DimensionValue, CustomerNo);
        // [GIVEN] A sales line for that order with a discount
        ICInboxSalesLine.SetRange("IC Transaction No.", ICInboxSalesHeader."IC Transaction No.");
        ICInboxSalesLine.SetRange("IC Partner Code", ICInboxSalesHeader."IC Partner Code");
        ICInboxSalesLine.SetRange("Transaction Source", ICInboxSalesHeader."Transaction Source");
        ICInboxSalesLine.FindFirst();
        // [WHEN] Received from IC
        ICInboxSalesLine."Line Discount %" := 70;
        ICInboxSalesLine."Line Discount Amount" := 700;
        ICInboxSalesLine."Unit Price" := 1000;
        ICInboxSalesLine."Line Amount" := 300;
        ICInboxSalesLine."Amount Including VAT" := 300;
        ICInboxSalesLine.Quantity := 1;
        ICInboxSalesLine.Modify();
        ICInboxOutboxMgt.CreateSalesDocument(ICInboxSalesHeader, false, WorkDate());
        // [THEN] The amounts are preserved
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        Assert.AreEqual(70, SalesLine."Line Discount %", 'When a sales order with a discount amount and prices including VAT is received from intercompany, the discount % should be preserved');
        Assert.AreEqual(700, SalesLine."Line Discount Amount", 'When a sales order with a discount amount and prices including VAT is received from intercompany, the discount amount should be preserved');
        Assert.AreEqual(1000, SalesLine."Unit Price", 'When a sales order with a discount amount and prices including VAT is received from intercompany, the unit price should be preserved');
        Assert.AreEqual(300, SalesLine."Line Amount", 'When a sales order with a discount amount and prices including VAT is received from intercompany, the line amount should be preserved');
    end;

    [Test]
    procedure ICNavigateFromSalesCreditMemoLine()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ICOutboxTransactions: TestPage "IC Outbox Transactions";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [SCENARIO 574577] "Unable to navigate to the related document" error message if you use Go to Document from the Intercompany Outbox Transactions for a Credit Memo.
        Initialize();
        LibraryApplicationArea.EnableEssentialSetup();
        CleanupIC(false, true, true, false);
        CreateCustomerWithICPartner(Customer);

        // [GIVEN] A posted sales credit memo to an IC customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] The posted sales credit memo IC transaction should be on the Outbox
        ICOutboxTransactions.OpenEdit();

        // [WHEN] Navigating from Outbox for this transaction
        PostedSalesCreditMemo.Trap();
        ICOutboxTransactions.GoToDocument.Invoke();

        // [THEN] It should open the Posted Sales Credit Memo
        PostedSalesCreditMemo."Pre-Assigned No.".AssertEquals(SalesHeader."No.");

        // Cleanup
        CleanupIC(false, true, true, false);
    end;

    local procedure Initialize()
    var
        ICSetup: Record "IC Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Intercompany III");

        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Intercompany III");
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(Database::"IC Setup");
        LibrarySetupStorage.Save(Database::"Inventory Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Intercompany III");
    end;

    local procedure CreateSetOfDimValues(var DimensionValue: array[5] of Record "Dimension Value")
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue[1]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[2]);
        LibraryDimension.CreateDimensionValue(DimensionValue[3], DimensionValue[2]."Dimension Code");
        LibraryDimension.CreateDimWithDimValue(DimensionValue[4]);
        LibraryDimension.CreateDimWithDimValue(DimensionValue[5]);
    end;

    local procedure CreateICGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; ICPartnerGLAccNo: Code[20]; Amount: Decimal; DocNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("IC Account Type", "IC Journal Account Type"::"G/L Account");
        GenJournalLine.Validate("IC Account No.", ICPartnerGLAccNo);

        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateICPartnerBase(var ICPartner: Record "IC Partner")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner.Validate("Receivables Account", GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        ICPartner.Validate("Payables Account", GLAccount."No.");
    end;

    local procedure CreateICPartnerWithInbox(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        CreateICPartnerBase(ICPartner);
        ICPartner.Validate(Name, LibraryUtility.GenerateGUID());
        ICPartner.Validate("Inbox Type", ICPartner."Inbox Type"::Database);
        ICPartner.Validate("Inbox Details", CompanyName);
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure CreateItemReference(ItemNo: Code[20]; VariantCode: Code[10]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[30]; ReferenceNo: Code[50]): Code[50]
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReference.Init();
        ItemReference."Item No." := ItemNo;
        ItemReference."Variant Code" := VariantCode;
        ItemReference."Reference Type" := ReferenceType;
        ItemReference."Reference Type No." := ReferenceTypeNo;
        ItemReference."Reference No." := ReferenceNo;
        ItemReference.Insert();
        exit(ReferenceNo);
    end;

    local procedure CreateDimValuesBeginEndTotalZeroIndentation(var DimensionValue: array[6] of Record "Dimension Value"; var ExpectedIndentation: array[6] of Integer)
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        CreateDimensionValue(
          DimensionValue[1], Dimension.Code, LibraryUtility.GenerateGUID(),
          DimensionValue[1]."Dimension Value Type"::"Begin-Total", '', false, 0);
        ExpectedIndentation[1] := 0;

        CreateDimensionValue(
          DimensionValue[2], Dimension.Code, LibraryUtility.GenerateGUID(),
          DimensionValue[2]."Dimension Value Type"::"Begin-Total", '', false, 0);
        ExpectedIndentation[2] := 1;  // incremented by 1 due to "Begin-Total" type above

        CreateDimensionValue(
          DimensionValue[3], Dimension.Code, LibraryUtility.GenerateGUID(),
          DimensionValue[3]."Dimension Value Type"::Standard, '', false, 0);
        ExpectedIndentation[3] := 2;  // incremented by 1 due to "Begin-Total" type above

        CreateDimensionValue(
          DimensionValue[4], Dimension.Code, LibraryUtility.GenerateGUID(),
          DimensionValue[4]."Dimension Value Type"::Standard, '', false, 0);
        ExpectedIndentation[4] := 2;  // not updated because the type is not "End-Total" and "Begin-Total" is not above

        CreateDimensionValue(
          DimensionValue[5], Dimension.Code, LibraryUtility.GenerateGUID(),
          DimensionValue[5]."Dimension Value Type"::"End-Total", '', false, 0);
        ExpectedIndentation[5] := 1;  // decremented by 1 due to "End-Total" type

        CreateDimensionValue(
          DimensionValue[6], Dimension.Code, LibraryUtility.GenerateGUID(),
          DimensionValue[6]."Dimension Value Type"::"End-Total", '', false, 0);
        ExpectedIndentation[6] := 0;  // decremented by 1 due to "End-Total" type
    end;

    local procedure CreateCustomerWithICPartner(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("IC Partner Code", CreateICPartnerCode());
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithICPartner(var Customer: Record Customer; ICPartnerCode: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("IC Partner Code", ICPartnerCode);
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithICPartner(var Vendor: Record Vendor)
    begin
        CreateVendorWithICPartner(Vendor, CreateICPartnerCode());
    end;

    local procedure CreateVendorWithICPartner(var Vendor: Record Vendor; ICPartnerCode: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("IC Partner Code", ICPartnerCode);
        Vendor.Modify(true);
    end;

    local procedure CreateICPartnerCode(): Code[20]
    var
        ICPartner: Record "IC Partner";
    begin
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner.Validate("Receivables Account", LibraryERM.CreateGLAccountNo());
        ICPartner.Validate("Payables Account", LibraryERM.CreateGLAccountNo());
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure CreateCustomerWithDefaultDimensions(DimensionValue: array[5] of Record "Dimension Value") CustomerNo: Code[20]
    var
        Customer: Record Customer;
        DefaultDimension: Record "Default Dimension";
    begin
        CreateCustomerWithICPartner(Customer);
        CustomerNo := Customer."No.";
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
    end;

    local procedure CreateVendorWithDefaultDimensions(DimensionValue: array[5] of Record "Dimension Value") VendorNo: Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, VendorNo, DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.CreateDefaultDimensionVendor(
          DefaultDimension, VendorNo, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
    end;

    local procedure CreateDimensionValue(var DimensionValue: Record "Dimension Value"; DimensionCode: Code[20]; "Code": Code[20]; Type: Option; Totaling: Text[250]; Blocked: Boolean; Indentation: Integer)
    begin
        LibraryDimension.CreateDimensionValueWithCode(DimensionValue, Code, DimensionCode);
        DimensionValue.Validate("Dimension Value Type", Type);
        DimensionValue.Validate(Totaling, Totaling);
        DimensionValue.Validate(Blocked, Blocked);
        DimensionValue.Validate(Indentation, Indentation);
        DimensionValue.Modify(true);
    end;

    local procedure CreateSalesDocumentWithGLAccount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DummyGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));

        LibrarySales.CreateSalesHeader(
            SalesHeader, DocumentType,
            LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale),
            LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithGLAccount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DummyGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));

        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, DocumentType,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Purchase),
            LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrder(ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateSalesDocumentForICPartnerCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ICPartnerCode: Code[20])
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        LineType: Enum "Sales Line Type";
    begin
        CreateCustomerWithICPartner(Customer, ICPartnerCode);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, LineType::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocumentForICPartnerVendor(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ICPartnerCode: Code[20]; PricesIncludingVAT: Boolean; LineDiscount: Decimal)
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        LineType: Enum "Purchase Line Type";
    begin
        CreateVendorWithICPartner(Vendor, ICPartnerCode);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        if PricesIncludingVAT then
            PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, LineType::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        if LineDiscount <> 0 then
            PurchaseLine.Validate("Line Discount %", LineDiscount);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLineCommentType(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; DescriptionValue: Text[100])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::" ", '', 0);
        UpdateDescriptionOnSalesLine(SalesLine, DescriptionValue);
    end;

    local procedure CreateSalesLineItemType(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, ItemNo, LibraryRandom.RandDecInRange(10, 20, 2));
        UpdateUnitPriceOnSalesLine(SalesLine, LibraryRandom.RandDecInRange(100, 200, 2));
    end;

    local procedure FindLastSalesInvoiceHeaderNo(OrderNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindLast();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure FindLastSalesCrMemoHeaderNo(OrderNo: Code[20]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Return Order No.", OrderNo);
        SalesCrMemoHeader.FindLast();
        exit(SalesCrMemoHeader."No.");
    end;

    local procedure FindICOutboxTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction"; SourceType: Enum "IC Transaction Source Type"; DocumentType: Enum "IC Transaction Document Type"; DocumentNo: Code[20]; ICPartnerCode: Code[20])
    begin
        ICOutboxTransaction.Reset();
        ICOutboxTransaction.SetRange("IC Source Type", SourceType);
        ICOutboxTransaction.SetRange("Document Type", DocumentType);
        ICOutboxTransaction.SetRange("Document No.", DocumentNo);
        ICOutboxTransaction.SetRange("IC Partner Code", ICPartnerCode);
        ICOutboxTransaction.FindFirst();
    end;

    local procedure FindHandledICOutboxTransaction(var HandledICOutboxTrans: Record "Handled IC Outbox Trans."; SourceType: Enum "IC Transaction Source Type"; DocumentType: Enum "IC Transaction Document Type"; DocumentNo: Code[20]; ICPartnerCode: Code[20])
    begin
        HandledICOutboxTrans.Reset();
        HandledICOutboxTrans.SetRange("IC Source Type", SourceType);
        HandledICOutboxTrans.SetRange("Document Type", DocumentType);
        HandledICOutboxTrans.SetRange("Document No.", DocumentNo);
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        HandledICOutboxTrans.FindFirst();
    end;

    local procedure GetICDimensionValueFromDimensionValue(var ICDimensionValue: Record "IC Dimension Value"; DimensionValue: Record "Dimension Value")
    begin
        ICDimensionValue.Reset();
        ICDimensionValue.SetRange("Dimension Code", DimensionValue."Dimension Code");
        ICDimensionValue.SetRange(Code, DimensionValue.Code);
        ICDimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type");
        ICDimensionValue.FindFirst();
    end;

    local procedure GetICTransactionKeyValues(var ICInboxTransaction: Record "IC Inbox Transaction"; var TransactionNo: Integer; var ICPartnerCode: Code[20]; var TransactionSource: Option "Returned by Partner","Created by Partner")
    begin
        TransactionNo := ICInboxTransaction."Transaction No.";
        ICPartnerCode := ICInboxTransaction."IC Partner Code";
        TransactionSource := ICInboxTransaction."Transaction Source";
    end;

    local procedure CleanupIC(Inbox: Boolean; Outbox: Boolean; Sales: Boolean; Purchase: Boolean)
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purchase Header";
    begin
        if Inbox then begin
            ICInboxTransaction.DeleteAll();
            HandledICInboxTrans.DeleteAll();
        end;
        if Outbox then begin
            ICOutboxTransaction.DeleteAll();
            HandledICOutboxTrans.DeleteAll();
        end;
        if Sales then begin
            SalesHeader.DeleteAll();
            SalesInvoiceHeader.DeleteAll();
        end;
        if Purchase then begin
            PurchaseHeader.DeleteAll();
            PurchaseInvoiceHeader.DeleteAll();
        end;
        if Inbox and Sales then
            ICInboxSalesHeader.DeleteAll();
        if Outbox and Sales then
            ICOutboxSalesHeader.DeleteAll();
    end;

    local procedure MockICInboxSalesOrder(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; DimensionValue: array[5] of Record "Dimension Value"; CustomerNo: Code[20])
    var
        ICPartnerRefType: Enum "IC Partner Reference Type";
    begin
        MockICInboxSalesHeader(ICInboxSalesHeader, CustomerNo);
        MockICDocumentDimension(ICInboxSalesHeader."IC Partner Code", ICInboxSalesHeader."IC Transaction No.",
          DimensionValue[3], DATABASE::"IC Inbox Sales Header", 0);
        MockICDocumentDimension(ICInboxSalesHeader."IC Partner Code", ICInboxSalesHeader."IC Transaction No.",
          DimensionValue[4], DATABASE::"IC Inbox Sales Header", 0);
        MockICDocumentDimension(ICInboxSalesHeader."IC Partner Code", ICInboxSalesHeader."IC Transaction No.",
          DimensionValue[5], DATABASE::"IC Inbox Sales Line",
          MockICInboxSalesLine(ICInboxSalesHeader, ICPartnerRefType::Item, LibraryInventory.CreateItemNo()));
    end;

    local procedure MockICInboxSalesHeader(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        ICInboxSalesHeader.Init();
        ICInboxSalesHeader."IC Transaction No." :=
          LibraryUtility.GetNewRecNo(ICInboxSalesHeader, ICInboxSalesHeader.FieldNo("IC Transaction No."));
        ICInboxSalesHeader."IC Partner Code" := Customer."IC Partner Code";
        ICInboxSalesHeader."Document Type" := ICInboxSalesHeader."Document Type"::Order;
        ICInboxSalesHeader."Sell-to Customer No." := Customer."No.";
        ICInboxSalesHeader."Bill-to Customer No." := Customer."No.";
        ICInboxSalesHeader."Posting Date" := WorkDate();
        ICInboxSalesHeader."Document Date" := WorkDate();
        ICInboxSalesHeader."No." := LibraryUtility.GenerateRandomCode(ICInboxSalesHeader.FieldNo("No."), DATABASE::"IC Inbox Sales Header");
        ICInboxSalesHeader.Insert();
    end;

    local procedure MockICInboxSalesLine(ICInboxSalesHeader: Record "IC Inbox Sales Header"; ICPartnerRefType: Enum "IC Partner Reference Type"; ICPartnerReference: Code[20]): Integer
    var
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.FindUnitOfMeasure(UnitOfMeasure);
        ICInboxSalesLine.Init();
        ICInboxSalesLine."Line No." :=
          LibraryUtility.GetNewRecNo(ICInboxSalesLine, ICInboxSalesLine.FieldNo("Line No."));
        ICInboxSalesLine."IC Transaction No." := ICInboxSalesHeader."IC Transaction No.";
        ICInboxSalesLine."IC Partner Code" := ICInboxSalesHeader."IC Partner Code";
        ICInboxSalesLine."Transaction Source" := ICInboxSalesHeader."Transaction Source";
        ICInboxSalesLine."IC Partner Ref. Type" := ICPartnerRefType;
        ICInboxSalesLine."IC Partner Reference" := ICPartnerReference;
        ICInboxSalesLine.Quantity := LibraryRandom.RandDecInRange(10, 20, 2);
        ICInboxSalesLine."Unit Price" := LibraryRandom.RandDecInRange(100, 200, 2);
        ICInboxSalesLine."Unit of Measure Code" := UnitOfMeasure.Code;
        ICInboxSalesLine.Insert();
        exit(ICInboxSalesLine."Line No.");
    end;

    local procedure MockICInboxPurchOrder(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; DimensionValue: array[5] of Record "Dimension Value"; VendorNo: Code[20])
    begin
        MockICInboxPurchHeader(ICInboxPurchaseHeader, VendorNo);
        MockICDocumentDimension(ICInboxPurchaseHeader."IC Partner Code", ICInboxPurchaseHeader."IC Transaction No.",
          DimensionValue[3], DATABASE::"IC Inbox Purchase Header", 0);
        MockICDocumentDimension(ICInboxPurchaseHeader."IC Partner Code", ICInboxPurchaseHeader."IC Transaction No.",
          DimensionValue[4], DATABASE::"IC Inbox Purchase Header", 0);
        MockICDocumentDimension(ICInboxPurchaseHeader."IC Partner Code", ICInboxPurchaseHeader."IC Transaction No.",
          DimensionValue[5], DATABASE::"IC Inbox Purchase Line", MockICInboxPurchLine(ICInboxPurchaseHeader));
    end;

    local procedure MockICInboxPurchaseDocument(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; ICInboxTransaction: Record "IC Inbox Transaction"; VendorNo: Code[20]; QuantityValue: Decimal)
    var
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
        ICPurchaseDocumentType: Enum "IC Purchase Document Type";
    begin
        case ICInboxTransaction."Document Type" of
            // Enums are incompatible
            ICInboxTransaction."Document Type"::Order:
                ICPurchaseDocumentType := ICPurchaseDocumentType::Order;
            ICInboxTransaction."Document Type"::"Return Order":
                ICPurchaseDocumentType := ICPurchaseDocumentType::"Return Order";
            else
                ICPurchaseDocumentType := ICInboxTransaction."Document Type";
        end;

        ICInboxPurchaseHeader.Init();
        ICInboxPurchaseHeader."Document Type" := ICPurchaseDocumentType;
        ICInboxPurchaseHeader."Pay-to Vendor No." := VendorNo;
        ICInboxPurchaseHeader."No." := ICInboxTransaction."Document No.";
        ICInboxPurchaseHeader."Vendor Order No." := ICInboxTransaction."Document No.";
        ICInboxPurchaseHeader."Vendor Invoice No." := ICInboxTransaction."Document No.";
        ICInboxPurchaseHeader."Buy-from Vendor No." := VendorNo;
        ICInboxPurchaseHeader."Posting Date" := WorkDate();
        ICInboxPurchaseHeader."Document Date" := WorkDate();
        ICInboxPurchaseHeader."IC Partner Code" := ICInboxTransaction."IC Partner Code";
        ICInboxPurchaseHeader."IC Transaction No." := ICInboxTransaction."Transaction No.";
        ICInboxPurchaseHeader."Transaction Source" := ICInboxTransaction."Transaction Source";
        ICInboxPurchaseHeader.Insert();

        ICInboxPurchaseLine."Document Type" := ICPurchaseDocumentType;
        ICInboxPurchaseLine."Document No." := ICInboxTransaction."Document No.";
        ICInboxPurchaseLine.Quantity := QuantityValue;
        ICInboxPurchaseLine."IC Partner Code" := ICInboxTransaction."IC Partner Code";
        ICInboxPurchaseLine."IC Transaction No." := ICInboxTransaction."Transaction No.";
        ICInboxPurchaseLine."Transaction Source" := ICInboxTransaction."Transaction Source";
        ICInboxPurchaseLine."Line No." := LibraryUtility.GetNewRecNo(ICInboxPurchaseLine, ICInboxPurchaseLine.FieldNo("Line No."));
        ICInboxPurchaseLine.Insert();
    end;

    local procedure MockICInboxPurchHeader(var ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"; VendorNo: Code[20])
    begin
        ICInboxPurchaseHeader.Init();
        ICInboxPurchaseHeader."IC Transaction No." :=
          LibraryUtility.GetNewRecNo(ICInboxPurchaseHeader, ICInboxPurchaseHeader.FieldNo("IC Transaction No."));
        ICInboxPurchaseHeader."IC Partner Code" :=
          LibraryUtility.GenerateRandomCode(ICInboxPurchaseHeader.FieldNo("IC Partner Code"), DATABASE::"IC Inbox Purchase Header");
        ICInboxPurchaseHeader."Document Type" := ICInboxPurchaseHeader."Document Type"::Order;
        ICInboxPurchaseHeader."Buy-from Vendor No." := VendorNo;
        ICInboxPurchaseHeader."Pay-to Vendor No." := VendorNo;
        ICInboxPurchaseHeader."Posting Date" := WorkDate();
        ICInboxPurchaseHeader."Document Date" := WorkDate();
        ICInboxPurchaseHeader.Insert();
    end;

    local procedure MockICInboxPurchLine(ICInboxPurchaseHeader: Record "IC Inbox Purchase Header"): Integer
    var
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
    begin
        ICInboxPurchaseLine.Init();
        ICInboxPurchaseLine."Line No." :=
          LibraryUtility.GetNewRecNo(ICInboxPurchaseLine, ICInboxPurchaseLine.FieldNo("Line No."));
        ICInboxPurchaseLine."IC Transaction No." := ICInboxPurchaseHeader."IC Transaction No.";
        ICInboxPurchaseLine."IC Partner Code" := ICInboxPurchaseHeader."IC Partner Code";
        ICInboxPurchaseLine."Transaction Source" := ICInboxPurchaseHeader."Transaction Source";
        ICInboxPurchaseLine."IC Partner Ref. Type" := ICInboxPurchaseLine."IC Partner Ref. Type"::Item;
        ICInboxPurchaseLine."IC Partner Reference" := LibraryInventory.CreateItemNo();
        ICInboxPurchaseLine.Insert();
        exit(ICInboxPurchaseLine."Line No.");
    end;

    local procedure MockICDocumentDimension(ICPartnerCode: Code[20]; TransactionNo: Integer; DimensionValue: Record "Dimension Value"; TableID: Integer; LineNo: Integer)
    var
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
        ICDocumentDimension: Record "IC Document Dimension";
    begin
        LibraryDimension.CreateAndMapICDimFromDim(ICDimension, DimensionValue."Dimension Code");
        LibraryDimension.CreateAndMapICDimValueFromDimValue(ICDimensionValue, DimensionValue.Code, DimensionValue."Dimension Code");
        ICDocumentDimension.Init();
        ICDocumentDimension."IC Partner Code" := ICPartnerCode;
        ICDocumentDimension."Transaction No." := TransactionNo;
        ICDocumentDimension."Table ID" := TableID;
        ICDocumentDimension."Dimension Code" := ICDimensionValue."Dimension Code";
        ICDocumentDimension."Dimension Value Code" := ICDimensionValue.Code;
        ICDocumentDimension."Line No." := LineNo;
        ICDocumentDimension.Insert();
    end;

    local procedure MockICOutboxTrans(var ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        ICOutboxTransaction.Init();
        ICOutboxTransaction."Transaction No." := LibraryUtility.GetNewRecNo(ICOutboxTransaction, ICOutboxTransaction.FieldNo("Transaction No."));
        ICOutboxTransaction."IC Partner Code" := CreateICPartnerCode();
        ICOutboxTransaction."Transaction Source" := ICOutboxTransaction."Transaction Source"::"Created by Current Company";
        ICOutboxTransaction."Document Type" := ICOutboxTransaction."Document Type"::Invoice;
        ICOutboxTransaction."IC Source Type" := ICOutboxTransaction."IC Source Type"::Journal;
        ICOutboxTransaction."Document No." := LibraryUtility.GenerateGUID();
        ICOutboxTransaction."Posting Date" := LibraryRandom.RandDate(10);
        ICOutboxTransaction."Document Date" := LibraryRandom.RandDate(10);
        ICOutboxTransaction."IC Account Type" := "IC Journal Account Type"::"G/L Account";
        ICOutboxTransaction."IC Account No." := LibraryUtility.GenerateGUID();
        ICOutboxTransaction."Source Line No." := LibraryRandom.RandInt(100);
        ICOutboxTransaction.Insert();
    end;

    local procedure MockICOutboxTransaction(var ICOutboxTransaction: Record "IC Outbox Transaction"; ICPartnerCode: Code[20]; SourceType: Enum "IC Transaction Source Type"; DocumentType: Enum "IC Transaction Document Type"; DocumentNo: Code[20])
    begin
        ICOutboxTransaction.Init();
        ICOutboxTransaction."IC Partner Code" := ICPartnerCode;
        ICOutboxTransaction."IC Source Type" := SourceType;
        ICOutboxTransaction."Document Type" := DocumentType;
        ICOutboxTransaction."Document No." := DocumentNo;
        ICOutboxTransaction."Posting Date" := WorkDate();
        ICOutboxTransaction."Transaction Source" := ICOutboxTransaction."Transaction Source"::"Created by Current Company";
        ICOutboxTransaction."Document Date" := WorkDate();
        ICOutboxTransaction."Transaction No." := LibraryUtility.GetNewRecNo(ICOutboxTransaction, ICOutboxTransaction.FieldNo("Transaction No."));
        ICOutboxTransaction.Insert();
    end;

    local procedure MockICOutboxSalesHeader(var ICOutboxSalesHeader: Record "IC Outbox Sales Header"; ICOutboxTransaction: Record "IC Outbox Transaction")
    begin
        ICOutboxSalesHeader.Init();
        ICOutboxSalesHeader."IC Transaction No." := ICOutboxTransaction."Transaction No.";
        ICOutboxSalesHeader."IC Partner Code" := ICOutboxTransaction."IC Partner Code";
        ICOutboxSalesHeader."Transaction Source" := ICOutboxTransaction."Transaction Source";
        ICOutboxSalesHeader."No." := LibraryUtility.GenerateGUID();
        ICOutboxSalesHeader."Order No." := LibraryUtility.GenerateGUID();
        ICOutboxSalesHeader.Insert();
    end;

    local procedure MockICOutboxSalesLine(var ICOutboxSalesLine: Record "IC Outbox Sales Line"; ICOutboxSalesHeader: Record "IC Outbox Sales Header")
    begin
        ICOutboxSalesLine.Init();
        ICOutboxSalesLine."Document No." := ICOutboxSalesHeader."No.";
        ICOutboxSalesLine."IC Transaction No." := ICOutboxSalesHeader."IC Transaction No.";
        ICOutboxSalesLine."IC Partner Code" := ICOutboxSalesHeader."IC Partner Code";
        ICOutboxSalesLine."Transaction Source" := ICOutboxSalesHeader."Transaction Source";
        ICOutboxSalesLine."Shipment Line No." := LibraryRandom.RandInt(1000);
        ICOutboxSalesLine."Shipment No." := LibraryUtility.GenerateGUID();
        ICOutboxSalesLine.Insert();
    end;

    local procedure MockICOutboxPurchaseDocument(var ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header"; ICOutboxTransaction: Record "IC Outbox Transaction"; VendorNo: Code[20]; QuantityValue: Decimal; DirectUnitCost: Decimal)
    var
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
        ICPurchaseDocumentType: Enum "IC Purchase Document Type";
    begin
        case ICOutboxTransaction."Document Type" of
            // Enums are incompatible
            ICOutboxTransaction."Document Type"::Order:
                ICPurchaseDocumentType := ICPurchaseDocumentType::Order;
            ICOutboxTransaction."Document Type"::"Return Order":
                ICPurchaseDocumentType := ICPurchaseDocumentType::"Return Order";
            else
                ICPurchaseDocumentType := ICOutboxTransaction."Document Type";
        end;
        ICOutboxPurchaseHeader.Init();
        ICOutboxPurchaseHeader."Document Type" := ICPurchaseDocumentType;
        ICOutboxPurchaseHeader."Buy-from Vendor No." := VendorNo;
        ICOutboxPurchaseHeader."No." := ICOutboxTransaction."Document No.";
        ICOutboxPurchaseHeader."Pay-to Vendor No." := VendorNo;
        ICOutboxPurchaseHeader."Posting Date" := WorkDate();
        ICOutboxPurchaseHeader."Document Date" := WorkDate();
        ICOutboxPurchaseHeader."IC Partner Code" := ICOutboxTransaction."IC Partner Code";
        ICOutboxPurchaseHeader."IC Transaction No." := ICOutboxTransaction."Transaction No.";
        ICOutboxPurchaseHeader."Transaction Source" := ICOutboxTransaction."Transaction Source";
        ICOutboxPurchaseHeader.Insert();

        ICOutboxPurchaseLine."Document Type" := ICPurchaseDocumentType;
        ICOutboxPurchaseLine."Document No." := ICOutboxTransaction."Document No.";
        ICOutboxPurchaseLine.Quantity := QuantityValue;
        ICOutboxPurchaseLine."Direct Unit Cost" := DirectUnitCost;
        ICOutboxPurchaseLine."IC Partner Code" := ICOutboxTransaction."IC Partner Code";
        ICOutboxPurchaseLine."IC Transaction No." := ICOutboxTransaction."Transaction No.";
        ICOutboxPurchaseLine."Transaction Source" := ICOutboxTransaction."Transaction Source";
        ICOutboxPurchaseLine."Line No." := LibraryUtility.GetNewRecNo(ICOutboxPurchaseLine, ICOutboxPurchaseLine.FieldNo("Line No."));
        ICOutboxPurchaseLine.Insert();
    end;

    local procedure MockICInboxTransaction(var ICInboxTransaction: Record "IC Inbox Transaction"; ICPartnerCode: Code[20]; SourceType: enum "IC Transaction Source Type"; DocumentType: Enum "IC Transaction Document Type"; DocumentNo: Code[20])
    begin
        ICInboxTransaction.Init();
        ICInboxTransaction."IC Partner Code" := ICPartnerCode;
        ICInboxTransaction."IC Source Type" := SourceType;
        ICInboxTransaction."Document Type" := DocumentType;
        ICInboxTransaction."Document No." := DocumentNo;
        ICInboxTransaction."Posting Date" := WorkDate();
        ICInboxTransaction."Transaction Source" := ICInboxTransaction."Transaction Source"::"Created by Partner";
        ICInboxTransaction."Document Date" := WorkDate();
        ICInboxTransaction."Original Document No." := DocumentNo;
        ICInboxTransaction."Transaction No." := LibraryUtility.GetNewRecNo(ICInboxTransaction, ICInboxTransaction.FieldNo("Transaction No."));
        ICInboxTransaction.Insert();
    end;

    local procedure MockICInboxSalesDocument(var ICInboxSalesHeader: Record "IC Inbox Sales Header"; ICInboxTransaction: Record "IC Inbox Transaction"; CustomerNo: Code[20]; QuantityValue: Decimal; UnitPrice: Decimal)
    var
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICSalesDocumentType: Enum "IC Sales Document Type";
    begin
        case ICInboxTransaction."Document Type" of
            // Enums ICSalesDocumentType and ICTransactionDocumentType are incompatible
            ICInboxTransaction."Document Type"::Order:
                ICSalesDocumentType := ICSalesDocumentType::Order;
            ICInboxTransaction."Document Type"::"Return Order":
                ICSalesDocumentType := ICSalesDocumentType::"Return Order";
            else
                ICSalesDocumentType := ICInboxTransaction."Document Type";
        end;
        ICInboxSalesHeader.Init();
        ICInboxSalesHeader."Document Type" := ICSalesDocumentType;
        ICInboxSalesHeader."Sell-to Customer No." := CustomerNo;
        ICInboxSalesHeader."No." := ICInboxTransaction."Document No.";
        ICInboxSalesHeader."Bill-to Customer No." := CustomerNo;
        ICInboxSalesHeader."Posting Date" := WorkDate();
        ICInboxSalesHeader."Document Date" := WorkDate();
        ICInboxSalesHeader."IC Partner Code" := ICInboxTransaction."IC Partner Code";
        ICInboxSalesHeader."IC Transaction No." := ICInboxTransaction."Transaction No.";
        ICInboxSalesHeader."Transaction Source" := ICInboxTransaction."Transaction Source";
        ICInboxSalesHeader.Insert();

        ICInboxSalesLine."Document Type" := ICSalesDocumentType;
        ICInboxSalesLine."Document No." := ICInboxTransaction."Document No.";
        ICInboxSalesLine.Quantity := QuantityValue;
        ICInboxSalesLine."Unit Price" := UnitPrice;
        ICInboxSalesLine."IC Partner Code" := ICInboxTransaction."IC Partner Code";
        ICInboxSalesLine."IC Transaction No." := ICInboxTransaction."Transaction No.";
        ICInboxSalesLine."Transaction Source" := ICInboxTransaction."Transaction Source";
        ICInboxSalesLine."Line No." := LibraryUtility.GetNewRecNo(ICInboxSalesLine, ICInboxSalesLine.FieldNo("Line No."));
        ICInboxSalesLine.Insert();
    end;

    local procedure RunCopyICDimensionsFromDimensions()
    var
        ICDimensionsSelector: TestPage "IC Dimensions Selector";
        ERMIntercompanyIII: Codeunit "ERM Intercompany III";
    begin
        ICDimensionsSelector.OpenView();
        BindSubscription(ERMIntercompanyIII);
        ICDimensionsSelector.CopyFromDimensions.Invoke();
    end;

    local procedure SetFilterDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; DimensionValue: Record "Dimension Value")
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        DimensionSetEntry.SetRange("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure UpdatePostingDescriptionOnSalesHeader(var SalesHeader: Record "Sales Header"; PostingDescriptionTxt: Text[100])
    begin
        SalesHeader.Validate("Posting Description", PostingDescriptionTxt);
        SalesHeader.Modify(true);
    end;

    local procedure UpdatePostingDescriptionOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PostingDescriptionTxt: Text[100])
    begin
        PurchaseHeader.Validate("Posting Description", PostingDescriptionTxt);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateICInfoOnSalesLine(var SalesLine: Record "Sales Line"; ICPartnerCode: Code[20])
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        LibraryERM.CreateICGLAccount(ICGLAccount);
        SalesLine.Validate("IC Partner Code", ICPartnerCode);
        SalesLine.Validate("IC Partner Ref. Type", SalesLine."IC Partner Ref. Type"::"G/L Account");
        SalesLine.Validate("IC Partner Reference", ICGLAccount."No.");
        SalesLine.Modify(true);
    end;

    local procedure UpdateICInfoOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; ICPartnerCode: Code[20])
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        LibraryERM.CreateICGLAccount(ICGLAccount);
        PurchaseLine.Validate("IC Partner Code", ICPartnerCode);
        PurchaseLine.Validate("IC Partner Ref. Type", PurchaseLine."IC Partner Ref. Type"::"G/L Account");
        PurchaseLine.Validate("IC Partner Reference", ICGLAccount."No.");
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateDescriptionOnSalesLine(var SalesLine: Record "Sales Line"; DescriptionValue: Text[100]);
    begin
        SalesLine.Validate(Description, DescriptionValue);
        SalesLine.Modify(true);
    end;

    local procedure UpdateDescription2OnSalesLine(var SalesLine: Record "Sales Line"; Description2: Text[50]);
    begin
        SalesLine.Validate("Description 2", Description2);
        SalesLine.Modify(true);
    end;

    local procedure UpdateDescription2OnPurchaseLine(var PurchaseLine: Record "Purchase Line"; Description2: Text[50]);
    begin
        PurchaseLine.Validate("Description 2", Description2);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateUnitPriceOnSalesLine(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure UpdateReserveOnCustomer(var Customer: Record Customer; ReserveMethod: Enum "Reserve Method")
    begin
        Customer.Validate(Reserve, ReserveMethod);
        Customer.Modify(true);
    end;

    local procedure UpdateAutoSendTransactionsOnCompanyInfo(AutoSendTransactions: Boolean);
    var
        ICSetup: Record "IC Setup";
    begin
        ICSetup.Get();
        ICSetup.Validate("Auto. Send Transactions", AutoSendTransactions);
        ICSetup.Modify(true);
    end;

    local procedure UpdateICPartnerCodeOnCompanyInfo(ICPartnerCode: Code[20])
    var
        ICSetup: Record "IC Setup";
    begin
        ICSetup.Get();
        ICSetup.Validate("IC Partner Code", ICPartnerCode);
        ICSetup.Modify(true);
    end;

    local procedure UpdateAutoAcceptTransOnICPartner(ICPartnerCode: Code[20]; AutoAcceptTransactions: Boolean)
    var
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(ICPartnerCode);
        ICPartner.Validate("Auto. Accept Transactions", AutoAcceptTransactions);
        ICPartner.Modify(true);
    end;

    local procedure UpdateQtyToShipOnSalesLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; LineNo: Integer; QtyToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(DocumentType, DocumentNo, LineNo);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure UpdateReturnQtyToReceiveOnSalesLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; LineNo: Integer; ReturnQtyToReceive: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(DocumentType, DocumentNo, LineNo);
        SalesLine.Validate("Return Qty. to Receive", ReturnQtyToReceive);
        SalesLine.Modify(true);
    end;

    local procedure UpdateICDirectionOnSalesHeader(var SalesHeader: Record "Sales Header"; ICDirection: Enum "IC Direction Type")
    begin
        SalesHeader.Validate("IC Direction", ICDirection);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateBillToCustomerNoOnSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        SalesHeader.Validate("Bill-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreateICSetup(var ICSetup: Record "IC Setup")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Intercompany);
        GenJournalTemplate.Modify();

        ICSetup.Get();
        ICSetup.Validate("IC Partner Code", 'abc');
        ICSetup.Validate("Default IC Gen. Jnl. Template", GenJournalTemplate.Name);
        ICSetup.Validate("Default IC Gen. Jnl. Batch", GenJournalBatch.Name);
        ICSetup.Modify();
    end;

    local procedure CreateDummyCInboxTransaction(var ICInboxTransaction: Record "IC Inbox Transaction"; ICPartnerCode: Code[20]);
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
    begin
        ICInboxTransaction.DeleteAll();
        HandledICInboxTrans.DeleteAll();

        ICInboxTransaction.Init();
        ICInboxTransaction."IC Partner Code" := ICPartnerCode;
        ICInboxTransaction."Transaction Source" := ICInboxTransaction."Transaction Source"::"Created by Partner";
        ICInboxTransaction."Document Type" := ICInboxTransaction."Document Type"::Invoice;
        ICInboxTransaction."IC Source Type" := ICInboxTransaction."IC Source Type"::Journal;
        ICInboxTransaction."Line Action" := ICInboxTransaction."Line Action"::Accept;
        ICInboxTransaction."Posting Date" := WorkDate() + 1;
        ICInboxTransaction.Insert();

        ICInboxTransaction.SetRange("Transaction No.", 0);
        ICInboxTransaction.FindSet();
    end;

    local procedure CreateDummyICInboxJnlLine(var ICInboxJnlLine: Record "IC Inbox Jnl. Line"; var ICGLAccount: Record "IC G/L Account"; ICPartnerCode: Code[20]);
    var
        HandledICInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
    begin
        ICInboxJnlLine.DeleteAll();
        HandledICInboxJnlLine.DeleteAll();

        LibraryERM.CreateICGLAccount(ICGLAccount);
        ICGLAccount.Validate("Map-to G/L Acc. No.", LibraryERM.CreateGLAccountNo());
        ICGLAccount.Modify();

        ICInboxJnlLine.Init();
        ICInboxJnlLine."IC Partner Code" := ICPartnerCode;
        ICInboxJnlLine."Transaction Source" := ICInboxJnlLine."Transaction Source"::"Created by Partner";
        ICInboxJnlLine."Account Type" := ICInboxJnlLine."Account Type"::"G/L Account";
        ICInboxJnlLine."Account No." := ICGLAccount."No.";
        ICInboxJnlLine."Document No." := LibraryUtility.GenerateGUID();
        ICInboxJnlLine.Insert();
    end;

    local procedure CreateFileLocationICSetup(var ICSetup: Record "IC Setup")
    var
        FileManagement: Codeunit "File Management";
        FileName: Text;
    begin
        FileName := FileManagement.ServerTempFileName('');
        CreateICSetup(ICSetup);
        ICSetup.Validate("Auto. Send Transactions", true);
        ICSetup.Validate("IC Inbox Type", ICSetup."IC Inbox Type"::"File Location");
        ICSetup.Validate("IC Inbox Details", FileManagement.GetDirectoryName(FileName));
        ICSetup.Modify(true);
    end;

    local procedure VerifySalesDocDimSet(DimensionValue: array[5] of Record "Dimension Value"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();
        VerifyDimensionSet(DimensionValue, SalesHeader."Dimension Set ID");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        VerifyLineDimSet(DimensionValue, SalesLine."Dimension Set ID");
    end;

    local procedure VerifyPurchDocDimSet(DimensionValue: array[5] of Record "Dimension Value"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
        VerifyDimensionSet(DimensionValue, PurchaseHeader."Dimension Set ID");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        VerifyLineDimSet(DimensionValue, PurchaseLine."Dimension Set ID");
    end;

    local procedure VerifyDimensionSet(DimensionValue: array[5] of Record "Dimension Value"; DimSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimSetID);
        SetFilterDimensionSetEntry(DimensionSetEntry, DimensionValue[1]);
        Assert.RecordIsNotEmpty(DimensionSetEntry);

        SetFilterDimensionSetEntry(DimensionSetEntry, DimensionValue[2]);
        Assert.RecordIsEmpty(DimensionSetEntry);

        SetFilterDimensionSetEntry(DimensionSetEntry, DimensionValue[3]);
        Assert.RecordIsNotEmpty(DimensionSetEntry);

        SetFilterDimensionSetEntry(DimensionSetEntry, DimensionValue[4]);
        Assert.RecordIsNotEmpty(DimensionSetEntry);
    end;

    local procedure VerifyLineDimSet(DimensionValue: array[5] of Record "Dimension Value"; DimSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        VerifyDimensionSet(DimensionValue, DimSetID);
        DimensionSetEntry.SetRange("Dimension Set ID", DimSetID);
        SetFilterDimensionSetEntry(DimensionSetEntry, DimensionValue[5]);
        Assert.RecordIsNotEmpty(DimensionSetEntry);
    end;

    local procedure VerifyIndentationICDimensionValuesAfterCopy(DimensionValue: array[6] of Record "Dimension Value"; ExpectedIndentation: array[6] of Integer)
    var
        ICDimensionValue: Record "IC Dimension Value";
        i: Integer;
    begin
        for i := 1 to ArrayLen(DimensionValue) do begin
            GetICDimensionValueFromDimensionValue(ICDimensionValue, DimensionValue[i]);
            ICDimensionValue.TestField(Indentation, ExpectedIndentation[i]);
        end;
    end;

    local procedure VerifyGLEntryDescriptionICPartner(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; ICPartnerCode: Code[20]; DescrpitionTxt: Text[100])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"IC Partner");
        GLEntry.SetRange("Bal. Account No.", ICPartnerCode);
        GLEntry.FindFirst();
        GLEntry.TestField(Description, DescrpitionTxt);
        GLEntry.TestField("IC Partner Code", ICPartnerCode);
    end;

    local procedure VerifyReservedQuantityOnSalesLine(CustomerNo: Code[20]; ExpectedQuantity: Decimal; ExpectedReservedQuantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        Assert.AreEqual(SalesLine.Quantity, ExpectedQuantity, '');

        SalesLine.CalcFields("Reserved Quantity");
        Assert.AreEqual(ExpectedReservedQuantity, SalesLine."Reserved Quantity", '');
    end;

    local procedure VerifyHandledICOutboxTransCount(SourceType: Enum "IC Transaction Source Type"; DocumentType: Enum "IC Transaction Document Type"; DocumentNo: Code[20]; ICPartnerCode: Code[20]; ExpectedCount: Integer)
    var
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
    begin
        HandledICOutboxTrans.SetRange("IC Source Type", SourceType);
        HandledICOutboxTrans.SetRange("Document Type", DocumentType);
        HandledICOutboxTrans.SetRange("Document No.", DocumentNo);
        HandledICOutboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        Assert.RecordCount(HandledICOutboxTrans, ExpectedCount);
    end;

    local procedure VerifyHandledICInboxTransCount(SourceType: enum "IC Transaction Source Type"; DocumentType: Enum "IC Transaction Document Type"; DocumentNo: Code[20]; ICPartnerCode: Code[20]; ExpectedCount: Integer)
    var
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
    begin
        HandledICInboxTrans.SetRange("IC Source Type", SourceType);
        HandledICInboxTrans.SetRange("Document Type", DocumentType);
        HandledICInboxTrans.SetRange("Document No.", DocumentNo);
        HandledICInboxTrans.SetRange("IC Partner Code", ICPartnerCode);
        Assert.RecordCount(HandledICInboxTrans, ExpectedCount);
    end;

    local procedure VerifyICOutboxSalesLineCount(ICOutboxTransaction: Record "IC Outbox Transaction"; ExpectedLineCount: Integer)
    var
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        ICOutboxSalesLine.SetRange("IC Transaction No.", ICOutboxTransaction."Transaction No.");
        ICOutboxSalesLine.SetRange("IC Partner Code", ICOutboxTransaction."IC Partner Code");
        ICOutboxSalesLine.SetRange("Transaction Source", ICOutboxTransaction."Transaction Source");
        Assert.RecordCount(ICOutboxSalesLine, ExpectedLineCount);
    end;

    local procedure VerifyICOutboxSalesLineQty(ICOutboxTransaction: Record "IC Outbox Transaction"; ICPartnerRefType: Enum "IC Partner Reference Type"; ICPartnerReference: Code[20]; ExpectedQuantity: Decimal)
    var
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        ICOutboxSalesLine.SetRange("IC Transaction No.", ICOutboxTransaction."Transaction No.");
        ICOutboxSalesLine.SetRange("IC Partner Code", ICOutboxTransaction."IC Partner Code");
        ICOutboxSalesLine.SetRange("Transaction Source", ICOutboxTransaction."Transaction Source");
        ICOutboxSalesLine.SetRange("IC Partner Ref. Type", ICPartnerRefType);
        ICOutboxSalesLine.SetRange("IC Partner Reference", ICPartnerReference);
        ICOutboxSalesLine.FindFirst();
        Assert.AreEqual(ExpectedQuantity, ICOutboxSalesLine.Quantity, '');
    end;

    local procedure VerifyHandledICOutboxSalesLineDescription2(HandledICOutboxTrans: Record "Handled IC Outbox Trans."; ICPartnerRefType: Enum "IC Partner Reference Type"; ICPartnerReference: Code[20]; ExpectedDescription2: Text[50])
    var
        HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line";
    begin
        HandledICOutboxSalesLine.SetRange("IC Transaction No.", HandledICOutboxTrans."Transaction No.");
        HandledICOutboxSalesLine.SetRange("IC Partner Code", HandledICOutboxTrans."IC Partner Code");
        HandledICOutboxSalesLine.SetRange("Transaction Source", HandledICOutboxTrans."Transaction Source");
        HandledICOutboxSalesLine.SetRange("IC Partner Ref. Type", ICPartnerRefType);
        HandledICOutboxSalesLine.SetRange("IC Partner Reference", ICPartnerReference);
        HandledICOutboxSalesLine.FindFirst();
        HandledICOutboxSalesLine.TestField("Description 2", ExpectedDescription2);
    end;

    local procedure VerifyHandledICOutboxPurchLineDescription2(HandledICOutboxTrans: Record "Handled IC Outbox Trans."; ICPartnerRefType: Enum "IC Partner Reference Type"; ICPartnerReference: Code[20]; ExpectedDescription2: Text[50])
    var
        HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line";
    begin
        HandledICOutboxPurchLine.SetRange("IC Transaction No.", HandledICOutboxTrans."Transaction No.");
        HandledICOutboxPurchLine.SetRange("IC Partner Code", HandledICOutboxTrans."IC Partner Code");
        HandledICOutboxPurchLine.SetRange("Transaction Source", HandledICOutboxTrans."Transaction Source");
        HandledICOutboxPurchLine.SetRange("IC Partner Ref. Type", ICPartnerRefType);
        HandledICOutboxPurchLine.SetRange("IC Partner Reference", ICPartnerReference);
        HandledICOutboxPurchLine.FindFirst();
        HandledICOutboxPurchLine.TestField("Description 2", ExpectedDescription2);
    end;

    local procedure VerifyICOutboxSalesLineTypeAndNoByLineNo(ICOutboxTransaction: Record "IC Outbox Transaction"; LineNo: Integer; ExpICPartnerRefType: Enum "IC Partner Reference Type"; ExpICPartnerReference: Code[20]; ExpDescription: Text[100])
    var
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
    begin
        ICOutboxSalesLine.SetRange("IC Transaction No.", ICOutboxTransaction."Transaction No.");
        ICOutboxSalesLine.SetRange("IC Partner Code", ICOutboxTransaction."IC Partner Code");
        ICOutboxSalesLine.SetRange("Transaction Source", ICOutboxTransaction."Transaction Source");
        ICOutboxSalesLine.SetRange("Line No.", LineNo);
        ICOutboxSalesLine.FindFirst();

        ICOutboxSalesLine.TestField("IC Partner Ref. Type", ExpICPartnerRefType);
        ICOutboxSalesLine.TestField("IC Partner Reference", ExpICPartnerReference);
        ICOutboxSalesLine.TestField(Description, ExpDescription);
    end;

    local procedure CreateItemJournalLinePositiveAdjustment(ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndRegisterPick(ItemNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
        WarehouseShipmentHeader."Shipping No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseShipmentHeader.Modify(true);

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        LibraryWarehouse.AutofillQtyToShipWhseShipment(WarehouseShipmentHeader);

        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader."Registering No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseActivityHeader.Modify(true);

        CODEUNIT.Run(CODEUNIT::"Whse.-Activity-Register", WarehouseActivityLine);
    end;

    local procedure PostWarehouseShipmentLine(SalesHeaderNo: Code[20]; SalesLineLineNo: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source No.", SalesHeaderNo);
        WarehouseShipmentLine.SetRange("Source Line No.", SalesLineLineNo);
        WarehouseShipmentLine.FindFirst();
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Shipment", WarehouseShipmentLine);
    end;

    local procedure UpdateNoSeries()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup."Whse. Ship Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup."Whse. Pick Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseSetup.Modify(true);
    end;

    local procedure VerifySalesOrder(PurchaseHeader: Record "Purchase Header"; LineDiscount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Document Type", PurchaseHeader."Document Type");
        SalesHeader.SetRange("External Document No.", PurchaseHeader."No.");
        Assert.RecordIsNotEmpty(SalesHeader);
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Line Discount %", LineDiscount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ComfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerEnqueueQuestion(Question: Text; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
        LibraryVariableStorage.Enqueue(Question);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ICSetupPageHandler(var ICSetup: TestPage "Intercompany Setup")
    begin
        ICSetup.Cancel().Invoke();
    end;

    [PageHandler]
    procedure GLPostingPreviewPageHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.Close();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSendICDocument', '', false, false)]
    local procedure OnBeforeSendICDocument(var SalesHeader: Record "Sales Header"; var ModifyHeader: Boolean; var IsHandled: Boolean)
    begin
        Error('OnBeforeSendICDocument should not be called');
    end;

    [EventSubscriber(ObjectType::Page, Page::"IC Dimensions Selector", 'OnBeforeSelectingDimensions', '', false, false)]
    local procedure OnBeforeSelectingDimensions(var IsHandled: Boolean; var Dimension: Record Dimension)
    begin
        IsHandled := true;
        Dimension.Reset();
    end;
}

