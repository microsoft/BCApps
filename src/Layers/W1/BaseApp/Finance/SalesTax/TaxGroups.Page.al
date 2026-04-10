// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SalesTax;

/// <summary>
/// List page for managing tax group classifications and descriptions.
/// Provides interface for creating and maintaining item tax categorizations.
/// </summary>
page 467 "Tax Groups"
{
    ApplicationArea = SalesTax;
    Caption = 'Tax Groups';
    PageType = List;
    SourceTable = "Tax Group";
    UsageCategory = Lists;

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
        area(navigation)
        {
            group("&Group")
            {
                Caption = '&Group';
                Image = Group;
                action(Details)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Details';
                    Image = View;
                    RunObject = Page "Tax Details";
                    RunPageLink = "Tax Group Code" = field(Code);
                    ToolTip = 'View tax-detail entries. A tax-detail entry includes all of the information that is used to calculate the amount of tax to be charged.';
                }
            }
        }
    }
}

