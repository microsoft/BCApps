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
        UpdateForNextYear: Boolean;
        SpecifyTablesErr: Label 'Please specify the tables for which you want to modify the number series.';
        FunctionNameLbl: Label 'UpdateExistingNumberSeries', Locked = true;
        DateSpecificPlaceholderLbl: Label '{current_date}', Locked = true;
        CustomPatternsPlaceholderLbl: Label '{custom_patterns}', Locked = true;
        TablesYamlFormatPlaceholderLbl: Label '{tables_yaml_format}', Locked = true;
        UpdateForNextYearPlaceholderLbl: Label '{update_for_next_year}', Locked = true;
        CurrentYearPlaceholderLbl: Label '{current_year}', Locked = true;
        NextYearPlaceholderLbl: Label '{next_year}', Locked = true;
        NumberOfAddedTablesPlaceholderLbl: Label '{number_of_tables}', Locked = true;

    procedure GetName(): Text
    begin
        exit(FunctionNameLbl);
    end;

    [NonDebuggable]
    procedure GetPrompt() Function: JsonObject;
    begin
        Function.ReadFrom(GetTool2Definition());
    end;

    [NonDebuggable]
    procedure Execute(Arguments: JsonObject): Variant
    begin
        exit(Build(Arguments));
    end;

    procedure SetUpdateForNextYear(IsNextYearIntent: Boolean)
    begin
        UpdateForNextYear := IsNextYearIntent;
    end;

    /// <summary>
    /// Build the prompts for modifying existing number series.
    /// </summary>
    /// <param name="Arguments">Function Arguments retrieved from LLM</param>
    /// <returns></returns>
    /// <remarks> This function is used to build the prompts for modifying existing series. The prompts are built based on the tables and patterns specified in the input. Tables should be specified. If no patterns are specified, default patterns are used. In case number of tables can't be pasted in one prompt, due to token limits, function chunk result into several messages, that need to be called separately</remarks>
    [NonDebuggable]
    local procedure Build(var Arguments: JsonObject) ToolResults: Dictionary of [Text, Integer]
    var
        TempSetupTable: Record "Table Metadata" temporary;
        TempNoSeriesField: Record "Field" temporary;
        NotificationManager: Codeunit "No. Ser. Cop. Notific. Manager";
        ChangeNoSeriesPrompt, CustomPatternsPromptList, TablesYamlList, ExistingNoSeriesToChangeList : List of [Text];
        NumberOfToolResponses, i, ActualTablesChunkSize : Integer;
        NumberOfChangedTables: Integer;
    begin
        if not CheckIfUserSpecifiedNoSeriesToChange(Arguments) then begin
            NotificationManager.SendNotification(GetLastErrorText());
            exit;
        end;

        GetTablesWithNoSeries(Arguments, TempSetupTable, TempNoSeriesField, ExistingNoSeriesToChangeList);
        ToolsImpl.GetUserSpecifiedOrExistingNumberPatternsGuidelines(Arguments, CustomPatternsPromptList, ExistingNoSeriesToChangeList, UpdateForNextYear);

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
                                                        .Replace(UpdateForNextYearPlaceholderLbl, Format(UpdateForNextYear))
                                                        .Replace(CurrentYearPlaceholderLbl, Format(Date2DMY(Today, 3)))
                                                        .Replace(NextYearPlaceholderLbl, Format(Date2DMY(Today, 3) + 1))
                                                        .Replace(NumberOfAddedTablesPlaceholderLbl, Format(ActualTablesChunkSize)));

                ToolResults.Add(ToolsImpl.ConvertListToText(ChangeNoSeriesPrompt), ActualTablesChunkSize);
            end
    end;

    [TryFunction]
    local procedure CheckIfUserSpecifiedNoSeriesToChange(Arguments: JsonObject)
    begin
        if ToolsImpl.CheckIfTablesSpecified(Arguments) then
            exit;

        if UpdateForNextYear then
            exit;

        Error(SpecifyTablesErr);
    end;

    local procedure GetTablesWithNoSeries(var Arguments: JsonObject; var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var ExistingNoSeriesToChangeList: List of [Text])
    begin
        ListOnlySpecifiedTablesWithExistingNumberSeries(TempSetupTable, TempNoSeriesField, ExistingNoSeriesToChangeList, ToolsImpl.GetEntities(Arguments));
    end;

    local procedure ListOnlySpecifiedTablesWithExistingNumberSeries(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var ExistingNoSeriesToChangeList: List of [Text]; Entities: List of [Text])
    var
        TempTableMetadata: Record "Table Metadata" temporary;
    begin
        // Looping through all Setup tables
        ToolsImpl.RetrieveSetupTables(TempTableMetadata);
        if TempTableMetadata.FindSet() then
            repeat
                ListOnlyRelevantNoSeriesFieldsWithExistingNumberSeries(TempSetupTable, TempNoSeriesField, ExistingNoSeriesToChangeList, TempTableMetadata, Entities);
            until TempTableMetadata.Next() = 0;
    end;

    local procedure ListOnlyRelevantNoSeriesFieldsWithExistingNumberSeries(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var ExistingNoSeriesToChangeList: List of [Text]; var TempTableMetadata: Record "Table Metadata" temporary; Entities: List of [Text])
    var
        Field: Record "Field";
    begin
        // Looping through all No. Series fields
        ToolsImpl.SetFilterOnNoSeriesFields(TempTableMetadata, Field);
        if Field.FindSet() then
            repeat
                if (ToolsImpl.IsRelevant(TempTableMetadata, Field, Entities)) or UpdateForNextYear then
                    AddChangeNoSeriesFieldToTablesList(TempSetupTable, TempNoSeriesField, ExistingNoSeriesToChangeList, TempTableMetadata, Field);
            until Field.Next() = 0;
    end;

    local procedure AddChangeNoSeriesFieldToTablesList(var TempSetupTable: Record "Table Metadata" temporary; var TempNoSeriesField: Record "Field" temporary; var ExistingNoSeriesToChangeList: List of [Text]; TempTableMetadata: Record "Table Metadata" temporary; Field: Record "Field")
    var
        NoSeries: Record "No. Series";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(TempTableMetadata.ID);
        if not RecRef.FindFirst() then
            exit;

        FieldRef := RecRef.Field(Field."No.");
        if Format(FieldRef.Value) = '' then
            exit;

        if not NoSeries.Get(Format(FieldRef.Value)) then
            exit;

        TempSetupTable := TempTableMetadata;
        if TempSetupTable.Insert() then;

        TempNoSeriesField := Field;
        TempNoSeriesField.ExternalName := NoSeries.Code; //we save the value of the existing number series, to show it in the prompt later
        TempNoSeriesField.Insert();

        ExistingNoSeriesToChangeList.Add(NoSeries.Code);
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