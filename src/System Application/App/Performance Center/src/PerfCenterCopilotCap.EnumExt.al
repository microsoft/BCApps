// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.AI;

/// <summary>
/// Registers the Performance Center Copilot capability used for AI-assisted performance analysis.
/// </summary>
enumextension 5477 "Perf. Center Copilot Cap." extends "Copilot Capability"
{
    value(5477; "Performance Center")
    {
        Caption = 'AI-assisted performance analysis in Performance Center';
    }
}
