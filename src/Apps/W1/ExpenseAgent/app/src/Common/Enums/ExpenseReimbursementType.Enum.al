// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6912 "Expense Reimbursement Type"
{
    Caption = 'Expense Reimbursement Type';

    value(0; " ") { Caption = ' '; }
    // Company Paid means the company has paid for the expense directly using purchase invoice from the vendor
    value(1; "Company Paid") { Caption = 'Company Paid'; }
    // Employee Paid means the employee has paid for the expense using own funds and is requesting reimbursement
    value(2; "Employee Paid") { Caption = 'Employee Paid'; }
    // Credit Card means the expense was paid using a company credit card and needs to be recorded for reconciliation with credit card statement
    value(3; "Credit Card") { Caption = 'Company Credit Card'; }
}