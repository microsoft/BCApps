codeunit 130023 "Test Management Internal"
{

    trigger OnRun()
    begin
    end;

    var
        TestCoverageMapPath: Label '%INETROOT%\Build\Tools\AppTestTools\TestCoverageMap\';
        LoadTestCoverageMapMsg: Label 'Loading test coverage map files @1@@@@@@@';
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        NoOfRecords: Integer;
        i: Integer;
        ImportObjectsMsg: Label 'Importing and compiling %1 codeunits @1@@@@@@@';
        FinsqlPathTxt: Label '%INETROOT%\Run\release\finsql.exe';
        TestFilePath: Label '%INETROOT%\App\Test\COD%1.txt';
        ImportCommand: Label 'command=ImportObjects,File="%1"';
        CompileCommand: Label 'command=CompileObjects,Filter=Type=%1;ID=%2';
        ConnectionSetup: Label 'servername=%1,database=%2,';

    [Scope('OnPrem')]
    procedure LoadDefaultTestMap()
    var
        TestCoverageMap: Record "Test Coverage Map";
        TestMapFile: File;
        InStream: InStream;
        Directory: DotNet Directory;
        files: DotNet ArrayList;
        i: Integer;
    begin
        TestCoverageMap.DeleteAll();

        files := files.ArrayList();
        files.AddRange(Directory.GetFiles(ExpandEnvVariables(TestCoverageMapPath)));
        OpenWindow(LoadTestCoverageMapMsg, files.Count);
        for i := 0 to files.Count - 1 do begin
            TestMapFile.Open(ExpandEnvVariables(Format(files.Item(i))));
            TestMapFile.CreateInStream(InStream);
            XMLPORT.Import(XMLPORT::"Test Coverage Map", InStream);
            TestMapFile.Close();
            UpdateWindow();
        end;
        Window.Close();
    end;

    [Scope('OnPrem')]
    procedure ImportTestCodeunits(var CodeunitIds: Record "Integer")
    var
        ActiveSession: Record "Active Session";
        AllObj: Record AllObj;
        fileName: Text;
    begin
        if CodeunitIds.FindSet() then begin
            OpenWindow(StrSubstNo(ImportObjectsMsg, CodeunitIds.Count), CodeunitIds.Count);
            ActiveSession.Get(ServiceInstanceId(), SessionId());
            repeat
                fileName := ExpandEnvVariables(StrSubstNo(TestFilePath, CodeunitIds.Number));
                StartProcess(
                  ExpandEnvVariables(FinsqlPathTxt),
                  StrSubstNo(ConnectionSetup, ActiveSession."Server Computer Name", ActiveSession."Database Name") +
                  StrSubstNo(ImportCommand, fileName));
                StartProcess(
                  ExpandEnvVariables(FinsqlPathTxt),
                  StrSubstNo(ConnectionSetup, ActiveSession."Server Computer Name", ActiveSession."Database Name") +
                  StrSubstNo(CompileCommand, AllObj."Object Type"::Codeunit, CodeunitIds.Number));
                UpdateWindow();
            until CodeunitIds.Next() = 0;
            Window.Close();
        end;
    end;

    local procedure ExpandEnvVariables(Path: Text[1024]): Text[1024]
    var
        [RunOnClient]
        Environment: DotNet Environment;
    begin
        exit(Environment.ExpandEnvironmentVariables(Path));
    end;

    local procedure OpenWindow(DisplayText: Text[250]; NoOfRecords2: Integer)
    begin
        i := 0;
        NoOfRecords := NoOfRecords2;
        WindowUpdateDateTime := CurrentDateTime;
        Window.Open(DisplayText);
    end;

    local procedure UpdateWindow()
    begin
        i := i + 1;
        if CurrentDateTime - WindowUpdateDateTime >= 1000 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, Round(i / NoOfRecords * 10000, 1));
        end;
    end;

    [Scope('OnPrem')]
    procedure StartProcess(executable: Text[1024]; arguments: Text)
    var
        [RunOnClient]
        Process: DotNet Process;
        [RunOnClient]
        ProcessStartInfo: DotNet "System.Diagnostics.ProcessStartInfo";
    begin
        Process := Process.Process();
        ProcessStartInfo := ProcessStartInfo.ProcessStartInfo();
        ProcessStartInfo.FileName(executable);
        ProcessStartInfo.Arguments(arguments);
        Process.StartInfo(ProcessStartInfo);
        Process.Start();
        Process.WaitForExit();
    end;
}

