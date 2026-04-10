codeunit 134710 "Manual Payment Registration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Registration]
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryCashFlowHelper: Codeunit "Library - Cash Flow Helper";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        isInitialized: Boolean;
        OpenCustomerDocErr: Label 'Document with No = %1 for Customer No = %2 should not be open.';
        CreatedPaymentErr: Label 'Payment journal line was created.';
        FilterNotPreservedErr: Label 'Filter was not preserved after posting';
        RecordChangedErr: Label 'None of the fields from %1 should have changed.';
        OpenCustomerCardErr: Label 'Open customer card did not succeed';
        NavigateErr: Label 'Navigate did not succeed';
        DummyUserNameTxt: Label 'User2';
        WrongBalAccountErr: Label 'Wrong Balancing account for user %1.';
        WrongFieldValueErr: Label 'Field %1 has a wrong value.';
        WrongCustomerErr: Label 'Finance Charge Memo page is opened for an different customer.';
        DueDateMsg: Label 'The payment is overdue. You can calculate interest for late payments from customers by choosing the Finance Charge Memo button.';
        WrongWarningErr: Label 'Warning text shown is not correct.';
        DistinctDateReceivedErr: Label 'To post as a lump payment, the %1 field must have the same value in all lines where the %2 check box is selected.';
        DistinctCustomerErr: Label 'To post as lump payment, the customer must be same value on all lines where the %1 check box is selected.';
        ForeignCurrNotSuportedErr: Label 'The document with type %1 and description %2 must have the same currency code as the payment you are registering.', Comment = '%1 = Document Type; %2 = Description';
        UnexpectedPreviewErr: Label 'Unexpected preview entry.';

    [Test]
    [HandlerFunctions('HandlerSetupPageForEmptySetupTest')]
    [Scope('OnPrem')]
    procedure EmptySetup()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        PaymentRegistrationPage: TestPage "Payment Registration";
    begin
        Initialize();

        MoveDefaultSetupToDummyUserSetup(); // to keep Default setup, so we could restore it after.
        DeleteCurrentUserSetup();

        // HandlerFunctions has a verification.
        PaymentRegistrationPage.OpenEdit();
        PaymentRegistrationPage.Close();

        PaymentRegistrationSetup.Get(UserId);

        RestoreDefaultSetupFromDummyUser();
    end;

    [Test]
    [HandlerFunctions('HandlerSetupPageForDefaultSetupTest')]
    [Scope('OnPrem')]
    procedure DefaultSetup()
    var
        PaymentRegistrationSetupDefault: Record "Payment Registration Setup";
        PaymentRegistrationSetupMyUser: Record "Payment Registration Setup";
        PaymentRegistrationPage: TestPage "Payment Registration";
    begin
        Initialize();

        DeleteCurrentUserSetup();

        PaymentRegistrationSetupDefault.Get();
        // HandlerFunctions has a verification.
        PaymentRegistrationPage.OpenEdit();
        PaymentRegistrationPage.Close();
        PaymentRegistrationSetupMyUser.Get(UserId);

        ValidateExpectedAndActualSetupTables(PaymentRegistrationSetupDefault, PaymentRegistrationSetupMyUser);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentForFinanceChargeMemoBalAccountGL()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo := IssueFinanceChargeMemoAndMarkItAsPaid(FinanceChargeMemoHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(FinanceChargeMemoHeader."Customer No.", PostedDocNo, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentForFinanceChargeMemoBalAccountBank()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();

        PostedDocNo := IssueFinanceChargeMemoAndMarkItAsPaid(FinanceChargeMemoHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(FinanceChargeMemoHeader."Customer No.", PostedDocNo, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentForSalesInvoiceBalAccountGL()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoice(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentForSalesInvoiceBalAccountBank()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoice(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentForSalesOrderBalAccountGL()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesOrder(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentForSalesOrderBalAccountBank()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesOrder(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreviewPaymentForSalesOrderBalAccountBank()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();
        CreatePostAndMarkAsPaidSalesOrder(SalesHeader, TempPaymentRegistrationBuffer);

        // Exercise:
        GLPostingPreview.Trap();
        TempPaymentRegistrationBuffer.SetRange("Payment Made", true);
        asserterror PaymentRegistrationMgt.Preview(TempPaymentRegistrationBuffer, false);
        Assert.AreEqual('', GetLastErrorText, 'Expected empty error from Preview function');

        // Verify:
        GLPostingPreview.First();
        repeat
            case GLPostingPreview."Table Name".Value of
                'G/L Entry':
                    Assert.AreEqual(2, GLPostingPreview."No. of Records".AsInteger(), 'Incorrect number of G/L preview records.');
                'Cust. Ledger Entry':
                    Assert.AreEqual(1, GLPostingPreview."No. of Records".AsInteger(), 'Incorrect number of cust preview records.');
                'Detailed Cust. Ledg. Entry':
                    Assert.AreEqual(3, GLPostingPreview."No. of Records".AsInteger(), 'Incorrect number of detailed cust preview records.');
                'Bank Account Ledger Entry':
                    Assert.AreEqual(1, GLPostingPreview."No. of Records".AsInteger(), 'Incorrect number of bank account preview records.');
                else
                    Error(UnexpectedPreviewErr);
            end;
        until not GLPostingPreview.Next();
        GLPostingPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreviewLumpPaymentForSalesOrderBalAccountBank()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();
        CreatePostAndMarkAsPaidSalesOrder(SalesHeader, TempPaymentRegistrationBuffer);

        // Exercise:
        GLPostingPreview.Trap();
        TempPaymentRegistrationBuffer.SetRange("Payment Made", true);
        asserterror PaymentRegistrationMgt.Preview(TempPaymentRegistrationBuffer, true);
        Assert.AreEqual('', GetLastErrorText, 'Expected empty error from Preview function');

        // Verify:
        GLPostingPreview.First();
        repeat
            case GLPostingPreview."Table Name".Value of
                'G/L Entry':
                    Assert.AreEqual(2, GLPostingPreview."No. of Records".AsInteger(), 'Incorrect number of G/L preview records.');
                'Cust. Ledger Entry':
                    Assert.AreEqual(1, GLPostingPreview."No. of Records".AsInteger(), 'Incorrect number of cust preview records.');
                'Detailed Cust. Ledg. Entry':
                    Assert.AreEqual(3, GLPostingPreview."No. of Records".AsInteger(), 'Incorrect number of detailed cust preview records.');
                'Bank Account Ledger Entry':
                    Assert.AreEqual(1, GLPostingPreview."No. of Records".AsInteger(), 'Incorrect number of bank account preview records.');
                else
                    Error(UnexpectedPreviewErr);
            end;
        until not GLPostingPreview.Next();

        GLPostingPreview.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPartialPaymentForFinanceChargeMemoBalAccountGL()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo := IssueFinanceChargeMemoAndMarkItAsPaid(FinanceChargeMemoHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        ExpectedAmount :=
          UpdateAmountReceived(TempPaymentRegistrationBuffer, FinanceChargeMemoHeader."Customer No.", PostedDocNo,
            LibraryRandom.RandDec(FinanceChargeMemoHeader."Remaining Amount" - 1, 2));

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyPartialPaymentRegistration(FinanceChargeMemoHeader."Customer No.", PostedDocNo, PaymentDocNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPartialPaymentForFinanceChargeMemoBalAccountBank()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();

        PostedDocNo := IssueFinanceChargeMemoAndMarkItAsPaid(FinanceChargeMemoHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        ExpectedAmount :=
          UpdateAmountReceived(TempPaymentRegistrationBuffer, FinanceChargeMemoHeader."Customer No.", PostedDocNo,
            LibraryRandom.RandDec(FinanceChargeMemoHeader."Remaining Amount" - 1, 2));

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyPartialPaymentRegistration(FinanceChargeMemoHeader."Customer No.", PostedDocNo, PaymentDocNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPartiaPaymentForSalesInvoiceBalAccountGL()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoice(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        ExpectedAmount :=
          UpdateAmountReceived(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo,
            LibraryRandom.RandDecInDecimalRange(0, GetInvoiceAmount(PostedDocNo) - 1, 2));

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyPartialPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPartialPaymentForSalesInvoiceBalAccountBank()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoice(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        ExpectedAmount :=
          UpdateAmountReceived(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo,
            LibraryRandom.RandDecInDecimalRange(0, GetInvoiceAmount(PostedDocNo) - 1, 2));

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyPartialPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPartialPaymentForSalesOrderBalAccountGL()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesOrder(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        ExpectedAmount :=
          UpdateAmountReceived(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo,
            LibraryRandom.RandDecInDecimalRange(0, GetInvoiceAmount(PostedDocNo) - 1, 2));

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyPartialPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPartialPaymentForSalesOrderBalAccountBank()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesOrder(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        ExpectedAmount :=
          UpdateAmountReceived(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.",
            PostedDocNo, LibraryRandom.RandDec(1, 2));

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyPartialPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentForSalesInvoiceWithDiscountBalAccountGL()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoiceWithPaymentDiscount(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        // Exercise:
        UpdatePaymentDetailsForPaymentDiscount(TempPaymentRegistrationBuffer, SalesHeader, PostedDocNo);
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentForSalesInvoiceWithDiscountBalAccountBank()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoiceWithPaymentDiscount(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        // Exercise:
        UpdatePaymentDetailsForPaymentDiscount(TempPaymentRegistrationBuffer, SalesHeader, PostedDocNo);
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostOverduePaymentForSalesInvoiceWithDiscountBalAccountGL()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoiceWithPaymentDiscount(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        // Exercise:
        ExpectedAmount := UpdatePaymentDetailsForOverduePaymentDiscount(TempPaymentRegistrationBuffer, SalesHeader, PostedDocNo);
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyPartialPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostWithFilterPreserved()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        PostedDocNo1: Code[20];
        PostedDocNo2: Code[20];
        PaymentDocNo2: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo1 := CreateAndPostSalesInvoice(SalesHeader1);
        PostedDocNo2 := CreateAndPostSalesInvoice(SalesHeader2);
        PaymentDocNo2 := GetNextPaymentDocNo();

        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader2."Sell-to Customer No.", PostedDocNo2);

        TempPaymentRegistrationBuffer.SetFilter("Document No.", '%1|%2', PostedDocNo1, PostedDocNo2);

        // Exercise:
        PaymentRegistrationMgt.ConfirmPost(TempPaymentRegistrationBuffer);

        // Verify:
        Assert.AreEqual(1, TempPaymentRegistrationBuffer.Count, FilterNotPreservedErr);
        VerifyFullPaymentRegistration(SalesHeader2."Sell-to Customer No.", PostedDocNo2, PaymentDocNo2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostOverduePaymentForSalesInvoiceWithDiscountBalAccountBank()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoiceWithPaymentDiscount(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        // Exercise:
        ExpectedAmount := UpdatePaymentDetailsForOverduePaymentDiscount(TempPaymentRegistrationBuffer, SalesHeader, PostedDocNo);
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyPartialPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentAmountGreaterThenSalesInvoiceWithDiscountBalAccountGL()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExtraPaymentAmount: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoiceWithPaymentDiscount(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        UpdatePaymentDetailsForPaymentDiscount(TempPaymentRegistrationBuffer, SalesHeader, PostedDocNo);

        ExtraPaymentAmount := LibraryRandom.RandDec(100, 2);
        UpdateAmountReceivedGreaterThanDiscountedAmount(
          TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo, ExtraPaymentAmount);

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyMorePaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo, -ExtraPaymentAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentAmountGreaterThenSalesInvoiceWithDiscountBalAccountBank()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExtraPaymentAmount: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsBankAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoiceWithPaymentDiscount(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        UpdatePaymentDetailsForPaymentDiscount(TempPaymentRegistrationBuffer, SalesHeader, PostedDocNo);
        ExtraPaymentAmount := LibraryRandom.RandDec(100, 2);
        UpdateAmountReceivedGreaterThanDiscountedAmount(
          TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo, ExtraPaymentAmount);

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyMorePaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo, -ExtraPaymentAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaymentForSalesInvoiceWithUpdatedPaymentDiscountDate()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        ExpectedPaymentDiscountDate: Date;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo := CreatePostAndMarkAsPaidSalesInvoiceWithPaymentDiscount(SalesHeader, TempPaymentRegistrationBuffer);
        PaymentDocNo := GetNextPaymentDocNo();

        UpdatePaymentDetailsForOverduePaymentDiscount(TempPaymentRegistrationBuffer, SalesHeader, PostedDocNo);

        // Exercise:
        ExpectedPaymentDiscountDate :=
          UpdatePaymentDiscountDateToDateReceived(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo);
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo);
        VerifyPaymentDiscountDateOnCustLedgerEntry(SalesHeader."Sell-to Customer No.", PostedDocNo, ExpectedPaymentDiscountDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWithZeroReceivedAmount()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        PostedDocNo: Code[20];
    begin
        Initialize();

        // Setup:
        PostedDocNo := IssueFinanceChargeMemoAndMarkItAsPaid(FinanceChargeMemoHeader, TempPaymentRegistrationBuffer);

        // Exercise:
        UpdateAmountReceived(TempPaymentRegistrationBuffer, FinanceChargeMemoHeader."Customer No.", PostedDocNo, 0);

        // Verify:
        asserterror PostPayments(TempPaymentRegistrationBuffer);
        Assert.ExpectedError(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaidMultipleDocuments()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PostedDocNo1: Code[20];
        PostedDocNo2: Code[20];
        PaymentDocNo1: Code[20];
        PaymentDocNo2: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo1 := CreateAndPostSalesInvoice(SalesHeader1);
        PostedDocNo2 := CreateAndPostSalesOrder(SalesHeader2);
        PaymentDocNo1 := GetNextPaymentDocNoPreserveNo(NoSeriesBatch);
        PaymentDocNo2 := GetNextPaymentDocNoPreserveNo(NoSeriesBatch);

        TempPaymentRegistrationBuffer.PopulateTable(); // TO DO: encapsulate in test library function
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader1."Sell-to Customer No.", PostedDocNo1);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader2."Sell-to Customer No.", PostedDocNo2);

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(SalesHeader1."Sell-to Customer No.", PostedDocNo1, PaymentDocNo1);
        VerifyFullPaymentRegistration(SalesHeader2."Sell-to Customer No.", PostedDocNo2, PaymentDocNo2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostPaidMultipleDocumentsWithFilterApplied()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PostedDocNo1: Code[20];
        PostedDocNo2: Code[20];
        PaymentDocNo1: Code[20];
        PaymentDocNo2: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo1 := CreateAndPostSalesInvoice(SalesHeader1);
        PostedDocNo2 := CreateAndPostSalesOrder(SalesHeader2);
        PaymentDocNo1 := GetNextPaymentDocNoPreserveNo(NoSeriesBatch);
        PaymentDocNo2 := GetNextPaymentDocNoPreserveNo(NoSeriesBatch);

        CreateAndPostSalesOrder(SalesHeader3);

        TempPaymentRegistrationBuffer.PopulateTable(); // TO DO: encapsulate in test library function
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader1."Sell-to Customer No.", PostedDocNo1);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader2."Sell-to Customer No.", PostedDocNo2);

        TempPaymentRegistrationBuffer.SetFilter("Document No.", PostedDocNo1);

        // Exercise:
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(SalesHeader1."Sell-to Customer No.", PostedDocNo1, PaymentDocNo1);
        VerifyFullPaymentRegistration(SalesHeader2."Sell-to Customer No.", PostedDocNo2, PaymentDocNo2);
        Assert.IsTrue(TempPaymentRegistrationBuffer.IsEmpty, FilterNotPreservedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure PostPaidDocumentConfirmNo()
    var
        GLRegister: Record "G/L Register";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        SalesHeader: Record "Sales Header";
        GLRegisterCount: Integer;
        ExpectedRecordFormat: Text;
    begin
        Initialize();

        // Setup:
        CreatePostAndMarkAsPaidSalesOrder(SalesHeader, TempPaymentRegistrationBuffer);
        GLRegisterCount := GLRegister.Count();

        // Exercise:
        ExpectedRecordFormat := Format(TempPaymentRegistrationBuffer);
        PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        Assert.AreEqual(GLRegisterCount, GLRegister.Count, CreatedPaymentErr);
        Assert.AreEqual(ExpectedRecordFormat, Format(TempPaymentRegistrationBuffer),
          StrSubstNo(RecordChangedErr, TempPaymentRegistrationBuffer.TableName))
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure BankAccountDiffCurrencyError()
    var
        Currency: Record Currency;
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        BankAccount: Record "Bank Account";
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        // Setup:
        LibraryERM.CreateBankAccount(BankAccount);
        CreateCurrency(Currency);
        BankAccount.Validate("Currency Code", Currency.Code);
        BankAccount.Modify(true);
        SetupBalAccount(PaymentRegistrationSetup."Bal. Account Type"::"Bank Account", BankAccount."No.", UserId);
        PaymentRegistrationSetup.Get(UserId);
        CreatePostAndMarkAsPaidSalesInvoice(SalesHeader, TempPaymentRegistrationBuffer);

        // Exercise:
        asserterror PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        Assert.ExpectedError(
          StrSubstNo(ForeignCurrNotSuportedErr, TempPaymentRegistrationBuffer."Document Type", TempPaymentRegistrationBuffer.Description));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CustomerDiffCurrencyError()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        BankAccount: Record "Bank Account";
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PostedDocNo: Code[20];
    begin
        Initialize();

        // Setup:
        LibraryERM.CreateBankAccount(BankAccount);
        CreateCurrency(Currency);
        SetupBalAccount(PaymentRegistrationSetup."Bal. Account Type"::"Bank Account", BankAccount."No.", UserId);
        PaymentRegistrationSetup.Get(UserId);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);
        CreateSalesDocumentWithCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo);

        // Exercise:
        asserterror PostPayments(TempPaymentRegistrationBuffer);

        // Verify:
        Assert.ExpectedError(
          StrSubstNo(ForeignCurrNotSuportedErr, TempPaymentRegistrationBuffer."Document Type", TempPaymentRegistrationBuffer.Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateOnDrillDownName()
    var
        PaymentRegistration: TestPage "Payment Registration";
        CustomerCard: TestPage "Customer Card";
        Name: Text;
        CustCardName: Text;
    begin
        Initialize();

        PaymentRegistration.OpenEdit();
        PaymentRegistration.Last();
        Name := PaymentRegistration.Name.Value();
        // Exercise:
        CustomerCard.Trap();
        PaymentRegistration.Name.DrillDown();
        CustCardName := CustomerCard.Name.Value();
        CustomerCard.Close();

        // Verify:
        Assert.AreEqual(Name, CustCardName, OpenCustomerCardErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateNavigateAction()
    var
        PaymentRegistration: TestPage "Payment Registration";
        Navigate: TestPage Navigate;
        SourceName: Text;
        Name: Text;
    begin
        Initialize();

        // Setup:
        PaymentRegistration.OpenEdit();
        PaymentRegistration.Last();
        Name := PaymentRegistration.Name.Value();

        // Exercise:
        Navigate.Trap();
        PaymentRegistration.Navigate.Invoke();
        SourceName := Navigate.SourceName.Value();
        Navigate.Close();

        // Verify:
        Assert.AreEqual(Name, SourceName, NavigateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateFinChargeMemoAction()
    var
        Customer: Record Customer;
        PaymentRegistration: TestPage "Payment Registration";
        FinanceChargeMemo: TestPage "Finance Charge Memo";
        CustomerNo: Text;
    begin
        Initialize();

        // Setup:
        PaymentRegistration.OpenEdit();
        PaymentRegistration.First();

        // Exercise:
        FinanceChargeMemo.Trap();
        PaymentRegistration.FinanceChargeMemo.Invoke();
        CustomerNo := FinanceChargeMemo.FILTER.GetFilter("Customer No.");
        FinanceChargeMemo.Close();
        Customer.Get(CustomerNo);

        // Verify:
        Assert.AreEqual(PaymentRegistration.Name.Value, Customer.Name, WrongCustomerErr);
    end;

    [Test]
    [HandlerFunctions('HandlerPaymentRegistrationDetails')]
    [Scope('OnPrem')]
    procedure ValidateDetailsAction()
    var
        PaymentRegistration: TestPage "Payment Registration";
    begin
        Initialize();

        // Setup:

        PaymentRegistration.OpenEdit();
        PaymentRegistration.Last();
        LibraryVariableStorage.Enqueue(PaymentRegistration.Name.Value);

        // Exercise:
        PaymentRegistration.Details.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarningMessageDueDate()
    var
        PaymentRegistration: TestPage "Payment Registration";
        DueDate: Date;
    begin
        Initialize();

        PaymentRegistration.OpenEdit();
        PaymentRegistration.First();
        Evaluate(DueDate, PaymentRegistration."Due Date".Value);
        PaymentRegistration."Date Received".SetValue(DueDate + LibraryRandom.RandInt(5));
        Assert.AreEqual(Format(DueDateMsg), PaymentRegistration.Warning.Value, WrongWarningErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLumpPaymentDifferentCustomerNo()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        PostedDocNo1: Code[20];
        PostedDocNo2: Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PostedDocNo1 := CreateAndPostSalesInvoice(SalesHeader1);
        PostedDocNo2 := CreateAndPostSalesInvoice(SalesHeader2);

        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader1."Sell-to Customer No.", PostedDocNo1);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader2."Sell-to Customer No.", PostedDocNo2);

        // Exercise:
        asserterror PostLumpPayments(TempPaymentRegistrationBuffer);

        // Verify:
        Assert.ExpectedError(
          StrSubstNo(
            DistinctCustomerErr,
            TempPaymentRegistrationBuffer.FieldCaption("Payment Made")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostLumpPaymentDifferentDateReceived()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        CustomerNo: Code[20];
        PostedDocNo: array[2] of Code[20];
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        CreatePostTwoSalesInvoices(CustomerNo, PostedDocNo);

        TempPaymentRegistrationBuffer.PopulateTable();

        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, PostedDocNo[1]);
        TempPaymentRegistrationBuffer."Date Received" := TempPaymentRegistrationBuffer."Date Received" + 1;
        TempPaymentRegistrationBuffer.Modify();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, PostedDocNo[2]);
        TempPaymentRegistrationBuffer."Date Received" := TempPaymentRegistrationBuffer."Date Received" + 2;
        TempPaymentRegistrationBuffer.Modify();

        // Exercise:
        asserterror PostLumpPayments(TempPaymentRegistrationBuffer);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(
            DistinctDateReceivedErr,
            TempPaymentRegistrationBuffer.FieldCaption("Date Received"),
            TempPaymentRegistrationBuffer.FieldCaption("Payment Made")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostLumpPayment()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        CustomerNo: Code[20];
        PostedDocNo: array[2] of Code[20];
        PaymentDocNo: Code[20];
        LumpAmount: Decimal;
    begin
        Initialize();

        // Setup:

        SetupBalAccountAsGLAccount();
        PaymentDocNo := GetNextPaymentDocNo();

        CreatePostTwoSalesInvoices(CustomerNo, PostedDocNo);

        TempPaymentRegistrationBuffer.PopulateTable();

        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, PostedDocNo[1]);
        LumpAmount += TempPaymentRegistrationBuffer."Amount Received";
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, PostedDocNo[2]);
        LumpAmount += TempPaymentRegistrationBuffer."Amount Received";

        // Exercise
        PostLumpPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyFullPaymentRegistration(CustomerNo, PostedDocNo[1], PaymentDocNo);
        VerifyFullPaymentRegistration(CustomerNo, PostedDocNo[2], PaymentDocNo);
        VerifyCustLedgerEntryLumpPayment(CustomerNo, PaymentDocNo, LumpAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostLumpPaymentPartial()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        CustomerNo: Code[20];
        PostedDocNo: array[2] of Code[20];
        PaymentDocNo: Code[20];
        LumpAmount: Decimal;
        ExpectedAmount1: Decimal;
        ExpectedAmount2: Decimal;
    begin
        Initialize();

        // Setup:
        SetupBalAccountAsGLAccount();

        PaymentDocNo := GetNextPaymentDocNo();

        CreatePostTwoSalesInvoices(CustomerNo, PostedDocNo);

        TempPaymentRegistrationBuffer.PopulateTable();

        ExpectedAmount1 :=
          UpdateAmountReceived(TempPaymentRegistrationBuffer, CustomerNo, PostedDocNo[1],
            LibraryRandom.RandDecInDecimalRange(0, GetInvoiceAmount(PostedDocNo[1]) - 1, 2));
        LumpAmount += TempPaymentRegistrationBuffer."Amount Received";

        ExpectedAmount2 :=
          UpdateAmountReceived(TempPaymentRegistrationBuffer, CustomerNo, PostedDocNo[2],
            LibraryRandom.RandDecInDecimalRange(0, GetInvoiceAmount(PostedDocNo[2]) - 1, 2));
        LumpAmount += TempPaymentRegistrationBuffer."Amount Received";

        // Exercise
        PostLumpPayments(TempPaymentRegistrationBuffer);

        // Verify:
        VerifyPartialPaymentRegistration(CustomerNo, PostedDocNo[1], PaymentDocNo, ExpectedAmount1);
        VerifyPartialPaymentRegistration(CustomerNo, PostedDocNo[2], PaymentDocNo, ExpectedAmount2);
        VerifyCustLedgerEntryLumpPayment(CustomerNo, PaymentDocNo, LumpAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure PostLumpPaymentFiltersPreserved()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        CustomerNo: Code[20];
        ExpectedRecordFormat: Text;
        PostedDocNo: array[2] of Code[20];
    begin
        Initialize();

        // Setup:

        SetupBalAccountAsGLAccount();

        CreatePostTwoSalesInvoices(CustomerNo, PostedDocNo);

        TempPaymentRegistrationBuffer.PopulateTable();

        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, PostedDocNo[1]);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, PostedDocNo[2]);

        TempPaymentRegistrationBuffer.SetFilter("Source No.", CustomerNo);
        ExpectedRecordFormat := Format(TempPaymentRegistrationBuffer);

        // Exercise
        PostLumpPayments(TempPaymentRegistrationBuffer);

        // Verify
        Assert.AreEqual(CustomerNo, TempPaymentRegistrationBuffer.GetFilter("Source No."), FilterNotPreservedErr);
        Assert.AreEqual(2, TempPaymentRegistrationBuffer.Count, FilterNotPreservedErr);
        Assert.AreEqual(ExpectedRecordFormat, Format(TempPaymentRegistrationBuffer),
          StrSubstNo(RecordChangedErr, TempPaymentRegistrationBuffer.TableName))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TotalBalanceOnPage()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentRegistration: TestPage "Payment Registration";
        PostedAmount: Decimal;
        UnpostedAmount: Decimal;
    begin
        Initialize();

        SetupBalAccountAsGLAccount();
        PaymentRegistrationSetup.Get(UserId);

        CreateGenJnlLine(GenJnlLine, PaymentRegistrationSetup);
        PostedAmount := GenJnlLine.Amount;
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        CreateGenJnlLine(GenJnlLine, PaymentRegistrationSetup);
        UnpostedAmount := GenJnlLine.Amount;

        // Verify
        PaymentRegistration.OpenEdit();
        PaymentRegistration.PostedBalance.AssertEquals(-PostedAmount);
        PaymentRegistration.UnpostedBalance.AssertEquals(UnpostedAmount);
        PaymentRegistration.TotalBalance.AssertEquals(-PostedAmount + UnpostedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountReceivedAfterReloadingPaymentRegistration()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        AmountReceived: Decimal;
    begin
        // [FEATURE] [UT] [Reload]
        // [SCENARIO 376319] Amount Received should be reloaded for Payment Registration if it was changed
        Initialize();

        // [GIVEN] Paid Payment Registration with "Amount Received" = "X"
        CreatePaidPaymentRegistration(TempPaymentRegistrationBuffer);

        // [GIVEN] Change "Amount Received" to different value
        TempPaymentRegistrationBuffer.Validate("Amount Received", LibraryRandom.RandDec(100, 2));
        TempPaymentRegistrationBuffer.Modify(true);
        AmountReceived := TempPaymentRegistrationBuffer."Amount Received";

        // [WHEN] Reload Payment Registration
        TempPaymentRegistrationBuffer.Reload();

        // [THEN] Payment Registration has "Amount Received" = "X"
        TempPaymentRegistrationBuffer.TestField("Amount Received", AmountReceived);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateSetupPageWith2Users()
    var
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        TempPaymentRegistrationSetup: Record "Payment Registration Setup" temporary;
        PaymentRegistrationSetupPage: TestPage "Payment Registration Setup";
    begin
        Initialize();

        SetupBalAccountAsBankAccount();

        LibraryERM.CreateGLAccount(GLAccount);
        SetupBalAccount(PaymentRegistrationSetup."Bal. Account Type"::"G/L Account", GLAccount."No.", DummyUserNameTxt);

        PaymentRegistrationSetup.FindSet();
        repeat
            TempPaymentRegistrationSetup.Copy(PaymentRegistrationSetup);
            TempPaymentRegistrationSetup.Insert();
        until PaymentRegistrationSetup.Next() = 0;

        LibraryERM.CreateBankAccount(BankAccount);

        PaymentRegistrationSetupPage.OpenEdit();
        PaymentRegistrationSetupPage."Bal. Account No.".Value := BankAccount."No.";
        PaymentRegistrationSetupPage.OK().Invoke();

        PaymentRegistrationSetup.Get();
        TempPaymentRegistrationSetup.Get();
        Assert.AreEqual(
          TempPaymentRegistrationSetup."Bal. Account No.",
          PaymentRegistrationSetup."Bal. Account No.",
          StrSubstNo(WrongBalAccountErr, 'Default'));

        PaymentRegistrationSetup.Get(UserId);
        Assert.AreEqual(
          BankAccount."No.",
          PaymentRegistrationSetup."Bal. Account No.",
          StrSubstNo(WrongBalAccountErr, PaymentRegistrationSetup."User ID"));

        PaymentRegistrationSetup.Get(DummyUserNameTxt);
        TempPaymentRegistrationSetup.Get(DummyUserNameTxt);
        Assert.AreEqual(
          TempPaymentRegistrationSetup."Bal. Account No.",
          PaymentRegistrationSetup."Bal. Account No.",
          StrSubstNo(WrongBalAccountErr, TempPaymentRegistrationSetup."User ID"));

        PaymentRegistrationSetupPage.OpenEdit();
        Assert.AreEqual(
          BankAccount."No.",
          PaymentRegistrationSetupPage."Bal. Account No.".Value,
          StrSubstNo(WrongBalAccountErr, UserId));

        PaymentRegistrationSetupPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PaymentRegisterIsNotChangedAfterErrorDuringPostLumpPayment()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        CustomerNo: Code[20];
        DocumentNo: array[2] of Code[20];
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Lump Payment]
        // [SCENARIO 209410] Payment registration line is not changed after error during "Post as Lump Payment" action
        Initialize();

        // [GIVEN] Payment registration setup with "Balancing Account Type" = "Bank Account", "Balancing Account" = "WWB-EUR"
        PreparePmtRegSetupWithBankBalAccount();

        // [GIVEN] Two posted sales invoices in LCY ("Currency Code" = "")
        CreatePostTwoSalesInvoices(CustomerNo, DocumentNo);

        // [GIVEN] Open payment registration. Mark "Payment Made" = TRUE for both invoices.
        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[1]);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[2]);

        // [WHEN] Perform "Post as Lump Payment" action. Confirm post.
        ExpectedAmount := TempPaymentRegistrationBuffer."Amount Received";
        asserterror PaymentRegistrationMgt.ConfirmPostLumpPayment(TempPaymentRegistrationBuffer);

        // [THEN] An error has been occurred: "The document with type Invoice and description Test Invoice must have the same currency code as the payment you are registering."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(ForeignCurrNotSuportedErr, TempPaymentRegistrationBuffer."Document Type", TempPaymentRegistrationBuffer.Description));

        // [THEN] Payment registration line is not changed after the error
        Assert.AreEqual(ExpectedAmount, TempPaymentRegistrationBuffer."Amount Received", TempPaymentRegistrationBuffer.FieldCaption("Amount Received"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure PaymentRegisterApplicationIsNotSavedWhenPostLumpPaymentIsNotConfirmed()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        CustomerNo: Code[20];
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Lump Payment]
        // [SCENARIO 230065] Application in Payment Registration page is not stored when Post as Lump Payment is not confirmed.
        Initialize();

        // [GIVEN] Setup Payment Registration Setup with G/L Account as Balance Account.
        // [GIVEN] Two posted Sales Invoices "PSI1" and "PSI2" for Customer.
        SetupBalAccountAsGLAccount();
        CreatePostTwoSalesInvoices(CustomerNo, DocumentNo);

        // [GIVEN] Payment Register table is populated and "PSI1" and "PSI2" are marked as paid.
        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[1]);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[2]);

        // [WHEN] "Post as Lump Payment" is invoked from Payment Register and then confirmation dialog is cancelled at ConfirmDialogNo.
        PostLumpPayments(TempPaymentRegistrationBuffer);

        // [THEN] Customer Ledger Entries for "PSI1" and "PSI2" are not marked for application.
        VerifyCustLedgerEntryIsNotApplied(CustomerNo, DocumentNo[1]);
        VerifyCustLedgerEntryIsNotApplied(CustomerNo, DocumentNo[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PaymentRegisterApplicationIsSavedWhenPostLumpPaymentIsConfirmed()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        CustomerNo: Code[20];
        DocumentNo: array[2] of Code[20];
    begin
        // [FEATURE] [Lump Payment]
        // [SCENARIO 230065] Application in Payment Registration page is succeded when Post as Lump Payment is confirmed.
        Initialize();

        // [GIVEN] Setup Payment Registration Setup with G/L Account as Balance Account.
        // [GIVEN] Two posted Sales Invoices "PSI1" and "PSI2" for Customer.
        SetupBalAccountAsGLAccount();
        CreatePostTwoSalesInvoices(CustomerNo, DocumentNo);

        // [GIVEN] Payment Register table is populated and "PSI1" and "PSI2" are marked as paid.
        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[1]);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[2]);

        // [WHEN] "Post as Lump Payment" is invoked from Payment Register and then confirmation dialog is confirmed at ConfirmDialogYes.
        PostLumpPayments(TempPaymentRegistrationBuffer);

        // [THEN] Customer Ledger Entries for "PSI1" and "PSI2" are closed by the posted lump payment.
        VerifyCustLedgerEntryIsApplied(CustomerNo, DocumentNo[1]);
        VerifyCustLedgerEntryIsApplied(CustomerNo, DocumentNo[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostLumpPaymentWithTolerance()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustomerNo: Code[20];
        DocumentNo: array[2] of Code[20];
        MaxPmtTolerance: Decimal;
        ExpectedTolerance: Decimal;
        I: Integer;
    begin
        // [FEATURE] [Lump Payment] [Payment Tolerance]
        // [SCENARIO 318741] Lump Payment with Amounts Received within the "Max Payment Tolerance" leads to Payment Tolerance posting
        Initialize();

        // [GIVEN] Payment registration setup with "Balancing Account Type" = "Bank Account", "Balancing Account" = "WWB-EUR"
        SetupBalAccountAsBankAccount();

        // [GIVEN] "Payment Tolerance %" = 0, "Max Pmt. Tolerance Amt." = 1
        MaxPmtTolerance := LibraryRandom.RandInt(10);
        LibraryCashFlowHelper.SetupPmtTolPercentage(0);
        LibraryCashFlowHelper.SetupPmtTolAmount(MaxPmtTolerance);

        // [GIVEN] Posted Sales Invoices "PSI1", "PSI2" with "Amount Incl. VAT" = 92.92 and 92.58, respectively
        CreatePostTwoSalesInvoices(CustomerNo, DocumentNo);

        // [GIVEN] Payment Register table is populated and "PSI1" and "PSI2" are marked as paid with "Amount Received" = 92 on the same date
        TempPaymentRegistrationBuffer.PopulateTable();
        for I := 1 to ArrayLen(DocumentNo) do begin
            MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[I]);
            UpdateAmountReceived(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[I],
              LibraryRandom.RandDecInDecimalRange(
                TempPaymentRegistrationBuffer."Amount Received" - MaxPmtTolerance, TempPaymentRegistrationBuffer."Amount Received", 2));
            ExpectedTolerance -= TempPaymentRegistrationBuffer."Remaining Amount";
        end;

        // [WHEN] "Post as Lump Payment" is invoked from Payment Register and then confirmation dialog is confirmed at ConfirmDialogYes.
        PostLumpPayments(TempPaymentRegistrationBuffer);

        // [THEN] "Payment Tolerance" Detailed Cust. Ledger Entry exists for the posted Payment with Amount = -1.5
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Payment);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Payment Tolerance");
        DetailedCustLedgEntry.FindFirst();
        Assert.AreEqual(ExpectedTolerance, DetailedCustLedgEntry.Amount, 'Unexpected Payment Tolerance amount');

        // [THEN] Customer Ledger Entries for "PSI1" and "PSI2" are closed by the posted lump payment.
        VerifyCustLedgerEntryIsApplied(CustomerNo, DocumentNo[1]);
        VerifyCustLedgerEntryIsApplied(CustomerNo, DocumentNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreviewPostPaymentWithToleranceWarning()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        SalesHeader: Record "Sales Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        GLPostingPreview: TestPage "G/L Posting Preview";
        DocumentNo: Code[20];
        MaxPmtTolerance: Decimal;
    begin
        // [FEATURE] [Lump Payment] [Payment Tolerance]
        // [SCENARIO 333915] Preview posting on Payment Registration is not interrupted by Payment Tolerance Warning dialog.
        Initialize();

        // [GIVEN] Payment registration setup with "Balancing Account Type" = "Bank Account", "Balancing Account" = "WWB-EUR"
        SetupBalAccountAsBankAccount();

        // [GIVEN] "Payment Tolerance %" = 0, "Max Pmt. Tolerance Amt." = 1
        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        MaxPmtTolerance := LibraryRandom.RandInt(10);
        LibraryCashFlowHelper.SetupPmtTolPercentage(0);
        LibraryCashFlowHelper.SetupPmtTolAmount(MaxPmtTolerance);

        // [GIVEN] Posted Sales Invoice "PSI1" with "Amount Incl. VAT" = 92.92
        CreateSalesDocumentWithCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] "Received Amount" is less then remaining amount that is causing payment tolerance warning on actual posting.
        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", DocumentNo);
        UpdateAmountReceived(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", DocumentNo,
          LibraryRandom.RandDecInDecimalRange(
            TempPaymentRegistrationBuffer."Amount Received" - MaxPmtTolerance, TempPaymentRegistrationBuffer."Amount Received", 2));

        // [WHEN] "Preview Post" is invoked from Payment Register
        GLPostingPreview.Trap();
        TempPaymentRegistrationBuffer.SetRange("Payment Made", true);
        asserterror PaymentRegistrationMgt.Preview(TempPaymentRegistrationBuffer, false);
        Assert.AreEqual('', GetLastErrorText(), 'Expected empty error from Preview function');

        // [THEN] Posting Preview shows correct numbers of entries with Payment Tolerance entries included
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"G/L Entry"));
        Assert.IsTrue(GLPostingPreview."No. of Records".AsInteger() > 0, 'G/L Entries expected.');
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Cust. Ledger Entry"));
        Assert.IsTrue(GLPostingPreview."No. of Records".AsInteger() > 0, 'Customer ledger entries expected.');
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Detailed Cust. Ledg. Entry"));
        Assert.IsTrue(GLPostingPreview."No. of Records".AsInteger() > 0, 'Detailed customer ledger entries expected.');
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"Bank Account Ledger Entry"));
        Assert.IsTrue(GLPostingPreview."No. of Records".AsInteger() > 0, 'Bank ledger entries expected.');
        GLPostingPreview.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostRefundForSalesCreditMemoBalAccountGL()
    var
        Customer: Record Customer;
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        NoSeriesBatch: Codeunit "No. Series - Batch";
        PostedInvoiceNo: Code[20];
        PostedCreditMemoNo: Code[20];
        PaymentDocNo: Code[20];
        RefundDocNo: Code[20];
    begin
        // [SCENARIO 340645] Post Refund and Payment for Credit Memo and Invoice for the same Customer
        Initialize();

        SetupBalAccountAsGLAccount();

        // [GIVEN] Customer "C"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Posted invoice "Inv" and Credit memo "CrM" documents for "C"
        CreatePostSalesInvoiceCreditMemoSingleCustomer(Customer, PostedInvoiceNo, PostedCreditMemoNo);
        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, Customer."No.", PostedInvoiceNo);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, Customer."No.", PostedCreditMemoNo);

        PaymentDocNo := GetNextPaymentDocNoPreserveNo(NoSeriesBatch);
        RefundDocNo := GetNextPaymentDocNoPreserveNo(NoSeriesBatch);

        // [WHEN] Post temporary Payment Registration Buffer with "Inv" and "CrM"
        PostPayments(TempPaymentRegistrationBuffer);

        // [THEN] Payment for "Inv" created and posted
        VerifyFullPaymentRegistration(Customer."No.", PostedInvoiceNo, PaymentDocNo);
        // [THEN] Refund for "CrM" created and posted
        VerifyFullRefundRegistration(Customer."No.", PostedCreditMemoNo, RefundDocNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostLumpPaymentTwoInvoicesOneCreditMemo()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        CustomerNo: Code[20];
        DocumentNo: array[3] of Code[20];
        SalesDocumentType: Enum "Sales Document Type";
        Amount: Decimal;
    begin
        // [FEATURE] [Lump Payment]
        // [SCENARIO 416898]
        Initialize();

        // [GIVEN] Setup Payment Registration Setup with G/L Account as Balance Account.
        SetupBalAccountAsGLAccount();

        // [GIVEN] Customer exists
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Two posted Sales Invoices "PSI1" and "PSI2" of amount = "X" for Customer.
        Amount := LibraryRandom.RandDec(100, 2);
        DocumentNo[1] := CreateAndPostSalesDocumentWithCustomerAndAmount(SalesDocumentType::Invoice, CustomerNo, Amount);
        DocumentNo[2] := CreateAndPostSalesDocumentWithCustomerAndAmount(SalesDocumentType::Invoice, CustomerNo, Amount);

        // [GIVEN] One posted Credit Memo "PCM1" of amount = "X" for Customer
        DocumentNo[3] := CreateAndPostSalesDocumentWithCustomerAndAmount(SalesDocumentType::"Credit Memo", CustomerNo, Amount);

        // [GIVEN] Payment Register table is populated and "PSI1", "PSI2" and "PCM1" are marked as paid.
        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[1]);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[2]);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[3]);

        // [WHEN] "Post as Lump Payment" is invoked from Payment Register and then confirmation dialog is confirmed at ConfirmDialogYes.
        PostLumpPayments(TempPaymentRegistrationBuffer);

        // [THEN] Customer Ledger Entries for "PSI1", "PSI2" and "PCM1" are closed by the posted lump payment.
        VerifyCustLedgerEntryIsApplied(CustomerNo, DocumentNo[1]);
        VerifyCustLedgerEntryIsApplied(CustomerNo, DocumentNo[2]);
        VerifyCustLedgerEntryIsApplied(CustomerNo, DocumentNo[3]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostLumpPaymentOneInvoiceTwoCreditMemos()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        CustomerNo: Code[20];
        DocumentNo: array[3] of Code[20];
        SalesDocumentType: Enum "Sales Document Type";
        Amount: Decimal;
    begin
        // [FEATURE] [Lump Payment]
        // [SCENARIO 416898]
        Initialize();

        // [GIVEN] Setup Payment Registration Setup with G/L Account as Balance Account.
        SetupBalAccountAsGLAccount();

        // [GIVEN] Customer exists
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Two posted Credit Memos "PCM1" and "PCM2" of amount = "X" for Customer
        Amount := LibraryRandom.RandDec(100, 2);
        DocumentNo[1] := CreateAndPostSalesDocumentWithCustomerAndAmount(SalesDocumentType::"Credit Memo", CustomerNo, Amount);
        DocumentNo[2] := CreateAndPostSalesDocumentWithCustomerAndAmount(SalesDocumentType::"Credit Memo", CustomerNo, Amount);

        // [GIVEN] One posted Sales Invoice "PSI1" of amount = "X" for Customer.
        DocumentNo[3] := CreateAndPostSalesDocumentWithCustomerAndAmount(SalesDocumentType::Invoice, CustomerNo, Amount);

        // [GIVEN] Payment Register table is populated and "PSI1", "PCM1" and "PCM2" are marked as paid.
        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[1]);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[2]);
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, CustomerNo, DocumentNo[3]);

        // [WHEN] "Post as Lump Payment" is invoked from Payment Register and then confirmation dialog is confirmed at ConfirmDialogYes.
        PostLumpPayments(TempPaymentRegistrationBuffer);

        // [THEN] Customer Ledger Entries for "PSI1", "PCM1" and "PCM2" are closed by the posted lump payment.
        VerifyCustLedgerEntryIsApplied(CustomerNo, DocumentNo[1]);
        VerifyCustLedgerEntryIsApplied(CustomerNo, DocumentNo[2]);
        VerifyCustLedgerEntryIsApplied(CustomerNo, DocumentNo[3]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PreviewPostLumpPaymentOneInvoiceWithPaymentTolerance()
    var
        SalesHeader: Record "Sales Header";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        Customer: Record Customer;
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        GLPostingPreview: TestPage "G/L Posting Preview";
        PostedDocNo: Code[20];
        PaymentDocNo: Code[20];
        AmountChange: Decimal;
    begin
        // [SCENARIO 419736] User should be able to post lump payment Register Customer Payments with Payment Tolerance
        Initialize();

        // [GIVEN] Payment Tolerance with Max. Payment Tolerance Amount = 10
        SetupBalAccountAsGLAccount();
        LibraryCashFlowHelper.SetupPmtTolPercentage(0);
        LibraryCashFlowHelper.SetupPmtTolAmount(10);

        // [GIVEN] Posted Sales Document with Amount = X
        CreateSalesDocumentWithCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Customer.Get(SalesHeader."Sell-to Customer No.");

        // [GIVEN] Register Customer Payments, Payment Made = true, Amount Received = X + 5
        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, Customer."No.", PostedDocNo);
        AmountChange := LibraryRandom.RandDecInDecimalRange(1, 9, 2);
        UpdateAmountReceived(
            TempPaymentRegistrationBuffer, Customer."No.", PostedDocNo,
            TempPaymentRegistrationBuffer."Amount Received" + AmountChange);
        PaymentDocNo := GetNextPaymentDocNo();

        // [WHEN] Preview Posting Payment as Lump
        // [THEN] No error messages shown
        GLPostingPreview.Trap();
        TempPaymentRegistrationBuffer.SetRange("Payment Made", true);
        asserterror PaymentRegistrationMgt.Preview(TempPaymentRegistrationBuffer, true);
        Assert.AreEqual('', GetLastErrorText, 'Expected empty error from Preview function');
        GLPostingPreview.Close();

        // [WHEN] Post As Lump Payment invoked
        PostLumpPayments(TempPaymentRegistrationBuffer);

        // [THEN] Payment for Invoice created and posted
        VerifyFullPaymentRegistration(SalesHeader."Sell-to Customer No.", PostedDocNo, PaymentDocNo);
        VerifyCustLedgerEntryLumpPayment(SalesHeader."Sell-to Customer No.", PaymentDocNo, TempPaymentRegistrationBuffer."Original Remaining Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesExternalDocNo()
    var
        SalesHeader: Record "Sales Header";
        PaymentRegistration: TestPage "Payment Registration";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 421199] Sales "External Document No." filled in payment registration page
        Initialize();

        // [GIVEN] Create and post sales invoice with "External Document No." = "EDN"
        CreateSalesDocumentWithCustomer(SalesHeader, "Sales Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        SalesHeader.Modify();
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Open Register Customer Payments page
        SetupBalAccountAsGLAccount();
        PaymentRegistration.OpenEdit();

        // [THEN] "External Document No." = "EDN"
        PaymentRegistration.Filter.SetFilter("Document No.", DocumentNo);
        PaymentRegistration.ExternalDocumentNo.AssertEquals(SalesHeader."External Document No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Manual Payment Registration");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Manual Payment Registration");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Manual Payment Registration");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '<>%1', '');
        GenProductPostingGroup.FindFirst();
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesDocumentWithCustomerAndAmount(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; Amount: Decimal) PostedDocNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateGenJnlBatch(JournalTemplateName: Code[10]): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JournalTemplateName);
        GenJournalBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch.Modify();
        exit(GenJournalBatch.Name);
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PaymentRegistrationSetup: Record "Payment Registration Setup")
    var
        Customer: Record Customer;
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibrarySales.CreateCustomer(Customer);

        LibraryERM.CreateGeneralJnlLine(GenJnlLine, GenJnlTemplate.Name, CreateGenJnlBatch(GenJnlTemplate.Name),
          GenJnlLine."Document Type"::Payment, GenJnlLine."Account Type"::Customer, Customer."No.", -LibraryRandom.RandDec(100, 2));
        case PaymentRegistrationSetup."Bal. Account Type" of
            PaymentRegistrationSetup."Bal. Account Type"::"Bank Account":
                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
            PaymentRegistrationSetup."Bal. Account Type"::"G/L Account":
                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        end;

        GenJnlLine."Bal. Account No." := PaymentRegistrationSetup."Bal. Account No.";
        GenJnlLine.Modify();
    end;

    local procedure CreateCurrency(var Currency: Record Currency)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, 0D);
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(100, 2);
        CurrencyExchangeRate."Relational Exch. Rate Amount" := LibraryRandom.RandDec(100, 2);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateBankAccountWithCurrency(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateGenJournalBatchWithBankAccount(var GenJournalBatch: Record "Gen. Journal Batch"; BankAccountNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccountNo);
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure DeleteCurrentUserSetup()
    var
        PaymentRegistrationSetupMyUser: Record "Payment Registration Setup";
    begin
        if PaymentRegistrationSetupMyUser.Get(UserId) then
            PaymentRegistrationSetupMyUser.Delete();
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocNo);
        CustLedgerEntry.FindLast();
    end;

    local procedure FindPaymentRegistrationBuffer(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; CustomerNo: Code[20]; DocNo: Code[20])
    begin
        TempPaymentRegistrationBuffer.SetRange("Source No.", CustomerNo);
        TempPaymentRegistrationBuffer.SetRange("Document No.", DocNo);
        TempPaymentRegistrationBuffer.FindFirst();
    end;

    local procedure GetNextPaymentDocNo(): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        NoSeries: Codeunit "No. Series";
    begin
        PaymentRegistrationSetup.Get(UserId);
        GenJournalBatch.Get(PaymentRegistrationSetup."Journal Template Name", PaymentRegistrationSetup."Journal Batch Name");
        exit(NoSeries.PeekNextNo(GenJournalBatch."No. Series"))
    end;

    local procedure GetNextPaymentDocNoPreserveNo(var NoSeriesBatch: Codeunit "No. Series - Batch"): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.Get(UserId);
        GenJournalBatch.Get(PaymentRegistrationSetup."Journal Template Name", PaymentRegistrationSetup."Journal Batch Name");
        exit(NoSeriesBatch.GetNextNo(GenJournalBatch."No. Series"))
    end;

    local procedure IssueFinanceChargeMemoAndMarkItAsPaid(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary): Code[20]
    var
        PostedDocNo: Code[20];
    begin
        PostedDocNo := IssueFinanceChargeMemo(FinanceChargeMemoHeader);

        TempPaymentRegistrationBuffer.PopulateTable(); // TO DO: encapsulate in test library function
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, FinanceChargeMemoHeader."Customer No.", PostedDocNo);

        exit(PostedDocNo);
    end;

    local procedure IssueFinanceChargeMemo(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"): Code[20]
    var
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        Customer: Record Customer;
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);

        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, Customer."No.");
        FinanceChargeMemoHeader.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        FinanceChargeMemoHeader.Modify(true);
        LibraryERM.CreateFinanceChargeMemoLine(FinanceChargeMemoLine,
          FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::"G/L Account");
        FinanceChargeMemoLine.Validate("No.", CreateGLAccount());
        FinanceChargeMemoLine.Validate(Amount, LibraryRandom.RandInt(1000));
        FinanceChargeMemoLine.Modify(true);

        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);

        IssuedFinChargeMemoHeader.SetRange("Pre-Assigned No.", FinanceChargeMemoHeader."No.");
        IssuedFinChargeMemoHeader.SetRange("Customer No.", FinanceChargeMemoHeader."Customer No.");
        IssuedFinChargeMemoHeader.FindLast();
        exit(IssuedFinChargeMemoHeader."No.")
    end;

    local procedure MarkDocumentAsPaid(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; CustomerNo: Code[20]; DocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustomerNo, DocNo);
        TempPaymentRegistrationBuffer.Get(CustLedgerEntry."Entry No.");
        TempPaymentRegistrationBuffer.Validate("Payment Made", true);
        TempPaymentRegistrationBuffer.Validate("Date Received", WorkDate());
        TempPaymentRegistrationBuffer.Modify(true);
    end;

    local procedure MoveDefaultSetupToDummyUserSetup()
    var
        PaymentRegistrationSetupDummy: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetupDummy.Get();
        PaymentRegistrationSetupDummy."User ID" := DummyUserNameTxt;
        PaymentRegistrationSetupDummy.Insert();
        PaymentRegistrationSetupDummy.Get();
        PaymentRegistrationSetupDummy.Delete();
    end;

    local procedure PostPayments(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    var
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        TempPaymentRegistrationBuffer.SetRange("Payment Made", true);
        PaymentRegistrationMgt.ConfirmPost(TempPaymentRegistrationBuffer)
    end;

    local procedure PostLumpPayments(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    var
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        TempPaymentRegistrationBuffer.SetRange("Payment Made", true);
        PaymentRegistrationMgt.ConfirmPostLumpPayment(TempPaymentRegistrationBuffer)
    end;

    local procedure CreateAndPostSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"): Code[20]
    begin
        CreateSalesDocument(SalesHeader, DocumentType);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true))
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice))
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(CreateAndPostSalesDocument(SalesHeader, SalesHeader."Document Type"::Order))
    end;

    local procedure CreateAndPostSalesDocumentWithPaymentDiscount(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"): Code[20]
    begin
        CreateSalesDocument(SalesHeader, DocumentType);
        UpdatePaymentDiscount(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true))
    end;

    local procedure CreateAndPostSalesInvoiceWithPaymentDiscount(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(CreateAndPostSalesDocumentWithPaymentDiscount(SalesHeader, SalesHeader."Document Type"::Invoice))
    end;

    local procedure CreatePostAndMarkAsPaidSalesInvoice(var SalesHeader: Record "Sales Header"; var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary): Code[20]
    var
        PostedDocNo: Code[20];
    begin
        PostedDocNo := CreateAndPostSalesInvoice(SalesHeader);

        TempPaymentRegistrationBuffer.PopulateTable(); // TO DO: encapsulate in test library function
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo);

        exit(PostedDocNo);
    end;

    local procedure CreatePostAndMarkAsPaidSalesOrder(var SalesHeader: Record "Sales Header"; var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary): Code[20]
    var
        PostedDocNo: Code[20];
    begin
        PostedDocNo := CreateAndPostSalesOrder(SalesHeader);

        TempPaymentRegistrationBuffer.PopulateTable(); // TO DO: encapsulate in test library function
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo);

        exit(PostedDocNo);
    end;

    local procedure CreatePostAndMarkAsPaidSalesInvoiceWithPaymentDiscount(var SalesHeader: Record "Sales Header"; var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary): Code[20]
    var
        PostedDocNo: Code[20];
    begin
        PostedDocNo := CreateAndPostSalesInvoiceWithPaymentDiscount(SalesHeader);

        TempPaymentRegistrationBuffer.PopulateTable(); // TO DO: encapsulate in test library function
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", PostedDocNo);

        exit(PostedDocNo);
    end;

    local procedure CreatePostSalesInvoiceCreditMemoSingleCustomer(Customer: Record Customer; var PostedInvoiceNo: Code[20]; var PostedCreditMemoNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Clear(SalesLine);
        Clear(SalesHeader);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        PostedCreditMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostTwoSalesInvoices(var CustomerNo: Code[20]; var DocumentNo: array[2] of Code[20])
    var
        SalesHeader: Record "Sales Header";
        i: Integer;
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        for i := 1 to ArrayLen(DocumentNo) do begin
            CreateSalesDocumentWithCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
            DocumentNo[i] := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;
    end;

    local procedure CreatePaidPaymentRegistration(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        PostedDocNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocumentWithCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        TempPaymentRegistrationBuffer.PopulateTable();
        MarkDocumentAsPaid(TempPaymentRegistrationBuffer, Customer."No.", PostedDocNo);
    end;

    local procedure RestoreDefaultSetupFromDummyUser()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.Get(DummyUserNameTxt);
        PaymentRegistrationSetup."User ID" := '';
        PaymentRegistrationSetup.Insert();
    end;

    local procedure SetupBalAccountAsGLAccount()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        SetupBalAccount(PaymentRegistrationSetup."Bal. Account Type"::"G/L Account", GLAccount."No.", UserId);
    end;

    local procedure SetupBalAccountAsBankAccount()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        SetupBalAccount(PaymentRegistrationSetup."Bal. Account Type"::"Bank Account", BankAccount."No.", UserId);
    end;

    local procedure SetupBalAccount(AccountType: Integer; AccountNo: Code[20]; SetUserID: Code[50])
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.SetRange("User ID", SetUserID);
        PaymentRegistrationSetup.DeleteAll();
        PaymentRegistrationSetup.SetRange("User ID");

        PaymentRegistrationSetup.Get();
        PaymentRegistrationSetup."User ID" := SetUserID;
        PaymentRegistrationSetup.Validate("Bal. Account Type", AccountType);
        PaymentRegistrationSetup.Validate("Bal. Account No.", AccountNo);
        PaymentRegistrationSetup."Use this Account as Def." := true;
        PaymentRegistrationSetup."Auto Fill Date Received" := true;

        PaymentRegistrationSetup.Insert(true);
    end;

    local procedure PreparePmtRegSetupWithBankBalAccount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        CreateGenJournalBatchWithBankAccount(GenJournalBatch, CreateBankAccountWithCurrency());
        PaymentRegistrationSetup.SetRange("User ID", UserId);
        PaymentRegistrationSetup.DeleteAll();

        PaymentRegistrationSetup.Init();
        PaymentRegistrationSetup."User ID" := UserId;
        PaymentRegistrationSetup.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        PaymentRegistrationSetup.Validate("Journal Batch Name", GenJournalBatch.Name);
        PaymentRegistrationSetup.Insert(true);
    end;

    local procedure UpdateAmountReceived(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; CustomerNo: Code[20]; DocNo: Code[20]; AmountReceived: Decimal): Decimal
    begin
        FindPaymentRegistrationBuffer(TempPaymentRegistrationBuffer, CustomerNo, DocNo);
        TempPaymentRegistrationBuffer.Validate("Amount Received", AmountReceived);
        TempPaymentRegistrationBuffer.Modify(true);
        exit(TempPaymentRegistrationBuffer."Remaining Amount")
    end;

    local procedure UpdateAmountReceivedGreaterThanDiscountedAmount(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; CustomerNo: Code[20]; DocNo: Code[20]; ExtraPaymentAmount: Decimal)
    begin
        FindPaymentRegistrationBuffer(TempPaymentRegistrationBuffer, CustomerNo, DocNo);
        TempPaymentRegistrationBuffer.Validate("Amount Received",
          TempPaymentRegistrationBuffer."Rem. Amt. after Discount" + ExtraPaymentAmount);
        TempPaymentRegistrationBuffer.Modify(true);
    end;

    local procedure UpdateAmountReceivedAsDiscountedAmount(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; CustomerNo: Code[20]; DocNo: Code[20]): Decimal
    begin
        FindPaymentRegistrationBuffer(TempPaymentRegistrationBuffer, CustomerNo, DocNo);
        TempPaymentRegistrationBuffer.Validate("Amount Received", TempPaymentRegistrationBuffer."Rem. Amt. after Discount");
        TempPaymentRegistrationBuffer.Modify(true);
        exit(TempPaymentRegistrationBuffer."Remaining Amount")
    end;

    local procedure UpdateDateReceived(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; CustomerNo: Code[20]; DocNo: Code[20]; DateReceived: Date)
    begin
        FindPaymentRegistrationBuffer(TempPaymentRegistrationBuffer, CustomerNo, DocNo);
        TempPaymentRegistrationBuffer.Validate("Date Received", DateReceived);
        TempPaymentRegistrationBuffer.Modify(true);
    end;

    local procedure UpdateDateReceivedAfterPaymentDiscountDate(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; SalesHeader: Record "Sales Header"; DocNo: Code[20])
    begin
        UpdateDateReceived(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", DocNo,
          CalcDate(StrSubstNo('<%1D>', 1), SalesHeader."Pmt. Discount Date"));
    end;

    local procedure UpdateDateReceivedWithinPaymentDiscountDate(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; SalesHeader: Record "Sales Header"; DocNo: Code[20])
    begin
        UpdateDateReceived(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", DocNo,
          CalcDate(StrSubstNo('<%1D>', -1), SalesHeader."Pmt. Discount Date"));
    end;

    local procedure UpdatePaymentDiscountDateToDateReceived(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; CustomerNo: Code[20]; DocNo: Code[20]): Date
    begin
        FindPaymentRegistrationBuffer(TempPaymentRegistrationBuffer, CustomerNo, DocNo);
        TempPaymentRegistrationBuffer.Validate("Pmt. Discount Date", TempPaymentRegistrationBuffer."Date Received");
        TempPaymentRegistrationBuffer.Modify(true);
        exit(TempPaymentRegistrationBuffer."Pmt. Discount Date")
    end;

    local procedure UpdatePaymentDetailsForPaymentDiscount(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; SalesHeader: Record "Sales Header"; DocNo: Code[20]): Decimal
    begin
        UpdateDateReceivedWithinPaymentDiscountDate(TempPaymentRegistrationBuffer, SalesHeader, DocNo);
        exit(UpdateAmountReceivedAsDiscountedAmount(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", DocNo));
    end;

    local procedure UpdatePaymentDetailsForOverduePaymentDiscount(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary; SalesHeader: Record "Sales Header"; DocNo: Code[20]): Decimal
    begin
        UpdateDateReceivedAfterPaymentDiscountDate(TempPaymentRegistrationBuffer, SalesHeader, DocNo);
        exit(UpdateAmountReceivedAsDiscountedAmount(TempPaymentRegistrationBuffer, SalesHeader."Sell-to Customer No.", DocNo));
    end;

    local procedure UpdatePaymentDiscount(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandInt(99));
        SalesHeader.Validate("Pmt. Discount Date",
          CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), SalesHeader."Posting Date"));
        SalesHeader.Validate("Due Date",
          CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), SalesHeader."Pmt. Discount Date"));
        SalesHeader.Modify(true)
    end;

    local procedure ValidateExpectedAndActualSetupTables(PaymentRegistrationSetupExpected: Record "Payment Registration Setup"; PaymentRegistrationSetupActual: Record "Payment Registration Setup")
    begin
        Assert.AreEqual(
          PaymentRegistrationSetupExpected."Journal Template Name",
          PaymentRegistrationSetupActual."Journal Template Name",
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupExpected.FieldCaption("Journal Template Name")));

        Assert.AreEqual(
          PaymentRegistrationSetupExpected."Journal Batch Name",
          PaymentRegistrationSetupActual."Journal Batch Name",
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupExpected.FieldCaption("Journal Batch Name")));

        Assert.AreEqual(
          PaymentRegistrationSetupExpected."Bal. Account Type",
          PaymentRegistrationSetupActual."Bal. Account Type",
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupExpected.FieldCaption("Bal. Account Type")));

        Assert.AreEqual(
          PaymentRegistrationSetupExpected."Bal. Account No.",
          PaymentRegistrationSetupActual."Bal. Account No.",
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupExpected.FieldCaption("Bal. Account No.")));

        Assert.AreEqual(
          PaymentRegistrationSetupExpected."Use this Account as Def.",
          PaymentRegistrationSetupActual."Use this Account as Def.",
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupExpected.FieldCaption("Use this Account as Def.")));

        Assert.AreEqual(
          PaymentRegistrationSetupExpected."Auto Fill Date Received",
          PaymentRegistrationSetupActual."Auto Fill Date Received",
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupExpected.FieldCaption("Auto Fill Date Received")));
    end;

    local procedure VerifyCustLedgerEntry(CustomerNo: Code[20]; DocNo: Code[20]; RemainingAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustomerNo, DocNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", RemainingAmount);
        CustLedgerEntry.TestField(Open, RemainingAmount <> 0);
    end;

    local procedure VerifyCustLedgerEntryWithType(CustomerNo: Code[20]; DocNo: Code[20]; RemainingAmount: Decimal; ExpectedDocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustomerNo, DocNo);
        CustLedgerEntry.TestField("Document Type", ExpectedDocumentType);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", RemainingAmount);
        CustLedgerEntry.TestField(Open, RemainingAmount <> 0);
    end;

    local procedure VerifyCustLedgerEntryLumpPayment(CustomerNo: Code[20]; DocNo: Code[20]; LumpAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustomerNo, DocNo);
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Amount, -LumpAmount);
    end;

    local procedure VerifyCustLedgerEntryIsNotApplied(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustomerNo, DocumentNo);
        CustLedgerEntry.TestField("Applies-to ID", '');
        CustLedgerEntry.TestField("Applies-to Doc. No.", '');
        CustLedgerEntry.TestField("Amount to Apply", 0);
    end;

    local procedure VerifyCustLedgerEntryIsApplied(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustomerNo, DocumentNo);
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.TestField("Closed by Entry No.");
    end;

    local procedure VerifyMorePaymentRegistration(CustomerNo: Code[20]; DocNo: Code[20]; PaymentDocNo: Code[20]; RemainingPaymentAmount: Decimal)
    begin
        VerifyCustLedgerEntry(CustomerNo, DocNo, 0);
        VerifyCustLedgerEntry(CustomerNo, PaymentDocNo, RemainingPaymentAmount);
        VerifyPaymentRegistrationBuffer(CustomerNo, DocNo, true);
    end;

    local procedure VerifyPaymentRegistrationBuffer(CustomerNo: Code[20]; DocNo: Code[20]; ShouldBeEmpty: Boolean)
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        TempPaymentRegistrationBuffer.PopulateTable();

        TempPaymentRegistrationBuffer.SetRange("Source No.", CustomerNo);
        TempPaymentRegistrationBuffer.SetRange("Document No.", DocNo);
        Assert.IsTrue(TempPaymentRegistrationBuffer.IsEmpty() = ShouldBeEmpty, StrSubstNo(OpenCustomerDocErr, DocNo, CustomerNo));
    end;

    local procedure VerifyFullPaymentRegistration(CustomerNo: Code[20]; DocNo: Code[20]; PaymentDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        VerifyCustLedgerEntry(CustomerNo, DocNo, 0);
        VerifyCustLedgerEntryWithType(CustomerNo, PaymentDocNo, 0, CustLedgerEntry."Document Type"::Payment);
        VerifyPaymentRegistrationBuffer(CustomerNo, DocNo, true);
        VerifyBatchAndBalAccountInformation(CustomerNo, PaymentDocNo);
    end;

    local procedure VerifyFullRefundRegistration(CustomerNo: Code[20]; DocNo: Code[20]; RefundDocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        VerifyCustLedgerEntry(CustomerNo, DocNo, 0);
        VerifyCustLedgerEntryWithType(CustomerNo, RefundDocNo, 0, CustLedgerEntry."Document Type"::Refund);
        VerifyPaymentRegistrationBuffer(CustomerNo, DocNo, true);
        VerifyBatchAndBalAccountInformation(CustomerNo, RefundDocNo);
    end;

    local procedure VerifyPartialPaymentRegistration(CustomerNo: Code[20]; DocNo: Code[20]; PaymentDocNo: Code[20]; RemainingAmount: Decimal)
    begin
        VerifyCustLedgerEntry(CustomerNo, DocNo, RemainingAmount);
        VerifyCustLedgerEntry(CustomerNo, PaymentDocNo, 0);
        VerifyPaymentRegistrationBuffer(CustomerNo, DocNo, false);
        VerifyBatchAndBalAccountInformation(CustomerNo, PaymentDocNo);
    end;

    local procedure VerifyPaymentDiscountDateOnCustLedgerEntry(CustomerNo: Code[20]; DocNo: Code[20]; PaymentDiscountDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustomerNo, DocNo);
        CustLedgerEntry.TestField("Pmt. Discount Date", PaymentDiscountDate)
    end;

    local procedure VerifyBatchAndBalAccountInformation(CustomerNo: Code[20]; DocNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        FindCustLedgerEntry(CustLedgerEntry, CustomerNo, DocNo);
        PaymentRegistrationSetup.Get(UserId);

        CustLedgerEntry.TestField("Bal. Account No.", PaymentRegistrationSetup."Bal. Account No.");
        CustLedgerEntry.TestField("Bal. Account Type", PaymentRegistrationSetup.GetGLBalAccountType());
        CustLedgerEntry.TestField("Journal Batch Name", PaymentRegistrationSetup."Journal Batch Name");
    end;

    local procedure GetInvoiceAmount(DocNo: Code[20]): Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocNo);
        SalesInvoiceHeader.CalcFields(Amount);
        exit(SalesInvoiceHeader.Amount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text; var Reply: Boolean)
    begin
        Reply := false
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandlerSetupPageForEmptySetupTest(var PaymentRegistrationSetupPage: TestPage "Payment Registration Setup")
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Assert.AreEqual(
          '',
          PaymentRegistrationSetupPage."Journal Template Name".Value,
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupPage."Journal Template Name".Caption));

        Assert.AreEqual(
          '',
          PaymentRegistrationSetupPage."Journal Batch Name".Value,
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupPage."Journal Batch Name".Caption));

        Assert.AreEqual(
          ' ',
          PaymentRegistrationSetupPage."Bal. Account Type".Value,
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupPage."Bal. Account Type".Caption));

        Assert.AreEqual(
          '',
          PaymentRegistrationSetupPage."Bal. Account No.".Value,
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupPage."Bal. Account No.".Caption));

        PaymentRegistrationSetup.Get(DummyUserNameTxt);
        PaymentRegistrationSetupPage."Journal Template Name".Value := PaymentRegistrationSetup."Journal Template Name";
        PaymentRegistrationSetupPage."Journal Batch Name".Value := PaymentRegistrationSetup."Journal Batch Name";
        PaymentRegistrationSetupPage."Bal. Account Type".Value := Format(PaymentRegistrationSetup."Bal. Account Type"::"Bank Account");
        PaymentRegistrationSetupPage."Bal. Account No.".Value := PaymentRegistrationSetup."Bal. Account No.";
        PaymentRegistrationSetupPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandlerSetupPageForDefaultSetupTest(var PaymentRegistrationSetupPage: TestPage "Payment Registration Setup")
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.Get();

        Assert.AreEqual(
          PaymentRegistrationSetup."Journal Template Name",
          PaymentRegistrationSetupPage."Journal Template Name".Value,
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupPage."Journal Template Name".Caption));

        Assert.AreEqual(
          PaymentRegistrationSetup."Journal Batch Name",
          PaymentRegistrationSetupPage."Journal Batch Name".Value,
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupPage."Journal Batch Name".Caption));

        Assert.AreEqual(
          Format(PaymentRegistrationSetup."Bal. Account Type"),
          PaymentRegistrationSetupPage."Bal. Account Type".Value,
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupPage."Bal. Account Type".Caption));

        Assert.AreEqual(
          PaymentRegistrationSetup."Bal. Account No.",
          PaymentRegistrationSetupPage."Bal. Account No.".Value,
          StrSubstNo(WrongFieldValueErr, PaymentRegistrationSetupPage."Bal. Account No.".Caption));

        PaymentRegistrationSetupPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandlerPaymentRegistrationDetails(var PaymentRegistrationDetails: TestPage "Payment Registration Details")
    var
        ExpectedName: Variant;
        Name: Text[100];
    begin
        LibraryVariableStorage.Dequeue(ExpectedName);
        Name := PaymentRegistrationDetails.Name.Value();
        Assert.AreEqual(Name, ExpectedName, WrongCustomerErr);
    end;
}
