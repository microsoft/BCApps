// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// This enum has the Status of the AI Test Line.
/// </summary>
enum 149031 "AIT Line Status"
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
    /// Specifies that the AI Test Line state is Starting.
    /// </summary>
    value(10; Starting)
    {
        Caption = 'Starting';
    }
    /// <summary>
    /// Specifies that the AI Test Line state is Running.
    /// </summary>
    value(20; Running)
    {
        Caption = 'Running';
    }

    /// <summary>
    /// Specifies that the AI Test Line state is Completed.
    /// </summary>
    value(30; Completed)
    {
        Caption = 'Completed';
    }

    /// <summary>
    /// Specifies that the AI Test Line state is Cancelled.
    /// </summary>
    value(40; Cancelled)
    {
        Caption = 'Cancelled';
    }
}