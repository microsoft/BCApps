codeunit 143018 "Library - VAT Ledger"
{
    // // [FEATURE] [VAT Ledger]
    Permissions = tabledata "Item Ledger Entry" = i,
                  tabledata "Sales Cr.Memo Header" = i,
                  tabledata "Sales Cr.Memo Line" = i,
                  tabledata "Sales Invoice Header" = i,
                  tabledata "Sales Invoice Line" = i,
                  tabledata "VAT Ledger Line" = i,
                  tabledata "VAT Ledger Line CD No." = i,
                  tabledata "VAT Ledger Line Tariff No." = i,
                  tabledata "Value Entry" = i,
                  tabledata "VAT Entry" = im;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";

    [Scope('OnPrem')]
    procedure CreateCustomerEAEU(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", MockCountryEAEU());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure MockSalesHeader(CustomerNo: Code[20]; ShipToCode: Code[10]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;
        SalesHeader."No." := LibraryUtility.GenerateGUID();
        SalesHeader."Sell-to Customer No." := CustomerNo;
        SalesHeader."Ship-to Code" := ShipToCode;
        SalesHeader.Insert();
        exit(SalesHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure MockSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
        SalesLine."Document No." := DocumentNo;
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine."Location Code" := LocationCode;
        SalesLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockSalesInvHeader(CustomerNo: Code[20]; ShipToCode: Code[10]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Sell-to Customer No." := CustomerNo;
        SalesInvoiceHeader."Ship-to Code" := ShipToCode;
        SalesInvoiceHeader.Insert();
        exit(SalesInvoiceHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure MockSalesInvLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        SalesInvoiceLine.Init();
        SalesInvoiceLine."Document No." := DocumentNo;
        SalesInvoiceLine."Line No." := LibraryUtility.GetNewRecNo(SalesInvoiceLine, SalesInvoiceLine.FieldNo("Line No."));
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::Item;
        SalesInvoiceLine."No." := ItemNo;
        SalesInvoiceLine."Location Code" := LocationCode;
        SalesInvoiceLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockSalesCrMemoHeader(CustomerNo: Code[20]; ShipToCode: Code[10]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader."Sell-to Customer No." := CustomerNo;
        SalesCrMemoHeader."Ship-to Code" := ShipToCode;
        SalesCrMemoHeader.Insert();
        exit(SalesCrMemoHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure MockSalesCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; DocumentNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        SalesCrMemoLine.Init();
        SalesCrMemoLine."Document No." := DocumentNo;
        SalesCrMemoLine."Line No." := LibraryUtility.GetNewRecNo(SalesCrMemoLine, SalesCrMemoLine.FieldNo("Line No."));
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::Item;
        SalesCrMemoLine."No." := ItemNo;
        SalesCrMemoLine."Location Code" := LocationCode;
        SalesCrMemoLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockVendorNo(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Init();
        Vendor."No." := LibraryUtility.GenerateGUID();
        Vendor.Validate("KPP Code", CopyStr(LibraryUtility.GenerateRandomXMLText(9), 1, 9));
        Vendor."VAT Registration No." := CopyStr(LibraryUtility.GenerateRandomXMLText(10), 1, 10);
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure MockCustomerNo(CountryRegionCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Init();
        Customer."No." := LibraryUtility.GenerateGUID();
        Customer."Country/Region Code" := CountryRegionCode;
        Customer.Insert();
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure MockVATLedger(var VATLedger: Record "VAT Ledger"; TypeValue: Option)
    begin
        VATLedger.Init();
        VATLedger.Type := TypeValue;
        VATLedger.Code := LibraryUtility.GenerateGUID();
        VATLedger."Start Date" := WorkDate();
        VATLedger."End Date" := WorkDate();
        VATLedger.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockVendorVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; var VendorNo: Code[20])
    begin
        VendorNo := MockVendorNo();
        MockVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Purchase, VATLedgerLine."C/V Type"::Vendor, VendorNo);
    end;

    [Scope('OnPrem')]
    procedure MockCustomerVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; var CustomerNo: Code[20])
    begin
        CustomerNo := MockCustomerNo(MockCountryEAEU());
        MockVATLedgerLine(VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerLine."C/V Type"::Customer, CustomerNo);
    end;

    [Scope('OnPrem')]
    procedure MockVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; TypeValue: Option; CVType: Option; CVNo: Code[20])
    var
        VATLedger: Record "VAT Ledger";
    begin
        MockVATLedger(VATLedger, TypeValue);
        VATLedgerLine.Init();
        VATLedgerLine.Type := VATLedger.Type;
        VATLedgerLine.Code := VATLedger.Code;
        VATLedgerLine."Line No." := LibraryUtility.GetNewRecNo(VATLedgerLine, VATLedgerLine.FieldNo("Line No."));
        VATLedgerLine."C/V Type" := CVType;
        VATLedgerLine."C/V No." := CVNo;
        VATLedgerLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockVATLedgerLineForTheGivenVATLedger(var VATLedgerLine: Record "VAT Ledger Line"; VATLedger: Record "VAT Ledger"; AddSheet: Boolean)
    begin
        VATLedgerLine.Init();
        VATLedgerLine.Type := VATLedger.Type;
        VATLedgerLine.Code := VATLedger.Code;
        VATLedgerLine."Line No." := LibraryUtility.GetNewRecNo(VATLedgerLine, VATLedgerLine.FieldNo("Line No."));
        VATLedgerLine."Additional Sheet" := AddSheet;
        VATLedgerLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockVendorVATLedgerLineWithCDNo(var VATLedgerLine: Record "VAT Ledger Line"; var CDNo: Code[50])
    begin
        CDNo := GenerateCDNoValue();
        MockVATLedgerLineWithCDNo(
          VATLedgerLine, VATLedgerLine.Type::Purchase, VATLedgerLine."C/V Type"::Vendor, MockVendorNo(), CDNo);
    end;

    [Scope('OnPrem')]
    procedure MockCustomerVATLedgerLineWithCDNo(var VATLedgerLine: Record "VAT Ledger Line"; var CDNo: Code[50])
    begin
        CDNo := GenerateCDNoValue();
        MockVATLedgerLineWithCDNo(
          VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerLine."C/V Type"::Customer, MockCustomerNo(''), CDNo);
    end;

    local procedure MockVATLedgerLineWithCDNo(var VATLedgerLine: Record "VAT Ledger Line"; Type: Option; CVType: Option; CVNo: Code[20]; CDNo: Code[50])
    begin
        MockVATLedgerLine(VATLedgerLine, Type, CVType, CVNo);
        MockVATLedgerLineCDNo(VATLedgerLine, CDNo);
    end;

    [Scope('OnPrem')]
    procedure MockVendorVATLedgerLineWithTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; var TariffNo: Code[20])
    begin
        TariffNo := MockTariffNo();
        MockVATLedgerLineWithTariffNo(
          VATLedgerLine, VATLedgerLine.Type::Purchase, VATLedgerLine."C/V Type"::Vendor, MockVendorNo(), TariffNo);
    end;

    [Scope('OnPrem')]
    procedure MockCustomerVATLedgerLineWithTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; var TariffNo: Code[20])
    begin
        TariffNo := MockTariffNo();
        MockVATLedgerLineWithTariffNo(
          VATLedgerLine, VATLedgerLine.Type::Sales, VATLedgerLine."C/V Type"::Customer, MockCustomerNo(''), TariffNo);
    end;

    local procedure MockVATLedgerLineWithTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; Type: Option; CVType: Option; CVNo: Code[20]; TariffNo: Code[20])
    begin
        MockVATLedgerLine(VATLedgerLine, Type, CVType, CVNo);
        MockVATLedgerLineTariffNo(VATLedgerLine, TariffNo);
    end;

    [Scope('OnPrem')]
    procedure MockVATLedgerLineCDNo(var VATLedgerLine: Record "VAT Ledger Line"; CDNo: Code[50])
    var
        VATLedgerLineCDNo: Record "VAT Ledger Line CD No.";
    begin
        VATLedgerLineCDNo.Init();
        VATLedgerLineCDNo.Type := VATLedgerLine.Type;
        VATLedgerLineCDNo.Code := VATLedgerLine.Code;
        VATLedgerLineCDNo."Line No." := VATLedgerLine."Line No.";
        VATLedgerLineCDNo."CD No." := CDNo;
        VATLedgerLineCDNo.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockVATLedgerLineTariffNo(var VATLedgerLine: Record "VAT Ledger Line"; TariffNo: Code[20])
    var
        VATLedgerLineTariffNo: Record "VAT Ledger Line Tariff No.";
    begin
        VATLedgerLineTariffNo.Init();
        VATLedgerLineTariffNo.Type := VATLedgerLine.Type;
        VATLedgerLineTariffNo.Code := VATLedgerLine.Code;
        VATLedgerLineTariffNo."Line No." := VATLedgerLine."Line No.";
        VATLedgerLineTariffNo."Tariff No." := TariffNo;
        VATLedgerLineTariffNo.Insert();
    end;

    [Scope('OnPrem')]
    procedure MockVendorValueEntryWithCDNo(VendorNo: Code[20]; DocumentNo: Code[20]; CDNo: Code[30])
    var
        ValueEntry: Record "Value Entry";
    begin
        MockValueEntry(ValueEntry."Source Type"::Vendor, VendorNo, DocumentNo, '', MockItemLedgerEntryNo(CDNo));
    end;

    [Scope('OnPrem')]
    procedure MockCustomerValueEntryWithCDNo(CustomerNo: Code[20]; DocumentNo: Code[20]; CDNo: Code[30])
    var
        ValueEntry: Record "Value Entry";
    begin
        MockValueEntry(ValueEntry."Source Type"::Customer, CustomerNo, DocumentNo, '', MockItemLedgerEntryNo(CDNo));
    end;

    [Scope('OnPrem')]
    procedure MockVendorValueEntryWithTariffNo(VendorNo: Code[20]; DocumentNo: Code[20]; TariffNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        MockValueEntry(ValueEntry."Source Type"::Vendor, VendorNo, DocumentNo, MockItemNo(TariffNo), MockItemLedgerEntryNo(''));
    end;

    [Scope('OnPrem')]
    procedure MockCustomerValueEntryWithTariffNo(CustomerNo: Code[20]; DocumentNo: Code[20]; TariffNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        DummyValueEntry: Record "Value Entry";
        ItemNo: Code[20];
    begin
        ItemNo := MockItemNo(TariffNo);
        MockSalesInvLine(SalesInvoiceLine, DocumentNo, ItemNo, '');
        MockValueEntry(DummyValueEntry."Source Type"::Customer, CustomerNo, DocumentNo, ItemNo, MockItemLedgerEntryNo(''));
    end;

    local procedure MockValueEntry(SourceType: Enum "Analysis Source Type"; SourceNo: Code[20]; DocumentNo: Code[20]; ItemNo: Code[20]; ItemLedgerEntryNo: Integer)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.Init();
        ValueEntry."Entry No." := LibraryUtility.GetNewRecNo(ValueEntry, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Source Type" := SourceType;
        ValueEntry."Source No." := SourceNo;
        ValueEntry."Item No." := ItemNo;
        ValueEntry."Item Ledger Entry No." := ItemLedgerEntryNo;
        ValueEntry."Document Type" := ValueEntry."Document Type"::"Sales Invoice";
        ValueEntry."Document No." := DocumentNo;
        ValueEntry."Document Line No." := 10000;
        ValueEntry.Insert();
    end;

    local procedure MockItemLedgerEntryNo(CDNo: Code[30]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Package No." := CDNo;
        ItemLedgerEntry.Insert();
        exit(ItemLedgerEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure MockPurchaseVATEntry(var DocumentNo: Code[20]; var VendorNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VendorNo := MockVendorNo();
        DocumentNo := LibraryUtility.GenerateGUID();
        MockVATEntry(VATEntry.Type::Purchase, DocumentNo, VendorNo);
    end;

    [Scope('OnPrem')]
    procedure MockSalesVATEntry(var DocumentNo: Code[20]; var CustomerNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        CustomerNo := MockCustomerNo(MockCountryEAEU());
        DocumentNo := MockSalesInvHeader(CustomerNo, '');
        MockVATEntry(VATEntry.Type::Sale, DocumentNo, CustomerNo);
    end;

    [Scope('OnPrem')]
    procedure MockPurchaseVATEntryAddSheet(var DocumentNo: Code[20]; var VendorNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VendorNo := MockVendorNo();
        DocumentNo := LibraryUtility.GenerateGUID();
        MockVATEntryAddSheet(VATEntry.Type::Purchase, DocumentNo, VendorNo);
    end;

    [Scope('OnPrem')]
    procedure MockSalesVATEntryAddSheet(var DocumentNo: Code[20]; var CustomerNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        CustomerNo := MockCustomerNo(MockCountryEAEU());
        DocumentNo := MockSalesInvHeader(CustomerNo, '');
        MockVATEntryAddSheet(VATEntry.Type::Sale, DocumentNo, CustomerNo);
    end;

    local procedure MockVATEntry(TypeValue: Enum "General Posting Type"; DocumentNo: Code[20]; CVNo: Code[20]): Integer
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry.Type := TypeValue;
        VATEntry."Posting Date" := WorkDate();
        VATEntry."VAT Reporting Date" := WorkDate();
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."Document No." := DocumentNo;
        VATEntry."Bill-to/Pay-to No." := CVNo;
        VATEntry.Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Normal VAT";
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry.Insert();
        exit(VATEntry."Entry No.");
    end;

    local procedure MockVATEntryAddSheet(TypeValue: Enum "General Posting Type"; DocumentNo: Code[20]; CVNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Get(MockVATEntry(TypeValue, DocumentNo, CVNo));
        VATEntry.Reversed := true;
        VATEntry."Corrected Document Date" := VATEntry."Posting Date";
        VATEntry."Additional VAT Ledger Sheet" := true;
        VATEntry.Modify();
    end;

    [Scope('OnPrem')]
    procedure MockItemNo(TariffNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID();
        Item."Tariff No." := TariffNo;
        Item.Insert();
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure MockTariffNo(): Code[20]
    var
        TariffNumber: Record "Tariff Number";
    begin
        TariffNumber.Init();
        TariffNumber."No." := LibraryUtility.GenerateGUID();
        TariffNumber.Insert();
        exit(TariffNumber."No.");
    end;

    [Scope('OnPrem')]
    procedure MockCountryNonEAEU(): Code[10]
    begin
        exit(MockCountry(''));
    end;

    [Scope('OnPrem')]
    procedure MockCountryEAEU(): Code[10]
    begin
        exit(MockCountry(LibraryUtility.GenerateGUID()));
    end;

    local procedure MockCountry(EAEUCountryRegionCode: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Init();
        CountryRegion.Code := LibraryUtility.GenerateGUID();
        CountryRegion."EAEU Country/Region Code" := EAEUCountryRegionCode;
        CountryRegion.Insert();
        exit(CountryRegion.Code);
    end;

    [Scope('OnPrem')]
    procedure MockLocationNonEAEU(): Code[10]
    begin
        exit(MockLocation(MockCountryNonEAEU()));
    end;

    [Scope('OnPrem')]
    procedure MockLocationEAEU(): Code[10]
    begin
        exit(MockLocation(MockCountryEAEU()));
    end;

    [Scope('OnPrem')]
    procedure MockLocation(CountryRegionCode: Code[10]): Code[10]
    var
        Location: Record Location;
    begin
        Location.Init();
        Location.Code := LibraryUtility.GenerateGUID();
        Location."Country/Region Code" := CountryRegionCode;
        Location.Insert();
        exit(Location.Code);
    end;

    [Scope('OnPrem')]
    procedure MockShipToAddressNonEAEU(CustomerNo: Code[20]): Code[10]
    begin
        exit(MockShipToAddress(CustomerNo, MockCountryNonEAEU()));
    end;

    [Scope('OnPrem')]
    procedure MockShipToAddressEAEU(CustomerNo: Code[20]): Code[10]
    begin
        exit(MockShipToAddress(CustomerNo, MockCountryEAEU()));
    end;

    [Scope('OnPrem')]
    procedure MockShipToAddress(CustomerNo: Code[20]; CountryRegionCode: Code[10]): Code[10]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        ShipToAddress.Init();
        ShipToAddress."Customer No." := CustomerNo;
        ShipToAddress.Code := LibraryUtility.GenerateGUID();
        ShipToAddress."Country/Region Code" := CountryRegionCode;
        ShipToAddress.Insert();
        exit(ShipToAddress.Code);
    end;

    [Scope('OnPrem')]
    procedure GenerateCDNoValue(): Code[30]
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomAlphabeticText(30, 0), 1, 30));
    end;

    [Scope('OnPrem')]
    procedure FindVATLedgerLine(var VATLedgerLine: Record "VAT Ledger Line"; VATLedger: Record "VAT Ledger")
    begin
        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure RunCreateVATPurchaseLedgerReport(VATLedger: Record "VAT Ledger"; VendorNo: Code[20])
    var
        CreateVATPurchaseLedger: Report "Create VAT Purchase Ledger";
    begin
        VATLedger.SetRecFilter();
        Clear(CreateVATPurchaseLedger);
        CreateVATPurchaseLedger.SetTableView(VATLedger);
        CreateVATPurchaseLedger.SetParameters(VendorNo, '', '', 0, false, true, 0, 0, true, true, false, false);
        CreateVATPurchaseLedger.UseRequestPage(false);
        CreateVATPurchaseLedger.Run();
    end;

    [Scope('OnPrem')]
    procedure RunCreateVATSalesLedgerReport(VATLedger: Record "VAT Ledger"; CustomerNo: Code[20])
    var
        CreateVATSalesLedger: Report "Create VAT Sales Ledger";
    begin
        VATLedger.SetRecFilter();
        Clear(CreateVATSalesLedger);
        CreateVATSalesLedger.SetTableView(VATLedger);
        CreateVATSalesLedger.SetParameters(CustomerNo, '', '', 0, true, true, true, false, false, false, false);
        CreateVATSalesLedger.UseRequestPage(false);
        CreateVATSalesLedger.Run();
    end;

    [Scope('OnPrem')]
    procedure RunCreateVATPurchLedAdShReport(VATLedger: Record "VAT Ledger"; VendorNo: Code[20])
    var
        CreateVATPurchLedAdSh: Report "Create VAT Purch. Led. Ad. Sh.";
    begin
        VATLedger.SetRecFilter();
        Clear(CreateVATPurchLedAdSh);
        CreateVATPurchLedAdSh.SetTableView(VATLedger);
        CreateVATPurchLedAdSh.SetParameters(VendorNo, '', '', 0, false, true, 0, 0, true, true, false, false);
        CreateVATPurchLedAdSh.UseRequestPage(false);
        CreateVATPurchLedAdSh.Run();
    end;

    [Scope('OnPrem')]
    procedure RunCreateVATSalesLedAdShReport(VATLedger: Record "VAT Ledger"; CustomerNo: Code[20])
    var
        CreateVATSalesLedAdSh: Report "Create VAT Sales Led. Ad. Sh.";
    begin
        VATLedger.SetRecFilter();
        Clear(CreateVATSalesLedAdSh);
        CreateVATSalesLedAdSh.SetTableView(VATLedger);
        CreateVATSalesLedAdSh.SetParameters(CustomerNo, '', '', 0, true, true, true, false, false, false);
        CreateVATSalesLedAdSh.UseRequestPage(false);
        CreateVATSalesLedAdSh.Run();
    end;

    [Scope('OnPrem')]
    procedure UpdateCompanyInformationEAEU()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Country/Region Code", MockCountryEAEU());
        CompanyInformation.Modify(true);
    end;
}

