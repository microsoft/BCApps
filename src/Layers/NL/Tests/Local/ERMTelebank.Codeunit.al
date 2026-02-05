codeunit 144037 "ERM Telebank"
{
    //  // [FEATURE] [Telebank]
    //  1. Test to Verify IBAN on Proposal Line table.
    //  2. Test to Verify Error on Telebank Proposal page with blank Country/Region Code on Bank Account.
    //  3. Test to Verify Error on Telebank Proposal page with blank IBAN on Bank Account.
    //  4. Test to Verify Error on Telebank Proposal page with blank SWIFT Code on Bank Account.
    //  5. Test to Verify Error on Telebank Proposal page after update Currency Code on Bank Account.
    //  6. Test to Verify Error on Telebank Proposal page with blank Bank Account No on Bank Account.
    //  7. Test to Verify Error on Telebank Proposal page with blank Account Holder Name on Bank Account.
    //  8. Test to Verify Error on Telebank Proposal page with blank Account Holder Address on Bank Account.
    //  9. Test to Verify Error on Telebank Proposal page with blank Account Holder Post Code on Bank Account.
    // 10. Test to Verify Error on Telebank Proposal page with blank Account Holder City on Bank Account.
    // 11. Test to Verify Error on Telebank Proposal page with blank IBAN on Vendor Bank Account.
    // 12. Test to Verify Error on Telebank Proposal page with blank SWIFT Code on Vendor Bank Account.
    // 13. Test to Verify Error on Telebank Proposal page with SWIFT Code more than 11 characters on Vendor Bank Account.
    // 14. Test to Verify Error on Telebank Proposal page with blank Country/Region Code on Vendor Bank Account.
    // 15. Test to Verify Error on Telebank Proposal page with SEPA Allowed as false on Country/Region.
    // 16. Test to Verify Error on Telebank Proposal page with blank Acc. Hold Country/Region Code on Vendor Bank Account.
    // 17. Test to Verify Error on Telebank Proposal page with blank Acc. Hold City on Vendor Bank Account.
    // 18. Test to Verify Error on Telebank Proposal page with No Check ID on Export Protocol.
    // 19. Test to Verify Error on Telebank Proposal page with Order as credit On Transaction Mode.
    // 20. Test to Verify Error on Telebank Proposal page with Currency Euro on General Ledger Setup.
    // 21. Test to Verify Error on Telebank Proposal page with blank Currency Euro on General Ledger Setup.
    // 22-26. Test to Verfiy Error on Check SEPA ISO20022 code unit of Nature of Payment Type Blank,Transito Trade,Invisible- and Capital Transactions,Transfer to Own Account,Other Registrated BFI during Process.
    // 27-31. Test to Verfiy Error on Check SEPA ISO20022 code unit of Nature of Payment Type Blank,Transito Trade,Invisible- and Capital Transactions,Transfer to Own Account,Other Registrated BFI during Check.
    // 32. Test to Verify error in case of set Serial No. as 0 on Propsal Detail Line.
    // 33. Test to Verify Description after changed description detail on Propsal Detail Line.
    // 34. Test to Verify updated Transaction Date in Detail Line.
    // 35. Test to Verify page Vendor Card and Vendor Ledger Entries openned correctly when lookup from Payment History Card with Account Type=Vendor on the line.
    // 36. Test to Verify page Customer Card and Customer Ledger Entries openned correctly when lookup from Payment History Card with Account Type=Customer on the line.
    // 37. Test to Verify what the Country/Region Code which is in a different area correct value is taken from Bank Country/Region.
    // 
    // Covers Test Cases for WI - 342314
    // -------------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                       TFS ID
    // -------------------------------------------------------------------------------------------------------------------------------------------
    // ProposalLineIBANConfirmYes, ProposalLineIBANConfirmNo, BankAccWithBlankCountryTelebankProposalError
    // BankAccWithBlankIBANTelebankProposalError, BankAccWithBlankSWIFTCodeTelebankProposalError
    // BankAccWithCurrencyTelebankProposalError, BankAccWithBlankBankAccNoTelebankProposalError
    // BankAccWithBlankNameTelebankProposalError, BankAccWithBlankAddressTelebankProposalError
    // BankAccWithBlankPostCodeTelebankProposalError, BankAccWithBlankCityTelebankProposalError
    // VendBankAccWithBlankIBANTelebankProposalError, VendBankAccWithBlankSWIFTCodeTelebankProposalError
    // VendBankAccWithSWIFTCodeTelebankProposalError, VendBankAccWithBlankCountryTelebankProposalError
    // VendBankAccWithSEPAAllowedAsFalseOnCountryRegion, VendBankAccWithBlankAccHoldTelebankProposalError
    // VendBankAccWithBlankCityTelebankProposalError, ExportProtocolWithNoCheckIDTelebankProposalError
    // TransactionModeWithOrdCreditTelebankProposalError, VendBankAccWithCurrencyTelebankProposalError
    // VendBankAccWithBlankCurrencyTelebankProposalError
    // 
    // Covers Test Cases for WI - 343204
    // -------------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                       TFS ID
    // -------------------------------------------------------------------------------------------------------------------------------------------
    // NatureOfPaymentBlankProcessErr, NatureOfPaymentTransitoTradeProcessErr                                                171428,171430
    // NatureOfPmtInvisibleAndCapitalTransacProcessErr, NatureOfPmtTransferToOwnAccountProcessErr                            171431,171429
    // NatureOfPmtOtherRegistratedBFIProcessErr, NatureOfPaymentBlankCheckErr                                                171427,171447
    // NatureOfPaymentTransitoTradeCheckErr, NatureOfPmtInvisibleAndCapitalTransacCheckErr                                   171449,171450
    // NatureOfPmtTransferToOwnAccountCheckErr, NatureOfPmtOtherRegistratedBFICheckErr                                       171448,171446,171389
    // 
    // Covers Test Cases for WI - 343360
    // -------------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                       TFS ID
    // -------------------------------------------------------------------------------------------------------------------------------------------
    // ProposalDetailLineSeriolNoErr                                                                                            171385
    // ProposalDetailLineUpdateDescription                                                                                      171475
    // UpdateTransactionDateInProcess                                                                                           259725
    // 
    // Covers Test Cases for Hotfix - 94400
    // -------------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                       TFS ID
    // -------------------------------------------------------------------------------------------------------------------------------------------
    // LookupFromPaymentHistoryCardWithVendorAccountType                                                                         94400
    // LookupFromPaymentHistoryCardWithCustomerAccountType                                                                       94400
    // 
    // Test Function Name                                                  TFS ID
    // --------------------------------------------------------------------------------------
    // FreelyTransMaximumOnDiffAccHoldCountryRegion                        358956

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNLLocalization: Codeunit "Library - NL Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        AmountExceedsMsg: Label 'Amount exceeds the maximum limit, Nature of the Payment must be entered. The default value is ''goods''.';
        BankAccountNoTxt: Label 'P5234567', Comment = 'aejhdwjqedf';
        CheckIDTxt: Label 'No Check ID entered in Export Protocol ';
        ErrorMatchMsg: Label 'Error Messages must match.';
        ErrorTxt: Label '%1 must be';
        ExpectedTxt: Label '%1 of';
        InvisibleAndCapitalMsg: Label 'Nature of the Payment is invisible- and capital transactions, Description Payment must be filled in.';
        PaymentTransitoMsg: Label 'Nature of the Payment is transito trade, Item No. and Traders No. must be filled in.';
        SepaTxt: Label 'SEPA Allowed cannot be No for Bank Country/Region Code:NL.';
        SerialNoErr: Label 'Serial No. (Entry) must be filled in. Enter a value.';
        SWIFTCodeTxt: Label 'SWIFT Code must not exceed 11 characters.';
        OwnAccountMsg: Label 'Nature of the Payment is transfer or sundry, Description Payment and Registration No. DNB must be filled in.';
        ProposalLinesQst: Label 'Process proposal lines?';
        WrongIBANErr: Label 'Wrong number in the field IBAN.';
        LibraryHumanResource: Codeunit "Library - Human Resource";
        AccountType: Option Vendor,Customer,Employee;
        WrongValueReturnedErr: Label 'Function returned wrong value';
        ExceedsMaximumLimitErr: Label '%1 exceeds the maximum limit, %2 must be entered. The default value is ''goods''.';
        WrongShortcutDimensionErr: Label 'Wrong Shortcut Dimension Code in Proposal Line.';
        ForeignAmountRecalculatedCorrectlyErr: Label 'Foreign Amount should be recalculated correctly.';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProposalLineIBANConfirmYes()
    begin
        AssignNewIBANnumber(true);
    end;

    [Test]
    [HandlerFunctions('IBANConfirmHandler')]
    [Scope('OnPrem')]
    procedure ProposalLineIBANConfirmNo()
    begin
        AssignNewIBANnumber(false);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccWithBlankCountryTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Test to Verify Error on Telebank Proposal page with blank Country/Region Code on Bank Account.
        UpdateBankAccAndGetEntriesOnTelebankProposal(
          BankAccount.FieldNo("Country/Region Code"), '', StrSubstNo(ErrorTxt, BankAccount.FieldCaption("Country/Region Code")));  // Country/Region Code as blank.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccWithBlankIBANTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO 226711] Error is generated on Telebank Proposal page with blank IBAN on SEPA Bank Account.
        UpdateBankAccAndGetEntriesOnTelebankProposal(BankAccount.FieldNo(IBAN), '', StrSubstNo(ErrorTxt, BankAccount.FieldCaption(IBAN)));  // IBAN as blank.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccWithBlankSWIFTCodeTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO 226711] Error is generated on Telebank Proposal page with blank SWIFT Code on SEPA Bank Account.
        UpdateBankAccAndGetEntriesOnTelebankProposal(
          BankAccount.FieldNo("SWIFT Code"), '', StrSubstNo(ErrorTxt, BankAccount.FieldCaption("SWIFT Code")));  // SWIFT Code as blank.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccWithCurrencyTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
    begin
        // [SCENARIO 363009] There is no currency check error on Telebank Proposal page after update Currency Code on Bank Account.
        asserterror UpdateBankAccAndGetEntriesOnTelebankProposal(BankAccount.FieldNo("Currency Code"), CreateCurrency(), '');
        Assert.ExpectedErrorCode('RecordNotFound');
        Assert.ExpectedError('The Freely Transferable Maximum does not exist');
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccWithBlankBankAccNoTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
        VendorBankAccount: Record "Vendor Bank Account";
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
        TelebankProposal: TestPage "Telebank Proposal";
    begin
        // [SCENARIO 226711] No any error generated on Telebank Proposal page with blank Bank Account No on Bank Account.
        Initialize();

        // [GIVEN] Posted Vendor invoice with Vendor Bank Account
        // [GIVEN] SEPA Bank Account with blank Bank Account No. field has Check SEPA ISO20022 codeunit in Export Protocol
        PostVendorInvoiceUpdateSEPABankAccount(BankAccount.FieldNo("Bank Account No."), '', VendorBankAccount); // Bank Account No. as blank.
        CreateFreelyTransMaximumWithAmount(VendorBankAccount."Country/Region Code", LibraryRandom.RandDecInRange(1000, 2000, 2));
        LibraryVariableStorage.Enqueue(VendorBankAccount."Vendor No."); // Enqueue for GetProposalEntriesRequestPageHandler.

        // [WHEN] Run Get Entries on Telebank Proposal Page.
        GetEntriesOnTelebankProposal(TelebankProposal, VendorBankAccount."Bank Account No.");

        // [THEN] Verify: Verify Error on Telebank Proposal Page.
        TelebankProposal.Message.AssertEquals('');

        // teardown
        FreelyTransferableMaximum.Get(VendorBankAccount."Country/Region Code", '');
        FreelyTransferableMaximum.Delete();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccWithBlankNameTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Test to Verify Error on Telebank Proposal page with blank Account Holder Name on Bank Account.
        UpdateBankAccAndGetEntriesOnTelebankProposal(
          BankAccount.FieldNo("Account Holder Name"), '', StrSubstNo(ExpectedTxt, BankAccount.FieldCaption("Account Holder Name")));  // Account Holder Name as blank.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccWithBlankAddressTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Test to Verify Error on Telebank Proposal page with blank Account Holder Address on Bank Account.
        UpdateBankAccAndGetEntriesOnTelebankProposal(
          BankAccount.FieldNo("Account Holder Address"), '', StrSubstNo(ExpectedTxt, BankAccount.FieldCaption("Account Holder Address")));  // Account Holder Address as blank.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccWithBlankPostCodeTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Test to Verify Error on Telebank Proposal page with blank Account Holder Post Code on Bank Account.
        UpdateBankAccAndGetEntriesOnTelebankProposal(
          BankAccount.FieldNo("Account Holder Post Code"), '', StrSubstNo(ExpectedTxt, BankAccount.FieldCaption("Account Holder Post Code")));  // Account Holder Post Code as blank.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccWithBlankCityTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
    begin
        // Test to Verify Error on Telebank Proposal page with blank Account Holder City on Bank Account.
        UpdateBankAccAndGetEntriesOnTelebankProposal(
          BankAccount.FieldNo("Account Holder City"), '', StrSubstNo(ExpectedTxt, BankAccount.FieldCaption("Account Holder City")));  // Account Holder City as blank.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerEmployee,MessageHandler')]
    [Scope('OnPrem')]
    procedure EmployeeWithBlankIBANTelebankProposalError()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with blank IBAN on Vendor Bank Account.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostEmployeeExpenseAndGetEntriesOnTelebankProposal(
          true, '', CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
          CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit, StrSubstNo(ErrorTxt, CompanyInformation.FieldCaption(IBAN)));  // IBAN as blank. SEPAAllowed as True.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerEmployee,MessageHandler')]
    [Scope('OnPrem')]
    procedure EmployeeWithSEPAAllowedAsFalseOnCountryRegion()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with SEPA Allowed as false on Country/Region.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostEmployeeExpenseAndGetEntriesOnTelebankProposal(
          false, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
          CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit, SepaTxt);  // SEPAAllowed as False.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerEmployee,MessageHandler')]
    [Scope('OnPrem')]
    procedure EmployeeWithBlankSWIFTCodeTelebankProposalError()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with blank SWIFT Code on Vendor Bank Account.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostEmployeeExpenseAndGetEntriesOnTelebankProposal(
          true, CompanyInformation.IBAN, '', CompanyInformation."Country/Region Code",
          CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit, StrSubstNo(
            ErrorTxt, CompanyInformation.FieldCaption("SWIFT Code")));  // SWIFT Code as blank. SEPAAllowed as True.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerEmployee,MessageHandler')]
    [Scope('OnPrem')]
    procedure EmployeeWithSWIFTCodeTelebankProposalError()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with SWIFT Code more than 11 characters on Vendor Bank Account.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostEmployeeExpenseAndGetEntriesOnTelebankProposal(
          true, CompanyInformation.IBAN,
          CopyStr(CompanyInformation."SWIFT Code" + CompanyInformation."SWIFT Code", 1, MaxStrLen(CompanyInformation."SWIFT Code")),
          CompanyInformation."Country/Region Code", CompanyInformation.City,
          GetCheckID(), TransactionMode.Order::Debit, SWIFTCodeTxt);   // Large value of SWIFT Code required.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendBankAccWithBlankIBANTelebankProposalError()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with blank IBAN on Vendor Bank Account.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostPurchaseInvAndGetEntriesOnTelebankProposal(
          true, '', CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code", CompanyInformation."Country/Region Code",
          CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit, StrSubstNo(ErrorTxt, CompanyInformation.FieldCaption(IBAN)));  // IBAN as blank. SEPAAllowed as True.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendBankAccWithBlankSWIFTCodeTelebankProposalError()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with blank SWIFT Code on Vendor Bank Account.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostPurchaseInvAndGetEntriesOnTelebankProposal(
          true, CompanyInformation.IBAN, '', CompanyInformation."Country/Region Code", CompanyInformation."Country/Region Code",
          CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit, StrSubstNo(
            ErrorTxt, CompanyInformation.FieldCaption("SWIFT Code")));  // SWIFT Code as blank. SEPAAllowed as True.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendBankAccWithSWIFTCodeTelebankProposalError()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with SWIFT Code more than 11 characters on Vendor Bank Account.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostPurchaseInvAndGetEntriesOnTelebankProposal(
          true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code" + CompanyInformation."SWIFT Code",
          CompanyInformation."Country/Region Code", CompanyInformation."Country/Region Code", CompanyInformation.City,
          GetCheckID(), TransactionMode.Order::Debit, SWIFTCodeTxt);   // Large value of SWIFT Code required.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendBankAccWithBlankCountryTelebankProposalError()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with blank Country/Region Code on Vendor Bank Account.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostPurchaseInvAndGetEntriesOnTelebankProposal(
          false, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", '', CompanyInformation."Country/Region Code",
          CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit,
          CompanyInformation.FieldCaption("Bank Account No."));  // Country/Region as blank. SEPAAllowed as False.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendBankAccWithSEPAAllowedAsFalseOnCountryRegion()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with SEPA Allowed as false on Country/Region.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostPurchaseInvAndGetEntriesOnTelebankProposal(
          false, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
          CompanyInformation."Country/Region Code", CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit, SepaTxt);  // SEPAAllowed as False.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendBankAccWithBlankAccHoldTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with blank Acc. Hold Country/Region Code on Vendor Bank Account.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostPurchaseInvAndGetEntriesOnTelebankProposal(
          true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code", '',
          CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit, BankAccount.FieldCaption("Acc. Hold. Country/Region Code"));  // Acc. Hold Country/Region as blank.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VendBankAccWithBlankCityTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with blank Acc. Hold City on Vendor Bank Account.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostPurchaseInvAndGetEntriesOnTelebankProposal(
          true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
          CompanyInformation."Country/Region Code", '', GetCheckID(), TransactionMode.Order::Debit,
          BankAccount.FieldCaption("Account Holder City"));  // Acc. Hold City as blank.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExportProtocolWithNoCheckIDTelebankProposalError()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with No Check ID on Export Protocol.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostPurchaseInvAndGetEntriesOnTelebankProposal(
          true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
          CompanyInformation."Country/Region Code", CompanyInformation.City, 0, TransactionMode.Order::Debit, CheckIDTxt);  // SEPAAllowed as True. Using 0 for CheckID.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TransactionModeWithOrdCreditTelebankProposalError()
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // Test to Verify Error on Telebank Proposal page with Order as credit On Transaction Mode.
        // Setup.
        Initialize();
        CompanyInformation.Get();

        // Exercise and Verify.
        PostPurchaseInvAndGetEntriesOnTelebankProposal(
          true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
          CompanyInformation."Country/Region Code", CompanyInformation.City, GetCheckID(), TransactionMode.Order::Credit,
          StrSubstNo(ErrorTxt, BankAccount.FieldCaption(Amount)));  // SEPAAllowed as True.
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBankAccWithCurrencyTelebankProposalError()
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        // [SCENARIO 363009] There is no currency check error on Telebank Proposal page with Currency Euro on General Ledger Setup.
        // Setup.
        Initialize();
        CompanyInformation.Get();
        UpdateGeneralLedgerSetup(CreateCurrency());

        // Exercise and Verify.
        asserterror PostPurchaseInvAndGetEntriesOnTelebankProposal(
            true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
            CompanyInformation."Country/Region Code", CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit, '');
        Assert.ExpectedErrorCode('RecordNotFound');
        Assert.ExpectedError('The Freely Transferable Maximum does not exist');
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendBankAccWithBlankCurrencyTelebankProposalError()
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TransactionMode: Record "Transaction Mode";
    begin
        // [SCENARIO 363009] There is no currency check error on Telebank Proposal page with blank Currency Euro on General Ledger Setup.
        // Setup.
        Initialize();
        CompanyInformation.Get();
        UpdateGeneralLedgerSetup('');  // Currency Euro as blank.

        // Exercise and Verify.
        asserterror PostPurchaseInvAndGetEntriesOnTelebankProposal(
            true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
            CompanyInformation."Country/Region Code", CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit,
            StrSubstNo(ErrorTxt, GeneralLedgerSetup.FieldCaption("Currency Euro")));
        Assert.ExpectedErrorCode('RecordNotFound');
        Assert.ExpectedError('The Freely Transferable Maximum does not exist');
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure NatureOfPaymentBlankProcessErr()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Test to Verify Error Blank Type Nature of the Payment during Process of Propsal Line for Code Unit No. 11000010 - Check SEPA ISO20022
        NatureOfPaymentProcessErr(ProposalLine."Nature of the Payment"::" ", AmountExceedsMsg);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure NatureOfPaymentTransitoTradeProcessErr()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Test to Verify Error Transito Trade Type Nature of the Payment during Process of Propsal Line for Code Unit No. 11000010 - Check SEPA ISO20022
        NatureOfPaymentProcessErr(ProposalLine."Nature of the Payment"::"Transito Trade", PaymentTransitoMsg);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure NatureOfPmtInvisibleAndCapitalTransacProcessErr()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Test to Verify Error Invisible and Capital Transactions Type Nature of the Payment during Process of Propsal Line for Code Unit No. 11000010 - Check SEPA ISO20022
        NatureOfPaymentProcessErr(
          ProposalLine."Nature of the Payment"::"Invisible- and Capital Transactions", InvisibleAndCapitalMsg);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure NatureOfPmtTransferToOwnAccountProcessErr()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Test to Verify Error Transfer To Own Account Type Nature of the Payment during Process of Propsal Line for Code Unit No. 11000010 - Check SEPA ISO20022
        NatureOfPaymentProcessErr(ProposalLine."Nature of the Payment"::"Transfer to Own Account", OwnAccountMsg);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure NatureOfPmtOtherRegistratedBFIProcessErr()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Test to Verify Error Other Registrated BFI Type Nature of the Payment during Process of Propsal Line for Code Unit No. 11000010 - Check SEPA ISO20022
        NatureOfPaymentProcessErr(ProposalLine."Nature of the Payment"::"Other Registrated BFI", OwnAccountMsg);
    end;

    local procedure NatureOfPaymentProcessErr(NatureOfThePayment: Option; ErrorMessage: Text)
    var
        CompanyInformation: Record "Company Information";
        VendorBankAccount: Record "Vendor Bank Account";
        ProposalLine: Record "Proposal Line";
        TelebankProposal: TestPage "Telebank Proposal";
        CurrencyCode: Code[10];
    begin
        // Setup: Create Bank Account, Create and post Purchase Invoice and  Get Entries on Telebank Proposal Page.
        Initialize();
        CompanyInformation.Get();
        CurrencyCode := CreateCurrency();
        UpdateGeneralLedgerSetup(CurrencyCode);
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
        SetupForProposalLine(VendorBankAccount, CompanyInformation, CurrencyCode);
        GetEntriesOnTelebankProposal(TelebankProposal, VendorBankAccount."Bank Account No.");
        UpdateProposalLine(
          ProposalLine, VendorBankAccount."Bank Account No.", VendorBankAccount."Vendor No.", NatureOfThePayment,
          CurrencyCode);

        // Exercise: Run Process on Telebank Proposal Page.
        TelebankProposal.Process.Invoke();

        // Verify: Verify Error on Code Unit No. 11000010 - Check SEPA ISO20022.
        VerifyProposalLineErrorMesage(VendorBankAccount."Bank Account No.", VendorBankAccount."Vendor No.", ErrorMessage);

        // TearDown: TearDown Freely Transferable Maximum Table and Close Telebank Proposal Page.
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", CurrencyCode);
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
        TelebankProposal.Close();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NatureOfPaymentBlankCheckErr()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Test to Verify Error Blank Type Nature of the Payment during Check of Propsal Line for Code Unit No. 11000010 - Check SEPA ISO20022
        NatureOfPaymentCheckErr(ProposalLine."Nature of the Payment"::" ", AmountExceedsMsg);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NatureOfPaymentTransitoTradeCheckErr()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Test to Verify Error Transito Trade Type Nature of the Payment during Check of Propsal Line for Code Unit No. 11000010 - Check SEPA ISO20022
        NatureOfPaymentCheckErr(ProposalLine."Nature of the Payment"::"Transito Trade", PaymentTransitoMsg);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NatureOfPmtInvisibleAndCapitalTransacCheckErr()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Test to Verify Error Invisible and Capital Transactions Type Nature of the Payment during Check of Propsal Line for Code Unit No. 11000010 - Check SEPA ISO20022
        NatureOfPaymentCheckErr(
          ProposalLine."Nature of the Payment"::"Invisible- and Capital Transactions", InvisibleAndCapitalMsg);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NatureOfPmtTransferToOwnAccountCheckErr()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Test to Verify Error Transfer To Own Account Type Nature of the Payment during Check of Propsal Line for Code Unit No. 11000010 - Check SEPA ISO20022
        NatureOfPaymentCheckErr(ProposalLine."Nature of the Payment"::"Transfer to Own Account", OwnAccountMsg);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure NatureOfPmtOtherRegistratedBFICheckErr()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Test to Verify Error Other Registrated BFI Type Nature of the Payment during Check of Propsal Line for Code Unit No. 11000010 - Check SEPA ISO20022
        NatureOfPaymentCheckErr(ProposalLine."Nature of the Payment"::"Other Registrated BFI", OwnAccountMsg);
    end;

    local procedure NatureOfPaymentCheckErr(NatureOfThePayment: Option; ErrorMessage: Text)
    var
        CompanyInformation: Record "Company Information";
        VendorBankAccount: Record "Vendor Bank Account";
        ProposalLine: Record "Proposal Line";
        TelebankProposal: TestPage "Telebank Proposal";
        CurrencyCode: Code[10];
    begin
        // Setup: Create Bank Account, Create and post Purchase Invoice and  Get Entries on Telebank Proposal Page.
        Initialize();
        CurrencyCode := CreateCurrency();
        CompanyInformation.Get();
        UpdateGeneralLedgerSetup(CurrencyCode);
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
        SetupForProposalLine(VendorBankAccount, CompanyInformation, CurrencyCode);
        GetEntriesOnTelebankProposal(TelebankProposal, VendorBankAccount."Bank Account No.");
        UpdateProposalLine(
          ProposalLine, VendorBankAccount."Bank Account No.", VendorBankAccount."Vendor No.", NatureOfThePayment,
          CurrencyCode);

        // Exercise: Run Check on Telebank Proposal Page.
        TelebankProposal.Check.Invoke();

        // Verify: Verify Error on Code Unit No. 11000010 - Check SEPA ISO20022.
        VerifyProposalLineErrorMesage(VendorBankAccount."Bank Account No.", VendorBankAccount."Vendor No.", ErrorMessage);

        // TearDown: TearDown Freely Transferable Maximum Table and Close Telebank Proposal Page.
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", CurrencyCode);
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
        TelebankProposal.Close();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,VendorLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ProposalDetailLineSeriolNoErr()
    var
        CompanyInformation: Record "Company Information";
        VendorBankAccount: Record "Vendor Bank Account";
        ProposalDetailLine: TestPage "Proposal Detail Line";
        TelebankProposal: TestPage "Telebank Proposal";
        DummyCurrencyCode: Code[10];
    begin
        // Test to Verify error in case of set Serial No. as 0 on Propsal Detail Line.

        // Setup: Create Bank Account, Create and post Purchase Invoice and open Proposal Detail line page.
        Initialize();
        CompanyInformation.Get();
        UpdateGeneralLedgerSetup(DummyCurrencyCode);
        SetupForProposalLine(VendorBankAccount, CompanyInformation, DummyCurrencyCode);
        GetEntriesOnTelebankProposal(TelebankProposal, VendorBankAccount."Bank Account No.");
        OpenProposalDetailLine(ProposalDetailLine, VendorBankAccount."Vendor No.");

        // Exercise: Set Serial No. 0 on Proposal Detail Line page.
        asserterror ProposalDetailLine.Control2."Serial No. (Entry)".SetValue(0);

        // Verify: Verify error in case of set Serial No. as 0.
        Assert.ExpectedError(SerialNoErr);

        // TearDown: TearDown Freely Transferable Maximum Table and Close Telebank Proposal Page.
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", DummyCurrencyCode);
        ProposalDetailLine.Close();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,VendorLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ProposalDetailLineUpdateDescription()
    var
        CompanyInformation: Record "Company Information";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TelebankProposal: TestPage "Telebank Proposal";
        ProposalDetailLine: TestPage "Proposal Detail Line";
        DummyCurrencyCode: Code[10];
        DocumentNo: Code[20];
    begin
        // Test to Verify Description after changed description detail on Propsal Detail Line.

        // Setup: Create Bank Account, Create and post Purchase Invoice and open and delete first entry on Proposal Detail line page.
        Initialize();
        CompanyInformation.Get();
        UpdateGeneralLedgerSetup(DummyCurrencyCode);
        SetupForProposalLine(VendorBankAccount, CompanyInformation, DummyCurrencyCode);
        DocumentNo := CreateAndPostPurchaseInvoice(VendorBankAccount."Vendor No.");
        GetEntriesOnTelebankProposal(TelebankProposal, VendorBankAccount."Bank Account No.");
        DeleteDetailLine(ProposalDetailLine, VendorBankAccount."Vendor No.");

        // Exercise: Call action Update Description on on Proposal Detail Line page.
        ProposalDetailLine.UpdateDescriptions.Invoke();

        // Verify: Verify Description on Proposal Detail Line page.
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        ProposalDetailLine."Description 1".AssertEquals(VendorLedgerEntry.Description);

        // TearDown: TearDown Freely Transferable Maximum Table and Close Telebank Proposal Page.
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
        ProposalDetailLine.Close();
        TelebankProposal.Close();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateTransactionDateInProcess()
    var
        CompanyInformation: Record "Company Information";
        VendorBankAccount: Record "Vendor Bank Account";
        ProposalLine: Record "Proposal Line";
        DetailLine: Record "Detail Line";
        TelebankProposal: TestPage "Telebank Proposal";
        CurrencyCode: Code[10];
    begin
        // Test to Verify updated Transaction Date in Detail Line.

        // Setup: Create Bank Account, Create and post Purchase Invoice and  Get Entries on Telebank Proposal Page.
        Initialize();
        CompanyInformation.Get();
        CurrencyCode := CreateCurrency();
        UpdateGeneralLedgerSetup(CurrencyCode);
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
        SetupForProposalLine(VendorBankAccount, CompanyInformation, CurrencyCode);
        GetEntriesOnTelebankProposal(TelebankProposal, VendorBankAccount."Bank Account No.");
        UpdateProposalLine(
          ProposalLine, VendorBankAccount."Bank Account No.", VendorBankAccount."Vendor No.", ProposalLine."Nature of the Payment"::" ",
          CurrencyCode);
        TelebankProposal."Transaction Date".SetValue(Format(CalcDate('<1M>', WorkDate())));

        // Exercise: Run Process on Telebank Proposal Page.
        TelebankProposal.Process.Invoke();

        // Verify: Verify Transaction Date on Detail Line.
        DetailLine.SetRange("Account No.", VendorBankAccount."Vendor No.");
        DetailLine.FindFirst();
        DetailLine.TestField(Date, CalcDate('<1M>', WorkDate()));

        // TearDown: TearDown Freely Transferable Maximum Table and Close Telebank Proposal Page.
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", CurrencyCode);
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
        TelebankProposal.Close();
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,VendorNoOnVendorCardPageHandler,VendorNoOnVendorLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure LookupFromPaymentHistoryCardWithVendorAccountType()
    begin
        // Test to Verify page Vendor Card and Vendor Ledger Entries openned correctly
        // when lookup from Payment History Card with Account Type=Vendor on the line.
        LookupFromPaymentHistoryCard(AccountType::Vendor);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,CustomerNoOnCustomerCardPageHandler,CustomerNoOnCustomerLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure LookupFromPaymentHistoryCardWithCustomerAccountType()
    begin
        // Test to Verify page Customer Card and Customer Ledger Entries openned correctly
        // when lookup from Payment History Card with Account Type=Customer on the line.
        LookupFromPaymentHistoryCard(AccountType::Customer);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler,EmployeeNoOnEmployeeCardPageHandler,EmployeeNoOnEmployeeLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure LookupFromPaymentHistoryCardWithEmployeeAccountType()
    begin
        // Test to Verify page Employee Card and Employee Ledger Entries openned correctly
        // when lookup from Payment History Card with Account Type=Vendor on the line.
        LookupFromPaymentHistoryCard(AccountType::Employee);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FreelyTransMaximumOnDiffAccHoldCountryRegion()
    var
        ProposalLine: Record "Proposal Line";
    begin
        // Setup: Initialize proposal line with different country region codes and limits according to factors.
        Initialize();
        InitProposalLineWithDiffCountryRegionCodes(ProposalLine);

        SetGLSetupEmptyLocalCurrency();

        // Exercise: Run codeunit for check.
        CODEUNIT.Run(CODEUNIT::"Check SEPA ISO20022", ProposalLine);

        // Verify: Error message assigned inside of codeunit.
        Assert.ExpectedMessage(
          StrSubstNo(ExceedsMaximumLimitErr, ProposalLine.FieldCaption(Amount), ProposalLine.FieldCaption("Nature of the Payment")),
          ProposalLine."Error Message");
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExDocNoMaximumLengthValueCheck()
    var
        CompanyInformation: Record "Company Information";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PaymentHistoryLine: Record "Payment History Line";
        CurrencyCode: Code[10];
        BankAccountNo: Code[20];
        AccountNo: Code[20];
        ExDocNoMaxLength: Code[35];
    begin
        // Setup: Create Bank Account, Create and post Invoice and Get Telebank Proposal Entries.
        Initialize();
        CompanyInformation.Get();
        CurrencyCode := CreateCurrency();
        UpdateGeneralLedgerSetup(CurrencyCode);
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
        SetupForProposalLineWithAccountType(AccountType, CompanyInformation, CurrencyCode, BankAccountNo, AccountNo);
        SetupForPaymentHistory(
          CompanyInformation."Country/Region Code", CurrencyCode, BankAccountNo, AccountNo);
        // Generate VLE."External Document No." with maximum length
        ExDocNoMaxLength :=
          LibraryUtility.GenerateRandomText(
            LibraryUtility.GetFieldLength(DATABASE::"Vendor Ledger Entry",
              VendorLedgerEntry.FieldNo("External Document No.")));
        VendorLedgerEntry.SetRange("Vendor No.", AccountNo);
        VendorLedgerEntry.ModifyAll("External Document No.", ExDocNoMaxLength);
        // Check GetUnstrRemitInfo processes "External Document No" of maximum length
        PaymentHistoryLine.SetRange("Account Type", PaymentHistoryLine."Account Type"::Vendor);
        PaymentHistoryLine.SetRange("Account No.", AccountNo);
        PaymentHistoryLine.FindFirst();
        Assert.AreEqual(ExDocNoMaxLength, PaymentHistoryLine.GetUnstrRemitInfo(), WrongValueReturnedErr);
        // TearDown: TearDown Freely Transferable Maximum Table and Close Telebank Proposal Page.
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", CurrencyCode);
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateDimensionInProposalForVendor()
    var
        ProposalLine: Record "Proposal Line";
        Vendor: Record Vendor;
        VendorBankAccountCode: Code[20];
        BankAccountNo: Code[20];
        DefaultDimension1Code: Code[20];
        DefaultDimension2Code: Code[20];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 122001] "Shorcut Dimension 1 Code" and "Shortcut Dimension 2 Code" of Proposal Line contains values of default dimensions for Vendor
        Initialize();
        // [GIVEN] Vendor and Bank Account with same default dimension, but different dimension value
        // [GIVEN] Value of "Shortcut Dimension 1 Code" = "X1", value of "Shortcut Dimension 2 Code" = "X2" in "Default Dimension" for vendor
        CreateVendorAndBankAccountWithDefaultDimension(Vendor, BankAccountNo, VendorBankAccountCode,
          DefaultDimension1Code, DefaultDimension2Code);
        // [GIVEN] "Proposal Line" - "PL"
        CreateProposalLineVendor(ProposalLine, Vendor."No.", BankAccountNo);
        // [WHEN] Validate Bank of Proposal Line
        ProposalLine.Validate(Bank, VendorBankAccountCode);
        // [THEN] PL."Shorcut Dimension 1 Code" = X1 and PL."Shortcut Dimension 2 Code" = X2
        VerifyDimensionsInProposalLine(ProposalLine, DATABASE::Vendor, Vendor."No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateDimensionInProposalForCustomer()
    var
        ProposalLine: Record "Proposal Line";
        Customer: Record Customer;
        BankAccountNo: Code[20];
        CustomerBankAccountCode: Code[20];
        DefaultDimension1Code: Code[20];
        DefaultDimension2Code: Code[20];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 122001] Fields "Shorcut Dimension 1 Code" and "Shortcut Dimension 2 Code" of Proposal Line contains values of default dimensions for Customer
        Initialize();
        // [GIVEN] Customer Bank Account and Bank Account with same dimension, but different dimension value
        // [GIVEN] Value of "Shortcut Dimension 1 Code" = "X1", value of "Shortcut Dimension 2 Code" = "X2" in "Default Dimension" for customer
        CreateCustomerAndBankAccountWithDefaultDimension(Customer, BankAccountNo, CustomerBankAccountCode,
          DefaultDimension1Code, DefaultDimension2Code);
        // [GIVEN] "Proposal Line" - "PL"
        CreateProposalLineCustomer(ProposalLine, Customer."No.", BankAccountNo);
        // [WHEN] Validate Bank of Proposal Line
        ProposalLine.Validate(Bank, CustomerBankAccountCode);
        // [THEN] PL."Shorcut Dimension 1 Code" = X1 and PL."Shortcut Dimension 2 Code" = X2
        VerifyDimensionsInProposalLine(ProposalLine, DATABASE::Customer, Customer."No.");
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerSetValueDate,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetProposalEntriesRespectsCurrencyAmountRoundingPrecision()
    var
        ProposalLine: Record "Proposal Line";
        PurchaseHeader: Record "Purchase Header";
        Currency: Record Currency;
        VendorNo: Code[20];
        Amount: Decimal;
        AmountInclVAT: Decimal;
        VATRate: Decimal;
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [Report] [Get Proposal Entries] [Rounding]
        // [SCENARIO 229408] When report "Get Proposal Entries" is run for FCY Posted Purchase Invoice, then "Foreign Amount" in Proposal Line is rounded with respect to "Amount Rounding Precision" of Currency.
        Initialize();
        ExchangeRate := 132.073876;
        Amount := 21111;
        VATRate := 19;

        // [GIVEN] Currency "C" with "Amount Rounding Precision" = 1
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Amount Rounding Precision", 1);
        Currency.Modify(true);

        // [GIVEN] Exchange Rate "ER" for "C" equals to 132.073876
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), ExchangeRate, LibraryRandom.RandInt(3));

        // [GIVEN] FCY Posted Purchase Invoice with one Line "PL", having Amount = 21111, "VAT %" = 19 and "Amount Including VAT" = ROUND(Amount * (1 + VATRate / 100),"C"."Amount Rounding Precision") = ROUND(21111 * 1.19,1) = 25122
        VendorNo := CreateVendorWithBankAccount('');
        AmountInclVAT := CreatePurchaseInvoiceWithAmountAndCurrency(
            PurchaseHeader, VendorNo, Amount, 1, VATRate, Currency.Code);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run report "Get Proposal Entries"
        RunReportGetProposalEntries(VendorNo);

        // [THEN] Proposal Line has Foreign Amount = ROUND(ROUND("PL". "Amount Including VAT" / "ER") * "ER","C"."Amount Rounding Precision") = ROUND(ROUND(25122 / 132.073876) * 132.073876,1) = ROUND(25121.771954,1) = 25122
        ProposalLine.SetRange("Account Type", ProposalLine."Account Type"::Vendor);
        ProposalLine.SetRange("Account No.", VendorNo);
        Assert.RecordCount(ProposalLine, 1);
        ProposalLine.FindFirst();
        ProposalLine.TestField(
          "Foreign Amount", Round(Round(AmountInclVAT / ExchangeRate) * ExchangeRate, Currency."Amount Rounding Precision"));
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerSetValueDate,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetProposalEntriesCombineSimilarEntries()
    var
        ProposalLine: Record "Proposal Line";
        PurchaseHeader: Record "Purchase Header";
        CurrencyCode: Code[10];
        VendorNo: Code[20];
        AmountInclVAT: array[2] of Decimal;
        VATRate: Decimal;
        I: Integer;
    begin
        // [FEATURE] [Report] [Get Proposal Entries]
        // [SCENARIO 230434] When report "Get Proposal Entries" is run for two similar FCY Posted Purchase Invoices [1] and [2], then one Proposal Line is created with Amount = [1].Total Amount + [2].Total Amount
        Initialize();
        VATRate := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Vendor, transactions go through "Our bank" with FCY
        CurrencyCode :=
          LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInRange(2, 100, 2), LibraryRandom.RandInt(3));
        VendorNo := CreateVendorWithBankAccount(CurrencyCode);

        // [GIVEN] FCY Posted Purchase Invoice [1] with one line, having Amount = 10, VAT % = 10, Amount Including VAT = "XX" = 11
        // [GIVEN] FCY Posted Purchase Invoice [2] with one line, having Amount = 20, VAT % = 10, Amount Including VAT = "YY" = 22
        for I := 1 to 2 do begin
            AmountInclVAT[I] := CreatePurchaseInvoiceWithAmountAndCurrency(
                PurchaseHeader, VendorNo, LibraryRandom.RandDecInRange(1000, 2000, 2), 1, VATRate, CurrencyCode);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        end;

        // [WHEN] Run report "Get Proposal Entries"
        RunReportGetProposalEntries(VendorNo);

        // [THEN] Proposal Line has Amount = "XX" + "YY" = 11 + 22 = 33
        ProposalLine.SetRange("Account Type", ProposalLine."Account Type"::Vendor);
        ProposalLine.SetRange("Account No.", VendorNo);
        Assert.RecordCount(ProposalLine, 1);
        ProposalLine.FindFirst();
        ProposalLine.TestField(Amount, AmountInclVAT[1] + AmountInclVAT[2]);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UpdateDimensionInProposalForEmployee()
    var
        ProposalLine: Record "Proposal Line";
        Employee: Record Employee;
        BankAccountNo: Code[20];
        DefaultDimension1Code: Code[20];
        DefaultDimension2Code: Code[20];
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 122001] "Shorcut Dimension 1 Code" and "Shortcut Dimension 2 Code" of Proposal Line contains values of default dimensions for Employee
        Initialize();
        // [GIVEN] Employee with default dimension
        // [GIVEN] Value of "Shortcut Dimension 1 Code" = "X1", value of "Shortcut Dimension 2 Code" = "X2" in "Default Dimension" for employee
        CreateEmployeeAndBankAccountWithDefaultDimension(Employee, BankAccountNo,
          DefaultDimension1Code, DefaultDimension2Code);
        // [GIVEN] "Proposal Line" - "PL"
        CreateProposalLineEmployee(ProposalLine, Employee."No.", BankAccountNo);
        // [WHEN] Validate Bank of Proposal Line
        ProposalLine.Validate(Bank, '');
        // [THEN] PL."Shorcut Dimension 1 Code" = X1 and PL."Shortcut Dimension 2 Code" = X2
        VerifyDimensionsInProposalLine(ProposalLine, DATABASE::Employee, Employee."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProposalLineGetSourceNameCustLength()
    var
        Customer: Record Customer;
        ProposalLine: Record "Proposal Line";
        SourceName: Text;
    begin
        // [FEATURE] [UT] [Proposal Line]
        // [SCENARIO 341996] GetSourceName returns full name of the source on the Proposal Line

        // [GIVEN] Customer "CU01" with Name of maximal field length
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateGUID();
        Customer.Name := LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name));
        Customer.Insert();

        // [GIVEN] Proposal Line "PL1" with "Account Type" = "Customer", "Account No." = "CU01"
        ProposalLine."Line No." := LibraryUtility.GetNewRecNo(ProposalLine, ProposalLine.FieldNo("Line No."));
        ProposalLine."Account Type" := ProposalLine."Account Type"::Customer;
        ProposalLine."Account No." := Customer."No.";
        ProposalLine.Insert();

        // [WHEN] Call GetSourceName on "PL1"
        SourceName := ProposalLine.GetSourceName();

        // [THEN] Full Customer's name retrieved
        Assert.AreEqual(Customer.Name, SourceName, 'Source name not retrieved');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentHistoryLineGetSourceNameCustLength()
    var
        Customer: Record Customer;
        PaymentHistoryLine: Record "Payment History Line";
        SourceName: Text;
    begin
        // [FEATURE] [UT] [Payment History]
        // [SCENARIO 341996] GetSourceName returns full name of the source on the Payment History Line

        // [GIVEN] Customer "CU01" with Name of maximal field length
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateGUID();
        Customer.Name := LibraryUtility.GenerateRandomText(MaxStrLen(Customer.Name));
        Customer.Insert();

        // [GIVEN] Payment History Line "PHL1" with "Account Type" = "Customer", "Account No." = "CU01"
        PaymentHistoryLine."Run No." := LibraryUtility.GenerateGUID();
        PaymentHistoryLine."Line No." := LibraryUtility.GetNewRecNo(PaymentHistoryLine, PaymentHistoryLine.FieldNo("Line No."));
        PaymentHistoryLine."Account Type" := PaymentHistoryLine."Account Type"::Customer;
        PaymentHistoryLine."Account No." := Customer."No.";
        PaymentHistoryLine.Insert();

        // [WHEN] Call GetSourceName on "PHL1"
        SourceName := PaymentHistoryLine.GetSourceName();

        // [THEN] Full Customer's name retrieved
        Assert.AreEqual(Customer.Name, SourceName, 'Source name not retrieved');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure UpdateProposalLineFromCustomerBankAccount()
    var
        ProposalLine: Record "Proposal Line";
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        BankAccountNo: Code[20];
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 420340] Fields IBAN, SWIFT, "Bank Account No.", "Direct Debit Mandate ID" updated in "Proposal Line" from "Customer Bank Account"
        Initialize();
        // [GIVEN] Customer Bank Account 
        // [GIVEN] Value of "Bank Account No." = "BAN1", "Direct Debit Mandate ID" = "DD1", IBAN = "I1", SWIFT = "S1"
        CreateCustomerAndBankAccount(Customer, BankAccountNo, CustomerBankAccount);
        // [GIVEN] "Proposal Line" - "PL"
        CreateProposalLineCustomerBankAccount(ProposalLine, CustomerBankAccount, BankAccountNo);

        // [WHEN] Validate "Customer Bank Account" "Bank Account No." = "BAN2", "Direct Debit Mandate ID" = "DD2", IBAN = "I2", SWIFT = "S2"
        LibraryERM.CreateBankAccount(BankAccount);
        CustomerBankAccount.Validate("Bank Account No.", BankAccount."No.");
        CustomerBankAccount.Validate("Direct Debit Mandate ID", MockSEPADirectDebitMandate(CustomerBankAccount));
        CustomerBankAccount.Validate(
            IBAN,
            LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(IBAN), DATABASE::"Customer Bank Account"));
        CustomerBankAccount.Validate(
            "SWIFT Code",
            LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("SWIFT Code"), DATABASE::"Customer Bank Account"));

        // [THEN] Proposal line has "Bank Account No." = "BAN2", "Direct Debit Mandate ID" = "DD2", IBAN = "I2", SWIFT = "S2"
        ProposalLine.Find();
        ProposalLine.TestField("Bank Account No.", CustomerBankAccount."Bank Account No.");
        ProposalLine.TestField("Direct Debit Mandate ID", CustomerBankAccount."Direct Debit Mandate ID");
        ProposalLine.TestField(IBAN, CustomerBankAccount.IBAN);
        ProposalLine.TestField("SWIFT Code", CustomerBankAccount."SWIFT Code");
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerSetValueDate,MessageHandler')]
    procedure ProposalLineAmountWhenCustLedgerEntryWithPartialRemainingPtmDiscount()
    var
        CompanyInformation: Record "Company Information";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ProposalLine: Record "Proposal Line";
        CustomerNo: Code[20];
        PostedDocNo: Code[20];
        RemainingPmtDiscount: Decimal;
        ExpProposalLineAmount: Decimal;
    begin
        // [FEATURE] [Report] [Get Proposal Entries] [Discount] [Sales]
        // [SCENARIO 442611] Proposal Line Amount when run Get Proposal Entries on Customer Ledger Entry with Remaining Pmt. Discount <> Original Pmt. Discount.
        Initialize();
        CompanyInformation.Get();
        LibraryNLLocalization.CheckAndCreateFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');

        // [GIVEN] Customer with Payment Terms.
        // [GIVEN] Payment Terms has Discount % 5 and Discount Date Calculation 5D.
        CustomerNo := CreateCustomerWithBankAccount('');
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        UpdatePaymentTermsOnCustomer(CustomerNo, PaymentTerms.Code);

        // [GIVEN] Posted Sales Invoice with Amount 1000.
        // [GIVEN] Customer Ledger Entry with Original Pmt. Disc. Possible = Remaining Pmt. Disc. Possible = 50 is created.
        // [GIVEN] Customer Ledger Entry has Pmt. Discount Date 01.02.24.
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, CustomerNo);
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Remaining Pmt. Disc. Possible is updated from 50 to 25.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, "Gen. Journal Document Type"::Invoice, PostedDocNo);
        RemainingPmtDiscount := CustLedgerEntry."Remaining Pmt. Disc. Possible";
        CustLedgerEntry.Validate("Remaining Pmt. Disc. Possible", RemainingPmtDiscount - Round(RemainingPmtDiscount / 2, 2));
        CustLedgerEntry.Modify(true);
        Commit();

        // [WHEN] Run report "Get Proposal Entries" with Currency Date = Pmt. Discount Date = 01.02.24.
        RunReportGetProposalEntriesWithCurrencyDateOnCustomer(CustomerNo, CustLedgerEntry."Pmt. Discount Date");

        // [THEN] Proposal Line with Amount = 1000 - 25 = 975 is created.
        CustLedgerEntry.CalcFields("Remaining Amount");
        ExpProposalLineAmount := -(CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible");
        VerifyProposalLineAmount(ProposalLine."Account Type"::Customer, CustomerNo, ExpProposalLineAmount);

        // tear down
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerSetValueDate,MessageHandler')]
    procedure ProposalLineAmountWhenVendorLedgerEntryWithPartialRemainingPtmDiscount()
    var
        CompanyInformation: Record "Company Information";
        PaymentTerms: Record "Payment Terms";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ProposalLine: Record "Proposal Line";
        VendorNo: Code[20];
        PostedDocNo: Code[20];
        RemainingPmtDiscount: Decimal;
        ExpProposalLineAmount: Decimal;
    begin
        // [FEATURE] [Report] [Get Proposal Entries] [Discount] [Purchase]
        // [SCENARIO 442611] Proposal Line Amount when run Get Proposal Entries on Vendor Ledger Entry with Remaining Pmt. Discount <> Original Pmt. Discount.
        Initialize();
        CompanyInformation.Get();
        LibraryNLLocalization.CheckAndCreateFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');

        // [GIVEN] Vendor with Payment Terms.
        // [GIVEN] Payment Terms has Discount % 5 and Discount Date Calculation 5D.
        VendorNo := CreateVendorWithBankAccount('');
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        UpdatePaymentTermsOnVendor(VendorNo, PaymentTerms.Code);

        // [GIVEN] Posted Purchase Invoice with Amount 1000.
        // [GIVEN] Vendor Ledger Entry with Original Pmt. Disc. Possible = Remaining Pmt. Disc. Possible = 50 is created.
        // [GIVEN] Vendor Ledger Entry has Pmt. Discount Date 01.02.24.
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, VendorNo);
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Remaining Pmt. Disc. Possible is updated from 50 to 25.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, "Gen. Journal Document Type"::Invoice, PostedDocNo);
        RemainingPmtDiscount := VendorLedgerEntry."Remaining Pmt. Disc. Possible";
        VendorLedgerEntry.Validate("Remaining Pmt. Disc. Possible", RemainingPmtDiscount - Round(RemainingPmtDiscount / 2, 2));
        VendorLedgerEntry.Modify(true);
        Commit();

        // [WHEN] Run report "Get Proposal Entries" with Currency Date = Pmt. Discount Date = 01.02.24.
        RunReportGetProposalEntriesWithCurrencyDateOnVendor(VendorNo, VendorLedgerEntry."Pmt. Discount Date");

        // [THEN] Proposal Line with Amount = 1000 - 25 = 975 is created.
        VendorLedgerEntry.CalcFields("Remaining Amount");
        ExpProposalLineAmount := -(VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible");
        VerifyProposalLineAmount(ProposalLine."Account Type"::Vendor, VendorNo, ExpProposalLineAmount);

        // tear down
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
    end;

    [Test]
    procedure UseManualNoSeriesForProposalLineIdentification()
    var
        ProposalLine: Record "Proposal Line";
        TransactionMode: Record "Transaction Mode";
        NoSeries: Record "No. Series";
        IdentificationNo: Code[20];
    begin
        // [GIVEN] A transaction mode with a No. Series that uses a manual No. Series
        CreateAndUpdateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer, GetCheckID(), TransactionMode.Order::Credit);
        LibraryUtility.CreateNoSeries(NoSeries, false, true, false);
        TransactionMode."Identification No. Series" := NoSeries.Code;
        TransactionMode.Modify();

        // [GIVEN] A proposal line with Identification being set
        IdentificationNo := '1234';
        ProposalLine."Account Type" := TransactionMode."Account Type";
        ProposalLine."Transaction Mode" := TransactionMode.Code;
        ProposalLine.Validate(Identification, IdentificationNo);

        // [THEN] The Identification is saved
        Assert.AreEqual(IdentificationNo, ProposalLine.Identification, 'Identification code was not set manually');
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerSetValueDate,MessageHandler')]
    procedure ForeignAmountRecalculatedCorrectlyAfterDetailLineDeletion()
    var
        Currency: Record Currency;
        ProposalLine: Record "Proposal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        i: Integer;
        AmountInDocumentCurrency: Decimal;
    begin
        // [SCENARIO 603120] When a Detail Line is deleted from Telebank Proposal, the Foreign Amount on the Proposal Line is recalculated correctly based on the Exchange Rate.
        Initialize();

        // [GIVEN] Create New Currency with Exchange Rate.
        Currency.Get(
            LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInRange(2, 100, 2), LibraryRandom.RandInt(3)));

        // [GIVEN] Create Vendor and Vendor Bank Account with the created Currency.
        CreateVendorAndVendorBankAccount(Vendor, Currency.Code);

        // [GIVEN] Create and Post two Purchase Invoices.
        for i := 1 to 2 do begin
            CreatePurchaseInvoiceWithAmountAndCurrency(
                PurchaseHeader, Vendor."No.", LibraryRandom.RandDecInRange(1000, 2000, 2),
                LibraryRandom.RandInt(10), LibraryRandom.RandInt(20), Vendor."Currency Code");
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        end;

        // [GIVEN] Run Report Get Proposal Entries.
        RunReportGetProposalEntries(Vendor."No.");

        // [WHEN] Delete one Detail Line for the Vendor.
        DeleteDetailLine(Vendor."No.");

        // [GIVEN] Find Proposal Line for the Vendor.
        FindProposalLine(ProposalLine, Vendor."No.");

        // [THEN] Verify Foreign Amount on Proposal Line is recalculated correctly based on the Exchange Rate.
        AmountInDocumentCurrency := CalculateForeignAmount(ProposalLine, Currency);
        Assert.AreEqual(ProposalLine."Foreign Amount", AmountInDocumentCurrency, ForeignAmountRecalculatedCorrectlyErr);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerSetValueDate,MessageHandler')]
    procedure VerifyForeignAmountWhenForeignCurrencyChangedInProposalLine()
    var
        Currency: Record Currency;
        ProposalLine: Record "Proposal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        i: Integer;
        AmountInDocumentCurrency: Decimal;
    begin
        // [SCENARIO 603120] When Foreign Currency is changed in Proposal Line, the Foreign Amount on the Proposal Line is recalculated correctly.
        Initialize();

        // [GIVEN] Create New Currency with Exchange Rate.
        Currency.Get(
            LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDecInRange(2, 100, 2), LibraryRandom.RandInt(3)));

        // [GIVEN] Create Vendor and Vendor Bank Account with the created Currency.
        CreateVendorAndVendorBankAccount(Vendor, Currency.Code);

        // [GIVEN] Create and Post two Purchase Invoices.
        for i := 1 to 2 do begin
            CreatePurchaseInvoiceWithAmountAndCurrency(
                PurchaseHeader, Vendor."No.", LibraryRandom.RandDecInRange(1000, 2000, 2),
                LibraryRandom.RandInt(10), LibraryRandom.RandInt(20), Vendor."Currency Code");
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        end;

        // [GIVEN] Run Report Get Proposal Entries.
        RunReportGetProposalEntries(Vendor."No.");

        // [GIVEN] Find Proposal Line for the Vendor.
        FindProposalLine(ProposalLine, Vendor."No.");

        // [WHEN] Set the Foreign Currency field in the proposal line to blank.
        ProposalLine.Validate("Foreign Currency", '');
        ProposalLine.Modify(true);

        // [THEN] Verify Foreign Amount on Proposal Line shows 0.
        Assert.AreEqual(ProposalLine."Amount (LCY)", ProposalLine."Foreign Amount", ForeignAmountRecalculatedCorrectlyErr);

        // [WHEN] Change the Foreign Currency in the Proposal Line back to the Vendor Currency.
        ProposalLine.Validate("Foreign Currency", Vendor."Currency Code");
        ProposalLine.Modify(true);

        // [THEN] Verify Foreign Amount on Proposal Line is recalculated correctly.
        AmountInDocumentCurrency := CalculateForeignAmount(ProposalLine, Currency);
        Assert.AreEqual(ProposalLine."Foreign Amount", AmountInDocumentCurrency, ForeignAmountRecalculatedCorrectlyErr);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandlerSetValueDate,MessageHandler')]
    procedure ForeignAmountRemainsZeroForSEPAPaymentsAfterDeletingDetailLine()
    var
        ProposalLine: Record "Proposal Line";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        i: Integer;
    begin
        // [SCENARIO 603120] When a Detail Line is deleted from Telebank Proposal, the Foreign Amount is not calculated when Currency Code is not aviliable.
        Initialize();

        // [GIVEN] Create Vendor and Vendor Bank Account with the created Currency.
        CreateVendorAndVendorBankAccount(Vendor, '');

        // [GIVEN] Create and Post two Purchase Invoices.
        for i := 1 to 2 do begin
            CreatePurchaseInvoiceWithAmountAndCurrency(
                PurchaseHeader, Vendor."No.", LibraryRandom.RandDecInRange(1000, 2000, 2),
                LibraryRandom.RandInt(10), LibraryRandom.RandInt(20), Vendor."Currency Code");
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        end;

        // [GIVEN] Run Report Get Proposal Entries.
        RunReportGetProposalEntries(Vendor."No.");

        // [WHEN] Delete one Detail Line for the Vendor.
        DeleteDetailLine(Vendor."No.");

        // [GIVEN] Find Proposal Line for the Vendor.
        FindProposalLine(ProposalLine, Vendor."No.");

        // [THEN] Verify Foreign Amount on Proposal Line is recalculated correctly based on the Exchange Rate.
        Assert.AreEqual(ProposalLine."Foreign Amount", 0, ForeignAmountRecalculatedCorrectlyErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Telebank");
        LibraryVariableStorage.Clear();
        UpdateSWIFTCodeOnCompanyInformation();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Telebank");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Telebank");
    end;

    local procedure CreateAndPostPurchaseInvoice(VendorNo: Code[20]): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader."Vendor Invoice No." := PurchaseHeader."No.";
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Using random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Using random value for Unit Cost.
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchaseInvoiceWithAmountAndCurrency(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DirectUnitCost: Decimal; Quantity: Decimal; VATRate: Decimal; CurrencyCode: Code[10]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATRate);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);

        exit(PurchaseLine."Amount Including VAT");
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2)); // Using random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2)); // Using random value for Unit Cost.
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostEmployeeExpense(Employee: Record Employee)
    var
        GenJournalLine: Record "Gen. Journal Line";
        LibraryJournals: Codeunit "Library - Journals";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Employee, Employee."No.", -LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndUpdateExportProtocol(CheckID: Integer): Code[20]
    var
        ExportProtocol: Record "Export Protocol";
    begin
        LibraryNLLocalization.CreateExportProtocol(ExportProtocol);
        ExportProtocol.Validate("Check ID", CheckID);
        ExportProtocol.Modify(true);
        exit(ExportProtocol.Code);
    end;

    local procedure CreateAndUpdateTransactionMode(var TransactionMode: Record "Transaction Mode"; AccountType: Option Customer,Vendor,Employee; CheckID: Integer; "Order": Option)
    begin
        LibraryNLLocalization.CreateTransactionMode(TransactionMode, AccountType);
        TransactionMode.Validate(Order, Order);
        TransactionMode.Validate("Our Bank", CreateBankAccount());
        TransactionMode.Validate("Export Protocol", CreateAndUpdateExportProtocol(CheckID));
        TransactionMode.Validate("Identification No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        TransactionMode.Validate("Run No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        if AccountType = AccountType::Employee then
            TransactionMode.Validate("Partner Type", TransactionMode."Partner Type"::" ");
        TransactionMode.Modify(true);
    end;

    local procedure RunReportGetProposalEntries(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryVariableStorage.Enqueue(WorkDate());
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        REPORT.Run(REPORT::"Get Proposal Entries", true, false, VendorLedgerEntry);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure RunReportGetProposalEntriesWithCurrencyDateOnVendor(VendorNo: Code[20]; CurrencyDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GetProposalEntries: Report "Get Proposal Entries";
    begin
        LibraryVariableStorage.Enqueue(CurrencyDate);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        CustLedgerEntry.SetRange("Customer No.", '');    // to get rid of Customer Ledger Entries
        GetProposalEntries.SetTableView(CustLedgerEntry);
        GetProposalEntries.SetTableView(VendorLedgerEntry);
        GetProposalEntries.UseRequestPage(true);
        GetProposalEntries.Run();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure RunReportGetProposalEntriesWithCurrencyDateOnCustomer(CustomerNo: Code[20]; CurrencyDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GetProposalEntries: Report "Get Proposal Entries";
    begin
        LibraryVariableStorage.Enqueue(CurrencyDate);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        VendorLedgerEntry.SetRange("Vendor No.", '');    // to get rid of Vendor Ledger Entries
        GetProposalEntries.SetTableView(CustLedgerEntry);
        GetProposalEntries.SetTableView(VendorLedgerEntry);
        GetProposalEntries.UseRequestPage(true);
        GetProposalEntries.Run();
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure UpdateTransactionModeForPaymInProcess(AccountType: Option; TransactionModeCode: Code[20])
    var
        TransactionMode: Record "Transaction Mode";
        SourceCode: Record "Source Code";
    begin
        LibraryERM.CreateSourceCode(SourceCode);
        TransactionMode.Get(AccountType, TransactionModeCode);
        TransactionMode.Validate("Acc. No. Pmt./Rcpt. in Process", CreateBalanceSheetGLAccount());
        TransactionMode.Validate("Posting No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        TransactionMode.Validate("Source Code", SourceCode.Code);
        TransactionMode.Modify(true);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CreateBankAccountLargeNo(BankAccount);
        BankAccount.Validate("Bank Account No.", BankAccountNoTxt);
        BankAccount.Validate(IBAN, CompanyInformation.IBAN);
        BankAccount.Validate("SWIFT Code", CompanyInformation."SWIFT Code");
        BankAccount.Validate("Min. Balance", -LibraryRandom.RandDecInRange(500, 1000, 2));  // Using random value greater than 500 for Min. Balance. Value is important for test.
        BankAccount.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        BankAccount.Validate("Account Holder Name", BankAccount.Name);  // Taking Bank Account Name as Account Holder Name. Value is not important for test.
        BankAccount.Validate("Account Holder Address", BankAccount.Name);  // Taking Bank Account Name as Account Holder Address. Value is not important for test.
        BankAccount.Validate("Account Holder Post Code", CompanyInformation."Country/Region Code");
        BankAccount.Validate("Account Holder City", CompanyInformation."Country/Region Code");
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomerWithBankAccount(BankAccountCurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        TransactionMode: Record "Transaction Mode";
        BankAccount: Record "Bank Account";
    begin
        CreateAndUpdateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer, GetCheckID(), TransactionMode.Order::Credit);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Transaction Mode Code", TransactionMode.Code);
        Customer.Modify(true);

        BankAccount.Get(TransactionMode."Our Bank");
        BankAccount.Validate("Currency Code", BankAccountCurrencyCode);
        BankAccount.Modify(true);

        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.Validate("Bank Account No.", BankAccount."Bank Account No.");
        CustomerBankAccount.Modify(true);

        exit(CustomerBankAccount."Customer No.");
    end;

    local procedure CreateVendorWithBankAccount(BankAccountCurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        TransactionMode: Record "Transaction Mode";
        BankAccount: Record "Bank Account";
    begin
        CreateAndUpdateTransactionMode(TransactionMode, TransactionMode."Account Type"::Vendor, GetCheckID(), TransactionMode.Order::Debit);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Transaction Mode Code", TransactionMode.Code);
        Vendor.Modify(true);

        BankAccount.Get(TransactionMode."Our Bank");
        BankAccount.Validate("Currency Code", BankAccountCurrencyCode);
        BankAccount.Modify(true);

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        VendorBankAccount.Validate("Bank Account No.", BankAccount."Bank Account No.");
        VendorBankAccount.Modify(true);

        exit(VendorBankAccount."Vendor No.");
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20]; BankAccountNo: Code[20]; IBAN: Code[50]; SWIFTCode: Code[20]; CountryRegionCode: Code[10]; AccHoldCountryRegionCode: Code[10]; AccountHolderCity: Text[30])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount.Validate("Country/Region Code", CountryRegionCode);
        VendorBankAccount.Validate("Account Holder City", AccountHolderCity);
        VendorBankAccount.Validate("Acc. Hold. Country/Region Code", AccHoldCountryRegionCode);
        VendorBankAccount.Validate("Bank Account No.", BankAccountNo);
        VendorBankAccount.Validate(IBAN, IBAN);
        VendorBankAccount.Validate("SWIFT Code", SWIFTCode);
        VendorBankAccount.Modify(true);
    end;

    local procedure CreateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; CustomerNo: Code[20]; BankAccountNo: Code[20]; IBANCode: Code[50]; SWIFTCode: Code[20]; CountryRegionCode: Code[10]; AccHoldCountryRegionCode: Code[10]; AccountHolderCity: Text[30])
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, CustomerNo);
        CustomerBankAccount.Validate("Country/Region Code", CountryRegionCode);
        CustomerBankAccount.Validate("Account Holder City", AccountHolderCity);
        CustomerBankAccount.Validate("Acc. Hold. Country/Region Code", AccHoldCountryRegionCode);
        CustomerBankAccount.Validate("Bank Account No.", BankAccountNo);
        CustomerBankAccount.Validate(IBAN, IBANCode);
        CustomerBankAccount.Validate("SWIFT Code", SWIFTCode);
        CustomerBankAccount.Modify(true);
    end;

    local procedure CreateVendorBankAccountAndUpdateVendor(var VendorBankAccount: Record "Vendor Bank Account"; IBAN: Code[50]; SWIFTCode: Code[20]; CountryRegionCode: Code[10]; AccHoldCountryRegionCode: Code[10]; AccountHolderCity: Text[30]; CheckID: Integer; "Order": Option)
    var
        TransactionMode: Record "Transaction Mode";
        Vendor: Record Vendor;
    begin
        CreateAndUpdateTransactionMode(TransactionMode, TransactionMode."Account Type"::Vendor, CheckID, Order);
        LibraryPurchase.CreateVendor(Vendor);
        CreateVendorBankAccount(
          VendorBankAccount, Vendor."No.", TransactionMode."Our Bank", IBAN, SWIFTCode, CountryRegionCode,
          AccHoldCountryRegionCode, AccountHolderCity);
        Vendor.Validate("Transaction Mode Code", TransactionMode.Code);
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Modify(true);
    end;

    local procedure CreateCustomerBankAccountAndUpdateCustomer(var CustomerBankAccount: Record "Customer Bank Account"; IBAN: Code[50]; SWIFTCode: Code[20]; CountryRegionCode: Code[10]; AccHoldCountryRegionCode: Code[10]; AccountHolderCity: Text[30]; CheckID: Integer; "Order": Option)
    var
        TransactionMode: Record "Transaction Mode";
        Customer: Record Customer;
    begin
        CreateAndUpdateTransactionMode(TransactionMode, TransactionMode."Account Type"::Customer, CheckID, Order);
        LibrarySales.CreateCustomer(Customer);
        CreateCustomerBankAccount(
          CustomerBankAccount, Customer."No.", TransactionMode."Our Bank", IBAN, SWIFTCode, CountryRegionCode,
          AccHoldCountryRegionCode, AccountHolderCity);
        Customer.Validate("Transaction Mode Code", TransactionMode.Code);
        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Modify(true);
    end;

    local procedure CreateEmployeeAndUpdateEmployee(var Employee: Record Employee; IBAN: Code[50]; SwiftCode: Code[20]; AccHoldCountryRegionCode: Code[10]; AccountHolderCity: Text[30]; CheckID: Integer; "Order": Option)
    var
        TransactionMode: Record "Transaction Mode";
    begin
        CreateAndUpdateTransactionMode(TransactionMode, TransactionMode."Account Type"::Employee, CheckID, Order);
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        Employee.Validate("Country/Region Code", AccHoldCountryRegionCode);
        Employee.Validate(City, AccountHolderCity);
        Employee.Validate("Transaction Mode Code", TransactionMode.Code);
        Employee.Validate("Bank Account No.", TransactionMode."Our Bank");
        Employee.Validate(IBAN, IBAN);
        Employee.Validate("SWIFT Code", SwiftCode);
        Employee.Modify(true);
    end;

    local procedure DeleteDetailLine(var ProposalDetailLine: TestPage "Proposal Detail Line"; AccountNo: Code[20])
    var
        DetailLine: Record "Detail Line";
    begin
        OpenProposalDetailLine(ProposalDetailLine, AccountNo);
        ProposalDetailLine.Close();
        DetailLine.SetRange("Account No.", AccountNo);
        DetailLine.FindFirst();
        DetailLine.Delete(true);
        ProposalDetailLine.OpenEdit();
        ProposalDetailLine.FILTER.SetFilter("Account No.", AccountNo);
    end;

    local procedure GetCheckID(): Integer
    begin
        exit(CODEUNIT::"Check SEPA ISO20022");
    end;

    local procedure GetEntriesOnTelebankProposal(var TelebankProposal: TestPage "Telebank Proposal"; BankAccFilter: Code[30])
    begin
        Commit();  // Commit Required.
        TelebankProposal.OpenEdit();
        TelebankProposal.BankAccFilter.SetValue(BankAccFilter);
        TelebankProposal.GetEntries.Invoke();
    end;

    local procedure LookupFromPaymentHistoryCard(AccountType: Option)
    var
        CompanyInformation: Record "Company Information";
        PaymentHistoryCard: TestPage "Payment History Card";
        CurrencyCode: Code[10];
        BankAccountNo: Code[20];
        AccountNo: Code[20];
    begin
        // Setup: Create Bank Account, Create and post Invoice and Get Entries on Telebank Proposal Page.
        // Update Freely Transferable Maximum, Proposal Line and Transaction Mode. Run Process on Telebank Proposal Page.
        Initialize();
        CompanyInformation.Get();
        CurrencyCode := CreateCurrency();
        UpdateGeneralLedgerSetup(CurrencyCode);
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
        SetupForProposalLineWithAccountType(AccountType, CompanyInformation, CurrencyCode, BankAccountNo, AccountNo);
        SetupForPaymentHistory(
          CompanyInformation."Country/Region Code", CurrencyCode, BankAccountNo, AccountNo);

        // Open Open Payment History Card.
        OpenPaymentHistoryCard(PaymentHistoryCard, BankAccountNo);

        // Exercise: Call action Card on Payment History Card page.
        // Verify: Verify Vendor Card/Customer Card Page openned correctly.
        LibraryVariableStorage.Enqueue(AccountNo); // Enqueue value for VendorNoOnVendorCardPageHandler/ CustomerNoOnCustomerCardPageHandler
        PaymentHistoryCard.Subform.Card.Invoke(); // Call action Card.

        // Exercise: Call action Ledger Entries on Payment History Card page.
        // Verify: Verify Vendor Ledger Entries/ Customer Ledger Entries Page openned correctly.
        LibraryVariableStorage.Enqueue(AccountNo); // Enqueue value for VendorNoOnVendorLedgerEntriesPageHandler/ CustomerNoOnCustomerLedgerEntriesPageHandler
        PaymentHistoryCard.Subform.LedgerEntries.Invoke(); // Call action Ledger Entries.

        // TearDown: TearDown Freely Transferable Maximum Table and Close Telebank Proposal Page.
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", CurrencyCode);
        RemoveFreelyTransferableMaximum(CompanyInformation."Country/Region Code", '');
        PaymentHistoryCard.Close();
    end;

    local procedure OpenProposalDetailLine(var ProposalDetailLine: TestPage "Proposal Detail Line"; AccountNo: Code[20])
    begin
        ProposalDetailLine.OpenEdit();
        ProposalDetailLine.FILTER.SetFilter("Account No.", AccountNo);
        ProposalDetailLine.Control2."Serial No. (Entry)".Lookup();
    end;

    local procedure OpenPaymentHistoryCard(var PaymentHistoryCard: TestPage "Payment History Card"; OurBank: Code[20])
    begin
        PaymentHistoryCard.OpenEdit();
        PaymentHistoryCard.FILTER.SetFilter("Our Bank", OurBank);
    end;

    local procedure PostPurchaseInvAndGetEntriesOnTelebankProposal(SEPAAllowed: Boolean; IBAN: Code[50]; SWIFTCode: Code[20]; CountryRegionCode: Code[10]; AccHoldCountryRegionCode: Code[10]; AccountHolderCity: Text[30]; CheckID: Integer; "Order": Option; ExpectedMessage: Text[125])
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TelebankProposal: TestPage "Telebank Proposal";
    begin
        // Create Vendor Bank Account. Create and post Purchase Invoice.
        PostPurchaseInvoiceWithVendorBankAccount(
          VendorBankAccount, SEPAAllowed, IBAN, SWIFTCode, CountryRegionCode, AccHoldCountryRegionCode, AccountHolderCity, CheckID, Order);
        LibraryVariableStorage.Enqueue(VendorBankAccount."Vendor No.");  // Enqueue for GetProposalEntriesRequestPageHandler.

        // Exercise: Get Entries on Telebank Proposal page.
        GetEntriesOnTelebankProposal(TelebankProposal, VendorBankAccount."Bank Account No.");

        // Verify: Verify Error on Telebank Proposal Page.
        Assert.IsTrue(StrPos(TelebankProposal.Message.Value, ExpectedMessage) > 0, ErrorMatchMsg);
    end;

    local procedure PostEmployeeExpenseAndGetEntriesOnTelebankProposal(SEPAAllowed: Boolean; IBAN: Code[50]; SWIFTCode: Code[20]; AccHoldCountryRegionCode: Code[10]; AccountHolderCity: Text[30]; CheckID: Integer; "Order": Option; ExpectedMessage: Text[125])
    var
        Employee: Record Employee;
        TelebankProposal: TestPage "Telebank Proposal";
    begin
        // Create Employee with bank account. Create and post Expense.
        PostEmployeeExpenseWithEmployee(
          Employee, SEPAAllowed, IBAN, SWIFTCode, AccHoldCountryRegionCode, AccountHolderCity, CheckID, Order);
        LibraryVariableStorage.Enqueue(Employee."No.");  // Enqueue for GetProposalEntriesRequestPageHandler.

        // Exercise: Get Entries on Telebank Proposal page.
        GetEntriesOnTelebankProposal(TelebankProposal, Employee."Bank Account No.");

        // Verify: Verify Error on Telebank Proposal Page.
        Assert.IsTrue(StrPos(TelebankProposal.Message.Value, ExpectedMessage) > 0, ErrorMatchMsg);
    end;

    local procedure PostPurchaseInvoiceWithVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; SEPAAllowed: Boolean; IBAN: Code[50]; SWIFTCode: Code[20]; CountryRegionCode: Code[10]; AccHoldCountryRegionCode: Code[10]; AccountHolderCity: Text[30]; CheckID: Integer; "Order": Option)
    begin
        UpdateSEPAAllowedOnCountryRegion(SEPAAllowed);
        CreateVendorBankAccountAndUpdateVendor(
          VendorBankAccount, IBAN, SWIFTCode, CountryRegionCode, AccHoldCountryRegionCode, AccountHolderCity, CheckID, Order);
        CreateAndPostPurchaseInvoice(VendorBankAccount."Vendor No.");
    end;

    local procedure PostEmployeeExpenseWithEmployee(var Employee: Record Employee; SEPAAllowed: Boolean; IBAN: Code[50]; SWIFTCode: Code[20]; AccHoldCountryRegionCode: Code[10]; AccountHolderCity: Text[30]; CheckID: Integer; "Order": Option)
    begin
        UpdateSEPAAllowedOnCountryRegion(SEPAAllowed);
        CreateEmployeeAndUpdateEmployee(
          Employee, IBAN, SWIFTCode, AccHoldCountryRegionCode, AccountHolderCity, CheckID, Order);
        CreateAndPostEmployeeExpense(Employee);
    end;

    local procedure PostSalesInvoiceWithCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account"; SEPAAllowed: Boolean; IBAN: Code[50]; SWIFTCode: Code[20]; CountryRegionCode: Code[10]; AccHoldCountryRegionCode: Code[10]; AccountHolderCity: Text[30]; CheckID: Integer; "Order": Option)
    begin
        UpdateSEPAAllowedOnCountryRegion(SEPAAllowed);
        CreateCustomerBankAccountAndUpdateCustomer(
          CustomerBankAccount, IBAN, SWIFTCode, CountryRegionCode, AccHoldCountryRegionCode, AccountHolderCity, CheckID, Order);
        CreateAndPostSalesInvoice(CustomerBankAccount."Customer No.");
    end;

    local procedure RemoveFreelyTransferableMaximum(CountryRegionCode: Code[10]; CurrencyCode: Code[10])
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        FreelyTransferableMaximum.SetRange("Country/Region Code", CountryRegionCode);
        FreelyTransferableMaximum.SetRange("Currency Code", CurrencyCode);
        FreelyTransferableMaximum.FindFirst();
        FreelyTransferableMaximum.Delete(true);
    end;

    local procedure UpdateAmountOnFreelyTransferableMaximum(CountryRegionCode: Code[10]; CurrencyCode: Code[10])
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        FreelyTransferableMaximum.Get(CountryRegionCode, CurrencyCode);
        FreelyTransferableMaximum.Validate(Amount, LibraryRandom.RandDecInRange(10000, 20000, 1));
        // Using Random for Amount, value need to greater than amount of all Ledger Entries in every Payment.
        FreelyTransferableMaximum.Modify(true);
    end;

    local procedure SetupForProposalLineWithAccountType(AccountTypeOption: Option; CompanyInformation: Record "Company Information"; CurrencyCode: Code[10]; var BankAccountNo: Code[20]; var AccountNo: Code[20])
    var
        VendorBankAccount: Record "Vendor Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        Employee: Record Employee;
    begin
        case AccountTypeOption of
            AccountType::Vendor:
                begin
                    SetupForProposalLine(VendorBankAccount, CompanyInformation, CurrencyCode);
                    BankAccountNo := VendorBankAccount."Bank Account No.";
                    AccountNo := VendorBankAccount."Vendor No.";
                end;
            AccountType::Customer:
                begin
                    SetupForProposalLineWithCustomerAccountType(CustomerBankAccount, CompanyInformation, CurrencyCode);
                    BankAccountNo := CustomerBankAccount."Bank Account No.";
                    AccountNo := CustomerBankAccount."Customer No.";
                end;
            AccountType::Employee:
                begin
                    SetupForProposalLineWithEmployeeAccountType(Employee, CompanyInformation, CurrencyCode);
                    BankAccountNo := CopyStr(Employee."Bank Account No.", 1, MaxStrLen(BankAccountNo));
                    AccountNo := Employee."No.";
                end;
        end;
    end;

    local procedure SetupForProposalLine(var VendorBankAccount: Record "Vendor Bank Account"; CompanyInformation: Record "Company Information"; CurrencyCode: Code[10])
    var
        TransactionMode: Record "Transaction Mode";
    begin
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CompanyInformation."Country/Region Code", CurrencyCode);  // Currency Code as blank.
        PostPurchaseInvoiceWithVendorBankAccount(
          VendorBankAccount, true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
          CompanyInformation."Country/Region Code", CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit);
        LibraryVariableStorage.Enqueue(VendorBankAccount."Vendor No.");  // Enqueue for GetProposalEntriesRequestPageHandler.
    end;

    local procedure SetupForProposalLineWithCustomerAccountType(var CustomerBankAccount: Record "Customer Bank Account"; CompanyInformation: Record "Company Information"; CurrencyCode: Code[10])
    var
        TransactionMode: Record "Transaction Mode";
    begin
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CompanyInformation."Country/Region Code", CurrencyCode);
        PostSalesInvoiceWithCustomerBankAccount(
          CustomerBankAccount, true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
          CompanyInformation."Country/Region Code", CompanyInformation.City, GetCheckID(), TransactionMode.Order::Credit);
        LibraryVariableStorage.Enqueue(CustomerBankAccount."Customer No."); // Enqueue for GetProposalEntriesRequestPageHandler.
    end;

    local procedure SetupForProposalLineWithEmployeeAccountType(var Employee: Record Employee; CompanyInformation: Record "Company Information"; CurrencyCode: Code[10])
    var
        TransactionMode: Record "Transaction Mode";
    begin
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CompanyInformation."Country/Region Code", CurrencyCode);
        PostEmployeeExpenseWithEmployee(
          Employee, true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code",
          CompanyInformation."Country/Region Code", CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit);
        LibraryVariableStorage.Enqueue(Employee."No."); // Enqueue for GetProposalEntriesRequestPageHandler.
    end;

    local procedure SetupForPaymentHistory(CountryRegionCode: Code[10]; CurrencyCode: Code[10]; BankAccountNo: Code[20]; AccountNo: Code[20])
    var
        ProposalLine: Record "Proposal Line";
        TelebankProposal: TestPage "Telebank Proposal";
    begin
        UpdateAmountOnFreelyTransferableMaximum(CountryRegionCode, CurrencyCode);
        GetEntriesOnTelebankProposal(TelebankProposal, BankAccountNo);
        UpdateProposalLine(
          ProposalLine, BankAccountNo, AccountNo, ProposalLine."Nature of the Payment"::Goods, CurrencyCode);
        UpdateTransactionModeForPaymInProcess(ProposalLine."Account Type", ProposalLine."Transaction Mode");
        TelebankProposal.Process.Invoke(); // Call action Process.
        TelebankProposal.Close();
    end;

    local procedure PostVendorInvoiceUpdateSEPABankAccount(FIELDNO: Integer; FieldValue: Code[20]; var VendorBankAccount: Record "Vendor Bank Account")
    var
        CompanyInformation: Record "Company Information";
        TransactionMode: Record "Transaction Mode";
    begin
        CompanyInformation.Get();
        PostPurchaseInvoiceWithVendorBankAccount(
          VendorBankAccount, true, CompanyInformation.IBAN, CompanyInformation."SWIFT Code", CompanyInformation."Country/Region Code",
          CompanyInformation."Country/Region Code", CompanyInformation.City, GetCheckID(), TransactionMode.Order::Debit);
        UpdateBankAccount(VendorBankAccount."Bank Account No.", FIELDNO, FieldValue);
    end;

    local procedure UpdateBankAccAndGetEntriesOnTelebankProposal(FIELDNO: Integer; FieldValue: Code[20]; ExpectedMessage: Text[125])
    var
        VendorBankAccount: Record "Vendor Bank Account";
        TelebankProposal: TestPage "Telebank Proposal";
    begin
        Initialize();

        PostVendorInvoiceUpdateSEPABankAccount(FIELDNO, FieldValue, VendorBankAccount);
        LibraryVariableStorage.Enqueue(VendorBankAccount."Vendor No."); // Enqueue for GetProposalEntriesRequestPageHandler.

        GetEntriesOnTelebankProposal(TelebankProposal, VendorBankAccount."Bank Account No.");

        Assert.IsTrue(StrPos(TelebankProposal.Message.Value, ExpectedMessage) > 0, ErrorMatchMsg);
    end;

    local procedure UpdateBankAccount(No: Code[30]; FieldNo: Integer; FieldValue: Code[50])
    var
        BankAccount: Record "Bank Account";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        BankAccount.Get(No);
        RecRef.GetTable(BankAccount);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(FieldValue);
        RecRef.SetTable(BankAccount);
        BankAccount.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(CurrencyEuro: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Local Currency", GeneralLedgerSetup."Local Currency"::Other);
        GeneralLedgerSetup.Validate("Currency Euro", CurrencyEuro);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateProposalLine(var ProposalLine: Record "Proposal Line"; OurBankNo: Code[50]; AccountNo: Code[20]; NatureOfThePayment: Option; CurrencyCode: Code[10])
    begin
        ProposalLine.SetRange("Our Bank No.", CopyStr(OurBankNo, 1, MaxStrLen(ProposalLine."Our Bank No.")));
        ProposalLine.SetRange("Account No.", AccountNo);
        ProposalLine.FindFirst();
        ProposalLine.Validate("Nature of the Payment", NatureOfThePayment);
        ProposalLine.Validate("Currency Code", CurrencyCode);
        ProposalLine.Modify(true);
    end;

    local procedure UpdateSWIFTCodeOnCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(
          "SWIFT Code", LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("SWIFT Code"), DATABASE::"Company Information"));
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateSEPAAllowedOnCountryRegion(SEPAAllowed: Boolean)
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.Get(CompanyInformation."Country/Region Code");
        CountryRegion.Validate("SEPA Allowed", SEPAAllowed);
        CountryRegion.Modify(true);
    end;

    local procedure UpdatePaymentTermsOnCustomer(CustomerNo: Code[20]; PaymentTermsCode: Code[10])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
    end;

    local procedure UpdatePaymentTermsOnVendor(VendorNo: Code[20]; PaymentTermsCode: Code[10])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
    end;

    local procedure AssignNewIBANnumber(ConfirmReply: Boolean)
    var
        ProposalLine: Record "Proposal Line";
        OldIBAN: Code[50];
        IBANNumber: Code[50];
    begin
        ProposalLine.Init();
        OldIBAN := ProposalLine.IBAN;
        LibraryVariableStorage.Enqueue(ConfirmReply);
        IBANNumber := LibraryUtility.GenerateGUID();

        if ConfirmReply then
            ProposalLine.Validate(IBAN, IBANNumber)
        else begin
            asserterror ProposalLine.Validate(IBAN, IBANNumber);
            IBANNumber := OldIBAN;
        end;

        VerifyIBAN(ProposalLine.IBAN, IBANNumber)
    end;

    local procedure CreateProposalLineVendor(var ProposalLine: Record "Proposal Line"; VendorNo: Code[20]; BankAccountNo: Code[20])
    begin
        ProposalLine.Validate("Our Bank No.", BankAccountNo);
        ProposalLine.Validate("Account Type", ProposalLine."Account Type"::Vendor);
        ProposalLine.Validate("Account No.", VendorNo);
    end;

    local procedure CreateVendorAndBankAccountWithDefaultDimension(var Vendor: Record Vendor; var BankAccountNo: Code[20]; var VendorBankAccountCode: Code[20]; var DefaultDimension1Code: Code[20]; var DefaultDimension2Code: Code[20])
    var
        BankAccount: Record "Bank Account";
        DimensionValue1Vendor: Record "Dimension Value";
        DimensionValue2Vendor: Record "Dimension Value";
        DimensionValue1BankAccount: Record "Dimension Value";
        DimensionValue2BankAccount: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccountNo := BankAccount."No.";

        CreateTwoDimensionsWithTwoValue(DimensionValue1Vendor, DimensionValue2Vendor,
          DimensionValue1BankAccount, DimensionValue2BankAccount);

        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Vendor,
          Vendor."No.", DimensionValue1Vendor."Dimension Code", DimensionValue1Vendor.Code);
        DefaultDimension1Code := DimensionValue1Vendor."Dimension Code";
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Vendor,
          Vendor."No.", DimensionValue2Vendor."Dimension Code", DimensionValue2Vendor.Code);
        DefaultDimension2Code := DimensionValue2Vendor."Dimension Code";

        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"Bank Account",
          BankAccount."No.", DimensionValue1BankAccount."Dimension Code", DimensionValue1BankAccount.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"Bank Account",
          BankAccount."No.", DimensionValue2BankAccount."Dimension Code", DimensionValue2BankAccount.Code);
        VendorBankAccount.Validate("Bank Account No.", BankAccount."No.");
        VendorBankAccount.Modify(true);
        VendorBankAccountCode := VendorBankAccount.Code;
    end;

    local procedure CreateProposalLineCustomer(var ProposalLine: Record "Proposal Line"; CustomerNo: Code[20]; BankAccountNo: Code[20])
    begin
        ProposalLine.Validate("Our Bank No.", BankAccountNo);
        ProposalLine.Validate("Account Type", ProposalLine."Account Type"::Customer);
        ProposalLine.Validate("Account No.", CustomerNo);
    end;

    local procedure CreateProposalLineCustomerBankAccount(var ProposalLine: Record "Proposal Line"; CustomerBankAccount: Record "Customer Bank Account"; BankAccountNo: Code[20])
    begin
        ProposalLine.Init();
        ProposalLine.Validate("Our Bank No.", BankAccountNo);
        ProposalLine.Validate("Account Type", ProposalLine."Account Type"::Customer);
        ProposalLine.Validate("Account No.", CustomerBankAccount."Customer No.");
        ProposalLine.Validate(Bank, CustomerBankAccount.Code);
        ProposalLine.Insert();
    end;

    local procedure CreateCustomerAndBankAccountWithDefaultDimension(var Customer: Record Customer; var BankAccountNo: Code[20]; var CustomerBankAccountCode: Code[20]; var DefaultDimension1Code: Code[20]; var DefaultDimension2Code: Code[20])
    var
        BankAccount: Record "Bank Account";
        DimensionValue1Customer: Record "Dimension Value";
        DimensionValue2Customer: Record "Dimension Value";
        DimensionValue1BankAccount: Record "Dimension Value";
        DimensionValue2BankAccount: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccountNo := BankAccount."No.";
        CreateTwoDimensionsWithTwoValue(DimensionValue1Customer, DimensionValue2Customer,
          DimensionValue1BankAccount, DimensionValue2BankAccount);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Customer,
          Customer."No.", DimensionValue1Customer."Dimension Code", DimensionValue1Customer.Code);
        DefaultDimension1Code := DimensionValue1Customer."Dimension Code";
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Customer,
          Customer."No.", DimensionValue2Customer."Dimension Code", DimensionValue2Customer.Code);
        DefaultDimension2Code := DimensionValue2Customer."Dimension Code";
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"Bank Account",
          BankAccount."No.", DimensionValue1BankAccount."Dimension Code", DimensionValue1BankAccount.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"Bank Account",
          BankAccount."No.", DimensionValue2BankAccount."Dimension Code", DimensionValue2BankAccount.Code);
        CustomerBankAccount.Validate("Bank Account No.", BankAccount."No.");
        CustomerBankAccount.Modify(true);
        CustomerBankAccountCode := CustomerBankAccount.Code;
    end;

    local procedure CreateCustomerAndBankAccount(var Customer: Record Customer; var BankAccountNo: Code[20]; var CustomerBankAccount: Record "Customer Bank Account")
    var
        BankAccount: Record "Bank Account";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccountNo := BankAccount."No.";
        CustomerBankAccount.Validate("Bank Account No.", BankAccount."No.");
        CustomerBankAccount.IBAN := Format(LibraryRandom.RandInt(100));
        CustomerBankAccount."SWIFT Code" :=
          LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo("SWIFT Code"), DATABASE::"Customer Bank Account");
        CustomerBankAccount."Direct Debit Mandate ID" := MockSEPADirectDebitMandate(CustomerBankAccount);
        CustomerBankAccount.Modify(true);
    end;

    local procedure MockSEPADirectDebitMandate(CustomerBankAccount: Record "Customer Bank Account"): Code[35]
    var
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        SEPADirectDebitMandate.Init();
        SEPADirectDebitMandate.ID := LibraryUtility.GenerateGUID();
        SEPADirectDebitMandate."Customer No." := CustomerBankAccount."Customer No.";
        SEPADirectDebitMandate."Customer Bank Account Code" := CustomerBankAccount.Code;
        SEPADirectDebitMandate.Insert();
        exit(SEPADirectDebitMandate.ID);
    end;

    local procedure CreateProposalLineEmployee(var ProposalLine: Record "Proposal Line"; EmployeeNo: Code[20]; BankAccountNo: Code[20])
    begin
        ProposalLine.Validate("Our Bank No.", BankAccountNo);
        ProposalLine.Validate("Account Type", ProposalLine."Account Type"::Employee);
        ProposalLine.Validate("Account No.", EmployeeNo);
    end;

    local procedure CreateEmployeeAndBankAccountWithDefaultDimension(var Employee: Record Employee; var BankAccountNo: Code[20]; var DefaultDimension1Code: Code[20]; var DefaultDimension2Code: Code[20])
    var
        BankAccount: Record "Bank Account";
        DimensionValue1Employee: Record "Dimension Value";
        DimensionValue2Employee: Record "Dimension Value";
        DimensionValue1BankAccount: Record "Dimension Value";
        DimensionValue2BankAccount: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccountNo := BankAccount."No.";

        CreateTwoDimensionsWithTwoValue(DimensionValue1Employee, DimensionValue2Employee,
          DimensionValue1BankAccount, DimensionValue2BankAccount);

        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Employee,
          Employee."No.", DimensionValue1Employee."Dimension Code", DimensionValue1Employee.Code);
        DefaultDimension1Code := DimensionValue1Employee."Dimension Code";
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::Employee,
          Employee."No.", DimensionValue2Employee."Dimension Code", DimensionValue2Employee.Code);
        DefaultDimension2Code := DimensionValue2Employee."Dimension Code";

        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"Bank Account",
          BankAccount."No.", DimensionValue1BankAccount."Dimension Code", DimensionValue1BankAccount.Code);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, DATABASE::"Bank Account",
          BankAccount."No.", DimensionValue2BankAccount."Dimension Code", DimensionValue2BankAccount.Code);
        Employee.Validate("Bank Account No.", BankAccount."No.");
        Employee.Modify(true);
    end;

    local procedure CreateTwoDimensionsWithTwoValue(var DimensionValue1: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value"; var DimensionValue1BankAccount: Record "Dimension Value"; var DimensionValue2BankAccount: Record "Dimension Value")
    var
        Dimension: Record Dimension;
        Dimension2: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue1, Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue1BankAccount, Dimension.Code);
        LibraryDimension.CreateDimension(Dimension2);
        LibraryDimension.CreateDimensionValue(DimensionValue2, Dimension2.Code);
        LibraryDimension.CreateDimensionValue(DimensionValue2BankAccount, Dimension2.Code);
        UpdateGLSetupDimension(Dimension.Code, Dimension2.Code);
    end;

    local procedure UpdateGLSetupDimension(DimensionCode1: Code[20]; DimensionCode2: Code[20])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Shortcut Dimension 1 Code" := DimensionCode1;
        GLSetup."Shortcut Dimension 2 Code" := DimensionCode2;
        GLSetup.Modify(true);
    end;

    local procedure CreateBalanceSheetGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure VerifyIBAN(CurrentIBAN: Code[50]; CheckIBAN: Code[50])
    begin
        Assert.AreEqual(CurrentIBAN, CheckIBAN, WrongIBANErr);
    end;

    local procedure VerifyProposalLineErrorMesage(OurBankNo: Code[20]; AccountNo: Code[20]; ErrorMessage: Text)
    var
        ProposalLine: Record "Proposal Line";
    begin
        ProposalLine.SetRange("Our Bank No.", OurBankNo);
        ProposalLine.SetRange("Account Type", ProposalLine."Account Type"::Vendor);
        ProposalLine.SetRange("Account No.", AccountNo);
        ProposalLine.FindFirst();
        ProposalLine.TestField("Error Message", ErrorMessage);
    end;

    local procedure VerifyProposalLineAmount(AccType: Option; AccountNo: Code[20]; ExpectedLineAmount: Decimal)
    var
        ProposalLine: Record "Proposal Line";
    begin
        ProposalLine.SetRange("Account Type", AccType);
        ProposalLine.SetRange("Account No.", AccountNo);
        ProposalLine.FindFirst();
        ProposalLine.TestField(Amount, ExpectedLineAmount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetProposalEntriesRequestPageHandler(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        GetProposalEntries.CurrencyDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Using Random Value for Day.
        GetProposalEntries."Vendor Ledger Entry".SetFilter("Vendor No.", VendorNo);
        GetProposalEntries.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetProposalEntriesRequestPageHandlerEmployee(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    var
        EmployeeNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(EmployeeNo);
        GetProposalEntries.CurrencyDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Using Random Value for Day.
        GetProposalEntries."Employee Ledger Entry".SetFilter("Employee No.", EmployeeNo);
        GetProposalEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        if StrPos(Question, ProposalLinesQst) > 0 then
            Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        VendorLedgerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorNoOnVendorLedgerEntriesPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        VendorLedgerEntries."Vendor No.".AssertEquals(VendorNo);
        VendorLedgerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorNoOnVendorCardPageHandler(var VendorCard: TestPage "Vendor Card")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        VendorCard."No.".AssertEquals(VendorNo);
        VendorCard.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerNoOnCustomerLedgerEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerLedgerEntries."Customer No.".AssertEquals(CustomerNo);
        CustomerLedgerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerNoOnCustomerCardPageHandler(var CustomerCard: TestPage "Customer Card")
    var
        CustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(CustomerNo);
        CustomerCard."No.".AssertEquals(CustomerNo);
        CustomerCard.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EmployeeNoOnEmployeeLedgerEntriesPageHandler(var EmployeeLedgerEntries: TestPage "Employee Ledger Entries")
    var
        EmployeeNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(EmployeeNo);
        EmployeeLedgerEntries."Employee No.".AssertEquals(EmployeeNo);
        EmployeeLedgerEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EmployeeNoOnEmployeeCardPageHandler(var EmployeeCard: TestPage "Employee Card")
    var
        EmployeeNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(EmployeeNo);
        EmployeeCard."No.".AssertEquals(EmployeeNo);
        EmployeeCard.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure IBANConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    var
        StoredReply: Variant;
    begin
        LibraryVariableStorage.Dequeue(StoredReply);
        Reply := StoredReply;
    end;

    [Scope('OnPrem')]
    procedure CreateBankAccountLargeNo(var BankAccount: Record "Bank Account")
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccount.Init();
        BankAccount.Validate("No.",
          LibraryUtility.GenerateRandomCode(BankAccount.FieldNo("No."), DATABASE::"Bank Account") +
          Format(LibraryRandom.RandIntInRange(10, 99)));
        BankAccount.Validate(Name, BankAccount."No.");
        BankAccount.Insert(true);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
    end;

    local procedure InitProposalLineWithDiffCountryRegionCodes(var ProposalLine: Record "Proposal Line")
    var
        BankCountryRegionFactor: Decimal;
        AccHoldCountryRegionFactor: Decimal;
    begin
        AccHoldCountryRegionFactor := LibraryRandom.RandIntInRange(3, 10);
        BankCountryRegionFactor := 1 / AccHoldCountryRegionFactor;
        ProposalLine.IBAN := Format(LibraryRandom.RandInt(100));
        ProposalLine."SWIFT Code" :=
          LibraryUtility.GenerateRandomCode(ProposalLine.FieldNo("SWIFT Code"), DATABASE::"Proposal Line");
        ProposalLine.Amount := LibraryRandom.RandDec(100, 2);
        ProposalLine."Acc. Hold. Country/Region Code" := CreateSEPACountryRegionWithLimit(Round(ProposalLine.Amount * AccHoldCountryRegionFactor));
        ProposalLine."Bank Country/Region Code" := CreateSEPACountryRegionWithLimit(Round(ProposalLine.Amount * BankCountryRegionFactor));
        ProposalLine."Our Bank No." := CreateBankAccountWithCountryRegionCode(ProposalLine);
        ProposalLine."Nature of the Payment" := ProposalLine."Nature of the Payment"::" ";
    end;

    local procedure CreateBankAccountWithCountryRegionCode(ProposalLine: Record "Proposal Line"): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Country/Region Code" := ProposalLine."Bank Country/Region Code";
        BankAccount.IBAN := ProposalLine.IBAN;
        BankAccount."SWIFT Code" := ProposalLine."SWIFT Code";
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    [Normal]
    local procedure SetGLSetupEmptyLocalCurrency()
    begin
        GLSetup.Get();
        GLSetup.Validate("Local Currency", 0);
        GLSetup.Modify(true);
    end;

    local procedure CreateSEPACountryRegionWithLimit(MaximumAmount: Decimal): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."SEPA Allowed" := true;
        CountryRegion.Modify();
        CreateFreelyTransMaximumWithAmount(CountryRegion.Code, MaximumAmount);
        exit(CountryRegion.Code);
    end;

    local procedure CreateFreelyTransMaximumWithAmount(CountryRegionCode: Code[10]; MaximumAmount: Decimal)
    var
        FreelyTransferableMaximum: Record "Freely Transferable Maximum";
    begin
        LibraryNLLocalization.CreateFreelyTransferableMaximum(CountryRegionCode, '');
        FreelyTransferableMaximum.Get(CountryRegionCode, '');
        FreelyTransferableMaximum.Validate(Amount, MaximumAmount);
        FreelyTransferableMaximum.Modify(true);
    end;

    local procedure VerifyDimensionsInProposalLine(ProposalLine: Record "Proposal Line"; TableID: Integer; SourceNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        LibraryDimension.FindDefaultDimension(DefaultDimension, TableID, SourceNo);
        DefaultDimension.SetRange("Dimension Code", GLSetup."Shortcut Dimension 1 Code");
        DefaultDimension.FindFirst();
        Assert.AreEqual(DefaultDimension."Dimension Value Code", ProposalLine."Shortcut Dimension 1 Code", WrongShortcutDimensionErr);
        DefaultDimension.SetRange("Dimension Code", GLSetup."Shortcut Dimension 2 Code");
        DefaultDimension.FindFirst();
        Assert.AreEqual(DefaultDimension."Dimension Value Code", ProposalLine."Shortcut Dimension 2 Code", WrongShortcutDimensionErr);
    end;

    local procedure CreateVendorAndVendorBankAccount(var Vendor: Record Vendor; CurrencyCode: Code[10])
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorNo: Code[20];
    begin
        VendorNo := CreateVendorWithBankAccount('');
        Vendor.Get(VendorNo);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);

        VendorBankAccount.SetRange("Vendor No.", VendorNo);
        VendorBankAccount.FindFirst();
        VendorBankAccount.Validate("Currency Code", Vendor."Currency Code");
        VendorBankAccount.Modify(true);
    end;

    local procedure DeleteDetailLine(VendorNo: Code[20])
    var
        DetailLine: Record "Detail Line";
    begin
        DetailLine.SetRange("Account Type", DetailLine."Account Type"::Vendor);
        DetailLine.SetRange("Status", DetailLine.Status::Proposal);
        DetailLine.SetRange("Account No.", VendorNo);
        DetailLine.FindFirst();
        DetailLine.Delete(true);
        Commit();
    end;

    local procedure FindProposalLine(var ProposalLine: Record "Proposal Line"; VendorNo: Code[20])
    begin
        ProposalLine.SetRange("Account Type", ProposalLine."Account Type"::Vendor);
        ProposalLine.SetRange("Account No.", VendorNo);
        ProposalLine.FindFirst();
    end;

    local procedure CalculateForeignAmount(ProposalLine: Record "Proposal Line"; Currency: Record Currency): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        exit(Round(
            CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                ProposalLine."Transaction Date", ProposalLine."Currency Code",
                ProposalLine."Foreign Currency", ProposalLine.Amount), Currency."Amount Rounding Precision"));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetProposalEntriesRequestPageHandlerSetValueDate(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    begin
        GetProposalEntries.CurrencyDate.SetValue(LibraryVariableStorage.DequeueDate());
        GetProposalEntries.OK().Invoke();
    end;
}

