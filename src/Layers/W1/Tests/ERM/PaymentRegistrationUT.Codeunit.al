codeunit 134700 "Payment Registration UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Registration] [UT]
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        BlankFieldErr: Label '%1 must have a value in %2';
        BlankOptionErr: Label '%1 must not be   in %2';
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ExpectedEntryErr: Label 'Expected entry not found.';
        MandatoryFieldsSetErr: Label 'All mandatory fields are set. Function should return TRUE.';
        MandatoryFieldsNotSetErr: Label 'Mandatory field is not set. Function should return FALSE.';
        UnexpectedEntryErr: Label 'Unexpected entry found.';
        WrongCaptionErr: Label 'Caption is missing %1.';
        EmptyReceivedDateErr: Label 'Date Received is missing for line with Document No.';
        ConfirmCloseExpectedTrueErr: Label 'Expected ConfirmClose to return TRUE';
        ReloadErr: Label 'Reload is incorrect (testing field %1).', Comment = 'Reload is incorrect (testing field Document Paid).';
        ReloadCountErr: Label 'Reload is incorrect (wrong count).';
        MaxPaymentDiscountAmount: Decimal;
        ReloadSortingErr: Label 'Reload is incorrect (wrong sorting).';
        ReloadCurrRecErr: Label 'Reload is incorrect (wrong Current Rec).';
        WrongUserErr: Label 'Wrong user.';
        StyleErr: Label 'Expected style is not correct.';
        WarningErr: Label 'Warning text is not correct.';
        DueDateMsg: Label 'The payment is overdue. You can calculate interest for late payments from customers by choosing the Finance Charge Memo button.';
        PmtDiscMsg: Label 'Payment Discount Date is earlier than Date Received. Payment will be registered as partial payment.';
        SalesOrderTxt: Label 'Sales Order';
        SalesBlanketOrderTxt: Label 'Sales Blanket Order';
        SalesQuoteTxt: Label 'Sales Quote';
        SalesInvoiceTxt: Label 'Sales Invoice';
        SalesReturnOrderTxt: Label 'Sales Return Order';
        SalesCreditMemoTxt: Label 'Sales Credit Memo';
        ServiceQuoteTxt: Label 'Service Quote';
        ServiceOrderTxt: Label 'Service Order';
        ServiceInvoiceTxt: Label 'Service Invoice';
        ServiceCreditMemoTxt: Label 'Service Credit Memo';
        ToleranceTxt: Label 'The program will search for documents with amounts between %1 and %2.';

    [Test]
    [Scope('OnPrem')]
    procedure CheckAutoPopulation()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        SetAutoFillDate();

        TempPaymentRegistrationBuffer.Init();
        TempPaymentRegistrationBuffer."Remaining Amount" := LibraryRandom.RandDec(100, 2);
        TempPaymentRegistrationBuffer."Original Remaining Amount" := TempPaymentRegistrationBuffer."Remaining Amount";
        TempPaymentRegistrationBuffer.Insert();

        TempPaymentRegistrationBuffer.TestField("Amount Received", 0);
        TempPaymentRegistrationBuffer.TestField("Date Received", 0D);

        TempPaymentRegistrationBuffer.Validate("Payment Made", true);
        TempPaymentRegistrationBuffer.Modify(true);

        TempPaymentRegistrationBuffer.TestField("Amount Received", TempPaymentRegistrationBuffer."Original Remaining Amount");
        TempPaymentRegistrationBuffer.TestField("Date Received", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckNoAutoPopulation()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        TempPaymentRegistrationBuffer.Init();
        TempPaymentRegistrationBuffer."Remaining Amount" := LibraryRandom.RandDec(100, 2);
        TempPaymentRegistrationBuffer.Insert();

        TempPaymentRegistrationBuffer.TestField("Amount Received", 0);
        TempPaymentRegistrationBuffer.TestField("Date Received", 0D);

        TempPaymentRegistrationBuffer.Validate("Payment Made", true);
        TempPaymentRegistrationBuffer.Modify(true);

        TempPaymentRegistrationBuffer.TestField("Amount Received", 0);
        TempPaymentRegistrationBuffer.TestField("Date Received", 0D);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckOpenCustomerLedgerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        FirstEntryNo: Integer;
    begin
        Initialize();

        // Create Open Entries
        FirstEntryNo := CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, true);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", true);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Finance Charge Memo", true);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Reminder, true);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Refund, true);

        // Create Closed Entries
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, false);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, false);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", false);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Finance Charge Memo", false);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Reminder, false);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Refund, false);

        // Exercise:
        TempPaymentRegistrationBuffer.PopulateTable();

        // Verify:
        // Valid Entries
        CustLedgerEntry.SetFilter("Entry No.", '%1..', FirstEntryNo);
        CustLedgerEntry.SetFilter("Document Type", '%1|%2|%3|%4|%5',
          CustLedgerEntry."Document Type"::Invoice,
          CustLedgerEntry."Document Type"::"Finance Charge Memo",
          CustLedgerEntry."Document Type"::Reminder,
          CustLedgerEntry."Document Type"::Refund,
          CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.FindSet();
        repeat
            Assert.IsTrue(TempPaymentRegistrationBuffer.Get(CustLedgerEntry."Entry No."), ExpectedEntryErr);
        until CustLedgerEntry.Next() = 0;

        // Invalid Open Entries
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetFilter("Entry No.", '%1..', FirstEntryNo);
        CustLedgerEntry.SetFilter("Document Type", '%1',
          CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.FindSet();
        repeat
            Assert.IsFalse(TempPaymentRegistrationBuffer.Get(CustLedgerEntry."Entry No."), UnexpectedEntryErr);
        until CustLedgerEntry.Next() = 0;

        // Invalid Closed Entries
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetFilter("Entry No.", '%1..', FirstEntryNo);
        CustLedgerEntry.SetRange(Open, false);
        CustLedgerEntry.FindSet();
        repeat
            Assert.IsFalse(TempPaymentRegistrationBuffer.Get(CustLedgerEntry."Entry No."), UnexpectedEntryErr);
        until CustLedgerEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPaymentRegistrationPageCaption()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        PaymentRegistrationPage: TestPage "Payment Registration";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);

        PaymentRegistrationPage.OpenView();
        Assert.IsTrue(StrPos(PaymentRegistrationPage.Caption, Format(PaymentRegistrationSetup."Bal. Account Type")) > 0,
          StrSubstNo(WrongCaptionErr, PaymentRegistrationSetup.FieldName("Bal. Account Type")));
        Assert.IsTrue(StrPos(PaymentRegistrationPage.Caption, Format(PaymentRegistrationSetup."Bal. Account No.")) > 0,
          StrSubstNo(WrongCaptionErr, PaymentRegistrationSetup.FieldName("Bal. Account No.")));

        PaymentRegistrationPage.Close();
    end;

    [Test]
    [HandlerFunctions('PaymentRegistrationSetupOKPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPaymentRegistrationPageCaptionOnRefresh()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        PaymentRegistrationPage: TestPage "Payment Registration";
    begin
        Initialize();

        PaymentRegistrationPage.OpenView();
        PaymentRegistrationPage.Setup.Invoke();

        PaymentRegistrationSetup.Get(UserId);
        Assert.IsTrue(StrPos(PaymentRegistrationPage.Caption, Format(PaymentRegistrationSetup."Bal. Account Type")) > 0,
          StrSubstNo(WrongCaptionErr, PaymentRegistrationSetup.FieldName("Bal. Account Type")));
        Assert.IsTrue(StrPos(PaymentRegistrationPage.Caption, Format(PaymentRegistrationSetup."Bal. Account No.")) > 0,
          StrSubstNo(WrongCaptionErr, PaymentRegistrationSetup.FieldName("Bal. Account No.")));

        PaymentRegistrationPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPopulateTable()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
    begin
        // [SCENARIO 412300] "Payment Method Code" must be filled if "Cust. Ledger Entry"."Payment Method Code" has value
        Initialize();

        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        CustLedgerEntry."Payment Method Code" := PaymentMethod.Code;
        CustLedgerEntry.Modify();
        CreateDetailedCustomerLedgerEntry(CustLedgerEntry."Entry No.");

        TempPaymentRegistrationBuffer.PopulateTable();
        TempPaymentRegistrationBuffer.Get(CustLedgerEntry."Entry No.");
        TempPaymentRegistrationBuffer.TestField("Source No.", CustLedgerEntry."Customer No.");
        Customer.Get(CustLedgerEntry."Customer No.");
        TempPaymentRegistrationBuffer.TestField(Name, Customer.Name);
        TempPaymentRegistrationBuffer.TestField("Document No.", CustLedgerEntry."Document No.");
        TempPaymentRegistrationBuffer.TestField("Document Type", CustLedgerEntry."Document Type");
        TempPaymentRegistrationBuffer.TestField(Description, CustLedgerEntry.Description);
        TempPaymentRegistrationBuffer.TestField("Due Date", CustLedgerEntry."Due Date");
        CustLedgerEntry.CalcFields("Remaining Amount");
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", CustLedgerEntry."Remaining Amount");
        TempPaymentRegistrationBuffer.TestField("Pmt. Discount Date", CustLedgerEntry."Pmt. Discount Date");
        TempPaymentRegistrationBuffer.TestField("Rem. Amt. after Discount",
          CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible");
        TempPaymentRegistrationBuffer.TestField("Payment Method Code", PaymentMethod.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPopulateTableWithNoOpenCustLedgEntry()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.ModifyAll(Open, false);
        Commit();

        asserterror CustLedgEntry.FindFirst();
        asserterror TempPaymentRegistrationBuffer.FindFirst();
        TempPaymentRegistrationBuffer.PopulateTable();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAllMandatoryFieldsOkShowErrorEnabled()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        Assert.IsTrue(PaymentRegistrationSetup.ValidateMandatoryFields(true), MandatoryFieldsSetErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAllMandatoryFieldsOk()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        Assert.IsTrue(PaymentRegistrationSetup.ValidateMandatoryFields(false), MandatoryFieldsSetErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateJournalTemplateNameMandatoryShowErrorEnabled()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Journal Template Name" := '';
        PaymentRegistrationSetup.Modify();
        asserterror PaymentRegistrationSetup.ValidateMandatoryFields(true);
        Assert.ExpectedError(StrSubstNo(BlankFieldErr,
            PaymentRegistrationSetup.FieldName("Journal Template Name"), PaymentRegistrationSetup.TableName))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateJournalBatchNameMandatoryShowErrorEnabled()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Journal Batch Name" := '';
        PaymentRegistrationSetup.Modify();
        asserterror PaymentRegistrationSetup.ValidateMandatoryFields(true);
        Assert.ExpectedError(StrSubstNo(BlankFieldErr,
            PaymentRegistrationSetup.FieldName("Journal Batch Name"), PaymentRegistrationSetup.TableName))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalAccountTypeMandatoryShowErrorEnabled()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Bal. Account Type" := PaymentRegistrationSetup."Bal. Account Type"::" ";
        PaymentRegistrationSetup.Modify();
        asserterror PaymentRegistrationSetup.ValidateMandatoryFields(true);
        Assert.ExpectedError(StrSubstNo(BlankOptionErr,
            PaymentRegistrationSetup.FieldName("Bal. Account Type"), PaymentRegistrationSetup.TableName))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalAccountNoMandatoryShowErrorEnabled()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Bal. Account No." := '';
        PaymentRegistrationSetup.Modify();
        asserterror PaymentRegistrationSetup.ValidateMandatoryFields(true);
        Assert.ExpectedError(StrSubstNo(BlankFieldErr,
            PaymentRegistrationSetup.FieldName("Bal. Account No."), PaymentRegistrationSetup.TableName))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateNothingToPostError()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        asserterror PaymentRegistrationMgt.ConfirmPost(TempPaymentRegistrationBuffer);
        Assert.ExpectedError(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [HandlerFunctions('HandlerConfirmYes')]
    [Scope('OnPrem')]
    procedure ValidateEmptyReceivedDateError()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        TempPaymentRegistrationBuffer.Init();
        TempPaymentRegistrationBuffer."Ledger Entry No." := -1;
        TempPaymentRegistrationBuffer."Amount Received" := -1;
        TempPaymentRegistrationBuffer."Payment Made" := true;
        TempPaymentRegistrationBuffer.Insert();

        asserterror PaymentRegistrationMgt.ConfirmPost(TempPaymentRegistrationBuffer);
        Assert.ExpectedError(EmptyReceivedDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateNoSeriesMandatoryShowErrrorEnabled()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        GenJournalBatch.Get(PaymentRegistrationSetup."Journal Template Name", PaymentRegistrationSetup."Journal Batch Name");
        GenJournalBatch."No. Series" := '';
        GenJournalBatch.Modify();
        asserterror PaymentRegistrationSetup.ValidateMandatoryFields(true);
        Assert.ExpectedError(StrSubstNo(BlankFieldErr,
            GenJournalBatch.FieldName("No. Series"), GenJournalBatch.TableName))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateJournalTemplateNameMandatory()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Journal Template Name" := '';
        PaymentRegistrationSetup.Modify();
        Assert.IsFalse(PaymentRegistrationSetup.ValidateMandatoryFields(false), MandatoryFieldsNotSetErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateJournalBatchNameMandatory()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Journal Batch Name" := '';
        PaymentRegistrationSetup.Modify();
        Assert.IsFalse(PaymentRegistrationSetup.ValidateMandatoryFields(false), MandatoryFieldsNotSetErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalAccountTypeMandatory()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Bal. Account Type" := PaymentRegistrationSetup."Bal. Account Type"::" ";
        PaymentRegistrationSetup.Modify();
        Assert.IsFalse(PaymentRegistrationSetup.ValidateMandatoryFields(false), MandatoryFieldsNotSetErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBalAccountNoMandatory()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Bal. Account No." := '';
        PaymentRegistrationSetup.Modify();
        Assert.IsFalse(PaymentRegistrationSetup.ValidateMandatoryFields(false), MandatoryFieldsNotSetErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateNoSeriesMandatory()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        GenJournalBatch.Get(PaymentRegistrationSetup."Journal Template Name", PaymentRegistrationSetup."Journal Batch Name");
        GenJournalBatch."No. Series" := '';
        GenJournalBatch.Modify();
        Assert.IsFalse(PaymentRegistrationSetup.ValidateMandatoryFields(false), MandatoryFieldsNotSetErr)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateJournalBatchWithBalAccountTypeAsGLAccount()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        GenJournalBatch.Get(PaymentRegistrationSetup."Journal Template Name", PaymentRegistrationSetup."Journal Batch Name");
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := LibraryERM.CreateGLAccountNo();
        GenJournalBatch.Modify();

        PaymentRegistrationSetup.Validate("Journal Batch Name", GenJournalBatch.Name);
        PaymentRegistrationSetup.TestField("Bal. Account Type", PaymentRegistrationSetup."Bal. Account Type"::"G/L Account");
        PaymentRegistrationSetup.TestField("Bal. Account No.", GenJournalBatch."Bal. Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateJournalBatchWithBalAccountTypeAsBankAccount()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        GenJournalBatch.Get(PaymentRegistrationSetup."Journal Template Name", PaymentRegistrationSetup."Journal Batch Name");
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := CreateBankAccount();
        GenJournalBatch.Modify();

        PaymentRegistrationSetup.Validate("Journal Batch Name", GenJournalBatch.Name);
        PaymentRegistrationSetup.TestField("Bal. Account Type", PaymentRegistrationSetup."Bal. Account Type"::"Bank Account");
        PaymentRegistrationSetup.TestField("Bal. Account No.", GenJournalBatch."Bal. Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateJournalBatchWithBalAccountTypeAsEmpty()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        Initialize();
        PaymentRegistrationSetup.Get(UserId);
        GenJournalBatch.Get(PaymentRegistrationSetup."Journal Template Name", PaymentRegistrationSetup."Journal Batch Name");
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::Customer;
        GenJournalBatch.Modify();

        PaymentRegistrationSetup.Validate("Journal Batch Name", GenJournalBatch.Name);
        PaymentRegistrationSetup.TestField("Bal. Account Type", PaymentRegistrationSetup."Bal. Account Type"::" ");
        PaymentRegistrationSetup.TestField("Bal. Account No.", GenJournalBatch."Bal. Account No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDocumentPaidInDiscDate()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Pmt. Discount Date" := TempPaymentRegistrationBuffer."Date Received" + LibraryRandom.RandInt(5);
        TempPaymentRegistrationBuffer.Validate("Payment Made", true);
        TempPaymentRegistrationBuffer.TestField("Amount Received", TempPaymentRegistrationBuffer."Rem. Amt. after Discount");
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDocumentPaidOutDiscDate()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Pmt. Discount Date" := TempPaymentRegistrationBuffer."Date Received" - LibraryRandom.RandInt(5);
        TempPaymentRegistrationBuffer.Validate("Payment Made", true);
        TempPaymentRegistrationBuffer.TestField("Amount Received", TempPaymentRegistrationBuffer."Original Remaining Amount");
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateUncheckOfDocumentPaid()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);

        TempPaymentRegistrationBuffer."Amount Received" := LibraryRandom.RandDec(100, 2);
        TempPaymentRegistrationBuffer."Payment Made" := true;
        TempPaymentRegistrationBuffer.Validate("Payment Made", false);
        TempPaymentRegistrationBuffer.TestField("Date Received", 0D);
        TempPaymentRegistrationBuffer.TestField("Amount Received", 0);
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", TempPaymentRegistrationBuffer."Original Remaining Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateReloadPersistChangedData()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        EntryNo: Integer;
    begin
        Initialize();

        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);
        EntryNo := CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);

        TempPaymentRegistrationBuffer.PopulateTable();

        TempPaymentRegistrationBuffer.Get(EntryNo);
        TempPaymentRegistrationBuffer."Payment Made" := true;
        TempPaymentRegistrationBuffer."Date Received" := WorkDate();
        TempPaymentRegistrationBuffer."Amount Received" := TempPaymentRegistrationBuffer."Remaining Amount";
        TempPaymentRegistrationBuffer.Modify();

        TempPaymentRegistrationBuffer.Reload();

        TempPaymentRegistrationBuffer.Get(EntryNo);

        Assert.IsTrue(TempPaymentRegistrationBuffer."Payment Made", StrSubstNo(ReloadErr, TempPaymentRegistrationBuffer.FieldName("Payment Made")));
        Assert.AreEqual(WorkDate(), TempPaymentRegistrationBuffer."Date Received", StrSubstNo(ReloadErr, TempPaymentRegistrationBuffer.FieldName("Date Received")));
        Assert.AreEqual(TempPaymentRegistrationBuffer."Remaining Amount", TempPaymentRegistrationBuffer."Amount Received", StrSubstNo(ReloadErr, TempPaymentRegistrationBuffer.FieldName("Amount Received")));

        TempPaymentRegistrationBuffer.SetRange("Payment Made", true);
        Assert.AreEqual(1, TempPaymentRegistrationBuffer.Count, ReloadCountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateReloadPersistFilter()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        EntryNo: Integer;
    begin
        Initialize();

        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);
        EntryNo := CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);

        TempPaymentRegistrationBuffer.PopulateTable();
        Assert.AreNotEqual(1, TempPaymentRegistrationBuffer.Count, ReloadCountErr);
        TempPaymentRegistrationBuffer.SetFilter("Ledger Entry No.", '%1', EntryNo);
        Assert.AreEqual(1, TempPaymentRegistrationBuffer.Count, ReloadCountErr);
        TempPaymentRegistrationBuffer.Reload();
        Assert.AreEqual(1, TempPaymentRegistrationBuffer.Count, ReloadCountErr);
        TempPaymentRegistrationBuffer.FindFirst();
        Assert.AreEqual(EntryNo, TempPaymentRegistrationBuffer."Ledger Entry No.", ReloadCountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateReloadPersistSorting()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        TempPaymentRegistrationBuffer.PopulateTable();
        TempPaymentRegistrationBuffer.SetCurrentKey("Amount Received");
        TempPaymentRegistrationBuffer.Reload();
        Assert.AreEqual('Amount Received', TempPaymentRegistrationBuffer.CurrentKey, ReloadSortingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateReloadPersistCurrRec()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PositionBeforeReload: Text;
    begin
        Initialize();

        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);
        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);

        TempPaymentRegistrationBuffer.PopulateTable();
        TempPaymentRegistrationBuffer.FindLast();
        PositionBeforeReload := TempPaymentRegistrationBuffer.GetPosition();
        TempPaymentRegistrationBuffer.Reload();
        Assert.AreEqual(PositionBeforeReload, TempPaymentRegistrationBuffer.GetPosition(), ReloadCurrRecErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateReloadIsGettingNewLines()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        EntryNo: Integer;
    begin
        Initialize();

        CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);
        TempPaymentRegistrationBuffer.PopulateTable();
        EntryNo := CreateCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, true);
        TempPaymentRegistrationBuffer.Reload();
        TempPaymentRegistrationBuffer.Get(EntryNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountReceivedIsSmallerThanRemainingAmount()
    var
        AmountReceived: Decimal;
        RemainingAmount: Decimal;
    begin
        Initialize();

        AmountReceived := LibraryRandom.RandDec(100, 2);
        RemainingAmount := AmountReceived + 1;

        VerifyAmountReceived(AmountReceived, RemainingAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountReceivedIsEqualToRemainingAmount()
    var
        AmountReceived: Decimal;
        RemainingAmount: Decimal;
    begin
        Initialize();

        AmountReceived := LibraryRandom.RandDec(100, 2);
        RemainingAmount := AmountReceived;

        VerifyAmountReceived(AmountReceived, RemainingAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAmountReceivedGreaterThanOrginalRemainingAmt()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        SetAutoFillDate();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);

        TempPaymentRegistrationBuffer.Validate("Amount Received", TempPaymentRegistrationBuffer."Original Remaining Amount" + LibraryRandom.RandDec(100, 2));
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAmountReceivedOutPmtDiscDateSmallerThanOriginalRemainingAmt()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        SetAutoFillDate();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);

        TempPaymentRegistrationBuffer."Pmt. Discount Date" := WorkDate() - LibraryRandom.RandInt(5);
        TempPaymentRegistrationBuffer.Validate("Amount Received",
          TempPaymentRegistrationBuffer."Original Remaining Amount" - LibraryRandom.RandDecInDecimalRange(0, TempPaymentRegistrationBuffer."Original Remaining Amount", 2));
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", TempPaymentRegistrationBuffer."Original Remaining Amount" - TempPaymentRegistrationBuffer."Amount Received");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAmountReceivedInPmtDiscDateGreaterThanDiscountedAmt()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        SetAutoFillDate();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);

        TempPaymentRegistrationBuffer."Pmt. Discount Date" := WorkDate() + LibraryRandom.RandInt(5);
        TempPaymentRegistrationBuffer.Validate("Amount Received", TempPaymentRegistrationBuffer."Rem. Amt. after Discount" + LibraryRandom.RandDec(10, 2));
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateAmountReceivedInPmtDiscDateSmallerThanDiscountedAmt()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        SetAutoFillDate();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);

        TempPaymentRegistrationBuffer."Pmt. Discount Date" := WorkDate() + LibraryRandom.RandInt(5);
        TempPaymentRegistrationBuffer.Validate("Amount Received",
          TempPaymentRegistrationBuffer."Rem. Amt. after Discount" - LibraryRandom.RandDecInDecimalRange(0, TempPaymentRegistrationBuffer."Rem. Amt. after Discount", 2));
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", TempPaymentRegistrationBuffer."Original Remaining Amount" - TempPaymentRegistrationBuffer."Amount Received");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateNegativeAmountReceivedGreaterThanNegativeOrginalRemainingAmt()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        SetAutoFillDate();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Remaining Amount" := -TempPaymentRegistrationBuffer."Remaining Amount";
        TempPaymentRegistrationBuffer."Original Remaining Amount" := -TempPaymentRegistrationBuffer."Original Remaining Amount";

        TempPaymentRegistrationBuffer.Validate("Amount Received", TempPaymentRegistrationBuffer."Remaining Amount" + LibraryRandom.RandDec(100, 2));
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", TempPaymentRegistrationBuffer."Original Remaining Amount" - TempPaymentRegistrationBuffer."Amount Received");
    end;

    local procedure VerifyAmountReceived(AmountReceived: Decimal; RemainingAmount: Decimal)
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        TempPaymentRegistrationBuffer."Remaining Amount" := RemainingAmount;
        TempPaymentRegistrationBuffer.Validate("Amount Received", AmountReceived);
        TempPaymentRegistrationBuffer.Insert();
        TempPaymentRegistrationBuffer.TestField("Payment Made", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDateReceivedEarlierThanPmtDiscDate()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);

        TempPaymentRegistrationBuffer."Pmt. Discount Date" := WorkDate();
        TempPaymentRegistrationBuffer.Validate("Date Received", TempPaymentRegistrationBuffer."Pmt. Discount Date" - LibraryRandom.RandInt(5));
        TempPaymentRegistrationBuffer.TestField("Payment Made", true);
        TempPaymentRegistrationBuffer.TestField("Amount Received", TempPaymentRegistrationBuffer."Rem. Amt. after Discount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateDateReceivedLaterThanPmtDiscDate()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Pmt. Discount Date" := WorkDate();
        TempPaymentRegistrationBuffer.Validate("Date Received", TempPaymentRegistrationBuffer."Pmt. Discount Date" + LibraryRandom.RandInt(5));
        TempPaymentRegistrationBuffer.TestField("Payment Made", true);
        TempPaymentRegistrationBuffer.TestField("Amount Received", TempPaymentRegistrationBuffer."Original Remaining Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePmtDiscDateAfterDateReceivedAmtReceivedGreaterThanOriginal()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        SetAutoFillDate();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);

        TempPaymentRegistrationBuffer."Amount Received" := TempPaymentRegistrationBuffer."Original Remaining Amount" + LibraryRandom.RandDec(100, 2);
        TempPaymentRegistrationBuffer.Validate("Pmt. Discount Date", TempPaymentRegistrationBuffer."Date Received" + LibraryRandom.RandInt(5));
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePmtDiscDateAfterDateReceivedAmountReceivedGreaterThanDiscounted()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        SetAutoFillDate();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);

        TempPaymentRegistrationBuffer."Amount Received" := TempPaymentRegistrationBuffer."Rem. Amt. after Discount" + LibraryRandom.RandDec(100, 2);
        TempPaymentRegistrationBuffer.Validate("Pmt. Discount Date", TempPaymentRegistrationBuffer."Date Received" + LibraryRandom.RandInt(5));
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePmtDiscDateAfterDateReceivedAmountSmallerThanDiscounted()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        SetAutoFillDate();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Amount Received" :=
  TempPaymentRegistrationBuffer."Rem. Amt. after Discount" - LibraryRandom.RandDecInDecimalRange(0, TempPaymentRegistrationBuffer."Rem. Amt. after Discount", 2);
        TempPaymentRegistrationBuffer.Validate("Pmt. Discount Date", TempPaymentRegistrationBuffer."Date Received" + LibraryRandom.RandInt(5));
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", TempPaymentRegistrationBuffer."Original Remaining Amount" - TempPaymentRegistrationBuffer."Amount Received");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidatePmtDiscDateBeforeDateReceivedAmtReceivedSmallerThanOriginal()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();

        SetAutoFillDate();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Amount Received" :=
          TempPaymentRegistrationBuffer."Original Remaining Amount" - LibraryRandom.RandDecInDecimalRange(0, TempPaymentRegistrationBuffer."Original Remaining Amount", 2);
        TempPaymentRegistrationBuffer.Validate("Pmt. Discount Date", TempPaymentRegistrationBuffer."Date Received" - LibraryRandom.RandInt(5));
        TempPaymentRegistrationBuffer.TestField("Remaining Amount", TempPaymentRegistrationBuffer."Original Remaining Amount" - TempPaymentRegistrationBuffer."Amount Received");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscStyle()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Pmt. Discount Date" := TempPaymentRegistrationBuffer."Date Received" - LibraryRandom.RandInt(5);
        TempPaymentRegistrationBuffer."Due Date" := TempPaymentRegistrationBuffer."Date Received" + LibraryRandom.RandInt(5);
        Assert.AreEqual(TempPaymentRegistrationBuffer.GetPmtDiscStyle(), 'Unfavorable', StyleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateStyle()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Due Date" := TempPaymentRegistrationBuffer."Date Received" - LibraryRandom.RandInt(5);
        Assert.AreEqual(TempPaymentRegistrationBuffer.GetDueDateStyle(), 'Unfavorable', StyleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetWarningTextEmpty()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Pmt. Discount Date" := TempPaymentRegistrationBuffer."Date Received" + LibraryRandom.RandInt(5);
        Assert.AreEqual(TempPaymentRegistrationBuffer.GetWarning(), '', WarningErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetWarningTextDueDate()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Date Received" := TempPaymentRegistrationBuffer."Pmt. Discount Date" + LibraryRandom.RandInt(5);
        Assert.AreEqual(TempPaymentRegistrationBuffer.GetWarning(), Format(DueDateMsg), WarningErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetWarningTextPmtDiscTxt()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Date Received" := TempPaymentRegistrationBuffer."Pmt. Discount Date" + LibraryRandom.RandInt(5);
        TempPaymentRegistrationBuffer."Due Date" := TempPaymentRegistrationBuffer."Date Received" + LibraryRandom.RandInt(5);
        Assert.AreEqual(TempPaymentRegistrationBuffer.GetWarning(), Format(PmtDiscMsg), WarningErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetWarningTextEmptyDateReceivedEarlierThanDueDate()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
    begin
        Initialize();
        InsertTempPaymentRegistrationBuffer(TempPaymentRegistrationBuffer);
        TempPaymentRegistrationBuffer."Date Received" := TempPaymentRegistrationBuffer."Pmt. Discount Date" + LibraryRandom.RandInt(5);
        TempPaymentRegistrationBuffer."Due Date" := TempPaymentRegistrationBuffer."Date Received" + LibraryRandom.RandInt(5);
        TempPaymentRegistrationBuffer."Remaining Amount" := 0;
        Assert.AreEqual(TempPaymentRegistrationBuffer.GetWarning(), '', WarningErr);
    end;

    [Test]
    [HandlerFunctions('PaymentRegistrationSetupCancelPageHandler')]
    [Scope('OnPrem')]
    procedure RunFirstSetup()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        PmtReg: TestPage "Payment Registration";
    begin
        PaymentRegistrationSetup.DeleteAll();

        // Expect transaction to stop because cancel is pressed
        asserterror PmtReg.OpenEdit();
        asserterror PmtReg.OK().Invoke();
        Assert.ExpectedError('The TestPage is not open.');
    end;

    [Test]
    [HandlerFunctions('PaymentRegistrationPromptOKPageHandler')]
    [Scope('OnPrem')]
    procedure RunNextSetupWithPrompt()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        PmtReg: TestPage "Payment Registration";
    begin
        Initialize();

        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Use this Account as Def." := false;
        PaymentRegistrationSetup.Modify();
        LibraryVariableStorage.Enqueue(UserId);

        PrepareDefaultSetup();

        // HandlerFunctions has a verification.
        PmtReg.OpenEdit();
        PmtReg.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunNextSetupWithNoPrompt()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        PmtReg: TestPage "Payment Registration";
    begin
        Initialize();

        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Use this Account as Def." := true;
        PaymentRegistrationSetup.Modify();

        PrepareDefaultSetup();

        PmtReg.OpenEdit();
        PmtReg.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConfirmCloseNoneMarkedAsPaid()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        TempPaymentRegistrationBuffer."Ledger Entry No." := 1;
        TempPaymentRegistrationBuffer."Payment Made" := false;
        TempPaymentRegistrationBuffer.Insert();
        Assert.IsTrue(PaymentRegistrationMgt.ConfirmClose(TempPaymentRegistrationBuffer), ConfirmCloseExpectedTrueErr);
    end;

    [Test]
    [HandlerFunctions('HandlerConfirmYes')]
    [Scope('OnPrem')]
    procedure ConfirmCloseSomeMarkedAsPaidYes()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        TempPaymentRegistrationBuffer."Ledger Entry No." := 1;
        TempPaymentRegistrationBuffer."Payment Made" := true;
        TempPaymentRegistrationBuffer.Insert();
        Assert.IsTrue(PaymentRegistrationMgt.ConfirmClose(TempPaymentRegistrationBuffer), ConfirmCloseExpectedTrueErr);
    end;

    [Test]
    [HandlerFunctions('HandlerConfirmNo')]
    [Scope('OnPrem')]
    procedure ConfirmCloseSomeMarkedAsPaidNo()
    var
        TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary;
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        TempPaymentRegistrationBuffer."Ledger Entry No." := 1;
        TempPaymentRegistrationBuffer."Payment Made" := true;
        TempPaymentRegistrationBuffer.Insert();
        Assert.IsFalse(PaymentRegistrationMgt.ConfirmClose(TempPaymentRegistrationBuffer), ConfirmCloseExpectedTrueErr);
    end;

    [Test]
    [HandlerFunctions('ReminderPageHandler')]
    [Scope('OnPrem')]
    procedure SearchReminderByDocNoShowResults()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ReminderHeader: Record "Reminder Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupReminder(ReminderHeader);
        LibraryVariableStorage.Enqueue(ReminderHeader."No.");

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, ReminderHeader."No.", 0, 0);

        // Verify. Show results validated in Reminder page handler.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, ReminderHeader."No.",
          ReminderHeader."Remaining Amount", DATABASE::"Reminder Header");

        PaymentRegistrationMgt.ShowRecords(TempDocumentSearchResult);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchReminderByRemaningAmount()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ReminderHeader: Record "Reminder Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupReminder(ReminderHeader);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, '', ReminderHeader."Remaining Amount", 0);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, ReminderHeader."No.",
          ReminderHeader."Remaining Amount", DATABASE::"Reminder Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchReminderByInterestAmount()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ReminderHeader: Record "Reminder Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupReminder(ReminderHeader);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, '', ReminderHeader."Interest Amount", 0);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, ReminderHeader."No.",
          ReminderHeader."Remaining Amount", DATABASE::"Reminder Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchReminderByDocNoAndAmount()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ReminderHeader: Record "Reminder Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupReminder(ReminderHeader);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, ReminderHeader."No.", ReminderHeader."Remaining Amount", 0);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, ReminderHeader."No.",
          ReminderHeader."Remaining Amount", DATABASE::"Reminder Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchReminderWithTolerance()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ReminderHeader: Record "Reminder Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        TolerancePct: Decimal;
    begin
        Initialize();

        // Setup.
        SetupReminder(ReminderHeader);

        // Exercise: Find values within tolerance, using a reference amount above the actual document amount.
        TolerancePct := LibraryRandom.RandInt(10);
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, '',
          (1 + TolerancePct / 100) * ReminderHeader."Remaining Amount", TolerancePct);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, ReminderHeader."No.",
          ReminderHeader."Remaining Amount", DATABASE::"Reminder Header");

        // Exercise: Find values within tolerance, using a reference amount below the actual document amount.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, '',
          (1 - (TolerancePct / 100) * (1 - TolerancePct / 100)) * ReminderHeader."Remaining Amount", TolerancePct);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, ReminderHeader."No.",
          ReminderHeader."Remaining Amount", DATABASE::"Reminder Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchReminderNegative()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ReminderHeader: Record "Reminder Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupReminder(ReminderHeader);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, '', 0.5 * ReminderHeader."Remaining Amount", 10);

        // Verify.
        asserterror VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, ReminderHeader."No.",
            ReminderHeader."Remaining Amount", DATABASE::"Reminder Header");
    end;

    [Test]
    [HandlerFunctions('FinChargeMemoPageHandler')]
    [Scope('OnPrem')]
    procedure SearchFinanceChargeMemoByDocNoShowResults()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupFinanceChargeMemo(FinanceChargeMemoHeader);
        LibraryVariableStorage.Enqueue(FinanceChargeMemoHeader."No.");

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, FinanceChargeMemoHeader."No.", 0, 0);

        // Verify. Show results validated in page handler.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, FinanceChargeMemoHeader."No.",
          FinanceChargeMemoHeader."Remaining Amount", DATABASE::"Finance Charge Memo Header");

        PaymentRegistrationMgt.ShowRecords(TempDocumentSearchResult);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchFinanceChargeMemoByAmount()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupFinanceChargeMemo(FinanceChargeMemoHeader);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, '', FinanceChargeMemoHeader."Remaining Amount", 0);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, FinanceChargeMemoHeader."No.",
          FinanceChargeMemoHeader."Remaining Amount", DATABASE::"Finance Charge Memo Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchFinanceChargeMemoByDocNoAndAmount()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupFinanceChargeMemo(FinanceChargeMemoHeader);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, FinanceChargeMemoHeader."No.",
          FinanceChargeMemoHeader."Remaining Amount", 0);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, FinanceChargeMemoHeader."No.",
          FinanceChargeMemoHeader."Remaining Amount", DATABASE::"Finance Charge Memo Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchFinanceChargeMemoWithTolerance()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        TolerancePct: Decimal;
    begin
        Initialize();

        // Setup.
        SetupFinanceChargeMemo(FinanceChargeMemoHeader);

        // Exercise: Find values within tolerance, using a reference amount above the actual document amount.
        TolerancePct := LibraryRandom.RandInt(10);
        PaymentRegistrationMgt.FindRecords(
          TempDocumentSearchResult, FinanceChargeMemoHeader."No.",
          (1 + TolerancePct / 100) * FinanceChargeMemoHeader."Remaining Amount", TolerancePct);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, FinanceChargeMemoHeader."No.",
          FinanceChargeMemoHeader."Remaining Amount", DATABASE::"Finance Charge Memo Header");

        // Exercise: Find values within tolerance, using a reference amount below the actual document amount.
        PaymentRegistrationMgt.FindRecords(
          TempDocumentSearchResult, FinanceChargeMemoHeader."No.",
          (1 - (TolerancePct / 100) * (1 - TolerancePct / 100)) * FinanceChargeMemoHeader."Remaining Amount", TolerancePct);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, FinanceChargeMemoHeader."No.",
          FinanceChargeMemoHeader."Remaining Amount", DATABASE::"Finance Charge Memo Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchFinanceChargeMemoNegative()
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupFinanceChargeMemo(FinanceChargeMemoHeader);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(
          TempDocumentSearchResult, FinanceChargeMemoHeader."No.", 0.5 * FinanceChargeMemoHeader."Remaining Amount", 10);

        // Verify.
        asserterror VerifyDocumentSearchResult(TempDocumentSearchResult, "Service Document Type"::Quote, FinanceChargeMemoHeader."No.",
            FinanceChargeMemoHeader."Remaining Amount", DATABASE::"Finance Charge Memo Header");
    end;

    [Test]
    [HandlerFunctions('SalesOrderPageHandler')]
    [Scope('OnPrem')]
    procedure SearchSalesOrderByDocNoShowResults()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoShowResults(SalesHeader."Document Type"::Order, SalesOrderTxt);
    end;

    [Test]
    [HandlerFunctions('SalesInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure SearchSalesInvoiceByDocNoShowResults()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoShowResults(SalesHeader."Document Type"::Invoice, SalesInvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('SalesReturnOrderPageHandler')]
    [Scope('OnPrem')]
    procedure SearchSalesReturnOrderByDocNoShowResults()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoShowResults(SalesHeader."Document Type"::"Return Order", SalesReturnOrderTxt);
    end;

    [Test]
    [HandlerFunctions('SalesQuotePageHandler')]
    [Scope('OnPrem')]
    procedure SearchSalesQuoteByDocNoShowResults()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoShowResults(SalesHeader."Document Type"::Quote, SalesQuoteTxt);
    end;

    [Test]
    [HandlerFunctions('SalesBlanketOrderPageHandler')]
    [Scope('OnPrem')]
    procedure SearchSalesBlanketOrderByDocNoShowResults()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoShowResults(SalesHeader."Document Type"::"Blanket Order", SalesBlanketOrderTxt);
    end;

    [Test]
    [HandlerFunctions('SalesCrMemoPageHandler')]
    [Scope('OnPrem')]
    procedure SearchSalesCrMemoByDocNoShowResults()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoShowResults(SalesHeader."Document Type"::"Credit Memo", SalesCreditMemoTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesOrderByAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByAmount(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesInvoiceByAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByAmount(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesReturnOrderByAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByAmount(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesQuoteByAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByAmount(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesCrMemoByAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByAmount(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesOrderByDocNoAndAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoAndAmount(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesInvoiceByDocNoAndAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoAndAmount(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesReturnOrderByDocNoAndAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoAndAmount(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesQuoteByDocNoAndAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoAndAmount(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesCrMemoByDocNoAndAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderByDocNoAndAmount(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesOrderWithTolerance()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderWithTolerance(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesInvoiceWithTolerance()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderWithTolerance(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesReturnOrderWithTolerance()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderWithTolerance(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesQuoteWithTolerance()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderWithTolerance(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesCrMemoWithTolerance()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderWithTolerance(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesOrderNegative()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderNegative(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesInvoiceNegative()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderNegative(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesReturnOrderNegative()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderNegative(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesQuoteNegative()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderNegative(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchSalesCrMemoNegative()
    var
        SalesHeader: Record "Sales Header";
    begin
        SearchSalesHeaderNegative(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ServiceOrderPageHandler')]
    [Scope('OnPrem')]
    procedure SearchServiceOrderByDocNoShowResults()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByDocNoShowResults(ServiceHeader."Document Type"::Order, ServiceOrderTxt);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoicePageHandler')]
    [Scope('OnPrem')]
    procedure SearchServiceInvoiceByDocNoShowResults()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByDocNoShowResults(ServiceHeader."Document Type"::Invoice, ServiceInvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('ServiceQuotePageHandler')]
    [Scope('OnPrem')]
    procedure SearchServiceQuoteByDocNoShowResults()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByDocNoShowResults(ServiceHeader."Document Type"::Quote, ServiceQuoteTxt);
    end;

    [Test]
    [HandlerFunctions('ServiceCrMemoPageHandler')]
    [Scope('OnPrem')]
    procedure SearchServiceCrMemoByDocNoShowResults()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByDocNoShowResults(ServiceHeader."Document Type"::"Credit Memo", ServiceCreditMemoTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceOrderByAmount()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByAmount(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceInvoiceByAmount()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByAmount(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceQuoteByAmount()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByAmount(ServiceHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceCrMemoByAmount()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByAmount(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceOrderByDocNoAndAmount()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByDocNoAndAmount(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceInvoiceByDocNoAndAmount()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByDocNoAndAmount(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceQuoteByDocNoAndAmount()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByDocNoAndAmount(ServiceHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceCrMemoByDocNoAndAmount()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderByDocNoAndAmount(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceOrderWithTolerance()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderWithTolerance(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceInvoiceWithTolerance()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderWithTolerance(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceQuoteWithTolerance()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderWithTolerance(ServiceHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceCrMemoWithTolerance()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderWithTolerance(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceOrderNegative()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderNegative(ServiceHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceInvoiceNegative()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderNegative(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceQuoteNegative()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderNegative(ServiceHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SearchServiceCrMemoNegative()
    var
        ServiceHeader: Record "Service Header";
    begin
        SearchServiceHeaderNegative(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetToleranceAndAmount()
    var
        DocumentSearch: TestPage "Document Search";
        Tolerance: Decimal;
    begin
        Initialize();

        // Setup.
        Tolerance := LibraryRandom.RandDec(100, 2);
        DocumentSearch.OpenEdit();

        // Exercise.
        DocumentSearch.Amount.SetValue(LibraryRandom.RandDec(100, 2));
        DocumentSearch.AmountTolerance.SetValue(Tolerance);

        // Verify.
        DocumentSearch.Warning.AssertEquals(
          StrSubstNo(ToleranceTxt, Format((1 - Tolerance / 100) * DocumentSearch.Amount.AsDecimal(), 0, '<Precision,2><Standard Format,0>'),
            Format((1 + Tolerance / 100) * DocumentSearch.Amount.AsDecimal(), 0, '<Precision,2><Standard Format,0>')));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnsetTolerance()
    var
        DocumentSearch: TestPage "Document Search";
    begin
        Initialize();

        // Setup.
        DocumentSearch.OpenEdit();
        DocumentSearch.Amount.SetValue(LibraryRandom.RandDec(100, 2));

        // Exercise.
        DocumentSearch.AmountTolerance.SetValue(LibraryRandom.RandDec(100, 2));
        DocumentSearch.AmountTolerance.SetValue('');

        // Verify.
        DocumentSearch.Warning.AssertEquals('');
    end;

    [Normal]
    local procedure SetToleranceBoundaries(Tolerance: Decimal)
    var
        DocumentSearch: TestPage "Document Search";
    begin
        Initialize();

        // Setup.
        DocumentSearch.OpenEdit();

        // Exercise / Verify.
        if (Tolerance < 0) or (Tolerance > 100) then
            asserterror DocumentSearch.AmountTolerance.SetValue(Tolerance)
        else begin
            DocumentSearch.AmountTolerance.SetValue(Tolerance);
            DocumentSearch.Warning.AssertEquals('');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetToleranceBelow0()
    begin
        SetToleranceBoundaries(-LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetToleranceAbove100()
    begin
        SetToleranceBoundaries(LibraryRandom.RandDecInRange(101, 200, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetToleranceTo0()
    begin
        SetToleranceBoundaries(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetToleranceTo100()
    begin
        SetToleranceBoundaries(100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetToleranceWithinRange()
    begin
        SetToleranceBoundaries(LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccountBalance()
    var
        GLEntry: Record "G/L Entry";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        PostedAmount: Decimal;
        UnpostedAmount: Decimal;
        ActualPosted: Decimal;
        ActualUnposted: Decimal;
    begin
        Initialize();

        // Setup
        PostedAmount := LibraryRandom.RandDec(100, 2);
        UnpostedAmount := LibraryRandom.RandDec(100, 2);

        SetPaymentRegistrationSetup(PaymentRegistrationSetup."Bal. Account Type"::"G/L Account");
        PaymentRegistrationSetup.Get(UserId);

        // Exercise
        CreateGLEntry(GLEntry, PaymentRegistrationSetup."Bal. Account No.", PostedAmount);
        CreateGnlJnlLine(GenJnlLine, PaymentRegistrationSetup, UnpostedAmount);

        PaymentRegistrationMgt.CalculateBalance(ActualPosted, ActualUnposted);

        // Verify
        Assert.AreEqual(PostedAmount, ActualPosted, '');
        Assert.AreEqual(UnpostedAmount, ActualUnposted, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountBalance()
    var
        BankAccLedgerEntry: Record "Bank Account Ledger Entry";
        PaymentRegistrationSetup: Record "Payment Registration Setup";
        GenJnlLine: Record "Gen. Journal Line";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        PostedAmount: Decimal;
        UnpostedAmount: Decimal;
        ActualPosted: Decimal;
        ActualUnposted: Decimal;
    begin
        Initialize();

        // Setup
        PostedAmount := LibraryRandom.RandDec(100, 2);
        UnpostedAmount := LibraryRandom.RandDec(100, 2);

        SetPaymentRegistrationSetup(PaymentRegistrationSetup."Bal. Account Type"::"Bank Account");
        PaymentRegistrationSetup.Get(UserId);

        // Exercise
        CreateBankAccLedgerEntry(BankAccLedgerEntry, PaymentRegistrationSetup."Bal. Account No.", PostedAmount);
        CreateGnlJnlLine(GenJnlLine, PaymentRegistrationSetup, UnpostedAmount);

        PaymentRegistrationMgt.CalculateBalance(ActualPosted, ActualUnposted);

        // Verify
        Assert.AreEqual(PostedAmount, ActualPosted, '');
        Assert.AreEqual(UnpostedAmount, ActualUnposted, '');
    end;

    local procedure Initialize()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Payment Registration UT");
        SetPaymentRegistrationSetup(PaymentRegistrationSetup."Bal. Account Type"::"Bank Account");
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Payment Registration UT");
        MaxPaymentDiscountAmount := 50;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Payment Registration UT");
    end;

    [Normal]
    local procedure CalcServiceAmmount(ServiceNo: Code[20]) ServiceTotal: Decimal
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetFilter("Document No.", ServiceNo);
        ServiceTotal := 0;
        if ServiceLine.FindSet() then
            repeat
                ServiceTotal := ServiceTotal + ServiceLine."Amount Including VAT";
            until ServiceLine.Next() = 0;
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Init();
        BankAccount."No." := LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("No."), DATABASE::"Bank Account");
        BankAccount.Insert();
        exit(BankAccount."No.")
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; IsOpen: Boolean): Integer
    begin
        if CustLedgerEntry.FindLast() then;
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." += 1;
        CustLedgerEntry."Customer No." := CreateCustomer();
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry.Open := IsOpen;
        if IsOpen then
            CustLedgerEntry."Remaining Amount" := LibraryRandom.RandDec(100, 2);
        CustLedgerEntry."Document No." :=
            LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo("Document No."), DATABASE::"Cust. Ledger Entry");
        CustLedgerEntry.Description :=
            LibraryUtility.GenerateRandomCode(CustLedgerEntry.FieldNo(Description), DATABASE::"Cust. Ledger Entry");
        CustLedgerEntry."Due Date" := LibraryUtility.GenerateRandomDate(WorkDate(), WorkDate() + LibraryRandom.RandInt(10));
        CustLedgerEntry."Remaining Pmt. Disc. Possible" := LibraryRandom.RandDec(MaxPaymentDiscountAmount, 2);
        CustLedgerEntry."Pmt. Discount Date" :=
            LibraryUtility.GenerateRandomDate(WorkDate() - LibraryRandom.RandInt(10), WorkDate());
        CustLedgerEntry.Insert();

        exit(CustLedgerEntry."Entry No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer);
        Customer.Name := LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer);
        Customer.Insert();
        exit(Customer."No.")
    end;

    local procedure CreateDetailedCustomerLedgerEntry(EntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Cust. Ledger Entry No." := EntryNo;
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDecInRange(MaxPaymentDiscountAmount, 100, 2);
        DetailedCustLedgEntry.Insert();
    end;

    local procedure CreateGenJournalBatch(TemplateName: Code[10]): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Init();
        GenJournalBatch."Journal Template Name" := TemplateName;
        GenJournalBatch.Name := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        GenJournalBatch."No. Series" :=
          LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo("No. Series"), DATABASE::"Gen. Journal Batch");
        GenJournalBatch.Insert();
        exit(GenJournalBatch.Name);
    end;

    local procedure CreateGenJournalTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Init();
        GenJournalTemplate.Name := LibraryUtility.GenerateRandomCode(GenJournalTemplate.FieldNo(Name), DATABASE::"Gen. Journal Template");
        GenJournalTemplate.Insert();
        exit(GenJournalTemplate.Name);
    end;

    local procedure CreateGnlJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PaymentRegistrationSetup: Record "Payment Registration Setup"; Amount: Decimal)
    begin
        GenJnlLine."Journal Template Name" := CreateGenJournalTemplate();
        GenJnlLine."Journal Batch Name" := CreateGenJournalBatch(GenJnlLine."Journal Template Name");

        case PaymentRegistrationSetup."Bal. Account Type" of
            PaymentRegistrationSetup."Bal. Account Type"::"Bank Account":
                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"Bank Account";
            PaymentRegistrationSetup."Bal. Account Type"::"G/L Account":
                GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        end;
        GenJnlLine."Bal. Account No." := PaymentRegistrationSetup."Bal. Account No.";
        GenJnlLine.Amount := Amount;
        GenJnlLine.Insert();
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; BalAccNo: Code[20]; Amount: Decimal)
    var
        EntryNo: Integer;
    begin
        GLEntry.FindLast();
        EntryNo := GLEntry."Entry No.";
        GLEntry.Init();
        GLEntry."Entry No." := EntryNo + 1;
        GLEntry."G/L Account No." := BalAccNo;
        GLEntry.Amount := Amount;
        GLEntry.Insert();
    end;

    local procedure CreateBankAccLedgerEntry(var BankAccLedgerEntry: Record "Bank Account Ledger Entry"; BalAccNo: Code[20]; Amount: Decimal)
    var
        EntryNo: Integer;
    begin
        BankAccLedgerEntry.FindLast();
        EntryNo := BankAccLedgerEntry."Entry No.";
        BankAccLedgerEntry.Init();
        BankAccLedgerEntry."Entry No." := EntryNo + 1;
        BankAccLedgerEntry."Bank Account No." := BalAccNo;
        BankAccLedgerEntry.Amount := Amount;
        BankAccLedgerEntry.Insert();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteDefaultSetup()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        if PaymentRegistrationSetup.Get() then
            PaymentRegistrationSetup.Delete();
    end;

    local procedure SetPaymentRegistrationSetup(AccountType: Option)
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.DeleteAll();
        PaymentRegistrationSetup.Init();
        PaymentRegistrationSetup."User ID" := UserId;
        case AccountType of
            PaymentRegistrationSetup."Bal. Account Type"::"Bank Account":
                PaymentRegistrationSetup."Bal. Account No." := CreateBankAccount();
            PaymentRegistrationSetup."Bal. Account Type"::"G/L Account":
                PaymentRegistrationSetup."Bal. Account No." := LibraryERM.CreateGLAccountNo();
        end;
        PaymentRegistrationSetup."Bal. Account Type" := AccountType;
        PaymentRegistrationSetup."Journal Template Name" := CreateGenJournalTemplate();
        PaymentRegistrationSetup."Journal Batch Name" := CreateGenJournalBatch(PaymentRegistrationSetup."Journal Template Name");
        PaymentRegistrationSetup."Auto Fill Date Received" := false;
        PaymentRegistrationSetup."Use this Account as Def." := true;
        PaymentRegistrationSetup.Insert();
    end;

    local procedure SetAutoFillDate()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetup.Get(UserId);
        PaymentRegistrationSetup."Auto Fill Date Received" := true;
        PaymentRegistrationSetup.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentRegistrationSetupCancelPageHandler(var PaymentRegistrationSetupPage: TestPage "Payment Registration Setup")
    begin
        PaymentRegistrationSetupPage.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentRegistrationSetupOKPageHandler(var PaymentRegistrationSetupPage: TestPage "Payment Registration Setup")
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        PaymentRegistrationSetupPage."Bal. Account Type".SetValue(PaymentRegistrationSetup."Bal. Account Type"::"G/L Account");
        PaymentRegistrationSetupPage."Bal. Account No.".SetValue(LibraryERM.CreateGLAccountNo());
        PaymentRegistrationSetupPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentRegistrationPromptOKPageHandler(var PaymentRegistrationPromptPage: TestPage "Balancing Account Setup")
    begin
        Assert.AreEqual(UpperCase(UserId), LibraryVariableStorage.DequeueText(), WrongUserErr);

        PaymentRegistrationPromptPage.OK().Invoke();
    end;

    local procedure PrepareDefaultSetup()
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        if not PaymentRegistrationSetup.Get() then begin
            PaymentRegistrationSetup."User ID" := '';
            PaymentRegistrationSetup.Insert();
        end;

        PaymentRegistrationSetup."Bal. Account No." := '';
        PaymentRegistrationSetup."Use this Account as Def." := false;
        PaymentRegistrationSetup.Modify();
    end;

    local procedure InsertTempPaymentRegistrationBuffer(var TempPaymentRegistrationBuffer: Record "Payment Registration Buffer" temporary)
    begin
        TempPaymentRegistrationBuffer.Init();
        TempPaymentRegistrationBuffer."Date Received" := WorkDate();
        TempPaymentRegistrationBuffer."Due Date" := WorkDate();
        TempPaymentRegistrationBuffer."Pmt. Discount Date" := WorkDate();
        TempPaymentRegistrationBuffer."Rem. Amt. after Discount" := LibraryRandom.RandDec(100, 2);
        TempPaymentRegistrationBuffer."Remaining Amount" := TempPaymentRegistrationBuffer."Rem. Amt. after Discount" + LibraryRandom.RandDec(100, 2);
        TempPaymentRegistrationBuffer."Original Remaining Amount" := TempPaymentRegistrationBuffer."Remaining Amount";
        TempPaymentRegistrationBuffer.Insert();
    end;

    [Normal]
    local procedure SearchSalesHeaderByDocNoShowResults(DocumentType: Enum "Sales Document Type"; Description: Text)
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        SalesHeader: Record "Sales Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupSalesHeader(SalesHeader, DocumentType);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, SalesHeader."No.", 0, 0);

        // Verify. Show results is validated in the page handler.
        VerifyDocumentSearchResult(TempDocumentSearchResult, SalesHeader."Document Type", SalesHeader."No.",
          SalesHeader."Amount Including VAT", DATABASE::"Sales Header");
        TempDocumentSearchResult.TestField(Description, Description);

        PaymentRegistrationMgt.ShowRecords(TempDocumentSearchResult);
    end;

    [Normal]
    local procedure SearchSalesHeaderByDocNoAndAmount(DocumentType: Enum "Sales Document Type")
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        SalesHeader: Record "Sales Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupSalesHeader(SalesHeader, DocumentType);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, SalesHeader."No.", SalesHeader."Amount Including VAT", 0);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, SalesHeader."Document Type", SalesHeader."No.",
          SalesHeader."Amount Including VAT", DATABASE::"Sales Header");
    end;

    [Normal]
    local procedure SearchSalesHeaderByAmount(DocumentType: Enum "Sales Document Type")
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        SalesHeader: Record "Sales Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupSalesHeader(SalesHeader, DocumentType);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, '', SalesHeader."Amount Including VAT", 0);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, SalesHeader."Document Type", SalesHeader."No.",
          SalesHeader."Amount Including VAT", DATABASE::"Sales Header");
    end;

    [Normal]
    local procedure SearchSalesHeaderWithTolerance(DocumentType: Enum "Sales Document Type")
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        SalesHeader: Record "Sales Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        TolerancePct: Decimal;
    begin
        Initialize();

        // Setup.
        SetupSalesHeader(SalesHeader, DocumentType);

        // Exercise: Find values within tolerance, using a reference amount above the actual document amount.
        TolerancePct := LibraryRandom.RandInt(10);
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, SalesHeader."No.",
          (1 + TolerancePct / 100) * SalesHeader."Amount Including VAT", TolerancePct);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, SalesHeader."Document Type", SalesHeader."No.",
          SalesHeader."Amount Including VAT", DATABASE::"Sales Header");

        // Exercise: Find values within tolerance, using a reference amount below the actual document amount.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, SalesHeader."No.",
          (1 - (TolerancePct / 100) * (1 - TolerancePct / 100)) * SalesHeader."Amount Including VAT", TolerancePct);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, SalesHeader."Document Type", SalesHeader."No.",
          SalesHeader."Amount Including VAT", DATABASE::"Sales Header");
    end;

    [Normal]
    local procedure SearchSalesHeaderNegative(DocumentType: Enum "Sales Document Type")
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        SalesHeader: Record "Sales Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupSalesHeader(SalesHeader, DocumentType);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, SalesHeader."No.", 0.5 * SalesHeader."Amount Including VAT", 0);

        // Verify.
        asserterror VerifyDocumentSearchResult(TempDocumentSearchResult, SalesHeader."Document Type", SalesHeader."No.",
            SalesHeader."Amount Including VAT", DATABASE::"Sales Header");
    end;

    [Normal]
    local procedure SearchServiceHeaderByDocNoShowResults(DocumentType: Enum "Service Document Type"; Description: Text)
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ServiceHeader: Record "Service Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupServiceHeader(ServiceHeader, DocumentType);
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, ServiceHeader."No.", 0, 0);

        // Verify. Show result is validated in the handler page.
        VerifyDocumentSearchResult(TempDocumentSearchResult, ServiceHeader."Document Type", ServiceHeader."No.",
          CalcServiceAmmount(ServiceHeader."No."), DATABASE::"Service Header");
        TempDocumentSearchResult.TestField(Description, Description);

        PaymentRegistrationMgt.ShowRecords(TempDocumentSearchResult);
    end;

    [Normal]
    local procedure SearchServiceHeaderByDocNoAndAmount(DocumentType: Enum "Service Document Type")
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ServiceHeader: Record "Service Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupServiceHeader(ServiceHeader, DocumentType);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, ServiceHeader."No.", CalcServiceAmmount(ServiceHeader."No."), 0);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, ServiceHeader."Document Type", ServiceHeader."No.",
          CalcServiceAmmount(ServiceHeader."No."), DATABASE::"Service Header");
    end;

    [Normal]
    local procedure SearchServiceHeaderByAmount(DocumentType: Enum "Service Document Type")
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ServiceHeader: Record "Service Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupServiceHeader(ServiceHeader, DocumentType);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, '', CalcServiceAmmount(ServiceHeader."No."), 0);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, ServiceHeader."Document Type", ServiceHeader."No.",
          CalcServiceAmmount(ServiceHeader."No."), DATABASE::"Service Header");
    end;

    [Normal]
    local procedure SearchServiceHeaderWithTolerance(DocumentType: Enum "Service Document Type")
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ServiceHeader: Record "Service Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
        TolerancePct: Decimal;
    begin
        Initialize();

        // Setup.
        SetupServiceHeader(ServiceHeader, DocumentType);

        // Exercise: Find values within tolerance, using a reference amount above the actual document amount.
        TolerancePct := LibraryRandom.RandInt(10);
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, ServiceHeader."No.",
          (1 + TolerancePct / 100) * CalcServiceAmmount(ServiceHeader."No."), 15);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, ServiceHeader."Document Type", ServiceHeader."No.",
          CalcServiceAmmount(ServiceHeader."No."), DATABASE::"Service Header");

        // Exercise: Find values within tolerance, using a reference amount below the actual document amount.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, ServiceHeader."No.",
          (1 - (TolerancePct / 100) * (1 - TolerancePct / 100)) * CalcServiceAmmount(ServiceHeader."No."), 15);

        // Verify.
        VerifyDocumentSearchResult(TempDocumentSearchResult, ServiceHeader."Document Type", ServiceHeader."No.",
          CalcServiceAmmount(ServiceHeader."No."), DATABASE::"Service Header");
    end;

    [Normal]
    local procedure SearchServiceHeaderNegative(DocumentType: Enum "Service Document Type")
    var
        TempDocumentSearchResult: Record "Document Search Result" temporary;
        ServiceHeader: Record "Service Header";
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
    begin
        Initialize();

        // Setup.
        SetupServiceHeader(ServiceHeader, DocumentType);

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, ServiceHeader."No.", 0.5 * CalcServiceAmmount(ServiceHeader."No."), 0);

        // Verify.
        asserterror VerifyDocumentSearchResult(TempDocumentSearchResult, ServiceHeader."Document Type", ServiceHeader."No.",
            CalcServiceAmmount(ServiceHeader."No."), DATABASE::"Service Header");

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, ServiceHeader."No." + 'K', CalcServiceAmmount(ServiceHeader."No."), 0);

        // Verify.
        asserterror VerifyDocumentSearchResult(TempDocumentSearchResult, ServiceHeader."Document Type", ServiceHeader."No.",
            CalcServiceAmmount(ServiceHeader."No."), DATABASE::"Service Header");

        // Exercise.
        PaymentRegistrationMgt.FindRecords(TempDocumentSearchResult, ServiceHeader."No.", CalcServiceAmmount(ServiceHeader."No.") + 0.1, 0);

        // Verify.
        asserterror VerifyDocumentSearchResult(TempDocumentSearchResult, ServiceHeader."Document Type", ServiceHeader."No.",
            CalcServiceAmmount(ServiceHeader."No."), DATABASE::"Service Header");
    end;

    [Normal]
    local procedure SetupReminder(var ReminderHeader: Record "Reminder Header")
    var
        Customer: Record Customer;
        ReminderLine: Record "Reminder Line";
        Amount: Decimal;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", Customer."No.");
        ReminderHeader.Modify(true);
        LibraryERM.CreateReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"G/L Account");
        Amount := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        ReminderLine.Validate("Remaining Amount", Amount);
        ReminderLine.Validate(Amount, Amount);
        ReminderLine.Modify(true);
        ReminderHeader.CalcFields("Remaining Amount", "Interest Amount");
    end;

    [Normal]
    local procedure SetupFinanceChargeMemo(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        Customer: Record Customer;
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        FinanceChargeTerms: Record "Finance Charge Terms";
        Amount: Decimal;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, Customer."No.");
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeMemoHeader.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        FinanceChargeMemoHeader.Modify(true);
        LibraryERM.CreateFinanceChargeMemoLine(
          FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::"G/L Account");
        Amount := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        FinanceChargeMemoLine.Validate("Remaining Amount", Amount);
        FinanceChargeMemoLine.Validate(Amount, Amount);
        FinanceChargeMemoLine.Modify(true);
        FinanceChargeMemoHeader.CalcFields("Remaining Amount", "Interest Amount");
    end;

    [Normal]
    local procedure SetupSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInDecimalRange(1, 100, 2));
        SalesLine.Modify(true);
        SalesHeader.CalcFields("Amount Including VAT");
    end;

    [Normal]
    local procedure SetupServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type")
    var
        ServiceLine: Record "Service Line";
        Item: Record Item;
        Customer: Record Customer;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInDecimalRange(1, 100, 2));
        ServiceLine.Validate("Amount Including VAT", LibraryRandom.RandDecInDecimalRange(1, 100, 2));
        ServiceLine.Modify(true);
    end;

    [Normal]
    local procedure VerifyDocumentSearchResult(var TempDocumentSearchResult: Record "Document Search Result" temporary; DocType: Enum "Service Document Type"; DocNo: Code[20]; Amount: Decimal; TableID: Integer)
    begin
        TempDocumentSearchResult.Get(DocType, DocNo, TableID);
        TempDocumentSearchResult.TestField(Amount, Amount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandlerConfirmYes(Message: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure HandlerConfirmNo(Message: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ReminderPageHandler(var Reminder: TestPage Reminder)
    var
        ReminderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ReminderNo);
        Reminder."No.".AssertEquals(ReminderNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FinChargeMemoPageHandler(var FinChargeMemo: TestPage "Finance Charge Memo")
    var
        FinChargeNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(FinChargeNo);
        FinChargeMemo."No.".AssertEquals(FinChargeNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPageHandler(var SalesOrder: TestPage "Sales Order")
    var
        SalesHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesHeaderNo);
        SalesOrder."No.".AssertEquals(SalesHeaderNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoicePageHandler(var SalesInvoice: TestPage "Sales Invoice")
    var
        SalesHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesHeaderNo);
        SalesInvoice."No.".AssertEquals(SalesHeaderNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesQuotePageHandler(var SalesQuote: TestPage "Sales Quote")
    var
        SalesHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesHeaderNo);
        SalesQuote."No.".AssertEquals(SalesHeaderNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderPageHandler(var BlanketSalesOrder: TestPage "Blanket Sales Order")
    var
        SalesHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesHeaderNo);
        BlanketSalesOrder."No.".AssertEquals(SalesHeaderNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCrMemoPageHandler(var SalesCreditMemo: TestPage "Sales Credit Memo")
    var
        SalesHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesHeaderNo);
        SalesCreditMemo."No.".AssertEquals(SalesHeaderNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesReturnOrderPageHandler(var SalesReturnOrder: TestPage "Sales Return Order")
    var
        SalesHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesHeaderNo);
        SalesReturnOrder."No.".AssertEquals(SalesHeaderNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderPageHandler(var ServiceOrder: TestPage "Service Order")
    var
        ServiceHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ServiceHeaderNo);
        ServiceOrder."No.".AssertEquals(ServiceHeaderNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoicePageHandler(var ServiceInvoice: TestPage "Service Invoice")
    var
        ServiceHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ServiceHeaderNo);
        ServiceInvoice."No.".AssertEquals(ServiceHeaderNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceCrMemoPageHandler(var ServiceCreditMemo: TestPage "Service Credit Memo")
    var
        ServiceHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ServiceHeaderNo);
        ServiceCreditMemo."No.".AssertEquals(ServiceHeaderNo);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuotePageHandler(var ServiceQuote: TestPage "Service Quote")
    var
        ServiceHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ServiceHeaderNo);
        ServiceQuote."No.".AssertEquals(ServiceHeaderNo);
    end;
}

