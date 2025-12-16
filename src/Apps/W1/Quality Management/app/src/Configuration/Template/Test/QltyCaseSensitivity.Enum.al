// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

/// <summary>
/// Used to help control if pass/fail result criteria is case sensitive or not.
/// </summary>
enum 20440 "Qlty. Case Sensitivity"
{
    Caption = 'Quality Case Sensitivity';
    Extensible = false;

    value(0; Sensitive)
    {
        Caption = 'Sensitive';
    }
    value(1; Insensitive)
    {
        Caption = 'Insensitive';
    }
}
