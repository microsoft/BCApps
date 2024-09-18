// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Telemetry;
using System.Azure.KeyVault;
using System.Environment;
using System.AI;
using System.Text.Json;

codeunit 324 "No. Series Copilot Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        IncorrectCompletionErr: Label 'Incorrect completion. The property %1 is empty', Comment = '%1 = property name';
        EmptyCompletionErr: Label 'Incorrect completion. The completion is empty.';
        IncorrectCompletionNumberOfGeneratedNoSeriesErr: Label 'Incorrect completion. The number of generated number series is incorrect. Expected %1, but got %2', Comment = '%1 = Expected Number, %2 = Actual Number';
        TextLengthIsOverMaxLimitErr: Label 'The property %1 exceeds the maximum length of %2', Comment = '%1 = property name, %2 = maximum length';
        DateSpecificPlaceholderLbl: Label '{current_date}', Locked = true;
        TheResponseShouldBeAFunctionCallErr: Label 'The response should be a function call.';
        ChatCompletionResponseErr: Label 'Sorry, something went wrong. Please rephrase and try again.';
        GeneratingNoSeriesForLbl: Label 'Generating number series %1', Comment = '%1 = No. Series';
        FeatureNameLbl: Label 'Number Series with AI', Locked = true;
        TelemetryToolsSelectionPromptRetrievalErr: Label 'Unable to retrieve the prompt for No. Series Copilot Tools Selection from Azure Key Vault.', Locked = true;
        ToolLoadingErr: Label 'Unable to load the No. Series Copilot Tool. Please try again later.';
        InvalidPromptTxt: Label 'Sorry, I couldn''t generate a good result from your input. Please rephrase and try again.';

    procedure GetNoSeriesSuggestions()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeriesCopilotRegister: Codeunit "No. Series Copilot Register";
        AzureOpenAI: Codeunit "Azure OpenAI";
    begin
        NoSeriesCopilotRegister.RegisterCapability();
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"No. Series Copilot") then
            exit;

        FeatureTelemetry.LogUptake('0000LF4', FeatureName(), Enum::"Feature Uptake Status"::Discovered);

        Page.Run(Page::"No. Series Generation");
    end;

    procedure Generate(var NoSeriesGeneration: Record "No. Series Generation"; var GeneratedNoSeries: Record "No. Series Generation Detail"; InputText: Text)
    var
        TokenCountImpl: Codeunit "AOAI Token";
        SystemPromptTxt: SecretText;
        CompletePromptTokenCount: Integer;
        Completion: Text;
    begin
        SystemPromptTxt := GetToolsSelectionSystemPrompt();

        CompletePromptTokenCount := TokenCountImpl.GetGPT35TokenCount(SystemPromptTxt) + TokenCountImpl.GetGPT35TokenCount(InputText);
        if CompletePromptTokenCount <= MaxInputTokens() then begin
            Completion := GenerateNoSeries(SystemPromptTxt, InputText);
            if CheckIfCompletionMeetAllRequirements(Completion) then begin
                SaveGenerationHistory(NoSeriesGeneration, InputText);
                CreateNoSeries(NoSeriesGeneration, GeneratedNoSeries, Completion);
            end else
                Error(InvalidPromptTxt);
        end else
            SendNotification(GetChatCompletionResponseErr());
    end;

    procedure ApplyGeneratedNoSeries(var GeneratedNoSeries: Record "No. Series Generation Detail")
    begin
        GeneratedNoSeries.SetRange(Exists, false);
        if GeneratedNoSeries.FindSet() then
            repeat
                InsertNoSeriesWithLines(GeneratedNoSeries);
                ApplyNoSeriesToSetup(GeneratedNoSeries);
            until GeneratedNoSeries.Next() = 0;
    end;

    local procedure InsertNoSeriesWithLines(var GeneratedNoSeries: Record "No. Series Generation Detail")
    begin
        InsertNoSeries(GeneratedNoSeries);
        InsertNoSeriesLine(GeneratedNoSeries);
    end;

    local procedure InsertNoSeries(var GeneratedNoSeries: Record "No. Series Generation Detail")
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Init();
        NoSeries.Code := GeneratedNoSeries."Series Code";
        NoSeries.Description := GeneratedNoSeries.Description;
        NoSeries."Manual Nos." := true;
        NoSeries."Default Nos." := true;
        if not NoSeries.Insert(true) then
            NoSeries.Modify(true);
    end;

    local procedure InsertNoSeriesLine(var GeneratedNoSeries: Record "No. Series Generation Detail")
    var
        NoSeriesLine: Record "No. Series Line";
        Implementation: Enum "No. Series Implementation";
    begin
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := GeneratedNoSeries."Series Code";
        NoSeriesLine."Line No." := GetNoSeriesLineNo(GeneratedNoSeries."Series Code", GeneratedNoSeries."Is Next Year");
        NoSeriesLine.Validate("Starting Date", GeneratedNoSeries."Starting Date");
        NoSeriesLine.Validate("Starting No.", GeneratedNoSeries."Starting No.");
        NoSeriesLine.Validate("Ending No.", GeneratedNoSeries."Ending No.");
        if GeneratedNoSeries."Warning No." <> '' then
            NoSeriesLine.Validate("Warning No.", GeneratedNoSeries."Warning No.");
        NoSeriesLine.Validate("Increment-by No.", GeneratedNoSeries."Increment-by No.");
        NoSeriesLine.Validate(Implementation, Implementation::Normal);
        if not NoSeriesLine.Insert(true) then
            NoSeriesLine.Modify(true);
    end;

    local procedure GetNoSeriesLineNo(SeriesCode: Code[20]; NewLineNo: Boolean): Integer
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        if not NoSeries.GetNoSeriesLine(NoSeriesLine, SeriesCode, 0D, true) then
            exit(10000);

        if NewLineNo then
            exit(NoSeriesLine."Line No." + 10000);

        exit(NoSeriesLine."Line No.");
    end;

    local procedure ApplyNoSeriesToSetup(var GeneratedNoSeries: Record "No. Series Generation Detail")
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(GeneratedNoSeries."Setup Table No.");
        if not RecRef.FindFirst() then
            exit;

        FieldRef := RecRef.Field(GeneratedNoSeries."Setup Field No.");
        FieldRef.Validate(GeneratedNoSeries."Series Code");
        RecRef.Modify(true);
    end;

    [NonDebuggable]
    local procedure GetToolsSelectionSystemPrompt() ToolsSelectionSystemPrompt: SecretText
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        Telemetry: Codeunit Telemetry;
        ToolsSelectionPrompt: Text;
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret('NoSeriesCopilotToolsSelectionPrompt', ToolsSelectionPrompt) then begin
            Telemetry.LogMessage('0000NDY', TelemetryToolsSelectionPromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            Error(ToolLoadingErr);
        end;

        ToolsSelectionSystemPrompt := ToolsSelectionPrompt.Replace(DateSpecificPlaceholderLbl, Format(Today(), 0, 4));
    end;

    local procedure GenerateNoSeries(SystemPromptTxt: SecretText; InputText: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AddNoSeriesIntent: Codeunit "No. Series Cop. Add Intent";
        ChangeNoSeriesIntent: Codeunit "No. Series Cop. Change Intent";
        AOAIDeployments: Codeunit "AOAI Deployments";
        NextYearNoSeriesIntent: Codeunit "No. Series Cop. Nxt Yr. Intent";
        CompletionAnswerTxt: Text;
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"No. Series Copilot") then
            exit;

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", AOAIDeployments.GetGPT4oLatest());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"No. Series Copilot");
        AOAIChatCompletionParams.SetMaxTokens(MaxOutputTokens());
        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatMessages.SetPrimarySystemMessage(SystemPromptTxt);
        AOAIChatMessages.AddUserMessage(InputText);

        AOAIChatMessages.AddTool(AddNoSeriesIntent);
        AOAIChatMessages.AddTool(ChangeNoSeriesIntent);
        AOAIChatMessages.AddTool(NextYearNoSeriesIntent);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if not AOAIOperationResponse.IsSuccess() then
            Error(AOAIOperationResponse.GetError());

        CompletionAnswerTxt := AOAIChatMessages.GetLastMessage(); // the model can answer to rephrase the question, if the user input is not clear

        if AOAIOperationResponse.IsFunctionCall() then
            CompletionAnswerTxt := GenerateNoSeriesUsingToolResult(AzureOpenAI, InputText, AOAIOperationResponse, AddNoSeriesIntent.GetExistingNoSeries());

        exit(CompletionAnswerTxt);
    end;

    [NonDebuggable]
    local procedure GenerateNoSeriesUsingToolResult(var AzureOpenAI: Codeunit "Azure OpenAI"; InputText: Text; var AOAIOperationResponse: Codeunit "AOAI Operation Response"; ExistingNoSeriesArray: Text): Text
    var
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        NoSeriesCopToolsImpl: Codeunit "No. Series Cop. Tools Impl.";
        NoSeriesGenerateTool: Codeunit "No. Series Cop. Generate";
        SystemPrompt: Text;
        ToolResponse: Dictionary of [Text, Integer]; // tool response can be a list of strings, as the response can be too long and exceed the token limit. In this case each string would be a separate message, each of them should be called separately. The integer is the number of tables used in the prompt, so we can test if the LLM answer covers all tables
        GeneratedNoSeriesArray: Text;
        FinalResults: List of [Text]; // The final response will be the concatenation of all the LLM responses (final results).
        FunctionResponses: List of [Codeunit "AOAI Function Response"];
        Progress: Dialog;
    begin
        if ExistingNoSeriesArray <> '' then
            FinalResults.Add(ExistingNoSeriesArray);

        FunctionResponses := AOAIOperationResponse.GetFunctionResponses();

        foreach AOAIFunctionResponse in FunctionResponses do begin
            if not AOAIFunctionResponse.IsSuccess() then
                Error(AOAIFunctionResponse.GetError());

            ToolResponse := AOAIFunctionResponse.GetResult();

            foreach SystemPrompt in ToolResponse.Keys() do begin
                Progress.Open(StrSubstNo(GeneratingNoSeriesForLbl, NoSeriesCopToolsImpl.ExtractAreaWithPrefix(SystemPrompt)));

                AOAIChatCompletionParams.SetTemperature(0);
                AOAIChatCompletionParams.SetMaxTokens(MaxOutputTokens());
                AOAIChatMessages.SetPrimarySystemMessage(SystemPrompt);
                AOAIChatMessages.AddUserMessage(InputText);
                AOAIChatMessages.AddTool(NoSeriesGenerateTool);
                AOAIChatMessages.SetToolChoice(NoSeriesGenerateTool.GetDefaultToolChoice());

                // call the API again to get the final response from the model
                if not GenerateAndReviewToolCompletionWithRetry(AzureOpenAI, AOAIChatMessages, AOAIChatCompletionParams, GeneratedNoSeriesArray, GetExpectedNoSeriesCount(ToolResponse, SystemPrompt)) then
                    Error(GetLastErrorText());

                FinalResults.Add(GeneratedNoSeriesArray);

                Clear(AOAIChatMessages);
                Progress.Close();
            end;
        end;
        exit(ConcatenateToolResponse(FinalResults));
    end;

    [NonDebuggable]
    local procedure GetExpectedNoSeriesCount(ToolResponse: Dictionary of [Text, Integer]; Message: Text) ExpectedNoSeriesCount: Integer
    begin
        ToolResponse.Get(Message, ExpectedNoSeriesCount);
    end;

    local procedure GenerateAndReviewToolCompletionWithRetry(var AzureOpenAI: Codeunit "Azure OpenAI"; var AOAIChatMessages: Codeunit "AOAI Chat Messages"; var AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"; var GeneratedNoSeriesArrayText: Text; ExpectedNoSeriesCount: Integer): Boolean
    var
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        MaxAttempts: Integer;
        Attempt: Integer;
    begin
        MaxAttempts := 3;
        for Attempt := 1 to MaxAttempts do begin
            AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
            if not AOAIOperationResponse.IsSuccess() then
                Error(AOAIOperationResponse.GetError());

            if not AOAIOperationResponse.IsFunctionCall() then
                Error(TheResponseShouldBeAFunctionCallErr);

            AOAIFunctionResponse := AOAIOperationResponse.GetFunctionResponses().Get(1); // There is only one tool
            if not AOAIFunctionResponse.IsSuccess() then
                Error(AOAIFunctionResponse.GetError());

            GeneratedNoSeriesArrayText := AOAIFunctionResponse.GetResult();
            if CheckIfValidResult(GeneratedNoSeriesArrayText, AOAIFunctionResponse.GetFunctionName(), ExpectedNoSeriesCount) then
                exit(true);

            AOAIChatMessages.DeleteMessage(AOAIChatMessages.GetHistory().Count); // remove the last message with wrong assistant response, as we need to regenerate the completion
            Sleep(500);
        end;

        exit(false);
    end;

    local procedure CheckIfValidResult(GeneratedNoSeriesArrayText: Text; FunctionName: Text; ExpectedNoSeriesCount: Integer): Boolean
    var
        AddNoSeriesIntent: Codeunit "No. Series Cop. Add Intent";
    begin
        if not CheckIfCompletionMeetAllRequirements(GeneratedNoSeriesArrayText) then
            exit(false);

        if FunctionName = AddNoSeriesIntent.GetName() then
            exit(CheckIfExpectedNoSeriesCount(GeneratedNoSeriesArrayText, ExpectedNoSeriesCount));

        exit(true);
    end;

    [TryFunction]
    local procedure CheckIfExpectedNoSeriesCount(GeneratedNoSeriesArrayText: Text; ExpectedNoSeriesCount: Integer)
    var
        ResultJArray: JsonArray;
        ResultedAccuracy: Decimal;
    begin
        ResultJArray := ReadGeneratedNumberSeriesJArray(GeneratedNoSeriesArrayText);
        if ResultJArray.Count = ExpectedNoSeriesCount then
            exit;
        if ExpectedNoSeriesCount = 0 then
            exit;

        ResultedAccuracy := ResultJArray.Count / ExpectedNoSeriesCount;
        if ResultedAccuracy < MinimumAccuracy() then
            Error(IncorrectCompletionNumberOfGeneratedNoSeriesErr, ExpectedNoSeriesCount, ResultJArray.Count);
    end;

    local procedure ConcatenateToolResponse(var FinalResults: List of [Text]) ConcatenatedResponse: Text
    var
        Result: Text;
        ResultJArray: JsonArray;
        JsonTok: JsonToken;
        JsonArr: JsonArray;
        i: Integer;
    begin
        foreach Result in FinalResults do begin
            ResultJArray := ReadGeneratedNumberSeriesJArray(Result);
            for i := 0 to ResultJArray.Count - 1 do begin
                ResultJArray.Get(i, JsonTok);
                JsonArr.Add(JsonTok);
            end;
        end;

        JsonArr.WriteTo(ConcatenatedResponse);
    end;

    [TryFunction]
    local procedure CheckIfCompletionMeetAllRequirements(GeneratedNoSeriesArrayText: Text)
    var
        Json: Codeunit Json;
        NoSeriesArrText: Text;
        NoSeriesObj: Text;
        i: Integer;
    begin
        ReadGeneratedNumberSeriesJArray(GeneratedNoSeriesArrayText).WriteTo(NoSeriesArrText);
        Json.InitializeCollection(NoSeriesArrText);
        CheckIfArrayIsNotEmpty(Json.GetCollectionCount());

        for i := 0 to Json.GetCollectionCount() - 1 do begin
            Json.GetObjectFromCollectionByIndex(i, NoSeriesObj);
            Json.InitializeObject(NoSeriesObj);
            CheckTextPropertyExistAndCheckIfNotEmpty('seriesCode', Json);
            CheckMaximumLengthOfPropertyValue('seriesCode', Json, 20);
            CheckTextPropertyExistAndCheckIfNotEmpty('description', Json);
            CheckTextPropertyExistAndCheckIfNotEmpty('startingNo', Json);
            CheckMaximumLengthOfPropertyValue('startingNo', Json, 20);
            CheckTextPropertyExistAndCheckIfNotEmpty('endingNo', Json);
            CheckMaximumLengthOfPropertyValue('endingNo', Json, 20);
            CheckTextPropertyExistAndCheckIfNotEmpty('warningNo', Json);
            CheckMaximumLengthOfPropertyValue('warningNo', Json, 20);
            CheckIntegerPropertyExistAndCheckIfNotEmpty('incrementByNo', Json);
            CheckIntegerPropertyExistAndCheckIfNotEmpty('tableId', Json);
            CheckIntegerPropertyExistAndCheckIfNotEmpty('fieldId', Json);
        end;
    end;

    local procedure CheckIfArrayIsNotEmpty(NumberOfGeneratedNoSeries: Integer)
    begin
        if NumberOfGeneratedNoSeries = 0 then
            Error(EmptyCompletionErr);
    end;

    local procedure CheckTextPropertyExistAndCheckIfNotEmpty(propertyName: Text; var Json: Codeunit Json)
    var
        value: Text;
    begin
        Json.GetStringPropertyValueByName(propertyName, value);
        if value = '' then
            Error(IncorrectCompletionErr, propertyName);
    end;

    local procedure CheckIntegerPropertyExistAndCheckIfNotEmpty(propertyName: Text; var Json: Codeunit Json)
    var
        PropertyValue: Integer;
    begin
        Json.GetIntegerPropertyValueFromJObjectByName(propertyName, PropertyValue);
        if PropertyValue = 0 then
            Error(IncorrectCompletionErr, propertyName);
    end;

    local procedure CheckMaximumLengthOfPropertyValue(propertyName: Text; var Json: Codeunit Json; maxLength: Integer)
    var
        value: Text;
    begin
        Json.GetStringPropertyValueByName(propertyName, value);
        if StrLen(value) > maxLength then
            Error(TextLengthIsOverMaxLimitErr, propertyName, maxLength);
    end;

    local procedure ReadGeneratedNumberSeriesJArray(Completion: Text) NoSeriesJArray: JsonArray
    begin
        NoSeriesJArray.ReadFrom(Completion);
        exit(NoSeriesJArray);
    end;

    local procedure SaveGenerationHistory(var NoSeriesGeneration: Record "No. Series Generation"; InputText: Text)
    begin
        NoSeriesGeneration.Init();
        NoSeriesGeneration."No." := NoSeriesGeneration.Count + 1;
        NoSeriesGeneration.SetInputText(InputText);
        NoSeriesGeneration.Insert(true);
    end;

    local procedure CreateNoSeries(var NoSeriesGeneration: Record "No. Series Generation"; var GeneratedNoSeries: Record "No. Series Generation Detail"; Completion: Text)
    var
        Json: Codeunit Json;
        NoSeriesArrText: Text;
        NoSeriesObj: Text;
        i: Integer;
    begin
        ReadGeneratedNumberSeriesJArray(Completion).WriteTo(NoSeriesArrText);
        ReassembleDuplicates(NoSeriesArrText);

        Json.InitializeCollection(NoSeriesArrText);

        for i := 0 to Json.GetCollectionCount() - 1 do begin
            Json.GetObjectFromCollectionByIndex(i, NoSeriesObj);

            InsertGeneratedNoSeries(GeneratedNoSeries, NoSeriesObj, NoSeriesGeneration."No.");
        end;
    end;

    local procedure ReassembleDuplicates(var NoSeriesArrText: Text)
    var
        Json: Codeunit Json;
        i: Integer;
        NoSeriesCodes: List of [Text];
    begin
        Json.InitializeCollection(NoSeriesArrText);

        for i := 0 to Json.GetCollectionCount() - 1 do
            ProcessNoSeries(i, NoSeriesCodes, Json);

        NoSeriesArrText := Json.GetCollectionAsText()
    end;

    local procedure ProcessNoSeries(i: Integer; var NoSeriesCodes: List of [Text]; var Json: Codeunit Json)
    var
        NoSeriesCode: Text;
        NoSeriesObj: Text;
        IsExists: Boolean;
    begin
        Json.GetObjectFromCollectionByIndex(i, NoSeriesObj);
        Json.InitializeObject(NoSeriesObj);
        Json.GetBoolPropertyValueFromJObjectByName('exists', IsExists);
        Json.GetStringPropertyValueByName('seriesCode', NoSeriesCode);

        if NoSeriesCodes.Contains(NoSeriesCode) and (not IsExists) then begin
            Json.RemoveJObjectFromCollection(i);
            exit;
        end;
        NoSeriesCodes.Add(NoSeriesCode);
    end;

    local procedure InsertGeneratedNoSeries(var GeneratedNoSeries: Record "No. Series Generation Detail"; NoSeriesObj: Text; GenerationNo: Integer)
    var
        Json: Codeunit Json;
        RecRef: RecordRef;
    begin
        Json.InitializeObject(NoSeriesObj);

        RecRef.GetTable(GeneratedNoSeries);
        RecRef.Init();
        SetGenerationNo(RecRef, GenerationNo, GeneratedNoSeries.FieldNo("Generation No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'seriesCode', GeneratedNoSeries.FieldNo("Series Code"));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'description', GeneratedNoSeries.FieldNo(Description));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'startingNo', GeneratedNoSeries.FieldNo("Starting No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'endingNo', GeneratedNoSeries.FieldNo("Ending No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'warningNo', GeneratedNoSeries.FieldNo("Warning No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'incrementByNo', GeneratedNoSeries.FieldNo("Increment-by No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'tableId', GeneratedNoSeries.FieldNo("Setup Table No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'fieldId', GeneratedNoSeries.FieldNo("Setup Field No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'nextYear', GeneratedNoSeries.FieldNo("Is Next Year"));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'exists', GeneratedNoSeries.FieldNo(Exists));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'message', GeneratedNoSeries.FieldNo(Message));
        if RecRef.Insert(true) then;

        ValidateGeneratedNoSeries(RecRef);
    end;

    local procedure ValidateGeneratedNoSeries(var RecRef: RecordRef)
    var
        GeneratedNoSeries: Record "No. Series Generation Detail";
    begin
        ValidateRecFieldNo(RecRef, GeneratedNoSeries.FieldNo("Is Next Year"));
        RecRef.Modify(true);
    end;

    local procedure ValidateRecFieldNo(var RecRef: RecordRef; FieldNo: Integer)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate();
    end;

    local procedure SetGenerationNo(var RecRef: RecordRef; GenerationId: Integer; FieldNo: Integer)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Value(GenerationId);
    end;

    local procedure MinimumAccuracy(): Decimal
    begin
        exit(0.9);
    end;

    local procedure MaxInputTokens(): Integer
    begin
        exit(MaxModelTokens() - MaxOutputTokens());
    end;

    local procedure MaxOutputTokens(): Integer
    begin
        exit(4096);
    end;

    local procedure MaxModelTokens(): Integer
    begin
        exit(16385); //gpt-4o-latest
    end;

    procedure IsCopilotVisible(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit(false);

        exit(true);
    end;

    procedure GetChatCompletionResponseErr(): Text
    begin
        exit(ChatCompletionResponseErr);
    end;

    local procedure GetNotificationId(): Guid
    begin
        exit('1fd2bfd6-6542-4574-8a88-f8247f4b8334');
    end;

    procedure RecallNotification()
    var
        Notification: Notification;
    begin
        Notification.Id := GetNotificationId();
        Notification.Recall();
    end;

    procedure SendNotification(NotificationMessage: Text)
    var
        Notification: Notification;
    begin
        Notification.Id := GetNotificationId();
        Notification.Scope := NotificationScope::LocalScope;
        Notification.Recall();
        Notification.Message := NotificationMessage;
        Notification.Send();
    end;

    procedure FeatureName(): Text
    begin
        exit(FeatureNameLbl);
    end;
}
