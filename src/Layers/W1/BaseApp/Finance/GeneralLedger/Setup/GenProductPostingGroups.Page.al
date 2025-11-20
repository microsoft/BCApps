// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

page 313 "Gen. Product Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'General Product Posting Groups';
    PageType = List;
    AboutTitle = 'About General Product Posting Groups';
    AboutText = 'Categorize items and resources by product type for sales and purchasing transactions, enabling accurate posting and reporting based on general product posting groups and default VAT settings.';
    SourceTable = "Gen. Product Posting Group";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the product posting group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the product posting group.';
                }
                field("Def. VAT Prod. Posting Group"; Rec."Def. VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a default VAT product group code.';
                }
                field("Auto Insert Default"; Rec."Auto Insert Default")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to automatically insert the default VAT product posting group code in the Def. VAT Prod. Posting Group field when you insert the corresponding general product posting group code from the Code field, for example on new item and resource cards, or in the item charges setup.';
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
                ApplicationArea = Basic, Suite;
                Caption = '&Setup';
                Image = Setup;
                RunObject = Page "General Posting Setup";
                RunPageLink = "Gen. Prod. Posting Group" = field(Code);
                ToolTip = 'View or edit how you want to set up combinations of general business and general product posting groups.';
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

