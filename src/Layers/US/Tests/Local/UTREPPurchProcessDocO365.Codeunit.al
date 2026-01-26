codeunit 144021 "UT REP Purch. Process Doc O365"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Reports] [O365]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        NoPurchaseHeaderTxt: Label 'No_PurchHeader';
        CompanyAddressTxt: Label 'CompanyAddress1';
        ItemNumberToPrintTxt: Label 'ItemNumberToPrint';
        TotalTaxLabelTxt: Label 'TotalTaxLabel';
        CopyNoTxt: Label 'CopyNo';
        CopyTextTxt: Label 'CopyTxt';
        SalesPurchasePersonNameTxt: Label 'SalesPurchPersonName';
        TotalTaxTxt: Label 'Total Tax';
        TotalSalesTaxTxt: Label 'Total Sales Tax';
        CopyTxt: Label 'COPY';
        TotalTaxPurchaseLineTxt: Label 'TotalTaxLabel_PurchLine';
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        ItemNumberToPrintPurchReceiptLineTxt: Label 'ItemNumberToPrint_PurchRcptLine';
        PaymentTermsDescTxt: Label 'PaymentTermsDesc';

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaseInvoiceHeaderPurchaseInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Purchase Invoice Header of Report 10121 - Purchase Invoice.

        // Setup: Create Purchase Invoice Header.
        Initialize();
        CreatePostedPurchaseInvoice(PurchInvHeader, PurchInvLine);

        // Exercise: Opens handler - PurchaseInvoiceRequestPageHandler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 319 - Purch. Inv.-Printed.
        LibraryLowerPermissions.SetPurchDocsPost();
        RunReportsPPForCompanyAddress(ResponsibilityCenter, PurchInvHeader."Responsibility Center", REPORT::"Purchase Invoice NA");

        // Verify: Verify Company Address on Report Purchase Invoice.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_PurchInvHeader', PurchInvHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyAddressTxt, ResponsibilityCenter.Name);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchInvHeaderTaxAreaUSPurchInv()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Invoice Header of Report 10121 - Purchase Invoice.

        // Setup: Create Purchase Invoice Header with Tax Area Country US.
        Initialize();
        OnAfterGetRecordPurchInvHeaderTaxAreaPurchInv(TaxArea."Country/Region"::US, TotalSalesTaxTxt);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchInvHeaderTaxAreaCAPurchInv()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Invoice Header of Report 10121 - Purchase Invoice.

        // Setup: Create Purchase Invoice Header with Tax Area Country CA.
        Initialize();
        OnAfterGetRecordPurchInvHeaderTaxAreaPurchInv(TaxArea."Country/Region"::CA, TotalTaxTxt);
    end;

    local procedure OnAfterGetRecordPurchInvHeaderTaxAreaPurchInv(Country: Option; ExpectedTaxValue: Text)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        TaxArea: Record "Tax Area";
    begin
        // Create Purchase Invoice.
        CreateTaxArea(TaxArea, Country);
        CreatePostedPurchaseInvoice(PurchInvHeader, PurchInvLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for PurchaseInvoiceRequestPageHandler.
        PurchInvHeader."Tax Area Code" := TaxArea.Code;
        PurchInvHeader.Modify();

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 319 - Purch. Inv.-Printed.
        REPORT.Run(REPORT::"Purchase Invoice NA");  // Opens handler - PurchaseInvoiceRequestPageHandler.

        // Verify: Verify Total Tax Label on Report Purchase Invoice.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalTaxLabelTxt, ExpectedTaxValue + ':');  // Not able to pass Symbol - :, as part of constant hence taking it here.
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopPurchaseInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        NumberOfCopies: Integer;
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop of Report 10121 - Purchase Invoice.

        // Setup: Create Purchase Invoice.
        Initialize();
        CreatePostedPurchaseInvoice(PurchInvHeader, PurchInvLine);

        // Exercise: Set Number of copies on handler - NumberOfCopiesPurchaseInvoiceRequestPageHandler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 319 - Purch. Inv.-Printed.
        RunRepotsPPForNumberOfCopies(NumberOfCopies, REPORT::"Purchase Invoice NA");

        // Verify: Verify Copy Caption and total number of copies on Report Purchase Invoice.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CopyTextTxt, Format(CopyTxt));
        LibraryReportDataset.AssertElementWithValueExists(CopyNoTxt, NumberOfCopies + 1);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseInvLineGLAccountPurchInv()
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Invoice Line of Report 10121 - Purchase Invoice.

        // Setup: Create Purchase Invoice with Type - G/L Account.
        Initialize();
        OnAfterGetRecordPurchaseInvoiceLinePurchaseInvoice(PurchInvLine.Type::"G/L Account");
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseInvoiceLineItemPurchInv()
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Invoice Line of Report 10121 - Purchase Invoice.

        // Setup: Create Purchase Invoice with Type - Item.
        Initialize();
        OnAfterGetRecordPurchaseInvoiceLinePurchaseInvoice(PurchInvLine.Type::Item);
    end;

    local procedure OnAfterGetRecordPurchaseInvoiceLinePurchaseInvoice(Type: Enum "Purchase Line Type")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        CreatePostedPurchaseInvoice(PurchInvHeader, PurchInvLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for PurchaseInvoiceRequestPageHandler.
        PurchInvLine.Type := Type;
        // TFS ID: 313614
        PurchInvLine."Line Discount %" := LibraryRandom.RandInt(10);
        PurchInvLine.Modify();

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 319 - Purch. Inv.-Printed.
        REPORT.Run(REPORT::"Purchase Invoice NA");  // Opens handler - PurchaseInvoiceRequestPageHandler.

        // Verify: Verify Item number on Report Purchase Invoice.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNumberToPrintTxt, PurchInvLine."No.");
        // [THEN] Line Discount % is in dataset
        LibraryReportDataset.SetRange('ItemNumberToPrint', Format(PurchInvLine."No."));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('LineDisc_PurchInvLine', PurchInvLine."Line Discount %");
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Purchase Header of Report 10123 - Purchase Quote.

        // Setup: Create Purchase Header Document Type - Quote.
        Initialize();
        OnPreDataItemPurchaseDocument(PurchaseHeader."Document Type"::Quote, REPORT::"Purchase Quote NA", NoPurchaseHeaderTxt);
    end;

    local procedure OnPreDataItemPurchaseDocument(DocumentType: Enum "Purchase Document Type"; ReportID: Integer; ElementCaption: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        // Create Purchase Header.
        CreatePurchaseHeader(PurchaseHeader, DocumentType);

        // Exercise: Opens different Request Page Handler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 317 - Purch.Header-Printed.
        RunReportsPPForCompanyAddress(ResponsibilityCenter, PurchaseHeader."Responsibility Center", ReportID);

        // Verify: Verify Purchase Header No and Company Address on Different Reports.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementCaption, PurchaseHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyAddressTxt, ResponsibilityCenter.Name);
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Header of Report 10123 - Purchase Quote.

        // Setup: Create Purchase Header Document Type - Quote.
        Initialize();
        OnAfterGetRecordPurchaseDocument(PurchaseHeader."Document Type"::Quote, REPORT::"Purchase Quote NA", PaymentTermsDescTxt);
    end;

    local procedure OnAfterGetRecordPurchaseDocument(DocumentType: Enum "Purchase Document Type"; ReportID: Integer; ElementCaption: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        PaymentTerms: Record "Payment Terms";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // Create Purchase Header.
        PaymentTerms.FindFirst();
        CreateSalespersonPurchaser(SalespersonPurchaser);
        CreatePurchaseHeader(PurchaseHeader, DocumentType);
        PurchaseHeader."Payment Terms Code" := PaymentTerms.Code;
        PurchaseHeader."Purchaser Code" := SalespersonPurchaser.Code;
        PurchaseHeader.Modify();
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for different RequestPageHandlers.

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 317 - Purch.Header-Printed.
        REPORT.Run(ReportID);  // Opens handler PurchaseBlanketOrderRequestPageHandler, PurchaseOrderRequestPageHandler or PurchaseQuoteRequestPageHandler.

        // Verify: Verify Sales Person Purchaser Name and Payment term Description on different Reports.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SalesPurchasePersonNameTxt, SalespersonPurchaser.Name);
        LibraryReportDataset.AssertElementWithValueExists(ElementCaption, PaymentTerms.Description);
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop of Report 10123 - Purchase Quote.

        // Setup: Create Purchase Header Document Type - Quote.
        Initialize();
        OnAfterGetRecordCopyLoopPurchaseDocument(PurchaseHeader."Document Type"::Quote, REPORT::"Purchase Quote NA");
    end;

    local procedure OnAfterGetRecordCopyLoopPurchaseDocument(DocumentType: Enum "Purchase Document Type"; ReportID: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        NumberOfCopies: Integer;
    begin
        // Create Purchase Header of different Document Type.
        CreatePurchaseHeader(PurchaseHeader, DocumentType);

        // Exercise: Set Number of copies on different Request Page Handler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 317 - Purch.Header-Printed.
        RunRepotsPPForNumberOfCopies(NumberOfCopies, ReportID);

        // Verify: Verify Copy Caption and total number of copies on Different Reports.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CopyTextTxt, Format(CopyTxt));
        LibraryReportDataset.AssertElementWithValueExists(CopyNoTxt, NumberOfCopies + 1);
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopTaxAreaCAPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of CopyLoop of Report 10123 - Purchase Quote.

        // Setup: Create Purchase Quote with Tax Area Country CA.
        Initialize();
        OnAfterGetRecordCopyLoopTaxAreaPurchaseDocument(
          TaxArea."Country/Region"::CA, PurchaseHeader."Document Type"::Quote, REPORT::"Purchase Quote NA", TotalTaxPurchaseLineTxt,
          TotalTaxTxt);
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopTaxAreaUSPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of CopyLoop of Report 10123 - Purchase Quote.

        // Setup: Create Purchase Quote with Tax Area Country US.
        Initialize();
        OnAfterGetRecordCopyLoopTaxAreaPurchaseDocument(
          TaxArea."Country/Region"::US, PurchaseHeader."Document Type"::Quote, REPORT::"Purchase Quote NA", TotalTaxPurchaseLineTxt,
          TotalSalesTaxTxt);
    end;

    local procedure OnAfterGetRecordCopyLoopTaxAreaPurchaseDocument(Country: Option; DocumentType: Enum "Purchase Document Type"; ReportID: Integer; ElementCaption: Text; ExpectedTaxValue: Text)
    var
        PurchaseHeader: Record "Purchase Header";
        TaxArea: Record "Tax Area";
    begin
        // Create Purchase Document with Tax Area.
        CreateTaxArea(TaxArea, Country);
        CreatePurchaseDocument(PurchaseHeader, DocumentType);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandInt(10));  // Enqueue value required in different Request Handlers.
        UpdatePurchaseHeaderTaxAreaCode(PurchaseHeader, TaxArea.Code);

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 317 - Purch.Header-Printed.
        REPORT.Run(ReportID);  // Opens Request Page handlers - NumberOfCopiesPurchaseBlanketOrderRequestPageHandler, NumberOfCopiesPurchaseOrderRequestPageHandler or NumberOfCopiesPurchaseQuoteRequestPageHandler.

        // Verify: Verify Total Tax Label on different Reports.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ElementCaption, ExpectedTaxValue + ':');  // Not able to pass Symbol - :, as part of constant hence taking it here.
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaseCreditMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Purchase Credit Memo Header of Report 10120 - Purchase Credit Memo.

        // Setup: Create Purchase Credit Memo.
        Initialize();
        CreatePostedPurchaseCreditMemo(PurchCrMemoHdr, PurchCrMemoLine);

        // Exercise: Opens handler - PurchaseCreditMemoRequestPageHandler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 320 - PurchCrMemo-Printed.
        RunReportsPPForCompanyAddress(ResponsibilityCenter, PurchCrMemoHdr."Responsibility Center", REPORT::"Purchase Credit Memo NA");

        // Verify: Verify Purchase Credit Memo No and Company Address on Report - Purchase Credit Memo.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_PurchCrMemoHdr', PurchCrMemoHdr."No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyAddressTxt, ResponsibilityCenter.Name);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTaxAreaUSPurchCrMemo()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Credit Memo Header of Report 10120 - Purchase Credit Memo.

        // Setup: Create Purchase Credit Memo with Tax Area Country US.
        Initialize();
        OnAfterGetRecordTaxAreaPurchCrMemo(TaxArea."Country/Region"::US, TotalSalesTaxTxt);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTaxAreaCAPurchCrMemo()
    var
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Credit Memo Header of Report 10120 - Purchase Credit Memo.

        // Setup: Create Purchase Credit Memo with Tax Area Country CA.
        Initialize();
        OnAfterGetRecordTaxAreaPurchCrMemo(TaxArea."Country/Region"::CA, TotalTaxTxt);
    end;

    local procedure OnAfterGetRecordTaxAreaPurchCrMemo(Country: Option; ExpectedTaxValue: Text)
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TaxArea: Record "Tax Area";
    begin
        // Create Posted Purchase Credit Memo.
        CreateTaxArea(TaxArea, Country);
        CreatePostedPurchaseCreditMemo(PurchCrMemoHdr, PurchCrMemoLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for PurchaseCreditMemoRequestPageHandler.
        PurchCrMemoHdr."Tax Area Code" := TaxArea.Code;
        PurchCrMemoHdr.Modify();

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 320 - PurchCrMemo-Printed.
        REPORT.Run(REPORT::"Purchase Credit Memo NA");  // Opens handler - PurchaseCreditMemoRequestPageHandler.

        // Verify: Verify Total Tax Label on Report - Purchase Credit Memo.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalTaxLabelTxt, ExpectedTaxValue + ':');  // Not able to pass Symbol - :, as part of constant hence taking it here.
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopPurchaseCreditMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        NumberOfCopies: Integer;
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop of Report 10120 - Purchase Credit Memo.

        // Setup: Create Purchase Credit Memo.
        Initialize();
        CreatePostedPurchaseCreditMemo(PurchCrMemoHdr, PurchCrMemoLine);

        // Exercise: Set Number of copies on handler - NumberOfCopiesPurchaseCreditMemoRequestPageHandler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 320 - PurchCrMemo-Printed.
        RunRepotsPPForNumberOfCopies(NumberOfCopies, REPORT::"Purchase Credit Memo NA");

        // Verify: Verify Copy Caption and total number of copies on Report - Purchase Credit Memo.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CopyTextTxt, Format(CopyTxt));
        LibraryReportDataset.AssertElementWithValueExists(CopyNoTxt, NumberOfCopies + 1);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordGLAccPurchCrMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Credit Memo Line of Report 10120 - Purchase Credit Memo.

        // Setup: Create Purchase Credit Memo with Type - G/L Account.
        Initialize();
        CreatePostedPurchaseCreditMemo(PurchCrMemoHdr, PurchCrMemoLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for PurchaseCreditMemoRequestPageHandler.
        UpdatePurchaseCrMemoLineType(PurchCrMemoLine, PurchCrMemoLine.Type::"G/L Account");

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 320 - PurchCrMemo-Printed.
        REPORT.Run(REPORT::"Purchase Credit Memo NA");  // Opens handler - PurchaseCreditMemoRequestPageHandler.

        // Verify: Verify Purchase Credit Memo Line Vendor Item No on Report - Purchase Credit Memo.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNumberToPrintTxt, PurchCrMemoLine."Vendor Item No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemPurchaseCrMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Credit Memo Line of Report 10120 - Purchase Credit Memo.

        // Setup: Create Purchase Credit Memo with Type - Item.
        Initialize();
        CreatePostedPurchaseCreditMemo(PurchCrMemoHdr, PurchCrMemoLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for PurchaseCreditMemoRequestPageHandler.
        UpdatePurchaseCrMemoLineType(PurchCrMemoLine, PurchCrMemoLine.Type::Item);

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 320 - PurchCrMemo-Printed.
        REPORT.Run(REPORT::"Purchase Credit Memo NA");  // Opens handler - PurchaseCreditMemoRequestPageHandler.

        // Verify: Verify Purchase Credit Memo Line No on Report - Purchase Credit Memo.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNumberToPrintTxt, PurchCrMemoLine."No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemPurchaseReceipt()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Purchase Receipt Header of Report 10124 - Purchase Receipt.

        // Setup: Create Posted Purchase Receipt.
        Initialize();
        CreatePostedPurchaseReceipt(PurchRcptHeader, PurchRcptLine);

        // Exercise: Set Print Company Address as TRUE on handler - PurchaseReceiptRequestPageHandler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 318 - Purch.Rcpt.-Printed.
        RunReportsPPForCompanyAddress(ResponsibilityCenter, PurchRcptHeader."Responsibility Center", REPORT::"Purchase Receipt NA");

        // Verify: Verify Purchase Receipt No and Company Address on Report - Purchase Receipt.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_PurchRcptHeader', PurchRcptHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyAddr1', ResponsibilityCenter.Name);
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordHeaderPurchaseReceipt()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ShipmentMethod: Record "Shipment Method";
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Receipt Header of Report 10124 - Purchase Receipt.

        // Setup: Create Posted Purchase Receipt.
        Initialize();
        CreateShipmentMethod(ShipmentMethod);
        CreateSalespersonPurchaser(SalespersonPurchaser);
        CreateTaxArea(TaxArea, LibraryRandom.RandIntInRange(0, 1)); // Only two option value for Tax Area so using Range 0 to 1.
        CreatePostedPurchaseReceipt(PurchRcptHeader, PurchRcptLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for PurchaseReceiptRequestPageHandler.
        PurchRcptHeader."Shipment Method Code" := ShipmentMethod.Code;
        PurchRcptHeader."Purchaser Code" := SalespersonPurchaser.Code;
        PurchRcptHeader."Tax Area Code" := TaxArea.Code;
        PurchRcptHeader.Modify();

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 318 - Purch.Rcpt.-Printed.
        REPORT.Run(REPORT::"Purchase Receipt NA");  // Opens handler - PurchaseReceiptRequestPageHandler.

        // Verify: Verify Sales Person Purchase Name and Shipment Method Description on Report - Purchase Receipt.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SalesPurchasePersonNameTxt, SalespersonPurchaser.Name);
        LibraryReportDataset.AssertElementWithValueExists('ShipmentMethodDesc', ShipmentMethod.Description);
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesPurchaseReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopPurchaseReceipt()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        NumberOfCopies: Integer;
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop of Report 10124 - Purchase Receipt.

        // Setup: Create Posted Purchase Receipt.
        Initialize();
        CreatePostedPurchaseReceipt(PurchRcptHeader, PurchRcptLine);

        // Exercise: Set Number of copies on handler - NumberOfCopiesPurchaseReceiptRequestPageHandler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 318 - Purch.Rcpt.-Printed.
        RunRepotsPPForNumberOfCopies(NumberOfCopies, REPORT::"Purchase Receipt NA");

        // Verify: Verify Copy Caption and total number of copies on Report - Purchase Receipt.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CopyTextTxt, Format(CopyTxt));
        LibraryReportDataset.AssertElementWithValueExists('myCopyNo', NumberOfCopies + 1);
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordPurchaseReceipt()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Receipt Line of Report 10124 - Purchase Receipt.

        // Setup: Create Posted Purchase Receipt.
        Initialize();
        CreatePostedPurchaseReceipt(PurchRcptHeader, PurchRcptLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for PurchaseReceiptRequestPageHandler.
        PurchRcptLine.Type := PurchRcptLine.Type::Item;
        PurchRcptLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchRcptLine."Order No." := LibraryUTUtility.GetNewCode();
        PurchRcptLine."Order Line No." := LibraryRandom.RandInt(10);
        PurchRcptLine.Modify();

        // Excercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 318 - Purch.Rcpt.-Printed.
        REPORT.Run(REPORT::"Purchase Receipt NA");  // Opens handler - PurchaseReceiptRequestPageHandler.

        // Verify: Verify Purchase Receipt Line Quantity on Report - Purchase Receipt.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('OrderedQty_PurchRcptLine', PurchRcptLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeGLAccPurchReceipt()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Receipt Line of Report 10124 - Purchase Receipt.

        // Setup: Create Posted Purchase Receipt with Type - G/L Account.
        Initialize();
        CreatePostedPurchaseReceipt(PurchRcptHeader, PurchRcptLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for PurchaseReceiptRequestPageHandler.
        UpdatePurchaseReceiptLineType(PurchRcptLine, PurchRcptLine.Type::"G/L Account");

        // Excercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 318 - Purch.Rcpt.-Printed.
        REPORT.Run(REPORT::"Purchase Receipt NA");  // Opens handler - PurchaseReceiptRequestPageHandler.

        // Verify: Verify Purchase Receipt Line Vendor Item No on Report - Purchase Receipt.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNumberToPrintPurchReceiptLineTxt, PurchRcptLine."Vendor Item No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeItemPurchReceipt()
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Receipt Line of Report 10124 - Purchase Receipt.

        // Setup: Create Posted Purchase Receipt with Type - Item.
        Initialize();
        CreatePostedPurchaseReceipt(PurchRcptHeader, PurchRcptLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for PurchaseReceiptRequestPageHandler.
        UpdatePurchaseReceiptLineType(PurchRcptLine, PurchRcptLine.Type::Item);

        // Excercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 318 - Purch.Rcpt.-Printed.
        REPORT.Run(REPORT::"Purchase Receipt NA");  // Opens handler - PurchaseReceiptRequestPageHandler.

        // Verify: Verify Purchase Receipt Line No on Report - Purchase Receipt.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNumberToPrintPurchReceiptLineTxt, PurchRcptLine."No.");
    end;

    [Test]
    [HandlerFunctions('ReturnShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnPreDataItemReturnShipment()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of Return Shipment Header of Report 10127 - Return Shipment.

        // Setup: Create Posted Return Shipment.
        Initialize();
        CreatePostedReturnShipment(ReturnShipmentHeader, ReturnShipmentLine);

        // Exercise: Set Print Company Address as TRUE on handler - ReturnShipmentRequestPageHandler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 6651 - Return Shipment - Printed.
        RunReportsPPForCompanyAddress(ResponsibilityCenter, ReturnShipmentHeader."Responsibility Center", REPORT::"Return Shipment");

        // Verify: Verify Return Shipment No and Company Address on Report - Return Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_ReturnShipmentHeader', ReturnShipmentHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyAddressTxt, ResponsibilityCenter.Name);
    end;

    [Test]
    [HandlerFunctions('ReturnShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordReturnShipment()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        ShipmentMethod: Record "Shipment Method";
        TaxArea: Record "Tax Area";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of Purchase Receipt Header of Report 10127 - Return Shipment.

        // Setup: Create Tax Area. Create Posted Return Shipment.
        Initialize();
        CreateShipmentMethod(ShipmentMethod);
        CreateSalespersonPurchaser(SalespersonPurchaser);
        CreateTaxArea(TaxArea, LibraryRandom.RandIntInRange(0, 1)); // Only two option value for Tax Area so using Range 0 to 1.
        CreatePostedReturnShipment(ReturnShipmentHeader, ReturnShipmentLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for ReturnShipmentRequestPageHandler.
        ReturnShipmentHeader."Shipment Method Code" := ShipmentMethod.Code;
        ReturnShipmentHeader."Tax Area Code" := TaxArea.Code;
        ReturnShipmentHeader."Purchaser Code" := SalespersonPurchaser.Code;
        ReturnShipmentHeader.Modify();

        // Exercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 6651 - Return Shipment - Printed.
        REPORT.Run(REPORT::"Return Shipment");  // Opens handler - ReturnShipmentRequestPageHandler.

        // Verify: Verify Sales person Purchaser and Shipment Method description on Report - Return Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SalesPurchasePersonNameTxt, SalespersonPurchaser.Name);
        LibraryReportDataset.AssertElementWithValueExists('ShipmentMethodDescription', ShipmentMethod.Description);
    end;

    [Test]
    [HandlerFunctions('NumberOfCopiesReturnShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordCopyLoopReturnShipment()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        NumberOfCopies: Integer;
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of CopyLoop of Report 10127 - Return Shipment.

        // Setup: Create Posted Return Shipment.
        Initialize();
        CreatePostedReturnShipment(ReturnShipmentHeader, ReturnShipmentLine);

        // Exercise: Set Number of copies on handler - NumberOfCopiesReturnShipmentRequestPageHandler. Commit required as the explicit Commit used on OnRun Trigger of Codeunit 6651 - Return Shipment - Printed.
        RunRepotsPPForNumberOfCopies(NumberOfCopies, REPORT::"Return Shipment");

        // Verify: Verify Copy Caption and total number of copies on Report - Return Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CopyTextTxt, Format(CopyTxt));
        LibraryReportDataset.AssertElementWithValueExists(CopyNoTxt, NumberOfCopies + 1);
    end;

    [Test]
    [HandlerFunctions('ReturnShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordLineReturnShipment()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Receipt Line of Report 10127 - Return Shipment.

        // Setup: Create Posted Return Shipment.
        Initialize();
        CreatePostedReturnShipment(ReturnShipmentHeader, ReturnShipmentLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for ReturnShipmentRequestPageHandler.
        ReturnShipmentLine.Type := ReturnShipmentLine.Type::Item;
        ReturnShipmentLine.Quantity := LibraryRandom.RandDec(10, 2);
        ReturnShipmentLine."Return Order No." := LibraryUTUtility.GetNewCode();
        ReturnShipmentLine."Return Order Line No." := LibraryRandom.RandInt(10);
        ReturnShipmentLine.Modify();

        // Excercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 6651 - Return Shipment - Printed.
        REPORT.Run(REPORT::"Return Shipment");  // Opens handler - ReturnShipmentRequestPageHandler.

        // Verify: Verify Return Shipment Line Quantity on Report - Return Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Qty_ReturnShipmentLine', ReturnShipmentLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReturnShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeGLAccReturnShipment()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Receipt Line of Report 10127 - Return Shipment.

        // Setup: Create Posted Return Shipment with Type - G/L Account.
        Initialize();
        CreatePostedReturnShipment(ReturnShipmentHeader, ReturnShipmentLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for ReturnShipmentRequestPageHandler.
        UpdateReturnShipmentLineType(ReturnShipmentLine, ReturnShipmentLine.Type::"G/L Account");

        // Excercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 6651 - Return Shipment - Printed.
        REPORT.Run(REPORT::"Return Shipment");

        // Verify: Verify Return Shipment Line Vendor Item No on Report - Return Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNumberToPrintTxt, ReturnShipmentLine."Vendor Item No.");
    end;

    [Test]
    [HandlerFunctions('ReturnShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTypeItemReturnShipment()
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Purpose of the test is to validate OnAfterGetRecord of Purchase Receipt Line of Report 10127 - Return Shipment.

        // Setup: Create Posted Return Shipment with Type - Item.
        Initialize();
        CreatePostedReturnShipment(ReturnShipmentHeader, ReturnShipmentLine);
        LibraryVariableStorage.Enqueue(false);  // Enqueue value for ReturnShipmentRequestPageHandler.
        UpdateReturnShipmentLineType(ReturnShipmentLine, ReturnShipmentLine.Type::Item);

        // Excercise.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of Codeunit 6651 - Return Shipment - Printed.
        REPORT.Run(REPORT::"Return Shipment");

        // Verify: Verify Return Shipment Line No on Report - Return Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ItemNumberToPrintTxt, ReturnShipmentLine."No.");
    end;

    [Test]
    [HandlerFunctions('OpenPurchaseInvoicesByJobRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecVendLedgEntryOpenPurchInvoicesByJob()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        AmountLCY: Decimal;
    begin
        // Purpose of the test is to validate OnAfterGetRecord of VendorLedgerEntry of Report 10092 - Open Purchase Invoices by Job.

        // Setup: Create Posted Purchase Invoice with Job.
        Initialize();
        CreatePostedPurchaseInvoiceWithJob(PurchInvLine);
        AmountLCY :=
          CreateDetailedVendorLedgerEntry(CreateVendorLedgerEntry(PurchInvLine."Document No.", PurchInvLine."Buy-from Vendor No."));

        // Exercise.
        REPORT.Run(REPORT::"Open Purchase Invoices by Job");  // Opens handler - OpenPurchaseInvoicesByJobRequestPageHandler.

        // Verify: Verify Job Number, Document No, and Remaining Amount LCY on Report - Open Purchase Invoices by Job.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Job_No_', PurchInvLine."Job No.");
        LibraryReportDataset.AssertElementWithValueExists('Purch__Inv__Line_Document_No_', PurchInvLine."Document No.");
        LibraryReportDataset.AssertElementWithValueExists('Vendor_Ledger_Entry___Remaining_Amt___LCY__', AmountLCY);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryApplicationArea.EnableFoundationSetup();
    end;

    local procedure CreateJob(): Code[20]
    var
        Job: Record Job;
    begin
        Job.Init();
        Job."No." := LibraryUTUtility.GetNewCode();
        Job.Insert();
        exit(Job."No.");
    end;

    local procedure CreateTaxArea(var TaxArea: Record "Tax Area"; Country: Option)
    begin
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea."Country/Region" := Country;
        TaxArea.Insert();
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := CreateVendor();
        PurchaseHeader."Responsibility Center" := CreateResponsibilityCenter();
        PurchaseHeader.Insert();
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");  // Enqueue value required in RequestPageHandler.
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType);
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Insert();
    end;

    local procedure CreatePostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchInvLine: Record "Purch. Inv. Line")
    begin
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader."Responsibility Center" := CreateResponsibilityCenter();
        PurchInvHeader.Insert();
        PurchInvLine."Document No." := PurchInvHeader."No.";
        PurchInvLine.Insert();
        LibraryVariableStorage.Enqueue(PurchInvHeader."No.");  // Enqueue value required in PurchaseInvoiceRequestPageHandler, NumberOfCopiesPurchaseInvoiceRequestPageHandler.
    end;

    local procedure CreatePostedPurchaseInvoiceWithJob(var PurchInvLine: Record "Purch. Inv. Line")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Init();
        PurchInvHeader."No." := LibraryUTUtility.GetNewCode();
        PurchInvHeader."Pay-to Vendor No." := CreateVendor();
        PurchInvHeader.Insert();
        PurchInvLine."Document No." := PurchInvHeader."No.";
        PurchInvLine."Job No." := CreateJob();
        PurchInvLine."Buy-from Vendor No." := PurchInvHeader."Pay-to Vendor No.";
        PurchInvLine.Insert();
        LibraryVariableStorage.Enqueue(PurchInvLine."Job No.");  // Enqueue value required in OpenPurchaseInvoicesByJobRequestPageHandler.
    end;

    local procedure CreatePostedPurchaseCreditMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; var PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        PurchCrMemoHdr."No." := LibraryUTUtility.GetNewCode();
        PurchCrMemoHdr."Responsibility Center" := CreateResponsibilityCenter();
        PurchCrMemoHdr.Insert();
        PurchCrMemoLine."Document No." := PurchCrMemoHdr."No.";
        PurchCrMemoLine."No." := LibraryUTUtility.GetNewCode();
        PurchCrMemoLine."Vendor Item No." := LibraryUTUtility.GetNewCode();
        PurchCrMemoLine.Insert();
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."No.");  // Enqueue value required in different Request Page Handler.
    end;

    local procedure CreatePostedPurchaseReceipt(var PurchRcptHeader: Record "Purch. Rcpt. Header"; var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        PurchRcptHeader."No." := LibraryUTUtility.GetNewCode();
        PurchRcptHeader."Responsibility Center" := CreateResponsibilityCenter();
        PurchRcptHeader.Insert();
        PurchRcptLine."Document No." := PurchRcptHeader."No.";
        PurchRcptLine."No." := LibraryUTUtility.GetNewCode();
        PurchRcptLine."Vendor Item No." := LibraryUTUtility.GetNewCode();
        PurchRcptLine.Insert();
        LibraryVariableStorage.Enqueue(PurchRcptHeader."No.");  // Enqueue value required in different Request Page Handler.
    end;

    local procedure CreatePostedReturnShipment(var ReturnShipmentHeader: Record "Return Shipment Header"; var ReturnShipmentLine: Record "Return Shipment Line")
    begin
        ReturnShipmentHeader."No." := LibraryUTUtility.GetNewCode();
        ReturnShipmentHeader."Responsibility Center" := CreateResponsibilityCenter();
        ReturnShipmentHeader.Insert();
        ReturnShipmentLine."Document No." := ReturnShipmentHeader."No.";
        ReturnShipmentLine."No." := LibraryUTUtility.GetNewCode();
        ReturnShipmentLine."Vendor Item No." := LibraryUTUtility.GetNewCode();
        ReturnShipmentLine.Insert();
        LibraryVariableStorage.Enqueue(ReturnShipmentHeader."No.");   // Enqueue value required in different Request Page Handler.
    end;

    local procedure CreateResponsibilityCenter(): Code[10]
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        ResponsibilityCenter.Init();
        ResponsibilityCenter.Code := LibraryUTUtility.GetNewCode10();
        ResponsibilityCenter.Name := LibraryUTUtility.GetNewCode();
        ResponsibilityCenter.Insert();
        exit(ResponsibilityCenter.Code);
    end;

    local procedure CreateSalespersonPurchaser(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        SalespersonPurchaser.Code := LibraryUTUtility.GetNewCode10();
        SalespersonPurchaser.Name := LibraryUTUtility.GetNewCode();
        SalespersonPurchaser.Insert();
    end;

    local procedure CreateShipmentMethod(var ShipmentMethod: Record "Shipment Method")
    begin
        ShipmentMethod.Code := LibraryUTUtility.GetNewCode10();
        ShipmentMethod.Description := LibraryUTUtility.GetNewCode();
        ShipmentMethod.Insert();
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.FindFirst();
        Vendor.Init();
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Vendor Posting Group" := VendorPostingGroup.Code;
        Vendor.Insert();
        exit(Vendor."No.")
    end;

    local procedure CreateVendorLedgerEntry(DocumentNo: Code[20]; VendorNo: Code[20]): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        if VendorLedgerEntry2.FindLast() then;
        VendorLedgerEntry."Entry No." := VendorLedgerEntry2."Entry No." + 1;
        VendorLedgerEntry."Document No." := DocumentNo;
        VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::Invoice;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
        exit(VendorLedgerEntry."Entry No.");
    end;

    local procedure CreateDetailedVendorLedgerEntry(VendorLedgerEntryNo: Integer): Decimal
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        if DetailedVendorLedgEntry2.FindLast() then;
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := DetailedVendorLedgEntry2."Entry No." + 1;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntryNo;
        DetailedVendorLedgEntry."Amount (LCY)" := LibraryRandom.RandDec(10, 2);
        DetailedVendorLedgEntry.Insert(true);
        exit(DetailedVendorLedgEntry."Amount (LCY)");
    end;

    local procedure DequeueDocumentNoAndNumberOfCopies(var No: Variant; var NumberOfCopies: Variant)
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(NumberOfCopies);
    end;

    local procedure DequeuePrintCompanyAddress(var No: Variant; var PrintCompanyAddress: Variant)
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintCompanyAddress);
    end;

    local procedure UpdatePurchaseHeaderTaxAreaCode(PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20])
    begin
        PurchaseHeader."Tax Area Code" := TaxAreaCode;
        PurchaseHeader.Modify();
    end;

    local procedure UpdateReturnShipmentLineType(ReturnShipmentLine: Record "Return Shipment Line"; Type: Enum "Purchase Line Type")
    begin
        ReturnShipmentLine.Type := Type;
        ReturnShipmentLine.Modify();
    end;

    local procedure UpdatePurchaseReceiptLineType(PurchRcptLine: Record "Purch. Rcpt. Line"; Type: Enum "Purchase Line Type")
    begin
        PurchRcptLine.Type := Type;
        PurchRcptLine.Modify();
    end;

    local procedure UpdatePurchaseCrMemoLineType(PurchCrMemoLine: Record "Purch. Cr. Memo Line"; Type: Enum "Purchase Line Type")
    begin
        PurchCrMemoLine.Type := Type;
        PurchCrMemoLine.Modify();
    end;

    local procedure OpenPurchaseInvoiceRequestPage(PurchaseInvoice: TestRequestPage "Purchase Invoice NA"; No: Variant)
    begin
        PurchaseInvoice."Purch. Inv. Header".SetFilter("No.", No);
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure OpenPurchaseCreditMemoRequestPage(PurchaseCreditMemo: TestRequestPage "Purchase Credit Memo NA"; No: Variant)
    begin
        PurchaseCreditMemo."Purch. Cr. Memo Hdr.".SetFilter("No.", No);
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure OpenPurchaseQuoteRequestPage(var PurchaseQuote: TestRequestPage "Purchase Quote NA"; No: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseQuote."Purchase Header".SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Quote));
        PurchaseQuote."Purchase Header".SetFilter("No.", No);
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure OpenPurchaseReceiptRequestPage(var PurchaseReceipt: TestRequestPage "Purchase Receipt NA"; No: Variant)
    begin
        PurchaseReceipt."Purch. Rcpt. Header".SetFilter("No.", No);
        PurchaseReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure OpenReturnShipmentRequestPage(var ReturnShipment: TestRequestPage "Return Shipment"; No: Variant)
    begin
        ReturnShipment."Return Shipment Header".SetFilter("No.", No);
        ReturnShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure RunReportsPPForCompanyAddress(var ResponsibilityCenter: Record "Responsibility Center"; "Code": Code[10]; ReportID: Integer)
    begin
        ResponsibilityCenter.Get(Code);
        LibraryVariableStorage.Enqueue(true);  // Enqueue value for different Request Page Handler.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of different Codeunits.
        REPORT.Run(ReportID);  // Opens handlers - PurchaseInvoiceRequestPageHandler, PurchaseCreditMemoRequestPageHandler, PurchaseReceiptRequestPageHandler Or ReturnShipmentRequestPageHandler.
    end;

    local procedure RunRepotsPPForNumberOfCopies(var NumberOfCopies: Integer; ReportID: Integer)
    begin
        NumberOfCopies := LibraryRandom.RandInt(10);
        LibraryVariableStorage.Enqueue(NumberOfCopies);  // Enqueue value required in different Request Page Handler.
        Commit();  // Commit required as the explicit Commit used on OnRun Trigger of different Codeunits.
        REPORT.Run(ReportID);  // Opens different handlers - NumberOfCopiesPurchaseInvoiceRequestPageHandler, NumberOfCopiesPurchaseCreditMemoRequestPageHandler or NumberOfCopiesPurchaseReceiptRequestPageHandler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase Invoice NA")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
    begin
        DequeuePrintCompanyAddress(No, PrintCompanyAddress);
        PurchaseInvoice.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        OpenPurchaseInvoiceRequestPage(PurchaseInvoice, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NumberOfCopiesPurchaseInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase Invoice NA")
    var
        No: Variant;
        NumberOfCopies: Variant;
    begin
        DequeueDocumentNoAndNumberOfCopies(No, NumberOfCopies);
        PurchaseInvoice.NumberOfCopies.SetValue(NumberOfCopies);
        OpenPurchaseInvoiceRequestPage(PurchaseInvoice, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase Credit Memo NA")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
    begin
        DequeuePrintCompanyAddress(No, PrintCompanyAddress);
        PurchaseCreditMemo.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        OpenPurchaseCreditMemoRequestPage(PurchaseCreditMemo, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NumberOfCopiesPurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase Credit Memo NA")
    var
        No: Variant;
        NumberOfCopies: Variant;
    begin
        DequeueDocumentNoAndNumberOfCopies(No, NumberOfCopies);
        PurchaseCreditMemo.NumberOfCopies.SetValue(NumberOfCopies);
        OpenPurchaseCreditMemoRequestPage(PurchaseCreditMemo, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase Quote NA")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
    begin
        DequeuePrintCompanyAddress(No, PrintCompanyAddress);
        PurchaseQuote.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        OpenPurchaseQuoteRequestPage(PurchaseQuote, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NumberOfCopiesPurchaseQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase Quote NA")
    var
        No: Variant;
        NumberOfCopies: Variant;
    begin
        DequeueDocumentNoAndNumberOfCopies(No, NumberOfCopies);
        PurchaseQuote.NumberOfCopies.SetValue(NumberOfCopies);
        OpenPurchaseQuoteRequestPage(PurchaseQuote, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseReceiptRequestPageHandler(var PurchaseReceipt: TestRequestPage "Purchase Receipt NA")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
    begin
        DequeuePrintCompanyAddress(No, PrintCompanyAddress);
        PurchaseReceipt.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        OpenPurchaseReceiptRequestPage(PurchaseReceipt, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NumberOfCopiesPurchaseReceiptRequestPageHandler(var PurchaseReceipt: TestRequestPage "Purchase Receipt NA")
    var
        No: Variant;
        NumberOfCopies: Variant;
    begin
        DequeueDocumentNoAndNumberOfCopies(No, NumberOfCopies);
        PurchaseReceipt.NumberOfCopies.SetValue(NumberOfCopies);
        OpenPurchaseReceiptRequestPage(PurchaseReceipt, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReturnShipmentRequestPageHandler(var ReturnShipment: TestRequestPage "Return Shipment")
    var
        No: Variant;
        PrintCompanyAddress: Variant;
    begin
        DequeuePrintCompanyAddress(No, PrintCompanyAddress);
        ReturnShipment.PrintCompanyAddress.SetValue(PrintCompanyAddress);
        OpenReturnShipmentRequestPage(ReturnShipment, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure NumberOfCopiesReturnShipmentRequestPageHandler(var ReturnShipment: TestRequestPage "Return Shipment")
    var
        No: Variant;
        NumberOfCopies: Variant;
    begin
        DequeueDocumentNoAndNumberOfCopies(No, NumberOfCopies);
        ReturnShipment.NumberOfCopies.SetValue(NumberOfCopies);
        OpenReturnShipmentRequestPage(ReturnShipment, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure OpenPurchaseInvoicesByJobRequestPageHandler(var OpenPurchaseInvoicesByJob: TestRequestPage "Open Purchase Invoices by Job")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        OpenPurchaseInvoicesByJob.Job.SetFilter("No.", No);
        OpenPurchaseInvoicesByJob.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

