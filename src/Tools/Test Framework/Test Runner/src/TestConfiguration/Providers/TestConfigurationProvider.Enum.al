// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Runtime providers initialized for each suite. Extensions can read their settings from the configuration.
/// </summary>
enum 130466 "Test Configuration Provider" implements "ITest Configuration Provider"
{
    Extensible = true;

    value(0; Seed)
    {
        Caption = 'Random seed';
        Implementation = "ITest Configuration Provider" = "Seed Test Config. Provider";
    }
    value(1; WorkDateFuture)
    {
        Caption = 'WorkDate in the future';
        Implementation = "ITest Configuration Provider" = "WorkDate Test Config. Prov.";
    }
}
