// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

enum 229 "Sales Order Print Option"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(1; "Order Confirmation")
    {
        Caption = 'Order Confirmation';
    }
    value(2; "Pro Forma Invoice")
    {
        Caption = 'Pro Forma Invoice';
    }
    value(3; "Work Order")
    {
        Caption = 'Work Order';
    }
    value(4; "Pick Instruction")
    {
        Caption = 'Pick Instruction';
    }
}
