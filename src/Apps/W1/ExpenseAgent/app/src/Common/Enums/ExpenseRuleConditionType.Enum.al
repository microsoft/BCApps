// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6911 "Expense Rule Condition Type"
{
    Access = Internal;
    Caption = 'Condition Type';

    value(0; " ") { Caption = 'None'; }
    value(1; "Fix Amount") { Caption = 'Fix Amount'; }
    value(2; "Max Amount") { Caption = 'Max Amount'; }
    value(3; "Min Amount") { Caption = 'Min Amount'; }
    value(4; "At Least Justification Needed") { Caption = 'At Least Justification Needed'; }
    value(5; "Daily Rate") { Caption = 'Daily Rate'; }
}