codeunit 139102 "PBI Test Report Impl." implements "Power BI Deployable Report"
{
    Access = Internal;

    procedure GetReportName(): Text[200]
    begin
        exit('Test Report');
    end;

    procedure GetStream(var InStr: InStream)
    var
        OutStr: OutStream;
    begin
        Clear(StreamBuffer);
        StreamBuffer.CreateOutStream(OutStr);
        OutStr.Write('Test PBIX content');
        StreamBuffer.CreateInStream(InStr);
    end;

    procedure GetVersion(): Integer
    begin
        exit(1);
    end;

    procedure GetDatasetParameters() Parameters: Dictionary of [Text, Text]
    begin
        Parameters.Add('COMPANY', CompanyName());
    end;

    var
        StreamBuffer: Codeunit "Temp Blob";
}
