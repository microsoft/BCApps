codeunit 144032 "ERM Purchase Doc. Amounts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Document Totals] [Document Amount]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryRandom: Codeunit "Library - Random";
        ValueMustNotEqualMsg: Label 'Value must not be equal';
        ValueMustEqualMsg: Label 'Value must be equal';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryCosting: Codeunit "Library - Costing";
        IsInitialized: Boolean;
        RecipientBankErr: Label 'Recipant Bank Account must be %1 in %2.', Comment = '%1 = Recipant Bank %2=Table Name';

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceDocAmountInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeaderNo: Code[20];
    begin
        // [GIVEN] Create Purchase Invoice with Document Amount Including VAT.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Update Doc. Amount Incl. VAT and post Purchase Invoice for Ship and Invoice.
        PurchInvHeaderNo :=
          UpdateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseLine, PurchaseLine."Line Amount" + PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);

        // [THEN] Verify Purchase Invoice posted successfully.
        VerifyPurchaseInvoiceLine(PurchInvHeaderNo, PurchaseHeader."Doc. Amount Incl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoDocAmountInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdrNo: Code[20];
    begin
        // [GIVEN] Create Purchase Credit Memo with Document Amount Including VAT.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Update Doc. Amount Incl. VAT and post Purchase Credit Memo for Ship and Invoice.
        PurchCrMemoHdrNo :=
          UpdateAndPostPurchaseDocument(
            PurchaseHeader, PurchaseLine, PurchaseLine."Line Amount" + PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);

        // [THEN] Verify Purchase Credit Memo posted successfully.
        VerifyPurchaseCreditMemoLine(PurchCrMemoHdrNo, PurchaseHeader."Doc. Amount Incl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceCheckDocTotalAmountsFalse()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeaderNo: Code[20];
    begin
        // [GIVEN] Update Check Doc. Total Amounts - FALSE on Purchases & Payables Setup, Create Purchase Invoice with wrong Document Amount Including VAT.
        Initialize();
        SetCheckDocTotalAmounts(false);
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] Update Doc. Amount Incl. VAT and post Purchase Invoice for Ship and Invoice.
        PurchInvHeaderNo := UpdateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LibraryRandom.RandDec(10, 2));  // Taking Random value for Doc. Amount Incl. VAT other than calculated value from Purchase Line.

        // [THEN] Verify Purchase Invoice posted successfully with wrong Document Amount Including VAT.
        VerifyPurchaseInvoiceLine(PurchInvHeaderNo, PurchaseLine."Line Amount" + PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoCheckDocTotalAmountsFalse()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHeaderNo: Code[20];
    begin
        // [GIVEN] Update Check Doc. Total Amounts - FALSE on Purchases & Payables Setup, Create Purchase Credit Memo with wrong Document Amount Including VAT.
        Initialize();
        SetCheckDocTotalAmounts(false);
        CreatePurchaseDocument(PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo");

        // [WHEN] Update Doc. Amount Incl. VAT and post Purchase Credit Memo for Ship and Invoice.
        PurchCrMemoHeaderNo := UpdateAndPostPurchaseDocument(PurchaseHeader, PurchaseLine, LibraryRandom.RandDec(10, 2));  // Taking Random value for Doc. Amount Incl. VAT other than calculated value from Purchase Line.

        // [THEN] Verify Purchase Credit Memo posted successfully with wrong Document Amount Including VAT.
        VerifyPurchaseCreditMemoLine(
          PurchCrMemoHeaderNo, PurchaseLine."Line Amount" + PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithDiffItemsMultipleLinesDocAmountInclVAT()
    begin
        // [SCENARIO] Purchase Invoice with multiple lines for different Items having different VAT %.
        Initialize();
        PurchDocWithDiffItemsMultipleLinesDocAmountInclVAT("Purchase Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoDiffItemsWithMultipleLinesDocAmtInclVAT()
    begin
        // [SCENARIO] Purchase Credit Memo with multiple lines for different Items having different VAT %.
        Initialize();
        PurchDocWithDiffItemsMultipleLinesDocAmountInclVAT("Purchase Document Type"::"Credit Memo");
    end;

    local procedure PurchDocWithDiffItemsMultipleLinesDocAmountInclVAT(DocumentType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocAmountIncVAT: Decimal;
        ExpectedDocAmountVAT: Decimal;
    begin
        // [GIVEN] Create Purchase Document with multiple lines for different Items having different VAT %.
        CreatePurchaseDocument(PurchaseLine, DocumentType);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreateItemWithDiffVATProdPostingGroup(Item, PurchaseLine."VAT Prod. Posting Group");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, Item."No.", Item."Unit Cost");
        DocAmountIncVAT :=
          PurchaseLine."Line Amount" +
          PurchaseLine."Line Amount" *
          PurchaseLine."VAT %" / 100 + PurchaseLine2."Line Amount" + PurchaseLine2."Line Amount" * PurchaseLine2."VAT %" / 100;
        ExpectedDocAmountVAT :=
          PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100 + PurchaseLine2."Line Amount" * PurchaseLine."VAT %" / 100;

        // [WHEN] Update Doc. Amount Incl. VAT on Purchase Header.
        UpdatePurchaseHeader(PurchaseHeader, DocAmountIncVAT);

        // [THEN] Verify Document Amount VAT on Purchase Header is updated with VAT % of first line for both the lines.
        Assert.AreNotEqual(ExpectedDocAmountVAT, PurchaseHeader."Doc. Amount VAT", ValueMustNotEqualMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithMultipleLinesDocAmountInclVAT()
    begin
        // [SCENARIO] Purchase Invoice with multiple lines for same Item.
        Initialize();
        PurchDocWithMultipleLinesDocAmountInclVAT("Purchase Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoWithMultipleLinesDocAmountInclVAT()
    begin
        // [SCENARIO] Purchase Credit Memo with multiple lines for same Item.
        Initialize();
        PurchDocWithMultipleLinesDocAmountInclVAT("Purchase Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocAmountInclVATWhenSingleLineWithoutAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocAmountInclVAT: Decimal;
    begin
        // [SCENARIO 280476] No error when validate Doc Amount Incl. VAT in Purchase Header when only zero amount lines present in purch. document
        // [SCENARIO] Doc. Amount VAT is <zero> in this case
        Initialize();
        DocAmountInclVAT := LibraryRandom.RandDecInRange(1000, 2000, 2);

        // [GIVEN] Purchase Invoice with Line having Qty = 1 and Unit Cost is <zero>
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Unit Cost", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Validate Doc. Amount Incl. VAT = 1000 in Purchase Header
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", DocAmountInclVAT);

        // [THEN] Doc. Amount Incl. VAT = 1000 in Purchase Header
        PurchaseHeader.TestField("Doc. Amount Incl. VAT", DocAmountInclVAT);

        // [THEN] Doc. Amount VAT is <zero> in Purchase Header
        PurchaseHeader.TestField("Doc. Amount VAT", 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceWithServiceItemFromListPageWithCheckDocTotalAmounts()
    var
        Item: Record Item;
    begin
        // [SCENARIO 369152] Correct Purchase Invoice with Service item from list page when "Check Doc. Total Amounts" is unabled
        CorrectInvoiceFromListPage(Item.Type::Service);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceWithInventoryItemFromListPageWithCheckDocTotalAmounts()
    var
        Item: Record Item;
    begin
        // [SCENARIO 369152] Correct Purchase Invoice with Inventory item from list page when "Check Doc. Total Amounts" is unabled
        CorrectInvoiceFromListPage(Item.Type::Inventory);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceWithServiceItemFromCardPageWithCheckDocTotalAmounts()
    var
        Item: Record Item;
    begin
        // [SCENARIO 369152] Correct Purchase Invoice with Service item from card page when "Check Doc. Total Amounts" is unabled
        CorrectInvoiceFromCardPage(Item.Type::Service);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TestCorrectInvoiceWithInventoryItemFromCardPageWithCheckDocTotalAmounts()
    var
        Item: Record Item;
    begin
        // [SCENARIO 369152] Correct Purchase Invoice with Inventory item from card page when "Check Doc. Total Amounts" is unabled
        CorrectInvoiceFromCardPage(Item.Type::Inventory);
    end;

    [Test]
    procedure RecipientBankAccountRetrivedFromVendorNotFromVendorLedgerEntryWhileApplied()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        VendorBankAccount: array[2] of Record "Vendor Bank Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AppliestoDoc: Code[20];
    begin
        // [SCINARIO 523612] The Recipient Bank Account is always retrieved from the Vendor Card and not from the one specified in the posted Purchase Invoice if you try to apply invoices in the Payment Journal.
        Initialize();

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create two Vendor Bank Accounts for the Vendor.
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount[1], Vendor."No.");
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount[2], Vendor."No.");

        // [GIVEN] Validate Preferred Bank Account with one Vendor Bank Account Code.
        Vendor.Validate("Preferred Bank Account Code", VendorBankAccount[1].Code);
        Vendor.Modify(true);

        // [GIVEN] Create a Purchase Header of Document Type Order for the Vendor.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Create Vat Posting Setup for the Venodr.
        CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", LibraryRandom.RandInt(9));

        // [GIVEN] Update Vendor Bank Account Code with different Vendor Bank Account than Preferred Bank Account Code.
        PurchaseHeader.Validate(PurchaseHeader."Bank Account Code", VendorBankAccount[2].Code);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create Purchase Line of Type Item.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(3));

        // [GIVEN] Validate Direct Unit Cost, Vat Product Posting Group.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);

        // [GIVEN] Post Purchase Order and get the Posted Purchase Document No.
        AppliestoDoc := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Journal Line and Validate Applies-to Doc No. with the Posted Purchase Document No.
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor,
            '',
             0);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDoc);
        GenJournalLine.Modify(true);

        // [THEN] Verify if the Recipient Bank Account in Payment Journal matches with Venodr Ledger Entry.
        VendorLedgerEntry.SetRange("Document No.", AppliestoDoc);
        VendorLedgerEntry.FindFirst();
        Assert.AreEqual(
            GenJournalLine."Recipient Bank Account",
            VendorLedgerEntry."Recipient Bank Account",
            StrSubstNo(
                RecipientBankErr,
                VendorLedgerEntry."Recipient Bank Account",
                GenJournalLine.TableCaption()));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Doc. Amounts");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Doc. Amounts");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Doc. Amounts");
    end;

    local procedure PurchDocWithMultipleLinesDocAmountInclVAT(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocAmountInclVAT: Decimal;
        ExpectedDocAmountVAT: Decimal;
    begin
        // [GIVEN] Create Purchase Document with multiple lines for same Item.
        CreatePurchaseDocument(PurchaseLine, DocumentType);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine."No.", PurchaseLine."Direct Unit Cost");
        DocAmountInclVAT :=
          PurchaseLine."Line Amount" +
          PurchaseLine."Line Amount" *
          PurchaseLine."VAT %" / 100 + PurchaseLine2."Line Amount" + PurchaseLine2."Line Amount" * PurchaseLine2."VAT %" / 100;
        ExpectedDocAmountVAT :=
          Round(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100 + PurchaseLine2."Line Amount" * PurchaseLine2."VAT %" / 100);

        // [WHEN] Update Doc. Amount Incl. VAT on Purchase Header.
        UpdatePurchaseHeader(PurchaseHeader, DocAmountInclVAT);

        // [THEN] Verify Document Amount VAT on Purchase Header is updated correctly.
        Assert.AreEqual(ExpectedDocAmountVAT, PurchaseHeader."Doc. Amount VAT", ValueMustEqualMsg);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(10));
        Item.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
    begin
        CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", Item."Unit Cost");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));  // Using Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateItemWithDiffVATProdPostingGroup(var Item: Record Item; VATProdPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATProductPostingGroup.SetFilter(Code, '<>%1', VATProdPostingGroupCode);  // VAT Product Posting Group should be different for second Items
        VATProductPostingGroup.FindFirst();
        CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        Item.Modify(true);
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocAmountInclVAT: Decimal)
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Doc. Amount Incl. VAT", DocAmountInclVAT);
        PurchaseHeader.Modify(true);
    end;

    local procedure SetCheckDocTotalAmounts(CheckTotals: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Check Doc. Total Amounts", CheckTotals);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; DocAmountInclVAT: Decimal) DocumentNo: Code[20]
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        UpdatePurchaseHeader(PurchaseHeader, DocAmountInclVAT);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure VerifyPurchaseInvoiceLine(DocumentNo: Code[20]; AmountIncludingVAT: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("Amount Including VAT", AmountIncludingVAT);
    end;

    local procedure VerifyPurchaseCreditMemoLine(DocumentNo: Code[20]; AmountIncludingVAT: Decimal)
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.TestField("Amount Including VAT", AmountIncludingVAT);
    end;

    local procedure CorrectInvoiceFromListPage(Type: Enum "Item Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        // [GIVEN] Unabled "Check Doc. Total Amounts" in Purchase & Payables Setup
        UnableCheckDocTotalAmounts();

        if GLEntry.FindLast() then;

        // [GIVEN] Created and posted Purchase Invoice
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        // [GIVEN] Opened page "Posted Purchase Invoices"
        PostedPurchaseInvoices.OpenView();
        PostedPurchaseInvoices.Filter.SetFilter("No.", PurchInvHeader."No.");
        PostedPurchaseInvoices.First();
        LibraryVariableStorage.Enqueue(true); // for the confirm handler
        PurchaseInvoice.Trap();

        // [WHEN] Correct Purchase Invoice
        PostedPurchaseInvoices.CorrectInvoice.Invoke();
        PurchaseInvoice.Close();

        // [THEN] Purchase Invoice corrected successfully
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
        DisableCheckDocTotalAmounts();
    end;

    local procedure CorrectInvoiceFromCardPage(Type: Enum "Item Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        Initialize();

        // [GIVEN] Unabled "Check Doc. Total Amounts" in Purchase & Payables Setup
        UnableCheckDocTotalAmounts();

        if GLEntry.FindLast() then;

        // [GIVEN] Created and posted Purchase Invoice
        CreateAndPostPurchaseInvForNewItemAndVendor(Item, Type, Vendor, 1, 1, PurchInvHeader);
        CheckSomethingIsPosted(Item, Vendor);

        // [GIVEN] Opened page "Posted Purchase Invoice"
        PostedPurchaseInvoice.OpenView();
        PostedPurchaseInvoice.Filter.SetFilter("No.", PurchInvHeader."No.");
        PostedPurchaseInvoice.First();
        LibraryVariableStorage.Enqueue(true); // for the confirm handler
        PurchaseInvoice.Trap();

        // [WHEN] Correct Purchase Invoice
        PostedPurchaseInvoice.CorrectInvoice.Invoke();
        PurchaseInvoice.Close();

        // [THEN] Purchase Invoice corrected successfully
        CheckEverythingIsReverted(Item, Vendor, GLEntry);
        DisableCheckDocTotalAmounts();
    end;

    local procedure CreateAndPostPurchaseInvForNewItemAndVendor(var Item: Record Item; Type: Enum "Item Type"; var Vendor: Record Vendor; UnitCost: Decimal; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header")
    begin
        CreateItemWithCost(Item, Type, UnitCost);
        LibrarySmallBusiness.CreateVendor(Vendor);
        BuyItem(Vendor, Item, Qty, PurchInvHeader);
    end;

    local procedure CheckSomethingIsPosted(Item: Record Item; Vendor: Record Vendor)
    begin
        // Inventory should be positive
        Item.CalcFields(Inventory);
        Assert.IsTrue(Item.Inventory > 0, '');

        // Vendor balance should be positive
        Vendor.CalcFields(Balance);
        Assert.IsTrue(Vendor.Balance > 0, '');
    end;

    local procedure CheckEverythingIsReverted(Item: Record Item; Vendor: Record Vendor; LastGLEntry: Record "G/L Entry")
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
        ValueEntry: Record "Value Entry";
        TotalDebit: Decimal;
        TotalCredit: Decimal;
        TotalCost: Decimal;
        TotalQty: Decimal;
    begin
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');
        ValueEntry.SetRange("Source Type", ValueEntry."Source Type"::Vendor);
        ValueEntry.SetRange("Source No.", Vendor."No.");
        ValueEntry.FindSet();
        repeat
            TotalQty += ValueEntry."Item Ledger Entry Quantity";
            TotalCost += ValueEntry."Cost Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreEqual(0, TotalQty, '');
        Assert.AreEqual(0, TotalCost, '');

        // Vendor balance should go back to zero
        Vendor.CalcFields(Balance);
        Assert.AreEqual(0, Vendor.Balance, '');

        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GLEntry.SetFilter("Entry No.", '>%1', LastGLEntry."Entry No.");
        GLEntry.FindSet();
        repeat
            TotalDebit += GLEntry."Credit Amount";
            TotalCredit += GLEntry."Debit Amount";
        until GLEntry.Next() = 0;

        Assert.AreEqual(TotalDebit, TotalCredit, '');
    end;

    local procedure CreateItemWithCost(var Item: Record Item; Type: Enum "Item Type"; UnitCost: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item.Validate(Type, Type);
        Item."Last Direct Cost" := UnitCost;
        Item.Modify();
    end;

    local procedure BuyItem(BuyFromVendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseInvoiceForItem(BuyFromVendor, Item, Qty, PurchaseHeader, PurchaseLine);
        PurchInvHeader.Get(LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeader));
    end;

    local procedure CreatePurchaseInvoiceForItem(Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, Qty);
    end;

    local procedure UnableCheckDocTotalAmounts()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Check Doc. Total Amounts", true);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure DisableCheckDocTotalAmounts()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Check Doc. Total Amounts", false);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostingGroupCode: Code[20]; VATPercent: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        VarReply: Variant;
    begin
        LibraryVariableStorage.Dequeue(VarReply);
        Reply := VarReply;
    end;
}

