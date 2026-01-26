codeunit 144037 "ERM CORRINV-AUTOINV"
{
    // Test for feature Corrective and Auto Invoice:
    //  1. Verify Corrected Invoice No. on Posted Purchase Credit Memo.
    //  2. Verify Purchase - Credit Memo report title as 'Purchase - Corrective Invoice' and Corrective Invoice Number.
    //  3. Verify Page Posted Purchase Credit Memos open after Invoking Find Corrective Invoice from Posted Purchase Invoice Page.
    //  4. Verify Page Posted Sales Credit Memos open after Invoking Find Corrective Invoice from Posted Sales Invoice Page.
    //  5. Verify Sales - Credit Memo report title as 'Sales - Corrective invoice ' and Corrective Invoice Number.
    //  6. Verify Corrected Invoice Identification for Sales Credit Memo in Make 340 Declaration text file.
    //  7. Verify Operation Date in the exported text file.
    //  8. Verify Posted Service Credit Memo opened from Find Corrective Invoice.
    //  9. Verify Service - Credit Memo report title as 'Service - Corrective invoice ' and Corrective Invoice Number.
    // 10. Verify Corrected Invoice Identification in the exported text file.
    // 11. Verify Sales Invoice Book report values.
    // 12. Verify Purchase - AutoCredit Memo report values.
    // 
    // Covers Test Cases for WI - 351134
    // ---------------------------------------------------------------------------
    // Test Function Name                                                   TFS ID
    // ---------------------------------------------------------------------------
    // CorrInvoiceOnPostedPurchaseCrMemo                                    275860
    // CorrInvoiceOnPostedPurchaseCrMemoReport                       275860,275861
    // CorrInvoiceOnPostedPurchCrMemoWithPostedPurchaseInvoice              275861
    // CorrInvoiceOnPostedPurchCrMemoWithPostedSalesInvoice                 275862
    // CorrInvoiceOnPostedSaleCrMemoReport                                  275862
    // CorrInvoiceWithMake340DeclarationReport                              275858
    // ServiceCrMemoOperationDateOnMake340DeclarationReport                 275986
    // CorrInvoiceIdentificationWithPostedServiceCrMemo                     275983
    // CorrInvoiceWithServiceCrMemoOnServiceCreditMemoReport                275983
    // CorrInvoicePostedServiceCrMemoOnMake340DeclarationReport             275983
    // VATAmountOnSalesInvoiceBookReport                                    152213
    // PurchaseAutoCreditMemoReportWithEUVendor                             152307

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CorrectInvcNoPurchCrMemoHeaderCap: Label 'CorrectInvcNo_PurchCrMemoHeader';
        CorrectInvNoServCrMemoHdrCap: Label 'CorrectInvNo_ServCrMemoHdr';
        FieldsAreNotEqualMsg: Label 'Actual value %2 is not equal to the expected value, which is %1.';
        PurchCrMemoHeaderCopyCap: Label 'PurchCrMemoHeaderCopyText';
        PurchaseCorrectiveInvoiceTxt: Label 'Purchase - Corrective invoice ';
        PurchCrMemoHdrNoCap: Label 'Purch__Cr__Memo_Hdr__No_';
        PurchCrMemoLineQuantityCap: Label 'Purch__Cr__Memo_Line_Quantity';
        SalesCorrectiveInvoiceTxt: Label 'Sales - Corrective invoice ';
        SalesCorrectInvCopyCap: Label 'SalesCorrectInvCopyText';
        VATAmountLineVATECBaseCap: Label 'VATAmountLine__VAT_EC_Base_';
        VATEntryDocumentNoCap: Label 'VATEntry_Document_No_';
        VATBufferBaseCap: Label 'VATBuffer2_Base';
        VATBufferVATCap: Label 'VATBuffer2__VAT___';
        VATBufferAmountCap: Label 'VATBuffer2_Amount';

    [Test]
    [Scope('OnPrem')]
    procedure CorrInvoiceOnPostedPurchaseCrMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        DocumentNo2: Variant;
        DocumentNo: Code[20];
    begin
        // Verify Corrected Invoice No. on Posted Purchase Credit Memo.

        // Setup.
        Initialize();

        // Exercise: Create Vendor, create and post Purchase Invoice and Purchase Return Order.
        DocumentNo := CreateAndPostMultiplePurchaseDocument();
        LibraryVariableStorage.Dequeue(DocumentNo2);

        // Verify: Verify Corrected Invoice No. on Posted Purchase Credit Memo.
        PurchCrMemoHdr.Get(DocumentNo2);
        PurchCrMemoHdr.TestField("Corrected Invoice No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CorrInvoiceOnPostedPurchaseCrMemoReport()
    var
        DocumentNo: Code[20];
    begin
        // Verify Purchase - Credit Memo report title as Purchase - Corrective Invoice and Corrective Invoice Number.

        // Setup: Create Vendor, create and post Purchase Invoice and Purchase Return Order.
        Initialize();
        DocumentNo := CreateAndPostMultiplePurchaseDocument();

        // Exercise.
        REPORT.Run(REPORT::"Purchase - Credit Memo");  // Open PurchaseCreditMemoRequestPageHandler.

        // Verify: Verify Purchase - Credit Memo report title as Purchase - Corrective Invoice and Corrective Invoice Number.
        VerifyDocumentNoAndCorrectiveInvoice(
          CorrectInvcNoPurchCrMemoHeaderCap, PurchCrMemoHeaderCopyCap, DocumentNo, PurchaseCorrectiveInvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationRequestPageHandler,Declaration340LinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure CorrInvoiceWithMake340DeclarationReport()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        ExportedFileName: Text[1024];
    begin
        // Verify Corrected Invoice Identification for Sales Credit Memo in Make 340 Declaration text file.

        // Setup: Create and Post Sales Invoice and Sales Return Order and find Sales Credit Memo.
        Initialize();
        DocumentNo := CreateAndPostMultipleSalesDocument(SalesLine."Document Type"::"Return Order");
        FindSalesCrMemoHeader(SalesCrMemoHeader, DocumentNo);
        LibraryVariableStorage.Enqueue(SalesCrMemoHeader."No.");

        // Exercise: Run Report Make 340 Declaration.
        ExportedFileName := RunMake340DeclarationReportSaveTxt();

        // Verify: Verify Corrected Invoice Identification in the exported text file.
        VerifyFieldRecordType(326, ExportedFileName, SalesCrMemoHeader."Corrected Invoice No.");  // 326 - Starting Position.
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationRequestPageHandler,Declaration340LinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure ServiceCrMemoOperationDateOnMake340DeclarationReport()
    var
        Item: Record Item;
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ExportedFileName: Text[1024];
        OperationDate: Text[8];
    begin
        // Verify Operation Date in the exported text file.

        // Setup: Create and Post Service Credit Memo, get Posting Date as Number.
        Initialize();
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::"Credit Memo",
          ServiceLine.Type::Item, CreateCustomer(), LibraryInventory.CreateItem(Item));
        PostServiceDocument(ServiceLine."Document Type"::"Credit Memo", ServiceLine."Document No.");
        ServiceCrMemoHeader.Get(FindServiceCrMemoHeader(ServiceLine."Customer No."));
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."No.");
        OperationDate := GetDateAsNumber(ServiceCrMemoHeader."Posting Date");

        // Exercise: Run Report Make 340 Declaration.
        ExportedFileName := RunMake340DeclarationReportSaveTxt();

        // Verify: Verify Operation Date in the exported text file.
        VerifyFieldRecordType(109, ExportedFileName, OperationDate);  // 109 - Starting Position.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrInvoiceIdentificationWithPostedServiceCrMemo()
    var
        PostedServiceCreditMemos: TestPage "Posted Service Credit Memos";
        CustomerNo: Code[20];
    begin
        // Verify Posted Service Credit Memo opened from Find Corrective Invoice.

        // Setup: Create and Post Service Invoice, create Service Credit Memo, update Posted Service Invoice as Corrective Invoice and Post Service Credit Memo.
        Initialize();
        CustomerNo := CreateAndPostMultipleServiceDocument();
        PostedServiceCreditMemos.Trap();

        // Exercise: Find Corrective Invoices on Posted Service Invoice.
        InvokePagePostedServiceCreditMemos(CustomerNo);

        // Verify: Verify Posted Service Credit Memo opened from Find Corrective Invoice.
        PostedServiceCreditMemos."No.".AssertEquals(FindServiceCrMemoHeader(CustomerNo));
        PostedServiceCreditMemos."Customer No.".AssertEquals(CustomerNo);
    end;

    [Test]
    [HandlerFunctions('ServiceCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CorrInvoiceWithServiceCrMemoOnServiceCreditMemoReport()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustomerNo: Code[20];
    begin
        // Verify Service - Credit Memo report title as 'Service - Corrective invoice ' and Corrective Invoice Number.

        // Setup: Create and Post Service Invoice, create Service Credit Memo, update Posted Service Invoice as Corrective Invoice and Post Service Credit Memo.
        Initialize();
        CustomerNo := CreateAndPostMultipleServiceDocument();
        ServiceInvoiceHeader.Get(FindServiceInvoiceHeader(CustomerNo));

        // Exercise.
        REPORT.Run(REPORT::"Service - Credit Memo");  // Open ServiceCreditMemoRequestPageHandler.

        // Verify: Verify Service - Credit Memo report title as 'Service - Corrective invoice ' and Corrective Invoice Number.
        VerifyDocumentNoAndCorrectiveInvoice(
          CorrectInvNoServCrMemoHdrCap, SalesCorrectInvCopyCap, ServiceInvoiceHeader."No.", SalesCorrectiveInvoiceTxt);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationRequestPageHandler,Declaration340LinesPageHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure CorrInvoicePostedServiceCrMemoOnMake340DeclarationReport()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ExportedFileName: Text[1024];
        CustomerNo: Code[20];
    begin
        // Verify Corrected Invoice Identification in the exported text file.

        // Setup: Create and Post Service Invoice, create Service Credit Memo, update Posted Service Invoice as Corrective Invoice and Post Service Credit Memo.
        Initialize();
        CustomerNo := CreateAndPostMultipleServiceDocument();
        ServiceCrMemoHeader.Get(FindServiceCrMemoHeader(CustomerNo));
        LibraryVariableStorage.Enqueue(ServiceCrMemoHeader."No.");

        // Exercise: Run Report Make 340 Declaration.
        ExportedFileName := RunMake340DeclarationReportSaveTxt();

        // Verify: Verify Corrected Invoice Identification in the exported text file.
        VerifyFieldRecordType(326, ExportedFileName, ServiceCrMemoHeader."Corrected Invoice No.");  // 326 - Starting Position.
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceBookRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VATAmountOnSalesInvoiceBookReport()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Sales Invoice Book report values.

        // Setup: Create Customer, Create and post Sales Invoice with multiple line.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesLine."Document Type"::Invoice, Customer."No.");
        CreateAndUpdateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount());
        CreateAndUpdateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount());
        DocumentNo := PostSalesDocument(SalesHeader."Document Type", SalesHeader."No.");
        LibraryVariableStorage.Enqueue(DocumentNo);

        // Exercise.
        REPORT.Run(REPORT::"Sales Invoice Book");  // Open SalesInvoiceBookRequestPageHandler.

        // Verify: Verify Sales Invoice Book report values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VATEntryDocumentNoCap, DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists(VATBufferBaseCap, (SalesLine.Amount + SalesLine2.Amount));
        LibraryReportDataset.AssertElementWithValueExists(VATBufferVATCap, SalesLine."VAT %");
        LibraryReportDataset.AssertElementWithValueExists(
          VATBufferAmountCap, ((SalesLine.Amount + SalesLine2.Amount) * SalesLine."VAT %") / 100);
    end;

    [Test]
    [HandlerFunctions('PurchasesAutoCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAutoCreditMemoReportWithEUVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocumentNo: Code[20];
        VATProdPostingGroup: Code[20];
        VendorNo: Code[20];
    begin
        // Verify Purchase - AutoCredit Memo report values.

        // Setup: Create and update Vendor, create and post Purchase Credit Memo with EU Vendor.
        Initialize();
        VendorNo := CreateAndUpdateVendor(VATProdPostingGroup);
        CreateAndUpdatePurchaseHeader(PurchaseHeader, VendorNo, PurchaseHeader."Document Type"::"Credit Memo");
        CreateAndUpdatePurchaseLine(PurchaseLine, PurchaseHeader, VATProdPostingGroup);
        CreateAndUpdatePurchaseLine(PurchaseLine2, PurchaseHeader, VATProdPostingGroup);
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryVariableStorage.Enqueue(DocumentNo);

        // Exercise.
        REPORT.Run(REPORT::"Purchases - AutoCredit Memo");  // Open PurchaseAutoCreditMemoRequestPageHandler.

        // Verify: Verify Purchase - AutoCredit Memo report values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PurchCrMemoHdrNoCap, DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists(PurchCrMemoLineQuantityCap, PurchaseLine.Quantity);
        LibraryReportDataset.AssertElementWithValueExists(PurchCrMemoLineQuantityCap, PurchaseLine2.Quantity);
        LibraryReportDataset.AssertElementWithValueExists(VATAmountLineVATECBaseCap, PurchaseLine.Amount + PurchaseLine2.Amount);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostMultipleServiceDocument(): Code[20]
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        CreateServiceDocument(
          ServiceLine, ServiceLine."Document Type"::Invoice, ServiceLine.Type::Item, CreateCustomer(), LibraryInventory.CreateItem(Item));
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateServiceDocument(
          ServiceLine, ServiceHeader."Document Type"::"Credit Memo", ServiceLine.Type::Item, ServiceLine."Customer No.", ServiceLine."No.");
        ServiceHeader.Get(ServiceHeader."Document Type"::"Credit Memo", ServiceLine."Document No.");
        ServiceHeader.Validate("Corrected Invoice No.", FindServiceInvoiceHeader(ServiceLine."Customer No."));
        ServiceHeader.Modify(true);
        PostServiceDocument(ServiceLine."Document Type", ServiceLine."Document No.");
        exit(ServiceLine."Customer No.");
    end;

    local procedure CreateAndPostMultiplePurchaseDocument() DocumentNo: Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo2: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Invoice, Vendor."No.", PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item));
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Return Order", Vendor."No.", PurchaseLine.Type::Item, PurchaseLine."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Corrected Invoice No.", DocumentNo);
        PurchaseHeader.Modify(true);
        DocumentNo2 := PostPurchaseDocument(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryVariableStorage.Enqueue(DocumentNo2);
    end;

    local procedure CreateAndPostMultipleSalesDocument(DocumentType: Enum "Sales Document Type") DocumentNo: Code[20]
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo2: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, Customer."No.", LibraryInventory.CreateItem(Item));
        DocumentNo := PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesDocument(SalesLine, DocumentType, Customer."No.", SalesLine."No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Corrected Invoice No.", DocumentNo);
        SalesHeader.Modify(true);
        DocumentNo2 := PostSalesDocument(SalesLine."Document Type", SalesLine."Document No.");
        LibraryVariableStorage.Enqueue(DocumentNo2);
    end;

    local procedure CreateAndUpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateAndUpdateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndUpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPostingGroup: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateAndUpdateItem(VATProdPostingGroup),
          LibraryRandom.RandDec(10, 2));  // Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndUpdateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, Type, No, LibraryRandom.RandInt(10));  // Random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Modify(true);
    end;

    local procedure CreateAndUpdateVendor(var VATProdPostingGroup: Code[20]): Code[20]
    var
        CompanyInformation: Record "Company Information";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        Vendor: Record Vendor;
    begin
        CompanyInformation.Get();
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CompanyInformation."Country/Region Code");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATProdPostingGroup := VATPostingSetup."VAT Prod. Posting Group";
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        Vendor.Validate("VAT Registration No.", VATRegistrationNoFormat.Format);
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndUpdatePurchaseHeader(PurchaseHeader, VendorNo, DocumentType);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Random Quantity.
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateAndUpdateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo);
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; Type: Enum "Service Line Type"; CustomerNo: Code[20]; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        CreateServiceLine(ServiceLine, DocumentType, ServiceHeader."No.", Type, No);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; DocumentNo: Code[20]; Type: Enum "Service Line Type"; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(DocumentType, DocumentNo);
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ServiceLine.Modify(true);
    end;

    local procedure PostServiceDocument(DocumentType: Enum "Service Document Type"; No: Code[20])
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader.Get(DocumentType, No);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
    end;

    local procedure InvokePagePostedServiceCreditMemos(CustomerNo: Code[20])
    var
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.FILTER.SetFilter("Customer No.", CustomerNo);
        PostedServiceInvoice.FindCorrectiveInvoices.Invoke();
    end;

    local procedure FindSalesCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; DocumentNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesInvoiceHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();
    end;

    local procedure FindServiceInvoiceHeader(CustomerNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Customer No.", CustomerNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure FindServiceCrMemoHeader(CustomerNo: Code[20]): Code[20]
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Customer No.", CustomerNo);
        ServiceCrMemoHeader.FindFirst();
        exit(ServiceCrMemoHeader."No.");
    end;

    local procedure GetDateAsNumber(Date: Date) DateAsNumber: Text[8]
    var
        Year: Text[4];
        Month: Text[2];
        Day: Text[2];
    begin
        Year := Format(Date2DMY(Date, 3));
        Month := Format(Date2DMY(Date, 2));
        Day := Format(Date2DMY(Date, 1));
        if StrLen(Month) < 2 then
            Month := '0' + Month;
        if StrLen(Day) < 2 then
            Day := '0' + Day;
        DateAsNumber := Year + Month + Day;
    end;

    local procedure GenerateRandomCode(NumberOfDigit: Integer) IntegerCode: Text[1024]
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfDigit do
            IntegerCode := InsStr(IntegerCode, Format(LibraryRandom.RandInt(9)), Counter);
    end;

    local procedure PostPurchaseDocument(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, DocumentNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesDocument(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure RunMake340DeclarationReportSaveTxt() ExportedFileName: Text[1024]
    var
        Make340Declaration: Report "Make 340 Declaration";
    begin
        ExportedFileName := TemporaryPath + 'ES340.txt';
        if Exists(ExportedFileName) then
            Erase(ExportedFileName);

        // Run Report Make 340 Declaration with filters.
        Clear(Make340Declaration);
        Make340Declaration.UseRequestPage(true);

        // Generate Code for - Contact Name,Telephone Number required 9 digit, Electronic Code required 16 digit and Declaration No. required 4 digit.
        // 0 - Min. Payment Amount and Declaration Media Type - Telematic, False - Replace Declaration, Blank - Previous Declaration Number and G/L Account Number, True - Test Run.
        Make340Declaration.InitializeRequest(
          Format(Date2DMY(WorkDate(), 3)), Date2DMY(WorkDate(), 2), GenerateRandomCode(LibraryRandom.RandInt(10)),
          GenerateRandomCode(9), GenerateRandomCode(4), GenerateRandomCode(16), 0, false, '', ExportedFileName, '', 0.0);
        Make340Declaration.RunModal();
        Make340Declaration.GetServerFileName(ExportedFileName);
    end;

    local procedure VerifyDocumentNoAndCorrectiveInvoice(DocumentNoTxt: Text; CorrectiveInvoiceTxt: Text; DocumentNo: Variant; CorrectiveInvoice: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DocumentNoTxt, DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists(CorrectiveInvoiceTxt, StrSubstNo(CorrectiveInvoice));
    end;

    local procedure VerifyFieldRecordType(StartingPosition: Integer; FileName: Text[1024]; ExpectedValue: Text[1024])
    var
        FieldValue: Text[1024];
    begin
        FieldValue :=
          LibraryTextFileValidation.ReadValue(LibraryTextFileValidation.FindLineWithValue(FileName, StartingPosition,
              StrLen(ExpectedValue), ExpectedValue), StartingPosition, StrLen(ExpectedValue));
        Assert.AreEqual(ExpectedValue, FieldValue, StrSubstNo(FieldsAreNotEqualMsg, ExpectedValue, FieldValue));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make340DeclarationRequestPageHandler(var Make340Declaration: TestRequestPage "Make 340 Declaration")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        Make340Declaration.VATEntry.SetFilter("Document No.", DocumentNo);
        Make340Declaration.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure Declaration340LinesPageHandler(var Declaration340Lines: TestPage "340 Declaration Lines")
    begin
        Declaration340Lines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasesAutoCreditMemoRequestPageHandler(var PurchasesAutoCreditMemo: TestRequestPage "Purchases - AutoCredit Memo")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PurchasesAutoCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceBookRequestPageHandler(var SalesInvoiceBook: TestRequestPage "Sales Invoice Book")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        SalesInvoiceBook.VATEntry.SetFilter("Document No.", DocumentNo);
        SalesInvoiceBook.ShowAutoInvoicesAutoCrMemo.SetValue(true);
        SalesInvoiceBook.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoRequestPageHandler(var ServiceCreditMemo: TestRequestPage "Service - Credit Memo")
    begin
        ServiceCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExportedSuccessfullyMessageHandler(Message: Text[1024])
    begin
    end;
}

