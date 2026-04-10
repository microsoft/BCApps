codeunit 138035 "O365 Correct Purchase Dim."
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Cancelled Document] [Invoice] [Purchase] [Dimension]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemDimBlocked()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        DimValue: Record "Dimension Value";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();
        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue, 1);

        CreateItemWithCost(Item, Item.Type::Inventory, 0);
        Item.Validate("Global Dimension 1 Code", DimValue.Code);
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vendor);
        BuyItem(Vendor, Item, 1, PurchInvHeader);

        // Block the Dimension
        BlockDimValue(DimValue);

        GLEntry.FindLast();

        // EXCERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // EXCERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // Unblock the Dimension
        UnblockDimValue(DimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorDimBlocked()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLEntry: Record "G/L Entry";
        DimValue: Record "Dimension Value";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();
        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue, 1);

        CreateItemWithCost(Item, Item.Type::Inventory, 0);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Global Dimension 1 Code", DimValue.Code);
        Vendor.Modify(true);

        BuyItem(Vendor, Item, 1, PurchInvHeader);

        // Block the Dimension
        BlockDimValue(DimValue);

        if GLEntry.FindLast() then;

        // EXERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // EXERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY
        CheckNothingIsCreated(Vendor."No.", GLEntry);

        // Unblock the Dimension
        UnblockDimValue(DimValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemCombinationBlocked()
    var
        Vend: Record Vendor;
        Item: Record Item;
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        Initialize();

        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue1, 1);
        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue2, 2);

        CreateItemWithCost(Item, Item.Type::Inventory, 0);
        Item.Validate("Global Dimension 1 Code", DimValue1.Code);
        Item.Validate("Global Dimension 2 Code", DimValue2.Code);
        Item.Modify(true);

        LibraryPurchase.CreateVendor(Vend);
        BuyItem(Vend, Item, 1, PurchInvHeader);

        GLEntry.FindLast();

        // EXERCISE AND VERIFY CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        TryCorrectingABlockedDimCombOnAPostedInvoice(
          PurchInvHeader, DimValue1."Dimension Code", DimValue2."Dimension Code", Vend, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendCombinationBlocked()
    var
        Vend: Record Vendor;
        Item: Record Item;
        DimValue1: Record "Dimension Value";
        DimValue2: Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        Initialize();

        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue1, 1);
        LibrarySmallBusiness.InitGlobalDimCodeValue(DimValue2, 2);

        CreateItemWithCost(Item, Item.Type::Inventory, 1);

        LibraryPurchase.CreateVendor(Vend);
        Vend.Validate("Global Dimension 1 Code", DimValue1.Code);
        Vend.Validate("Global Dimension 2 Code", DimValue2.Code);
        Vend.Modify(true);

        CreatePurchaseInvoiceForItem(Vend, Item, 1, PurchHeader, PurchLine);
        PurchLine.Validate("Shortcut Dimension 1 Code", '');
        PurchLine.Validate("Shortcut Dimension 2 Code", '');
        PurchLine.Modify(true);
        Commit();

        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchHeader, false, true));

        GLEntry.FindLast();

        // EXERCISE AND VERIFY
        TryCorrectingABlockedDimCombOnAPostedInvoice(
          PurchInvHeader, DimValue1."Dimension Code", DimValue2."Dimension Code", Vend, GLEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVendorItemDimMandatory()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        VendorPostingGroup: Record "Vendor Posting Group";
        InvtPostingSetup: Record "Inventory Posting Setup";
        TempDefaultDim: Record "Default Dimension" temporary;
        DefaultDim: Record "Default Dimension";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        Initialize();

        CreateItemWithCost(Item, Item.Type::Inventory, 1);
        CreateBuyFromWithDifferentPayToVendor(BuyFromVendor, PayToVendor);
        BuyItem(BuyFromVendor, Item, 1, PurchInvHeader);

        // Make Dimension Mandatory
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          TempDefaultDim, DATABASE::Vendor, PayToVendor."No.", TempDefaultDim."Value Posting"::"Code Mandatory");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          TempDefaultDim, DATABASE::Item, Item."No.", TempDefaultDim."Value Posting"::"Code Mandatory");

        VendorPostingGroup.Get(PayToVendor."Vendor Posting Group");
        GLAcc.Get(VendorPostingGroup."Payables Account");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          TempDefaultDim, DATABASE::"G/L Account", GLAcc."No.", TempDefaultDim."Value Posting"::"Code Mandatory");

        InvtPostingSetup.Get(BuyFromVendor."Location Code", Item."Inventory Posting Group");
        GLAcc.Get(InvtPostingSetup."Inventory Account");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          TempDefaultDim, DATABASE::"G/L Account", GLAcc."No.", TempDefaultDim."Value Posting"::"Code Mandatory");
        TempDefaultDim.FindSet();
        repeat
            DefaultDim := TempDefaultDim;
            DefaultDim.Insert(true);
            Commit();

            GLEntry.FindLast();

            // EXERCISE
            asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

            // VERIFY
            CheckNothingIsCreated(PayToVendor."No.", GLEntry);

            // EXERCISE
            asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

            // VERIFY
            CheckNothingIsCreated(PayToVendor."No.", GLEntry);

            // Unblock the Dimension
            DefaultDim.Delete(true);
            Commit();
        until TempDefaultDim.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATGLAccDimMandatory()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        GLAcc: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize();

        CreateItemWithCost(Item, Item.Type::Inventory, 1);

        CreateBuyFromWithDifferentPayToVendor(BuyFromVendor, PayToVendor);

        VATPostingSetup.Get(PayToVendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        GLAcc.Get(VATPostingSetup."Purchase VAT Account");

        BuyItem(BuyFromVendor, Item, 1, PurchInvHeader);

        VerifyCorrectionFailsOnMandatoryDimGLAcc(GLAcc."No.", PayToVendor, PurchInvHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPurchDocPayablesAccWithNoCodeDimension()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item: Record Item;
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        GLAcc: Record "G/L Account";
        VendorPostingGroup: Record "Vendor Posting Group";
        InvtPostingSetup: Record "Inventory Posting Setup";
        DefaultDim: Record "Default Dimension";
        DefaultDim2: Record "Default Dimension";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // [SCENARIO 415473] Purchase document with Pyables Account with No Code dimension can be cancelled
        Initialize();

        // [GIVEN] Item "I" with Dimension and "Value Posting" = "Code Mandatory"
        CreateItemWithCost(Item, Item.Type::Inventory, 1);
        CreateBuyFromWithDifferentPayToVendor(BuyFromVendor, PayToVendor);
        InvtPostingSetup.Get(BuyFromVendor."Location Code", Item."Inventory Posting Group");
        GLAcc.Get(InvtPostingSetup."Inventory Account");
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
            DefaultDim, DATABASE::Item, Item."No.", DefaultDim."Value Posting"::"Code Mandatory");

        // [GIVEN] Vendor "V" with Vendor Postin Group, with "Paybles Account" = G/L Account with Dimension and "Value Posting" = "No Code"
        VendorPostingGroup.Get(PayToVendor."Vendor Posting Group");
        GLAcc.Get(VendorPostingGroup."Payables Account");
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDim2, GLAcc."No.", DefaultDim."Dimension Code", '');
        DefaultDim2.Validate("Value Posting", DefaultDim2."Value Posting"::"No Code");
        DefaultDim2.Modify(true);

        // [GIVEN] Posted Purchase Invoice for Vendor "V" and item "I"
        BuyItem(BuyFromVendor, Item, 1, PurchInvHeader);
        Commit();

        // [WHEN] Posted Purchase Invoice is cancelled
        // [THEN] Invoice is Cancelled with no errors
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        PurchCrMemoHdr.Reset();
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", BuyFromVendor."No.");
        Assert.RecordIsNotEmpty(PurchCrMemoHdr);
        // Unblock the Dimension
        DefaultDim.Delete(true);
        DefaultDim2.Delete(true);
        Commit();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Correct Purchase Dim.");
        // Initialize setup.
        LibraryApplicationArea.EnableFoundationSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Correct Purchase Dim.");

        ClearTable(DATABASE::"Production BOM Line");
        ClearTable(DATABASE::Resource);

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryERMCountryData.CreateVATData();

        SetGlobalNoSeriesInSetups();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Correct Purchase Dim.");
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

    local procedure ClearTable(TableID: Integer)
    var
        ProductionBOMLine: Record "Production BOM Line";
        Resource: Record Resource;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::"Production BOM Line":
                ProductionBOMLine.DeleteAll();
            DATABASE::Resource:
                Resource.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    local procedure CreateItemWithCost(var Item: Record Item; ItemType: Enum "Item Type"; UnitCost: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, ItemType);
        Item."Last Direct Cost" := UnitCost;
        Item.Modify();
    end;

    local procedure CreateBuyFromWithDifferentPayToVendor(var BuyFromVendor: Record Vendor; var PayToVendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(BuyFromVendor);
        LibraryPurchase.CreateVendor(PayToVendor);
        BuyFromVendor.Validate("Pay-to Vendor No.", PayToVendor."No.");
        BuyFromVendor.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceForItem(Vendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, Vendor."No.", Item."No.", Qty, '', 0D);
    end;

    local procedure BuyItem(BuyFromVendor: Record Vendor; Item: Record Item; Qty: Decimal; var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseInvoiceForItem(BuyFromVendor, Item, Qty, PurchaseHeader, PurchaseLine);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
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

    local procedure CheckNothingIsCreated(VendorNo: Code[20]; LastGLEntry: Record "G/L Entry")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        Assert.IsTrue(LastGLEntry.Next() = 0, 'No new G/L entries are created');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.SetRange("Pay-to Vendor No.", VendorNo);
        Assert.IsTrue(PurchaseHeader.IsEmpty, 'The Credit Memo should not have been created');
    end;

    local procedure TryCorrectingABlockedDimCombOnAPostedInvoice(PurchInvHeader: Record "Purch. Inv. Header"; DimCode1: Code[20]; DimCode2: Code[20]; Vend: Record Vendor; GLEntry: Record "G/L Entry")
    var
        PurchHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // Block the Dimension Combination
        BlockDimCombination(DimCode1, DimCode2);

        // EXERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(Vend."No.", GLEntry);

        // EXERCISE CHECK IT SHOULD BE POSSIBLE TO UNDO IF ITEM IS BLOCKED
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY
        CheckNothingIsCreated(Vend."No.", GLEntry);

        // Unblock the Dimension Combination
        UnblockDimCombination(DimCode1, DimCode2);
    end;

    local procedure VerifyCorrectionFailsOnMandatoryDimGLAcc(GLAccNo: Code[20]; PayToVendor: Record Vendor; PurchInvHeader: Record "Purch. Inv. Header")
    var
        DefaultDim: Record "Default Dimension";
        GLEntry: Record "G/L Entry";
        PurchaseHeaderCorrection: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        // Make Dimension Mandatory
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDim, DATABASE::"G/L Account", GLAccNo, DefaultDim."Value Posting"::"Code Mandatory");
        Commit();

        if GLEntry.FindLast() then;

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeaderCorrection);

        // VERIFY
        CheckNothingIsCreated(PayToVendor."No.", GLEntry);

        // EXERCISE
        asserterror CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);

        // VERIFY
        CheckNothingIsCreated(PayToVendor."No.", GLEntry);

        // Unblock the Dimension
        DefaultDim.Delete(true);
        Commit();
    end;
}

