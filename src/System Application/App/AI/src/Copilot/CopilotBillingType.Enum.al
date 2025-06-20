// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The billable type of the Copilot Capability.
/// </summary>
enum 7786 "Copilot Billing Type"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// The Copilot Capability is in free.
    /// </summary>
    value(0; "Not Billed")
    {
        Caption = 'Not Billed';
    }

    /// <summary>
    /// The Copilot Capability is billed by Microsoft.
    /// </summary>
    value(1; "Microsoft Billed")
    {
        Caption = 'Microsoft billed';
    }

    /// <summary>
    /// The Copilot Capability is billed by partner/publisher.
    /// </summary>
    value(2; "Custom Billed")
    {
        Caption = 'Custom billed';
    }

    /// <summary>
    /// UnDefined, only for internal use.
    /// </summary>
    value(3; "Undefined")
    {
        Caption = 'Undefined';
    }
}