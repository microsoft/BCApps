// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// Whether to automatically configure this result on new tests and new templates.
/// </summary>
enum 20417 "Qlty. Result Finish Allowed"
{
    Caption = 'Result Finish Allowed';

    value(0; "Allow Finish")
    {
        Caption = 'Allow Finish';
    }
    value(1; "Do Not Allow Finish")
    {
        Caption = 'Do Not Allow Finish';
    }
}