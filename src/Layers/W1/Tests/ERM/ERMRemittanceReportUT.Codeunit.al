codeunit 133770 "ERM Remittance Report UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance Advice - Journal]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentEqualToInvoiceAmountOnRemittance()
    begin
        // [SCENARIO 54444] Check the Total Amount on the Report Remittance Advice - Journal With Equal Invoice and Payment Amount.
        CheckTotalAmountOnRemittance(LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentGreaterthanInvoiceAmountOnRemittance()
    begin
        // [SCENARIO 54444] Check the Total Amount on the Report Remittance Advice - Journal With more than Invoiced Amount.
        CheckTotalAmountOnRemittance(LibraryRandom.RandDec(10, 2), LibraryRandom.RandDecInRange(20, 30, 2));
    end;

    [Test]
    [HandlerFunctions('RemittanceAdviceJournalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentlessthanInvoiceAmountOnRemittance()
    begin
        // [SCENARIO 54444] Check the Total Amount on the Report Remittance Advice - Journal With less than Invoiced Amount.
        CheckTotalAmountOnRemittance(LibraryRandom.RandDecInRange(20, 30, 2), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CheckTotalAmountOnRemittance(InvoiceAmount: Decimal; PaymentAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        XmlParameters: Text;
    begin
        // Check the Total Amount on Report "Remittance Advice - Journal".

        // Setup: Create and post Gen jnl line and applying Payment.
        DocumentNo := CreateAndPostGenJnlLine(GenJournalLine, InvoiceAmount);
        CreatePaymentGenJnlLine(GenJournalLine, DocumentNo, PaymentAmount);

        // Exercise: Run the Report Remittance Advice - Journal.
        Commit();
        XmlParameters := REPORT.RunRequestPage(REPORT::"Remittance Advice - Journal");
        LibraryReportDataset.RunReportAndLoad(REPORT::"Remittance Advice - Journal", GenJournalLine, XmlParameters);

        // Verify: Verifying Total Amount on Report.
        LibraryReportDataset.AssertElementWithValueExists('Amt_GenJournalLine', GenJournalLine.Amount);
    end;

    local procedure CreateAndPostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; InvoiceAmount: Decimal): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, CreateVendor(), -InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreatePaymentGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; PaymentAmount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, GenJournalLine."Account No.", PaymentAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
    end;

    local procedure SelectGenJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RemittanceAdviceJournalRequestPageHandler(var RemittanceAdviceJournal: TestRequestPage "Remittance Advice - Journal")
    begin
        // Empty handler used to close the request page. We use default settings.
    end;
}

