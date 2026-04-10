codeunit 134200 "Document Approval - Errors"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = rimd,
                  TableData Workflow = rimd,
                  TableData "Workflow Step" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Approval]
        isInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        isInitialized: Boolean;
        BothApprovalLimitErr: Label 'You cannot have both a %1 and %2. ', Comment = '%1 = Field Caption %2 = Field Caption';
        DocumentMustBeApprovedAndReleasedErr: Label '%1 %2 must be approved and released before you can perform this action.', Comment = '%1 = Document Type Value %2 = Document No. Value';
        SalespersPurchCodeErr: Label 'The salesperson/purchaser user ID  does not exist in the Approval User Setup window for Salespers./Purch. Code .';
        SubstituteErr: Label 'There is no substitute, direct approver, or approval administrator for user ID %1 in the Approval User Setup window.', Comment = 'There is no substitute for user ID NAVUser in the User Setup window.';
        NoSuitableApproverFoundErr: Label 'No qualified approver was found.', Comment = 'Approval user ID NAVUser does not exist in the User Setup table.';
        VendorRestrictionErr: Label 'You cannot use Vendor: %1 for this action.', Comment = '%1 = Buy-from Vendor No.';
        CustomerRestrictionErr: Label 'You cannot use Customer: %1 for this action.', Comment = '%1 = Sell to Customer No';
        ItemRestrictionErr: Label 'You cannot use Item: %1 for this action.', Comment = '%1 = Item No';
        DelegateOnlyOpenRequestsErr: Label 'You can only delegate open approval requests.';
        ApproveOnlyOpenRequestsErr: Label 'You can only approve open approval requests.';
        RejectOnlyOpenRequestsErr: Label 'You can only reject open approval entries.';
        ApproverChainErr: Label 'No sufficient approver was found in the approver chain.';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostOpenedPurchaseCreditMemoError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PostOpenedPurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostOpenedPurchaseInvoiceError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PostOpenedPurchaseDocument(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceOnBuyFromVendorRestrictionError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 380033] Post Purchase Invoice if restriction for Vendor record exists
        Initialize();

        // [GIVEN] Purchase Invoice "PI" with "Buy-from Vendor No." = "V1"
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);

        // [GIVEN] Vendor "V1" has restriction.
        SetRestrictionToVendor(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Post Purchase Invoice "PI"
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error is thrown "You cannot use Vendor: "V1" for this action."
        Assert.ExpectedError(StrSubstNo(VendorRestrictionErr, PurchaseHeader."Buy-from Vendor No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceOnPayToVendorRestrictionError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 380033] Post Purchase Invoice if restriction for Vendor record exists
        Initialize();

        // [GIVEN] Purchase Invoice "PI" with "Buy-from Vendor No." = "V1", "Pay-to Vendor No." = "V2"
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.Validate("Pay-to Vendor No.", LibraryPurchase.CreateVendorNo());

        // [GIVEN] Vendor "V2" has restriction.
        SetRestrictionToVendor(PurchaseHeader."Pay-to Vendor No.");

        // [WHEN] Post Purchase Invoice "PI"
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error is thrown "You cannot use Vendor: "V2" for this action."
        Assert.ExpectedError(StrSubstNo(VendorRestrictionErr, PurchaseHeader."Pay-to Vendor No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceOnSellToCustRestrictionError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 380033] Post Sales Invoice if restriction for Customer record exists
        Initialize();

        // [GIVEN] Sales Invoice "SI" with "Sell-to Customer No." = "C1"
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] Customer "C1" has restriction.
        SetRestrictionToCustomer(SalesHeader."Sell-to Customer No.");

        // [WHEN] Post Sales Invoice "SI"
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Error is thrown "You cannot use Customer: "C1" for this action."
        Assert.ExpectedError(StrSubstNo(CustomerRestrictionErr, SalesHeader."Sell-to Customer No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceOnBillToCustRestrictionError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 380033] Post Sales Invoice if restriction for Customer record exists
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        // [GIVEN] Sales Invoice "SI" with "Sell-to Customer No." = "C1", "Bill-to Customer No." = "C2"
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [GIVEN] Customer "C2" has restriction.
        SalesHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        SetRestrictionToCustomer(SalesHeader."Bill-to Customer No.");

        // [WHEN] Post Sales Invoice "SI"
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Error is thrown "You cannot use Customer: "C2" for this action."
        Assert.ExpectedError(StrSubstNo(CustomerRestrictionErr, SalesHeader."Bill-to Customer No."));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostOpenedPurchaseOrderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PostOpenedPurchaseDocument(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostOpenedPurchaseReturnOrderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PostOpenedPurchaseDocument(PurchaseHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostOpenedSalesCreditMemoError()
    var
        SalesHeader: Record "Sales Header";
    begin
        PostOpenedSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostOpenedSalesInvoiceError()
    var
        SalesHeader: Record "Sales Header";
    begin
        PostOpenedSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostOpenedSalesOrderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        PostOpenedSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostOpenedSalesReturnOrderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        PostOpenedSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseAmountApprovalLimitWithUnlimitedError()
    var
        UserSetup: Record "User Setup";
    begin
        // Setup
        Initialize();
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, '');
        LibraryDocumentApprovals.UpdateApprovalLimits(UserSetup, false, true, false, 0, 0, 0);

        // Exercise
        asserterror UserSetup.Validate("Purchase Amount Approval Limit", LibraryRandom.RandInt(100));

        // Verify
        Assert.ExpectedError(StrSubstNo(BothApprovalLimitErr, UserSetup.FieldCaption("Purchase Amount Approval Limit"),
            UserSetup.FieldCaption("Unlimited Purchase Approval")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderBeyondApprovalLimitError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentBeyondApprovalLimit(PurchaseHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderNoWorkflow()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentApproval(PurchaseHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderWithPurchaserCodeError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithDifferentPurchaserCode(PurchHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderWithSubstituteError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithoutSubstitute(PurchHeader."Document Type"::"Blanket Order")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoBeyondApprovaLimitlError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentBeyondApprovalLimit(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoNoWorkflow()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentApproval(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithPurchaserCodeError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithDifferentPurchaserCode(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithSubstituteError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithoutSubstitute(PurchHeader."Document Type"::"Credit Memo")
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceBeyondApprovalLimitError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentBeyondApprovalLimit(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceNoWorkflow()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentApproval(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithPurchaserCodeError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithDifferentPurchaserCode(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithSubstituteError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithoutSubstitute(PurchHeader."Document Type"::Invoice)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderBeyondApprovalLimitError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentBeyondApprovalLimit(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderNoWorkflow()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentApproval(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPurchaserCodeError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithDifferentPurchaserCode(PurchHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithSubstituteError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithoutSubstitute(PurchHeader."Document Type"::Order)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteBeyondApprovalLimitError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentBeyondApprovalLimit(PurchaseHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteNoWorkflow()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentApproval(PurchaseHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteWithPurchaserCodeError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithDifferentPurchaserCode(PurchHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteWithSubstituteError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithoutSubstitute(PurchHeader."Document Type"::Quote)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderBeyondApprovalLimitError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentBeyondApprovalLimit(PurchaseHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrdeNoWorkflow()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseDocumentApproval(PurchaseHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderPurchaserCodeError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithDifferentPurchaserCode(PurchHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderWithSubstituteError()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchaseDocumentWithoutSubstitute(PurchHeader."Document Type"::"Return Order")
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestAmountApprovalLimitWithUnlimitedError()
    var
        UserSetup: Record "User Setup";
    begin
        // Setup
        Initialize();
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, '');
        LibraryDocumentApprovals.UpdateApprovalLimits(UserSetup, false, false, true, 0, 0, 0);

        // Exercise
        asserterror UserSetup.Validate("Request Amount Approval Limit", LibraryRandom.RandInt(100));

        // Verify
        Assert.ExpectedError(StrSubstNo(BothApprovalLimitErr, UserSetup.FieldCaption("Request Amount Approval Limit"),
            UserSetup.FieldCaption("Unlimited Request Approval")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesAmountApprovalLimitWithUnlimitedError()
    var
        UserSetup: Record "User Setup";
    begin
        // Setup
        Initialize();
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, '');
        LibraryDocumentApprovals.UpdateApprovalLimits(UserSetup, true, false, false, 0, 0, 0);

        // Exercise
        asserterror UserSetup.Validate("Sales Amount Approval Limit", LibraryRandom.RandInt(100));

        // Verify
        Assert.ExpectedError(StrSubstNo(BothApprovalLimitErr, UserSetup.FieldCaption("Sales Amount Approval Limit"),
            UserSetup.FieldCaption("Unlimited Sales Approval")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderBeyondApprovalLimitError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentBeyondApprovalLimit(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderNoWorkflow()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentApproval(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderWithSalesPersonCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithDifferentSalesPersonCode(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderWithSubstituteError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithoutSubstitute(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoBeyondApprovalLimitError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentBeyondApprovalLimit(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoNoWorkflow()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentApproval(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithSalesPersonCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithDifferentSalesPersonCode(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithSubstituteError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithoutSubstitute(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceBeyondApprovalLimitError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentBeyondApprovalLimit(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceNoWorkflow()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentApproval(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithSalesPersonCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithDifferentSalesPersonCode(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithSubstituteError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithoutSubstitute(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderBeyondApprovalLimitError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentBeyondApprovalLimit(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderNoWorkflow()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentApproval(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithSalesPersonCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithDifferentSalesPersonCode(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithSubstituteError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithoutSubstitute(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteBeyondApprovalLimitError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentBeyondApprovalLimit(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteNoWorkflow()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentApproval(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteWithSalesPersonCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithDifferentSalesPersonCode(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteWithSubstituteError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithoutSubstitute(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderBeyondApprovalLimitError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentBeyondApprovalLimit(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderNoWorkflow()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentApproval(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderWithSalesPersonCodeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithDifferentSalesPersonCode(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderWithSubstituteError()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesDocumentWithoutSubstitute(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPmtOnVendorRestriction()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 380230] Post Payment to Vendor when restriction for Vendor record exists
        Initialize();

        // [GIVEN] Payment where "Account Type" = Vendor and "Account No." = "V1"
        GenJournalLine.Init();
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Vendor "V1" has restriction.
        SetRestrictionToVendor(GenJournalLine."Account No.");

        // [WHEN] Check post restriction
        asserterror RecordRestrictionMgt.VendorCheckGenJournalLinePostRestrictions(GenJournalLine);

        // [THEN] Error is thrown "You cannot use Vendor: "V1" for this action."
        Assert.ExpectedError(StrSubstNo(VendorRestrictionErr, GenJournalLine."Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorAsBalanceAccountPmtOnVendorRestriction()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 380230] Post Payment to Vendor as balance account when restriction for Vendor record exists
        Initialize();

        // [GIVEN] Payment where "Bal. Account Type" = Vendor and "Bal. Account No." = "V1"
        GenJournalLine.Init();
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Vendor;
        GenJournalLine."Bal. Account No." := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Vendor "V1" has restriction.
        SetRestrictionToVendor(GenJournalLine."Bal. Account No.");

        // [WHEN] Check post restriction
        asserterror RecordRestrictionMgt.VendorCheckGenJournalLinePostRestrictions(GenJournalLine);

        // [THEN] Error is thrown "You cannot use Vendor: "V1" for this action."
        Assert.ExpectedError(StrSubstNo(VendorRestrictionErr, GenJournalLine."Bal. Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPmtOnCustomerRestriction()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 380230] Post Payment from Customer when restriction for Customer record exists
        Initialize();

        // [GIVEN] Payment where "Account Type" = Customer and "Account No." = "C1"
        GenJournalLine.Init();
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := LibrarySales.CreateCustomerNo();

        // [GIVEN] Customer "C1" has restriction.
        SetRestrictionToCustomer(GenJournalLine."Account No.");

        // [WHEN] Check post restriction
        asserterror RecordRestrictionMgt.CustomerCheckGenJournalLinePostRestrictions(GenJournalLine);

        // [THEN] Error is thrown "You cannot use Customer: "C1" for this action."
        Assert.ExpectedError(StrSubstNo(CustomerRestrictionErr, GenJournalLine."Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerAsBalanceAccountPmtOnCustomerRestriction()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 380230] Post Payment from Customer as Balance Account when restriction for Customer record exists
        Initialize();

        // [GIVEN] Payment where "Bal. Account Type" = Customer and "Bal. Account No." = "C1"
        GenJournalLine.Init();
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Customer;
        GenJournalLine."Bal. Account No." := LibrarySales.CreateCustomerNo();

        // [GIVEN] Customer "C1" has restriction.
        SetRestrictionToCustomer(GenJournalLine."Bal. Account No.");

        // [WHEN] Check post restriction
        asserterror RecordRestrictionMgt.CustomerCheckGenJournalLinePostRestrictions(GenJournalLine);

        // [THEN] Error is thrown "You cannot use Customer: "C1" for this action."
        Assert.ExpectedError(StrSubstNo(CustomerRestrictionErr, GenJournalLine."Bal. Account No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPmtIfVendorNotExist()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 380230] Post Payment to Vendor when Vendor record does not exists
        Initialize();

        // [GIVEN] Vendor "V1" does not exist
        // [GIVEN] Payment where "Account Type" = Vendor and "Account No." = "V1"
        GenJournalLine.Init();
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Vendor;
        GenJournalLine."Account No." := LibraryUtility.GenerateGUID();

        // [WHEN] Check post restriction
        asserterror RecordRestrictionMgt.VendorCheckGenJournalLinePostRestrictions(GenJournalLine);

        // [THEN] Error is thrown "The Vendor does not exist. Identification fields and values: No.='V1'"
        Assert.ExpectedErrorCannotFind(Database::Vendor, GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorAsBalanceAccountPmtIfVendorNotExist()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 380230] Post Payment to Vendor as balance account when Vendor record does not exists
        Initialize();

        // [GIVEN] Vendor "V1" does not exist
        // [GIVEN] Payment where "Bal. Account Type" = Vendor and "Bal. Account No." = "V1"
        GenJournalLine.Init();
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Vendor;
        GenJournalLine."Bal. Account No." := LibraryUtility.GenerateGUID();

        // [WHEN] Check post restriction
        asserterror RecordRestrictionMgt.VendorCheckGenJournalLinePostRestrictions(GenJournalLine);

        // [THEN] Error is thrown "The Vendor does not exist. Identification fields and values: No.='V1'"
        Assert.ExpectedErrorCannotFind(Database::Vendor, GenJournalLine."Bal. Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPmtIfCustomerNotExist()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 380230] Post Payment from Customer when Customer record does not exists
        Initialize();

        // [GIVEN] Customer "C1" does not exist
        // [GIVEN] Payment where "Account Type" = Customer and "Account No." = "C1"
        GenJournalLine.Init();
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := LibraryUtility.GenerateGUID();

        // [WHEN] Check post restriction
        asserterror RecordRestrictionMgt.CustomerCheckGenJournalLinePostRestrictions(GenJournalLine);

        // [THEN] Error is thrown "The Customer does not exist. Identification fields and values: No.='C1'"
        Assert.ExpectedErrorCannotFind(Database::Customer, GenJournalLine."Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerAsBalanceAccountPmtIfCustomerNotExist()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 380230] Post Payment from Customer as Balance Account when Customer record does not exists
        Initialize();

        // [GIVEN] Customer "C1" does not exist
        // [GIVEN] Payment where "Bal. Account Type" = Customer and "Bal. Account No." = "C1"
        GenJournalLine.Init();
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Customer;
        GenJournalLine."Bal. Account No." := LibraryUtility.GenerateGUID();

        // [WHEN] Check post restriction
        asserterror RecordRestrictionMgt.CustomerCheckGenJournalLinePostRestrictions(GenJournalLine);

        // [THEN] Error is thrown "The Customer does not exist. Identification fields and values: No.='C1'"
        Assert.ExpectedErrorCannotFind(Database::Customer, GenJournalLine."Bal. Account No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotApproveIfApprovalRequestIsNotOpen()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 379900] User cannot approve approval entry with status <> Open

        // [GIVEN] Mock Rejected Approval Entry;
        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := DATABASE::"Sales Header";
        ApprovalEntry.Status := ApprovalEntry.Status::Rejected;
        ApprovalEntry.Insert();

        // [WHEN] Approve approval request
        asserterror ApprovalsMgmt.ApproveApprovalRequests(ApprovalEntry);

        // [THEN] Error occurs: "You can only approve open approval requests."
        Assert.ExpectedError(ApproveOnlyOpenRequestsErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotRejectIfApprovalRequestIsNotOpen()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 379900] User cannot reject approval entry with status <> Open

        // [GIVEN] Approval Entry with Status <> Open
        ApprovalEntry.Init();
        ApprovalEntry."Table ID" := DATABASE::"Sales Header";
        ApprovalEntry.Status := ApprovalEntry.Status::Rejected;
        ApprovalEntry.Insert();

        // [WHEN] Reject approval request
        asserterror ApprovalsMgmt.RejectApprovalRequests(ApprovalEntry);

        // [THEN] Error occurs: "You can only reject open approval entries."
        Assert.ExpectedError(RejectOnlyOpenRequestsErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CannotDelegateIfApprovalRequestIsNotOpen()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [SCENARIO 379900] User cannot delegate approval entry with status <> Open

        // [GIVEN] Approval Entry with Status <> Open
        ApprovalEntry.Init();
        ApprovalEntry.Status := ApprovalEntry.Status::Rejected;
        ApprovalEntry.Insert();

        // [WHEN] Delegate approval request
        asserterror ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // [THEN] Error occurs: "You can only delegate open approval requests."
        Assert.ExpectedError(DelegateOnlyOpenRequestsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemJournalPostOnItemRestriction()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 206308] Post Item Journal when restriction for Item exists
        Initialize();

        // [GIVEN] Item Journal Line with Item "I"
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Item "I" has restriction.
        SetRestrictionToItem(ItemJournalLine."Item No.");

        // [WHEN] Post Item Journal
        asserterror LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // [THEN] Error is thrown "You cannot use Item: "I" for this action."
        Assert.ExpectedError(StrSubstNo(ItemRestrictionErr, ItemJournalLine."Item No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPostOnItemRestriction()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 206308] Post Sales Order when restriction for Item exists
        Initialize();

        // [GIVEN] Sales Order with item "I"
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Item "I" has restriction.
        SetRestrictionToItem(SalesLine."No.");

        // [WHEN] Post Sales Order
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Error is thrown "You cannot use Item: "I" for this action."
        Assert.ExpectedError(StrSubstNo(ItemRestrictionErr, SalesLine."No."));
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPostPreviewOnItemRestriction()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 206308] Preview Posting for Sales Order when restriction for Item exists
        Initialize();

        // [GIVEN] Sales Order with item "I"
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Order);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesHeader.Validate(Ship, true);
        SalesHeader.Validate(Invoice, true);
        SalesHeader.Modify(true);

        // [GIVEN] Item "I" has restriction.
        SetRestrictionToItem(SalesLine."No.");

        // [WHEN] Preview posting for Sales Order
        Commit();
        asserterror SalesPostYesNo.Preview(SalesHeader);

        // [THEN] No errors occured - preview mode error only
        Assert.ExpectedError('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderPostOnItemRestriction()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 206308] Post Purchase Order when restriction for Item exists
        Initialize();

        // [GIVEN] Purchase Order with item "I"
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Item "I" has restriction.
        SetRestrictionToItem(PurchaseLine."No.");

        // [WHEN] Post Purchase Order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Error is thrown "You cannot use Item: "I" for this action."
        Assert.ExpectedError(StrSubstNo(ItemRestrictionErr, PurchaseLine."No."));
    end;

    [Test]
    [HandlerFunctions('GLPostingPreviewHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderPostPreviewOnItemRestriction()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 206308] Preview Posting for Purchase Order when restriction for Item exists
        Initialize();

        // [GIVEN] Purchase Order with item "I"
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Item "I" has restriction.
        SetRestrictionToItem(PurchaseLine."No.");

        // [WHEN] Preview posting for Purchase Order
        Commit();
        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchaseHeader);

        // [THEN] No errors occured - preview mode error only
        Assert.ExpectedError('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceApproverChainLoop()
    var
        UserSetup: Record "User Setup";
        SalesHeader: Record "Sales Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Creating approval entries for an approver chain fails when there is a loop
        Initialize();

        // [GIVEN] An approver chain setup with a loop
        SetupUsersWithLoop(UserSetup);

        // [GIVEN] A Sales Invoice approval workflow
        SetupApprovalWorkflows(DATABASE::"Sales Header", SalesHeader."Document Type"::Invoice.AsInteger());

        // [GIVEN] A Sales Invoice is sent for approval
        CreateSalesDocumentWithSalespersonCode(SalesHeader, SalesHeader."Document Type"::Invoice, UserSetup."Salespers./Purch. Code");
        // [THEN] An error is thrown
        asserterror ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Verify
        Assert.ExpectedError(ApproverChainErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        isInitialized := true;
        Commit();
        BindSubscription(LibraryJobQueue);
    end;

    local procedure ApproveRequest(TableID: Integer; DocumentType: Option; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        GetApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
        ApprovalEntry.SetRecFilter();
        ApprovalsMgmt.ApproveApprovalRequests(ApprovalEntry);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreatePurchaseDocumentWithPurchaserCode(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PurchaserCode: Code[20])
    begin
        CreatePurchaseDocument(PurchaseHeader, DocumentType);
        PurchaseHeader.Validate("Purchaser Code", PurchaserCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure SetRestrictionToVendor(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        RestrictedRecord: Record "Restricted Record";
    begin
        Vendor.Get(VendorNo);
        RestrictedRecord.Init();
        RestrictedRecord."Record ID" := Vendor.RecordId;
        RestrictedRecord.Insert();
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesDocumentWithSalespersonCode(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SalespersonCode: Code[20])
    begin
        CreateSalesDocument(SalesHeader, DocumentType);
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure SetRestrictionToCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        RestrictedRecord: Record "Restricted Record";
    begin
        Customer.Get(CustomerNo);
        RestrictedRecord.Init();
        RestrictedRecord."Record ID" := Customer.RecordId;
        RestrictedRecord.Insert();
    end;

    local procedure SetRestrictionToItem(ItemNo: Code[20])
    var
        Item: Record Item;
        RestrictedRecord: Record "Restricted Record";
    begin
        Item.Get(ItemNo);
        RestrictedRecord.Init();
        RestrictedRecord."Record ID" := Item.RecordId;
        RestrictedRecord.Insert();
    end;

    local procedure CreateUser(var User: Record User; WindowsUserName: Text[208])
    var
        UserName: Code[50];
    begin
        UserName :=
          CopyStr(LibraryUtility.GenerateRandomCode(User.FieldNo("User Name"), DATABASE::User),
            1, LibraryUtility.GetFieldLength(DATABASE::User, User.FieldNo("User Name")));
        LibraryDocumentApprovals.CreateUser(UserName, WindowsUserName);
        LibraryDocumentApprovals.GetUser(User, WindowsUserName)
    end;

    local procedure GetApprovalEntries(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DocumentType: Option; DocumentNo: Code[20])
    begin
        ApprovalEntry.SetRange("Table ID", TableID);
        ApprovalEntry.SetRange("Document Type", DocumentType);
        ApprovalEntry.SetRange("Document No.", DocumentNo);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        ApprovalEntry.FindSet();
    end;

    local procedure PostOpenedPurchaseDocument(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, true);
        SetupApprovalWorkflows(DATABASE::"Purchase Header", DocumentType.AsInteger());
        CreatePurchaseDocumentWithPurchaserCode(PurchaseHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Purchase Header", DocumentType.AsInteger(), PurchaseHeader."No.");
        ApproveRequest(DATABASE::"Purchase Header", DocumentType.AsInteger(), PurchaseHeader."No.");
        PurchaseHeader.Get(DocumentType, PurchaseHeader."No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // Exercise
        asserterror PurchaseHeader.SendToPosting(CODEUNIT::"Purch.-Post (Yes/No)");

        // Verify
        Assert.ExpectedError(StrSubstNo(DocumentMustBeApprovedAndReleasedErr, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    local procedure PostOpenedSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, true);
        SetupApprovalWorkflows(DATABASE::"Sales Header", DocumentType.AsInteger());
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Sales Header", DocumentType.AsInteger(), SalesHeader."No.");
        ApproveRequest(DATABASE::"Sales Header", DocumentType.AsInteger(), SalesHeader."No.");
        SalesHeader.Get(DocumentType, SalesHeader."No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Exercise
        asserterror SalesHeader.SendToPosting(CODEUNIT::"Sales-Post (Yes/No)");

        // Verify
        Assert.ExpectedError(StrSubstNo(DocumentMustBeApprovedAndReleasedErr, SalesHeader."Document Type", SalesHeader."No."));
    end;

    local procedure PurchaseDocumentApproval(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, DocumentType);

        // Exercise
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // Verify: no error and status stays Open.
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
    end;

    local procedure PurchaseDocumentBeyondApprovalLimit(DocumentType: Enum "Purchase Document Type")
    var
        UserSetup: Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, false);
        SetupApprovalWorkflows(DATABASE::"Purchase Header", DocumentType.AsInteger());
        CreatePurchaseDocumentWithPurchaserCode(PurchaseHeader, DocumentType, UserSetup."Salespers./Purch. Code");

        // Exercise
        asserterror ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // Verify
        Assert.ExpectedError(NoSuitableApproverFoundErr);
    end;

    local procedure PurchaseDocumentWithDifferentPurchaserCode(DocumentType: Enum "Purchase Document Type")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
        PurchHeader: Record "Purchase Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, true);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SetupApprovalWorkflows(DATABASE::"Purchase Header", DocumentType.AsInteger());
        CreatePurchaseDocumentWithPurchaserCode(PurchHeader, DocumentType, SalespersonPurchaser.Code);

        // Exercise
        asserterror ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Verify
        Assert.ExpectedError(StrSubstNo(SalespersPurchCodeErr));
    end;

    local procedure PurchaseDocumentWithoutSubstitute(DocumentType: Enum "Purchase Document Type")
    var
        UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        ApprovalAdminUserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, true);
        ApprovalAdminUserSetup.ModifyAll("Approval Administrator", false, true);
        SetupApprovalWorkflows(DATABASE::"Purchase Header", DocumentType.AsInteger());
        CreatePurchaseDocumentWithPurchaserCode(PurchHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Purchase Header", DocumentType.AsInteger(), PurchHeader."No.");
        GetApprovalEntries(ApprovalEntry, DATABASE::"Purchase Header", PurchHeader."Document Type".AsInteger(), PurchHeader."No.");

        UserSetup."Approver ID" := '';
        UserSetup.Modify(true);

        // Exercise
        ApprovalEntry.SetRecFilter();
        asserterror ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // Verify
        Assert.ExpectedError(StrSubstNo(SubstituteErr, UpperCase(UserId)));
    end;

    local procedure SalesDocumentApproval(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup
        Initialize();
        CreateSalesDocument(SalesHeader, DocumentType);

        // Exercise
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Verify: no error and status stays Open.
        SalesHeader.Find();
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
    end;

    local procedure SalesDocumentBeyondApprovalLimit(DocumentType: Enum "Sales Document Type")
    var
        UserSetup: Record "User Setup";
        SalesHeader: Record "Sales Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, false);
        SetupApprovalWorkflows(DATABASE::"Sales Header", DocumentType.AsInteger());
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");

        // Exercise
        asserterror ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Verify
        Assert.ExpectedError(NoSuitableApproverFoundErr);
    end;

    local procedure SalesDocumentWithDifferentSalesPersonCode(DocumentType: Enum "Sales Document Type")
    var
        UserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesHeader: Record "Sales Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, true);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SetupApprovalWorkflows(DATABASE::"Sales Header", DocumentType.AsInteger());
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, SalespersonPurchaser.Code);

        // Exercise
        asserterror ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Verify
        Assert.ExpectedError(StrSubstNo(SalespersPurchCodeErr));
    end;

    local procedure SalesDocumentWithoutSubstitute(DocumentType: Enum "Sales Document Type")
    var
        UserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        ApprovalAdminUserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, true);
        ApprovalAdminUserSetup.ModifyAll("Approval Administrator", false, true);
        SetupApprovalWorkflows(DATABASE::"Sales Header", DocumentType.AsInteger());
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Sales Header", DocumentType.AsInteger(), SalesHeader."No.");
        GetApprovalEntries(ApprovalEntry, DATABASE::"Sales Header", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");

        UserSetup."Approver ID" := '';
        UserSetup.Modify(true);

        // Exercise
        ApprovalEntry.SetRecFilter();
        asserterror ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // Verify
        Assert.ExpectedError(StrSubstNo(SubstituteErr, UpperCase(UserId)));
    end;

    local procedure SetApprovalAdmin(ApprovalAdministrator: Code[50])
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(ApprovalAdministrator);
        UserSetup."Approval Administrator" := true;
        UserSetup.Modify();
    end;

    local procedure SetupApprovalWorkflows(TableNo: Integer; DocumentType: Option)
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
        Workflow: Record Workflow;
        WorkflowSetup: Codeunit "Workflow Setup";
        BlankDateFormula: DateFormula;
    begin
        LibraryWorkflow.DeleteAllExistingWorkflows();

        case TableNo of
            DATABASE::"Purchase Header":
                WorkflowSetup.InsertPurchaseDocumentApprovalWorkflowSteps(
                    Workflow, "Purchase Document Type".FromInteger(DocumentType),
                    WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser", WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
                    '', BlankDateFormula);
            DATABASE::"Sales Header":
                WorkflowSetup.InsertSalesDocumentApprovalWorkflowSteps(
                    Workflow, "Sales Document Type".FromInteger(DocumentType),
                    WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser", WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
                    '', BlankDateFormula);
        end;

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure SetupDocumentApprovals(var UserSetup: Record "User Setup"; UnlimitedApproval: Boolean)
    begin
        SetupUsers(UserSetup, UnlimitedApproval);
        SetApprovalAdmin(UserSetup."Approver ID");
    end;

    local procedure SetupUsers(var RequestorUserSetup: Record "User Setup"; UnlimitedApproval: Boolean)
    var
        ApproverUserSetup: Record "User Setup";
        RequestorUser: Record User;
    begin
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.UpdateApprovalLimits(ApproverUserSetup, UnlimitedApproval, UnlimitedApproval, UnlimitedApproval, 0, 0, 0);

        if LibraryDocumentApprovals.UserExists(UserId) then
            LibraryDocumentApprovals.GetUser(RequestorUser, UserId)
        else
            CreateUser(RequestorUser, UserId);

        if LibraryDocumentApprovals.GetUserSetup(RequestorUserSetup, UserId) then
            LibraryDocumentApprovals.DeleteUserSetup(RequestorUserSetup, UserId);

        LibraryDocumentApprovals.CreateUserSetup(RequestorUserSetup, RequestorUser."User Name", ApproverUserSetup."User ID");
        LibraryDocumentApprovals.UpdateApprovalLimits(RequestorUserSetup, false, false, false, 0, 0, 0);
    end;

    local procedure SetupUsersWithLoop(var RequestorUserSetup: Record "User Setup")
    var
        UserSetup2: Record "User Setup";
        UserSetup3: Record "User Setup";
    begin
        // setup:
        // User 1 = requestor
        // User 2 Approves User 1
        // User 3 Approves User 2
        // User 1 Approves User 3

        // create users 1 & 2
        LibraryDocumentApprovals.CreateMockupUserSetup(RequestorUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup2);
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup3);
        RequestorUserSetup."Approver ID" := UserSetup2."User ID";
        LibraryDocumentApprovals.UpdateApprovalLimits(RequestorUserSetup, false, false, false, 0, 0, 0);
        UserSetup2."Approver ID" := UserSetup3."User ID";
        LibraryDocumentApprovals.UpdateApprovalLimits(UserSetup2, false, false, false, 0, 0, 0);
        UserSetup3."Approver ID" := RequestorUserSetup."User ID";
        LibraryDocumentApprovals.UpdateApprovalLimits(UserSetup3, false, false, false, 0, 0, 0);
    end;

    local procedure UpdateApprovalEntryWithTempUser(UserSetup: Record "User Setup"; TableID: Integer; DocumentType: Option; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        GetApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLPostingPreviewHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.OK().Invoke();
    end;
}

