codeunit 144118 "ERM Make 349 Declaration 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Make 349 Declaration]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryESLocalization: Codeunit "Library - ES Localization";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        IsInitialized: Boolean;
        CVWarning349Qst: Label 'One or more Credit Memos were found for the specified period. \You can select the ones that require a correction entry in current declaration and specify the correction amount for them. \Would you like to specify these corrections?';
        VATRegNoValidationQst: Label 'The VAT Registration number is not valid.\The length of the number exceeds the maximum limit of 9 characters.\\Do you still want to save it?';
        OnlyMarkedIncludedCorrectQst: Label 'Only corrections marked as "Include Correction", and with a valid Original Declaration FY and Original Declaration Period will be included in the file. \Are you sure you want to continue and generate the text file?.';
        UnxpectedRowCountErr: Label 'Unexpected row count for %1 = %2';
        CustomerTok: Label 'Customer';
        VendorTok: Label 'Vendor';

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,DummyMessageHandler,VerifyingComfirmHandler,CustomerVendorWarnings349ModalPageHandler')]
    [Scope('OnPrem')]
    procedure FullyAndPartiallyCorrectedInvoicesSales()
    var
        Customer: array[2] of Record Customer;
        PostingDate: Date;
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: array[2] of Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 268944] Report Make 349 Declaration doesn't include Customer entries when full correction was applied and EU Service is FALSE
        Initialize();

        // setup new year to avoid noise in "Customer / Vendor Warnings 349" page
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        // [GIVEN] Customers Customer[1] and Customer[2]
        // [GIVEN] Posted Invoice[1] for Customer[1] with two lines with EU Service is FALSE
        // [GIVEN] Posted Invoice[2] for Customer[2] with two lines with EU Service is FALSE
        // [GIVEN] Posted corrective Credit Memo for each Invoice. Each Credit Memo had two lines with same Amounts as corrected Invoice.
        PostTwoInvoicesAndTwoCreditMemosWithTwoLinesEachSales(Customer, PostingDate, PostedInvoiceNo, PostedCreditMemoNo, false);

        // [GIVEN] Ran "Make 349 Declaration"
        // [GIVEN] Aggreed to setup corrections per document lines
        // [GIVEN] Decided to include correction for first line of Credit Memo[1] and both lines of Credit Memo[2]
        // [GIVEN] Decided to export only marked "Included Correction" credit memo entries
        QueueMake349DeclarationConfirmationResponses(PostingDate, PostedCreditMemoNo);

        // [WHEN] Push "Process" on "Customer / Vendor Warnings 349" page
        RunMake349DeclarationReportWithCorrection(FileName);

        // [THEN] Entry for Customer[1] has been exported
        VerifyRowCountForCustomerInFile(FileName, 1, CustomerTok, Customer[1]."No.", 93);
        // [THEN] Entry for Customer[2] has not been exported
        VerifyRowCountForCustomerInFile(FileName, 0, VendorTok, Customer[2]."No.", 93);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,DummyMessageHandler,VerifyingComfirmHandler,CustomerVendorWarnings349ModalPageHandler')]
    [Scope('OnPrem')]
    procedure FullyAndPartiallyCorrectedInvoicesPurchase()
    var
        Vendor: array[2] of Record Vendor;
        PostingDate: Date;
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: array[2] of Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 268944] Report Make 349 Declaration doesn't include Vendor entries when full correction was applied and EU Service is FALSE
        Initialize();

        // setup new year to avoid noise in "Customer / Vendor Warnings 349" page
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        // [GIVEN] Vendors Vendor[1] and Vendor[2]
        // [GIVEN] Posted Invoice[1] for Vendor[1] with two lines with EU Service = FALSE
        // [GIVEN] Posted Invoice[2] for Vendor[2] with two lines with EU Service = FALSE
        // [GIVEN] Posted corrective Credit Memo for each Invoice. Each Credit Memo had two lines with same Amounts as corrected Invoice.
        PostTwoInvoicesAndTwoCreditMemosWithTwoLinesEachPurchase(Vendor, PostingDate, PostedInvoiceNo, PostedCreditMemoNo, false);

        // [GIVEN] Ran "Make 349 Declaration"
        // [GIVEN] Aggreed to setup corrections per document lines
        // [GIVEN] Decided to include correction for first line of Credit Memo[1] and both lines of Credit Memo[2]
        // [GIVEN] Decided to export only marked "Included Correction" credit memo entries
        QueueMake349DeclarationConfirmationResponses(PostingDate, PostedCreditMemoNo);

        // [WHEN] Push "Process" on "Customer / Vendor Warnings 349" page
        RunMake349DeclarationReportWithCorrection(FileName);

        // [THEN] Entry for Vendor[1] has been exported
        VerifyRowCountForCustomerInFile(FileName, 1, CustomerTok, Vendor[1]."No.", 93);
        // [THEN] Entry for Vendor[2] has not been exported
        VerifyRowCountForCustomerInFile(FileName, 0, VendorTok, Vendor[2]."No.", 93);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,DummyMessageHandler,VerifyingComfirmHandler,CustomerVendorWarnings349ModalPageHandler')]
    [Scope('OnPrem')]
    procedure FullyAndPartiallyCorrectedInvoicesSalesWhenEUService()
    var
        Customer: array[2] of Record Customer;
        PostingDate: Date;
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: array[2] of Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 273362] Report Make 349 Declaration doesn't include Customer entries when full correction was applied and EU Service is TRUE
        Initialize();

        // setup new year to avoid noise in "Customer / Vendor Warnings 349" page
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        // [GIVEN] Customers Customer[1] and Customer[2]
        // [GIVEN] Posted Invoice[1] for Customer[1] with two lines with EU Service = TRUE
        // [GIVEN] Posted Invoice[2] for Customer[2] with two lines with EU Service = TRUE
        // [GIVEN] Posted corrective Credit Memo for each Invoice. Each Credit Memo had two lines with same Amounts as corrected Invoice.
        PostTwoInvoicesAndTwoCreditMemosWithTwoLinesEachSales(Customer, PostingDate, PostedInvoiceNo, PostedCreditMemoNo, true);

        // [GIVEN] Ran "Make 349 Declaration"
        // [GIVEN] Aggreed to setup corrections per document lines
        // [GIVEN] Decided to include correction for first line of Credit Memo[1] and both lines of Credit Memo[2]
        // [GIVEN] Decided to export only marked "Included Correction" credit memo entries
        QueueMake349DeclarationConfirmationResponses(PostingDate, PostedCreditMemoNo);

        // [WHEN] Push "Process" on "Customer / Vendor Warnings 349" page
        RunMake349DeclarationReportWithCorrection(FileName);

        // [THEN] Entry for Customer[1] has been exported
        VerifyRowCountForCustomerInFile(FileName, 1, CustomerTok, Customer[1]."No.", 93);
        // [THEN] Entry for Customer[2] has not been exported
        VerifyRowCountForCustomerInFile(FileName, 0, VendorTok, Customer[2]."No.", 93);
    end;

    [Test]
    [HandlerFunctions('Make349DeclarationRequestPageHandler,DummyMessageHandler,VerifyingComfirmHandler,CustomerVendorWarnings349ModalPageHandler')]
    [Scope('OnPrem')]
    procedure FullyAndPartiallyCorrectedInvoicesPurchaseWhenEUService()
    var
        Vendor: array[2] of Record Vendor;
        PostingDate: Date;
        PostedInvoiceNo: array[2] of Code[20];
        PostedCreditMemoNo: array[2] of Code[20];
        FileName: Text;
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 273362] Report Make 349 Declaration doesn't include Vendor entries when full correction was applied and EU Service is TRUE
        Initialize();

        // setup new year to avoid noise in "Customer / Vendor Warnings 349" page
        PostingDate := LibraryFiscalYear.GetFirstPostingDate(false);

        // [GIVEN] Vendors Vendor[1] and Vendor[2]
        // [GIVEN] Posted Invoice[1] for Vendor[1] with two lines with EU Service = TRUE
        // [GIVEN] Posted Invoice[2] for Vendor[2] with two lines with EU Service = TRUE
        // [GIVEN] Posted corrective Credit Memo for each Invoice. Each Credit Memo had two lines with same Amounts as corrected Invoice.
        PostTwoInvoicesAndTwoCreditMemosWithTwoLinesEachPurchase(Vendor, PostingDate, PostedInvoiceNo, PostedCreditMemoNo, true);

        // [GIVEN] Ran "Make 349 Declaration"
        // [GIVEN] Aggreed to setup corrections per document lines
        // [GIVEN] Decided to include correction for first line of Credit Memo[1] and both lines of Credit Memo[2]
        // [GIVEN] Decided to export only marked "Included Correction" credit memo entries
        QueueMake349DeclarationConfirmationResponses(PostingDate, PostedCreditMemoNo);

        // [WHEN] Push "Process" on "Customer / Vendor Warnings 349" page
        RunMake349DeclarationReportWithCorrection(FileName);

        // [THEN] Entry for Vendor[1] has been exported
        VerifyRowCountForCustomerInFile(FileName, 1, CustomerTok, Vendor[1]."No.", 93);
        // [THEN] Entry for Vendor[2] has not been exported
        VerifyRowCountForCustomerInFile(FileName, 0, VendorTok, Vendor[2]."No.", 93);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Make 349 Declaration 2");

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Make 349 Declaration 2");

        LibraryFiscalYear.CloseFiscalYear();
        LibraryFiscalYear.CreateFiscalYear();

        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Make 349 Declaration 2");
    end;

    local procedure CreateInvoiceWithAmountSales(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LineAmount: array[2] of Decimal; PostingDate: Date; EUService: Boolean)
    begin
        CreateDocumentWithAmountSales(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, PostingDate, LineAmount, EUService);
    end;

    local procedure CreateInvoiceWithAmountPurchase(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; LineAmount: array[2] of Decimal; PostingDate: Date; EUService: Boolean)
    begin
        CreateDocumentWithAmountPurchase(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, PostingDate, LineAmount, EUService);
    end;

    local procedure CreateCorrectiveCreditMemoWithAmountSales(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; LineAmount: array[2] of Decimal; CorrectedInvoiceNo: Code[20]; PostingDate: Date; EUService: Boolean)
    begin
        CreateDocumentWithAmountSales(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo, PostingDate, LineAmount, EUService);
        SalesHeader.Validate("Corrected Invoice No.", CorrectedInvoiceNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreateCorrectiveCreditMemoWithAmountPurchase(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; LineAmount: array[2] of Decimal; CorrectedInvoiceNo: Code[20]; PostingDate: Date; EUService: Boolean)
    begin
        CreateDocumentWithAmountPurchase(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, PostingDate, LineAmount, EUService);
        PurchaseHeader.Validate("Corrected Invoice No.", CorrectedInvoiceNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateDocumentWithAmountSales(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PostingDate: Date; LineAmount: array[2] of Decimal; EUService: Boolean)
    var
        SalesLine: Record "Sales Line";
        Index: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        for Index := 1 to ArrayLen(LineAmount) do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
            SalesLine.Validate("Unit Price", LineAmount[Index]);
            SalesLine.Modify(true);
            ModifyVATPostingSetupEUService(SalesHeader."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", EUService);
        end;
    end;

    local procedure CreateDocumentWithAmountPurchase(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PostingDate: Date; LineAmount: array[2] of Decimal; EUService: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        Index: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        for Index := 1 to ArrayLen(LineAmount) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
            PurchaseLine.Validate("Direct Unit Cost", LineAmount[Index]);
            PurchaseLine.Modify(true);
            ModifyVATPostingSetupEUService(PurchaseHeader."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", EUService);
        end;
    end;

    local procedure CreateCustomerWithEUCountryRegionAndVATRegNo(var Customer: Record Customer)
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryESLocalization.CreateCountryRegionEUVATRegistrationNo(CountryRegion);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code));
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithEUCountryRegionAndVATRegNo(var Vendor: Record Vendor)
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryESLocalization.CreateCountryRegionEUVATRegistrationNo(CountryRegion);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code));
        Vendor.Modify(true);
    end;

    local procedure ModifyVATPostingSetupEUService(VATBusPostingGrp: Code[20]; VATProdPostingGrp: Code[20]; EUService: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGrp, VATProdPostingGrp);
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Modify(true);
    end;

    local procedure PostTwoInvoicesAndTwoCreditMemosWithTwoLinesEachSales(var Customer: array[2] of Record Customer; PostingDate: Date; var PostedInvoiceNo: array[2] of Code[20]; var PostedCreditMemoNo: array[2] of Code[20]; EUService: Boolean)
    var
        SalesHeader: Record "Sales Header";
        DocumentIndex: Integer;
        LineIndex: Integer;
        DocumentAmount: array[2, 2] of Decimal;
    begin
        for DocumentIndex := 1 to ArrayLen(DocumentAmount, 1) do begin
            for LineIndex := 1 to ArrayLen(DocumentAmount[DocumentIndex]) do
                DocumentAmount[DocumentIndex] [LineIndex] := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

            // Confirm to accept bad VAT Registration No.
            LibraryVariableStorage.Enqueue(VATRegNoValidationQst);
            LibraryVariableStorage.Enqueue(true);
            CreateCustomerWithEUCountryRegionAndVATRegNo(Customer[DocumentIndex]);

            CreateInvoiceWithAmountSales(SalesHeader, Customer[DocumentIndex]."No.", DocumentAmount[DocumentIndex], PostingDate, EUService);
            PostedInvoiceNo[DocumentIndex] := LibrarySales.PostSalesDocument(SalesHeader, true, true);

            CreateCorrectiveCreditMemoWithAmountSales(
              SalesHeader, Customer[DocumentIndex]."No.", DocumentAmount[DocumentIndex], PostedInvoiceNo[DocumentIndex], PostingDate,
              EUService);
            PostedCreditMemoNo[DocumentIndex] := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        end;
    end;

    local procedure PostTwoInvoicesAndTwoCreditMemosWithTwoLinesEachPurchase(var Vendor: array[2] of Record Vendor; PostingDate: Date; var PostedInvoiceNo: array[2] of Code[20]; var PostedCreditMemoNo: array[2] of Code[20]; EUService: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentIndex: Integer;
        LineIndex: Integer;
        DocumentAmount: array[2, 2] of Decimal;
    begin
        for DocumentIndex := 1 to ArrayLen(DocumentAmount, 1) do begin
            for LineIndex := 1 to ArrayLen(DocumentAmount[DocumentIndex]) do
                DocumentAmount[DocumentIndex] [LineIndex] := LibraryRandom.RandDecInDecimalRange(100, 200, 2);

            // Confirm to accept bad VAT Registration No.
            LibraryVariableStorage.Enqueue(VATRegNoValidationQst);
            LibraryVariableStorage.Enqueue(true);
            CreateVendorWithEUCountryRegionAndVATRegNo(Vendor[DocumentIndex]);

            CreateInvoiceWithAmountPurchase(
              PurchaseHeader, Vendor[DocumentIndex]."No.", DocumentAmount[DocumentIndex], PostingDate, EUService);
            PostedInvoiceNo[DocumentIndex] := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

            CreateCorrectiveCreditMemoWithAmountPurchase(
              PurchaseHeader, Vendor[DocumentIndex]."No.", DocumentAmount[DocumentIndex], PostedInvoiceNo[DocumentIndex], PostingDate,
              EUService);
            PostedCreditMemoNo[DocumentIndex] := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        end;
    end;

    local procedure GetPostingPeriodForMake349Declaration(PostingDate: Date; Delta: Integer) Period: Text[2]
    var
        PeriodNumber: Integer;
    begin
        PeriodNumber := Date2DMY(PostingDate, 2);
        PeriodNumber += Delta;
        if PeriodNumber > 12 then
            PeriodNumber := 12;
        Period := Format(PeriodNumber);
        if StrLen(Period) = 1 then
            Period := '0' + Period;
        exit(Period);
    end;

    local procedure QueueMake349DeclarationConfirmationResponses(PostingDate: Date; PostedCreditMemoNo: array[2] of Code[20])
    begin
        // setup vales in "Make 349 Declaration" request page
        QueueArgumensForMake349DeclarationReport(PostingDate);

        // agree to setup correction
        LibraryVariableStorage.Enqueue(CVWarning349Qst);
        LibraryVariableStorage.Enqueue(true);

        // "Include Correction" = TRUE for first line of Credit Memo[1] and both lines of Credit Memo[2]
        LibraryVariableStorage.Enqueue(ArrayLen(PostedCreditMemoNo));
        LibraryVariableStorage.Enqueue(PostedCreditMemoNo[1]);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(PostedCreditMemoNo[2]);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);

        // response yes
        LibraryVariableStorage.Enqueue(OnlyMarkedIncludedCorrectQst);
        LibraryVariableStorage.Enqueue(true);
    end;

    local procedure QueueArgumensForMake349DeclarationReport(PostingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(GetPostingPeriodForMake349Declaration(PostingDate, 0));
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryERM.CreateCountryRegionWithIntrastatCode());
    end;

    local procedure RunMake349DeclarationReportWithCorrection(var FileName: Text)
    var
        Make349Declaration: Report "Make 349 Declaration";
        FileManagement: Codeunit "File Management";
    begin
        FileName := FileManagement.ServerTempFileName('.txt');
        Commit();
        Make349Declaration.InitializeRequest(FileName);
        Make349Declaration.Run();
    end;

    local procedure AssignIncludeCorrectionToDocument(var CustomerVendorWarning349: Record "Customer/Vendor Warning 349"; IncludeCorrection: Boolean)
    begin
        CustomerVendorWarning349.Validate("Include Correction", IncludeCorrection);
        CustomerVendorWarning349.Modify(true);
    end;

    local procedure SetupQueuedIncludeCorrection()
    var
        CustomerVendorWarning349: Record "Customer/Vendor Warning 349";
        DocumentNo: Text;
        NoOfDocuments: Integer;
    begin
        NoOfDocuments := LibraryVariableStorage.DequeueInteger();

        while NoOfDocuments > 0 do begin
            DocumentNo := LibraryVariableStorage.DequeueText();
            CustomerVendorWarning349.SetRange("Document No.", DocumentNo);
            CustomerVendorWarning349.FindSet();
            AssignIncludeCorrectionToDocument(CustomerVendorWarning349, LibraryVariableStorage.DequeueBoolean());
            CustomerVendorWarning349.Next();
            AssignIncludeCorrectionToDocument(CustomerVendorWarning349, LibraryVariableStorage.DequeueBoolean());
            NoOfDocuments -= 1;
        end;
    end;

    local procedure VerifyRowCountForCustomerInFile(FileName: Text; ExpectedRowCount: Integer; AccountType: Text; CustomerNo: Code[20]; StartingPosition: Integer)
    begin
        Assert.AreEqual(
          ExpectedRowCount,
          LibraryTextFileValidation.CountNoOfLinesWithValue(
            FileName, PadStr(CustomerNo, MaxStrLen(CustomerNo)), StartingPosition, MaxStrLen(CustomerNo)),
          StrSubstNo(UnxpectedRowCountErr, AccountType, CustomerNo));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make349DeclarationRequestPageHandler(var Make349Declaration: TestRequestPage "Make 349 Declaration")
    begin
        Make349Declaration.FiscalYear.SetValue(Date2DMY(LibraryVariableStorage.DequeueDate(), 3));
        Make349Declaration.Period.SetValue(LibraryVariableStorage.DequeueInteger());
        Make349Declaration.ContactName.SetValue(LibraryVariableStorage.DequeueText());
        Make349Declaration.TelephoneNumber.SetValue(123456789);
        Make349Declaration.CompanyCountryRegion.SetValue(LibraryVariableStorage.DequeueText());
        Make349Declaration.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DummyMessageHandler(MessageText: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure VerifyingComfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();

        // it is headache to setup values through the page having growing number of documents per year
        if StrPos(Question, CVWarning349Qst) = 1 then
            SetupQueuedIncludeCorrection();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerVendorWarnings349ModalPageHandler(var CustomerVendorWarnings349: TestPage "Customer/Vendor Warnings 349")
    begin
        CustomerVendorWarnings349.Process.Invoke();
    end;
}

