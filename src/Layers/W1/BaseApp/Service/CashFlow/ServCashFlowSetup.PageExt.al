// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Setup;

pageextension 6473 "Serv. Cash Flow Setup" extends "Cash Flow Setup"
{
    layout
    {
        addafter("Sales Order CF Account No.")
        {
            field("Service CF Account No."; Rec."Service CF Account No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the service account number that is used in cash flow forecasts.';
            }
        }
    }
}
