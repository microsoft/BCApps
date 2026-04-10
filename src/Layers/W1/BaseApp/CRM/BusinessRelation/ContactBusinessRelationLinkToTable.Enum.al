// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.BusinessRelation;

#pragma warning disable AL0659
enum 5057 "Contact Business Relation Link To Table" implements "Contact Business Relation Link"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;
    DefaultImplementation = "Contact Business Relation Link" = "Contact BRL Default";

    value(0; " ")
    {
    }
    value(1; Customer)
    {
        Caption = 'Customer';
        Implementation = "Contact Business Relation Link" = "Contact BRL Customer";
    }
    value(2; Vendor)
    {
        Caption = 'Vendor';
        Implementation = "Contact Business Relation Link" = "Contact BRL Vendor";
    }
    value(3; "Bank Account")
    {
        Caption = 'Bank Account';
        Implementation = "Contact Business Relation Link" = "Contact BRL Bank Account";
    }
    value(4; Employee)
    {
        Caption = 'Employee';
        Implementation = "Contact Business Relation Link" = "Contact BRL Employee";
    }
}
