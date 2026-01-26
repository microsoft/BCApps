codeunit 144048 "ERM Make 340 Declaration"
{
    // // [FEATURE] [Export] [Make 340 Declaration]
    // Test For Report - Make 340 Declaration.
    // 1. Test to verify Operation Code and Customer Number on Report 10743 - Make 340 Declaration, when fields - Property Location, Property Tax Account Number and Operation code filled on 340 Declaration Lines.
    // 2. Test to verify No of Registers and Customer Number on Report 10743 - Make 340 Declaration.
    // 3. Test to verify Operation Code and Document Number on Report 10743 - Make 340 Declaration for Sales Credit Memos with multiple lines with VAT Percent - 0.
    // 4. Test to verify Amount on Report 10743 - Make 340 Declaration, Create and Post multiple Sales Invoice.
    // 5. Test to verify Amount on Report 10743 - Make 340 Declaration, Create and Post multiple Sales Invoice When Posting Date more than WORKDATE.
    // 6. Test to verify Values on Report 10743 - Make 340 Declaration, after changing the length of Company Name, Address and Address2 and length to 50 characters.
    // 7. Test to verify Values on Report 10743 - Make 340 Declaration, when having two posted Prchase Journal lines with the same Document No and Posting Date in different years.
    // 8. Purchase Invoice posted between Unrealized VAT Invoice with applied Payment should appear in the 340 Declaration
    // 9. Sales Invoice posted between Unrealized VAT Invoice with applied Payment should appear in the 340 Declaration
    // 
    // Covers Test Cases for WI - 351136.
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ----------------------------------------------------------------------------------------------
    // RunMake340DeclarationForSalesInvoiceWithOperationCode                            319171,319158
    // RunMake340DeclarationForSalesInvoiceWithNoOfRegister                             319173,318675
    // RunMake340DeclarationForSalesCreditMemoWithMultipleLine                          318677,319168
    // RunMake340DeclarationForMultiSalesInvPostingDate,                                319169,318677
    // RunMake340DeclarationForMultiSalesInvGreaterPostingDate
    // 
    // Covers Test Cases for WI - 351903.
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ----------------------------------------------------------------------------------------------
    // RunMake340DeclarationPurchaseInvoiceUpdatedCompanyInfo                                 156905
    // 
    // Covers Test Cases for TFS 90971.
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                     TFS ID
    // ----------------------------------------------------------------------------------------------
    // RunMake340DeclarationPurchJournalLinesWithSameDocNo                                    90971
    // 
    // Covers Test Cases for TFS 360956.
    // ----------------------------------------------------------------------------------------------
    // RunMake340NormalPurchAndUnrealizedPurchWithAppln
    // RunMake340NormalSaleAndUnrealizedSaleWithAppln

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryMake340Declaration: Codeunit "Library - Make 340 Declaration";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryVariableStorageVerifyValues: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        ExpectedValueTxt: Label 'D';
        NoOfRegistersTxt: Label '01';
        ValueNotFoundMsg: Label 'Value Not found.';
        IncorrectLineCountErr: Label 'Incorrect Line Count for %1';
        Decl340LinesCountErr: Label 'Expected only one declaration line';
        LibraryJournals: Codeunit "Library - Journals";
        IsInitialized: Boolean;
        LineNotFoundErr: Label 'File line is not found';
        IncorrectValueErr: Label 'Incorrect value';

    [Test]
    [HandlerFunctions('Declaration340LinesWithOperationCodePageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationForSalesInvoiceWithOperationCode()
    var
        OperationCode: Code[1];
        OperationCodeStartingPosition: Integer;
    begin
        // [SCENARIO] to verify Operation Code and Customer Number on Report 10743 - Make 340 Declaration, when fields - Property Location, Property Tax Account Number and Operation code filled on 340 Declaration Lines.
        OperationCode := CopyStr(LibraryUtility.GenerateGUID(), 1, 1);  // Operation Code of Length 1 Required.
        OperationCodeStartingPosition := 100;  // Hardcoded values for Known Operation Code - Starting Position in text file.
        RunMake340DeclarationForSalesInvoice(OperationCode, OperationCodeStartingPosition, OperationCode);  // Hardcoded values for Known Starting Position.
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesWithOperationCodePageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationForSalesInvoiceWithNoOfRegister()
    var
        NoOfRegistersStartingPosition: Integer;
    begin
        // [SCENARIO] to verify No of Registers and Customer Number on Report 10743 - Make 340 Declaration.
        NoOfRegistersStartingPosition := 244;
        RunMake340DeclarationForSalesInvoice('', NoOfRegistersStartingPosition, NoOfRegistersTxt);  // Blank Operation Code, Hardcoded values for Known Starting Position.
    end;

    local procedure RunMake340DeclarationForSalesInvoice(OperationCodeCode: Code[1]; StartingPostion: Integer; ExpectedValue: Text[1024])
    var
        OperationCode: Record "Operation Code";
        CustomerNo: Code[20];
        ExportFileName: Text[1024];
        CustomerNoStartingPosition: Integer;
    begin
        // Setup: Create and Post Sales Invoice.
        Initialize();
        CustomerNo := CreateCustomer();
        LibraryMake340Declaration.CreateOperationCode(OperationCode, OperationCodeCode);
        CreateAndPostSalesInvoice(CustomerNo, WorkDate());  // WorkDate() - Posting Date.
        CustomerNoStartingPosition := 36;  // Hardcoded values for Known Posted Customer No - Starting Position in text file.
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        LibraryVariableStorage.Enqueue(OperationCodeCode);  // Enqueue for - Declaration340LinesWithOperationCodePageHandler.

        // Exercise: Open handler - Make340DeclarationHandler and Declaration340LinesWithOperationCodePageHandler.
        ExportFileName := RunMake340DeclarationReport(WorkDate());  // WorkDate() - Posting Date.

        // Verify: Verify Posted Customer Number and Operation Code in Text File, Using Hardcoded values for Known Starting Position.
        VerifyValuesOnGeneratedTextFile(ExportFileName, StartingPostion, CustomerNoStartingPosition, ExpectedValue, CustomerNo);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationForSalesCreditMemoWithMultipleLine()
    var
        DocumentNo: Code[20];
        ExportFileName: Text[1024];
        PostedDocNumberStartingPosition: Integer;
        OperationCodeStartingPosition: Integer;
    begin
        // [SCENARIO] to verify Operation Code and Document Number on Report 10743 - Make 340 Declaration, Create and Post Sales Credit Memos with multiple lines with VAT Percent - 0.

        // [GIVEN] Create and Post Sales Credit Memo with multiple Line.
        Initialize();
        DocumentNo := CreateAndPostSalesCreditMemoWithMultipleLine();
        PostedDocNumberStartingPosition := 218;  // Hardcoded values for Known Post Doc Number - Starting Position in text file.
        OperationCodeStartingPosition := 100;  // Hardcoded values for Known Operation Code - Starting Position in text file.

        // [WHEN] Open handler - Make340DeclarationHandler and Declaration340LinesPageHandler.
        ExportFileName := RunMake340DeclarationReport(WorkDate());  // WorkDate() - Posting Date.

        // [THEN] Verify Posted Document Number and Operation Code in Text File, Using Hardcoded values for Known Starting Position.
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, PostedDocNumberStartingPosition, OperationCodeStartingPosition, DocumentNo, ExpectedValueTxt);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationForMultiSalesInvPostingDate()
    begin
        // [SCENARIO] to verify Amount on Report 10743 - Make 340 Declaration, Create and Post multiple Sales Invoice.

        // Setup.
        Initialize();
        RunMake340DeclarationForMultiSalesInvoice(WorkDate());  // WorkDate() - Posting Date.
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationForMultiSalesInvGreaterPostingDate()
    begin
        // [SCENARIO]  to verify Amount on Report 10743 - Make 340 Declaration, Create and Post multiple Sales Invoice When Posting Date more than WORKDATE.

        // Setup.
        Initialize();
        RunMake340DeclarationForMultiSalesInvoice(CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));  // Random - Posting Date more than WORKDATE.
    end;

    local procedure RunMake340DeclarationForMultiSalesInvoice(PostingDate: Date)
    var
        Amount: Decimal;
        Amount2: Decimal;
        CustomerNo: Code[20];
        ExportFileName: Text[1024];
        AmountStartingPosition: Integer;
        Shift: Integer;
    begin
        // Create and Post multiple Sales Invoice.
        CustomerNo := CreateCustomer();
        Amount := CreateAndPostSalesInvoice(CustomerNo, PostingDate);
        Amount2 := CreateAndPostSalesInvoice(CustomerNo, PostingDate);
        Amount := Round(Amount, 0.01);
        Shift := StrLen(Format(Amount * 100, 0, '<Integer>'));

        AmountStartingPosition := 135 - Shift + 1;  // 135-last simbol of Amount fld

        // Exercise: Open handler - Make340DeclarationHandler and Declaration340LinesPageHandler.
        ExportFileName := RunMake340DeclarationReport(PostingDate);

        // Verify: Verify Amount in Text File, Using Hardcoded values for Known Starting Position.
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, AmountStartingPosition, AmountStartingPosition, DelChr(Format(Amount), '=', ','), DelChr(Format(Amount2), '=', ','));
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationPurchaseInvoiceUpdatedCompanyInfo()
    var
        PurchaseHeader: Record "Purchase Header";
        CompanyNameStartingPosition: Integer;
        VendorNumberStartingPosition: Integer;
        CompanyName: Text[50];
        ExportFileName: Text[1024];
    begin
        // [SCENARIO] to verify Values on Report 10743 - Make 340 Declaration, after changing the length of Company Name, Address and Address2 and length to 50 characters.

        // [GIVEN] Update Company Information - Name, Address and Address2 , Create and Post Purchase Invoice.
        Initialize();
        CompanyNameStartingPosition := 18;  // Hardcoded values for Known Company Name - Starting Position in text file.
        VendorNumberStartingPosition := 36;  // Hardcoded values for Known Vendor Number - Starting Position in text file.
        CompanyName := CopyStr(GenerateRandomCode(50), 1, 50);
        UpdateCompanyInformationNameAndAddress(CompanyName, CompanyName, CompanyName);  // Address and Address2 of length - 50.
        CreateAndPostPurchaseInvoiceNewVendor(PurchaseHeader);
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");  // Enqueue value for handler - Make340DeclarationHandler.

        // [WHEN] Open handler - Make340DeclarationHandler and Declaration340LinesPageHandler.
        ExportFileName := RunMake340DeclarationReport(WorkDate());  // WorkDate() - Posting Date.

        // [THEN] Verify Company Name and Vendor Number in Text File.
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, CompanyNameStartingPosition, VendorNumberStartingPosition, CopyStr(CompanyName, 1, 40),
          PurchaseHeader."Buy-from Vendor No.");  // Company Name length 40 characters in exported File.
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationPurchJournalLinesWithSameDocNo()
    var
        Amount: Decimal;
        VendorNo: Code[20];
        PrevNoSeries: Code[20];
        ExportFileName: Text[1024];
        AmountStartingPosition: Integer;
        VendorNumberStartingPosition: Integer;
    begin
        // [SCENARIO] to verify Values on Report 10743 - Make 340 Declaration, when having two posted Purchase Journal lines with the same Document No and Posting Date in different years.

        // [GIVEN]
        Initialize();
        PrevNoSeries := SetupPurchaseJournalNoSeries(CreateNoSeries());
        VendorNo := CreateVendor();
        CreateAndPostPurchaseJournal(VendorNo, CalcDate('<-1Y>', WorkDate()));
        Amount := CreateAndPostPurchaseJournal(VendorNo, WorkDate());
        AmountStartingPosition := 159;  // Hardcoded values for Known Amount - Starting Position in text file.
        VendorNumberStartingPosition := 36;  // Hardcoded values for Known Vendor Number - Starting Position in text file.
        LibraryVariableStorage.Enqueue(VendorNo);  // Enqueue value for handler - Make340DeclarationHandler.
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));

        // [WHEN] Open handler - Make340DeclarationHandler and Declaration340LinesPageHandler.
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Verify Amount and Vendor No in Text File, Using Hardcoded values for Known Starting Position.
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, AmountStartingPosition, VendorNumberStartingPosition,
          DelChr(Format(Amount), '=', ',.'), VendorNo);

        // Teardown
        SetupPurchaseJournalNoSeries(PrevNoSeries);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340NormalPurchAndUnrealizedPurchWithAppln()
    var
        UnrealizedVATPostingSetup: Record "VAT Posting Setup";
        NormalVATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        NormalInvoiceNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [SCENARIO] Purchase Invoice posted between Unrealized VAT Invoice with applied Payment should appear in the 340 Declaration
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);

        // [GIVEN] Create VAT Posting Setup, set up new Vendor
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup.Code);
        CreateVATPostingSetup(UnrealizedVATPostingSetup,
          VATBusinessPostingGroup.Code, UnrealizedVATPostingSetup."Unrealized VAT Type"::Percentage, false);
        CreateVATPostingSetup(NormalVATPostingSetup,
          VATBusinessPostingGroup.Code, NormalVATPostingSetup."Unrealized VAT Type"::" ", false);
        // [GIVEN] Post Invoice "InvU" with Unrealized VAT on date "D"
        InvoiceNo :=
          CreateAndPostPurchaseDocOnDate(
            PurchaseHeader."Document Type"::Invoice, VendorNo,
            UnrealizedVATPostingSetup, CalcDate('<-CM>', WorkDate()));
        // [GIVEN] Post Invoice "InvN" with Normal VAT on date "D"+1d
        NormalInvoiceNo :=
          CreateAndPostPurchaseDocOnDate(
            PurchaseHeader."Document Type"::Invoice, VendorNo,
            NormalVATPostingSetup, CalcDate('<-CM+1D>', WorkDate()));
        FindVendorLedgerEntry(VendorLedgerEntry, VendorNo, VendorLedgerEntry."Document Type"::Invoice, NormalInvoiceNo);
        // [GIVEN] Post Payment at the end of the month and apply to Invoice "InvU"
        CreatePostApplyPurchasePayment(VendorNo, CalcDate('<CM>', WorkDate()), InvoiceNo);

        // [WHEN] Export by report 'Make 340 Declaration'
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Amount and "Document No." of Invoice "InvN" exist in 340 Declaration on hardcoded 150 and 218 positions respectively
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 150, 218,
          DelChr(FormatAmount(-VendorLedgerEntry.Amount), '=', ',.'), NormalInvoiceNo);
        // [THEN] NoOfRecords is equal to 2 in header line on 146 position
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 146, 218, Format(2), NormalInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340NormalSaleAndUnrealizedSaleWithAppln()
    var
        UnrealizedVATPostingSetup: Record "VAT Posting Setup";
        NormalVATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        NormalInvoiceNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [SCENARIO] Sales Invoice posted between Unrealized VAT Invoice with applied Payment should appear in the 340 Declaration
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);

        // [GIVEN] Create VAT Posting Setup, set up new Customer
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusinessPostingGroup.Code);
        CreateVATPostingSetup(UnrealizedVATPostingSetup,
          VATBusinessPostingGroup.Code, UnrealizedVATPostingSetup."Unrealized VAT Type"::Percentage, false);
        CreateVATPostingSetup(NormalVATPostingSetup,
          VATBusinessPostingGroup.Code, NormalVATPostingSetup."Unrealized VAT Type"::" ", false);
        // [GIVEN] Post Invoice "InvU" with Unrealized VAT on date "D"
        InvoiceNo := CreateAndPostSalesInvoiceWithVAT(CustomerNo, UnrealizedVATPostingSetup, CalcDate('<-CM>', WorkDate()));
        // [GIVEN] Post Invoice "InvN" with Normal VAT on date "D"+1d
        NormalInvoiceNo := CreateAndPostSalesInvoiceWithVAT(
            CustomerNo, NormalVATPostingSetup, CalcDate('<-CM+1D>', WorkDate()));
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Invoice, NormalInvoiceNo);
        // [GIVEN] Post Payment at the end of the month and apply to Invoice "InvU"
        CreatePostApplySalesPayment(CustomerNo, CalcDate('<CM>', WorkDate()), InvoiceNo);

        // [WHEN] Export by report 'Make 340 Declaration'
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Amount and "Document No." of Invoice "InvN" exist in 340 Declaration on hardcoded 150 and 218 positions respectively
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 150, 218,
          DelChr(FormatAmount(CustLedgerEntry.Amount), '=', ',.'), NormalInvoiceNo);
        // [THEN] NoOfRecords is equal to 2 in header line on 146 position
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 146, 218, Format(2), NormalInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler,ExportedSuccessfullyMessageHandler,Declaration340LinesPageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationSalesOrderOperationDateEarliestShipmentDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExportFileName: Text[1024];
        OperationDateText: Text[8];
    begin
        // [SCENARIO 360969] Report Make 340 Declaration Operation Date field values is earliest shipment date within the document
        Initialize();
        // [GIVEN] Sales Order
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order,
          CreateCustomer(), CalcDate('<1M>', WorkDate()));
        // [GIVEN] Partial Shipment in Work date + 1 month
        SalesLine.Validate(
          "Qty. to Ship", LibraryRandom.RandIntInRange(1, SalesLine.Quantity - 1));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        // [GIVEN] Ship remaining and Invoice at work date
        SetSalesHeaderPostingDate(SalesHeader, WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [WHEN] User runs report Exported 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());
        OperationDateText := FormatDate(WorkDate());
        // [THEN] 'Operation Date' field value in exported field equals to the Date of earliest Shipment
        Assert.AreEqual(
          OperationDateText,
          LibraryTextFileValidation.ReadValueFromLine(
            ExportFileName, 2, 109, MaxStrLen(OperationDateText)),
          ValueNotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler,ExportedSuccessfullyMessageHandler,Declaration340LinesPageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationPurchaseOrderOperationDateEarliestReceiptDate()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExportFileName: Text[1024];
        OperationDateText: Text[8];
    begin
        // [SCENARIO] Report Make 340 Declaration Operation Date field values is earliest receipt date within the document
        Initialize();
        // [GIVEN] Purchase Order
        CreatePurchDocument(
          PurchHeader, PurchLine, PurchHeader."Document Type"::Order,
          CreateVendor(), CalcDate('<1M>', WorkDate()));
        // [GIVEN] Partial Receipt in Work date + 1 month
        PurchLine.Validate(
          "Qty. to Receive", LibraryRandom.RandIntInRange(1, PurchLine.Quantity - 1));
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, false);
        // [GIVEN] Receive remaining and Invoice at work date
        SetPurchHeaderPostingDate(PurchHeader, WorkDate());
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        LibraryVariableStorage.Enqueue(PurchHeader."Buy-from Vendor No.");
        // [WHEN] User runs report Exported 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());
        OperationDateText := FormatDate(WorkDate());
        // [THEN] 'Operation Date' field value equals to the Date of earliest Receipt
        Assert.AreEqual(
          OperationDateText,
          LibraryTextFileValidation.ReadValueFromLine(
            ExportFileName, 2, 109, MaxStrLen(OperationDateText)),
          ValueNotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler,ExportedSuccessfullyMessageHandler,Declaration340LinesPageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationSalesOrderOperationDatePartialShipAndInvoiceOnDiffDates()
    var
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ExportFileName: Text[1024];
        OperationDateText: Text[8];
    begin
        // [FEATURE] [Sales] [Shipment]
        // [SCENARIO 382070] Report Make 340 Declaration when Sales Order is partially shipped and invoiced on different dates
        Initialize();

        // [GIVEN] Sales Order has "Item1" and "Item2"
        CreateSalesDocument(
          SalesHeader, SalesLine1, SalesHeader."Document Type"::Order, CreateCustomer(), LibraryRandom.RandDate(-5));
        CreateSalesLine(SalesHeader, SalesLine2);

        // [GIVEN] Shipment is posted for "Item1" on 15-01-2016
        SalesLine2.Validate("Qty. to Ship", 0);
        SalesLine2.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Shipment is posted for "Item2" on 16-01-2016
        SetSalesHeaderPostingDate(SalesHeader, WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Sales Invoice is posted on 16-01-2016 for "Item2"
        SalesLine1.Find();
        SalesLine1.Validate("Qty. to Invoice", 0);
        SalesLine1.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] User runs report Make 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());
        OperationDateText := FormatDate(WorkDate());

        // [THEN] 'Operation Date' field value is equal to 16-01-2016
        Assert.AreEqual(
          OperationDateText,
          LibraryTextFileValidation.ReadValueFromLine(
            ExportFileName, 2, 109, MaxStrLen(OperationDateText)),
          ValueNotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler,ExportedSuccessfullyMessageHandler,Declaration340LinesPageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationSalesCrMemoOperationDatePartialReceiptOnDiffDates()
    var
        SalesHeader: Record "Sales Header";
        SalesLine1: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
        ExportFileName: Text[1024];
        OperationDateText: Text[8];
    begin
        // [FEATURE] [Sales] [Return Receipt]
        // [SCENARIO 382070] Report Make 340 Declaration when Sales Return Order is partially received on different dates with Credit Memo
        Initialize();

        // [GIVEN] Sales Order has "Item1" and "Item2"
        CreateSalesDocument(
          SalesHeader, SalesLine1, SalesHeader."Document Type"::"Return Order", CreateCustomer(), LibraryRandom.RandDate(-5));
        CreateSalesLine(SalesHeader, SalesLine2);

        // [GIVEN] Return Receipt is posted for "Item1" on 15-01-2016
        SalesLine2.Validate("Return Qty. to Receive", 0);
        SalesLine2.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Return Receipt is posted for "Item2" on 16-01-2016
        SetSalesHeaderPostingDate(SalesHeader, WorkDate());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Sales Credit Memo is posted on 16-01-2016 for "Item2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        SalesGetReturnReceipts.SetSalesHeader(SalesHeader);
        ReturnReceiptLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        ReturnReceiptLine.SetRange("No.", SalesLine2."No.");
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader."Corrected Invoice No." := ''; // it is empty on manual posting
        SalesCrMemoHeader.Modify();
        Commit();

        // [WHEN] User runs report Make 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());
        OperationDateText := FormatDate(WorkDate());

        // [THEN] 'Operation Date' field value is equal to 16-01-2016
        Assert.AreEqual(
          OperationDateText,
          LibraryTextFileValidation.ReadValueFromLine(
            ExportFileName, 2, 109, MaxStrLen(OperationDateText)),
          ValueNotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler,ExportedSuccessfullyMessageHandler,Declaration340LinesPageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationPurchaseOrderOperationDatePartialReceiveAndInvoiceOnDiffDates()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ExportFileName: Text[1024];
        OperationDateText: Text[8];
    begin
        // [FEATURE] [Purchase] [Receipt]
        // [SCENARIO 382070] Report Make 340 Declaration when Purchase Order is partially received and invoiced on different dates
        Initialize();

        // [GIVEN] Purchase Order has "Item1" and "Item2"
        CreatePurchDocument(
          PurchaseHeader, PurchaseLine1, PurchaseHeader."Document Type"::Order, CreateVendor(), LibraryRandom.RandDate(-5));
        CreatePurchLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandIntInRange(3, 10), LibraryRandom.RandIntInRange(3, 10));

        // [GIVEN] Receipt is posted for "Item1" on 15-01-2016
        PurchaseLine2.Validate("Qty. to Receive", 0);
        PurchaseLine2.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Receipt is posted for "Item2" on 16-01-2016
        SetPurchHeaderPostingDate(PurchaseHeader, WorkDate());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Purchase Invoice is posted on 16-01-2016 for "Item2"
        PurchaseLine1.Find();
        PurchaseLine1.Validate("Qty. to Invoice", 0);
        PurchaseLine1.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] User runs report Make 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());
        OperationDateText := FormatDate(WorkDate());

        // [THEN] 'Operation Date' field value is equal to 16-01-2016
        Assert.AreEqual(
          OperationDateText,
          LibraryTextFileValidation.ReadValueFromLine(
            ExportFileName, 2, 109, MaxStrLen(OperationDateText)),
          ValueNotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler,ExportedSuccessfullyMessageHandler,Declaration340LinesPageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340DeclarationPurchaseCrMemoOperationDatePartialShipmentOnDiffDates()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchGetReturnShipments: Codeunit "Purch.-Get Return Shipments";
        ExportFileName: Text[1024];
        OperationDateText: Text[8];
    begin
        // [FEATURE] [Purchase] [Return Shipment]
        // [SCENARIO 382070] Report Make 340 Declaration when Purchase Order is partially received and invoiced on different dates
        Initialize();

        // [GIVEN] Purchase Order has "Item1" and "Item2"
        CreatePurchDocument(
          PurchaseHeader, PurchaseLine1, PurchaseHeader."Document Type"::"Return Order", CreateVendor(), LibraryRandom.RandDate(-5));
        CreatePurchLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandIntInRange(3, 10), LibraryRandom.RandIntInRange(3, 10));

        // [GIVEN] Shipment is posted for "Item1" on 15-01-2016
        PurchaseLine2.Validate("Return Qty. to Ship", 0);
        PurchaseLine2.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Shipment is posted for "Item2" on 16-01-2016
        SetPurchHeaderPostingDate(PurchaseHeader, WorkDate());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Purchase Credit Memo is posted on 16-01-2016 for "Item2"
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");
        PurchGetReturnShipments.SetPurchHeader(PurchaseHeader);
        ReturnShipmentLine.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        ReturnShipmentLine.SetRange("No.", PurchaseLine2."No.");
        PurchGetReturnShipments.CreateInvLines(ReturnShipmentLine);
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        PurchCrMemoHdr."Corrected Invoice No." := ''; // it is empty on manual posting
        PurchCrMemoHdr.Modify();
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");
        Commit();

        // [WHEN] User runs report Make 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());
        OperationDateText := FormatDate(WorkDate());

        // [THEN] 'Operation Date' field value is equal to 16-01-2016
        Assert.AreEqual(
          OperationDateText,
          LibraryTextFileValidation.ReadValueFromLine(
            ExportFileName, 2, 109, MaxStrLen(OperationDateText)),
          ValueNotFoundMsg);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340PurchDocNoAndDateInMultyUnrealizedDifferentVATAppliedToPayment()
    var
        UnrealizedVATPostingSetupX: Record "VAT Posting Setup";
        UnrealizedVATPostingSetupY: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        InvoiceNoX: Code[20];
        InvoiceNoY: Code[20];
        ExportFileName: Text[1024];
    begin
        // [SCENARIO 120499] Payment should be exported with Posting Date and No of proper Invoice If One Payment Applied to Unrealized Invoices
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);

        // [GIVEN] Create VAT Posting Setup, set up new Vendor
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup.Code);
        CreateVATPostingSetup(UnrealizedVATPostingSetupX,
          VATBusinessPostingGroup.Code, UnrealizedVATPostingSetupX."Unrealized VAT Type"::Percentage, true);
        CreateVATPostingSetup(UnrealizedVATPostingSetupY,
          VATBusinessPostingGroup.Code, UnrealizedVATPostingSetupY."Unrealized VAT Type"::Percentage, true);
        // [GIVEN] Create and Post Purchase Invoices X and Y
        InvoiceNoX :=
          CreateAndPostPurchaseDocOnDate(
            PurchaseHeader."Document Type"::Invoice, VendorNo, UnrealizedVATPostingSetupX, CalcDate('<-CM>', WorkDate()));
        InvoiceNoY :=
          CreateAndPostPurchaseDocOnDate(
            PurchaseHeader."Document Type"::Invoice, VendorNo, UnrealizedVATPostingSetupY, CalcDate('<-CM+1D>', WorkDate()));

        // [GIVEN] Post Payment and apply to both invoices during posting
        CreatePostApplyPurchasePaymentToMultyInv(
          VendorNo, CalcDate('<-CM+10D>', WorkDate()), InvoiceNoX, InvoiceNoY, LibraryUtility.GenerateGUID());

        // [WHEN] Export by report 'Make 340 Declaration'
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Posting Date and "Document No." exist for both Invoices in exported Payment Lines: 2 lines per Invoice, 1 per Payment
        VerifyLineCountForUnrealizedPurchasePaymentValues(InvoiceNoX, ExportFileName, 2, 1);
        VerifyLineCountForUnrealizedPurchasePaymentValues(InvoiceNoY, ExportFileName, 2, 1);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340PurchUngroupLinesInMultyUnrealizedSameVATAppliedToPayment()
    var
        UnrealizedVATPostingSetup: Record "VAT Posting Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        InvoiceNoX: Code[20];
        InvoiceNoY: Code[20];
        ExportFileName: Text[1024];
    begin
        // [SCENARIO 120499] Payment Declaration Line should be ungrouped If One Payment Applied to Unrealized Invoices with the same VAT
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);

        // [GIVEN] Create VAT Posting Setup, set up new Vendor
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup.Code);
        CreateVATPostingSetup(UnrealizedVATPostingSetup,
          VATBusinessPostingGroup.Code, UnrealizedVATPostingSetup."Unrealized VAT Type"::Percentage, true);

        // [GIVEN] Create and Post Purchase Invoices X and Y with the same VATPostingSetup
        InvoiceNoX :=
          CreateAndPostPurchaseDocOnDate(
            PurchaseHeader."Document Type"::Invoice, VendorNo, UnrealizedVATPostingSetup, CalcDate('<-CM>', WorkDate()));
        InvoiceNoY :=
          CreateAndPostPurchaseDocOnDate(
            PurchaseHeader."Document Type"::Invoice, VendorNo, UnrealizedVATPostingSetup, CalcDate('<-CM+1D>', WorkDate()));

        // [GIVEN] Post Payment and apply to both invoices during posting
        CreatePostApplyPurchasePaymentToMultyInv(
          VendorNo, CalcDate('<-CM+10D>', WorkDate()), InvoiceNoX, InvoiceNoY, LibraryUtility.GenerateGUID());

        // [WHEN] Export by report 'Make 340 Declaration'
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Amount and Payment Posting Date exist for each Invoice in 340 Declaration on hardcoded 150 and 100 positions respectively
        // [THEN] Deductible Amount exported for each Invoice in 340 Declaration on 336 position
        VerifyPaymentWithDeductibleAmount(VendorNo, InvoiceNoX, ExportFileName);
        VerifyPaymentWithDeductibleAmount(VendorNo, InvoiceNoY, ExportFileName);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler,VerifyDeclaration340LinesMPH')]
    [Scope('OnPrem')]
    procedure RunMake340PurchInvWithTwoLinesAndDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        TotalAmount: Decimal;
    begin
        // [SCENARIO 362777] Run Make 340 Report generates one total line for two Purchase Invoices Lines with different dimensions
        // [FEATURE] [Dimensions]
        Initialize();

        // [GIVEN] Purchase Invoice with two lines with different dimensions and total amount = "X"
        CreateAndPostPurchaseInvoiceWithTwoLinesAndDims(PurchaseHeader, TotalAmount);

        // [WHEN] Run Make 340 report
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No."); // Make340DeclarationHandler
        LibraryVariableStorageVerifyValues.Enqueue(TotalAmount);
        RunMake340DeclarationReport(WorkDate());

        // [THEN] Report generates one declaration line with amount Base = "X"
        // Verify in VerifyDeclaration340LinesMPH
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler,VerifyDeclaration340LinesMPH')]
    [Scope('OnPrem')]
    procedure RunMake340SalesInvWithTwoLinesAndDimensions()
    var
        SalesHeader: Record "Sales Header";
        TotalAmount: Decimal;
    begin
        // [SCENARIO 362777] Run Make 340 Report generates one total line for two Sales Invoices Lines with different dimensions
        // [FEATURE] [Dimensions]
        Initialize();

        // [GIVEN] Sales Invoice with two lines with different dimensions and total amount = "X"
        CreateAndPostSalesInvoiceWithTwoLinesAndDims(SalesHeader, TotalAmount);

        // [WHEN] Run Make 340 report
        LibraryVariableStorageVerifyValues.Enqueue(TotalAmount); // VerifyDeclaration340LinesMPH
        RunMake340DeclarationReport(WorkDate());

        // [THEN] Report generates one declaration line with amount Base = "X"
        // Verify in VerifyDeclaration340LinesMPH
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveDuplicateAmounts340DeclarationLineUT()
    var
        Rec340DeclarationLinePayment: Record "340 Declaration Line";
        Rec340DeclarationLineRefund: Record "340 Declaration Line";
        Rec340DeclarationLineBill: Record "340 Declaration Line";
        VATEntry: Record "VAT Entry";
    begin
        // [SCENARIO 363693] 340 Declaration Lines function RemoveDuplicateAmounts clears VAT and EC Amounts for Document of types Payment, Refund, Bill
        // [FEATURE] [UT]

        // [GIVEN] 340 Declaration Lines: "P" of Payment Document Type, "R" of Refund Document Type, "B" of Bill Document Type
        // [GIVEN] Fields "VAT Amount","VAT Amount / EC Amount","Amount Including VAT / EC","VAT %","Base","EC %","EC Amount" <> 0
        Create340DeclarationLine(Rec340DeclarationLinePayment, VATEntry."Document Type"::Payment);
        Create340DeclarationLine(Rec340DeclarationLineRefund, VATEntry."Document Type"::Refund);
        Create340DeclarationLine(Rec340DeclarationLineBill, VATEntry."Document Type"::Bill);

        // [WHEN] Run table 340 Declaration Line function RemoveDuplicateAmounts for each line
        Rec340DeclarationLinePayment.RemoveDuplicateAmounts();
        Rec340DeclarationLineRefund.RemoveDuplicateAmounts();
        Rec340DeclarationLineBill.RemoveDuplicateAmounts();

        // [THEN] Fields "VAT Amount","VAT Amount / EC Amount","Amount Including VAT / EC","VAT %","Base","EC %","EC Amount" in Lines "P", "R" and "B" are equal to 0.
        Verify340DeclarationEmptyAmounts(Rec340DeclarationLinePayment);
        Verify340DeclarationEmptyAmounts(Rec340DeclarationLineRefund);
        Verify340DeclarationEmptyAmounts(Rec340DeclarationLineBill);

        Rec340DeclarationLinePayment.Delete();
        Rec340DeclarationLineRefund.Delete();
        Rec340DeclarationLineBill.Delete();
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesVerifyVATECAmountPctHandler,Make340DeclarationHandler')]
    [Scope('OnPrem')]
    procedure RunMake340PurchInvWithECPct()
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PostedDocNo: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 372058] Make 340 Declaration Report generates 340 Declaration Line with EC % and EC Amount

        // [GIVEN] Posted Purchase Invoice with VAT % = 5, VAT Amount = 10, EC % = 4, EC Amount = 8.
        Initialize();
        LibraryMake340Declaration.CreateVATPostingSetup(VATPostingSetup, 21, 5.2);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        PostedDocNo := CreateAndPostPurchaseDocOnDate(PurchaseHeader."Document Type"::Invoice, VendorNo, VATPostingSetup, WorkDate());
        FindVATEntry(VATEntry, VendorNo, VATEntry."Document Type"::Invoice, PostedDocNo);

        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        LibraryVariableStorage.Enqueue(VATEntry."VAT %");
        LibraryVariableStorage.Enqueue(VATEntry.Base * VATEntry."VAT %" / 100);
        LibraryVariableStorage.Enqueue(VATEntry."EC %");
        LibraryVariableStorage.Enqueue(VATEntry.Base * VATEntry."EC %" / 100);

        // [WHEN] Run Make 340 Declaration
        RunMake340DeclarationReport(WorkDate());

        // [THEN] Generated 340 Declaration Line with VAT % = 5, VAT Amount = 10, EC % = 4, EC Amount = 8.
        // Verification done in Declaration340LinesVerifyVATECAmountPctHandler
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340PurchInvWithECPctHeaderLineRounding()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 372057] Make 340 Declaration Report Header and Line Rounding for Purchase

        // [GIVEN] VAT Posting Setup with VAT % = 21, EC % = 5.2
        Initialize();
        LibraryMake340Declaration.CreateVATPostingSetup(VATPostingSetup, 21, 5.2);

        // [GIVEN] Posted Purchase Invoice with 1st Line: Qty = 1, Unit Cost = 86.85
        // [GIVEN] 2nd Line with Qty = 1, Unit Cost = 4.14.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchLineWithUnitCost(
          PurchaseHeader,
          PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::" "),
          1, 86.85);
        CreatePurchLineWithUnitCost(
          PurchaseHeader,
          PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::" "),
          1, 4.14);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Run Make 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Generated text file has value 1911 ( = 19.11, e.g. Total VAT Amount - EC VAT Amount) on position 146 - Header, 1911 on position 179 (Line)
        VerifyValuesOnGeneratedTextFile(ExportFileName, 146, 179, Format(1911), Format(1911));
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340SalesInvWithECPctHeaderLineRounding()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 372057] Make 340 Declaration Report Header and Line Rounding for Sales

        // [GIVEN] VAT Posting Setup with VAT % = 21, EC % = 5.2
        Initialize();
        LibraryMake340Declaration.CreateVATPostingSetup(VATPostingSetup, 21, 5.2);

        // [GIVEN] Posted Sales Invoice with 1st Line: Qty = 1, Unit Cost = 86.85
        // [GIVEN] 2nd Line with Qty = 1, Unit Cost = 4.14.
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreateSalesLineWithUnitPrice(
          SalesHeader,
          SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::" "),
          1, 86.85);
        CreateSalesLineWithUnitPrice(
          SalesHeader,
          SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::" "),
          1, 4.14);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");

        // [WHEN] Run Make 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Generated text file has value 1911 (= 19.11, e.g. Total VAT Amount - EC VAT Amount) on position 146 - Header, 1911 on position 179 (Line)
        VerifyValuesOnGeneratedTextFile(ExportFileName, 146, 179, Format(1911), Format(1911));
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure LineCustVATRegNoWithCountryCodePrefix()
    var
        Customer: Record Customer;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Make 340 Declaration] Customer's VAT Registration number part of file does not contain extra country code prefix
        // in case VAT Registration number has country prefix

        Initialize();

        // [GIVEN] Country with EU Country/Region Code and VAT Registration number of XX########### format
        // [GIVEN] Foreign customer with VAT Registration number of created format
        Customer.Get(
          CreateForeignCustomerWithVATRegNo(
            CreateCountryWithVATRegNoFormat(true)));

        // [GIVEN] Sales invoice posted
        CreateAndPostSalesInvoice(Customer."No.", WorkDate());

        // [WHEN] Run Make 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] VAT Registration field part = country prefix + digital part of Customer."VAT Registration No."
        VerifyCounterpartyLineVATRegNo(
          Customer.Name,
          Customer."VAT Registration No.",
          Customer."Country/Region Code",
          true,
          ExportFileName);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure LineCustVATRegNoWithoutCountryCodePrefix()
    var
        Customer: Record Customer;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Make 340 Declaration] Customer's VAT Registration number part of file does not contain extra country code prefix
        // in case VAT Registration number does not have country prefix

        Initialize();

        // [GIVEN] Country with EU Country/Region Code and VAT Registration number of ########### format
        // [GIVEN] Foreign customer with VAT Registration number of created format
        Customer.Get(
          CreateForeignCustomerWithVATRegNo(
            CreateCountryWithVATRegNoFormat(false)));

        // [GIVEN] Sales invoice posted
        CreateAndPostSalesInvoice(Customer."No.", WorkDate());

        // [WHEN] Run Make 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] VAT Registration field part = country prefix + digital part of Customer."VAT Registration No."
        VerifyCounterpartyLineVATRegNo(
          Customer.Name,
          Customer."VAT Registration No.",
          Customer."Country/Region Code",
          false,
          ExportFileName);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure LineVendVATRegNoWithCountryCodePrefix()
    var
        Vendor: Record Vendor;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Make 340 Declaration] Vendor's VAT Registration number part of file does not contain extra country code prefix
        // in case VAT Registration number has country prefix

        Initialize();

        // [GIVEN] Country with EU Country/Region Code and VAT Registration number of XX########### format
        // [GIVEN] Foreign vendor with VAT Registration number of created format
        Vendor.Get(
          CreateForeignVendorWithVATRegNo(
            CreateCountryWithVATRegNoFormat(true)));

        // [GIVEN] Purchase invoice posted
        CreateAndPostPurchaseInvoice(Vendor."No.", WorkDate());

        // [WHEN] Run Make 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] VAT Registration field part = country prefix + digital part of Vendor."VAT Registration No."
        VerifyCounterpartyLineVATRegNo(
          Vendor.Name,
          Vendor."VAT Registration No.",
          Vendor."Country/Region Code",
          true,
          ExportFileName);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure LineVendVATRegNoWithoutCountryCodePrefix()
    var
        Vendor: Record Vendor;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Make 340 Declaration] Vendor's VAT Registration number part of file does not contain extra country code prefix
        // in case VAT Registration number does not have country prefix

        Initialize();

        // [GIVEN] Country with EU Country/Region Code and VAT Registration number of ########### format
        // [GIVEN] Foreign vendor with VAT Registration number of created format
        Vendor.Get(
          CreateForeignVendorWithVATRegNo(
            CreateCountryWithVATRegNoFormat(false)));

        // [GIVEN] Purchase invoice posted
        CreateAndPostPurchaseInvoice(Vendor."No.", WorkDate());

        // [WHEN] Run Make 340 Declaration
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] VAT Registration field part = country prefix + digital part of Vendor."VAT Registration No."
        VerifyCounterpartyLineVATRegNo(
          Vendor.Name,
          Vendor."VAT Registration No.",
          Vendor."Country/Region Code",
          false,
          ExportFileName);
    end;

    [Test]
    [HandlerFunctions('CarteraDocumentsMPH,ConfirmHandlerYes,MessageHandler,Make340DeclarationHandler,VerifyPartialSettlementDeclaration340LinesMPH')]
    [Scope('OnPrem')]
    procedure BillPartialSettlementUnrealizedVAT()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentOrder: Record "Payment Order";
        VATEntry: array[2] of Record "VAT Entry";
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Bill] [Unrealized VAT] [Partial Settlement]
        // [SCENARIO 211658] VAT Declaration lines have combined amount after Partial Settlement and Total Settlement of Posted Payment Ortder in case of Unrealized VAT Setup
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);

        // [GIVEN] Vendor with Unrealized VAT Setup, "Bill-to-Cartera" Payment Method.
        VendorNo := CreateVendorWithBillToCarteraPaymentMethod(VATPostingSetup);
        // [GIVEN] Post Purchase Invoice. Bill has been automatically created from the Invoice.
        InvoiceNo := CreateAndPostPurchaseDocOnDate(PurchaseHeader."Document Type"::Invoice, VendorNo, VATPostingSetup, WorkDate());
        // [GIVEN] Create Cartera Payment Order.
        CreateCarteraPaymentOrder(PaymentOrder);
        // [GIVEN] Insert posted Bill(Invoice) into Payment Order.
        InsertPayableDocsIntoPaymentOrder(VendorNo, PaymentOrder."No.");
        // [GIVEN] Post Payment Order.
        LibraryCarteraPayables.PostCarteraPaymentOrder(PaymentOrder);
        // [GIVEN] Partial Settle Posted Payment Order.
        RunPartialSettlePayable(PaymentOrder."No.", Round(GetPostedPurchDocAmount(InvoiceNo) / 3));
        FindVATEntry(VATEntry[2], VendorNo, VATEntry[2]."Document Type"::Payment, PaymentOrder."No.");
        // [GIVEN] Total Settle Posted Payment Order.
        RunTotalSettlePayable(PaymentOrder."No.");
        VATEntry[1] := VATEntry[2];
        VATEntry[2].Next();

        // [WHEN] Run "Make 340 Declaration" report
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorageVerifyValues.Enqueue(VATEntry[1].Base + VATEntry[2].Base);
        LibraryVariableStorageVerifyValues.Enqueue(VATEntry[1].Amount + VATEntry[2].Amount);
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] There is one Declaration Line with partial and total settlement amount
        // VerifyPartialSettlementDeclaration340LinesMPH
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 123, 137,
          Format((VATEntry[1].Base + VATEntry[2].Base) * 100, 0, '<Integer,13><Filler Character,0>'),
          Format((VATEntry[1].Amount + VATEntry[2].Amount) * 100, 0, '<Integer,13><Filler Character,0>'));
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NoTaxVATPurchaseSingleInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        InvNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [No Taxable VAT] [Purchase]
        // [SCENARIO 210613] Purchase Invoice with "VAT Calculation Type" = "No Taxable VAT" should appear in the 340 Declaration

        Initialize();

        // [GIVEN] Vendor with "Country/Code" = "GB"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", 0);
        CreateVendorWithCountryCodeAndVATBusPostingGroup(Vendor, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Posted Purchase Invoice with "No Taxable VAT" with Amount = 100 and "Vendor Invoice No." = "INV1"
        InvNo := CreateAndPostPurchaseDocOnDate(PurchaseHeader."Document Type"::Invoice, Vendor."No.", VATPostingSetup, WorkDate());
        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", VendorLedgerEntry."Document Type"::Invoice, InvNo);

        // [WHEN] Export by report 'Make 340 Declaration'
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Verify Amount = 100, "Document No." = "INV1" and "Country Code" = "GB" in exported file
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 122, 178, DelChr(FormatAmount(-VendorLedgerEntry.Amount), '=', ',.'), VendorLedgerEntry."External Document No.");
        VerifyEUCountryRegionCodeOnGeneratedTextFile(ExportFileName, Vendor."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NoTaxVATPurchaseSingleCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        CrMemoNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [No Taxable VAT] [Purchase]
        // [SCENARIO 210613] Purchase Credit Memo with "VAT Calculation Type" = "No Taxable VAT" should appear in the 340 Declaration

        Initialize();

        // [GIVEN] Posted Purchase Credit Memo with "No Taxable VAT" with Amount = 100 and "Vendor Credit Memo No." = "CR1"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", 0);
        CreateVendorWithCountryCodeAndVATBusPostingGroup(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        CrMemoNo := CreateAndPostPurchaseDocOnDate(PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.", VATPostingSetup, WorkDate());
        FindVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", VendorLedgerEntry."Document Type"::"Credit Memo", CrMemoNo);

        // [WHEN] Export by report 'Make 340 Declaration'
        LibraryVariableStorage.Enqueue(Vendor."No.");
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Verify Amount = -100 and "Document No." = "CR1" in exported file
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 122, 178, DelChr(FormatAmount(-VendorLedgerEntry.Amount), '=', ',.'), VendorLedgerEntry."External Document No.");
        VerifyEUCountryRegionCodeOnGeneratedTextFile(ExportFileName, Vendor."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NoTaxVATSalesSingleInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [No Taxable VAT] [Sales]
        // [SCENARIO 210613] Sales Invoice with "VAT Calculation Type" = "No Taxable VAT" should appear in the 340 Declaration

        Initialize();

        // [GIVEN] Posted Sales Invoice with "No Taxable VAT" with Amount = 100 and " No." = "INV1"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", 0);
        CreateCustomerWithCountryCodeAndVATBusPostingGroup(Customer, VATPostingSetup."VAT Bus. Posting Group");
        InvNo :=
          CreateAndPostSalesDocWithVATPostingSetup(SalesHeader."Document Type"::Invoice, Customer."No.", VATPostingSetup, WorkDate());
        FindCustomerLedgerEntry(CustLedgerEntry, Customer."No.", CustLedgerEntry."Document Type"::Invoice, InvNo);

        // [WHEN] Export by report 'Make 340 Declaration'
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Verify Amount = 100 and "Document No." = "INV1" in exported file
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 122, 178, DelChr(FormatAmount(CustLedgerEntry.Amount), '=', ',.'), CustLedgerEntry."Document No.");
        VerifyEUCountryRegionCodeOnGeneratedTextFile(ExportFileName, Customer."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NoTaxVATSalesSingleCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [No Taxable VAT] [Sales]
        // [SCENARIO 210613] Sales Credit Memo with "VAT Calculation Type" = "No Taxable VAT" should appear in the 340 Declaration

        Initialize();

        // [GIVEN] Posted Sales Credit Memo with "No Taxable VAT" with Amount = 100 and "No." = "CR1"
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"No Taxable VAT", 0);
        CreateCustomerWithCountryCodeAndVATBusPostingGroup(Customer, VATPostingSetup."VAT Bus. Posting Group");
        InvNo :=
          CreateAndPostSalesDocWithVATPostingSetup(SalesHeader."Document Type"::"Credit Memo", Customer."No.", VATPostingSetup, WorkDate());
        FindCustomerLedgerEntry(CustLedgerEntry, Customer."No.", CustLedgerEntry."Document Type"::"Credit Memo", InvNo);

        // [WHEN] Export by report 'Make 340 Declaration'
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Verify Amount = -100 and "Document No." = "CR1" in exported file
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 122, 178, DelChr(FormatAmount(CustLedgerEntry.Amount), '=', ',.'), CustLedgerEntry."Document No.");
        VerifyEUCountryRegionCodeOnGeneratedTextFile(ExportFileName, Customer."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure TwoLinesWithhDiffDimOfPurchUnrealizedBillCombinedIn340Declaration()
    var
        PaymentMethod: Record "Payment Method";
        UnrealizedVATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        InvoiceNo: Code[20];
        ExportFileName: Text[1024];
        TotalAmount: Decimal;
    begin
        // [SCENARIO 211658] Purchase Invoice posted as Bill with Unrealized VAT and two lines with different dim should appear as one line in the 340 Declaration

        Initialize();

        // [GIVEN] Vendor "V"
        SetupUnrealizedVAT(UnrealizedVATPostingSetup);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(UnrealizedVATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Payment Method "X" with "Create Bills" = Yes
        LibraryCarteraPayables.CreateBillToCarteraPaymentMethod(PaymentMethod);

        // [GIVEN] Post Invoice "Y" with Vendor "V", Unrealized VAT, Payment Method "X" and two lines with different dimensions and Total amount = 200
        InvoiceNo :=
          PostPurchInvWithPmtMethodTwoLinesDiffDimAndVATProdPostingGroup(
            TotalAmount, VendorNo, PaymentMethod.Code, UnrealizedVATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Post Payment and apply to Bill "Y" created for invoice "Y"
        CreatePostApplyPurchaseBill(VendorNo, InvoiceNo);

        // [WHEN] Invoke report "Make 340 Declaration" for Vendor "V"
        LibraryVariableStorage.Enqueue(VendorNo);
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Total Amount of Bill "Y" = 200 exists in 340 Declaration
        VerifyValueOnGeneratedTextFile(ExportFileName, 122, DelChr(FormatAmount(TotalAmount), '=', ',.'));
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure TwoLinesWithhDiffDimOfSalesUnrealizedBillCombinedIn340Declaration()
    var
        PaymentMethod: Record "Payment Method";
        UnrealizedVATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        ExportFileName: Text[1024];
        TotalAmount: Decimal;
    begin
        // [SCENARIO 211658] Sales Invoice posted as Bill with Unrealized VAT and two lines with different dim should appear as one line in the 340 Declaration

        Initialize();

        // [GIVEN] Customer "C"
        SetupUnrealizedVAT(UnrealizedVATPostingSetup);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(UnrealizedVATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Payment Method "X" with "Create Bills" = Yes
        LibraryCarteraPayables.CreateBillToCarteraPaymentMethod(PaymentMethod);

        // [GIVEN] Post Invoice "Y" with Customer "C", Unrealized VAT, Payment Method "X" and two lines with different dimensions and Total amount = 200
        InvoiceNo :=
          PostSalesInvWithPmtMethodTwoLinesDiffDimAndVATProdPostingGroup(
            TotalAmount, CustomerNo, PaymentMethod.Code, UnrealizedVATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Post Payment and apply to Bill "Y" created for invoice "Y"
        CreatePostApplySalesBill(CustomerNo, InvoiceNo);

        // [WHEN] Invoke report "Make 340 Declaration" for Customer "C"
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(Date2DMY(WorkDate(), 2));
        ExportFileName := RunMake340DeclarationReport(WorkDate());

        // [THEN] Total Amount of Bill "Y" = 200 exists in 340 Declaration
        VerifyValueOnGeneratedTextFile(ExportFileName, 122, DelChr(FormatAmount(TotalAmount), '=', ',.'));
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler,VerifyDeclaration340LinesOperationCodeMPH')]
    [Scope('OnPrem')]
    procedure RunMake340PurchInvWithTwoLinesAndDimensionsAndOperationCode()
    var
        PurchaseHeader: Record "Purchase Header";
        OperationCode: Code[1];
        TotalAmount: Decimal;
        VendorInvNo: Code[35];
    begin
        // [SCENARIO 213537] Run Make 340 Report for two Purchase Invoice's Lines with different dimensions and Operation Code
        // [FEATURE] [Dimensions]
        Initialize();

        // [GIVEN] Purchase Invoice with two lines with different dimensions and total amount = "X"
        // [GIVEN] Operation Code has 'R' value for used Gen. Prod. Posting Group
        OperationCode := 'R';
        VendorInvNo := CreateAndPostPurchaseInvoiceWithTwoLinesAndDimsAndOperationCode(PurchaseHeader, TotalAmount, OperationCode);

        // [WHEN] Run Make 340 Declaration report
        LibraryVariableStorage.Enqueue(PurchaseHeader."Buy-from Vendor No."); // Make340DeclarationHandler
        LibraryVariableStorageVerifyValues.Enqueue(VendorInvNo);
        LibraryVariableStorageVerifyValues.Enqueue(TotalAmount);
        LibraryVariableStorageVerifyValues.Enqueue(OperationCode);

        RunMake340DeclarationReport(WorkDate());

        // [THEN] Report generates one declaration line with amount Base = "X"
        // [THEN] Operation Code field has 'R' value
        // Verify in VerifyDeclaration340LinesOperationCodeMPH
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure RunMake340PurchDocMultiLinesRevChrgUnrealVATAppliedToPayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        PostedDocNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Unrealized VAT]
        // [SCENARIO 268945] Report "Make 340 Declaration" exports summarized VAT Amount in case of multiple Unrealized VAT
        Initialize();

        // [GIVEN] Unrealized VAT was activated in General Ledger Setup
        LibraryERM.SetUnrealizedVAT(true);

        // [GIVEN] VAT Posting Setup with Reverse Charge, VAT Rate = 20%
        CreateVATPostingSetupRevCharge(VATPostingSetup);

        // [GIVEN] Posted Invoice with 2 lines: 1st with Amount = 1000 and 2nd with Amount = 800 (with total VAT Amount = 360)
        CreatePurchaseInvoiceWithTwoLines(
          PurchaseHeader, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Posted Payment for Invoice
        CreatePostPaymentForInvoice(GenJournalLine, PostedDocNo);

        // [WHEN] Run "Make 340 Declaration" report
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        ExportFileName := RunMake340DeclarationReport(GenJournalLine."Posting Date");

        // [THEN] Exported file has one line with VAT Amount at position 337 ='000000036000'
        VerifyValueOnGeneratedTextFile(
          ExportFileName, 337, DelChr(FormatAmount(GetTotalVATAmountFromVATEntries(VATPostingSetup."VAT Prod. Posting Group")), '=', ' '));
        Assert.AreEqual(
          1,
          LibraryTextFileValidation.CountNoOfLinesWithValue(
            ExportFileName, PurchaseHeader."Vendor Invoice No.", 178, StrLen(PurchaseHeader."Vendor Invoice No.")),
          StrSubstNo(IncorrectLineCountErr, PurchaseHeader.FieldCaption("Vendor Invoice No.")));
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        OperationCode: Record "Operation Code";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryVariableStorage.Clear();
        LibraryVariableStorageVerifyValues.Clear();
        OperationCode.DeleteAll();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();
        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Company Information");
    end;

    local procedure GetTotalVATAmountFromVATEntries(VATProdPostingGrp: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGrp);
        VATEntry.CalcSums(Amount);
        exit(VATEntry.Amount);
    end;

    local procedure SetupPurchaseJournalNoSeries(NewNoSeries: Code[20]) Result: Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePurchaseJournalBatch(GenJournalBatch);
        Result := GenJournalBatch."No. Series";
        GenJournalBatch.Validate("No. Series", NewNoSeries);
        GenJournalBatch.Modify();
    end;

    local procedure SetupUnrealizedVAT(var UnrealizedVATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.SetUnrealizedVAT(true);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVATPostingSetup(UnrealizedVATPostingSetup,
          VATBusinessPostingGroup.Code, UnrealizedVATPostingSetup."Unrealized VAT Type"::Percentage, false);
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        AddNoSeriesLine(NoSeries.Code, CalcDate('<-1Y-1D>', WorkDate()));
        AddNoSeriesLine(NoSeries.Code, CalcDate('<-1D>', WorkDate()));

        exit(NoSeries.Code);
    end;

    local procedure AddNoSeriesLine(NoSeriesCode: Code[20]; FromDate: Date)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeriesCode, 'T001', 'T999');
        NoSeriesLine.Validate("Starting Date", FromDate);
        NoSeriesLine.Modify();
    end;

    local procedure Create340DeclarationLine(var Rec340DeclarationLine: Record "340 Declaration Line"; DocumentType: Enum "Gen. Journal Document Type")
    var
        VATEntry: Record "VAT Entry";
        RecRef: RecordRef;
    begin
        VATEntry.Init();
        VATEntry."Document Type" := DocumentType;
        Rec340DeclarationLine.Init();
        RecRef.GetTable(Rec340DeclarationLine);
        Rec340DeclarationLine.Validate(Key, LibraryUtility.GetNewLineNo(RecRef, Rec340DeclarationLine.FieldNo(Key)));
        Rec340DeclarationLine."Document Type" := Format(VATEntry."Document Type");
        Rec340DeclarationLine."VAT Cash Regime" := true;
        Rec340DeclarationLine."VAT Amount" := LibraryRandom.RandInt(10);
        Rec340DeclarationLine."VAT Amount / EC Amount" := LibraryRandom.RandInt(10);
        Rec340DeclarationLine."Amount Including VAT / EC" := LibraryRandom.RandInt(10);
        Rec340DeclarationLine."VAT %" := LibraryRandom.RandInt(10);
        Rec340DeclarationLine.Base := LibraryRandom.RandInt(10);
        Rec340DeclarationLine."EC %" := LibraryRandom.RandInt(10);
        Rec340DeclarationLine."EC Amount" := LibraryRandom.RandInt(10);
        Rec340DeclarationLine.Insert();
    end;

    local procedure CreatePurchaseInvoiceWithTwoLines(var PurchaseHeader: Record "Purchase Header"; VATBusGrpCode: Code[20]; VATProdGrpCode: Code[20])
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        Index: Integer;
    begin
        CreateVendorWithCountryCodeAndVATBusPostingGroup(Vendor, VATBusGrpCode);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        for Index := 1 to 2 do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(
                PurchaseHeader."Gen. Bus. Posting Group", VATProdGrpCode), LibraryRandom.RandDecInRange(10, 20, 2));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure CreateAndPostPurchaseInvoice(VendorNo: Code[20]; PostingDate: Date) TotalAmount: Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, VendorNo, PostingDate);
        PurchaseHeader.CalcFields("Amount Including VAT");
        TotalAmount := PurchaseHeader."Amount Including VAT";
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseInvoiceNewVendor(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        CreatePurchLineWithUnitCost(
          PurchaseHeader,
          PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostPurchaseDocOnDate(DocType: Enum "Purchase Document Type"; VendorNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        CreatePurchLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(PurchaseHeader."Gen. Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"),
          1, LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithTwoLinesAndDims(var PurchaseHeader: Record "Purchase Header"; var TotalAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());

        ItemNo := LibraryInventory.CreateItemNo();
        TotalAmount := CreatePurchLineWithDim(PurchaseLine, PurchaseHeader, ItemNo);
        TotalAmount += CreatePurchLineWithDim(PurchaseLine, PurchaseHeader, ItemNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true)
    end;

    local procedure CreateAndPostPurchaseInvoiceWithTwoLinesAndDimsAndOperationCode(var PurchaseHeader: Record "Purchase Header"; var TotalAmount: Decimal; OperationCode: Code[1]): Code[35]
    var
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."Buy-from Vendor No.");
        PurchaseHeader.Modify(true);
        ItemNo := CreateItemWithOperationCode(PurchaseHeader."Gen. Bus. Posting Group", OperationCode);

        TotalAmount := CreatePurchLineWithDim(PurchaseLine, PurchaseHeader, ItemNo);
        TotalAmount += CreatePurchLineWithDim(PurchaseLine, PurchaseHeader, ItemNo);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        exit(PurchaseHeader."Vendor Invoice No.");
    end;

    local procedure CreateAndPostPurchaseJournal(VendorNo: Code[20]; PostingDate: Date): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        CreatePostGenJnlLine(GenJournalLine,
          GenJournalLine."Document Type"::Invoice, PostingDate, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Bal. Account Type"::Vendor, VendorNo,
          LibraryRandom.RandDecInDecimalRange(100, 1000, 2));
        exit(GenJournalLine.Amount);
    end;

    local procedure CreatePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal)
    begin
        CreateGenJnlLine(GenJournalLine, DocType, PostingDate, AccountType, AccountNo, BalAccountType, BalAccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostPaymentForInvoice(var GenJournalLine: Record "Gen. Journal Line"; PostedDocNo: Code[20])
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, '', 0);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Qty: Decimal; UnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Qty);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineWithUnitCost(PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchLine(PurchaseLine, PurchaseHeader, Type, No, Qty, UnitCost);
    end;

    local procedure CreateSalesLineWithUnitPrice(SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Qty);
        SalesLine.Validate("Unit Price", UnitCost);
        SalesLine.Modify(true);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        CreatePurchaseJournalBatch(GenJournalBatch);
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocType, AccountType, AccountNo, BalAccountType, BalAccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostApplyGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal; DocNo: Code[20])
    begin
        CreateGenJnlLine(GenJournalLine, DocType, PostingDate, AccountType, AccountNo, BalAccountType, BalAccountNo, Amount);
        GenJournalLine."Document No." := DocNo;
        GenJournalLine."Applies-to ID" := DocNo;
        GenJournalLine.Modify();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostApplyPurchasePayment(VendorNo: Code[20]; PostingDate: Date; InvoiceNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry1: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, VendorNo, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        LibraryERM.CreateGLAccount(GLAccount);

        CreatePostGenJnlLine(GenJournalLine,
          GenJournalLine."Document Type"::Payment, PostingDate, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Bal. Account Type"::Vendor, VendorNo,
          -LibraryRandom.RandDecInRange(1, VendorLedgerEntry1.Amount, 2));

        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, GenJournalLine.Amount);
        FindVendorLedgerEntry(VendorLedgerEntry1, VendorNo, VendorLedgerEntry1."Document Type"::Payment, GenJournalLine."Document No.");
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry1);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry);
    end;

    local procedure CreatePostApplyPurchasePaymentToMultyInv(VendorNo: Code[20]; PostingDate: Date; InvoiceNo1: Code[20]; InvoiceNo2: Code[20]; PaymentNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        PaymentAmount: Decimal;
    begin
        PaymentAmount := UpdateVendorLedgerEntryForApplication(VendorNo, InvoiceNo1, PaymentNo);
        PaymentAmount += UpdateVendorLedgerEntryForApplication(VendorNo, InvoiceNo2, PaymentNo);

        LibraryERM.CreateGLAccount(GLAccount);
        CreatePostApplyGenJnlLine(GenJournalLine,
          GenJournalLine."Document Type"::Payment, PostingDate, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Bal. Account Type"::Vendor, VendorNo, PaymentAmount, PaymentNo);
    end;

    local procedure CreatePostApplyPurchaseBill(VendorNo: Code[20]; DocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, VendorNo, VendorLedgerEntry."Document Type"::Bill, DocNo);
        VendorLedgerEntry.CalcFields(Amount);
        CreatePostBill(
          GenJournalLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", -VendorLedgerEntry.Amount, DocNo,
          VendorLedgerEntry."Bill No.");
    end;

    local procedure CreatePostApplySalesBill(CustomerNo: Code[20]; DocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Bill, DocNo);
        CustLedgerEntry.CalcFields(Amount);
        CreatePostBill(
          GenJournalLine."Account Type"::Customer, CustLedgerEntry."Customer No.", -CustLedgerEntry.Amount, DocNo,
          CustLedgerEntry."Bill No.");
    end;

    local procedure CreatePostBill(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; DocNo: Code[20]; BillNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGenJnlLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, WorkDate(),
          AccountType, AccountNo,
          GenJournalLine."Bal. Account Type", LibraryERM.CreateGLAccountNo(), Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Bill);
        GenJournalLine.Validate("Applies-to Doc. No.", DocNo);
        GenJournalLine.Validate("Applies-to Bill No.", BillNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPurchInvWithPmtMethodTwoLinesDiffDimAndVATProdPostingGroup(var TotalAmount: Decimal; VendorNo: Code[20]; PaymentMethodCode: Code[10]; VATProdPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethodCode);
        PurchaseHeader.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Modify(true);
        TotalAmount :=
          CreatePurchLineWithVATProdGroupAndDim(PurchaseHeader, Item."No.", VATProdPostingGroupCode);
        TotalAmount +=
          CreatePurchLineWithVATProdGroupAndDim(PurchaseHeader, Item."No.", VATProdPostingGroupCode);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostSalesInvWithPmtMethodTwoLinesDiffDimAndVATProdPostingGroup(var TotalAmount: Decimal; CustomerNo: Code[20]; PaymentMethodCode: Code[10]; VATProdPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Modify(true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        Item.Modify(true);
        TotalAmount :=
          CreateSalesLineWithVATProdGroupAndDim(SalesHeader, Item."No.", VATProdPostingGroupCode);
        TotalAmount +=
          CreateSalesLineWithVATProdGroupAndDim(SalesHeader, Item."No.", VATProdPostingGroupCode);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure UpdateVendorLedgerEntryForApplication(VendorNo: Code[20]; InvoiceNo: Code[20]; PaymentNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, VendorNo, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);

        VendorLedgerEntry."Applies-to ID" := PaymentNo;
        VendorLedgerEntry."Amount to Apply" := VendorLedgerEntry.Amount;
        VendorLedgerEntry.Modify();

        exit(VendorLedgerEntry.Amount);
    end;

    local procedure CreatePostApplySalesPayment(CustomerNo: Code[20]; PostingDate: Date; InvoiceNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry1: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Invoice, InvoiceNo);
        LibraryERM.CreateGLAccount(GLAccount);

        CreatePostGenJnlLine(GenJournalLine,
          GenJournalLine."Document Type"::Payment, PostingDate, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Bal. Account Type"::Customer, CustomerNo,
          LibraryRandom.RandDecInRange(1, -CustLedgerEntry1.Amount, 2));

        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, GenJournalLine.Amount);
        FindCustomerLedgerEntry(CustLedgerEntry1, CustomerNo, CustLedgerEntry1."Document Type"::Payment, GenJournalLine."Document No.");
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry1);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CreateAndPostSalesCreditMemoWithMultipleLine(): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(), WorkDate());  // WorkDate() - Posting Date.
        CreateSalesLine(SalesHeader, SalesLine);
        CreateSalesLine(SalesHeader, SalesLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; PostingDate: Date) Amount: Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, PostingDate);
        Amount := CreateSalesLine(SalesHeader, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocWithVATPostingSetup(DocType: Enum "Sales Document Type"; CustomerNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, DocType, CustomerNo, PostingDate);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount(SalesHeader."Gen. Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandIntInRange(3, 10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(50, 100));
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithVAT(CustomerNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount(SalesHeader."Gen. Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group"), 1);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithTwoLinesAndDims(var SalesHeader: Record "Sales Header"; var TotalAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());

        ItemNo := LibraryInventory.CreateItemNo();
        TotalAmount := CreateSalesLineWithDim(SalesLine, SalesHeader, ItemNo);
        TotalAmount += CreateSalesLineWithDim(SalesLine, SalesHeader, ItemNo);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateCountryWithVATRegNoFormat(VATRegNoHasCountryPrefix: Boolean): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("EU Country/Region Code", CopyStr(CountryRegion.Code, 1, 2)); // emulate EU country
        CountryRegion.Modify();

        CreateVATRegistrationNoFormat(CountryRegion, VATRegNoHasCountryPrefix);
        exit(CountryRegion.Code);
    end;

    local procedure CreateVendorWithCountryCodeAndVATBusPostingGroup(var Vendor: Record Vendor; VATBusPostGroupCode: Code[20])
    begin
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusPostGroupCode));
        Vendor.Validate("Country/Region Code", CreateCountryWithVATRegNoFormat(false));
        Vendor.Modify(true);
    end;

    local procedure CreateCustomerWithCountryCodeAndVATBusPostingGroup(var Customer: Record Customer; VATBusPostGroupCode: Code[20])
    begin
        Customer.Get(LibrarySales.CreateCustomerWithVATBusPostingGroup(VATBusPostGroupCode));
        Customer.Validate("Country/Region Code", CreateCountryWithVATRegNoFormat(false));
        Customer.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue value for handler - Make340DeclarationHandler.
        exit(Customer."No.");
    end;

    local procedure CreateForeignCustomerWithVATRegNo(CountryRegionCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        // make the unique name to simplify the search of file line
        Customer.Name := LibraryUtility.GenerateRandomCode(Customer.FieldNo(Name), DATABASE::Customer);
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer."VAT Registration No." :=
            PadStr(LibraryERM.GenerateVATRegistrationNo(CountryRegionCode), 17, '0');
        Customer.Modify(true);
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue value for handler - Make340DeclarationHandler.

        exit(Customer."No.");
    end;

    local procedure CreateForeignVendorWithVATRegNo(CountryRegionCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        // make the unique name to simplify the search of file line
        Vendor.Name := LibraryUtility.GenerateRandomCode(Vendor.FieldNo(Name), DATABASE::Customer);
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor."VAT Registration No." :=
            PadStr(LibraryERM.GenerateVATRegistrationNo(CountryRegionCode), 17, '0');
        Vendor.Modify(true);
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue value for handler - Make340DeclarationHandler.

        exit(Vendor."No.");
    end;

    local procedure CreatePurchLineWithDim(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]): Decimal
    begin
        CreatePurchLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Dimension Set ID", CreateDimSetID(PurchaseLine."Dimension Set ID"));
        PurchaseLine.Modify(true);
        exit(PurchaseLine.Amount);
    end;

    local procedure CreatePurchLineWithVATProdGroupAndDim(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; VATProdPostingGroupCode: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchLineWithDim(PurchaseLine, PurchaseHeader, ItemNo);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        PurchaseLine.Modify(true);
        exit(PurchaseLine.Amount);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"): Decimal
    var
        Item: Record Item;
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandIntInRange(3, 10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(50, 100));
        SalesLine.Modify(true);
        exit(SalesLine.Amount);
    end;

    local procedure CreateSalesLineWithDim(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header"; ItemNo: Code[20]): Decimal
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Dimension Set ID", CreateDimSetID(SalesLine."Dimension Set ID"));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(SalesLine.Amount);
    end;

    local procedure CreateSalesLineWithVATProdGroupAndDim(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; VATProdPostingGroupCode: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesLineWithDim(SalesLine, SalesHeader, ItemNo);
        SalesLine.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        SalesLine.Modify(true);
        exit(SalesLine.Amount);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SalesDocType: Enum "Sales Document Type"; CustomerNo: Code[20]; PostingDate: Date) Amount: Decimal
    begin
        CreateSalesHeader(SalesHeader, SalesDocType, CustomerNo, PostingDate);
        Amount := CreateSalesLine(SalesHeader, SalesLine);
    end;

    local procedure CreatePurchDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PurchDocType: Enum "Purchase Document Type"; VendorNo: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchDocType, VendorNo);
        SetPurchHeaderPostingDate(PurchaseHeader, PostingDate);
        CreatePurchLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandIntInRange(3, 10), LibraryRandom.RandIntInRange(50, 100));
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithBillToCarteraPaymentMethod(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryCarteraPayables.CreateBillToCarteraPaymentMethod(PaymentMethod);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        Vendor.Get(LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATBusinessPostingGroup.Code));
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
        CreateVATPostingSetup(VATPostingSetup,
          VATBusinessPostingGroup.Code, VATPostingSetup."Unrealized VAT Type"::Percentage, false);
        exit(Vendor."No.");
    end;

    local procedure CreateGLAccount(GenBusPostGr: Code[20]; VATProdPostGr: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GenPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GenPostingSetup);
        GenPostingSetup.SetRange("Gen. Bus. Posting Group", GenBusPostGr);
        GenPostingSetup.FindFirst();
        GLAccount.Validate("Gen. Bus. Posting Group", GenPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GenPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostGr);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure GenerateRandomCode(NumberOfDigit: Integer) ElectronicCode: Text[1024]
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfDigit do
            ElectronicCode := InsStr(ElectronicCode, Format(LibraryRandom.RandInt(9)), Counter);  // Random value of 1 digit required.
    end;

    local procedure CreatePurchaseJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        LibraryERM: Codeunit "Library - ERM";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Purchases);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateVATPostingSetupRevCharge(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATPostingSetup."Unrealized VAT Type"::Percentage, false);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusinessPostGrCode: Code[20]; UnrealizedType: Option; UseVATCashRegime: Boolean)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostGrCode, VATProductPostingGroup.Code);
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateRandomCode20(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDecInRange(10, 20, 2));
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedType);
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("VAT Cash Regime", UseVATCashRegime);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATRegistrationNoFormat(CountryRegion: Record "Country/Region"; VATRegNoHasCountryPrefix: Boolean)
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegNoFormat: Text[20];
    begin
        VATRegNoFormat := '###########';
        if VATRegNoHasCountryPrefix then
            VATRegNoFormat := CountryRegion."EU Country/Region Code" + VATRegNoFormat;

        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CountryRegion.Code);
        VATRegistrationNoFormat.Validate(Format, VATRegNoFormat);
        VATRegistrationNoFormat.Modify(true);
    end;

    local procedure CreateDimSetID(DimSetID: Integer): Integer
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        exit(LibraryDimension.CreateDimSet(DimSetID, DimensionValue."Dimension Code", DimensionValue.Code));
    end;

    local procedure CreateCarteraPaymentOrder(var PaymentOrder: Record "Payment Order")
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraPayables.CreateBankAccount(BankAccount, '');
        LibraryCarteraPayables.CreateCarteraPaymentOrder(BankAccount, PaymentOrder, '');
        PaymentOrder.Validate("Export Electronic Payment", false);
        PaymentOrder.Modify(false);
    end;

    local procedure CreateItemWithOperationCode(GenBusPostGroup: Code[20]; OperationCode: Code[1]): Code[20]
    var
        Item: Record Item;
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        OperationCodeRec: Record "Operation Code";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostGroup, GenProductPostingGroup.Code);
        GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
        LibraryMake340Declaration.CreateOperationCode(OperationCodeRec, OperationCode);
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
        GenProductPostingGroup.Validate("Operation Code", OperationCodeRec.Code);
        GenProductPostingGroup.Modify(true);
        Item.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; SourceNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", SourceNo);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure FindPostedCarteraDoc(var PostedCarteraDoc: Record "Posted Cartera Doc."; PaymentOrderNo: Code[20])
    begin
        PostedCarteraDoc.SetRange(Type, PostedCarteraDoc.Type::Payable);
        PostedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", PaymentOrderNo);
        PostedCarteraDoc.FindFirst();
    end;

    local procedure GetExpectedVATRegNoPart(VATRegNo: Text; CountryRegionCode: Code[10]; VATRegNoHasCountryPrefix: Boolean): Text
    var
        CountryRegion: Record "Country/Region";
    begin
        // VAT registration number part - country code prefix + digit part of VAT Reg. No.
        if VATRegNoHasCountryPrefix then
            exit(VATRegNo);

        CountryRegion.Get(CountryRegionCode);
        exit(CountryRegion."EU Country/Region Code" + VATRegNo);
    end;

    local procedure GetUnrealizedDeductibleAmount(SourceNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]): Decimal
    var
        VATEntry: Record "VAT Entry";
    begin
        FindVATEntry(VATEntry, SourceNo, DocumentType, DocumentNo);
        exit(VATEntry."Unrealized Amount");
    end;

    local procedure GetPostedPurchDocAmount(DocumentNo: Code[20]): Decimal
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        exit(PurchInvHeader."Amount Including VAT");
    end;

    local procedure RunMake340DeclarationReport(PostingDate: Date) ExportFileName: Text[1024]
    var
        Make340Declaration: Report "Make 340 Declaration";
    begin
        ExportFileName := TemporaryPath + 'ES340.txt';
        if Exists(ExportFileName) then
            Erase(ExportFileName);

        Clear(Make340Declaration);
        LibraryVariableStorage.Enqueue(Date2DMY(PostingDate, 2));
        Make340Declaration.InitializeRequest(
          Format(Date2DMY(PostingDate, 3)), Date2DMY(PostingDate, 2), GenerateRandomCode(LibraryRandom.RandInt(10)),
          GenerateRandomCode(9), GenerateRandomCode(4), GenerateRandomCode(16),
          0, false, '', ExportFileName, '', 0.0);
        Make340Declaration.UseRequestPage(true);
        Make340Declaration.RunModal();
    end;

    local procedure RunPartialSettlePayable(PaymentOrderNo: Code[20]; SettleAmount: Decimal)
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        PartialSettlPayable: Report "Partial Settl. - Payable";
    begin
        FindPostedCarteraDoc(PostedCarteraDoc, PaymentOrderNo);
        Clear(PartialSettlPayable);
        PartialSettlPayable.SetInitValue(SettleAmount, '', PostedCarteraDoc."Entry No.");
        PartialSettlPayable.SetTableView(PostedCarteraDoc);
        PartialSettlPayable.UseRequestPage(false);
        PartialSettlPayable.RunModal();
    end;

    local procedure RunTotalSettlePayable(PaymentOrderNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        SettleDocsInPostedPO: Report "Settle Docs. in Posted PO";
    begin
        FindPostedCarteraDoc(PostedCarteraDoc, PaymentOrderNo);
        Clear(SettleDocsInPostedPO);
        SettleDocsInPostedPO.SetTableView(PostedCarteraDoc);
        SettleDocsInPostedPO.UseRequestPage(false);
        SettleDocsInPostedPO.RunModal();
    end;

    local procedure SetSalesHeaderPostingDate(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure SetPurchHeaderPostingDate(var PurchHeader: Record "Purchase Header"; PostingDate: Date)
    begin
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Modify(true);
    end;

    local procedure UpdateCompanyInformationNameAndAddress(Name: Text[50]; Address: Text[50]; Address2: Text[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate(Name, Name);
        CompanyInformation.Validate(Address, Address);
        CompanyInformation.Validate("Address 2", Address2);
        CompanyInformation.Modify(true);
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    var
        Sign: Text[1];
    begin
        if Amount < 0 then
            Sign := 'N'
        else
            Sign := ' ';
        exit(Sign + ConvertStr(Format(Round(Amount * 100, 1), 13, '<Integer>'), ' ', '0'));
    end;

    local procedure InsertPayableDocsIntoPaymentOrder(VendorNo: Code[20]; PaymentOrderNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
        CarteraManagement: Codeunit CarteraManagement;
    begin
        CarteraDoc.SetRange(Type, CarteraDoc.Type::Payable);
        CarteraDoc.SetRange("Collection Agent", CarteraDoc."Collection Agent"::Bank);
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", PaymentOrderNo);
        LibraryVariableStorage.Enqueue(VendorNo);
        CarteraManagement.InsertPayableDocs(CarteraDoc);
    end;

    local procedure VerifyValuesOnGeneratedTextFile(ExportFileName: Text[1024]; StartingPosition: Integer; StartingPosition2: Integer; ExpectedValue: Text; ExpectedValue2: Text)
    begin
        VerifyValueOnGeneratedTextFile(ExportFileName, StartingPosition, ExpectedValue);
        VerifyValueOnGeneratedTextFile(ExportFileName, StartingPosition2, ExpectedValue2);
    end;

    local procedure VerifyValueOnGeneratedTextFile(ExportFileName: Text[1024]; StartingPosition: Integer; ExpectedValue: Text)
    var
        FieldValue: Text;
        Line: Text[1024];
    begin
        Line :=
          CopyStr(
            LibraryTextFileValidation.FindLineWithValue(ExportFileName, StartingPosition, StrLen(ExpectedValue), ExpectedValue),
            1, MaxStrLen(Line));
        FieldValue := LibraryTextFileValidation.ReadValue(Line, StartingPosition, StrLen(ExpectedValue));
        Assert.AreEqual(ExpectedValue, FieldValue, ValueNotFoundMsg);
    end;

    local procedure VerifyLineCountForUnrealizedPurchasePaymentValues(InvoiceNo: Code[20]; ExportFileName: Text[1024]; ExpectedInvoiceLineCount: Integer; ExpectedPaymentLineCount: Integer)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(InvoiceNo);
        Assert.AreEqual(
          ExpectedInvoiceLineCount,
          LibraryTextFileValidation.CountNoOfLinesWithValue(
            ExportFileName, PurchInvHeader."Vendor Invoice No.", 178, StrLen(PurchInvHeader."Vendor Invoice No.")),
          StrSubstNo(IncorrectLineCountErr, PurchInvHeader.FieldCaption("Vendor Invoice No.")));
        Assert.AreEqual(
          ExpectedPaymentLineCount,
          LibraryTextFileValidation.CountNoOfLinesWithValue(
            ExportFileName, FormatDate(PurchInvHeader."Posting Date") + '00000', 109, 13),
          StrSubstNo(IncorrectLineCountErr, PurchInvHeader.FieldCaption("Posting Date")));
    end;

    local procedure VerifyPaymentWithDeductibleAmount(VendorNo: Code[20]; InvoiceNo: Code[20]; ExportFileName: Text[1024])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DeductibleVATAmount: Decimal;
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, VendorNo, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 150, 100,
          DelChr(FormatAmount(-VendorLedgerEntry.Amount), '=', ',.'), 'Z' + FormatDate(VendorLedgerEntry."Posting Date"));

        DeductibleVATAmount := GetUnrealizedDeductibleAmount(VendorNo, VendorLedgerEntry."Document Type", InvoiceNo);
        VerifyValuesOnGeneratedTextFile(
          ExportFileName, 336, 100,
          DelChr(FormatAmount(DeductibleVATAmount), '=', ',.'), 'Z' + FormatDate(VendorLedgerEntry."Posting Date"));
    end;

    local procedure Verify340DeclarationEmptyAmounts(Rec340DeclarationLine: Record "340 Declaration Line")
    begin
        Assert.AreEqual(0, Rec340DeclarationLine."VAT Amount", Rec340DeclarationLine.FieldCaption("VAT Amount"));
        Assert.AreEqual(0, Rec340DeclarationLine."VAT Amount / EC Amount", Rec340DeclarationLine.FieldCaption("VAT Amount / EC Amount"));
        Assert.AreEqual(0, Rec340DeclarationLine."Amount Including VAT / EC", Rec340DeclarationLine.FieldCaption("Amount Including VAT / EC"));
        Assert.AreEqual(0, Rec340DeclarationLine."VAT %", Rec340DeclarationLine.FieldCaption("VAT %"));
        Assert.AreEqual(0, Rec340DeclarationLine.Base, Rec340DeclarationLine.FieldCaption(Base));
        Assert.AreEqual(0, Rec340DeclarationLine."EC %", Rec340DeclarationLine.FieldCaption("EC %"));
        Assert.AreEqual(0, Rec340DeclarationLine."EC Amount", Rec340DeclarationLine.FieldCaption("EC Amount"));
    end;

    local procedure VerifyCounterpartyLineVATRegNo(Name: Text; VATRegNo: Text; CountryRegionCode: Code[10]; VATRegNoHasCountryPrefix: Boolean; ExportFileName: Text[1024])
    var
        FileLine: Text;
        FieldValue: Text[1024];
    begin
        FileLine := LibraryTextFileValidation.FindLineContainingValue(ExportFileName, 1, 1024, Name);
        Assert.IsTrue(FileLine <> '', LineNotFoundErr);
        // take 20 symbols starting from 79 and remove trailing spaces
        FieldValue := DelChr(CopyStr(FileLine, 79, 20), '>', ' ');

        Assert.AreEqual(
          GetExpectedVATRegNoPart(
            VATRegNo,
            CountryRegionCode,
            VATRegNoHasCountryPrefix),
          FieldValue,
          IncorrectValueErr);
    end;

    local procedure VerifyEUCountryRegionCodeOnGeneratedTextFile(ExportFileName: Text[1024]; CountryCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryCode);
        VerifyValueOnGeneratedTextFile(ExportFileName, 76, CountryRegion."EU Country/Region Code");
    end;

    local procedure FormatDate(PostingDate: Date): Text[8]
    begin
        exit(Format(PostingDate, 8, '<Year4><Month,2><Day,2>'));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure Declaration340LinesPageHandler(var Declaration340Lines: TestPage "340 Declaration Lines")
    begin
        Declaration340Lines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure Declaration340LinesWithOperationCodePageHandler(var Declaration340Lines: TestPage "340 Declaration Lines")
    var
        Declaration340Line: Record "340 Declaration Line";
        OperationCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(OperationCode);
        Declaration340Lines."Operation Code".SetValue(OperationCode);
        Declaration340Lines."Property Location".SetValue(Declaration340Line."Property Location"::"Property in Spain");
        Declaration340Lines."Property Tax Account No.".SetValue(LibraryUtility.GenerateGUID());
        Declaration340Lines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure Declaration340LinesVerifyVATECAmountPctHandler(var Declaration340Lines: TestPage "340 Declaration Lines")
    begin
        Declaration340Lines."VAT %".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Declaration340Lines."VAT Amount".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Declaration340Lines."EC %".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Declaration340Lines."EC Amount".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Declaration340Lines.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyDeclaration340LinesMPH(var Declaration340Lines: TestPage "340 Declaration Lines")
    begin
        Declaration340Lines.First();
        Declaration340Lines.Base.AssertEquals(LibraryVariableStorageVerifyValues.DequeueDecimal());
        Assert.IsFalse(Declaration340Lines.Next(), Decl340LinesCountErr);
        Declaration340Lines.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyDeclaration340LinesOperationCodeMPH(var Declaration340Lines: TestPage "340 Declaration Lines")
    begin
        Declaration340Lines.FILTER.SetFilter("Document No.", LibraryVariableStorageVerifyValues.DequeueText());
        Declaration340Lines.First();
        Declaration340Lines.Base.AssertEquals(LibraryVariableStorageVerifyValues.DequeueDecimal());
        Declaration340Lines."Operation Code".AssertEquals(LibraryVariableStorageVerifyValues.DequeueText());
        Declaration340Lines.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyPartialSettlementDeclaration340LinesMPH(var Declaration340Lines: TestPage "340 Declaration Lines")
    begin
        Declaration340Lines.First();
        Declaration340Lines.Base.AssertEquals(LibraryVariableStorageVerifyValues.DequeueDecimal());
        Declaration340Lines."VAT Amount".AssertEquals(LibraryVariableStorageVerifyValues.DequeueDecimal());
        Declaration340Lines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make340DeclarationHandler(var Make340Declaration: TestRequestPage "Make 340 Declaration")
    var
        BilToPayToNo: Variant;
        Month: Variant;
    begin
        LibraryVariableStorage.Dequeue(BilToPayToNo);
        LibraryVariableStorage.Dequeue(Month);
        Make340Declaration.Month.SetValue(Format(DMY2Date(1, Month, 2000), 0, '<Month Text>'));
        Make340Declaration.VATEntry.SetFilter("Bill-to/Pay-to No.", BilToPayToNo);
        Make340Declaration.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExportedSuccessfullyMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CarteraDocumentsMPH(var CarteraDocuments: TestPage "Cartera Documents")
    begin
        CarteraDocuments.FILTER.SetFilter("Account No.", LibraryVariableStorage.DequeueText());
        CarteraDocuments.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

