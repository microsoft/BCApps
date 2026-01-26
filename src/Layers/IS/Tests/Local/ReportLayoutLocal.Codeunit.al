codeunit 141000 "Report Layout - Local"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    [Test]
    [HandlerFunctions('RHVATBalancingReport')]
    [Scope('OnPrem')]
    procedure TestVATBalancingReport()
    begin
        REPORT.Run(REPORT::"VAT Balancing Report");
    end;

    [Test]
    [HandlerFunctions('RHVATReconciliation')]
    [Scope('OnPrem')]
    procedure TestVATReconciliation()
    begin
        REPORT.Run(REPORT::"VAT Reconciliation A");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVATBalancingReport(var VATBalancingReport: TestRequestPage "VAT Balancing Report")
    begin
        VATBalancingReport.Year.SetValue((Date2DWY(WorkDate(), 3) - 1));
        VATBalancingReport.SaveAsPdf(FormatFileName(VATBalancingReport.Caption));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVATReconciliation(var VATBalancing: TestRequestPage "VAT Reconciliation A")
    var
        Period1: Option Custom,"January-February","March-April","May-June","July-August","September-October","November-December";
    begin
        VATBalancing.Period.SetValue(Period1::"January-February");
        VATBalancing.Year.SetValue((Date2DWY(WorkDate(), 3) - 1));
        VATBalancing.SaveAsPdf(FormatFileName(VATBalancing.Caption));
    end;

    local procedure FormatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;
}

