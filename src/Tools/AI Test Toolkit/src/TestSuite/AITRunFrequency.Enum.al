// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Specifies the run frequency for AI Eval Suites.
/// </summary>
enum 149040 "AIT Run Frequency"
{
    Extensible = false;

    /// <summary>
    /// Specifies evals that are not included in automation, but can be run manually by engineers.
    /// </summary>
    value(0; Manual)
    {
        Caption = 'Manual';
    }

    /// <summary>
    /// Specifies that automation evals run on a daily basis.
    /// </summary>
    value(1; Daily)
    {
        Caption = 'Daily';
    }

    /// <summary>
    /// Specifies that automation evals run every week.
    /// </summary>
    value(2; Weekly)
    {
        Caption = 'Weekly';
    }
}
