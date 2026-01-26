codeunit 144051 "ERM Reports DE"
{
    //  // [FEATURE] [Report] [VAT VIES]
    //  1. Test and verify Adjust Cost Item Entries after Fully Purchase Invoice.
    //  2. Test and Inventory Valuation Expected after Fully Purchase Invoice.
    //  3. Test and verify Adjust Cost Item Entries after Partial Purchase Invoice.
    //  4. Test and Inventory Valuation Expected after Partial Purchase Invoice.
    //  5. Verify that Report Intrastat - Form DE print correct caption.
    // 
    //  Covers Test Cases for WI - 326841
    //  ------------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                                   TFS ID
    //  ------------------------------------------------------------------------------------------------------------
    //  AdjustCostItemEntriesAfterFullyPurchaseInvoice, InventoryValuationExpdAfterFullyPurchaseInvoice      155741
    //  AdjustCostItemEntriesAfterPartialPurchaseInvoice, InventoryValuationExpdAfterPartialPurchaseInvoice  155740
    // 
    //  BUG ID - 329756
    //  ------------------------------------------------------------------------------------------------------------
    //  Test Function Name                                                                                   TFS ID
    //  ------------------------------------------------------------------------------------------------------------
    //  CheckIntrastatFormDEReportHeaderCaptions

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2', Locked = true;
        ValueMustBeEqualErr: Label 'The value of %1 must be Equal to %2.', Locked = true;
        FileVersionNotDefinedErr: Label 'You must specify file version.';
        FileVersionElsterOnlineNotDefinedErr: Label 'You must specify file version (Elster online).';

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesAfterFullyPurchaseInvoice()
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        DocumentNo4: Code[20];
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        // Setup: Create two Items with different Costing Method. Create and post Purchase Order as Receive and Invoice.
        // Create and post Second Purchase Order as only Receive. Create and post Sales Order as Ship.
        // Post Second Purchase Order as Invoice with Updated Direct Unit Cost. Calculated values required for test.
        Initialize();
        CreateItemsWithCostingMethodAndInvtPostingGroup(Item, Item2);
        DirectUnitCost := LibraryRandom.RandDec(100, 2);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrdersAsInvoiceAndReceive(
          PurchaseHeader, DocumentNo, DocumentNo2, Item."No.", Item2."No.", Quantity, DirectUnitCost);
        DocumentNo3 := CreateAndPostSalesOrderWithTwoLines(Item."No.", Item2."No.", Quantity, Quantity * 2);
        DocumentNo4 :=
          PostPurchaseOrderAfterUpdateDirectUnitCost(PurchaseHeader, Item."No.", Item2."No.", DirectUnitCost + DirectUnitCost / 2, false);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(Item."No." + '|' + Item2."No.", '');

        // Verify.
        VerifyValueEntries(DocumentNo, DocumentNo2, DocumentNo3, DocumentNo4, Item."No.", Item2."No.", Quantity, DirectUnitCost, false);
    end;

    [Test]
    [HandlerFunctions('InventoryValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationExpdAfterFullyPurchaseInvoice()
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        // Setup: Create two Items with different Costing Method. Create and post Purchase Order as Receive and Invoice.
        // Create and post Second Purchase Order as only Receive. Create and post Sales Order as Ship.
        // Post Second Purchase Order as Invoice with Updated Direct Unit Cost. Adjust Cost Item Entries. Calculated values required for test.
        Initialize();
        CreateItemsWithCostingMethodAndInvtPostingGroup(Item, Item2);
        DirectUnitCost := LibraryRandom.RandDec(100, 2);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrdersAsInvoiceAndReceive(
          PurchaseHeader, DocumentNo, DocumentNo2, Item."No.", Item2."No.", Quantity, DirectUnitCost);
        CreateAndPostSalesOrderWithTwoLines(Item."No.", Item2."No.", Quantity, Quantity * 2);
        PostPurchaseOrderAfterUpdateDirectUnitCost(PurchaseHeader, Item."No.", Item2."No.", DirectUnitCost + DirectUnitCost / 2, false);
        LibraryCosting.AdjustCostItemEntries(Item."No." + '|' + Item2."No.", '');

        // Exercise.
        RunInventoryValue(Item."No." + '|' + Item2."No.");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInventoryValuationExpectedOnInventoryValue(Item);
        VerifyInventoryValuationExpectedOnInventoryValue(Item2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesAfterPartialPurchaseInvoice()
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        DocumentNo4: Code[20];
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        // Setup: Create two Items with different Costing Method. Create and post Purchase Order as Receive and Invoice.
        // Create and post Second Purchase Order as only Receive. Create and post Sales Order as Ship.
        // Partial Post Second Purchase Order as Invoice with Updated Direct Unit Cost. Calculated values required for test.
        Initialize();
        CreateItemsWithCostingMethodAndInvtPostingGroup(Item, Item2);
        DirectUnitCost := LibraryRandom.RandDec(100, 2);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrdersAsInvoiceAndReceive(
          PurchaseHeader, DocumentNo, DocumentNo2, Item."No.", Item2."No.", Quantity, DirectUnitCost);
        DocumentNo3 := CreateAndPostSalesOrderWithTwoLines(Item."No.", Item2."No.", Quantity, Quantity * 2);
        DocumentNo4 :=
          PostPurchaseOrderAfterUpdateDirectUnitCost(
            PurchaseHeader, Item."No.", Item2."No.", DirectUnitCost + DirectUnitCost / 2, true);  // Use True for Partial Invoice.

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(Item."No." + '|' + Item2."No.", '');

        // Verify.
        VerifyValueEntries(DocumentNo, DocumentNo2, DocumentNo3, DocumentNo4, Item."No.", Item2."No.", Quantity, DirectUnitCost, true);
    end;

    [Test]
    [HandlerFunctions('InventoryValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationExpdAfterPartialPurchaseInvoice()
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DirectUnitCost: Decimal;
        Quantity: Decimal;
    begin
        // Setup: Create two Items with different Costing Method. Create and post Purchase Order as Receive and Invoice.
        // Create and post Second Purchase Order as only Receive. Create and post Sales Order as Ship.
        // Partial Post Second Purchase Order as Invoice with Updated Direct Unit Cost. Adjust Cost Item Entries. Calculated values required for test.
        Initialize();
        CreateItemsWithCostingMethodAndInvtPostingGroup(Item, Item2);
        DirectUnitCost := LibraryRandom.RandDec(100, 2);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostPurchaseOrdersAsInvoiceAndReceive(
          PurchaseHeader, DocumentNo, DocumentNo2, Item."No.", Item2."No.", Quantity, DirectUnitCost);
        CreateAndPostSalesOrderWithTwoLines(Item."No.", Item2."No.", Quantity, Quantity * 2);
        PostPurchaseOrderAfterUpdateDirectUnitCost(
          PurchaseHeader, Item."No.", Item2."No.", DirectUnitCost + DirectUnitCost / 2, true);  // Use True for Partial Invoice.
        LibraryCosting.AdjustCostItemEntries(Item."No." + '|' + Item2."No.", '');

        // Exercise.
        RunInventoryValue(Item."No." + '|' + Item2."No.");

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyInventoryValuationExpectedOnInventoryValue(Item);
        VerifyInventoryValuationExpectedOnInventoryValue(Item2);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationDiskReportFailedWhenFileVersionNotDefined()
    var
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 381790] The "VAT - VIES Declaration Disk" report failed when "File Version" is not defined on Request Page

        // [GIVEN] Posted Sales Invoice with VAT Entry "X"
        Initialize();
        DocumentNo := CreateAndPostSalesDocument();
        FindVATEntry(VATEntry, DocumentNo);
        // [GIVEN] Set value for "File Version" and blank for "File version 2 (Elster online)" for VATVIESDeclarationDiskRequestPageHandler
        LibraryVariableStorage.Enqueue(LibraryUTUtility.GetNewCode());
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run report "VAT - VIES Declaration Disk" against VAT Entry with Request Page and "File version" not defined
        asserterror RunReportVATVIESDeclarationDisk(VATEntry);

        // [THEN] The error message "You must specify file version (Elster online)" is raised
        Assert.ExpectedError(FileVersionElsterOnlineNotDefinedErr);

        // Tear down to avoid "VAT Registration No." duplication
        DeleteCustomer(VATEntry."Bill-to/Pay-to No.");
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationDiskReportFailedWhenFileVersionElsterOnlineNotDefined()
    var
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 381790] The "VAT - VIES Declaration Disk" report failed when "File version 2 (Elster online)" is not defined on Request Page

        // [GIVEN] Posted Sales Invoice with VAT Entry "X"
        Initialize();
        DocumentNo := CreateAndPostSalesDocument();
        FindVATEntry(VATEntry, DocumentNo);
        // [GIVEN] Set blank for "File Version" and value for "File version 2 (Elster online)" for VATVIESDeclarationDiskRequestPageHandler
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(LibraryUTUtility.GetNewCode());
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run report "VAT - VIES Declaration Disk" against VAT Entry with Request Page and "File version 2 (Elster online)" not defined
        asserterror RunReportVATVIESDeclarationDisk(VATEntry);

        // [THEN] The error message "You must specify file version" is raised
        Assert.ExpectedError(FileVersionNotDefinedErr);

        // Tear down to avoid "VAT Registration No." duplication
        DeleteCustomer(VATEntry."Bill-to/Pay-to No.");
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskReqPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationDiskFileVersionFieldsInSAAS()
    var
        VATVIESDeclarationDisk: Report "VAT- VIES Declaration Disk";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266624] The fields "Show Amounts in Add. Reporting Currency", "File version (Elster online)" and "File version 2 (Elster online)" of "VAT- VIES Declaration Disk" have to aviable in SAAS
        Initialize();

        // [GIVEN] Enable Basic setup
        LibraryApplicationArea.EnableBasicSetup();
        Commit();

        // [WHEN] Run "VAT- VIES Declaration Disk"
        VATVIESDeclarationDisk.Run();

        // [THEN] Fields "Show Amounts in Add. Reporting Currency", "File version (Elster online)" and "File version 2 (Elster online)" are aviable on Request page
        // Verifying in VATVIESDeclarationDiskReqPageHandler
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationDiskReportWorksWithoutCustCountryCodeIfSkipEnabled()
    var
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
        FileName: Text;
    begin
        // [SCENARIO 279504] The "VAT - VIES Declaration Disk" report doesn't fail without Customer's Country Code if SkipCustomerDataCheck option is enabled
        Initialize();
        CompanyInformation.Get();

        // [GIVEN] A customer with Country Code blank, but a non-empty VAT Registration No.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code"));
        Customer.Modify(true);

        // [GIVEN] A VAT Entry for this Customer with filled in Country Code and VAT Registration No.
        CreateVATEntryForCustomer(Customer, VATEntry);
        UpdateCountryAndVATRegNoOnVATEntry(VATEntry);

        // [GIVEN] SkipCustomerDataCheck was enabled on request page
        EnqueueValuesForVATVIESRequestPage('1', '2', true);

        // [GIVEN] Prepare VAT Entries for the customer
        VATEntry.SetRange("Posting Date", VATEntry."Posting Date");
        VATEntry.SetRange("VAT Reporting Date", VATEntry."VAT Reporting Date");
        VATEntry.SetRange("Bill-to/Pay-to No.", Customer."No.");

        Commit();

        // [WHEN] Run report "VAT - VIES Declaration Disk" with SkipCustomerDataCheck enabled
        FileName := RunReportVATVIESDeclarationDisk(VATEntry);
        // Request Page handled by VATVIESDeclarationDiskRequestPageHandler

        // [THEN] No error pops up and the report file is generated
        Assert.IsTrue(FILE.Exists(FileName), 'Report file must exist on disk');
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationDiskReportWorksWithoutCustVATRegNoIfSkipEnabled()
    var
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
        FileName: Text;
    begin
        // [SCENARIO 283151] The "VAT - VIES Declaration Disk" report doesn't fail without Customer's VAT Registration No. if SkipCustomerDataCheck option is enabled
        Initialize();
        CompanyInformation.Get();

        // [GIVEN] A Customer with VAT Registration No. blank, but a non-empty Country Code
        LibrarySales.CreateCustomer(Customer);
        UpdateCountryCodeOnCustomer(Customer);

        // [GIVEN] A VAT entry for this Customer with filled in Country Code and VAT Registration No.
        CreateVATEntryForCustomer(Customer, VATEntry);
        UpdateCountryAndVATRegNoOnVATEntry(VATEntry);

        // [GIVEN] SkipCustomerDataCheck was enabled on request page
        EnqueueValuesForVATVIESRequestPage('1', '2', true);

        // [GIVEN] Prepare VAT Entries for the Customer
        VATEntry.SetRange("Posting Date", VATEntry."Posting Date");
        VATEntry.SetRange("VAT Reporting Date", VATEntry."VAT Reporting Date");
        VATEntry.SetRange("Bill-to/Pay-to No.", Customer."No.");

        Commit();

        // [WHEN] Run report "VAT - VIES Declaration Disk" with SkipCustomerDataCheck enabled
        FileName := RunReportVATVIESDeclarationDisk(VATEntry);
        // Request Page handled by VATVIESDeclarationDiskRequestPageHandler

        // [THEN] No error pops up and the report file is generated
        Assert.IsTrue(FILE.Exists(FileName), 'Report file must exist on disk');
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationDiskReportFailsWithoutCustCountryCodeIfSkipDisabled()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
    begin
        // [SCENARIO 279504] The "VAT - VIES Declaration Disk" report fails without Customer's Country Code if SkipCustomerDataCheck option is disabled
        Initialize();
        LibraryERM.SetBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] A customer with Country Code blank
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] A VAT Entry for this Customer with filled in Country Code and VAT Registration No.
        CreateVATEntryForCustomer(Customer, VATEntry);
        UpdateCountryAndVATRegNoOnVATEntry(VATEntry);

        // [GIVEN] SkipCustomerCountryRegionCheck was disabled on request page
        EnqueueValuesForVATVIESRequestPage('1', '2', false);

        // [GIVEN] Prepare VAT Entries for the Customer
        VATEntry.SetRange("Posting Date", VATEntry."Posting Date");
        VATEntry.SetRange("VAT Reporting Date", VATEntry."VAT Reporting Date");
        VATEntry.SetRange("Bill-to/Pay-to No.", Customer."No.");

        Commit();

        // [WHEN] Run report "VAT - VIES Declaration Disk" with SkipCustomerDataCheck disabled
        asserterror RunReportVATVIESDeclarationDisk(VATEntry);
        // Request Page handled by VATVIESDeclarationDiskRequestPageHandler

        // [THEN] Error pops up: Country/Region Code must have a value in Customer: No.=%1. It cannot be zero or empty.
        Assert.ExpectedTestFieldError(Customer.FieldCaption("Country/Region Code"), '');
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationDiskRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationDiskReportFailsWithoutCustVATRegNoIfSkipDisabled()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        Customer: Record Customer;
    begin
        // [SCENARIO 283151] The "VAT - VIES Declaration Disk" report fails without Customer's VAT Registration No. if SkipCustomerDataCheck option is disabled
        Initialize();
        LibraryERM.SetBillToSellToVATCalc(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");

        // [GIVEN] A Customer with Country Code filled, but VAT Registration No. blank
        LibrarySales.CreateCustomer(Customer);
        UpdateCountryCodeOnCustomer(Customer);

        // [GIVEN] A VAT Entry for this Customer with filled in Country Code and VAT Registration No.
        CreateVATEntryForCustomer(Customer, VATEntry);
        UpdateCountryAndVATRegNoOnVATEntry(VATEntry);

        // [GIVEN] SkipCustomerCountryRegionCheck was disabled on request page
        EnqueueValuesForVATVIESRequestPage('1', '2', false);

        // [GIVEN] Prepare VAT Entries for the customer
        VATEntry.SetRange("Posting Date", VATEntry."Posting Date");
        VATEntry.SetRange("VAT Reporting Date", VATEntry."VAT Reporting Date");
        VATEntry.SetRange("Bill-to/Pay-to No.", Customer."No.");

        Commit();

        // [WHEN] Run report "VAT - VIES Declaration Disk" with SkipCustomerDataCheck disabled
        asserterror RunReportVATVIESDeclarationDisk(VATEntry);
        // Request Page handled by VATVIESDeclarationDiskRequestPageHandler

        // [THEN] Error pops up: VAT Registration No. must have a value in Customer: No.=%1. It cannot be zero or empty.
        Assert.ExpectedTestFieldError(Customer.FieldCaption("VAT Registration No."), '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reports DE");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reports DE");
        NoSeriesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reports DE");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        CompanyInformation: Record "Company Information";
        Customer: Record Customer;
    begin
        CompanyInformation.Get();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code"));
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using Random for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndPostSalesDocument(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure NoSeriesSetup()
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        PurchaseSetup.Get();
        PurchaseSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchaseSetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);
    end;

    local procedure CalculateInventoryValuationTotal(ItemNo: Code[20]): Decimal
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Cost Amount (Expected)", "Cost Amount (Actual)");
        exit(ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Amount (Actual)");  // Calculated Values required for test.
    end;

    local procedure CreateAndPostPurchaseOrderWithTwoLines(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; Invoice: Boolean): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithDirectUnitCost(PurchaseHeader, PurchaseLine, ItemNo, Quantity, DirectUnitCost);
        CreatePurchaseLineWithDirectUnitCost(PurchaseHeader, PurchaseLine, ItemNo2, Quantity, DirectUnitCost);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice));  // Use True for Receive.
    end;

    local procedure CreateAndPostPurchaseOrdersAsInvoiceAndReceive(var PurchaseHeader: Record "Purchase Header"; var DocumentNo: Code[20]; var DocumentNo2: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        DocumentNo :=
          CreateAndPostPurchaseOrderWithTwoLines(PurchaseHeader, ItemNo, ItemNo2, Quantity, DirectUnitCost, true);  // Use True For Invoice.
        DocumentNo2 := CreateAndPostPurchaseOrderWithTwoLines(PurchaseHeader, ItemNo, ItemNo2, Quantity * 2, DirectUnitCost, false);
    end;

    local procedure CreateAndPostSalesOrderWithTwoLines(ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; Quantity2: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithUnitPrice(SalesHeader, ItemNo, Quantity);
        CreateSalesLineWithUnitPrice(SalesHeader, ItemNo2, Quantity2);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));  // Use True for Ship.
    end;

    local procedure CreateEUCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Validate("EU Country/Region Code", CountryRegion.Code);
        CountryRegion.Validate("VAT Scheme", LibraryUtility.GenerateGUID());
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateItemsWithCostingMethodAndInvtPostingGroup(var Item: Record Item; var Item2: Record Item)
    begin
        CreateItemWithCostingMethod(Item, Item."Costing Method"::LIFO);
        CreateItemWithCostingMethod(Item2, Item."Costing Method"::FIFO);
        UpdateInventoryPostingGroupOnItem(Item2, Item."Inventory Posting Group");
    end;

    local procedure CreateItemWithCostingMethod(var Item: Record Item; CostingMethod: Enum "Costing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
    end;

    local procedure CreatePurchaseLineWithDirectUnitCost(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVATEntryForCustomer(Customer: Record Customer; var VATEntry: Record "VAT Entry")
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."Bill-to/Pay-to No." := Customer."No.";
        VATEntry."VAT Registration No." := Customer."VAT Registration No.";
        VATEntry."Country/Region Code" := Customer."Country/Region Code";
        VATEntry.Base := LibraryRandom.RandDecInRange(10, 20, 2);
        VATEntry.Insert();
    end;

    local procedure CreateSalesLineWithUnitPrice(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Posting Date", WorkDate());
        VATEntry.FindFirst();
    end;

    local procedure EnqueueValuesForVATVIESRequestPage(FileVersion: Text; FileVersion2: Text; SkipCustDataCheck: Boolean)
    begin
        LibraryVariableStorage.Enqueue(FileVersion);
        LibraryVariableStorage.Enqueue(FileVersion2);
        LibraryVariableStorage.Enqueue(SkipCustDataCheck);
    end;

    local procedure PostPurchaseOrderAfterUpdateDirectUnitCost(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; ItemNo2: Code[20]; DirectUnitCost: Decimal; PartialInvoice: Boolean): Code[20]
    begin
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        UpdateDirectUnitCostOnPurchaseLine(PurchaseHeader."No.", ItemNo, DirectUnitCost, PartialInvoice);
        UpdateDirectUnitCostOnPurchaseLine(PurchaseHeader."No.", ItemNo2, DirectUnitCost, PartialInvoice);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));  // Use True for Invoice.
    end;

    local procedure RunInventoryValue(ItemNoFilter: Text)
    begin
        LibraryVariableStorage.Enqueue(ItemNoFilter);  // Enqueue for InventoryValueRequestPageHandler.
        Commit();  // Commit required for InventoryValueRequestPageHandler.
        REPORT.Run(REPORT::"Inventory Value (Help Report)");
    end;

    local procedure RunReportVATVIESDeclarationDisk(var VATEntry: Record "VAT Entry"): Text[1024]
    var
        VATVIESDeclarationDisk: Report "VAT- VIES Declaration Disk";
    begin
        VATVIESDeclarationDisk.SetTableView(VATEntry);
        VATVIESDeclarationDisk.InitializeRequest(true);
        VATVIESDeclarationDisk.RunModal();
        exit(VATVIESDeclarationDisk.GetFileName());
    end;

    local procedure UpdateDirectUnitCostOnPurchaseLine(DocumentNo: Code[20]; ItemNo: Code[20]; DirectUnitCost: Decimal; PartialInvoice: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        if PartialInvoice then
            PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice" / 2);  // Use Partial Quantity to Invoice.
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateCountryAndVATRegNoOnVATEntry(var VATEntry: Record "VAT Entry")
    begin
        VATEntry.Validate("Country/Region Code", CreateEUCountryRegion());
        VATEntry.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(VATEntry."Country/Region Code"));
        VATEntry.Modify(true);
    end;

    local procedure UpdateCountryCodeOnCustomer(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer.Modify();
    end;

    local procedure UpdateInventoryPostingGroupOnItem(var Item: Record Item; InventoryPostingGroupCode: Code[20])
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        InventoryPostingGroup.SetFilter(Code, '<>%1', InventoryPostingGroupCode);
        InventoryPostingGroup.FindFirst();
        Item.Validate("Inventory Posting Group", InventoryPostingGroup.Code);
        Item.Modify(true);
    end;

    local procedure DeleteCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Delete();
    end;

    local procedure VerifyInventoryValuationExpectedOnInventoryValue(Item: Record Item)
    begin
        LibraryReportDataset.SetRange('PostingGroupCode', Item."Inventory Posting Group");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'PostingGroupCode', Item."Inventory Posting Group");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'PostingGroupInvValuationTotal', CalculateInventoryValuationTotal(Item."No."));
    end;

    local procedure VerifyValueEntries(DocumentNo: Code[20]; DocumentNo2: Code[20]; DocumentNo3: Code[20]; DocumentNo4: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal; Partial: Boolean)
    var
        ValueEntry: Record "Value Entry";
    begin
        // Calculated values required for Cost Amount Expected, Cost Amount Actual and True for Adjustment.
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Purchase, DocumentNo, ItemNo, false, 0, Quantity * DirectUnitCost);
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Purchase, DocumentNo2, ItemNo, false, 2 * Quantity * DirectUnitCost, 0);
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Sale, DocumentNo3, ItemNo, false, -Quantity * DirectUnitCost, 0);
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Purchase, DocumentNo, ItemNo2, false, 0, Quantity * DirectUnitCost);
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Purchase, DocumentNo2, ItemNo2, false, 2 * Quantity * DirectUnitCost, 0);
        VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Sale, DocumentNo3, ItemNo2, false, -2 * Quantity * DirectUnitCost, 0);
        if Partial then begin
            VerifyValueEntry(
              ValueEntry."Item Ledger Entry Type"::Purchase, DocumentNo4, ItemNo, false, -Quantity * DirectUnitCost,
              Quantity * (DirectUnitCost + DirectUnitCost / 2));
            VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Sale, DocumentNo3, ItemNo, true, -Quantity * DirectUnitCost / 4, 0);
            VerifyValueEntry(
              ValueEntry."Item Ledger Entry Type"::Purchase, DocumentNo4, ItemNo2, false,
              -Quantity * DirectUnitCost, Quantity * (DirectUnitCost + DirectUnitCost / 2));
            VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Sale, DocumentNo3, ItemNo2, true, -Quantity * DirectUnitCost / 4, 0);
        end else begin
            VerifyValueEntry(
              ValueEntry."Item Ledger Entry Type"::Purchase, DocumentNo4, ItemNo, false, -2 * Quantity * DirectUnitCost,
              2 * Quantity * (DirectUnitCost + DirectUnitCost / 2));
            VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Sale, DocumentNo3, ItemNo, true, -Quantity * DirectUnitCost / 2, 0);
            VerifyValueEntry(
              ValueEntry."Item Ledger Entry Type"::Purchase, DocumentNo4, ItemNo2, false,
              -2 * Quantity * DirectUnitCost, 2 * Quantity * (DirectUnitCost + DirectUnitCost / 2));
            VerifyValueEntry(ValueEntry."Item Ledger Entry Type"::Sale, DocumentNo3, ItemNo2, true, -Quantity * DirectUnitCost / 2, 0);
        end;
    end;

    local procedure VerifyValueEntry(ItemLedgerEntryType: Enum "Item Ledger Entry Type"; DocumentNo: Code[20]; ItemNo: Code[20]; Adjustment: Boolean; CostAmountExpected: Decimal; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange(Adjustment, Adjustment);
        ValueEntry.FindFirst();
        Assert.AreNearlyEqual(
          CostAmountExpected, ValueEntry."Cost Amount (Expected)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValueMustBeEqualErr, ValueEntry.FieldCaption("Cost Amount (Expected)"), CostAmountExpected));
        Assert.AreNearlyEqual(
          CostAmountActual, ValueEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValueMustBeEqualErr, ValueEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValueRequestPageHandler(var InventoryValue: TestRequestPage "Inventory Value (Help Report)")
    var
        ItemNoFilter: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNoFilter);
        InventoryValue.Item.SetFilter("No.", ItemNoFilter);
        InventoryValue.StatusDate.SetValue(WorkDate());
        InventoryValue.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationDiskRequestPageHandler(var VATVIESDeclarationDisk: TestRequestPage "VAT- VIES Declaration Disk")
    begin
        VATVIESDeclarationDisk.FileVersion.SetValue(LibraryVariableStorage.DequeueText());
        VATVIESDeclarationDisk."FileVersion 2".SetValue(LibraryVariableStorage.DequeueText());
        VATVIESDeclarationDisk.SkipCustomerDataCheck.SetValue(LibraryVariableStorage.DequeueBoolean());
        VATVIESDeclarationDisk.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationDiskReqPageHandler(var VATVIESDeclarationDisk: TestRequestPage "VAT- VIES Declaration Disk")
    begin
        Assert.IsTrue(VATVIESDeclarationDisk.FileVersion.Visible(), 'File version (Elster online) field has to be visible');
        Assert.IsTrue(VATVIESDeclarationDisk."FileVersion 2".Visible(), 'File version 2 (Elster online) field has to be visible');
        Assert.IsTrue(
          VATVIESDeclarationDisk.ShowAmtInAddRepCurr.Visible(), 'Show Amounts in Add. Reporting Currency field has to be visible');
        VATVIESDeclarationDisk.Cancel().Invoke();
    end;
}

