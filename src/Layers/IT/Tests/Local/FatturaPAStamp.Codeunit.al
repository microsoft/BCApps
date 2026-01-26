codeunit 144203 "FatturaPA Stamp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [Export]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        FatturaPA_ElectronicFormatTxt: Label 'FatturaPA';
        UnexpectedElementValueErr: Label 'Unexpected element value for element %1. Expected element value: %2. Actual element value: %3.', Comment = '%1=XML Element Name;%2=Expected XML Element Value;%3=Actual XML element Value;';
        YesTok: Label 'SI', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithStamp()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 294788] Fattura Stamp information exports to DatiBollo XML node for Sales Order

        Initialize();
        DocNo := PostSalesDocumentWithStamp(SalesHeader, SalesHeader."Document Type"::Order, true);

        SalesInvoiceHeader.SetRange("No.", DocNo);
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyStampInXmlFile(TempBlob, SalesHeader."Fattura Stamp Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithStamp()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 294788] Fattura Stamp information exports to DatiBollo XML node for Sales Invoice

        Initialize();
        DocNo := PostSalesDocumentWithStamp(SalesHeader, SalesHeader."Document Type"::Invoice, true);

        SalesInvoiceHeader.SetRange("No.", DocNo);
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyStampInXmlFile(TempBlob, SalesHeader."Fattura Stamp Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithStamp()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 294788] Fattura Stamp information exports to DatiBollo XML node for Sales Credit Memo

        Initialize();
        DocNo := PostSalesDocumentWithStamp(SalesHeader, SalesHeader."Document Type"::"Credit Memo", true);

        SalesCrMemoHeader.SetRange("No.", DocNo);
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyStampInXmlFile(TempBlob, SalesHeader."Fattura Stamp Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithStamp()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Order]
        // [SCENARIO 294788] Fattura Stamp information exports to DatiBollo XML node for Service Order

        Initialize();
        PostServiceDocumentWithStamp(ServiceHeader, ServiceHeader."Document Type"::Order, true);

        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyStampInXmlFile(TempBlob, ServiceHeader."Fattura Stamp Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceWithStamp()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 294788] Fattura Stamp information exports to DatiBollo XML node for Service Invoice

        Initialize();
        PostServiceDocumentWithStamp(ServiceHeader, ServiceHeader."Document Type"::Invoice, true);

        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyStampInXmlFile(TempBlob, ServiceHeader."Fattura Stamp Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoWithStamp()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 294788] Fattura Stamp information exports to DatiBollo XML node for Service Credit Memo

        Initialize();
        PostServiceDocumentWithStamp(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", true);

        ServiceCrMemoHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyStampInXmlFile(TempBlob, ServiceHeader."Fattura Stamp Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderNoStamp()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 294788] No DatiBollo XML node when Fattura Stamp not specified for Sales Order

        Initialize();
        DocNo := PostSalesDocumentWithStamp(SalesHeader, SalesHeader."Document Type"::Order, false);

        SalesInvoiceHeader.SetRange("No.", DocNo);
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyNoStampInXmlFile(TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceNoStamp()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 294788] No DatiBollo XML node when Fattura Stamp not specified for Sales Invoice

        Initialize();
        DocNo := PostSalesDocumentWithStamp(SalesHeader, SalesHeader."Document Type"::Invoice, false);

        SalesInvoiceHeader.SetRange("No.", DocNo);
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyNoStampInXmlFile(TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoNoStamp()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        DocNo: Code[20];
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 294788] No DatiBollo XML node when Fattura Stamp not specified for Sales Credit Memo

        Initialize();
        DocNo := PostSalesDocumentWithStamp(SalesHeader, SalesHeader."Document Type"::"Credit Memo", false);

        SalesCrMemoHeader.SetRange("No.", DocNo);
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, SalesCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyNoStampInXmlFile(TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderNoStamp()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Order]
        // [SCENARIO 294788] No DatiBollo XML node when Fattura Stamp not specified for Service Order

        Initialize();
        PostServiceDocumentWithStamp(ServiceHeader, ServiceHeader."Document Type"::Order, false);

        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyNoStampInXmlFile(TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceInvoiceNoStamp()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 294788] No DatiBollo XML node when Fattura Stamp not specified for Service Invoice

        Initialize();
        PostServiceDocumentWithStamp(ServiceHeader, ServiceHeader."Document Type"::Invoice, false);

        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceInvoiceHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyNoStampInXmlFile(TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceCrMemoNoStamp()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        ClientFileName: Text[250];
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 294788] No DatiBollo XML node when Fattura Stamp not specified for Service Credit Memo

        Initialize();
        PostServiceDocumentWithStamp(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", false);

        ServiceCrMemoHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ElectronicDocumentFormat.SendElectronically(TempBlob,
          ClientFileName, ServiceCrMemoHeader, CopyStr(FatturaPA_ElectronicFormatTxt, 1, 20));

        VerifyNoStampInXmlFile(TempBlob);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_SalesOrderWithStamp()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        DocNo: Code[20];
    begin
        // [FEATURE] [UI] [Sales] [Order] [UI]
        // [SCENARIO 294788] Fattura Stamp field visible on Sales Order page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        DocNo := PostSalesDocumentWithStamp(SalesHeader, SalesHeader."Document Type"::Order, true);

        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", DocNo);
        Assert.IsTrue(SalesOrder."Fattura Stamp".Visible(), '');
        Assert.IsTrue(SalesOrder."Fattura Stamp Amount".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_SalesInvoiceWithStamp()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        DocNo: Code[20];
    begin
        // [FEATURE] [UI] [Sales] [Invoice] [UI]
        // [SCENARIO 294788] Fattura Stamp field visible on Sales Invoice Order page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        DocNo := PostSalesDocumentWithStamp(SalesHeader, SalesHeader."Document Type"::Invoice, true);

        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", DocNo);
        Assert.IsTrue(SalesInvoice."Fattura Stamp".Visible(), '');
        Assert.IsTrue(SalesInvoice."Fattura Stamp Amount".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_SalesCrMemoWithStamp()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Credit Memo] [UI]
        // [SCENARIO 294788] Fattura Stamp field visible on Sales Credit Memo page

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        DocNo := PostSalesDocumentWithStamp(SalesHeader, SalesHeader."Document Type"::"Credit Memo", true);

        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", DocNo);
        Assert.IsTrue(SalesCreditMemo."Fattura Stamp".Visible(), '');
        Assert.IsTrue(SalesCreditMemo."Fattura Stamp Amount".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ServiceOrderWithStamp()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Service] [Order] [UI]
        // [SCENARIO 294788] Fattura Stamp field visible on Service Order page

        Initialize();
        LibraryApplicationArea.EnableServiceManagementSetup();
        PostServiceDocumentWithStamp(ServiceHeader, ServiceHeader."Document Type"::Order, true);
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ServiceInvoiceHeader.FindFirst();

        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", ServiceInvoiceHeader."No.");
        Assert.IsTrue(ServiceOrder."Fattura Stamp".Visible(), '');
        Assert.IsTrue(ServiceOrder."Fattura Stamp Amount".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ServiceWithStamp()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoice: TestPage "Service Invoice";
    begin
        // [FEATURE] [Service] [Invoice] [UI]
        // [SCENARIO 294788] Fattura Stamp field visible on Service Invoice page

        Initialize();
        LibraryApplicationArea.EnableServiceManagementSetup();
        PostServiceDocumentWithStamp(ServiceHeader, ServiceHeader."Document Type"::Invoice, true);
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ServiceInvoiceHeader.FindFirst();

        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", ServiceInvoiceHeader."No.");
        Assert.IsTrue(ServiceInvoice."Fattura Stamp".Visible(), '');
        Assert.IsTrue(ServiceInvoice."Fattura Stamp Amount".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_ServiceCrMemoWithStamp()
    var
        ServiceHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        // [FEATURE] [Service] [Credit Memo] [UI]
        // [SCENARIO 294788] Fattura Stamp field visible on Service Credit Memo page

        Initialize();
        LibraryApplicationArea.EnableServiceManagementSetup();
        PostServiceDocumentWithStamp(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", true);
        ServiceCrMemoHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ServiceCrMemoHeader.FindFirst();

        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", ServiceCrMemoHeader."No.");
        Assert.IsTrue(ServiceCreditMemo."Fattura Stamp".Visible(), '');
        Assert.IsTrue(ServiceCreditMemo."Fattura Stamp Amount".Visible(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryITLocalization.SetupFatturaPA();
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        // Public Company Customer
        exit(
          LibraryITLocalization.CreateFatturaCustomerNo(
            CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("PA Code"), DATABASE::Customer), 1, 6)));
    end;

    local procedure CreatePaymentMethod(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentMethodCode());
    end;

    local procedure CreatePaymentTerms(): Code[10]
    begin
        exit(LibraryITLocalization.CreateFatturaPaymentTermsCode());
    end;

    local procedure PostSalesDocumentWithStamp(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; FatturaStamp: Boolean): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CreateCustomer());
        SalesHeader.Validate("Payment Method Code", CreatePaymentMethod());
        SalesHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        SalesHeader.Validate("Fattura Stamp", FatturaStamp);
        SalesHeader.Validate("Fattura Stamp Amount", LibraryRandom.RandDec(100, 2));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostServiceDocumentWithStamp(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type"; FatturaStamp: Boolean)
    var
        ServiceItem: Record "Service Item";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocType, CreateCustomer());
        ServiceHeader.Validate("Order Date", WorkDate());
        ServiceHeader.Validate("Payment Method Code", CreatePaymentMethod());
        ServiceHeader.Validate("Payment Terms Code", CreatePaymentTerms());
        ServiceHeader.Validate("Fattura Stamp", FatturaStamp);
        ServiceHeader.Validate("Fattura Stamp Amount", LibraryRandom.RandDec(100, 2));
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, '');
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure FormatAmount(Amount: Decimal): Text[250]
    begin
        exit(Format(Amount, 0, '<Precision,2:2><Standard Format,9>'))
    end;

    local procedure AssertCurrentElementValue(TempXMLBuffer: Record "XML Buffer" temporary; ExpectedValue: Text)
    begin
        Assert.AreEqual(ExpectedValue, TempXMLBuffer.Value,
          StrSubstNo(UnexpectedElementValueErr, TempXMLBuffer.GetElementName(), ExpectedValue, TempXMLBuffer.Value));
    end;

    local procedure VerifyStampInXmlFile(TempBlob: Codeunit "Temp Blob"; ExpectedStampAmount: Decimal)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/DatiBollo/BolloVirtuale');
        AssertCurrentElementValue(TempXMLBuffer, YesTok);
        TempXMLBuffer.FindNodesByXPath(
          TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/DatiBollo/ImportoBollo');
        AssertCurrentElementValue(TempXMLBuffer, FormatAmount(ExpectedStampAmount));
    end;

    local procedure VerifyNoStampInXmlFile(TempBlob: Codeunit "Temp Blob")
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        LibraryITLocalization.LoadTempXMLBufferFromTempBlob(TempXMLBuffer, TempBlob);
        Assert.IsFalse(
          TempXMLBuffer.FindNodesByXPath(
            TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/DatiBollo/BolloVirtuale'), '');
        Assert.IsFalse(
          TempXMLBuffer.FindNodesByXPath(
            TempXMLBuffer, '/p:FatturaElettronica/FatturaElettronicaBody/DatiGenerali/DatiGeneraliDocumento/DatiBollo/ImportoBollo'), '');
    end;
}

