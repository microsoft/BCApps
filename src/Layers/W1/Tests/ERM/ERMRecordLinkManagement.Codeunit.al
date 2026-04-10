codeunit 134074 "ERM Record Link Management"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Record Link]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        RecordLinkCountErr: Label 'The only one record link expected';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithNotification()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375015] Posted Sales Order with notification to a user produces record links without notification flag
        Initialize();

        // [GIVEN] Sales Order with notification note ("Record Link".Notify = TRUE)
        CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(SalesHeader, true);

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Sales Invoice has a note without notification ("Record Link".Notify = FALSE)
        FindSalesInvoiceHeader(SalesInvoiceHeader, SalesHeader);
        VerifyNotificationOnRecordLink(SalesInvoiceHeader);
        // [THEN] Posted Sales Shipment has a note without notification ("Record Link".Notify = FALSE)
        FindSalesShipmentHeader(SalesShipmentHeader, SalesHeader);
        VerifyNotificationOnRecordLink(SalesShipmentHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 375015] Posted Purchase Order with notification to a user produces record link without notification flag
        Initialize();

        // [GIVEN] Purchase Order with notification note ("Record Link".Notify = TRUE)
        CreatePurchaseOrder(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(PurchaseHeader, true);

        // [WHEN] Post Purchase Order
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posted Purchase Invoice has a note without notification ("Record Link".Notify = FALSE)
        FindPurchaseInvoiceHeader(PurchInvHeader, PurchaseHeader);
        VerifyNotificationOnRecordLink(PurchInvHeader);
        // [THEN] Posted Purchase Receipt has a note without notification ("Record Link".Notify = FALSE)
        FindPurchaseReceiptHeader(PurchRcptHeader, PurchaseHeader);
        VerifyNotificationOnRecordLink(PurchRcptHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithNotification()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 375015] Posted Service Order with notification to a user produces record link without notification flag
        Initialize();

        // [GIVEN] Service Order with notification note ("Record Link".Notify = TRUE)
        UpdateServiceMgtSetup(true, true);
        CreateServiceOrder(ServiceHeader, ServiceHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(ServiceHeader, true);

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posted Service Invoice has a note without notification ("Record Link".Notify = FALSE)
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader);
        VerifyNotificationOnRecordLink(ServiceInvoiceHeader);

        // [THEN] Posted Service Shipment has a note without notification ("Record Link".Notify = FALSE)
        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader);
        VerifyNotificationOnRecordLink(ServiceShipmentHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchiveSalesOrderWithNotification()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375015] Archived Sales Order with notification to a user produces record links without notification flag
        Initialize();

        // [GIVEN] Sales Order with notification note ("Record Link".Notify = TRUE)
        CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(SalesHeader, true);

        // [WHEN] Archive Sales Order
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);

        // [THEN] Archived Sales Order has a note without notification ("Record Link".Notify = FALSE)
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeader);
        VerifyNotificationOnRecordLink(SalesHeaderArchive);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivePurchaseOrderWithNotification()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 375015] Archived Purchase Order with notification to a user produces record link without notification flag
        Initialize();

        // [GIVEN] Purchase Order with notification note ("Record Link".Notify = TRUE)
        CreatePurchaseOrder(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(PurchaseHeader, true);

        // [WHEN] Archive Purchase Order
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);

        // [THEN] Archived Purchase Order has a note without notification ("Record Link".Notify = FALSE)
        FindPurchaseHeaderArchive(PurchaseHeaderArchive, PurchaseHeader);
        VerifyNotificationOnRecordLink(PurchaseHeaderArchive);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure RestoreSalesDocumentFromArchiveWithNotification()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 375015] Restored from archive Sales Order with notification to a user produces record link without notification flag
        Initialize();

        // [GIVEN] Sales Order with notification note ("Record Link".Notify = TRUE)
        CreateSalesOrder(SalesHeader, SalesHeader."Document Type"::Order);
        SetupNotificationOnRecordLink(SalesHeader, true);

        // [GIVEN] Archived Sales Order with note having notification flag
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeader);
        SetupNotificationOnRecordLink(SalesHeaderArchive, true);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] Restore Sales Order
        ArchiveManagement.RestoreSalesDocument(SalesHeaderArchive);

#pragma warning disable AA0181
        // Find() or Find('=') does not have to be used in combination with Next since it returns only one record
        SalesHeader.Find();
#pragma warning restore AA0181

        // [THEN] Restored Sales Order has a note without notification ("Record Link".Notify = FALSE)
        VerifyNotificationOnRecordLink(SalesHeader);
    end;

    [Test]
    procedure RecordLinkCopiedFromGenJnlLineToGLEntryOnPosting()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLAccNo: array[2] of Code[20];
    begin
        // [FEATURE] [General Journal] [General Ledger]
        // [SCENARIO] Record links are copied from a gen. journal line into general ledger entries on journal posting

        Initialize();

        GLAccNo[1] := LibraryERM.CreateGLAccountNo();
        GLAccNo[2] := LibraryERM.CreateGLAccountNo();

        // [GIVEN] General journal line with a record link assigned
        CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJnlLine."Account Type"::"G/L Account", GLAccNo[1], GenJnlLine."Bal. Account Type"::"G/L Account", GLAccNo[2]);

        LibraryUtility.CreateRecordLink(GenJnlLine);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] Record link has been copied to G/L entries
        VerifyGLEntryRecordLink(GLAccNo[1]);
        VerifyGLEntryRecordLink(GLAccNo[2]);
    end;

    [Test]
    procedure RecordLinkCopiedFromGenJnlLineToCustLedgerEntryOnPosting()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLAccNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [General Journal] [Customer Ledger Entry]
        // [SCENARIO] Record links are copied from a gen. journal line into customer ledger entries on journal posting

        Initialize();

        GLAccNo := LibraryERM.CreateGLAccountNo();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Gen. journal line with a customer as a balancing account. Record link is assigned to the line
        CreateGeneralJnlLineWithBalAcc(GenJnlLine, GenJnlLine."Account Type"::"G/L Account", GLAccNo, GenJnlLine."Bal. Account Type"::Customer, CustomerNo);
        LibraryUtility.CreateRecordLink(GenJnlLine);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] Record link has been copied to the customer ledger entry
        VerifyGLEntryRecordLink(GLAccNo);
        VerifyCustLedgerEntryRecordLink(CustomerNo);
    end;

    [Test]
    procedure RecordLinkCopiedFromGenJnlLineToVendorAndBankLedgerEntryOnPosting()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [General Journal] [Vendor Ledger Entry] [Bank Account Ledger Entry]
        // [SCENARIO] Record links are copied from a gen. journal line into vendor ledger entries and bank acc. ledger entries on journal posting

        Initialize();

        BankAccNo := LibraryERM.CreateBankAccountNo();
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Gen. journal line with a vendor account and bank account as a balancing account.
        CreateGeneralJnlLineWithBalAcc(GenJnlLine, GenJnlLine."Account Type"::Vendor, VendorNo, GenJnlLine."Bal. Account Type"::"Bank Account", BankAccNo);

        // [GIVEN] Assign a record link to the journal line
        LibraryUtility.CreateRecordLink(GenJnlLine);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] Record link has been copied to both vendor ledge entry and bank account ledger entry
        VerifyVendorLedgerEntryRecordLink(VendorNo);
        VerifyBankAccLedgerEntryRecordLink(BankAccNo);
    end;

    [Test]
    procedure RecordLinkCopiedFromGenJnlLineToFALedgerEntryOnPosting()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DepreciationBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        BankAccNo: Code[20];
    begin
        // [FEATURE] [General Journal] [FA Ledger Entry]
        // [SCENARIO] Record links are copied from a gen. journal line into FA ledger entries on journal posting

        Initialize();

        // [GIVEN] Fixed asset "FA1" with integration of acquisition cost to G/L enabled
        // [GIVEN] Acquisition cost G/L account in the FA posting group is "10000"
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Modify(true);

        LibraryFixedAsset.CreateFADepreciationBook(FADeprBook, FixedAsset."No.", DepreciationBook.Code);
        FADeprBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADeprBook.Modify(true);

        BankAccNo := LibraryERM.CreateBankAccountNo();

        // [GIVEN] Create a general journal line with FA acquisition posting type for the asset "FA1"
        CreateGeneralJnlLineWithBalAcc(GenJnlLine, GenJnlLine."Account Type"::"Fixed Asset", FixedAsset."No.", GenJnlLine."Bal. Account Type"::"Bank Account", BankAccNo);
        GenJnlLine.Validate("FA Posting Type", Enum::"Gen. Journal Line FA Posting Type"::"Acquisition Cost");
        GenJnlLine.Validate("Depreciation Book Code", DepreciationBook.Code);
        GenJnlLine.Modify(true);

        // [GIVEN] Assign a record link to the journal line
        LibraryUtility.CreateRecordLink(GenJnlLine);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] Record link is copied to the FA ledger entry and the G/L entry on the acquisition account "10000"
        VerifyBankAccLedgerEntryRecordLink(BankAccNo);
        VerifyFALedgerEntryRecordLink(FixedAsset."No.");

        FAPostingGroup.Get(FixedAsset."FA Posting Group");
        VerifyGLEntryRecordLink(FAPostingGroup."Acquisition Cost Account");
    end;

    [Test]
    procedure RecordLinkCopiedFromGenJnlLineToEmployeeLedgerEntryOnPosting()
    var
        GenJnlLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        BankAccNo: Code[20];
    begin
        // [FEATURE] [General Journal] [Employee Ledger Entry]
        // [SCENARIO] Record links are copied from a gen. journal line into employee ledger entries on journal posting

        Initialize();

        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount();
        BankAccNo := LibraryERM.CreateBankAccountNo();

        // [GIVEN] Gen. journal line with an employee account and a record link assigned
        CreateGeneralJnlLineWithBalAcc(GenJnlLine, GenJnlLine."Account Type"::Employee, EmployeeNo, GenJnlLine."Bal. Account Type"::"Bank Account", BankAccNo);
        LibraryUtility.CreateRecordLink(GenJnlLine);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] Record link has been copied to the employee ledger entry
        VerifyEmployeeLedgerEntryRecordLink(EmployeeNo);
        VerifyBankAccLedgerEntryRecordLink(BankAccNo);
    end;

    [Test]
    procedure RecordLinkCopiedFromGenJnlLineToPostedGenJnlLineOnPosting()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlTemplate: Record "Gen. Journal Template";
        GLAccNo: Code[20];
    begin
        // [SCENARIO] Record links are copied from a general journal line into the posted gen. journal line on journal posting

        Initialize();

        // [GIVEN] General journal line in the template "T"
        GLAccNo := LibraryERM.CreateGLAccountNo();
        CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJnlLine."Account Type"::"G/L Account", GLAccNo, GenJnlLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo());

        // [GIVEN] Enable copying posted journal lines for the template "T"
        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        GenJnlTemplate.Validate("Copy to Posted Jnl. Lines", true);
        GenJnlTemplate.Modify(true);

        // [GIVEN] Assign a record link to the journal line
        LibraryUtility.CreateRecordLink(GenJnlLine);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] The record link has been copied to the posted journal line
        VerifyPostedGenJnlLineRecordLink(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Account Type", GLAccNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Record Link Management");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Record Link Management");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Service Mgt. Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Record Link Management");
    end;

    local procedure CreateGeneralJnlLineWithBalAcc(
        var GenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20];
        BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::" ", AccountType, AccountNo, BalAccountType, BalAccountNo, LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryInventory.CreateItem(Item);
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ServiceItem."Item No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        ServiceLine.Modify(true);
    end;

    local procedure FindSalesInvoiceHeader(var SalesInvoiceHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header")
    begin
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();
    end;

    local procedure FindSalesShipmentHeader(var SalesShipmentHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header")
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();
    end;

    local procedure FindSalesHeaderArchive(var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    begin
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst();
    end;

    local procedure FindPurchaseInvoiceHeader(var PurchInvHeader: Record "Purch. Inv. Header"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchInvHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvHeader.FindFirst();
    end;

    local procedure FindPurchaseReceiptHeader(var PurchRcptHeader: Record "Purch. Rcpt. Header"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchRcptHeader.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchRcptHeader.FindFirst();
    end;

    local procedure FindPurchaseHeaderArchive(var PurchaseHeaderArchive: Record "Purchase Header Archive"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.FindFirst();
    end;

    local procedure FindServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    begin
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure FindServiceShipmentHeader(var ServiceShipmentHeader: Record "Service Shipment Header"; ServiceHeader: Record "Service Header")
    begin
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceShipmentHeader.FindFirst();
    end;

    local procedure SetupNotificationOnRecordLink(SourceRecord: Variant; NewNotification: Boolean)
    var
        RecordLink: Record "Record Link";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SourceRecord);
        RecRef.AddLink(LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        RecordLink.SetRange("Record ID", RecRef.RecordId);
        RecordLink.FindFirst();
        RecordLink.Notify := NewNotification;
        RecordLink."To User ID" := UserId;
        RecordLink.Modify();
    end;

    local procedure UpdateServiceMgtSetup(CopyCommentsToInvoice: Boolean; CopyCommentsToShipment: Boolean)
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup."Copy Comments Order to Invoice" := CopyCommentsToInvoice;
        ServiceMgtSetup."Copy Comments Order to Shpt." := CopyCommentsToShipment;
        ServiceMgtSetup.Modify();
    end;

    local procedure VerifyNotificationOnRecordLink(RecVar: Variant)
    var
        RecordLink: Record "Record Link";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        RecordLink.SetRange("To User ID", UserId);
        RecordLink.SetRange("Record ID", RecRef.RecordId);
        RecordLink.FindFirst();

        Assert.AreEqual(1, RecordLink.Count, RecordLinkCountErr);
    end;

    local procedure VerifyBankAccLedgerEntryRecordLink(AccountNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        VerifyRecordLink(Database::"Bank Account Ledger Entry", BankAccountLedgerEntry.FieldNo("Bank Account No."), AccountNo);
    end;

    local procedure VerifyCustLedgerEntryRecordLink(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        VerifyRecordLink(Database::"Cust. Ledger Entry", CustLedgerEntry.FieldNo("Customer No."), CustomerNo);
    end;

    local procedure VerifyEmployeeLedgerEntryRecordLink(EmployeeNo: Code[20])
    var
        EmplyeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        VerifyRecordLink(Database::"Employee Ledger Entry", EmplyeeLedgerEntry.FieldNo("Employee No."), EmployeeNo);
    end;

    local procedure VerifyFALedgerEntryRecordLink(FANo: Code[20])
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        VerifyRecordLink(Database::"FA Ledger Entry", FALedgerEntry.FieldNo("FA No."), FANo);
    end;

    local procedure VerifyGLEntryRecordLink(AccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        VerifyRecordLink(Database::"G/L Entry", GLEntry.FieldNo("G/L Account No."), AccountNo);
    end;

    local procedure VerifyVendorLedgerEntryRecordLink(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VerifyRecordLink(Database::"Vendor Ledger Entry", VendorLedgerEntry.FieldNo("Vendor No."), VendorNo);
    end;

    local procedure VerifyPostedGenJnlLineRecordLink(TemplateName: Code[10]; BatchName: Code[10]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        PostedGenJnlLine: Record "Posted Gen. Journal Line";
        RecordLink: Record "Record Link";
    begin
        PostedGenJnlLine.SetRange("Journal Template Name", TemplateName);
        PostedGenJnlLine.SetRange("Journal Batch Name", BatchName);
        PostedGenJnlLine.SetRange("Account Type", AccountType);
        PostedGenJnlLine.SetRange("Account No.", AccountNo);
        PostedGenJnlLine.FindFirst();

        RecordLink.SetRange("Record ID", PostedGenJnlLine.RecordId());
        Assert.RecordCount(RecordLink, 1);
    end;

    local procedure VerifyRecordLink(TableNo: Integer; FieldNo: Integer; EntityNo: Code[20])
    var
        RecordLink: Record "Record Link";
        RecRef: RecordRef;
        FilterFildRef: FieldRef;
    begin
        RecRef.Open(TableNo);
        FilterFildRef := RecRef.Field(FieldNo);
        FilterFildRef.SetRange(EntityNo);
        RecRef.FindFirst();

        RecordLink.SetRange("Record ID", RecRef.RecordId());
        Assert.RecordCount(RecordLink, 1);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

