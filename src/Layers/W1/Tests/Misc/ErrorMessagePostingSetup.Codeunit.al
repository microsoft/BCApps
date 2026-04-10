codeunit 135007 "Error Message Posting Setup"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Error Message]
    end;

    var
        GlobalGeneralPostingSetup: Record "General Posting Setup";
        GlobalVATPostingSetup: Record "VAT Posting Setup";
        GlobalInventoryPostingSetup: Record "Inventory Posting Setup";
        GlobalCustomerPostingGroup: Record "Customer Posting Group";
        GlobalVendorPostingGroup: Record "Vendor Posting Group";
        GlobalJobPostingGroup: Record "Job Posting Group";
        GlobalFAPostingGroup: Record "FA Posting Group";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryErrorMessage: Codeunit "Library - Error Message";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetupErrMgtNotActivated()
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesAccount of General Posting Setup table shows an error if "Sales Account" field is empty and error management is not activated
        Initialize();

        // [GIVEN] General Posting Setup with empty accounts
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [WHEN] GeneralPostingSetup.GetSalesAccount() is being run
        asserterror GeneralPostingSetup.GetSalesAccount();

        // [THEN] Error "Sales Account is missing in General Posting Setup."
        Assert.ExpectedError(
            LibraryErrorMessage.GetMissingAccountErrorMessage(
                GeneralPostingSetup.FieldCaption("Sales Account"),
                GeneralPostingSetup));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetSalesAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesAccount of General Posting Setup table logs an error if "Sales Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Sales Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetSalesLineDiscountAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesLineDiscountAccount of General Posting Setup table logs an error if "Sales Line Disc. Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Sales Line Disc. Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetSalesInvDiscountAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesInvDiscountAccount of General Posting Setup table logs an error if "Sales Inv. Disc. Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetSalesCreditMemoAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesCreditMemoAccount of General Posting Setup table logs an error if "Sales Credit Memo Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Sales Credit Memo Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetInvtAccrualAccInterim()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetInvtAccrualAccInterim of General Posting Setup table logs an error if "Invt. Accrual Acc. (Interim)" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Invt. Accrual Acc. (Interim)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetInventoryAdjmtAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetInventoryAdjmtAccount of General Posting Setup table logs an error if "Inventory Adjmt. Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Inventory Adjmt. Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetCOGSAccountInterim()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCOGSAccountInterim of General Posting Setup table logs an error if "COGS Account (Interim)" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("COGS Account (Interim)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetCOGSAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCOGSAccount of General Posting Setup table logs an error if "COGS Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("COGS Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetSalesPrepaymentsAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesPrepaymentsAccount of General Posting Setup table logs an error if "Sales Prepayments Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Sales Prepayments Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetSalesPmtDiscountAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesPmtDiscountAccount of General Posting Setup table logs an error if "Sales Pmt. Disc. Debit Acc." field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Sales Pmt. Disc. Debit Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetSalesPmtDiscountAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesPmtDiscountAccount of General Posting Setup table logs an error if "Sales Pmt. Disc. Credit Acc." field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Sales Pmt. Disc. Credit Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetSalesPmtToleranceAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesPmtToleranceAccount of General Posting Setup table logs an error if "Sales Pmt. Tol. Debit Acc." field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Sales Pmt. Tol. Debit Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetSalesPmtToleranceAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesPmtToleranceAccount of General Posting Setup table logs an error if "Sales Pmt. Tol. Credit Acc." field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Sales Pmt. Tol. Credit Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchAccount of General Posting Setup table logs an error if "Purch. Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purch. Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchCreditMemoAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchCrMemoAccount of General Posting Setup table logs an error if "Purch. Credit Memo Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purch. Credit Memo Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchInvDiscAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchInvDiscAccount of General Posting Setup table logs an error if "Purch. Inv. Disc. Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchLineDiscAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchLineDiscAccount of General Posting Setup table logs an error if "Purch. Line Disc. Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purch. Line Disc. Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchPmtDiscountAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchPmtDiscountAccount of General Posting Setup table logs an error if "Purch. Pmt. Disc. Debit Acc." field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purch. Pmt. Disc. Debit Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchPmtDiscountAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchPmtDiscountAccount of General Posting Setup table logs an error if "Purch. Pmt. Disc. Credit Acc." field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purch. Pmt. Disc. Credit Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchPmtToleranceAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchPmtToleranceAccount of General Posting Setup table logs an error if "Purch. Pmt. Tol. Debit Acc.") field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purch. Pmt. Tol. Debit Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchPmtToleranceAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchPmtToleranceAccount of General Posting Setup table logs an error if "Purch. Pmt. Tol. Credit Acc." field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purch. Pmt. Tol. Credit Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchPrepaymentsAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchPrepmtAccount of General Posting Setup table logs an error if "Purch. Prepayments Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purch. Prepayments Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchFADiscAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchFADiscAccount of General Posting Setup table logs an error if "Purch. FA Disc. Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purch. FA Disc. Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetDirectCostAppliedAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetDirectCostAppliedAccount of General Posting Setup table logs an error if "Direct Cost Applied Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Direct Cost Applied Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetOverheadAppliedAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetOverheadAppliedAccount of General Posting Setup table logs an error if "Overhead Applied Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Overhead Applied Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralPostingSetup_GetPurchaseVarianceAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchaseVarianceAccount of General Posting Setup table logs an error if "Purchase Variance Account" field is empty
        GeneralPostingSetupScenario(GlobalGeneralPostingSetup.FieldNo("Purchase Variance Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetup_GetSalesAccountUnrealizedTrue()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesAccount of VAT Posting Setup table logs an error if "Sales VAT Unreal. Account") field is empty
        VATPostingSetupScenario(GlobalVATPostingSetup.FieldNo("Sales VAT Unreal. Account"), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetup_GetSalesAccountUnrealizedFalse()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesAccount of VAT Posting Setup table logs an error if "Sales VAT Account" field is empty
        VATPostingSetupScenario(GlobalVATPostingSetup.FieldNo("Sales VAT Account"), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetup_GetPurchAccountUnrealizedTrue()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchAccount of VAT Posting Setup table logs an error if "Purch. VAT Unreal. Account") field is empty
        VATPostingSetupScenario(GlobalVATPostingSetup.FieldNo("Purch. VAT Unreal. Account"), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetup_GetPurchAccountUnrealizedFalse()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPurchAccount of VAT Posting Setup table logs an error if "Purchase VAT Account" field is empty
        VATPostingSetupScenario(GlobalVATPostingSetup.FieldNo("Purchase VAT Account"), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetup_GetRevChargeAccountUnrealizedTrue()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetRevChargeAccount of VAT Posting Setup table logs an error if "Reverse Chrg. VAT Unreal. Acc.") field is empty
        VATPostingSetupScenario(GlobalVATPostingSetup.FieldNo("Reverse Chrg. VAT Unreal. Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingSetup_GetRevChargeAccountUnrealizedFalse()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetRevChargeAccount of VAT Posting Setup table logs an error if ""Reverse Chrg. VAT Acc." field is empty
        VATPostingSetupScenario(GlobalVATPostingSetup.FieldNo("Reverse Chrg. VAT Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPostingSetup_GetCapacityVarianceAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCapacityVarianceAccount of Inventory Posting Setup table logs an error if "Capacity Variance Account" field is empty
        InventoryPostingSetupScenario(GlobalInventoryPostingSetup.FieldNo("Capacity Variance Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPostingSetup_GetCapOverheadVarianceAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCapOverheadVarianceAccount of Inventory Posting Setup table logs an error if "Cap. Overhead Variance Account" field is empty
        InventoryPostingSetupScenario(GlobalInventoryPostingSetup.FieldNo("Cap. Overhead Variance Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPostingSetup_GetInventoryAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetInventoryAccount of Inventory Posting Setup table logs an error if "Inventory Account" field is empty
        InventoryPostingSetupScenario(GlobalInventoryPostingSetup.FieldNo("Inventory Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPostingSetup_GetInventoryAccountInterim()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetInventoryAccountInterim of Inventory Posting Setup table logs an error if "Inventory Account (Interim)" field is empty
        InventoryPostingSetupScenario(GlobalInventoryPostingSetup.FieldNo("Inventory Account (Interim)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPostingSetup_GetMaterialVarianceAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetMaterialVarianceAccount of Inventory Posting Setup table logs an error if "Material Variance Account" field is empty
        InventoryPostingSetupScenario(GlobalInventoryPostingSetup.FieldNo("Material Variance Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPostingSetup_GetMfgOverheadVarianceAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetMfgOverheadVarianceAccount of Inventory Posting Setup table logs an error if "Mfg. Overhead Variance Account" field is empty
        InventoryPostingSetupScenario(GlobalInventoryPostingSetup.FieldNo("Mfg. Overhead Variance Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPostingSetup_GetSubcontractedVarianceAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSubcontractedVarianceAccount of Inventory Posting Setup table logs an error if "Subcontracted Variance Account" field is empty
        InventoryPostingSetupScenario(GlobalInventoryPostingSetup.FieldNo("Subcontracted Variance Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryPostingSetup_GetWIPAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetWIPAccount of Inventory Posting Setup table logs an error if "WIP Account" field is empty
        InventoryPostingSetupScenario(GlobalInventoryPostingSetup.FieldNo("WIP Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetPayablesAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPayablesAccount of Vendor Posting Group table logs an error if "Payables Account" field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Payables Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetPmtDiscountAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPmtDiscountAccount of Vendor Posting Group table logs an error if "Payment Disc. Debit Acc." field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Payment Disc. Debit Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetPmtDiscountAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPmtDiscountAccount of Vendor Posting Group table logs an error if "Payment Disc. Credit Acc." field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Payment Disc. Credit Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetPmtToleranceAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPmtToleranceAccount of Vendor Posting Group table logs an error if "Payment Tolerance Debit Acc." field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Payment Tolerance Debit Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetPmtToleranceAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPmtToleranceAccount of Vendor Posting Group table logs an error if "Payment Tolerance Credit Acc." field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Payment Tolerance Credit Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetRoundingAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetRoundingAccount of Vendor Posting Group table logs an error if "Debit Rounding Account" field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Debit Rounding Account"), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetRoundingAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetRoundingAccount of Vendor Posting Group table logs an error if "Credit Rounding Account" field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Credit Rounding Account"), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetApplRoundingAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetApplRoundingAccount of Vendor Posting Group table logs an error if "Debit Curr. Appln. Rndg. Acc." field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Debit Curr. Appln. Rndg. Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetApplRoundingAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetApplRoundingAccount of Vendor Posting Group table logs an error if "Credit Curr. Appln. Rndg. Acc." field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Credit Curr. Appln. Rndg. Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetInvRoundingAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetInvRoundingAccount of Vendor Posting Group table logs an error if "Invoice Rounding Account" field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Invoice Rounding Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorPostingGroup_GetServiceChargeAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetServiceChargeAccount of Vendor Posting Group table logs an error if "Service Charge Acc." field is empty
        VendorPostingGroupScenario(GlobalVendorPostingGroup.FieldNo("Service Charge Acc."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetReceivablesAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetReceivablesAccount of Customer Posting Group table logs an error if "Receivables Account" field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Receivables Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetPmtDiscountAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPmtDiscountAccount of Customer Posting Group table logs an error if "Payment Disc. Debit Acc." field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Payment Disc. Debit Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetPmtDiscountAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPmtDiscountAccount of Customer Posting Group table logs an error if "Payment Disc. Credit Acc." field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Payment Disc. Credit Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetPmtToleranceAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPmtToleranceAccount of Customer Posting Group table logs an error if "Payment Tolerance Debit Acc." field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Payment Tolerance Debit Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetPmtToleranceAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetPmtToleranceAccount of Customer Posting Group table logs an error if "Payment Tolerance Credit Acc." field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Payment Tolerance Credit Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetRoundingAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetRoundingAccount of Customer Posting Group table logs an error if "Debit Rounding Account" field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Debit Rounding Account"), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetRoundingAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetRoundingAccount of Customer Posting Group table logs an error if "Credit Rounding Account" field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Credit Rounding Account"), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetApplRoundingAccountDebit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetApplRoundingAccount of Customer Posting Group table logs an error if "Debit Curr. Appln. Rndg. Acc." field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Debit Curr. Appln. Rndg. Acc."), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetApplRoundingAccountCredit()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetApplRoundingAccount of Customer Posting Group table logs an error if "Credit Curr. Appln. Rndg. Acc." field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Credit Curr. Appln. Rndg. Acc."), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetInvRoundingAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetInvRoundingAccount of Customer Posting Group table logs an error if "Invoice Rounding Account" field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Invoice Rounding Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetServiceChargeAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetServiceChargeAccount of Customer Posting Group table logs an error if "Service Charge Acc." field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Service Charge Acc."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetAdditionalFeeAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAdditionalFeeAccount of Customer Posting Group table logs an error if "Additional Fee Account" field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Additional Fee Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetAddFeePerLineAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAddFeePerLineAccount of Customer Posting Group table logs an error if "Add. Fee per Line Account" field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Add. Fee per Line Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPostingGroup_GetInterestAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetInterestAccount of Customer Posting Group table logs an error if "Interest Account" field is empty
        CustomerPostingGroupScenario(GlobalCustomerPostingGroup.FieldNo("Interest Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetWIPCostsAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetWIPCostsAccount of Job Posting Group table logs an error if "WIP Costs Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("WIP Costs Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetWIPAccruedCostsAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetWIPAccruedCostsAccount of Job Posting Group table logs an error if "WIP Accrued Costs Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("WIP Accrued Costs Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetWIPAccruedSalesAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetWIPAccruedSalesAccount of Job Posting Group table logs an error if "WIP Accrued Sales Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("WIP Accrued Sales Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetWIPInvoicedSalesAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetWIPInvoicedSalesAccount of Job Posting Group table logs an error if "WIP Invoiced Sales Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("WIP Invoiced Sales Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetJobCostsAppliedAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetJobCostsAppliedAccount of Job Posting Group table logs an error if "Job Costs Applied Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("Job Costs Applied Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetJobCostsAdjustmentAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetJobCostsAdjustmentAccount of Job Posting Group table logs an error if "Job Costs Adjustment Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("Job Costs Adjustment Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetGLExpenseAccountContract()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetGLExpenseAccountContract of Job Posting Group table logs an error if "G/L Expense Acc. (Contract)" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("G/L Expense Acc. (Contract)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetJobSalesAdjustmentAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetJobSalesAdjustmentAccount of Job Posting Group table logs an error if "Job Sales Adjustment Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("Job Sales Adjustment Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetJobSalesAppliedAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetJobSalesAppliedAccount of Job Posting Group table logs an error if "Job Sales Applied Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("Job Sales Applied Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetRecognizedCostsAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetRecognizedCostsAccount of Job Posting Group table logs an error if "Recognized Costs Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("Recognized Costs Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetRecognizedSalesAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetRecognizedSalesAccount of Job Posting Group table logs an error if "Recognized Sales Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("Recognized Sales Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetItemCostsAppliedAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetItemCostsAppliedAccount of Job Posting Group table logs an error if "Item Costs Applied Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("Item Costs Applied Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetResourceCostsAppliedAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetResourceCostsAppliedAccount of Job Posting Group table logs an error if "Resource Costs Applied Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("Resource Costs Applied Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPostingGroup_GetGLCostsAppliedAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetGLCostsAppliedAccount of Job Posting Group table logs an error if "G/L Costs Applied Account" field is empty
        JobPostingGroupScenario(GlobalJobPostingGroup.FieldNo("G/L Costs Applied Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetAcquisitionCostAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAcquisitionCostAccount of FA Posting Group table logs an error if "Acquisition Cost Account" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Acquisition Cost Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetAcquisitionCostAccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAcquisitionCostAccountOnDisposal of FA Posting Group table logs an error if "Acq. Cost Acc. on Disposal" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Acq. Cost Acc. on Disposal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetAcquisitionCostBalanceAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAcquisitionCostBalanceAccount of FA Posting Group table logs an error if "Acquisition Cost Bal. Acc." field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Acquisition Cost Bal. Acc."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetAccumDepreciationAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAccumDepreciationAccount of FA Posting Group table logs an error if "Accum. Depreciation Account" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Accum. Depreciation Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetAccumDepreciationAccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAccumDepreciationAccountOnDisposal of FA Posting Group table logs an error if "Accum. Depr. Acc. on Disposal" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Accum. Depr. Acc. on Disposal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetAppreciationAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAppreciationAccount of FA Posting Group table logs an error if "Appreciation Account" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Appreciation Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetAppreciationAccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAppreciationAccountOnDisposal of FA Posting Group table logs an error if "Appreciation Acc. on Disposal" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Appreciation Acc. on Disposal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetAppreciationBalanceAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAppreciationBalanceAccount of FA Posting Group table logs an error if "Appreciation Bal. Account" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Appreciation Bal. Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetAppreciationBalAccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetAppreciationBalAccountOnDisposal of FA Posting Group table logs an error if "Apprec. Bal. Acc. on Disp." field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Apprec. Bal. Acc. on Disp."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetBookValueAccountOnDisposalGain()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetBookValueAccountOnDisposalGain of FA Posting Group table logs an error if "Book Val. Acc. on Disp. (Gain)" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Book Val. Acc. on Disp. (Gain)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetBookValueAccountOnDisposalLoss()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetBookValueAccountOnDisposalLoss of FA Posting Group table logs an error if "Book Val. Acc. on Disp. (Loss)" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Book Val. Acc. on Disp. (Loss)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetCustom1Account()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCustom1Account of FA Posting Group table logs an error if "Custom 1 Account" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Custom 1 Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetCustom2Account()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCustom2Account of FA Posting Group table logs an error if "Custom 2 Account" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Custom 2 Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetCustom1AccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCustom1AccountOnDisposal of FA Posting Group table logs an error if "Custom 1 Account on Disposal" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Custom 1 Account on Disposal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetCustom2AccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCustom2AccountOnDisposal of FA Posting Group table logs an error if "Custom 2 Account on Disposal" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Custom 2 Account on Disposal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetCustom1BalAccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCustom1BalAccountOnDisposal of FA Posting Group table logs an error if "Custom 1 Bal. Acc. on Disposal" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Custom 1 Bal. Acc. on Disposal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetCustom2BalAccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCustom2BalAccountOnDisposal of FA Posting Group table logs an error if "Custom 2 Bal. Acc. on Disposal" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Custom 2 Bal. Acc. on Disposal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetCustom1ExpenseAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCustom1ExpenseAccount of FA Posting Group table logs an error if "Custom 1 Expense Acc." field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Custom 1 Expense Acc."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetCustom2ExpenseAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetCustom2ExpenseAccount of FA Posting Group table logs an error if "Custom 2 Expense Acc." field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Custom 2 Expense Acc."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetDepreciationExpenseAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetDepreciationExpenseAccount of FA Posting Group table logs an error if "Depreciation Expense Acc." field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Depreciation Expense Acc."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetGainsAccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetGainsAccountOnDisposal of FA Posting Group table logs an error if "Gains Acc. on Disposal" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Gains Acc. on Disposal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetLossesAccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetLossesAccountOnDisposal of FA Posting Group table logs an error if "Losses Acc. on Disposal" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Losses Acc. on Disposal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetMaintenanceExpenseAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetMaintenanceExpenseAccount of FA Posting Group table logs an error if "Maintenance Expense Account" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Maintenance Expense Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetMaintenanceBalanceAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetMaintenanceBalanceAccount of FA Posting Group table logs an error if "Maintenance Bal. Acc." field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Maintenance Bal. Acc."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetSalesBalanceAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesBalanceAccount of FA Posting Group table logs an error if "Sales Bal. Acc." field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Sales Bal. Acc."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetSalesAccountOnDisposalGain()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesAccountOnDisposalGain of FA Posting Group table logs an error if "Sales Acc. on Disp. (Gain)" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Sales Acc. on Disp. (Gain)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetSalesAccountOnDisposalLoss()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetSalesAccountOnDisposalLoss of FA Posting Group table logs an error if "Sales Acc. on Disp. (Loss)" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Sales Acc. on Disp. (Loss)"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetWriteDownAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetWriteDownAccount of FA Posting Group table logs an error if "Write-Down Account" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Write-Down Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetWriteDownAccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetWriteDownAccountOnDisposal of FA Posting Group table logs an error if "Write-Down Acc. on Disposal" field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Write-Down Acc. on Disposal"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetWriteDownBalAccountOnDisposal()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetWriteDownBalAccountOnDisposal of FA Posting Group table logs an error if "Write-Down Bal. Acc. on Disp." field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Write-Down Bal. Acc. on Disp."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPostingGroup_GetWriteDownExpenseAccount()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391482] Function GetWriteDownExpenseAccount of FA Posting Group table logs an error if "Write-Down Expense Acc." field is empty
        FAPostingGroupScenario(GlobalFAPostingGroup.FieldNo("Write-Down Expense Acc."));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Error Message Posting Setup");
    end;

    local procedure GeneralPostingSetupScenario(FieldNo: Integer)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        Initialize();

        // [GIVEN] General Posting Setup with empty accounts
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Function GetXXXAccount of General Posting Setup is being run
        case FieldNo of
            GeneralPostingSetup.FieldNo("Sales Account"):
                GeneralPostingSetup.GetSalesAccount();
            GeneralPostingSetup.FieldNo("Sales Line Disc. Account"):
                GeneralPostingSetup.GetSalesLineDiscAccount();
            GeneralPostingSetup.FieldNo("Sales Inv. Disc. Account"):
                GeneralPostingSetup.GetSalesInvDiscAccount();
            GeneralPostingSetup.FieldNo("Sales Credit Memo Account"):
                GeneralPostingSetup.GetSalesCrMemoAccount();
            GeneralPostingSetup.FieldNo("Invt. Accrual Acc. (Interim)"):
                GeneralPostingSetup.GetInventoryAccrualAccount();
            GeneralPostingSetup.FieldNo("Inventory Adjmt. Account"):
                GeneralPostingSetup.GetInventoryAdjmtAccount();
            GeneralPostingSetup.FieldNo("COGS Account (Interim)"):
                GeneralPostingSetup.GetCOGSInterimAccount();
            GeneralPostingSetup.FieldNo("COGS Account"):
                GeneralPostingSetup.GetCOGSAccount();
            GeneralPostingSetup.FieldNo("Sales Prepayments Account"):
                GeneralPostingSetup.GetSalesPrepmtAccount();
            GeneralPostingSetup.FieldNo("Purch. Account"):
                GeneralPostingSetup.GetPurchAccount();
            GeneralPostingSetup.FieldNo("Purch. Credit Memo Account"):
                GeneralPostingSetup.GetPurchCrMemoAccount();
            GeneralPostingSetup.FieldNo("Purch. Inv. Disc. Account"):
                GeneralPostingSetup.GetPurchInvDiscAccount();
            GeneralPostingSetup.FieldNo("Purch. Line Disc. Account"):
                GeneralPostingSetup.GetPurchLineDiscAccount();
            GeneralPostingSetup.FieldNo("Purch. Prepayments Account"):
                GeneralPostingSetup.GetPurchPrepmtAccount();
            GeneralPostingSetup.FieldNo("Purch. FA Disc. Account"):
                GeneralPostingSetup.GetPurchFADiscAccount();
            GeneralPostingSetup.FieldNo("Direct Cost Applied Account"):
                GeneralPostingSetup.GetDirectCostAppliedAccount();
            GeneralPostingSetup.FieldNo("Overhead Applied Account"):
                GeneralPostingSetup.GetOverheadAppliedAccount();
            GeneralPostingSetup.FieldNo("Purchase Variance Account"):
                GeneralPostingSetup.GetPurchaseVarianceAccount();
        end;

        // [THEN] Error message created "XXX is missing in General Posting Setup."
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        VerifyErrorMessage(TempErrorMessage, GeneralPostingSetup, GetGeneralPostingSetupFieldCaption(GeneralPostingSetup, FieldNo));
    end;

    local procedure GeneralPostingSetupScenario(FieldNo: Integer; BooleanParameter: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        Initialize();

        // [GIVEN] General Posting Setup with empty accounts
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Function GetXXXAccount(BooleanParameter) of General Posting Setup is being run
        case FieldNo of
            GeneralPostingSetup.FieldNo("Sales Pmt. Disc. Debit Acc."),
            GeneralPostingSetup.FieldNo("Sales Pmt. Disc. Credit Acc."):
                GeneralPostingSetup.GetSalesPmtDiscountAccount(BooleanParameter);
            GeneralPostingSetup.FieldNo("Sales Pmt. Tol. Debit Acc."),
            GeneralPostingSetup.FieldNo("Sales Pmt. Tol. Credit Acc."):
                GeneralPostingSetup.GetSalesPmtToleranceAccount(BooleanParameter);
            GeneralPostingSetup.FieldNo("Purch. Pmt. Disc. Debit Acc."),
            GeneralPostingSetup.FieldNo("Purch. Pmt. Disc. Credit Acc."):
                GeneralPostingSetup.GetPurchPmtDiscountAccount(BooleanParameter);
            GeneralPostingSetup.FieldNo("Purch. Pmt. Tol. Debit Acc."),
            GeneralPostingSetup.FieldNo("Purch. Pmt. Tol. Credit Acc."):
                GeneralPostingSetup.GetPurchPmtToleranceAccount(BooleanParameter);
        end;

        // [THEN] Error message created "XXX is missing in General Posting Setup."
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        VerifyErrorMessage(TempErrorMessage, GeneralPostingSetup, GetGeneralPostingSetupFieldCaption(GeneralPostingSetup, FieldNo));
    end;

    local procedure VATPostingSetupScenario(FieldNo: Integer; BooleanParameter: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        Initialize();

        // [GIVEN] VAT Posting Setup with empty accounts
        CreateVATPostingSetup(VATPostingSetup);

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Function GetXXXAccount(BooleanParameter) of VAT Posting Setup is being run
        case FieldNo of
            VATPostingSetup.FieldNo("Sales VAT Unreal. Account"),
            VATPostingSetup.FieldNo("Sales VAT Account"):
                VATPostingSetup.GetSalesAccount(BooleanParameter);
            VATPostingSetup.FieldNo("Purch. VAT Unreal. Account"),
            VATPostingSetup.FieldNo("Purchase VAT Account"):
                VATPostingSetup.GetPurchAccount(BooleanParameter);
            VATPostingSetup.FieldNo("Reverse Chrg. VAT Unreal. Acc."),
            VATPostingSetup.FieldNo("Reverse Chrg. VAT Acc."):
                VATPostingSetup.GetRevChargeAccount(BooleanParameter);
        end;

        // [THEN] Error message created "XXX is missing in VAT Posting Setup."
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        VerifyErrorMessage(TempErrorMessage, VATPostingSetup, GetVATPostingSetupFieldCaption(VATPostingSetup, FieldNo));
    end;

    local procedure InventoryPostingSetupScenario(FieldNo: Integer)
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        Initialize();

        // [GIVEN] Inventory Posting Setup with empty accounts
        CreateInventoryPostingSetup(InventoryPostingSetup);

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Function GetXXXAccount of Inventory Posting Setup is being run
        case FieldNo of
            InventoryPostingSetup.FieldNo("Capacity Variance Account"):
                InventoryPostingSetup.GetCapacityVarianceAccount();
            InventoryPostingSetup.FieldNo("Cap. Overhead Variance Account"):
                InventoryPostingSetup.GetCapOverheadVarianceAccount();
            InventoryPostingSetup.FieldNo("Inventory Account"):
                InventoryPostingSetup.GetInventoryAccount();
            InventoryPostingSetup.FieldNo("Inventory Account (Interim)"):
                InventoryPostingSetup.GetInventoryAccountInterim();
            InventoryPostingSetup.FieldNo("Material Variance Account"):
                InventoryPostingSetup.GetMaterialVarianceAccount();
            InventoryPostingSetup.FieldNo("Mfg. Overhead Variance Account"):
                InventoryPostingSetup.GetMfgOverheadVarianceAccount();
            InventoryPostingSetup.FieldNo("Subcontracted Variance Account"):
                InventoryPostingSetup.GetSubcontractedVarianceAccount();
            InventoryPostingSetup.FieldNo("WIP Account"):
                InventoryPostingSetup.GetWIPAccount();
        end;

        // [THEN] Error message created "XXX is missing in Inventory Posting Setup."
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        VerifyErrorMessage(TempErrorMessage, InventoryPostingSetup, GetInventoryPostingSetupFieldCaption(InventoryPostingSetup, FieldNo));
    end;

    local procedure CustomerPostingGroupScenario(FieldNo: Integer)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        Initialize();

        // [GIVEN] Customer Posting Setup with empty accounts
        CreateCustomerPostingGroup(CustomerPostingGroup);

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Function GetXXXAccount of Customer Posting Setup is being run
        case FieldNo of
            CustomerPostingGroup.FieldNo("Receivables Account"):
                CustomerPostingGroup.GetReceivablesAccount();
            CustomerPostingGroup.FieldNo("Invoice Rounding Account"):
                CustomerPostingGroup.GetInvRoundingAccount();
            CustomerPostingGroup.FieldNo("Service Charge Acc."):
                CustomerPostingGroup.GetServiceChargeAccount();
            CustomerPostingGroup.FieldNo("Additional Fee Account"):
                CustomerPostingGroup.GetAdditionalFeeAccount();
            CustomerPostingGroup.FieldNo("Add. Fee per Line Account"):
                CustomerPostingGroup.GetAddFeePerLineAccount();
            CustomerPostingGroup.FieldNo("Interest Account"):
                CustomerPostingGroup.GetInterestAccount();
        end;

        // [THEN] Error message created "XXX is missing in Customer Posting Setup."
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        VerifyErrorMessage(TempErrorMessage, CustomerPostingGroup, GetCustomerPostingGroupFieldCaption(CustomerPostingGroup, FieldNo));
    end;

    local procedure CustomerPostingGroupScenario(FieldNo: Integer; BooleanParameter: Boolean)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        Initialize();

        // [GIVEN] Customer Posting Group with empty accounts
        CreateCustomerPostingGroup(CustomerPostingGroup);

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Function GetXXXAccount of Customer Posting Group is being run
        case FieldNo of
            CustomerPostingGroup.FieldNo("Payment Disc. Debit Acc."),
            CustomerPostingGroup.FieldNo("Payment Disc. Credit Acc."):
                CustomerPostingGroup.GetPmtDiscountAccount(BooleanParameter);
            CustomerPostingGroup.FieldNo("Payment Tolerance Debit Acc."),
            CustomerPostingGroup.FieldNo("Payment Tolerance Credit Acc."):
                CustomerPostingGroup.GetPmtToleranceAccount(BooleanParameter);
            CustomerPostingGroup.FieldNo("Debit Rounding Account"),
            CustomerPostingGroup.FieldNo("Credit Rounding Account"):
                CustomerPostingGroup.GetRoundingAccount(BooleanParameter);
            CustomerPostingGroup.FieldNo("Debit Curr. Appln. Rndg. Acc."),
            CustomerPostingGroup.FieldNo("Credit Curr. Appln. Rndg. Acc."):
                CustomerPostingGroup.GetApplRoundingAccount(BooleanParameter);
        end;

        // [THEN] Error message created "XXX is missing in Customer Posting Group."
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        VerifyErrorMessage(TempErrorMessage, CustomerPostingGroup, GetCustomerPostingGroupFieldCaption(CustomerPostingGroup, FieldNo));
    end;

    local procedure VendorPostingGroupScenario(FieldNo: Integer)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        Initialize();

        // [GIVEN] Vendor Posting Group with empty accounts
        CreateVendorPostingGroup(VendorPostingGroup);

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Function GetXXXAccount of Vendor Posting Group is being run
        case FieldNo of
            VendorPostingGroup.FieldNo("Payables Account"):
                VendorPostingGroup.GetPayablesAccount();
            VendorPostingGroup.FieldNo("Invoice Rounding Account"):
                VendorPostingGroup.GetInvRoundingAccount();
            VendorPostingGroup.FieldNo("Service Charge Acc."):
                VendorPostingGroup.GetServiceChargeAccount();
        end;

        // [THEN] Error message created "XXX is missing in Vendor Posting Group."
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        VerifyErrorMessage(TempErrorMessage, VendorPostingGroup, GetVendorPostingGroupFieldCaption(VendorPostingGroup, FieldNo));
    end;

    local procedure VendorPostingGroupScenario(FieldNo: Integer; BooleanParameter: Boolean)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        Initialize();

        // [GIVEN] Vendor Posting Group with empty accounts
        CreateVendorPostingGroup(VendorPostingGroup);

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Function GetXXXAccount of Vendor Posting Group is being run
        case FieldNo of
            VendorPostingGroup.FieldNo("Payment Disc. Debit Acc."),
            VendorPostingGroup.FieldNo("Payment Disc. Credit Acc."):
                VendorPostingGroup.GetPmtDiscountAccount(BooleanParameter);
            VendorPostingGroup.FieldNo("Payment Tolerance Debit Acc."),
            VendorPostingGroup.FieldNo("Payment Tolerance Credit Acc."):
                VendorPostingGroup.GetPmtToleranceAccount(BooleanParameter);
            VendorPostingGroup.FieldNo("Debit Rounding Account"),
            VendorPostingGroup.FieldNo("Credit Rounding Account"):
                VendorPostingGroup.GetRoundingAccount(BooleanParameter);
            VendorPostingGroup.FieldNo("Debit Curr. Appln. Rndg. Acc."),
            VendorPostingGroup.FieldNo("Credit Curr. Appln. Rndg. Acc."):
                VendorPostingGroup.GetApplRoundingAccount(BooleanParameter);
        end;

        // [THEN] Error message created "XXX is missing in Vendor Posting Group."
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        VerifyErrorMessage(TempErrorMessage, VendorPostingGroup, GetVendorPostingGroupFieldCaption(VendorPostingGroup, FieldNo));
    end;

    local procedure JobPostingGroupScenario(FieldNo: Integer)
    var
        JobPostingGroup: Record "Job Posting Group";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        Initialize();

        // [GIVEN] Job Posting Setup with empty accounts
        CreateJobPostingGroup(JobPostingGroup);

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Function GetXXXAccount of Job Posting Setup is being run
        case FieldNo of
            JobPostingGroup.FieldNo("WIP Costs Account"):
                JobPostingGroup.GetWIPCostsAccount();
            JobPostingGroup.FieldNo("WIP Accrued Costs Account"):
                JobPostingGroup.GetWIPAccruedCostsAccount();
            JobPostingGroup.FieldNo("WIP Accrued Sales Account"):
                JobPostingGroup.GetWIPAccruedSalesAccount();
            JobPostingGroup.FieldNo("WIP Invoiced Sales Account"):
                JobPostingGroup.GetWIPInvoicedSalesAccount();
            JobPostingGroup.FieldNo("Job Costs Applied Account"):
                JobPostingGroup.GetJobCostsAppliedAccount();
            JobPostingGroup.FieldNo("Job Costs Adjustment Account"):
                JobPostingGroup.GetJobCostsAdjustmentAccount();
            JobPostingGroup.FieldNo("G/L Expense Acc. (Contract)"):
                JobPostingGroup.GetGLExpenseAccountContract();
            JobPostingGroup.FieldNo("Job Sales Adjustment Account"):
                JobPostingGroup.GetJobSalesAdjustmentAccount();
            JobPostingGroup.FieldNo("Job Sales Applied Account"):
                JobPostingGroup.GetJobSalesAppliedAccount();
            JobPostingGroup.FieldNo("Recognized Costs Account"):
                JobPostingGroup.GetRecognizedCostsAccount();
            JobPostingGroup.FieldNo("Recognized Sales Account"):
                JobPostingGroup.GetRecognizedSalesAccount();
            JobPostingGroup.FieldNo("Item Costs Applied Account"):
                JobPostingGroup.GetItemCostsAppliedAccount();
            JobPostingGroup.FieldNo("Resource Costs Applied Account"):
                JobPostingGroup.GetResourceCostsAppliedAccount();
            JobPostingGroup.FieldNo("G/L Costs Applied Account"):
                JobPostingGroup.GetGLCostsAppliedAccount();
        end;

        // [THEN] Error message created "XXX is missing in Job Posting Setup."
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        VerifyErrorMessage(TempErrorMessage, JobPostingGroup, GetJobPostingGroupFieldCaption(JobPostingGroup, FieldNo));
    end;

    local procedure FAPostingGroupScenario(FieldNo: Integer)
    var
        FAPostingGroup: Record "FA Posting Group";
        TempErrorMessage: Record "Error Message" temporary;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
    begin
        Initialize();

        // [GIVEN] FA Posting Setup with empty accounts
        CreateFAPostingGroup(FAPostingGroup);

        // [GIVEN] Activate error handling 
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        // [WHEN] Function GetXXXAccount of FA Posting Setup is being run
        case FieldNo of
            FAPostingGroup.FieldNo("Acquisition Cost Account"):
                FAPostingGroup.GetAcquisitionCostAccount();
            FAPostingGroup.FieldNo("Acq. Cost Acc. on Disposal"):
                FAPostingGroup.GetAcquisitionCostAccountOnDisposal();
            FAPostingGroup.FieldNo("Acquisition Cost Bal. Acc."):
                FAPostingGroup.GetAcquisitionCostBalanceAccount();
            FAPostingGroup.FieldNo("Accum. Depreciation Account"):
                FAPostingGroup.GetAccumDepreciationAccount();
            FAPostingGroup.FieldNo("Accum. Depr. Acc. on Disposal"):
                FAPostingGroup.GetAccumDepreciationAccountOnDisposal();
            FAPostingGroup.FieldNo("Appreciation Account"):
                FAPostingGroup.GetAppreciationAccount();
            FAPostingGroup.FieldNo("Appreciation Acc. on Disposal"):
                FAPostingGroup.GetAppreciationAccountOnDisposal();
            FAPostingGroup.FieldNo("Appreciation Bal. Account"):
                FAPostingGroup.GetAppreciationBalanceAccount();
            FAPostingGroup.FieldNo("Apprec. Bal. Acc. on Disp."):
                FAPostingGroup.GetAppreciationBalAccountOnDisposal();
            FAPostingGroup.FieldNo("Book Val. Acc. on Disp. (Gain)"):
                FAPostingGroup.GetBookValueAccountOnDisposalGain();
            FAPostingGroup.FieldNo("Book Val. Acc. on Disp. (Loss)"):
                FAPostingGroup.GetBookValueAccountOnDisposalLoss();
            FAPostingGroup.FieldNo("Custom 1 Account"):
                FAPostingGroup.GetCustom1Account();
            FAPostingGroup.FieldNo("Custom 2 Account"):
                FAPostingGroup.GetCustom2Account();
            FAPostingGroup.FieldNo("Custom 1 Account on Disposal"):
                FAPostingGroup.GetCustom1AccountOnDisposal();
            FAPostingGroup.FieldNo("Custom 2 Account on Disposal"):
                FAPostingGroup.GetCustom2AccountOnDisposal();
            FAPostingGroup.FieldNo("Custom 1 Bal. Acc. on Disposal"):
                FAPostingGroup.GetCustom1BalAccountOnDisposal();
            FAPostingGroup.FieldNo("Custom 2 Bal. Acc. on Disposal"):
                FAPostingGroup.GetCustom2BalAccountOnDisposal();
            FAPostingGroup.FieldNo("Custom 1 Expense Acc."):
                FAPostingGroup.GetCustom1ExpenseAccount();
            FAPostingGroup.FieldNo("Custom 2 Expense Acc."):
                FAPostingGroup.GetCustom2ExpenseAccount();
            FAPostingGroup.FieldNo("Depreciation Expense Acc."):
                FAPostingGroup.GetDepreciationExpenseAccount();
            FAPostingGroup.FieldNo("Gains Acc. on Disposal"):
                FAPostingGroup.GetGainsAccountOnDisposal();
            FAPostingGroup.FieldNo("Losses Acc. on Disposal"):
                FAPostingGroup.GetLossesAccountOnDisposal();
            FAPostingGroup.FieldNo("Maintenance Expense Account"):
                FAPostingGroup.GetMaintenanceExpenseAccount();
            FAPostingGroup.FieldNo("Maintenance Bal. Acc."):
                FAPostingGroup.GetMaintenanceBalanceAccount();
            FAPostingGroup.FieldNo("Sales Bal. Acc."):
                FAPostingGroup.GetSalesBalanceAccount();
            FAPostingGroup.FieldNo("Sales Acc. on Disp. (Gain)"):
                FAPostingGroup.GetSalesAccountOnDisposalGain();
            FAPostingGroup.FieldNo("Sales Acc. on Disp. (Loss)"):
                FAPostingGroup.GetSalesAccountOnDisposalLoss();
            FAPostingGroup.FieldNo("Write-Down Account"):
                FAPostingGroup.GetWriteDownAccount();
            FAPostingGroup.FieldNo("Write-Down Acc. on Disposal"):
                FAPostingGroup.GetWriteDownAccountOnDisposal();
            FAPostingGroup.FieldNo("Write-Down Bal. Acc. on Disp."):
                FAPostingGroup.GetWriteDownBalAccountOnDisposal();
            FAPostingGroup.FieldNo("Write-Down Expense Acc."):
                FAPostingGroup.GetWriteDownExpenseAccount();
        end;

        // [THEN] Error message created "XXX is missing in FA Posting Setup."
        ErrorMessageHandler.AppendTo(TempErrorMessage);
        VerifyErrorMessage(TempErrorMessage, FAPostingGroup, GetFAPostingGroupFieldCaption(FAPostingGroup, FieldNo));
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
    end;

    local procedure CreateInventoryPostingSetup(var InventoryPostingSetup: Record "Inventory Posting Setup")
    var
        Location: Record Location;
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, InventoryPostingGroup.Code);
    end;

    local procedure CreateCustomerPostingGroup(var CustomerPostingGroup: Record "Customer Posting Group")
    begin
        CustomerPostingGroup.Init();
        CustomerPostingGroup.Validate(Code,
          LibraryUtility.GenerateRandomCode(CustomerPostingGroup.FieldNo(Code), DATABASE::"Customer Posting Group"));
        CustomerPostingGroup.Insert(true);
    end;

    local procedure CreateVendorPostingGroup(var VendorPostingGroup: Record "Vendor Posting Group")
    begin
        VendorPostingGroup.Init();
        VendorPostingGroup.Validate(Code,
          LibraryUtility.GenerateRandomCode(VendorPostingGroup.FieldNo(Code), DATABASE::"Vendor Posting Group"));
        VendorPostingGroup.Insert(true);
    end;

    local procedure CreateJobPostingGroup(var JobPostingGroup: Record "Job Posting Group")
    begin
        JobPostingGroup.Init();
        JobPostingGroup.Validate(Code,
          LibraryUtility.GenerateRandomCode(JobPostingGroup.FieldNo(Code), DATABASE::"Job Posting Group"));
        JobPostingGroup.Insert(true);
    end;

    local procedure CreateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    begin
        FAPostingGroup.Init();
        FAPostingGroup.Validate(Code,
          LibraryUtility.GenerateRandomCode(FAPostingGroup.FieldNo(Code), DATABASE::"FA Posting Group"));
        FAPostingGroup.Insert(true);
    end;

    local procedure GetGeneralPostingSetupFieldCaption(var GeneralPostingSetup: Record "General Posting Setup"; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(GeneralPostingSetup);
        FldRef := RecRef.Field(FieldNo);
        exit(FldRef.Caption);
    end;

    local procedure GetInventoryPostingSetupFieldCaption(var InventoryPostingSetup: Record "Inventory Posting Setup"; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(InventoryPostingSetup);
        FldRef := RecRef.Field(FieldNo);
        exit(FldRef.Caption);
    end;

    local procedure GetVATPostingSetupFieldCaption(var VATPostingSetup: Record "VAT Posting Setup"; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(VATPostingSetup);
        FldRef := RecRef.Field(FieldNo);
        exit(FldRef.Caption);
    end;

    local procedure GetCustomerPostingGroupFieldCaption(var CustomerPostingGroup: Record "Customer Posting Group"; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(CustomerPostingGroup);
        FldRef := RecRef.Field(FieldNo);
        exit(FldRef.Caption);
    end;

    local procedure GetVendorPostingGroupFieldCaption(var VendorPostingGroup: Record "Vendor Posting Group"; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(VendorPostingGroup);
        FldRef := RecRef.Field(FieldNo);
        exit(FldRef.Caption);
    end;

    local procedure GetJobPostingGroupFieldCaption(var JobPostingGroup: Record "Job Posting Group"; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(JobPostingGroup);
        FldRef := RecRef.Field(FieldNo);
        exit(FldRef.Caption);
    end;

    local procedure GetFAPostingGroupFieldCaption(var FAPostingGroup: Record "FA Posting Group"; FieldNo: Integer): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.GetTable(FAPostingGroup);
        FldRef := RecRef.Field(FieldNo);
        exit(FldRef.Caption);
    end;

    local procedure VerifyErrorMessage(var TempErrorMessage: Record "Error Message" temporary; VariantRec: Variant; FieldCaption: Text)
    begin
        TempErrorMessage.FindFirst();
        TempErrorMessage.TestField(
            "Message",
            LibraryErrorMessage.GetMissingAccountErrorMessage(FieldCaption, VariantRec));
        TempErrorMessage.TestField("Support Url", 'https://go.microsoft.com/fwlink/?linkid=2157418');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true
    end;
}