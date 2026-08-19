codeunit 144529 "ERM Stat. Reporting"
{
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryStatReporting: Codeunit "Library - Stat. Reporting";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ExportStatutoryReportSettings_FSI_4()
    begin
        Initialize();

        VerifyStatutoryReportSettingsExportToFile('FSI-4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportStatutoryReportSettings_RSV_1()
    begin
        Initialize();

        VerifyStatutoryReportSettingsExportToFile('RSV-1');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportStatutoryReportData_FSI_4()
    begin
        Initialize();

        VerifyStatutoryReportDataExportToFile('FSI-4');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportStatutoryReportData_RSV_1()
    begin
        Initialize();

        VerifyStatutoryReportDataExportToFile('RSV-1');
    end;

    local procedure Initialize()
    var
        StatutoryReportSetup: Record "Statutory Report Setup";
    begin
        if IsInitialized then
            exit;

        StatutoryReportSetup.Get();
        StatutoryReportSetup.Validate("Report Data Nos", LibraryUtility.GetGlobalNoSeriesCode());
        StatutoryReportSetup.Validate("Report Export Log Nos", LibraryUtility.GetGlobalNoSeriesCode());
        StatutoryReportSetup.Modify();

        UpdateCompanyAddress();

        IsInitialized := true;
        Commit();
    end;

    [Scope('OnPrem')]
    procedure UpdateCompanyAddress()
    var
        CompanyAddress: Record "Company Address";
        StatutoryReport: Record "Statutory Report";
    begin
        CompanyAddress.FindFirst();
        StatutoryReport.SetFilter("Company Address Code", '%1', '');
        if StatutoryReport.FindSet(true, false) then
            repeat
                StatutoryReport."Company Address Code" := CompanyAddress.Code;
                StatutoryReport."Company Address Language Code" := CompanyAddress."Language Code";
                StatutoryReport.Modify();
            until StatutoryReport.Next() = 0;
    end;

    local procedure VerifyStatutoryReportDataExportToFile(ReportCode: Code[20])
    var
        StatutoryReport: Record "Statutory Report";
        StatutoryReportDataHeader: Record "Statutory Report Data Header";
    begin
        StatutoryReport.Get(ReportCode);

        LibraryReportValidation.SetFileName(CreateGuid());
        StatutoryReportDataHeader.SetFileNameSilent(LibraryReportValidation.GetFileName());
        StatutoryReportDataHeader.SetTestMode(true);
        StatutoryReportDataHeader.CreateReportHeader(
          StatutoryReport,
          CalcDate('<-1Y+CY>', WorkDate()), CalcDate('<-1Y-CY>', WorkDate()), CalcDate('<-1Y+CY>', WorkDate()),
          0, 0, 0, 'Test', 3, '46', '2016');
        LibraryStatReporting.ReleaseStatutoryReportDataHeader(StatutoryReportDataHeader);
        StatutoryReportDataHeader.ExportResultsToXML();
    end;

    local procedure VerifyStatutoryReportSettingsExportToFile(ReportCode: Code[20])
    var
        StatutoryReport: Record "Statutory Report";
        StatutoryReportMgt: Codeunit "Statutory Report Management";
    begin
        StatutoryReport.Get(ReportCode);
        LibraryReportValidation.SetFileName(CreateGuid());

        StatutoryReport.SetRecFilter();
        StatutoryReportMgt.SetTestMode(true);
        StatutoryReportMgt.SetFileNameSilent(LibraryReportValidation.GetFileName());
        StatutoryReportMgt.ExportReportSettings(StatutoryReport);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure StatReportDataOverviewHandler(var StatutoryReportDataOverview: TestPage "Statutory Report Data Overview")
    begin
        StatutoryReportDataOverview.ShowData.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StatReportDataOverviewMatrixHandler(var _StatReportDataSubform: TestPage "_Stat. Report Data Subform")
    begin
        _StatReportDataSubform.OK().Invoke();
    end;
}

