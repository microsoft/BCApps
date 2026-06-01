// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Dispositions;

/// <summary>
/// Defines how quantities should be moved with the variety of reactions/dispositions.
/// </summary>
enum 20458 "Qlty. Quantity Behavior"
{
    Caption = 'Quality Quantity Behavior', Locked = true;
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "Specific Quantity")
    {
        Caption = 'Specific Quantity';
    }
    value(1; "Item Tracked Quantity")
    {
        Caption = 'Item Tracked Quantity';
    }
    value(2; "Sample Quantity")
    {
        Caption = 'Sample Quantity';
    }
    value(3; "Failed Quantity")
    {
        Caption = 'Failed Quantity';
    }
    value(4; "Passed Quantity")
    {
        Caption = 'Passed Quantity';
    }
}
