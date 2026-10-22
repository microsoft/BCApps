// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Applies runtime settings from the current flat configuration. Layout is generated separately.
/// </summary>
interface "ITest Configuration Provider"
{
    procedure Initialize(TestConfiguration: Record "Test Configuration");
    procedure OnBeforeTestMethodRun();
    procedure Reset();
}
