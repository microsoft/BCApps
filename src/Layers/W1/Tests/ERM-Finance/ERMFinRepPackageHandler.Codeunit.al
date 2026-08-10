codeunit 135010 "ERM Fin. Rep. Package Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        PackageTempBlobs: Dictionary of [Integer, Codeunit "Temp Blob"];

    procedure GetPackageTempBlobs(var PackageTempBlobsOut: Dictionary of [Integer, Codeunit "Temp Blob"])
    begin
        PackageTempBlobsOut := PackageTempBlobs;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Financial Report Packages", OnBeforePrintAccountSchedule, '', false, false)]
    local procedure OnBeforePrintAccountSchedule(var FinancialReportPackage: Record "Financial Report Package"; var AccountSchedule: Report "Account Schedule"; var AccScheduleParam: Text; var IsHandled: Boolean)
    var
        FinReportPackageReport: Record "Fin. Report Package Report";
        AccountScheduleXML: Report "Account Schedule";
        FinReportPackageExportJob: Codeunit "Financial Report Export Job";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        // Save report as PDF to trigger packaging code
        TempBlob.CreateOutStream(OutStr);
        AccountSchedule.SaveAs(AccScheduleParam, ReportFormat::Pdf, OutStr);

        // Save report again in XML for test suite validation
        FinReportPackageReport.SetRange("Package Code", FinancialReportPackage.Code);
        FinReportPackageReport.FindFirst();
        Clear(TempBlob);
        PackageTempBlobs.Add(FinReportPackageReport."Line No.", TempBlob);
        TempBlob.CreateOutStream(OutStr);
        FinReportPackageExportJob.InitAccSchFromPackageReport(AccountScheduleXML, FinReportPackageReport);
        AccountScheduleXML.SaveAs(AccScheduleParam, ReportFormat::Xml, OutStr);

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Account Schedule", OnBeforeSavePackageReport, '', false, false)]
    local procedure OnBeforeSavePackageReport(var AccountSchedule: Report "Account Schedule"; var FinReportPackageReport: Record "Fin. Report Package Report"; var AccScheduleParam: Text; var OutStr: OutStream; var IsHandled: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStrOverride: OutStream;
        InStr: InStream;
    begin
        PackageTempBlobs.Add(FinReportPackageReport."Line No.", TempBlob);
        TempBlob.CreateOutStream(OutStrOverride);
        AccountSchedule.SaveAs(AccScheduleParam, ReportFormat::Xml, OutStrOverride);
        TempBlob.CreateInStream(InStr);
        CopyStream(OutStr, InStr);
        IsHandled := true;
    end;
}