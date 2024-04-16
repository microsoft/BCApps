table 130452 "Test Input"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Test Suite"; Code[10])
        {
            TableRelation = "AL Test Suite".Name;
        }
        field(2; Name; Text[250])
        {
        }
        field(3; Description; Text[2048])
        {
        }
        field(10; "Test Input"; Blob)
        {
        }
    }

    keys
    {
        key(Key1; "Test Suite", "Name")
        {
            Clustered = true;
        }
    }

    internal procedure SetInput(TestInput: Record "Test Input"; TextInput: Text)
    var
        TestInputOutStream: OutStream;
    begin
        TestInput."Test Input".CreateOutStream(TestInputOutStream, GetTextEncoding());
        TestInputOutStream.Write(TextInput);
        TestInput.Modify(true);
    end;

    internal procedure GetInput(TestInput: Record "Test Input"): Text
    var
        TestInputInStream: InStream;
        TextInput: Text;
    begin
        TestInput.CalcFields("Test Input");
        if (not TestInput."Test Input".HasValue()) then
            exit('');

        TestInput."Test Input".CreateInStream(TestInputInStream, GetTextEncoding());
        TestInputInStream.Read(TextInput);
        exit(TextInput);
    end;

    local procedure GetTextEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF16);
    end;
}