codeunit 138300 "RS Pack Content - Standard"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DEMO] [Standard]
    end;

    var
        Assert: Codeunit Assert;
        PostingAfterWDIsOnErr: Label 'Posting After Working Date option is on';
        XOUTGOINGTxt: Label 'OUTGOING';
        NonStockNoSeriesTok: Label 'NS-ITEM';
        TransShipmentNoSeriesTok: Label 'T-SHPT';
        TransReceiptNoSeriesTok: Label 'T-RCPT';
        TransOrderNoSeriesTok: Label 'T-ORD';
        ItemNoSeriesTok: Label 'ITEM';

    [Test]
    [Scope('OnPrem')]
    procedure CompanyIsDemoCompany()
    var
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO] The current Company is NOT a Demo Company
        CompanyInformation.Get();
        Assert.IsFalse(CompanyInformation."Demo Company", CompanyInformation.FieldName("Demo Company"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingAfterWDIsOn()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        // [SCENARIO 169269] "Posting After Working Date Not Allowed" is on in "My Settings"

        Assert.IsTrue(InstructionMgt.IsEnabled(InstructionMgt.PostingAfterWorkingDateNotAllowedCode()), PostingAfterWDIsOnErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] There are 0 Sales Invoices and 0 documents of other types
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        Assert.RecordCount(SalesHeader, 0);

        SalesHeader.SetFilter("Document Type", '<>%1', SalesHeader."Document Type"::Invoice);
        Assert.RecordCount(SalesHeader, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountPurchDocuments()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] There are 0 Purchase Invoices and 0 documents of other types
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
        Assert.RecordCount(PurchHeader, 0);

        PurchHeader.SetFilter("Document Type", '<>%1', PurchHeader."Document Type"::Invoice);
        Assert.RecordCount(PurchHeader, 0);
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
        Assert.TableIsNotEmpty(DATABASE::"Shipping Agent");
        Assert.TableIsNotEmpty(DATABASE::"Shipping Agent Services");
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
        Assert.RecordCount(InteractionGroup, 6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplates()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 174769] Interaction Template should have 26 templates.
        Assert.RecordCount(InteractionTemplate, 26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplateOutgoingIgnoreCorrType()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 159181] Interaction Template OUTGOING should have Ignore Contact Corres. Type = TRUE
        InteractionTemplate.Get(XOUTGOINGTxt);
        InteractionTemplate.TestField("Ignore Contact Corres. Type", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Locations()
    begin
        // [FEATURE] [Location]
        // [SCENARIO] Demo data contains no locations
        Assert.TableIsEmpty(DATABASE::Location);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferRoutes()
    begin
        // [FEATURE] [Location Transfer]
        // [SCENARIO] Demo data contains no transfer routes
        Assert.TableIsEmpty(DATABASE::"Transfer Route");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferOrders()
    begin
        // [FEATURE] [Location Transfer]
        // [SCENARIO] Demo data contains no transfer orders
        Assert.TableIsEmpty(DATABASE::"Transfer Header");
        Assert.TableIsEmpty(DATABASE::"Transfer Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferShipments()
    begin
        // [FEATURE] [Transfer] [Shipment]
        // [SCENARIO] Demo data contains no transfer shipments
        Assert.TableIsEmpty(DATABASE::"Transfer Shipment Header");
        Assert.TableIsEmpty(DATABASE::"Transfer Shipment Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferReciepts()
    begin
        // [FEATURE] [Transfer] [Receipt]
        // [SCENARIO] Demo data contains no transfer receipts
        Assert.TableIsEmpty(DATABASE::"Transfer Receipt Header");
        Assert.TableIsEmpty(DATABASE::"Transfer Receipt Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Employees()
    begin
        // [FEATURE] [Basic HR]
        // [SCENARIO] Demo data contains no employees
        Assert.TableIsEmpty(DATABASE::Employee);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MarketingSetupDefaultFields()
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        // [SCENARIO 175276] Marketing Setup Default fields filled
        MarketingSetup.Get();
        MarketingSetup.TestField("Default Language Code");
        MarketingSetup.TestField("Default Correspondence Type", MarketingSetup."Default Correspondence Type"::Email);
        MarketingSetup.TestField("Default Sales Cycle Code");
        MarketingSetup.TestField("Mergefield Language ID");
        MarketingSetup.TestField("Autosearch for Duplicates", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutomaticCostPostingInInventorySetup()
    var
        InventorySetup: Record "Inventory Setup";
    begin
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
    procedure O365HTMLTemplates()
    var
        O365HTMLTemplate: Record "O365 HTML Template";
        MediaResources: Record "Media Resources";
    begin
        // [SCENARIO 207285] There should be 1 HTML template
        Assert.RecordCount(O365HTMLTemplate, 1);
        O365HTMLTemplate.FindFirst();
        O365HTMLTemplate.TestField("Media Resources Ref");
        MediaResources.Get(O365HTMLTemplate."Media Resources Ref");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365BrandColors()
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        // [SCENARIO 207285] There should be 12 brand colors
        Assert.RecordCount(O365BrandColor, 12);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure O365PaymentServiceLogos()
    var
        O365PaymentServiceLogo: Record "O365 Payment Service Logo";
    begin
        // [SCENARIO 207285] There should be 3 records of O365 Payment Service Logo table
        Assert.RecordCount(O365PaymentServiceLogo, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportLayoutSelections()
    begin
        // [SCENARIO 215679] There should be BLUESIMPLE custom layouts defined for report layout selections
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
    procedure VATStatementNotEmpty()
    begin
        // [SCENARIO] VAT Statement tables must contain records
        Assert.TableIsNotEmpty(DATABASE::"VAT Statement Template");
        Assert.TableIsNotEmpty(DATABASE::"VAT Statement Name");
        Assert.TableIsNotEmpty(DATABASE::"VAT Statement Line");
    end;
}

