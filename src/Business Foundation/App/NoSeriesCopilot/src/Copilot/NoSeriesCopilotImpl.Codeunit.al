codeunit 324 "No. Series Copilot Impl."
{
    var
        IncorrectCompletionErr: Label 'Incorrect completion. The property %1 is empty';
        TextLengthIsOverMaxLimitErr: Label 'The property %1 exceeds the maximum length of %2';
        DateSpecificPromptLbl: label 'Today''s date is %1, which should be used for understanding the context of period-specific requests.', Locked = true;
        SpecifyTablesErr: Label 'Please specify the tables for which you want to modify the number series.';

    procedure Generate(var NoSeriesProposal: Record "No. Series Proposal"; var ResponseText: text; var NoSeriesGenerated: Record "No. Series Proposal Line"; InputText: Text)
    var
        SystemPromptTxt: SecretText;
        ToolsTxt: SecretText;
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

    procedure ApplyProposedNoSeries(var NoSeriesGenerated: Record "No. Series Proposal Line")
    begin
        //TODO: Implement the logic for applying the proposed number series
    end;

    [NonDebuggable]
    local procedure GetSystemPrompt() SystemPrompt: Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the system prompt. The system prompt should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the system prompt from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        SystemPrompt := NoSeriesCopilotSetup.GetSystemPromptFromIsolatedStorage();
        SystemPrompt += StrSubstNo(DateSpecificPromptLbl, Format(Today(), 0, 4));
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
    local procedure GetTool1GeneralInstructions(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 general instructions. The tool 1 general instructions should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1GeneralInstructionsPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool1Limitations(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 limitations. The tool 1 limitations should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1LimitationsPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool1CodeGuidelines(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 code guidelines. The tool 1 code guidelines should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1CodeGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool1DescrGuidelines(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 description guidelines. The tool 1 description guidelines should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1DescrGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool1NumberGuideline(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 number guideline. The tool 1 number guideline should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1NumberGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool1OutputExamples(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 output examples. The tool 1 output examples should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1OutputExamplesPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool1OutputFormat(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 output format. The tool 1 output format should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1OutputFormatPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool2GeneralInstructions(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 general instructions. The tool 2 general instructions should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2GeneralInstructionsPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool2Limitations(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 limitations. The tool 2 limitations should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2LimitationsPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool2CodeGuidelines(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 code guidelines. The tool 2 code guidelines should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2CodeGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool2DescrGuidelines(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 description guidelines. The tool 2 description guidelines should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2DescrGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool2NumberGuideline(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 number guideline. The tool 2 number guideline should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2NumberGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool2OutputExamples(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 output examples. The tool 2 output examples should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2OutputExamplesPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetTool2OutputFormat(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 output format. The tool 2 output format should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2OutputFormatPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    internal procedure GenerateNoSeries(SystemPromptTxt: SecretText; InputText: Text): Text
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
        AOAIChatMessages.AddSystemMessage(SystemPromptTxt.Unwrap());

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
        FunctionName, FunctionArguments, ToolResponse : Text;
        ToolResponses: Dictionary of [Text, Integer]; // tool response can be a list of strings, as the response can be too long and exceed the token limit. In this case each string would be a separate message, each of them should be called separately. The integer is the number of tables used in the prompt, so we can test if the LLM answer covers all tables
        FinalResults: List of [Text]; // The final response will be the concatenation of all the LLM responses (final results).        MaxToolResponseTokenLength, i : Integer;
        MaxToolResponseTokenLength, ExpectedNoSeriesCount, i : Integer;
    begin
        // remove the tools from the chat messages, as they are not needed anymore
        AOAIChatMessages.ClearTools();

        MaxToolResponseTokenLength := MaxInputTokens() - AOAIChatMessages.GetHistoryTokenCount();

        AOAIChatMessages.ParseTool(ToolDefinition, FunctionName, FunctionArguments, ToolCallId, 0);
        case
            FunctionName of
            'get_new_tables_and_patterns':
                ToolResponses := BuildGenerateNewNumbersSeriesPrompts(FunctionArguments, MaxToolResponseTokenLength);
            'get_existing_tables_and_patterns':
                ToolResponses := BuildModifyExistingNumbersSeriesPrompt(FunctionArguments, MaxToolResponseTokenLength);
            else
                Error('Function call not supported');
        end;

        if ToolResponses.Count = 0 then
            Error('Function call failed');

        AOAIChatCompletionParams.SetJsonMode(true);

        foreach ToolResponse in ToolResponses.Keys() do begin
            // adding function response to messages
            AOAIChatMessages.AddToolMessage(ToolCallId, FunctionName, ToolResponse);

            // call the API again to get the final response from the model
            ToolResponses.Get(ToolResponse, ExpectedNoSeriesCount);
            if not GenerateAndReviewToolCompletion(AzureOpenAI, AOAIChatMessages, AOAIChatCompletionParams, ExpectedNoSeriesCount) then
                Error(GetLastErrorText());

            FinalResults.Add(AOAIChatMessages.GetLastMessage());

            AOAIChatMessages.DeleteMessage(AOAIChatMessages.GetHistory().Count); // remove the last message, as it is not needed anymore
            AOAIChatMessages.DeleteMessage(AOAIChatMessages.GetHistory().Count); // remove the tools message, as it is not needed anymore

            Sleep(1000); // sleep for 1000ms, as the model can be called only limited number of times per second
        end;

        exit(ConcatenateToolResponse(FinalResults));
    end;

    /// <summary>
    /// Build the prompts for generating new number series.
    /// </summary>
    /// <param name="FunctionArguments">Function Arguments retrieved from LLM</param>
    /// <param name="MaxToolResultsTokensLength">Maximum number of tokens can be allocated for the result</param>
    /// <returns></returns>
    /// <remarks> This function is used to build the prompts for generating new number series. The prompts are built based on the tables and patterns specified in the input. If no tables are specified, all tables with number series are used. If no patterns are specified, default patterns are used. In case number of tables can't be pasted in one prompt, due to token limits, function chunk result into several messages, that need to be called separately</remarks>
    local procedure BuildGenerateNewNumbersSeriesPrompts(var FunctionArguments: Text; MaxToolResultsTokensLength: Integer) ToolResults: Dictionary of [Text, Integer]
    var
        NewNoSeriesPrompt, TablesPromptList, CustomPatternsPromptList : List of [Text];
        TablesBlockLbl: Label 'Tables:', Locked = true;
        NumberOfToolResponses, MaxTablesPromptListTokensLength, i, ActualTablesChunkSize : Integer;
        TokenCountImpl: Codeunit "AOAI Token";
    begin
        GetNewNumberSeriesTablesPrompt(FunctionArguments, TablesPromptList);
        GetUserSpecifiedOrExistingNumberPatternsGuidelines(FunctionArguments, CustomPatternsPromptList);

        MaxTablesPromptListTokensLength := MaxToolResultsTokensLength -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool1GeneralInstructions()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool1Limitations()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool1CodeGuidelines()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool1DescrGuidelines()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool1NumberGuideline()) -
                                            TokenCountImpl.GetGPT4TokenCount(ConvertListToText(CustomPatternsPromptList)) -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool1OutputExamples()) -
                                            TokenCountImpl.GetGPT4TokenCount(Format(TablesBlockLbl)) -
                                            // we skip the token count of the tables, as that's what we are trying to calculate
                                            TokenCountImpl.GetGPT4TokenCount(GetTool1OutputFormat());

        NumberOfToolResponses := Round(TablesPromptList.Count / GetTablesChunkSize(), 1, '>'); // we add tables by small chunks, as more tables can lead to hallucinations

        for i := 1 to NumberOfToolResponses do begin
            if TablesPromptList.Count > 0 then begin
                Clear(NewNoSeriesPrompt);
                Clear(ActualTablesChunkSize);
                NewNoSeriesPrompt.Add(GetTool1GeneralInstructions());
                NewNoSeriesPrompt.Add(GetTool1Limitations());
                NewNoSeriesPrompt.Add(GetTool1CodeGuidelines());
                NewNoSeriesPrompt.Add(GetTool1DescrGuidelines());
                NewNoSeriesPrompt.Add(GetTool1NumberGuideline());
                NewNoSeriesPrompt.Add(ConvertListToText(CustomPatternsPromptList));
                NewNoSeriesPrompt.Add(GetTool1OutputExamples());
                NewNoSeriesPrompt.Add(TablesBlockLbl);
                AddChunkedTablesPrompt(NewNoSeriesPrompt, TablesPromptList, MaxTablesPromptListTokensLength, ActualTablesChunkSize);
                NewNoSeriesPrompt.Add(GetTool1OutputFormat());
                ToolResults.Add(ConvertListToText(NewNoSeriesPrompt), ActualTablesChunkSize);
            end
        end;
    end;

    local procedure GetNewNumberSeriesTablesPrompt(var FunctionArguments: Text; var TablesPromptList: List of [Text])
    begin
        if CheckIfTablesSpecified(FunctionArguments) then
            ListOnlySpecifiedTables(TablesPromptList, GetEntities(FunctionArguments))
        else
            ListAllTablesWithNumberSeries(TablesPromptList);
    end;

    local procedure GetChangeNumberSeriesTablesPrompt(var FunctionArguments: Text; var TablesPromptList: List of [Text])
    begin
        if not CheckIfTablesSpecified(FunctionArguments) then
            Error(SpecifyTablesErr);

        ListOnlySpecifiedTablesWithExistingNumberSeries(TablesPromptList, GetEntities(FunctionArguments));
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

        exit(EntitiesToken.AsValue().AsText().Split(',')); // split the text by commas into a list of entities
    end;

    local procedure ListOnlySpecifiedTables(var TablesPromptList: List of [Text]; Entities: List of [Text])
    var
        TableMetadata: Record "Table Metadata";
    begin
        // Looping trhough all Setup tables
        SetFilterOnSetupTables(TableMetadata);
        if TableMetadata.FindSet() then
            repeat
                ListOnlyRelevantNoSeriesFields(TablesPromptList, TableMetadata, Entities);
            until TableMetadata.Next() = 0;
    end;

    local procedure ListOnlySpecifiedTablesWithExistingNumberSeries(var TablesPromptList: List of [Text]; Entities: List of [Text])
    var
        TableMetadata: Record "Table Metadata";
    begin
        // Looping trhough all Setup tables
        SetFilterOnSetupTables(TableMetadata);
        if TableMetadata.FindSet() then
            repeat
                ListOnlyRelevantNoSeriesFieldsWithExistingNumberSeries(TablesPromptList, TableMetadata, Entities);
            until TableMetadata.Next() = 0;
    end;

    local procedure ListOnlyRelevantNoSeriesFields(var TablesPromptList: List of [Text]; var TableMetadata: Record "Table Metadata"; Entities: List of [Text])
    var
        Field: Record "Field";
    begin
        SetFilterOnNoSeriesFields(TableMetadata, Field);
        if Field.FindSet() then
            repeat
                if IsRelevant(TableMetadata, Field, Entities) then
                    AddNewNoSeriesFieldToTablesPrompt(TablesPromptList, TableMetadata, Field);
            until Field.Next() = 0;
    end;

    local procedure ListOnlyRelevantNoSeriesFieldsWithExistingNumberSeries(var TablesPromptList: List of [Text]; var TableMetadata: Record "Table Metadata"; Entities: List of [Text])
    var
        Field: Record "Field";
        NoSeries: Record "No. Series";
    begin
        SetFilterOnNoSeriesFields(TableMetadata, Field);
        if Field.FindSet() then
            repeat
                if IsRelevant(TableMetadata, Field, Entities) then
                    AddChangeNoSeriesFieldToTablesPrompt(TablesPromptList, TableMetadata, Field);
            until Field.Next() = 0;
    end;

    local procedure IsRelevant(TableMetadata: Record "Table Metadata"; Field: Record "Field"; Entities: List of [Text]): Boolean
    var
        Entity: Text;
        String1: Text[250];
        String2: Text[250];
        Score: Decimal;
    begin
        //TODO: Replace this with embeddings, when Business Central supports it
        foreach Entity in Entities do begin
            String1 := RemoveShortWords(RemoveTextPart(TableMetadata.Caption, ' Setup') + ' ' + RemoveTextPart(Field.FieldName, ' Nos.'));
            String2 := RemoveShortWords(Entity);
            Score := CalculateStringNearness(String1, String2, 1, 100) / 100;
            if Score >= RequiredNearness() then
                exit(true);
        end;
        exit(false);
    end;

    local procedure RemoveShortWords(Text: Text[250]): Text[250];
    var
        Words: List of [Text];
        Word: Text[250];
        Result: Text[250];
    begin
        Words := Text.Split(' '); // split the text by spaces into a list of words
        foreach Word in Words do // loop through each word in the list
            if StrLen(Word) >= 3 then // check if the word length is at least 3
                Result += Word + ' '; // append the word and a space to the result
        Result := CopyStr(Result.TrimEnd(), 1, MaxStrLen(Result)); // remove the trailing space from the result
        Text := Result; // assign the result back to the text parameter
        exit(Text);
    end;

    //TODO: This is a copy of codeunit 1251 "Record Match Mgt." CalculateStringNearness(). It should be moved to a system app, or replaced with a system function
    /// <summary>
    /// Computes a nearness score between strings. Nearness is based on repeatedly finding longest common substrings.
    /// Substring matches below Threshold are not considered.
    /// Normalizing factor is the max value returned by this procedure.
    /// </summary>
    /// <param name="FirstString">First string to match</param>
    /// <param name="SecondString">Second string to match</param>
    /// <param name="Threshold">Substring matches below Threshold are not considered</param>
    /// <param name="NormalizingFactor">Max value returned by this procedure</param>
    /// <returns>A number between 0 and NormalizingFactor, representing how much of the strings was matched</returns>
    procedure CalculateStringNearness(FirstString: Text; SecondString: Text; Threshold: Integer; NormalizingFactor: Integer): Integer
    var
        Result: Text;
        TotalMatchedChars: Integer;
        MinLength: Integer;
        ShouldContinue: Boolean;
    begin
        if (FirstString = '') or (SecondString = '') then
            exit(0);

        FirstString := UpperCase(FirstString);
        SecondString := UpperCase(SecondString);

        MinLength := GetLengthOfShortestString(FirstString, SecondString);
        if MinLength = 0 then
            MinLength := 1;

        TotalMatchedChars := 0;
        Result := GetLongestCommonSubstring(FirstString, SecondString);
        ShouldContinue := IsSubstringConsideredForNearness(Result, Threshold);
        while ShouldContinue do begin
            TotalMatchedChars += StrLen(Result);
            FirstString := DelStr(FirstString, StrPos(FirstString, Result), StrLen(Result));
            SecondString := DelStr(SecondString, StrPos(SecondString, Result), StrLen(Result));
            Result := GetLongestCommonSubstring(FirstString, SecondString);
            ShouldContinue := IsSubstringConsideredForNearness(Result, Threshold);
        end;

        exit((NormalizingFactor * TotalMatchedChars) div MinLength);
    end;

    //TODO: This is a copy of codeunit 1251 "Record Match Mgt." GetLongestCommonSubstring(). It should be moved to a system app, or replaced with a system function
    procedure GetLongestCommonSubstring(FirstString: Text; SecondString: Text): Text
    var
        Result: Text;
        Buffer: Text;
        i: Integer;
        j: Integer;
    begin
        FirstString := UpperCase(FirstString);
        SecondString := UpperCase(SecondString);
        Result := '';

        i := 1;
        while i + StrLen(Result) - 1 <= StrLen(FirstString) do begin
            j := 1;
            while (j + i - 1 <= StrLen(FirstString)) and (j <= StrLen(SecondString)) do begin
                if StrPos(SecondString, CopyStr(FirstString, i, j)) > 0 then
                    Buffer := CopyStr(FirstString, i, j);

                if StrLen(Buffer) > StrLen(Result) then
                    Result := Buffer;
                Buffer := '';
                j += 1;
            end;
            i += 1;
        end;

        exit(Result);
    end;


    //TODO: This is a copy of codeunit 1251 "Record Match Mgt." GetLengthOfShortestString(). It should be moved to a system app, or replaced with a system function
    local procedure GetLengthOfShortestString(FirstString: Text; SecondString: Text): Integer
    begin
        exit((StrLen(FirstString) + StrLen(SecondString) - Abs(StrLen(FirstString) - StrLen(SecondString))) / 2);
    end;

    //TODO: This is a copy of codeunit 1251 "Record Match Mgt." IsSubstringConsideredForNearness(). It should be moved to a system app, or replaced with a system function
    local procedure IsSubstringConsideredForNearness(Substring: Text; MinThreshold: Integer): Boolean
    var
        Length: Integer;
    begin
        Length := StrLen(Substring);
        if Length <= 1 then
            exit(false);

        exit(MinThreshold <= Length);
    end;

    local procedure RequiredNearness(): Decimal
    begin
        exit(0.9)
    end;

    local procedure ListAllTablesWithNumberSeries(var TablesPromptList: List of [Text])
    var
        TableMetadata: Record "Table Metadata";
    begin
        // Looping trhough all Setup tables
        SetFilterOnSetupTables(TableMetadata);
        if TableMetadata.FindSet() then
            repeat
                ListAllNoSeriesFields(TablesPromptList, TableMetadata);
            until TableMetadata.Next() = 0;
    end;

    local procedure SetFilterOnSetupTables(var TableMetadata: Record "Table Metadata")
    begin
        TableMetadata.SetFilter(Name, '* Setup');
        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::No); //TODO: Check if 'Pending' should be included
        TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal);
    end;

    local procedure ListAllNoSeriesFields(var TablesPromptList: List of [Text]; var TableMetadata: Record "Table Metadata")
    var
        Field: Record "Field";
    begin
        SetFilterOnNoSeriesFields(TableMetadata, Field);
        if Field.FindSet() then
            repeat
                AddNewNoSeriesFieldToTablesPrompt(TablesPromptList, TableMetadata, Field);
            until Field.Next() = 0;
    end;

    local procedure AddNewNoSeriesFieldToTablesPrompt(var TablesPromptList: List of [Text]; TableMetadata: Record "Table Metadata"; Field: Record "Field")
    begin
        TablesPromptList.Add('Area: ' + RemoveTextPart(TableMetadata.Caption, ' Setup') + ', TableId: ' + Format(TableMetadata.ID) + ', FieldId: ' + Format(Field."No.") + ', FieldName: ' + RemoveTextPart(Field.FieldName, ' Nos.'));
    end;

    local procedure AddChangeNoSeriesFieldToTablesPrompt(var TablesPromptList: List of [Text]; TableMetadata: Record "Table Metadata"; Field: Record "Field")
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        NoSeries: Record "No. Series";
    begin
        //TODO: Check if we need to check if the requested change no. series exists: should we give error or do nothing
        RecRef.OPEN(TableMetadata.ID);
        if not RecRef.FindFirst() then
            exit;

        FieldRef := RecRef.FIELD(Field."No.");
        if Format(FieldRef.Value) = '' then
            exit;

        if not NoSeries.Get(Format(FieldRef.Value)) then
            exit;

        TablesPromptList.Add('Area: ' + RemoveTextPart(TableMetadata.Caption, ' Setup') + ', TableId: ' + Format(TableMetadata.ID) + ', FieldId: ' + Format(Field."No.") + ', FieldName: ' + RemoveTextPart(Field.FieldName, ' Nos.') + ', seriesCode: ' + NoSeries.Code + ', description: ' + NoSeries.Description);
    end;

    local procedure SetFilterOnNoSeriesFields(var TableMetadata: Record "Table Metadata"; var Field: Record "Field")
    begin
        Field.SetRange(TableNo, TableMetadata.ID);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetRange(Type, Field.Type::Code);
        Field.SetRange(Len, 20);
        Field.SetRange(RelationTableNo, Database::"No. Series");
    end;

    local procedure RemoveTextPart(Text: Text; PartToRemove: Text): Text
    begin
        exit(DelStr(Text, StrPos(Text, PartToRemove), StrLen(PartToRemove)));
    end;

    local procedure AddChunkedTablesPrompt(var FinalPrompt: List of [Text]; var TablesPromptList: List of [Text]; MaxTokensLength: Integer; var AddedCount: Integer)
    var
        TokenCountImpl: Codeunit "AOAI Token";
        TablePrompt: Text;
        IncludedTablePrompts: List of [Text];
    begin
        // we add by chunks of 10 tables, not to exceed the token limit, as more than 10 tables can lead to hallucinations
        foreach TablePrompt in TablesPromptList do
            if (AddedCount < GetTablesChunkSize()) and (TokenCountImpl.GetGPT4TokenCount(ConvertListToText(IncludedTablePrompts)) + TokenCountImpl.GetGPT4TokenCount(TablePrompt) < MaxTokensLength) then begin
                IncludedTablePrompts.Add(TablePrompt);
                AddedCount += 1;
            end;

        foreach TablePrompt in IncludedTablePrompts do begin
            FinalPrompt.Add(TablePrompt);
            TablesPromptList.Remove(TablePrompt);
        end;
    end;

    local procedure GetUserSpecifiedOrExistingNumberPatternsGuidelines(var FunctionArguments: Text; var CustomPatternsPromptList: List of [Text])
    var
        CustomGuidelinesPrefixLbl: label 'Custom Guidelines as specified by the user:', Locked = true;
        CustomGuidelinesPostfixLbl: label 'Apply these guidelines where relevant to ensure compliance with user requests.', Locked = true;
    begin
        CustomPatternsPromptList.Add(CustomGuidelinesPrefixLbl);
        //TODO: Not Tested. Need to test if the custom patterns are added to the prompt and how they influence the completion
        if CheckIfPatternSpecified(FunctionArguments) then
            CustomPatternsPromptList.Add(GetPattern(FunctionArguments))
        else
            AddExistingPatternIfExist(CustomPatternsPromptList);
        CustomPatternsPromptList.Add(CustomGuidelinesPostfixLbl);
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


    local procedure AddExistingPatternIfExist(var CustomPatternsPromptList: List of [Text]): Text
    begin
        if not CheckIfNumberSeriesExists() then
            exit;

        AddExistingPattern(CustomPatternsPromptList)
    end;

    local procedure CheckIfNumberSeriesExists(): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        exit(not NoSeries.IsEmpty);
    end;

    local procedure AddExistingPattern(var PatternsPromptList: List of [Text])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesManagement: Codeunit "No. Series";
        JsonObj: JsonObject;
        JsonArr: JsonArray;
        TextValue: Text;
        i: Integer;
    begin
        // show first 5 existing number series as example
        // TODO: Probably there is better way to show the existing number series, maybe by showing the most used ones, or the ones that are used in the same tables as the ones that are specified in the input
        if NoSeries.FindSet() then
            repeat
                NoSeriesManagement.GetNoSeriesLine(NoSeriesLine, NoSeries.Code, Today(), false);
                JsonObj.Add('seriesCode', NoSeries.Code);
                JsonObj.Add('description', NoSeries.Description);
                JsonObj.Add('startingNo', NoSeriesLine."Starting No.");
                JsonObj.Add('endingNo', NoSeriesLine."Ending No.");
                JsonObj.Add('warningNo', NoSeriesLine."Warning No.");
                JsonObj.Add('incrementByNo', NoSeriesLine."Increment-by No.");
                JsonArr.Add(JsonObj);
                if i > 5 then
                    break;
                i += 1;
            until NoSeries.Next() = 0;

        if JsonArr.Count = 0 then
            exit;

        Clear(JsonObj);
        JsonObj.Add('noSeries', JsonArr);
        JsonObj.WriteTo(TextValue);

        PatternsPromptList.Add(TextValue);
    end;

    local procedure BuildModifyExistingNumbersSeriesPrompt(var FunctionArguments: Text; MaxToolResultsTokensLength: Integer) ToolResults: Dictionary of [Text, Integer]
    var
        ChangeNoSeriesPrompt, TablesPromptList, CustomPatternsPromptList : List of [Text];
        TablesBlockLbl: Label 'Tables:', Locked = true;
        NumberOfToolResponses, MaxTablesPromptListTokensLength, i, ActualTablesChunkSize : Integer;
        TokenCountImpl: Codeunit "AOAI Token";
    begin
        GetChangeNumberSeriesTablesPrompt(FunctionArguments, TablesPromptList);
        GetUserSpecifiedOrExistingNumberPatternsGuidelines(FunctionArguments, CustomPatternsPromptList);

        MaxTablesPromptListTokensLength := MaxToolResultsTokensLength -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool2GeneralInstructions()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool2Limitations()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool2CodeGuidelines()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool2DescrGuidelines()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool2NumberGuideline()) -
                                            TokenCountImpl.GetGPT4TokenCount(ConvertListToText(CustomPatternsPromptList)) -
                                            TokenCountImpl.GetGPT4TokenCount(GetTool2OutputExamples()) -
                                            TokenCountImpl.GetGPT4TokenCount(Format(TablesBlockLbl)) -
                                            // we skip the token count of the tables, as that's what we are trying to calculate
                                            TokenCountImpl.GetGPT4TokenCount(GetTool2OutputFormat());

        NumberOfToolResponses := Round(TablesPromptList.Count / GetTablesChunkSize(), 1, '>'); // we add tables by small chunks, as more tables can lead to hallucinations

        for i := 1 to NumberOfToolResponses do begin
            if TablesPromptList.Count > 0 then begin
                Clear(ChangeNoSeriesPrompt);
                Clear(ActualTablesChunkSize);
                ChangeNoSeriesPrompt.Add(GetTool2GeneralInstructions());
                ChangeNoSeriesPrompt.Add(GetTool2Limitations());
                ChangeNoSeriesPrompt.Add(GetTool2CodeGuidelines());
                ChangeNoSeriesPrompt.Add(GetTool2DescrGuidelines());
                ChangeNoSeriesPrompt.Add(GetTool2NumberGuideline());
                ChangeNoSeriesPrompt.Add(ConvertListToText(CustomPatternsPromptList));
                ChangeNoSeriesPrompt.Add(GetTool2OutputExamples());
                ChangeNoSeriesPrompt.Add(TablesBlockLbl);
                AddChunkedTablesPrompt(ChangeNoSeriesPrompt, TablesPromptList, MaxTablesPromptListTokensLength, ActualTablesChunkSize);
                ChangeNoSeriesPrompt.Add(GetTool2OutputFormat());
                ToolResults.Add(ConvertListToText(ChangeNoSeriesPrompt), ActualTablesChunkSize);
            end
        end;
    end;

    local procedure ConvertListToText(MyList: List of [Text]): Text
    var
        Element: Text;
        Result: TextBuilder;
    begin
        foreach Element in MyList do
            Result.AppendLine(Element);

        exit(Result.ToText());
    end;

    local procedure GenerateAndReviewToolCompletion(var AzureOpenAI: Codeunit "Azure OpenAi"; var AOAIChatMessages: Codeunit "AOAI Chat Messages"; var AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params"; ExpectedNoSeriesCount: Integer): Boolean
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

            if IsExpectedNoSeriesCount(AOAIChatMessages.GetLastMessage(), ExpectedNoSeriesCount) and CheckIfValidCompletion(AOAIChatMessages.GetLastMessage()) then
                exit(true);

            AOAIChatMessages.DeleteMessage(AOAIChatMessages.GetHistory().Count); // remove the last message with wrong assistant response, as we need to regenerate the completion
            Sleep(500);
        end;

        exit(false);
    end;

    local procedure IsExpectedNoSeriesCount(Completion: Text; ExpectedNoSeriesCount: Integer): Boolean
    var
        ResultJArray: JsonArray;
    begin
        ResultJArray := ReadGeneratedNumberSeriesJArray(Completion);
        exit(ResultJArray.Count = ExpectedNoSeriesCount);
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

    local procedure GetTablesChunkSize(): Integer
    begin
        exit(10);
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
