codeunit 134139 "ERM Reverse Blocked Vendor"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Reverse] [Blocked] [Vendor]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Vendor after Posting Invoice with Random Amount, Reverse posted entry.
        Initialize();
        ReverseBlockedVendorDocument(GenJournalLine."Document Type"::Invoice, -LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseCreditMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Vendor after Posting Credit Memo with Random Amount, Reverse posted entry.
        Initialize();
        ReverseBlockedVendorDocument(GenJournalLine."Document Type"::"Credit Memo", LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseFinanceChargeMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Vendor after Posting Finance Charge Memo with Random Amount, Reverse posted entry.
        Initialize();
        ReverseBlockedVendorDocument(GenJournalLine."Document Type"::"Finance Charge Memo", -LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseReminder()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Vendor after Posting Reminder with Random Amount, Reverse posted entry.
        Initialize();
        ReverseBlockedVendorDocument(GenJournalLine."Document Type"::Reminder, -LibraryRandom.RandDec(50, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Balance of Vendor after Posting Refund with Random Amount, Reverse posted entry.
        Initialize();
        ReverseBlockedVendorDocument(GenJournalLine."Document Type"::Refund, -LibraryRandom.RandDec(50, 2));
    end;

    local procedure ReverseBlockedVendorDocument(DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GLRegister: Record "G/L Register";
        ReversalEntry: Record "Reversal Entry";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        // Setup: Create a Vendor. Create and Post General Journal Line. Block Vendor for Payment.
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostGenJournalLine(Vendor."No.", DocumentType, Amount);
        BlockVendorByOption(Vendor, Vendor.Blocked::Payment);

        // Exercise: Reverse the posted entries and clear Vendor Blocked field.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");
        BlockVendorByOption(Vendor, Vendor.Blocked::" ");

        // Verify: Verify that Balance is Zero for the Vendor after Reversing the posted entries.
        Vendor.CalcFields(Balance);
        Vendor.TestField(Balance, 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reverse Blocked Vendor");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reverse Blocked Vendor");

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reverse Blocked Vendor");
    end;

    local procedure CreateAndPostGenJournalLine(VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure BlockVendorByOption(var Vendor: Record Vendor; Blocked: Enum "Vendor Blocked")
    begin
        // Modify value of Blocked field for Vendor as per Option selected.
        Vendor.Validate(Blocked, Blocked);
        Vendor.Modify(true);
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

