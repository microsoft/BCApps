codeunit 144105 "ERM Miscellaneous Bugs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        StringTxt: Label 'A', Comment = 'Single character string is required for the field 770 Code which is of 1 character';
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataSet: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        AmountErr: Label '%1 must be %2.', Locked = true;
        AmountErrorMsg: Label '%1 must be %2 in %3 %4 %5.', Locked = true;
        LibraryRandom: Codeunit "Library - Random";
        CustomerNoTok: Label 'Customer__No__';
        CustLedgEntryAmountTok: Label 'CustLedgEntry1__Remaining_Amt___LCY__';
        CustLedgEntryNumberTok: Label 'CustLedgEntry1_Entry_No_';
        LessFilterTxt: Label '<%1';
        GreaterFilterTxt: Label '>%1';
        NonTaxAmountTok: Label 'NonTaxAmount';
        TotalAmountTok: Label 'TotalAmount';
        ValueMustNotSameMsg: Label 'Value must not same.';
        VATBookEntrySellToBuyFromNoTok: Label 'VAT_Book_Entry__Sell_to_Buy_from_No__';
        VATBookEntryDocumentNoTok: Label 'VAT_Book_Entry__Document_No__';
        VATBookEntryBaseTok: Label 'VAT_Book_Entry_Base';
        VATPageNoTok: Label 'VATRegisterLastPrintedPageNo';
        VATPageNo1Tok: Label 'VATRegisterLastPrintedPageNo1';
        FormatTxt: Label '########';
        VendLedgEntryAmountTok: Label 'VendLedgEntry1__Amount__LCY__';
        VendLedgEntryNumberTok: Label 'VendLedgEntry1_Entry_No_';
        VendorNoTok: Label 'Vendor__No__';
        VendorNumberTok: Label 'VendNo';
        WithholdTaxAmountTok: Label 'WithhTaxAmount';
        CustLedgEntryPaymentMethodTok: Label 'CustLedgEntry1__Payment_Method_';
        ExposureAmountTok: Label 'ExposureAmount';
        CustomerPaymentTermsCodeTok: Label 'Customer__Payment_Terms_Code_';
        RowNotFoundErr: Label '%1 row does not exit for %2.', Locked = true;
        PeriodErr: Label 'The Date does not exist. Identification fields and values: Period Type=''Month'',Period Start=''%1''', Locked = true;
        PreviousDatesErr: Label 'There are entries in the previous period that were not printed.';
        NameTok: Label 'Name';
        SuggestedLinesCountMismatchErr: Label 'The number of sugested lines did not match the expected';
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        IsInitialized: Boolean;
        ChangePmtToleranceQst: Label 'Do you want to change all open entries for every customer and vendor that are not blocked?';

    [Test]
    [Scope('OnPrem')]
    procedure FirstNameValueOnVendor()
    var
        Vendor: Record Vendor;
    begin
        // Verify Resident, Individual Person, Resident Address, Residence Post Code after updating First Name.
        // Setup.
        Initialize();

        // Exercise: Updated Resident, Individual Person to TRUE, Resident Address, Residence Post Code and First Name on the Vendor.
        CreateAndUpdateVendor(Vendor, false, '', '');  // Using FALSE for Include In VAT Transac. Rep. and Blank for Withhold Code and Payment Method Code.

        // Verify: Verify Resident, Individual Person, Resident Address, Residence Post Code after updating First Name.
        Vendor.TestField("First Name");
        Vendor.TestField(Resident, Vendor.Resident::Resident);
        Vendor.TestField("Individual Person", true);
        Vendor.TestField("Residence Address");
        Vendor.TestField("Residence Post Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithVATTransacRepOnVATPostingSetup()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Verify that Purchase Invoice must posted without error using Include in VAT Transac. Rep. TRUE on VAT Posting Setup.

        // Setup: Create VAT Transaction Report Amount, Vendor and create Purchase Invoice.
        Initialize();
        LibraryITLocalization.CreateVATTransactionReportAmount(VATTransactionReportAmount, WorkDate());
        VATTransactionReportAmount.Validate("Threshold Amount Excl. VAT", 0);
        VATTransactionReportAmount.Validate("Threshold Amount Incl. VAT", LibraryRandom.RandDec(10, 2));
        VATTransactionReportAmount.Modify(true);
        CreateAndUpdateVendor(Vendor, true, '', '');  // Using TRUE for Include In VAT Transac. Rep. and Blank for Withhold Code and Payment Method Code.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.", LibraryInventory.CreateItem(Item), PurchaseLine.Type::Item,
          LibraryRandom.RandInt(10));  // Random as Line Discount.

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // TRUE for Ship and Invoice.

        // Verify: Verify Posted Purch. Inv. Line Include in VAT Transac. Rep.
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("Include in VAT Transac. Rep.", true);
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler,ConfirmHandler,MessageHandler,ApplyVendorEntriesModalPageHandler,PostApplicationModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostApplicationWithVendorBillPayment()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        VendorNo: Code[20];
    begin
        // Verify Vendor Ledger Entry after Post Application from Apply Vendor Entries.

        // Setup: Create Vendor with Withhold Code, create Vendor Bill Header, Issue Bill and open Vendor Ledger Entries Page.
        Initialize();
        VendorNo := CreateVendorBillWithholdCodeSetup(VendorBillHeader);
        PostUsingVendorBillListSentCardPage(VendorBillHeader."No.");
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, CreateAndUpdateGLAccount(), PurchaseLine.Type::"G/L Account",
          LibraryRandom.RandInt(10));  // Random as Line Discount.
        OpenWithholdTaxesContributionCardUsingPurchInvoicePage(PurchaseHeader);
        OpenVendorLedgerEntriesPage(VendorLedgerEntries, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // TRUE for Ship and Invoice.
        LibraryVariableStorage.Enqueue(VendorNo);  // Enqueue value for ApplyVendorEntriesModalPageHandler.

        // Exercise.
        VendorLedgerEntries.ActionApplyEntries.Invoke();  // Opens ApplyVendorEntriesModalPageHandler.

        // Verify: Verify Vendor Ledger Entry after Post Application from Apply Vendor Entries.
        VerifyVendorLedgerEntry(VendorNo, 0, false);  // Using 0 for Amount to Pay, False for Open.
        VendorLedgerEntries.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtToleranceUsingGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify Customer Ledger Entry for Payment Tolerance after Post Application from Gen. Journal Line.

        // Setup: Update General Ledger Setup, create and post Sales Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        Amount := LibraryRandom.RandIntInRange(100, 999);
        CustomerNo := CreateSalesDocument(SalesHeader, Amount, SalesHeader."Document Type"::Invoice);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // TRUE for Ship and Invoice.

        // Exercise: Apply and Post General Journal Line.
        ApplyAndPostGeneralJournalLine(
          GenJournalLine."Account Type"::Customer, CustomerNo, DocumentNo, -Amount + LibraryRandom.RandInt(10));  // Taking lesser Amount than Sales Line.

        // Verify: Verify Customer Ledger Entry for Payment Tolerance after posting Sales Invoice.
        VerifyMaxPaymentToleranceInvoice(DocumentNo);

        // TearDown: Roll back General Ledger Setup.
        UpdatePmtToleranceGenLedgerSetup(GeneralLedgerSetup."Payment Tolerance %", GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnapplyPaymentAndReverseLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLBookEntry: Record "GL Book Entry";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify that a GL Book Entry must exist after reversal of Customer Ledger Entry.

        // Setup: Create and post Sales Invoice, create, apply and post Gen. Journal Line and Unapply Customer Ledger Entry.
        Initialize();
        Amount := LibraryRandom.RandIntInRange(100, 999);
        CustomerNo := CreateSalesDocument(SalesHeader, Amount, SalesHeader."Document Type"::Invoice);
        DocumentNo :=
          ApplyAndPostGeneralJournalLine(GenJournalLine."Account Type"::Customer, CustomerNo,
            LibrarySales.PostSalesDocument(SalesHeader, true, true), -Amount);  // TRUE for Ship and Invoice.
        UnapplyCustLedgerEntry(DocumentNo);

        // Exercise.
        ReverseCustLedgerEntries(DocumentNo, CustomerNo);

        // Verify: Verify that a GL Book Entry must exist after reversal of Customer Ledger Entry.
        GLBookEntry.SetRange("Document Type", GLBookEntry."Document Type"::Payment);
        GLBookEntry.SetRange("Document No.", DocumentNo);
        GLBookEntry.FindLast();  // Finding last entry of reversal.
        GLBookEntry.CalcFields(Amount);
        GLBookEntry.TestField(Positive, false);
        GLBookEntry.TestField(Amount, -Amount);
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostVendorBillIssueWithVendorBillPayment()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        VendorNo: Code[20];
    begin
        // Verify Remaining Amount on Vendor Ledger Entry after Post Vendor Bill Issued.

        // Setup: Create Vendor with Withhold Code, Vendor Bill Header, Issue Bill.
        Initialize();
        VendorNo := CreateVendorBillWithholdCodeSetup(VendorBillHeader);
        VendorBillLine.SetRange("Vendor No.", VendorNo);
        VendorBillLine.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorBillLine.FindFirst();

        // Exercise: Post Vendor Bill Issued.
        PostUsingVendorBillListSentCardPage(VendorBillHeader."No.");

        // Verify: Verify Remaining Amount on Vendor Ledger Entry.
        VerifyVendorLedgerEntry(VendorNo, VendorBillLine."Amount to Pay", true);  // TRUE for Open.
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler')]
    [Scope('OnPrem')]
    procedure CorrectEntriesOnVATRegisterPrint()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRegister: Record "VAT Register";
        LineAmount: Decimal;
        DocumentNo: Code[20];
        PrintingType: Option Test,Final,Reprint;
    begin
        // [FEATURE] [Report]
        // [SCENARIO] Run report "VAT Register - Print" with PrintingType "Test".

        // [GIVEN] VAT Register for Purchase with "Last Printing Date" > WORKDATE
        // [GIVEN] Create Purchase Order "PO" with "PO".Line Amount = 1000, "PO"."Buy-from Vendor No." = "V1"
        // [GIVEN] Post "PO", Posted Document NO. = "PI"
        LineAmount := CreatePurchaseOrderAndVATRegister(VATRegister, PurchaseHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run "VAT Register - Print" report with PrintingType = "Test"
        RunVATRegisterReport(CalcDate('<CM-1M+1D>', WorkDate()), VATRegister.Code, PrintingType::Test, true);

        // [THEN] Print Vendor "V1", Line Amount 1000 and Document No "PI"
        // [THEN] VATRegisterLastPrintedPageNo token in dataset should be 0
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(VATBookEntrySellToBuyFromNoTok, PurchaseHeader."Buy-from Vendor No.");
        LibraryReportDataSet.AssertElementWithValueExists(VATBookEntryBaseTok, LineAmount);
        LibraryReportDataSet.AssertElementWithValueExists(VATBookEntryDocumentNoTok, DocumentNo);
        LibraryReportDataSet.AssertElementWithValueExists(VATPageNoTok, 0);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PageNoOnVATRegisterPrint()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRegister: Record "VAT Register";
        PrintingType: Option Test,Final,Reprint;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382067] "VAT Register - Print" run with PrintingType "Final" and Company Information page

        // [GIVEN] VAT Register for Purchase with "Last Printing Date" > WORKDATE and "Last Printed VAT Register Page" = 100
        // [GIVEN] Posted Purchase Order with Posting Date = WORKDATE
        CreatePurchaseOrderAndVATRegister(VATRegister, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run "VAT Register - Print" report with PrintingType = "Final" and Company Information Data
        RunVATRegisterReport(CalcDate('<CM-1M+1D>', WorkDate()), VATRegister.Code, PrintingType::Final, true);

        // [THEN]  VATRegisterLastPrintedPageNo token in dataset should be equal "Last Printed VAT Register Page" - 1 = 99
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(VATPageNoTok, VATRegister."Last Printed VAT Register Page" - 1);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PageNoOnVATRegisterPrintWithoutCompInfo()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRegister: Record "VAT Register";
        PrintingType: Option Test,Final,Reprint;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382067] "VAT Register - Print" run with PrintingType "Final" and without Company Information page

        // [GIVEN] VAT Register for Purchase with "Last Printing Date" > WORKDATE and "Last Printed VAT Register Page" = 100
        // [GIVEN] Posted Purchase Order with Posting Date = WORKDATE
        CreatePurchaseOrderAndVATRegister(VATRegister, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run "VAT Register - Print" report with PrintingType = "Final" without Company Information Data
        RunVATRegisterReport(CalcDate('<CM-1M+1D>', WorkDate()), VATRegister.Code, PrintingType::Final, false);

        // [THEN] VATRegisterLastPrintedPageNo1 token in dataset should be 100
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(VATPageNo1Tok, VATRegister."Last Printed VAT Register Page");
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PageNoOnVATRegisterPrintWithoutBookEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRegister: Record "VAT Register";
        PrintingType: Option Test,Final,Reprint;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382067] "VAT Register - Print" run with PrintingType "Final" and Company Information page without any book entries

        // [GIVEN] VAT Register for Purchase with "Last Printing Date" > WORKDATE and "Last Printed VAT Register Page" = 100
        // [GIVEN] Purchase Order is not posted
        CreatePurchaseOrderAndVATRegister(VATRegister, PurchaseHeader);

        // [WHEN] Run "VAT Register - Print" report with PrintingType = "Final" and Company Information Data
        RunVATRegisterReport(CalcDate('<CM-1M+1D>', WorkDate()), VATRegister.Code, PrintingType::Final, true);

        // [THEN] VATRegisterLastPrintedPageNo token in dataset should be 99
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(VATPageNoTok, VATRegister."Last Printed VAT Register Page" - 1);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler')]
    [Scope('OnPrem')]
    procedure PageNoOnVATRegisterReprint()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRegister: Record "VAT Register";
        PrintingType: Option Test,Final,Reprint;
        PageNo: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382067] "VAT Register - Print" run with PrintingType "Reprint" and Company Information page

        // [GIVEN] VAT Register for Purchase with "Last Printing Date" > WORKDATE and "Last Printed VAT Register Page" = 100
        // [GIVEN] Posted Purchase Order with Posting Date = WORKDATE
        CreatePurchaseOrderAndVATRegister(VATRegister, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PageNo := CreateReprintInfo(VATRegister);

        // [WHEN] Run "VAT Register - Print" report with PrintingType = "Reprint" and Company Information Data
        RunVATRegisterReport(CalcDate('<CM-1M+1D>', WorkDate()), VATRegister.Code, PrintingType::Reprint, true);

        // [THEN] VATRegisterLastPrintedPageNo token in dataset should be 98
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(VATPageNoTok, PageNo - 2);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler')]
    [Scope('OnPrem')]
    procedure PageNoOnVATRegisterReprintWithoutCompInfo()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRegister: Record "VAT Register";
        PrintingType: Option Test,Final,Reprint;
        PageNo: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382067] "VAT Register - Print" run with PrintingType "Reprint" without Company Information page

        // [GIVEN] VAT Register for Purchase with "Last Printing Date" > WORKDATE and "Last Printed VAT Register Page" = 100
        // [GIVEN] Posted Purchase Order with Posting Date = WORKDATE
        CreatePurchaseOrderAndVATRegister(VATRegister, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PageNo := CreateReprintInfo(VATRegister);

        // [WHEN] Run "VAT Register - Print" report with PrintingType = "Reprint" without Company Information Data
        RunVATRegisterReport(CalcDate('<CM-1M+1D>', WorkDate()), VATRegister.Code, PrintingType::Reprint, false);

        // [THEN] VATRegisterLastPrintedPageNo1 token in dataset should be 99
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(VATPageNo1Tok, PageNo - 1);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler')]
    [Scope('OnPrem')]
    procedure PageNoOnVATRegisterReprintWithoutBookEntries()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRegister: Record "VAT Register";
        PrintingType: Option Test,Final,Reprint;
        PageNo: Integer;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382067] "VAT Register - Print" run with PrintingType "Reprint" and Company Information page without any book entries

        // [GIVEN] VAT Register for Purchase with "Last Printing Date" > WORKDATE and "Last Printed VAT Register Page" = 100
        // [GIVEN] Purchase Order is not posted
        CreatePurchaseOrderAndVATRegister(VATRegister, PurchaseHeader);
        PageNo := CreateReprintInfo(VATRegister);

        // [WHEN] Run "VAT Register - Print" report with PrintingType = "Reprint" and Company Information Data
        RunVATRegisterReport(CalcDate('<CM-1M+1D>', WorkDate()), VATRegister.Code, PrintingType::Reprint, true);

        // [THEN] VATRegisterLastPrintedPageNo token in dataset should be 98
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(VATPageNoTok, PageNo - 2);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterPrintPeriodError()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRegister: Record "VAT Register";
        BeginDate: Date;
        PrintingType: Option Test,Final,Reprint;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382067] "VAT Register - Print" with PrintingType = "Final" when BeginDate isn't begin of any month period.

        // [GIVEN] VAT Register for Purchase, Purchase Order is not posted
        CreatePurchaseOrderAndVATRegister(VATRegister, PurchaseHeader);
        BeginDate := CalcDate('<CM-1M+3D>', WorkDate());

        // [WHEN] Run "VAT Register - Print" report with PrintingType = "Final" and BeginDate is not begin of month
        asserterror RunVATRegisterReport(BeginDate, VATRegister.Code, PrintingType::Final, true);

        // [THEN] Error "The Date does not exist. Identification fields and values: Period Type='Month'" is thrown
        Assert.ExpectedError(StrSubstNo(PeriodErr, BeginDate));
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler')]
    [Scope('OnPrem')]
    procedure VATRegisterPrintEarlierEntriesError()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRegister: Record "VAT Register";
        PrintingType: Option Test,Final,Reprint;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382067] "VAT Register - Print" with PrintingType = "Final" when BeginDate greater then not printed VAT Book Entry.

        // [GIVEN] VAT Register for Purchase
        // [GIVEN] Posted Purchase Invoice wit Posting Date = WORKDATE
        CreatePurchaseOrderAndVATRegister(VATRegister, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run "VAT Register - Print" report with PrintingType = "Final" and BeginDate in next month after WORKDATE
        asserterror RunVATRegisterReport(CalcDate('<CM+1D>', WorkDate()), VATRegister.Code, PrintingType::Final, true);

        // [THEN] Error "There are entries in the previous period that were not printed" is thrown
        Assert.ExpectedError(PreviousDatesErr);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PageNoOnVATRegisterPrintDiffYears()
    var
        PurchaseHeader: Record "Purchase Header";
        VATRegister: Record "VAT Register";
        VATBookEntry: Record "VAT Book Entry";
        PrintingType: Option Test,Final,Reprint;
    begin
        // [FEATURE] [Report]
        // [SCENARIO 382067] "VAT Register - Print" run with PrintingType "Final" and BeginDate in next Year

        // [GIVEN] VAT Register for Purchase with "Last Printing Date" > WORKDATE and "Last Printed VAT Register Page" = 100
        // [GIVEN] Posted Purchase Order with Posting Date = WORKDATE
        CreatePurchaseOrderAndVATRegister(VATRegister, PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        VATBookEntry.ModifyAll("Printing Date", CalcDate('<CY>', WorkDate()));

        // [WHEN] Run "VAT Register - Print" report with PrintingType = "Final" and BeginDate in next year
        RunVATRegisterReport(CalcDate('<CY+1D>', WorkDate()), VATRegister.Code, PrintingType::Final, true);

        // [THEN] VATRegisterLastPrintedPageNo token in dataset should be -1
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(VATPageNoTok, -1);
    end;

    [Test]
    [HandlerFunctions('CommentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentTypeOnPurchCommentLineForPurchInvoice()
    var
        Item: Record Item;
        PurchCommentLine: Record "Purch. Comment Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PostedPurchaseInvoices: TestPage "Posted Purchase Invoices";
        DocumentNo: Code[20];
    begin
        // Verify correct value updated on field Document Type in Purchase Comment Line after adding comments on Posted Purchase Invoice.

        // Setup: Create and Post Purchase Order and opened Posted Purchase Invoices page.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.", LibraryInventory.CreateItem(Item), PurchaseLine.Type::Item,
          LibraryRandom.RandInt(10));  // Random as Line Discount.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PostedPurchaseInvoices.OpenEdit();
        PostedPurchaseInvoices.FILTER.SetFilter("No.", DocumentNo);

        // Exercise: Add Comments on Posted Invoice.
        PostedPurchaseInvoices."Co&mments".Invoke();  // Opens CommentRequestPageHandler.

        // Verify: Verify correct value updated on field Document Type on Purchase Comment Line after adding comments on Posted Purchase Invoice.
        VerifyPurchCommentLine(DocumentNo, PurchCommentLine."Document Type"::"Posted Invoice");
        PostedPurchaseInvoices.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('CommentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentTypeOnPurchCommentLineForPurchCreditMemo()
    var
        Item: Record Item;
        PurchCommentLine: Record "Purch. Comment Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        DocumentNo: Code[20];
    begin
        // Verify correct value updated on field Document Type in Purchase Comment Line after adding comments on Posted Purchase Credit Memo.

        // Setup: Create and Post Purchase Order.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.",
          LibraryInventory.CreateItem(Item), PurchaseLine.Type::Item, LibraryRandom.RandInt(10));  // Random as Line Discount.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Add Comments on Posted Credit Memo.
        PostedPurchaseCreditMemo.OpenEdit();
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", DocumentNo);
        PostedPurchaseCreditMemo."Co&mments".Invoke();  // Opens CommentRequestPageHandler.

        // Verify: Verify correct value updated on field Documents Type on Purchase Comment Line after adding comments on Posted Purchase Credit Memo.
        VerifyPurchCommentLine(DocumentNo, PurchCommentLine."Document Type"::"Posted Credit Memo");
        PostedPurchaseCreditMemo.OK().Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationOccurredDateOnServiceInvoice()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify Program updates the Operation Occurred Date as Posting date on Service Header with Document Type Invoice.
        OperationOccurredDateOnServiceDocument(ServiceHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationOccurredDateOnServiceCreditMemo()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify Program updates the Operation Occurred Date as Posting date on Service Header with Document Type Credit Memo.
        OperationOccurredDateOnServiceDocument(ServiceHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationOccurredDateOnServiceOrder()
    var
        ServiceHeader: Record "Service Header";
    begin
        // Verify Program updates the Operation Occurred Date as Posting date on Service Header with Document Type Order.
        OperationOccurredDateOnServiceDocument(ServiceHeader."Document Type"::Order);
    end;

    local procedure OperationOccurredDateOnServiceDocument(DocumentType: Enum "Service Document Type")
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
    begin
        // Setup: Create Service Header.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");

        // Exercise: Update Posting Date.
        UpdateServiceHeaderPostingDate(ServiceHeader);

        // Verify: Verify Operation Occurred Date as Posting Date.
        ServiceHeader.Get(ServiceHeader."Document Type", ServiceHeader."No.");
        ServiceHeader.TestField("Operation Occurred Date", ServiceHeader."Posting Date");
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillListPageHandler')]
    [Scope('OnPrem')]
    procedure OnlyOpenedEntriesFalseOnVendorAccountBillList()
    begin
        // Verify program populates correct entries on Report "Vendor Account Bill List" with Only Opened Entries as False.
        OnlyOpenedEntriesOnVendorAccountBillList(false);  // Only Opened Entries as False.
    end;

    [Test]
    [HandlerFunctions('VendorAccountBillListPageHandler')]
    [Scope('OnPrem')]
    procedure OnlyOpenedEntriesTrueOnVendorAccountBillList()
    begin
        // Verify program populates correct entries on Report "Vendor Account Bill List" with Only Opened Entries as True.
        OnlyOpenedEntriesOnVendorAccountBillList(true);  // Only Opened Entries as True.
    end;

    local procedure OnlyOpenedEntriesOnVendorAccountBillList(OnlyOpenedEntries: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // Setup: Create and Post Purchase Invoice.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreateAndPostPurchaseDocument(PurchaseHeader, Vendor."No.", PurchaseHeader."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(OnlyOpenedEntries);  // Enqueue values for VendorAccountBillListPageHandler.

        // Exercise: Run Report Vendor Account Bills List.
        RunVendorAccountBillsListReport(Vendor."No.");

        // Verify: Verify Vendor Number, Vendor Ledger Entry - Entry Number and Amount on Report - Vendor Account Bills List.
        VerifyEntryNoAndAmountOnVendorAccountBillsList(Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('CustomerBilListPageHandler')]
    [Scope('OnPrem')]
    procedure OnlyOpenedEntriesFalseOnCustomerBillList()
    begin
        // Verify program populates correct entries on Report "Customer Bills List" with Only Opened Entries as False.
        OnlyOpenedEntriesOnCustomerBillList(false);  // Only Opened Entries as False.
    end;

    [Test]
    [HandlerFunctions('CustomerBilListPageHandler')]
    [Scope('OnPrem')]
    procedure OnlyOpenedEntriesTrueOnCustomerBillList()
    begin
        // Verify program populates correct entries on Report "Customer Bills List" with Only Opened Entries as True.
        OnlyOpenedEntriesOnCustomerBillList(true);  // Only Opened Entries as True.
    end;

    local procedure OnlyOpenedEntriesOnCustomerBillList(OnlyOpenedEntries: Boolean)
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // Setup: Create and Post Sales Invoice.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateAndPostSalesDocumentWithServiceTariffNumber(Customer."No.", SalesHeader."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(OnlyOpenedEntries);  // Enqueue value for CustomerBilListPageHandler.

        // Exercise: Run Report Customer Bills List.
        RunCustomerBillsListReport(Customer."No.");

        // Verify: Verify Customer Number, Customer Ledger Entry - Entry Number and Amount on Report - Customer Bills List.
        VerifyEntryNoAndAmountOnCustomerBillsList(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContributionModalPageHandler,WithholdingTaxesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentJournalWithholdTaxesSocSecurityOnWithholdingTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxAmount: Decimal;
        TaxableBase: Decimal;
        NonTaxableAmount: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Verify program populates correct entries on Report -  Withholding Taxes after Calculating Withholding Taxes Soc. Security on Payment Journal and apply Posted Purchase Invoice.

        // Setup: Post Purchase Invoice, Calculating Withholding Taxes Soc. Security on Payment Journal and apply Posted Purchase Invoice.
        Initialize();
        WithholdingTax.DeleteAll();
        CreatePurchaseDocumentWithholdTaxesContribution(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateAndPostGeneralJnlLineWithComputedWithhold(PostedDocumentNo);
        WithholdingTaxAmount := CalculateWithholdTaxes(TaxableBase, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount");
        NonTaxableAmount := PurchaseLine."Line Amount" - TaxableBase;

        // Exercise: Run Report - Withholding Taxes.
        RunWithholdingTaxesReport(PurchaseLine."Buy-from Vendor No.");  // Open Handler - WithholdingTaxesRequestPageHandler.

        // Verify: Verify Withholding Taxes - Vendor Number, Total Amount, Non Tax Amount and Withholding Tax Amount on XML of Report - Withholding Taxes.
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(VendorNumberTok, PurchaseLine."Buy-from Vendor No.");
        LibraryReportDataSet.AssertElementWithValueExists(TotalAmountTok, PurchaseLine."Line Amount");
        LibraryReportDataSet.AssertElementWithValueExists(NonTaxAmountTok, NonTaxableAmount);
        LibraryReportDataSet.AssertElementWithValueExists(WithholdTaxAmountTok, WithholdingTaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoThresholdAmountOnVatReport()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Verify Program Populates only Posted Purchase Credit Memos which one is greater than the Threshold Amount.

        // Setup: Create VAT Transaction Report Amount, Vendor and Post Purchase Credit Memo.
        Initialize();
        CreateVATTransactionReportAmount();
        CreateAndUpdateVendor(Vendor, true, '', '');  // Using TRUE for Include In VAT Transac. Rep. and Blank for Withhold Code and Payment Method Code.
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.",
          LibraryInventory.CreateItem(Item), PurchaseLine.Type::Item, LibraryRandom.RandInt(10));  // Random as Line Discount.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // TRUE for Ship and Invoice.

        // Exercise: Invoke Action - Suggest lines on Page - Vat Report.
        SuggestAndVerifyVATReportLineCount(DocumentNo, 1);

        // Verify: Verify Amount Including VAT and Base Amount on Page - VAT Report Sub form.
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst();

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoThresholdAmountOnVatReport()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Program Populates only Posted Sales Credit memos which one is greater than the Threshold Amount.

        // Setup: Create VAT Transaction Report Amount And Sales Credit Memo.
        Initialize();
        CreateVATTransactionReportAmount();
        CreateSalesDocument(SalesHeader, LibraryRandom.RandInt(10), SalesHeader."Document Type"::"Credit Memo");  // Quantity as Random.
        UpdateIndividualPersonFiscalCodeResidentOnCustomer(SalesHeader."Sell-to Customer No.");
        UpdateVATRegistrationNoOnSalesHeader(SalesHeader);
        UpdateIncludeInVATTransacRepOnSalsesLine(SalesLine, SalesHeader);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // TRUE for Ship and Invoice.

        // Exercise: Invoke Action - Suggest lines on Page - Vat Report.
        SuggestLinesOnVATReport();

        // Verify: Verify Amount Including VAT and Base Amount on Page - VAT Report Sub form.
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.FindFirst();
        VerifyAmountInclVATAndBaseAmountOnVATReportSubformPage(DocumentNo, SalesCrMemoLine.Amount, SalesCrMemoLine."Amount Including VAT");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentOnVendorLedgerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        Amount: Decimal;
        UnrealizedVAT: Boolean;
        DocumentNo: Code[20];
        PostedDocumentNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // Verify Program Populates Correct Entries after Unapply Payment On Vendor Ledger Entries.

        // Setup: Create And Post Purchase Invoice,Payment Journal.
        Initialize();
        UnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);  // TRUE as General Ledger Setup -  Unrealized VAT.
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.",
          CreateAndUpdateGLAccount(), PurchaseLine.Type::"G/L Account", 0);  // Line Discount percentage - 0.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseLine.Type::"G/L Account", PurchaseHeader."No.");
        Amount := PurchaseLine."VAT %" * PurchaseLine."Line Amount" / 100;
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // TRUE for Ship and Invoice.
        PaymentAmount := LibraryRandom.RandDec(10, 2);
        DocumentNo :=
          ApplyAndPostGeneralJournalLine(GenJournalLine."Account Type"::Vendor, Vendor."No.",
            PostedDocumentNo, PaymentAmount);

        // Exercise: Unapply Vendor Ledger Entry.
        UnapplyVendorLedgerEntry(DocumentNo);

        // Verify: Verify VAT Entry - Base, Amount and Detailed Vendor Ledger Entries.
        VerifyVATEntryBaseAndAmount(PostedDocumentNo, PurchaseLine."Line Amount", Amount);
        VerifyDetailedVendorLedgerEntry(DocumentNo, PurchaseLine."Buy-from Vendor No.", GreaterFilterTxt, PaymentAmount);
        VerifyDetailedVendorLedgerEntry(DocumentNo, PurchaseLine."Buy-from Vendor No.", LessFilterTxt, -PaymentAmount);

        // TearDown.
        UpdateUnrealizedVATOnGeneralLedgerSetup(UnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnapplyPaymentOnCustomerLedgerEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Amount: Decimal;
        UnrealizedVAT: Boolean;
        PostedDocumentNo: Code[20];
        CustomerNo: Code[20];
        DocumentNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // Verify Program Populates Correct Entries after Unapply Payment On Customer Ledger Entries.

        // Setup: Create And Post Sales Invoice,Payment Journal.
        Initialize();
        UnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);  // TRUE as General Ledger Setup -  Unrealized VAT.
        CustomerNo := CreateSalesDocument(SalesHeader, LibraryRandom.RandInt(100), SalesHeader."Document Type"::Invoice);
        UpdateVATRegistrationNoOnSalesHeader(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesLine.Type::Item, SalesHeader."No.");
        Amount := SalesLine."VAT %" * SalesLine.Amount / 100;
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // TRUE for Ship and Invoice.
        PaymentAmount := LibraryRandom.RandDec(10, 2);
        DocumentNo :=
          ApplyAndPostGeneralJournalLine(GenJournalLine."Account Type"::Customer, CustomerNo,
            PostedDocumentNo, -PaymentAmount);

        // Exercise: Unapply Customer Ledger Entry.
        UnapplyCustLedgerEntry(DocumentNo);

        // Verify: Verify VAT Entry - Base, Amount and Detailed Customer Ledger Entries.
        VerifyVATEntryBaseAndAmount(PostedDocumentNo, -SalesLine.Amount, -Amount);
        VerifyDetailedCustomerLedgerEntry(DocumentNo, SalesLine."Sell-to Customer No.", GreaterFilterTxt, PaymentAmount);
        VerifyDetailedCustomerLedgerEntry(DocumentNo, SalesLine."Sell-to Customer No.", LessFilterTxt, -PaymentAmount);

        // TearDown.
        UpdateUnrealizedVATOnGeneralLedgerSetup(UnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithMorePaymentNos()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        PaymentLines: Record "Payment Lines";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify G/L Entry and Customer Ledger Entry after Posting Sales Invoice with more than one Payment Number.

        // Setup: Create Customer With Payment Method.
        Initialize();
        CreateCustomerWithPaymentMethod(Customer);

        // Exercise: Create and Post Sales Invoice With Payment Method - more than one Payment Number.
        PostedDocumentNo := CreateAndPostSalesInvoiceWithPaymentMethod(SalesLine, Customer."No.");

        // Verify: Verify G/L Entry - Amount and Due Date and Customer Ledger Entry - Payment Method, Amount And Due Date.
        FindPaymentLines(PaymentLines, PaymentLines.Type::"Payment Terms", Customer."Payment Terms Code");
        Amount := SalesLine."Amount Including VAT" * PaymentLines."Payment %" / 100;
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntryAmount(
          GLEntry."Document Type"::Invoice, PostedDocumentNo, GeneralPostingSetup."Sales Account", SalesLine.Amount, 0, WorkDate());  // Credit Amount - 0.
        VerifyGLEntryAmount(
          GLEntry."Document Type"::Invoice, PostedDocumentNo, CustomerPostingGroup."Receivables Account", 0, Amount, WorkDate());  // Debit Amount - 0.
        VerifyCustLedgerEntryPaymentMethodAmountAndDueDate(
          CustLedgerEntry."Document Type"::Invoice, PostedDocumentNo, Customer."No.", Customer."Payment Method Code", Amount,
          CalcDate(PaymentLines."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('IssuingCustomerBillRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceIssuingCustomerBillWithMorePaymentNos()
    var
        Bill: Record Bill;
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        PaymentLines: Record "Payment Lines";
        SalesLine: Record "Sales Line";
        PostingDate: Variant;
        Amount: Decimal;
    begin
        // Verify G/L Entry and Customer Ledger Entry after running Report - Issuing Customer Bill with more than one Payment Number.

        // Setup: Create Customer With Payment Method, Create and Post Sales Invoice.
        Initialize();
        CreateCustomerWithPaymentMethod(Customer);
        CreateAndPostSalesInvoiceWithPaymentMethod(SalesLine, Customer."No.");
        FindPaymentLines(PaymentLines, PaymentLines.Type::"Payment Terms", Customer."Payment Terms Code");
        Amount := SalesLine."Amount Including VAT" * PaymentLines."Payment %" / 100;

        // Exercise.
        RunIssuingCustomerBillReport(Customer."No.");  // Opens handler - IssuingCustomerBillRequestPageHandler.

        // Verify: Verify G/L Entry - Amount and Due Date and Customer Ledger Entry - Payment Method, Amount And Due Date.
        LibraryVariableStorage.Dequeue(PostingDate);
        FindCustLedgerEntryWithDocumentType(CustLedgerEntry, Customer."No.", CustLedgerEntry."Document Type"::Payment);
        Bill.Get(FindBill(true, true));  // Bank Receipt, Allow Issue - TRUE.
        VerifyGLEntryAmount(
          GLEntry."Document Type"::Payment, CustLedgerEntry."Document No.", Bill."Bills for Coll. Temp. Acc. No.", 0, Amount, PostingDate);  // Debit Amount - 0.
        VerifyCustLedgerEntryPaymentMethodAmountAndDueDate(
          CustLedgerEntry."Document Type"::Payment, CustLedgerEntry."Document No.", Customer."No.", Customer."Payment Method Code", -Amount,
          CalcDate(PaymentLines."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('IssuingCustomerBillRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceSuggestCustomerBillsWithMorePaymentNos()
    var
        Customer: Record Customer;
        CustomerBillHeader: Record "Customer Bill Header";
        SalesLine: Record "Sales Line";
        PaymentLines: Record "Payment Lines";
        PostingDateVar: Variant;
        Amount: Decimal;
        PostedDocumentNo: Code[20];
        PostingDate: Date;
    begin
        // Verify Subform Customer Bill Line after running Report - Suggest Customer Bills with more than one Payment Number.

        // Setup: Create Customer With Payment Method, Create and Post Sales Invoice. Create Customer Bill Header.
        Initialize();
        CreateCustomerWithPaymentMethod(Customer);
        PostedDocumentNo := CreateAndPostSalesInvoiceWithPaymentMethod(SalesLine, Customer."No.");
        FindPaymentLines(PaymentLines, PaymentLines.Type::"Payment Terms", Customer."Payment Terms Code");
        Amount := SalesLine."Amount Including VAT" * PaymentLines."Payment %" / 100;
        RunIssuingCustomerBillReport(Customer."No.");  // Opens handler - IssuingCustomerBillRequestPageHandler.
        LibraryVariableStorage.Dequeue(PostingDateVar);
        PostingDate := PostingDateVar;
        CreateCustomerBillHeader(CustomerBillHeader, Customer."Payment Method Code", PostingDate);

        // Exercise.
        RunSuggestCustomerBillsReport(CustomerBillHeader, Customer."No.");

        // Verify: Verify Customer No,Document Type,Document No,Amount and Due Date on Subform Customer Bill Line.
        VerifySubformCustomerBillLineValues(
          Customer."No.", PostedDocumentNo, Amount, CalcDate(PaymentLines."Due Date Calculation", WorkDate()));
    end;

    [Test]
    [HandlerFunctions('IssuingCustomerBillRequestPageHandler,MessageHandler,CustomerBillsListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCustomerBillsListWithMorePaymentNos()
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        PaymentLines: Record "Payment Lines";
        Amount: Decimal;
    begin
        // Verify Posted Sales Invoice after running Report - Customer Bills List with more than one Payment Number.

        // Setup: Create Customer With Payment Method, Create and Post Sales Invoice,run Report - Issuing Customer Bill.
        Initialize();
        CreateCustomerWithPaymentMethod(Customer);
        CreateAndPostSalesInvoiceWithPaymentMethod(SalesLine, Customer."No.");
        FindPaymentLines(PaymentLines, PaymentLines.Type::"Payment Terms", Customer."Payment Terms Code");
        LibraryVariableStorage.Enqueue(CalcDate(PaymentLines."Due Date Calculation", WorkDate()));  // Enqueue value for handler - CustomerBillsListRequestPageHandler.
        Amount := SalesLine."Amount Including VAT" * PaymentLines."Payment %" / 100;
        RunIssuingCustomerBillReport(Customer."No.");  // Opens handler - IssuingCustomerBillRequestPageHandler.

        // Exercise.
        RunCustomerBillsListReport(Customer."No.");  // Opens handler - CustomerBillsListRequestPageHandler.

        // Verify: Verify Payment Terms Code, Payment Method Code and Amount on generated XML of Report - Customer Bills List.
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(CustomerPaymentTermsCodeTok, Customer."Payment Terms Code");
        LibraryReportDataSet.AssertElementWithValueExists(CustLedgEntryPaymentMethodTok, Customer."Payment Method Code");
        LibraryReportDataSet.AssertElementWithValueExists(ExposureAmountTok, Round(Amount, LibraryERM.GetAmountRoundingPrecision()));
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler')]
    [Scope('OnPrem')]
    procedure VendorNameOnVATRegisterPrintForPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Vendor Name after posting Purchase Invoice on the VAT Register - Print Report.
        VendorNameOnVATRegisterPrint(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintPageHandler')]
    [Scope('OnPrem')]
    procedure VendorNameOnVATRegisterPrintForCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Vendor Name after posting Purchase Credit Memo on the VAT Register - Print Report.
        VendorNameOnVATRegisterPrint(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceForeignIndividualVendorOnVatReport()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Post Purchase Invoice for Individual vendor with
        Initialize();
        CreateVATTransactionReportAmount();
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateIndividualVendor(),
          LibraryInventory.CreateItem(Item), PurchaseLine.Type::Item, LibraryRandom.RandInt(10));  // Random as Line Discount.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        SuggestAndVerifyVATReportLineCount(DocumentNo, 1);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullVATSalesInvoiceOnVatReport()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Checks suggestion posted Full VAT entries for Sales Invoice
        FullVATSalesDocumentOnVatReport(SalesHeader."Document Type"::Invoice);

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FullVATSalesCreditMemoOnVatReport()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Checks suggestion posted Full VAT entries for Sales Credit Memo
        FullVATSalesDocumentOnVatReport(SalesHeader."Document Type"::"Credit Memo");

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OfficialDateGLBookEntryAfterPost()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldWorkDate: Date;
    begin
        // [FEATURE] [Post] [GL Book Entry] [VAT Book Entry]
        // [SCENARIO 202125] "Official Date" of "GL Book Entry" and "VAT Book Entry" have to contain normal date after posting when WORKDATE is closing date
        Initialize();

        // [GIVEN] Set WORKDATE is 1 day before Open Accounting Period
        OldWorkDate := WorkDate();
        WorkDate := NormalDate(LibraryFiscalYear.IdentifyOpenAccountingPeriod() - 1);

        // [GIVEN] Gen. Journal Line
        UpdateVATPostingSetupIncludeInVATTransacRep(VATPostingSetup, false);
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), -LibraryRandom.RandIntInRange(10, 100));

        // [GIVEN] WORKDATE is closing date
        WorkDate := ClosingDate(WorkDate());

        // [WHEN] Post the line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] "Official Date" of "GL Book Entry" is normal date
        // [THEN] "Official Date" of "VAT Book Entry" is normal date
        VerifyOfficialDateGLVATBookEntries(GenJournalLine."Account No.");

        WorkDate := OldWorkDate; // Return WORKDATE to normal
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingReverseChargeVATLineWithBatchPostingNoSeriesOfSpecialCode()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DummyGLEntry: Record "G/L Entry";
        DocNo: Code[20];
        PostingDocNo: Code[20];
    begin
        // [FEATURE] [Post] [Reverse Charge VAT]
        // [SCENARIO 205519] Post Gen. Journal Batch with Reverse Charge VAT line where Posting No. Series comes later in sorting than Document No.
        Initialize();

        // [GIVEN] Gen. Journal Batch where "Posting No. Series" is numbered from '19-00001'
        // [GIVEN] Gen. Journal Line for simple G/L Account
        // [GIVEN] Balance Gen. Journal Line for G/L Account with Reverse Charge VAT
        // [GIVEN] Document No. = '1' for both lines (special sorting order)
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -LibraryRandom.RandDec(100, 2));

        PostingDocNo :=
          LibraryUtility.GetNextNoFromNoSeries(
            UpdateNoSeriesOnGenJnlBatch(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name"), WorkDate());
        DocNo := CopyStr('0' + PostingDocNo, 1, MaxStrLen(DocNo));
        UpdateGenJnlLine(GenJournalLine, DocNo);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account", CreateGLAccountWithReverseChargeVAT(),
          -GenJournalLine.Amount);
        UpdateGenJnlLine(GenJournalLine, DocNo);

        // [WHEN] Post Gen. Journal lines
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] G/L Entries created with "Document No." = '19-00001'
        DummyGLEntry.SetRange("Document No.", PostingDocNo);
        Assert.RecordIsNotEmpty(DummyGLEntry);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification,PmtToleranceWarningZeroBalanceModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesPmtToleranceToDocWithSameOccurence()
    var
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocNo: Code[20];
        "Part": array[3] of Decimal;
        MaxPmtTolerance: Decimal;
        AmtWithTolerance: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 338278] Payment Tolerance applies to correct sales document with the same occurence

        Initialize();

        // [GIVEN] Payment Discount Tolerance Warning enabled, "Max Payment Tolerance is 0.1"
        MaxPmtTolerance := 0.1;
        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        LibraryVariableStorage.Enqueue(ChangePmtToleranceQst);
        UpdatePmtTolerance(MaxPmtTolerance);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText(
          StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(3, 10)));

        // [GIVEN] Customer with Payment Terms with three Payment Lines: "Payment %" = 10%, 60%, 30%
        Part[1] := 0.1;
        Part[2] := 0.6;
        Part[3] := 0.3;

        // [GIVEN] Three posted sales invoices with same "Document No." = "X" and amount equals 100, 600 and 300 accordingly
        DocNo :=
          CreateAndPostSalesInvoiceWithPaymentMethod(SalesLine, CreateCustomerWithPaymentTerms(CreatePaymentTermsWithThreeLines(Part)));

        // [GIVEN] Create payment line applies to the third invoice with amount 300
        CustLedgerEntry.SetRange("Document Occurrence", ArrayLen(Part));
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocNo);
        CustLedgerEntry.CalcFields(Amount);

        CreateGenJnlLineWithAppliesToOccurence(
          GenJournalLine, GenJournalLine."Account Type"::Customer,
          SalesLine."Bill-to Customer No.", DocNo, ArrayLen(Part), -CustLedgerEntry.Amount);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry.Amount);
        AmtWithTolerance := GenJournalLine.Amount + MaxPmtTolerance;

        // [WHEN] Change amount to 299,9
        GenJournalLine.Validate(Amount, AmtWithTolerance);

        // [THEN] Applying amount is 299,99, applied amount is -299,99, balance is 0.1
        // Values takes from PmtToleranceWarningZeroBalanceModalPageHandler
        Assert.AreEqual(AmtWithTolerance, LibraryVariableStorage.DequeueDecimal(), 'Applying amount is not correct');
        Assert.AreEqual(-AmtWithTolerance, LibraryVariableStorage.DequeueDecimal(), 'Applied amount is not correct');
        Assert.AreEqual(MaxPmtTolerance, LibraryVariableStorage.DequeueDecimal(), 'Balance is not correct');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerWithVerification,PmtToleranceWarningZeroBalanceModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchPmtToleranceToDocWithSameOccurence()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocNo: Code[20];
        "Part": array[3] of Decimal;
        MaxPmtTolerance: Decimal;
        AmtWithTolerance: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 338278] Payment Tolerance applies to correct purchase document with the same occurence

        Initialize();

        // [GIVEN] Payment Discount Tolerance Warning enabled, "Max Payment Tolerance is 0.1"
        MaxPmtTolerance := 0.1;
        LibraryPmtDiscSetup.SetPmtToleranceWarning(true);
        LibraryVariableStorage.Enqueue(ChangePmtToleranceQst);
        UpdatePmtTolerance(MaxPmtTolerance);
        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText(
          StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(3, 10)));

        // [GIVEN] Vendor with Payment Terms with three Payment Lines: "Payment %" = 10%, 60%, 30%
        Part[1] := 0.1;
        Part[2] := 0.6;
        Part[3] := 0.3;

        // [GIVEN] Three posted purchase invoices with same "Document No." = "X" and amount equals 100, 600 and 300 accordingly
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(
          PurchaseHeader, CreateVendorWithPaymentTerms(CreatePaymentTermsWithThreeLines(Part)));
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create payment line applies to the third invoice with amount 300
        VendorLedgerEntry.SetRange("Document Occurrence", ArrayLen(Part));
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocNo);
        VendorLedgerEntry.CalcFields(Amount);

        CreateGenJnlLineWithAppliesToOccurence(
          GenJournalLine, GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Pay-to Vendor No.", DocNo, ArrayLen(Part), -VendorLedgerEntry.Amount);
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry.Amount);
        AmtWithTolerance := GenJournalLine.Amount - MaxPmtTolerance;

        // [WHEN] Change amount to 299,9
        GenJournalLine.Validate(Amount, AmtWithTolerance);

        // [THEN] Applying amount is 299,99, applied amount is -299,99, balance is 0.1
        // Values takes from PmtToleranceWarningZeroBalanceModalPageHandler
        Assert.AreEqual(AmtWithTolerance, LibraryVariableStorage.DequeueDecimal(), 'Applying amount is not correct');
        Assert.AreEqual(-AmtWithTolerance, LibraryVariableStorage.DequeueDecimal(), 'Applied amount is not correct');
        Assert.AreEqual(MaxPmtTolerance, -LibraryVariableStorage.DequeueDecimal(), 'Balance is not correct');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VendorAgingMatrixModalPageHandler')]
    [Scope('OnPrem')]
    procedure VendorAgingMatrixPeriodBalance()
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorAging: TestPage "Vendor Aging";
        AmountType: Option "Period Balance","Balance at Date";
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 389493] "Vendor Aging Matrix" shows sum of ledger entries for a period when "Amount Type" is set to "Period Balance".
        Initialize();

        // [GIVEN] Vendor with 2 detailed ledger entries with "Initial Due Date" = "15.01.21"/"17.01.21", "Amount" = "10"/"15".
        LibraryPurchase.CreateVendor(Vendor);
        MockVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", WorkDate(), WorkDate());
        Amount[1] := VendorLedgerEntry.Amount;
        MockDtldVendorLedgerEntry(VendorLedgerEntry."Entry No.", Amount[1]);
        Amount[2] := 0;
        MockVendorLedgerEntry(VendorLedgerEntry, Vendor."No.", WorkDate(), WorkDate() + 2);
        Amount[3] := VendorLedgerEntry.Amount;
        MockDtldVendorLedgerEntry(VendorLedgerEntry."Entry No.", Amount[3]);

        // [GIVEN] "Vendor Aging" page is opened with "Date Filter" starting on "15.01.21", "Amount Type" set to "Period Balance".
        Vendor.SetRange("Date Filter", WorkDate(), WorkDate() + 30);
        Vendor.CalcFields("Balance (LCY)");
        Vendor.TestField("Balance (LCY)", -(Amount[1] + Amount[2] + Amount[3]));

        VendorAging.Trap();
        PAGE.Run(PAGE::"Vendor Aging", Vendor);
        VendorAging.AmountType.SetValue(AmountType::"Period Balance");

        // [WHEN] "Show matrix" action on page "Vendor Aging" is used.
        LibraryVariableStorage.Enqueue(Vendor."No.");
        VendorAging."&Show Matrix".Invoke();

        // [THEN] In opened matrix page:
        // [THEN] Field1 Caption = "15.01.21", Value = "10";
        // [THEN] Field2 Caption = "16.01.21", Value = "0";
        // [THEN] Field3 Caption = "17.01.21", Value = "15".
        for i := 1 to 3 do begin
            Assert.AreEqual(Format(WorkDate() + i - 1), LibraryVariableStorage.DequeueText(), '');
            Assert.AreEqual(Amount[i], -LibraryVariableStorage.DequeueDecimal(), '');
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerAgingMatrixModalPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerAgingMatrixPeriodBalance()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerAging: TestPage "Customer Aging";
        AmountType: Option "Period Balance","Balance at Date";
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 389493] "Customer Aging Matrix" shows sum of ledger entries for a period when "Amount Type" is set to "Period Balance".
        Initialize();

        // [GIVEN] Customer with 2 detailed ledger entries with "Initial Due Date" = "15.01.21"/"17.01.21", "Amount" = "10"/"15".
        LibrarySales.CreateCustomer(Customer);
        MockCustomerLedgerEntry(CustLedgerEntry, Customer."No.", WorkDate(), WorkDate());
        Amount[1] := CustLedgerEntry.Amount;
        MockDtldCustLedgerEntry(CustLedgerEntry."Entry No.", Amount[1]);
        Amount[2] := 0;
        MockCustomerLedgerEntry(CustLedgerEntry, Customer."No.", WorkDate(), WorkDate() + 2);
        Amount[3] := CustLedgerEntry.Amount;
        MockDtldCustLedgerEntry(CustLedgerEntry."Entry No.", Amount[3]);

        // [GIVEN] "Customer Aging" page is opened with "Date Filter" starting on "15.01.21", "Amount Type" set to "Period Balance".
        Customer.SetRange("Date Filter", WorkDate(), WorkDate() + 30);
        Customer.CalcFields("Balance (LCY)");
        Customer.TestField("Balance (LCY)", Amount[1] + Amount[2] + Amount[3]);

        CustomerAging.Trap();
        PAGE.Run(PAGE::"Customer Aging", Customer);
        CustomerAging.AmountType.SetValue(AmountType::"Period Balance");

        // [WHEN] "Show matrix" action on page "Customer Aging" is used.
        LibraryVariableStorage.Enqueue(Customer."No.");
        CustomerAging."&Show Matrix".Invoke();

        // [THEN] In opened matrix page:
        // [THEN] Field1 Caption = "15.01.21", Value = "10";
        // [THEN] Field2 Caption = "16.01.21", Value = "0";
        // [THEN] Field3 Caption = "17.01.21", Value = "15".
        for i := 1 to 3 do begin
            Assert.AreEqual(Format(WorkDate() + i - 1), LibraryVariableStorage.DequeueText(), '');
            Assert.AreEqual(Amount[i], LibraryVariableStorage.DequeueDecimal(), '');
        end;

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler,ConfirmHandler,MessageHandler,ApplyVendorEntriesModalPageHandler,PostApplicationModalPageHandler')]
    [Scope('OnPrem')]
    procedure VendorBillIsCorrectAfterApplyingPmtToInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        VendorNo: Code[20];
    begin
        // [SCENARIO 395832] The information in the vendor bill is correct after applying invoice to payment

        Initialize();
        // [GIVEN] Create Vendor with Withhold Code
        // [GIVEN] Vendor Bill document
        VendorNo := CreateVendorBillWithholdCodeSetup(VendorBillHeader);
        PostUsingVendorBillListSentCardPage(VendorBillHeader."No.");

        // [GIVEN] Posted invoice
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, CreateAndUpdateGLAccount(), PurchaseLine.Type::"G/L Account",
          LibraryRandom.RandInt(10));  // Random as Line Discount.

        // [GIVEN] Withholding tax amount is "X" in the "Withholding Taxes Contribution" card
        OpenWithholdTaxesContributionCardUsingPurchInvoicePage(PurchaseHeader);
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // [GIVEN] Payment applied to invoice
        OpenVendorLedgerEntriesPage(VendorLedgerEntries, LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
        LibraryVariableStorage.Enqueue(VendorNo);  // Enqueue value for ApplyVendorEntriesModalPageHandler.
        VendorLedgerEntries.ActionApplyEntries.Invoke();  // Opens ApplyVendorEntriesModalPageHandler.
        VendorLedgerEntries.OK().Invoke();

        // [WHEN] Run report "Suggest Vendor Bills"
        RunSuggestVendorBillsForVendorNo(VendorBillHeader, PurchaseHeader."Buy-from Vendor No.");

        // [THEN] Withholding tax amount is "X" in Vendor Bill Line
        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.FindFirst();
        VendorBillLine.TestField("Withholding Tax Amount", PurchWithhContribution."Withholding Tax Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBillIsCorrectAfterApplyingPartialPmtToInvoice()
    var
        BankAccount: Record "Bank Account";
        BillPostingGroup: Record "Bill Posting Group";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillLine: Record "Vendor Bill Line";
        PurchWithhContribution: Record "Purch. Withh. Contribution";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorBillWithholdingTax: Record "Vendor Bill Withholding Tax";
        VendorNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 427450] "Total Amount" does not included remaining amount of partial payment when payment's amount is greater than withholding tax amount.

        Initialize();

        VendorNo := CreateVendorWithhold();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, BankAccount."No.", FindPaymentMethod());
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BankAccount."No.");
        VendorBillHeader.Validate("Payment Method Code", BillPostingGroup."Payment Method");
        VendorBillHeader.Modify(true);

        UpdateTaxPerscentsOnVendorWitholdingTax(VendorNo, 20, 100);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Payment Method Code", 'BANKTRANSF');
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateAndUpdateGLAccount(), 1);
        PurchaseLine.Validate("Direct Unit Cost", 1000);
        PurchaseLine.Modify(true);

        UpdateCheckTotalOnPuchaseDocument(PurchaseHeader, PurchaseLine."Amount Including VAT");

        OpenWithholdTaxesContributionCardUsingPurchInvoicePage(PurchaseHeader);
        PurchWithhContribution.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");

        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor, VendorNo, 200);
        GenJournalLine.Validate("Payment Method Code", '');
        GenJournalLine.Modify(true);
        GenJournalLine.TestField("Debit Amount", 200);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        LibraryERM.ApplyVendorLedgerEntries(
          VendorLedgerEntry."Document Type"::Invoice, VendorLedgerEntry."Document Type"::" ",
          InvoiceNo, GenJournalLine."Document No.");

        RunSuggestVendorBillsForVendorNo(VendorBillHeader, VendorNo);

        Commit();

        VendorBillLine.SetRange("Vendor Bill List No.", VendorBillHeader."No.");
        VendorBillLine.SetRange("Document Type", VendorBillLine."Document Type"::Invoice);
        VendorBillLine.SetRange("Document No.", InvoiceNo);
        VendorBillLine.FindFirst();
        VendorBillLine.TestField("Withholding Tax Amount", PurchWithhContribution."Withholding Tax Amount");

        VendorBillWithholdingTax.Get(VendorBillHeader."No.", VendorBillLine."Line No.");
        VendorBillWithholdingTax.TestField("Total Amount", 1000);
        VendorBillWithholdingTax.TestField("Withholding Tax Amount", 200);
        VendorBillWithholdingTax.TestField("Non Taxable Amount", 0);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    procedure GLEntryDimensionsWhenTwoDifferentVendorsMultipleBillMovements()
    var
        BillPostingGroup: Record "Bill Posting Group";
        BankAccount: Record "Bank Account";
        Vendor: array[2] of Record Vendor;
        VendorBillHeader: Record "Vendor Bill Header";
        VendorNoFilter: Code[50];
    begin
        // [SCENARIO 568576] Check the GL entry dimensions when two different vendors have multiple bill movements.
        Initialize();

        // [GIVEN] Crete Bank Account.
        LibraryERM.CreateBankAccount(BankAccount);

        // [GIVEN] Create two different vendors with default dimensions.
        CreateVendorWithDimension(Vendor[1]);
        CreateVendorWithDimension(Vendor[2]);

        // [GIVEN] Create the full bill posting group setup
        CreateBillPostingGroupWithFullSetup(
            BillPostingGroup, Vendor[1]."Payment Method Code", BankAccount."No.");

        // [GIVEN] Create and post purchase invoices for two different vendors.
        CreatePurchaseInvoiceAndPost(Vendor[1]."No.");
        CreatePurchaseInvoiceAndPost(Vendor[2]."No.");

        // [GIVEN] Create Vendor Bill Header.
        CretaeVendorBillHeader(VendorBillHeader, BankAccount."No.");
        VendorNoFilter := Vendor[1]."No." + '|' + Vendor[2]."No.";

        // [GIVEN] Insert multiple vendor bill lines from the 'Suggest Vendor Bills' action.
        SuggestMultipleVendorsBills(VendorBillHeader, VendorNoFilter);
        Commit();

        // [GIVEN] Issue vendor bills.
        IssueVendorBill(VendorBillHeader."No.");

        // [WHEN] Post the vendor bill from the Vendor Bill List Issued page.
        PostUsingVendorBillListSentCardPage(VendorBillHeader."No.");

        // [THEN] Verify that the GL entry does not contain any dimensions.
        VerifyGlEntryDimensions(BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('ShowComputedWithholdContributionMultipleCloseHandler')]
    [Scope('OnPrem')]
    procedure WithholdingTaxPageCanBeClosedMultipleTimes()
    var
        WithholdingTax: Record "Withholding Tax";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO 610443] Show Computed Withh. Contrib. page can be opened and closed multiple times without concurrency error
        Initialize();

        // [GIVEN] A payment journal line with vendor that has withholding tax code configured
        WithholdingTax.DeleteAll();
        FindGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor, CreateVendorWithholdCode(), 150);
        GenJournalLine.Modify(true);

        // [GIVEN] Payment Journal page is opened and navigated to the journal batch
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalLine."Journal Batch Name");

        // [WHEN] Show Computed Withh. Contrib. page is opened and closed twice consecutively
        PaymentJournal.WithhTaxSocSec.Invoke();
        PaymentJournal.WithhTaxSocSec.Invoke();

        PaymentJournal.Close();

        // [THEN] Both open/close cycles complete successfully without concurrency error
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        Commit();
        IsInitialized := true;
    end;

    local procedure TearDown()
    begin
        asserterror Error('');
    end;

    local procedure ApplyAndPostGeneralJournalLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccountNo, AppliesToDocNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure VendorNameOnVATRegisterPrint(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PrintingType: Option Test,Final,Reprint;
    begin
        // Verify Vendor Name after posting Purchase Document on the VAT Register - Print Report.

        // Setup: Create and Post Purchase Document and enqueue values.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseHeader, CreateEUVendor(), DocumentType);

        RunVATRegisterReport(
          CalcDate('<CM-1M+1D>', WorkDate()), FindVATRegister(PurchaseHeader."Operation Type"), PrintingType::Test, true);

        // Verify: Program populates correct entries on Report - VAT Register - Print.
        VerifyVendorNameExistOnVATRegister(PurchaseHeader."Buy-from Vendor No.");
    end;

    local procedure CreateAndPostGeneralJnlLineWithComputedWithhold(AppliesToDocNo: Code[20]): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Applies-to Doc. Type"::Invoice, AppliesToDocNo);
        VendorLedgerEntry.CalcFields(Amount);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorLedgerEntry."Vendor No.", AppliesToDocNo, -VendorLedgerEntry.Amount);
        ShowComputedWithholdContributionOnPayment(GenJournalLine."Journal Batch Name");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VenderNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        CreatePurchaseDocumentWithServiceTariffNumber(PurchaseHeader, VenderNo, DocumentType);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesInvoiceWithPaymentMethod(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, CreateItem());
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesLine.Type::Item, SalesHeader."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocumentWithServiceTariffNumber(CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"): Code[10]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocumentWithServiceTariffNumber(SalesHeader, CustomerNo, DocumentType);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesHeader."Service Tariff No.");
    end;

    local procedure CreateAndUpdateVendor(var Vendor: Record Vendor; IncludeInVATTransacRep: Boolean; WithholdingTaxCode: Code[20]; PaymentMethodCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        UpdateVATPostingSetupIncludeInVATTransacRep(VATPostingSetup, IncludeInVATTransacRep);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Validate(Resident, Vendor.Resident::Resident);
        Vendor.Validate("Individual Person", true);
        Vendor.Validate("Residence Address", Vendor."No.");
        Vendor.Validate("Residence Post Code", CreatePostCode());
        Vendor.Validate("First Name", Vendor."No.");
        Vendor.Validate("Fiscal Code", LibraryITLocalization.GetFiscalCode());
        Vendor.Validate("Withholding Tax Code", WithholdingTaxCode);
        Vendor.Validate("Payment Method Code", PaymentMethodCode);
        Vendor.Modify(true);
    end;

    local procedure CreateAndUpdateWithholdCode(): Code[20]
    var
        WithholdCode: Record "Withhold Code";
    begin
        LibraryITLocalization.CreateWithholdCode(WithholdCode);
        WithholdCode.Validate("Withholding Taxes Payable Acc.", CreateAndUpdateGLAccount());
        WithholdCode.Validate("Tax Code", Format(LibraryRandom.RandIntInRange(100, 9999)));  // Using Random value for Tax Code.
        WithholdCode.Validate("770 Code", StringTxt);
        WithholdCode.Modify(true);
        exit(WithholdCode.Code);
    end;

    local procedure CreateAndUpdateGLAccount(): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        UpdateVATPostingSetupIncludeInVATTransacRep(VATPostingSetup, false);  // FALSE for Include in VAT Transac. Rep.
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateDirectPostingGLAccount(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        GLAccount.Validate("Direct Posting", true);
        GLAccount.Modify(true);
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccountWithReverseChargeVAT(): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CalcMaxPaymentToleranceInvoice(DocumentNo: Code[20]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        GeneralLedgerSetup.Get();
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        if (SalesInvoiceHeader."Amount Including VAT" * GeneralLedgerSetup."Payment Tolerance %" / 100) >
           GeneralLedgerSetup."Max. Payment Tolerance Amount"
        then
            exit(GeneralLedgerSetup."Max. Payment Tolerance Amount");
        exit(SalesInvoiceHeader."Amount Including VAT" * GeneralLedgerSetup."Payment Tolerance %" / 100);
    end;

    local procedure CalculateWithholdTaxes(var TaxableBase: Decimal; VendorNo: Code[20]; LineAmount: Decimal) WithholdingTaxAmount: Decimal
    var
        WithholdCodeLine: Record "Withhold Code Line";
        Currency: Record Currency;
    begin
        FindWithholdCodeLine(WithholdCodeLine, VendorNo);
        TaxableBase := Round(LineAmount * WithholdCodeLine."Taxable Base %" / 100);
        WithholdingTaxAmount := Round(TaxableBase * WithholdCodeLine."Withholding Tax %" / 100, Currency."Amount Rounding Precision");
    end;

    local procedure CalculateWithholdTaxesContributionOnPurchInvoice(var WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card"; No: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        WithhTaxesContributionCard.Trap();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", No);
        PurchaseInvoice."With&hold Taxes-Soc. Sec.".Invoke();
        WithhTaxesContributionCard.Close();
        PurchaseInvoice.Close();
    end;

    local procedure ChangeStatusUsingVendorBillCardPage(VendorBillHeader: Record "Vendor Bill Header")
    var
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        VendorBillCard.OpenEdit();
        VendorBillCard.GotoRecord(VendorBillHeader);
        VendorBillCard.InsertVendBillLineManual.Invoke();
        VendorBillCard."&Create List".Invoke();
        VendorBillCard.Close();
    end;

    local procedure CreateCountryRegion(): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("Intrastat Code", CountryRegion.Code);
        CountryRegion.Modify(true);
        exit(CountryRegion.Code);
    end;

    local procedure CreateCustomer(ShipmentMethodCode: Code[10]; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]): Code[20]
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Shipment Method Code", ShipmentMethodCode);
        Customer.Validate("Country/Region Code", CountryRegionCode);
        Customer.Validate("VAT Registration No.", VATRegistrationNo);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerBillHeader(var CustomerBillHeader: Record "Customer Bill Header"; PaymentMethod: Code[10]; PostingDate: Date)
    var
        BillPostingGroup: Record "Bill Posting Group";
    begin
        BillPostingGroup.SetRange("Payment Method", PaymentMethod);
        BillPostingGroup.FindFirst();
        LibrarySales.CreateCustomerBillHeader(
          CustomerBillHeader, BillPostingGroup."No.", BillPostingGroup."Payment Method", CustomerBillHeader.Type::"Bills For Collection");
        CustomerBillHeader.Validate("Posting Date", PostingDate);
        CustomerBillHeader.Modify(true);
    end;

    local procedure CreateVATRegister(var VATRegister: Record "VAT Register"; OperationType: Code[20])
    var
        VATBookEntry: Record "VAT Book Entry";
        ReprintInfoFiscalReports: Record "Reprint Info Fiscal Reports";
        BeginDate: Date;
    begin
        BeginDate := CalcDate('<CM-1M+1D>', WorkDate());
        VATBookEntry.ModifyAll("Printing Date", BeginDate - 1);
        VATRegister.Get(FindVATRegister(OperationType));
        VATRegister.Validate("Last Printed VAT Register Page", LibraryRandom.RandInt(100));
        VATRegister.Validate("Last Printing Date", BeginDate + 1);
        VATRegister.Modify(true);
        ReprintInfoFiscalReports.SetRange("Vat Register Code", VATRegister.Code);
        ReprintInfoFiscalReports.DeleteAll();
    end;

    local procedure CreateCustomerWithPaymentMethod(var Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
    begin
        PaymentTerms.SetFilter("Payment Nos.", '>%1', 1);  // Payment Numbers greater than one requied.
        LibraryERM.FindPaymentTerms(PaymentTerms);
        PaymentMethod.SetRange("Bill Code", FindBill(true, true));  // Bank Receipt, Allow Issue - TRUE.
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithPaymentTerms(PaymentTermsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTermsCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateEUVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Shipment Method Code", FindShipmentMethod());
        Vendor.Validate("Country/Region Code", CreateVATRegistrationNoFormat());
        Vendor.Validate("VAT Registration No.", LibraryUtility.GenerateGUID());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateIndividualVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Registration No.", LibraryUtility.GenerateGUID());
        Vendor.Validate("Fiscal Code", LibraryITLocalization.GetFiscalCode());
        Vendor.Validate("Payment Terms Code", '');
        Vendor.Validate("Payment Method Code", '');
        Vendor.Validate("Individual Person", true);
        Vendor.Modify(true);

        UpdateIncludeInVATTransacRepOnVATPostingSetup(VATPostingSetup, true, Vendor."Gen. Bus. Posting Group");
        UpdateIncludeInVATTransacRepOnVATPostingSetup(VATPostingSetup, true, Vendor."VAT Bus. Posting Group");

        exit(Vendor."No.");
    end;

    local procedure CreateGenJnlLineWithAppliesToOccurence(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; DocNo: Code[20]; OccurenceNo: Integer; Amount: Decimal)
    begin
        CreateGeneralJournalLine(GenJournalLine, AccountType, AccNo, DocNo, Amount);
        GenJournalLine.Validate("Applies-to Occurrence No.", OccurenceNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        FindGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithVATProdPostingGroup(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePostCode(): Code[20]
    var
        CountryRegion: Record "Country/Region";
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryERM.CreatePostCode(PostCode);
        PostCode.Validate("Country/Region Code", CountryRegion.Code);
        PostCode.Modify(true);
        exit(PostCode.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; No: Code[20]; Type: Enum "Purchase Line Type"; LineDiscountPct: Decimal): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDecInRange(100, 500, 2));  // Using Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 500, 2));
        PurchaseLine.Validate("Line Discount %", LineDiscountPct);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseLine.Validate("Refers to Period", PurchaseLine."Refers to Period"::"Current Calendar Year");
        PurchaseLine.Modify(true);
        UpdateCheckTotalOnPuchaseDocument(PurchaseHeader, PurchaseLine."Amount Including VAT");
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreatePurchaseDocumentWithholdTaxesContribution(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendorWithholdCode(),
          CreateAndUpdateGLAccount(), PurchaseLine.Type::"G/L Account", LibraryRandom.RandInt(10));  // Random as Line Discount.
        CalculateWithholdTaxesContributionOnPurchInvoice(WithhTaxesContributionCard, PurchaseHeader."No.");
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseLine.Type::"G/L Account", PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseDocumentWithServiceTariffNumber(var PurchaseHeader: Record "Purchase Header"; VenderNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VenderNo);
        CreateAndUpdateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group",
          VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine.Type::Item, CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    var
        PaymentMethod: Record "Payment Method";
        ServiceTariffNumber: Record "Service Tariff Number";
        TransportMethod: Record "Transport Method";
    begin
        TransportMethod.FindFirst();
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Service Tariff No.", ServiceTariffNumber."No.");
        PurchaseHeader.Validate("Transport Method", TransportMethod.Code);
        PurchaseHeader.Validate("Payment Method Code", PaymentMethod.Code);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Refers to Period", PurchaseHeader."Refers to Period"::Current);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, ItemNo, LibraryRandom.RandInt(10));  // Quantity as Random.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; Amount: Integer; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        UpdatePmtToleranceGenLedgerSetup(LibraryRandom.RandIntInRange(1, 10), LibraryRandom.RandIntInRange(50, 100));  // Using Random value for Payment Tolerance % and Payment Tolerance Amount.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer('', '', ''));  // Blank for Shipment Code, Country Region Code and VAT Registration Number.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), Amount);
        SalesLine.Validate("Refers to Period", SalesLine."Refers to Period"::"Current Calendar Year");
        SalesLine.Modify(true);
        exit(SalesLine."Sell-to Customer No.");
    end;

    local procedure CreateSalesDocumentWithServiceTariffNumber(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateAndUpdateVATPostingSetup(
          VATPostingSetup, SalesHeader."VAT Bus. Posting Group", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesLine(SalesHeader, SalesLine.Type::Item, CreateItemWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));
    end;

    local procedure CreateAndPostSalesDocument(CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type"; VATCalculationType: Enum "Tax Calculation Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateAndUpdateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group", VATCalculationType);
        CreateVATTransactionReportAmount();
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup.Validate("Include in VAT Transac. Rep.", true);
        VATPostingSetup.Modify(true);
        CreateSalesLine(
          SalesHeader, SalesLine.Type::"G/L Account", CreateDirectPostingGLAccount(VATPostingSetup));
        UpdateIncludeInVATTransacRepOnSalsesLine(SalesLine, SalesHeader);

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    var
        PaymentMethod: Record "Payment Method";
        ServiceTariffNumber: Record "Service Tariff Number";
        TransportMethod: Record "Transport Method";
    begin
        TransportMethod.FindFirst();
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Service Tariff No.", ServiceTariffNumber."No.");
        SalesHeader.Validate("Transport Method", TransportMethod.Code);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Validate("Refers to Period", SalesHeader."Refers to Period"::Current);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, LibraryRandom.RandInt(10));  // Using Random Int for Item Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateAndUpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20]; VATCalculationType: Enum "Tax Calculation Type")
    begin
        CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATCalculationType);
        VATPostingSetup.Validate("VAT Identifier", LibraryERM.CreateRandomVATIdentifierAndGetCode());
        VATPostingSetup.Validate("EU Service", true);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20]; VATCalculationType: Enum "Tax Calculation Type")
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateVATRegistrationNoFormat(): Code[10]
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
    begin
        LibraryERM.CreateVATRegistrationNoFormat(VATRegistrationNoFormat, CreateCountryRegion());
        VATRegistrationNoFormat.Validate(Format, CopyStr(LibraryUtility.GenerateGUID(), 1, 2) + FormatTxt);
        VATRegistrationNoFormat.Modify(true);
        exit(VATRegistrationNoFormat."Country/Region Code");
    end;

    local procedure CreateVATTransactionReportAmount()
    var
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
    begin
        VATTransactionReportAmount.DeleteAll();
        LibraryITLocalization.CreateVATTransactionReportAmount(VATTransactionReportAmount, WorkDate());
        VATTransactionReportAmount.Validate("Threshold Amount Excl. VAT", 0);
        VATTransactionReportAmount.Validate("Threshold Amount Incl. VAT", LibraryRandom.RandDec(10, 2));
        VATTransactionReportAmount.Modify(true);
    end;

    local procedure CreateVendorWithholdCode(): Code[20]
    var
        Vendor: Record Vendor;
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        LibraryITLocalization.CreateWithholdCodeLine(WithholdCodeLine, CreateAndUpdateWithholdCode(), WorkDate());  // Using Random value for WithholdingTax and Taxable Base.
        WithholdCodeLine.Validate("Withholding Tax %", LibraryRandom.RandInt(10));  // Using Random value for WithholdingTax.
        WithholdCodeLine.Validate("Taxable Base %", LibraryRandom.RandInt(10));  // Using Random value for Taxable Base.
        WithholdCodeLine.Modify(true);
        CreateAndUpdateVendor(Vendor, false, WithholdCodeLine."Withhold Code", FindPaymentMethod());  // Using FALSE for Include In VAT Transac. Rep.
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue value for VendorBillCardPageHandler.
        LibraryVariableStorage.Enqueue(WithholdCodeLine."Withhold Code");  // Enqueue value for VendorBillCardPageHandler.
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithhold(): Code[20]
    var
        Vendor: Record Vendor;
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        LibraryITLocalization.CreateWithholdCodeLine(WithholdCodeLine, CreateAndUpdateWithholdCode(), WorkDate());  // Using Random value for WithholdingTax and Taxable Base.
        WithholdCodeLine.Validate("Withholding Tax %", LibraryRandom.RandInt(10));  // Using Random value for WithholdingTax.
        WithholdCodeLine.Validate("Taxable Base %", LibraryRandom.RandInt(10));  // Using Random value for Taxable Base.
        WithholdCodeLine.Modify(true);
        CreateAndUpdateVendor(Vendor, false, WithholdCodeLine."Withhold Code", FindPaymentMethod());  // Using FALSE for Include In VAT Transac. Rep.
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBillWithholdCodeSetup(var VendorBillHeader: Record "Vendor Bill Header") VendorNo: Code[20]
    var
        BankAccount: Record "Bank Account";
        BillPostingGroup: Record "Bill Posting Group";
    begin
        VendorNo := CreateVendorWithholdCode();
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, BankAccount."No.", FindPaymentMethod());
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BankAccount."No.");
        VendorBillHeader.Validate("Payment Method Code", BillPostingGroup."Payment Method");
        VendorBillHeader.Modify(true);
        ChangeStatusUsingVendorBillCardPage(VendorBillHeader);
    end;

    local procedure CreatePurchaseOrderAndVATRegister(var VATRegister: Record "VAT Register"; var PurchaseHeader: Record "Purchase Header"): Decimal
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        LineAmount: Decimal;
    begin
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LineAmount :=
          CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.",
            LibraryInventory.CreateItem(Item), PurchaseLine.Type::Item, LibraryRandom.RandInt(10));  // Random as Line Discount.
        CreateVATRegister(VATRegister, PurchaseHeader."Operation Type");
        exit(LineAmount);
    end;

    local procedure CreateReprintInfo(VATRegister: Record "VAT Register"): Integer
    var
        ReprintInfoFiscalReports: Record "Reprint Info Fiscal Reports";
    begin
        ReprintInfoFiscalReports.Init();
        ReprintInfoFiscalReports.Validate(Report, ReprintInfoFiscalReports.Report::"VAT Register - Print");
        ReprintInfoFiscalReports.Validate("Start Date", CalcDate('<CM-1M+1D>', WorkDate()));
        ReprintInfoFiscalReports."End Date" := CalcDate('<CM>', WorkDate());
        ReprintInfoFiscalReports."Vat Register Code" := VATRegister.Code;
        ReprintInfoFiscalReports."First Page Number" := LibraryRandom.RandInt(100);
        ReprintInfoFiscalReports.Insert(true);
        exit(ReprintInfoFiscalReports."First Page Number");
    end;

    local procedure CreatePaymentTermsWithThreeLines("Part": array[3] of Decimal): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        PaymentLines: Record "Payment Lines";
        i: Integer;
    begin
        LibraryERM.CreatePaymentTermsIT(PaymentTerms);
        for i := 1 to ArrayLen(Part) do begin
            LibraryERM.CreatePaymentLines(
              PaymentLines, PaymentLines."Sales/Purchase"::" ", PaymentLines.Type::"Payment Terms", PaymentTerms.Code, '', 0);
            PaymentLines.Validate("Payment %", Part[i] * 100);
            PaymentLines.Modify(true);
        end;
        exit(PaymentTerms.Code);
    end;

    local procedure RunVATRegisterReport(BeginDate: Date; VATRegisterCode: Code[10]; PrintingType: Option; PrintCompInfo: Boolean)
    var
        CompanyInformation: Record "Company Information";
        EndDate: Date;
    begin
        EndDate := CalcDate('<+1M-1D>', BeginDate);

        LibraryVariableStorage.Enqueue(VATRegisterCode);
        LibraryVariableStorage.Enqueue(BeginDate);
        LibraryVariableStorage.Enqueue(EndDate);
        LibraryVariableStorage.Enqueue(
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Register Company No."), DATABASE::"Company Information"));
        LibraryVariableStorage.Enqueue(LibraryITLocalization.GetVATCode());
        LibraryVariableStorage.Enqueue(PrintingType);
        LibraryVariableStorage.Enqueue(PrintCompInfo);

        Commit();
        REPORT.Run(REPORT::"VAT Register - Print");
    end;

    local procedure FindBill(BankReceipt: Boolean; AllowIssue: Boolean): Code[20]
    var
        Bill: Record Bill;
    begin
        Bill.SetRange("Bank Receipt", BankReceipt);
        Bill.SetRange("Allow Issue", AllowIssue);
        Bill.FindFirst();
        exit(Bill.Code);
    end;

    local procedure FindCustLedgerEntryWithDocumentType(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.FindFirst();
        CustLedgerEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindCustLedgerEntryTransactionNo(DocumentNo: Code[20]; AccountNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", AccountNo);
        CustLedgerEntry.SetRange(Open, true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        exit(CustLedgerEntry."Transaction No.");
    end;

    local procedure FindGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure FindPaymentLines(var PaymentLines: Record "Payment Lines"; Type: Enum "Payment Lines Document Type"; "Code": Code[20])
    begin
        PaymentLines.SetRange(Type, Type);
        PaymentLines.SetRange(Code, Code);
        PaymentLines.FindFirst();
    end;

    local procedure FindPaymentMethod(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Bill Code", FindBill(false, false));  // Bank Receipt, Allow Issue - FALSE.
        PaymentMethod.FindFirst();
        exit(PaymentMethod.Code);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, Type);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, Type);
        SalesLine.FindFirst();
    end;

    local procedure FindShipmentMethod(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.FindFirst();
        exit(ShipmentMethod.Code);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20])
    begin
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure FindVATRegister(OperationType: Code[20]): Code[10]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.SetRange(Code, OperationType);
        NoSeries.FindFirst();
        exit(NoSeries."VAT Register");
    end;

    local procedure FindWithholdCodeLine(var WithholdCodeLine: Record "Withhold Code Line"; VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        WithholdCodeLine.SetRange("Withhold Code", Vendor."Withholding Tax Code");
        WithholdCodeLine.FindFirst();
    end;

    local procedure FullVATSalesDocumentOnVatReport(DocumentType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Checks suggestion posted Full VAT entries for Sales Document
        DocumentNo :=
          CreateAndPostSalesDocument(
            CreateCustomer(FindShipmentMethod(), CreateVATRegistrationNoFormat(), LibraryUtility.GenerateGUID()),
            DocumentType,
            VATPostingSetup."VAT Calculation Type"::"Full VAT");

        SuggestAndVerifyVATReportLineCount(DocumentNo, 1);
    end;

    local procedure MockVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; PostingDate: Date; DueDate: Date)
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry."Due Date" := DueDate;
        VendorLedgerEntry.Amount := LibraryRandom.RandDecInDecimalRange(10, 20, 2);
        VendorLedgerEntry."Amount (LCY)" := VendorLedgerEntry.Amount;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
    end;

    local procedure MockDtldVendorLedgerEntry(VendorLedgerEntryNo: Integer; EntryAmount: Decimal): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        VendorLedgerEntry.Get(VendorLedgerEntryNo);
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendorLedgerEntry."Entry No.";
        DetailedVendorLedgEntry."Vendor No." := VendorLedgerEntry."Vendor No.";
        DetailedVendorLedgEntry."Entry Type" := DetailedVendorLedgEntry."Entry Type"::"Initial Entry";
        DetailedVendorLedgEntry.Amount := EntryAmount;
        DetailedVendorLedgEntry."Amount (LCY)" := EntryAmount;
        DetailedVendorLedgEntry."Posting Date" := VendorLedgerEntry."Posting Date";
        DetailedVendorLedgEntry."Initial Entry Due Date" := VendorLedgerEntry."Due Date";
        DetailedVendorLedgEntry.Insert();
        exit(DetailedVendorLedgEntry."Entry No.");
    end;

    local procedure MockCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; PostingDate: Date; DueDate: Date)
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry.Amount := LibraryRandom.RandDecInDecimalRange(10, 20, 2);
        CustLedgerEntry."Amount (LCY)" := CustLedgerEntry.Amount;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
    end;

    local procedure MockDtldCustLedgerEntry(CustomerLedgerEntryNo: Integer; EntryAmount: Decimal): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        CustLedgerEntry.Get(CustomerLedgerEntryNo);
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        DetailedCustLedgEntry."Customer No." := CustLedgerEntry."Customer No.";
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Initial Entry";
        DetailedCustLedgEntry.Amount := EntryAmount;
        DetailedCustLedgEntry."Amount (LCY)" := EntryAmount;
        DetailedCustLedgEntry."Posting Date" := CustLedgerEntry."Posting Date";
        DetailedCustLedgEntry."Initial Entry Due Date" := CustLedgerEntry."Due Date";
        DetailedCustLedgEntry.Insert();
        exit(DetailedCustLedgEntry."Entry No.");
    end;

    local procedure SuggestAndVerifyVATReportLineCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        VATReportLine: Record "VAT Report Line";
    begin
        // Exercise: Invoke Action - Suggest lines on Page - Vat Report.
        SuggestLinesOnVATReport();

        // Verify: Full VAT transaction should be suggested
        VATReportLine.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(ExpectedCount, VATReportLine.Count, SuggestedLinesCountMismatchErr);
    end;

    local procedure RunIssuingCustomerBillReport(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuingCustomerBill: Report "Issuing Customer Bill";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Occurrence", 1);  // Document Occurrence one is required to Issue one Customer Bill.
        IssuingCustomerBill.SetTableView(CustLedgerEntry);
        IssuingCustomerBill.Run();
    end;

    local procedure RunSuggestCustomerBillsReport(CustomerBillHeader: Record "Customer Bill Header"; CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SuggestCustomerBills: Report "Suggest Customer Bills";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        SuggestCustomerBills.SetTableView(CustLedgerEntry);
        SuggestCustomerBills.InitValues(CustomerBillHeader, true);
        SuggestCustomerBills.UseRequestPage(false);
        SuggestCustomerBills.Run();
    end;

    local procedure OpenWithholdTaxesContributionCardUsingPurchInvoicePage(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
        WithhTaxesContributionCard: TestPage "Withh. Taxes-Contribution Card";
    begin
        WithhTaxesContributionCard.Trap();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice."With&hold Taxes-Soc. Sec.".Invoke();
        WithhTaxesContributionCard.OK().Invoke();
        PurchaseInvoice.Close();
    end;

    local procedure OpenVendorLedgerEntriesPage(var VendorLedgerEntries: TestPage "Vendor Ledger Entries"; DocumentNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        VendorLedgerEntries.OpenEdit();
        VendorLedgerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        VendorLedgerEntries.FILTER.SetFilter("Document Type", Format(PurchaseHeader."Document Type"::Invoice));
    end;

    local procedure PostUsingVendorBillListSentCardPage(No: Code[20])
    var
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillListSentCard: TestPage "Vendor Bill List Sent Card";
    begin
        VendorBillHeader.Get(No);
        VendorBillListSentCard.OpenEdit();
        VendorBillListSentCard.GotoRecord(VendorBillHeader);
        VendorBillListSentCard.Post.Invoke();  // Opens ManualVendorPaymentLinePageHandler.
        VendorBillListSentCard.Close();
    end;

    local procedure ReverseCustLedgerEntries(DocumentNo: Code[20]; AccountNo: Code[20])
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(FindCustLedgerEntryTransactionNo(DocumentNo, AccountNo));
    end;

    local procedure RunCustomerBillsListReport(No: Code[20])
    var
        Customer: Record Customer;
        CustomerBillsList: Report "Customer Bills List";
    begin
        Clear(CustomerBillsList);
        Customer.SetRange("No.", No);
        CustomerBillsList.SetTableView(Customer);
        CustomerBillsList.Run();
    end;

    local procedure RunVendorAccountBillsListReport(No: Code[20])
    var
        Vendor: Record Vendor;
        VendorAccountBillsList: Report "Vendor Account Bills List";
    begin
        Clear(VendorAccountBillsList);
        Vendor.SetRange("No.", No);
        VendorAccountBillsList.SetTableView(Vendor);
        VendorAccountBillsList.Run();
    end;

    local procedure RunWithholdingTaxesReport(VendorNo: Code[20])
    var
        WithholdingTax: Record "Withholding Tax";
        WithholdingTaxes: Report "Withholding Taxes";
    begin
        Clear(WithholdingTaxes);
        WithholdingTax.SetRange("Vendor No.", VendorNo);
        WithholdingTaxes.SetTableView(WithholdingTax);
        WithholdingTaxes.Run();  // Invoke Handler - WithholdingTaxesRequestPageHandler.
    end;

    local procedure RunSuggestVendorBillsForVendorNo(VendorBillHeader: Record "Vendor Bill Header"; VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SuggestVendorBills: Report "Suggest Vendor Bills";
    begin
        SuggestVendorBills.InitValues(VendorBillHeader);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        SuggestVendorBills.SetTableView(VendorLedgerEntry);
        SuggestVendorBills.UseRequestPage(false);
        SuggestVendorBills.RunModal();
    end;

    local procedure ShowComputedWithholdContributionOnPayment(JnlBatchName: Code[10])
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(JnlBatchName);
        PaymentJournal.WithhTaxSocSec.Invoke();  // Invoke Handler - ShowComputedWithholdContributionModalPageHandler.
        PaymentJournal.Close();
    end;

    local procedure SuggestLinesOnVATReport()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReport: TestPage "VAT Report";
        VATReportSubform: TestPage "VAT Report Subform";
    begin
        VATReportHeader.DeleteAll();
        UpdateVATReportSetup();
        VATReportSubform.Trap();
        VATReport.OpenNew();
        VATReport."No.".Activate();
        VATReport."Start Date".SetValue(WorkDate());
        VATReport.SuggestLines.Invoke();
    end;

    local procedure UpdateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        VATReportSetup.Modify(true);
    end;

    local procedure UpdatePmtToleranceGenLedgerSetup(PaymentTolerancePct: Decimal; MaxPaymentToleranceAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", PaymentTolerancePct);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", MaxPaymentToleranceAmount);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateIndividualPersonFiscalCodeResidentOnCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        UpdateVATPostingSetupIncludeInVATTransacRep(VATPostingSetup, true);  // Include in VAT Transac. Rep as TRUE.
        Customer.Get(CustomerNo);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate(Resident, Customer.Resident::Resident);
        Customer.Validate("Individual Person", true);
        Customer.Validate("Fiscal Code", LibraryITLocalization.GetFiscalCode());
        Customer.Modify(true);
    end;

    local procedure UpdateServiceHeaderPostingDate(var ServiceHeader: Record "Service Header")
    begin
        ServiceHeader.Validate("Posting Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Posting date greater than WORKDATE.
        ServiceHeader.Modify(true);
    end;

    local procedure UpdateUnrealizedVATOnGeneralLedgerSetup(UnrealizedVAT: Boolean) OldUnrealizedVAT: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetupIncludeInVATTransacRep(var VATPostingSetup: Record "VAT Posting Setup"; IncludeInVATTransacRep: Boolean)
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Include in VAT Transac. Rep.", IncludeInVATTransacRep);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateVATRegistrationNoOnSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."VAT Registration No." := LibraryUtility.GenerateGUID();
        SalesHeader.Modify(true);
    end;

    local procedure UpdateIncludeInVATTransacRepOnVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; IncludeInVATTransacRep: Boolean; BusinessPostingGroup: Code[20])
    begin
        VATPostingSetup.SetRange("VAT Bus. Posting Group", BusinessPostingGroup);
        VATPostingSetup.ModifyAll("Include in VAT Transac. Rep.", IncludeInVATTransacRep);
    end;

    local procedure UpdateIncludeInVATTransacRepOnSalsesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        SalesLine.Validate("Include in VAT Transac. Rep.", true);
        SalesLine.Modify(true);
    end;

    local procedure UnapplyCustLedgerEntry(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UnapplyVendorLedgerEntry(DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.UnapplyVendorLedgerEntry(VendorLedgerEntry);
    end;

    local procedure UpdateCheckTotalOnPuchaseDocument(PurchaseHeader: Record "Purchase Header"; CheckTotal: Decimal)
    begin
        PurchaseHeader.Validate("Check Total", CheckTotal);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DocNo: Code[20])
    begin
        GenJournalLine."Document No." := DocNo;
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::"G/L Account";
        GenJournalLine."Bal. Account No." := '';
        GenJournalLine.Modify();
    end;

    local procedure UpdateNoSeriesOnGenJnlBatch(TemplateName: Code[10]; BatchName: Code[10]): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(TemplateName, BatchName);
        GenJournalBatch."No. Series" := '';
        GenJournalBatch."Posting No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch.Modify();
        exit(GenJournalBatch."Posting No. Series");
    end;

    local procedure UpdatePmtTolerance(MaxPaymentToleranceAmount: Decimal)
    var
        ChangePaymentTolerance: Report "Change Payment Tolerance";
    begin
        ChangePaymentTolerance.InitializeRequest(true, '', 0, MaxPaymentToleranceAmount);
        ChangePaymentTolerance.UseRequestPage(false);
        ChangePaymentTolerance.Run();
    end;

    local procedure UpdateTaxPerscentsOnVendorWitholdingTax(VendorNo: Code[20]; WithholdingTaxPercent: Decimal; TaxableBasePercent: Decimal)
    var
        Vendor: Record Vendor;
        WithholdCodeLine: Record "Withhold Code Line";
    begin
        Vendor.Get(VendorNo);
        WithholdCodeLine.SetRange("Withhold Code", Vendor."Withholding Tax Code");
        WithholdCodeLine.FindFirst();
        WithholdCodeLine.Validate("Withholding Tax %", WithholdingTaxPercent);
        WithholdCodeLine.Validate("Taxable Base %", TaxableBasePercent);
        WithholdCodeLine.Modify(true);
    end;

    local procedure VerifyAmountInclVATAndBaseAmountOnVATReportSubformPage(DocumentNo: Code[20]; Amount: Decimal; AmountIncludingVAT: Decimal)
    var
        VATReportSubform: TestPage "VAT Report Subform";
    begin
        VATReportSubform.OpenEdit();
        VATReportSubform.FILTER.SetFilter("Document No.", DocumentNo);
        VATReportSubform.Base.AssertEquals(Amount);
        VATReportSubform."Amount Incl. VAT".AssertEquals(AmountIncludingVAT);
        VATReportSubform.Close();
    end;

    local procedure VerifyDetailedCustomerLedgerEntry(DocumentNo: Code[20]; CustomerNo: Code[20]; AmountFilter: Text[30]; Amount: Decimal)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.SetRange("Initial Document Type", DetailedCustLedgEntry."Initial Document Type"::Payment);
        DetailedCustLedgEntry.SetFilter(Amount, AmountFilter, 0);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyDetailedVendorLedgerEntry(DocumentNo: Code[20]; VendorNo: Code[20]; AmountFilter: Text[30]; Amount: Decimal)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::Application);
        DetailedVendorLedgEntry.SetRange("Vendor No.", VendorNo);
        DetailedVendorLedgEntry.SetRange("Initial Document Type", DetailedVendorLedgEntry."Initial Document Type"::Payment);
        DetailedVendorLedgEntry.SetFilter(Amount, AmountFilter, 0);
        DetailedVendorLedgEntry.FindFirst();
        DetailedVendorLedgEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyEntryNoAndAmountOnCustomerBillsList(SellToCustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, SellToCustomerNo);
        VerifyEntryNoAndAmountOnReports(CustomerNoTok, CustLedgEntryNumberTok, CustLedgEntryAmountTok,
          SellToCustomerNo, CustLedgerEntry."Entry No.", CustLedgerEntry."Sales (LCY)");
    end;

    local procedure VerifyEntryNoAndAmountOnReports(NumberCap: Text[50]; EntryNumberCap: Text[50]; AmountCap: Text[50]; Number: Code[20]; EntryNumber: Integer; Amount: Decimal)
    begin
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.AssertElementWithValueExists(NumberCap, Number);
        LibraryReportDataSet.AssertElementWithValueExists(EntryNumberCap, EntryNumber);
        LibraryReportDataSet.AssertElementWithValueExists(AmountCap, Amount);
    end;

    local procedure VerifyGLEntryAmount(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; CreditAmount: Decimal; DebitAmount: Decimal; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField("Posting Date", PostingDate);
        Assert.AreNearlyEqual(CreditAmount, GLEntry."Credit Amount", LibraryERM.GetAmountRoundingPrecision(), ValueMustNotSameMsg);
        Assert.AreNearlyEqual(DebitAmount, GLEntry."Debit Amount", LibraryERM.GetAmountRoundingPrecision(), ValueMustNotSameMsg);
    end;

    local procedure VerifyCustLedgerEntryPaymentMethodAmountAndDueDate(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; CustomerNo: Code[20]; PaymentMethod: Code[10]; Amount: Decimal; DueDate: Date)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        FindCustLedgerEntryWithDocumentType(CustLedgerEntry, CustomerNo, DocumentType);
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField("Payment Method Code", PaymentMethod);
        CustLedgerEntry.TestField("Due Date", DueDate);
        Assert.AreNearlyEqual(Amount, CustLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), ValueMustNotSameMsg);
    end;

    local procedure VerifyPurchCommentLine(DocumentNo: Code[20]; DocumentType: Enum "Purchase Comment Document Type")
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        PurchCommentLine.SetRange("No.", DocumentNo);
        PurchCommentLine.FindFirst();
        PurchCommentLine.TestField("Document Type", DocumentType);
    end;

    local procedure VerifySubformCustomerBillLineValues(CustomerNo: Code[20]; DocumentNo: Code[20]; Amount: Decimal; DueDate: Date)
    var
        SalesLine: Record "Sales Line";
        SubformCustomerBillLine: TestPage "Subform Customer Bill Line";
    begin
        SubformCustomerBillLine.OpenEdit();
        SubformCustomerBillLine.FILTER.SetFilter("Customer No.", CustomerNo);
        SubformCustomerBillLine."Document Type".AssertEquals(SalesLine."Document Type"::Invoice);
        SubformCustomerBillLine."Document No.".AssertEquals(DocumentNo);
        SubformCustomerBillLine."Due Date".AssertEquals(DueDate);
        Assert.AreNearlyEqual(Amount, SubformCustomerBillLine.Amount.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), ValueMustNotSameMsg);
    end;

    local procedure VerifyMaxPaymentToleranceInvoice(DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PaymentToleranceAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        PaymentToleranceAmount := CalcMaxPaymentToleranceInvoice(DocumentNo);
        Assert.AreNearlyEqual(
          PaymentToleranceAmount, CustLedgerEntry."Max. Payment Tolerance",
          GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountErrorMsg, CustLedgerEntry.FieldCaption(Amount),
            PaymentToleranceAmount, CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
        Assert.AreNotEqual(CustLedgerEntry.Amount, CustLedgerEntry."Remaining Amount", ValueMustNotSameMsg);
    end;

    local procedure VerifyEntryNoAndAmountOnVendorAccountBillsList(BuyFromVendorNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchInvHeader.FindFirst();
        VendorLedgerEntry.SetRange("Document No.", PurchInvHeader."No.");
        VendorLedgerEntry.FindFirst();
        VerifyEntryNoAndAmountOnReports(
          VendorNoTok, VendLedgEntryNumberTok, VendLedgEntryAmountTok,
          BuyFromVendorNo, VendorLedgerEntry."Entry No.", VendorLedgerEntry."Purchase (LCY)");
    end;

    local procedure VerifyVATEntryBaseAndAmount(DocumentNo: Code[20]; Base: Decimal; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          VATEntry.Base, Base, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), Base));
        Assert.AreNearlyEqual(
          VATEntry.Amount, Amount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(AmountErr, VATEntry.FieldCaption(Amount), Amount));
    end;

    local procedure VerifyVendorNameExistOnVATRegister(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        LibraryReportDataSet.LoadDataSetFile();
        LibraryReportDataSet.SetRange(VATBookEntrySellToBuyFromNoTok, Vendor."No.");
        if not LibraryReportDataSet.GetNextRow() then
            Error(RowNotFoundErr, VATBookEntrySellToBuyFromNoTok, Vendor."No.");
        LibraryReportDataSet.AssertCurrentRowValueEquals(NameTok, Vendor.Name);
    end;

    local procedure VerifyVendorLedgerEntry(VendorNo: Code[20]; Amount: Decimal; Open: Boolean)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VendorLedgerEntry.TestField(Open, Open);
        VendorLedgerEntry.TestField("Remaining Amount", Amount);  // Remaining Amount must be zero after Apply Vendor Entry and Post Application.
    end;

    local procedure VerifyOfficialDateGLVATBookEntries(AccountNo: Code[20])
    var
        GLBookEntry: Record "GL Book Entry";
        VATBookEntry: Record "VAT Book Entry";
    begin
        GLBookEntry.SetRange("G/L Account No.", AccountNo);
        GLBookEntry.FindFirst();
        GLBookEntry.TestField("Official Date", NormalDate(WorkDate()));
        VATBookEntry.SetRange("Document No.", GLBookEntry."Document No.");
        VATBookEntry.FindFirst();
        VATBookEntry.TestField("Official Date", NormalDate(WorkDate()));
    end;

    local procedure CreateVendorWithDimension(var Vendor: Record Vendor)
    var
        Dimension: array[4] of Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Method Code", FindPaymentMethod());
        Vendor.Modify(true);

        for i := 1 to 4 do begin
            GenerateDimensions(Dimension[i], DimensionValue);
            LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", Dimension[i].Code, DimensionValue.Code);
        end;
    end;

    local procedure GenerateDimensions(var Dimension: Record Dimension; var DimensionValue: Record "Dimension Value")
    var
        Number: Integer;
    begin
        LibraryDimension.CreateDimension(Dimension);
        Number := LibraryRandom.RandIntInRange(5, 10);
        while Number > 0 do begin
            LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
            Number -= 1;
        end;
    end;

    local procedure CreateBillPostingGroupWithFullSetup(var BillPostingGroup: Record "Bill Posting Group"; PaymentMethod: Code[10]; BankAccountNo: Code[20])
    var
        BillPostingGroup2: Record "Bill Posting Group";
        PaymentMethod2: Record "Payment Method";
    begin
        PaymentMethod2.Setrange("Bill Code", FindBill(true, true));
        PaymentMethod2.FindFirst();
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup2, BankAccountNo, PaymentMethod);
        LibraryITLocalization.CreateBillPostingGroup(BillPostingGroup, BankAccountNo, PaymentMethod2.Code);
        BillPostingGroup.Validate("Bills For Collection Acc. No.", LibraryERM.CreateGLAccountNo());
        BillPostingGroup.Validate("Bills For Discount Acc. No.", LibraryERM.CreateGLAccountNo());
        BillPostingGroup.Validate("Bills Subj. to Coll. Acc. No.", LibraryERM.CreateGLAccountNo());
        BillPostingGroup.Validate("Expense Bill Account No.", LibraryERM.CreateGLAccountNo());
        BillPostingGroup.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceAndPost(VendorNo: Code[20])
    var
        PurchasHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchasHeader, VendorNo);
        LibraryPurchase.PostPurchaseDocument(PurchasHeader, true, true);
    end;

    local procedure CretaeVendorBillHeader(var VendorBillHeader: Record "Vendor Bill Header"; BankAccNo: Code[20])
    begin
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BankAccNo);
        VendorBillHeader.Validate("Payment Method Code", FindPaymentMethod());
        VendorBillHeader.Modify(true);
    end;

    local procedure SuggestMultipleVendorsBills(VendorBillHeader: Record "Vendor Bill Header"; VendorNo: Code[50])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SuggestVendorBills: Report "Suggest Vendor Bills";
    begin
        Commit();
        VendorLedgerEntry.SetFilter("Vendor No.", VendorNo);
        SuggestVendorBills.InitValues(VendorBillHeader);
        SuggestVendorBills.SetTableView(VendorLedgerEntry);
        SuggestVendorBills.UseRequestPage(false);
        SuggestVendorBills.Run();
    end;

    local procedure IssueVendorBill(No: Code[20])
    var
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        VendorBillCard.OpenEdit();
        VendorBillCard.Filter.SetFilter("No.", No);
        VendorBillCard."&Create List".Invoke();
    end;

    local procedure VerifyGlEntryDimensions(BankAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Source No.", BankAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField("Dimension Set ID", 0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesModalPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        FindVendorLedgerEntry(VendorLedgerEntry, VendorNo);
        ApplyVendorEntries.FindFirstField(ApplyVendorEntries."Document No.", VendorLedgerEntry."Document No.");
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.FindNextField(ApplyVendorEntries."Document No.", VendorLedgerEntry."Document No.");
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ManualVendorPaymentLinePageHandler(var ManualVendorPaymentLine: TestPage "Manual vendor Payment Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorNo: Variant;
        WithholdingTaxCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(WithholdingTaxCode);
        ManualVendorPaymentLine.VendorNo.SetValue(VendorNo);
        ManualVendorPaymentLine.WithholdingTaxCode.SetValue(WithholdingTaxCode);
        ManualVendorPaymentLine.DocumentType.SetValue(VendorLedgerEntry."Document Type"::Payment);
        ManualVendorPaymentLine.DocumentNo.SetValue(LibraryUtility.GenerateGUID());
        ManualVendorPaymentLine.DocumentDate.SetValue(WorkDate());
        ManualVendorPaymentLine.TotalAmount.SetValue(LibraryRandom.RandInt(100));
        ManualVendorPaymentLine.InsertLine.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationModalPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CommentRequestPageHandler(var PurchCommentSheet: TestPage "Purch. Comment Sheet")
    begin
        PurchCommentSheet.Date.SetValue(WorkDate());
        PurchCommentSheet.Comment.SetValue(LibraryUtility.GenerateGUID());
        PurchCommentSheet.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBilListPageHandler(var CustomerBillsList: TestRequestPage "Customer Bills List")
    var
        OnlyOpenedEntries: Variant;
    begin
        LibraryVariableStorage.Dequeue(OnlyOpenedEntries);
        CustomerBillsList."Only Opened Entries".SetValue(OnlyOpenedEntries);
        CustomerBillsList."Ending Date".SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Using random Date.
        CustomerBillsList.SaveAsXml(LibraryReportDataSet.GetParametersFileName(), LibraryReportDataSet.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShowComputedWithholdContributionModalPageHandler(var ShowComputedWithhContrib: TestPage "Show Computed Withh. Contrib.")
    begin
        ShowComputedWithhContrib.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShowComputedWithholdContributionMultipleCloseHandler(var ShowComputedWithhContrib: TestPage "Show Computed Withh. Contrib.")
    begin
        ShowComputedWithhContrib.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerAgingMatrixModalPageHandler(var CustomerAgingMatrix: TestPage "Customer Aging Matrix")
    begin
        CustomerAgingMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(CustomerAgingMatrix.Field1.Caption);
        LibraryVariableStorage.Enqueue(CustomerAgingMatrix.Field1.Value());
        LibraryVariableStorage.Enqueue(CustomerAgingMatrix.Field2.Caption);
        LibraryVariableStorage.Enqueue(CustomerAgingMatrix.Field2.Value());
        LibraryVariableStorage.Enqueue(CustomerAgingMatrix.Field3.Caption);
        LibraryVariableStorage.Enqueue(CustomerAgingMatrix.Field3.Value());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorAgingMatrixModalPageHandler(var VendorAgingMatrix: TestPage "Vendor Aging Matrix")
    begin
        VendorAgingMatrix.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(VendorAgingMatrix.Field1.Caption);
        LibraryVariableStorage.Enqueue(VendorAgingMatrix.Field1.Value());
        LibraryVariableStorage.Enqueue(VendorAgingMatrix.Field2.Caption);
        LibraryVariableStorage.Enqueue(VendorAgingMatrix.Field2.Value());
        LibraryVariableStorage.Enqueue(VendorAgingMatrix.Field3.Caption);
        LibraryVariableStorage.Enqueue(VendorAgingMatrix.Field3.Value());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterPrintPageHandler(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    begin
        VATRegisterPrint.VATRegister.SetValue(LibraryVariableStorage.DequeueText());
        VATRegisterPrint.PeriodStartingDate.SetValue(LibraryVariableStorage.DequeueDate());
        VATRegisterPrint.PeriodEndingDate.SetValue(LibraryVariableStorage.DequeueDate());
        VATRegisterPrint.RegisterCompanyNo.SetValue(LibraryVariableStorage.DequeueText());
        VATRegisterPrint.FiscalCode.SetValue(LibraryVariableStorage.DequeueText());
        VATRegisterPrint.PrintingType.SetValue(LibraryVariableStorage.DequeueInteger());
        VATRegisterPrint.PrintCompanyInformations.SetValue(LibraryVariableStorage.DequeueBoolean());

        VATRegisterPrint.SaveAsXml(LibraryReportDataSet.GetParametersFileName(), LibraryReportDataSet.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorAccountBillListPageHandler(var VendorAccountBillsList: TestRequestPage "Vendor Account Bills List")
    var
        OnlyOpenedEntries: Variant;
    begin
        LibraryVariableStorage.Dequeue(OnlyOpenedEntries);
        VendorAccountBillsList.OnlyOpenedEntries.SetValue(OnlyOpenedEntries);
        VendorAccountBillsList.EndingDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));  // Using random Date.
        VendorAccountBillsList.SaveAsXml(LibraryReportDataSet.GetParametersFileName(), LibraryReportDataSet.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WithholdingTaxesRequestPageHandler(var WithholdingTaxes: TestRequestPage "Withholding Taxes")
    begin
        WithholdingTaxes.ReferenceMonth.SetValue(Date2DMY(WorkDate(), 2));  // For Reference Month.
        WithholdingTaxes.ReferenceYear.SetValue(Date2DMY(WorkDate(), 3));  // For Reference Year.
        WithholdingTaxes.FinalPrinting.SetValue(true);
        WithholdingTaxes.SaveAsXml(LibraryReportDataSet.GetParametersFileName(), LibraryReportDataSet.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssuingCustomerBillRequestPageHandler(var IssuingCustomerBill: TestRequestPage "Issuing Customer Bill")
    begin
        IssuingCustomerBill.PostingDate.SetValue(CalcDate('<' + Format(LibraryRandom.RandIntInRange(5, 10)) + 'D>', WorkDate()));
        IssuingCustomerBill.DocumentDate.SetValue(IssuingCustomerBill.PostingDate.AsDate());
        IssuingCustomerBill.PostingDescription.SetValue(IssuingCustomerBill.PostingDescription.Caption);
        LibraryVariableStorage.Enqueue(IssuingCustomerBill.PostingDate.AsDate());  // Enqueue value in Test function.
        IssuingCustomerBill.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerBillsListRequestPageHandler(var CustomerBillsList: TestRequestPage "Customer Bills List")
    var
        EndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(EndingDate);
        CustomerBillsList."Ending Date".SetValue(EndingDate);
        CustomerBillsList.SaveAsXml(LibraryReportDataSet.GetParametersFileName(), LibraryReportDataSet.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerWithVerification(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtToleranceWarningZeroBalanceModalPageHandler(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    begin
        LibraryVariableStorage.Enqueue(PaymentToleranceWarning.ApplyingAmount.Value);
        LibraryVariableStorage.Enqueue(PaymentToleranceWarning.AppliedAmount.Value);
        LibraryVariableStorage.Enqueue(PaymentToleranceWarning.BalanceAmount.Value);
    end;
}
