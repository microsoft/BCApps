// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;

pageextension 99001503 "Sub. Prod. Order Rtng." extends "Prod. Order Routing"
{
    layout
    {
        addafter(Description)
        {
            field(Subcontracting; Rec.Subcontracting)
            {
                ApplicationArea = Manufacturing;
            }
        }
        addbefore(Control1900383207)
        {
            part("Subc. Routing Info Factbox"; "Sub. Routing Info Factbox")
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
                ToolTip = 'Shows Purchase Order Lines for Subcontracting.';
            }
        }
        addlast("F&unctions")
        {
            action(CreateSubcontracting)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Create Subcontracting Order';
                Image = CreateDocument;
                ToolTip = 'Create Purchase Orders for Subcontracting directly from the Production Routing Line.';
                trigger OnAction()
                var
                    ProdOrderRtngLine: Record "Prod. Order Routing Line";
                    PurchaseLine: Record "Purchase Line";
                    SubcontractingMgmt: Codeunit "Subcontracting Management";
                    NoOfCreatedPurchOrder: Integer;
                    NoPurchOrderCreatedMsg: Label 'No subcontracting order was created for the selected operations in production order %1. Please check whether the operation or operations have already been completed.', Comment = '%1=Production Order No.';
                begin
                    CurrPage.SetSelectionFilter(ProdOrderRtngLine);
                    ProdOrderRtngLine.FindSet();
                    repeat
                        NoOfCreatedPurchOrder += SubcontractingMgmt.CreateSubcontractingPurchaseOrderFromRoutingLine(ProdOrderRtngLine);
                    until ProdOrderRtngLine.Next() = 0;

                    if NoOfCreatedPurchOrder = 0 then begin
                        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.");
                        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
                        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
                        PurchaseLine.SetRange("Prod. Order No.", Rec."Prod. Order No.");
                        PurchaseLine.SetRange("Routing No.", Rec."Routing No.");
                        PurchaseLine.SetRange("Operation No.", Rec."Operation No.");
                        if PurchaseLine.IsEmpty() then
                            Message(NoPurchOrderCreatedMsg, ProdOrderRtngLine."Prod. Order No.")
                    end else begin
                        if NoOfCreatedPurchOrder = 1 then begin
                            SubcontractingMgmt.ClearOperationNoForCreatedPurchaseOrder();
                            SubcontractingMgmt.SetOperationNoForCreatedPurchaseOrder(Rec."Operation No.");
                        end;
                        SubcontractingMgmt.ShowCreatedPurchaseOrder(Rec."Prod. Order No.", NoOfCreatedPurchOrder);
                    end;
                end;
            }
        }
    }
}