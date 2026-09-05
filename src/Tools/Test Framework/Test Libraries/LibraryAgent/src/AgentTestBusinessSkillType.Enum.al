// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Agents;

/// <summary>
/// Specifies the Business IQ skill type used by agent tests.
/// </summary>
enum 130566 "Agent Test Business Skill Type"
{
    Extensible = false;

    value(0; Policy)
    {
        Caption = 'Policy';
    }
    value(1; Workflow)
    {
        Caption = 'Workflow';
    }
    value(2; Rule)
    {
        Caption = 'Rule';
    }
}
