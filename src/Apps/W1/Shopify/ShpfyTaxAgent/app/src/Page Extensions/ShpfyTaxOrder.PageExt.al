// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Agents;

/// <summary>
/// Adds the "On Hold" field to the Shopify Order card and controls
/// visibility of the Create Sales Document action for agent sessions.
/// </summary>
pageextension 30471 "Shpfy Tax Order" extends "Shpfy Order"
{
    layout
    {
        addlast(General)
        {
            field("On Hold"; Rec."On Hold")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies if the order is on hold pending tax matching by the Shopify Tax Agent. While on hold, the order cannot be processed into a sales document.';
            }
        }
        addafter(ShipToCity)
        {
            field(ShipToCounty; Rec."Ship-to County")
            {
                ApplicationArea = All;
                Caption = 'County';
                Editable = false;
                ToolTip = 'Specifies the county or state of the ship-to address.';
            }
        }
    }

    actions
    {
        modify(CreateSalesDocument)
        {
            Visible = ShowCreateSalesDoc;
        }
    }

    trigger OnOpenPage()
    begin
        UpdateActionVisibility();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateActionVisibility();
    end;

    local procedure UpdateActionVisibility()
    var
        Shop: Record "Shpfy Shop";
        AgentSession: Codeunit "Agent Session";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        if not AgentSession.IsAgentSession(AgentMetadataProvider) then begin
            ShowCreateSalesDoc := true;
            exit;
        end;

        ShowCreateSalesDoc := false;
        if Shop.Get(Rec."Shop Code") then
            ShowCreateSalesDoc := Shop."Auto Create Orders";
    end;

    var
        ShowCreateSalesDoc: Boolean;
}
