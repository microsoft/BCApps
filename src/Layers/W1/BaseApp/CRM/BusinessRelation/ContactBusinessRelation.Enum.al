// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

enum 5056 "Contact Business Relation"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; Customer)
    {
        Caption = 'Customer';
    }
    value(2; Vendor)
    {
        Caption = 'Vendor';
    }
    value(3; "Bank Account")
    {
        Caption = 'Bank Account';
    }
    value(4; Employee)
    {
        Caption = 'Employee';
    }
    value(100; None)
    {
        Caption = 'None';
    }
    value(101; Other)
    {
        Caption = 'Other';
    }
    value(102; Multiple)
    {
        Caption = 'Multiple';
    }
}
