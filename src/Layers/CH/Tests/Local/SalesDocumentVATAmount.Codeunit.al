codeunit 144048 "Sales Document VAT Amount"
{
    // // [FEATURE] [Sales] [VAT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        PaymentTerms: Record "Payment Terms";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('BlanketOrderReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderVATAmountIsZero()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // SETUP
        Initialize();

        // Create Foreign Customer
        CustomerNo := CreateCustomer1();

        // Create Sales Blanket Order + Lines
        CreateSalesDocumentVATIsZero(SalesHeader, SalesHeader."Document Type"::"Blanket Order", CustomerNo);
        Commit();

        // Run Report
        SalesHeader.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Blanket Sales Order", true, false, SalesHeader);

        // Validate Report
        VerifySalesDocumentReportData(SalesHeader, true);
    end;

    [Test]
    [HandlerFunctions('BlanketOrderReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderVATAmountIsNotZero()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // SETUP
        Initialize();

        // Create Foreign Customer
        CustomerNo := CreateCustomer2();

        // Create Sales Blanket Order + Lines
        CreateSalesDocumentVATIsNotZero(SalesHeader, SalesHeader."Document Type"::"Blanket Order", CustomerNo);
        Commit();

        // Run Report
        SalesHeader.SetRange("No.", SalesHeader."No.");
        REPORT.Run(REPORT::"Blanket Sales Order", true, false, SalesHeader);

        // Validate Report
        VerifySalesDocumentReportData(SalesHeader, false);
    end;

    [Test]
    [HandlerFunctions('QuoteReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteVATAmountIsZero()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // SETUP
        Initialize();

        // Create Foreign Customer
        CustomerNo := CreateCustomer1();

        // Create Sales Quote + Lines
        CreateSalesDocumentVATIsZero(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
        Commit();

        // Run Report
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // Validate Report
        VerifyStdSalesDocumentReportData(SalesHeader, true);
    end;

    [Test]
    [HandlerFunctions('QuoteReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteVATAmountIsNotZero()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // SETUP
        Initialize();

        // Create Foreign Customer
        CustomerNo := CreateCustomer2();

        // Create Sales Quote + Lines
        CreateSalesDocumentVATIsNotZero(SalesHeader, SalesHeader."Document Type"::Quote, CustomerNo);
        Commit();

        // Run Report
        SalesHeader.SetRecFilter();
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // Validate Report
        VerifyStdSalesDocumentReportData(SalesHeader, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateVATProdPostingGroupWhenUpdateShipmentDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedVATPercent: Decimal;
        ExpectedAmountInclVAT: Decimal;
    begin
        // [SCENARIO 225589] Validate "VAT Prod Posting Group" when update "Shipment Date" in Sales Header
        Initialize();

        // [GIVEN] Sales Invoice with the following values in Sales Line
        // [GIVEN] "VAT %" = 10
        // [GIVEN] "Amount Including VAT" = 110
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), 1);
        FindSalesLine(SalesHeader, SalesLine);
        ExpectedVATPercent := SalesLine."VAT %" + LibraryRandom.RandInt(5);
        ExpectedAmountInclVAT := Round(SalesLine.Amount / 100 * (100 + ExpectedVATPercent));

        // [GIVEN] "VAT %" was changed to 20 in "VAT Posting Setup"
        SetVATPercentInVATPostingSetup(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", ExpectedVATPercent);

        // [WHEN] Validate "Shipment Date" in Sales Header
        SalesHeader.Validate("Shipment Date");

        // [THEN] Sales Line has the following values
        // [THEN] "VAT %" = 20
        // [THEN] "Amount Including VAT" = 120
        SalesLine.Find();
        SalesLine.TestField("VAT %", ExpectedVATPercent);
        SalesLine.TestField("Amount Including VAT", ExpectedAmountInclVAT);
    end;

    [Test]
    procedure UpdateSalesOrderShipmentDateAfterPostingPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [FEATURE] [Prepayment] [Shipment Date]
        // [SCENARIO 404747] Sales Order "Shipment Date" can be changed after posting prepayment invoice
        Initialize();

        // [GIVEN] Sales order with prepayment
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(100));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);

        // [GIVEN] Post prepayment invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [GIVEN] Reopen the order
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] Modify "Shipment Date"
        SalesHeader.Find();
        SalesHeader.Validate("Shipment Date", SalesHeader."Shipment Date" + 1);
        SalesHeader.Modify(true);

        // [THEN] Shipment Date has been updated
        SalesLine.Find();
        SalesLine.TestField("Shipment Date", SalesHeader."Shipment Date");
    end;

    local procedure Initialize()
    begin
        if IsInitialized = true then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        // General initialization
        IsInitialized := true;

        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<CM>');
        PaymentTerms.Modify(true);

        Commit();
    end;

    local procedure CreateSalesDocumentVATIsZero(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, CreateItem(),
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(10000, 2), FindZeroVATProdPosingGroup());
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, CreateItem(),
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(10000, 2), FindZeroVATProdPosingGroup());
        CreateSalesLine(SalesHeader, SalesLine.Type::"New Page", '', 0, 0, '');
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, CreateItem(),
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(10000, 2), FindZeroVATProdPosingGroup());
        CreateSalesLine(SalesHeader, SalesLine.Type::"New Page", '', 0, 0, '');
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, CreateItem(),
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(10000, 2), FindZeroVATProdPosingGroup());
        CreateSalesLine(SalesHeader, SalesLine.Type::"New Page", '', 0, 0, '');
    end;

    local procedure CreateSalesDocumentVATIsNotZero(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, CreateItem(),
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(10000, 2), FindNonZeroVATProdPosingGroup());
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, CreateItem(),
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(10000, 2), FindNonZeroVATProdPosingGroup());
        CreateSalesLine(SalesHeader, SalesLine.Type::"New Page", '', 0, 0, '');
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, CreateItem(),
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(10000, 2), FindNonZeroVATProdPosingGroup());
        CreateSalesLine(SalesHeader, SalesLine.Type::"New Page", '', 0, 0, '');
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, CreateItem(),
          LibraryRandom.RandInt(10), LibraryRandom.RandDec(10000, 2), FindNonZeroVATProdPosingGroup());
        CreateSalesLine(SalesHeader, SalesLine.Type::"New Page", '', 0, 0, '');
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; LineCount: Integer)
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        for i := 1 to LineCount do
            CreateSalesLine(SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(),
              LibraryRandom.RandInt(10), LibraryRandom.RandDec(10000, 2), FindNonZeroVATProdPosingGroup());
    end;

    [Normal]
    local procedure CreateCustomer1(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", FindZeroVATBusPosingGroup());
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Currency Code", CreateCurrency());
        Customer.Modify();
        exit(Customer."No.");
    end;

    [Normal]
    local procedure CreateCustomer2(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", FindNonZeroVATBusPosingGroup());
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Currency Code", '');
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", FindZeroVATProdPosingGroup());
        Item.Modify();
        exit(Item."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        ExchangeRate: Decimal;
    begin
        ExchangeRate := 1.284;
        exit(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRate, ExchangeRate));
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; SalesLineType: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal; VatPostingGroup: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLineType, ItemNo, Quantity);
        if SalesLineType <> SalesLine.Type::"New Page" then begin
            SalesLine.Validate("Unit Price", UnitPrice);
            SalesLine.Validate("VAT Prod. Posting Group", VatPostingGroup);
            SalesLine.Modify();
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BlanketOrderReportRequestPageHandler(var BlanketSalesOrder: TestRequestPage "Blanket Sales Order")
    begin
        BlanketSalesOrder.NoOfCopies.SetValue(0);
        BlanketSalesOrder.ShowInternalInfo.SetValue(false);
        BlanketSalesOrder.ArchiveDocument.SetValue(false);
        BlanketSalesOrder.LogInteraction.SetValue(true);

        BlanketSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure QuoteReportRequestPageHandler(var StandardSalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        StandardSalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure VerifySalesDocumentReportData(SalesHeader: Record "Sales Header"; VerifyIsZeroVAT: Boolean)
    var
        SalesLine: Record "Sales Line";
        ElementValue: Variant;
        TotalLineAmountExclVAT: Decimal;
        TotalAllAmountExclVAT: Decimal;
        TotalVATAmount: Decimal;
        ElementName: Option UnitPrice,LineAmount,VATPercentage,TotalAmountExVAT,TotalVATAmount;
    begin
        // Verify the XML
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.IsTrue(SalesLine.Count = 7, 'Wrong number of Sales Line found.');

        TotalAllAmountExclVAT := 0;
        TotalVATAmount := 0;
        if SalesLine.FindSet() then
            repeat
                LibraryReportDataset.GetNextRow();
                if SalesLine.Type <> SalesLine.Type::"New Page" then begin
                    LibraryReportDataset.AssertCurrentRowValueEquals(GetElementName(SalesHeader, ElementName::UnitPrice), SalesLine."Unit Price");
                    TotalLineAmountExclVAT := SalesLine."Unit Price" * SalesLine.Quantity;
                    LibraryReportDataset.AssertCurrentRowValueEquals(
                      GetElementName(SalesHeader, ElementName::LineAmount), TotalLineAmountExclVAT);
                    if VerifyIsZeroVAT = true then
                        LibraryReportDataset.AssertCurrentRowValueEquals(GetElementName(SalesHeader, ElementName::VATPercentage), 0)
                    else
                        LibraryReportDataset.AssertCurrentRowValueEquals(GetElementName(SalesHeader, ElementName::VATPercentage), SalesLine."VAT %");
                    TotalAllAmountExclVAT += TotalLineAmountExclVAT;
                    TotalVATAmount += (SalesLine."VAT %" * TotalLineAmountExclVAT) / 100;
                end;
            until SalesLine.Next() = 0;

        LibraryReportDataset.MoveToRow(SalesLine.Count);

        TotalAllAmountExclVAT := Round(TotalAllAmountExclVAT, 0.01);
        TotalVATAmount := Round(TotalVATAmount, 0.01);

        LibraryReportDataset.GetElementValueInCurrentRow(GetElementName(SalesHeader, ElementName::TotalAmountExVAT), ElementValue);
        Assert.AreNearlyEqual(ElementValue, TotalAllAmountExclVAT, 0.5, 'Wrong Total Amount Excl. VAT');

        LibraryReportDataset.GetElementValueInCurrentRow(GetElementName(SalesHeader, ElementName::TotalVATAmount), ElementValue);
        if VerifyIsZeroVAT then
            Assert.AreNearlyEqual(ElementValue, 0, 0.5, 'Wrong Total VAT Amount')
        else
            Assert.AreNearlyEqual(ElementValue, TotalVATAmount, 0.5, 'Wrong Total VAT Amount');
    end;

    local procedure VerifyStdSalesDocumentReportData(SalesHeader: Record "Sales Header"; VerifyIsZeroVAT: Boolean)
    var
        SalesLine: Record "Sales Line";
        ElementValue: Variant;
        TotalLineAmountExclVAT: Decimal;
        TotalAllAmountExclVAT: Decimal;
        TotalVATAmount: Decimal;
        ElementName: Option UnitPrice,LineAmount,VATPercentage,TotalAmountExVAT,TotalVATAmount;
    begin
        // Verify the XML
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.IsTrue(SalesLine.Count = 7, 'Wrong number of Sales Line found.');

        TotalAllAmountExclVAT := 0;
        TotalVATAmount := 0;
        if SalesLine.FindSet() then
            repeat
                if SalesLine.Type <> SalesLine.Type::"New Page" then begin
                    LibraryReportDataset.AssertCurrentRowValueEquals(GetElementName(SalesHeader, ElementName::UnitPrice), Format(SalesLine."Unit Price", 0, '<Integer Thousand><Decimals,3>'));
                    TotalLineAmountExclVAT := SalesLine."Unit Price" * SalesLine.Quantity;
                    LibraryReportDataset.AssertCurrentRowValueEquals(GetElementName(SalesHeader, ElementName::LineAmount), Format(TotalLineAmountExclVAT, 0, '<Integer Thousand><Decimals,3>'));
                    if VerifyIsZeroVAT = true then
                        LibraryReportDataset.AssertCurrentRowValueEquals(GetElementName(SalesHeader, ElementName::VATPercentage), Format(0))
                    else
                        LibraryReportDataset.AssertCurrentRowValueEquals(GetElementName(SalesHeader, ElementName::VATPercentage), Format(SalesLine."VAT %"));
                    TotalAllAmountExclVAT += TotalLineAmountExclVAT;
                    TotalVATAmount += (SalesLine."VAT %" * TotalLineAmountExclVAT) / 100;
                end;
                LibraryReportDataset.GetNextRow();
            until SalesLine.Next() = 0;

        LibraryReportDataset.GetLastRow();

        TotalAllAmountExclVAT := Round(TotalAllAmountExclVAT, 0.01);
        TotalVATAmount := Round(TotalVATAmount, 0.01);

        LibraryReportDataset.GetElementValueInCurrentRow(GetElementName(SalesHeader, ElementName::TotalAmountExVAT), ElementValue);
        Assert.AreNearlyEqual(ElementValue, TotalAllAmountExclVAT, 0.5, 'Wrong Total Amount Excl. VAT');

        LibraryReportDataset.GetElementValueInCurrentRow(GetElementName(SalesHeader, ElementName::TotalVATAmount), ElementValue);
        if VerifyIsZeroVAT then
            Assert.AreNearlyEqual(ElementValue, 0, 0.5, 'Wrong Total VAT Amount')
        else
            Assert.AreNearlyEqual(ElementValue, TotalVATAmount, 0.5, 'Wrong Total VAT Amount');
    end;

    local procedure GetElementName(SalesHeader: Record "Sales Header"; ElementName: Option UnitPrice,LineAmount,VATPercentage,TotalAmountExVAT,TotalVATAmount): Text
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                case ElementName of
                    ElementName::UnitPrice:
                        exit('UnitPrice_SalesLine');
                    ElementName::LineAmount:
                        exit('LineAmt_SalesLine');
                    ElementName::VATPercentage:
                        exit('VAT_SalesLine');
                    ElementName::TotalAmountExVAT:
                        exit('VATBaseAmount');
                    ElementName::TotalVATAmount:
                        exit('VATAmount');
                end;
            SalesHeader."Document Type"::"Blanket Order":
                case ElementName of
                    ElementName::UnitPrice:
                        exit('SalesLineUnitPrice');
                    ElementName::LineAmount:
                        exit('SalesLineLineAmount1');
                    ElementName::VATPercentage:
                        exit('SalesLineVAT');
                    ElementName::TotalAmountExVAT:
                        exit('VATBaseAmt');
                    ElementName::TotalVATAmount:
                        exit('VATAmount');
                end;
            SalesHeader."Document Type"::Quote:
                case ElementName of
                    ElementName::UnitPrice:
                        exit('UnitPrice');
                    ElementName::LineAmount:
                        exit('LineAmount_Line');
                    ElementName::VATPercentage:
                        exit('VATPct_Line');
                    ElementName::TotalAmountExVAT:
                        exit('TotalNetAmount');
                    ElementName::TotalVATAmount:
                        exit('TotalVATAmount');
                end;
        end;

        exit('');
    end;

    local procedure FindNonZeroVATBusPosingGroup(): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure FindNonZeroVATProdPosingGroup(): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FindSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindZeroVATBusPosingGroup(): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure FindZeroVATProdPosingGroup(): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindZeroVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure SetVATPercentInVATPostingSetup(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; NewVATPercent: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        VATPostingSetup.Validate("VAT %", NewVATPercent);
        VATPostingSetup.Modify(true);
    end;
}

