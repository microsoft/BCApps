codeunit 144012 "Checklist Revenue and VAT Test"
{
    // // [FEATURE] [Report] [Checklist Revenue and VAT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";
        GLEntry2DocumentNoTxt: Label 'G_L_Entry2___Document_No__';

    [Test]
    [HandlerFunctions('HandleRequestPage')]
    [Scope('OnPrem')]
    procedure ValidatePostedJournalLinesOnReport()
    var
        FilterGLAccount: Record "G/L Account";
        ChecklistRevenueAndVAT: Report "Checklist Revenue and VAT";
        Month: Integer;
        GLAccNo: Code[20];
        BalGLAccNo: Code[20];
    begin
        PostGLEntries(GLAccNo, BalGLAccNo);
        FilterGLAccount.SetFilter("No.", '%1|%2', GLAccNo, BalGLAccNo);
        ChecklistRevenueAndVAT.SetTableView(FilterGLAccount);
        ChecklistRevenueAndVAT.Language := 1031;
        ChecklistRevenueAndVAT.Run();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('G_L_Account__No__', GLAccNo);
        for Month := 1 to 12 do
            LibraryReportDataset.AssertElementWithValueExists(StrSubstNo('TotalAmount_%1_', Month), -1000 * Month);
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertElementWithValueExists('G_L_Account__No__', BalGLAccNo);
        for Month := 1 to 12 do
            LibraryReportDataset.AssertElementWithValueExists(StrSubstNo('TotalAmount_%1_', Month), 1000 * Month);
    end;

    [Test]
    [HandlerFunctions('HandleRequestPage')]
    [Scope('OnPrem')]
    procedure NoAmountVATBaseDiffExcludedDataItem()
    var
        FilterGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 363419] Posted Document with no difference in Amount and VAT Base Amount not included in Report 11312 DataItem
        // [GIVEN] Posted Sales Document
        DocumentNo := CreatePostSalesDocument('');
        FilterGLAccount.SetRange("No.", '_');
        // [WHEN] Print Report Checklist Revenue and VAT
        REPORT.Run(REPORT::"Checklist Revenue and VAT", true, true, FilterGLAccount);
        // [THEN] Posted G/L Entry is not included in "G/L Entry2" DataItem
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueNotExist(GLEntry2DocumentNoTxt, DocumentNo);
    end;

    [Test]
    [HandlerFunctions('HandleRequestPage')]
    [Scope('OnPrem')]
    procedure AmountVATBaseDiffIncludedDataItem()
    var
        FilterGLAccount: Record "G/L Account";
        PaymentTerms: Record "Payment Terms";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 363419] Posted Document with difference in Amount and VAT Base Amount included in Report 11312 DataItem
        // [GIVEN] Posted Sales Document with Payment Terms Code and Payment Discount
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
        DocumentNo := CreatePostSalesDocument(PaymentTerms.Code);
        FilterGLAccount.SetRange("No.", '_');
        // [WHEN] Print Report Checklist Revenue and VAT
        REPORT.Run(REPORT::"Checklist Revenue and VAT", true, true, FilterGLAccount);
        // [THEN] Posted G/L Entry is included in "G/L Entry2" DataItem
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(GLEntry2DocumentNoTxt, DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ChecklistRevenueAndVATSaveAsPDF_RPH')]
    [Scope('OnPrem')]
    procedure PrintChecklistRevenueAndVAT()
    var
        FilterGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 333888] Report "Purchase Advice" can be printed without RDLC rendering errors
        DocumentNo := CreatePostSalesDocument('');
        FilterGLAccount.SetRange("No.", '_');
        // [WHEN] Report "Purchase Advice" is being printed to PDF
        REPORT.Run(REPORT::"Checklist Revenue and VAT", true, true, FilterGLAccount);
        // [THEN] No RDLC rendering errors
    end;

    local procedure PostGLEntries(var GLAccNo: Code[20]; var BalGLAccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        BalanceGLAccount: Record "G/L Account";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        MonthCounter: Integer;
        PostingDate: Date;
    begin
        // Make G/L Account setup
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(BalanceGLAccount);
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);

        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch."Bal. Account Type" := GenJnlBatch."Bal. Account Type"::"G/L Account";
        GenJnlBatch."Bal. Account No." := BalanceGLAccount."No.";
        GenJnlBatch.Modify();

        // Post a line every month
        for MonthCounter := 1 to 12 do begin
            PostingDate := DMY2Date(1, MonthCounter, Date2DMY(WorkDate(), 3));
            LibraryERM.CreateGeneralJnlLine(
              GenJnlLine, GenJnlTemplate.Name, GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
              GenJnlLine."Account Type"::"G/L Account", GLAccount."No.", 1000 * MonthCounter);
            GenJnlLine."Posting Date" := PostingDate;
            CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Line", GenJnlLine);
        end;
        Commit();

        GLAccNo := GLAccount."No.";
        BalGLAccNo := BalanceGLAccount."No.";
    end;

    local procedure CreatePostSalesDocument(PaymentTermsCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Payment Terms Code", PaymentTermsCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure HandleRequestPage(var RequestPage: TestRequestPage "Checklist Revenue and VAT")
    begin
        RequestPage.StartDate.SetValue := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
        RequestPage.NoOfPeriods.SetValue := 12;
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ChecklistRevenueAndVATSaveAsPDF_RPH(var RequestPage: TestRequestPage "Checklist Revenue and VAT")
    begin
        RequestPage.StartDate.SetValue := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
        RequestPage.NoOfPeriods.SetValue := 12;
        RequestPage.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;
}

