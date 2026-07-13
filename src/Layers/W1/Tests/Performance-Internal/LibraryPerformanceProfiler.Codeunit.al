codeunit 132209 "Library - Performance Profiler"
{

    trigger OnRun()
    begin
    end;

    var
        EtwPerformanceProfiler: DotNet EtwPerformanceProfiler;
        DescriptionTxt: Label 'Id, Session ID, Indentation, Object Type, Object ID, Line No, Event type, Statement, Duration, HitCount, OriginalType, SubType, IsALEvent;';
        LineTxt: Label '%1, %2, %3, %4, %5, %6, %7, %8, %9, %10, %11, %12, %13;';
        TotalTxt: Label 'Total: %1;';
        TotalSQLQueriesTxt: Label 'Total SQL Queries: %1;';
        TotalSQLQueryDurationTxt: Label 'Total SQL Query Duration: %1;';
        TotalSQLQueryHitCountTxt: Label 'Total SQL Query Hit Count: %1;';
        MaxSQLQueryDurationTxt: Label 'Max SQL Query Duration: %1;';
        MaxSQLQueryHitCountTxt: Label 'Max SQL Query Hit Count: %1;';
        TraceDumpFileNamePrefixTxt: Label 'PerformanceProfilerTests', Locked = true;
        ProfilerIdentificationTxt: Label 'Profiler Identification: %1;';
        TotalMDSQLQueriesTxt: Label 'Total MetaData (2000000207,2000000071) SQL Queries: %1;';
        TotalMDSQLQueryHitCountTxt: Label 'Total MetaData (2000000207,2000000071) SQL Query Hit Count: %1;';
        ProfilerIdentification: Text;

    procedure SetProfilerIdentification(NewProfilerIdentification: Text)
    begin
        ProfilerIdentification := NewProfilerIdentification;
    end;

    procedure StartProfiler(ClearCache: Boolean)
    var
        PermissionTestHelper: DotNet PermissionTestHelper;
    begin
        if ClearCache then
            SelectLatestVersion();
        PermissionTestHelper := PermissionTestHelper.PermissionTestHelper();
        PermissionTestHelper.EnableFullALFunctionTracing(true);
        EtwPerformanceProfiler := EtwPerformanceProfiler.EtwPerformanceProfiler();
        EtwPerformanceProfiler.Start(SessionId(), -1);
    end;

    procedure StopProfiler(var PerfProfilerEventsTest: Record "Perf Profiler Events Test"; TestName: Text; LogFromObjectType: Option; LogFromObjectID: Integer; LogResults: Boolean): Text
    var
        PermissionTestHelper: DotNet PermissionTestHelper;
        I: Integer;
        ObjectID: Integer;
        ObjectType: Option;
        StartLogging: Boolean;
        PauseLogging: Boolean;
        ObjectIsATestLibrary: Boolean;
    begin
        Sleep(WaitingTimeForProfilerEventsCollection());
        PerfProfilerEventsTest.Reset();
        PerfProfilerEventsTest.DeleteAll();
        PermissionTestHelper := PermissionTestHelper.PermissionTestHelper();
        PermissionTestHelper.EnableFullALFunctionTracing(false);
        EtwPerformanceProfiler.Stop();
        I := 1;

        while EtwPerformanceProfiler.CallTreeMoveNext() do begin
            ObjectID := EtwPerformanceProfiler.CallTreeCurrentStatementOwningObjectId;
            ObjectType := EtwPerformanceProfiler.CallTreeCurrentStatementOwningObjectType;
            ObjectIsATestLibrary := (ObjectID >= 130000) and (ObjectID < 133000);
            if not StartLogging then
                StartLogging := (ObjectType = LogFromObjectType) and (ObjectID = LogFromObjectID);

            // pause logging when test libraries start issuing calls
            if not PauseLogging then
                PauseLogging := ObjectIsATestLibrary
            else
                PauseLogging := (ObjectID = 0) or ObjectIsATestLibrary;

            if StartLogging and not PauseLogging then begin
                Clear(PerfProfilerEventsTest);
                PerfProfilerEventsTest.Init();
                PerfProfilerEventsTest.Id := I;
                PerfProfilerEventsTest."Session ID" := SessionId();
                PerfProfilerEventsTest.Indentation := EtwPerformanceProfiler.CallTreeCurrentStatementIndentation;
                PerfProfilerEventsTest."Object Type" := EtwPerformanceProfiler.CallTreeCurrentStatementOwningObjectType;
                PerfProfilerEventsTest."Object ID" := EtwPerformanceProfiler.CallTreeCurrentStatementOwningObjectId;
                PerfProfilerEventsTest."Line No" := EtwPerformanceProfiler.CallTreeCurrentStatementLineNo;
                PerfProfilerEventsTest.Statement :=
                  CopyStr(EtwPerformanceProfiler.CallTreeCurrentStatement, 1, MaxStrLen(PerfProfilerEventsTest.Statement));
                PerfProfilerEventsTest.Duration := EtwPerformanceProfiler.CallTreeCurrentStatementDurationMs;
                PerfProfilerEventsTest.HitCount := EtwPerformanceProfiler.CallTreeCurrentStatementHitCount;
                PerfProfilerEventsTest."Event Type" := EtwPerformanceProfiler.CallTreeCurrentSqlEventType;
                PerfProfilerEventsTest."Original Type" := EtwPerformanceProfiler.CallTreeCurrentOriginalType;
                PerfProfilerEventsTest."Sub Type" := EtwPerformanceProfiler.CallTreeCurrentSubType;
                PerfProfilerEventsTest.IsALEvent := EtwPerformanceProfiler.CallTreeCurrentStatementIsAlEvent;
                PerfProfilerEventsTest.Insert();
                I += 1;
            end;
        end;
        EtwPerformanceProfiler.Dispose();

        PerfProfilerEventsTest.CalcFields(
          Total, "Total SQL Queries", "Total SQL Query Duration", "Total SQL Query Hit Count", "Max SQL Query Duration",
          "Max SQL Query Hit Count");

        if LogResults then
            exit(SavePerfProfilerResultToDisk(PerfProfilerEventsTest, TestName));

        exit('');
    end;

    local procedure WaitingTimeForProfilerEventsCollection(): Integer
    begin
        exit(5000)
    end;

    local procedure SavePerfProfilerResultToDisk(PerfProfilerEventsTest: Record "Perf Profiler Events Test"; TestName: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
        FileStr: Text;
    begin
        TempBlob.CreateOutStream(OutStream);

        OutStream.WriteText(DescriptionTxt);
        AddLineBreak(OutStream);

        PerfProfilerEventsTest.SetFilter(Statement, '<> *2000000207*User AL Code* & <> *2000000071*User AL Code*');

        if PerfProfilerEventsTest.FindSet() then
            repeat
                OutStream.WriteText(
                  StrSubstNo(
                    LineTxt,
                    PerfProfilerEventsTest.Id,
                    PerfProfilerEventsTest."Session ID",
                    PerfProfilerEventsTest.Indentation,
                    PerfProfilerEventsTest."Object Type",
                    PerfProfilerEventsTest."Object ID",
                    PerfProfilerEventsTest."Line No",
                    PerfProfilerEventsTest."Event Type",
                    PerfProfilerEventsTest.Statement,
                    PerfProfilerEventsTest.Duration,
                    PerfProfilerEventsTest.HitCount,
                    PerfProfilerEventsTest."Original Type",
                    PerfProfilerEventsTest."Sub Type",
                    PerfProfilerEventsTest.IsALEvent
                    ));
                AddLineBreak(OutStream);
            until PerfProfilerEventsTest.Next() = 0;

        PerfProfilerEventsTest.CalcFields(
          Total, "Total SQL Queries", "Total SQL Query Duration", "Total SQL Query Hit Count", "Max SQL Query Duration",
          "Max SQL Query Hit Count", "Total MD SQL Queries", "Total MD SQL Query Hit Count");

        OutStream.WriteText(StrSubstNo(TotalMDSQLQueriesTxt, PerfProfilerEventsTest."Total MD SQL Queries"));
        AddLineBreak(OutStream);
        OutStream.WriteText(StrSubstNo(TotalMDSQLQueryHitCountTxt, PerfProfilerEventsTest."Total MD SQL Query Hit Count"));
        AddLineBreak(OutStream);
        OutStream.WriteText(StrSubstNo(TotalTxt, PerfProfilerEventsTest.Total));
        AddLineBreak(OutStream);
        OutStream.WriteText(StrSubstNo(TotalSQLQueriesTxt, PerfProfilerEventsTest."Total SQL Queries"));
        AddLineBreak(OutStream);
        OutStream.WriteText(StrSubstNo(TotalSQLQueryDurationTxt, PerfProfilerEventsTest."Total SQL Query Duration"));
        AddLineBreak(OutStream);
        OutStream.WriteText(StrSubstNo(TotalSQLQueryHitCountTxt, PerfProfilerEventsTest."Total SQL Query Hit Count"));
        AddLineBreak(OutStream);
        OutStream.WriteText(StrSubstNo(MaxSQLQueryDurationTxt, PerfProfilerEventsTest."Max SQL Query Duration"));
        AddLineBreak(OutStream);
        OutStream.WriteText(StrSubstNo(MaxSQLQueryHitCountTxt, PerfProfilerEventsTest."Max SQL Query Hit Count"));
        AddLineBreak(OutStream);
        OutStream.WriteText(StrSubstNo(ProfilerIdentificationTxt, ProfilerIdentification));

        // export the BLOB to a new temp file.
        FileStr := '%1_%2_%3_%4.txt';
        FileName := FileMgt.GetSafeFileName(StrSubstNo(FileStr, TraceDumpFileNamePrefixTxt, TestName, Today, Time));
        TempBlob.CreateInStream(InStream);
        DownloadFromStream(InStream, '', FileMgt.Magicpath(), '', FileName);
        exit(FileName);
    end;

    local procedure AddLineBreak(var OutStream: OutStream)
    var
        LF: Char;
        CR: Char;
    begin
        LF := 10;
        CR := 13;
        OutStream.WriteText(Format(CR, 0, '<CHAR>') + Format(LF, 0, '<CHAR>'));
    end;
}