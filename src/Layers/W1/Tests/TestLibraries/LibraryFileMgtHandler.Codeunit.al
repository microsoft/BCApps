codeunit 131106 "Library - File Mgt Handler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        FileMgt: Codeunit "File Management";
        ServerTempFileName: Text;
        BeforeDownloadHandlerActivated: Boolean;
        BeforeDownloadFromStreamHandlerActivated: Boolean;
        DownloadFromSreamToFileName: Text;
        TempBlob: Codeunit "Temp Blob";
        SaveFileActivated: Boolean;

    [Scope('OnPrem')]
    procedure SetDownloadSubscriberActivated(NewBeforeDownloadHandlerActivated: Boolean)
    begin
        BeforeDownloadHandlerActivated := NewBeforeDownloadHandlerActivated;
    end;

    procedure SetBeforeDownloadFromStreamHandlerActivated(NewBeforeDownloadFromStreamHandlerActivated: Boolean)
    begin
        BeforeDownloadFromStreamHandlerActivated := NewBeforeDownloadFromStreamHandlerActivated;
    end;

    procedure SetSaveFileActivated(NewSaveFileActivated: Boolean)
    begin
        SaveFileActivated := NewSaveFileActivated;
    end;

    procedure GetServerTempFileName(): Text
    begin
        exit(ServerTempFileName);
    end;

    procedure GetDownloadFromSreamToFileName(): Text
    begin
        exit(DownloadFromSreamToFileName);
    end;

    procedure GetTempBlob(var TempBlobResult: Codeunit "Temp Blob")
    begin
        TempBlobResult := TempBlob;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure HandleOnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    begin
        if not BeforeDownloadHandlerActivated then
            exit;

        if SaveFileActivated then begin
            ServerTempFileName := FileMgt.ServerTempFileName(FileMgt.GetExtension(FromFileName));
            FileMgt.CopyServerFile(FromFileName, ServerTempFileName, false);
        end;

        IsHandled := true;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadFromStreamHandler', '', false, false)]
    local procedure HandleOnBeforeDownloadFromStreamHandler(var ToFolder: Text; ToFileName: Text; FromInStream: InStream; var IsHandled: Boolean)
    var
        OutStreamVar: OutStream;
    begin
        if not BeforeDownloadFromStreamHandlerActivated then
            exit;

        DownloadFromSreamToFileName := ToFileName;
        TempBlob.CreateOutStream(OutStreamVar);
        CopyStream(OutStreamVar, FromInStream);

        IsHandled := true;
    end;
}

