// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

enum 352 "Default Dimension Parent Type"
{
    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Customer)
    {
        Caption = 'Customer';
    }
    value(2; "Item")
    {
        Caption = 'Item';
    }
    value(3; "Vendor")
    {
        Caption = 'Vendor';
    }
    value(4; "Employee")
    {
        Caption = 'Employee';
    }
}
