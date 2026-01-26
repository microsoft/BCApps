codeunit 144011 "UT REP ICL"
{
    // 1. Purpose of the test is to validate OnPreReport Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL).
    // 2 - 3. Purpose of the test is to validate VAT Entry - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL).
    // 4. Purpose of the test is to validate TempIntracommLev1 - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL) With EU3PartyTrade as False.
    // 5. Purpose of the test is to validate TempIntracommLev2 - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL) With EU3PartyTrade as True.
    // 6. Purpose of the test is to validate TempIntracommLev1 - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL) With VAT Entries with different Countries.
    // 7. Purpose of the test is to validate TempIntracommLev2 - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL) With VAT Entries with different Countries.
    // 
    // Covers Test Cases for WI - 341949
    // ----------------------------------------------------------------------------------------
    // Test Function Name                                                                TFS ID
    // ----------------------------------------------------------------------------------------
    // OnPreReportVATVIESDeclTaxAuthNL                                                   152160
    // OnAfterGetRecordTempICL1ShowAmountFalse                                           152230
    // OnAfterGetRecordTempCL2ShowAmountTrue                                             152261
    // OnAfterGetRecordTempICL1EU3PartyTradeFalse                                        152268
    // OnAfterGetRecordTempICL2EU3PartyTradeTrue                                         152267
    // OnAfterGetRecordTempICL1WithDiffCountry                                           152270
    // OnAfterGetRecordTempICL2WithDiffCountry                                           152269

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CurrencyCap: Label 'CurrencyReportCode';
        TempICL1BaseCap: Label 'TempIntracommLev1_Base';
        TempICL2BaseCap: Label 'TempIntracommLev2_Base';
        TempICL1CodeCap: Label 'TempIntracommLev1__Country_Region_Code_';
        TempICL2CodeCap: Label 'TempIntracommLev2__Country_Region_Code_';
        VATRegistrationErr: Label 'There is no VAT Registration number filled in the company information.';

    [Test]
    [HandlerFunctions('VATVIESDeclTaxAuthNLReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportVATVIESDeclTaxAuthNL()
    var
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL).

        // Setup.
        Initialize();
        UpdateVATRegistrationNoOnCompanyInformation();
        CreateVATEntryWithEU3PartyTrade(VATEntry, false);  // EU3PartyTrade as False.
        EnqueueValuesForRequestPage(VATEntry."Bill-to/Pay-to No.", false);  // ShowAmount as False.

        // Exercise.
        REPORT.Run(REPORT::"VAT- VIES Decl. Tax Auth NL");  // Opens VATVIESDeclTaxAuthNLReqPageHandler.

        // Verify: Verify value of ErrorText_Number_ on Report (VAT- VIES Decl. Tax Auth NL).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_', Format(VATRegistrationErr));
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclTaxAuthNLReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTempICL1ShowAmountFalse()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to validate VAT Entry - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL) With Show Amount as False.

        // Setup.
        Initialize();
        ModifyGeneralLedgerSetup(GeneralLedgerSetup);
        CreateVATEntryWithEU3PartyTrade(VATEntry, false);  // EU3PartyTrade as False.
        EnqueueValuesForRequestPage(VATEntry."Bill-to/Pay-to No.", false);  // ShowAmount as False.

        // Exercise and Verify: Verify values of TempIntracommLev1_Base, CurrencyReportCode on Report (VAT- VIES Decl. Tax Auth NL).
        RunReportAndVerifyXMLData(TempICL1BaseCap, CurrencyCap, -VATEntry.Base, GeneralLedgerSetup."LCY Code");
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclTaxAuthNLReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTempCL2ShowAmountTrue()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
    begin
        // Purpose of the test is to validate VAT Entry - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL) With Show Amount as True.

        // Setup.
        Initialize();
        ModifyGeneralLedgerSetup(GeneralLedgerSetup);
        CreateVATEntryWithEU3PartyTrade(VATEntry, false);  // EU3PartyTrade as False.
        EnqueueValuesForRequestPage(VATEntry."Bill-to/Pay-to No.", true);  // ShowAmount as True.

        // Exercise and Verify: Verify values of TempIntracommLev1_Base, CurrencyReportCode on Report (VAT- VIES Decl. Tax Auth NL).
        RunReportAndVerifyXMLData(
          TempICL1BaseCap, CurrencyCap, -VATEntry."Additional-Currency Base", GeneralLedgerSetup."Additional Reporting Currency");
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclTaxAuthNLReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTempICL1EU3PartyTradeFalse()
    begin
        // Purpose of the test is to validate TempIntracommLev1 - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL) With EU3PartyTrade as False.
        // Verify values of TempIntracommLev1_Base, TempIntracommLev1__Country_Region_Code_ on Report (VAT- VIES Decl. Tax Auth NL).
        VATEntryWithEU3PartyTrade(false, TempICL1BaseCap, TempICL1CodeCap);  // EU3PartyTrade as False.
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclTaxAuthNLReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTempICL2EU3PartyTradeTrue()
    begin
        // Purpose of the test is to validate TempIntracommLev2 - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL) With EU3PartyTrade as True.
        // Verify values of TempIntracommLev2_Base, TempIntracommLev2__Country_Region_Code_ on Report (VAT- VIES Decl. Tax Auth NL).
        VATEntryWithEU3PartyTrade(true, TempICL2BaseCap, TempICL2CodeCap);  // EU3PartyTrade as True.
    end;

    local procedure VATEntryWithEU3PartyTrade(EU3PartyTrade: Boolean; Caption1: Text[50]; Caption2: Text[50])
    var
        VATEntry: Record "VAT Entry";
    begin
        // Setup.
        Initialize();
        CreateVATEntryWithEU3PartyTrade(VATEntry, EU3PartyTrade);
        EnqueueValuesForRequestPage(VATEntry."Bill-to/Pay-to No.", false);  // ShowAmount as False.

        // Exercise and Verify.
        RunReportAndVerifyXMLData(Caption1, Caption2, -VATEntry.Base, VATEntry."Country/Region Code");
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclTaxAuthNLReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTempICL1WithDiffCountry()
    begin
        // Purpose of the test is to validate TempIntracommLev1 - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL) With VAT Entries with different Countries.
        // Verify values of TempIntracommLev1_Base, TempIntracommLev1__Country_Region_Code_ on Report (VAT- VIES Decl. Tax Auth NL).
        VATEntriesWithMulpleCountries(false, TempICL1BaseCap, TempICL1CodeCap);  // EU3PartyTrade as False.
    end;

    [Test]
    [HandlerFunctions('VATVIESDeclTaxAuthNLReqPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTempICL2WithDiffCountry()
    begin
        // Purpose of the test is to validate TempIntracommLev2 - OnAfterGetRecord Trigger of Report 11409 (VAT- VIES Decl. Tax Auth NL) With VAT Entries with different Countries.
        // Verify values of TempIntracommLev2_Base, TempIntracommLev2__Country_Region_Code_ on Report (VAT- VIES Decl. Tax Auth NL).
        VATEntriesWithMulpleCountries(true, TempICL2BaseCap, TempICL2CodeCap);  // EU3PartyTrade as True.
    end;

    local procedure VATEntriesWithMulpleCountries(EU3PartyTrade: Boolean; Caption1: Text[50]; Caption2: Text[50])
    var
        Customer: Record Customer;
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
    begin
        // Setup.
        Initialize();
        FindCustomerWithCountryRegion(Customer);
        CreateVATEntryWithEU3PartyTrade(VATEntry2, EU3PartyTrade);
        CreateVATEntry(
          VATEntry, VATEntry2."Bill-to/Pay-to No.", Customer."Country/Region Code", Customer."VAT Registration No.", EU3PartyTrade);
        EnqueueValuesForRequestPage(VATEntry."Bill-to/Pay-to No.", false);  // ShowAmount as False.

        // Exercise and Verify.
        RunReportAndVerifyXMLData(Caption1, Caption2, -VATEntry.Base, VATEntry."Country/Region Code");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(var Customer: Record Customer)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Country/Region Code" := CompanyInformation."Country/Region Code";
        Customer."VAT Registration No." := CompanyInformation."VAT Registration No.";
        Customer.Insert();
    end;

    local procedure CreateVATEntryWithEU3PartyTrade(var VATEntry: Record "VAT Entry"; EU3PartyTrade: Boolean)
    var
        Customer: Record Customer;
    begin
        CreateCustomer(Customer);
        CreateVATEntry(VATEntry, Customer."No.", Customer."Country/Region Code", Customer."VAT Registration No.", EU3PartyTrade);
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; BillToPayToNo: Code[20]; CountryRegionCode: Code[10]; VATRegistrationNo: Text[20]; EU3PartyTrade: Boolean)
    var
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry."Bill-to/Pay-to No." := BillToPayToNo;
        VATEntry."Country/Region Code" := CountryRegionCode;
        VATEntry."VAT Registration No." := VATRegistrationNo;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Document Type" := VATEntry."Document Type"::Invoice;
        VATEntry."VAT Calculation Type" := VATEntry."VAT Calculation Type"::"Reverse Charge VAT";
        VATEntry."EU 3-Party Trade" := EU3PartyTrade;
        VATEntry.Base := LibraryRandom.RandDec(10, 2);
        VATEntry."Additional-Currency Base" := LibraryRandom.RandDec(10, 2);
        VATEntry.Insert();
    end;

    local procedure EnqueueValuesForRequestPage(BillToPayToNo: Code[20]; ShowAmount: Boolean)
    begin
        LibraryVariableStorage.Enqueue(BillToPayToNo);  // Enqueue for VATVIESDeclTaxAuthNLReqPageHandler.
        LibraryVariableStorage.Enqueue(ShowAmount);  // Enqueue for VATVIESDeclTaxAuthNLReqPageHandler.
    end;

    local procedure FindCustomerWithCountryRegion(var Customer: Record Customer)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        Customer.SetFilter("Country/Region Code", '<>%1', CompanyInformation."Country/Region Code");
        Customer.SetFilter("VAT Registration No.", '<>''''');
        Customer.FindFirst();
    end;

    local procedure ModifyGeneralLedgerSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := LibraryUTUtility.GetNewCode10();
        GeneralLedgerSetup."Additional Reporting Currency" := CreateCurrency();
        GeneralLedgerSetup.Modify();
    end;

    local procedure RunReportAndVerifyXMLData(Caption1: Text[50]; Caption2: Text[50]; Value1: Decimal; Value2: Code[10])
    begin
        // Exercise.
        REPORT.Run(REPORT::"VAT- VIES Decl. Tax Auth NL");  // Opens VATVIESDeclTaxAuthNLReqPageHandler.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption1, Value1);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, Value2);
    end;

    local procedure UpdateVATRegistrationNoOnCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := '';
        CompanyInformation.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATVIESDeclTaxAuthNLReqPageHandler(var VATVIESDeclTaxAuthNL: TestRequestPage "VAT- VIES Decl. Tax Auth NL")
    var
        BillToPayToNo: Variant;
        ShowAmtInAddReportingCurrency: Variant;
    begin
        LibraryVariableStorage.Dequeue(BillToPayToNo);
        LibraryVariableStorage.Dequeue(ShowAmtInAddReportingCurrency);
        VATVIESDeclTaxAuthNL."VAT Entry".SetFilter("Bill-to/Pay-to No.", BillToPayToNo);
        VATVIESDeclTaxAuthNL.ShowAmtInAddReportingCurrency.SetValue(ShowAmtInAddReportingCurrency);
        VATVIESDeclTaxAuthNL.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

