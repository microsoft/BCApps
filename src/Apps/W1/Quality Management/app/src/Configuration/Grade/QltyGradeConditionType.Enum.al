// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Grade;

/// <summary>
/// What a condition configuration applies to.
/// </summary>
enum 20414 "Qlty. Grade Condition Type"
{
    Caption = 'Quality Grade Condition Type';

    value(0; Field)
    {
        Caption = 'Field';
    }
    value(1; Template)
    {
        Caption = 'Template';
    }
    value(2; Test)
    {
        Caption = 'Test';
    }
}
