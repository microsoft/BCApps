// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

/// <summary>
/// This is used to influence how the Sample Size on an inspection is initially set.
/// </summary>
enum 20463 "Qlty. Sample Size Source"
{
    Caption = 'Quality Sample Size Source';

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Fixed Quantity")
    {
        Caption = 'Fixed Quantity';
    }
    value(2; "Percent of Quantity")
    {
        Caption = 'Percent of Quantity';
    }
}
