codeunit 144006 "UT REP VAT 2010"
{
    // 1. Purpose of the test is to verify EC Sales List Report for Seperate Lines and Third Party Trade = True.
    // 2. Purpose of the test is to verify EC Sales List Report for Column with Amount and Third Party Trade = False.
    // 3. Purpose of the test is to verify EC Sales List Report for Error for invalid Date Filter.
    // 
    // Covers Test Cases for WI - 339788
    // -----------------------------------------------------------------------
    // Test Function Name                                              TFS ID
    // -----------------------------------------------------------------------
    // RequestPageOptionSeparateLinesECSalesList                       157289,157294
    // RequestPageOptionColumnWithAmountECSalesList                    157290,157295
    // OnPreReportECSalesList                                          157293

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        PostingDateErr: Label '%1 filter %2 must be corrected, to run the report monthly or quarterly. ', Comment = '%1:FieldCaption;%2:FieldValue';
        DateFilterCap: Label '%1..%2';
        ThirdPartyTradeCap: Label 'ThirdPartyTrade';

    [Test]
    [HandlerFunctions('SeperateLinesECSalesListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestPageOptionSeparateLinesECSalesList()
    var
        VATEntry: Record "VAT Entry";
        PrintTestValue: Option "Separate Lines","Column with Amount";
    begin
        // Purpose of the test is to verify EC Sales List Report for Seperate Lines and Third Party Trade = True.

        // Setup.
        Initialize();
        CreateVATEntry(VATEntry, true);
        LibraryVariableStorage.Enqueue(PrintTestValue::"Separate Lines");

        // Exercise.
        REPORT.Run(REPORT::"EC Sales List");

        // Verify: Verifying Third Party Trade on Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ThirdPartyTradeCap, true);
    end;

    [Test]
    [HandlerFunctions('SeperateLinesECSalesListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure RequestPageOptionColumnWithAmountECSalesList()
    var
        VATEntry: Record "VAT Entry";
        PrintTestValue: Option "Separate Lines","Column with Amount";
    begin
        // Purpose of the test is to verify EC Sales List Report for Column with Amount and Third Party Trade = False.

        // Setup.
        Initialize();
        CreateVATEntry(VATEntry, false);
        LibraryVariableStorage.Enqueue(PrintTestValue::"Column with Amount");

        // Exercise.
        REPORT.Run(REPORT::"EC Sales List");

        // Verify: Verifying Third Party Trade on Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ThirdPartyTradeCap, false);
    end;

    [Test]
    [HandlerFunctions('ECSalesListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportECSalesList()
    var
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to verify EC Sales List Report for Error for invalid Date Filter.

        // Setup.
        Initialize();
        CreateVATEntry(VATEntry, false);

        // Exercise.
        asserterror REPORT.Run(REPORT::"EC Sales List");

        // Verify.
        Assert.ExpectedError(StrSubstNo(PostingDateErr, VATEntry.FieldCaption("Posting Date"), VATEntry."Posting Date"));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; EU3PartyTrade: Boolean)
    var
        VATEntry2: Record "VAT Entry";
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Code := LibraryUTUtility.GetNewCode10();
        CountryRegion.Insert();
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry."Country/Region Code" := CountryRegion.Code;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry.Amount := LibraryRandom.RandDec(100, 2);
        VATEntry."EU 3-Party Trade" := EU3PartyTrade;
        VATEntry."Posting Date" := WorkDate();
        VATEntry.Insert();
        LibraryVariableStorage.Enqueue(CountryRegion.Code);
        CalculateDate();
    end;

    local procedure CalculateDate()
    var
        Calender: Record Date;
        StartDate: Date;
    begin
        // Calculate Start Date and End Date.
        StartDate := DMY2Date(1, 12, Date2DMY(WorkDate(), 3) - 1);
        Calender.SetRange("Period Type", Calender."Period Type"::Month);
        Calender.SetRange("Period Start", StartDate);
        if Calender.FindFirst() then;
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(NormalDate(Calender."Period End"));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SeperateLinesECSalesListRequestPageHandler(var ECSalesList: TestRequestPage "EC Sales List")
    var
        "Code": Variant;
        StartDate: Variant;
        EndDate: Variant;
        PrintThirdPartyTradeAs: Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        LibraryVariableStorage.Dequeue(PrintThirdPartyTradeAs);
        ECSalesList."VAT Entry".SetFilter("Country/Region Code", Code);
        ECSalesList."VAT Entry".SetFilter("Posting Date", StrSubstNo(DateFilterCap, StartDate, EndDate));
        ECSalesList.ReportLayout.SetValue(PrintThirdPartyTradeAs);
        ECSalesList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ECSalesListRequestPageHandler(var ECSalesList: TestRequestPage "EC Sales List")
    var
        "Code": Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        ECSalesList."VAT Entry".SetFilter("Country/Region Code", Code);
        ECSalesList."VAT Entry".SetFilter("Posting Date", Format(WorkDate()));
        ECSalesList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

