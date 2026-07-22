codeunit 148150 "FI Company Field Report Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        BusinessIdentityCodeTxt: Text[20];
        RegisteredHomeCityTxt: Text[50];

    local procedure Initialize()
    var
        CompanyInformation: Record "Company Information";
    begin
        BusinessIdentityCodeTxt := '0123456789';
        RegisteredHomeCityTxt := '0123456789';

        EnableVATVIESDeclarationFeature();
        LibraryReportDataset.Reset();
        CompanyInformation.Get();
        CompanyInformation."Business Identity Code" := BusinessIdentityCodeTxt;
        CompanyInformation."Registered Home City" := RegisteredHomeCityTxt;
        CompanyInformation.Modify();

        Commit();
    end;

    [Test]
    [HandlerFunctions('StandardSalesQuoteReportRequestPageHandler')]
    procedure RegisteredHomeCityInStandardSalesQuote()
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        RequestPageXML: Text;
    begin
        // [Scenario] Test FI Core extension subscriber for the field "Registered Home City"
        Initialize();

        DocumentNo := CreateSalesDocument(SalesHeader."Document Type"::Quote);

        // [THEN] The even should be triggered in OnInitReport
        RequestPageXML := Report.RunRequestPage(Report::"Standard Sales - Quote", RequestPageXML);

        SalesHeader.SetRange("No.", DocumentNo);
        LibraryReportDataset.RunReportAndLoad(Report::"Standard Sales - Quote", SalesHeader, RequestPageXML);

        // [THEN] Element should be correctly initialized
        LibraryReportDataset.AssertElementWithValueExists('CompanyLegalOffice', RegisteredHomeCityTxt);
        LibraryReportDataset.AssertElementWithValueExists('CompanyLegalOffice_Lbl', CompanyInformation.FieldCaption(CompanyInformation."Registered Home City"));
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationTaxAuthReportRequestPageHandler')]
    procedure CompanyFieldsInVATVIESDeclaration()
    var
        CompanyInformation: Record "Company Information";
        VATVIESDeclarationTaxAuthReport: Report "VAT- VIES Declaration Tax Auth";
    begin
        // [Scenario] Test FI Core extension subscriber for Finnish company fields in the VIES declaration.
        Initialize();

        // [WHEN] The VAT VIES declaration report is run.
        VATVIESDeclarationTaxAuthReport.UseRequestPage(true);
        VATVIESDeclarationTaxAuthReport.InitializeRequest(true, WorkDate(), WorkDate() + 365, '');
        VATVIESDeclarationTaxAuthReport.Run();

        // [THEN] Finnish company fields and captions are initialized in the report dataset.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoBusinessIdentityCode', BusinessIdentityCodeTxt);
        LibraryReportDataset.AssertElementWithValueExists('BusinessIdentityCodeCaption', CompanyInformation.FieldCaption(CompanyInformation."Business Identity Code"));
        LibraryReportDataset.AssertElementWithValueExists('CompanyInfoRegisteredHomeCity', RegisteredHomeCityTxt);
        LibraryReportDataset.AssertElementWithValueExists('RegHomeCityCaption', CompanyInformation.FieldCaption(CompanyInformation."Registered Home City"));
        LibraryReportDataset.AssertElementWithValueExists('ServiceSuppliesCode4Caption', 'Total Value of Service Supplies(Code 4)');
    end;

    local procedure EnableVATVIESDeclarationFeature()
    var
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
        FeatureIdTok: Label 'FIVATVIESDeclaration', Locked = true;
    begin
        if FeatureKey.Get(FeatureIdTok) then begin
            FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get(FeatureIdTok, CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Enabled;
            FeatureKeyUpdateStatus.Modify();
        end;
        Commit();
    end;

    local procedure CreateSalesDocument(Type: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, Type, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(1000));

        Commit();

        exit(SalesHeader."No.");
    end;

    [RequestPageHandler]
    procedure StandardSalesQuoteReportRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
    end;

    [RequestPageHandler]
    procedure VATVIESDeclarationTaxAuthReportRequestPageHandler(var VATVIESDeclarationTaxAuthReport: TestRequestPage "VAT- VIES Declaration Tax Auth")
    begin
        VATVIESDeclarationTaxAuthReport.SaveAsXml(
            LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
