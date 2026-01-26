codeunit 141444 "ERM Purch. Prepmt. Include Tax"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Prepayment]
    end;

    var
        LibraryPurch: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        IncorrectAmountErr: Label 'Incorrect Amount for Document %1 Account %2';
        IncorrectInvRoundingErr: Label 'Incorrect invoice rounding precision';
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";

    [Test]
    [Scope('OnPrem')]
    procedure DisableInclTaxAfterPrepmtInv()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchHeader."Prepmt. Include Tax" := true;
        PreparePOwithPostedPrepmtInv(PurchHeader, PurchLine, 1);

        asserterror PurchHeader.Validate("Prepmt. Include Tax", false);
        Assert.ExpectedError(StrSubstNo('You cannot change %1', PurchHeader.FieldCaption("Prepmt. Include Tax")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SecondPrepmtInvPostingInclTax()
    begin
        SecondPrepmtInvPosting(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SecondPrepmtInvPostingExclTax()
    begin
        SecondPrepmtInvPosting(false);
    end;

    local procedure SecondPrepmtInvPosting(IncludeTax: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        FirstPrepmtInvNo: Code[20];
    begin
        PurchHeader."Prepmt. Include Tax" := IncludeTax;
        PreparePOwithPostedPrepmtInv(PurchHeader, PurchLine, 1);
        FirstPrepmtInvNo := PurchHeader."Last Prepayment No.";
        DoubleQuantityInLines(PurchHeader);

        PostPurchPrepmtInvoice(PurchHeader);

        Assert.AreNotEqual(FirstPrepmtInvNo, PurchHeader."Last Prepayment No.", 'New Prepmt Invoice No. exepected');
        VerifyPrepmtAmountsInLines(PurchHeader);
    end;

    local procedure ReopenPurchOrder(var PurchHeader: Record "Purchase Header")
    var
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        ReleasePurchDoc.PerformManualReopen(PurchHeader);
    end;

    local procedure DoubleQuantityInLines(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        ReopenPurchOrder(PurchHeader);
        FindPurchLine(PurchLine, PurchHeader."Document Type", PurchHeader."No.");
        repeat
            PurchLine.Validate(Quantity, 2 * PurchLine.Quantity);
            PurchLine.Validate("Line Discount %", 0);
            PurchLine.Modify();
        until PurchLine.Next() = 0;
    end;

    local procedure VerifyPrepmtAmountsInLines(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        FindPurchLine(PurchLine, PurchHeader."Document Type", PurchHeader."No.");
        repeat
            PurchLine.TestField("Line Amount", PurchLine."Prepmt. Line Amount");
            PurchLine.TestField("Prepmt. Line Amount", PurchLine."Prepmt. Amt. Inv.");
        until PurchLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiLineInvPartRoundErr()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchHeader."Prepmt. Include Tax" := true;
        PreparePOwithPostedPrepmtInv(PurchHeader, PurchLine, 3);
        PurchLine.Find();
        PurchLine.Validate("Qty. to Receive", 1);
        PurchLine.Modify();

        PostPurchOrder(PurchHeader);

        VerifyZeroVendorAccEntry();
        VerifyInvRoundingEqualToRoundingPrecision(PurchHeader."Pay-to Vendor No.", PurchHeader."Vendor Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiLineOrderPartLCYTFS323743()
    var
        DummyPurchHeader: Record "Purchase Header";
    begin
        MultiLineOrderPartTFS323743(DummyPurchHeader);
        VerifyZeroVendorAccEntry();
    end;

    local procedure MultiLineOrderPartTFS323743(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchHeader."Prepmt. Include Tax" := true;
        PreparePOwithPostedPrepmtInv(PurchHeader, PurchLine, 3);
        PurchLine.Find();
        PurchLine.Validate("Qty. to Receive", PurchLine."Qty. to Receive" - 1);
        PurchLine.Modify();
        PostPurchOrder(PurchHeader);
        VerifyZeroVendorAccEntry();

        PostPurchOrder(PurchHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiLineOrderLCYTFS323742()
    var
        DummyPurchHeader: Record "Purchase Header";
    begin
        MultiLineOrderTFS323742(DummyPurchHeader);
        VerifyZeroVendorAccEntry();
    end;

    local procedure MultiLineOrderTFS323742(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchHeader."Prepmt. Include Tax" := true;
        PreparePOwithPostedPrepmtInv(PurchHeader, PurchLine, 3);
        PostPurchOrder(PurchHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialRcptInvOfOrderWith100PctPrepmt()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Prepmt. Include Tax] [100% Prepayment]
        // [SCENARIO 371956] Zero Vendor Ledg Entry should be posted for partial "receive and invoice" of Order with 100% prepayment

        // [GIVEN] Purchase Order in LCY, where "Prepmt. Include Tax" = Yes
        PurchHeader."Prepmt. Include Tax" := true;
        // [GIVEN] Order contains 3 lines, where "Prepayment %" = 100
        // [GIVEN] Posted Prepayment Invoice
        PreparePOwithPostedPrepmtInv(PurchHeader, PurchLine, 3);
        // [GIVEN] Set "Quantity to Receive" = 0 for lines except the third one
        PurchLine.SetFilter("Line No.", '<%1', PurchLine."Line No.");
        FindPurchLine(PurchLine, PurchLine."Document Type", PurchLine."Document No.");
        repeat
            PurchLine.Validate("Qty. to Receive", 0);
            PurchLine.Modify(true);
        until PurchLine.Next() = 0;

        // [WHEN] Receive and Invoice the third line
        PostPurchOrder(PurchHeader);

        // [THEN] Vendor Ledger Entry is posted where Amount = 0
        VerifyZeroVendorAccEntry();
        // [THEN] Invoice Rounding G/L Entry is posted, where Amount = 0.01
        VerifyInvRoundingEqualToRoundingPrecision(PurchHeader."Pay-to Vendor No.", PurchHeader."Vendor Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Scenario55698LCYExclTax()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Init();
        PurchHeader."Prepmt. Include Tax" := false;
        Scenario55698(PurchHeader);
        asserterror VerifyZeroVendorAccEntry();
        Assert.ExpectedError('Expected zero Vendor Ledger Entry');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Scenario55698LCYInclTax()
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Init();
        PurchHeader."Prepmt. Include Tax" := true;
        Scenario55698(PurchHeader);
        VerifyZeroVendorAccEntry();
    end;

    local procedure Scenario55698(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PreparePOwithPostedPrepmtInv(PurchHeader, PurchLine, 1);
        PostPurchOrder(PurchHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentWithTaxAreaTFS358485()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GenPostSetup: Record "General Posting Setup";
        PurchAmount: Decimal;
        PrepmtAmount: Decimal;
        ExchRate: Decimal;
    begin
        // Create purch.order with magic number that lead to inconsistent error
        ExchRate := 100 / 106.37;
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        CreatePurchDoc(PurchHeader, FindTaxAreaCode(), CreateCurrency(ExchRate), false);
        PreparePurchLineForGLAcc(PurchLine, PurchHeader);
        AddPurchOrderLine(PurchLine, 1, 400500, 30);
        AddPurchOrderLine(PurchLine, 1, 3000, 30);

        // Calculated expected values, post perpayment and order
        PurchHeader.CalcFields("Amount Including VAT");
        PurchAmount := Round(PurchHeader."Amount Including VAT" / ExchRate);
        PostPurchPrepmtInvoice(PurchHeader);
        PrepmtAmount := GetPrepmtAmount(PurchHeader."Last Prepayment No.");
        PostPurchOrder(PurchHeader);

        // Verify Amounts in G/L Entry
        VerifyGLEntryAmount(PurchHeader."Last Posting No.", PurchLine."No.", PurchAmount);
        GenPostSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        VerifyGLEntryAmount(PurchHeader."Last Posting No.", GenPostSetup."Purch. Prepayments Account", PrepmtAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostingForPrepmtIncludeTax()
    var
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorPostingGroup: Record "Vendor Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        TaxPct: Integer;
        PrepmtPct: Integer;
        Quantity: Integer;
        PrepmtAmount: Decimal;
        Invoice1: Code[20];
        Invoice2: Code[20];
    begin
        // [SCENARIO 359777] Post purchase order partially when Prepmt. Include Tax = true.

        // [GIVEN] Tax Details for tax jurisdiction with 5 %.
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxGroup(TaxGroup);
        TaxPct := LibraryRandom.RandIntInRange(5, 10);
        CreateTaxAreaSetupWithValues(TaxDetail, TaxArea.Code, TaxGroup.Code, TaxPct);

        // [GIVEN] Posted Purchase Order with "Prepmt. Include Tax" = TRUE and "Prepayment %" = 50.
        // [GIVEN] Purchase Line with Quantity = 2, Amount = 1000, Tax Amount = 50
        PrepmtPct := LibraryRandom.RandIntInRange(1, 5) * 10;
        Vendor.Get(CreateVendorWithTaxArea(TaxArea.Code));
        LibraryPurch.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Tax Area Code", TaxArea.Code);
        PurchaseHeader.Validate("Prepayment %", PrepmtPct);
        PurchaseHeader.Validate("Prepmt. Include Tax", true);
        PurchaseHeader.Modify(true);
        Quantity := LibraryRandom.RandIntInRange(1, 5);
        LibraryPurch.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithTaxGroup(TaxGroup.Code), Quantity * 2);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 500));
        PurchaseLine.Modify(true);
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // [GIVEN] Prepayment Invoice is posted with amount of 525 = (1000 + 50) * 50 %
        PostPurchPrepmtInvoice(PurchaseHeader);
        PrepmtAmount := Round(PurchaseHeader."Amount Including VAT" * PrepmtPct / 100);

        // [GIVEN] Purchase order is posted partially with 'Qty. to receive' = 1
        PurchaseLine.Find();
        PurchaseLine.Validate("Qty. to Receive", Quantity);
        PurchaseLine.Modify(true);
        Invoice1 := PostPurchOrder(PurchaseHeader);

        // [WHEN] Post final invoice
        Invoice2 := PostPurchOrder(PurchaseHeader);

        // [THEN] First Purchase Invoice is posted with Amount = 237.5 (500 - 525/2 ) Amount Incl. Tax =262.5 (525 - 525/2)
        // [THEN] G/L Entry for Account Payables has Amount = 262.5
        // [THEN] G/L Entry for Purchase Prepayments Account has Amount = 237.5
        VerifyPostedVendorEntriesWithPrepmt(
          Invoice1, GetGLAccountFromTaxJurisdiction(TaxGroup.Code), PurchaseHeader.Amount / 2,
          (PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount) / 2,
          PurchaseHeader.Amount / 2 - PrepmtAmount / 2, PurchaseHeader."Amount Including VAT" / 2 - PrepmtAmount / 2,
          VendorPostingGroup."Payables Account", GeneralPostingSetup."Purch. Prepayments Account", PrepmtAmount / 2);
        // [THEN] Final invoice has same values after posting
        VerifyPostedVendorEntriesWithPrepmt(
          Invoice2, GetGLAccountFromTaxJurisdiction(TaxGroup.Code), PurchaseHeader.Amount / 2,
          (PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount) / 2,
          PurchaseHeader.Amount / 2 - PrepmtAmount / 2, PurchaseHeader."Amount Including VAT" / 2 - PrepmtAmount / 2,
          VendorPostingGroup."Payables Account", GeneralPostingSetup."Purch. Prepayments Account", PrepmtAmount / 2);
    end;

    local procedure PreparePOwithPostedPrepmtInv(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; NoOfLines: Integer)
    var
        i: Integer;
    begin
        PreparePOwithPurchLine(PurchHeader, PurchLine);
        for i := 1 to NoOfLines do
            AddPurchOrderLine100PctPrepmt(PurchLine);

        PostPurchPrepmtInvoice(PurchHeader);
    end;

    local procedure PreparePOwithPurchLine(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    begin
        PurchHeader."Document Type" := PurchHeader."Document Type"::Order;
        CreatePurchDoc(PurchHeader, FindTaxAreaCode(), PurchHeader."Currency Code", PurchHeader."Prepmt. Include Tax");
        PreparePurchLine(PurchLine, PurchHeader);
    end;

    local procedure CreateItemWithTaxGroup(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchDoc(var PurchHeader: Record "Purchase Header"; TaxAreaCode: Code[20]; CurrencyCode: Code[10]; PrepmtInclTax: Boolean)
    var
        VendorNo: Code[20];
    begin
        if PurchHeader."Buy-from Vendor No." = '' then
            VendorNo := CreateVendorWithTaxArea(TaxAreaCode)
        else
            VendorNo := PurchHeader."Buy-from Vendor No.";
        PrepmtInclTax := PurchHeader."Prepmt. Include Tax";
        LibraryPurch.CreatePurchHeader(PurchHeader, PurchHeader."Document Type", VendorNo);
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Validate("Prices Including VAT", false);
        PurchHeader.Validate("Compress Prepayment", true);
        PurchHeader.Validate("Prepmt. Include Tax", PrepmtInclTax);
        PurchHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchHeader.Modify();
    end;

    local procedure CreateVendorWithTaxArea(TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.SetFilter("Purch. Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.FindFirst();

        Vendor.Init();
        Vendor.Insert(true);
        Vendor.Validate(Name, Vendor."No.");
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Vendor Posting Group", LibraryPurch.FindVendorPostingGroup());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateTaxAreaSetupWithValues(var TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxBelowMax: Decimal)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Purchases)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Modify(true);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxBelowMax);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdiction.Code);
    end;

    local procedure GetGLAccountFromTaxJurisdiction(TaxGroupCode: Code[20]) GLAccFilter: Text
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindSet();
        repeat
            TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
            GLAccFilter += TaxJurisdiction."Tax Account (Purchases)" + '|';
        until TaxDetail.Next() = 0;
        GLAccFilter := CopyStr(GLAccFilter, 1, StrLen(GLAccFilter) - 1);
    end;

    local procedure PreparePurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
        PreparePurchLineForType(PurchLine, PurchHeader, PurchLine.Type::Item, FindItem());
    end;

    local procedure PreparePurchLineForType(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; NewType: Enum "Purchase Line Type"; NewNo: Code[20])
    begin
        PurchLine."Document Type" := PurchHeader."Document Type";
        PurchLine."Document No." := PurchHeader."No.";
        PurchLine."Line No." := 0;
        PurchLine.Type := NewType;
        PurchLine.Validate("No.", NewNo);

        FillPrepmtAcc(PurchLine);
    end;

    local procedure PreparePurchLineForGLAcc(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
        PreparePurchLineForType(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", CreateGLAccount());
    end;

    local procedure AddPurchOrderLine(var PurchLine: Record "Purchase Line"; Qty: Decimal; UnitCost: Decimal; PrepmtPct: Decimal)
    begin
        PurchLine."Line No." += 10000;
        PurchLine.Validate("No.");
        PurchLine.Validate(Quantity, Qty);
        PurchLine.Validate("Direct Unit Cost", UnitCost);
        PurchLine.Validate("Line Discount %", 0);
        PurchLine.Validate("Prepayment %", PrepmtPct);
        PurchLine.Insert(true);
    end;

    local procedure AddPurchOrderLine100PctPrepmt(var PurchLine: Record "Purchase Line")
    begin
        AddPurchOrderLine(PurchLine, 7.3, 3.993, 100); // Magic numbers that lead to prepmt rounding errors. See BUG 332246.
    end;

    local procedure FindTaxAreaCode(): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.FindFirst();
        exit(TaxArea.Code);
    end;

    local procedure FindTaxGroupCode(): Code[10]
    var
        TaxGroup: Record "Tax Group";
    begin
        TaxGroup.SetFilter(Code, '<>NONTAXABLE');
        TaxGroup.FindFirst();
        exit(TaxGroup.Code);
    end;

    local procedure PostPurchPrepmtInvoice(var PurchHeader: Record "Purchase Header")
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        PurchPostPrepayments.Invoice(PurchHeader);
    end;

    local procedure PostPurchOrder(var PurchHeader: Record "Purchase Header"): Code[20]
    begin
        PurchHeader."Vendor Invoice No." := LibraryUtility.GenerateGUID();
        exit(LibraryPurch.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure FindItem(): Code[10]
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        Item.FindFirst();

        Item."No." := '';
        Item.Validate("Tax Group Code", FindTaxGroupCode());
        Item.Insert(true);

        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure."Item No." := Item."No.";
        ItemUnitOfMeasure.Code := Item."Base Unit of Measure";
        ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
        ItemUnitOfMeasure.Insert();

        exit(Item."No.");
    end;

    local procedure FindPurchLine(var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; DocNo: Code[20])
    begin
        PurchLine.SetRange("Document Type", DocType);
        PurchLine.SetRange("Document No.", DocNo);
        PurchLine.FindSet();
    end;

    local procedure CreateCurrency(ExchRateAmount: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), ExchRateAmount, ExchRateAmount);
        exit(Currency.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
        CopyGLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        CopyGLAccount := GLAccount;
        CopyGLAccount."No." := LibraryUtility.GenerateGUID();
        CopyGLAccount."Tax Group Code" := 'NONTAXABLE';
        CopyGLAccount.Insert();
        exit(CopyGLAccount."No.");
    end;

    local procedure FillPrepmtAcc(PurchLine: Record "Purchase Line")
    var
        GenPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GenPostingSetup.Get(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.SetRange("Gen. Prod. Posting Group", PurchLine."Gen. Prod. Posting Group");
        GLAccount.SetRange("VAT Prod. Posting Group", PurchLine."VAT Prod. Posting Group");
        GLAccount.FindFirst();
        GLAccount."Tax Group Code" := 'NONTAXABLE';
        GLAccount.Modify();
        GenPostingSetup."Purch. Prepayments Account" := GLAccount."No.";
        GenPostingSetup.Modify();
    end;

    local procedure GetPrepmtAmount(DocumentNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Original Amt. (LCY)");
        exit(VendorLedgerEntry."Original Amt. (LCY)");
    end;

    local procedure VerifyInvRoundingEqualToRoundingPrecision(VendNo: Code[20]; VendPostingGroupCode: Code[20])
    var
        VendPostingGroup: Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Source Type", GLEntry."Source Type"::Vendor);
        GLEntry.SetRange("Source No.", VendNo);
        GLEntry.FindLast();
        GLEntry.Reset();
        GLEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        VendPostingGroup.Get(VendPostingGroupCode);
        GLEntry.SetRange("G/L Account No.", VendPostingGroup."Invoice Rounding Account");
        GLEntry.FindLast();
        Assert.AreEqual(
          Abs(GLEntry.Amount), LibraryERM.GetAmountRoundingPrecision(), IncorrectInvRoundingErr);
    end;

    local procedure VerifyZeroVendorAccEntry()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.FindLast();
        VendLedgEntry.CalcFields(Amount, "Amount (LCY)");
        Assert.AreEqual(0, VendLedgEntry.Amount, 'Expected zero Vendor Ledger Entry due to 100% prepayment.');
        Assert.AreEqual(0, VendLedgEntry."Amount (LCY)", 'Expected zero Vendor Ledger Entry in LCY due to 100% prepayment.');
    end;

    local procedure VerifyGLEntryAmount(DocumentNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.FindFirst();
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount,
          StrSubstNo(IncorrectAmountErr, DocumentNo, GLAccNo));
    end;

    local procedure VerifyPostedVendorEntries(DocumentNo: Code[20]; GLAccountFilter: Text; ExpVATBase: Decimal; ExpVATAmount: Decimal; ExpSalesInvAmount: Decimal; ExpSalesInvRemAmount: Decimal)
    begin
        VerifyPostedVendorInvoice(DocumentNo, ExpSalesInvAmount, ExpSalesInvRemAmount, ExpSalesInvRemAmount);
        VerifyVATEntries(DocumentNo, ExpVATBase, ExpVATAmount);
        VerifyGLEntries(DocumentNo, GLAccountFilter, ExpVATAmount);
    end;

    local procedure VerifyPostedVendorEntriesWithPrepmt(DocumentNo: Code[20]; GLAccountFilter: Text; ExpVATBase: Decimal; ExpVATAmount: Decimal; ExpSalesInvAmount: Decimal; ExpSalesInvRemAmount: Decimal; ReceivablesAcc: Code[20]; PrepaymentAcc: Code[20]; PrepmtAmount: Decimal)
    begin
        VerifyPostedVendorEntries(
          DocumentNo, GLAccountFilter, ExpVATBase, ExpVATAmount, ExpSalesInvAmount, ExpSalesInvRemAmount);
        VerifyGLEntries(DocumentNo, ReceivablesAcc, -(ExpVATBase + ExpVATAmount - PrepmtAmount));
        VerifyGLEntries(DocumentNo, PrepaymentAcc, -PrepmtAmount);
    end;

    local procedure VerifyPostedVendorInvoice(DocumentNo: Code[20]; ExpAmount: Decimal; ExpAmountInclVAT: Decimal; ExpRemAmount: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
        PurchInvHeader.CalcFields(Amount);
        PurchInvHeader.TestField(Amount, ExpAmount);
        PurchInvHeader.TestField("Amount Including VAT", ExpAmountInclVAT);
        PurchInvHeader.TestField("Remaining Amount", ExpRemAmount);
    end;

    local procedure VerifyVATEntries(DocumentNo: Code[20]; ExpBase: Decimal; ExpAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Base, Amount);
        VATEntry.TestField(Base, ExpBase);
        VATEntry.TestField(Amount, ExpAmount);
    end;

    local procedure VerifyGLEntries(DocumentNo: Code[20]; GLAccFilter: Text; ExpAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter("G/L Account No.", GLAccFilter);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpAmount);
    end;
}

