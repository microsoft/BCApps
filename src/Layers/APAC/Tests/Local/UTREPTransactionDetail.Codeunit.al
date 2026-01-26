codeunit 141074 "UT REP Transaction Detail"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [Transaction Detail]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AdditionalCurrencyAmountCap: Label 'G_L_Entry__Additional_Currency_Amount_';
        AmountCap: Label 'G_L_Entry_Amount';
        DateFilterTxt: Label '%1..%2';
        VATAmountCap: Label 'G_L_Entry__VAT_Amount_';

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntrySrcTypeCustDocTypeInv()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with Source Type Customer and Document Type Invoice.
        OnAfterGetRecordGLEntry(
          GLEntry."Source Type"::Customer, CreateCustomer(), GLEntry."Document Type"::Invoice, CreateSalesInvoiceHeader());
    end;

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntrySrcTypeCustDocTypeCrMemo()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with Source Type Customer and Document Type Credit Memo.
        OnAfterGetRecordGLEntry(
          GLEntry."Source Type"::Customer, CreateCustomer(), GLEntry."Document Type"::"Credit Memo", CreateSalesCrMemoHeader());
    end;

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntrySrcTypeCustDocTypeFinChrgMemo()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with Source Type Customer and Document Type Finance Charge Memo.
        OnAfterGetRecordGLEntry(
          GLEntry."Source Type"::Customer, CreateCustomer(), GLEntry."Document Type"::"Finance Charge Memo", CreateFinanceMemoHeader());
    end;

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntrySrcTypeCustDocTypeReminder()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with Source Type Customer and Document Type Reminder.
        OnAfterGetRecordGLEntry(GLEntry."Source Type"::Customer, CreateCustomer(), GLEntry."Document Type"::Reminder, CreateReminderHeader());
    end;

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntrySrcTypeVendDocTypeInv()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with Source Type Vendor and Document Type Invoice.
        OnAfterGetRecordGLEntry(GLEntry."Source Type"::Vendor, CreateVendor(), GLEntry."Document Type"::Invoice, CreatePurchInvoiceHeader());
    end;

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntrySrcTypeVendDocTypeCrMemo()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with Source Type Vendor and Document Type Credit Memo.
        OnAfterGetRecordGLEntry(
          GLEntry."Source Type"::Vendor, CreateVendor(), GLEntry."Document Type"::"Credit Memo", CreatePurchCrMemoHeader());
    end;

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntrySrcTypeBankAccount()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with Source Type Bank Account.
        OnAfterGetRecordGLEntry(GLEntry."Source Type"::"Bank Account", CreateBankAccount(), GLEntry."Document Type"::" ", '');  // Using Blank for Document Type and Document No.
    end;

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntrySrcTypeFADocTypeInv()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with Source Type Fixed Asset and Document Type Invoice.
        OnAfterGetRecordGLEntry(
          GLEntry."Source Type"::"Fixed Asset", CreateFixedAsset(), GLEntry."Document Type"::Invoice, CreatePurchInvoiceHeader());
    end;

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntrySrcTypeFADocTypeCrMemo()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with Source Type Fixed Asset and Document Type Credit Memo.
        OnAfterGetRecordGLEntry(
          GLEntry."Source Type"::"Fixed Asset", CreateFixedAsset(), GLEntry."Document Type"::"Credit Memo", CreatePurchCrMemoHeader());
    end;

    local procedure OnAfterGetRecordGLEntry(SourceType: Enum "Gen. Journal Source Type"; SourceNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        // Setup and Exercise.
        Initialize();
        CreateGLEntryAndRunTransactionDetailReport(GLEntry, WorkDate(), SourceType, SourceNo, DocumentType, DocumentNo, true);  // Using True for ShowAmountsInAddReportingCurrency.

        // Verify.
        VerifyAmountsOnTransactionDetailReport(GLEntry.Amount, GLEntry."VAT Amount", GLEntry."Additional-Currency Amount");
    end;

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntryShowAmtInAddReportingCurrFalse()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with ShowAmountsInAddReportingCurrency as False.

        // Setup and Exercise.
        Initialize();
        CreateGLEntryAndRunTransactionDetailReport(
          GLEntry, ClosingDate(WorkDate()), GLEntry."Source Type"::Customer, CreateCustomer(), GLEntry."Document Type"::Invoice,
          CreateSalesInvoiceHeader(), false);  // Using False for ShowAmountsInAddReportingCurrency.

        // Verify.
        VerifyAmountsOnTransactionDetailReport(0, 0, GLEntry."Additional-Currency Amount");  // Using 0 for Amount and VAT Amount.
    end;

    [Test]
    [HandlerFunctions('TransactionDetailRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecGLEntryShowAmtInAddReportingCurrTrue()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] validate G/L Entry - OnAfterGetRecord Trigger of Report - 17109 with ShowAmountsInAddReportingCurrency as True.

        // Setup and Exercise.
        Initialize();
        CreateGLEntryAndRunTransactionDetailReport(
          GLEntry, ClosingDate(WorkDate()), GLEntry."Source Type"::Customer, CreateCustomer(), GLEntry."Document Type"::Invoice,
          CreateSalesInvoiceHeader(), true);  // Using True for ShowAmountsInAddReportingCurrency.

        // Verify.
        VerifyAmountsOnTransactionDetailReport(GLEntry.Amount, GLEntry."VAT Amount", 0);  // Using 0 for Additional Currency Amount.
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

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry"; PostingDate: Date; SourceType: Enum "Gen. Journal Source Type"; SourceNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry."G/L Account No." := CreateGLAccount();
        GLEntry.Amount := LibraryRandom.RandDec(100, 2);
        GLEntry."VAT Amount" := LibraryRandom.RandDec(100, 2);
        GLEntry."Additional-Currency Amount" := LibraryRandom.RandDec(100, 2);
        GLEntry."Posting Date" := PostingDate;
        GLEntry."Source Type" := SourceType;
        GLEntry."Source No." := SourceNo;
        GLEntry."Document Type" := DocumentType;
        GLEntry."Document No." := DocumentNo;
        GLEntry.Insert();
    end;

    local procedure CreateGLEntryAndRunTransactionDetailReport(var GLEntry: Record "G/L Entry"; PostingDate: Date; SourceType: Enum "Gen. Journal Source Type"; SourceNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; ShowAmountsInAddReportingCurrency: Boolean)
    begin
        // Setup.
        CreateGLEntry(GLEntry, PostingDate, SourceType, SourceNo, DocumentType, DocumentNo);

        // Enqueue values for TransactionDetailRequestPageHandler.
        LibraryVariableStorage.Enqueue(ShowAmountsInAddReportingCurrency);
        LibraryVariableStorage.Enqueue(GLEntry."G/L Account No.");

        // Exercise.
        REPORT.Run(REPORT::"Transaction Detail Report");  // Opens TransactionDetailRequestPageHandler.
    end;

    local procedure CreateFinanceMemoHeader(): Code[20]
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        FinanceChargeMemoHeader."No." := LibraryUTUtility.GetNewCode();
        FinanceChargeMemoHeader.Insert();
        exit(FinanceChargeMemoHeader."No.");
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        FixedAsset."No." := LibraryUTUtility.GetNewCode();
        FixedAsset.Insert();
        exit(FixedAsset."No.");
    end;

    local procedure CreatePurchCrMemoHeader(): Code[20]
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr."No." := LibraryUTUtility.GetNewCode();
        PurchCrMemoHdr.Insert();
        exit(PurchCrMemoHdr."No.");
    end;

    local procedure CreatePurchInvoiceHeader(): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader.Insert();
        exit(PurchInvHeader."No.");
    end;

    local procedure CreateReminderHeader(): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
    begin
        ReminderHeader."No." := LibraryUTUtility.GetNewCode();
        ReminderHeader.Insert();
        exit(ReminderHeader."No.");
    end;

    local procedure CreateSalesCrMemoHeader(): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        SalesCrMemoHeader.Insert();
        exit(SalesCrMemoHeader."No.");
    end;

    local procedure CreateSalesInvoiceHeader(): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        SalesInvoiceHeader.Insert();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure VerifyAmountsOnTransactionDetailReport(Amount: Decimal; VATAmount: Decimal; AdditionalCurrencyAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(AmountCap, Amount);
        LibraryReportDataset.AssertElementWithValueExists(VATAmountCap, VATAmount);
        LibraryReportDataset.AssertElementWithValueExists(AdditionalCurrencyAmountCap, AdditionalCurrencyAmount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransactionDetailRequestPageHandler(var TransactionDetailReport: TestRequestPage "Transaction Detail Report")
    var
        No: Variant;
        ShowAmountsInAddReportingCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountsInAddReportingCurrency);
        LibraryVariableStorage.Dequeue(No);
        TransactionDetailReport."G/L Account".SetFilter("No.", No);
        TransactionDetailReport."G/L Account".SetFilter("Date Filter", StrSubstNo(DateFilterTxt, WorkDate(), ClosingDate(WorkDate())));
        TransactionDetailReport.ShowAmountsInAddReportingCurrency.SetValue(ShowAmountsInAddReportingCurrency);
        TransactionDetailReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

