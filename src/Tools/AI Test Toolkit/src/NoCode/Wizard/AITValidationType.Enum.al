// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Specifies the type of validation for a test.
/// </summary>
enum 149077 "AIT Validation Type"
{
    Caption = 'Validation Type';
    Extensible = true;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; DatabaseRecords)
    {
        Caption = 'Database Records';
    }
    value(2; MessageContent)
    {
        Caption = 'Message Content';
    }
    value(3; ValidationPrompt)
    {
        Caption = 'Validation Prompt';
    }
    value(4; InterventionRequest)
    {
        Caption = 'Intervention Request';
    }
}
