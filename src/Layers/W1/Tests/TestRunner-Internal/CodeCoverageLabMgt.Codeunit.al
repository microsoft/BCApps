codeunit 130003 "Code Coverage Lab Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        InputFilePathTxt: Label '%INETROOT%\NTF_Bin\Changes.txt';
        OutputFilePathTxt: Label '%INETROOT%\Application.codebase';
        GetChangelistCode: Codeunit "Get Changelist Code";

    procedure CreateAppCodeBase()
    begin
        CodeCoverageMgt.Start(false);

        GetChangelistCode.ProcessChangeList(ExpandEnvVariables(InputFilePathTxt));
        IncludeAllCodeBase();
        DumpCodeBaseLines(ExpandEnvVariables(OutputFilePathTxt));

        CodeCoverageMgt.Stop();
    end;

    local procedure DumpCodeBaseLines(FilePath: Text)
    var
        DataStream: OutStream;
        CCDumpFile: File;
    begin
        CodeCoverageMgt.Refresh();

        CCDumpFile.Create(StrSubstNo(FilePath));
        CCDumpFile.CreateOutStream(DataStream);
        XMLPORT.Export(XMLPORT::"Code Base Lines", DataStream);
        CCDumpFile.Close();
    end;

    procedure CalculateAndExportGitBasedALCodeCoverage(CheckinID: Text; ChangesInputFile: Text; CoverageInputFile: Text; OutputFile: Text; OutputFilePerObject: Text)
    begin
        // To be used as Web Service
        CodeCoverageMgt.Start(false);

        GetChangelistCode.ProcessGitChanges(ChangesInputFile);
        IncludeAllCodeBase();
        RestoreFromBackupFile(CoverageInputFile);
        DumpALCodeCoverage(CheckinID, OutputFile);
        DumpALCodeCoveragePerObject(CheckinID, OutputFilePerObject);
        CodeCoverageMgt.Stop();
    end;

    procedure CalculateAndExportALCodeCoverage(CheckinID: Text; ChangesInputFile: Text; CoverageInputFile: Text; OutputFile: Text; OutputFilePerObject: Text)
    begin
        // To be used as Web Service
        CodeCoverageMgt.Start(false);

        GetChangelistCode.ProcessChangeList(ChangesInputFile);
        IncludeAllCodeBase();
        RestoreFromBackupFile(CoverageInputFile);
        DumpALCodeCoverage(CheckinID, OutputFile);
        DumpALCodeCoveragePerObject(CheckinID, OutputFilePerObject);
        CodeCoverageMgt.Stop();
    end;

    local procedure DumpALCodeCoverage(CheckinID: Text; FilePath: Text)
    var
        CoverageResultsDetailed: XMLport "Coverage Results Detailed";
        DataStream: OutStream;
        CCDumpFile: File;
    begin
        CodeCoverageMgt.Refresh();

        CCDumpFile.Create(StrSubstNo(FilePath));
        CCDumpFile.CreateOutStream(DataStream);
        CoverageResultsDetailed.SetSkipTestAndDemo(true);
        CoverageResultsDetailed.SetCheckinID(CheckinID);
        CoverageResultsDetailed.SetDestination(DataStream);
        CoverageResultsDetailed.Export();
        CCDumpFile.Close();
    end;

    local procedure DumpALCodeCoveragePerObject(CheckinID: Text; FilePath: Text)
    var
        CoverageResultsSummary: XMLport "Coverage Results Summary";
        DataStream: OutStream;
        CCDumpFile: File;
    begin
        CodeCoverageMgt.Refresh();

        CCDumpFile.Create(StrSubstNo(FilePath));
        CCDumpFile.CreateOutStream(DataStream);
        CoverageResultsSummary.SetSkipTestAndDemo(true);
        CoverageResultsSummary.SetCheckinID(CheckinID);
        CoverageResultsSummary.SetDestination(DataStream);
        CoverageResultsSummary.Export();
        CCDumpFile.Close();
    end;

    procedure RestoreFromBackupFile(FilePath: Text)
    var
        CodeCoverageDetailed: XMLport "Code Coverage Detailed";
        DataStream: InStream;
        BackupFile: File;
    begin
        BackupFile.Open(FilePath);
        BackupFile.CreateInStream(DataStream);

        CodeCoverageDetailed.ImportFile := true;
        CodeCoverageDetailed.SetSource(DataStream);
        CodeCoverageDetailed.Import();

        BackupFile.Close();
    end;

    local procedure IncludeAllCodeBase()
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetFilter("Object ID", '..1069|1073..1806|1811..1449|1455..99999|150000..'); // exclude test, costing suite and demo tool range
        CodeCoverageMgt.Include(AllObj);
    end;

    procedure IncludeAll()
    var
        AllObj: Record AllObj;
    begin
        CodeCoverageMgt.Include(AllObj);
    end;

    local procedure ExpandEnvVariables(Path: Text): Text
    var
        [RunOnClient]
        Environment: DotNet Environment;
    begin
        exit(Environment.ExpandEnvironmentVariables(Path))
    end;
}

