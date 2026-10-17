// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit.Tests;

using System.Globalization;
using System.TestLibraries.Utilities;
using System.TestTools.AITestToolkit;

codeunit 149052 "AIT Run Data Export Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure OrdinaryPathsRemainUnchanged()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
    begin
        InsertTempLogEntry(TempAITLogEntry, 1, 'DATASET.YAML', 'INPUT');

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        Assert.AreEqual('EXPORT\version-7\results.json', AITRunDataExport.GetResultsFilePath('EXPORT', 7), 'Ordinary summary path changed.');
        Assert.AreEqual('DATASET-INPUT', GetFolderName(AITRunDataExport, TempAITLogEntry), 'Ordinary dataset folder changed.');
        Assert.AreEqual('export-status.json', GetText(Summary, 'exportStatusFile'), 'Summary must reference the export completeness report.');
        Assert.AreEqual('EXPORT', GetText(Summary, 'suite'), 'Summary suite changed.');
        Assert.AreEqual(7, GetInteger(Summary, 'version'), 'Summary version changed.');
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure ExtensionRemovalPreservesOriginalDatasetIDs()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
        Evaluation: JsonObject;
        Dataset: JsonObject;
        Extensions: List of [Text];
        Extension: Text;
        Index: Integer;
    begin
        Extensions.Add('.yaml');
        Extensions.Add('.yml');
        Extensions.Add('.jsonl');
        Extensions.Add('.json');
        foreach Extension in Extensions do begin
            Index += 1;
            InsertTempLogEntry(TempAITLogEntry, Index, 'DATASET' + Extension, 'INPUT' + Format(Index, 0, 9));
        end;
        InsertTempLogEntry(TempAITLogEntry, 5, 'DATASET.TXT', 'INPUT5');

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        for Index := 1 to 5 do begin
            GetTempLogEntry(TempAITLogEntry, Index);
            if Index < 5 then
                Assert.AreEqual('DATASET-INPUT' + Format(Index, 0, 9), GetFolderName(AITRunDataExport, TempAITLogEntry), 'Only the dataset file extension should be removed.')
            else
                Assert.AreEqual('DATASET%2ETXT-INPUT5', GetFolderName(AITRunDataExport, TempAITLogEntry), 'Unrecognized extensions must remain escaped in folder names.');
            Clear(Evaluation);
            Assert.IsTrue(Evaluation.ReadFrom(AITRunDataExport.GetEvaluationResult(TempAITLogEntry)), 'Evaluation must be valid JSON.');
            Dataset := GetObject(Evaluation, 'dataset');
            Assert.AreEqual(TempAITLogEntry."Test Input Group Code", GetText(Dataset, 'groupCode'), 'Evaluation must retain the original dataset group including its extension.');
            Assert.AreEqual(TempAITLogEntry."Test Input Code", GetText(Dataset, 'inputCode'), 'Evaluation must retain the original input code.');
        end;
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure RepeatedDatasetIdentityUsesOneFolder()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
        FirstFolder: Text;
    begin
        InsertTempLogEntry(TempAITLogEntry, 1, PadStr('', 90, '%') + '.yaml', 'INPUT');
        InsertTempLogEntry(TempAITLogEntry, 2, PadStr('', 90, '%') + '.yaml', 'OTHER');
        InsertTempLogEntry(TempAITLogEntry, 3, PadStr('', 90, '%') + '.yaml', 'INPUT');

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        GetTempLogEntry(TempAITLogEntry, 1);
        FirstFolder := GetFolderName(AITRunDataExport, TempAITLogEntry);
        GetTempLogEntry(TempAITLogEntry, 3);
        Assert.AreEqual(FirstFolder, GetFolderName(AITRunDataExport, TempAITLogEntry), 'Repeated dataset identities must share a folder without consuming another suffix.');
        GetTempLogEntry(TempAITLogEntry, 2);
        Assert.AreNotEqual(FirstFolder, GetFolderName(AITRunDataExport, TempAITLogEntry), 'Distinct dataset identities must not share a folder.');
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure HyphenAmbiguityDoesNotMergeDatasetIdentities()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
    begin
        InsertTempLogEntry(TempAITLogEntry, 1, 'A-B', 'C');
        InsertTempLogEntry(TempAITLogEntry, 2, 'A', 'B-C');
        InsertTempLogEntry(TempAITLogEntry, 3, 'A-B', 'C');

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        AssertFolder(AITRunDataExport, TempAITLogEntry, 1, 'A-B-C');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 2, 'A-B-C-2');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 3, 'A-B-C');
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure ExtensionAmbiguityDoesNotMergeDatasetIdentities()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
    begin
        InsertTempLogEntry(TempAITLogEntry, 1, 'DATASET.YAML', 'INPUT');
        InsertTempLogEntry(TempAITLogEntry, 2, 'DATASET.JSON', 'INPUT');
        InsertTempLogEntry(TempAITLogEntry, 3, 'DATASET', 'INPUT');

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        AssertFolder(AITRunDataExport, TempAITLogEntry, 1, 'DATASET-INPUT');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 2, 'DATASET-INPUT-2');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 3, 'DATASET-INPUT-3');
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure PercentExpandedFoldersAreBoundedUniqueAndConsistent()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
        GroupCode: Text;
    begin
        GroupCode := PadStr('', 90, '%') + '.yaml';
        InsertTempLogEntry(TempAITLogEntry, 1, GroupCode, 'FIRST');
        InsertTempLogEntry(TempAITLogEntry, 2, GroupCode, 'SECOND');
        InsertTempLogEntry(TempAITLogEntry, 3, GroupCode, 'THIRD');

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        AssertFolder(AITRunDataExport, TempAITLogEntry, 1, EncodedPercents(85));
        AssertFolder(AITRunDataExport, TempAITLogEntry, 2, EncodedPercents(84) + '-2');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 3, EncodedPercents(84) + '-3');
        AssertUniqueBoundedFolders(AITRunDataExport, TempAITLogEntry, 3);
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure OrdinaryNamesAndSuffixCandidatesAreReservedFirst()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
        GroupCode: Text;
        FolderPrefix: Text;
    begin
        GroupCode := PadStr('', 80, '%') + '.yaml';
        FolderPrefix := EncodedPercents(80) + '-';
        InsertTempLogEntry(TempAITLogEntry, 1, GroupCode, 'ABCDEFGHIJKLMNOP-FIRST');
        InsertTempLogEntry(TempAITLogEntry, 2, GroupCode, 'ABCDEFGHIJKLMNOP-SECOND');
        InsertTempLogEntry(TempAITLogEntry, 3, GroupCode, 'ABCDEFGHIJKLMN');
        InsertTempLogEntry(TempAITLogEntry, 4, GroupCode, 'ABCDEFGHIJKL-2');
        InsertTempLogEntry(TempAITLogEntry, 5, GroupCode, 'ABCDEFGHIJKL-3');

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        AssertFolder(AITRunDataExport, TempAITLogEntry, 1, FolderPrefix + 'ABCDEFGHIJKL-4');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 2, FolderPrefix + 'ABCDEFGHIJKL-5');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 3, FolderPrefix + 'ABCDEFGHIJKLMN');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 4, FolderPrefix + 'ABCDEFGHIJKL-2');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 5, FolderPrefix + 'ABCDEFGHIJKL-3');
        AssertUniqueBoundedFolders(AITRunDataExport, TempAITLogEntry, 5);
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure TwoDigitSuffixesReduceThePrefixBudget()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
        GroupCode: Text;
        FolderPrefix: Text;
        Index: Integer;
    begin
        GroupCode := PadStr('', 80, '%') + '.yaml';
        FolderPrefix := EncodedPercents(80) + '-';
        for Index := 1 to 12 do
            InsertTempLogEntry(TempAITLogEntry, Index, GroupCode, 'ABCDEFGHIJKLMNOP-' + Format(Index, 0, 9));

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        AssertFolder(AITRunDataExport, TempAITLogEntry, 1, FolderPrefix + 'ABCDEFGHIJKLMN');
        for Index := 2 to 9 do
            AssertFolder(AITRunDataExport, TempAITLogEntry, Index, FolderPrefix + 'ABCDEFGHIJKL-' + Format(Index, 0, 9));
        for Index := 10 to 12 do
            AssertFolder(AITRunDataExport, TempAITLogEntry, Index, FolderPrefix + 'ABCDEFGHIJK-' + Format(Index, 0, 9));
        AssertUniqueBoundedFolders(AITRunDataExport, TempAITLogEntry, 12);
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure TruncationNeverSplitsPercentEscapes()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
    begin
        InsertTempLogEntry(TempAITLogEntry, 1, 'A' + PadStr('', 90, '%') + '.yaml', 'INPUT');
        InsertTempLogEntry(TempAITLogEntry, 2, 'AA' + PadStr('', 90, '%') + '.yaml', 'INPUT');

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        AssertFolder(AITRunDataExport, TempAITLogEntry, 1, 'A' + EncodedPercents(84));
        AssertFolder(AITRunDataExport, TempAITLogEntry, 2, 'AA' + EncodedPercents(84));
        AssertUniqueBoundedFolders(AITRunDataExport, TempAITLogEntry, 2);
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure TruncationNeverSplitsSurrogatePairs()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
        GroupCode: Text;
    begin
        GroupCode := PadStr('', 84, '%') + 'AA' + SupplementaryCharacter() + '.yaml';
        InsertTempLogEntry(TempAITLogEntry, 1, GroupCode, 'FIRST');
        GroupCode := PadStr('', 83, '%') + 'AAA' + SupplementaryCharacter() + '.yaml';
        InsertTempLogEntry(TempAITLogEntry, 2, GroupCode, 'FIRST');
        InsertTempLogEntry(TempAITLogEntry, 3, GroupCode, 'SECOND');

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        AssertFolder(AITRunDataExport, TempAITLogEntry, 1, EncodedPercents(84) + 'AA');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 2, EncodedPercents(83) + 'AAA' + SupplementaryCharacter() + '-');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 3, EncodedPercents(83) + 'AAA-2');
        AssertUniqueBoundedFolders(AITRunDataExport, TempAITLogEntry, 3);
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure FolderAllocationIsStableAcrossViewsAndRestoresTheView()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
        Paths: Dictionary of [Integer, Text];
        OriginalView: Text;
        Index: Integer;
    begin
        for Index := 1 to 3 do begin
            InsertTempLogEntry(TempAITLogEntry, Index, PadStr('', 90, '%') + '.yaml', Format(Index, 0, 9));
            TempAITLogEntry."Test Method Line No." := Index * 10000;
            TempAITLogEntry.Modify();
        end;
        InsertTempLogEntry(TempAITLogEntry, 4, PadStr('', 84, '%') + '.yaml', '2');
        TempAITLogEntry.Version := 6;
        TempAITLogEntry.Modify();
        TempAITLogEntry.SetRange("Test Suite Code", 'EXPORT');
        TempAITLogEntry.SetRange(Version, 7);
        TempAITLogEntry.SetFilter("Test Method Line No.", '10000..30000');
        TempAITLogEntry.SetCurrentKey("Entry No.");
        OriginalView := TempAITLogEntry.GetView(false);

        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);
        Assert.AreEqual(OriginalView, TempAITLogEntry.GetView(false), 'Ascending caller view must be restored.');
        RememberPaths(AITRunDataExport, TempAITLogEntry, Paths);
        Assert.AreEqual(3, Paths.Count(), 'Only the filtered run should be mapped.');

        TempAITLogEntry.SetCurrentKey("Test Suite Code", Version, "Test Method Line No.", Operation, "Procedure Name");
        TempAITLogEntry.Ascending(false);
        OriginalView := TempAITLogEntry.GetView(false);
        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        Assert.AreEqual(OriginalView, TempAITLogEntry.GetView(false), 'Caller key, direction, and filters must survive mapping initialization.');
        AssertSavedPaths(AITRunDataExport, TempAITLogEntry, Paths);
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
        AssertFolder(AITRunDataExport, TempAITLogEntry, 1, EncodedPercents(85));
        AssertFolder(AITRunDataExport, TempAITLogEntry, 2, EncodedPercents(84) + '-2');
        AssertFolder(AITRunDataExport, TempAITLogEntry, 3, EncodedPercents(84) + '-3');
    end;

    [Test]
    procedure NewSummaryReinitializesFolderReservations()
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Summary: JsonObject;
    begin
        InsertTempLogEntry(TempAITLogEntry, 1, 'A-B', 'C');
        InsertTempLogEntry(TempAITLogEntry, 2, 'A', 'B-C');
        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);
        AssertFolder(AITRunDataExport, TempAITLogEntry, 2, 'A-B-C-2');

        TempAITLogEntry.SetRange("Entry No.", TempAITLogEntry."Entry No.");
        ReadSummary(AITRunDataExport, TempAITLogEntry, Summary);

        AssertFolder(AITRunDataExport, TempAITLogEntry, 2, 'A-B-C');
        AssertAllReferences(AITRunDataExport, TempAITLogEntry, Summary);
    end;

    [Test]
    procedure TaskExportErrorIsAnExplicitEscapedJsonEnvelope()
    var
        AITRunDataExport: Codeunit "AIT Run Data Export";
        ExportError: JsonObject;
        Token: JsonToken;
        AgentTaskID: BigInteger;
        ErrorText: Text;
    begin
        Evaluate(AgentTaskID, '9007199254740993');
        ErrorText := '  Denied "task": C:\folder\file' + LineBreak(true) + LineBreak(false) + 'cause ' + UnicodeText() + '  ';

        Assert.IsTrue(ExportError.ReadFrom(AITRunDataExport.GetAgentTaskExportError(AgentTaskID, ErrorText)), 'Error envelope must be valid JSON, including quotes, backslashes, line breaks, and Unicode.');

        Assert.AreEqual(3, ExportError.Keys().Count(), 'Failure envelope must contain only task identity, export status, and error.');
        Assert.IsTrue(ExportError.Get('agentTaskId', Token), 'Failure envelope must identify the task.');
        Assert.AreEqual(AgentTaskID, Token.AsValue().AsBigInteger(), 'Task identity must not be truncated to an Integer or floating point value.');
        Assert.AreEqual('Failed', GetText(ExportError, 'exportStatus'), 'Task export failure must be unmistakable.');
        AssertExactText(ErrorText, GetText(ExportError, 'error'), 'Error envelope changed the failure message.');
        Assert.IsFalse(ExportError.Contains('taskContext'), 'Failure must not masquerade as successful task context.');
        Assert.IsFalse(ExportError.Contains('logEntries'), 'Failure must not masquerade as successful task logs.');
    end;

    [Test]
    procedure EmptyMessageAndStackRoundTripExactly()
    begin
        AssertBlobRoundTrip('');
    end;

    [Test]
    procedure PlainMessageAndStackRoundTripExactly()
    begin
        AssertBlobRoundTrip('A single-line result with "quotes" and C:\source\file.al.');
    end;

    [Test]
    procedure CRLFMessageAndStackRoundTripExactly()
    begin
        AssertBlobRoundTrip('first line' + LineBreak(true) + 'second line' + LineBreak(true) + 'third line');
    end;

    [Test]
    procedure LFMessageAndStackRoundTripExactly()
    begin
        AssertBlobRoundTrip('first line' + LineBreak(false) + 'second line' + LineBreak(false) + 'third line');
    end;

    [Test]
    procedure WhitespaceAndBlankLinesRoundTripExactly()
    begin
        AssertBlobRoundTrip('  plain text  ');
        AssertBlobRoundTrip(LineBreak(true) + LineBreak(false) + '  first line  ' + LineBreak(true) + LineBreak(true) + '  last line  ' + LineBreak(false) + LineBreak(true));
    end;

    [Test]
    procedure UnicodeMessageAndStackRoundTripExactly()
    begin
        AssertBlobRoundTrip(UnicodeText() + LineBreak(true) + '  ' + SupplementaryCharacter() + LineBreak(false));
    end;

    [Test]
    procedure LongMultilineMessageAndStackRoundTripExactly()
    var
        Content: TextBuilder;
        Index: Integer;
    begin
        for Index := 1 to 200 do
            Content.Append(Format(Index, 0, 9) + ' ' + PadStr('', 300, 'x') + LineBreak(true) + UnicodeText() + LineBreak(false));
        AssertBlobRoundTrip(Content.ToText());
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageExportsAllEvaluationsBeforeTaskDetails()
    var
        AITTestSuite: Record "AIT Test Suite";
        FirstAITLogEntry: Record "AIT Log Entry";
        SecondAITLogEntry: Record "AIT Log Entry";
        AITCommandLineCard: TestPage "AIT CommandLine Card";
        Summary: JsonObject;
        Evaluation: JsonObject;
        Paths: Dictionary of [Integer, Text];
        RunFolder: Text;
        ExpectedPath: Text;
    begin
        CreateSuite(AITTestSuite);
        InsertSuiteLine(AITTestSuite.Code, 10000);
        InsertSuiteLine(AITTestSuite.Code, 20000);
        InsertPageLogEntry(FirstAITLogEntry, AITTestSuite.Code, 20000, 7, PadStr('', 90, '%') + '.yaml', 'FIRST');
        InsertPageLogEntry(SecondAITLogEntry, AITTestSuite.Code, 10000, 7, PadStr('', 90, '%') + '.yaml', 'SECOND');
        InsertTaskAssociation(FirstAITLogEntry);
        InsertTaskAssociation(SecondAITLogEntry);
        OpenExportPage(AITCommandLineCard, AITTestSuite.Code);

        LoadPageSummary(AITCommandLineCard, Summary, Paths);

        Assert.AreEqual(2, Paths.Count(), 'Summary must include both evaluations.');
        RunFolder := AITTestSuite.Code + '\version-7\';
        Paths.Get(FirstAITLogEntry."Entry No.", ExpectedPath);
        Assert.AreEqual(EncodedPercents(85) + '/evaluation-result-' + Format(FirstAITLogEntry."Entry No.", 0, 9) + '.json', ExpectedPath, 'Allocation must follow entry number rather than page line ordering.');
        Paths.Get(SecondAITLogEntry."Entry No.", ExpectedPath);
        Assert.AreEqual(EncodedPercents(84) + '-2/evaluation-result-' + Format(SecondAITLogEntry."Entry No.", 0, 9) + '.json', ExpectedPath, 'Page must retain the collision map built by its summary action.');
        AssertSummaryTaskCounts(Summary, 1);

        LoadPageEvaluation(AITCommandLineCard, SecondAITLogEntry, RunFolder, Paths, Evaluation);
        AssertEvaluationTaskReference(Evaluation);
        LoadPageEvaluation(AITCommandLineCard, FirstAITLogEntry, RunFolder, Paths, Evaluation);
        AssertEvaluationTaskReference(Evaluation);

        // Stop before task serialization: Agent feature availability is not a prerequisite for evaluation export.
        AITCommandLineCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageExportsSharedTaskOncePerDatasetAndResetsDeduplication()
    var
        AITTestSuite: Record "AIT Test Suite";
        FirstAITLogEntry: Record "AIT Log Entry";
        RepeatedAITLogEntry: Record "AIT Log Entry";
        OtherDatasetAITLogEntry: Record "AIT Log Entry";
        AITCommandLineCard: TestPage "AIT CommandLine Card";
        Summary: JsonObject;
        Evaluation: JsonObject;
        Paths: Dictionary of [Integer, Text];
        RunFolder: Text;
        SharedTaskPath: Text;
        OtherDatasetTaskPath: Text;
        ExportPass: Integer;
    begin
        CreateSuite(AITTestSuite);
        InsertSuiteLine(AITTestSuite.Code, 10000);
        InsertSuiteLine(AITTestSuite.Code, 20000);
        InsertSuiteLine(AITTestSuite.Code, 30000);
        InsertPageLogEntry(FirstAITLogEntry, AITTestSuite.Code, 10000, 7, PadStr('', 90, '%') + '.yaml', 'SHARED');
        InsertPageLogEntry(RepeatedAITLogEntry, AITTestSuite.Code, 20000, 7, PadStr('', 90, '%') + '.yaml', 'SHARED');
        InsertPageLogEntry(OtherDatasetAITLogEntry, AITTestSuite.Code, 30000, 7, PadStr('', 90, '%') + '.yaml', 'OTHER');
        InsertTaskAssociation(FirstAITLogEntry);
        InsertTaskAssociation(RepeatedAITLogEntry);
        InsertTaskAssociation(OtherDatasetAITLogEntry);
        OpenExportPage(AITCommandLineCard, AITTestSuite.Code);
        RunFolder := AITTestSuite.Code + '\version-7\';

        for ExportPass := 1 to 2 do begin
            if ExportPass = 2 then begin
                AITCommandLineCard.ResetTestSuite.Invoke();
                AssertPageExportCleared(AITCommandLineCard);
            end;
            LoadPageSummary(AITCommandLineCard, Summary, Paths);
            Assert.AreEqual(3, Paths.Count(), 'Task deduplication must not remove evaluations.');
            AssertSummaryTaskCounts(Summary, 1);
            LoadPageEvaluation(AITCommandLineCard, FirstAITLogEntry, RunFolder, Paths, Evaluation);
            AssertEvaluationTaskReference(Evaluation);
            LoadPageEvaluation(AITCommandLineCard, RepeatedAITLogEntry, RunFolder, Paths, Evaluation);
            AssertEvaluationTaskReference(Evaluation);
            LoadPageEvaluation(AITCommandLineCard, OtherDatasetAITLogEntry, RunFolder, Paths, Evaluation);
            AssertEvaluationTaskReference(Evaluation);

            SharedTaskPath := GetPageTaskPath(FirstAITLogEntry."Entry No.", RunFolder, Paths);
            Assert.AreEqual(SharedTaskPath, GetPageTaskPath(RepeatedAITLogEntry."Entry No.", RunFolder, Paths), 'Repeated dataset identity must reference the same task file.');
            OtherDatasetTaskPath := GetPageTaskPath(OtherDatasetAITLogEntry."Entry No.", RunFolder, Paths);
            Assert.AreNotEqual(SharedTaskPath, OtherDatasetTaskPath, 'The same task ID in a different dataset must have a separate file.');

            LoadPageTaskDetails(AITCommandLineCard, SharedTaskPath);
            LoadPageTaskDetails(AITCommandLineCard, OtherDatasetTaskPath);
            AssertPageCompleted(AITCommandLineCard);
            AssertPageCompleted(AITCommandLineCard);
        end;

        AITCommandLineCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageKeepsVersionAndLineFiltersUntilReset()
    var
        AITTestSuite: Record "AIT Test Suite";
        AITLogEntry: Record "AIT Log Entry";
        SelectedAITLogEntry: Record "AIT Log Entry";
        NewAITLogEntry: Record "AIT Log Entry";
        AITCommandLineCard: TestPage "AIT CommandLine Card";
        Summary: JsonObject;
        Evaluation: JsonObject;
        Paths: Dictionary of [Integer, Text];
    begin
        CreateSuite(AITTestSuite);
        InsertSuiteLine(AITTestSuite.Code, 10000);
        InsertSuiteLine(AITTestSuite.Code, 20000);
        InsertPageLogEntry(AITLogEntry, AITTestSuite.Code, 10000, 1, 'OLD', 'INPUT');
        InsertPageLogEntry(SelectedAITLogEntry, AITTestSuite.Code, 10000, 2, 'SELECTED', 'INPUT');
        InsertPageLogEntry(AITLogEntry, AITTestSuite.Code, 20000, 2, 'OTHER-LINE', 'INPUT');
        OpenExportPage(AITCommandLineCard, AITTestSuite.Code);
        AITCommandLineCard."Line No. Filter".SetValue(10000);

        LoadPageSummary(AITCommandLineCard, Summary, Paths);
        Assert.AreEqual(2, GetInteger(Summary, 'version'), 'Export must use the latest logged version.');
        Assert.AreEqual(1, Paths.Count(), 'Summary must honor the selected line.');
        Assert.IsTrue(Paths.ContainsKey(SelectedAITLogEntry."Entry No."), 'Summary included an old version or the wrong line.');
        InsertPageLogEntry(NewAITLogEntry, AITTestSuite.Code, 10000, 3, 'NEW', 'INPUT');
        InsertPageLogEntry(AITLogEntry, AITTestSuite.Code, 20000, 3, 'NEW-OTHER-LINE', 'INPUT');

        LoadPageEvaluation(AITCommandLineCard, SelectedAITLogEntry, AITTestSuite.Code + '\version-2\', Paths, Evaluation);
        AssertPageCompleted(AITCommandLineCard);
        AssertPageCompleted(AITCommandLineCard);
        AITCommandLineCard.ResetTestSuite.Invoke();
        AssertPageExportCleared(AITCommandLineCard);
        LoadPageSummary(AITCommandLineCard, Summary, Paths);

        Assert.AreEqual(3, GetInteger(Summary, 'version'), 'Reset must choose the new latest version.');
        Assert.AreEqual(1, Paths.Count(), 'Reset must preserve the selected line filter.');
        Assert.IsTrue(Paths.ContainsKey(NewAITLogEntry."Entry No."), 'Reset reused the previous export cursor.');
        LoadPageEvaluation(AITCommandLineCard, NewAITLogEntry, AITTestSuite.Code + '\version-3\', Paths, Evaluation);
        AssertPageCompleted(AITCommandLineCard);
        AITCommandLineCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageSuiteAndLineValidationRestartExport()
    var
        FirstAITTestSuite: Record "AIT Test Suite";
        SecondAITTestSuite: Record "AIT Test Suite";
        FirstAITLogEntry: Record "AIT Log Entry";
        SecondAITLogEntry: Record "AIT Log Entry";
        OtherSuiteAITLogEntry: Record "AIT Log Entry";
        AITCommandLineCard: TestPage "AIT CommandLine Card";
        Summary: JsonObject;
        Paths: Dictionary of [Integer, Text];
    begin
        CreateSuite(FirstAITTestSuite);
        CreateSuite(SecondAITTestSuite);
        InsertSuiteLine(FirstAITTestSuite.Code, 10000);
        InsertSuiteLine(FirstAITTestSuite.Code, 20000);
        InsertSuiteLine(SecondAITTestSuite.Code, 30000);
        InsertPageLogEntry(FirstAITLogEntry, FirstAITTestSuite.Code, 10000, 2, 'FIRST', 'INPUT');
        InsertPageLogEntry(SecondAITLogEntry, FirstAITTestSuite.Code, 20000, 2, 'SECOND', 'INPUT');
        InsertPageLogEntry(OtherSuiteAITLogEntry, SecondAITTestSuite.Code, 30000, 4, 'OTHER', 'INPUT');
        OpenExportPage(AITCommandLineCard, FirstAITTestSuite.Code);
        AITCommandLineCard."Line No. Filter".SetValue(10000);
        LoadPageSummary(AITCommandLineCard, Summary, Paths);
        Assert.AreEqual(1, Paths.Count(), 'Initial line filter was ignored.');
        Assert.IsTrue(Paths.ContainsKey(FirstAITLogEntry."Entry No."), 'Initial export selected the wrong line.');

        AITCommandLineCard."Line No. Filter".SetValue(20000);
        AssertPageExportCleared(AITCommandLineCard);
        LoadPageSummary(AITCommandLineCard, Summary, Paths);
        Assert.AreEqual(1, Paths.Count(), 'Changing the line must start a filtered summary.');
        Assert.IsTrue(Paths.ContainsKey(SecondAITLogEntry."Entry No."), 'Changing the line reused a prior cursor.');

        AITCommandLineCard."AIT Suite Code".SetValue(SecondAITTestSuite.Code);
        AssertPageExportCleared(AITCommandLineCard);
        LoadPageSummary(AITCommandLineCard, Summary, Paths);
        Assert.AreEqual(SecondAITTestSuite.Code, GetText(Summary, 'suite'), 'Changing the suite must discard the previous export.');
        Assert.AreEqual(4, GetInteger(Summary, 'version'), 'Changing the suite must recompute its latest version.');
        Assert.AreEqual(1, Paths.Count(), 'Changing the suite must clear the previous line filter.');
        Assert.IsTrue(Paths.ContainsKey(OtherSuiteAITLogEntry."Entry No."), 'Changing the suite reused the old suite or line.');
        AITCommandLineCard.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure PageLanguageValidationRestartsCompletedExport()
    var
        AITTestSuite: Record "AIT Test Suite";
        AITTestSuiteLanguage: Record "AIT Test Suite Language";
        WindowsLanguage: Record "Windows Language";
        FirstAITLogEntry: Record "AIT Log Entry";
        SecondAITLogEntry: Record "AIT Log Entry";
        AITCommandLineCard: TestPage "AIT CommandLine Card";
        Summary: JsonObject;
        Evaluation: JsonObject;
        Paths: Dictionary of [Integer, Text];
    begin
        CreateSuite(AITTestSuite);
        InsertSuiteLine(AITTestSuite.Code, 10000);
        InsertSuiteLine(AITTestSuite.Code, 20000);
        InsertPageLogEntry(FirstAITLogEntry, AITTestSuite.Code, 10000, 2, 'FIRST', 'INPUT');
        InsertPageLogEntry(SecondAITLogEntry, AITTestSuite.Code, 20000, 2, 'SECOND', 'INPUT');
        WindowsLanguage.Get(1033);
        AITTestSuiteLanguage."Test Suite Code" := AITTestSuite.Code;
        AITTestSuiteLanguage."Language ID" := WindowsLanguage."Language ID";
        AITTestSuiteLanguage.Insert();
        OpenExportPage(AITCommandLineCard, AITTestSuite.Code);
        AITCommandLineCard."Line No. Filter".SetValue(10000);
        LoadPageSummary(AITCommandLineCard, Summary, Paths);
        LoadPageEvaluation(AITCommandLineCard, FirstAITLogEntry, AITTestSuite.Code + '\version-2\', Paths, Evaluation);
        AssertPageCompleted(AITCommandLineCard);

        AITCommandLineCard."Language Tag".SetValue(WindowsLanguage."Language Tag");

        AssertPageExportCleared(AITCommandLineCard);
        AITTestSuite.Get(AITTestSuite.Code);
        Assert.AreEqual(1033, AITTestSuite."Run Language ID", 'Language validation must still update the suite.');
        LoadPageSummary(AITCommandLineCard, Summary, Paths);
        Assert.AreEqual(2, Paths.Count(), 'Language validation must clear the line filter and restart a completed export.');
        Assert.IsTrue(Paths.ContainsKey(FirstAITLogEntry."Entry No."), 'Restart omitted the first evaluation.');
        Assert.IsTrue(Paths.ContainsKey(SecondAITLogEntry."Entry No."), 'Restart retained the previous line filter.');
        LoadPageEvaluation(AITCommandLineCard, FirstAITLogEntry, AITTestSuite.Code + '\version-2\', Paths, Evaluation);
        LoadPageEvaluation(AITCommandLineCard, SecondAITLogEntry, AITTestSuite.Code + '\version-2\', Paths, Evaluation);
        AssertPageCompleted(AITCommandLineCard);
        AITCommandLineCard.Close();
    end;

    local procedure InsertTempLogEntry(var TempAITLogEntry: Record "AIT Log Entry" temporary; Index: Integer; GroupCode: Text; InputCode: Text)
    begin
        TempAITLogEntry.Init();
        // Negative temporary identities cannot pick up unrelated persisted Agent Task Log associations.
        TempAITLogEntry."Entry No." := -100000 + Index;
        TempAITLogEntry."Test Suite Code" := 'EXPORT';
        TempAITLogEntry."Test Method Line No." := 10000;
        TempAITLogEntry.Version := 7;
        TempAITLogEntry."Test Input Group Code" := CopyStr(GroupCode, 1, MaxStrLen(TempAITLogEntry."Test Input Group Code"));
        TempAITLogEntry."Test Input Code" := CopyStr(InputCode, 1, MaxStrLen(TempAITLogEntry."Test Input Code"));
        TempAITLogEntry.Insert();
    end;

    local procedure GetTempLogEntry(var TempAITLogEntry: Record "AIT Log Entry" temporary; Index: Integer)
    begin
        TempAITLogEntry.Get(-100000 + Index);
    end;

    local procedure ReadSummary(var AITRunDataExport: Codeunit "AIT Run Data Export"; var AITLogEntry: Record "AIT Log Entry"; var Summary: JsonObject)
    begin
        Clear(Summary);
        Assert.IsTrue(Summary.ReadFrom(AITRunDataExport.GetRunResults(AITLogEntry)), 'Summary must be valid JSON.');
    end;

    local procedure GetFolderName(var AITRunDataExport: Codeunit "AIT Run Data Export"; AITLogEntry: Record "AIT Log Entry"): Text
    var
        Segments: List of [Text];
    begin
        Segments := AITRunDataExport.GetEvaluationResultFilePath(AITLogEntry).Split('\');
        Assert.AreEqual(4, Segments.Count(), 'Evaluation path schema changed.');
        exit(Segments.Get(3));
    end;

    local procedure AssertFolder(var AITRunDataExport: Codeunit "AIT Run Data Export"; var TempAITLogEntry: Record "AIT Log Entry" temporary; Index: Integer; ExpectedFolder: Text)
    begin
        GetTempLogEntry(TempAITLogEntry, Index);
        AssertExactText(ExpectedFolder, GetFolderName(AITRunDataExport, TempAITLogEntry), 'Unexpected dataset folder.');
    end;

    local procedure AssertUniqueBoundedFolders(var AITRunDataExport: Codeunit "AIT Run Data Export"; var TempAITLogEntry: Record "AIT Log Entry" temporary; ExpectedCount: Integer)
    var
        SeenFolders: Dictionary of [Text, Boolean];
        Folder: Text;
        Index: Integer;
        Character: Char;
    begin
        TempAITLogEntry.FindSet();
        repeat
            Folder := GetFolderName(AITRunDataExport, TempAITLogEntry);
            Assert.IsTrue(StrLen(Folder) <= 255, 'A dataset folder exceeds the filesystem component limit.');
            Assert.IsFalse(SeenFolders.ContainsKey(Folder.ToUpper()), 'Distinct datasets received colliding folders.');
            SeenFolders.Add(Folder.ToUpper(), true);
            Index := 1;
            while Index <= StrLen(Folder) do begin
                Character := Folder[Index];
                if Character = '%' then begin
                    Assert.AreEqual('%25', CopyStr(Folder, Index, 3), 'Percent escape was truncated.');
                    Index += 3;
                end else
                    if (Character >= 55296) and (Character <= 56319) then begin
                        Assert.IsTrue(Index < StrLen(Folder), 'Folder ends with a high surrogate.');
                        Character := Folder[Index + 1];
                        Assert.IsTrue((Character >= 56320) and (Character <= 57343), 'High surrogate has no matching low surrogate.');
                        Index += 2;
                    end else begin
                        Assert.IsFalse((Character >= 56320) and (Character <= 57343), 'Folder contains an unpaired low surrogate.');
                        Index += 1;
                    end;
            end;
        until TempAITLogEntry.Next() = 0;
        Assert.AreEqual(ExpectedCount, SeenFolders.Count(), 'Unexpected distinct folder count.');
    end;

    local procedure AssertAllReferences(var AITRunDataExport: Codeunit "AIT Run Data Export"; var TempAITLogEntry: Record "AIT Log Entry" temporary; Summary: JsonObject)
    var
        Evaluations: JsonArray;
        Evaluation: JsonObject;
        Token: JsonToken;
        RelativePath: Text;
        RunFolder: Text;
        Folder: Text;
    begin
        Evaluations := GetArray(Summary, 'evaluations');
        Assert.AreEqual(TempAITLogEntry.Count(), Evaluations.Count(), 'Summary must contain precisely the filtered evaluations.');
        foreach Token in Evaluations do begin
            Evaluation := Token.AsObject();
            TempAITLogEntry.Get(GetInteger(Evaluation, 'aiEvalLogId'));
            Assert.AreEqual(TempAITLogEntry."Test Input Group Code", GetText(Evaluation, 'datasetGroupCode'), 'Summary must retain the original dataset group.');
            Assert.AreEqual(TempAITLogEntry."Test Input Code", GetText(Evaluation, 'testInputCode'), 'Summary must retain the original input code.');
            RelativePath := GetText(Evaluation, 'path');
            Folder := GetFolderName(AITRunDataExport, TempAITLogEntry);
            Assert.AreEqual(Folder + '/evaluation-result-' + Format(TempAITLogEntry."Entry No.", 0, 9) + '.json', RelativePath, 'Summary must use the initialized dataset folder map.');
            RunFolder := AITRunDataExport.GetResultsFilePath(TempAITLogEntry."Test Suite Code", TempAITLogEntry.Version);
            RunFolder := CopyStr(RunFolder, 1, StrLen(RunFolder) - StrLen('results.json'));
            Assert.AreEqual(RunFolder + RelativePath.Replace('/', '\'), AITRunDataExport.GetEvaluationResultFilePath(TempAITLogEntry), 'Evaluation filename must agree with its summary reference.');
            Assert.AreEqual(RunFolder + Folder + '\agent-task-details\task-42.json', AITRunDataExport.GetAgentTaskDetailsFilePath(TempAITLogEntry, 42), 'Task filename must use the same dataset folder as its evaluation.');
        end;
    end;

    local procedure RememberPaths(var AITRunDataExport: Codeunit "AIT Run Data Export"; var TempAITLogEntry: Record "AIT Log Entry" temporary; var Paths: Dictionary of [Integer, Text])
    begin
        Clear(Paths);
        TempAITLogEntry.FindSet();
        repeat
            Paths.Add(TempAITLogEntry."Entry No.", AITRunDataExport.GetEvaluationResultFilePath(TempAITLogEntry));
        until TempAITLogEntry.Next() = 0;
    end;

    local procedure AssertSavedPaths(var AITRunDataExport: Codeunit "AIT Run Data Export"; var TempAITLogEntry: Record "AIT Log Entry" temporary; Paths: Dictionary of [Integer, Text])
    var
        ExpectedPath: Text;
    begin
        TempAITLogEntry.FindSet();
        repeat
            Assert.IsTrue(Paths.Get(TempAITLogEntry."Entry No.", ExpectedPath), 'Changed view introduced another record.');
            Assert.AreEqual(ExpectedPath, AITRunDataExport.GetEvaluationResultFilePath(TempAITLogEntry), 'Changing record order changed the dataset folder allocation.');
        until TempAITLogEntry.Next() = 0;
    end;

    local procedure AssertBlobRoundTrip(ExpectedText: Text)
    var
        TempAITLogEntry: Record "AIT Log Entry" temporary;
        AITRunDataExport: Codeunit "AIT Run Data Export";
        Evaluation: JsonObject;
        Result: JsonObject;
    begin
        InsertTempLogEntry(TempAITLogEntry, 1, 'DATASET', 'INPUT');
        TempAITLogEntry.SetMessage(ExpectedText);
        TempAITLogEntry.SetErrorCallStack(ExpectedText);
        TempAITLogEntry.Modify();
        GetTempLogEntry(TempAITLogEntry, 1);

        AssertExactText(ExpectedText, TempAITLogEntry.GetMessage(), 'Message BLOB round trip changed the text.');
        AssertExactText(ExpectedText, TempAITLogEntry.GetErrorCallStack(), 'Call stack BLOB round trip changed the text.');
        Assert.IsTrue(Evaluation.ReadFrom(AITRunDataExport.GetEvaluationResult(TempAITLogEntry)), 'Evaluation must be valid JSON.');
        Result := GetObject(Evaluation, 'result');
        AssertExactText(ExpectedText, GetText(Result, 'message'), 'Evaluation JSON changed the message.');
        AssertExactText(ExpectedText, GetText(Result, 'errorCallStack'), 'Evaluation JSON changed the call stack.');
    end;

    local procedure AssertExactText(ExpectedText: Text; ActualText: Text; FailureMessage: Text)
    var
        ExpectedCharacter: Integer;
        ActualCharacter: Integer;
        Index: Integer;
    begin
        Assert.AreEqual(StrLen(ExpectedText), StrLen(ActualText), FailureMessage + ' Length differs.');
        for Index := 1 to StrLen(ExpectedText) do begin
            ExpectedCharacter := ExpectedText[Index];
            ActualCharacter := ActualText[Index];
            Assert.AreEqual(ExpectedCharacter, ActualCharacter, FailureMessage + ' UTF-16 code unit ' + Format(Index, 0, 9) + ' differs.');
        end;
    end;

    local procedure EncodedPercents(Count: Integer): Text
    begin
        exit(PadStr('', Count, '%').Replace('%', '%25'));
    end;

    local procedure LineBreak(IncludeCarriageReturn: Boolean): Text
    var
        CarriageReturn: Char;
        LineFeed: Char;
    begin
        CarriageReturn := 13;
        LineFeed := 10;
        if IncludeCarriageReturn then
            exit(Format(CarriageReturn) + Format(LineFeed));
        exit(Format(LineFeed));
    end;

    local procedure UnicodeText(): Text
    var
        LatinCharacter: Char;
        CJKCharacter: Char;
    begin
        LatinCharacter := 233;
        CJKCharacter := 28450;
        exit(Format(LatinCharacter) + Format(CJKCharacter) + SupplementaryCharacter());
    end;

    local procedure SupplementaryCharacter(): Text
    var
        HighSurrogate: Char;
        LowSurrogate: Char;
    begin
        HighSurrogate := 55357;
        LowSurrogate := 56832;
        exit(Format(HighSurrogate) + Format(LowSurrogate));
    end;

    local procedure GetText(Object: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Object.Get(PropertyName, Token), 'Missing JSON property: ' + PropertyName);
        exit(Token.AsValue().AsText());
    end;

    local procedure GetInteger(Object: JsonObject; PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Object.Get(PropertyName, Token), 'Missing JSON property: ' + PropertyName);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure GetObject(Object: JsonObject; PropertyName: Text): JsonObject
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Object.Get(PropertyName, Token), 'Missing JSON object: ' + PropertyName);
        exit(Token.AsObject());
    end;

    local procedure GetArray(Object: JsonObject; PropertyName: Text): JsonArray
    var
        Token: JsonToken;
    begin
        Assert.IsTrue(Object.Get(PropertyName, Token), 'Missing JSON array: ' + PropertyName);
        exit(Token.AsArray());
    end;

    local procedure CreateSuite(var AITTestSuite: Record "AIT Test Suite")
    begin
        AITTestSuite.Init();
        repeat
            AITTestSuite.Code := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(AITTestSuite.Code));
        until AITTestSuite.Insert();
    end;

    local procedure InsertSuiteLine(SuiteCode: Code[10]; LineNo: Integer)
    var
        AITTestMethodLine: Record "AIT Test Method Line";
    begin
        AITTestMethodLine."Test Suite Code" := SuiteCode;
        AITTestMethodLine."Line No." := LineNo;
        AITTestMethodLine.Insert();
    end;

    local procedure InsertPageLogEntry(var AITLogEntry: Record "AIT Log Entry"; SuiteCode: Code[10]; LineNo: Integer; Version: Integer; GroupCode: Text; InputCode: Text)
    begin
        AITLogEntry.Init();
        AITLogEntry."Entry No." := 0;
        AITLogEntry."Test Suite Code" := SuiteCode;
        AITLogEntry."Test Method Line No." := LineNo;
        AITLogEntry.Version := Version;
        AITLogEntry."Test Input Group Code" := CopyStr(GroupCode, 1, MaxStrLen(AITLogEntry."Test Input Group Code"));
        AITLogEntry."Test Input Code" := CopyStr(InputCode, 1, MaxStrLen(AITLogEntry."Test Input Code"));
        AITLogEntry.Insert();
    end;

    local procedure InsertTaskAssociation(AITLogEntry: Record "AIT Log Entry")
    var
        AgentTaskLog: Record "Agent Task Log";
    begin
        AgentTaskLog."Test Suite Code" := AITLogEntry."Test Suite Code";
        AgentTaskLog."Test Method Line No." := AITLogEntry."Test Method Line No.";
        AgentTaskLog.Version := AITLogEntry.Version;
        AgentTaskLog."Test Log Entry ID" := AITLogEntry."Entry No.";
        // No live Agent task is needed to verify scheduling and relative references.
        AgentTaskLog."Agent Task ID" := 0;
        AgentTaskLog.Insert();
    end;

    local procedure OpenExportPage(var AITCommandLineCard: TestPage "AIT CommandLine Card"; SuiteCode: Code[10])
    begin
        AITCommandLineCard.OpenEdit();
        AITCommandLineCard."AIT Suite Code".SetValue(SuiteCode);
    end;

    local procedure LoadPageSummary(var AITCommandLineCard: TestPage "AIT CommandLine Card"; var Summary: JsonObject; var Paths: Dictionary of [Integer, Text])
    var
        Evaluations: JsonArray;
        Evaluation: JsonObject;
        Token: JsonToken;
    begin
        AITCommandLineCard.LoadAITRunDataFile.Invoke();
        Assert.AreEqual('', AITCommandLineCard."AIT Run Data File Error".Value(), 'Summary export must not report a task error.');
        Clear(Summary);
        Clear(Paths);
        Assert.IsTrue(Summary.ReadFrom(AITCommandLineCard."AIT Run Data File".Value()), 'Page must begin with a JSON summary.');
        Assert.AreEqual('export-status.json', GetText(Summary, 'exportStatusFile'), 'Page summary must reference the completeness report.');
        Assert.AreEqual(GetText(Summary, 'suite') + '\version-' + Format(GetInteger(Summary, 'version'), 0, 9) + '\results.json', AITCommandLineCard."AIT Run Data File Path".Value(), 'Page summary path must retain suite and version.');
        Evaluations := GetArray(Summary, 'evaluations');
        foreach Token in Evaluations do begin
            Evaluation := Token.AsObject();
            Paths.Add(GetInteger(Evaluation, 'aiEvalLogId'), GetText(Evaluation, 'path'));
        end;
    end;

    local procedure LoadPageEvaluation(var AITCommandLineCard: TestPage "AIT CommandLine Card"; ExpectedAITLogEntry: Record "AIT Log Entry"; RunFolder: Text; Paths: Dictionary of [Integer, Text]; var Evaluation: JsonObject)
    var
        Dataset: JsonObject;
        ExpectedPath: Text;
    begin
        AITCommandLineCard.LoadAITRunDataFile.Invoke();
        Assert.AreEqual('', AITCommandLineCard."AIT Run Data File Error".Value(), 'Evaluation export must not attempt task serialization.');
        Assert.IsTrue(Paths.Get(ExpectedAITLogEntry."Entry No.", ExpectedPath), 'Expected evaluation was absent from the summary.');
        Assert.AreEqual(RunFolder + ExpectedPath.Replace('/', '\'), AITCommandLineCard."AIT Run Data File Path".Value(), 'Evaluation action must agree with the summary and precede task details.');
        Clear(Evaluation);
        Assert.IsTrue(Evaluation.ReadFrom(AITCommandLineCard."AIT Run Data File".Value()), 'Evaluation action must emit JSON.');
        Assert.AreEqual(ExpectedAITLogEntry."Entry No.", GetInteger(Evaluation, 'aiEvalLogId'), 'Page emitted the wrong evaluation.');
        Assert.AreEqual(ExpectedAITLogEntry.Version, GetInteger(Evaluation, 'version'), 'Page changed the selected version between actions.');
        Assert.AreEqual(ExpectedAITLogEntry."Test Method Line No.", GetInteger(Evaluation, 'methodLine'), 'Page changed the selected line between actions.');
        Assert.AreEqual(ExpectedAITLogEntry."Test Suite Code", GetText(Evaluation, 'suite'), 'Page changed the selected suite between actions.');
        Dataset := GetObject(Evaluation, 'dataset');
        AssertExactText(ExpectedAITLogEntry."Test Input Group Code", GetText(Dataset, 'groupCode'), 'Page evaluation must retain the original dataset group.');
        AssertExactText(ExpectedAITLogEntry."Test Input Code", GetText(Dataset, 'inputCode'), 'Page evaluation must retain the original input code.');
    end;

    local procedure GetPageTaskPath(LogEntryNo: Integer; RunFolder: Text; Paths: Dictionary of [Integer, Text]): Text
    var
        Segments: List of [Text];
        EvaluationPath: Text;
    begin
        Assert.IsTrue(Paths.Get(LogEntryNo, EvaluationPath), 'Task file must belong to an evaluation in the summary.');
        Segments := EvaluationPath.Split('/');
        Assert.AreEqual(2, Segments.Count(), 'Evaluation summary path must be relative to the run folder.');
        exit(RunFolder + Segments.Get(1) + '\agent-task-details\task-0.json');
    end;

    local procedure LoadPageTaskDetails(var AITCommandLineCard: TestPage "AIT CommandLine Card"; ExpectedPath: Text)
    var
        TaskDetails: JsonObject;
        FileError: Text;
    begin
        AITCommandLineCard.LoadAITRunDataFile.Invoke();
        Assert.AreEqual(ExpectedPath, AITCommandLineCard."AIT Run Data File Path".Value(), 'Export must emit each task file path once, not deduplicate by task ID alone.');
        Assert.IsTrue(TaskDetails.ReadFrom(AITCommandLineCard."AIT Run Data File".Value()), 'Task detail content must be valid JSON even if task export is denied.');
        FileError := AITCommandLineCard."AIT Run Data File Error".Value();

        // Task 0 can produce minimal context or fail the existing feature/permission checks.
        if FileError <> '' then begin
            Assert.AreEqual(3, TaskDetails.Keys().Count(), 'Task failure must use the explicit error envelope.');
            Assert.AreEqual(0, GetInteger(TaskDetails, 'agentTaskId'), 'Failure envelope must identify the attempted task.');
            Assert.AreEqual('Failed', GetText(TaskDetails, 'exportStatus'), 'Task failure must be unmistakable.');
            AssertExactText(FileError, GetText(TaskDetails, 'error'), 'Failure envelope must preserve the page error.');
            Assert.IsFalse(TaskDetails.Contains('taskContext'), 'Failure must not masquerade as successful task context.');
            Assert.IsFalse(TaskDetails.Contains('logEntries'), 'Failure must not masquerade as successful task logs.');
        end else
            Assert.IsFalse(TaskDetails.Contains('exportStatus'), 'A task failure envelope must also set the page error field.');
    end;

    local procedure AssertSummaryTaskCounts(Summary: JsonObject; ExpectedCount: Integer)
    var
        Evaluations: JsonArray;
        Token: JsonToken;
    begin
        Evaluations := GetArray(Summary, 'evaluations');
        foreach Token in Evaluations do
            Assert.AreEqual(ExpectedCount, GetInteger(Token.AsObject(), 'agentTaskCount'), 'Summary must count associated task details without exporting them.');
    end;

    local procedure AssertEvaluationTaskReference(Evaluation: JsonObject)
    var
        TaskDetails: JsonArray;
        Token: JsonToken;
    begin
        TaskDetails := GetArray(Evaluation, 'agentTaskDetails');
        Assert.AreEqual(1, TaskDetails.Count(), 'Evaluation must reference its associated task.');
        TaskDetails.Get(0, Token);
        Assert.AreEqual('agent-task-details/task-0.json', Token.AsValue().AsText(), 'Task reference must remain relative to the mapped evaluation folder.');
    end;

    local procedure AssertPageCompleted(var AITCommandLineCard: TestPage "AIT CommandLine Card")
    begin
        AITCommandLineCard.LoadAITRunDataFile.Invoke();
        Assert.AreEqual('', AITCommandLineCard."AIT Run Data File Path".Value(), 'Completed export must not retain a file path.');
        Assert.AreEqual('', AITCommandLineCard."AIT Run Data File Error".Value(), 'Completed export must not retain an error.');
        Assert.AreEqual('No more AI Eval run data files.', AITCommandLineCard."AIT Run Data File".Value(), 'Completed export must return the sentinel.');
    end;

    local procedure AssertPageExportCleared(var AITCommandLineCard: TestPage "AIT CommandLine Card")
    begin
        Assert.AreEqual('', AITCommandLineCard."AIT Run Data File Path".Value(), 'Reset must clear the previous file path.');
        Assert.AreEqual('', AITCommandLineCard."AIT Run Data File".Value(), 'Reset must clear the previous file content.');
        Assert.AreEqual('', AITCommandLineCard."AIT Run Data File Error".Value(), 'Reset must clear the previous file error.');
    end;
}
