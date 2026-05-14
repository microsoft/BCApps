// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
pageextension 99001544 "Subc.Change Status Prod. Order" extends "Change Status on Prod. Order"
{
    layout
    {
        addafter("Finish Order without Output")
        {
            field("WIP Quantity Clean Up"; WIPQuantityCleanUp)
            {
                ApplicationArea = Manufacturing;
                Enabled = WIPQuantityCleanUpEnabled;
                Visible = WIPQuantityCleanUpVisible;
                Caption = 'WIP Quantity Clean Up';
                ToolTip = 'Specifies whether the WIP quantity on the production order should be set to zero. When enabled, the WIP quantity on the production order will be set to zero. This is used when the production order is finished but there is still WIP quantity that needs to be cleaned up.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        WIPQuantityCleanUp := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetControlProperties();
    end;

    protected var
        WIPQuantityCleanUp: Boolean;

    var
        ProductionOrder: Record "Production Order";
        WIPQuantityCleanUpEnabled, WIPQuantityCleanUpVisible : Boolean;

    procedure ReturnSubWIPQuantityCleanUp(): Boolean
    begin
        exit(WIPQuantityCleanUp);
    end;

    procedure SubcSetOrder(var ProductionOrderForStatusChange: Record "Production Order")
    begin
        ProductionOrder := ProductionOrderForStatusChange;
        SetControlProperties();
    end;

    procedure SubcGetOrder() ProductionOrderForStatusChange: Record "Production Order"
    begin
        ProductionOrderForStatusChange := ProductionOrder;
    end;

    local procedure SetControlProperties()
    var
        SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        if ProductionOrder.Status <> "Production Order Status"::Released then begin
            WIPQuantityCleanUpEnabled := false;
            WIPQuantityCleanUpVisible := false;
            WIPQuantityCleanUp := false;
            exit;
        end;
        SubcontractorWIPLedgerEntry.SetCurrentKey("Prod. Order No.", "Prod. Order Status", "Prod. Order Line No.", "Routing Reference No.", "Routing No.", "Operation No.", "Location Code");
        SubcontractorWIPLedgerEntry.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcontractorWIPLedgerEntry.SetRange("Prod. Order Status", "Production Order Status"::Released);
        WIPQuantityCleanUpEnabled := not SubcontractorWIPLedgerEntry.IsEmpty();
        WIPQuantityCleanUpVisible := WIPQuantityCleanUpEnabled;
        if not WIPQuantityCleanUpEnabled then
            WIPQuantityCleanUp := false;
    end;
}