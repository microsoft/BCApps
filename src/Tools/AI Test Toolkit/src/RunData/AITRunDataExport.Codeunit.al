// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

codeunit 149051 "AIT Run Data Export"
{
    Access = Internal;

    procedure GetRunResults(var AITLogEntry: Record "AIT Log Entry"): Text
    var
        AgentTaskLog: Record "Agent Task Log";
        EvaluationResult: JsonObject;
        EvaluationResults: JsonArray;
        RunResults: JsonObject;
        ResultText: Text;
    begin
        InitializeEvaluationFolderNames(AITLogEntry);
        if not AITLogEntry.FindSet() then
            exit;

        RunResults.Add(SuiteTok, AITLogEntry."Test Suite Code");
        RunResults.Add(VersionTok, AITLogEntry.Version);
        RunResults.Add(ExportStatusFileTok, ExportStatusFileTxt);
        RunResults.Add(AnalysisGuidanceTok, AnalysisGuidanceTxt);
        repeat
            Clear(EvaluationResult);
            EvaluationResult.Add(AIEvalLogIDTok, AITLogEntry."Entry No.");
            EvaluationResult.Add(MethodLineTok, AITLogEntry."Test Method Line No.");
            EvaluationResult.Add(DatasetGroupCodeTok, AITLogEntry."Test Input Group Code");
            EvaluationResult.Add(TestInputCodeTok, AITLogEntry."Test Input Code");
            EvaluationResult.Add(StatusTok, GetStatus(AITLogEntry));
            EvaluationResult.Add(AccuracyTok, AITLogEntry."Test Method Line Accuracy");
            EvaluationResult.Add(PathTok, GetEvaluationResultRelativePath(AITLogEntry));

            AgentTaskLog.SetRange("Test Log Entry ID", AITLogEntry."Entry No.");
            EvaluationResult.Add(AgentTaskCountTok, AgentTaskLog.Count());
            EvaluationResults.Add(EvaluationResult);
        until AITLogEntry.Next() = 0;

        RunResults.Add(EvaluationsTok, EvaluationResults);
        RunResults.WriteTo(ResultText);
        exit(ResultText);
    end;

    procedure GetAgentTaskExportError(AgentTaskID: BigInteger; ErrorText: Text): Text
    var
        ExportError: JsonObject;
        ResultText: Text;
    begin
        ExportError.Add(AgentTaskIDTok, AgentTaskID);
        ExportError.Add(ExportStatusTok, FailedTxt);
        ExportError.Add(ErrorTok, ErrorText);
        ExportError.WriteTo(ResultText);
        exit(ResultText);
    end;

    procedure GetEvaluationResult(AITLogEntry: Record "AIT Log Entry"): Text
    var
        AgentTaskLog: Record "Agent Task Log";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        AgentTaskDetails: JsonArray;
        Dataset: JsonObject;
        EvaluationResult: JsonObject;
        Result: JsonObject;
        ResultText: Text;
    begin
        AITLogEntry.CalcFields("Codeunit Name");
        EvaluationResult.Add(SuiteTok, AITLogEntry."Test Suite Code");
        EvaluationResult.Add(SuiteDescriptionTok, AITLogEntry.GetSuiteDescription());
        EvaluationResult.Add(VersionTok, AITLogEntry.Version);
        EvaluationResult.Add(AIEvalLogIDTok, AITLogEntry."Entry No.");
        EvaluationResult.Add(SystemIDTok, AITLogEntry.SystemId);
        EvaluationResult.Add(RunIDTok, AITLogEntry."Run ID");
        EvaluationResult.Add(TagTok, AITLogEntry.Tag);
        EvaluationResult.Add(MethodLineTok, AITLogEntry."Test Method Line No.");
        EvaluationResult.Add(MethodLineDescriptionTok, AITLogEntry.GetTestMethodLineDescription());
        EvaluationResult.Add(OperationTok, AITLogEntry.Operation);
        EvaluationResult.Add(ProcedureTok, AITLogEntry."Procedure Name");
        EvaluationResult.Add(CodeunitIDTok, AITLogEntry."Codeunit ID");
        EvaluationResult.Add(CodeunitNameTok, AITLogEntry."Codeunit Name");
        EvaluationResult.Add(StartTimeTok, AITLogEntry."Start Time");
        EvaluationResult.Add(EndTimeTok, AITLogEntry."End Time");
        EvaluationResult.Add(LastModifiedDateTimeTok, AITLogEntry.SystemModifiedAt);

        Dataset.Add(GroupCodeTok, AITLogEntry."Test Input Group Code");
        Dataset.Add(InputCodeTok, AITLogEntry."Test Input Code");
        Dataset.Add(DescriptionTok, AITLogEntry."Test Input Description");
        EvaluationResult.Add(DatasetTok, Dataset);

        AddTextAsJson(EvaluationResult, InputTok, AITLogEntry.GetInputBlob());
        AddTextAsJson(EvaluationResult, OutputTok, AITLogEntry.GetOutputBlob());

        Result.Add(StatusTok, GetStatus(AITLogEntry));
        Result.Add(MessageTok, AITLogEntry.GetMessage());
        Result.Add(ErrorCallStackTok, AITLogEntry.GetErrorCallStack());
        Result.Add(DurationMsTok, AITLogEntry."Duration (ms)");
        Result.Add(AccuracyTok, AITLogEntry."Test Method Line Accuracy");
        Result.Add(TurnsTok, AITLogEntry."No. of Turns");
        Result.Add(TurnsPassedTok, AITLogEntry."No. of Turns Passed");
        Result.Add(TokensConsumedTok, AITLogEntry."Tokens Consumed");
        Result.Add(CopilotCreditsTok, AgentTestContextImpl.GetCopilotCreditsForLogEntry(AITLogEntry."Entry No."));
        Result.Add(SensitiveTok, AITLogEntry.Sensitive);
        EvaluationResult.Add(ResultTok, Result);

        AgentTaskLog.SetRange("Test Log Entry ID", AITLogEntry."Entry No.");
        if AgentTaskLog.FindSet() then
            repeat
                AgentTaskDetails.Add(GetAgentTaskDetailsRelativePath(AgentTaskLog."Agent Task ID"));
            until AgentTaskLog.Next() = 0;
        EvaluationResult.Add(AgentTaskDetailsTok, AgentTaskDetails);

        EvaluationResult.WriteTo(ResultText);
        exit(ResultText);
    end;

    procedure GetResultsFilePath(TestSuiteCode: Code[100]; Version: Integer): Text
    begin
        exit(StrSubstNo(RunResultsPathTxt, GetSafePathSegment(TestSuiteCode, SuiteFallbackTxt), Version));
    end;

    procedure GetEvaluationResultFilePath(AITLogEntry: Record "AIT Log Entry"): Text
    begin
        exit(StrSubstNo(EvaluationResultPathTxt, GetRunFolderPath(AITLogEntry."Test Suite Code", AITLogEntry.Version), GetEvaluationFolderName(AITLogEntry), AITLogEntry."Entry No."));
    end;

    procedure GetAgentTaskDetailsFilePath(AITLogEntry: Record "AIT Log Entry"; AgentTaskID: BigInteger): Text
    begin
        exit(StrSubstNo(AgentTaskDetailsPathTxt, GetRunFolderPath(AITLogEntry."Test Suite Code", AITLogEntry.Version), GetEvaluationFolderName(AITLogEntry), AgentTaskID));
    end;

    local procedure GetRunFolderPath(TestSuiteCode: Code[100]; Version: Integer): Text
    begin
        exit(StrSubstNo(RunFolderPathTxt, GetSafePathSegment(TestSuiteCode, SuiteFallbackTxt), Version));
    end;

    local procedure GetEvaluationFolderName(AITLogEntry: Record "AIT Log Entry"): Text
    var
        FolderName: Text;
    begin
        if not EvaluationFolderNames.Get(GetDatasetIdentity(AITLogEntry), FolderName) then
            Error(FolderNamesNotInitializedErr);
        exit(FolderName);
    end;

    local procedure InitializeEvaluationFolderNames(var AITLogEntry: Record "AIT Log Entry")
    var
        OriginalView: Text;
        FolderName: Text;
    begin
        Clear(EvaluationFolderNames);
        Clear(AllocatedFolderNames);
        Clear(FolderNameSuffixes);
        MaximumFolderNameLength := 255;
        OriginalView := AITLogEntry.GetView(false);
        AITLogEntry.SetCurrentKey("Entry No.");
        AITLogEntry.Ascending(true);

        if AITLogEntry.FindSet() then
            repeat
                FolderName := GetFullEvaluationFolderName(AITLogEntry);
                if StrLen(FolderName) <= MaximumFolderNameLength then
                    if not AllocatedFolderNames.ContainsKey(FolderName.ToUpper()) then
                        AllocatedFolderNames.Add(FolderName.ToUpper(), false);
            until AITLogEntry.Next() = 0;

        if AITLogEntry.FindSet() then
            repeat
                AllocateEvaluationFolderName(AITLogEntry);
            until AITLogEntry.Next() = 0;

        AITLogEntry.SetView(OriginalView);
    end;

    local procedure AllocateEvaluationFolderName(AITLogEntry: Record "AIT Log Entry")
    var
        DatasetIdentity: Text;
        FullFolderName: Text;
        FolderName: Text;
        AbbreviationKey: Text;
        Suffix: Text;
        SuffixNumber: Integer;
        Allocated: Boolean;
    begin
        DatasetIdentity := GetDatasetIdentity(AITLogEntry);
        if EvaluationFolderNames.ContainsKey(DatasetIdentity) then
            exit;

        FullFolderName := GetFullEvaluationFolderName(AITLogEntry);
        if AllocatedFolderNames.Get(FullFolderName.ToUpper(), Allocated) then
            if not Allocated then begin
                AllocatedFolderNames.Set(FullFolderName.ToUpper(), true);
                EvaluationFolderNames.Add(DatasetIdentity, FullFolderName);
                exit;
            end;

        FolderName := AbbreviateFolderName(FullFolderName, MaximumFolderNameLength);
        AbbreviationKey := FolderName.ToUpper();
        if not FolderNameSuffixes.Get(AbbreviationKey, SuffixNumber) then
            SuffixNumber := 1;
        while AllocatedFolderNames.ContainsKey(FolderName.ToUpper()) do begin
            SuffixNumber += 1;
            Suffix := '-' + Format(SuffixNumber, 0, 9);
            FolderName := AbbreviateFolderName(FullFolderName, MaximumFolderNameLength - StrLen(Suffix)) + Suffix;
        end;

        if FolderNameSuffixes.ContainsKey(AbbreviationKey) then
            FolderNameSuffixes.Set(AbbreviationKey, SuffixNumber)
        else
            FolderNameSuffixes.Add(AbbreviationKey, SuffixNumber);
        AllocatedFolderNames.Add(FolderName.ToUpper(), true);
        EvaluationFolderNames.Add(DatasetIdentity, FolderName);
    end;

    local procedure AbbreviateFolderName(FolderName: Text; MaximumLength: Integer): Text
    var
        LastCharacter: Char;
    begin
        FolderName := CopyStr(FolderName, 1, MaximumLength);
        if FolderName.EndsWith('%') then
            FolderName := CopyStr(FolderName, 1, StrLen(FolderName) - 1)
        else
            if (StrLen(FolderName) > 1) and (FolderName[StrLen(FolderName) - 1] = '%') then
                FolderName := CopyStr(FolderName, 1, StrLen(FolderName) - 2);

        LastCharacter := FolderName[StrLen(FolderName)];
        if (LastCharacter >= 55296) and (LastCharacter <= 56319) then
            FolderName := CopyStr(FolderName, 1, StrLen(FolderName) - 1);
        exit(FolderName);
    end;

    local procedure GetDatasetIdentity(AITLogEntry: Record "AIT Log Entry"): Text
    var
        DatasetIdentity: JsonArray;
        IdentityText: Text;
    begin
        DatasetIdentity.Add(AITLogEntry."Test Input Group Code");
        DatasetIdentity.Add(AITLogEntry."Test Input Code");
        DatasetIdentity.WriteTo(IdentityText);
        exit(IdentityText);
    end;

    local procedure GetFullEvaluationFolderName(AITLogEntry: Record "AIT Log Entry"): Text
    var
        DatasetGroupCode: Text;
    begin
        DatasetGroupCode := RemoveDatasetFileExtension(AITLogEntry."Test Input Group Code");
        exit(
            StrSubstNo(
                EvaluationFolderNameTxt,
                GetSafePathSegment(DatasetGroupCode, DatasetFallbackTxt),
                GetSafePathSegment(AITLogEntry."Test Input Code", InputFallbackTxt)));
    end;

    local procedure GetAgentTaskDetailsRelativePath(AgentTaskID: BigInteger): Text
    begin
        exit(StrSubstNo(AgentTaskDetailsRelativePathTxt, AgentTaskID));
    end;

    local procedure GetEvaluationResultRelativePath(AITLogEntry: Record "AIT Log Entry"): Text
    begin
        exit(StrSubstNo(EvaluationResultRelativePathTxt, GetEvaluationFolderName(AITLogEntry), AITLogEntry."Entry No."));
    end;

    local procedure RemoveDatasetFileExtension(DatasetGroupCode: Text): Text
    var
        LowerCaseDatasetGroupCode: Text;
    begin
        LowerCaseDatasetGroupCode := DatasetGroupCode.ToLower();
        if LowerCaseDatasetGroupCode.EndsWith(YamlExtensionTxt) then
            exit(DatasetGroupCode.Substring(1, StrLen(DatasetGroupCode) - StrLen(YamlExtensionTxt)));
        if LowerCaseDatasetGroupCode.EndsWith(YmlExtensionTxt) then
            exit(DatasetGroupCode.Substring(1, StrLen(DatasetGroupCode) - StrLen(YmlExtensionTxt)));
        if LowerCaseDatasetGroupCode.EndsWith(JsonlExtensionTxt) then
            exit(DatasetGroupCode.Substring(1, StrLen(DatasetGroupCode) - StrLen(JsonlExtensionTxt)));
        if LowerCaseDatasetGroupCode.EndsWith(JsonExtensionTxt) then
            exit(DatasetGroupCode.Substring(1, StrLen(DatasetGroupCode) - StrLen(JsonExtensionTxt)));
        exit(DatasetGroupCode);
    end;

    local procedure GetSafePathSegment(Value: Text; FallbackValue: Text): Text
    var
        SafeValue: Text;
    begin
        SafeValue := Value.Trim()
            .Replace('%', '%25')
            .Replace('<', '%3C')
            .Replace('>', '%3E')
            .Replace(':', '%3A')
            .Replace('"', '%22')
            .Replace('/', '%2F')
            .Replace('\', '%5C')
            .Replace('|', '%7C')
            .Replace('?', '%3F')
            .Replace('*', '%2A')
            .Replace('.', '%2E');

        if (SafeValue = '') or (SafeValue = '.') or (SafeValue = '..') then
            exit(FallbackValue);
        if IsWindowsReservedPathSegment(SafeValue) then
            exit('%00' + SafeValue);
        exit(SafeValue);
    end;

    local procedure IsWindowsReservedPathSegment(Value: Text): Boolean
    begin
        case Value.ToUpper() of
            'CON', 'PRN', 'AUX', 'NUL',
            'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
            'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9':
                exit(true);
        end;
    end;

    local procedure AddTextAsJson(var Target: JsonObject; PropertyName: Text; Value: Text)
    var
        ValueToken: JsonToken;
    begin
        if (Value <> '') and ValueToken.ReadFrom(Value) then
            Target.Add(PropertyName, ValueToken)
        else
            Target.Add(PropertyName, Value);
    end;

    local procedure GetStatus(AITLogEntry: Record "AIT Log Entry"): Text
    begin
        case AITLogEntry.Status of
            AITLogEntry.Status::Success:
                exit(SuccessTxt);
            AITLogEntry.Status::Error:
                exit(ErrorTxt);
            AITLogEntry.Status::Skipped:
                exit(SkippedTxt);
        end;
    end;

    var
        EvaluationFolderNames: Dictionary of [Text, Text];
        AllocatedFolderNames: Dictionary of [Text, Boolean];
        FolderNameSuffixes: Dictionary of [Text, Integer];
        MaximumFolderNameLength: Integer;
        AccuracyTok: Label 'accuracy', Locked = true;
        AgentTaskCountTok: Label 'agentTaskCount', Locked = true;
        AgentTaskDetailsTok: Label 'agentTaskDetails', Locked = true;
        AgentTaskIDTok: Label 'agentTaskId', Locked = true;
        AIEvalLogIDTok: Label 'aiEvalLogId', Locked = true;
        AnalysisGuidanceTok: Label 'analysisGuidance', Locked = true;
        CodeunitIDTok: Label 'codeunitId', Locked = true;
        CodeunitNameTok: Label 'codeunitName', Locked = true;
        CopilotCreditsTok: Label 'copilotCredits', Locked = true;
        DatasetTok: Label 'dataset', Locked = true;
        DatasetGroupCodeTok: Label 'datasetGroupCode', Locked = true;
        DescriptionTok: Label 'description', Locked = true;
        DurationMsTok: Label 'durationMs', Locked = true;
        EndTimeTok: Label 'endTime', Locked = true;
        ErrorCallStackTok: Label 'errorCallStack', Locked = true;
        ErrorTok: Label 'error', Locked = true;
        EvaluationsTok: Label 'evaluations', Locked = true;
        ExportStatusTok: Label 'exportStatus', Locked = true;
        ExportStatusFileTok: Label 'exportStatusFile', Locked = true;
        GroupCodeTok: Label 'groupCode', Locked = true;
        InputCodeTok: Label 'inputCode', Locked = true;
        InputTok: Label 'input', Locked = true;
        LastModifiedDateTimeTok: Label 'lastModifiedDateTime', Locked = true;
        MessageTok: Label 'message', Locked = true;
        MethodLineTok: Label 'methodLine', Locked = true;
        MethodLineDescriptionTok: Label 'methodLineDescription', Locked = true;
        OperationTok: Label 'operation', Locked = true;
        OutputTok: Label 'output', Locked = true;
        PathTok: Label 'path', Locked = true;
        ProcedureTok: Label 'procedure', Locked = true;
        ResultTok: Label 'result', Locked = true;
        RunIDTok: Label 'runId', Locked = true;
        SensitiveTok: Label 'sensitive', Locked = true;
        StartTimeTok: Label 'startTime', Locked = true;
        StatusTok: Label 'status', Locked = true;
        SuiteTok: Label 'suite', Locked = true;
        SuiteDescriptionTok: Label 'suiteDescription', Locked = true;
        SystemIDTok: Label 'systemId', Locked = true;
        TagTok: Label 'tag', Locked = true;
        TestInputCodeTok: Label 'testInputCode', Locked = true;
        TokensConsumedTok: Label 'tokensConsumed', Locked = true;
        TurnsPassedTok: Label 'turnsPassed', Locked = true;
        TurnsTok: Label 'turns', Locked = true;
        VersionTok: Label 'version', Locked = true;
        AnalysisGuidanceTxt: Label 'Check exportStatusFile for export completeness before analysis. Analyze each evaluation result first. Open agentTaskDetails only for failures, uncertainty, or deeper causal analysis.', Locked = true;
        ExportStatusFileTxt: Label 'export-status.json', Locked = true;
        FailedTxt: Label 'Failed', Locked = true;
        FolderNamesNotInitializedErr: Label 'Generate the run results before exporting evaluation file paths so that dataset folder names are initialized.';
        SuccessTxt: Label 'Success', Locked = true;
        ErrorTxt: Label 'Error', Locked = true;
        SkippedTxt: Label 'Skipped', Locked = true;
        SuiteFallbackTxt: Label 'suite', Locked = true;
        DatasetFallbackTxt: Label 'no-dataset', Locked = true;
        InputFallbackTxt: Label 'no-input', Locked = true;
        RunFolderPathTxt: Label '%1\version-%2', Locked = true;
        RunResultsPathTxt: Label '%1\version-%2\results.json', Locked = true;
        EvaluationFolderNameTxt: Label '%1-%2', Locked = true;
        EvaluationResultPathTxt: Label '%1\%2\evaluation-result-%3.json', Locked = true;
        EvaluationResultRelativePathTxt: Label '%1/evaluation-result-%2.json', Locked = true;
        AgentTaskDetailsPathTxt: Label '%1\%2\agent-task-details\task-%3.json', Locked = true;
        AgentTaskDetailsRelativePathTxt: Label 'agent-task-details/task-%1.json', Locked = true;
        YamlExtensionTxt: Label '.yaml', Locked = true;
        YmlExtensionTxt: Label '.yml', Locked = true;
        JsonlExtensionTxt: Label '.jsonl', Locked = true;
        JsonExtensionTxt: Label '.json', Locked = true;
}
