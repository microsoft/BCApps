codeunit 144008 "UT TAB CURRENCY"
{
    // Unit Test Cases for CURRENCY Feature in Table.
    // 
    // 1. Purpose of this test is to verify error on delete Currency used in Open Customer Ledger Entry.
    // 
    // Covers Test Cases for WI - 340237
    // --------------------------------------------------------
    // Test Function Name                               TFS ID
    // --------------------------------------------------------
    // OnDeleteCurrencyError                            159614

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteCurrencyError()
    var
        Currency: Record Currency;
    begin
        // Purpose of this test is to verify error on delete Currency used in Open Customer Ledger Entry.

        // Setup.
        Currency.Get(CreateCustomerLedgerEntry());

        // Exercise.
        asserterror Currency.Delete(true);

        // Verify:  Verify Actual Error - "There is one or more opened entries in the Cust. Ledger Entry table using Currency".
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateCustomerLedgerEntry(): Code[10]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry."Entry No." := LibraryRandom.RandInt(5);  // Use random value.
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Document No." := LibraryUTUtility.GetNewCode();
        CustLedgerEntry."Currency Code" := CreateCurrency();
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Currency Code");
    end;
}

