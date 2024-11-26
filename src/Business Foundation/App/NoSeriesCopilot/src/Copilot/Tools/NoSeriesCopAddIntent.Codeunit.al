// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

using System.Azure.KeyVault;
using System.AI;
using System.Reflection;
using System.Telemetry;

codeunit 331 "No. Series Cop. Add Intent" implements "AOAI Function"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        Telemetry: Codeunit Telemetry;
        ToolsImpl: Codeunit "No. Series Cop. Tools Impl.";
        ExistingNoSeriesJArr: JsonArray;
        FunctionNameLbl: Label 'CreateNewNumberSeries', Locked = true;
        DateSpecificPlaceholderLbl: Label '{current_date}', Locked = true;
        CustomPatternsPlaceholderLbl: Label '{custom_patterns}', Locked = true;
        TablesYamlFormatPlaceholderLbl: Label '{tables_yaml_format}', Locked = true;
        NumberOfAddedTablesPlaceholderLbl: Label '{number_of_tables}', Locked = true;
        TelemetryTool1PromptRetrievalErr: Label 'Unable to retrieve the prompt for No. Series Copilot Tool 1 from Azure Key Vault.', Locked = true;
        TelemetryTool1DefinitionRetrievalErr: Label 'Unable to retrieve the definition for No. Series Copilot Tool 1 from Azure Key Vault.', Locked = true;
        ToolProgressDialogTextLbl: Label 'Searching for tables with number series related to your query';
        ToolLoadingErr: Label 'Unable to load the No. Series Copilot Tool 1. Please try again later.';
        ExistingNoSeriesMessageLbl: Label 'Number series already configured. If you wish to modify the existing series, please use the `Modify number series` prompt.';

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
        TempNoSeriesField: Record "Field" temporary;
        TempSetupTable: Record "Table Metadata" temporary;
        NoSeriesCopilotTelemetry: Codeunit "No. Series Copilot Telemetry";
        NewNoSeriesPrompt, CustomPatternsPromptList, TablesYamlList, EmptyList : List of [Text];
        NumberOfToolResponses, i, ActualTablesChunkSize : Integer;
        NumberOfAddedTables: Integer;
        Progress: Dialog;
    begin
        Progress.Open(ToolProgressDialogTextLbl);
        GetTablesRequireNoSeries(Arguments, TempSetupTable, TempNoSeriesField);
        ToolsImpl.GetUserSpecifiedOrExistingNumberPatternsGuidelines(Arguments, CustomPatternsPromptList, EmptyList, false);

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
            end;
        Progress.Close();
        NoSeriesCopilotTelemetry.LogCreateNewNumberSeriesToolUsage(ToolsImpl.GetEntities(Arguments).Count, CustomPatternsPromptList.Count > 0, NumberOfToolResponses, NumberOfAddedTables);
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
        if Format(FieldRef.Value) <> '' then begin
            SaveExistingNoSeries(TempTableMetadata, FieldRef);
            exit; // No need to generate number series if it already created and configured
        end;

        TempSetupTable := TempTableMetadata;
        if TempSetupTable.Insert() then;

        TempNoSeriesField := Field;
        TempNoSeriesField.Insert();
    end;

    local procedure SaveExistingNoSeries(TempTableMetadata: Record "Table Metadata" temporary; FieldRef: FieldRef)
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesManagement: Codeunit "No. Series";
        ExistingNoSeriesJObj: JsonObject;
    begin
        if not NoSeries.Get(Format(FieldRef.Value)) then
            exit;

        NoSeriesManagement.GetNoSeriesLine(NoSeriesLine, NoSeries.Code, Today(), false);

        Clear(ExistingNoSeriesJObj);
        ExistingNoSeriesJObj.Add('seriesCode', NoSeries.Code);
        ExistingNoSeriesJObj.Add('description', NoSeries.Description);
        ExistingNoSeriesJObj.Add('startingNo', NoSeriesLine."Starting No.");
        ExistingNoSeriesJObj.Add('endingNo', NoSeriesLine."Ending No.");
        ExistingNoSeriesJObj.Add('warningNo', NoSeriesLine."Warning No.");
        ExistingNoSeriesJObj.Add('incrementByNo', NoSeriesLine."Increment-by No.");
        ExistingNoSeriesJObj.Add('tableId', TempTableMetadata.ID);
        ExistingNoSeriesJObj.Add('fieldId', FieldRef.Number);
        ExistingNoSeriesJObj.Add('nextYear', false);
        ExistingNoSeriesJObj.Add('exists', true);
        ExistingNoSeriesJObj.Add('message', ExistingNoSeriesMessageLbl);

        ExistingNoSeriesJArr.Add(ExistingNoSeriesJObj);
    end;

    procedure GetExistingNoSeries() ExistingNoSeries: Text
    begin
        if ExistingNoSeriesJArr.Count() = 0 then
            exit('');

        ExistingNoSeriesJArr.WriteTo(ExistingNoSeries);
    end;

    [NonDebuggable]
    local procedure GetToolPrompt() Prompt: Text
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret('NoSeriesCopilotTool1Prompt', Prompt) then begin
            Telemetry.LogMessage('0000ND4', TelemetryTool1PromptRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            Error(ToolLoadingErr);
        end;
    end;

    [NonDebuggable]
    local procedure GetToolDefinition() Definition: Text
    begin
        if not AzureKeyVault.GetAzureKeyVaultSecret('NoSeriesCopilotTool1Definition', Definition) then begin
            Telemetry.LogMessage('0000ND5', TelemetryTool1DefinitionRetrievalErr, Verbosity::Error, DataClassification::SystemMetadata);
            Error(ToolLoadingErr);
        end;
    end;

}