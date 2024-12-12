// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.AI;
using System.Reflection;
using System.Azure.KeyVault;
using System.Telemetry;

codeunit 334 "No. Series Cop. Change Intent" implements "AOAI Function"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        Telemetry: Codeunit Telemetry;
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
        TelemetryTool2PromptRetrievalErr: Label 'Unable to retrieve the prompt for No. Series Copilot Tool 2 from Azure Key Vault.', Locked = true;
        TelemetryTool2DefinitionRetrievalErr: Label 'Unable to retrieve the definition for No. Series Copilot Tool 2 from Azure Key Vault.', Locked = true;
        ToolProgressDialogTextLbl: Label 'Searching for tables with number series related to your query';
        ToolLoadingErr: Label 'Unable to load the No. Series Copilot Tool 2. Please try again later.';

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
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
        NoSeriesCopilotTelemetry: Codeunit "No. Series Copilot Telemetry";
        ChangeNoSeriesPrompt, CustomPatternsPromptList, TablesYamlList, ExistingNoSeriesToChangeList : List of [Text];
        NumberOfToolResponses, i, ActualTablesChunkSize : Integer;
        NumberOfChangedTables: Integer;
        Progress: Dialog;
    begin
        if not CheckIfUserSpecifiedNoSeriesToChange(Arguments) then begin
            NoSeriesCopilotImpl.SendNotification(GetLastErrorText());
            exit;
        end;

        Progress.Open(ToolProgressDialogTextLbl);
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
            end;
        Progress.Close();
        NoSeriesCopilotTelemetry.LogModifyExistingNumberSeriesToolUsage(ToolsImpl.GetEntities(Arguments).Count, CustomPatternsPromptList.Count > 0, NumberOfToolResponses, NumberOfChangedTables, UpdateForNextYear);
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
    local procedure GetToolPrompt() Prompt: Text
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret('NoSeriesCopilotTool2Prompt', Prompt) then begin
            Telemetry.LogMessage('0000ND6', TelemetryTool2PromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            Error(ToolLoadingErr);
        end;
    end;

    [NonDebuggable]
    local procedure GetTool2Definition() Definition: Text
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret('NoSeriesCopilotTool2Definition', Definition) then begin
            Telemetry.LogMessage('0000ND7', TelemetryTool2DefinitionRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            Error(ToolLoadingErr);
        end;
    end;
}