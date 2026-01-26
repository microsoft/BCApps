codeunit 142057 "UT REP VATFUNC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";
        ValueMustBeEqualMsg: Label 'Value must be Equal.';

    [Test]
    [HandlerFunctions('VATStmtGermanySelectionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSelectionClosedVATStatementGermany()
    var
        EntrySelection: Option Open,Closed;
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 11005 - VAT Statement Germany.
        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(EntrySelection::Closed);  // Enqueue value for Selection Type - Closed used in VATStmtGermanySelectionRequestPageHandler.

        // Exercise: Run the VAT Statement Germany report. Opens handler - VATStmtGermanySelectionRequestPageHandler.
        REPORT.Run(REPORT::"VAT Statement Germany");

        // Verify: Verify Selection Type on Report VAT Statement Germany.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Selection', 1);  // Use 1 for Selection Option Closed.
    end;

    [Test]
    [HandlerFunctions('VATStmtGermanyPeriodSelectionRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportPeriodSelectionVATStatementGermany()
    begin
        // Purpose of the test is to validate OnPreReport Trigger of Report 11005 - VAT Statement Germany.
        // Setup.
        Initialize();

        // Exercise: Run Report with Period Selection Type Before and Within Period set in Handler - VATStmtGermanyPeriodSelectionRequestPageHandler.
        REPORT.Run(REPORT::"VAT Statement Germany");

        // Verify: Verify Period Selection on Report VAT Statement Germany.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Heading', 'VAT entries before and within the period');
    end;

    [Test]
    [HandlerFunctions('VATStmtGermanyUseAmtsInAddCurrRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemVATStatementLineVATStatementGermany()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to validate OnPreDataItem Trigger of VAT Statement Line on Report 11005 - VAT Statement Germany.

        // Setup: Update General Ledger Setup.
        Initialize();
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := LibraryUTUtility.GetNewCode10();
        GeneralLedgerSetup.Modify();

        // Exercise: Run Report for Additional Reporting Currency set in handler - VATStmtGermanyUseAmtsInAddCurrRequestPageHandler.
        REPORT.Run(REPORT::"VAT Statement Germany");

        // Verify: Verify Additional Reporting Currency on Report VAT Statement Germany.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('HeaderText', StrSubstNo('All amounts are in %1', GeneralLedgerSetup."Additional Reporting Currency"));
    end;

    [Test]
    [HandlerFunctions('VATStmtGermanyInitializeRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure InitializeRequestVATStatementGermany()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
        VATStatementGermany: Report "VAT Statement Germany";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
    begin
        // Purpose of the test is to validate InitializeRequest function of Report 11005 - VAT Statement Germany.

        // Setup: Initialize parameters of InitializeRequest function of Report VAT Statement Germany.
        Initialize();
        VATStatementLine.SetRange("Date Filter", 0D, WorkDate());
        VATStatementGermany.InitializeRequest(VATStatementName, VATStatementLine, "VAT Statement Report Selection"::Closed, PeriodSelection::"Within Period", false, false);  // Boolean False for PrintInIntegers and Additional Currency.

        // Exercise And Verify: Run Report and verify initialized values in the handler - VATStmtGermanyInitializeRequestPageHandler.
        VATStatementGermany.Run();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcLineTotalTypeAccountTotalingVATStmtGermany()
    var
        GLAccount: Record "G/L Account";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementGermany: Report "VAT Statement Germany";
        TotalAmount: Decimal;
        TotalBase: Decimal;
        TotalEmpty: Decimal;
        TotalUnrealizedAmount: Decimal;
        TotalUnrealizedBase: Decimal;
    begin
        // Purpose of the test is to validate CalcLineTotal function of Report 11005 - VAT Statement Germany.

        // Setup: Create General Ledger Account. Create VAT Statement Line.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateVATStatementLine(VATStatementLine, GLAccount."No.", VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type");

        // Exercise.
        VATStatementGermany.CalcLineTotal(VATStatementLine, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, 0);  // Value 0 for Level.

        // Verify: Verify Net Change of General Ledger Account is updated with opposite sign of TotalEmpty after CalcLineTotal function.
        GLAccount.CalcFields("Net Change");
        GLAccount.TestField("Net Change", -TotalEmpty);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcLineTotalAmtTypeAmountVATStatementGermany()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate CalcLineTotal function for Amount Type - Amount of Report 11005 - VAT Statement Germany.
        // Setup.
        Initialize();
        CalcLineTotalAmtTypeVATStatementGermany(VATStatementLine."Amount Type"::Amount);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcLineTotalAmtTypeBaseVATStatementGermany()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate CalcLineTotal function for Amount Type - Base of Report 11005 - VAT Statement Germany.
        // Setup.
        Initialize();
        CalcLineTotalAmtTypeVATStatementGermany(VATStatementLine."Amount Type"::Base);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcLineTotalAmtTypeUnrealizedAmtVATStmtGermany()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate CalcLineTotal function for Amount Type - Unrealized Amount of Report 11005 - VAT Statement Germany.
        // Setup.
        Initialize();
        CalcLineTotalAmtTypeVATStatementGermany(VATStatementLine."Amount Type"::"Unrealized Amount");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcLineTotalAmtTypeUnrealizedBaseVATStmtGermany()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate CalcLineTotal function for Amount Type - Unrealized Base of Report 11005 - VAT Statement Germany.
        // Setup.
        Initialize();
        CalcLineTotalAmtTypeVATStatementGermany(VATStatementLine."Amount Type"::"Unrealized Base");
    end;

    local procedure CalcLineTotalAmtTypeVATStatementGermany(AmountType: Enum "VAT Statement Line Amount Type")
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementGermany: Report "VAT Statement Germany";
        TotalAmount: Decimal;
        TotalBase: Decimal;
        TotalEmpty: Decimal;
        TotalUnrealizedAmount: Decimal;
        TotalUnrealizedBase: Decimal;
    begin
        // Create VAT Entry with VAT Statement Line.
        CreateVATEntryForVATStatementLine(VATStatementLine, VATEntry, AmountType);

        // Exercise.
        VATStatementGermany.CalcLineTotal(VATStatementLine, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, 0);  // Value 0 for Level.

        // Verify: Verify  various Amounts of VAT Entry updated with opposite sign.
        VerifyVATEntry(VATEntry, VATStatementLine."Amount Type", TotalAmount, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcLineTotalTypeRowTotalingVATStmtGermany()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatementGermany: Report "VAT Statement Germany";
        TotalAmount: Decimal;
        TotalBase: Decimal;
        TotalEmpty: Decimal;
        TotalUnrealizedAmount: Decimal;
        TotalUnrealizedBase: Decimal;
    begin
        // Purpose of the test is to validate CalcLineTotal function of Report 11005 - VAT Statement Germany.

        // Setup: Create and update VAT Statement Line.
        Initialize();
        CreateVATStatementLine(VATStatementLine, '', VATStatementLine.Type::"Row Totaling", VATStatementLine."Amount Type");
        VATStatementLine."Row No." := Format(LibraryRandom.RandInt(10));
        VATStatementLine."Row Totaling" := VATStatementLine."Row No.";
        VATStatementLine.Modify();

        // Exercise.
        asserterror VATStatementGermany.CalcLineTotal(VATStatementLine, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, 0);  // Value 0 for Level.

        // Verify: Verify Error Code for Error message - Row No error in VAT Statement Line for selected Statement Template Name and Statement Name.
        Assert.ExpectedErrorCode('NCLCSRTS:TableErrorStr');
    end;

    [Test]
    [HandlerFunctions('VATStatementGermanyPrintInIntegerRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATStatementLineVATStmtGermany()
    var
        GLAccount: Record "G/L Account";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementName: Record "VAT Statement Name";
    begin
        // Purpose of the test is to validate OnAfterGetRecord Trigger of VATStatementLine of Report 11005 - VAT Statement Germany.

        // Setup: Create General Ledger Account. Create VAT Statement Line.
        Initialize();
        CreateGLAccount(GLAccount);
        CreateVATStatementLine(VATStatementLine, GLAccount."No.", VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type");
        CreateVATStatementName(VATStatementName, VATStatementLine."Statement Template Name", VATStatementLine."Statement Name");

        // Exercise: Run Report with Statement Template Name and set PrintInInteger TRUE in handler - VATStatementGermanyPrintInIntegerRequestPageHandler.
        REPORT.Run(REPORT::"VAT Statement Germany");

        // Verify: Verify TotalEmpty Amount calculated by Report VAT Statement Germany with PrinInInteger as TRUE.
        GLAccount.CalcFields("Net Change");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalEmpty', Round(-GLAccount."Net Change", 1, '<'));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ReportingPeriodTextVATVieDeclarationTaxDE()
    var
        VATViesDeclarationTaxDE: Report "VAT-Vies Declaration Tax - DE";
    begin
        // Purpose of the test is to validate ReportingPeriodText function of Report 11007 - VAT-Vies Declaration Tax - DE.
        // Setup.
        Initialize();

        // Exercise and Verify: Verify returned value of function ReportingPeriodText of Report - VAT-Vies Declaration Tax - DE.
        Assert.AreEqual('Februar', VATViesDeclarationTaxDE.ReportingPeriodText(1), ValueMustBeEqualMsg);  // Use 1 for  Option ReportingPeriod Februar.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GetIndicatorCodeVATVieDeclarationTaxDE()
    var
        VATViesDeclarationTaxDE: Report "VAT-Vies Declaration Tax - DE";
    begin
        // Purpose of the test is to validate GetIndicatorCode function of Report 11007 - VAT-Vies Declaration Tax - DE.
        // Setup.
        Initialize();

        // Exercise and Verify: Verify returned value of function GetIndicatorCode of Report - VAT-Vies Declaration Tax - DE.
        Assert.AreEqual(2, VATViesDeclarationTaxDE.GetIndicatorCode(true, false), ValueMustBeEqualMsg);  // Value 2 is returned by function GetIndicatorCode for TRUE value of EU 3-Party Trade and FALSE for EU Service field of VAT Entry.
    end;

    [Test]
    [HandlerFunctions('VATViesDeclarationTaxDESaveAsPDFReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintVATVieDeclarationTaxDE()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 333888] Report "VAT-Vies Declaration Tax - DE" can be printed without RDLC rendering errors
        Initialize();

        // [WHEN] Report "VAT-Vies Declaration Tax - DE" is being printed to PDF
        Report.Run(Report::"VAT-Vies Declaration Tax - DE");
        // [THEN] No RDLC rendering errors
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATStatementLineNonDedVATBaseType()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementGermany: Report "VAT Statement Germany";
        TotalAmount: Decimal;
        TotalBase: Decimal;
        TotalEmpty: Decimal;
        TotalUnrealizedAmount: Decimal;
        TotalUnrealizedBase: Decimal;
    begin
        // [SCENARIO 524882] The CalcLineTotal function of the VAT Statement Germany report calculates the Non-Deductible VAT Base correctly

        // [GIVEN] VAT Statement Line with Amount Type = Non-Deductible Base
        // [GIVEN] VAT Entry with Non-Deductible VAT Base = 100
        CreateVATEntryForVATStatementLine(VATStatementLine, VATEntry, VATStatementLine."Amount Type"::"Non-Deductible Base");

        // [[WHEN] Call the CalcLineTotal function for the VAT statement line
        VATStatementGermany.CalcLineTotal(VATStatementLine, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, 0);  // Value 0 for Level.

        // [[THEN] TotalBase is 100
        Assert.AreEqual(-VATEntry."Non-Deductible VAT Base", TotalBase, ValueMustBeEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATStatementLineNonDedVATAmountType()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementGermany: Report "VAT Statement Germany";
        TotalAmount: Decimal;
        TotalBase: Decimal;
        TotalEmpty: Decimal;
        TotalUnrealizedAmount: Decimal;
        TotalUnrealizedBase: Decimal;
    begin
        // [SCENARIO 524882] The CalcLineTotal function of the VAT Statement Germany report calculates the Non-Deductible VAT amount correctly

        // [GIVEN] VAT Statement Line with Amount Type = Non-Deductible Amount
        // [GIVEN] VAT Entry with Non-Deductible VAT Amount = 100
        CreateVATEntryForVATStatementLine(VATStatementLine, VATEntry, VATStatementLine."Amount Type"::"Non-Deductible Amount");

        // [[WHEN] Call the CalcLineTotal function for the VAT statement line
        VATStatementGermany.CalcLineTotal(VATStatementLine, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, 0);  // Value 0 for Level.

        // [[THEN] TotalAmount is 100
        Assert.AreEqual(-VATEntry."Non-Deductible VAT Amount", TotalAmount, ValueMustBeEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATStatementLineFullBaseType()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementGermany: Report "VAT Statement Germany";
        TotalAmount: Decimal;
        TotalBase: Decimal;
        TotalEmpty: Decimal;
        TotalUnrealizedAmount: Decimal;
        TotalUnrealizedBase: Decimal;
    begin
        // [SCENARIO 524882] The CalcLineTotal function of the VAT Statement Germany report calculates the sum of Base and Non-Deductible VAT Base correctly

        // [GIVEN] VAT Statement Line with Amount Type = Full Base
        // [GIVEN] VAT Entry with Base = 100 and Non-Deductible VAT Base = 50
        CreateVATEntryForVATStatementLine(VATStatementLine, VATEntry, VATStatementLine."Amount Type"::"Full Base");

        // [[WHEN] Call the CalcLineTotal function for the VAT statement line
        VATStatementGermany.CalcLineTotal(VATStatementLine, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, 0);  // Value 0 for Level.

        // [[THEN] TotalBase is 500
        Assert.AreEqual(-VATEntry.Base - VATEntry."Non-Deductible VAT Base", TotalBase, ValueMustBeEqualMsg);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATStatementLineFullAmountType()
    var
        VATEntry: Record "VAT Entry";
        VATStatementLine: Record "VAT Statement Line";
        VATStatementGermany: Report "VAT Statement Germany";
        TotalAmount: Decimal;
        TotalBase: Decimal;
        TotalEmpty: Decimal;
        TotalUnrealizedAmount: Decimal;
        TotalUnrealizedBase: Decimal;
    begin
        // [SCENARIO 524882] The CalcLineTotal function of the VAT Statement Germany report calculates the sum of Amount and Non-Deductible VAT Amount correctly

        // [GIVEN] VAT Statement Line with Amount Type = Full Amount
        // [GIVEN] VAT Entry with Base = 100 and Non-Deductible VAT Base = 50
        CreateVATEntryForVATStatementLine(VATStatementLine, VATEntry, VATStatementLine."Amount Type"::"Full Amount");

        // [[WHEN] Call the CalcLineTotal function for the VAT statement line
        VATStatementGermany.CalcLineTotal(VATStatementLine, TotalAmount, TotalEmpty, TotalBase, TotalUnrealizedAmount, TotalUnrealizedBase, 0);  // Value 0 for Level.

        // [[THEN] TotalAmount is 150
        Assert.AreEqual(-VATEntry.Amount - VATEntry."Non-Deductible VAT Amount", TotalAmount, ValueMustBeEqualMsg);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Insert();

        // G/L Entry record required for Net Change of G/L Account.
        GLEntry2.FindLast();
        GLEntry."Entry No." := GLEntry2."Entry No." + 1;
        GLEntry.Amount := LibraryRandom.RandDec(10, 2);
        GLEntry."G/L Account No." := GLAccount."No.";
        GLEntry.Insert();
    end;

    local procedure CreateVATEntryForVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; var VATEntry: Record "VAT Entry"; AmountType: Enum "VAT Statement Line Amount Type")
    var
        VATEntry2: Record "VAT Entry";
    begin
        CreateVATStatementLine(VATStatementLine, '', VATStatementLine.Type::"VAT Entry Totaling", AmountType);
        VATStatementLine."VAT Bus. Posting Group" := LibraryUTUtility.GetNewCode10();
        VATStatementLine.Modify();

        VATEntry2.FindLast();
        VATEntry."Entry No." := VATEntry2."Entry No." + 1;
        VATEntry."VAT Bus. Posting Group" := VATStatementLine."VAT Bus. Posting Group";
        case VATStatementLine."Amount Type" of
            VATStatementLine."Amount Type"::Amount:
                VATEntry.Amount := LibraryRandom.RandDec(10, 2);
            VATStatementLine."Amount Type"::Base:
                VATEntry.Base := LibraryRandom.RandDec(10, 2);
            VATStatementLine."Amount Type"::"Unrealized Amount":
                VATEntry."Unrealized Amount" := LibraryRandom.RandDec(10, 2);
            VATStatementLine."Amount Type"::"Unrealized Base":
                VATEntry."Unrealized Base" := LibraryRandom.RandDec(10, 2);
            VATStatementLine."Amount Type"::"Non-Deductible Base":
                VATEntry."Non-Deductible VAT Base" := LibraryRandom.RandDec(10, 2);
            VATStatementLine."Amount Type"::"Non-Deductible Amount":
                VATEntry."Non-Deductible VAT Amount" := LibraryRandom.RandDec(10, 2);
            VATStatementLine."Amount Type"::"Full Base":
                begin
                    VATEntry.Base := LibraryRandom.RandDec(10, 2);
                    VATEntry."Non-Deductible VAT Base" := LibraryRandom.RandDec(10, 2);
                end;
            VATStatementLine."Amount Type"::"Full Amount":
                begin
                    VATEntry.Amount := LibraryRandom.RandDec(10, 2);
                    VATEntry."Non-Deductible VAT Amount" := LibraryRandom.RandDec(10, 2);
                end;
        end;
        VATEntry.Insert();
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; AccountTotaling: Code[20]; Type: Enum "VAT Statement Line Type"; AmountType: Enum "VAT Statement Line Amount Type")
    begin
        VATStatementLine."Statement Template Name" := LibraryUTUtility.GetNewCode10();
        VATStatementLine."Statement Name" := LibraryUTUtility.GetNewCode10();
        VATStatementLine."Account Totaling" := AccountTotaling;
        VATStatementLine."Calculate with" := VATStatementLine."Calculate with"::"Opposite Sign";
        VATStatementLine.Type := Type;
        VATStatementLine."Amount Type" := AmountType;
        VATStatementLine.Insert();
    end;

    local procedure CreateVATStatementName(var VATStatementName: Record "VAT Statement Name"; StatementTemplateName: Code[10]; Name: Code[10])
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        VATStatementTemplate.Name := StatementTemplateName;
        VATStatementTemplate.Insert();

        VATStatementName."Statement Template Name" := VATStatementTemplate.Name;
        VATStatementName.Name := Name;
        VATStatementName.Insert();
        LibraryVariableStorage.Enqueue(VATStatementName."Statement Template Name");  // Enqueue value for VATStatementGermanyPrintInIntegerRequestPageHandler.
    end;

    local procedure VerifyVATEntry(VATEntry: Record "VAT Entry"; AmountType: Enum "VAT Statement Line Amount Type"; TotalAmount: Decimal; TotalBase: Decimal; TotalUnrealizedAmount: Decimal; TotalUnrealizedBase: Decimal)
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        case AmountType of
            VATStatementLine."Amount Type"::Amount:
                VATEntry.TestField(Amount, -TotalAmount);
            VATStatementLine."Amount Type"::Base:
                VATEntry.TestField(Base, -TotalBase);
            VATStatementLine."Amount Type"::"Unrealized Amount":
                VATEntry.TestField("Unrealized Amount", -TotalUnrealizedAmount);
            VATStatementLine."Amount Type"::"Unrealized Base":
                VATEntry.TestField("Unrealized Base", -TotalUnrealizedBase);
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStmtGermanyInitializeRequestPageHandler(var VATStatementGermany: TestRequestPage "VAT Statement Germany")
    var
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        EntrySelection: Option Open,Closed;
    begin
        VATStatementGermany.Selection.AssertEquals(EntrySelection::Closed);
        VATStatementGermany.PeriodSelection.AssertEquals(PeriodSelection::"Within Period");
        VATStatementGermany.EndDateReq.AssertEquals(WorkDate());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStmtGermanyPeriodSelectionRequestPageHandler(var VATStatementGermany: TestRequestPage "VAT Statement Germany")
    var
        PeriodSelection: Enum "VAT Statement Report Period Selection";
    begin
        VATStatementGermany.PeriodSelection.SetValue(PeriodSelection::"Before and Within Period");
        VATStatementGermany.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStmtGermanySelectionRequestPageHandler(var VATStatementGermany: TestRequestPage "VAT Statement Germany")
    var
        EntrySelection: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntrySelection);
        VATStatementGermany.Selection.SetValue(EntrySelection);
        VATStatementGermany.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStmtGermanyUseAmtsInAddCurrRequestPageHandler(var VATStatementGermany: TestRequestPage "VAT Statement Germany")
    begin
        VATStatementGermany.UseAmtsInAddCurr.SetValue(true);
        VATStatementGermany.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementGermanyPrintInIntegerRequestPageHandler(var VATStatementGermany: TestRequestPage "VAT Statement Germany")
    var
        StatementTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(StatementTemplateName);
        VATStatementGermany."VAT Statement Name".SetFilter("Statement Template Name", StatementTemplateName);
        VATStatementGermany.PrintInIntegers.SetValue(true);
        VATStatementGermany.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure VATViesDeclarationTaxDESaveAsPDFReportHandler(var VATViesDeclarationTaxDE: Report "VAT-Vies Declaration Tax - DE")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("VAT Reporting Date", WorkDate());
        VATEntry.SetFilter("VAT Registration No.", '<>%1', '');
        VATEntry.SetFilter("Country/Region Code", '<>%1', '');
        VATViesDeclarationTaxDE.SetTableView(VATEntry);
        VATViesDeclarationTaxDE.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;
}

