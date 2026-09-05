// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents;

using System.Agents;
using System.Agents.Troubleshooting;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 133964 "Agent Task Log Page Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure TestFormatJsonTextForRichContent_VariousInputs()
    var
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        TestCases: List of [Text];
        TestCase: Text;
        FormattedResult: Text;
    begin
        // [GIVEN] Various JSON test cases
        TestCases.Add('{"simple":"value"}');
        TestCases.Add('{"nested":{"object":"value"}}');
        TestCases.Add('{"array":[1,2,3]}');
        TestCases.Add('{"mixed":{"type":"object","values":[1,2,3]}}');

        // [WHEN] Each test case is formatted
        foreach TestCase in TestCases do begin
            FormattedResult := AgentTaskLogEntry.FormatJsonTextForRichContent(TestCase);

            // [THEN] Each should be wrapped in pre tags and contain original data
            Assert.IsTrue(FormattedResult.StartsWith('<pre>'), 'Should start with <pre> tag');
            Assert.IsTrue(FormattedResult.EndsWith('</pre>'), 'Should end with </pre> tag');
        end;
    end;

    [Test]
    procedure TestFormatJsonTextForRichContent_EmptyString()
    var
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        FormattedResult: Text;
    begin
        // [GIVEN] An empty string
        // [WHEN] FormatJsonTextForRichContent is called
        FormattedResult := AgentTaskLogEntry.FormatJsonTextForRichContent('');

        // [THEN] Should handle empty string gracefully
        Assert.IsTrue(FormattedResult.StartsWith('<pre>'), 'Should still have pre tag');
        Assert.IsTrue(FormattedResult.EndsWith('</pre>'), 'Should still close pre tag');
    end;

    [Test]
    procedure TestFormatJsonTextForRichContent_VeryLargeJson()
    var
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        LargeJson: Text;
        FormattedResult: Text;
        i: Integer;
        KeyLbl: Label 'key%1', Locked = true;
        ValueLbl: Label 'value%1', Locked = true;
    begin
        // [GIVEN] A very large JSON string
        LargeJson := '{';
        for i := 1 to 100 do begin
            if i > 1 then
                LargeJson += ',';
            LargeJson += StrSubstNo('"%1":"%2"', StrSubstNo(KeyLbl, i), StrSubstNo(ValueLbl, i));
        end;
        LargeJson += '}';

        // [WHEN] FormatJsonTextForRichContent is called
        FormattedResult := AgentTaskLogEntry.FormatJsonTextForRichContent(LargeJson);

        // [THEN] Should handle large JSON
        Assert.IsTrue(FormattedResult.StartsWith('<pre>'), 'Should format large JSON');
        Assert.IsTrue(StrLen(FormattedResult) > StrLen(LargeJson), 'Formatted should include markup');
    end;

    [Test]
    procedure TestExtractPageStack_WithContext()
    var
        TempPageStackRecords: Record "Agent JSON Buffer" temporary;
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        ContextRootObject: JsonObject;
        PageStackArray: JsonArray;
        TaskPageContext: JsonObject;
    begin
        // [GIVEN] A context with both page stack and other properties
        PageStackArray.Add('CustomerList');
        PageStackArray.Add('CustomerCard');
        ContextRootObject.Add('pageStack', PageStackArray);

        TaskPageContext.Add('pageId', 21);
        TaskPageContext.Add('mode', 'Edit');
        ContextRootObject.Add('taskPageContext', TaskPageContext);
        ContextRootObject.Add('isDecisionPoint', true);

        // [WHEN] ExtractPageStack is called
        AgentTaskLogEntry.ExtractPageStack(TempPageStackRecords, ContextRootObject);

        // [THEN] Only page stack should be extracted
        Assert.AreEqual(2, TempPageStackRecords.Count(), 'Should extract 2 pages');
        TempPageStackRecords.FindFirst();
        Assert.AreEqual('CustomerCard', TempPageStackRecords.GetJsonText(), 'Top page should be CustomerCard');
    end;

    [Test]
    procedure TestExtractMemorizedData_CompleteScenario()
    var
        TempMemorizedDataRecords: Record "Agent JSON Buffer" temporary;
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        ContextRootObject: JsonObject;
        MemorizedDataObject: JsonObject;
    begin
        // [GIVEN] A complete context with various memorized data types
        MemorizedDataObject.Add('userName', 'John Doe');
        MemorizedDataObject.Add('customerId', '12345');
        MemorizedDataObject.Add('orderDate', '2024-01-15');
        MemorizedDataObject.Add('totalAmount', '1500.00');
        MemorizedDataObject.Add('isProcessed', 'true');
        ContextRootObject.Add('memorizedData', MemorizedDataObject);
        ContextRootObject.Add('otherProperty', 'notMemorized');

        // [WHEN] ExtractMemorizedData is called
        AgentTaskLogEntry.ExtractMemorizedData(TempMemorizedDataRecords, ContextRootObject);
        ValidateCompleteScenario(TempMemorizedDataRecords);
    end;

    local procedure ValidateCompleteScenario(var TempMemorizedDataRecords: Record "Agent JSON Buffer" temporary)
    begin
        // [THEN] Only memorized data from the memorizedData object should be extracted
        Assert.AreEqual(5, TempMemorizedDataRecords.Count(), 'Should extract 5 memorized entries');
        TempMemorizedDataRecords.FindSet();
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"key":"userName"'), 'Should contain userName key');
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"value":"John Doe"'), 'Should contain userName value');
        TempMemorizedDataRecords.Next();
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"key":"customerId"'), 'Should contain customerId key');
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"value":"12345"'), 'Should contain customerId value');
        TempMemorizedDataRecords.Next();
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"key":"orderDate"'), 'Should contain orderDate key');
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"value":"2024-01-15"'), 'Should contain orderDate value');
        TempMemorizedDataRecords.Next();
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"key":"totalAmount"'), 'Should contain totalAmount key');
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"value":"1500.00"'), 'Should contain totalAmount value');
        TempMemorizedDataRecords.Next();
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"key":"isProcessed"'), 'Should contain isProcessed key');
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"value":"true"'), 'Should contain isProcessed value');
    end;

    [Test]
    procedure TestCompleteContextParsing()
    var
        TempPageStackRecords: Record "Agent JSON Buffer" temporary;
        TempAvailableToolsRecords: Record "Agent JSON Buffer" temporary;
        TempMemorizedDataRecords: Record "Agent JSON Buffer" temporary;
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        ContextRootObject: JsonObject;
        MemorizedDataObject: JsonObject;
        PageStackArray: JsonArray;
        AvailableToolsArray: JsonArray;
        Success: Boolean;
    begin
        // [GIVEN] A complete context object with all components
        PageStackArray.Add('HomePage');
        PageStackArray.Add('ListPage');
        PageStackArray.Add('CardPage');
        ContextRootObject.Add('pageStack', PageStackArray);

        AvailableToolsArray.Add('Tool1');
        AvailableToolsArray.Add('Tool2');
        ContextRootObject.Add('availableTools', AvailableToolsArray);

        MemorizedDataObject.Add('key1', 'value1');
        MemorizedDataObject.Add('key2', 'value2');
        ContextRootObject.Add('memorizedData', MemorizedDataObject);

        ContextRootObject.Add('isDecisionPoint', true);

        // [WHEN] Extraction methods are called
        AgentTaskLogEntry.ExtractPageStack(TempPageStackRecords, ContextRootObject);
        AgentTaskLogEntry.ExtractAvailableTools(TempAvailableToolsRecords, ContextRootObject);
        AgentTaskLogEntry.ExtractMemorizedData(TempMemorizedDataRecords, ContextRootObject);

        // [THEN] All data should be extracted correctly
        Assert.AreEqual(3, TempPageStackRecords.Count(), 'Should have 3 pages');
        Assert.AreEqual(2, TempAvailableToolsRecords.Count(), 'Should have 2 tools');
        Assert.AreEqual(2, TempMemorizedDataRecords.Count(), 'Should have 2 memorized entries');
        Assert.IsTrue(AgentTaskLogEntry.GetDecisionPoint(ContextRootObject), 'Should identify the decision point');
        Assert.IsTrue(AgentTaskLogEntry.GetSuccess('{"success":true}', Success), 'Should find the success value');
        Assert.IsTrue(Success, 'Should parse the success value');

        ValidateFullContext(TempPageStackRecords, TempAvailableToolsRecords, TempMemorizedDataRecords);
    end;

    [Test]
    procedure TestBuildContextJson_IncludesCalculatedDetails()
    var
        AgentTaskLogExport: Codeunit "Agent Task Log Export";
        ContextJson: JsonObject;
        PageToken: JsonToken;
        PageStackEntry: JsonObject;
        ContextTxt: Text;
    begin
        // [GIVEN] Troubleshooting context containing all calculated detail-page sections
        ContextTxt := '{"serializedPage":"{\"page\":\"Customer Card\"}","isDecisionPoint":true,"pageStack":["Customer List","Customer Card"],"availableTools":["Edit record"],"memorizedData":{"customerNo":"10000"},"taskPageContext":{"currencyCode":"USD","currencySymbol":"$","outgoingCommunicationCulture":{"language":"en-US","dateFormat":"M/d/yyyy","timeFormat":"h:mm tt","formattedNumberExample":"1,234.56"}}}';

        // [WHEN] The context is projected for an authorized export
        AgentTaskLogExport.BuildContextJson(ContextTxt, true, ContextJson);

        // [THEN] The native JSON values and calculated flags are preserved
        Assert.IsTrue(ContextJson.GetBoolean('decisionPoint'), 'The decision point should be exported.');
        Assert.IsTrue(ContextJson.Contains('pageContent'), 'The page content should be included.');
        Assert.IsFalse(ContextJson.Contains('pageContentRedacted'), 'The page content should not be redacted.');
        Assert.AreEqual(2, ContextJson.GetArray('pageStack').Count(), 'The page stack should be exported.');
        ContextJson.GetArray('pageStack').Get(0, PageToken);
        PageStackEntry := PageToken.AsObject();
        Assert.AreEqual('1', PageStackEntry.GetText('order'), 'The first page should have order 1.');
        Assert.AreEqual('Customer List', PageStackEntry.GetText('pageCaption'), 'The page stack should preserve the stored order.');
        Assert.AreEqual(1, ContextJson.GetArray('availableTools').Count(), 'The available tools should be exported.');
        Assert.AreEqual('10000', ContextJson.GetObject('memorizedData').GetText('customerNo'), 'The memorized data should be exported.');
        Assert.AreEqual('USD', ContextJson.GetObject('taskAndPageSettings').GetText('currencyCode'), 'The task and page settings should be exported.');
        Assert.AreEqual('en-US', ContextJson.GetObject('taskAndPageSettings').GetObject('communication').GetObject('culture').GetText('language'), 'The communication settings should be nested.');
        Assert.AreEqual('Customer Card', ContextJson.GetObject('pageContent').GetText('page'), 'The page content should remain JSON.');
    end;

    [Test]
    procedure TestBuildContextJson_RedactsSerializedPage()
    var
        AgentTaskLogExport: Codeunit "Agent Task Log Export";
        ContextJson: JsonObject;
    begin
        // [GIVEN] Troubleshooting context containing a sensitive page snapshot
        // [WHEN] The context is projected without the troubleshooting permission
        AgentTaskLogExport.BuildContextJson('{"serializedPage":"{\"secret\":\"value\"}"}', false, ContextJson);

        // [THEN] The snapshot is not present and the redaction is explicit
        Assert.IsFalse(ContextJson.Contains('pageContent'), 'The page content should not be included.');
        Assert.IsTrue(ContextJson.GetBoolean('pageContentRedacted'), 'The page content should be marked as redacted.');
        Assert.IsTrue(ContextJson.GetText('pageContentRedactionReason').Contains('Troubleshoot All Agents'), 'The redaction reason should identify the required permission.');
    end;

    [Test]
    procedure TestExportToJson_UsesChronologicalOrder()
    var
        TempAgentTaskLogEntry: Record "Agent Task Log Entry" temporary;
        ExportJson: JsonObject;
        EntryToken: JsonToken;
        LogEntries: JsonArray;
    begin
        // [GIVEN] Log entries inserted in ascending order
        CreateTempLogEntryWithContext(TempAgentTaskLogEntry, 1, '');
        CreateTempLogEntryWithContext(TempAgentTaskLogEntry, 2, '');

        // [WHEN] All selected log entries are exported
        ExportToJson(TempAgentTaskLogEntry, ExportJson);

        // [THEN] Log entries use chronological order for downstream consumption
        LogEntries := ExportJson.GetArray('logEntries');
        Assert.AreEqual(2, LogEntries.Count(), 'All selected log entries should be exported.');
        LogEntries.Get(0, EntryToken);
        Assert.AreEqual(1, EntryToken.AsObject().GetInteger('id'), 'The oldest log entry should be exported first.');
        LogEntries.Get(1, EntryToken);
        Assert.AreEqual(2, EntryToken.AsObject().GetInteger('id'), 'The newest log entry should be exported last.');
        Assert.IsFalse(ExportJson.Contains('memoryEntries'), 'Selected log-entry export should not include task memory entries.');
    end;

    [Test]
    procedure TestExportToJson_SeparatesLogAndMemoryEntries()
    var
        TempAgentTaskLogEntry: Record "Agent Task Log Entry" temporary;
        TempAgentTaskMemoryEntry: Record "Agent Task Memory Entry" temporary;
        ExportJson: JsonObject;
        EntryToken: JsonToken;
        LogEntries: JsonArray;
        MemoryEntries: JsonArray;
    begin
        // [GIVEN] Three log entries referencing three of six task memory entries
        CreateTempLogEntry(TempAgentTaskLogEntry, 1, 2);
        CreateTempLogEntry(TempAgentTaskLogEntry, 2, 4);
        CreateTempLogEntry(TempAgentTaskLogEntry, 3, 6);
        CreateTempMemoryEntries(TempAgentTaskMemoryEntry, 6);

        // [WHEN] The task data is exported
        ExportToJson(TempAgentTaskLogEntry, TempAgentTaskMemoryEntry, ExportJson);

        // [THEN] Log and memory records remain separate and chronological
        LogEntries := ExportJson.GetArray('logEntries');
        MemoryEntries := ExportJson.GetArray('memoryEntries');
        Assert.AreEqual(3, LogEntries.Count(), 'The export should contain the three displayed log entries.');
        Assert.AreEqual(6, MemoryEntries.Count(), 'The export should contain all six task memory entries.');
        LogEntries.Get(0, EntryToken);
        Assert.AreEqual(2, EntryToken.AsObject().GetInteger('memoryEntryId'), 'The first log entry should reference memory entry 2.');
        LogEntries.Get(2, EntryToken);
        Assert.AreEqual(6, EntryToken.AsObject().GetInteger('memoryEntryId'), 'The last log entry should reference memory entry 6.');
        MemoryEntries.Get(0, EntryToken);
        Assert.AreEqual(1, EntryToken.AsObject().GetInteger('id'), 'The oldest memory entry should be exported first.');
        MemoryEntries.Get(5, EntryToken);
        Assert.AreEqual(6, EntryToken.AsObject().GetInteger('id'), 'The newest memory entry should be exported last.');
        Assert.IsFalse(ExportJson.Contains('steps'), 'Memory entries must not be represented as task steps.');
        Assert.IsFalse(ExportJson.Contains('formatVersion'), 'The unshipped export does not need a format version.');
    end;

    [Test]
    procedure TestExportToJson_DeserializesMemoryDetails()
    var
        TempAgentTaskLogEntry: Record "Agent Task Log Entry" temporary;
        TempAgentTaskMemoryEntry: Record "Agent Task Memory Entry" temporary;
        ExportJson: JsonObject;
        MemoryEntryJson: JsonObject;
        MemoryEntryToken: JsonToken;
        DetailsJsonToken: JsonToken;
    begin
        // [GIVEN] A memory entry whose details contain JSON text
        CreateTempMemoryEntry(TempAgentTaskMemoryEntry, 1, 'Memory details');
        SetTempMemoryEntryDetails(TempAgentTaskMemoryEntry, '{"pageName":"Sales Order List","success":true}');

        // [WHEN] Task data is exported
        ExportToJson(TempAgentTaskLogEntry, TempAgentTaskMemoryEntry, ExportJson);

        // [THEN] Memory details are a JSON object rather than escaped text
        ExportJson.GetArray('memoryEntries').Get(0, MemoryEntryToken);
        MemoryEntryJson := MemoryEntryToken.AsObject();
        MemoryEntryJson.Get('details', DetailsJsonToken);
        Assert.IsTrue(DetailsJsonToken.IsObject(), 'Memory details should be exported as native JSON.');
        Assert.AreEqual('Sales Order List', MemoryEntryJson.GetObject('details').GetText('pageName'), 'The memory details should preserve their JSON values.');
        Assert.IsTrue(MemoryEntryJson.GetObject('details').GetBoolean('success'), 'The memory details should preserve Boolean values.');
    end;

    [Test]
    procedure TestExportToJson_UsesEnglishEnumCaptionsAndRestoresLanguage()
    var
        TempAgentTaskLogEntry: Record "Agent Task Log Entry" temporary;
        ExportJson: JsonObject;
        EntryJson: JsonObject;
        CurrentGlobalLanguage: Integer;
        LanguageAfterExport: Integer;
    begin
        // [GIVEN] A non-English session and a page-operation log entry
        CreateTempLogEntry(TempAgentTaskLogEntry, 1, 0);
        CurrentGlobalLanguage := GlobalLanguage();
        GlobalLanguage(1036); // French

        // [WHEN] The log entry is exported
        ExportToJson(TempAgentTaskLogEntry, ExportJson);
        LanguageAfterExport := GlobalLanguage();
        GlobalLanguage(CurrentGlobalLanguage);

        // [THEN] The export uses English captions without changing the caller's language
        EntryJson := GetFirstEntry(ExportJson);
        Assert.AreEqual('Page Operation', EntryJson.GetText('type'), 'The log entry type should use its English caption.');
        Assert.AreEqual(1036, LanguageAfterExport, 'The export should restore the caller''s global language.');
    end;

    [Test]
    procedure TestExportToJson_UsesRealTaskContext()
    var
        AgentRecord: Record Agent;
        AgentTask: Record "Agent Task";
        TempAgentTaskLogEntry: Record "Agent Task Log Entry" temporary;
        TempAgentTaskMemoryEntry: Record "Agent Task Memory Entry" temporary;
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        LibraryMockAgent: Codeunit "Library Mock Agent";
        ExportJson: JsonObject;
        TaskContextJson: JsonObject;
        AgentUserSecurityID: Guid;
        TaskTitle: Text[150];
        ExternalIdTok: Label 'LOG-EXPORT-TASK', Locked = true;
    begin
        // [GIVEN] A real task for a mock SDK agent
        LibraryMockAgent.DeleteAllAgents();
        TaskTitle := 'Task log export';
        AgentUserSecurityID := LibraryMockAgent.GetOrCreateDefaultAgent(AgentRecord, 'LOGEXPORT', 'Log Export Agent', 'Export task logs.');
        AgentTaskBuilder.Initialize(AgentUserSecurityID, TaskTitle).SetExternalId(ExternalIdTok);
        AgentTask := AgentTaskBuilder.Create(true, false);

        // [WHEN] The task context is exported with deterministic temporary collections
        ExportToJson(TempAgentTaskLogEntry, TempAgentTaskMemoryEntry, AgentTask.ID, ExportJson);

        // [THEN] The root context comes from the persisted task
        TaskContextJson := ExportJson.GetObject('taskContext');
        Assert.AreEqual(Format(AgentTask.ID, 0, 9), TaskContextJson.GetText('taskId'), 'The task ID should be exported.');
        Assert.AreEqual(TaskTitle, TaskContextJson.GetText('taskTitle'), 'The task title should be exported.');
        Assert.AreEqual('Log Export Agent', TaskContextJson.GetText('agentName'), 'The agent name should be exported.');
    end;

    local procedure CreateTempLogEntryWithContext(var TempAgentTaskLogEntry: Record "Agent Task Log Entry" temporary; EntryID: Integer; ContextTxt: Text)
    var
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        ContextOutStream: OutStream;
    begin
        TempAgentTaskLogEntry.Init();
        TempAgentTaskLogEntry.ID := EntryID;
        TempAgentTaskLogEntry."Task ID" := -1;
        TempAgentTaskLogEntry."Memory Entry ID" := 1;
        TempAgentTaskLogEntry.Type := TempAgentTaskLogEntry.Type::"Input Message";
        TempAgentTaskLogEntry."Troubleshooting Info".CreateOutStream(ContextOutStream, AgentTaskLogEntry.GetDefaultEncoding());
        ContextOutStream.WriteText(ContextTxt);
        TempAgentTaskLogEntry.Insert();
    end;

    local procedure CreateTempLogEntry(var TempAgentTaskLogEntry: Record "Agent Task Log Entry" temporary; EntryID: Integer; MemoryEntryID: Integer)
    begin
        TempAgentTaskLogEntry.Init();
        TempAgentTaskLogEntry.ID := EntryID;
        TempAgentTaskLogEntry."Task ID" := -1;
        TempAgentTaskLogEntry."Memory Entry ID" := MemoryEntryID;
        TempAgentTaskLogEntry.Type := TempAgentTaskLogEntry.Type::"Page Operation";
        TempAgentTaskLogEntry.Insert();
    end;

    local procedure CreateTempMemoryEntry(var TempAgentTaskMemoryEntry: Record "Agent Task Memory Entry" temporary; EntryID: Integer; Description: Text)
    begin
        TempAgentTaskMemoryEntry.Init();
        TempAgentTaskMemoryEntry."Task ID" := -1;
        TempAgentTaskMemoryEntry.ID := EntryID;
        TempAgentTaskMemoryEntry.Type := TempAgentTaskMemoryEntry.Type::Message;
        TempAgentTaskMemoryEntry.Description := CopyStr(Description, 1, MaxStrLen(TempAgentTaskMemoryEntry.Description));
        TempAgentTaskMemoryEntry.Insert();
    end;

    local procedure CreateTempMemoryEntries(var TempAgentTaskMemoryEntry: Record "Agent Task Memory Entry" temporary; EntryCount: Integer)
    var
        EntryID: Integer;
    begin
        for EntryID := 1 to EntryCount do begin
            CreateTempMemoryEntry(TempAgentTaskMemoryEntry, EntryID, StrSubstNo('Memory entry %1', EntryID));
            if EntryID mod 2 = 1 then begin
                TempAgentTaskMemoryEntry.Type := TempAgentTaskMemoryEntry.Type::"Memorized Data";
                TempAgentTaskMemoryEntry.Modify();
            end;
        end;
    end;

    local procedure SetTempMemoryEntryDetails(var TempAgentTaskMemoryEntry: Record "Agent Task Memory Entry" temporary; DetailsTxt: Text)
    var
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        DetailsOutStream: OutStream;
    begin
        TempAgentTaskMemoryEntry.Details.CreateOutStream(DetailsOutStream, AgentTaskLogEntry.GetDefaultEncoding());
        DetailsOutStream.WriteText(DetailsTxt);
        TempAgentTaskMemoryEntry.Modify();
    end;

    local procedure ExportToJson(var TempAgentTaskLogEntry: Record "Agent Task Log Entry" temporary; var ExportJson: JsonObject)
    var
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        AgentTaskLogExport: Codeunit "Agent Task Log Export";
        TempBlob: Codeunit "Temp Blob";
        ExportInStream: InStream;
        ExportOutStream: OutStream;
        ExportTxt: Text;
    begin
        TempBlob.CreateOutStream(ExportOutStream, AgentTaskLogEntry.GetDefaultEncoding());
        AgentTaskLogExport.ExportToJson(TempAgentTaskLogEntry, ExportOutStream);
        TempBlob.CreateInStream(ExportInStream, AgentTaskLogEntry.GetDefaultEncoding());
        ExportInStream.ReadText(ExportTxt);
        Assert.IsTrue(ExportJson.ReadFrom(ExportTxt), 'The export should contain valid JSON.');
    end;

    local procedure ExportToJson(var TempAgentTaskLogEntry: Record "Agent Task Log Entry" temporary; var TempAgentTaskMemoryEntry: Record "Agent Task Memory Entry" temporary; var ExportJson: JsonObject)
    begin
        ExportToJson(TempAgentTaskLogEntry, TempAgentTaskMemoryEntry, -1, ExportJson);
    end;

    local procedure ExportToJson(var TempAgentTaskLogEntry: Record "Agent Task Log Entry" temporary; var TempAgentTaskMemoryEntry: Record "Agent Task Memory Entry" temporary; AgentTaskID: BigInteger; var ExportJson: JsonObject)
    var
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        AgentTaskLogExport: Codeunit "Agent Task Log Export";
        TempBlob: Codeunit "Temp Blob";
        ExportInStream: InStream;
        ExportOutStream: OutStream;
        ExportTxt: Text;
    begin
        TempBlob.CreateOutStream(ExportOutStream, AgentTaskLogEntry.GetDefaultEncoding());
        AgentTaskLogExport.ExportToJson(TempAgentTaskLogEntry, TempAgentTaskMemoryEntry, AgentTaskID, ExportOutStream);
        TempBlob.CreateInStream(ExportInStream, AgentTaskLogEntry.GetDefaultEncoding());
        ExportInStream.ReadText(ExportTxt);
        Assert.IsTrue(ExportJson.ReadFrom(ExportTxt), 'The export should contain valid JSON.');
    end;

    local procedure GetFirstEntry(ExportJson: JsonObject): JsonObject
    var
        EntryToken: JsonToken;
    begin
        ExportJson.GetArray('logEntries').Get(0, EntryToken);
        exit(EntryToken.AsObject());
    end;

    local procedure ValidateFullContext(var TempPageStackRecords: Record "Agent JSON Buffer" temporary; var TempAvailableToolsRecords: Record "Agent JSON Buffer" temporary; var TempMemorizedDataRecords: Record "Agent JSON Buffer" temporary)
    begin
        // Validate page stack contents (note: pages are reversed)
        TempPageStackRecords.FindSet();
        Assert.AreEqual('CardPage', TempPageStackRecords.GetJsonText(), 'First page should be CardPage (reversed order)');
        TempPageStackRecords.Next();
        Assert.AreEqual('ListPage', TempPageStackRecords.GetJsonText(), 'Second page should be ListPage');
        TempPageStackRecords.Next();
        Assert.AreEqual('HomePage', TempPageStackRecords.GetJsonText(), 'Third page should be HomePage');

        // Validate available tools contents
        TempAvailableToolsRecords.FindSet();
        Assert.AreEqual('Tool1', TempAvailableToolsRecords.GetJsonText(), 'First tool should be Tool1');
        TempAvailableToolsRecords.Next();
        Assert.AreEqual('Tool2', TempAvailableToolsRecords.GetJsonText(), 'Second tool should be Tool2');

        // Validate memorized data contents
        TempMemorizedDataRecords.FindSet();
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"key":"key1"'), 'First entry should contain key1');
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"value":"value1"'), 'First entry should contain value1');
        TempMemorizedDataRecords.Next();
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"key":"key2"'), 'Second entry should contain key2');
        Assert.IsTrue(TempMemorizedDataRecords.GetJsonText().Contains('"value":"value2"'), 'Second entry should contain value2');
    end;

    [Test]
    procedure TestExtractPageStack_NullValues()
    var
        TempPageStackRecords: Record "Agent JSON Buffer" temporary;
        AgentTaskLogEntry: Codeunit "Agent Task Log Entry";
        ContextRootObject: JsonObject;
        PageStackArray: JsonArray;
        NullToken: JsonToken;
    begin
        // [GIVEN] A page stack with null values
        PageStackArray.Add('Page1');
        NullToken.ReadFrom('null');
        PageStackArray.Add(NullToken);
        PageStackArray.Add('Page3');
        ContextRootObject.Add('pageStack', PageStackArray);

        // [WHEN] ExtractPageStack is called
        AgentTaskLogEntry.ExtractPageStack(TempPageStackRecords, ContextRootObject);

        // [THEN] Null values are skipped and the remaining pages are reversed
        Assert.AreEqual(2, TempPageStackRecords.Count(), 'Should extract exactly 2 non-null pages');
        TempPageStackRecords.FindFirst();
        Assert.AreEqual('Page3', TempPageStackRecords.GetJsonText(), 'The last page should be first');
        TempPageStackRecords.Next();
        Assert.AreEqual('Page1', TempPageStackRecords.GetJsonText(), 'The first page should be last');
    end;
}
