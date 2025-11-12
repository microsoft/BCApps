// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Grade;

/// <summary>
/// Whether to automatically configure this grade on new fields and new templates.
/// </summary>
enum 20417 "Qlty. Grade Finish Allowed"
{
    Caption = 'Grade Finish Allowed';

    value(0; "Allow Finish")
    {
        Caption = 'Allow Finish';
    }
    value(1; "Do Not Allow Finish")
    {
        Caption = 'Do Not Allow Finish';
    }
}