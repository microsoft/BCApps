codeunit 144707 "ERM Advance Statement"
{
    // // [FEATURE] [Purchases] [Advance Statement]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRUReports: Codeunit "Library RU Reports";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        TestRowNoFoundErr: Label 'TestRowNotFound';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoice_SimpleInvoice_ReportContainsInvoiceNoInHeader()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchInvoiceAndPrintAdvStatement(PurchaseHeader, LibraryRandom.RandIntInRange(2, 5));
        LibraryReportValidation.VerifyCellValue(13, 19, PurchaseHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoice_MultipleLines_ReportContainsValidTotal()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchInvoiceAndPrintAdvStatement(PurchaseHeader, LibraryRandom.RandIntInRange(2, 5));
        LibraryReportValidation.VerifyCellValue(
          65, 25, LibraryRUReports.GetPurchaseTotalAmountIncVAT(PurchaseHeader."Document Type"::Invoice, PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoice_SimpleInvoice_ReportContainsInvoiceNoInHeader()
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := CreateAndPostPurchInvoiceAndPrintAdvStatement(LibraryRandom.RandIntInRange(2, 5));
        LibraryReportValidation.VerifyCellValue(13, 19, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoice_MultipleLines_ReportContainsValidTotal()
    var
        DocumentNo: Code[20];
    begin
        DocumentNo := CreateAndPostPurchInvoiceAndPrintAdvStatement(LibraryRandom.RandIntInRange(2, 5));
        LibraryReportValidation.VerifyCellValue(
          65, 25, LibraryRUReports.GetPostedPurchaseTotalAmountIncVAT(DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_PurchInvoicesPageDoesNotShowAdvanceStatements()
    var
        InvPurchHeader: Record "Purchase Header";
        AdvStPurchHeader: Record "Purchase Header";
        PurchInvoices: TestPage "Purchase Invoices";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 364587] "Purchase Invoice" page does not show Advance Statements

        Initialize();
        // [GIVEN] Invoice "X1" with "Empl. Purch" = No
        MockPurchInvoice(InvPurchHeader, false);
        // [GIVEN] Invoice "X2" with "Empl. Purch" = Yes
        MockPurchInvoice(AdvStPurchHeader, true);
        // [WHEN] Open "Purchase Invoices" page
        PurchInvoices.OpenView();
        // [THEN] "Purchase Invoices" page contains Invoice "X1"
        PurchInvoices.GotoRecord(InvPurchHeader);
        // [THEN] "Purchase Invoices" page does not contain Invoice "X2"
        asserterror PurchInvoices.GotoRecord(AdvStPurchHeader);
        Assert.ExpectedErrorCode(TestRowNoFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OKPOCodeInAdvanceStatementReport()
    var
        PurchaseHeader: Record "Purchase Header";
        NewOKPOCode: Code[10];
    begin
        // [SCENARIO 377331] "OKPO Code" should be taken from Company Information setup to print in Advance Statement Report

        Initialize();
        // [GIVEN] "OKPO Code" is "X" in "Company Information"
        NewOKPOCode := LibraryUtility.GenerateGUID();
        UpdateOKPOCodeInCompanyInfo(NewOKPOCode);

        // [GIVEN] Purchase Order
        LibraryRUReports.CreatePurchDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandIntInRange(2, 5));

        // [WHEN] Run Advance Statement report and export to Excel
        RunAdvanceStatementReport(PurchaseHeader);

        // [THEN] Cell value of "OKPO Code" is "X"
        VerifyOKPOCode(NewOKPOCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OKPOCodeInPostedAdvanceStatementReport()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        NewOKPOCode: Code[10];
    begin
        // [SCENARIO 377331] "OKPO Code" should be taken from Company Information setup to print in Posted Advance Statement Report

        Initialize();
        // [GIVEN] "OKPO Code" is "X" in "Company Information"
        NewOKPOCode := LibraryUtility.GenerateGUID();
        UpdateOKPOCodeInCompanyInfo(NewOKPOCode);

        // [GIVEN] Posted Purchase Order
        DocumentNo :=
          LibraryRUReports.CreatePostPurchDocument(PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandIntInRange(2, 5));

        // [WHEN] Run Advance Statement report and export to Excel
        RunPostedAdvanceStatementReport(DocumentNo);

        // [THEN] Cell value of "OKPO Code" is "X"
        VerifyOKPOCode(NewOKPOCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdvanceStatementReminder()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Report][Reminder]
        // [SCENARIO 377029] Reminder should be empty in Advance Statment report when reminder is zero
        Initialize();

        // [GIVEN] Released advance statement for payment
        CreatePostCashOrderJournal(GenJournalLine);
        CreateAdvanceStatement(PurchaseHeader, GenJournalLine."Posting Date", GenJournalLine."Account No.", GenJournalLine.Amount);

        // [WHEN] Invoke Advandce Statement
        RunAdvanceStatementReport(PurchaseHeader);

        // [THEN] Cell of reminder should be empty
        LibraryReportValidation.VerifyCellValue(25, 18, '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Company Information");

        IsInitialized := true;
        Commit();
    end;

    local procedure CreatePurchInvoiceAndPrintAdvStatement(var PurchaseHeader: Record "Purchase Header"; LinesQuantity: Integer)
    begin
        Initialize();
        LibraryRUReports.CreatePurchDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LinesQuantity);
        RunAdvanceStatementReport(PurchaseHeader);
    end;

    local procedure CreateAndPostPurchInvoiceAndPrintAdvStatement(LinesQuantity: Integer) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();
        DocumentNo := LibraryRUReports.CreatePostPurchDocument(PurchaseHeader."Document Type"::Invoice, LinesQuantity);
        RunPostedAdvanceStatementReport(DocumentNo);
    end;

    local procedure MockPurchInvoice(var PurchHeader: Record "Purchase Header"; EmplPurchase: Boolean): Code[20]
    begin
        PurchHeader.Init();
        PurchHeader."Document Type" := PurchHeader."Document Type"::Invoice;
        PurchHeader."Empl. Purchase" := EmplPurchase;
        PurchHeader.Insert(true);
        exit(PurchHeader."No.");
    end;

    local procedure CreatePostCashOrderJournal(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bal. Account Type"::"Bank Account", LibraryERM.CreateBankAccountNo(), LibraryRandom.RandDec(1000, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAdvanceStatement(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date; VendorNo: Code[20]; Amount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader."Posting Date" := CalcDate('<+1D>', PostingDate);
        PurchaseHeader."Prices Including VAT" := true;
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine."Direct Unit Cost" := Amount;
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure RunAdvanceStatementReport(var PurchaseHeader: Record "Purchase Header")
    var
        AdvanceStatement: Report "Advance Statement";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        PurchaseHeader.SetRecFilter();
        AdvanceStatement.SetTableView(PurchaseHeader);
        AdvanceStatement.SetFileNameSilent(LibraryReportValidation.GetFileName());
        AdvanceStatement.UseRequestPage(false);
        AdvanceStatement.Run();
    end;

    local procedure RunPostedAdvanceStatementReport(DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedAdvanceStatement: Report "Posted Advance Statement";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        PurchInvHeader.SetRange("No.", DocumentNo);
        PostedAdvanceStatement.SetTableView(PurchInvHeader);
        PostedAdvanceStatement.SetFileNameSilent(LibraryReportValidation.GetFileName());
        PostedAdvanceStatement.UseRequestPage(false);
        PostedAdvanceStatement.Run();
    end;

    local procedure UpdateOKPOCodeInCompanyInfo(NewOKPOCode: Code[10])
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo."OKPO Code" := NewOKPOCode;
        CompanyInfo.Modify(true);
    end;

    local procedure VerifyOKPOCode(OKPOCode: Code[10])
    begin
        LibraryReportValidation.VerifyCellValue(7, 47, OKPOCode);
    end;
}

