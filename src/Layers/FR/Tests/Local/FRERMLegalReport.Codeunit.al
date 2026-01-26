codeunit 144037 "FR ERM Legal Report"
{
    // 1. Verify existance of Invoiced Sale Order with Charge Item after running report Delete Invoiced Sales Orders.
    // 
    //   Covers Test Cases for WI - 344840
    //   -------------------------------------------------------------------------------------------------------
    //   Test Function Name                                                                             TFS ID
    //   -------------------------------------------------------------------------------------------------------
    //   DeleteInvoiceSalesOrderWithItemCharge                                                          167830

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('GetShipmentLinePageHandler,DeleteInvoicedSalesOrdersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteInvoiceSalesOrderWithItemCharge()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify existance of Invoiced Sale Order with Charge Item after running report (ID-299) Delete Invoiced Sales Orders.

        // Setup: Create Item, Sale Order with Charge Item and post Sales Order as Ship.
        LibraryInventory.CreateItem(Item);
        CreateSalesOrderWithChargeItem(SalesHeader, Item."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Create Sales Invoice, Get Shipment Line and post invoice.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader2, SalesLine.Type::Item, Item."No.", 0);  // Using 0 for Quantity.
        LibrarySales.GetShipmentLines(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Exercise.
        REPORT.Run(REPORT::"Delete Invoiced Sales Orders");

        // Verify: Verify existance of Invoiced Sale Order with Charge Item.
        Assert.IsFalse(SalesHeader2.Get(SalesHeader."No.", SalesHeader."Document Type"::Order), 'Unexpected Error');
    end;

    local procedure CreateSalesOrderWithChargeItem(var SalesHeader: Record "Sales Header"; No: Code[20])
    var
        Customer: Record Customer;
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandInt(10));  // Using Random Int for Item Quantity.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), LibraryRandom.RandInt(10));  // Using Random Int for Charge Item Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random Dec for Unit Price.
        SalesLine.Modify(true);
        LibraryInventory.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.", No);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinePageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeleteInvoicedSalesOrdersRequestPageHandler(var DeleteInvoicedSalesOrders: TestRequestPage "Delete Invoiced Sales Orders")
    begin
        DeleteInvoicedSalesOrders.OK().Invoke();
    end;
}

