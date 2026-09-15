#pragma warning disable AA0247
codeunit 26550 "Statutory Report Management"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text001: Label 'Sent data cannot be opened.';
#pragma warning restore AA0074
        FileMgt: Codeunit "File Management";
        DataCompression: Codeunit "Data Compression";
        ServerFileName: Text;
        TestMode: Boolean;
        SelectFileNameTxt: Label 'Select a filename to export File Settings to.';
        DefaultFileNameTxt: Label '', Comment = 'StatutoryReport';

    [Scope('OnPrem')]
    procedure ExportReportSettings(var StatutoryReport: Record "Statutory Report")
    var
        FormatVersion: Record "Format Version";
        TempBlob: Codeunit "Temp Blob";
        ZipTempBlob: Codeunit "Temp Blob";
        StatutoryReportsXML: XMLport "Statutory Reports";
        OutputFile: File;
        ServerTempFileInStream: InStream;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
        OutStr: OutStream;
        FileName: Text;
        PathName: Text;
    begin
        DataCompression.CreateZipArchive();

        if ServerFileName = '' then
            ServerFileName := FileMgt.ServerTempFileName('xml');

        OutputFile.Create(ServerFileName);
        OutputFile.CreateOutStream(OutStr);
        StatutoryReportsXML.SetDestination(OutStr);
        StatutoryReportsXML.SetData(StatutoryReport);
        StatutoryReportsXML.Export();
        OutputFile.Close();
        Clear(OutStr);

        if TestMode then
            exit;

        FileMgt.BLOBImportFromServerFile(TempBlob, ServerFileName);
        TempBlob.CreateInStream(ServerTempFileInStream);
        DataCompression.AddEntry(ServerTempFileInStream, DefaultFileNameTxt + '.xml');

        if StatutoryReport.FindSet() then
            repeat
                if not StatutoryReport.Header then begin
                    StatutoryReport.TestField("Format Version Code");
                    FormatVersion.Get(StatutoryReport."Format Version Code");

                    if FormatVersion."Excel File Name" <> '' then begin
                        FormatVersion.CalcFields("Report Template");
                        if FormatVersion."Report Template".HasValue() then begin
                            Clear(TempBlob);
                            TempBlob.FromRecord(FormatVersion, FormatVersion.FieldNo("Report Template"));
                            TempBlob.CreateInStream(ServerTempFileInStream);
                            DataCompression.AddEntry(ServerTempFileInStream, FormatVersion."Excel File Name");
                        end;
                    end;
                    if FormatVersion."XML Schema File Name" <> '' then begin
                        FormatVersion.CalcFields("XML Schema");
                        if FormatVersion."XML Schema".HasValue() then begin
                            Clear(TempBlob);
                            TempBlob.FromRecord(FormatVersion, FormatVersion.FieldNo("XML Schema"));
                            TempBlob.CreateInStream(ServerTempFileInStream);
                            DataCompression.AddEntry(ServerTempFileInStream, FormatVersion."XML Schema File Name");
                            FileMgt.BLOBExport(TempBlob, PathName + FormatVersion."XML Schema File Name", true);
                        end;
                    end;
                end;
            until StatutoryReport.Next() = 0;

        FileName := DefaultFileNameTxt + '.zip';
        ZipTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();
        ZipTempBlob.CreateInStream(ZipInStream);
        DownloadFromStream(ZipInStream, SelectFileNameTxt, PathName, '', FileName);
    end;

    [Scope('OnPrem')]
    procedure ImportReportSettings(FileName2: Text)
    var
        StatutoryReports: XMLport "Statutory Reports";
        InStr: InStream;
        ReportFile: File;
        PathName: Text;
    begin
        ReportFile.Open(FileName2);
        ReportFile.CreateInStream(InStr);

        PathName := StrSubstNo('%1\', FileMgt.GetDirectoryName(FileName2));
        StatutoryReports.SetSource(InStr);
        StatutoryReports.Import();
        StatutoryReports.ImportData(CopyStr(PathName, 1, 1024));
        Clear(InStr);
        ReportFile.Close();
    end;

    [Scope('OnPrem')]
    procedure ReleaseDataHeader(var StatutoryReportDataHeader: Record "Statutory Report Data Header")
    begin
        if StatutoryReportDataHeader.Status = StatutoryReportDataHeader.Status::Released then
            exit;

        StatutoryReportDataHeader.TestField(Status, StatutoryReportDataHeader.Status::Open);

        StatutoryReportDataHeader.Status := StatutoryReportDataHeader.Status::Released;
        StatutoryReportDataHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure ReopenDataHeader(var StatutoryReportDataHeader: Record "Statutory Report Data Header")
    begin
        if StatutoryReportDataHeader.Status = StatutoryReportDataHeader.Status::Open then
            exit;

        if StatutoryReportDataHeader.Status = StatutoryReportDataHeader.Status::Sent then
            Error(Text001);

        StatutoryReportDataHeader.TestField(Status, StatutoryReportDataHeader.Status::Released);

        StatutoryReportDataHeader.Status := StatutoryReportDataHeader.Status::Open;
        StatutoryReportDataHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        ServerFileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;
}

