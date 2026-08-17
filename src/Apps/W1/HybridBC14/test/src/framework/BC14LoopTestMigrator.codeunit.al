// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Test-only per-record migrator used by BC14 Migration Loop Tests. Iterates
/// over the BC14 Country/Region buffer table (convenient because it has a
/// single-field Code primary key) and intentionally raises an error when the
/// Code starts with 'FAIL', so loop tests can exercise the success and failure
/// branches of BC14 Migration Loop.RunRecordLoop without depending on any real
/// migrator's transformation logic.
/// </summary>
codeunit 148913 "BC14 Loop Test Migrator"
{
    Access = Internal;
    TableNo = "BC14 Country/Region";

    trigger OnRun()
    begin
        if CopyStr(Rec.Code, 1, 4) = 'FAIL' then
            Error(IntentionalFailureErr, Rec.Code);
    end;

    var
        IntentionalFailureErr: Label 'Intentional test failure for record %1.', Comment = '%1 = source record code';
}
