// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

page 7000063 "Customer Ratings"
{
    Caption = 'Customer Ratings';
    DataCaptionExpression = Rec.Caption();
    PageType = List;
    SourceTable = "Customer Rating";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer number for which the risk percentage will be defined by this bank.';
                }
                field("Risk Percentage"; Rec."Risk Percentage")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the risk percentages assigned by the bank to the different customers.';
                }
            }
        }
    }

    actions
    {
    }
}

