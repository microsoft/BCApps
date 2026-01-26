codeunit 144077 "UT REP Extra VAT"
{
    // 1-8. Purpose of the test is to validate OnPreReport Trigger of Report - 12108 VAT Register Grouped with blank Company Name,Company Address,Company Post Code,Register Company Number,Fiscal Code,
    //      blank Period Starting Date and five years back workdate.
    //   9. Purpose of the test is to validate OnAfterGetRecord - VAT Entry Trigger of Report 20 - Calculate and Post VAT Settlement with Show VAT Entries.
    //  10. Purpose of the test is to validate OnAfterGetRecord - VAT Entry Trigger of Report 20 - Calculate and Post VAT Settlement without Show VAT Entries.
    //  11. Purpose of the test is to validate OnAfterGetRecord - Close VAT Entries Trigger of Report 20 - Calculate and Post VAT Settlement for Sales with Unrealized VAT.
    //  12. Purpose of the test is to validate OnAfterGetRecord - Close VAT Entries Trigger of Report 20 - Calculate and Post VAT Settlement for Purchase with Unrealized VAT.
    //  13. Purpose of the test is to validate OnPostDataItem - VAT Posting Setup Trigger of Report 20 - Calculate and Post VAT Settlement.
    //  14. Purpose of the test is to check that the VAT Register Grouped when Starting Date equals Ending Date and Print company information is True.
    //  15. Purpose of the test is to check that the VAT Register Grouped is working fine when Ending Date is greater then Starting Date and Print company information is True.
    //  16. Purpose of the test is to check the VAT Register Grouped when Starting Date is 2 years less than Ending Date and Print company information is True.
    //  17. Purpose of the test is to check that the VAT Register Grouped is working fine when Ending Date is greater then Starting Date and Print company information is True.
    //  18. Purpose of the test is to validate Unrealized VAT - OnAfterGetRecord Trigger of VAT Register Print for Purchase.
    //  19. Purpose of the test is to validate Unrealized VAT - OnAfterGetRecord Trigger of VAT Register Print for Sales.
    // 
    // Covers Test Cases for WI - 346623
    // ---------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // ---------------------------------------------------------------------------------------------------------------------
    // OnPreDataItemBlankCompanyNameVATRegGrpErr                                                            156049
    // OnPreDataItemBlankCompanyAddressVATRegGrpErr                                                         156051
    // OnPreDataItemBlankCompanyPostCodeVATRegGrpErr                                                        156052
    // OnPreDataItemBlankRegisterCompanyNumberVATRegGrpErr                                                  156053
    // OnPreDataItemBlankVATRegistrationNoVATRegGrpErr                                                      156054
    // OnPreDataItemBlankFiscalCodeVATRegGrpErr                                                             156055
    // OnPreDataItemWithoutPeriodStartingDateVATRegGrpErr                                                   156046
    // OnPreDataItemWithPeriodStartingDateVATRegGrpErr                                                      156056
    // 
    // Covers Test Cases for WI - 346722
    // ---------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // ---------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecShowVATEntryCalcAndPostVATSettlement                                                    156264
    // OnAfterGetRecCalcAndPostVATSettlement                                                                156263
    // OnAfterGetRecSalesInvoiceCalcAndPostVATSettlement                                                    168445
    // OnAfterGetRecPurchInvoiceCalcAndPostVATSettlement                                                    155890
    // OnPostDataItemCalcAndPostVATSettlement                                                               207207
    // 
    // Covers Test Cases for WI - 346771
    // ---------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // ---------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecEqualDatesVATRegGrouped,OnAfterGetRecCrntMthStartingDateVATRegGrouped               156040,156028,156031
    // OnAfterGetRecTwoYearBackStartingDateVATRegGrouped                                                156034,156044,156042
    // OnAfterGetRecCrntMthEndingDateVATRegGrouped                                                      156038
    // 
    // Covers Test Cases for WI - 346951
    // ---------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // ---------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordUnrealizedVATPurchVATRegisterPrint                                         155491,155492,155489,155490
    // OnAfterGetRecordUnrealizedVATSaleVATRegisterPrint                                          155743,264004,155833,155742

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
        DialogErr: Label 'Dialog';
        PeriodStartingDateErr: Label 'DB:NothingInsideFilter';
        CompanyInfoNameCap: Label 'CompanyInformation_1_';
        CompanyInfoAddressCap: Label 'CompanyInformation_2_';
        CompanyInfoPostCodeCap: Label 'CompanyInformation_3_';
        CompanyInfoRegCompanyNoCap: Label 'CompanyInformation_4_';
        CompanyInfoVATRegNoCap: Label 'CompanyInformation_5_';
        CompanyInfoFiscalCodeCap: Label 'CompanyInformation_6_';
        EndingDateCap: Label 'EndingDate';
        NondeductibleAmountCap: Label 'NondeductibleAmount_VATEntry';
        NondeductibleBaseCap: Label 'NondeductibleBase_VATEntry';
        NondeductibleAmtCap: Label 'VATBookEntryTemp__Nondeductible_Amount_';
        PeriodInputVATYearInputVATCap: Label 'PeriodInputVATYearInputVAT';
        RemUnrealizedAmtVATEntryCap: Label 'RemUnrealizedAmt_VATEntry';
        RemUnrealizedBaseVATEntryCap: Label 'RemUnrealizedBase_VATEntry';
        LibraryRandom: Codeunit "Library - Random";
        SignumUnrealizedAmountCap: Label 'VATBookEntryTemp__Unrealized_Amount__Control1130196';
        StartingDateCap: Label 'StartingDate';
        TotalVATNondeducAmntCap: Label 'TotalVATNondeducAmnt';
        TotalVATNondeducBaseCap: Label 'TotalVATNondeducBase';
        UnrealizedVATSellToBuyFromNoCap: Label 'UnrealizedVAT__Sell_to_Buy_from_No__';
        UnrealizedVATEntryNoCap: Label 'UnrealizedVAT_UnrealizedVAT__Entry_No__';
        LastSettlementDateErr: Label 'Last Settlement Date must have a value in General Ledger Setup';

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemBlankCompanyNameVATRegGrpErr()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12108 VAT Register Grouped with blank Company Name.
        Initialize();
        VATRegisterGrouped(
          '', LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode10(), LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Blank Company Name.
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemBlankCompanyAddressVATRegGrpErr()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12108 VAT Register Grouped with blank Company Address.
        Initialize();
        VATRegisterGrouped(
          LibraryUTUtility.GetNewCode(), '', LibraryUTUtility.GetNewCode10(), LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Blank Company Address.
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemBlankCompanyPostCodeVATRegGrpErr()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12108 VAT Register Grouped blank Company Post Code
        Initialize();
        VATRegisterGrouped(
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '', LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Blank Company Post Code.
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemBlankRegisterCompanyNumberVATRegGrpErr()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12108 VAT Register Grouped blank Register Company Number.
        Initialize();
        VATRegisterGrouped(
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode10(), '',
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());  // Blank Register Company Number.
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemBlankVATRegistrationNoVATRegGrpErr()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12108 VAT Register Grouped blank VAT Registration No.
        Initialize();
        VATRegisterGrouped(
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode10(),
          LibraryUTUtility.GetNewCode(), '', LibraryUTUtility.GetNewCode());  // Blank VAT Registration No.
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemBlankFiscalCodeVATRegGrpErr()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12108 VAT Register Grouped blank Fiscal Code
        Initialize();
        VATRegisterGrouped(
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode10(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), '');  // Blank Fiscal Code.
    end;

    local procedure VATRegisterGrouped(Name: Text[50]; Address: Text[50]; PostCode: Code[10]; RegisterCompanyNo: Text[50]; VATRegistrationNo: Text[20]; FiscalCode: Code[20])
    begin
        // Setup.
        UpdateCompanyInformation(Name, Address, PostCode, RegisterCompanyNo, VATRegistrationNo, FiscalCode);
        LibraryVariableStorage.Enqueue(WorkDate());  // Enqueue Period Starting Date for VAT Register Grouped Request Page Handler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"VAT Register Grouped");  // Opens handler - VATRegisterGroupedRequestPageHandler.

        // Verify: Verify Error Code. Actual error message is "All Company Information related fields should be filled in on the request form".
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemWithoutPeriodStartingDateVATRegGrpErr()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12108 VAT Register Grouped with blank Period Starting Date.
        // Actual error message is "There is no Accounting Period within the filter.Filters: Starting Date: <='', New Fiscal Year: Yes".
        Initialize();
        VATRegisterGroupedPeriodStartingDate(0D);  // Blank Period Starting Date.
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemWithPeriodStartingDateVATRegGrpErr()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report - 12108 VAT Register Grouped with one day prior of first Accounting Period Starting Date.
        // Actual error message is "There is no Accounting Period within the filter.Filters: Starting Date: <=XXXXX, New Fiscal Year: Yes"
        Initialize();
        AccountingPeriod.FindFirst();
        VATRegisterGroupedPeriodStartingDate(CalcDate('<-1D>', AccountingPeriod."Starting Date"));  // Taking one day prior of first Accounting Period Starting Date.
    end;

    local procedure VATRegisterGroupedPeriodStartingDate(PeriodStartingDate: Date)
    begin
        // Setup.
        UpdateCompanyInformation(
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode10(), LibraryUTUtility.GetNewCode(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());
        EnqueueValuesInVATRegisterGroupedHandler(PeriodStartingDate, 0D);  // Enqueue blank Period Ending Date for VAT Register Grouped Request Page Handler.

        // Exercise.
        asserterror REPORT.Run(REPORT::"VAT Register Grouped");  // Opens handler - VATRegisterGroupedRequestPageHandler.

        // Verify: Verify Error Code.
        Assert.ExpectedErrorCode(PeriodStartingDateErr);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecShowVATEntryCalcAndPostVATSettlement()
    begin
        // Purpose of the test is to validate OnAfterGetRecord - VAT Entry Trigger of Report 20 - Calculate and Post VAT Settlement with Show VAT Entries.
        ShowVATEntryCalcAndPostVATSettlement(true, NondeductibleAmountCap, NondeductibleBaseCap);  // True for Show VAT Entries
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecCalcAndPostVATSettlement()
    begin
        // Purpose of the test is to validate OnAfterGetRecord - VAT Entry Trigger of Report 20 - Calculate and Post VAT Settlement without Show VAT Entries.
        ShowVATEntryCalcAndPostVATSettlement(false, TotalVATNondeducAmntCap, TotalVATNondeducBaseCap);  // False for Show VAT Entries
    end;

    local procedure ShowVATEntryCalcAndPostVATSettlement(ShowVATEntries: Boolean; ExpectedAmountCaption: Text; ExpectedBaseCaption: Text)
    var
        VATEntry: Record "VAT Entry";
    begin
        // Setup and Exercise.
        Initialize();
        CalcAndPostVATSettlementWithUnrealizedVAT(VATEntry, false, VATEntry.Type::Sale, ShowVATEntries);  // False for Unrealized VAT.

        // Verify: Non Deductible Base and Amount on generated file of Report - Calculate and Post VAT Settlement.
        VerifyValuesOnCalcAndPostVATSettlementReport(
          ExpectedAmountCaption, VATEntry."Nondeductible Amount", ExpectedBaseCaption, VATEntry."Nondeductible Base");
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecSalesInvoiceCalcAndPostVATSettlement()
    var
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Close VAT Entries Trigger of Report 20 - Calculate and Post VAT Settlement for Sales with Unrealized VAT.
        PostInvoiceWithUnrealVATCalcAndPostVATSettlement(VATEntry.Type::Sale);
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecPurchInvoiceCalcAndPostVATSettlement()
    var
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to validate OnAfterGetRecord - Close VAT Entries Trigger of Report 20 - Calculate and Post VAT Settlement for Purchase with Unrealized VAT.
        PostInvoiceWithUnrealVATCalcAndPostVATSettlement(VATEntry.Type::Purchase);
    end;

    local procedure PostInvoiceWithUnrealVATCalcAndPostVATSettlement(EntryType: Enum "General Posting Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        // Setup and Exercise.
        Initialize();
        CalcAndPostVATSettlementWithUnrealizedVAT(VATEntry, true, EntryType, true);  // True for Unrealized VAT and Show VAT Entries.

        // Verify: Remaining Unrealized Base and Amount on generated file of Report - Calculate and Post VAT Settlement.
        VerifyValuesOnCalcAndPostVATSettlementReport(
          RemUnrealizedAmtVATEntryCap, VATEntry."Remaining Unrealized Amount", RemUnrealizedBaseVATEntryCap,
          VATEntry."Remaining Unrealized Base");
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestPageHandler,ConfirmHandlerTrue')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPostDataItemCalcAndPostVATSettlement()
    var
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to validate OnPostDataItem - VAT Posting Setup Trigger of Report 20 - Calculate and Post VAT Settlement.

        // Setup and Exercise.
        Initialize();
        CalcAndPostVATSettlementWithUnrealizedVAT(VATEntry, false, VATEntry.Type::Purchase, true);  // False for Unrealized VAT and True for Show VAT Entries.

        // Verify: Next Period Input VAT Amount on generated file of Report - Calculate and Post VAT Settlement.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          PeriodInputVATYearInputVATCap, FindPeriodicSettlementVATEntry(VATEntry."Operation Occurred Date"));
    end;

    [Test]
    [HandlerFunctions('CalcAndPostVATSettlementRequestSimplePageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementWithBlankLastSettlementDate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [SCENARIO 421454] Run Calc. and Post VAT Settlement if "Last Settlement Date" is blank in setup.
        Initialize();
        // [GIVEN] Blank "Last Settlement Date" in GLSetup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Last Settlement Date" := 0D;
        GeneralLedgerSetup.Modify();
        // [WHEN] Run "Calc. and Post VAT Settlement"
        asserterror REPORT.Run(REPORT::"Calc. and Post VAT Settlement");  // Opens handler - CalcAndPostVATSettlementRequestSimplePageHandler.
        // [THEN] Error: "Last Settlement Date must havea value"
        Assert.ExpectedError(LastSettlementDateErr);
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler,VATRegisterPrintRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecEqualDatesVATRegGrouped()
    begin
        // Purpose of the test is to check that the Report - 12108 VAT Register Grouped when Starting Date equals Ending Date and Print company information is Yes.
        VATRegisterGroupedWithPrintCompanyInformation(CalcDate('<-CM>', WorkDate()), CalcDate('<-CM>', WorkDate()));  // Taking current month first date as Period Starting Date and Period Ending Date.
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler,VATRegisterPrintRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecCrntMthStartingDateVATRegGrouped()
    begin
        // Purpose of the test is to check that the Report - 12108 VAT Register Grouped is working fine when Ending Date is greater then Starting Date and Print company information is Yes.
        VATRegisterGroupedWithPrintCompanyInformation(CalcDate('<-CM>', WorkDate()), 0D);  // Taking current month first date as Period Starting Date, blank Period Ending Date.
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler,VATRegisterPrintRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecTwoYearBackStartingDateVATRegGrouped()
    begin
        // Purpose of the test is to check the Report - 12108 VAT Register Grouped when Starting Date is 2 years less than Ending Date and Print company information is Yes.
        VATRegisterGroupedWithPrintCompanyInformation(CalcDate('<CY -2Y +1D>', WorkDate()), CalcDate('<-CY>', WorkDate()));  // Taking 2 years back date as Period Starting Date, current year first date as Period Ending Date.
    end;

    [Test]
    [HandlerFunctions('VATRegisterGroupedRequestPageHandler,VATRegisterPrintRequestPageHandler,ConfirmHandlerTrue,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecCrntMthEndingDateVATRegGrouped()
    begin
        // Purpose of the test is to check that the Report - 12108 VAT Register Grouped is working fine when Ending Date is greater then Starting Date and Print company information is Yes.
        VATRegisterGroupedWithPrintCompanyInformation(CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));  // Taking current month first date as Period Starting Date, current month end date as Period Ending Date.
    end;

    local procedure VATRegisterGroupedWithPrintCompanyInformation(PeriodStartingDate: Date; PeriodEndingDate: Date)
    begin
        // Setup.
        Initialize();
        UpdateCompanyInformation(
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode10(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());
        RunVATRegisterPrintWithVATBookEntry(PeriodStartingDate);
        EnqueueValuesInVATRegisterGroupedHandler(PeriodStartingDate, PeriodEndingDate);

        // Exercise.
        REPORT.Run(REPORT::"VAT Register Grouped");  // Opens handler - VATRegisterGroupedRequestPageHandler.

        // Verify: Verify Values on VAT Register Grouped Report.
        VerifyValuesOnVATRegisterGroupedReport(PeriodStartingDate, PeriodEndingDate);
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordUnrealizedVATPurchVATRegisterPrint()
    var
        VATBookEntry: Record "VAT Book Entry";
    begin
        // Purpose of the test is to validate Unrealized VAT - OnAfterGetRecord Trigger of Report - 12120 VAT Register Print for Purchase.
        Initialize();
        VATRegisterPrintWithVATBookEntry(VATBookEntry.Type::Purchase, LibraryRandom.RandDec(10, 2));  // Using random value for Unrealized Amount
    end;

    [Test]
    [HandlerFunctions('VATRegisterPrintRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordUnrealizedVATSaleVATRegisterPrint()
    var
        VATBookEntry: Record "VAT Book Entry";
    begin
        // Purpose of the test is to validate Unrealized VAT - OnAfterGetRecord Trigger of Report - 12120 VAT Register Print for Sales.
        Initialize();
        VATRegisterPrintWithVATBookEntry(VATBookEntry.Type::Sale, -LibraryRandom.RandDec(10, 2));  // Using random value for Unrealized Amount
    end;

    local procedure VATRegisterPrintWithVATBookEntry(Type: Enum "General Posting Type"; UnrealizedAmount: Decimal)
    var
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        PrintingType: Option Test;
    begin
        // Setup.
        UpdateCompanyInformation(
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode10(),
          LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode(), LibraryUTUtility.GetNewCode());
        CreateNumberSeries(NoSeries);
        CreateVATBookEntry(VATBookEntry, WorkDate(), NoSeries.Code, Type, UnrealizedAmount);
        EnqueueValuesForVATRegisterPrintRequestPageHandler(NoSeries."VAT Register", PrintingType::Test, WorkDate(), WorkDate());  // Enqueue WORKDATE as PeriodStartingDate and PeriodEndingDate for handler - VATRegisterPrintRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"VAT Register - Print");  // Opens handler - VATRegisterPrintRequestPageHandler.

        // Verify: Verify values on VAT Register - Print report.
        VerifyValuesOnVATRegisterPrintReport(VATBookEntry);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CalcAndPostVATSettlementWithUnrealizedVAT(var VATEntry: Record "VAT Entry"; UnrealizedVAT: Boolean; EntryType: Enum "General Posting Type"; ShowVATEntries: Boolean)
    begin
        // Setup: Update General Ledger Setup and Create VAT Entry.
        UpdateUnrealizedVATOnGeneralLedgerSetup(UnrealizedVAT);
        CreateVATEntry(VATEntry, EntryType);
        EnqueueValuesInCalcAndPostVATSettlementHandler(ShowVATEntries);

        // Exercise.
        REPORT.Run(REPORT::"Calc. and Post VAT Settlement");  // Opens handler - CalcAndPostVATSettlementRequestPageHandler.
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateNumberSeries(var NoSeries: Record "No. Series")
    begin
        NoSeries.Code := LibraryUTUtility.GetNewCode10();
        NoSeries."VAT Register" := CreateVATRegister();
        NoSeries.Insert();
    end;

    local procedure CreateVATBookEntry(var VATBookEntry: Record "VAT Book Entry"; PeriodStartingDate: Date; NoSeries: Code[20]; Type: Enum "General Posting Type"; UnrealizedAmount: Decimal)
    var
        VATBookEntry2: Record "VAT Book Entry";
    begin
        VATBookEntry2.FindLast();
        VATBookEntry."Entry No." := VATBookEntry2."Entry No." + 1;
        VATBookEntry.Type := Type;
        VATBookEntry."No. Series" := NoSeries;
        VATBookEntry."Posting Date" := PeriodStartingDate;
        VATBookEntry."VAT Identifier" := CreateVATIdentifier();
        VATBookEntry."Unrealized VAT" := true;
        VATBookEntry."Unrealized Amount" := UnrealizedAmount;
        VATBookEntry."Nondeductible Amount" := VATBookEntry."Unrealized Amount";
        VATBookEntry."Unrealized Base" := VATBookEntry."Unrealized Amount";
        VATBookEntry."Unrealized VAT Entry No." := CreateVATEntryWithDetails(VATBookEntry);
        VATBookEntry.Insert();
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; Type: Enum "General Posting Type")
    var
        VATEntry2: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup);
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry.Type := Type;
        VATEntry."Operation Occurred Date" := GetStartingDate();
        VATEntry."Remaining Unrealized Amount" := LibraryRandom.RandDec(100, 2);
        VATEntry."Remaining Unrealized Base" := VATEntry."Remaining Unrealized Amount";
        VATEntry."Nondeductible Base" := VATEntry."Remaining Unrealized Amount";
        VATEntry."Nondeductible Amount" := VATEntry."Remaining Unrealized Amount";
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry.Insert();
    end;

    local procedure CreateVATEntryWithDetails(VATBookEntry: Record "VAT Book Entry"): Integer
    var
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry.Type := VATBookEntry.Type;
        VATEntry."No. Series" := VATBookEntry."No. Series";
        VATEntry."VAT Identifier" := VATBookEntry."VAT Identifier";
        VATEntry."Unrealized VAT Entry No." := VATEntry."Entry No.";
        VATEntry."Unrealized Amount" := VATBookEntry."Unrealized Amount";
        VATEntry."Unrealized Base" := VATBookEntry."Unrealized Base";
        VATEntry."Nondeductible Amount" := VATBookEntry."Nondeductible Amount";
        VATEntry.Insert();
        exit(VATEntry."Entry No.");
    end;

    local procedure CreateVATIdentifier(): Code[10]
    var
        VATIdentifier: Record "VAT Identifier";
    begin
        VATIdentifier.Code := LibraryUTUtility.GetNewCode10();
        VATIdentifier.Insert();
        exit(VATIdentifier.Code);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup."VAT Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATPostingSetup."VAT Prod. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATPostingSetup."Sales VAT Account" := LibraryUTUtility.GetNewCode();
        VATPostingSetup."Purchase VAT Account" := VATPostingSetup."Sales VAT Account";
        VATPostingSetup.Insert();
    end;

    local procedure CreateVATRegister(): Code[10]
    var
        VATRegister: Record "VAT Register";
    begin
        VATRegister.Code := LibraryUTUtility.GetNewCode10();
        VATRegister.Insert();
        exit(VATRegister.Code);
    end;

    local procedure EnqueueValuesInCalcAndPostVATSettlementHandler(ShowVATEntries: Boolean)
    begin
        // Enqueue Values for Handler - CalcAndPostVATSettlementRequestPageHandler.
        LibraryVariableStorage.Enqueue(ShowVATEntries);
    end;

    local procedure EnqueueValuesInVATRegisterGroupedHandler(PeriodStartingDate: Date; PeriodEndingDate: Date)
    begin
        // Enqueue Values For VAT Register Grouped Request Page Handler.
        LibraryVariableStorage.Enqueue(PeriodStartingDate);
        LibraryVariableStorage.Enqueue(PeriodEndingDate);
    end;

    local procedure EnqueueValuesForVATRegisterPrintRequestPageHandler(VATRegisterCode: Code[10]; PrintingType: Option; PeriodStartingDate: Date; PeriodEndingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(VATRegisterCode);
        LibraryVariableStorage.Enqueue(PeriodStartingDate);
        LibraryVariableStorage.Enqueue(PeriodEndingDate);
        LibraryVariableStorage.Enqueue(PrintingType);
    end;

    local procedure FindPeriodicSettlementVATEntry(PeriodDate: Date): Decimal
    var
#if not CLEAN27
        PeriodicSettlementVATEntry: Record "Periodic Settlement VAT Entry";
#else
        PeriodicSettlementVATEntry: Record "Periodic VAT Settlement Entry";
#endif
    begin
        // Periodic VAT Settlement Entry is created after running the Report - Calc. and Post VAT Settlement.
        PeriodicSettlementVATEntry.SetRange(
          "VAT Period", Format(Date2DMY(PeriodDate, 3)) + '/' + ConvertStr(Format(Date2DMY(PeriodDate, 2), 2), ' ', '0'));  // Calculation is given in OnPostDataItem - VAT Posting Setup of Report - Calc. and Post VAT Settlement.
        PeriodicSettlementVATEntry.FindFirst();
        exit(PeriodicSettlementVATEntry."Prior Period Input VAT");
    end;

    local procedure RunVATRegisterPrintWithVATBookEntry(PeriodStartingDate: Date)
    var
        NoSeries: Record "No. Series";
        VATBookEntry: Record "VAT Book Entry";
        PrintingType: Option Test,Final;
    begin
        CreateNumberSeries(NoSeries);
        CreateVATBookEntry(VATBookEntry, PeriodStartingDate, NoSeries.Code, VATBookEntry.Type::Sale, LibraryRandom.RandDec(10, 2));  // Using random value for Unrealized Amount
        EnqueueValuesForVATRegisterPrintRequestPageHandler(
          NoSeries."VAT Register", PrintingType::Final, PeriodStartingDate, CalcDate('<CM>', PeriodStartingDate));  // Enqueue values for handler - VATRegisterPrintRequestPageHandler.
        REPORT.Run(REPORT::"VAT Register - Print");  // Opens handler - VATRegisterPrintRequestPageHandler.
    end;

    local procedure GetStartingDate(): Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(CalcDate('<1D>', GeneralLedgerSetup."Last Settlement Date"));  // 1D is required as Starting date for Report - Calculate and Post VAT Settlement should be the next Day of Last Settlement Date.
    end;

    local procedure UpdateCompanyInformation(Name: Text[50]; Address: Text[50]; PostCode: Code[10]; RegisterCompanyNo: Text[50]; VATRegistrationNo: Text[20]; FiscalCode: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Name := Name;
        CompanyInformation.Address := Address;
        CompanyInformation."Post Code" := PostCode;
        CompanyInformation.City := CompanyInformation."Post Code";
        CompanyInformation.County := CompanyInformation."Post Code";
        CompanyInformation."Register Company No." := RegisterCompanyNo;
        CompanyInformation."VAT Registration No." := VATRegistrationNo;
        CompanyInformation."Fiscal Code" := FiscalCode;
        CompanyInformation.Modify();
    end;

    local procedure UpdateUnrealizedVATOnGeneralLedgerSetup(UnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyValuesOnCalcAndPostVATSettlementReport(ExpectedAmountCaption: Text; ExpectedAmountValue: Decimal; ExpectedBaseCaption: Text; ExpectedBaseValue: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ExpectedAmountCaption, ExpectedAmountValue);
        LibraryReportDataset.AssertElementWithValueExists(ExpectedBaseCaption, ExpectedBaseValue);
    end;

    local procedure VerifyValuesOnVATRegisterGroupedReport(PeriodStartingDate: Date; PeriodEndingDate: Date)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoNameCap, CompanyInformation.Name);
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoAddressCap, CompanyInformation.Address);
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoPostCodeCap, CompanyInformation."Post Code");
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoRegCompanyNoCap, CompanyInformation."Register Company No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoVATRegNoCap, CompanyInformation."VAT Registration No.");
        LibraryReportDataset.AssertElementWithValueExists(CompanyInfoFiscalCodeCap, CompanyInformation."Fiscal Code");
        LibraryReportDataset.AssertElementWithValueExists(StartingDateCap, Format(PeriodStartingDate));
        LibraryReportDataset.AssertElementWithValueExists(EndingDateCap, Format(PeriodEndingDate));
    end;

    local procedure VerifyValuesOnVATRegisterPrintReport(VATBookEntry: Record "VAT Book Entry")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(UnrealizedVATSellToBuyFromNoCap, VATBookEntry."Sell-to/Buy-from No.");
        LibraryReportDataset.AssertElementWithValueExists(UnrealizedVATEntryNoCap, VATBookEntry."Entry No.");
        LibraryReportDataset.AssertElementWithValueExists(SignumUnrealizedAmountCap, VATBookEntry."Unrealized Amount");
        LibraryReportDataset.AssertElementWithValueExists(NondeductibleAmtCap, VATBookEntry."Nondeductible Amount");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestPageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    var
        ShowVATEntries: Variant;
        GLAccountNo: Code[20];
    begin
        GLAccountNo := CreateGLAccount();
        LibraryVariableStorage.Dequeue(ShowVATEntries);
        CalcAndPostVATSettlement.StartingDate.SetValue(GetStartingDate());
        CalcAndPostVATSettlement.DocumentNo.SetValue(LibraryUTUtility.GetNewCode());
        CalcAndPostVATSettlement.SettlementAcc.SetValue(GLAccountNo);
        CalcAndPostVATSettlement.GLGainsAccount.SetValue(GLAccountNo);
        CalcAndPostVATSettlement.GLLossesAccount.SetValue(GLAccountNo);
        CalcAndPostVATSettlement.Post.SetValue(true);
        CalcAndPostVATSettlement.ShowVATEntries.SetValue(ShowVATEntries);
        CalcAndPostVATSettlement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostVATSettlementRequestSimplePageHandler(var CalcAndPostVATSettlement: TestRequestPage "Calc. and Post VAT Settlement")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterGroupedRequestPageHandler(var VATRegisterGrouped: TestRequestPage "VAT Register Grouped")
    var
        CompanyInformation: Record "Company Information";
        PeriodStartingDate: Variant;
        PeriodEndingDate: Variant;
    begin
        CompanyInformation.Get();
        LibraryVariableStorage.Dequeue(PeriodStartingDate);
        LibraryVariableStorage.Dequeue(PeriodEndingDate);
        VATRegisterGrouped.PeriodStartingDate.SetValue(Format(PeriodStartingDate));
        VATRegisterGrouped.PeriodEndingDate.SetValue(Format(PeriodEndingDate));
        VATRegisterGrouped.RegisterCompanyNo.SetValue(CompanyInformation."Register Company No.");
        VATRegisterGrouped.FiscalCode.SetValue(CompanyInformation."Fiscal Code");
        VATRegisterGrouped.Name.SetValue(CompanyInformation.Name);
        VATRegisterGrouped.Address.SetValue(CompanyInformation.Address);
        VATRegisterGrouped.PostCodeCityCounty.SetValue(CompanyInformation."Post Code");
        VATRegisterGrouped.VATRegistrationNo.SetValue(CompanyInformation."VAT Registration No.");
        VATRegisterGrouped.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterPrintRequestPageHandler(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    var
        PrintingType: Variant;
        PeriodStartingDate: Variant;
        PeriodEndingDate: Variant;
        VATRegister: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATRegister);
        LibraryVariableStorage.Dequeue(PeriodStartingDate);
        LibraryVariableStorage.Dequeue(PeriodEndingDate);
        LibraryVariableStorage.Dequeue(PrintingType);
        VATRegisterPrint.VATRegister.SetValue(VATRegister);
        VATRegisterPrint.PeriodStartingDate.SetValue(Format(PeriodStartingDate));
        VATRegisterPrint.PeriodEndingDate.SetValue(Format(PeriodEndingDate));
        VATRegisterPrint.PrintingType.SetValue(PrintingType);
        VATRegisterPrint.FiscalCode.SetValue(LibraryUTUtility.GetNewCode());
        VATRegisterPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;
}

