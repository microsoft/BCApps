codeunit 144055 "UT PAG Auto Payment"
{
    //  1. Purpose of the test is to validate code of OnAction TransferFloppy trigger of Page - 12190 Vendor Bill List Sent Card.
    //  2. Purpose of the test is to validate OnAction Invoice Card of Page - 12193 Subform Posted Vend Bill Lines with Manual Line FALSE.
    //  3. Purpose of the test is to validate OnAction Invoice Card of Page - 12193 Subform Posted Vend Bill Lines with Manual Line TRUE.
    //  4. Purpose of the test is to validate OnAction Dimension of Page - 12186 Subform Vendor Bill Lines with Manual Line TRUE.
    //  5. Purpose of the test is to validate OnAction Dimension of Page - 12186 Subform Vendor Bill Lines with Manual Line FALSE.
    //  6. Purpose of the test is to validate OnAction Invoice card of Page - 12186 Subform Vendor Bill Lines with Manual Line FALSE.
    //  7. Purpose of the test is to validate OnAction Invoice Card of Page - 12186 Subform Vendor Bill Lines with Manual Line TRUE.
    //  8. Purpose of the test is to validate CalcBalance function of Page - 12175 Customer Bill Card without Bank Account No.
    //  9. Purpose of the test is to validate CalcBalance function of Page - 12175 Customer Bill Card with Type as Bills For Discount.
    // 10. Purpose of the test is to validate CalcBalance function of Page - 12175 Customer Bill Card with Type as Bills Subject To Collection.
    // 11. Purpose of the test is to validate OnAction SuggestCustomerBill trigger of Page - 12175 Customer Bill Card without Payment Method Code.
    // 12. Purpose of the test is to validate OnAction SuggestCustomerBill trigger of Page - 12175 Customer Bill Card without Bank Account No.
    // 13. Purpose of the test is to validate OnAction SuggestCustomerBill trigger of Page - 12175 Customer Bill Card.
    // 14. Purpose of the test is to validate OnAction BRFloppy trigger of Page - 12175 Customer Bill Card.
    // 15. Purpose of the test is to validate OnAction Test Report trigger of Page - 12175 Customer Bill Card.
    // 16. Purpose of the test is to validate OnAssistEdit - No. trigger of Page - 12175 Customer Bill Card.
    // 17. Purpose of the test is to validate OnAction SelectBillToRecall trigger of Page - 12176 Subform Customer Bill Line.
    // 18. Purpose of the test is to validate OnAction Print trigger of Page - 12190 Vendor Bill List Sent Card.
    // 19. Purpose of the test is to validate OnAction Cancel List trigger of Page - 12190 Vendor Bill List Sent Card.
    // 20. Purpose of the test is to validate OnAction Print trigger of Page - 12185 Vendor Bill Card.
    // 21. Purpose of the test is to validate OnAction Select Bill To Recall of Page - 12181 Subform Issued Customer Bill Lines with blank Recalled By.
    // 22. Purpose of the test is to validate OnAction Select Bill To Recall of Page - 12181 Subform Issued Customer Bill Lines with blank Recalled Date.
    // 23. Purpose of the test is to validate OnAction Select Bill To Recall of Page - 12181 Subform Issued Customer Bill Lines with blank Recalled Date and blank Recalled By.
    // 
    // Covers Test Cases for WI - 347715.
    // ---------------------------------------------------------
    // Test Function Name                                 TFS ID
    // ---------------------------------------------------------
    // OnActionTransferFloppyVendorBillListSentCardError  151697
    // 
    // Covers Test Cases for WI - 348537
    // ---------------------------------------------------------
    // Test Function Name                                 TFS ID
    // ---------------------------------------------------------
    // OnActionInvoiceCardSubformPostedVendorBillLines
    // OnActionInvoiceCardSubformPostedVendorBillLinesError
    // OnActionDimensionVendorBillCardWithManualLineTrue
    // OnActionDimensionVendorBillCardWithManualLineFalse
    // OnActionInvoiceCardSubformVendorBillLines
    // OnActionInvoiceCardSubformVendorBillLinesError
    // 
    // Covers Test Cases for WI - 349771
    // ---------------------------------------------------------
    // Test Function Name                                 TFS ID
    // ---------------------------------------------------------
    // CalcBalanceBlankBankAccountNoCustomerBillCard
    // CalcBalanceBillsForDiscountCustomerBillCard
    // CalcBalanceBillsSubjectToCollectionCustBillCard
    // OnActionSugCustBillBlankPmtMethodCustBillCardError
    // OnActionSugCustBillBlankBankAccNoCustBillCardError
    // OnActionSuggestCustomerBillCustomerBillCard
    // OnActionBRFloppyCustomerBillCardError
    // OnActionTestReportCustomerBillCardError
    // OnAssistEditNoCustomerBillCard
    // OnActionSelectBillToRecallSubformCustBillLineError
    // OnActionPrintVendorBillListSentCard
    // OnActionCancelListVendorBillListSentCard
    // OnActionPrintVendorBillCard
    // OnActionSelectBillToRecallSubformIssuedVendBillLinesErr
    // OnActSelBillToRecallRecalledBySubformIssuedCustBillLns
    // OnActSelBillToRecallBlankRecalledBySubformIssuedCustBillLns

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        DialogErr: Label 'Dialog';
        FieldMustNotBeEmptyErr: Label 'Field %1 must not be empty.';
        OperationMsg: Label 'This operation will cause a gap in the numbering of %1. Continue anyway?';
        TestFieldErr: Label 'TestField';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        ValueEqualMsg: Label 'Value must be equal.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionTransferFloppyVendorBillListSentCardError()
    var
        VendorBillLine: Record "Vendor Bill Line";
        VendorBillListSentCard: TestPage "Vendor Bill List Sent Card";
    begin
        // Purpose of the test is to validate code of OnAction TransferFloppy trigger of Page - 12190 Vendor Bill List Sent Card.

        // Setup.
        Initialize();
        CreateVendorBillHeaderWithLine(VendorBillLine, false, 0);  // FALSE for manual Line, 0 for Dimension Set ID.
        VendorBillListSentCard.OpenEdit();
        VendorBillListSentCard.FILTER.SetFilter("No.", VendorBillLine."Vendor Bill List No.");

        // Exercise.
        asserterror VendorBillListSentCard.ExportBillListToFile.Invoke();

        // Verify: Verify expected error code.
        Assert.ExpectedErrorCannotFind(Database::"Bank Account");
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseInvoiceModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionInvoiceCardSubformPostedVendorBillLines()
    var
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        // Purpose of the test is to validate OnAction Invoice Card of Page - 12193 Subform Posted Vend Bill Lines with Manual Line FALSE.

        // Setup: Create Posted Vendor Bill Header and Purchase Invoice Header.
        Initialize();
        CreatePostedVendorBill(PostedVendorBillLine, false);  // FALSE for Manual Line.
        CreatePurchaseInvoiceHeader(PostedVendorBillLine."Document No.", PostedVendorBillLine."Vendor No.");

        // Enqueue values for PostedPurchaseInvoiceModalPageHandler.
        LibraryVariableStorage.Enqueue(PostedVendorBillLine."Document No.");
        LibraryVariableStorage.Enqueue(PostedVendorBillLine."Vendor Name");

        // Exercise.
        InvoiceCardOnSubformPostedVendorBillLines(PostedVendorBillLine."Vendor Bill No.");

        // Verify: Verify Vendor No on PostedPurchaseInvoiceModalPageHandler
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionInvoiceCardSubformPostedVendorBillLinesError()
    var
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        // Purpose of the test is to validate OnAction Invoice Card of Page - 12193 Subform Posted Vend Bill Lines with Manual Line TRUE.

        // Setup.
        Initialize();
        CreatePostedVendorBill(PostedVendorBillLine, true);  // TRUE for Manual Line.

        // Exercise.
        asserterror InvoiceCardOnSubformPostedVendorBillLines(PostedVendorBillLine."Vendor Bill No.");

        // Verify: Verify expected error code, actual error:"Invoice does not exists."
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionDimensionVendorBillCardWithManualLineTrue()
    begin
        // Purpose of the test is to validate OnAction Dimension of Page - 12186 Subform Vendor Bill Lines with Manual Line TRUE.
        OnActionDimensionVendorBillCard(true);  // TRUE for Manual Line.
    end;

    [Test]
    [HandlerFunctions('DimensionSetEntriesModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionDimensionVendorBillCardWithManualLineFalse()
    begin
        // Purpose of the test is to validate OnAction Dimension of Page - 12186 Subform Vendor Bill Lines with Manual Line FALSE.
        OnActionDimensionVendorBillCard(false);  // FALSE for Manual Line.
    end;

    [TransactionModel(TransactionModel::AutoRollback)]
    local procedure OnActionDimensionVendorBillCard(ManualLine: Boolean)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        VendorBillLine: Record "Vendor Bill Line";
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        // Setup: Create Dimension Set Entry, Create Vendor Bill.
        Initialize();
        CreateDimensionSetEntry(DimensionSetEntry);
        CreateVendorBillHeaderWithLine(VendorBillLine, ManualLine, DimensionSetEntry."Dimension Set ID");
        LibraryVariableStorage.Enqueue(DimensionSetEntry."Dimension Code");  // Enqueue for DimensionSetEntriesModalPageHandler and EditDimensionSetEntriesModalPageHandler.
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", VendorBillLine."Vendor Bill List No.");

        // Exercise.
        VendorBillCard.VendorBillLines.Dimension.Invoke();

        // Verify: Verify Dimension Code on DimensionSetEntriesModalPageHandler and EditDimensionSetEntriesModalPageHandler.

        // Tear down.
        VendorBillCard.Close();
    end;

    [Test]
    [HandlerFunctions('PostedPurchaseInvoiceModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionInvoiceCardSubformVendorBillLines()
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        // Purpose of the test is to validate OnAction Invoice card of Page - 12186 Subform Vendor Bill Lines with Manual Line FALSE.

        // Setup: Create vendor Bill and Purchase Invoice Header.
        Initialize();
        CreateVendorBillHeaderWithLine(VendorBillLine, false, 0);  // FALSE for Manual Line, 0 for Dimension Set Id.
        CreatePurchaseInvoiceHeader(VendorBillLine."Document No.", VendorBillLine."Vendor No.");

        // Enqueue values for PostedPurchaseInvoiceModalPageHandler.
        LibraryVariableStorage.Enqueue(VendorBillLine."Document No.");
        LibraryVariableStorage.Enqueue(VendorBillLine."Vendor Name");

        // Exercise.
        InvoiceCardOnVendorBillLines(VendorBillLine."Vendor Bill List No.");

        // Verify: Verify Vendor No on PostedPurchaseInvoiceModalPageHandler
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionInvoiceCardSubformVendorBillLinesError()
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        // Purpose of the test is to validate OnAction Invoice Card of Page - 12186 Subform Vendor Bill Lines with Manual Line TRUE.

        // Setup.
        Initialize();
        CreateVendorBillHeaderWithLine(VendorBillLine, true, 0);  // TRUE for Manual Line, 0 for Dimension Set Id.

        // Exercise.
        asserterror InvoiceCardOnVendorBillLines(VendorBillLine."Vendor Bill List No.");

        // Verify: Verify expected error code, actual error:"Invoice does not exists."
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcBalanceBlankBankAccountNoCustomerBillCard()
    var
        CustomerBillCard: TestPage "Customer Bill Card";
    begin
        // Purpose of the test is to validate CalcBalance function of Page - 12175 Customer Bill Card without Bank Account No.

        // Setup & Exercise.
        Initialize();
        CreateCustBillHeaderAndOpenCustBillCard(CustomerBillCard, '', CreatePaymentMethod());  // Using blank value for Bank Account No.

        // Verify.
        CustomerBillCard.Control1901848907.TotalPayments.AssertEquals(0);  // Value 0 required for TotalPayments.
        CustomerBillCard.Control1901848907.Balance.AssertEquals(0);  // Value 0 required for Balance.
        CustomerBillCard.Control1901848907.NewBalance.AssertEquals(0);  // Value 0 required for NewBalance.
        CustomerBillCard.Control1901848907.CreditLimit.AssertEquals(0);  // Value 0 required for CreditLimit.
        CustomerBillCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcBalanceBillsForDiscountCustomerBillCard()
    var
        CustomerBillHeader: Record "Customer Bill Header";
    begin
        // Purpose of the test is to validate CalcBalance function of Page - 12175 Customer Bill Card with Type as Bills For Discount.
        CalcBalanceOnCustomerBillCard(CustomerBillHeader.Type::"Bills For Discount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcBalanceBillsSubjectToCollectionCustBillCard()
    var
        CustomerBillHeader: Record "Customer Bill Header";
    begin
        // Purpose of the test is to validate CalcBalance function of Page - 12175 Customer Bill Card with Type as Bills Subject To Collection.
        CalcBalanceOnCustomerBillCard(CustomerBillHeader.Type::"Bills Subject To Collection");
    end;

    local procedure CalcBalanceOnCustomerBillCard(Type: Enum "Customer Bill Type")
    var
        CustomerBillHeader: Record "Customer Bill Header";
        GLAccount: Record "G/L Account";
        CustomerBillCard: TestPage "Customer Bill Card";
    begin
        // Setup: Create Customer Bill Header and Bill Posting Group.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateGLEntry(GLAccount."No.");
        GLAccount.CalcFields(Balance);
        CreateCustomerBillHeaderWithLine(CustomerBillHeader, CreateBankAccount(), CreatePaymentMethod(), Type);
        CreateBillPostingGroup(GLAccount."No.", CustomerBillHeader."Bank Account No.", CustomerBillHeader."Payment Method Code");
        CustomerBillCard.OpenEdit();

        // Exercise.
        CustomerBillCard.FILTER.SetFilter("No.", CustomerBillHeader."No.");

        // Verify.
        CustomerBillCard.Control1901848907.Balance.AssertEquals(GLAccount.Balance);
        CustomerBillCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionSugCustBillBlankPmtMethodCustBillCardError()
    begin
        // Purpose of the test is to validate OnAction SuggestCustomerBill trigger of Page - 12175 Customer Bill Card without Payment Method Code.
        Initialize();
        SuggestCustomerBillOnCustomerBillCard('');  // Using blank value for Payment Method Code.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionSugCustBillBlankBankAccNoCustBillCardError()
    begin
        // Purpose of the test is to validate OnAction SuggestCustomerBill trigger of Page - 12175 Customer Bill Card without Bank Account No.
        Initialize();
        SuggestCustomerBillOnCustomerBillCard(CreatePaymentMethod());
    end;

    local procedure SuggestCustomerBillOnCustomerBillCard(PaymentMethod: Code[10])
    var
        CustomerBillCard: TestPage "Customer Bill Card";
    begin
        // Setup.
        CreateCustBillHeaderAndOpenCustBillCard(CustomerBillCard, '', PaymentMethod);  // Using blank value for Bank Account No.

        // Exercise.
        asserterror CustomerBillCard.SuggestCustomerBill.Invoke();

        // Verify: Verify expected error code, actual error:"XXXX must have a value in Customer Bill Header:XXXX. It cannot be zero or empty."
        Assert.ExpectedErrorCode(TestFieldErr);
        CustomerBillCard.Close();
    end;

    [Test]
    [HandlerFunctions('SuggestCustomerBillsRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionSuggestCustomerBillCustomerBillCard()
    var
        CustomerBillCard: TestPage "Customer Bill Card";
    begin
        // Purpose of the test is to validate OnAction SuggestCustomerBill trigger of Page - 12175 Customer Bill Card.

        // Setup.
        Initialize();
        CreateCustBillHeaderAndOpenCustBillCard(CustomerBillCard, CreateBankAccount(), CreatePaymentMethod());

        // Exercise.
        CustomerBillCard.SuggestCustomerBill.Invoke();  // Opens SuggestCustomerBillsRequestPageHandler

        // Verify: SuggestCustomerBillsRequestPageHandler successfully opened.
        CustomerBillCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionBRFloppyCustomerBillCardError()
    var
        Bill: Record Bill;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        CustomerBillCard: TestPage "Customer Bill Card";
    begin
        // Purpose of the test is to validate OnAction BRFloppy trigger of Page - 12175 Customer Bill Card.

        // Setup.
        Initialize();
        CreateCustBillHeaderAndOpenCustBillCard(CustomerBillCard, CreateBankAccount(), CreatePaymentMethod());

        // Exercise.
        DirectDebitCollection.CreateRecord(CustomerBillCard."No.".Value, '', "Partner Type"::" ");
        DirectDebitCollection."Source Table ID" := DATABASE::"Customer Bill Header";
        DirectDebitCollection.Modify();
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        asserterror CODEUNIT.Run(CODEUNIT::"Customer Bills Floppy", DirectDebitCollectionEntry);

        // Verify: Verify expected error code, actual error:"You cannot create BR Floppy for Payment Method Code XXXX."
        Assert.ExpectedTestFieldError(Bill.FieldCaption("Bank Receipt"), Format(true));
        CustomerBillCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionTestReportCustomerBillCardError()
    var
        CustomerBillCard: TestPage "Customer Bill Card";
    begin
        // Purpose of the test is to validate OnAction Test Report trigger of Page - 12175 Customer Bill Card.

        // Setup.
        Initialize();
        CreateCustBillHeaderAndOpenCustBillCard(CustomerBillCard, CreateBankAccount(), CreatePaymentMethod());

        // Exercise.
        asserterror CustomerBillCard.TestReport.Invoke();

        // Verify: Verify expected error code, actual error:"Line XXXX has Amount equal to 0."
        Assert.ExpectedErrorCode(DialogErr);
        CustomerBillCard.Close();
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAssistEditNoCustomerBillCard()
    var
        CustomerBillCard: TestPage "Customer Bill Card";
    begin
        // Purpose of the test is to validate OnAssistEdit - No. trigger of Page - 12175 Customer Bill Card.

        // Setup.
        Initialize();
        CustomerBillCard.OpenNew();

        // Exercise.
        CustomerBillCard."No.".AssistEdit();

        // Verify.
        Assert.AreNotEqual('', Format(CustomerBillCard."No."), StrSubstNo(FieldMustNotBeEmptyErr, CustomerBillCard."No.".Caption));  // Using blank value for Customer Bill Card No.
        CustomerBillCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnActionSelectBillToRecallSubformCustBillLineError()
    var
        CustomerBillCard: TestPage "Customer Bill Card";
    begin
        // Purpose of the test is to validate OnAction SelectBillToRecall trigger of Page - 12176 Subform Customer Bill Line.

        // Setup.
        Initialize();
        CreateCustBillHeaderAndOpenCustBillCard(CustomerBillCard, CreateBankAccount(), CreatePaymentMethod());

        // Exercise.
        asserterror CustomerBillCard.CustomerBillLine.SelectBillToRecall.Invoke();

        // Verify: Verify expected error code, actual error:"You can run this function only when field Allow Issue in table Bill is Yes."
        Assert.ExpectedErrorCode(DialogErr);
        CustomerBillCard.Close();
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler,VendorBillReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionPrintVendorBillListSentCard()
    var
        VendorBillListSentCard: TestPage "Vendor Bill List Sent Card";
    begin
        // Purpose of the test is to validate OnAction Print trigger of Page - 12190 Vendor Bill List Sent Card.

        // Setup.
        Initialize();
        VendorBillListSentCard.OpenEdit();
        VendorBillListSentCard."No.".AssistEdit();

        // Exercise.
        VendorBillListSentCard.Print.Invoke();  // Opens VendorBillReportHandler.

        // Verify: VendorBillReportHandler successfully opened.
        VendorBillListSentCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionCancelListVendorBillListSentCard()
    var
        VendorBillListSentCard: TestPage "Vendor Bill List Sent Card";
    begin
        // Purpose of the test is to validate OnAction Cancel List trigger of Page - 12190 Vendor Bill List Sent Card.

        // Setup.
        Initialize();
        VendorBillListSentCard.OpenEdit();

        // Exercise.
        VendorBillListSentCard.CancelList.Invoke();

        // Verify: Verification is done in ConfirmHandler.
        VendorBillListSentCard.Close();
    end;

    [Test]
    [HandlerFunctions('VendorBillReportHandler,NoSeriesListModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionPrintVendorBillCard()
    var
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        // Purpose of the test is to validate OnAction Print trigger of Page - 12185 Vendor Bill Card.

        // Setup.
        Initialize();
        VendorBillCard.OpenEdit();
        VendorBillCard."No.".AssistEdit();

        // Exercise.
        VendorBillCard.Print.Invoke();  // Opens VendorBillReportHandler.

        // Verify: VendorBillReportHandler successfully opened.
        VendorBillCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionSelectBillToRecallSubformIssuedCustBillLinesErr()
    var
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
    begin
        // Purpose of the test is to validate OnAction Select Bill To Recall of Page - 12181 Subform Issued Customer Bill Lines with blank Recalled By.

        // Setup.
        Initialize();
        CreateIssuedCustomerBill(IssuedCustomerBillLine, WorkDate(), '');  // Blank for Recalled By.

        // Exercise.
        asserterror SelectBillToRecallOnIssuedCustomerBillCard(IssuedCustomerBillLine."Customer Bill No.");

        // Verify: Verify expected error code, actual error:"Customer Bill  already recalled."
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActSelBillToRecallRecalledBySubformIssuedCustBillLns()
    begin
        // Purpose of the test is to validate OnAction Select Bill To Recall of Page - 12181 Subform Issued Customer Bill Lines with blank Recalled Date.
        OnActionSelectBillToRecallSubformIssuedCustBillLines(UserId, '');  // Blank for ExpectedRecalled By.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActSelBillToRecallBlankRecalledBySubformIssuedCustBillLns()
    begin
        // Purpose of the test is to validate OnAction Select Bill To Recall of Page - 12181 Subform Issued Customer Bill Lines with blank Recalled Date and blank Recalled By.
        OnActionSelectBillToRecallSubformIssuedCustBillLines('', UserId);  // Blank for Recalled By.
    end;

    local procedure OnActionSelectBillToRecallSubformIssuedCustBillLines(RecalledBy: Code[50]; ExpectedRecalledBy: Code[50])
    var
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
    begin
        // Setup.
        Initialize();
        CreateIssuedCustomerBill(IssuedCustomerBillLine, 0D, RecalledBy);  // 0D for Recall Date.

        // Exercise.
        SelectBillToRecallOnIssuedCustomerBillCard(IssuedCustomerBillLine."Customer Bill No.");

        // Verify:
        IssuedCustomerBillLine.Get(IssuedCustomerBillLine."Customer Bill No.", IssuedCustomerBillLine."Line No.");
        IssuedCustomerBillLine.TestField("Recalled by", ExpectedRecalledBy);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount."Bank Acc. Posting Group" := CreateBankAccountPostingGroup();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBankAccountPostingGroup(): Code[20]
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccountPostingGroup.Code := LibraryUTUtility.GetNewCode10();
        BankAccountPostingGroup.Insert();
        exit(BankAccountPostingGroup.Code);
    end;

    local procedure CreateBill(): Code[20]
    var
        Bill: Record Bill;
    begin
        Bill.Code := LibraryUTUtility.GetNewCode();
        Bill."Allow Issue" := false;  // As required by the test case using FALSE for Allow Issue.
        Bill.Insert();
        exit(Bill.Code);
    end;

    local procedure CreateBillPostingGroup(BillsForDiscountAccNo: Code[20]; No: Code[20]; PaymentMethod: Code[10])
    var
        BillPostingGroup: Record "Bill Posting Group";
    begin
        BillPostingGroup."No." := No;
        BillPostingGroup."Payment Method" := PaymentMethod;
        BillPostingGroup."Bills For Discount Acc. No." := BillsForDiscountAccNo;
        BillPostingGroup."Bills Subj. to Coll. Acc. No." := BillsForDiscountAccNo;
        BillPostingGroup.Insert();
    end;

    local procedure CreateCustBillHeaderAndOpenCustBillCard(var CustomerBillCard: TestPage "Customer Bill Card"; BankAccountNo: Code[20]; PaymentMethodCode: Code[10])
    var
        CustomerBillHeader: Record "Customer Bill Header";
    begin
        CreateCustomerBillHeaderWithLine(CustomerBillHeader, BankAccountNo, PaymentMethodCode, CustomerBillHeader.Type::" ");
        CustomerBillCard.OpenEdit();
        CustomerBillCard.FILTER.SetFilter("No.", CustomerBillHeader."No.");
    end;

    local procedure CreateCustomerBillHeaderWithLine(var CustomerBillHeader: Record "Customer Bill Header"; BankAccountNo: Code[20]; PaymentMethodCode: Code[10]; Type: Enum "Customer Bill Type")
    var
        CustomerBillLine: Record "Customer Bill Line";
    begin
        CustomerBillHeader."No." := LibraryUTUtility.GetNewCode();
        CustomerBillHeader."Bank Account No." := BankAccountNo;
        CustomerBillHeader.Type := Type;
        CustomerBillHeader."Payment Method Code" := PaymentMethodCode;
        CustomerBillHeader.Insert();
        CustomerBillLine."Customer Bill No." := CustomerBillHeader."No.";
        CustomerBillLine.Insert();
    end;

    local procedure CreateDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry")
    var
        DimensionSetEntry2: Record "Dimension Set Entry";
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue."Dimension Code" := LibraryUTUtility.GetNewCode();
        DimensionValue.Code := LibraryUTUtility.GetNewCode();
        DimensionValue.Insert();
        DimensionSetEntry2.FindLast();
        DimensionSetEntry."Dimension Set ID" := DimensionSetEntry2."Dimension Set ID" + LibraryRandom.RandInt(10);
        DimensionSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        DimensionSetEntry."Dimension Value ID" := LibraryRandom.RandInt(10);
        DimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        DimensionSetEntry.Insert();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
    end;

    local procedure CreateGLEntry(GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry.Amount := LibraryRandom.RandDec(100, 2);
        GLEntry.Insert();
    end;

    local procedure CreateIssuedCustomerBill(var IssuedCustomerBillLine: Record "Issued Customer Bill Line"; RecallDate: Date; RecalledBy: Code[50])
    var
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
    begin
        IssuedCustomerBillHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedCustomerBillHeader.Insert();
        IssuedCustomerBillLine."Customer Bill No." := IssuedCustomerBillHeader."No.";
        IssuedCustomerBillLine."Line No." := LibraryRandom.RandInt(10);
        IssuedCustomerBillLine."Recall Date" := RecallDate;
        IssuedCustomerBillLine."Recalled by" := RecalledBy;
        IssuedCustomerBillLine.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBillHeaderWithLine(var VendorBillLine: Record "Vendor Bill Line"; ManualLine: Boolean; DimensionSetID: Integer)
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        VendorBillHeader."No." := LibraryUTUtility.GetNewCode();
        VendorBillHeader."Bank Account No." := CreateBankAccount();
        VendorBillHeader."Vendor Bill List No." := LibraryUTUtility.GetNewCode();
        VendorBillHeader.Insert();
        VendorBillLine."Vendor Bill List No." := VendorBillHeader."No.";
        VendorBillLine."Document No." := LibraryUTUtility.GetNewCode();
        VendorBillLine."Vendor No." := CreateVendor();
        VendorBillLine."Dimension Set ID" := DimensionSetID;
        VendorBillLine."Manual Line" := ManualLine;
        VendorBillLine.Insert();
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Code := LibraryUTUtility.GetNewCode10();
        PaymentMethod."Bill Code" := CreateBill();
        PaymentMethod.Insert();
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePostedVendorBill(var PostedVendorBillLine: Record "Posted Vendor Bill Line"; ManualLine: Boolean)
    var
        PostedVendorBillHeader: Record "Posted Vendor Bill Header";
    begin
        PostedVendorBillHeader."No." := LibraryUTUtility.GetNewCode();
        PostedVendorBillHeader.Insert();
        PostedVendorBillLine."Vendor Bill No." := PostedVendorBillHeader."No.";
        PostedVendorBillLine."Document No." := LibraryUTUtility.GetNewCode();
        PostedVendorBillLine."Vendor No." := CreateVendor();
        PostedVendorBillLine."Manual Line" := ManualLine;
        PostedVendorBillLine.Insert();
    end;

    local procedure CreatePurchaseInvoiceHeader(No: Code[20]; BuyFromVendorNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader."No." := No;
        PurchInvHeader."Buy-from Vendor No." := BuyFromVendorNo;
        PurchInvHeader.Insert();
    end;

    local procedure InvoiceCardOnVendorBillLines(No: Code[20])
    var
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        VendorBillCard.OpenEdit();
        VendorBillCard.FILTER.SetFilter("No.", No);
        VendorBillCard.VendorBillLines.InvoiceCard.Invoke();  // Invokes PostedPurchaseInvoiceModalPageHandler.
        VendorBillCard.Close();
    end;

    local procedure InvoiceCardOnSubformPostedVendorBillLines(No: Code[20])
    var
        PostedVendorBillCard: TestPage "Posted Vendor Bill Card";
    begin
        PostedVendorBillCard.OpenEdit();
        PostedVendorBillCard.FILTER.SetFilter("No.", No);
        PostedVendorBillCard.SubformPostedVendBillLines.InvoiceCard.Invoke();  // Invokes PostedPurchaseInvoiceModalPageHandler.
        PostedVendorBillCard.Close();
    end;

    local procedure SelectBillToRecallOnIssuedCustomerBillCard(No: Code[20])
    var
        IssuedCustomerBillCard: TestPage "Issued Customer Bill Card";
    begin
        IssuedCustomerBillCard.OpenEdit();
        IssuedCustomerBillCard.FILTER.SetFilter("No.", No);
        IssuedCustomerBillCard.BankReceiptsLines.SelectBillToRecall.Invoke();
        IssuedCustomerBillCard.Close();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestCustomerBillsRequestPageHandler(var SuggestCustomerBills: TestRequestPage "Suggest Customer Bills")
    begin
        SuggestCustomerBills.OK().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure VendorBillReportHandler(var VendorBillReport: Report "Vendor Bill Report")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesModalPageHandler(var DimensionSetEntries: TestPage "Dimension Set Entries")
    var
        DimensionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCode);
        DimensionSetEntries."Dimension Code".AssertEquals(DimensionCode);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesModalPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    var
        DimensionCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DimensionCode);
        EditDimensionSetEntries."Dimension Code".AssertEquals(DimensionCode);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceModalPageHandler(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    var
        BuyFromVendorName: Variant;
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(BuyFromVendorName);
        PostedPurchaseInvoice.FILTER.SetFilter("No.", No);
        PostedPurchaseInvoice."Buy-from Vendor Name".AssertEquals(BuyFromVendorName);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.AreEqual(StrSubstNo(OperationMsg), Question, ValueEqualMsg);
    end;
}

