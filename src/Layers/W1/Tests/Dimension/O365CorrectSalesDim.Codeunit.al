codeunit 138034 "O365 Correct Sales Dim."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Invoice] [Sales] [Dimension]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemDimBlocked()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        DimValue: Record "Dimension Value";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize();

        CreateItemsWithPrice(Item, 0);

        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue, 1);
        Item.Validate("Global Dimension 1 Code", DimValue.Code);
        Item.Modify(true);

        LibrarySales.CreateCustomer(Cust);
        SellItem(Cust, Item, 1, SalesInvoiceHeader);

        // Block the Dimension
        BlockDimValue(DimValue);

        GLEntry.FindLast();

        // EXERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // EXERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // Unblock the Dimension
        UnblockDimValue(DimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustDimBlocked()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        DimValue: Record "Dimension Value";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize();

        CreateItemsWithPrice(Item, 0);
        LibrarySales.CreateCustomer(Cust);

        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue, 1);
        Cust.Validate("Global Dimension 1 Code", DimValue.Code);
        Cust.Modify(true);
        SellItem(Cust, Item, 1, SalesInvoiceHeader);

        // Block the Dimension
        BlockDimValue(DimValue);

        if GLEntry.FindLast() then;

        // EXERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // EXERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // Unblock the Dimension
        UnblockDimValue(DimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemCombinationBlocked()
    var
        Cust: Record Customer;
        Item: Record Item;
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Initialize();

        CreateItemsWithPrice(Item, 0);

        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue1, 1);
        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue2, 2);

        Item.Validate("Global Dimension 1 Code", DimValue1.Code);
        Item.Validate("Global Dimension 2 Code", DimValue2.Code);
        Item.Modify(true);

        LibrarySales.CreateCustomer(Cust);
        SellItem(Cust, Item, 1, SalesInvoiceHeader);

        GLEntry.FindLast();

        // EXERCISE AND VERIFY CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        TryCorrectingABlockedDimCombOnAPostedInvoice(
          SalesInvoiceHeader, DimValue1."Dimension Code", DimValue2."Dimension Code", Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustCombinationBlocked()
    var
        Cust: Record Customer;
        Item: Record Item;
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue1, 1);
        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue2, 2);

        CreateItemsWithPrice(Item, 1);
        LibrarySales.CreateCustomer(Cust);

        Cust.Validate("Global Dimension 1 Code", DimValue1.Code);
        Cust.Validate("Global Dimension 2 Code", DimValue2.Code);
        Cust.Modify(true);

        CreateSalesInvoiceForItem(Cust, Item, 1, SalesHeader, SalesLine);
        SalesLine.Validate("Shortcut Dimension 1 Code", '');
        SalesLine.Validate("Shortcut Dimension 2 Code", '');
        SalesLine.Modify(true);
        Commit();

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));

        GLEntry.FindLast();

        // EXERCISE AND VERIFY
        TryCorrectingABlockedDimCombOnAPostedInvoice(
          SalesInvoiceHeader, DimValue1."Dimension Code", DimValue2."Dimension Code", Cust, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustItemDimMandatory()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        CustPostingGroup: Record "Customer Posting Group";
        InvtPostingSetup: Record "Inventory Posting Setup";
        TempDefaultDim: Record "Default Dimension" temporary;
        DefaultDim: Record "Default Dimension";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        Initialize();

        CreateItemsWithPrice(Item, 1);
        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);
        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);

        // Make Dimension Mandatory
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          TempDefaultDim, DATABASE::Customer, BillToCust."No.", TempDefaultDim."Value Posting"::"Code Mandatory");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          TempDefaultDim, DATABASE::Item, Item."No.", TempDefaultDim."Value Posting"::"Code Mandatory");

        CustPostingGroup.Get(BillToCust."Customer Posting Group");
        InvtPostingSetup.Get(SellToCust."Location Code", Item."Inventory Posting Group");
        InitGLAccountsDefDimCandatoryScenario(
          TempDefaultDim, CustPostingGroup."Receivables Account", InvtPostingSetup."Inventory Account");

        TempDefaultDim.FindSet();
        repeat
            DefaultDim := TempDefaultDim;
            DefaultDim.Insert(true);
            Commit();

            GLEntry.FindLast();

            // EXERCISE
            asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

            // VERIFY
            CheckNothingIsCreated(BillToCust."No.", GLEntry);

            // EXERCISE
            asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

            // VERIFY
            CheckNothingIsCreated(BillToCust."No.", GLEntry);

            // Unblock the Dimension
            DefaultDim.Delete(true);
            Commit();
        until TempDefaultDim.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATGLAccDimMandatory()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLAcc: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize();

        CreateItemsWithPrice(Item, 1);

        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);

        VATPostingSetup.Get(BillToCust."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        GLAcc.Get(VATPostingSetup."Sales VAT Account");

        SellItem(SellToCust, Item, 1, SalesInvoiceHeader);

        VerifyCorrectionFailsOnMandatoryDimGLAcc(GLAcc, BillToCust, SalesInvoiceHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelSalesDocPayablesAccWithNoCodeDimension()
    var
        SellToCust: Record Customer;
        BillToCust: Record Customer;
        Item: Record Item;
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHdr: Record "Sales Cr.Memo Header";
        GLAcc: Record "G/L Account";
        CustomerPostingGroup: Record "Customer Posting Group";
        InvtPostingSetup: Record "Inventory Posting Setup";
        DefaultDim: Record "Default Dimension";
        DefaultDim2: Record "Default Dimension";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // [SCENARIO 415473] Sales document with Reveivables Account with No Code dimension can be cancelled
        Initialize();

        // [GIVEN] Item "I" with Dimension and "Value Posting" = "Code Mandatory"
        CreateItemsWithPrice(Item, 1);
        CreateSellToWithDifferentBillToCust(SellToCust, BillToCust);
        InvtPostingSetup.Get(SellToCust."Location Code", Item."Inventory Posting Group");
        GLAcc.Get(InvtPostingSetup."Inventory Account");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
            DefaultDim, DATABASE::Item, Item."No.", DefaultDim."Value Posting"::"Code Mandatory");

        // [GIVEN] Vendor "V" with Vendor Postin Group, with "Paybles Account" = G/L Account with Dimension and "Value Posting" = "No Code"
        CustomerPostingGroup.Get(BillToCust."Customer Posting Group");
        GLAcc.Get(CustomerPostingGroup."Receivables Account");
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDim2, GLAcc."No.", DefaultDim."Dimension Code", '');
        DefaultDim2.Validate("Value Posting", DefaultDim2."Value Posting"::"No Code");
        DefaultDim2.Modify(true);

        // [GIVEN] Posted Purchase Invoice for Vendor "V" and item "I"
        SellItem(SellToCust, Item, 1, SalesInvHeader);
        Commit();

        // [WHEN] Posted Purchase Invoice is cancelled
        // [THEN] Invoice is Cancelled with no errors
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvHeader);

        SalesCrMemoHdr.Reset();
        SalesCrMemoHdr.SetRange("Sell-to Customer No.", SellToCust."No.");
        Assert.RecordIsNotEmpty(SalesCrMemoHdr);
        // Unblock the Dimension
        DefaultDim.Delete(true);
        DefaultDim2.Delete(true);
        Commit();
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Correct Sales Dim.");
        // Initialize setup.
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Correct Sales Dim.");

        IsInitialized := true;

        LibraryERMCountryData.CreateVATData();

        SetGlobalNoSeriesInSetups();

        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Correct Sales Dim.");
    end;

    local procedure SetGlobalNoSeriesInSetups()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        MarketingSetup: Record "Marketing Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup."Customer Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        SalesReceivablesSetup.Modify();

        MarketingSetup.Get();
        MarketingSetup."Contact Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        MarketingSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Ext. Doc. No. Mandatory" := false;
        PurchasesPayablesSetup."Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Posted Credit Memo Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Invoice Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Order Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup."Vendor Nos." := LibraryUtility.GetGlobalNoSeriesCode();
        PurchasesPayablesSetup.Modify();
    end;

    local procedure CreateItemsWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        CreateServiceItemWithPrice(Item, UnitPrice);
        CreateInventoryItemWithPrice(Item, UnitPrice);
    end;

    local procedure CreateInventoryItemWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Type := Item.Type::Inventory;
        Item.Modify();
    end;

    local procedure CreateServiceItemWithPrice(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := UnitPrice;
        Item.Type := Item.Type::Service;
        Item.Modify();
    end;

    local procedure CreateSalesInvoiceForItem(Cust: Record Customer; Item: Record Item; Qty: Decimal; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Cust."No.", Item."No.", Qty, '', 0D);
    end;

    local procedure CreateSellToWithDifferentBillToCust(var SellToCust: Record Customer; var BillToCust: Record Customer)
    begin
        LibrarySales.CreateCustomer(SellToCust);
        LibrarySales.CreateCustomer(BillToCust);
        SellToCust.Validate("Bill-to Customer No.", BillToCust."No.");
        SellToCust.Modify(true);
    end;

    local procedure BlockDimValue(var DimValue: Record "Dimension Value")
    begin
        DimValue.Validate(Blocked, true);
        DimValue.Modify(true);
        Commit();
    end;

    local procedure BlockDimCombination(DimCode1: Code[20]; DimCode2: Code[20])
    var
        DimCombination: Record "Dimension Combination";
    begin
        DimCombination.Init();
        DimCombination.Validate("Dimension 1 Code", DimCode1);
        DimCombination.Validate("Dimension 2 Code", DimCode2);
        DimCombination.Validate("Combination Restriction", DimCombination."Combination Restriction"::Blocked);
        DimCombination.Insert();
        Commit();
    end;

    local procedure UnblockDimValue(var DimValue: Record "Dimension Value")
    begin
        DimValue.Validate(Blocked, false);
        DimValue.Modify(true);
        Commit();
    end;

    local procedure UnblockDimCombination(DimCode1: Code[20]; DimCode2: Code[20])
    var
        DimCombination: Record "Dimension Combination";
    begin
        DimCombination.Get(DimCode1, DimCode2);
        DimCombination.Delete(true);
        Commit();
    end;

    local procedure SellItem(SellToCust: Record Customer; Item: Record Item; Qty: Decimal; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesInvoiceForItem(SellToCust, Item, Qty, SalesHeader, SalesLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure InitGLAccountsDefDimCandatoryScenario(var DefaultDim: Record "Default Dimension"; FirstGLAccNo: Code[20]; SecondGLAccNo: Code[20])
    begin
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDim, DATABASE::"G/L Account", FirstGLAccNo, DefaultDim."Value Posting"::"Code Mandatory");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDim, DATABASE::"G/L Account", SecondGLAccNo, DefaultDim."Value Posting"::"Code Mandatory");
    end;

    local procedure CheckNothingIsCreated(CustNo: Code[20]; LastGLEntry: Record "G/L Entry")
    var
        SalesHeader: Record "Sales Header";
    begin
        Assert.IsTrue(LastGLEntry.Next() = 0, 'No new G/L entries are created');
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetRange("Bill-to Customer No.", CustNo);
        Assert.IsTrue(SalesHeader.IsEmpty, 'The Credit Memo should not have been created');
    end;

    local procedure TryCorrectingABlockedDimCombOnAPostedInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; DimCode1: Code[20]; DimCode2: Code[20]; Cust: Record Customer; GLEntry: Record "G/L Entry")
    var
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // Block the Dimension Combination
        BlockDimCombination(DimCode1, DimCode2);

        // EXERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // EXERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY
        CheckNothingIsCreated(Cust."No.", GLEntry);

        // Unblock the Dimension Combination
        UnblockDimCombination(DimCode1, DimCode2);
    end;

    local procedure VerifyCorrectionFailsOnMandatoryDimGLAcc(GLAcc: Record "G/L Account"; BillToCust: Record Customer; SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        DefaultDim: Record "Default Dimension";
        GLEntry: Record "G/L Entry";
        SalesHeaderCorrection: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        // Make Dimension Mandatory
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDim, DATABASE::"G/L Account", GLAcc."No.", DefaultDim."Value Posting"::"Code Mandatory");
        Commit();

        if GLEntry.FindLast() then;

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(BillToCust."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        // VERIFY
        CheckNothingIsCreated(BillToCust."No.", GLEntry);

        // Unblock the Dimension
        DefaultDim.Delete(true);
        Commit();
    end;
}

