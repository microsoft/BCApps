// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// Whether to automatically configure this result on new tests and new templates.
/// </summary>
enum 20413 "Qlty. Result Copy Behavior"
{
    Caption = 'Quality Result Copy Behavior';

    value(0; "Automatically copy the result")
    {
        Caption = 'Automatically copy the result';
    }
    value(1; "Do not automatically copy")
    {
        Caption = 'Do not automatically copy';
    }
}
