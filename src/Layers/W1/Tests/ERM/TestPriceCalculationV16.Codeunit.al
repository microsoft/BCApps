codeunit 134159 "Test Price Calculation - V16"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Lowest Price]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;
        AllowLineDiscErr: Label 'Allow Line Disc. must have a value in Sales Line';
        PickedWrongMinQtyErr: Label 'The quantity in the line is below the minimum quantity of the picked price list line.';
        CampaignActivatedMsg: Label 'Campaign %1 is now activated.';
        GetPriceOutOfDateErr: Label 'The selected price line is not valid on the document date %1.',
            Comment = '%1 - a date value';
        GetPriceFieldMismatchErr: Label 'The %1 in the selected price line must be %2.',
            Comment = '%1 - a field caption, %2 - a value of the field';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in %3', Comment = '%1 = Field Caption , %2 = Expected Value , %3 = Table Caption';
        TestFieldErr: Label '%1 must have a value', Comment = '%1 = Field Caption';
        LineDiscPctErr: Label 'Line Discount % must be %1 in %2', Comment = '%1 = Line Discount % value, %2 = Service Line';

    [Test]
    procedure T001_SalesLineAddsActivatedCampaignOnHeaderAsSource()
    var
        Campaign: array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Campaign] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, false);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Invoice for customer 'A', where 'Campaign No.' is 'HdrCmp'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Campaign No.", Campaign[1]."No.");
        SalesHeader.Modify(true);
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains one Campaign 'HdrCmp'
        VerifyCampaignSource(SalesLinePrice, Campaign[1]."No.", 1);
    end;

    [Test]
    procedure T002_SalesLineAddsActivatedCustomerCampaignAsSource()
    var
        Campaign: array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Campaign] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, false);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Invoice for customer 'A', where 'Campaign No.' is <blank>
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains one Campaign 'CustCmp'
        VerifyCampaignSource(SalesLinePrice, Campaign[2]."No.", 2);
        VerifyCampaignSource(SalesLinePrice, Campaign[3]."No.", 2);
    end;

    [Test]
    procedure T003_SalesLineAddsActivatedContactCampaignAsSource()
    var
        Campaign: array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Campaign] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has none activated Campaigns, "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, true);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Invoice for customer 'A', where 'Campaign No.' is <blank>
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains one Campaign 'ContCmp'
        VerifyCampaignSource(SalesLinePrice, Campaign[4]."No.", 2);
        VerifyCampaignSource(SalesLinePrice, Campaign[5]."No.", 2);
    end;

    [Test]
    procedure T010_SalesLinePriceCopyToBufferWithoutPostingDate()
    var
        Item: Record Item;
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Sales]
        Initialize();
        // [GIVEN] Sales Line, where 'Posting Date' is <blank>, while WorkDate is '250120'
        SalesLine."Posting Date" := 0D;
        SalesLine.Type := SalesLine.Type::Item;
        LibraryInventory.CreateItem(Item);
        SalesLine."No." := Item."No.";

        // [GIVEN] Initialize LineWithPrice with SalesLine, no Header set
        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, SalesLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
        // [THEN] "VAT Prod. Posting Group" is copied from Item card
        PriceCalculationBuffer.TestField("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
    end;

    [Test]
    procedure T011_SalesLinePriceCopyToBufferWithoutHeader()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Sales]
        Initialize();
        // [GIVEN] Sales Line, where 'Posting Date' is '300120', while WorkDate is '250120'
        SalesLine."Posting Date" := WorkDate() + 5;
        SalesLine.Type := SalesLine.Type::Resource;
        LibraryResource.CreateResource(Resource, '');
        SalesLine."No." := Resource."No.";

        // [GIVEN] Initialize LineWithPrice with SalesLine, no Header set
        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, SalesLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from Line."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", SalesLine."Posting Date");
        // [THEN] "VAT Prod. Posting Group" is copied from Resource card
        PriceCalculationBuffer.TestField("VAT Prod. Posting Group", Resource."VAT Prod. Posting Group");
    end;

    [Test]
    procedure T012_SalesLinePriceCopyToBufferWithHeaderBlankNo()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Sales]
        Initialize();
        // [GIVEN] Sales Header, where "Document Type" is Invoice, "No." is <blank>, "Posting Date" is '300120', "Order Date" is '290120'
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := '';
        SalesHeader."Posting Date" := WorkDate() + 5;
        SalesHeader."Order Date" := SalesHeader."Posting Date" - 1;

        // [GIVEN] Sales Line, where 'Posting Date' is '310120', while WorkDate is '250120'
        SalesLine."Posting Date" := SalesHeader."Posting Date" + 1;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with SalesLine and Header
        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '310120' (from Line."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", SalesLine."Posting Date");
    end;

    [Test]
    procedure T013_SalesLinePriceCopyToBufferWithHeaderInvoice()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Sales]
        Initialize();
        // [GIVEN] Sales Header, where "Document Type" is Invoice, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := LibraryRandom.RandText(20);
        SalesHeader."Posting Date" := WorkDate() + 5;
        SalesHeader."Order Date" := SalesHeader."Posting Date" - 1;
        SalesHeader.Insert();

        // [GIVEN] Sales Line, where 'Posting Date' is '310120', while WorkDate is '250120'
        SalesLine."Posting Date" := SalesHeader."Posting Date" + 1;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := LibraryERM.CreateGLAccountNo();
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Document Type" := SalesHeader."Document Type";

        // [GIVEN] Initialize LineWithPrice with SalesLine and Header
        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120' (from Header."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", SalesHeader."Posting Date");
    end;

    [Test]
    procedure T014_SalesLinePriceCopyToBufferWithHeaderOrder()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Sales]
        Initialize();
        // [GIVEN] Sales Header, where "Document Type" is Order, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryRandom.RandText(20);
        SalesHeader."Posting Date" := WorkDate() + 5;
        SalesHeader."Order Date" := SalesHeader."Posting Date" - 1;
        SalesHeader.Insert();

        // [GIVEN] Sales Line, where 'Order Date' is '310120', while WorkDate is '250120'
        SalesLine."Posting Date" := SalesHeader."Posting Date" + 1;
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := LibraryERM.CreateGLAccountNo();
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Document Type" := SalesHeader."Document Type";

        // [GIVEN] Initialize LineWithPrice with SalesLine and Header
        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '290120' (from Header."Order Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", SalesHeader."Order Date");
    end;

    [Test]
    procedure T015_ServiceLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Resource: Record Resource;
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Service]
        Initialize();
        // [GIVEN] Service Line, where 'Posting Date' is <blank>, while WorkDate is '250120'
        ServiceLine."Posting Date" := 0D;
        ServiceLine.Type := ServiceLine.Type::Resource;
        LibraryResource.CreateResource(Resource, '');
        ServiceLine."No." := Resource."No.";

        // [GIVEN] Initialize LineWithPrice with ServiceLine, no Header set
        LineWithPrice := ServiceLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ServiceLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
        // [THEN] "VAT Prod. Posting Group" is copied from Resource card
        PriceCalculationBuffer.TestField("VAT Prod. Posting Group", Resource."VAT Prod. Posting Group");
    end;

    [Test]
    procedure T016_ServiceLinePriceCopyToBufferWithoutHeader()
    var
        Item: Record Item;
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Service]
        Initialize();
        // [GIVEN] Service Line, where 'Posting Date' is '300120', while WorkDate is '250120'
        ServiceLine."Posting Date" := WorkDate() + 5;
        ServiceLine.Type := ServiceLine.Type::Item;
        LibraryInventory.CreateItem(Item);
        ServiceLine."No." := Item."No.";

        // [GIVEN] Initialize LineWithPrice with ServiceLine, no Header set
        LineWithPrice := ServiceLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ServiceLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from Line."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ServiceLine."Posting Date");
        // [THEN] "VAT Prod. Posting Group" is copied from Item card
        PriceCalculationBuffer.TestField("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
    end;

    [Test]
    procedure T017_ServiceLinePriceCopyToBufferWithHeaderBlankNo()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Service]
        Initialize();
        // [GIVEN] Service Header, where "Document Type" is Invoice, "No." is <blank>, "Posting Date" is '300120', "Order Date" is '290120'
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceHeader."No." := '';
        ServiceHeader."Posting Date" := WorkDate() + 5;
        ServiceHeader."Order Date" := ServiceHeader."Posting Date" - 1;

        // [GIVEN] Service Line, where 'Posting Date' is '310120', while WorkDate is '250120'
        ServiceLine."Posting Date" := ServiceHeader."Posting Date" + 1;
        ServiceLine.Type := ServiceLine.Type::"G/L Account";
        ServiceLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with ServiceLine and Header
        LineWithPrice := ServiceLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ServiceHeader, ServiceLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '310120' (from Line."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ServiceLine."Posting Date");
    end;

    [Test]
    procedure T018_ServiceLinePriceCopyToBufferWithHeaderInvoice()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Service]
        Initialize();
        // [GIVEN] Service Header, where "Document Type" is Invoice, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Invoice;
        ServiceHeader."No." := LibraryRandom.RandText(20);
        ServiceHeader."Posting Date" := WorkDate() + 5;
        ServiceHeader."Order Date" := ServiceHeader."Posting Date" - 1;

        // [GIVEN] Service Line, where 'Posting Date' is '310120', while WorkDate is '250120'
        ServiceLine."Posting Date" := ServiceHeader."Posting Date" + 1;
        ServiceLine.Type := ServiceLine.Type::"G/L Account";
        ServiceLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with ServiceLine and Header
        LineWithPrice := ServiceLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ServiceHeader, ServiceLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120' (from Header."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ServiceHeader."Posting Date");
    end;

    [Test]
    procedure T019_ServiceLinePriceCopyToBufferWithHeaderOrder()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceLinePrice: Codeunit "Service Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Service]
        Initialize();
        // [GIVEN] Service Header, where "Document Type" is Order, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        ServiceHeader."Document Type" := ServiceHeader."Document Type"::Order;
        ServiceHeader."No." := LibraryRandom.RandText(20);
        ServiceHeader."Posting Date" := WorkDate() + 5;
        ServiceHeader."Order Date" := ServiceHeader."Posting Date" - 1;
        // [GIVEN] Service Line, where 'Order Date' is '310120', while WorkDate is '250120'
        ServiceLine."Posting Date" := ServiceHeader."Posting Date" + 1;
        ServiceLine.Type := ServiceLine.Type::"G/L Account";
        ServiceLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with ServiceLine and Header
        LineWithPrice := ServiceLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ServiceHeader, ServiceLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '290120' (from Header."Order Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ServiceHeader."Order Date");
    end;

    [Test]
    procedure T020_PurchaseLinePriceCopyToBufferWithoutPostingDate()
    var
        Item: Record Item;
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        PurchaseLine: Record "Purchase Line";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Purchase]
        Initialize();
        // [GIVEN] Purchase Line, while WorkDate is '250120'
        PurchaseLine.Type := PurchaseLine.Type::Item;
        LibraryInventory.CreateItem(Item);
        PurchaseLine."No." := Item."No.";

        // [GIVEN] Initialize LineWithPrice with PurchaseLine, no Header set
        LineWithPrice := PurchaseLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, PurchaseLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
        // [THEN] "VAT Prod. Posting Group" is copied from Item card
        PriceCalculationBuffer.TestField("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
    end;

    [Test]
    procedure T021_PurchaseLinePriceCopyToBufferWithHeaderInvoice()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Purchase]
        Initialize();
        // [GIVEN] Purchase Header, where "Document Type" is Invoice, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Invoice;
        PurchaseHeader."No." := LibraryRandom.RandText(20);
        PurchaseHeader."Posting Date" := WorkDate() + 5;
        PurchaseHeader."Order Date" := PurchaseHeader."Posting Date" - 1;
        PurchaseHeader.Insert();

        // [GIVEN] Purchase Line, while WorkDate is '250120'
        PurchaseLine.Type := PurchaseLine.Type::Resource;
        LibraryResource.CreateResource(Resource, '');
        PurchaseLine."No." := Resource."No.";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";

        // [GIVEN] Initialize LineWithPrice with PurchaseLine and Header
        LineWithPrice := PurchaseLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, PurchaseHeader, PurchaseLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120' (from Header."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", PurchaseHeader."Posting Date");
        // [THEN] "VAT Prod. Posting Group" is copied from Resource card
        PriceCalculationBuffer.TestField("VAT Prod. Posting Group", Resource."VAT Prod. Posting Group");
    end;

    [Test]
    procedure T022_PurchaseLinePriceCopyToBufferWithHeaderOrder()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Purchase]
        Initialize();
        // [GIVEN] Purchase Header, where "Document Type" is Order, "No." is 'X', "Posting Date" is '300120', "Order Date" is '290120'
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryRandom.RandText(20);
        PurchaseHeader."Posting Date" := WorkDate() + 5;
        PurchaseHeader."Order Date" := PurchaseHeader."Posting Date" - 1;
        PurchaseHeader.Insert();

        // [GIVEN] Purchase Line, while WorkDate is '250120'
        PurchaseLine.Type := PurchaseLine.Type::"G/L Account";
        PurchaseLine."No." := LibraryERM.CreateGLAccountNo();
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";

        // [GIVEN] Initialize LineWithPrice with PurchaseLine and Header
        LineWithPrice := PurchaseLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, PurchaseHeader, PurchaseLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '290120' (from Header."Order Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", PurchaseHeader."Order Date");
    end;

    [Test]
    procedure T025_ItemJournalLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLinePrice: Codeunit "Item Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Item Journal]
        Initialize();
        // [GIVEN] Item Journal Line, while WorkDate is '250120'
        ItemJournalLine.Type := ItemJournalLine.Type::Resource;
        ItemJournalLine."Item No." := LibraryInventory.CreateItemNo();

        // [GIVEN] Initialize LineWithPrice with ItemJournalLine
        LineWithPrice := ItemJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ItemJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T026_ItemJournalLinePriceCopyToBufferWithPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLinePrice: Codeunit "Item Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Item Journal]
        Initialize();
        // [GIVEN] Item Journal Line, where "Posting Date" is 300120, while WorkDate is '250120'
        ItemJournalLine."Posting Date" := WorkDate() + 5;
        ItemJournalLine."Item No." := LibraryInventory.CreateItemNo();

        // [GIVEN] Initialize LineWithPrice with ItemJournalLine
        LineWithPrice := ItemJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ItemJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from ItemJournalLine."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ItemJournalLine."Posting Date");
    end;

    [Test]
    procedure T027_StandardItemJournalLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        StandardItemJournalLine: Record "Standard Item Journal Line";
        StdItemJnlLinePrice: Codeunit "Std. Item Jnl. Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Standard Item Journal]
        Initialize();
        // [GIVEN] Item Journal Line, while WorkDate is '250120'
        StandardItemJournalLine."Item No." := LibraryInventory.CreateItemNo();

        // [GIVEN] Initialize LineWithPrice with StandardItemJournalLine
        LineWithPrice := StdItemJnlLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, StandardItemJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T028_JobJournalLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Job Journal]
        Initialize();
        // [GIVEN] Job Journal Line, while WorkDate is '250120'
        LibraryJob.CreateJob(Job);
        JobJournalLine."Job No." := Job."No.";
        JobJournalLine.Type := JobJournalLine.Type::"G/L Account";
        JobJournalLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with JobJournalLine
        LineWithPrice := JobJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, JobJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T029_JobJournalLinePriceCopyToBufferWithPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Job Journal]
        Initialize();
        // [GIVEN] Job Journal Line, where "Posting Date" is 300120, while WorkDate is '250120'
        LibraryJob.CreateJob(Job);
        JobJournalLine."Job No." := Job."No.";
        JobJournalLine."Posting Date" := WorkDate() + 5;
        JobJournalLine.Type := JobJournalLine.Type::"G/L Account";
        JobJournalLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with JobJournalLine
        LineWithPrice := JobJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, JobJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from JobJournalLine."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", JobJournalLine."Posting Date");
    end;

    [Test]
    procedure T030_JobPlanningLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLinePrice: Codeunit "Job Planning Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Job Planning]
        Initialize();
        // [GIVEN] Job Planning Line, where "Planning Date" is <blank>, while WorkDate is '250120'
        LibraryJob.CreateJob(Job);
        JobPlanningLine."Job No." := Job."No.";
        JobPlanningLine.Type := JobPlanningLine.Type::"G/L Account";
        JobPlanningLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with JobPlanningLine
        LineWithPrice := JobPlanningLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, JobPlanningLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T031_JobPlanningLinePriceCopyToBufferWithPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLinePrice: Codeunit "Job Planning Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Job Planning]
        Initialize();
        // [GIVEN] Job Planning Line, where "Planning Date" is 300120, while WorkDate is '250120'
        LibraryJob.CreateJob(Job);
        JobPlanningLine."Job No." := Job."No.";
        JobPlanningLine."Planning Date" := WorkDate() + 5;
        JobPlanningLine.Type := JobPlanningLine.Type::"G/L Account";
        JobPlanningLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with JobPlanningLine
        LineWithPrice := JobPlanningLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, JobPlanningLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from JobPlanningLine."Planning Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", JobPlanningLine."Planning Date");
    end;

    [Test]
    procedure T032_RequisitionLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        RequisitionLine: Record "Requisition Line";
        RequisitionLinePrice: Codeunit "Requisition Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Requisition Line]
        Initialize();
        // [GIVEN] Requisition Line, where "Order Date" is <blank>, while WorkDate is '250120'
        RequisitionLine.Type := RequisitionLine.Type::"G/L Account";
        RequisitionLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with RequisitionLine
        LineWithPrice := RequisitionLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, RequisitionLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T033_RequisitionLinePriceCopyToBufferWithPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        RequisitionLine: Record "Requisition Line";
        RequisitionLinePrice: Codeunit "Requisition Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Requisition Line]
        Initialize();
        // [GIVEN] Requisition Line, where "Order Date" is 300120, while WorkDate is '250120'
        RequisitionLine."Order Date" := WorkDate() + 5;
        RequisitionLine.Type := RequisitionLine.Type::"G/L Account";
        RequisitionLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with RequisitionLine
        LineWithPrice := RequisitionLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, RequisitionLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from RequisitionLine."Order Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", RequisitionLine."Order Date");
    end;

    [Test]
    procedure T034_ResJournalLinePriceCopyToBufferWithoutPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ResJournalLine: Record "Res. Journal Line";
        ResJournalLinePrice: Codeunit "Res. Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Resource Journal]
        Initialize();
        // [GIVEN] Res. Journal Line, where "Posting Date" is <blank>, while WorkDate is '250120'
        ResJournalLine."Resource No." := LibraryResource.CreateResourceNo();

        // [GIVEN] Initialize LineWithPrice with ResJournalLine
        LineWithPrice := ResJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ResJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '250120'(from WorkDate)
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", WorkDate());
    end;

    [Test]
    procedure T035_ResJournalLinePriceCopyToBufferWithPostingDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ResJournalLine: Record "Res. Journal Line";
        ResJournalLinePrice: Codeunit "Res. Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Resource Journal]
        Initialize();
        // [GIVEN] Res. Journal Line, where "Posting Date" is 300120, while WorkDate is '250120'
        ResJournalLine."Posting Date" := WorkDate() + 5;
        ResJournalLine."Resource No." := LibraryResource.CreateResourceNo();

        // [GIVEN] Initialize LineWithPrice with ResJournalLine
        LineWithPrice := ResJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ResJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '300120'(from ResJournalLine."Posting Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ResJournalLine."Posting Date");
    end;

    [Test]
    procedure T036_JobJournalLinePriceCopyToBufferWithTimeSheetDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        Job: Record Job;
        JobJournalLine: Record "Job Journal Line";
        JobJournalLinePrice: Codeunit "Job Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Job Journal] [Time Sheet]
        Initialize();
        // [GIVEN] Job Journal Line, where "Posting Date" is 300120, "Time Sheet Date" is 010220,, while WorkDate is '250120'
        LibraryJob.CreateJob(Job);
        JobJournalLine."Job No." := Job."No.";
        JobJournalLine."Posting Date" := WorkDate() + 5;
        JobJournalLine."Time Sheet Date" := WorkDate() + 6;
        JobJournalLine.Type := JobJournalLine.Type::"G/L Account";
        JobJournalLine."No." := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Initialize LineWithPrice with JobJournalLine
        LineWithPrice := JobJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, JobJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '010220'(from JobJournalLine."Time Sheet Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", JobJournalLine."Time Sheet Date");
    end;

    [Test]
    procedure T037_ResJournalLinePriceCopyToBufferWithTimeSheetDate()
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        ResJournalLine: Record "Res. Journal Line";
        ResJournalLinePrice: Codeunit "Res. Journal Line - Price";
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        LineWithPrice: Interface "Line With Price";
    begin
        // [FEATURE] [UT] [Resource Journal] [Time Sheet]
        Initialize();
        // [GIVEN] Res. Journal Line, where "Posting Date" is 300120, "Time Sheet Date" is 010220, while WorkDate is '250120'
        ResJournalLine."Posting Date" := WorkDate() + 5;
        ResJournalLine."Time Sheet Date" := WorkDate() + 6;
        ResJournalLine."Resource No." := LibraryResource.CreateResourceNo();

        // [GIVEN] Initialize LineWithPrice with ResJournalLine
        LineWithPrice := ResJournalLinePrice;
        LineWithPrice.SetLine("Price Type"::Sale, ResJournalLine);

        // [WHEN] CopyToBuffer()
        LineWithPrice.CopyToBuffer(PriceCalculationBufferMgt);

        // [THEN] Buffer, where "Document Date" is '010220'(from ResJournalLine."Time Sheet Date")
        PriceCalculationBufferMgt.GetBuffer(PriceCalculationBuffer);
        PriceCalculationBuffer.TestField("Document Date", ResJournalLine."Time Sheet Date");
    end;

    [Test]
    procedure T040_SalesLineJobAddsJobSources()
    var
        Customer: Record Customer;
        Job: Record Job;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Job] [UT]
        Initialize();
        // [GIVEN] Customer 'A', Job 'J'
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");

        // [GIVEN] Invoice for customer 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', "Job no." 'J'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := LibraryInventory.CreateItemNo();
        SalesLine."Job No." := Job."No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains 'All Jobs', Job 'J'
        VerifyJobSources(Job, SalesLinePrice, 1, 1, 0);
    end;

    [Test]
    procedure T041_SalesLineJobTaskAddsJobTaskSources()
    var
        Customer: Record Customer;
        Job: Record Job;
        JobTask: Record "Job Task";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Job] [UT]
        Initialize();
        // [GIVEN] Customer 'A', Job 'J', Job Task 'JT'
        LibrarySales.CreateCustomer(Customer);
        LibraryJob.CreateJob(Job, Customer."No.");
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Invoice for customer 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', "Job no." 'J', "Job Task No." 'JT'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := LibraryInventory.CreateItemNo();
        SalesLine."Job No." := Job."No.";
        SalesLine."Job Task No." := JobTask."Job Task No.";
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources contains 'All Jobs', Job 'J', Job Task 'JT'
        VerifyJobSources(JobTask, SalesLinePrice, 1, 1, 1);
    end;

    [Test]
    procedure T042_SalesLineNoJobDoesNotAddsJobSources()
    var
        Customer: Record Customer;
        Job: Record Job;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Job] [UT]
        Initialize();
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Invoice for customer 'A'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', "Job no." <blank>
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := LibraryInventory.CreateItemNo();
        SalesLine."Job No." := '';
        SalesLine.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources does not contain 'All Jobs', Job, Job Task
        Clear(Job);
        VerifyJobSources(Job, SalesLinePrice, 0, 0, 0);
    end;

    [Test]
    procedure T045_PurchLineJobAddsJobSources()
    var
        Vendor: Record Vendor;
        Job: Record Job;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
    begin
        // [FEATURE] [Purchase] [Job] [UT]
        Initialize();
        // [GIVEN] Vendor 'A', Job 'J'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryJob.CreateJob(Job);

        // [GIVEN] Invoice for Vendor 'A'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', "Job no." 'J'
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := LibraryInventory.CreateItemNo();
        PurchaseLine."Job No." := Job."No.";
        PurchaseLine.Modify(true);

        // [WHEN] SetLine()
        PurchaseLinePrice.SetLine("Price Type"::Purchase, PurchaseHeader, PurchaseLine);

        // [THEN] List of sources contains 'All Jobs', Job 'J'
        VerifyJobSources(Job, PurchaseLinePrice, 1, 1, 0);
    end;

    [Test]
    procedure T046_PurchLineJobTaskAddsJobTaskSources()
    var
        Vendor: Record Vendor;
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
    begin
        // [FEATURE] [Purchase] [Job] [UT]
        Initialize();
        // [GIVEN] Vendor 'A', Job 'J', Job Task 'JT'
        LibraryPurchase.CreateVendor(Vendor);
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Invoice for Vendor 'A'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', "Job no." 'J', "Job Task No." 'JT'
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := LibraryInventory.CreateItemNo();
        PurchaseLine."Job No." := Job."No.";
        PurchaseLine."Job Task No." := JobTask."Job Task No.";
        PurchaseLine.Modify(true);

        // [WHEN] SetLine()
        PurchaseLinePrice.SetLine("Price Type"::Purchase, PurchaseHeader, PurchaseLine);

        // [THEN] List of sources contains 'All Jobs', Job 'J', Job Task 'JT'
        VerifyJobSources(JobTask, PurchaseLinePrice, 1, 1, 1);
    end;

    [Test]
    procedure T047_PurchLineNoJobDoesNotAddsJobSources()
    var
        Vendor: Record Vendor;
        Job: Record Job;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
    begin
        // [FEATURE] [Purchase] [Job] [UT]
        Initialize();
        // [GIVEN] Vendor 'A'
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Invoice for Vendor 'A'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");

        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', "Job no." <blank>
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := LibraryInventory.CreateItemNo();
        PurchaseLine."Job No." := '';
        PurchaseLine.Modify(true);

        // [WHEN] SetLine()
        PurchaseLinePrice.SetLine("Price Type"::Purchase, PurchaseHeader, PurchaseLine);

        // [THEN] List of sources does not contain 'All Jobs', Job, Job Task
        Clear(Job);
        VerifyJobSources(Job, PurchaseLinePrice, 0, 0, 0);
    end;

    [Test]
    procedure T050_ApplyDiscountSalesLineCalculateDiscIfAllowLineDiscFalseV15()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceCalculationSetup: Record "Price Calculation Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculation: interface "Price Calculation";
        LineWithPrice: Interface "Line With Price";
        ExpectedDiscount: Decimal;
        Line: Variant;
    begin
        // [FEATURE] [Sales] [Discount] [UT] [V15]
        // [SCENARIO] ApplyDiscount() updates 'Line Discount %' in sales line even if "Allow Line Disc." is false.
        Initialize();
        // [GIVEN] "Sales Line discount" record for Customer and Item 'X': 15%
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ExpectedDiscount := LibraryRandom.RandInt(50);
        CreateCustomerItemDiscount(SalesLineDiscount, Customer."No.", Item, ExpectedDiscount);

        // [GIVEN] Invoice, where "Price Calculation Method" is "Lowest Price"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Line Discount %" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Allow Line Disc." := false;
        SalesLine.Modify(true);

        // [WHEN] ApplyDiscount() for the sales line
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Lowest Price",
            PriceCalculationSetup.Type::Sale, PriceCalculationSetup."Asset Type"::" ",
            "Price Calculation Handler"::"Business Central (Version 15.0)", true);

        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine(PriceCalculationSetup.Type::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.Init(LineWithPrice, PriceCalculationSetup);
        PriceCalculation.ApplyDiscount();

        // [THEN] Line, where "Line Discount %" is 15%
        PriceCalculation.GetLine(Line);
        SalesLine := Line;
        SalesLine.TestField("Allow Line Disc.", false);
        SalesLine.TestField("Line Discount %", ExpectedDiscount);
    end;

    [Test]
    procedure T051_ApplyDiscountSalesLineCalculateDiscIfAllowLineDiscFalseV16()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculation: interface "Price Calculation";
        LineWithPrice: Interface "Line With Price";
        ExpectedDiscount: Decimal;
        Line: Variant;
    begin
        // [FEATURE] [Sales] [Discount] [UT]
        // [SCENARIO] ApplyDiscount() updates 'Line Discount %' in sales line even if "Allow Line Disc." is false.
        Initialize();
        // [GIVEN] "Sales Line discount" record for Customer and Item 'X': 15%
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ExpectedDiscount := LibraryRandom.RandInt(50);
        CreateCustomerItemDiscount(PriceListLine, "Price Source Type"::Customer, Customer."No.", Item, ExpectedDiscount);

        // [GIVEN] Invoice, where "Price Calculation Method" is "Lowest Price"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Line Discount %" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine."Allow Line Disc." := false;
        SalesLine.Modify(true);

        // [WHEN] ApplyDiscount() for the sales line
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, PriceCalculationSetup.Method::"Lowest Price",
            PriceCalculationSetup.Type::Sale, PriceCalculationSetup."Asset Type"::" ",
            "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        LineWithPrice := SalesLinePrice;
        LineWithPrice.SetLine(PriceCalculationSetup.Type::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(LineWithPrice, PriceCalculation);
        PriceCalculation.Init(LineWithPrice, PriceCalculationSetup);
        PriceCalculation.ApplyDiscount();

        // [THEN] Line, where "Line Discount %" is 15%
        PriceCalculation.GetLine(Line);
        SalesLine := Line;
        SalesLine.TestField("Allow Line Disc.", false);
        SalesLine.TestField("Line Discount %", ExpectedDiscount);
    end;

    [Test]
    procedure T060_CalcBestAmountPicksBestPriceOfTwoBestFirst()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
    begin
        // [FEATURE] [UT]
        // [GIVEN] Buffer where Quantity = 1, "Currency Code" = <blank>
        MockBuffer("Price Type"::Sale, '', 1, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is blank, "Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 15);
        // [GIVEN] 'Draft' Price line #3, where "Currency Code" is blank, "Unit Price" is 9 (best of 3)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 9);
        TempPriceListLine.Status := TempPriceListLine.Status::Draft;
        TempPriceListLine.Modify();

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #1 is picked
        TempPriceListLine.TestField("Line No.", 10000);
    end;

    [Test]
    procedure T061_CalcBestAmountPicksBestPriceOfTwoBestSecond()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
    begin
        // [FEATURE] [UT]
        // [GIVEN] Buffer where Quantity = 1, "Currency Code" = <blank>
        MockBuffer("Price Type"::Sale, '', 1, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 15 (is worse that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 15);
        // [GIVEN] Price line #2, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] 'Inactive' Price line #3, where "Currency Code" is blank, "Unit Price" is 9 (best of 3)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 9);
        TempPriceListLine.Status := TempPriceListLine.Status::Inactive;
        TempPriceListLine.Modify();

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 20000);
    end;

    [Test]
    procedure T062_CalcBestAmountWorsePriceButFilledCurrencyCode()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 20000);
    end;

    [Test]
    procedure T063_CalcBestAmountAmongPricesWhereFilledCurrencyCode()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Unit Price" is 16 (is worse that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 16);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 20000);
    end;

    [Test]
    procedure T064_CalcBestAmountAmongPricesWhereFilledCurrencyCodeOrVariantCodeSecond()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 16 (is worse that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', VariantCode, 16);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #2 is picked
        TempPriceListLine.TestField("Line No.", 20000);
    end;

    [Test]
    procedure T065_CalcBestAmountAmongPricesWhereFilledCurrencyCodeOrVariantCodeThird()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 11 (is better that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', VariantCode, 11);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #3 is picked
        TempPriceListLine.TestField("Line No.", 30000);
    end;

    [Test]
    procedure T066_CalcBestAmountAmongPricesWhereFilledCurrencyCodeAndVariantCode()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 14 (is better that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', VariantCode, 14);
        // [GIVEN] Price line #4, where "Currency Code" is 'X', "Variant Code" is 'A', "Unit Price" is 20 (is worse of all price lines)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, VariantCode, 20);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #4 is picked
        TempPriceListLine.TestField("Line No.", 40000);
    end;

    [Test]
    procedure T067_CalcBestAmountAmongPricesWhereFilledCurrencyCodeAndVariantCodeOfTwo()
    var
        TempPriceListLine: Record "Price List Line" temporary;
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        PriceCalculationV16: Codeunit "Price Calculation - V16";
        CurrencyCode: Code[10];
        CurrencyFactor: Decimal;
        VariantCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [GIVEN] Currency 'X', where factor = 1.3
        CurrencyFactor := 1.3;
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), CurrencyFactor, CurrencyFactor);
        // [GIVEN] Variant code 'A'
        VariantCode := 'A';
        // [GIVEN] Buffer line, where Quantity = 1, "Currency Code" = 'X'
        MockBuffer("Price Type"::Sale, CurrencyCode, CurrencyFactor, PriceCalculationBufferMgt);
        // [GIVEN] Price line #1, where "Currency Code" is 'X', "Variant Code" is 'A', "Unit Price" is 10
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, VariantCode, 10);
        // [GIVEN] Price line #2, where "Currency Code" is 'X', "Variant Code" is blank,"Unit Price" is 15 (is worse that the first price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, '', 15);
        // [GIVEN] Price line #3, where "Currency Code" is blank, "Variant Code" is 'A', "Unit Price" is 14 (is better that the second price line)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', VariantCode, 14);
        // [GIVEN] Price line #4, where "Currency Code" is 'X', "Variant Code" is 'A', "Unit Price" is 20 (is worse of all price lines)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, CurrencyCode, VariantCode, 20);
        // [GIVEN] Price line #5, where "Currency Code" is blank, "Variant Code" is blank, "Unit Price" is 7 (the best)
        AddPriceLine(TempPriceListLine, "Price Type"::Sale, '', '', 7);

        // [WHEN] CalcBestAmount()
        TempPriceListLine.FindFirst();
        PriceCalculationV16.CalcBestAmount("Price Amount Type"::Price, PriceCalculationBufferMgt, TempPriceListLine);
        // [THEN] Price line #1 is picked
        TempPriceListLine.TestField("Line No.", 10000);
    end;

    [Test]
    procedure T070_JobPlanningLineTakeZeroJobItemDiscountOverItemDiscount()
    var
        Customer: Record Customer;
        Item: Record Item;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: array[2] of Record "Price List Line";
        PriceListHeader: array[2] of Record "Price List Header";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Sale,
            "Price Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Item 'I' Discount '1%' for Customer 'C'
        LibrarySales.CreateCustomer(Customer);
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::Customer, Customer."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Discount, "Price Asset Type"::Item, Item."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] Job 'J', where "Bill-to Customer No." is 'C', Item 'I' "Unit Price" is 'X', Discount is '0%' for Customer 'C'
        LibraryJob.CreateJob(Job, Customer."No.");
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Job, Job."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Any, "Price Asset Type"::Item, Item."No.");
        PriceListLine[2]."Line Discount %" := 0;
        PriceListLine[2].Status := PriceListLine[2].Status::Active;
        PriceListLine[2].Modify();
        // [GIVEN] Job Planning Line, wheer Job 'J', Customer 'C'
        JobPlanningLine.Validate("Job No.", Job."No.");
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        // [WHEN] Enter Item 'I' in the Job Planning Line
        JobPlanningLine.Validate("No.", Item."No.");
        // [THEN] "Unit Price" is 'X', "Line Discount" is 0
        JobPlanningLine.TestField("Unit Price", PriceListLine[2]."Unit Price");
        JobPlanningLine.TestField("Line Discount %", 0);
    end;

    [Test]
    procedure T071_JobPlanningLineTakeZeroJobItemPriceOverItemPrice()
    var
        Customer: Record Customer;
        Item: Record Item;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: array[2] of Record "Price List Line";
        PriceListHeader: array[2] of Record "Price List Header";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Sale,
            "Price Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Item 'I' Price '100.00' for Customer 'C'
        LibrarySales.CreateCustomer(Customer);
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::Customer, Customer."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] Job 'J', where "Bill-to Customer No." is 'C', Item 'I' "Unit Price" is 0.00, Discount is '1%' for Customer 'C'
        LibraryJob.CreateJob(Job, Customer."No.");
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::Job, Job."No.");
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Any, "Price Asset Type"::Item, Item."No.");
        PriceListLine[2]."Unit Price" := 0;
        PriceListLine[2].Status := PriceListLine[2].Status::Active;
        PriceListLine[2].Modify();
        // [GIVEN] Job Planning Line, wheer Job 'J', Customer 'C'
        JobPlanningLine.Validate("Job No.", Job."No.");
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);
        // [WHEN] Enter Item 'I' in the Job Planning Line
        JobPlanningLine.Validate("No.", Item."No.");
        // [THEN] "Unit Price" is 0.00, "Line Discount" is 1%
        JobPlanningLine.TestField("Unit Price", 0);
        JobPlanningLine.TestField("Line Discount %", PriceListLine[2]."Line Discount %");
    end;

    [Test]
    procedure T072_JobPlanningLineForGLAccountPicksCostByMinQty()
    var
        GLAccountNo: Code[20];
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: array[2] of Record "Price List Line";
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Purchase,
            "Price Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        // [GIVEN] GLAccount 'A'
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        // [GIVEN] Job 'J'
        LibraryJob.CreateJob(Job);
        // [GIVEN] Price list for 'J' where are 2 lines for account 'A':
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Job, Job."No.");
        // [GIVEN] 1st line, where "Minimum Quantity" is 0, "Direct Unit Cost" is 1000
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", GLAccountNo);
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] 2nd line, where "Minimum Quantity" is 2, "Direct Unit Cost" is 999
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", GLAccountNo);
        PriceListLine[2]."Minimum Quantity" := 2;
        PriceListLine[2]."Direct Unit Cost" := PriceListLine[1]."Direct Unit Cost" - 1;
        PriceListLine[2].Status := PriceListLine[2].Status::Active;
        PriceListLine[2].Modify();
        // [GIVEN] Job Planning Line, where Job 'J'
        JobPlanningLine.Validate("Job No.", Job."No.");
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::"G/L Account");

        // [WHEN] Enter G/L Account 'A' in the Job Planning Line
        JobPlanningLine.Validate("No.", GLAccountNo);
        // [THEN] "Unit Cost" is 1000, "Unit Price" is 0
        JobPlanningLine.TestField("Unit Cost", PriceListLine[1]."Direct Unit Cost");
        JobPlanningLine.TestField("Unit Price", 0);

        // [WHEN] Change Quantity to 2
        JobPlanningLine.Validate(Quantity, 2);
        // [THEN] "Unit Cost" is 999, "Unit Price" is 0
        JobPlanningLine.TestField("Unit Cost", PriceListLine[2]."Direct Unit Cost");
        JobPlanningLine.TestField("Unit Price", 0);
    end;

    [Test]
    procedure T073_JobPlanningLineForItemPicksCostByMinQty()
    var
        Item: Record Item;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: array[2] of Record "Price List Line";
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Purchase,
            "Price Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Job 'J'
        LibraryJob.CreateJob(Job);
        // [GIVEN] Price list for 'J' where are 2 lines for Item 'I':
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Job, Job."No.");
        // [GIVEN] 1st line, where "Minimum Quantity" is 0, "Direct Unit Cost" is 1000
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] 2nd line, where "Minimum Quantity" is 2, "Direct Unit Cost" is 999
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine[2]."Minimum Quantity" := 2;
        PriceListLine[2]."Direct Unit Cost" := PriceListLine[1]."Direct Unit Cost" - 1;
        PriceListLine[2].Status := PriceListLine[2].Status::Active;
        PriceListLine[2].Modify();
        // [GIVEN] Job Planning Line, where Job 'J'
        JobPlanningLine.Validate("Job No.", Job."No.");
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Item);

        // [WHEN] Enter Item 'I' in the Job Planning Line
        JobPlanningLine.Validate("No.", Item."No.");
        // [THEN] "Direct Unit Cost (LCY)" is 1000, "Unit Cost" is 0, "Unit Price" is 0
        JobPlanningLine.TestField("Direct Unit Cost (LCY)", PriceListLine[1]."Direct Unit Cost");
        JobPlanningLine.TestField("Unit Cost", 0);
        JobPlanningLine.TestField("Unit Price", 0);

        // [WHEN] Change Quantity to 2
        JobPlanningLine.Validate(Quantity, 2);
        // [THEN] "Direct Unit Cost (LCY)" is 999, "Unit Cost" is 0, "Unit Price" is 0
        JobPlanningLine.TestField("Direct Unit Cost (LCY)", PriceListLine[2]."Direct Unit Cost");
        JobPlanningLine.TestField("Unit Cost", 0);
        JobPlanningLine.TestField("Unit Price", 0);
    end;

    [Test]
    procedure T074_JobPlanningLineForResourcePicksCostByMinQty()
    var
        Resource: Record Resource;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: array[2] of Record "Price List Line";
        PriceListHeader: Record "Price List Header";
    begin
        Initialize();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Purchase,
            "Price Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        // [GIVEN] Resource 'R'
        LibraryResource.CreateResource(Resource, '');
        // [GIVEN] Job 'J'
        LibraryJob.CreateJob(Job);
        // [GIVEN] Price list for 'J' where are 2 lines for Resource 'R':
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Job, Job."No.");
        // [GIVEN] 1st line, where "Minimum Quantity" is 0, "Direct Unit Cost" is 1000, "Unit Cost" is 1010
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Resource, Resource."No.");
        PriceListLine[1]."Unit Cost" := PriceListLine[1]."Direct Unit Cost" + 10;
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] 2nd line, where "Minimum Quantity" is 2, "Direct Unit Cost" is 999, "Unit Cost" is 1019
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Resource, Resource."No.");
        PriceListLine[2]."Minimum Quantity" := 2;
        PriceListLine[2]."Direct Unit Cost" := PriceListLine[1]."Direct Unit Cost" - 1;
        PriceListLine[2]."Unit Cost" := PriceListLine[2]."Direct Unit Cost" + 20;
        PriceListLine[2].Status := PriceListLine[2].Status::Active;
        PriceListLine[2].Modify();
        // [GIVEN] Job Planning Line, where Job 'J'
        JobPlanningLine.Validate("Job No.", Job."No.");
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Resource);

        // [WHEN] Enter Resource 'R' in the Job Planning Line
        JobPlanningLine.Validate("No.", Resource."No.");
        // [THEN] "Direct Unit Cost (LCY)" is 1000, "Unit Cost (LCY)" is 1010, "Unit Cost" is 1010
        JobPlanningLine.TestField("Direct Unit Cost (LCY)", PriceListLine[1]."Direct Unit Cost");
        JobPlanningLine.TestField("Unit Cost (LCY)", PriceListLine[1]."Unit Cost");
        JobPlanningLine.TestField("Unit Cost", PriceListLine[1]."Unit Cost");

        // [WHEN] Change Quantity to 2
        JobPlanningLine.Validate(Quantity, 2);
        // [THEN] "Direct Unit Cost (LCY)" is 999, "Unit Cost (LCY)" is 1019, "Unit Cost" is 1019
        JobPlanningLine.TestField("Direct Unit Cost (LCY)", PriceListLine[2]."Direct Unit Cost");
        JobPlanningLine.TestField("Unit Cost (LCY)", PriceListLine[2]."Unit Cost");
        JobPlanningLine.TestField("Unit Cost", PriceListLine[2]."Unit Cost");
    end;

    [Test]
    procedure T080_ConvertVATNormalExclVATToNormalInclVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceCalculationSetup: Record "Price Calculation Setup";
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpectedPriceInclVAT: Decimal;
    begin
        Initialize();
        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        PriceCalculationSetup.DeleteAll();
        LibraryPriceCalculation.AddSetup(
            PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Sale,
            "Price Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        // [GIVEN] Customer 'C' and Item 'I' with VAT posting setup, where "VAT Calculation Type"::"Normal VAT"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        // [GIVEN] Price line for 'I', where "Prices Including VAT" is 'No', "Unit Price" is 100, "VAT %" is 20
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Price Includes VAT" := false;
        PriceListLine."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        ExpectedPriceInclVAT := Round(PriceListLine."Unit Price" * (100 + VATPostingSetup."VAT %") / 100, 0.01);

        // [GIVEN] Sales Invoice for Customer 'C', where "Prices Including VAT" is 'Yes'
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify();
        // [WHEN] Add line for item 'I'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Unit Price" is 120
        SalesLine.Find();
        Assert.AreNearlyEqual(ExpectedPriceInclVAT, Round(SalesLine."Unit Price", 0.01), 0.01, 'Wrong Unit Price incl VAT');
    end;

    [Test]
    procedure T081_ConvertVATNormalInclVATToNormalExclVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpectedPriceExclVAT: Decimal;
    begin
        Initialize();
        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Customer 'C' and Item 'I' with VAT posting setup, where "VAT Calculation Type"::"Normal VAT"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        // [GIVEN] Price line for 'I', where "Prices Including VAT" is 'Yes', "Unit Price" is 120, "VAT %" is 20
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Price Includes VAT" := true;
        PriceListLine."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        ExpectedPriceExclVAT := Round(PriceListLine."Unit Price" * 100 / (100 + VATPostingSetup."VAT %"), 0.01);

        // [GIVEN] Sales Invoice for Customer 'C', where "Prices Including VAT" is 'No'
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify();
        // [WHEN] Add line for item 'I'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Unit Price" is 100
        SalesLine.Find();
        Assert.AreNearlyEqual(ExpectedPriceExclVAT, Round(SalesLine."Unit Price", 0.01), 0.01, 'Wrong Unit Price excl VAT');
    end;

    [Test]
    procedure T082_ConvertVATNormalExclVATToRevChargeInclVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        RevChVATPostingSetup: Record "VAT Posting Setup";
        ExpectedPriceExclVAT: Decimal;
    begin
        Initialize();
        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Customer 'C' with "Reverce Charge VAT" setup, and Item 'I' with "Normal VAT" setup
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        CreateRevChargeVATPostingSetup(VATPostingSetup, RevChVATPostingSetup);
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(RevChVATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Price line for 'I', where "Prices Including VAT" is 'No', "Unit Price" is 100, "Normal VAT" setup
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Price Includes VAT" := false;
        PriceListLine."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        ExpectedPriceExclVAT := Round(PriceListLine."Unit Price", 0.01);
        // [GIVEN] Sales Invoice for Customer 'C', where "Prices Including VAT" is 'Yes'
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify();
        // [WHEN] Add line for item 'I'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Unit Price" is 100
        SalesLine.Find();
        Assert.AreNearlyEqual(
            ExpectedPriceExclVAT, Round(SalesLine."Unit Price", 0.01), 0.01, 'Wrong Unit Price excl VAT');
    end;

    [Test]
    procedure T083_ConvertVATNormalInclVATToRevChargeExclVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        RevChVATPostingSetup: Record "VAT Posting Setup";
        ExpectedPriceExclVAT: Decimal;
    begin
        Initialize();
        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Customer 'C' with "Reverce Charge VAT" setup, and Item 'I' with "Normal VAT" setup
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        CreateRevChargeVATPostingSetup(VATPostingSetup, RevChVATPostingSetup);
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(RevChVATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Price line for 'I', where "Prices Including VAT" is 'Yes', "Unit Price" is 125, "Normal VAT" setup
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Price Includes VAT" := true;
        PriceListLine."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        ExpectedPriceExclVAT := Round(PriceListLine."Unit Price" * 100 / (100 + VATPostingSetup."VAT %"), 0.01);

        // [GIVEN] Sales Invoice for Customer 'C', where "Prices Including VAT" is 'No'
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify();
        // [WHEN] Add line for item 'I'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Unit Price" is 100
        SalesLine.Find();
        Assert.AreNearlyEqual(ExpectedPriceExclVAT, Round(SalesLine."Unit Price", 0.01), 0.01, 'Wrong Unit Price excl VAT');
    end;

    [Test]
    procedure T084_ConvertVATNormalInclVATToRevChargeInclVAT()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        RevChVATPostingSetup: Record "VAT Posting Setup";
        ExpectedPriceExclVAT: Decimal;
    begin
        Initialize();
        // [GIVEN] New pricing enabled
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Customer 'C' with "Reverce Charge VAT" setup, and Item 'I' with "Normal VAT" setup
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
        CreateRevChargeVATPostingSetup(VATPostingSetup, RevChVATPostingSetup);
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(RevChVATPostingSetup."VAT Bus. Posting Group"));

        // [GIVEN] Price line for 'I', where "Prices Including VAT" is 'Yes', "Unit Price" is 125, "Normal VAT" setup
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Price Includes VAT" := true;
        PriceListLine."VAT Bus. Posting Gr. (Price)" := VATPostingSetup."VAT Bus. Posting Group";
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();
        ExpectedPriceExclVAT :=
            Round(PriceListLine."Unit Price" * 100 / (100 + VATPostingSetup."VAT %"), 0.01);

        // [GIVEN] Sales Invoice for Customer 'C', where "Prices Including VAT" is 'Yes'
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify();
        // [WHEN] Add line for item 'I'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Unit Price" is 100
        SalesLine.Find();
        Assert.AreNearlyEqual(ExpectedPriceExclVAT, Round(SalesLine."Unit Price", 0.01), 0.01, 'Wrong Unit Price excl VAT');
    end;

    [Test]
    procedure T110_ApplyDiscountSalesLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceCalculation: interface "Price Calculation";
        ExpectedDiscount: Decimal;
        Line: Variant;
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] ApplyDiscount() updates 'Line Discount %' in sales line.
        Initialize();
        // [GIVEN] 2 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'B' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        // [GIVEN] Two "Sales Line discount" records for Item 'X': 15% and 14.99%
        PriceListLine.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        ExpectedDiscount := LibraryRandom.RandInt(50);
        CreateCustomerItemDiscount(PriceListLine, "Price Source Type"::Customer, Customer."No.", Item, ExpectedDiscount - 0.01);
        CreateCustomerItemDiscount(PriceListLine, "Price Source Type"::"All Customers", '', Item, ExpectedDiscount);

        // [GIVEN] Invoice, where "Price Calculation Method" is "Lowest Price"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Line Discount %" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
        SalesLine."Bill-to Customer No." := SalesHeader."Bill-to Customer No.";
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Modify(true);

        // [WHEN] ApplyDiscount() for the sales line
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(SalesLinePrice, PriceCalculation);
        PriceCalculation.ApplyDiscount();
        PriceCalculation.GetLine(Line);
        SalesLine := Line;

        // [THEN] Line, where "Line Discount %" is 15%
        SalesLine.TestField("Line Discount %", ExpectedDiscount);
    end;

    [Test]
    procedure T111_ApplyPriceSalesLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceCalculationSetup: array[5] of Record "Price Calculation Setup";
        SalesLinePrice: Codeunit "Sales Line - Price";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PriceCalculation: interface "Price Calculation";
        ExpectedPrice: Decimal;
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] ApplyPrice() updates 'Unit Price' in sales line.
        Initialize();
        // [GIVEN] 2 setup lines: 'A','B' for 'Sale' for 'All' asset types, 'B' - default
        PriceCalculationSetup[5].DeleteAll();
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[1], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::Test, false);
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup[2], PriceCalculationSetup[5].Method::"Lowest Price", PriceCalculationSetup[5].Type::Sale, PriceCalculationSetup[5]."Asset Type"::" ", "Price Calculation Handler"::"Business Central (Version 16.0)", true);

        // [GIVEN] Item 'X', where "Unit Price" is 100
        ExpectedPrice := LibraryRandom.RandDec(1000, 2);
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := ExpectedPrice + 0.02;
        Item.Modify();
        // [GIVEN] Sales prices for Item 'X': 99.99 and 99.98
        LibrarySales.CreateCustomer(Customer);
        PriceListLine.DeleteAll();
        CreateCustomerItemPrice(PriceListLine, "Price Source Type"::Customer, Customer."No.", Item, ExpectedPrice);
        CreateCustomerItemPrice(PriceListLine, "Price Source Type"::"All Customers", '', Item, ExpectedPrice + 0.01);

        // [GIVEN] Invoice, where "Price Calculation Method" is not defined
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X', and "Unit Price" is 0
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := Item."No.";
        SalesLine.Quantity := 1;
        SalesLine.Modify(true);

        // [WHEN] ApplyPrice for the sales line
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);
        PriceCalculationMgt.GetHandler(SalesLinePrice, PriceCalculation);
        SalesLine.ApplyPrice(SalesLine.FieldNo(Quantity), PriceCalculation);

        // [THEN] Line, where "Unit Price" is 99.98, "Price Calculation Method" is 'Lowest Price'
        SalesLine.TestField("Unit Price", ExpectedPrice);
        // SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
    end;

    [Test]
    procedure T112_ApplyPriceFromItemCardSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] ApplyPrice() updates 'Unit Price' in sales line with Item's "Unit Price" if no prices set.
        Initialize();
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Item 'X', where "Unit Price" is 100 and there is no sales prices for Item 'X'
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandDec(1000, 2);
        Item.Modify();
        // [GIVEN] Invoice, where "Price Calculation Method" is not defined
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        // [GIVEN] with one line, where "Type" is 'Item'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // [WHEN] Set "No." as 'X' in the sales line
        SalesLine.Validate("No.", Item."No.");

        // [THEN] Line, where "Unit Price" is 100, "Price Calculation Method" is 'Lowest Price'
        SalesLine.TestField("Unit Price", Item."Unit Price");
        //SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T122_ApplyPriceFromItemCardServiceLine()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Service] [Price]
        // [SCENARIO] ApplyPrice() updates 'Unit Price' in sales line with Item's "Unit Price" if no prices set.
        Initialize();
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Item 'X', where "Unit Price" is 100 and there is no sales prices for Item 'X'
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandDec(1000, 2);
        Item.Modify();
        // [GIVEN] Order, where "Price Calculation Method" is not defined
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        // [GIVEN] with one line, where "Type" is 'Item'
        // [WHEN] Set "No." as 'X' in the sales line
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");

        // [THEN] Line, where "Unit Price" is 100, "Price Calculation Method" is 'Lowest Price'
        ServiceLine.TestField("Unit Price", Item."Unit Price");
        //SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T132_ApplyPriceFromItemCardPurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Purchase] [Price]
        // [SCENARIO] ApplyPrice() updates 'Direct Unit Cost' in sales line with Item's "Last Direct Cost" if no prices set.
        Initialize();
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Item 'X', where "Last Direct Cost" is 100 and there is no sales prices for Item 'X'
        LibraryInventory.CreateItem(Item);
        Item."Last Direct Cost" := LibraryRandom.RandDec(1000, 2);
        Item.Modify();
        // [GIVEN] Invoice, where "Price Calculation Method" is not defined
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        // [GIVEN] with one line, where "Type" is 'Item'
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        // [WHEN] Set "No." as 'X' in the sales line
        PurchaseLine.Validate("No.", Item."No.");

        // [THEN] Line, where "Direct Unit Cost" is 100, "Price Calculation Method" is 'Lowest Price'
        PurchaseLine.TestField("Direct Unit Cost", Item."Last Direct Cost");
        //SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T160_ApplyDiscountSalesLineIfNoPriceNoLineDiscAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is 0 in sales line if Customer does not allow discount and no price line that allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] No price list lines with for Item 'I'
        RemovePricesForItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLine, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 0, "Allow Line Disc." is No
        VerifyLineDiscount(SalesLine, 0);

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T161_ApplyDiscountSalesLineIfNoPriceButLineDiscAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is set in sales line if Customer allows discount, but no price line that allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is Yes
        CreateCustomerAllowingLineDisc(Customer, true);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] No price list lines with for Item 'I'
        RemovePricesForItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C, "Line Discount %" is 'X'
        CreateDiscountLine(PriceListLine, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 'X', "Allow Line Disc." is Yes
        VerifyLineDiscount(SalesLine, PriceListLine."Line Discount %");

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T162_ApplyDiscountSalesLineIfPriceDoesNotAllowLineDiscAndNotAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLineDisc: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is 0 in sales line if Customer does not allow discount and found price line does not allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Alloe Line Disc." is 'No'
        CreatePriceLine(PriceListLine, Customer, Item, false);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLineDisc, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 0, "Allow Line Disc." is No
        VerifyLineDiscount(SalesLine, 0);

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T163_ApplyDiscountSalesLineIfPriceDoesNotAllowLineDiscButDiscAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLineDisc: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is 0 in sales line if Customer allows discount, but the found price line does not allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is Yes
        CreateCustomerAllowingLineDisc(Customer, true);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Allow Line Disc." is 'No'
        CreatePriceLine(PriceListLine, Customer, Item, false);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLineDisc, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 0, "Allow Line Disc." is No
        VerifyLineDiscount(SalesLine, 0);

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T164_ApplyDiscountSalesLineIfPriceAllowsLineDiscButDiscNotAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLineDisc: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is set in sales line if Customer does not allow discount, but the found price line allows it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Allow Line Disc." is 'Yes'
        CreatePriceLine(PriceListLine, Customer, Item, true);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLineDisc, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 'X', "Allow Line Disc." is Yes
        VerifyLineDiscount(SalesLine, PriceListLineDisc."Line Discount %");

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T165_ApplyDiscountSalesLineIfPriceAllowsLineDiscAndDiscAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLineDisc: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] "Line Discount %" is set in sales line if Customer does allow discount and the found price line allows it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is Yes
        CreateCustomerAllowingLineDisc(Customer, true);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Allow Line Disc." is 'Yes'
        CreatePriceLine(PriceListLine, Customer, Item, true);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLineDisc, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [THEN] Sales Line, where "Line Discount" is 'X', "Allow Line Disc." is Yes
        VerifyLineDiscount(SalesLine, PriceListLineDisc."Line Discount %");

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLineDiscountModalPageHandler')]
    procedure T170_PickDiscountSalesLineIfNoPriceLineDiscButAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] Cannot pick Discount for the sales line if Customer allows discount and no price line that allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is Yes
        CreateCustomerAllowingLineDisc(Customer, true);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] No price list lines with for Item 'I'
        RemovePricesForItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLine, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [WHEN] PickDiscount
        SalesLine.PickDiscount();

        // [THEN] Error message: 'Allow Line Disc. must be equal to Yes'
        VerifyLineDiscount(SalesLine, PriceListLine."Line Discount %");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePriceModalPageHandler')]
    procedure T171_PickPriceSalesLineBelowMinQuantity()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] Cannot pick price line for the sales line if minimal quantity in the price line below the quantity in the sales line.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Minimum Quantity" is 10
        CreatePriceLine(PriceListLine, Customer, Item, false);
        PriceListLine."Minimum Quantity" := 10;
        PriceListLine.Modify();
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I', where Quantity is 1
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [WHEN] PickPrice
        asserterror SalesLine.PickPrice();

        // [THEN] Error message: "Qunatity is below Minimal Qty"
        Assert.ExpectedError(PickedWrongMinQtyErr);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePriceModalPageHandler')]
    procedure T172_PickPriceSalesLineWithNotAllowedLineDiscount()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        PriceListLineDisc: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] Picked price line with not allowed discount makes previously calculated discount zero.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is Yes
        CreateCustomerAllowingLineDisc(Customer, true);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLineDisc, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I', where Quantity is 1
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        VerifyLineDiscount(SalesLine, PriceListLineDisc."Line Discount %");
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Allow Line Disc." is No
        CreatePriceLine(PriceListLine, Customer, Item, false);

        // [WHEN] PickPrice
        SalesLine.PickPrice();

        // [THEN] "Line Discount %" is 0
        VerifyLineDiscount(SalesLine, 0);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLineDiscountModalPageHandler')]
    procedure T173_PickDiscountSalesLineIfNoPriceNoLineDiscAllowedByCustomer()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Discount]
        // [SCENARIO] Cannot pick Discount for the sales line if Customer does not allow discount and no price line that allow it.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] One price list line for Item 'I', where Amount Type is 'Price'
        RemovePricesForItem(Item);
        CreatePriceLine(PriceListLine, Customer, Item, false);
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C
        CreateDiscountLine(PriceListLine, Customer, Item);
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [WHEN] PickDiscount
        asserterror SalesLine.PickDiscount();

        // [THEN] Error message: 'Allow Line Disc. must have a value in Sales Line'
        Assert.ExpectedError(AllowLineDiscErr);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLineModalPageHandler')]
    procedure T174_PickPriceSalesLineOfTwoPriceLinesAmountTypeAny()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListHeader: array[3] of Record "Price List Header";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
        ExpectedUnitPrice: array[2] of Decimal;
        ExpectedDiscount: Decimal;
    begin
        // [FEATURE] [Sales] [Price] [UI]
        // [SCENARIO] While picking prices "Get Price Lines" page shows lines with "Amount Type" 'Any'
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] One price list line for Item 'I', where Amount Type is 'Price', "Unit Price" is 'P1'
        RemovePricesForItem(Item);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[1], PriceListHeader[1]."Price Type"::Sale, PriceListHeader[1]."Source Type"::Customer, Customer."No.");
        PriceListLine."Price List Code" := PriceListHeader[1].Code;
        CreatePriceLine(PriceListLine, Customer, Item, false);
        ExpectedUnitPrice[1] := PriceListLine."Unit Price";
        ExpectedUnitPrice[2] := 10 * ExpectedUnitPrice[1];
        // [GIVEN] Price List Line, where "Amount Type" is 'Discount', "Source No." is 'C, "Line Discount %" is 'D1'
        CreateDiscountLine(PriceListLine, Customer, Item);
        ExpectedDiscount := PriceListLine."Line Discount %";

        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        // [GIVEN] Calculate discount, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        // [GIVEN] Sales Line, where "Unit Price" is 'P1', "Line Discount %" is 0, as "Allow Line Disc." is 'No'
        SalesLine.TestField("Unit Price", ExpectedUnitPrice[1]);
        SalesLine.TestField("Allow Line Disc.", false);
        SalesLine.TestField("Line Discount %", 0);

        // [GIVEN] Added price list line for Item 'I', where Amount Type is 'Any', "Unit Price" is 'P2', "Line Discount %" is 'D2'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[2], PriceListHeader[2]."Price Type"::Sale, PriceListHeader[2]."Source Type"::Customer, Customer."No.");
        PriceListLine."Price List Code" := PriceListHeader[2].Code;
        CreatePriceLine(PriceListLine, Customer, Item, true);
        PriceListLine."Unit Price" := ExpectedUnitPrice[2];
        PriceListLine."Line Discount %" := ExpectedDiscount + 0.01; // just a better discount
        PriceListLine."Amount Type" := PriceListLine."Amount Type"::Any;
        PriceListLine.Modify();

        // [GIVEN] Added price list line for Item 'I', where Amount Type is 'Price', "Unit Price" is 'P3'
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[3], PriceListHeader[3]."Price Type"::Sale, PriceListHeader[3]."Source Type"::Customer, Customer."No.");
        PriceListLine."Price List Code" := PriceListHeader[2].Code;
        CreatePriceLine(PriceListLine, Customer, Item, true);
        PriceListLine."Unit Price" := ExpectedUnitPrice[2] + 100.0;
        PriceListLine.Modify();

        // [WHEN] PickPrice with "Amount Type" 'Any'
        LibraryVariableStorage.Enqueue(PriceListHeader[2].Code); // for GetPriceLineModalPageHandler
        SalesLine.PickPrice();

        // [THEN] Sales Line, where "Unit Price" is 'P2', "Line Discount %" is '0', "Allow Line Disc." is Yes
        SalesLine.TestField("Unit Price", ExpectedUnitPrice[2]);
        SalesLine.TestField("Allow Line Disc.", true);
        SalesLine.TestField("Line Discount %", 0);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T175_CardPriceRestoredInSalesLineBelowMinQuantity()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price] [Minimum Quantity]
        // [SCENARIO] Price is taken from the Item card if the Quantity is below "Minimum Quantity" of the price list line
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I', where "Unit Price" is 'X'
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandDec(100, 2);
        Item.Modify();

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Minimum Quantity" is 10, "Unit Price" is 'Y'
        CreatePriceLine(PriceListLine, Customer, Item, false);
        PriceListLine."Minimum Quantity" := 5 + LibraryRandom.RandInt(100);
        PriceListLine.Modify();
        // [GIVEN] Sales Invoice for Customer 'C' selling Item 'I', where Quantity is 10, giving "Unit Price" as 'Y'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", PriceListLine."Minimum Quantity");
        Assert.AreEqual(PriceListLine."Unit Price", SalesLine."Unit Price", 'Unit Price in Sales Line for Minimum Quantity');

        // [WHEN] Change Quantity in Sales Line to 9 (below "Minimum Quantity")
        SalesLine.Validate(Quantity, SalesLine.Quantity - 1);

        // [THEN] Sales Line, where "Unit Price" is 'X' (from the Item card)
        SalesLine.TestField("Unit Price", Item."Unit Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePriceModalPageHandler')]
    procedure T176_PickPriceSalesLineOutOfDateStartindDate()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] Cannot pick price line for the sales line if "Starting Date" is later than "Order Date".
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales Order for Customer 'C' selling Item 'I', where "Order Date" is '010120'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Starting Date" is 020120, "Ending Date" is 0D
        CreatePriceLine(PriceListLine, Customer, Item, false);
        PriceListLine."Starting Date" := SalesHeader."Order Date" + 1;
        PriceListLine."Ending Date" := 0D;
        PriceListLine.Modify();

        // [WHEN] PickPrice
        asserterror SalesLine.PickPrice();

        // [THEN] Error message: "The selected price line is not valid..."
        Assert.ExpectedError(StrSubstNo(GetPriceOutOfDateErr, SalesHeader."Order Date"));
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePriceModalPageHandler')]
    procedure T177_PickPriceSalesLineWrongUnitOfMeasure()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemUnitofMeasure: array[2] of Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        UnitofMeasure: array[2] of Record "Unit of Measure";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] Cannot pick price line for the sales line if "Unit of Measure" does not match.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I' with twou unit of measures 'PCS' and 'BOX'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure[1]);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure[1], Item."No.", UnitofMeasure[1].Code, 1);
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure[2]);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure[1], Item."No.", UnitofMeasure[2].Code, 5);

        // [GIVEN] Sales Order for Customer 'C' selling , where "Order Date" is '100120'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        // [GIVEN] Sales Line, whre Item 'I' and "Unit Of Measure" 'PCS'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit of Measure", UnitofMeasure[1].Code);
        SalesLine.Modify();
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Unit Of Measure Code" 'BOX'
        CreatePriceLine(PriceListLine, Customer, Item, false);
        PriceListLine."Unit of Measure Code" := UnitofMeasure[2].Code;
        PriceListLine.Modify();

        // [WHEN] PickPrice
        asserterror SalesLine.PickPrice();

        // [THEN] Error message: "The Unit of Measure Code in the selected price line must be PCS."
        Assert.ExpectedError(
            StrSubstNo(GetPriceFieldMismatchErr,
            PriceListLine.FieldCaption("Unit of Measure Code"), SalesLine."Unit of Measure Code"));
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePriceModalPageHandler')]
    procedure T178_PickPriceSalesLineWrongCurrencyCode()
    var
        Customer: Record Customer;
        Item: Record Item;
        Currency: array[2] of Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Price]
        // [SCENARIO] Cannot pick price line for the sales line if "Currency Code" does not match.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C', where "Allow Line Disc." is No
        CreateCustomerAllowingLineDisc(Customer, false);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        Currency[1].Code := LibraryERM.CreateCurrencyWithRandomExchRates();
        LibraryERM.CreateCurrency(Currency[2]);

        // [GIVEN] Sales Order for Customer 'C' selling , where "Order Date" is '100120', "Currency Code" 'USD'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Currency Code", Currency[1].Code);
        SalesHeader.Modify();
        // [GIVEN] Sales Line, whrere Item 'I' and "Currency Code" 'USD'
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Currency Code" 'EUR'
        CreatePriceLine(PriceListLine, Customer, Item, false);
        PriceListLine."Currency Code" := Currency[2].Code;
        PriceListLine.Modify();

        // [WHEN] PickPrice
        asserterror SalesLine.PickPrice();

        // [THEN] Error message: "The Currency Code in the selected price line must be USD."
        Assert.ExpectedError(
            StrSubstNo(GetPriceFieldMismatchErr,
            PriceListLine.FieldCaption("Currency Code"), SalesLine."Currency Code"));
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPurchPriceLinePriceModalPageHandler')]
    procedure T180_PickPricePurchLineBelowMinQuantity()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Purchase] [Price]
        // [SCENARIO] Cannot pick price line for the Purchase line if minimal quantity in the price line below the quantity in the Purchase line.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Vendor 'V'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Minimum Quantity" is 10
        CreatePriceLine(PriceListLine, Vendor, Item, false);
        PriceListLine."Minimum Quantity" := 10;
        PriceListLine.Modify();
        // [GIVEN] Purchase Invoice for Vendor 'V' selling Item 'I', where Quantity is 1
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        // [WHEN] PickPrice
        asserterror PurchaseLine.PickPrice();

        // [THEN] Error message: "Quantity is below Minimal Qty"
        Assert.ExpectedError(PickedWrongMinQtyErr);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('GetPurchPriceLineDiscountModalPageHandler')]
    procedure T181_PickDiscountPurchLine()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        ItemDiscountGroup: Record "Item Discount Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Purchase] [Discount] [UI]
        // [SCENARIO 381378] Get Price Line page shows product columns if the item has Item Discount Group set.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Vendor 'V'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Item 'I', where "Item Disc. Group" is 'IDG'
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        Item."Item Disc. Group" := ItemDiscountGroup.Code;
        item.Modify();

        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C, "Minimum Quantity" is 0
        CreateDiscountLine(PriceListLine, Vendor, Item);
        // [GIVEN] Purchase Invoice for Vendor 'V' selling Item 'I', where Quantity is 1
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        // [WHEN] PickDiscount
        PurchaseLine.PickDiscount();

        // [THEN] "Asset Type" and "Asset No." are visible in the "Get Price Line" page
        // verified in GetPurchPriceLineDiscountModalPageHandler
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure T190_ActivateCampaignIfPriceExists()
    var
        Campaign: Record Campaign;
        CampaignTargetGr: Record "Campaign Target Group";
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        PriceListLine: Record "Price List Line";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
        OldHandler: enum "Price Calculation Handler";
        Msg: Text;
    begin
        // [FEATURE] [Sales] [Campaign]
        // [SCENARIO] Activate campaign if price list lines for the campaign do exist.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Campaign 'C'
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentHeader.Validate("Campaign No.", Campaign."No.");
        SegmentHeader.Validate("Campaign Target", true);
        SegmentHeader.Modify();
        // [GIVEN] Price List Line for Campaign 'C'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::Campaign, Campaign."No.",
            "Price Asset Type"::Item, LibraryInventory.CreateItemNo());

        // [WHEN] Activate Campaign 'C'
        CampaignTargetGroupMgt.ActivateCampaign(Campaign);

        // [THEN] Campaign C is activated (CampaignTargetGr added)
        CampaignTargetGr.SetRange("Campaign No.", Campaign."No.");
        Assert.RecordIsNotEmpty(CampaignTargetGr);
        // [THEN] Message: 'Campaign C is activated'.
        Msg := LibraryVariableStorage.DequeueText(); // from MessageHandler
        Assert.AreEqual(StrSubstNo(CampaignActivatedMsg, Campaign."No."), Msg, 'Wrong message.');

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    procedure T191_ActivateCampaignIfPriceDoesNotExist()
    var
        Campaign: Record Campaign;
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        PriceListLine: Record "Price List Line";
        CampaignTargetGr: Record "Campaign Target Group";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Campaign]
        // [SCENARIO] Activate campaign is stopped if price list lines for the campaign do not exist.
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Campaign 'C'
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentHeader.Validate("Campaign No.", Campaign."No.");
        SegmentHeader.Validate("Campaign Target", true);
        SegmentHeader.Modify();
        // [GIVEN] Price List Line for Campaign 'C' does not exist
        PriceListLine.SetRange("Source Type", PriceListLine."Source Type"::Campaign);
        PriceListLine.SetRange("Source No.", Campaign."No.");
        PriceListLine.DeleteAll();

        // [WHEN] Activate Campaign 'C' and answer 'No' on confirmation
        CampaignTargetGroupMgt.ActivateCampaign(Campaign);

        // [THEN] Campaign C is not activated (CampaignTargetGr don't exist)
        CampaignTargetGr.SetRange("Campaign No.", Campaign."No.");
        Assert.RecordIsEmpty(CampaignTargetGr);

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure T192_SalesLineChangeActivatedCampaignOnHeaderAsSource()
    var
        Campaign: array[2] of Record Campaign;
        PriceListLine: array[2] of Record "Price List Line";
        Contact: Record Contact;
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CampaignTargetGroupMgt: Codeunit "Campaign Target Group Mgt";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Campaign]
        // [SCENARIO 465382] When changing the Campaign No. in the header, the Unit Price must be updated on the previously added line

        Initialize();
        // [GIVEN] New Contact with Customer
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for selling all assets.
        //OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and activate segment campaigns 'C1' with lower price and 'C2' with higher price for Contact
        CreateSegmentCampaignsForContact(Campaign, Contact);
        // Activate campaign 'C1'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '', "Price Source Type"::Campaign, Campaign[1]."No.",
            "Price Asset Type"::Item, Item."No.");
        UnitPrice[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        PriceListLine[1].Validate("Unit Price", UnitPrice[1]);
        PriceListLine[1].Status := PriceListLine[1].Status::Active;
        PriceListLine[1].Modify();
        CampaignTargetGroupMgt.ActivateCampaign(Campaign[1]);

        // Activate campaign 'C2'
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[2], '', "Price Source Type"::Campaign, Campaign[2]."No.",
            "Price Asset Type"::Item, Item."No.");
        UnitPrice[2] := LibraryRandom.RandDecInRange(300, 400, 2);
        PriceListLine[2].Validate("Unit Price", UnitPrice[2]);
        PriceListLine[2].Status := PriceListLine[1].Status::Active;
        PriceListLine[2].Modify();
        CampaignTargetGroupMgt.ActivateCampaign(Campaign[2]);

        // [GIVEN] Order with campaign 'C1' for customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Campaign No.", Campaign[1]."No.");
        SalesHeader.Modify(true);
        // [GIVEN] with one line, where "Type" is 'Item', "No." is 'X'
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Validate("No.", Item."No.");
        SalesLine.Modify(true);

        // Exercise: Unit price from active campaign 'C1' must be applied on sales line
        Assert.AreEqual(UnitPrice[1], SalesLine."Unit Price", 'Wrong price for first campaign');

        // [WHEN] Switch campaign on sales order
        SalesHeader.Validate("Campaign No.", Campaign[2]."No.");

        // [THEN] Verify unit price is changed on sales order
        SalesLine.SetRecFilter();
        SalesLine.FindFirst();
        Assert.AreEqual(UnitPrice[2], SalesLine."Unit Price", 'Wrong price for second campaign');
        //LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T200_PostedArchivedSalesDocumentsContainPriceCalcMethod()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        CopiedSalesHeader: Record "Sales Header";
        CopiedSalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLineArchive: Record "Sales Line Archive";
        OldHandler: enum "Price Calculation Handler";
        InvoiceDocNo: Code[20];
        OrderNo: Code[20];
        LineNo: Integer;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Price Calculation Method during posting is populated to posted and archived documents and copied back.
        Initialize();
        SalesHeaderArchive.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'C'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'C'
        CreatePriceLine(PriceListLine, Customer, Item, false);
        // [GIVEN] Sales Order for Customer 'C' selling Item 'I'
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        // [GIVEN] Calculate price, by validating Quantity
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method"::"Lowest Price");
        SalesLine."Price Calculation Method" := SalesLine."Price Calculation Method"::"Test Price";
        SalesLine.Modify();
        // [GIVEN] Enable "Archive Orders"
        LibrarySales.SetArchiveOrders(true);

        // [WHEN] Post Sales Order
        OrderNo := SalesHeader."No.";
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Commit();

        // [THEN] Posted Sales Invoice, Method is 'Test' in line, 'Lowest Price' in header
        SalesInvoiceHeader.Get(InvoiceDocNo);
        SalesInvoiceHeader.TestField("Price Calculation Method", SalesHeader."Price Calculation Method");
        SalesInvoiceLine.SetRange("Document No.", InvoiceDocNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method");
        // [THEN] Posted Sales Shipment, Method is 'Test' in line, 'Lowest Price' in header
        SalesShipmentHeader.Get(FindShipmentHeaderNo(OrderNo));
        SalesShipmentHeader.TestField("Price Calculation Method", SalesShipmentHeader."Price Calculation Method");
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField("Price Calculation Method", SalesLine."Price Calculation Method");
        // [THEN] Sales Order Archive, Method is 'Test' in line, 'Lowest Price' in header
        SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::Order);
        SalesHeaderArchive.SetRange("No.", OrderNo);
        SalesHeaderArchive.FindLast();
        SalesHeaderArchive.TestField("Price Calculation Method", SalesHeaderArchive."Price Calculation Method");
        SalesLineArchive.SetRange("Document Type", SalesHeaderArchive."Document Type");
        SalesLineArchive.SetRange("Document No.", OrderNo);
        SalesLineArchive.FindFirst();
        SalesLineArchive.TestField("Price Calculation Method", SalesLine."Price Calculation Method");

        // [WHEN] Copy archived order as new order
        LibrarySales.CreateSalesHeader(CopiedSalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CopySalesDoc("Sales Document Type From"::"Arch. Order", OrderNo, CopiedSalesHeader);
        // [THEN] New Order, where Method is 'Test' in line, 'Lowest Price' in header
        CopiedSalesHeader.Find();
        CopiedSalesHeader.TestField("Price Calculation Method", SalesHeader."Price Calculation Method");
        CopiedSalesLine.SetRange("Document Type", CopiedSalesHeader."Document Type");
        CopiedSalesLine.SetRange("Document No.", CopiedSalesHeader."No.");
        CopiedSalesLine.FindLast();
        CopiedSalesLine.TestField("Price Calculation Method", SalesLineArchive."Price Calculation Method");
        LineNo := CopiedSalesLine."Line No.";

        // [WHEN] Copy line from invoice to order
        CopySalesLinesToDoc("Sales Document Type From"::"Posted Invoice", SalesInvoiceLine, CopiedSalesHeader);
        // [THEN] New line, where Method is 'Test' in line
        CopiedSalesLine.SetFilter("Line No.", '>%1', LineNo);
        CopiedSalesLine.FindLast();
        CopiedSalesLine.TestField("Price Calculation Method", SalesInvoiceLine."Price Calculation Method");
        LineNo := CopiedSalesLine."Line No.";

        // [WHEN] Copy line from shipment to order
        CopySalesLinesToDoc("Sales Document Type From"::"Posted Shipment", SalesShipmentLine, CopiedSalesHeader);
        // [THEN] New line, where Method is 'Test' in line
        CopiedSalesLine.SetFilter("Line No.", '>%1', LineNo);
        CopiedSalesLine.FindLast();
        CopiedSalesLine.TestField("Price Calculation Method", SalesShipmentLine."Price Calculation Method");

        LibraryNotificationMgt.RecallNotificationsForRecord(CopiedSalesHeader);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T202_PostedArchivedPurchDocumentsContainPriceCalcMethod()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        CopiedPurchaseHeader: Record "Purchase Header";
        CopiedPurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        PurchaseLineArchive: Record "Purchase Line Archive";
        OldHandler: enum "Price Calculation Handler";
        CrMemoDocNo: Code[20];
        OrderNo: Code[20];
        LineNo: Integer;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Price Calculation Method during posting is populated to posted and archived documents and copied back.
        Initialize();
        PurchaseHeaderArchive.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Vendor 'V'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Item 'I'
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Price List Line, where "Amount Type" is 'Price', "Source No." is 'V'
        CreatePriceLine(PriceListLine, Vendor, Item, false);
        // [GIVEN] Purchase Order for Vendor 'V' selling Item 'I'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Vendor."No.");
        // [GIVEN] Calculate price, by validating Quantity
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.TestField("Price Calculation Method", PurchaseLine."Price Calculation Method"::"Lowest Price");
        PurchaseLine."Price Calculation Method" := PurchaseLine."Price Calculation Method"::"Test Price";
        PurchaseLine.Modify();
        // [GIVEN] Enable "Archive Orders"
        LibraryPurchase.SetArchiveReturnOrders(true);

        // [WHEN] Post Purchase Order
        OrderNo := PurchaseHeader."No.";
        CrMemoDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Commit();

        // [THEN] Posted Purchase CrMemo, Method is 'Test' in line, 'Lowest Price' in header
        PurchCrMemoHeader.Get(CrMemoDocNo);
        PurchCrMemoHeader.TestField("Price Calculation Method", PurchaseHeader."Price Calculation Method");
        PurchCrMemoLine.SetRange("Document No.", CrMemoDocNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.TestField("Price Calculation Method", PurchaseLine."Price Calculation Method");
        // [THEN] Posted Return Shipment, Method is 'Test' in line, 'Lowest Price' in header
        ReturnShipmentHeader.Get(FindReturnShipmentHeaderNo(OrderNo));
        ReturnShipmentHeader.TestField("Price Calculation Method", ReturnShipmentHeader."Price Calculation Method");
        ReturnShipmentLine.SetRange("Document No.", ReturnShipmentHeader."No.");
        ReturnShipmentLine.FindFirst();
        ReturnShipmentLine.TestField("Price Calculation Method", PurchaseLine."Price Calculation Method");
        // [THEN] Purchase Order Archive, Method is 'Test' in line, 'Lowest Price' in header
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeaderArchive."Document Type"::"Return Order");
        PurchaseHeaderArchive.SetRange("No.", OrderNo);
        PurchaseHeaderArchive.FindLast();
        PurchaseHeaderArchive.TestField("Price Calculation Method", PurchaseHeaderArchive."Price Calculation Method");
        PurchaseLineArchive.SetRange("Document Type", PurchaseHeaderArchive."Document Type");
        PurchaseLineArchive.SetRange("Document No.", OrderNo);
        PurchaseLineArchive.FindFirst();
        PurchaseLineArchive.TestField("Price Calculation Method", PurchaseLine."Price Calculation Method");

        // [WHEN] Copy archived order as new order
        LibraryPurchase.CreatePurchHeader(CopiedPurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CopyPurchaseDoc("Purchase Document Type From"::"Arch. Return Order", OrderNo, CopiedPurchaseHeader);
        // [THEN] New Order, where Method is 'Test' in line, 'Lowest Price' in header
        CopiedPurchaseHeader.Find();
        CopiedPurchaseHeader.TestField("Price Calculation Method", PurchaseHeader."Price Calculation Method");
        CopiedPurchaseLine.SetRange("Document Type", CopiedPurchaseHeader."Document Type");
        CopiedPurchaseLine.SetRange("Document No.", CopiedPurchaseHeader."No.");
        CopiedPurchaseLine.FindLast();
        CopiedPurchaseLine.TestField("Price Calculation Method", PurchaseLineArchive."Price Calculation Method");
        LineNo := CopiedPurchaseLine."Line No.";

        // [WHEN] Copy line from credit memo to order
        CopyPurchLinesToDoc("Purchase Document Type From"::"Posted Credit Memo", PurchCrMemoLine, CopiedPurchaseHeader);
        // [THEN] New line, where Method is 'Test' in line
        CopiedPurchaseLine.SetFilter("Line No.", '>%1', LineNo);
        CopiedPurchaseLine.FindLast();
        CopiedPurchaseLine.TestField("Price Calculation Method", PurchCrMemoLine."Price Calculation Method");
        LineNo := CopiedPurchaseLine."Line No.";

        // [WHEN] Copy line from return shipment to order
        CopyPurchLinesToDoc("Purchase Document Type From"::"Posted Return Shipment", ReturnShipmentLine, CopiedPurchaseHeader);
        // [THEN] New line, where Method is 'Test' in line
        CopiedPurchaseLine.SetFilter("Line No.", '>%1', LineNo);
        CopiedPurchaseLine.FindLast();
        CopiedPurchaseLine.TestField("Price Calculation Method", ReturnShipmentLine."Price Calculation Method");

        LibraryNotificationMgt.RecallNotificationsForRecord(CopiedPurchaseHeader);
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T203_PostedServiceCrMemoContainsPriceCalcMethod()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Price Calculation Method during posting is populated to posted Service Credit Memo documents.
        Initialize();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Create Service Credit Memo - Service Header, one Service Line with Type as Resource, "Price Calculation Method" is 'Lowest Price'
        Initialize();
        CreateServiceDocumentWithResource(
            ServiceHeader, ServiceLine, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        ServiceLine.TestField("Price Calculation Method", ServiceLine."Price Calculation Method"::"Lowest Price");

        // [WHEN] Post Service Credit Memo
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3. Verify: Check that the posted Service Credit Memo Header has "Price Calculation Method" as 'Lowest Price'
        FindServiceCreditMemoHeader(ServiceCrMemoHeader, ServiceHeader."No.");
        ServiceCrMemoHeader.TestField("Price Calculation Method", ServiceCrMemoHeader."Price Calculation Method"::"Lowest Price");
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.FindFirst();
        ServiceCrMemoLine.TestField("Price Calculation Method", ServiceCrMemoLine."Price Calculation Method"::"Lowest Price");

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T204_PostedServiceInvoiceContainsPriceCalcMethod()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        OldHandler: enum "Price Calculation Handler";
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Price Calculation Method during posting is populated to posted Service Invoice/Shipment documents.
        Initialize();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Create Service Order - Service Header, one Service Line with Type as Resource, "Price Calculation Method" is 'Lowest Price'
        Initialize();
        CreateServiceOrderWithResource(ServiceHeader, ServiceLine, LibrarySales.CreateCustomerNo());
        ServiceLine.TestField("Price Calculation Method", ServiceLine."Price Calculation Method"::"Lowest Price");

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Posted Service Invoice Header has "Price Calculation Method" as 'Lowest Price'
        FindServiceInvoiceFromOrder(ServiceInvoiceHeader, ServiceHeader."No.");
        ServiceInvoiceHeader.TestField("Price Calculation Method", ServiceInvoiceHeader."Price Calculation Method"::"Lowest Price");
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField("Price Calculation Method", ServiceInvoiceLine."Price Calculation Method"::"Lowest Price");
        // [THEN] Posted Service Shipment Header has "Price Calculation Method" as 'Lowest Price'
        FindServiceShipmentHeader(ServiceShipmentHeader, ServiceHeader."No.");
        ServiceShipmentHeader.TestField("Price Calculation Method", ServiceShipmentHeader."Price Calculation Method"::"Lowest Price");
        ServiceShipmentLine.SetRange("Document No.", ServiceShipmentHeader."No.");
        ServiceShipmentLine.FindFirst();
        ServiceShipmentLine.TestField("Price Calculation Method", ServiceShipmentLine."Price Calculation Method"::"Lowest Price");

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T210_SalesLineMinQtyPriceForGLAccount()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [G/L Account] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price list line for G/L Account 'X', where "Minimum Quantity" is 10, "Unit Price" is 50
        GLAccount."No." := LibraryERM.CreateGLAccountWithSalesSetup();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::"G/L Account", GLAccount."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Unit Price" := 100 + LibraryRandom.RandDec(100, 2);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [GIVEN] Order for customer 'A' with one line with "Type" = 'G/L Account' and "No." = 'X', "Quantity" = 1
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::"G/L Account", GLAccount."No.", 1);
        // [GIVEN] Sales Line, where "Unit Price" is 0
        SalesLine.TestField("Unit Price", 0);

        // [WHEN] Change "Quantity" to 10
        SalesLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Sales Line, where "Unit Price" is 50 (from Price line)
        SalesLine.TestField("Unit Price", PriceListLine."Unit Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T211_ServiceLineMinQtyPriceForGLAccount()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        GLAccount: Record "G/L Account";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Service] [G/L Account] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Price list line for G/L Account 'X', where "Minimum Quantity" is 10, "Unit Price" is 50
        GLAccount."No." := LibraryERM.CreateGLAccountWithSalesSetup();
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::"G/L Account", GLAccount."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Unit Price" := 100 + LibraryRandom.RandDec(100, 2);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [GIVEN] Service Order for customer 'A' with one line with "Type" = 'G/L Account' and "No." = 'X', "Quantity" = 1
        LibraryService.CreateServiceHeader(ServiceHeader, "Sales Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, "Service Line Type"::"G/L Account", GLAccount."No.");
        // [GIVEN] Service Line, where "Unit Price" is 0
        ServiceLine.TestField("Unit Price", 0);

        // [WHEN] Change "Quantity" to 10
        ServiceLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Service Line, where "Unit Price" is 50 (from Price line)
        ServiceLine.TestField("Unit Price", PriceListLine."Unit Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T212_PurchaseLineMinQtyPriceForGLAccount()
    var
        PriceListLine: Record "Price List Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Purchase] [G/L Account] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Vendor 'V'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Price list line for G/L Account 'X', where "Minimum Quantity" is 10, "Unit Price" is 50
        GLAccount."No." := LibraryERM.CreateGLAccountWithSalesSetup();
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::"G/L Account", GLAccount."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Direct Unit Cost" := 100 + LibraryRandom.RandDec(100, 2);
        ;
        PriceListLine."Unit Cost" := PriceListLine."Direct Unit Cost" / 4;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
        // [GIVEN] Order for Vendor 'V', with one line, where "Type" is 'G/L Account', "No." is 'X'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        // [GIVEN] Purchase Line, where "Direct Unit Cost" is 0
        PurchaseLine.TestField("Direct Unit Cost", 0);

        // [WHEN] Change "Quantity" to 10
        PurchaseLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Purchase Line, where "Direct Unit Price" is 50 (from Price line)
        PurchaseLine.TestField("Direct Unit Cost", PriceListLine."Direct Unit Cost");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T230_SalesLineGetsCustomerSourcesForResource()
    var
        Campaign: array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempPriceSource: Record "Price Source" temporary;
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, false);
        // [GIVEN] Customer 'A', where "Customer Discount Group" is 'CDG', "Customer Price Group" is 'CPG'
        SetGroupsOnCustomer(Customer, CustomerDiscountGroup, CustomerPriceGroup);

        // [GIVEN] Invoice for customer 'A' with 'Campaign No.' = 'HdrCmp'.
        // [GIVEN] Invoice has one line with "Type" = 'Resource' and "No." = 'X'.
        CreateSalesInvoiceWithResource(SalesHeader, SalesLine, Customer."No.");
        SalesHeader.Validate("Campaign No.", Campaign[1]."No.");
        SalesHeader.Modify(true);

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources on the level 0 contains: All Customers, Customer 'A', 'CPG', 'CDG', Contact 'C', Campaign 'HdrCmp'
        GetSources(SalesLinePrice, TempPriceSource);
        VerifySaleResourceSources(TempPriceSource, Customer, Contact, 0);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Campaign);
        TempPriceSource.SetRange("Source No.", Campaign[1]."No.");
        Assert.RecordCount(TempPriceSource, 1);
        // [THEN] All Jobs is not in the list
        TempPriceSource.Reset();
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Jobs");
        Assert.IsTrue(TempPriceSource.IsEmpty(), 'Found All Jobs source in the list');
    end;

    [Test]
    procedure T231_SalesLineGetsCustomerSourcesForResourceWithJob()
    var
        Campaign: array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        Job: Record Job;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempPriceSource: Record "Price Source" temporary;
        SalesLinePrice: Codeunit "Sales Line - Price";
    begin
        // [FEATURE] [Sales] [Resource] [UT]
        Initialize();
        // [GIVEN] Job 'J'
        LibraryJob.CreateJob(Job);
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, false);
        // [GIVEN] Customer 'A', where "Customer Discount Group" is 'CDG', "Customer Price Group" is 'CPG'
        SetGroupsOnCustomer(Customer, CustomerDiscountGroup, CustomerPriceGroup);

        // [GIVEN] Invoice for customer 'A' with 'Campaign No.' = 'HdrCmp'.
        // [GIVEN] Invoice has one line with "Type" = 'Resource' and "No." = 'X'.
        CreateSalesInvoiceWithResource(SalesHeader, SalesLine, Customer."No.");
        SalesHeader.Validate("Campaign No.", Campaign[1]."No.");
        SalesHeader.Modify(true);
        // [GIVEN] "Job No." is 'J' in the line
        SalesLine.Validate("Job No.", Job."No.");
        SalesLine.Modify();

        // [WHEN] SetLine()
        SalesLinePrice.SetLine("Price Type"::Sale, SalesHeader, SalesLine);

        // [THEN] List of sources on the level 0 contains: All Customers, Customer 'A', 'CPG', 'CDG', Contact 'C', Campaign 'HdrCmp'
        GetSources(SalesLinePrice, TempPriceSource);
        VerifySaleResourceSources(TempPriceSource, Customer, Contact, 0);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Campaign);
        TempPriceSource.SetRange("Source No.", Campaign[1]."No.");
        Assert.RecordCount(TempPriceSource, 1);
        // [THEN] All Jobs is on the level 1, 'Job' on Level 2.
        TempPriceSource.Reset();
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Jobs");
        TempPriceSource.FindFirst();
        TempPriceSource.TestField(Level, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Job);
        TempPriceSource.SetRange("Source No.", Job."No.");
        TempPriceSource.FindFirst();
        TempPriceSource.TestField(Level, 2);
    end;

    [Test]
    procedure T232_SalesLineGetsCustomerPriceForResourceOverJobPrice()
    var
        Customer: Record Customer;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Invoice for customer 'A', where is one line with "Type" = 'Resource' and "No." = 'R', "Job No." is blank
        CreateSalesInvoiceWithResource(SalesHeader, SalesLine, Customer."No.");

        // [GIVEN] Sales Price line for 'R' assigned to 'All Customers', "Unit Price" is 100
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Resource, SalesLine."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] Sales Price line for 'R' assigned to 'All Jobs', "Unit Price" is 99
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Resource, SalesLine."No.");
        PriceListLine[2].Validate("Unit Price", PriceListLine[1]."Unit Price" - 1);
        PriceListLine[2].Status := "Price Status"::Active;
        PriceListLine[2].Modify();

        // [WHEN] Set Quantity to 1
        SalesLine.Validate(Quantity, 1);

        // [THEN] "Unit Price" is 100 (from All Customers price)
        SalesLine.TestField("Unit Price", PriceListLine[1]."Unit Price");
    end;

    [Test]
    procedure T233_SalesLineGetsResourceCardPriceIfNoAllCustomers()
    var
        Customer: Record Customer;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Invoice for customer 'A', where is one line with "Type" = 'Resource' and "No." = 'R', "Job No." is blank
        CreateSalesInvoiceWithResource(SalesHeader, SalesLine, Customer."No.");
        Resource.Get(SalesLine."No.");

        // [GIVEN] Sales Price line for 'R' assigned to 'All Jobs', "Unit Price" is 100
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Resource, SalesLine."No.");
        PriceListLine[2].Status := "Price Status"::Active;
        PriceListLine[2].Modify();

        // [WHEN] Set Quantity to 1
        SalesLine.Validate(Quantity, 1);

        // [THEN] "Unit Price" is 50 (from resource card)
        SalesLine.TestField("Unit Price", Resource."Unit Price");
    end;

    [Test]
    procedure T234_SalesLineGetsAllJobsPriceForResourceIfJobDefined()
    var
        Customer: Record Customer;
        Job: Record Job;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Job 'J'
        LibraryJob.CreateJob(Job);
        // [GIVEN] Invoice for customer 'A', where is one line with "Type" = 'Resource' and "No." = 'R', "Job No." is 'J'
        CreateSalesInvoiceWithResource(SalesHeader, SalesLine, Customer."No.");
        SalesLine.Validate("Job No.", Job."No.");
        SalesLine.Modify();

        // [GIVEN] Sales Price line for 'R' assigned to 'All Customers', "Unit Price" is 99
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Resource, SalesLine."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] Sales Price line for 'R' assigned to 'All Jobs', "Unit Price" is 100
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Resource, SalesLine."No.");
        PriceListLine[2].Validate("Unit Price", PriceListLine[1]."Unit Price" + 1);
        PriceListLine[2].Status := "Price Status"::Active;
        PriceListLine[2].Modify();

        // [WHEN] Set Quantity to 1
        SalesLine.Validate(Quantity, 1);

        // [THEN] "Unit Price" is 100 (from All Jobs price)
        SalesLine.TestField("Unit Price", PriceListLine[2]."Unit Price");
    end;

    [Test]
    procedure T235_SalesLineGetsAllCustomersPriceForResourceIfJobPrice()
    var
        Customer: Record Customer;
        Job: Record Job;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Job 'J'
        LibraryJob.CreateJob(Job);
        // [GIVEN] Invoice for customer 'A', where is one line with "Type" = 'Resource' and "No." = 'R', "Job No." is 'J'
        CreateSalesInvoiceWithResource(SalesHeader, SalesLine, Customer."No.");
        SalesLine.Validate("Job No.", Job."No.");
        SalesLine.Modify();

        // [GIVEN] Sales Price line for 'R' assigned to 'All Customers', "Unit Price" is 99
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Resource, SalesLine."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();

        // [WHEN] Set Quantity to 1
        SalesLine.Validate(Quantity, 1);

        // [THEN] "Unit Price" is 99 (from All Customers price)
        SalesLine.TestField("Unit Price", PriceListLine[1]."Unit Price");
    end;

    [Test]
    procedure T236_ServiceLineGetsCustomerSourcesForResource()
    var
        Campaign: array[5] of Record Campaign;
        Contact: Record Contact;
        Customer: Record Customer;
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TempPriceSource: Record "Price Source" temporary;
        ServiceLinePrice: Codeunit "Service Line - Price";
    begin
        // [FEATURE] [Service] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A' has one activated Campaign 'CustCmp', "Primary Contact No." is 'C'
        // [GIVEN] Contact 'C' has one activated Campaign 'ContCmp'
        CreateCustomerWithContactAndActivatedCampaigns(Customer, Contact, Campaign, false);
        // [GIVEN] Customer 'A', where "Customer Discount Group" is 'CDG', "Customer Price Group" is 'CPG'
        SetGroupsOnCustomer(Customer, CustomerDiscountGroup, CustomerPriceGroup);

        // [GIVEN] Invoice for customer 'A'.
        // [GIVEN] Invoice has one line with "Type" = 'Resource' and "No." = 'X'.
        CreateServiceDocumentWithResource(
            ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] SetLine(Sale)
        ServiceLinePrice.SetLine("Price Type"::Sale, ServiceHeader, ServiceLine);

        // [THEN] List of sources contains: All Customers, Customer 'A', 'CPG', 'CDG', Contact 'C', but no Campaign
        GetSources(ServiceLinePrice, TempPriceSource);
        VerifySaleResourceSources(TempPriceSource, Customer, Contact, 0);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Campaign);
        Assert.RecordIsEmpty(TempPriceSource);
        // [THEN] All Jobs is not in the list.
        TempPriceSource.Reset();
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Jobs");
        Assert.IsTrue(TempPriceSource.IsEmpty(), 'Found All Jobs source in the list for sales');

        // [WHEN] SetLine(Purchase)
        ServiceLinePrice.SetLine("Price Type"::Purchase, ServiceHeader, ServiceLine);
        // [THEN] List of sources at level 0 contains: All Vendors
        GetSources(ServiceLinePrice, TempPriceSource);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Vendors");
        TempPriceSource.SetRange(Level, 0);
        Assert.RecordIsNotEmpty(TempPriceSource);
        // [THEN] All Jobs is not in the list.
        TempPriceSource.Reset();
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Jobs");
        Assert.IsTrue(TempPriceSource.IsEmpty(), 'Found All Jobs source in the list for purch');
    end;

    [Test]
    procedure T237_ServiceLineGetsCustomerPriceForResourceOverJobPrice()
    var
        Customer: Record Customer;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Service Invoice for customer 'A', where is one line with "Type" = 'Resource' and "No." = 'R', "Job No." is blank
        CreateServiceDocumentWithResource(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Sales Price line for 'R' assigned to 'All Customers', "Unit Price" is 100
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Resource, ServiceLine."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] Sales Price line for 'R' assigned to 'All Jobs', "Unit Price" is 99
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Resource, ServiceLine."No.");
        PriceListLine[2].Validate("Unit Price", PriceListLine[1]."Unit Price" - 1);
        PriceListLine[2].Status := "Price Status"::Active;
        PriceListLine[2].Modify();

        // [WHEN] Set Quantity to 1
        ServiceLine.Validate(Quantity, 1);

        // [THEN] "Unit Price" is 100 (from All Customers price)
        ServiceLine.TestField("Unit Price", PriceListLine[1]."Unit Price");
    end;

    [Test]
    procedure T238_ServiceLineGetsPriceFromResourceCardIfNoAllCustomers()
    var
        Customer: Record Customer;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Invoice for customer 'A', where is one line with "Type" = 'Resource' and "No." = 'R', "Job No." is blank
        CreateServiceDocumentWithResource(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice, Customer."No.");
        Resource.Get(ServiceLine."No.");

        // [GIVEN] Service Price line for 'R' assigned to 'All Jobs', "Unit Price" is 100
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Resource, ServiceLine."No.");
        PriceListLine[2].Status := "Price Status"::Active;
        PriceListLine[2].Modify();

        // [WHEN] Set Quantity to 1
        ServiceLine.Validate(Quantity, 1);

        // [THEN] "Unit Price" is 50 (from resource card)
        ServiceLine.TestField("Unit Price", Resource."Unit Price");
    end;

    [Test]
    procedure T239_ServiceLineGetsAllJobsPriceForResourceIfJobDefined()
    var
        Customer: Record Customer;
        Job: Record Job;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Job 'J'
        LibraryJob.CreateJob(Job);
        Job.SetHideValidationDialog(true);
        Job.Validate("Bill-to Customer No.", Customer."No.");
        Job.Modify();
        // [GIVEN] Invoice for customer 'A', where is one line with "Type" = 'Resource' and "No." = 'R', "Job No." is 'J'
        CreateServiceDocumentWithResource(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceLine.Validate("Job No.", Job."No.");
        ServiceLine.Modify();

        // [GIVEN] Service Price line for 'R' assigned to 'All Customers', "Unit Price" is 99
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Resource, ServiceLine."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] Service Price line for 'R' assigned to 'All Jobs', "Unit Price" is 100
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Resource, ServiceLine."No.");
        PriceListLine[2].Validate("Unit Price", PriceListLine[1]."Unit Price" + 1);
        PriceListLine[2].Status := "Price Status"::Active;
        PriceListLine[2].Modify();

        // [WHEN] Set Quantity to 1
        ServiceLine.Validate(Quantity, 1);

        // [THEN] "Unit Price" is 100 (from All Jobs price)
        ServiceLine.TestField("Unit Price", PriceListLine[2]."Unit Price");
    end;

    [Test]
    procedure T240_ServiceLineGetsAllCustomersPriceForResourceIfJobPrice()
    var
        Customer: Record Customer;
        Job: Record Job;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service] [Resource] [UT]
        Initialize();
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Job 'J'
        LibraryJob.CreateJob(Job);
        Job.SetHideValidationDialog(true);
        Job.Validate("Bill-to Customer No.", Customer."No.");
        Job.Modify();
        // [GIVEN] Invoice for customer 'A', where is one line with "Type" = 'Resource' and "No." = 'R', "Job No." is 'J'
        CreateServiceDocumentWithResource(ServiceHeader, ServiceLine, ServiceHeader."Document Type"::Invoice, Customer."No.");
        ServiceLine.Validate("Job No.", Job."No.");
        ServiceLine.Modify();

        // [GIVEN] Service Price line for 'R' assigned to 'All Customers', "Unit Price" is 99
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Resource, ServiceLine."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();

        // [WHEN] Set Quantity to 1
        ServiceLine.Validate(Quantity, 1);

        // [THEN] "Unit Price" is 99 (from All Customers price)
        ServiceLine.TestField("Unit Price", PriceListLine[1]."Unit Price");
    end;

    [Test]
    procedure T241_PurchaseLineGetsVendorSourcesForResource()
    var
        Campaign: Record Campaign;
        Contact: Record Contact;
        Resource: Record Resource;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPriceSource: Record "Price Source" temporary;
        Vendor: Record Vendor;
        PurchaseLinePrice: Codeunit "Purchase Line - Price";
    begin
        // [FEATURE] [Purchase] [Resource] [UT]
        Initialize();
        // [GIVEN] Vendor 'V', where "Primary Contact No." is 'C'
        CreateVendorWithContactAndCampaign(Vendor, Contact, Campaign);

        // [GIVEN] Invoice for Vendor 'V', where 'Campaign No.' is 'HdrCmp'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Campaign No.", Campaign."No.");
        PurchaseHeader.Modify(true);
        // [GIVEN] with one line, where "Type" is 'Resource', "No." is 'X'
        LibraryResource.CreateResource(Resource, '');
        LibraryPurchase.CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader);
        PurchaseLine.Type := PurchaseLine.Type::Resource;
        PurchaseLine."No." := Resource."No.";
        PurchaseLine.Modify(true);

        // [WHEN] SetLine()
        PurchaseLinePrice.SetLine("Price Type"::Sale, PurchaseHeader, PurchaseLine);

        // [THEN] List of sources at the level 0 contains: All Vendors, Vendor 'V', Contact 'C', Campaign 'HdrCmp'
        GetSources(PurchaseLinePrice, TempPriceSource);
        VerifyPurchaseResourceSources(TempPriceSource, Vendor, Contact, 0);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Campaign);
        TempPriceSource.SetRange("Source No.", Campaign."No.");
        Assert.RecordCount(TempPriceSource, 1);
        // [THEN] All Jobs is not in the list.
        TempPriceSource.Reset();
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Jobs");
        Assert.IsTrue(TempPriceSource.IsEmpty(), 'Found All Jobs source in the list');
    end;

    [Test]
    procedure T242_PurchaseLineGetsPriceFromResourceCardIfNoAllVendors()
    var
        Vendor: Record Vendor;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Resource] [UT]
        Initialize();
        // [GIVEN] Vendor 'A'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Invoice for Vendor 'A', where is one line with "Type" = 'Resource' and "No." = 'R', "Job No." is blank
        CreatePurchaseInvoiceWithResource(PurchaseHeader, PurchaseLine, Vendor."No.");
        Resource.Get(PurchaseLine."No.");

        // [GIVEN] Purchase Price line for 'R' assigned to 'All Jobs', "Direct Unit Cost" is 100
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Sale, "Price Source Type"::"All Jobs", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Resource, PurchaseLine."No.");
        PriceListLine[2].Status := "Price Status"::Active;
        PriceListLine[2].Modify();

        // [WHEN] Set Quantity to 1
        PurchaseLine.Validate(Quantity, 1);

        // [THEN] "Direct Unit Cost" is 50 (from Resource card price)
        PurchaseLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost");
    end;

    [Test]
    procedure T243_PurchaseLineGetsAllJobsPriceForItemIfJobDefined()
    var
        Vendor: Record Vendor;
        Job: Record Job;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Resource] [UT]
        Initialize();
        // [GIVEN] Vendor 'A'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Job 'J'
        LibraryJob.CreateJob(Job);
        // [GIVEN] Invoice for Vendor 'A', where is one line with "Type" = 'Item' and "No." = 'I', "Job No." is 'J'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(),
            LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Modify();

        // [GIVEN] Purchase Price line for 'I' assigned to 'All Vendors', "Direct Unit Cost" is 99
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::Item, PurchaseLine."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] Purchase Price line for 'I' assigned to 'All Jobs', "Direct Unit Cost" is 100
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::"All Jobs", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[2], PriceListHeader[2], "Price Amount Type"::Price, "Price Asset Type"::Item, PurchaseLine."No.");
        PriceListLine[2].Validate("Direct Unit Cost", PriceListLine[1]."Direct Unit Cost" + 1);
        PriceListLine[2].Status := "Price Status"::Active;
        PriceListLine[2].Modify();

        // [WHEN] Set Quantity to 1
        PurchaseLine.Validate(Quantity, 1);

        // [THEN] "Direct Unit Cost" is 100 (from All Jobs price)
        PurchaseLine.TestField("Direct Unit Cost", PriceListLine[2]."Direct Unit Cost");
    end;

    [Test]
    procedure T244_PurchaseLineGetsAllVendorsPriceForGLAccountIfNoJobPrice()
    var
        Job: Record Job;
        Vendor: Record Vendor;
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Resource] [UT]
        Initialize();
        // [GIVEN] Vendor 'A'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Job 'J'
        LibraryJob.CreateJob(Job);
        // [GIVEN] Invoice for Vendor 'A', where is one line with "Type" = 'G/L Account' and "No." = 'A', "Job No." is 'J'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
            LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Modify();

        // [GIVEN] Purchase Price line for 'A' assigned to 'All Vendors', "Direct Unit Cost" is 99
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader[1], "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine[1], PriceListHeader[1], "Price Amount Type"::Price, "Price Asset Type"::"G/L Account", PurchaseLine."No.");
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();

        // [WHEN] Set Quantity to 1
        PurchaseLine.Validate(Quantity, 1);

        // [THEN] "Direct Unit Cost" is 99 (from All Vendors price)
        PurchaseLine.TestField("Direct Unit Cost", PriceListLine[1]."Direct Unit Cost");
    end;

    [Test]
    procedure T245_SalesLineMinQtyPriceForResource()
    var
        Customer: Record Customer;
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Sales] [Resource] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Resource 'X', where "Unit Price" is '100'
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");
        Resource."Unit Price" := 100 + LibraryRandom.RandDec(100, 2);
        Resource.Modify();
        // [GIVEN] Price list line for Resource 'X', where "Minimum Quantity" is 10, "Unit Price" is 50
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Unit Price" := Resource."Unit Price" / 2;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [GIVEN] Order for customer 'A' with one line with "Type" = 'Resource' and "No." = 'X', "Quantity" = 1
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Resource, Resource."No.", 1);
        // [GIVEN] Sales Line, where "Unit Price" is 100 (from Resource card)
        SalesLine.TestField("Unit Price", Resource."Unit Price");

        // [WHEN] Change "Quantity" to 10
        SalesLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Sales Line, where "Unit Price" is 50 (from Price line)
        SalesLine.TestField("Unit Price", PriceListLine."Unit Price");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T246_ServiceLineMinQtyPriceForResource()
    var
        Customer: Record Customer;
        PriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        OldHandler: Enum "Price Calculation Handler";
        MinQty: Decimal;
    begin
        // [FEATURE] [Service] [Resource] [UT]
        Initialize();
        PriceListLine[1].DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Customer 'A'
        LibrarySales.CreateCustomer(Customer);
        // [GIVEN] Resource 'X', where "Unit Price" is 100, "Unit Cost" is 33
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");
        Resource."Unit Price" := 100 + LibraryRandom.RandDec(100, 2);
        Resource."Unit Cost" := 100 - LibraryRandom.RandDec(100, 2);
        Resource.Modify();
        MinQty := 10 + LibraryRandom.RandInt(20);
        // [GIVEN] Sales Price list line for "All Customers" for Resource 'X', where "Minimum Quantity" is 10, "Unit Price" is 50
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine[1]."Minimum Quantity" := MinQty;
        PriceListLine[1]."Unit Price" := Resource."Unit Price" / 2;
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GIVEN] Purchase Price list line for "All Vendors" for Resource 'X', where "Minimum Quantity" is 10, "Unit Cost" is 11
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[2], '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine[2]."Minimum Quantity" := MinQty;
        PriceListLine[2]."Unit Cost" := Resource."Unit Cost" / 3;
        PriceListLine[2].Status := PriceListLine[2].Status::Active;
        PriceListLine[2].Modify();

        // [GIVEN] Service Order for customer 'A' with one line with "Type" = 'Resource' and "No." = 'X', "Quantity" = 1
        LibraryService.CreateServiceHeader(ServiceHeader, "Sales Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, "Service Line Type"::Resource, Resource."No.");
        // [GIVEN] Service Line, where "Unit Price" is 100 , "Unit Cost" is 33 (from Resource card)
        ServiceLine.TestField("Unit Price", Resource."Unit Price");
        ServiceLine.TestField("Unit Cost", Resource."Unit Cost");

        // [WHEN] Change "Quantity" to 10
        ServiceLine.Validate(Quantity, MinQty);

        // [THEN] Service Line, where "Unit Price" is 50, "Unit Cost (LCY)" is 11 (from Price lines)
        ServiceLine.TestField("Unit Price", PriceListLine[1]."Unit Price");
        ServiceLine.TestField("Unit Cost (LCY)", PriceListLine[2]."Unit Cost");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T247_PurchaseLineMinQtyPriceForResource()
    var
        PriceListLine: Record "Price List Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
        Vendor: Record Vendor;
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [FEATURE] [Purchase] [Resource] [UT]
        Initialize();
        PriceListLine.DeleteAll();
        // [GIVEN] Default price calculation is 'V16'
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Vendor 'V'
        LibraryPurchase.CreateVendor(Vendor);
        // [GIVEN] Resource 'X', where "Unit Cost" is '100'
        LibraryResource.CreateResource(Resource, Vendor."VAT Bus. Posting Group");
        Resource."Direct Unit Cost" := 100 + LibraryRandom.RandDec(100, 2);
        Resource.Modify();
        // [GIVEN] Price list line for Resource 'X', where "Minimum Quantity" is 10, "Direct Unit Price" is 50
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine."Minimum Quantity" := 10 + LibraryRandom.RandInt(20);
        PriceListLine."Direct Unit Cost" := Resource."Direct Unit Cost" / 2;
        PriceListLine."Unit Cost" := Resource."Direct Unit Cost" / 4;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
        // [GIVEN] Order for Vendor 'V', with one line, where "Type" is 'Resource', "No." is 'X'
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, Resource."No.", 1);
        // [GIVEN] Purchase Line, where "Direct Unit Cost" is 100 (from Resource card)
        PurchaseLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost");

        // [WHEN] Change "Quantity" to 10
        PurchaseLine.Validate(Quantity, PriceListLine."Minimum Quantity");

        // [THEN] Purchase Line, where "Direct Unit Price" is 50 (from Price line)
        PurchaseLine.TestField("Direct Unit Cost", PriceListLine."Direct Unit Cost");
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T250_ResourceCostNoPriceLine()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource card
        ResJournalLine.TestField("Unit Cost", Resource."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost");
    end;

    [Test]
    procedure T251_ResourceCostResPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::Resource, Resource."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T252_ResourceCostResGroupPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Group Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T253_ResourceCostResAllPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::Resource, '', WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource All Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T254_ResourceCostResAndResGroupPriceLines()
    var
        PriceListLine: array[2] of Record "Price List Line";
        WTPriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, Resource."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine[1]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine[1]."Direct Unit Cost");
    end;

    [Test]
    procedure T255_ResourceCostResAllAndResGroupPriceLines()
    var
        PriceListLine: array[2] of Record "Price List Line";
        WTPriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, '', WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Group Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine[2]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine[2]."Direct Unit Cost");
    end;

    [Test]
    procedure T256_ResourceCostResAndResGrAndResAllPriceLines()
    var
        PriceListLine: array[3] of Record "Price List Line";
        WTPriceListLine: array[3] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[3], "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, Resource."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[3], "Price Asset Type"::Resource, '', WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X', "Work Type Code" is 'WT'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);

        // [WHEN] Validate "Resource No." as 'X'
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line
        ResJournalLine.TestField("Unit Cost", PriceListLine[1]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", PriceListLine[1]."Direct Unit Cost");
    end;

    [Test]
    procedure T260_ResWorkTypeCostNoPriceLine()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource card
        ResJournalLine.TestField("Unit Cost", Resource."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost");
    end;

    [Test]
    procedure T261_ResWorkTypeCostResPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::Resource, Resource."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);


        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T262_ResWorkTypeCostResGroupPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Group Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T263_ResWorkTypeCostResAllPriceLine()
    var
        PriceListLine: Record "Price List Line";
        WTPriceListLine: Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine, "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine, "Price Asset Type"::Resource, '', WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource All Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine."Direct Unit Cost");
    end;

    [Test]
    procedure T264_ResWorkTypeCostResAndResGroupPriceLines()
    var
        PriceListLine: array[2] of Record "Price List Line";
        WTPriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, Resource."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine[1]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine[1]."Direct Unit Cost");
    end;

    [Test]
    procedure T265_ResWorkTypeCostResAllAndResGroupPriceLines()
    var
        PriceListLine: array[2] of Record "Price List Line";
        WTPriceListLine: array[2] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, '', WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Group Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine[2]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine[2]."Direct Unit Cost");
    end;

    [Test]
    procedure T266_ResWorkTypeCostResAndResGrAndResAllPriceLines()
    var
        PriceListLine: array[3] of Record "Price List Line";
        WTPriceListLine: array[3] of Record "Price List Line";
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResJournalLine: Record "Res. Journal Line";
        WorkType: Record "Work Type";
    begin
        Initialize();
        // [GIVEN] Price Calculation Setup, where "V16" is the default handler for purchasing all assets.
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Work Type 'WT'
        LibraryResource.CreateWorkType(WorkType);
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Direct Unit Cost" is 30, "Unit Cost" is 45
        CreateResourceWithGroup(Resource, ResourceGroup);

        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[1], "Price Asset Type"::Resource, Resource."No.", '');
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", '');
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is <blank>
        CreateResourcePurchPriceLine(PriceListLine[3], "Price Asset Type"::Resource, '', '');
        // [GIVEN] Resource Price Line, for Resource 'X', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[1], "Price Asset Type"::Resource, Resource."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource Group 'A', "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[2], "Price Asset Type"::"Resource Group", ResourceGroup."No.", WorkType.Code);
        // [GIVEN] Resource Price Line, for Resource <blank> (All), "Work Type Code" is 'WT'
        CreateResourcePurchPriceLine(WTPriceListLine[3], "Price Asset Type"::Resource, '', WorkType.Code);

        // [GIVEN] ResJournalLine, where "Entry Type" is 'Purchase', "Resource No." is 'X'
        ResJournalLine.Init();
        ResJournalLine.Validate("Entry Type", ResJournalLine."Entry Type"::Purchase);
        ResJournalLine.Validate("Resource No.", Resource."No.");

        // [WHEN] Validate "Work Type Code" as 'WT'
        ResJournalLine.Validate("Work Type Code", WorkType.Code);

        // [THEN] "Unit Cost", "Direct Unit Cost" is taken from the Resource Price Line with Work Type 'WT'
        ResJournalLine.TestField("Unit Cost", WTPriceListLine[1]."Unit Cost");
        ResJournalLine.TestField("Direct Unit Cost", WTPriceListLine[1]."Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ResPriceListReportHandler')]
    procedure T270_ResPriceListReport()
    var
        Resource: Record Resource;
        PriceListLine: Record "Price List Line";
        WorkType: array[2] of Record "Work Type";
        ResPriceList: Report "Res. Price List";
    begin
        // [SCENARIO] Test and verify "Res. Price List" Report.
        Initialize();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Create Resource, Work Type and Resource Price.
        CreateResource(Resource);
        LibraryResource.CreateWorkType(WorkType[1]);
        LibraryResource.CreateWorkType(WorkType[2]);
        CreateResourcePrice(PriceListLine, Resource."No.", WorkType[2].Code);

        // [WHEN] Run the "Res. Price List" Report.
        Commit();
        Clear(ResPriceList);
        Resource.SetRange("No.", Resource."No.");
        ResPriceList.SetTableView(Resource);
        ResPriceList.Run();

        // [THEN] Verify values on "Res. Price List" Report.
        VerifyResPriceList(PriceListLine, Resource."Unit Price");
    end;

    [Test]
    [HandlerFunctions('ResPriceListReportHandler')]
    procedure T271_ResPriceListWithCurrency()
    var
        Resource: Record Resource;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ValueVar: Variant;
        ActualUnitPrice: Decimal;
    begin
        // [SCENARIO] Test and verify "Res. Price List" Report with Currency.
        Initialize();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Create Resource, Currency and Currency Exchange Rate.
        CreateResource(Resource);
        LibraryERM.CreateCurrency(Currency);
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code);

        // [GIVEN] Calculation for Actual Unit Price is taken from Report.
        ActualUnitPrice :=
          Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              WorkDate(), Currency.Code, Resource."Unit Price",
              CurrencyExchangeRate.ExchangeRate(WorkDate(), Currency.Code)),
            Currency."Unit-Amount Rounding Precision");

        // [WHEN] Run the "Res. Price List" Report with Currency.
        RunResPriceListReport(Resource."No.", Currency.Code);

        // [THEN] Verify values on "Res. Price List" Report with Currency.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Resource', Resource."No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the resource no');

        LibraryReportDataset.FindCurrentRowValue('UnitPrice_Resource', ValueVar);
        Assert.AreNearlyEqual(
            ActualUnitPrice, ValueVar, Currency."Unit-Amount Rounding Precision", 'Resource."Unit Price"');
    end;

    [Test]
    [HandlerFunctions('ImplementStandardCostChangesHandler,MessageHandler')]
    procedure T280_ImplementResourceStandardCostChanges()
    var
        PriceListLine: Record "Price List Line";
        Resource: Record Resource;
        NewStdCost: Decimal;
    begin
        Initialize();
        // [GIVEN] Resource, where "Direct Unit Cost" is 100
        LibraryResource.CreateResource(Resource, '');

        // [GIVEN] Active purchase Price List Line for Resource, where "Source Type" is 'All Jobs'
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Jobs", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLine.Validate("Direct Unit Cost", Resource."Direct Unit Cost" + 1);
        PriceListLine.Validate("Unit Cost", Resource."Direct Unit Cost");
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();

        // [WHEN] Implement Standard Cost Change, where "New Standard Cost" is 111
        NewStdCost := Resource."Direct Unit Cost" + LibraryRandom.RandDec(100, 2);
        ImplementStandardCostChanges(Resource, Resource."Direct Unit Cost", NewStdCost);

        // [THEN] Price List line is updated: "Direct Unit Cost" is 100, "Unit Cost" is 111
        PriceListLine.Find();
        PriceListLine.TestField(Status, "Price Status"::Active);
        PriceListLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost");
        PriceListLine.TestField("Unit Cost", NewStdCost);
    end;

    [Test]
    procedure T290_InvtReceiptLineFindPrice()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        BaseUOM: Record "Unit of Measure";
        UOM: Record "Unit of Measure";
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        PriceListLine: array[3] of Record "Price List Line";
    begin
        Initialize();
        LibraryPriceCalculation.SetMethodInPurchSetup();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Item 'I', where "Base Unit of Measure" is 'PCS'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, Item."No.", UOM.Code, 5);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, Item."No.", BaseUOM.Code, 1);
        Item.Validate("Base Unit of Measure", ItemUnitofMeasure.Code);
        Item.Modify();
        // [GIVEN] Purchase Prices, where "All Vendors", Item 'I':
        // [GiVEN] UOM is 'PCS', "Minimal Quantity" is 0, "Direct Unit Cost" is 100
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[1], '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Item, Item."No.");
        PriceListLine[1].Validate("Unit of Measure Code", ItemUnitofMeasure.Code);
        PriceListLine[1]."Direct Unit Cost" := 100 + LibraryRandom.RandDec(100, 2);
        PriceListLine[1].Status := "Price Status"::Active;
        PriceListLine[1].Modify();
        // [GiVEN] UOM is 'PCS', "Minimum Quantity" is 100, "Direct Unit Cost" is 80
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[2], '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Item, Item."No.");
        PriceListLine[2].Validate("Unit of Measure Code", ItemUnitofMeasure.Code);
        PriceListLine[2]."Minimum Quantity" := 100;
        PriceListLine[2]."Direct Unit Cost" := Round(PriceListLine[1]."Direct Unit Cost" * 0.8, 0.01);
        PriceListLine[2].Status := "Price Status"::Active;
        PriceListLine[2].Modify();
        // [GiVEN] UOM is 'BOX', "Minimal Quantity" is 0, "Direct Unit Cost" is 75
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine[3], '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Item, Item."No.");
        PriceListLine[3].Validate("Unit of Measure Code", UOM.Code);
        PriceListLine[3]."Direct Unit Cost" := Round(PriceListLine[1]."Direct Unit Cost" * 0.75, 0.01);
        PriceListLine[3].Status := "Price Status"::Active;
        PriceListLine[3].Modify();

        // [WHEN] Inventory receipt document line, where 'Item No.' is 'I'
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentLine.Init();
        InvtDocumentLine."Line No." := 10000;
        InvtDocumentLine.Validate("Document Type", InvtDocumentLine."Document Type"::Receipt);
        InvtDocumentLine.Validate("Document No.", InvtDocumentHeader."No.");
        InvtDocumentLine.Validate("Item No.", Item."No.");
        InvtDocumentLine.Insert();
        // [THEN] Line, where "Unit Amount" is 100
        InvtDocumentLine.TestField("Unit Amount", PriceListLine[1]."Direct Unit Cost");

        // [WHEN] Set Quantity as 100 in the line
        InvtDocumentLine.Validate(Quantity, 100);
        // [THEN] Line, where "Unit Amount" is 80
        InvtDocumentLine.TestField("Unit Amount", PriceListLine[2]."Direct Unit Cost");

        // [WHEN] UOM is 'BOX' in the line
        InvtDocumentLine.Validate("Unit of Measure Code", UOM.Code);
        // [THEN] Line, where "Unit Amount" is 75
        InvtDocumentLine.TestField("Unit Amount", PriceListLine[3]."Direct Unit Cost");
    end;

    [Test]
    procedure T291_InvtReceiptLineUOMPriceBlankUOM()
    var
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        BaseUOM: Record "Unit of Measure";
        UOM: Record "Unit of Measure";
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        LibraryPriceCalculation.SetMethodInPurchSetup();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        // [GIVEN] Item 'I', where "Base Unit of Measure" is 'PCS', 'BOX' is 5 'PCS'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, Item."No.", UOM.Code, 5);
        LibraryInventory.CreateUnitOfMeasureCode(BaseUOM);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, Item."No.", BaseUOM.Code, 1);
        Item.Validate("Base Unit of Measure", ItemUnitofMeasure.Code);
        Item.Modify();
        // [GIVEN] Purchase Price, where "All Vendors", Item 'I', UOM is <blank>, "Minimal Quantity" is 0, "Direct Unit Cost" is 100
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Unit of Measure Code", '');
        PriceListLine."Direct Unit Cost" := 100 + LibraryRandom.RandDec(100, 2);
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify();

        // [GIVEN] Inventory receipt document line, where 'Item No.' is 'I'
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        InvtDocumentLine.Init();
        InvtDocumentLine."Line No." := 10000;
        InvtDocumentLine.Validate("Document Type", InvtDocumentLine."Document Type"::Receipt);
        InvtDocumentLine.Validate("Document No.", InvtDocumentHeader."No.");
        InvtDocumentLine.Validate("Item No.", Item."No.");
        InvtDocumentLine.Insert();

        // [WHEN] UOM is 'BOX' in the line
        InvtDocumentLine.Validate("Unit of Measure Code", UOM.Code);
        // [THEN] Line, where "Unit Amount" is 500
        InvtDocumentLine.TestField("Unit Amount", PriceListLine."Direct Unit Cost" * 5);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure RequisitionLineSetDirectUnitCostWhenIncludeVAT()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [Purchase Price List] [Price Include VAT] [Requisition Line]
        Initialize();

        // [GIVEN] Create a item with "Replenishment System" as 'Purchase'
        LibraryInventory.CreateItem(Item);
        if Item."Replenishment System" <> Item."Replenishment System"::Purchase then begin
            Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
            Item.Modify();
        end;
        Item.TestField("VAT Prod. Posting Group");

        // [GIVEN] Purchase Price List with Price Include VAT
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        PriceListHeader."Allow Updating Defaults" := true;
        PriceListHeader.Modify();
        LibraryPriceCalculation.CreatePriceListLine(PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");

        // [GIVEN] Set Price Include VAT in Price List Line
        PriceListLine.TestField("Direct Unit Cost");
        PriceListLine.Validate("Price Includes VAT", true);
        PriceListLine.Validate("VAT Bus. Posting Gr. (Price)", FindVatBusinessPostingGroupCode(Item));
        PriceListLine.Modify(true);

        // [GIVEN] Update Status to Active in Price List Header.
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);
        PriceListHeader.Modify(true);

        // [GIVEN] Requisition Line, where "Type" is 'Item'
        InitReqWorksheetLine(RequisitionLine);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);

        // [WHEN] Validate "No."
        RequisitionLine.Validate("No.", Item."No.");

        // [THEN] Direct Unit Cost is set
        RequisitionLine.TestField("Direct Unit Cost");
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure WhenTheCampaignNoInTheHeaderIsUpdatedCheckTheDirectUnitCostInThePurchaseLine()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Campaign: Record Campaign;
        PurchaseLine: Record "Purchase Line";
        PriceListLine: Record "Price List Line";
        PurchaseHeader: Record "Purchase Header";
        PriceListHeader: Record "Price List Header";
    begin
        // [SCENARIO 480343] Verify the direct unit cost in the line when changing the campaign number in the purchase order.
        Initialize();

        // [GIVEN] Create a vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a campaign and update the starting and ending date.
        LibraryMarketing.CreateCampaign(Campaign);
        Campaign.Validate("Starting Date", CalcDate('<-CM>', WorkDate()));
        Campaign.Validate("Ending Date", CalcDate('<CM>', WorkDate()));
        Campaign.Modify();

        // [GIVEN] Create a Price List Header with the Campaign.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader,
            "Price Type"::Purchase,
            "Price Source Type"::Campaign,
            Campaign."No.");

        // [GIVEN] Create a Price List Line with an Item.
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine,
            PriceListHeader,
            "Price Amount Type"::Price,
            "Price Asset Type"::Item,
            Item."No.");

        // [GIVEN] Update the Direct Unit Cost in Price List Line.
        PriceListLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        PriceListLine.Validate("Allow Invoice Disc.", false);
        PriceListLine.Validate("Allow Line Disc.", false);
        PriceListLine.Modify(true);

        // [GIVEN] Update Status to Active in Price List Header.
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);
        PriceListHeader.Modify(true);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Create a Purchase Line with an Item.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(10));

        // [WHEN] Update a Campaign No. in the Purchase Header.
        PurchaseHeader.Validate("Campaign No.", Campaign."No.");
        PurchaseHeader.Modify(true);

        // [VERIFY] Verify the direct unit cost in the line when changing the campaign number in the purchase order.
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        Assert.AreEqual(
            PriceListLine."Direct Unit Cost",
            PurchaseLine."Direct Unit Cost",
            StrSubstNo(
                ValueMustBeEqualErr,
                PurchaseLine.FieldCaption("Direct Unit Cost"),
                PriceListLine."Direct Unit Cost",
                PurchaseLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure S483393_CopyAllowInvoiceDiscInGetReceiptLines()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PriceListLine: Record "Price List Line";
        PriceListHeader: Record "Price List Header";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        // [SCENARIO 483393] Verify that manually set "Allow Invoice Disc." is carried over from Order to Invoice line with Get Receipt Lines.
        Initialize();

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Price List Header for All Vendors.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader,
            "Price Type"::Purchase,
            "Price Source Type"::"All Vendors",
            '');

        // [GIVEN] Create a Price List Line with an Item.
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine,
            PriceListHeader,
            "Price Amount Type"::Any,
            "Price Asset Type"::Item,
            Item."No.");

        // [GIVEN] Update the Direct Unit Cost in Price List Line with Allow Line Disc. = true and Allow Invoice Disc. = false.
        PriceListLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        PriceListLine.Validate("Allow Line Disc.", true);
        PriceListLine.Validate("Allow Invoice Disc.", false);
        PriceListLine.Modify(true);

        // [GIVEN] Update Status to Active in Price List Header.
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);
        PriceListHeader.Modify(true);

        // [GIVEN] Create a Purchase Order Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, Vendor."No.");

        // [GIVEN] Create a Purchase Order Line with an Item.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLineOrder,
            PurchaseHeaderOrder,
            PurchaseLineOrder.Type::Item,
            Item."No.",
            LibraryRandom.RandInt(10));

        // [GIVEN] Set Invoice Discount for Item line.
        PurchaseLineOrder.Validate("Allow Invoice Disc.", true);
        PurchaseLineOrder.Validate("Inv. Discount Amount", Round(PurchaseLineOrder."Line Amount" * LibraryRandom.RandDec(1, 2)));
        PurchaseLineOrder.Modify(true);

        // [GIVEN] Receive Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Create a Purchase Invoice Header.
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeaderInvoice,
            PurchaseHeaderInvoice."Document Type"::Invoice,
            PurchaseHeaderOrder."Buy-from Vendor No.");
        PurchaseHeaderInvoice.Validate("Vendor Invoice No.", PurchaseHeaderInvoice."No.");
        PurchaseHeaderInvoice.Modify(true);

        // [WHEN] Run "Get Receipt Lines" from new Purchase Invoice.
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchRcptHeader.SetRange("Order No.", PurchaseHeaderOrder."No.");
        if PurchRcptHeader.FindSet() then
            repeat
                PurchRcptLine.SetRange("Document No.", PurchRcptHeader."No.");
                PurchGetReceipt.CreateInvLines(PurchRcptLine);
            until PurchRcptHeader.Next() = 0;

        // [THEN] Verify that "Allow Invoce Disc." is copied from Purchase Order Line to Purchase Invoice Line.
        PurchaseLineInvoice.SetRange("Document No.", PurchaseHeaderInvoice."No.");
        PurchaseLineInvoice.FindFirst();
        Assert.AreEqual(
            true,
            PurchaseLineInvoice."Allow Invoice Disc.",
            PurchaseLineInvoice.FieldCaption("Allow Invoice Disc."));
    end;

    [Test]
    procedure S485957_SalesLineForResourceInForeignCurrency_UnitCost()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Customer: Record Customer;
        Resource: Record Resource;
        PriceListLineSales: Record "Price List Line";
        PriceListLinePurchase: Record "Price List Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OldHandler: Enum "Price Calculation Handler";
        UnitCostInFCY: Decimal;
    begin
        // [FEATURE] [Sales] [Resource] [UT]
        // [SCENARIO 485957 - 1] Sales line for Resource in foreign Currency - Given that there is Unit Cost defined in Resource Card, verify that Unit Cost is taken from Resource Card.
        // [SCENARIO 485957 - 2] Sales line for Resource in foreign Currency - Given that there is Unit Cost defined in Resource Card and higher in Purchase Price List in local Currency, verify that Unit Cost is taken from Purchase Price List.
        // [SCENARIO 485957 - 3] Sales line for Resource in foreign Currency - Given that there is Unit Cost defined in Resource Card and higher in Purchase Price List in local Currency and even higher in Purchase Price List in foreign Currency, verify that Unit Cost is taken from Purchase Price List in foreign Currency.

        Initialize();
        PriceListLineSales.DeleteAll();

        // [GIVEN] Default price calculation is 'V16'.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Currency and Currency Exchange Rate.
        LibraryERM.CreateCurrency(Currency);
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code);

        // [GIVEN] Customer 'A' with Currency.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);

        // [GIVEN] Resource 'X', where "Unit Price" is '100' in local Currency, "Unit Cost" is 33 in local Currency.
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");
        Resource.Validate("Unit Price", 100 + LibraryRandom.RandDec(100, 2));
        Resource.Validate("Unit Cost", 100 - LibraryRandom.RandDec(100, 2));
        Resource.Modify();

        // [GIVEN] Sales Price List line for "All Customers" for Resource 'X', "Unit Price" is 50 in foreign Currency.
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLineSales, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLineSales.Validate("Currency Code", Currency.Code);
        PriceListLineSales."Unit Price" := Resource."Unit Price" / 2;
        PriceListLineSales.Status := PriceListLineSales."Status"::Active;
        PriceListLineSales.Modify();

        // [GIVEN] Sales Order for customer 'A' in Currency.
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");

        // [WHEN - 1] One Sales Order line with "Type" = 'Resource' and "No." = 'X', "Quantity" = 1.
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine."Type"::Resource, Resource."No.", 1);

        // [THEN - 1] "Unit Cost (LCY)" = 33 (from Resource Card), "Unit Price" = 50 (from Sales Price List line).
        SalesLine.TestField("Unit Cost (LCY)", Round(Resource."Unit Cost", Currency."Unit-Amount Rounding Precision"));
        UnitCostInFCY := Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              WorkDate(), Currency.Code, Resource."Unit Cost",
              CurrencyExchangeRate.ExchangeRate(WorkDate(), Currency.Code)),
            Currency."Unit-Amount Rounding Precision");
        SalesLine.TestField("Unit Cost", UnitCostInFCY);
        SalesLine.TestField("Unit Price", PriceListLineSales."Unit Price");

        // [GIVEN] Purchase Price List line for "All Vendors" for Resource 'X', "Unit Cost" is 66 in local Currency.
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLinePurchase, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLinePurchase."Unit Cost" := Resource."Unit Cost" * 2;
        PriceListLinePurchase.Status := PriceListLinePurchase."Status"::Active;
        PriceListLinePurchase.Modify();

        // [WHEN - 2] One Sales Order line with "Type" = 'Resource' and "No." = 'X', "Quantity" = 1.
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine."Type"::Resource, Resource."No.", 1);

        // [THEN - 2] "Unit Cost (LCY)" = 66 (from Purchase Price List line), "Unit Price" = 50 (from Sales Price List line).
        SalesLine.TestField("Unit Cost (LCY)", Round(PriceListLinePurchase."Unit Cost", Currency."Unit-Amount Rounding Precision"));
        UnitCostInFCY := Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              WorkDate(), Currency.Code, PriceListLinePurchase."Unit Cost",
              CurrencyExchangeRate.ExchangeRate(WorkDate(), Currency.Code)),
            Currency."Unit-Amount Rounding Precision");
        SalesLine.TestField("Unit Cost", UnitCostInFCY);
        SalesLine.TestField("Unit Price", PriceListLineSales."Unit Price");

        // [GIVEN] Purchase Price List line for "All Vendors" for Resource 'X', "Unit Cost" is 99 local currency (but defined in foreign currency).
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLinePurchase, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLinePurchase.Validate("Currency Code", Currency.Code);
        UnitCostInFCY := Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              WorkDate(), Currency.Code, Resource."Unit Cost" * 3,
              CurrencyExchangeRate.ExchangeRate(WorkDate(), Currency.Code)),
            Currency."Unit-Amount Rounding Precision");
        PriceListLinePurchase."Unit Cost" := UnitCostInFCY;
        PriceListLinePurchase.Status := PriceListLinePurchase."Status"::Active;
        PriceListLinePurchase.Modify();

        // [WHEN - 3] One Sales Order line with "Type" = 'Resource' and "No." = 'X', "Quantity" = 1.
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine."Type"::Resource, Resource."No.", 1);

        // [THEN - 3] "Unit Cost (LCY)" = 99 (from Purchase Price List line in foreign Currency), "Unit Price" = 50 (from Sales Price List line).
        SalesLine.TestField("Unit Cost (LCY)", Resource."Unit Cost" * 3);
        SalesLine.TestField("Unit Cost", PriceListLinePurchase."Unit Cost");
        SalesLine.TestField("Unit Price", PriceListLineSales."Unit Price");

        // Cleanup
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure S485957_ServiceLineForResourceInForeignCurrency_UnitCost()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Customer: Record Customer;
        Resource: Record Resource;
        PriceListLineSales: Record "Price List Line";
        PriceListLinePurchase: Record "Price List Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        OldHandler: Enum "Price Calculation Handler";
        UnitCostInFCY: Decimal;
    begin
        // [FEATURE] [Service] [Resource] [UT]
        // [SCENARIO 485957 - 1] Service line for Resource in foreign Currency - Given that there is Unit Cost defined in Resource Card, verify that Unit Cost is taken from Resource Card.
        // [SCENARIO 485957 - 2] Service line for Resource in foreign Currency - Given that there is Unit Cost defined in Resource Card and higher in Purchase Price List in local Currency, verify that Unit Cost is taken from Purchase Price List.
        // [SCENARIO 485957 - 3] Service line for Resource in foreign Currency - Given that there is Unit Cost defined in Resource Card and higher in Purchase Price List in local Currency and even higher in Purchase Price List in foreign Currency, verify that Unit Cost is taken from Purchase Price List in foreign Currency.

        Initialize();
        PriceListLineSales.DeleteAll();

        // [GIVEN] Default price calculation is 'V16'.
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Currency and Currency Exchange Rate.
        LibraryERM.CreateCurrency(Currency);
        CreateCurrencyExchangeRate(CurrencyExchangeRate, Currency.Code);

        // [GIVEN] Customer 'A' with Currency.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);

        // [GIVEN] Resource 'X', where "Unit Price" is '100' in local Currency, "Unit Cost" is 33 in local Currency.
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");
        Resource.Validate("Unit Price", 100 + LibraryRandom.RandDec(100, 2));
        Resource.Validate("Unit Cost", 100 - LibraryRandom.RandDec(100, 2));
        Resource.Modify();

        // [GIVEN] Sales Price List line for "All Customers" for Resource 'X', "Unit Price" is 50 in foreign Currency.
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLineSales, '', "Price Source Type"::"All Customers", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLineSales.Validate("Currency Code", Currency.Code);
        PriceListLineSales."Unit Price" := Resource."Unit Price" / 2;
        PriceListLineSales.Status := PriceListLineSales."Status"::Active;
        PriceListLineSales.Modify();

        // [GIVEN] Sales Order for customer 'A' in Currency.
        LibraryService.CreateServiceHeader(ServiceHeader, "Sales Document Type"::Order, Customer."No.");

        // [WHEN - 1] One Sales Order line with "Type" = 'Resource' and "No." = 'X', "Quantity" = 1.
        Clear(ServiceLine);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine."Type"::Resource, Resource."No.");

        // [THEN - 1] "Unit Cost (LCY)" = 33 (from Resource Card), "Unit Price" = 50 (from Sales Price List line).
        ServiceLine.TestField("Unit Cost (LCY)", Round(Resource."Unit Cost", Currency."Unit-Amount Rounding Precision"));
        UnitCostInFCY := Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              WorkDate(), Currency.Code, Resource."Unit Cost",
              CurrencyExchangeRate.ExchangeRate(WorkDate(), Currency.Code)),
            Currency."Unit-Amount Rounding Precision");
        ServiceLine.TestField("Unit Cost", UnitCostInFCY);
        ServiceLine.TestField("Unit Price", PriceListLineSales."Unit Price");

        // [GIVEN] Purchase Price List line for "All Vendors" for Resource 'X', "Unit Cost" is 66 in local Currency.
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLinePurchase, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLinePurchase."Unit Cost" := Resource."Unit Cost" * 2;
        PriceListLinePurchase.Status := PriceListLinePurchase."Status"::Active;
        PriceListLinePurchase.Modify();

        // [WHEN - 2] One Sales Order line with "Type" = 'Resource' and "No." = 'X', "Quantity" = 1.
        Clear(ServiceLine);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine."Type"::Resource, Resource."No.");

        // [THEN - 2] "Unit Cost (LCY)" = 66 (from Purchase Price List line), "Unit Price" = 50 (from Sales Price List line).
        ServiceLine.TestField("Unit Cost (LCY)", Round(PriceListLinePurchase."Unit Cost", Currency."Unit-Amount Rounding Precision"));
        UnitCostInFCY := Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              WorkDate(), Currency.Code, PriceListLinePurchase."Unit Cost",
              CurrencyExchangeRate.ExchangeRate(WorkDate(), Currency.Code)),
            Currency."Unit-Amount Rounding Precision");
        ServiceLine.TestField("Unit Cost", UnitCostInFCY);
        ServiceLine.TestField("Unit Price", PriceListLineSales."Unit Price");

        // [GIVEN] Purchase Price List line for "All Vendors" for Resource 'X', "Unit Cost" is 99 local currency (but defined in foreign currency).
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLinePurchase, '', "Price Source Type"::"All Vendors", '', "Price Asset Type"::Resource, Resource."No.");
        PriceListLinePurchase.Validate("Currency Code", Currency.Code);
        UnitCostInFCY := Round(
            CurrencyExchangeRate.ExchangeAmtLCYToFCY(
              WorkDate(), Currency.Code, Resource."Unit Cost" * 3,
              CurrencyExchangeRate.ExchangeRate(WorkDate(), Currency.Code)),
            Currency."Unit-Amount Rounding Precision");
        PriceListLinePurchase."Unit Cost" := UnitCostInFCY;
        PriceListLinePurchase.Status := PriceListLinePurchase."Status"::Active;
        PriceListLinePurchase.Modify();

        // [WHEN - 3] One Sales Order line with "Type" = 'Resource' and "No." = 'X', "Quantity" = 1.
        Clear(ServiceLine);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine."Type"::Resource, Resource."No.");

        // [THEN - 3] "Unit Cost (LCY)" = 99 (from Purchase Price List line in foreign Currency), "Unit Price" = 50 (from Sales Price List line).
        ServiceLine.TestField("Unit Cost (LCY)", Resource."Unit Cost" * 3);
        ServiceLine.TestField("Unit Cost", PriceListLinePurchase."Unit Cost");
        ServiceLine.TestField("Unit Price", PriceListLineSales."Unit Price");

        // Cleanup
        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T292_PriceListLineForAllItemsNotAllowed()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [SCENARIO 506148] It is not possible to create price list with Product Type = Item without specifying item number.
        Initialize();
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        LibrarySales.CreateCustomer(Customer);
        Item."No." := '';
        Commit();

        asserterror CreatePriceLine(PriceListLine, Customer, Item, true);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(StrSubstNo(TestFieldErr, PriceListLine.FieldCaption("Asset No.")));

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    procedure T293_DiscountLineForAllItemsAllowed()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        OldHandler: Enum "Price Calculation Handler";
    begin
        // [SCENARIO 563145] It is possible to create discount line with Product Type = Item without specifying item number.
        Initialize();
        OldHandler := LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        LibrarySales.CreateCustomer(Customer);
        Item."No." := '';
        Commit();

        CreateDiscountLine(PriceListLine, Customer, Item);
        PriceListLine.TestField("Asset No.", '');

        LibraryPriceCalculation.SetupDefaultHandler(OldHandler);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure LineDiscPctInServLineForServCostIsEqualToLineDiscPctOfItsSalesPrice()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        ServiceCost: Record "Service Cost";
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        // [SCENARIO 574353] "Line Discount %" in Service Line of Service Cost is 
        // equal to "Line Discount %" of Sales Price Line of Service Cost.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Service Cost.
        CreateServiceCost(ServiceCost, Item);

        // [GIVEN] Create a Price Header.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader,
            PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers",
            '');

        // [GIVEN] Create Price List Line [1].
        PriceListLine[1].DeleteAll();
        CreatePriceListLineForItem(PriceListLine[1], PriceListHeader, Item);

        // [GIVEN] Validate "Allow Invoice Disc." in Price List Line [1].
        PriceListLine[1].Validate("Allow Invoice Disc.", false);
        PriceListLine[1].Modify(true);

        // [GIVEN] Create Price List Line [2].
        CreatePriceListLineForServiceCost(PriceListLine[2], PriceListHeader, ServiceCost);

        // [GIVEN] Validate "Allow Invoice Disc." in Price List Line [2].
        PriceListLine[2].Validate("Allow Invoice Disc.", true);
        PriceListLine[2].Modify(true);

        // [GIVEN] Validate "Status" in Price List Header.
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);
        PriceListHeader.Modify(true);

        // [GIVEN] Create a Customer and Validate " Allow Line Disc.".
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Line Disc.", true);
        Customer.Modify(true);

        // [GIVEN] Create a Service Item and Validate "Item No.".
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);

        // [GIVEN] Create a Service Header.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Create a Service Item Line.
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [WHEN] Create a Service Line.
        Clear(ServiceLine);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItemLine, ServiceCost);

        // [THEN] "Line Discount %" of Service Line is equal to "Line Discount %" of Price List Line [2].
        Assert.AreEqual(
            PriceListLine[2]."Line Discount %",
            ServiceLine."Line Discount %",
            StrSubstNo(
                LineDiscPctErr,
                PriceListLine[2]."Line Discount %",
                ServiceLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ServiceCostsModalPageHandler')]
    procedure ServCostsPageLookupIsShownInProdNoIfProdTypeIsServCostInSalesPriceLines()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        ServiceCost: Record "Service Cost";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO 579104] Service Costs page lookup is shown under "Product No." field 
        // of Sales Price List Lines if "Asset Type" is Service Cost.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Service Cost.
        CreateServiceCost(ServiceCost, Item);

        // [GIVEN] Create a Price Header.
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader,
            PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::"All Customers",
            '');

        // [GIVEN] Open Sales Price List page.
        SalesPriceList.OpenEdit();
        SalesPriceList.GoToRecord(PriceListHeader);

        // [WHEN] Set values in "Asset Type" and "Product No.".
        LibraryVariableStorage.Enqueue(Format(ServiceCost.Code));
        SalesPriceList.Lines."Asset Type".SetValue("Price Asset Type"::"Service Cost");
        SalesPriceList.Lines."Product No.".Lookup();

        // [THEN] "Product No." in Sales Price List Lines is 
        // equal to "Code" of Service Cost.
        SalesPriceList.Lines."Product No.".AssertEquals(ServiceCost.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandlerOK,GetPriceLineHandler')]
    procedure VerifySalesPriceInSalesLineWhenSalesPriceIsUpdatedViaGetPriceFunction()
    var
        Customer: Record Customer;
        Item: Record Item;
        PriceListHeader: array[2] of Record "Price List Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        UnitPrice: array[2] of Decimal;
        FirstDayOfYear, LastDayOfYear : Date;
    begin
        // [SCENARIO 580007] Confirm sales price in sales line when sales price is updated via GetPrice function.
        Initialize();

        // [GIVEN] Calculate the first and last day of the year.
        FirstDayOfYear := CalcDate('<-CY>', WorkDate());
        LastDayOfYear := CalcDate('<CY>', WorkDate());

        // [GIVEN] Create an Item and customer.
        CreateItemAndCustomer(Item, Customer);

        // [GIVEN] Create First Sales Price.
        UnitPrice[1] := CreatePriceListHeader(
            PriceListHeader[1], Customer."No.", Item."No.", FirstDayOfYear, LastDayOfYear);

        // [GIVEN] Create Second Sales Price.
        UnitPrice[2] := CreatePriceListHeader(
            PriceListHeader[2], Customer."No.", Item."No.",
            CalcDate('<6M>', FirstDayOfYear), LastDayOfYear);

        // [GIVEN] Set WorkDate.
        WorkDate := CalcDate('<5M>', FirstDayOfYear);

        // [GIVEN] Create a sales order.
        CreateSalesOrder(SalesHeader, Customer."No.", Item."No.");
        LibraryVariableStorage.Enqueue(PriceListHeader[2]."Starting Date");

        // [GIVEN] Open Sales Order page.
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);

        // [GIVEN] Change Posting Date and Order Date value.
        SalesOrder."Posting Date".SetValue(CalcDate('<2M>', WorkDate()));
        SalesOrder."Order Date".SetValue(CalcDate('<2M>', WorkDate()));

        // [WHEN] Get Prices Action was invoked.
        SalesOrder.SalesLines.GetPrices.Invoke();

        // [GIVEN] Find Updated Sales Line.
        FindSalesLine(SalesLine, SalesHeader."No.", Item."No.");

        // [THEN] No error occurred and the unit price is updating in the sales line from the sales price.
        Assert.AreEqual(
            UnitPrice[2], SalesLine."Unit Price",
            StrSubstNo(
                ValueMustBeEqualErr,
                SalesLine.FieldCaption("Unit Price"),
                UnitPrice[2],
                SalesLine.TableCaption()));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SalesPriceListViewColumnforFilterIsNotChangedOnClosePage()
    var
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPriceList: TestPage "Sales Price List";
    begin
        // [SCENARIO 592500] Sales Price List View Column for Filter Is Changed OnClosePage
        Initialize();

        // [GIVEN] Create Item and Sales Price List Header and Line
        LibraryInventory.CreateItem(Item);
        LibraryPriceCalculation.CreatePriceHeader(
                   PriceListHeader, "Price Type"::Sale, "Price Source Type"::"All Customers", '');

        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code, "Price Source Type"::"All Customers", '',
            "Price Asset Type"::Item, Item."No.");
        PriceListHeader.Status := PriceListHeader.Status::Active;
        PriceListHeader.Modify();

        // [GIVEN] Open "Sales Price List" page
        SalesPriceList.OpenEdit();
        SalesPriceList.Filter.SetFilter(Code, PriceListHeader.Code);

        // [WHEN] Change Amount Type in "Sales Price List" page
        SalesPriceList.AmountType.SetValue("Price Amount Type"::Price);
        SalesPriceList.Close();

        // [THEN] Check Amount Type Field value saved after chnge the value
    end;

    [Test]
    procedure JobsLinkedPurchaseOrderFullyReceivedIsIgnoredInPlanningWorksheet()
    var
        Item: Record Item;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Quantity: Decimal;
    begin
        // [SCENARIO 592371] Project Planning Line does not show Requisition Line when linked Purchase Order is fully received but not invoiced.
        Initialize();

        // [GIVEN] Create a Job and Job Task.
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create an item with "Reordering Policy" = "Lot-for-Lot"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        // [GIVEN] Store a random quantity.
        Quantity := LibraryRandom.RandIntInRange(1, 10);

        // [GIVEN] Create a job planning line with "Line Type" = "Budget", "Type" = "Item", linked to the Job Task and an Item.
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, Quantity);
        JobPlanningLine.Modify(true);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create a Purchase Line with the Item, linked to the Job, Job Task and Job Planning Line.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Job No.", Job."No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Planning Line No.", JobPlanningLine."Line No.");
        PurchaseLine.Modify(true);

        // [GIVEN] Validate Qty. to Receive = Quantity.
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity);
        PurchaseLine.Modify(true);

        // [GIVEN] Post the Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Calculate the plan for Requisition Worksheet.
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, WorkDate() - LibraryRandom.RandIntInRange(365, 365), WorkDate());

        // [THEN] Requisition Line for the Item should not be created.
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Price Calculation - V16");
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test Price Calculation - V16");
        LibraryERMCountryData.CreateVATData();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test Price Calculation - V16");
    end;

    local procedure AddPriceLine(var TempPriceListLine: Record "Price List Line" temporary; PriceType: Enum "Price Type"; CurrencyCode: code[10]; VarianCode: Code[10]; Price: Decimal)
    begin
        TempPriceListLine.Init();
        TempPriceListLine."Line No." += 10000;
        TempPriceListLine."Price Type" := PriceType;
        TempPriceListLine.Status := TempPriceListLine.Status::Active;
        TempPriceListLine."Currency Code" := CurrencyCode;
        TempPriceListLine."Variant Code" := VarianCode;
        TempPriceListLine."Unit Price" := Price;
        TempPriceListLine.Insert(true);
    end;

    local procedure FindVatBusinessPostingGroupCode(var Item: Record Item): Code[20]
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VatPostingSetup: Record "VAT Posting Setup";
    begin
        if Item."VAT Bus. Posting Gr. (Price)" <> '' then
            exit(Item."VAT Bus. Posting Gr. (Price)");

        VATBusinessPostingGroup.SetFilter(Code, '<>%1', '');
        if VATBusinessPostingGroup.FindSet() then
            repeat
                if VatPostingSetup.Get(VATBusinessPostingGroup.Code, Item."VAT Prod. Posting Group") then
                    exit(VATBusinessPostingGroup.Code);
            until VATBusinessPostingGroup.Next() = 0;

        exit('');
    end;

    local procedure InitReqWorksheetLine(var RequisitionLine: Record "Requisition Line")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, RequisitionWkshName."Template Type"::"Req.");
        ReqWkshTemplate.FindFirst();
        RequisitionWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
        if not RequisitionWkshName.FindFirst() then begin
            LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
            Commit();
        end;

        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", RequisitionWkshName.Name);
    end;

    local procedure CopyPurchLinesToDoc(PurchDocType: Enum "Purchase Document Type From"; DocumentLine: Variant; var ToPurchaseHeader: Record "Purchase Header")
    var
        FromReturnShipmentLine: Record "Return Shipment Line";
        FromPurchInvLine: Record "Purch. Inv. Line";
        FromPurchCrMemoLine: Record "Purch. Cr. Memo Line";
        FromPurchRcptLine: Record "Purch. Rcpt. Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        case PurchDocType of
            "Purchase Document Type From"::"Posted Invoice":
                begin
                    FromPurchInvLine := DocumentLine;
                    FromPurchInvLine.SetRecFilter();
                end;
            "Purchase Document Type From"::"Posted Return Shipment":
                begin
                    FromReturnShipmentLine := DocumentLine;
                    FromReturnShipmentLine.SetRecFilter();
                end;
            "Purchase Document Type From"::"Posted Credit Memo":
                begin
                    FromPurchCrMemoLine := DocumentLine;
                    FromPurchCrMemoLine.SetRecFilter();
                end;
            "Purchase Document Type From"::"Posted Receipt":
                begin
                    FromPurchRcptLine := DocumentLine;
                    FromPurchRcptLine.SetRecFilter();
                end;
            else
                Error('Not supported Purchase doc type');
        end;
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.CopyPurchaseLinesToDoc(
            PurchDocType.AsInteger(), ToPurchaseHeader,
            FromPurchRcptLine, FromPurchInvLine, FromReturnShipmentLine, FromPurchCrMemoLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopyPurchaseDoc(PurchDocType: Enum "Purchase Document Type From"; FromDocNo: Code[20]; var ToPurchaseHeader: Record "Purchase Header")
    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.SetArchDocVal(1, 1);
        CopyDocMgt.CopyPurchDoc(PurchDocType, FromDocNo, ToPurchaseHeader);
    end;

    local procedure CopySalesLinesToDoc(SalesDocType: Enum "Sales Document Type From"; DocumentLine: Variant; var ToSalesHeader: Record "Sales Header")
    var
        FromSalesShptLine: Record "Sales Shipment Line";
        FromSalesInvLine: Record "Sales Invoice Line";
        FromSalesCrMemoLine: Record "Sales Cr.Memo Line";
        FromReturnRcptLine: Record "Return Receipt Line";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        LinesNotCopied: Integer;
        MissingExCostRevLink: Boolean;
    begin
        case SalesDocType of
            "Sales Document Type From"::"Posted Shipment":
                begin
                    FromSalesShptLine := DocumentLine;
                    FromSalesShptLine.SetRecFilter();
                end;
            "Sales Document Type From"::"Posted Invoice":
                begin
                    FromSalesInvLine := DocumentLine;
                    FromSalesInvLine.SetRecFilter();
                end;
            "Sales Document Type From"::"Posted Return Receipt":
                begin
                    FromReturnRcptLine := DocumentLine;
                    FromReturnRcptLine.SetRecFilter();
                end;
            "Sales Document Type From"::"Posted Credit Memo":
                begin
                    FromSalesCrMemoLine := DocumentLine;
                    FromSalesCrMemoLine.SetRecFilter();
                end;
            else
                Error('Not supported sales doc type');
        end;
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.CopySalesLinesToDoc(
            SalesDocType.AsInteger(), ToSalesHeader,
            FromSalesShptLine, FromSalesInvLine, FromReturnRcptLine, FromSalesCrMemoLine, LinesNotCopied, MissingExCostRevLink);
    end;

    local procedure CopySalesDoc(SalesDocType: Enum "Sales Document Type From"; FromDocNo: Code[20]; var ToSalesHeader: Record "Sales Header")
    var
        CopyDocMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocMgt.SetProperties(false, false, false, false, true, true, true);
        CopyDocMgt.SetArchDocVal(1, 1);
        CopyDocMgt.CopySalesDoc(SalesDocType, FromDocNo, ToSalesHeader);
    end;

    local procedure CreateCustomerAllowingLineDisc(var Customer: Record Customer; AllowLineDisc: Boolean)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Allow Line Disc." := AllowLineDisc;
        Customer.Modify();
    end;

    local procedure CreateCustomerItemDiscount(var PriceListLine: Record "Price List Line"; SourceType: Enum "Price Source Type"; CustomerCode: Code[20]; Item: Record Item; Discount: Decimal)
    begin
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, '', SourceType, CustomerCode, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Starting Date", WorkDate());
        PriceListLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PriceListLine.Validate("Line Discount %", Discount);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify(true);
    end;

    local procedure CreateCustomerItemPrice(var PriceListLine: Record "Price List Line"; SourceType: Enum "Price Source Type"; CustomerCode: Code[20]; Item: Record Item; Price: Decimal)
    begin
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, '', SourceType, CustomerCode, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Starting Date", WorkDate());
        PriceListLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PriceListLine.Validate("Unit Price", Price);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify(true);
    end;

    local procedure CreateCustomerItemDiscount(var SalesLineDiscount: Record "Sales Line Discount"; CustomerCode: Code[20]; Item: Record Item; Discount: Decimal)
    begin
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::Customer, CustomerCode,
            WorkDate(), '', '', Item."Base Unit of Measure", 0);
        SalesLineDiscount.Validate("Line Discount %", Discount);
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateDiscountLine(var PriceListLine: Record "Price List Line"; Customer: Record Customer; Item: Record Item)
    begin
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine, PriceListLine."Price List Code",
            "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;

    local procedure CreateCustomerWithContactAndActivatedCampaigns(var Customer: Record Customer; var Contact: Record Contact; var Campaign: array[5] of Record Campaign; SkipCustomerCampaign: Boolean)
    var
        CampaignTargetGr: Record "Campaign Target Group";
        i: Integer;
    begin
        LibraryMarketing.CreateCampaign(Campaign[1]);

        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        if not SkipCustomerCampaign then begin

            CampaignTargetGr.Init();
            CampaignTargetGr.Type := CampaignTargetGr.Type::Customer;
            CampaignTargetGr."No." := Customer."No.";
            for i := 2 to 3 do begin
                LibraryMarketing.CreateCampaign(Campaign[i]);
                CampaignTargetGr."Campaign No." := Campaign[i]."No.";
                CampaignTargetGr.Insert();
            end;
        end;

        CampaignTargetGr.Init();
        CampaignTargetGr.Type := CampaignTargetGr.Type::Contact;
        CampaignTargetGr."No." := Contact."No.";
        for i := 4 to 5 do begin
            LibraryMarketing.CreateCampaign(Campaign[i]);
            CampaignTargetGr."Campaign No." := Campaign[i]."No.";
            CampaignTargetGr.Insert();
        end;
    end;

    local procedure CreateVendorWithContactAndCampaign(var Vendor: Record Vendor; var Contact: Record Contact; var Campaign: Record Campaign)
    begin
        LibraryMarketing.CreateCampaign(Campaign);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryMarketing.CreateCompanyContact(Contact);
        Vendor."Primary Contact No." := Contact."No.";
        Vendor.Modify();
    end;

    local procedure CreatePriceLine(var PriceListLine: Record "Price List Line"; Customer: Record Customer; Item: Record Item; AllowLineDisc: Boolean)
    begin
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListLine."Price List Code",
            "Price Source Type"::Customer, Customer."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Allow Line Disc." := AllowLineDisc;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;

    local procedure CreatePriceLine(var PriceListLine: Record "Price List Line"; Vendor: Record Vendor; Item: Record Item; AllowLineDisc: Boolean)
    begin
        LibraryPriceCalculation.CreatePurchPriceLine(
            PriceListLine, PriceListLine."Price List Code",
            "Price Source Type"::Vendor, Vendor."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine."Allow Line Disc." := AllowLineDisc;
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;

    local procedure CreateDiscountLine(var PriceListLine: Record "Price List Line"; Vendor: Record Vendor; Item: Record Item)
    begin
        LibraryPriceCalculation.CreatePurchDiscountLine(
            PriceListLine, PriceListLine."Price List Code",
            "Price Source Type"::Vendor, Vendor."No.", "Price Asset Type"::Item, Item."No.");
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;

    local procedure CreateCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10])
    begin
        // Create Currency Exchange Rate with Exchange Rate Amount, Relational Exch. Rate Amount as Random values.
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(10, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exch. Rate Amount is always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount",
          LibraryRandom.RandDec(10, 2) + CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateResource(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        Resource: Record Resource;
    begin
        LibraryResource.CreateResource(Resource, VATBusPostingGroup);
        Resource.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure CreateResourcePrice(var PriceListLine: Record "Price List Line"; ResourceNo: Code[20]; WorkTypeCode: Code[10])
    var
        PriceListHeader: Record "Price List Header";
    begin
        PriceListHeader."Price Type" := "Price Type"::Sale;
        PriceListHeader."Source Type" := "Price Source Type"::"All Customers";
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Resource, ResourceNo);
        PriceListLine.Validate("Work Type Code", WorkTypeCode);
        PriceListLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify(true);
    end;

    local procedure CreateResourceWithGroup(var Resource: Record Resource; var ResourceGroup: Record "Resource Group")
    begin
        LibraryResource.CreateResourceGroup(ResourceGroup);
        LibraryResource.CreateResource(Resource, '');
        Resource."Direct Unit Cost" := LibraryRandom.RandDec(100, 2);
        Resource."Unit Cost" := Round(Resource."Unit Cost" * 1.5);
        Resource."Resource Group No." := ResourceGroup."No.";
        Resource.Modify();
    end;

    local procedure CreateResourcePurchPriceLine(var PriceListLine: Record "Price List Line"; AssetType: Enum "Price Asset Type"; AssetNo: Code[20]; WorkTypeCode: Code[10])
    begin
        LibraryPriceCalculation.CreatePurchPriceLine(PriceListLine, '', "Price Source Type"::"All Vendors", '', AssetType, AssetNo);
        PriceListLine."Work Type Code" := WorkTypeCode;
        PriceListLine."Direct Unit Cost" := LibraryRandom.RandDec(100, 2);
        PriceListLine."Unit Cost" := Round(PriceListLine."Direct Unit Cost" * 1.3);
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();
    end;

    local procedure CreatePurchaseInvoiceWithResource(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ResourceNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(5, 10, 2));
        ResourceNo := CreateResource(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdateVATBusPostingGroupOnVendor(VendorNo, VATPostingSetup."VAT Bus. Posting Group");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, ResourceNo, LibraryRandom.RandDecInRange(10, 20, 2));
    end;

    local procedure CreateSalesInvoiceWithResource(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ResourceNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(5, 10, 2));
        ResourceNo := CreateResource(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdateVATBusPostingGroupOnCustomer(CustomerNo, VATPostingSetup."VAT Bus. Posting Group");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, ResourceNo, LibraryRandom.RandDecInRange(10, 20, 2));
    end;

    local procedure CreateServiceDocumentWithResource(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ServiceDocType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerPostingGroup: Record "Customer Posting Group";
        ResourceNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(5, 10, 2));
        ResourceNo := CreateResource(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdateVATBusPostingGroupOnCustomer(CustomerNo, VATPostingSetup."VAT Bus. Posting Group");

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceDocType, CustomerNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
        ServiceLine.Modify(true);

        CustomerPostingGroup.Get(ServiceHeader."Customer Posting Group");
        UpdateVATProdPostingGroupOnInvRoundingAccount(CustomerPostingGroup.GetInvRoundingAccount(), VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateServiceOrderWithResource(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; CustomerNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        ResourceNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(5, 10, 2));
        ResourceNo := CreateResource(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdateVATBusPostingGroupOnCustomer(CustomerNo, VATPostingSetup."VAT Bus. Posting Group");

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, ResourceNo);
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDecInRange(10, 20, 2));
        ServiceLine.Modify(true);

        CustomerPostingGroup.Get(ServiceHeader."Customer Posting Group");
        UpdateVATProdPostingGroupOnInvRoundingAccount(CustomerPostingGroup.GetInvRoundingAccount(), VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateResource(var Resource: Record Resource)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryResource.CreateResource(Resource, VATPostingSetup."VAT Bus. Posting Group");

        // Use Random because value is not important.
        Resource.Validate(Capacity, LibraryRandom.RandDec(10, 2));
        Resource.Modify(true);
    end;

    local procedure CreateRevChargeVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"; var RevChVATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        RevChVATPostingSetup := VATPostingSetup;
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        RevChVATPostingSetup."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
        RevChVATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT";
        RevChVATPostingSetup."VAT %" += 5;
        RevChVATPostingSetup.Insert();
    end;

    local procedure FindReturnShipmentHeaderNo(OrderNo: Code[20]): Code[20]
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        ReturnShipmentHeader.SetRange("Return Order No.", OrderNo);
        ReturnShipmentHeader.FindFirst();
        exit(ReturnShipmentHeader."No.");
    end;

    local procedure FindServiceCreditMemoHeader(var ServiceCrMemoHeader: Record "Service Cr.Memo Header"; PreAssignedNo: Code[20])
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure FindServiceInvoiceFromOrder(var ServiceInvoiceHeader: Record "Service Invoice Header"; OrderNo: Code[20])
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure FindServiceShipmentHeader(var ServiceShipmentHeader: Record "Service Shipment Header"; OrderNo: Code[20])
    begin
        ServiceShipmentHeader.SetRange("Order No.", OrderNo);
        ServiceShipmentHeader.FindFirst();
    end;

    local procedure FindShipmentHeaderNo(OrderNo: Code[20]): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure RemovePricesForItem(Item: Record Item)
    var
        PriceListLine: Record "Price List Line";
    begin
        PriceListLine.SetRange("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.SetRange("Asset No.", Item."No.");
        PriceListLine.DeleteAll();
    end;

    local procedure SetGroupsOnCustomer(var Customer: Record Customer; var CustomerDiscountGroup: Record "Customer Discount Group"; var CustomerPriceGroup: Record "Customer Price Group")
    begin
        LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        Customer."Customer Disc. Group" := CustomerDiscountGroup.Code;
        Customer."Customer Price Group" := CustomerPriceGroup.Code;
        Customer.Modify();
    end;

    local procedure MockBuffer(PriceType: enum "Price Type"; CurrencyCode: Code[10]; CurrencyFactor: Decimal; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.")
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        DummyPriceSourceList: Codeunit "Price Source List";
    begin
        PriceCalculationBuffer.Init();
        PriceCalculationBuffer."Price Type" := PriceType;
        PriceCalculationBuffer."Qty. per Unit of Measure" := 1;
        PriceCalculationBuffer.Quantity := 1;
        PriceCalculationBuffer."Currency Code" := CurrencyCode;
        PriceCalculationBuffer."Currency Factor" := CurrencyFactor;
        PriceCalculationBufferMgt.Set(PriceCalculationBuffer, DummyPriceSourceList);
    end;

    local procedure GetSources(PurchaseLinePrice: Codeunit "Purchase Line - Price"; var TempPriceSource: Record "Price Source" temporary): Boolean;
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
    begin
        PurchaseLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        exit(PriceCalculationBufferMgt.GetSources(TempPriceSource));
    end;

    local procedure GetSources(SalesLinePrice: Codeunit "Sales Line - Price"; var TempPriceSource: Record "Price Source" temporary): Boolean;
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
    begin
        SalesLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        exit(PriceCalculationBufferMgt.GetSources(TempPriceSource));
    end;

    local procedure GetSources(ServiceLinePrice: Codeunit "Service Line - Price"; var TempPriceSource: Record "Price Source" temporary): Boolean;
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
    begin
        ServiceLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        exit(PriceCalculationBufferMgt.GetSources(TempPriceSource));
    end;

    local procedure RunResPriceListReport(No: Code[20]; CurrencyCode: Code[10])
    var
        Resource: Record Resource;
        ResPriceList: Report "Res. Price List";
    begin
        Commit();
        Clear(ResPriceList);
        Resource.SetRange("No.", No);
        ResPriceList.SetTableView(Resource);
        ResPriceList.InitializeRequest(WorkDate(), "Job Price Source Type"::"All Jobs", '', CurrencyCode);
        ResPriceList.Run();
    end;

    local procedure UpdateVATBusPostingGroupOnVendor(VendorNo: Code[20]; VATBusPostingGroup: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
    end;

    local procedure UpdateVATBusPostingGroupOnCustomer(CustomerNo: Code[20]; VATBusPostingGroup: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
    end;

    local procedure UpdateVATProdPostingGroupOnInvRoundingAccount(InvRoundingAccountCode: Code[20]; VATProdPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(InvRoundingAccountCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure VerifyCampaignSource(SalesLinePrice: Codeunit "Sales Line - Price"; CampaignNo: code[20]; ExpectedCount: Integer)
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
        TempPriceSource: Record "Price Source" temporary;
    begin
        SalesLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        PriceCalculationBufferMgt.GetSources(TempPriceSource);
        TempPriceSource.SetRange("Source Type", TempPriceSource."Source Type"::Campaign);
        Assert.RecordCount(TempPriceSource, ExpectedCount);
        TempPriceSource.SetRange("Source No.", CampaignNo);
        TempPriceSource.FindFirst();
    end;

    local procedure VerifyLineDiscount(var SalesLine: Record "Sales Line"; LineDisc: Decimal)
    begin
        SalesLine.TestField("Line Discount %", LineDisc);
        SalesLine.TestField("Allow Line Disc.", LineDisc > 0);
    end;

    local procedure VerifyPurchaseResourceSources(var TempPriceSource: Record "Price Source" temporary; Vendor: Record Vendor; Contact: Record Contact; ExpectedLevel: Integer)
    begin
        TempPriceSource.SetRange(Level, ExpectedLevel);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Vendors");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Vendor);
        TempPriceSource.SetRange("Source No.", Vendor."No.");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Contact);
        TempPriceSource.SetRange("Source No.", Contact."No.");
        Assert.RecordCount(TempPriceSource, 1);
    end;

    local procedure VerifySaleResourceSources(var TempPriceSource: Record "Price Source" temporary; Customer: Record Customer; Contact: Record Contact; ExpectedLevel: Integer)
    begin
        TempPriceSource.SetRange(Level, ExpectedLevel);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"All Customers");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Customer);
        TempPriceSource.SetRange("Source No.", Customer."No.");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"Customer Disc. Group");
        TempPriceSource.SetRange("Source No.", Customer."Customer Disc. Group");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::"Customer Price Group");
        TempPriceSource.SetRange("Source No.", Customer."Customer Price Group");
        Assert.RecordCount(TempPriceSource, 1);
        TempPriceSource.SetRange("Source Type", "Price Source Type"::Contact);
        TempPriceSource.SetRange("Source No.", Contact."No.");
        Assert.RecordCount(TempPriceSource, 1);
    end;

    local procedure VerifyResPriceList(PriceListLine: Record "Price List Line"; ResourceUnitPrice: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Resource', PriceListLine."Asset No.");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the work type code');
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitPrice_Resource', ResourceUnitPrice);

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('No_Resource', PriceListLine."Asset No.");
        LibraryReportDataset.SetRange('WorkTypeCode_ResPrice', PriceListLine."Work Type Code");
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), 'find element with the work type code');
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitPrice_ResPrice', PriceListLine."Unit Price");
    end;

    local procedure CreateStandardCostWorksheet(var StandardCostWorksheetPage: TestPage "Standard Cost Worksheet"; ResourceNo: Code[20]; StandardCost: Decimal; NewStandardCost: Decimal)
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        StandardCostWorksheetPage.Type.SetValue(StandardCostWorksheet.Type::Resource);
        StandardCostWorksheetPage."No.".SetValue(ResourceNo);
        StandardCostWorksheetPage."Standard Cost".SetValue(StandardCost);
        StandardCostWorksheetPage."New Standard Cost".SetValue(NewStandardCost);
        StandardCostWorksheetPage.Next();
    end;

    local procedure ImplementStandardCostChanges(Resource: Record Resource; StandardCost: Decimal; NewStandardCost: Decimal)
    var
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        StandardCostWorksheetPage: TestPage "Standard Cost Worksheet";
    begin
        StandardCostWorksheet.DeleteAll();
        StandardCostWorksheetPage.OpenEdit();
        CreateStandardCostWorksheet(StandardCostWorksheetPage, Resource."No.", StandardCost, NewStandardCost);
        Commit();  // Commit Required due to Run Modal.
        StandardCostWorksheetPage."&Implement Standard Cost Changes".Invoke();
    end;

    local procedure VerifyJobSources(var Job: Record Job; var SalesLinePrice: Codeunit "Sales Line - Price"; AllJobsCounter: Integer; JobCounter: Integer; JobTaskCounter: Integer)
    var
        JobTask: Record "Job Task";
    begin
        JobTask."Job No." := Job."No.";
        VerifyJobSources(JobTask, SalesLinePrice, AllJobsCounter, JobCounter, JobTaskCounter);
    end;

    local procedure VerifyJobSources(var JobTask: Record "Job Task"; var SalesLinePrice: Codeunit "Sales Line - Price"; AllJobsCounter: Integer; JobCounter: Integer; JobTaskCounter: Integer)
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
    begin
        SalesLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        VerifyJobSources(JobTask, PriceCalculationBufferMgt, AllJobsCounter, JobCounter, JobTaskCounter);
    end;

    local procedure VerifyJobSources(var Job: Record Job; var PurchaseLinePrice: Codeunit "Purchase Line - Price"; AllJobsCounter: Integer; JobCounter: Integer; JobTaskCounter: Integer)
    var
        JobTask: Record "Job Task";
    begin
        JobTask."Job No." := Job."No.";
        VerifyJobSources(JobTask, PurchaseLinePrice, AllJobsCounter, JobCounter, JobTaskCounter);
    end;

    local procedure VerifyJobSources(var JobTask: Record "Job Task"; var PurchaseLinePrice: Codeunit "Purchase Line - Price"; AllJobsCounter: Integer; JobCounter: Integer; JobTaskCounter: Integer)
    var
        PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt.";
    begin
        PurchaseLinePrice.CopyToBuffer(PriceCalculationBufferMgt);
        VerifyJobSources(JobTask, PriceCalculationBufferMgt, AllJobsCounter, JobCounter, JobTaskCounter);
    end;

    local procedure VerifyJobSources(var JobTask: Record "Job Task"; var PriceCalculationBufferMgt: Codeunit "Price Calculation Buffer Mgt."; AllJobsCounter: Integer; JobCounter: Integer; JobTaskCounter: Integer)
    var
        TempPriceSource: Record "Price Source" temporary;
    begin
        PriceCalculationBufferMgt.GetSources(TempPriceSource);
        TempPriceSource.SetRange("Source Type", TempPriceSource."Source Type"::"All Jobs");
        Assert.RecordCount(TempPriceSource, AllJobsCounter);
        TempPriceSource.SetRange("Source Type", TempPriceSource."Source Type"::Job);
        TempPriceSource.SetRange("Source No.", JobTask."Job No.");
        Assert.RecordCount(TempPriceSource, JobCounter);
        TempPriceSource.SetRange("Source Type", TempPriceSource."Source Type"::"Job Task");
        TempPriceSource.SetRange("Source No.", JobTask."Job Task No.");
        TempPriceSource.SetRange("Parent Source No.", JobTask."Job No.");
        Assert.RecordCount(TempPriceSource, JobTaskCounter);
    end;

    local procedure CreateSegmentCampaignsForContact(var Campaign: array[2] of Record Campaign; Contact: Record Contact)
    var
        SegmentHeader: array[2] of Record "Segment Header";
        SegmentLine: array[2] of Record "Segment Line";
        i: Integer;
    begin
        for i := 1 to 2 do begin
            LibraryMarketing.CreateCampaign(Campaign[i]);
            LibraryMarketing.CreateSegmentHeader(SegmentHeader[i]);
            LibraryMarketing.CreateSegmentLine(SegmentLine[i], SegmentHeader[i]."No.");
            SegmentLine[i].Validate("Contact No.", Contact."No.");
            SegmentHeader[i].Validate("Campaign No.", Campaign[i]."No.");
            SegmentHeader[i].Validate("Campaign Target", true);
            SegmentHeader[i].Modify();
        end;
    end;

    local procedure CreateServiceCost(var ServiceCost: Record "Service Cost"; Item: Record Item)
    begin
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Validate("Cost Type", ServiceCost."Cost Type"::Support);
        ServiceCost.Validate("Default Quantity", LibraryRandom.RandIntInRange(1, 1));
        ServiceCost.Validate("Default Unit Cost", LibraryRandom.RandIntInRange(100, 100));
        ServiceCost.Validate("Default Unit Price", LibraryRandom.RandIntInRange(200, 200));
        ServiceCost.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        ServiceCost.Modify(true);
    end;

    local procedure CreatePriceListLineForItem(var PriceListLine: Record "Price List Line"; PriceListHeader: Record "Price List Header"; Item: Record Item)
    begin
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine,
            PriceListHeader,
            "Price Amount Type"::Any,
            "Price Asset Type"::Item,
            Item."No.");

        PriceListLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PriceListLine.Validate("Allow Line Disc.", true);
        PriceListLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 10));
        PriceListLine.Validate("Unit Price", 0);
        PriceListLine.Modify(true);
    end;

    local procedure CreatePriceListLineForServiceCost(var PriceListLine: Record "Price List Line"; PriceListHeader: Record "Price List Header"; ServiceCost: Record "Service Cost")
    begin
        LibraryPriceCalculation.CreatePriceListLine(
            PriceListLine,
            PriceListHeader,
            "Price Amount Type"::Any,
            "Price Asset Type"::"Service Cost",
            ServiceCost.Code);

        PriceListLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 10));
        PriceListLine.Validate("Allow Line Disc.", true);
        PriceListLine.Validate("Unit Price", 0);
        PriceListLine.Modify(true);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemLine: Record "Service Item Line"; ServiceCost: Record "Service Cost")
    begin
        ServiceLine.Init();
        ServiceLine."Document Type" := ServiceLine."Document Type"::Order;
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine."Line No." := LibraryRandom.RandIntInRange(10000, 10000);
        ServiceLine."Service Item Line No." := ServiceItemLine."Line No.";
        ServiceLine.Insert(true);

        ServiceLine.Validate(Type, ServiceLine.Type::Cost);
        ServiceLine.Validate("No.", ServiceCost.Code);
        ServiceLine.Modify(true);
    end;

    local procedure CreateItemAndCustomer(var Item: Record Item; var Customer: Record Customer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Allow Line Disc.", false);
        Customer.Modify(true);
    end;

    local procedure CreatePriceListHeader(var PriceListHeader: Record "Price List Header"; CustomerNo: Code[20]; ItemNo: Code[20]; FirstDayOfYear: Date; LastDayOfYear: Date): Decimal
    var
        PriceListLine: Record "Price List Line";
    begin
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader, PriceListHeader."Price Type"::Sale,
            PriceListHeader."Source Type"::Customer, CustomerNo);
        PriceListHeader.Validate("Starting Date", FirstDayOfYear);
        PriceListHeader.Validate("Ending Date", LastDayOfYear);
        PriceListHeader.Validate("Allow Updating Defaults", true);
        PriceListHeader.Modify(true);

        CreatePriceListLine(PriceListLine, PriceListHeader, ItemNo, FirstDayOfYear);
        PriceListHeader.Validate(Status, PriceListHeader.Status::Active);
        PriceListHeader.Modify(true);

        exit(PriceListLine."Unit Price");
    end;

    local procedure CreatePriceListLine(var PriceListLine: Record "Price List Line"; var PriceListHeader: Record "Price List Header"; ItemNo: Code[20]; FirstDayOfYear: Date)
    begin
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine, PriceListHeader.Code,
            PriceListHeader."Source Type", PriceListHeader."Source No.",
            PriceListLine."Asset Type"::Item, ItemNo);
        PriceListLine.Validate("Minimum Quantity", 1);
        PriceListLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        PriceListLine.Validate("Starting Date", FirstDayOfYear);
        PriceListLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesOrdertNo: Code[20]; ItemNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrdertNo);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
    end;

    [RequestPageHandler]
    procedure ImplementStandardCostChangesHandler(var ImplementStandardCostChange: TestRequestPage "Implement Standard Cost Change")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ImplementStandardCostChange.ItemJournalTemplate.SetValue(ItemJournalTemplate.Name);
        ImplementStandardCostChange.ItemJournalBatchName.SetValue(ItemJournalBatch.Name);
        ImplementStandardCostChange.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GetPriceLinePriceModalPageHandler(var GetPriceLine: TestPage "Get Price Line")
    begin
        Assert.AreEqual(true, GetPriceLine."Price List Code".Visible(), 'Price List Code.Visible');
        Assert.AreEqual(false, GetPriceLine."Line Discount %".Visible(), 'Line Discount %.Visible');
        Assert.AreEqual(true, GetPriceLine."Unit Price".Visible(), 'Unit Price.Visible');
        Assert.AreEqual(false, GetPriceLine."Direct Unit Cost".Visible(), 'Direct Unit Cost.Visible');
        Assert.AreEqual(false, GetPriceLine.PurchLineDiscountPct.Visible(), 'PurchLineDiscountPct.Visible');
        Assert.AreEqual(true, GetPriceLine."Allow Line Disc.".Visible(), 'Allow Line Disc.Visible');
        Assert.AreEqual(true, GetPriceLine."Allow Invoice Disc.".Visible(), 'Allow Invoice Disc.Visible');
        GetPriceLine.First();
        GetPriceLine.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GetPurchPriceLinePriceModalPageHandler(var GetPriceLine: TestPage "Get Price Line")
    begin
        Assert.AreEqual(true, GetPriceLine."Price List Code".Visible(), 'Price List Code.Visible');
        Assert.AreEqual(false, GetPriceLine."Line Discount %".Visible(), 'Line Discount %.Visible');
        Assert.AreEqual(false, GetPriceLine."Unit Price".Visible(), 'Unit Price.Visible');
        Assert.AreEqual(true, GetPriceLine."Direct Unit Cost".Visible(), 'Direct Unit Cost.Visible');
        Assert.AreEqual(false, GetPriceLine.PurchLineDiscountPct.Visible(), 'PurchLineDiscountPct.Visible');
        Assert.AreEqual(true, GetPriceLine."Allow Line Disc.".Visible(), 'Allow Line Disc.Visible');
        Assert.AreEqual(true, GetPriceLine."Allow Invoice Disc.".Visible(), 'Allow Invoice Disc.Visible');
        // Asset Type/No visible as the asset list contains (All items) asset
        Assert.AreEqual(true, GetPriceLine."Asset Type".Visible(), 'Asset Type.Visible');
        Assert.AreEqual(true, GetPriceLine."Asset No.".Visible(), 'Asset No.Visible');
        GetPriceLine.First();
        GetPriceLine.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GetPurchPriceLineDiscountModalPageHandler(var GetPriceLine: TestPage "Get Price Line")
    begin
        Assert.AreEqual(true, GetPriceLine."Price List Code".Visible(), 'Price List Code.Visible');
        Assert.AreEqual(false, GetPriceLine."Line Discount %".Visible(), 'Line Discount %.Visible');
        Assert.AreEqual(false, GetPriceLine."Unit Price".Visible(), 'Unit Price.Visible');
        Assert.AreEqual(false, GetPriceLine."Direct Unit Cost".Visible(), 'Direct Unit Cost.Visible');
        Assert.AreEqual(true, GetPriceLine.PurchLineDiscountPct.Visible(), 'PurchLineDiscountPct.Visible');
        Assert.AreEqual(false, GetPriceLine."Allow Line Disc.".Visible(), 'Allow Line Disc.Visible');
        Assert.AreEqual(false, GetPriceLine."Allow Invoice Disc.".Visible(), 'Allow Invoice Disc.Visible');
        // Asset Type/No visible as the asset list is more than one asset
        Assert.AreEqual(true, GetPriceLine."Asset Type".Visible(), 'Asset Type.Visible');
        Assert.AreEqual(true, GetPriceLine."Asset No.".Visible(), 'Asset No.Visible');
        GetPriceLine.First();
        GetPriceLine.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GetPriceLineDiscountModalPageHandler(var GetPriceLine: TestPage "Get Price Line")
    begin
        Assert.AreEqual(true, GetPriceLine."Price List Code".Visible(), 'Price List Code.Visible');
        Assert.AreEqual(true, GetPriceLine."Line Discount %".Visible(), 'Line Discount %.Visible');
        Assert.AreEqual(false, GetPriceLine."Unit Price".Visible(), 'Unit Price.Visible');
        Assert.AreEqual(false, GetPriceLine."Direct Unit Cost".Visible(), 'Direct Unit Cost.Visible');
        Assert.AreEqual(false, GetPriceLine.PurchLineDiscountPct.Visible(), 'PurchLineDiscountPct.Visible');
        Assert.AreEqual(false, GetPriceLine."Allow Line Disc.".Visible(), 'Allow Line Disc.Visible');
        Assert.AreEqual(false, GetPriceLine."Allow Invoice Disc.".Visible(), 'Allow Invoice Disc.Visible');
        GetPriceLine.First();
        GetPriceLine.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GetPriceLineModalPageHandler(var GetPriceLine: TestPage "Get Price Line")
    var
        PriceListCode: Text;
    begin
        PriceListCode := LibraryVariableStorage.DequeueText();
        GetPriceLine.Filter.SetFilter("Price List Code", PriceListCode);
        GetPriceLine.First();
        GetPriceLine."Allow Line Disc.".AssertEquals(Format(true));
        Assert.AreNotEqual(0, GetPriceLine."Line Discount %".AsDecimal(), 'Line Discount % in GetPriceLine');
        GetPriceLine.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ServiceCostsModalPageHandler(var ServiceCosts: TestPage "Service Costs")
    begin
        ServiceCosts.Filter.SetFilter("Code", LibraryVariableStorage.DequeueText());
        ServiceCosts.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(QuestionText: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Msg: Text)
    begin
        LibraryVariableStorage.Enqueue(Msg);
    end;

    [RequestPageHandler]
    procedure ResPriceListReportHandler(var ResPriceList: TestRequestPage "Res. Price List")
    begin
        ResPriceList.Handler.SetValue("Price Calculation Handler"::"Business Central (Version 16.0)");
        ResPriceList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    procedure MessageHandlerOK(Msg: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure GetPriceLineHandler(var GetPriceLine: TestPage "Get Price Line")
    begin
        GetPriceLine.Filter.SetFilter("Starting Date", Format(LibraryVariableStorage.DequeueDate()));
        GetPriceLine.OK().Invoke();
    end;
}