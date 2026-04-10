namespace System.IO;

table 8630 "Config. Media Buffer"
{
    Caption = 'Config. Media Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            DataClassification = SystemMetadata;
        }
        field(2; "Media Set ID"; Guid)
        {
            Caption = 'Media Set ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Media ID"; Guid)
        {
            Caption = 'Media ID';
            DataClassification = SystemMetadata;
        }
        field(4; "No."; Integer)
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Media Blob"; BLOB)
        {
            Caption = 'Media Blob';
            DataClassification = SystemMetadata;
        }
        field(11; "Media Set"; MediaSet)
        {
            Caption = 'Media Set';
            DataClassification = SystemMetadata;
        }
        field(12; Media; Media)
        {
            Caption = 'Media';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Package Code", "Media Set ID", "Media ID", "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetNextNo(): Integer
    var
        ConfigMediaBuffer: Record "Config. Media Buffer";
    begin
        ConfigMediaBuffer.SetRange("Package Code", "Package Code");
        ConfigMediaBuffer.SetRange("Media Set ID", "Media Set ID");
        ConfigMediaBuffer.SetRange("Media ID", "Media ID");

        if ConfigMediaBuffer.FindLast() then
            exit(ConfigMediaBuffer."No." + 1);

        exit(1);
    end;
}

