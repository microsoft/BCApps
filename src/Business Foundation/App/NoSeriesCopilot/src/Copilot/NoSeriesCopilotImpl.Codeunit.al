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
                CreateNoSeries(NoSeriesProposal, NoSeriesGenerated, Completion);
            end else
                ResponseText := Completion;
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
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetToolsDefinitionFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool1OutputFormat(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 output format definition. The tool 1 output format definition should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tool 1 output format definition from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1OutputFormatFromIsolatedStorage())
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

        if AOAIChatMessages.IsToolsList(CompletionAnswerTxt) then
            CompletionAnswerTxt := CallTool(AzureOpenAI, AOAIChatMessages, AOAIChatCompletionParams, CompletionAnswerTxt);

        exit(CompletionAnswerTxt);
    end;

    local procedure CallTool(var AzureOpenAI: Codeunit "Azure OpenAi"; var AOAIChatMessages: Codeunit "AOAI Chat Messages"; var AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"; var ToolDefinition: Text): Text
    var
        ToolCallId: Text;
        FunctionName: Text;
        FunctionArguments: Text;
        ToolResponse: Text;
        i: Integer;
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
    begin
        AOAIChatMessages.ParseTool(ToolDefinition, FunctionName, FunctionArguments, ToolCallId, 0);

        case
            FunctionName of
            'get_new_tables_and_patterns':
                ToolResponse := BuildGenerateNewNumbersSeriesPrompt(FunctionArguments);
            'get_existing_tables_and_patterns':
                ToolResponse := BuildModifyExistingNumbersSeriesPrompt(FunctionArguments);
            else
                Error('Function call not supported');
        end;

        if ToolResponse = '' then
            Error('Function call failed');

        // remove the tool message from the chat messages
        for i := 1 to AOAIChatMessages.GetTools().Count do
            AOAIChatMessages.DeleteTool(1); //when the tool is removed the index of the next tool is i-1, so the next tool should be removed with index 1

        AOAIChatCompletionParams.SetJsonMode(true);

        // adding function response to messages
        AOAIChatMessages.AddToolMessage(ToolCallId, FunctionName, ToolResponse);

        // call the API again to get the final response from the model
        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);
        if AOAIOperationResponse.IsSuccess() then
            exit(AOAIChatMessages.GetLastMessage())
        else
            Error(AOAIOperationResponse.GetError());
    end;

    local procedure BuildGenerateNewNumbersSeriesPrompt(var FunctionArguments: Text): Text
    var
        NewNoSeriesPrompt: TextBuilder;
        NewNumbersSeriesInstructionsLbl: Label 'Generate number series configurations based on the following table entries, ensuring each JSON object directly corresponds to one table entry. Use the Pattern Examples solely to inform the `startingNo`, `endingNo`, and `warningNo` fields based on the seriesCode relationship. Patterns are not to generate additional JSON objects.', Locked = true;
        NewNumbersSeriesPatternUsageInstructionsLbl: Label 'For `startingNo`, `endingNo`, and `warningNo` values, refer to these pattern examples, applying them based on their seriesCode:', Locked = true;
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        NewNoSeriesPrompt.AppendLine(NewNumbersSeriesInstructionsLbl);
        NewNoSeriesPrompt.AppendLine('Tables:');
        if CheckIfTablesSpecified(FunctionArguments) then
            ListOnlySpecifiedTables(NewNoSeriesPrompt, GetEntities(FunctionArguments))
        else
            ListAllTablesWithNumberSeries(NewNoSeriesPrompt);

        NewNoSeriesPrompt.AppendLine(NewNumbersSeriesPatternUsageInstructionsLbl);
        if CheckIfPatternSpecified(FunctionArguments) then
            NewNoSeriesPrompt.AppendLine(GetPattern(FunctionArguments))
        else
            ListDefaultOrExistingPattern(NewNoSeriesPrompt);

        NewNoSeriesPrompt.AppendLine(GetTool1OutputFormat());

        exit(NewNoSeriesPrompt.ToText());
    end;

    local procedure CheckIfTablesSpecified(var FunctionArguments: Text): Boolean
    begin
        exit(GetEntities(FunctionArguments).Count > 0);
    end;

    local procedure GetEntities(var FunctionArguments: Text): List of [Text]
    var
        Arguments: JsonObject;
        EntitiesToken: JsonToken;
        XpathLbl: Label '$.entities', Locked = true;
    begin
        if not Arguments.ReadFrom(FunctionArguments) then
            exit;

        if not Arguments.SelectToken(XpathLbl, EntitiesToken) then
            exit;

        exit(EntitiesToken.AsValue().AsText().Split());
    end;

    local procedure ListOnlySpecifiedTables(var NewNoSeriesPrompt: TextBuilder; Entities: List of [Text])
    begin
        //TODO: implement
        Error('Not implemented');
    end;

    local procedure ListAllTablesWithNumberSeries(var NewNoSeriesPrompt: TextBuilder)
    var
        TableMetadata: Record "Table Metadata";
        i: Integer;
    begin
        // Looping trhough all Setup tables
        TableMetadata.SetFilter(Name, '* Setup');
        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::No); //TODO: Check if 'Pending' should be included
        TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal);
        if TableMetadata.FindSet() then
            repeat
                ListAllNoSeriesFields(NewNoSeriesPrompt, TableMetadata, i);
            until TableMetadata.Next() = 0;
    end;

    local procedure ListAllNoSeriesFields(var NewNoSeriesPrompt: TextBuilder; var TableMetadata: Record "Table Metadata"; var AddedCount: Integer)
    var
        Field: Record "Field";
    begin
        Field.SetRange(TableNo, TableMetadata.ID);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetRange(Type, Field.Type::Code);
        Field.SetRange(Len, 20);
        Field.SetFilter(FieldName, '*Nos.'); //TODO: Check if this is the correct filter
        if Field.FindSet() then
            repeat
                if (AddedCount + 1) > 5 then  // TODO: Refactor this, probably send tables in chunks, as when there are many tables the prompt will reach the token limit and timeout
                    exit;

                NewNoSeriesPrompt.AppendLine('Area: ' + TableMetadata.Caption + ', TableId: ' + Format(TableMetadata.ID) + ', FieldId: ' + Format(Field."No.") + ', FieldName: ' + Field.FieldName);
                AddedCount += 1;
            until Field.Next() = 0;
    end;

    local procedure CheckIfPatternSpecified(var FunctionArguments: Text): Boolean
    begin
        exit(GetPattern(FunctionArguments) <> '');
    end;

    local procedure GetPattern(var FunctionArguments: Text): Text
    var
        Arguments: JsonObject;
        PatternToken: JsonToken;
        XpathLbl: Label '$.pattern', Locked = true;
    begin
        if not Arguments.ReadFrom(FunctionArguments) then
            exit;

        if not Arguments.SelectToken(XpathLbl, PatternToken) then
            exit;

        exit(PatternToken.AsValue().AsText());
    end;


    local procedure ListDefaultOrExistingPattern(var NewNoSeriesPrompt: TextBuilder): Text
    begin
        if CheckIfNumberSeriesExists() then
            ListExistingPattern(NewNoSeriesPrompt)
        else
            ListDefaultPattern(NewNoSeriesPrompt);
    end;

    local procedure CheckIfNumberSeriesExists(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        exit(not NoSeries.IsEmpty);
    end;

    local procedure ListExistingPattern(var NewNoSeriesPrompt: TextBuilder)
    var
        NoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit "No. Series";
        i: Integer;
    begin
        // show first 5 existing number series as example
        // TODO: Probably there is better way to show the existing number series, maybe by showing the most used ones, or the ones that are used in the same tables as the ones that are specified in the input
        if NoSeries.FindSet() then
            repeat
                NewNoSeriesPrompt.AppendLine('Code: ' + NoSeries.Code + ', Description: ' + NoSeries.Description + ', Pattern: ' + NoSeriesManagement.GetLastNoUsed(NoSeries.Code)); //TODO: Replace `GetLastNoUsed` with `GetStartingNo`
                if i > 5 then
                    break;
                i += 1;
            until NoSeries.Next() = 0;
    end;

    local procedure ListDefaultPattern(var NewNoSeriesPrompt: TextBuilder)
    begin
        // TODO: Probably there are better default patterns. These are taken from CRONUS USA, Inc. demo data
        NewNoSeriesPrompt.AppendLine('Code: CUST, Description: Customer, Pattern: C00001');
        NewNoSeriesPrompt.AppendLine('Code: GJNL-GEN, Description: General Journal, Pattern: G00001');
        NewNoSeriesPrompt.AppendLine('Code: P-CR, Description: Purchase Credit Memo, Pattern: 1001');
        NewNoSeriesPrompt.AppendLine('Code: P-CR+, Description: Posted Purchase Credit Memo, Pattern: 109001');
        NewNoSeriesPrompt.AppendLine('Code: S-ORD, Description: Sales Order, Pattern: S-ORD101001');
        NewNoSeriesPrompt.AppendLine('Code: SVC-INV+, Description: Posted Service Invoices, Pattern: PSVI000001');
    end;

    local procedure BuildModifyExistingNumbersSeriesPrompt(var FunctionCallParams: Text): Text
    begin
        Error('Not implemented');
    end;

    [TryFunction]
    local procedure CheckIfValidCompletion(var Completion: Text)
    begin
        ReadGeneratedNumberSeriesJArray(Completion);
    end;

    local procedure ReadGeneratedNumberSeriesJArray(var Completion: Text): JsonArray
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
        NoSeriesProposal."No." += 1;
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
        Json.InitializeCollection(NoSeriesArrText);

        for i := 0 to Json.GetCollectionCount() - 1 do begin
            Json.GetObjectFromCollectionByIndex(NoSeriesObj, i);

            InsertNoSeriesGenerated(NoSeriesGenerated, NoSeriesObj, NoSeriesProposal."No.");
        end;
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
