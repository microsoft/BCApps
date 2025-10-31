// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Manufacturing;

/// <summary>
/// Helps determine the behavior of when to create tests with production output.
/// </summary>
enum 20442 "Qlty. Auto. Production Trigger"
{
    Caption = 'Quality Automatic Production Trigger';

    value(0; OnAnyOutput)
    {
        Caption = 'Any Output Entry (time or quantity)';
    }
    value(1; OnAnyQuantity)
    {
        Caption = 'Any Quantity Output';
    }
    value(2; OnlyWithQuantity)
    {
        Caption = 'Only with Quantity';
    }
    value(3; OnlyWithScrap)
    {
        Caption = 'Only with Scrap';
    }
}
