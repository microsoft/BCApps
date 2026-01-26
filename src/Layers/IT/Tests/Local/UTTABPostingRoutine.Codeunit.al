codeunit 144067 "UT TAB Posting Routine"
{
    // Test for feature - POSTROUT - Posting Routine.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        DialogErr: Label 'Dialog';
        LibraryRandom: Codeunit "Library - Random";
        NCLCSRTSErr: Label 'NCLCSRTS:TableErrorStr';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteSalesCreditMemoHeaderError()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 114 Sales Cr.Memo Header.
        // Setup.
        SalesCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        SalesCrMemoHeader.Insert();

        // Exercise.
        asserterror SalesCrMemoHeader.Delete(true);

        // Verify: Verify expected error code, actual error: You are not allowed to delete posted credit memos.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteSalesInvoiceHeaderError()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 112 Sales Invoice Header.
        // Setup.
        SalesInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        SalesInvoiceHeader.Insert();

        // Exercise.
        asserterror SalesInvoiceHeader.Delete(true);

        // Verify: Verify expected error code, actual error: You are not allowed to delete posted invoices.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePurchaseInvoiceHeaderError()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 122 Purch. Inv. Header.
        // Setup.
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader.Insert();

        // Exercise.
        asserterror PurchInvHeader.Delete(true);

        // Verify: Verify expected error code, actual error: You are not allowed to delete posted invoices.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePurchaseCreditMemoHeaderError()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 124 Purch. Cr. Memo Hdr.
        // Setup.
        PurchCrMemoHdr."No." := LibraryUTUtility.GetNewCode();
        PurchCrMemoHdr.Insert();

        // Exercise.
        asserterror PurchCrMemoHdr.Delete(true);

        // Verify: Verify expected error code, actual error: You are not allowed to delete posted credit memos.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteServiceInvoiceHeaderError()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 5992 Service Invoice Header.
        // Setup.
        ServiceInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceInvoiceHeader.Insert();

        // Exercise.
        asserterror ServiceInvoiceHeader.Delete(true);

        // Verify: Verify expected error code, actual error: You are not allowed to delete posted invoices.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteSalesHeaderError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 36 Sales Header.
        // Setup.
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Posting No." := LibraryUTUtility.GetNewCode();
        SalesHeader.Insert();

        // Exercise.
        asserterror SalesHeader.Delete(true);

        // Verify: Verify expected error code, actual error: A Posting No. has been assigned to this record. You cannot delete this document.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeletePurchaseHeaderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnDelete Trigger of Table ID - 38 Purchase Header.
        // Setup.
        CreatePurchaseHeader(PurchaseHeader);

        // Exercise.
        asserterror PurchaseHeader.Delete(true);

        // Verify: Verify expected error code, actual error: A Posting No. has been assigned to this record. You cannot delete this document.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateOperationOccurredDatePurchaseHeaderError()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate Operation Occurred Date - OnValidate Trigger of Table ID - 38 Purchase Header.
        // Setup.
        CreatePurchaseHeader(PurchaseHeader);

        // Exercise.
        asserterror PurchaseHeader.Validate("Operation Occurred Date", WorkDate());

        // Verify: Verify expected error code, Actual error message: You can not change the Operation Occurred Date field because Posting No. Series Date Order = Yes and the Document has already been assigned Posting No.
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RunCheckOperationOccurredDateGenJnlCheckLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        // Purpose of the test is to validate RunCheck function of CodeUnit ID - 11 Gen. Jnl.-Check Line.
        // Setup.
        UpdateGLSetupLastGenJourPrintingDate();
        CreateGeneralJournalLine(GenJournalLine);

        // Exercise.
        asserterror GenJnlCheckLine.RunCheck(GenJournalLine);

        // Verify: Verify expected error code, actual error: Operation Occurred Date must not be prior to General Ledger Setup - Last Gen. Jour. Printing Date in Gen. Journal Line.
        Assert.ExpectedErrorCode(NCLCSRTSErr);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Name := LibraryUTUtility.GetNewCode10();
        GenJournalTemplate.Insert();
        GenJournalBatch."Journal Template Name" := GenJournalTemplate.Name;
        GenJournalBatch.Name := LibraryUTUtility.GetNewCode10();
        GenJournalBatch.Insert();
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine.Amount := LibraryRandom.RandDec(10, 2);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := LibraryUTUtility.GetNewCode();
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine.Insert();
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10();
        NoSeries."Date Order" := true;
        NoSeries.Insert();
        exit(NoSeries.Code);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Posting No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Posting No. Series" := CreateNoSeries();
        PurchaseHeader.Insert();
    end;

    local procedure UpdateGLSetupLastGenJourPrintingDate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Last Gen. Jour. Printing Date" := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());  // Last Gen. Jour. Printing Date after WORKDATE.
        GeneralLedgerSetup.Modify();
    end;
}

