codeunit 147210 "RU Report Download Handler"
{
    // Test helper (non-test codeunit). RU local reports export Excel through a client-side download
    // (codeunit "File Management".DownloadHandler). In container-based test runs that client download
    // does not materialize the file at the server session path the report tests read from
    // ("Library - Report Validation" reads TemporaryPath + name), so the tests fail opening the file.
    // This static subscriber copies the server-side source file to the requested target path so the
    // report validation can open it. A single shared, non-test handler is used (instead of per-test
    // manual subscribers) because many RU report test codeunits rely on this behavior; a static
    // subscriber is allowed here because this is not a test codeunit (AL0501 only applies to those).

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure CopyServerFileToTargetOnBeforeDownloadHandler(ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        FileManagement: Codeunit "File Management";
    begin
        if (FromFileName = '') or (ToFileName = '') then
            exit;
        if not FileManagement.ServerFileExists(FromFileName) then
            exit;
        FileManagement.CopyServerFile(FromFileName, ToFileName, true);
        IsHandled := true;
    end;
}
