codeunit 142500 "Export Payments File Handling"
{
    // 1. Verify that no error of Input Qualifier while doing export payement.
    // 
    // BUG ID 50988
    // ---------------------------------------------------------------------------
    // CheckExportPayment
    // ---------------------------------------------------------------------------

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Export Payments]
    end;

    var
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        FieldsAreNotEqualMsg: Label 'Actual value %2 is not equal to the expected value, which is %1.';
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ExportedCVNameErr: Label 'Wrong Customer/Vendor Name in exported payment file.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransmitExportedFileACH()
    var
        BankAccount: Record "Bank Account";
        ExportPaymentsACH: Codeunit "Export Payments (ACH)";
        FileName: Text[30];
        TempPath: Text;
    begin
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        FileName := CreateClientExportFile();

        ExportPaymentsACH.TransmitExportedFile(BankAccount."No.", FileName);

        VerifyMovedFile(BankAccount, FileName);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransmitExportedFileRB()
    var
        BankAccount: Record "Bank Account";
        ExportPaymentsRB: Codeunit "Export Payments (RB)";
        FileName: Text[30];
        TempPath: Text;
    begin
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        FileName := CreateClientExportFile();

        ExportPaymentsRB.TransmitExportedFile(BankAccount."No.", FileName);

        VerifyMovedFile(BankAccount, FileName);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TransmitExportedFileCecoban()
    var
        BankAccount: Record "Bank Account";
        ExportPaymentsCecoban: Codeunit "Export Payments (Cecoban)";
        FileName: Text[30];
        TempPath: Text;
    begin
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        FileName := CreateClientExportFile();

        ExportPaymentsCecoban.TransmitExportedFile(BankAccount."No.", FileName);

        VerifyMovedFile(BankAccount, FileName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckExportPayment()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsRB: Codeunit "Export Payments (RB)";
        VendorNo, VendorBankAccountNo : Code[20];
    begin
        // Verify that no error of Input Qualifier while doing export payment.
        Initialize();

        // Setup: Create Gen journal line and create Vendor bank account.
        UpdateCompanyInfo();

        VendorNo := CreateLongNameVendorNo();
        VendorBankAccountNo := LibraryRandom.RandText(20);
        CreateVendorBankAccount(VendorNo, VendorBankAccountNo, BankAccount."Export Format"::US);

        CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        ModifyBankAccount(BankAccount);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, BankAccount."No.", VendorBankAccountNo);

        // Exercise: Export Payment.
        ExportPaymentsRB.StartExportFile(BankAccount."No.", GenJournalLine);
        ExportPaymentsRB.ExportElectronicPayment(GenJournalLine, GenJournalLine.Amount, WorkDate());

        // Verify: File export successfully without Input Qualifier.
        ExportPaymentsRB.EndExportFile();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRBExportedFileData()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        ExportPaymentsRB: Codeunit "Export Payments (RB)";
        VendorNo, VendorBankAccountNo : Code[20];
    begin
        // Verify data of the RB exported file (only related to HF 363117)
        // this test should be used for future changes of RB electronic payment format
        Initialize();

        // Setup: Create Gen journal line and create Vendor bank account.
        UpdateCompanyInfo();

        VendorNo := CreateLongNameVendorNo();
        VendorBankAccountNo := LibraryRandom.RandText(20);
        CreateVendorBankAccount(VendorNo, VendorBankAccountNo, BankAccount."Export Format"::US);

        CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);
        ModifyBankAccount(BankAccount);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, BankAccount."No.", VendorBankAccountNo);

        // Exercise: Export Payment.
        ExportPaymentsRB.StartExportFile(BankAccount."No.", GenJournalLine);
        ExportPaymentsRB.ExportElectronicPayment(GenJournalLine, GenJournalLine.Amount, WorkDate());

        // Verify: Verify exported file
        ExportPaymentsRB.EndExportFile();
        VerifyRBFileData(BankAccount, VendorNo, GenJournalLine.Amount, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPayments_ACH_VendorName()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorNo, VendorBankAccountNo : Code[20];
        TempPath: Text;
    begin
        // [FEATURE] [Export Payments (ACH)] [Payables]
        // [SCENARIO 364614] Exported Payment File (ACH) has 16-chars length Vendor.Name
        // [SCENARIO 430249] Exported Payment File (ACH) has 22 chars length Vendor Name.
        Initialize();
        UpdateCompanyInfo();
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);

        // [GIVEN] Vendor with Name of length 100.
        VendorNo := CreateLongNameVendorNo();
        VendorBankAccountNo := LibraryRandom.RandText(20);
        CreateVendorBankAccount(VendorNo, VendorBankAccountNo, BankAccount."Export Format"::US);

        // [GIVEN] Vendor general journal payment line
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, BankAccount."No.", VendorBankAccountNo);

        // [WHEN] Export Payments (ACH)
        ExportPayments_ACH(GenJournalLine);

        // [THEN] Exported File (ACH) has Vendor name value trimmed to 22 chars.
        Vendor.Get(VendorNo);
        VerifyExportedFileACHCustVendorName(CopyStr(Vendor.Name, 1, 22), GetBankExportFileName(BankAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPayments_ACH_CustomerName()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustomerNo, CustomerBankAccountNo : Code[20];
        TempPath: Text;
    begin
        // [FEATURE] [Export Payments (ACH)] [Receivables]
        // [SCENARIO 364614] Exported Payment File (ACH) has 16-chars length Customer.Name
        // [SCENARIO 430249] Exported Payment File (ACH) has 22 chars length Customer Name.
        Initialize();
        UpdateCompanyInfo();
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::US);

        // [GIVEN] Customer with Name of length 100.
        CustomerNo := CreateLongNameCustomerNo();
        CustomerBankAccountNo := LibraryRandom.RandText(20);
        CreateCustomerBankAccount(CustomerNo, CustomerBankAccountNo, BankAccount."Export Format"::US);

        // [GIVEN] Customer general journal payment line
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, BankAccount."No.", CustomerBankAccountNo);

        // [WHEN] Export Payments (ACH)
        ExportPayments_ACH(GenJournalLine);

        // [THEN] Exported File (ACH) has Customer name value trimmed to 22 chars.
        Customer.Get(CustomerNo);
        VerifyExportedFileACHCustVendorName(CopyStr(Customer.Name, 1, 22), GetBankExportFileName(BankAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPayments_Cecoban_VendorName()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo, VendorBankAccountNo : Code[20];
        TempPath: Text;
    begin
        // [FEATURE] [Export Payments (Cecoban)] [Payables]
        // [SCENARIO 364614] Exported Payment File (Cecoban) has 40-chars length Vendor.Name
        Initialize();
        UpdateCompanyInfo();

        // [GIVEN] Vendor with Name = "XY", where "X" = 40-chars length string, "Y" = 10-chars length string
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::MX);

        VendorNo := CreateLongNameVendorNo();
        VendorBankAccountNo := LibraryRandom.RandText(20);
        CreateVendorBankAccount(VendorNo, VendorBankAccountNo, BankAccount."Export Format"::MX);

        // [GIVEN] Vendor general journal payment line
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo, BankAccount."No.", VendorBankAccountNo);

        // [WHEN] Export Payments (Cecoban)
        ExportPayments_Cecoban(GenJournalLine);

        // [THEN] Exported File (Cecoban) has Vendor name value = "X"
        VerifyExportedFileCecobanVendorName(VendorNo, BankAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPayments_Cecoban_CustomerName()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo, CustomerBankAccountNo : Code[20];
        TempPath: Text;
    begin
        // [FEATURE] [Export Payments (Cecoban)] [Receivables]
        // [SCENARIO 364614] Exported Payment File (Cecoban) has 40-chars length Customer.Name
        Initialize();
        UpdateCompanyInfo();

        // [GIVEN] Customer with Name = "XY", where "X" = 40-chars length string, "Y" = 10-chars length string
        TempPath := CreateBankAccountWithExportPaths(BankAccount, BankAccount."Export Format"::MX);

        CustomerNo := CreateLongNameCustomerNo();
        CustomerBankAccountNo := LibraryRandom.RandText(20);
        CreateCustomerBankAccount(CustomerNo, CustomerBankAccountNo, BankAccount."Export Format"::MX);

        // [GIVEN] Customer general journal payment line
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, BankAccount."No.", CustomerBankAccountNo);

        // [WHEN] Export Payments (Cecoban)
        ExportPayments_Cecoban(GenJournalLine);

        // [THEN] Exported File (Cecoban) has Customer name value = "X"
        VerifyExportedFileCecobanCustomerName(CustomerNo, BankAccount."No.");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        IsInitialized := true;
    end;

    local procedure ExportPayments_ACH(GenJournalLine: Record "Gen. Journal Line")
    var
        ExportPaymentsACH: Codeunit "Export Payments (ACH)";
        ServiceClassCode: Code[10];
    begin
        ServiceClassCode := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(ServiceClassCode));
        ExportPaymentsACH.StartExportFile(GenJournalLine."Bal. Account No.", CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10));
        ExportPaymentsACH.StartExportBatch(
          ServiceClassCode, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10),
          CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), WorkDate());
        ExportPaymentsACH.ExportElectronicPayment(GenJournalLine, GenJournalLine.Amount);
        ExportPaymentsACH.EndExportBatch(ServiceClassCode);
        ExportPaymentsACH.EndExportFile();
    end;

    local procedure ExportPayments_Cecoban(GenJournalLine: Record "Gen. Journal Line")
    var
        ExportPaymentsCecoban: Codeunit "Export Payments (Cecoban)";
    begin
        ExportPaymentsCecoban.StartExportFile(
          GenJournalLine."Bal. Account No.", CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10));
        ExportPaymentsCecoban.StartExportBatch(0, CopyStr(LibraryUtility.GenerateRandomText(10), 1, 10), WorkDate());
        ExportPaymentsCecoban.ExportElectronicPayment(GenJournalLine, GenJournalLine.Amount, WorkDate());
        ExportPaymentsCecoban.EndExportBatch();
        ExportPaymentsCecoban.EndExportFile();
    end;

    local procedure CreateBankAccountWithExportPaths(var BankAccount: Record "Bank Account"; ExportFormat: Option) TempPath: Text
    begin
        TempPath := GetTempPath();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."E-Pay Export File Path" := CopyStr(CreateDirectory(TempPath + 'Misc\'), 1, MaxStrLen(BankAccount."E-Pay Export File Path"));
        BankAccount."E-Pay Trans. Program Path" := CopyStr(CreateDirectory(TempPath + 'Trans\'), 1, MaxStrLen(BankAccount."E-Pay Trans. Program Path"));
        BankAccount."Last E-Pay Export File Name" := 'ExportPayments000.txt';
        BankAccount."Export Format" := ExportFormat;
        BankAccount."Transit No." := GetTransitNo(ExportFormat);
        BankAccount.Modify();
    end;

    local procedure CreateClientExportFile(): Text[30]
    var
        FileName: Text[30];
    begin
        FileName := LibraryUtility.GenerateGUID() + '.txt';
        exit(FileName);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankAccountNo: Code[20]; RecipientBanAccount: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        LibraryUTUtility: Codeunit "Library UT Utility";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, AccountType, AccountNo, LibraryRandom.RandDec(100, 2));
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor then
            GenJournalLine.Amount := -GenJournalLine.Amount;
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Validate("Transaction Code", CopyStr(LibraryUTUtility.GetNewCode10(), 1, MaxStrLen(GenJournalLine."Transaction Code")));
        GenJournalLine.Validate("Company Entry Description", CopyStr(AccountNo, 1, 10));
        GenJournalLine.Validate("Recipient Bank Account", RecipientBanAccount);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateVendorBankAccount(VendorNo: Code[20]; Code: Code[20]; ExportFormat: Option ,US,CA,MX)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount."Vendor No." := VendorNo;
        VendorBankAccount.Code := Code;
        VendorBankAccount."Use for Electronic Payments" := true;
        VendorBankAccount."Transit No." := GetTransitNo(ExportFormat);
        VendorBankAccount."Bank Account No." := VendorNo;
        VendorBankAccount.Insert();
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]; Code: Code[20]; ExportFormat: Option ,US,CA,MX)
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount."Customer No." := CustomerNo;
        CustomerBankAccount.Code := Code;
        CustomerBankAccount."Use for Electronic Payments" := true;
        CustomerBankAccount."Transit No." := GetTransitNo(ExportFormat);
        CustomerBankAccount."Bank Account No." := CustomerNo;
        CustomerBankAccount.Insert();
    end;

    local procedure CreateLongNameVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Vendor.Name), 0));
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreateLongNameCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer.Name), 0));
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure GetTempPath(): Text
    begin
        exit(TemporaryPath + Format(CreateGuid()) + '\');
    end;

    local procedure GetTransitNo(ExportFormat: Option ,US,CA,MX): Text[20]
    begin
        // Special values for Checksum
        case ExportFormat of
            ExportFormat::US:
                exit('123456780');
            ExportFormat::MX:
                exit('123456789012345678');
            else
                exit('');
        end;
    end;

    local procedure GetBankExportFileName(BankAccountNo: Code[20]): Text
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccountNo);
        exit(BankAccount."E-Pay Export File Path" + BankAccount."Last E-Pay Export File Name");
    end;

    local procedure CreateDirectory(FilePathName: Text): Text
    begin
        exit(FilePathName);
    end;

    local procedure ModifyBankAccount(var BankAccount: Record "Bank Account")
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccount.Validate("Export Format", BankAccount."Export Format"::CA);
        BankAccount.Validate("Transit No.", BankAccount."No.");
        BankAccount.Validate("Client No.", BankAccount."No.");
        BankAccount.Validate("Client Name", BankAccount."Client No.");
        BankAccount.Validate("Last E-Pay Export File Name", BankAccount."No.");
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Validate("E-Pay Export File Path", TemporaryPath);
        BankAccount.Validate("Last E-Pay Export File Name", Format(LibraryRandom.RandInt(10)));
        BankAccount.Modify(true);
    end;

    local procedure UpdateCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Federal ID No.", LibraryUtility.GenerateGUID());
        CompanyInformation.Modify();
    end;

    local procedure VerifyMovedFile(BankAccount: Record "Bank Account"; FileName: Text)
    var
        [RunOnClient]
        ClientFileHelper: DotNet File;
    begin
        Assert.IsTrue(
          ClientFileHelper.Exists(BankAccount."E-Pay Trans. Program Path" + FileName),
          StrSubstNo('File is expected to be in folder %1', BankAccount."E-Pay Trans. Program Path"));
        Assert.IsFalse(
          ClientFileHelper.Exists(BankAccount."E-Pay Export File Path" + FileName),
          StrSubstNo('File is not expected to be in folder %1', BankAccount."E-Pay Export File Path"));
    end;

    local procedure FormatNumToPrnString(Number: Integer): Text[250]
    var
        TmpString: Text[250];
    begin
        TmpString := DelChr(Format(Number), '=', '.,-');
        exit(TmpString)
    end;

    local procedure FormatAmtToPrnString(Amount: Decimal): Text[250]
    var
        TmpString: Text[250];
        I: Integer;
    begin
        TmpString := Format(Amount);
        I := StrPos(TmpString, '.');
        case true of
            I = 0:
                TmpString := TmpString + '.00';
            I = StrLen(TmpString) - 1:
                TmpString := TmpString + '0';
        end;
        TmpString := DelChr(TmpString, '=', '.,-');
        exit(TmpString)
    end;

    local procedure ReadExportedFile_ACH_NameValue(FileName: Text): Text
    var
        LineText: Text;
        CustVendName: Text;
        NameLength: Integer;
        i: Integer;
    begin
        NameLength := 100;
        LineText := LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 3, 59, NameLength);
        for i := 1 to StrLen(LineText) - 1 do
            if (LineText[i] = ' ') and (LineText[i + 1] = ' ') then
                NameLength := i - 1;    // Name is followed by two spaces
        CustVendName := CopyStr(LineText, 1, NameLength);
        exit(CustVendName);
    end;

    local procedure ReadExportedFile_Cecoban_NameValue(FileName: Text): Text
    begin
        exit(LibraryTextFileValidation.ReadValueFromLine(CopyStr(FileName, 1, 1024), 2, 91, 40));
    end;

    local procedure VerifyRBFileData(BankAccount: Record "Bank Account"; VendorNo: Code[20]; TotalOfCreditPaymentTrans: Decimal; NumberOfCreditPaymentTrans: Integer)
    var
        FileName: Text[250];
    begin
        FileName := BankAccount."E-Pay Export File Path" + IncStr(BankAccount."Last E-Pay Export File Name");

        // trailer record
        VerifyField(FileName, FormatAmtToPrnString(TotalOfCreditPaymentTrans), 7, 'ZTRL', 27, 14, true); // ZTRL marks trailer record
        VerifyField(FileName, FormatNumToPrnString(NumberOfCreditPaymentTrans), 7, 'ZTRL', 21, 6, true); // ZTRL marks trailer record

        // basic payment record
        VerifyField(FileName, 'C', 22, VendorNo, 7, 1, false); // 'C' marks payment rec
    end;

    local procedure VerifyField(FileName: Text[250]; ExpectedValue: Text[1024]; IdentifierStartingPosition: Integer; IdentifierString: Text[1024]; StartingPosition: Integer; FieldSize: Integer; IsZeroFill: Boolean)
    var
        FieldValue: Text[1024];
        Filler: Text[1];
        FillerString: Text;
    begin
        if IsZeroFill then
            Filler := '0'
        else
            Filler := ' ';

        FillerString := PadStr('', FieldSize - StrLen(ExpectedValue), Filler);

        FieldValue :=
          LibraryTextFileValidation.ReadValue(LibraryTextFileValidation.FindLineWithValue(FileName, IdentifierStartingPosition,
              StrLen(IdentifierString), IdentifierString), StartingPosition, FieldSize);
        Assert.AreEqual(FillerString + ExpectedValue, FieldValue,
          StrSubstNo(FieldsAreNotEqualMsg, PadStr(ExpectedValue, FieldSize, '0'), FieldValue));
    end;

    local procedure VerifyExportedFileACHCustVendorName(ExpectedCustVendName: Text; FileName: Text)
    begin
        Assert.AreEqual(ExpectedCustVendName, ReadExportedFile_ACH_NameValue(FileName), ExportedCVNameErr);
    end;

    local procedure VerifyExportedFileCecobanVendorName(VendorNo: Code[20]; BankAccountNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Assert.AreEqual(
          CopyStr(Vendor.Name, 1, 40), ReadExportedFile_Cecoban_NameValue(GetBankExportFileName(BankAccountNo)), ExportedCVNameErr);
    end;

    local procedure VerifyExportedFileCecobanCustomerName(CustomerNo: Code[20]; BankAccountNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Assert.AreEqual(
          CopyStr(Customer.Name, 1, 40), ReadExportedFile_Cecoban_NameValue(GetBankExportFileName(BankAccountNo)), ExportedCVNameErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

