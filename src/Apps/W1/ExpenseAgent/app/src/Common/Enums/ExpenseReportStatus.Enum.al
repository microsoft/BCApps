// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6910 "Expense Report Status"
{
    Access = Internal;
    Caption = 'Expense Report Status';

    value(0; Open) { Caption = 'Open'; }
    value(1; "Pending Approval") { Caption = 'Pending Approval'; }
    value(2; Released) { Caption = 'Released'; }
    value(3; Approved) { Caption = 'Approved'; }
    value(4; Rejected) { Caption = 'Rejected'; }
    value(5; "Processed for Payment") { Caption = 'Processed for Payment'; }
    value(6; Completed) { Caption = 'Completed'; }
    value(7; "Interim Approved") { Caption = 'Interim Approved'; }
}