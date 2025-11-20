codeunit 135008 "ERM Fin. Report Sheet Handler"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        SheetTempBlobs: Dictionary of [Integer, Codeunit "Temp Blob"];

    procedure GetSheetTempBlobs(var SheetTempBlobsOut: Dictionary of [Integer, Codeunit "Temp Blob"])
    begin
        SheetTempBlobsOut := SheetTempBlobs;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Account Schedule", OnBeforeSaveSheetDefinitionReport, '', false, false)]
    local procedure OnBeforeSaveSheetDefinitionReport(SheetDefLine: Record "Sheet Definition Line"; var AccountSchedule: Report "Account Schedule"; var OutStr: OutStream; var IsHandled: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStrOverride: OutStream;
        InStr: InStream;
    begin
        SheetTempBlobs.Add(SheetDefLine."Line No.", TempBlob);
        TempBlob.CreateOutStream(OutStrOverride);
        AccountSchedule.SaveAs('', ReportFormat::Xml, OutStrOverride);
        TempBlob.CreateInStream(InStr);
        CopyStream(OutStr, InStr);
        IsHandled := true;
    end;
}