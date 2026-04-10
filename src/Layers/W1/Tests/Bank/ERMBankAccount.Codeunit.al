codeunit 134231 "ERM Bank Account"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd,
                  TableData "Bank Account Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Account] [UT]
        IsInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        WrongIBANErr: Label 'Wrong number in the field IBAN.';
        BankAccDeleteErr: Label 'You cannot delete this bank account because it is associated with one or more open ledger entries.';
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        IBANConfirmationMsg: Label 'The number %1 that you entered may not be a valid International Bank Account Number (IBAN). Do you want to continue?';
        OnNextRecordStepsErr: Label 'OnNextRecord returned incorrect Steps parameter.';

    [Test]
    [Scope('OnPrem')]
    procedure CRUDBankAccount()
    var
        BankAccount: Record "Bank Account";
        AccountNo: Code[20];
        AccountName: Text[50];
    begin
        Initialize();
        // Create a new bank account
        Evaluate(AccountNo, LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("No."), DATABASE::"Bank Account"));
        Evaluate(AccountName, LibraryUtility.GenerateRandomCode(BankAccount.FieldNo(Name), DATABASE::"Bank Account"));

        LibraryLowerPermissions.SetBanking();
        BankAccount."No." := AccountNo;
        BankAccount.Name := AccountNo;
        BankAccount.IBAN := FindIBAN();
        // Value important for IT.
        BankAccount.Insert(true);

        LibraryLowerPermissions.SetFinancialReporting();
        // Verify it exists
        Assert.IsTrue(BankAccount.Get(AccountNo), 'Failed to find newly created bank account');

        // Update the bank account
        BankAccount.Validate(Name, AccountName);
        BankAccount.Modify(true);

        // Verify it got changed
        Assert.AreEqual(BankAccount.Name, AccountName, 'Bank account information did not get updated');

        LibraryLowerPermissions.SetOutsideO365Scope();
        // Delete the bank account
        BankAccount.Get(AccountNo);
        BankAccount.Delete(true);

        // Verify it no longer exists
        Assert.IsFalse(BankAccount.Get(AccountNo), 'Bank account still exists after deletion');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CRUDSWIFT()
    var
        SWIFTCode: Record "SWIFT Code";
        "Code": Code[20];
        Name: Text[100];
    begin
        Initialize();
        // Create a new SWIFT code
        Evaluate(Code, LibraryUtility.GenerateRandomCode(SWIFTCode.FieldNo(Code), DATABASE::"SWIFT Code"));
        Evaluate(Name, LibraryUtility.GenerateRandomCode(SWIFTCode.FieldNo(Name), DATABASE::"SWIFT Code"));

        LibraryLowerPermissions.SetBanking();
        SWIFTCode.Code := Code;
        SWIFTCode.Name := Code;
        SWIFTCode.Insert(true);

        // Verify it exists
        Assert.IsTrue(SWIFTCode.Get(Code), 'Failed to find newly created SWIFT Code');

        // Update record
        SWIFTCode.Validate(Name, Name);
        SWIFTCode.Modify(true);

        // Verify it got changed
        Assert.AreEqual(SWIFTCode.Name, Name, 'SWIFT code information did not get updated');

        LibraryLowerPermissions.SetOutsideO365Scope();
        // Delete record
        SWIFTCode.Get(Code);
        SWIFTCode.Delete(true);

        // Verify it no longer exists
        Assert.IsFalse(SWIFTCode.Get(Code), 'SWIFT code still exists after deletion');
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckBankAccIBANConfirmYes()
    begin
        // Purpose of the test is to modify IBAN field of table Bank Account and confirm Yes.
        LibraryLowerPermissions.SetO365Full();
        AssignBankAccIBANnumber(true);
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckBankAccIBANConfirmNo()
    begin
        // Purpose of the test is to modify IBAN field of table Bank Account and confirm No.
        LibraryLowerPermissions.SetO365Full();
        AssignBankAccIBANnumber(false);
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckVendBankAccIBANConfirmYes()
    begin
        // Purpose of the test is to modify IBAN field of table Vendor Bank Account and confirm Yes.
        LibraryLowerPermissions.SetO365Full();
        AssignVendBankAccIBANnumber(true);
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure CheckVendBankAccIBANConfirmNo()
    begin
        // Purpose of the test is to modify IBAN field of table Vendor Bank Account and confirm No.
        LibraryLowerPermissions.SetO365Full();
        AssignVendBankAccIBANnumber(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteVendBankAccWithAssociatedOpenEntry()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // [FEATURE] [Vendor Bank Account] [UT] [Purchase]
        // [SCENARIO 378203] Vendor Bank Account cannot be deleted when it has associated open entries
        Initialize();

        // [GIVEN] Vendor with Vendor Bank Account "X"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        // [GIVEN] Opened Vendor Ledger Entry with "Recipient Bank Account" = "X"
        CreateVendLedgEntry(VendorBankAccount, true);

        // [WHEN] Delete Vendor Bank Account "X"
        LibraryLowerPermissions.SetBanking();
        asserterror VendorBankAccount.Delete(true);

        // [THEN] Error Message: You cannot delete this bank account because it is associated with one or more open ledger entries.
        Assert.ExpectedError(BankAccDeleteErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCustBankAccWithAssociatedOpenEntry()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [Customer Bank Account] [UT] [Sales]
        // [SCENARIO 378203] Customer Bank Account cannot be deleted when it has associated open entries
        Initialize();

        // [GIVEN] Customer with Customer Bank Account "X"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // [GIVEN] Opened Customer Ledger Entry with "Recipient Bank Account" = "X"
        CreateCustLedgEntry(CustomerBankAccount, true);

        // [WHEN] Delete Customer Bank Account "X"
        LibraryLowerPermissions.SetBanking();
        asserterror CustomerBankAccount.Delete(true);

        // [THEN] Error Message: You cannot delete this bank account because it is associated with one or more open ledger entries.
        Assert.ExpectedError(BankAccDeleteErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteVendBankAccWithAssociatedClosedEntry()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorBankAccountCode: Code[20];
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 378203] Vendor Bank Account can be deleted when it has associated closed entries
        Initialize();

        // [GIVEN] Vendor with Vendor Bank Account "X"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccountCode := VendorBankAccount.Code;

        // [GIVEN] Closed Vendor Ledger Entry with "Recipient Bank Account" = "X"
        CreateVendLedgEntry(VendorBankAccount, false);

        // [WHEN] Delete Vendor Bank Account "X"
        VendorBankAccount.Delete(true);

        // [THEN] Closed entries are not deleted
        VendorLedgerEntry.Init();
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Recipient Bank Account", VendorBankAccountCode);
        VendorLedgerEntry.SetRange(Open, false);
        Assert.RecordIsNotEmpty(VendorLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCustBankAccWithAssociatedClosedEntry()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerBankAccountCode: Code[20];
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 378203] Customer Bank Account can be deleted when it has associated closed entries
        Initialize();

        // [GIVEN] Customer with Customer Bank Account "X"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccountCode := CustomerBankAccount.Code;

        // [GIVEN] Closed Customer Ledger Entry with "Recipient Bank Account" = "X"
        CreateCustLedgEntry(CustomerBankAccount, false);

        // [WHEN] Delete Customer Bank Account "X"
        CustomerBankAccount.Delete(true);

        // [THEN] Closed entries are not deleted
        CustLedgerEntry.Init();
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Recipient Bank Account", CustomerBankAccountCode);
        CustLedgerEntry.SetRange(Open, false);
        Assert.RecordIsNotEmpty(CustLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignSWIFTCodeToBankAccount()
    var
        BankAccount: Record "Bank Account";
        SWIFTCode: Record "SWIFT Code";
    begin
        // [FEATURE] [UT] [Bank Account]
        Initialize();

        // [GIVEN] Bank Account and new SWIFT Code created
        LibraryERM.CreateBankAccount(BankAccount);

        // [WHEN] Succesfully assign when existing code to field "Bank Account"."SWIFT Code"
        CreateSWIFTCode(SWIFTCode);
        BankAccount.Validate("SWIFT Code", SWIFTCode.Code);
        BankAccount.TestField("SWIFT Code", SWIFTCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignSWIFTCodeToCustBankAccount()
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        SWIFTCode: Record "SWIFT Code";
    begin
        // [FEATURE] [UT] [Bank Account]
        Initialize();

        // [GIVEN] Customer with Customer Bank Account "X"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");

        // [WHEN] Succesfully assign when existing code to field "Bank Account"."SWIFT Code"
        CreateSWIFTCode(SWIFTCode);
        CustomerBankAccount.Validate("SWIFT Code", SWIFTCode.Code);
        CustomerBankAccount.TestField("SWIFT Code", SWIFTCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignSWIFTCodeToVendAccount()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        SWIFTCode: Record "SWIFT Code";
    begin
        // [FEATURE] [UT] [Bank Account]
        Initialize();

        // [GIVEN] Vendor with Vendor Bank Account "X"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");

        // [WHEN] Succesfully assign when existing code to field "Bank Account"."SWIFT Code"
        VendorBankAccount.Validate("SWIFT Code", SWIFTCode.Code);
        VendorBankAccount.TestField("SWIFT Code", SWIFTCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignSWIFTCodeToCompBankAccount()
    var
        CompanyInformation: Record "Company Information";
        SWIFTCode: Record "SWIFT Code";
    begin
        // [FEATURE] [UT] [Bank Account]
        Initialize();

        // [GIVEN] Company Information
        CompanyInformation.Get();

        // [WHEN] Succesfully assign when existing code to field "Bank Account"."SWIFT Code"
        CreateSWIFTCode(SWIFTCode);
        CompanyInformation.Validate("SWIFT Code", SWIFTCode.Code);
        CompanyInformation.TestField("SWIFT Code", SWIFTCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignSWIFTCodeToEmplBankAccount()
    var
        Employee: Record Employee;
        SWIFTCode: Record "SWIFT Code";
    begin
        // [FEATURE] [UT] [Bank Account]
        Initialize();

        // [GIVEN] Employee
        LibraryHumanResource.CreateEmployee(Employee);

        // [WHEN] Succesfully assign when existing code to field "Bank Account"."SWIFT Code"
        CreateSWIFTCode(SWIFTCode);
        Employee.Validate("SWIFT Code", SWIFTCode.Code);
        Employee.TestField("SWIFT Code", SWIFTCode.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountPageBasicSetup()
    var
        BankAccountBalance: TestPage "Bank Account Balance";
    begin
        // [FEATURE] [UI] [Application Area]
        // [SCENARIO 203033] Balance lines page part musst be visible in Basic application area setup.
        LibraryApplicationArea.EnableBasicSetup();
        BankAccountBalance.OpenView();

        Assert.IsTrue(
          BankAccountBalance.BankAccBalanceLines."Period Start".Visible(), 'BankAccBalanceLines."Period Start" must be visible');
        Assert.IsTrue(
          BankAccountBalance.BankAccBalanceLines."Period Name".Visible(), 'BankAccBalanceLines."Period Name" must be visible');
        Assert.IsTrue(
          BankAccountBalance.BankAccBalanceLines.NetChange.Visible(), 'BankAccBalanceLines.NetChange  must be visible');
        Assert.IsTrue(
          BankAccountBalance.BankAccBalanceLines."BankAcc.""Net Change (LCY)""".Visible(), 'BankAccBalanceLines.NetChangeLCY must be visible');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure IBANWithoutPrefixValidation()
    var
        CompanyInformation: Record "Company Information";
        IBANCode: Code[100];
    begin
        // [SCENARIO 337588] IBAN '60050777122' does not pass validation since it does not have country code as prefix
        Initialize();

        IBANCode := '60050777122';

        LibraryVariableStorage.Enqueue(StrSubstNo(IBANConfirmationMsg, IBANCode));
        LibraryVariableStorage.Enqueue(false); // do not confirm invalid IBAN
        asserterror CompanyInformation.CheckIBAN(IBANCode);

        Assert.ExpectedError('');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure IBANWithPrefixValidation()
    var
        CompanyInformation: Record "Company Information";
        IBANCode: Code[100];
    begin
        // [SCENARIO 337588] IBAN 'IT60050777122' does not pass checksum validation.
        Initialize();

        IBANCode := 'IT60050777122';

        LibraryVariableStorage.Enqueue(StrSubstNo(IBANConfirmationMsg, IBANCode));
        LibraryVariableStorage.Enqueue(false); // do not confirm invalid IBAN
        asserterror CompanyInformation.CheckIBAN(IBANCode);

        Assert.ExpectedError('');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountListBalance()
    var
        BankAccount: Record "Bank Account";
        BankAccountList: TestPage "Bank Account List";
    begin
        // [SCENARIO 402879] Bank account list page shows Balance and Balance (LCY) fields
        // [FEATURE] [UI]
        Initialize();

        // [GIVEN] Bank Account
        LibraryERM.CreateBankAccount(BankAccount);

        // [WHEN] Bank Account List page opened
        // [THEN] Balance and Balance (LCY) fields are visible.
        BankAccountList.OpenView();
        Assert.IsTrue(BankAccountList.BalanceAmt.Visible(), 'Balance must be visible');
        Assert.IsTrue(BankAccountList.BalanceLCY.Visible(), 'Balance (LCY) must be visible');
    end;

    [Test]
    procedure RunningBalance()
    var
        BankAccountledgerEntry: Record "Bank Account Ledger Entry";
        BankAccount: Record "Bank Account";
        CalcRunningAccBalance: Codeunit "Calc. Running Acc. Balance";
        i: Integer;
        TotalAmt: Decimal;
        TotalAmtLCY: Decimal;
    begin
        // [SCENARIO] Bank ledger entries show a running balance
        // [FEATURE] [Bank]
        Initialize();

        // [GIVEN] Bank Account and some entries - also more on same day.
        LibraryERM.CreateBankAccount(BankAccount);
        if BankAccountledgerEntry.FindLast() then;
        for i := 1 to 5 do begin
            BankAccountledgerEntry."Entry No." += 1;
            BankAccountledgerEntry."Bank Account No." := BankAccount."No.";
            BankAccountledgerEntry."Posting Date" := DMY2Date(1 + i div 2, 1, 2025);  // should give Januar 1,2,2,3,3,4
            BankAccountledgerEntry.Amount := 1;
            BankAccountledgerEntry."Debit Amount" := 1;
            BankAccountledgerEntry."Credit Amount" := 0;
            BankAccountledgerEntry."Amount (LCY)" := 1;
            BankAccountledgerEntry."Debit Amount (LCY)" := 1;
            BankAccountledgerEntry."Credit Amount (LCY)" := 0;
            BankAccountledgerEntry.Insert();
        end;

        // [WHEN] Running balance is calculated per entry
        // [THEN] RunningBalance and RunningBalanceLCY are the sum of entries up till then.
        BankAccount.CalcFields(Balance, "Balance (LCY)");
        Assert.AreEqual(5, BankAccount.Balance, 'Amount out of balance.');
        Assert.AreEqual(5, BankAccount."Balance (LCY)", 'Amount (LCY) out of balance.');
        BankAccountledgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        BankAccountledgerEntry.SetCurrentKey("Posting Date", "Entry No.");
        if BankAccountledgerEntry.FindSet() then
            repeat
                TotalAmt += BankAccountledgerEntry.Amount;
                TotalAmtLCY += BankAccountledgerEntry."Amount (LCY)";
                Assert.AreEqual(TotalAmt, CalcRunningAccBalance.GetBankAccBalance(BankAccountledgerEntry), 'TotalAmt out of balance');
                Assert.AreEqual(TotalAmtLCY, CalcRunningAccBalance.GetBankAccBalanceLCY(BankAccountledgerEntry), 'TotalAmtLCY out of balance');
            until BankAccountledgerEntry.Next() = 0;
    end;

    [Test]
    procedure RecordRefInsertTempRecordVariant()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        RecRef: RecordRef;
        RecVar: Variant;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 434158] System keeps temporary record information when it passed to RecordRef and returned back via Variant variable
        RecVar := TempNameValueBuffer;

        RecRef.GetTable(RecVar);
        RecRef.Insert();
        Assert.AreEqual(RecRef.Count(), 1, '');
        Assert.IsTrue(RecRef.IsTemporary(), '');

        RecRef.SetTable(RecVar);
        RecRef.Close();
        TempNameValueBuffer := RecVar;

        Assert.IsTrue(TempNameValueBuffer.IsTemporary(), '');
        asserterror Assert.RecordCount(TempNameValueBuffer, 1); // inserted record is lost due to bug 434158
    end;

    [Test]
    procedure RecordRefInsertTempRecord()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        RecRef: RecordRef;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 434158] System keeps temporary record information when it passed to RecordRef and returned back explicitly
        RecRef.GetTable(TempNameValueBuffer);
        RecRef.Insert();
        Assert.AreEqual(RecRef.Count(), 1, '');
        Assert.IsTrue(RecRef.IsTemporary(), '');

        RecRef.SetTable(TempNameValueBuffer);

        Assert.IsTrue(TempNameValueBuffer.IsTemporary(), '');
        Assert.RecordCount(TempNameValueBuffer, 1);
    end;

    [Test]
    procedure RecordRefInsertNormalRecordVariant()
    var
        NameValueBuffer: Record "Name/Value Buffer";
        RecRef: RecordRef;
        RecVar: Variant;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 434158] System keeps record information when it passed to RecordRef and returned back via Variant variable
        RecVar := NameValueBuffer;

        RecRef.GetTable(RecVar);
        RecRef.Insert();
        Assert.AreEqual(RecRef.Count(), 1, '');
        Assert.IsFalse(RecRef.IsTemporary(), '');

        RecRef.SetTable(RecVar);
        NameValueBuffer := RecVar;

        Assert.IsFalse(NameValueBuffer.IsTemporary(), '');
        Assert.RecordCount(NameValueBuffer, 1);
        NameValueBuffer.DeleteAll();
    end;

    [Test]
    procedure RecordRefInsertNormalRecord()
    var
        NameValueBuffer: Record "Name/Value Buffer";
        RecRef: RecordRef;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 434158] System keeps record information when it passed to RecordRef and returned back explicitly
        RecRef.GetTable(NameValueBuffer);
        RecRef.Insert();
        Assert.AreEqual(RecRef.Count(), 1, '');
        Assert.IsFalse(RecRef.IsTemporary(), '');

        RecRef.SetTable(NameValueBuffer);

        Assert.IsFalse(NameValueBuffer.IsTemporary(), '');
        Assert.RecordCount(NameValueBuffer, 1);
        NameValueBuffer.DeleteAll();
    end;

    [Test]
    procedure PeriodFormLinesMgt_OnNextRecord()
    var
        TempBankAccountBalanceBuffer: Record "Bank Account Balance Buffer" temporary;
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        PeriodType: Enum "Analysis Period Type";
        Steps: Integer;
        ExpectedDate: Date;
        FindResult: Boolean;
        NextRecordResult: Integer;
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 417912]  "Period Form Lines Mgt.".NextDate() function has to sync Date Record with moved "Buffer" record when system invokes OnNextRecord trigger of a page.
        Initialize();

        Steps := 0;
        PeriodType := "Analysis Period Type"::Month;

        FindResult := BankAccountBalancePageFindRecordTrigger(TempBankAccountBalanceBuffer, DateRec, PeriodType, PeriodFormLinesMgt);
        Assert.IsTrue(FindResult, '');


        ExpectedDate := CalcDate('<-CM>', WorkDate());
        VerifyBufferAndDateRecords(TempBankAccountBalanceBuffer, DateRec, NextRecordResult, 1, PeriodType, ExpectedDate, 0);

        Steps := 1;
        NextRecordResult := BankAccountBalancePageNextRecordTrigger(TempBankAccountBalanceBuffer, DateRec, Steps, PeriodType, PeriodFormLinesMgt);

        ExpectedDate := CalcDate('<-CM+1M>', WorkDate());
        VerifyBufferAndDateRecords(TempBankAccountBalanceBuffer, DateRec, NextRecordResult, 2, PeriodType, ExpectedDate, Steps);

        NextRecordResult := BankAccountBalancePageNextRecordTrigger(TempBankAccountBalanceBuffer, DateRec, Steps, PeriodType, PeriodFormLinesMgt);

        ExpectedDate := CalcDate('<-CM+2M>', WorkDate());
        VerifyBufferAndDateRecords(TempBankAccountBalanceBuffer, DateRec, NextRecordResult, 3, PeriodType, ExpectedDate, Steps);

        TempBankAccountBalanceBuffer.FindFirst();
        Steps := -1;

        NextRecordResult := BankAccountBalancePageNextRecordTrigger(TempBankAccountBalanceBuffer, DateRec, Steps, PeriodType, PeriodFormLinesMgt);

        ExpectedDate := CalcDate('<-CM-1M>', WorkDate());
        VerifyBufferAndDateRecords(TempBankAccountBalanceBuffer, DateRec, NextRecordResult, 4, PeriodType, ExpectedDate, Steps);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Bank Account");
        LibraryApplicationArea.EnableFoundationSetup();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Bank Account");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Bank Account");
    end;

    local procedure BankAccountBalancePageFindRecordTrigger(var TempBankAccountBalanceBuffer: Record "Bank Account Balance Buffer" temporary; var DateRec: Record Date; PeriodType: Enum "Analysis Period Type"; var PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.") TriggerResult: Boolean
    var
        RecVar: Variant;
    begin
        // Simulates OnFindRecord trigger of "Bank Account Balance" page
        RecVar := TempBankAccountBalanceBuffer;
        TriggerResult := PeriodFormLinesMgt.FindDate(RecVar, DateRec, '=<>', PeriodType.AsInteger());
        TempBankAccountBalanceBuffer := RecVar;
        // additional Insert due to bug 434158
        if TriggerResult then
            TempBankAccountBalanceBuffer.Insert()
    end;

    local procedure BankAccountBalancePageNextRecordTrigger(var TempBankAccountBalanceBuffer: Record "Bank Account Balance Buffer" temporary; var DateRec: Record Date; Steps: Integer; PeriodType: Enum "Analysis Period Type"; var PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.") TriggerResult: Integer
    var
        RecVar: Variant;
    begin
        // Simulates OnNextRecord trigger of "Bank Account Balance" page
        RecVar := TempBankAccountBalanceBuffer;
        TriggerResult := PeriodFormLinesMgt.NextDate(RecVar, DateRec, Steps, PeriodType.AsInteger());
        TempBankAccountBalanceBuffer := RecVar;
        // additional Insert due to bug 434158
        if TriggerResult <> 0 then
            TempBankAccountBalanceBuffer.Insert()
    end;

    local procedure FindIBAN(): Code[50]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation.IBAN);
    end;

    local procedure AssignBankAccIBANnumber(ConfirmReply: Boolean)
    var
        BankAccount: Record "Bank Account";
        IBANNumber: Code[50];
        OldIBAN: Code[50];
    begin
        BankAccount.Init();
        OldIBAN := BankAccount.IBAN;
        IBANNumber := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(StrSubstNo(IBANConfirmationMsg, IBANNumber));
        LibraryVariableStorage.Enqueue(ConfirmReply);

        if ConfirmReply then
            BankAccount.Validate(IBAN, IBANNumber)
        else begin
            asserterror BankAccount.Validate(IBAN, IBANNumber);
            IBANNumber := OldIBAN;
        end;

        VerifyIBAN(BankAccount.IBAN, IBANNumber);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure AssignVendBankAccIBANnumber(ConfirmReply: Boolean)
    var
        VendBankAccount: Record "Vendor Bank Account";
        IBANNumber: Code[50];
        OldIBAN: Code[50];
    begin
        VendBankAccount.Init();
        OldIBAN := VendBankAccount.IBAN;
        IBANNumber := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(StrSubstNo(IBANConfirmationMsg, IBANNumber));
        LibraryVariableStorage.Enqueue(ConfirmReply);

        if ConfirmReply then
            VendBankAccount.Validate(IBAN, IBANNumber)
        else begin
            asserterror VendBankAccount.Validate(IBAN, IBANNumber);
            IBANNumber := OldIBAN;
        end;

        VerifyIBAN(VendBankAccount.IBAN, IBANNumber);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateVendLedgEntry(VendorBankAccount: Record "Vendor Bank Account"; IsOpen: Boolean)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
    begin
        VendLedgEntry.Init();
        RecRef.GetTable(VendLedgEntry);
        VendLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, VendLedgEntry.FieldNo("Entry No."));
        VendLedgEntry."Vendor No." := VendorBankAccount."Vendor No.";
        VendLedgEntry."Recipient Bank Account" := VendorBankAccount.Code;
        VendLedgEntry.Open := IsOpen;
        VendLedgEntry.Insert();
    end;

    local procedure CreateCustLedgEntry(CustomerBankAccount: Record "Customer Bank Account"; IsOpen: Boolean)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
    begin
        CustLedgEntry.Init();
        RecRef.GetTable(CustLedgEntry);
        CustLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CustLedgEntry.FieldNo("Entry No."));
        CustLedgEntry."Customer No." := CustomerBankAccount."Customer No.";
        CustLedgEntry."Recipient Bank Account" := CustomerBankAccount.Code;
        CustLedgEntry.Open := IsOpen;
        CustLedgEntry.Insert();
    end;

    local procedure CreateSWIFTCode(var SWIFTCode: Record "SWIFT Code")
    begin
        SWIFTCode.Init();
        SWIFTCode.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(SWIFTCode.FieldNo(Code), DATABASE::"SWIFT Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"SWIFT Code", SWIFTCode.FieldNo(Code))));
        SWIFTCode.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(SWIFTCode.Name)));
        SWIFTCode.Insert(true);
    end;

    local procedure VerifyIBAN(CurrentIBAN: Code[50]; CheckIBAN: Code[50])
    begin
        Assert.AreEqual(CurrentIBAN, CheckIBAN, WrongIBANErr);
    end;

    local procedure VerifyBufferAndDateRecords(var TempBankAccountBalanceBuffer: Record "Bank Account Balance Buffer" temporary; var DateRec: Record Date; var Steps: Integer; ExpectedCount: Integer; ExpectedPeriodType: Enum "Analysis Period Type"; ExpectedDate: Date; ExpectedSteps: Integer)
    begin
        Assert.RecordCount(TempBankAccountBalanceBuffer, ExpectedCount);
        TempBankAccountBalanceBuffer.TestField("Period Type", ExpectedPeriodType);
        TempBankAccountBalanceBuffer.TestField("Period Start", ExpectedDate);
        DateRec.TestField("Period Type", ExpectedPeriodType);
        DateRec.TestField("Period Start", ExpectedDate);
        Assert.AreEqual(Steps, ExpectedSteps, OnNextRecordStepsErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure IBANConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

