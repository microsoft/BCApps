codeunit 136900 "Service Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [Service]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryService: Codeunit "Library - Service";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        ErrorWarning: Label 'Warning!';
        ErrorText: Label 'You must enter the customer''s %1.';
        PostUntilDateError: Label 'You must fill in the Post Until Date field.';
        PostingDateError: Label 'You must fill in the Posting Date field.';
        PriceUpdateError: Label 'You must fill in the Price Update % field.';
        RemoveToError: Label 'You must fill in the Remove to field.';
        ReasonCodeError: Label 'You must fill in the Reason Code field.';
        UnknownError: Label 'Unknown Error.';
        InvoiceToDateError: Label 'You must fill in the Invoice-to Date field.';
        ErrorPostingDate: Label 'You have not filled in the posting date.';
        ErrorInvoiceToDate: Label 'The Invoice-to Date is later than the work date.\\Confirm that this is the correct date.';
        ErrorInPostingDate: Label 'The posting date is later than the work date.\\Confirm that this is the correct date.';
        BatchJobError: Label 'The program has stopped the batch job at your request.';
        GrossAmountError: Label 'Amounts must be same';
        FindElemWithServiceNoMsg: Label 'find element with the service no';
        ServiceInvoiceTxt: Label 'Service - Invoice %1';
        ServiceTaxInvoiceTxt: Label 'Service - Tax Invoice %1';
        CreateContrUsingTemplateQst: Label 'Do you want to create the contract using a contract template?';
        NextPlannedServiceDateConfirmQst: Label 'The Next Planned Service Date field is empty on one or more service contract lines, and service orders cannot be created automatically. Do you want to continue?';
        SignServContractQst: Label 'Do you want to sign service contract %1?', Comment = '%1 = Contract No.';

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ServiceContractCustomerReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractCustomer()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractHeader2: Record "Service Contract Header";
        ServiceContractCustomer: Report "Service Contract - Customer";
    begin
        // Test that the Service Contract - Customer Report is generated properly.

        // 1. Setup: Create two Service Contracts - Service Item, Service Contract Header, Service Contract Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractWithExpiredLine(ServiceContractHeader, Customer."No.");
        CreateContractWithExpiredLine(ServiceContractHeader2, Customer."No.");

        // 2. Exercise: Generate the Service Contract - Customer report.
        Commit();
        Clear(ServiceContractCustomer);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.SetFilter(
          "Contract No.", ServiceContractHeader."Contract No." + '|' + ServiceContractHeader2."Contract No.");
        ServiceContractCustomer.SetTableView(ServiceContractHeader);
        ServiceContractCustomer.Run();

        // 3. Verify: Check that the Amount Per Period, Amount on Expired Lines and Annual Amount are generated correctly in the report.
        // Check that the Total Amounts for Customer as the sum of Amounts of both Service Contract.
        LibraryReportDataset.LoadDataSetFile();
        VerifyServiceContractCustomer(ServiceContractHeader);
        VerifyServiceContractCustomer(ServiceContractHeader2);
    end;

    [Test]
    [HandlerFunctions('ServiceItemWorksheetReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemWorksheetReport()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceItemWorksheet: Report "Service Item Worksheet";
    begin
        // Test that the Service Item Worksheet Report is generated properly.

        // 1. Setup: Create Service Order - Service Item, Service Header, Service Item Line and Service Line.
        Initialize();
        CreateServiceHeaderWithItemLine(
          ServiceHeader, ServiceItemLine, ServiceItem, LibrarySales.CreateCustomerNo(), ServiceHeader."Document Type"::Order);
        ServiceItemLineFaultSymptom(ServiceItemLine);
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");

        // 2. Exercise: Generate the Service Item Worksheet report.
        Commit();
        Clear(ServiceItemWorksheet);
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemWorksheet.SetTableView(ServiceItemLine);
        ServiceItemWorksheet.Run();

        // 3. Verify: Check that the Service Item Worksheet is generated properly.
        VerifyServiceItemWorksheet(ServiceItemLine, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ServiceItemWorksheetReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemWorksheetComments()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
        ServiceCommentLine1: Record "Service Comment Line";
        ServiceCommentLine2: Record "Service Comment Line";
        ServiceItemWorksheet: Report "Service Item Worksheet";
    begin
        // Test that the Service Item Worksheet Report is generated properly when Show Comments is TRUE.

        // 1. Setup: Create Service Order - Service Item, Service Header, Service Item Line and Service Line. Create
        // comments for Fault and Resolution.
        Initialize();
        CreateServiceHeaderWithItemLine(
          ServiceHeader, ServiceItemLine, ServiceItem, LibrarySales.CreateCustomerNo(), ServiceHeader."Document Type"::Order);
        ServiceItemLineFaultSymptom(ServiceItemLine);
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateCommentLineForServHeader(ServiceCommentLine1, ServiceItemLine, ServiceCommentLine1.Type::Fault);
        LibraryService.CreateCommentLineForServHeader(ServiceCommentLine2, ServiceItemLine, ServiceCommentLine2.Type::Resolution);

        // 2. Exercise: Generate the Service Item Worksheet report with Show Comments as TRUE.
        Commit();
        Clear(ServiceItemWorksheet);
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceItemWorksheet.SetTableView(ServiceItemLine);
        ServiceItemWorksheet.InitializeRequest(true);
        ServiceItemWorksheet.Run();

        // 3. Verify: Check that the Service Item Worksheet is generated properly with Show Comments as TRUE.
        VerifyServiceItemWorksheet(ServiceItemLine, ServiceLine);

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Comment_ServCommentLine', ServiceCommentLine1.Comment);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the Fault');

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Comment1_ServCommentLine', ServiceCommentLine2.Comment);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the Resolution');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,MaintenanceVisitPlanningReportHandler')]
    [Scope('OnPrem')]
    procedure MaintenanceVisitPlanningReport()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        MaintenanceVisitPlanning: Report "Maintenance Visit - Planning";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that the Maintenance Visit - Planning report is generated properly.

        // 1. Setup: Create Service Contract - Service Item, Service Contract Header, Service Contract Line and sign it.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractWithExpiredLine(ServiceContractHeader, Customer."No.");
        ResponsibilityCenterHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Generate the Maintenance Visit - Planning report.
        Commit();
        Clear(MaintenanceVisitPlanning);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        MaintenanceVisitPlanning.SetTableView(ServiceContractHeader);
        MaintenanceVisitPlanning.Run();

        // 3. Verify: Check that the Maintenance Visit - Planning is generated properly.
        VerifyMaintenanceVisitPlanning(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ServiceItemsOutOfWarrantyReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemsOutOfWarranty()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceItem: Record "Service Item";
        ServiceItemsOutOfWarranty: Report "Service Items Out of Warranty";
    begin
        // Test that the Service Items Out of Warranty report is generated properly.

        // 1. Setup: Create Service Contract - Service Item, Service Contract Header, Service Contract Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        WarrantyEndingDatePartsItem(ServiceItem);
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // 2. Exercise: Generate the Service Items Out of Warranty report.
        Commit();
        Clear(ServiceItemsOutOfWarranty);
        ServiceItem.SetRange("No.", ServiceItem."No.");
        ServiceItemsOutOfWarranty.SetTableView(ServiceItem);
        ServiceItemsOutOfWarranty.Run();

        // 3. Verify: Check that the Service Items Out of Warranty report is generated properly.
        VerifyServiceItemsOutWarranty(ServiceItem);
    end;

    [Test]
    [HandlerFunctions('ServiceItemResourceUsageReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemResourceUsage()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceItemResourceUsage: Report "Service Item - Resource Usage";
    begin
        // [FEATURE] [UI] [Report Service Item - Resource Usage]
        // [SCENARIO] Verify report "Service Item - Resource Usage" after ship & invoice service order.

        // [GIVEN] Service Order with resource usage on service item.
        Initialize();
        CreateServiceHeaderWithItemLine(
          ServiceHeader, ServiceItemLine, ServiceItem, LibrarySales.CreateCustomerNo(), ServiceHeader."Document Type"::Order);
        CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItem."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceItem.Get(ServiceItem."No.");

        // [WHEN] Run report "Service Item - Resource Usage".
        Commit();
        Clear(ServiceItemResourceUsage);
        ServiceItem.SetRange("No.", ServiceItem."No.");
        ServiceItemResourceUsage.SetTableView(ServiceItem);
        ServiceItemResourceUsage.Run();

        // [THEN] Report "Service Item - Resource Usage" results contain service item and it's correct usage amount and profit/profit percent values.
        VerifyServiceItemResourceUsage(ServiceItem);
    end;

    [Test]
    [HandlerFunctions('ServiceItemResourceUsageReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemResourceUsageDetail()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceItemResourceUsage: Report "Service Item - Resource Usage";
    begin
        // [FEATURE] [UI] [Report Service Item - Resource Usage]
        // [SCENARIO] Verify report "Service Item - Resource Usage" with "Show Details" flag after ship & invoice service order.

        // [GIVEN] Service Order with resource usage on service item.
        Initialize();
        CreateServiceHeaderWithItemLine(
          ServiceHeader, ServiceItemLine, ServiceItem, LibrarySales.CreateCustomerNo(), ServiceHeader."Document Type"::Order);
        CreateServiceLineWithResource(ServiceLine, ServiceHeader, ServiceItem."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceItem.Get(ServiceItem."No.");

        // [WHEN] Run report "Service Item - Resource Usage" with "Show Details" = TRUE.
        Commit();
        Clear(ServiceItemResourceUsage);
        ServiceItem.SetRange("No.", ServiceItem."No.");
        ServiceItemResourceUsage.SetTableView(ServiceItem);
        ServiceItemResourceUsage.InitializeRequest(true);
        ServiceItemResourceUsage.Run();

        // [THEN] Report "Service Item - Resource Usage" results contain service item and it's correct usage amount and profit/profit percent values.
        VerifyServiceItemResourceUsage(ServiceItem);
        // [THEN] Report "Service Item - Resource Usage" results contain service item and it's correct total amount value in details.
        VerifyServiceResourceDetail(ServiceItem);
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteReportReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteReport()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        // Test Values on Service Quote Report.

        // 1. Setup: Create Service Item, Service Header with Document Type Quote, Service Item Line with Service Item and
        // Service Line with Type Item.
        Initialize();
        CreateServiceHeaderWithItemLine(
          ServiceHeader, ServiceItemLine, ServiceItem, LibrarySales.CreateCustomerNo(), ServiceHeader."Document Type"::Quote);
        CreateServiceLine(ServiceHeader, ServiceItemLine."Line No.");

        // 2. Exercise: Run Service Quote Report.
        RunServiceQuoteReport(ServiceHeader."No.");

        // 3. Verify: Verify Values on Service Quote Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ServItemNo_ServLineType', ServiceItemLine."Service Item No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the service item no');
        LibraryReportDataset.AssertCurrentRowValueEquals('Description_ServLineType', ServiceItemLine.Description);

        VerifyServiceLineOnReport(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ServiceProfitRespCentersHandler')]
    [Scope('OnPrem')]
    procedure ServiceProfitRespCentersReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // [FEATURE] [UI] [Report Service Profit Resp. Centers]
        // [SCENARIO] Verify values on report Service Profit Resp. Centers after shipping & invoicing service order twice.

        // [GIVEN] Partial Ship and invoice Service Order with Responcibility Center twice, as result completely shipped and invoiced.
        Initialize();
        CreateHeaderWithResponsibility(ServiceHeader);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceHeader, ServiceItemLine."Line No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service Profit Resp. Centers".
        RunServiceProfitRespCenters(ServiceHeader."Responsibility Center");

        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Report's results contain correct Sales, Cost and Discount Amounts.
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindSet();
        VerifyServiceLedgerEntryAmount(ServiceShipmentHeader);

        ServiceShipmentHeader.Next();
        VerifyServiceLedgerEntryAmount(ServiceShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('ServiceLoadLevelReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceLoadLevelWithQuantity()
    var
        Selection: Option Quantity,Cost,Prices;
    begin
        // Verifiy Capacity of a Resource on the selection of Quantity.

        ServiceLoadLevelReport(Selection::Quantity);
    end;

    [Test]
    [HandlerFunctions('ServiceLoadLevelReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceLoadLevelWithCost()
    var
        Selection: Option Quantity,Cost,Prices;
    begin
        // Verifiy Capacity of a Resource on the selection of Cost.

        ServiceLoadLevelReport(Selection::Cost);
    end;

    [Test]
    [HandlerFunctions('ServiceLoadLevelReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceLoadLevelWithPrice()
    var
        Selection: Option Quantity,Cost,Prices;
    begin
        // Verifiy Capacity of a Resource on the selection of Price.

        ServiceLoadLevelReport(Selection::Prices);
    end;

    local procedure ServiceLoadLevelReport(Selection: Option)
    var
        Resource: Record Resource;
        ServiceLoadLevel: Report "Service Load Level";
    begin
        // Test that value of Capacity in Service Load Level matches the value of Capacity in corresponding Resource.

        // 1. Setup.
        Initialize();
        LibraryResource.CreateResourceNew(Resource);

        // 2. Exercise: Generate Service Load Level Report with different options.
        Commit();
        Clear(ServiceLoadLevel);
        Resource.SetRange("No.", Resource."No.");
        ServiceLoadLevel.SetTableView(Resource);
        ServiceLoadLevel.InitializeRequest(Selection);
        ServiceLoadLevel.Run();

        // 3. Verify: Check that the value of Capicity in Service Load Level is equal to the value of Capacity in corresponding Resource.
        // Check that only one row is generated on different Selections.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Resource', Resource."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the resourve no');
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), 'no more lines should exist');
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestAmount()
    var
        ServiceLine: Record "Service Line";
    begin
        // Test that value of Amount in Service Document - Test matches the value of Amount in corresponding Service Line.

        // 1. Setup: Create a Service Invoice - Service Header, Service Line.
        Initialize();
        ServiceDocumentTestReport(ServiceLine);

        // 3. Verify: Check that the value of Amount in Service Document - Test is equal to the value of Amount in
        // corresponding Service Line, Check that only one row is generated for the Item.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Service_Line___No__', ServiceLine."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), FindElemWithServiceNoMsg);

        LibraryReportDataset.AssertCurrentRowValueEquals('Service_Line___Line_Amount_', ServiceLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestError()
    var
        ServiceLine: Record "Service Line";
        ServiceHeader: Record "Service Header";
    begin
        // Test that value of Error Message in Service Document - Test matches.

        // 1. Setup: Create a Service Invoice.
        Initialize();
        ServiceDocumentTestReport(ServiceLine);

        // 3. Verify: Check that the value of Amount in Service Document - Test is equal to the value of Amount in
        // corresponding Service Line, Check that only one row is generated for the Item.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ErrorText_Number__Control97',
          StrSubstNo(ErrorText, ServiceHeader.FieldCaption("VAT Registration No.")));
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with error');
    end;

    local procedure ServiceDocumentTestReport(var ServiceLine: Record "Service Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        ServiceDocumentTest: Report "Service Document - Test";
    begin
        // Test that value of Amount in Service Document - Test matches the value of Amount in corresponding Service Line.

        // 1. Setup: Create a Service Invoice - Service Header, Service Line with VAT Posting Setup having VAT Calculation Type as Reverse Charge VAT.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        UpdateQuantityServiceLine(ServiceLine);

        // 2. Exercise: Generate the Service Document - Test report.
        Commit();
        Clear(ServiceDocumentTest);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        ServiceDocumentTest.SetTableView(ServiceHeader);
        ServiceDocumentTest.InitializeRequest(true, true, true);
        ServiceDocumentTest.Run();
    end;

    [Test]
    [HandlerFunctions('ServiceItemsReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceItemsReport()
    var
        ServiceItem: Record "Service Item";
        Customer: Record Customer;
        ServiceItems: Report "Service Items";
    begin
        // Test that value of Item No in Service Items matches the value of Item No in corresponding Service Item.

        // 1. Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");

        // 2. Exercise: Generate the Service Items report.
        Commit();
        Clear(ServiceItems);
        ServiceItem.SetRange("No.", ServiceItem."No.");
        ServiceItems.SetTableView(ServiceItem);
        ServiceItems.Run();

        // 3. Verify: Check that the value of Item No in Service Items is equal to the value of Item No in
        // corresponding Service Item, Check that only one row is generated for the Item.

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ServItem', ServiceItem."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with Service Item no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Description_ServItem', ServiceItem.Description);
    end;

    [Test]
    [HandlerFunctions('DispatchBoardReportHandler')]
    [Scope('OnPrem')]
    procedure DispatchBoardReport()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        DispatchBoard: Report "Dispatch Board";
    begin
        // Test that value of No. in Dispatch Board matches the value of No. Field in corresponding Service Header.

        // 1. Setup: Create a Service Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, '');

        // 2. Exercise: Generate the Dispatch Board report.
        Commit();
        Clear(DispatchBoard);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        DispatchBoard.SetTableView(ServiceHeader);
        DispatchBoard.Run();

        // 3. Verify: Check that the value of No. in Dispatch Board is equal to the value of No. in corresponding Service Header.
        // Check that only one row is generated for the Item.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ServHeader', ServiceHeader."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with Service header no');

        LibraryReportDataset.AssertCurrentRowValueEquals('OrderDate_ServHeader', Format(ServiceHeader."Order Date"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ServiceContractReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContract()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContract: Report "Service Contract";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that value of Line Value in Service Contract matches the value of Line Value Field in corresponding Service Contract Line.

        // 1. Setup: Create Service Contract and Modify Service Contract header.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);

        // 2. Exercise: Sign Service Contract, Generate the Service Contract report.
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
        Clear(ServiceContract);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContract.SetTableView(ServiceContractHeader);
        ServiceContract.InitializeRequest(true);
        ServiceContract.Run();

        // 3. Verify: Check that the value of Line Value in Service Contract is equal to the value of Line Value in
        // corresponding Service Contract Line, Check that only one row is generated for the Item.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ServItemNo_ServContractLine', ServiceContractLine."Service Item No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with Service item no');

        LibraryReportDataset.AssertCurrentRowValueEquals('LineValue_ServContractLine', ServiceContractLine."Line Value");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ContractServiceOrdersTestReportHandler')]
    [Scope('OnPrem')]
    procedure ContractServiceOrdersTest()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ContrServOrdersTest: Report "Contr. Serv. Orders - Test";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that value of Contract No. in Contr. Serv. Orders - Test matches the value of Contract No. in corresponding
        // Service Contract Line.

        // 1. Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);

        // 2. Exercise: Sign Service Contract, Generate the Service Contract report.
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
        Clear(ContrServOrdersTest);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ContrServOrdersTest.SetTableView(ServiceContractHeader);
        ContrServOrdersTest.InitVariables(WorkDate(), WorkDate());
        ContrServOrdersTest.Run();

        // 3. Verify: Check that the value of Contract No. in Contr. Serv. Orders - Test is equal to the value of Contract No. in
        // corresponding Service Contract Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Service_Contract_Line__Contract_No__', ServiceContractLine."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with Service contract no');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ContractGainLossEntriesReportHandler')]
    [Scope('OnPrem')]
    procedure ContractGainLossEntries()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        ContractGainLossEntries: Report "Contract Gain/Loss Entries";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that value of Contract Gain in Contract Gain/Loss Entries matches the value of Line Amount in corresponding
        // Service Contract Line.

        // 1. Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);

        // 2. Exercise: Generate the Service Items report.
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
        Clear(ContractGainLossEntries);
        ContractGainLossEntry.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ContractGainLossEntry.FindFirst();
        ContractGainLossEntries.SetTableView(ContractGainLossEntry);
        ContractGainLossEntries.Run();

        // 3. Verify: Test that value of Contract Gain in Contract Gain/Loss Entries matches the value of Line Amount in
        // corresponding Service Contract Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ContNo_ContGainLossEntry', ContractGainLossEntry."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with Service contract no');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,MaintenancePerformanceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MaintenancePerformanceReport()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        MaintenancePerformance: Report "Maintenance Performance";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that value of Annual Amount in Maintenance Performance matches the value of Annual Amount in corresponding
        // Service Contract Line.

        // 1. Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);

        // 2. Exercise: Sign Service Contract, Generate the Service Contract report.
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
        Clear(MaintenancePerformance);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        MaintenancePerformance.SetTableView(ServiceContractHeader);
        MaintenancePerformance.InitializeRequest(WorkDate());
        MaintenancePerformance.Run();

        // 3. Verify: Test that value of Annual Amount in Maintenance Performance matches the value of Annual Amount in corresponding
        // corresponding Service Contract Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('AnnualAmount', Round(ServiceContractHeader."Annual Amount", 1.0));
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with annual amount');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,MaintenancePerformanceToExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MaintenancePerformanceSaveToExcel()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO 332702] Run report "Maintenance Performance" with saving results to Excel file.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Signed Service Contract Header with Type = Contract.
        LibraryService.CreateServiceContractHeader(
            ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();

        // [WHEN] Run report "Maintenance Performance", save report output to Excel file.
        ServiceContractHeader.SetRecFilter();
        Report.Run(Report::"Maintenance Performance", true, false, ServiceContractHeader);

        // [THEN] Report output is saved to Excel file.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 11, '1'); // page number
        Assert.AreNotEqual(0, LibraryReportValidation.FindColumnNoFromColumnCaption('Maintenance Performance'), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,ServiceContractDetailReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractDetailReport()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        Customer: Record Customer;
        ServiceContractDetail: Report "Service Contract-Detail";
    begin
        // Test that value of Line Value in Service Contract Detail matches the value of Line Value
        // Field in corresponding Service Contract Line.

        // 1. Setup: Create Service Contract Header and Service Contract Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractHeaderAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);

        // 2. Exercise: Generate Service Contract Detail Report.
        Commit();
        Clear(ServiceContractDetail);
        FilterServiceContractHeader(ServiceContractHeader);
        ServiceContractDetail.SetTableView(ServiceContractHeader);
        ServiceContractDetail.Run();

        // 3. Verify: Check that the value of Line Value in Service Contract Detail is equal to the value of Line Value in
        // corresponding Service Contract Line, Check that only one row is generated for the Item.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ServeItmNo_ServeContrLine', ServiceContractLine."Service Item No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with Service item no');

        LibraryReportDataset.AssertCurrentRowValueEquals('LineValue_ServeContrLine', ServiceContractLine."Line Value");
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceInvoice: Report "Service - Invoice";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO] "Line Amount" in Service Invoice report matches the value of "Line Amount" in corresponding Service Line.
        // [GIVEN] Service Invoice shipped and invoiced.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        UpdateQuantityServiceLine(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service - Invoice".
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        Clear(ServiceInvoice);
        ServiceInvoice.SetTableView(ServiceInvoiceHeader);
        ServiceInvoice.Run();

        // [THEN] The value of Amount in Service Invoice is equal to the value of Line Amount in corresponding Service Invoice Line.
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ServiceInvHeader', ServiceInvoiceLine."No.");
        LibraryReportDataset.SetRange('LineNo_ServInvLine', ServiceInvoiceLine."Line No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'No line with Line No.');
        LibraryReportDataset.AssertCurrentRowValueEquals('TotalLineAmount', ServiceInvoiceLine."Line Amount");
        // [THEN] Report title is 'Service - Invoice '
        LibraryReportDataset.AssertCurrentRowValueEquals('ReportTitleCopyText', StrSubstNo(ServiceInvoiceTxt, ''));
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportLineSorting()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: array[2] of Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: array[2] of Record "Service Item Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        ServiceInvoice: Report "Service - Invoice";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 428385] Service Lines are shown in groups per Service Item Line.
        // [GIVEN] Service Order shipped and invoiced.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine[1], ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine[2], ServiceHeader, ServiceItem."No.");
        // [GIVEN] Service Line #2 linked to ServiceItemLine #2 and has "Line No." 10000
        LibraryService.CreateServiceLine(
          ServiceLine[2], ServiceHeader, ServiceLine[2].Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        ServiceLine[2].Validate("Service Item Line No.", ServiceItemLine[2]."Line No.");
        UpdateQuantityServiceLine(ServiceLine[2]);
        // [GIVEN] Service Line #1 linked to ServiceItemLine #1 and has "Line No." 20000
        LibraryService.CreateServiceLine(
          ServiceLine[1], ServiceHeader, ServiceLine[1].Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        ServiceLine[1].Validate("Service Item Line No.", ServiceItemLine[1]."Line No.");
        UpdateQuantityServiceLine(ServiceLine[1]);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service - Invoice".
        ServiceInvoiceHeader.Get(ServiceHeader."Last Posting No.");
        ServiceInvoiceHeader.SetRecFilter();
        Clear(ServiceInvoice);
        ServiceInvoice.SetTableView(ServiceInvoiceHeader);
        ServiceInvoice.Run();

        // [THEN] Posted Service Invoice Lines are sorted so first is Service Line #1, second is Service Line #2
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.Filter.SetFilter("No.", ServiceInvoiceHeader."No.");
        PostedServiceInvoice.ServInvLines.First();
        PostedServiceInvoice.ServInvLines."No.".AssertEquals(ServiceLine[1]."No.");
        PostedServiceInvoice.ServInvLines.Next();
        PostedServiceInvoice.ServInvLines."No.".AssertEquals(ServiceLine[2]."No.");
        // [THEN] ServiceInvoice report prints service line 1 and then service line 2, regardless of their "Line No."
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ServiceInvHeader', ServiceInvoiceHeader."No.");
        LibraryReportDataset.SetRange('TypeInt', 1);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'No first line with Item');
        LibraryReportDataset.AssertCurrentRowValueEquals('No_ServiceInvLine', ServiceLine[1]."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'No second line with Item');
        LibraryReportDataset.AssertCurrentRowValueEquals('No_ServiceInvLine', ServiceLine[2]."No.");
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportCustomCaption()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceInvoice: Report "Service - Invoice";
        ReportCaptionSubscriber: Codeunit "Report Caption Subscriber";
    begin
        // [FEATURE] [Invoice] [Report Caption]
        // [SCENARIO] 'Service - Invoice' report caption can be redefined by subscription.
        // [GIVEN] Service Invoice shipped and invoiced.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        UpdateQuantityServiceLine(ServiceLine);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        // [GIVEN] Redefined report title as 'Service - Tax Invoice'
        ReportCaptionSubscriber.SetCaption(ServiceTaxInvoiceTxt);
        BindSubscription(ReportCaptionSubscriber);
        // [WHEN] Run report "Service - Invoice".
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        Clear(ServiceInvoice);
        ServiceInvoice.SetTableView(ServiceInvoiceHeader);
        ServiceInvoice.Run();

        // [THEN] Report title is 'Service - Tax Invoice '
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'Cannot get first line');
        LibraryReportDataset.AssertCurrentRowValueEquals('ReportTitleCopyText', StrSubstNo(ServiceTaxInvoiceTxt, ''));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ExpiredContractLineslReportHandler')]
    [Scope('OnPrem')]
    procedure ExpiredContractLines()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        Customer: Record Customer;
        ExpiredContractLinesTest: Report "Expired Contract Lines - Test";
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // Test that value of Contract Expiration Date in Expired Contract Lines Test matches the value of Contract Expiration Date Field in
        // corresponding Service Contract Line.

        // Setup: Create Service Contract, Modify Service Contract header, Sign Service Contract and Modify Expiration Date.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractHeaderAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        UpdateExpirationDateOnHeader(ServiceContractHeader);

        // 2. Exercise: Generate Expired Contract Lines Test report.
        Clear(ExpiredContractLinesTest);
        FilterServiceContractHeader(ServiceContractHeader);
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst();
        ExpiredContractLinesTest.SetTableView(ServiceContractLine);
        ExpiredContractLinesTest.InitVariables(WorkDate(), CreateReasonCode());
        Commit();
        ExpiredContractLinesTest.Run();

        // 3. Verify: Check that value of Contract Expiration Date in Expired Contract Lines Test matches the value of
        // Contract Expiration Date Field in corresponding Service Contract Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Service_Contract_Line__Contract_No__', ServiceContractLine."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with Service contract no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Service_Contract_Line__Contract_Expiration_Date_',
          Format(ServiceContractLine."Contract Expiration Date"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ExpiredContractLineslReportHandler')]
    [Scope('OnPrem')]
    procedure ExpiredContractLinesRemoveTo()
    begin
        // Test that System generates an error when Remove To is not filled.
        ExpiredContractLinesError(0D, CreateReasonCode(), RemoveToError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ExpiredContractLineslReportHandler')]
    [Scope('OnPrem')]
    procedure ExpiredContractLinesReasonCode()
    begin
        // Test that System generates an error when Reason Code is not filled.
        ExpiredContractLinesError(WorkDate(), '', ReasonCodeError);
    end;

    local procedure ExpiredContractLinesError(RemoveTo: Date; ReasonCode: Code[10]; Error: Text[50])
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        Customer: Record Customer;
        ExpiredContractLinesTest: Report "Expired Contract Lines - Test";
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // Test that System generates an error when Reason Code is not filled.

        // Setup: Create Service Contract, Modify Service Contract header, Sign Service Contract and Modify Expiration Date and
        // Modify Service Management Setup.
        Initialize();
        UpdateReasonOnServiceSetup();
        LibrarySales.CreateCustomer(Customer);
        CreateContractHeaderAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        UpdateExpirationDateOnHeader(ServiceContractHeader);

        // 2. Exercise: Generate Expired Contract Lines Test report.
        Commit();
        Clear(ExpiredContractLinesTest);
        FilterServiceContractHeader(ServiceContractHeader);
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ExpiredContractLinesTest.SetTableView(ServiceContractLine);
        ExpiredContractLinesTest.InitVariables(RemoveTo, ReasonCode);
        asserterror ExpiredContractLinesTest.Run();

        // 3. Verify: Check that System generates an error when Reason Code is not filled.
        Assert.AreEqual(StrSubstNo(Error), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ContractTemplateListHandler,ServiceProfitContractsHandler')]
    [Scope('OnPrem')]
    procedure ServiceProfitContracts()
    var
        ServiceHeader: Record "Service Header";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        Customer: Record Customer;
        ServiceProfitContracts: Report "Service Profit (Contracts)";
        SignServContractDoc: Codeunit SignServContractDoc;
        ServContractManagement: Codeunit ServContractManagement;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // Test that value of Service Amount LCY in Service Profit Contracts matches the value of
        // Amount LCY Field in corresponding Service Ledger Entry.

        // 1. Setup: Create and Sign Service Contract Post Service Invoice and Create Service Credit Memo.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractHeaderAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();

        ServiceContractHeader.Get(ServiceContractHeader."Contract Type"::Contract, ServiceContractHeader."Contract No.");
        ServiceHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        REPORT.RunModal(REPORT::"Batch Post Service Invoices", false, true, ServiceHeader);
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        UpdateExpirationDateOnHeader(ServiceContractHeader);

        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.FindFirst();
        ServContractManagement.CreateContractLineCreditMemo(ServiceContractLine, true);

        // 2. Exercise: Generate Service Profit Contracts Report.
        Clear(ServiceProfitContracts);
        FilterServiceContractHeader(ServiceContractHeader);
        ServiceProfitContracts.SetTableView(ServiceContractHeader);
        ServiceProfitContracts.InitializeRequest(true);
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        ServiceLedgerEntry.FindFirst();

        Commit();
        ServiceProfitContracts.Run();

        // 3. Verify: Check that value of Service Amount LCY in Service Profit Contracts matches the value of
        // Amount LCY Field in corresponding Service Ledger Entry.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ServLedgEntry', ServiceLedgerEntry."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('AmountLCY_ServLedgEntry', -ServiceLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'ProfitAmount_ServLedgEntry',
          ServiceLedgerEntry."Cost Amount" - ServiceLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ContractTemplateListHandler,ContractPriceUpdateTestReportHandler')]
    [Scope('OnPrem')]
    procedure ContractPriceUpdateTest()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        Customer: Record Customer;
        ContractPriceUpdateTest: Report "Contract Price Update - Test";
        SignServContractDoc: Codeunit SignServContractDoc;
        UpdatePercent: Decimal;
    begin
        // Test that value of Customer No in Contract Price Update Test matches the value of
        // Customer No Field in corresponding Service Contract Header.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractHeaderAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Generate Contract Price Update Test Report.
        Commit();
        Clear(ContractPriceUpdateTest);
        FilterServiceContractHeader(ServiceContractHeader);
        ContractPriceUpdateTest.SetTableView(ServiceContractHeader);
        UpdatePercent := LibraryRandom.RandDecInRange(5, 10, 2);
        ContractPriceUpdateTest.InitVariables(
          UpdatePercent, CalcDate('<' + Format(LibraryRandom.RandInt(2)) + 'M>', ServiceContractHeader."Starting Date"));
        ContractPriceUpdateTest.Run();

        // 3. Verify: Check that value of Customer No in Contract Price Update Test matches the value of
        // Customer No Field in corresponding Service Contract Header.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Service_Contract_Header__Contract_No__', ServiceContractHeader."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with Service contract no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Service_Contract_Header__Customer_No__', ServiceContractHeader."Customer No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('PriceUpdPct_Control23', UpdatePercent);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ContractTemplateListHandler,ContractPriceUpdateTestReportHandler')]
    [Scope('OnPrem')]
    procedure ContractPriceUpdateError()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        Customer: Record Customer;
        ContractPriceUpdateTest: Report "Contract Price Update - Test";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that System generates an error when Price Update is not filled.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractHeaderAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Generate Contract Price Update Test Report.
        Commit();
        Clear(ContractPriceUpdateTest);
        FilterServiceContractHeader(ServiceContractHeader);
        ContractPriceUpdateTest.SetTableView(ServiceContractHeader);
        ContractPriceUpdateTest.InitVariables(
          0, CalcDate('<' + Format(LibraryRandom.RandInt(2)) + 'M>', ServiceContractHeader."Starting Date"));
        asserterror ContractPriceUpdateTest.Run();

        // 3. Verify: Check that System generates an error when Price Update is not filled.
        Assert.AreEqual(StrSubstNo(PriceUpdateError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,PrepaidContractEntriesTestReportHandler')]
    [Scope('OnPrem')]
    procedure PrepaidContractEntriesTest()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        Customer: Record Customer;
        PrepaidContrEntriesTest: Report "Prepaid Contr. Entries - Test";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [FEATURE] [UI] [Report Prepaid Contr. Entries - Test]
        // [SCENARIO] Value of Amount LCY in "Prepaid Contrract Entries - Test" matches the value of Amount LCY Field in corresponding Service Ledger Entry.

        // Test that value of Amount LCY in Prepaid Contrract Entries Test matches the value of
        // Amount LCY Field in corresponding Service Ledger Entry.

        // [GIVEN] Signed Service Contract with Posted Service Invoice and not posted Service Credit Memo.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractHeaderAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        ModifyHeaderForPrepaid(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        CreateAndPostServiceInvoice(ServiceContractHeader);

        // [WHEN] Run report "Prepaid Contr. Entries - Test".
        Commit();
        Clear(PrepaidContrEntriesTest);
        FilterServiceContractHeader(ServiceContractHeader);
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        ServiceLedgerEntry.FindFirst();
        PrepaidContrEntriesTest.SetTableView(ServiceLedgerEntry);
        PrepaidContrEntriesTest.InitVariables(WorkDate(), WorkDate());
        PrepaidContrEntriesTest.Run();

        // [THEN] The value of Amount LCY in report results matches the value of Amount LCY Field in corresponding Service Ledger Entry.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Service_Ledger_Entry__Service_Contract_No__', ServiceLedgerEntry."Service Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with Service contract no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Service_Ledger_Entry__Amount__LCY__', ServiceLedgerEntry."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,PrepaidContractEntriesTestReportHandler')]
    [Scope('OnPrem')]
    procedure PrepaidContractPostUntilDate()
    begin
        // [FEATURE] [UI] [Report Prepaid Contr. Entries - Test]
        // [SCENARIO] Check that an error is throwed on running "Prepaid Contr. Entries - Test" if "Post Until Date" is not filled.

        // [GIVEN] Post Until Date is not filled.
        // [WHEN] Run report "Prepaid Contr. Entries - Test".
        // [THEN] System generates an error.
        PrepaidContractErrorTest(0D, WorkDate(), PostUntilDateError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,PrepaidContractEntriesTestReportHandler')]
    [Scope('OnPrem')]
    procedure PrepaidContractPostingDate()
    begin
        // [FEATURE] [UI] [Report Prepaid Contr. Entries - Test]
        // [SCENARIO] Check that an error is throwed on running "Prepaid Contr. Entries - Test" if "Posting Date" is not filled.

        // [GIVEN] Posting Date is not filled.
        // [WHEN] Run report "Prepaid Contr. Entries - Test".
        // [THEN] System generates an error.
        PrepaidContractErrorTest(WorkDate(), 0D, PostingDateError);
    end;

    local procedure PrepaidContractErrorTest(PostUntilDate: Date; PostingDate: Date; Error: Text[50])
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        Customer: Record Customer;
        PrepaidContrEntriesTest: Report "Prepaid Contr. Entries - Test";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that System generates an error when Posting Date is not filled.

        // 1. Setup: Create and Sign Service Contract Post Service Invoice and Create Service Credit Memo.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractHeaderAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        ModifyHeaderForPrepaid(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
        CreateAndPostServiceInvoice(ServiceContractHeader);

        // 2. Exercise: Generate Prepaid Contr Entries Test Report.
        Clear(PrepaidContrEntriesTest);
        FilterServiceContractHeader(ServiceContractHeader);
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        PrepaidContrEntriesTest.SetTableView(ServiceLedgerEntry);
        PrepaidContrEntriesTest.InitVariables(PostUntilDate, PostingDate);
        asserterror PrepaidContrEntriesTest.Run();

        // 3. Verify: Check that System generates an error when Posting Date is not filled.
        Assert.AreEqual(StrSubstNo(Error), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,PrepaidContractEntriesTestReportHandler')]
    [Scope('OnPrem')]
    procedure PrepaidContrEntriesTestWarning()
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        Customer: Record Customer;
        PrepaidContrEntriesTest: Report "Prepaid Contr. Entries - Test";
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [FEATURE] [UI] [Report Prepaid Contr. Entries - Test]
        // [SCENARIO] Verify that report "Prepaid Contr. Entries - Test" has warning because of unposted credit memo.

        // [GIVEN] Signed Service Contract, with posted Service Invoice and not posted Credit Memo.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractHeaderAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        UpdateContractExpirationDate(ServiceContractLine, ServiceContractHeader."Starting Date");
        AmountsInServiceContractHeader(ServiceContractHeader);
        ModifyHeaderForPrepaid(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        CreateAndPostServiceInvoice(ServiceContractHeader);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        CreateCreditMemoFromContract(ServiceContractHeader);

        // 2. [WHEN] Run report "Prepaid Contr. Entries - Test".
        Commit();
        Clear(PrepaidContrEntriesTest);
        FilterServiceContractHeader(ServiceContractHeader);
        ServiceLedgerEntry.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        PrepaidContrEntriesTest.SetTableView(ServiceLedgerEntry);
        PrepaidContrEntriesTest.InitVariables(WorkDate(), WorkDate());
        PrepaidContrEntriesTest.Run();

        // 3. [THEN] Prepaid Contract Entries Test results contain warning.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Warning_Caption', ErrorWarning);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with error');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ServiceContractQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteReport()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Test values on Service Contract Quote Report with Show Comments False.

        // 1. Setup: Create Service Item, Service Contract Header of Contract Type Quote and Service Contract Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);

        // 2. Exercise: Run Service Contract Quote Report with Show Comments False.
        RunServiceContractQuote(ServiceContractLine."Contract No.", false);

        // 3. Verify: Verify values on Service Contract Quote Report.
        VerifyServiceContractLine(ServiceContractLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ServiceContractQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteComment()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        // Test values on Service Contract Quote Report with Show Comments True.

        // 1. Setup: Create Service Item, Service Contract Header of Contract Type Quote, Service Contract Line, Create Comment for the
        // Service Contract Quote.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        CreateServiceQuoteComment(ServiceCommentLine, ServiceContractLine);

        // 2. Exercise: Run Service Contract Quote Report with Show Comments True.
        RunServiceContractQuote(ServiceContractLine."Contract No.", true);

        // 3. Verify: Verify values on Service Contract Quote Report.
        VerifyServiceContractLine(ServiceContractLine);
        VerifyCommentOnReport(ServiceCommentLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ServiceContractQuoteToExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteSaveToExcel()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // [SCENARIO 332702] Run report "Service Contract Quote" with saving results to Excel file.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Service Contract Header with Type = Quote.
        LibraryService.CreateServiceContractHeader(
            ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, LibrarySales.CreateCustomerNo());
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        Commit();

        // [WHEN] Run report "Service Contract Quote", save report output to Excel file.
        ServiceContractHeader.SetRecFilter();
        Report.Run(Report::"Service Contract Quote", true, false, ServiceContractHeader);

        // [THEN] Report output is saved to Excel file.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(1, 15, '1'); // page number
        Assert.AreNotEqual(0, LibraryReportValidation.FindColumnNoFromColumnCaption('Service Contract Quote'), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ServiceContractQuoteDetailReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteDetail()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Test values on Service Contract Quote Detail Report with Show Comments False.

        // 1. Setup: Create Service Item, Service Contract Header of Contract Type Quote and Service Contract Line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);

        // 2. Exercise: Run Service Contract Quote Detail Report with Show Comments False.
        RunServiceContractQuoteDetail(ServiceContractLine."Contract No.", false);

        // 3. Verify: Verify values on Service Contract Quote Detail Report.
        VerifyServiceContractLine(ServiceContractLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalse,ServiceContractQuoteDetailReportHandler')]
    [Scope('OnPrem')]
    procedure ContractQuoteDetailComment()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceCommentLine: Record "Service Comment Line";
    begin
        // Test values on Service Contract Quote Detail Report with Show Comments True.

        // 1. Setup: Create Service Item, Service Contract Header of Contract Type Quote, Service Contract Line, Create Comment for the
        // Service Contract Quote.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        CreateServiceQuoteComment(ServiceCommentLine, ServiceContractLine);

        // 2. Exercise: Run Service Contract Quote Detail Report with Show Comments True.
        RunServiceContractQuoteDetail(ServiceContractLine."Contract No.", true);

        // 3. Verify: Verify values on Service Contract Quote Detail Report.
        VerifyServiceContractLine(ServiceContractLine);
        VerifyCommentOnReport(ServiceCommentLine);
    end;

    [Test]
    [HandlerFunctions('ServiceTasksReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceTasksReport()
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceTasks: Report "Service Tasks";
    begin
        // Test that the Service Tasks Report is generated properly.

        // 1. Setup: Create Service Order - Service Item, Service Header, Service Item Line and Service Line.
        Initialize();
        CreateServiceHeaderWithItemLine(
          ServiceHeader, ServiceItemLine, ServiceItem, LibrarySales.CreateCustomerNo(), ServiceHeader."Document Type"::Order);

        // 2. Exercise: Generate the Service Tasks report.
        Commit();
        Clear(ServiceTasks);
        ServiceItemLine.SetRange("Document Type", ServiceItemLine."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceItemLine."Document No.");
        ServiceTasks.SetTableView(ServiceItemLine);
        ServiceTasks.Run();

        // 3. Verify: Check that the Service Task is generated properly.
        VerifyServiceTasks(ServiceItemLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ServiceContractSalespersonReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractSalesperson()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ServContractSalesperson: Report "Serv. Contract - Salesperson";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that value of SalesPerson Code,Annual Amount and Contract No. in Serv. Contract - Salesperson matches the
        // Value of SalesPerson Code,Line Value and Contract No. Field in corresponding Service Contract Header and Service Contract Line.

        // 1. Setup: Create Service Contract and Modify Service Contract header and Calculate Amount in Service Contract Header.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);

        // 2. Exercise: Sign Service Contract, Generate the Serv. Contract - Salesperson.
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();
        Clear(ServContractSalesperson);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServContractSalesperson.SetTableView(ServiceContractHeader);
        ServContractSalesperson.Run();

        // 3. Verify: Check that value of SalesPerson Code,Annual Amount and Contract No. in Serv. Contract - Salesperson matches the
        // Value of SalesPerson Code,Line Value and Contract No. Field in corresponding Service Contract Header and Service Contract Line.
        VerifyServiceContractSalesper(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ContractGainLossResponsibilityReportHandler')]
    [Scope('OnPrem')]
    procedure ContractGainLossResponsibility()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractHeader2: Record "Service Contract Header";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        ContrGainLossRespCtr: Report "Contr. Gain/Loss - Resp. Ctr.";
    begin
        // Test that value of Grand Total Amount in Contr. Gain/Loss - Resp. Ctr. matches the value of Amount in corresponding
        // Contract Gain/Loss Entry.

        // 1. Setup: Create Multiple Contract Gain Loss Entries.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateContractGainLossEntries(ServiceContractHeader, Customer."No.");
        CreateContractGainLossEntries(ServiceContractHeader2, Customer."No.");

        // 2. Exercise: Generate the Contr. Gain/Loss - Resp. Ctr.
        Commit();
        Clear(ContrGainLossRespCtr);
        ContractGainLossEntry.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ContractGainLossEntry.SetFilter(
          "Contract No.", ServiceContractHeader."Contract No." + '|' + ServiceContractHeader2."Contract No.");
        ContrGainLossRespCtr.SetTableView(ContractGainLossEntry);
        ContrGainLossRespCtr.InitializeRequest(true);
        ContrGainLossRespCtr.Run();

        // 3. Verify: Verify that value of Grand Total Amount in Contr. Gain/Loss - Resp. Ctr. matches the value of Amount in
        // Corresponding Contract Gain/Loss Entry.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ContNo_ContGnLossEty', ServiceContractHeader."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the contract no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_ContGnLossEty', ServiceContractHeader."Annual Amount");

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('ContNo_ContGnLossEty', ServiceContractHeader2."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the contract no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Amt_ContGnLossEty', ServiceContractHeader2."Annual Amount");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ContractInvoicingReportHandler')]
    [Scope('OnPrem')]
    procedure ContractInvoicing()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that values of Contract No.,Amount Per Period in Contract Invoicing matches the value of Contract No.,Amount Per Period
        // in corresponding Service Contract Header.

        // 1. Setup: Create Contract Gain Loss Entries and Calculate Amount Per Period.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Generate the Contract Invoicing.
        RunContractInvoicingReport(ServiceContractHeader, WorkDate(), ServiceContractHeader."Next Invoice Period End");

        // 3. Verify: Verify that values of Contract No.,Amount Per Period in Contract Invoicing matches the value of
        // Contract No.,Amount Per Period in corresponding Service Contract Header.
        VerifyContractInvoicing(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ContractInvoicingReportHandler')]
    [Scope('OnPrem')]
    procedure ContractInvoicingInvoiceToDate()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that System generates an error when Invoice-to Date is not filled.

        // 1. Setup: Create Contract Gain Loss Entries and Calculate Amount Per Period.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Generate the Contract Invoicing.
        asserterror RunContractInvoicingReport(ServiceContractHeader, WorkDate(), 0D);

        // 3. Verify: Verify the Invoice to Date Error message.
        Assert.AreEqual(StrSubstNo(InvoiceToDateError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ContractInvoicingReportHandler')]
    [Scope('OnPrem')]
    procedure ContractInvoicingPostingDate()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that System generates an error when Posting Date is not filled.

        // 1. Setup: Create Contract Gain Loss Entries and Calculate Amount Per Period.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Generate the Contract Invoicing.
        asserterror RunContractInvoicingReport(ServiceContractHeader, 0D, WorkDate());

        // 3. Verify: Verify the Posting Date Error message.
        Assert.AreEqual(StrSubstNo(ErrorPostingDate), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,ContractInvoicingReportHandler')]
    [Scope('OnPrem')]
    procedure ContractInvoicingChangeInvoicingPeriod()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
        LockOpenServContract: Codeunit "Lock-OpenServContract";
    begin
        // [FEATURE] [Contract Invoicing]
        // [SCENARIO 229113] Contract Invoicing report contains all new invoicing periods after Next Invoice Date when Invoice Period value is changed
        Initialize();

        // [GIVEN] Service Contract "SC" with Service Contract Line
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, '');
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);

        // [GIVEN] "SC" Starting Date is set to the first date of the current mounth "D1" to match with the Next Invoice Date
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-CM>', WorkDate()));
        ServiceContractHeader.Modify(true);

        // [GIVEN] "SC" Invoice Period is set
        Evaluate(ServiceContractHeader."Price Update Period", '');
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::"Two Months");
        ServiceContractHeader.Modify(true);

        // [GIVEN] "SC" is signed
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [GIVEN] Create and post Service Invoice for the next "SC" Invoicing Period "D1".."D2"
        CreateAndPostServiceInvoice(ServiceContractHeader);

        // [GIVEN] Reopen "SC" and change Invoicing Period
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        LockOpenServContract.OpenServContract(ServiceContractHeader);
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Quarter);
        ServiceContractHeader.Modify(true);

        // [WHEN] Run Contract Invoicing Report
        RunContractInvoicingReport(ServiceContractHeader, WorkDate(), CalcDate('<1Y>', WorkDate()));

        // [THEN] Contract Invoicing Report starts from "D2"
        VerifyContractInvoicingNextInvoicePeriod(ServiceContractHeader);
    end;

    [Test]
    [HandlerFunctions('InvoiceDateConfirmHandler,ContractTemplateListHandler,MessageHandler,ContractInvoicingReportHandler')]
    [Scope('OnPrem')]
    procedure InvoiceToDateLaterThanWorkDate()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that System generates an error when The Invoice-to Date is later than the work date.
        // Confirm that this is the correct date.

        // 1. Setup: Create Contract Gain Loss Entries and Calculate Amount Per Period.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Generate the Contract Invoicing.
        // System generates an error when The Invoice-to Date is later than the work date.
        asserterror
          RunContractInvoicingReport(
            ServiceContractHeader, WorkDate(), CalcDate('<' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'M>', WorkDate()));

        // 3. Verify: Verify that System generates an error when The Invoice-to Date is later than the work date.
        Assert.AreEqual(StrSubstNo(BatchJobError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('PostingDateConfirmHandler,ContractTemplateListHandler,MessageHandler,ContractInvoicingReportHandler')]
    [Scope('OnPrem')]
    procedure PostingDateLaterThanWorkdate()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that System generates an error when posting date is later than the work date.Confirm that this is the correct date.

        // 1. Setup: Create Contract Gain Loss Entries and Calculate Amount Per Period.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // 2. Exercise: Generate the Contract Invoicing.
        // System generates an error when posting date is later than the work date.
        asserterror
          RunContractInvoicingReport(
            ServiceContractHeader, CalcDate('<' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'M>', WorkDate()), WorkDate());

        // 3. Verify: Verify that System generates an error when posting date is later than the work date.
        Assert.AreEqual(StrSubstNo(BatchJobError), GetLastErrorText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ContractTemplateListHandler,ConfirmHandlerTrue,ServiceContractWithForecastReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractWithForecast()
    var
        ServiceContractLine: Record "Service Contract Line";
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
    begin
        // Test that value of Forecast Amount in Contract Quotes to Be Signed matches the value of Forecast Amount in corresponding
        // Service Contract Line.

        // 1. Setup: Create Service Contract Quote - Service Contract Header, Service Contract Line, Service Item.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);

        // 2. Exercise: Sign Service Contract, Generate the Service Contract report.
        RunContractQuotesToBeSigned(ServiceContractHeader, true);

        // 3. Verify: Check that value of Forecast Amount in Contract Quotes to Be Signed matches the value of Forecast Amount
        // in corresponding Service Contract Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Service_Contract_Header__Contract_No__', ServiceContractLine."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the contract no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Service_Contract_Header__Annual_Amount_', ServiceContractLine."Line Value");
    end;

    [Test]
    [HandlerFunctions('ContractTemplateListHandler,ConfirmHandlerTrue,ServiceContractWithForecastReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceContractWithoutForecast()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
    begin
        // Test that value of Quoted Amount in Contract Quotes to Be Signed matches the value of Quoted Amount in corresponding
        // Service Contract Line.

        // 1. Setup: Create Service Contract Quote - Service Contract Header, Service Contract Line, Service Item.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);

        // 2. Exercise: Sign Service Contract, Generate the Service Contract report.
        RunContractQuotesToBeSigned(ServiceContractHeader, false);

        // 3. Verify: that value of Quoted Amount in Contract Quotes to Be Signed matches the value of Quoted Amount
        // in corresponding Service Contract Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Service_Contract_Header__Contract_No__', ServiceContractLine."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the contract no');

        LibraryReportDataset.AssertCurrentRowValueEquals('Service_Contract_Header__Annual_Amount_', ServiceContractLine."Line Value");
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestCodeMandatory()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // Test to verify Line Dimension on Service Order with Service Line of Type Cost with Value Posting Code Mandatory after running Service Document Test report.

        ServiceDocumentTestShowDimension(DefaultDimension."Value Posting"::"Code Mandatory");
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestValuePostingBlank()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // Test to verify Line Dimension on Service Order with Service Line of Type Cost with Value Posting blank after running Service Document Test report.

        ServiceDocumentTestShowDimension(DefaultDimension."Value Posting"::" ");
    end;

    [Test]
    [HandlerFunctions('CreateAndPrintServiceOrderReportHandler')]
    [Scope('OnPrem')]
    procedure CreateAndPrintServiceOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceCost: Record "Service Cost";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceOrderReport: Report "Service Order";
        ReportAmount: Variant;
        DiscountPct: Decimal;
        GrossAmount: Decimal;
        ShowQty: Option Quantity,"Quantity Invoiced";
    begin
        // Test to verify Invoice Discount Amount by printing Service Order report.

        // 1. Setup : Modify Sales Receivables Setup, Create Customer, Item, Customer Invoice Discount, Service Order and Calculate Invoice Discount.
        Initialize();
        UpdateCalculateInvoiceDiscount(true);
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        DiscountPct := LibraryRandom.RandDecInRange(5, 10, 2);  // Generate Random Value for Discount Percent.
        CreateCustomerInvoiceDiscount(Customer."No.", DiscountPct);
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.FindServiceCost(ServiceCost);
        CreateAndUpdateServiceLine(ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, 1, ServiceItemLine."Line No.");  // Take 1 for Quantity.
        GetServiceLine(ServiceLine, ServiceHeader."Document Type", ServiceHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServiceLine);

        // 2. Exercise : Run the Report.
        Commit();
        Clear(ServiceOrderReport);
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        ServiceOrderReport.SetTableView(ServiceHeader);
        ServiceOrderReport.InitializeRequest(false, ShowQty::Quantity);
        ServiceOrderReport.Run();

        GrossAmount := LibraryService.GetServiceOrderReportGrossAmount(ServiceLine);

        // 3. Verify : Verify Gross Amount in Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_ServLine', ServiceLine."Document No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the service item no');

        LibraryReportDataset.FindCurrentRowValue('GrossAmt', ReportAmount);
        Assert.AreNearlyEqual(GrossAmount, ReportAmount, LibraryERM.GetAmountRoundingPrecision(), GrossAmountError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ContractGainLossEntriesReportHandler')]
    [Scope('OnPrem')]
    procedure ContractQuotesGainLossEntries()
    var
        Customer: Record Customer;
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        ContractGainLossEntries: Report "Contract Gain/Loss Entries";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // Test that value of Contract Quote Gain in Contract Gain/Loss Entries matches the value of Line Amount in corresponding
        // Service Contract Line.

        // 1. Setup.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Quote, Customer."No.");

        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);

        AmountsInServiceContractHeader(ServiceContractHeader);

        // 2. Exercise: Generate the Service Items report.
        SignServContractDoc.SignContractQuote(ServiceContractHeader);
        Commit();
        Clear(ContractGainLossEntries);
        ContractGainLossEntry.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ContractGainLossEntry.FindFirst();
        ContractGainLossEntries.SetTableView(ContractGainLossEntry);
        ContractGainLossEntries.Run();

        // 3. Verify: Test that value of Contract Gain in Contract Gain/Loss Entries matches the value of Line Amount in
        // corresponding Service Contract Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ContNo_ContGainLossEntry', ContractGainLossEntry."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with Service contract no');
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), 'no more lines should exist');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler,ContractTemplateListHandler,ContractPriceUpdateTestReportHandler')]
    [Scope('OnPrem')]
    procedure ContractPriceUpdateAnnualAmount()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractHeader2: Record "Service Contract Header";
        ContractPriceUpdateTest: Report "Contract Price Update - Test";
        UpdatePercent: Decimal;
    begin
        // Test that value of Annual Amount in Contract Price Update Test matches the value of
        // Annual Amount Field in corresponding Service Contract Header.

        // 1. Setup: Create and Sign Service Contract.
        Initialize();

        CreateAndSignServiceContract(ServiceContractHeader);
        CreateAndSignServiceContract(ServiceContractHeader2);
        // 2. Exercise: Generate Contract Price Update Test Report.
        Commit();
        Clear(ContractPriceUpdateTest);
        UpdatePercent := LibraryRandom.RandDecInRange(5, 10, 2);
        ContractPriceUpdateTest.InitVariables(
          UpdatePercent, CalcDate('<' + Format(LibraryRandom.RandInt(2)) + 'M>', ServiceContractHeader."Starting Date"));
        ContractPriceUpdateTest.Run();

        // 3. Verify: Check that value of Annual Amount in Contract Price Update Test matches the value of
        // Annual Amount Field in corresponding Service Contract Header.
        VerifyContractPriceUpdateAnnualAmount(ServiceContractHeader2);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestReportHandler')]
    [Scope('OnPrem')]
    procedure InvDiscAmountPrintedInTestReportWhenInvDiscNotAllowInFirstServLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServTestReportPrint: Codeunit "Serv. Test Report Print";
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
        DiscountPct: Decimal;
        ExpectedInvDiscAmount: Decimal;
        ServiceItemLineNo: Integer;
    begin
        // [FEATURE] [Invoice Discount]
        // [SCENARIO 375187] Total Invoice Discount Amount should be printed in "Service Document - Test" report when "Allow Inv. Disc." is not mark in first Service Line

        Initialize();
        // [GIVEN] Service Order with two lines. "Allow Inv. Discount" is on only for the second line. "Inv. Disc. Amount" = "X"
        UpdateCalculateInvoiceDiscount(true);
        ReportSelectionMgt.UpdateReportSelection("Report Selection Usage"::"SM.Test", '1', Report::"Service Document - Test");

        CreateServiceOrderWithDiscount(ServiceHeader, ServiceItemLineNo, DiscountPct);
        CreateServiceLineWithAllowInvDisc(ServiceLine, ServiceHeader, ServiceItemLineNo, false);
        CreateServiceLineWithAllowInvDisc(ServiceLine, ServiceHeader, ServiceItemLineNo, true);
        ExpectedInvDiscAmount :=
          Round(ServiceLine.Amount * DiscountPct / 100, LibraryERM.GetAmountRoundingPrecision());
        Commit();

        // [WHEN] Print "Service Document - Test" report
        ServTestReportPrint.PrintServiceHeader(ServiceHeader);

        // [THEN] Invoice Discount Amount is printed and value = "X"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Service_Line___No__', ServiceLine."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), FindElemWithServiceNoMsg);
        LibraryReportDataset.AssertElementWithValueExists('SumInvDiscountAmount', ExpectedInvDiscAmount);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestReportHandler')]
    [Scope('OnPrem')]
    procedure SellToAddrInTestReport()
    var
        ServiceHeader: Record "Service Header";
        ServTestReportPrint: Codeunit "Serv. Test Report Print";
        ReportSelectionMgt: Codeunit "Report Selection Mgt.";
    begin
        // [SCENARIO 375362] Section "Customer" of Test Report should contain Sell-to address from Service Order header
        Initialize();
        ReportSelectionMgt.UpdateReportSelection("Report Selection Usage"::"SM.Test", '1', Report::"Service Document - Test");

        // [GIVEN] Service order with different Sell-to and Ship-to Addresses
        CreateServiceOrderWithSelltoAddress(ServiceHeader);
        FillServiceOrderShiptoAddressValuesAreNotSameSellto(ServiceHeader);
        Commit();

        // [WHEN] Print "Service Document - Test" report
        ServTestReportPrint.PrintServiceHeader(ServiceHeader);

        // [THEN] Report should contain correct Sell-to address
        VerifyCustomerAddressInTestReport(ServiceHeader);
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestReportHandler')]
    [Scope('OnPrem')]
    procedure ServiceTestReportWithDimensions()
    var
        ServiceHeader: Record "Service Header";
        ServiceDocumentTest: Report "Service Document - Test";
        DimText: Text;
    begin
        // [FEATURE] [Dimensions]
        // [SCENARIO 376031] Long Dimension text should be printed fully for both Header and Lines in Test Report
        Initialize();

        // [GIVEN] Service Order with Dimensions that give long length string
        DimText := CreateServiceOrderWithDimensions(ServiceHeader);
        Commit();

        // [WHEN] Print "Service Document - Test" report with 'Show Dimensions'
        ServiceHeader.SetRecFilter();
        ServiceDocumentTest.SetTableView(ServiceHeader);
        ServiceDocumentTest.InitializeRequest(false, false, true);
        ServiceDocumentTest.Run();

        // [THEN] All header dimensions are printed in the report
        // [THEN] All line dimensions are printed in the report
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimText', DimText);
        LibraryReportDataset.AssertElementWithValueExists('DimText_Control159', DimText);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ContractTemplateListHandler,MessageHandler,ServiceInvoiceToExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportSerialNo()
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SignServContractDoc: Codeunit SignServContractDoc;
        SerialNo: Code[50];
    begin
        // [FEATURE] [Service Contract]
        // [SCENARIO 355864] "Serial No." of Service Item is shown in table part on printed page of Service Invoice.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Signed Service Contract with Service Item "SI", that has "Serial No." = "SN".
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, LibrarySales.CreateCustomerNo());
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        UpdateSerialNoOnServiceItem(ServiceContractLine."Service Item No.", SerialNo);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);

        // [GIVEN] Posted Service Inovoice for Service Contract.
        CreateAndPostServiceInvoice(ServiceContractHeader);
        FindFirstServiceInvoiceOnServiceContract(ServiceInvoiceHeader, ServiceContractHeader."Contract No.");

        // [WHEN] Run report "Service - Invoice" for Service Invoice, save report output to Excel file.
        ServiceInvoiceHeader.SetRecFilter();
        Report.Run(Report::"Service - Invoice", true, false, ServiceInvoiceHeader);

        // [THEN] "Serial No." "SN" is printed in column "Serial No." for Service Invoice Line with "No." = "SI".
        VerifySerialNoInServiceInvoiceReport(SerialNo);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceToExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceReportServiceItemSerialNo()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SerialNo: Code[50];
    begin
        // [FEATURE] [Service Contract]
        // [SCENARIO 428308] "Service Item Serial No." printed for posted service invoice
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        SerialNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Service Order with Service Item "SI", that has "Serial No." = "SN".
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceDocumentForCustomerNo(ServiceHeader, "Service Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceItem.Validate("Serial No.", SerialNo);
        ServiceItem.Modify();
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.TestField("Service Item Serial No.", SerialNo);

        // [GIVEN] Post Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [WHEN] Run report "Service - Invoice" for Service Invoice, save report output to Excel file.
        ServiceInvoiceHeader.SetRange("Customer No.", Customer."No.");
        Report.Run(Report::"Service - Invoice", true, false, ServiceInvoiceHeader);

        // [THEN] "Serial No." "SN" is printed in column "Serial No." for Service Invoice Line with "No." = "SI".
        VerifySerialNoInServiceInvoiceReport(SerialNo);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceContractConfirmHandler,SelectServiceContractTemplateListHandler,ContractInvoicingReportHandler')]
    procedure CreateServContractInvReportPrintsLineAmountOfNonPrepaidServContractInExpectedInvAmt()
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractTemplate: Record "Service Contract Template";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        // [SCENARIO 555819] Expected Invoice Amount in Create Service Contracts Invoice Report
        // Opened with Print Only is equal to the total of Line Value in non prepaid Service Contract.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Service Item and Validate Item No.
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Contract Template.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CreateContrUsingTemplateQst);
        CreateServiceContractTemplate(ServiceContractTemplate, '<1Y>', ServiceContractHeader."Invoice Period"::Year, true, true, true);

        // [GIVEN] Create a Service Contract Header.
        LibraryVariableStorage.Enqueue(ServiceContractTemplate."No.");
        CreateServiceContractHeader(ServiceContractHeader, Customer);

        // [GIVEN] Create a Service Contract Line and Validate Line Cost and Line Value.
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");
        ServiceContractLine.Validate("Line Cost", 0);
        ServiceContractLine.Validate("Line Value", LibraryRandom.RandIntInRange(100, 100));
        ServiceContractLine.Modify(true);

        // [GIVEN] Create a Service Contract Account Group.
        LibraryService.CreateServiceContractAcctGrp(ServiceContractAccountGroup);

        // [GIVEN] Validate Annual Amount, Serv. Contract Acc. Gr. Code,
        // Invoice Period and Prepaid in Service Contract Header.
        ServiceContractHeader.Validate("Annual Amount", LibraryRandom.RandIntInRange(100, 100));
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Validate("Invoice Period", ServiceContractHeader."Invoice Period"::Year);
        ServiceContractHeader.Validate(Prepaid, false);
        ServiceContractHeader.Modify(true);

        // [GIVEN] Sign Contract.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(StrSubstNo(SignServContractQst, ServiceContractHeader."Contract No."));
        SignServContractDoc.SignContract(ServiceContractHeader);
        Commit();

        // [WHEN] Run Create Service Contract Invoices Report.
        RunCreateContractInvoices(ServiceContractHeader);

        // [THEN] Expected Invoice Amount in Create Service Contract Invoices Report
        // Is equal to Line Value of Service Contract Line.
        VerifyContractInvoicingExpectedInvAmount(ServiceContractHeader, ServiceContractLine);
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceToExcelRequestPageHandler')]
    procedure ServiceInvoiceShowsTranslatedVATClause()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATClause: Record "VAT Clause";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClauseTranslation: Record "VAT Clause Translation";
        Customer: Record Customer;
        Language: Record Language;
        ServiceInvoiceNo: Code[20];
    begin
        // [SCENARIO 575517] Check Report 5911 "Service - Invoice" shows the translated VAT Clause.
        Initialize();

        // [GIVEN] Language code "DEU".
        Language.Validate(Code, LibraryUtility.GenerateGUID());
        Language.Insert(true);

        // [GIVEN] VAT Posting Setup with the VAT clause that has a translation for the language code "X". Description = "Beschreibung 1", "Description 2" ="Beschreibung 2"
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        LibraryERM.CreateVATClause(VATClause);
        VATPostingSetup.Validate("VAT Clause Code", VATClause.Code);
        VATPostingSetup.Modify(true);

        // [GIVEN] Create VAT Clause Translation.
        CreateVATClauseTranslation(VATClauseTranslation, VATClause.Code, Language.Code);

        // [GIVEN] Service Invoice with the VAT Posting setup associated with the VAT Clause.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Language Code", Language.Code);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        CreateServiceLineWithItemWithVATPostingSetup(ServiceHeader, VATPostingSetup);

        // [GIVEN] Posted Service Invoice.
        ServiceInvoiceNo := PostServiceInvoice(ServiceHeader);
        ServiceInvoiceHeader.Get(ServiceInvoiceNo);
        ServiceInvoiceHeader.SetRecFilter();

        // [WHEN] Run report "Service - Invoice" for Posted Service Invoice.
        Report.Run(Report::"Service - Invoice", true, false, ServiceInvoiceHeader);

        // [THEN] Report DataSet contains VAT Clause fields: "Beschreibung 1" and "Beschreibung 2".
        LibraryReportValidation.OpenExcelFile();
        VerifyVATClauseTranslationDescription(VATClauseTranslation);//assert
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Reports");
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Reports");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Reports");
    end;

    local procedure ServiceDocumentTestShowDimension(ValuePosting: Enum "Default Dimension Value Posting Type")
    var
        Customer: Record Customer;
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        ServiceOrderNo: Code[20];
    begin
        // 1. Setup: Create Customer, Dimension, Dimension value, create an account type Default Dimension, create default dimension for Customer and create a Service Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", Dimension.Code, DimensionValue.Code);
        LibraryDimension.CreateAccTypeDefaultDimension(
          DefaultDimension, DATABASE::Resource, Dimension.Code, DimensionValue.Code, ValuePosting);
        ServiceOrderNo := CreateServiceOrder(Customer."No.");

        // 2. Exercise: Run Service Document Test Report.
        RunServiceDocumentTestReport(ServiceOrderNo);

        // 3. Verify: Verify that correct Line Dimension is populated on Service Document Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimText',
          StrSubstNo('%1 - %2', DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));

        // 4. Tear Down: Delete the Default Dimensions created.
        DefaultDimension.Delete(true);
    end;

    local procedure AmountsInServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.CalcFields("Calcd. Annual Amount");
        ServiceContractHeader.Validate("Annual Amount", ServiceContractHeader."Calcd. Annual Amount");
        ServiceContractHeader.Validate("Starting Date", WorkDate());
        ServiceContractHeader.Validate("Price Update Period", ServiceContractHeader."Service Period");
        ServiceContractHeader.Modify(true);
    end;

    local procedure CalculateAmountLCY(ServiceOrderNo: Code[20]) AmountLCY: Decimal
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FindServiceLedgerEntry(ServiceLedgerEntry, ServiceOrderNo);
        repeat
            AmountLCY += ServiceLedgerEntry."Amount (LCY)";
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure CalculateCostAmount(ServiceOrderNo: Code[20]) CostAmount: Decimal
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FindServiceLedgerEntry(ServiceLedgerEntry, ServiceOrderNo);
        repeat
            CostAmount += ServiceLedgerEntry."Cost Amount";
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure CalculateDiscountAmount(ServiceOrderNo: Code[20]) DiscountAmount: Decimal
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
    begin
        FindServiceLedgerEntry(ServiceLedgerEntry, ServiceOrderNo);
        repeat
            DiscountAmount += ServiceLedgerEntry."Discount Amount";
        until ServiceLedgerEntry.Next() = 0;
    end;

    local procedure CreateContractHeaderAccGroup(var ServiceContractHeader: Record "Service Contract Header"; ContractType: Enum "Service Contract Type"; CustomerNo: Code[20])
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ContractType, CustomerNo);
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Modify(true);
    end;

    local procedure CreateContractWithExpiredLine(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20])
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        LibraryService.CreateServiceContractHeader(
          ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        DatesInServiceContractLine(ServiceContractLine, WorkDate());
        AmountsInServiceContractHeader(ServiceContractHeader);
    end;

    local procedure CreateCreditMemoFromContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
        ExpirationDate: Date;
    begin
        FindServiceContractLines(ServiceContractLine, ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");

        // Expiration Date should be set after Starting Date.
        ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'D>', ServiceContractHeader."Starting Date");
        ServiceContractLine.Validate("Credit Memo Date", ExpirationDate);
        DatesInServiceContractLine(ServiceContractLine, ExpirationDate);
        ServContractManagement.CreateContractLineCreditMemo(ServiceContractLine, false);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateContractGainLossEntries(var ServiceContractHeader: Record "Service Contract Header"; CustomerNo: Code[20])
    var
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, CustomerNo);
        ServiceContractAccountHeader(ServiceContractHeader);
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure CreateHeaderWithResponsibility(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Responsibility Center", ResponsibilityCenter.Code);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateAndSignServiceContract(var ServiceContractHeader: Record "Service Contract Header")
    var
        Customer: Record Customer;
        ServiceContractLine: Record "Service Contract Line";
        SignServContractDoc: Codeunit SignServContractDoc;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateContractHeaderAccGroup(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        CreateServiceContractLine(ServiceContractLine, ServiceContractHeader);
        AmountsInServiceContractHeader(ServiceContractHeader);
        SignServContractDoc.SignContract(ServiceContractHeader);
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(5, 100, 2));  // Use Random because value is not important.
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateReasonCode(): Code[10]
    var
        ReasonCode: Record "Reason Code";
    begin
        LibraryERM.CreateReasonCode(ReasonCode);
        exit(ReasonCode.Code);
    end;

    local procedure CreateServiceOrderWithDiscount(var ServiceHeader: Record "Service Header"; var ServiceItemLineNo: Integer; var DiscountPct: Decimal)
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        DiscountPct := LibraryRandom.RandInt(10);
        CreateCustomerInvoiceDiscount(Customer."No.", DiscountPct);
        CreateServiceHeaderWithItemLine(
          ServiceHeader, ServiceItemLine, ServiceItem, Customer."No.", ServiceHeader."Document Type"::Order);
        ServiceItemLineNo := ServiceItemLine."Line No.";
    end;

    local procedure CreateServiceOrderWithSelltoAddress(var ServiceHeader: Record "Service Header")
    var
        CountryRegion: Record "Country/Region";
        Option: Option Capitalized,"Literal and Capitalized";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        ServiceHeader.Name := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ServiceHeader.Name), Option::Capitalized), 1, MaxStrLen(ServiceHeader.Name));
        ServiceHeader."Name 2" :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ServiceHeader."Name 2"), Option::Capitalized), 1, MaxStrLen(ServiceHeader."Name 2"));
        ServiceHeader."Contact Name" :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ServiceHeader."Contact Name"), Option::Capitalized),
            1, MaxStrLen(ServiceHeader."Contact Name"));
        ServiceHeader.Address := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ServiceHeader.Address), Option::Capitalized), 1, MaxStrLen(ServiceHeader.Address));
        ServiceHeader."Address 2" :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ServiceHeader."Address 2"), Option::Capitalized), 1, MaxStrLen(ServiceHeader."Address 2"));
        ServiceHeader.City := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ServiceHeader.City), Option::Capitalized), 1, MaxStrLen(ServiceHeader.City));
        ServiceHeader."Post Code" :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ServiceHeader."Post Code"), Option::Capitalized), 1, MaxStrLen(ServiceHeader."Post Code"));
        ServiceHeader.County := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(ServiceHeader.County), Option::Capitalized), 1, MaxStrLen(ServiceHeader.County));
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate(Name,
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(CountryRegion.Name)), MaxStrLen(CountryRegion.Name)));
        ServiceHeader."Country/Region Code" := CountryRegion.Code;
        ServiceHeader.Modify();
    end;

    local procedure FillServiceOrderShiptoAddressValuesAreNotSameSellto(var ServiceHeader: Record "Service Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        ServiceHeader."Ship-to Name" := CopyStr(ServiceHeader.Name, 2);
        ServiceHeader."Ship-to Name 2" := CopyStr(ServiceHeader."Name 2", 2);
        ServiceHeader."Ship-to Contact" := CopyStr(ServiceHeader."Contact Name", 2);
        ServiceHeader."Ship-to Address" := CopyStr(ServiceHeader.Address, 2);
        ServiceHeader."Ship-to Address 2" := CopyStr(ServiceHeader."Address 2", 2);
        ServiceHeader."Ship-to City" := CopyStr(ServiceHeader.City, 2);
        ServiceHeader."Ship-to Post Code" := CopyStr(ServiceHeader."Post Code", 2);
        ServiceHeader."Ship-to County" := CopyStr(ServiceHeader.County, 2);
        LibraryERM.CreateCountryRegion(CountryRegion);
        ServiceHeader."Ship-to Country/Region Code" := CountryRegion.Code;
        ServiceHeader.Modify();
    end;

    local procedure CreateServiceOrderWithDimensions(var ServiceHeader: Record "Service Header") DimText: Text
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        DimensionValue: Record "Dimension Value";
        DimSetID: Integer;
    begin
        CreateServiceHeaderWithItemLine(
          ServiceHeader, ServiceItemLine, ServiceItem, LibrarySales.CreateCustomerNo(), ServiceHeader."Document Type"::Order);
        repeat
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code);
            if DimText <> '' then
                DimText += '; ';
            DimText += DimensionValue."Dimension Code" + ' - ' + DimensionValue.Code;
        until StrLen(DimText) > 120;
        ServiceHeader.Validate("Dimension Set ID", DimSetID);
        ServiceHeader.Modify(true);
        CreateServiceLineWithItem(ServiceLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceHeaderWithItemLine(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; DocumentType: Enum "Service Document Type")
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceItem: Record "Service Item";
        ServicePeriod: DateFormula;
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceContractHeader."Customer No.");
        LibraryService.CreateServiceContractLine(ServiceContractLine, ServiceContractHeader, ServiceItem."No.");

        // Use Random because value is not important.
        ServiceContractLine.Validate("Line Cost", 1000 * LibraryRandom.RandDecInRange(5, 10, 2));
        ServiceContractLine.Validate("Line Value", 1000 * LibraryRandom.RandDecInRange(5, 10, 2));
        Evaluate(ServicePeriod, '<' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'M>');
        ServiceContractLine.Validate("Service Period", ServicePeriod);
        ServiceContractLine.Modify(true);
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer)
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(5, 10, 2));  // Use Random because value is not important.
        ServiceLine.Validate("Unit Price", LibraryRandom.RandIntInRange(5, 100));
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity * LibraryUtility.GenerateRandomFraction());
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithItem(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(
          Quantity, LibraryRandom.RandDecInRange(5, 100, 2));  // Required field - value is not important to test case.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithResource(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        Resource: Record Resource;
    begin
        LibraryResource.FindResource(Resource);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, Resource."No.");
        ServiceLine.Validate("Service Item No.", ServiceItemNo);
        ServiceLine.Validate(
          Quantity, LibraryRandom.RandDecInRange(5, 100, 2));  // Required field - value is not important to test case.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceLineWithAllowInvDisc(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer; AllowInvDiscount: Boolean)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndUpdateServiceLine(
          ServiceHeader, ServiceLine.Type::Item, Item."No.", LibraryRandom.RandInt(10), ServiceItemLineNo);
        ServiceLine.SetRange("No.", Item."No.");
        GetServiceLine(ServiceLine, ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceLine.Validate("Allow Invoice Disc.", AllowInvDiscount);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceQuoteComment(var ServiceCommentLine: Record "Service Comment Line"; ServiceContractLine: Record "Service Contract Line")
    begin
        LibraryService.CreateCommentLineForServCntrct(ServiceCommentLine, ServiceContractLine, ServiceCommentLine.Type::General);
        ServiceCommentLine.Validate(Date, WorkDate());
        ServiceCommentLine.Modify(true);
    end;

    local procedure CreateAndPostServiceInvoice(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServiceContractHeader.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.");
        ServContractManagement.InitCodeUnit();
        ServContractManagement.CreateInvoice(ServiceContractHeader);
        PostServiceInvoice(ServiceContractHeader."Contract No.");
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Modify(true);
    end;

    local procedure CreateAndUpdateServiceLine(ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; Quantity: Decimal; ServiceItemLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(5, 100, 2));  // Take Random Value for Unit Price.
        ServiceLine.Modify(true);
    end;

    local procedure CreateCustomerInvoiceDiscount(CustomerNo: Code[20]; DiscountPct: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);  // Take Blank for Currency And Zero for Min. Amount.
        CustInvoiceDisc.Validate("Discount %", DiscountPct);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure DatesInServiceContractLine(var ServiceContractLine: Record "Service Contract Line"; ContractExpirationDate: Date)
    var
        ServicePeriod: DateFormula;
    begin
        // Use random value for Service Period.
        Evaluate(ServicePeriod, '<' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'M>');
        ServiceContractLine.Validate("Service Period", ServicePeriod);
        ServiceContractLine.Validate("Contract Expiration Date", ContractExpirationDate);
        ServiceContractLine.Modify(true);
    end;

    local procedure FindFaultCode(var FaultCode: Record "Fault Code")
    var
        FaultArea: Record "Fault Area";
        SymptomCode: Record "Symptom Code";
    begin
        LibraryService.CreateFaultArea(FaultArea);
        LibraryService.CreateSymptomCode(SymptomCode);
        LibraryService.CreateFaultCode(FaultCode, FaultArea.Code, SymptomCode.Code);
    end;

    local procedure FindFaultReasonCode(): Code[10]
    var
        FaultReasonCode: Record "Fault Reason Code";
    begin
        LibraryService.FindFaultReasonCode(FaultReasonCode);
        exit(FaultReasonCode.Code);
    end;

    local procedure FindRepairStatus(): Code[10]
    var
        RepairStatus: Record "Repair Status";
    begin
        RepairStatus.SetRange("Quote Finished", false);
        RepairStatus.Init();
        RepairStatus.FindFirst();
        exit(RepairStatus.Code);
    end;

    local procedure FindServiceLedgerEntry(var ServiceLedgerEntry: Record "Service Ledger Entry"; ServiceOrderNo: Code[20])
    begin
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::Shipment);
        ServiceLedgerEntry.SetRange("Service Order No.", ServiceOrderNo);
        ServiceLedgerEntry.FindSet();
    end;

    local procedure FindServiceContractLines(var ServiceContractLine: Record "Service Contract Line"; ContractType: Enum "Service Contract Type"; ContractNo: Code[20])
    begin
        ServiceContractLine.SetRange("Contract Type", ContractType);
        ServiceContractLine.SetRange("Contract No.", ContractNo);
        ServiceContractLine.FindSet();
    end;

    local procedure FindFirstServiceInvoiceOnServiceContract(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceContractNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Contract No.", ServiceContractNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure GetServiceLine(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; No: Code[20])
    begin
        ServiceLine.SetRange("Document Type", DocumentType);
        ServiceLine.SetRange("Document No.", No);
        ServiceLine.FindSet();
    end;

    local procedure FilterServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractHeader.FindFirst();
    end;

    local procedure ModifyHeaderForPrepaid(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-CM>', WorkDate()));  // Validate first date of month.
        ServiceContractHeader.Validate(Prepaid, true);
        ServiceContractHeader.Modify(true);
    end;

    local procedure PostServiceInvoice(ServiceContractNo: Code[20])
    var
        ServiceDocumentRegister: Record "Service Document Register";
        ServiceHeader: Record "Service Header";
    begin
        // Find the Service Invoice by searching in Service Document Register.
        ServiceDocumentRegister.SetRange("Source Document Type", ServiceDocumentRegister."Source Document Type"::Contract);
        ServiceDocumentRegister.SetRange("Source Document No.", ServiceContractNo);
        ServiceDocumentRegister.SetRange("Destination Document Type", ServiceDocumentRegister."Destination Document Type"::Invoice);
        ServiceDocumentRegister.FindFirst();
        ServiceHeader.Get(ServiceHeader."Document Type"::Invoice, ServiceDocumentRegister."Destination Document No.");
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
    end;

    local procedure UpdateContractExpirationDate(var ServiceContractLine: Record "Service Contract Line"; ContractExpirationDate: Date)
    begin
        ServiceContractLine.Validate("Contract Expiration Date", ContractExpirationDate);
        ServiceContractLine.Modify(true);
    end;

    local procedure UpdateExpirationDateOnHeader(var ServiceContractHeader: Record "Service Contract Header")
    begin
        ServiceContractHeader.Validate("Expiration Date", WorkDate());
        ServiceContractHeader.Modify(true);
    end;

    local procedure UpdateReasonOnServiceSetup()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Use Contract Cancel Reason", true);
        ServiceMgtSetup.Modify(true);
    end;

    local procedure ResponsibilityCenterHeader(var ServiceContractHeader: Record "Service Contract Header")
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        ServiceContractHeader.Validate("Responsibility Center", ResponsibilityCenter.Code);
        ServiceContractHeader.Modify(true);
    end;

    local procedure RunServiceContractQuote(ContractNo: Code[20]; ShowComments: Boolean)
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractQuote: Report "Service Contract Quote";
    begin
        Commit();
        Clear(ServiceContractQuote);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Quote);
        ServiceContractHeader.SetRange("Contract No.", ContractNo);
        ServiceContractQuote.SetTableView(ServiceContractHeader);
        ServiceContractQuote.InitializeRequestComment(ShowComments);
        ServiceContractQuote.Run();
    end;

    local procedure RunServiceContractQuoteDetail(ContractNo: Code[20]; ShowComments: Boolean)
    var
        ServiceContractHeader: Record "Service Contract Header";
        ServiceContractQuoteDetail: Report "Service Contract Quote-Detail";
    begin
        Commit();
        Clear(ServiceContractQuoteDetail);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Quote);
        ServiceContractHeader.SetRange("Contract No.", ContractNo);
        ServiceContractQuoteDetail.SetTableView(ServiceContractHeader);
        ServiceContractQuoteDetail.InitializeRequest(ShowComments);
        ServiceContractQuoteDetail.Run();
    end;

    local procedure RunContractQuotesToBeSigned(ServiceContractHeader: Record "Service Contract Header"; ForecastIncluded: Boolean)
    var
        ContractQuotesToBeSigned: Report "Contract Quotes to Be Signed";
    begin
        Commit();
        Clear(ContractQuotesToBeSigned);
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Quote);
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");

        ContractQuotesToBeSigned.SetTableView(ServiceContractHeader);
        ContractQuotesToBeSigned.InitializeRequest(ForecastIncluded);
        ContractQuotesToBeSigned.Run();
    end;

    local procedure RunServiceProfitRespCenters(ResponsibilityCenter: Code[10])
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceProfitRespCenters: Report "Service Profit (Resp. Centers)";
    begin
        Clear(ServiceProfitRespCenters);
        ServiceShipmentHeader.SetRange("Responsibility Center", ResponsibilityCenter);
        ServiceProfitRespCenters.SetTableView(ServiceShipmentHeader);
        ServiceShipmentHeader.FindFirst();
        ServiceProfitRespCenters.InitializeRequest(true);

        ServiceProfitRespCenters.Run();
    end;

    local procedure RunServiceQuoteReport(No: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceQuote: Report "Service Quote";
    begin
        Commit();
        Clear(ServiceQuote);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Quote);
        ServiceHeader.SetRange("No.", No);
        ServiceQuote.SetTableView(ServiceHeader);
        ServiceQuote.Run();
    end;

    local procedure RunContractInvoicingReport(ServiceContractHeader: Record "Service Contract Header"; PostingDate: Date; InvoiceToDate: Date)
    var
        ContractInvoicing: Report "Contract Invoicing";
    begin
        Commit();
        Clear(ContractInvoicing);
        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ContractInvoicing.SetTableView(ServiceContractHeader);
        ContractInvoicing.InitVariables(PostingDate, InvoiceToDate);
        ContractInvoicing.Run();
    end;

    local procedure ServiceContractAccountHeader(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractAccountGroup: Record "Service Contract Account Group";
    begin
        LibraryService.FindContractAccountGroup(ServiceContractAccountGroup);
        ServiceContractHeader.Validate("Serv. Contract Acc. Gr. Code", ServiceContractAccountGroup.Code);
        ServiceContractHeader.Modify(true);
    end;

    local procedure ServiceItemLineFaultSymptom(var ServiceItemLine: Record "Service Item Line")
    var
        FaultCode: Record "Fault Code";
    begin
        FindFaultCode(FaultCode);
        ServiceItemLine.Validate("Fault Reason Code", FindFaultReasonCode());
        ServiceItemLine.Validate("Fault Area Code", FaultCode."Fault Area Code");
        ServiceItemLine.Validate("Symptom Code", FaultCode."Symptom Code");
        ServiceItemLine.Validate("Fault Code", FaultCode.Code);
        ServiceItemLine.Validate("Repair Status Code", FindRepairStatus());
        ServiceItemLine.Modify(true);
    end;

    local procedure UpdateQuantityServiceLine(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(5, 10, 2));  // Use Random because value is not important.
        ServiceLine.Modify(true);
    end;

    local procedure WarrantyEndingDatePartsItem(var ServiceItem: Record "Service Item")
    begin
        ServiceItem.Validate("Warranty Ending Date (Parts)", WorkDate());
        ServiceItem.Modify(true);
    end;

    local procedure CreateServiceLineOfTypeCost(ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        ServiceCost: Record "Service Cost";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.FindServiceCost(ServiceCost);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code);
        ServiceLine.Validate("Service Item No.", ServiceItemNo);

        // Use the random value for Quantity.
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(5, 100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(CustomerNo: Code[20]): Code[20]
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceHeaderWithItemLine(
          ServiceHeader, ServiceItemLine, ServiceItem, CustomerNo, ServiceHeader."Document Type"::Order);
        CreateServiceLineOfTypeCost(ServiceHeader, ServiceItem."No.");
        exit(ServiceHeader."No.");
    end;

    local procedure RunServiceDocumentTestReport(No: Code[20])
    var
        ServiceHeader: Record "Service Header";
        ServiceDocumentTest: Report "Service Document - Test";
    begin
        Commit();
        Clear(ServiceDocumentTest);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceHeader.SetRange("No.", No);
        ServiceDocumentTest.SetTableView(ServiceHeader);
        ServiceDocumentTest.InitializeRequest(true, true, true);
        ServiceDocumentTest.Run();
    end;

    local procedure UpdateCalculateInvoiceDiscount(CalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateSerialNoOnServiceItem(ServiceItemNo: Code[20]; SerialNo: Code[50])
    var
        ServiceItem: Record "Service Item";
    begin
        ServiceItem.Get(ServiceItemNo);
        ServiceItem.Validate("Serial No.", SerialNo);
        ServiceItem.Modify(true);
    end;

    local procedure VerifyCommentOnReport(ServiceCommentLine: Record "Service Comment Line")
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Comment_ServCommentLine', ServiceCommentLine.Comment);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the comment');
    end;

    local procedure VerifyContractInvoicing(ServiceContractHeader: Record "Service Contract Header")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('CustNo_ServContract', ServiceContractHeader."Customer No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the customer no');

        LibraryReportDataset.AssertCurrentRowValueEquals('ContractNo1_ServContract', ServiceContractHeader."Contract No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('NextInvDate_ServContract', Format(ServiceContractHeader."Next Invoice Date"));
    end;

    local procedure VerifyContractInvoicingNextInvoicePeriod(ServiceContractHeader: Record "Service Contract Header")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.MoveToRow(2);

        LibraryReportDataset.AssertCurrentRowValueEquals(
          'ContractInvPeriod',
          Format(ServiceContractHeader."Next Invoice Period Start") + '..' + Format(ServiceContractHeader."Next Invoice Period End"));
    end;

    local procedure VerifyMaintenanceVisitPlanning(ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
    begin
        ServiceContractLine.Get(ServiceContractHeader."Contract Type", ServiceContractHeader."Contract No.", 10000);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ContrNo_ServContractLine', ServiceContractHeader."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the contract no');

        LibraryReportDataset.AssertCurrentRowValueEquals('RespCntr_ServContractHdr', ServiceContractHeader."Responsibility Center");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustNo_ServContractLine', ServiceContractHeader."Customer No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('NxtPlServDt_ServContractLine',
          Format(ServiceContractLine."Next Planned Service Date"));

        VerifyServicePeriod(ServiceContractLine, 'ServPerd_ServContractLine');
    end;

    local procedure VerifyServiceContractCustomer(ServiceContractHeader: Record "Service Contract Header")
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('ContractNo_ServContract', ServiceContractHeader."Contract No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the contract no');

        LibraryReportDataset.AssertCurrentRowValueEquals('AmtperPeriod_ServContract', ServiceContractHeader."Amount per Period");
        LibraryReportDataset.AssertCurrentRowValueEquals('AnnualAmount_ServContract', ServiceContractHeader."Annual Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('AmtOnExpiredLines', ServiceContractHeader."Annual Amount");
    end;

    local procedure VerifyServiceContractSalesper(ServiceContractHeader: Record "Service Contract Header")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('SlspersonCod_ServContract', ServiceContractHeader."Salesperson Code");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the salesperson code');

        LibraryReportDataset.AssertCurrentRowValueEquals('ContractNo_ServContract', ServiceContractHeader."Contract No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('AnnualAmount_ServContract', ServiceContractHeader."Annual Amount");
    end;

    local procedure VerifyServiceItemsOutWarranty(ServiceItem: Record "Service Item")
    begin
        LibraryReportDataset.LoadDataSetFile();
        ServiceItem.CalcFields(Name, "No. of Active Contracts");

        LibraryReportDataset.SetRange('No_ServItem', ServiceItem."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the service item no');

        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerNo_ServItem', ServiceItem."Customer No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Name_ServItem', ServiceItem.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals('Description_ServItem', ServiceItem.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('NoofActvContrct_ServItem', ServiceItem."No. of Active Contracts");
    end;

    local procedure VerifyServiceItemResource(ServiceItem: Record "Service Item")
    begin
        ServiceItem.CalcFields("Usage (Cost)", "Usage (Amount)");

        LibraryReportDataset.AssertCurrentRowValueEquals('UsageAmt_ServiceItem', ServiceItem."Usage (Amount)");
        LibraryReportDataset.AssertCurrentRowValueEquals('OrderProfit', ServiceItem."Usage (Amount)" - ServiceItem."Usage (Cost)");
        LibraryReportDataset.AssertCurrentRowValueEquals('OrderProfitPct',
          Round(100 * (ServiceItem."Usage (Amount)" - ServiceItem."Usage (Cost)") / ServiceItem."Usage (Amount)", 0.1));
    end;

    local procedure VerifyServiceItemResourceUsage(ServiceItem: Record "Service Item")
    begin
        ServiceItem.CalcFields("Total Quantity", "Usage (Amount)");

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ServiceItem', ServiceItem."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the service item no');

        VerifyServiceItemResource(ServiceItem);
    end;

    local procedure VerifyServiceItemWorksheet(ServiceItemLine: Record "Service Item Line"; ServiceLine: Record "Service Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ServItemNo_ServItemLine', ServiceItemLine."Service Item No.");
        LibraryReportDataset.SetRange('ServiceLinesCaption', 'Service Lines');
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the service item no');

        LibraryReportDataset.AssertCurrentRowValueEquals('RepStatusCode_ServItemLine', ServiceItemLine."Repair Status Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_ServLine', ServiceLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('FaultAreaCode_ServLine', ServiceLine."Fault Area Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Symptom_ServLine', ServiceLine."Symptom Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('FaultCode_ServLine', ServiceLine."Fault Code");
    end;

    local procedure VerifyServiceResourceDetail(ServiceItem: Record "Service Item")
    begin
        ServiceItem.CalcFields("Total Quantity", "Usage (Amount)");

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('No_ServiceItem', ServiceItem."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the service item no');

        LibraryReportDataset.AssertCurrentRowValueEquals('TotalQty_ServiceItem', ServiceItem."Total Quantity");

        VerifyServiceItemResource(ServiceItem);
    end;

    local procedure VerifyServicePeriod(ServiceContractLine: Record "Service Contract Line"; ElementName: Text)
    begin
        LibraryReportDataset.AssertCurrentRowValueEquals(ElementName, Format(ServiceContractLine."Service Period"));
    end;

    local procedure VerifyServiceTasks(ServiceItemLine: Record "Service Item Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocNo_ServItemLine', ServiceItemLine."Document No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the document no');

        LibraryReportDataset.AssertCurrentRowValueEquals('ResponseDate_ServItemLine', Format(ServiceItemLine."Response Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('Priority_ServItemLine', Format(ServiceItemLine.Priority));
    end;

    local procedure VerifyServiceContractLine(ServiceContractLine: Record "Service Contract Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ServItemNo_ServContractLine', ServiceContractLine."Service Item No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the service item no');

        LibraryReportDataset.AssertCurrentRowValueEquals('LineValue_ServContractLine', ServiceContractLine."Line Value");

        VerifyServicePeriod(ServiceContractLine, 'ServicePeriod_ServContractLine');
    end;

    local procedure VerifyServiceLineOnReport(DocumentNo: Code[20])
    var
        ServiceLine: Record "Service Line";
    begin
        GetServiceLine(ServiceLine, "Service Document Type"::Quote, DocumentNo);

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Type_ServLine', Format(ServiceLine.Type));
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the service Line type');

        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_ServLine', ServiceLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('LineDiscount_ServLine', ServiceLine."Line Discount %");
        LibraryReportDataset.AssertCurrentRowValueEquals('Amt', ServiceLine."Line Amount");
    end;

    local procedure VerifyServiceLedgerEntryAmount(ServiceShipmentHeader: Record "Service Shipment Header")
    begin
        LibraryReportDataset.SetRange('No_ServShptHeader', ServiceShipmentHeader."No.");
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('SalesAmount', CalculateAmountLCY(ServiceShipmentHeader."Order No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('CostAmount', CalculateCostAmount(ServiceShipmentHeader."Order No."));
        LibraryReportDataset.AssertCurrentRowValueEquals('DiscountAmount', CalculateDiscountAmount(ServiceShipmentHeader."Order No."));
    end;

    local procedure VerifyContractPriceUpdateAnnualAmount(ServiceContractHeader: Record "Service Contract Header")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Service_Contract_Header__Contract_No__', ServiceContractHeader."Contract No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OldAnnualAmount', ServiceContractHeader."Annual Amount");
    end;

    local procedure VerifyCustomerAddressInTestReport(ServiceHeader: Record "Service Header")
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('SellToAddr_1_', ServiceHeader.Name);
        LibraryReportDataset.AssertCurrentRowValueEquals('SellToAddr_2_', ServiceHeader."Name 2");
        LibraryReportDataset.AssertCurrentRowValueEquals('SellToAddr_3_', ServiceHeader."Contact Name");
        LibraryReportDataset.AssertCurrentRowValueEquals('SellToAddr_4_', ServiceHeader.Address);
        LibraryReportDataset.AssertCurrentRowValueEquals('SellToAddr_5_', ServiceHeader."Address 2");
        // Skip 'SellToAddr_6_' check as not important
        LibraryReportDataset.AssertCurrentRowValueEquals('SellToAddr_7_', ServiceHeader.County);
        CountryRegion.Get(ServiceHeader."Country/Region Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('SellToAddr_8_', CountryRegion.Name);
    end;

    local procedure VerifySerialNoInServiceInvoiceReport(SerialNo: Code[50])
    var
        ColumnNo: Integer;
        RowNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        ColumnNo := LibraryReportValidation.FindColumnNoFromColumnCaption('Serial No.');
        RowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(ColumnNo, 'Serial No.');
        Assert.AreNotEqual(
          0, LibraryReportValidation.FindRowNoFromColumnNoAndValueInsideArea(ColumnNo, SerialNo, StrSubstNo('>%1', RowNo)), '');
    end;

    local procedure RunCreateContractInvoices(ServiceContractHeader: Record "Service Contract Header")
    var
        CreateContractInvoices: Report "Create Contract Invoices";
        CreateInvoices: Option "Create Invoices","Print Only";
    begin
        ServiceContractHeader.SetRange("Contract Type", ServiceContractHeader."Contract Type"::Contract);
        ServiceContractHeader.SetRange("Customer No.", ServiceContractHeader."Customer No.");

        Clear(CreateContractInvoices);
        CreateContractInvoices.SetTableView(ServiceContractHeader);
        CreateContractInvoices.SetOptions(CalcDate('<-2Y-CY+5M+CM>', WorkDate()), CalcDate('<-1Y-CY+5M+CM>', WorkDate()), CreateInvoices::"Print Only");
        CreateContractInvoices.UseRequestPage(false);
        CreateContractInvoices.Run();
    end;

    local procedure UpdateTemplateNoOnServiceContract(var ServiceContractTemplateList: TestPage "Service Contract Template List"; No: Text)
    begin
        ServiceContractTemplateList.Filter.SetFilter("No.", No);
        ServiceContractTemplateList.OK().Invoke();
    end;

    local procedure CreateServiceContractTemplate(var ServiceContractTemplate: Record "Service Contract Template"; ServicePeriodTxt: Text; InvoicePeriod: Enum "Service Contract Header Invoice Period"; CombineInvoices: Boolean; ContractLinesOnInvoice: Boolean; IsPrepaid: Boolean)
    var
        DefaultServicePeriod: DateFormula;
    begin
        Evaluate(DefaultServicePeriod, ServicePeriodTxt);

        LibraryService.CreateServiceContractTemplate(ServiceContractTemplate, DefaultServicePeriod);
        ServiceContractTemplate.Validate("Invoice Period", InvoicePeriod);
        ServiceContractTemplate.Validate(Prepaid, IsPrepaid);
        ServiceContractTemplate.Validate("Combine Invoices", CombineInvoices);
        ServiceContractTemplate.Validate("Contract Lines on Invoice", ContractLinesOnInvoice);
        ServiceContractTemplate.Modify(true);
    end;

    local procedure CreateServiceContractHeader(var ServiceContractHeader: Record "Service Contract Header"; Customer: Record Customer)
    begin
        LibraryService.CreateServiceContractHeader(ServiceContractHeader, ServiceContractHeader."Contract Type"::Contract, Customer."No.");
        Evaluate(ServiceContractHeader."Service Period", '<4D>');
        ServiceContractHeader.Validate("Starting Date", CalcDate('<-2Y-CY+5M+CM>', WorkDate()));
        ServiceContractHeader.Validate("Allow Unbalanced Amounts", false);
        ServiceContractHeader.Validate("Combine Invoices", false);
        ServiceContractHeader.Validate("Contract Lines on Invoice", false);
        ServiceContractHeader.Modify(true);
    end;

    local procedure VerifyContractInvoicingExpectedInvAmount(ServiceContractHeader: Record "Service Contract Header"; ServiceContractLine: Record "Service Contract Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ContractInvPeriod', Format(ServiceContractHeader."Next Invoice Period Start") + '..' + Format(ServiceContractHeader."Next Invoice Period End"));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ServLedgEntryAmt', ServiceContractLine."Line Value");
    end;

    local procedure PostServiceInvoice(var ServiceHeader: Record "Service Header"): Code[20]
    begin
        // "Invoice" parameter must be false when posting a service invoice via PostServiceOrder, otherwise posting fails
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);
        exit(ServiceHeader."Last Posting No.");
    end;

    local procedure CreateServiceLineWithItemWithVATPostingSetup(ServiceHeader: Record "Service Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateVATClauseTranslation(var VATClauseTranslation: Record "VAT Clause Translation"; VATClauseCode: Code[20]; LanguageCode: Code[10])
    begin
        VATClauseTranslation.Validate("VAT Clause Code", VATClauseCode);
        VATClauseTranslation.Validate("Language Code", LanguageCode);
        VATClauseTranslation.Validate(Description, LibraryUtility.GenerateGUID());
        VATClauseTranslation.Validate("Description 2", LibraryUtility.GenerateGUID());
        VATClauseTranslation.Insert(true);
    end;

    local procedure VerifyVATClauseTranslationDescription(var VATClauseTranslation: Record "VAT Clause Translation")
    var
        RowNo: Integer;
        ColumnNo: Integer;
        CheckValueExist: Boolean;
    begin
        CheckValueExist := LibraryReportValidation.CheckIfValueExists(VATClauseTranslation.Description + ' ' + VATClauseTranslation."Description 2");
        if CheckValueExist then begin
            ColumnNo := LibraryReportValidation.FindFirstColumnNoByValue(CopyStr(VATClauseTranslation.Description + ' ' + VATClauseTranslation."Description 2", 1, 250));
            RowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(ColumnNo, CopyStr(VATClauseTranslation.Description + ' ' + VATClauseTranslation."Description 2", 1, 250));
            Assert.AreNotEqual(0, LibraryReportValidation.FindRowNoFromColumnNoAndValueInsideArea(ColumnNo, CopyStr(VATClauseTranslation.Description + ' '
                + VATClauseTranslation."Description 2", 1, 250), StrSubstNo('=%1', RowNo)), '');
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceDateConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = ErrorInvoiceToDate);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostingDateConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not (Question = ErrorInPostingDate);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ServiceContractConfirmHandler(SignContractMessage: Text[1024]; var Result: Boolean)
    var
        CreateServiceInvoiceWithinPeriod: Boolean;
    begin
        CreateServiceInvoiceWithinPeriod := LibraryVariableStorage.DequeueBoolean();
        case true of
            SignContractMessage = Format(LibraryVariableStorage.DequeueText()):
                Result := true;
            SignContractMessage = Format(NextPlannedServiceDateConfirmQst):
                Result := true;
            CreateServiceInvoiceWithinPeriod = true:
                Result := true;
            else
                Result := false;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContractTemplateListHandler(var ServiceContractTemplateList: Page "Service Contract Template List"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectServiceContractTemplateListHandler(var ServiceContractTemplateList: TestPage "Service Contract Template List")
    begin
        UpdateTemplateNoOnServiceContract(ServiceContractTemplateList, LibraryVariableStorage.DequeueText());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceProfitRespCentersHandler(var ServiceProfitRespCenters: TestRequestPage "Service Profit (Resp. Centers)")
    begin
        ServiceProfitRespCenters.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceRequestPageHandler(var ServiceInvoice: TestRequestPage "Service - Invoice")
    begin
        ServiceInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceToExcelRequestPageHandler(var ServiceInvoice: TestRequestPage "Service - Invoice")
    begin
        ServiceInvoice.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceProfitContractsHandler(var ServiceProfitContracts: TestRequestPage "Service Profit (Contracts)")
    begin
        ServiceProfitContracts.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName())
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractCustomerReportHandler(var ServiceContractCustomer: TestRequestPage "Service Contract - Customer")
    begin
        ServiceContractCustomer.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemWorksheetReportHandler(var ServiceItemWorksheet: TestRequestPage "Service Item Worksheet")
    begin
        ServiceItemWorksheet.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MaintenanceVisitPlanningReportHandler(var MaintenanceVisitPlanning: TestRequestPage "Maintenance Visit - Planning")
    begin
        MaintenanceVisitPlanning.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemsOutOfWarrantyReportHandler(var ServiceItemsOutofWarranty: TestRequestPage "Service Items Out of Warranty")
    begin
        ServiceItemsOutofWarranty.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemResourceUsageReportHandler(var ServiceItemResourceUsage: TestRequestPage "Service Item - Resource Usage")
    begin
        ServiceItemResourceUsage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteReportReportHandler(var ServiceQuote: TestRequestPage "Service Quote")
    begin
        ServiceQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceLoadLevelReportHandler(var ServiceLoadLevel: TestRequestPage "Service Load Level")
    begin
        ServiceLoadLevel.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestReportHandler(var ServiceDocumentTest: TestRequestPage "Service Document - Test")
    begin
        ServiceDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceItemsReportHandler(var ServiceItems: TestRequestPage "Service Items")
    begin
        ServiceItems.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DispatchBoardReportHandler(var DispatchBoard: TestRequestPage "Dispatch Board")
    begin
        DispatchBoard.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractReportHandler(var ServiceContract: TestRequestPage "Service Contract")
    begin
        ServiceContract.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContractServiceOrdersTestReportHandler(var ContrServOrdersTest: TestRequestPage "Contr. Serv. Orders - Test")
    begin
        ContrServOrdersTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContractGainLossEntriesReportHandler(var ContractGainLossEntries: TestRequestPage "Contract Gain/Loss Entries")
    begin
        ContractGainLossEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MaintenancePerformanceRequestPageHandler(var MaintenancePerformance: TestRequestPage "Maintenance Performance")
    begin
        MaintenancePerformance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MaintenancePerformanceToExcelRequestPageHandler(var MaintenancePerformance: TestRequestPage "Maintenance Performance")
    begin
        MaintenancePerformance.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractDetailReportHandler(var ServiceContractDetail: TestRequestPage "Service Contract-Detail")
    begin
        ServiceContractDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExpiredContractLineslReportHandler(var ExpiredContractLinesTest: TestRequestPage "Expired Contract Lines - Test")
    begin
        ExpiredContractLinesTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContractPriceUpdateTestReportHandler(var ContractPriceUpdateTest: TestRequestPage "Contract Price Update - Test")
    begin
        ContractPriceUpdateTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PrepaidContractEntriesTestReportHandler(var PrepaidContrEntriesTest: TestRequestPage "Prepaid Contr. Entries - Test")
    begin
        PrepaidContrEntriesTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteRequestPageHandler(var ServiceContractQuote: TestRequestPage "Service Contract Quote")
    begin
        ServiceContractQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteToExcelRequestPageHandler(var ServiceContractQuote: TestRequestPage "Service Contract Quote")
    begin
        ServiceContractQuote.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractQuoteDetailReportHandler(var ServiceContractQuoteDetail: TestRequestPage "Service Contract Quote-Detail")
    begin
        ServiceContractQuoteDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceTasksReportHandler(var ServiceTasks: TestRequestPage "Service Tasks")
    begin
        ServiceTasks.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractSalespersonReportHandler(var ServContractSalesperson: TestRequestPage "Serv. Contract - Salesperson")
    begin
        ServContractSalesperson.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContractGainLossResponsibilityReportHandler(var ContrGainLossRespCtr: TestRequestPage "Contr. Gain/Loss - Resp. Ctr.")
    begin
        ContrGainLossRespCtr.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContractInvoicingReportHandler(var ContractInvoicing: TestRequestPage "Contract Invoicing")
    begin
        ContractInvoicing.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceContractWithForecastReportHandler(var ContractQuotestoBeSigned: TestRequestPage "Contract Quotes to Be Signed")
    begin
        ContractQuotestoBeSigned.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateAndPrintServiceOrderReportHandler(var ServiceOrder: TestRequestPage "Service Order")
    begin
        ServiceOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
