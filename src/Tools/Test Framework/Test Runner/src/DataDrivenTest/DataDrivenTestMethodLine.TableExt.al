namespace System.TestTools.TestRunner;
tableextension 130458 "Data Driven Test Method Line" extends "Test Method Line"
{
    fields
    {
        field(1000; "Data Input"; Blob)
        {
            Caption = 'Data Input';
            ToolTip = 'Data input for the test method line';
            DataClassification = CustomerContent;
        }
    }

    procedure GetDataInput(): Text
    var
        InStream: InStream;
        P: Text;
    begin
        CalcFields("Data Input");
        "Data Input".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(P);
        exit(P);
    end;

}