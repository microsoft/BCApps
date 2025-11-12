// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

enum 5468 "Picture Entity Parent Type"
{
    AssignmentCompatibility = true;
    Extensible = false;

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
    value(5; "Contact")
    {
        Caption = 'Contact';
    }
}