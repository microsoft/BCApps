// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Applies runtime settings from the current flat configuration. Layout is generated separately.
/// </summary>
interface ITestConfigurationProvider
{
    procedure Initialize(TestConfiguration: Record "Test Configuration");
    procedure ApplyBeforeTestMethodRun();
    procedure Reset();
}
