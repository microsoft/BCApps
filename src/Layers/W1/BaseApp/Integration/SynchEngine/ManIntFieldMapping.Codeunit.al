// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.Dataverse;
using System.Apps.ExtensionGeneration;
using System.Reflection;

/// <summary>
/// Provides functionality to create user-defined manual field mappings in addition to out-of-the-box mappings.
/// </summary>
codeunit 5391 "Man. Int. Field Mapping"
{
    var
        FieldNotFoundTok: Label 'Field not found: %1.', Locked = true, Comment = '%1 - field name';
        UsingDataverseTableBuilderTok: Label 'Using Dataverse table builder for %1 fields.', Locked = true, Comment = '%1 - number of fields';
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;
        IntegrationTableFieldNameEmptyTok: Label 'Integration table field name is empty. Skipping this field mapping.', Locked = true;

    /// <summary>
    /// Creates field mappings from the temporary manual integration field mapping table for fields that already exist in the integration table.
    /// </summary>
    /// <param name="TempManIntFieldMapping">Temporary manual integration field mapping record.</param>
    /// <param name="IntegrationMappingName">Name of the integration mapping.</param>
    /// <param name="SetupExistingIntegrationMapping">Indicates whether to set up existing integration mapping.</param>
    procedure CreateFieldMappings(var TempManIntFieldMapping: Record "Man. Int. Field Mapping" temporary; IntegrationMappingName: Code[20]; SetupExistingIntegrationMapping: Boolean)
    var
        ManIntegrationTableMapping: Record "Man. Integration Table Mapping";
        ManIntFieldMapping: Record "Man. Int. Field Mapping";
    begin
        TempManIntFieldMapping.Reset();
        TempManIntFieldMapping.SetRange(Name, '');
        TempManIntFieldMapping.SetFilter("Integration Table Field No.", '<>%1', 0);
        if TempManIntFieldMapping.FindSet() then
            repeat
                ManIntegrationTableMapping.InsertIntegrationFieldMapping(
                    IntegrationMappingName,
                    TempManIntFieldMapping."Table Field No.",
                    TempManIntFieldMapping."Integration Table Field No.",
                    TempManIntFieldMapping.Direction,
                    TempManIntFieldMapping."Const Value",
                    TempManIntFieldMapping."Validate Field",
                    TempManIntFieldMapping."Validate Integr. Table Field",
                    not SetupExistingIntegrationMapping,
                    TempManIntFieldMapping."Transformation Rule");

                ManIntFieldMapping.CreateRecord(
                    IntegrationMappingName,
                    TempManIntFieldMapping."Table Field No.",
                    TempManIntFieldMapping."Integration Table Field No.",
                    TempManIntFieldMapping.Direction,
                    TempManIntFieldMapping."Const Value",
                    TempManIntFieldMapping."Validate Field",
                    TempManIntFieldMapping."Validate Integr. Table Field",
                    TempManIntFieldMapping."Transformation Rule");

            until TempManIntFieldMapping.Next() = 0;
    end;

    /// <summary>
    /// Gets the runtime fields to create from the temporary manual integration field mapping table. These are fields that do not yet exist in the integration table.
    /// </summary>
    /// <param name="TempManIntFieldMapping">Temporary manual integration field mapping record.</param>
    /// <param name="RuntimeFields">List of runtime fields to create.</param>
    procedure GetRuntimeFieldsToCreate(var TempManIntFieldMapping: Record "Man. Int. Field Mapping" temporary; var RuntimeFields: List of [Text])
    begin
        TempManIntFieldMapping.Reset();
        TempManIntFieldMapping.SetRange(Name, '');
        TempManIntFieldMapping.SetRange("Integration Table Field No.", 0);
        if TempManIntFieldMapping.FindSet() then
            repeat
                if TempManIntFieldMapping."Integration Table Field Name" = '' then begin
                    Session.LogMessage('0000QM3', IntegrationTableFieldNameEmptyTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    continue;
                end;

                if RuntimeFields.Contains(TempManIntFieldMapping."Integration Table Field Name") then
                    continue;

                RuntimeFields.Add(TempManIntFieldMapping."Integration Table Field Name");
            until TempManIntFieldMapping.Next() = 0;
    end;

    /// <summary>
    /// Creates runtime fields in the integration table by publishing a table extension object using the Dataverse Table Builder.
    /// </summary>
    /// <param name="RuntimeFields">List of runtime fields to create.</param>
    /// <param name="IntegrationMappingIntTableId">Integration table ID to extend.</param>
    [TryFunction]
    procedure TryCreateRuntimeFields(RuntimeFields: List of [Text]; IntegrationMappingIntTableId: Integer)
    var
        DataverseTableBuilder: Codeunit "Dataverse Table Builder";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        if RuntimeFields.Count() > 0 then begin
            Session.LogMessage('0000QLC', StrSubstNo(UsingDataverseTableBuilderTok, RuntimeFields.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            DataverseTableBuilder.StartGeneration(true);
            DataverseTableBuilder.UpdateExistingTable(IntegrationMappingIntTableId, RuntimeFields, CDSIntegrationMgt.GetEntityMetadata(IntegrationMappingIntTableId));
            DataverseTableBuilder.CommitGeneration();
        end;
    end;

    /// <summary>
    /// Creates field mappings from the temporary manual integration field mapping table for runtime fields that were just created in the integration table.
    /// </summary>
    /// <param name="TempManIntFieldMapping">Temporary manual integration field mapping record.</param>
    /// <param name="IntegrationMappingName">Name of the integration mapping.</param>
    /// <param name="IntegrationMappingIntTableId">Integration table ID.</param>
    /// <param name="SetupExistingIntegrationMapping">Indicates whether to set up existing integration mapping.</param>
    /// <param name="FailedFields">Indicates whether any fields failed to be mapped.</param>
    procedure CreateFieldMappingsForRuntimeFields(var TempManIntFieldMapping: Record "Man. Int. Field Mapping" temporary; IntegrationMappingName: Code[20]; IntegrationMappingIntTableId: Integer; SetupExistingIntegrationMapping: Boolean; var FailedFields: Boolean)
    var
        Field: Record "Field";
        ManIntegrationTableMapping: Record "Man. Integration Table Mapping";
        ManIntFieldMapping: Record "Man. Int. Field Mapping";
    begin
        if TempManIntFieldMapping.FindSet() then
            repeat
                Field.SetRange(TableNo, IntegrationMappingIntTableId);
                Field.SetRange(ExternalName, TempManIntFieldMapping."Integration Table Field Name");
                if not Field.FindFirst() then begin
                    Session.LogMessage('0000QLB', StrSubstNo(FieldNotFoundTok, TempManIntFieldMapping."Integration Table Field Name"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    FailedFields := true;
                    continue;
                end;

                ManIntegrationTableMapping.InsertIntegrationFieldMapping(
                    IntegrationMappingName,
                    TempManIntFieldMapping."Table Field No.",
                    Field."No.",
                    TempManIntFieldMapping.Direction,
                    TempManIntFieldMapping."Const Value",
                    TempManIntFieldMapping."Validate Field",
                    TempManIntFieldMapping."Validate Integr. Table Field",
                    not SetupExistingIntegrationMapping,
                    TempManIntFieldMapping."Transformation Rule");

                ManIntFieldMapping.CreateRecord(
                    IntegrationMappingName,
                    TempManIntFieldMapping."Table Field No.",
                    Field."No.",
                    TempManIntFieldMapping.Direction,
                    TempManIntFieldMapping."Const Value",
                    TempManIntFieldMapping."Validate Field",
                    TempManIntFieldMapping."Validate Integr. Table Field",
                    TempManIntFieldMapping."Transformation Rule");
            until TempManIntFieldMapping.Next() = 0;
    end;
}