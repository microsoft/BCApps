codeunit 135006 "Fin. Report Export Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        TempBlob: Codeunit "Temp Blob";

    procedure GetStream() InStr: InStream
    begin
        TempBlob.CreateInStream(InStr);
    end;

    procedure GetBlob(var Blob: Codeunit "Temp Blob")
    begin
        Blob := TempBlob;
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