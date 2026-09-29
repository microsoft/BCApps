codeunit 147210 "RU Report Download Handler"
{
    // Test helper (non-test codeunit) for RU report tests. RU local reports download their Excel
    // output client-side, which doesn't materialize the file at the server path the tests read from
    // in container runs; this subscriber copies the source file to the target so validation can open it.
    //
    // Manual subscriber: each RU report test binds it (see the test codeunits' Initialize), so it stays
    // scoped to RU tests and never interferes with shared W1 report tests. A future RU test that forgets
    // to bind fails in the BCApps run (file never produced) instead of breaking NAV. As a safeguard the
    // copy only runs for a target whose directory exists on the server (bug 645025).

    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure CopyServerFileToTargetOnBeforeDownloadHandler(ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        FileManagement: Codeunit "File Management";
        TargetDirectory: Text;
    begin
        if (FromFileName = '') or (ToFileName = '') then
            exit;
        if not FileManagement.ServerFileExists(FromFileName) then
            exit;

        // Only redirect to a server-side copy when the target directory actually exists on the server.
        // A bare/relative target yields an empty or non-existent directory here, so we skip and let the
        // platform's normal download flow handle it.
        TargetDirectory := FileManagement.GetDirectoryName(ToFileName);
        if TargetDirectory = '' then
            exit;
        if not FileManagement.ServerDirectoryExists(TargetDirectory) then
            exit;

        FileManagement.CopyServerFile(FromFileName, ToFileName, true);
        IsHandled := true;
    end;
}
