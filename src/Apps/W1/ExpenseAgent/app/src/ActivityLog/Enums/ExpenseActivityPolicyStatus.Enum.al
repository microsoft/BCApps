// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

enum 6925 "Expense Activity Policy Status"
{
    Access = Internal;
    Extensible = false;
    Caption = 'Expense Activity Policy Status', Locked = true;

    value(0; " ")
    {
        Caption = ' ', Locked = true;
    }
    value(1; NonCompliant)
    {
        Caption = 'NonCompliant', Locked = true;
    }
    value(2; RequiresReview)
    {
        Caption = 'RequiresReview', Locked = true;
    }
    value(3; Pending)
    {
        Caption = 'Pending', Locked = true;
    }
    value(4; Compliant)
    {
        Caption = 'Compliant', Locked = true;
    }
    value(5; Exempt)
    {
        Caption = 'Exempt', Locked = true;
    }
}
