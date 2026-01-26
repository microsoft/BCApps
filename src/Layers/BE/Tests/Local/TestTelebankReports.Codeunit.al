codeunit 144020 "Test Telebank Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Message1PrefixTxt: Label 'Message1:%1';
        ReferencePrefixTxt: Label 'Reference:%1';
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";

    [HandlerFunctions('HandleDomiciliationJournalTestReport')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DomiciliationJournalReportTest()
    var
        DomiciliationCustomer: Record Customer;
        DomiciliationBankAccount: Record "Bank Account";
        DomiciliationJournalTemplate: Record "Domiciliation Journal Template";
        DomiciliationJournalBatch: Record "Domiciliation Journal Batch";
        BankAccountNo: Text[12];
        TotalAmount: Decimal;
        MonthCounter: Integer;
    begin
        // Setup
        LibraryERM.CreateBankAccount(DomiciliationBankAccount);
        DomiciliationBankAccount.Validate("No.", '000000000097');
        DomiciliationBankAccount.Validate(Name, DomiciliationBankAccount."No.");
        DomiciliationBankAccount.Insert();

        LibrarySales.CreateCustomer(DomiciliationCustomer);
        BankAccountNo := DelStr(DomiciliationBankAccount."No.", 13);
        DomiciliationCustomer.Validate("Domiciliation No.", BankAccountNo);
        DomiciliationCustomer.Modify();
        DomiciliationJournalTemplate.Validate("Bank Account No.", BankAccountNo);

        CreateDomiciliationJournalTemplate(DomiciliationJournalTemplate);
        CreateDomiciliationJournalBatch(DomiciliationJournalTemplate, DomiciliationJournalBatch);
        CreateDomiciliationJournalLines(DomiciliationJournalBatch, DomiciliationBankAccount, DomiciliationCustomer);

        // Execution
        REPORT.Run(REPORT::"Domiciliation Journal - Test", true, false, DomiciliationJournalBatch);

        // Validation
        LibraryReportDataset.LoadDataSetFile();

        for MonthCounter := 1 to 12 do begin
            LibraryReportDataset.AssertElementWithValueExists(
              'Message1_DomiciliationJnlLine', StrSubstNo(Message1PrefixTxt, MonthCounter));
            LibraryReportDataset.AssertElementWithValueExists(
              'Amount_DomiciliationJnlLine', MonthCounter * 1000);
            LibraryReportDataset.AssertElementWithValueExists(
              'PmtDiscPossible_DomiciliationJnlLine', MonthCounter * 100);
            LibraryReportDataset.AssertElementWithValueExists(
              'PostingDateFormatted_DomiciliationJnlLine', Format(DMY2Date(1, MonthCounter, Date2DMY(WorkDate(), 3))));
            LibraryReportDataset.AssertElementWithValueExists(
              'Reference_DomiciliationJnlLine', StrSubstNo(ReferencePrefixTxt, MonthCounter));

            TotalAmount += MonthCounter * 1000;
            LibraryReportDataset.AssertElementWithValueExists('TotalAmount', TotalAmount);
            LibraryReportDataset.GetNextRow();
        end;
    end;

    local procedure CreateDomiciliationJournalTemplate(var DomiciliationJournalTemplate: Record "Domiciliation Journal Template")
    begin
        DomiciliationJournalTemplate.Validate(Name, CopyStr(CreateGuid(), 1, MaxStrLen(DomiciliationJournalTemplate.Name)));
        DomiciliationJournalTemplate.Insert();
    end;

    local procedure CreateDomiciliationJournalBatch(DomiciliationJournalTemplate: Record "Domiciliation Journal Template"; var DomiciliationJournalBatch: Record "Domiciliation Journal Batch")
    begin
        DomiciliationJournalBatch.Validate("Journal Template Name", DomiciliationJournalTemplate.Name);
        DomiciliationJournalBatch.SetRange("Journal Template Name", DomiciliationJournalBatch."Journal Template Name");
        DomiciliationJournalBatch.Validate(Name, CopyStr(CreateGuid(), 1, MaxStrLen(DomiciliationJournalBatch.Name)));
        DomiciliationJournalBatch.Insert();
    end;

    local procedure CreateDomiciliationJournalLines(DomiciliationJournalBatch: Record "Domiciliation Journal Batch"; DomiciliationBankAccount: Record "Bank Account"; DomiciliationCustomer: Record Customer)
    var
        DomiciliationJournalLine: Record "Domiciliation Journal Line";
        MonthCounter: Integer;
    begin
        for MonthCounter := 1 to 12 do begin
            DomiciliationJournalLine.Init();
            DomiciliationJournalLine.Validate("Customer No.", DomiciliationCustomer."No.");
            DomiciliationJournalLine.Validate("Bank Account No.", DomiciliationBankAccount."No.");
            DomiciliationJournalLine.Validate("Message 1", StrSubstNo(Message1PrefixTxt, MonthCounter));
            DomiciliationJournalLine.Validate(Amount, MonthCounter * 1000);
            DomiciliationJournalLine.Validate("Posting Date", DMY2Date(1, MonthCounter, Date2DMY(WorkDate(), 3)));
            DomiciliationJournalLine.Validate("Pmt. Disc. Possible", MonthCounter * 100);
            DomiciliationJournalLine.Validate("Pmt. Discount Date", DMY2Date(1, MonthCounter, Date2DMY(WorkDate(), 3)));
            DomiciliationJournalLine.Validate(Reference, StrSubstNo(ReferencePrefixTxt, MonthCounter));
            DomiciliationJournalLine.Validate("Journal Template Name", DomiciliationJournalBatch."Journal Template Name");
            DomiciliationJournalLine.Validate("Journal Batch Name", DomiciliationJournalBatch.Name);
            DomiciliationJournalLine.SetRange("Journal Template Name", DomiciliationJournalLine."Journal Template Name");
            DomiciliationJournalLine.SetRange("Journal Batch Name", DomiciliationJournalLine."Journal Batch Name");
            DomiciliationJournalLine.Validate("Line No.", DomiciliationJournalLine.Amount);
            DomiciliationJournalLine.Insert();
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure HandleDomiciliationJournalTestReport(var RequestPage: TestRequestPage "Domiciliation Journal - Test")
    begin
        RequestPage.ShowDim.SetValue(true);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

