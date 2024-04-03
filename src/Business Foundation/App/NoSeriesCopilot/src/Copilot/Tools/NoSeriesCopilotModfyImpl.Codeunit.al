codeunit 334 "No. Series Copilot Modfy Impl."
{
    Access = Internal;

    var
        ToolsImpl: Codeunit "No. Series Copilot Tools Impl.";
        SpecifyTablesErr: Label 'Please specify the tables for which you want to modify the number series.';

    /// <summary>
    /// Build the prompts for modifying existing number series.
    /// </summary>
    /// <param name="FunctionArguments">Function Arguments retrieved from LLM</param>
    /// <param name="MaxToolResultsTokensLength">Maximum number of tokens can be allocated for the result</param>
    /// <returns></returns>
    /// <remarks> This function is used to build the prompts for modifying existing series. The prompts are built based on the tables and patterns specified in the input. Tables should be specified. If no patterns are specified, default patterns are used. In case number of tables can't be pasted in one prompt, due to token limits, function chunk result into several messages, that need to be called separately</remarks>
    procedure Build(var FunctionArguments: Text; MaxToolResultsTokensLength: Integer) ToolResults: Dictionary of [Text, Integer]
    var
        ChangeNoSeriesPrompt, TablesPromptList, CustomPatternsPromptList, ExistingNoSeriesToChangeList : List of [Text];
        TablesBlockLbl: Label 'Tables:', Locked = true;
        NumberOfToolResponses, MaxTablesPromptListTokensLength, i, ActualTablesChunkSize : Integer;
        TokenCountImpl: Codeunit "AOAI Token";
    begin
        GetTablesPrompt(FunctionArguments, TablesPromptList, ExistingNoSeriesToChangeList);
        ToolsImpl.GetUserSpecifiedOrExistingNumberPatternsGuidelines(FunctionArguments, CustomPatternsPromptList, ExistingNoSeriesToChangeList, GetToolCustomPatternsGuidelines());

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
                Clear(ChangeNoSeriesPrompt);
                Clear(ActualTablesChunkSize);
                ChangeNoSeriesPrompt.Add(GetToolGeneralInstructions());
                ChangeNoSeriesPrompt.Add(GetToolLimitations());
                ChangeNoSeriesPrompt.Add(GetToolCodeGuidelines());
                ChangeNoSeriesPrompt.Add(GetToolDescrGuidelines());
                ChangeNoSeriesPrompt.Add(GetToolNumberGuideline());
                ChangeNoSeriesPrompt.Add(ToolsImpl.ConvertListToText(CustomPatternsPromptList));
                ChangeNoSeriesPrompt.Add(GetToolOutputExamples());
                ChangeNoSeriesPrompt.Add(TablesBlockLbl);
                ToolsImpl.AddChunkedTablesPrompt(ChangeNoSeriesPrompt, TablesPromptList, MaxTablesPromptListTokensLength, ActualTablesChunkSize);
                ChangeNoSeriesPrompt.Add(GetToolOutputFormat());
                ToolResults.Add(ToolsImpl.ConvertListToText(ChangeNoSeriesPrompt), ActualTablesChunkSize);
            end
        end;
    end;

    local procedure GetTablesPrompt(var FunctionArguments: Text; var TablesPromptList: List of [Text]; var ExistingNoSeriesToChangeList: List of [Text])
    begin
        if not ToolsImpl.CheckIfTablesSpecified(FunctionArguments) then
            Error(SpecifyTablesErr);

        ListOnlySpecifiedTablesWithExistingNumberSeries(TablesPromptList, ExistingNoSeriesToChangeList, ToolsImpl.GetEntities(FunctionArguments));
    end;

    local procedure ListOnlySpecifiedTablesWithExistingNumberSeries(var TablesPromptList: List of [Text]; var ExistingNoSeriesToChangeList: List of [Text]; Entities: List of [Text])
    var
        TableMetadata: Record "Table Metadata";
    begin
        // Looping trhough all Setup tables
        ToolsImpl.SetFilterOnSetupTables(TableMetadata);
        if TableMetadata.FindSet() then
            repeat
                ListOnlyRelevantNoSeriesFieldsWithExistingNumberSeries(TablesPromptList, ExistingNoSeriesToChangeList, TableMetadata, Entities);
            until TableMetadata.Next() = 0;
    end;

    local procedure ListOnlyRelevantNoSeriesFieldsWithExistingNumberSeries(var TablesPromptList: List of [Text]; var ExistingNoSeriesToChangeList: List of [Text]; var TableMetadata: Record "Table Metadata"; Entities: List of [Text])
    var
        Field: Record "Field";
        NoSeries: Record "No. Series";
    begin
        ToolsImpl.SetFilterOnNoSeriesFields(TableMetadata, Field);
        if Field.FindSet() then
            repeat
                if ToolsImpl.IsRelevant(TableMetadata, Field, Entities) then
                    AddChangeNoSeriesFieldToTablesPrompt(TablesPromptList, ExistingNoSeriesToChangeList, TableMetadata, Field);
            until Field.Next() = 0;
    end;

    local procedure AddChangeNoSeriesFieldToTablesPrompt(var TablesPromptList: List of [Text]; var ExistingNoSeriesToChangeList: List of [Text]; TableMetadata: Record "Table Metadata"; Field: Record "Field")
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        NoSeries: Record "No. Series";
    begin
        //TODO: Check if we need to check if the requested change no. series exists: should we give error or do nothing
        RecRef.OPEN(TableMetadata.ID);
        if not RecRef.FindFirst() then
            exit;

        FieldRef := RecRef.Field(Field."No.");
        if Format(FieldRef.Value) = '' then
            exit;

        if not NoSeries.Get(Format(FieldRef.Value)) then
            exit;

        TablesPromptList.Add('Area: ' + ToolsImpl.RemoveTextPart(TableMetadata.Caption, ' Setup') + ', TableId: ' + Format(TableMetadata.ID) + ', FieldId: ' + Format(Field."No.") + ', FieldName: ' + ToolsImpl.RemoveTextPart(Field.FieldName, ' Nos.') + ', seriesCode: ' + NoSeries.Code + ', description: ' + NoSeries.Description);
        ExistingNoSeriesToChangeList.Add(NoSeries.Code);
    end;

    [NonDebuggable]
    local procedure GetToolGeneralInstructions(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 general instructions. The tool 2 general instructions should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2GeneralInstructionsPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolLimitations(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 limitations. The tool 2 limitations should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2LimitationsPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolCodeGuidelines(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 code guidelines. The tool 2 code guidelines should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2CodeGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolDescrGuidelines(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 description guidelines. The tool 2 description guidelines should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2DescrGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolNumberGuideline(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 number guideline. The tool 2 number guideline should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2NumberGuidelinePromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolCustomPatternsGuidelines(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 custom patterns guidelines. The tool 2 custom patterns guidelines should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2CustomPatternsPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolOutputExamples(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 output examples. The tool 2 output examples should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2OutputExamplesPromptFromIsolatedStorage())
    end;

    [NonDebuggable]
    local procedure GetToolOutputFormat(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool 2 output format. The tool 2 output format should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2OutputFormatPromptFromIsolatedStorage())
    end;
}