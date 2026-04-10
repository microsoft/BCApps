namespace System.TestTools.CodeCoverage;

using System;
using System.Reflection;
using System.Tooling;

codeunit 9990 "Code Coverage Mgt."
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        [WithEvents]
        Timer: DotNet Timer;
#pragma warning disable AA0470
        BackupErr: Label 'Code Coverage Backup encountered an error: %1.';
#pragma warning restore AA0470
        FormatStringTxt: Label '<Day,2>_<Month,2>_<Year>_<Hours24,2>_<Minutes,2>.', Locked = true;
        BackupFilePath: Text[1024];
        SummaryFilePath: Text[1024];
#pragma warning disable AA0470
        BackupPathFormatTxt: Label 'CodeCoverageBackup_%1.txt';
        SummaryPathFormatTxt: Label 'CodeCoverageSummary_%1.xml';
#pragma warning restore AA0470
        ApplicationBaseline: Integer;
        IsRunning: Boolean;
        CodeCovNotRunningErr: Label 'Code coverage is not running.';
        CodeCovAlreadyRunningErr: Label 'Code coverage is already running.';
        StartedByApp: Boolean;
        CannotNestAppCovErr: Label 'Cannot nest multiple calls to StartApplicationCoverage.';
        MultiSession: Boolean;

    procedure Start(MultiSessionValue: Boolean)
    begin
        MultiSession := MultiSessionValue;
        if IsRunning then
            Error(CodeCovAlreadyRunningErr);
        CodeCoverageLog(true, MultiSession);
        IsRunning := true;
    end;

    procedure Stop()
    begin
        if not IsRunning then
            Error(CodeCovNotRunningErr);
        CodeCoverageLog(false, MultiSession);
        IsRunning := false;
    end;

    procedure Refresh()
    begin
        CodeCoverageRefresh();
    end;

    procedure Clear()
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverage.DeleteAll();
    end;

    procedure Import()
    begin
        CodeCoverageLoad();
    end;

    procedure Include(var AllObj: Record AllObj)
    begin
        CodeCoverageInclude(AllObj);
    end;

    procedure Running(): Boolean
    begin
        exit(IsRunning);
    end;

    procedure StartApplicationCoverage()
    begin
        if IsRunning and StartedByApp then
            Error(CannotNestAppCovErr);

        if not IsRunning then begin
            StartedByApp := true;
            Start(false);
        end;

        // Establish baseline
        ApplicationBaseline := 0;
        ApplicationBaseline := ApplicationHits();
    end;

    procedure StopApplicationCoverage()
    begin
        if StartedByApp then
            Stop();
        StartedByApp := false;
    end;

    procedure ApplicationHits() NoOFLines: Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetFilter("No. of Hits", '>%1', 0);
        // excluding Code Coverage range 9900..9999 from calculation
        CodeCoverage.SetFilter("Object ID", '..9989|10000..129999|150000..');
        if CodeCoverage.FindSet() then
            repeat
                NoOFLines += CodeCoverage."No. of Hits";
            until CodeCoverage.Next() = 0;

        // Subtract baseline to produce delta
        NoOFLines -= ApplicationBaseline;
    end;

    procedure GetNoOfHitsCoverageForObject(ObjectType: Option; ObjectID: Integer; CodeLine: Text) NoOfHits: Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetRange("Object Type", ObjectType);
        CodeCoverage.SetRange("Object ID", ObjectID);
        CodeCoverage.SetFilter("No. of Hits", '>%1', 0);
        CodeCoverage.SetFilter(Line, '@*' + CodeLine + '*');
        if CodeCoverage.FindSet() then
            repeat
                NoOfHits += CodeCoverage."No. of Hits";
            until CodeCoverage.Next() = 0;
        exit(NoOfHits);
    end;

    procedure CoveragePercent(NoCodeLines: Integer; NoCodeLinesHit: Integer): Decimal
    begin
        if NoCodeLines > 0 then
            exit(NoCodeLinesHit / NoCodeLines);

        exit(1.0)
    end;

    procedure ObjectCoverage(var CodeCoverage: Record "Code Coverage"; var NoCodeLines: Integer; var NoCodeLinesHit: Integer): Decimal
    var
        CodeCoverage2: Record "Code Coverage";
    begin
        NoCodeLines := 0;
        NoCodeLinesHit := 0;

        CodeCoverage2.SetPosition(CodeCoverage.GetPosition());
        CodeCoverage2.SetRange("Object Type", CodeCoverage."Object Type");
        CodeCoverage2.SetRange("Object ID", CodeCoverage."Object ID");

        repeat
            if CodeCoverage2."Line Type" = CodeCoverage2."Line Type"::Code then begin
                NoCodeLines += 1;
                if CodeCoverage2."No. of Hits" > 0 then
                    NoCodeLinesHit += 1;
            end
        until (CodeCoverage2.Next() = 0) or
                (CodeCoverage2."Line Type" = CodeCoverage2."Line Type"::Object);

        exit(CoveragePercent(NoCodeLines, NoCodeLinesHit))
    end;

    procedure ObjectsCoverage(var CodeCoverage: Record "Code Coverage"; var NoCodeLines: Integer; var NoCodeLinesHit: Integer): Decimal
    var
        CodeCoverage2: Record "Code Coverage";
    begin
        NoCodeLines := 0;
        NoCodeLinesHit := 0;

        CodeCoverage2.CopyFilters(CodeCoverage);
        CodeCoverage2.SetFilter("Line Type", 'Code');
        repeat
            NoCodeLines += 1;
            if CodeCoverage2."No. of Hits" > 0 then
                NoCodeLinesHit += 1;
        until CodeCoverage2.Next() = 0;

        exit(CoveragePercent(NoCodeLines, NoCodeLinesHit))
    end;

    procedure FunctionCoverage(var CodeCoverage: Record "Code Coverage"; var NoCodeLines: Integer; var NoCodeLinesHit: Integer): Decimal
    var
        CodeCoverage2: Record "Code Coverage";
    begin
        NoCodeLines := 0;
        NoCodeLinesHit := 0;

        CodeCoverage2.SetPosition(CodeCoverage.GetPosition());
        CodeCoverage2.SetRange("Object Type", CodeCoverage."Object Type");
        CodeCoverage2.SetRange("Object ID", CodeCoverage."Object ID");

        repeat
            if CodeCoverage2."Line Type" = CodeCoverage2."Line Type"::Code then begin
                NoCodeLines += 1;
                if CodeCoverage2."No. of Hits" > 0 then
                    NoCodeLinesHit += 1;
            end
        until (CodeCoverage2.Next() = 0) or
                (CodeCoverage2."Line Type" = CodeCoverage2."Line Type"::Object) or
                (CodeCoverage2."Line Type" = CodeCoverage2."Line Type"::"Trigger/Function");

        exit(CoveragePercent(NoCodeLines, NoCodeLinesHit))
    end;

    [Scope('OnPrem')]
    procedure CreateBackupFile(BackupPath: Text)
    var
        BackupStream: OutStream;
        BackupFile: File;
    begin
        Refresh();

        BackupFile.Create(BackupPath);
        BackupFile.CreateOutStream(BackupStream);
        XMLPORT.Export(XMLPORT::"Code Coverage Detailed", BackupStream);
        BackupFile.Close();
    end;

    [Scope('OnPrem')]
    procedure CreateSummaryFile(SummaryPath: Text)
    var
        SummaryStream: OutStream;
        SummaryFile: File;
    begin
        Refresh();

        SummaryFile.Create(SummaryPath);
        SummaryFile.CreateOutStream(SummaryStream);
        XMLPORT.Export(XMLPORT::"Code Coverage Summary", SummaryStream);
        SummaryFile.Close();
    end;

    procedure StartAutomaticBackup(TimeInterval: Integer; BackupPath: Text[1024]; SummaryPath: Text[1024])
    var
        AllObj: Record AllObj;
    begin
        Include(AllObj); // Load all objects
        Start(false); // Start code coverage

        // Setup Timer and File Paths
        if IsNull(Timer) then
            Timer := Timer.Timer();
        UpdateAutomaticBackupSettings(TimeInterval, BackupPath, SummaryPath);
    end;

    procedure UpdateAutomaticBackupSettings(TimeInterval: Integer; BackupPath: Text[1024]; SummaryPath: Text[1024])
    begin
        if not IsNull(Timer) then begin
            Timer.Stop();
            Timer.Interval := TimeInterval * 60000;
            BackupFilePath := BackupPath;
            SummaryFilePath := SummaryPath;
            Timer.Start();
        end;
    end;

    trigger Timer::Elapsed(sender: Variant; e: DotNet EventArgs)
    begin
        CreateBackupFile(BackupFilePath + StrSubstNo(BackupPathFormatTxt, Format(CurrentDateTime, 0, FormatStringTxt)));
        CreateSummaryFile(SummaryFilePath + StrSubstNo(SummaryPathFormatTxt, Format(CurrentDateTime, 0, FormatStringTxt)));
    end;

    trigger Timer::ExceptionOccurred(sender: Variant; e: DotNet ExceptionOccurredEventArgs)
    begin
        Error(BackupErr, e.Exception.Message);
    end;
}

