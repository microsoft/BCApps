// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

interface "I BC14 Migrator Execution Policy"
{
    procedure Initialize(ResumeFromMigratorName: Text[100]);

    procedure ShouldRunMigrator(CurrentMigratorName: Text[100]): Boolean;
}
