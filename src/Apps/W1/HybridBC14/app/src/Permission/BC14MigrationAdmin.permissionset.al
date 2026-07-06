// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using System.Integration;

/// <summary>
/// Admin permission set for BC14 Cloud Migration.
/// This permission set should only be assigned to administrators who need full control
/// over the migration process, including modifying configuration and deleting error logs.
/// </summary>
permissionset 46850 "BC14 Migration Admin"
{
    Assignable = false;
    Caption = 'Cloud Migration - Admin';

    Permissions =
        tabledata BC14CompanyMigrationInfo = RIMD,
        tabledata "Data Migration Error" = RIMD,
        tabledata "BC14 Global Migration Settings" = RIMD;
}
