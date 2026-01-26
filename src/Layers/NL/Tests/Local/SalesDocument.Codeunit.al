codeunit 144542 "Sales Document"
{
    // 1. Test Foreign Amount on Proposal Line after running Get Proposal Entries Report when Sales Invoice Posted with Currency.
    // 2. Test Foreign Amount on Proposal Line after running Get Proposal Entries Report when Sales Invoice Posted without Currency.
    // 
    // Covers Test Cases for Bug Id: 333284
    //  ---------------------------------------------------------------------------------------------
    //  Test Function Name                                                                 TFS ID
    //  ---------------------------------------------------------------------------------------------
    // RunGetProposalEntriesReportWithCurrency,RunGetProposalEntriesReportWithoutCurrency   330140

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Sales Document");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Sales Document");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Sales Document");
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunGetProposalEntriesReportWithCurrency()
    var
        SalesHeader: Record "Sales Header";
        SalesLineAmount: Decimal;
    begin
        Initialize();
        // Test Foreign Amount on Proposal Line after running Get Proposal Entries Report when Sales Invoice Posted with Currency.

        // Setup: Create and post Sales Invoice with Bank Account Code and Currency.
        SalesLineAmount := CreateAndPostSalesInvoice(SalesHeader, CreateCustomerWithCurrency(CreateCurrencyWithRandomExchangeRate()));

        // Exercise: Run Get Proposal Entries Report.
        REPORT.Run(REPORT::"Get Proposal Entries");

        // Verify: Verify Foreign Amount and Currency on  Proposal Line.
        VerifyForeignCurrencyAndAmountOnProposalLine(SalesHeader, -1 * SalesLineAmount);
    end;

    [Test]
    [HandlerFunctions('GetProposalEntriesRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RunGetProposalEntriesReportWithoutCurrency()
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();
        // Test Foreign Amount on Proposal Line after running Get Proposal Entries Report when Sales Invoice Posted without Currency.

        // Setup: Create and post Sales Invoice with Bank Account Code.
        CreateAndPostSalesInvoice(SalesHeader, CreateCustomerWithCurrency(''));

        // Exercise: Run Get Proposal Entries Report.
        REPORT.Run(REPORT::"Get Proposal Entries");

        // Verify: Verify Foreign Amount and Currency on  Proposal Line.
        VerifyForeignCurrencyAndAmountOnProposalLine(SalesHeader, 0);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesLine."Line Amount");
    end;

    local procedure CreateCustomerWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        TransactionMode: Record "Transaction Mode";
    begin
        LibrarySales.CreateCustomer(Customer);
        TransactionMode.FindFirst();
        Customer.Validate("Transaction Mode Code", TransactionMode.Code);
        Customer.Validate("Preferred Bank Account Code", CreateCustomerBankAccount(Customer."No."));
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBankAccount(CustomerNo: Code[20]): Code[10]
    var
        CustomerBankAccount: Record "Customer Bank Account";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        CustomerBankAccount.Init();
        CustomerBankAccount.Validate(
          Code, LibraryUtility.GenerateRandomCode(CustomerBankAccount.FieldNo(Code), DATABASE::"Customer Bank Account"));
        CustomerBankAccount.Validate("Customer No.", CustomerNo);
        CustomerBankAccount.Insert(true);
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateCurrencyWithRandomExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Invoice Rounding Precision", LibraryERM.GetAmountRoundingPrecision());
        Currency.Modify(true);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure VerifyForeignCurrencyAndAmountOnProposalLine(SalesHeader: Record "Sales Header"; ForeignAmount: Decimal)
    var
        ProposalLine: Record "Proposal Line";
    begin
        ProposalLine.SetRange(Bank, SalesHeader."Bank Account Code");
        ProposalLine.SetRange("Account Type", ProposalLine."Account Type"::Customer);
        ProposalLine.SetRange("Account No.", SalesHeader."Sell-to Customer No.");
        ProposalLine.FindFirst();
        ProposalLine.TestField("Foreign Currency", SalesHeader."Currency Code");
        ProposalLine.TestField("Foreign Amount", ForeignAmount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GetProposalEntriesRequestPageHandler(var GetProposalEntries: TestRequestPage "Get Proposal Entries")
    begin
        GetProposalEntries.CurrencyDate.SetValue(CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(5)), WorkDate()));
        GetProposalEntries.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy Message Handler.
    end;
}

