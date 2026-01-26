// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

enum 11000006 "CBG Statement Information Type"
{
    Extensible = true;

    value(0; "Description and Sundries")
    {
        Caption = 'Description and Sundries';
    }
    value(1; "Account No. Balancing Account")
    {
        Caption = 'Account No. Balancing Account';
    }
    value(2; "Name Acct. Holder")
    {
        Caption = 'Name Acct. Holder';
    }
    value(3; "Address Acct. Holder")
    {
        Caption = 'Address Acct. Holder';
    }
    value(4; "City Acct. Holder")
    {
        Caption = 'City Acct. Holder';
    }
    value(5; "Payment Identification")
    {
        Caption = 'Payment Identification';
    }
}
