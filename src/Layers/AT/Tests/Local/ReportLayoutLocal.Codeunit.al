codeunit 141000 "Report Layout - Local"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('RHFixedAssetsListAT')]
    [Scope('OnPrem')]
    procedure TestFixedAssetsListAT()
    begin
        Initialize();
        REPORT.Run(REPORT::"Fixed Assets - List AT");
    end;

    local procedure Initialize()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        if isInitialized then
            exit;

        // Setup logo to be printed by default
        SalesSetup.Validate("Logo Position on Documents", SalesSetup."Logo Position on Documents"::Center);
        SalesSetup.Modify(true);

        isInitialized := true;
        Commit();
    end;

    local procedure FomatFileName(ReportCaption: Text) ReportFileName: Text
    begin
        ReportFileName := DelChr(ReportCaption, '=', '/') + '.pdf'
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHFixedAssetsListAT(var FixedAssetsListAT: TestRequestPage "Fixed Assets - List AT")
    var
        GroupTotals: Option " ","FA Class","FA Subclass","FA Location","Main Asset","Global Dimension 1","Global Dimension 2","FA Posting Group";
    begin
        FixedAssetsListAT.StartDate.SetValue(WorkDate());
        FixedAssetsListAT.EndDate.SetValue(CalcDate('<+10Y>', WorkDate()));
        FixedAssetsListAT.GroupTotals.SetValue(GroupTotals::"FA Subclass");
        FixedAssetsListAT.PrintDetails.SetValue(true);
        FixedAssetsListAT.SaveAsPdf(FomatFileName(FixedAssetsListAT.Caption));
    end;
}

