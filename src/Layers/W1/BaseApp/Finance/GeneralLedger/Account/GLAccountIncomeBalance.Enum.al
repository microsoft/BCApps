// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

enum 18 "G/L Account Income/Balance"
{
    AssignmentCompatibility = true;
    Extensible = false;

    value(0; " ") { Caption = ' '; }
    value(1; "Income Statement") { Caption = 'Income Statement'; }
    value(2; "Balance Sheet") { Caption = 'Balance Sheet'; }
}
