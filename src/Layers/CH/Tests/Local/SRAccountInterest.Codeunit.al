codeunit 144036 "SR Account Interest"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        RequestPageAccountType: Option "G/L",Customer,Vendor,Bank;
        LengthOfYear: Option "360 Days","Actual Days (365/366)";
        AccountNoMissingErr: Label 'Account no, interest rate, start date, end date and interest date must be specified.';

    [Test]
    [HandlerFunctions('ReportRequestPageHandler,ConfimHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure AccountInterestGLEntryTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalLineDocumentNo: Code[20];
        CustomerNo: Code[20];
        Amount: Decimal;
    begin
        // Create Customer
        CustomerNo := CreateCustomer();
        Amount := LibraryRandom.RandDec(10000, 2);

        // Create and Post General Journal Line
        JournalLineDocumentNo := CreateAndPostGenJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // Exercise.
        LibraryVariableStorage.Enqueue(RequestPageAccountType::"G/L");
        LibraryVariableStorage.Enqueue(1000);

        REPORT.Run(REPORT::"SR Account Interest", true, false);

        // Verify
        VerifyReportData('Inv', 'GLEntry', JournalLineDocumentNo, -1 * Amount);
    end;

    [Test]
    [HandlerFunctions('ReportRequestPageHandler,ConfimHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure AccountInterestCustomerTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalLineDocumentNo: Code[20];
        CustomerNo: Code[20];
        Amount: Decimal;
    begin
        // Create Customer
        CustomerNo := CreateCustomer();
        Amount := LibraryRandom.RandDec(10000, 2);

        // Create and Post General Journal Line
        JournalLineDocumentNo := CreateAndPostGenJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // Exercise.
        LibraryVariableStorage.Enqueue(RequestPageAccountType::Customer);
        LibraryVariableStorage.Enqueue(CustomerNo);

        REPORT.Run(REPORT::"SR Account Interest", true, false);

        // Verify
        VerifyReportData('Inv', 'CustLedgEntry', JournalLineDocumentNo, Amount);
    end;

    [Test]
    [HandlerFunctions('ReportRequestPageHandler,ConfimHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure AccountInterestVendorTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalLineDocumentNo: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
    begin
        // Create Vendor
        VendorNo := CreateVendor();
        Amount := LibraryRandom.RandDec(10000, 2);

        // Create and Post General Journal Line
        JournalLineDocumentNo := CreateAndPostGenJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);

        // Exercise.
        LibraryVariableStorage.Enqueue(RequestPageAccountType::Vendor);
        LibraryVariableStorage.Enqueue(VendorNo);

        REPORT.Run(REPORT::"SR Account Interest", true, false);

        // Verify
        VerifyReportData('Pay', 'VendLedgEntry', JournalLineDocumentNo, Amount);
    end;

    [Test]
    [HandlerFunctions('ReportRequestPageHandler,ConfimHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure AccountInterestBankTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalLineDocumentNo: Code[20];
        BankNo: Code[20];
        Amount: Decimal;
    begin
        // Create Bank
        BankNo := CreateBankAccount();
        Amount := LibraryRandom.RandDec(10000, 2);

        // Create and Post General Journal Line
        JournalLineDocumentNo := CreateAndPostGenJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"Bank Account", BankNo, Amount);

        // Exercise.
        LibraryVariableStorage.Enqueue(RequestPageAccountType::Bank);
        LibraryVariableStorage.Enqueue(BankNo);

        REPORT.Run(REPORT::"SR Account Interest", true, false);

        // Verify
        VerifyReportData('Inv', 'BankAccLedgEntry', JournalLineDocumentNo, Amount);
    end;

    [Test]
    [HandlerFunctions('ReportRequestPageHandler,ConfimHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure AccountInterestErrorTest()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        Amount: Decimal;
    begin
        // Create Customer
        CustomerNo := CreateCustomer();
        Amount := LibraryRandom.RandDec(10000, 2);

        // Create and Post General Journal Line
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);

        // Exercise.
        LibraryVariableStorage.Enqueue(RequestPageAccountType::Customer);
        LibraryVariableStorage.Enqueue('');

        asserterror REPORT.Run(REPORT::"SR Account Interest", true, false);

        // Verify: To check that error is encountered on missing Account No / Customer No.
        Assert.ExpectedError(AccountNoMissingErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportRequestPageHandler(var SRAccountInterest: TestRequestPage "SR Account Interest")
    var
        AccountType: Variant;
        AccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccountType);
        LibraryVariableStorage.Dequeue(AccountNo);

        SRAccountInterest."Account Type".SetValue(AccountType);
        SRAccountInterest."Account No.".SetValue(AccountNo);
        SRAccountInterest."From Date".SetValue(WorkDate());
        SRAccountInterest.EndDate.SetValue(WorkDate()); // To Date
        SRAccountInterest."Interest Date".SetValue(WorkDate());
        SRAccountInterest."Interest Rate %".SetValue(5);
        SRAccountInterest."No of Days per Year".SetValue(LengthOfYear::"360 Days");
        SRAccountInterest."With Start Balance".SetValue(false);
        SRAccountInterest."Show Interest per Line".SetValue(true);

        SRAccountInterest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Normal]
    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DocumentNo: Code[20];
    begin
        SelectAndClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", '1000'); // Cash Account
        GenJournalLine.Modify();
        DocumentNo := GenJournalLine."Document No.";
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJournalLine);
        exit(DocumentNo);
    end;

    local procedure VerifyReportData(DocumentTypeStr: Text; DocElementNamePrefix: Text; AccountNo: Code[20]; Amount: Decimal)
    var
        Value: Variant;
        FoundAccountNo: Boolean;
        CodeValue: Code[20];
        ExpectedInterestAmount: Decimal;
    begin
        // Verify the XML

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetNextRow();

        FoundAccountNo := false;
        ExpectedInterestAmount := CalculateExpectedInterestAmount(Amount);

        repeat
            // Find Document No.
            LibraryReportDataset.FindCurrentRowValue('DocNo_' + DocElementNamePrefix, Value);
            CodeValue := VariantToCode(Value);

            if CodeValue = AccountNo then begin
                FoundAccountNo := true;

                // Validate Document Type
                LibraryReportDataset.AssertCurrentRowValueEquals('DocType_' + DocElementNamePrefix, DocumentTypeStr);

                // Validate Interest Amount
                LibraryReportDataset.AssertCurrentRowValueEquals('InterestAmt', ExpectedInterestAmount);
            end;

        until LibraryReportDataset.GetNextRow() = false;

        Assert.IsTrue(FoundAccountNo, 'The Posted Document No. was not found in Report.');
    end;

    local procedure VariantToCode(Value: Variant): Code[20]
    var
        CodeValue: Code[20];
    begin
        Evaluate(CodeValue, Value);
        exit(CodeValue);
    end;

    local procedure CalculateExpectedInterestAmount(Amount: Decimal): Decimal
    var
        Temp: Decimal;
    begin
        Temp := Round((Amount * 5) / (100 * 360), 0.01);
        exit(Temp);
    end;

    local procedure SelectAndClearGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfimHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

