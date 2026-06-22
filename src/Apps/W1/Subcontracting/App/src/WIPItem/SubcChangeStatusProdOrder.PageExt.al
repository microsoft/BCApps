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
                ApplicationArea = Subcontracting;
                Enabled = WIPQuantityCleanUpEnabled;
                Visible = WIPQuantityCleanUpVisible;
                Caption = 'WIP Quantity Clean Up';
                ToolTip = 'Specifies whether the WIP quantity on the production order should be set to zero. When enabled, the WIP quantity on the production order will be set to zero. This is used when the production order is finished but there is still WIP quantity that needs to be cleaned up.';
            }
        }
    }

    trigger OnOpenPage()
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        WIPQuantityCleanUp := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        SetControlProperties();
    end;

    protected var
        WIPQuantityCleanUp: Boolean;

    var
        ProductionOrder: Record "Production Order";
#if not CLEAN29
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
        WIPQuantityCleanUpEnabled, WIPQuantityCleanUpVisible : Boolean;

    procedure ReturnSubWIPQuantityCleanUp(): Boolean
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit(false);
#endif
        exit(WIPQuantityCleanUp);
    end;

    procedure SubcSetOrder(var ProductionOrderForStatusChange: Record "Production Order")
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit;
#endif
        ProductionOrder := ProductionOrderForStatusChange;
        SetControlProperties();
    end;

    procedure SubcGetOrder() ProductionOrderForStatusChange: Record "Production Order"
    begin
#if not CLEAN29
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            exit(ProductionOrder);
#endif
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