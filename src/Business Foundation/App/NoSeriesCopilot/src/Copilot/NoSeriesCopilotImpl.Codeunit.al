codeunit 324 "No. Series Copilot Impl."
{
    var
        IncorrectCompletionErr: Label 'Incorrect completion. The property %1 is empty';
        IncorrectCompletionNumberOfGeneratedNoSeriesErr: Label 'Incorrect completion. The number of generated number series is incorrect. Expected %1, but got %2';
        TextLengthIsOverMaxLimitErr: Label 'The property %1 exceeds the maximum length of %2';
        DateSpecificPlaceholderLbl: label '{current_date}', Locked = true;
        NotAbleToGenerateNumberSeriesTryToRephraseErr: Label 'Sorry, I am not able to generate the number series. Try to rephrase your request or provide more details.';

    procedure Generate(var NoSeriesProposal: Record "No. Series Proposal"; var ResponseText: text; var NoSeriesGenerated: Record "No. Series Proposal Line"; InputText: Text)
    var
        SystemPromptTxt: SecretText;
        ToolsTxt: SecretText;
        CompletePromptTokenCount: Integer;
        Completion: Text;
        TokenCountImpl: Codeunit "AOAI Token";
    begin
        Clear(ResponseText);
        SystemPromptTxt := GetToolsSystemPrompt();
        ToolsTxt := GetToolsText();

        CompletePromptTokenCount := TokenCountImpl.GetGPT4TokenCount(SystemPromptTxt) + TokenCountImpl.GetGPT4TokenCount(ToolsTxt) + TokenCountImpl.GetGPT4TokenCount(InputText);
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
        RecRef.OPEN(NoSeriesGenerated."Setup Table No.");
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
    local procedure GetTools() ToolsList: List of [JsonObject]
    var
        ToolsJArray: JsonArray;
        ToolJToken: JsonToken;
        i: Integer;
    begin
        ToolsJArray.ReadFrom(GetToolsText());

        for i := 0 to ToolsJArray.Count - 1 do begin
            ToolsJArray.Get(i, ToolJToken);
            ToolsList.Add(ToolJToken.AsObject());
        end;
    end;

    [NonDebuggable]
    local procedure GetToolsText(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tools. The tools should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetToolsDefinitionFromIsolatedStorage())
    end;

    [NonDebuggable]
    internal procedure GenerateNoSeries(SystemPromptTxt: SecretText; InputText: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAi";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        CompletionAnswerTxt: Text;
        ToolJson: JsonObject;
    begin
        if not AzureOpenAI.IsEnabled(Enum::"Copilot Capability"::"No. Series Copilot") then
            exit;

        AzureOpenAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", GetEndpoint(), GetDeployment(), GetSecret());
        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"No. Series Copilot");
        AOAIChatCompletionParams.SetMaxTokens(MaxOutputTokens());
        AOAIChatCompletionParams.SetTemperature(0);
        AOAIChatMessages.SetPrimarySystemMessage(SystemPromptTxt.Unwrap());

        foreach ToolJson in GetTools() do
            AOAIChatMessages.AddTool(ToolJson);

        AOAIChatMessages.AddUserMessage(InputText);

        if not GenerateAndReviewToolSelectionOrAIAnswerWithRetry(AzureOpenAI, AOAIChatMessages, AOAIChatCompletionParams) then
            Error(GetLastErrorText());

        CompletionAnswerTxt := AOAIChatMessages.GetLastMessage();

        if AOAIChatMessages.IsToolsList(CompletionAnswerTxt) then
            CompletionAnswerTxt := CallTool(AzureOpenAI, AOAIChatMessages, AOAIChatCompletionParams, CompletionAnswerTxt);

        exit(CompletionAnswerTxt);
    end;

    local procedure GenerateAndReviewToolSelectionOrAIAnswerWithRetry(var AzureOpenAI: Codeunit "Azure OpenAi"; var AOAIChatMessages: Codeunit "AOAI Chat Messages"; var AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"): Boolean
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

            if not AOAIChatMessages.IsToolsList(AOAIChatMessages.GetLastMessage()) then // AI provided the answer, no need to call the tools
                exit(true);

            if IsExpectedToolsCount(AOAIChatMessages.GetLastMessage(), 1) then
                exit(true);

            AOAIChatMessages.DeleteMessage(AOAIChatMessages.GetHistory().Count); // remove the last message with wrong assistant response, as we need to regenerate the completion
            Sleep(500);
        end;

        exit(false);
    end;

    local procedure IsExpectedToolsCount(CompletionAnswerTxt: Text; ExpectedCount: Integer): Boolean
    var
        ToolsJArray: JsonArray;
    begin
        ToolsJArray.ReadFrom(CompletionAnswerTxt);
        exit(ToolsJArray.Count = ExpectedCount);
    end;

    local procedure CallTool(var AzureOpenAI: Codeunit "Azure OpenAi"; var AOAIChatMessages: Codeunit "AOAI Chat Messages"; var AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"; var CallToolNameAndParameters: Text): Text
    var
        ToolCallId: Text;
        FunctionName, FunctionArguments, ToolResponse : Text;
        ToolResponses: Dictionary of [Text, Integer]; // tool response can be a list of strings, as the response can be too long and exceed the token limit. In this case each string would be a separate message, each of them should be called separately. The integer is the number of tables used in the prompt, so we can test if the LLM answer covers all tables
        FinalResults: List of [Text]; // The final response will be the concatenation of all the LLM responses (final results).
        MaxToolResponseTokenLength, ExpectedNoSeriesCount, i : Integer;
        NewNumbersSeriesPrompts: Codeunit "No. Series Copilot New Impl.";
        ModifyNumbersSeriesPrompts: Codeunit "No. Series Copilot Modfy Impl.";
    begin
        // remove the tools from the chat messages, as they are not needed anymore
        AOAIChatMessages.ClearTools();

        MaxToolResponseTokenLength := MaxInputTokens() - AOAIChatMessages.GetHistoryTokenCount();

        AOAIChatMessages.ParseTool(CallToolNameAndParameters, FunctionName, FunctionArguments, ToolCallId, 0);
        case
            FunctionName of
            Format("No. Series Copilot Tool"::GetNewTablesAndPatterns):
                ToolResponses := NewNumbersSeriesPrompts.Build(FunctionArguments, MaxToolResponseTokenLength);
            Format("No. Series Copilot Tool"::GetExistingTablesAndPatterns):
                ToolResponses := ModifyNumbersSeriesPrompts.Build(FunctionArguments, MaxToolResponseTokenLength);
            else
                Error(NotAbleToGenerateNumberSeriesTryToRephraseErr);
        end;

        if ToolResponses.Count = 0 then
            Error(NotAbleToGenerateNumberSeriesTryToRephraseErr);

        AOAIChatMessages.SetPrimarySystemMessage(GetNoSeriesGenerationSystemPrompt());
        AOAIChatCompletionParams.SetJsonMode(true);

        foreach ToolResponse in ToolResponses.Keys() do begin
            // adding function response to messages
            AOAIChatMessages.AddToolMessage(ToolCallId, FunctionName, ToolResponse);

            // call the API again to get the final response from the model
            ToolResponses.Get(ToolResponse, ExpectedNoSeriesCount);
            if not GenerateAndReviewToolCompletionWithRetry(AzureOpenAI, AOAIChatMessages, AOAIChatCompletionParams, ExpectedNoSeriesCount) then
                Error(GetLastErrorText());

            FinalResults.Add(AOAIChatMessages.GetLastMessage());

            AOAIChatMessages.DeleteMessage(AOAIChatMessages.GetHistory().Count); // remove the last message, as it is not needed anymore
            AOAIChatMessages.DeleteMessage(AOAIChatMessages.GetHistory().Count); // remove the tools message, as it is not needed anymore

            Sleep(1000); // sleep for 1000ms, as the model can be called only limited number of times per second
        end;

        exit(ConcatenateToolResponse(FinalResults));
    end;

    local procedure GenerateAndReviewToolCompletionWithRetry(var AzureOpenAI: Codeunit "Azure OpenAi"; var AOAIChatMessages: Codeunit "AOAI Chat Messages"; var AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"; ExpectedNoSeriesCount: Integer): Boolean
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
            Error(StrSubstNo(IncorrectCompletionNumberOfGeneratedNoSeriesErr, ExpectedNoSeriesCount, ResultJArray.Count));
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
            Error(StrSubstNo(IncorrectCompletionErr, propertyName));
    end;

    local procedure CheckIntegerPropertyExistAndCheckIfNotEmpty(propertyName: Text; var Json: Codeunit Json)
    var
        value: Integer;
    begin
        Json.GetIntegerPropertyValueFromJObjectByName(propertyName, value);
        if value = 0 then
            Error(StrSubstNo(IncorrectCompletionErr, propertyName));
    end;

    local procedure CheckMaximumLengthOfPropertyValue(propertyName: Text; var Json: Codeunit Json; maxLength: Integer)
    var
        value: Text;
    begin
        Json.GetStringPropertyValueByName(propertyName, value);
        if StrLen(value) > maxLength then
            Error(StrSubstNo(TextLengthIsOverMaxLimitErr, propertyName, maxLength));
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
        ReAssambleDuplicates(NoSeriesArrText);

        Json.InitializeCollection(NoSeriesArrText);

        for i := 0 to Json.GetCollectionCount() - 1 do begin
            Json.GetObjectFromCollectionByIndex(i, NoSeriesObj);

            InsertNoSeriesGenerated(NoSeriesGenerated, NoSeriesObj, NoSeriesProposal."No.");
        end;
    end;

    local procedure ReAssambleDuplicates(var NoSeriesArrText: Text)
    var
        i: Integer;
        NoSeriesObj: Text;
        NoSeriesCodes: List of [Text];
        NoSeriesCode: Text;
        Json: Codeunit Json;
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


    local procedure InsertNoSeriesGenerated(var NoSeriesGenerated: Record "No. Series Proposal Line"; var NoSeriesObj: Text; ProposalNo: Integer)
    var
        Json: Codeunit Json;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        Json.InitializeObject(NoSeriesObj);

        RecRef.GetTable(NoSeriesGenerated);
        RecRef.Init();
        SetProposalNo(RecRef, ProposalNo, NoSeriesGenerated.FieldNo("Proposal No."));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'seriesCode', NoSeriesGenerated.FieldNo("Series Code"));
        Json.GetValueAndSetToRecFieldNo(RecRef, 'description', NoSeriesGenerated.FieldNo("Description"));
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
