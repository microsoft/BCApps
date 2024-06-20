// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Telemetry;
using System.AI;
using System.Text.Json;

codeunit 324 "No. Series Copilot Impl."
{
    var
        IncorrectCompletionErr: Label 'Incorrect completion. The property %1 is empty', Comment = '%1 = property name';
        IncorrectCompletionNumberOfGeneratedNoSeriesErr: Label 'Incorrect completion. The number of generated number series is incorrect. Expected %1, but got %2', Comment = '%1 = Expected Number, %2 = Actual Number';
        TextLengthIsOverMaxLimitErr: Label 'The property %1 exceeds the maximum length of %2', Comment = '%1 = property name, %2 = maximum length';
        DateSpecificPlaceholderLbl: Label '{current_date}', Locked = true;
        NotAbleToGenerateNumberSeriesTryToRephraseErr: Label 'Sorry, I am not able to generate the number series. Try to rephrase your request or provide more details.';

    internal procedure GetNoSeriesSuggestions()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NoSeriesCopilotRegister: Codeunit "No. Series Copilot Register";
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        AzureOpenAI: Codeunit "Azure OpenAI";
        NoSeriesCopilot: Page "No. Series Proposal";
    begin
        NoSeriesCopilotRegister.RegisterCapability();
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"No. Series Copilot") then
            exit;

        FeatureTelemetry.LogUptake('0000LF4', NoSeriesCopilotImpl.FeatureName(), Enum::"Feature Uptake Status"::Discovered); //TODO: Update signal id

        NoSeriesCopilot.LookupMode := true;
        NoSeriesCopilot.Run();
    end;

    procedure Generate(var NoSeriesProposal: Record "No. Series Proposal"; var ResponseText: Text; var NoSeriesGenerated: Record "No. Series Proposal Line"; InputText: Text)
    var
        TokenCountImpl: Codeunit "AOAI Token";
        SystemPromptTxt: SecretText;
        CompletePromptTokenCount: Integer;
        Completion: Text;
    begin
        Clear(ResponseText);
        SystemPromptTxt := GetToolsSystemPrompt();

        CompletePromptTokenCount := TokenCountImpl.GetGPT4TokenCount(SystemPromptTxt) + TokenCountImpl.GetGPT4TokenCount(InputText);
        if CompletePromptTokenCount <= MaxInputTokens() then begin
            Completion := GenerateNoSeries(SystemPromptTxt, InputText);
            if CheckIfValidCompletion(Completion) then begin
                SaveGenerationHistory(NoSeriesProposal, InputText);
                CreateNoSeries(NoSeriesProposal, NoSeriesGenerated, Completion);
            end else
                ResponseText := Completion;
        end;
    end;

    procedure ApplyProposedNoSeries(var NoSeriesGenerated: Record "No. Series Proposal Line")
    begin
        if NoSeriesGenerated.FindSet() then
            repeat
                InsertNoSeriesWithLines(NoSeriesGenerated);
                ApplyNoSeriesToSetup(NoSeriesGenerated);
            until NoSeriesGenerated.Next() = 0;
    end;

    local procedure InsertNoSeriesWithLines(var NoSeriesGenerated: Record "No. Series Proposal Line")
    begin
        InsertNoSeries(NoSeriesGenerated);
        InsertNoSeriesLine(NoSeriesGenerated);
    end;

    local procedure InsertNoSeries(var NoSeriesGenerated: Record "No. Series Proposal Line")
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Init();
        NoSeries.Code := NoSeriesGenerated."Series Code";
        NoSeries.Description := NoSeriesGenerated.Description;
        NoSeries."Manual Nos." := true;
        NoSeries."Default Nos." := true;
        //TODO: Check if we need to add more fields here, like "Mask", "No. Series Type", "Reverse Sales VAT No. Series" etc.
        if not NoSeries.Insert(true) then
            NoSeries.Modify(true);
    end;

    local procedure InsertNoSeriesLine(var NoSeriesGenerated: Record "No. Series Proposal Line")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.Init();
        NoSeriesLine."Series Code" := NoSeriesGenerated."Series Code";
        NoSeriesLine."Line No." := GetNoSeriesLineNo(NoSeriesGenerated."Series Code");
        NoSeriesLine."Starting No." := NoSeriesGenerated."Starting No.";
        NoSeriesLine."Ending No." := NoSeriesGenerated."Ending No.";
        NoSeriesLine."Warning No." := NoSeriesGenerated."Warning No.";
        NoSeriesLine."Increment-by No." := NoSeriesGenerated."Increment-by No.";
        //TODO: Check if we need to add more fields here, like "Allow Gaps in Nos.", "Sequence Name" etc.
        if not NoSeriesLine.Insert(true) then
            NoSeriesLine.Modify(true);
    end;

    local procedure GetNoSeriesLineNo(SeriesCode: Code[20]): Integer
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        if not NoSeries.GetNoSeriesLine(NoSeriesLine, SeriesCode, 0D, true) then
            exit(1000);

        exit(NoSeriesLine."Line No."); // TODO: Check if we need to update existing no series line, or add a new one, e.g. if user requested to create no. series for the new year
    end;

    local procedure ApplyNoSeriesToSetup(var NoSeriesGenerated: Record "No. Series Proposal Line")
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(NoSeriesGenerated."Setup Table No.");
        if not RecRef.FindFirst() then
            exit;

        FieldRef := RecRef.Field(NoSeriesGenerated."Setup Field No.");
        FieldRef.Validate(NoSeriesGenerated."Series Code");
        RecRef.Modify(true);
    end;

    [NonDebuggable]
    local procedure GetNoSeriesGenerationSystemPrompt() SystemPrompt: Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the system prompt. The system prompt should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the system prompt from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        SystemPrompt := NoSeriesCopilotSetup.GetNoSeriesGenerationSystemPromptFromIsolatedStorage().Replace(DateSpecificPlaceholderLbl, Format(Today(), 0, 4));
    end;

    [NonDebuggable]
    local procedure GetToolsSystemPrompt() SystemPrompt: Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the system prompt. The system prompt should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the system prompt from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        SystemPrompt := NoSeriesCopilotSetup.GetToolsSystemPromptFromIsolatedStorage().Replace(DateSpecificPlaceholderLbl, Format(Today(), 0, 4));
    end;

    [NonDebuggable]
    local procedure GenerateNoSeries(SystemPromptTxt: SecretText; InputText: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AddNoSeriesIntent: Codeunit "No. Series Cop. Add Intent";
        ChangeNoSeriesIntent: Codeunit "No. Series Cop. Change Intent";
        CompletionAnswerTxt: Text;
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"No. Series Copilot") then
            exit;

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", GetEndpoint(), GetDeployment(), GetSecret());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"No. Series Copilot");
        AOAIChatCompletionParams.SetMaxTokens(MaxOutputTokens());
        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatMessages.SetPrimarySystemMessage(SystemPromptTxt.Unwrap());
        AOAIChatMessages.AddUserMessage(InputText);

        AOAIChatMessages.AddTool(AddNoSeriesIntent);
        AOAIChatMessages.AddTool(ChangeNoSeriesIntent);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if not AOAIOperationResponse.IsSuccess() then
            Error(AOAIOperationResponse.GetError());

        CompletionAnswerTxt := AOAIChatMessages.GetLastMessage();

        if AOAIOperationResponse.IsFunctionCall() then
            CompletionAnswerTxt := GenerateNoSeriesUsingToolResult(AzureOpenAI, AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        exit(CompletionAnswerTxt);
    end;

    local procedure GenerateNoSeriesUsingToolResult(var AzureOpenAI: Codeunit "Azure OpenAI"; var AOAIChatMessages: Codeunit "AOAI Chat Messages"; var AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"; var AOAIOperationResponse: Codeunit "AOAI Operation Response"): Text
    var
        AOAIFunctionResponse: Codeunit "AOAI Function Response";
        NoSeriesCopToolsImpl: Codeunit "No. Series Cop. Tools Impl.";
        ToolResponse: Text;
        ToolResponses: Dictionary of [Text, Integer]; // tool response can be a list of strings, as the response can be too long and exceed the token limit. In this case each string would be a separate message, each of them should be called separately. The integer is the number of tables used in the prompt, so we can test if the LLM answer covers all tables
        FinalResults: List of [Text]; // The final response will be the concatenation of all the LLM responses (final results).
        ExpectedNoSeriesCount: Integer;
        Progress: Dialog;
        GeneratingNoSeriesForLbl: Label 'Generating number series %1', Comment = '%1 = No. Series';
    begin
        // remove the tools from the chat messages, as they are not needed anymore
        AOAIChatMessages.ClearTools();

        AOAIFunctionResponse := AOAIOperationResponse.GetFunctionResponse();
        if not AOAIFunctionResponse.IsSuccess() then
            Error(AOAIFunctionResponse.GetError());

        ToolResponses := AOAIFunctionResponse.GetResult();

        if ToolResponses.Count = 0 then
            Error(NotAbleToGenerateNumberSeriesTryToRephraseErr);

        AOAIChatMessages.SetPrimarySystemMessage(GetNoSeriesGenerationSystemPrompt());
        AOAIChatCompletionParams.SetJsonMode(true);

        foreach ToolResponse in ToolResponses.Keys() do begin
            Progress.Open(StrSubstNo(GeneratingNoSeriesForLbl, NoSeriesCopToolsImpl.ExtractAreaWithPrefix(ToolResponse)));
            // adding function response to messages
            AOAIChatMessages.AddToolMessage(AOAIFunctionResponse.GetFunctionId(), AOAIFunctionResponse.GetFunctionName(), ToolResponse);

            // call the API again to get the final response from the model
            ToolResponses.Get(ToolResponse, ExpectedNoSeriesCount);
            if not GenerateAndReviewToolCompletionWithRetry(AzureOpenAI, AOAIChatMessages, AOAIChatCompletionParams, ExpectedNoSeriesCount) then
                Error(GetLastErrorText());

            FinalResults.Add(AOAIChatMessages.GetLastMessage());

            AOAIChatMessages.DeleteMessage(AOAIChatMessages.GetHistory().Count); // remove the last message, as it is not needed anymore
            AOAIChatMessages.DeleteMessage(AOAIChatMessages.GetHistory().Count); // remove the tools message, as it is not needed anymore

            Sleep(1000); // sleep for 1000ms, as the model can be called only limited number of times per second
            Progress.Close();
        end;

        exit(ConcatenateToolResponse(FinalResults));
    end;

    local procedure GenerateAndReviewToolCompletionWithRetry(var AzureOpenAI: Codeunit "Azure OpenAI"; var AOAIChatMessages: Codeunit "AOAI Chat Messages"; var AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"; ExpectedNoSeriesCount: Integer): Boolean
    var
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        MaxAttempts: Integer;
        Attempt: Integer;
    begin
        MaxAttempts := 3;
        for Attempt := 1 to MaxAttempts do begin
            AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
            if not AOAIOperationResponse.IsSuccess() then
                Error(AOAIOperationResponse.GetError());

            if CheckIfExpectedNoSeriesCount(AOAIChatMessages.GetLastMessage(), ExpectedNoSeriesCount) and CheckIfValidCompletion(AOAIChatMessages.GetLastMessage()) then
                exit(true);

            AOAIChatMessages.DeleteMessage(AOAIChatMessages.GetHistory().Count); // remove the last message with wrong assistant response, as we need to regenerate the completion
            Sleep(500);
        end;

        exit(false);
    end;

    [TryFunction]
    local procedure CheckIfExpectedNoSeriesCount(Completion: Text; ExpectedNoSeriesCount: Integer)
    var
        ResultJArray: JsonArray;
    begin
        ResultJArray := ReadGeneratedNumberSeriesJArray(Completion);
        if ResultJArray.Count <> ExpectedNoSeriesCount then
            Error(IncorrectCompletionNumberOfGeneratedNoSeriesErr, ExpectedNoSeriesCount, ResultJArray.Count);
    end;

    local procedure ConcatenateToolResponse(var FinalResults: List of [Text]) ConcatenatedResponse: Text
    var
        Result: Text;
        ResultJArray: JsonArray;
        JsonTok: JsonToken;
        JsonArr: JsonArray;
        JsonObj: JsonObject;
        i: Integer;
    begin
        foreach Result in FinalResults do begin
            ResultJArray := ReadGeneratedNumberSeriesJArray(Result);
            for i := 0 to ResultJArray.Count - 1 do begin
                ResultJArray.Get(i, JsonTok);
                JsonArr.Add(JsonTok);
            end;
        end;

        JsonObj.Add('noSeries', JsonArr);
        JsonObj.WriteTo(ConcatenatedResponse);
    end;

    [TryFunction]
    local procedure CheckIfValidCompletion(Completion: Text)
    var
        Json: Codeunit Json;
        NoSeriesArrText: Text;
        NoSeriesObj: Text;
        i: Integer;
    begin
        ReadGeneratedNumberSeriesJArray(Completion).WriteTo(NoSeriesArrText);
        Json.InitializeCollection(NoSeriesArrText);

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

    local procedure ReadGeneratedNumberSeriesJArray(Completion: Text): JsonArray
    var
        JsonObject: JsonObject;
        JsonArrayToken: JsonToken;
        XPathLbl: Label '$.noSeries', Locked = true;
    begin
        JsonObject.ReadFrom(Completion);
        JsonObject.SelectToken(XPathLbl, JsonArrayToken);
        exit(JsonArrayToken.AsArray());
    end;

    local procedure SaveGenerationHistory(var NoSeriesProposal: Record "No. Series Proposal"; InputText: Text)
    begin
        NoSeriesProposal.Init();
        NoSeriesProposal."No." := NoSeriesProposal.Count + 1;
        NoSeriesProposal.SetInputText(InputText);
        NoSeriesProposal.Insert(true);
    end;

    local procedure CreateNoSeries(var NoSeriesProposal: Record "No. Series Proposal"; var NoSeriesGenerated: Record "No. Series Proposal Line"; Completion: Text)
    var
        Json: Codeunit Json;
        NoSeriesArrText: Text;
        NoSeriesObj: Text;
        i: Integer;
    begin
        ReadGeneratedNumberSeriesJArray(Completion).WriteTo(NoSeriesArrText);
        ReAssembleDuplicates(NoSeriesArrText);

        Json.InitializeCollection(NoSeriesArrText);

        for i := 0 to Json.GetCollectionCount() - 1 do begin
            Json.GetObjectFromCollectionByIndex(i, NoSeriesObj);

            InsertNoSeriesGenerated(NoSeriesGenerated, NoSeriesObj, NoSeriesProposal."No.");
        end;
    end;

    local procedure ReAssembleDuplicates(var NoSeriesArrText: Text)
    var
        Json: Codeunit Json;
        i: Integer;
        NoSeriesObj: Text;
        NoSeriesCodes: List of [Text];
        NoSeriesCode: Text;
    begin
        Json.InitializeCollection(NoSeriesArrText);

        for i := 0 to Json.GetCollectionCount() - 1 do begin
            Json.GetObjectFromCollectionByIndex(i, NoSeriesObj);
            Json.InitializeObject(NoSeriesObj);
            Json.GetStringPropertyValueByName('seriesCode', NoSeriesCode);
            if NoSeriesCodes.Contains(NoSeriesCode) then begin
                Json.ReplaceOrAddJPropertyInJObject('seriesCode', GenerateNewSeriesCodeValue(NoSeriesCodes, NoSeriesCode));
                NoSeriesObj := Json.GetObjectAsText();
                Json.ReplaceJObjectInCollection(i, NoSeriesObj);
            end;
            NoSeriesCodes.Add(NoSeriesCode);
        end;

        NoSeriesArrText := Json.GetCollectionAsText()
    end;

    local procedure GenerateNewSeriesCodeValue(var NoSeriesCodes: List of [Text]; var NoSeriesCode: Text): Text
    var
        NewNoSeriesCode: Text;
    begin
        repeat
            NewNoSeriesCode := CopyStr(NoSeriesCode, 1, 18) + '-' + RandomCharacter();
        until not NoSeriesCodes.Contains(NewNoSeriesCode);

        NoSeriesCode := NewNoSeriesCode;
        exit(NewNoSeriesCode);
    end;

    local procedure RandomCharacter(): Char
    begin
        exit(RandIntInRange(33, 126)); // ASCII: ! (33) to ~ (126)
    end;

    local procedure RandIntInRange("Min": Integer; "Max": Integer): Integer
    begin
        exit(Min - 1 + Random(Max - Min + 1));
    end;


    local procedure InsertNoSeriesGenerated(var NoSeriesGenerated: Record "No. Series Proposal Line"; NoSeriesObj: Text; ProposalNo: Integer)
    var
        Json: Codeunit Json;
        RecRef: RecordRef;
    begin
        Json.InitializeObject(NoSeriesObj);

        RecRef.GetTable(NoSeriesGenerated);
        RecRef.Init();
        SetProposalNo(RecRef, ProposalNo, NoSeriesGenerated.FieldNo("Proposal No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'seriesCode', NoSeriesGenerated.FieldNo("Series Code"));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'description', NoSeriesGenerated.FieldNo(Description));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'startingNo', NoSeriesGenerated.FieldNo("Starting No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'endingNo', NoSeriesGenerated.FieldNo("Ending No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'warningNo', NoSeriesGenerated.FieldNo("Warning No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'incrementByNo', NoSeriesGenerated.FieldNo("Increment-by No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'tableId', NoSeriesGenerated.FieldNo("Setup Table No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'fieldId', NoSeriesGenerated.FieldNo("Setup Field No."));
        RecRef.Insert(true);
    end;

    local procedure SetProposalNo(var RecRef: RecordRef; GenerationId: Integer; FieldNo: Integer)
    var
        FieldRef: FieldRef;
    begin
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Value(GenerationId);
    end;

    /// <summary>
    /// Get the endpoint from the Azure Key Vault.
    /// This is a temporary solution to get the endpoint. The endpoint should be retrieved from the Azure Key Vault.
    /// </summary>
    /// <returns></returns>
    local procedure GetEndpoint(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        exit(NoSeriesCopilotSetup.GetEndpoint())
    end;

    /// <summary>
    /// Get the deployment from the Azure Key Vault.
    /// This is a temporary solution to get the deployment. The deployment should be retrieved from the Azure Key Vault.
    /// </summary>
    /// <returns></returns>
    local procedure GetDeployment(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        exit(NoSeriesCopilotSetup.GetDeployment())
    end;

    /// <summary>
    /// Get the secret from the Azure Key Vault.
    /// This is a temporary solution to get the secret. The secret should be retrieved from the Azure Key Vault.
    /// </summary>
    /// <returns></returns>
    [NonDebuggable]
    local procedure GetSecret(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetSecretKeyFromIsolatedStorage())
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
        exit(16385); //gpt-3.5-turbo-1106
    end;

    procedure FeatureName(): Text
    begin
        exit('Number Series with AI');
    end;
}
