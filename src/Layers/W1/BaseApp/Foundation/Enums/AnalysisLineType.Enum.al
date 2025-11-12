// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Enums;

enum 7114 "Analysis Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Item)
    {
        Caption = 'Item';
    }
    value(1; "Item Group")
    {
        Caption = 'Item Group';
    }
    value(2; Customer)
    {
        Caption = 'Customer';
    }
    value(3; "Customer Group")
    {
        Caption = 'Customer Group';
    }
    value(4; Vendor)
    {
        Caption = 'Vendor';
    }
    value(5; "Sales/Purchase Person")
    {
        Caption = 'Salesperson/Purchaser';
    }
    value(6; Formula)
    {
        Caption = 'Formula';
    }
}
