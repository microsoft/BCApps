// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

/// <summary>
/// Enum to track the current state of BC14 migration.
/// Used to support pause/resume functionality when Stop On First Error is enabled.
/// </summary>
enum 50182 "BC14 Migration State"
{
    Extensible = false;

    value(0; NotStarted)
    {
        Caption = 'Not Started';
    }
    value(1; Setup)
    {
        Caption = 'Setup Migrations';
    }
    value(2; Master)
    {
        Caption = 'Master Migrations';
    }
    value(3; Transaction)
    {
        Caption = 'Transaction Migrations';
    }
    value(4; Historical)
    {
        Caption = 'Historical Migrations';
    }
    value(5; Posting)
    {
        Caption = 'Journal Posting';
    }
    value(6; Completed)
    {
        Caption = 'Completed';
    }
    value(7; Paused)
    {
        Caption = 'Paused (Error)';
    }
}
