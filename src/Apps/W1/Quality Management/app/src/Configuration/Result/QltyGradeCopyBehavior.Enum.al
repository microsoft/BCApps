// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// Whether to automatically configure this grade on new fields and new templates.
/// </summary>
enum 20413 "Qlty. Grade Copy Behavior"
{
    Caption = 'Quality Grade Copy Behavior';

    value(0; "Automatically copy the grade")
    {
        Caption = 'Automatically copy the grade';
    }
    value(1; "Do not automatically copy")
    {
        Caption = 'Do not automatically copy';
    }
}
