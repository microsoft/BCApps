// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 7113 "Analysis Value Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Quantity)
    {
        Caption = 'Quantity';
    }
    value(2; "Sales Amount")
    {
        Caption = 'Sales Amount';
    }
    value(3; "Cost Amount")
    {
        Caption = 'Cost Amount';
    }
    value(4; "Non-Invntble Amount")
    {
        Caption = 'Non-Invntble Amount';
    }
    value(5; "Unit Price")
    {
        Caption = 'Unit Price';
    }
    value(6; "Standard Cost")
    {
        Caption = 'Standard Cost';
    }
    value(7; "Indirect Cost")
    {
        Caption = 'Indirect Cost';
    }
    value(8; "Unit Cost")
    {
        Caption = 'Unit Cost';
    }
}
