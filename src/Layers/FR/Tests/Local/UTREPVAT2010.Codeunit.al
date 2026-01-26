codeunit 144068 "UT REP VAT2010"
{
    // 1. Purpose of the test is to verify error for Report - 10876 (EC Sales List - Services) with no data.
    // 2. Purpose of the test is to verify error for Report - 10876 (EC Sales List - Services) without date range.
    // 3. Purpose of the test is to verify VAT Entry - OnAfterGetRecord for Report - 10876 (EC Sales List - Services).
    // 4. Purpose of the test is to verify Country/Region - OnPreDataItem for Report - 10876 (EC Sales List - Services).
    // 
    // Covers Test Cases for WI -  344464
    // ----------------------------------------------------------------------------------------------
    // Test Function Name                                                                      TFS ID
    // ----------------------------------------------------------------------------------------------
    // OnPreReportECSalesListServicesError                                              203481,203478
    // OnPostReportECSalesListServicesError                                             203479,203480
    // OnAfterGetRecordVATEntryECSalesListServices                                      203482,203484
    // OnPreDataItemCountryRegionECSalesListServices                                    203485,203483

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
        AmountCap: Label 'Amount( %1)';
        DateFilterTxt: Label '%1..%2';

    [Test]
    [HandlerFunctions('ECSalesListServicesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportECSalesListServicesError()
    begin
        // Purpose of the test is to verify error for Report - 10876 (EC Sales List - Services) with no data.
        // Verify actual error: "There is no data to export. No XML file is created."
        ECSalesListServicesReportErrors(StrSubstNo(DateFilterTxt, CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate())));
    end;

    [Test]
    [HandlerFunctions('ECSalesListServicesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPostReportECSalesListServicesError()
    begin
        // Purpose of the test is to verify error for Report - 10876 (EC Sales List - Services) without date range.
        // Verify actual error: "Posting Date filter must be corrected, to run the report monthly."
        ECSalesListServicesReportErrors(Format(WorkDate()));
    end;

    local procedure ECSalesListServicesReportErrors(PostingDate: Text)
    begin
        // Setup: Enqueue required for ECSalesListServicesRequestPageHandler.
        Initialize();
        EnqueueForECSalesListServicesReqPageHandler(true, true, PostingDate);  // Create XML and ShowAmountsInAddReportingCurrency as True.

        // Exercise.
        asserterror REPORT.Run(REPORT::"EC Sales List - Services");

        // Verify.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('ECSalesListServicesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATEntryECSalesListServices()
    begin
        // Purpose of the test is to verify VAT Entry - OnAfterGetRecord for Report - 10876 (EC Sales List - Services).
        // Setup.
        Initialize();

        // Exercise and Verify.
        ExecuteECSalesListServicesReportWithData(UpdateCompanyInformation(), UpdateGeneralLedgerSetup(), true);  // ShowAmountsInAddReportingCurrency as True.
    end;

    [Test]
    [HandlerFunctions('ECSalesListServicesRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemCountryRegionECSalesListServices()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to verify Country/Region - OnPreDataItem for Report - 10876 (EC Sales List - Services).
        // Setup.
        Initialize();
        GeneralLedgerSetup.Get();

        // Exercise and Verify.
        ExecuteECSalesListServicesReportWithData(UpdateCompanyInformation(), GeneralLedgerSetup."LCY Code", false);  // ShowAmountsInAddReportingCurrency as False.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure EnqueueForECSalesListServicesReqPageHandler(CreateXML: Boolean; ShowAmountsInAddReportingCurrency: Boolean; PostingDate: Text)
    begin
        LibraryVariableStorage.Enqueue(CreateXML);
        LibraryVariableStorage.Enqueue(ShowAmountsInAddReportingCurrency);
        LibraryVariableStorage.Enqueue(PostingDate);
    end;

    local procedure UpdateCompanyInformation(): Text[20]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := LibraryUTUtility.GetNewCode10();
        CompanyInformation.Modify();
        exit(CompanyInformation."VAT Registration No.");
    end;

    local procedure UpdateGeneralLedgerSetup(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := LibraryUTUtility.GetNewCode10();
        GeneralLedgerSetup.Modify();
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;

    local procedure ExecuteECSalesListServicesReportWithData(VATRegistrationNo: Text[20]; CurrencyCode: Code[10]; ShowAmountsInAddReportingCurrency: Boolean)
    begin
        EnqueueForECSalesListServicesReqPageHandler(
          false, ShowAmountsInAddReportingCurrency, StrSubstNo(DateFilterTxt, CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate())));  // Create XML as False.

        // Exercise.
        REPORT.Run(REPORT::"EC Sales List - Services");

        // Verify: Verify values of VATRegNo and AmountCaption on report EC Sales List - Services.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VATRegNo', VATRegistrationNo);
        LibraryReportDataset.AssertElementWithValueExists('AmountCaption', StrSubstNo(AmountCap, CurrencyCode));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ECSalesListServicesRequestPageHandler(var ECSalesListServices: TestRequestPage "EC Sales List - Services")
    var
        CreateXML: Variant;
        PostingDate: Variant;
        ShowAmountsInAddReportingCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(CreateXML);
        LibraryVariableStorage.Dequeue(ShowAmountsInAddReportingCurrency);
        LibraryVariableStorage.Dequeue(PostingDate);
        ECSalesListServices."VAT Entry".SetFilter("Posting Date", PostingDate);
        ECSalesListServices.ShowAmountsInAddReportingCurrency.SetValue(ShowAmountsInAddReportingCurrency);
        ECSalesListServices.CreateXML.SetValue(CreateXML);
        ECSalesListServices.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

