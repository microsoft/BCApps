// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

enum 20 "G/L Account Report Type"
{
    AssignmentCompatibility = true;
    Extensible = true;

    value(0; "Income Statement") { Caption = 'Income Statement'; }
    value(1; "Balance Sheet") { Caption = 'Balance Sheet'; }
}