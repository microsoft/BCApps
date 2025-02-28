// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Enumeration of valid types of usage of the Copilot Quota.
/// </summary>
enum 7785 "Copilot Quota Usage Type"
{
    Caption = 'Copilot Quota Usage Type';
    Access = Public;
    Extensible = false;

    /// <summary>
    /// Represents a Generative AI Answer usage type.
    /// </summary>
    value(0; "Generative AI Answer")
    {
        Caption = 'Generative AI Answer';
    }

    /// <summary>
    /// Represents an Autonomous Action usage type.
    /// </summary>
    value(1; "Autonomous Action")
    {
        Caption = 'Autonomous Action';
    }
}