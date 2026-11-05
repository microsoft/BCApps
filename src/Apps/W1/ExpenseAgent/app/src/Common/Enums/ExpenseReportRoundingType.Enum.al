#if not CLEANSCHEMA29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

#pragma warning disable AS0105
enum 6987 "Expense Report Rounding Type"
{
    Access = Internal;
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';
    ObsoleteReason = 'This is no longer required and will be removed in a future release.';
    Caption = 'Expense Report Rounding Type';

    value(0; Nearest)
    {
        Caption = 'Nearest';
    }
    value(1; Up)
    {
        Caption = 'Up';
    }
    value(2; Down)
    {
        Caption = 'Down';
    }
}
#pragma warning restore AS0105
#endif