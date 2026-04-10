codeunit 134888 "ERM Application Employee"
{


    Permissions = TableData "Employee Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryERMEmployeeWatch: Codeunit "Library - ERM Employee Watch";
        LibraryRandom: Codeunit "Library - Random";
        LibraryrHR: Codeunit "Library - Human Resource";
        isInitialized: Boolean;
        EmployeeAmount: Decimal;
        WrongBalancePerTransNoErr: Label 'Wrong total amount of detailed entries per transaction.';


    [Test]
    [Scope('OnPrem')]
    procedure EmployeeCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            EmployeeInvPmtCorrection(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::" ", EmployeeAmount, Stepwise);
            EmployeeInvPmtCorrection(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::" ", -EmployeeAmount, Stepwise);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeRealizedGain()
    var
        DtldEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            EmployeeRealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::" ", EmployeeAmount, Stepwise,
              0.9, DtldEmployeeLedgEntry."Entry Type"::"Realized Gain");
            EmployeeRealizedAdjust(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::" ", -EmployeeAmount, Stepwise,
              1.1, DtldEmployeeLedgEntry."Entry Type"::"Realized Gain");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeRealizedLoss()
    var
        DtldEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            EmployeeRealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::" ", EmployeeAmount, Stepwise,
              1.1, DtldEmployeeLedgEntry."Entry Type"::"Realized Loss");
            EmployeeRealizedAdjust(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::" ", -EmployeeAmount, Stepwise,
              0.9, DtldEmployeeLedgEntry."Entry Type"::"Realized Loss");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeUnrealizedGain()
    var
        DtldEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            EmployeeUnrealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::" ", EmployeeAmount, Stepwise,
              0.9, DtldEmployeeLedgEntry."Entry Type"::"Realized Gain");
            EmployeeUnrealizedAdjust(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::" ", -EmployeeAmount, Stepwise,
              1.1, DtldEmployeeLedgEntry."Entry Type"::"Realized Gain");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeUnrealizedLoss()
    var
        DtldEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            EmployeeUnrealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::" ", EmployeeAmount, Stepwise,
              1.1, DtldEmployeeLedgEntry."Entry Type"::"Realized Loss");
            EmployeeUnrealizedAdjust(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::" ", -EmployeeAmount, Stepwise,
              0.9, DtldEmployeeLedgEntry."Entry Type"::"Realized Loss");
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FutureCurrAdjTransaction()
    var
        Employee: Record Employee;
        EmployeePostingGroup: Record "Employee Posting Group";
        DtldEmplLedgEntry: Record "Detailed Employee Ledger Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        LastTransactionNo: array[2] of Integer;
        TransactionNo: Integer;
        i: Integer;
        TotalAmount: Decimal;
        InvAmount: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates] [Transaction No.]
        // [SCENARIO] Currency Adjustment job posts Detailed Employee Ledger Entries linked by "Transaction No." with related G/L Entries
        Initialize();

        // [GIVEN] Currency "FCY" with different rates on Workdate and on (WorkDate() + 1)
        CurrencyCode := SetExchRateForCurrency(2);

        LibraryrHR.CreateEmployee(Employee);

        GetGLBalancedBatch(GenJournalBatch);
        for i := 1 to 3 do begin
            // [GIVEN] Post Invoice in "FCY" on WorkDate
            InvAmount := LibraryRandom.RandDec(1000, 2);
            DocumentNo := CreateJournalLine(
                GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee,
                Employee."No.", -InvAmount, '<0D>', CurrencyCode, LibraryUtility.GenerateGUID(), '');
            RunGenJnlPostLine(GenJournalLine);
            // [GIVEN] Post 1st partial Payment in "FCY" on WorkDate with application to Invoice
            CreateJournalLine(
              GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Employee,
              Employee."No.", InvAmount / (i + 1), '<0D>', CurrencyCode, LibraryUtility.GenerateGUID(), '');
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::" ");
            GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
            GenJournalLine.Modify();
            RunGenJnlPostLine(GenJournalLine);
            // [GIVEN] Post 2nd partial Payment in "FCY" on (WorkDate() + 2) with application to Invoice
            CreateJournalLine(
              GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Employee,
              Employee."No.", InvAmount - GenJournalLine.Amount, '<2D>', CurrencyCode, LibraryUtility.GenerateGUID(), '');
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::" ");
            GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
            GenJournalLine.Modify();
            RunGenJnlPostLine(GenJournalLine);
        end;

        LastTransactionNo[1] := GetLastTransactionNo();

        // [WHEN] Run the Adjust Exchange Rates Batch job on (WorkDate() + 1)
        LibraryERM.RunExchRateAdjustmentSimple(
          CurrencyCode, CalcDate('<1D>', WorkDate()), CalcDate('<1D>', WorkDate()));

        // [THEN] posted G/L Entries on different dates have different "Transaction No."
        // [THEN] Dtld. Employee Ledger Entries have same "Transaction No." with related G/L Entries
        LastTransactionNo[2] := GetLastTransactionNo();
        EmployeePostingGroup.Get(Employee."Employee Posting Group");
        for TransactionNo := LastTransactionNo[1] + 1 to LastTransactionNo[2] do begin
            GLEntry.SetRange("Transaction No.", TransactionNo);
            GLEntry.SetRange("G/L Account No.", EmployeePostingGroup."Payables Account");
            GLEntry.FindLast();
            TotalAmount := 0;
            DtldEmplLedgEntry.SetRange("Transaction No.", TransactionNo);
            DtldEmplLedgEntry.FindSet();
            repeat
                TotalAmount += DtldEmplLedgEntry."Amount (LCY)";
            until DtldEmplLedgEntry.Next() = 0;
            Assert.AreEqual(GLEntry.Amount, TotalAmount, WrongBalancePerTransNoErr);
        end;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        UpdateEmployeePostingGroup();

        EmployeeAmount := 1000;  // Use a fixed amount to avoid rounding issues.
        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure EmployeeRealizedAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean; CurrencyAdjustFactor: Decimal; DtldLedgerType: Enum "Detailed CV Ledger Entry Type")
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
        Employee: Record Employee;
        Desc: Text[30];
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalBatch);
        CreateEmployee(Employee);

        // Find currency code with realized gaisn/losses account
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        // Create new exchange rate
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();

        // Watch for Realized gain/loss dtld. ledger entries
        LibraryERMEmployeeWatch.Init();
        LibraryERMEmployeeWatch.DtldEntriesEqual(Employee."No.", DtldLedgerType, 0);

        // Generate a document that triggers application dtld. ledger entries.
        InvAmount := Amount;
        PmtAmount := LibraryERM.ConvertCurrency(InvAmount, Currency.Code, '', WorkDate()) * CurrencyAdjustFactor;

        Desc := GenerateDocument(GenJournalBatch, Employee, PmtType, InvType, PmtAmount, InvAmount, '<0D>', '', Currency.Code);

        // Adjust the currency exchange rate of the document currency to trigger realized gain/loss
        CurrencyExchangeRate."Relational Exch. Rate Amount" *= CurrencyAdjustFactor;
        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" *= CurrencyAdjustFactor;
        CurrencyExchangeRate.Modify(true);

        EmployeeApplyUnapply(Desc, Stepwise);

        LibraryERMEmployeeWatch.AssertEmployee();
    end;

    local procedure EmployeeUnrealizedAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean; CurrencyAdjustFactor: Decimal; DtldLedgerType: Enum "Detailed CV Ledger Entry Type")
    var
        Currency: Record Currency;
        GenJournalBatch: Record "Gen. Journal Batch";
        Employee: Record Employee;
        Desc: Text[30];
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalBatch);
        CreateEmployee(Employee);

        Currency.Get(SetExchRateForCurrency(CurrencyAdjustFactor));

        // Watch for Realized gain/loss dtld. ledger entries
        LibraryERMEmployeeWatch.Init();
        LibraryERMEmployeeWatch.DtldEntriesEqual(Employee."No.", DtldLedgerType, 0);

        // Generate a document that triggers application dtld. ledger entries.
        InvAmount := Amount;
        PmtAmount := LibraryERM.ConvertCurrency(InvAmount, Currency.Code, '', WorkDate()) * CurrencyAdjustFactor;

        Desc := GenerateDocument(GenJournalBatch, Employee, PmtType, InvType, PmtAmount, InvAmount, '<1D>', '', Currency.Code);

        // Run the Adjust Exchange Rates Batch job.
        LibraryERM.RunExchRateAdjustmentSimple(
            Currency.Code, CalcDate('<1D>', WorkDate()), CalcDate('<1D>', WorkDate()));

        EmployeeApplyUnapply(Desc, Stepwise);

        LibraryERMEmployeeWatch.AssertEmployee();
    end;

    local procedure EmployeeInvPmtCorrection(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Employee: Record Employee;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DtldEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        Desc: Text[30];
    begin
        // Test with payment discount
        GetGLBalancedBatch(GenJournalBatch);
        CreateEmployee(Employee);

        // Create a currency code with magic exchange rate valid for Amount = 1000
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 64.580459);  // Magic exchange rate
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);

        // Watch for "Correction of Remaining Amount" detailed ledger entries.
        LibraryERMEmployeeWatch.Init();
        LibraryERMEmployeeWatch.DtldEntriesGreaterThan(Employee."No.", DtldEmployeeLedgEntry."Entry Type"::"Correction of Remaining Amount", 0);

        // Generate a document that triggers "Correction of Remaining Amount" dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Employee, PmtType, InvType, Amount, Amount, '<0D>', Currency.Code, Currency.Code);
        EmployeeApplyUnapply(Desc, Stepwise);

        LibraryERMEmployeeWatch.AssertEmployee();
    end;

    local procedure EmployeeApplyUnapply(Desc: Text[30]; Stepwise: Boolean)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange(Description, Desc);
        Assert.AreEqual(EmployeeLedgerEntry.Count, 4, 'Expected to find exactly 4 Employee ledger entries!');

        // Exercise #1. Apply entries.
        PostEmployeeApplication(EmployeeLedgerEntry, Stepwise);

        // Verify #1.
        VerifyEmployeeEntriesClosed(EmployeeLedgerEntry);

        // Exercise #2. Unapply entries.
        PostEmployeeUnapply(EmployeeLedgerEntry, Stepwise);

        // Verify #2.
        VerifyEmployeeEntriesOpen(EmployeeLedgerEntry);

        // Exercise #3. Apply entries.
        PostEmployeeApplication(EmployeeLedgerEntry, Stepwise);

        // Verify #3.
        VerifyEmployeeEntriesClosed(EmployeeLedgerEntry);
    end;

    local procedure GenerateDocument(GenJournalBatch: Record "Gen. Journal Batch"; Employee: Record Employee; PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; PmtAmount: Decimal; InvAmount: Decimal; PmtOffset: Text[30]; PmtCurrencyCode: Code[10]; InvCurrencyCode: Code[10]): Text[30]
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        Desc: Text[30];
    begin
        ClearJournalBatch(GenJournalBatch);
        // Create four documents with seperate document no. and external document no. but with unique description.
        DocumentNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, PmtType, GenJournalLine."Account Type"::Employee,
            Employee."No.", PmtAmount / 4, PmtOffset, PmtCurrencyCode, DocumentNo, '');
        Desc := DocumentNo;
        DocumentNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, PmtType, GenJournalLine."Account Type"::Employee,
            Employee."No.", PmtAmount / 4, PmtOffset, PmtCurrencyCode, IncStr(DocumentNo), Desc);
        DocumentNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, PmtType, GenJournalLine."Account Type"::Employee,
            Employee."No.", PmtAmount / 2, PmtOffset, PmtCurrencyCode, IncStr(DocumentNo), Desc);
        DocumentNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, InvType, GenJournalLine."Account Type"::Employee,
            Employee."No.", -InvAmount, '<0D>', InvCurrencyCode, IncStr(DocumentNo), Desc);

        PostJournalBatch(GenJournalBatch);
        exit(Desc);
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; PmtOffset: Text[30]; CurrencyCode: Code[10]; DocNo: Code[20]; Description: Text[30]): Code[20]
    var
        DateOffset: DateFormula;
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          DocumentType,
          AccountType,
          AccountNo,
          Amount);

        Evaluate(DateOffset, PmtOffset);

        // Update journal line currency
        GenJournalLine.Validate("Posting Date", CalcDate(DateOffset, WorkDate()));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Description, GenJournalLine."Document No.");

        // Update document number and description if specified
        if DocNo <> '' then
            GenJournalLine."Document No." := DocNo;
        if Description <> '' then
            GenJournalLine.Description := Description;

        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);

        exit(GenJournalLine."Document No.");
    end;

    local procedure ClearJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll();
    end;

    local procedure PostJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostEmployeeApplication(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; Stepwise: Boolean)
    begin
        if Stepwise then
            PostEmployeeApplicationStepwise(EmployeeLedgerEntry)
        else
            PostEmployeeApplicationOneGo(EmployeeLedgerEntry);
    end;

    local procedure PostEmployeeApplicationOneGo(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        // The first entry is the applying entry.
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields(Amount);
        LibraryERM.SetApplyEmployeeEntry(EmployeeLedgerEntry, EmployeeLedgerEntry.Amount);

        // Apply to all other entries.
        LibraryERM.SetAppliestoIdEmployee(EmployeeLedgerEntry);

        // Call Apply codeunit.
        EmployeeLedgerEntry.FindFirst();
        LibraryERM.PostEmplLedgerApplication(EmployeeLedgerEntry);
    end;

    local procedure PostEmployeeApplicationStepwise(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
        i: Integer;
    begin
        // The first entry is the applying entry.
        EmployeeLedgerEntry.FindLast();
        EmployeeLedgerEntry2.SetRange("Entry No.", EmployeeLedgerEntry."Entry No.");
        EmployeeLedgerEntry2.FindFirst();

        EmployeeLedgerEntry.FindFirst();
        for i := 1 to EmployeeLedgerEntry.Count - 1 do begin
            EmployeeLedgerEntry.CalcFields(Amount);
            LibraryERM.SetApplyEmployeeEntry(EmployeeLedgerEntry, EmployeeLedgerEntry.Amount);

            // Apply to last entry.
            LibraryERM.SetAppliestoIdEmployee(EmployeeLedgerEntry2);

            // Post application.
            LibraryERM.PostEmplLedgerApplication(EmployeeLedgerEntry);

            EmployeeLedgerEntry.Next();
        end;
    end;

    local procedure PostEmployeeUnapply(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; Stepwise: Boolean)
    begin
        if Stepwise then
            PostEmployeeUnapplyStepwise(EmployeeLedgerEntry)
        else
            PostEmployeeUnapplyOneGo(EmployeeLedgerEntry);
    end;

    local procedure PostEmployeeUnapplyOneGo(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        DtldEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        DtldEmployeeLedgEntry2: Record "Detailed Employee Ledger Entry";
        EmplEntryApplyPostedEntries: Codeunit "EmplEntry-Apply Posted Entries";
    begin
        DtldEmployeeLedgEntry.Get(FindLastApplEntry(EmployeeLedgerEntry."Entry No."));

        DtldEmployeeLedgEntry2.SetRange("Transaction No.", DtldEmployeeLedgEntry."Transaction No.");
        DtldEmployeeLedgEntry2.SetRange("Employee No.", DtldEmployeeLedgEntry."Employee No.");
        DtldEmployeeLedgEntry2.FindFirst();

        ApplyUnapplyParameters."Document No." := EmployeeLedgerEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := DtldEmployeeLedgEntry."Posting Date";
        EmplEntryApplyPostedEntries.PostUnApplyEmployee(DtldEmployeeLedgEntry, ApplyUnapplyParameters);
    end;

    local procedure PostEmployeeUnapplyStepwise(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        i: Integer;
    begin
        EmployeeLedgerEntry.FindLast();

        for i := 1 to EmployeeLedgerEntry.Count - 1 do begin
            // Unapply in reverse order.
            EmployeeLedgerEntry.Next(-1);
            PostEmployeeUnapplyOneGo(EmployeeLedgerEntry);
        end;
    end;

    local procedure SetExchRateForCurrency(CurrencyAdjustFactor: Decimal): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Find currency code with realized gaisn/losses account
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        // Create new exchange rates
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 100);
        CurrencyExchangeRate.Modify(true);

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, CalcDate('<1D>', WorkDate()));
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100 * CurrencyAdjustFactor);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 100 * CurrencyAdjustFactor);
        CurrencyExchangeRate.Modify(true);

        exit(Currency.Code);
    end;

    local procedure GetLastTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        exit(GLEntry."Transaction No.");
    end;

    local procedure GetGLBalancedBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        // Find template type.
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        // Find a GL balanced batch.
        GenJnlBatch.SetRange("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"G/L Account");
        GenJnlBatch.SetFilter("Journal Template Name", GenJnlTemplate.Name);
        GenJnlBatch.SetRange("Bal. Account No.");
        GenJnlBatch.FindFirst();
        GenJnlBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlBatch.Modify(true);

        ClearJournalBatch(GenJnlBatch);
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"): Integer
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;

    local procedure VerifyEmployeeEntriesClosed(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        EmployeeLedgerEntry.FindFirst();
        repeat
            Assert.IsFalse(EmployeeLedgerEntry.Open, StrSubstNo('Employee ledger entry %1 did not close.', EmployeeLedgerEntry."Entry No."));
        until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure VerifyEmployeeEntriesOpen(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        EmployeeLedgerEntry.FindFirst();
        repeat
            Assert.IsTrue(EmployeeLedgerEntry.Open, StrSubstNo('Employee ledger entry %1 did not open.', EmployeeLedgerEntry."Entry No."));
        until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure FindLastApplEntry(EmplLedgEntryNo: Integer): Integer
    var
        DtldEmployeeLedgEntry: Record "Detailed Employee Ledger Entry";
        ApplicationEntryNo: Integer;
    begin
        DtldEmployeeLedgEntry.SetCurrentKey("Employee Ledger Entry No.", "Entry Type");
        DtldEmployeeLedgEntry.SetRange("Employee Ledger Entry No.", EmplLedgEntryNo);
        DtldEmployeeLedgEntry.SetRange("Entry Type", DtldEmployeeLedgEntry."Entry Type"::Application);
        ApplicationEntryNo := 0;
        if DtldEmployeeLedgEntry.Find('-') then
            repeat
                if (DtldEmployeeLedgEntry."Entry No." > ApplicationEntryNo) and not DtldEmployeeLedgEntry.Unapplied then
                    ApplicationEntryNo := DtldEmployeeLedgEntry."Entry No.";
            until DtldEmployeeLedgEntry.Next() = 0;
        exit(ApplicationEntryNo);
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    var
        LibraryHR: Codeunit "Library - Human Resource";
    begin
        LibraryHR.CreateEmployee(Employee);
        Employee.Validate("Application Method", Employee."Application Method"::Manual);
        Employee.Modify(true);
    end;

    local procedure UpdateEmployeePostingGroup()
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        if EmployeePostingGroup.FindFirst() then
            if EmployeePostingGroup."Debit Rounding Account" = '' then begin
                EmployeePostingGroup.Validate("Debit Rounding Account", LibraryERM.CreateGLAccountNo());
                EmployeePostingGroup.Validate("Credit Rounding Account", LibraryERM.CreateGLAccountNo());
                EmployeePostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", LibraryERM.CreateGLAccountNo());
                EmployeePostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", LibraryERM.CreateGLAccountNo());
                EmployeePostingGroup.Modify();
            end;
    end;
}

