// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

/// <summary>
/// VAT business posting groups list page for managing customer and vendor VAT categorization.
/// Provides interface to create, edit, and maintain VAT business posting groups used in VAT posting setup combinations.
/// </summary>
/// <remarks>
/// Data source: VAT Business Posting Group table containing codes and descriptions for customer/vendor VAT categories.
/// Usage context: Administrative setup for categorizing customers and vendors by VAT characteristics.
/// Integration: Used in combination with VAT product posting groups to create VAT posting setups.
/// </remarks>
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
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

