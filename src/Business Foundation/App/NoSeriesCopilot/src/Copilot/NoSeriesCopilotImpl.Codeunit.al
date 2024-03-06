codeunit 324 "No. Series Copilot Impl."
{
    procedure Generate(var NoSeriesProposal: Record "No. Series Proposal"; var ResponseText: text; var NoSeriesGenerated: Record "No. Series Proposal Line"; InputText: Text)
    var
        SystemPromptTxt: Text;
        ToolsTxt: Text;
        CompletePromptTokenCount: Integer;
        Completion: Text;
        TokenCountImpl: Codeunit "AOAI Token";
    begin
        SystemPromptTxt := GetSystemPrompt();
        ToolsTxt := GetToolsText();

        CompletePromptTokenCount := TokenCountImpl.GetGPT4TokenCount(SystemPromptTxt) + TokenCountImpl.GetGPT4TokenCount(ToolsTxt) + TokenCountImpl.GetGPT4TokenCount(InputText);
        if CompletePromptTokenCount <= MaxInputTokens() then begin
            Completion := GenerateNoSeries(SystemPromptTxt, InputText);
            if CheckIfValidCompletion(Completion) then begin
                SaveGenerationHistory(NoSeriesProposal, InputText);
                // CreateNoSeries(NoSeriesProposal, NoSeriesGenerated, Completion);
                ResponseText := Completion;
            end;
        end;
    end;

    [NonDebuggable]
    local procedure GetSystemPrompt(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the system prompt. The system prompt should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the system prompt from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetSystemPromptFromIsolatedStorage());
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
        exit(NoSeriesCopilotSetup.GetFunctionsPromptFromIsolatedStorage())
    end;


    [NonDebuggable]
    internal procedure GenerateNoSeries(var SystemPromptTxt: Text; InputText: Text): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAi";
        AOAIDeployments: Codeunit "AOAI Deployments";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
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
        AOAIChatMessages.AddSystemMessage(SystemPromptTxt);

        foreach ToolJson in GetTools() do
            AOAIChatMessages.AddTool(ToolJson);

        AOAIChatMessages.AddUserMessage(InputText);
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if AOAIOperationResponse.IsSuccess() then
            CompletionAnswerTxt := AOAIChatMessages.GetLastMessage()
        else
            Error(AOAIOperationResponse.GetError());

        if CheckIfToolShouldBeCalled(CompletionAnswerTxt) then
            CompletionAnswerTxt := CallTool(AzureOpenAI, AOAIChatMessages, AOAIChatCompletionParams, CompletionAnswerTxt);

        exit(CompletionAnswerTxt);
    end;

    local procedure CheckIfToolShouldBeCalled(var CompletionAnswerTxt: Text): Boolean
    var
        JsonObj: JsonObject;
        FunctionCallNameToken: JsonToken;
        XPathFunctionCallNameLbl: Label '$.function_call.name', Comment = 'For more details on response, see https://aka.ms/AAlrz36', Locked = true;
    begin
        if not JsonObj.ReadFrom(CompletionAnswerTxt) then
            exit(false);

        exit(JsonObj.SelectToken(XPathFunctionCallNameLbl, FunctionCallNameToken));
    end;

    local procedure GetToolNameAndParams(var CompletionAnswerTxt: Text; var FunctionCallName: Text; var FunctionCallParams: Text)
    var
        JsonObj: JsonObject;
        FunctionCallNameToken: JsonToken;
        FunctionCallParamsToken: JsonToken;
        XPathFunctionCallNameLbl: Label '$.function_call.name', Comment = 'For more details on response, see https://aka.ms/AAlrz36', Locked = true;
        XPathFunctionCallParamsLbl: Label '$.function_call.arguments', Comment = 'For more details on response, see https://aka.ms/AAlrz36', Locked = true;
    begin
        if not JsonObj.ReadFrom(CompletionAnswerTxt) then
            exit;

        JsonObj.SelectToken(XPathFunctionCallNameLbl, FunctionCallNameToken);
        JsonObj.SelectToken(XPathFunctionCallParamsLbl, FunctionCallParamsToken);

        FunctionCallName := FunctionCallNameToken.AsValue().AsText();
        FunctionCallParams := FunctionCallParamsToken.AsValue().AsText();
    end;

    local procedure CallTool(var AzureOpenAI: Codeunit "Azure OpenAi"; var AOAIChatMessages: Codeunit "AOAI Chat Messages"; var AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"; var ToolDefinition: Text): Text
    var
        FunctionCallName: Text;
        FunctionCallParams: Text;
        ToolResponse: Text;
        ToolResponseMessageJson: JsonObject;
        ToolResponseMessage: Text;
        i: Integer;
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
    begin
        GetToolNameAndParams(ToolDefinition, FunctionCallName, FunctionCallParams);

        case
            FunctionCallName of
            'generate_new_numbers_series':
                ToolResponse := GenerateNewNumbersSeries(FunctionCallParams);
            'modify_existing_numbers_series':
                ToolResponse := ModifyExistingNumbersSeries(FunctionCallParams);
            else
                Error('Function call not supported');
        end;

        if ToolResponse = '' then
            Error('Function call failed');

        // remove the tool message from the chat messages
        for i := 1 to AOAIChatMessages.GetTools().Count do
            AOAIChatMessages.DeleteTool(i);

        // add the assistant response and function response to the messages
        AOAIChatMessages.AddAssistantMessage(ToolDefinition);

        // adding function response to messages
        ToolResponseMessageJson.Add('role', 'function');
        ToolResponseMessageJson.Add('name', FunctionCallName);
        ToolResponseMessageJson.Add('content', ToolResponse);
        ToolResponseMessageJson.WriteTo(ToolResponseMessage);
        AOAIChatMessages.AddAssistantMessage(ToolResponseMessage);

        // call the API again to get the final response from the model
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if AOAIOperationResponse.IsSuccess() then
            exit(AOAIChatMessages.GetLastMessage())
        else
            Error(AOAIOperationResponse.GetError());
    end;


    [TryFunction]
    local procedure CheckIfValidCompletion(var Completion: Text)
    var
        JsonArray: JsonArray;
    begin
        JsonArray.ReadFrom(Completion);
    end;

    local procedure SaveGenerationHistory(var NoSeriesProposal: Record "No. Series Proposal"; InputText: Text)
    begin
        NoSeriesProposal."No." += 1;
        NoSeriesProposal.SetInputText(InputText);
        NoSeriesProposal.Insert(true);
    end;

    // local procedure CreateNoSeries(var NoSeriesProposal: Record "No. Series Proposal"; var NoSeriesGenerated: Record "No. Series Proposal Line"; Completion: Text)
    // var
    //     JSONManagement: Codeunit "JSON Management";
    //     NoSeriesObj: Text;
    //     i: Integer;
    // begin
    //     JSONManagement.InitializeCollection(Completion);

    //     for i := 0 to JSONManagement.GetCollectionCount() - 1 do begin
    //         JSONManagement.GetObjectFromCollectionByIndex(NoSeriesObj, i);

    //         InsertNoSeriesGenerated(NoSeriesGenerated, NoSeriesObj, GenerationId.ID);
    //     end;
    // end;

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
        exit(8192); //gpt-4-0613
    end;

    procedure FeatureName(): Text
    begin
        exit('Number Series with AI');
    end;

}
