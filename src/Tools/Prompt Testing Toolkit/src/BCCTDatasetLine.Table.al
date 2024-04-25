namespace System.Tooling;

table 149033 "BCCT Dataset Line"
{
    DataCaptionFields = "Dataset Name";
    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Dataset Name"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(3; Input; Text[2048])
        {
            DataClassification = CustomerContent;
        }
        field(4; "Input Data"; Blob)
        {
            DataClassification = CustomerContent;
        }
        field(5; "Expected Output Blob"; Blob)
        {
            DataClassification = CustomerContent;
        }
        field(6; "Expected Output"; Text[2048])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    procedure SetInputBlob(P: Text)
    var
        OutStream: OutStream;
    begin
        "Input Data".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.Write(P);
    end;

    procedure GetInputBlob(): Text
    var
        InStream: InStream;
        P: Text;
    begin
        CalcFields("Input Data");
        "Input Data".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(P);
        exit(P);
    end;

    procedure SetExpOutputBlob(P: Text)
    var
        OutStream: OutStream;
    begin
        "Expected Output Blob".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.Write(P);
    end;

    procedure GetExpResultBlob(): Text
    var
        InStream: InStream;
        P: Text;
    begin
        CalcFields("Expected Output Blob");
        "Expected Output Blob".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(P);
        exit(P);
    end;



}