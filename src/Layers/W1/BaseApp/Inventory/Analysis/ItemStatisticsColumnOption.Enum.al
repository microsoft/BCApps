// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

enum 5822 "Item Statistics Column Option"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Profit Calculation")
    {
        Caption = 'Profit Calculation';
    }
    value(1; "Cost Specification")
    {
        Caption = 'Cost Specification';
    }
    value(2; "Purch. Item Charge Spec.")
    {
        Caption = 'Purch. Item Charge Spec.';
    }
    value(3; "Sales Item Charge Spec.")
    {
        Caption = 'Sales Item Charge Spec.';
    }
    value(4; "Period")
    {
        Caption = 'Period';
    }
    value(5; "Location")
    {
        Caption = 'Location';
    }
    value(99; "Undefined")
    {
        Caption = 'Undefined';
    }
}
