codeunit 134283 "Non-Deductible Purch. Posting"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Non-Deductible VAT] [UT]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryNonDeductibleVAT: Codeunit "Library - NonDeductible VAT";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        PrepaymentsWithNDVATErr: Label 'You cannot post prepayment that contains Non-Deductible VAT.';
        AmountMustBeEqualErr: Label 'Amount must be equal.';
        CostAmountActualErr: Label '%1 must be %2 in %3', Comment = '%1 = Cost Amount (Actual), %2 = value of Cost Amount (Actual), %3 = Value Entry';

    [Test]
    procedure NormalVATNonDeductibleAmountsAfterPostingPurchInvEndToEnd()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        ValueEntry: Record "Value Entry";
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        NonDeductibleVATPct: Decimal;
        NonDeductibleVATBase: Decimal;
        NonDeductibleVATAmount: Decimal;
        DocNo: Code[20];
    begin
        // [SCENARIO 456471] Stan can post Normal VAT with Non-Deductible VAT

        Initialize();
        LibraryNonDeductibleVAT.SetUseForItemCost();
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchLineItemWithVATProdPostingGroup(PurchLine, PurchHeader, VATPostingSetup."VAT Prod. Posting Group");
        // [WHEN] Post purchase document
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        // [THEN] A single VAT entry posted
        FindVATEntry(VATEntry, DocNo);
        Assert.RecordCount(VATEntry, 1);
        // [THEN] VAT Entry has following values: Base = 750, Amount = 150; "Non-Deductible Base" = 250, "Non-Deductible Amount" = 50
        NonDeductibleVATPct := LibraryNonDeductibleVAT.GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup);
        NonDeductibleVATBase := Round(PurchLine."VAT Base Amount" * NonDeductibleVATPct / 100);
        NonDeductibleVATAmount := Round((PurchLine."Amount Including VAT" - PurchLine.Amount) * NonDeductibleVATPct / 100);
        LibraryNonDeductibleVAT.VerifyVATAmountsInVATEntry(
            VATEntry, PurchLine.Amount - NonDeductibleVATBase,
            PurchLine."Amount Including VAT" - PurchLine.Amount - NonDeductibleVATAmount,
            NonDeductibleVATBase, NonDeductibleVATAmount);
        // [THEN] Cost Amount in Value Entry is 1250 (Amount = 1000, ND VAT = 250)
        FindValueEntry(ValueEntry, PurchLine."No.", PurchHeader."Buy-from Vendor No.", DocNo);
        ValueEntry.TestField("Cost Amount (Actual)", PurchLine.Amount + NonDeductibleVATAmount);
        // [THEN] G/L Entry for purchase account has "Non-Deductible VAT Amount" = 50
        GeneralPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        FilterGLEntry(GLEntry, DocNo, GeneralPostingSetup."Purch. Account");
        GLEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLEntry.FindFirst();
        GLEntry.TestField("Non-Deductible VAT Amount", NonDeductibleVATAmount);
    end;

    [Test]
    procedure RevChargeNonDeductibleAmountsAfterPostingPurchInvEndToEnd()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        ValueEntry: Record "Value Entry";
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        AmountInclVAT: Decimal;
        NonDeductibleVATPct: Decimal;
        NonDeductibleVATBase: Decimal;
        NonDeductibleVATAmount: Decimal;
        DocNo: Code[20];
    begin
        // [SCENARIO 456471] Stan can post Reverse Charge VAT with Non-Deductible VAT

        Initialize();
        LibraryNonDeductibleVAT.SetUseForItemCost();
        // [GIVEN] Reverse Charge VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleReverseChargeVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchLineItemWithVATProdPostingGroup(PurchLine, PurchHeader, VATPostingSetup."VAT Prod. Posting Group");
        // [WHEN] Post purchase document
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        // [THEN] A single VAT entry posted
        FindVATEntry(VATEntry, DocNo);
        Assert.RecordCount(VATEntry, 1);
        // [THEN] VAT Entry has following values: Base = 750, Amount = 150; "Non-Deductible Base" = 250, "Non-Deductible Amount" = 50
        NonDeductibleVATPct := LibraryNonDeductibleVAT.GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup);
        NonDeductibleVATBase := Round(PurchLine."VAT Base Amount" * NonDeductibleVATPct / 100);
        AmountInclVAT := PurchLine.Amount + Round(PurchLine.Amount * VATPostingSetup."VAT %" / 100);
        NonDeductibleVATAmount := Round((AmountInclVAT - PurchLine.Amount) * NonDeductibleVATPct / 100);
        LibraryNonDeductibleVAT.VerifyVATAmountsInVATEntry(
            VATEntry, PurchLine.Amount - NonDeductibleVATBase,
            AmountInclVAT - PurchLine.Amount - NonDeductibleVATAmount,
            NonDeductibleVATBase, NonDeductibleVATAmount);
        // [THEN] Cost Amount in Value Entry is 1250 (Amount = 1000, ND VAT = 250)
        FindValueEntry(ValueEntry, PurchLine."No.", PurchHeader."Buy-from Vendor No.", DocNo);
        ValueEntry.TestField("Cost Amount (Actual)", PurchLine.Amount + NonDeductibleVATAmount);
        // [THEN] G/L Entry for purchase account has "Non-Deductible VAT Amount" = 50
        GeneralPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        FilterGLEntry(GLEntry, DocNo, GeneralPostingSetup."Purch. Account");
        GLEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLEntry.FindFirst();
        GLEntry.TestField("Non-Deductible VAT Amount", NonDeductibleVATAmount);
    end;

    [Test]
    procedure CombinedVATAmountLineForTwoPurchLineFirstNonDedVATSecondNormalVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        PurchHeader: Record "Purchase Header";
        NonDedPurchLine: Record "Purchase Line";
        NormalPurchLine: Record "Purchase Line";
        TempPurchLine: Record "Purchase Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        Currency: Record Currency;
        PurchPost: Codeunit "Purch.-Post";
        TotalVATAmount: Decimal;
        VATIdentifier: Code[20];
    begin
        // [SCENARIO 456471] Combine VAT amount line from two purchase lines (first has Non-Deductible VAT, second is not) has correct Non-Deductible VAT Base and Non-Deductible VAT Amount

        Initialize();
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        VATIdentifier := VATPostingSetup."VAT Identifier";
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchLineItemWithVATProdPostingGroup(NonDedPurchLine, PurchHeader, VATPostingSetup."VAT Prod. Posting Group");

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 20));
        VATPostingSetup.Validate("VAT Identifier", VATIdentifier);
        VATPostingSetup.Modify(true);

        CreatePurchLineItemWithVATProdPostingGroup(NormalPurchLine, PurchHeader, VATPostingSetup."VAT Prod. Posting Group");
        PurchPost.GetPurchLines(PurchHeader, TempPurchLine, 0);
        NormalPurchLine.CalcVATAmountLines(0, PurchHeader, TempPurchLine, TempVATAmountLine);

        // [WHEN]
        TempVATAmountLine.UpdateLines(
          TotalVATAmount, Currency, LibraryRandom.RandIntInRange(10, 50), false, 0, '', true, WorkDate());

        // [THEN]
        Assert.RecordCount(TempVATAmountLine, 1);
        asserterror TempVATAmountLine.TestField("Non-Deductible VAT Base", NonDedPurchLine."Non-Deductible VAT Base");
        Assert.ExpectedTestFieldError(NonDedPurchLine.FieldCaption("Non-Deductible VAT Base"), Format(0));
        ClearLastError();
        asserterror TempVATAmountLine.TestField("Non-Deductible VAT Amount", NonDedPurchLine."Non-Deductible VAT Amount");
        Assert.ExpectedTestFieldError(NonDedPurchLine.FieldCaption("Non-Deductible VAT Amount"), Format(0));
    end;

    [Test]
    procedure PurchInvoiceWithPrepayment()
    var
        LineGLAccount: Record "G/L Account";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [SCENARIO 456471] Stan cannot create purchase order with prepayment and Non-Deductible VAT

        Initialize();
        // [GIVEN] Purchase order with prepayment
        LibraryNonDeductibleVAT.CreatePurchPrepmtNonDeductibleNormalVATPostingSetup(LineGLAccount);
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorWithBusPostingGroups(LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group"));
        PurchHeader.Validate("Prepayment %", 100);
        PurchHeader.Modify(true);

        // [WHEN] Create purchase line
        asserterror CreatePurchLineItemWithPostingSetupOfGLAcc(PurchLine, PurchHeader, LineGLAccount);

        // [THEN] An error message "You cannot post prepayment that contains Non-Deductible VAT." is thrown
        Assert.ExpectedError(PrepaymentsWithNDVATErr);
    end;

    [Test]
    procedure PostedEntriesManualChangeOfNonDedVATPct()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        ValueEntry: Record "Value Entry";
        NonDeductibleVATPct: Decimal;
        NonDeductibleVATBase: Decimal;
        NonDeductibleVATAmount: Decimal;
        DocNo: Code[20];
    begin
        // [SCENARIO 456471] Posted entries are correct if Stan changes the Non-Deductible VAT % in purchase line manually
        Initialize();
        LibraryNonDeductibleVAT.SetUseForItemCost();
        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase invoice with amount = 100
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchLineItemWithVATProdPostingGroup(PurchLine, PurchHeader, VATPostingSetup."VAT Prod. Posting Group");
        // [GIVEN] Change "Non-Deductible VAT %" to 50 in purchase line
        NonDeductibleVATPct := Round(LibraryNonDeductibleVAT.GetNonDeductibleVATPctFromVATPostingSetup(VATPostingSetup) / 2);
        PurchLine.Validate("Non-Deductible VAT %", NonDeductibleVATPct);
        PurchLine.Modify(true);

        // [WHEN] Post purchase document
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        // [THEN] A single VAT entry posted
        FindVATEntry(VATEntry, DocNo);
        Assert.RecordCount(VATEntry, 1);
        // [THEN] VAT Entry has following values: Base = 500, Amount = 100; "Non-Deductible Base" = 500, "Non-Deductible Amount" = 100
        NonDeductibleVATBase := Round(PurchLine."VAT Base Amount" * NonDeductibleVATPct / 100);
        NonDeductibleVATAmount := Round((PurchLine."Amount Including VAT" - PurchLine.Amount) * NonDeductibleVATPct / 100);
        LibraryNonDeductibleVAT.VerifyVATAmountsInVATEntry(
            VATEntry, PurchLine.Amount - NonDeductibleVATBase,
            PurchLine."Amount Including VAT" - PurchLine.Amount - NonDeductibleVATAmount,
            NonDeductibleVATBase, NonDeductibleVATAmount);
        // [THEN] Cost Amount in Value Entry is 1100 (Amount = 1000, ND VAT = 100)
        FindValueEntry(ValueEntry, PurchLine."No.", PurchHeader."Buy-from Vendor No.", DocNo);
        ValueEntry.TestField("Cost Amount (Actual)", PurchLine.Amount + PurchLine."Non-Deductible VAT Amount");
    end;

    [Test]
    procedure CannotPostPrepaymentIfPrepmtGLAccountHasNonDeductibleVATSetup()
    var
        Item: Record Item;
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 474028] Stan cannot post prepayment if prepayment G/L account has Non-Deductible VAT setup

        Initialize();
        // [GIVEN] Non-Deductible VAT Posting "DOMESTIC" - "VAT25"
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);
        // [GIVEN] Purchase order with "Prepaymnent %" = 100 and "VAT Bus. Posting Group" = "DOMESTIC" and "Gen. Bus Posting Group" = "DOMESTIC"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Validate("Prepayment %", 100);
        PurchaseHeader.Modify(true);
        // [GIVEN] Item with "VAT Prod. Posting Group" = "VAT10" and "Gen Prod. Posting Group" = "RETAIL"
        LibraryInventory.CreateItem(Item);
        // [GIVEN] "Purch. Prepayments Account" in General Posting Setup "DOMESTIC" - "RETAIL" has VAT Setup "DOMESTIC" - "VAT25"
        GeneralPostingSetup.Get(PurchaseHeader."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Purch. Prepayments Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase));
        GeneralPostingSetup.Modify(true);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        // [WHEN] Create purchase line
        asserterror LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        // [THEN] An error message "You cannot post prepayment that contains Non-Deductible VAT." is thrown
        Assert.ExpectedError(PrepaymentsWithNDVATErr);
    end;

    [Test]
    procedure HundredPctPurchInvWithCurrencyAndRounding()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        VendorNo: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 492296] Stan can post the purchase invoice with 100 % Non-Deductible VAT, currency and rounding
        Initialize();

        // [GIVEN] Enable "Use For Item Cost" on VAT Setup
        LibraryNonDeductibleVAT.SetUseForItemCost();

        // [GIVEN] Create Currency and Currency Exchange Rate
        CreateCurrencyWithExchangeRateFor492296(CurrencyExchangeRate, Currency);

        // [GIVEN] Create VAT Posting Setup with Non Dedutible setup
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(VATPostingSetup, 20, 100);

        // [GIVEN] Create Vendor with Currency Code
        VendorNo := CreateVendorWithCurrencyCode(VATPostingSetup, Currency.Code);

        // [GIVEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // [GIVEN] Create Purchase Line with Non Deductible VAT Posting Setup
        CreatePurchLineItemWithVATProdPostingGroup(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Update Direct unit Cost to 123.05 for not getting the Inconsistency error
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Validate("Direct Unit Cost", 123.05);
        PurchaseLine.Modify();

        // [WHEN] Post purchase document and save document no
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify VAT entry posted
        FindVATEntry(VATEntry, DocNo);
        Assert.RecordCount(VATEntry, 1);
        VerifyVATEntryFor492296(VATEntry);

        // [WHEN] Find G/l Entry of Non Deductible G/L Account
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        FilterGLEntry(GLEntry, DocNo, GeneralPostingSetup."Purch. Account");
        GLEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLEntry.FindFirst();

        // [VERIFY] G/L Entries has been created for Non Deductible G/L
        Assert.AreEqual(VATEntry."Non-Deductible VAT Amount", GLEntry."Non-Deductible VAT Amount", AmountMustBeEqualErr);
        Assert.AreEqual(VATEntry."Non-Deductible VAT Amount", GLEntry."VAT Amount", AmountMustBeEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SuggestItemChargeAssignmentPageHandler')]
    procedure CostAmountInValueEntryHavingItemChargeNoIncludesNonDeductibleVATAmount()
    var
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        ItemNo: Code[20];
        CostAmountActual: Decimal;
    begin
        // [SCENARIO 542325] When Stan posts a Purchase Order having Item Charge with Non Deductible VAT Posting Setup then the 
        // Value Entry Created for Item Charge No. will have value including Non Deductible VAT Amount in Cost Amount (Actual).
        Initialize();

        // [GIVEN] Enable "Use For Item Cost" on VAT Setup.
        LibraryNonDeductibleVAT.SetUseForItemCost();

        // [GIVEN] Create VAT Posting Setup with Non Deductible Detail.
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(
            VATPostingSetup, LibraryRandom.RandIntInRange(25, 25), LibraryRandom.RandIntInRange(90, 90));

        // [GIVEN] Create an Item with VAT Prod. Posting Group and save it in a Variable.
        ItemNo := LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create an Item Charge and Validate VAT Prod. Posting Group.
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ItemCharge.Modify(true);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Create a Purchase Line with Type Item.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            ItemNo, LibraryRandom.RandInt(0));

        // [GIVEN]  Validate Direct Unit Cost in Purchase Line.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine.Modify(true);

        // [GIVEN] Create a Purchase Line with Type Charge (Item).
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
            ItemCharge."No.", LibraryRandom.RandInt(0));

        // [GIVEN]  Validate Direct Unit Cost in Purchase Line.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine.Modify(true);

        // [GIVEN] Update Qty. to Assign on Item Charge Assignment.
        UpdateQtyToAssignOnItemChargeAssignment(PurchaseHeader);

        // [GIVEN] Post Purchase Order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Find Value Entry of Item.
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();

        // [GIVEN] Save Cost Amount (Actual) in a Variable.
        CostAmountActual := ValueEntry."Cost Amount (Actual)";

        // [WHEN] Find Value Entry of Item Charge.
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item Charge No.", ItemCharge."No.");
        ValueEntry.FindFirst();

        // [THEN] Cost Amount (Actual) of Item Charge Value Entry and Item Value Entry must be same.
        Assert.AreEqual(
            CostAmountActual,
            ValueEntry."Cost Amount (Actual)",
            StrSubstNo(
                CostAmountActualErr,
                ValueEntry.FieldCaption("Cost Amount (Actual)"),
                CostAmountActual,
                ValueEntry.TableCaption()));
    end;

    [Test]
    procedure ReverseChargeNonDeductibleAmountsAfterPostingPurchaseOrder()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 562638] Non-Deductible VAT rounding when using Reverse Charge VAT.
        Initialize();

        // [GIVEN] Create Currency and Currency Exchange Rate.
        CreateCurrencyWithExchangeRateFor492296(CurrencyExchangeRate, Currency);

        // [GIVEN] Setup Use For Item Cost.
        LibraryNonDeductibleVAT.SetUseForItemCost();

        // [GIVEN] Create Non Deductible Reverse Charge in VAT Posting Setup.
        LibraryNonDeductibleVAT.CreateNonDeductibleReverseChargeVATPostingSetup(VATPostingSetup);

        // [GIVEN] Create Purchase Header and Validate Currency Code.
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create Purchase Line with Vat Product Posting Group
        CreatePurchLineItemWithVATProdPostingGroup(PurchaseLine, PurchaseHeader, VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Post purchase document
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Find VAT Entry.
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Bill-to/Pay-to No.", PurchaseHeader."Buy-from Vendor No.");
        VATEntry.FindFirst();

        // [GIVEN] Find General Posting Setup.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [THEN] Non deductible VAT Amount must be correct.
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLEntry.FindFirst();
        Assert.AreEqual(GLEntry."Non-Deductible VAT Amount", VATEntry."Non-Deductible VAT Amount", AmountMustBeEqualErr);
    end;

    [Test]
    [HandlerFunctions('JobConfirmHandler')]
    procedure VerifyUnitCostOnProjectLedgerEntryForNonDeductibleAmountsAfterPosting()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobLedgerEntry: Record "Job Ledger Entry";
        DocNo: Code[20];
    begin
        // [SCENARIO 573600] Incorrect "Unit Cost" in Project Ledger Entries when partially invoicing after receiving the full quantity with Non-deductible VAT setting

        Initialize();
        LibraryNonDeductibleVAT.SetUseForItemCost();
        LibraryNonDeductibleVAT.SetUseForJobCost();

        // [GIVEN] Normal VAT Posting Setup with "VAT %" = 20 and Non-Deductible VAT %" = 75
        LibraryNonDeductibleVAT.CreateNonDeductibleNormalVATPostingSetup(VATPostingSetup);

        // [GIVEN] Create a new Project and Project Task
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Purchase invoice with amount = 100
        LibraryPurchase.CreatePurchHeader(
            PurchHeader, PurchHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchLineItemWithVATProdPostingGroup(PurchLine, PurchHeader, VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Update Project and Project Task No. on Purchase Line
        PurchLine.Validate("Job No.", Job."No.");
        PurchLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchLine.Modify(true);

        // [GIVEN] Post purchase document with Receipt
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);

        // [GIVEN] Update Qty. to Invoice with 1
        PurchLine.Get(PurchHeader."Document Type", PurchHeader."No.", PurchLine."Line No.");
        PurchLine.Validate("Qty. to Invoice", 1);
        PurchLine.Modify(true);

        // [WHEN] Post purchase document with Invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true);

        // [THEN] Verify Unit Cost Amount on Project Ledger Entry
        FindVATEntry(VATEntry, DocNo);
        FindJobLedgerEntry(JobLedgerEntry, DocNo);
        Assert.AreEqual(JobLedgerEntry."Unit Cost", PurchLine."Direct Unit Cost" + VATEntry."Non-Deductible VAT Amount", JobLedgerEntry.FieldCaption("Unit Cost"));
    end;

    [Test]
    [HandlerFunctions('SuggestItemChargeAssignmentPageHandler')]
    procedure ValueEntryItemChargeIncludesNonDeductibleVATAmountInCostAmount()
    var
        ItemCharge: Record "Item Charge";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: array[2] of Record "Value Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO 573517] Cost Amount Actual posted in Value Entries for Item Charge includes Non-deductible VAT.
        Initialize();

        // [GIVEN] Enable "Use For Item Cost" on VAT Setup.
        LibraryNonDeductibleVAT.SetUseForItemCost();

        // [GIVEN] Create VAT Posting Setup with Non Deductible Detail.
        LibraryNonDeductibleVAT.CreateVATPostingSetupWithNonDeductibleDetail(
            VATPostingSetup,
            LibraryRandom.RandIntInRange(25, 25),
            LibraryRandom.RandIntInRange(90, 90));

        // [GIVEN] Create an Item with VAT Prod. Posting Group and save it in a Variable.
        ItemNo := LibraryInventory.CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create an Item Charge and Validate VAT Prod. Posting Group.
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ItemCharge.Modify(true);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader,
            PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Validate Prices Including VAT to true in Purchase Header.
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);

        // [GIVEN] Create a Purchase Line for Item.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            ItemNo, LibraryRandom.RandInt(0));

        // [GIVEN]  Validate Direct Unit Cost in Purchase Line.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine.Modify(true);

        // [GIVEN] Create a Purchase Line for Charge Item.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::"Charge (Item)",
            ItemCharge."No.",
            LibraryRandom.RandInt(0));

        // [GIVEN]  Validate Direct Unit Cost in Purchase Line.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        PurchaseLine.Modify(true);

        // [GIVEN] Assign Item Charge to Item.
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();
        PurchaseLine.ShowItemChargeAssgnt();

        // [GIVEN] Post Purchase Document.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Find Value Entry for Type Item.
        ValueEntry[1].SetRange("Document No.", DocumentNo);
        ValueEntry[1].SetRange("Item No.", ItemNo);
        ValueEntry[1].FindFirst();

        // [WHEN] Find Value Entry of Item Charge.
        ValueEntry[2].SetRange("Document No.", DocumentNo);
        ValueEntry[2].SetRange("Item Charge No.", ItemCharge."No.");
        ValueEntry[2].FindFirst();

        // [THEN] Cost Amount (Actual) in Value Entries must be same.
        Assert.AreEqual(
            ValueEntry[1]."Cost Amount (Actual)",
            ValueEntry[2]."Cost Amount (Actual)",
            StrSubstNo(
                CostAmountActualErr,
                ValueEntry[1].FieldCaption("Cost Amount (Actual)"),
                ValueEntry[1]."Cost Amount (Actual)",
                ValueEntry[1].TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Non-Deductible Purch. Posting");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Non-Deductible Purch. Posting");
        LibraryNonDeductibleVAT.EnableNonDeductibleVAT();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Non-Deductible Purch. Posting");
    end;

    local procedure CreatePurchLineItemWithVATProdPostingGroup(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; VATProdPostGroupCode: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::Item, LibraryInventory.CreateItemWithVATProdPostingGroup(VATProdPostGroupCode), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchLineItemWithPostingSetupOfGLAcc(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; LineGLAccount: Record "G/L Account")
    begin
        LibraryPurchase.CreatePurchaseLine(
            PurchLine, PurchHeader, PurchLine.Type::Item, CreateItemWithPostingSetup(LineGLAccount), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);
    end;

    local procedure CreateItemWithPostingSetup(LineGLAccount: Record "G/L Account"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", LineGLAccount."Gen. Prod. Posting Group");
        Item.Validate("VAT Prod. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.FindFirst();
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemNo: Code[20]; SourceNo: Code[20]; DocumentNo: Code[20])
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Source No.", SourceNo);
        ValueEntry.FindFirst();
    end;

    local procedure FilterGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
    end;

    local procedure CreateVendorWithCurrencyCode(VATPostingSetup: Record "VAT Posting Setup"; CurrencyCode: Code[10]): Code[20];
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    local procedure CreateCurrencyWithExchangeRateFor492296(var CurrencyExchangeRate: Record "Currency Exchange Rate"; var Currency: Record Currency)
    var
        CurrCode: Code[10];
    begin
        CurrCode := LibraryERM.CreateCurrencyWithGLAccountSetup();
        Currency.Get(CurrCode);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, 0D);
        UpdateExchangeRatesFor492296(CurrencyExchangeRate);
    end;

    local procedure UpdateExchangeRatesFor492296(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 82.05);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 82.05);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure VerifyVATEntryFor492296(VATEntry: Record "VAT Entry")
    begin
        Assert.AreEqual(0, VATEntry.Base, AmountMustBeEqualErr);
        Assert.AreEqual(0, VATEntry.Amount, AmountMustBeEqualErr);
        Assert.AreEqual(100.96, VATEntry."Non-Deductible VAT Base", AmountMustBeEqualErr);
        Assert.AreEqual(20.20, VATEntry."Non-Deductible VAT Amount", AmountMustBeEqualErr);
    end;

    local procedure UpdateQtyToAssignOnItemChargeAssignment(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"Charge (Item)");
        PurchaseLine.FindFirst();
        PurchaseLine.ShowItemChargeAssgnt();
    end;

    local procedure FindJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; DocumentNo: Code[20])
    begin
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.SetRange("Posting Date", WorkDate());
        JobLedgerEntry.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SuggestItemChargeAssignmentPageHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
    end;

    [ConfirmHandler]
    procedure JobConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
