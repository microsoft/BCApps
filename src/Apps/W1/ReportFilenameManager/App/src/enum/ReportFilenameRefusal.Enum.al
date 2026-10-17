// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
enum 50116 "Report Filename Refusal"
{
    // Why a name every placeholder gave a value to is still not used as a file name, so that
    // Test Pattern can say so instead of blaming a placeholder. None means the name is used.

    // Not extensible: an internal enum cannot be reached by another extension, so declaring
    // it extensible would promise something impossible.
    Extensible = false;
    Caption = 'Report Filename Refusal';
    Access = Internal;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; "Nothing Usable")
    {
        Caption = 'Nothing Usable';
    }
    value(2; Reserved)
    {
        Caption = 'Reserved';
    }
    value(3; "Nothing After Cut")
    {
        Caption = 'Nothing After Cut';
    }
    value(4; "Reserved After Cut")
    {
        Caption = 'Reserved After Cut';
    }
}
