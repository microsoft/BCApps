codeunit 134075 "ERM Change Exchange Rate"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Currency Factor] [General Journal]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be calculated correctly on %2.';

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyFactorOnGenJournalLine()
    begin
        // Covers Document TFS_TC_ID = 8866, 8867, 11723, 8870, 8878, 8879, 8882, 8883.

        // Test to Create Currency and Verify the Currency Factor on General Journal Line.
        CurrencyFactorAndAmountLCY(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateLCYOnGenJournalLine()
    begin
        // Covers Document TFS_TC_ID = 8866, 8867, 11723, 8869, 8870, 8878, 8879, 8881, 8882, 8883.

        // Test to Create Currency and Verify the AmountLCY on General Journal Line after changing Relational Currency's Exchange Rates.
        CurrencyFactorAndAmountLCY(true);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Change Exchange Rate");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Change Exchange Rate");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Change Exchange Rate");
    end;

    local procedure CurrencyFactorAndAmountLCY(UpdateExchangeRate: Boolean)
    var
        Customer: Record Customer;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        RelationalCurrencyCode: Code[10];
    begin
        // Setup: Create a Customer and attach a newly created Currency on it. Create another Currency and attach it on previous Currency
        // as Relational Currency.
        Initialize();
        CreateCustomer(Customer);
        RelationalCurrencyCode := UpdateRelationalCurrency(Customer."Currency Code");

        // Exercise: Create General Journal Line. Update the Exchange Rates, Update the Currency Factor on Journal Line.
        CreateGeneralJournalLine(TempGenJournalLine, Customer."No.");
        if UpdateExchangeRate then begin
            UpdateRelationalExchangeRate(RelationalCurrencyCode);
            TempGenJournalLine.Validate("Currency Factor", CalculateCurrencyFactor(Customer."Currency Code"));
            TempGenJournalLine.Modify(true);
        end;

        // Verify: Verify Currency Factor and Amount (LCY) on Journal Line as per the option selected.
        if UpdateExchangeRate then
            VerifyAmountLCY(TempGenJournalLine)
        else
            Assert.AreEqual(CalculateCurrencyFactor(Customer."Currency Code"), TempGenJournalLine."Currency Factor",
              StrSubstNo(AmountError, TempGenJournalLine.FieldCaption("Currency Factor"), TempGenJournalLine.TableCaption()));
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Create a New Customer, Create and update a new Currency on it.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        Customer.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var TempGenJournalLine: Record "Gen. Journal Line" temporary; CustomerNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // Create Journal Lines of Payment Type using the selected Journal Batch, Customer with a Random Amount.
        LibraryERM.CreateGeneralJnlLine(
          TempGenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, TempGenJournalLine."Document Type"::Payment,
          TempGenJournalLine."Account Type"::Customer, CustomerNo, LibraryRandom.RandInt(100));
    end;

    local procedure UpdateRelationalCurrency(CurrencyCode: Code[10]): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Create a Relational Currency for Currency and update Fix Exchange Rate Amount field.
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyExchangeRate.Validate("Relational Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        CurrencyExchangeRate.Validate("Fix Exchange Rate Amount", CurrencyExchangeRate."Fix Exchange Rate Amount"::Both);
        CurrencyExchangeRate.Modify(true);
        exit(CurrencyExchangeRate."Relational Currency Code");
    end;

    local procedure UpdateRelationalExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();

        // Update the Exchange Rates by subtracting a Random Decimal Amount from the Old Exchange Rates.
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" - LibraryRandom.RandDec(1, 2));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CalculateCurrencyFactor(CurrencyCode: Code[10]) CurrencyFactor: Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        CurrencyFactor := CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount";

        CurrencyExchangeRate.SetRange("Currency Code", CurrencyExchangeRate."Relational Currency Code");
        CurrencyExchangeRate.FindFirst();
        CurrencyFactor :=
          CurrencyFactor * CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount";
        exit(CurrencyFactor);
    end;

    local procedure VerifyAmountLCY(TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        AmountLCY: Decimal;
    begin
        Currency.Get(TempGenJournalLine."Currency Code");
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();
        AmountLCY :=
          (TempGenJournalLine.Amount / CurrencyExchangeRate."Exchange Rate Amount") *
          CurrencyExchangeRate."Relational Exch. Rate Amount";

        CurrencyExchangeRate.SetRange("Currency Code", CurrencyExchangeRate."Relational Currency Code");
        CurrencyExchangeRate.FindFirst();
        AmountLCY := (AmountLCY / CurrencyExchangeRate."Exchange Rate Amount") * CurrencyExchangeRate."Relational Exch. Rate Amount";
        Assert.AreNearlyEqual(
          AmountLCY, TempGenJournalLine."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, TempGenJournalLine.FieldCaption("Amount (LCY)"), TempGenJournalLine.TableCaption()));
    end;
}

