// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Reporting;

enumextension 6915 "Report Selection Usage Ext" extends "Report Selection Usage"
{
    value(6900; "Expense Report")
    {
        Caption = 'Expense Report';
    }
    value(6901; "Cover Page")
    {
        Caption = 'Cover Page';
    }
    value(6902; "Distribution")
    {
        Caption = 'Distribution';
    }
    value(6903; "Legal Page")
    {
        Caption = 'Legal Page';
    }
}