codeunit 144166 "UT VAT Statement"
{
    // 2. Purpose of the test is to verify Total Amount on VAT Statement Line - OnCalcLineTotal Trigger of Report 12 (VAT Statement Report) without Add. Currency Nondeductable Amount and Base.
    // 3. Purpose of the test is to verify Total Amount on VAT Statement Line - OnCalcLineTotal Trigger of Report 12 (VAT Statement Report) with Add. Currency Nondeductable Amount and Base.
    // 4. Purpose of the test is to verify new options Non-Deductible Amount and Non- Deductible Base - OnValidate Amount Type of Annual VAT Communication Page (12126).
    // 6. Purpose of the test is to verify new options Non-Deductible Amount and Non- Deductible Base - OnValidate Amount Type of VAT Statement Page (317).
    // 
    // Covers Test Cases for WI - 346275
    // -------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                            TFS ID
    // -------------------------------------------------------------------------------------------------------------
    // OnCalcLineTotalWithoutCurrencyVATStatement                                                     255340,255342
    // OnCalcLineTotalWithCurrencyVATStatement                                                        255350
    // OnValidateAmountTypeAnnualVATCommunication,

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
        TotalAmountCap: Label 'TotalAmount';
        RowTotalingTxt: Label '%1..%2';

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnCalcLineTotalWithoutCurrencyVATStatement()
    begin
        // Purpose of the test is to verify Total Amount on VAT Statement Line - OnCalcLineTotal Trigger of Report 12 (VAT Statement Report) without Add. Currency Nondeductable Amount and Base.
        // Setup.
        Initialize();
        CalculateLineTotalOnVATStatement(0, 0);  // Passing 0 values for Add. Currency Nondeductable Amount and Add. Currency Nondeductable Base.
    end;

    [Test]
    [HandlerFunctions('VATStatementRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnCalcLineTotalWithCurrencyVATStatement()
    begin
        // Purpose of the test is to verify Total Amount on VAT Statement Line - OnCalcLineTotal Trigger of Report 12 (VAT Statement Report) with Add. Currency Nondeductable Amount and Base.

        // Setup: Update Additional Reprting Currency on GL Setup.
        Initialize();
        UpdateAdditionalReportingCurrencyOnGLSetup();
        CalculateLineTotalOnVATStatement(LibraryRandom.RandDec(10, 2), LibraryRandom.RandDecInRange(11, 100, 2));  // Passing Random values for Add. Currency Nondeductable Amount and Add. Currency Nondeductable Base.
    end;

    local procedure CalculateLineTotalOnVATStatement(AddCurrNondeductibleAmount: Decimal; AddCurrNondeductibleBase: Decimal)
    var
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VATStatementName: Record "VAT Statement Name";
    begin
        // Create VAT Posting Setup, VAT Entry, VAT Statement Names and VAT Statement Lines.
        CreateVATPostingSetup(VATPostingSetup);
        CreateVATEntry(VATEntry, VATPostingSetup, '', AddCurrNondeductibleAmount, AddCurrNondeductibleBase);  // Coutry Region Code Code as blank
        CreateVATStatementName(VATStatementName, PAGE::"VAT Statement", REPORT::"VAT Statement");
        CreateMultipleVATStatementLines(VATPostingSetup, VATStatementName);
        LibraryVariableStorage.Enqueue(VATStatementName.Name);  // Enqueue VAT Statement Name in VATStatementRequestPageHandler.

        // Exercise: Run VAT Statement Report.
        REPORT.Run(REPORT::"VAT Statement");

        // Verify: Verify Total Amounts on Report 12 (VAT Statement).
        VerifyXMLValuesOnMiscellaneousReport(VATEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateAmountTypeAnnualVATCommunication()
    var
        VATStatementLine: Record "VAT Statement Line";
        RowNo: Code[10];
        RowNo2: Code[10];
    begin
        // Purpose of the test is to verify new options Non-Deductible Amount and Non- Deductible Base - OnValidate Amount Type of Annual VAT Communication Page (12126).
        // Transaction Model property is set to Auto Commit because Commit is explicitly called in Function Template Selection of VATStmtManagement Codeunit.
        // Setup.
        Initialize();
        RowNo := LibraryUTUtility.GetNewCode10();
        RowNo2 := LibraryUTUtility.GetNewCode10();

        // Exercise.
        OpenAnnualVATCommunicationPage(RowNo, RowNo2);

        // Verify: Verify Non-Deductible Amount and Non- Deductible Base options in Amount Type field in VAT Statement Line Record.
        VerifyVATStatementLine(RowNo, VATStatementLine."Amount Type"::"Non-Deductible Amount");
        VerifyVATStatementLine(RowNo2, VATStatementLine."Amount Type"::"Non-Deductible Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnValidateAmountTypeVATStatement()
    var
        VATStatementLine: Record "VAT Statement Line";
        RowNo: Code[10];
        RowNo2: Code[10];
    begin
        // Purpose of the test is to verify new options Non-Deductible Amount and Non- Deductible Base - OnValidate Amount Type of VAT Statement Page (317).
        // Transaction Model property is set to Auto Commit because Commit is explicitly called in Function Template Selection of VATStmtManagement Codeunit.
        // Setup.
        Initialize();
        RowNo := LibraryUTUtility.GetNewCode10();
        RowNo2 := LibraryUTUtility.GetNewCode10();

        // Exercise.
        OpenVATStatementPage(RowNo, RowNo2);

        // Verify: Verify Non-Deductible Amount and Non- Deductible Base options in Amount Type field in VAT Statement Line Record.
        VerifyVATStatementLine(RowNo, VATStatementLine."Amount Type"::"Non-Deductible Amount");
        VerifyVATStatementLine(RowNo2, VATStatementLine."Amount Type"::"Non-Deductible Base");
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
        Currency."Residual Gains Account" := CreateGLAccount();
        Currency."Residual Losses Account" := CreateGLAccount();
        Currency.Insert();
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyExchangeRate(): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        CurrencyExchangeRate."Currency Code" := CreateCurrency();
        CurrencyExchangeRate."Exchange Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate."Relational Exch. Rate Amount" := LibraryRandom.RandDec(10, 2);
        CurrencyExchangeRate.Insert();
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateMultipleVATStatementLines(VATPostingSetup: Record "VAT Posting Setup"; VATStatementName: Record "VAT Statement Name")
    var
        VATStatementLine: Record "VAT Statement Line";
        RowNo: Code[10];
        RowNo2: Code[10];
    begin
        RowNo :=
          CreateVATStatementLine(
            VATPostingSetup, VATStatementName, VATStatementLine.Type::"VAT Entry Totaling",
            VATStatementLine."Amount Type"::"Non-Deductible Base", '');  // Row Totalling as blank.
        RowNo2 :=
          CreateVATStatementLine(
            VATPostingSetup, VATStatementName, VATStatementLine.Type::"VAT Entry Totaling",
            VATStatementLine."Amount Type"::"Non-Deductible Amount", '');  // Row Totalling as blank.
        CreateVATStatementLine(
          VATPostingSetup, VATStatementName, VATStatementLine.Type::"Row Totaling",
          VATStatementLine."Amount Type"::" ", StrSubstNo(RowTotalingTxt, RowNo, RowNo2));  // Black Listed as False and Amount type as blank.
    end;

    local procedure CreateVATEntry(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; CountryRegionCode: Code[10]; AddCurrNondeductibleAmt: Decimal; AddCurrNondeductibleBase: Decimal)
    var
        VATEntry2: Record "VAT Entry";
    begin
        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry.Type := VATEntry.Type::Purchase;
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry."Bill-to/Pay-to No." := LibraryUTUtility.GetNewCode();
        VATEntry."Country/Region Code" := CountryRegionCode;
        VATEntry."Operation Occurred Date" := WorkDate();
        VATEntry."Nondeductible Amount" := LibraryRandom.RandDec(10, 2);
        VATEntry."Nondeductible Base" := LibraryRandom.RandDec(100, 2);
        VATEntry."Add. Curr. Nondeductible Amt." := AddCurrNondeductibleAmt;
        VATEntry."Add. Curr. Nondeductible Base" := AddCurrNondeductibleBase;
        VATEntry.Insert();
    end;

    local procedure CreateVATStatementLine(VATPostingSetup: Record "VAT Posting Setup"; VATStatementName: Record "VAT Statement Name"; Type: Enum "VAT Statement Line Type"; AmountType: Enum "VAT Statement Line Amount Type"; RowTotaling: Text): Code[10]
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine."Statement Template Name" := VATStatementName."Statement Template Name";
        VATStatementLine."Statement Name" := VATStatementName.Name;
        VATStatementLine."Line No." := LibraryRandom.RandIntInRange(10000, 99999);  // Large random number is required for Line No.
        VATStatementLine."Row No." := LibraryUTUtility.GetNewCode10();
        VATStatementLine.Type := Type;
        VATStatementLine."Amount Type" := AmountType;
        VATStatementLine."Gen. Posting Type" := VATStatementLine."Gen. Posting Type"::Purchase;
        VATStatementLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStatementLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATStatementLine."Row Totaling" := RowTotaling;
        VATStatementLine.Insert();
        exit(VATStatementLine."Row No.");
    end;

    local procedure CreateVATStatementName(var VATStatementName: Record "VAT Statement Name"; PageID: Integer; ReportID: Integer)
    begin
        VATStatementName."Statement Template Name" := CreateVATStatementTemplate(PageID, ReportID);
        VATStatementName.Name := LibraryUTUtility.GetNewCode10();
        VATStatementName.Insert();
    end;

    local procedure CreateVATStatementTemplate(PageID: Integer; VATStatementReportID: Integer): Code[10]
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        VATStatementTemplate.Name := LibraryUTUtility.GetNewCode10();
        VATStatementTemplate."Page ID" := PageID;
        VATStatementTemplate."VAT Statement Report ID" := VATStatementReportID;
        VATStatementTemplate.Insert();
        exit(VATStatementTemplate.Name);
    end;

    local procedure OpenAnnualVATCommunicationPage(RowNo: Code[10]; RowNo2: Code[10])
    var
        AnnualVATCommunication: TestPage "Annual VAT Communication";
    begin
        AnnualVATCommunication.OpenEdit();
        AnnualVATCommunication."Row No.".SetValue(RowNo);
        AnnualVATCommunication."Amount Type".SetValue(AnnualVATCommunication."Amount Type".GetOption(7));  // Set Amount Type as Non-Deductible Amount.
        AnnualVATCommunication.Next();
        AnnualVATCommunication."Row No.".SetValue(RowNo2);
        AnnualVATCommunication."Amount Type".SetValue(AnnualVATCommunication."Amount Type".GetOption(8));  // Set Amount Type as Non-Deductible Base.
        AnnualVATCommunication.OK().Invoke();
    end;

    local procedure OpenVATStatementPage(RowNo: Code[10]; RowNo2: Code[10])
    var
        VATStatement: TestPage "VAT Statement";
    begin
        VATStatement.OpenEdit();
        VATStatement."Row No.".SetValue(RowNo);
        VATStatement."Amount Type".SetValue(VATStatement."Amount Type".GetOption(7));  // Set Amount Type as Non-Deductible Amount.
        VATStatement.Next();
        VATStatement."Row No.".SetValue(RowNo2);
        VATStatement."Amount Type".SetValue(VATStatement."Amount Type".GetOption(8));  // Set Amount Type as Non-Deductible Base.
        VATStatement.OK().Invoke();
    end;

    local procedure VerifyVATStatementLine(RowNo: Code[10]; AmountType: Enum "VAT Statement Line Amount Type")
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        VATStatementLine.SetRange("Row No.", RowNo);
        VATStatementLine.FindFirst();
        VATStatementLine.TestField("Amount Type", AmountType);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup."VAT Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATPostingSetup."VAT Prod. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATPostingSetup."Nondeductible VAT Account" := LibraryUTUtility.GetNewCode();
        VATPostingSetup."Deductible %" := LibraryRandom.RandInt(5);
        VATPostingSetup.Insert();
    end;

    local procedure UpdateAdditionalReportingCurrencyOnGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CreateCurrencyExchangeRate();
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyXMLValuesOnMiscellaneousReport(VATEntry: Record "VAT Entry")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(TotalAmountCap, VATEntry."Nondeductible Amount");
        LibraryReportDataset.AssertElementWithValueExists(TotalAmountCap, VATEntry."Nondeductible Base");
        LibraryReportDataset.AssertElementWithValueExists(
          TotalAmountCap, VATEntry."Nondeductible Base" + VATEntry."Nondeductible Amount");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementRequestPageHandler(var VATStatement: TestRequestPage "VAT Statement")
    var
        StatementName: Variant;
    begin
        LibraryVariableStorage.Dequeue(StatementName);
        VATStatement."VAT Statement Line".SetFilter("Statement Name", StatementName);
        VATStatement.StartingDate.SetValue(WorkDate());
        VATStatement.EndingDate.SetValue(WorkDate());
        VATStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

