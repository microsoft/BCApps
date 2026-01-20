// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Defines the supported field types for query schema fields.
/// </summary>
enum 149063 "AIT Query Field Type"
{
    Caption = 'AI Test Query Field Type';
    Extensible = true;
    Access = Public;

    value(0; Text)
    {
        Caption = 'Text';
    }
    value(1; MultilineText)
    {
        Caption = 'Multiline Text';
    }
    value(2; Boolean)
    {
        Caption = 'Boolean';
    }
    value(3; Integer)
    {
        Caption = 'Integer';
    }
    value(4; FileList)
    {
        Caption = 'File List';
    }
    value(5; JsonObject)
    {
        Caption = 'JSON Object';
    }
}
