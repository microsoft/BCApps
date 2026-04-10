codeunit 144722 "ERM Bill of Lading Report"
{
    // // [FEATURE] [Report] [Bill of Lading]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesSetupReportTemplate()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 377117] Verify SalesReceivablesSetup."Bill of Lading Template Code" <> ''
        SalesReceivablesSetup.Get();
        Assert.AreNotEqual(
          '',
          SalesReceivablesSetup."Bill of Lading Template Code",
          SalesReceivablesSetup.FieldCaption("Bill of Lading Template Code"));
    end;

    [Test]
    [HandlerFunctions('BOLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestReportExport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocalReportManagement: Codeunit "Local Report Management";
        ItemDescription: Text;
        VehicleDescription: Text;
        VehicleRegNo: Text;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 424668] Export "Bill of Lading" Excel for an open Sales Invoice

        // [GIVEN] Sales Invoice Header
        CreateReleaseSalesInvoice(SalesHeader);
        SalesHeader.SetRange("No.", SalesHeader."No.");
        SalesHeader.CalcFields("Amount Including VAT (LCY)");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        SalesLine."Net Weight" := LibraryRandom.RandIntInRange(2, 3);
        SalesLine."Gross Weight" := LibraryRandom.RandIntInRange(4, 5);
        SalesLine."Unit Volume" := LibraryRandom.RandIntInRange(1, 5);
        SalesLine.Modify();

        ItemDescription := LibraryUtility.GenerateGUID();
        VehicleDescription := LibraryUtility.GenerateGUID();
        VehicleRegNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(ItemDescription);
        LibraryVariableStorage.Enqueue(VehicleDescription);
        LibraryVariableStorage.Enqueue(VehicleRegNo);
        Commit();

        // [WHEN] Run Bill Of lading report for the sales document
        LibraryReportValidation.SetFileName(SalesHeader."No.");
        RunReport(SalesHeader, LibraryReportValidation.GetFileName());

        // [THEN] Sales Document number, Order Date and shipment info is exported
        LibraryReportValidation.VerifyCellValueByRef('BU', 9, 1, Format(SalesHeader."Order Date"));
        LibraryReportValidation.VerifyCellValueByRef('CQ', 9, 1, SalesHeader."No.");
        LibraryReportValidation.VerifyCellValueByRef(
          'B', 15, 1,
          LocalReportManagement.GetCompanyName() + '. ' +
          LocalReportManagement.GetLegalAddress() + LocalReportManagement.GetCompanyPhoneFax());

        LibraryReportValidation.VerifyCellValueByRef('B', 20, 1, SalesHeader."Sell-to Customer No." + '  ');
        LibraryReportValidation.VerifyCellValueByRef('B', 25, 1, ItemDescription);
        LibraryReportValidation.VerifyCellValueByRef('BF', 25, 1, Format(SalesLine."Qty. to Ship"));
        LibraryReportValidation.VerifyCellValueByRef(
          'B', 27, 1,
          LocalReportManagement.FormatReportValue(SalesLine."Qty. to Ship" * SalesLine."Net Weight", 2) + ',  ,' +
          LocalReportManagement.FormatReportValue(SalesLine."Qty. to Ship" * SalesLine."Unit Volume", 2));
        LibraryReportValidation.VerifyCellValueByRef(
          'BF', 29, 1, LocalReportManagement.FormatAmount(SalesHeader."Amount Including VAT (LCY)"));

        LibraryReportValidation.VerifyCellValueByRef('B', 47, 1, VehicleDescription);
        LibraryReportValidation.VerifyCellValueByRef('BF', 47, 1, VehicleRegNo);

        LibraryReportValidation.VerifyCellValueByRef(
          'B', 86, 2, Format(SalesLine."Qty. to Ship" * SalesLine."Net Weight"));

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateReleaseSalesInvoice(var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader."Location Code" := CreateLocationCode();
        SalesHeader."Shipping Agent Code" := CreateShippingAgentCode();
        SalesHeader.Modify();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location."Country/Region Code" := CreateCountryRegionCode();
        Location."Post Code" := LibraryUtility.GenerateGUID();
        Location.City := LibraryUtility.GenerateGUID();
        Location.Address := LibraryUtility.GenerateGUID();
        Location."Address 2" := LibraryUtility.GenerateGUID();
        Location.Modify();
        exit(Location.Code);
    end;

    local procedure CreateCountryRegionCode(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion."Local Name" := LibraryUtility.GenerateGUID();
        CountryRegion.Modify();
        exit(CountryRegion.Code);
    end;

    local procedure CreateShippingAgentCode(): Code[10]
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgent.Name := LibraryUtility.GenerateGUID();
        ShippingAgent.Modify();
        exit(ShippingAgent.Code);
    end;

    local procedure RunReport(var SalesHeader: Record "Sales Header"; FileName: Text)
    var
        BillOfLading: Report "Bill of Lading";
    begin
        BillOfLading.SetTestMode(true);
        BillOfLading.SetFileNameSilent(FileName);
        BillOfLading.SetTableView(SalesHeader);
        BillOfLading.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BOLRequestPageHandler(var BillofLading: TestRequestPage "Bill of Lading")
    begin
        BillofLading.ItemDescription.SetValue(LibraryVariableStorage.DequeueText());
        BillofLading.VehicleDescription.SetValue(LibraryVariableStorage.DequeueText());
        BillofLading.VehicleRegistrationNo.SetValue(LibraryVariableStorage.DequeueText());
        BillofLading.OK().Invoke();
    end;
}

