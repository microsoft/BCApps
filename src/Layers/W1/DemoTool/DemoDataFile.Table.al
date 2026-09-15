table 101905 "Demo Data File"
{
    Caption = 'Demo Data File';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ',Standard,Extended,Evaluation';
            OptionMembers = ,Standard,Extended,Evaluation;
        }
        field(2; Version; Text[30])
        {
            Caption = 'Version';
        }
        field(3; "Json File"; BLOB)
        {
            Caption = 'Json File';
        }
    }

    keys
    {
        key(Key1; Type, Version)
        {
        }
    }

    fieldgroups
    {
    }

    var
        FileDoesNotExistErr: Label 'The file %1 does not exist.', Comment = '%1 File Path';

    procedure SetJsonFile(FilePath: Text)
    var
        OutStream: OutStream;
        InStream: InStream;
        InputFile: File;
    begin
        if not FILE.Exists(FilePath) then
            Error(FileDoesNotExistErr, FilePath);

        InputFile.Open(FilePath);
        InputFile.CreateInStream(InStream);
        "Json File".CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        InputFile.Close();
        Modify(true);
    end;
}

