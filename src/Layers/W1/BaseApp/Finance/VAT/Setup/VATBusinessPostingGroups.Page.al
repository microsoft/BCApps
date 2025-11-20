// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

page 470 "VAT Business Posting Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Business Posting Groups';
    PageType = List;
    SourceTable = "VAT Business Posting Group";
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
                    ToolTip = 'Specifies a code for the posting group that determines how to calculate and post VAT for customers and vendors. The number of VAT posting groups that you set up can depend on local legislation and whether you trade both domestically and internationally.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the posting group that determines how to calculate and post VAT for customers and vendors. The number of VAT posting groups that you set up can depend on local legislation and whether you trade both domestically and internationally.';
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
                RunObject = Page "VAT Posting Setup";
                RunPageLink = "VAT Bus. Posting Group" = field(Code);
                ToolTip = 'View or edit combinations of Tax business posting groups and Tax product posting groups. Fill in a line for each combination of VAT business posting group and VAT product posting group.';
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

