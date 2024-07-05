// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.AI;
using System.Reflection;
using System.Utilities;

codeunit 331 "No. Series Cop. Add Intent" implements "AOAI Function"
{
    Access = Internal;

    var
        ToolsImpl: Codeunit "No. Series Cop. Tools Impl.";
        FunctionNameLbl: Label 'GetNewTablesAndPatterns', Locked = true;
        DateSpecificPlaceholderLbl: Label '{current_date}', Locked = true;
        CustomPatternsPlaceholderLbl: Label '{custom_patterns}', Locked = true;
        TablesYamlFormatPlaceholderLbl: Label '{tables_yaml_format}', Locked = true;
        NumberOfAddedTablesPlaceholderLbl: Label '{number_of_tables}', Locked = true;

    procedure GetName(): Text
    begin
        exit(FunctionNameLbl);
    end;

    [NonDebuggable]
    procedure GetPrompt() Function: JsonObject;
    begin
        Function.ReadFrom(GetToolDefinition());
    end;

    [NonDebuggable]
    procedure Execute(Arguments: JsonObject): Variant
    begin
        exit(Build(Arguments));
    end;

    /// <summary>
    /// Build the prompts for generating new number series.
    /// </summary>
    /// <param name="Arguments">Function Arguments retrieved from LLM</param>
    /// <returns></returns>
    /// <remarks> This function is used to build the prompts for generating new number series. The prompts are built based on the tables and patterns specified in the input. If no tables are specified, all tables with number series are used. If no patterns are specified, default patterns are used. In case number of tables can't be pasted in one prompt, due to token limits, function chunk result into several messages, that need to be called separately</remarks>
    [NonDebuggable]
    local procedure Build(var Arguments: JsonObject) ToolResults: Dictionary of [Text, Integer]
    var
        NewNoSeriesPrompt, CustomPatternsPromptList, TablesYamlList, EmptyList : List of [Text];
        NumberOfToolResponses, i, ActualTablesChunkSize : Integer;
        TempSetupTable: Record "Table Metadata" temporary;
        TempNoSeriesField: Record "Field" temporary;
        NumberOfAddedTables: Integer;
    begin
        GetTablesRequireNoSeries(Arguments, TempSetupTable, TempNoSeriesField);
        ToolsImpl.GetUserSpecifiedOrExistingNumberPatternsGuidelines(Arguments, CustomPatternsPromptList, EmptyList);

        NumberOfAddedTables := TempNoSeriesField.Count();
        NumberOfToolResponses := Round(NumberOfAddedTables / ToolsImpl.GetMaxNumberOfTablesInOneChunk(), 1, '>'); // we add tables by small chunks, as more tables can lead to hallucinations

        for i := 1 to NumberOfToolResponses do
            if NumberOfAddedTables > 0 then begin
                Clear(NewNoSeriesPrompt);
                Clear(ActualTablesChunkSize);
                ToolsImpl.GenerateChunkedTablesListInYamlFormat(TablesYamlList, TempSetupTable, TempNoSeriesField, ActualTablesChunkSize);
                NewNoSeriesPrompt.Add(GetToolPrompt().Replace(DateSpecificPlaceholderLbl, Format(Today(), 0, 4))
                                                     .Replace(CustomPatternsPlaceholderLbl, ToolsImpl.ConvertListToText(CustomPatternsPromptList))
                                                     .Replace(TablesYamlFormatPlaceholderLbl, ToolsImpl.ConvertListToText(TablesYamlList))
                                                     .Replace(NumberOfAddedTablesPlaceholderLbl, Format(ActualTablesChunkSize)));

                ToolResults.Add(ToolsImpl.ConvertListToText(NewNoSeriesPrompt), ActualTablesChunkSize);
            end
    end;

    local procedure GetTablesRequireNoSeries(var Arguments: JsonObject; var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary)
    begin
        if ToolsImpl.CheckIfTablesSpecified(Arguments) then
            ListOnlySpecifiedTables(TempSetupTable, TempNoSeriesField, ToolsImpl.GetEntities(Arguments))
        else
            ListAllTablesWithNumberSeries(TempSetupTable, TempNoSeriesField);
    end;

    local procedure ListOnlySpecifiedTables(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; Entities: List of [Text])
    var
        TempTableMetadata: Record "Table Metadata" temporary;
    begin
        // Looping through all Setup tables
        ToolsImpl.RetrieveSetupTables(TempTableMetadata);
        if TempTableMetadata.FindSet() then
            repeat
                ListOnlyRelevantNoSeriesFields(TempSetupTable, TempNoSeriesField, TempTableMetadata, Entities);
            until TempTableMetadata.Next() = 0;
    end;

    local procedure ListOnlyRelevantNoSeriesFields(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var TempTableMetadata: Record "Table Metadata" temporary; Entities: List of [Text])
    var
        Field: Record "Field";
    begin
        // Looping through all No. Series fields
        ToolsImpl.SetFilterOnNoSeriesFields(TempTableMetadata, Field);
        if Field.FindSet() then
            repeat
                if ToolsImpl.IsRelevant(TempTableMetadata, Field, Entities) then
                    AddNewNoSeriesFieldToTablesList(TempSetupTable, TempNoSeriesField, TempTableMetadata, Field);
            until Field.Next() = 0;
    end;

    local procedure ListAllTablesWithNumberSeries(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary)
    var
        TempTableMetadata: Record "Table Metadata" temporary;
    begin
        // Looping through all Setup tables
        ToolsImpl.RetrieveSetupTables(TempTableMetadata);
        if TempTableMetadata.FindSet() then
            repeat
                ListAllNoSeriesFields(TempSetupTable, TempNoSeriesField, TempTableMetadata);
            until TempTableMetadata.Next() = 0;
    end;

    local procedure ListAllNoSeriesFields(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var TempTableMetadata: Record "Table Metadata" temporary)
    var
        Field: Record "Field";
    begin
        // Looping through all No. Series fields
        ToolsImpl.SetFilterOnNoSeriesFields(TempTableMetadata, Field);
        if Field.FindSet() then
            repeat
                AddNewNoSeriesFieldToTablesList(TempSetupTable, TempNoSeriesField, TempTableMetadata, Field);
            until Field.Next() = 0;
    end;

    local procedure AddNewNoSeriesFieldToTablesList(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; TempTableMetadata: Record "Table Metadata" temporary; Field: Record "Field")
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TempTableMetadata.ID);
        if not RecRef.FindFirst() then
            exit;

        FieldRef := RecRef.Field(Field."No.");
        if Format(FieldRef.Value) <> '' then
            exit; // No need to generate number series if it already created and confgured

        TempSetupTable := TempTableMetadata;
        if TempSetupTable.Insert() then;

        TempNoSeriesField := Field;
        TempNoSeriesField.Insert();
    end;

    [NonDebuggable]
    local procedure GetToolPrompt(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool prompt. The tool should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1PromptFromIsolatedStorage())
    end;


    [NonDebuggable]
    local procedure GetToolDefinition(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool definition. The tool should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool1DefinitionFromIsolatedStorage())
    end;

}