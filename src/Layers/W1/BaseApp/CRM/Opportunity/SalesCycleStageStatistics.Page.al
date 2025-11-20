// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

page 5122 "Sales Cycle Stage Statistics"
{
    Caption = 'Sales Cycle Stage Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Sales Cycle Stage";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                group(Active)
                {
                    Caption = 'Active';
                    field("No. of Opportunities"; Rec."No. of Opportunities")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Specifies the number of opportunities that are currently at this stage in the sales cycle. This field is not editable.';
                    }
                    field("Estimated Value (LCY)"; Rec."Estimated Value (LCY)")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Specifies the estimated value of all the open opportunities that are at this stage of the sales cycle. This field is not editable.';
                    }
                    field("Calcd. Current Value (LCY)"; Rec."Calcd. Current Value (LCY)")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Specifies the calculated current value of all the open opportunities that are at this stage in the sales cycle. This field is not editable.';
                    }
                }
                group(Inactive)
                {
                    Caption = 'Inactive';
                    field("Average No. of Days"; Rec."Average No. of Days")
                    {
                        ApplicationArea = RelationshipMgmt;
                        ToolTip = 'Specifies the average number of days the opportunities have remained at this stage of the sales cycle. This field is not editable.';
                    }
                }
            }
        }
    }

    actions
    {
    }
}

