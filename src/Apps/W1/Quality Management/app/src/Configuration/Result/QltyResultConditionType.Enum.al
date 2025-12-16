// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// What a condition configuration applies to.
/// </summary>
enum 20414 "Qlty. Result Condition Type"
{
    Caption = 'Quality Result Condition Type';

    value(0; Test)
    {
        Caption = 'Test';
    }
    value(1; Template)
    {
        Caption = 'Template';
    }
    value(2; Inspection)
    {
        Caption = 'Inspection';
    }
}
