codeunit 135006 "Fin. Report Export Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        TempBlob: Codeunit "Temp Blob";
        OutputFileName: Text;

    procedure GetStream() InStr: InStream
    begin
        TempBlob.CreateInStream(InStr);
    end;

    procedure GetBlob(var Blob: Codeunit "Temp Blob")
    begin
        Blob := TempBlob;
    end;

    procedure GetOutputFileName(): Text
    begin
        exit(OutputFileName);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", GetFilename, '', false, false)]
    local procedure OnGetFilename(ReportID: Integer; Caption: Text[250]; ObjectPayload: JsonObject; FileExtension: Text[30]; ReportRecordRef: RecordRef; var Filename: Text; var Success: Boolean)
    begin
        if (ReportID = Report::"Account Schedule") and Success then
            OutputFileName := Filename;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Financial Report Export Job", OnBeforeSavePdf, '', true, true)]
    local procedure OnBeforeSavePdf(AccScheduleParam: Text; var AccountSchedule: Report "Account Schedule"; var OutStr: OutStream; var IsHandled: Boolean)
    var
        OutStrOverride: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStrOverride);
        AccountSchedule.SaveAs(AccScheduleParam, ReportFormat::Xml, OutStrOverride);
        TempBlob.CreateInStream(InStr);
        CopyStream(OutStr, InStr);
        IsHandled := true;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Financial Report Export Job", OnBeforeSaveExcel, '', true, true)]
    local procedure OnBeforeSaveExcel(ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel"; var OutStr: OutStream; var IsHandled: Boolean)
    var
        OutStrOverride: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStrOverride);
        ExportAccSchedToExcel.SetSaveToStream(true);
        ExportAccSchedToExcel.Execute('');
        ExportAccSchedToExcel.GetSavedStream(OutStrOverride);
        TempBlob.CreateInStream(InStr);
        CopyStream(OutStr, InStr);
        IsHandled := true;
    end;
}