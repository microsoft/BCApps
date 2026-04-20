// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Specifies the type of AI eval.
/// </summary>
enum 149041 "AIT Test Type" implements "AIT Eval Limit Provider"
{
    Extensible = false;
    DefaultImplementation = "AIT Eval Limit Provider" = "AIT Eval No Limit";

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
        Implementation = "AIT Eval Limit Provider" = "AIT Eval Monthly Copilot Cred.";
    }

    /// <summary>
    /// MCP eval type.
    /// </summary>
    value(2; MCP)
    {
        Caption = 'MCP';
    }
}
