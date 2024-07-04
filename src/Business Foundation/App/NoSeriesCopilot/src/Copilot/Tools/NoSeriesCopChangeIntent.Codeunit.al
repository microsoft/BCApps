// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.AI;
using System.Reflection;
using System.Utilities;

codeunit 334 "No. Series Cop. Change Intent" implements "AOAI Function"
{
    Access = Internal;

    var
        ToolsImpl: Codeunit "No. Series Cop. Tools Impl.";
        SpecifyTablesErr: Label 'Please specify the tables for which you want to modify the number series.';
        DateSpecificPlaceholderLbl: Label '{current_date}', Locked = true;
        CustomPatternsPlaceholderLbl: Label '{custom_patterns}', Locked = true;
        TablesYamlFormatPlaceholderLbl: Label '{tables_yaml_format}', Locked = true;
        NumberOfAddedTablesPlaceholderLbl: Label '{number_of_tables}', Locked = true;

    procedure GetName(): Text
    begin
        exit('GetExistingTablesAndPatterns');
    end;

    procedure GetPrompt() Function: JsonObject;
    begin
        Function.ReadFrom(GetTool2Definition());
    end;

    procedure Execute(Arguments: JsonObject): Variant
    begin
        exit(Build(Arguments));
    end;

    /// <summary>
    /// Build the prompts for modifying existing number series.
    /// </summary>
    /// <param name="Arguments">Function Arguments retrieved from LLM</param>
    /// <returns></returns>
    /// <remarks> This function is used to build the prompts for modifying existing series. The prompts are built based on the tables and patterns specified in the input. Tables should be specified. If no patterns are specified, default patterns are used. In case number of tables can't be pasted in one prompt, due to token limits, function chunk result into several messages, that need to be called separately</remarks>
    local procedure Build(var Arguments: JsonObject) ToolResults: Dictionary of [Text, Integer]
    var
        ChangeNoSeriesPrompt, CustomPatternsPromptList, TablesYamlList, ExistingNoSeriesToChangeList : List of [Text];
        NumberOfToolResponses, i, ActualTablesChunkSize : Integer;
        TempSetupTable: Record "Table Metadata" temporary;
        TempNoSeriesField: Record "Field" temporary;
        NumberOfChangedTables: Integer;
    begin
        GetTablesWithNoSeries(Arguments, TempSetupTable, TempNoSeriesField, ExistingNoSeriesToChangeList);
        ToolsImpl.GetUserSpecifiedOrExistingNumberPatternsGuidelines(Arguments, CustomPatternsPromptList, ExistingNoSeriesToChangeList);

        NumberOfChangedTables := TempNoSeriesField.Count();
        NumberOfToolResponses := Round(NumberOfChangedTables / ToolsImpl.GetMaxNumberOfTablesInOneChunk(), 1, '>'); // we add tables by small chunks, as more tables can lead to hallucinations

        for i := 1 to NumberOfToolResponses do
            if NumberOfChangedTables > 0 then begin
                Clear(ChangeNoSeriesPrompt);
                Clear(ActualTablesChunkSize);
                ToolsImpl.GenerateChunkedTablesListInYamlFormat(TablesYamlList, TempSetupTable, TempNoSeriesField, ActualTablesChunkSize);
                ChangeNoSeriesPrompt.Add(GetToolPrompt().Replace(DateSpecificPlaceholderLbl, Format(Today(), 0, 4))
                                                        .Replace(CustomPatternsPlaceholderLbl, ToolsImpl.ConvertListToText(CustomPatternsPromptList))
                                                        .Replace(TablesYamlFormatPlaceholderLbl, ToolsImpl.ConvertListToText(TablesYamlList))
                                                        .Replace(NumberOfAddedTablesPlaceholderLbl, Format(ActualTablesChunkSize)));

                ToolResults.Add(ToolsImpl.ConvertListToText(ChangeNoSeriesPrompt), ActualTablesChunkSize);
            end
    end;

    local procedure GetTablesWithNoSeries(var Arguments: JsonObject; var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var ExistingNoSeriesToChangeList: List of [Text])
    begin
        if not ToolsImpl.CheckIfTablesSpecified(Arguments) then
            Error(SpecifyTablesErr);

        ListOnlySpecifiedTablesWithExistingNumberSeries(TempSetupTable, TempNoSeriesField, ExistingNoSeriesToChangeList, ToolsImpl.GetEntities(Arguments));
    end;

    local procedure ListOnlySpecifiedTablesWithExistingNumberSeries(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var ExistingNoSeriesToChangeList: List of [Text]; Entities: List of [Text])
    var
        TableMetadata: Record "Table Metadata";
    begin
        // Looping through all Setup tables
        ToolsImpl.SetFilterOnSetupTables(TableMetadata);
        if TableMetadata.FindSet() then
            repeat
                ListOnlyRelevantNoSeriesFieldsWithExistingNumberSeries(TempSetupTable, TempNoSeriesField, ExistingNoSeriesToChangeList, TableMetadata, Entities);
            until TableMetadata.Next() = 0;
    end;

    local procedure ListOnlyRelevantNoSeriesFieldsWithExistingNumberSeries(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var ExistingNoSeriesToChangeList: List of [Text]; var TableMetadata: Record "Table Metadata"; Entities: List of [Text])
    var
        Field: Record "Field";
    begin
        // Looping through all No. Series fields
        ToolsImpl.SetFilterOnNoSeriesFields(TableMetadata, Field);
        if Field.FindSet() then
            repeat
                if ToolsImpl.IsRelevant(TableMetadata, Field, Entities) then
                    AddChangeNoSeriesFieldToTablesList(TempSetupTable, TempNoSeriesField, ExistingNoSeriesToChangeList, TableMetadata, Field);
            until Field.Next() = 0;
    end;

    local procedure AddChangeNoSeriesFieldToTablesList(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var ExistingNoSeriesToChangeList: List of [Text]; TableMetadata: Record "Table Metadata"; Field: Record "Field")
    var
        NoSeries: Record "No. Series";
        RecRef: RecordRef;
        FieldRef: FieldRef;
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

        TempSetupTable := TableMetadata;
        if TempSetupTable.Insert() then;

        TempNoSeriesField := Field;
        TempNoSeriesField.ExternalName := NoSeries.Code; //we save the value of the existing number series, to show it in the prompt later
        TempNoSeriesField.Insert();

        ExistingNoSeriesToChangeList.Add(NoSeries.Code);

        // TablesPromptList.Add('Area: ' + ToolsImpl.RemoveTextPart(TableMetadata.Caption, ' Setup') + ', TableId: ' + Format(TableMetadata.ID) + ', FieldId: ' + Format(Field."No.") + ', FieldName: ' + ToolsImpl.RemoveTextParts(Field.FieldName, ToolsImpl.GetNoSeriesAbbreviations()) + ', seriesCode: ' + NoSeries.Code + ', description: ' + NoSeries.Description);
    end;

    [NonDebuggable]
    local procedure GetToolPrompt(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool definition. The tool should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2PromptFromIsolatedStorage())
    end;


    [NonDebuggable]
    local procedure GetTool2Definition(): Text
    var
        NoSeriesCopilotSetup: Record "No. Series Copilot Setup";
    begin
        // This is a temporary solution to get the tool definition. The tool should be retrieved from the Azure Key Vault.
        // TODO: Retrieve the tools from the Azure Key Vault, when passed all tests.
        NoSeriesCopilotSetup.Get();
        exit(NoSeriesCopilotSetup.GetTool2DefinitionFromIsolatedStorage())
    end;
}