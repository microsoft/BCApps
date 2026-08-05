// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6919 "Expense Vendor Status"
{
    Access = Internal;
    Caption = 'Expense Vendor Status';

    value(0; Unmatched) { Caption = 'Unmatched'; }
    value(1; Matched) { Caption = 'Matched'; }
    value(2; "Pending Approval") { Caption = 'Pending Approval'; }
    value(3; Approved) { Caption = 'Approved'; }
    value(4; Rejected) { Caption = 'Rejected'; }
}
