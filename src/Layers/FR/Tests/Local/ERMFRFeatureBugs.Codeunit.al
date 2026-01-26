codeunit 144015 "ERM FR Feature Bugs"
{
    //
    //   1. Test to verify that Book Value is zero when the TAX Depreciation Book achieves the Depreciation End Date.
    //   2. Test to verify that Derogatory Amount is only visible in the TAX Depreciation Book.
    //   3. Test to verify that Derogatory Entries are considered only in the TAX Depreciation Book.
    //   4. Test to verify that after posting FA GL Journal there are entries with right FA Posting Date in FA Ledger Entries.
    //   5. Test to verify that Posted Sales Invoice is created successfully with Lot Tracking in Item Ledger Entry.
    //   6. Test to verify that Sales Invoice is printed with associated Shipment after posting Sales Invoice with GetShipmentLine.
    //   7. Test to verify that Sales Invoice is printed without associated Shipment after posting Sales Invoice with GetShipmentLine.
    //   8. Test to verify that relation between Sales Invoice and Sales Shipment is recorded in Shipment Invoiced Table after posting Sales Invoice with GetShipmentLine.
    //   9. Test to verify that relation between Sales Invoice Lines and Sales Shipment Lines is recorded in Shipment Invoiced Table.
    //  10. Test to verify that relation between Sales Invoice and Sales Shipment is recorded in Shipment Invoiced Table.
    //  11. Test to verify VAT Prod. Posting Group on Purchase Line When changed through Vat Rate Change Setup Page.
    //  12. Test to verify Dimension on Payment Slip flow form Vendor.
    //  13. Test to verify Dimension on Payment Slip flow form Customer.
    //
    //   Covers Test Cases for WI - 344026
    //   ----------------------------------------------------------------------------------
    //   Test Function Name                                                       TFS ID
    //   ----------------------------------------------------------------------------------
    //   BookValueAfterPostDepreciationAndDerogatoryFAJnl                         343466
    //   DerogatoryAmountAfterPostDepreciationAndDerogatoryFAJnl                  342860
    //   DerogatoryEntriesAfterPostDepreciationAndDerogatoryFAJnl                 342818
    //   PostingDatesAfterPostDepreciationAndDerogatoryFAJnl                      342877
    //   PostedSalesInvoiceWithDecimalLotTrackingAndProdBOM                       341056
    //   SalesInvoiceWithShipmentOnSalesInvoiceReport                             152143
    //   SalesInvoiceWithoutShipmentOnSalesInvoiceReport                          152602
    //   ShipmentInvoicedForPostedSalesInvoiceGetShipmentLine                     152142
    //   ShipmentInvoicedForMultiLinePostedSalesInvoice                           152141
    //   ShipmentInvoicedForSingleLinePostedSalesInvoice                          152140
    //
    //   Covers Test Cases for WI - 344431.
    //   ----------------------------------------------------------------------------------
    //   Test Function Name                                                       TFS ID
    //   ----------------------------------------------------------------------------------
    //   VATProdPostingGroupVATRateChangePurchaseLine                             300903
    //   DefaultDimensionCodeForVendorOnPaymentSlip                               291748
    //   DefaultDimensionCodeForCustomerOnPaymentSlip                             291748

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryFRLocalization: Codeunit "Library - FR Localization";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure BookValueAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // Test to verify that Book Value is zero when the TAX Depreciation Book achieves the Depreciation End Date.

        // Setup: Create a Fixed Asset with two FA Depreciation Books. Create and post Acquisition Cost for the Fixed Asset.
        Initialize();
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);  // Large random Integer value required.
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');  // Blank Derogatory Calculation.
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, 2 * AcquisitionCostAmount);

        // Exercise: Create and post FA GL Journal Type Depreciation and Derogatory.
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, AcquisitionCostAmount);

        // Verify: Verify that Book Value is zero when the TAX Depreciation Book achieves the Depreciation End Date.
        FADepreciationBook.Get(FANo, TaxDepreciationBookCode);
        FADepreciationBook.CalcFields("Book Value");
        FADepreciationBook.TestField("Book Value", 0);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DerogatoryAmountAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // Test to verify that Derogatory Amount is only visible in the TAX Depreciation Book.

        // Setup: Create a Fixed Asset with two FA Depreciation Books. Create and post Acquisition Cost for the Fixed Asset.
        Initialize();
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);  // Large random Integer value required.
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');  // Blank Derogatory Calculation.
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, 2 * AcquisitionCostAmount);
        RunCalculateDepreciationReport(NormalDepreciationBookCode);  // Calculate Depreciation.

        // Exercise: Create and post FA GL Journal Type Depreciation and Derogatory.
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, AcquisitionCostAmount);

        // Verify: Verify that Derogatory Amount is only visible in the TAX Depreciation Book.
        FADepreciationBook.Get(FANo, TaxDepreciationBookCode);
        FADepreciationBook.CalcFields(Derogatory);
        FADepreciationBook.TestField(Derogatory, -AcquisitionCostAmount);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DerogatoryEntriesAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // Test to verify that Derogatory Entries are considered only in the TAX Depreciation Book.

        // Setup: Create a Fixed Asset with two FA Depreciation Books. Create and post Acquisition Cost for the Fixed Asset.
        Initialize();
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);  // Large random Integer value required.
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');  // Blank Derogatory Calculation.
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, 2 * AcquisitionCostAmount);
        RunCalculateDepreciationReport(NormalDepreciationBookCode);  // Calculate Depreciation.

        // Exercise: Create and post FA GL Journal Type Depreciation and Derogatory.
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, AcquisitionCostAmount);

        // Verify: Verify that Derogatory Entries are considered only in the TAX Depreciation Book.
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::"Acquisition Cost", WorkDate(), 2 * AcquisitionCostAmount);
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::Derogatory, CalcDate('<1M>', WorkDate()), -AcquisitionCostAmount);
        VerifyFALedgerEntries(
          FANo, FALedgerEntry."FA Posting Type"::Depreciation, CalcDate('<1Y>', WorkDate()), -AcquisitionCostAmount);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceWithDecimalLotTrackingAndProdBOM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvoiceNo: Code[20];
        ItemNo: Code[20];
        TrackingQuantity: Decimal;
    begin
        // Test to verify that Posted Sales Invoice is created successfully with Lot Tracking in Item Ledger Entry.

        // Setup: Create Parent and Child Items with Lot Tracking, update Item Inventory, create a Sales Order with Lot Tracking.
        Initialize();
        ItemNo := CreateCertifiedProductionBOMWithLotTrackedItem();
        TrackingQuantity := LibraryRandom.RandDec(10, 2);  // Decimal random value required for the bug.
        CreateAndPostItemJournalLineWithLotTracking(ItemNo, TrackingQuantity);
        CreateSalesOrderWithLotTracking(SalesHeader, ItemNo, TrackingQuantity);

        // Exercise: Post Sales Order as Ship and Invoice.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify the Posted Sales Invoice is created successfully with Lot Tracking as decimal value in Item Ledger Entry.
        VerifyPostedSalesInvoice(InvoiceNo, SalesLine.Type::Item, TrackingQuantity, SalesHeader."Sell-to Customer No.");
        VerifyItemLedgerEntry(ItemNo, -TrackingQuantity, Format(TrackingQuantity), SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationRequestPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostingDatesAfterPostDepreciationAndDerogatoryFAJnl()
    var
        FALedgerEntry: Record "FA Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        AcquisitionCostAmount: Integer;
        FANo: Code[20];
        NormalDepreciationBookCode: Code[10];
        TaxDepreciationBookCode: Code[10];
    begin
        // Test to verify that after posting FA GL Journal there are entries with right FA Posting Date in FA Ledger Entries.

        // Setup: Create a Fixed Asset with two FA Depreciation Books. Create and post Acquisition Cost for the Fixed Asset.
        Initialize();
        AcquisitionCostAmount := LibraryRandom.RandIntInRange(10000, 20000);  // Large random Integer value required.
        NormalDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation('');  // Blank Derogatory Calculation.
        FANo := CreateFAWithTaxFADepreciationBookAndGLIntegration(TaxDepreciationBookCode, NormalDepreciationBookCode);
        CreateAndPostGenJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."FA Posting Type"::"Acquisition Cost", FANo,
          NormalDepreciationBookCode, AcquisitionCostAmount);
        RunCalculateDepreciationReport(NormalDepreciationBookCode);  // Calculate Depreciation.

        // Exercise: Create and post FA GL Journal Type Depreciation and Derogatory with Derogatory Amount Zero.
        CreatePostDepreciationAndDerogatoryFAJournal(FANo, NormalDepreciationBookCode, AcquisitionCostAmount, 0);

        // Verify: Verify that after posting FA GL Journal there are entries with right FA Posting Date in FA Ledger Entries.
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::"Acquisition Cost", WorkDate(), AcquisitionCostAmount);
        VerifyFALedgerEntries(FANo, FALedgerEntry."FA Posting Type"::Derogatory, CalcDate('<1M>', WorkDate()), 0);
        VerifyFALedgerEntries(
          FANo, FALedgerEntry."FA Posting Type"::Depreciation, CalcDate('<1Y>', WorkDate()), -AcquisitionCostAmount);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentInvoicedForPostedSalesInvoiceGetShipmentLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ShipmentInvoiced: Record "Shipment Invoiced";
        InvoiceNo: Code[20];
    begin
        // Test to verify that relation between Sales Invoice and Sales Shipment is recorded in Shipment Invoiced Table after
        // posting Sales Invoice with GetShipmentLine.

        // Setup: Create a Sales Shipment and Sales Invoice. Invoke GetShipmentLine function on Sales Invoice created.
        Initialize();
        SalesShipmentLine.Get(CreateShipmentAndSalesInvoice(SalesLine), SalesLine."Line No.");
        LibrarySales.GetShipmentLines(SalesLine);  // Invokes GetShipmentLinesPageHandler.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Post the Sales Invoice.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that relation between Sales Invoice and Sales Shipment is recorded in Shipment Invoiced Table.
        SalesInvoiceLine.Get(InvoiceNo, 20000);  // Used for next Line No.
        ShipmentInvoiced.Get(InvoiceNo, SalesInvoiceLine."Line No.", SalesShipmentLine."Document No.", SalesShipmentLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentInvoicedForMultiLinePostedSalesInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceLine2: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesShipmentLine2: Record "Sales Shipment Line";
        ShipmentInvoiced: Record "Shipment Invoiced";
        InvoiceNo: Code[20];
        ShipmentNo: Code[20];
    begin
        // Test to verify that relation between Sales Invoice Lines and Sales Shipment Lines is recorded in Shipment Invoiced Table.

        // Setup: Create Customer, create a Sales Order with multiple Sales Lines and post as Ship.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        // Use random values for Quantity.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", CreateItem(), LibraryRandom.RandDec(10, 2));
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship only.

        // Exercise: Post the Sales Invoice.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);  // Post as Invoice Only.

        // Verify: Verify that relation between Sales Invoice Lines and Sales Shipment Lines is recorded in Shipment Invoiced Table.
        SalesShipmentLine.Get(ShipmentNo, SalesLine."Line No.");
        SalesShipmentLine2.Get(ShipmentNo, SalesLine2."Line No.");
        SalesInvoiceLine.Get(InvoiceNo, SalesShipmentLine."Line No.");
        SalesInvoiceLine2.Get(InvoiceNo, SalesShipmentLine2."Line No.");
        ShipmentInvoiced.Get(InvoiceNo, SalesInvoiceLine."Line No.", ShipmentNo, SalesShipmentLine."Line No.");
        ShipmentInvoiced.Get(InvoiceNo, SalesInvoiceLine2."Line No.", ShipmentNo, SalesShipmentLine2."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipmentInvoicedForSingleLinePostedSalesInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ShipmentInvoiced: Record "Shipment Invoiced";
        InvoiceNo: Code[20];
        ShipmentNo: Code[20];
    begin
        // Test to verify that relation between Sales Invoice and Sales Shipment is recorded in Shipment Invoiced Table.

        // Setup: Create Customer, create a Sales Order and post as Ship.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        ShipmentNo := CreateAndPostSalesOrderAsShip(SalesLine, Customer."No.");
        SalesShipmentHeader.Get(ShipmentNo);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesShipmentHeader."Order No.");

        // Exercise: Post Sales Invoice.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Verify: Verify that relation between Sales Invoice and Sales Shipment is recorded in Shipment Invoiced Table.
        ShipmentInvoiced.SetRange("Invoice No.", InvoiceNo);
        ShipmentInvoiced.SetRange("Shipment No.", ShipmentNo);
        ShipmentInvoiced.FindFirst();
    end;

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultDimensionCodeForVendorOnPaymentSlip()
    var
        DefaultDimension: Record "Default Dimension";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentLine: Record "Payment Line";
    begin
        // Test to verify Dimension on Payment Slip flow form Vendor.

        // Setup: Create Vendor with dimension,Default dimension code on Payment Slip for Vendor.
        Initialize();
        CreateAndUpdateVendorWithDimension(DefaultDimension);
        DefaultDimensionCodeOnPaymentSlip(
          PaymentStepLedger.Sign::Credit, PaymentLine."Account Type"::Vendor, DefaultDimension."No.", DefaultDimension."Dimension Code");
    end;

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultDimensionCodeForCustomerOnPaymentSlip()
    var
        DefaultDimension: Record "Default Dimension";
        PaymentStepLedger: Record "Payment Step Ledger";
        PaymentLine: Record "Payment Line";
    begin
        // Test to verify Dimension on Payment Slip flow form Cusotmer.

        // Setup: Create Customer with dimension,Default dimension code on Payment Slip for Customer.
        Initialize();
        CreateAndUpdateCustomerWithDimension(DefaultDimension);
        DefaultDimensionCodeOnPaymentSlip(
          PaymentStepLedger.Sign::Debit, PaymentLine."Account Type"::Customer, DefaultDimension."No.", DefaultDimension."Dimension Code");
    end;

    [Test]
    [HandlerFunctions('PaymentClassListPageHandler')]
    procedure CreateAndPostPaymentSlipForIncompleteDimension()
    var
        DefaultDimension: Record "Default Dimension";
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
    begin
        // [SCENARIO 308571] Creating 'Payment Line' for Vendor with empty 'Dimension Value Code' in 'Default Dimension' doesn't throw error
        Initialize();

        // [GIVEN] Created Vendor with 'Default Dimension' with empty 'Dimension Value Code'
        CreateAndUpdateVendorWithIncompleteDimension(DefaultDimension);

        // [WHEN] Create 'Payment Line' for that Vendor
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentHeader."No.");
        PaymentLine.Validate("Account Type", PaymentLine."Account Type"::Vendor);
        PaymentLine.Validate("Account No.", DefaultDimension."No.");
        PaymentLine.Modify(true);

        // [THEN] No error thrown, and invalid Dimension Set Entry is not created
        PaymentLine.TestField("Dimension Set ID", 0);
    end;

    local procedure DefaultDimensionCodeOnPaymentSlip(Sign: Option; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DimensionCode: Code[10])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetID: Integer;
    begin
        CreatePaymentStatus(CreatePaymentClass(), Sign);

        // Exercise: Create Payment Slip.
        DimensionSetID := CreatePaymentSlip(AccountType, AccountNo);

        // Verify: Verify Dimension Code on Dimension Set Entry.
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.FindFirst();
        DimensionSetEntry.TestField("Dimension Code", DimensionCode);
    end;

    local procedure Initialize()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.DeleteAll();
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostItemJournalLineWithLotTracking(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue value for use in ItemTrackingPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostSalesOrderAsShip(var SalesLine: Record "Sales Line"; SelltoCustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Order and post. Use random value for Quantity.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, SelltoCustomerNo, CreateItem(), LibraryRandom.RandDec(10, 2));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));  // Post as Ship Only.
    end;

    local procedure CreateAndSetupDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreateAndUpdateCustomerWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateCertifiedProductionBOMWithLotTrackedItem(): Code[20]
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // True for Lot Tracking.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(true));

        // Random value taken for Quantity per.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CreateItem(), LibraryRandom.RandInt(5));
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateDepreciationBookAndModifyDerogatoryCalculation(DerogatoryCalculation: Code[10]): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateAndSetupDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("Use Same FA+G/L Posting Dates", false);
        DepreciationBook.Validate("Derogatory Calculation", DerogatoryCalculation);
        DepreciationBook.Modify(true);
        exit(DepreciationBook.Code);
    end;

    local procedure CreateFADepreciationBook(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());

        // Use random value for Depreciation Ending Date.
        FADepreciationBook.Validate(
          "Depreciation Ending Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAWithTaxFADepreciationBookAndGLIntegration(var TaxDepreciationBookCode: Code[10]; NormalDepreciationBookCode: Code[10]): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        UpdateIntegrationInBook(NormalDepreciationBookCode);
        TaxDepreciationBookCode := CreateDepreciationBookAndModifyDerogatoryCalculation(NormalDepreciationBookCode);
        CreateFixedAssetAndUpdateFAPostingGroup(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", NormalDepreciationBookCode, FixedAsset."FA Posting Group");
        CreateFADepreciationBook(FixedAsset."No.", TaxDepreciationBookCode, FixedAsset."FA Posting Group");
        exit(FixedAsset."No.");
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset")
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFixedAssetAndUpdateFAPostingGroup(var FixedAsset: Record "Fixed Asset")
    begin
        CreateFixedAsset(FixedAsset);
        UpdateFAPostingGroup(FixedAsset."FA Posting Group");
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; FAPostingDate: Date; FAPostingType: Enum "Gen. Journal Line FA Posting Type"; FANo: Code[20]; DepreciationBookCode: Code[10]; Amount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type"::"Fixed Asset", FANo, Amount);
        GenJournalLine.Validate("FA Posting Type", FAPostingType);
        GenJournalLine.Validate("FA Posting Date", FAPostingDate);
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateItemTrackingCode(LotSpecificTracking: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, LotSpecificTracking);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LotSpecificTracking);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreatePaymentClass(): Text[30]
    var
        PaymentClass: Record "Payment Class";
    begin
        LibraryFRLocalization.CreatePaymentClass(PaymentClass);
        PaymentClass.Validate("Header No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        PaymentClass.Validate(Suggestions, PaymentClass.Suggestions::Vendor);
        PaymentClass.Modify(true);
        exit(PaymentClass.Code);
    end;

    local procedure CreatePaymentStatus(PaymentClass: Text[30]; Sign: Option)
    var
        PaymentStatus: Record "Payment Status";
        PaymentStep: Record "Payment Step";
        PaymentStepLedger: Record "Payment Step Ledger";
    begin
        LibraryFRLocalization.CreatePaymentStatus(PaymentStatus, PaymentClass);
        PaymentStatus.Validate(RIB, true);
        PaymentStatus.Validate(Look, true);
        PaymentStatus.Validate(ReportMenu, true);
        PaymentStatus.Validate("Acceptation Code", true);
        PaymentStatus.Validate(Debit, true);
        PaymentStatus.Validate(Credit, true);
        PaymentStatus.Validate("Bank Account", true);
        PaymentStatus.Modify(true);
        LibraryFRLocalization.CreatePaymentStep(PaymentStep, PaymentClass);
        LibraryFRLocalization.CreatePaymentStepLedger(PaymentStepLedger, PaymentClass, Sign, PaymentStep.Line);
    end;

    local procedure CreatePaymentSlip(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Integer
    var
        PaymentHeader: Record "Payment Header";
        PaymentLine: Record "Payment Line";
    begin
        LibraryFRLocalization.CreatePaymentHeader(PaymentHeader);
        LibraryFRLocalization.CreatePaymentLine(PaymentLine, PaymentHeader."No.");
        PaymentLine.Validate("Account Type", AccountType);
        PaymentLine.Validate("Account No.", AccountNo);
        PaymentLine.Modify(true);
        exit(PaymentLine."Dimension Set ID");
    end;

    local procedure CreatePostDepreciationAndDerogatoryFAJournal(FANo: Code[20]; DepreciationBookCode: Code[10]; DepreciationAmount: Decimal; DerogatoryAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostGenJournalLine(
          GenJournalLine, CalcDate('<1Y>', WorkDate()), GenJournalLine."FA Posting Type"::Depreciation, FANo,
          DepreciationBookCode, -DepreciationAmount);
        CreateAndPostGenJournalLine(
          GenJournalLine, CalcDate('<1M>', WorkDate()), GenJournalLine."FA Posting Type"::Derogatory, FANo,
          DepreciationBookCode, -DerogatoryAmount);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);  // Use random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use random value for Unit Price.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithLotTracking(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue value for use in ItemTrackingPageHandler.
        SalesLine.OpenItemTrackingLines();  // Invokes ItemTrackingPageHandler.
    end;

    local procedure CreateShipmentAndSalesInvoice(var SalesLine: Record "Sales Line"): Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        ShipmentNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue value for use in GetShipmentLinesPageHandler.
        ShipmentNo := CreateAndPostSalesOrderAsShip(SalesLine2, Customer."No.");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", SalesLine2."Line No.");
        exit(ShipmentNo);
    end;

    local procedure CreateAndUpdateVendorWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateAndUpdateVendorWithIncompleteDimension(var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", Dimension.Code, '');
    end;

    local procedure RunCalculateDepreciationReport(DepreciationBookCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(DepreciationBookCode);
        REPORT.Run(REPORT::"Calculate Depreciation");
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FAJournalSetup2.SetRange("Depreciation Book Code", FASetup."Default Depr. Book");
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    local procedure UpdateFAPostingGroup(FAPostingGroupCode: Code[20])
    var
        FAPostingGroup: Record "FA Posting Group";
        FAPostingGroup2: Record "FA Posting Group";
        RecordRef: RecordRef;
    begin
        FAPostingGroup.Get(FAPostingGroupCode);
        FAPostingGroup2.SetFilter("Acquisition Cost Account", '<>''''');
        RecordRef.GetTable(FAPostingGroup2);
        LibraryUtility.FindRecord(RecordRef);
        RecordRef.SetTable(FAPostingGroup2);
        FAPostingGroup.TransferFields(FAPostingGroup2, false);
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateIntegrationInBook(DepreciationBookCode: Code[10])
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Derogatory", true);
        DepreciationBook.Modify(true);
    end;

    local procedure VerifyFALedgerEntries(FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; FAPostingDate: Date; Amount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetRange("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindSet();
        repeat
            FALedgerEntry.TestField("FA Posting Date", FAPostingDate);
            FALedgerEntry.TestField(Amount, Amount);
        until FALedgerEntry.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[20]; SourceNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Source No.", SourceNo);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item Tracking", ItemLedgerEntry."Item Tracking"::"Lot No.");
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedSalesInvoice(DocumentNo: Code[20]; Type: Enum "Sales Line Type"; Quantity: Decimal; SellToCustomerNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Type, Type);
        SalesInvoiceLine.TestField("Sell-to Customer No.", SellToCustomerNo);
        SalesInvoiceLine.TestField(Quantity, Quantity);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateDepreciationRequestPageHandler(var CalculateDepreciation: TestRequestPage "Calculate Depreciation")
    var
        DepreciationBookCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DepreciationBookCode);
        CalculateDepreciation.DepreciationBook.SetValue(DepreciationBookCode);
        CalculateDepreciation.FAPostingDate.SetValue(WorkDate());
        CalculateDepreciation.PostingDate.SetValue(WorkDate());
        CalculateDepreciation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    var
        SellToCustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SellToCustomerNo);
        GetShipmentLines.FILTER.SetFilter("Sell-to Customer No.", SellToCustomerNo);
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingQuantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(TrackingQuantity);
        ItemTrackingLines."Lot No.".SetValue(TrackingQuantity);
        ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentClassListPageHandler(var PaymentClassList: TestPage "Payment Class List")
    begin
        PaymentClassList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
