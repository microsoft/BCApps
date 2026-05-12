// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Agents;

using System.Agents;
using System.Environment;
using System.Environment.Configuration;
using System.Globalization;
using System.TestLibraries.Utilities;
using System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

codeunit 130561 "Library - Agent Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetAgentUnderTest(var AgentUserSecurityID: Guid)
    var
        AgentTestContext: Codeunit "Agent Test Context";
    begin
        EnsureIsTest();
        AgentTestContext.GetAgentUserSecurityID(AgentUserSecurityID);
    end;

    procedure EnsureAgentIsActive(AgentUserSecurityID: Guid)
    var
        Agent: Codeunit Agent;
    begin
        EnsureIsTest();
        if not Agent.IsActive(AgentUserSecurityID) then
            Agent.Activate(AgentUserSecurityID);
    end;

    procedure CreateTaskAndWait(var AgentTaskBuilder: Codeunit "Agent Task Builder"; var AgentTask: Record "Agent Task"): Boolean
    var
        AgentTestContext: Codeunit "Agent Test Context";
    begin
        EnsureIsTest();
        AgentTask := AgentTaskBuilder.Create(true, false); // Test tasks do not require message.
        AgentTestContext.AddTaskToLog(AgentTask.ID);
        Commit();
        exit(WaitForTaskToComplete(AgentTask));
    end;

    procedure CreateMessageAndWait(var AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder"; var AgentTask: Record "Agent Task"): Boolean
    var
        AgentTestContext: Codeunit "Agent Test Context";
    begin
        EnsureIsTest();
        AgentTaskMessageBuilder.SetRequiresReview(false);
        AgentTask.Get(AgentTaskMessageBuilder.Create()."Task ID");
        AgentTestContext.AddTaskToLog(AgentTask.ID);
        Commit();

        exit(WaitForTaskToComplete(AgentTask));
    end;

    procedure StopAllTasks()
    var
        BlankGuid: Guid;
    begin
        EnsureIsTest();
        StopTasks(BlankGuid);
    end;

    procedure StopTasks(AgentUserSecurityId: Guid)
    var
        AgentTask: Record "Agent Task";
    begin
        EnsureIsTest();
        AgentTask.ReadIsolation := IsolationLevel::ReadCommitted;
        AgentTask.SetFilter(Status, '<>%1', AgentTask.Status::Paused);
        if not IsNullGuid(AgentUserSecurityId) then
            AgentTask.SetFilter("Agent User Security ID", AgentUserSecurityId);
        if not AgentTask.FindSet() then
            exit;

        repeat
            StopTask(AgentTask);
        until AgentTask.Next() = 0;
    end;

    procedure WriteTurnToOutput(var AgentTask: Record "Agent Task"; TurnSuccessful: Boolean; ErrorReason: Text)
    var
        AITTestContext: Codeunit "AIT Test Context";
        AgentOutputText: Codeunit "Test Output Json";
        TestJsonObject: JsonObject;
        AnswerText: Text;
    begin
        EnsureIsTest();
        AgentOutputText.Initialize();
        WriteTaskToOutput(AgentTask, AgentOutputText);

        TestJsonObject.ReadFrom('{}');
        TestJsonObject.Add('success', TurnSuccessful);
        TestJsonObject.Add('errorReason', ErrorReason);
        TestJsonObject.Add('taskDetails', AgentOutputText.AsJsonToken());
        TestJsonObject.WriteTo(AnswerText);

        AITTestContext.SetAnswerForQnAEvaluation(AnswerText);
    end;

    procedure WriteTaskToOutput(var AgentTask: Record "Agent Task"; var AgentTaskTestOutput: Codeunit "Test Output Json")
    begin
        EnsureIsTest();
        WriteTaskToOutput(AgentTask, AgentTaskTestOutput, 0DT);
    end;

    procedure WriteTaskToOutput(var AgentTask: Record "Agent Task"; var AgentTaskTestOutput: Codeunit "Test Output Json"; FromDateTime: DateTime)
    var
        AgentMessagesTestOutput: Codeunit "Test Output Json";
        LastLogEntryIdTok: Label 'lastLogEntryId', Locked = true;
        LastLogEntryTimestampTok: Label 'lastLogEntryTimestamp', Locked = true;

        AgentLanguageCultureTok: Label 'agentLanguageCulture', Locked = true;
        AgentLocaleCultureTok: Label 'agentLocaleCulture', Locked = true;
    begin
        EnsureIsTest();
        AgentTaskTestOutput.Add(IdTok, Format(AgentTask.ID, 0, 9));
        AgentTaskTestOutput.Add(StatusTok, Format(AgentTask.Status, 0, 9));
        AgentTaskTestOutput.Add(LastLogEntryIdTok, AgentTask."Last Log Entry ID");
        AgentTaskTestOutput.Add(LastLogEntryTimestampTok, AgentTask."Last Log Entry Timestamp");
        AgentTaskTestOutput.Add(AgentLanguageCultureTok, GetAgentLanguageCultureName(AgentTask."Agent User Security ID"));
        AgentTaskTestOutput.Add(AgentLocaleCultureTok, GetAgentLocaleCultureName(AgentTask."Agent User Security ID"));
        AgentMessagesTestOutput := AgentTaskTestOutput.AddArray(MessagesTok);
        AddMessagesToOutput(AgentTask, AgentMessagesTestOutput, FromDateTime);

        OnWriteTaskToOutput(AgentTask, AgentTaskTestOutput, FromDateTime);
    end;

    procedure ContinueTaskAndWait(var AgentTask: Record "Agent Task"; UserInput: Text): Boolean
    var
        UserInterventionRequestEntry: Record "Agent Task Log Entry";
        AgentTaskMessage: Record "Agent Task Message";
        AgentUserIntervention: Codeunit "Agent User Intervention";
        AgentTestContext: Codeunit "Agent Test Context";
    begin
        EnsureIsTest();
        UserInterventionRequestEntry.Get(AgentTask.ID, AgentTask."Last Log Entry ID");
        AgentUserIntervention.CreateUserIntervention(UserInterventionRequestEntry, UserInput);

        // Mark all output messages that have been reviewed as sent
        AgentTaskMessage.SetRange("Task ID", AgentTask.ID);
        AgentTaskMessage.SetRange("Type", AgentTaskMessage."Type"::Output);
        AgentTaskMessage.SetRange(Status, AgentTaskMessage.Status::Reviewed);
        if AgentTaskMessage.FindSet() then
            repeat
                // ModifyAll is not currently implemented in the virtual data provider.
                AgentTaskMessage.Status := AgentTaskMessage.Status::Sent;
                AgentTaskMessage.Modify();
            until AgentTaskMessage.Next() = 0;

        Commit();
        Sleep(GetDefaultWaitTime());
        SelectLatestVersion();
        AgentTask.Find();
        AgentTestContext.AddTaskToLog(AgentTask.ID);
        exit(WaitForTaskToComplete(AgentTask));
    end;

    procedure ParseUserInterventionRequestType(UserInterventionRequestTypeText: Text): Enum "Agent User Int Request Type"
    var
        UserInterventionRequestType: Enum "Agent User Int Request Type";
        IndexOfName: Integer;
    begin
        EnsureIsTest();
        IndexOfName := UserInterventionRequestType.Names.IndexOf(UserInterventionRequestTypeText);
        if IndexOfName <= 0 then
            Error(UserInterventionRequestTypeDoesNotExistErr, UserInterventionRequestTypeText);

        UserInterventionRequestType := Enum::"Agent User Int Request Type".FromInteger(UserInterventionRequestType.Ordinals().Get(IndexOfName));
        exit(UserInterventionRequestType);
    end;

    procedure RequiresUserIntervention(AgentTask: Record "Agent Task"): Boolean
    begin
        EnsureIsTest();
        exit((AgentTask.Status = AgentTask.Status::Paused) and AgentTask."Needs Attention");
    end;

    procedure GetLastUserInterventionRequestDetails(
        AgentTask: Record "Agent Task";
        var TempUserInterventionRequest: Record "Agent User Int Request Details" temporary;
        var TempUserInterventionAnnotation: Record "Agent Annotation" temporary;
        var TempUserInterventionSuggestion: Record "Agent Task User Int Suggestion" temporary): Boolean
    var
        UserInterventionRequestEntry: Record "Agent Task Log Entry";
        AgentUserIntervention: Codeunit "Agent User Intervention";
    begin
        EnsureIsTest();
        UserInterventionRequestEntry.SetRange("Task ID", AgentTask.ID);
        UserInterventionRequestEntry.SetRange(Type, UserInterventionRequestEntry.Type::"User Intervention Request");
        UserInterventionRequestEntry.SetCurrentKey("ID");
        if not UserInterventionRequestEntry.FindLast() then
            exit(false);

        AgentUserIntervention.GetUserInterventionRequestDetails(UserInterventionRequestEntry, TempUserInterventionRequest, TempUserInterventionAnnotation, TempUserInterventionSuggestion);
        exit(true);
    end;

    procedure GetUserInterventionRequestDetails(
        UserInterventionRequestEntry: Record "Agent Task Log Entry";
        var TempUserInterventionRequest: Record "Agent User Int Request Details" temporary;
        var TempUserInterventionAnnotation: Record "Agent Annotation" temporary;
        var TempUserInterventionSuggestion: Record "Agent Task User Int Suggestion" temporary)
    var
        AgentUserIntervention: Codeunit "Agent User Intervention";
    begin
        EnsureIsTest();
        AgentUserIntervention.GetUserInterventionRequestDetails(UserInterventionRequestEntry, TempUserInterventionRequest, TempUserInterventionAnnotation, TempUserInterventionSuggestion);
    end;

    procedure CreateUserInterventionAndWait(var AgentTask: Record "Agent Task"; UserInput: Text): Boolean
    var
        UserInterventionRequestEntry: Record "Agent Task Log Entry";
        AgentUserIntervention: Codeunit "Agent User Intervention";
        AgentTestContext: Codeunit "Agent Test Context";
    begin
        EnsureIsTest();
        AgentTestContext.AddTaskToLog(AgentTask.ID);
        UserInterventionRequestEntry.Get(AgentTask.ID, AgentTask."Last Log Entry ID");
        AgentUserIntervention.CreateUserIntervention(UserInterventionRequestEntry, UserInput);

        Commit();
        Sleep(GetDefaultWaitTime());
        SelectLatestVersion();
        AgentTask.Find();

        exit(WaitForTaskToComplete(AgentTask));
    end;

    procedure CreateUserInterventionFromSuggestionAndWait(var AgentTask: Record "Agent Task"; SuggestionCode: Code[20]): Boolean
    var
        UserInterventionRequestEntry: Record "Agent Task Log Entry";
        AgentUserIntervention: Codeunit "Agent User Intervention";
        AgentTestContext: Codeunit "Agent Test Context";
    begin
        EnsureIsTest();
        AgentTestContext.AddTaskToLog(AgentTask.ID);
        UserInterventionRequestEntry.Get(AgentTask.ID, AgentTask."Last Log Entry ID");
        AgentUserIntervention.CreateUserInterventionFromSuggestionCode(UserInterventionRequestEntry, SuggestionCode);

        Commit();
        Sleep(GetDefaultWaitTime());
        SelectLatestVersion();
        AgentTask.Find();

        exit(WaitForTaskToComplete(AgentTask));
    end;

    procedure WaitForTaskToComplete(var AgentTask: Record "Agent Task"): Boolean
    var
        AgentTestContext: Codeunit "Agent Test Context";
        WaitTime: Duration;
        Timeout: Duration;
        TaskCompleted: Boolean;
    begin
        EnsureIsTest();
        // Logging to capture all tasks that are invoked via UI actions. 
        // Test can create a task by invoking UI and wait for the task.
        AgentTestContext.AddTaskToLog(AgentTask.ID);

        Timeout := GetAgentTaskTimeout();
        VerifyAgentIsActive(AgentTask."Agent User Security ID");
        VerifyTimeout(Timeout);

        while (IsAgentTaskRunning(AgentTask) and (WaitTime < Timeout))
        do begin
            Sleep(GetDefaultWaitTime());
            WaitTime += GetDefaultWaitTime();
            SelectLatestVersion();
            AgentTask.Find();
        end;

        TaskCompleted := HasAgentTaskCompleted(AgentTask);
        if not TaskCompleted then
            StopTask(AgentTask);

        exit(TaskCompleted);
    end;

    procedure SetAgentTaskTimeout(NewTaskTimeout: Duration)
    begin
        EnsureIsTest();
        VerifyTimeout(NewTaskTimeout);
        GlobalAgentTaskTimeout := NewTaskTimeout;
    end;

    local procedure StopTask(var AgentTask: Record "Agent Task")
    begin
        AgentTask.Status := AgentTask.Status::"Stopped by User";
        AgentTask.Modify(true);
        Commit();
    end;

    local procedure VerifyTimeout(Timeout: Duration)
    var
        MaxTimeout: Duration;
    begin
        if Timeout < 0 then
            Error(TimeoutCannotBeNegativeErr);

        MaxTimeout := GetMaximumTimeout();
        if Timeout > MaxTimeout then
            Error(TimeoutExceedsMaximumErr, Timeout, MaxTimeout);
    end;

    local procedure VerifyAgentIsActive(AgentUserSecurityId: Guid)
    var
        Agent: Codeunit Agent;
    begin
        if not Agent.IsActive(AgentUserSecurityId) then
            Error(AgentNotActiveErr, AgentUserSecurityId);
    end;

    local procedure AddMessagesToOutput(var AgentTask: Record "Agent Task"; var AgentMessagesTestOutput: Codeunit "Test Output Json"; FromDateTime: DateTime)
    var
        AgentTaskMessage: Record "Agent Task Message";
        SingleMessageTestOutput: Codeunit "Test Output Json";
    begin
        AgentTaskMessage.SetRange("Task ID", AgentTask.ID);
        if FromDateTime <> 0DT then
            AgentTaskMessage.SetFilter(SystemCreatedAt, '>=%1', FromDateTime);

        if AgentTaskMessage.FindSet() then
            repeat
                SingleMessageTestOutput := AgentMessagesTestOutput.Add('{}');
                SingleMessageTestOutput.Add(IdTok, Format(AgentTaskMessage.ID, 0, 4));
                SingleMessageTestOutput.Add(TypeTok, AgentTaskMessage."Type");
                SingleMessageTestOutput.Add(StatusTok, AgentTaskMessage.Status);
                SingleMessageTestOutput.Add(ContentTok, GetMessageText(AgentTaskMessage));
                SingleMessageTestOutput.Add(CreatedDateTimeTok, AgentTaskMessage.SystemCreatedAt);
            until AgentTaskMessage.Next() = 0;
    end;

    local procedure GetAgentTaskTimeout(): Duration
    var
        BlankDuration: Duration;
    begin
        if GlobalAgentTaskTimeout <> BlankDuration then
            exit(GlobalAgentTaskTimeout);

        GlobalAgentTaskTimeout := 15 * 60 * 1000; // 15 minutes

        exit(GlobalAgentTaskTimeout);
    end;

    local procedure GetMaximumTimeout(): Duration
    begin
        exit(30 * 60 * 1000); // 30 minutes
    end;

    local procedure GetDefaultEncoding(): TextEncoding
    begin
        exit(TextEncoding::UTF8);
    end;

    local procedure GetMessageText(var AgentTaskMessage: Record "Agent Task Message"): Text
    var
        ContentInStream: InStream;
        ContentText: Text;
    begin
        AgentTaskMessage.CalcFields(Content);
        AgentTaskMessage.Content.CreateInStream(ContentInStream, GetDefaultEncoding());
        ContentInStream.Read(ContentText);
        exit(ContentText);
    end;

    local procedure IsAgentTaskRunning(var AgentTask: Record "Agent Task"): Boolean
    begin
        exit((AgentTask.Status = AgentTask.Status::Ready) or
        (AgentTask.Status = AgentTask.Status::Scheduled) or
        (AgentTask.Status = AgentTask.Status::Running));
    end;

    local procedure HasAgentTaskCompleted(var AgentTask: Record "Agent Task"): Boolean
    begin
        exit((AgentTask.Status = AgentTask.Status::Paused) or
        (AgentTask.Status = AgentTask.Status::Completed) or
        (AgentTask.Status = AgentTask.Status::"Stopped by System") or
        (AgentTask.Status = AgentTask.Status::"Stopped by User"));
    end;

    local procedure GetAgentLanguageCultureName(AgentUserSecurityId: Guid): Text
    var
        TempUserSettings: Record "User Settings" temporary;
        Agent: Codeunit Agent;
        Language: Codeunit Language;
    begin
        Agent.GetUserSettings(AgentUserSecurityId, TempUserSettings);

        if TempUserSettings."Language ID" <> 0 then
            exit(Language.GetCultureName(TempUserSettings."Language ID"));

        exit('');
    end;

    local procedure GetAgentLocaleCultureName(AgentUserSecurityId: Guid): Text
    var
        TempUserSettings: Record "User Settings" temporary;
        Agent: Codeunit Agent;
        Language: Codeunit Language;
    begin
        Agent.GetUserSettings(AgentUserSecurityId, TempUserSettings);
        if TempUserSettings."Locale ID" <> 0 then
            exit(Language.GetCultureName(TempUserSettings."Locale ID"));

        exit('');
    end;

    local procedure GetDefaultWaitTime(): Duration
    begin
        exit(500);
    end;

    procedure RunTurnAndWait(AgentUserSecurityId: Guid; var AgentTask: Record "Agent Task"; LoadResources: Boolean; AgentTestResourceProvider: Interface IAgentTestResourceProvider): Boolean
    var
        AITTestContext: Codeunit "AIT Test Context";
        QueryInput: Codeunit "Test Input Json";
        IsTaskInput, IsIntervention : Boolean;
    begin
        EnsureIsTest();
        QueryInput := AITTestContext.GetQuery();

        QueryInput.ElementExists(TitleTok, IsTaskInput);
        QueryInput.ElementExists(InterventionTok, IsIntervention);

        if IsTaskInput and IsIntervention then
            Error(InvalidQueryBothErr);

        if not IsTaskInput and not IsIntervention then
            Error(InvalidQueryNeitherErr);

        if IsTaskInput then
            exit(CreateTaskFromQueryAndWait(AgentUserSecurityId, QueryInput, AgentTask, LoadResources, AgentTestResourceProvider));

        exit(ProcessInterventionAndWait(QueryInput, AgentTask));
    end;

    local procedure ProcessInterventionAndWait(QueryInput: Codeunit "Test Input Json"; var AgentTask: Record "Agent Task"): Boolean
    var
        TempSuggestion: Record "Agent Task User Int Suggestion" temporary;
        InterventionInput: Codeunit "Test Input Json";
        SuggestionExists, InstructionExists : Boolean;
    begin
        InterventionInput := QueryInput.Element(InterventionTok);

        InterventionInput.ElementExists(SuggestionTok, SuggestionExists);
        if SuggestionExists then
            exit(CreateUserInterventionFromSuggestionAndWait(
                AgentTask,
                CopyStr(InterventionInput.Element(SuggestionTok).ValueAsText(), 1, MaxStrLen(TempSuggestion.Code))));

        InterventionInput.ElementExists(InstructionTok, InstructionExists);
        if InstructionExists then
            exit(CreateUserInterventionAndWait(
                AgentTask, InterventionInput.Element(InstructionTok).ValueAsText()));

        Error(InvalidInterventionErr);
    end;

    local procedure CreateTaskFromQueryAndWait(AgentUserSecurityId: Guid; QueryInput: Codeunit "Test Input Json"; var AgentTask: Record "Agent Task"; LoadResources: Boolean; AgentTestResourceProvider: Interface IAgentTestResourceProvider): Boolean
    var
        AgentTaskBuilder: Codeunit "Agent Task Builder";
        AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder";
        AttachmentsInput: Codeunit "Test Input Json";
        TitleInput, FromInput, MessageInput : Codeunit "Test Input Json";
        Assert: Codeunit "Library Assert";
        ResourceInStream: InStream;
        FromValue: Text[250];
        MessageValue: Text;
        FileName: Text[250];
        MIMEType: Text[100];
        HasTitle, HasFrom, HasMessage, HasAttachments : Boolean;
        I: Integer;
    begin
        TitleInput := QueryInput.ElementExists(TitleTok, HasTitle);
        Assert.IsTrue(HasTitle, MissingTitleErr);

#pragma warning disable AA0139
        AgentTaskBuilder.Initialize(AgentUserSecurityId, TitleInput.ValueAsText());
#pragma warning restore AA0139

        FromInput := QueryInput.ElementExists(FromTok, HasFrom);
        if not HasFrom then
            exit;

#pragma warning disable AA0139
        FromValue := FromInput.ValueAsText();
#pragma warning restore AA0139

        MessageInput := QueryInput.ElementExists(MessageTok, HasMessage);
        if HasMessage then
            MessageValue := MessageInput.ValueAsText();

        AgentTaskMessageBuilder.Initialize(FromValue, MessageValue);
        AgentTaskMessageBuilder.SetRequiresReview(false);
        AgentTaskBuilder.AddTaskMessage(AgentTaskMessageBuilder);

        if LoadResources then begin
            AttachmentsInput := QueryInput.ElementExists(AttachmentsTok, HasAttachments);
            if HasAttachments then
                for I := 0 to AttachmentsInput.GetElementCount() - 1 do begin
                    AgentTestResourceProvider.GetResource(
                        AttachmentsInput.ElementAt(I).Element(FileTok).ValueAsText(),
                        ResourceInStream, FileName, MIMEType);
                    AgentTaskMessageBuilder.AddAttachment(FileName, MIMEType, ResourceInStream);
                end;
        end;

        exit(CreateTaskAndWait(AgentTaskBuilder, AgentTask));
    end;

    procedure FinalizeTurn(var AgentTask: Record "Agent Task"; TurnSuccessful: Boolean; ErrorReason: Text) Continue: Boolean
    var
        AITTestContext: Codeunit "AIT Test Context";
    begin
        EnsureIsTest();
        WriteTurnToOutput(AgentTask, TurnSuccessful, ErrorReason);
        Commit();

        ValidateInterventionExpectation(AgentTask);
        if not TurnSuccessful then
            exit(false);

        exit(AITTestContext.NextTurn());
    end;

    local procedure ValidateInterventionExpectation(AgentTask: Record "Agent Task")
    var
        TempUserInterventionRequest: Record "Agent User Int Request Details" temporary;
        TempAnnotation: Record "Agent Annotation" temporary;
        TempSuggestion: Record "Agent Task User Int Suggestion" temporary;
        Assert: Codeunit "Library Assert";
        ExpectedInterventionRequest: Codeunit "Test Input Json";
        HasActualIntervention: Boolean;
        HasExpectedIntervention: Boolean;
        InterventionMustBeDeclared: Boolean;
    begin
        HasActualIntervention := RequiresUserIntervention(AgentTask);
        if HasActualIntervention then
            HasActualIntervention := GetLastUserInterventionRequestDetails(AgentTask, TempUserInterventionRequest, TempAnnotation, TempSuggestion);

        HasExpectedIntervention := GetExpectedInterventionRequest(ExpectedInterventionRequest);

        if HasExpectedIntervention and (not HasActualIntervention) then
            Assert.Fail(ExpectedInterventionNotFoundErr);

        InterventionMustBeDeclared := HasActualIntervention and (TempUserInterventionRequest.Type in [TempUserInterventionRequest.Type::Assistance, TempUserInterventionRequest.Type::ReviewRecord]);
        if InterventionMustBeDeclared and (not HasExpectedIntervention) then
            Assert.Fail(UnexpectedInterventionErr);

        if HasActualIntervention and HasExpectedIntervention then
            ValidateInterventionDetails(TempUserInterventionRequest, TempSuggestion, ExpectedInterventionRequest);
    end;

    local procedure ValidateInterventionDetails(
        TempUserInterventionRequest: Record "Agent User Int Request Details" temporary;
        var TempSuggestion: Record "Agent Task User Int Suggestion" temporary;
        ExpectedInterventionRequest: Codeunit "Test Input Json")
    var
        TypeInput, SuggestionsInput : Codeunit "Test Input Json";
        Assert: Codeunit "Library Assert";
        ExpectedType: Enum "Agent User Int Request Type";
        TypeExists, SuggestionsExist : Boolean;
        I: Integer;
    begin
        TypeInput := ExpectedInterventionRequest.ElementExists(TypeTok, TypeExists);
        if TypeExists then begin
            ExpectedType := ParseUserInterventionRequestType(TypeInput.ValueAsText());
            Assert.AreEqual(ExpectedType, TempUserInterventionRequest.Type,
                StrSubstNo(TypeMismatchErr, Format(ExpectedType), Format(TempUserInterventionRequest.Type)));
        end;

        SuggestionsInput := ExpectedInterventionRequest.ElementExists(SuggestionsTok, SuggestionsExist);
        if SuggestionsExist then begin
            // Each YAML suggestion code must exist in the actual TempSuggestion table
            for I := 0 to SuggestionsInput.GetElementCount() - 1 do begin
                TempSuggestion.SetRange(Code, CopyStr(SuggestionsInput.ElementAt(I).ValueAsText(), 1, MaxStrLen(TempSuggestion.Code)));
                Assert.IsFalse(TempSuggestion.IsEmpty(),
                    StrSubstNo(SuggestionMissingErr, SuggestionsInput.ElementAt(I).ValueAsText()));
                TempSuggestion.Reset();
            end;

            // Counts must match — no extra actual suggestions beyond what YAML declares
            Assert.AreEqual(SuggestionsInput.GetElementCount(), TempSuggestion.Count(),
                StrSubstNo(SuggestionCountMismatchErr, SuggestionsInput.GetElementCount(), TempSuggestion.Count()));
        end;
    end;

    procedure GetExpectedInterventionRequest(var ExpectedInterventionRequest: Codeunit "Test Input Json"): Boolean
    var
        AITTestContext: Codeunit "AIT Test Context";
        HasInterventionRequest: Boolean;
    begin
        EnsureIsTest();
        ExpectedInterventionRequest := AITTestContext.GetExpectedData().ElementExists(InterventionRequestTok, HasInterventionRequest);
        exit(HasInterventionRequest);
    end;

    procedure ValidateInterventionRequest(AgentTask: Record "Agent Task"; ExpectedInterventionRequest: Codeunit "Test Input Json")
    var
        TempUserInterventionRequest: Record "Agent User Int Request Details" temporary;
        TempAnnotation: Record "Agent Annotation" temporary;
        TempSuggestion: Record "Agent Task User Int Suggestion" temporary;
        TypeInput, SuggestionsInput : Codeunit "Test Input Json";
        Assert: Codeunit "Library Assert";
        ExpectedType: Enum "Agent User Int Request Type";
        TypeExists, SuggestionsExist : Boolean;
        I: Integer;
    begin
        EnsureIsTest();
        Assert.IsTrue(RequiresUserIntervention(AgentTask),
            StrSubstNo(NotPausedErr, Format(AgentTask.Status)));

        Assert.IsTrue(GetLastUserInterventionRequestDetails(AgentTask, TempUserInterventionRequest, TempAnnotation, TempSuggestion),
            StrSubstNo(NoRequestErr, Format(AgentTask.ID)));

        TypeInput := ExpectedInterventionRequest.ElementExists(TypeTok, TypeExists);
        if TypeExists then begin
            ExpectedType := ParseUserInterventionRequestType(TypeInput.ValueAsText());
            Assert.AreEqual(ExpectedType, TempUserInterventionRequest.Type,
                StrSubstNo(TypeMismatchErr, Format(ExpectedType), Format(TempUserInterventionRequest.Type)));
        end;

        SuggestionsInput := ExpectedInterventionRequest.ElementExists(SuggestionsTok, SuggestionsExist);
        if SuggestionsExist then
            for I := 0 to SuggestionsInput.GetElementCount() - 1 do begin
                TempSuggestion.SetRange(Code, CopyStr(SuggestionsInput.ElementAt(I).ValueAsText(), 1, MaxStrLen(TempSuggestion.Code)));
                Assert.IsFalse(TempSuggestion.IsEmpty(),
                    StrSubstNo(SuggestionMissingErr, SuggestionsInput.ElementAt(I).ValueAsText()));
                TempSuggestion.Reset();
            end;
    end;

    [InternalEvent(false, false)]
    local procedure OnWriteTaskToOutput(var AgentTask: Record "Agent Task"; var AgentTaskTestOutput: Codeunit "Test Output Json"; FromDateTime: DateTime)
    begin
    end;

    /// <summary>
    /// Ensures the current session is a test session. All publicly exposed methods should call this method.
    /// </summary>
    local procedure EnsureIsTest()
    var
        NotInTestErr: Label 'This method can only be called in a test context.';
    begin
        if not FeatureAccessManagement.IsTestSession() then
            Error(NotInTestErr);
    end;

    var
        FeatureAccessManagement: Codeunit "Feature Access Management";
        GlobalAgentTaskTimeout: Duration;
        AgentNotActiveErr: Label 'Agent with user security id %1 is not active.', Comment = '%1 = agent user security id';
        TimeoutExceedsMaximumErr: Label 'The specified timeout %1 exceeds the maximum allowed timeout of %2.', Comment = '%1 = specified timeout, %2 = maximum timeout';
        IdTok: Label 'id', Locked = true;
        TypeTok: Label 'type', Locked = true;
        StatusTok: Label 'status', Locked = true;
        MessagesTok: Label 'messages', Locked = true;
        ContentTok: Label 'content', Locked = true;
        CreatedDateTimeTok: Label 'createdDateTime', Locked = true;
        TimeoutCannotBeNegativeErr: Label 'The task timeout cannot be negative.';
        UserInterventionRequestTypeDoesNotExistErr: Label 'The user intervention request type "%1" does not exist.', Comment = '%1 = user intervention request type';
        InterventionTok: Label 'intervention', Locked = true;
        SuggestionTok: Label 'suggestion', Locked = true;
        InstructionTok: Label 'instruction', Locked = true;
        MessageTok: Label 'message', Locked = true;
        TitleTok: Label 'title', Locked = true;
        FromTok: Label 'from', Locked = true;
        AttachmentsTok: Label 'attachments', Locked = true;
        FileTok: Label 'file', Locked = true;
        InterventionRequestTok: Label 'intervention_request', Locked = true;

        SuggestionsTok: Label 'suggestions', Locked = true;
        InvalidQueryBothErr: Label 'Query cannot contain both ''title'' and ''intervention'' elements.';
        InvalidQueryNeitherErr: Label 'Query must contain either a ''title'' (task input) or ''intervention'' element.';
        InvalidInterventionErr: Label 'Intervention must contain either a ''suggestion'' or ''instruction'' element.';
        MissingTitleErr: Label 'Task input query must contain a ''title'' element.';
        NotPausedErr: Label 'Expected task to require user intervention but status is %1.', Comment = '%1 = task status';
        NoRequestErr: Label 'No user intervention request found on task %1.', Comment = '%1 = task ID';
        TypeMismatchErr: Label 'Expected intervention type %1 but got %2.', Comment = '%1 = expected type, %2 = actual type';
        SuggestionMissingErr: Label 'Expected suggestion "%1" not found in intervention request.', Comment = '%1 = suggestion code';
        SuggestionCountMismatchErr: Label 'Expected %1 suggestions but found %2 actual suggestions.', Comment = '%1 = expected count, %2 = actual count';
        UnexpectedInterventionErr: Label 'Task paused for user intervention but no intervention_request found in expected_data for this turn.';
        ExpectedInterventionNotFoundErr: Label 'Expected intervention_request in expected_data but the task did not pause for user intervention.';
}