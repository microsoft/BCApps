codeunit 142078 "Test Vat VIES Declaration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        NoSeries: Record "No. Series";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        FileMgt: Codeunit "File Management";
        ReportingType: Option "Normal transmission","Recall of an earlier report";
        Initialized: Boolean;
        CustomerNotFoundErr: Label 'Could not find any EU customer.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Test Vat VIES Declaration");
        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Test Vat VIES Declaration");
        Initialized := true;
        CreateNoSeries(NoSeries);
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestVATVIESForEU3rdPartyTrade()
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocumentNo: Code[20];
        ExportedFileName: Text;
        VATRegistrationNo: Text[20];
        Amount: Decimal;
    begin
        // Setup
        Initialize();
        VATEntry.DeleteAll(true);
        DocumentNo := CreateAndPostSalesInvoice(Customer);

        // Exercise
        ExportedFileName := FileMgt.ServerTempFileName('xml');
        RunReportVATVIESDeclarationXML(
          ReportingType::"Normal transmission", ExportedFileName,
          Customer."VAT Bus. Posting Group",
          NoSeries.Code,
          false);

        // Verify
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATRegistrationNo := VATEntry."VAT Registration No.";

        Clear(VATEntry);
        VATEntry.CalcSums(Base);
        Amount := VATEntry.Base;

        LibraryXPathXMLReader.Initialize(ExportedFileName, '');

        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '/ERKLAERUNGS_UEBERMITTLUNG/ERKLAERUNG/ZM/UID_MS',
          VATRegistrationNo);

        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '/ERKLAERUNGS_UEBERMITTLUNG/ERKLAERUNG/ZM/SUM_BGL',
          Format(Round(-Amount, 1), 0, 1));
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclarationXMLRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestRecallReportVATVIESForEU3rdPartyTrade()
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        DocumentNo: Code[20];
        ExportedFileName: Text;
    begin
        // Setup
        Initialize();
        VATEntry.DeleteAll(true);
        DocumentNo := CreateAndPostSalesInvoice(Customer);

        // Exercise
        ExportedFileName := FileMgt.ServerTempFileName('xml');
        RunReportVATVIESDeclarationXML(
          ReportingType::"Recall of an earlier report", ExportedFileName,
          Customer."VAT Bus. Posting Group",
          NoSeries.Code,
          true);

        // Verify
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();

        LibraryXPathXMLReader.Initialize(ExportedFileName, '');

        LibraryXPathXMLReader.VerifyNodeAbsence('/ERKLAERUNGS_UEBERMITTLUNG/ERKLAERUNG/ZM');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
          '/ERKLAERUNGS_UEBERMITTLUNG/ERKLAERUNG/GESAMTRUECKZIEHUNG/GESAMTRUECK',
          'J');
    end;

    local procedure CreateNoSeries(var NoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '000000000', '111111111');
    end;

    local procedure CreateAndPostSalesInvoice(var Customer: Record Customer): Code[10]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        FindEUCustomer(Customer);
        LibrarySales.FindItem(Item);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("EU 3-Party Trade", true);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 30);
        SalesLine.Validate("Unit Price", 40);
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure RunReportVATVIESDeclarationXML(ReportingType: Option; XMLFileName: Text; VATBusPostingGroup: Code[20]; NoSeriesCode: Code[20]; UseReportingDate: Boolean)
    var
        VATVIESDeclarationXML: Report "VAT - VIES Declaration XML";
    begin
        // Enqueue Required inside VATVIESDeclarationXMLRequestPageHandler.
        LibraryVariableStorage.Enqueue(ReportingType);
        LibraryVariableStorage.Enqueue(NoSeriesCode);
        LibraryVariableStorage.Enqueue(VATBusPostingGroup);
        LibraryVariableStorage.Enqueue(UseReportingDate);
        Commit();

        VATVIESDeclarationXML.SetFileName(XMLFileName);
        VATVIESDeclarationXML.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATVIESDeclarationXMLRequestPageHandler(var VATVIESDeclarationXML: TestRequestPage "VAT - VIES Declaration XML")
    var
        ReportingTypeVar: Variant;
        NoSeriesVar: Variant;
        VATBusPostingGroupVar: Variant;
        UseReportingDateVar: Variant;
        UseReportingDate: Boolean;
    begin
        LibraryVariableStorage.Dequeue(ReportingTypeVar);
        LibraryVariableStorage.Dequeue(NoSeriesVar);
        LibraryVariableStorage.Dequeue(VATBusPostingGroupVar);
        LibraryVariableStorage.Dequeue(UseReportingDateVar);

        UseReportingDate := UseReportingDateVar;

        VATVIESDeclarationXML.ReportingType.SetValue(ReportingTypeVar);
        if UseReportingDate then
            VATVIESDeclarationXML.ReportingDate.SetValue(WorkDate())
        else
            VATVIESDeclarationXML.ReportingDate.SetValue(0D);

        VATVIESDeclarationXML.RepPeriodFrom.SetValue(WorkDate() - 2);
        // Starting Date
        VATVIESDeclarationXML.RepPeriodTo.SetValue(WorkDate() + 5);
        // Ending Date
        VATVIESDeclarationXML.NoSeries.SetValue(NoSeriesVar);
        VATVIESDeclarationXML."VAT Entry".SetFilter("VAT Bus. Posting Group", VATBusPostingGroupVar);
        VATVIESDeclarationXML.SaveAsXml(FileMgt.ServerTempFileName('xml'), FileMgt.ServerTempFileName('xml'));
    end;

    local procedure FindEUCustomer(var Customer: Record Customer)
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        CountryRegion.SetFilter("EU Country/Region Code", '<>'''' & <>''%1''', CompanyInformation."Country/Region Code");
        CountryRegion.FindSet();

        repeat
            Clear(Customer);
            Customer.SetRange("Country/Region Code", CountryRegion.Code);
            if not Customer.IsEmpty() then begin
                Customer.FindFirst();
                exit;
            end
        until CountryRegion.Next() <> 0;

        Error(CustomerNotFoundErr)
    end;
}

