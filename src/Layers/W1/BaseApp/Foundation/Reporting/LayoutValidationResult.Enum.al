// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Shared.Report;

/// <summary>
/// The result of validating a report layout with the ValidateReportLayout procedure of the "Report Layouts" codeunit.
/// </summary>
enum 9661 "Layout Validation Result"
{
    Access = Public;
    Extensible = false;

    /// <summary>
    /// The layout is valid.
    /// </summary>
    value(0; Valid)
    {
        Caption = 'Valid';
    }
    /// <summary>
    /// The layout is valid, but it references theme or header/footer parts that are missing or obsolete.
    /// </summary>
    value(1; "Valid with Warnings")
    {
        Caption = 'Valid with Warnings';
    }
    /// <summary>
    /// The layout is not valid.
    /// </summary>
    value(2; Invalid)
    {
        Caption = 'Invalid';
    }
    /// <summary>
    /// The layout cannot be validated because validation is not supported for its layout format.
    /// </summary>
    value(3; "Not Supported")
    {
        Caption = 'Not Supported';
    }
}
