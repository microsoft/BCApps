// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// This enum has the Status of the AI Test Suite.
/// </summary>
enum 149030 "AIT Test Suite Status"
{
    Extensible = false;

    /// <summary>
    /// Specifies the initial state.
    /// </summary>
    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }

    /// <summary>
    /// Specifies that the AI Test Suite state is Running.
    /// </summary>
    value(20; Running)
    {
        Caption = 'Running';
    }

    /// <summary>
    /// Specifies that the AI Test Suite state is Completed.
    /// </summary>
    value(30; Completed)
    {
        Caption = 'Completed';
    }

    /// <summary>
    /// Specifies that the AI Test Suite state is Cancelled.
    /// </summary>
    value(40; Cancelled)
    {
        Caption = 'Cancelled';
    }
}