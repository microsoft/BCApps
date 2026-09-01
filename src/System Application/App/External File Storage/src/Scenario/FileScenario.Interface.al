// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

interface "File Scenario"
{
    /// <summary>
    /// Called before adding or modifying a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param>
    /// <returns>True if the operation is allowed; otherwise false.</returns>
    procedure BeforeAddOrModifyFileScenarioCheck(Scenario: Enum "File Scenario"; Connector: Enum System.ExternalFileStorage."Ext. File Storage Connector") SkipInsertOrModify: Boolean;

    /// <summary>
    /// Called to get additional setup for a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param>
    /// <returns>True if additional setup is available, otherwise false.</returns>
    procedure GetAdditionalScenarioSetup(Scenario: Enum "File Scenario"; Connector: Enum System.ExternalFileStorage."Ext. File Storage Connector") SetupExist: Boolean;

    /// <summary>
    /// Called before deleting a file scenario.
    /// </summary>
    /// <param name="Scenario">The ID of the file scenario.</param>
    /// <param name="Connector">The file storage connector.</param>
    /// <returns>True if the delete operation is handled and should not proceed; otherwise false.</returns>
    procedure BeforeDeleteFileScenarioCheck(Scenario: Enum "File Scenario"; Connector: Enum System.ExternalFileStorage."Ext. File Storage Connector") SkipDelete: Boolean;

    /// <summary>
    /// Called before reassigning a file scenario from one to another.
    /// </summary>
    /// <param name="CurrentScenario">The ID of the old file scenario.</param>
    /// <returns>True if the reassign operation is handled and should not proceed, otherwise false.</returns>
    procedure BeforeReassignFileScenarioCheck(Scenario: Enum "File Scenario") SkipReassign: Boolean
}
