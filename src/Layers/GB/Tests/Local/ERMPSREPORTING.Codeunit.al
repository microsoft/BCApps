codeunit 144061 "ERM PSREPORTING"
{
    // Test for PSREPORTING feature.
    // 
    // 1. Verify Cost Amount(Expected) on Sales Analysis Matrix when Item Ledger Entry Type Filter Sales.
    // 2. Verify Cost Amount(Expected) on Sales Analysis Matrix when Item Ledger Entry Type Filter Purchase.
    // 3. Verify Area Code is updated on Inventory Analysis Area for Item with Dimension.
    // 
    //   Covers Test cases:
    //  --------------------------------------------------------------------------------------------------
    //   Test Function                                                                            TFS ID
    //  --------------------------------------------------------------------------------------------------
    //   SalesAnalysisReportWithItemLedgerEntryTypeSales                                          176473
    //   PurchaseAnalysisReportWithItemLedgerEntryTypePurchase                                    176474
    //   ItemDimensionWithInventoryAnalysisArea                                                   250597

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('SalesAnalysisReportPageHandler,SalesAnalysisMatrixPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportWithItemLedgerEntryTypeSales()
    var
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisView: Record "Item Analysis View";
        SalesHeader: Record "Sales Header";
        ValueEntry: Record "Value Entry";
        ValueEntry2: Record "Value Entry";
        Customer: Record Customer;
        SalesHeader2: Record "Sales Header";
        AnalysisLine: Record "Analysis Line";
        AnalysisReportName: Code[10];
    begin
        // Verify Cost Amount(Expected) on Sales Analysis Matrix when Item Ledger Entry Type Filter Sales.

        // Setup: Post Sales Invoice with Ship Option and Create Analysis Report Name.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesInvoice(SalesHeader, Customer."No.");
        FindValueEntry(ValueEntry, LibrarySales.PostSalesDocument(SalesHeader, true, false));

        // Create Sales Invoice with same Customer on different Posting Date.
        CreateSalesInvoice(SalesHeader2, Customer."No.");
        UpdateSalesHeaderPostingDate(SalesHeader2);
        FindValueEntry(ValueEntry2, LibrarySales.PostSalesDocument(SalesHeader2, true, false));
        AnalysisReportName :=
          CreateItemAnalysisSetup(
            ItemAnalysisView, ValueEntry."Cost Amount (Expected)" + ValueEntry2."Cost Amount (Expected)",
            ItemAnalysisView."Analysis Area"::Sales);

        // Exercise: Open Analysis Report Sales with correct filter Item Ledger Entry Type Sales.
        OpenAndEditAnalysisReportSales(AnalysisReportName,
          CreateAnalysisLine(ItemAnalysisView."Analysis Area", AnalysisLine.Type::Customer, SalesHeader."Sell-to Customer No."),
          CreateAnalysisColumnWithItemLedgerEntryType(ItemAnalysisView."Analysis Area",
            Format(ValueEntry."Item Ledger Entry Type"::Sale), AnalysisColumn."Value Type"::"Cost Amount"));

        // Verify: Verification of Cost Amount (Expected) done in SalesAnalysisMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('PurchaseAnalysisReportPageHandler,PurchaseAnalysisMatrixPageHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisReportWithItemLedgerEntryTypePurchase()
    var
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisView: Record "Item Analysis View";
        ValueEntry: Record "Value Entry";
        ValueEntry2: Record "Value Entry";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        AnalysisLine: Record "Analysis Line";
        AnalysisReportName: Code[10];
    begin
        // Verify Cost Amount(Expected) on Sales Analysis Matrix when Item Ledger Entry Type Filter Purchase.

        // Setup: Post Purchase Invoice with Ship Option and Create Analysis Report Name.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseInvoice(PurchaseHeader, Vendor."No.");
        FindValueEntry(ValueEntry, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));

        // Create Purchase Invoice with same Vendor on different Posting Date.
        CreatePurchaseInvoice(PurchaseHeader2, Vendor."No.");
        UpdatePurchaseHeaderPostingDate(PurchaseHeader2);
        FindValueEntry(ValueEntry2, LibraryPurchase.PostPurchaseDocument(PurchaseHeader2, true, false));
        AnalysisReportName :=
          CreateItemAnalysisSetup(
            ItemAnalysisView, ValueEntry."Cost Amount (Expected)" + ValueEntry2."Cost Amount (Expected)",
            ItemAnalysisView."Analysis Area"::Purchase);

        // Exercise: Open Analysis Report Purchase with correct filter Item Ledger Entry Type Purchase.
        OpenAndEditAnalysisReportPurchase(AnalysisReportName,
          CreateAnalysisLine(ItemAnalysisView."Analysis Area", AnalysisLine.Type::Vendor, PurchaseHeader."Buy-from Vendor No."),
          CreateAnalysisColumnWithItemLedgerEntryType(ItemAnalysisView."Analysis Area",
            Format(ValueEntry."Item Ledger Entry Type"::Purchase), AnalysisColumn."Value Type"::"Cost Amount"));

        // Verify: Verification of Cost Amount (Expected) is done in PurchaseAnalysisMatrixPageHandler.
    end;

    [Test]
    [HandlerFunctions('InvtAnalysisByDimensionsPageHandler,InvtAnalysByDimMatrixPageHandler,ItemAnalysisViewEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimensionWithInventoryAnalysisArea()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Area Code for Inventory Analysis Area.

        // Setup: Create Item with Dimension, create and post Item Journal Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateItemDimension(DefaultDimension, Item."No.");
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");

        // Exercise: Open and Edit Analysis View List Inventory. Show Matrix on Item Analysis by Dimension Page.
        OpenAndEditAnalysisViewListInventory(Item."No.", DefaultDimension."Dimension Value Code");

        // Verify: Verification of Area Code is done in ItemAnalysisViewEntriesPageHandler.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SellToCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Using Random Quantity.
    end;

    local procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; BuyFromVendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));  // Using Random Quantity.
    end;

    local procedure CreateAnalysisLine(ItemAnalysisViewAnalysisArea: Enum "Analysis Area Type"; Type: Enum "Analysis Line Type"; Range: Code[20]): Code[10]
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, ItemAnalysisViewAnalysisArea);
        LibraryInventory.CreateAnalysisLine(AnalysisLine, ItemAnalysisViewAnalysisArea, AnalysisLineTemplate.Name);
        AnalysisLine.Validate(Type, Type);
        AnalysisLine.Validate(Range, Range);
        AnalysisLine.Modify(true);
        exit(AnalysisLine."Analysis Line Template Name");
    end;

    local procedure CreateAnalysisColumnWithItemLedgerEntryType(ItemAnalysisViewAnalysisArea: Enum "Analysis Area Type"; ItemLedgerEntryTypeFilter: Text[250]; ValueType: Enum "Analysis Value Type"): Code[10]
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisColumn: Record "Analysis Column";
    begin
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisViewAnalysisArea);
        LibraryERM.CreateAnalysisColumn(AnalysisColumn, ItemAnalysisViewAnalysisArea, AnalysisColumnTemplate.Name);
        AnalysisColumn.Validate("Column No.", CopyStr(LibraryUtility.GenerateGUID(), 1, AnalysisColumn.FieldNo("Column No.")));
        AnalysisColumn.Validate(
          "Column Header",
          CopyStr(
            LibraryUtility.GenerateRandomCode(AnalysisColumn.FieldNo("Column Header"), DATABASE::"Analysis Column"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Analysis Column", AnalysisColumn.FieldNo("Column Header"))));
        AnalysisColumn.Validate("Item Ledger Entry Type Filter", ItemLedgerEntryTypeFilter);
        AnalysisColumn.Validate("Value Type", ValueType);
        Evaluate(AnalysisColumn."Comparison Date Formula", '<' + Format(LibraryRandom.RandIntInRange(2, 5)) + 'M>');  // Posting Date should lies in between Analysis Column Comparison Date Formula.
        AnalysisColumn.Modify(true);
        exit(AnalysisColumnTemplate.Name);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Purchase, ItemNo, LibraryRandom.RandDec(10, 2));  // Use Random Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateItemAnalysisSetup(var ItemAnalysisView: Record "Item Analysis View"; CostAmountExpected: Decimal; AnalysisArea: Enum "Analysis Area Type"): Code[10]
    var
        AnalysisReportName: Record "Analysis Report Name";
    begin
        LibraryVariableStorage.Enqueue(CostAmountExpected); // Required inside SaleAnalysisMatrixPageHandler and PurchaseAnalysisMatrixPageHandler.
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, AnalysisArea);
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area");
        exit(AnalysisReportName.Name);
    end;

    local procedure UpdateSalesHeaderPostingDate(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Posting Date", CalcDate('<' + Format(LibraryRandom.RandInt(3)) + 'M>', WorkDate()));  // Posting Date should lies in between Analysis Column Comparison Date Formula.
        SalesHeader.Modify(true);
    end;

    local procedure UpdatePurchaseHeaderPostingDate(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Posting Date", CalcDate('<' + Format(LibraryRandom.RandInt(3)) + 'M>', WorkDate()));  // Posting Date should lies in between Analysis Column Comparison Date Formula.
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateItemDimension(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; DocumentNo: Code[20])
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
    end;

    local procedure OpenAndEditAnalysisReportSales(Name: Code[10]; AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisReportSale: TestPage "Analysis Report Sale";
    begin
        AnalysisReportSale.OpenEdit();
        AnalysisReportSale.FILTER.SetFilter(Name, Name);
        AnalysisReportSale."Analysis Line Template Name".SetValue(AnalysisLineTemplateName);
        AnalysisReportSale."Analysis Column Template Name".SetValue(AnalysisColumnTemplateName);
        AnalysisReportSale.EditAnalysisReport.Invoke();  // Opens SalesAnalysisReportPageHandler.
    end;

    local procedure OpenAndEditAnalysisReportPurchase(Name: Code[10]; AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisReportPurchase: TestPage "Analysis Report Purchase";
    begin
        AnalysisReportPurchase.OpenEdit();
        AnalysisReportPurchase.FILTER.SetFilter(Name, Name);
        AnalysisReportPurchase."Analysis Line Template Name".SetValue(AnalysisLineTemplateName);
        AnalysisReportPurchase."Analysis Column Template Name".SetValue(AnalysisColumnTemplateName);
        AnalysisReportPurchase.EditAnalysisReport.Invoke();  // Opens PurchaseAnalysisReportPageHandler.
    end;

    local procedure OpenAndEditAnalysisViewListInventory(ItemNo: Code[20]; DimensionValueCode: Code[20])
    var
        AnalysisViewListInventory: TestPage "Analysis View List Inventory";
    begin
        LibraryVariableStorage.Enqueue(ItemNo);  // Required inside InvtAnalysByDimMatrixPageHandler.
        LibraryVariableStorage.Enqueue(DimensionValueCode);  // Required inside ItemAnalysisViewEntriesPageHandler.
        AnalysisViewListInventory.OpenEdit();
        AnalysisViewListInventory."&Update".Invoke();
        AnalysisViewListInventory.EditAnalysisView.Invoke();  // Opens InvtAnalysisByDimensionsPageHandler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportPageHandler(var SalesAnalysisReport: TestPage "Sales Analysis Report")
    var
        SalesPeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        SalesAnalysisReport.PeriodType.SetValue(SalesPeriodType::Month);
        SalesAnalysisReport.ShowMatrix.Invoke();  // Opens SalesAnalysisMatrixPageHandler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisMatrixPageHandler(var SalesAnalysisMatrix: TestPage "Sales Analysis Matrix")
    var
        CostAmountExpected: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostAmountExpected);
        SalesAnalysisMatrix.Field1.AssertEquals(CostAmountExpected);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisReportPageHandler(var PurchaseAnalysisReport: TestPage "Purchase Analysis Report")
    var
        PurchasePeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        PurchaseAnalysisReport.PeriodType.SetValue(PurchasePeriodType::Month);
        PurchaseAnalysisReport.ShowMatrix.Invoke();  // Opens PurchaseAnalysisMatrixPageHandler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisMatrixPageHandler(var PurchaseAnalysisMatrix: TestPage "Purchase Analysis Matrix")
    var
        CostAmountExpected: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostAmountExpected);
        PurchaseAnalysisMatrix.Field1.AssertEquals(CostAmountExpected);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure InvtAnalysisByDimensionsPageHandler(var InvtAnalysisByDimensions: TestPage "Invt. Analysis by Dimensions")
    begin
        InvtAnalysisByDimensions.ShowMatrix.Invoke();  // Opens InvtAnalysByDimMatrixPageHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvtAnalysByDimMatrixPageHandler(var InvtAnalysByDimMatrix: TestPage "Invt. Analys by Dim. Matrix")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        InvtAnalysByDimMatrix.FindFirstField(Code, Code);
        InvtAnalysByDimMatrix.TotalInvtValue.DrillDown();  // Opens ItemAnalysisViewEntriesPageHandler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemAnalysisViewEntriesPageHandler(var ItemAnalysisViewEntries: TestPage "Item Analysis View Entries")
    var
        AreaCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(AreaCode);
        ItemAnalysisViewEntries."Dimension 1 Value Code".AssertEquals(AreaCode);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

