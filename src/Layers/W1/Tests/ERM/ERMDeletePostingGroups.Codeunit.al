codeunit 134070 "ERM Delete Posting Groups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Posting Group]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        YouCannotDeleteErr: Label 'You cannot delete %1 %2.';
        YouCannotDeleteOrModifyErr: Label 'You cannot modify or delete VAT posting setup %1 %2 as it has been used to generate GL entries. Changing the setup now can cause inconsistencies in your financial data.';

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCustomerPostingGroupWithCustomers()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        // [FEATURE] [Customer]
        Initialize();

        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer."Customer Posting Group" := CustomerPostingGroup.Code;
        Customer.Modify(true);

        asserterror CustomerPostingGroup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCustomerPostingGroupWithLedgerEntries()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        // [FEATURE] [Customer]
        Initialize();

        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateCustomer(Customer);
        Customer."Customer Posting Group" := CustomerPostingGroup.Code;
        Customer.Modify(true);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandInt(10), '', 0D);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        asserterror CustomerPostingGroup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteVendorPostingGroupWithCustomers()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        // [FEATURE] [Vendor]
        Initialize();

        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Vendor Posting Group" := VendorPostingGroup.Code;
        Vendor.Modify(true);

        asserterror VendorPostingGroup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteVendorPostingGroupWithLedgerEntries()
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Vendor]
        Initialize();

        LibraryPurchase.CreateVendorPostingGroup(VendorPostingGroup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Vendor Posting Group" := VendorPostingGroup.Code;
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, Vendor."No.", '', LibraryRandom.RandInt(10), '', 0D);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        asserterror VendorPostingGroup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteInvtPostingGroupWithItems()
    var
        Item: Record Item;
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        // [FEATURE] [Inventory]
        Initialize();

        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        LibraryInventory.CreateItem(Item);
        Item."Inventory Posting Group" := InventoryPostingGroup.Code;
        Item.Modify(true);

        asserterror InventoryPostingGroup.Delete(true);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeleteInvtPostingSetupWithValueEntries()
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        InventoryPostingGroup: Record "Inventory Posting Group";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Inventory]
        // [GIVEN] new Inventory Posting Setup, where "Location" = 'A',"Inv. Posting Group Code" = 'B'
        Location.Code := CopyStr(LibraryRandom.RandText(10), 1, MaxStrLen(Location.Code));
        Location.Insert();
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        LibraryInventory.CreateInventoryPostingSetup(InventoryPostingSetup, Location.Code, InventoryPostingGroup.Code);

        // [GIVEN] Posted a G/L Entry, where "Location" = 'A',"Inv. Posting Group Code" = 'B'
        if ValueEntry.FindLast() then;
        ValueEntry."Entry No." += 1;
        ValueEntry."Location Code" := Location.Code;
        ValueEntry."Inventory Posting Group" := InventoryPostingGroup.Code;
        ValueEntry.Insert();

        // [WHEN] Delete General Posting Setup
        asserterror InventoryPostingSetup.Delete(true);
        // [THEN] Error: 'You cannot delete A B'
        Assert.ExpectedError(
          StrSubstNo(YouCannotDeleteErr, Location.Code, InventoryPostingGroup.Code));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeleteGenPostingSetupWithLedgerEntries()
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [General Ledger]
        // [GIVEN] new General Posting Setup, where "Gen. Bus. Posting Group" = 'A',"Gen. Prod. Posting Group" = 'B'
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(
          GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);

        // [GIVEN] Posted a G/L Entry, where "Gen. Bus. Posting Group" = 'A',"Gen. Prod. Posting Group" = 'B'
        if GLEntry.FindLast() then;
        GLEntry."Entry No." += 1;
        GLEntry."Gen. Bus. Posting Group" := GeneralPostingSetup."Gen. Bus. Posting Group";
        GLEntry."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        GLEntry.Insert();

        // [WHEN] Delete General Posting Setup
        asserterror GeneralPostingSetup.Delete(true);
        // [THEN] Error: 'You cannot delete A B'
        Assert.ExpectedError(
          StrSubstNo(YouCannotDeleteErr, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ModifyVATPostingSetupWithLedgerEntries()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup, VATProductPostingGroup2: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [VAT]
        // [GIVEN] new VAT Posting Setup, where "VAT Bus. Posting Group" = 'A',"VAT Prod. Posting Group" = 'B'
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup2);
        LibraryERM.CreateVATPostingSetup(
          VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);

        // [GIVEN] Posted a G/L Entry, where "VAT Bus. Posting Group" = 'A',"VAT Prod. Posting Group" = 'B'
        if GLEntry.FindLast() then;
        GLEntry."Entry No." += 1;
        GLEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        GLEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GLEntry.Insert();

        // [WHEN] Rename VAT Posting Setup we throw error
        asserterror VATPostingSetup.Rename(VATBusinessPostingGroup.Code, VATProductPostingGroup2.Code);

        // [THEN] Error: 'You cannot delete/modify A B ...'
        Assert.ExpectedError(
          StrSubstNo(YouCannotDeleteOrModifyErr, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure DeleteVATPostingSetupWithLedgerEntries()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [VAT]
        // [GIVEN] new VAT Posting Setup, where "VAT Bus. Posting Group" = 'A',"VAT Prod. Posting Group" = 'B'
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(
          VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);

        // [GIVEN] Posted a G/L Entry, where "VAT Bus. Posting Group" = 'A',"VAT Prod. Posting Group" = 'B'
        if GLEntry.FindLast() then;
        GLEntry."Entry No." += 1;
        GLEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        GLEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        GLEntry.Insert();

        // [WHEN] Delete VAT Posting Setup
        asserterror VATPostingSetup.Delete(true);
        // [THEN] Error: 'You cannot delete/modify A B ...'
        Assert.ExpectedError(
          StrSubstNo(YouCannotDeleteOrModifyErr, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Delete Posting Groups");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Delete Posting Groups");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Delete Posting Groups");
    end;
}

