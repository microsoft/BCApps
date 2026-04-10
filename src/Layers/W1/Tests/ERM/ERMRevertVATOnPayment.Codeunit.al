codeunit 134917 "ERM Revert VAT On Payment"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Discount] [FCY]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2 in \\%3 %4=%5.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Revert VAT On Payment");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Revert VAT On Payment");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateAccountInVendorPostingGroups();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Revert VAT On Payment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiscountWithCurrencyOfCustomer()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        Amount: Decimal;
        AmountLCY: Decimal;
        AmountToApply: Decimal;
        DocumentNo: Code[20];
    begin
        // Test invoice in foreign currency for Customer that allow payment discount.

        // 1. Setup: Create Payment Terms and Currency. Create and post General Journal Line.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        CreatePaymentTerms(PaymentTerms);

        // Create Customer with Currency and Payment Terms.
        CustomerWithCurrency(Customer, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(100, 2);
        AmountLCY := LibraryERM.ConvertCurrency(Amount, Customer."Currency Code", '', WorkDate());
        AmountToApply := Amount * (1 - (GetPaymentTermsDiscountPercentage(PaymentTerms) / 100));

        CreateGeneralJournalBatch(GenJournalBatch);
        // Apply refund to Credit Memo With random values.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer, Customer."No.", -Amount);
        UpdateGeneralJournalLine(GenJournalLine);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer, Customer."No.", AmountToApply);
        UpdateGeneralJournalLine(GenJournalLine);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Apply and post customer entry.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Refund, GenJournalLine."Document No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry2, CustLedgerEntry2."Document Type"::"Credit Memo", DocumentNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

        // 3. Verify: Verify Customer Ledger Entry for Amount and Amount LCY.
        VerifyCustomerLedgerEntry(Customer."No.", DocumentNo, -Amount, -AmountLCY);
        VerifyCustomerLedgerEntry(Customer."No.", GenJournalLine."Document No.", Amount, AmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiscountWithCurrencyOfVendor()
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
        Amount: Decimal;
        AmountLCY: Decimal;
        AmountToApply: Decimal;
        DocumentNo: Code[20];
    begin
        // Test invoice in foreign currency for Vendor that allow payment discount.

        // 1. Setup: Create Payment Terms and Currency. Create and post General Journal Line.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        CreatePaymentTerms(PaymentTerms);

        // Create Vendor with Currency and Payment Terms.
        VendorWithCurrency(Vendor, PaymentTerms.Code);
        Amount := LibraryRandom.RandDec(100, 2);
        AmountLCY := LibraryERM.ConvertCurrency(Amount, Vendor."Currency Code", '', WorkDate());
        AmountToApply := Amount * (1 - (GetPaymentTermsDiscountPercentage(PaymentTerms) / 100));

        CreateGeneralJournalBatch(GenJournalBatch);
        // Apply refund to Credit Memo With random values.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor, Vendor."No.", Amount);
        UpdateGeneralJournalLine(GenJournalLine);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Vendor, Vendor."No.", -AmountToApply);
        UpdateGeneralJournalLine(GenJournalLine);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Apply and post vendor entry.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Refund, GenJournalLine."Document No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry2, VendorLedgerEntry2."Document Type"::"Credit Memo", DocumentNo);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);

        // 3. Verify: Verify Vendor Ledger Entry for Amount and Amount LCY.
        VerifyVendorLedgerEntry(Vendor."No.", DocumentNo, Amount, AmountLCY);
        VerifyVendorLedgerEntry(Vendor."No.", GenJournalLine."Document No.", -Amount, -AmountLCY);
    end;

    local procedure CustomerWithCurrency(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Validate("Currency Code", CurrencyWithExchangeRate());
        Customer.Modify(true);
    end;

    local procedure VendorWithCurrency(var Vendor: Record Vendor; PaymentTermsCode: Code[10])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Validate("Currency Code", CurrencyWithExchangeRate());
        Vendor.Modify(true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", Currency."Residual Gains Account");
        Currency.Validate("Realized G/L Gains Account", GLAccount."No.");
        Currency.Validate("Realized G/L Losses Account", Currency."Realized G/L Gains Account");
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CurrencyWithExchangeRate(): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Create new exchange rates with random values.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CreateCurrency(), WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100 * LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 2 * CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);

        // Create General Journal Batch.
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePaymentTerms(var PaymentTerms: Record "Payment Terms")
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
    end;

    local procedure UpdateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        // Validating Document No as Journal Batch Name and Line No because value is not important.
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure VerifyCustomerLedgerEntry(CustomerNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal; AmountLCY: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        Assert.AreNearlyEqual(
          Amount, CustLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            AmountError, CustLedgerEntry.FieldCaption(Amount), AmountLCY, CustLedgerEntry.TableCaption(),
            CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
        Assert.AreNearlyEqual(
          AmountLCY, CustLedgerEntry."Amount (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            AmountError, CustLedgerEntry.FieldCaption("Amount (LCY)"), AmountLCY, CustLedgerEntry.TableCaption(),
            CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal; AmountLCY: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount, "Amount (LCY)");
        Assert.AreNearlyEqual(
          Amount, VendorLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            AmountError, VendorLedgerEntry.FieldCaption(Amount), AmountLCY, VendorLedgerEntry.TableCaption(),
            VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
        Assert.AreNearlyEqual(
          AmountLCY, VendorLedgerEntry."Amount (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            AmountError, VendorLedgerEntry.FieldCaption("Amount (LCY)"), AmountLCY, VendorLedgerEntry.TableCaption(),
            VendorLedgerEntry.FieldCaption("Entry No."), VendorLedgerEntry."Entry No."));
    end;

    local procedure GetPaymentTermsDiscountPercentage(PaymentTerms: Record "Payment Terms"): Decimal
    begin
        exit(LibraryERM.GetPaymentTermsDiscountPct(PaymentTerms));
    end;
}

