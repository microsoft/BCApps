codeunit 132571 "Payment Export Mgt Unit Test"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Export] [UT]
    end;

    var
        DataExchColDefType: Record "Data Exch. Column Def";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        LibraryRandom: Codeunit "Library - Random";
        AssertMsg: Label '%1 Field:"%2" different from expected.';
        BankAccIdentifierIsEmptyErr: Label 'You must specify either a Bank Account No. or an IBAN.';
        ExpectedErrorFailedErr: Label 'Assert.ExpectedError failed. Expected: %1. Actual: %2.';
        HasErrorsErr: Label 'The file export has one or more errors.\\For each line to be exported, resolve the errors displayed to the right and then try to export again.';
        IncorrectLengthOfValuesErr: Label 'The payment that you are trying to export is different from the specified %1, %2.\\The value in the %3 field does not have the length that is required by the export format. \Expected: %4 \Actual: %5 \Field Value: %6', Comment = 'N/A';
        PmtDataExportingFlagErr: Label 'Payment data on %1 exporting status is wrong.';
        DataExchLineDefNotFoundErr: Label 'The %1 export format does not support the Payment Method Code %2.', Comment = '%1=data exch. name,%2=payment type';
        RecipientBankAccErr: Label 'Recipient Bank Account is wrong.';
        RollbackChangesErr: Label 'Roll back all the changes.';
        TableErrorMsg: Label '%1 Line:%2', Comment = 'Adding line no to the error message from the caller';
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPaymentFormat: Codeunit "Library - Payment Format";
        AnyText: Text[20];
        AnyDecimal: Decimal;
        AnyDate: Date;
        WrongFieldValueErr: Label '%1 for one or more %2 is different from %3.', Comment = '%1=Field;%2=Table;%3=Value';
        IncorrectNoOfBatchErr: Label 'Incorrect no. of batch validation.';

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure AutoApplyJnlLineExportedLedgerEntryExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, true);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine, GenJnlBatch, VendLedgerEntry);

        // Setup
        ApplyPaymentAutomatically(GenJnlLine, VendLedgerEntry);

        // Post-Setup
        Assert.IsTrue(GenJnlLine."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine.TableCaption()));
        Assert.IsTrue(VendLedgerEntry."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry.TableCaption()));

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure AutoApplyJnlLineExportedLedgerEntryNotExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, false);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine, GenJnlBatch, VendLedgerEntry);

        // Setup
        ApplyPaymentAutomatically(GenJnlLine, VendLedgerEntry);

        // Post-Setup
        Assert.IsFalse(GenJnlLine."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine.TableCaption()));
        SetGenJournalLineExported(GenJnlLine, true);
        Assert.IsFalse(VendLedgerEntry."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry.TableCaption()));

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure AutoApplyJnlLineNotExportedLedgerEntryExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, true);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine, GenJnlBatch, VendLedgerEntry);

        // Setup
        ApplyPaymentAutomatically(GenJnlLine, VendLedgerEntry);

        // Post-Setup
        Assert.IsTrue(GenJnlLine."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine.TableCaption()));
        Assert.IsTrue(VendLedgerEntry."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry.TableCaption()));

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoApplyJnlLineNotExportedLedgerEntryNotExported()
    var
        BankAccount: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateBankAccountWithExportFormat(BankAccount);
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, false);
        CreateGenJournalBatch(GenJnlBatch, BankAccount."No.");
        CreateGenJournalLine(GenJnlLine, GenJnlBatch, VendLedgerEntry);

        // Setup
        ApplyPaymentAutomatically(GenJnlLine, VendLedgerEntry);

        // Post-Setup
        Assert.IsFalse(GenJnlLine."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine.TableCaption()));
        Assert.IsFalse(VendLedgerEntry."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry.TableCaption()));

        // Exercise
        asserterror PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        Assert.ExpectedError(HasErrorsErr);
        CheckCreditTransferRegisterStatus(BankAccount."No.", CreditTransferRegister.Status::Canceled);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure AutoApplyMultiJnlLineExportedLedgerEntryExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Invoice, false);
        CreateVendorLedgerEntry(VendLedgerEntry2, VendLedgerEntry2."Document Type"::Invoice, true);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine1, GenJnlBatch, VendLedgerEntry1);
        CreateGenJournalLine(GenJnlLine2, GenJnlBatch, VendLedgerEntry2);

        // Setup
        ApplyPaymentAutomatically(GenJnlLine1, VendLedgerEntry1);
        ApplyPaymentAutomatically(GenJnlLine2, VendLedgerEntry2);

        // Post-Setup
        Assert.IsFalse(GenJnlLine1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine1.TableCaption()));
        Assert.IsTrue(GenJnlLine2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine2.TableCaption()));
        Assert.IsFalse(VendLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry1.TableCaption()));
        Assert.IsTrue(VendLedgerEntry2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry2.TableCaption()));

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure AutoApplyMultiJnlLineExportedLedgerEntryNotExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Invoice, false);
        CreateVendorLedgerEntry(VendLedgerEntry2, VendLedgerEntry2."Document Type"::Invoice, false);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine1, GenJnlBatch, VendLedgerEntry1);
        CreateGenJournalLine(GenJnlLine2, GenJnlBatch, VendLedgerEntry2);

        // Setup
        ApplyPaymentAutomatically(GenJnlLine1, VendLedgerEntry1);
        ApplyPaymentAutomatically(GenJnlLine2, VendLedgerEntry2);

        // Post-Setup
        Assert.IsFalse(GenJnlLine1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine1.TableCaption()));
        Assert.IsFalse(GenJnlLine2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine2.TableCaption()));
        SetGenJournalLineExported(GenJnlLine2, true);
        Assert.IsFalse(VendLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry1.TableCaption()));
        Assert.IsFalse(VendLedgerEntry2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry2.TableCaption()));

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure AutoApplyMultiJnlLineNotExportedLedgerEntryExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Invoice, false);
        CreateVendorLedgerEntry(VendLedgerEntry2, VendLedgerEntry2."Document Type"::Invoice, true);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine1, GenJnlBatch, VendLedgerEntry1);
        CreateGenJournalLine(GenJnlLine2, GenJnlBatch, VendLedgerEntry2);

        // Setup
        ApplyPaymentAutomatically(GenJnlLine1, VendLedgerEntry1);
        ApplyPaymentAutomatically(GenJnlLine2, VendLedgerEntry2);

        // Post-Setup
        Assert.IsFalse(GenJnlLine1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine1.TableCaption()));
        Assert.IsTrue(GenJnlLine2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine2.TableCaption()));
        Assert.IsFalse(VendLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry1.TableCaption()));
        Assert.IsTrue(VendLedgerEntry2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry2.TableCaption()));

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoApplyMultiJnlLineNotExportedLedgerEntryNotExported()
    var
        BankAccount: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateBankAccountWithExportFormat(BankAccount);
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Invoice, false);
        CreateVendorLedgerEntry(VendLedgerEntry2, VendLedgerEntry2."Document Type"::Invoice, false);
        CreateGenJournalBatch(GenJnlBatch, BankAccount."No.");
        CreateGenJournalLine(GenJnlLine1, GenJnlBatch, VendLedgerEntry1);
        CreateGenJournalLine(GenJnlLine2, GenJnlBatch, VendLedgerEntry2);

        // Setup
        ApplyPaymentAutomatically(GenJnlLine1, VendLedgerEntry1);
        ApplyPaymentAutomatically(GenJnlLine2, VendLedgerEntry2);

        // Post-Setup
        Assert.IsFalse(GenJnlLine1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine1.TableCaption()));
        Assert.IsFalse(GenJnlLine2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine2.TableCaption()));
        Assert.IsFalse(VendLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry1.TableCaption()));
        Assert.IsFalse(VendLedgerEntry2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry2.TableCaption()));

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();

        // Exercise
        asserterror PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        Assert.ExpectedError(HasErrorsErr);
        CheckCreditTransferRegisterStatus(BankAccount."No.", CreditTransferRegister.Status::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustBankAccMissingAccNo()
    var
        CustBankAcc: Record "Customer Bank Account";
    begin
        Initialize();

        // Setup
        CreateCustWithCustBankAcc(CustBankAcc, LibraryUtility.GenerateGUID(), '', '');

        // Exercise
        asserterror CustBankAcc.GetBankAccountNoWithCheck();

        // Verify
        Assert.ExpectedError(BankAccIdentifierIsEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustBankAccMissingIBAN()
    var
        CustBankAcc: Record "Customer Bank Account";
    begin
        Initialize();

        // Setup
        CreateCustWithCustBankAcc(CustBankAcc, '', '', '');

        // Exercise
        asserterror CustBankAcc.GetBankAccountNoWithCheck();

        // Verify
        Assert.ExpectedError(BankAccIdentifierIsEmptyErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CustLedgerEntryExportedHasFilter()
    var
        CustLedgerEntry1: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        PmtExportMgtCustLedgEntry: Codeunit "Pmt Export Mgt Cust Ledg Entry";
    begin
        Initialize();

        // Setup
        CreateCustLedgerEntry(CustLedgerEntry1, CustLedgerEntry1."Document Type"::Refund, true);

        // Post-Setup
        Assert.IsTrue(CustLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, CustLedgerEntry1.TableCaption()));

        // Pre-Exercise
        CustLedgerEntry2.SetRange("Entry No.", CustLedgerEntry1."Entry No.");
        CustLedgerEntry2.FindLast();

        // Exercise
        PmtExportMgtCustLedgEntry.ExportCustPaymentFileYN(CustLedgerEntry2);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgerEntryNotExportedHasFilter()
    var
        CustLedgerEntry1: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        PmtExportMgtCustLedgEntry: Codeunit "Pmt Export Mgt Cust Ledg Entry";
    begin
        Initialize();

        // Setup
        CreateCustLedgerEntry(CustLedgerEntry1, CustLedgerEntry1."Document Type"::Refund, false);

        // Post-Setup
        Assert.IsFalse(CustLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, CustLedgerEntry1.TableCaption()));

        // Pre-Exercise
        CustLedgerEntry2.SetRange("Entry No.", CustLedgerEntry1."Entry No.");
        CustLedgerEntry2.FindLast();

        // Exercise
        asserterror PmtExportMgtCustLedgEntry.ExportCustPaymentFileYN(CustLedgerEntry2);

        // Verify
        Assert.ExpectedErrorCannotFind(Database::"Bank Account");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CustLedgerEntryPmtAppliedToExportedInv()
    var
        CustLedgerEntry1: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        PmtExportMgtCustLedgEntry: Codeunit "Pmt Export Mgt Cust Ledg Entry";
    begin
        Initialize();

        // Pre-Setup
        CreateCustLedgerEntry(CustLedgerEntry1, CustLedgerEntry1."Document Type"::Invoice, true);
        CreateCustLedgerEntry(CustLedgerEntry2, CustLedgerEntry2."Document Type"::Refund, false);

        // Setup
        CustLedgerEntry1."Closed by Entry No." := CustLedgerEntry2."Entry No.";
        CustLedgerEntry1.Modify();

        // Exercise
        PmtExportMgtCustLedgEntry.ExportCustPaymentFileYN(CustLedgerEntry2);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgerEntryPmtAppliedToNotExportedInv()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry1: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        PmtExportMgtCustLedgEntry: Codeunit "Pmt Export Mgt Cust Ledg Entry";
    begin
        Initialize();

        // Pre-Setup
        CreateCustLedgerEntry(CustLedgerEntry1, CustLedgerEntry1."Document Type"::Invoice, false);
        CreateCustLedgerEntry(CustLedgerEntry2, CustLedgerEntry2."Document Type"::Refund, false);

        // Setup
        CustLedgerEntry1."Closed by Entry No." := CustLedgerEntry2."Entry No.";
        CustLedgerEntry1.Modify();

        // Pre-Exercise
        CustLedgerEntry.SetRange("Entry No.", CustLedgerEntry1."Entry No.", CustLedgerEntry2."Entry No.");
        CustLedgerEntry.FindFirst();

        // Exercise
        asserterror PmtExportMgtCustLedgEntry.ExportCustPaymentFileYN(CustLedgerEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(WrongFieldValueErr, CustLedgerEntry.FieldCaption("Document Type"),
            CustLedgerEntry.TableCaption(), CustLedgerEntry."Document Type"::Refund));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterByHasPaymentExportError()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlLine3: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
        BankAccountNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        DeleteExtraPaymentJnlTemplates();
        BankAccountNo := CreateSimpleBankAccount();
        CreateGenJournalBatch(GenJnlBatch, BankAccountNo);

        // Setup
        LibraryERM.CreateGeneralJnlLine(GenJnlLine1, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine1."Document Type"::Payment, GenJnlLine1."Account Type"::Vendor, '', LibraryRandom.RandDec(1000, 2));
        GenJnlLine1.Description := Format(1);
        GenJnlLine1.Modify();
        LibraryERM.CreateGeneralJnlLine(GenJnlLine2, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine2."Document Type"::Payment, GenJnlLine2."Account Type"::Vendor, '', LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateGeneralJnlLine(GenJnlLine3, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine3."Document Type"::Payment, GenJnlLine3."Account Type"::Vendor, '', LibraryRandom.RandDec(1000, 2));
        GenJnlLine3.Description := Format(3);
        GenJnlLine3.Modify();

        CreateErrorsForGenJnlLine(GenJnlLine1);
        CreateErrorsForGenJnlLine(GenJnlLine3);

        // Exercise
        Commit();
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJnlBatch.Name);
        PaymentJournal.FILTER.SetFilter("Has Payment Export Error", Format(true));

        // Verify
        Assert.IsFalse(PaymentJournal."Has Payment Export Error".Editable(), GenJnlLine.FieldCaption("Has Payment Export Error"));
        PaymentJournal.First();
        Assert.AreEqual('1', PaymentJournal.Description.Value, GenJnlLine1.FieldName(Description));
        PaymentJournal.Next();
        Assert.AreEqual('3', PaymentJournal.Description.Value, GenJnlLine3.FieldName(Description));
        PaymentJournal.Next();
        Assert.AreEqual('', PaymentJournal.Description.Value, GenJnlLine.FieldName(Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterByExportedToPaymentFile()
    var
        BankAccount: Record "Bank Account";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        DataExchMapping: Record "Data Exch. Mapping";
        Vendor: Record Vendor;
    begin
        Initialize();

        // Pre-Setup
        DefinePaymentExportFormat(DataExchMapping);
        CreateAnyBankAccount(BankAccount);

        // Setup
        LibraryPaymentExport.CreateVendorWithBankAccount(Vendor);
        UpdatePaymentMethodLineDef(Vendor."Payment Method Code", DataExchMapping."Data Exch. Line Def Code");

        CreateGenJournalBatch(GenJnlBatch, BankAccount."No.");
        LibraryERM.CreateGeneralJnlLine(GenJnlLine1,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine1."Document Type"::Payment,
          GenJnlLine1."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateGeneralJnlLine(GenJnlLine2,
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine2."Document Type"::Payment,
          GenJnlLine2."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(1000, 2));

        // Post-Setup
        SetGenJournalLineExported(GenJnlLine1, true);
        SetGenJournalLineExported(GenJnlLine2, false);

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Exported to Payment File", false);

        // Exercise
        asserterror GenJnlLine.ExportPaymentFile();

        // Verify
        Assert.ExpectedTestFieldError(BankAccount.FieldCaption("Payment Export Format"), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ManualApplyJnlLineExportedLedgerEntryExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, true);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine, GenJnlBatch, VendLedgerEntry);

        // Setup
        ApplyPaymentManually(GenJnlLine, VendLedgerEntry, GenJnlLine."Document No.");

        // Post-Setup
        Assert.IsTrue(GenJnlLine."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine.TableCaption()));
        Assert.IsTrue(VendLedgerEntry."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry.TableCaption()));

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ManualApplyJnlLineExportedLedgerEntryNotExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, false);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine, GenJnlBatch, VendLedgerEntry);

        // Setup
        ApplyPaymentManually(GenJnlLine, VendLedgerEntry, GenJnlLine."Document No.");

        // Post-Setup
        Assert.IsFalse(GenJnlLine."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine.TableCaption()));
        SetGenJournalLineExported(GenJnlLine, true);
        Assert.IsFalse(VendLedgerEntry."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry.TableCaption()));

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ManualApplyJnlLineNotExportedLedgerEntryExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, true);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine, GenJnlBatch, VendLedgerEntry);

        // Setup
        ApplyPaymentManually(GenJnlLine, VendLedgerEntry, GenJnlLine."Document No.");

        // Post-Setup
        Assert.IsTrue(GenJnlLine."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine.TableCaption()));
        Assert.IsTrue(VendLedgerEntry."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry.TableCaption()));

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualApplyJnlLineNotExportedLedgerEntryNotExported()
    var
        BankAccount: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateBankAccountWithExportFormat(BankAccount);
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, false);
        CreateGenJournalBatch(GenJnlBatch, BankAccount."No.");
        CreateGenJournalLine(GenJnlLine, GenJnlBatch, VendLedgerEntry);

        // Setup
        ApplyPaymentManually(GenJnlLine, VendLedgerEntry, GenJnlLine."Document No.");

        // Post-Setup
        Assert.IsFalse(GenJnlLine."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine.TableCaption()));
        Assert.IsFalse(VendLedgerEntry."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry.TableCaption()));

        // Exercise
        asserterror PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        Assert.ExpectedError(HasErrorsErr);
        CheckCreditTransferRegisterStatus(BankAccount."No.", CreditTransferRegister.Status::Canceled);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ManualApplyMultiJnlLineExportedLedgerEntryExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Invoice, false);
        CreateVendorLedgerEntry(VendLedgerEntry2, VendLedgerEntry2."Document Type"::Invoice, true);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine1, GenJnlBatch, VendLedgerEntry1);
        CreateGenJournalLine(GenJnlLine2, GenJnlBatch, VendLedgerEntry2);

        // Setup
        ApplyPaymentManually(GenJnlLine1, VendLedgerEntry1, GenJnlLine1."Document No.");
        ApplyPaymentManually(GenJnlLine2, VendLedgerEntry2, GenJnlLine1."Document No."); // use the same Applies-to ID for both

        // Post-Setup
        Assert.IsFalse(GenJnlLine1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine1.TableCaption()));
        Assert.IsTrue(GenJnlLine2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine2.TableCaption()));
        Assert.IsFalse(VendLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry1.TableCaption()));
        Assert.IsTrue(VendLedgerEntry2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry2.TableCaption()));

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ManualApplyMultiJnlLineExportedLedgerEntryNotExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Invoice, false);
        CreateVendorLedgerEntry(VendLedgerEntry2, VendLedgerEntry2."Document Type"::Invoice, false);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine1, GenJnlBatch, VendLedgerEntry1);
        CreateGenJournalLine(GenJnlLine2, GenJnlBatch, VendLedgerEntry2);

        // Setup
        ApplyPaymentManually(GenJnlLine1, VendLedgerEntry1, GenJnlLine1."Document No.");
        ApplyPaymentManually(GenJnlLine2, VendLedgerEntry2, GenJnlLine1."Document No."); // use the same Applies-to ID for both

        // Post-Setup
        Assert.IsFalse(GenJnlLine1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine1.TableCaption()));
        Assert.IsFalse(GenJnlLine2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine2.TableCaption()));
        SetGenJournalLineExported(GenJnlLine2, true);
        Assert.IsFalse(VendLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry1.TableCaption()));
        Assert.IsFalse(VendLedgerEntry2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry2.TableCaption()));

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ManualApplyMultiJnlLineNotExportedLedgerEntryExported()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Invoice, false);
        CreateVendorLedgerEntry(VendLedgerEntry2, VendLedgerEntry2."Document Type"::Invoice, true);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        CreateGenJournalLine(GenJnlLine1, GenJnlBatch, VendLedgerEntry1);
        CreateGenJournalLine(GenJnlLine2, GenJnlBatch, VendLedgerEntry2);

        // Setup
        ApplyPaymentManually(GenJnlLine1, VendLedgerEntry1, GenJnlLine1."Document No.");
        ApplyPaymentManually(GenJnlLine2, VendLedgerEntry2, GenJnlLine1."Document No."); // use the same Applies-to ID for both

        // Post-Setup
        Assert.IsFalse(GenJnlLine1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine1.TableCaption()));
        Assert.IsTrue(GenJnlLine2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine2.TableCaption()));
        Assert.IsFalse(VendLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry1.TableCaption()));
        Assert.IsTrue(VendLedgerEntry2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry2.TableCaption()));

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualApplyMultiJnlLineNotExportedLedgerEntryNotExported()
    var
        BankAccount: Record "Bank Account";
        CreditTransferRegister: Record "Credit Transfer Register";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateBankAccountWithExportFormat(BankAccount);
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Invoice, false);
        CreateVendorLedgerEntry(VendLedgerEntry2, VendLedgerEntry2."Document Type"::Invoice, false);
        CreateGenJournalBatch(GenJnlBatch, BankAccount."No.");
        CreateGenJournalLine(GenJnlLine1, GenJnlBatch, VendLedgerEntry1);
        CreateGenJournalLine(GenJnlLine2, GenJnlBatch, VendLedgerEntry2);

        // Setup
        ApplyPaymentManually(GenJnlLine1, VendLedgerEntry1, GenJnlLine1."Document No.");
        ApplyPaymentManually(GenJnlLine2, VendLedgerEntry2, GenJnlLine1."Document No."); // use the same Applies-to ID for both

        // Post-Setup
        Assert.IsFalse(GenJnlLine1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine1.TableCaption()));
        Assert.IsFalse(GenJnlLine2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, GenJnlLine2.TableCaption()));
        Assert.IsFalse(VendLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry1.TableCaption()));
        Assert.IsFalse(VendLedgerEntry2."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry2.TableCaption()));

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();

        // Exercise
        asserterror PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJnlLine);

        // Verify
        Assert.ExpectedError(HasErrorsErr);
        CheckCreditTransferRegisterStatus(BankAccount."No.", CreditTransferRegister.Status::Canceled);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccBlankedByAccNo()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine."Recipient Bank Account" := LibraryUtility.GenerateGUID();

        // Exercise
        GenJnlLine.Validate("Account No.", '');

        // Verify
        Assert.AreEqual('', GenJnlLine."Recipient Bank Account", RecipientBankAccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccBlankedByBalAccNo()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Recipient Bank Account" := LibraryUtility.GenerateGUID();

        // Exercise
        GenJnlLine.Validate("Bal. Account No.", '');

        // Verify
        Assert.AreEqual('', GenJnlLine."Recipient Bank Account", RecipientBankAccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccNotBlankedByAccNo()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccountCode: Code[20];
    begin
        Initialize();

        // Setup
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::Customer;
        GenJnlLine."Recipient Bank Account" := LibraryUtility.GenerateGUID();
        BankAccountCode := GenJnlLine."Recipient Bank Account";
        // Exercise
        GenJnlLine.Validate("Account No.", '');

        // Verify
        Assert.AreEqual(BankAccountCode, GenJnlLine."Recipient Bank Account", RecipientBankAccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccNotBlankedByBalAccNo()
    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccountCode: Code[20];
    begin
        Initialize();

        // Setup
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Recipient Bank Account" := LibraryUtility.GenerateGUID();
        BankAccountCode := GenJnlLine."Recipient Bank Account";

        // Exercise
        GenJnlLine.Validate("Bal. Account No.", '');

        // Verify
        Assert.AreEqual(BankAccountCode, GenJnlLine."Recipient Bank Account", RecipientBankAccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccSetByAccNoCust()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustomerBankAcc: Record "Customer Bank Account";
    begin
        Initialize();

        // Setup
        CreateCustWithCustBankAcc(CustomerBankAcc, LibraryUtility.GenerateGUID(), '', '');
        Customer.Get(CustomerBankAcc."Customer No.");
        Customer."Preferred Bank Account Code" := CustomerBankAcc.Code;
        Customer.Modify(true);

        // Exercise
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine.Validate("Account No.", Customer."No.");

        // Verify
        Assert.AreEqual(CustomerBankAcc.Code, GenJnlLine."Recipient Bank Account", RecipientBankAccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccSetByAccNoVend()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        Initialize();

        // Setup
        CreateVendorWithVendorBankAcc(VendorBankAcc, LibraryUtility.GenerateGUID(), '', '');
        Vendor.Get(VendorBankAcc."Vendor No.");
        Vendor."Preferred Bank Account Code" := VendorBankAcc.Code;
        Vendor.Modify(true);

        // Exercise
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine.Validate("Account No.", Vendor."No.");

        // Verify
        Assert.AreEqual(VendorBankAcc.Code, GenJnlLine."Recipient Bank Account", RecipientBankAccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccSetByBalAccNoCust()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CustomerBankAcc: Record "Customer Bank Account";
    begin
        Initialize();

        // Setup
        CreateCustWithCustBankAcc(CustomerBankAcc, LibraryUtility.GenerateGUID(), '', '');
        Customer.Get(CustomerBankAcc."Customer No.");
        Customer."Preferred Bank Account Code" := CustomerBankAcc.Code;
        Customer.Modify(true);

        // Exercise
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Bal. Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine.Validate("Bal. Account No.", Customer."No.");

        // Verify
        Assert.AreEqual(CustomerBankAcc.Code, GenJnlLine."Recipient Bank Account", RecipientBankAccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccSetByBalAccNoVend()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        Initialize();

        // Setup
        CreateVendorWithVendorBankAcc(VendorBankAcc, LibraryUtility.GenerateGUID(), '', '');
        Vendor.Get(VendorBankAcc."Vendor No.");
        Vendor."Preferred Bank Account Code" := VendorBankAcc.Code;
        Vendor.Modify(true);

        // Exercise
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Bal. Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine.Validate("Bal. Account No.", Vendor."No.");

        // Verify
        Assert.AreEqual(VendorBankAcc.Code, GenJnlLine."Recipient Bank Account", RecipientBankAccErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SenderBankAccMissingAccNo()
    var
        BankAcc: Record "Bank Account";
    begin
        Initialize();

        // Setup
        CreateBankAccount(BankAcc, LibraryUtility.GenerateGUID(), '');

        // Exercise
        asserterror BankAcc.GetBankAccountNoWithCheck();

        // Verify
        Assert.ExpectedError(BankAccIdentifierIsEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SenderBankAccMissingIBAN()
    var
        BankAcc: Record "Bank Account";
    begin
        Initialize();

        // Setup
        CreateBankAccount(BankAcc, '', '');

        // Exercise
        asserterror BankAcc.GetBankAccountNoWithCheck();

        // Verify
        Assert.ExpectedError(BankAccIdentifierIsEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBankAccMissingAccNo()
    var
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        Initialize();

        // Setup
        CreateVendorWithVendorBankAcc(VendorBankAcc, LibraryUtility.GenerateGUID(), '', '');

        // Exercise
        asserterror VendorBankAcc.GetBankAccountNoWithCheck();

        // Verify
        Assert.ExpectedError(BankAccIdentifierIsEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBankAccMissingIBAN()
    var
        VendorBankAcc: Record "Vendor Bank Account";
    begin
        Initialize();

        // Setup
        CreateVendorWithVendorBankAcc(VendorBankAcc, '', '', '');

        // Exercise
        asserterror VendorBankAcc.GetBankAccountNoWithCheck();

        // Verify
        Assert.ExpectedError(BankAccIdentifierIsEmptyErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryExportedHasFilter()
    var
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
    begin
        Initialize();

        // Setup
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Payment, true);

        // Post-Setup
        Assert.IsTrue(VendLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry1.TableCaption()));

        // Pre-Exercise
        VendLedgerEntry2.SetRange("Entry No.", VendLedgerEntry1."Entry No.");
        VendLedgerEntry2.FindLast();

        // Exercise
        PmtExportMgtVendLedgEntry.ExportVendorPaymentFileYN(VendLedgerEntry2);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryNotExportedHasFilter()
    var
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
    begin
        Initialize();

        // Setup
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Payment, false);

        // Post-Setup
        Assert.IsFalse(VendLedgerEntry1."Exported to Payment File", StrSubstNo(PmtDataExportingFlagErr, VendLedgerEntry1.TableCaption()));

        // Pre-Exercise
        VendLedgerEntry2.SetRange("Entry No.", VendLedgerEntry1."Entry No.");
        VendLedgerEntry2.FindLast();

        // Exercise
        asserterror PmtExportMgtVendLedgEntry.ExportVendorPaymentFileYN(VendLedgerEntry2);

        // Verify
        Assert.ExpectedErrorCannotFind(Database::"Bank Account");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryPmtAppliedToExportedInv()
    var
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Invoice, true);
        CreateVendorLedgerEntry(VendLedgerEntry2, VendLedgerEntry2."Document Type"::Payment, false);

        // Setup
        VendLedgerEntry1."Closed by Entry No." := VendLedgerEntry2."Entry No.";
        VendLedgerEntry1.Modify();

        // Exercise
        PmtExportMgtVendLedgEntry.ExportVendorPaymentFileYN(VendLedgerEntry2);

        // Verify
        // Prompt: Export again?

        // Cleanup
        asserterror Error(RollbackChangesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryPmtAppliedToNotExportedInv()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry1: Record "Vendor Ledger Entry";
        VendLedgerEntry2: Record "Vendor Ledger Entry";
        PmtExportMgtVendLedgEntry: Codeunit "Pmt Export Mgt Vend Ledg Entry";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry1, VendLedgerEntry1."Document Type"::Invoice, false);
        CreateVendorLedgerEntry(VendLedgerEntry2, VendLedgerEntry2."Document Type"::Payment, false);

        // Setup
        VendLedgerEntry1."Closed by Entry No." := VendLedgerEntry2."Entry No.";
        VendLedgerEntry1.Modify();

        // Pre-Exercise
        VendLedgerEntry.SetRange("Entry No.", VendLedgerEntry1."Entry No.", VendLedgerEntry2."Entry No.");
        VendLedgerEntry.FindFirst();

        // Exercise
        asserterror PmtExportMgtVendLedgEntry.ExportVendorPaymentFileYN(VendLedgerEntry);

        // Verify
        Assert.ExpectedError(
          StrSubstNo(WrongFieldValueErr, VendLedgerEntry.FieldCaption("Document Type"),
            VendLedgerEntry.TableCaption(), VendLedgerEntry."Document Type"::Payment));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryExportedTwice()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        PmtExportMgtGenJnlLine: Codeunit "Pmt Export Mgt Gen. Jnl Line";
    begin
        Initialize();

        // Pre-Setup
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Payment, true);

        LibraryERM.CreateBankAccount(BankAccount);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());
        GenJnlBatch."Bal. Account No." := BankAccount."No.";
        GenJnlBatch.Modify();

        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJnlBatch."Journal Template Name",
          GenJnlBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, VendLedgerEntry."Vendor No.",
          LibraryRandom.RandDec(1000, 2));

        // Setup
        VendLedgerEntry."Bal. Account No." := BankAccount."No.";
        VendLedgerEntry."Applies-to Doc. Type" := GenJournalLine."Document Type";
        VendLedgerEntry."Applies-to Doc. No." := GenJournalLine."Document No.";
        VendLedgerEntry.Modify();
        Commit();

        // Exercise
        PmtExportMgtGenJnlLine.ExportJournalPaymentFileYN(GenJournalLine);

        // Verify
        // No error occurs!
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportNoCustomFormatting()
    begin
        VerifyFieldMapping(123.01, Format(123.01),
          80, DataExchColDefType."Data Type"::Decimal, '', 0, 1, '', 1);

        VerifyFieldMapping(DMY2Date(5, 12, 2012), Format(DMY2Date(5, 12, 2012)),
          82, DataExchColDefType."Data Type"::Date, '', 0, 0, '', 1);

        VerifyFieldMapping('Short Advice', 'Short Advice',
          64, DataExchColDefType."Data Type"::Text, '', 0, 0, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportUseMultiplier()
    begin
        VerifyFieldMapping(123.01, Format(1230.1),
          80, DataExchColDefType."Data Type"::Decimal, '', 0, 10, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportUseDateAndDecimalFormatting()
    begin
        VerifyFieldMapping(123.01, '123,01',
          80, DataExchColDefType."Data Type"::Decimal, '<Integer><Decimals><Comma,,><Sign>', 0, 1, '', 1);

        VerifyFieldMapping(-123.01, '123,01-',
          80, DataExchColDefType."Data Type"::Decimal, '<Integer><Decimals><Comma,,><Sign>', 0, 1, '', 1);

        VerifyFieldMapping(DMY2Date(5, 12, 2012), '051212',
          82, DataExchColDefType."Data Type"::Date, '<Day,2><Month,2><Year,2>', 0, 0, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateTimeStandardFormattingXml()
    var
        CurrDateTime: DateTime;
    begin
        CurrDateTime := CurrentDateTime();
        VerifyFieldMapping(CurrDateTime, Format(CurrDateTime, 0, 9), 132571, DataExchColDefType."Data Type"::DateTime, '', 0, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateTimeCustomFormattingXml()
    var
        CurrDateTime: DateTime;
    begin
        CurrDateTime := CurrentDateTime();
        VerifyFieldMapping(CurrDateTime, Format(CurrDateTime, 0, '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>'), 132571, DataExchColDefType."Data Type"::DateTime,
          '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>', 0, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateStandardFormattingXml()
    begin
        VerifyFieldMapping(DMY2Date(27, 1, 2016), '2016-01-27', 82, DataExchColDefType."Data Type"::Date, '', 0, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateCustomFormattingXml()
    begin
        VerifyFieldMapping(DMY2Date(27, 1, 2016), '270116', 82, DataExchColDefType."Data Type"::Date, '<Day,2><Month,2><Year,2>', 0, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDecimalStandardFormattingXml()
    begin
        VerifyFieldMapping(123.01, '123.01', 80, DataExchColDefType."Data Type"::Decimal, '', 0, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDecimalTimeCustomFormattingXml()
    begin
        VerifyFieldMapping(123.01, '123,01', 80, DataExchColDefType."Data Type"::Decimal,
          '<Integer><Decimals><Comma,,><Sign>', 0, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateTimeStandardFormattingVariableText()
    var
        CurrDateTime: DateTime;
    begin
        CurrDateTime := CurrentDateTime();
        VerifyFieldMapping(CurrDateTime, Format(CurrDateTime), 132571, DataExchColDefType."Data Type"::DateTime, '', 0, 1, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateTimeCustomFormattingVariableText()
    var
        CurrDateTime: DateTime;
    begin
        CurrDateTime := CurrentDateTime();
        VerifyFieldMapping(CurrDateTime, Format(CurrDateTime, 0, '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>'), 132571, DataExchColDefType."Data Type"::DateTime,
          '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>', 0, 1, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateTimeStandardFormattingFixedWidth()
    var
        CurrDateTime: DateTime;
        ExpDateTime: Text;
    begin
        CurrDateTime := CurrentDateTime();
        ExpDateTime := Format(CurrDateTime);
        VerifyFieldMapping(CurrDateTime, ExpDateTime, 132571, DataExchColDefType."Data Type"::DateTime, '', StrLen(ExpDateTime), 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateTimeCustomFormattingFixedWidth()
    var
        CurrDateTime: DateTime;
    begin
        CurrDateTime := CurrentDateTime();
        VerifyFieldMapping(CurrDateTime, Format(CurrDateTime, 0, '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>'), 132571, DataExchColDefType."Data Type"::DateTime,
          '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>', 10, 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateAsDateTimeStandardFormattingXml()
    begin
        VerifyFieldMapping(DMY2Date(27, 1, 2016), Format(CreateDateTime(DMY2Date(27, 1, 2016), 0T), 0, 9), 82, DataExchColDefType."Data Type"::DateTime, '', 0, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateAsDateTimeCustomFormattingXml()
    begin
        VerifyFieldMapping(DMY2Date(27, 1, 2016), Format(CreateDateTime(DMY2Date(27, 1, 2016), 0T), 0, '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>'), 82, DataExchColDefType."Data Type"::DateTime,
          '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>', 0, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateAsDateTimeStandardFormattingVariableText()
    begin
        VerifyFieldMapping(DMY2Date(27, 1, 2016), Format(CreateDateTime(DMY2Date(27, 1, 2016), 0T)),
          82, DataExchColDefType."Data Type"::DateTime, '', 0, 1, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateAsDateTimeCustomFormattingVariableText()
    begin
        VerifyFieldMapping(DMY2Date(27, 1, 2016), Format(CreateDateTime(DMY2Date(27, 1, 2016), 0T), 0, '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>'), 82, DataExchColDefType."Data Type"::DateTime,
          '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>', 0, 1, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateAsDateTimeStandardFormattingFixedWidth()
    var
        ExpDateTime: Text;
    begin
        ExpDateTime := Format(CreateDateTime(DMY2Date(27, 1, 2016), 0T));
        VerifyFieldMapping(DMY2Date(27, 1, 2016), ExpDateTime,
          82, DataExchColDefType."Data Type"::DateTime, '', StrLen(ExpDateTime), 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateAsDateTimeCustomFormattingFixedWidth()
    begin
        VerifyFieldMapping(DMY2Date(27, 1, 2016), Format(CreateDateTime(DMY2Date(27, 1, 2016), 0T), 0, '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>'), 82, DataExchColDefType."Data Type"::DateTime,
          '<Day,2><Month,2><Year,2><Hours24,2><Minutes,2>', 10, 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportTimeStandardFormattingXml()
    var
        CurrTime: Time;
    begin
        CurrTime := Time();
        VerifyFieldMapping(CurrTime, Format(CreateDateTime(Today(), CurrTime), 0, 9), 132572, DataExchColDefType."Data Type"::DateTime, '', 0, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportTimeCustomFormattingXml()
    var
        CurrTime: Time;
    begin
        CurrTime := Time();
        VerifyFieldMapping(CurrTime, Format(CreateDateTime(Today(), CurrTime), 0, '<Hours24,2><Minutes,2>'), 132572, DataExchColDefType."Data Type"::DateTime,
          '<Hours24,2><Minutes,2>', 0, 1, '', 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportTimeStandardFormattingVariableText()
    var
        CurrTime: Time;
    begin
        CurrTime := Time();
        VerifyFieldMapping(CurrTime, Format(CreateDateTime(Today(), CurrTime)), 132572, DataExchColDefType."Data Type"::DateTime, '', 0, 1, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportTimeCustomFormattingVariableText()
    var
        CurrTime: Time;
    begin
        CurrTime := Time();
        VerifyFieldMapping(CurrTime, Format(CreateDateTime(Today(), CurrTime), 0, '<Hours24,2><Minutes,2>'), 132572, DataExchColDefType."Data Type"::DateTime,
          '<Hours24,2><Minutes,2>', 0, 1, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportTimeStandardFormattingFixedWidth()
    var
        CurrTime: Time;
        ExpDateTime: Text;
    begin
        CurrTime := Time();
        ExpDateTime := Format(CreateDateTime(Today(), CurrTime));
        VerifyFieldMapping(CurrTime, ExpDateTime, 132572, DataExchColDefType."Data Type"::DateTime, '', StrLen(ExpDateTime), 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportTimeCustomFormattingFixedWidth()
    var
        CurrTime: Time;
    begin
        CurrTime := Time();
        VerifyFieldMapping(CurrTime, Format(CreateDateTime(Today(), CurrTime), 0, '<Hours24,2><Minutes,2>'), 132572, DataExchColDefType."Data Type"::DateTime,
          '<Hours24,2><Minutes,2>', 4, 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportUseDefaultValue()
    begin
        VerifyFieldMapping(123.01, '100.00',
          80, DataExchColDefType."Data Type"::Decimal, '', 0, 1, '100.00', 1);

        VerifyFieldMapping(DMY2Date(5, 12, 2012), '010112',
          82, DataExchColDefType."Data Type"::Date, '', 0, 0, '010112', 1);

        VerifyFieldMapping('Short Advice', 'Default Value',
          64, DataExchColDefType."Data Type"::Text, '', 0, 0, 'Default Value', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportWithPrefix()
    begin
        VerifyFieldMapping(123.01, '$' + Format(123.01),
          80, DataExchColDefType."Data Type"::Decimal, '$<Standard Format,0>', 0, 1, '', 1);

        VerifyFieldMapping(DMY2Date(5, 12, 2012), 'D' + Format(DMY2Date(5, 12, 2012)),
          82, DataExchColDefType."Data Type"::Date, 'D<Standard Format,0>', 0, 0, '', 1);

        VerifyFieldMapping('Short Advice', 'PrefixShort Advice',
          64, DataExchColDefType."Data Type"::Text, 'Prefix<Standard Format,0>', 0, 0, '', 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthDecimalPrefixPlus()
    begin
        VerifyFieldMapping(123.01, '$000' + Format(123.01), 80,
          DataExchColDefType."Data Type"::Decimal, '$<Sign,1><Filler Character,0><Integer,5><Filler Character,0><Decimals>', 10, 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthDecimalPrefixMinus()
    begin
        VerifyFieldMapping(-123.01, '$-00' + Format(123.01), 80,
          DataExchColDefType."Data Type"::Decimal, '$<Sign,1><Filler Character,0><Integer,5><Filler Character,0><Decimals>', 10, 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthDecimalPlusAtTheEnd()
    begin
        VerifyFieldMapping(123.01, '000' + Format(123.01) + '+', 80, DataExchColDefType."Data Type"::Decimal,
          '<Integer,6><Filler Character,0><Decimals,3><Filler Character,0><Sign,1><Filler Character,+>', 10, 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthDecimalMinusAtTheEnd()
    begin
        VerifyFieldMapping(-123.01, '000' + Format(123.01) + '-', 80, DataExchColDefType."Data Type"::Decimal,
          '<Integer,6><Filler Character,0><Decimals,3><Filler Character,0><Sign,1><Filler Character,+>', 10, 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthDecimalFromTextFieldWithPrefix()
    begin
        VerifyFieldMapping(456789, 'Account0000456789',
          64, DataExchColDefType."Data Type"::Decimal, 'Account<Integer,10><Filler Character,0>', 17, 1, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthDefaultValue()
    begin
        VerifyFieldMapping(123.01, '100.00', 80, DataExchColDefType."Data Type"::Decimal, '', 6, 100, '100.00', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthToLong()
    begin
        VerifyFieldMappingError(123.01, '100.00', 80, DataExchColDefType."Data Type"::Decimal, '', 7, 100, '100.00');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthToShort()
    begin
        VerifyFieldMappingError(123.01, '100.00', 80, DataExchColDefType."Data Type"::Decimal, '', 5, 100, '100.00');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthText()
    begin
        VerifyFieldMapping('AnyText', 'AnyTex', 64, DataExchColDefType."Data Type"::Text, '<Text,6>', 6, 0, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthTextSpacePadding()
    begin
        VerifyFieldMapping('AnyText', 'AnyText   ', 64, DataExchColDefType."Data Type"::Text, '', 10, 0, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedWidthTextTruncate()
    begin
        VerifyFieldMapping('AnyText', 'AnyT', 64, DataExchColDefType."Data Type"::Text, '<Text,4>', 4, 0, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportTextToDate()
    begin
        VerifyFieldMapping('101010', '10-10-10', 64, DataExchColDefType."Data Type"::Date, '<Day,2>-<Month,2>-<Year,2>', 8, 0, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDecimalToText()
    begin
        VerifyFieldMapping(123, '123  ', 80, DataExchColDefType."Data Type"::Text, '<Text,5>', 5, 0, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDateToText()
    begin
        VerifyFieldMapping(DMY2Date(5, 12, 2012), Format(DMY2Date(5, 12, 2012)) + '  ', 82, DataExchColDefType."Data Type"::Text, '', 10, 0, '', 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingValueOnNonOptionalDecimal()
    begin
        VerifyFieldMappingError(0, '', 80, DataExchColDefType."Data Type"::Decimal, '', 0, 1, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingValueOnNonOptionalDate()
    begin
        VerifyFieldMappingError(0D, Format(0D), 82, DataExchColDefType."Data Type"::Date, '', 1, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingValueOnNonOptionalText()
    begin
        VerifyFieldMappingError('', '', 64, DataExchColDefType."Data Type"::Text, '', 0, 0, '');
    end;

    local procedure MissingDataExchLineDef(FileType: Option)
    var
        BankAcc: Record "Bank Account";
        TempPmtExportData: Record "Payment Export Data" temporary;
        DataExchDef: Record "Data Exch. Def";
        DataExch: Record "Data Exch.";
        PaymentExportMgt: Codeunit "Payment Export Mgt";
    begin
        Initialize();

        // Setup.
        CreateDataExchDef(DataExchDef, FileType);
        CreateDataExch(DataExch, DataExchDef.Code);
        CreateAnyBankAccount(BankAcc);
        CreatePaymentExportDataSingleValue(TempPmtExportData, BankAcc."No.", DataExch."Entry No.", '',
          TempPmtExportData.FieldNo("Sender Bank Account Code"), BankAcc."No.");

        // Exercise
        asserterror PaymentExportMgt.CreatePaymentLines(TempPmtExportData);

        // Verify
        Assert.ExpectedError(StrSubstNo(DataExchLineDefNotFoundErr, DataExchDef.Name, ''));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingDataExchLineDefFixedWidth()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        MissingDataExchLineDef(DataExchDef."File Type"::"Fixed Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingDataExchLineDefCSV()
    var
        DataExchDef: Record "Data Exch. Def";
    begin
        MissingDataExchLineDef(DataExchDef."File Type"::"Variable Text");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingValueOnNonOptionalCode()
    begin
        VerifyFieldMappingError('', '', 88, DataExchColDefType."Data Type"::Text, '', 0, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingValueOnNonOptionalInteger()
    begin
        VerifyFieldMappingError(0, '', 3, DataExchColDefType."Data Type"::Decimal, '', 0, 1, '');
    end;

    local procedure VerifyFieldMapping(InputValue: Variant; ExpectedOutput: Text; FieldNo: Integer; DataType: Option; DataTypeFormatting: Text[100]; Length: Integer; Multiplier: Decimal; DefaultValue: Text[50]; FileType: Integer)
    var
        TempPmtExportData: Record "Payment Export Data" temporary;
        BankAcc: Record "Bank Account";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchField: Record "Data Exch. Field";
        DataExch: Record "Data Exch.";
        PaymentExportMgt: Codeunit "Payment Export Mgt";
    begin
        Initialize();

        // Setup export definition
        CreateDataExchDef(DataExchDef, FileType);
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 1);
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 1, '', DataType, DataTypeFormatting, Length, '');
        CreateDataExchMapping(DataExchDef.Code, DataExchLineDef.Code);
        CreateDataExchFieldMapping(DataExchDef.Code, DataExchLineDef.Code, 1, FieldNo, DefaultValue, Multiplier);

        // Setup Input data
        CreateDataExch(DataExch, DataExchDef.Code);
        CreateAnyBankAccount(BankAcc);
        CreatePaymentExportDataSingleValue(TempPmtExportData, BankAcc."No.", DataExch."Entry No.", DataExchLineDef.Code, FieldNo, InputValue);

        // Exercise
        PaymentExportMgt.CreatePaymentLines(TempPmtExportData);

        // Verify
        DataExchField.Get(DataExch."Entry No.", 1, 1);
        Assert.AreEqual(ExpectedOutput, DataExchField.Value, 'Wrong Value');
    end;

    local procedure VerifyFieldMappingError(InputValue: Variant; ExpectedOutput: Text; FieldNo: Integer; DataType: Option; DataTypeFormatting: Text[100]; Length: Integer; Multiplier: Decimal; DefaultValue: Text[50])
    var
        TempPmtExportData: Record "Payment Export Data" temporary;
        BankAcc: Record "Bank Account";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        DataExchField: Record "Data Exch. Field";
        DataExch: Record "Data Exch.";
        PaymentExportMgt: Codeunit "Payment Export Mgt";
        RecRef: RecordRef;
        ExpectedError: Text;
    begin
        Initialize();

        // Setup export definition
        if Length = 0 then
            CreateDataExchDef(DataExchDef, DataExchDef."File Type"::"Variable Text")
        else
            CreateDataExchDef(DataExchDef, DataExchDef."File Type"::"Fixed Text");

        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 1);
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 1, '', DataType, DataTypeFormatting, Length, '');
        CreateDataExchMapping(DataExchDef.Code, DataExchLineDef.Code);
        CreateDataExchFieldMapping(DataExchDef.Code, DataExchLineDef.Code, 1, FieldNo, DefaultValue, Multiplier);

        // Setyp Input data
        CreateDataExch(DataExch, DataExchDef.Code);
        CreateAnyBankAccount(BankAcc);
        CreatePaymentExportDataSingleValue(TempPmtExportData, BankAcc."No.", DataExch."Entry No.", DataExchLineDef.Code, FieldNo, InputValue);

        // Exercise
        asserterror PaymentExportMgt.CreatePaymentLines(TempPmtExportData);

        // Verify
        RecRef.Open(DATABASE::"Payment Export Data");

        if GetLastErrorCode = 'TestField' then
            Assert.ExpectedTestFieldError(RecRef.Field(FieldNo).Caption, '')
        else
            ExpectedError :=
              StrSubstNo(IncorrectLengthOfValuesErr,
                DataExchDef.Type::"Payment Export", DataExchDef.Code, RecRef.Field(FieldNo).Caption,
                Length, StrLen(ExpectedOutput), ExpectedOutput);

        if ExpectedError <> '' then
            AssertExpectedError(ExpectedError);
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsTrue(DataExchField.IsEmpty, 'No line should be imported');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MissingValueOnOptional()
    var
        TempPmtExportData: Record "Payment Export Data" temporary;
        BankAcc: Record "Bank Account";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        PaymentExportMgt: Codeunit "Payment Export Mgt";
    begin
        Initialize();

        // Setup export definition
        CreateDataExchDef(DataExchDef, DataExchDef."File Type"::"Fixed Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 3);
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 1, 'Amount',
          DataExchColDefType."Data Type"::Decimal, '', 1, '');
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 2, 'Transfer Date',
          DataExchColDefType."Data Type"::Date, '', 0, '');
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 3, 'Short Advice',
          DataExchColDefType."Data Type"::Text, '', 0, '');
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 4, 'Short Advice Format as Decimal',
          DataExchColDefType."Data Type"::Decimal, '<Integer,4><Filler Char,0>', 4, '');

        CreateDataExchMapping(DataExchDef.Code, DataExchLineDef.Code);
        CreateDataExchFieldMappingOptional(DataExchDef.Code, DataExchLineDef.Code, 1, 80, 1);
        CreateDataExchFieldMappingOptional(DataExchDef.Code, DataExchLineDef.Code, 2, 82, 0);
        CreateDataExchFieldMappingOptional(DataExchDef.Code, DataExchLineDef.Code, 3, 64, 0);
        CreateDataExchFieldMappingOptional(DataExchDef.Code, DataExchLineDef.Code, 4, 64, 1);

        // Setup input data
        CreateDataExch(DataExch, DataExchDef.Code);
        CreateAnyBankAccount(BankAcc);
        CreatePaymentExportData(TempPmtExportData, BankAcc."No.", 1, 0, 0D, '', DataExch."Entry No.", DataExchLineDef.Code);

        // Exercise
        PaymentExportMgt.CreatePaymentLines(TempPmtExportData);

        // Verify
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, '0', DataExchLineDef.Code);
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, Format(0D), DataExchLineDef.Code);
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 3, '', DataExchLineDef.Code);
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 4, '0000', DataExchLineDef.Code);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportUnmappedField()
    var
        TempPmtExportData: Record "Payment Export Data" temporary;
        BankAcc: Record "Bank Account";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        PaymentExportMgt: Codeunit "Payment Export Mgt";
    begin
        Initialize();

        // Setup export definition
        CreateDataExchDef(DataExchDef, DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 3);
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 1, 'Amount',
          DataExchColDefType."Data Type"::Decimal, '', 0, '');
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 2, 'Transfer Date',
          DataExchColDefType."Data Type"::Date, '', 0, '');
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 3, 'Short Advice',
          DataExchColDefType."Data Type"::Text, '', 0, '');

        CreateDataExchMapping(DataExchDef.Code, DataExchLineDef.Code);
        CreateDataExchFieldMapping(DataExchDef.Code, DataExchLineDef.Code, 2, 82, '', 0);
        CreateDataExchFieldMapping(DataExchDef.Code, DataExchLineDef.Code, 3, 64, '', 0);

        // Setup input data
        CreateDataExch(DataExch, DataExchDef.Code);
        CreateAnyBankAccount(BankAcc);
        CreatePaymentExportData(TempPmtExportData, BankAcc."No.", 1, AnyDecimal, AnyDate,
          AnyText, DataExch."Entry No.", DataExchLineDef.Code);

        // Exercise
        PaymentExportMgt.CreatePaymentLines(TempPmtExportData);

        // Verify
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, '', DataExchLineDef.Code);
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, Format(AnyDate), DataExchLineDef.Code);
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 3, AnyText, DataExchLineDef.Code);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportUnmappedFieldFixedWidth()
    var
        TempPmtExportData: Record "Payment Export Data" temporary;
        BankAcc: Record "Bank Account";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        PaymentExportMgt: Codeunit "Payment Export Mgt";
    begin
        Initialize();

        // Setup export definition
        CreateDataExchDef(DataExchDef, DataExchDef."File Type"::"Fixed Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 1, 'Amount',
          DataExchColDefType."Data Type"::Decimal, '', 5, '');
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 2, 'Transfer Date',
          DataExchColDefType."Data Type"::Date, '', StrLen(Format(AnyDate)), '');
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 3, 'Short Advice',
          DataExchColDefType."Data Type"::Text, '', 5, 'Const');

        CreateDataExchMapping(DataExchDef.Code, DataExchLineDef.Code);
        CreateDataExchFieldMapping(DataExchDef.Code, DataExchLineDef.Code, 2, 82, '', 0);

        // Setup input data
        CreateDataExch(DataExch, DataExchDef.Code);
        CreateAnyBankAccount(BankAcc);
        CreatePaymentExportData(TempPmtExportData, BankAcc."No.", 1, AnyDecimal, AnyDate,
          AnyText, DataExch."Entry No.", DataExchLineDef.Code);

        // Exercise
        PaymentExportMgt.CreatePaymentLines(TempPmtExportData);

        // Verify
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, '     ', DataExchLineDef.Code);
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, Format(AnyDate), DataExchLineDef.Code);
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 3, 'Const', DataExchLineDef.Code);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportDifferentLineTypes()
    var
        TempPmtExportData: Record "Payment Export Data" temporary;
        BankAcc: Record "Bank Account";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempExpectedDataExchField: Record "Data Exch. Field" temporary;
        DataExch: Record "Data Exch.";
        DataExchField: Record "Data Exch. Field";
        PaymentExportMgt: Codeunit "Payment Export Mgt";
    begin
        Initialize();

        // Setup export definition
        CreateDataExchDef(DataExchDef, DataExchDef."File Type"::"Variable Text");
        DataExchLineDef.InsertRec(DataExchDef.Code, 'LineType1', '', 7);
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 2, 'Amount',
          DataExchColDefType."Data Type"::Decimal, '', 0, '');
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 4, 'Transfer Date',
          DataExchColDefType."Data Type"::Date, '', 0, '');

        CreateDataExchMapping(DataExchDef.Code, DataExchLineDef.Code);
        CreateDataExchFieldMapping(DataExchDef.Code, DataExchLineDef.Code, 2, 80, '', 1);
        CreateDataExchFieldMapping(DataExchDef.Code, DataExchLineDef.Code, 4, 82, '', 0);

        DataExchLineDef.InsertRec(DataExchDef.Code, 'LineType2', '', 4);
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 1, 'Short Advice',
          DataExchColDefType."Data Type"::Text, '', 0, '');
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 2, 'Amount',
          DataExchColDefType."Data Type"::Decimal, '', 0, '');
        CreateDataExchColDef(DataExchDef.Code, DataExchLineDef.Code, 3, 'Transfer Date',
          DataExchColDefType."Data Type"::Date, '', 0, '');

        CreateDataExchMapping(DataExchDef.Code, DataExchLineDef.Code);
        CreateDataExchFieldMapping(DataExchDef.Code, DataExchLineDef.Code, 1, 64, '', 0);
        CreateDataExchFieldMapping(DataExchDef.Code, DataExchLineDef.Code, 2, 80, '', 1);
        CreateDataExchFieldMapping(DataExchDef.Code, DataExchLineDef.Code, 3, 82, '', 0);

        // Setup input data
        CreateDataExch(DataExch, DataExchDef.Code);
        CreateAnyBankAccount(BankAcc);

        // Exercise
        CreatePaymentExportData(TempPmtExportData, BankAcc."No.", 1, AnyDecimal, AnyDate,
          AnyText, DataExch."Entry No.", 'LineType1');
        PaymentExportMgt.CreatePaymentLines(TempPmtExportData);
        CreatePaymentExportData(TempPmtExportData, BankAcc."No.", 2, AnyDecimal, AnyDate,
          AnyText, DataExch."Entry No.", 'LineType2');
        PaymentExportMgt.CreatePaymentLines(TempPmtExportData);

        // Verify
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 1, '', 'LineType1');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 2, Format(AnyDecimal), 'LineType1');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 3, '', 'LineType1');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 4, Format(AnyDate), 'LineType1');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 5, '', 'LineType1');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 6, '', 'LineType1');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 1, 7, '', 'LineType1');

        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 1, AnyText, 'LineType2');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 2, Format(AnyDecimal), 'LineType2');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 3, Format(AnyDate), 'LineType2');
        TempExpectedDataExchField.InsertRec(DataExch."Entry No.", 2, 4, '', 'LineType2');

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        AssertDataInTable(TempExpectedDataExchField, DataExchField, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentVendorLedgerEntryExported()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, true);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());

        // Exercise
        SuggestVendorPayment(VendLedgerEntry, GenJnlBatch, GenJnlLine);

        // Verify
        FindAppliedGenJnlLine(GenJnlBatch, VendLedgerEntry, GenJnlLine);
        GenJnlLine.TestField("Exported to Payment File", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentVendorLedgerEntryNotExported()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();

        // Setup
        CreateVendorLedgerEntry(VendLedgerEntry, VendLedgerEntry."Document Type"::Invoice, false);
        CreateGenJournalBatch(GenJnlBatch, LibraryUtility.GenerateGUID());

        // Exercise
        SuggestVendorPayment(VendLedgerEntry, GenJnlBatch, GenJnlLine);

        // Verify
        FindAppliedGenJnlLine(GenJnlBatch, VendLedgerEntry, GenJnlLine);
        GenJnlLine.TestField("Exported to Payment File", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataExchFieldNotRemovedWhenPostingNonRelatedGenJnlLine()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DataExchField: Record "Data Exch. Field";
    begin
        // [SCENARIO 377827] Posting Exch. Field should not be removed when posting non-related General Journal Line in the same batch with related

        Initialize();
        // [GIVEN] Posting Exch. Field
        MockDataExchField(DataExchField, MockDataExchNo());

        // [GIVEN] General Journal Line "A" in batch "X" related to Posting Exch. Field
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, "Gen. Journal Document Type"::" ", GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(1000, 2));
        GenJnlLine."Data Exch. Entry No." := DataExchField."Data Exch. No.";
        GenJnlLine."Data Exch. Line No." := DataExchField."Line No.";
        GenJnlLine.Modify(true);

        // [GIVEN] General Journal Line "B" in batch "X" without relation to Posting Exch. Field
        LibraryJournals.CreateGenJournalLine(
          GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", "Gen. Journal Document Type"::" ",
          GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Filter on General Journal Line "B"
        GenJnlLine.SetRecFilter();

        // [WHEN] Post General Journal Line "B"
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine);

        // [THEN] Posting Exch. Field is not removed
        DataExchField.SetRecFilter();
        Assert.RecordIsNotEmpty(DataExchField);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportGenJnlCheckPerfomance()
    var
        PaymentExportMgtUnitTest: Codeunit "Payment Export Mgt Unit Test";
        GenJournalTemplateName: Code[10];
        BatchCount: Integer;
    begin
        // [FEATURE] [Purchase] [Payment Export]
        // [SCENARIO 379332] Codeunit 1211 must call batch validation once per batch
        Initialize();

        // [GIVEN] 3 Gen. Journal Batches with some 4 lines per each batch
        GenJournalTemplateName := CreateGenJnlBatchWithLines(BatchCount);
        Commit();
        BindSubscription(PaymentExportMgtUnitTest);
        PaymentExportMgtUnitTest.InitializeEventHitsCounter();

        // [WHEN] Run check for all batches
        RunGenJnlLines(GenJournalTemplateName);

        // [THEN] The event OnCheckGenJournalLineExportRestrictions fired 3 times
        PaymentExportMgtUnitTest.VerifyEventHitsCounter(BatchCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentExportGenJnlLineCleanErrors()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        // [FEATURE] [[Payment Export]] [Gen. Journal Line] 
        // [SCENARIO 539686] Clean Payment Jnl. Export Errors when change Bank Payment Type
        Initialize();

        // [GIVEN] The Gen. Journal line with Bank Payment Type = "Electronic Payment" and Payment Jnl. Export Error Text
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, "Gen. Journal Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate(GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Modify(true);

        PaymentJnlExportErrorText.Init();
        PaymentJnlExportErrorText."Journal Template Name" := GenJournalLine."Journal Template Name";
        PaymentJnlExportErrorText."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        PaymentJnlExportErrorText."Journal Line No." := GenJournalLine."Line No.";
        PaymentJnlExportErrorText."Document No." := GenJournalLine."Document No.";
        PaymentJnlExportErrorText.Insert();

        // [WHEN] Change Bank Payment Type to " "
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::" ");

        // [THEN] Payment Jnl. Export Error Text is removed
        PaymentJnlExportErrorText.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        PaymentJnlExportErrorText.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        PaymentJnlExportErrorText.SetRange("Journal Line No.", GenJournalLine."Line No.");
        Assert.RecordIsEmpty(PaymentJnlExportErrorText);
    end;

    local procedure Initialize()
    var
        PaymentExportData: Record "Payment Export Data";
    begin
        AnyText := LibraryUtility.GenerateRandomCode(PaymentExportData.FieldNo("Short Advice"), DATABASE::"Payment Export Data");
        AnyDecimal := LibraryRandom.RandDecInRange(-1000000, 1000000, 2);
        AnyDate := LibraryUtility.GenerateRandomDate(WorkDate() - 200, WorkDate() + 200);
    end;

    local procedure ApplyPaymentAutomatically(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
        ApplyToOpenLedgerEntriesWithAppliesToDocNo(GenJnlLine, VendLedgerEntry."Document Type", VendLedgerEntry."Document No.");
    end;

    local procedure ApplyPaymentManually(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgerEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50])
    begin
        ApplyToOpenLedgerEntriesWithAppliesToID(GenJnlLine, VendLedgerEntry, AppliesToID);
    end;

    local procedure ApplyToOpenLedgerEntriesWithAppliesToDocNo(var GenJnlLine: Record "Gen. Journal Line"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20])
    begin
        GenJnlLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJnlLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJnlLine.Modify();
    end;

    local procedure ApplyToOpenLedgerEntriesWithAppliesToID(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgerEntry: Record "Vendor Ledger Entry"; AppliesToID: Code[50])
    begin
        VendLedgerEntry."Applies-to ID" := AppliesToID;
        VendLedgerEntry.Modify();

        GenJnlLine.Validate("Applies-to ID", AppliesToID);
        GenJnlLine.Modify();
    end;

    local procedure SuggestVendorPayment(VendLedgerEntry: Record "Vendor Ledger Entry"; GenJnlBatch: Record "Gen. Journal Batch"; var GenJnlLine: Record "Gen. Journal Line")
    var
        Vendor: Record Vendor;
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        GenJnlLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJnlLine.Validate("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.Validate("Journal Batch Name", GenJnlBatch.Name);
        SuggestVendorPayments.SetGenJnlLine(GenJnlLine);

        Vendor.SetRange("No.", VendLedgerEntry."Vendor No.");
        SuggestVendorPayments.SetTableView(Vendor);

        SuggestVendorPayments.InitializeRequest(VendLedgerEntry."Due Date", false, 0, false, VendLedgerEntry."Due Date", '1', false,
          GenJnlBatch."Bal. Account Type", '', GenJnlLine."Bank Payment Type"::" ");
        SuggestVendorPayments.UseRequestPage(false);
        SuggestVendorPayments.RunModal();
    end;

    local procedure CheckCreditTransferRegisterStatus(BankAccountNo: Code[20]; Status: Option)
    var
        CreditTransferRegister: Record "Credit Transfer Register";
    begin
        CreditTransferRegister.SetRange("From Bank Account No.", BankAccountNo);
        CreditTransferRegister.FindLast();
        CreditTransferRegister.TestField(Status, Status);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; BankBranchNo: Text[20]; BankAccountNo: Text[30])
    begin
        LibraryERM.CreateBankAccount(BankAccount);

        BankAccount."Bank Branch No." := BankBranchNo;
        BankAccount."Bank Account No." := BankAccountNo;
        BankAccount.IBAN := '';
        BankAccount.Modify();
    end;

    local procedure CreateAnyBankAccount(var BankAccount: Record "Bank Account")
    begin
        CreateBankAccount(BankAccount,
          Format(LibraryRandom.RandIntInRange(1111, 9999)),
          Format(LibraryRandom.RandIntInRange(111111111, 999999999)) + '9');
    end;

    local procedure CreateBankAccountWithExportFormat(var BankAccount: Record "Bank Account")
    var
        DataExchDef: Record "Data Exch. Def";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryPaymentFormat.CreateDataExchDef(
          DataExchDef, 0, 0, CODEUNIT::"Exp. Writing Gen. Jnl.",
          XMLPORT::"Export Generic CSV", CODEUNIT::"Save Data Exch. Blob Sample", 0);
        LibraryPaymentFormat.CreateBankExportImportSetup(BankExportImportSetup, DataExchDef);
        BankAccount.Validate("Payment Export Format", BankExportImportSetup.Code);
        BankAccount.Modify(true);
    end;

    local procedure CreateCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; Exported: Boolean)
    var
        PaymentMethod: Record "Payment Method";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LastCustLedgerEntryNo() + 1000;
        CustLedgerEntry."Customer No." := LibrarySales.CreateCustomerNo();
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        CustLedgerEntry.Open := true;
        CustLedgerEntry."Due Date" := CalcDate('<1D>', CustLedgerEntry."Posting Date");
        CustLedgerEntry."Bal. Account Type" := CustLedgerEntry."Bal. Account Type"::"Bank Account";
        CustLedgerEntry."Bal. Account No." := LibraryUtility.GenerateGUID();
        CustLedgerEntry.Amount := LibraryRandom.RandDecInRange(100, 1000, 2);
        LibraryPaymentExport.CreatePaymentMethod(PaymentMethod);
        CustLedgerEntry."Payment Method Code" := PaymentMethod.Code;
        CustLedgerEntry."Recipient Bank Account" := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Message to Recipient" := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Exported to Payment File" := Exported;
        CustLedgerEntry.Insert();
    end;

    local procedure CreateCustWithCustBankAcc(var CustomerBankAccount: Record "Customer Bank Account"; BankBranchNo: Text[20]; BankAccountNo: Text[30]; NewIBAN: Code[50])
    begin
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, LibrarySales.CreateCustomerNo());

        CustomerBankAccount."Bank Branch No." := CopyStr(BankBranchNo, 1, MaxStrLen(CustomerBankAccount."Bank Branch No."));
        CustomerBankAccount."Bank Account No." := BankAccountNo;
        CustomerBankAccount.IBAN := NewIBAN;
        CustomerBankAccount.Modify();
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; BalAccountNo: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryPaymentExport.SelectPaymentJournalTemplate());
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BalAccountNo;
        GenJournalBatch."Allow Payment Export" := true;
        GenJournalBatch.Modify();
    end;

    local procedure CreateGenJournalLine(var GenJnlLine: Record "Gen. Journal Line"; GenJnlBatch: Record "Gen. Journal Batch"; VendLedgerEntry: Record "Vendor Ledger Entry")
    begin
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        GenJnlLine."Line No." := LibraryRandom.RandInt(10000);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
        GenJnlLine."Account No." := VendLedgerEntry."Vendor No.";
        GenJnlLine."Posting Date" := WorkDate();
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := LibraryUtility.GenerateGUID();
        GenJnlLine."External Document No." := LibraryUtility.GenerateGUID();
        GenJnlLine.Amount := VendLedgerEntry.Amount;
        GenJnlLine."Bal. Account Type" := GenJnlBatch."Bal. Account Type";
        GenJnlLine."Bal. Account No." := GenJnlBatch."Bal. Account No.";
        GenJnlLine."Payment Method Code" := VendLedgerEntry."Payment Method Code";
        GenJnlLine."Recipient Bank Account" := LibraryUtility.GenerateGUID();
        GenJnlLine."Message to Recipient" := LibraryUtility.GenerateGUID();
        GenJnlLine.Insert();
    end;

    local procedure CreateVendorLedgerEntry(var VendLedgerEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; Exported: Boolean)
    var
        PaymentMethod: Record "Payment Method";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendLedgerEntry.Init();
        VendLedgerEntry."Entry No." := LastVendorLedgerEntryNo() + 1000;
        VendLedgerEntry."Vendor No." := LibraryPurchase.CreateVendorNo();
        VendLedgerEntry."Posting Date" := WorkDate();
        VendLedgerEntry."Document Type" := DocumentType;
        VendLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        VendLedgerEntry.Open := true;
        VendLedgerEntry."Due Date" := CalcDate('<1D>', VendLedgerEntry."Posting Date");
        VendLedgerEntry.Amount := -LibraryRandom.RandDecInRange(100, 1000, 2);
        VendLedgerEntry."Bal. Account Type" := VendLedgerEntry."Bal. Account Type"::"Bank Account";
        VendLedgerEntry."Bal. Account No." := LibraryUtility.GenerateGUID();
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        VendLedgerEntry."Payment Method Code" := PaymentMethod.Code;
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendLedgerEntry."Vendor No.");
        VendLedgerEntry."Recipient Bank Account" := VendorBankAccount.Code;
        VendLedgerEntry."Message to Recipient" := LibraryUtility.GenerateGUID();
        VendLedgerEntry."Exported to Payment File" := Exported;
        VendLedgerEntry.Insert();
        CreateDtldVendLedgEntry(VendLedgerEntry);
    end;

    local procedure CreateVendorWithVendorBankAcc(var VendorBankAccount: Record "Vendor Bank Account"; BankBranchNo: Text[20]; BankAccountNo: Text[30]; NewIBAN: Code[50])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, LibraryPurchase.CreateVendorNo());

        VendorBankAccount."Bank Branch No." := BankBranchNo;
        VendorBankAccount."Bank Account No." := BankAccountNo;
        VendorBankAccount.IBAN := NewIBAN;
        VendorBankAccount.Modify();
    end;

    local procedure CreateGenJnlBatchWithLines(var BatchCount: Integer): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BatchIndex: Integer;
        BatchRecCount: Integer;
        RecIndex: Integer;
    begin
        BatchCount := LibraryRandom.RandIntInRange(2, 5);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        for BatchIndex := 1 to BatchCount do begin
            BatchRecCount := LibraryRandom.RandIntInRange(2, 5);
            LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
            for RecIndex := 1 to BatchRecCount do
                LibraryJournals.CreateGenJournalLine(
                  GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
                  "Gen. Journal Account Type"::"G/L Account", '', "Gen. Journal Account Type"::"G/L Account", '', 0);
        end;
        exit(GenJournalTemplate.Name);
    end;

    local procedure RunGenJnlLines(GenJournalTemplateName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        PaymentExportGenJnlCheck: Codeunit "Payment Export Gen. Jnl Check";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplateName);
        GenJournalLine.FindSet();
        repeat
            if PaymentExportGenJnlCheck.Run(GenJournalLine) then;
        until GenJournalLine.Next() = 0;
    end;

    local procedure MockDataExchNo(): Integer
    var
        DataExch: Record "Data Exch.";
    begin
        DataExch.Init();
        DataExch."Entry No." := LibraryUtility.GetNewRecNo(DataExch, DataExch.FieldNo("Entry No."));
        DataExch.Insert();
        exit(DataExch."Entry No.");
    end;

    local procedure MockDataExchField(var DataExchField: Record "Data Exch. Field"; PostExchNo: Integer)
    begin
        DataExchField.Init();
        DataExchField."Data Exch. No." := PostExchNo;
        DataExchField."Line No." := LibraryRandom.RandInt(100);
        DataExchField.Insert();
    end;

    local procedure CreateDtldVendLedgEntry(VendLedgEntry: Record "Vendor Ledger Entry")
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::"Vendor Ledger Entry");
        DtldVendLedgEntry.Init();
        DtldVendLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, DtldVendLedgEntry.FieldNo("Entry No."));
        DtldVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntry."Entry No.";
        DtldVendLedgEntry."Entry Type" := DtldVendLedgEntry."Entry Type"::"Initial Entry";
        DtldVendLedgEntry."Posting Date" := VendLedgEntry."Posting Date";
        DtldVendLedgEntry."Document Type" := VendLedgEntry."Document Type";
        DtldVendLedgEntry."Document No." := VendLedgEntry."Document No.";
        DtldVendLedgEntry.Amount := VendLedgEntry.Amount;
        DtldVendLedgEntry."Amount (LCY)" := DtldVendLedgEntry.Amount;
        DtldVendLedgEntry."Vendor No." := VendLedgEntry."Vendor No.";
        DtldVendLedgEntry."Ledger Entry Amount" := true;
        DtldVendLedgEntry.Insert();
    end;

    local procedure FindAppliedGenJnlLine(GenJnlBatch: Record "Gen. Journal Batch"; VendLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Applies-to Doc. Type", VendLedgerEntry."Document Type");
        GenJnlLine.SetRange("Applies-to Doc. No.", VendLedgerEntry."Document No.");
        GenJnlLine.FindFirst();
    end;

    local procedure LastCustLedgerEntryNo(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindLast() then
            exit(CustLedgerEntry."Entry No.");
        exit(0);
    end;

    local procedure LastVendorLedgerEntryNo(): Integer
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VendLedgerEntry.FindLast() then
            exit(VendLedgerEntry."Entry No.");
        exit(0);
    end;

    local procedure CreateDataExchDef(var DataExchDef: Record "Data Exch. Def"; FileType: Option)
    begin
        DataExchDef.InsertRecForExport(LibraryUtility.GenerateRandomCode(DataExchDef.FieldNo(Code), DATABASE::"Data Exch. Def"),
          LibraryUtility.GenerateGUID(), DataExchDef.Type::"Payment Export".AsInteger(), 0, FileType);
    end;

    local procedure CreateDataExchColDef(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; Name: Text[30]; DataType: Option; DataTypeFormatting: Text[100]; Length: Integer; Constant: Text[30])
    var
        DataExchColDef: Record "Data Exch. Column Def";
    begin
        DataExchColDef.InsertRecForExport(
          DataExchDefCode, DataExchLineDefCode, ColumnNo, Name, DataType, DataTypeFormatting, Length, Constant);
    end;

    local procedure CreateDataExchMapping(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20])
    var
        DataExchMapping: Record "Data Exch. Mapping";
    begin
        DataExchMapping.InsertRecForExport(DataExchDefCode, DataExchLineDefCode, 1226, 'Test Mapping', 0);
    end;

    local procedure CreateDataExchFieldMapping(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; FieldId: Integer; DefaultValue: Text[250]; Multiplier: Decimal)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.InsertRec(DataExchDefCode, DataExchLineDefCode, 1226, ColumnNo, FieldId, false, Multiplier);

        if DefaultValue <> '' then begin
            DataExchFieldMapping.Validate("Default Value", DefaultValue);
            DataExchFieldMapping.Modify();
        end;
    end;

    local procedure CreateDataExchFieldMappingOptional(DataExchDefCode: Code[20]; DataExchLineDefCode: Code[20]; ColumnNo: Integer; FieldId: Integer; Multiplier: Decimal)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.InsertRec(DataExchDefCode, DataExchLineDefCode, 1226, ColumnNo, FieldId, true, Multiplier);
    end;

    local procedure CreatePaymentExportData(var PaymentExportData: Record "Payment Export Data"; BankAccCode: Code[20]; LineNo: Integer; Amount: Decimal; TransferDate: Date; ShortAdvice: Text[20]; DataExchEntryNo: Integer; DataExchLineDefCode: Code[20])
    begin
        PaymentExportData.Init();
        PaymentExportData."Data Exch. Line Def Code" := DataExchLineDefCode;
        PaymentExportData."Sender Bank Account Code" := BankAccCode;
        PaymentExportData."Data Exch Entry No." := DataExchEntryNo;
        PaymentExportData."Entry No." := LineNo;
        PaymentExportData."Line No." := LineNo;
        PaymentExportData.Amount := Amount;
        PaymentExportData."Transfer Date" := TransferDate;
        PaymentExportData."Short Advice" := ShortAdvice;
        PaymentExportData.Insert();
    end;

    local procedure CreatePaymentExportDataSingleValue(var PaymentExportData: Record "Payment Export Data"; BankAccCode: Code[20]; DataExchEntryNo: Integer; DataExchLineDefCode: Code[20]; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        PaymentExportData.Init();
        PaymentExportData."Data Exch. Line Def Code" := DataExchLineDefCode;
        PaymentExportData."Sender Bank Account Code" := BankAccCode;
        PaymentExportData."Data Exch Entry No." := DataExchEntryNo;
        PaymentExportData."Entry No." := 1;
        PaymentExportData."Line No." := 1;

        RecRef.GetTable(PaymentExportData);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Value := Value;
        RecRef.Insert();
        RecRef.SetTable(PaymentExportData);
    end;

    local procedure CreateDataExch(var DataExch: Record "Data Exch."; DataExchDefCode: Code[20])
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('', InStream, DataExchDefCode);
        DataExch.SetRange("Entry No.", DataExch."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure InitializeEventHitsCounter()
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", 'OnCheckGenJournalLineExportRestrictions', '', false, false)]
    local procedure CountEventHitsOnCheckGenJournalLineExportRestrictions(var Sender: Record "Gen. Journal Batch")
    begin
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger() + 1);
    end;

    [Scope('OnPrem')]
    procedure VerifyEventHitsCounter(ExpectedCount: Integer)
    begin
        Assert.AreEqual(ExpectedCount, LibraryVariableStorage.DequeueInteger(), IncorrectNoOfBatchErr);
    end;

    local procedure AssertDataInTable(var ExpectedDataExchField: Record "Data Exch. Field"; var ActualDataExchField: Record "Data Exch. Field"; Msg: Text)
    var
        LineNo: Integer;
    begin
        ExpectedDataExchField.FindFirst();
        ActualDataExchField.FindFirst();
        repeat
            LineNo += 1;
            AreEqualRecords(ExpectedDataExchField, ActualDataExchField, StrSubstNo(TableErrorMsg, Msg, LineNo));
        until (ExpectedDataExchField.Next() = 0) or (ActualDataExchField.Next() = 0);
        Assert.AreEqual(ExpectedDataExchField.Count, ActualDataExchField.Count, 'Row count does not match');
    end;

    local procedure AreEqualRecords(ExpectedRecord: Variant; ActualRecord: Variant; Msg: Text)
    var
        ExpectedRecRef: RecordRef;
        ActualRecRef: RecordRef;
        i: Integer;
    begin
        ExpectedRecRef.GetTable(ExpectedRecord);
        ActualRecRef.GetTable(ActualRecord);

        Assert.AreEqual(ExpectedRecRef.Number, ActualRecRef.Number, 'Tables are not the same');

        for i := 1 to ExpectedRecRef.FieldCount do
            if IsSupportedType(ExpectedRecRef.FieldIndex(i).Value) then
                Assert.AreEqual(ExpectedRecRef.FieldIndex(i).Value, ActualRecRef.FieldIndex(i).Value,
                  StrSubstNo(AssertMsg, Msg, ExpectedRecRef.FieldIndex(i).Name));
    end;

    local procedure IsSupportedType(Value: Variant): Boolean
    begin
        exit(Value.IsBoolean or
          Value.IsOption or
          Value.IsInteger or
          Value.IsDecimal or
          Value.IsText or
          Value.IsCode or
          Value.IsDate or
          Value.IsTime);
    end;

    local procedure AssertExpectedError(Expected: Text)
    begin
        if StrPos(GetLastErrorText, Expected) = 0 then
            Error(ExpectedErrorFailedErr, Expected, GetLastErrorText);
    end;

    local procedure SetGenJournalLineExported(var GenJournalLine: Record "Gen. Journal Line"; Exported: Boolean)
    begin
        GenJournalLine."Exported to Payment File" := Exported;
        GenJournalLine.Modify();
    end;

    local procedure CreateSimpleBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        CreateBankAccount(BankAccount, '', '');
        exit(BankAccount."No.");
    end;

    local procedure DefinePaymentExportFormat(var DataExchMapping: Record "Data Exch. Mapping")
    var
        PaymentExportData: Record "Payment Export Data";
        DataExchDef: Record "Data Exch. Def";
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping(DataExchMapping,
          DATABASE::"Payment Export Data", PaymentExportData.FieldNo("Message to Recipient 1"));

        DataExchDef.Get(DataExchMapping."Data Exch. Def Code");
        DataExchDef.Validate("File Type", DataExchDef."File Type"::"Variable Text");
        DataExchDef.Validate("Reading/Writing XMLport", XMLPORT::"Export Generic CSV");
        DataExchDef.Modify(true);

        DataExchLineDef.Get(DataExchMapping."Data Exch. Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExchLineDef.Validate("Column Count", 1);
        DataExchLineDef.Modify(true);
    end;

    local procedure UpdatePaymentMethodLineDef(PaymentMethodCode: Code[10]; DataExchLineDefCode: Code[20])
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get(PaymentMethodCode);
        PaymentMethod.Validate("Pmt. Export Line Definition", DataExchLineDefCode);
        PaymentMethod.Modify(true);
    end;

    local procedure CreateErrorsForGenJnlLine(GenJnlLine: Record "Gen. Journal Line")
    var
        PmtJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PmtJnlExportErrorText.CreateNew(GenJnlLine, '', '', '');
    end;

    local procedure DeleteExtraPaymentJnlTemplates()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetFilter(Name, '<>%1', LibraryPurchase.SelectPmtJnlTemplate());
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange("Page ID", PAGE::"Payment Journal");
        GenJournalTemplate.DeleteAll(true);
    end;
}

