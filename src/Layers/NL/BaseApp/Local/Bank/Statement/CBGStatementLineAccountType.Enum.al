// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

#pragma warning disable AL0659 // Accepted: renaming the enum is a breaking change
enum 11000007 "CBG Statement Line Account Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "G/L Account")
    {
        Caption = 'G/L Account';
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
}
