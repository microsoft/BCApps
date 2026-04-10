namespace System.Utilities;

using System.Environment;
using System.IO;

table 9400 "Media Repository"
{
    Caption = 'Media Repository';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(2; "Display Target"; Code[50])
        {
            Caption = 'Display Target';
        }
        field(3; Image; Media)
        {
            Caption = 'Image';
        }
        field(4; "Media Resources Ref"; Code[50])
        {
            Caption = 'Media Resources Ref';
        }
    }

    keys
    {
        key(Key1; "File Name", "Display Target")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        FileManagement: Codeunit "File Management";
        FileDoesNotExistErr: Label 'The file %1 does not exist. Import failed.', Comment = '%1 = File Path';

    [TryFunction]
    procedure GetForCurrentClientType(FileName: Text[250])
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        TargetClientType: ClientType;
    begin
        TargetClientType := ClientTypeManagement.GetCurrentClientType();

        if TargetClientType = ClientType::Teams then begin
            if Rec.Get(FileName, Format(TargetClientType)) then
                exit;
            TargetClientType := ClientType::Web;
        end;

        Rec.Get(FileName, Format(TargetClientType));
    end;

    [Scope('OnPrem')]
    procedure ImportMedia(FilePath: Text; DisplayTarget: Code[50])
    var
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
        FileName: Text[250];
        MediaResourcesCode: Code[50];
    begin
        if FileManagement.ServerFileExists(FilePath) then begin
            FileName := CopyStr(FileManagement.GetFileName(FilePath), 1, MaxStrLen(FileName));
            if not Get(FileName, DisplayTarget) then begin
                Init();
                "File Name" := FileName;
                "Display Target" := DisplayTarget;
                Insert(true);
            end;
            MediaResourcesCode := CopyStr(FileName, 1, MaxStrLen("Media Resources Ref"));
            MediaResourcesMgt.InsertMediaFromFile(MediaResourcesCode, FilePath);
            "Media Resources Ref" := MediaResourcesCode;
            Modify(true);
        end else
            Error(FileDoesNotExistErr, FilePath);
    end;

    [Scope('OnPrem')]
    procedure SetIconFromInstream(MediaResourceRef: Code[50]; MediaInstream: InStream)
    var
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
    begin
        if not MediaResourcesMgt.InsertMediaFromInstream(MediaResourceRef, MediaInstream) then
            exit;

        Validate("Media Resources Ref", MediaResourceRef);
        Modify(true);
    end;
}

