// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Feedback;

/// <summary>
/// Specifies the type of feedback being provided.
/// </summary>
enum 1599 "Feedback Type"
{
    /// <summary>
    /// General feedback, not tied to a specific feature.
    /// </summary>
    value(0; "General Feedback")
    {
        Caption = 'General Feedback';
    }

    /// <summary>
    /// Feedback related to a specific Copilot feature.
    /// </summary>
    value(1; "Copilot Feedback")
    {
        Caption = 'Copilot Feedback';
    }
}