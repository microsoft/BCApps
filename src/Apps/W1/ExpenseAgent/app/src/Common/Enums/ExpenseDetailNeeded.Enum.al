// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6905 "Expense Detail Needed"
{
    Access = Internal;
    Caption = 'Expense Detail Needed';

    value(0; " ") { Caption = 'None'; }
    value(1; Itemize) { Caption = 'Itemize'; }
    value(2; Participants) { Caption = 'Participants'; }
    value(3; "Per Diem") { Caption = 'Per Diem'; }
    value(4; Mileage) { Caption = 'Mileage'; }
}