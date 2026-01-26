codeunit 142066 "UT PAG VATSTAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetUsageFilterVATStatement()
    var
        ReportSelections: Record "Report Selections";
    begin
        // Purpose of the test is to validate SetUsageFilter function of Page Report Selection - VAT Stmt.
        // Setup.
        SetUsageFilter(
            ReportSelections.Usage::"VAT Statement", "Report Selection Usage VAT"::"VAT Statement", REPORT::"VAT Statement Germany");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetUsageFilterGLVATReconciliation()
    var
        ReportSelections: Record "Report Selections";
    begin
        // Purpose of the test is to validate SetUsageFilter function of Page ID 26101 Report Selection - VAT.
        // Setup.
        SetUsageFilter(
            ReportSelections.Usage::"Sales VAT Acc. Proof", "Report Selection Usage VAT"::"Sales VAT Adv. Not. Acc", REPORT::"G/L - VAT Reconciliation");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure SetUsageFilterSalesVATStatementSchedule()
    var
        ReportSelections: Record "Report Selections";
    begin
        // Purpose of the test is to validate SetUsageFilter function of Page ID 26101 Report Selection - VAT.
        // Setup.
        SetUsageFilter(
            ReportSelections.Usage::"VAT Statement Schedule", "Report Selection Usage VAT"::"VAT Statement Schedule", REPORT::"VAT Statement Schedule");
    end;

    local procedure SetUsageFilter(Usage: Enum "Report Selection Usage"; ReportUsage: Enum "Report Selection Usage VAT"; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
        ReportSelectionVATStmt: TestPage "Report Selection - VAT Stmt.";
    begin
        // Create DACH Report Selections for different Usage.
        CreateReportSelections(ReportSelections, Usage, ReportID);
        ReportSelectionVATStmt.OpenEdit();

        // Exercise: Report Selection VAT Page for different ReportUsage2.
        ReportSelectionVATStmt.ReportUsage2.SetValue(ReportUsage);
        ReportSelectionVATStmt.FILTER.SetFilter(Sequence, ReportSelections.Sequence);

        // Verify: Verify Report ID is updated on Page Report Selection - VAT for different Usages.
        ReportSelectionVATStmt."Report ID".AssertEquals(ReportSelections."Report ID");
        ReportSelectionVATStmt.Close();
    end;

    [Test]
    [HandlerFunctions('VATStatementGermanyRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure PrintVATStatement()
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatement: TestPage "VAT Statement";
    begin
        // Purpose of the test is to validate Print Action of Page 317 - VAT Statement.
        // Setup.
        VATStatementName.FindFirst();
        VATStatement.OpenEdit();
        VATStatement.CurrentStmtName.SetValue(VATStatementName.Name);

        // Excercise & verify: Invoke Action Print on Page VAT Statement. Opens Report - VAT Statement Germany handled in VATStatementGermanyRequestPageHandler.
        VATStatement.Print.Invoke();
        VATStatement.Close();
    end;

    [Test]
    [HandlerFunctions('GLVATReconciliationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure GLVATReconciliationVATStatement()
    var
        ReportSelections: Record "Report Selections";
        VATStatementAction: Option GLVATReconciliation,VATStatementSchedule;
    begin
        // Purpose of the test is to validate GLVATReconciliation Action of Page 317 - VAT Statement.

        // Setup: Opens Report - G/L - VAT Reconciliation handled in GLVATReconciliationRequestPageHandler.
        VATStatementForReportSelections(
            ReportSelections.Usage::"Sales VAT Acc. Proof", VATStatementAction::GLVATReconciliation, REPORT::"G/L - VAT Reconciliation");
    end;

    [Test]
    [HandlerFunctions('VATStatementScheduleRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure VATStatementScheduleFromVATStatement()
    var
        ReportSelections: Record "Report Selections";
        VATStatementAction: Option GLVATReconciliation,VATStatementSchedule;
    begin
        // Purpose of the test is to validate VATStatementSchedule Action of Page 317 - VAT Statement.

        // Setup: Opens Report - VAT Statement Schedule handled in VATStatementScheduleRequestPageHandler.
        VATStatementForReportSelections(ReportSelections.Usage::"VAT Statement Schedule", VATStatementAction::VATStatementSchedule, REPORT::"VAT Statement Schedule");
    end;

    local procedure VATStatementForReportSelections(Usage: Enum "Report Selection Usage"; VATStatementAction: Option; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
        VATStatementName: Record "VAT Statement Name";
        VATStatement: TestPage "VAT Statement";
    begin
        // Open VAT Statement Page.
        CreateReportSelections(ReportSelections, Usage, ReportID);
        VATStatementName.FindFirst();
        VATStatement.OpenEdit();
        VATStatement.CurrentStmtName.SetValue(VATStatementName.Name);

        // Excercise & verify: Invoke different Actions on Page - VAT Statement. Verified different Reports opened successfully.
        InvokeVATStatementAction(VATStatement, VATStatementAction);
    end;

    local procedure CreateReportSelections(var ReportSelections: Record "Report Selections"; Usage: Enum "Report Selection Usage"; ReportID: Integer)
    begin
        ReportSelections.Usage := Usage;
        ReportSelections.Sequence := LibraryUTUtility.GetNewCode10();
        ReportSelections."Report ID" := ReportID;
        ReportSelections.Insert();
    end;

    local procedure InvokeVATStatementAction(VATStatement: TestPage "VAT Statement"; "Action": Option)
    var
        VATStatementAction: Option GLVATReconciliation,VATStatementSchedule;
    begin
        case Action of
            VATStatementAction::GLVATReconciliation:
                VATStatement.GLVATReconciliation.Invoke();  // Opens handler GLVATReconciliationRequestPageHandler.
            VATStatementAction::VATStatementSchedule:
                VATStatement.VATStatementSchedule.Invoke();  // Opens handler VATStatementScheduleRequestPageHandler.
        end;
        VATStatement.Close();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementGermanyRequestPageHandler(var VATStatementGermany: TestRequestPage "VAT Statement Germany")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLVATReconciliationRequestPageHandler(var GLVATReconciliation: TestRequestPage "G/L - VAT Reconciliation")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStatementScheduleRequestPageHandler(var VATStatementSchedule: TestRequestPage "VAT Statement Schedule")
    begin
    end;
}

