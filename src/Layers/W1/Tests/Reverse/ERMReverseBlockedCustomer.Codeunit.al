codeunit 134138 "ERM Reverse Blocked Customer"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Blocked] [Customer]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceWithShipBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Invoice with Random Amount, Block Customer with Ship and Reverse posted entry.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::Invoice, Customer.Blocked::Ship, LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentWithInvoiceBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Payment with Random Amount, Block Customer with Invoice and Reverse posted entry.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::Payment, Customer.Blocked::Invoice, -LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentWithShipBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Payment with Random Amount, Block Customer with Ship and Reverse posted entries.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::Payment, Customer.Blocked::Ship, -LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoWithInvoiceBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Credit Memo with Random Amount, Block Customer with Invoice and Reverse posted entry.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::"Credit Memo", Customer.Blocked::Invoice, -LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoWithShipBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Credit Memo with Random Amount, Block Customer with Ship and Reverse posted entry.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::"Credit Memo", Customer.Blocked::Ship, -LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FinChargeMemoInvoiceBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Fin. Charge Memo with Random Amount, Block Customer with Invoice, Reverse posted entry.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::"Finance Charge Memo", Customer.Blocked::Invoice, LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FinChargeMemoShipBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Fin. Charge Memo with Random Amount, Block Customer with Ship, Reverse posted entry.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::"Finance Charge Memo", Customer.Blocked::Ship, LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReminderWithInvoiceBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Reminder with Random Amount, Block Customer with Invoice and Reverse posted entry.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::Reminder, Customer.Blocked::Invoice, LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReminderWithShipBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Reminder with Random Amount, Block Customer with Ship and Reverse posted entry.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::Reminder, Customer.Blocked::Ship, LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RefundWithInvoiceBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Refund with Random Amount, Block Customer with Invoice and Reverse posted entry.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::Refund, Customer.Blocked::Invoice, LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RefundWithShipBlocked()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Customer after Posting Refund with Random Amount, Block Customer with Ship and Reverse posted entry.
        Initialize();
        ReverseBlockedCustomerDocument(
          GenJournalLine."Document Type"::Refund, Customer.Blocked::Ship, LibraryRandom.RandDec(50, 2));
    end;

    local procedure ReverseBlockedCustomerDocument(DocumentType: Enum "Gen. Journal Document Type"; BlockedType: Enum "Customer Blocked"; Amount: Decimal)
    var
        Customer: Record Customer;
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Setup: Create a Customer. Create and Post General Journal Line. Change Value of Blocked field as per the option for Customer.
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostGenJournalLine(Customer."No.", DocumentType, Amount);
        BlockCustomerByOption(Customer, BlockedType);

        // Exercise: Reverse the posted Transaction and clear Customer Blocked field after Reversing Entries.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");
        BlockCustomerByOption(Customer, Customer.Blocked::" ");

        // Verify: Verify that Balance is Zero for the Customer after Reversing the posted entry.
        Customer.CalcFields(Balance);
        Customer.TestField(Balance, 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reverse Blocked Customer");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reverse Blocked Customer");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reverse Blocked Customer");
    end;

    local procedure CreateAndPostGenJournalLine(CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure BlockCustomerByOption(var Customer: Record Customer; Blocked: Enum "Customer Blocked")
    begin
        // Modify value of Blocked field for Customer as per Option selected.
        Customer.Validate(Blocked, Blocked);
        Customer.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm Handler.
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

