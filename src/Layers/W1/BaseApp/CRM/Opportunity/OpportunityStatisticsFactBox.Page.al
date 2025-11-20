// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

page 5174 "Opportunity Statistics FactBox"
{
    Caption = 'Opportunity Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = CardPart;
    SourceTable = Opportunity;

    layout
    {
        area(content)
        {
            field("No. of Interactions"; Rec."No. of Interactions")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies the number of interactions linked to this opportunity.';
            }
            field("Current Sales Cycle Stage"; Rec."Current Sales Cycle Stage")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies the current sales cycle stage of the opportunity.';
            }
            field("Estimated Value (LCY)"; Rec."Estimated Value (LCY)")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies the estimated value of the opportunity.';
            }
            field("Chances of Success %"; Rec."Chances of Success %")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies the chances of success of the opportunity.';
            }
            field("Completed %"; Rec."Completed %")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies the percentage of the sales cycle that has been completed for this opportunity.';
            }
            field("Probability %"; Rec."Probability %")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies the probability of the opportunity resulting in a sale.';
            }
            field("Calcd. Current Value (LCY)"; Rec."Calcd. Current Value (LCY)")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies the current calculated value of the opportunity.';
            }
        }
    }

    actions
    {
    }
}

