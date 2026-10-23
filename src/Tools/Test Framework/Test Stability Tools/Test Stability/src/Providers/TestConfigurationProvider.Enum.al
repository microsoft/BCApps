// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

/// <summary>
/// Runtime providers initialized for each suite. Extensions can read their settings from the configuration.
/// </summary>
enum 130482 "Test Configuration Provider" implements ITestConfigurationProvider
{
    Extensible = true;

    value(0; Seed)
    {
        Caption = 'Random seed';
        Implementation = ITestConfigurationProvider = "Seed Test Config. Provider";
    }
    value(1; WorkDateFuture)
    {
        Caption = 'WorkDate in the future';
        Implementation = ITestConfigurationProvider = "WorkDate Test Config. Prov.";
    }
}
