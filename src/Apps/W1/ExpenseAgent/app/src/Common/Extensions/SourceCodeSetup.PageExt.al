// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.AuditCodes;

pageextension 6976 "Source Code Setup" extends "Source Code Setup"
{
    layout
    {
        addafter("Unapplied Empl. Entry Appln.")
        {
            field("Expense"; Rec.Expense)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the expense code used for posting and reporting.';
            }
        }
    }
}