// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

enum 1236 "Transformation Rule Group"
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Find Value")
    {
        Caption = 'Find Value';
    }
    value(2; "Replace Value")
    {
        Caption = 'Replace Value';
    }
    value(3; "Start Position")
    {
        Caption = 'Start Position';
    }
    value(4; "End Position")
    {
        Caption = 'End Position';
    }
    value(5; "Field Lookup")
    {
        Caption = 'Field Lookup';
    }
    value(6; "Extract from Date")
    {
        Caption = 'Extract from Date';
    }
    value(7; "Round")
    {
        Caption = 'Round';
    }
}