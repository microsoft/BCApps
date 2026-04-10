codeunit 138400 "RS Pack Content - Evaluation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DEMO] [Evaluation]
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        PostingAfterWDIsOnErr: Label 'Posting After Working Date option is on';
        XOUTGOINGTxt: Label 'OUTGOING';
        XINCOMETxt: Label 'INCOME';
        NonStockNoSeriesTok: Label 'NS-ITEM';
        TransShipmentNoSeriesTok: Label 'T-SHPT';
        TransReceiptNoSeriesTok: Label 'T-RCPT';
        TransOrderNoSeriesTok: Label 'T-ORD';
        ItemNoSeriesTok: Label 'ITEM';
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SalesReturnReceiptTok: Label 'S-RCPT';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyIsDemoCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO] The current Company is a Demo Company
        Initialize();

        CompanyInformation.Get();
        Assert.IsTrue(CompanyInformation."Demo Company", CompanyInformation.FieldName("Demo Company"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyNameEqualsDisplayNameAndShipToName()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO] The ship-to name and display name equals the company name
        Initialize();

        CompanyInformation.Get();
        CompanyInformation.TestField(Name, CompanyName);
        CompanyInformation.TestField("Ship-to Name", CompanyName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingAfterWDIsOn()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        // [SCENARIO 169269] "Posting After Working Date Not Allowed" is on in "My Settings"
        Initialize();

        Assert.IsTrue(InstructionMgt.IsEnabled(InstructionMgt.PostingAfterWorkingDateNotAllowedCode()), PostingAfterWDIsOnErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] There are 7 Sales Invoices, 4 Orders, and 2 Quotes
        Initialize();

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        Assert.RecordCount(SalesHeader, 7);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        Assert.RecordCount(SalesHeader, 4);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        Assert.RecordCount(SalesHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountSalesDocumentsWithShippingAgentCode()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] There are 2 Sales Invoices and 4 Sales Orders with Shipping Agent Code
        Initialize();

        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetFilter("Shipping Agent Code", '<>%1', '');
        Assert.RecordCount(SalesHeader, 2);

        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetFilter("Shipping Agent Code", '<>%1', '');
        Assert.RecordCount(SalesHeader, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNoReleasedSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] There are no Released Sales Documents in the Evaluation data except orders
        // As we can reopen orders, we have will not open orders
        Initialize();

        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.SetFilter("Document Type", '<> %1', SalesHeader."Document Type"::Order);
        Assert.RecordIsEmpty(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAmountsAreCalculatedSalesDocuments()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] The Sales Lines have the Amount field set in the Evaluation data
        Initialize();

        SalesLine.SetRange(Amount, 0);
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        Assert.RecordIsEmpty(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateItemSalesXML()
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempXMLBufferPeriods: Record "XML Buffer" temporary;
        Item: Record Item;
        FileManagement: Codeunit "File Management";
        Periods: Integer;
    begin
        // [FEATURE] [Item sales forecast]
        // [SCENARIO] The data on itemsales.xml are consistent
        Initialize();

        TempXMLBuffer.Load(FileManagement.CombinePath(
            ApplicationPath, '../../App/Demotool/Pictures/MachineLearning/itemsales.xml'));

        Item.SetRange("Assembly BOM", false);
        Evaluate(Periods, TempXMLBuffer.GetAttributeValueAsText('Periods'));
        TempXMLBuffer.FindChildElements(TempXMLBuffer);
        TempXMLBuffer.FindSet();
        Assert.RecordCount(TempXMLBuffer, Item.Count);
        repeat
            TempXMLBuffer.FindChildElements(TempXMLBufferPeriods);
            Assert.AreEqual(Periods, TempXMLBufferPeriods.Count,
              StrSubstNo('Item %1 does not have %2 periods',
                TempXMLBuffer.GetAttributeValueAsText('item'),
                Format(Periods)));
        until TempXMLBuffer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AnyCustomerHaveSalespersonCode()
    var
        Customer: Record Customer;
    begin
        // [FEATURE] [Salesperson]
        // [SCENARIO] All customers should have "Salesperson Code" defined.
        Initialize();

        Customer.SetRange("Salesperson Code", '');
        Assert.RecordIsEmpty(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoices()
    var
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Existing Sales Invoices can be posted without errors
        Initialize();
        // [WHEN] Post all Invoices
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindSet();
        repeat
            PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
            // [THEN] Cust. Ledger Entries are created
            CustLedgEntry.FindLast();
            CustLedgEntry.TestField("Document No.", PostedInvoiceNo);
        until SalesHeader.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountPurchDocuments()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] There are 3 Purchase Invoices and 4 purchase orders but no documents of other types
        Initialize();

        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
        Assert.RecordCount(PurchHeader, 3);

        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        Assert.RecordCount(PurchHeader, 5);

        PurchHeader.SetFilter("Document Type", '<>%1&<>%2', PurchHeader."Document Type"::Order, PurchHeader."Document Type"::Invoice);
        Assert.RecordCount(PurchHeader, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyNoReleasedPurchaseDocuments()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] There are no Released Purchase Documents in the Evaluation data
        Initialize();

        PurchaseHeader.SetRange(Status, PurchaseHeader.Status::Released);
        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMonthlyPurchaseAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PeriodStart: Date;
        PeriodEnd: Date;
        LastOrderDate: Date;
        Total: Decimal;
    begin
        // [FEATURE] [Cash Flow] [Forecast] [Azure AI]
        // [SCENARIO] Monthly purchases must be between 15.000 and 45.000
        Initialize();

        PurchaseHeader.Reset();
        PurchaseHeader.SetCurrentKey("Due Date");
        PurchaseHeader.FindFirst();
        PeriodStart := PurchaseHeader."Due Date";
        PurchaseHeader.FindLast();
        LastOrderDate := PurchaseHeader."Due Date";
        // First of the month
        PeriodStart := CalcDate('<CM + 1D>', CalcDate('<-1M>', PeriodStart));
        PeriodEnd := CalcDate('<CM>', PeriodStart);
        while PeriodEnd < LastOrderDate do begin
            Total := 0;
            PurchaseHeader.Reset();
            PurchaseHeader.SetRange("Due Date", PeriodStart, PeriodEnd);
            PurchaseHeader.FindSet();
            repeat
                PurchaseHeader.CalcFields("Amount Including VAT");
                Total := Total + PurchaseHeader."Amount Including VAT";
            until PurchaseHeader.Next() = 0;
            Assert.IsTrue(Total >= 15000, 'There are less purchases than expected');
            Assert.IsTrue(Total <= 40000, 'There are more purchases than expected');
            PeriodStart := CalcDate('<+1M>', PeriodStart);
            PeriodEnd := CalcDate('<CM>', PeriodStart);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoices()
    var
        PurchHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Existing Purchase Invoices can be posted without errors
        Initialize();
        // [WHEN] Post all Invoices
        PurchHeader.Reset();
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
        PurchHeader.FindSet();
        repeat
            PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
            // [THEN] Vendor Ledger Entries are created
            VendLedgEntry.FindLast();
            VendLedgEntry.TestField("Document No.", PostedInvoiceNo);
        until PurchHeader.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchOrders()
    var
        PurchHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        PostedOrderNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] Existing Purchase Orders can be posted without errors
        Initialize();
        // [WHEN] Post all Orders
        PurchHeader.Reset();
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.FindSet();
        repeat
            PostedOrderNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
            // [THEN] Vendor Ledger Entries are created
            VendLedgEntry.FindLast();
            VendLedgEntry.TestField("Document No.", PostedOrderNo);
        until PurchHeader.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountContacts()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        ContactBusinessRelation: Record "Contact Business Relation";
        CompanyNo: Code[20];
    begin
        // [FEATURE] [Contacts]
        // [SCENARIO] There are two contacts (Company, Person) per each Customer, Vendor, Bank
        Initialize();

        if Customer.FindSet() then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
                VerifyContactPerson(CompanyNo);
            until Customer.Next() = 0;

        if Vendor.FindSet() then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.");
                VerifyContactPerson(CompanyNo);
            until Vendor.Next() = 0;

        if BankAccount.FindSet() then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::"Bank Account", BankAccount."No.");
            until BankAccount.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingAgentRelatedTablesAreNotEmpty()
    begin
        // [SCENARIO] Shipping Agent related tables should not be empty
        Initialize();

        Assert.TableIsNotEmpty(DATABASE::"Shipping Agent");
        Assert.TableIsNotEmpty(DATABASE::"Shipping Agent Services");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemRelatedTablesAreNotEmpty()
    begin
        // [SCENARIO 171192] Susan can set up Item Substitution
        // [SCENARIO 167751] Susan can set up Item References
        Initialize();

        Assert.TableIsNotEmpty(DATABASE::"Item Substitution");
        Assert.TableIsNotEmpty(DATABASE::"Item Reference");
    end;

    local procedure VerifyContactCompany(var CompanyNo: Code[20]; LinkToTable: Enum "Contact Business Relation Link To Table"; No: Code[20])
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", No);
        Assert.RecordCount(ContactBusinessRelation, 1);
        ContactBusinessRelation.FindFirst();
        CompanyNo := ContactBusinessRelation."Contact No.";
    end;

    local procedure VerifyContactPerson(CompanyNo: Code[20])
    var
        ContactPerson: Record Contact;
    begin
        ContactPerson.SetRange("Company No.", CompanyNo);
        ContactPerson.SetRange(Type, ContactPerson.Type::Person);
        Assert.RecordCount(ContactPerson, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionGroups()
    var
        InteractionGroup: Record "Interaction Group";
    begin
        // [FEATURE] [CRM] [Interaction Group]
        // [SCENARIO 174769] Interaction Group should have 6 groups.
        Initialize();

        Assert.RecordCount(InteractionGroup, 6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplates()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 174769] Interaction Template should have 31 templates.
        Initialize();

        Assert.RecordCount(InteractionTemplate, 31);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplateOutgoingIgnoreCorrType()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 159181] Interaction Template OUTGOING should have Ignore Contact Corres. Type = TRUE
        Initialize();

        InteractionTemplate.Get(XOUTGOINGTxt);
        InteractionTemplate.TestField("Ignore Contact Corres. Type", true);
        InteractionTemplate.TestField("Information Flow", InteractionTemplate."Information Flow"::Outbound);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplateIncom()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 390815] Interaction Template INCOM should have Information Flow = Inbound, "Ignore Contact Corres. Type"=Yes
        Initialize();

        InteractionTemplate.Get(XINCOMETxt);
        InteractionTemplate.TestField("Ignore Contact Corres. Type", true);
        InteractionTemplate.TestField("Information Flow", InteractionTemplate."Information Flow"::Inbound);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Locations()
    var
        Location: Record Location;
    begin
        // [FEATURE] [Location]
        // [SCENARIO] Demo data contains 3 regular locations and 2 in-transit locations
        Initialize();

        Location.SetRange("Use As In-Transit", false);
        Assert.RecordCount(Location, 3);
        Location.SetRange("Use As In-Transit", true);
        Assert.RecordCount(Location, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferRoutes()
    var
        TransferRoute: Record "Transfer Route";
    begin
        // [FEATURE] [Location Transfer]
        // [SCENARIO] Demo data contains 2 transfer routes
        Initialize();

        Assert.RecordCount(TransferRoute, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrders()
    var
        TransferHeader: Record "Transfer Header";
    begin
        // [FEATURE] [Location Transfer]
        // [SCENARIO] Demo data contains 2 transfer orders.
        Initialize();

        Assert.RecordCount(TransferHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferShipments()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        // [FEATURE] [Transfer] [Shipment]
        // [SCENARIO] Demo data contains 1 transfer shipment
        Initialize();

        Assert.RecordCount(TransferShipmentHeader, 1);
        Assert.RecordCount(TransferShipmentLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferReciepts()
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        TransferReceiptLine: Record "Transfer Receipt Line";
    begin
        // [FEATURE] [Transfer] [Receipt]
        // [SCENARIO] Demo data contains 1 transfer receipt
        Initialize();

        Assert.RecordCount(TransferReceiptHeader, 1);
        Assert.RecordCount(TransferReceiptLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Employees()
    var
        Employee: Record Employee;
    begin
        // [FEATURE] [Basic HR]
        // [SCENARIO] Demo data contains 7 employees
        Initialize();

        Assert.RecordCount(Employee, 7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MarketingSetupDefaultFields()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        // [SCENARIO 175276] Marketing Setup Default fields filled
        Initialize();

        MarketingSetup.Get();
        MarketingSetup.TestField("Default Language Code");
        MarketingSetup.TestField("Default Correspondence Type", MarketingSetup."Default Correspondence Type"::Email);
        MarketingSetup.TestField("Default Sales Cycle Code");
        MarketingSetup.TestField("Mergefield Language ID");
        MarketingSetup.TestField("Autosearch for Duplicates", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Campaigns()
    var
        Campaign: Record Campaign;
    begin
        // [FEATURE] [CRM] [Campaigns]
        // [SCENARIO 180135] Demo data contain 3 campaigns
        Initialize();

        Assert.RecordCount(Campaign, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAccounts()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [G/L Account]
        // [SCENARIO] Demo DB should have at least one G/L Account
        Initialize();

        Assert.RecordIsNotEmpty(GLAccount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMs()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // [FEATURE] [BOM]
        // [SCENARIO] Demo DB should have 5 BOMs with multiple components
        Initialize();

        // [THEN] 4 BOMs have 3 components
        // [THEN] 1 BOM has 2 components
        Item.SetRange("Assembly BOM", true);
        Assert.RecordCount(Item, 5);

        BOMComponent.SetRange("Parent Item No.", '1925-W');
        Assert.RecordCount(BOMComponent, 3);

        BOMComponent.SetRange("Parent Item No.", '1929-W');
        Assert.RecordCount(BOMComponent, 3);

        BOMComponent.SetRange("Parent Item No.", '1953-W');
        Assert.RecordCount(BOMComponent, 2);

        BOMComponent.SetRange("Parent Item No.", '1965-W');
        Assert.RecordCount(BOMComponent, 3);

        BOMComponent.SetRange("Parent Item No.", '1969-W');
        Assert.RecordCount(BOMComponent, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutomaticCostPostingInInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Initialize();

        InventorySetup.Get();
        InventorySetup.TestField("Automatic Cost Posting", true);
        InventorySetup.TestField("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment"::Always);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesInInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        Initialize();

        InventorySetup.Get();
        InventorySetup.TestField("Item Nos.", ItemNoSeriesTok);
        ValidateNoSeriesExists(ItemNoSeriesTok);
        InventorySetup.TestField("Nonstock Item Nos.", NonStockNoSeriesTok);
        ValidateNoSeriesExists(NonStockNoSeriesTok);
        InventorySetup.TestField("Transfer Order Nos.", TransOrderNoSeriesTok);
        ValidateNoSeriesExists(TransOrderNoSeriesTok);
        InventorySetup.TestField("Posted Transfer Rcpt. Nos.", TransReceiptNoSeriesTok);
        ValidateNoSeriesExists(TransReceiptNoSeriesTok);
        InventorySetup.TestField("Posted Transfer Shpt. Nos.", TransShipmentNoSeriesTok);
        ValidateNoSeriesExists(TransShipmentNoSeriesTok);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportLayoutSelections()
    begin
        // [SCENARIO 215679] There should be BLUESIMPLE custom layouts defined for report layout selections
        Initialize();

        VerifyReportLayoutSelection(REPORT::"Standard Sales - Quote", 'StandardSalesQuoteBlue.docx');
        VerifyReportLayoutSelection(REPORT::"Standard Sales - Invoice", 'StandardSalesInvoiceBlueSimple.docx');
    end;

    local procedure VerifyReportLayoutSelection(ReportID: Integer; CustomReportLayoutName: Text[250])
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        TenantReportLayoutSelection.SetRange("Report ID", ReportID);
        TenantReportLayoutSelection.SetRange("Layout Name", CustomReportLayoutName);
        Assert.RecordIsNotEmpty(TenantReportLayoutSelection);
    end;

    local procedure ValidateNoSeriesExists(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.SetRange(Code, NoSeriesCode);
        Assert.RecordIsNotEmpty(NoSeries);
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        Assert.RecordIsNotEmpty(NoSeriesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingGroupsCount()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [SCENARIO] There are 7 VAT Prod. Posting groups
        Initialize();

        Assert.RecordCount(VATProductPostingGroup, 7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemsHaveImages()
    var
        Item: Record Item;
    begin
        Initialize();

        Item.FindSet();
        repeat
            Assert.AreNotEqual(0, Item.Picture.Count, StrSubstNo('Expected at least one image for item %1', Item."No."));
        until Item.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesInPurchSetup()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        // [SCENARIO 259575] Purchase Setup has all needed number series fields filled in to be able create and post purchase documents
        Initialize();

        PurchSetup.Get();
        PurchSetup.TestField("Vendor Nos.");
        ValidateNoSeriesExists(PurchSetup."Vendor Nos.");
        PurchSetup.TestField("Quote Nos.");
        ValidateNoSeriesExists(PurchSetup."Quote Nos.");
        PurchSetup.TestField("Order Nos.");
        ValidateNoSeriesExists(PurchSetup."Order Nos.");
        PurchSetup.TestField("Invoice Nos.");
        ValidateNoSeriesExists(PurchSetup."Invoice Nos.");
        PurchSetup.TestField("Posted Invoice Nos.");
        ValidateNoSeriesExists(PurchSetup."Posted Invoice Nos.");
        PurchSetup.TestField("Credit Memo Nos.");
        ValidateNoSeriesExists(PurchSetup."Credit Memo Nos.");
        PurchSetup.TestField("Posted Credit Memo Nos.");
        ValidateNoSeriesExists(PurchSetup."Posted Credit Memo Nos.");
        PurchSetup.TestField("Posted Receipt Nos.");
        ValidateNoSeriesExists(PurchSetup."Posted Receipt Nos.");
        PurchSetup.TestField("Blanket Order Nos.");
        ValidateNoSeriesExists(PurchSetup."Blanket Order Nos.");
        PurchSetup.TestField("Return Order Nos.");
        ValidateNoSeriesExists(PurchSetup."Return Order Nos.");
        PurchSetup.TestField("Posted Return Shpt. Nos.");
        ValidateNoSeriesExists(PurchSetup."Posted Return Shpt. Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalesReturnReceiptNoSeriesPopulated()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales] [No. Series] [UT]
        // [SCENARIO 291743] Posted Sales Return Receipt No. Series is populated
        Initialize();

        ValidateNoSeriesExists(SalesReturnReceiptTok);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.TestField("Posted Return Receipt Nos.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPurchasingCodes()
    var
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [UT] [Purchasing]
        // [SCENARIO 328635] There are 3 records of Purchasing table
        Initialize();

        Assert.RecordCount(Purchasing, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionAllowedValuesFilter()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Default Dimension]
        // [SCENARIO 386881] At least one "Default Dimension" record with non empty "Allowed Values Filter"
        Initialize();

        DefaultDimension.SetFilter("Allowed Values Filter", '<>%1', '');
        Assert.RecordIsNotEmpty(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionLogEntries()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [Interaction Log Entry]
        // [SCENARIO 386492] "Interaction Log Entry" table has data 
        Initialize();

        Assert.RecordIsNotEmpty(InteractionLogEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CausesOfAbsence()
    var
        CauseofAbsence: Record "Cause of Absence";
    begin
        // [FEATURE] [Cause of Absence]
        // [SCENARIO 404724] "Cause of Absence" table has data 
        Initialize();

        Assert.RecordIsNotEmpty(CauseofAbsence);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"RS Pack Content - Evaluation");

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"RS Pack Content - Evaluation");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"RS Pack Content - Evaluation");
    end;
}

