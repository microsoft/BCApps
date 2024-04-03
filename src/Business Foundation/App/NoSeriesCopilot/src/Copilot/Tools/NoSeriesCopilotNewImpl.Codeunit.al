codeunit 331 "No. Series Copilot New Impl."
{
    Access = Internal;

    var
        ToolsImpl: Codeunit "No. Series Copilot Tools Impl.";

    /// <summary>
    /// Build the prompts for generating new number series.
    /// </summary>
    /// <param name="FunctionArguments">Function Arguments retrieved from LLM</param>
    /// <param name="MaxToolResultsTokensLength">Maximum number of tokens can be allocated for the result</param>
    /// <returns></returns>
    /// <remarks> This function is used to build the prompts for generating new number series. The prompts are built based on the tables and patterns specified in the input. If no tables are specified, all tables with number series are used. If no patterns are specified, default patterns are used. In case number of tables can't be pasted in one prompt, due to token limits, function chunk result into several messages, that need to be called separately</remarks>
    procedure Build(var FunctionArguments: Text; MaxToolResultsTokensLength: Integer) ToolResults: Dictionary of [Text, Integer]
    var
        NewNoSeriesPrompt, TablesPromptList, CustomPatternsPromptList, EmptyList : List of [Text];
        TablesBlockLbl: Label 'Tables:', Locked = true;
        NumberOfToolResponses, MaxTablesPromptListTokensLength, i, ActualTablesChunkSize : Integer;
        TokenCountImpl: Codeunit "AOAI Token";
    begin
        GetTablesPrompt(FunctionArguments, TablesPromptList);
        ToolsImpl.GetUserSpecifiedOrExistingNumberPatternsGuidelines(FunctionArguments, CustomPatternsPromptList, EmptyList, GetToolCustomPatternsGuidelines());

        MaxTablesPromptListTokensLength := MaxToolResultsTokensLength -
                                            TokenCountImpl.GetGPT4TokenCount(GetToolGeneralInstructions()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetToolLimitations()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetToolCodeGuidelines()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetToolDescrGuidelines()) -
                                            TokenCountImpl.GetGPT4TokenCount(GetToolNumberGuideline()) -
                                            TokenCountImpl.GetGPT4TokenCount(ToolsImpl.ConvertListToText(CustomPatternsPromptList)) -
                                            TokenCountImpl.GetGPT4TokenCount(GetToolOutputExamples()) -
                                            TokenCountImpl.GetGPT4TokenCount(Format(TablesBlockLbl)) -
                                            // we skip the token count of the tables, as that's what we are trying to calculate
                                            TokenCountImpl.GetGPT4TokenCount(GetToolOutputFormat());

        NumberOfToolResponses := Round(TablesPromptList.Count / ToolsImpl.GetTablesChunkSize(), 1, '>'); // we add tables by small chunks, as more tables can lead to hallucinations

        for i := 1 to NumberOfToolResponses do begin
            if TablesPromptList.Count > 0 then begin
                Clear(NewNoSeriesPrompt);
                Clear(ActualTablesChunkSize);
                NewNoSeriesPrompt.Add(GetToolGeneralInstructions());
                NewNoSeriesPrompt.Add(GetToolLimitations());
                NewNoSeriesPrompt.Add(GetToolCodeGuidelines());
                NewNoSeriesPrompt.Add(GetToolDescrGuidelines());
                NewNoSeriesPrompt.Add(GetToolNumberGuideline());
                NewNoSeriesPrompt.Add(ToolsImpl.ConvertListToText(CustomPatternsPromptList));
                NewNoSeriesPrompt.Add(GetToolOutputExamples());
                NewNoSeriesPrompt.Add(TablesBlockLbl);
                ToolsImpl.AddChunkedTablesPrompt(NewNoSeriesPrompt, TablesPromptList, MaxTablesPromptListTokensLength, ActualTablesChunkSize);
                NewNoSeriesPrompt.Add(GetToolOutputFormat());
                ToolResults.Add(ToolsImpl.ConvertListToText(NewNoSeriesPrompt), ActualTablesChunkSize);
            end
        end;
    end;

    local procedure GetTablesPrompt(var FunctionArguments: Text; var TablesPromptList: List of [Text])
    begin
        if ToolsImpl.CheckIfTablesSpecified(FunctionArguments) then
            ListOnlySpecifiedTables(TablesPromptList, ToolsImpl.GetEntities(FunctionArguments))
        else
            ListAllTablesWithNumberSeries(TablesPromptList);
    end;

    local procedure ListOnlySpecifiedTables(var TablesPromptList: List of [Text]; Entities: List of [Text])
    var
        TableMetadata: Record "Table Metadata";
    begin
        // Looping trhough all Setup tables
        ToolsImpl.SetFilterOnSetupTables(TableMetadata);
        if TableMetadata.FindSet() then
            repeat
                ListOnlyRelevantNoSeriesFields(TablesPromptList, TableMetadata, Entities);
            until TableMetadata.Next() = 0;
    end;

    local procedure ListOnlyRelevantNoSeriesFields(var TablesPromptList: List of [Text]; var TableMetadata: Record "Table Metadata"; Entities: List of [Text])
    var
        Field: Record "Field";
    begin
        ToolsImpl.SetFilterOnNoSeriesFields(TableMetadata, Field);
        if Field.FindSet() then
            repeat
                if ToolsImpl.IsRelevant(TableMetadata, Field, Entities) then
                    AddNewNoSeriesFieldToTablesPrompt(TablesPromptList, TableMetadata, Field);
            until Field.Next() = 0;
    end;

    local procedure ListAllTablesWithNumberSeries(var TablesPromptList: List of [Text])
    var
        TableMetadata: Record "Table Metadata";
    begin
        // Looping trhough all Setup tables
        ToolsImpl.SetFilterOnSetupTables(TableMetadata);
        if TableMetadata.FindSet() then
            repeat
                ListAllNoSeriesFields(TablesPromptList, TableMetadata);
            until TableMetadata.Next() = 0;
    end;

    local procedure ListAllNoSeriesFields(var TablesPromptList: List of [Text]; var TableMetadata: Record "Table Metadata")
    var
        Field: Record "Field";
    begin
        ToolsImpl.SetFilterOnNoSeriesFields(TableMetadata, Field);
        if Field.FindSet() then
            repeat
                AddNewNoSeriesFieldToTablesPrompt(TablesPromptList, TableMetadata, Field);
            until Field.Next() = 0;
    end;

    local procedure AddNewNoSeriesFieldToTablesPrompt(var TablesPromptList: List of [Text]; TableMetadata: Record "Table Metadata"; Field: Record "Field")
    begin
        TablesPromptList.Add('Area: ' + ToolsImpl.RemoveTextPart(TableMetadata.Caption, ' Setup') + ', TableId: ' + Format(TableMetadata.ID) + ', FieldId: ' + Format(Field."No.") + ', FieldName: ' + ToolsImpl.RemoveTextPart(Field.FieldName, ' Nos.'));
    end;

    [NonDebuggable]
    local procedure GetToolGeneralInstructions(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 general instructions. The tool 1 general instructions should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1GeneralInstructionsPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolLimitations(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 limitations. The tool 1 limitations should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1LimitationsPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolCodeGuidelines(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 code guidelines. The tool 1 code guidelines should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1CodeGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolDescrGuidelines(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 description guidelines. The tool 1 description guidelines should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1DescrGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolNumberGuideline(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 number guideline. The tool 1 number guideline should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1NumberGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolCustomPatternsGuidelines(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 custom patterns guidelines. The tool 1 custom patterns guidelines should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1CustomPatternsPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolOutputExamples(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 output examples. The tool 1 output examples should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1OutputExamplesPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolOutputFormat(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 1 output format. The tool 1 output format should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1OutputFormatPromptFromIsolatedStorage())
    end;
}