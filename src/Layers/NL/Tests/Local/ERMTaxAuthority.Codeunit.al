codeunit 144005 "ERM Tax Authority"
{
    // // [FEATURE] [Tax Authority - Audit File]
    // Test for feature Audit.
    //  1. Verify Posting date, Sourc Code, Entry No., VAT Business Posting Group, GL Account No., Description, Vendor/Customer
    //    Details  in generated Audit file with in Start Date/End Date.
    //  2. Verify total number entries and Credit/Debit Amount from GL Entry  in generated Audit file.
    //  3. Verify Reversal entry in generated Audit file.
    //  4. Verify no description with 'Transactie beginbalans' found in generated Audit file when ExcludeBalance on Tax Authority - Audit File set to TRUE.
    //  5. Verify description in generated Audit file when ExcludeBalance on Tax Authority - Audit File set to FALSE.
    //  6. Verify report header details in generated Audit file.
    //  7. Verify Tax Registration No. in generated Audit file when VAT Registration No. is blank on Company Information.
    //  8. Verify description in generated Audit file when Audit file contains closing G/L entries.
    //  9. Verify the Audit file can be overwritten.
    //
    // Covers Test Cases for WI - 342836
    // ------------------------------------------------------------------------------------------------------
    // Test Function Name                          TFS ID
    // ------------------------------------------------------------------------------------------------------
    // TaxAuthorityAuditGLEnries                   151278, 151279, 151280, 151285, 151286, 151392, 151393
    // AuditTotalGLEntryAmount                     151281
    // AuditReversalEntry                          151282
    //
    // Covers Test Cases for WI - 342837
    // ----------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                             TFS ID
    // ----------------------------------------------------------------------------------------------------------------
    // DescriptionWithExcludeBalanceTrue                                              151546
    // DescriptionWithExcludeBalanceFalse                                             151547
    // HeaderInformation                                                              151551,151548,173622,151650,151550
    // VATRegistrationNoBlank                                                         151539,173621
    // AuditFileWithClosingGLEntries                                                  151284
    // OverwriteAuditFile                                                             151543

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryXPathXMLReader: Codeunit "Library - XPath XML Reader";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryDimension: Codeunit "Library - Dimension";
        FileManagement: Codeunit "File Management";
        DescriptionCap: Label 'desc';
        JournalIDCap: Label 'jrnID';
        TaxRegistrationCap: Label 'taxRegIdent';
        TransactieBeginbalansCap: Label 'Transactie beginbalans';
        ReverseEntriesQst: Label 'To reverse these entries, correcting entries will be posted.';
        CloseFiscalYearQst: Label 'Do you want to create and close the fiscal year?';
        SuccessfullyReversedMsg: Label 'The entries were successfully reversed.';
        SuccessfullyCreatedMsg: Label 'The journal lines have successfully been created.';
        UnexpectedMsg: Label 'Unexpected message.';
        NodeNotFoundMsg: Label 'A XML node with the value %1 could not be found.';
        DecimalFormatTxt: Label '<Precision,2:2><Standard Format,0>', Locked = true;
        DateFormatTxt: Label '<Year4>-<Month,2>-<Day,2>', Locked = true;
        XAFNameSpaceTxt: Label 'http://www.auditfiles.nl/XAF/3.2', Locked = true;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    procedure TaxAuthorityAuditGLEnries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SourceCode: Record "Source Code";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        Amount: Decimal;
        FileName: Text;
        LedgerAccXPath: Text;
        JournalXPath: Text;
        TrLineXPath: Text;
        PostingDate: Date;
    begin
        // [SCENARIO 209589] Audit file have to contains formated values of Customer."No." and Vendor."No."
        // [SCENARIO 431143] Transaction information in Audit file version 3.2.

        // Setup: Create and post Sales Order, Purchase Order and Gen. Journal.
        Initialize();
        PostingDate := GetPostingDate();

        // [GIVEN] Posted purchase order for Vendor."No." = "VENDOR0001"
        PurchInvHeader.Get(CreateAndPostPurchaseOrder(PostingDate));
        FindGLEntry(GLEntry, PurchInvHeader."No.", false);
        Vendor.Get(PurchInvHeader."Buy-from Vendor No.");

        // [GIVEN] Posted sales order for Customer."No." = "CUSTOMER0001"
        SalesInvoiceHeader.Get(CreateAndPostSalesOrder(PostingDate));
        FindGLEntry(GLEntry2, SalesInvoiceHeader."No.", false);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");

        CreateLedgerEntry(GenJournalBatch, CalcDate('<' + Format(LibraryRandom.RandIntInRange(1, 4)) + 'D>', PostingDate));
        GLAccount.Get(GLEntry2."G/L Account No.");

        // [WHEN] Run report "Tax Authority - Audit File"
        EnqueueValuesForRequestPage(PostingDate, true);
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();

        // [THEN] G/L Account information is stored under "ledgerAccount" tag.
        LibraryXPathXMLReader.Initialize(FileName, XAFNameSpaceTxt);
        LedgerAccXPath := '//company/generalLedger/ledgerAccount/';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(LedgerAccXPath + 'accID', GLAccount."No.", 5);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(LedgerAccXPath + 'accDesc', GLAccount.Name, 5);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(LedgerAccXPath + 'accTp', 'P', 5);   // P - Profit and Loss
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(LedgerAccXPath + 'leadCode', GLAccount."No.", 5);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(LedgerAccXPath + 'leadDescription', GLAccount.Name, 5);

        // [THEN] G/L Entry information is stored under "journal" tag.
        SourceCode.Get(GLEntry."Source Code");
        JournalXPath := '//auditfile/company/transactions/journal/';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(JournalXPath + 'jrnID', GLEntry."Source Code", 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(JournalXPath + 'desc', SourceCode.Description, 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(JournalXPath + 'jrnID', GLEntry2."Source Code", 1);

        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(JournalXPath + 'transaction/nr', Format(GLEntry."Transaction No."), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(JournalXPath + 'transaction/desc', Format(GLEntry.Description), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(JournalXPath + 'transaction/periodNumber', Format(Date2DMY(PostingDate, 2)), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(JournalXPath + 'transaction/trDt', Format(PostingDate, 0, DateFormatTxt), 0);

        TrLineXPath := '//auditfile/company/transactions/journal/transaction/trLine/';
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'nr', Format(GLEntry."Entry No."), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'accID', GLEntry."G/L Account No.", 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'docRef', GLEntry."Document No.", 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'effDate', Format(GLEntry."Posting Date", 0, DateFormatTxt), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'effDate', Format(GLEntry2."Posting Date", 0, DateFormatTxt), 3);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'desc', GLEntry.Description, 0);
        Amount := GLEntry."Debit Amount";
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'amnt', Format(Amount, 0, 9), 0);  // 3 trLine per transaction
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'amntTp', 'D', 0);
        Amount := GLEntry2."Credit Amount";
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'amnt', Format(Amount, 0, 9), 3);  // 3 trLine per transaction
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'amntTp', 'C', 3);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'costID', GLEntry."Global Dimension 1 Code", 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'prodID', GLEntry."Global Dimension 2 Code", 0);

        VATPostingSetup.Get(GLEntry."VAT Bus. Posting Group", GLEntry."VAT Prod. Posting Group");
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'vat/vatID', GLEntry."VAT Prod. Posting Group", 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
            TrLineXPath + 'vat/vatPerc', Format(VATPostingSetup."VAT %", 0, '<Precision,:3><Standard Format,9>'), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
            TrLineXPath + 'vat/vatAmnt', ConvertStr(Format(GLEntry."VAT Amount", 0, DecimalFormatTxt), ',', '.'), 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'vat/vatAmntTp', 'D', 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'vat/vatAmntTp', 'C', 1);

        // [THEN] Value 'custSupID' for the first supplier = '3VENDOR0001'
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'custSupID', '3' + Vendor."No.", 0);

        // [THEN] Value 'custSupID' for the second supplier = '2CUSTOMER0001'
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(TrLineXPath + 'custSupID', '2' + Customer."No.", 3);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    procedure AuditTotalGLEntryAmount()
    var
        GLEntry: Record "G/L Entry";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        FileName: Text;
        PostingDate: Date;
        DocumentNo: Code[20];
    begin
        // Verify total number entries and Credit/Debit Amount from GL Entry  in generated Audit file.

        // Setup: Create and post Sales Order, find GL Entry.
        Initialize();

        // [GIVEN] Use random posting date and clear all entries before posting to avoid clashes
        PostingDate := GetPostingDate();
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.DeleteAll();
        DocumentNo := CreateAndPostSalesOrder(PostingDate);
        Commit();

        // [WHEN] Run Tax Authority - Audit File report.
        EnqueueValuesForRequestPage(PostingDate, true);
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();

        // [THEN] Verify Total number entries and credit/debit amount from GL Entry  in generated Audit file.
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", DocumentNo);
        LibraryXPathXMLReader.Initialize(FileName, XAFNameSpaceTxt);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//company/transactions/linesCount', Format(GLEntry.Count));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
            '//company/transactions/totalDebit', ConvertStr(Format(GetGLEntryAmount(DocumentNo, '>%1'), 0, DecimalFormatTxt), ',', '.'));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
            '//company/transactions/totalCredit', ConvertStr(Format(Abs(GetGLEntryAmount(DocumentNo, '<%1')), 0, DecimalFormatTxt), ',', '.'));
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler,MessageHandler,ConfirmHandler')]
    procedure AuditReversalEntry()
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        FileName: Text;
    begin
        // Verify Reversal entry in generated Audit file.
        Initialize();

        // [GIVEN] Create and post Gen Jouranl and reverse.
        FindGLEntry(
          GLEntry, CreateLedgerEntry(GenJournalBatch, GetPostingDate()), false);
        LibraryVariableStorage.Enqueue(ReverseEntriesQst);  // Enqueue for ConfirmHandler.
        ReverseTransaction(GLEntry."Transaction No.");

        // [WHEN] Run Tax Authority - Audit File report.
        EnqueueValuesForRequestPage(GLEntry."Posting Date", false);
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();

        // [THEN] Verify Reversal entry in generated Audit file.
        FindGLEntry(GLEntry2, GLEntry."Document No.", true);
        GLEntry2.FindLast();
        VerifyTaxAuthorityAuditFile(FileName, JournalIDCap, GLEntry2."Source Code", -1);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    procedure DescriptionWithExcludeBalanceTrue()
    var
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
        [RunOnClient]
        Node: DotNet XmlNode;
        FileName: Text;
    begin
        // Verify no description with 'Transactie beginbalans' found in generated Audit file when ExcludeBalance on Tax Authority - Audit File set to TRUE.
        Initialize();

        // [WHEN] Create and post Gen. Journal and run report.
        FileName := FileManagement.ServerTempFileName('xaf');
        CreateLedgerEntryAndRunReport(FileName, true);  // TRUE for ExcludeBalance.

        // [THEN] Verify Description in generated Audit file when ExcludeBalance on Tax Authority - Audit File set to TRUE.
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.GetNodeListByElementName(DescriptionCap, NodeList);
        Node := NodeList.Item(2);
        Assert.AreNotEqual(StrSubstNo(TransactieBeginbalansCap), Node.InnerText, UnexpectedMsg);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    procedure DescriptionWithExcludeBalanceFalse()
    var
        FileName: Text;
    begin
        // Verify description in generated Audit file when ExcludeBalance on Tax Authority - Audit File set to FALSE.
        Initialize();

        // [WHEN] Create and post Gen. Journal and run report.
        FileName := FileManagement.ServerTempFileName('xaf');
        CreateLedgerEntryAndRunReport(FileName, false);  // FALSE for ExludeBalance.

        // [THEN]
        VerifyTaxAuthorityAuditFile(FileName, DescriptionCap, StrSubstNo(TransactieBeginbalansCap), 2);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    procedure HeaderInformation()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        ApplicationSystemConstants: Codeunit "Application System Constants";
        FileName: Text;
    begin
        // Verify report header details in generated Audit file.
        Initialize();

        // [GIVEN] Posted Sales Order.
        UpdateLCYCodeGLSetup(GeneralLedgerSetup);
        CreateAndPostSalesOrder(GetPostingDate());
        Commit();

        // [WHEN] Run Tax Authority - Audit File report.
        EnqueueValuesForRequestPage(GetPostingDate(), false);
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();

        // [THEN] Verify start/end date, Currency code, software name and version, Date format in generated Audit file are according to the length prescribed by the tax authorities.
        LibraryXPathXMLReader.Initialize(FileName, XAFNameSpaceTxt);
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//auditfile/header/startDate', Format(GetPostingDate(), 0, DateFormatTxt));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//auditfile/header/endDate', Format(GetPostingDate(), 0, DateFormatTxt));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//auditfile/header/curCode', CopyStr(GeneralLedgerSetup."LCY Code", 1, 3));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//auditfile/header/dateCreated', Format(Today, 0, DateFormatTxt));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//auditfile/header/softwareDesc', 'Microsoft Dynamics NAV');
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//auditfile/header/softwareVersion', CopyStr(ApplicationSystemConstants.ApplicationVersion(), 1, 20));
        LibraryXPathXMLReader.VerifyNodeValueByXPath('//transactions/journal/transaction/trDt', Format(GetPostingDate(), 0, DateFormatTxt));
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    procedure VATRegistrationNoBlank()
    var
        CompanyInformation: Record "Company Information";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        FileName: Text;
    begin
        // Verify Tax Registration No. in generated Audit file when VAT Registration No. is blank on Company Information.
        Initialize();

        // [GIVEN] Company Information with blank VAT Registration No.
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := '';
        CompanyInformation.Modify();
        Commit();

        // [WHEN] Run Tax Authority - Audit File report.
        EnqueueValuesForRequestPage(GetPostingDate(), false);
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();

        // [THEN] Verify Tax Registration No. in generated Audit file.
        VerifyTaxAuthorityAuditFile(FileName, TaxRegistrationCap, '', 0);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler,CloseIncomeStatementRequestPageHandler,MessageHandler,CreateFiscalYearRequestPageHandler,ConfirmHandler')]
    procedure AuditFileWithClosingGLEntries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        ClosingDate: Date;
        FileName: Text;
        StartDate: Date;
    begin
        // Verify description in generated Audit file when Audit file contains closing G/L entries.
        Initialize();

        // [GIVEN]
        LibraryVariableStorage.Enqueue(CloseFiscalYearQst);  // Enqueue for CreateFiscalYearRequestPageHandler.
        REPORT.Run(REPORT::"Create Fiscal Year"); // Create previous fiscal year.
        StartDate := LibraryFiscalYear.GetFirstPostingDate(true);
        CreateLedgerEntry(GenJournalBatch, StartDate);
        ClosingDate := CalcDate('<1Y - 1D>', StartDate);  // Getting last date of fiscal year, which is required for Close Income Statement.
        LibraryERM.CreateGLAccount(GLAccount);

        // [GIVEN] Enqueue values for CloseIncomeStatementRequestPageHandler.
        LibraryVariableStorage.Enqueue(GenJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(ClosingDate);
        LibraryVariableStorage.Enqueue(GenJournalBatch.Name);
        LibraryVariableStorage.Enqueue(GLAccount."No.");
        RunCloseIncomeStatement(GenJournalBatch);
        Commit();

        // [WHEN] Run Tax Authority - Audit File report.
        EnqueueValuesForRequestPage(ClosingDate, false);
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();

        // [THEN] Verify description in generated Audit file when Audit file contains closing G/L entries.
        VerifyTaxAuthorityAuditFile(FileName, DescriptionCap, 'Opening Entries', -1);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    procedure CompanyInformation()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        ShipToCountryRegion: Record "Country/Region";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        FileName: Text;
        CompanyXPath: Text;
        PostingDate: Date;
    begin
        // [SCENARIO 431143] Company information in Audit file version 3.2.
        Initialize();
        PostingDate := GetPostingDate();

        // [GIVEN] Company Information with VAT Registration No., Address, Ship-to Address.
        UpdateCompanyInformation();
        CompanyInfo.Get();
        CountryRegion.Get(CompanyInfo."Country/Region Code");
        ShipToCountryRegion.Get(CompanyInfo."Ship-to Country/Region Code");

        // [GIVEN] Posted Sales Order.
        CreateAndPostSalesOrder(PostingDate);

        // [WHEN] Run report "Tax Authority - Audit File"
        EnqueueValuesForRequestPage(PostingDate, true);
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();

        // [THEN] Company information is stored under "company" tag.
        LibraryXPathXMLReader.Initialize(FileName, XAFNameSpaceTxt);
        CompanyXPath := '//auditfile/company/';
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'companyIdent', CopyStr(CompanyName(), 1, 35));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'companyName', CompanyInfo.Name);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'taxRegistrationCountry', CountryRegion."ISO Code");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'taxRegIdent', CompanyInfo."VAT Registration No.");

        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'streetAddress/streetname', CompanyInfo."Ship-to Address");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'streetAddress/number', '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'streetAddress/numberExtension', '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'streetAddress/city', CompanyInfo."Ship-to City");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'streetAddress/postalCode', CopyStr(CompanyInfo."Ship-to Post Code", 1, 10));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'streetAddress/country', ShipToCountryRegion."ISO Code");

        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'postalAddress/streetname', CompanyInfo.Address);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'postalAddress/number', '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'postalAddress/numberExtension', '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'postalAddress/city', CompanyInfo.City);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'postalAddress/postalCode', CopyStr(CompanyInfo."Post Code", 1, 10));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CompanyXPath + 'postalAddress/country', CountryRegion."ISO Code");
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler,MessageHandlerOK')]
    procedure CustomerInformation()
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CountryRegion: Record "Country/Region";
        ShipToAddress: Record "Ship-to Address";
        CustomerBankAccount: Record "Customer Bank Account";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        PostingDate: Date;
        FileName: Text;
        CustVendXPath: Text;
    begin
        // [SCENARIO 431143] Customer information in Audit file version 3.2.
        Initialize();
        PostingDate := GetPostingDate();
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.DeleteAll();
        CustLedgerEntry.SetRange("Posting Date", PostingDate);
        CustLedgerEntry.DeleteAll();

        // [GIVEN] Customer "C1" with Address, two Ship-to Addresses and two Bank Accounts.
        // [GIVEN] Posted Sales Invoice for Customer "C1".
        LibrarySales.CreateCustomerWithAddress(Customer);
        UpdateCustomerInformation(Customer);

        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        UpdateCustomerBankAccount(CustomerBankAccount);

        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        UpdatePostingDateOnSalesHeader(SalesHeader, PostingDate);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        CountryRegion.Get(Customer."Country/Region Code");
        ShipToAddress.Get(Customer."No.", Customer."Ship-to Code");

        // [WHEN] Run report "Tax Authority - Audit File".
        EnqueueValuesForRequestPage(PostingDate, true);
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();

        // [THEN] Customer information is stored under "customerSupplier" tag.
        LibraryXPathXMLReader.Initialize(FileName, XAFNameSpaceTxt);
        CustVendXPath := '//company/customersSuppliers/customerSupplier/';
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'custSupID', '2' + Customer."No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'custSupName', Customer.Name);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'contact', Customer.Contact);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'telephone', Customer."Phone No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'fax', Customer."Fax No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'eMail', Customer."E-Mail");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'website', Customer."Home Page");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'taxRegistrationCountry', CountryRegion."ISO Code");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'taxRegIdent', Customer."VAT Registration No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'custSupTp', 'C'); // C - Customer
        LibraryXPathXMLReader.VerifyNodeValueByXPath(
            CustVendXPath + 'custCreditLimit', Format(Customer."Credit Limit (LCY)", 0, '<Precision,:2><Standard Format,9>'));

        // [THEN] Customer Shipping Addresses are stored under "customerSupplier/streetAddress" tag. Country tags with blank value are not added.
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'streetAddress/streetname', '', 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'streetAddress/number', '', 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'streetAddress/numberExtension', '', 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'streetAddress/city', '', 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'streetAddress/postalCode', '', 0);

        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'streetAddress/streetname', ShipToAddress.Address, 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'streetAddress/number', '', 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'streetAddress/numberExtension', '', 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'streetAddress/city', ShipToAddress.City, 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'streetAddress/postalCode', ShipToAddress."Post Code", 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(
            CustVendXPath + 'streetAddress/country', CopyStr(ShipToAddress."Country/Region Code", 1, 2), 0);
        LibraryXPathXMLReader.VerifyNodeCountByXPath(CustVendXPath + 'streetAddress/country', 1);

        // [THEN] Customer Address is stored under "customerSupplier/postalAddress" tag.
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/streetname', Customer.Address);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/number', '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/numberExtension', '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/city', Customer.City);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/postalCode', Customer."Post Code");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/country', CountryRegion."ISO Code");

        // [THEN] Customer Bank Account information is stored under "customerSupplier/bankAccount" tag.
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'bankAccount/bankAccNr', '', 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'bankAccount/bankIdCd', '', 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'bankAccount/bankAccNr', CustomerBankAccount."Bank Account No.", 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'bankAccount/bankIdCd', CustomerBankAccount."SWIFT Code", 1);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler,MessageHandlerOK')]
    procedure VendorInformation()
    var
        GLEntry: Record "G/L Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        CountryRegion: Record "Country/Region";
        VendorBankAccount: Record "Vendor Bank Account";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        PostingDate: Date;
        FileName: Text;
        CustVendXPath: Text;
    begin
        // [SCENARIO 431143] Vendor information in Audit file version 3.2.
        Initialize();
        PostingDate := GetPostingDate();
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.DeleteAll();
        VendorLedgerEntry.SetRange("Posting Date", PostingDate);
        VendorLedgerEntry.DeleteAll();

        // [GIVEN] Vendor "V1" with Address and two Bank Accounts.
        // [GIVEN] Posted Purchase Invoice for Vendor "V1".
        LibraryPurchase.CreateVendorWithAddress(Vendor);
        UpdateVendorInformation(Vendor);

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        UpdateVendorBankAccount(VendorBankAccount);

        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        UpdatePostingDateOnPurchaseHeader(PurchaseHeader, PostingDate);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        CountryRegion.Get(Vendor."Country/Region Code");

        // [WHEN] Run report "Tax Authority - Audit File".
        EnqueueValuesForRequestPage(PostingDate, true);
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();

        // [THEN] Vendor information is stored under "customerSupplier" tag.
        LibraryXPathXMLReader.Initialize(FileName, XAFNameSpaceTxt);
        CustVendXPath := '//company/customersSuppliers/customerSupplier/';
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'custSupID', '3' + Vendor."No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'custSupName', Vendor.Name);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'contact', Vendor.Contact);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'telephone', Vendor."Phone No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'fax', Vendor."Fax No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'eMail', Vendor."E-Mail");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'website', Vendor."Home Page");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'taxRegistrationCountry', CountryRegion."ISO Code");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'taxRegIdent', Vendor."VAT Registration No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'custSupTp', 'S'); // S - Supplier

        // [THEN] Vendor Address is stored under "customerSupplier/postalAddress" tag.
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/streetname', Vendor.Address);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/number', '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/numberExtension', '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/city', Vendor.City);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/postalCode', Vendor."Post Code");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/country', CountryRegion."ISO Code");

        // [THEN] Vendor Bank Account information is stored under "customerSupplier/bankAccount" tag.
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'bankAccount/bankAccNr', '', 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'bankAccount/bankIdCd', '', 0);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'bankAccount/bankAccNr', VendorBankAccount."Bank Account No.", 1);
        LibraryXPathXMLReader.VerifyNodeValueByXPathWithIndex(CustVendXPath + 'bankAccount/bankIdCd', VendorBankAccount."SWIFT Code", 1);
    end;

    [Test]
    [HandlerFunctions('TaxAuthorityAuditFileRequestPageHandler')]
    procedure BankAccountInformation()
    var
        GLEntry: Record "G/L Entry";
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        CountryRegion: Record "Country/Region";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
        PostingDate: Date;
        FileName: Text;
        CustVendXPath: Text;
    begin
        // [SCENARIO 431143] Vendor information in Audit file version 3.2.
        Initialize();
        PostingDate := GetPostingDate();
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.DeleteAll();

        // [GIVEN] Bank Account with Address, Bank Account No. and SWIFT.
        LibraryERM.CreateBankAccount(BankAccount);
        UpdateBankAccount(BankAccount);
        CountryRegion.Get(BankAccount."Country/Region Code");

        // [GIVEN] Posted General Journal Line with Account Type "Bank Account" and Bal. Account Type "G/L Account".
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
            "Gen. Journal Account Type"::"Bank Account", BankAccount."No.",
            "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(100, 200, 2));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report "Tax Authority - Audit File".
        EnqueueValuesForRequestPage(PostingDate, true);
        FileName := FileManagement.ServerTempFileName('xaf');
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();

        // [THEN] Bank Account information is stored under "customerSupplier" tag.
        LibraryXPathXMLReader.Initialize(FileName, XAFNameSpaceTxt);
        CustVendXPath := '//company/customersSuppliers/customerSupplier/';
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'custSupID', '4' + BankAccount."No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'custSupName', CopyStr(BankAccount.Name, 1, 50));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'contact', CopyStr(BankAccount.Contact, 1, 50));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'telephone', BankAccount."Phone No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'fax', BankAccount."Fax No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'eMail', BankAccount."E-Mail");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'website', BankAccount."Home Page");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'custSupTp', 'O'); // O - Other

        // [THEN] Bank Account Address is stored under "customerSupplier/postalAddress" tag.
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/streetname', BankAccount.Address);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/number', '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/numberExtension', '');
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/city', BankAccount.City);
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/postalCode', CopyStr(BankAccount."Post Code", 1, 10));
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'postalAddress/country', CountryRegion."ISO Code");

        // [THEN] Bank Account Number and SWIFT are stored under "customerSupplier/bankAccount" tag.
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'bankAccount/bankAccNr', BankAccount."Bank Account No.");
        LibraryXPathXMLReader.VerifyNodeValueByXPath(CustVendXPath + 'bankAccount/bankIdCd', BankAccount."SWIFT Code");
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Tax Authority");
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Tax Authority");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Tax Authority");
    end;

    local procedure GetPostingDate(): Date
    var
        Math: Codeunit Math;
        DaysFromNY: Integer;
        CurrentYear: Integer;
        RandMaxDelta: Integer;
    begin
        // the logic in this method prevent the test from failing in the first days of the year
        Evaluate(CurrentYear, Format(Today(), 0, '<Year4>'));  // DATE2DWY works bad for the very beginning/end of a year
        DaysFromNY := Today() - DMY2Date(1, 1, CurrentYear);
        RandMaxDelta := Math.Min(DaysFromNY, 10);
        exit(LibraryRandom.RandDateFrom(Today(), -RandMaxDelta));
    end;

    local procedure CreateAndPostPurchaseOrder(PostingDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: Record "Dimension Value";
        VendorNo: Code[20];
        ItemNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, "Tax Calculation Type"::"Normal VAT", LibraryRandom.RandDecInDecimalRange(10, 20, 3));
        VendorNo := CreateVendor();
        UpdateVATBusPostingGroupOnVendor(VendorNo, VATPostingSetup."VAT Bus. Posting Group");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        UpdatePostingDateOnPurchaseHeader(PurchaseHeader, PostingDate);
        LibraryDimension.FindDimensionValue(DimensionValue, LibraryERM.GetShortcutDimensionCode(1));
        PurchaseHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.FindDimensionValue(DimensionValue, LibraryERM.GetShortcutDimensionCode(2));
        PurchaseHeader.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        PurchaseHeader.Modify(true);

        ItemNo := CreateItem();
        UpdateVATProdPostingGroupOnItem(ItemNo, VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesOrder(PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DimensionValue: Record "Dimension Value";
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            VATPostingSetup, "Tax Calculation Type"::"Normal VAT", LibraryRandom.RandDecInDecimalRange(10, 20, 3));
        CustomerNo := CreateCustomer();
        UpdateVATBusPostingGroupOnCustomer(CustomerNo, VATPostingSetup."VAT Bus. Posting Group");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        UpdatePostingDateOnSalesHeader(SalesHeader, PostingDate);
        LibraryDimension.FindDimensionValue(DimensionValue, LibraryERM.GetShortcutDimensionCode(1));
        SalesHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.FindDimensionValue(DimensionValue, LibraryERM.GetShortcutDimensionCode(2));
        SalesHeader.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        SalesHeader.Modify(true);

        ItemNo := CreateItem();
        UpdateVATProdPostingGroupOnItem(ItemNo, VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateLedgerEntryAndRunReport(FileName: Text; ExcludeBalance: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TaxAuthorityAuditFile: Report "Tax Authority - Audit File";
    begin
        CreateLedgerEntry(GenJournalBatch, CalcDate('<-1D>', GetPostingDate())); // necessary to create Balance at Date
        CreateLedgerEntry(GenJournalBatch, GetPostingDate());
        EnqueueValuesForRequestPage(GetPostingDate(), ExcludeBalance);  // Enqueue values for TaxAuthorityAuditFileRequestPageHandler.

        // Exercise.
        TaxAuthorityAuditFile.SetFileName(FileName);
        TaxAuthorityAuditFile.Run();
    end;

    local procedure RunCloseIncomeStatement(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Enqueue(SuccessfullyCreatedMsg);  // Enqueue for MessageHandler.
        Commit();  // COMMIT required.
        REPORT.Run(REPORT::"Close Income Statement");

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.")
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer."No." := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Customer."No.")), 1, MaxStrLen(Customer."No."));
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using Random for Unit Price.
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));  // Using Random for Unit Cost.
        Item.Modify(true);
        exit(Item."No.")
    end;

    local procedure CreateLedgerEntry(var GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date) DocumentNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SelectAndClearGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Bank Account", CreateBankAccount(), LibraryRandom.RandDec(1000, 2));  // Using Random for Amount.
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
        DocumentNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor."No.")), 1, MaxStrLen(Vendor."No."));
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure EnqueueValuesForRequestPage(StartEndDate: Variant; ExcludeBalance: Variant)
    begin
        LibraryVariableStorage.Enqueue(StartEndDate);
        LibraryVariableStorage.Enqueue(ExcludeBalance);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; Reversed: Boolean)
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange(Reversed, Reversed);
        GLEntry.FindFirst();
    end;

    local procedure GetGLEntryAmount(DocumentNo: Code[20]; Condition: Text[3]) Amount: Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter(Amount, Condition, 0);
        GLEntry.FindSet();
        repeat
            Amount += GLEntry.Amount;
        until GLEntry.Next() = 0;
    end;

    local procedure ReverseTransaction(TransactionNo: Integer)
    var
        ReversalEntry: Record "Reversal Entry";
    begin
        LibraryVariableStorage.Enqueue(SuccessfullyReversedMsg);  // Enqueue for MessageHandler.
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(TransactionNo);
        Commit();  // COMMIT required.
    end;

    local procedure SelectAndClearGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInfo: Record "Company Information";
        CountryRegion: Record "Country/Region";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("ISO Code", CopyStr(CountryRegion.Code, 1, MaxStrLen(CountryRegion."ISO Code")));
        CountryRegion.Modify(true);

        CompanyInfo.Get();
        CompanyInfo.Validate(Name, LibraryUtility.GenerateGUID());
        CompanyInfo.Validate("Ship-to Address", LibraryUtility.GenerateGUID());
        CompanyInfo.Validate("Ship-to City", LibraryUtility.GenerateGUID());
        CompanyInfo.Validate("Ship-to Post Code", LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID());
        CompanyInfo.Validate("Ship-to Country/Region Code", CountryRegion.Code);

        CompanyInfo.Validate(Address, LibraryUtility.GenerateGUID());
        CompanyInfo.Validate(City, LibraryUtility.GenerateGUID());
        CompanyInfo.Validate("Post Code", LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID());
        CompanyInfo.Validate("Country/Region Code", 'NL');

        CompanyInfo.Modify(true);

        LibraryERMCountryData.CompanyInfoSetVATRegistrationNo();
    end;

    local procedure UpdateLCYCodeGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := '';        // to avoid error on updating LCY Code
        GeneralLedgerSetup.Validate("LCY Code", LibraryUtility.GenerateGUID());
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePostingDateOnSalesHeader(var SalesHeader: Record "Sales Header"; NewPostingDate: Date)
    begin
        SalesHeader.Validate("Posting Date", NewPostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure UpdatePostingDateOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; NewPostingDate: Date)
    begin
        PurchaseHeader.Validate("Posting Date", NewPostingDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateCustomerInformation(var Customer: Record Customer)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        ShipToAddress: Record "Ship-to Address";
        CountryRegion: Record "Country/Region";
        ContactNo: Code[20];
    begin
        ContactNo := LibraryMarketing.CreateCompanyContactNo();
        LibraryMarketing.CreateBusinessRelationBetweenContactAndCustomer(ContactBusinessRelation, ContactNo, Customer."No.");
        Customer.Validate(Contact, ContactNo);

        LibraryERM.CreateCountryRegion(CountryRegion);
        CountryRegion.Validate("ISO Code", CopyStr(CountryRegion.Code, 1, MaxStrLen(CountryRegion."ISO Code")));
        CountryRegion.Modify(true);

        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Validate(Address, LibraryUtility.GenerateGUID());
        ShipToAddress.Validate(City, LibraryUtility.GenerateGUID());
        ShipToAddress.Validate("Post Code", LibraryUtility.GenerateGUID());
        ShipToAddress.Validate("Country/Region Code", CountryRegion.Code);
        ShipToAddress.Modify(true);
        Customer.Validate("Ship-to Code", ShipToAddress.Code);

        Customer.Validate(Name, LibraryUtility.GenerateGUID());
        Customer.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        Customer.Validate("Fax No.", LibraryUtility.GenerateRandomPhoneNo());
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Validate("Home Page", LibraryUtility.GenerateGUID());
        Customer.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Customer."Country/Region Code"));
        Customer.Validate("Credit Limit (LCY)", LibraryRandom.RandDecInDecimalRange(100, 200, 3));
        Customer.Modify(true);
    end;

    local procedure UpdateVendorInformation(var Vendor: Record Vendor)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactNo: Code[20];
    begin
        ContactNo := LibraryMarketing.CreateCompanyContactNo();
        LibraryMarketing.CreateBusinessRelationBetweenContactAndVendor(ContactBusinessRelation, ContactNo, Vendor."No.");
        Vendor.Validate(Contact, ContactNo);

        Vendor.Validate(Name, LibraryUtility.GenerateGUID());
        Vendor.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        Vendor.Validate("Fax No.", LibraryUtility.GenerateRandomPhoneNo());
        Vendor.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Vendor.Validate("Home Page", LibraryUtility.GenerateGUID());
        Vendor.Validate("VAT Registration No.", LibraryERM.GenerateVATRegistrationNo(Vendor."Country/Region Code"));
        Vendor.Modify(true);
    end;

    local procedure UpdateCustomerBankAccount(var CustomerBankAccount: Record "Customer Bank Account")
    begin
        CustomerBankAccount.Validate("Bank Account No.", LibraryUtility.GenerateGUID());
        CustomerBankAccount.Validate("SWIFT Code", LibraryUtility.GenerateGUID());
        CustomerBankAccount.Modify(true);
    end;

    local procedure UpdateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account")
    begin
        VendorBankAccount.Validate("Bank Account No.", LibraryUtility.GenerateGUID());
        VendorBankAccount.Validate("SWIFT Code", LibraryUtility.GenerateGUID());
        VendorBankAccount.Modify(true);
    end;

    local procedure UpdateBankAccount(var BankAccount: Record "Bank Account")
    begin
        BankAccount.Validate(
            Name, CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(BankAccount.Name)), 1, MaxStrLen(BankAccount.Name)));
        BankAccount.Validate(
            Contact, CopyStr(LibraryUtility.GenerateRandomXMLText(MaxStrLen(BankAccount.Contact)), 1, MaxStrLen(BankAccount.Contact)));
        BankAccount.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        BankAccount.Validate("Fax No.", LibraryUtility.GenerateRandomPhoneNo());
        BankAccount.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        BankAccount.Validate("Home Page", LibraryUtility.GenerateGUID());

        BankAccount.Validate(Address, LibraryUtility.GenerateGUID());
        BankAccount.Validate(City, LibraryUtility.GenerateGUID());
        BankAccount.Validate("Post Code", LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID());
        BankAccount.Validate("Country/Region Code", 'NL');

        BankAccount.Validate("Bank Account No.", LibraryUtility.GenerateGUID());
        BankAccount.Validate("SWIFT Code", LibraryUtility.GenerateGUID());
        BankAccount.Modify(true);
    end;

    local procedure UpdateVATBusPostingGroupOnCustomer(CustomerNo: Code[20]; NewVATBusPostingGroup: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("VAT Bus. Posting Group", NewVATBusPostingGroup);
        Customer.Modify(true);
    end;

    local procedure UpdateVATBusPostingGroupOnVendor(VendorNo: Code[20]; NewVATBusPostingGroup: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("VAT Bus. Posting Group", NewVATBusPostingGroup);
        Vendor.Modify(true);
    end;

    local procedure UpdateVATProdPostingGroupOnItem(ItemNo: Code[10]; NewVATProdPostingGroup: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("VAT Prod. Posting Group", NewVATProdPostingGroup);
        Item.Modify(true);
    end;

    local procedure VerifyTaxAuthorityAuditFile(FileName: Text; ElementCap: Text[30]; Value: Text[100]; IndexNo: Integer)
    var
        [RunOnClient]
        NodeList: DotNet XmlNodeList;
        [RunOnClient]
        Node: DotNet XmlNode;
    begin
        // If IndexNo is set to a negative value, this function will search for a XML node with the value defined in the Value parameter.
        LibraryXMLRead.Initialize(FileName);
        LibraryXMLRead.GetNodeListByElementName(ElementCap, NodeList);
        if IndexNo >= 0 then begin
            Node := NodeList.Item(IndexNo);
            Assert.AreEqual(Value, Node.InnerText, ElementCap);
        end else begin
            for IndexNo := 0 to NodeList.Count - 1 do begin
                Node := NodeList.Item(IndexNo);
                if Node.InnerText = Value then
                    exit;
            end;
            Assert.Fail(StrSubstNo(NodeNotFoundMsg, Value));
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        Message: Variant;
    begin
        LibraryVariableStorage.Dequeue(Message);
        Assert.AreNotEqual(StrPos(Question, Message), 0, UnexpectedMsg);
        Reply := true;
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
    var
        ActualMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ActualMessage);
        Assert.AreEqual(Message, Format(ActualMessage), UnexpectedMsg);
    end;

    [MessageHandler]
    procedure MessageHandlerOK(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateFiscalYearRequestPageHandler(var CreateFiscalYear: TestRequestPage "Create Fiscal Year")
    begin
        CreateFiscalYear.StartingDate.SetValue(CalcDate('<-1Y>', LibraryFiscalYear.GetFirstPostingDate(true)));  // Required prevoius year Start Date.
        CreateFiscalYear.NoOfPeriods.SetValue(12);
        CreateFiscalYear.PeriodLength.SetValue('<1M>');
        CreateFiscalYear.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CloseIncomeStatementRequestPageHandler(var CloseIncomeStatement: TestRequestPage "Close Income Statement")
    var
        GenJournalTemplate: Variant;
        GenJournalBatch: Variant;
        FiscalYearEndingDate: Variant;
        RetainedEarningsAcc: Variant;
    begin
        LibraryVariableStorage.Dequeue(GenJournalTemplate);
        LibraryVariableStorage.Dequeue(FiscalYearEndingDate);
        LibraryVariableStorage.Dequeue(GenJournalBatch);
        LibraryVariableStorage.Dequeue(RetainedEarningsAcc);
        CloseIncomeStatement.GenJournalTemplate.SetValue(GenJournalTemplate);
        CloseIncomeStatement.FiscalYearEndingDate.SetValue(FiscalYearEndingDate);
        CloseIncomeStatement.GenJournalBatch.SetValue(GenJournalBatch);
        CloseIncomeStatement.RetainedEarningsAcc.SetValue(RetainedEarningsAcc);
        CloseIncomeStatement.PostingDescription.SetValue('Opening Entries');  // Used hard coded value as needed for verification in Audit File.
        CloseIncomeStatement.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TaxAuthorityAuditFileRequestPageHandler(var TaxAuthorityAuditFile: TestRequestPage "Tax Authority - Audit File")
    var
        StartEndDate: Variant;
        ExcludeBalance: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartEndDate);
        LibraryVariableStorage.Dequeue(ExcludeBalance);
        TaxAuthorityAuditFile.StartDate.SetValue(StartEndDate);
        TaxAuthorityAuditFile.EndDate.SetValue(StartEndDate);
        TaxAuthorityAuditFile.ExcludeBalance.SetValue(ExcludeBalance);
        TaxAuthorityAuditFile.OK().Invoke();
    end;
}
