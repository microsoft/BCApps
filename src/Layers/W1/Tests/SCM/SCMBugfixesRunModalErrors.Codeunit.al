codeunit 137041 "SCM Bugfixes Run Modal Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Stockout Warning] [Credit Warnings] [Sales]
        isInitialized := false;
    end;

    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure StockoutSetupFalseNoWarning()
    begin
        // Check Stockout warning does not appear when Stockout setup is FALSE.
        Initialize();
        StockoutWarning(false, false);  // Stockout warning and Drop Shipment.
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure StockoutSetupTrueAndWarning()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check Stockout warning appears when Stockout setup is TRUE.
        Initialize();
        StockoutWarning(true, false);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StockoutDropShipNoWarning()
    begin
        // Check Stockout warning does not appear even when Stockout setup is TRUE, with Drop Shipment.
        Initialize();
        StockoutWarning(true, true);
    end;

    local procedure StockoutWarning(StockoutWarning: Boolean; DropShip: Boolean)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        // Setup.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, SalesReceivablesSetup."Credit Warnings"::"No Warning", StockoutWarning);
        CreateSalesOrderCustCrLimit(SalesLine);
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Drop Shipment"), DropShip);

        // Verify : Check Item Stock Availability without and with Stockout warning.
        Assert.IsFalse(ItemCheckAvail.SalesLineCheck(SalesLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditWarningSetupNoWarning()
    begin
        // Check Credit warning does not appear when Credit warning setup is No Warning.
        Initialize();
        StockoutAndCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"No Warning", false, false, true);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreditLimitWarning()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check Credit warning appears when Credit warning setup is Both Warnings.
        Initialize();
        StockoutAndCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Both Warnings", false, false, true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure StockAndCreditLimitWarning()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check Stock and Credit warning appears when Stockout setup is TRUE and Credit warning setup is Both Warnings.
        Initialize();
        StockoutAndCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Both Warnings", true, false, true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure DropShipCreditLimitWarning()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check Stock and Credit warning when Drop Shipment is True.
        Initialize();
        StockoutAndCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Both Warnings", true, true, true);  // Drop Shipment-TRUE.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure DropShipStockCreditWarning()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check Stock and Credit warning when Drop Shipment is True and after Drop Shipment is False.
        Initialize();
        StockoutAndCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"Both Warnings", true, true, false);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreditWarningStockoutWarning()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check Credit warning does not appear when Credit warning setup is No Warning and Stock Out Warning TRUE.
        Initialize();
        StockoutAndCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"No Warning", true, false, false);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure StockoutAndCreditWarnings(CreditWarnings: Option; StockoutWarning: Boolean; DropShipBefore: Boolean; DropShipAfter: Boolean)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        // Setup.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, CreditWarnings, StockoutWarning);
        CreateSalesOrderCustCrLimit(SalesLine);
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Drop Shipment"), DropShipBefore);

        // Verify: Check Item Stock Availability.
        Assert.IsFalse(ItemCheckAvail.SalesLineCheck(SalesLine), '');

        // Exercise: Update Sales Order line with Item Unit Price.
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Unit Price"), LibraryRandom.RandInt(10));

        // Verify : Check Customer Credit Limit.
        CustCheckCrLimit.SalesLineCheck(SalesLine);

        // Exercise: Update Sales Line with required Drop Shipment value.
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Drop Shipment"), DropShipAfter);

        // Verify: Check Item Stock Availability with Stockout warning.
        Assert.IsFalse(ItemCheckAvail.SalesLineCheck(SalesLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StockEqualNoWarning()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        // Setup.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, SalesReceivablesSetup."Credit Warnings"::"Both Warnings", true);
        CreateItemWithInventory(Item, LibraryRandom.RandInt(10));  // Inventory value important for test.
        CreateCustomerWithCreditLimit(Customer, LibraryRandom.RandInt(10));  // Credit Limit greater than Zero important for test.

        // Exercise: Create Sales Order With required Item Quantity.
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", Item.Inventory);

        // Verify : Check Item Stock Availability without any warnings.
        Assert.IsFalse(ItemCheckAvail.SalesLineCheck(SalesLine), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditLimitEqualNoWarning()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        // Setup.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, SalesReceivablesSetup."Credit Warnings"::"Both Warnings", true);
        CreateItemWithInventory(Item, LibraryRandom.RandInt(10));  // Inventory value important for test.
        CreateCustomerWithCreditLimit(Customer, LibraryRandom.RandInt(10));  // Credit Limit greater than Zero important for test.

        // Create Sales Order With required Item Quantity.
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", Item.Inventory);

        // Exercise: Update Sales Order line with Item Unit Price.
        GeneralLedgerSetup.Get();
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Unit Price"), Customer."Credit Limit (LCY)" / Item.Inventory);

        // Verify : Check Customer Credit Limit without any warnings.
        CustCheckCrLimit.SalesLineCheck(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure NewCustStockEqualNoWarning()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer2: Record Customer;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        // Setup.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, SalesReceivablesSetup."Credit Warnings"::"No Warning", true);
        CreateItemWithInventory(Item, LibraryRandom.RandInt(10));  // Inventory value important for test.
        CreateCustomerWithCreditLimit(Customer, 0);
        CreateCustomerWithCreditLimit(Customer2, 0);

        // Create Sales Order With required Item Quantity.
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", Item.Inventory);

        // Exercise: Update Sales Order with new Sell to Customer No.
        UpdateSalesHeader(SalesHeader, Customer2."No.");

        // Verify : Check Item Stock Availability without any warnings.
        Assert.IsFalse(ItemCheckAvail.SalesLineCheck(SalesLine), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure NewCustCreditWarning()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check for Credit Limit Warning for Old and New customer with different Credit Limit without Shipping details.
        Initialize();
        SalesOrderSellToCustomerNo(SalesReceivablesSetup."Credit Warnings"::"Both Warnings", false);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,ConfirmHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure NewCustShippingCreditWarning()
    var
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check for Credit Limit Warning for Old and New customer with different Credit Limit with Shipping details.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        SalesOrderSellToCustomerNo(SalesReceivablesSetup."Credit Warnings"::"Both Warnings", true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CustShippingNoCreditWarning()
    begin
        // Check for Credit Limit Warning (No Warning) for Old and New customer with different Credit Limit with Shipping details.
        Initialize();
        SalesOrderSellToCustomerNo(SalesReceivablesSetup."Credit Warnings"::"No Warning", true);
    end;

    local procedure SalesOrderSellToCustomerNo(CreditWarning: Option; Shipping: Boolean)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        // Setup.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, CreditWarning, false);
        CreateSalesOrderDimNoCrLimit(SalesHeader, SalesLine, false);  // Customer 1:Dimension-FALSE.
        CreateNewCustomerForSalesOrder(Customer, Shipping);  // Customer 2:Shipping.

        // Exercise: Update Sales Line with Unit Price.
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Unit Price"), LibraryRandom.RandInt(10) + 50);
        // Value important.

        // Verify: Check Customer Credit Limit without warning.
        CustCheckCrLimit.SalesLineCheck(SalesLine);
        Clear(CustCheckCrLimit);

        // Exercise: Update Sales Header with new Sell to Customer No. and Unit Price.
        UpdateSalesHeader(SalesHeader, Customer."No.");
        UpdateSalesLineUnitPrice(SalesLine);

        // Verify: Check Credit Limit, Bill to Customer No. and Shipping Time.
        CustCheckCrLimit.SalesLineCheck(SalesLine);
        SalesHeader.TestField("Bill-to Customer No.", Customer."No.");
        if Shipping then
            SalesLine.TestField("Shipping Time", Customer."Shipping Time");
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,ConfirmHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure NewCustDimensionCreditWarning()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        // Setup.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, SalesReceivablesSetup."Credit Warnings"::"Both Warnings", false);
        CreateSalesOrderDimNoCrLimit(SalesHeader, SalesLine, true);  // Customer 1:Dimension-TRUE.
        CreateNewCustomerForSalesOrder(Customer, false);  // Customer 2:Shipping-FALSE.

        // Exercise: Update Sales Header with new Sell to Customer No. and Unit Price.
        UpdateSalesHeader(SalesHeader, Customer."No.");
        UpdateSalesLineUnitPrice(SalesLine);

        // Verify: Check Dimension and Credit Limit warning that credit limit exceeds.
        SalesLine.TestField("Dimension Set ID", 0);
        CustCheckCrLimit.SalesLineCheck(SalesLine);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure NewCustStockAndCreditWarning()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check for warnings with Shipping and Dimension.
        Initialize();
        SalesOrderShippingAndDimension(true);  // Both Credit Warning and Stockout Warning come up.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure NewCustShipDimStockWarning()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Check for warnings with Shipping and Dimension.
        Initialize();
        SalesOrderShippingAndDimension(false);  // Stockout Warning only comes up.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure SalesOrderShippingAndDimension(CreditWarning: Boolean)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        ItemCheckAvail: Codeunit "Item-Check Avail.";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        // Setup.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup, SalesReceivablesSetup."Credit Warnings"::"Both Warnings", true);
        CreateItemWithInventory(Item, 0);  // Inventory value important for test.
        CreateSalesOrderDimNoCrLimit(SalesHeader, SalesLine, true);  // Customer 1:Dimension-TRUE.
        CreateNewCustomerForSalesOrder(Customer, true);  // Customer 2:Shipping-TRUE.

        // Exercise: Update Sales Header with new Sell to Customer No.
        UpdateSalesHeader(SalesHeader, Customer."No.");
        SelectSalesLine(SalesLine, SalesHeader."Document Type"::Order, SalesHeader."No.");
        if CreditWarning then
            LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Unit Price"), LibraryRandom.RandInt(10) + 50);
        // Value important.

        // Verify: Check Dimension,Shipping, Item availability and  Credit Limit warning that credit limit exceeds.
        SalesLine.TestField("Dimension Set ID", 0);
        SalesLine.TestField("Shipping Time", Customer."Shipping Time");
        CustCheckCrLimit.SalesLineCheck(SalesLine);
        Assert.IsFalse(ItemCheckAvail.SalesLineCheck(SalesLine), '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Bugfixes Run Modal Errors");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Bugfixes Run Modal Errors");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ItemJournalSetup();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Bugfixes Run Modal Errors");
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    [Normal]
    local procedure UpdateSalesReceivablesSetup(var TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary; CreditWarnings: Option; StockoutWarning: Boolean)
    begin
        SalesReceivablesSetup.Get();
        TempSalesReceivablesSetup := SalesReceivablesSetup;
        TempSalesReceivablesSetup.Insert();

        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateSalesOrderCustCrLimit(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        CreateItemWithInventory(Item, 0);  // Inventory value important for test.
        CreateCustomerWithCreditLimit(Customer, LibraryRandom.RandInt(10));  // Credit Limit important for test.

        // Exercise: Create Sales Order With required Item Quantity.
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", LibraryRandom.RandInt(10) + 100);  // Value important.
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; ItemQty: Integer)
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo, ItemNo, ItemQty, '', 0D);
    end;

    local procedure CreateItemWithInventory(var Item: Record Item; Inventory: Integer)
    begin
        LibraryInventory.CreateItem(Item);
        if Inventory <> 0 then
            CreateAndPostItemJournal(Item."No.");
    end;

    local procedure CreateAndPostItemJournal(ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity.
        ClearJournal(ItemJournalBatch);  // Clear Item Journal Template and Journal Batch.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandInt(10) + 10);  // Value important for test.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure ClearJournal(ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure CreateCustomerWithCreditLimit(var Customer: Record Customer; CreditLimit: Decimal)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", CreditLimit);
        Customer.Validate("Prices Including VAT", true);
        Customer.Modify(true);
    end;

    local procedure CreateSalesOrderDimNoCrLimit(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Dimension: Boolean)
    var
        Customer: Record Customer;
        Item: Record Item;
    begin
        CreateItemWithInventory(Item, 0);  // Inventory value important for test.
        CreateCustomerWithCreditLimit(Customer, 0);  // Create first Customer with no credit limit.
        if Dimension then
            CreateDefaultDimension(Customer."No.");

        // Create Sales Order With required Item Quantity.
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", LibraryRandom.RandInt(10) + 100);  // Value important.
    end;

    local procedure SelectSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure UpdateCustomerShippingTime(var Customer: Record Customer)
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        ShippingTime: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        Customer.Validate("Shipping Agent Code", ShippingAgent.Code);
        Customer.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        Customer.Modify(true);
    end;

    local procedure CreateDefaultDimension(CustomerNo: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateNewCustomerForSalesOrder(var Customer: Record Customer; Shipping: Boolean)
    begin
        CreateCustomerWithCreditLimit(Customer, LibraryRandom.RandInt(10));  // Create a second Customer with random credit limit.
        if Shipping then
            UpdateCustomerShippingTime(Customer);
    end;

    local procedure UpdateSalesHeader(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20])
    begin
        SalesHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesLineUnitPrice(var SalesLine: Record "Sales Line")
    begin
        SelectSalesLine(SalesLine, SalesLine."Document Type"::Order, SalesLine."Document No.");
        LibraryInventory.UpdateSalesLine(SalesLine, SalesLine.FieldNo("Unit Price"), LibraryRandom.RandInt(10) + 50);
        // Value important.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

