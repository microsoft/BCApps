// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

enum 2670 "Destination Account Type"
{
    Extensible = true;

    value(0; "G/L Account")
    {
        Caption = 'G/L Account';
    }

    value(1; "Bank Account")
    {
        Caption = 'Bank Account';
    }

    value(2; "Inherit from Parent")
    {
        Caption = 'Inherit from parent';
    }
}
