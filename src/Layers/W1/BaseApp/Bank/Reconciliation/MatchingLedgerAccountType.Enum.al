// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

enum 1248 "Matching Ledger Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Customer") { Caption = 'Customer'; }
    value(1; "Vendor") { Caption = 'Vendor'; }
    value(2; "G/L Account") { Caption = 'G/L Account'; }
    value(3; "Bank Account") { Caption = 'Bank Account'; }
    value(4; "Employee") { Caption = 'Employee'; }
}
