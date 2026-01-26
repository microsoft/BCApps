codeunit 144054 "UT TAB Auto Payment"
{
    //  1. Purpose of the test is to validate code of OnModify trigger of table 288 - Vendor Bank Account.
    //  2. Purpose of the test is to validate code of OnModify trigger of table 270 - Bank Account.
    //  3. Purpose of the test is to validate code of OnValidate trigger of IBAN field of table 270 - Bank Account.
    //  4. Purpose of the test is to validate code of OnValidate trigger of IBAN field of table 288 - Vendor Bank Account.
    //  5. Purpose of the test is to validate OnDelete trigger of table 12177 - Issued Customer Bill Header.
    //  6. Purpose of the test is to validate OnRename trigger of table 12177 - Issued Customer Bill Header.
    //  7. Purpose of the test is to validate Navigate function of table 12177 - Issued Customer Bill Header.
    //  8. Purpose of the test is to validate OnDelete trigger of table 12180 - Bill.
    //  9. Purpose of the test is to validate OnRename trigger of table 12183 - Posted Vendor Bill Header.
    // 10. Purpose of the test is to validate Navigate function of table 12183 - Posted Vendor Bill Header.
    // 11. Purpose of the test is to validate GetCurrCode function of table 12184 - Posted Vendor Bill Line.
    // 12. Purpose of the test is to validate AssistEdit trigger of table 12174 - Customer Bill Header.
    // 13. Purpose of the test is to validate OnDelete trigger of table 12174 - Customer Bill Header.
    // 14. Purpose of the test is to validate OnRename trigger of table 12174 - Customer Bill Header.
    // 15. Purpose of the test is to validate AssistEdit trigger of table 12181 - Vendor Bill Header.
    // 16. Purpose of the test is to validate OnRename trigger of table 12181 - Vendor Bill Header.
    // 17. Purpose of the test is to validate Bank Account No. - OnValidate trigger of table 12181 - Vendor Bill Header.
    // 18. Purpose of the test is to validate Beneficiary Value Date - OnValidate trigger of table 12181 - Vendor Bill Header.
    // 19. Purpose of the test is to validate Currency Code - OnValidate trigger of table 12181 - Vendor Bill Header with new Currency.
    // 20. Purpose of the test is to validate List Date - OnValidate trigger of table 12181 - Vendor Bill Header with List Date greater than Posting Date.
    // 21. Purpose of the test is to validate List Date - OnValidate trigger of table 12181 - Vendor Bill Header with blank Posting Date.
    // 22. Purpose of the test is to validate Payment Method Code - OnValidate trigger of table 12181 - Vendor Bill Header.
    // 23. Purpose of the test is to validate UpdateCurrencyFactor function of table 12181 - Vendor Bill Header.
    // 24. Purpose of the test is to validate UpdateCurrencyFactor function of table 12181 - Vendor Bill Header without Currency.
    // 25. Purpose of the test is to validate Amount To Pay - OnValidate trigger of table 12182 - Vendor Bill Line.
    // 26. Purpose of the test is to validate GetVendBillWithhTax function of table 12182 - Vendor Bill Line with different Vendor Bill Withholding Tax.
    // 27. Purpose of the test is to validate GetVendBillWithhTax function of table 12182 - Vendor Bill Line.
    // 
    // Covers Test Cases for WI - 347715.
    // ---------------------------------------------------------
    // Test Function Name                                 TFS ID
    // ---------------------------------------------------------
    // OnModifyVendorBankAccountError              151400,151401
    // OnModifyBankAccountError                    151477,151478
    // 
    // Covers Test Cases for WI - 348537
    // ---------------------------------------------------------
    // Test Function Name                                 TFS ID
    // ---------------------------------------------------------
    // OnDeleteIssuedCustomerBillHeader
    // OnRenameIssuedCustomerBillHeader
    // NavigateIssuedCustomerBillHeader
    // OnDeleteBill
    // OnRenamePostedVendorBillHeader
    // NavigatePostedVendorBillHeader
    // GetCurrencyCodePostedVendorBillLine
    // 
    // Covers Test Cases for WI - 348978
    // ---------------------------------------------------------
    // Test Function Name                                 TFS ID
    // ---------------------------------------------------------
    // AssistEditCustomerBillHeader
    // OnDeleteCustomerBillHeader
    // OnRenameCustomerBillHeaderError
    // AssistEditVendorBillHeader
    // OnRenameVendorBillHeaderError
    // OnValidateBankAccountNoVendorBillHeaderError
    // OnValidateBeneficiaryValueDateVendBillHeaderError
    // OnValidateCurrencyCodeVendorBillHeaderError
    // OnValidateListDateVendorBillHeaderError
    // OnValidateListDateWithBlankPostDateVendBillHeader
    // OnValidatePaymentMethodCodeVendorBillHeaderError
    // UpdateCurrencyFactorVendorBillHeader
    // UpdateCurrencyFactorWithBlankCurrVendorBillHeader
    // OnValidateAmountToPayVendorBillLineError
    // GetVendBillWithhTaxVendorBillLine
    // GetVendBillWithhTaxWithInitValuesVendorBillLine

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        DialogErr: Label 'Dialog';
        IBANMandatoryMsg: Label 'The field IBAN is mandatory.';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LineMustNotExistsErr: Label '%1 must not exists.';
        NotAssignedErr: Label '%1 not assigned.';
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnModifyVendorBankAccountError()
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        // Purpose of the test is to validate code of OnModify trigger of table 288 - Vendor Bank Account.

        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(IBANMandatoryMsg);  // Enqueue for ConfirmHandler.
        CreateVendorBankAccount(VendorBankAccount);
        VendorBankAccount.Name := LibraryUTUtility.GetNewCode();

        // Exercise.
        VendorBankAccount.Modify(true);

        // Verify: The field IBAN is mandatory. Verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnModifyBankAccountError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Purpose of the test is to validate code of OnModify trigger of table 270 - Bank Account.

        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(IBANMandatoryMsg);  // Enqueue for ConfirmHandler.
        BankAccount.Get(CreateBankAccount(false));  // FALSE for Blocked.
        BankAccount.Name := LibraryUTUtility.GetNewCode();

        // Exercise.
        BankAccount.Modify(true);

        // Verify: The field IBAN is mandatory. Verification done in ConfirmHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteIssuedCustomerBillHeader()
    var
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
    begin
        // Purpose of the test is to validate OnDelete trigger of table 12177 - Issued Customer Bill Header.

        // Setup.
        Initialize();
        CreateIssuedCustomerBill(IssuedCustomerBillHeader);

        // Exercise.
        IssuedCustomerBillHeader.Delete(true);

        // Verify: Verify no Issued Customer Bill Line exists for Deleted Issued Customer Bill Header.
        IssuedCustomerBillLine.SetRange("Customer Bill No.", IssuedCustomerBillHeader."No.");
        Assert.IsFalse(IssuedCustomerBillLine.FindFirst(), StrSubstNo(LineMustNotExistsErr, IssuedCustomerBillLine.TableCaption()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenameIssuedCustomerBillHeader()
    var
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
    begin
        // Purpose of the test is to validate OnRename trigger of table 12177 - Issued Customer Bill Header.

        // Setup.
        Initialize();
        CreateIssuedCustomerBill(IssuedCustomerBillHeader);

        // Exercise.
        asserterror IssuedCustomerBillHeader.Rename(LibraryUTUtility.GetNewCode());

        // Verify: Verify expected error code, actual error: "You cannot rename a Issued Customer Bill Header.".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigateIssuedCustomerBillHeader()
    var
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
    begin
        // Purpose of the test is to validate Navigate function of table 12177 - Issued Customer Bill Header.

        // Setup.
        Initialize();
        CreateIssuedCustomerBill(IssuedCustomerBillHeader);
        LibraryVariableStorage.Enqueue(DATABASE::"Issued Customer Bill Header");  // Enqueue for NavigatePageHandler.

        // Exercise.
        IssuedCustomerBillHeader.Navigate();

        // Verify: Verify No. of records in NavigatePageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteBill()
    var
        Bill: Record Bill;
    begin
        // Purpose of the test is to validate OnDelete trigger of table 12180 - Bill.

        // Setup.
        Initialize();
        CreateBillWithPaymentMethod(Bill);

        // Exercise.
        asserterror Bill.Delete(true);

        // Verify: Verify expected error code, actual error: "You cannot delete Bill XXXX because there are one or more payment methods for this code."
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenamePostedVendorBillHeader()
    var
        PostedVendorBillHeader: Record "Posted Vendor Bill Header";
    begin
        // Purpose of the test is to validate OnRename trigger of table 12183 - Posted Vendor Bill Header.

        // Setup.
        Initialize();
        CreatePostedVendorBillHeader(PostedVendorBillHeader);

        // Exercise.
        asserterror PostedVendorBillHeader.Rename(LibraryUTUtility.GetNewCode());

        // Verify: Verify expected error code, actual error: "You cannot rename a Posted Vendor Bill Header".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NavigatePostedVendorBillHeader()
    var
        PostedVendorBillHeader: Record "Posted Vendor Bill Header";
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
    begin
        // Purpose of the test is to validate Navigate function of table 12183 - Posted Vendor Bill Header.

        // Setup.
        Initialize();
        CreatePostedVendorBillHeader(PostedVendorBillHeader);
        CreatePostedVendorBillLine(PostedVendorBillLine, PostedVendorBillHeader."No.");
        CreateVendorLedgerEntry(PostedVendorBillLine."Vendor No.", PostedVendorBillHeader."No.");
        LibraryVariableStorage.Enqueue(DATABASE::"Vendor Ledger Entry");  // Enqueue for NavigatePageHandler.

        // Exercise.
        PostedVendorBillHeader.Navigate();

        // Verify: Verify No. of records in NavigatePageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetCurrencyCodePostedVendorBillLine()
    var
        PostedVendorBillLine: Record "Posted Vendor Bill Line";
        VendorBillHeader: Record "Vendor Bill Header";
        CurrencyCode: Code[10];
    begin
        // Purpose of the test is to validate GetCurrCode function of table 12184 - Posted Vendor Bill Line.

        // Setup.
        Initialize();
        CreateVendorBillHeader(VendorBillHeader, CreateCurrency(), WorkDate());
        CreatePostedVendorBillLine(PostedVendorBillLine, VendorBillHeader."No.");

        // Exercise.
        CurrencyCode := PostedVendorBillLine.GetCurrCode();

        // Verify.
        VendorBillHeader.TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AssistEditCustomerBillHeader()
    var
        CustomerBillHeader: Record "Customer Bill Header";
    begin
        // Purpose of the test is to validate AssistEdit trigger of table 12174 - Customer Bill Header.

        // Setup.
        Initialize();

        // Exercise.
        CreateCustomerBill(CustomerBillHeader);

        // Verify.
        Assert.IsTrue(
          CustomerBillHeader.AssistEdit(CustomerBillHeader), StrSubstNo(NotAssignedErr, CustomerBillHeader.FieldCaption("No.")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteCustomerBillHeader()
    var
        CustomerBillHeader: Record "Customer Bill Header";
        CustomerBillLine: Record "Customer Bill Line";
    begin
        // Purpose of the test is to validate OnDelete trigger of table 12174 - Customer Bill Header.

        // Setup.
        Initialize();
        CreateCustomerBill(CustomerBillHeader);

        // Exercise.
        CustomerBillHeader.Delete(true);

        // Verify: Verify no Customer Bill Line exists for deleted Customer Bill Header.
        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        Assert.IsFalse(CustomerBillLine.FindFirst(), StrSubstNo(LineMustNotExistsErr, CustomerBillLine.TableCaption()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenameCustomerBillHeaderError()
    var
        CustomerBillHeader: Record "Customer Bill Header";
    begin
        // Purpose of the test is to validate OnRename trigger of table 12174 - Customer Bill Header.

        // Setup.
        Initialize();
        CreateCustomerBill(CustomerBillHeader);

        // Exercise.
        asserterror CustomerBillHeader.Rename(LibraryUTUtility.GetNewCode());

        // Verify: Verify expected error code, actual error: "You cannot rename a Customer Bill Header".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure AssistEditVendorBillHeader()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate AssistEdit trigger of table 12181 - Vendor Bill Header.

        // Setup.
        Initialize();

        // Exercise.
        CreateVendorBillHeader(VendorBillHeader, '', WorkDate());  // Blank value for Currency Code.

        // Verify.
        Assert.IsTrue(VendorBillHeader.AssistEdit(VendorBillHeader), StrSubstNo(NotAssignedErr, VendorBillHeader.FieldCaption("No.")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenameVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate OnRename trigger of table 12181 - Vendor Bill Header.

        // Setup.
        Initialize();
        CreateVendorBillHeader(VendorBillHeader, '', WorkDate());  // Blank value for Currency Code.

        // Exercise.
        asserterror VendorBillHeader.Rename(LibraryUTUtility.GetNewCode());

        // Verify: Verify expected error code, actual error: "You cannot rename a Vendor Bill Header".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBankAccountNoVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate Bank Account No. - OnValidate trigger of table 12181 - Vendor Bill Header.

        // Setup.
        Initialize();
        CreateVendorBillHeader(VendorBillHeader, '', WorkDate());  // Blank value for Currency Code.

        // Exercise.
        asserterror VendorBillHeader.Validate("Bank Account No.", CreateBankAccount(true));  // True for Blocked.

        // Verify: Verify expected error code, actual error: "Bank Account No. il blocked".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBeneficiaryValueDateVendBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate Beneficiary Value Date - OnValidate trigger of table 12181 - Vendor Bill Header.

        // Setup.
        Initialize();
        CreateVendorBill(VendorBillHeader, '');  // Blank value for Currency Code.

        // Exercise.
        asserterror VendorBillHeader.Validate(
            "Beneficiary Value Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        // Verify: Verify expected error code, actual error: "It's not possible to change Beneficiary Value Date because there are Vendor Bill Line associated to this Vendor Bill Header".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateCurrencyCodeVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate Currency Code - OnValidate trigger of table 12181 - Vendor Bill Header with new Currency.

        // Setup.
        Initialize();
        CreateVendorBill(VendorBillHeader, CreateCurrencyExchangeRate());

        // Exercise.
        asserterror VendorBillHeader.Validate("Currency Code", CreateCurrency());

        // Verify: Verify expected error code, actual error: "It's not possible to change Currency Code because there are Vendor Bill Line associated to this Vendor Bill Header".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateListDateVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate List Date - OnValidate trigger of table 12181 - Vendor Bill Header with List Date greater than Posting Date.

        // Setup.
        Initialize();
        CreateVendorBillHeader(VendorBillHeader, '', WorkDate());  // Blank for Currency Code.

        // Exercise.
        asserterror VendorBillHeader.Validate(
            "List Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', VendorBillHeader."Posting Date"));

        // Verify: Verify expected error code, actual error: "List Date must not be greater than Posting Date".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateListDateWithBlankPostDateVendBillHeader()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate List Date - OnValidate trigger of table 12181 - Vendor Bill Header with blank Posting Date.

        // Setup.
        Initialize();
        CreateVendorBillHeader(VendorBillHeader, '', 0D);  // Blank value for Currency Code and 0D for Posting Date.

        // Exercise.
        VendorBillHeader.Validate("List Date", WorkDate());

        // Verify.
        VendorBillHeader.TestField("Posting Date", VendorBillHeader."List Date");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidatePaymentMethodCodeVendorBillHeaderError()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate Payment Method Code - OnValidate trigger of table 12181 - Vendor Bill Header.

        // Setup.
        Initialize();
        CreateVendorBill(VendorBillHeader, '');  // Blank value for Currency Code.

        // Exercise.
        asserterror VendorBillHeader.Validate("Payment Method Code", CreatePaymentMethod());

        // Verify: Verify expected error code, actual error: "It's not possible to change Payment Method Code because there are Vendor Bill Line associated to this Vendor Bill Header".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateCurrencyFactorVendorBillHeader()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate UpdateCurrencyFactor function of table 12181 - Vendor Bill Header.

        // Setup.
        Initialize();
        CreateVendorBillHeader(VendorBillHeader, '', WorkDate());  // Blank value for Currency Code.

        // Exercise.
        VendorBillHeader.Validate("Currency Code", CreateCurrencyExchangeRate());

        // Verify.
        VendorBillHeader.TestField(
          "Currency Factor", CurrencyExchangeRate.ExchangeRate(VendorBillHeader."List Date", VendorBillHeader."Currency Code"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateCurrencyFactorWithBlankCurrVendorBillHeader()
    var
        VendorBillHeader: Record "Vendor Bill Header";
    begin
        // Purpose of the test is to validate UpdateCurrencyFactor function of table 12181 - Vendor Bill Header without Currency.

        // Setup.
        Initialize();
        CreateVendorBillHeader(VendorBillHeader, CreateCurrencyExchangeRate(), WorkDate());

        // Exercise.
        VendorBillHeader.Validate("Currency Code", '');  // Blank value required for Currency Code.

        // Verify.
        VendorBillHeader.TestField("Currency Factor", 0);  // Value 0 required for Curency Factor.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateAmountToPayVendorBillLineError()
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        // Purpose of the test is to validate Amount To Pay - OnValidate trigger of table 12182 - Vendor Bill Line.

        // Setup.
        Initialize();
        CreateVendorBillLine(VendorBillLine, LibraryUTUtility.GetNewCode());

        // Exercise.
        asserterror VendorBillLine.Validate(
            "Amount to Pay", VendorBillLine."Remaining Amount" + LibraryRandom.RandDec(5, 2));  // Greater value required for Amount to Pay.

        // Verify: Verify expected error code, actual error: "Amount to Pay must not be less than zero or greater than Remaining Amount".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetVendBillWithhTaxVendorBillLine()
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        // Purpose of the test is to validate GetVendBillWithhTax function of table 12182 - Vendor Bill Line with different Vendor Bill Withholding Tax.

        // Setup.
        Initialize();
        CreateVendorBillLine(VendorBillLine, LibraryUTUtility.GetNewCode());

        // Exercise.
        CreateVendorBillWithholdingTax();

        // Verify.
        Assert.IsFalse(
          VendorBillLine.GetVendBillWithhTax(), StrSubstNo(NotAssignedErr, VendorBillLine.FieldCaption("Withholding Tax Amount")));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetVendBillWithhTaxWithInitValuesVendorBillLine()
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        // Purpose of the test is to validate GetVendBillWithhTax function of table 12182 - Vendor Bill Line.

        // Setup.
        Initialize();
        CreateVendorBillLine(VendorBillLine, LibraryUTUtility.GetNewCode());

        // Exercise.
        VendorBillLine.InitValues();

        // Verify.
        Assert.IsTrue(
          VendorBillLine.GetVendBillWithhTax(), StrSubstNo(NotAssignedErr, VendorBillLine.FieldCaption("Withholding Tax Amount")));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryUTUtility.Clear();
    end;

    local procedure CreateBankAccount(Blocked: Boolean): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Blocked := Blocked;
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateBillWithPaymentMethod(var Bill: Record Bill)
    var
        PaymentMethod: Record "Payment Method";
    begin
        Bill.Code := LibraryUTUtility.GetNewCode();
        Bill.Insert();
        PaymentMethod."Bill Code" := Bill.Code;
        PaymentMethod.Insert();
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchangeRate(): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate."Currency Code" := CreateCurrency();
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(100, 2);
        CurrencyExchangeRate."Relational Exch. Rate Amount" := LibraryRandom.RandDec(100, 2);
        CurrencyExchangeRate.Insert();
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreateCustomerBill(var CustomerBillHeader: Record "Customer Bill Header")
    var
        CustomerBillLine: Record "Customer Bill Line";
    begin
        CustomerBillHeader."No." := LibraryUTUtility.GetNewCode();
        CustomerBillHeader."Bank Account No." := CreateBankAccount(false);  // False for Blocked.
        CustomerBillHeader.Insert();
        CustomerBillLine."Customer Bill No." := CustomerBillHeader."No.";
        CustomerBillLine.Insert();
    end;

    local procedure CreateIssuedCustomerBill(var IssuedCustomerBillHeader: Record "Issued Customer Bill Header")
    var
        IssuedCustomerBillLine: Record "Issued Customer Bill Line";
    begin
        IssuedCustomerBillHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedCustomerBillHeader.Insert();
        IssuedCustomerBillLine."Customer Bill No." := IssuedCustomerBillHeader."No.";
        IssuedCustomerBillLine.Insert();
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Code := LibraryUTUtility.GetNewCode10();
        PaymentMethod."Bill Code" := LibraryUTUtility.GetNewCode();
        PaymentMethod.Insert();
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePostedVendorBillHeader(var PostedVendorBillHeader: Record "Posted Vendor Bill Header")
    begin
        PostedVendorBillHeader."No." := LibraryUTUtility.GetNewCode();
        PostedVendorBillHeader."Posting Date" := WorkDate();
        PostedVendorBillHeader.Insert();
    end;

    local procedure CreatePostedVendorBillLine(var PostedVendorBillLine: Record "Posted Vendor Bill Line"; VendorBillNo: Code[20])
    begin
        PostedVendorBillLine."Vendor Bill No." := VendorBillNo;
        PostedVendorBillLine."Vendor No." := CreateVendor();
        PostedVendorBillLine."Manual Line" := true;
        PostedVendorBillLine.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        VendorBankAccount."Vendor No." := LibraryUTUtility.GetNewCode10();
        VendorBankAccount.Code := LibraryUTUtility.GetNewCode10();
        VendorBankAccount.Insert();
    end;

    local procedure CreateVendorBill(var VendorBillHeader: Record "Vendor Bill Header"; CurrencyCode: Code[10])
    var
        VendorBillLine: Record "Vendor Bill Line";
    begin
        CreateVendorBillHeader(VendorBillHeader, CurrencyCode, WorkDate());
        CreateVendorBillLine(VendorBillLine, VendorBillHeader."No.");
    end;

    local procedure CreateVendorBillHeader(var VendorBillHeader: Record "Vendor Bill Header"; CurrencyCode: Code[10]; PostingDate: Date)
    begin
        VendorBillHeader."No." := LibraryUTUtility.GetNewCode();
        VendorBillHeader."Currency Code" := CurrencyCode;
        VendorBillHeader."Payment Method Code" := CreatePaymentMethod();
        VendorBillHeader."List Date" := WorkDate();
        VendorBillHeader."Currency Code" := CurrencyCode;
        VendorBillHeader."Posting Date" := PostingDate;
        VendorBillHeader."Beneficiary Value Date" := WorkDate();
        VendorBillHeader.Insert();
    end;

    local procedure CreateVendorBillLine(var VendorBillLine: Record "Vendor Bill Line"; VendorBillListNo: Code[20])
    begin
        VendorBillLine."Vendor Bill List No." := VendorBillListNo;
        VendorBillLine."Line No." := LibraryRandom.RandInt(10);
        VendorBillLine."Remaining Amount" := LibraryRandom.RandDec(100, 2);
        VendorBillLine.Insert();
    end;

    local procedure CreateVendorBillWithholdingTax()
    var
        VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax";
    begin
        VendorBillWithholdingTax."Vendor Bill List No." := LibraryUTUtility.GetNewCode();
        VendorBillWithholdingTax."Line No." := LibraryRandom.RandInt(10);
        VendorBillWithholdingTax.Insert();
    end;

    local procedure CreateVendorLedgerEntry(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry2.FindLast();
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ConfirmMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(ConfirmMsg);
        Assert.IsTrue(StrPos(ConfirmMessage, ConfirmMsg) > 0, ConfirmMessage);
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePageHandler(var Navigate: TestPage Navigate)
    var
        TableID: Variant;
    begin
        LibraryVariableStorage.Dequeue(TableID);
        Navigate.FILTER.SetFilter("Table ID", Format(TableID));
        Navigate."No. of Records".AssertEquals(1);  // 1 for No. of records.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.OK().Invoke();
    end;
}

