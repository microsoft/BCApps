// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Grade;

/// <summary>
/// Whether to try and make this grade more prominent, this can optionally be used on some reports and forms.
/// </summary>
enum 20416 "Qlty. Grade Visibility"
{
    Caption = 'Quality Grade Visibility';

    value(0; "Configuration only")
    {
        Caption = 'Configuration only';
    }
    value(1; Promoted)
    {
        Caption = 'Promoted';
    }
}
