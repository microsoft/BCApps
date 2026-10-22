// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

codeunit 130476 "WorkDate Test Config. Prov." implements "ITest Configuration Provider"
{
    SingleInstance = true;

    var
        InitialWorkDate: Date;
        ConfiguredWorkDate: Date;

    procedure Initialize(TestConfiguration: Record "Test Configuration")
    begin
        InitialWorkDate := WorkDate();
        Clear(ConfiguredWorkDate);
        if Format(TestConfiguration."WorkDate Offset") <> '' then
            ConfiguredWorkDate := CalcDate(TestConfiguration."WorkDate Offset", InitialWorkDate);
    end;

    procedure OnBeforeTestMethodRun()
    begin
        if ConfiguredWorkDate <> 0D then
            WorkDate(ConfiguredWorkDate);
    end;

    procedure Reset()
    begin
        if InitialWorkDate <> 0D then
            WorkDate(InitialWorkDate);
        Clear(InitialWorkDate);
        Clear(ConfiguredWorkDate);
    end;
}
