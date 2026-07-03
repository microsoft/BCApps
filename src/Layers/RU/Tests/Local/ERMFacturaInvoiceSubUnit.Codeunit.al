codeunit 144513 "ERM FacturaInvoiceSubUnit"
{
    // // [FEATURE] [Factura-Invoice] [Proforma-Invoice] [Report]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryVATLedger: Codeunit "Library - VAT Ledger";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRUReports: Codeunit "Library RU Reports";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        SalesVATLedgerKPPErr: Label 'Sales VAT Ledger Line incorrect Reg. Reason Code';

    [Test]
    [Scope('OnPrem')]
    procedure UnpostedSalesFactura()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] Export REP 12411 "Order Factura-Invoice (A)" for open sales invoice

        // [GIVEN] Company address with "Post Code" = "A", County = "B", City = "C", "Address" = "D", "Address 2" = "E"
        // [GIVEN] Sales invoice for customer with "Post Code" = "F", County = "G", City = "H", "Address" = "I", "Address 2" = "J"
        CreateCustomerAndInvoice(SalesHeader, Customer, ShipToAddress);

        // [WHEN] Print REP 12411 "Order Factura-Invoice (A)"
        FacturaInvoiceExcelExport(SalesHeader, false);

        // [THEN] Exported factura field "2a" (seller address) = "A, B, C, D, E"
        // [THEN] Exported factura field "6a" (buyer address) = "F, G, H, I, J"
        VerifyFacturaReportHeader(Customer."No.");
        VerifyAddressKPPCode(Customer, ShipToAddress, ShipToAddress."KPP Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesFactura()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // [SCENARIO] Export REP 12418 "Posted Factura-Invoice (A)" for posted sales invoice
        CreateCustomerAndInvoice(SalesHeader, Customer, ShipToAddress);

        // [GIVEN] Company address with "Post Code" = "A", County = "B", City = "C", "Address" = "D", "Address 2" = "E"
        // [GIVEN] Posted sales invoice for customer with "Post Code" = "F", County = "G", City = "H", "Address" = "I", "Address 2" = "J"
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Print REP 12418 "Posted Factura-Invoice (A)"
        PostedFacturaInvoiceExcelExport(DocumentNo);
        VerifyAddressKPPCode(Customer, ShipToAddress, ShipToAddress."KPP Code");

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), Customer."No.");

        // [THEN] Exported factura field "2a" (seller address) = "A, B, C, D, E"
        // [THEN] Exported factura field "6a" (buyer address) = "F, G, H, I, J"
        VerifyFacturaReportHeader(Customer."No.");
        VerifyVATLedgerKPPCode(VATLedgerCode, ShipToAddress."KPP Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualKPPCode()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        KPPCode: Code[10];
    begin
        // Manually filled KPP Code
        CreateCustomerAndInvoice(SalesHeader, Customer, ShipToAddress);
        KPPCode :=
          LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("KPP Code"), DATABASE::"Sales Header");
        SetManualKPPCode(SalesHeader, KPPCode);

        FacturaInvoiceExcelExport(SalesHeader, false);
        VerifyAddressKPPCode(Customer, ShipToAddress, KPPCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocKPPCode()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        VATLedgerCode: Code[20];
    begin
        // Copy Document KPP Code check
        CreateCustomerAndInvoice(SalesHeader, Customer, ShipToAddress);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);
        FindSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        UpdateSalesHeaderAddSheet(SalesHeader, CalcDate('<1D>', WorkDate()), WorkDate(), true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        FacturaInvoiceExcelExport(SalesHeader, false);
        FindSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VATLedgerCode := LibrarySales.CreateSalesVATLedger(WorkDate(), WorkDate(), Customer."No.");
        LibrarySales.CreateSalesVATLedgerAddSheet(VATLedgerCode);
        VerifyVATLedgerKPPCode(VATLedgerCode, ShipToAddress."KPP Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketOrderKPPCode()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Order from Blanket Order. Verify KPP Code.
        VerifyKPPCodeBlanketQuoteOrder(SalesHeader."Document Type"::"Blanket Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteKPPCode()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Order from Sales Quote. Verify KPP Code.
        VerifyKPPCodeBlanketQuoteOrder(SalesHeader."Document Type"::Quote);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceProformaBankPaymentDetails()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [GIVEN] Unposted Sales Invoice
        CreateCustomerAndInvoice(SalesHeader, Customer, ShipToAddress);

        // [WHEN] Print REP12409 "Order Proforma-Invoice (A)"
        FacturaInvoiceExcelExport(SalesHeader, true);

        // [THEN] Exported Proforma has correct Company Bank Payment details
        VerifyProformaBankPaymentSection();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        Clear(LibraryReportValidation);

        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        UpdateStockOutWarning();
        UpdateCompanyInformation();
        IsInitialized := true;
    end;

    local procedure CreateCustomerWithSubUnit(var Customer: Record Customer; var ShipToAddress1: Record "Ship-to Address")
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := LibraryUtility.GenerateGUID();
        Customer."Address 2" := LibraryUtility.GenerateGUID();
        Customer."KPP Code" := GenerateKPPCode();
        Customer.County := LibraryUtility.GenerateGUID();
        Customer.Modify(true);
        AddShipToAddress(Customer."No.", ShipToAddress1);
    end;

    local procedure GenerateKPPCode(): Code[10]
    var
        Customer: Record Customer;
    begin
        exit(
          LibraryUtility.GenerateRandomCode(Customer.FieldNo("KPP Code"), DATABASE::Customer));
    end;

    local procedure AddShipToAddress(CustomerNo: Code[20]; var ShipToAddress: Record "Ship-to Address")
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.Address := LibraryUtility.GenerateGUID();
        ShipToAddress."Address 2" := LibraryUtility.GenerateGUID();
        ShipToAddress.County := LibraryUtility.GenerateGUID();
        ShipToAddress."KPP Code" := GenerateKPPCode();
        ShipToAddress.Modify(true);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CustomerNo: Code[20]; ShipToCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemNoWithTariff(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(5));
        SalesLine.Modify(true);
        SalesHeader.Validate("Ship-to Code", ShipToCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateItemNoWithTariff(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Item.Description), 0), 1, MaxStrLen(Item.Description)));
        Item.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        Item.Validate("Tariff No.", CreateTariffNo());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateTariffNo(): Code[20]
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.Init();
        TariffNumber."No." := LibraryUtility.GenerateRandomCode(TariffNumber.FieldNo("No."), DATABASE::"Tariff Number");
        TariffNumber.Description := LibraryUtility.GenerateGUID();
        TariffNumber.Insert();
        exit(TariffNumber."No.");
    end;

    local procedure FacturaInvoiceExcelExport(SalesHeader: Record "Sales Header"; IsProforma: Boolean) FileName: Text
    var
        OrderFacturaInvoice: Report "Order Factura-Invoice (A)";
    begin
        LibraryReportValidation.SetFileName(SalesHeader."No.");
        FileName := LibraryReportValidation.GetFileName();
        Commit();
        SalesHeader.SetRange("No.", SalesHeader."No.");
        OrderFacturaInvoice.SetTableView(SalesHeader);
        OrderFacturaInvoice.InitializeRequest(1, 1, false, false, IsProforma);
        OrderFacturaInvoice.SetFileNameSilent(FileName);
        OrderFacturaInvoice.UseRequestPage(false);
        OrderFacturaInvoice.Run();
    end;

    local procedure PostedFacturaInvoiceExcelExport(DocumentNo: Code[20]) FileName: Text
    var
        SalesInvHeader: Record "Sales Invoice Header";
        PostedFacturaInvoice: Report "Posted Factura-Invoice (A)";
    begin
        LibraryReportValidation.SetFileName(DocumentNo);
        FileName := LibraryReportValidation.GetFileName();
        Commit();
        SalesInvHeader.SetRange("No.", DocumentNo);
        PostedFacturaInvoice.SetTableView(SalesInvHeader);
        PostedFacturaInvoice.SetFileNameSilent(FileName);
        PostedFacturaInvoice.UseRequestPage(false);
        PostedFacturaInvoice.Run();
    end;

    local procedure CreateCustomerAndInvoice(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    begin
        Initialize();
        CreateCustomerWithSubUnit(Customer, ShipToAddress);
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", ShipToAddress.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure SetManualKPPCode(var SalesHeader: Record "Sales Header"; KPPCode: Code[10])
    begin
        SalesHeader."KPP Code" := KPPCode;
        SalesHeader.Modify();
    end;

    local procedure FindSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("No.", DocumentNo);
        SalesHeader.FindFirst();
    end;

    local procedure UpdateStockOutWarning()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Stockout Warning" := false;
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateSalesHeaderAddSheet(var SalesHeader: Record "Sales Header"; PostingDate: Date; CorrectedDocDate: Date; AddVATLedger: Boolean)
    begin
        SalesHeader."Posting Date" := PostingDate;
        SalesHeader."Additional VAT Ledger Sheet" := AddVATLedger;
        SalesHeader."Corrected Document Date" := CorrectedDocDate;
        SalesHeader.Modify(true);
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Bank Name" := LibraryUtility.GenerateGUID();
        CompanyInformation."Bank City" := LibraryUtility.GenerateGUID();
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInformation."KPP Code" := LibraryUtility.GenerateGUID();
        CompanyInformation."Full Name" := LibraryUtility.GenerateGUID();
        CompanyInformation."Bank Branch No." := LibraryUtility.GenerateGUID();
        CompanyInformation."Bank BIC" := LibraryUtility.GenerateGUID();
        CompanyInformation."Bank Corresp. Account No." := LibraryUtility.GenerateGUID();
        CompanyInformation."Bank Account No." := LibraryUtility.GenerateGUID();
        CompanyInformation."Country/Region Code" := LibraryVATLedger.MockCountryEAEU();
        CompanyInformation.Modify();
        LibraryRUReports.UpdateCompanyAddress();
    end;

    local procedure VerifyAddressKPPCode(Customer: Record Customer; ShipToAddress: Record "Ship-to Address"; ShipToKPPCode: Code[10])
    var
        LocalReportMgt: Codeunit "Local Report Management";
        FileName: Text;
    begin
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyFactura_ConsigneeAndAddress(
              FileName,
              LocalReportMgt.GetShipToAddrName(Customer."No.", ShipToAddress.Code, ShipToAddress.Name, ShipToAddress."Name 2") + '  ' +
              LocalReportMgt.GetFullAddr(ShipToAddress."Post Code", ShipToAddress.City, ShipToAddress.Address, ShipToAddress."Address 2", '', ShipToAddress.County));
        LibraryRUReports.VerifyFactura_BuyerINN(FileName, Customer."VAT Registration No." + ' / ' + ShipToKPPCode);
    end;

    local procedure VerifyVATLedgerKPPCode(VATLedgerCode: Code[20]; KPPCode: Code[20])
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.FindSet();
        repeat
            Assert.AreEqual(KPPCode, VATLedgerLine."Reg. Reason Code", SalesVATLedgerKPPErr);
        until VATLedgerLine.Next() = 0;
    end;

    local procedure VerifyKPPCodeBlanketQuoteOrder(DocType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        SalesOrderHeader: Record "Sales Header";
        ERMVATTool: Codeunit "ERM VAT Tool - Helper";
    begin
        Initialize();
        CreateCustomerWithSubUnit(Customer, ShipToAddress);
        CreateSalesDoc(SalesHeader, DocType, Customer."No.", ShipToAddress.Code);
        ERMVATTool.MakeOrderSales(SalesHeader, SalesOrderHeader);

        Assert.AreEqual(ShipToAddress."KPP Code", SalesOrderHeader."KPP Code", SalesVATLedgerKPPErr);
    end;

    local procedure VerifyProformaBankPaymentSection()
    var
        CompanyInformation: Record "Company Information";
        LocalReportManagement: Codeunit "Local Report Management";
    begin
        CompanyInformation.Get();
        LibraryReportValidation.VerifyCellValueByRef('Y', 30, 1, CompanyInformation."Bank Name");
        // BankName
        LibraryReportValidation.VerifyCellValueByRef('Y', 31, 1, CompanyInformation."Bank City");
        // BankCity
        LibraryReportValidation.VerifyCellValueByRef('AE', 32, 1, CompanyInformation."VAT Registration No.");
        // ComapnyINN
        LibraryReportValidation.VerifyCellValueByRef('BH', 32, 1, CompanyInformation."KPP Code");
        // ComapnyKPP
        LibraryReportValidation.VerifyCellValueByRef('Y', 33, 1, LocalReportManagement.GetCompanyName());
        // ComapnyName
        LibraryReportValidation.VerifyCellValueByRef('Y', 34, 1, CompanyInformation."Bank Branch No.");
        // BankBranchNo
        LibraryReportValidation.VerifyCellValueByRef('CR', 30, 1, CompanyInformation."Bank BIC");
        // BankBIC
        LibraryReportValidation.VerifyCellValueByRef('CR', 31, 1, CompanyInformation."Bank Corresp. Account No.");
        // BankCorespAccNo
        LibraryReportValidation.VerifyCellValueByRef('CR', 33, 1, CompanyInformation."Bank Account No."); // BankAccountNo
    end;

    local procedure VerifyFacturaReportHeader(CustomerNo: Code[20])
    var
        CompanyInformation: Record "Company Information";
        LocalReportMgt: Codeunit "Local Report Management";
        FileName: Text;
    begin
        FileName := LibraryReportValidation.GetFileName();
        LibraryRUReports.VerifyFactura_SellerName(FileName, LocalReportMgt.GetCompanyName());
        LibraryRUReports.VerifyFactura_SellerAddress(FileName, LocalReportMgt.GetLegalAddress());
        CompanyInformation.Get();
        LibraryRUReports.VerifyFactura_SellerINN(
          FileName, CompanyInformation."VAT Registration No." + ' / ' + CompanyInformation."KPP Code");
        LibraryRUReports.VerifyFactura_BuyerName(FileName, LocalReportMgt.GetCustName(CustomerNo));
        LibraryRUReports.VerifyFactura_BuyerAddress(FileName, LibraryRUReports.GetCustomerFullAddress(CustomerNo));
    end;
}
