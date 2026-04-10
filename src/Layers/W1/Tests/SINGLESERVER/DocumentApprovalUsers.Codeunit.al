codeunit 134202 "Document Approval - Users"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Approval Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Approval] [User]
    end;

    var
        Assert: Codeunit Assert;
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        ValueNotExpectedErr: Label '%1 must not be %2', Comment = '%1=FieldCaption,%2=User ID';
        WrongOrderStatusErr: Label 'Wrong status of %1.';
        WrongNumberOfApprovalEntriesMsg: Label 'Wrong number of Approval Entries.';
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryERM: Codeunit "Library - ERM";
        UserNameErr: Label 'The user name %1 does not exist.';
        TestUserNameTxt: Label 'Test User Name';
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        DocumentApprovalUsers: Codeunit "Document Approval - Users";
        IsInitialized: Boolean;
        RecordRestrictedTxt: Label 'You cannot use %1 for this action.', Comment = 'You cannot use Customer 10000 for this action.';
        ApprovalAdministratorErr: Label 'Approval Administrator must have a value in User Setup';
        UserSetupDoesNotExistErr: Label 'The User Setup does not exist';
        TestFieldTok: Label 'TestField';
        DBRecordNotFoundTok: Label 'DB:RecordNotFound';
        DelegatePermissionErr: Label 'You do not have permission to delegate one or more of the selected approval requests.';
        PhoneNoCannotContainLettersErr: Label 'must not contain letters';

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRelatedRecordsForSalesInvoiceEmail()
    var
        SalesHeader: Record "Sales Header";
    begin
        VerifyRelatedRecordsForEmail(SalesHeader)
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForPurchBlanketOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ApproveRequestForPurchDocument(PurchHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForPurchCreditMemo()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ApproveRequestForPurchDocument(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForPurchInvoice()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ApproveRequestForPurchDocument(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ApproveRequestForPurchDocument(PurchHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForPurchQuote()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ApproveRequestForPurchDocument(PurchHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForPurchReturnOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ApproveRequestForPurchDocument(PurchHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        ApproveRequestForSalesDocument(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        ApproveRequestForSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        ApproveRequestForSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        ApproveRequestForSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        ApproveRequestForSalesDocument(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApproveRequestForSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        ApproveRequestForSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForPurchBlanketOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        CancelRequestByRequestorForPurchDocument(PurchHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForPurchCrMemo()
    var
        PurchHeader: Record "Purchase Header";
    begin
        CancelRequestByRequestorForPurchDocument(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForPurchInvoice()
    var
        PurchHeader: Record "Purchase Header";
    begin
        CancelRequestByRequestorForPurchDocument(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        CancelRequestByRequestorForPurchDocument(PurchHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForPurchQuote()
    var
        PurchHeader: Record "Purchase Header";
    begin
        CancelRequestByRequestorForPurchDocument(PurchHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForPurchReturnOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        CancelRequestByRequestorForPurchDocument(PurchHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        CancelRequestByRequestorForSalesDocument(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        CancelRequestByRequestorForSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        CancelRequestByRequestorForSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        CancelRequestByRequestorForSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        CancelRequestByRequestorForSalesDocument(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CancelRequestByRequestorForSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        CancelRequestByRequestorForSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForPurchBlanketOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DelegateRequestForPurchDocument(PurchHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForPurchCrMemo()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DelegateRequestForPurchDocument(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForPurchInvoice()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DelegateRequestForPurchDocument(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DelegateRequestForPurchDocument(PurchHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForPurchQuote()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DelegateRequestForPurchDocument(PurchHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForPurchReturnOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DelegateRequestForPurchDocument(PurchHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        DelegateRequestForSalesDocument(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        DelegateRequestForSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        DelegateRequestForSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        DelegateRequestForSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        DelegateRequestForSalesDocument(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateRequestForSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        DelegateRequestForSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForPurchBlanketOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DoubleRequestApprovalForPurchDocument(PurchHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForPurchCrMemo()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DoubleRequestApprovalForPurchDocument(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForPurchInvoice()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DoubleRequestApprovalForPurchDocument(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DoubleRequestApprovalForPurchDocument(PurchHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForPurchQuote()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DoubleRequestApprovalForPurchDocument(PurchHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForPurchReturnOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        DoubleRequestApprovalForPurchDocument(PurchHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        DoubleRequestApprovalForSalesDocument(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        DoubleRequestApprovalForSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        DoubleRequestApprovalForSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        DoubleRequestApprovalForSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        DoubleRequestApprovalForSalesDocument(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DoubleRequestApprovalForSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        DoubleRequestApprovalForSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedPurchBlanketOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ModifyApprovedPurchDocument(PurchHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedPurchCrMemo()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ModifyApprovedPurchDocument(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedPurchInvoice()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ModifyApprovedPurchDocument(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ModifyApprovedPurchDocument(PurchHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedPurchQuote()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ModifyApprovedPurchDocument(PurchHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedPurchReturnOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        ModifyApprovedPurchDocument(PurchHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        ModifyApprovedSalesDocument(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        ModifyApprovedSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        ModifyApprovedSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        ModifyApprovedSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        ModifyApprovedSalesDocument(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyApprovedSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        ModifyApprovedSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchAmountApprovalLimitWithUnlimitedAmount()
    var
        UserSetup: Record "User Setup";
    begin
        Initialize();
        // Setup
        SetupUsers(UserSetup, '', false, false, false, 0, LibraryRandom.RandInt(100), 0);

        // Exercise
        UserSetup.Validate("Unlimited Purchase Approval", true);

        // Verify
        UserSetup.TestField("Purchase Amount Approval Limit", 0);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForPurchBlanketOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RejectRequestForPurchDocument(PurchHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForPurchCreditMemo()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RejectRequestForPurchDocument(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForPurchInvoice()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RejectRequestForPurchDocument(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RejectRequestForPurchDocument(PurchHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForPurchQuote()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RejectRequestForPurchDocument(PurchHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForPurchReturnOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RejectRequestForPurchDocument(PurchHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocument(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocument(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RejectRequestForSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        RejectRequestForSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestAmountApprovalLimitWithUnlimitedAmount()
    var
        UserSetup: Record "User Setup";
    begin
        Initialize();
        // Setup
        SetupUsers(UserSetup, '', false, false, false, 0, 0, LibraryRandom.RandInt(100));

        // Exercise
        UserSetup.Validate("Unlimited Request Approval", true);

        // Verify
        UserSetup.TestField("Request Amount Approval Limit", 0);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestApprovalForPurchBlanketOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RequestApprovalForPurchDocument(PurchHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestApprovalForPurchCrMemo()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RequestApprovalForPurchDocument(PurchHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestApprovalForPurchInvoice()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RequestApprovalForPurchDocument(PurchHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestApprovalForPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RequestApprovalForPurchDocument(PurchHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestApprovalForPurchQuote()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RequestApprovalForPurchDocument(PurchHeader."Document Type"::Quote);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestApprovalForPurchReturnOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        RequestApprovalForPurchDocument(PurchHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestApprovalForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        RequestApprovalForSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestApprovalForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        RequestApprovalForSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestApprovalForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        RequestApprovalForSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestApprovalForSalesQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        RequestApprovalForSalesDocument(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesAmountApprovalLimitWithUnlimitedAmount()
    var
        UserSetup: Record "User Setup";
    begin
        Initialize();
        // Setup
        SetupUsers(UserSetup, '', false, false, false, LibraryRandom.RandInt(100), 0, 0);

        // Exercise
        UserSetup.Validate("Unlimited Sales Approval", true);

        // Verify
        UserSetup.TestField("Sales Amount Approval Limit", 0);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForPurchBlanketOrder()
    var
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", PurchHeader."Document Type"::"Blanket Order", '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, PurchHeader."Document Type"::"Blanket Order",
          UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Exercise
        BlanketPurchaseOrder.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Purchase Header", PurchHeader."Document Type", PurchHeader."No.");

        // Verify
        BlanketPurchaseOrder."No.".AssertEquals(PurchHeader."No.");
        BlanketPurchaseOrder.Status.AssertEquals(PurchHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForPurchCrMemo()
    var
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header",
          PurchHeader."Document Type"::"Credit Memo", '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, PurchHeader."Document Type"::"Credit Memo", UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Exercise
        PurchaseCreditMemo.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Purchase Header", PurchHeader."Document Type", PurchHeader."No.");

        // Verify
        PurchaseCreditMemo."No.".AssertEquals(PurchHeader."No.");
        PurchaseCreditMemo.Status.AssertEquals(PurchHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForPurchInvoice()
    var
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", PurchHeader."Document Type"::Invoice, '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, PurchHeader."Document Type"::Invoice, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Exercise
        PurchaseInvoice.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Purchase Header", PurchHeader."Document Type", PurchHeader."No.");

        // Verify
        PurchaseInvoice."No.".AssertEquals(PurchHeader."No.");
        PurchaseInvoice.Status.AssertEquals(PurchHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", PurchHeader."Document Type"::Order, '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, PurchHeader."Document Type"::Order, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Exercise
        PurchaseOrder.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Purchase Header", PurchHeader."Document Type", PurchHeader."No.");

        // Verify
        PurchaseOrder."No.".AssertEquals(PurchHeader."No.");
        PurchaseOrder.Status.AssertEquals(PurchHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForPurchQuote()
    var
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", PurchHeader."Document Type"::Quote, '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, PurchHeader."Document Type"::Quote, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Exercise
        PurchaseQuote.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Purchase Header", PurchHeader."Document Type", PurchHeader."No.");

        // Verify
        PurchaseQuote."No.".AssertEquals(PurchHeader."No.");
        PurchaseQuote.Status.AssertEquals(PurchHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForPurchReturnOrder()
    var
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", PurchHeader."Document Type"::"Return Order", '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, PurchHeader."Document Type"::"Return Order", UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Exercise
        PurchaseReturnOrder.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Purchase Header", PurchHeader."Document Type", PurchHeader."No.");

        // Verify
        PurchaseReturnOrder."No.".AssertEquals(PurchHeader."No.");
        PurchaseReturnOrder.Status.AssertEquals(PurchHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForSalesBlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", SalesHeader."Document Type"::"Blanket Order", '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, SalesHeader."Document Type"::"Blanket Order",
          UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Exercise
        BlanketSalesOrder.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.");

        // Verify
        BlanketSalesOrder."No.".AssertEquals(SalesHeader."No.");
        BlanketSalesOrder.Status.AssertEquals(SalesHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", SalesHeader."Document Type"::"Credit Memo", '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, SalesHeader."Document Type"::"Credit Memo",
          UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Exercise
        SalesCreditMemo.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.");

        // Verify
        SalesCreditMemo."No.".AssertEquals(SalesHeader."No.");
        SalesCreditMemo.Status.AssertEquals(SalesHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", SalesHeader."Document Type"::Invoice, '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, SalesHeader."Document Type"::Invoice, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Exercise
        SalesInvoice.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.");

        // Verify
        SalesHeader.Find();
        SalesInvoice."No.".AssertEquals(SalesHeader."No.");
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", SalesHeader."Document Type"::Order, '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, SalesHeader."Document Type"::Order, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Exercise
        SalesOrder.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.");

        // Verify
        SalesOrder."No.".AssertEquals(SalesHeader."No.");
        SalesOrder.Status.AssertEquals(SalesHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SalesQuote: TestPage "Sales Quote";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", SalesHeader."Document Type"::Quote, '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, SalesHeader."Document Type"::Quote, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Exercise
        SalesQuote.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.");

        // Verify
        SalesQuote."No.".AssertEquals(SalesHeader."No.");
        SalesQuote.Status.AssertEquals(SalesHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDocumentFromApprovalEntryForSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", SalesHeader."Document Type"::"Return Order", '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, SalesHeader."Document Type"::"Return Order",
          UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Exercise
        SalesReturnOrder.Trap();
        ShowDocumentFromApprovalEntry(DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.");

        // Verify
        SalesReturnOrder."No.".AssertEquals(SalesHeader."No.");
        SalesReturnOrder.Status.AssertEquals(SalesHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure MultipleUsersApproveSequence()
    var
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        PurchHeader: Record "Purchase Header";
        RequestorUserSetup: Record "User Setup";
        ApproverUserSetup: Record "User Setup";
        ApprovalEntry: Record "Approval Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        "Count": Integer;
        i: Integer;
        "Sum": Integer;
        AmountLimit: Integer;
        BlankDateFormula: DateFormula;
    begin
        // Test Case for HF344645
        // Create NAV user linked to current Windows User account with SUPER permissions
        // It is necessary to create further users
        Initialize();
        SetupUsers(RequestorUserSetup, '', false, false, false, 0, 0, 0);

        // Create NAV Users that are not linked to any Windows Account with SUPER pemissions.
        // Count >=3 to have enough sequence length
        Count := LibraryRandom.RandIntInRange(3, 5);
        for i := 1 to Count do begin
            AmountLimit := LibraryRandom.RandInt(1000);
            SetupNonWindowsUser(ApproverUserSetup);
            SetupApproverAndPurchAmountApprovalLimit(RequestorUserSetup, ApproverUserSetup."User ID", AmountLimit);
            RequestorUserSetup := ApproverUserSetup;
            Sum += AmountLimit;
        end;
        LibraryDocumentApprovals.UpdateApprovalLimits(ApproverUserSetup, true, true, true, 0, 0, 0);
        Count += 1; // Total approval entry count: Windows User + Non Windows User

        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InsertPurchaseDocumentApprovalWorkflowSteps(
            Workflow, PurchHeader."Document Type"::Order,
            WorkflowStepArgument."Approver Type"::Approver, WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
            '', BlankDateFormula);
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);

        // Excercise
        CreatePurchDocumentWithDirectCost(PurchHeader, PurchHeader."Document Type"::Order, Sum + 1);
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Test
        ApprovalEntry.SetRange("Document No.", PurchHeader."No.");
        Assert.AreEqual(Count, ApprovalEntry.Count, WrongNumberOfApprovalEntriesMsg);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SalesListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PostingDropShipmentOrderForApprovalNotCompleted()
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        RestrictedRecord: Record "Restricted Record";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        ExpectedErrorMessage: Text;
        ActualErrorMessage: Text;
    begin
        // [FEATURE] [UT] [Drop Shipment]
        // [SCENARIO 378540] In a Drop Shipment scenario Purchase Order posting errors by not approved Sales Order
        Initialize();

        // [GIVEN] Enable Sales Order Approval Template. Set approval chain of two users
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", SalesHeader."Document Type"::Order, '');

        // [GIVEN] Drop Shipment by Sales Order and Purchase Order with Salesperson Code of Current User
        CreateSalesAndPurchOrdersWithDropShipment(SalesHeader, PurchaseHeader);
        SalesHeader.Validate("Salesperson Code", UserSetup."Salespers./Purch. Code");
        SalesHeader.Modify();

        // [GIVEN] Approval requests is sent for Sales Order. Sales Order Status = "Pending Approval"
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // [GIVEN] Set restriction for Sales Header
        RecordRestrictionMgt.RestrictRecordUsage(SalesHeader, '');
        RestrictedRecord.SetRange("Record ID", SalesHeader.RecordId);
        RestrictedRecord.FindFirst();
        ExpectedErrorMessage := StrSubstNo(RecordRestrictedTxt,
            Format(Format(RestrictedRecord."Record ID", 0, 1)));

        // [WHEN] Post Purchase Order
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Expected restriction error occurred on release not approved Sales Order
        ActualErrorMessage := CopyStr(GetLastErrorText, 1, StrLen(ExpectedErrorMessage));
        // TODO Assert.AreEqual(ExpectedErrorMessage, ActualErrorMessage, 'Unexpected error message.');

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesOrderApprovalsAfterReopen()
    var
        UserSetup: Record "User Setup";
        SalesHeader: Record "Sales Header";
        Workflow: Record Workflow;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApprovalAmount: Decimal;
    begin
        // [FEATURE] [UT] [Workflow]
        // [SCENARIO 379158] Approving Sales Order after reopen
        Initialize();

        // [GIVEN] Approval chain of two users and Workflow on Sales Order Approval Template
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", SalesHeader."Document Type"::Order, '');
        CreateEnabledWorkflowForSalesOrder(Workflow);

        // [GIVEN] Sales Order
        CreateSalesDocumentWithApprovalAmount(
          SalesHeader, SalesHeader."Document Type"::Order,
          UserSetup."Salespers./Purch. Code", ApprovalAmount);

        // [GIVEN] Approval requests is sent for Sales Order for two steps approving
        SetupApproverAndSalesAmountApprovalLimit(UserSetup, UserSetup."Approver ID", Round(ApprovalAmount / 2, 1));
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // [GIVEN] Sales Order approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(SalesHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(SalesHeader.RecordId);

        // [GIVEN] Sales Order reopened
        SalesHeader.Find();
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [GIVEN] Approval Limit of current user updated for one step approving
        SetupApproverAndSalesAmountApprovalLimit(UserSetup, UserSetup."Approver ID", Round(ApprovalAmount * 2, 1));

        // [WHEN] Approval request is sent for Sales Order
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // [THEN] Sales Order Status = "Released"
        SalesHeader.Find();
        SalesHeader.TestField(Status, SalesHeader.Status::Released);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchaseOrderApprovalsAfterReopen()
    var
        UserSetup: Record "User Setup";
        PurchaseHeader: Record "Purchase Header";
        Workflow: Record Workflow;
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApprovalAmount: Decimal;
    begin
        // [FEATURE] [UT] [Workflow]
        // [SCENARIO 379158] Approving Purchase Order after reopen
        Initialize();

        // [GIVEN] Approval chain of two users and Workflow on Purchase Order Approval Template
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", PurchaseHeader."Document Type"::Order, '');
        CreateEnabledWorkflowForPurchaseOrder(Workflow);

        // [GIVEN] Purchase Order
        CreatePurchDocumentWithApprovalAmount(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          UserSetup."Salespers./Purch. Code", ApprovalAmount);

        // [GIVEN] Approval requests is sent for Sales Order for two steps approving
        SetupApproverAndPurchAmountApprovalLimit(UserSetup, UserSetup."Approver ID", Round(ApprovalAmount / 2, 1));
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // [GIVEN] Purchase Order approved
        LibraryDocumentApprovals.UpdateApprovalEntryWithCurrUser(PurchaseHeader.RecordId);
        ApprovalsMgmt.ApproveRecordApprovalRequest(PurchaseHeader.RecordId);

        // [GIVEN] Purchase Order reopened
        PurchaseHeader.Find();
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [GIVEN] Approval Limit of current user updated for one step approving
        SetupApproverAndPurchAmountApprovalLimit(UserSetup, UserSetup."Approver ID", Round(ApprovalAmount * 2, 1));

        // [WHEN] Approval request is sent for Purchase Order
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);

        // [THEN] Purhase Order Status = "Released"
        PurchaseHeader.Find();
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SalesOrderReleasedStatusAfterRequestApproval()
    var
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        Customer: Record Customer;
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        BlankDateFormula: DateFormula;
    begin
        // [SCENARIO] status of sales order is "Release" after the successfullt request approval.
        Initialize();

        // [GIVEN] Create user setup, approval template and customer with Credit Limit.
        SetupCurrUser(UserSetup);
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InsertSalesDocumentApprovalWorkflowSteps(
            Workflow, SalesHeader."Document Type"::Order,
            WorkflowStepArgument."Approver Type"::Approver, WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
            '', BlankDateFormula);
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
        CreateCustomerWithCreditLimit(Customer, LibraryRandom.RandDec(10000, 2));

        // [WHEN] Create sales document based on user setup.
        CreateSalesDocWithCustAndSalesPerson(
          SalesHeader, Customer, SalesHeader."Document Type"::Order, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // [THEN] Check that status changed to Released.
        SalesHeader.Find();
        Assert.AreEqual(
          SalesHeader.Status::Released, SalesHeader.Status, StrSubstNo(WrongOrderStatusErr, SalesHeader.TableCaption()));
        UserSetup.Delete(true);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PurchOrderReleasedStatusAfterRequestApproval()
    var
        Workflow: Record Workflow;
        WorkflowStepArgument: Record "Workflow Step Argument";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        WorkflowSetup: Codeunit "Workflow Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        BlankDateFormula: DateFormula;
    begin
        // [SCENARIO] status of purchase order is "Release" after the successfullt request approval.
        Initialize();

        // [GIVEN] Create user setup and approval template.
        SetupCurrUser(UserSetup);
        LibraryWorkflow.DeleteAllExistingWorkflows();
        WorkflowSetup.InsertPurchaseDocumentApprovalWorkflowSteps(
            Workflow, PurchHeader."Document Type"::Order,
            WorkflowStepArgument."Approver Type"::Approver, WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
            '', BlankDateFormula);
        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);

        // [WHEN] Create purchase document based on user setup.
        CreatePurchDocumentWithPurchaserCode(PurchHeader, PurchHeader."Document Type"::Order,
          UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // [THEN] Check that status changed to Released.
        PurchHeader.Find();
        Assert.AreEqual(PurchHeader.Status::Released, PurchHeader.Status, StrSubstNo(WrongOrderStatusErr, PurchHeader.TableCaption()));
        UserSetup.Delete(true);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserDefinedAsSelfApprover()
    var
        UserSetup: Record "User Setup";
    begin
        // Setup
        Initialize();

        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, '');

        // Exercise
        asserterror UserSetup.Validate("Approver ID", UserId);

        // Verify
        Assert.ExpectedError(StrSubstNo(ValueNotExpectedErr, UserSetup.FieldCaption("Approver ID"), UserId));

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserSetupWithEmailPhone()
    var
        MockupUserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ApprovalUserSetup: TestPage "Approval User Setup";
        UserSetupPage: TestPage "User Setup";
    begin
        // [GIVEN] User Setup for user 'X', where "Salespers./Purch. Code" is 'S'
        LibraryDocumentApprovals.CreateMockupUserSetup(MockupUserSetup);
        // [WHEN] Set "E-Mail" is 'A', "Phone No." is 'B'

        MockupUserSetup.Validate("E-Mail", 'alias@domain.com');
        MockupUserSetup.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        MockupUserSetup.Modify();

        // [THEN] SalespersonPurchaser 'S' got values: "E-Mail" is 'A', "Phone No." is 'B'
        SalespersonPurchaser.Get(MockupUserSetup."Salespers./Purch. Code");
        SalespersonPurchaser.TestField("E-Mail", MockupUserSetup."E-Mail");
        SalespersonPurchaser.TestField("Phone No.", MockupUserSetup."Phone No.");

        // [WHEN] Open "Approval User Setup" page
        ApprovalUserSetup.OpenEdit();
        ApprovalUserSetup.GotoRecord(MockupUserSetup);

        // [THEN] "E-Mail" is 'A', "Phone No." is 'B', both controls are editable
        Assert.IsTrue(ApprovalUserSetup."E-Mail".Editable(), '"E-Mail".Editable');
        ApprovalUserSetup."E-Mail".AssertEquals(MockupUserSetup."E-Mail");
        Assert.IsTrue(ApprovalUserSetup.PhoneNo.Editable(), '"Phone No.".Editable');
        ApprovalUserSetup.PhoneNo.AssertEquals(MockupUserSetup."Phone No.");
        ApprovalUserSetup.Close();

        // [WHEN] Open "User Setup" page
        UserSetupPage.OpenEdit();
        UserSetupPage.GotoRecord(MockupUserSetup);

        // [THEN] "E-Mail" is 'A', "Phone No." is 'B', both controls are editable
        Assert.IsTrue(UserSetupPage.Email.Editable(), '"E-Mail".Editable');
        UserSetupPage.Email.AssertEquals(MockupUserSetup."E-Mail");
        Assert.IsTrue(UserSetupPage.PhoneNo.Editable(), '"Phone No.".Editable');
        UserSetupPage.PhoneNo.AssertEquals(MockupUserSetup."Phone No.");
        UserSetupPage.Close();

        // Teardown
        MockupUserSetup.Delete(true);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('ApprovalUserSetupPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserSetupWithApprover()
    var
        MockupUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        ApprovalUserSetup: TestPage "Approval User Setup";
    begin
        // Setup
        LibraryDocumentApprovals.CreateMockupUserSetup(MockupUserSetup);
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, '');

        // Exercise
        ApprovalUserSetup.OpenEdit();
        ApprovalUserSetup.GotoRecord(MockupUserSetup);
        ApprovalUserSetup."Approver ID".Lookup();

        // Verify
        // Modal Page Handler

        // Teardown
        UserSetup.Delete(true);
        MockupUserSetup.Delete(true);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserDefinedAsSelfSubstitute()
    var
        UserSetup: Record "User Setup";
    begin
        // Setup
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, '');

        // Exercise
        asserterror UserSetup.Validate(Substitute, UserId);

        // Verify
        Assert.ExpectedError(StrSubstNo(ValueNotExpectedErr, UserSetup.FieldCaption(Substitute), UserId));

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('ApprovalUserSetupPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserSetupWithSubstitute()
    var
        MockupUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        ApprovalUserSetup: TestPage "Approval User Setup";
    begin
        // Setup
        LibraryDocumentApprovals.CreateMockupUserSetup(MockupUserSetup);
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, '');

        // Exercise
        ApprovalUserSetup.OpenEdit();
        ApprovalUserSetup.GotoRecord(MockupUserSetup);
        ApprovalUserSetup.Substitute.Lookup();

        // Verify
        // Modal Page Handler

        // Teardown
        UserSetup.Delete(true);
        MockupUserSetup.Delete(true);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UserSetupMatchExistingUser()
    var
        User: Record User;
        ApprovalUserSetup: TestPage "Approval User Setup";
    begin
        // Setup
        CreateUser(User, UserId);

        // Exercise
        ApprovalUserSetup.OpenEdit();
        ApprovalUserSetup."User ID".SetValue(UserId);
        asserterror ApprovalUserSetup."User ID".SetValue(TestUserNameTxt);

        Assert.ExpectedError(StrSubstNo(UserNameErr, UpperCase(TestUserNameTxt)));
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(UserNameErr, UpperCase(TestUserNameTxt))) > 0, 'Wrong user name');
        ApprovalUserSetup.Close();

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApproveRequestWithCommentForSalesQuoteAndMakeOrder()
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        SalesOrderNo: Code[20];
    begin
        // [FEATURE] [Sales] [Make Order] [Document Approvals - Comments]
        // [SCENARIO 375014] Sales Quote Approval with Comment is copied to Sales Order after Make Order action.
        Initialize();
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", SalesHeader."Document Type"::Quote, '');

        // [GIVEN] Sales Quote.
        CreateSalesDocumentWithSalespersonCode(SalesHeader, SalesHeader."Document Type", UserSetup."Salespers./Purch. Code");

        // [GIVEN] Send Approval Request. Add Approval comment.
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.");
        MockApprovalComment(SalesHeader.RecordId, SalesHeader."Document Type"::Quote, SalesHeader."No.");

        // [GIVEN] Approve request.
        ApproveRequest(ApprovalsMgmt, DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.");

        // [WHEN] Make Order from Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);
        SalesOrderNo := FindSalesOrderNoByQuoteNo(SalesHeader."No.", SalesHeader."Sell-to Customer No.");

        // [THEN] Approve request is shown for new Sales Order.
        VerifyApprovalEntries(
          DATABASE::"Sales Header", SalesHeader."Document Type"::Order, SalesOrderNo,
          UserSetup."Approver ID", UserSetup."User ID", UserSetup."User ID",
          UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);

        // [THEN] Approval Comment is shown for new Sales Order.
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        VerifyApprovalCommentLineExist(SalesHeader.RecordId);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ApproveRequestWithCommentForPurchQuoteAndMakeOrder()
    var
        ApprovalEntry: Record "Approval Entry";
        PurchaseHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        PurchaseOrderNo: Code[20];
    begin
        // [FEATURE] [Purchases] [Make Order] [Document Approvals - Comments]
        // [SCENARIO 375014] Purchase Quote Approval with Comment is copied to Purchase Order after Make Order action.
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", PurchaseHeader."Document Type"::Quote, '');

        // [GIVEN] Purchase Quote.
        CreatePurchDocumentWithPurchaserCode(
          PurchaseHeader, PurchaseHeader."Document Type"::Quote, UserSetup."Salespers./Purch. Code");

        // [GIVEN] Send Approval Request. Add Approval comment.
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchaseHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Purchase Header", PurchaseHeader."Document Type", PurchaseHeader."No.");
        MockApprovalComment(PurchaseHeader.RecordId, PurchaseHeader."Document Type"::Quote, PurchaseHeader."No.");

        // [GIVEN] Approve request.
        ApproveRequest(ApprovalsMgmt, DATABASE::"Purchase Header", PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [WHEN] Make Order from Sales Quote.
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order", PurchaseHeader);
        PurchaseOrderNo := FindPurchOrderNoByQuoteNo(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.");

        // [THEN] Approve request is shown for new Purchase Order.
        VerifyApprovalEntries(
          DATABASE::"Purchase Header", PurchaseHeader."Document Type"::Order, PurchaseOrderNo,
          UserSetup."Approver ID", UserSetup."User ID", UserSetup."User ID",
          UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);

        // [THEN] Approval Comment is shown for new Purchase Order.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderNo);
        VerifyApprovalCommentLineExist(PurchaseHeader.RecordId);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowApprovalEntryForApproverAndSender()
    var
        ApprovalEntry: array[4] of Record "Approval Entry";
        ApprovalEntriesPage: TestPage "Approval Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 379842] User should see Approval Entries where he is approver or sender

        // [GIVEN] Four approval entries
        // [GIVEN] Approval Entry 1 has "Approver ID" = User1 and "Sender ID" = User2
        MockApprovalEntry(ApprovalEntry[1], UserId, LibraryUtility.GenerateGUID());

        // [GIVEN] Approval Entry 2 has "Approver ID" = User2 and "Sender ID" = User2
        MockApprovalEntry(ApprovalEntry[2], LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [GIVEN] Approval Entry 3 has "Approver ID" = User2 and "Sender ID" = User1
        MockApprovalEntry(ApprovalEntry[3], LibraryUtility.GenerateGUID(), UserId);

        // [GIVEN] Approval Entry 4 has "Approver ID" = User1 and "Sender ID" = User1
        MockApprovalEntry(ApprovalEntry[4], UserId, UserId);

        // [WHEN] User1 opened page "Approval Entries"
        ApprovalEntriesPage.OpenView();

        // [THEN] User1 should see entry 1, 3 and 4
        ApprovalEntriesPage.GotoRecord(ApprovalEntry[1]);
        ApprovalEntriesPage.GotoRecord(ApprovalEntry[3]);
        ApprovalEntriesPage.GotoRecord(ApprovalEntry[4]);

        // [THEN] User1 shouldn't see entry 2
        asserterror ApprovalEntriesPage.GotoRecord(ApprovalEntry[2]);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PreventApproveApprovalEntries()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376824] User can't approve request if "Approval Entry"."Approver ID" is not equal USERID and user isn't Approval Administrator

        ApprovalEntry.DeleteAll();

        // [GIVEN] Record of "Approval Entry" with "Approver ID" <> USERID
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        UpdateApprovalAdministrator(false);

        // [WHEN] Approve approval entry
        asserterror ApprovalsMgmt.ApproveApprovalRequests(ApprovalEntry);

        // [THEN] Throw error "Approval Administrator must have a value in User Setup..."
        Assert.ExpectedError(ApprovalAdministratorErr);
        Assert.ExpectedErrorCode(TestFieldTok);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PreventRejectApprovalEntries()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376824] User can't reject request if "Approval Entry"."Approver ID" is not equal USERID and user isn't Approval Administrator

        ApprovalEntry.DeleteAll();

        // [GIVEN] Record of "Approval Entry" with "Approver ID" <> USERID
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        UpdateApprovalAdministrator(false);

        // [WHEN] Reject approval entry
        asserterror ApprovalsMgmt.RejectApprovalRequests(ApprovalEntry);

        // [THEN] Throw error "Approval Administrator must have a value in User Setup..."
        Assert.ExpectedError(ApprovalAdministratorErr);
        Assert.ExpectedErrorCode(TestFieldTok);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PreventDelegateApprovalEntries()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376824] User can't delegate request if "Approval Entry"."Approver ID" and "Approval Entry"."Sender ID" are not equal USERID and user isn't Approval Administrator

        ApprovalEntry.DeleteAll();

        // [GIVEN] Record of "Approval Entry" with "Approver ID" <> USERID
        // [GIVEN] Record of "Approval Entry" with "Sender ID" <> USERID
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        UpdateApprovalAdministrator(false);

        // [WHEN] Delegate approval entry
        asserterror ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // [THEN] System threw error "You do not have permission to delegate one or more of the selected approval requests."
        Assert.ExpectedError(DelegatePermissionErr);
        Assert.ExpectedErrorCode('Dialog');

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PreventApproveApprovalEntriesWithoutUserSetup()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376824] User can't approve request if "Approval Entry"."Approver ID" is not equal USERID and user doesn't have User Setup

        ApprovalEntry.DeleteAll();

        // [GIVEN] Record of "Approval Entry" with "Approver ID" <> USERID
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [WHEN] Approve approval entry
        asserterror ApprovalsMgmt.ApproveApprovalRequests(ApprovalEntry);

        // [THEN] Throw error "The User Setup does not exist..."
        Assert.ExpectedError(UserSetupDoesNotExistErr);
        Assert.ExpectedErrorCode(DBRecordNotFoundTok);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PreventRejectApprovalEntriesWithoutUserSetup()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376824] User can't reject request if "Approval Entry"."Approver ID" is not equal USERID and user doesn't have User Setup

        ApprovalEntry.DeleteAll();

        // [GIVEN] Record of "Approval Entry" with "Approver ID" <> USERID
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [WHEN] Reject approval entry
        asserterror ApprovalsMgmt.RejectApprovalRequests(ApprovalEntry);

        // [THEN] Throw error "The User Setup does not exist..."
        Assert.ExpectedError(UserSetupDoesNotExistErr);
        Assert.ExpectedErrorCode(DBRecordNotFoundTok);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PreventDelegateApprovalEntriesWithoutUserSetup()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376824] User can't delegate request if "Approval Entry"."Approver ID" and "Approval Entry"."Sender ID" are not equal USERID and user doesn't have User Setup

        ApprovalEntry.DeleteAll();

        // [GIVEN] Record of "Approval Entry" with "Approver ID" <> USERID
        // [GIVEN] Record of "Approval Entry" with "Sender ID" <> USERID
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [WHEN] Delegate approval entry
        asserterror ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // [THEN] System threw error "You do not have permission to delegate one or more of the selected approval requests."
        Assert.ExpectedError(DelegatePermissionErr);
        Assert.ExpectedErrorCode('Dialog');

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DelegateApprovalEntries()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApproverUserId: Code[50];
        SubstituteUserId: Code[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 376824] User can delegate request if "Approval Entry"."Sender ID" is equal to USERID and "Approval Entry"."Approver ID" is not equal to USERID

        ApprovalEntry.DeleteAll();

        // [GIVEN] User setup for approver - "User 1" with substitute "User 2"
        MockApprovalSubstituteUserSetup(ApproverUserId, SubstituteUserId);

        // [GIVEN] Approval Entry has "Approver ID" = "User 1" and "Sender ID" = USERID
        MockApprovalEntry(ApprovalEntry, ApproverUserId, UserId);
        UpdateApprovalAdministrator(false);

        // [WHEN] Delegate approval entry
        ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // [THEN] "Approval Entry"."Approver ID" = "User 2"
        FindApprovalEntry(ApprovalEntry, UserId, ApprovalEntry."Document No.");
        ApprovalEntry.TestField("Approver ID", SubstituteUserId);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowApprovalEntryForApprovalAdministrator()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntriesPage: TestPage "Approval Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 379842] Approval Administrator should see all Approval Entries

        ApprovalEntry.DeleteAll();

        // [GIVEN] Approval Administrator = User1
        UpdateApprovalAdministrator(true);

        // [GIVEN] Approval Entry has "Approver ID" = User2 and "Sender ID" = User3
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [WHEN] User1 opened page "Approval Entries"
        ApprovalEntriesPage.OpenView();

        // [THEN] User1 should see approval entry
        ApprovalEntriesPage.GotoRecord(ApprovalEntry);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApprovalAdministratorApproveApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApproverUserId: Code[50];
        SubstituteUserId: Code[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379842] Approval Administrator can approve request if "Approval Entry"."Approver ID" and "Approval Entry"."Sender ID" are not equal to USERID

        ApprovalEntry.DeleteAll();

        // [GIVEN] Approval Administrator = "User 1"
        UpdateApprovalAdministrator(true);

        // [GIVEN] User setup for approver - "User 2" with substitute "User 3"
        MockApprovalSubstituteUserSetup(ApproverUserId, SubstituteUserId);

        // [GIVEN] Approval Entry has "Approver ID" = User2 and "Sender ID" = User3
        MockApprovalEntry(ApprovalEntry, ApproverUserId, SubstituteUserId);

        // [WHEN] Approve approval entry
        ApprovalsMgmt.ApproveApprovalRequests(ApprovalEntry);

        // [THEN] "Approval Entry".Status = Approved
        FindApprovalEntry(ApprovalEntry, SubstituteUserId, ApprovalEntry."Document No.");
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Approved);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApprovalAdministratorRejectApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApproverUserId: Code[50];
        SubstituteUserId: Code[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379842] Approval Administrator can reject request if "Approval Entry"."Approver ID" and "Approval Entry"."Sender ID" are not equal to USERID

        ApprovalEntry.DeleteAll();

        // [GIVEN] Approval Administrator = "User 1"
        UpdateApprovalAdministrator(true);

        // [GIVEN] User setup for approver - "User 2" with substitute "User 3"
        MockApprovalSubstituteUserSetup(ApproverUserId, SubstituteUserId);

        // [GIVEN] Approval Entry has "Approver ID" = User2 and "Sender ID" = User3
        MockApprovalEntry(ApprovalEntry, ApproverUserId, SubstituteUserId);

        // [WHEN] Reject approval entry
        ApprovalsMgmt.RejectApprovalRequests(ApprovalEntry);

        // [THEN] "Approval Entry".Status = Rejected
        FindApprovalEntry(ApprovalEntry, SubstituteUserId, ApprovalEntry."Document No.");
        ApprovalEntry.TestField(Status, ApprovalEntry.Status::Rejected);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ApprovalAdministratorDelegateApprovalEntry()
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApproverUserId: Code[50];
        SubstituteUserId: Code[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379842] Approval Administrator can delegate request if "Approval Entry"."Approver ID" and "Approval Entry"."Sender ID" are not equal to USERID
        ApprovalEntry.DeleteAll();

        // [GIVEN] Approval Administrator = "User 1"
        UpdateApprovalAdministrator(true);

        // [GIVEN] User setup for approver - "User 2" with substitute "User 3"
        MockApprovalSubstituteUserSetup(ApproverUserId, SubstituteUserId);

        // [GIVEN] Approval Entry has "Approver ID" = User2 and "Sender ID" = User3
        MockApprovalEntry(ApprovalEntry, ApproverUserId, SubstituteUserId);

        // [WHEN] Delegate approval entry
        ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);

        // [THEN] "Approval Entry"."Approver ID" = "User 3"
        FindApprovalEntry(ApprovalEntry, SubstituteUserId, ApprovalEntry."Document No.");
        ApprovalEntry.TestField("Approver ID", SubstituteUserId);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FilterApprovalEntriesWhenUserisSenderOrApprover()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379842] "Approval Entry".MarkAllWhereUserisApproverOrSender passes entries when user is Sender or Approver
        ApprovalEntry.DeleteAll();

        // [GIVEN] Approval Entry[1]."Approver ID" = USERID Approval Entry[1]."Sender ID" = "USER_A"
        MockApprovalEntry(ApprovalEntry, UserId, LibraryUtility.GenerateGUID());

        // [GIVEN] Approval Entry[2]."Approver ID" = "USER_A" Approval Entry[2]."Sender ID" = "USER_A"
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [GIVEN] Approval Entry[3]."Approver ID" = "USER_A" Approval Entry[3]."Sender ID" = USERID
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), UserId);

        // [WHEN] Call "MarkAllWhereUserisApproverOrSender" function of "Approval Entry" table
        ApprovalEntry.MarkAllWhereUserisApproverOrSender();

        // [THEN] Approval Entry[1] and Approval Entry[3] are available
        ApprovalEntry.FindSet();
        ApprovalEntry.TestField("Approver ID", UserId);
        ApprovalEntry.Next();
        ApprovalEntry.TestField("Sender ID", UserId);

        Assert.RecordCount(ApprovalEntry, 2);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure FilterApprovalEntriesWhenUserisApprovalAdministrator()
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 379842] "Approval Entry".MarkAllWhereUserisApproverOrSender passes all entries when user is Approval Administrator.
        ApprovalEntry.DeleteAll();

        // [GIVEN] Approval Entry[1]."Approver ID" = USERID Approval Entry[1]."Sender ID" = "USER_A"
        MockApprovalEntry(ApprovalEntry, UserId, LibraryUtility.GenerateGUID());

        // [GIVEN] Approval Entry[2]."Approver ID" = "USER_A" Approval Entry[2]."Sender ID" = "USER_A"
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());

        // [GIVEN] Approval Entry[3]."Approver ID" = "USER_A" Approval Entry[3]."Sender ID" = USERID
        MockApprovalEntry(ApprovalEntry, LibraryUtility.GenerateGUID(), UserId);

        // [GIVEN] User is the approval administrator.
        UpdateApprovalAdministrator(true);

        // [WHEN] Call "MarkAllWhereUserisApproverOrSender" function of "Approval Entry" table
        ApprovalEntry.MarkAllWhereUserisApproverOrSender();

        // [THEN] All entries are available
        Assert.RecordCount(ApprovalEntry, 3);

        // Teardown
        TestCleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationEmailUrlIsBasedOnRecipientNotificationSetup()
    var
        User: Record User;
        NotificationSetup: Record "Notification Setup";
        NotificationSetupArray: array[2] of Record "Notification Setup";
        NotificationEntry: Record "Notification Entry";
        FileManagement: Codeunit "File Management";
        BodyTextXML: Text;
        RecipientUser: Code[50];
    begin
        // [FEATURE] [Notification Setup] [UT]
        // [SCENARIO 284134] URL created in Approval Entry
        Initialize();
        NotificationSetup.DeleteAll();
        NotificationEntry.DeleteAll();

        // [GIVEN] Notification Recipient has User table entry, where Recipient <> USERID
        RecipientUser := LibraryUtility.GenerateGUID();
        LibraryPermissions.CreateUser(User, RecipientUser, true);

        // [GIVEN] Notification Setup with Approval type, Email method, for all users, DisplayTarget = Windows
        CreateNotificationSetupWithDisplayTarget(
          NotificationSetupArray[1], '', NotificationSetupArray[1]."Notification Type"::Approval,
          NotificationSetupArray[1]."Notification Method"::Email);

        // [GIVEN] Notification Setup with Approval type, Email method, for Recipient, DisplayTarget = Web
        CreateNotificationSetupWithDisplayTarget(
          NotificationSetupArray[2], RecipientUser, NotificationSetupArray[2]."Notification Type"::Approval,
          NotificationSetupArray[2]."Notification Method"::Email);

        // [GIVEN] Sales Invoice "SI" and Approval Entry created for "SI" for the Recipient
        // [GIVEN] Notification Entry created for USER based on created Approval Entry
        CreateApprovalEntryForSalesHeaderWithNotification(NotificationEntry, RecipientUser);

        // [WHEN] Notification Email body generated and saved as XML
        BodyTextXML := FileManagement.ServerTempFileName('xml');
        NotificationEntry.SetRecFilter();
        REPORT.SaveAsXml(REPORT::"Notification Email", BodyTextXML, NotificationEntry);

        // [THEN] Verify URL generated for "SI" contains Web Client port number for "SI" and Notification Setup Settings
        VerifyGeneratedURLForApprovalNotificationEmail(BodyTextXML, '48900');

        // Teardown
        TestCleanup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUserSetupPhoneNo()
    var
        UserSetup: Record "User Setup";
    begin
        // [GIVEN] User setup
        LibraryDocumentApprovals.CreateMockupUserSetup(UserSetup);
        // [WHEN] Enter letters in the "Phone No." field
        asserterror UserSetup.Validate("Phone No.", LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(UserSetup."Phone No."), 1));
        // [THEN] Error is shown: 'Phone No. must not contain letters'
        Assert.ExpectedError(PhoneNoCannotContainLettersErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotificationSettingIsBasedOnRecipientNotificationSetup()
    var
        User: Record User;
        NotificationSetup: Record "Notification Setup";
        NotificationSetupArray: array[2] of Record "Notification Setup";
        NotificationEntry: Record "Notification Entry";
        FileManagement: Codeunit "File Management";
        BodyTextXML: Text;
        RecipientUser: Code[50];
    begin
        // [SCENARIO 457183] The Approval Notification message allows to modify general Notification settings instead of the Approver Notification Settings.
        Initialize();
        NotificationSetup.DeleteAll();
        NotificationEntry.DeleteAll();

        // [GIVEN] Notification Recipient has User table entry, where Recipient <> USERID
        RecipientUser := LibraryUtility.GenerateGUID();
        LibraryPermissions.CreateUser(User, RecipientUser, true);

        // [GIVEN] Notification Setup with Approval type, Email method, for all users, DisplayTarget = Windows
        CreateNotificationSetupWithDisplayTarget(
          NotificationSetupArray[1], '', NotificationSetupArray[1]."Notification Type"::Approval,
          NotificationSetupArray[1]."Notification Method"::Email);

        // [GIVEN] Notification Setup with Approval type, Email method, for Recipient, DisplayTarget = Web
        CreateNotificationSetupWithDisplayTarget(
          NotificationSetupArray[2], RecipientUser, NotificationSetupArray[2]."Notification Type"::Approval,
          NotificationSetupArray[2]."Notification Method"::Email);

        // [GIVEN] Sales Invoice "SI" and Approval Entry created for "SI" for the Recipient
        // [GIVEN] Notification Entry created for USER based on created Approval Entry
        CreateApprovalEntryForSalesHeaderWithNotification(NotificationEntry, RecipientUser);

        // [WHEN] Notification Email body generated and saved as XML
        BodyTextXML := FileManagement.ServerTempFileName('xml');
        NotificationEntry.SetRecFilter();
        REPORT.SaveAsXml(REPORT::"Notification Email", BodyTextXML, NotificationEntry);

        // [THEN] Verify URL generated for Notification Setup Settings
        VerifyNotificationURLForApprovalNotificationEmail(BodyTextXML, UserId);
    end;

    local procedure ApproveRequest(var ApprovalsMgmt: Codeunit "Approvals Mgmt."; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        GetOpenApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
        ApprovalEntry.SetRecFilter();
        ApprovalsMgmt.ApproveApprovalRequests(ApprovalEntry);
    end;

    local procedure VerifyRelatedRecordsForEmail(SalesHeader: Record "Sales Header")
    var
        ConnectorMock: Codeunit "Connector Mock";
        EmailScenarioMock: Codeunit "Email Scenario Mock";
        TempAccount: Record "Email Account" temporary;
        UserSetup: Record "User Setup";
        SentEmail: Record "Sent Email";
        ApprovalEntry: Record "Approval Entry";
        NotificationEntry: Record "Notification Entry";
        RecRef: RecordRef;
        MessageIdFieldRef: FieldRef;
        RecordTypeOccurences: Array[2] of Integer;
        RecRefTableId: Integer;
        Index: Integer;
    begin
        // [Scenario] User has set up an email account, a document approval workflow for Sales Invoices, and requests approval for a Sales Invoice.
        Initialize();
        ConnectorMock.Initialize();
        ConnectorMock.AddAccount(TempAccount);
        EmailScenarioMock.DeleteAllMappings();
        EmailScenarioMock.AddMapping(Enum::"Email Scenario"::Default, TempAccount."Account Id", TempAccount.Connector);

        SentEmail.DeleteAll();
        ApprovalEntry.DeleteAll();
        NotificationEntry.DeleteAll();

        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", "Sales Document Type"::Invoice, '');

        // [Given] A Sales Invoice, Approval Entry and Notification Entry
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibraryDocumentApprovals.CreateApprovalEntryBasic(
            ApprovalEntry, DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
            ApprovalEntry.Status::Open, ApprovalEntry."Limit Type"::"Approval Limits",
            SalesHeader.RecordId, ApprovalEntry."Approval Type"::Approver, 0D, 0);
        NotificationEntry.CreateNotificationEntry(NotificationEntry.Type::Approval, UserSetup."Approver ID", ApprovalEntry, 1, '', UserSetup."User ID");

        // [When] Requesting approval of invoice
        Codeunit.run(Codeunit::"Notification Entry Dispatcher");

        // [Then] Approval request email is sent
        Assert.AreEqual(1, SentEmail.Count, 'A single email should be in sent');

        // [Then] The email has Related Records
        SentEmail.FindFirst();
        RecRef.Open(8909); // Related Record
        MessageIdFieldRef := RecRef.Field(1); // Message ID
        MessageIdFieldRef.SetRange(SentEmail.GetMessageId());
        RecRef.FindSet();

        // [Then] The Related Records should contain one Notification Entry and one Sales Header
        repeat
            RecRefTableId := RecRef.Field(2).Value(); // Table ID
            if RecRefTableId = NotificationEntry.RecordId.TableNo then
                RecordTypeOccurences[1] += 1;

            if RecRefTableId = SalesHeader.RecordId.TableNo then
                RecordTypeOccurences[2] += 1;
        until RecRef.Next() = 0;

        for Index := 1 to 2 do
            Assert.AreEqual(1, RecordTypeOccurences[Index], 'There should be exactly one occurence of each type of Related Record');

        // Teardown
        TestCleanup();
    end;

    local procedure ApproveRequestForPurchDocument(DocumentType: Enum "Purchase Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Pre-Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", DocumentType, '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");

        // Exercise
        ApproveRequest(ApprovalsMgmt, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");

        // Verify
        VerifyApprovalEntries(DATABASE::"Purchase Header", DocumentType, PurchHeader."No.", UserSetup."Approver ID", UserSetup."User ID",
          UserSetup."User ID", UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);
        PurchHeader.Get(DocumentType, PurchHeader."No.");
        PurchHeader.TestField(Status, PurchHeader.Status::Released);

        // Teardown
        TestCleanup();
    end;

    local procedure ApproveRequestForSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Pre-Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", DocumentType, '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");

        // Exercise
        ApproveRequest(ApprovalsMgmt, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");

        // Verify
        VerifyApprovalEntries(DATABASE::"Sales Header", DocumentType, SalesHeader."No.", UserSetup."Approver ID", UserSetup."User ID",
          UserSetup."User ID", UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);
        SalesHeader.Get(DocumentType, SalesHeader."No.");
        SalesHeader.TestField(Status, SalesHeader.Status::Released);

        // Teardown
        TestCleanup();
    end;

    local procedure CancelRequestByRequestorForPurchDocument(DocumentType: Enum "Purchase Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Pre-Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", DocumentType, '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Exercise
        ApprovalsMgmt.OnCancelPurchaseApprovalRequest(PurchHeader);

        // Verify
        VerifyApprovalEntries(DATABASE::"Purchase Header", DocumentType, PurchHeader."No.", UserSetup."User ID", UserSetup."User ID",
          UserSetup."Approver ID", UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Canceled, ApprovalEntry.Status::Canceled);

        // Teardown
        TestCleanup();
    end;

    local procedure CancelRequestByRequestorForSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        // Pre-Setup
        Initialize();
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", DocumentType, '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Exercise
        ApprovalsMgmt.OnCancelSalesApprovalRequest(SalesHeader);

        // Verify
        VerifyApprovalEntries(DATABASE::"Sales Header", DocumentType, SalesHeader."No.", UserSetup."User ID", UserSetup."User ID",
          UserSetup."Approver ID", UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Canceled, ApprovalEntry.Status::Canceled);

        // Teardown
        TestCleanup();
    end;

    local procedure CreateApprovalEntryForSalesHeaderWithNotification(var NotificationEntry: Record "Notification Entry"; RecipientUser: Code[50])
    var
        SalesHeader: Record "Sales Header";
        ApprovalEntry: Record "Approval Entry";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibraryDocumentApprovals.CreateApprovalEntryBasic(
            ApprovalEntry, DATABASE::"Sales Header", SalesHeader."Document Type", SalesHeader."No.",
            ApprovalEntry.Status::Open, ApprovalEntry."Limit Type"::"Approval Limits", SalesHeader.RecordId,
            ApprovalEntry."Approval Type"::Approver, 0D, 0);
        ApprovalEntry."Approver ID" := RecipientUser;
        ApprovalEntry.Modify();

        NotificationEntry.Init();
        NotificationEntry.Type := NotificationEntry.Type::Approval;
        NotificationEntry."Recipient User ID" := RecipientUser;
        NotificationEntry."Triggered By Record" := ApprovalEntry.RecordId;
        NotificationEntry.Insert();
    end;

    local procedure CreateNotificationSetupWithDisplayTarget(var NotificationSetup: Record "Notification Setup"; UserName: Code[50]; NotificationType: Enum "Notification Entry Type"; NotificationMethod: Enum "Notification Method Type")
    begin
        LibraryWorkflow.CreateNotificationSetup(NotificationSetup, UserName, NotificationType, NotificationMethod);
        NotificationSetup.Modify();
    end;

    local procedure CreatePurchDocument(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchLine: Record "Purchase Line";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, DocumentType, LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(10));
    end;

    local procedure CreatePurchDocumentWithDirectCost(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; Cost: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        CreatePurchDocument(PurchHeader, DocumentType);
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindFirst();
        PurchLine.Validate("Direct Unit Cost", Cost);
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchDocumentWithPurchaserCode(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PurchaserCode: Code[20])
    begin
        CreatePurchDocument(PurchHeader, DocumentType);
        PurchHeader.Validate("Purchaser Code", PurchaserCode);
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchDocumentWithApprovalAmount(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; PurchaserCode: Code[20]; var ApprovalAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApprovalAmountLCY: Decimal;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Purchaser Code", PurchaserCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 500, 2));
        PurchaseLine.Modify(true);

        ApprovalsMgmt.CalcPurchaseDocAmount(PurchaseHeader, ApprovalAmount, ApprovalAmountLCY);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType, LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesDocumentWithSalespersonCode(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SalespersonCode: Code[20])
    begin
        CreateSalesDocument(SalesHeader, DocumentType);
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocWithCustAndSalesPerson(var SalesHeader: Record "Sales Header"; Customer: Record Customer; DocumentType: Enum "Sales Document Type"; SalespersonCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify();

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", Customer."Credit Limit (LCY)" + 0.01); // to exceed Customer Credit Limit
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithApprovalAmount(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SalespersonCode: Code[20]; var ApprovalAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ApprovalAmountLCY: Decimal;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType, LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Salesperson Code", SalespersonCode);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 500, 2));
        SalesLine.Modify(true);

        ApprovalsMgmt.CalcSalesDocAmount(SalesHeader, ApprovalAmount, ApprovalAmountLCY);
    end;

    local procedure CreateUser(var User: Record User; WindowsUserName: Text[50])
    begin
        LibraryPermissions.CreateUser(User, WindowsUserName, true);
    end;

    local procedure MockApprovalComment(SourceRecordID: RecordID; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    var
        ApprovalCommentLine: Record "Approval Comment Line";
        LastEntryNo: Integer;
    begin
        LastEntryNo := 0;
        if ApprovalCommentLine.FindLast() then
            LastEntryNo := ApprovalCommentLine."Entry No.";
        ApprovalCommentLine.Init();
        ApprovalCommentLine."Entry No." := LastEntryNo + 1;
        ApprovalCommentLine."Table ID" := SourceRecordID.TableNo;
        ApprovalCommentLine."Document Type" := DocumentType;
        ApprovalCommentLine."Document No." := DocumentNo;
        ApprovalCommentLine."Record ID to Approve" := SourceRecordID;
        ApprovalCommentLine.Comment := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ApprovalCommentLine.Comment)), 1, MaxStrLen(ApprovalCommentLine.Comment));
        ApprovalCommentLine.Insert();
    end;

    local procedure MockApprovalEntry(var ApprovalEntry: Record "Approval Entry"; ApproverId: Code[50]; SenderId: Code[50])
    begin
        Clear(ApprovalEntry);
        ApprovalEntry.Init();
        ApprovalEntry.Validate("Document No.",
          LibraryUtility.GenerateRandomCode(ApprovalEntry.FieldNo("Document No."), DATABASE::"Approval Entry"));
        ApprovalEntry."Approver ID" := ApproverId;
        ApprovalEntry.Status := ApprovalEntry.Status::Open;
        ApprovalEntry."Sender ID" := SenderId;
        ApprovalEntry."Table ID" := DATABASE::"Sales Header";
        ApprovalEntry.Insert();
    end;

    local procedure MockApprovalSubstituteUserSetup(var ApproverUserId: Code[50]; var SubstituteUserId: Code[50])
    var
        ApproverUserSetup: Record "User Setup";
        SubstituteUserSetup: Record "User Setup";
    begin
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        LibraryDocumentApprovals.CreateMockupUserSetup(SubstituteUserSetup);
        ApproverUserSetup.Substitute := SubstituteUserSetup."User ID";
        ApproverUserSetup.Modify();
        ApproverUserId := ApproverUserSetup."User ID";
        SubstituteUserId := SubstituteUserSetup."User ID";
    end;

    local procedure GenerateUserName() UserName: Code[50]
    var
        User: Record User;
    begin
        repeat
            UserName :=
              CopyStr(LibraryUtility.GenerateRandomCode(User.FieldNo("User Name"), DATABASE::User),
                1, LibraryUtility.GetFieldLength(DATABASE::User, User.FieldNo("User Name")));
            User.SetRange("User Name", UserName);
        until User.IsEmpty();
    end;

    local procedure DelegateApprovalRequest(var ApprovalsMgmt: Codeunit "Approvals Mgmt."; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        GetOpenApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
        ApprovalEntry.SetRecFilter();
        ApprovalsMgmt.DelegateApprovalRequests(ApprovalEntry);
    end;

    local procedure DelegateRequestForPurchDocument(DocumentType: Enum "Purchase Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        UserSetup: Record "User Setup";
        PurchHeader: Record "Purchase Header";
        SubstituteUserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        Initialize();
        // Pre-Setup
        LibraryDocumentApprovals.CreateMockupUserSetup(SubstituteUserSetup);
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", DocumentType,
          SubstituteUserSetup."User ID");

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");
        UpdateSubstitute(UserSetup, SubstituteUserSetup."User ID");

        // Exercise
        DelegateApprovalRequest(ApprovalsMgmt, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");

        // Verify
        VerifyApprovalEntries(DATABASE::"Purchase Header", DocumentType, PurchHeader."No.", UserSetup."Approver ID", UserSetup."User ID",
          UserSetup.Substitute, UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Teardown
        TestCleanup();
    end;

    local procedure DelegateRequestForSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        SubstituteUserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        Initialize();
        // Pre-Setup
        LibraryDocumentApprovals.CreateMockupUserSetup(SubstituteUserSetup);
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", DocumentType, SubstituteUserSetup."User ID");

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");
        UpdateSubstitute(UserSetup, SubstituteUserSetup."User ID");

        // Exercise
        DelegateApprovalRequest(ApprovalsMgmt, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");

        // Verify
        VerifyApprovalEntries(DATABASE::"Sales Header", DocumentType, SalesHeader."No.", UserSetup."Approver ID", UserSetup."User ID",
          UserSetup.Substitute, UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Teardown
        TestCleanup();
    end;

    local procedure DoubleRequestApprovalForPurchDocument(DocumentType: Enum "Purchase Document Type")
    var
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", DocumentType, '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Exercise
        PurchHeader.Get(DocumentType, PurchHeader."No.");
        PurchHeader.TestField(Status, PurchHeader.Status::"Pending Approval");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Verify
        PurchHeader.Find();
        PurchHeader.TestField(Status, PurchHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    local procedure DoubleRequestApprovalForSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", DocumentType, '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Exercise
        SalesHeader.Get(DocumentType, SalesHeader."No.");
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Approval");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Verify
        SalesHeader.Find();
        SalesHeader.TestField(Status, SalesHeader.Status::"Pending Approval");

        // Teardown
        TestCleanup();
    end;

    local procedure GetApprovalEntries(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    begin
        ApprovalEntry.SetRange("Table ID", TableID);
        ApprovalEntry.SetRange("Document Type", DocumentType);
        ApprovalEntry.SetRange("Document No.", DocumentNo);
        ApprovalEntry.FindSet();
    end;

    local procedure GetOpenApprovalEntries(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    begin
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Open);
        GetApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
    end;

    local procedure ModifyApprovedPurchDocument(DocumentType: Enum "Purchase Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", DocumentType, '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");
        ApproveRequest(ApprovalsMgmt, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");
        UserSetup."Unlimited Purchase Approval" := true;
        UserSetup."Unlimited Request Approval" := true;
        UserSetup.Modify();

        // Exercise
        PurchHeader.Get(DocumentType, PurchHeader."No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchHeader);
        UpdateQuantityAndDirectUnitCostOnPurchaseLine(PurchHeader);

        // Verify
        VerifyApprovalEntries(DATABASE::"Purchase Header", DocumentType, PurchHeader."No.", UserSetup."Approver ID", UserSetup."User ID",
          UserSetup."User ID", UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);

        // Teardown
        TestCleanup();
    end;

    local procedure ModifyApprovedSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", DocumentType, '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");
        ApproveRequest(ApprovalsMgmt, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");
        UserSetup."Unlimited Sales Approval" := true;
        UserSetup.Modify();

        // Exercise
        SalesHeader.Get(DocumentType, SalesHeader."No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        UpdateQuantityAndUnitPriceOnSalesLine(SalesHeader);

        // Verify
        VerifyApprovalEntries(DATABASE::"Sales Header", DocumentType, SalesHeader."No.", UserSetup."Approver ID", UserSetup."User ID",
          UserSetup."User ID", UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Approved, ApprovalEntry.Status::Approved);

        // Teardown
        TestCleanup();
    end;

    local procedure RejectApprovalRequest(var ApprovalsMgmt: Codeunit "Approvals Mgmt."; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        GetOpenApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
        ApprovalEntry.SetRecFilter();
        ApprovalsMgmt.RejectApprovalRequests(ApprovalEntry);
    end;

    local procedure RejectRequestForPurchDocument(DocumentType: Enum "Purchase Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        PurchHeader: Record "Purchase Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", DocumentType, '');

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");

        // Exercise
        RejectApprovalRequest(ApprovalsMgmt, DATABASE::"Purchase Header", DocumentType, PurchHeader."No.");

        // Verify
        VerifyApprovalEntries(DATABASE::"Purchase Header", DocumentType, PurchHeader."No.", UserSetup."Approver ID", UserSetup."User ID",
          UserSetup."User ID", UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);
        PurchHeader.Get(DocumentType, PurchHeader."No.");
        PurchHeader.TestField(Status, PurchHeader.Status::Open);

        // Teardown
        TestCleanup();
    end;

    local procedure RejectRequestForSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", DocumentType, '');

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);
        UpdateApprovalEntryWithTempUser(UserSetup, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");

        // Exercise
        RejectApprovalRequest(ApprovalsMgmt, DATABASE::"Sales Header", DocumentType, SalesHeader."No.");

        // Verify
        VerifyApprovalEntries(DATABASE::"Sales Header", DocumentType, SalesHeader."No.", UserSetup."Approver ID", UserSetup."User ID",
          UserSetup."User ID", UserSetup."Salespers./Purch. Code", ApprovalEntry.Status::Rejected, ApprovalEntry.Status::Rejected);
        SalesHeader.Get(DocumentType, SalesHeader."No.");
        SalesHeader.TestField(Status, SalesHeader.Status::Open);

        // Teardown
        TestCleanup();
    end;

    local procedure RequestApprovalForPurchDocument(DocumentType: Enum "Purchase Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        ExpectedUserSetup: Record "User Setup";
        UserSetup: Record "User Setup";
        PurchHeader: Record "Purchase Header";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Purchase Header", DocumentType, '');
        ExpectedUserSetup := UserSetup;

        // Setup
        CreatePurchDocumentWithPurchaserCode(PurchHeader, DocumentType, UserSetup."Salespers./Purch. Code");

        // Exercise
        ApprovalsMgmt.OnSendPurchaseDocForApproval(PurchHeader);

        // Verify
        VerifyApprovalEntries(DATABASE::"Purchase Header", DocumentType, PurchHeader."No.", ExpectedUserSetup."User ID",
          ExpectedUserSetup."User ID", ExpectedUserSetup."Approver ID", ExpectedUserSetup."Salespers./Purch. Code",
          ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Teardown
        TestCleanup();
    end;

    local procedure RequestApprovalForSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        ApprovalEntry: Record "Approval Entry";
        ExpectedUserSetup: Record "User Setup";
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        Initialize();
        // Pre-Setup
        SetupDocumentApprovals(UserSetup, DATABASE::"Sales Header", DocumentType, '');
        ExpectedUserSetup := UserSetup;

        // Setup
        CreateSalesDocumentWithSalespersonCode(SalesHeader, DocumentType, UserSetup."Salespers./Purch. Code");

        // Exercise
        ApprovalsMgmt.OnSendSalesDocForApproval(SalesHeader);

        // Verify
        VerifyApprovalEntries(DATABASE::"Sales Header", DocumentType, SalesHeader."No.", ExpectedUserSetup."User ID",
          ExpectedUserSetup."User ID", ExpectedUserSetup."Approver ID", ExpectedUserSetup."Salespers./Purch. Code",
          ApprovalEntry.Status::Approved, ApprovalEntry.Status::Open);

        // Teardown
        TestCleanup();
    end;

    local procedure SetApprovalAdmin(ApprovalAdministrator: Code[50])
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.Get(ApprovalAdministrator);
        UserSetup."Approval Administrator" := true;
        UserSetup.Modify();
    end;

    local procedure SetupApprovalWorkflows(TableNo: Integer; DocumentType: Enum "Approval Document Type")
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
                    Workflow, "Purchase Document Type".FromInteger(DocumentType.AsInteger()),
                    WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser", WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
                    '', BlankDateFormula);
            DATABASE::"Sales Header":
                WorkflowSetup.InsertSalesDocumentApprovalWorkflowSteps(
                    Workflow, "Sales Document Type".FromInteger(DocumentType.AsInteger()),
                    WorkflowStepArgument."Approver Type"::"Salesperson/Purchaser", WorkflowStepArgument."Approver Limit Type"::"Approver Chain",
                    '', BlankDateFormula);
        end;

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure SetupDocumentApprovals(var UserSetup: Record "User Setup"; TableNo: Integer; DocumentType: Enum "Approval Document Type"; Substitute: Code[50])
    begin
        SetupUsers(UserSetup, Substitute, false, false, false, 0, 0, 0);
        SetApprovalAdmin(UserSetup."Approver ID");
        SetupApprovalWorkflows(TableNo, DocumentType);
    end;

    local procedure SetupUsers(var RequestorUserSetup: Record "User Setup"; Substitute: Code[50]; UnlimitedSalesApproval: Boolean; UnlimitedPurchaseApproval: Boolean; UnlimitedRequestApproval: Boolean; SalesAmountApprovalLimit: Integer; PurchaseAmountApprovalLimit: Integer; RequestAmountApprovalLimit: Integer)
    var
        ApproverUserSetup: Record "User Setup";
        RequestorUser: Record User;
    begin
        LibraryDocumentApprovals.CreateMockupUserSetup(ApproverUserSetup);
        UpdateSubstitute(ApproverUserSetup, Substitute);

        if LibraryDocumentApprovals.UserExists(UserId) then
            LibraryDocumentApprovals.GetUser(RequestorUser, UserId)
        else
            CreateUser(RequestorUser, UserId);

        if LibraryDocumentApprovals.GetUserSetup(RequestorUserSetup, UserId) then
            LibraryDocumentApprovals.DeleteUserSetup(RequestorUserSetup, UserId);

        LibraryDocumentApprovals.CreateUserSetup(RequestorUserSetup, RequestorUser."User Name", ApproverUserSetup."User ID");
        LibraryDocumentApprovals.UpdateApprovalLimits(RequestorUserSetup, UnlimitedSalesApproval, UnlimitedPurchaseApproval,
          UnlimitedRequestApproval, SalesAmountApprovalLimit, PurchaseAmountApprovalLimit, RequestAmountApprovalLimit);
    end;

    local procedure SetupCurrUser(var UserSetup: Record "User Setup")
    begin
        LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId, UserId);
        LibraryDocumentApprovals.UpdateApprovalLimits(UserSetup, true, true, true, 0, 0, 0);
    end;

    local procedure SetupNonWindowsUser(var UserSetup: Record "User Setup")
    var
        User: Record User;
        UserName: Code[50];
    begin
        UserName := GenerateUserName();
        LibraryPermissions.CreateUser(User, UserName, false);
        UserSetup.Validate("User ID", UserName);
        UserSetup.Insert(true);
    end;

    local procedure SetupApproverAndPurchAmountApprovalLimit(var RequestorUserSetup: Record "User Setup"; ApproverId: Code[50]; PurchaseAmountApprovalLimit: Integer)
    begin
        RequestorUserSetup."Approver ID" := ApproverId;
        LibraryDocumentApprovals.UpdateApprovalLimits(
          RequestorUserSetup, false, false, false, 0, PurchaseAmountApprovalLimit, 0);
    end;

    local procedure SetupApproverAndSalesAmountApprovalLimit(var RequestorUserSetup: Record "User Setup"; ApproverId: Code[50]; SalesAmountApprovalLimit: Integer)
    begin
        RequestorUserSetup."Approver ID" := ApproverId;
        LibraryDocumentApprovals.UpdateApprovalLimits(
          RequestorUserSetup, false, false, false, SalesAmountApprovalLimit, 0, 0);
    end;

    local procedure ShowDocumentFromApprovalEntry(TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        GetOpenApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
        ApprovalEntry.ShowRecord();
    end;

    local procedure UpdateApprovalEntryWithTempUser(UserSetup: Record "User Setup"; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20])
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        GetApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
        ApprovalEntry.ModifyAll("Sender ID", UserSetup."Approver ID", true);
        ApprovalEntry.ModifyAll("Approver ID", UserSetup."User ID", true);
    end;

    local procedure UpdateQuantityAndDirectUnitCostOnPurchaseLine(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindFirst();
        PurchLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Direct Unit Cost", 0);
        PurchLine.Modify(true);
    end;

    local procedure UpdateQuantityAndUnitPriceOnSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", 0);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSubstitute(var UserSetup: Record "User Setup"; Substitute: Code[50])
    begin
        UserSetup.Validate(Substitute, Substitute);
        UserSetup.Modify(true);
    end;

    local procedure UpdateApprovalAdministrator(ApprovalAdministrator: Boolean)
    var
        UserSetup: Record "User Setup";
    begin
        SetupCurrUser(UserSetup);
        UserSetup."Approval Administrator" := ApprovalAdministrator;
        UserSetup.Modify();
    end;

    local procedure FindSalesOrderNoByQuoteNo(QuoteNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.SetRange("Quote No.", QuoteNo);
        SalesHeader.FindFirst();
        exit(SalesHeader."No.");
    end;

    local procedure FindPurchOrderNoByQuoteNo(QuoteNo: Code[20]; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.SetRange("Quote No.", QuoteNo);
        PurchaseHeader.FindFirst();
        exit(PurchaseHeader."No.");
    end;

    local procedure FindApprovalEntry(var ApprovalEntry: Record "Approval Entry"; SenderId: Code[50]; DocumentNo: Code[20])
    begin
        ApprovalEntry.SetRange("Sender ID", SenderId);
        ApprovalEntry.SetRange("Document No.", DocumentNo);
        ApprovalEntry.FindFirst();
    end;

    local procedure TestCleanup()
    var
        UserSetup: Record "User Setup";
        AccessControl: Record "Access Control";
    begin
        // When we add any user into User table Server switches authentication mode
        // and further tests fail with permission error until Server is restarted.
        // Automatic rollback in test isolation does not revert Server's authentication mode.
        // In this case we need manually clean up User table if test passed and User table
        // is modified during this test.
        // User Setup must cleaned too, due to reference to User table.
        DeleteAllUsers();
        UserSetup.DeleteAll(true);
        AccessControl.DeleteAll(true);
    end;

    local procedure DeleteAllUsers()
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        if User.FindFirst() then begin
            if UserPersonalization.Get(User."User Security ID") then
                UserPersonalization.Delete();
            User.Delete();
        end;
    end;

    local procedure VerifyRequestorAndApproverEntries(var ApprovalEntry: Record "Approval Entry"; TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20]; SenderID: Code[50]; SalespersPurchCode: Code[20]; RequestorID: Code[50]; ApproverID: Code[50]; RequestorStatus: Enum "Approval Status"; ApproverStatus: Enum "Approval Status")
    begin
        GetApprovalEntries(ApprovalEntry, TableID, DocumentType, DocumentNo);
        ValidateApprovalEntry(ApprovalEntry, 1, SenderID, SalespersPurchCode, RequestorID, RequestorStatus);
        ApprovalEntry.Next();
        ValidateApprovalEntry(ApprovalEntry, 2, SenderID, SalespersPurchCode, ApproverID, ApproverStatus);
    end;

    local procedure VerifyApprovalCommentLineExist(SourceRecordID: RecordID)
    var
        DummyApprovalCommentLine: Record "Approval Comment Line";
    begin
        DummyApprovalCommentLine.SetRange("Table ID", SourceRecordID.TableNo);
        DummyApprovalCommentLine.SetRange("Record ID to Approve", SourceRecordID);
        Assert.RecordIsNotEmpty(DummyApprovalCommentLine);
    end;

    local procedure ValidateApprovalEntry(var ApprovalEntry: Record "Approval Entry"; SequenceNo: Integer; SenderID: Code[50]; SalespersonPurchCode: Code[20]; ApproverID: Code[50]; Status: Enum "Approval Status")
    begin
        ApprovalEntry.TestField("Sequence No.", SequenceNo);
        ApprovalEntry.TestField("Sender ID", SenderID);
        ApprovalEntry.TestField("Salespers./Purch. Code", SalespersonPurchCode);
        ApprovalEntry.TestField("Approver ID", ApproverID);
        ApprovalEntry.TestField(Status, Status);
        ApprovalEntry.TestField("Approval Type", ApprovalEntry."Approval Type"::"Sales Pers./Purchaser");
    end;

    local procedure VerifyApprovalEntries(TableID: Integer; DocumentType: Enum "Approval Document Type"; DocumentNo: Code[20]; SenderID: Code[50]; ApproverID: Code[50]; SubstituteApproverID: Code[50]; SalespersPurchCode: Code[20]; RequestorStatus: Enum "Approval Status"; ApproverStatus: Enum "Approval Status")
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        VerifyRequestorAndApproverEntries(ApprovalEntry, TableID, DocumentType, DocumentNo, SenderID, SalespersPurchCode, ApproverID,
          SubstituteApproverID, RequestorStatus, ApproverStatus);
        Assert.AreEqual(0, ApprovalEntry.Next(), WrongNumberOfApprovalEntriesMsg);
    end;

    local procedure VerifyGeneratedURLForApprovalNotificationEmail(BodyTextXML: Text; SubString: Text[20])
    var
        Node: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(true);
        LibraryXPathXMLReader.Initialize(BodyTextXML, '');
        LibraryXPathXMLReader.GetNodeByXPath('//ReportDataSet/DataItems/DataItem/DataItems/DataItem/Columns/Column[5]', Node);
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(Node, 'name', 'Document_Url');
        Assert.IsSubstring(Node.InnerText, SubString);

        LibraryXPathXMLReader.GetNodeByXPath('//ReportDataSet/DataItems/DataItem//Columns/Column[6]', Node);
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(Node, 'name', 'Settings_Url');
        Assert.IsSubstring(Node.InnerText, SubString);
    end;

    local procedure VerifyNotificationURLForApprovalNotificationEmail(BodyTextXML: Text; SubString: Text[20])
    var
        Node: DotNet XmlNode;
    begin
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(true);
        LibraryXPathXMLReader.Initialize(BodyTextXML, '');
        LibraryXPathXMLReader.GetNodeByXPath('//ReportDataSet/DataItems/DataItem//Columns/Column[6]', Node);
        LibraryXPathXMLReader.VerifyOptionalAttributeFromNode(Node, 'name', 'Settings_Url');
        Assert.IsSubstring(Node.InnerText, SubString);
    end;

    local procedure CreateCustomerWithCreditLimit(var Customer: Record Customer; CreditLimit: Decimal)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", CreditLimit);
        Customer.Modify(true);
    end;

    local procedure CreateSalesAndPurchOrdersWithDropShipment(var SalesHeader: Record "Sales Header"; var PurchHeader: Record "Purchase Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateDropShipmentLine(SalesLine, SalesHeader);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        CreatePurchHeader(PurchHeader, SalesHeader."Sell-to Customer No.", '');
        LibraryPurchase.GetDropShipment(PurchHeader);
    end;

    local procedure CreateDropShipmentLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    var
        Purchasing: Record Purchasing;
        Item: Record Item;
    begin
        CreateItemWithVendNo(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateItemWithVendNo(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);

        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(500, 2));
        Item.Modify(true);
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; SellToCustomerNo: Code[20]; ShipToCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        PurchHeader.Validate("Ship-to Code", ShipToCode);
        PurchHeader.Modify(true);
    end;

    local procedure CreateEnabledWorkflowForPurchaseOrder(var Workflow: Record Workflow)
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.DisableAllWorkflows();
        WorkflowSetup.InitWorkflow();

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.PurchaseOrderApprovalWorkflowCode());

        WorkflowEvent.Get(WorkflowEventHandling.RunWorkflowOnSendPurchaseDocForApprovalCode());
        WorkflowEvent.Validate("Request Page ID", REPORT::"Workflow Event Simple Args");
        WorkflowEvent.Modify(true);

        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    local procedure CreateEnabledWorkflowForSalesOrder(var Workflow: Record Workflow)
    var
        WorkflowEvent: Record "Workflow Event";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        LibraryWorkflow.DisableAllWorkflows();
        WorkflowSetup.InitWorkflow();

        LibraryWorkflow.CopyWorkflowTemplate(Workflow, WorkflowSetup.SalesOrderApprovalWorkflowCode());

        WorkflowEvent.Get(WorkflowEventHandling.RunWorkflowOnSendSalesDocForApprovalCode());
        WorkflowEvent.Validate("Request Page ID", REPORT::"Workflow Event Simple Args");
        WorkflowEvent.Modify(true);

        LibraryWorkflow.EnableWorkflow(Workflow);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApprovalUserSetupPageHandler(var ApprovalUserSetup: TestPage "Approval User Setup")
    begin
        Assert.AreNotEqual(StrSubstNo('<>%1', UserId), ApprovalUserSetup.FILTER.GetFilter("User ID"), '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Document Approval - Users");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Document Approval - Users");

        IsInitialized := true;
        BindSubscription(LibraryJobQueue);
        BindSubscription(DocumentApprovalUsers);

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Document Approval - Users");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;
}

