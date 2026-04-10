codeunit 138200 "Normal DemoData"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DEMO] [Extended]
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibrarySales: Codeunit "Library - Sales";
        EmptyBlobErr: Label 'BLOB field is empty.';
        XOUTGOINGTxt: Label 'OUTGOING';
        XINCOMETxt: Label 'INCOME';
        XCashCycleAccSchedNameTxt: Label 'I_CACYCLE', Comment = 'Data for Cash Cycle chart abrivated. Starting with I beacuse of sorting. Maximum lenght 10 characters';
        XReducedTrialBalanceAccSchedNameTxt: Label 'I_MINTRIAL', Comment = 'Data for Mini Trial Balance chart abrivated. Starting with I beacuse of sorting. Maximum lenght 10 characters';
        XBUDGANALYS: Label 'BUDGANALYS';
        XACTBUD: Label 'Act/Bud';

    [Test]
    [Scope('OnPrem')]
    procedure CompanyIsDemoCompany()
    var
        CompanyInformation: Record "Company Information";
        IsDemoCompany: Boolean;
    begin
        // [SCENARIO] The current Company is a Demo Company if it is named CRONUS
        CompanyInformation.Get();
        if CompanyInformation.Name = '' then
            IsDemoCompany := false
        else
            IsDemoCompany := CompanyInformation.Name.Contains('CRONUS');

        Assert.AreEqual(IsDemoCompany, CompanyInformation."Demo Company", StrSubstNo('%1 must be set to true for Company: %2', CompanyInformation.FieldName("Demo Company"), CompanyInformation.Name));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] There is 1 Sales Invoice and 43 documents of other types
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        Assert.RecordCount(SalesHeader, 1);

        SalesHeader.SetFilter("Document Type", '<>%1', SalesHeader."Document Type"::Invoice);
        Assert.RecordCount(SalesHeader, 43);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoices()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] Existing Sales Invoice cannot be posted
        // [WHEN] Post all Invoices
        SalesHeader.Reset();
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.FindSet();
        repeat
            asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
            // [THEN] An error: 'There is nothing to post.'
            Assert.ExpectedError(DocumentErrorsMgt.GetNothingToPostErrorMsg());
        until SalesHeader.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CountPurchDocuments()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO] There are 0 Purchase Invoices and 21 documents of other types
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Invoice);
        Assert.RecordCount(PurchHeader, 0);

        PurchHeader.SetFilter("Document Type", '<>%1', PurchHeader."Document Type"::Invoice);
        Assert.RecordCount(PurchHeader, 21);
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
        // [SCENARIO] There is a Company contact per each Customer, Vendor, Bank
        if Customer.FindSet() then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::Customer, Customer."No.");
            until Customer.Next() = 0;

        if Vendor.FindSet() then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.");
            until Vendor.Next() = 0;

        if BankAccount.FindSet() then
            repeat
                VerifyContactCompany(CompanyNo, ContactBusinessRelation."Link to Table"::"Bank Account", BankAccount."No.");
            until BankAccount.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuerySegmentLinesInDemo()
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceOData: Record "Tenant Web Service OData";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 266325] "Tenant Web Service" and "Tenant Web Service OData" contain record for Query "Segment Lines"

        TenantWebService.Get(TenantWebService."Object Type"::Query, 'SegmentLines');
        TenantWebService.TestField("Object ID", QUERY::"Segment Lines");
        TenantWebService.TestField(Published, true);

        TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        Assert.RecordIsNotEmpty(TenantWebServiceOData);
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

    [Test]
    [Scope('OnPrem')]
    procedure InteractionGroups()
    var
        InteractionGroup: Record "Interaction Group";
    begin
        // [FEATURE] [CRM] [Interaction Group]
        // [SCENARIO 174769] Interaction Group should have 6 groups.
        Assert.RecordCount(InteractionGroup, 8);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplates()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 174769] Interaction Template should have 41 templates.
        Assert.RecordCount(InteractionTemplate, 41);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplateOutgoing()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [CRM] [Interaction Template]
        // [SCENARIO 390815] Interaction Template OUTGOING should have Information Flow = Outbound, "Ignore Contact Corres. Type"=Yes

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

        InteractionTemplate.Get(XINCOMETxt);
        InteractionTemplate.TestField("Ignore Contact Corres. Type", true);
        InteractionTemplate.TestField("Information Flow", InteractionTemplate."Information Flow"::Inbound);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPostingGroupsCount()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // [SCENARIO] There are 3 VAT Prod. Posting groups
        Assert.RecordCount(VATProductPostingGroup, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicingEmailMediaResources()
    begin
        // [SCENARIO 213193] Media resources related to invoicing email are imported
        VerifyBLOBMediaResources('INVOICING - SALESMAIL.HTML');
        VerifyBLOBMediaResources('PAYMENT SERVICE - MICROSOFT-LOGO.PNG');
        VerifyBLOBMediaResources('PAYMENT SERVICE - PAYPAL-LOGO.PNG');
        VerifyBLOBMediaResources('PAYMENT SERVICE - WORLDPAY-LOGO.PNG');
        VerifyBLOBMediaResources('SOCIAL - FACEBOOK.PNG');
        VerifyBLOBMediaResources('SOCIAL - INSTAGRAM.PNG');
        VerifyBLOBMediaResources('SOCIAL - LINKEDIN.PNG');
        VerifyBLOBMediaResources('SOCIAL - PINTEREST.PNG');
        VerifyBLOBMediaResources('SOCIAL - TWITTER.PNG');
        VerifyBLOBMediaResources('SOCIAL - YELP.PNG');
        VerifyBLOBMediaResources('SOCIAL - YOUTUBE.PNG');
    end;

    local procedure VerifyBLOBMediaResources("Code": Code[50])
    var
        MediaResources: Record "Media Resources";
    begin
        MediaResources.Get(Code);
        MediaResources.CalcFields(Blob);
        Assert.IsTrue(MediaResources.Blob.HasValue, EmptyBlobErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLSetupTaxInvoiceRenamingThreshold()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Tax Invoice Threshold]
        // [SCENARIO 271628] "Tax Invoice Renaming Threshold" is 0.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Tax Invoice Renaming Threshold", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ElectronicDocumentFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        UsageOption: Option;
    begin
        // [FEATURE] [Electronic Document]
        // [SCENARIO 341241] Electronic document format has setup for PEPPOL BIS3 for all Usage options
        for UsageOption := ElectronicDocumentFormat.Usage::"Sales Invoice".AsInteger() to ElectronicDocumentFormat.Usage::"Service Validation".AsInteger() do
            ElectronicDocumentFormat.Get('PEPPOL BIS3', UsageOption);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobDefaultDimension()
    var
        Job: Record Job;
    begin
        // [FEATURE] [Job] [Dimensions]
        // [SCENARIO 282994] Job default dimensions are the same with bill-to customer default dimensions
        if Job.FindSet() then
            repeat
                VerifyJobDefaultDimensions(Job);
            until Job.Next() = 0;
    end;

    local procedure VerifyJobDefaultDimensions(Job: Record Job)
    var
        CustDefaultDimension: Record "Default Dimension";
        JobDefaultDimension: Record "Default Dimension";
    begin
        CustDefaultDimension.SetRange("Table ID", DATABASE::Customer);
        CustDefaultDimension.SetRange("No.", Job."Bill-to Customer No.");
        if CustDefaultDimension.FindSet() then
            repeat
                JobDefaultDimension.Get(DATABASE::Job, Job."No.", CustDefaultDimension."Dimension Code");
                JobDefaultDimension.TestField("Dimension Value Code", CustDefaultDimension."Dimension Value Code");
            until CustDefaultDimension.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportSetup_ReturnPeriodDefaultSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
        DummyDateFormula: DateFormula;
    begin
        // [FEATURE] [VAT Return Period]
        // [SCENARIO 258181] TAB 743 "VAT Report Setup" default setup
        VATReportSetup.Get();
        VATReportSetup.TestField("VAT Return Period No. Series");
        VATReportSetup.TestField("Report Version", '');
        VATReportSetup.TestField("Period Reminder Calculation", DummyDateFormula);
        VATReportSetup.TestField("Update Period Job Frequency", VATReportSetup."Update Period Job Frequency"::Never);
        VATReportSetup.TestField("Manual Receive Period CU ID", 0);
        VATReportSetup.TestField("Receive Submitted Return CU ID", 0);
        VATReportSetup.TestField("Auto Receive Period CU ID", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionAllowedValuesFilter()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        // [FEATURE] [Default Dimension]
        // [SCENARIO 386881] At least one "Default Dimension" record with non empty "Allowed Values Filter"

        DefaultDimension.SetFilter("Allowed Values Filter", '<>%1', '');
        Assert.RecordIsNotEmpty(DefaultDimension);
    end;

    [Test]
    procedure AccountScheduleHideCurrencySymbol()
    begin
        // [SCENARIO 425105] Specific account schedule lines marked with "Hide Currency Symbol"
        VerifyAccountScheduleLineHideCurencySymbol(XCashCycleAccSchedNameTxt, 50000);
        VerifyAccountScheduleLineHideCurencySymbol(XCashCycleAccSchedNameTxt, 60000);
        VerifyAccountScheduleLineHideCurencySymbol(XCashCycleAccSchedNameTxt, 70000);
        VerifyAccountScheduleLineHideCurencySymbol(XCashCycleAccSchedNameTxt, 80000);

        VerifyAccountScheduleLineHideCurencySymbol(XReducedTrialBalanceAccSchedNameTxt, 40000);
        VerifyAccountScheduleLineHideCurencySymbol(XReducedTrialBalanceAccSchedNameTxt, 70000);
    end;

    [Test]
    procedure ColumnLayoutHideCurrencySymbol()
    begin
        // [SCENARIO 425105] Specific column layout marked with "Hide Currency Symbol"
        VerifyColumnLayoutHideCurencySymbol(XBUDGANALYS, 30000);

        VerifyColumnLayoutHideCurencySymbol(XACTBUD, 40000);
    end;

    local procedure VerifyAccountScheduleLineHideCurencySymbol(ScheduleName: Code[10]; LineNo: Integer)
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        AccScheduleLine.Get(ScheduleName, LineNo);
        AccScheduleLine.TestField("Hide Currency Symbol", true);
    end;


    local procedure VerifyColumnLayoutHideCurencySymbol(ColumnLayoutName: Code[10]; LineNo: Integer)
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.Get(ColumnLayoutName, LineNo);
        ColumnLayout.TestField("Hide Currency Symbol", true);
    end;

    [Test]
    procedure GBIsExcludedFromEUCountry()
    var
        CountryRegion: Record "Country/Region";
    begin
        // [SCENARIO 402208] "GB" is excluded from country\region "EU Country/Region Code" field value for all countries
        CountryRegion.SetRange("EU Country/Region Code", 'GB');
        Assert.RecordIsEmpty(CountryRegion);
    end;
}

