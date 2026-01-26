codeunit 142064 "UT REP VATSTAT"
{
    // // [FEATURE] [VAT Statement]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        HeaderTextMsg: Label 'All amounts are in %1';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('GLVATReconciliationReportHandler,ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemLCYCodeGLVATReconciliation()
    var
        VATStatementLine: Record "VAT Statement Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to validate the VAT Statement Name - OnPreDataItem trigger of GLVATReconciliation Report for LCY Code.
        // Setup.
        Initialize();
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type");

        // Exercise.
        RunGLVATReconciliationReport(VATStatementLine);

        // Verify: Verify the LCY Code on GLVATReconciliation Report.
        LibraryReportDataset.LoadDataSetFile();
        GeneralLedgerSetup.Get();
        LibraryReportDataset.AssertElementWithValueExists('HeaderText', StrSubstNo(HeaderTextMsg, GeneralLedgerSetup."LCY Code"));
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationReportHandler,ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportNoOfEntriesGLVATReconciliation()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate the OnPreReport trigger of GLVATReconciliation Report for Period Selection.
        // Setup.
        Initialize();
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type");

        // Exercise.
        RunGLVATReconciliationReport(VATStatementLine);

        // Verify: Verify the Period Selection and No of Lines on GLVATReconciliation Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Header', 'VAT entries before and within the period');
        LibraryReportDataset.AssertElementWithValueExists('Number', 1);
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationSelectionReportHandler,ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSelectionAllGLVATReconciliation()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate the OnPreReport trigger of GLVATReconciliation Report for Selection as Open and Closed.
        // Setup.
        Initialize();
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type");

        // Exercise.
        RunGLVATReconciliationReport(VATStatementLine);

        // Verify: Verify the Selection as Open and Closed on GLVATReconciliation Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Header2', 'The report includes all VAT entries.');
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationClosedEntryReportHandler,ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreReportSelectionClosedGLVATReconciliation()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate the OnPreReport trigger of GLVATReconciliation Report for Selection as Closed.
        // Setup.
        Initialize();
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type");

        // Exercise.
        RunGLVATReconciliationReport(VATStatementLine);

        // Verify: Verify the Selection as Closed on GLVATReconciliation Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Header2', 'The report includes only closed VAT entries.');
    end;

    [Test]
    [HandlerFunctions('AddCurrencyVATAdvNotAccProofReportHandler,ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemAddCurrencyGLVATReconciliation()
    var
        VATStatementLine: Record "VAT Statement Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Purpose of the test is to validate the VAT Statement Name - OnPreDataItem trigger of GLVATReconciliation Report for Additional Reporting Currency.
        // Setup.
        Initialize();
        UpdateGeneralLedgerSetup();  // Update Additional Reporting Currency on General Ledger Setup.
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type");

        // Exercise.
        RunGLVATReconciliationReport(VATStatementLine);

        // Verify: Verify the Additional Reporting Currency on GLVATReconciliation Report.
        LibraryReportDataset.LoadDataSetFile();
        GeneralLedgerSetup.Get();
        LibraryReportDataset.AssertElementWithValueExists('HeaderText',
          StrSubstNo(HeaderTextMsg, GeneralLedgerSetup."Additional Reporting Currency"));
    end;

    [Test]
    [HandlerFunctions('AddCurrencyVATAdvNotAccProofReportHandler,ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAddCurrencyGLVATReconciliation()
    var
        VATStatementLine: Record "VAT Statement Line";
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate the G/L Account - OnAfterGetRecord trigger of GLVATReconciliation Report for Additional-Currency Net Change.
        // Setup.
        Initialize();
        UpdateGeneralLedgerSetup();  // Update Additional Reporting Currency on General Ledger Setup.
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type"::Amount);

        // Exercise.
        RunGLVATReconciliationReport(VATStatementLine);

        // Verify: Verify the Total Amount on GLVATReconciliation Report.
        LibraryReportDataset.LoadDataSetFile();
        GLAccount.Get(VATStatementLine."Account Totaling");
        GLAccount.CalcFields("Additional-Currency Net Change");
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GLAccount."Additional-Currency Net Change");
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationClosedEntryReportHandler,ConfirmHandlerTRUE')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTotalAmountGLVATReconciliation()
    var
        VATStatementLine: Record "VAT Statement Line";
        GLAccount: Record "G/L Account";
    begin
        // Purpose of the test is to validate the G/L Account - OnAfterGetRecord trigger of GLVATReconciliation Report for Net Change.
        // Setup.
        Initialize();
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type"::Amount);

        // Exercise.
        RunGLVATReconciliationReport(VATStatementLine);

        // Verify: Verify the Total Amount on GLVATReconciliation Report.
        LibraryReportDataset.LoadDataSetFile();
        GLAccount.Get(VATStatementLine."Account Totaling");
        GLAccount.CalcFields("Net Change");
        LibraryReportDataset.AssertElementWithValueExists('TotalAmount', GLAccount."Net Change");
    end;

    [Test]
    [HandlerFunctions('VATStatementReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordVATStatementReportError()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate the VAT Statement Line - OnAfterGetRecord trigger of VAT Statement Report.
        // Setup.
        Initialize();
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"VAT Entry Totaling", VATStatementLine."Amount Type");

        // Exercise.
        asserterror RunVATStatementReport(VATStatementLine);

        // Verify: Verify the Error Code, Actual Error - Amount Type must not be blank, after running VAT Statement Report.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CalcLineTotalVATStatementReportError()
    var
        VATStatementLine: Record "VAT Statement Line";
        VATStatement: Report "VAT Statement";
        TotalAmount: Decimal;
    begin
        // Purpose of the test is to validate the CalcLineTotal function of VAT Statement Report.
        // Setup.
        Initialize();
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"VAT Entry Totaling", VATStatementLine."Amount Type");

        // Exercise.
        TotalAmount := 0;  // Assignment required as the parameter is passed by Reference in CalcLineTotal function of VAT Statement Report.
        asserterror VATStatement.CalcLineTotal(VATStatementLine, TotalAmount, 0);  // Zero Level.

        // Verify: Verify the Error Code, Actual Error - Amount Type must not be blank, after calling Calculate Line Total function of VAT Statement Report.
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [HandlerFunctions('VATStatementScheduleReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordRowTotalingVATStatementSchedule()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate the VAT Statement Line - OnAfterGetRecord trigger of VAT Statement Schedule Report for VAT Statement Line Type of Row Totaling.
        // Setup.
        Initialize();
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"Row Totaling", VATStatementLine."Amount Type");

        // Exercise.
        RunVATStatementScheduleReport(VATStatementLine);

        // Verify: Verify the VAT Statement Line Type after running VAT Statement Schedule Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Totaling', VATStatementLine."Row Totaling");
    end;

    [Test]
    [HandlerFunctions('VATStatementScheduleReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordAccTotalingVATStatementSchedule()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate the VAT Statement Line - OnAfterGetRecord trigger of VAT Statement Schedule Report for VAT Statement Line Type of Account Totaling.
        // Setup.
        Initialize();
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type");

        // Exercise.
        RunVATStatementScheduleReport(VATStatementLine);

        // Verify: Verify the VAT Statement Line Type after running VAT Statement Schedule Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Totaling', VATStatementLine."Account Totaling");
    end;

    [Test]
    [HandlerFunctions('VATStatementScheduleReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBlankTotalingVATStatementSchedule()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // Purpose of the test is to validate the VAT Statement Line - OnAfterGetRecord trigger of VAT Statement Schedule Report for blank VAT Statement Line Type.
        // Setup.
        Initialize();
        CreateVATStatementLine(VATStatementLine, VATStatementLine.Type::"Row Totaling", VATStatementLine."Amount Type");
        VATStatementLine."Account Totaling" := '';
        VATStatementLine.Modify();

        // Exercise.
        RunVATStatementScheduleReport(VATStatementLine);

        // Verify: Verify the VAT Statement Line Type after running VAT Statement Schedule Report. Verify blank Totaling as Account Totaling is blank.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Totaling', '');
    end;

    [Test]
    [HandlerFunctions('UpdateVATStatementTemplateBlankReportHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordBlankTemplUpdateVATStatTemplError()
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        // Purpose of the test is to validate Integer - OnAfterGetRecord of Update VAT Statement Template Report for blank VAT Statement Template Name.
        // Setup.
        Initialize();
        CreateVATStatementTemplate(VATStatementTemplate);

        // Exercise.
        asserterror REPORT.Run(REPORT::"Update VAT Statement Template");

        // Verify: Verify the Error Code, Error - Please specify a VAT Statement Template Name in Report Update VAT Statement Template.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('UpdateVATStatementTemplateReportHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordWithTemplateUpdateVATStatTemplate()
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        // Purpose of the test is to validate Integer - OnAfterGetRecord of Update VAT Statement Template Report for blank VAT Statement Description.
        // Setup.
        Initialize();
        CreateVATStatementTemplate(VATStatementTemplate);
        LibraryVariableStorage.Enqueue(VATStatementTemplate.Name);  // Enqueue VAT Statement Template Name for use in UpdateVATStatementTemplateReportHandler.

        // Exercise.
        Commit();  // Commit required as the explicit Commit used in Update function of Codeunit ID: 11110 - Update VAT AT.
        REPORT.Run(REPORT::"Update VAT Statement Template");

        // Verify: Verify the VAT Statement Template after running Update VAT Statement Template Report.
        VerifyVATStatementTemplate(VATStatementTemplate.Name);
    end;

    local procedure Initialize()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryVariableStorage.Clear();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; Type: Enum "VAT Statement Line Type"; AmountType: Enum "VAT Statement Line Amount Type")
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        VATStatementName."Statement Template Name" := LibraryUTUtility.GetNewCode10();
        VATStatementName.Name := LibraryUTUtility.GetNewCode10();
        VATStatementName.Insert();

        VATStatementLine."Statement Template Name" := VATStatementName."Statement Template Name";
        VATStatementLine."Statement Name" := VATStatementName.Name;
        VATStatementLine."Line No." := 1;
        VATStatementLine."Account Totaling" := CreateGLAccount();
        VATStatementLine.Type := Type;
        VATStatementLine."Amount Type" := AmountType;
        VATStatementLine.Insert();
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount."No." := LibraryUTUtility.GetNewCode();
        GLAccount.Totaling := '<>''''';  // Non blank Totaling GL Account.
        GLAccount.Insert();
        exit(GLAccount."No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        Currency.Code := LibraryUTUtility.GetNewCode10();
        Currency.Insert();
        CurrencyExchangeRate."Currency Code" := Currency.Code;
        CurrencyExchangeRate."Starting Date" := WorkDate();
        CurrencyExchangeRate."Exchange Rate Amount" := 1;
        CurrencyExchangeRate."Relational Exch. Rate Amount" := 1;
        CurrencyExchangeRate.Insert();
        exit(CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreateVATStatementTemplate(var VATStatementTemplate: Record "VAT Statement Template")
    begin
        VATStatementTemplate.Name := LibraryUTUtility.GetNewCode10();
        VATStatementTemplate.Description := LibraryUTUtility.GetNewCode();
        VATStatementTemplate.Insert();
    end;

    local procedure RunGLVATReconciliationReport(VATStatementLine: Record "VAT Statement Line")
    var
        GlVatReconciliation: Report "G/L - VAT Reconciliation";
    begin
        VATStatementLine.SetRange("Statement Name", VATStatementLine."Statement Name");
        GlVatReconciliation.SetTableView(VATStatementLine);
        GlVatReconciliation.Run();  // Invokes GLVATReconciliationReportHandler, AddCurrencyVATAdvNotAccProofReportHandler and GLVATReconciliationSelectionReportHandler.
    end;

    local procedure RunVATStatementScheduleReport(VATStatementLine: Record "VAT Statement Line")
    var
        VATStatementSchedule: Report "VAT Statement Schedule";
    begin
        VATStatementLine.SetRange("Statement Name", VATStatementLine."Statement Name");
        VATStatementSchedule.SetTableView(VATStatementLine);
        VATStatementSchedule.Run();  // Invokes VATStatementScheduleReportHandler.
    end;

    local procedure RunVATStatementReport(VATStatementLine: Record "VAT Statement Line")
    var
        VATStatement: Report "VAT Statement";
    begin
        VATStatementLine.SetRange("Statement Name", VATStatementLine."Statement Name");
        VATStatement.SetTableView(VATStatementLine);
        VATStatement.Run();  // Invokes VATStatementReportHandler.
    end;

    local procedure UpdateGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := CreateCurrencyWithExchangeRate();
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyVATStatementTemplate(VATStatementTemplateName: Code[10])
    var
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        VATStatementTemplate.Get(VATStatementTemplateName);
        VATStatementTemplate.TestField(Name, VATStatementTemplateName);
        VATStatementTemplate.TestField("VAT Statement Report ID", REPORT::"VAT Statement AT");
        VATStatementTemplate.TestField("Page ID", PAGE::"VAT Statement");
    end;

    local procedure UpdateGLVATReconciliationReportRequestPage(GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation"; PeriodSelection: Enum "VAT Statement Report Period Selection"; EntrySelection: Enum "VAT Statement Report Selection"; UseAmtsInAddCurr: Boolean)
    begin
        GLVATReconciliation.StartDate.SetValue(WorkDate());
        GLVATReconciliation.EndDateReq.SetValue(WorkDate());
        GLVATReconciliation.UseAmtsInAddCurr.SetValue(UseAmtsInAddCurr);
        GLVATReconciliation.PeriodSelection.SetValue(PeriodSelection);
        GLVATReconciliation.Selection.SetValue(EntrySelection);
        GLVATReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure UpdateVATStatementTemplateReportRequestPage(UpdateVATStatementTemplate: TestRequestPage "Update VAT Statement Template"; VATStatementTemplateName: Code[10])
    begin
        UpdateVATStatementTemplate.VATStatementTemplateName.SetValue(VATStatementTemplateName);
        UpdateVATStatementTemplate.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementScheduleReportHandler(var VATStatementSchedule: TestRequestPage "VAT Statement Schedule")
    begin
        VATStatementSchedule.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementReportHandler(var VATStatement: TestRequestPage "VAT Statement")
    begin
        VATStatement.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVATReconciliationReportHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    var
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        EntrySelection: Enum "VAT Statement Report Selection";
    begin
        UpdateGLVATReconciliationReportRequestPage(GLVATReconciliation, PeriodSelection::"Before and Within Period", EntrySelection, false);  // Use Additional Reporting Currency - FALSE.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AddCurrencyVATAdvNotAccProofReportHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    var
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        EntrySelection: Enum "VAT Statement Report Selection";
    begin
        UpdateGLVATReconciliationReportRequestPage(GLVATReconciliation, PeriodSelection, EntrySelection, true);  // Use Additional Reporting Currency - TRUE.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVATReconciliationClosedEntryReportHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    var
        EntrySelection: Enum "VAT Statement Report Selection";
    begin
        UpdateGLVATReconciliationReportRequestPage(GLVATReconciliation, "VAT Statement Report Period Selection"::"Within Period", EntrySelection::Closed, false);  // Use Additional Reporting Currency - FALSE.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVATReconciliationSelectionReportHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    var
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        EntrySelection: Enum "VAT Statement Report Selection";
    begin
        UpdateGLVATReconciliationReportRequestPage(GLVATReconciliation, PeriodSelection, EntrySelection::"Open and Closed", false);  // Use Additional Reporting Currency - FALSE.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateVATStatementTemplateBlankReportHandler(var UpdateVATStatementTemplate: TestRequestPage "Update VAT Statement Template")
    begin
        UpdateVATStatementTemplateReportRequestPage(UpdateVATStatementTemplate, '');  // Blank VAT Statement Template.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateVATStatementTemplateReportHandler(var UpdateVATStatementTemplate: TestRequestPage "Update VAT Statement Template")
    var
        VATStatementTemplateName: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATStatementTemplateName);
        UpdateVATStatementTemplateReportRequestPage(UpdateVATStatementTemplate, VATStatementTemplateName);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

