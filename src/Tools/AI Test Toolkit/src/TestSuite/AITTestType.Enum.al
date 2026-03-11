// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Specifies the type of AI eval.
/// </summary>
enum 149041 "AIT Test Type"
{
    Extensible = false;

    /// <summary>
    /// Copilot eval type.
    /// </summary>
    value(0; Copilot)
    {
        Caption = 'Copilot';
    }

    /// <summary>
    /// Agent eval type.
    /// </summary>
    value(1; Agent)
    {
        Caption = 'Agent';
    }

    /// <summary>
    /// MCP eval type.
    /// </summary>
    value(2; MCP)
    {
        Caption = 'MCP';
    }
}
