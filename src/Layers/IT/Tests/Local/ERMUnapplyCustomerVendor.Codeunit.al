codeunit 144158 "ERM Unapply Customer Vendor"
{
    //  1. Test to verify unapply Vendor Ledger Entry with Document Type Invoice after posting VAT Settlement.
    //  2. Test to verify unapply Vendor Ledger Entry with Document Type Refund after posting VAT Settlement.
    //  3. Test to verify unapply Vendor Ledger Entry with Document Type blank after posting VAT Settlement.
    //  4. Test to verify unapply Vendor Ledger Entry with Document Type Credit Memo after posting VAT Settlement.
    //  5. Test to verify unapply Vendor Ledger Entry with Document Type Payment after posting VAT Settlement.
    //  6. Test to verify unapply Customer Ledger Entry with Document Type Invoice after posting VAT Settlement.
    //  7. Test to verify unapply Customer Ledger Entry with Document Type Refund after posting VAT Settlement.
    //  8. Test to verify unapply Customer Ledger Entry with Document Type blank after posting VAT Settlement.
    //  9. Test to verify unapply Customer Ledger Entry with Document Type Credit Memo after posting VAT Settlement.
    // 10. Test to verify unapply Customer Ledger Entry with Document Type Payment after posting VAT Settlement.
    // 11. Test unapply Customer/Vendor LedgerEntry when Unrealized VAT is not involved
    // 
    // Covers Test Cases for WI - 346326
    // ---------------------------------------------------------------------------------------------------
    // Test Function Name                                                                          TFS ID
    // ---------------------------------------------------------------------------------------------------
    // UnapplyVendorAfterPostingVATSettlementDocTypeInvoice                                        217530
    // UnapplyVendorAfterPostingVATSettlementDocTypeRefund                                         217531
    // UnapplyVendorAfterPostingVATSettlementDocTypeBlank                                          217532
    // UnapplyVendorAfterPostingVATSettlementDocTypeCrMemo                                         217533
    // UnapplyVendorAfterPostingVATSettlementDocTypePayment                                        217534
    // UnapplyCustomerAfterPostingVATSettlementDocTypeInvoice                                      217535
    // UnapplyCustomerAfterPostingVATSettlementDocTypeRefund                                       217536
    // UnapplyCustomerAfterPostingVATSettlementDocTypeBlank                                        217537
    // UnapplyCustomerAfterPostingVATSettlementDocTypeCrMemo                                       217538
    // UnapplyCustomerAfterPostingVATSettlementDocTypePayment                                      217539
    // UnapplyVendorAfterPostingVATSettlementUnrealizedVATOff                                      73962
    // UnapplyCustomerAfterPostingVATSettlementUnrealizedVATOff                                    73962

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        VATPeriodTxt: Label '%1/%2', Comment = '%1 = FieldValue,%2 = FieldValue';
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyVendorEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendorAfterPostingVATSettlementDocTypeInvoice()
    var
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Vendor Ledger Entry with Document Type Invoice after posting VAT Settlement.
        Initialize();
        UnapplyVendorAfterPostingVATSettlement(
          PurchaseLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Invoice,
          -LibraryRandom.RandDec(10, 2), true);  // Taken random Amount.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyVendorEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendorAfterPostingVATSettlementDocTypeRefund()
    var
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Vendor Ledger Entry with Document Type Refund after posting VAT Settlement.
        Initialize();
        UnapplyVendorAfterPostingVATSettlement(
          PurchaseLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund,
          -LibraryRandom.RandDec(10, 2), true);  // Taken random Amount.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyVendorEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendorAfterPostingVATSettlementDocTypeBlank()
    var
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Vendor Ledger Entry with Document Type blank after posting VAT Settlement.
        Initialize();
        UnapplyVendorAfterPostingVATSettlement(
          PurchaseLine."Document Type"::Invoice, GenJournalLine."Document Type"::" ",
          LibraryRandom.RandDec(10, 2), true);  // Taken random Amount.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyVendorEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendorAfterPostingVATSettlementDocTypeCrMemo()
    var
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Vendor Ledger Entry with Document Type Credit Memo after posting VAT Settlement.
        Initialize();
        UnapplyVendorAfterPostingVATSettlement(
          PurchaseLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo",
          LibraryRandom.RandDec(10, 2), true);  // Taken random Amount.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyVendorEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendorAfterPostingVATSettlementDocTypePayment()
    var
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Vendor Ledger Entry with Document Type Payment after posting VAT Settlement.
        Initialize();
        UnapplyVendorAfterPostingVATSettlement(
          PurchaseLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          LibraryRandom.RandDec(10, 2), true);  // Taken random Amount.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyVendorEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyVendorAfterPostingVATSettlementUnrealizedVATOff()
    var
        PurchaseLine: Record "Purchase Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Vendor Ledger Entry with Document Type Payment after posting VAT Settlement.
        Initialize();
        UnapplyVendorAfterPostingVATSettlement(
          PurchaseLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          LibraryRandom.RandDec(10, 2), false);  // Taken random Amount.
    end;

    local procedure UnapplyVendorAfterPostingVATSettlement(DocumentType: Enum "Purchase Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        AppliesToDocNo: Code[20];
        VendorNo: Code[20];
        UnrealizedVATType: Option;
        JournalPostingDate: Date;
    begin
        // Setup: Post Purchase Document, run Calculate and Post VAT Settlement report, update VAT Period closed on Periodic Settlement VAT entry.
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(UnrealizedVAT, CalcDate('<CY - 1Y>', WorkDate()));  // TRUE for UnrealizedVAT, Last Settlement Date is set to last date of the previous year to Work Date.
        SetupPostingDateUnrealizedVATType(JournalPostingDate, UnrealizedVATType, UnrealizedVAT);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          UnrealizedVATType);
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        AppliesToDocNo :=
          CreateAndPostPurchaseDocument(DocumentType, VendorNo, VATPostingSetup."VAT Prod. Posting Group");
        RunCalcAndPostVATSettlementReport();
        UpdatePeriodicSettlementVATEntry();

        // Post Payment General.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::Payments, DocumentType2, GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        UpdateAndPostGeneralJournalLine(GenJournalLine, DocumentType, AppliesToDocNo, JournalPostingDate);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, AppliesToDocNo);

        // Exercise: Unapply Vendor Ledger Entry.
        VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendorLedgerEntry."Entry No.");

        // Verify: Verify Vendor Ledger Entries are successfully unapplied.
        VendorLedgerEntry.SetRange(Open, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, AppliesToDocNo);
        VendorLedgerEntry.SetRange(Open, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType2, GenJournalLine."Document No.");

        // Tear Down: Update VAT Posting Setup, General Ledger Setup and delete Periodic VAT Settlement entries.
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."Unrealized VAT Type");
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Unrealized VAT", GeneralLedgerSetup."Last Settlement Date");
        DeletePeriodicSettlementVATEntry(WorkDate());
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate()));  // '1M' required for one month next to Workdate
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyCustomerEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustomerAfterPostingVATSettlementDocTypeInvoice()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Customer Ledger Entry with Document Type Invoice after posting VAT Settlement.
        Initialize();
        UnapplyCustomerAfterPostingVATSettlement(
          SalesLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Invoice,
          LibraryRandom.RandDec(10, 2), true);  // Taken random Amount.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyCustomerEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustomerAfterPostingVATSettlementDocTypeRefund()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Customer Ledger Entry with Document Type Refund after posting VAT Settlement.
        Initialize();
        UnapplyCustomerAfterPostingVATSettlement(
          SalesLine."Document Type"::"Credit Memo", GenJournalLine."Document Type"::Refund,
          LibraryRandom.RandDec(10, 2), true);  // Taken random Amount.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyCustomerEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustomerAfterPostingVATSettlementDocTypeBlank()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Customer Ledger Entry with Document Type blank after posting VAT Settlement.
        Initialize();
        UnapplyCustomerAfterPostingVATSettlement(
          SalesLine."Document Type"::Invoice, GenJournalLine."Document Type"::" ",
          -LibraryRandom.RandDec(10, 2), true);  // Taken random Amount.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyCustomerEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustomerAfterPostingVATSettlementDocTypeCrMemo()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Customer Ledger Entry with Document Type Credit Memo after posting VAT Settlement.
        Initialize();
        UnapplyCustomerAfterPostingVATSettlement(
          SalesLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo",
          -LibraryRandom.RandDec(10, 2), true);  // Taken random Amount.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyCustomerEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustomerAfterPostingVATSettlementDocTypePayment()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Customer Ledger Entry with Document Type Payment after posting VAT Settlement.
        Initialize();
        UnapplyCustomerAfterPostingVATSettlement(
          SalesLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          -LibraryRandom.RandDec(10, 2), true);  // Taken random Amount.
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandler,UnapplyCustomerEntriesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyCustomerAfterPostingVATSettlementUnrealizedVATOff()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Test to verify unapply Customer Ledger Entry with Document Type Payment after posting VAT Settlement.
        Initialize();
        UnapplyCustomerAfterPostingVATSettlement(
          SalesLine."Document Type"::Invoice, GenJournalLine."Document Type"::Payment,
          -LibraryRandom.RandDec(10, 2), false);  // Taken random Amount.
    end;

    local procedure UnapplyCustomerAfterPostingVATSettlement(DocumentType: Enum "Sales Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; Amount: Decimal; UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        AppliesToDocNo: Code[20];
        CustomerNo: Code[20];
        UnrealizedVATType: Option;
        JournalPostingDate: Date;
    begin
        // Setup: Post Sales Document, Run Calculate and Post VAT Settlement report. Update VAT Period closed on Periodic Settlement VAT entry.
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(UnrealizedVAT, CalcDate('<CY - 1Y>', WorkDate()));  // TRUE for UnrealizedVAT, Last Settlement Date is set to last date of the previous year to Work Date.
        SetupPostingDateUnrealizedVATType(JournalPostingDate, UnrealizedVATType, UnrealizedVAT);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
          UnrealizedVATType);
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        AppliesToDocNo :=
          CreateAndPostSalesDocument(DocumentType, CustomerNo, VATPostingSetup."VAT Prod. Posting Group");  // Use Blank value for Applies To Doc No.
        RunCalcAndPostVATSettlementReport();
        UpdatePeriodicSettlementVATEntry();

        // Post Cash Receipt Journal.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalTemplate.Type::"Cash Receipts", DocumentType2,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        UpdateAndPostGeneralJournalLine(GenJournalLine, DocumentType, AppliesToDocNo, JournalPostingDate);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, AppliesToDocNo);

        // Exercise: Unapply Customer Ledger Entry.
        CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");

        // Verify: Error on unapply Customer Ledger Entry.
        CustLedgerEntry.SetRange(Open, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, AppliesToDocNo);
        CustLedgerEntry.SetRange(Open, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType2, GenJournalLine."Document No.");

        // Tear Down: Update VAT Posting Setup, General Ledger Setup and delete Periodic VAT Settlement entries.
        UpdateVATPostingSetup(
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."Unrealized VAT Type");
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Unrealized VAT", GeneralLedgerSetup."Last Settlement Date");
        DeletePeriodicSettlementVATEntry(WorkDate());
        DeletePeriodicSettlementVATEntry(CalcDate('<1M>', WorkDate()));  // '1M' required for one month next to Workdate
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        isInitialized := true;
        Commit();
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATProdPostingGroup), LibraryRandom.RandDec(10, 2));  // Taken Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocument(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATProdPostingGroup), LibraryRandom.RandDec(10, 2));  // Taken Random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Type: Enum "Gen. Journal Template Type"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, Type);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure SetupPostingDateUnrealizedVATType(var JournalPostingDate: Date; var UnrealizedVATType: Option; UnrealizedVAT: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if UnrealizedVAT then begin
            JournalPostingDate := CalcDate('<1M>', WorkDate());
            UnrealizedVATType := VATPostingSetup."Unrealized VAT Type"::Percentage;
        end else begin
            JournalPostingDate := WorkDate();
            UnrealizedVATType := VATPostingSetup."Unrealized VAT Type"::" ";
        end;
    end;

    local procedure DeletePeriodicSettlementVATEntry(PeriodDate: Date)
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
        FindPeriodicSettlementVATEntry(PeriodicSettlementVATEntry, PeriodDate);
        PeriodicSettlementVATEntry.Delete(true);
    end;

#if not CLEAN27
    local procedure FindPeriodicSettlementVATEntry(var PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry"; PeriodDate: Date)
    begin
        PeriodicSettlementVATEntry.SetRange(
          "VAT Period", StrSubstNo(VATPeriodTxt, Date2DMY(PeriodDate, 3), ConvertStr(Format(Date2DMY(PeriodDate, 2), 2), ' ', '0')));  // Value Zero required for VAT Period.
        PeriodicSettlementVATEntry.FindFirst();
    end;
#else
    local procedure FindPeriodicSettlementVATEntry(var PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry"; PeriodDate: Date)
    begin
        PeriodicSettlementVATEntry.SetRange(
          "VAT Period", StrSubstNo(VATPeriodTxt, Date2DMY(PeriodDate, 3), ConvertStr(Format(Date2DMY(PeriodDate, 2), 2), ' ', '0')));  // Value Zero required for VAT Period.
        PeriodicSettlementVATEntry.FindFirst();
    end;
#endif

    local procedure GetStartingDate(): Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(CalcDate('<1D>', GeneralLedgerSetup."Last Settlement Date"));  // 1D is required as Starting date for Calc. and Post VAT Settlement report should be the next Day of Last Settlement Date.
    end;

    local procedure RunCalcAndPostVATSettlementReport()
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryVariableStorage.Enqueue(GLAccount."No.");  // Enqueue for CalcAndPostVATSettlementRequestPageHandler.
        Commit();  // Commit required to run the report
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");
    end;

    local procedure UpdateAndPostGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; PostingDate: Date)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Validate("Posting Date", PostingDate);  // Required for test case to set Posting Date as next month to workdate.
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure UpdateGeneralLedgerSetup(UnrealizedVAT: Boolean; LastSettlementDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Validate("Last Settlement Date", LastSettlementDate);
        GeneralLedgerSetup.Modify(true)
    end;

    local procedure UpdateVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; UnrealizedVATType: Option)
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdatePeriodicSettlementVATEntry()
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
        FindPeriodicSettlementVATEntry(PeriodicSettlementVATEntry, WorkDate());
        PeriodicSettlementVATEntry.Validate("VAT Period Closed", false);
        PeriodicSettlementVATEntry.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        AccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(AccountNo);
        CalcAndPostVATSettlement.StartingDate.SetValue(GetStartingDate());
        CalcAndPostVATSettlement.SettlementAcc.SetValue(AccountNo);
        CalcAndPostVATSettlement.GLGainsAccount.SetValue(AccountNo);
        CalcAndPostVATSettlement.GLLossesAccount.SetValue(AccountNo);
        CalcAndPostVATSettlement.DocumentNo.SetValue(AccountNo);
        CalcAndPostVATSettlement.Post.SetValue(true);
        CalcAndPostVATSettlement.ShowVATEntries.SetValue(true);
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesModalPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyVendorEntriesModalPageHandler(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke();
    end;
}

