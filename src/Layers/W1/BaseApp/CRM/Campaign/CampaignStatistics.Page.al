// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Campaign;

page 5088 "Campaign Statistics"
{
    Caption = 'Campaign Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Campaign;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Target Contacts Contacted"; Rec."Target Contacts Contacted")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of target contacts that you have contacted with this campaign. The field is not editable.';
                }
                field("Contacts Responded"; Rec."Contacts Responded")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of contacts who have responded to the campaign. This field is not editable.';
                }
                field(ResponseRate; ResponseRate)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Response Rate %';
                    DecimalPlaces = 1 : 1;
                    ToolTip = 'Specifies how many participated in the campaign, represented as a percentage of the number of target contacts contacted.';
                }
                field("Cost (LCY)"; Rec."Cost (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the total cost of all the interactions created as part of the campaign. This field is not editable.';
                }
                field(AvgCostPerResp; AvgCostPerResp)
                {
                    ApplicationArea = RelationshipMgmt;
                    AutoFormatType = 1;
                    Caption = 'Avg. Cost per Response';
                    ToolTip = 'Specifies the cost of the campaign per response.';
                }
                field("Duration (Min.)"; Rec."Duration (Min.)")
                {
                    ApplicationArea = RelationshipMgmt;
                    DecimalPlaces = 0 : 0;
                    ToolTip = 'Specifies the total time it took to complete all the interactions linked to the campaign. This field is not editable.';
                }
                field(AvgDurationPerResp; AvgDurationPerResp)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Avg. Duration per Response';
                    DecimalPlaces = 0 : 0;
                    ToolTip = 'Specifies how long the campaign took per response.';
                }
            }
            group(Opportunities)
            {
                Caption = 'Opportunities';
                field("No. of Opportunities"; Rec."No. of Opportunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of opportunities created as part of this campaign. This field is not editable.';
                }
                field("Estimated Value (LCY)"; Rec."Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the estimated value of the opportunities created as part of this campaign. This field is not editable.';
                }
                field("Calcd. Current Value (LCY)"; Rec."Calcd. Current Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the calculated current value of the opportunities linked to the campaign. This field is not editable.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Target Contacts Contacted" = 0 then
            ResponseRate := 0
        else
            ResponseRate := Round(Rec."Contacts Responded" / Rec."Target Contacts Contacted" * 100, 0.1);

        if Rec."Contacts Responded" = 0 then begin
            AvgCostPerResp := 0;
            AvgDurationPerResp := 0;
        end else begin
            AvgCostPerResp := Round(Rec."Cost (LCY)" / Rec."Contacts Responded");
            AvgDurationPerResp := Round(Rec."Duration (Min.)" / Rec."Contacts Responded", 0.01);
        end;
    end;

    var
        ResponseRate: Decimal;
        AvgCostPerResp: Decimal;
        AvgDurationPerResp: Decimal;
}

