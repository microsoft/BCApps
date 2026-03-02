// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;
using Microsoft.Inventory.Item;
using System.Agents;

/// <summary>
/// Extends the Shopify Order Tax Lines page with agent-only fields and actions.
/// Adds a computed Tax Group Code field and a Tax Jurisdictions navigation action,
/// both visible only during agent sessions.
/// </summary>
pageextension 30474 "Shpfy Tax Order Tax Lines" extends "Shpfy Order Tax Lines"
{
    layout
    {
        addafter("Tax Jurisdiction Code")
        {
            field(TaxGroupCode; TaxGroupCodeValue)
            {
                ApplicationArea = All;
                Caption = 'Tax Group Code';
                Editable = false;
                ToolTip = 'Specifies the Tax Group Code from the mapped BC item for this order line. Used to verify Tax Details under the matched Tax Jurisdiction.';
                // Visible = IsAgentSession;
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(TaxJurisdictions)
            {
                ApplicationArea = All;
                Caption = 'Tax Jurisdictions';
                Image = TaxSetup;
                ToolTip = 'Open the Tax Jurisdictions list to find or create matching jurisdictions.';
                // Visible = IsAgentSession;

                trigger OnAction()
                begin
                    Page.Run(Page::"Tax Jurisdictions");
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentSession: Codeunit "Agent Session";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        IsAgentSession := AgentSession.IsAgentSession(AgentMetadataProvider);
    end;

    trigger OnAfterGetRecord()
    begin
        ComputeTaxGroupCode();
    end;

    local procedure ComputeTaxGroupCode()
    var
        OrderLine: Record "Shpfy Order Line";
        Item: Record Item;
    begin
        TaxGroupCodeValue := '';
        OrderLine.SetRange("Line Id", Rec."Parent Id");
        if OrderLine.FindFirst() then
            if Item.Get(OrderLine."Item No.") then
                TaxGroupCodeValue := Item."Tax Group Code";
    end;

    var
        TaxGroupCodeValue: Code[20];
        IsAgentSession: Boolean;
}
