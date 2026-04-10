codeunit 134097 "ERM Check Posting Groups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Posting Group] [Account] [UT]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCustPostingGroupGetAccounts()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Initialize();

        // Execute
        CreateCustomerPostingGroup(CustomerPostingGroup, false);
        // Verify
        Assert.AreEqual(
          CustomerPostingGroup."Receivables Account", CustomerPostingGroup.GetReceivablesAccount(), 'Receivables Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Service Charge Acc.", CustomerPostingGroup.GetServiceChargeAccount(), 'Service Charge Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Payment Disc. Debit Acc.", CustomerPostingGroup.GetPmtDiscountAccount(true), 'Payment Disc. Debit Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Payment Disc. Credit Acc.", CustomerPostingGroup.GetPmtDiscountAccount(false), 'Payment Disc. Credit Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Invoice Rounding Account", CustomerPostingGroup.GetInvRoundingAccount(), 'Invoice Rounding Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Additional Fee Account", CustomerPostingGroup.GetAdditionalFeeAccount(), 'Additional Fee Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Interest Account", CustomerPostingGroup.GetInterestAccount(), 'Interest Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Debit Curr. Appln. Rndg. Acc.", CustomerPostingGroup.GetApplRoundingAccount(true), 'Debit Curr. Appln. Rndg. Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Credit Curr. Appln. Rndg. Acc.", CustomerPostingGroup.GetApplRoundingAccount(false), 'Credit Curr. Appln. Rndg. Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Debit Rounding Account", CustomerPostingGroup.GetRoundingAccount(true), 'Debit Rounding Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Credit Rounding Account", CustomerPostingGroup.GetRoundingAccount(false), 'Credit Rounding Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Payment Tolerance Debit Acc.", CustomerPostingGroup.GetPmtToleranceAccount(true), 'Payment Tolerance Debit Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Payment Tolerance Credit Acc.", CustomerPostingGroup.GetPmtToleranceAccount(false), 'Payment Tolerance Credit Accounts are not equal');
        Assert.AreEqual(
          CustomerPostingGroup."Add. Fee per Line Account", CustomerPostingGroup.GetAddFeePerLineAccount(), 'Add. Fee per Line Accounts are not equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVendPostingGroupGetAccounts()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Initialize();

        // Execute
        CreateVendorPostingGroup(VendorPostingGroup, false);
        // Verify
        Assert.AreEqual(
          VendorPostingGroup."Payables Account", VendorPostingGroup.GetPayablesAccount(), 'Payables Accounts are not equal');
        Assert.AreEqual(
          VendorPostingGroup."Service Charge Acc.", VendorPostingGroup.GetServiceChargeAccount(), 'Service Charge Accounts are not equal');
        Assert.AreEqual(
          VendorPostingGroup."Payment Disc. Debit Acc.", VendorPostingGroup.GetPmtDiscountAccount(true), 'Payment Disc. Debit Accounts are not equal');
        Assert.AreEqual(
          VendorPostingGroup."Payment Disc. Credit Acc.", VendorPostingGroup.GetPmtDiscountAccount(false), 'Payment Disc. Credit Accounts are not equal');
        Assert.AreEqual(
          VendorPostingGroup."Invoice Rounding Account", VendorPostingGroup.GetInvRoundingAccount(), 'Invoice Rounding Accounts are not equal');
        Assert.AreEqual(
          VendorPostingGroup."Debit Curr. Appln. Rndg. Acc.", VendorPostingGroup.GetApplRoundingAccount(true), 'Debit Curr. Appln. Rndg. Accounts are not equal');
        Assert.AreEqual(
          VendorPostingGroup."Credit Curr. Appln. Rndg. Acc.", VendorPostingGroup.GetApplRoundingAccount(false), 'Credit Curr. Appln. Rndg. Accounts are not equal');
        Assert.AreEqual(
          VendorPostingGroup."Debit Rounding Account", VendorPostingGroup.GetRoundingAccount(true), 'Debit Rounding Accounts are not equal');
        Assert.AreEqual(
          VendorPostingGroup."Credit Rounding Account", VendorPostingGroup.GetRoundingAccount(false), 'Credit Rounding Accounts are not equal');
        Assert.AreEqual(
          VendorPostingGroup."Payment Tolerance Debit Acc.", VendorPostingGroup.GetPmtToleranceAccount(true), 'Payment Tolerance Debit Accounts are not equal');
        Assert.AreEqual(
          VendorPostingGroup."Payment Tolerance Credit Acc.", VendorPostingGroup.GetPmtToleranceAccount(false), 'Payment Tolerance Credit Accounts are not equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckInvtPostingSetupGetAccounts()
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        Initialize();

        // Execute
        CreateInventoryPostingSetup(InventoryPostingSetup, false);
        // Verify
        Assert.AreEqual(
          InventoryPostingSetup."Inventory Account", InventoryPostingSetup.GetInventoryAccount(), 'Inventory Accounts are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."Inventory Account (Interim)", InventoryPostingSetup.GetInventoryAccountInterim(), 'Inventory Accounts (Interim) are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."WIP Account", InventoryPostingSetup.GetWIPAccount(), 'WIP Accounts are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."Material Variance Account", InventoryPostingSetup.GetMaterialVarianceAccount(), 'Material Variance Accounts are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."Capacity Variance Account", InventoryPostingSetup.GetCapacityVarianceAccount(), 'Capacity Variance Accounts are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."Mfg. Overhead Variance Account", InventoryPostingSetup.GetMfgOverheadVarianceAccount(), 'Mfg. Overhead Variance Accounts are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."Cap. Overhead Variance Account", InventoryPostingSetup.GetCapOverheadVarianceAccount(), 'Cap. Overhead Variance Accounts are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."Subcontracted Variance Account", InventoryPostingSetup.GetSubcontractedVarianceAccount(), 'Subcontracted Variance Accounts are not equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckGenPostingGroupGetAccounts()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenPostingSetup: Record "General Posting Setup";
    begin
        Initialize();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Adjust for Payment Disc." := true;
        GeneralLedgerSetup.Modify();

        // Execute
        CreateGeneralPostingSetup(GenPostingSetup, false);
        // Verify
        Assert.AreEqual(
          GenPostingSetup."Sales Account", GenPostingSetup.GetSalesAccount(), 'Sales Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Line Disc. Account", GenPostingSetup.GetSalesLineDiscAccount(), 'Sales Line Disc. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Inv. Disc. Account", GenPostingSetup.GetSalesInvDiscAccount(), 'Sales Inv. Disc. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Pmt. Disc. Debit Acc.", GenPostingSetup.GetSalesPmtDiscountAccount(true), 'Sales Pmt. Disc. Debit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Account", GenPostingSetup.GetPurchAccount(), 'Purch. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Line Disc. Account", GenPostingSetup.GetPurchLineDiscAccount(), 'Purch. Line Disc. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Inv. Disc. Account", GenPostingSetup.GetPurchInvDiscAccount(), 'Purch. Inv. Disc. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Pmt. Disc. Credit Acc.", GenPostingSetup.GetPurchPmtDiscountAccount(false), 'Purch. Pmt. Disc. Credit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."COGS Account", GenPostingSetup.GetCOGSAccount(), 'COGS Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Inventory Adjmt. Account", GenPostingSetup.GetInventoryAdjmtAccount(), 'Inventory Adjmt. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Credit Memo Account", GenPostingSetup.GetSalesCrMemoAccount(), 'Sales Credit Memo Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Credit Memo Account", GenPostingSetup.GetPurchCrMemoAccount(), 'Purch. Credit Memo Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Pmt. Tol. Debit Acc.", GenPostingSetup.GetSalesPmtToleranceAccount(true), 'Sales Pmt. Tol. Debit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Pmt. Tol. Credit Acc.", GenPostingSetup.GetSalesPmtToleranceAccount(false), 'Sales Pmt. Tol. Credit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Pmt. Tol. Debit Acc.", GenPostingSetup.GetPurchPmtToleranceAccount(true), 'Purch. Pmt. Tol. Debit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Pmt. Tol. Credit Acc.", GenPostingSetup.GetPurchPmtToleranceAccount(false), 'Purch. Pmt. Tol. Credit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Prepayments Account", GenPostingSetup.GetSalesPrepmtAccount(), 'Sales Prepayments Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Prepayments Account", GenPostingSetup.GetPurchPrepmtAccount(), 'Purch. Prepayments Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. FA Disc. Account", GenPostingSetup.GetPurchFADiscAccount(), 'Purch. FA Disc. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Invt. Accrual Acc. (Interim)", GenPostingSetup.GetInventoryAccrualAccount(), 'Invt. Accrual Accounts (Interim) are not equal');
        Assert.AreEqual(
          GenPostingSetup."COGS Account (Interim)", GenPostingSetup.GetCOGSInterimAccount(), 'COGS Accounts (Interim) are not equal');
        Assert.AreEqual(
          GenPostingSetup."Direct Cost Applied Account", GenPostingSetup.GetDirectCostAppliedAccount(), 'Direct Cost Applied Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Overhead Applied Account", GenPostingSetup.GetOverheadAppliedAccount(), 'Overhead Applied Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purchase Variance Account", GenPostingSetup.GetPurchaseVarianceAccount(), 'Purchase Variance Accounts are not equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckVATPostingGroupGetAccounts()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Initialize();

        // Execute
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup."Sales VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Sales VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Purchase VAT Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Purch. VAT Unreal. Account" := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Reverse Chrg. VAT Acc." := LibraryERM.CreateGLAccountNo();
        VATPostingSetup."Reverse Chrg. VAT Unreal. Acc." := LibraryERM.CreateGLAccountNo();
        VATPostingSetup.Modify();
        // Verify
        Assert.AreEqual(
          VATPostingSetup."Sales VAT Account", VATPostingSetup.GetSalesAccount(false), 'Sales VAT Accounts are not equal');
        Assert.AreEqual(
          VATPostingSetup."Sales VAT Unreal. Account", VATPostingSetup.GetSalesAccount(true), 'Sales VAT Unreal. Accounts are not equal');
        Assert.AreEqual(
          VATPostingSetup."Purchase VAT Account", VATPostingSetup.GetPurchAccount(false), 'Purchase VAT Accounts are not equal');
        Assert.AreEqual(
          VATPostingSetup."Purch. VAT Unreal. Account", VATPostingSetup.GetPurchAccount(true), 'Purch. VAT Unreal. Accounts are not equal');
        Assert.AreEqual(
          VATPostingSetup."Reverse Chrg. VAT Acc.", VATPostingSetup.GetRevChargeAccount(false), 'Reverse Chrg. VAT Accounts are not equal');
        Assert.AreEqual(
          VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.", VATPostingSetup.GetRevChargeAccount(true), 'Reverse Chrg. VAT Unreal. Accounts are not equal');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure CheckInvtPostingSetupSuggestAccounts()
    var
        Location: Record Location;
        InventoryPostingGroup: Record "Inventory Posting Group";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        TestInventoryPostingSetup: Record "Inventory Posting Setup";
        RecRef: RecordRef;
    begin
        Initialize();

        // Execute
        LibraryWarehouse.CreateLocation(Location);
        if not InventoryPostingSetup.FindFirst() then
            LibraryInventory.CreateInventoryPostingSetup(
              InventoryPostingSetup, Location.Code, InventoryPostingSetup."Invt. Posting Group Code")
        else begin
            LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
            LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, InventoryPostingGroup.Code);
        end;
        RecRef.GetTable(InventoryPostingSetup);
        SuggestAccount2(RecRef, InventoryPostingSetup."Location Code", InventoryPostingSetup."Invt. Posting Group Code", InventoryPostingSetup.FieldNo("Inventory Account"));
        SuggestAccount2(RecRef, InventoryPostingSetup."Location Code", InventoryPostingSetup."Invt. Posting Group Code", InventoryPostingSetup.FieldNo("Inventory Account (Interim)"));
        SuggestAccount2(RecRef, InventoryPostingSetup."Location Code", InventoryPostingSetup."Invt. Posting Group Code", InventoryPostingSetup.FieldNo("WIP Account"));
        SuggestAccount2(RecRef, InventoryPostingSetup."Location Code", InventoryPostingSetup."Invt. Posting Group Code", InventoryPostingSetup.FieldNo("Material Variance Account"));
        SuggestAccount2(RecRef, InventoryPostingSetup."Location Code", InventoryPostingSetup."Invt. Posting Group Code", InventoryPostingSetup.FieldNo("Capacity Variance Account"));
        SuggestAccount2(RecRef, InventoryPostingSetup."Location Code", InventoryPostingSetup."Invt. Posting Group Code", InventoryPostingSetup.FieldNo("Mfg. Overhead Variance Account"));
        SuggestAccount2(RecRef, InventoryPostingSetup."Location Code", InventoryPostingSetup."Invt. Posting Group Code", InventoryPostingSetup.FieldNo("Cap. Overhead Variance Account"));
        SuggestAccount2(RecRef, InventoryPostingSetup."Location Code", InventoryPostingSetup."Invt. Posting Group Code", InventoryPostingSetup.FieldNo("Subcontracted Variance Account"));
        TestInventoryPostingSetup := InventoryPostingSetup;
        InventoryPostingSetup.Init();
        InventoryPostingSetup.SuggestSetupAccounts();
        InventoryPostingSetup.Modify();
        // Verify
        Assert.AreEqual(
          InventoryPostingSetup."Inventory Account", TestInventoryPostingSetup."Inventory Account",
          'Inventory Accounts are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."Inventory Account (Interim)", TestInventoryPostingSetup."Inventory Account (Interim)",
          'Inventory Accounts (Interim) are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."WIP Account", TestInventoryPostingSetup."WIP Account", 'WIP Accounts are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."Material Variance Account", TestInventoryPostingSetup."Material Variance Account",
          'Material Variance Accounts are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."Capacity Variance Account", TestInventoryPostingSetup."Capacity Variance Account",
          'Capacity Variance Accounts are not equal');
        Assert.AreEqual(
          InventoryPostingSetup."Mfg. Overhead Variance Account", TestInventoryPostingSetup."Mfg. Overhead Variance Account",
          'Mfg. Overhead Variance Accounts are not equal');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure CheckGenPostingSetupSuggestAccounts()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GenPostingSetup: Record "General Posting Setup";
        TestGenPostingSetup: Record "General Posting Setup";
        RecRef: RecordRef;
    begin
        Initialize();

        // Execute
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        RecRef.GetTable(GenPostingSetup);
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Sales Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Sales Line Disc. Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Sales Inv. Disc. Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Sales Pmt. Disc. Debit Acc."));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Purch. Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Purch. Line Disc. Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Purch. Inv. Disc. Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Purch. Pmt. Disc. Credit Acc."));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("COGS Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Inventory Adjmt. Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Sales Credit Memo Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Purch. Credit Memo Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Sales Pmt. Tol. Debit Acc."));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Sales Pmt. Tol. Credit Acc."));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Purch. Pmt. Tol. Debit Acc."));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Purch. Pmt. Tol. Credit Acc."));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Sales Prepayments Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Purch. Prepayments Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Purch. FA Disc. Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Invt. Accrual Acc. (Interim)"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("COGS Account (Interim)"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Direct Cost Applied Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Overhead Applied Account"));
        SuggestAccount2(RecRef, GenPostingSetup."Gen. Bus. Posting Group", GenPostingSetup."Gen. Prod. Posting Group", GenPostingSetup.FieldNo("Purchase Variance Account"));
        TestGenPostingSetup := GenPostingSetup;
        GenPostingSetup.Init();
        GenPostingSetup.SuggestSetupAccounts();
        GenPostingSetup.Modify();
        // Verify
        Assert.AreEqual(
          GenPostingSetup."Sales Account", TestGenPostingSetup."Sales Account", 'Sales Accountccounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Line Disc. Account", TestGenPostingSetup."Sales Line Disc. Account",
          'Sales Line Disc. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Inv. Disc. Account", TestGenPostingSetup."Sales Inv. Disc. Account",
          'Sales Inv. Disc. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Pmt. Disc. Debit Acc.", TestGenPostingSetup."Sales Pmt. Disc. Debit Acc.",
          'Sales Pmt. Disc. Debit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Account", TestGenPostingSetup."Purch. Account", 'Purch. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Line Disc. Account", TestGenPostingSetup."Purch. Line Disc. Account",
          'Purch. Line Disc. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Inv. Disc. Account", TestGenPostingSetup."Purch. Inv. Disc. Account",
          'Purch. Inv. Disc. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Pmt. Disc. Credit Acc.", TestGenPostingSetup."Purch. Pmt. Disc. Credit Acc.",
          'Purch. Pmt. Disc. Credit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."COGS Account", TestGenPostingSetup."COGS Account", 'COGS Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Inventory Adjmt. Account", TestGenPostingSetup."Inventory Adjmt. Account",
          'Inventory Adjmt. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Credit Memo Account", TestGenPostingSetup."Sales Credit Memo Account",
          'Sales Credit Memo Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Credit Memo Account", TestGenPostingSetup."Purch. Credit Memo Account",
          'Purch. Credit Memo Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Pmt. Tol. Debit Acc.", TestGenPostingSetup."Sales Pmt. Tol. Debit Acc.",
          'Sales Pmt. Tol. Debit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Pmt. Tol. Credit Acc.", TestGenPostingSetup."Sales Pmt. Tol. Credit Acc.",
          'Sales Pmt. Tol. Credit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Pmt. Tol. Debit Acc.", TestGenPostingSetup."Purch. Pmt. Tol. Debit Acc.",
          'Purch. Pmt. Tol. Debit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Pmt. Tol. Credit Acc.", TestGenPostingSetup."Purch. Pmt. Tol. Credit Acc.",
          'Purch. Pmt. Tol. Credit Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Sales Prepayments Account", TestGenPostingSetup."Sales Prepayments Account",
          'Sales Prepayments Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. Prepayments Account", TestGenPostingSetup."Purch. Prepayments Account",
          'Purch. Prepayments Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purch. FA Disc. Account", TestGenPostingSetup."Purch. FA Disc. Account",
          'Purch. FA Disc. Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Invt. Accrual Acc. (Interim)", TestGenPostingSetup."Invt. Accrual Acc. (Interim)",
          'Invt. Accrual Accounts (Interim) are not equal');
        Assert.AreEqual(
          GenPostingSetup."COGS Account (Interim)", TestGenPostingSetup."COGS Account (Interim)",
          'COGS Accounts (Interim) are not equal');
        Assert.AreEqual(
          GenPostingSetup."Direct Cost Applied Account", TestGenPostingSetup."Direct Cost Applied Account",
          'Direct Cost Applied Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Overhead Applied Account", TestGenPostingSetup."Overhead Applied Account",
          'Overhead Applied Accounts are not equal');
        Assert.AreEqual(
          GenPostingSetup."Purchase Variance Account", TestGenPostingSetup."Purchase Variance Account",
          'Purchase Variance Accounts are not equal');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure CheckVATPostingSetupSuggestAccounts()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        TestVATPostingSetup: Record "VAT Posting Setup";
        RecRef: RecordRef;
    begin
        Initialize();

        // Execute
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        RecRef.GetTable(VATPostingSetup);
        SuggestAccount2(RecRef, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup.FieldNo("Sales VAT Account"));
        SuggestAccount2(RecRef, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup.FieldNo("Sales VAT Unreal. Account"));
        SuggestAccount2(RecRef, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup.FieldNo("Purchase VAT Account"));
        SuggestAccount2(RecRef, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup.FieldNo("Purch. VAT Unreal. Account"));
        SuggestAccount2(RecRef, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup.FieldNo("Reverse Chrg. VAT Acc."));
        SuggestAccount2(RecRef, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup.FieldNo("Reverse Chrg. VAT Unreal. Acc."));
        TestVATPostingSetup := VATPostingSetup;
        VATPostingSetup.Init();
        VATPostingSetup.SuggestSetupAccounts();
        VATPostingSetup.Modify();
        // Verify
        Assert.AreEqual(
          VATPostingSetup."Sales VAT Account", TestVATPostingSetup."Sales VAT Account",
          'Sales VAT Accounts are not equal');
        Assert.AreEqual(
          VATPostingSetup."Sales VAT Unreal. Account", TestVATPostingSetup."Sales VAT Unreal. Account",
          'Sales VAT Unreal. Accounts are not equal');
        Assert.AreEqual(
          VATPostingSetup."Purchase VAT Account", TestVATPostingSetup."Purchase VAT Account",
          'Purchase VAT Accounts are not equal');
        Assert.AreEqual(
          VATPostingSetup."Purch. VAT Unreal. Account", TestVATPostingSetup."Purch. VAT Unreal. Account",
          'Purch. VAT Unreal. Accounts are not equal');
        Assert.AreEqual(
          VATPostingSetup."Reverse Chrg. VAT Acc.", TestVATPostingSetup."Reverse Chrg. VAT Acc.",
          'Reverse Chrg. VAT Accounts are not equal');
        Assert.AreEqual(
          VATPostingSetup."Reverse Chrg. VAT Unreal. Acc.", TestVATPostingSetup."Reverse Chrg. VAT Unreal. Acc.",
          'Reverse Chrg. VAT Unreal. Accounts are not equal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCurrencySuggestAccounts()
    var
        Currency: Record Currency;
        TestCurrency: Record Currency;
        RecRef: RecordRef;
    begin
        Initialize();

        // Execute
        LibraryERM.CreateCurrency(Currency);
        RecRef.GetTable(Currency);
        SuggestAccount(RecRef, Currency.Code, Currency.FieldNo("Unrealized Gains Acc."));
        SuggestAccount(RecRef, Currency.Code, Currency.FieldNo("Realized Gains Acc."));
        SuggestAccount(RecRef, Currency.Code, Currency.FieldNo("Unrealized Losses Acc."));
        SuggestAccount(RecRef, Currency.Code, Currency.FieldNo("Realized Losses Acc."));
        SuggestAccount(RecRef, Currency.Code, Currency.FieldNo("Realized G/L Gains Account"));
        SuggestAccount(RecRef, Currency.Code, Currency.FieldNo("Realized G/L Losses Account"));
        SuggestAccount(RecRef, Currency.Code, Currency.FieldNo("Residual Gains Account"));
        SuggestAccount(RecRef, Currency.Code, Currency.FieldNo("Residual Losses Account"));
        SuggestAccount(RecRef, Currency.Code, Currency.FieldNo("Conv. LCY Rndg. Debit Acc."));
        SuggestAccount(RecRef, Currency.Code, Currency.FieldNo("Conv. LCY Rndg. Credit Acc."));
        TestCurrency := Currency;
        Currency.Init();
        Currency.SuggestSetupAccounts();
        Currency.Modify();
        // Verify
        Assert.AreEqual(
          Currency."Unrealized Gains Acc.", TestCurrency."Unrealized Gains Acc.", 'Unrealized Gains Accounts are not equal');
        Assert.AreEqual(
          Currency."Realized Gains Acc.", TestCurrency."Realized Gains Acc.", 'Realized Gains Accounts are not equal');
        Assert.AreEqual(
          Currency."Unrealized Losses Acc.", TestCurrency."Unrealized Losses Acc.", 'Unrealized Losses Accounts are not equal');
        Assert.AreEqual(
          Currency."Realized Losses Acc.", TestCurrency."Realized Losses Acc.", 'Realized Losses Accounts are not equal');
        Assert.AreEqual(
          Currency."Realized G/L Gains Account", TestCurrency."Realized G/L Gains Account", 'Realized G/L Gains Accounts are not equal');
        Assert.AreEqual(
          Currency."Realized G/L Losses Account", TestCurrency."Realized G/L Losses Account", 'Realized G/L Losses Accounts are not equal');
        Assert.AreEqual(
          Currency."Residual Gains Account", TestCurrency."Residual Gains Account", 'Residual Gains Accounts are not equal');
        Assert.AreEqual(
          Currency."Residual Losses Account", TestCurrency."Residual Losses Account", 'Residual Losses Accounts are not equal');
        Assert.AreEqual(
          Currency."Conv. LCY Rndg. Credit Acc.", TestCurrency."Conv. LCY Rndg. Credit Acc.", 'Conv. LCY Rndg. Credit Accounts are not equal');
        Assert.AreEqual(
          Currency."Conv. LCY Rndg. Debit Acc.", TestCurrency."Conv. LCY Rndg. Debit Acc.", 'Conv. LCY Rndg. Debit Accounts are not equal');
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupReceivablesByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Receivables Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupReceivablesNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Receivables Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupServiceChargeNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Service Charge Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupPaymentDiscDebitByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Disc. Debit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupPaymentDiscDebitNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Disc. Debit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupPaymentDiscCreditByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Disc. Credit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupPaymentDiscCreditNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Disc. Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupInvoiceRoundingByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Invoice Rounding Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupInvoiceRoundingNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Invoice Rounding Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupAdditionalFeeByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Additional Fee Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupAdditionalFeeNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Additional Fee Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupInterestByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Interest Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupInterestNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Interest Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupDebitCurrApplnRndgByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Debit Curr. Appln. Rndg. Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupDebitCurrApplnRndgNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Debit Curr. Appln. Rndg. Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupCreditCurrApplnRndgByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Credit Curr. Appln. Rndg. Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupCreditCurrApplnRndgNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Credit Curr. Appln. Rndg. Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupDebitRoundingByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Disc. Debit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupDebitRoundingNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Disc. Debit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupCreditRoundingByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Disc. Credit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupCreditRoundingNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Disc. Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupPaymentToleranceDebitByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Tolerance Debit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupPaymentToleranceDebitNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Tolerance Debit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupPaymentToleranceCreditByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Tolerance Credit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupPaymentToleranceCreditNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Payment Tolerance Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupAddFeePerLineByAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Add. Fee per Line Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupCustPostingGroupAddFeePerLineNoAccCat()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LookupCustPostingGroupAccount(CustomerPostingGroup.FieldNo("Add. Fee per Line Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupPayablesByAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payables Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupPayablesNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payables Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupServiceChargeNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Service Charge Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupPaymentDiscDebitByAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Disc. Debit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupPaymentDiscDebitNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Disc. Debit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupPaymentDiscCreditByAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Disc. Credit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupPaymentDiscCreditNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Disc. Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupInvoiceRoundingByAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Invoice Rounding Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupInvoiceRoundingNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Invoice Rounding Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupDebitCurrApplnRndgByAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Debit Curr. Appln. Rndg. Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupDebitCurrApplnRndgNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Debit Curr. Appln. Rndg. Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupCreditCurrApplnRndgByAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Credit Curr. Appln. Rndg. Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupCreditCurrApplnRndgNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Credit Curr. Appln. Rndg. Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupDebitRoundingByAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Disc. Debit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupDebitRoundingNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Disc. Debit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupCreditRoundingByAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Disc. Credit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupCreditRoundingNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Disc. Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupPaymentToleranceDebitByAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Tolerance Debit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupPaymentToleranceDebitNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Tolerance Debit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupPaymentToleranceCreditByAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Tolerance Credit Acc."), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupVendPostingGroupPaymentToleranceCreditNoAccCat()
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        LookupVendPostingGroupAccount(VendorPostingGroup.FieldNo("Payment Tolerance Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupInvtPostingSetupInventoryByAccCat()
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        LookupInvtPostingSetupAccount(InventoryPostingSetup.FieldNo("Inventory Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupInvtPostingSetupInventoryNoAccCat()
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        LookupInvtPostingSetupAccount(InventoryPostingSetup.FieldNo("Inventory Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupInvtPostingSetupInventoryInterimByAccCat()
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        LookupInvtPostingSetupAccount(InventoryPostingSetup.FieldNo("Inventory Account (Interim)"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupInvtPostingSetupInventoryInterimNoAccCat()
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        LookupInvtPostingSetupAccount(InventoryPostingSetup.FieldNo("Inventory Account (Interim)"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesByAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesLineDiscByAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Line Disc. Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesLineDiscNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Line Disc. Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesInvDiscByAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesInvDiscNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesPmtDiscDebitNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Pmt. Disc. Debit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesCreditMemoNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Credit Memo Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesPmtDiscCreditNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Pmt. Disc. Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesPmtTolDebiNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Pmt. Tol. Debit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesPmtTolCreditNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Pmt. Tol. Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupSalesPrepaymentsNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Sales Prepayments Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchByAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchLineDiscByAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchLineDiscNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchInvDiscByAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchInvDiscNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchPmtDiscDebitNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Pmt. Disc. Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchCreditMemoNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Credit Memo Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchPmtDiscCreditNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Pmt. Disc. Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchPmtTolDebiNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Pmt. Tol. Debit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchPmtTolCreditNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Pmt. Tol. Credit Acc."), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchPrepaymentsNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. Prepayments Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchFADiscNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purch. FA Disc. Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupCOGSByAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("COGS Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupCOGSNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("COGS Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupInventoryAdjmtByAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Inventory Adjmt. Account"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupInventoryAdjmtNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Inventory Adjmt. Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupInvtAccrualInterimByAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Invt. Accrual Acc. (Interim)"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupInvtAccrualInterimNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Invt. Accrual Acc. (Interim)"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupWithAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupCOGSInterimByAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("COGS Account (Interim)"), false);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupCOGSInterimNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("COGS Account (Interim)"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupDirectCostAppliedNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Direct Cost Applied Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupOverheadAppliedNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Overhead Applied Account"), true);
    end;

    [Test]
    [HandlerFunctions('GLAccountLookupNoAccCatHandler')]
    [Scope('OnPrem')]
    procedure LookupGenPostingSetupPurchVarianceNoAccCat()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LookupGenPostingSetupAccount(GeneralPostingSetup.FieldNo("Purchase Variance Account"), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGLAccountInvoiceByGenJnlWithoutGenProdPostingGroupForAdjustVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [FEATURE] [G/L Account] [Invoice] [Payment Discount]
        // [SCENARIO 307158] G/L Account Invoice can mistakenly be posted with empty "Gen. Prod. Posting Group".
        Initialize();

        // [GIVEN] Created a VAT Posting Setup with "Adjust for Payment Discount"=TRUE
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Tolerance %", 0);
        GeneralLedgerSetup.Modify(true);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(false);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        // [GIVEN] Created a Gen Journal Line Invoice for G/L Account
        CreateGenJnlLineWithAccountVATPostingSetup(GenJournalLine, VATPostingSetup, GenJournalLine."Document Type"::Invoice);

        // [GIVEN] Set an empty "Gen. Prod. Posting Group" for the Gen Journal Line
        GenJournalLine."Gen. Prod. Posting Group" := '';
        GenJournalLine.Modify(true);

        // [WHEN] Post the Gen Journal Line
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The error is thrown: 'Gen. Prod. Posting Group must have a value in Gen. Journal Line'
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Gen. Prod. Posting Group"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBalGLAccountInvoiceByGenJnlWithoutGenProdPostingGroupForAdjustVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [FEATURE] [G/L Account] [Invoice] [Payment Discount]
        // [SCENARIO 307158] G/L Account Invoice can mistakenly be posted with empty "Bal. Gen. Prod. Posting Group".
        Initialize();

        // [GIVEN] Created a VAT Posting Setup with "Adjust for Payment Discount"=TRUE
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Tolerance %", 0);
        GeneralLedgerSetup.Modify(true);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(false);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        // [GIVEN] Created a Gen Journal Line Invoice for G/L Account
        CreateGenJnlLineWithBalAccountVATPostingSetup(GenJournalLine, VATPostingSetup, GenJournalLine."Document Type"::Invoice);

        // [GIVEN] Set an empty "Bal. Gen. Prod. Posting Group" for the Gen Journal Line
        GenJournalLine."Bal. Gen. Prod. Posting Group" := '';
        GenJournalLine.Modify(true);

        // [WHEN] Post the Gen Journal Line
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The error is thrown: 'Bal. Gen. Prod. Posting Group must have a value in Gen. Journal Line'

        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Bal. Gen. Prod. Posting Group"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostGLAccountCreditMemoByGenJnlWithoutGenProdPostingGroupForAdjustVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [FEATURE] [G/L Account] [Credit Memo] [Payment Discount]
        // [SCENARIO 320325] G/L Account Credit Memo cannot be posted with an empty "Gen. Prod. Posting Group"
        Initialize();

        // [GIVEN] Created a VAT Posting Setup with "Adjust for Payment Discount"=TRUE
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Tolerance %", 0);
        GeneralLedgerSetup.Modify(true);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(false);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        // [GIVEN] Created a Gen Journal Line Credit Memo for G/L Account
        CreateGenJnlLineWithAccountVATPostingSetup(GenJournalLine, VATPostingSetup, GenJournalLine."Document Type"::"Credit Memo");

        // [GIVEN] Set an empty "Gen. Prod. Posting Group" for the Gen Journal Line
        GenJournalLine."Gen. Prod. Posting Group" := '';
        GenJournalLine.Modify(true);

        // [WHEN] Post the Gen Journal Line
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The error is thrown: 'Gen. Prod. Posting Group must have a value in Gen. Journal Line'
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Gen. Prod. Posting Group"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostBalGLAccountCreditMemoByGenJnlWithoutGenProdPostingGroupForAdjustVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [FEATURE] [G/L Account] [Credit Memo] [Payment Discount]
        // [SCENARIO 320325] G/L Account Credit Memo cannot be posted with an empty "Bal. Gen. Prod. Posting Group".
        Initialize();

        // [GIVEN] Created a VAT Posting Setup with "Adjust for Payment Discount"=TRUE
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Tolerance %", 0);
        GeneralLedgerSetup.Modify(true);
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(false);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        // [GIVEN] Created a Gen Journal Line Credit Memo for G/L Account
        CreateGenJnlLineWithBalAccountVATPostingSetup(GenJournalLine, VATPostingSetup, GenJournalLine."Document Type"::"Credit Memo");

        // [GIVEN] Set an empty "Bal. Gen. Prod. Posting Group" for the Gen Journal Line
        GenJournalLine."Bal. Gen. Prod. Posting Group" := '';
        GenJournalLine.Modify(true);

        // [WHEN] Post the Gen Journal Line
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The error is thrown: 'Bal. Gen. Prod. Posting Group must have a value in Gen. Journal Line'
        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Bal. Gen. Prod. Posting Group"), '');
    end;

    local procedure Initialize()
    begin
        // Lazy Setup.
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        Commit();
    end;

    local procedure CreateGenJnlLineWithAccountVATPostingSetup(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; GenJournalLineType: Enum "Gen. Journal Document Type")
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.FindBankAccount(BankAccount);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
        GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLineType,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandDec(10, 2));
        GenJournalLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJnlLineWithBalAccountVATPostingSetup(var GenJournalLine: Record "Gen. Journal Line"; VATPostingSetup: Record "VAT Posting Setup"; GenJournalLineType: Enum "Gen. Journal Document Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        GenJournalBatch.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
        GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLineType,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandDec(10, 2));
        GenJournalLine.Validate("Bal. VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GenJournalLine.Validate("Bal. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGLAccountNo(GenProdGroup: Boolean; DirectPosting: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        if GenProdGroup then begin
            LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
            GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        end;
        if DirectPosting then
            GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

    local procedure CreateCustomerPostingGroup(var CustomerPostingGroup: Record "Customer Posting Group"; ViewAllAccounts: Boolean)
    begin
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Receivables Account" := CreateGLAccountNo(false, false);
        CustomerPostingGroup."Service Charge Acc." := CreateGLAccountNo(true, true);
        CustomerPostingGroup."Payment Disc. Debit Acc." := CreateGLAccountNo(false, false);
        CustomerPostingGroup."Payment Disc. Credit Acc." := CreateGLAccountNo(false, false);
        CustomerPostingGroup."Invoice Rounding Account" := CreateGLAccountNo(true, false);
        CustomerPostingGroup."Additional Fee Account" := CreateGLAccountNo(true, true);
        CustomerPostingGroup."Interest Account" := CreateGLAccountNo(true, false);
        CustomerPostingGroup."Debit Curr. Appln. Rndg. Acc." := CreateGLAccountNo(false, false);
        CustomerPostingGroup."Credit Curr. Appln. Rndg. Acc." := CreateGLAccountNo(false, false);
        CustomerPostingGroup."Debit Rounding Account" := CreateGLAccountNo(false, false);
        CustomerPostingGroup."Credit Rounding Account" := CreateGLAccountNo(false, false);
        CustomerPostingGroup."Payment Tolerance Debit Acc." := CreateGLAccountNo(false, false);
        CustomerPostingGroup."Payment Tolerance Credit Acc." := CreateGLAccountNo(false, false);
        CustomerPostingGroup."Add. Fee per Line Account" := CreateGLAccountNo(true, false);
        CustomerPostingGroup."View All Accounts on Lookup" := ViewAllAccounts;
        CustomerPostingGroup.Modify();
    end;

    local procedure CreateVendorPostingGroup(var VendorPostingGroup: Record "Vendor Posting Group"; ViewAllAccounts: Boolean)
    begin
        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        VendorPostingGroup."Payables Account" := CreateGLAccountNo(false, false);
        VendorPostingGroup."Service Charge Acc." := CreateGLAccountNo(true, true);
        VendorPostingGroup."Payment Disc. Debit Acc." := CreateGLAccountNo(false, false);
        VendorPostingGroup."Payment Disc. Credit Acc." := CreateGLAccountNo(false, false);
        VendorPostingGroup."Invoice Rounding Account" := CreateGLAccountNo(true, false);
        VendorPostingGroup."Debit Curr. Appln. Rndg. Acc." := CreateGLAccountNo(false, false);
        VendorPostingGroup."Credit Curr. Appln. Rndg. Acc." := CreateGLAccountNo(false, false);
        VendorPostingGroup."Debit Rounding Account" := CreateGLAccountNo(false, false);
        VendorPostingGroup."Credit Rounding Account" := CreateGLAccountNo(false, false);
        VendorPostingGroup."Payment Tolerance Debit Acc." := CreateGLAccountNo(false, false);
        VendorPostingGroup."Payment Tolerance Credit Acc." := CreateGLAccountNo(false, false);
        VendorPostingGroup."View All Accounts on Lookup" := ViewAllAccounts;
        VendorPostingGroup.Modify();
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; ViewAllAccounts: Boolean)
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesPmtDiscAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchPmtDiscAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupInvtAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        UpdateGenProdPostingGroupOnGLAccount(GeneralPostingSetup."Sales Prepayments Account");
        UpdateGenProdPostingGroupOnGLAccount(GeneralPostingSetup."Purch. Prepayments Account");
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        GeneralPostingSetup."Purch. FA Disc. Account" := LibraryERM.CreateGLAccountNo();
        GeneralPostingSetup."View All Accounts on Lookup" := ViewAllAccounts;
        GeneralPostingSetup.Modify();
    end;

    local procedure UpdateGenProdPostingGroupOnGLAccount(GLAccontNo: Code[20])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GLAccount.Get(GLAccontNo);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Modify(true);
    end;

    local procedure CreateInventoryPostingSetup(var InventoryPostingSetup: Record "Inventory Posting Setup"; ViewAllAccounts: Boolean)
    var
        Location: Record Location;
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        LibraryWarehouse.CreateLocation(Location);
        if not InventoryPostingSetup.FindFirst() then
            LibraryInventory.CreateInventoryPostingSetup(
              InventoryPostingSetup, Location.Code, InventoryPostingSetup."Invt. Posting Group Code")
        else begin
            LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
            LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, InventoryPostingGroup.Code);
        end;
        InventoryPostingSetup."Inventory Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup."Inventory Account (Interim)" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup."WIP Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup."Material Variance Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup."Capacity Variance Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup."Mfg. Overhead Variance Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup."Cap. Overhead Variance Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup."Subcontracted Variance Account" := LibraryERM.CreateGLAccountNo();
        InventoryPostingSetup."View All Accounts on Lookup" := ViewAllAccounts;
        InventoryPostingSetup.Modify();
    end;

    local procedure LookupCustPostingGroupAccount(LookupFieldNo: Integer; ViewAllAccounts: Boolean)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerPostingGroupsPage: TestPage "Customer Posting Groups";
        GLAccountList: TestPage "G/L Account List";
    begin
        Initialize();
        CreateCustomerPostingGroup(CustomerPostingGroup, ViewAllAccounts);

        CustomerPostingGroupsPage.OpenEdit();
        CustomerPostingGroupsPage.GotoRecord(CustomerPostingGroup);
        GLAccountList.Trap();
        case LookupFieldNo of
            CustomerPostingGroup.FieldNo("Receivables Account"):
                CustomerPostingGroupsPage."Receivables Account".Lookup();
            CustomerPostingGroup.FieldNo("Service Charge Acc."):
                CustomerPostingGroupsPage."Service Charge Acc.".Lookup();
            CustomerPostingGroup.FieldNo("Payment Disc. Debit Acc."):
                CustomerPostingGroupsPage."Payment Disc. Debit Acc.".Lookup();
            CustomerPostingGroup.FieldNo("Payment Disc. Credit Acc."):
                CustomerPostingGroupsPage."Payment Disc. Credit Acc.".Lookup();
            CustomerPostingGroup.FieldNo("Debit Curr. Appln. Rndg. Acc."):
                CustomerPostingGroupsPage."Debit Curr. Appln. Rndg. Acc.".Lookup();
            CustomerPostingGroup.FieldNo("Credit Curr. Appln. Rndg. Acc."):
                CustomerPostingGroupsPage."Credit Curr. Appln. Rndg. Acc.".Lookup();
            CustomerPostingGroup.FieldNo("Payment Tolerance Debit Acc."):
                CustomerPostingGroupsPage."Payment Tolerance Debit Acc.".Lookup();
            CustomerPostingGroup.FieldNo("Payment Tolerance Credit Acc."):
                CustomerPostingGroupsPage."Payment Tolerance Credit Acc.".Lookup();
            CustomerPostingGroup.FieldNo("Invoice Rounding Account"):
                CustomerPostingGroupsPage."Invoice Rounding Account".Lookup();
            CustomerPostingGroup.FieldNo("Debit Rounding Account"):
                CustomerPostingGroupsPage."Debit Rounding Account".Lookup();
            CustomerPostingGroup.FieldNo("Credit Rounding Account"):
                CustomerPostingGroupsPage."Credit Rounding Account".Lookup();
            CustomerPostingGroup.FieldNo("Additional Fee Account"):
                CustomerPostingGroupsPage."Additional Fee Account".Lookup();
            CustomerPostingGroup.FieldNo("Add. Fee per Line Account"):
                CustomerPostingGroupsPage."Add. Fee per Line Account".Lookup();
            CustomerPostingGroup.FieldNo("Interest Account"):
                CustomerPostingGroupsPage."Interest Account".Lookup();
        end;
    end;

    local procedure LookupVendPostingGroupAccount(LookupFieldNo: Integer; ViewAllAccounts: Boolean)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorPostingGroupsPage: TestPage "Vendor Posting Groups";
        GLAccountList: TestPage "G/L Account List";
    begin
        Initialize();
        CreateVendorPostingGroup(VendorPostingGroup, ViewAllAccounts);

        VendorPostingGroupsPage.OpenEdit();
        VendorPostingGroupsPage.GotoRecord(VendorPostingGroup);
        GLAccountList.Trap();
        case LookupFieldNo of
            VendorPostingGroup.FieldNo("Payables Account"):
                VendorPostingGroupsPage."Payables Account".Lookup();
            VendorPostingGroup.FieldNo("Service Charge Acc."):
                VendorPostingGroupsPage."Service Charge Acc.".Lookup();
            VendorPostingGroup.FieldNo("Payment Disc. Debit Acc."):
                VendorPostingGroupsPage."Payment Disc. Debit Acc.".Lookup();
            VendorPostingGroup.FieldNo("Invoice Rounding Account"):
                VendorPostingGroupsPage."Invoice Rounding Account".Lookup();
            VendorPostingGroup.FieldNo("Debit Curr. Appln. Rndg. Acc."):
                VendorPostingGroupsPage."Debit Curr. Appln. Rndg. Acc.".Lookup();
            VendorPostingGroup.FieldNo("Credit Curr. Appln. Rndg. Acc."):
                VendorPostingGroupsPage."Credit Curr. Appln. Rndg. Acc.".Lookup();
            VendorPostingGroup.FieldNo("Debit Rounding Account"):
                VendorPostingGroupsPage."Debit Rounding Account".Lookup();
            VendorPostingGroup.FieldNo("Credit Rounding Account"):
                VendorPostingGroupsPage."Credit Rounding Account".Lookup();
            VendorPostingGroup.FieldNo("Payment Disc. Credit Acc."):
                VendorPostingGroupsPage."Payment Disc. Credit Acc.".Lookup();
            VendorPostingGroup.FieldNo("Payment Tolerance Debit Acc."):
                VendorPostingGroupsPage."Payment Tolerance Debit Acc.".Lookup();
            VendorPostingGroup.FieldNo("Payment Tolerance Credit Acc."):
                VendorPostingGroupsPage."Payment Tolerance Credit Acc.".Lookup();
        end;
    end;

    local procedure LookupInvtPostingSetupAccount(LookupFieldNo: Integer; ViewAllAccounts: Boolean)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        InventoryPostingSetupPage: TestPage "Inventory Posting Setup";
        GLAccountList: TestPage "G/L Account List";
    begin
        Initialize();
        CreateInventoryPostingSetup(InventoryPostingSetup, ViewAllAccounts);

        InventoryPostingSetupPage.OpenEdit();
        InventoryPostingSetupPage.GotoRecord(InventoryPostingSetup);
        GLAccountList.Trap();
        case LookupFieldNo of
            InventoryPostingSetup.FieldNo("Inventory Account"):
                InventoryPostingSetupPage."Inventory Account".Lookup();
            InventoryPostingSetup.FieldNo("Inventory Account (Interim)"):
                InventoryPostingSetupPage."Inventory Account (Interim)".Lookup();
            InventoryPostingSetup.FieldNo("WIP Account"):
                InventoryPostingSetupPage."WIP Account".Lookup();
            InventoryPostingSetup.FieldNo("Material Variance Account"):
                InventoryPostingSetupPage."Material Variance Account".Lookup();
            InventoryPostingSetup.FieldNo("Capacity Variance Account"):
                InventoryPostingSetupPage."Capacity Variance Account".Lookup();
            InventoryPostingSetup.FieldNo("Mfg. Overhead Variance Account"):
                InventoryPostingSetupPage."Mfg. Overhead Variance Account".Lookup();
            InventoryPostingSetup.FieldNo("Cap. Overhead Variance Account"):
                InventoryPostingSetupPage."Cap. Overhead Variance Account".Lookup();
            InventoryPostingSetup.FieldNo("Subcontracted Variance Account"):
                InventoryPostingSetupPage."Subcontracted Variance Account".Lookup();
        end;
    end;

    local procedure LookupGenPostingSetupAccount(LookupFieldNo: Integer; ViewAllAccounts: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetupPage: TestPage "General Posting Setup";
        GLAccountList: TestPage "G/L Account List";
    begin
        Initialize();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Adjust for Payment Disc." := true;
        GeneralLedgerSetup.Modify();

        CreateGeneralPostingSetup(GeneralPostingSetup, ViewAllAccounts);

        GeneralPostingSetupPage.OpenEdit();
        GeneralPostingSetupPage.GotoRecord(GeneralPostingSetup);
        GLAccountList.Trap();
        case LookupFieldNo of
            // Sales
            GeneralPostingSetup.FieldNo("Sales Account"):
                GeneralPostingSetupPage."Sales Account".Lookup();
            GeneralPostingSetup.FieldNo("Sales Line Disc. Account"):
                GeneralPostingSetupPage."Sales Line Disc. Account".Lookup();
            GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"):
                GeneralPostingSetupPage."Sales Inv. Disc. Account".Lookup();
            GeneralPostingSetup.FieldNo("Sales Pmt. Disc. Debit Acc."):
                GeneralPostingSetupPage."Sales Pmt. Disc. Debit Acc.".Lookup();
            GeneralPostingSetup.FieldNo("Sales Credit Memo Account"):
                GeneralPostingSetupPage."Sales Credit Memo Account".Lookup();
            GeneralPostingSetup.FieldNo("Sales Pmt. Disc. Credit Acc."):
                GeneralPostingSetupPage."Sales Pmt. Disc. Credit Acc.".Lookup();
            GeneralPostingSetup.FieldNo("Sales Pmt. Tol. Debit Acc."):
                GeneralPostingSetupPage."Sales Pmt. Tol. Debit Acc.".Lookup();
            GeneralPostingSetup.FieldNo("Sales Pmt. Tol. Credit Acc."):
                GeneralPostingSetupPage."Sales Pmt. Tol. Credit Acc.".Lookup();
            GeneralPostingSetup.FieldNo("Sales Prepayments Account"):
                GeneralPostingSetupPage."Sales Prepayments Account".Lookup();
            // Purchases
            GeneralPostingSetup.FieldNo("Purch. Account"):
                GeneralPostingSetupPage."Purch. Account".Lookup();
            GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"):
                GeneralPostingSetupPage."Purch. Line Disc. Account".Lookup();
            GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"):
                GeneralPostingSetupPage."Purch. Inv. Disc. Account".Lookup();
            GeneralPostingSetup.FieldNo("Purch. Pmt. Disc. Credit Acc."):
                GeneralPostingSetupPage."Purch. Pmt. Disc. Credit Acc.".Lookup();
            GeneralPostingSetup.FieldNo("Purch. Credit Memo Account"):
                GeneralPostingSetupPage."Purch. Credit Memo Account".Lookup();
            GeneralPostingSetup.FieldNo("Purch. Pmt. Disc. Debit Acc."):
                GeneralPostingSetupPage."Purch. Pmt. Disc. Debit Acc.".Lookup();
            GeneralPostingSetup.FieldNo("Purch. Pmt. Tol. Debit Acc."):
                GeneralPostingSetupPage."Purch. Pmt. Tol. Debit Acc.".Lookup();
            GeneralPostingSetup.FieldNo("Purch. Pmt. Tol. Credit Acc."):
                GeneralPostingSetupPage."Purch. Pmt. Tol. Credit Acc.".Lookup();
            GeneralPostingSetup.FieldNo("Purch. Prepayments Account"):
                GeneralPostingSetupPage."Purch. Prepayments Account".Lookup();
            GeneralPostingSetup.FieldNo("Purch. FA Disc. Account"):
                GeneralPostingSetupPage."Purch. FA Disc. Account".Lookup();
            // Inventory
            GeneralPostingSetup.FieldNo("COGS Account"):
                GeneralPostingSetupPage."COGS Account".Lookup();
            GeneralPostingSetup.FieldNo("Inventory Adjmt. Account"):
                GeneralPostingSetupPage."Inventory Adjmt. Account".Lookup();
            GeneralPostingSetup.FieldNo("Invt. Accrual Acc. (Interim)"):
                GeneralPostingSetupPage."Invt. Accrual Acc. (Interim)".Lookup();
            GeneralPostingSetup.FieldNo("COGS Account (Interim)"):
                GeneralPostingSetupPage."COGS Account (Interim)".Lookup();
            // Manufactruring
            GeneralPostingSetup.FieldNo("Direct Cost Applied Account"):
                GeneralPostingSetupPage."Direct Cost Applied Account".Lookup();
            GeneralPostingSetup.FieldNo("Overhead Applied Account"):
                GeneralPostingSetupPage."Overhead Applied Account".Lookup();
            GeneralPostingSetup.FieldNo("Purchase Variance Account"):
                GeneralPostingSetupPage."Purchase Variance Account".Lookup();
        end;
    end;

    local procedure SuggestAccount(var RecRef: RecordRef; "Code": Code[20]; AccountFieldNo: Integer)
    var
        TempAccountUseBuffer: Record "Account Use Buffer" temporary;
        CurrencyRecRef: RecordRef;
        CurrencyFieldRef: FieldRef;
        RecFieldRef: FieldRef;
    begin
        TempAccountUseBuffer.DeleteAll();

        CurrencyRecRef.Open(RecRef.Number);

        CurrencyRecRef.Reset();
        CurrencyFieldRef := CurrencyRecRef.Field(1);
        CurrencyFieldRef.SetFilter('<>%1', Code);
        TempAccountUseBuffer.UpdateBuffer(CurrencyRecRef, AccountFieldNo);

        CurrencyRecRef.Close();

        TempAccountUseBuffer.Reset();
        TempAccountUseBuffer.SetCurrentKey("No. of Use");
        if TempAccountUseBuffer.FindLast() then begin
            RecFieldRef := RecRef.Field(AccountFieldNo);
            RecFieldRef.Value(TempAccountUseBuffer."Account No.");
        end;
    end;

    local procedure SuggestAccount2(var RecRef: RecordRef; Code1: Code[20]; Code2: Code[20]; AccountFieldNo: Integer)
    var
        TempAccountUseBuffer: Record "Account Use Buffer" temporary;
        PostingSetupRecRef: RecordRef;
        PostingSetupFieldRef: FieldRef;
        RecFieldRef: FieldRef;
    begin
        TempAccountUseBuffer.DeleteAll();

        PostingSetupRecRef.Open(RecRef.Number);

        PostingSetupRecRef.Reset();
        PostingSetupFieldRef := PostingSetupRecRef.Field(1);
        PostingSetupFieldRef.SetRange(Code1);
        PostingSetupFieldRef := PostingSetupRecRef.Field(2);
        PostingSetupFieldRef.SetFilter('<>%1', Code2);
        TempAccountUseBuffer.UpdateBuffer(PostingSetupRecRef, AccountFieldNo);

        PostingSetupRecRef.Reset();
        PostingSetupFieldRef := PostingSetupRecRef.Field(1);
        PostingSetupFieldRef.SetFilter('<>%1', Code1);
        PostingSetupFieldRef := PostingSetupRecRef.Field(2);
        PostingSetupFieldRef.SetRange(Code2);
        TempAccountUseBuffer.UpdateBuffer(PostingSetupRecRef, AccountFieldNo);

        PostingSetupRecRef.Close();

        TempAccountUseBuffer.Reset();
        TempAccountUseBuffer.SetCurrentKey("No. of Use");
        if TempAccountUseBuffer.FindLast() then begin
            RecFieldRef := RecRef.Field(AccountFieldNo);
            RecFieldRef.Value(TempAccountUseBuffer."Account No.");
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountLookupWithAccCatHandler(var GLAccountList: TestPage "G/L Account List")
    var
        GLAccountFilter: Text;
    begin
        GLAccountFilter := GLAccountList.FILTER.GetFilter("Account Category");
        Assert.IsFalse(GLAccountFilter = '', 'Account Category filter missing.');
        GLAccountList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GLAccountLookupNoAccCatHandler(var GLAccountList: TestPage "G/L Account List")
    var
        GLAccountFilter: Text;
    begin
        GLAccountFilter := GLAccountList.FILTER.GetFilter("Account Category");
        Assert.IsTrue(GLAccountFilter = '', 'Account Category filter set.');
        GLAccountList.Cancel().Invoke();
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

