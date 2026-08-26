// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// The set of test configuration providers. The enum is extensible so other apps can add their own
/// providers: add a value that implements "ITest Configuration Provider" and it becomes available on
/// a test configuration line.
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
    value(2; OneByOne)
    {
        Caption = 'One by one';
        Implementation = "ITest Configuration Provider" = "One By One Test Config. Prov.";
    }
    value(3; ReverseOrder)
    {
        Caption = 'Reverse order';
        Implementation = "ITest Configuration Provider" = "Reverse Order Test Cfg. Prov.";
    }
}
