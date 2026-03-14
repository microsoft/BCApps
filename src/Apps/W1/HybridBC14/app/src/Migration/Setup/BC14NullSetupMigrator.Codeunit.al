// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

/// <summary>
/// Null implementation of ISetupMigrator.
/// Used as default implementation when no specific migrator is assigned.
/// </summary>
codeunit 50186 "BC14 Null Setup Migrator" implements "ISetupMigrator"
{
    procedure GetName(): Text[250]
    begin
        exit('');
    end;

    procedure IsEnabled(): Boolean
    begin
        exit(false);
    end;

    procedure Migrate(StopOnFirstError: Boolean): Boolean
    begin
        exit(true);
    end;
}
