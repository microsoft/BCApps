codeunit 147305 "Cartera Posting"
{
    // // [FEATURE] [Cartera]
    // 
    // Tests
    // 
    //   1. SalesUnrealVATEntryBillToInvSeveralVATGroups
    //   2. SalesUnrealVATPayToBillFullAmountAndApplyPostedEntries
    //   3. SalesUnrealVATHigherPayToBillAndApplyPostedEntries
    //   4. SalesUnrealVATLowerPayToBillAndApplyPostedEntries
    //   5. SalesUnrealVATApplyFromJournalPayToBillFullAmount
    //   6. SalesUnrealVATApplyFromJournalHigherPayToBill
    //   7. SalesUnrealVATApplyFromJournalLowerPayToBill
    //   8. SalesUnrealVATDistributionFirstInstallment
    //   9. SalesUnrealVATDistributionLastInstallment
    //  10. SalesUnrealVATSeveralPaysToBillAndApplyPostedEntries
    //  11. SalesUnrealVATApplyFromJournalSeveralPaysToBill
    //  12. SalesUnrealVATPayToSeveralBillsAndApplyPostedEntries
    //  13. SalesUnrealVATApplyFromJournalPayToSeveralBills
    //  14. SalesUnrealVATApplyFromJournalPayToDoubleBill
    //  15. SalesUnrealVATPayToDoubleBillAndApplyPostedEntries
    //  16. PurchUnrealVATEntryBillToInvSeveralVATGroups
    //  17. PurchUnrealVATPayToBillFullAmountAndApplyPostedEntries
    //  18. PurchUnrealVATHigherPayToBillAndApplyPostedEntries
    //  19. PurchUnrealVATLowerPayToBillAndApplyPostedEntries
    //  20. PurchUnrealVATApplyFromJournalPayToBillFullAmount
    //  21. PurchUnrealVATApplyHigherPayToBill
    //  22. PurchUnrealVATApplyLowerPayToBill
    //  23. PurchUnrealVATDistributionFirstInstallment
    //  24. PurchUnrealVATDistributionLastInstallment
    //  25. PurchUnrealVATSeveralPaysToBillAndApplyPostedEntries
    //  26. PurchUnrealVATApplyFromJournalSeveralPaysToBill
    //  27. PurchUnrealVATPayToSeveralBillsAndApplyPostedEntries
    //  28. PurchUnrealVATApplyFromJournalPayToSeveralBills
    //  29. PurchUnrealVATApplyFromJournalPayToDoubleBill
    //  30. PurchUnrealVATPayToDoubleBillAndApplyPostedEntries
    //  31. Test posting Cartera Journal Lines, which are applied to several Customer Ledger Entries being one of them a Bill at the same time.
    //  32. Test posting Cartera Journal Lines, which are applied to several Vendor Ledger Entries being one of them a Bill at the same time.
    //  33. Test posting Payment Journal Line with non-empty Currency which is applied to Bill
    //  34. Test posting Cash Receipt Journal Line with non-empty Currency which is applied to Bill
    //  35. Check that settle docs. in posted bill group can be posted successfully using bank account with dimension
    //  36. Check that bill group with "Discount" Dealing Type can be posted successfully using bank account with dimension
    //  37. Check VAT entries when Cr. Memo applied to Invoice and Unrealized VAT involved (Sales)
    //  38. Check VAT entries when Cr. Memo applied to Invoice and Unrealized VAT involved (Purchase)
    //  39. Try to partially settle document with missing dimension in posted bill group.
    //  40. Try to redraw settled document with missing dimension in posted bill group.
    //  41. Try to redraw settled document with missing dimension in closed bill group.
    //  42. Try to reject document with missing dimension in posted bill group with discount dealing type.
    //  43. Try to redraw rejected document with missing dimension in posted bill group with discount dealing type.
    //  44. Try to redraw settled document with missing dimension in closed bill group with discount dealing type.
    //  45. Try to partially settle document with missing dimension in posted payment order.
    //  46. Try to redraw settled document with missing dimension in posted payment order.
    //  47. Try to redraw settled document with missing dimension in closed payment order.
    // 
    // --------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                      TFS ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // SalesUnrealVATEntryBillToInvSeveralVATGroups                                                                            325186
    // SalesUnrealVATPayToBillFullAmountAndApplyPostedEntries
    // SalesUnrealVATHigherPayToBillAndApplyPostedEntries
    // SalesUnrealVATLowerPayToBillAndApplyPostedEntries
    // SalesUnrealVATApplyFromJournalPayToBillFullAmount
    // SalesUnrealVATApplyFromJournalHigherPayToBill
    // SalesUnrealVATApplyFromJournalLowerPayToBill
    // SalesUnrealVATDistributionFirstInstallment
    // SalesUnrealVATDistributionLastInstallment
    // SalesUnrealVATSeveralPaysToBillAndApplyPostedEntries
    // SalesUnrealVATApplyFromJournalSeveralPaysToBill
    // SalesUnrealVATPayToSeveralBillsAndApplyPostedEntries
    // SalesUnrealVATApplyFromJournalPayToSeveralBills
    // SalesUnrealVATApplyFromJournalPayToDoubleBill
    // SalesUnrealVATPayToDoubleBillAndApplyPostedEntries
    // PurchUnrealVATEntryBillToInvSeveralVATGroups
    // PurchUnrealVATPayToBillFullAmountAndApplyPostedEntries
    // PurchUnrealVATHigherPayToBillAndApplyPostedEntries
    // PurchUnrealVATLowerPayToBillAndApplyPostedEntries
    // PurchUnrealVATApplyFromJournalPayToBillFullAmount
    // PurchUnrealVATApplyHigherPayToBill
    // PurchUnrealVATApplyLowerPayToBill
    // PurchUnrealVATDistributionFirstInstallment
    // PurchUnrealVATDistributionLastInstallment
    // PurchUnrealVATSeveralPaysToBillAndApplyPostedEntries
    // PurchUnrealVATApplyFromJournalSeveralPaysToBill
    // PurchUnrealVATPayToSeveralBillsAndApplyPostedEntries
    // PurchUnrealVATApplyFromJournalPayToSeveralBills
    // PurchUnrealVATApplyFromJournalPayToDoubleBill
    // PurchUnrealVATPayToDoubleBillAndApplyPostedEntries
    // --------------------------------------------------------------------------------------------------------------------------------
    // 
    // --------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                      TFS ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // SalesPostEntriesAppliedToSeveralWithBill                                                                                348140
    // PurchPostEntriesAppliedToSeveralWithBill                                                                                348140
    // 
    // --------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                      TFS ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // SalesPostPaymentWithCurrencyAppliedToBill                                                                               349783
    // 
    // SalesSettleDocInPostBillGrWithDimension                                                                                 85211
    // SalesBillGroupDiscountDealingTypeWithDimension                                                                          85211
    // SalesCreditMemoApplyToInvoice                                                                                           89051
    // PurchaseCreditMemoApplyToInvoice                                                                                        89051
    // 
    // --------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                      TFS ID
    // --------------------------------------------------------------------------------------------------------------------------------
    // SalesPartSettleDocInPostBillGrWithDimension                                                                             90510
    // SalesRedrawDocInPostBillGrWithDimension                                                                                 90510
    // SalesRedrawDocInClosedBillGrWithDimension                                                                               90510
    // SalesRejectDocInPostBillGrDiscountWithDim                                                                               90510
    // SalesRedrawRejectedDocInPostBillGrDiscountWithDim                                                                       90510
    // SalesRedrawDocInClosedBillGrDiscountWithDim                                                                             90510
    // PurchPartSettleDocInPostBillGrWithDimension                                                                             90510
    // PurchRedrawDocInPostBillGrWithDimension                                                                                 90510

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        Assert: Codeunit Assert;
        Text001: Label 'Customer Ledger verification failed. One of the Customer Ledger Entries was not entered correctly.';
        VATEntryError: Label 'There must be no other posted VAT Entries.';
        AmountErr: Label '%1 must be %2 in %3 %4 %5.';
        GLEntriesNotExistErr: Label 'G/L Entries do not exist!';
        GLEntriesWrongCountErr: Label 'Number of G/L Entries is wrong.';
        IncorrectDimValueErr: Label 'Incorrect dimension value in G/L Entry %1.';
        FieldErr: Label '%1 value is wrong in %2';
        JournalMustBePostedMsg: Label 'Please, post the journal lines. Otherwise, inconsistences can appear in your data.';
        CarteraJournalErr: Label 'Cartera Journal cannot be posted.';
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('ReceivablePostOnlyHandler,RejectDocsHandler,RejectDocumentMessageHandler,RedrawDocumentHandler,CarteraJournalHandler')]
    [Scope('OnPrem')]
    procedure TestPostRedrawnInvoiceInBillGroup()
    var
        BillGroup: Record "Bill Group";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        InvoiceNo1: Code[20];
        InvoiceNo2: Code[20];
        Amount1: Decimal;
        CustLedgerEntryNo1: Integer;
    begin
        // Related to bug TFS 268625
        // Test scenario redrawing and posting a Sales Invoice from Bill Group with two Sales Invoices
        // Expected Result - Sales Invoice has been posted and two more Customer Ledger Entries created
        Initialize();

        // Pre-Setup
        CreateCustomer(Customer);
        InvoiceNo1 := CreateAndPostSalesInvoice(Customer);
        InvoiceNo2 := CreateAndPostSalesInvoice(Customer);
        SalesInvoiceHeader.Get(InvoiceNo1);
        Amount1 := SalesInvoiceHeader.Amount;

        // Setup
        CreateBillGroup(BillGroup);
        AddDocToBillGroup(BillGroup."No.", InvoiceNo1);
        AddDocToBillGroup(BillGroup."No.", InvoiceNo2);
        CustLedgerEntryNo1 := GetCustLedgerEntryNo(InvoiceNo1);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // Exercise and Verify
        RejectDocument(CustLedgerEntryNo1);
        RedrawDocument(CustLedgerEntryNo1);

        VerifyCustomerLedgerEntry(
          Customer, CustLedgerEntry."Document Type"::Bill, InvoiceNo1, CustLedgerEntry."Document Status"::Redrawn, Amount1, 0);
        VerifyCustomerLedgerEntry(
          Customer, CustLedgerEntry."Document Type"::" ", InvoiceNo1, CustLedgerEntry."Document Status"::" ", -Amount1, 0);
        VerifyCustomerLedgerEntry(
          Customer, CustLedgerEntry."Document Type"::Bill, InvoiceNo1, CustLedgerEntry."Document Status"::Open, Amount1, Amount1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATEntryPayApplToInv()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // Check Unrealized VAT Entries when post Payment with application to
        // one of the sales invoices that was posted within the same transaction no.
        UnrealVATEntryWhenPostEntryWithAppl(GenJnlLine."Account Type"::Customer, GenJnlLine."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATEntryPayApplToInv()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // Check Unrealized VAT Entries when post Payment with application to
        // one of the purchase invoices that was posted within the same transaction no.

        UnrealVATEntryWhenPostEntryWithAppl(GenJnlLine."Account Type"::Vendor, GenJnlLine."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATEntryRefundApplToCrMemo()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // Check Unrealized VAT Entries when post Refund with application to
        // one of the sales credit memos that was posted within the same transaction no.

        UnrealVATEntryWhenPostEntryWithAppl(GenJnlLine."Account Type"::Customer, GenJnlLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATEntryRefundApplToCrMemo()
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // Check Unrealized VAT Entries when post Refund with application to
        // one of the purchase credit memos that was posted within the same transaction no.

        UnrealVATEntryWhenPostEntryWithAppl(GenJnlLine."Account Type"::Vendor, GenJnlLine."Document Type"::"Credit Memo");
    end;

    local procedure UnrealVATEntryWhenPostEntryWithAppl(AccType: Enum "Gen. Journal Account Type"; DocType: Enum "Gen. Journal Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateUnrealVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());

        CreatePostPairedGenJnlLine(GenJnlLine, DocType, AccType, VATPostingSetup);

        VerifyVATEntryTransaction(GenJnlLine."Posting Date", GenJnlLine."Document No.");

        UpdateUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type",
          VATPostingSetup."Purch. VAT Unreal. Account", VATPostingSetup."Sales VAT Unreal. Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATEntryBillToInvSeveralVATGroups()
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        VATProdPostingGroupCode: array[2] of Code[20];
        CustNo: Code[20];
        InvoiceNo: Code[20];
        BillNo: Code[20];
        PayNo: Code[20];
        TotalAmtInclVAT: Decimal;
        LineAmtInclVAT: array[2] of Decimal;
        i: Integer;
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATBusinessPostingGroup(VATBusPostingGroup);
        CustNo :=
          CreateCustWithPaymentTermsAndVATGroup(PaymentTerms."VAT distribution"::Proportional, VATBusPostingGroup.Code);
        for i := 1 to 2 do
            VATProdPostingGroupCode[i] :=
              CreateVATPostingSetup(VATBusPostingGroup.Code);

        InvoiceNo :=
          CreatePostSalesInvoiceWithSeveralVATGroups(
            LineAmtInclVAT,
            CustNo,
            VATProdPostingGroupCode);
        TotalAmtInclVAT :=
          LineAmtInclVAT[1] + LineAmtInclVAT[2];
        BillNo :=
          CreateApplyPostBillToInvoice(GenJnlLine."Account Type"::Customer, CustNo,
            TotalAmtInclVAT, InvoiceNo);
        PayNo :=
          CreateApplyPostPaymentToBill(GenJnlLine."Account Type"::Customer, CustNo, InvoiceNo, BillNo,
            -TotalAmtInclVAT);

        for i := 1 to ArrayLen(VATProdPostingGroupCode) do
            VerifyGLAndVATEntriesByVATPostingSetup(
              VATBusPostingGroup.Code, VATProdPostingGroupCode[i], CustNo, PayNo, LineAmtInclVAT[i], -TotalAmtInclVAT);

        for i := 1 to ArrayLen(VATProdPostingGroupCode) do begin
            VATPostingSetup.Get(VATBusPostingGroup.Code, VATProdPostingGroupCode[i]);
            VATPostingSetup.Delete();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATPayToBillFullAmountAndApplyPostedEntries()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := 0;
        SalesUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATHigherPayToBillAndApplyPostedEntries()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := -LibraryRandom.RandDec(10, 2);
        SalesUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATLowerPayToBillAndApplyPostedEntries()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := LibraryRandom.RandDec(10, 2);
        SalesUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATApplyFromJournalPayToBillFullAmount()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := 0;
        SalesUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATApplyFromJournalHigherPayToBill()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := -LibraryRandom.RandDec(10, 2);
        SalesUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATApplyFromJournalLowerPayToBill()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := LibraryRandom.RandDec(10, 2);
        SalesUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATDistributionFirstInstallment()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := LibraryRandom.RandDec(10, 2);
        SalesUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::"First Installment", PayAmountDiff, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATDistributionLastInstallment()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := LibraryRandom.RandDec(10, 2);
        SalesUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::"Last Installment", PayAmountDiff, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATSeveralPaysToBillAndApplyPostedEntries()
    begin
        SalesUnrealVATSeveralPaysToBill(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATApplyFromJournalSeveralPaysToBill()
    begin
        SalesUnrealVATSeveralPaysToBill(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATPayToSeveralBillsAndApplyPostedEntries()
    begin
        exit; // VSTF 54637
        SalesUnrealVATPayToSeveralBills(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATApplyFromJournalPayToSeveralBills()
    begin
        exit; // VSTF 54637
        SalesUnrealVATPayToSeveralBills(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATApplyFromJournalPayToDoubleBill()
    begin
        SalesUnrealVATPayToDoubleBill(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnrealVATPayToDoubleBillAndApplyPostedEntries()
    begin
        SalesUnrealVATPayToDoubleBill(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATEntryBillToInvSeveralVATGroups()
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        VATProdPostingGroupCode: array[2] of Code[20];
        VendNo: Code[20];
        InvoiceNo: Code[20];
        BillNo: Code[20];
        PayNo: Code[20];
        TotalAmtInclVAT: Decimal;
        LineAmtInclVAT: array[2] of Decimal;
        i: Integer;
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATBusinessPostingGroup(VATBusPostingGroup);
        VendNo :=
          CreateVendWithPaymentTermsAndVATGroup(PaymentTerms."VAT distribution"::Proportional, VATBusPostingGroup.Code);
        for i := 1 to 2 do
            VATProdPostingGroupCode[i] :=
              CreateVATPostingSetup(VATBusPostingGroup.Code);

        InvoiceNo :=
          CreatePostPurchInvoiceWithSeveralVATGroups(
            LineAmtInclVAT,
            VendNo,
            VATProdPostingGroupCode);
        TotalAmtInclVAT :=
          LineAmtInclVAT[1] + LineAmtInclVAT[2];
        BillNo :=
          CreateApplyPostBillToInvoice(GenJnlLine."Account Type"::Vendor, VendNo,
            -TotalAmtInclVAT, InvoiceNo);
        PayNo :=
          CreateApplyPostPaymentToBill(GenJnlLine."Account Type"::Vendor, VendNo, InvoiceNo, BillNo,
            TotalAmtInclVAT);

        for i := 1 to ArrayLen(VATProdPostingGroupCode) do
            VerifyGLAndVATEntriesByVATPostingSetup(
              VATBusPostingGroup.Code, VATProdPostingGroupCode[i], VendNo, PayNo, -LineAmtInclVAT[i], TotalAmtInclVAT);

        for i := 1 to ArrayLen(VATProdPostingGroupCode) do begin
            VATPostingSetup.Get(VATBusPostingGroup.Code, VATProdPostingGroupCode[i]);
            VATPostingSetup.Delete();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATPayToBillFullAmountAndApplyPostedEntries()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := 0;
        PurchUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATHigherPayToBillAndApplyPostedEntries()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := -LibraryRandom.RandDec(10, 2);
        PurchUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATLowerPayToBillAndApplyPostedEntries()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := LibraryRandom.RandDec(10, 2);
        PurchUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATApplyFromJournalPayToBillFullAmount()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := 0;
        PurchUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATApplyFromJournalHigherPayToBill()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := -LibraryRandom.RandDec(10, 2);
        PurchUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATApplyFromJournalLowerPayToBill()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := LibraryRandom.RandDec(10, 2);
        PurchUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::Proportional, PayAmountDiff, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATDistributionFirstInstallment()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := LibraryRandom.RandDec(10, 2);
        PurchUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::"First Installment", PayAmountDiff, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATDistributionLastInstallment()
    var
        PaymentTerms: Record "Payment Terms";
        PayAmountDiff: Decimal;
    begin
        PayAmountDiff := LibraryRandom.RandDec(10, 2);
        PurchUnrealVATPayToBill(
          PaymentTerms."VAT distribution"::"Last Installment", PayAmountDiff, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATSeveralPaysToBillAndApplyPostedEntries()
    begin
        PurchUnrealVATSeveralPaysToBill(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATApplyFromJournalSeveralPaysToBill()
    begin
        PurchUnrealVATSeveralPaysToBill(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATPayToSeveralBillsAndApplyPostedEntries()
    begin
        PurchUnrealVATPayToSeveralBills(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATApplyFromJournalPayToSeveralBills()
    begin
        PurchUnrealVATPayToSeveralBills(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATApplyFromJournalPayToDoubleBill()
    begin
        PurchUnrealVATPayToDoubleBill(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchUnrealVATPayToDoubleBillAndApplyPostedEntries()
    begin
        PurchUnrealVATPayToDoubleBill(false);
    end;

    [Test]
    [HandlerFunctions('ApplyCustEntriesHandler')]
    [Scope('OnPrem')]
    procedure SalesPostEntriesAppliedToSeveralWithBill()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // Related to bug TFS 348140
        // Test posting Cartera Journal Lines, which are applied to several
        // Customer Ledger Entries being one of them a Bill at the same time.
        Initialize();

        // Setup
        CreateCustomer(Customer);

        // Exercise
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(Customer));
        SalesInvoiceHeader.CalcFields(Amount);
        DocumentNo := CreatePostDocsForCustVend(
            GenJnlLine."Account Type"::Customer, Customer."No.", -SalesInvoiceHeader.Amount / 2);

        // Verify
        VerifyGLEntryExists(DocumentNo, WorkDate());
    end;

    [Test]
    [HandlerFunctions('ApplyVendEntriesHandler')]
    [Scope('OnPrem')]
    procedure PurchPostEntriesAppliedToSeveralWithBill()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // Related to bug TFS 348140
        // Test posting Cartera Journal Lines, which are applied to several
        // Vendor Ledger Entries being one of them a Bill at the same time.
        Initialize();

        // Setup
        CreateVendor(Vendor);

        // Exercise
        PurchInvHeader.Get(CreateAndPostPurchInvoice(Vendor));
        PurchInvHeader.CalcFields(Amount);
        DocumentNo := CreatePostDocsForCustVend(
            GenJnlLine."Account Type"::Vendor, Vendor."No.", PurchInvHeader.Amount / 2);

        // Verify
        VerifyGLEntryExists(DocumentNo, WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPostPaymentWithCurrencyAppliedToBill()
    var
        GenJnlLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Currency: Record Currency;
        DocumentNo: Code[20];
    begin
        // Related to bug TFS 349783 and TFS 298727
        // Test posting Payment Journal Line with non-empty Currency which is applied to Bill
        Initialize();

        // Setup
        ClearAddReportingCurrency();
        CreateCustomer(Customer);
        LibraryERM.FindCurrency(Currency);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify();

        // Exercise
        SalesInvoiceHeader.Get(CreateAndPostSalesInvoice(Customer));
        SalesInvoiceHeader.CalcFields(Amount);
        DocumentNo :=
          CreateApplyPostPaymentToBill(
            GenJnlLine."Account Type"::Customer, Customer."No.",
            SalesInvoiceHeader."No.", '1', -SalesInvoiceHeader.Amount); // Bill No always 1

        // Verify
        VerifyGLEntryCount(DocumentNo, WorkDate(), 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SettleDocsInPostedBillGroupRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesSettleDocInPostBillGrWithDimension()
    var
        BillGroup: Record "Bill Group";
        BankAccNo: Code[20];
    begin
        // Check that settle docs. in posted bill group can be posted successfully using bank account with dimension

        SetupBillGroupWithBankAccDimension(BillGroup, BankAccNo, BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        RunSettleDocs(BankAccNo);
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesBillGroupDiscountDealingTypeWithDimension()
    var
        BillGroup: Record "Bill Group";
        BankAccNo: Code[20];
    begin
        // Check that bill group with "Discount" Dealing Type can be posted successfully using bank account with dimension

        SetupBillGroupWithBankAccDimension(BillGroup, BankAccNo, BillGroup."Dealing Type"::Discount);
        Commit();
        EnqueueCarteraGenJnlBatch();
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoApplyToInvoice()
    var
        SalesLine: Record "Sales Line";
        PaymentTerms: Record "Payment Terms";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        AppliedDocumentNo: Code[20];
    begin
        // Check VAT entries when Cr. Memo applied to Invoice and Unrealized VAT involved
        Initialize();

        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);

        DocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine, SalesLine."Document Type"::Invoice,
            CreateCustWithPaymentTermsAndVATGroup(PaymentTerms."VAT distribution"::Proportional, VATBusinessPostingGroup.Code),
            CreateItemWithVATGroup(CreateVATPostingSetup(VATBusinessPostingGroup.Code)));
        AppliedDocumentNo := ApplyPostSalesCreditMemoToInvoice(SalesLine, DocumentNo);

        VerifyAppliedVATEntries(
          VATEntry."Document Type"::Invoice, DocumentNo, VATEntry."Document Type"::"Credit Memo", AppliedDocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoApplyToInvoice()
    var
        PurchaseLine: Record "Purchase Line";
        PaymentTerms: Record "Payment Terms";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        AppliedDocumentNo: Code[20];
    begin
        // Check VAT entries when Cr. Memo applied to Invoice and Unrealized VAT involved
        Initialize();

        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);

        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, CreateVendWithPaymentTermsAndVATGroup(PaymentTerms."VAT distribution"::Proportional, VATBusinessPostingGroup.Code),
            CreateItemWithVATGroup(CreateVATPostingSetup(VATBusinessPostingGroup.Code)));
        AppliedDocumentNo := ApplyPostPurchaseCreditMemoToInvoice(PurchaseLine, DocumentNo);

        VerifyAppliedVATEntries(
          VATEntry."Document Type"::Invoice, DocumentNo, VATEntry."Document Type"::"Credit Memo", AppliedDocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,PartialSettlReceivableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesPartSettleDocInPostBillGrWithDimension()
    var
        BillGroup: Record "Bill Group";
        BankAccNo: Code[20];
    begin
        // Try to partially settle document with missing dimension in posted bill group.

        SetupBillGroupWithBankAccDimension(BillGroup, BankAccNo, BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        PartiallySettleDocument(BankAccNo);
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,SettleDocsInPostedBillGroupRequestPageHandler,RedrawReceivableBillsRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRedrawDocInPostBillGrWithDimension()
    var
        BillGroup: Record "Bill Group";
        BankAccNo: Code[20];
    begin
        // Try to redraw settled document with missing dimension in posted bill group.

        SetupBillGroupWithBankAccDimension(BillGroup, BankAccNo, BillGroup."Dealing Type"::Collection);
        AddInvoiceToBillGroup(BillGroup);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        SettleDocument(BankAccNo);
        RedrawDocument(GetCustVendLedgerEntryNoWithPostedCarteraDoc(GetPostedCarteraDocNo(BankAccNo)));
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,SettleDocsInPostedBillGroupRequestPageHandler,RedrawReceivableBillsRequestPageHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRedrawDocInClosedBillGrWithDimension()
    var
        BillGroup: Record "Bill Group";
        BankAccNo: Code[20];
    begin
        // Try to redraw settled document with missing dimension in closed bill group.

        SetupBillGroupWithBankAccDimension(BillGroup, BankAccNo, BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        SettleDocument(BankAccNo);
        RedrawDocument(GetCustVendLedgerEntryNoWithClosedCarteraDoc(GetClosedCarteraDocNo(BankAccNo)));
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,PostBillGroupRequestPageHandler,RejectDocsHandler,CarteraJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRejectDocInPostBillGrDiscountWithDim()
    var
        BillGroup: Record "Bill Group";
        BankAccNo: Code[20];
    begin
        // Try to reject document with missing dimension in posted bill group with discount dealing type.

        SetupBillGroupWithBankAccDimension(BillGroup, BankAccNo, BillGroup."Dealing Type"::Discount);
        Commit();
        EnqueueCarteraGenJnlBatch();
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        RejectDocument(GetCustVendLedgerEntryNoWithPostedCarteraDoc(GetPostedCarteraDocNo(BankAccNo)));
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,PostBillGroupRequestPageHandler,RejectDocsHandler,CarteraJournalModalPageHandler,RedrawReceivableBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRedrawRejectedDocInPostBillGrDiscountWithDim()
    var
        BillGroup: Record "Bill Group";
        BankAccNo: Code[20];
    begin
        // Try to redraw rejected document with missing dimension in posted bill group with discount dealing type.

        SetupBillGroupWithBankAccDimension(BillGroup, BankAccNo, BillGroup."Dealing Type"::Discount);
        AddInvoiceToBillGroup(BillGroup);
        Commit();
        EnqueueCarteraGenJnlBatch();
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        RejectDocument(GetCustVendLedgerEntryNoWithPostedCarteraDoc(GetPostedCarteraDocNo(BankAccNo)));
        RedrawDocument(GetCustVendLedgerEntryNoWithPostedCarteraDoc(GetPostedCarteraDocNo(BankAccNo)));
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,PostBillGroupRequestPageHandler,CarteraJournalModalPageHandler,SettleDocsInPostedBillGroupRequestPageHandler,RedrawReceivableBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRedrawDocInClosedBillGrDiscountWithDim()
    var
        BillGroup: Record "Bill Group";
        BankAccNo: Code[20];
    begin
        // Try to redraw settled document with missing dimension in closed bill group with discount dealing type.

        SetupBillGroupWithBankAccDimension(BillGroup, BankAccNo, BillGroup."Dealing Type"::Discount);
        Commit();
        EnqueueCarteraGenJnlBatch();
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        SettleDocument(BankAccNo);
        RedrawDocument(GetCustVendLedgerEntryNoWithClosedCarteraDoc(GetClosedCarteraDocNo(BankAccNo)));
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,PartialSettlPayableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchPartSettleDocInPostBillGrWithDimension()
    var
        PaymentOrder: Record "Payment Order";
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
        BankAccNo: Code[20];
    begin
        // Try to partially settle document with missing dimension in posted payment order.

        SetupPaymentOrderWithBankAccDimension(PaymentOrder, BankAccNo);
        POPostAndPrint.PayablePostOnly(PaymentOrder);
        PartiallySettlePurchDocument(BankAccNo);
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,SettleDocsInPostedPaymentOrderRequestPageHandler,RedrawPayableBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchRedrawDocInPostBillGrWithDimension()
    var
        PaymentOrder: Record "Payment Order";
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
        BankAccNo: Code[20];
    begin
        // Try to redraw settled document with missing dimension in posted payment order.

        SetupPaymentOrderWithBankAccDimension(PaymentOrder, BankAccNo);
        AddInvoiceToPaymentOrder(PaymentOrder);
        POPostAndPrint.PayablePostOnly(PaymentOrder);
        SettlePurchDocument(BankAccNo);
        RedrawPurchDocument(GetCustVendLedgerEntryNoWithPostedCarteraDoc(GetPostedCarteraDocNo(BankAccNo)));
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,SettleDocsInPostedPaymentOrderRequestPageHandler,RedrawPayableBillsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchRedrawDocInClosedBillGrWithDimension()
    var
        PaymentOrder: Record "Payment Order";
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
        BankAccNo: Code[20];
    begin
        // Check

        SetupPaymentOrderWithBankAccDimension(PaymentOrder, BankAccNo);
        POPostAndPrint.PayablePostOnly(PaymentOrder);
        SettlePurchDocument(BankAccNo);
        RedrawPurchDocument(GetCustVendLedgerEntryNoWithClosedCarteraDoc(GetClosedCarteraDocNo(BankAccNo)));
        VerifyDefDimOfBankAccExistInGLEntry(BankAccNo);
    end;

    [Test]
    [HandlerFunctions('ReceivablePostOnlyHandler,MessageHandler,RedrawDocumentWithSpecificBatchHandler,CarteraJournalCheckBatchHandler')]
    [Scope('OnPrem')]
    procedure OpenCarteraJournalWithSelectedBatchFromRedrawReceivablesBills()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        CustLedgerEntryNo: Integer;
    begin
        // [SCENARIO 362553] Open Cartera Journal with Batch selected in Rewraw Receivables Bills job

        Initialize();
        // [GIVEN] Default Cartera General Journal Batch
        CreateCarteraGenJnlTemplateWithBatch(GenJournalBatch);
        // [GIVEN] Second Cartera General Journal Batch "X"
        // Text code to prevent batch removal after posting
        CreateGenJnlBatchWithTextCode(GenJournalBatch, GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);

        // [GIVEN] Posted Receivable Bill Group "Y" on Sales Invoice
        CustLedgerEntryNo := PostReceivablesBillGroupOnSalesInvoice();

        // [WHEN] Run Redraw Recaivable Bill job with General Journal Batch "X" and Cust. Ledg. Entry "Y"
        RedrawDocument(CustLedgerEntryNo);

        // [THEN] Cartera Journal opened with General Journal Batch "X"
        // Verification done in CarteraJournalCheckBatchHandler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SettleDocsInPostedBillGroupRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewUpdateOnPostingAfterSalesSettleDocInPostedBillGroup()
    var
        BillGroup: Record "Bill Group";
        AnalysisView: Record "Analysis View";
        GLEntry: Record "G/L Entry";
        BankAccNo: Code[20];
    begin
        // [FEATURE] [Analysis View]
        // [SCENARIO 363182] "Analysis View"."Last Entry No." is updated after run REP7000098 "Settle Docs. in Post. Bill Gr."

        // [GIVEN] Analysis View with "Update on Posting" = TRUE
        CreateAnalysisView(AnalysisView);

        // [GIVEN] Posted Receivable Bill Group
        SetupBillGroupWithBankAccDimension(BillGroup, BankAccNo, BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [WHEN] Run report 7000098 "Settle Docs. in Post. Bill Gr."
        RunSettleDocs(BankAccNo);

        // [THEN] "Analysis View"."Last Entry No." = last G/L Entry No.
        GLEntry.FindLast();
        AnalysisView.Find();
        Assert.AreEqual(GLEntry."Entry No.", AnalysisView."Last Entry No.", AnalysisView.FieldCaption("Last Entry No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,SettleDocsInPostedPaymentOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewUpdateOnPostingAfterSalesSettleDocInPostedPO()
    var
        PaymentOrder: Record "Payment Order";
        AnalysisView: Record "Analysis View";
        GLEntry: Record "G/L Entry";
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
        BankAccNo: Code[20];
    begin
        // [FEATURE] [Analysis View]
        // [SCENARIO 363182] "Analysis View"."Last Entry No." is updated after run REP7000082 "Settle Docs. in Posted PO"

        // [GIVEN] Analysis View with "Update on Posting" = TRUE
        CreateAnalysisView(AnalysisView);

        // [GIVEN] Posted Payment Order
        SetupPaymentOrderWithBankAccDimension(PaymentOrder, BankAccNo);
        AddInvoiceToPaymentOrder(PaymentOrder);
        POPostAndPrint.PayablePostOnly(PaymentOrder);

        // [WHEN] Run report 7000082 "Settle Docs. in Posted PO"
        SettlePurchDocument(BankAccNo);

        // [THEN] "Analysis View"."Last Entry No." = last G/L Entry No.
        GLEntry.FindLast();
        AnalysisView.Find();
        Assert.AreEqual(GLEntry."Entry No.", AnalysisView."Last Entry No.", AnalysisView.FieldCaption("Last Entry No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,PartialSettlReceivableRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisViewUpdateOnPostingAfterSalesSettleDocInPartialSettlReceivable()
    var
        BillGroup: Record "Bill Group";
        AnalysisView: Record "Analysis View";
        GLEntry: Record "G/L Entry";
        BankAccNo: Code[20];
    begin
        // [FEATURE] [Analysis View]
        // [SCENARIO 363182] "Analysis View"."Last Entry No." is updated after run REP7000084 "Partial Settl.- Receivable"

        // [GIVEN] Analysis View with "Update on Posting" = TRUE
        CreateAnalysisView(AnalysisView);

        // [GIVEN] Posted Bill Group
        SetupBillGroupWithBankAccDimension(BillGroup, BankAccNo, BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [WHEN] Run report 7000084 "Partial Settl.- Receivable"
        PartiallySettleDocument(BankAccNo);

        // [THEN] "Analysis View"."Last Entry No." = last G/L Entry No.
        GLEntry.FindLast();
        AnalysisView.Find();
        Assert.AreEqual(GLEntry."Entry No.", AnalysisView."Last Entry No.", AnalysisView.FieldCaption("Last Entry No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CustLedgEntryAmountNotIncludedRejectionAndRedrawalDtldEntries()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [UT] [Customer Ledger Entry] [Rejection]
        // [SCENARIO 364474] The flow-field "Amount" in Customer Ledger Entry should not included Rejection and Redrawal Dtld. Ledger Entries into calculation

        Initialize();
        // [GIVEN] Customer Ledger Entry with Detailed Entries ("Initial Entry", Amount = X; "Rejection", Amount = Y; "Redrawal", Amount = Z)
        MockCustLedgEntry(CustLedgEntry);
        ExpectedAmount :=
          MockDtldCustLedgEntry(CustLedgEntry."Entry No.", CustLedgEntry."Posting Date", DtldCustLedgEntry."Entry Type"::"Initial Entry");
        MockDtldCustLedgEntry(CustLedgEntry."Entry No.", CustLedgEntry."Posting Date", DtldCustLedgEntry."Entry Type"::Rejection);
        MockDtldCustLedgEntry(CustLedgEntry."Entry No.", CustLedgEntry."Posting Date", DtldCustLedgEntry."Entry Type"::Redrawal);

        // [WHEN] Calculate "Amount" in Customer Ledger Entry
        CustLedgEntry.CalcFields(Amount);

        // [THEN] "Amount" = X
        Assert.AreEqual(ExpectedAmount, CustLedgEntry.Amount, CustLedgEntry.FieldCaption(Amount));
    end;

    [Test]
    [HandlerFunctions('PostBillGroupRequestPageHandler,ConfirmHandler,CarteraJournalCheckBatchHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OpenJournalBatchFromMultipleBatchesWhenPostDiscountBillGroup()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        GenJournalBatchA: Record "Gen. Journal Batch";
        GenJournalBatchB: Record "Gen. Journal Batch";
        CarteraJournal: TestPage "Cartera Journal";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 378220] Bill Group with 'Dealing Type' Discount uses selected Journal Batch name when posting
        Initialize();
        UpdateCarteraSetup();

        // [GIVEN] Saved Batch Name for Cartera Journal is "A"
        LibraryCarteraReceivables.CreateCarteraJournalBatch(GenJournalBatchA);
        CarteraJournal.OpenView();
        CarteraJournal.CurrentJnlBatchName.SetValue(GenJournalBatchA.Name);
        CarteraJournal.OK().Invoke();

        // [GIVEN] Cartera Bill Group with "Dealing Type" = Discount
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, '');
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, '');
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Discount);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, InvoiceNo, Customer."No.", BillGroup."No.");

        // [GIVEN] Cartera Journal Batch with Name = "B"
        LibraryCarteraReceivables.CreateCarteraJournalBatch(GenJournalBatchB);
        Commit();
        LibraryVariableStorage.Enqueue(GenJournalBatchA."Journal Template Name"); // used in PostBillGroupRequestPageHandler
        LibraryVariableStorage.Enqueue(GenJournalBatchB.Name); // used in PostBillGroupRequestPageHandler
        LibraryVariableStorage.Enqueue(GenJournalBatchB.Name); // used in CarteraJournalCheckBatchHandler

        // [WHEN] Post Bill Group with selected Journal Batch "B" for posting
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [THEN] Gen. Journal Batch is opened with Batch Name = "B"
        // verification is done in CarteraJournalCheckBatchHandler

        GenJournalBatchA.Delete();
        GenJournalBatchB.Delete();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ApplyCustCreditMemoToBillNotIncludedInPaymentOrderWithApplyToOldestMethod()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        SalesHeader: Record "Sales Header";
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        InvNo: array[2] of Code[20];
        CrMemoNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Credit Memo] [Application] [Sales]
        // [SCENARIO 380386] Credit Memo should be automatically applied to Bill which is not included to Payment Order when using "Apply-to Oldest" method of application

        Initialize();

        // [GIVEN] Customer "X" with "Application Method" = "Apply-to Oldest"
        CreateCustomer(Customer);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);

        // [GIVEN] Invoice "A" and Invoice "B" with Customer "X"
        for i := 1 to ArrayLen(InvNo) do
            InvNo[i] := CreateAndPostSalesInvoice(Customer);

        // [GIVEN] Posted Bill Group applied to Bill "A"
        LibraryERM.CreateBankAccount(BankAccount);
        CreateBillGroupWithSpecificBankAccount(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        AddDocToBillGroup(BillGroup."No.", InvNo[1]);
        BGPostAndPrint.ReceivablePostOnly(BillGroup);

        // [GIVEN] Sales Credit Memo with Customer "X"
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [WHEN] Post Sales Credit Memo
        CrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted Sales Credit Memo applied to Bill "B"
        VerifyCustLedgEntryApplicationExists(InvNo[2], CrMemoNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ApplyVendCreditMemoToBillNotIncludedInPaymentOrderWithApplyToOldestMethod()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        PaymentOrder: Record "Payment Order";
        PurchHeader: Record "Purchase Header";
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
        InvNo: array[2] of Code[20];
        CrMemoNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Credit Memo] [Application] [Purchase]
        // [SCENARIO 380386] Credit Memo should be automatically applied to Bill which is not included to Payment Order when using "Apply-to Oldest" method of application

        Initialize();

        // [GIVEN] Vendor "X" with "Application Method" = "Apply-to Oldest"
        CreateVendor(Vendor);
        Vendor.Validate("Application Method", Vendor."Application Method"::"Apply to Oldest");
        Vendor.Modify(true);

        // [GIVEN] Invoice "A" and Invoice "B" with Vendor "X"
        for i := 1 to ArrayLen(InvNo) do
            InvNo[i] := CreateAndPostPurchInvoice(Vendor);

        // [GIVEN] Posted Payment Order applied to Bill "A"
        LibraryERM.CreateBankAccount(BankAccount);
        CreatePaymentOrderWithSpecificBankAccount(PaymentOrder, BankAccount."No.");
        AddDocToBillGroup(PaymentOrder."No.", InvNo[1]);
        POPostAndPrint.PayablePostOnly(PaymentOrder);

        // [GIVEN] Purchase Credit Memo with Vendor "X"
        CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", Vendor."No.");

        // [WHEN] Post Purchase Credit Memo
        CrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Posted Purchase Credit Memo applied to Bill "B"
        VerifyVendLedgEntryApplicationExists(InvNo[2], CrMemoNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler2,SettleDocsInPostedPaymentOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchSettleDocOfInvoiceWithUnrealizedVATAndDescriptionPurchaseLine()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PaymentOrder: Record "Payment Order";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 213095] VAT entry should be created when Run Settle Doc on Payment Order for Purchase Invoice with description line
        Initialize();

        // [GIVEN] Unrealized VAT in G/L Setup
        UpdateGenLedgVATSetup(true);

        // [GIVEN] Posted Cartera Bill for Purchase Invoice with 1st description line
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          CreateVendorWithCarteraPmtMethodAndVATSetup(VATBusinessPostingGroup.Code));
        AddDescriptionPurchLine(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItemWithVATGroup(CreateVATPostingSetup(VATBusinessPostingGroup.Code)), LibraryRandom.RandDec(10, 2));
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Payment Order is created and posted for the Purchase Invoice
        CreatePaymentOrderWithSpecificBankAccount(PaymentOrder, LibraryERM.CreateBankAccountNo());
        AddDocToBillGroup(PaymentOrder."No.", DocumentNo);
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);

        // [WHEN] Run Settle Doc on Payment Order
        SettlePurchDocument(PaymentOrder."Bank Account No.");

        // [THEN] VAT Entry is created for settled Payment Order
        VerifyVATEntryExists(PaymentOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SettleDocsInPostedBillGroupRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesSettleDocOfInvoiceWithUnrealizedVATAndDescriptionSalesLine()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BillGroup: Record "Bill Group";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 213095] VAT entry should be created when Run Settle Doc on Bill Group for Sales Invoice with description line
        Initialize();

        // [GIVEN] Unrealized VAT in G/L Setup
        UpdateGenLedgVATSetup(true);

        // [GIVEN] Posted Cartera Bill for Sales Invoice with 1st description line
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustWithCarteraPmtMethodAndVATSetup(VATBusinessPostingGroup.Code));
        AddDescriptionSalesLine(SalesHeader);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItemWithVATGroup(CreateVATPostingSetup(VATBusinessPostingGroup.Code)), LibraryRandom.RandDec(10, 2));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Bill Group is created and posted for the Sales Invoice
        CreateBillGroup(BillGroup);
        AddDocToBillGroup(BillGroup."No.", DocumentNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [WHEN] Run Settle Doc on Posted Bill Group
        SettleDocument(BillGroup."Bank Account No.");

        // [THEN] VAT Entry is created for settled Bill Group
        VerifyVATEntryExists(BillGroup."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DetailedCustLedgEntryAmountNotIncludedInMyCustomerBalanceCalculation()
    var
        Customer: Record Customer;
        MyCustomer: Record "My Customer";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [UT] [Customer Ledger Entry]
        // [SCENARIO 366386] The flow-field "Balance (LCY)" in My Customer does not account for Excluded Dtld. Ledger Entries
        Initialize();

        // [GIVEN] Created Customer and My Customer
        LibrarySales.CreateCustomer(Customer);
        CreateMyCustomer(Customer, UserId);

        // [GIVEN] Created Detailed Ledger Entry A with "Amount (LCY)" = 100 and "Excluded from calculation" = FALSE
        ExpectedAmount := CreateDetailedCustLedgEntry(Customer."No.", false);

        // [GIVEN] Created Detailed Ledger Entry B with "Amount (LCY)" = 200 and "Excluded from calculation" = TRUE
        CreateDetailedCustLedgEntry(Customer."No.", true);

        // [WHEN] Calculate "Balance (LCY)" for My Customer
        MyCustomer.Get(UserId, Customer."No.");
        MyCustomer.CalcFields("Balance (LCY)");

        // [THEN] "Balance (LCY)" in My Customer = 100
        Assert.AreEqual(ExpectedAmount, MyCustomer."Balance (LCY)", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,SettleDocsInPostedPaymentOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyDimensionAfterSettlePaymentOrderWithPurchaseOrder()
    var
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        PaymentOrder: Record "Payment Order";
        POPostAndPrint: Codeunit "BG/PO-Post and Print";
        GLEntry: Record "G/L Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        InvNo: Code[20];
        DimSetId: Integer;
    begin
        // [SCENARIO 454719] Dimensions in the G/L Entries and Bank Ledger Entries are not correctly shown in the lines when settling Payment Orders in the Spanish version
        Initialize();

        // [GIVEN] Create Vendor "X" 
        CreateVendor(Vendor);

        // [GIVEN] Invoice "A" and Invoice "B" with Vendor "X"
        InvNo := CreateAndPostPurchOrderWithDimension(Vendor, DimSetId);

        // [GIVEN] Posted Payment Order applied to Bill "A"
        LibraryERM.CreateBankAccount(BankAccount);
        CreatePaymentOrderWithSpecificBankAccount(PaymentOrder, BankAccount."No.");
        AddDocToBillGroup(PaymentOrder."No.", InvNo);
        POPostAndPrint.PayablePostOnly(PaymentOrder);

        // [WHEN] Run report 7000082 "Settle Docs. in Posted PO"
        SettlePurchDocument(BankAccount."No.");

        // [THEN] Get Last Posted G/L Entry and Bank Account Ledger Entry record
        GLEntry.FindLast();
        BankAccountLedgerEntry.FindLast();

        // [VERIFY] Verify Dimension on G/L Entry and Bank Account Ledger Entry
        Assert.AreEqual(GLEntry."Dimension Set ID", DimSetId, GLEntry.FieldCaption("Dimension Set ID"));
        Assert.AreEqual(BankAccountLedgerEntry."Dimension Set ID", DimSetId, BankAccountLedgerEntry.FieldCaption("Dimension Set ID"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGLRegisterIsCreatedWhenPostedSalesInvoiceApplywithPaymentforMultiplePostingGroups()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        GLRegister: Record "G/L Register";
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        CustomerPostingGroup, CustomerPostingGroup2 : Record "Customer Posting Group";
        SalesInvoiceNo, PaymentDocNo : Code[20];
        TotalAmount: Decimal;
        LastGLRegisterNo: Integer;
    begin
        // [SCENARIO 492112] Verify a new ledger entry for the applied payment and invoice if we use multiple posting groups for customers.
        Initialize();

        // [GIVEN] Set "Allow Multiple Posting Groups" to true.
        SetSalesAllowMultiplePostingGroups(true);

        // [GIVEN] Create a customer and set "Allow Multiple Posting Groups" to true.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();

        // [GIVEN] Get a customer posting group.
        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        //[GIVEN] Save "GL Register" in a variable.
        GLRegister.FindLast();
        LastGLRegisterNo := GLRegister."No.";

        // [GIVEN] Create a sales invoice.
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader,
            SalesLine,
            "Sales Document Type"::Invoice,
            Customer."No.",
            '',
            LibraryRandom.RandInt(10),
            '',
            0D);

        // [GIVEN] Create another customer posting group.
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup2);

        // [GIVEN] Create an "Alt. Customer Posting Group."
        LibrarySales.CreateAltCustomerPostingGroup(Customer."Customer Posting Group", CustomerPostingGroup2.Code);

        // [GIVEN] Update a customer posting group in the sales header.
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup2.Code);
        SalesHeader.Modify();

        // [GIVEN] Update a unit price in the sales line.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify();

        // [GIVEN] Save the invoice amount in a variable.
        SalesHeader.CalcFields("Amount Including VAT");
        TotalAmount := SalesHeader."Amount Including VAT";

        // [GIVEN] Post a sales document.
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create a general journal line with "Document Type" = Payment.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer,
            Customer."No.",
            -TotalAmount);

        // [GIVEN] Update Bal Account No. in the general journal line.
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalLine.Modify();

        // [GIVEN] Post payment.
        PaymentDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Apply for payment with the invoice and post the application.
        ApplyAndPostCustomerEntry(
            PaymentDocNo,
            SalesInvoiceNo,
            -TotalAmount,
            "Gen. Journal Document Type"::Payment,
            "Gen. Journal Document Type"::Invoice);

        // [VERIFY] Verify a new ledger entry for the applied payment and invoice if we use multiple posting groups for customers.
        GLRegister.SetFilter("No.", '%1..', LastGLRegisterNo + 1);
        Assert.RecordCount(GLRegister, LibraryRandom.RandIntInRange(3, 3));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Cartera Setup");
        isInitialized := true;
    end;

    local procedure CreateMyCustomer(Customer: Record Customer; UserID: Text)
    var
        MyCustomer: Record "My Customer";
    begin
        MyCustomer.Init();
        MyCustomer.Validate("Customer No.", Customer."No.");
        MyCustomer."User ID" := CopyStr(UserID, 1, MaxStrLen(MyCustomer."User ID"));
        MyCustomer.Insert(true);
    end;

    local procedure CreateDetailedCustLedgEntry(CustomerNo: Code[20]; Excluded: Boolean): Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Customer No." := CustomerNo;
        DetailedCustLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        DetailedCustLedgEntry."Excluded from calculation" := Excluded;
        DetailedCustLedgEntry.Insert();
        exit(DetailedCustLedgEntry."Amount (LCY)");
    end;

    local procedure ClearAddReportingCurrency()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Additional Reporting Currency" <> '' then begin
            GeneralLedgerSetup.Validate("Additional Reporting Currency", '');
            GeneralLedgerSetup.Modify();
        end;
    end;

    local procedure SetupBillGroupWithBankAccDimension(var BillGroup: Record "Bill Group"; var BankAccNo: Code[20]; DealingType: Enum "Cartera Dealing Type")
    begin
        Initialize();
        UpdateCarteraSetup();
        BankAccNo := CreateBankAccountWithDimension();
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccNo, DealingType);
        AddInvoiceToBillGroup(BillGroup);
    end;

    local procedure AddInvoiceToBillGroup(var BillGroup: Record "Bill Group")
    var
        Customer: Record Customer;
        InvNo: Code[20];
    begin
        CreateCustomer(Customer);
        InvNo := CreateAndPostSalesInvoice(Customer);
        AddDocToBillGroup(BillGroup."No.", InvNo);
    end;

    local procedure AddInvoiceToPaymentOrder(var PaymentOrder: Record "Payment Order")
    var
        Vendor: Record Vendor;
        InvNo: Code[20];
    begin
        CreateVendor(Vendor);
        InvNo := CreateAndPostPurchInvoice(Vendor);
        AddDocToBillGroup(PaymentOrder."No.", InvNo);
    end;

    local procedure SetupPaymentOrderWithBankAccDimension(var PaymentOrder: Record "Payment Order"; var BankAccNo: Code[20])
    begin
        Initialize();
        UpdateCarteraSetup();
        BankAccNo := CreateBankAccountWithDimension();
        CreatePaymentOrderWithSpecificBankAccount(PaymentOrder, BankAccNo);
        AddInvoiceToPaymentOrder(PaymentOrder);
    end;

    local procedure CreateBankAccountWithDimension(): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        DimValue: Record "Dimension Value";
        DefaultDim: Record "Default Dimension";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        BankAccPostingGroup.Validate("Liabs. for Disc. Bills Acc.", LibraryERM.CreateGLAccountNo());
        BankAccPostingGroup.Modify(true);

        CreateDimValue(DimValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDim, DATABASE::"Bank Account", BankAccount."No.", DimValue."Dimension Code", DimValue.Code);
        DefaultDim.Validate("Value Posting", DefaultDim."Value Posting"::"Same Code");
        DefaultDim.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateDimValue(var DimValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimValue, Dimension.Code);
    end;

    local procedure CreateBillGroup(var BillGroup: Record "Bill Group")
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
    end;

    local procedure CreateBillGroupWithSpecificBankAccount(var BillGroup: Record "Bill Group"; BankAccNo: Code[20]; DealingType: Enum "Cartera Dealing Type")
    begin
        BillGroup.Init();
        BillGroup.Validate("Bank Account No.", BankAccNo);
        BillGroup.Validate("Dealing Type", DealingType);
        BillGroup.Insert(true);
    end;

    local procedure CreatePaymentOrderWithSpecificBankAccount(var PaymentOrder: Record "Payment Order"; BankAccNo: Code[20])
    begin
        PaymentOrder.Init();
        PaymentOrder.Validate("Bank Account No.", BankAccNo);
        PaymentOrder.Insert(true);
    end;

    local procedure UpdateGenLedgVATSetup(NewUnrealizedVAT: Boolean)
    begin
        LibraryERM.SetUnrealizedVAT(NewUnrealizedVAT);
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateUnrealVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"; UnrealizedType: Option; PurchUnrealVATAcc: Code[20]; SalesUnrealVATAcc: Code[20])
    begin
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedType);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", PurchUnrealVATAcc);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", SalesUnrealVATAcc);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateCarteraSetup()
    var
        CarteraSetup: Record "Cartera Setup";
    begin
        CarteraSetup.Get();
        CarteraSetup."Bills Discount Limit Warnings" := false;
        CarteraSetup.Modify(true);
    end;

    local procedure CreateGLAccWithVAT(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateItemWithVATGroup(VATProdPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    [HandlerFunctions('RejectDocsHandler')]
    local procedure RejectDocument(CustLedgerEntryNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get(CustLedgerEntryNo);
        CustLedgEntry.Mark(true);
        CustLedgEntry.MarkedOnly(true);
        REPORT.RunModal(REPORT::"Reject Docs.", true, false, CustLedgEntry);
    end;

    [HandlerFunctions('RedrawDocumentHandler')]
    local procedure RedrawDocument(CustLedgerEntryNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get(CustLedgerEntryNo);
        CustLedgEntry.Mark(true);
        CustLedgEntry.MarkedOnly(true);
        LibraryVariableStorage.Enqueue(CalcDate('<+1D>', CustLedgEntry."Due Date"));
        REPORT.RunModal(REPORT::"Redraw Receivable Bills", true, false, CustLedgEntry);
    end;

    local procedure SettleDocument(BankAccountNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        SettleDocsInPostBillGr: Report "Settle Docs. in Post. Bill Gr.";
    begin
        GetPostedCarteraDocEntry(BankAccountNo, PostedCarteraDoc);
        SettleDocsInPostBillGr.SetHidePrintDialog(true);
        SettleDocsInPostBillGr.SetTableView(PostedCarteraDoc);
        SettleDocsInPostBillGr.Run();
    end;

    [HandlerFunctions('RedrawDocumentHandler')]
    local procedure RedrawPurchDocument(VendLedgerEntryNo: Integer)
    var
        VendorLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgEntry.Get(VendLedgerEntryNo);
        VendorLedgEntry.Mark(true);
        VendorLedgEntry.MarkedOnly(true);
        LibraryVariableStorage.Enqueue(CalcDate('<+1D>', VendorLedgEntry."Due Date"));
        REPORT.RunModal(REPORT::"Redraw Payable Bills", true, false, VendorLedgEntry);
    end;

    local procedure SettlePurchDocument(BankAccountNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        SettleDocsInPostedPO: Report "Settle Docs. in Posted PO";
    begin
        GetPostedCarteraDocEntry(BankAccountNo, PostedCarteraDoc);
        SettleDocsInPostedPO.SetHidePrintDialog(true);
        SettleDocsInPostedPO.SetTableView(PostedCarteraDoc);
        SettleDocsInPostedPO.Run();
    end;

    local procedure PartiallySettleDocument(BankAccountNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        PartialSettlReceivable: Report "Partial Settl.- Receivable";
    begin
        GetPostedCarteraDocEntry(BankAccountNo, PostedCarteraDoc);
        PartialSettlReceivable.SetInitValue(
          PostedCarteraDoc."Remaining Amount", PostedCarteraDoc."Currency Code", PostedCarteraDoc."Entry No.");
        PartialSettlReceivable.SetTableView(PostedCarteraDoc);
        PartialSettlReceivable.Run();
    end;

    local procedure GetPostedCarteraDocEntry(BankAccountNo: Code[20]; var PostedCarteraDoc: Record "Posted Cartera Doc.")
    begin
        PostedCarteraDoc.SetRange("Bank Account No.", BankAccountNo);
        PostedCarteraDoc.FindFirst();
        PostedCarteraDoc.SetRange("Entry No.", PostedCarteraDoc."Entry No.");
    end;

    local procedure PartiallySettlePurchDocument(BankAccountNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        PartialSettlPayable: Report "Partial Settl. - Payable";
    begin
        GetPostedCarteraDocEntry(BankAccountNo, PostedCarteraDoc);
        PartialSettlPayable.SetInitValue(
          PostedCarteraDoc."Remaining Amount", PostedCarteraDoc."Currency Code", PostedCarteraDoc."Entry No.");
        PartialSettlPayable.SetTableView(PostedCarteraDoc);
        PartialSettlPayable.Run();
    end;

    local procedure CreateAcc(AccType: Enum "Gen. Journal Account Type"; VATBusPostGroupCode: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case AccType of
            GenJnlLine."Account Type"::Vendor:
                exit(CreateVendWithVATBusPostGroup(VATBusPostGroupCode));
            GenJnlLine."Account Type"::Customer:
                exit(CreateCustWithVATBusPostGroup(VATBusPostGroupCode));
        end;
    end;

    local procedure CreateVendWithVATBusPostGroup(VATBusPostGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        SetVendorPaymentData(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure SetVendorPaymentData(var Vendor: Record Vendor)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
    end;

    local procedure CreateCustWithVATBusPostGroup(VATBusPostGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustWithPaymentTermsAndVATGroup(VATDistributionType: Option; VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Validate(
          "Payment Terms Code", CreatePaymentTermsWithVATDistribType(VATDistributionType));
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendWithPaymentTermsAndVATGroup(VATDistributionType: Option; VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Vendor.Validate(
          "Payment Terms Code", CreatePaymentTermsWithVATDistribType(VATDistributionType));
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePaymentTermsWithVATDistribType(VATDistributionType: Option): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("VAT distribution", VATDistributionType);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateVATPostingSetup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);
        UpdateVATPostingSetup(VATPostingSetup);
        UpdateUnrealVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.FindPaymentTerms(PaymentTerms);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Payment Method Code", GetPaymentMethodCartera());
        Customer.Modify(true);
    end;

    local procedure CreateVendor(var Vendor: Record Vendor)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.FindPaymentTerms(PaymentTerms);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", GetPaymentMethodCartera());
        Vendor.Modify(true);
    end;

    local procedure CreateCustWithCarteraPmtMethodAndVATSetup(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithCarteraPmtMethodAndVATSetup(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostSalesInvoice(Customer: Record Customer) InvoiceNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchInvoice(Vendor: Record Vendor): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchHeader(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; VendNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        LibrarySales.FindItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", Item."Unit Price");
        PurchaseLine.Modify();
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        LibrarySales.FindItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreatePostSalesInvoiceWithVATGroup(var TotalAmount: Decimal; CustomerNo: Code[20]; VATProductPostingGroupCode: Code[20]) DocumentNo: Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        DocumentNo :=
          CreateAndPostSalesDocument(
            SalesLine, SalesLine."Document Type"::Invoice, CustomerNo, CreateItemWithVATGroup(VATProductPostingGroupCode));
        TotalAmount := SalesLine."Amount Including VAT";
        exit(DocumentNo);
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader,
          SalesLine.Type::Item, ItemNo,
          LibraryRandom.RandDec(100, 2));
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesLine.Find();
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostPurchInvoiceWithVATGroup(var TotalAmount: Decimal; VendorNo: Code[20]; VATProductPostingGroupCode: Code[20]) DocumentNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, VendorNo, CreateItemWithVATGroup(VATProductPostingGroupCode));
        TotalAmount := PurchaseLine."Amount Including VAT";
        exit(DocumentNo);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchDocument: Codeunit "Release Purchase Document";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader,
          PurchaseLine.Type::Item, ItemNo,
          LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", PurchaseLine."Unit Price (LCY)");
        PurchaseLine.Modify(true);
        ReleasePurchDocument.PerformManualRelease(PurchaseHeader);
        PurchaseLine.Find();
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostSalesInvoiceWithSeveralVATGroups(var AmountInclVAT: array[2] of Decimal; CustNo: Code[20]; VATProdPostingGroupCode: array[2] of Code[20]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
        UnitPrice: Decimal;
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(10);
        UnitPrice := LibraryRandom.RandDec(100, 2);
        for i := 1 to 2 do
            AmountInclVAT[i] :=
              GetSalesLineAmtInclVAT(
                SalesHeader,
                AddSalesLine(
                  SalesHeader, Item."No.", VATProdPostingGroupCode[i], Quantity, UnitPrice));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostPurchInvoiceWithSeveralVATGroups(var AmountInclVAT: array[2] of Decimal; VendNo: Code[20]; VATProdPostingGroupCode: array[2] of Code[20]): Code[20]
    var
        Item: Record Item;
        PurchHeader: Record "Purchase Header";
        Quantity: Decimal;
        UnitCost: Decimal;
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendNo);
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandDec(100, 2);
        for i := 1 to 2 do
            AmountInclVAT[i] :=
              GetPurchLineAmtInclVAT(
                PurchHeader,
                AddPurchLine(
                  PurchHeader, Item."No.", VATProdPostingGroupCode[i], Quantity, UnitCost));
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure MockCustLedgEntry(CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.Init();
        CustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(CustLedgEntry, CustLedgEntry.FieldNo("Entry No."));
        CustLedgEntry."Posting Date" := WorkDate();
        CustLedgEntry.Insert();
    end;

    local procedure MockDtldCustLedgEntry(CustLedgEntryNo: Integer; PostingDate: Date; EntryType: Enum "Detailed CV Ledger Entry Type"): Decimal
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.Init();
        DtldCustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DtldCustLedgEntry, DtldCustLedgEntry.FieldNo("Entry No."));
        DtldCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntryNo;
        DtldCustLedgEntry."Entry Type" := EntryType;
        DtldCustLedgEntry."Posting Date" := PostingDate;
        DtldCustLedgEntry.Amount := LibraryRandom.RandDec(100, 2);
        DtldCustLedgEntry.Insert(true);
        exit(DtldCustLedgEntry.Amount);
    end;

    local procedure AddSalesLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; VATProdPostingGroupCode: Code[20]; Quantity: Decimal; UnitPrice: Decimal): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader,
          SalesLine.Type::Item, ItemNo,
          Quantity);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        exit(SalesLine."Line No.");
    end;

    local procedure AddPurchLine(var PurchHeader: Record "Purchase Header"; ItemNo: Code[20]; VATProdPostingGroupCode: Code[20]; Quantity: Decimal; UnitCost: Decimal): Integer
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader,
          PurchLine.Type::Item, ItemNo,
          Quantity);
        PurchLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        PurchLine.Validate("Direct Unit Cost", UnitCost);
        PurchLine.Modify(true);
        exit(PurchLine."Line No.");
    end;

    local procedure AddDescriptionSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate(Description, LibraryUtility.GenerateGUID());
        SalesLine.Insert(true);
    end;

    local procedure AddDescriptionPurchLine(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate(Description, LibraryUtility.GenerateGUID());
        PurchaseLine.Insert(true);
    end;

    local procedure GetSalesLineAmtInclVAT(var SalesHeader: Record "Sales Header"; SalesLineNo: Integer): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesLine.Get(
          SalesHeader."Document Type", SalesHeader."No.", SalesLineNo);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure GetPurchLineAmtInclVAT(var PurchHeader: Record "Purchase Header"; PurchLineNo: Integer): Decimal
    var
        PurchLine: Record "Purchase Line";
        ReleasePurchDocument: Codeunit "Release Purchase Document";
    begin
        ReleasePurchDocument.PerformManualRelease(PurchHeader);
        PurchLine.Get(
          PurchHeader."Document Type", PurchHeader."No.", PurchLineNo);
        ReleasePurchDocument.PerformManualReopen(PurchHeader);
        exit(PurchLine."Amount Including VAT");
    end;

    local procedure CreateGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
    end;

    local procedure FindGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch"; TemplateType: Enum "Gen. Journal Template Type")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.SetRange(Type, TemplateType);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJnlBatch);
    end;

    local procedure CreatePostPairedGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; VATPostingSetup: Record "VAT Posting Setup")
    var
        AccNo: Code[20];
    begin
        AccNo := CreateAcc(AccType, VATPostingSetup."VAT Bus. Posting Group");
        InitGenJnlLineWithBatch(GenJnlLine);
        CreateBalancedGenJnlLines(GenJnlLine, DocType, AccType, AccNo, VATPostingSetup);
        CreateBalancedGenJnlLines(GenJnlLine, DocType, AccType, AccNo, VATPostingSetup);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        CreatePostAppliedDoc(GenJnlLine, DocType, AccType, AccNo);
    end;

    local procedure InitGenJnlLineWithBatch(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJnlBatch(GenJnlBatch);
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
    end;

    local procedure InitGenJnlLineWithGivenBatch(var GenJnlLine: Record "Gen. Journal Line"; JnlTemplateName: Code[20]; JnlBatchName: Code[20])
    begin
        GenJnlLine.Init();
        GenJnlLine."Journal Template Name" := JnlTemplateName;
        GenJnlLine."Journal Batch Name" := JnlBatchName;
    end;

    local procedure CreateBalancedGenJnlLines(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup")
    var
        DocNo: Code[20];
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name",
            DocType, AccType, AccNo, GetEntryAmount(AccType, DocType));

        DocNo := GenJnlLine."Document No.";

        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name",
          DocType, GenJnlLine."Account Type"::"G/L Account", CreateGLAccWithVAT(VATPostingSetup), -GenJnlLine.Amount);
        GenJnlLine.Validate("Document No.", DocNo);
        GenJnlLine.Validate("Gen. Posting Type", GetGenPostType(AccType));
        GenJnlLine.Modify(true);
    end;

    local procedure CreateApplyPostBillToInvoice(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; BillAmount: Decimal; InvoiceNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        exit(
          CreateApplyPostBill(
            AccType, AccNo, BillAmount, GenJnlLine."Applies-to Doc. Type"::Invoice, InvoiceNo, ''));
    end;

    local procedure CreateApplyPostSeveralBillsToInvoice(var BillNo: array[2] of Code[20]; var BillAmount: array[2] of Decimal; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; InvoiceNo: Code[20]; InvAmount: Decimal)
    begin
        BillAmount[1] := GetAmountPart(InvAmount);
        BillNo[1] :=
          CreateApplyPostBillToInvoice(AccType, AccNo, BillAmount[1], InvoiceNo);
        BillAmount[2] := InvAmount - BillAmount[1];
        BillNo[2] :=
          CreateApplyPostBillToInvoice(AccType, AccNo, BillAmount[2], InvoiceNo);
    end;

    local procedure CreateApplyPostBillToBill(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; BillAmount: Decimal; InvoiceNo: Code[20]; BillNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        exit(
          CreateApplyPostBill(
            AccType, AccNo, BillAmount, GenJnlLine."Applies-to Doc. Type"::Bill, InvoiceNo, BillNo));
    end;

    local procedure CreateApplyPostBillToBillToInvoice(var BillNo: array[2] of Code[20]; var BillAmount: Decimal; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; InvoiceNo: Code[20]; InvAmount: Decimal)
    begin
        BillAmount := GetAmountPart(InvAmount);
        BillNo[1] :=
          CreateApplyPostBillToInvoice(AccType, AccNo, BillAmount, InvoiceNo);
        BillAmount := GetAmountPart(BillAmount);
        BillNo[2] :=
          CreateApplyPostBillToBill(AccType, AccNo, BillAmount, InvoiceNo, BillNo[1]);
    end;

    local procedure CreateApplyPostBill(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; BillAmount: Decimal; ApplyToDocType: Enum "Gen. Journal Document Type"; InvoiceNo: Code[20]; ApplyToBillNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        InitGenJnlLineWithBatch(GenJnlLine);
        CreateGenJnlLineWithSpecialDocNo(
          GenJnlLine, GenJnlLine."Document Type"::" ", InvoiceNo, AccType, AccNo, -BillAmount, true, ApplyToDocType, InvoiceNo, ApplyToBillNo);
        CreateGenJnlLineWithSpecialDocNo(
          GenJnlLine, GenJnlLine."Document Type"::Bill, InvoiceNo, AccType, AccNo, BillAmount, true, GenJnlLine."Applies-to Doc. Type"::" ", '', '');
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Bill No.");
    end;

    local procedure CreateApplyPostPaymentToBill(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; InvoiceNo: Code[20]; BillNo: Code[20]; PayAmount: Decimal): Code[20]
    begin
        exit(PostPaymentApplyingToBill(AccType, AccNo, InvoiceNo, BillNo, PayAmount, true));
    end;

    local procedure CreatePostPaymentToSeveralBills(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; InvoiceNo: Code[20]; BillNo: array[2] of Code[20]; PayAmount: Decimal; ApplyFromJournal: Boolean): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        i: Integer;
    begin
        InitGenJnlLineWithBatch(GenJnlLine);
        CreateGenJnlLine(
          GenJnlLine, GenJnlLine."Document Type"::Payment, AccType, AccNo, PayAmount, false, GenJnlLine."Applies-to Doc. Type"::" ", '', '');
        ApplyPaymentToBillFromGenJnlLine(GenJnlLine, ApplyFromJournal, InvoiceNo, BillNo);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        for i := 1 to 2 do
            ApplyPaymentToBill(AccType, GenJnlLine."Document No.", InvoiceNo, BillNo[i], ApplyFromJournal);
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreateApplyPostSeveralPaysToBill(var PayNo: array[2] of Code[20]; var PayAmount: array[2] of Decimal; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; InvoiceNo: Code[20]; InvAmount: Decimal; BillNo: Code[20]; ApplyFromGenJnlLine: Boolean)
    begin
        PayAmount[1] := -GetAmountPart(InvAmount);
        PayNo[1] :=
          PostPaymentApplyingToBill(AccType, AccNo, InvoiceNo, BillNo, PayAmount[1], ApplyFromGenJnlLine);
        PayAmount[2] := -InvAmount - PayAmount[1];
        PayNo[2] :=
          PostPaymentApplyingToBill(AccType, AccNo, InvoiceNo, BillNo, PayAmount[2], ApplyFromGenJnlLine);
    end;

    local procedure PostPaymentApplyingToBill(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; InvoiceNo: Code[20]; BillNo: Code[20]; PayAmount: Decimal; ApplyFromJournal: Boolean): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        exit(
          CreatePostGenJnlLine(GenJnlLine."Document Type"::Payment, AccType, AccNo, PayAmount,
            ApplyFromJournal, GenJnlLine."Applies-to Doc. Type"::Bill, InvoiceNo, BillNo));
    end;

    local procedure PostReceivablesBillGroupOnSalesInvoice() CustLedgerEntryNo: Integer
    var
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        InvoiceNo: Code[20];
    begin
        CreateCustomer(Customer);
        InvoiceNo := CreateAndPostSalesInvoice(Customer);
        CreateBillGroup(BillGroup);
        AddDocToBillGroup(BillGroup."No.", InvoiceNo);
        CustLedgerEntryNo := GetCustLedgerEntryNo(InvoiceNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        exit(CustLedgerEntryNo);
    end;

    local procedure CreatePostGenJnlLine(DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; EntryAmount: Decimal; ApplyFromGenJnlLine: Boolean; ApplDocType: Enum "Gen. Journal Document Type"; ApplDocNo: Code[20]; ApplToBillNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        InitGenJnlLineWithBatch(GenJnlLine);
        CreateGenJnlLine(
          GenJnlLine, DocType, AccType, AccNo, EntryAmount, ApplyFromGenJnlLine, ApplDocType, ApplDocNo, ApplToBillNo);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        ApplyPaymentToBill(AccType, GenJnlLine."Document No.", ApplDocNo, ApplToBillNo, ApplyFromGenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreatePostSimpleGenJnlLine(JournalTemplateName: Code[20]; JournalBatchName: Code[20]; DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; EntryAmount: Decimal): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        InitGenJnlLineWithGivenBatch(GenJnlLine, JournalTemplateName, JournalBatchName);
        CreateGenJnlLine(
          GenJnlLine, DocType, AccType, AccNo, EntryAmount, false, "Gen. Journal Document Type"::" ", '', '');
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreatePostSeveralGenJnlLines(JournalTemplateName: Code[20]; JournalBatchName: Code[20]; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        LineAmount: Decimal;
    begin
        InitGenJnlLineWithGivenBatch(GenJnlLine, JournalTemplateName, JournalBatchName);
        CreateGenJnlLineNoBalanceAcc(GenJnlLine, GenJnlLine."Document Type"::Payment, AccType, AccNo, 0);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJnlLine);
        LineAmount := GenJnlLine.Amount;
        InitGenJnlLineWithGivenBatch(GenJnlLine, JournalTemplateName, JournalBatchName);
        CreateGenJnlLineNoBalanceAcc(GenJnlLine, GenJnlLine."Document Type"::Bill, AccType, AccNo, -LineAmount);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreateGenJnlLineWithSpecialDocNo(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; EntryAmount: Decimal; ApplyFromGenJnlLine: Boolean; ApplDocType: Enum "Gen. Journal Document Type"; ApplDocNo: Code[20]; ApplToBillNo: Code[20])
    begin
        CreateGenJnlLine(GenJnlLine, DocType, AccType, AccNo, EntryAmount, ApplyFromGenJnlLine, ApplDocType, ApplDocNo, ApplToBillNo);
        GenJnlLine.Validate("Document No.", DocNo);
        GenJnlLine.Modify(true);
    end;

    local procedure CreateGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; EntryAmount: Decimal; ApplyFromGenJnlLine: Boolean; ApplDocType: Enum "Gen. Journal Document Type"; ApplDocNo: Code[20]; ApplToBillNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name",
            DocType, AccType, AccNo, EntryAmount);
        if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Bill then begin
            GenJnlLine.Validate(
              "Bill No.", LibraryUtility.GenerateRandomCode(GenJnlLine.FieldNo("Bill No."), DATABASE::"Gen. Journal Line"));
            GenJnlLine.Validate("Payment Method Code", GetPaymentMethodCartera());
        end;
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        if ApplyFromGenJnlLine then begin
            GenJnlLine.Validate("Applies-to Doc. Type", ApplDocType);
            GenJnlLine.Validate("Applies-to Doc. No.", ApplDocNo);
            GenJnlLine.Validate("Applies-to Bill No.", ApplToBillNo);
        end;
        GenJnlLine.Modify(true);
    end;

    local procedure CreateGenJnlLineNoBalanceAcc(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; EntryAmount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name",
            DocType, AccType, AccNo, EntryAmount);
        if GenJnlLine."Document Type" = GenJnlLine."Document Type"::Bill then begin
            GenJnlLine.Validate(
              "Bill No.", LibraryUtility.GenerateRandomCode(GenJnlLine.FieldNo("Bill No."), DATABASE::"Gen. Journal Line"));
            GenJnlLine.Validate("Payment Method Code", GetPaymentMethodCartera());
        end;
        GenJnlLine.Modify(true);
    end;

    local procedure CreatePostDocsForCustVend(AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if AccType = GenJnlLine."Account Type"::Customer then
            FindGenJnlBatch(GenJnlBatch, GenJournalTemplate.Type::"Cash Receipts")
        else
            FindGenJnlBatch(GenJnlBatch, GenJournalTemplate.Type::Payments);
        CreatePostSimpleGenJnlLine(
          GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          AccType, AccNo, Amount);
        FindGenJnlBatch(GenJnlBatch, GenJournalTemplate.Type::Cartera);
        exit(
          CreatePostSeveralGenJnlLines(
            GenJnlBatch."Journal Template Name", GenJnlBatch.Name, AccType, AccNo));
    end;

    local procedure CreateGenJnlBatchWithTextCode(var GenJnlBatch: Record "Gen. Journal Batch"; JnlTemplateName: Code[10])
    var
        AlphabeticTextOption: Option Capitalized,Literal;
    begin
        GenJnlBatch.Init();
        GenJnlBatch.Validate("Journal Template Name", JnlTemplateName);
        GenJnlBatch.Validate(Name,
          LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(GenJnlBatch.Name), AlphabeticTextOption::Capitalized));
        GenJnlBatch.Insert(true);
    end;

    local procedure CreateCarteraGenJnlTemplateWithBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        RemoveExistingCarteraTemplates(); // to have one cartera template and avoid passing of template name in handler
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Force Doc. Balance", false);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Cartera);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateAnalysisView(var AnalysisView: Record "Analysis View")
    begin
        LibraryERM.CreateAnalysisView(AnalysisView);
        AnalysisView.Validate("Update on Posting", true);
        AnalysisView.Modify();
    end;

    local procedure RemoveExistingCarteraTemplates()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Cartera);
        GenJournalTemplate.DeleteAll(true);
    end;

    local procedure SetAppliesToIDInGenJournalLine(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.Validate("Applies-to ID", UserId);
        GenJnlLine.Modify(true);
    end;

    local procedure ApplyPaymentToBillFromGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; ApplyFromJournal: Boolean; InvoiceNo: Code[20]; BillNo: array[2] of Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        i: Integer;
    begin
        if not ApplyFromJournal then
            exit;

        SetAppliesToIDInGenJournalLine(GenJnlLine);
        for i := 1 to 2 do
            case GenJnlLine."Account Type" of
                GenJnlLine."Account Type"::Customer:
                    begin
                        FindBillCustLedgEntry(CustLedgEntry, InvoiceNo, BillNo[i]);
                        LibraryERM.SetAppliestoIdCustomer(CustLedgEntry);
                    end;
                GenJnlLine."Account Type"::Vendor:
                    begin
                        FindBillVendLedgEntry(VendLedgEntry, InvoiceNo, BillNo[i]);
                        LibraryERM.SetAppliestoIdVendor(VendLedgEntry);
                    end;
            end;
    end;

    local procedure ApplyPaymentToBill(AccType: Enum "Gen. Journal Account Type"; PayNo: Code[20]; InvoiceNo: Code[20]; BillNo: Code[20]; AppliedFromGenJnlLine: Boolean)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if AppliedFromGenJnlLine then
            exit;

        case AccType of
            GenJnlLine."Account Type"::Customer:
                ApplyPaymentToBillFromCustLedgEntry(PayNo, InvoiceNo, BillNo);
            GenJnlLine."Account Type"::Vendor:
                ApplyPaymentToBillFromVendLedgEntry(PayNo, InvoiceNo, BillNo);
        end;
    end;

    local procedure ApplyPaymentToBillFromCustLedgEntry(PayNo: Code[20]; InvoiceNo: Code[20]; BillNo: Code[20])
    var
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AmountToApply: Decimal;
    begin
        LibraryERM.FindCustomerLedgerEntry(
          ApplyingCustLedgerEntry, ApplyingCustLedgerEntry."Document Type"::Payment, PayNo);
        ApplyingCustLedgerEntry.CalcFields("Remaining Amount");
        AmountToApply := ApplyingCustLedgerEntry."Remaining Amount";
        LibraryERM.SetApplyCustomerEntry(
          ApplyingCustLedgerEntry, AmountToApply);

        FindBillCustLedgEntry(CustLedgerEntry, InvoiceNo, BillNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.Validate("Amount to Apply", GetMin(CustLedgerEntry."Remaining Amount", -AmountToApply));
        CustLedgerEntry.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        LibraryERM.PostCustLedgerApplication(ApplyingCustLedgerEntry);
    end;

    local procedure ApplyPaymentToBillFromVendLedgEntry(PayNo: Code[20]; InvoiceNo: Code[20]; BillNo: Code[20])
    var
        ApplyingVendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        AmountToApply: Decimal;
    begin
        LibraryERM.FindVendorLedgerEntry(
          ApplyingVendLedgerEntry, ApplyingVendLedgerEntry."Document Type"::Payment, PayNo);
        ApplyingVendLedgerEntry.CalcFields("Remaining Amount");
        AmountToApply := ApplyingVendLedgerEntry."Remaining Amount";
        LibraryERM.SetApplyVendorEntry(
          ApplyingVendLedgerEntry, AmountToApply);

        FindBillVendLedgEntry(VendLedgEntry, InvoiceNo, BillNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        VendLedgEntry.Validate("Amount to Apply", GetMin(VendLedgEntry."Remaining Amount", -AmountToApply));
        VendLedgEntry.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendLedgEntry);
        LibraryERM.PostVendLedgerApplication(ApplyingVendLedgerEntry);
    end;

    local procedure ApplyPostSalesCreditMemoToInvoice(SalesLine: Record "Sales Line"; ApplyDocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesLine."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", SalesLine.Quantity);
        SalesHeader."Applies-to Doc. Type" := SalesHeader."Applies-to Doc. Type"::Invoice;
        SalesHeader."Applies-to Doc. No." := ApplyDocumentNo;
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true))
    end;

    local procedure ApplyPostPurchaseCreditMemoToInvoice(PurchaseLine: Record "Purchase Line"; ApplyDocumentNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchaseLine."No.", PurchaseLine.Quantity);
        PurchaseHeader."Applies-to Doc. Type" := PurchaseHeader."Applies-to Doc. Type"::Invoice;
        PurchaseHeader."Applies-to Doc. No." := ApplyDocumentNo;
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true))
    end;

    local procedure AddDocToBillGroup(BillGroupNo: Code[20]; InvoiceNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", InvoiceNo);
        CarteraDoc.FindFirst();
        CarteraDoc.Validate("Bill Gr./Pmt. Order No.", BillGroupNo);
        CarteraDoc.Modify(true);
    end;

    local procedure GetCustLedgerEntryNo(DocNo: Code[20]): Integer
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", DocNo);
        CarteraDoc.FindFirst();
        exit(CarteraDoc."Entry No.");
    end;

    local procedure GetCustVendLedgerEntryNoWithPostedCarteraDoc(DocNo: Code[20]): Integer
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        PostedCarteraDoc.SetRange("Document No.", DocNo);
        PostedCarteraDoc.FindFirst();
        exit(PostedCarteraDoc."Entry No.");
    end;

    local procedure GetCustVendLedgerEntryNoWithClosedCarteraDoc(DocNo: Code[20]): Integer
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        ClosedCarteraDoc.SetRange("Document No.", DocNo);
        ClosedCarteraDoc.FindFirst();
        exit(ClosedCarteraDoc."Entry No.");
    end;

    local procedure GetPostedCarteraDocNo(BankAccountNo: Code[20]): Code[20]
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        PostedCarteraDoc.SetRange("Bank Account No.", BankAccountNo);
        PostedCarteraDoc.FindFirst();
        exit(PostedCarteraDoc."Document No.");
    end;

    local procedure GetClosedCarteraDocNo(BankAccountNo: Code[20]): Code[20]
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        ClosedCarteraDoc.SetRange("Bank Account No.", BankAccountNo);
        ClosedCarteraDoc.FindFirst();
        exit(ClosedCarteraDoc."Document No.");
    end;

    local procedure GetEntryAmount(AccType: Enum "Gen. Journal Account Type"; DocType: Enum "Gen. Journal Document Type") Amt: Decimal
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        Amt := LibraryRandom.RandDec(100, 2);
        if (AccType = GenJnlLine."Account Type"::Vendor) xor (DocType = GenJnlLine."Document Type"::"Credit Memo") then
            Amt := -Amt;
    end;

    local procedure GetGenPostType(AccType: Enum "Gen. Journal Account Type"): Enum "General Posting Type"
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case AccType of
            GenJnlLine."Account Type"::Customer:
                exit(GenJnlLine."Gen. Posting Type"::Sale);
            GenJnlLine."Account Type"::Vendor:
                exit(GenJnlLine."Gen. Posting Type"::Purchase);
        end;
    end;

    local procedure CreatePostAppliedDoc(var GenJnlLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    var
        ApplDocType: Enum "Gen. Journal Document Type";
        ApplDocNo: Code[20];
        EntryAmount: Decimal;
    begin
        ApplDocType := GenJnlLine."Document Type";
        ApplDocNo := GenJnlLine."Document No.";
        EntryAmount := GenJnlLine.Amount;
        InitGenJnlLineWithBatch(GenJnlLine);
        LibraryERM.CreateGeneralJnlLine(
          GenJnlLine, GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name",
          GetAppliedDocType(DocType), AccType, AccNo, EntryAmount);
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlLine.Validate("Applies-to Doc. Type", ApplDocType);
        GenJnlLine.Validate("Applies-to Doc. No.", ApplDocNo);
        GenJnlLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure GetAppliedDocType(DocType: Enum "Gen. Journal Document Type"): Enum "General Posting Type"
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        case DocType of
            GenJnlLine."Document Type"::Invoice:
                exit(GenJnlLine."Document Type"::Payment);
            GenJnlLine."Document Type"::"Credit Memo":
                exit(GenJnlLine."Document Type"::Refund);
        end;
    end;

    local procedure SalesUnrealVATPayToBill(VATDistributionType: Option; PayAmountDiff: Decimal; ApplyFromGenJnlLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        CustNo: Code[20];
        InvoiceNo: Code[20];
        BillNo: Code[20];
        PayNo: Code[20];
        InvAmount: Decimal;
        PayAmount: Decimal;
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateUnrealVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());

        CustNo :=
          CreateCustWithPaymentTermsAndVATGroup(VATDistributionType, VATPostingSetup."VAT Bus. Posting Group");
        InvoiceNo :=
          CreatePostSalesInvoiceWithVATGroup(InvAmount, CustNo, VATPostingSetup."VAT Prod. Posting Group");
        BillNo :=
          CreateApplyPostBillToInvoice(GenJnlLine."Account Type"::Customer, CustNo, InvAmount, InvoiceNo);
        PayAmount := PayAmountDiff - InvAmount;
        PayNo :=
          PostPaymentApplyingToBill(GenJnlLine."Account Type"::Customer, CustNo, InvoiceNo, BillNo, PayAmount, ApplyFromGenJnlLine);
        CalcAmtAndVerifyEntries(VATPostingSetup, CustNo, PayNo, InvAmount, PayAmount);

        UpdateUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type",
          VATPostingSetup."Purch. VAT Unreal. Account", VATPostingSetup."Sales VAT Unreal. Account");
    end;

    local procedure PurchUnrealVATPayToBill(VATDistributionType: Option; PayAmountDiff: Decimal; ApplyFromGenJnlLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJnlLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        InvoiceNo: Code[20];
        BillNo: Code[20];
        PayNo: Code[20];
        InvAmount: Decimal;
        PayAmount: Decimal;
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateUnrealVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());

        VendNo :=
          CreateVendWithPaymentTermsAndVATGroup(VATDistributionType, VATPostingSetup."VAT Bus. Posting Group");
        InvoiceNo :=
          CreatePostPurchInvoiceWithVATGroup(InvAmount, VendNo, VATPostingSetup."VAT Prod. Posting Group");
        BillNo :=
          CreateApplyPostBillToInvoice(GenJnlLine."Account Type"::Vendor, VendNo, -InvAmount, InvoiceNo);
        PayAmount := InvAmount - PayAmountDiff;
        PayNo :=
          PostPaymentApplyingToBill(GenJnlLine."Account Type"::Vendor, VendNo, InvoiceNo, BillNo, PayAmount, ApplyFromGenJnlLine);
        CalcAmtAndVerifyEntries(VATPostingSetup, VendNo, PayNo, -InvAmount, PayAmount);

        UpdateUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type",
          VATPostingSetup."Purch. VAT Unreal. Account", VATPostingSetup."Sales VAT Unreal. Account");
    end;

    local procedure SalesUnrealVATPayToDoubleBill(ApplyFromGenJnlLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        CustNo: Code[20];
        InvoiceNo: Code[20];
        BillNo: array[2] of Code[20];
        PayNo: Code[20];
        InvAmount: Decimal;
        PayAmount: Decimal;
        BillAmount: Decimal;
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateUnrealVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());

        CustNo :=
          CreateCustWithPaymentTermsAndVATGroup(PaymentTerms."VAT distribution"::Proportional, VATPostingSetup."VAT Bus. Posting Group");
        InvoiceNo :=
          CreatePostSalesInvoiceWithVATGroup(InvAmount, CustNo, VATPostingSetup."VAT Prod. Posting Group");
        CreateApplyPostBillToBillToInvoice(
          BillNo, BillAmount, GenJnlLine."Account Type"::Customer, CustNo, InvoiceNo, InvAmount);
        PayAmount := -BillAmount;
        PayNo :=
          PostPaymentApplyingToBill(GenJnlLine."Account Type"::Customer, CustNo, InvoiceNo, BillNo[1], PayAmount, ApplyFromGenJnlLine);

        CalcAmtAndVerifyEntries(VATPostingSetup, CustNo, PayNo, InvAmount, PayAmount);

        UpdateUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type",
          VATPostingSetup."Purch. VAT Unreal. Account", VATPostingSetup."Sales VAT Unreal. Account");
    end;

    local procedure PurchUnrealVATPayToDoubleBill(ApplyFromGenJnlLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        InvoiceNo: Code[20];
        BillNo: array[2] of Code[20];
        PayNo: Code[20];
        InvAmount: Decimal;
        PayAmount: Decimal;
        BillAmount: Decimal;
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateUnrealVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());

        VendNo :=
          CreateVendWithPaymentTermsAndVATGroup(PaymentTerms."VAT distribution"::Proportional, VATPostingSetup."VAT Bus. Posting Group");
        InvoiceNo :=
          CreatePostPurchInvoiceWithVATGroup(InvAmount, VendNo, VATPostingSetup."VAT Prod. Posting Group");
        CreateApplyPostBillToBillToInvoice(
          BillNo, BillAmount, GenJnlLine."Account Type"::Vendor, VendNo, InvoiceNo, -InvAmount);
        PayAmount := -BillAmount;
        PayNo :=
          PostPaymentApplyingToBill(GenJnlLine."Account Type"::Vendor, VendNo, InvoiceNo, BillNo[1], PayAmount, ApplyFromGenJnlLine);

        CalcAmtAndVerifyEntries(VATPostingSetup, VendNo, PayNo, InvAmount, PayAmount);

        UpdateUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type",
          VATPostingSetup."Purch. VAT Unreal. Account", VATPostingSetup."Sales VAT Unreal. Account");
    end;

    local procedure SalesUnrealVATSeveralPaysToBill(ApplyFromGenJnlLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        CustNo: Code[20];
        InvoiceNo: Code[20];
        BillNo: Code[20];
        PayNo: array[2] of Code[20];
        InvAmount: Decimal;
        PayAmount: array[2] of Decimal;
        i: Integer;
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateUnrealVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());

        CustNo :=
          CreateCustWithPaymentTermsAndVATGroup(PaymentTerms."VAT distribution"::Proportional, VATPostingSetup."VAT Bus. Posting Group");
        InvoiceNo :=
          CreatePostSalesInvoiceWithVATGroup(InvAmount, CustNo, VATPostingSetup."VAT Prod. Posting Group");
        BillNo :=
          CreateApplyPostBillToInvoice(GenJnlLine."Account Type"::Customer, CustNo, InvAmount, InvoiceNo);
        CreateApplyPostSeveralPaysToBill(
          PayNo, PayAmount, GenJnlLine."Account Type"::Customer, CustNo, InvoiceNo, InvAmount, BillNo, ApplyFromGenJnlLine);

        for i := 1 to 2 do
            CalcAmtAndVerifyEntries(VATPostingSetup, CustNo, PayNo[i], InvAmount, PayAmount[i]);

        UpdateUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type",
          VATPostingSetup."Purch. VAT Unreal. Account", VATPostingSetup."Sales VAT Unreal. Account");
    end;

    local procedure PurchUnrealVATSeveralPaysToBill(ApplyFromGenJnlLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        InvoiceNo: Code[20];
        BillNo: Code[20];
        PayNo: array[2] of Code[20];
        InvAmount: Decimal;
        PayAmount: array[2] of Decimal;
        i: Integer;
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateUnrealVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());

        VendNo :=
          CreateVendWithPaymentTermsAndVATGroup(PaymentTerms."VAT distribution"::Proportional, VATPostingSetup."VAT Bus. Posting Group");
        InvoiceNo :=
          CreatePostPurchInvoiceWithVATGroup(InvAmount, VendNo, VATPostingSetup."VAT Prod. Posting Group");
        BillNo :=
          CreateApplyPostBillToInvoice(GenJnlLine."Account Type"::Vendor, VendNo, -InvAmount, InvoiceNo);
        CreateApplyPostSeveralPaysToBill(
          PayNo, PayAmount, GenJnlLine."Account Type"::Vendor, VendNo, InvoiceNo, -InvAmount, BillNo, ApplyFromGenJnlLine);

        for i := 1 to 2 do
            CalcAmtAndVerifyEntries(VATPostingSetup, VendNo, PayNo[i], InvAmount, PayAmount[i]);

        UpdateUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type",
          VATPostingSetup."Purch. VAT Unreal. Account", VATPostingSetup."Sales VAT Unreal. Account");
    end;

    local procedure SalesUnrealVATPayToSeveralBills(ApplyFromGenJnlLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        CustNo: Code[20];
        InvoiceNo: Code[20];
        BillNo: array[2] of Code[20];
        PayNo: Code[20];
        InvAmount: Decimal;
        BillAmount: array[2] of Decimal;
        PayAmount: Decimal;
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateUnrealVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());

        CustNo :=
          CreateCustWithPaymentTermsAndVATGroup(PaymentTerms."VAT distribution"::Proportional, VATPostingSetup."VAT Bus. Posting Group");
        InvoiceNo :=
          CreatePostSalesInvoiceWithVATGroup(InvAmount, CustNo, VATPostingSetup."VAT Prod. Posting Group");
        CreateApplyPostSeveralBillsToInvoice(
          BillNo, BillAmount, GenJnlLine."Account Type"::Customer, CustNo, InvoiceNo, InvAmount);
        PayAmount := -InvAmount;
        PayNo :=
          CreatePostPaymentToSeveralBills(
            GenJnlLine."Account Type"::Customer, CustNo, InvoiceNo, BillNo, PayAmount, ApplyFromGenJnlLine);

        CalcAmtAndVerifyMultipleEntries(VATPostingSetup, CustNo, PayNo, InvAmount, BillAmount);

        UpdateUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type",
          VATPostingSetup."Purch. VAT Unreal. Account", VATPostingSetup."Sales VAT Unreal. Account");
    end;

    local procedure PurchUnrealVATPayToSeveralBills(ApplyFromGenJnlLine: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        VendNo: Code[20];
        InvoiceNo: Code[20];
        BillNo: array[2] of Code[20];
        PayNo: Code[20];
        InvAmount: Decimal;
        BillAmount: array[2] of Decimal;
        PayAmount: Decimal;
    begin
        Initialize();
        UpdateGenLedgVATSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        UpdateUnrealVATPostingSetup(
          VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, LibraryERM.CreateGLAccountNo(), LibraryERM.CreateGLAccountNo());

        VendNo :=
          CreateVendWithPaymentTermsAndVATGroup(PaymentTerms."VAT distribution"::Proportional, VATPostingSetup."VAT Bus. Posting Group");
        InvoiceNo :=
          CreatePostPurchInvoiceWithVATGroup(InvAmount, VendNo, VATPostingSetup."VAT Prod. Posting Group");
        CreateApplyPostSeveralBillsToInvoice(
          BillNo, BillAmount, GenJnlLine."Account Type"::Vendor, VendNo, InvoiceNo, -InvAmount);
        PayAmount := InvAmount;
        PayNo :=
          CreatePostPaymentToSeveralBills(
            GenJnlLine."Account Type"::Vendor, VendNo, InvoiceNo, BillNo, PayAmount, ApplyFromGenJnlLine);

        CalcAmtAndVerifyMultipleEntries(VATPostingSetup, VendNo, PayNo, InvAmount, BillAmount);

        UpdateUnrealVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type",
          VATPostingSetup."Purch. VAT Unreal. Account", VATPostingSetup."Sales VAT Unreal. Account");
    end;

    local procedure GetPaymentMethodCartera(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.FindPaymentMethodCartea(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    local procedure GetAmountPart(Amount: Decimal): Decimal
    begin
        exit(Round(Amount / 7, GetAmountRoundingPrecision()));
    end;

    local procedure GetAmountRoundingPrecision(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Amount Rounding Precision");
    end;

    local procedure GetUnrealVATBase(InvAmount: Decimal; PayAmount: Decimal): Decimal
    begin
        if Abs(PayAmount) > Abs(InvAmount) then
            exit(-InvAmount);
        exit(PayAmount);
    end;

    local procedure GetMin(FirstValue: Decimal; SecondValue: Decimal): Decimal
    begin
        if Abs(FirstValue) > Abs(SecondValue) then
            exit(SecondValue);
        exit(FirstValue);
    end;

    local procedure GetAmtRoundingPrecision(CurrencyCode: Code[10]): Decimal
    begin
        exit(LibraryERM.GetCurrencyAmountRoundingPrecision(CurrencyCode));
    end;

    local procedure CalcVATAmount(InvAmount: Decimal; PayAmount: Decimal; VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        exit(
          Round(GetUnrealVATBase(InvAmount, PayAmount) * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"),
            GetAmountRoundingPrecision()));
    end;

    local procedure FindBillCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; InvoiceNo: Code[20]; BillNo: Code[20])
    begin
        CustLedgEntry.SetRange("Bill No.", BillNo);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgEntry, CustLedgEntry."Document Type"::Bill, InvoiceNo);
    end;

    local procedure FindBillVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; InvoiceNo: Code[20]; BillNo: Code[20])
    begin
        VendLedgEntry.SetRange("Bill No.", BillNo);
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::Bill, InvoiceNo);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLEntry.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AccNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", AccNo);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.FindFirst();
    end;

    local procedure FindDocumentVATEntry(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.FindFirst();
    end;

    local procedure RunSettleDocs(BankAccountNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        SettleDocsInPostedBillGroup: Report "Settle Docs. in Post. Bill Gr.";
    begin
        PostedCarteraDoc.SetRange("Bank Account No.", BankAccountNo);
        SettleDocsInPostedBillGroup.SetHidePrintDialog(true);
        SettleDocsInPostedBillGroup.SetTableView(PostedCarteraDoc);
        SettleDocsInPostedBillGroup.Run();
    end;

    local procedure FindCarteraGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
    end;

    local procedure EnqueueCarteraGenJnlBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // used in PostBillGroupRequestPageHandler
        FindCarteraGenJnlBatch(GenJournalBatch);
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchOrderWithDimension(Vendor: Record Vendor; var DimSetId: Integer): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        DimValue: Record "Dimension Value";
        DefaultDim: Record "Default Dimension";
    begin
        CreateDimValue(DimValue);
        LibraryDimension.CreateDefaultDimension(
            DefaultDim, DATABASE::Vendor, Vendor."No.", DimValue."Dimension Code", DimValue.Code);
        DefaultDim.Validate("Value Posting", DefaultDim."Value Posting"::"Same Code");
        DefaultDim.Modify(true);

        CreatePurchHeaderWithDimension(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        DimSetId := PurchaseHeader."Dimension Set ID";
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePurchHeaderWithDimension(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; VendNo: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendNo);
        LibrarySales.FindItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", Item."Unit Price");
        PurchaseLine.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RejectDocsHandler(var RejectDocs: TestRequestPage "Reject Docs.")
    begin
        RejectDocs.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ReceivablePostOnlyHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure RejectDocumentMessageHandler(Question: Text[1024])
    begin
        // dummy handler
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawDocumentHandler(var RedrawReceivableBills: TestRequestPage "Redraw Receivable Bills")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FindCarteraGenJnlBatch(GenJournalBatch);
        RedrawReceivableBills.NewDueDate.SetValue(CalcDate(StrSubstNo('<%1M>', Format(LibraryRandom.RandInt(5))), WorkDate()));
        RedrawReceivableBills.AuxJnlTemplateName.SetValue(GenJournalBatch."Journal Template Name");
        RedrawReceivableBills.AuxJnlBatchName.SetValue(GenJournalBatch.Name);
        RedrawReceivableBills.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawDocumentWithSpecificBatchHandler(var RedrawReceivableBills: TestRequestPage "Redraw Receivable Bills")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        DueDate: Variant;
        BatchName: Variant;
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Cartera);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);

        LibraryVariableStorage.Dequeue(BatchName);
        LibraryVariableStorage.Dequeue(DueDate);

        RedrawReceivableBills.NewDueDate.SetValue(DueDate);
        RedrawReceivableBills.AuxJnlTemplateName.SetValue(GenJournalTemplate.Name);
        RedrawReceivableBills.AuxJnlBatchName.SetValue(BatchName);
        RedrawReceivableBills.OK().Invoke();

        LibraryVariableStorage.Enqueue(BatchName);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraJournalHandler(var CarteraJournal: TestPage "Cartera Journal")
    begin
        CarteraJournal.Post.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler2(Message: Text)
    begin
        Assert.AreEqual(0, StrPos(Message, JournalMustBePostedMsg), CarteraJournalErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettleDocsInPostedBillGroupRequestPageHandler(var SettleDocsInPostedBillGroup: TestRequestPage "Settle Docs. in Post. Bill Gr.")
    begin
        SettleDocsInPostedBillGroup.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettleDocsInPostedPaymentOrderRequestPageHandler(var SettleDocsInPostedPO: TestRequestPage "Settle Docs. in Posted PO")
    begin
        SettleDocsInPostedPO.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PartialSettlReceivableRequestPageHandler(var PartialSettlReceivableRequestPage: TestRequestPage "Partial Settl.- Receivable")
    begin
        PartialSettlReceivableRequestPage.SettledAmount.SetValue(
          PartialSettlReceivableRequestPage.SettledAmount.AsDecimal() / 2); // Settled Amt
        PartialSettlReceivableRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PartialSettlPayableRequestPageHandler(var PartialSettlPayableRequestPage: TestRequestPage "Partial Settl. - Payable")
    begin
        PartialSettlPayableRequestPage.AppliedAmt.SetValue(
          PartialSettlPayableRequestPage.AppliedAmt.AsDecimal() / 2); // Settled Amt
        PartialSettlPayableRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawReceivableBillsRequestPageHandler(var RedrawReceivableBillsRequestPage: TestRequestPage "Redraw Receivable Bills")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DueDateVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DueDateVar);
        RedrawReceivableBillsRequestPage.NewDueDate.SetValue(DueDateVar);
        FindCarteraGenJnlBatch(GenJournalBatch);
        RedrawReceivableBillsRequestPage.AuxJnlTemplateName.SetValue(GenJournalBatch."Journal Template Name");
        RedrawReceivableBillsRequestPage.AuxJnlBatchName.SetValue(GenJournalBatch.Name);
        RedrawReceivableBillsRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RedrawPayableBillsRequestPageHandler(var RedrawPayableBillsRequestPage: TestRequestPage "Redraw Payable Bills")
    var
        DueDateVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(DueDateVar);
        RedrawPayableBillsRequestPage.NewDueDate.SetValue(DueDateVar);
        RedrawPayableBillsRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostBillGroupRequestPageHandler(var PostBillGroup: TestRequestPage "Post Bill Group")
    begin
        PostBillGroup.TemplName.SetValue(LibraryVariableStorage.DequeueText());
        PostBillGroup.BatchName.SetValue(LibraryVariableStorage.DequeueText());
        PostBillGroup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraJournalModalPageHandler(var CarteraJournal: TestPage "Cartera Journal")
    begin
        CarteraJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraJournalCheckBatchHandler(var CarteraJournal: TestPage "Cartera Journal")
    var
        BatchName: Variant;
    begin
        LibraryVariableStorage.Dequeue(BatchName);
        CarteraJournal.CurrentJnlBatchName.AssertEquals(BatchName);
        CarteraJournal.Post.Invoke(); // post in order to close the page
    end;

    local procedure VerifyCustomerLedgerEntry(Customer: Record Customer; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentStatus: Enum "ES Document Status"; Amount: Decimal; RemainingAmount: Decimal)
    var
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustomerLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustomerLedgerEntry.SetRange("Document No.", DocumentNo);
        CustomerLedgerEntry.SetRange("Document Type", DocumentType);
        CustomerLedgerEntry.SetRange("Document Status", DocumentStatus);

        CustomerLedgerEntry.FindFirst();
        Assert.IsTrue(CustomerLedgerEntry.Amount = Amount, Text001);
        Assert.IsTrue(CustomerLedgerEntry."Remaining Amount" = RemainingAmount, Text001);
    end;

    local procedure VerifyVATEntryTransaction(PostingDate: Date; DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.Reset();
        VATEntry.SetFilter("Entry No.", '<>%1', VATEntry."Entry No.");
        VATEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
        Assert.IsTrue(VATEntry.IsEmpty, VATEntryError);
    end;

    local procedure CalcAmtAndVerifyEntries(VATPostingSetup: Record "VAT Posting Setup"; CustNo: Code[20]; PayNo: Code[20]; InvAmount: Decimal; PayAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        VerifyGLAndVATEntry(
          CustNo, GenJnlLine."Document Type"::Payment, PayNo, VATPostingSetup, CalcVATAmount(InvAmount, PayAmount, VATPostingSetup));
    end;

    local procedure CalcAmtAndVerifyMultipleEntries(VATPostingSetup: Record "VAT Posting Setup"; CustNo: Code[20]; PayNo: Code[20]; InvAmount: Decimal; PayAmount: array[2] of Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        VATAmount: array[2] of Decimal;
        i: Integer;
    begin
        for i := 1 to 2 do
            VATAmount[i] :=
              CalcVATAmount(InvAmount, -PayAmount[i], VATPostingSetup);
        VerifyMultipleGLAndVATEntry(
          CustNo, GenJnlLine."Document Type"::Payment, PayNo, VATPostingSetup, VATAmount);
    end;

    local procedure VerifyGLAndVATEntriesByVATPostingSetup(VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; CustNo: Code[20]; PayNo: Code[20]; LineAmtInclVAT: Decimal; PayAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroupCode, VATProdPostingGroupCode);
        CalcAmtAndVerifyEntries(
          VATPostingSetup, CustNo, PayNo, LineAmtInclVAT, PayAmount);
    end;

    local procedure VerifyGLAndVATEntry(AccNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; VATAmount: Decimal)
    begin
        VerifyGLEntry(DocType, DocNo, VATPostingSetup, VATAmount, false);
        VerifyVATEntry(AccNo, DocType, DocNo, VATPostingSetup, '', VATAmount, false);
    end;

    local procedure VerifyMultipleGLAndVATEntry(AccNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; VATAmount: array[2] of Decimal)
    var
        GetNextEntry: Boolean;
        i: Integer;
    begin
        for GetNextEntry := false to true do begin
            i += 1;
            VerifyGLEntry(DocType, DocNo, VATPostingSetup, VATAmount[i], GetNextEntry);
            VerifyVATEntry(AccNo, DocType, DocNo, VATPostingSetup, '', VATAmount[i], GetNextEntry);
        end;
    end;

    local procedure VerifyGLEntry(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; VATAmount: Decimal; GetNextEntry: Boolean)
    var
        GenLedgSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
    begin
        GenLedgSetup.Get();
        FindGLEntry(GLEntry, DocNo, DocType, VATPostingSetup);
        if GetNextEntry then
            GLEntry.Next();
        Assert.AreNearlyEqual(
          VATAmount, GLEntry.Amount, GenLedgSetup."Amount Rounding Precision", StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount),
            VATAmount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure VerifyVATEntry(AccNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]; Amount: Decimal; GetNextEntry: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, DocNo, DocType, AccNo, VATPostingSetup);
        if GetNextEntry then
            VATEntry.Next();
        Assert.AreNearlyEqual(
          Amount, VATEntry.Amount, GetAmtRoundingPrecision(CurrencyCode),
          StrSubstNo(
            AmountErr, VATEntry.FieldCaption(Amount), Amount, VATEntry.TableCaption(), VATEntry.FieldCaption("Entry No."),
            VATEntry."Entry No."));
    end;

    local procedure VerifyVATEntryExists(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordIsNotEmpty(VATEntry);
    end;

    local procedure VerifyGLEntryExists(DocNo: Code[20]; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        Assert.IsFalse(GLEntry.IsEmpty, GLEntriesNotExistErr);
    end;

    local procedure VerifyGLEntryCount(DocNo: Code[20]; PostingDate: Date; EntryCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        Assert.AreEqual(EntryCount, GLEntry.Count, GLEntriesWrongCountErr);
    end;

    local procedure VerifyDefDimOfBankAccExistInGLEntry(BankAccNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        BankAccPostingGroup: Record "Bank Account Posting Group";
        DefDim: Record "Default Dimension";
        GLEntry: Record "G/L Entry";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        BankAccount.Get(BankAccNo);
        BankAccPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        GLEntry.SetRange("G/L Account No.", BankAccPostingGroup."G/L Account No.");
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::"Bank Account");
        GLEntry.SetRange("Source No.", BankAccount."No.");
        GLEntry.FindLast();

        DefDim.SetRange("Table ID", DATABASE::"Bank Account");
        DefDim.SetRange("No.", BankAccount."No.");
        DefDim.FindSet();
        repeat
            DimSetEntry.Get(GLEntry."Dimension Set ID", DefDim."Dimension Code");
            Assert.AreEqual(
              DefDim."Dimension Value Code", DimSetEntry."Dimension Value Code", StrSubstNo(IncorrectDimValueErr, GLEntry."Entry No."));
        until DefDim.Next() = 0;
    end;

    local procedure VerifyAppliedVATEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AppliedDocumentType: Enum "Gen. Journal Document Type"; AppliedDocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        VATEntryApplied: Record "VAT Entry";
    begin
        FindDocumentVATEntry(VATEntry, DocumentType, DocumentNo);
        FindDocumentVATEntry(VATEntryApplied, AppliedDocumentType, AppliedDocumentNo);

        Assert.AreEqual(-VATEntry."Unrealized Amount", VATEntryApplied."Unrealized Amount", FieldErrorMessage(VATEntryApplied.FieldCaption("Unrealized Amount")));
        Assert.AreEqual(-VATEntry."Unrealized Base", VATEntryApplied."Unrealized Base", FieldErrorMessage(VATEntryApplied.FieldCaption("Unrealized Base")));
        Assert.AreEqual(0, VATEntryApplied."Remaining Unrealized Amount", FieldErrorMessage(VATEntryApplied.FieldCaption("Remaining Unrealized Amount")));
        Assert.AreEqual(0, VATEntryApplied."Remaining Unrealized Base", FieldErrorMessage(VATEntryApplied.FieldCaption("Remaining Unrealized Base")));

        VATEntryApplied.FindLast();
        Assert.AreEqual(-VATEntry."Unrealized Amount", VATEntryApplied.Amount, FieldErrorMessage(VATEntryApplied.FieldCaption(Amount)));
        Assert.AreEqual(-VATEntry."Unrealized Base", VATEntryApplied.Base, FieldErrorMessage(VATEntryApplied.FieldCaption(Base)));
    end;

    local procedure VerifyVendLedgEntryApplicationExists(InvNo: Code[20]; CrMemoNo: Code[20])
    var
        BillVendLedgEntry: Record "Vendor Ledger Entry";
        CrMemoVendLedgEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(BillVendLedgEntry, BillVendLedgEntry."Document Type"::Bill, InvNo);
        LibraryERM.FindVendorLedgerEntry(CrMemoVendLedgEntry, CrMemoVendLedgEntry."Document Type"::"Credit Memo", CrMemoNo);
        DetailedVendLedgEntry.SetRange("Entry Type", DetailedVendLedgEntry."Entry Type"::Application);
        DetailedVendLedgEntry.SetRange("Vendor Ledger Entry No.", BillVendLedgEntry."Entry No.");
        DetailedVendLedgEntry.SetRange("Applied Vend. Ledger Entry No.", CrMemoVendLedgEntry."Entry No.");
        Assert.RecordIsNotEmpty(DetailedVendLedgEntry);
    end;

    local procedure VerifyCustLedgEntryApplicationExists(InvNo: Code[20]; CrMemoNo: Code[20])
    var
        BillCustLedgEntry: Record "Cust. Ledger Entry";
        CrMemoCustLedgEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(BillCustLedgEntry, BillCustLedgEntry."Document Type"::Bill, InvNo);
        LibraryERM.FindCustomerLedgerEntry(CrMemoCustLedgEntry, CrMemoCustLedgEntry."Document Type"::"Credit Memo", CrMemoNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", BillCustLedgEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.", CrMemoCustLedgEntry."Entry No.");
        Assert.RecordIsNotEmpty(DetailedCustLedgEntry);
    end;

    local procedure FieldErrorMessage(FieldCaption: Text): Text
    var
        VATEntry: Record "VAT Entry";
    begin
        exit(StrSubstNo(FieldErr, FieldCaption, VATEntry.TableCaption()))
    end;

    local procedure SetSalesAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        SalesReceivablesSetup."Check Multiple Posting Groups" := "Posting Group Change Method"::"Alternative Groups";
        SalesReceivablesSetup.Modify();
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; DocumentNo2: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustEntriesHandler(var ApplyCustEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustEntries.Last();
        repeat
            ApplyCustEntries."Set Applies-to ID".Invoke();
        until ApplyCustEntries.Previous() = false;
        ApplyCustEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendEntriesHandler(var ApplyVendEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendEntries.Last();
        repeat
            ApplyVendEntries.ActionSetAppliesToID.Invoke();
        until ApplyVendEntries.Previous() = false;
        ApplyVendEntries.OK().Invoke();
    end;
}

