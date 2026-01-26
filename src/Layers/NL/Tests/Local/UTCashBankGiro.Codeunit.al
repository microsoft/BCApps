codeunit 144013 "UT Cash Bank Giro"
{
    // 
    // 1:  Purpose of the test is to validate Cash Journal and Bank Journal of Source Code Setup Page .
    // 2:  Purpose of the test is to hit CheckBankAccNo for Country/Region Code 'NL' on Codeunit Local Functionality Mgt.
    // 3:  Purpose of the test is to hit CheckBankAccNo for Valid Bank Account No. on Codeunit Local Functionality Mgt.
    // 4:  Purpose of the test is to hit CheckBankAccNo for Bank Account No. equal to 0 on Codeunit Local Functionality Mgt.
    // 5:  Purpose of the test is to hit CheckBankAccNo for Bank Account No. of length 8 on Codeunit Local Functionality Mgt.
    // 6:  Purpose of the test is to hit CheckBankAccNo for Bank Account No. of length 10 on Codeunit Local Functionality Mgt.
    // 7:  Purpose of the test is to hit CheckBankAccNo for Bank Account No. of length 12 on Codeunit Local Functionality Mgt.
    // 8:  Purpose of the test is to hit CheckBankAccNo for Bank Account No. of length 9 on Codeunit Local Functionality Mgt.
    // 9:  Purpose of the test is to hit CheckBankAccNo of not valid Bank Account No on Codeunit Local Functionality Mgt.
    // 10: Purpose of the test is to hit ConvertPhoneNumber without Code on Codeunit Local Functionality Mgt.
    // 11: Purpose of the test is to hit ConvertPhoneNumber with Code on Codeunit Local Functionality Mgt.
    // 12: Purpose of the test is to hit ConvertPhoneNumber with Code Includes Zero on Codeunit Local Functionality Mgt.
    // 
    // Covers Test Cases: 343063
    // -----------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                            TFS ID
    // -----------------------------------------------------------------------------------------------------------------------------
    // OnOpenPageSourceCodeSetup, CheckBankAccNoWithCountryCodeLocalFunctionalityMgt
    // CheckBankAccNoWithValidAccountNoLocalFunctionalityMgt, CheckBankAccNoAccLengthOneLocalFunctionalityMgt
    // CheckBankAccNoAccLengthEightLocalFunctionalityMgt, CheckBankAccNoAccLengthTenLocalFunctionalityMgt
    // CheckBankAccNoAccLengthTwelveLocalFunctionalityMgt, CheckBankAccNoAccLengthNineLocalFunctionalityMgt
    // CheckBankAccNoInValidAccountNoLocalFunctionalityMgt, ConvertPhoneNumberWithoutCodeLocalFunctionalityMgt
    // ConvertPhoneNumberWithCodeLocalFunctionalityMgt, ConvertPhoneNumberWithCodeIncludesZeroLocalFunctionalityMgt

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        IncorrectAccountNoMsg: Label 'Bank Account No. %1 may be incorrect.';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnOpenPageSourceCodeSetup()
    var
        SourceCodeSetup: Record "Source Code Setup";
        SourceCodeSetupPage: TestPage "Source Code Setup";
    begin
        // Purpose of this test to verify Cash Journal and Bank Journal on Page ID - 279 Source Code Setup Page.

        // Setup.
        Initialize();
        CreateSourceCodeSetup(SourceCodeSetup);

        // Exercise.
        SourceCodeSetupPage.OpenEdit();

        // Verify: Verify Cash Journal and Bank Journal on Source Code Setup Page.
        SourceCodeSetupPage."Cash Journal".AssertEquals(SourceCodeSetup."Cash Journal");
        SourceCodeSetupPage."Bank Journal".AssertEquals(SourceCodeSetup."Bank Journal");

        // TearDown: Close Source Code Setup page.
        SourceCodeSetupPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBankAccNoWithCountryCodeLocalFunctionalityMgt()
    var
        BankAccountNo: Text[30];
    begin
        // Purpose of the test is to hit CheckBankAccNo for Country/Region Code 'NL' on Codeunit ID -11400 Local Functionality Mgt.

        // Setup: Create Bank Account.
        Initialize();
        BankAccountNo := CreateBankAccount();

        // Exercise.
        UpdateBankAccountNoOnCompanyInformation(BankAccountNo);

        // Verify: Verify Bank Account No.
        VerifyBankAccountNoOnCompanyInformation(BankAccountNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBankAccNoWithValidAccountNoLocalFunctionalityMgt()
    var
        BankAccountNo: Text[30];
    begin
        // Purpose of the test is to hit CheckBankAccNo for Valid Bank Account No. on Codeunit ID -11400 Local Functionality Mgt.

        // Setup: Find Bank Account.
        Initialize();
        BankAccountNo := CharacterFilter(UpperCase(FindBankAccountNo()), 'PG0123456789');  // Using Hard code value 'PG0123456789' of Bank Account No for function CheckBankAccNo on Codeunit ID -11400 Local Functionality Mgt.
        CheckBankAccNoAccountNoWithLength(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBankAccNoAccLengthOneLocalFunctionalityMgt()
    var
        BankAccountNo: Text[30];
    begin
        // Purpose of the test is to hit CheckBankAccNo for Bank Account No. equal to 0 on Codeunit ID -11400 Local Functionality Mgt.

        // Setup.
        Initialize();
        BankAccountNo := 'P0';  // Using Hard code value 'P0' of Bank Account No for function CheckBankAccNo on Codeunit ID -11400 Local Functionality Mgt.
        LibraryVariableStorage.Enqueue(BankAccountNo);
        CheckBankAccNoAccountNoWithLength(BankAccountNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBankAccNoAccLengthEightLocalFunctionalityMgt()
    begin
        // Purpose of the test is to hit CheckBankAccNo for Bank Account No. of length 8 on Codeunit ID -11400 Local Functionality Mgt.

        // Setup: Create Bank Account.
        Initialize();
        CheckBankAccNoAccountNoWithLength(CopyStr('P' + CreateBankAccount(), 1, 8));  // Using Hard code value 'P' of Bank Account No for function CheckBankAccNo on Codeunit ID -11400 Local Functionality Mgt.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBankAccNoAccLengthTenLocalFunctionalityMgt()
    var
        BankAccountNo: Text[30];
    begin
        // Purpose of the test is to hit CheckBankAccNo for Bank Account No. of length 10 on Codeunit ID -11400 Local Functionality Mgt.

        // Setup: Create Bank Account.
        Initialize();
        BankAccountNo := CopyStr(CreateBankAccount(), 1, 10);
        LibraryVariableStorage.Enqueue(BankAccountNo);
        CheckBankAccNoAccountNoWithLength(BankAccountNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBankAccNoAccLengthTwelveLocalFunctionalityMgt()
    var
        BankAccountNo: Text[30];
    begin
        // Purpose of the test is to hit CheckBankAccNo for Bank Account No. of length 12 on Codeunit ID -11400 Local Functionality Mgt.

        // Setup: Create Bank Account.
        Initialize();
        BankAccountNo := CopyStr('PG0' + CreateBankAccount(), 1, 12);  // Using Hard code value 'PGO' of Bank Account No for function CheckBankAccNo on Codeunit ID -11400 Local Functionality Mgt.
        LibraryVariableStorage.Enqueue(BankAccountNo);
        CheckBankAccNoAccountNoWithLength(BankAccountNo);
    end;

    local procedure CheckBankAccNoAccountNoWithLength(BankAccountNo: Text[30])
    var
        CountryRegionCode: Code[10];
    begin
        CountryRegionCode := UpdateBlankCountryRegionCodeOnCompanyInformation('');

        // Exercise.
        UpdateBankAccountNoOnCompanyInformation(BankAccountNo);

        // Verify: Verify Bank Account No.
        VerifyBankAccountNoOnCompanyInformation(BankAccountNo);

        // TearDown: Update Old Country Region Code in Company Information.
        UpdateBlankCountryRegionCodeOnCompanyInformation(CountryRegionCode);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CheckBankAccNoInValidAccountNoLocalFunctionalityMgt()
    var
        CompanyInformation: Record "Company Information";
        BankAccountNo: Text[30];
    begin
        // Purpose of the test is to hit CheckBankAccNo of not valid Bank Account No on Codeunit ID -11400 Local Functionality Mgt.

        // Setup: Create Bank Account.
        Initialize();
        BankAccountNo := CopyStr(LibraryUTUtility.GetNewCode10() + CreateBankAccount(), 1, 20);
        LibraryVariableStorage.Enqueue(BankAccountNo);  // Enqueue BankAccountNo for MessageHandler.

        // Exercise.
        CompanyInformation.Validate("Bank Account No.", BankAccountNo);

        // Verify: Verification done in Message Handler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConvertPhoneNumberWithoutCodeLocalFunctionalityMgt()
    begin
        // Purpose of the test is to hit ConvertPhoneNumber function on Codeunit ID -11400 Local Functionality Mgt.

        // Using blank for Phone Number Code, Blank space '-' to delete characters from Phone Number, 2 to copy from second digit of Phone Number.
        ConvertPhoneNumberLocalFunctionalityMgt('', '-', 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConvertPhoneNumberWithCodeLocalFunctionalityMgt()
    begin
        // Purpose of the test is to validate ConvertPhoneNumber function of CodeUnit ID -11400 Local Functionality Mgt.

        // Using '0031' for Phone Number Code, Blank space and Zero '-,0' to delete characters from Phone Number, 5 to copy from second digit of Phone Number.
        ConvertPhoneNumberLocalFunctionalityMgt('0031', '-,0', 5);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ConvertPhoneNumberWithCodeIncludesZeroLocalFunctionalityMgt()
    begin
        // Purpose of the test is to validate ConvertPhoneNumber function of CodeUnit ID -11400 Local Functionality Mgt.

        // Using '+310' for Phone Number Code, Blank space '-' to delete characters from Phone Number, 5 to copy from second digit of Phone Number.
        ConvertPhoneNumberLocalFunctionalityMgt('+310', '-', 5);
    end;

    local procedure ConvertPhoneNumberLocalFunctionalityMgt(RequiredStartingNumber: Text[4]; DeleteCharacter: Text[3]; CopyFrom: Integer)
    var
        CompanyInformation: Record "Company Information";
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        PhoneNo: Text[20];
    begin
        // Setup.
        CompanyInformation.Get();

        // Exercise.
        PhoneNo := RequiredStartingNumber + DelChr(CompanyInformation."Phone No.", '=', DeleteCharacter);

        // Verify: Verify Phone No.
        Assert.AreEqual('+31' + CopyStr(PhoneNo, CopyFrom), LocalFunctionalityMgt.ConvertPhoneNumber(PhoneNo), 'Value must be equal.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBankAccNoIsNotDoingMod11Check()
    var
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        AccountNo: Text[30];
    begin
        // [SCENARIO 331593] CheckBankAccountNo return TRUE for Bank Account No. which does not satisfy MOD11 check.
        Initialize();

        AccountNo := Format(387080820);
        Assert.IsTrue(LocalFunctionalityMgt.CheckBankAccNo(AccountNo, '', AccountNo), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBankAccNoAccLengthEight()
    var
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        AccountNo: Text[30];
    begin
        // [SCENARIO 331593] CheckBankAccountNo return FALSE for Bank Account No. of length 8.
        Initialize();

        AccountNo := Format(LibraryRandom.RandIntInRange(10000000, 99999999));
        Assert.IsFalse(LocalFunctionalityMgt.CheckBankAccNo(AccountNo, '', AccountNo), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBankAccNoAccLengthNine()
    var
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        AccountNo: Text[30];
    begin
        // [SCENARIO 331593] CheckBankAccountNo return TRUE for Bank Account No. of length 9.
        Initialize();

        AccountNo := Format(LibraryRandom.RandIntInRange(100000000, 999999999));
        Assert.IsTrue(LocalFunctionalityMgt.CheckBankAccNo(AccountNo, '', AccountNo), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBankAccNoAccLengthEleven()
    var
        LocalFunctionalityMgt: Codeunit "Local Functionality Mgt.";
        AccountNo: Text[30];
    begin
        // [SCENARIO 331593] CheckBankAccountNo return FALSE for Bank Account No. of length 11.
        Initialize();

        AccountNo := Format(LibraryRandom.RandIntInRange(100000000, 999999999)) + '00';
        Assert.IsFalse(LocalFunctionalityMgt.CheckBankAccNo(AccountNo, '', AccountNo), '');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CharacterFilter(Text: Text[250]; "Filter": Text[20]): Text[250]
    begin
        exit(DelChr(Text, '=', DelChr(Text, '=', Filter)));
    end;

    local procedure CreateBankAccount(): Text[30]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount."Bank Account No." := Format(LibraryRandom.RandIntInRange(1800000000, 2000000000));
        BankAccount.Insert();
        exit(BankAccount."Bank Account No.");
    end;

    local procedure CreateSourceCode(): Code[10]
    var
        SourceCode: Record "Source Code";
    begin
        SourceCode.Code := LibraryUTUtility.GetNewCode10();
        SourceCode.Insert();
        exit(SourceCode.Code);
    end;

    local procedure CreateSourceCodeSetup(var SourceCodeSetup: Record "Source Code Setup")
    begin
        SourceCodeSetup.Validate("Cash Journal", CreateSourceCode());
        SourceCodeSetup.Validate("Bank Journal", CreateSourceCode());
        SourceCodeSetup.Modify();
    end;

    local procedure FindBankAccountNo(): Text[30]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.FindFirst();
        exit(BankAccount."Bank Account No.");
    end;

    local procedure UpdateBankAccountNoOnCompanyInformation(BankAccountNo: Text[30])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Bank Account No.", BankAccountNo);
        CompanyInformation.Modify();
    end;

    local procedure UpdateBlankCountryRegionCodeOnCompanyInformation(CountryRegionCode: Code[10]) OldCountryRegionCode: Code[10]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        OldCountryRegionCode := CompanyInformation."Country/Region Code";
        CompanyInformation."Country/Region Code" := CountryRegionCode;
        CompanyInformation.Modify();
    end;

    local procedure VerifyBankAccountNoOnCompanyInformation(BankAccountNo: Text[30])
    var
        CompanyInformationPage: TestPage "Company Information";
    begin
        CompanyInformationPage.OpenEdit();
        CompanyInformationPage."Bank Account No.".AssertEquals(BankAccountNo);
        CompanyInformationPage.Close();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        Assert.IsTrue(StrPos(Message, StrSubstNo(IncorrectAccountNoMsg, BankAccountNo)) > 0, 'Message must be same.');
    end;
}

