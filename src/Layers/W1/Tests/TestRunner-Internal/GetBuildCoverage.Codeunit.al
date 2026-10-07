codeunit 130029 "Get Build Coverage"
{

    trigger OnRun()
    var
        GetCoverage: Page "Get Coverage";
        MergedTestCoveragePath: Text;
    begin
        GetCoverage.LookupMode := true;
        if GetCoverage.RunModal() <> ACTION::LookupOK then
            exit;

        Initialize(GetCoverage.GetFromDateTime(), GetCoverage.GetToDateTime(), GetCoverage.GetSnapQueueID(), GetCoverage.GetCountryCode(), GetCoverage.GetSdAppPath());

        MergedTestCoveragePath := UnzipAndCCMergeTestResults(SnapQueueID, CountryCode);

        FetchingChangelistCode(SdAppPath, FromDateTime, ToDateTime);

        LoadTestCodeCoverageResults(MergedTestCoveragePath);

        UpdateWindow(4);
        CODEUNIT.Run(CODEUNIT::"Calculate Changelist Coverage");
        UpdateDoneWindow(4);

        Message(CompletedMsg);
    end;

    var
        GettingCodeCoverageMsg: Label 'Getting code coverage based on:\- Test results of snap checkin id: %1\- Country: %2\- Code checkins between: %3 and %4\';
        DownloadingUnzippingMergingTestResultsMsg: Label 'Downloading, unzipping and merging test results #2########################\';
        ImportingCodeCoverageMsg: Label 'Importing code coverage test results #3########################\';
        FetchingChangelistCodeMsg: Label 'Fetching changelist code #1########################\';
        GetChangelistCode: Codeunit "Get Changelist Code";
        Window: Dialog;
        WindowIsOpen: Boolean;
        FromDateTime: DateTime;
        ToDateTime: DateTime;
        SnapQueueID: Text[10];
        CountryCode: Text;
        SdAppPath: Text;
        ComputingCoverageMsg: Label 'Computing coverage #4########################\';
        StartedMsg: Label 'Started...';
        DoneInMsg: Label 'Done in %1';
        StartTime: DateTime;
        CompletedMsg: Label 'Fetching coverage completed.';

    local procedure Initialize(NewFromDateTime: DateTime; NewToDateTime: DateTime; NewSnapQueueID: Text[10]; NewCountryCode: Text; NewSdAppPath: Text)
    begin
        FromDateTime := NewFromDateTime;
        ToDateTime := NewToDateTime;
        SnapQueueID := NewSnapQueueID;
        CountryCode := NewCountryCode;
        SdAppPath := NewSdAppPath;
    end;

    [Scope('OnPrem')]
    procedure LoadTestCodeCoverageResults(TestCoveragePath: Text)
    var
        InputFile: File;
        DataStream: InStream;
    begin
        UpdateWindow(3);

        InputFile.Open(TestCoveragePath);

        InputFile.CreateInStream(DataStream);
        XMLPORT.Import(XMLPORT::"Import Code Cov. Test Results", DataStream);
        InputFile.Close();

        UpdateDoneWindow(3);
    end;

    local procedure FetchingChangelistCode(SdAppPath: Text; FromDateTime: DateTime; ToDateTime: DateTime)
    var
        ChangelistCode: Record "Changelist Code";
        GetChangelistCode: Codeunit "Get Changelist Code";
    begin
        UpdateWindow(1);

        ChangelistCode.DeleteAll();
        GetChangelistCode.ProcessChangeList(
          RunGetSDChanges(
            SdAppPath, ConvertDateTimeToSdDateTime(FromDateTime), ConvertDateTimeToSdDateTime(ToDateTime)));
        GetChangelistCode.Cleanup();

        UpdateDoneWindow(1);
    end;

    [Scope('OnPrem')]
    procedure UnzipAndCCMergeTestResults(SnapQueueID: Text[10]; CountryCode: Text) FileName: Text
    var
        [RunOnClient]
        SystemDiagnosticsProcess: DotNet Process;
        errorText: Text;
    begin
        UpdateWindow(2);

        FileName := 'TestResults.txt';

        InitSd(
          SystemDiagnosticsProcess,
          StrSubstNo(
            '%1%5 %1 -CoreXtBranch ''Main''; %1%6 -CheckinID ''%2'' -FileName ''%3'' -CountryCode ''%4''',
            GetChangelistCode.GetSdClientPath(),
            SnapQueueID,
            FileName,
            CountryCode,
            'Eng\Core\Enlistment\start.ps1',
            'Eng\Normal\Tools\CALCodeCoverage\ProcessCoverageResults.ps1'));

        SystemDiagnosticsProcess.Start();

        errorText := DelChr(SystemDiagnosticsProcess.StandardError.ReadToEnd(), '<>', ' ');

        SystemDiagnosticsProcess.WaitForExit();

        SystemDiagnosticsProcess.Close();

        if errorText <> '' then
            Error(errorText);

        FileName := GetChangelistCode.GetSdClientPath() + 'App\ALCodeCoverage\' + SnapQueueID + '\' +
          CountryCode + '\' + FileName;

        UpdateDoneWindow(2);
    end;

    local procedure RunGetSDChanges(SdAppPath: Text; FromDateTime: Text; ToDateTime: Text) FileName: Text
    var
        [RunOnClient]
        SystemDiagnosticsProcess: DotNet Process;
        errorText: Text;
    begin
        FileName := GetChangelistCode.GetSdClientPath() + 'App\ALCodeCoverage\' + CountryCode + '\SDChanges.txt';

        InitSd(
          SystemDiagnosticsProcess,
          StrSubstNo(
            '%1%6 %1 -CoreXtBranch ''Main''; %1%7 -SDFolder ''%2'' -FromDateTime ''%3'' -ToDateTime ''%4'' -OutputFile ''%5''',
            GetChangelistCode.GetSdClientPath(),
            SdAppPath,
            FromDateTime,
            ToDateTime,
            FileName,
            'Eng\Core\Enlistment\start.ps1',
            'Build\Application\GetSDChanges.ps1'));

        SystemDiagnosticsProcess.Start();

        errorText := DelChr(SystemDiagnosticsProcess.StandardError.ReadToEnd(), '<>', ' ');

        SystemDiagnosticsProcess.WaitForExit();

        SystemDiagnosticsProcess.Close();

        if errorText <> '' then
            Error(errorText);
    end;

    local procedure InitSd(var SystemDiagnosticsProcess: DotNet Process; command: Text)
    begin
        SystemDiagnosticsProcess := SystemDiagnosticsProcess.Process();
        SystemDiagnosticsProcess.StartInfo.FileName('powershell.exe');
        SystemDiagnosticsProcess.StartInfo.Arguments(command);
        SystemDiagnosticsProcess.StartInfo.UseShellExecute := false;
        SystemDiagnosticsProcess.StartInfo.RedirectStandardError := true;
        SystemDiagnosticsProcess.StartInfo.RedirectStandardOutput := false;

        SystemDiagnosticsProcess.StartInfo.CreateNoWindow := true;
    end;

    local procedure ConvertDateTimeToSdDateTime(FromDateTime: DateTime): Text[30]
    var
        Date: Date;
        Time: Time;
        DayText: Text;
        MonthText: Text;
        YearText: Text;
    begin
        Date := DT2Date(FromDateTime);
        Time := DT2Time(FromDateTime);
        DayText := Format(Date2DMY(Date, 1));
        MonthText := Format(Date2DMY(Date, 2));
        YearText := Format(Date2DMY(Date, 3));
        if StrLen(DayText) = 1 then
            DayText := '0' + DayText;
        if StrLen(MonthText) = 1 then
            MonthText := '0' + MonthText;
        exit(StrSubstNo('%1/%2/%3:%4', YearText, MonthText, DayText, Time))
    end;

    local procedure OpenWindow()
    begin
        Window.Open(
          StrSubstNo(GettingCodeCoverageMsg, SnapQueueID, CountryCode, FromDateTime, ToDateTime) +
          FetchingChangelistCodeMsg +
          DownloadingUnzippingMergingTestResultsMsg +
          ImportingCodeCoverageMsg +
          ComputingCoverageMsg);
    end;

    local procedure UpdateWindow(What: Integer)
    begin
        if not WindowIsOpen then
            OpenWindow();
        WindowIsOpen := true;
        Window.Update(What, StartedMsg);
        StartTime := CurrentDateTime;
    end;

    local procedure UpdateDoneWindow(What: Integer)
    begin
        Window.Update(What, StrSubstNo(DoneInMsg, CurrentDateTime - StartTime));
    end;

    [Scope('OnPrem')]
    procedure GetTestResults()
    var
        GetCoverage: Page "Get Coverage";
        MergedTestCoveragePath: Text;
    begin
        GetCoverage.Init(true);
        GetCoverage.LookupMode := true;
        if GetCoverage.RunModal() <> ACTION::LookupOK then
            exit;

        Initialize(0DT, 0DT, GetCoverage.GetSnapQueueID(), GetCoverage.GetCountryCode(), '');

        MergedTestCoveragePath := UnzipAndCCMergeTestResults(SnapQueueID, CountryCode);

        LoadTestCodeCoverageResults(MergedTestCoveragePath);
    end;
}

