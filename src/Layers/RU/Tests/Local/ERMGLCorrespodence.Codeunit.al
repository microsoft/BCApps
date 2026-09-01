codeunit 144016 "ERM G/L Correspodence"
{
    // // [FEATURE] [G/L Correspondence]

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "G/L Entry" = i;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        GLCorrEntryCountErr: Label 'G/L Correspondence Entry contains wrong number of entries.';
        GLCorrEntryErr: Label 'G/L Correspondence Entry with Debit Account No. %1, Credit Account No. %2, Amount %3 was not found.';
        TransVATType: Option " ","Amount + Tax","Amount & Tax";
        EntryType: Option Sale,Purchase;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoice()
    begin
        PurchaseInvoiceGLCorrespondence(TransVATType::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceAmountPlusTax()
    begin
        PurchaseInvoiceGLCorrespondence(TransVATType::"Amount + Tax");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceAmountAndTax()
    begin
        PurchaseInvoiceGLCorrespondence(TransVATType::"Amount & Tax");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice()
    begin
        SalesInvoiceGLCorrespondence(TransVATType::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceAmountPlusTax()
    begin
        SalesInvoiceGLCorrespondence(TransVATType::"Amount + Tax");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceAmountAndTax()
    begin
        SalesInvoiceGLCorrespondence(TransVATType::"Amount & Tax");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnPurchasePrepayment()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        GenJnlLine: Record "Gen. Journal Line";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
    begin
        // [FEATURE] [Purchase] [Prepayment]
        // [SCENARIO 362545] G/L Correspondence Entry is created when running Return Purchase Prepayment

        Initialize();
        // [GIVEN] Vendor with default posting group where "Payables Account" = "X" and "Prepayment Account" = "Y"
        LibraryPurchase.CreateVendor(Vendor);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        // [GIVEN] Post Purchase Prepayment
        PostPrepaymentGenJnlLine(GenJnlLine, GenJnlLine."Account Type"::Vendor, Vendor."No.");
        // [WHEN] Return Prepayment
        RunReturnPrepaymentReport(FindPmtVendLedgEntry(GenJnlLine."Document No."), EntryType::Purchase);
        // [THEN] G/L Correspondence Entry is created where "Debit Account No." = "X" and "Credit Account No." = "Y"
        SetGLCorrEntryFiltersAndVerify(
          GLCorrespondenceEntry, VendorPostingGroup."Payables Account", VendorPostingGroup."Prepayment Account", GenJnlLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLCorrEntriesCreationIsContinuedWhileGLEntriesCanBePaired()
    var
        GLEntry: Record "G/L Entry";
        GLCorrespManagement: Codeunit "G/L Corresp. Management";
        TransactionNo: Integer;
    begin
        // [SCENARIO 380769] G/L Correspondence entries should be created as long as there are G/L entries left to be paired. The sum of G/L Correspondence should be equal to the sum of debit G/L entries.
        Initialize();

        // [GIVEN] Pairs of debit and credit G/L Entries with single Transaction No. are created and shuffled thus all amounts are messed.
        MockMixedPairsOfGLEntriesInSingleTransaction(TransactionNo);

        // [WHEN] Create G/L Correspondence for the transaction.
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLCorrespManagement.CreateCorrespEntries(GLEntry);

        // [THEN] Sum of G/L correspondence Amount is equal to sum of G/L entries Debit Amount.
        VerifyGLCorrespondenceAmount(TransactionNo, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLCorrEntriesCreationIsStoppedWhenNoGLEntriesArePaired()
    var
        GLEntry: Record "G/L Entry";
        GLCorrespManagement: Codeunit "G/L Corresp. Management";
        TransactionNo: Integer;
        Amount: Decimal;
    begin
        // [SCENARIO 380769] Creation of G/L Correspondence entries is stopped when there is a pair of G/L entries split between transactions. The sum of G/L Corresp. should be less than the sum of debit G/L entries by the amount of the split entry.
        Initialize();

        // [GIVEN] Pairs of debit and credit G/L Entries with single Transaction No. "T" are created, then all entries are shuffled so the paired entries would not have adjacent Entry Nos.
        MockMixedPairsOfGLEntriesInSingleTransaction(TransactionNo);

        // [GIVEN] Pair of G/L Entries with Amount "X" split between transactions "T" and "T+1" is inserted.
        Amount := LibraryRandom.RandDecInRange(5, 10, 2);
        MockGLEntry(LibraryERM.CreateGLAccountNo(), Amount, 0, TransactionNo);
        MockGLEntry(LibraryERM.CreateGLAccountNo(), 0, Amount, TransactionNo + 1);

        // [WHEN] Create G/L Correspondence for the transaction "T".
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLCorrespManagement.CreateCorrespEntries(GLEntry);

        // [THEN] Sum of G/L correspondence Amount is less than sum of G/L entries Debit Amount by "X".
        VerifyGLCorrespondenceAmount(TransactionNo, Amount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InitialAndReversedGLCorrEntriesAreIdentical()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ReversalEntry: Record "Reversal Entry";
        GLRegister: Record "G/L Register";
        GLAccountNo: array[3] of Code[20];
        i: Integer;
    begin
        // [FEATURE] [Reverse]
        // [SCENARIO 201071] Initial and reversed G/L Correspondence Entries are identical except amount sign
        Initialize();
        for i := 1 to ArrayLen(GLAccountNo) do
            GLAccountNo[i] := LibraryERM.CreateGLAccountNo();
        CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] General journal with several lines having the same Document No., empty Bal. Account No.:
        // [GIVEN] "G/L Account No." = "A" Amount = 10
        // [GIVEN] "G/L Account No." = "B" Amount = 20
        // [GIVEN] "G/L Account No." = "C" Amount = 30
        // [GIVEN] "G/L Account No." = "B" Amount = -20
        // [GIVEN] "G/L Account No." = "A" Amount = -10
        // [GIVEN] "G/L Account No." = "C" Amount = -30
        CreateGenJnlLineWithGLAccount(GenJournalLine, GenJournalBatch, GLAccountNo[1], 10);
        CreateGenJnlLineWithGLAccount(GenJournalLine, GenJournalBatch, GLAccountNo[2], 20);
        CreateGenJnlLineWithGLAccount(GenJournalLine, GenJournalBatch, GLAccountNo[3], 30);
        CreateGenJnlLineWithGLAccount(GenJournalLine, GenJournalBatch, GLAccountNo[2], -20);
        CreateGenJnlLineWithGLAccount(GenJournalLine, GenJournalBatch, GLAccountNo[1], -10);
        CreateGenJnlLineWithGLAccount(GenJournalLine, GenJournalBatch, GLAccountNo[3], -30);
        // [GIVEN] Post the journal. "Initial" G/L Correspondence Entries have been created.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Reverse the last G/L Register. "Reversed" G/L Correspondence Entries have been created.
        GLRegister.FindLast();
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseRegister(GLRegister."No.");

        // [THEN] "Reversed" and "Initial" G/L Correspondence Entries are identical except amount sign
        VerifyInitialAndReversedGLCorrEntries(GLRegister."No.", GLRegister."No." + 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DoNotMatchEntriesWithSameGLAccountNoIfPossible()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        DummyPurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        GLCorrespManagement: Codeunit "G/L Corresp. Management";
        DocNo: Code[20];
        Qty: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Post Inventory Cost to G/L]
        // [SCENARIO 375755] G/L Correspondence does not match pair of G/L entries with the same G/L Account No. if alternate paired G/L entry can be found.
        Initialize();
        DocNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);
        UnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Disable automatic g/l correspondence.
        // [GIVEN] Disable automatic cost posting.
        SetAutomaticGLCorrespondence(false);
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Post purchase invoice and credit-memo for one item, quantity and amount are same.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseDocument("Purchase Document Type"::Invoice, Vendor."No.", Item."No.", Qty, UnitCost);
        CreateAndPostPurchaseDocument(DummyPurchaseHeader."Document Type"::"Credit Memo", Vendor."No.", Item."No.", Qty, UnitCost);

        // [GIVEN] Inventory Account for the item = "X".
        // [GIVEN] Direct Cost Applied Account = "Y".
        InventoryPostingSetup.Get('', Item."Inventory Posting Group");
        GeneralPostingSetup.Get(Vendor."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");

        // [GIVEN] Post inventory cost to G/L with "Per Posting Group" option.
        LibraryPostInventoryToGL.PostInvtCostToGL(true, WorkDate(), DocNo);

        // [WHEN] Create G/L Correspondence.
        GLEntry.SetRange("Document No.", DocNo);
        GLCorrespManagement.CreateCorrespEntries(GLEntry);

        // [THEN] The batch job matches the G/L entry for inventory account with the G/L entry for direct cost applied account.
        // [THEN] First correspondence entry: Debit Account No. = "X"; Credit Account No. = "Y".
        // [THEN] Second correspondence entry: Debit Account No. = "Y"; Credit Account No. = "X".
        VerifyGLCorrespondenceAccount(
          DocNo, InventoryPostingSetup."Inventory Account", GeneralPostingSetup."Direct Cost Applied Account");
        VerifyGLCorrespondenceAccount(
          DocNo, GeneralPostingSetup."Direct Cost Applied Account", InventoryPostingSetup."Inventory Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MatchEntriesWithSameGLAccountNoIfOtherwiseImpossible()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
        GLCorrespManagement: Codeunit "G/L Corresp. Management";
        GLAccountNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 375755] G/L Correspondence still matches pair of G/L entries with the same G/L Account No. if no alternate paired G/L entry can be found.
        Initialize();
        Amount := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Disable automatic g/l correspondence.
        SetAutomaticGLCorrespondence(false);

        // [GIVEN] G/L Account "X".
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] Post two gen. journal lines on G/L Account "X" and opposite amounts.
        CreateGenJnlLineWithGLAccount(GenJournalLine, GenJournalBatch, GLAccountNo, Amount);
        CreateGenJnlLineWithGLAccount(GenJournalLine, GenJournalBatch, GLAccountNo, -Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Create G/L Correspondence.
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLCorrespManagement.CreateCorrespEntries(GLEntry);

        // [THEN] The batch job creates a correspondence entry with "Debit Amount" = "Credit Amount" = "X".
        GLCorrespondenceEntry.SetRange("Debit Account No.", GLAccountNo);
        GLCorrespondenceEntry.FindFirst();
        GLCorrespondenceEntry.TestField("Credit Account No.", GLAccountNo);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        SetAutomaticGLCorrespondence(true);

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateAndPostPurchaseInvoice(var GLAccountArray: array[4] of Code[20]; var PurchaseInvoiceHeaderNo: Code[20]; var AmountArray: array[2] of Decimal; TransVATType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        CreateVATPostingSetup(VATPostingSetup, TransVATType);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine.Modify(true);
        AmountArray[1] := PurchaseLine."Line Amount";
        AmountArray[2] := Round(PurchaseLine."Line Amount" / 100 * PurchaseLine."VAT %");

        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        GLAccountArray[1] := PurchaseLine."No.";
        GLAccountArray[2] := VendorPostingGroup."Payables Account";
        GLAccountArray[3] := VATPostingSetup."Purchase VAT Account";
        GLAccountArray[4] := VATPostingSetup."Trans. VAT Account";

        PurchaseInvoiceHeaderNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoice(var GLAccountArray: array[4] of Code[20]; var SalesInvoiceHeaderNo: Code[20]; var AmountArray: array[2] of Decimal; TransVATType: Option)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CreateVATPostingSetup(VATPostingSetup, TransVATType);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000));
        SalesLine.Modify(true);
        AmountArray[1] := SalesLine."Line Amount";
        AmountArray[2] := Round(SalesLine."Line Amount" / 100 * SalesLine."VAT %");

        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        GLAccountArray[1] := SalesLine."No.";
        GLAccountArray[2] := CustomerPostingGroup."Receivables Account";
        GLAccountArray[3] := VATPostingSetup."Sales VAT Account";
        GLAccountArray[4] := VATPostingSetup."Trans. VAT Account";

        SalesInvoiceHeaderNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, VendorNo, ItemNo, Qty, '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; TransVATType: Option)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(20));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup.Validate("Trans. VAT Type", TransVATType);
        if VATPostingSetup."Trans. VAT Type" <> VATPostingSetup."Trans. VAT Type"::" " then
            VATPostingSetup.Validate("Trans. VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJnlLineWithGLAccount(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; GLAccountNo: Code[20]; LineAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccountNo,
          "Gen. Journal Account Type"::"G/L Account", '', LineAmount);
    end;

    local procedure FindPmtVendLedgEntry(DocNo: Code[20]): Integer
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Payment, DocNo);
        exit(VendLedgEntry."Entry No.");
    end;

    local procedure MockMixedPairsOfGLEntriesInSingleTransaction(var TransactionNo: Integer)
    var
        DebitGLAccountNo: Code[20];
        CreditGLAccountNo: Code[20];
        AmountString: Text;
        Amount: Decimal;
        i: Integer;
    begin
        DebitGLAccountNo := LibraryERM.CreateGLAccountNo();
        CreditGLAccountNo := LibraryERM.CreateGLAccountNo();
        TransactionNo := LibraryUtility.GetLastTransactionNo() + 1;

        AmountString := '-38,-19,10,6,-10,-20,20,-6,-4,-25,-30,19,4,30,38,25';
        for i := 1 to 16 do begin
            Evaluate(Amount, SelectStr(i, AmountString));
            if Amount > 0 then
                MockGLEntry(DebitGLAccountNo, Amount, 0, TransactionNo)
            else
                MockGLEntry(CreditGLAccountNo, 0, -Amount, TransactionNo);
        end;
    end;

    local procedure MockGLEntry(GLAccountNo: Code[20]; DebitAmount: Decimal; CreditAmount: Decimal; TransactionNo: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Debit Amount" := DebitAmount;
        GLEntry."Credit Amount" := CreditAmount;
        GLEntry.Amount := DebitAmount - CreditAmount;
        GLEntry."Bal. Account Type" := GLEntry."Bal. Account Type"::"G/L Account";
        GLEntry."Transaction No." := TransactionNo;
        GLEntry.Insert();
    end;

    local procedure PurchaseInvoiceGLCorrespondence(TransVATType: Option)
    var
        PurchaseInvoiceHeaderNo: Code[20];
        GLAccountArray: array[4] of Code[20];
        AmountArray: array[2] of Decimal;
    begin
        Initialize();
        CreateAndPostPurchaseInvoice(GLAccountArray, PurchaseInvoiceHeaderNo, AmountArray, TransVATType);
        VerifyPurchaseInvoiceGLCorrespondence(
          GLAccountArray, PurchaseInvoiceHeaderNo, AmountArray, TransVATType);
    end;

    local procedure PostPrepaymentGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Code[20]
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::Payment, AccountType, AccountNo, LibraryRandom.RandDec(100, 2));
        GenJnlLine.Validate(Prepayment, true);
        GenJnlLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure SalesInvoiceGLCorrespondence(TransVATType: Option)
    var
        SalesInvoiceHeaderNo: Code[20];
        GLAccountArray: array[4] of Code[20];
        AmountArray: array[2] of Decimal;
    begin
        Initialize();
        CreateAndPostSalesInvoice(GLAccountArray, SalesInvoiceHeaderNo, AmountArray, TransVATType);
        VerifySalesInvoiceGLCorrespondence(
          GLAccountArray, SalesInvoiceHeaderNo, AmountArray, TransVATType);
    end;

    local procedure SetGLCorrEntryFiltersAndVerify(var GLCorrEntry: Record "G/L Correspondence Entry"; DebitAccNo: Code[20]; CreditAccNo: Code[20]; EntryAmount: Decimal)
    begin
        GLCorrEntry.SetRange("Debit Account No.", DebitAccNo);
        GLCorrEntry.SetRange("Credit Account No.", CreditAccNo);
        GLCorrEntry.SetRange(Amount, EntryAmount);
        Assert.IsTrue(
          not GLCorrEntry.IsEmpty, StrSubstNo(GLCorrEntryErr, DebitAccNo, CreditAccNo, EntryAmount));
    end;

    local procedure SetAutomaticGLCorrespondence(NewValue: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Automatic G/L Correspondence", NewValue);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure RunReturnPrepaymentReport(EntryNo: Integer; EntryType: Option Sale,Purchase)
    var
        ReturnPrepayment: Report "Return Prepayment";
    begin
        ReturnPrepayment.InitializeRequest(EntryNo, EntryType);
        ReturnPrepayment.UseRequestPage := false;
        ReturnPrepayment.Run();
    end;

    local procedure VerifyPurchaseInvoiceGLCorrespondence(GLAccountArray: array[4] of Code[20]; DocumentNo: Code[20]; AmountArray: array[2] of Decimal; TransVATType: Option " ","Amount + Tax","Amount & Tax")
    var
        GLCorrEntry: Record "G/L Correspondence Entry";
    begin
        GLCorrEntry.SetRange("Document No.", DocumentNo);
        case TransVATType of
            TransVATType::" ":
                begin
                    Assert.AreEqual(2, GLCorrEntry.Count, GLCorrEntryCountErr);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[1], GLAccountArray[2], AmountArray[1]);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[3], GLAccountArray[2], AmountArray[2]);
                end;
            TransVATType::"Amount + Tax",
            TransVATType::"Amount & Tax":
                begin
                    Assert.AreEqual(3, GLCorrEntry.Count, GLCorrEntryCountErr);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[1], GLAccountArray[2], AmountArray[1]);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[3], GLAccountArray[4], AmountArray[2]);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[4], GLAccountArray[2], AmountArray[2]);
                end;
        end;
    end;

    local procedure VerifySalesInvoiceGLCorrespondence(GLAccountArray: array[4] of Code[20]; DocumentNo: Code[20]; AmountArray: array[2] of Decimal; TransVATType: Option " ","Amount + Tax","Amount & Tax")
    var
        GLCorrEntry: Record "G/L Correspondence Entry";
    begin
        GLCorrEntry.SetRange("Document No.", DocumentNo);
        case TransVATType of
            TransVATType::" ":
                begin
                    Assert.AreEqual(2, GLCorrEntry.Count, GLCorrEntryCountErr);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[2], GLAccountArray[1], AmountArray[1]);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[2], GLAccountArray[3], AmountArray[2]);
                end;
            TransVATType::"Amount + Tax":
                begin
                    Assert.AreEqual(2, GLCorrEntry.Count, GLCorrEntryCountErr);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[4], GLAccountArray[3], AmountArray[2]);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[2], GLAccountArray[1], AmountArray[1] + AmountArray[2]);
                end;
            TransVATType::"Amount & Tax":
                begin
                    Assert.AreEqual(3, GLCorrEntry.Count, GLCorrEntryCountErr);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[2], GLAccountArray[1], AmountArray[1]);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[4], GLAccountArray[3], AmountArray[2]);
                    SetGLCorrEntryFiltersAndVerify(GLCorrEntry, GLAccountArray[2], GLAccountArray[4], AmountArray[2]);
                end;
        end;
    end;

    local procedure VerifyGLCorrespondenceAmount(TransactionNo: Integer; Delta: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
    begin
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.CalcSums("Debit Amount");
        GLCorrespondenceEntry.SetRange("Transaction No.", TransactionNo);
        GLCorrespondenceEntry.CalcSums(Amount);
        GLCorrespondenceEntry.TestField(Amount, GLEntry."Debit Amount" - Delta);
    end;

    local procedure VerifyInitialAndReversedGLCorrEntries(InitialGLRegNo: Integer; ReversedGLRegNo: Integer)
    var
        GLRegister: Record "G/L Register";
        InitialGLCorrespondenceEntry: Record "G/L Correspondence Entry";
        ReversedGLCorrespondenceEntry: Record "G/L Correspondence Entry";
    begin
        GLRegister.Get(InitialGLRegNo);
        InitialGLCorrespondenceEntry.SetCurrentKey("Transaction No.", "Debit Account No.", "Credit Account No.");
        InitialGLCorrespondenceEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");

        GLRegister.Get(ReversedGLRegNo);
        ReversedGLCorrespondenceEntry.SetCurrentKey("Transaction No.", "Debit Account No.", "Credit Account No.");
        ReversedGLCorrespondenceEntry.SetRange("Entry No.", GLRegister."From Entry No.", GLRegister."To Entry No.");

        Assert.AreEqual(
          InitialGLCorrespondenceEntry.Count, ReversedGLCorrespondenceEntry.Count,
          'Rversed and Initial G/L Correspondence Entries must have the same number of records.');

        InitialGLCorrespondenceEntry.FindSet();
        ReversedGLCorrespondenceEntry.FindSet();
        repeat
            Assert.AreEqual(InitialGLCorrespondenceEntry."Debit Account No.", ReversedGLCorrespondenceEntry."Debit Account No.", InitialGLCorrespondenceEntry.FieldCaption("Debit Account No."));
            Assert.AreEqual(InitialGLCorrespondenceEntry."Credit Account No.", ReversedGLCorrespondenceEntry."Credit Account No.", InitialGLCorrespondenceEntry.FieldCaption("Credit Account No."));
            Assert.AreEqual(-InitialGLCorrespondenceEntry.Amount, ReversedGLCorrespondenceEntry.Amount, InitialGLCorrespondenceEntry.FieldCaption(Amount));
            ReversedGLCorrespondenceEntry.Next();
        until InitialGLCorrespondenceEntry.Next() = 0;
    end;

    local procedure VerifyGLCorrespondenceAccount(DocumentNo: Code[20]; DebitAccountNo: Code[20]; CreditAccountNo: Code[20])
    var
        GLCorrespondenceEntry: Record "G/L Correspondence Entry";
    begin
        GLCorrespondenceEntry.SetRange("Document No.", DocumentNo);
        GLCorrespondenceEntry.SetRange("Debit Account No.", DebitAccountNo);
        GLCorrespondenceEntry.FindFirst();
        GLCorrespondenceEntry.TestField("Credit Account No.", CreditAccountNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

