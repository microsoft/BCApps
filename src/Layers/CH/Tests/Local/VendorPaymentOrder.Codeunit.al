codeunit 144024 "Vendor Payment Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        IncorrectBankCodeErr: Label 'Incorrect Bank Code.';

    [Test]
    [HandlerFunctions('VendorPaymentOrderRequestPageHandlerBatchName')]
    [Scope('OnPrem')]
    procedure RunVendorPaymentOrderReportBatchName()
    var
        VendorName: Text[100];
    begin
        Initialize();

        // Setup
        VendorName := CreateVendorWithVendorBankAccCreateVendorPayments();

        // Exercise
        REPORT.Run(REPORT::"Vendor Payment Order", true, false);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        VerifyNumberOfRowsAndVendor(VendorName);

        LibraryReportDataset.AssertCurrentRowValueEquals('ShowAdrLines', false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VendorPaymentOrderRequestPageHandlerBatchNameDebitDate')]
    [Scope('OnPrem')]
    procedure RunVendorPaymentOrderReportBatchNameDebitDate()
    var
        VendorName: Text[100];
    begin
        Initialize();

        // Setup
        VendorName := CreateVendorWithVendorBankAccCreateVendorPayments();

        // Exercise
        REPORT.Run(REPORT::"Vendor Payment Order", true, false);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        VerifyNumberOfRowsAndVendor(VendorName);

        LibraryReportDataset.AssertCurrentRowValueEquals('DebitDate', Format(WorkDate()));
        LibraryReportDataset.AssertCurrentRowValueEquals('ShowAdrLines', false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VendorPaymentOrderRequestPageHandlerBatchNameDebitDateShowAddressLines')]
    [Scope('OnPrem')]
    procedure RunVendorPaymentOrderReportBatchNameDebitDateShowAddressLines()
    var
        VendorName: Text[100];
    begin
        Initialize();

        // Setup
        VendorName := CreateVendorWithVendorBankAccCreateVendorPayments();

        // Exercise
        REPORT.Run(REPORT::"Vendor Payment Order", true, false);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        VerifyNumberOfRowsAndVendor(VendorName);

        LibraryReportDataset.AssertCurrentRowValueEquals('DebitDate', Format(WorkDate()));
        LibraryReportDataset.AssertCurrentRowValueEquals('ShowAdrLines', true);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferVendorPreferableBankToPurchHeaderBankCode()
    var
        VendorBankAccount: Record "Vendor Bank Account";
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        // Setup
        CreateVendorWithVendorBankAcc(VendorBankAccount, '', '', '');

        // Exercise
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorBankAccount."Vendor No.");

        // Verify
        Assert.AreEqual(VendorBankAccount.Code, PurchaseHeader."Bank Code", IncorrectBankCodeErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure VerifyNumberOfRowsAndVendor(VendorName: Text[100])
    var
        ElementValue: Variant;
    begin
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), 'Wrong number of rows in the dataset.');
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetElementValueInCurrentRow('Text1', ElementValue);
        Assert.IsTrue(StrPos(ElementValue, VendorName) > 0, 'Vendor Name was not found.');
    end;

    local procedure CreateVendorWithVendorBankAccCreateVendorPayments() VendorName: Text[100]
    var
        Vendor: Record Vendor;
        VendorBankAcc: Record "Vendor Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        // Setup

        // 1. Vendor and bank account
        CreateVendorWithVendorBankAcc(VendorBankAcc, '', '', '');

        // 2. Run suggest vendor payments report
        SelectGenJournalBatch(GenJournalBatch);
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);

        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.InitializeRequest(
          WorkDate(), true, 0, false, WorkDate(), '1', true,
          GenJournalLine."Bal. Account Type"::"G/L Account", SelectGLAccount(), GenJournalLine."Bank Payment Type"::" ");
        SuggestVendorPayments.UseRequestPage(false);
        Vendor.SetRange("No.", VendorBankAcc."Vendor No.");
        SuggestVendorPayments.SetTableView(Vendor);
        SuggestVendorPayments.RunModal();

        Vendor.SetRange("No.", VendorBankAcc."Vendor No.");
        Vendor.FindFirst();
        VendorName := Vendor.Name;
    end;

    local procedure CreateVendorWithVendorBankAcc(var VendorBankAccount: Record "Vendor Bank Account"; BankBranchNo: Text[20]; BankAccountNo: Text[30]; NewIBAN: Code[50])
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, FindVendor());

        VendorBankAccount."Bank Branch No." := BankBranchNo;
        VendorBankAccount."Bank Account No." := BankAccountNo;
        VendorBankAccount.IBAN := NewIBAN;
        VendorBankAccount.Modify();

        Vendor.Get(VendorBankAccount."Vendor No.");
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount.Code);
        Vendor.Modify(true);
    end;

    local procedure FindVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetRange("Date Filter", 0D, CalcDate('<1D>', WorkDate()));
        Vendor.SetFilter("Balance Due (LCY)", '>%1', 0);
        Vendor.SetFilter("Balance (LCY)", '>%1', 0);
        Vendor.SetRange("Currency Code", '');
        Vendor.FindFirst();
        exit(Vendor."No.");
    end;

    local procedure SelectGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        LibraryERM.FindGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.FindFirst();
        GenJournalBatch.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.FindFirst();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPaymentOrderRequestPageHandlerBatchName(var RequestPage: TestRequestPage "Vendor Payment Order")
    var
        BatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BatchName);
        RequestPage.JourName.SetValue(BatchName);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPaymentOrderRequestPageHandlerBatchNameDebitDate(var RequestPage: TestRequestPage "Vendor Payment Order")
    var
        BatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BatchName);
        RequestPage.JourName.SetValue(BatchName);
        RequestPage.DebitDate.SetValue(WorkDate());
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorPaymentOrderRequestPageHandlerBatchNameDebitDateShowAddressLines(var RequestPage: TestRequestPage "Vendor Payment Order")
    var
        BatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BatchName);
        RequestPage.JourName.SetValue(BatchName);
        RequestPage.DebitDate.SetValue(WorkDate());
        RequestPage.ShowAdrLines.SetValue(true);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

