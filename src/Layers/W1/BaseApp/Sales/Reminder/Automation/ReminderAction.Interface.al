// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Defines the contract for reminder automation actions including setup, validation, and execution methods.
/// </summary>
interface "Reminder Action"
{
    /// <summary>
    /// Initializes the reminder action with the specified system ID.
    /// </summary>
    /// <param name="ReminderActionSystemId">The system ID of the reminder action to initialize.</param>
    procedure Initialize(ReminderActionSystemId: Guid);
    /// <summary>
    /// Gets the setup record information for this reminder action.
    /// </summary>
    /// <param name="TableID">Returns the table ID of the setup record.</param>
    /// <param name="RecordSystemId">Returns the system ID of the setup record.</param>
    procedure GetSetupRecord(var TableID: Integer; var RecordSystemId: Guid);
    /// <summary>
    /// Gets the system ID of this reminder action.
    /// </summary>
    /// <returns>The system ID of the reminder action.</returns>
    procedure GetReminderActionSystemId(): Guid;
    /// <summary>
    /// Gets the unique identifier code for this action type.
    /// </summary>
    /// <returns>The action ID code.</returns>
    procedure GetID(): Code[50];
    /// <summary>
    /// Gets a summary description of this reminder action's current configuration.
    /// </summary>
    /// <returns>A text summary of the action.</returns>
    procedure GetSummary(): Text;
    /// <summary>
    /// Creates a new reminder action with the specified codes.
    /// </summary>
    /// <param name="ActionCode">The code for the new action.</param>
    /// <param name="ActionGroupCode">The action group code the new action belongs to.</param>
    /// <returns>True if the action was created successfully, otherwise false.</returns>
    procedure CreateNew(ActionCode: Code[50]; ActionGroupCode: Code[50]): Boolean;
    /// <summary>
    /// Opens the setup page for configuring this reminder action.
    /// </summary>
    procedure Setup();
    /// <summary>
    /// Deletes this reminder action and its associated setup.
    /// </summary>
    procedure Delete();
    /// <summary>
    /// Invokes the reminder action to perform its configured operation.
    /// </summary>
    /// <param name="ErrorOccured">Returns true if an error occurred during invocation.</param>
    procedure Invoke(var ErrorOccured: Boolean);
    /// <summary>
    /// Validates that the reminder action is properly configured and ready to be invoked.
    /// </summary>
    procedure ValidateSetup();
}