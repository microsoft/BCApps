codeunit 144023 "Sales Picking List"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [HandlerFunctions('ReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesPickingListTest()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CustomerNo: Code[20];
        NoOfItemsToSell: Integer;
    begin
        // Setup
        NoOfItemsToSell := LibraryRandom.RandInt(10);

        // Create General Posting setup
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        CustomerNo := CreateCustomer(PaymentTerms.Code);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        CreateOpenSalesOrder(CustomerNo, SalespersonPurchaser.Code, NoOfItemsToSell);
        Commit();

        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();

        // Exercise.
        REPORT.Run(REPORT::"Sales Picking List", true, false, SalesHeader);

        // Verify
        VerifyReportData(SalesHeader, CustomerNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportRequestPageHandler(var SalesPickingList: TestRequestPage "Sales Picking List")
    begin
        SalesPickingList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Normal]
    local procedure CreateOpenSalesOrder(CustomerNo: Code[20]; SalesPerson: Code[20]; NoOfItems: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Salesperson Code", SalesPerson);
        SalesHeader.Validate("Shipment Method Code", CreateShipmentMethodCode());
        SalesHeader.Modify();

        CreateSalesLine(SalesHeader, CreateItem(), NoOfItems);
        CreateSalesLine(SalesHeader, CreateItem(), NoOfItems);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; NoOfItems: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, NoOfItems);
    end;

    [Normal]
    local procedure CreateCustomer(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateShipmentMethodCode(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), DATABASE::"Shipment Method");
        ShipmentMethod.Description := 'Test Shipment Method';
        ShipmentMethod.Insert();
        exit(ShipmentMethod.Code);
    end;

    local procedure VerifyReportData(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        NoOfSalesLines: Integer;
        "Count": Integer;
    begin
        // Verify the XML
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();

        NoOfSalesLines := SalesLine.Count();
        Assert.AreEqual(2, NoOfSalesLines, 'Expecting exact 2 sales lines.');

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        Count := 0;

        // Note that the report will contain two Picking List ..
        // A original version and a copy.
        repeat
            // Validate Item No.
            LibraryReportDataset.AssertCurrentRowValueEquals('No_Line', SalesLine."No.");

            // Validate Quantity on sales lines
            LibraryReportDataset.AssertCurrentRowValueEquals('QtytoShip_Line', SalesLine.Quantity);

            // Validate Sell-To Customer No.
            LibraryReportDataset.AssertCurrentRowValueEquals('HeadBilltoCustomerNo', CustomerNo);

            if Count = 1 then begin
                SalesLine.FindFirst();
                Count := 0;
            end else begin
                SalesLine.Next();
                Count += 1;
            end;
        until LibraryReportDataset.GetNextRow() = false;
    end;
}

