// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// This enum specifies the run frequency for AI Test Suites.
/// </summary>
enum 149040 "AIT Run Frequency"
{
    Extensible = false;

    /// <summary>
    /// Specifies that automation tests run on a daily basis.
    /// </summary>
    value(0; Daily)
    {
        Caption = 'Daily';
    }

    /// <summary>
    /// Specifies that automation tests run every week.
    /// </summary>
    value(1; Weekly)
    {
        Caption = 'Weekly';
    }

    /// <summary>
    /// Specifies tests that are not included in the automation tests, but can be run manually.
    /// </summary>
    value(2; Manual)
    {
        Caption = 'Manual';
    }

    /// <summary>
    /// Specifies that automation tests run on a daily basis against preview models.
    /// </summary>
    value(3; Preview)
    {
        Caption = 'Preview';
    }

    /// <summary>
    /// Specifies a small group of tests that is used for validation, e.g. of Copilot.
    /// </summary>
    value(4; Validation)
    {
        Caption = 'Validation';
    }
}
