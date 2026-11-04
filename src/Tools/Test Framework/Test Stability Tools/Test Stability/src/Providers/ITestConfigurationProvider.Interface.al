// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

/// <summary>
/// Applies runtime settings from the current flat configuration. Layout is generated separately.
/// Providers initialize per codeunit block, apply before procedures/cases, and reset only owned state.
/// Methods default to no operation.
/// </summary>
interface ITestConfigurationProvider
{
    procedure Initialize(TestConfiguration: Record "Test Configuration")
    begin
    end;

    procedure ApplyBeforeTestMethodRun()
    begin
    end;

    procedure Reset()
    begin
    end;
}
