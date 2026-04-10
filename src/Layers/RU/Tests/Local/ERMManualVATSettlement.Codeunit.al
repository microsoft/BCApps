codeunit 147126 "ERM Manual VAT Settlement"
{
    // // [FEATURE] [VAT] [VAT Settlement]
    // 
    //     TEST FUNCTION NAME                    TFS ID
    // 
    // 1. PurchaseCM_IC_Settlement               325377
    // 2. SalesCM_IC_Settlement                  325402
    // 3. PurchUndeprFASettlementAllowBeforeRel  330290
    // 4. PurchUndeprFASettlement                330293
    // 5. PurchUndeprFASettlementWOutRelease     330294

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "VAT Entry" = imd,
                  tabledata "Detailed Cust. Ledg. Entry" = imd,
                  tabledata "Detailed Vendor Ledg. Entry" = imd,
                  tabledata "Cust. Ledger Entry" = imd,
                  tabledata "Vendor Ledger Entry" = imd;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        Assert: Codeunit Assert;
        VATSettlType: Option ,Purchase,Sale,FA,FPE;
        XVATSETTxt: Label 'vatset';
        XDEFAULTTxt: Label 'default';
        CVType: Option " ",Customer,Vendor;
        EntryType: Option ,Invoice,Prepayment;
        IsInitialized: Boolean;
        SuggestVATSettlNotEmptyErr: Label 'Suggested VAT Settlement line exist';
        IncorrectAcqCostErr: Label 'Acquisition Cost is incorrect';
        WrongCalcAmountErr: Label 'Calculated Amount is wrong';
        WrongValueReturnedErr: Label 'Function returned wrong value';
        MustBePositiveErr: Label 'must be positive';
        MustBeNegativeErr: Label 'must be negative';

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSelection')]
    [Scope('OnPrem')]
    procedure PurchaseCM_IC_Settlement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        Vendor: Record Vendor;
        PurchaseInvoiceNo: Code[20];
        CreditMemoNo: Code[20];
        ItemNo: array[2] of Code[20];
    begin
        // Purchase
        // Invoice(with Item Charge)/Post -> Credit Memo (copy from Invoice)/Post -> Try Manual VAT Settlement with Group VAT Allocation

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);

        CreateVendor(Vendor, VATPostingSetup);
        ItemNo[1] := CreateItem(VATPostingSetup);

        PurchaseInvoiceNo := CreatePostPurchInvIC(Vendor."No.", ItemNo, ItemCharge."No.", 1, 1);
        CreditMemoNo := CreatePostPurchCrMIC(Vendor."No.", PurchaseInvoiceNo);

        CreatePostVATAllocLine(PurchaseInvoiceNo, VATPostingSetup, VATSettlType::Purchase, WorkDate());
        CreatePostVATAllocLine(CreditMemoNo, VATPostingSetup, VATSettlType::Purchase, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSelection')]
    [Scope('OnPrem')]
    procedure PurchaseCM_IC_Settlement2Lines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        Vendor: Record Vendor;
        PurchaseInvoiceNo: Code[20];
        CreditMemoNo: Code[20];
        ItemNo: array[2] of Code[20];
    begin
        // Purchase
        // Invoice(with Item Charge)/Post -> Credit Memo (copy from Invoice)/Post -> Try Manual VAT Settlement with Group VAT Allocation

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);

        CreateVendor(Vendor, VATPostingSetup);
        ItemNo[1] := CreateItem(VATPostingSetup);

        PurchaseInvoiceNo := CreatePostPurchInvIC(Vendor."No.", ItemNo, ItemCharge."No.", 2, 1);
        CreditMemoNo := CreatePostPurchCrMIC(Vendor."No.", PurchaseInvoiceNo);

        CreatePostVATAllocLine(PurchaseInvoiceNo, VATPostingSetup, VATSettlType::Purchase, WorkDate());
        CreatePostVATAllocLine(CreditMemoNo, VATPostingSetup, VATSettlType::Purchase, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchSettlFullByPart1Line()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // Purchase Invoice/Post -> Random Number of Partial VAT Settlements
        // Last VAT Settlement for Full Manual VAT Settlement
        // Check no more line suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);
        Items[1] := CreateItem(VATPostingSetup);
        DocumentNo := CreateVendorAndPostInvoice(VATPostingSetup, PurchaseLine.Type::Item, Items, 1, 1);

        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup, VATSettlType::Purchase,
          LibraryRandom.RandIntInRange(2, 10), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchFullManualVATSettl1Line()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // Purchase Invoice/Post -> Full Manual VAT Settlement at 1 time
        // Check no more line suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);
        Items[1] := CreateItem(VATPostingSetup);
        DocumentNo := CreateVendorAndPostInvoice(VATPostingSetup, PurchaseLine.Type::Item, Items, 1, 1);

        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup, VATSettlType::Purchase, 1, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchSettlFullByPartRndLine()
    var
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // Purchase Invoice/Post -> Random Number of Partial VAT Settlements
        // Last VAT Settlement for Full Manual VAT Settlement
        // Check no more line suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup1, ItemCharge, false);
        Setup(GeneralPostingSetup, VATPostingSetup2, ItemCharge, false);

        Items[1] := CreateItem(VATPostingSetup1);
        Items[2] := CreateItem(VATPostingSetup2);
        DocumentNo := CreateVendorAndPostInvoice(
            VATPostingSetup1, PurchaseLine.Type::Item, Items, LibraryRandom.RandIntInRange(2, 20), 2);

        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup1, VATSettlType::Purchase, LibraryRandom.RandIntInRange(2, 10), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchFullManualVATSettlRndLine()
    var
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // Purchase Invoice/Post -> Full Manual VAT Settlement at 1 time
        // Check no more line suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup1, ItemCharge, false);
        Setup(GeneralPostingSetup, VATPostingSetup2, ItemCharge, false);
        Items[1] := CreateItem(VATPostingSetup1);
        Items[2] := CreateItem(VATPostingSetup2);

        DocumentNo := CreateVendorAndPostInvoice(
            VATPostingSetup1, PurchaseLine.Type::Item, Items, LibraryRandom.RandIntInRange(2, 20), 2);

        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup1, VATSettlType::Purchase, 1, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchSettlZeroVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        GenJnlLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // Purchase Invoice/Post -> 1 Line with 0% VAT
        // Check no lines suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, true);

        Items[1] := CreateItem(VATPostingSetup);
        DocumentNo := CreateVendorAndPostInvoice(VATPostingSetup, PurchaseLine.Type::Item, Items, 1, 1);

        SuggestVATSettlement(DocumentNo, VATPostingSetup, VATSettlType::Purchase, GenJnlLine, true, WorkDate());
        FilterGenJnlLine(GenJnlLine, VATPostingSetup, DocumentNo);
        Assert.IsTrue(GenJnlLine.IsEmpty, SuggestVATSettlNotEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchSettlZeroNonZeroVAT()
    var
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // Purchase Invoice/Post -> Random Number of Partial VAT Settlements
        // Last VAT Settlement for Full Manual VAT Settlement
        // Check no more line suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup1, ItemCharge, true);
        Setup(GeneralPostingSetup, VATPostingSetup2, ItemCharge, false);

        Items[1] := CreateItem(VATPostingSetup1);
        Items[2] := CreateItem(VATPostingSetup2);
        DocumentNo := CreateVendorAndPostInvoice(
            VATPostingSetup1, PurchaseLine.Type::Item, Items, LibraryRandom.RandIntInRange(2, 20), 2);

        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup1, VATSettlType::Purchase, LibraryRandom.RandIntInRange(2, 10), WorkDate());
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSelection')]
    [Scope('OnPrem')]
    procedure SalesCM_IC_Settlement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        Customer: Record Customer;
        SalesInvoiceNo: Code[20];
        CreditMemoNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // Sales
        // Invoice(with Item Charge)/Post -> Credit Memo (copy from Invoice)/Post -> Try Manual VAT Settlement with Group VAT Allocation

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);
        CreateCustomer(Customer, GeneralPostingSetup, VATPostingSetup);
        Items[1] := CreateItem(VATPostingSetup);

        SalesInvoiceNo := CreatePostSalesInvIC(Customer."No.", Items, ItemCharge."No.", 1, 1);
        CreditMemoNo := CreatePostSalesCrMIC(Customer."No.", SalesInvoiceNo);

        CreatePostVATAllocLine(SalesInvoiceNo, VATPostingSetup, VATSettlType::Sale, WorkDate());
        CreatePostVATAllocLine(CreditMemoNo, VATPostingSetup, VATSettlType::Sale, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSelection')]
    [Scope('OnPrem')]
    procedure SalesCM_IC_Settlement2Lines()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        Customer: Record Customer;
        SalesInvoiceNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // Sales
        // Invoice(with Item Charge)/Post -> Credit Memo (copy from Invoice)/Post -> Try Manual VAT Settlement with Group VAT Allocation

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);
        CreateCustomer(Customer, GeneralPostingSetup, VATPostingSetup);
        Items[1] := CreateItem(VATPostingSetup);

        SalesInvoiceNo := CreatePostSalesInvIC(Customer."No.", Items, ItemCharge."No.", 2, 1);

        CreatePostVATAllocLine(SalesInvoiceNo, VATPostingSetup, VATSettlType::Sale, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesSettlFullByPart1Line()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        Items: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // Sales Invoice/Post -> Random Number of Partial VAT Settlements
        // Last VAT Settlement for Full Manual VAT Settlement
        // Check no more line suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);
        Items[1] := CreateItem(VATPostingSetup);
        DocumentNo := CreateCustomerAndPostInvoice(GeneralPostingSetup, VATPostingSetup, Items, 1, 1);

        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup, VATSettlType::Sale, LibraryRandom.RandIntInRange(2, 20), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFullManualVATSettl1Line()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        DocumentNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // Sales Invoice/Post -> Full Manual VAT Settlement at 1 time

        // Check no more line suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);
        Items[1] := CreateItem(VATPostingSetup);
        DocumentNo := CreateCustomerAndPostInvoice(GeneralPostingSetup, VATPostingSetup, Items, 1, 1);
        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup, VATSettlType::Sale, 1, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesSettlFullByPartRandLines()
    var
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        Items: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // Sales Invoice/Post -> Random Number of Partial VAT Settlements
        // Last VAT Settlement for Full Manual VAT Settlement
        // Check no more line suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup1, ItemCharge, false);
        Setup(GeneralPostingSetup, VATPostingSetup2, ItemCharge, false);
        Items[1] := CreateItem(VATPostingSetup1);
        Items[2] := CreateItem(VATPostingSetup2);
        DocumentNo := CreateCustomerAndPostInvoice(
            GeneralPostingSetup, VATPostingSetup1, Items, LibraryRandom.RandIntInRange(2, 20), 2);

        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup1, VATSettlType::Sale, LibraryRandom.RandIntInRange(2, 10), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFullManualVATSettlRandLine()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        DocumentNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // Sales Invoice/Post -> Full Manual VAT Settlement at 1 time
        // Check no more line suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);
        Items[1] := CreateItem(VATPostingSetup);
        DocumentNo := CreateCustomerAndPostInvoice(
            GeneralPostingSetup, VATPostingSetup, Items, LibraryRandom.RandIntInRange(2, 10), 1);
        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup, VATSettlType::Sale, 1, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesSettlFullZeroVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        GenJnlLine: Record "Gen. Journal Line";
        Items: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // Sales Invoice/Post -> 1 Line with 0% VAT
        // Check no lines suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, true);
        Items[1] := CreateItem(VATPostingSetup);
        DocumentNo := CreateCustomerAndPostInvoice(GeneralPostingSetup, VATPostingSetup, Items, 1, 1);

        SuggestVATSettlement(DocumentNo, VATPostingSetup, VATSettlType::Sale, GenJnlLine, true, WorkDate());
        FilterGenJnlLine(GenJnlLine, VATPostingSetup, DocumentNo);
        Assert.IsTrue(GenJnlLine.IsEmpty, SuggestVATSettlNotEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesSettlZeroNonZeroVAT()
    var
        VATPostingSetup1: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        Items: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // Sales Invoice/Post -> Random Number of Partial VAT Settlements
        // Last VAT Settlement for Full Manual VAT Settlement
        // Check no more line suggested

        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup1, ItemCharge, true);
        Setup(GeneralPostingSetup, VATPostingSetup2, ItemCharge, false);
        Items[1] := CreateItem(VATPostingSetup1);
        Items[2] := CreateItem(VATPostingSetup2);
        DocumentNo := CreateCustomerAndPostInvoice(
            GeneralPostingSetup, VATPostingSetup1, Items, LibraryRandom.RandIntInRange(2, 20), 2);
        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup1, VATSettlType::Sale, LibraryRandom.RandIntInRange(2, 10), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUndeprFASettlementAllowBeforeRel()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // General Preparations => Create VENDOR, FA => Create & Post Purchase Invoice, Create & Release FA Release Act(Option),
        // Manual VAT Settlement with Allocation (VAT & Charge).
        // Underpreciable FA = TRUE, Allow VAT Settlement Before Release = FALSE, Create and POST FA Release = TRUE
        FAPurchRelease(true, false, true, true, VATPostingSetup, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUndeprFASettlement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // General Preparations => Create VENDOR, FA => Create & Post Purchase Invoice, Create & Release FA Release Act(Option),
        // Manual VAT Settlement with Allocation (VAT & Charge).
        // Underpreciable FA = TRUE, Allow VAT Settlement Before Release = TRUE, Create and POST FA Release = TRUE
        FAPurchRelease(true, true, true, true, VATPostingSetup, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUndeprFASettlementWOutRelease()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // General Preparations => Create VENDOR, FA => Create & Post Purchase Invoice, Create & Release FA Release Act(Option),
        // Manual VAT Settlement with Allocation (VAT & Charge).
        // Underpreciable FA = TRUE, Allow VAT Settlement Before Release = TRUE, Create and POST FA Release = FALSE
        FAPurchRelease(true, true, false, true, VATPostingSetup, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VATSettlCancelCheck()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        VATEntry: Record "VAT Entry";
        ReversalEntry: Record "Reversal Entry";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        Items: array[2] of Code[20];
    begin
        // [FEATURE] [Manual VAT Settlement]
        // [SCENARIO 363173] Reverse manual VAT entry
        Initialize();
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);
        Items[1] := CreateItem(VATPostingSetup);
        // [GIVEN] Posted Purchase Invoice
        DocumentNo := CreateVendorAndPostInvoice(VATPostingSetup, PurchaseLine.Type::Item, Items, 1, 1);
        // [GIVEN] Manual VAT Settlement
        FullVATSettlementByPart(DocumentNo, VATPostingSetup, VATSettlType::Purchase, 1, WorkDate());
        // [WHEN] Reverse manual VAT Entry
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(VATEntry."Transaction No.");
        // [THEN] VAT entry is reversed
        VerifyVATEntryManualVATSettlement(VATEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchFAFullSettlement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // General Preparations => Create VENDOR, FA => Create & Post Purchase Invoice, Create & Release FA Release Act(Option),
        // Manual VAT Settlement at one time.
        // Check no more lines suggested
        DocumentNo := FAPurchRelease(true, false, true, false, VATPostingSetup, WorkDate());

        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup, VATSettlType::FA, 1, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchFAFullSettlementByPart()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // General Preparations => Create VENDOR, FA => Create & Post Purchase Invoice, Create & Release FA Release Act(Option),
        // Manual VAT Settlement at random number of times.
        // Check no more lines suggested
        DocumentNo := FAPurchRelease(true, false, true, false, VATPostingSetup, WorkDate());

        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup, VATSettlType::FA, LibraryRandom.RandIntInRange(2, 10), WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchFASettlementReleaseNextMonth()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // General Preparations => Create VENDOR, FA => Create & Post Purchase Invoice, Create & Release FA Release Act(Option),
        // Manual VAT Settlement at one time.
        // Check no more lines suggested
        DocumentNo := FAPurchRelease(
            true, false, true, false, VATPostingSetup, CalcDate('<1M>', WorkDate()));

        SuggestVATSettlement(
          DocumentNo, VATPostingSetup, VATSettlType::Sale, GenJnlLine, true, CalcDate('<1M>', WorkDate()));
        FilterGenJnlLine(GenJnlLine, VATPostingSetup, DocumentNo);
        Assert.IsTrue(GenJnlLine.IsEmpty, SuggestVATSettlNotEmptyErr);

        FullVATSettlementByPart(
          DocumentNo, VATPostingSetup, VATSettlType::FA, 1, CalcDate('<1M>', WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementMgtCalcAmount()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DtldVendLedgEntry1: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry3: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry4: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        SumAmountLCY: Decimal;
    begin
        // UT: Check CalcAmount function calculates correct Applied Amount
        CreateGenJnlLineVendLedgEntry(GenJnlLine, VendLedgEntry);
        SumAmountLCY +=
          CreateDtldVendLedgerEntry(
            GenJnlLine, VendLedgEntry, DtldVendLedgEntry1."Entry Type"::Application,
            GenJnlLine."VAT Transaction No.", DtldVendLedgEntry1);
        SumAmountLCY +=
          CreateDtldVendLedgerEntry(
            GenJnlLine, VendLedgEntry, DtldVendLedgEntry2."Entry Type"::"Realized Loss",
            GenJnlLine."VAT Transaction No.", DtldVendLedgEntry2);
        SumAmountLCY +=
          CreateDtldVendLedgerEntry(
            GenJnlLine, VendLedgEntry, DtldVendLedgEntry3."Entry Type"::"Realized Gain",
            GenJnlLine."VAT Transaction No.", DtldVendLedgEntry3);
        CreateDtldVendLedgerEntry(
          GenJnlLine, VendLedgEntry, DtldVendLedgEntry4."Entry Type"::"Payment Discount",
          GenJnlLine."VAT Transaction No.", DtldVendLedgEntry4);
        Assert.AreEqual(SumAmountLCY, VATSettlementMgt.CalcAmount(GenJnlLine), WrongCalcAmountErr);

        VendLedgEntry.Delete();
        DtldVendLedgEntry1.Delete();
        DtldVendLedgEntry2.Delete();
        DtldVendLedgEntry3.Delete();
        DtldVendLedgEntry4.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferCVLedgerEntry()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        // UT: Check TransferVendLedgEntry/TransferCustLedgerEntry functionality
        CreateVendLedgerEntry(
          VendLedgEntry, "Gen. Journal Document Type".FromInteger(LibraryRandom.RandInt(6)), LibraryUtility.GenerateGUID(), GetNextTransactionNo());
        VendLedgEntry."Posting Date" := WorkDate();
        VendLedgEntry.Description := LibraryUtility.GenerateGUID();
        VendLedgEntry.Modify();
        VATSettlementMgt.TransferVendLedgEntry(VendLedgEntry, CVLedgerEntryBuffer);
        CheckCVLedgEntryVendor(VendLedgEntry, CVLedgerEntryBuffer);

        CreateCustLedgerEntry(
          CustLedgEntry, "Gen. Journal Document Type".FromInteger(LibraryRandom.RandInt(6)), LibraryUtility.GenerateGUID(), GetNextTransactionNo());
        CustLedgEntry."Posting Date" := WorkDate();
        CustLedgEntry.Description := LibraryUtility.GenerateGUID();
        CustLedgEntry.Modify();
        VATSettlementMgt.TransferCustLedgEntry(CustLedgEntry, CVLedgerEntryBuffer);
        CheckCVLedgEntryCustomer(CustLedgEntry, CVLedgerEntryBuffer);
        VendLedgEntry.Delete();
        CustLedgEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementMgtIsLastApplication()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DtldVendLedgEntry1: Record "Detailed Vendor Ledg. Entry";
        DtldVendLedgEntry2: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        // UT: Check IsLastApplication functionality
        CreateGenJnlLineVendLedgEntry(GenJnlLine, VendLedgEntry);
        CreateDtldVendLedgerEntry(
          GenJnlLine, VendLedgEntry, DtldVendLedgEntry1."Entry Type"::Application,
          GenJnlLine."VAT Transaction No.", DtldVendLedgEntry1);
        Assert.IsTrue(VATSettlementMgt.IsLastApplication(GenJnlLine), WrongValueReturnedErr);

        CreateDtldVendLedgerEntry(
          GenJnlLine, VendLedgEntry, DtldVendLedgEntry2."Entry Type"::Application,
          GenJnlLine."VAT Transaction No." + 1, DtldVendLedgEntry2);
        Assert.IsFalse(VATSettlementMgt.IsLastApplication(GenJnlLine), WrongValueReturnedErr);

        CreateVATEntry(VATEntry, GenJnlLine, VATEntry.Type::Purchase, 0);
        VATEntry."Transaction No." += 1;
        VATEntry.Modify();
        Assert.IsTrue(VATSettlementMgt.IsLastApplication(GenJnlLine), WrongValueReturnedErr);
        VendLedgEntry.Delete();
        VATEntry.Delete();
        DtldVendLedgEntry1.Delete();
        DtldVendLedgEntry2.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementMgtCalcUnrealVATPart()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        // UT: Check CalcUnrealVATPart calculation
        CreateGenJnlLine(GenJnlLine);
        CreateVATEntry(VATEntry, GenJnlLine, VATEntry.Type::Purchase, 0);
        VATEntry."Transaction No." += 1;
        VATEntry.Modify();
        GenJnlLine."Unrealized VAT Entry No." := VATEntry."Entry No.";
        GenJnlLine.Modify();
        Assert.AreEqual(
          GenJnlLine.Amount / VATEntry."Remaining Unrealized Amount",
          VATSettlementMgt.CalcUnrealVATPart(GenJnlLine), WrongValueReturnedErr);
        VATEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementMgtGetRemUnrealVAT()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry1: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        // UT: Check GetRemUnrealVAT calculation
        CreateGenJnlLine(GenJnlLine);
        CreateVATEntry(VATEntry1, GenJnlLine, VATEntry1.Type::Purchase, 0);
        CreateVATEntry(VATEntry2, GenJnlLine, VATEntry2.Type::Purchase, VATEntry1."Entry No.");
        Assert.AreEqual(
          VATEntry1."Remaining Unrealized Amount",
          VATSettlementMgt.GetRemUnrealVAT(VATEntry1."Entry No.", CalcDate('<-1D>', WorkDate())),
          WrongValueReturnedErr);
        VATEntry1.Delete();
        VATEntry2.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementMgtCalcPaidAmountVendor()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntry1: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // UT: Check CalcPaidAmount calculation - Purchase
        CreateGenJnlLineVendLedgEntry(GenJnlLine, VendLedgEntry);
        Amount1 := CreateDtldVendLedgerEntry(
            GenJnlLine, VendLedgEntry, DtldVendLedgEntry."Entry Type"::"Initial Entry",
            GenJnlLine."VAT Transaction No.", DtldVendLedgEntry);
        Amount2 := CreateDtldVendLedgerEntry(
            GenJnlLine, VendLedgEntry, DtldVendLedgEntry."Entry Type"::Application,
            GenJnlLine."VAT Transaction No.", DtldVendLedgEntry);
        CreateVATEntry(VATEntry1, GenJnlLine, VATEntry1.Type::Purchase, 0);
        CreateVATEntry(VATEntry2, GenJnlLine, VATEntry2.Type::Purchase, VATEntry1."Entry No.");
        Assert.AreEqual(
          Round(Amount2 * VATEntry1."Unrealized Base" / Amount1),
          VATSettlementMgt.CalcPaidAmount(CalcDate('<-1D>', WorkDate()), WorkDate(), VATEntry2."Unrealized VAT Entry No.", 1),
          WrongValueReturnedErr);
        VendLedgEntry.Delete();
        VATEntry1.Delete();
        VATEntry2.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementMgtCalcPaidAmountCustomer()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VATEntry1: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // UT: Check CalcPaidAmount calculation - Sales
        CreateGenJnlLine(GenJnlLine);
        CreateCustLedgerEntry(
          CustLedgEntry, GenJnlLine."Document Type", GenJnlLine."Document No.", GenJnlLine."VAT Transaction No.");
        Amount1 := CreateDtldCustLedgerEntry(
            GenJnlLine, CustLedgEntry, DtldCustLedgEntry."Entry Type"::"Initial Entry", GenJnlLine."VAT Transaction No.");
        Amount2 := CreateDtldCustLedgerEntry(
            GenJnlLine, CustLedgEntry, DtldCustLedgEntry."Entry Type"::Application, GenJnlLine."VAT Transaction No.");
        CreateVATEntry(VATEntry1, GenJnlLine, VATEntry1.Type::Sale, 0);
        CreateVATEntry(VATEntry2, GenJnlLine, VATEntry2.Type::Sale, VATEntry1."Entry No.");
        Assert.AreEqual(
          Round(Amount2 * VATEntry1."Unrealized Base" / Amount1),
          VATSettlementMgt.CalcPaidAmount(CalcDate('<-1D>', WorkDate()), WorkDate(), VATEntry2."Unrealized VAT Entry No.", 1),
          WrongValueReturnedErr);
        CustLedgEntry.Delete();
        VATEntry1.Delete();
        VATEntry2.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementMgtGetVATPercent()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        // UT: Check GetVATPercent return correct VAT % value based on VAT Entry Posting Groups setup
        CreateGenJnlLineVendLedgEntry(GenJnlLine, VendLedgEntry);
        CreateVATEntry(VATEntry, GenJnlLine, VATEntry.Type::Purchase, 0);

        Assert.AreEqual(
          VATPostingSetup."VAT %",
          VATSettlementMgt.GetVATPercent(VATEntry."Entry No."),
          WrongValueReturnedErr);
        VendLedgEntry.Delete();
        VATEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementMgtAppliedToCMDetailed()
    var
        GenJnlLine: Record "Gen. Journal Line";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        // UT: Check AppliedToCrMemo returns TRUE if Delat
        CreateGenJnlLineVendLedgEntry(GenJnlLine, VendLedgEntry);
        CreateDtldVendLedgerEntry(
          GenJnlLine, VendLedgEntry, DtldVendLedgEntry."Entry Type"::Application,
          GenJnlLine."VAT Transaction No.", DtldVendLedgEntry);
        DtldVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
        DtldVendLedgEntry.FindFirst();
        DtldVendLedgEntry."Document Type" := DtldVendLedgEntry."Document Type"::"Credit Memo";
        DtldVendLedgEntry.Modify();
        Assert.IsTrue(
          VATSettlementMgt.AppliedToCrMemo(GenJnlLine), WrongValueReturnedErr);
        VendLedgEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementCopyDimensionsVendor()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        DimVal1: Record "Dimension Value";
        DimVal2: Record "Dimension Value";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        // UT: Check Dimension are transferred from VLE to Gen. Jnl. Line using
        // CopyDimensions function - Purchase Part
        CreateGenJnlLineVendLedgEntry(GenJnlLine, VendLedgEntry);
        CreateDimensionValuesAndDimSetID(DimVal1, DimVal2, Dimension, DimensionValue);
        VendLedgEntry."Global Dimension 1 Code" := DimVal1.Code;
        VendLedgEntry."Global Dimension 2 Code" := DimVal2.Code;
        VendLedgEntry."Dimension Set ID" :=
          LibraryDimension.CreateDimSet(VendLedgEntry."Dimension Set ID", Dimension.Code, DimensionValue.Code);
        VendLedgEntry.Modify();
        VATSettlementMgt.CopyDimensions(GenJnlLine, CVType::Vendor, GenJnlLine."VAT Transaction No.");
        VerifyGenJnlLineDimensions(GenJnlLine, DimVal1.Code, DimVal2.Code, VendLedgEntry."Dimension Set ID");
        VendLedgEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementCopyDimensionsCustomer()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        DimVal1: Record "Dimension Value";
        DimVal2: Record "Dimension Value";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        // UT: Check Dimension are transferred from VLE to Gen. Jnl. Line using
        // CopyDimensions function - Sales Part
        CreateGenJnlLine(GenJnlLine);
        CreateDimensionValuesAndDimSetID(DimVal1, DimVal2, Dimension, DimensionValue);
        CreateCustLedgerEntry(
          CustLedgEntry, GenJnlLine."Document Type", GenJnlLine."Document No.", GenJnlLine."VAT Transaction No.");
        CustLedgEntry."Global Dimension 1 Code" := DimVal1.Code;
        CustLedgEntry."Global Dimension 2 Code" := DimVal2.Code;
        CustLedgEntry."Dimension Set ID" :=
          LibraryDimension.CreateDimSet(CustLedgEntry."Dimension Set ID", Dimension.Code, DimensionValue.Code);
        CustLedgEntry.Modify();
        VATSettlementMgt.CopyDimensions(GenJnlLine, CVType::Customer, GenJnlLine."VAT Transaction No.");
        VerifyGenJnlLineDimensions(GenJnlLine, DimVal1.Code, DimVal2.Code, CustLedgEntry."Dimension Set ID");
        CustLedgEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementUpdateDocVATAlloc()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATEntry: Record "VAT Entry";
        VATAllocLine: Record "VAT Allocation Line";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        VATAmountToAlloc: Decimal;
        PostingDate: Date;
    begin
        CreateGenJnlLineVendLedgEntry(GenJnlLine, VendLedgEntry);
        CreateVATEntry(VATEntry, GenJnlLine, VATEntry.Type::Purchase, 0);
        VATEntrySetVATPostingSetupGroups(VATEntry);
        VATEntry."CV Ledg. Entry No." := VendLedgEntry."Entry No.";
        VATEntry.Modify();
        VATAmountToAlloc :=
          LibraryRandom.RandDecInRange(
            VATEntry."Remaining Unrealized Amount", VATEntry."Remaining Unrealized Amount" * 2, 2);
        VATSettlementMgt.UpdateDocVATAlloc(VATAmountToAlloc, VATEntry."CV Ledg. Entry No.", PostingDate);
        Assert.AreEqual(VATEntry."Remaining Unrealized Amount", VATAmountToAlloc, WrongCalcAmountErr);

        VATAllocLine.SetRange("VAT Entry No.", VATEntry."Entry No.");
        VATAllocLine.FindFirst();
        Assert.AreEqual(
          VATEntry."Remaining Unrealized Amount", VATAllocLine.Amount, VATAllocLine.FieldCaption(Amount));
        VendLedgEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementUpdateDocVATAllocMustBePosErr()
    begin
        CheckErrorUpdateDocVATAlloc(1, MustBePositiveErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSettlementUpdateDocVATAllocMustBeNegErr()
    begin
        CheckErrorUpdateDocVATAlloc(-1, MustBeNegativeErr);
    end;

    [Test]
    [HandlerFunctions('ChangeVendorVATInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ChangeVendorVATInvoice()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorVATInvoiceNo: Code[20];
    begin
        // Check VLE Vendor VAT Invoice fields values after runnin Change Vendor VAT Invoice report
        CreateVendLedgEntryForChangeVATInvoice(VendLedgEntry, VATPostingSetup);

        VendorVATInvoiceNo := LibraryUtility.GenerateGUID();
        EnqueueVendorVATInvoceParam(VendorVATInvoiceNo, 0, 0);
        RunChangeVendorVATInvoice(VendLedgEntry, '');
        VendLedgEntry.Get(VendLedgEntry."Entry No.");
        Assert.AreEqual(
          VendorVATInvoiceNo, VendLedgEntry."Vendor VAT Invoice No.", VendLedgEntry.FieldCaption("Vendor VAT Invoice No."));
        Assert.AreEqual(
          WorkDate(), VendLedgEntry."Vendor VAT Invoice Date", VendLedgEntry.FieldCaption("Vendor VAT Invoice Date"));
        Assert.AreEqual(
          WorkDate(), VendLedgEntry."Vendor VAT Invoice Rcvd Date", VendLedgEntry.FieldCaption("Vendor VAT Invoice Rcvd Date"));
    end;

    [Test]
    [HandlerFunctions('ChangeVendorVATInvoiceReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeVendorVATInvoiceCreatePrepayment()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // Check Purch. Prepayment Invoice created if Create Prepmt. Invoice = TRUE for
        // Change Vendor VAT Invoice report
        CreateVendLedgEntryForChangeVATInvoice(VendLedgEntry, VATPostingSetup);
        VendLedgEntry.CalcFields("Remaining Amt. (LCY)");
        VATBase := LibraryRandom.RandDecInDecimalRange(1, VendLedgEntry."Remaining Amt. (LCY)", 2);
        VATAmount := LibraryRandom.RandDecInDecimalRange(1, VATBase, 2);

        EnqueueVendorVATInvoceParam(LibraryUtility.GenerateGUID(), VATBase, VATAmount);
        RunChangeVendorVATInvoice(VendLedgEntry, VATPostingSetup."VAT Prod. Posting Group");
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendLedgEntry."Vendor No.");
        PurchInvHeader.FindFirst();
        Assert.IsTrue(PurchInvHeader."Prepayment Invoice", PurchInvHeader.FieldCaption("Prepayment Invoice"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchFullUnrealizedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 362592] Manual Full VAT Settlement of Purchase Invoice

        Initialize();
        // [GIVEN] Posted Purchase Invoice with "Full" VAT and Amount = "X"
        PostPurchInvoiceWithFullVAT(VATPostingSetup, VendLedgEntry);

        // [WHEN] Run Suggest VAT Settlement and Copy to Gen. Journal
        SuggestVATSettlement(VendLedgEntry."Document No.", VATPostingSetup, VATSettlType::Purchase, GenJnlLine, true, WorkDate());

        // [THEN] Gen. Journal Line is generated, "Amount" = "X", "Unrealized Amount" = -"X"
        VerifyGenJnlLineAmounts(GenJnlLine, VATPostingSetup, VendLedgEntry."Document No.", VendLedgEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesFullUnrealizedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 362592] Manual Full VAT Settlement of Sales Invoice

        Initialize();
        // [GIVEN] Posted Sales Invoice with "Full" VAT and Amount = "X"
        PostSalesInvoiceWithFullVAT(VATPostingSetup, CustLedgEntry);

        // [WHEN] Run Suggest VAT Settlement and Copy to Gen. Journal
        SuggestVATSettlement(CustLedgEntry."Document No.", VATPostingSetup, VATSettlType::Sale, GenJnlLine, true, WorkDate());

        // [THEN] Gen. Journal Line is generated, "Amount" = "X", "Unrealized Amount" = -"X"
        VerifyGenJnlLineAmounts(GenJnlLine, VATPostingSetup, CustLedgEntry."Document No.", CustLedgEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchIncrPrepmtDiffDebitCreditVATSettlement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        OldCancelPrepmtAdjmtInTA: Boolean;
        Factor: Decimal;
    begin
        // [FEATURE] [Purchase] [Prepayment] [Cancel Prepmt. Adjmt. in TA] [G/L Correspondence]
        // [SCENARIO 363275] G/L Correspondence Entry for Prepmt. Diff. VAT Settlement posted with Debit Purch VAT Acc. and Credit Purch. VAT Unreal Acc. when FCY increased

        Initialize();
        OldCancelPrepmtAdjmtInTA := UpdateCancelPrepmtAdjmtInTA(true);
        Factor := 3;
        // [GIVEN] Prepmt. Diff. VAT Settlement Journal Line with "Initial VAT Entry No." = "VAT Entry No." of applied invoice
        SetupPurchPrepmtDiffDebitCreditVATSettlementScenario(VATPostingSetup, GenJnlLine, Factor);

        // [WHEN] Post Prepmt. Diff. VAT Settlement Journal Line
        GenJnlPostBatch.VATSettlement(GenJnlLine);

        // [THEN] G/L Corr. Entry posted where Debit Acc. = "Purch. VAT Acc.", Credit Acc. = "Purch. VAT Unreal Acc." and Amount = Prepmt. Diff. VAT Entry Amount
        VerifyPurchVATSettlementGLCorrEntry(
          VATPostingSetup, FindVATSettlementVATEntry(GenJnlLine, true, VATEntry.Type::Purchase));

        // Tear Down
        UpdateCancelPrepmtAdjmtInTA(OldCancelPrepmtAdjmtInTA);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDecrPrepmtDiffDebitCreditVATSettlement()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        OldCancelPrepmtAdjmtInTA: Boolean;
        Factor: Decimal;
    begin
        // [FEATURE] [Purchase] [Prepayment] [Cancel Prepmt. Adjmt. in TA] [G/L Correspondence]
        // [SCENARIO 363275] G/L Correspondence Entry for Prepmt. Diff. VAT Settlement posted with Debit Purch VAT Acc. and Credit Purch. VAT Unreal Acc. when FCY decreased

        Initialize();
        OldCancelPrepmtAdjmtInTA := UpdateCancelPrepmtAdjmtInTA(true);
        Factor := 1 / 3;
        // [GIVEN] Prepmt. Diff. VAT Settlement Journal Line with "Initial VAT Entry No." = "VAT Entry No." of applied invoice
        SetupPurchPrepmtDiffDebitCreditVATSettlementScenario(VATPostingSetup, GenJnlLine, Factor);

        // [WHEN] Post Prepmt. Diff. VAT Settlement Journal Line
        GenJnlPostBatch.VATSettlement(GenJnlLine);

        // [THEN] G/L Corr. Entry posted where Debit Acc. = "Purch. VAT Acc.", Credit Acc. = "Purch. VAT Unreal Acc." and Amount = Prepmt. Diff. VAT Entry Amount
        VerifyPurchVATSettlementGLCorrEntry(
          VATPostingSetup, FindVATSettlementVATEntry(GenJnlLine, true, VATEntry.Type::Purchase));

        // Tear Down
        UpdateCancelPrepmtAdjmtInTA(OldCancelPrepmtAdjmtInTA);
    end;

    [Test]
    [HandlerFunctions('ChangeVendorVATInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure ChangeVendorVATInvoiceLongCode()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        NewVendorVATInvoiceNo: Code[30];
        CodeLength: Integer;
    begin
        // [FEATURE] [VAT] [Invoice]
        // [SCENARIO 279529] Report 14907 runs correctly when length of "Vendor VAT Invoice No." = MAX
        Initialize();
        CodeLength := MaxStrLen(VendLedgEntry."Vendor VAT Invoice No.");
        NewVendorVATInvoiceNo := CopyStr(
            LibraryUtility.GenerateRandomNumericText(CodeLength), 1, CodeLength);

        // [GIVEN] Vendor Ledger Entry with "Vendor VAT Invoice No." length = MAX
        CreateVendLedgEntryForChangeVATInvoice(VendLedgEntry, VATPostingSetup);
        VendLedgEntry."Vendor VAT Invoice No." := CopyStr(
            LibraryUtility.GenerateRandomNumericText(CodeLength), 1, CodeLength);

        // [WHEN] Report 14907 runs
        EnqueueVendorVATInvoceParam(NewVendorVATInvoiceNo, 0, 0);
        RunChangeVendorVATInvoice(VendLedgEntry, '');

        // [THEN] It runs with no errors and sets "Vendor VAT Invoice No." for this entry to new value
        VendLedgEntry.Get(VendLedgEntry."Entry No.");
        VendLedgEntry.TestField("Vendor VAT Invoice No.", NewVendorVATInvoiceNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
    end;

    local procedure SetupPurchPrepmtDiffDebitCreditVATSettlementScenario(var VATPostingSetup: Record "VAT Posting Setup"; var GenJnlLine: Record "Gen. Journal Line"; Factor: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        VATEntry: Record "VAT Entry";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        CurrencyCode: Code[10];
        PrepmtNo: Code[20];
        InvNo: Code[20];
        PostingDate: array[2] of Date;
        TotalInvAmount: Decimal;
    begin
        // Prepayment with FCY applied to Invoice with FCY and different posting date
        CreateVATPostingSetup(VATPostingSetup);
        UpdateVATPostingSetup_VATSettl(VATPostingSetup, LibraryRandom.RandIntInRange(10, 25));
        SetupPostingDateAndCurrExchRates(PostingDate, CurrencyCode, Factor);
        TotalInvAmount :=
          CreateReleasePurchInvoiceWithCurrency(PurchHeader, PostingDate[EntryType::Invoice], CurrencyCode, VATPostingSetup);
        PrepmtNo :=
          CreatePostPrepaymentWithCurrency(PostingDate[EntryType::Prepayment], CurrencyCode,
            GenJnlLine."Account Type"::Vendor, PurchHeader."Pay-to Vendor No.", TotalInvAmount, PurchHeader."No.");
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        ApplyPurchPrepmtToInv(PrepmtNo, InvNo);
        // Posted initial VAT Settlement Entry No. = "X"
        SuggestVATSettlement(InvNo, VATPostingSetup, VATSettlType::Purchase, GenJnlLine, true, PostingDate[EntryType::Invoice]);
        UpdateVATSettlmentJnlLineDocNo(GenJnlLine);
        GenJnlLine.SetRange("Prepmt. Diff.", false);
        GenJnlLine.FindFirst();
        GenJnlPostBatch.VATSettlement(GenJnlLine);

        // Prepmt. Diff. VAT Settlement Jounrnal Line with "Initial VAT Entry No." = "X"
        GenJnlLine.SetRange("Prepmt. Diff.", true);
        GenJnlLine.FindFirst();
        GenJnlLine.Validate("Initial VAT Entry No.", FindVATSettlementVATEntry(GenJnlLine, false, VATEntry.Type::Purchase));
        GenJnlLine.Modify(true);
    end;

    local procedure CreateItemCharge(var ItemCharge: Record "Item Charge"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
        ItemCharge.Init();
        ItemCharge.Validate(
          "No.", LibraryUtility.GenerateRandomCode(ItemCharge.FieldNo("No."), DATABASE::"Item Charge"));
        ItemCharge.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ItemCharge.Insert(true);
    end;

    local procedure CreatePostVATAllocLine(DocumentNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; VATSettlementType: Option; DateFilter: Date) ChargeAmount: Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        VATAmount: Decimal;
    begin
        SuggestVATSettlement(DocumentNo, VATPostingSetup, VATSettlementType, GenJnlLine, true, DateFilter);
        GenJnlLine.FindFirst();

        VATAmount := Round(
            GenJnlLine.Amount * LibraryRandom.RandDecInDecimalRange(0, 1, 2),
            LibraryERM.GetAmountRoundingPrecision());
        ChargeAmount := GenJnlLine.Amount - VATAmount;

        LibraryERM.UpdateVATAllocLine(
          GenJnlLine."Unrealized VAT Entry No.", 10000, 0, '', -VATAmount); // VAT
        LibraryERM.CreateVATAllocLine(GenJnlLine."Unrealized VAT Entry No.", 20000, 2, '', -ChargeAmount); // Charge

        Clear(GenJnlPostBatch);
        GenJnlPostBatch.VATSettlement(GenJnlLine);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        Customer.Insert(true);
        Customer.Validate(Name, Customer."No.");
        // Validating Name as No. because value is not important.
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Customer Posting Group", FindCustomerPostingGroup());
        Customer.Modify(true);
    end;

    local procedure CreateItem(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemChargeAssgntPurch(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemChargeCode: Code[20]; Quantity: Decimal)
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Get(ItemChargeCode);
        PurchaseHeader.CalcFields("Amount Including VAT");
        CreatePurchDocItemChargeLine(
          PurchaseHeader, ItemChargeCode, Quantity,
          PurchaseHeader."Amount Including VAT", PurchaseHeader."Amount Including VAT");
        FindLastItemChargePurchLine(PurchaseLine, PurchaseHeader."No.", PurchaseHeader."Document Type");
        SuggestItemChargeAssgntPurch(PurchaseLine, ItemCharge, Quantity, PurchaseHeader."Amount Including VAT");
    end;

    local procedure CreateItemChargeAssgntSales(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemChargeCode: Code[20]; Quantity: Decimal)
    var
        ItemCharge: Record "Item Charge";
    begin
        ItemCharge.Get(ItemChargeCode);
        SalesHeader.CalcFields("Amount Including VAT");
        CreateSalesDocItemChargeLine(
          SalesHeader, ItemChargeCode, Quantity,
          SalesHeader."Amount Including VAT", SalesHeader."Amount Including VAT");
        GetLastItemChargeSalesLine(SalesLine, SalesHeader."No.", SalesHeader."Document Type");
        SuggestItemChargeAssgntSales(SalesLine, ItemCharge, Quantity, SalesHeader."Amount Including VAT");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup.Code, VATProdPostingGroup.Code);

        VATPostingSetup."VAT Identifier" := VATPostingSetup."VAT Prod. Posting Group";
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::Percentage;
        VATPostingSetup."Purch. VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Sales VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Write-Off VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup.Modify(true);
    end;

    local procedure GetItemChargePurchLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();
    end;

    local procedure GetItemChargeSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindFirst();
    end;

    local procedure AddPurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(50, 100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure AddSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);

        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(50, 100, 2));
        SalesLine.Modify(true);
    end;

    local procedure FAPurchRelease(UndepreciableFA: Boolean; AllowVATSetBeforeFARel: Boolean; FARelease: Boolean; VATAllocation: Boolean; var VATPostingSetup: Record "VAT Posting Setup"; FAReleaseDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        ItemCharge: Record "Item Charge";
        FADeprBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        PurchInvoiceNo: Code[20];
        FixedAssetNo: Code[20];
        ChargeAmount: Decimal;
        FAAcquisitionCost: Decimal;
    begin
        // General Preparations => Create VENDOR, FA => Create & Post Purchase Invoice, Create & Release FA Release Act(Option),
        // Manual VAT Settlement with Allocation (VAT & Charge).

        Initialize();
        SetAllowVATSetBeforeFARelease(AllowVATSetBeforeFARel);
        Setup(GeneralPostingSetup, VATPostingSetup, ItemCharge, false);

        CreateVendor(Vendor, VATPostingSetup);
        FixedAssetNo := CreateFA(VATPostingSetup, UndepreciableFA);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        AddPurchaseLine(PurchaseHeader, PurchaseLine, PurchaseLine.Type::"Fixed Asset", FixedAssetNo, 1);
        FAAcquisitionCost := PurchaseLine."Direct Unit Cost";
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        FASetup.Get();
        // Release FA to operation
        if FARelease then begin
            CreateAndPostFAReleaseDoc(FixedAssetNo, FAReleaseDate);
            FADeprBook.Get(FixedAssetNo, FASetup."Release Depr. Book");
        end else
            FADeprBook.Get(FixedAssetNo, FASetup."Default Depr. Book");

        if VATAllocation then begin
            ChargeAmount := -CreatePostVATAllocLine(PurchInvoiceNo, VATPostingSetup, VATSettlType::FA, WorkDate());
            FADeprBook.CalcFields("Acquisition Cost");
            Assert.AreEqual(
              FAAcquisitionCost + ChargeAmount, FADeprBook."Acquisition Cost", IncorrectAcqCostErr);
        end;
        exit(PurchInvoiceNo);
    end;

    local procedure CreateFA(VATPostingSetup: Record "VAT Posting Setup"; UndepreciableFA: Boolean): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        LibraryFixedAsset.CreateFixedAssetWithCustomSetup(FixedAsset, VATPostingSetup);
        FixedAsset.Validate("Undepreciable FA", UndepreciableFA);
        FixedAsset.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure UpdateVATPostingSetup_ItemCharge(var VATPostingSetup: Record "VAT Posting Setup"; var ItemCharge: Record "Item Charge"; GenProdPostingGroup: Code[20])
    begin
        CreateItemCharge(ItemCharge, VATPostingSetup."VAT Prod. Posting Group", GenProdPostingGroup);
        VATPostingSetup."VAT Charge No." := ItemCharge."No.";
        VATPostingSetup.Modify(true);
    end;

    local procedure CreatePurchInv(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; Type: Enum "Purchase Line Type"; Items: array[2] of Code[20]; NoOfLines: Integer; NoOfItems: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        Counter: Integer;
        NewCounter: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        for Counter := 1 to NoOfLines do
            for NewCounter := 1 to NoOfItems do
                AddPurchaseLine(PurchaseHeader, PurchaseLine, Type, Items[NewCounter], LibraryRandom.RandInt(50));
    end;

    local procedure CreatePurchCrM(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; PurchaseInvoiceNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PurchaseInvoiceNo, true, false);
    end;

    local procedure CreateSalesInv(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; Type: Enum "Sales Line Type"; Items: array[2] of Code[20]; NoOfLines: Integer; NoOfItems: Integer)
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
        NewCounter: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        for Counter := 1 to NoOfLines do
            for NewCounter := 1 to NoOfItems do
                AddSalesLine(SalesHeader, SalesLine, Type, Items[NewCounter], LibraryRandom.RandInt(50));
    end;

    local procedure CreateSalesCrM(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; SalesInvoiceNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", SalesInvoiceNo, true, false);
    end;

    local procedure CreatePostPurchInvIC(VendorNo: Code[20]; Items: array[2] of Code[20]; ItemChargeNo: Code[20]; NoOfLines: Integer; NoOfItems: Integer): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchInv(PurchaseHeader, VendorNo, PurchaseLine.Type::Item, Items, NoOfLines, NoOfItems);
        CreateItemChargeAssgntPurch(PurchaseHeader, PurchaseLine, ItemChargeNo, 1);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostPurchCrMIC(VendorNo: Code[20]; PurchaseInvoiceNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
    begin
        CreatePurchCrM(PurchaseHeader, VendorNo, PurchaseInvoiceNo);
        GetItemChargePurchLine(PurchaseHeader, PurchaseLine);
        ItemCharge.Get(PurchaseLine."No.");
        SuggestItemChargeAssgntPurch(PurchaseLine, ItemCharge, 1, PurchaseHeader."Amount Including VAT");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateReleasePurchInvoiceWithCurrency(var PurchHeader: Record "Purchase Header"; PostingDate: Date; CurrencyCode: Code[10]; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        PurchLine: Record "Purchase Line";
        GLAccNo: Code[20];
    begin
        CreateVendor(Vendor, VATPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.");
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);
        GLAccNo :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccNo, LibraryRandom.RandIntInRange(100, 1000));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);
        PurchHeader.CalcFields("Amount Including VAT");
        exit(PurchHeader."Amount Including VAT");
    end;

    local procedure PostPurchInvoiceWithFullVAT(var VATPostingSetup: Record "VAT Posting Setup"; var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        PurchLine: Record "Purchase Line";
        GLAccNo: array[2] of Code[20];
        DocNo: Code[20];
    begin
        InitializeFullVATSetup(VATPostingSetup);
        GLAccNo[1] :=
          VATPostingSetup."Purchase VAT Account";
        DocNo :=
          CreateVendorAndPostInvoiceWithGLAcc(VATPostingSetup."VAT Bus. Posting Group", PurchLine.Type::"G/L Account", GLAccNo, 1, 1);
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Invoice, DocNo);
        VendLedgEntry.CalcFields(Amount);
    end;

    local procedure CreatePostSalesInvIC(CustomerNo: Code[20]; Items: array[2] of Code[20]; ItemChargeNo: Code[20]; NoOfLines: Integer; NoOfItems: Integer): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesInv(SalesHeader, CustomerNo, SalesLine.Type::Item, Items, NoOfLines, NoOfItems);
        CreateItemChargeAssgntSales(SalesHeader, SalesLine, ItemChargeNo, 1);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesCrMIC(CustomerNo: Code[20]; SalesInvoiceNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCharge: Record "Item Charge";
    begin
        CreateSalesCrM(SalesHeader, CustomerNo, SalesInvoiceNo);
        GetItemChargeSalesLine(SalesHeader, SalesLine);
        ItemCharge.Get(SalesLine."No.");
        SuggestItemChargeAssgntSales(SalesLine, ItemCharge, 1, SalesHeader."Amount Including VAT");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostPrepaymentWithCurrency(PostingDate: Date; CurrencyCode: Code[10]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; EntryAmount: Decimal; PrepmtDocNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJnlLine, GenJnlLine."Document Type"::Payment, AccountType, AccountNo, EntryAmount);
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Currency Code", CurrencyCode);
        GenJnlLine.Validate(Prepayment, true);
        GenJnlLine.Validate("Prepayment Document No.", PrepmtDocNo);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure PostSalesInvoiceWithFullVAT(var VATPostingSetup: Record "VAT Posting Setup"; var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        GLAccNo: array[2] of Code[20];
        DocNo: Code[20];
    begin
        InitializeFullVATSetup(VATPostingSetup);
        GLAccNo[1] :=
          VATPostingSetup."Sales VAT Account";
        DocNo :=
          CreateCustomerAndPostInvoiceWithGLAcc(VATPostingSetup."VAT Bus. Posting Group", GLAccNo, 1, 1);
        LibraryERM.FindCustomerLedgerEntry(CustLedgEntry, CustLedgEntry."Document Type"::Invoice, DocNo);
        CustLedgEntry.CalcFields(Amount);
    end;

    local procedure CreateVATSettlTemplateAndBatch(var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlBatch: Record "Gen. Journal Batch")
    begin
        if not GenJnlTemplate.Get(XVATSETTxt) then begin
            GenJnlTemplate.Init();
            GenJnlTemplate.Name := XVATSETTxt;
            GenJnlTemplate.Validate(Type, GenJnlTemplate.Type::"VAT Settlement");
            GenJnlTemplate.Insert();
        end;
        if not GenJnlBatch.Get(XVATSETTxt, XDEFAULTTxt) then begin
            GenJnlBatch.Init();
            GenJnlBatch.Validate("Journal Template Name", GenJnlTemplate.Name);
            GenJnlBatch.Validate(Name, XDEFAULTTxt);
            GenJnlBatch.Insert();
        end;
    end;

    local procedure UpdateVATPostingSetup_VATSettl(var VATPostingSetup: Record "VAT Posting Setup"; VATPct: Integer)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        CreateVATSettlTemplateAndBatch(GenJnlTemplate, GenJnlBatch);
        VATPostingSetup."Manual VAT Settlement" := true;
        VATPostingSetup."VAT Settlement Template" := GenJnlBatch."Journal Template Name";
        VATPostingSetup."VAT Settlement Batch" := GenJnlBatch.Name;
        VATPostingSetup."VAT %" := VATPct;
        VATPostingSetup.Modify();
    end;

    [Normal]
    local procedure FindCustomerPostingGroup(): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Reset();
        CustomerPostingGroup.SetFilter("Invoice Rounding Account", '<>''''');
        if not CustomerPostingGroup.FindFirst() then begin
            CustomerPostingGroup.Reset();
            CustomerPostingGroup.FindFirst();
            CustomerPostingGroup."Invoice Rounding Account" := LibraryERM.CreateGLAccountNo();
            CustomerPostingGroup.Modify();
        end;
        exit(CustomerPostingGroup.Code);
    end;

    local procedure SuggestItemChargeAssgntPurch(PurchLine: Record "Purchase Line"; ItemCharge: Record "Item Charge"; ChargeItemQty: Decimal; ChargeItemAmt: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargeAssgntPurch: Codeunit "Item Charge Assgnt. (Purch.)";
    begin
        LibraryPurchase.CreateItemChargeAssignment(ItemChargeAssignmentPurch, PurchLine, ItemCharge,
          ItemChargeAssignmentPurch."Applies-to Doc. Type"::Invoice,
          PurchLine."Document No.", PurchLine."Line No.",
          PurchLine."No.", ChargeItemQty, ChargeItemAmt);
        ItemChargeAssgntPurch.CreateDocChargeAssgnt(ItemChargeAssignmentPurch, PurchLine."Receipt No.");
        ItemChargeAssgntPurch.SuggestAssgnt(PurchLine, PurchLine.Quantity, PurchLine."Line Amount");
    end;

    local procedure CreatePurchDocItemChargeLine(PurchHeader: Record "Purchase Header"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; LineAmt: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        CreatePurchDocLine(PurchHeader, PurchLine.Type::"Charge (Item)", ItemNo, Qty, UnitCost, LineAmt);
    end;

    local procedure FindLastItemChargePurchLine(var PurchLine: Record "Purchase Line"; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Invoice);
        PurchLine.SetRange("Document No.", DocumentNo);
        PurchLine.SetRange("Document Type", DocumentType);
        PurchLine.SetRange(Type, PurchLine.Type::"Charge (Item)");
        PurchLine.FindLast();
    end;

    local procedure CreatePurchDocLine(PurchHeader: Record "Purchase Header"; ItemType: Enum "Purchase Line Type"; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; LineAmt: Decimal)
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, ItemType, ItemNo, Qty);
        PurchLine.Validate("Direct Unit Cost", UnitCost);
        PurchLine.Validate("Line Amount", LineAmt);
        PurchLine.Modify(true);
    end;

    local procedure CreateSalesDocItemChargeLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; UnitPrice: Decimal; LineAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocLine(SalesHeader, SalesLine.Type::"Charge (Item)", ItemNo, Qty, UnitPrice, LineAmt);
    end;

    local procedure CreateSalesDocLine(SalesHeader: Record "Sales Header"; ItemType: Enum "Sales Line Type"; ItemNo: Code[20]; Qty: Decimal; UnitPrice: Decimal; LineAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, ItemType, ItemNo, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Amount", LineAmt);
        SalesLine.Modify(true);
    end;

    local procedure GetLastItemChargeSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type")
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindLast();
    end;

    local procedure SuggestItemChargeAssgntSales(SalesLine: Record "Sales Line"; ItemCharge: Record "Item Charge"; ChargeItemQty: Decimal; ChargeItemAmt: Decimal)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemChargeAssgntSales: Codeunit "Item Charge Assgnt. (Sales)";
    begin
        LibrarySales.CreateItemChargeAssignment(ItemChargeAssignmentSales, SalesLine, ItemCharge,
          ItemChargeAssignmentSales."Applies-to Doc. Type"::Invoice,
          SalesLine."Document No.", SalesLine."Line No.",
          SalesLine."No.", ChargeItemQty, ChargeItemAmt);
        ItemChargeAssgntSales.CreateDocChargeAssgn(ItemChargeAssignmentSales, SalesLine."Shipment No.");
        ItemChargeAssgntSales.SuggestAssignment(SalesLine, SalesLine.Quantity, SalesLine."Line Amount");
    end;

    local procedure Setup(var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup"; var ItemCharge: Record "Item Charge"; ZeroVATPct: Boolean)
    var
        VATPct: Decimal;
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        CreateVATPostingSetup(VATPostingSetup);
        UpdateVATPostingSetup_ItemCharge(VATPostingSetup, ItemCharge, GeneralPostingSetup."Gen. Prod. Posting Group");
        if ZeroVATPct then
            VATPct := 0
        else
            VATPct := LibraryRandom.RandIntInRange(1, 99);
        UpdateVATPostingSetup_VATSettl(VATPostingSetup, VATPct);
    end;

    local procedure InitializeFullVATSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Full VAT");
        VATPostingSetup.Modify(true);
        UpdateVATPostingSetup_VATSettl(VATPostingSetup, VATPostingSetup."VAT %");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        UpdatePostingGroupsGLAccount(GeneralPostingSetup, VATPostingSetup, VATPostingSetup."Purchase VAT Account");
        UpdatePostingGroupsGLAccount(GeneralPostingSetup, VATPostingSetup, VATPostingSetup."Sales VAT Account");
    end;

    local procedure SetupPostingDateAndCurrExchRates(var PostingDate: array[2] of Date; var CurrencyCode: Code[10]; Factor: Decimal)
    var
        Currency: Record Currency;
        ExchRateAmount: array[2] of Decimal;
    begin
        PostingDate[EntryType::Prepayment] := WorkDate();
        ExchRateAmount[EntryType::Prepayment] := LibraryRandom.RandInt(100);
        PostingDate[EntryType::Invoice] := CalcDate('<1M>', WorkDate());
        ExchRateAmount[EntryType::Invoice] :=
          ExchRateAmount[EntryType::Prepayment] * Factor;
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Purch. PD Losses Acc. (TA)", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Sales PD Losses Acc. (TA)", LibraryERM.CreateGLAccountNo());
        Currency.Validate("PD Bal. Gain/Loss Acc. (TA)", LibraryERM.CreateGLAccountNo());
        Currency.Modify(true);
        LibraryERM.CreateExchangeRate(
          Currency.Code, PostingDate[EntryType::Invoice],
          ExchRateAmount[EntryType::Invoice], ExchRateAmount[EntryType::Invoice]);
        LibraryERM.CreateExchangeRate(
          Currency.Code, PostingDate[EntryType::Prepayment],
          ExchRateAmount[EntryType::Prepayment], ExchRateAmount[EntryType::Prepayment]);
        CurrencyCode := Currency.Code;
    end;

    local procedure SuggestVATSettlement(DocumentNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; VATSettlementType: Option ,Purchase,Sale,FA,FPE; var GenJnlLine: Record "Gen. Journal Line"; CopyToJournal: Boolean; DateFilter: Date)
    var
        TempVATDocEntryBuffer: Record "VAT Document Entry Buffer" temporary;
        VATEntry: Record "VAT Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
    begin
        // create VAT Settlement
        TempVATDocEntryBuffer.SetRange("Date Filter", 0D, DateFilter);
        TempVATDocEntryBuffer.SetRange("Document No.", DocumentNo);
        TempVATDocEntryBuffer.Next(0); // Needed to trick preCAL
        VATSettlementMgt.Generate(TempVATDocEntryBuffer, VATSettlementType);
        if CopyToJournal and TempVATDocEntryBuffer.FindSet() then
            VATSettlementMgt.CopyToJnl(TempVATDocEntryBuffer, VATEntry);
        FilterGenJnlLine(GenJnlLine, VATPostingSetup, DocumentNo);
    end;

    local procedure FullVATSettlementByPart(DocumentNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; VATSettlType: Option ,Purchase,Sale,FA,FPE; NoOfPartSettlements: Integer; DateFilter: Date)
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        Count2: Integer;
    begin
        for Count2 := 1 to NoOfPartSettlements do begin
            SuggestVATSettlement(DocumentNo, VATPostingSetup, VATSettlType, GenJnlLine, true, DateFilter);
            GenJnlLine.FindFirst();
            if Count2 <> NoOfPartSettlements then
                GenJnlLine.Validate(Amount, -GenJnlLine.GetUnrealizedVATAmount(true) / NoOfPartSettlements)
            else
                GenJnlLine.Validate(Amount, -GenJnlLine.GetUnrealizedVATAmount(true));
            GenJnlLine.Modify(true);
            Clear(GenJnlPostBatch);
            GenJnlPostBatch.VATSettlement(GenJnlLine);
        end;

        SuggestVATSettlement(DocumentNo, VATPostingSetup, VATSettlType, GenJnlLine, true, DateFilter);
        Assert.IsTrue(GenJnlLine.IsEmpty, SuggestVATSettlNotEmptyErr);
    end;

    local procedure CreateCustomerAndPostInvoice(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; Items: array[2] of Code[20]; NoOfLines: Integer; NoOfItems: Integer): Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateCustomer(Customer, GeneralPostingSetup, VATPostingSetup);
        CreateSalesInv(SalesHeader, Customer."No.", SalesLine.Type::Item, Items, NoOfLines, NoOfItems);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCustomerAndPostInvoiceWithGLAcc(VATBusinessPostingGroup: Code[20]; GLAccounts: array[2] of Code[20]; NoOfLines: Integer; NoOfGLAccounts: Integer): Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup);
        Customer.Modify(true);
        CreateSalesInv(SalesHeader, Customer."No.", SalesLine.Type::"G/L Account", GLAccounts, NoOfLines, NoOfGLAccounts);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateVendorAndPostInvoice(VATPostingSetup: Record "VAT Posting Setup"; Type: Enum "Purchase Line Type"; Items: array[2] of Code[20]; NoOfLines: Integer; NoOfItems: Integer): Code[20]
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateVendor(Vendor, VATPostingSetup);
        CreatePurchInv(PurchaseHeader, Vendor."No.", Type, Items, NoOfLines, NoOfItems);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateVendorAndPostInvoiceWithGLAcc(VATBusinessPostingGroup: Code[20]; Type: Enum "Purchase Line Type"; Items: array[2] of Code[20]; NoOfLines: Integer; NoOfItems: Integer): Code[20]
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup);
        Vendor.Modify(true);
        CreatePurchInv(PurchaseHeader, Vendor."No.", Type, Items, NoOfLines, NoOfItems);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure FilterGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; DocumentNo: Code[20])
    begin
        GenJnlLine.SetRange("Journal Template Name", VATPostingSetup."VAT Settlement Template");
        GenJnlLine.SetRange("Journal Batch Name", VATPostingSetup."VAT Settlement Batch");
        GenJnlLine.SetRange("Document No.", DocumentNo);
    end;

    local procedure SetAllowVATSetBeforeFARelease(AllowVATSetBeforeFARelease: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Allow VAT Set. before FA Rel.", AllowVATSetBeforeFARelease);
        GLSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSelection(Options: Text[1024]; var Choice: Integer; Instuction: Text[1024])
    begin
        Choice := 2;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    local procedure CreateDtldVendLedgerEntry(GenJnlLine: Record "Gen. Journal Line"; VendLedgEntry: Record "Vendor Ledger Entry"; EntryType: Enum "Detailed CV Ledger Entry Type"; TransactionNo: Integer; var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry"): Decimal
    var
        RecRef: RecordRef;
    begin
        DtldVendLedgEntry.Init();
        RecRef.GetTable(DtldVendLedgEntry);
        DtldVendLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, DtldVendLedgEntry.FieldNo("Entry No."));
        DtldVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntry."Entry No.";
        DtldVendLedgEntry."Vendor No." := GenJnlLine."Account No.";
        DtldVendLedgEntry."Transaction No." := TransactionNo;
        DtldVendLedgEntry."Vendor Ledger Entry No." := VendLedgEntry."Entry No.";
        DtldVendLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        DtldVendLedgEntry."Entry Type" := EntryType;
        DtldVendLedgEntry."Prepmt. Diff. in TA" := false;
        DtldVendLedgEntry."Posting Date" := WorkDate();
        DtldVendLedgEntry.Insert();
        exit(DtldVendLedgEntry."Amount (LCY)");
    end;

    local procedure CreateDtldCustLedgerEntry(GenJnlLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry"; EntryType: Enum "Detailed CV Ledger Entry Type"; TransactionNo: Integer): Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        RecRef: RecordRef;
    begin
        DtldCustLedgEntry.Init();
        RecRef.GetTable(DtldCustLedgEntry);
        DtldCustLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, DtldCustLedgEntry.FieldNo("Entry No."));
        DtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntry."Entry No.";
        DtldCustLedgEntry."Customer No." := GenJnlLine."Account No.";
        DtldCustLedgEntry."Transaction No." := TransactionNo;
        DtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntry."Entry No.";
        DtldCustLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        DtldCustLedgEntry."Entry Type" := EntryType;
        DtldCustLedgEntry."Prepmt. Diff. in TA" := false;
        DtldCustLedgEntry."Posting Date" := WorkDate();
        DtldCustLedgEntry.Insert();
        exit(DtldCustLedgEntry."Amount (LCY)");
    end;

    local procedure CreateVendLedgerEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; TransactionNo: Integer)
    var
        RecRef: RecordRef;
    begin
        VendLedgEntry.Init();
        RecRef.GetTable(VendLedgEntry);
        VendLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, VendLedgEntry.FieldNo("Entry No."));
        VendLedgEntry."Document Type" := DocumentType;
        VendLedgEntry."Document No." := DocumentNo;
        VendLedgEntry."Transaction No." := TransactionNo;
        VendLedgEntry.Insert();
    end;

    local procedure CreateCustLedgerEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; TransactionNo: Integer)
    var
        RecRef: RecordRef;
    begin
        CustLedgEntry.Init();
        RecRef.GetTable(CustLedgEntry);
        CustLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CustLedgEntry.FieldNo("Entry No."));
        CustLedgEntry."Document Type" := DocumentType;
        CustLedgEntry."Document No." := DocumentNo;
        CustLedgEntry."Transaction No." := TransactionNo;
        CustLedgEntry.Insert();
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        RecRef: RecordRef;
    begin
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlTemplate.Name;
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        RecRef.GetTable(GenJnlLine);
        GenJnlLine."Line No." := LibraryUtility.GetNewLineNo(RecRef, GenJnlLine.FieldNo("Line No."));
        GenJnlLine.Insert();
        GenJnlLine."VAT Transaction No." := GetNextTransactionNo();
        GenJnlLine."Account No." := LibraryUtility.GenerateGUID();
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
        GenJnlLine."Document No." := LibraryUtility.GenerateGUID();
        GenJnlLine."Posting Date" := WorkDate();
        GenJnlLine.Amount := LibraryRandom.RandInt(20);
        GenJnlLine.Modify();
    end;

    local procedure UpdatePostingGroupsGLAccount(GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; GLAccNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccNo);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure CheckCVLedgEntry(CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; PostingDate: Date; EntryNo: Integer; CVNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; CVLEDescription: Text[100])
    begin
        CVLedgerEntryBuffer.TestField("Posting Date", PostingDate);
        CVLedgerEntryBuffer.TestField("Entry No.", EntryNo);
        CVLedgerEntryBuffer.TestField("CV No.", CVNo);
        CVLedgerEntryBuffer.TestField("Document Type", DocumentType);
        CVLedgerEntryBuffer.TestField("Document No.", DocumentNo);
        CVLedgerEntryBuffer.TestField(Description, CVLEDescription);
    end;

    local procedure CheckCVLedgEntryVendor(VendLedgEntry: Record "Vendor Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
        CheckCVLedgEntry(
          CVLedgerEntryBuffer,
          VendLedgEntry."Posting Date", VendLedgEntry."Entry No.",
          VendLedgEntry."Vendor No.", VendLedgEntry."Document Type",
          VendLedgEntry."Document No.", VendLedgEntry.Description);
    end;

    local procedure CheckCVLedgEntryCustomer(CustLedgEntry: Record "Cust. Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
        CheckCVLedgEntry(
          CVLedgerEntryBuffer,
          CustLedgEntry."Posting Date", CustLedgEntry."Entry No.",
          CustLedgEntry."Customer No.", CustLedgEntry."Document Type",
          CustLedgEntry."Document No.", CustLedgEntry.Description);
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; GenJnlLine: Record "Gen. Journal Line"; VATEntryType: Enum "General Posting Type"; UnrealizedVATEntryNo: Integer)
    var
        RecRef: RecordRef;
    begin
        VATEntry.Init();
        RecRef.GetTable(VATEntry);
        VATEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, VATEntry.FieldNo("Entry No."));
        VATEntry."Transaction No." := GetNextTransactionNo();
        VATEntry."Object Type" := "Gen. Journal Account Type".FromInteger(GenJnlLine."Object Type");
        VATEntry."Object No." := GenJnlLine."Object No.";
        VATEntry."Unrealized VAT Entry No." := LibraryRandom.RandInt(100);
        VATEntry."Posting Date" := WorkDate();
        VATEntry."Remaining Unrealized Amount" := LibraryRandom.RandIntInRange(20, 50);
        VATEntry."Unrealized Base" := LibraryRandom.RandIntInRange(51, 100);
        VATEntry.Type := VATEntryType;
        VATEntry."Document Type" := VATEntry."Document Type"::Payment;
        if UnrealizedVATEntryNo <> 0 then
            VATEntry."Unrealized VAT Entry No." := UnrealizedVATEntryNo;
        VATEntry.Insert();
    end;

    local procedure GetNextTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        exit(GLEntry."Transaction No." + 1);
    end;

    local procedure CreateGenJnlLineVendLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        CreateGenJnlLine(GenJnlLine);
        CreateVendLedgerEntry(
          VendLedgEntry, GenJnlLine."Document Type", GenJnlLine."Document No.", GenJnlLine."VAT Transaction No.");
    end;

    local procedure CreateDimensionValuesAndDimSetID(var DimVal1: Record "Dimension Value"; var DimVal2: Record "Dimension Value"; var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value")
    var
        GLSetup: Record "General Ledger Setup";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimVal1, GLSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimVal2, GLSetup."Global Dimension 1 Code");
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure FindVATSettlementVATEntry(GenJnlLine: Record "Gen. Journal Line"; PrepmtDiff: Boolean; EntryType: Enum "General Posting Type"): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", GenJnlLine."Document Type");
        VATEntry.SetRange("Document No.", GenJnlLine."Document No.");
        VATEntry.SetRange(Type, EntryType);
        VATEntry.SetFilter("Unrealized VAT Entry No.", '<>0');
        VATEntry.SetRange("Bill-to/Pay-to No.", GenJnlLine."Account No.");
        VATEntry.SetRange("Prepmt. Diff.", PrepmtDiff);
        VATEntry.FindLast();
        exit(VATEntry."Entry No.");
    end;

    local procedure UpdateCancelPrepmtAdjmtInTA(NewCancelPrepmtAdjmtInTA: Boolean) OldCancelPrepmtAdjmtInTA: Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        OldCancelPrepmtAdjmtInTA := GLSetup."Cancel Prepmt. Adjmt. in TA";
        GLSetup.Validate("Cancel Prepmt. Adjmt. in TA", NewCancelPrepmtAdjmtInTA);
        GLSetup.Modify(true);
    end;

    local procedure UpdateVATSettlmentJnlLineDocNo(var GenJnlLine: Record "Gen. Journal Line")
    var
        VATSettlementDocNo: Code[20];
    begin
        VATSettlementDocNo := LibraryUtility.GenerateGUID();
        GenJnlLine.FindSet(true);
        repeat
            GenJnlLine.Validate("Document No.", VATSettlementDocNo);
            GenJnlLine.Validate("External Document No.", GenJnlLine."Document No.");
            GenJnlLine.Modify(true);
        until GenJnlLine.Next() = 0;
        GenJnlLine.SetRange("Document No.");
    end;

    local procedure ApplyPurchPrepmtToInv(PrepmtNo: Code[20]; InvNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.ApplyVendorLedgerEntry(
          VendLedgEntry."Document Type"::Payment, PrepmtNo,
          VendLedgEntry."Document Type"::Invoice, InvNo);
    end;

    local procedure CreateAndPostFAReleaseDoc(FANo: Code[20]; PostingDate: Date)
    var
        FADocumentHeader: Record "FA Document Header";
    begin
        LibraryFixedAsset.CreateFAReleaseDoc(FADocumentHeader, FANo, PostingDate);
        LibraryFixedAsset.PostFADocument(FADocumentHeader);
    end;

    local procedure VerifyGenJnlLineDimensions(GenJnlLine: Record "Gen. Journal Line"; DimValCode1: Code[20]; DimValCode2: Code[20]; DimSetId: Integer)
    begin
        Assert.AreEqual(DimValCode1, GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine.FieldCaption("Shortcut Dimension 1 Code"));
        Assert.AreEqual(DimValCode2, GenJnlLine."Shortcut Dimension 2 Code", GenJnlLine.FieldCaption("Shortcut Dimension 2 Code"));
        Assert.AreEqual(DimSetId, GenJnlLine."Dimension Set ID", GenJnlLine.FieldCaption("Dimension Set ID"));
    end;

    local procedure VerifyVATEntryManualVATSettlement(VATEntry: Record "VAT Entry")
    var
        ReversedVATEntry: Record "VAT Entry";
    begin
        ReversedVATEntry.SetRange("Reversed Entry No.", VATEntry."Entry No.");
        ReversedVATEntry.FindFirst();
        Assert.AreEqual(-ReversedVATEntry.Base, VATEntry.Base, ReversedVATEntry.FieldCaption(Base));
        Assert.AreEqual(-ReversedVATEntry.Amount, VATEntry.Amount, ReversedVATEntry.FieldCaption(Amount));
    end;

    local procedure VATEntrySetVATPostingSetupGroups(var VATEntry: Record "VAT Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::Percentage;
        VATPostingSetup."Purch. VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup.Modify();
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry.Modify();
    end;

    local procedure CheckErrorUpdateDocVATAlloc(Sign: Integer; ErrorText: Text)
    var
        GenJnlLine: Record "Gen. Journal Line";
        VATEntry: Record "VAT Entry";
        VATSettlementMgt: Codeunit "VAT Settlement Management";
        VATAmountToAlloc: Decimal;
        PostingDate: Date;
    begin
        CreateGenJnlLine(GenJnlLine);
        CreateVATEntry(VATEntry, GenJnlLine, VATEntry.Type::Purchase, 0);
        VATEntry."Remaining Unrealized Amount" := Sign * VATEntry."Remaining Unrealized Amount";
        VATEntry.Modify();
        VATAmountToAlloc :=
          -LibraryRandom.RandDecInRange(
            VATEntry."Remaining Unrealized Amount", VATEntry."Remaining Unrealized Amount" + 1, 2);
        asserterror VATSettlementMgt.UpdateDocVATAlloc(VATAmountToAlloc, VATEntry."CV Ledg. Entry No.", PostingDate);
        Assert.ExpectedError(ErrorText);
    end;

    local procedure EnqueueVendorVATInvoceParam(VendorVATInvoiceNo: Code[30]; VATBase: Decimal; VATAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(VendorVATInvoiceNo);
        LibraryVariableStorage.Enqueue(VATBase);
        LibraryVariableStorage.Enqueue(VATAmount);
    end;

    local procedure CreateVendLedgEntryForChangeVATInvoice(var VendLedgEntry: Record "Vendor Ledger Entry"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        GenJnlLine: Record "Gen. Journal Line";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        Vendor: Record Vendor;
    begin
        CreateGenJnlLineVendLedgEntry(GenJnlLine, VendLedgEntry);
        CreateDtldVendLedgerEntry(
          GenJnlLine, VendLedgEntry, DtldVendLedgEntry."Entry Type"::Application,
          GenJnlLine."VAT Transaction No.", DtldVendLedgEntry);
        CreateVATPostingSetup(VATPostingSetup);
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Full VAT";
        VATPostingSetup.Modify();
        CreateVendor(Vendor, VATPostingSetup);
        LibraryERM.FindVATProductPostingGroup(VATProdPostingGroup);
        VendLedgEntry."Vendor No." := Vendor."No.";
        VendLedgEntry."Vendor Posting Group" := Vendor."Vendor Posting Group";
        VendLedgEntry.Prepayment := true;
        VendLedgEntry.Modify();
        VendLedgEntry.SetRecFilter();
    end;

    local procedure RunChangeVendorVATInvoice(VendLedgEntry: Record "Vendor Ledger Entry"; VATProdPostingGroup: Code[20])
    var
        ChangeVendorVATInvoice: Report "Change Vendor VAT Invoice";
    begin
        ChangeVendorVATInvoice.SetVendLedgEntry(VendLedgEntry);
        if VATProdPostingGroup <> '' then
            ChangeVendorVATInvoice.SetVATProdGroup(VATProdPostingGroup);
        Commit();
        ChangeVendorVATInvoice.Run();
    end;

    local procedure VerifyGenJnlLineAmounts(var GenJnlLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; DocNo: Code[20]; ExpectedAmount: Decimal)
    begin
        FilterGenJnlLine(GenJnlLine, VATPostingSetup, DocNo);
        GenJnlLine.FindFirst();
        Assert.AreEqual(ExpectedAmount, GenJnlLine.Amount, GenJnlLine.FieldCaption(Amount));
        Assert.AreEqual(-ExpectedAmount, GenJnlLine."Unrealized Amount", GenJnlLine.FieldCaption("Unrealized Amount"));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ChangeVendorVATInvoiceReportHandler(var VendorVATInvoiceReportHandler: TestRequestPage "Change Vendor VAT Invoice")
    var
        InvoiceNo: Variant;
        VATBase: Variant;
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvoiceNo);
        LibraryVariableStorage.Dequeue(VATBase);
        LibraryVariableStorage.Dequeue(VATAmount);
        VendorVATInvoiceReportHandler.InvoiceNo.SetValue(InvoiceNo); // Vendor VAT Invoice No.
        VendorVATInvoiceReportHandler.InvoiceDate.SetValue(WorkDate());  // Vendor VAT Invoice Date
        VendorVATInvoiceReportHandler.InvoiceRcvdDate.SetValue(WorkDate());  // Vendor VAT Invoice Rcvd Date
        VendorVATInvoiceReportHandler.VATBase.SetValue(VATBase);
        VendorVATInvoiceReportHandler.VATAmt.SetValue(VATAmount);
        VendorVATInvoiceReportHandler.OK().Invoke();
    end;

    local procedure VerifyPurchVATSettlementGLCorrEntry(VATPostingSetup: Record "VAT Posting Setup"; VATEntryNo: Integer)
    var
        VATEntry: Record "VAT Entry";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
    begin
        VATEntry.Get(VATEntryNo);
        GLCorrespondenceEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        GLCorrespondenceEntry.FindLast();
        Assert.AreEqual(
          VATPostingSetup."Purchase VAT Account", GLCorrespondenceEntry."Debit Account No.",
          GLCorrespondenceEntry.FieldCaption("Debit Account No."));
        Assert.AreEqual(
          VATPostingSetup."Purch. VAT Unreal. Account", GLCorrespondenceEntry."Credit Account No.",
          GLCorrespondenceEntry.FieldCaption("Credit Account No."));
        Assert.AreEqual(
          VATEntry.Amount, GLCorrespondenceEntry.Amount, GLCorrespondenceEntry.FieldCaption(Amount));
    end;

}

