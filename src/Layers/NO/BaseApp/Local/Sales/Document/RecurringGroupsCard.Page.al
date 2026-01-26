// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

page 15000300 "Recurring Groups Card"
{
    Caption = 'Recurring Groups Card';
    PageType = Card;
    SourceTable = "Recurring Group";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code to identify the recurring group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description to identify the recurring group.';
                }
                field("Date formula"; Rec."Date formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date formula to calculate the time interval between orders.';
                }
                field("Create only the latest"; Rec."Create only the latest")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to only create the latest recurring order, if the recurring group interval has been exceeded.';
                }
                field("Starting date"; Rec."Starting date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first date of the recurring group.';
                }
                field("Closing date"; Rec."Closing date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date of the recurring group.';
                }
            }
            group(Update)
            {
                Caption = 'Update';
                field("Update Document Date"; Rec."Update Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the document date will be updated.';
                }
                field("Document Date Formula"; Rec."Document Date Formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date formula to calculate the document date on the order.';
                }
                field("Delivery Date Formula"; Rec."Delivery Date Formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date formula to calculate the delivery date on the order.';
                }
                field("Update Price"; Rec."Update Price")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how prices will be updated on new orders.';
                }
                field("Update Number"; Rec."Update Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to manage the quantity specified on the original order.';
                }
            }
        }
    }

    actions
    {
    }
}

