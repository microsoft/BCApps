codeunit 134053 "ERM VAT Tool - Serv. Doc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Rate Change] [Service]
        isInitialized := false;
    end;

    var
        VATRateChangeSetup2: Record "VAT Rate Change Setup";
        ServiceHeader2: Record "Service Header";
        Assert: Codeunit Assert;
        ERMVATToolHelper: Codeunit "ERM VAT Tool - Helper";
        LibrarySales: Codeunit "Library - Sales";
        LibraryResource: Codeunit "Library - Resource";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryService: Codeunit "Library - Service";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceDocConvFalse()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] Run VAT Rate Change with Perform Conversion = FALSE for Service Order, expect no updates.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create data with groups to update.
        CreateServiceOrder(ServiceHeader, 1);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::Both, false, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify that no data was updated
        ERMVATToolHelper.VerifyUpdateConvFalse(DATABASE::"Service Line");

        // Verify log entries
        ERMVATToolHelper.VerifyLogEntriesConvFalse(DATABASE::"Service Line", false);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceDocPShConvFalse()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO] Run VAT Rate Change with Perform Conversion = FALSE for Posted Service Order, expect no updates.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create data with groups to update.
        CreateServiceOrder(ServiceHeader, 1);
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::Both, false, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify that no data was updated
        ERMVATToolHelper.VerifyUpdateConvFalse(DATABASE::"Service Line");

        // Verify log entries
        ERMVATToolHelper.VerifyLogEntriesConvFalse(DATABASE::"Service Line", true);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceOrderVAT()
    begin
        // [SCENARIO] Service Order with one line, update VAT group only.
        VATToolServiceLine(VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group",
          ServiceHeader2."Document Type"::Order, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceOrderVATAmount()
    begin
        // [SCENARIO] Service Order with Multiple Lines, Update VAT Group, Verify Amount.
        VATToolServiceLineAmount(ServiceHeader2."Document Type"::Order, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceOrderGen()
    begin
        // [SCENARIO] Service Order with one line, update Gen group only.
        VATToolServiceLine(VATRateChangeSetup2."Update Service Docs."::"Gen. Prod. Posting Group",
          ServiceHeader2."Document Type"::Order, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceOrderBoth()
    begin
        // [SCENARIO] Service Order with one line, update both groups.
        VATToolServiceLine(VATRateChangeSetup2."Update Service Docs."::Both,
          ServiceHeader2."Document Type"::Order, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceOrderNo()
    begin
        // [SCENARIO] Service Order with one line, don't update groups.
        asserterror VATToolServiceLine(VATRateChangeSetup2."Update Service Docs."::No, ServiceHeader2."Document Type"::Order, false, false);
        Assert.ExpectedError(ERMVATToolHelper.GetConversionErrorNoTables());

        // Cleanup: Delete Groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServOrderMultipleLines()
    begin
        // [SCENARIO] Service Order with multiple lines, update both groups.
        VATToolServiceLine(VATRateChangeSetup2."Update Service Docs."::Both,
          ServiceHeader2."Document Type"::Order, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServOrderMultipleLinesUpdateFirst()
    begin
        // [SCENARIO] Service Order with multiple lines, update first line only.
        VATToolServOrderMultipleLinesUpdateSplit(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServOrderMultipleLinesUpdateSecond()
    begin
        // [SCENARIO] Service Order with multiple lines, update second line only.
        VATToolServOrderMultipleLinesUpdateSplit(false);
    end;

    local procedure VATToolServOrderMultipleLinesUpdateSplit(First: Boolean)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
        LineCount: Integer;
    begin
        // Service Order with multiple lines, update one line only.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Update VAT Change Tool Setup table and get New VAT group Code
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group", true, false);
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, DATABASE::"Service Line");

        // SETUP: Create a Sales Order with 2 lines and Save data to update in a temporary table.
        CreateServiceOrder(ServiceHeader, 2);

        // SETUP: Change VAT Prod. Posting Group to new on one of the lines.
        GetServiceLine(ServiceHeader, ServiceLine);
        LineCount := ServiceLine.Count();
        if First then
            ServiceLine.Next()
        else
            ServiceLine.FindFirst();
        ServiceLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ServiceLine.Modify(true);

        // SETUP: Ship (Partially).
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        GetServiceLine(ServiceHeader, ServiceLine);
        Assert.AreEqual(LineCount + 1, ServiceLine.Count, ERMVATToolHelper.GetConversionErrorSplitLines());

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServOrderPartShipVAT()
    begin
        // [SCENARIO] Service Order with one partially shipped line, update VAT group only.
        VATToolServiceLnPartSh(VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServOrderPartShpVATAmt()
    begin
        // [SCENARIO] Service Order with one partially shipped and released line, update VAT group and ignore header status. Verify Amount.
        VATToolServiceLineAmount(ServiceHeader2."Document Type"::Order, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollServOrderPartShipGen()
    begin
        // [SCENARIO] Service Order with one partially shipped line, update Gen group only.
        VATToolServiceLnPartSh(VATRateChangeSetup2."Update Service Docs."::"Gen. Prod. Posting Group", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollServOrderPartShipBoth()
    begin
        // [SCENARIO] Service Order with one partially shipped line, update both groups.
        VATToolServiceLnPartSh(VATRateChangeSetup2."Update Service Docs."::Both, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollServOrderPartShipAndConsume()
    begin
        // [SCENARIO] Service Order with one partially shipped and consumed line, update both groups.
        VATToolServiceLnPartShInvoiceConsume(VATRateChangeSetup2."Update Service Docs."::Both, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollServOrderPartShipAndInvoice()
    begin
        // [SCENARIO] Service Order with one partially shipped and invoiced line, update both groups.
        VATToolServiceLnPartShInvoiceConsume(VATRateChangeSetup2."Update Service Docs."::Both, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiOrderPartShpInvoiceAndConsume()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO] Service Order with one partially shipped and consumed and invoiced line, update both groups.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create a Service Order.
        CreateServiceOrder(ServiceHeader, 1);

        // SETUP: Ship (Partially) and Consume.
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        ERMVATToolHelper.UpdateQtyToConsumeInvoice(ServiceHeader, true, false);
        LibraryService.PostServiceOrder(ServiceHeader, true, true, false);

        // SETUP: Ship (Partially) and Invoice.
        ServiceHeader.Find();
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        ERMVATToolHelper.UpdateQtyToConsumeInvoice(ServiceHeader, false, true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group", true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check that line was split.
        GetServiceLine(ServiceHeader, ServiceLine);
        Assert.AreEqual(2, ServiceLine.Count, ERMVATToolHelper.GetConversionErrorSplitLines());

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollServOrderPartShipBothMultipleLines()
    begin
        // [SCENARIO] Service Order with multiple partially shipped lines, update both groups.
        VATToolServiceLnPartSh(VATRateChangeSetup2."Update Service Docs."::Both, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToollServOrPShAutoInsSetup()
    begin
        // [SCENARIO] Service Order with one partially shipped line, update both groups. Auto insert default VAT Prod. Posting Group.
        VATToolServiceLnPartSh(VATRateChangeSetup2."Update Service Docs."::Both, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServOrderFullyShip()
    begin
        // [SCENARIO] Service Order with one fully received line, update both groups. No update expected.
        VATToolServiceLine(VATRateChangeSetup2."Update Service Docs."::Both,
          ServiceHeader2."Document Type"::Order, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceCreditMemo()
    begin
        // [SCENARIO] Service Credit Memo with one line, update both groups. Do not expect update.
        VATToolServiceLine(VATRateChangeSetup2."Update Service Docs."::Both,
          ServiceHeader2."Document Type"::"Credit Memo", false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceInvoice()
    begin
        // [SCENARIO] Service Invoice with one line, update both groups. Expect update.
        VATToolServiceLine(VATRateChangeSetup2."Update Service Docs."::Both, ServiceHeader2."Document Type"::Invoice, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceInvoiceVAT()
    begin
        // [SCENARIO] Service Invoice with Multiple Lines, update VAT group only.
        VATToolServiceLine(
          VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group", ServiceHeader2."Document Type"::Invoice, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceInvoiceVATAmount()
    begin
        // [SCENARIO] Service Invoice with Multiple Lines, Update VAT Group, Verify Amount.
        VATToolServiceLineAmount(ServiceHeader2."Document Type"::Invoice, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServInvoiceForShipment()
    var
        TempRecRef: RecordRef;
    begin
        // [SCENARIO] Service Invoice with one line, related to a Shipment Line, update both groups. No update expected.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        PrepareServInvoiceForShipment(TempRecRef);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::Both, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        ERMVATToolHelper.VerifyUpdate(TempRecRef, false);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, false);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceOrderReserve()
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        PrepareServDocWithReservation(1);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::Both, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifyServDocWithReservation(false);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure VATToolServOrderItemTracking()
    begin
        // [SCENARIO] Service Order with one line with Item Tracking with Serial No., update both groups.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        PrepareServDocItemTracking();

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::Both, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifyServDocWithReservation(true);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiLnDimensions()
    var
        ServiceHeader: Record "Service Header";
        TempRecRef: RecordRef;
    begin
        // [SCENARIO] Service Order with one partially shipped line with Dimensions assigned, update both groups.
        // Verify that dimensions are copied to the new line.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and save data to update in a temporary table.
        CreateServiceOrderWithRef(ServiceHeader, TempRecRef, 1);

        // SETUP: Add Dimensions to the Service Lines and save them in a temporary table
        AddDimensionsForServiceLines(ServiceHeader);

        // SETUP: Ship (Partially).
        PostPartialShipmentService(ServiceHeader, TempRecRef);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::Both, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifyServiceLnPartShipped(TempRecRef);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceOrderNoSpaceForNewLine()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        LineCount: Integer;
    begin
        // [SCENARIO] Service Order with two lines, first partially shipped, no line number available between them. Update both groups.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        CreateServiceOrder(ServiceHeader, 1);
        AddLineWithNextLineNo(ServiceHeader);
        GetServiceLine(ServiceHeader, ServiceLine);
        LineCount := ServiceLine.Count();

        // SETUP: Ship
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::Both, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check that each line was split.
        GetServiceLine(ServiceHeader, ServiceLine);
        Assert.AreEqual(LineCount * 2, ServiceLine.Count, ERMVATToolHelper.GetConversionErrorSplitLines());

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceLineWithZeroOutstandingQty()
    var
        ServiceHeader: Record "Service Header";
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        VatProdPostingGroup: Code[20];
    begin
        // [SCENARIO] Check Description field value when out standing quantity is zero on service order.

        // Setup: Create posting groups to update and save them in VAT Change Tool Conversion table.
        Initialize();
        ERMVATToolHelper.UpdateVatRateChangeSetup(VATRateChangeSetup);
        SetupToolService(VATRateChangeSetup."Update Service Docs."::"VAT Prod. Posting Group", true, false);
        CreateServiceOrder(ServiceHeader, LibraryRandom.RandInt(5));
        VatProdPostingGroup := GetVatProdPostingGroupFromServiceLine(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Verify Description field on vat rate change log entry.
        ERMVATToolHelper.VerifyValueOnZeroOutstandingQty(VatProdPostingGroup, DATABASE::"Service Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSetupPageSetIgnoreStatusOnServiceDocs()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 255529] When Stan sets an "Ignore Status on Service Docs." checkbox of "VAT Rate Change Setup" page, field "Ignore Status on Service Docs." of "VAT Rate Change Setup" table is set to TRUE.
        Initialize();

        // [GIVEN] "Ignore Status on Service Docs." has its initial state FALSE.
        SetFieldStateIgnoreStatusOnServiceDocs(false);

        // [WHEN] Stan sets an "Ignore Status on Service Docs." flag on "VAT Rate Change Setup" page.
        SetCheckboxStateOnPageIgnoreStatusOnServiceDocs(true);

        // [THEN] Field "Ignore Status on Service Docs." of "VAT Rate Change Setup" table is set to TRUE.
        VATRateChangeSetup.Get();
        VATRateChangeSetup.TestField("Ignore Status on Service Docs.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSetupPageClearIgnoreStatusOnServiceDocs()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 255529] When Stan clears an "Ignore Status on Service Docs." checkbox of "VAT Rate Change Setup" page, field "Ignore Status on Service Docs." of "VAT Rate Change Setup" table is set to FALSE.
        Initialize();

        // [GIVEN] "Ignore Status on Service Docs." has its initial state TRUE.
        SetFieldStateIgnoreStatusOnServiceDocs(true);

        // [WHEN] Stan clears an "Ignore Status on Service Docs." flag on "VAT Rate Change Setup" page.
        SetCheckboxStateOnPageIgnoreStatusOnServiceDocs(false);

        // [THEN] Field "Ignore Status on Service Docs." of "VAT Rate Change Setup" table is set to FALSE.
        VATRateChangeSetup.Get();
        VATRateChangeSetup.TestField("Ignore Status on Service Docs.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceOrderReleasedToShipIgnoreStatusOnServiceDocsSet()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 255529] Conversion for Sales Order with release status "Released To Ship" is allowed, if "Ignore Status on Service Docs." checkbox is set.
        Initialize();

        // [GIVEN] "VAT Change Tool Conversion" table is set up.
        ERMVATToolHelper.CreatePostingGroups(false);

        // [GIVEN] Service Order with release status "Released To Ship".
        CreateServiceOrder(ServiceHeader, 1);
        ServiceHeader.Find();
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [GIVEN] Table "VAT Rate Change Setup" is set up for Service Documents conversion, "Ignore Status on Service Docs." is set.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group", false, true);

        // [WHEN] Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // [THEN] Conversion process successfully completed.
        ERMVATToolHelper.VerifyLogEntriesConvFalse(DATABASE::"Service Line", false);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolServiceOrderReleasedToShipIgnoreStatusOnServiceDocsCleared()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [SCENARIO 255529] Conversion for Sales Order with release status "Released To Ship" is not allowed, if "Ignore Status on Service Docs." checkbox is cleared.
        Initialize();

        // [GIVEN] "VAT Change Tool Conversion" table is set up.
        ERMVATToolHelper.CreatePostingGroups(false);

        // [GIVEN] Service Order with release status "Released To Ship".
        CreateServiceOrder(ServiceHeader, 1);
        ServiceHeader.Find();
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [GIVEN] Table "VAT Rate Change Setup" is set up for Service Documents conversion, "Ignore Status on Service Docs." is cleared.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group", false, false);

        // [WHEN] Run VAT Rate Change Tool.
        asserterror ERMVATToolHelper.RunVATRateChangeTool();

        // [THEN] Error "Release Status must be equal to Open" occured.
        Assert.ExpectedTestFieldError(ServiceHeader.FieldCaption("Release Status"), Format(ServiceHeader."Release Status"::Open));

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateServiceLinesByFieldNo()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceHeader."Document Type"::Invoice,
          LibraryResource.CreateResourceNo());

        ServiceHeader.Validate("Order Date", Today);

        ServiceLine.Find();
        ServiceLine.TestField("Order Date", ServiceHeader."Order Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceUpdateForGLAccLineWhenPricesIncludingVATEnabled()
    var
        ServiceLine: Record "Service Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]
        // [SCENARIO 361066] A unit price of service line with "Prices Including VAT" and type "G/L Account" updates on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is enabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(true, false, false);
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group", true, true);
        CreateServiceInvoiceWithPricesIncludingVAT(ServiceLine, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := CalcChangedUnitPriceGivenDiffVATPostingSetup(ServiceLine);
        ServiceLine.Find();
        ServiceLine.TestField("Unit Price", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceDoesNotUpdateForGLAccLineWhenPricesIncludingVATEnabled()
    var
        ServiceLine: Record "Service Line";
        ExpectedUnitPrice: Decimal;
    begin
        // [FEATURE] [Prices Including VAT]
        // [SCENARIO 361066] A unit price of service line with "Prices Including VAT" and type "G/L Account" does not update on "VAT Product Posting Group" change
        // [SCENARIO 361066] if "Update Unit Price For G/L Acc." is disabled in VAT Rate Change Setup

        Initialize();

        ERMVATToolHelper.CreatePostingGroups(false);
        ERMVATToolHelper.UpdateUnitPricesInclVATSetup(false, false, false);
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group", true, true);
        CreateServiceInvoiceWithPricesIncludingVAT(ServiceLine, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());

        ERMVATToolHelper.RunVATRateChangeTool();

        ExpectedUnitPrice := ServiceLine."Unit Price";
        ServiceLine.Find();
        ServiceLine.TestField("Unit Price", ExpectedUnitPrice);

        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConvertPartiallyReceivedOrderWithBlankQtyToReceive()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempRecRef: RecordRef;
    begin
        // [SCENARIO 362310] Stan can convert a VAT group of the Service Order that was partially received and "Default Quantity to Shup" is enabled in the Sales & Receivables setup

        Initialize();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Quantity to Ship", SalesReceivablesSetup."Default Quantity to Ship"::Blank);
        SalesReceivablesSetup.Modify(true);

        ERMVATToolHelper.CreatePostingGroups(false);

        CreateServiceOrderWithRef(ServiceHeader, TempRecRef, 1);
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        ERMVATToolHelper.CreateLinesRefService(TempRecRef, ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group", true, true);
        GetServiceLine(ServiceHeader, ServiceLine);

        ERMVATToolHelper.RunVATRateChangeTool();

        VerifyLineConverted(ServiceHeader, ServiceLine."Quantity Shipped", ServiceLine.Quantity - ServiceLine."Quantity Shipped");
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM VAT Tool - Serv. Doc");

        ERMVATToolHelper.ResetToolSetup();  // This resets the setup table for all test cases.
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM VAT Tool - Serv. Doc");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ERMVATToolHelper.SetupItemNos();
        ERMVATToolHelper.ResetToolSetup();  // This resets setup table for the first test case after database is restored.
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibrarySetupStorage.SaveSalesSetup();
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM VAT Tool - Serv. Doc");
    end;

    local procedure SetupToolService(FieldOption: Option; PerformConversion: Boolean; IgnoreStatus: Boolean)
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        ERMVATToolHelper.SetupToolOption(VATRateChangeSetup.FieldNo("Update Service Docs."), FieldOption);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup.FieldNo("Ignore Status on Service Docs."), IgnoreStatus);
        ERMVATToolHelper.SetupToolCheckbox(VATRateChangeSetup.FieldNo("Perform Conversion"), PerformConversion);
    end;

    local procedure VATToolServiceLine(FieldOption: Option; DocumentType: Enum "Service Document Type"; Ship: Boolean; MultipleLines: Boolean)
    var
        ServiceHeader: Record "Service Header";
        TempRecRef: RecordRef;
        Update: Boolean;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        if DocumentType = ServiceHeader."Document Type"::Order then
            CreateServiceOrderWithRef(ServiceHeader, TempRecRef, GetLineCount(MultipleLines))
        else
            CreateServiceDocumentWithRef(ServiceHeader, TempRecRef, DocumentType, GetLineCount(MultipleLines));

        // SETUP: Ship (Fully).
        if Ship then
            LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(FieldOption, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        Update := ExpectUpdate(DocumentType, Ship);
        ERMVATToolHelper.VerifyUpdate(TempRecRef, Update);

        // Verify: Log Entries
        if Update then
            ERMVATToolHelper.VerifyLogEntries(TempRecRef)
        else
            ERMVATToolHelper.VerifyErrorLogEntries(TempRecRef, ExpectLogEntries(DocumentType));

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolServiceLineAmount(DocumentType: Enum "Service Document Type"; PartialShip: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        // Service Order with one partially shipped and released line, update VAT group and ignore header status. Verify Amount.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        if DocumentType = ServiceHeader."Document Type"::Order then
            CreateServiceOrder(ServiceHeader, 0)
        else
            CreateServiceDocument(ServiceHeader, DocumentType, 0);
        ServiceHeader.Validate("Prices Including VAT", true);
        ServiceHeader.Modify(true);
        if DocumentType = ServiceHeader."Document Type"::Order then
            CreateServiceLine(ServiceHeader, true)
        else
            CreateServiceLine(ServiceHeader, false);

        if PartialShip then begin
            ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
            LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        end;

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(VATRateChangeSetup2."Update Service Docs."::"VAT Prod. Posting Group", true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check VAT%, Unit Price and Line Amount Including VAT.
        VerifyServiceDocAmount(ServiceHeader);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolServiceLnPartSh(FieldOption: Option; AutoInsertDefault: Boolean; MultipleLines: Boolean)
    var
        ServiceHeader: Record "Service Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(AutoInsertDefault);

        // SETUP: Create and Save data to update in a temporary table.
        CreateServiceOrderWithRef(ServiceHeader, TempRecRef, GetLineCount(MultipleLines));

        // SETUP: Ship (Partially).
        PostPartialShipmentService(ServiceHeader, TempRecRef);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(FieldOption, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifyServiceLnPartShipped(TempRecRef);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyDocumentSplitLogEntries(TempRecRef);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure VATToolServiceLnPartShInvoiceConsume(FieldOption: Option; Invoice: Boolean; Consume: Boolean)
    var
        ServiceHeader: Record "Service Header";
        TempRecRef: RecordRef;
    begin
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Create and Save data to update in a temporary table.
        CreateServiceOrderWithRef(ServiceHeader, TempRecRef, 1);

        // SETUP: Ship (Partially) and Invoice/Consume.
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        ERMVATToolHelper.UpdateQtyToConsumeInvoice(ServiceHeader, Consume, Invoice);
        ERMVATToolHelper.CreateLinesRefService(TempRecRef, ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, Consume, Invoice);

        // SETUP: Update VAT Change Tool Setup table.
        SetupToolService(FieldOption, true, false);

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Check if proper data was updated.
        VerifyServiceLnPartShipped(TempRecRef);

        // Verify: Log Entries
        ERMVATToolHelper.VerifyDocumentSplitLogEntries(TempRecRef);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure AddDimensionsForServiceLines(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        GetServiceLine(ServiceHeader, ServiceLine);
        repeat
            DimensionSetID := ServiceLine."Dimension Set ID";
            LibraryDimension.FindDimension(Dimension);
            LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
            DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, DimensionValue."Dimension Code", DimensionValue.Code);
            ServiceLine.Validate("Dimension Set ID", DimensionSetID);
            ServiceLine.Modify(true);
        until ServiceLine.Next() = 0;
    end;

    local procedure AddLineWithNextLineNo(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        ServiceLine3: Record "Service Line";
    begin
        GetServiceLine(ServiceHeader, ServiceLine3);
        ServiceLine3.FindLast();

        ServiceLine.Init();
        ServiceLine.Validate("Document Type", ServiceHeader."Document Type");
        ServiceLine.Validate("Document No.", ServiceHeader."No.");
        ServiceLine.Validate("Line No.", ServiceLine3."Line No." + 1);
        ServiceLine.Insert(true);

        ServiceLine.Validate("Service Item Line No.", ServiceLine3."Service Item Line No.");
        ServiceLine.Validate(Type, ServiceLine3.Type);
        ServiceLine.Validate("No.", ServiceLine3."No.");
        ServiceLine.Validate(Quantity, ServiceLine3.Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure AddReservationLinesForService(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetFilter("Document No.", ServiceHeader."No.");
        if ServiceLine.FindSet() then
            repeat
                LibraryService.AutoReserveServiceLine(ServiceLine);
            until ServiceLine.Next() = 0;
    end;

    local procedure CopyServiceLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ServiceLine3: Record "Service Line"; ServiceItemLineNo: Integer)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ServiceLine3."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, ServiceLine3.Quantity);
        ServiceLine.Validate("VAT Prod. Posting Group", ServiceLine3."VAT Prod. Posting Group");
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; LineCount: Integer)
    var
        I: Integer;
    begin
        // Creates Service Invoices, Credit Memos and Quotes (not Orders)
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, ERMVATToolHelper.CreateCustomer());
        for I := 1 to LineCount do
            CreateServiceLine(ServiceHeader, false);
    end;

    local procedure CreateServiceDocumentWithRef(var ServiceHeader: Record "Service Header"; var TempRecRef: RecordRef; DocumentType: Enum "Service Document Type"; LineCount: Integer)
    begin
        // Creates Service Invoices, Credit Memos and Quotes (not Orders)
        TempRecRef.Open(DATABASE::"Service Line", true);
        CreateServiceDocument(ServiceHeader, DocumentType, LineCount);
        ERMVATToolHelper.CreateLinesRefService(TempRecRef, ServiceHeader);
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; "Order": Boolean)
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        Item: Record Item;
        Qty: Integer;
    begin
        ERMVATToolHelper.CreateItem(Item);
        ERMVATToolHelper.CreateInventorySetup(Item."Inventory Posting Group", '');
        Qty := ERMVATToolHelper.GetQuantity();
        ERMVATToolHelper.PostItemPurchase(Item, '', Qty);

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        if Order then begin
            ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
            ServiceItemLine.SetFilter("Document No.", ServiceHeader."No.");
            ServiceItemLine.FindFirst();
            ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        end;
        ServiceLine.Validate(Quantity, Qty);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; LineCount: Integer)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        I: Integer;
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ERMVATToolHelper.CreateCustomer());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        for I := 1 to LineCount do
            CreateServiceLine(ServiceHeader, true);
    end;

    local procedure CreateServiceOrderWithRef(var ServiceHeader: Record "Service Header"; var TempRecRef: RecordRef; LineCount: Integer)
    begin
        TempRecRef.Open(DATABASE::"Service Line", true);
        CreateServiceOrder(ServiceHeader, LineCount);
        ERMVATToolHelper.CreateLinesRefService(TempRecRef, ServiceHeader);
    end;

    local procedure CreateServiceInvoiceWithPricesIncludingVAT(var ServiceLine: Record "Service Line"; Type: Enum "Service Line Type"; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        ServiceHeader.Validate("Prices Including VAT", true);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup, GenProdPostingGroup);
        ServiceLine.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ServiceLine.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure GetLineCount(MultipleLines: Boolean) "Count": Integer
    begin
        if MultipleLines then
            Count := LibraryRandom.RandInt(2) + 1
        else
            Count := 1;
    end;

    local procedure GetServiceLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
        ServiceHeader.Find();
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure GetServiceShipmentLine(var ServiceShipmentLine: Record "Service Shipment Line"; ServiceHeader: Record "Service Header")
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        ServiceShipmentLine.SetRange(Type, ServiceShipmentLine.Type::Item);
        ServiceShipmentLine.FindFirst();
    end;

    local procedure GetShipmentLineForServInvoice(var ServiceHeader: Record "Service Header"; var ServShipmentLine: Record "Service Shipment Line")
    var
        ServiceGetShpt: Codeunit "Service-Get Shipment";
    begin
        ServiceGetShpt.SetServiceHeader(ServiceHeader);
        ServiceGetShpt.CreateInvLines(ServShipmentLine);
    end;

    local procedure GetVatProdPostingGroupFromServiceLine(var ServiceHeader: Record "Service Header"): Code[20]
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        exit(ServiceLine."VAT Prod. Posting Group");
    end;

    local procedure CalcChangedUnitPriceGivenDiffVATPostingSetup(ServiceLine: Record "Service Line"): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenProdPostingGroup: Code[20];
        VATProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, DATABASE::"Service Line");
        VATPostingSetup.Get(ServiceLine."VAT Bus. Posting Group", VATProdPostingGroup);
        exit(
          Round(
            ServiceLine."Unit Price" * (100 + VATPostingSetup."VAT %") / (100 + ServiceLine."VAT %"),
            LibraryERM.GetUnitAmountRoundingPrecision()));
    end;

    local procedure ExpectLogEntries(DocumentType: Enum "Service Document Type"): Boolean
    var
        Update: Boolean;
    begin
        Update := true;

        if DocumentType = ServiceHeader2."Document Type"::"Credit Memo" then
            Update := false;

        exit(Update);
    end;

    local procedure ExpectUpdate(DocumentType: Enum "Service Document Type"; Ship: Boolean): Boolean
    var
        Update: Boolean;
    begin
        Update := true;

        if Ship then
            Update := false;

        if DocumentType = ServiceHeader2."Document Type"::"Credit Memo" then
            Update := false;

        exit(Update);
    end;

    local procedure SetTempTableService(TempRecRef: RecordRef; var TempServiceLn: Record "Service Line" temporary)
    begin
        // SETTABLE call required for each record of the temporary table.
        TempRecRef.Reset();
        if TempRecRef.FindSet() then begin
            TempServiceLn.SetView(TempRecRef.GetView());
            repeat
                TempRecRef.SetTable(TempServiceLn);
                TempServiceLn.Insert(false);
            until TempRecRef.Next() = 0;
        end;
    end;

    local procedure SetCheckboxStateOnPageIgnoreStatusOnServiceDocs(State: Boolean)
    var
        VATRateChangeSetup: TestPage "VAT Rate Change Setup";
    begin
        VATRateChangeSetup.OpenEdit();
        VATRateChangeSetup."Ignore Status on Service Docs.".SetValue(State);
        VATRateChangeSetup.Close();
    end;

    local procedure SetFieldStateIgnoreStatusOnServiceDocs(State: Boolean)
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        VATRateChangeSetup.Get();
        VATRateChangeSetup."Ignore Status on Service Docs." := State;
        VATRateChangeSetup.Modify();
    end;

    local procedure PrepareServInvoiceForShipment(var TempRecRef: RecordRef)
    var
        ServiceHeader: Record "Service Header";
        ServiceHeader2: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        RecRef: RecordRef;
    begin
        CreateServiceOrder(ServiceHeader, 1);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
        GetServiceShipmentLine(ServiceShipmentLine, ServiceHeader);

        LibraryService.CreateServiceHeader(ServiceHeader2, ServiceHeader."Document Type"::Invoice, ServiceHeader."Bill-to Customer No.");
        GetShipmentLineForServInvoice(ServiceHeader2, ServiceShipmentLine);

        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetFilter("Document No.", ServiceHeader."No.");
        ServiceLine.DeleteAll();

        ServiceLine.SetRange("Document Type", ServiceHeader2."Document Type");
        ServiceLine.SetFilter("Document No.", ServiceHeader2."No.");
        // Do not include empty lines containing only Description.
        ServiceLine.SetFilter("Bill-to Customer No.", ServiceHeader2."Bill-to Customer No.");
        ServiceLine.FindFirst();

        TempRecRef.Open(DATABASE::"Service Line", true);
        RecRef.GetTable(ServiceLine);
        ERMVATToolHelper.CopyRecordRef(RecRef, TempRecRef);
    end;

    local procedure PrepareServDocItemTracking()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        Qty: Integer;
    begin
        // Create Item with tracking and purchase it
        ERMVATToolHelper.CreateItemWithTracking(Item, true);
        Qty := ERMVATToolHelper.GetQuantity();
        ERMVATToolHelper.PostItemPurchase(Item, '', Qty);

        // Create Service Order with Item with tracking
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ERMVATToolHelper.CreateCustomer());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, Qty);
        ServiceLine.Modify(true);

        // Assign Serial Nos
        ServiceLine.OpenItemTrackingLines();

        // Partially Ship Order
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        ERMVATToolHelper.UpdateQtyToHandleService(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    local procedure PrepareServDocWithReservation(LineCount: Integer)
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceOrder(ServiceHeader, LineCount);
        AddReservationLinesForService(ServiceHeader);
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    local procedure PostPartialShipmentService(var ServiceHeader: Record "Service Header"; var TempRecRef: RecordRef)
    begin
        ERMVATToolHelper.UpdateQtyToShipService(ServiceHeader);
        ERMVATToolHelper.CreateLinesRefService(TempRecRef, ServiceHeader);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    local procedure VerifyServiceDocAmount(ServiceHeader: Record "Service Header")
    var
        ServiceHeader3: Record "Service Header";
        ServiceItemLine3: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceLine3: Record "Service Line";
    begin
        GetServiceLine(ServiceHeader, ServiceLine);
        LibraryService.CreateServiceHeader(ServiceHeader3, ServiceHeader3."Document Type"::Order, ServiceHeader."Bill-to Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine3, ServiceHeader3, ServiceLine."Service Item No.");
        ServiceHeader3.Validate("Prices Including VAT", true);
        ServiceHeader3.Modify(true);
        repeat
            CopyServiceLine(ServiceHeader3, ServiceLine3, ServiceLine, ServiceItemLine3."Line No.");
            VerifyServiceLineAmount(ServiceLine, ServiceLine3);
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLineAmount(ServiceLine: Record "Service Line"; ServiceLine3: Record "Service Line")
    begin
        ServiceLine.TestField("VAT %", ServiceLine3."VAT %");
        ServiceLine.TestField("Unit Price", ServiceLine3."Unit Price");
        ServiceLine.TestField("Line Amount", ServiceLine3."Line Amount");
    end;

    local procedure VerifyServDocWithReservation(Tracking: Boolean)
    var
        ServiceLine: Record "Service Line";
        ReservationEntry: Record "Reservation Entry";
        VATProdPostingGroup: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroup, GenProdPostingGroup, DATABASE::"Service Line");

        ServiceLine.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        ServiceLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        ServiceLine.FindSet();

        repeat
            ERMVATToolHelper.GetReservationEntryService(ReservationEntry, ServiceLine);
            if Tracking then
                Assert.AreEqual(ServiceLine.Quantity, ReservationEntry.Count, ERMVATToolHelper.GetConversionErrorUpdate())
            else
                Assert.AreEqual(1, ReservationEntry.Count, ERMVATToolHelper.GetConversionErrorUpdate());

        until ServiceLine.Next() = 0;

        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroup,
          GenProdPostingGroup);

        ServiceLine.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        ServiceLine.SetRange("Gen. Prod. Posting Group", GenProdPostingGroup);
        ServiceLine.FindSet();

        repeat
            ERMVATToolHelper.GetReservationEntryService(ReservationEntry, ServiceLine);
            Assert.AreEqual(0, ReservationEntry.Count, ERMVATToolHelper.GetConversionErrorUpdate());
        until ServiceLine.Next() = 0;
    end;

    local procedure VerifyServiceLnPartShipped(TempRecRef: RecordRef)
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
        TempServiceLn: Record "Service Line" temporary;
        ServiceLn: Record "Service Line";
        VATProdPostingGroupOld: Code[20];
        GenProdPostingGroupOld: Code[20];
        VATProdPostingGroupNew: Code[20];
        GenProdPostingGroupNew: Code[20];
    begin
        VATRateChangeSetup.Get();
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroupOld, GenProdPostingGroupOld);
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroupNew, GenProdPostingGroupNew, TempRecRef.Number);

        ServiceLn.Reset();
        ServiceLn.SetFilter("VAT Prod. Posting Group", StrSubstNo('%1|%2', VATProdPostingGroupOld, VATProdPostingGroupNew));
        ServiceLn.SetFilter("Gen. Prod. Posting Group", StrSubstNo('%1|%2', GenProdPostingGroupOld, GenProdPostingGroupNew));
        ServiceLn.FindSet();

        // Compare Number of lines.
        Assert.AreEqual(TempRecRef.Count, ServiceLn.Count, StrSubstNo(ERMVATToolHelper.GetConversionErrorCount(), ServiceLn.GetFilters));

        TempRecRef.Reset();
        SetTempTableService(TempRecRef, TempServiceLn);
        TempServiceLn.FindSet();

        repeat
            if TempServiceLn."Description 2" = Format(TempServiceLn."Line No.") then
                VerifySplitNewLineService(TempServiceLn, ServiceLn, VATProdPostingGroupNew, GenProdPostingGroupNew)
            else
                VerifySplitOldLineService(TempServiceLn, ServiceLn);
            ServiceLn.Next();
        until TempServiceLn.Next() = 0;
    end;

    local procedure VerifySplitOldLineService(var ServiceLn1: Record "Service Line"; ServiceLn2: Record "Service Line")
    begin
        // Splitted Line should have Quantity = Quantity to Ship/Receive of the Original Line and old Product Posting Groups.
        ServiceLn2.TestField("Line No.", ServiceLn1."Line No.");
        ServiceLn2.TestField(Quantity, ServiceLn1."Qty. to Ship");
        ServiceLn2.TestField("Qty. to Ship", 0);
        ServiceLn2.TestField("Quantity Shipped", ServiceLn1."Qty. to Ship");
        ServiceLn2.TestField("VAT Prod. Posting Group", ServiceLn1."VAT Prod. Posting Group");
        ServiceLn2.TestField("Gen. Prod. Posting Group", ServiceLn1."Gen. Prod. Posting Group");
    end;

    local procedure VerifySplitNewLineService(var ServiceLn1: Record "Service Line"; ServiceLn2: Record "Service Line"; VATProdPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
        // Line should have Quantity = Original Quantity - Quantity Shipped/Received,
        // Quantity Shipped/Received = 0 and new Posting Groups.
        ServiceLn2.TestField(Quantity, ServiceLn1.Quantity);
        ServiceLn2.TestField("Qty. to Ship", ServiceLn1."Qty. to Ship");
        ServiceLn2.TestField("Dimension Set ID", ServiceLn1."Dimension Set ID");
        ServiceLn2.TestField("VAT Prod. Posting Group", VATProdPostingGroup);
        ServiceLn2.TestField("Gen. Prod. Posting Group", GenProdPostingGroup);
    end;

    local procedure VerifyLineConverted(ServiceHeader: Record "Service Header"; QtyShipped: Decimal; QtyToBeConverted: Decimal)
    var
        ServiceLine: Record "Service Line";
        VATProdPostingGroupCode: Code[20];
        GenProdPostingGroupCode: Code[20];
    begin
        GetServiceLine(ServiceHeader, ServiceLine);
        ServiceLine.TestField(Quantity, QtyShipped);
        ServiceLine.TestField("Quantity Shipped", QtyShipped);
        ERMVATToolHelper.GetGroupsBefore(VATProdPostingGroupCode, GenProdPostingGroupCode);
        ServiceLine.TestField("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        ServiceLine.TestField("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Assert.AreEqual(1, ServiceLine.Next(), 'No second line has been generated');
        ServiceLine.TestField(Quantity, QtyToBeConverted);
        ServiceLine.TestField("Quantity Shipped", 0);
        ERMVATToolHelper.GetGroupsAfter(VATProdPostingGroupCode, GenProdPostingGroupCode, DATABASE::"Service Line");
        ServiceLine.TestField("Gen. Prod. Posting Group", GenProdPostingGroupCode);
        ServiceLine.TestField("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Assert.AreEqual(0, ServiceLine.Next(), 'The third line has been generated');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;
}

