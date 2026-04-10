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
            }
            field("Current Sales Cycle Stage"; Rec."Current Sales Cycle Stage")
            {
                ApplicationArea = RelationshipMgmt;
            }
            field("Estimated Value (LCY)"; Rec."Estimated Value (LCY)")
            {
                ApplicationArea = RelationshipMgmt;
                ToolTip = 'Specifies the estimated value of the opportunity.';
            }
            field("Chances of Success %"; Rec."Chances of Success %")
            {
                ApplicationArea = RelationshipMgmt;
            }
            field("Completed %"; Rec."Completed %")
            {
                ApplicationArea = RelationshipMgmt;
            }
            field("Probability %"; Rec."Probability %")
            {
                ApplicationArea = RelationshipMgmt;
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

