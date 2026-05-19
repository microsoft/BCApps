// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

pageextension 99001503 "Subc. Prod. Order Rtng." extends "Prod. Order Routing"
{
    layout
    {
        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                UpdateWIPEnabled();
            end;
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                UpdateWIPEnabled();
            end;
        }
        addafter(Description)
        {
            field(Subcontracting; Rec.Subcontracting)
            {
                ApplicationArea = Manufacturing;
            }
            field("Transfer WIP Item"; Rec."Transfer WIP Item")
            {
                ApplicationArea = Manufacturing;
                Enabled = TransferWIPItemEnabled;
            }
            field("Transfer Description"; Rec."Transfer Description")
            {
                ApplicationArea = Manufacturing;
                Enabled = Rec."Transfer WIP Item";
            }
            field("Transfer Description 2"; Rec."Transfer Description 2")
            {
                ApplicationArea = Manufacturing;
                Enabled = Rec."Transfer WIP Item";
                Visible = false;
            }
            field("WIP Qty. (Base) at Subc."; Rec."WIP Qty. (Base) at Subc.")
            {
                ApplicationArea = Manufacturing;
                Visible = false;
            }
            field("WIP Qty. (Base) in Transit"; Rec."WIP Qty. (Base) in Transit")
            {
                ApplicationArea = Manufacturing;
                Visible = false;
            }
        }
        addbefore(Control1900383207)
        {
            part("Subc. Routing Info Factbox"; "Subc. Routing Info Factbox")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Prod. Order No." = field("Prod. Order No."), "Routing No." = field("Routing No."), "Routing Reference No." = field("Routing Reference No."), "Operation No." = field("Operation No.");
            }
        }
    }
    actions
    {
        addafter("Allocated Capacity")
        {
            action("Subcontracting Purchase Lines")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting Purchase Order Lines';
                Image = SubcontractingWorksheet;
                RunObject = page "Purchase Lines";
                RunPageLink = "Document Type" = const(Order), "Prod. Order No." = field("Prod. Order No."), "Routing No." = field("Routing No."), "Routing Reference No." = field("Routing Reference No."), "Operation No." = field("Operation No.");
                ToolTip = 'Show purchase order lines for subcontracting.';
            }
            action("WIP Ledger Entries")
            {
                ApplicationArea = Manufacturing;
                Caption = 'WIP Ledger Entries';
                Image = LedgerEntries;
                RunObject = page "Subc. WIP Ledger Entries";
                RunPageLink = "Prod. Order Status" = field(Status),
                              "Prod. Order No." = field("Prod. Order No."),
                              "Routing Reference No." = field("Routing Reference No."),
                              "Routing No." = field("Routing No."),
                              "Operation No." = field("Operation No.");
                ToolTip = 'View the Subcontractor WIP Ledger Entries for this routing line.';
            }
        }
        addlast("F&unctions")
        {
            action("WIP Adjustment")
            {
                ApplicationArea = Manufacturing;
                Caption = 'WIP Adjustment';
                Image = AdjustEntries;
                ToolTip = 'Manually adjust the WIP quantity for the selected prod. order routing line.';

                trigger OnAction()
                var
                    WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
                    WIPAdjustmentPage: Page "Subc. WIP Adjustment";
                begin
                    WIPLedgerEntry.SetProductionOrderRoutingFilter(Rec, true);
                    WIPAdjustmentPage.SetWIPLedgerEntry(WIPLedgerEntry);
                    WIPAdjustmentPage.SetDocumentNo(Rec."Prod. Order No.");
                    WIPAdjustmentPage.RunModal();
                end;
            }
            action(CreateSubcontracting)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Create Subcontracting Order';
                Image = CreateDocument;
                Enabled = CreateSubcontractingEnabled;
                Visible = CreateSubcontractingVisible;
                ToolTip = 'Create Purchase Orders for Subcontracting directly from the Production Routing Line.';
                trigger OnAction()
                var
                    ProdOrderRoutingLine: Record "Prod. Order Routing Line";
                    PurchaseLine: Record "Purchase Line";
                    SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
                    NoOfCreatedPurchOrder: Integer;
                begin
                    CurrPage.SetSelectionFilter(ProdOrderRoutingLine);
                    SubcPurchaseOrderCreator.ShowExistingPurchaseOrdersForRoutingLines(ProdOrderRoutingLine);
                    ProdOrderRoutingLine.FindSet();
                    repeat
                        NoOfCreatedPurchOrder += SubcPurchaseOrderCreator.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRoutingLine);
                    until ProdOrderRoutingLine.Next() = 0;

                    if NoOfCreatedPurchOrder = 0 then begin
                        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.");
                        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
                        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
                        PurchaseLine.SetRange("Prod. Order No.", Rec."Prod. Order No.");
                        PurchaseLine.SetRange("Routing No.", Rec."Routing No.");
                        PurchaseLine.SetRange("Routing Reference No.", Rec."Routing Reference No.");
                        PurchaseLine.SetRange("Operation No.", Rec."Operation No.");
                        if PurchaseLine.IsEmpty() then
                            Message(NoPurchOrderCreatedMsg, ProdOrderRoutingLine."Prod. Order No.")
                    end else begin
                        if NoOfCreatedPurchOrder = 1 then begin
                            SubcPurchaseOrderCreator.ClearOperationNoForCreatedPurchaseOrder();
                            SubcPurchaseOrderCreator.SetOperationNoForCreatedPurchaseOrder(Rec."Operation No.");
                            SubcPurchaseOrderCreator.ClearRoutingReferenceNoForCreatedPurchaseOrder();
                            SubcPurchaseOrderCreator.SetRoutingReferenceNoForCreatedPurchaseOrder(Rec."Routing Reference No.");
                        end;
                        SubcPurchaseOrderCreator.ShowCreatedPurchaseOrder(Rec."Prod. Order No.", NoOfCreatedPurchOrder);
                    end;
                end;
            }
        }
    }
    var
        TransferWIPItemEnabled: Boolean;
        CreateSubcontractingEnabled: Boolean;
        CreateSubcontractingVisible: Boolean;
        NoPurchOrderCreatedMsg: Label 'No subcontracting order was created for the selected operations in production order %1. Please check whether the operation or operations have already been completed.', Comment = '%1=Production Order No.';

    trigger OnOpenPage()
    var
        StatusFilter: Text;
    begin
        StatusFilter := Rec.GetFilter(Rec.Status);
        if StatusFilter.Contains(Format("Production Order Status"::Released)) then
            CreateSubcontractingVisible := true
        else
            CreateSubcontractingVisible := false;
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateWIPEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateWIPEnabled();
        CreateSubcontractingEnabled := Rec.Subcontracting and (Rec.Status = "Production Order Status"::Released);
    end;

    local procedure UpdateWIPEnabled()
    begin
        Rec.Calcfields(Subcontracting);
        TransferWIPItemEnabled := Rec.Subcontracting;
    end; 
}