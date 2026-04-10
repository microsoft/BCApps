codeunit 134013 "ERM BAT Test for Application"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Application] [Sales]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvCustLedEntry()
    begin
        ApplyCustLedEntry("Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCMCustLedEntry()
    begin
        ApplyCustLedEntry("Gen. Journal Document Type"::Refund, "Gen. Journal Document Type"::"Credit Memo", -LibraryRandom.RandDec(100, 2));
    end;

    [Normal]
    local procedure ApplyCustLedEntry(ApplyingType: Enum "Gen. Journal Document Type"; AppliesToType: Enum "Gen. Journal Document Type"; ApplicationAmount: Decimal)
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Application using Customer Ledger Entry and verify the same post application.

        // Setup: Setup Data for Apply Customer Ledger Entries.
        // Create and Post General Journal Line for Credit Memo and Refund.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // Use LibraryRandom to select Random Amount.
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, AppliesToType, Customer."No.", ApplicationAmount);
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, ApplyingType, GenJournalLine."Account No.", -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Apply and Post Refund to Credit Memo from Customer Ledger Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", GenJournalLine.Amount, ApplyingType);

        // Verification: Verify Customer Ledger Entry.
        VerifyCustLedEntry(ApplyingType, GenJournalLine."Document No.");
        VerifyCustLedEntry(AppliesToType, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvAppliesToID()
    begin
        ApplyAppliesToID("Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCMAppliesToID()
    begin
        ApplyAppliesToID("Gen. Journal Document Type"::Refund, "Gen. Journal Document Type"::"Credit Memo", -LibraryRandom.RandDec(100, 2));
    end;

    [Normal]
    local procedure ApplyAppliesToID(ApplyingType: Enum "Gen. Journal Document Type"; AppliesToType: Enum "Gen. Journal Document Type"; ApplicationAmount: Decimal)
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Application using Applies to ID and verify Customer Ledger Entry post application.

        // Setup: Setup Data for Apply Customer Ledger Entries.
        // Create and Post General Journal Line for Invoice.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // Use LibraryRandom to select Random Amount.
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, AppliesToType, Customer."No.", ApplicationAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create General Journal Line for Payment.
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, ApplyingType, GenJournalLine."Account No.", 0);

        // Exercise: Application of Payment Entry to Invoice using Applies to ID.
        // Post General Journal Line.
        ApplyCustLedEntryAppliesToID(GenJournalLine, CustLedgerEntry);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verification: Verify Customer Ledger Entry.
        VerifyCustLedEntry(ApplyingType, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvAppliesToDoc()
    begin
        ApplyAppliesToDoc("Gen. Journal Document Type"::Payment, "Gen. Journal Document Type"::Invoice, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyCMAppliesToDoc()
    begin
        ApplyAppliesToID("Gen. Journal Document Type"::Refund, "Gen. Journal Document Type"::"Credit Memo", -LibraryRandom.RandDec(100, 2));
    end;

    [Normal]
    local procedure ApplyAppliesToDoc(ApplyingType: Enum "Gen. Journal Document Type"; AppliesToType: Enum "Gen. Journal Document Type"; ApplicationAmount: Decimal)
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Application using Applies to Document No. and verify Customer Ledger Entry post application.

        // Setup: Setup Data for Apply Customer Ledger Entries.
        // Create and Post General Journal Line for Invoice.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        LibraryERM.SelectLastGenJnBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // Use LibraryRandom to select Random Amount.
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, AppliesToType, Customer."No.", ApplicationAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Create General Journal Line for Payment.
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, ApplyingType, GenJournalLine."Account No.", -GenJournalLine.Amount);

        // Exercise: Execute Application of Payment Entry to Invoice using Applies to Document No.
        // Post General Journal Line.
        ApplyCustLedEntryAppliesToDoc(GenJournalLine, CustLedgerEntry, AppliesToType);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verification: Verify Customer Ledger Entry.
        VerifyCustLedEntry(ApplyingType, GenJournalLine."Document No.");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM BAT Test for Application");
        // Setup demo data.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM BAT Test for Application");
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM BAT Test for Application");
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
    end;

    [Normal]
    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        // Apply Customer Entries.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        CustLedgerEntry2.Reset();
        CustLedgerEntry2.SetRange("Document No.", DocumentNo);
        CustLedgerEntry2.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;

        // Set Applies-to ID.
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure ApplyCustLedEntryAppliesToID(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        // Apply Customer Entries.
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.Validate("Applies-to ID", GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount");
        CustLedgerEntry.Modify(true);
        GenJournalLine.Validate(Amount, -CustLedgerEntry."Amount to Apply");
        GenJournalLine.Validate("Applies-to ID", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure ApplyCustLedEntryAppliesToDoc(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; ApplietoDocType: Enum "Gen. Journal Document Type")
    begin
        // Apply Customer Entries.
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetRange("Document Type", ApplietoDocType);
        CustLedgerEntry.FindFirst();
        GenJournalLine.Validate("Applies-to Doc. Type", ApplietoDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyCustLedEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);

        // Verify Applied Payment Entry .
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Remaining Amount", 0);
    end;
}

