// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

codeunit 50199 "BC14 Step Execution Policy" implements "I BC14 Migrator Execution Policy"
{
    var
        ResumeFromMigratorName: Text[100];
        ResumeFromReached: Boolean;

    procedure Initialize(ResumeFromMigratorNameParam: Text[100])
    begin
        ResumeFromMigratorName := ResumeFromMigratorNameParam;
        ResumeFromReached := (ResumeFromMigratorName = '');
    end;

    procedure ShouldRunMigrator(CurrentMigratorName: Text[100]): Boolean
    begin
        if (not ResumeFromReached) and (CurrentMigratorName = ResumeFromMigratorName) then
            ResumeFromReached := true;

        exit(ResumeFromReached);
    end;
}
