// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

pageextension 11354 "Apply Employee Entries NL" extends "Apply Employee Entries"
{
    layout
    {
        addafter("Global Dimension 2 Code")
        {
            field("Payments in Process"; Rec."Payments in Process")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total amount of payments/collections in process.';
            }
        }
    }
}