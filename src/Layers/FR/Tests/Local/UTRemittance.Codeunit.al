codeunit 144057 "UT Remittance"
{
    // 1. Purpose of the test is to validate OnAfterGetRecord - Bank Account Code On report 10843 - Recapitulation Form.
    // 2. Purpose of the test is to validate OnAfterGetRecord - Customer Code On report 10843 - Recapitulation Form.
    // 3. Purpose of the test is to validate OnAfterGetRecord - Gen. Journal Line On report 10843 - Recapitulation Form.
    // 4. Purpose of the test is to validate OnPreDataItem -  Gen. Journal Line On report 10843 - Recapitulation Form.
    // 5. Purpose of the test is to Open Check Remittance report through Page 255 - Cash Receipt Journal.
    // 
    // Covers Test Cases for WI - 344648.
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                              TFS ID
    // ------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordBankAccountRecapitulationForm,OnAfterGetRecordCustomerRecapitulationForm        154983
    // OnAfterGetRecordGenJournalLineRecapitulationForm,OnPreDataItemGenJournalLineRecapitulationForm  155364,154984
    // CheckRemittanceReport                                                                           151203,151204,151205

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('RecapitulationFormRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBankAccountRecapitulationForm()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Bank Account Code On report 10843 Recapitulation Form.
        // Setup.
        Initialize();
        CreateGenJournalLineAndRunRecapitulationForm(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(), '', '', CreateBankAccount());  // Using blank for Bank Account Code and Currency Code.

        // Verify: Bal. Account No.,Account No. and Amount on report.
        VerifyValuesOnReportRecapitulationForm(GenJournalLine."Bal. Account No.", GenJournalLine."Account No.", GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('RecapitulationFormRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCustomerRecapitulationForm()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Customer Code On report 10843 Recapitulation Form.
        // Setup.
        Initialize();
        CustomerNo := CreateCustomer();
        CreateGenJournalLineAndRunRecapitulationForm(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo, CreateCustomerBankAccount(CustomerNo),
          LibraryUTUtility.GetNewCode10(), CreateBankAccount());  // Using LibraryUTUtility.GetNewCode10 for Currency Code.

        // Verify: Bal. Account No.,Account No. and Amount on report.
        VerifyValuesOnReportRecapitulationForm(GenJournalLine."Bal. Account No.", GenJournalLine."Account No.", GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('RecapitulationFormRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGenJournalLineRecapitulationForm()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is validate OnAfterGetRecord - Gen. Journal Line On report 10843 Recapitulation Form.
        // Using LibraryUTUtility.GetNewCode() for G/L Account No., blank for Bank Account Code and Currency Code.
        // Setup.
        Initialize();
        CreateGenJournalLineAndRunRecapitulationForm(
          GenJournalLine, GenJournalLine."Account Type"::"G/L Account", LibraryUTUtility.GetNewCode(), '', '', CreateBankAccount());

        // Verify: Verify Amount on Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('GenJnlLine_Amount', GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('RecapitulationFormRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemGenJournalLineRecapitulationForm()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Purpose of the test is to validate OnPreDataItem -  Gen. Journal Line On report 10843 Recapitulation Form.
        // Setup.
        Initialize();
        CreateGenJournalLineAndRunRecapitulationForm(
          GenJournalLine, GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(), '', '', '');  // Using blank for Bank Account Code,Currency Code and Bank Account No.

        // Verify: RecapitulationFormRequestPageHandler opens successfully.  Blank report generate in this case.
    end;

    local procedure CreateGenJournalLineAndRunRecapitulationForm(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankAccountCode: Code[20]; CurrencyCode: Code[10]; BalAccountNo: Code[20])
    begin
        // Setup.
        CreateGenJournalLine(GenJournalLine, AccountType, AccountNo, BankAccountCode, CurrencyCode, BalAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");  // Enqueue for RecapitulationFormRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Recapitulation Form");  // Opens RecapitulationFormRequestPageHandler.
    end;

    [Test]
    [HandlerFunctions('RecapitulationFormRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckRemittanceReport()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // Purpose of the test is to Open Check Remittance report through Page 255 Cash Receipt Journal.

        // Setup.
        Initialize();
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(), '', '', CreateBankAccount());  // Using blank for Bank Account Code and Currency Code.
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account No.");  // Enqueue for RecapitulationFormRequestPageHandler.
        Commit();  // Commit is required to run report. Since runmodal is used in page 255 Cash Receipt Journal.
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.FILTER.SetFilter("Account No.", GenJournalLine."Account No.");

        // Exercise.
        CashReceiptJournal.PrintCheckRemittanceReport.Invoke();

        // Verify: Verify Debit Amount on Page.
        CashReceiptJournal."Debit Amount".AssertEquals(GenJournalLine."Debit Amount");
        CashReceiptJournal.Close();
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Clear();
        GenJournalLine.DeleteAll();
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount."No." := LibraryUTUtility.GetNewCode();
        BankAccount.Insert();
        exit(BankAccount."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer.Insert();
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount."Customer No." := CustomerNo;
        CustomerBankAccount.Code := LibraryUTUtility.GetNewCode10();
        CustomerBankAccount.Insert();
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BankAccountCode: Code[10]; CurrencyCode: Code[10]; BalAccountNo: Code[20])
    begin
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine.Amount := LibraryRandom.RandDec(10, 2);  // Using random for Amount.
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"Bank Account";
        GenJournalLine."Bal. Account No." := BalAccountNo;
        GenJournalLine."Recipient Bank Account" := BankAccountCode;
        GenJournalLine."Currency Code" := CurrencyCode;
        GenJournalLine.Insert();
    end;

    local procedure VerifyValuesOnReportRecapitulationForm(BalAccountNo: Code[20]; AccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Bank_Account__No__', BalAccountNo);
        LibraryReportDataset.AssertElementWithValueExists('Gen__Journal_Line_Account_No_', AccountNo);
        LibraryReportDataset.AssertElementWithValueExists('GenJnlLine_Amount', Amount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RecapitulationFormRequestPageHandler(var RecapitulationForm: TestRequestPage "Recapitulation Form")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        RecapitulationForm."Bank Account".SetFilter("No.", No);
        RecapitulationForm.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

