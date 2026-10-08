// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;

/// <summary>
/// Facade codeunit for managing integration with Microsoft Dataverse.
/// Provides simplified access to Dataverse integration functionality.
/// </summary>
codeunit 7200 "CDS Integration Mgt."
{
    Access = Public;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";

    /// <summary>
    /// Tests if the active connection to Dataverse is working.
    /// </summary>
    /// <returns>True if the connection is active and working, otherwise false.</returns>
    procedure TestConnection(): Boolean
    begin
        exit(CDSIntegrationImpl.TestActiveConnection());
    end;

    /// <summary>
    /// Activates the connection to Dataverse.
    /// </summary>
    /// <returns>True if the connection was successfully activated, otherwise false.</returns>
    procedure ActivateConnection(): Boolean
    begin
        exit(CDSIntegrationImpl.ActivateConnection());
    end;

    /// <summary>
    /// Registers the connection to Dataverse.
    /// </summary>
    /// <returns>True if the connection was successfully registered, otherwise false.</returns>
    procedure RegisterConnection(): Boolean
    begin
        exit(CDSIntegrationImpl.RegisterConnection());
    end;

    /// <summary>
    /// Checks if the Dataverse integration is enabled.
    /// </summary>
    /// <returns>True if integration is enabled, otherwise false.</returns>
    procedure IsIntegrationEnabled(): Boolean
    begin
        exit(CDSIntegrationImpl.IsIntegrationEnabled());
    end;

    /// <summary>
    /// Checks if business events are enabled for the Dataverse integration.
    /// </summary>
    /// <returns>True if business events are enabled, otherwise false.</returns>
    procedure IsBusinessEventsEnabled(): Boolean
    begin
        exit(CDSIntegrationImpl.IsBusinessEventsEnabled());
    end;

    /// <summary>
    /// Checks if the connection to Dataverse is currently active.
    /// </summary>
    /// <returns>True if the connection is active, otherwise false.</returns>
    procedure IsConnectionActive(): Boolean
    begin
        exit(CDSIntegrationImpl.IsConnectionActive());
    end;

    /// <summary>
    /// Checks if the default Dataverse integration solution is installed.
    /// </summary>
    /// <returns>True if the solution is installed, otherwise false.</returns>
    procedure IsSolutionInstalled(): Boolean
    begin
        exit(CDSIntegrationImpl.IsSolutionInstalled());
    end;

    /// <summary>
    /// Checks if a specific Dataverse solution is installed.
    /// </summary>
    /// <param name="UniqueName">The unique name of the solution to check.</param>
    /// <returns>True if the solution is installed, otherwise false.</returns>
    procedure IsSolutionInstalled(UniqueName: Text): Boolean
    begin
        exit(CDSIntegrationImpl.IsSolutionInstalled(UniqueName));
    end;

    /// <summary>
    /// Gets the version of the default Dataverse integration solution.
    /// </summary>
    /// <param name="Version">Returns the version string of the solution.</param>
    /// <returns>True if the version was successfully retrieved, otherwise false.</returns>
    procedure GetSolutionVersion(var Version: Text): Boolean
    begin
        exit(CDSIntegrationImpl.GetSolutionVersion(Version));
    end;

    /// <summary>
    /// Gets the version of a specific Dataverse solution.
    /// </summary>
    /// <param name="UniqueName">The unique name of the solution.</param>
    /// <param name="Version">Returns the version string of the solution.</param>
    /// <returns>True if the version was successfully retrieved, otherwise false.</returns>
    procedure GetSolutionVersion(UniqueName: Text; var Version: Text): Boolean
    begin
        exit(CDSIntegrationImpl.GetSolutionVersion(UniqueName, Version));
    end;

    /// <summary>
    /// Checks if the company ID on the record matches the current company.
    /// </summary>
    /// <param name="RecRef">The record reference to check.</param>
    /// <returns>True if the company ID matches, otherwise false.</returns>
    procedure CheckCompanyId(var RecRef: RecordRef): Boolean
    begin
        exit(CDSIntegrationImpl.CheckCompanyId(RecRef));
    end;

    /// <summary>
    /// Checks if the record is owned by the configured owning team.
    /// </summary>
    /// <param name="RecRef">The record reference to check.</param>
    /// <returns>True if the record is owned by the owning team, otherwise false.</returns>
    procedure CheckOwningTeam(var RecRef: RecordRef): Boolean
    begin
        exit(CDSIntegrationImpl.CheckOwningTeam(RecRef));
    end;

    /// <summary>
    /// Checks if the record is owned by the specified user.
    /// </summary>
    /// <param name="RecRef">The record reference to check.</param>
    /// <param name="UserId">The user ID to check ownership against.</param>
    /// <returns>True if the record is owned by the user, otherwise false.</returns>
    procedure CheckOwningUser(var RecRef: RecordRef; UserId: Guid): Boolean
    begin
        exit(CDSIntegrationImpl.CheckOwningUser(RecRef, UserId));
    end;

    /// <summary>
    /// Checks if the record is owned by the specified user with an option to skip business unit check.
    /// </summary>
    /// <param name="RecRef">The record reference to check.</param>
    /// <param name="UserId">The user ID to check ownership against.</param>
    /// <param name="SkipBusinessUnitCheck">If true, skips the business unit validation.</param>
    /// <returns>True if the record is owned by the user, otherwise false.</returns>
    procedure CheckOwningUser(var RecRef: RecordRef; UserId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    begin
        exit(CDSIntegrationImpl.CheckOwningUser(RecRef, UserId, SkipBusinessUnitCheck));
    end;

    /// <summary>
    /// Checks if the specified table has a company ID field.
    /// </summary>
    /// <param name="TableId">The ID of the table to check.</param>
    /// <returns>True if the table has a company ID field, otherwise false.</returns>
    procedure HasCompanyIdField(TableId: Integer): Boolean
    begin
        exit(CDSIntegrationImpl.HasCompanyIdField(TableId));
    end;

    /// <summary>
    /// Resets the company ID field on the record to empty.
    /// </summary>
    /// <param name="RecRef">The record reference to modify.</param>
    /// <returns>True if the company ID was successfully reset, otherwise false.</returns>
    procedure ResetCompanyId(var RecRef: RecordRef): Boolean
    begin
        exit(CDSIntegrationImpl.ResetCompanyId(RecRef));
    end;

    /// <summary>
    /// Sets the company ID field on the record to the current company.
    /// </summary>
    /// <param name="RecRef">The record reference to modify.</param>
    /// <returns>True if the company ID was successfully set, otherwise false.</returns>
    procedure SetCompanyId(var RecRef: RecordRef): Boolean
    begin
        exit(CDSIntegrationImpl.SetCompanyId(RecRef));
    end;

    /// <summary>
    /// Sets the owning team on the record to the configured default team.
    /// </summary>
    /// <param name="RecRef">The record reference to modify.</param>
    /// <returns>True if the owning team was successfully set, otherwise false.</returns>
    procedure SetOwningTeam(var RecRef: RecordRef): Boolean
    begin
        exit(CDSIntegrationImpl.SetOwningTeam(RecRef));
    end;

    /// <summary>
    /// Sets the owning user on the record to the specified user.
    /// </summary>
    /// <param name="RecRef">The record reference to modify.</param>
    /// <param name="UserId">The user ID to set as owner.</param>
    /// <returns>True if the owning user was successfully set, otherwise false.</returns>
    procedure SetOwningUser(var RecRef: RecordRef; UserId: Guid): Boolean
    begin
        exit(CDSIntegrationImpl.SetOwningUser(RecRef, UserId, false));
    end;

    /// <summary>
    /// Sets the owning user on the record to the specified user with an option to skip business unit check.
    /// </summary>
    /// <param name="RecRef">The record reference to modify.</param>
    /// <param name="UserId">The user ID to set as owner.</param>
    /// <param name="SkipBusinessUnitCheck">If true, skips the business unit validation.</param>
    /// <returns>True if the owning user was successfully set, otherwise false.</returns>
    procedure SetOwningUser(var RecRef: RecordRef; UserId: Guid; SkipBusinessUnitCheck: Boolean): Boolean
    begin
        exit(CDSIntegrationImpl.SetOwningUser(RecRef, UserId, SkipBusinessUnitCheck));
    end;

    /// <summary>
    /// Gets the Dataverse company record that corresponds to the current Business Central company.
    /// </summary>
    /// <param name="CDSCompany">Returns the Dataverse Company record.</param>
    /// <returns>True if the company was found, otherwise false.</returns>
    procedure GetCDSCompany(var CDSCompany: Record "CDS Company"): Boolean
    begin
        exit(CDSIntegrationImpl.TryGetCDSCompany(CDSCompany));
    end;

    /// <summary>
    /// Gets the ID of the business unit that is coupled with the current company.
    /// </summary>
    /// <returns>The GUID of the coupled business unit.</returns>
    procedure GetCoupledBusinessUnitId(): Guid
    begin
        exit(CDSIntegrationImpl.GetCoupledBusinessUnitId());
    end;

    /// <summary>
    /// Checks if the team ownership model is selected for the integration.
    /// </summary>
    /// <returns>True if team ownership model is selected, otherwise false.</returns>
    procedure IsTeamOwnershipModelSelected(): Boolean
    begin
        exit(CDSIntegrationImpl.IsTeamOwnershipModelSelected());
    end;

    /// <summary>
    /// Registers the Dataverse integration assisted setup.
    /// </summary>
    procedure RegisterAssistedSetup()
    begin
        CDSIntegrationImpl.RegisterAssistedSetup();
    end;

    /// <summary>
    /// Resets the cached integration data.
    /// </summary>
    procedure ResetCache()
    begin
        CDSIntegrationImpl.ResetCache();
    end;

    /// <summary>
    /// Gets the metadata for an option set field in Dataverse.
    /// </summary>
    /// <param name="EntityName">The name of the Dataverse entity.</param>
    /// <param name="FieldName">The name of the option set field.</param>
    /// <returns>A dictionary mapping option values to their labels.</returns>
    procedure GetOptionSetMetadata(EntityName: Text; FieldName: Text): Dictionary of [Integer, Text]
    begin
        exit(CDSIntegrationImpl.GetOptionSetMetadata(EntityName, FieldName));
    end;

    /// <summary>
    /// Inserts a new option into an option set field in Dataverse.
    /// </summary>
    /// <param name="EntityName">The name of the Dataverse entity.</param>
    /// <param name="FieldName">The name of the option set field.</param>
    /// <param name="NewOptionLabel">The label for the new option.</param>
    /// <returns>The option value assigned to the new option.</returns>
    procedure InsertOptionSetMetadata(EntityName: Text; FieldName: Text; NewOptionLabel: Text): Integer
    begin
        exit(CDSIntegrationImpl.InsertOptionSetMetadata(EntityName, FieldName, NewOptionLabel));
    end;

    /// <summary>
    /// Inserts a new option into an option set field in Dataverse with a specific option value.
    /// </summary>
    /// <param name="EntityName">The name of the Dataverse entity.</param>
    /// <param name="FieldName">The name of the option set field.</param>
    /// <param name="NewOptionLabel">The label for the new option.</param>
    /// <param name="NewOptionValue">The specific option value to use.</param>
    /// <returns>The option value of the inserted option.</returns>
    procedure InsertOptionSetMetadataWithOptionValue(EntityName: Text; FieldName: Text; NewOptionLabel: Text; NewOptionValue: Integer): Integer
    begin
        exit(CDSIntegrationImpl.InsertOptionSetMetadataWithOptionValue(EntityName, FieldName, NewOptionLabel, NewOptionValue));
    end;

    /// <summary>
    /// Updates the label of an existing option in an option set field in Dataverse.
    /// </summary>
    /// <param name="EntityName">The name of the Dataverse entity.</param>
    /// <param name="FieldName">The name of the option set field.</param>
    /// <param name="OptionValue">The option value to update.</param>
    /// <param name="NewOptionLabel">The new label for the option.</param>
    procedure UpdateOptionSetMetadata(EntityName: Text; FieldName: Text; OptionValue: Integer; NewOptionLabel: Text)
    begin
        CDSIntegrationImpl.UpdateOptionSetMetadata(EntityName, FieldName, OptionValue, NewOptionLabel);
    end;

    /// <summary>
    /// Finds the company ID field in a record reference.
    /// </summary>
    /// <param name="RecRef">The record reference to search.</param>
    /// <param name="CompanyIdFldRef">Returns the field reference for the company ID field.</param>
    /// <returns>True if the company ID field was found, otherwise false.</returns>
    procedure FindCompanyIdField(var RecRef: RecordRef; var CompanyIdFldRef: FieldRef): Boolean
    begin
        exit(CDSIntegrationImpl.FindCompanyIdField(RecRef, CompanyIdFldRef));
    end;

    /// <summary>
    /// Gets the entity metadata for a Dataverse table.
    /// </summary>
    /// <param name="TableNo">The table number of the Dataverse table.</param>
    /// <returns>The entity metadata as a JSON string.</returns>
    procedure GetEntityMetadata(TableNo: Integer): Text
    begin
        exit(CDSIntegrationImpl.GetEntityMetadata(TableNo));
    end;

    /// <summary>
    /// Gets the field metadata for a Dataverse entity and populates a temporary Field record.
    /// </summary>
    /// <param name="TableNo">The table number to use for the Field record.</param>
    /// <param name="IntegrationField">Returns a temporary Integration Field record with the entity's field metadata.</param>
    procedure GetEntityFields(TableNo: Integer; var IntegrationField: Record "Integration Field")
    begin
        CDSIntegrationImpl.GetEntityFields(TableNo, IntegrationField);
    end;

    /// <summary>
    /// Integration event raised before registering the Dataverse connection.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnBeforeRegisterConnection()
    begin
    end;

    /// <summary>
    /// Integration event raised after registering the Dataverse connection.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnAfterRegisterConnection()
    begin
    end;

    /// <summary>
    /// Integration event raised before unregistering the Dataverse connection.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnBeforeUnregisterConnection()
    begin
    end;

    /// <summary>
    /// Integration event raised after unregistering the Dataverse connection.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnAfterUnregisterConnection()
    begin
    end;

    /// <summary>
    /// Integration event raised before activating the Dataverse connection.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnBeforeActivateConnection()
    begin
    end;

    /// <summary>
    /// Integration event raised after activating the Dataverse connection.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnAfterActivateConnection()
    begin
    end;

    /// <summary>
    /// Integration event raised when the Dataverse integration is enabled.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnEnableIntegration()
    begin
    end;

    /// <summary>
    /// Integration event raised when the Dataverse integration is disabled.
    /// </summary>
    [IntegrationEvent(false, false)]
    procedure OnDisableIntegration()
    begin
    end;

    /// <summary>
    /// Integration event to retrieve the list of required Dataverse security roles for integration.
    /// </summary>
    /// <param name="RequiredRoleIdList">Returns a list of required role GUIDs.</param>
    [IntegrationEvent(false, false)]
    procedure OnGetIntegrationRequiredRoles(var RequiredRoleIdList: List of [Guid])
    begin
    end;

    /// <summary>
    /// Integration event to retrieve the list of required Dataverse solutions for integration.
    /// </summary>
    /// <param name="SolutionUniqueNameList">Returns a list of solution unique names.</param>
    [IntegrationEvent(false, false)]
    procedure OnGetIntegrationSolutions(var SolutionUniqueNameList: List of [Text])
    begin
    end;

    /// <summary>
    /// Integration event to determine if detailed logging is enabled for Dataverse integration.
    /// </summary>
    /// <param name="Enabled">Returns true if detailed logging is enabled.</param>
    [IntegrationEvent(false, false)]
    procedure OnGetDetailedLoggingEnabled(var Enabled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event to check if a table has a company ID field.
    /// </summary>
    /// <param name="TableId">The ID of the table to check.</param>
    /// <param name="HasField">Returns true if the table has a company ID field.</param>
    [IntegrationEvent(false, false)]
    procedure OnHasCompanyIdField(TableId: Integer; var HasField: Boolean)
    begin
    end;
}

