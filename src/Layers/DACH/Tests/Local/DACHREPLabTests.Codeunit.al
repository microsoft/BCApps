codeunit 142500 "DACH REP Lab Tests"
{
    // // [FEATURE] [VAT Statement]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        VATStatementLineAmountTypeTok: Label 'VAT_Statement_Line___Amount_Type_';
        VATStatementLineTypeTok: Label 'VAT_Statement_Line__Type';
        LibraryERM: Codeunit "Library - ERM";

    [Test]
    [HandlerFunctions('GLVATReconciliationReportHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReportGLVATReconciliationTranslated()
    var
        VATStatementLine: Record "VAT Statement Line";
    begin
        // [SCENARIO 379359] Columns "Type" and "Amount Type" in report "G/L - VAT Reconciliation" should contain translated values
        Initialize();

        // [GIVEN] VAT Statement Line with type = "Account Totaling" and "Amount Type" = Base
        CreateVATStatementLine(
          VATStatementLine, VATStatementLine.Type::"Account Totaling", VATStatementLine."Amount Type"::Base);
        Commit();

        // [WHEN] Run report "G/L - VAT Reconciliation"
        RunGLVATReconciliationReport(VATStatementLine);

        // [THEN] Fields in report Type = "Account Totaling" and "Amount Type" = Base
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(VATStatementLineAmountTypeTok, Format(VATStatementLine."Amount Type"));
        LibraryReportDataset.AssertElementWithValueExists(VATStatementLineTypeTok, Format(VATStatementLine.Type));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; Type: Enum "VAT Statement Line Type"; AmountType: Enum "VAT Statement Line Amount Type")
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementTemplate: Record "VAT Statement Template";
    begin
        LibraryERM.CreateVATStatementTemplate(VATStatementTemplate);
        LibraryERM.CreateVATStatementName(VATStatementName, VATStatementTemplate.Name);
        LibraryERM.CreateVATStatementLine(VATStatementLine, VATStatementTemplate.Name, VATStatementName.Name);
        VATStatementLine."Account Totaling" := LibraryERM.CreateGLAccountNo();
        VATStatementLine.Type := Type;
        VATStatementLine."Amount Type" := AmountType;
        VATStatementLine.Modify();
    end;

    local procedure RunGLVATReconciliationReport(VATStatementLine: Record "VAT Statement Line")
    var
        GlVatReconciliation: Report "G/L - VAT Reconciliation";
    begin
        VATStatementLine.SetRange("Statement Name", VATStatementLine."Statement Name");
        GlVatReconciliation.SetTableView(VATStatementLine);
        GlVatReconciliation.Run();  // Invokes GLVATReconciliationReportHandler, AddCurrencyVATAdvNotAccProofReportHandler and GLVATReconciliationSelectionReportHandler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVATReconciliationReportHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    begin
        UpdateGLVATReconciliationReportRequestPage(
          GLVATReconciliation, "VAT Statement Report Period Selection"::"Before and Within Period", "VAT Statement Report Selection"::Open, false);  // Use Additional Reporting Currency - FALSE.
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

