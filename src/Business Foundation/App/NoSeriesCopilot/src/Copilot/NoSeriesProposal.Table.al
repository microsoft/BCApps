table 391 "No. Series Proposal"
{
    TableType = Temporary;

    fields
    {
        field(1; "No."; Integer)
        {

        }
        field(10; "Input Text"; Blob)
        {

        }
    }

    keys
    {
        key(PK; "No.")
        {

        }
    }

    procedure SetInputText(NewText: Text)
    var
        OutStr: OutStream;
    begin
        Rec."Input Text".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
    end;

    procedure GetInputText(): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        Rec.CalcFields("Input Text");
        Rec."Input Text".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(Result);

        exit(Result);
    end;


}