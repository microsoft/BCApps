// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Apps.ExtensionGeneration;

/// <summary>
/// Provides functions for generating runtime Dataverse tables and table extensions based on Dataverse schema.
/// </summary>
codeunit 2507 "Dataverse Table Builder"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        DataverseTableBuilderImpl: Codeunit "Dataverse Table Builder Impl.";

    /// <summary>
    /// Starts the generation of Dataverse tables and table extensions.
    /// </summary>
    /// <param name="OverwriteExisting">Indicates whether to overwrite existing generation.</param>
    /// <returns>True if the generation was started successfully; otherwise, false.</returns>
    procedure StartGeneration(OverwriteExisting: Boolean): Boolean
    begin
        exit(DataverseTableBuilderImpl.StartGeneration(OverwriteExisting));
    end;

    /// <summary>
    /// Updates an existing Dataverse table by adding new fields based on the provided Dataverse schema.
    /// </summary>/// 
    /// <param name="TableId">The ID of the table to update.</param>
    /// <param name="FieldsToAdd">The fields to add to the table.</param>
    /// <param name="DataverseSchema">The Dataverse schema to use for the update.</param>
    /// <returns>True if the update was successful; otherwise, false.</returns>
    procedure UpdateExistingTable(TableId: Integer; FieldsToAdd: List of [Text]; DataverseSchema: Text): Boolean
    begin
        exit(DataverseTableBuilderImpl.UpdateExistingTable(TableId, FieldsToAdd, DataverseSchema));
    end;

    /// <summary>
    /// Commits the generated Dataverse tables and table extensions to the system.
    /// </summary>
    /// <returns>True if the commit was successful; otherwise, false.</returns>
    procedure CommitGeneration(): Boolean
    begin
        exit(DataverseTableBuilderImpl.CommitGeneration());
    end;

    /// <summary>
    /// Clears any ongoing or incomplete generation of Dataverse tables and table extensions.
    /// </summary> 
    procedure ClearGeneration()
    begin
        DataverseTableBuilderImpl.ClearGeneration();
    end;
}