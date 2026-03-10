#if not CLEAN28
codeunit 141000 "Report Layout - Local"
{
    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Code move to IS core.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';

    trigger OnRun()
    begin
    end;

    [Test]
    [HandlerFunctions('RHVATBalancingReport')]
    [Scope('OnPrem')]
    [Obsolete('Code move to IS core.', '28.0')]
    procedure TestVATBalancingReport()
    begin
        REPORT.Run(REPORT::"VAT Balancing Report");
    end;

    [Test]
    [HandlerFunctions('RHVATReconciliation')]
    [Scope('OnPrem')]
    [Obsolete('Code move to IS core.', '28.0')]
    procedure TestVATReconciliation()
    begin
        REPORT.Run(REPORT::"VAT Reconciliation A");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    [Obsolete('Code move to IS core.', '28.0')]
    procedure RHVATBalancingReport(var VATBalancingReport: TestRequestPage "VAT Balancing Report")
    begin
        VATBalancingReport.Year.SetValue((Date2DWY(WorkDate(), 3) - 1));
        VATBalancingReport.SaveAsPdf(FormatFileName(VATBalancingReport.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    [Obsolete('Code move to IS core.', '28.0')]
    procedure RHVATReconciliation(var VATBalancing: TestRequestPage "VAT Reconciliation A")
    var
        Period1: Option Custom,"January-February","March-April","May-June","July-August","September-October","November-December";
    begin
        VATBalancing.Period.SetValue(Period1::"January-February");
        VATBalancing.Year.SetValue((Date2DWY(WorkDate(), 3) - 1));
        VATBalancing.SaveAsPdf(FormatFileName(VATBalancing.Caption));
    end;

    [Obsolete('Code move to IS core.', '28.0')]
    local procedure FormatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;
}
#endif
