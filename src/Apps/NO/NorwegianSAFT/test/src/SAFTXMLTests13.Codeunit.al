codeunit 148110 "SAF-T XML Tests 1.3"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SAF-T] [XML]
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryJournals: Codeunit "Library - Journals";
        SAFTTestHelper: Codeunit "SAF-T Test Helper";
        Assert: Codeunit Assert;
        SAFTMappingType: Enum "SAF-T Mapping Type";
        IsInitialized: Boolean;
        GenerateSAFTFileImmediatelyQst: Label 'Since you did not schedule the SAF-T file generation, it will be generated immediately which can take a while. Do you want to continue?';

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure MasterFile()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        TempXMLBuffer: Record "XML Buffer" temporary;
        NumberOfMasterDataRecords: Integer;
    begin
        // [SCENARIO 309923] The first XML file generates by SAF-T Export functionality has master data

        Initialize();
        NumberOfMasterDataRecords := LibraryRandom.RandIntInRange(3, 5);
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", NumberOfMasterDataRecords);
        SAFTTestHelper.PostRandomAmountForNumberOfMasterDataRecords(SAFTMappingRange."Ending Date", NumberOfMasterDataRecords);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Completed);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        Assert.RecordCount(SAFTExportLine, 2);
        SAFTExportLine.TestField("Master Data", true);
        SAFTExportHeader.Find();
        SAFTExportHeader.TestField(Status, SAFTExportHeader.Status::Completed);
        SAFTExportHeader.TestField("Execution Start Date/Time");
        SAFTExportHeader.TestField("Execution End Date/Time");

        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyHeaderStructure(TempXMLBuffer, SAFTExportLine);
        // TFS 348392: All G/L accounts are exports
        // TFS 349472: Both Company Information's bank account and all records from Bank Acount table exports
        // TFS 349472: All customer and vendor bank accounts exports
        // TFS 350284: All xnl nodes predefined with 'n1:'
        // TFS 350284: Both sales and purchase VAT Entry information exports 
        // TFS 372962: Customer and vendor with zero balance should be presented
        // TFS 425270: Xml nodes values are encoded. The value '<&' must be exported as '&amp;lt;&amp;amp;'
        // TFS 427679: Export all bank account data
        // TFS 453255: Export bank account data depends on IBAN
        // TFS 485839: VAT Registration No. field of the Company Information exports to the Registratuin Number xml node
        VerifyMasterDataStructureWithStdAccMapping(TempXMLBuffer, SAFTExportHeader."Mapping Range Code", NumberOfMasterDataRecords);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure OpeningDebitBalanceOnMasterData()
    var
        GLAccount: Record "G/L Account";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        TempXMLBuffer: Record "XML Buffer" temporary;
        BalanceAmount: Decimal;
        ClosingAmount: Decimal;
    begin
        // [SCENARIO 309923] The master data information in the first XML file has OpeningDebitBalance

        Initialize();
        SetupSAFTSingleAcc(
            SAFTMappingRange, SAFTMappingType::"Income Statement", GLAccount."Income/Balance"::"Balance Sheet");
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        BalanceAmount := LibraryRandom.RandDec(100, 2);
        ClosingAmount := LibraryRandom.RandDec(100, 2);
        SAFTTestHelper.MockEntriesForFirstRecordOfMasterData(
            GLAccount."Income/Balance"::"Balance Sheet", SAFTExportHeader."Starting Date" - 1,
            BalanceAmount, BalanceAmount, -BalanceAmount);
        SAFTTestHelper.MockEntriesForFirstRecordOfMasterData(
            GLAccount."Income/Balance"::"Balance Sheet", SAFTExportHeader."Starting Date",
            ClosingAmount, ClosingAmount, ClosingAmount);
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyMasterDataBalance(TempXMLBuffer, 'OpeningDebitBalance', BalanceAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure OpeningCreditBalanceOnMasterData()
    var
        GLAccount: Record "G/L Account";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        TempXMLBuffer: Record "XML Buffer" temporary;
        BalanceAmount: Decimal;
        ClosingAmount: Decimal;
    begin
        // [SCENARIO 309923] The master data information in the first XML file has OpeningCreditBalance

        Initialize();
        SetupSAFTSingleAcc(
            SAFTMappingRange, SAFTMappingType::"Income Statement", GLAccount."Income/Balance"::"Balance Sheet");
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        BalanceAmount := LibraryRandom.RandDec(100, 2);
        ClosingAmount := LibraryRandom.RandDec(100, 2);
        SAFTTestHelper.MockEntriesForFirstRecordOfMasterData(
            GLAccount."Income/Balance"::"Balance Sheet", SAFTExportHeader."Starting Date" - 1,
            -BalanceAmount, -BalanceAmount, BalanceAmount);
        SAFTTestHelper.MockEntriesForFirstRecordOfMasterData(
            GLAccount."Income/Balance"::"Balance Sheet", SAFTExportHeader."Starting Date",
            ClosingAmount, ClosingAmount, ClosingAmount);
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyMasterDataBalance(TempXMLBuffer, 'OpeningCreditBalance', BalanceAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ClosingDebitBalanceOnMasterData()
    var
        GLAccount: Record "G/L Account";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        TempXMLBuffer: Record "XML Buffer" temporary;
        BalanceAmount: Decimal;
    begin
        // [SCENARIO 309923] The master data information in the first XML file has ClosingDebitBalance

        Initialize();
        SetupSAFTSingleAcc(
            SAFTMappingRange, SAFTMappingType::"Income Statement", GLAccount."Income/Balance"::"Balance Sheet");
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        BalanceAmount := LibraryRandom.RandDec(100, 2);
        SAFTTestHelper.MockEntriesForFirstRecordOfMasterData(
            GLAccount."Income/Balance"::"Balance Sheet", SAFTExportHeader."Ending Date",
            BalanceAmount, BalanceAmount, -BalanceAmount);
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyMasterDataBalance(TempXMLBuffer, 'ClosingDebitBalance', BalanceAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ClosingCreditBalanceOnMasterData()
    var
        GLAccount: Record "G/L Account";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        TempXMLBuffer: Record "XML Buffer" temporary;
        BalanceAmount: Decimal;
    begin
        // [SCENARIO 309923] The master data information in the first XML file has ClosingCreditBalance

        Initialize();
        SetupSAFTSingleAcc(
            SAFTMappingRange, SAFTMappingType::"Income Statement", GLAccount."Income/Balance"::"Balance Sheet");
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        BalanceAmount := LibraryRandom.RandDec(100, 2);
        SAFTTestHelper.MockEntriesForFirstRecordOfMasterData(
            GLAccount."Income/Balance"::"Balance Sheet", SAFTExportHeader."Ending Date",
            -BalanceAmount, -BalanceAmount, BalanceAmount);
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyMasterDataBalance(TempXMLBuffer, 'ClosingCreditBalance', BalanceAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure GeneralLedgerEntryFile()
    var
        GLAccount: Record "G/L Account";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempSAFTSourceCode: Record "SAF-T Source Code" temporary;
        SAFTSourceCode: Record "SAF-T Source Code";
        SourceCode: Record "Source Code";
        VATEntry: Record "VAT Entry";
        SAFTAnalysisType: Code[9];
        DimValueCode: Code[20];
        DimSetID: Integer;
        JournalsNumber: Integer;
        EntriesInTransactionNumber: Integer;
        TransactionNo: Integer;
        i: Integer;
        j: Integer;
        EntryType: Integer;
        DocNo: Code[20];
    begin
        // [SCENARIO 309923] The structure of the XML file with General Ledger Entries is correct
        // [SCENARIO 331600] "NumberOfEntries" contains the number of transactions
        // [SCENARIO 334997] "ReferenceNumber" xml node exports after "TaxInformation" section
        // [SCENARIO 495176] "TransactionID" xml node contains the concatenated value of the "Posting Date" and "Document No." fields of the G/L Entry

        Initialize();
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", LibraryRandom.RandInt(5));
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        EntriesInTransactionNumber := LibraryRandom.RandIntInRange(3, 5);
        JournalsNumber := LibraryRandom.RandInt(5);
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindFirst();
        SAFTTestHelper.SetDimensionForGLAccount(GLAccount."No.", SAFTAnalysisType, DimValueCode, DimSetID);
        SAFTSourceCode.FindSet();
        TransactionNo := GetLastUsedTransactionNo();
        for i := 1 to JournalsNumber do begin
            SourceCode.SetRange("SAF-T Source Code", SAFTSourceCode.Code);
            SourceCode.FindFirst();
            DocNo := LibraryUtility.GenerateGUID();
            for j := 1 to EntriesInTransactionNumber do
                for EntryType := VATEntry.Type::Purchase to VATEntry.Type::Sale do begin
                    SAFTTestHelper.MockVATEntry(VATEntry, SAFTExportHeader."Ending Date", DocNo, EntryType, TransactionNo + i);
                    SAFTTestHelper.MockGLEntryVATEntryLink(
                        SAFTTestHelper.MockGLEntry(
                            SAFTExportHeader."Ending Date", VATEntry."Document No.", GLAccount."No.",
                            VATEntry."Transaction No.", DimSetID, VATEntry."VAT Bus. Posting Group",
                            VATEntry."VAT Prod. Posting Group", 0, '', SourceCode.Code, LibraryRandom.RandDec(100, 2), 0),
                        VATEntry."Entry No.");
                end;
            TempSAFTSourceCode := SAFTSourceCode;
            TempSAFTSourceCode.Insert();
            SAFTSourceCode.Next();
        end;
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Completed);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        Assert.RecordCount(SAFTExportLine, 2);
        SAFTExportLine.Next();
        SAFTExportLine.TestField("Master Data", false);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyXMLFileHasHeader(TempXMLBuffer);
        VerifyGLEntriesGroupedBySAFTSourceCode(
            TempXMLBuffer, TempSAFTSourceCode, EntriesInTransactionNumber * 2, SAFTExportLine."Starting Date", SAFTExportLine."Ending Date",
            SAFTAnalysisType, DimValueCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CustomerIDExportsOncePerLine()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempResultElementXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
        TransactionNo: Integer;
        DocNo: Code[20];
    begin
        // [SCENARIO 331600] "CustomerID" xml node exports only once per document

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", LibraryRandom.RandInt(5));
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Customer with posting group where "Receivables Account" = "X"
        Customer.FindFirst();
        CustomerPostingGroup.Get(Customer."Customer Posting Group");

        // [GIVEN] G/L account "Y"
        GLAccount.SetFilter("No.", '<>%1', CustomerPostingGroup."Receivables Account");
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] Two G/L Entries with accounts "X" and "Y"
        TransactionNo := GetLastUsedTransactionNo() + 1;
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocNo, CustomerPostingGroup."Receivables Account",
            TransactionNo, 0, 0, '',
            '', GLEntry."Source Type"::Customer, Customer."No.", '', LibraryRandom.RandDec(100, 2), 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
            TransactionNo, 0, 0, '',
            '', GLEntry."Source Type"::Customer, Customer."No.", '', LibraryRandom.RandDec(100, 2), 0);

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] CustomerID xml node exists only for the first G/L entry
        // TFS ID 389407: CustomerID exports for G/L Entry where G/L account is Receivables Account
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer,
                '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line'),
                'No G/L entries with CustomerID exported.');
        Assert.RecordCount(TempXMLBuffer, 2);

        SAFTTestHelper.FilterChildElementsByName(TempResultElementXMLBuffer, TempXMLBuffer, 'CustomerID');
        Assert.RecordIsNotEmpty(TempResultElementXMLBuffer);

        SAFTTestHelper.FindNextElement(TempXMLBuffer);
        SAFTTestHelper.FilterChildElementsByName(TempResultElementXMLBuffer, TempXMLBuffer, 'CustomerID');
        Assert.RecordIsEmpty(TempResultElementXMLBuffer);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SupplierIDExportsOncePerLine()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempResultElementXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        GLEntry: Record "G/L Entry";
        TransactionNo: Integer;
        DocNo: Code[20];
    begin
        // [SCENARIO 331600] "SupplierID" xml node exports only once per document

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", LibraryRandom.RandInt(5));
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Customer with posting group where "Receivables Account" = "X"
        Vendor.FindFirst();
        VendorPostingGroup.GET(Vendor."Vendor Posting Group");

        // [GIVEN] G/L account "Y"
        GLAccount.SETFILTER("No.", '<>%1', VendorPostingGroup."Payables Account");
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] Two G/L Entries with accounts "X" and "Y"
        TransactionNo := GetLastUsedTransactionNo() + 1;
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocNo, VendorPostingGroup."Payables Account",
            TransactionNo, 0, 0, '',
            '', GLEntry."Source Type"::Vendor, Vendor."No.", '', LibraryRandom.RandDec(100, 2), 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
            TransactionNo, 0, 0, '',
            '', GLEntry."Source Type"::Vendor, Vendor."No.", '', LibraryRandom.RandDec(100, 2), 0);

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] SupplierID xml node exists only for the first G/L entry
        // TFS ID 389407: SupplierID exports for G/L Entry where G/L account is Payables Account
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer,
                '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line'),
                'No G/L entries with CustomerID exported.');
        Assert.RecordCount(TempXMLBuffer, 2);

        SAFTTestHelper.FilterChildElementsByName(TempResultElementXMLBuffer, TempXMLBuffer, 'SupplierID');
        Assert.RecordIsNotEmpty(TempResultElementXMLBuffer);

        SAFTTestHelper.FindNextElement(TempXMLBuffer);
        SAFTTestHelper.FilterChildElementsByName(TempResultElementXMLBuffer, TempXMLBuffer, 'SupplierID');
        Assert.RecordIsEmpty(TempResultElementXMLBuffer);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure GLAccountExportWithIncomeStatementMappingType()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        TempXMLBuffer: Record "XML Buffer" temporary;
        NumberOfMasterDataRecords: Integer;
    begin
        // [SCENARIO 352458] The xml file of master data contains G/L account with income statement mapping if "Mapping Type" is "Income Statement"  

        Initialize();
        NumberOfMasterDataRecords := LibraryRandom.RandIntInRange(3, 5);
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", NumberOfMasterDataRecords);
        SAFTTestHelper.PostRandomAmountForNumberOfMasterDataRecords(SAFTMappingRange."Ending Date", NumberOfMasterDataRecords);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);

        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyGeneralLedgerAccountsWithIncomeStatementMapping(TempXMLBuffer, SAFTExportHeader."Mapping Range Code");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure GroupingCategoryExportsExtendedValueInXML()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTMappingCategory: Record "SAF-T Mapping Category";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        TempXMLBuffer: Record "XML Buffer" temporary;
        NumberOfMasterDataRecords: Integer;
        ExtendedCategoryValue: Text[500];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] When SAF-T Mapping Category has Extended No., the exported XML GroupingCategory node contains the extended value
        Initialize();

        // [GIVEN] SAF-T setup with Income Statement mapping and GL accounts mapped
        NumberOfMasterDataRecords := 1;
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", NumberOfMasterDataRecords);
        SAFTTestHelper.PostRandomAmountForNumberOfMasterDataRecords(SAFTMappingRange."Ending Date", NumberOfMasterDataRecords);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);

        // [GIVEN] SAF-T Mapping Category "C" has Extended No. = "X"
        ExtendedCategoryValue := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(500, 0), 1, 500);
        SAFTGLAccountMapping.SetRange("Mapping Range Code", SAFTMappingRange.Code);
        SAFTGLAccountMapping.SetFilter("Category No.", '<>%1', '');
        SAFTGLAccountMapping.FindFirst();
        SAFTMappingCategory.Get(SAFTGLAccountMapping."Mapping Type", SAFTGLAccountMapping."Category No.");
        SAFTMappingCategory."Extended No." := ExtendedCategoryValue;
        SAFTMappingCategory.Modify();

        // [WHEN] SAF-T export is run
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);

        // [THEN] Exported XML GroupingCategory node contains the extended value "X"
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyGroupingCategoryValue(TempXMLBuffer, SAFTMappingRange.Code);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure GroupingCodeExportsExtendedValueInXML()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTMapping: Record "SAF-T Mapping";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        TempXMLBuffer: Record "XML Buffer" temporary;
        NumberOfMasterDataRecords: Integer;
        ExtendedCodeValue: Text[500];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] When SAF-T Mapping has Extended No., the exported XML GroupingCode node contains the extended value
        Initialize();

        // [GIVEN] SAF-T setup with Income Statement mapping and GL accounts mapped
        NumberOfMasterDataRecords := 1;
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", NumberOfMasterDataRecords);
        SAFTTestHelper.PostRandomAmountForNumberOfMasterDataRecords(SAFTMappingRange."Ending Date", NumberOfMasterDataRecords);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);

        // [GIVEN] SAF-T Mapping "M" has Extended No. = "X"
        ExtendedCodeValue := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(500, 0), 1, 500);
        SAFTGLAccountMapping.SetRange("Mapping Range Code", SAFTMappingRange.Code);
        SAFTGLAccountMapping.SetFilter("No.", '<>%1', '');
        SAFTGLAccountMapping.FindFirst();
        SAFTMapping.Get(SAFTGLAccountMapping."Mapping Type", SAFTGLAccountMapping."Category No.", SAFTGLAccountMapping."No.");
        SAFTMapping."Extended No." := ExtendedCodeValue;
        SAFTMapping.Modify();

        // [WHEN] SAF-T export is run
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);

        // [THEN] Exported XML GroupingCode node contains the extended value "X"
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyGroupingCodeValue(TempXMLBuffer, SAFTMappingRange.Code, SAFTGLAccountMapping."G/L Account No.", ExtendedCodeValue);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure GroupingCodeExportsShortValueWhenNoExtendedNo()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTMapping: Record "SAF-T Mapping";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        TempXMLBuffer: Record "XML Buffer" temporary;
        NumberOfMasterDataRecords: Integer;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] When SAF-T Mapping has blank Extended No., the exported XML GroupingCode node contains the No. value
        Initialize();

        // [GIVEN] SAF-T setup with Income Statement mapping and GL accounts mapped
        NumberOfMasterDataRecords := 1;
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", NumberOfMasterDataRecords);
        SAFTTestHelper.PostRandomAmountForNumberOfMasterDataRecords(SAFTMappingRange."Ending Date", NumberOfMasterDataRecords);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);

        // [GIVEN] SAF-T Mapping "M" has blank Extended No.
        SAFTGLAccountMapping.SetRange("Mapping Range Code", SAFTMappingRange.Code);
        SAFTGLAccountMapping.SetFilter("No.", '<>%1', '');
        SAFTGLAccountMapping.FindFirst();
        SAFTMapping.Get(SAFTGLAccountMapping."Mapping Type", SAFTGLAccountMapping."Category No.", SAFTGLAccountMapping."No.");
        SAFTMapping."Extended No." := '';
        SAFTMapping.Modify();

        // [WHEN] SAF-T export is run
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);

        // [THEN] Exported XML GroupingCode node contains the No. value (not extended)
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyGroupingCodeValue(TempXMLBuffer, SAFTMappingRange.Code, SAFTGLAccountMapping."G/L Account No.", SAFTGLAccountMapping."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure GLEntryVATEntryLink()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        Vendor: Record Customer;
        GLEntry: Record "G/L Entry";
        VATEntry: array[2] of Record "VAT Entry";
        TransactionNo: Integer;
        DocNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [VAT]
        // [SCENARIO 359996] Each G/L Entry under the "Line" xml node has the correct VAT Entry under the "TaxInformation" node 

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", LibraryRandom.RandInt(5));
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindFirst();
        Vendor.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] Two G/L Entries with the same document/transaction, each related to its own VAT Entry
        // [GIVEN] VAT Entry 1: Base = 100, Amount = 21
        // [GIVEN] VAT Entry 2. Base = 200, Amount = 36
        TransactionNo := GetLastUsedTransactionNo() + 1;
        SAFTTestHelper.MockVATEntry(VATEntry[2], SAFTExportHeader."Ending Date", VATEntry[1].Type::Purchase, TransactionNo);
        for i := 1 to ArrayLen(VATEntry) do begin
            SAFTTestHelper.MockVATEntry(VATEntry[i], SAFTExportHeader."Ending Date", VATEntry[i].Type::Purchase, TransactionNo);
            SAFTTestHelper.MockGLEntryVATEntryLink(
                SAFTTestHelper.MockGLEntry(
                    SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                    TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, VATEntry[i]."VAT Bus. Posting Group",
                    VATEntry[i]."VAT Prod. Posting Group", GLEntry."Source Type"::Vendor, Vendor."No.", '', LibraryRandom.RandDec(100, 2), 0),
                VATEntry[i]."Entry No.");
        end;

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] The following nodes have exported:
        // [THEN] n1:Line/n1:TaxInformation/n1:TaxBase. Value: 100
        // [THEN] n1:Line/n1:TaxInformation/n1:TaxAmount/n1:Amount. Value: 21
        // [THEN] n1:Line/n1:TaxInformation/n1:TaxBase. Value: 200
        // [THEN] n1:Line/n1:TaxInformation/n1:TaxAmount/n1:Amount. Value: 36
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer,
                '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:TaxInformation/n1:TaxBase'),
                'A TaxBase xml node hasn''t found');
        Assert.RecordCount(TempXMLBuffer, 2);
        SAFTTestHelper.AssertCurrentElementValue(TempXMLBuffer, 'n1:TaxBase', SAFTTestHelper.FormatAmount(VATEntry[1].Base));
        TempXMLBuffer.Next();
        SAFTTestHelper.AssertCurrentElementValue(TempXMLBuffer, 'n1:TaxBase', SAFTTestHelper.FormatAmount(VATEntry[2].Base));
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer,
                '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:TaxInformation/n1:DebitTaxAmount/n1:Amount'),
                'A TaxAmount xml node hasn''t found');
        Assert.RecordCount(TempXMLBuffer, 2);
        SAFTTestHelper.AssertCurrentElementValue(TempXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(VATEntry[1].Amount));
        TempXMLBuffer.Next();
        SAFTTestHelper.AssertCurrentElementValue(TempXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(VATEntry[2].Amount));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LastModifiedDateTimeExportsToSystemEntryDateXMLNode()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        GLEntry: Record "G/L Entry";
        TransactionNo: Integer;
        DocNo: Code[20];
    begin
        // [SCENARIO 360658] A value of "Last Modified DateTime" exports to the SystemEntryDate xml node

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", LibraryRandom.RandInt(5));
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindFirst();
        Customer.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] A G/L Entry with "Last Modified DateTime" = "X" and "Posting Date" = "Y"
        TransactionNo := GetLastUsedTransactionNo() + 1;
        GLEntry.Get(
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Sale, '',
                '', GLEntry."Source Type"::Customer, Customer."No.", '', LibraryRandom.RandDec(100, 2), 0));

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] SystemEntryDate xml node has value "X"
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer,
                '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:SystemEntryDate'),
                'No G/L entries with SystemEntryDate exported.');
        Assert.RecordCount(TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(
            TempXMLBuffer, 'n1:SystemEntryDate',
            SAFTTestHelper.FormatDate(DT2Date(GLEntry."Last Modified DateTime")));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure PostingDateExportsToSystemEntryDateXMLNode()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        GLEntry: Record "G/L Entry";
        TransactionNo: Integer;
        DocNo: Code[20];
    begin
        // [SCENARIO 360658] A value of "Posting Date" exports to the SystemEntryDate xml node when "Last Modified DateTime" is blank

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", LibraryRandom.RandInt(5));
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindFirst();
        Customer.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] A G/L Entry with blank "Last Modified DateTime" and "Posting Date" = "Y"
        TransactionNo := GetLastUsedTransactionNo() + 1;
        GLEntry.Get(
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Sale, '',
                '', GLEntry."Source Type"::Customer, Customer."No.", '', LibraryRandom.RandDec(100, 2), 0));
        GLEntry.Validate("Last Modified DateTime", 0DT);
        GLEntry.Modify();

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] SystemEntryDate xml node has value "Y"
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer,
                '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:SystemEntryDate'),
                'No G/L entries with SystemEntryDate exported.');
        Assert.RecordCount(TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(
            TempXMLBuffer, 'n1:SystemEntryDate',
            SAFTTestHelper.FormatDate(GLEntry."Posting Date"));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CustomerIDWithZeroBalanceInvoiceAndPayment();
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Customer: Record Customer;
        CustNo: Code[20];
        Cust2No: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 372962] CustomerID of Customer with zero balance and non-zero sales must be presented in XML
        Initialize();

        // [GIVEN] SAF-T Setup
        BasicSAFTSetup(SAFTExportHeader);

        // [GIVEN] Customer with 2 Customer Ledger Entries - Invoice and Payment
        Customer.FindFirst();
        CustNo := Customer."No.";
        Amount := LibraryRandom.RandIntInRange(100, 1000);
        SAFTTestHelper.MockCustLedgEntry(
            SAFTExportHeader."Starting Date", CustNo, Amount, Amount, "Gen. Journal Document Type"::Invoice);
        SAFTTestHelper.MockCustLedgEntry(
            SAFTExportHeader."Starting Date", CustNo, 0, -Amount, "Gen. Journal Document Type"::Payment);

        // [GIVEN] Customer2 without any ledger entries
        Cust2No := LibrarySales.CreateCustomerNo();

        // [WHEN] Export SAF-T
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Master file contains the 'n1:CustomerID' for Customer with zero balance
        VerifyXMLNodeOfMasterFile(SAFTExportHeader, 'CustomerID', CustNo);

        // [THEN] Master file does not contain the 'n1:CustomerID' for Customer2
        VerifyNonExistingXMLNodeOfMasterFile(SAFTExportHeader, 'CustomerID', Cust2No);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure VendorIDWithZeroBalanceInvoiceAndPayment();
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Vendor: Record Vendor;
        VendNo: Code[20];
        Vend2No: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 372962] SupplierID of Vendor with zero balance and non-zero sales must be presented in XML
        Initialize();

        // [GIVEN] SAF-T Setup
        BasicSAFTSetup(SAFTExportHeader);

        // [GIVEN] Vendor with 2 Vendor Ledger Entries - Invoice and Payment
        Vendor.FindFirst();
        VendNo := Vendor."No.";
        Amount := LibraryRandom.RandIntInRange(100, 1000);
        SAFTTestHelper.MockVendLedgEntry(
            SAFTExportHeader."Starting Date", VendNo, Amount, Amount, "Gen. Journal Document Type"::Invoice);
        SAFTTestHelper.MockVendLedgEntry(
            SAFTExportHeader."Starting Date", VendNo, 0, -Amount, "Gen. Journal Document Type"::Payment);

        // [GIVEN] Vendor2 without any ledger entries
        Vend2No := LibraryPurchase.CreateVendorNo();

        // [WHEN] Export SAF-T
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Master file contains the 'n1:SupplierID' for Vendor with zero balance
        VerifyXMLNodeOfMasterFile(SAFTExportHeader, 'SupplierID', VendNo);

        // [THEN] Master file does not contain the 'n1:SupplierID' for Vendor2
        VerifyNonExistingXMLNodeOfMasterFile(SAFTExportHeader, 'SupplierID', Vend2No);
        LibraryVariableStorage.AssertEmpty();
    END;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CustomerIDWithZeroBalanceInvoiceAndCreditMemo();
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Customer: Record Customer;
        CustNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 372962] CustomerID of Customer with zero balance and non-zero sales must be presented in XML
        Initialize();

        // [GIVEN] SAF-T Setup
        BasicSAFTSetup(SAFTExportHeader);

        // [GIVEN] Customer with 2 Customer Ledger Entries - Invoice and Credit Memo
        Customer.FindFirst();
        CustNo := Customer."No.";
        Amount := LibraryRandom.RandIntInRange(100, 1000);
        SAFTTestHelper.MockCustLedgEntry(
            SAFTExportHeader."Starting Date", CustNo, Amount, Amount, "Gen. Journal Document Type"::Invoice);
        SAFTTestHelper.MockCustLedgEntry(
            SAFTExportHeader."Starting Date", CustNo, -Amount, -Amount, "Gen. Journal Document Type"::"Credit Memo");

        // [WHEN] Export SAF-T
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Master file contains the 'n1:CustomerID' for Customer with zero balance
        VerifyXMLNodeOfMasterFile(SAFTExportHeader, 'CustomerID', CustNo);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure VendorIDWithZeroBalanceInvoiceAndCreditMemo();
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Vendor: Record Vendor;
        VendNo: Code[20];
        Amount: Decimal;
    begin
        // [SCENARIO 372962] SupplierID of Vendor with zero balance and non-zero sales must be presented in XML
        Initialize();

        // [GIVEN] SAF-T Setup
        BasicSAFTSetup(SAFTExportHeader);

        // [GIVEN] Vendor with 2 Vendor Ledger Entries - Invoice and Credit Memo
        Vendor.FindFirst();
        VendNo := Vendor."No.";
        Amount := LibraryRandom.RandIntInRange(100, 1000);
        SAFTTestHelper.MockVendLedgEntry(
            SAFTExportHeader."Starting Date", VendNo, Amount, Amount, "Gen. Journal Document Type"::Invoice);
        SAFTTestHelper.MockVendLedgEntry(
            SAFTExportHeader."Starting Date", VendNo, -Amount, -Amount, "Gen. Journal Document Type"::"Credit Memo");

        // [WHEN] Export SAF-T
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Master file contains the 'n1:SupplierID' for Vendor with zero balance
        VerifyXMLNodeOfMasterFile(SAFTExportHeader, 'SupplierID', VendNo);
        LibraryVariableStorage.AssertEmpty();
    END;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DefaultPostCodeUsesWhenCustomerOrVendorHasNoPostCode()
    var
        SAFTSetup: Record "SAF-T Setup";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [SCENARIO 389723] A "Default Post Code" of the SAF-T setup uses when customer or vendor does not have their own post code

        Initialize();

        // [GIVEN] SAF-T Setup with single customer and vendor
        BasicSAFTSetup(SAFTExportHeader);

        // [GIVEN] Customer and vendor does not have the value of Post Code
        Customer.FindFirst();
        Customer.Validate("Post Code", '');
        Customer.Modify(true);
        SAFTTestHelper.MockCustLedgEntry(
          SAFTExportHeader."Starting Date", Customer."No.", 1, 1, CustLedgerEntry."Document Type"::Invoice);
        Vendor.FindFirst();
        SAFTTestHelper.MockVendLedgEntry(
          SAFTExportHeader."Starting Date", Vendor."No.", 1, 1, VendorLedgerEntry."Document Type"::Invoice);

        // [GIVEN] "Default Post Code" of the SAF-T Setup is "X"
        SAFTSetup.Get();
        SAFTSetup."Default Post Code" := LibraryUtility.GenerateGUID();
        SAFTSetup.Modify();

        // [WHEN] Export SAF-T
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Master file contains the 'n1:Customers/n1:Customer/n1:Address/n1:PostalCode' xml node for customer and vendor with "X" value
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Completed);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        SAFTTestHelper.AssertCurrentValue(
          TempXMLBuffer,
          '/n1:AuditFile/n1:MasterFiles/n1:Customers/n1:Customer/n1:Address/n1:PostalCode', SAFTSetup."Default Post Code");
        SAFTTestHelper.AssertCurrentValue(
          TempXMLBuffer,
          '/n1:AuditFile/n1:MasterFiles/n1:Vendors/n1:Vendor/n1:Address/n1:PostalCode', SAFTSetup."Default Post Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure VendCurrencyInformationExportsWhenExportCurrencyOptionEnabled()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        DocNo: Code[20];
        GLEntryNo: Integer;
        TransactionNo: Integer;
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrGLAccNo: array[4] of Code[20];
        CurrAdjmtAmount: array[4] of Decimal;
        ExchangeRate: Decimal;
        i: integer;
    begin
        // [FEATURE] [Currency] [Purchase]
        // [SCENARIO 399930] Only G/L Entries xml node associated with the vendor ledger entry has with currency and not relation to gains/loss account has the information about the currency code and exchange rate
        // [SCENARIO 300030] when "Export Currency Information" option is enabled in the SAF-T export card

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", 10);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        // "Export Currency Information" is enabled by default
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindSet();
        Vendor.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] G/L entry with "Entry No."" = "X", "Transaction No." = "Y" and Amount = 100 (Amount LCY)
        AmountLCY := LibraryRandom.RandDec(100, 2);
        ExchangeRate := round(1 / LibraryRandom.RandIntInRange(5, 10), 0.00001);
        Amount := Round(AmountLCY / ExchangeRate);
        GLEntry.SetCurrentKey("Transaction No.");
        if GLEntry.FindLast() then;
        TransactionNo := GLEntry."Transaction No." + 1;
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::Vendor, Vendor."No.", '', AmountLCY, 0);

        // [GIVEN] Currency with "Unrealized Gain Acc." = "U1", "Unrealized Loss Acc." = "U2", "Realized Gain Acc." = "R1", "Realized Loss Acc." = "R2"
        LibraryERM.CreateCurrency(Currency);
        for i := 1 to ArrayLen(CurrGLAccNo) do begin
            GLAccount.Next();
            CurrGLAccNo[i] := GLAccount."No.";
            CurrAdjmtAmount[i] := LibraryRandom.RandDec(100, 2);
        end;
        Currency.Validate("Unrealized Gains Acc.", CurrGLAccNo[1]);
        Currency.Validate("Unrealized Losses Acc.", CurrGLAccNo[2]);
        Currency.Validate("Realized Gains Acc.", CurrGLAccNo[3]);
        Currency.Validate("Realized Losses Acc.", CurrGLAccNo[4]);
        Currency.Modify(true);

        // [GIVEN] Four G/L entries with "Transaction No." = "Y" and G/L Accounts "U1", "U2", "R1", "R2"
        for i := 1 to ArrayLen(CurrGLAccNo) do
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, CurrGLAccNo[i],
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::Vendor, Vendor."No.", '', CurrAdjmtAmount[i], 0);

        // [GIVEN] G/L entry with "Entry No."" <> "X", "Transaction No." = "Y" and Amount = 100 (Amount LCY)
        GLAccount.Next();
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::Vendor, Vendor."No.", '', AmountLCY, 0);

        // [GIVEN] Vendor Ledger Entry with "Entry No."  = "X", "Transaction No." = "Y", Amount = 80 and "Amount (LCY)" = 100
        SAFTTestHelper.MockVendLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", Vendor."No.", TransactionNo, Currency.Code, Amount, Amount, AmountLCY, AmountLCY / Amount, "Gen. Journal Document Type"::Invoice);

        // [GIVEN] Two credit G/L entries with negative vendor currency amounts, one using the entry-number fallback
        TransactionNo += 1;
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
            TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase.AsInteger(), '',
            '', GLEntry."Source Type"::Vendor.AsInteger(), Vendor."No.", '', 0, -AmountLCY);
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase.AsInteger(), '',
                '', GLEntry."Source Type"::Vendor.AsInteger(), Vendor."No.", '', 0, -AmountLCY);
        SAFTTestHelper.MockVendLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", Vendor."No.", TransactionNo, Currency.Code,
            -Amount, -Amount, -AmountLCY, AmountLCY / Amount, "Gen. Journal Document Type"::Invoice);

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] Six "n1:Transaction/n1:Line/n1:DebitAmount" nodes have been generated         
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:DebitAmount'),
                'No G/L entries exported.');
        Assert.RecordCount(TempXMLBuffer, 6);
        // [THEN] The first one has "n1:Amount, "n1:CurrencyCode", "n1:CurrencyAmount" and "n1:ExchangeRate"
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);
        // [THEN] The second to fifth have only "n1:Amount""        "
        for i := 1 to ArrayLen(CurrGLAccNo) do begin
            TempXMLBuffer.Next();
            VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
            SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(CurrAdjmtAmount[i]));
        end;
        // [THEN] The sixth one has "n1:Amount, "n1:CurrencyCode", "n1:CurrencyAmount" and "n1:ExchangeRate"
        TempXMLBuffer.Next();
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);

        // [THEN] Both credit lines retain their parent, positive magnitudes, currency code and exchange rate
        VerifyCreditCurrencyAmounts(TempXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CustCurrencyInformationExportsWhenExportCurrencyOptionEnabled()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        DocNo: Code[20];
        GLEntryNo: Integer;
        TransactionNo: Integer;
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrGLAccNo: array[4] of Code[20];
        CurrAdjmtAmount: array[4] of Decimal;
        ExchangeRate: Decimal;
        i: integer;
    begin
        // [FEATURE] [Currency] [Sales]
        // [SCENARIO 399930] Only G/L Entries xml node associated with the customer ledger entry has with currency and not relation to gains/loss account has the information about the currency code and exchange rate
        // [SCENARIO 300030] when "Export Currency Information" option is enabled in the SAF-T export card

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", 10);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        // "Export Currency Information" is enabled by default
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindSet();
        Customer.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] G/L entry with "Entry No."" = "X", "Transaction No." = "Y" and Amount = 100 (Amount LCY)
        AmountLCY := LibraryRandom.RandDec(100, 2);
        ExchangeRate := round(1 / LibraryRandom.RandIntInRange(5, 10), 0.00001);
        Amount := Round(AmountLCY / ExchangeRate);
        TransactionNo := GetLastUsedTransactionNo() + 1;
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Sale, '',
                '', GLEntry."Source Type"::Customer, Customer."No.", '', AmountLCY, 0);

        // [GIVEN] Currency with "Unrealized Gain Acc." = "U1", "Unrealized Loss Acc." = "U2", "Realized Gain Acc." = "R1", "Realized Loss Acc." = "R2"
        LibraryERM.CreateCurrency(Currency);
        for i := 1 to ArrayLen(CurrGLAccNo) do begin
            GLAccount.Next();
            CurrGLAccNo[i] := GLAccount."No.";
            CurrAdjmtAmount[i] := LibraryRandom.RandDec(100, 2);
        end;
        Currency.Validate("Unrealized Gains Acc.", CurrGLAccNo[1]);
        Currency.Validate("Unrealized Losses Acc.", CurrGLAccNo[2]);
        Currency.Validate("Realized Gains Acc.", CurrGLAccNo[3]);
        Currency.Validate("Realized Losses Acc.", CurrGLAccNo[4]);
        Currency.Modify(true);

        // [GIVEN] Four G/L entries with "Transaction No." = "Y" and G/L Accounts "U1", "U2", "R1", "R2"
        for i := 1 to ArrayLen(CurrGLAccNo) do
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, CurrGLAccNo[i],
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::Customer, Customer."No.", '', CurrAdjmtAmount[i], 0);

        // [GIVEN] G/L entry with "Entry No."" <> "X", "Transaction No." = "Y" and Amount = 100 (Amount LCY)
        GLAccount.Next();
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::Customer, Customer."No.", '', AmountLCY, 0);

        // [GIVEN] Customer Ledger Entry with "Entry No."  = "X", "Transaction No." = "Y", Amount = 80 and "Amount (LCY)" = 100
        SAFTTestHelper.MockCustLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", Customer."No.", TransactionNo, Currency.Code, Amount, Amount, AmountLCY, AmountLCY / Amount, "Gen. Journal Document Type"::Invoice);

        // [GIVEN] Two credit G/L entries with negative customer currency amounts, one using the entry-number fallback
        TransactionNo += 1;
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
            TransactionNo, 0, GLEntry."Gen. Posting Type"::Sale.AsInteger(), '',
            '', GLEntry."Source Type"::Customer.AsInteger(), Customer."No.", '', 0, -AmountLCY);
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Sale.AsInteger(), '',
                '', GLEntry."Source Type"::Customer.AsInteger(), Customer."No.", '', 0, -AmountLCY);
        SAFTTestHelper.MockCustLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", Customer."No.", TransactionNo, Currency.Code,
            -Amount, -Amount, -AmountLCY, AmountLCY / Amount, "Gen. Journal Document Type"::Payment);

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] Six "n1:Transaction/n1:Line/n1:DebitAmount" nodes have been generated         
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:DebitAmount'),
                'No G/L entries exported.');
        Assert.RecordCount(TempXMLBuffer, 6);
        // [THEN] The first one has "n1:Amount, "n1:CurrencyCode", "n1:CurrencyAmount" and "n1:ExchangeRate"
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);
        // [THEN] The second to fifth have only "n1:Amount""        "
        for i := 1 to ArrayLen(CurrGLAccNo) do begin
            TempXMLBuffer.Next();
            VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
            SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(CurrAdjmtAmount[i]));
        end;
        // [THEN] The sixth one has "n1:Amount, "n1:CurrencyCode", "n1:CurrencyAmount" and "n1:ExchangeRate"
        TempXMLBuffer.Next();
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);

        // [THEN] Both credit lines retain their parent, positive magnitudes, currency code and exchange rate
        VerifyCreditCurrencyAmounts(TempXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure BankCurrencyInformationExportsWhenExportCurrencyOptionEnabled()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        DocNo: Code[20];
        GLEntryNo: Integer;
        TransactionNo: Integer;
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrGLAccNo: array[4] of Code[20];
        CurrAdjmtAmount: array[4] of Decimal;
        ExchangeRate: Decimal;
        i: integer;
    begin
        // [FEATURE] [Currency] [Bank]
        // [SCENARIO 399930] Only G/L Entries xml node associated with the bank ledger entry has with currency and not relation to gains/loss account has the information about the currency code and exchange rate
        // [SCENARIO 300030] when "Export Currency Information" option is enabled in the SAF-T export card

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", 10);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        // "Export Currency Information" is enabled by default
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindSet();
        BankAccount.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] G/L entry with "Entry No."" = "X", "Transaction No." = "Y" and Amount = 100 (Amount LCY)
        AmountLCY := LibraryRandom.RandDec(100, 2);
        ExchangeRate := round(1 / LibraryRandom.RandIntInRange(5, 10), 0.00001);
        Amount := Round(AmountLCY / ExchangeRate);
        GLEntry.SetCurrentKey("Transaction No.");
        if GLEntry.FindLast() then;
        TransactionNo := GLEntry."Transaction No." + 1;
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Sale, '',
                '', GLEntry."Source Type"::"Bank Account", BankAccount."No.", '', AmountLCY, 0);

        // [GIVEN] Currency with "Unrealized Gain Acc." = "U1", "Unrealized Loss Acc." = "U2", "Realized Gain Acc." = "R1", "Realized Loss Acc." = "R2"
        LibraryERM.CreateCurrency(Currency);
        for i := 1 to ArrayLen(CurrGLAccNo) do begin
            GLAccount.Next();
            CurrGLAccNo[i] := GLAccount."No.";
            CurrAdjmtAmount[i] := LibraryRandom.RandDec(100, 2);
        end;
        Currency.Validate("Unrealized Gains Acc.", CurrGLAccNo[1]);
        Currency.Validate("Unrealized Losses Acc.", CurrGLAccNo[2]);
        Currency.Validate("Realized Gains Acc.", CurrGLAccNo[3]);
        Currency.Validate("Realized Losses Acc.", CurrGLAccNo[4]);
        Currency.Modify(true);

        // [GIVEN] Four G/L entries with "Transaction No." = "Y" and G/L Accounts "U1", "U2", "R1", "R2"
        for i := 1 to ArrayLen(CurrGLAccNo) do
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, CurrGLAccNo[i],
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::"Bank Account", BankAccount."No.", '', CurrAdjmtAmount[i], 0);

        // [GIVEN] G/L entry with "Entry No."" <> "X", "Transaction No." = "Y" and Amount = 100 (Amount LCY)
        GLAccount.Next();
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::"Bank Account", BankAccount."No.", '', AmountLCY, 0);

        // [GIVEN] Bank Ledger Entry with "Entry No."  = "X", "Transaction No." = "Y", Amount = 80 and "Amount (LCY)" = 100
        SAFTTestHelper.MockBankLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", BankAccount."No.", TransactionNo, Currency.Code, Amount, AmountLCY, "Gen. Journal Document Type"::Invoice);

        // [GIVEN] Two credit G/L entries with negative bank currency amounts, one using the entry-number fallback
        TransactionNo += 1;
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
            TransactionNo, 0, GLEntry."Gen. Posting Type"::Sale.AsInteger(), '',
            '', GLEntry."Source Type"::"Bank Account".AsInteger(), BankAccount."No.", '', 0, -AmountLCY);
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Sale.AsInteger(), '',
                '', GLEntry."Source Type"::"Bank Account".AsInteger(), BankAccount."No.", '', 0, -AmountLCY);
        SAFTTestHelper.MockBankLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", BankAccount."No.", TransactionNo, Currency.Code,
            -Amount, -AmountLCY, "Gen. Journal Document Type"::Payment);

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] Six "n1:Transaction/n1:Line/n1:DebitAmount" nodes have been generated         
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:DebitAmount'),
                'No G/L entries exported.');
        Assert.RecordCount(TempXMLBuffer, 6);
        // [THEN] The first one has "n1:Amount, "n1:CurrencyCode", "n1:CurrencyAmount" and "n1:ExchangeRate"
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);
        // [THEN] The second to fifth have only "n1:Amount""        "
        for i := 1 to ArrayLen(CurrGLAccNo) do begin
            TempXMLBuffer.Next();
            VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
            SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(CurrAdjmtAmount[i]));
        end;
        // [THEN] The sixth one has "n1:Amount, "n1:CurrencyCode", "n1:CurrencyAmount" and "n1:ExchangeRate"
        TempXMLBuffer.Next();
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);

        // [THEN] Both credit lines retain their parent, positive magnitudes, currency code and exchange rate
        VerifyCreditCurrencyAmounts(TempXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure NoCurrencyInformationExportsWhenExportCurrencyOptionDisabled()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        DocNo: Code[20];
        GLEntryNo: Integer;
        TransactionNo: Integer;
        Amount: Decimal;
        AmountLCY: Decimal;
        CurrGLAccNo: array[4] of Code[20];
        CurrAdjmtAmount: array[4] of Decimal;
        ExchangeRate: Decimal;
        i: integer;
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 399930] No G/L Entries xml node associated with the customer ledger entry has with currency and not relation to gains/loss account has the information about the currency code and exchange rate
        // [SCENARIO 300030] when "Export Currency Information" option is disabled in the SAF-T export card

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", 10);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        SAFTExportHeader.Validate("Export Currency Information", false);
        SAFTExportHeader.Modify(true);

        DocNo := LibraryUtility.GenerateGUID();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindSet();
        Vendor.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] G/L entry with "Entry No."" = "X", "Transaction No." = "Y" and Amount = 100 (Amount LCY)
        AmountLCY := LibraryRandom.RandDec(100, 2);
        ExchangeRate := round(1 / LibraryRandom.RandIntInRange(5, 10), 0.00001);
        Amount := Round(AmountLCY / ExchangeRate);
        TransactionNo := GetLastUsedTransactionNo() + 1;
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::Vendor, Vendor."No.", '', AmountLCY, 0);

        // [GIVEN] Currency with "Unrealized Gain Acc." = "U1", "Unrealized Loss Acc." = "U2", "Realized Gain Acc." = "R1", "Realized Loss Acc." = "R2"
        LibraryERM.CreateCurrency(Currency);
        for i := 1 to ArrayLen(CurrGLAccNo) do begin
            GLAccount.Next();
            CurrGLAccNo[i] := GLAccount."No.";
            CurrAdjmtAmount[i] := LibraryRandom.RandDec(100, 2);
        end;
        Currency.Validate("Unrealized Gains Acc.", CurrGLAccNo[1]);
        Currency.Validate("Unrealized Losses Acc.", CurrGLAccNo[2]);
        Currency.Validate("Realized Gains Acc.", CurrGLAccNo[3]);
        Currency.Validate("Realized Losses Acc.", CurrGLAccNo[4]);
        Currency.Modify(true);

        // [GIVEN] Four G/L entries with "Transaction No." = "Y" and G/L Accounts "U1", "U2", "R1", "R2"
        for i := 1 to ArrayLen(CurrGLAccNo) do
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, CurrGLAccNo[i],
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::Vendor, Vendor."No.", '', CurrAdjmtAmount[i], 0);

        // [GIVEN] G/L entry with "Entry No."" <> "X", "Transaction No." = "Y" and Amount = 100 (Amount LCY)
        GLAccount.Next();
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::Vendor, Vendor."No.", '', AmountLCY, 0);

        // [GIVEN] Vendor Ledger Entry with "Entry No."  = "X", "Transaction No." = "Y", Amount = 80 and "Amount (LCY)" = 100
        SAFTTestHelper.MockVendLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", Vendor."No.", TransactionNo, Currency.Code, Amount, Amount, AmountLCY, AmountLCY / Amount, "Gen. Journal Document Type"::Invoice);

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] All six "n1:Transaction/n1:Line/n1:DebitAmount" nodes which have been generated do not have currency information and only
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:DebitAmount'),
                'No G/L entries exported.');
        Assert.RecordCount(TempXMLBuffer, 6);
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(AmountLCY));
        TempXMLBuffer.Next();
        for i := 1 to ArrayLen(CurrAdjmtAmount) do begin
            VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
            SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(CurrAdjmtAmount[i]));
            TempXMLBuffer.Next();
        end;
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(AmountLCY));
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ExportCurrencyBlockWithZeroVendGLEntryAmount()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        DocNo: Code[20];
        GLEntryNo: Integer;
        TransactionNo: Integer;
        Amount: Decimal;
        AmountLCY: Decimal;
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [Currency] [Purchase]
        // [SCENARIO 460063] Stan has a currency information XML block in the output file if the vendor G/L Entry amount is zero

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", 10);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        // "Export Currency Information" is enabled by default
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindSet();
        Vendor.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] G/L entry with "Entry No."" = "X", "Transaction No." = "Y" and Amount = 0
        AmountLCY := 0;
        Amount := 0.1;
        ExchangeRate := 0.1;
        TransactionNo := GetLastUsedTransactionNo() + 1;
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Purchase, '',
                '', GLEntry."Source Type"::Vendor, Vendor."No.", '', AmountLCY, 0);

        // [GIVEN] Vendor Ledger Entry with "Entry No."  = "X", "Currency Code" = EUR, "Transaction No." = "Y", Amount = 0.1 and "Amount (LCY)" = 0
        LibraryERM.CreateCurrency(Currency);
        SAFTTestHelper.MockVendLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", Vendor."No.", TransactionNo, Currency.Code, Amount, Amount, AmountLCY, ExchangeRate, "Gen. Journal Document Type"::Invoice);

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] One "n1:Transaction/n1:Line/n1:CreditAmount" node have been generated         
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:CreditAmount'),
                'No G/L entries exported.');
        Assert.RecordCount(TempXMLBuffer, 1);
        // [THEN] The node has subnodes: "n1:Amount" = 0, "n1:CurrencyCode" = EUR, "n1:CurrencyAmount" = 0.1 and "n1:ExchangeRate" = 0.1
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ExportCurrencyBlockWithZeroCustGLEntryAmount()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        DocNo: Code[20];
        GLEntryNo: Integer;
        TransactionNo: Integer;
        Amount: Decimal;
        AmountLCY: Decimal;
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [Currency] [Sales]
        // [SCENARIO 460063] Stan has a currency information XML block in the output file if the customer G/L Entry amount is zero

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", 10);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        // "Export Currency Information" is enabled by default
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindSet();
        Customer.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] G/L entry with "Entry No."" = "X", "Transaction No." = "Y" and Amount = 0
        AmountLCY := 0;
        Amount := 0.1;
        ExchangeRate := 0.1;
        TransactionNo := GetLastUsedTransactionNo() + 1;
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Sale, '',
                '', GLEntry."Source Type"::Customer, Customer."No.", '', AmountLCY, 0);

        // [GIVEN] Customer Ledger Entry with "Entry No."  = "X", "Currency Code" = EUR, "Transaction No." = "Y", Amount = 0.1 and "Amount (LCY)" = 0
        LibraryERM.CreateCurrency(Currency);
        SAFTTestHelper.MockCustLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", Customer."No.", TransactionNo, Currency.Code, Amount, Amount, AmountLCY, ExchangeRate, "Gen. Journal Document Type"::Invoice);

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] One "n1:Transaction/n1:Line/n1:CreditAmount" node have been generated         
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:CreditAmount'),
                'No G/L entries exported.');
        Assert.RecordCount(TempXMLBuffer, 1);
        // [THEN] The node has subnodes: "n1:Amount" = 0, "n1:CurrencyCode" = EUR, "n1:CurrencyAmount" = 0.1 and "n1:ExchangeRate" = 0.1
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, Currency.Code, Amount, AmountLCY, ExchangeRate);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ExportCurrencyBlockWithZeroBankGLEntryAmount()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        GLAccount: Record "G/L Account";
        BankAccount: Record "Bank Account";
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        DocNo: Code[20];
        GLEntryNo: Integer;
        TransactionNo: Integer;
        Amount: Decimal;
        AmountLCY: Decimal;
        ExchangeRate: Decimal;
    begin
        // [FEATURE] [Currency] [Bank]
        // [SCENARIO 460063] Stan has a currency information XML block in the output file if the bank G/L Entry amount is zero

        Initialize();

        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", 10);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        // "Export Currency Information" is enabled by default
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        DocNo := LibraryUtility.GenerateGUID();
        GLAccount.SetRange("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        GLAccount.FindSet();
        BankAccount.FindFirst();
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] G/L entry with "Entry No."" = "X", "Transaction No." = "Y" and Amount = 0
        AmountLCY := 0;
        Amount := 0.1;
        ExchangeRate := 0.1;
        TransactionNo := GetLastUsedTransactionNo() + 1;
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Ending Date", DocNo, GLAccount."No.",
                TransactionNo, 0, GLEntry."Gen. Posting Type"::Sale, '',
                '', GLEntry."Source Type"::"Bank Account", BankAccount."No.", '', AmountLCY, 0);

        // [GIVEN] Bank Ledger Entry with "Entry No."  = "X", "Currency Code" = EUR, "Transaction No." = "Y", Amount = 0.1 and "Amount (LCY)" = 0
        LibraryERM.CreateCurrency(Currency);
        SAFTTestHelper.MockBankLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", BankAccount."No.", TransactionNo, Currency.Code, Amount, AmountLCY, "Gen. Journal Document Type"::Invoice);

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] One "n1:Transaction/n1:Line/n1:CreditAmount" node have been generated         
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:CreditAmount'),
                'No G/L entries exported.');
        Assert.RecordCount(TempXMLBuffer, 1);
        // [THEN] The node has subnodes: "n1:Amount" = 0, "n1:CurrencyCode" = EUR, "n1:CurrencyAmount" = 0.1 and "n1:ExchangeRate" = 0
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, Currency.Code, Amount, AmountLCY, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure GLEntryTotalsContainValuesFromAllPeriods()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        TempXMLBuffer: Record "XML Buffer" temporary;
        Amount: array[2] of Decimal;
        LastUsedTransactionNo: Integer;
        NumberOfTransactions: Integer;
    begin
        // [SCENARIO 485839] G/L Entry Totals xml nodes contain values from all periods when SAF-T file splitted to multiple periods

        Initialize();
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", LibraryRandom.RandInt(5));
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        // [GIVEN] SAF-T Export with "Starting Date" = 01.01.2023 and "Ending Date" = 01.02.2023
        // [GIVEN] "Split by Month" option is enabled
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] G/L Entry with "Transaction No." = 1, "Posting Date" = 01.01.2023 and Debit = 100
        LastUsedTransactionNo := GetLastUsedTransactionNo();
        Amount[1] := LibraryRandom.RandDec(100, 2);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", LibraryUtility.GenerateGUID(), '',
            LastUsedTransactionNo + 1, 0, 0, '', '', 0, '', '', Amount[1], 0);
        // [GIVEN] G/L Entry with "Transaction No." = 2, "Posting Date" = 01.02.2023 and Credit Amount = 200
        Amount[2] := LibraryRandom.RandDec(100, 2);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", LibraryUtility.GenerateGUID(), '',
            LastUsedTransactionNo + 2, 0, 0, '', '', 0, '', '', 0, Amount[2]);

        // [WHEN] Export G/L Entries to the XML file
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Two SAF-T Export Lines have been generated
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        Assert.RecordCount(SAFTExportLine, 2);
        NumberOfTransactions := CountSelectionTransactions(SAFTExportHeader.ID);
        repeat
            SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
            Assert.IsTrue(TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries'), 'No G/L entries exported.');
            // [THEN] Each file repeats the complete selection's XML transaction count
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:NumberOfEntries', Format(NumberOfTransactions));
            // [GIVEN] Each file has "Total Debit" = 100
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TotalDebit', SAFTTestHelper.FormatAmount(Amount[1]));
            // [GIVEN] Each file has "Total Credit" = 200
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TotalCredit', SAFTTestHelper.FormatAmount(Amount[2]));
        until SAFTExportLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CreditBalanceForPurchInvoice()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Vendor: Record Vendor;
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        VendNo: Code[20];
        OpeningAmount: Decimal;
        AmountInPeriod: Decimal;
    begin
        // [SCENARIO 464814] Purchase invoice exports with credit opening and closing balance

        Initialize();
        // [GIVEN] SAF-T Setup with "Starting Date" = 01.01.2023
        BasicSAFTSetup(SAFTExportHeader);

        Vendor.FindFirst();
        VendNo := Vendor."No.";
        OpeningAmount := LibraryRandom.RandIntInRange(100, 1000);
        // [GIVEN] Invoice Vendor Ledger Entry with "Starting Date" = 31.12.2022 and Amount = -100
        SAFTTestHelper.MockVendLedgEntry(
            SAFTExportHeader."Starting Date" - 1, VendNo, -OpeningAmount, -OpeningAmount, "Gen. Journal Document Type"::Invoice);
        AmountInPeriod := LibraryRandom.RandIntInRange(100, 1000);
        // [GIVEN] Invoice Vendor Ledger Entry with "Starting Date" = 01.01.2023 and Amount = -200
        SAFTTestHelper.MockVendLedgEntry(
            SAFTExportHeader."Starting Date", VendNo, -AmountInPeriod, -AmountInPeriod, "Gen. Journal Document Type"::Invoice);

        // [WHEN] Export SAF-T
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Master file contains the 'n1:SupplierID' node with 'OpeningCreditBalance' = 100 and 'ClosingCreditBalance' = 300
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Completed);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        TempXMLBuffer.SetFilter(Name, 'SupplierID');
        TempXMLBuffer.FindSet();
        TempXMLBuffer.Reset();
        TempXMLBuffer.Next(); // skip BalanceAccount xml node
        TempXMLBuffer.Next(); // skip AccountIDXmlNode
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:OpeningCreditBalance', SAFTTestHelper.FormatAmount(OpeningAmount));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:ClosingCreditBalance', SAFTTestHelper.FormatAmount(OpeningAmount + AmountInPeriod));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DebitBalanceForPurchCrMemo()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Vendor: Record Vendor;
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        VendNo: Code[20];
        OpeningAmount: Decimal;
        AmountInPeriod: Decimal;
    begin
        // [SCENARIO 464814] Purchase credit memo exports with debit ppening and closing balance

        Initialize();
        // [GIVEN] SAF-T Setup with "Starting Date" = 01.01.2023
        BasicSAFTSetup(SAFTExportHeader);

        Vendor.FindFirst();
        VendNo := Vendor."No.";
        OpeningAmount := LibraryRandom.RandIntInRange(100, 1000);
        // [GIVEN] Credit Memo Vendor Ledger Entry with "Starting Date" = 31.12.2022 and Amount = -100
        SAFTTestHelper.MockVendLedgEntry(
            SAFTExportHeader."Starting Date" - 1, VendNo, OpeningAmount, OpeningAmount, "Gen. Journal Document Type"::"Credit Memo");
        AmountInPeriod := LibraryRandom.RandIntInRange(100, 1000);
        // [GIVEN] Credit Memo Vendor Ledger Entry with "Starting Date" = 01.01.2023 and Amount = -200
        SAFTTestHelper.MockVendLedgEntry(
            SAFTExportHeader."Starting Date", VendNo, AmountInPeriod, AmountInPeriod, "Gen. Journal Document Type"::"Credit Memo");

        // [WHEN] Export SAF-T
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Master file contains the 'n1:SupplierID' node with 'OpeningDebitBalance' = 100 and 'ClosingDebitBalance' = 300
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Completed);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        TempXMLBuffer.SetFilter(Name, 'SupplierID');
        TempXMLBuffer.FindSet();
        TempXMLBuffer.Reset();
        TempXMLBuffer.Next(); // skip BalanceAccount xml node
        TempXMLBuffer.Next(); // skip AccountIDXmlNode
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:OpeningDebitBalance', SAFTTestHelper.FormatAmount(OpeningAmount));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:ClosingDebitBalance', SAFTTestHelper.FormatAmount(OpeningAmount + AmountInPeriod));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure BlankDimensionValueDoesNotExportToAnalysisID()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Vendor: Record Vendor;
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        VendNo: Code[20];
    begin
        // [SCENARIO 485406] A default dimension with blank dimension value code does not export to the 'AnalysysID' xml node

        Initialize();
        BasicSAFTSetup(SAFTExportHeader);

        Vendor.FindFirst();
        VendNo := Vendor."No.";
        // [GIVEN] Vendor with a default dimension "ADM" and no dimension value code
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, VendNo, Dimension.Code, '');

        // [WHEN] Export SAF-T
        LibraryVariableStorage.Enqueue(GenerateSAFTFileImmediatelyQst);
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Master file does not contain the 'n1:PartyInfo' xml node under the 'n1:SupplierID' xml node 
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Completed);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        Assert.IsFalse(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:Suppliers/n1:Supplier/n1:PartyInfo'), 'Vendor dimension is exported.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    procedure VendCurrencyInformationExportsCurrencyInformationOnlyForLineThatHasCurrency()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        GenJournalLine: array[3] of Record "Gen. Journal Line";
    begin
        // [SCENARIO 539115] SAF-T Export is exporting currency information for a line that is posted with LCY
        Initialize();

        // [GIVEN] Setup SAF-T
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", 10);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);

        // [GIVEN] Create SAF-T Export Header where "Export Currency Information" is enabled by default
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] Create and Post Payment Journal
        CreateAndPostPaymentJnl(GenJournalLine, SAFTExportHeader);

        // [WHEN] Export G/L Entries to the XML file
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] Two "n1:Transaction/n1:Line/n1:DebitAmount" nodes have been generated
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:DebitAmount'),
                'No G/L entries exported.');
        Assert.RecordCount(TempXMLBuffer, 2);

        // [THEN] The first one has "n1:Amount, "n1:CurrencyCode", "n1:CurrencyAmount" and "n1:ExchangeRate"
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(
            TempChildXMLBuffer, GenJournalLine[1]."Currency Code",
            GenJournalLine[1].Amount, GenJournalLine[1]."Amount (LCY)", GenJournalLine[1]."Currency Factor");

        // [THEN] The second have only "n1:Amount"
        TempXMLBuffer.Next();
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(GenJournalLine[2]."Amount (LCY)"));

        // [THEN] Two "n1:Transaction/n1:Line/n1:CreditAmount" nodes have been generated
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:CreditAmount'),
                'No G/L entries exported.');
        Assert.RecordCount(TempXMLBuffer, 1);

        // [THEN] The third have only "n1:Amount"
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(GenJournalLine[1]."Amount (LCY)" + GenJournalLine[2]."Amount (LCY)"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    procedure DebitCreditAmountWhenPaymentReversed()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        ReversalEntry: Record "Reversal Entry";
        PaymentAmount: Decimal;
    begin
        // [SCENARIO 537092] Export reversed payment.
        Initialize();

        // [GIVEN] SAF-T set up.
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Income Statement", 10);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);

        // [GIVEN] SAF-T Export Header
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");

        // [GIVEN] Posted payment for Customer with Amount -100.
        PaymentAmount := LibraryRandom.RandInt(100);
        CreatePaymentJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, Enum::"Gen. Journal Document Type"::Payment,
            Enum::"Gen. Journal Account Type"::Customer, LibrarySales.CreateCustomerNo(), Enum::"Gen. Journal Account Type"::"G/L Account",
            LibraryERM.CreateGLAccountNo(), -PaymentAmount);
        GenJournalLine.Validate("Posting Date", SAFTExportHeader."Ending Date");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Reversal Entry for payment.
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(GetPostedDocTransactionNo(GenJournalLine."Document No."));

        // [WHEN] Export G/L Entries to the XML file
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);

        // [THEN] Two "n1:Transaction/n1:Line/n1:DebitAmount" nodes have been generated
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:DebitAmount'),
            'DebitAmount node was not found.');
        Assert.RecordCount(TempXMLBuffer, 2);

        // [THEN] Both debit nodes have "n1:Amount" = 100
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(PaymentAmount));
        TempXMLBuffer.Next();
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(PaymentAmount));

        // [THEN] Two "n1:Transaction/n1:Line/n1:CreditAmount" nodes have been generated
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:CreditAmount'),
            'CreditAmount node was not found.');
        Assert.RecordCount(TempXMLBuffer, 2);

        // [THEN] Both credit nodes have "n1:Amount" = 100
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(PaymentAmount));
        TempXMLBuffer.Next();
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(PaymentAmount));
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure HeaderExportsVersion130AndApplicationVersion()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 1.0] [Header]
        // [SCENARIO] The header exports audit-file version 1.30 and the running application version.
        Initialize();

        // [GIVEN] A SAF-T 1.30 export
        BasicSAFTSetup(SAFTExportHeader);

        // [WHEN] Generate the export
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] The master file contains one audit-file version and one application version
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        SAFTExportLine.SetRange("Master Data", true);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyAuditAndSoftwareVersions(TempXMLBuffer);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    procedure CreditAmountShouldAppearAsPositiveWhenExportCurrencyInformationIsEnabled()
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [AI test 1.0] [Currency] [Sales]
        // [SCENARIO 564905] A foreign-currency cash receipt exports positive credit magnitudes in SAF-T 1.30.
        Initialize();

        // [GIVEN] SAF-T 1.30 with currency information enabled
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Four Digit Standard Account", 10);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();

        // [GIVEN] A posted foreign-currency cash receipt for customer "C"
        CreateAndPostCashReceiptJnl(GenJournalLine, SAFTExportHeader);

        // [WHEN] Export G/L entries
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] The customer line remains a credit with positive amounts and unchanged currency metadata
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:CreditAmount'),
            'CreditAmount node was not found.');
        Assert.RecordCount(TempXMLBuffer, 1);
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(
            TempChildXMLBuffer, GenJournalLine."Currency Code", Abs(GenJournalLine.Amount),
            Abs(GenJournalLine."Amount (LCY)"), GenJournalLine."Currency Factor");

        // [THEN] The balancing bank line remains a debit in local currency
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:DebitAmount'),
            'DebitAmount node was not found.');
        Assert.RecordCount(TempXMLBuffer, 1);
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(
            TempChildXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(Abs(GenJournalLine."Amount (LCY)")));
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure AnalysisOmittedWhenAllDimensionsExcluded()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        TempMasterXMLBuffer: Record "XML Buffer" temporary;
        TempGLEntryXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 1.0] [Dimension]
        // [SCENARIO] Excluding every dimension omits analysis master data and all default and G/L dimension references.
        Initialize();

        // [GIVEN] Excluded dimensions "D1" and "D2" with values used by customer "C", vendor "V" and a G/L entry
        CreateAnalysisExportFixture(SAFTExportHeader, Dimension, DimensionValue);

        // [WHEN] Export SAF-T 1.30
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Neither file contains analysis containers, entries or references
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        LoadAnalysisExportFiles(SAFTExportHeader, TempMasterXMLBuffer, TempGLEntryXMLBuffer);
        VerifyNoAnalysisOutput(TempMasterXMLBuffer);
        VerifyNoAnalysisOutput(TempGLEntryXMLBuffer);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure AnalysisExportsOnlySelectedDimensions()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        AdditionalDimensionValue: Record "Dimension Value";
        TempMasterXMLBuffer: Record "XML Buffer" temporary;
        TempGLEntryXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 1.0] [Dimension]
        // [SCENARIO] Mixed dimension selection preserves eligible master-data order and matching customer, supplier and G/L references.
        Initialize();

        // [GIVEN] Only dimension "D2" is selected, with two values, and references also contain excluded dimension "D1"
        CreateAnalysisExportFixture(SAFTExportHeader, Dimension, DimensionValue);
        Dimension[2].Validate("Export to SAF-T", true);
        Dimension[2].Modify(true);
        LibraryDimension.CreateDimensionValue(AdditionalDimensionValue, Dimension[2].Code);
        AdditionalDimensionValue.Validate(Name, AdditionalDimensionValue.Code);
        AdditionalDimensionValue.Modify(true);

        // [WHEN] Export SAF-T 1.30
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] One analysis table contains both selected values in their original key order
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        LoadAnalysisExportFiles(SAFTExportHeader, TempMasterXMLBuffer, TempGLEntryXMLBuffer);
        VerifySelectedAnalysisTypeTable(TempMasterXMLBuffer, Dimension[2], 2);

        // [THEN] Each party and G/L line references only the selected value, and no other analysis references exist
        VerifyAnalysisReferences(
            TempMasterXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:Customers/n1:Customer/n1:PartyInfo/n1:Analysis',
            Dimension[2]."SAF-T Analysis Type", DimensionValue[2].Code, 1);
        VerifyAnalysisReferences(
            TempMasterXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:Suppliers/n1:Supplier/n1:PartyInfo/n1:Analysis',
            Dimension[2]."SAF-T Analysis Type", DimensionValue[2].Code, 1);
        VerifyAnalysisReferences(
            TempMasterXMLBuffer, '/n1:Analysis', Dimension[2]."SAF-T Analysis Type", DimensionValue[2].Code, 2);
        VerifyAnalysisReferences(
            TempGLEntryXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:Analysis',
            Dimension[2]."SAF-T Analysis Type", DimensionValue[2].Code, 1);
        VerifyAnalysisReferences(
            TempGLEntryXMLBuffer, '/n1:Analysis', Dimension[2]."SAF-T Analysis Type", DimensionValue[2].Code, 1);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure ExcludedDefaultDimensionsOmitPartyAnalysis()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        TempMasterXMLBuffer: Record "XML Buffer" temporary;
        TempGLEntryXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 1.0] [Dimension]
        // [SCENARIO] Customer and supplier PartyInfo retain non-analysis metadata but omit excluded default dimensions.
        Initialize();

        // [GIVEN] Customer "C" and vendor "V" have nonblank default dimension values, all excluded from SAF-T
        CreateAnalysisExportFixture(SAFTExportHeader, Dimension, DimensionValue);

        // [WHEN] Export SAF-T 1.30
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Exported customer and supplier PartyInfo have no Analysis children
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        LoadAnalysisExportFiles(SAFTExportHeader, TempMasterXMLBuffer, TempGLEntryXMLBuffer);
        Assert.IsFalse(
            TempMasterXMLBuffer.FindNodesByXPath(
                TempMasterXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:Customers/n1:Customer/n1:PartyInfo/n1:Analysis'),
            'Excluded customer default dimensions were exported.');
        Assert.IsFalse(
            TempMasterXMLBuffer.FindNodesByXPath(
                TempMasterXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:Suppliers/n1:Supplier/n1:PartyInfo/n1:Analysis'),
            'Excluded supplier default dimensions were exported.');
        VerifyNoAnalysisOutput(TempMasterXMLBuffer);
        VerifyNoAnalysisOutput(TempGLEntryXMLBuffer);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure SelectedDimensionWithoutValuesOmitsAnalysisTable()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        EmptyDimension: Record Dimension;
        TempMasterXMLBuffer: Record "XML Buffer" temporary;
        TempGLEntryXMLBuffer: Record "XML Buffer" temporary;
    begin
        // [FEATURE] [AI test 1.0] [Dimension]
        // [SCENARIO] A selected dimension without values cannot create an empty analysis table when excluded values exist.
        Initialize();

        // [GIVEN] Excluded dimensions with values and selected dimension "E" with no values
        CreateAnalysisExportFixture(SAFTExportHeader, Dimension, DimensionValue);
        LibraryDimension.CreateDimension(EmptyDimension);
        EmptyDimension.Validate("Export to SAF-T", true);
        EmptyDimension.Modify(true);

        // [WHEN] Export SAF-T 1.30
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] No eligible value means no analysis container, entry or reference in either file
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        LoadAnalysisExportFiles(SAFTExportHeader, TempMasterXMLBuffer, TempGLEntryXMLBuffer);
        VerifyNoAnalysisOutput(TempMasterXMLBuffer);
        VerifyNoAnalysisOutput(TempGLEntryXMLBuffer);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure TransactionCountMatchesSingleFileGrouping()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
    begin
        // [FEATURE] [AI test 1.0] [Transaction Count]
        // [SCENARIO] Document/date groups, not transaction numbers or G/L lines, determine the single-file count.
        Initialize();

        // [GIVEN] Four lines with two transaction numbers form three document/date groups
        CreateTransactionCountSetup(SAFTExportHeader, GLAccount, SourceCode);
        SAFTExportHeader.Validate("Ending Date", SAFTExportHeader."Starting Date" + 2);
        SAFTExportHeader.Modify(true);
        CreateTransactionCountEntries(SAFTExportHeader, GLAccount."No.", SourceCode.Code);

        // [WHEN] Export one G/L file
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] NumberOfEntries equals the three independently counted XML transactions
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        VerifySelectionTransactionCount(SAFTExportHeader, 1, 3, 4);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure TransactionCountRepeatsAcrossMonthFiles()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
    begin
        // [FEATURE] [AI test 1.0] [Transaction Count]
        // [SCENARIO] Every monthly file repeats the total XML transaction count across the selection.
        Initialize();

        // [GIVEN] Three document/date groups spread over two months
        CreateTransactionCountSetup(SAFTExportHeader, GLAccount, SourceCode);
        SAFTExportHeader.Validate("Ending Date", CalcDate('<1M+CM>', SAFTExportHeader."Starting Date"));
        SAFTExportHeader.Validate("Split By Month", true);
        SAFTExportHeader.Modify(true);
        CreateTransactionCountEntries(SAFTExportHeader, GLAccount."No.", SourceCode.Code);

        // [WHEN] Export monthly files
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Both files report the sum of their XML transaction counts
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        VerifySelectionTransactionCount(SAFTExportHeader, 2, 3, 4);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure TransactionCountRepeatsAcrossDateFiles()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
    begin
        // [FEATURE] [AI test 1.0] [Transaction Count]
        // [SCENARIO] Daily files repeat the selection total and days without entries create no additional part.
        Initialize();

        // [GIVEN] Three document/date groups on two dates separated by an empty day
        CreateTransactionCountSetup(SAFTExportHeader, GLAccount, SourceCode);
        SAFTExportHeader.Validate("Ending Date", SAFTExportHeader."Starting Date" + 2);
        SAFTExportHeader.Validate("Split By Date", true);
        SAFTExportHeader.Modify(true);
        CreateTransactionCountEntries(SAFTExportHeader, GLAccount."No.", SourceCode.Code);

        // [WHEN] Export daily files
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Both nonempty parts repeat the complete XML transaction count
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        VerifySelectionTransactionCount(SAFTExportHeader, 2, 3, 4);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure TransactionCountSeparatesJournals()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        GLAccount: Record "G/L Account";
        SourceCode: array[3] of Record "Source Code";
        SAFTSourceCode: Record "SAF-T Source Code";
        TransactionNo: Integer;
    begin
        // [FEATURE] [AI test 1.0] [Transaction Count]
        // [SCENARIO] Identical document/date IDs in separate journals count separately; sources within one journal share a group.
        Initialize();

        // [GIVEN] Two populated journals and an empty journal, all lines sharing one transaction number and document/date
        CreateTransactionCountSetup(SAFTExportHeader, GLAccount, SourceCode[1]);
        CreateTransactionCountJournal(SAFTSourceCode, false);
        LibraryERM.CreateSourceCode(SourceCode[2]);
        SourceCode[2].Validate("SAF-T Source Code", SAFTSourceCode.Code);
        SourceCode[2].Modify(true);
        LibraryERM.CreateSourceCode(SourceCode[3]);
        SourceCode[3].Validate("SAF-T Source Code", SourceCode[1]."SAF-T Source Code");
        SourceCode[3].Modify(true);
        CreateTransactionCountJournal(SAFTSourceCode, false);
        TransactionNo := GetLastUsedTransactionNo() + 1;
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", 'COUNT-A', GLAccount."No.", TransactionNo, 0, '', '', 0, '', SourceCode[1].Code, 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", 'COUNT-A', GLAccount."No.", TransactionNo, 0, '', '', 0, '', SourceCode[2].Code, 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", 'COUNT-A', GLAccount."No.", TransactionNo, 0, '', '', 0, '', SourceCode[3].Code, 100, 0);

        // [WHEN] Export SAF-T
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] The two journals emit two transactions containing all three lines, without filter leakage
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        VerifyTransactionCountJournals(SAFTExportHeader.ID, SourceCode[1]."SAF-T Source Code", SourceCode[2]."SAF-T Source Code");
        VerifySelectionTransactionCount(SAFTExportHeader, 1, 2, 3);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure TransactionCountIncludesBlankSourceJournal()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
        SAFTSourceCode: Record "SAF-T Source Code";
        TransactionNo: Integer;
    begin
        // [FEATURE] [AI test 1.0] [Transaction Count]
        // [SCENARIO] A journal with only Includes No Source Code contributes its blank-source transaction exactly once.
        Initialize();

        // [GIVEN] Mapped and blank source lines with the same document/date belong to separate journals
        CreateTransactionCountSetup(SAFTExportHeader, GLAccount, SourceCode);
        SAFTSourceCode.ModifyAll("Includes No Source Code", false);
        CreateTransactionCountJournal(SAFTSourceCode, true);
        TransactionNo := GetLastUsedTransactionNo() + 1;
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", 'COUNT-A', GLAccount."No.", TransactionNo, 0, '', '', 0, '', SourceCode.Code, 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", 'COUNT-A', GLAccount."No.", TransactionNo, 0, '', '', 0, '', '', 100, 0);

        // [WHEN] Export SAF-T
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Both journal transactions and both G/L lines are included exactly once
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        VerifyTransactionCountJournals(SAFTExportHeader.ID, SourceCode."SAF-T Source Code", SAFTSourceCode.Code);
        VerifySelectionTransactionCount(SAFTExportHeader, 1, 2, 2);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure TransactionCountUsesSyntheticAssortedJournal()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
        SAFTSourceCode: Record "SAF-T Source Code";
    begin
        // [FEATURE] [AI test 1.0] [Transaction Count]
        // [SCENARIO] Without journal definitions the synthetic assorted journal uses the same grouping for counting and export.
        Initialize();

        // [GIVEN] Three document/date groups and no SAF-T journal records
        CreateTransactionCountSetup(SAFTExportHeader, GLAccount, SourceCode);
        CreateTransactionCountEntries(SAFTExportHeader, GLAccount."No.", SourceCode.Code);
        SAFTSourceCode.DeleteAll();

        // [WHEN] Export SAF-T
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] The fallback journal preserves all groups and lines
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        VerifySelectionTransactionCount(SAFTExportHeader, 1, 3, 4);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure TransactionCountIsZeroWithoutEntries()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        GLAccount: Record "G/L Account";
        SourceCode: Record "Source Code";
    begin
        // [FEATURE] [AI test 1.0] [Transaction Count]
        // [SCENARIO] An empty export selection reports zero transactions.
        Initialize();

        // [GIVEN] A mapped selection with no G/L entries
        CreateTransactionCountSetup(SAFTExportHeader, GLAccount, SourceCode);

        // [WHEN] Export SAF-T
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] The generated file contains no transactions or lines and reports zero
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        VerifySelectionTransactionCount(SAFTExportHeader, 1, 0, 0);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirmationHandler')]
    procedure CombinedSplitExportPreservesHeaderCurrencyAnalysisAndTotals()
    var
        SAFTExportHeader: Record "SAF-T Export Header";
        SAFTExportLine: Record "SAF-T Export Line";
        Dimension: array[2] of Record Dimension;
        DimensionValue: array[2] of Record "Dimension Value";
        SAFTSourceCode: Record "SAF-T Source Code";
        SourceCode: Record "Source Code";
        Customer: Record Customer;
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempChildXMLBuffer: Record "XML Buffer" temporary;
        BlankSourceJournalCode: Code[9];
        GLEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0] [Deployment Validation]
        // [SCENARIO] A split export preserves header versions, credit magnitudes, dimension selection and transaction totals across journals.
        Initialize();

        // [GIVEN] Excluded customer, supplier and G/L dimensions with one debit entry in the last month
        CreateAnalysisExportFixture(SAFTExportHeader, Dimension, DimensionValue);
        SAFTExportHeader.Validate("Split By Month", true);
        SAFTExportHeader.Modify(true);
        GLEntry.SetCurrentKey("Posting Date");
        GLEntry.SetRange("Posting Date", SAFTExportHeader."Starting Date", SAFTExportHeader."Ending Date");
        GLEntry.FindFirst();
        SAFTSourceCode.ModifyAll("Includes No Source Code", false);
        CreateTransactionCountJournal(SAFTSourceCode, true);
        BlankSourceJournalCode := SAFTSourceCode.Code;
        CreateTransactionCountJournal(SAFTSourceCode, false);
        LibraryERM.CreateSourceCode(SourceCode);
        SourceCode.Validate("SAF-T Source Code", SAFTSourceCode.Code);
        SourceCode.Modify(true);

        // [GIVEN] Customer "C" has two foreign-currency credits in separate months, sharing the debit's transaction number
        Customer.FindFirst();
        LibraryERM.CreateCurrency(Currency);
        GLEntryNo :=
            SAFTTestHelper.MockGLEntry(
                SAFTExportHeader."Starting Date", 'HOLISTIC', GLEntry."G/L Account No.", GLEntry."Transaction No.",
                GLEntry."Dimension Set ID", '', '', GLEntry."Source Type"::Customer.AsInteger(), Customer."No.", SourceCode.Code, 0, -100);
        SAFTTestHelper.MockCustLedgEntry(
            GLEntryNo, SAFTExportHeader."Starting Date", Customer."No.", GLEntry."Transaction No.", Currency.Code,
            -200, -200, -100, 0.5, "Gen. Journal Document Type"::Payment);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", 'HOLISTIC', GLEntry."G/L Account No.", GLEntry."Transaction No.",
            GLEntry."Dimension Set ID", '', '', GLEntry."Source Type"::Customer.AsInteger(), Customer."No.", SourceCode.Code, 0, -100);

        // [WHEN] Generate the combined SAF-T 1.30 export using the published application
        SAFTTestHelper.RunSAFTExport(SAFTExportHeader);

        // [THEN] Master data retains both parties but emits no excluded analysis
        Assert.ExpectedMessage(GenerateSAFTFileImmediatelyQst, LibraryVariableStorage.DequeueText());
        SAFTExportLine.SetRange("Master Data", true);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        Assert.RecordCount(SAFTExportLine, 1);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        VerifyAuditAndSoftwareVersions(TempXMLBuffer);
        VerifyNoAnalysisOutput(TempXMLBuffer);
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:Customers/n1:Customer'),
            'Customer master data was not exported.');
        Assert.RecordCount(TempXMLBuffer, 1);
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:Suppliers/n1:Supplier'),
            'Supplier master data was not exported.');
        Assert.RecordCount(TempXMLBuffer, 1);

        // [THEN] Both G/L files retain exact header values, positive credit magnitudes and metadata, and no excluded analysis
        VerifySelectionTransactionCount(SAFTExportHeader, 2, 3, 3);
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        repeat
            SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
            VerifyAuditAndSoftwareVersions(TempXMLBuffer);
            VerifyNoAnalysisOutput(TempXMLBuffer);
            Assert.IsTrue(
                TempXMLBuffer.FindNodesByXPath(
                    TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:CreditAmount'),
                'The foreign-currency line must remain a credit.');
            Assert.RecordCount(TempXMLBuffer, 1);
            VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
            VerifyCurrencyAmountInfo(TempChildXMLBuffer, Currency.Code, 200, 100, 0.5);
        until SAFTExportLine.Next() = 0;

        // [THEN] The last month contains both journals and the unchanged local-currency debit
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:JournalID');
        Assert.RecordCount(TempXMLBuffer, 2);
        TempXMLBuffer.SetRange(Value, BlankSourceJournalCode);
        Assert.RecordCount(TempXMLBuffer, 1);
        TempXMLBuffer.SetRange(Value, SourceCode."SAF-T Source Code");
        Assert.RecordCount(TempXMLBuffer, 1);
        TempXMLBuffer.SetRange(Value);
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:DebitAmount'),
            'The balancing entry must remain a debit.');
        Assert.RecordCount(TempXMLBuffer, 1);
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:Amount', '100');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SAF-T XML Tests 1.3");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SAF-T XML Tests 1.3");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SAF-T XML Tests 1.3");
    end;

    local procedure SetupSAFTSingleAcc(var SAFTMappingRange: Record "SAF-T Mapping Range"; MappingType: Enum "SAF-T Mapping Type"; IncomeBalance: Integer): Code[20]
    var
        SAFTMappingHelper: Codeunit "SAF-T Mapping Helper";
    begin
        SAFTTestHelper.SetupMasterDataSingleAcc(IncomeBalance);
        SAFTTestHelper.InsertSAFTMappingRangeFullySetup(
            SAFTMappingRange, MappingType, SAFTTestHelper.GetWorkDateInYearWithNoGLEntries(),
            CalcDate('<CY>', SAFTTestHelper.GetWorkDateInYearWithNoGLEntries()));
        SAFTMappingHelper.MapRestSourceCodesToAssortedJournals();
        exit(SAFTMappingRange.Code);
    end;

    local procedure BasicSAFTSetup(var SAFTExportHeader: Record "SAF-T Export Header");
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
    begin
        SAFTTestHelper.SetupSAFT(
          SAFTMappingRange, "SAF-T Mapping Type"::"Four Digit Standard Account", LibraryRandom.RandIntInRange(3, 5));
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
    end;

    local procedure CreateAnalysisExportFixture(var SAFTExportHeader: Record "SAF-T Export Header"; var Dimension: array[2] of Record Dimension; var DimensionValue: array[2] of Record "Dimension Value")
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        ExistingDimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        Customer: Record Customer;
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        DimensionSetID: Integer;
        DimensionIndex: Integer;
    begin
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Four Digit Standard Account", 1);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        SAFTTestHelper.IncludesNoSourceCodeToTheFirstSAFTSourceCode();
        ExistingDimension.ModifyAll("Export to SAF-T", false);

        Customer.FindFirst();
        Vendor.FindFirst();
        for DimensionIndex := 1 to ArrayLen(Dimension) do begin
            LibraryDimension.CreateDimension(Dimension[DimensionIndex]);
            Dimension[DimensionIndex].Validate("Export to SAF-T", false);
            Dimension[DimensionIndex].Modify(true);
            LibraryDimension.CreateDimensionValue(DimensionValue[DimensionIndex], Dimension[DimensionIndex].Code);
            DimensionValue[DimensionIndex].Validate(Name, DimensionValue[DimensionIndex].Code);
            DimensionValue[DimensionIndex].Modify(true);
            LibraryDimension.CreateDefaultDimensionCustomer(
                DefaultDimension, Customer."No.", Dimension[DimensionIndex].Code, DimensionValue[DimensionIndex].Code);
            LibraryDimension.CreateDefaultDimensionVendor(
                DefaultDimension, Vendor."No.", Dimension[DimensionIndex].Code, DimensionValue[DimensionIndex].Code);
            DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, Dimension[DimensionIndex].Code, DimensionValue[DimensionIndex].Code);
        end;

        SAFTTestHelper.MockCustLedgEntry(SAFTExportHeader."Ending Date", Customer."No.", 100, 100, "Gen. Journal Document Type"::Invoice);
        SAFTTestHelper.MockVendLedgEntry(SAFTExportHeader."Ending Date", Vendor."No.", -100, -100, "Gen. Journal Document Type"::Invoice);
        GLAccount.FindFirst();
        SAFTTestHelper.MockGLEntryNoVAT(
            SAFTExportHeader."Ending Date", GLAccount."No.", GetLastUsedTransactionNo() + 1, DimensionSetID, 0, '', '', 100, 0);
    end;

    local procedure CreateTransactionCountSetup(var SAFTExportHeader: Record "SAF-T Export Header"; var GLAccount: Record "G/L Account"; var SourceCode: Record "Source Code")
    var
        SAFTMappingRange: Record "SAF-T Mapping Range";
        SAFTSourceCode: Record "SAF-T Source Code";
    begin
        SAFTTestHelper.SetupSAFT(SAFTMappingRange, SAFTMappingType::"Four Digit Standard Account", 1);
        SAFTTestHelper.MatchGLAccountsFourDigit(SAFTMappingRange.Code);
        SAFTTestHelper.CreateSAFTExportHeader(SAFTExportHeader, SAFTMappingRange.Code, Enum::"SAF-T Version"::"1.30");
        SAFTExportHeader.Validate("Split By Month", false);
        SAFTExportHeader.Modify(true);
        GLAccount.FindFirst();
        CreateTransactionCountJournal(SAFTSourceCode, false);
        LibraryERM.CreateSourceCode(SourceCode);
        SourceCode.Validate("SAF-T Source Code", SAFTSourceCode.Code);
        SourceCode.Modify(true);
    end;

    local procedure CreateTransactionCountJournal(var SAFTSourceCode: Record "SAF-T Source Code"; IncludesBlankSource: Boolean)
    begin
        SAFTSourceCode.Init();
        SAFTSourceCode.Code :=
            CopyStr(LibraryUtility.GenerateRandomCode(SAFTSourceCode.FieldNo(Code), Database::"SAF-T Source Code"), 1, MaxStrLen(SAFTSourceCode.Code));
        SAFTSourceCode.Description := SAFTSourceCode.Code;
        SAFTSourceCode.Validate("Includes No Source Code", IncludesBlankSource);
        SAFTSourceCode.Insert(true);
    end;

    local procedure CreateTransactionCountEntries(SAFTExportHeader: Record "SAF-T Export Header"; GLAccountNo: Code[20]; SourceCode: Code[10])
    var
        TransactionNo: Integer;
    begin
        TransactionNo := GetLastUsedTransactionNo() + 1;
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", 'COUNT-A', GLAccountNo, TransactionNo, 0, '', '', 0, '', SourceCode, 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", 'COUNT-A', GLAccountNo, TransactionNo + 1, 0, '', '', 0, '', SourceCode, 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date", 'COUNT-B', GLAccountNo, TransactionNo, 0, '', '', 0, '', SourceCode, 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date", 'COUNT-A', GLAccountNo, TransactionNo, 0, '', '', 0, '', SourceCode, 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Starting Date" - 1, 'OUTSIDE', GLAccountNo, TransactionNo + 2, 0, '', '', 0, '', SourceCode, 100, 0);
        SAFTTestHelper.MockGLEntry(
            SAFTExportHeader."Ending Date" + 1, 'OUTSIDE', GLAccountNo, TransactionNo + 2, 0, '', '', 0, '', SourceCode, 100, 0);
    end;

    local procedure CreateAndPostCashReceiptJnl(var GenJournalLine: Record "Gen. Journal Line"; SAFTExportHeader: Record "SAF-T Export Header")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.DeleteAll();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", GetDifferentCurrencyCode());
        Customer.Modify(true);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, Customer."No.", GenJournalLine."Bal. Account Type"::"Bank Account",
            LibraryERM.CreateBankAccountNo(), -LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Posting Date", SAFTExportHeader."Ending Date");
        GenJournalLine.Modify(true);

        BankAccount.Get(GenJournalLine."Bal. Account No.");
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        BankAccountPostingGroup.Validate("G/L Account No.", LibraryERM.CreateGLAccountNo());
        BankAccountPostingGroup.Modify(true);

        CashReceiptJournal.OpenEdit();
        CashReceiptJournal.Post.Invoke();
    end;

    local procedure LoadAnalysisExportFiles(SAFTExportHeader: Record "SAF-T Export Header"; var TempMasterXMLBuffer: Record "XML Buffer" temporary; var TempGLEntryXMLBuffer: Record "XML Buffer" temporary)
    var
        SAFTExportLine: Record "SAF-T Export Line";
    begin
        SAFTExportLine.SetRange("Master Data", true);
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Completed);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        Assert.RecordCount(SAFTExportLine, 1);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempMasterXMLBuffer, SAFTExportLine);
        Assert.IsTrue(
            TempMasterXMLBuffer.FindNodesByXPath(
                TempMasterXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:Customers/n1:Customer/n1:PartyInfo/n1:CurrencyCode'),
            'Customer PartyInfo metadata was not exported.');
        Assert.RecordCount(TempMasterXMLBuffer, 1);
        Assert.IsTrue(
            TempMasterXMLBuffer.FindNodesByXPath(
                TempMasterXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:Suppliers/n1:Supplier/n1:PartyInfo/n1:CurrencyCode'),
            'Supplier PartyInfo metadata was not exported.');
        Assert.RecordCount(TempMasterXMLBuffer, 1);

        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        Assert.RecordCount(SAFTExportLine, 1);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempGLEntryXMLBuffer, SAFTExportLine);
        Assert.IsTrue(
            TempGLEntryXMLBuffer.FindNodesByXPath(
                TempGLEntryXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line'),
            'The G/L entry carrying dimensions was not exported.');
        Assert.RecordCount(TempGLEntryXMLBuffer, 1);
    end;

    local procedure CountXMLTransactions(var TempXMLBuffer: Record "XML Buffer" temporary): Integer
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction');
        exit(TempXMLBuffer.Count());
    end;

    local procedure CountSelectionTransactions(ExportID: Integer) NumberOfTransactions: Integer
    var
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, ExportID);
        repeat
            Assert.AreEqual(SAFTExportLine.Status::Completed, SAFTExportLine.Status, 'Every export part must be completed.');
            SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
            NumberOfTransactions += CountXMLTransactions(TempXMLBuffer);
        until SAFTExportLine.Next() = 0;
    end;

    local procedure GetPostedDocTransactionNo(DocumentNo: Code[20]): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindLast();
        exit(GLEntry."Transaction No.");
    end;

    local procedure GetLastUsedTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetCurrentKey("Transaction No.");
        GLEntry.FindLast();
        exit(GLEntry."Transaction No.");
    end;

    local procedure VerifyHeaderStructure(var TempXMLBuffer: Record "XML Buffer" temporary; SAFTExportLine: Record "SAF-T Export Line")
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SAFTExportHeader: Record "SAF-T Export Header";
        ApplicationSystemConstants: Codeunit "Application System Constants";

    begin
        SAFTTestHelper.FindSAFTHeaderElement(TempXMLBuffer);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AuditFileVersion', '1.30');
        CompanyInformation.Get();
        GeneralLedgerSetup.Get();
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AuditFileCountry', CompanyInformation."Country/Region Code");
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AuditFileDateCreated', SAFTTestHelper.FormatDate(Today()));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:SoftwareCompanyName', 'Microsoft');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:SoftwareID', 'Microsoft Dynamics 365 Business Central');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:SoftwareVersion', ApplicationSystemConstants.ApplicationVersion());
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Company');
        VerifyCompanyStructure(TempXMLBuffer, CompanyInformation);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:DefaultCurrencyCode', GeneralLedgerSetup."LCY Code");
        SAFTExportHeader.Get(SAFTExportLine.ID);
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:SelectionCriteria');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:PeriodStart', format(Date2DMY(SAFTExportHeader."Starting Date", 2)));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:PeriodStartYear', format(Date2DMY(SAFTExportHeader."Starting Date", 3)));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:PeriodEnd', format(Date2DMY(SAFTExportHeader."Ending Date", 2)));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:PeriodEndYear', format(Date2DMY(SAFTExportHeader."Ending Date", 3)));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TaxAccountingBasis', 'A');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:UserID', UserId());
    end;

    local procedure VerifyMasterDataStructureWithStdAccMapping(var TempXMLBuffer: Record "XML Buffer" temporary; MappingRangeCode: Code[20]; NumberOfMasterDataRecords: Integer)
    begin
        VerifyGeneralLedgerAccountsWithStdAccMapping(TempXMLBuffer, MappingRangeCode, NumberOfMasterDataRecords);
        VerifyCustomers(TempXMLBuffer, MappingRangeCode, NumberOfMasterDataRecords);
        VerifyVendors(TempXMLBuffer, MappingRangeCode, NumberOfMasterDataRecords);
        VerifyVATPostingSetup(TempXMLBuffer);
        VerifyDimensions(TempXMLBuffer);
    end;

    local procedure VerifyMasterDataBalance(var TempXMLBuffer: Record "XML Buffer" temporary; BalanceXMLNodeName: Text; ExpectedAmount: Decimal)
    var
        AmountText: Text;
    begin
        AmountText := SAFTTestHelper.FormatAmount(ExpectedAmount);
        SAFTTestHelper.AssertCurrentValue(
            TempXMLBuffer, StrSubstNo('/n1:AuditFile/n1:MasterFiles/n1:GeneralLedgerAccounts/n1:Account/n1:%1', BalanceXMLNodeName), AmountText);
        SAFTTestHelper.AssertCurrentValue(
            TempXMLBuffer, StrSubstNo('/n1:AuditFile/n1:MasterFiles/n1:Customers/n1:Customer/n1:%1', BalanceXMLNodeName), AmountText);
        SAFTTestHelper.AssertCurrentValue(
            TempXMLBuffer, StrSubstNo('/n1:AuditFile/n1:MasterFiles/n1:Suppliers/n1:Supplier/n1:%1', BalanceXMLNodeName), AmountText);
    end;

    local procedure VerifyGeneralLedgerAccountsWithStdAccMapping(var TempXMLBuffer: Record "XML Buffer" temporary; MappingRangeCode: Code[20]; NumberOfMasterDataRecords: Integer)
    var
        GLAccount: Record "G/L Account";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        i: Integer;
    begin
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:MasterFiles');
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:GeneralLedgerAccounts');
        GLAccount.FindSet();
        SAFTMappingRange.Get(MappingRangeCode);
        // Income statement accounts
        for i := 1 to NumberOfMasterDataRecords do begin
            SAFTGLAccountMapping.Get(MappingRangeCode, GLAccount."No.");
            VerifyAccountHeader(TempXMLBuffer, GLAccount, SAFTGLAccountMapping);
            VerifyAccountAmounts(TempXMLBuffer, GLAccount, SAFTMappingRange, 'n1:OpeningDebitBalance', 'n1:ClosingDebitBalance');
            GLAccount.Next();
        end;
        // Balance sheet accounts (all but last)
        for i := 1 to (NumberOfMasterDataRecords - 1) do begin
            SAFTGLAccountMapping.Get(MappingRangeCode, GLAccount."No.");
            VerifyAccountHeader(TempXMLBuffer, GLAccount, SAFTGLAccountMapping);
            VerifyAccountAmounts(TempXMLBuffer, GLAccount, SAFTMappingRange, 'n1:OpeningCreditBalance', 'n1:ClosingDebitBalance');
            GLAccount.Next();
        end;
        // The last account has no entries but still exports.
        SAFTGLAccountMapping.Get(MappingRangeCode, GLAccount."No.");
        VerifyAccountHeader(TempXMLBuffer, GLAccount, SAFTGLAccountMapping);
        VerifyAccountAmounts(TempXMLBuffer, GLAccount, SAFTMappingRange, 'n1:OpeningCreditBalance', 'n1:ClosingCreditBalance');
    end;

    local procedure VerifyGeneralLedgerAccountsWithIncomeStatementMapping(var TempXMLBuffer: Record "XML Buffer" temporary; MappingRangeCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
    begin
        Assert.IsTrue(TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:GeneralLedgerAccounts/n1:Account'), 'No G/L accounts exported.');
        GLAccount.FindSet();
        repeat
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountID', GLAccount."No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountDescription', GLAccount.Name);
            SAFTGLAccountMapping.Get(MappingRangeCode, GLAccount."No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:GroupingCategory', SAFTGLAccountMapping."Category No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:GroupingCode', SAFTGLAccountMapping."No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountType', 'GL');
            SAFTTestHelper.FindNextElement(TempXMLBuffer); // skip opening balance check
            SAFTTestHelper.FindNextElement(TempXMLBuffer); // skip closing balance check
            SAFTTestHelper.FindNextElement(TempXMLBuffer); // skip n1:Account
        until GLAccount.Next() = 0;
    end;

    local procedure VerifyGroupingCategoryValue(var TempXMLBuffer: Record "XML Buffer" temporary; MappingRangeCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
    begin
        Assert.IsTrue(TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:GeneralLedgerAccounts/n1:Account'), 'No G/L accounts exported.');
        GLAccount.FindSet();
        repeat
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountID', GLAccount."No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountDescription', GLAccount.Name);
            SAFTGLAccountMapping.Get(MappingRangeCode, GLAccount."No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:GroupingCategory', GetExpectedGroupingCategory(SAFTGLAccountMapping));
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:GroupingCode', SAFTGLAccountMapping."No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountType', 'GL');
            SAFTTestHelper.FindNextElement(TempXMLBuffer);
            SAFTTestHelper.FindNextElement(TempXMLBuffer);
            SAFTTestHelper.FindNextElement(TempXMLBuffer);
        until GLAccount.Next() = 0;
    end;

    local procedure GetExpectedGroupingCategory(SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping"): Text
    var
        SAFTMappingCategory: Record "SAF-T Mapping Category";
    begin
        SAFTMappingCategory.Get(SAFTGLAccountMapping."Mapping Type", SAFTGLAccountMapping."Category No.");
        exit(SAFTMappingCategory."Extended No.");
    end;

    local procedure VerifyGroupingCodeValue(var TempXMLBuffer: Record "XML Buffer" temporary; MappingRangeCode: Code[20]; TargetGLAccountNo: Code[20]; ExpectedCodeValue: Text)
    var
        GLAccount: Record "G/L Account";
        SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping";
        GroupingCodeValue: Text;
    begin
        Assert.IsTrue(TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:GeneralLedgerAccounts/n1:Account'), 'No G/L accounts exported.');
        GLAccount.FindSet();
        repeat
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountID', GLAccount."No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountDescription', GLAccount.Name);
            SAFTGLAccountMapping.Get(MappingRangeCode, GLAccount."No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:GroupingCategory', SAFTGLAccountMapping."Category No.");
            if GLAccount."No." = TargetGLAccountNo then
                GroupingCodeValue := ExpectedCodeValue
            else
                GroupingCodeValue := SAFTGLAccountMapping."No.";
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:GroupingCode', GroupingCodeValue);
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountType', 'GL');
            SAFTTestHelper.FindNextElement(TempXMLBuffer);
            SAFTTestHelper.FindNextElement(TempXMLBuffer);
            SAFTTestHelper.FindNextElement(TempXMLBuffer);
        until GLAccount.Next() = 0;
    end;

    local procedure VerifyAccountHeader(var TempXMLBuffer: Record "XML Buffer" temporary; GLAccount: Record "G/L Account"; SAFTGLAccountMapping: Record "SAF-T G/L Account Mapping")
    begin
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Account');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountID', GLAccount."No.");
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountDescription', GLAccount.Name);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:GroupingCategory', SAFTGLAccountMapping."Category No.");
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:GroupingCode', SAFTGLAccountMapping."No.");
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountType', 'GL');
    end;

    local procedure VerifyAccountAmounts(var TempXMLBuffer: Record "XML Buffer" temporary; GLAccount: Record "G/L Account"; SAFTMappingRange: Record "SAF-T Mapping Range"; OpeningBalanceNodeText: Text; ClosingBalanceNodeText: Text)
    begin
        GLAccount.SetRange("Date Filter", 0D, ClosingDate(SAFTMappingRange."Starting Date" - 1));
        GLAccount.CalcFields("Net Change");
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, OpeningBalanceNodeText, SAFTTestHelper.FormatAmount(GLAccount."Net Change"));
        GLAccount.SetRange("Date Filter", 0D, ClosingDate(SAFTMappingRange."Ending Date"));
        GLAccount.CalcFields("Net Change");
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, ClosingBalanceNodeText, SAFTTestHelper.FormatAmount(GLAccount."Net Change"));
    end;

    local procedure VerifyCustomers(var TempXMLBuffer: Record "XML Buffer" temporary; MappingRangeCode: Code[20]; NumberOfMasterDataRecords: Integer)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerBankAccount: Record "Customer Bank Account";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        i: Integer;
    begin
        Customer.FindSet();
        SAFTMappingRange.Get(MappingRangeCode);
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Customers');
        for i := 1 to NumberOfMasterDataRecords do begin
            SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Customer');
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:RegistrationNumber', Customer."VAT Registration No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Name', SAFTTestHelper.CombineWithSpace(Customer.Name, Customer."Name 2"));
            VerifyAddress(
                TempXMLBuffer, SAFTTestHelper.CombineWithSpace(Customer.Address, Customer."Address 2"),
                Customer.City, Customer."Post Code", Customer."Country/Region Code");
            VerifyContactSimple(
                TempXMLBuffer, Customer.Contact, Customer."Phone No.", Customer."Fax No.", Customer."E-Mail", Customer."Home Page");
            CustomerBankAccount.SetRange("Customer No.", Customer."No.");
            CustomerBankAccount.FindFirst();
            VerifyNormalBankAccount(
                TempXMLBuffer, CustomerBankAccount."Bank Account No.", CustomerBankAccount.Name,
                CustomerBankAccount."Bank Clearing Code", CustomerBankAccount."SWIFT Code");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:CustomerID', Customer."No.");
            CustomerPostingGroup.Get(Customer."Customer Posting Group");
            TempXMLBuffer.Next(); // skip BalanceAccount xml node
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountID', CustomerPostingGroup."Receivables Account");
            Customer.SetRange("Date Filter", 0D, closingdate(SAFTMappingRange."Starting Date" - 1));
            Customer.CalcFields("Net Change (LCY)");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:OpeningCreditBalance', SAFTTestHelper.FormatAmount(Customer."Net Change (LCY)"));
            Customer.SetRange("Date Filter", 0D, closingdate(SAFTMappingRange."Ending Date"));
            Customer.CalcFields("Net Change (LCY)");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:ClosingDebitBalance', SAFTTestHelper.FormatAmount(Customer."Net Change (LCY)"));
            VerifyPartyInfo(TempXMLBuffer, Customer."Payment Terms Code", database::Customer, Customer."No.");
            Customer.Next();
        end;
    end;

    local procedure VerifyVendors(var TempXMLBuffer: Record "XML Buffer" temporary; MappingRangeCode: Code[20]; NumberOfMasterDataRecords: Integer)
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
        VendorBankAccount: Record "Vendor Bank Account";
        SAFTMappingRange: Record "SAF-T Mapping Range";
        i: Integer;
    begin
        Vendor.FindSet();
        SAFTMappingRange.Get(MappingRangeCode);
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Suppliers');
        for i := 1 to NumberOfMasterDataRecords do begin
            SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Supplier');
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:RegistrationNumber', Vendor."VAT Registration No.");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Name', SAFTTestHelper.CombineWithSpace(Vendor.Name, Vendor."Name 2"));
            VerifyAddress(
                TempXMLBuffer, SAFTTestHelper.CombineWithSpace(Vendor.Address, Vendor."Address 2"),
                Vendor.City, Vendor."Post Code", Vendor."Country/Region Code");
            VerifyContactSimple(
                TempXMLBuffer, Vendor.Contact, Vendor."Phone No.", Vendor."Fax No.", Vendor."E-Mail", Vendor."Home Page");
            VendorBankAccount.SetRange("Vendor No.", Vendor."No.");
            VendorBankAccount.FindFirst();
            VerifyNormalBankAccount(
                TempXMLBuffer, VendorBankAccount."Bank Account No.", VendorBankAccount.Name,
                VendorBankAccount."Bank Clearing Code", VendorBankAccount."SWIFT Code");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:SupplierID', Vendor."No.");
            VendorPostingGroup.Get(Vendor."Vendor Posting Group");
            TempXMLBuffer.Next(); // skip BalanceAccount xml node
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountID', VendorPostingGroup."Payables Account");
            Vendor.SetRange("Date Filter", 0D, closingdate(SAFTMappingRange."Starting Date" - 1));
            Vendor.CalcFields("Net Change (LCY)");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:OpeningCreditBalance', SAFTTestHelper.FormatAmount(Vendor."Net Change (LCY)"));
            Vendor.SetRange("Date Filter", 0D, closingdate(SAFTMappingRange."Ending Date"));
            Vendor.CalcFields("Net Change (LCY)");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:ClosingCreditBalance', SAFTTestHelper.FormatAmount(Vendor."Net Change (LCY)"));
            VerifyPartyInfo(TempXMLBuffer, Vendor."Payment Terms Code", database::Vendor, Vendor."No.");
            Vendor.Next();
        end;
    end;

    local procedure VerifyVATPostingSetup(var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SAFTExportMgt: Codeunit "SAF-T Export Mgt.";
        NotApplicationVATCode: Code[20];
    begin
        VATPostingSetup.FindSet();
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:TaxTable');
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:TaxTableEntry');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TaxType', 'MVA');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Description', 'Merverdiavgift');
        NotApplicationVATCode := SAFTExportMgt.GetNotApplicableVATCode();
        // Verify first VAT Posting Setup with no standard tax codes
        VerifySingleVATPostingSetup(
            TempXMLBuffer, VATPostingSetup."Sales SAF-T Tax Code", VATPostingSetup.Description,
            VATPostingSetup."VAT %", NotApplicationVATCode, false, 100);
        VerifySingleVATPostingSetup(
            TempXMLBuffer, VATPostingSetup."Purchase SAF-T Tax Code", VATPostingSetup.Description,
            VATPostingSetup."VAT %", NotApplicationVATCode, false, 100);
        VATPostingSetup.Next();
        repeat
            VerifySingleVATPostingSetup(
                TempXMLBuffer, VATPostingSetup."Sales SAF-T Tax Code", VATPostingSetup.Description,
                VATPostingSetup."VAT %", VATPostingSetup."Sale VAT Reporting Code", false, 100);
            VerifySingleVATPostingSetup(
                TempXMLBuffer, VATPostingSetup."Purchase SAF-T Tax Code", VATPostingSetup.Description,
                VATPostingSetup."VAT %", VATPostingSetup."Purch. VAT Reporting Code", false, 100);
        until VATPostingSetup.Next() = 0;
    end;

    local procedure VerifyDimensions(var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.FindSet();
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:AnalysisTypeTable');
        repeat
            SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:AnalysisTypeTableEntry');
            Dimension.Get(DimensionValue."Dimension Code");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AnalysisType', Dimension."SAF-T Analysis Type");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AnalysisTypeDescription', Dimension.Name);
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AnalysisID', DimensionValue.Code);
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AnalysisIDDescription', '&amp;lt;&amp;amp;');
        until DimensionValue.Next() = 0;
    end;

    local procedure VerifySingleVATPostingSetup(var TempXMLBuffer: Record "XML Buffer" temporary; TaxCode: Integer; Description: Text; VATRate: Decimal; StandardTaxCode: Code[20]; Compensation: Boolean; DeductionRate: Decimal)
    var
        CompanyInformation: record "Company Information";
    begin
        CompanyInformation.Get();
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:TaxCodeDetails');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TaxCode', Format(TaxCode));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Description', Description);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TaxPercentage', SAFTTestHelper.FormatAmount(VATRate));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Country', CompanyInformation."Country/Region Code");
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:StandardTaxCode', StandardTaxCode);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Compensation', Format(Compensation, 0, 9));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:BaseRate', SAFTTestHelper.FormatAmount(DeductionRate));
    end;

    local procedure VerifyCompanyStructure(var TempXMLBuffer: Record "XML Buffer" temporary; CompanyInformation: Record "Company Information")
    var
        Employee: Record Employee;
        BankAccount: Record "Bank Account";
    begin
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:RegistrationNumber', CompanyInformation."VAT Registration No.");
        SAFTTestHelper.AssertElementValue(
            TempXMLBuffer, 'n1:Name', SAFTTestHelper.CombineWithSpace(CompanyInformation.Name, CompanyInformation."Name 2"));
        VerifyAddress(
            TempXMLBuffer, SAFTTestHelper.CombineWithSpace(CompanyInformation.Address, CompanyInformation."Address 2"),
            CompanyInformation.City, CompanyInformation."Post Code", CompanyInformation."Country/Region Code");
        Employee.Get(CompanyInformation."SAF-T Contact No.");
        VerifyEmployee(
            TempXMLBuffer, Employee."First Name", Employee."Last Name", Employee."Phone No.",
             Employee."Fax No.", Employee."E-Mail", Employee."Mobile Phone No.");
        VerifyTaxRegistration(TempXMLBuffer, CompanyInformation);
        VerifyIBANBankAccount(
            TempXMLBuffer, CompanyInformation.IBAN, CompanyInformation."SWIFT Code");
        BankAccount.FindFirst();
        VerifyIBANBankAccount(
            TempXMLBuffer, BankAccount.IBAN, BankAccount."SWIFT Code");
    end;

    local procedure VerifyAddress(var TempXMLBuffer: Record "XML Buffer" temporary; StreetName: Text; City: Text; PostCode: Code[20]; CountryRegionCode: Code[20])
    begin
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Address');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:StreetName', StreetName);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:City', City);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:PostalCode', PostCode);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Country', CountryRegionCode);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AddressType', 'StreetAddress');
    end;

    local procedure VerifyContactSimple(var TempXMLBuffer: Record "XML Buffer" temporary; Name: Text; PhoneNo: Text; FaxNo: Text; Email: Text; HomePage: Text)
    var
        FirstName: Text;
        LastName: Text;
    begin
        SAFTTestHelper.GetFirstAndLastNameFromContactName(FirstName, LastName, Name);
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Contact');
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:ContactPerson');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:FirstName', FirstName);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:LastName', LastName);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Telephone', PhoneNo);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Fax', FaxNo);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Email', Email);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Website', HomePage);
    end;

    local procedure VerifyEmployee(var TempXMLBuffer: Record "XML Buffer" temporary; FirstName: Text; LastName: Text; PhoneNo: Text; FaxNo: Text; Email: Text; MobilePhoneNo: Text)

    begin
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Contact');
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:ContactPerson');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:FirstName', FirstName);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:LastName', LastName);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Telephone', PhoneNo);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Fax', FaxNo);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Email', Email);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:MobilePhone', MobilePhoneNo);
    end;

    local procedure VerifyPartyInfo(var TempXMLBuffer: Record "XML Buffer" temporary; PaymentTermsCode: Code[10]; TableID: Integer; SourceNo: Code[20]);
    var
        PaymentTerms: Record "Payment Terms";
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        SAFTExportMgt: Codeunit "SAF-T Export Mgt.";
    begin
        PaymentTerms.Get(PaymentTermsCode);
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:PartyInfo');
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:PaymentTerms');
        SAFTTestHelper.AssertElementValue(
            TempXMLBuffer, 'n1:Days', format(CalcDate(PaymentTerms."Due Date Calculation", WorkDate()) - WorkDate()));
        SAFTTestHelper.AssertElementValue(
            TempXMLBuffer, 'n1:CashDiscountDays', format(CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()) - WorkDate()));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:CashDiscountRate', SAFTTestHelper.FormatAmount(PaymentTerms."Discount %"));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:CurrencyCode', SAFTExportMgt.GetISOCurrencyCode(''));
        DefaultDimension.SetRange("Table ID", TableID);
        DefaultDimension.SetRange("No.", SourceNo);
        DefaultDimension.FindSet();
        repeat
            SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Analysis');
            Dimension.get(DefaultDimension."Dimension Code");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AnalysisType', Dimension."SAF-T Analysis Type");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AnalysisID', DefaultDimension."Dimension Value Code");
        until DefaultDimension.Next() = 0;
    end;

    local procedure VerifyTaxRegistration(var TempXMLBuffer: Record "XML Buffer" temporary; CompanyInformation: Record "Company Information")
    begin
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:TaxRegistration');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TaxRegistrationNumber', CompanyInformation."VAT Registration No.");
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TaxAuthority', 'Skatteetaten');
    end;

    local procedure VerifyIBANBankAccount(var TempXMLBuffer: Record "XML Buffer" temporary; IBAN: Text; SWIFT: Text)
    var
        SAFTExportMgt: Codeunit "SAF-T Export Mgt.";
    begin
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:BankAccount');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:IBANNumber', IBAN);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:BIC', SWIFT);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:CurrencyCode', SAFTExportMgt.GetISOCurrencyCode(''));
    end;

    local procedure VerifyNormalBankAccount(var TempXMLBuffer: Record "XML Buffer" temporary; BankAccountNumber: Text[30]; BankAccName: Text; SortCode: Text; SWIFT: Text)
    var
        SAFTExportMgt: Codeunit "SAF-T Export Mgt.";
    begin
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:BankAccount');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:BankAccountNumber', BankAccountNumber);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:BankAccountName', BankAccName);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:SortCode', SortCode);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:BIC', SWIFT);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:CurrencyCode', SAFTExportMgt.GetISOCurrencyCode(''));
    end;

    local procedure VerifyXMLFileHasHeader(var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        SAFTTestHelper.FindSAFTHeaderElement(TempXMLBuffer);
        Assert.RecordCount(TempXMLBuffer, 1);
    end;

    local procedure VerifyGLEntriesGroupedBySAFTSourceCode(var TempXMLBuffer: Record "XML Buffer" temporary; var TempSAFTSourceCode: Record "SAF-T Source Code" temporary; ExpectedEntriesInTransactionNumber: Integer; StartingDate: Date; EndingDate: Date; SAFTAnalysisType: Code[9]; DimValueCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
        SourceCode: Record "Source Code";
        NumberOfTransactions: Integer;
    begin
        GLEntry.SetCurrentKey("Document No.", "Posting Date");
        GLEntry.SetRange("Posting Date", StartingDate, EndingDate);
        NumberOfTransactions := CountXMLTransactions(TempXMLBuffer);
        TempXMLBuffer.Reset();
        Assert.IsTrue(TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries'), 'No G/L entries exported.');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:NumberOfEntries', Format(NumberOfTransactions));
        GLEntry.CalcSums("Debit Amount", "Credit Amount");
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TotalDebit', SAFTTestHelper.FormatAmount(GLEntry."Debit Amount"));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TotalCredit', SAFTTestHelper.FormatAmount(GLEntry."Credit Amount"));
        TempSAFTSourceCode.FindSet();
        repeat
            SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Journal');
            SourceCode.SetRange("SAF-T Source Code", TempSAFTSourceCode.Code);
            SourceCode.FindFirst();
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:JournalID', TempSAFTSourceCode.Code);
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Description', TempSAFTSourceCode.Description);
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Type', TempSAFTSourceCode.Code);
            GLEntry.SetRange("Source Code", SourceCode.Code);
            GLEntry.FindSet();
            VerifyGLEntriesGroupedByPostingDateAndDocNo(TempXMLBuffer, GLEntry, ExpectedEntriesInTransactionNumber, SAFTAnalysisType, DimValueCode);
            GLEntry.SetRange("Source Code");
        until TempSAFTSourceCode.Next() = 0;
    end;

    local procedure VerifyGLEntriesGroupedByPostingDateAndDocNo(var TempXMLBuffer: Record "XML Buffer" temporary; var GLEntry: Record "G/L Entry"; ExpectedEntriesInTransactionNumber: Integer; SAFTAnalysisType: Code[9]; DimValueCode: Code[20])
    var
        ActualEntriesInTransactionNumber: Integer;
        Step: Integer;
    begin
        repeat
            SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Transaction');
            GLEntry.SetRange("Posting Date", GLEntry."Posting Date");
            GLEntry.SetRange("Document No.", GLEntry."Document No.");
            SAFTTestHelper.AssertElementValue(
                TempXMLBuffer, 'n1:TransactionID',
                GLEntry."Document No." + Format(GLEntry."Posting Date", 0, '<Day,2><Month,2><Year,2>'));
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Period', format(Date2DMY(GLEntry."Posting Date", 2)));
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:PeriodYear', format(Date2DMY(GLEntry."Posting Date", 3)));
            SAFTTestHelper.AssertElementValue(
                TempXMLBuffer, 'n1:TransactionDate', SAFTTestHelper.FormatDate(GLEntry."Document Date"));
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:SourceID', GLEntry."User ID");
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TransactionType', Format(GLEntry."Document Type"));
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Description', GLEntry.Description);
            SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:BatchID', Format(GLEntry."Transaction No."));
            SAFTTestHelper.AssertElementValue(
                TempXMLBuffer, 'n1:SystemEntryDate', SAFTTestHelper.FormatDate(DT2Date(GLEntry."Last Modified DateTime")));
            SAFTTestHelper.AssertElementValue(
                TempXMLBuffer, 'n1:GLPostingDate', SAFTTestHelper.FormatDate(GLEntry."Posting Date"));
            Step := 1;
            ActualEntriesInTransactionNumber := 0;
            while Step = 1 do begin
                VerifySingleGLEntry(TempXMLBuffer, GLEntry, SAFTAnalysisType, DimValueCode);
                Step := GLEntry.Next();
                ActualEntriesInTransactionNumber += 1;
            end;
            GLEntry.SetRange("Posting Date");
            GLEntry.SetRange("Document No.");
            Assert.AreEqual(
                ExpectedEntriesInTransactionNumber, ActualEntriesInTransactionNumber, 'Number of transactions not expected');
        until GLEntry.Next() = 0;
    end;

    local procedure VerifySingleGLEntry(var TempXMLBuffer: Record "XML Buffer" temporary; var GLEntry: Record "G/L Entry"; SAFTAnalysisType: Code[9]; DimValueCode: Code[20])
    var
        SAFTExportMgt: Codeunit "SAF-T Export Mgt.";
        AmountXMLNode: Text;
        Amount: Decimal;
    begin
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Line');
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:RecordID');
        SAFTTestHelper.AssertCurrentElementValue(TempXMLBuffer, 'n1:RecordID', Format(GLEntry."Entry No."));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AccountID', GLEntry."G/L Account No.");
        VerifyDimensions(TempXMLBuffer, SAFTAnalysisType, DimValueCode);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:SourceDocumentID', GLEntry."Document No.");
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Description', GLEntry.Description);
        SAFTExportMgt.GetAmountInfoFromGLEntry(AmountXMLNode, Amount, GLEntry);
        VerifyAmountInfo(TempXMLBuffer, AmountXMLNode, Amount);
        VerifySalesVATEntry(TempXMLBuffer, GLEntry);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:ReferenceNumber', GLEntry."External Document No.");
    end;

    local procedure VerifySalesVATEntry(var TempXMLBuffer: Record "XML Buffer" temporary; GLEntry: Record "G/L Entry")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        GLEntryVATEntryLinkRec: Record "G/L Entry - VAT Entry Link";
    begin
        GLEntry.TestField("VAT Bus. Posting Group");
        GLEntry.TestField("VAT Prod. Posting Group");
        VATPostingSetup.Get(GLEntry."VAT Bus. Posting Group", GLEntry."VAT Prod. Posting Group");
        GLEntryVATEntryLinkRec.SetRange("G/L Entry No.", GLEntry."Entry No.");
        GLEntryVATEntryLinkRec.FindFirst();
        VATEntry.Get(GLEntryVATEntryLinkRec."VAT Entry No.");

        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:TaxInformation');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:TaxType', 'MVA');
        SAFTTestHelper.AssertElementValue(
            TempXMLBuffer, 'n1:TaxCode',
            Format(GetSAFTTaxCodeFromVATPostinSetup(VATPostingSetup, VATEntry.Type)));
        SAFTTestHelper.AssertElementValue(
            TempXMLBuffer, 'n1:TaxPercentage', SAFTTestHelper.FormatAmount(VATPostingSetup."VAT %"));
        SAFTTestHelper.AssertElementValue(
            TempXMLBuffer, 'n1:TaxBase', SAFTTestHelper.FormatAmount(abs(VATEntry.Base)));
        VerifyAmountInfo(TempXMLBuffer, 'DebitTaxAmount', abs(VATEntry.Amount));
    end;

    local procedure VerifyXMLNodeOfMasterFile(SAFTExportHeader: Record "SAF-T Export Header"; XmlName: Text[250]; XmlValue: Text[250]);
    var
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Completed);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        TempXMLBuffer.SetFilter(Name, XmlName);
        TempXMLBuffer.FindFirst();
        TempXMLBuffer.TestField(Value, XmlValue);
    END;

    local procedure VerifyNonExistingXMLNodeOfMasterFile(SAFTExportHeader: Record "SAF-T Export Header"; XmlName: Text[250]; XmlValue: Text[250]);
    var
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        SAFTExportLine.SetRange(Status, SAFTExportLine.Status::Completed);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        TempXMLBuffer.SetRange(Name, XmlName);
        TempXMLBuffer.SetRange(Value, XmlValue);
        Assert.RecordIsEmpty(TempXMLBuffer);
    END;

    local procedure GetSAFTTaxCodeFromVATPostinSetup(VATPostingSetup: Record "VAT Posting Setup"; EntryType: Integer): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        case EntryType of
            VATEntry.Type::Purchase:
                exit(VATPostingSetup."Purchase SAF-T Tax Code");
            VATEntry.Type::Sale:
                exit(VATPostingSetup."Sales SAF-T Tax Code");
        end;
    end;

    local procedure VerifyChildElementsCount(var TempChildXMLBuffer: Record "XML Buffer" temporary; var TempXMLBuffer: Record "XML Buffer" temporary; ExpectedCount: Integer)
    begin
        TempXMLBuffer.FindChildElements(TempChildXMLBuffer);
        Assert.RecordCount(TempChildXMLBuffer, ExpectedCount);
    end;

    local procedure VerifyDimensions(var TempXMLBuffer: Record "XML Buffer" temporary; SAFTAnalysisType: Code[9]; DimValueCode: Code[20])
    begin
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:Analysis');
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AnalysisType', SAFTAnalysisType);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:AnalysisID', DimValueCode);
    end;

    local procedure VerifyAmountInfo(var TempXMLBuffer: Record "XML Buffer" temporary; AmountXMLNode: Text; Amount: Decimal)
    begin
        SAFTTestHelper.AssertElementName(TempXMLBuffer, 'n1:' + AmountXMLNode);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(Amount));
    end;

    local procedure VerifyCurrencyAmountInfo(var TempXMLBuffer: Record "XML Buffer" temporary; CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; ExchangeRate: Decimal)
    begin
        SAFTTestHelper.AssertCurrentElementValue(TempXMLBuffer, 'n1:Amount', SAFTTestHelper.FormatAmount(AmountLCY));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:CurrencyCode', CurrencyCode);
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:CurrencyAmount', SAFTTestHelper.FormatAmount(Amount));
        SAFTTestHelper.AssertElementValue(TempXMLBuffer, 'n1:ExchangeRate', SAFTTestHelper.FormatAmount(ExchangeRate));
    end;

    local procedure VerifyAuditAndSoftwareVersions(var TempXMLBuffer: Record "XML Buffer" temporary)
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
    begin
        TempXMLBuffer.Reset();
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:Header/n1:AuditFileVersion'),
            'AuditFileVersion was not exported.');
        Assert.RecordCount(TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(TempXMLBuffer, 'n1:AuditFileVersion', '1.30');
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:Header/n1:SoftwareVersion'),
            'SoftwareVersion was not exported.');
        Assert.RecordCount(TempXMLBuffer, 1);
        SAFTTestHelper.AssertCurrentElementValue(
            TempXMLBuffer, 'n1:SoftwareVersion', ApplicationSystemConstants.ApplicationVersion());
    end;

    local procedure VerifyNoAnalysisOutput(var TempXMLBuffer: Record "XML Buffer" temporary)
    begin
        TempXMLBuffer.Reset();
        TempXMLBuffer.SetFilter(Name, 'AnalysisTypeTable|AnalysisTypeTableEntry|Analysis');
        Assert.RecordCount(TempXMLBuffer, 0);
        TempXMLBuffer.Reset();
    end;

    local procedure VerifySelectedAnalysisTypeTable(var TempXMLBuffer: Record "XML Buffer" temporary; Dimension: Record Dimension; ExpectedCount: Integer)
    var
        DimensionValue: Record "Dimension Value";
        TempChildXMLBuffer: Record "XML Buffer" temporary;
    begin
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:MasterFiles/n1:AnalysisTypeTable'),
            'Selected analysis table was not exported.');
        Assert.RecordCount(TempXMLBuffer, 1);
        TempXMLBuffer.FindChildElements(TempXMLBuffer);
        Assert.RecordCount(TempXMLBuffer, ExpectedCount);
        DimensionValue.SetRange("Dimension Code", Dimension.Code);
        DimensionValue.FindSet();
        repeat
            SAFTTestHelper.AssertCurrentElementName(TempXMLBuffer, 'n1:AnalysisTypeTableEntry');
            VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
            SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:AnalysisType', Dimension."SAF-T Analysis Type");
            SAFTTestHelper.AssertElementValue(TempChildXMLBuffer, 'n1:AnalysisTypeDescription', Dimension.Name);
            SAFTTestHelper.AssertElementValue(TempChildXMLBuffer, 'n1:AnalysisID', DimensionValue.Code);
            SAFTTestHelper.AssertElementValue(TempChildXMLBuffer, 'n1:AnalysisIDDescription', DimensionValue.Name);
            TempXMLBuffer.Next();
        until DimensionValue.Next() = 0;
    end;

    local procedure VerifyAnalysisReferences(var TempXMLBuffer: Record "XML Buffer" temporary; XPath: Text; AnalysisType: Code[9]; AnalysisID: Code[20]; ExpectedCount: Integer)
    var
        TempChildXMLBuffer: Record "XML Buffer" temporary;
    begin
        TempXMLBuffer.Reset();
        Assert.IsTrue(TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, XPath), 'Selected analysis references were not exported.');
        Assert.RecordCount(TempXMLBuffer, ExpectedCount);
        repeat
            VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 2);
            SAFTTestHelper.AssertCurrentElementValue(TempChildXMLBuffer, 'n1:AnalysisType', AnalysisType);
            SAFTTestHelper.AssertElementValue(TempChildXMLBuffer, 'n1:AnalysisID', AnalysisID);
        until TempXMLBuffer.Next() = 0;
    end;

    local procedure VerifySelectionTransactionCount(SAFTExportHeader: Record "SAF-T Export Header"; ExpectedFiles: Integer; ExpectedTransactions: Integer; ExpectedLines: Integer)
    var
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
        NumberOfTransactions: Integer;
        NumberOfLines: Integer;
    begin
        NumberOfTransactions := CountSelectionTransactions(SAFTExportHeader.ID);
        Assert.AreEqual(ExpectedTransactions, NumberOfTransactions, 'Unexpected number of generated XML transactions.');
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, SAFTExportHeader.ID);
        Assert.RecordCount(SAFTExportLine, ExpectedFiles);
        repeat
            SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
            Assert.IsTrue(
                TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:NumberOfEntries'),
                'NumberOfEntries was not exported.');
            Assert.RecordCount(TempXMLBuffer, 1);
            SAFTTestHelper.AssertCurrentElementValue(TempXMLBuffer, 'n1:NumberOfEntries', Format(NumberOfTransactions));
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line');
            NumberOfLines += TempXMLBuffer.Count();
        until SAFTExportLine.Next() = 0;
        Assert.AreEqual(ExpectedLines, NumberOfLines, 'G/L lines must not be lost or duplicated across journals or parts.');
    end;

    local procedure VerifyTransactionCountJournals(ExportID: Integer; FirstJournalCode: Code[9]; SecondJournalCode: Code[9])
    var
        SAFTExportLine: Record "SAF-T Export Line";
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        SAFTExportLine.SetRange("Master Data", false);
        SAFTTestHelper.FindSAFTExportLine(SAFTExportLine, ExportID);
        SAFTTestHelper.LoadXMLBufferFromSAFTExportLine(TempXMLBuffer, SAFTExportLine);
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:JournalID'),
            'Expected journals were not exported.');
        Assert.RecordCount(TempXMLBuffer, 2);
        TempXMLBuffer.SetRange(Value, FirstJournalCode);
        Assert.RecordCount(TempXMLBuffer, 1);
        TempXMLBuffer.SetRange(Value, SecondJournalCode);
        Assert.RecordCount(TempXMLBuffer, 1);
    end;

    local procedure VerifyCreditCurrencyAmounts(var TempXMLBuffer: Record "XML Buffer" temporary; CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; ExchangeRate: Decimal)
    var
        TempChildXMLBuffer: Record "XML Buffer" temporary;
    begin
        Assert.IsTrue(
            TempXMLBuffer.FindNodesByXPath(
                TempXMLBuffer, '/n1:AuditFile/n1:GeneralLedgerEntries/n1:Journal/n1:Transaction/n1:Line/n1:CreditAmount'),
            'CreditAmount nodes were not found.');
        Assert.RecordCount(TempXMLBuffer, 2);
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, CurrencyCode, Amount, AmountLCY, ExchangeRate);
        TempXMLBuffer.Next();
        VerifyChildElementsCount(TempChildXMLBuffer, TempXMLBuffer, 4);
        VerifyCurrencyAmountInfo(TempChildXMLBuffer, CurrencyCode, Amount, AmountLCY, ExchangeRate);
    end;

    local procedure CreateAndPostPaymentJnl(
        var GenJournalLine: array[3] of Record "Gen. Journal Line";
        SAFTExportHeader: Record "SAF-T Export Header")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        PaymentJournal: TestPage "Payment Journal";
    begin
        CreatePaymentJournalBatch(GenJournalBatch);

        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Currency Code" := GetDifferentCurrencyCode();
        Vendor.Modify(true);

        LibraryJournals.CreateGenJournalLine(
            GenJournalLine[1], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[1]."Document Type"::Payment,
            GenJournalLine[1]."Account Type"::Vendor, Vendor."No.", GenJournalLine[1]."Bal. Account Type"::"G/L Account",
            '', LibraryRandom.RandInt(100));
        GenJournalLine[1].Validate("Posting Date", SAFTExportHeader."Ending Date");
        GenJournalLine[1].Modify(true);

        LibraryJournals.CreateGenJournalLine(
            GenJournalLine[2], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[2]."Document Type"::Payment,
            GenJournalLine[2]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), GenJournalLine[2]."Bal. Account Type"::"G/L Account",
            '', LibraryRandom.RandInt(100));
        GenJournalLine[2]."Document No." := GenJournalLine[1]."Document No.";
        GenJournalLine[2].Validate("Posting Date", SAFTExportHeader."Ending Date");
        GenJournalLine[2].Modify(true);

        LibraryJournals.CreateGenJournalLine(
            GenJournalLine[3], GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine[3]."Document Type"::Payment,
            GenJournalLine[3]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), GenJournalLine[3]."Bal. Account Type"::"G/L Account",
            '', -(GenJournalLine[1]."Amount (LCY)" + GenJournalLine[2]."Amount (LCY)"));
        GenJournalLine[3]."Document No." := GenJournalLine[1]."Document No.";
        GenJournalLine[3].Validate("Posting Date", SAFTExportHeader."Ending Date");
        GenJournalLine[3].Modify(true);

        PaymentJournal.OpenEdit();
        PaymentJournal.Post.Invoke();
    end;

    local procedure CreatePaymentJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.DeleteAll();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure GetDifferentCurrencyCode(): Code[10]
    begin
        exit(LibraryERM.CreateCurrencyWithRandomExchRates());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    procedure CaptureConfirmationHandler(Question: Text; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
