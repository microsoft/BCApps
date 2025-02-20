// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The Copilot Capability codeunit is used to register, modify, and delete Copilot capabilities.
/// </summary>
enum 7773 "Copilot Quota Usage Type"
{
    Access = Public;
    Extensible = false;
    Scope = OnPrem;

    /// <summary>
    /// The Copilot Capability is in preview.
    /// </summary>
    value(0; GenAIAnswer)
    {
        Caption = 'Gen AI Answer';
    }

    /// <summary>
    /// The Copilot Capability is in preview.
    /// </summary>
    value(1; AutonomousAction)
    {
        Caption = 'Autonomous Action';
    }
}