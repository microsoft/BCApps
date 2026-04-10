// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 7111 "Analysis Type List"
{
    Caption = 'Analysis Type List';
    Editable = false;
    PageType = List;
    SourceTable = "Analysis Type";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Value Type"; Rec."Value Type")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Setup")
            {
                ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                Caption = '&Setup';
                Image = Setup;
                RunObject = Page "Analysis Types";
                ToolTip = 'Set up the analysis type.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Setup_Promoted"; "&Setup")
                {
                }
            }
        }
    }
}

