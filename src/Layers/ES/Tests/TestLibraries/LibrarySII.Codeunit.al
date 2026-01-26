codeunit 143006 "Library - SII"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        SIIXMLCreator: Codeunit "SII XML Creator";
        SIIManagement: Codeunit "SII Management";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        SiiTxt: Label 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroInformacion.xsd', Locked = true;
        SiiLRTxt: Label 'https://www2.agenciatributaria.gob.es/static_files/common/internet/dep/aplicaciones/es/aeat/ssii/fact/ws/SuministroLR.xsd', Locked = true;
        SoapenvUrlTok: Label 'http://schemas.xmlsoap.org/soap/envelope/';
        XPathSalesIDFacturaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:IDFactura/';
        XPathPurchIDFacturaTok: Label '//soapenv:Body/siiLR:SuministroLRFacturasRecibidas/siiLR:RegistroLRFacturasRecibidas/siiLR:IDFactura/';

    [Scope('OnPrem')]
    procedure InitSetup(Enabled: Boolean; EnableBatchSubmissions: Boolean)
    var
        SIISetup: Record "SII Setup";
        CompanyInformation: Record "Company Information";
    begin
        if not SIISetup.Get() then begin
            SIISetup.Init();
            SIISetup.Insert(true);
        end;
        SIISetup.Enabled := Enabled;
        SIISetup."Enable Batch Submissions" := EnableBatchSubmissions;
        SIISetup.Modify(true);

        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := GetLocalVATRegNo();
        CompanyInformation.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure ShowAdvancedActions(ShowAdvancedActions: Boolean)
    var
        SIISetup: Record "SII Setup";
    begin
        if not SIISetup.Get() then begin
            SIISetup.Init();
            SIISetup.Insert(true);
        end;
        SIISetup."Show Advanced Actions" := ShowAdvancedActions;
        SIISetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure BindSubscriptionJobQueue()
    begin
        BindSubscription(LibraryJobQueue);
    end;

    [Scope('OnPrem')]
    procedure MockPendingHistoryEntry(var SIIHistory: Record "SII History")
    begin
        MockHistoryEntry(SIIHistory, SIIHistory.Status::Pending);
    end;

    [Scope('OnPrem')]
    procedure MockAcceptedHistoryEntry(var SIIHistory: Record "SII History")
    begin
        MockHistoryEntry(SIIHistory, SIIHistory.Status::Accepted);
    end;

    [Scope('OnPrem')]
    procedure MockHistoryEntry(var SIIHistory: Record "SII History"; NewStatus: Enum "SII Document Status")
    var
        SIIDocUploadState: Record "SII Doc. Upload State";
        DocumentNo: Code[20];
    begin
        DocumentNo := MockSalesInvoice('');
        SIIDocUploadState.CreateNewRequest(
          MockCLE(DocumentNo), SIIDocUploadState."Document Source"::"Customer Ledger".AsInteger(), SIIDocUploadState."Document Type"::Invoice.AsInteger(), DocumentNo, '', WorkDate());
        SIIDocUploadState.SetRange("Document No.", DocumentNo);
        SIIDocUploadState.FindFirst();
        SIIDocUploadState.Status := NewStatus;
        SIIDocUploadState.Modify();

        SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
        SIIHistory.FindFirst();
        SIIHistory.Status := NewStatus;
        SIIHistory.Modify();
    end;

    [Scope('OnPrem')]
    procedure MockCLE(DocumentNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := LibrarySales.CreateCustomerNo();
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."VAT Reporting Date" := WorkDate();
        CustLedgerEntry."Document No." := DocumentNo;
        CustLedgerEntry.Insert();
        exit(CustLedgerEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure MockVLE(DocumentNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := LibraryPurchase.CreateVendorNo();
        VendorLedgerEntry."Posting Date" := WorkDate();
        VendorLedgerEntry."VAT Reporting Date" := WorkDate();
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure MockSalesInvoice(ExternalDocumentNo: Code[35]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader."Bill-to Customer No." := LibrarySales.CreateCustomerNo();
        SalesInvoiceHeader."External Document No." := ExternalDocumentNo;
        SalesInvoiceHeader.Insert();
        exit(SalesInvoiceHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure MockSalesCrMemo(CorrectionType: Option): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader."Correction Type" := CorrectionType;
        SalesCrMemoHeader.Insert();
        exit(SalesCrMemoHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure MockServiceCrMemo(CorrectionType: Option): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.Init();
        ServiceCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        ServiceCrMemoHeader."Correction Type" := CorrectionType;
        ServiceCrMemoHeader.Insert();
        exit(ServiceCrMemoHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure MockPurchaseCrMemo(CorrectionType: Option): Code[20]
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.Init();
        PurchCrMemoHdr."No." := LibraryUtility.GenerateGUID();
        PurchCrMemoHdr."Correction Type" := CorrectionType;
        PurchCrMemoHdr.Insert();
        exit(PurchCrMemoHdr."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateVendor(VendorCountryCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendWithCountryAndVATReg(Vendor, VendorCountryCode, LibraryERM.GenerateVATRegistrationNo(VendorCountryCode));
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateCustomer(CustomerCountryCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        CreateCustWithCountryAndVATReg(Customer, CustomerCountryCode, LibraryERM.GenerateVATRegistrationNo(CustomerCountryCode));
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateCustWithVATSetup(var Customer: Record Customer)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateCustWithCountryAndVATReg(Customer, '', GetLocalVATRegNo());
        Customer.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateForeignCustWithVATSetup(var Customer: Record Customer)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateCustWithCountryAndVATReg(Customer, GetForeignCountry(), GetForeignVATRegNo());
        Customer.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateForeignVendWithVATSetup(var Vendor: Record Vendor)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVendWithCountryAndVATReg(Vendor, GetForeignCountry(), GetForeignVATRegNo());
        Vendor.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        Vendor.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateCustWithCountryAndVATReg(var Customer: Record Customer; CustomerCountryCode: Code[10]; VATRegNo: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CustomerCountryCode);
        Customer."VAT Registration No." := VATRegNo;
        Customer.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendWithCountryAndVATReg(var Vendor: Record Vendor; VendorCountryCode: Code[10]; VATRegNo: Code[20])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Country/Region Code" := VendorCountryCode;
        Vendor."VAT Registration No." := VATRegNo;
        Vendor.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendWithVATSetup(VATBusPostGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendWithCountryAndVATReg(Vendor, 'ES', GetLocalVATRegNo());
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var VATProductPostingGroup: Record "VAT Product Posting Group"; VATBusinessPostingGroup: Record "VAT Business Posting Group"; VATCalculationType: Enum "Tax Calculation Type"; VATRate: Decimal; EUService: Boolean)
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("VAT %", VATRate);
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSpecificVATSetup(VATBusPostGroupCode: Code[20]; VATPct: Decimal): Code[20]
    begin
        exit(CreateSpecificVATSetupEUService(VATBusPostGroupCode, VATPct, false));
    end;

    [Scope('OnPrem')]
    procedure CreateSpecificVATSetupEUService(VATBusPostGroupCode: Code[20]; VATPct: Decimal; EUService: Boolean): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Normal VAT";
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("VAT Identifier",
          LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Modify(true);

        exit(VATProductPostingGroup.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateItemWithSpecificVATSetup(VATBusPostGroupCode: Code[20]; VATPct: Decimal): Code[20]
    var
        Item: Record Item;
        VATProductPostingGroupCode: Code[20];
    begin
        VATProductPostingGroupCode := CreateSpecificVATSetup(VATBusPostGroupCode, VATPct);

        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateItemWithSpecificVATSetupEUService(VATBusPostGroupCode: Code[20]; VATPct: Decimal; EUService: Boolean): Code[20]
    var
        Item: Record Item;
        VATProductPostingGroupCode: Code[20];
    begin
        VATProductPostingGroupCode := CreateSpecificVATSetupEUService(VATBusPostGroupCode, VATPct, EUService);

        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateItemNoWithSpecificVATSetup(VATProductPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateSpecificNoTaxableVATSetup(VATBusPostGroupCode: Code[20]; EUService: Boolean; NonTaxableType: Option): Code[20]
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATBusinessPostingGroup.Get(VATBusPostGroupCode);
        CreateVATPostingSetup(
          VATPostingSetup, VATProductPostingGroup, VATBusinessPostingGroup,
          VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", 0, EUService);
        VATPostingSetup.Validate("No Taxable Type", NonTaxableType);
        VATPostingSetup.Modify(true);

        exit(VATProductPostingGroup.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateNormalWithNoTaxableVATSetup(VATBusPostGroupCode: Code[20]; EUService: Boolean; NonTaxableType: Option): Code[20]
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATBusinessPostingGroup.Get(VATBusPostGroupCode);
        CreateVATPostingSetup(
          VATPostingSetup, VATProductPostingGroup, VATBusinessPostingGroup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0, EUService);
        VATPostingSetup.Validate("No Taxable Type", NonTaxableType);
        VATPostingSetup.Modify(true);

        exit(VATProductPostingGroup.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateVATPostingSetupWithSIIExemptVATClause(VATBusPostGroupCode: Code[20]; ExemptionCode: Enum "SII Exemption Code"): Code[20]
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("VAT Identifier",
          LibraryUtility.GenerateRandomCode(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("VAT Clause Code", CreateVATClauseWithSIIExemptionCode(ExemptionCode));
        VATPostingSetup.Modify(true);
        exit(VATProductPostingGroup.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateVATClauseWithSIIExemptionCode(ExemptionCode: Enum "SII Exemption Code"): Code[20]
    var
        VATClause: Record "VAT Clause";
    begin
        LibraryERM.CreateVATClause(VATClause);
        VATClause.Validate("SII Exemption Code", ExemptionCode);
        VATClause.Modify(true);
        exit(VATClause.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesLineWithUnitPrice(SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        UpdateUnitPriceSalesLine(SalesLine, LibraryRandom.RandDec(100, 2));
    end;

    [Scope('OnPrem')]
    procedure CreatePurchLineWithSetup(var VATRate: Decimal; var Amount: Decimal; PurchaseHeader: Record "Purchase Header"; VATBusinessPostingGroup: Record "VAT Business Posting Group"; VATCalculationType: Enum "Tax Calculation Type")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
        UnitCost: Decimal;
        Quantity: Decimal;
    begin
        UnitCost := LibraryRandom.RandDec(10000.0, 1);
        Quantity := LibraryRandom.RandIntInRange(1, 100);
        VATRate := LibraryRandom.RandDec(99.0, 1);
        Amount := UnitCost * Quantity;

        CreateVATPostingSetup(VATPostingSetup, VATProductPostingGroup, VATBusinessPostingGroup, VATCalculationType, VATRate, true);

        Library340347Declaration.CreateItem(Item, VATProductPostingGroup.Code);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePurchLineWithUnitCost(PurchHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        UpdateDirectUnitCostPurchaseLine(PurchLine, LibraryRandom.RandInt(100));
    end;

    [Scope('OnPrem')]
    procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type"; CustNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, CustNo);
        ServiceHeader.Validate("Posting Date", WorkDate());
        ServiceHeader.Validate("Order Date", WorkDate());
        ServiceHeader.Validate("Currency Code", CurrencyCode);
        ServiceHeader.Validate("Operation Description", LibraryUtility.GenerateGUID());
        ServiceHeader.Validate("Operation Description 2", LibraryUtility.GenerateGUID());
        ServiceHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateServiceLineWithUnitPrice(ServiceHeader: Record "Service Header"; ItemNo: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDocWithVATClauseOnDate(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; PostingDate: Date; CorrectionType: Option)
    begin
        CreateSalesWithVATClause(SalesHeader, DocType, PostingDate, CorrectionType);
    end;

    [Scope('OnPrem')]
    procedure CreateSalesDocWithVATClause(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CorrectionType: Option)
    begin
        CreateSalesWithVATClause(SalesHeader, DocType, WorkDate(), CorrectionType);
    end;

    local procedure CreateSalesWithVATClause(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; PostingDate: Date; CorrectionType: Option)
    var
        VATClause: Record "VAT Clause";
    begin
        CreateSalesWithSpecificVATClause(
          SalesHeader, DocType, PostingDate, CorrectionType, VATClause."SII Exemption Code"::"E6 Exempt on other grounds");
    end;

    [Scope('OnPrem')]
    procedure CreateSalesWithSpecificVATClause(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; PostingDate: Date; CorrectionType: Option; ExemptionCode: Enum "SII Exemption Code")
    var
        Customer: Record Customer;
        ItemNo: Code[20];
    begin
        CreateCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Correction Type", CorrectionType);
        SalesHeader.Modify(true);
        ItemNo :=
          CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSIIExemptVATClause(Customer."VAT Bus. Posting Group", ExemptionCode));
        CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);
    end;

    [Scope('OnPrem')]
    procedure UpdateUnitPriceSalesLine(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateDirectUnitCostPurchaseLine(var PurchaseLine: Record "Purchase Line"; DirectUnitCost: Decimal)
    begin
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostSalesCrMemo(CustomerNo: Code[20]; CreditMemoType: Option " ",Replacement,Difference,Removal; ItemNo: Code[20]; AddCorrectedInvoiceNo: Boolean): Code[20]
    var
        SalesHeaderCrMemo: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLine: Record "Sales Line";
        QuantityInvoice: Decimal;
        PriceInvoice: Decimal;
    begin
        QuantityInvoice := LibraryRandom.RandDec(100, 2);
        PriceInvoice := LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeaderInvoice, SalesLine,
          SalesHeaderInvoice."Document Type"::Invoice, CustomerNo,
          ItemNo, QuantityInvoice, '', WorkDate());
        UpdateUnitPriceSalesLine(SalesLine, PriceInvoice);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeaderCrMemo, SalesLine,
          SalesHeaderCrMemo."Document Type"::"Credit Memo", CustomerNo,
          ItemNo, LibraryRandom.RandDec(QuantityInvoice div 1, 2), '', WorkDate());
        SalesHeaderCrMemo.Validate("Operation Description", LibraryUtility.GenerateGUID());
        SalesHeaderCrMemo.Validate("Operation Description 2", LibraryUtility.GenerateGUID());
        SalesHeaderCrMemo.Modify(true);
        UpdateUnitPriceSalesLine(SalesLine, PriceInvoice);

        SalesHeaderCrMemo.CalcFields(Amount);
        SalesHeaderInvoice.CalcFields(Amount);
        SalesHeaderCrMemo.CalcFields("Amount Including VAT");
        SalesHeaderInvoice.CalcFields("Amount Including VAT");

        if CreditMemoType = CreditMemoType::Difference then begin
            LibraryVariableStorage.Enqueue(SalesLine."VAT %");

            // Minus sign because credit memo for sales are positive when we send money back to the customer
            LibraryVariableStorage.Enqueue(-SalesHeaderCrMemo.Amount);
            LibraryVariableStorage.Enqueue(-SalesHeaderCrMemo."Amount Including VAT" +
              SalesHeaderCrMemo.Amount);
        end else
            if CreditMemoType = CreditMemoType::Replacement then begin
                LibraryVariableStorage.Enqueue(SalesLine."VAT %");
                LibraryVariableStorage.Enqueue(
                  Abs(SalesHeaderInvoice.Amount - SalesHeaderCrMemo.Amount));
                LibraryVariableStorage.Enqueue(
                  Abs(SalesHeaderInvoice."Amount Including VAT" - SalesHeaderInvoice.Amount) -
                  Abs(SalesHeaderCrMemo."Amount Including VAT" - SalesHeaderCrMemo.Amount));
            end;

        if AddCorrectedInvoiceNo then begin
            SalesHeaderCrMemo."Corrected Invoice No." := LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, false);
            SalesHeaderCrMemo.Modify();
        end;

        exit(LibrarySales.PostSalesDocument(SalesHeaderCrMemo, false, false));
    end;

    [Scope('OnPrem')]
    procedure CreatePostSalesInvoiceEU(var VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        Customer.Get(CustomerNo);
        VATBusinessPostingGroup.Get(Customer."VAT Bus. Posting Group");
        CreateVATPostingSetup(
          VATPostingSetup, VATProductPostingGroup, VATBusinessPostingGroup,
          VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 20), true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::" "), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    [Scope('OnPrem')]
    procedure CreatePurchDocumentWithDiffPayToVendor(IsInvoice: Boolean; PayToVendorNo: Code[20]; VendorNo: Code[20]; CreditMemoType: Option " ",Replacement,Difference,Removal; AddCorrectedInvoiceNo: Boolean): Code[20]
    var
        PurchaseHeaderCrMemo: Record "Purchase Header";
        Item: Record Item;
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QuantityInvoice: Decimal;
        PriceInvoice: Decimal;
    begin
        if IsInvoice then begin
            LibraryPurchase.CreatePurchaseDocumentWithItem(
              PurchaseHeaderInvoice, PurchaseLine,
              PurchaseHeaderInvoice."Document Type"::Invoice, VendorNo,
              LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());
            PurchaseHeaderInvoice.Validate("Pay-to Vendor No.", PayToVendorNo);
            PurchaseHeaderInvoice.Modify(true);
            exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, false));
        end;

        LibraryInventory.CreateItem(Item);
        QuantityInvoice := LibraryRandom.RandDec(100, 2);
        PriceInvoice := LibraryRandom.RandDec(100, 2);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeaderInvoice, PurchaseLine,
          PurchaseHeaderInvoice."Document Type"::Invoice, VendorNo,
          Item."No.", QuantityInvoice, '', WorkDate());
        PurchaseHeaderInvoice.Validate("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeaderInvoice.Modify(true);
        UpdateDirectUnitCostPurchaseLine(PurchaseLine, PriceInvoice);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeaderCrMemo, PurchaseLine,
          PurchaseHeaderCrMemo."Document Type"::"Credit Memo", VendorNo,
          Item."No.", LibraryRandom.RandDec(100, 2), '', WorkDate());
        PurchaseHeaderCrMemo.Validate("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeaderCrMemo.Validate("Operation Description", LibraryUtility.GenerateGUID());
        PurchaseHeaderCrMemo.Validate("Operation Description 2", LibraryUtility.GenerateGUID());
        PurchaseHeaderCrMemo.Modify(true);
        UpdateDirectUnitCostPurchaseLine(PurchaseLine, PriceInvoice);

        PurchaseHeaderInvoice.CalcFields(Amount);
        PurchaseHeaderCrMemo.CalcFields(Amount);
        PurchaseHeaderInvoice.CalcFields("Amount Including VAT");
        PurchaseHeaderCrMemo.CalcFields("Amount Including VAT");

        if CreditMemoType in [CreditMemoType::" ", CreditMemoType::Difference] then begin
            LibraryVariableStorage.Enqueue(PurchaseLine."VAT %");
            LibraryVariableStorage.Enqueue(PurchaseHeaderCrMemo.Amount);
            LibraryVariableStorage.Enqueue(PurchaseHeaderCrMemo."Amount Including VAT" - PurchaseHeaderCrMemo.Amount);
        end else
            if CreditMemoType = CreditMemoType::Replacement then begin
                LibraryVariableStorage.Enqueue(PurchaseLine."VAT %");

                LibraryVariableStorage.Enqueue(PurchaseHeaderCrMemo.Amount - PurchaseHeaderInvoice.Amount);
                LibraryVariableStorage.Enqueue(
                  PurchaseHeaderCrMemo."Amount Including VAT" - PurchaseHeaderInvoice."Amount Including VAT" -
                  PurchaseHeaderCrMemo.Amount + PurchaseHeaderInvoice.Amount);
            end;

        if AddCorrectedInvoiceNo then begin
            PurchaseHeaderCrMemo."Corrected Invoice No." := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, false);
            PurchaseHeaderCrMemo.Modify();
        end;

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, false, false));
    end;

    [Scope('OnPrem')]
    procedure CreatePurchDocWithReverseChargeVAT(var PurchaseHeader: Record "Purchase Header"; var VATRate: Decimal; var Amount: Decimal; DocType: Enum "Purchase Document Type"; CountryRegion: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        CreatePurchHeaderWithSetup(PurchaseHeader, VATBusinessPostingGroup, DocType, CountryRegion);
        CreatePurchLineWithSetup(
          VATRate, Amount, PurchaseHeader, VATBusinessPostingGroup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
    end;

    [Scope('OnPrem')]
    procedure CreatePurchHeaderWithSetup(var PurchaseHeader: Record "Purchase Header"; var VATBusinessPostingGroup: Record "VAT Business Posting Group"; DocType: Enum "Purchase Document Type"; CountryRegion: Code[10])
    var
        Vendor: Record Vendor;
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        Library340347Declaration.CreateVendor(Vendor, VATBusinessPostingGroup.Code);
        Vendor."VAT Registration No." := GetLocalVATRegNo();
        Vendor."Country/Region Code" := CountryRegion;
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, Vendor."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PostSalesDocWithNoTaxableVATOnDate(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; PostingDate: Date; EUService: Boolean; NonTaxableType: Option)
    begin
        PostSalesWithNoTaxableVAT(CustLedgerEntry, DocType, PostingDate, EUService, NonTaxableType);
    end;

    [Scope('OnPrem')]
    procedure PostSalesDocWithNoTaxableVAT(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; EUService: Boolean; NonTaxableType: Option)
    begin
        PostSalesWithNoTaxableVAT(CustLedgerEntry, DocType, WorkDate(), EUService, NonTaxableType);
    end;

    [Scope('OnPrem')]
    procedure PostSalesDocWithVATClauseOnDate(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; PostingDate: Date; CorrectionType: Option)
    begin
        PostSalesWithVATClause(CustLedgerEntry, DocType, PostingDate, CorrectionType);
    end;

    [Scope('OnPrem')]
    procedure PostSalesDocWithVATClause(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrectionType: Option)
    begin
        PostSalesWithVATClause(CustLedgerEntry, DocType, WorkDate(), CorrectionType);
    end;

    local procedure PostSalesWithVATClause(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; PostingDate: Date; CorrectionType: Option)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesWithVATClause(SalesHeader, DocType, PostingDate, CorrectionType);
        CustLedgerEntry.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure PostSalesWithNoTaxableVAT(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; PostingDate: Date; EUService: Boolean; NonTaxableType: Option)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        if EUService then
            CreateForeignCustWithVATSetup(Customer)
        else
            CreateCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        ItemNo :=
          CreateItemNoWithSpecificVATSetup(
            CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", EUService,
              NonTaxableType));
        CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);
        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    [Scope('OnPrem')]
    procedure PostSalesInvWithMultiplesLinesDiffVAT(var CustLedgerEntry: Record "Cust. Ledger Entry"; AddNoTaxableLine: Boolean)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
        i: Integer;
    begin
        CreateCustWithVATSetup(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            CreateSalesLineWithUnitPrice(
              SalesHeader, CreateItemWithSpecificVATSetup(Customer."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)));

        if AddNoTaxableLine then begin
            ItemNo :=
              CreateItemNoWithSpecificVATSetup(
                CreateSpecificNoTaxableVATSetup(Customer."VAT Bus. Posting Group", false, 0));
            CreateSalesLineWithUnitPrice(SalesHeader, ItemNo);
        end;

        CustLedgerEntry.SetRange("Sell-to Customer No.", Customer."No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    [Scope('OnPrem')]
    procedure PostServiceDocWithNonTaxableVAT(DocType: Enum "Service Document Type"; NonTaxableType: Option): Code[20]
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ItemNo: Code[20];
    begin
        CreateCustWithVATSetup(Customer);
        CreateServiceHeader(ServiceHeader, DocType, Customer."No.", '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ItemNo :=
          CreateItemNoWithSpecificVATSetup(
            CreateSpecificNoTaxableVATSetup(ServiceHeader."VAT Bus. Posting Group", false, NonTaxableType));
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure PostServDocWithCurrency(DocType: Enum "Service Document Type"; CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        CreateCustWithVATSetup(Customer);
        CreateServiceHeader(ServiceHeader, DocType, Customer."No.", CurrencyCode);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          CreateItemWithSpecificVATSetup(ServiceHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(10, 25)),
          LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        exit(ServiceHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure SetupXMLNamespaces()
    begin
        LibraryXPathXMLReader.SetDefaultNamespaceUsage(false);
        LibraryXPathXMLReader.AddAdditionalNamespace('soapenv', SoapenvUrlTok);
        LibraryXPathXMLReader.AddAdditionalNamespace('siiRL', SiiLRTxt);
        LibraryXPathXMLReader.AddAdditionalNamespace('siiLR', SiiLRTxt);
        LibraryXPathXMLReader.AddAdditionalNamespace('sii', SiiTxt);
    end;

    [Scope('OnPrem')]
    procedure GetInetRoot(): Text
    begin
        exit(ApplicationPath + '\..\..\..\');
    end;

    local procedure GetSignOfVATEntry(DocType: Enum "Gen. Journal Document Type"): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        if DocType = VATEntry."Document Type"::"Credit Memo" then
            exit(-1);
        exit(1);
    end;

    [Scope('OnPrem')]
    procedure GetLocalVATRegNo(): Code[20]
    begin
        exit('B80833593');
    end;

    [Scope('OnPrem')]
    procedure GetForeignCountry(): Code[10]
    begin
        exit('FR');
    end;

    [Scope('OnPrem')]
    procedure GetForeignVATRegNo(): Code[20]
    begin
        exit('FR01234567890');
    end;

    [Scope('OnPrem')]
    procedure FindCustLedgEntryForPostedServInvoice(var CustLedgerEntry: Record "Cust. Ledger Entry"; ServInvNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Pre-Assigned No.", ServInvNo);
        ServiceInvoiceHeader.FindFirst();
        CustLedgerEntry.SetRange("Sell-to Customer No.", ServiceInvoiceHeader."Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, ServiceInvoiceHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure FindCustLedgEntryForPostedServCrMemo(var CustLedgerEntry: Record "Cust. Ledger Entry"; ServCrMemoNo: Code[20])
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", ServCrMemoNo);
        ServiceCrMemoHeader.FindFirst();
        CustLedgerEntry.SetRange("Sell-to Customer No.", ServiceCrMemoHeader."Customer No.");
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", ServiceCrMemoHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure FindSIIDocUploadState(var SIIDocUploadState: Record "SII Doc. Upload State"; DocumentSource: Enum "SII Doc. Upload State Document Source"; DocumentType: Enum "SII Doc. Upload State Document Type"; DocumentNo: Code[20])
    begin
        SIIDocUploadState.SetRange("Document Source", DocumentSource);
        SIIDocUploadState.SetRange("Document Type", DocumentType);
        SIIDocUploadState.SetRange("Document No.", DocumentNo);
        SIIDocUploadState.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure CalculateVATEntries(var TempReturnVATEntry: Record "VAT Entry" temporary; DocumentNo: Code[20]; PostingDate: Date; TransactionNo: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.SetRange("Transaction No.", TransactionNo);
        VATEntry.SetFilter("VAT %", '>0');
        VATEntry.SetRange("Ignore In SII", false);
        if VATEntry.FindSet() then
            repeat
                TempReturnVATEntry.SetRange("VAT %");
                TempReturnVATEntry.SetRange("VAT %", VATEntry."VAT %");
                if TempReturnVATEntry.FindFirst() then begin
                    TempReturnVATEntry.Amount += Abs(VATEntry.Amount + VATEntry."Unrealized Amount");
                    TempReturnVATEntry.Base += Abs(VATEntry.Base + VATEntry."Unrealized Base");
                    TempReturnVATEntry.Modify();
                end else begin
                    TempReturnVATEntry.Init();
                    TempReturnVATEntry.Copy(VATEntry);
                    TempReturnVATEntry.Amount := Abs(TempReturnVATEntry.Amount + TempReturnVATEntry."Unrealized Amount");
                    TempReturnVATEntry.Base := Abs(TempReturnVATEntry.Base + TempReturnVATEntry."Unrealized Base");
                    TempReturnVATEntry.Insert();
                end;
            until VATEntry.Next() = 0;

        if VATEntry."Document Type" = VATEntry."Document Type"::Invoice then begin
            TempReturnVATEntry.Reset();
            TempReturnVATEntry.SetCurrentKey("VAT %", "EC %");
            if TempReturnVATEntry.FindSet() then
                repeat
                    LibraryVariableStorage.Enqueue(TempReturnVATEntry."VAT %");
                    LibraryVariableStorage.Enqueue(TempReturnVATEntry.Base);
                    LibraryVariableStorage.Enqueue(TempReturnVATEntry.Amount);
                until TempReturnVATEntry.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure CalculateServiceInvoiceAmount(ServiceInvoiceHeader: Record "Service Invoice Header"): Decimal
    var
        ServiceInvoiceLine: Record "Service Invoice Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.CalcSums(Amount);
        exit(
          Round(ServiceInvoiceLine.Amount /
            CurrencyExchangeRate.ExchangeRate(ServiceInvoiceHeader."Posting Date", ServiceInvoiceHeader."Currency Code")));
    end;

    [Scope('OnPrem')]
    procedure CalculateServiceCrMemoAmount(ServiceCrMemoHeader: Record "Service Cr.Memo Header"): Decimal
    var
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        ServiceCrMemoLine.SetRange("Document No.", ServiceCrMemoHeader."No.");
        ServiceCrMemoLine.CalcSums(Amount);
        exit(
          Round(ServiceCrMemoLine.Amount /
            CurrencyExchangeRate.ExchangeRate(ServiceCrMemoHeader."Posting Date", ServiceCrMemoHeader."Currency Code")));
    end;

    [Scope('OnPrem')]
    procedure CalcSalesNoTaxableAmount(CustLedgerEntry: Record "Cust. Ledger Entry"): Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempVATEntry: Record "VAT Entry" temporary;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        InvoiceAmount: Decimal;
        VatBaseAmount: Decimal;
    begin
        CalculateVATEntries(
          TempVATEntry, CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date", CustLedgerEntry."Transaction No.");
        LibraryVariableStorage.Clear();
        if TempVATEntry.FindSet() then
            repeat
                VatBaseAmount += TempVATEntry.Base;
            until TempVATEntry.Next() = 0;

        case true of
            SalesInvoiceHeader.Get(CustLedgerEntry."Document No."):
                begin
                    SalesInvoiceHeader.CalcFields(Amount);
                    InvoiceAmount :=
                      Round(SalesInvoiceHeader.Amount /
                        CurrencyExchangeRate.ExchangeRate(SalesInvoiceHeader."Posting Date", SalesInvoiceHeader."Currency Code"));
                end;
            ServiceInvoiceHeader.Get(CustLedgerEntry."Document No."):
                InvoiceAmount := CalculateServiceInvoiceAmount(ServiceInvoiceHeader);
            SalesCrMemoHeader.Get(CustLedgerEntry."Document No."):
                begin
                    SalesCrMemoHeader.CalcFields(Amount);
                    InvoiceAmount :=
                      Round(SalesCrMemoHeader.Amount /
                        CurrencyExchangeRate.ExchangeRate(SalesCrMemoHeader."Posting Date", SalesCrMemoHeader."Currency Code"));
                end;
            ServiceCrMemoHeader.Get(CustLedgerEntry."Document No."):
                InvoiceAmount := CalculateServiceCrMemoAmount(ServiceCrMemoHeader);
        end;
        exit(InvoiceAmount - VatBaseAmount);
    end;

    [Scope('OnPrem')]
    procedure DisableCashBased(VATPostingSetup: Record "VAT Posting Setup")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        VATPostingSetup.Delete();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", false);
        GeneralLedgerSetup.Validate("Unrealized VAT", false);
        GeneralLedgerSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure PageSIIHistory_Retry(SIIHistory: Record "SII History")
    var
        PageSIIHistory: TestPage "SII History";
    begin
        PageSIIHistory.OpenEdit();
        PageSIIHistory.GotoRecord(SIIHistory);
        PageSIIHistory.Retry.Invoke();
    end;

    [Scope('OnPrem')]
    procedure PageSIIHistory_RetryAll(SIIHistory: Record "SII History")
    var
        PageSIIHistory: TestPage "SII History";
    begin
        PageSIIHistory.OpenEdit();
        PageSIIHistory.GotoRecord(SIIHistory);
        PageSIIHistory."Retry All".Invoke();
    end;

    [Scope('OnPrem')]
    procedure PageSIIHistory_RetryAccepted(SIIHistory: Record "SII History")
    var
        PageSIIHistory: TestPage "SII History";
    begin
        PageSIIHistory.OpenEdit();
        PageSIIHistory.GotoRecord(SIIHistory);
        PageSIIHistory."Retry Accepted".Invoke();
    end;

    [Scope('OnPrem')]
    procedure ValidateXmlAgainstXsdSchema(XMLDoc: DotNet XmlDocument)
    var
        FileManagement: Codeunit "File Management";
        LibraryVerifyXMLSchema: Codeunit "Library - Verify XML Schema";
        XmlStream: OutStream;
        XmlFile: File;
        XmlPath: Text;
        XsdPath: Text;
        Message: Text;
    begin
        XmlPath := FileManagement.ServerTempFileName('xml');
        XmlFile.Create(XmlPath);
        XmlFile.CreateOutStream(XmlStream);
        XMLDoc.Save(XmlStream);
        XmlFile.Close();

        XsdPath := GetInetRoot() + '\GDL\ES\App\Test\SIIxmlschema\SuministroLR.xsd';
        Assert.IsTrue(LibraryVerifyXMLSchema.VerifyXMLAgainstSchema(XmlPath, XsdPath, Message), Message);
    end;

    [Scope('OnPrem')]
    procedure ValidateElementByName(XMLDoc: DotNet XmlDocument; ElementName: Text; ExpectedValue: Text)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        i: Integer;
        AssertMsg: Text;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(ElementName);
        Assert.IsTrue(XMLNodeList.Count > 0, StrSubstNo('No elements found with name %1', ElementName));
        for i := 0 to XMLNodeList.Count - 1 do begin
            XMLNode := XMLNodeList.Item(i);
            AssertMsg := StrSubstNo('Value is invalid for element : %1', ElementName);
            Assert.AreEqual(ExpectedValue, Format(XMLNode.InnerText), AssertMsg);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateElementByNameAt(XMLDoc: DotNet XmlDocument; ElementName: Text; ExpectedValue: Text; Position: Integer)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        AssertMsg: Text;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(ElementName);
        XMLNode := XMLNodeList.Item(Position);
        AssertMsg := StrSubstNo('Value is invalid for element : %1', ElementName);
        Assert.AreEqual(ExpectedValue, Format(XMLNode.InnerText), AssertMsg);
    end;

    [Scope('OnPrem')]
    procedure ValidateNoElementsByName(XMLDoc: DotNet XmlDocument; ElementName: Text)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(ElementName);
        Assert.AreEqual(0, XMLNodeList.Count, StrSubstNo('Element %1 exists in XML file', ElementName));
    end;

    [Scope('OnPrem')]
    procedure ValidateElementWithNameExists(XMLDoc: DotNet XmlDocument; ElementName: Text)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(ElementName);
        Assert.IsTrue(XMLNodeList.Count > 0, StrSubstNo('Element %1 exists in XML file', ElementName));
    end;

    [Scope('OnPrem')]
    procedure VerifyCountOfElements(XMLDoc: DotNet XmlDocument; ElementName: Text; ExpectedCount: Integer)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(ElementName);
        Assert.AreEqual(ExpectedCount, XMLNodeList.Count, 'Incorrect count of elements');
    end;

    [Scope('OnPrem')]
    procedure VerifyXml(XMLDoc: DotNet XmlDocument; LedgerEntry: Variant; XmlType: Option Invoice,"Intra Community",Payment; IsCashBasedVAT: Boolean; IsSelfEmployed: Boolean)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempVATEntry: Record "VAT Entry" temporary;
        RecordRef: RecordRef;
    begin
        ValidateXmlAgainstXsdSchema(XMLDoc);
        VerifyXMLHeader(XMLDoc);

        RecordRef.GetTable(LedgerEntry);

        case RecordRef.Number of
            DATABASE::"Cust. Ledger Entry":
                begin
                    RecordRef.SetTable(CustLedgerEntry);
                    if XmlType = XmlType::Invoice then
                        CalculateVATEntries(
                          TempVATEntry, CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date", CustLedgerEntry."Transaction No.");
                    CustLedgerEntry.CalcFields(Amount);
                    VerifyXMLForSalesLedger(
                      XMLDoc, TempVATEntry, CustLedgerEntry, IsCashBasedVAT, XmlType = XmlType::"Intra Community", IsSelfEmployed);
                end;
            DATABASE::"Vendor Ledger Entry":
                begin
                    RecordRef.SetTable(VendorLedgerEntry);
                    if XmlType = XmlType::Invoice then
                        CalculateVATEntries(
                          TempVATEntry, VendorLedgerEntry."Document No.", VendorLedgerEntry."Posting Date", VendorLedgerEntry."Transaction No.");

                    VerifyXMLForPurchLedger(
                      XMLDoc, TempVATEntry, VendorLedgerEntry, IsCashBasedVAT, XmlType = XmlType::"Intra Community", IsSelfEmployed);
                end;
            DATABASE::"Detailed Cust. Ledg. Entry":
                begin
                    RecordRef.SetTable(DetailedCustLedgEntry);
                    VerifyXMLCustomerPayment(XMLDoc, DetailedCustLedgEntry);
                end;
            DATABASE::"Detailed Vendor Ledg. Entry":
                begin
                    RecordRef.SetTable(DetailedVendorLedgEntry);
                    VerifyXMLVendorPayment(XMLDoc, DetailedVendorLedgEntry);
                end
            else
                exit;
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyXMLPurchNoTaxableAmount(XMLDoc: DotNet XmlDocument; VendorLedgerEntry: Record "Vendor Ledger Entry")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        TempVATEntry: Record "VAT Entry" temporary;
        InvoiceAmount: Decimal;
        NonTaxableAmount: Decimal;
        VatBaseAmount: Decimal;
    begin
        CalculateVATEntries(
          TempVATEntry, VendorLedgerEntry."Document No.", VendorLedgerEntry."Posting Date", VendorLedgerEntry."Transaction No.");
        LibraryVariableStorage.Clear();
        if TempVATEntry.FindSet() then
            repeat
                VatBaseAmount += TempVATEntry.Base;
            until TempVATEntry.Next() = 0;

        PurchInvHeader.Get(VendorLedgerEntry."Document No.");
        PurchInvHeader.CalcFields(Amount);
        InvoiceAmount := PurchInvHeader.Amount;
        NonTaxableAmount := InvoiceAmount + VatBaseAmount;
        ValidateElementByName(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(NonTaxableAmount));
    end;

    [Scope('OnPrem')]
    procedure VerifyXMLWithNormalAndReverseChargeVAT(XMLDoc: DotNet XmlDocument; VATRate: Decimal; VATRateReverseCharge: Decimal; Amount: Decimal; AmountReverse: Decimal)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        CuotaDeducibleDecValue: Decimal;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('sii:DesgloseFactura');
        XMLNode := XMLNodeList.Item(0);
        XMLNodeList := XMLNode.ChildNodes;
        Assert.AreEqual(2, XMLNodeList.Count, 'sii:DesgloseFactura must have 2 children in this case');

        XMLNode := XMLNodeList.Item(0);
        VerifyXMLInvoiceDetails(CuotaDeducibleDecValue, XMLNode, 'sii:InversionSujetoPasivo', VATRateReverseCharge, AmountReverse);

        XMLNode := XMLNodeList.Item(1);
        VerifyXMLInvoiceDetails(CuotaDeducibleDecValue, XMLNode, 'sii:DesgloseIVA', VATRate, Amount);

        ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(CuotaDeducibleDecValue));
    end;

    [Scope('OnPrem')]
    procedure VerifyVATInXMLDoc(XMLDoc: DotNet XmlDocument; XMLNodeName: Text; VATRate: Decimal; Amount: Decimal)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
        CuotaDeducibleDecValue: Decimal;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('sii:DesgloseFactura');
        XMLNode := XMLNodeList.Item(0);
        XMLNodeList := XMLNode.ChildNodes;
        Assert.AreEqual(1, XMLNodeList.Count, 'sii:DesgloseFactura must have 1 child in this case');

        XMLNode := XMLNodeList.Item(0);
        VerifyXMLInvoiceDetails(CuotaDeducibleDecValue, XMLNode, XMLNodeName, VATRate, Amount);

        ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(CuotaDeducibleDecValue));
    end;

    local procedure VerifyXMLHeader(XMLDoc: DotNet XmlDocument)
    var
        Attribute: DotNet XmlAttribute;
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('soapenv:Envelope');
        XMLNode := XMLNodeList.Item(0);

        Attribute := XMLNode.Attributes.GetNamedItem('xmlns:sii');
        Assert.AreEqual(Attribute.Value, SiiTxt, 'sii url is not setup correctly');
        Attribute := XMLNode.Attributes.GetNamedItem('xmlns:siiLR');
        Assert.AreEqual(Attribute.Value, SiiLRTxt, 'siiLR url is not setup correctly');
    end;

    local procedure VerifyXMLForSalesLedger(XMLDoc: DotNet XmlDocument; var TempVATEntry: Record "VAT Entry" temporary; CustLedgerEntry: Record "Cust. Ledger Entry"; IsCashBasedVAT: Boolean; IsIntraCommunity: Boolean; IsSelfEmpoyed: Boolean)
    var
        Customer: Record Customer;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CreditMemoRemovalCase: Boolean;
    begin
        if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::"Credit Memo" then begin
            SalesCrMemoHeader.Get(CustLedgerEntry."Document No.");
            if SalesCrMemoHeader."Correction Type" = SalesCrMemoHeader."Correction Type"::Removal then begin
                CreditMemoRemovalCase := true;
                ValidateElementByName(XMLDoc, 'sii:NumSerieFacturaEmisor', SalesCrMemoHeader."Corrected Invoice No.");
            end else
                VerifyOneNodeWithValueByXPath(XMLDoc, XPathSalesIDFacturaTok, 'sii:NumSerieFacturaEmisor', CustLedgerEntry."Document No.");
        end else
            ValidateElementByName(XMLDoc, 'sii:NumSerieFacturaEmisor', CustLedgerEntry."Document No.");

        ValidateElementByName(XMLDoc, 'sii:FechaExpedicionFacturaEmisor', SIIXMLCreator.FormatDate(CustLedgerEntry."Posting Date"));

        if CreditMemoRemovalCase then begin
            case SalesCrMemoHeader."Correction Type" of
                SalesCrMemoHeader."Correction Type"::Difference:
                    ValidateElementByName(XMLDoc, 'sii:TipoRectificativa', 'I');
                SalesCrMemoHeader."Correction Type"::Replacement:
                    ValidateElementByName(XMLDoc, 'sii:TipoRectificativa', 'S');
            end;
            exit;
        end;

        Customer.Get(CustLedgerEntry."Customer No.");
        if not IsIntraCommunity then begin
            if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice then
                ValidateElementByName(XMLDoc, 'sii:TipoFactura', 'F1')
            else
                ValidateElementByName(XMLDoc, 'sii:TipoFactura', 'R1');
            if SIIManagement.CountryAndVATRegNoAreLocal(Customer."Country/Region Code", Customer."VAT Registration No.") or
               SIIManagement.CustomerIsIntraCommunity(Customer."No.")
            then
                if IsCashBasedVAT then
                    ValidateElementByName(XMLDoc, 'sii:ClaveRegimenEspecialOTrascendencia', '07')
                else
                    ValidateElementByName(XMLDoc, 'sii:ClaveRegimenEspecialOTrascendencia', '01')
            else
                ValidateElementByName(XMLDoc, 'sii:ClaveRegimenEspecialOTrascendencia', '02');
        end;

        ValidateElementByName(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(CustLedgerEntry."Posting Date", 3)));

        if IsIntraCommunity then
            ValidateElementByNameAt(XMLDoc, 'sii:NombreRazon', Customer.Name, 2)
        else
            ValidateElementByNameAt(XMLDoc, 'sii:NombreRazon', Customer.Name, 1);

        if SIIManagement.CountryAndVATRegNoAreLocal(Customer."Country/Region Code", Customer."VAT Registration No.") then
            ValidateElementByNameAt(XMLDoc, 'sii:NIF', Customer."VAT Registration No.", 2)
        else begin
            ValidateElementByNameAt(XMLDoc, 'sii:CodigoPais', Customer."Country/Region Code", 0);
            if SIIManagement.CustomerIsIntraCommunity(Customer."No.") then
                ValidateElementByNameAt(XMLDoc, 'sii:IDType', '02', 0)
            else
                if IsSelfEmpoyed then
                    ValidateElementByNameAt(XMLDoc, 'sii:IDType', '07', 0)
                else
                    ValidateElementByNameAt(XMLDoc, 'sii:IDType', '06', 0);

            ValidateElementByNameAt(XMLDoc, 'sii:ID', Customer."VAT Registration No.", 0);
        end;
        ValidateElementByName(XMLDoc, 'sii:RefExterna', Format(CustLedgerEntry."Entry No."));

        if IsIntraCommunity then begin
            ValidateElementByName(XMLDoc, 'sii:TipoOperacion', 'A');
            ValidateElementByName(XMLDoc, 'sii:ClaveDeclarado', 'D');
            ValidateElementByName(XMLDoc, 'sii:EstadoMiembro', Customer."Country/Region Code");
        end else
            VerifyXMLSalesVATEntries(XMLDoc, TempVATEntry);
    end;

    local procedure VerifyXMLForPurchLedger(XMLDoc: DotNet XmlDocument; var TempVATEntry: Record "VAT Entry" temporary; VendorLedgerEntry: Record "Vendor Ledger Entry"; IsCashBasedVAT: Boolean; IsIntraCommunity: Boolean; IsSelfEmpoyed: Boolean)
    var
        Vendor: Record Vendor;
        CompanyInformation: Record "Company Information";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        CreditMemoRemovalCase: Boolean;
    begin
        if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::"Credit Memo" then begin
            PurchCrMemoHdr.Get(VendorLedgerEntry."Document No.");
            if PurchCrMemoHdr."Correction Type" = PurchCrMemoHdr."Correction Type"::Removal then begin
                PurchInvHeader.Get(PurchCrMemoHdr."Corrected Invoice No.");
                CreditMemoRemovalCase := true;
                ValidateElementByName(XMLDoc, 'sii:NumSerieFacturaEmisor', PurchInvHeader."Vendor Invoice No.");
            end else
                VerifyOneNodeWithValueByXPath(
                  XMLDoc, XPathPurchIDFacturaTok, 'sii:NumSerieFacturaEmisor', VendorLedgerEntry."External Document No.");
        end else
            ValidateElementByName(XMLDoc, 'sii:NumSerieFacturaEmisor', VendorLedgerEntry."External Document No.");

        ValidateElementByName(XMLDoc, 'sii:FechaExpedicionFacturaEmisor', SIIXMLCreator.FormatDate(VendorLedgerEntry."Document Date"));

        if CreditMemoRemovalCase then begin
            case PurchCrMemoHdr."Correction Type" of
                PurchCrMemoHdr."Correction Type"::Difference:
                    ValidateElementByName(XMLDoc, 'sii:TipoRectificativa', 'I');
                PurchCrMemoHdr."Correction Type"::Replacement:
                    ValidateElementByName(XMLDoc, 'sii:TipoRectificativa', 'S');
            end;
            exit;
        end;

        Vendor.Get(VendorLedgerEntry."Vendor No.");
        if not IsIntraCommunity then begin
            if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Invoice then
                ValidateElementByName(XMLDoc, 'sii:TipoFactura', 'F1')
            else
                ValidateElementByName(XMLDoc, 'sii:TipoFactura', 'R1');
            if IsCashBasedVAT then
                ValidateElementByName(XMLDoc, 'sii:ClaveRegimenEspecialOTrascendencia', '07')
            else
                if PurchInvHeader.Get(VendorLedgerEntry."Document No.") then
                    ValidateElementByName(
                      XMLDoc, 'sii:ClaveRegimenEspecialOTrascendencia', CopyStr(Format(PurchInvHeader."Special Scheme Code"), 1, 2))
                else
                    if SIIManagement.VendorIsIntraCommunity(Vendor."No.") then
                        ValidateElementByName(XMLDoc, 'sii:ClaveRegimenEspecialOTrascendencia', '09')
                    else
                        ValidateElementByName(XMLDoc, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
        end;

        ValidateElementByName(XMLDoc, 'sii:Ejercicio', Format(Date2DMY(VendorLedgerEntry."Posting Date", 3)));

        CompanyInformation.Get();
        ValidateElementByNameAt(XMLDoc, 'sii:NombreRazon', CompanyInformation.Name, 0);
        ValidateElementByNameAt(XMLDoc, 'sii:NombreRazon', Vendor.Name, 1);
        ValidateElementByNameAt(XMLDoc, 'sii:NIF', CompanyInformation."VAT Registration No.", 0);

        if SIIManagement.CountryIsLocal(Vendor."Country/Region Code") or (StrPos(Vendor."VAT Registration No.", 'N') = 1) then begin
            ValidateElementByNameAt(XMLDoc, 'sii:NIF', Vendor."VAT Registration No.", 1);
            ValidateElementByNameAt(XMLDoc, 'sii:NIF', Vendor."VAT Registration No.", 2);
        end else begin
            ValidateElementByNameAt(XMLDoc, 'sii:CodigoPais', Vendor."Country/Region Code", 0);
            if IsIntraCommunity then
                ValidateElementByNameAt(XMLDoc, 'sii:IDType', '02', 0)
            else
                if IsSelfEmpoyed then
                    ValidateElementByNameAt(XMLDoc, 'sii:IDType', '07', 0)
                else
                    ValidateElementByNameAt(XMLDoc, 'sii:IDType', '06', 0);

            ValidateElementByNameAt(XMLDoc, 'sii:CodigoPais', Vendor."Country/Region Code", 1);
            if IsIntraCommunity then
                ValidateElementByNameAt(XMLDoc, 'sii:IDType', '02', 1)
            else
                if IsSelfEmpoyed then
                    ValidateElementByNameAt(XMLDoc, 'sii:IDType', '07', 1)
                else
                    ValidateElementByNameAt(XMLDoc, 'sii:IDType', '06', 1);

            ValidateElementByNameAt(XMLDoc, 'sii:ID', Vendor."VAT Registration No.", 0);
            ValidateElementByNameAt(XMLDoc, 'sii:ID', Vendor."VAT Registration No.", 1);
        end;
        ValidateElementByName(XMLDoc, 'sii:RefExterna', Format(VendorLedgerEntry."Entry No."));

        if IsIntraCommunity then begin
            ValidateElementByName(XMLDoc, 'sii:TipoOperacion', 'A');
            ValidateElementByName(XMLDoc, 'sii:ClaveDeclarado', 'D');
            ValidateElementByName(XMLDoc, 'sii:EstadoMiembro', Vendor."Country/Region Code");
        end else
            VerifyXMLPurchVATEntries(XMLDoc, TempVATEntry);
    end;

    local procedure VerifyXMLSalesVATEntries(XMLDoc: DotNet XmlDocument; var TempVATEntry: Record "VAT Entry" temporary)
    var
        AmountVariant: Variant;
        VATVariant: Variant;
        Index: Integer;
    begin
        Index := 0;
        TempVATEntry.Reset();
        if TempVATEntry.FindSet() then
            repeat
                LibraryVariableStorage.Dequeue(VATVariant);
                ValidateElementByNameAt(XMLDoc, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(VATVariant), Index);
                LibraryVariableStorage.Dequeue(AmountVariant);
                ValidateElementByNameAt(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(AmountVariant), Index);
                LibraryVariableStorage.Dequeue(AmountVariant);
                ValidateElementByNameAt(XMLDoc, 'sii:CuotaRepercutida', SIIXMLCreator.FormatNumber(AmountVariant), Index);
                Index += 1;
            until TempVATEntry.Next() = 0;
    end;

    local procedure VerifyXMLPurchVATEntries(XMLDoc: DotNet XmlDocument; var TempVATEntry: Record "VAT Entry" temporary)
    var
        VATVariant: Variant;
        Amount: Decimal;
        EntryAmount: Decimal;
        TotalAmount: Decimal;
        Index: Integer;
        Sign: Integer;
    begin
        Index := 0;
        TempVATEntry.Reset();
        if TempVATEntry.FindSet() then
            repeat
                Sign := GetSignOfVATEntry(TempVATEntry."Document Type");
                LibraryVariableStorage.Dequeue(VATVariant);
                ValidateElementByNameAt(XMLDoc, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(VATVariant), Index);
                Amount := Sign * LibraryVariableStorage.DequeueDecimal();
                ValidateElementByNameAt(XMLDoc, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(Amount), Index);
                EntryAmount := Sign * LibraryVariableStorage.DequeueDecimal();
                ValidateElementByNameAt(XMLDoc, 'sii:CuotaSoportada', SIIXMLCreator.FormatNumber(EntryAmount), Index);
                TotalAmount += EntryAmount;
                Index += 1;
            until TempVATEntry.Next() = 0;
        ValidateElementByName(XMLDoc, 'sii:CuotaDeducible', SIIXMLCreator.FormatNumber(TotalAmount))
    end;

    local procedure VerifyXMLInvoiceDetails(var CuotaDeducibleDecValue: Decimal; XMLNode: DotNet XmlNode; XMLNodeName: Text; VATRate: Decimal; Amount: Decimal)
    var
        XMLNodeDetails: DotNet XmlNodeList;
    begin
        Assert.AreEqual(
          XMLNodeName, Format(XMLNode.Name), XMLNodeName + ' is not the 1st child of DesgloseFactura');
        XMLNodeDetails := XMLNode.ChildNodes;
        Assert.AreEqual(1, XMLNodeDetails.Count, 'sii:InversionSujetoPassivo or sii:DesgloseIVA must have 1 child');
        XMLNode := XMLNodeDetails.Item(0);
        XMLNodeDetails := XMLNode.ChildNodes;
        Assert.AreEqual(3, XMLNodeDetails.Count, 'sii:DetalleIVA must have 3 children');
        ValidateElementByNameAt(XMLNode, 'sii:TipoImpositivo', SIIXMLCreator.FormatNumber(VATRate), 0);
        ValidateElementByNameAt(XMLNode, 'sii:BaseImponible', SIIXMLCreator.FormatNumber(Amount), 0);
        ValidateElementByNameAt(XMLNode, 'sii:CuotaSoportada', SIIXMLCreator.FormatNumber(Amount * VATRate / 100), 0);

        CuotaDeducibleDecValue += Amount * VATRate / 100;
    end;

    local procedure VerifyXMLCustomerPayment(XMLDoc: DotNet XmlDocument; DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        ValidateElementByName(XMLDoc, 'sii:Importe', SIIXMLCreator.FormatNumber(-DetailedCustLedgEntry.Amount));
        ValidateElementByName(XMLDoc, 'sii:Fecha', SIIXMLCreator.FormatDate(DetailedCustLedgEntry."Posting Date"));
        ValidateElementByName(XMLDoc, 'sii:Medio', '04');
    end;

    local procedure VerifyXMLVendorPayment(XMLDoc: DotNet XmlDocument; DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        ValidateElementByName(XMLDoc, 'sii:Importe', SIIXMLCreator.FormatNumber(DetailedVendorLedgEntry.Amount));
        ValidateElementByName(XMLDoc, 'sii:Fecha', SIIXMLCreator.FormatDate(DetailedVendorLedgEntry."Posting Date"));
        ValidateElementByName(XMLDoc, 'sii:Medio', '04');
    end;

    [Scope('OnPrem')]
    procedure VerifyNodeCountWithValueByXPath(var XMLDoc: DotNet XmlDocument; BasePath: Text; NodeToken: Text; ExpectedValue: Text; ExpectedCount: Integer)
    begin
        LibraryXPathXMLReader.InitializeWithText(XMLDoc.OuterXml, '');
        SetupXMLNamespaces();
        LibraryXPathXMLReader.VerifyNodeCountWithValueByXPath(BasePath + NodeToken, ExpectedValue, ExpectedCount);
    end;

    [Scope('OnPrem')]
    procedure VerifyOneNodeWithValueByXPath(XMLDoc: DotNet XmlDocument; BasePath: Text; NodeToken: Text; ExpectedValue: Text)
    begin
        VerifyNodeCountWithValueByXPath(XMLDoc, BasePath, NodeToken, ExpectedValue, 1);
    end;

    [Scope('OnPrem')]
    procedure VerifySequenceOfTwoChildNodes(XMLDoc: DotNet XmlDocument; ParentNodeName: Text; FirstNodeName: Text; SecondNodeName: Text)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(ParentNodeName);
        XMLNode := XMLNodeList.Item(0);
        XMLNodeList := XMLNode.ChildNodes;
        Assert.AreEqual(2, XMLNodeList.Count, 'Incorrect count of child nodes');
        XMLNode := XMLNodeList.Item(0);
        Assert.AreEqual(FirstNodeName, XMLNode.Name, 'Incorrect Node Name');
        XMLNode := XMLNodeList.Item(1);
        Assert.AreEqual(SecondNodeName, XMLNode.Name, 'Incorrect Node Name');
    end;

    [Scope('OnPrem')]
    procedure VerifyTwoLevelChildNodes(XMLDoc: DotNet XmlDocument; ParentNodeName: Text; FirstNodeName: Text; SecondNodeName: Text)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName(ParentNodeName);
        XMLNode := XMLNodeList.Item(0);

        XMLNodeList := XMLNode.ChildNodes;
        XMLNode := XMLNodeList.Item(0);
        Assert.AreEqual(FirstNodeName, XMLNode.Name, 'Incorrect Node Name');

        XMLNodeList := XMLNode.ChildNodes;
        XMLNode := XMLNodeList.Item(0);
        Assert.AreEqual(SecondNodeName, XMLNode.Name, 'Incorrect Node Name');
    end;

    [Scope('OnPrem')]
    procedure VerifyXMLSalesDocHeaderCnt(XMLDoc: DotNet XmlDocument; ExpectedCount: Integer)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('siiLR:SuministroLRFacturasEmitidas');
        Assert.AreEqual(ExpectedCount, XMLNodeList.Count, 'Wrong count of XML tag SuministroLRFacturasEmitidas');
    end;

    [Scope('OnPrem')]
    procedure VerifyXMLSalesCrMemoRemovalHeaderCnt(XMLDoc: DotNet XmlDocument; ExpectedCount: Integer)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('siiLR:BajaLRFacturasEmitidas');
        Assert.AreEqual(ExpectedCount, XMLNodeList.Count, 'Wrong count of XML tag BajaLRFacturasEmitidas');
    end;

    [Scope('OnPrem')]
    procedure VerifyXMLSalesDocCnt(XMLDoc: DotNet XmlDocument; ExpectedCount: Integer)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('siiLR:RegistroLRFacturasEmitidas');
        Assert.AreEqual(ExpectedCount, XMLNodeList.Count, 'Wrong count of XML tag RegistroLRFacturasEmitidas');
    end;

    [Scope('OnPrem')]
    procedure VerifyXMLPurchDocHeaderCnt(XMLDoc: DotNet XmlDocument; ExpectedCount: Integer)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('siiLR:SuministroLRFacturasRecibidas');
        Assert.AreEqual(ExpectedCount, XMLNodeList.Count, 'Wrong count of XML tag SuministroLRFacturasRecibidas');
    end;

    [Scope('OnPrem')]
    procedure VerifyXMLPurchCrMemoRemovalHeaderCnt(XMLDoc: DotNet XmlDocument; ExpectedCount: Integer)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('siiLR:BajaLRFacturasRecibidas');
        Assert.AreEqual(ExpectedCount, XMLNodeList.Count, 'Wrong count of XML tag BajaLRFacturasRecibidas');
    end;

    [Scope('OnPrem')]
    procedure VerifyXMLPurchDocCnt(XMLDoc: DotNet XmlDocument; ExpectedCount: Integer)
    var
        XMLNodeList: DotNet XmlNodeList;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('siiLR:RegistroLRFacturasRecibidas');
        Assert.AreEqual(ExpectedCount, XMLNodeList.Count, 'Wrong count of XML tag RegistroLRFacturasRecibidas');
    end;

    [Scope('OnPrem')]
    procedure VerifyXMLTipoComunicacionValue(XMLDoc: DotNet XmlDocument; ExpectedCount: Integer; ExpectedValue: Text)
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNode: DotNet XmlNode;
    begin
        XMLNodeList := XMLDoc.GetElementsByTagName('sii:TipoComunicacion');
        Assert.AreEqual(ExpectedCount, XMLNodeList.Count, 'Wrong count of XML tag TipoComunicacion');
        if ExpectedCount > 0 then begin
            XMLNode := XMLNodeList.Item(0);
            Assert.AreEqual(ExpectedValue, XMLNode.InnerText, 'Wrong XML TipoComunicacion value');
        end;
    end;

    [Scope('OnPrem')]
    procedure AssertLibraryVariableStorage()
    begin
        LibraryVariableStorage.AssertEmpty();
    end;
}

