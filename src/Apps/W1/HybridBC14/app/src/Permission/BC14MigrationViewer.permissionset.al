// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using System.Integration;

/// <summary>
/// Viewer permission set for BC14 Cloud Migration.
/// This permission set provides read-only access to monitor migration status and errors.
/// Safe to assign to users who need to view migration progress without making changes.
/// </summary>
permissionset 46851 "BC14MigrationViewer"
{
    Assignable = true;
    Caption = 'Cloud Migration - Viewer';

    Permissions =
        tabledata BC14CompanyMigrationInfo = R,
        tabledata "Data Migration Error" = R,
        tabledata "BC14 Global Migration Settings" = R;
}
