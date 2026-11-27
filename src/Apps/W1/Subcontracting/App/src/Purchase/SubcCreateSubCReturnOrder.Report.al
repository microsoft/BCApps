// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 20502 "Subc. Create SubCReturnOrder"
{
    ApplicationArea = Subcontracting;
    Caption = 'Create Subcontracting Return Order';
    ProcessingOnly = true;
    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") order(ascending);
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") order(ascending) where("Prod. Order No." = filter(<> ''));
                trigger OnAfterGetRecord()
                var
                    QtyToPost: Decimal;
                    SubcontractingManagement: Codeunit "Subcontracting Management";
                begin
                    if not TempSelectedPurchaseLine.Get("Document Type", "Document No.", "Line No.") then begin
                        CurrReport.Skip();
                        exit;
                    end;
                    SubcontractingManagement.CheckWIPSelection("Purchase Line", TempSelectedPurchaseLine, TempProductionLine, TempRouting, SourceVersions);
                    HandleComponentReturnForPurchLine("Purchase Line", true, QtyToPost);
                    HandleWIPReturnForPurchLine("Purchase Line", true);
                end;
            }
            trigger OnAfterGetRecord()
            begin
                "Purchase Header".CalcFields("Subc. Order");
                if not "Subc. Order" then
                    Error(OrderNoIsNotSubcontractorErr, PurchOrderNo);

                if not CanCreateHeaders.Get("No.") then
                    Error(NothingToCreateErr);

                Vendor.Get("Purchase Header"."Buy-from Vendor No.");
            end;

            trigger OnPostDataItem()
            begin
                ShowDocument();
            end;

            trigger OnPreDataItem()
            begin
                PurchOrderNo := CopyStr("Purchase Header".GetFilter("No."), 1, MaxStrLen(PurchOrderNo));
                if PurchOrderNo = '' then
                    Error(WarningToSpecifyPurchOrderErr);
                CheckTransferToCreate();
            end;
        }
    }

#if not CLEAN28
    trigger OnInitReport()
    var
#pragma warning disable AL0432
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
    begin
#pragma warning disable AL0432
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
            CurrReport.Quit();
    end;

#endif
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        TempSelectedPurchaseLine: Record "Purchase Line" temporary;
        TempProductionLine: Record "Prod. Order Line" temporary;
        TempRouting: Record "Prod. Order Routing Line" temporary;
        TempWIPPlan: Record "Transfer Line" temporary;
        SourceVersions: Dictionary of [Text, BigInteger];
        SelectionViews: List of [Text];
        CanCreateHeaders: Dictionary of [Code[20], Boolean];
        WIPPlanLineNo: Integer;
        PurchOrderNo: Code[20];
        LineNo: Integer;
        NothingToCreateErr: Label 'Nothing to create. No components or WIP items to return for the specified subcontracting order.';
        OrderNoDoesNotExistInProdOrderErr: Label 'Operation %1 in the subcontracting order %2 does not exist in the routing %3 of the production order %4.', Comment = '%1=Operation No., %2=Purchase Order No., %3=Routing No., %4=Production Order No.';
        OrderNoIsNotSubcontractorErr: Label 'Order %1 is not a Subcontractor work.', Comment = '%1=Purchase Order No.';
        SubcLocationCodeMissingErr: Label 'The Subc. Location Code must be specified on Vendor %1 or the Subcontracting Purchase Order to create return orders.', Comment = '%1=Vendor No.';
        WarningToSpecifyPurchOrderErr: Label 'Warning. Specify a Purchase Order No. for the Subcontractor work.';
        WIPSourceEvidenceErr: Label 'Cannot verify WIP availability for operation %1 of production order %2 at location %3, document %4. Retain the source documents and reconcile the WIP evidence before creating another transfer.', Comment = '%1 = source operation, %2 = production order, %3 = source location, %4 = evidence document';

    local procedure InsertTransferHeader(TransferFromLocationCode: Code[10]; TransferToLocationCode: Code[10])
    var
        TransferRoute: Record "Transfer Route";
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
    begin
        TransferHeader.Reset();
        TransferHeader.SetRange("Subc. Source Type", TransferHeader."Subc. Source Type"::Subcontracting);
        TransferHeader.SetRange("Source ID", "Purchase Header"."Buy-from Vendor No.");
        TransferHeader.SetRange(Status, TransferHeader.Status::Open);
        TransferHeader.SetRange("Completely Shipped", false);
        TransferHeader.SetRange("Transfer-from Code", TransferFromLocationCode);
        TransferHeader.SetRange("Transfer-to Code", TransferToLocationCode);
        TransferHeader.SetRange("Subc. Return Order", true);
        if not TransferHeader.FindFirst() then begin
            TransferHeader.Init();
            TransferHeader."No." := '';
            TransferHeader.Insert(true);

            TransferHeader.Validate("Transfer-from Code", TransferFromLocationCode);
            TransferHeader.Validate("Transfer-to Code", TransferToLocationCode);

            if not TransferRoute.Get(TransferFromLocationCode, TransferToLocationCode) or (TransferRoute."In-Transit Code" = '') then begin
                SubcTransferManagement.CheckDirectTransferIsAllowedForTransferHeader(TransferHeader);
                TransferHeader.Validate("Direct Transfer", true);
            end;

            TransferHeader."Subc. Source Type" := TransferHeader."Subc. Source Type"::Subcontracting;
            TransferHeader."Source ID" := "Purchase Header"."Buy-from Vendor No.";
            TransferHeader."Subcontr. Purch. Order No." := "Purchase Header"."No.";
            TransferHeader."Subcontr. PO Line No." := "Purchase Line"."Line No.";
            TransferHeader."Subc. Return Order" := true;
            TransferHeader."Transfer-from Name" := Vendor.Name;
            TransferHeader."Transfer-from Name 2" := Vendor."Name 2";
            TransferHeader."Transfer-from Address" := Vendor.Address;
            TransferHeader."Transfer-from Address 2" := Vendor."Address 2";
            TransferHeader."Transfer-from Post Code" := Vendor."Post Code";
            TransferHeader."Transfer-from City" := Vendor.City;
            TransferHeader."Transfer-from County" := Vendor.County;
            TransferHeader."Trsf.-from Country/Region Code" := Vendor."Country/Region Code";

            TransferHeader.Modify();
            OnAfterInsertTransferHeader(TransferHeader, Vendor);
            LineNo := 0;
        end else begin
            TransferLine.SetRange("Document No.", TransferHeader."No.");
            if TransferLine.FindLast() then
                LineNo := TransferLine."Line No."
            else
                LineNo := 0;
        end;
    end;

    local procedure CheckTransferToCreate(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        SelectedHeader: Record "Purchase Header";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        QtyToPost: Decimal;
        CanCreate: Boolean;
    begin
        TempSelectedPurchaseLine.Reset();
        TempSelectedPurchaseLine.DeleteAll();
        TempWIPPlan.Reset();
        TempWIPPlan.DeleteAll();
        WIPPlanLineNo := 0;
        Clear(CanCreateHeaders);
        Clear(SourceVersions);
        Clear(SelectionViews);
        SelectedHeader.CopyFilters("Purchase Header");
        SelectedHeader.ReadIsolation := IsolationLevel::ReadCommitted;
        if SelectedHeader.FindSet() then
            repeat
                SelectedHeader.CalcFields("Subc. Order");
                if not SelectedHeader."Subc. Order" then
                    Error(OrderNoIsNotSubcontractorErr, SelectedHeader."No.");
                CanCreateHeaders.Add(SelectedHeader."No.", false);
                SourceVersions.Add(Format(SelectedHeader.RecordId), SelectedHeader.SystemRowVersion);
                PurchaseLine.Reset();
                PurchaseLine.CopyFilters("Purchase Line");
                PurchaseLine.ReadIsolation := IsolationLevel::ReadCommitted;
                PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
                PurchaseLine.SetRange("Document Type", SelectedHeader."Document Type");
                PurchaseLine.SetRange("Document No.", SelectedHeader."No.");
                PurchaseLine.SetFilter("Prod. Order No.", '<>''''');
                PurchaseLine.SetFilter("Prod. Order Line No.", '<>0');
                PurchaseLine.SetFilter("Operation No.", '<>0');
                SelectionViews.Add(PurchaseLine.GetView(false));
                if PurchaseLine.FindSet() then
                    repeat
                        SubcontractingManagement.RememberWIPSelection(PurchaseLine, TempSelectedPurchaseLine, SourceVersions);
                    until PurchaseLine.Next() = 0;
            until SelectedHeader.Next() = 0;
        SubcontractingManagement.ProtectWIPSelection(TempSelectedPurchaseLine, TempProductionLine, TempRouting, SourceVersions);
        SubcontractingManagement.CheckWIPSelectedKeys(TempSelectedPurchaseLine, SelectionViews, SourceVersions);
        // WIP for the entire selection must be safe before even the component availability check can exit early.
        if TempSelectedPurchaseLine.FindSet() then
            repeat
                if PlanWIPReturn(TempSelectedPurchaseLine) then begin
                    CanCreate := true;
                    CanCreateHeaders.Set(TempSelectedPurchaseLine."Document No.", true);
                end;
            until TempSelectedPurchaseLine.Next() = 0;
        if TempSelectedPurchaseLine.FindSet() then
            repeat
                if HandleComponentReturnForPurchLine(TempSelectedPurchaseLine, false, QtyToPost) then begin
                    CanCreate := true;
                    CanCreateHeaders.Set(TempSelectedPurchaseLine."Document No.", true);
                end;
            until TempSelectedPurchaseLine.Next() = 0;
        exit(CanCreate);
    end;

    local procedure HandleComponentReturnForPurchLine(PurchaseLine: Record "Purchase Line"; InsertLine: Boolean; var QtyToPost: Decimal): Boolean
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseVendor: Record Vendor;
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
        SubcFromLocationCode: Code[10];
        AvailableToReturn: Decimal;
        QtyPerUom: Decimal;
    begin
        if not ProdOrderLine.Get(ProdOrderLine.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get(ProdOrderRoutingLine.Status::Released, PurchaseLine."Prod. Order No.",
             PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.")
        then
            Error(OrderNoDoesNotExistInProdOrderErr, PurchaseLine."Operation No.", PurchOrderNo, PurchaseLine."Routing No.", PurchaseLine."Prod. Order No.");

        if TransferLineAlreadyExists(PurchaseLine) then
            exit(false);

        Item.SetLoadFields("Base Unit of Measure", "Rounding Precision");
        Item.Get(PurchaseLine."No.");
        QtyPerUom := UnitofMeasureManagement.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Subc. Purchase Order Filter", PurchaseLine."Document No.");
        ProdOrderComponent.SetRange("Component Supply Method", ProdOrderComponent."Component Supply Method"::"Transfer to Vendor");
        if ProdOrderComponent.FindSet() then begin
            PurchaseHeader.ReadIsolation := IsolationLevel::UpdLock;
            PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
            if PurchaseHeader.SystemRowVersion <> SourceVersions.Get(Format(PurchaseHeader.RecordId)) then
                Error(WIPSourceEvidenceErr, ProdOrderRoutingLine."Operation No.", ProdOrderLine."Prod. Order No.", '', PurchaseHeader."No.");
            SubcFromLocationCode := PurchaseHeader."Subc. Location Code";
            if SubcFromLocationCode = '' then begin
                PurchaseVendor.Get(PurchaseHeader."Buy-from Vendor No.");
                SubcFromLocationCode := PurchaseVendor."Subc. Location Code";
                if SubcFromLocationCode = '' then
                    Error(SubcLocationCodeMissingErr, PurchaseVendor."No.");
            end;
            repeat
                Item.Get(ProdOrderComponent."Item No.");
                QtyToPost := MfgCostCalculationMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComponent,
                    Round(PurchaseLine."Outstanding Quantity" * QtyPerUom, UnitofMeasureManagement.QtyRndPrecision()));
                ProdOrderComponent.CalcFields(
                    "Subc. Qty. in Transit (Base)", "Subc. Qty. transf. to Subcontr",
                    "RetQtyOnTransOrder (Base)", "RetQtyInTransit (Base)");

                AvailableToReturn :=
                    Abs(ProdOrderComponent."Subc. Qty. in Transit (Base)") + Abs(ProdOrderComponent."Subc. Qty. transf. to Subcontr")
                    - SubcTransferManagement.CalcConsumedQtyAtSubcLocation(ProdOrderComponent)
                    - Abs(ProdOrderComponent."RetQtyOnTransOrder (Base)") - Abs(ProdOrderComponent."RetQtyInTransit (Base)");
                if QtyToPost > AvailableToReturn then
                    QtyToPost := AvailableToReturn;
                if QtyToPost > 0 then
                    if InsertLine then begin
                        if ProdOrderComponent."Subc. Original Location Code" = '' then
                            ProdOrderComponent."Subc. Original Location Code" := ProdOrderComponent."Location Code";

                        InsertTransferHeader(SubcFromLocationCode, ProdOrderComponent."Subc. Original Location Code");

                        LineNo := LineNo + 10000;

                        TransferLine.Init();
                        TransferLine."Document No." := TransferHeader."No.";
                        TransferLine."Line No." := LineNo;
                        TransferLine.Validate("Item No.", ProdOrderComponent."Item No.");
                        TransferLine.Validate("Variant Code", ProdOrderComponent."Variant Code");
                        TransferLine."Unit of Measure Code" := ProdOrderComponent."Unit of Measure Code";
                        TransferLine."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";
                        TransferLine.Validate(Quantity, Round(QtyToPost / ProdOrderComponent."Qty. per Unit of Measure", Item."Rounding Precision", '>'));
                        TransferLine."Subc. Purch. Order No." := PurchaseLine."Document No.";
                        TransferLine."Subc. Purch. Order Line No." := PurchaseLine."Line No.";
                        TransferLine."Subc. Prod. Order No." := PurchaseLine."Prod. Order No.";
                        TransferLine."Subc. Prod. Order Line No." := PurchaseLine."Prod. Order Line No.";
                        TransferLine."Subc. Prod. Ord. Comp Line No." := ProdOrderComponent."Line No.";
                        TransferLine."Subc. Return Order" := true;

                        TransferLine."Subc. Routing No." := ProdOrderRoutingLine."Routing No.";
                        TransferLine."Subc. Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
                        TransferLine."Subc. Work Center No." := ProdOrderRoutingLine."Work Center No.";
                        TransferLine."Subc. Operation No." := ProdOrderRoutingLine."Operation No.";

                        TransferLine."Subc. Return Order" := true;

                        TransferLine.Insert();

                        SubcTransferManagement.TransferReservationEntryFromProdOrderCompToTransferOrder(TransferLine, ProdOrderComponent);

                        if ProdOrderComponent."Subc. Orig. Bin Code" = '' then
                            ProdOrderComponent."Subc. Orig. Bin Code" := ProdOrderComponent."Bin Code";
                        if TransferHeader."Transfer-to Code" <> ProdOrderComponent."Location Code" then
                            SubcontractingManagement.ValidateProdOrderCompLocationPreservingFlushingMethod(ProdOrderComponent, TransferHeader."Transfer-to Code");
                        ProdOrderComponent.Modify();

                        SubcTransferManagement.CreateReservEntryForTransferReceiptToProdOrderComp(TransferLine, ProdOrderComponent);
                    end else
                        exit(true);
            until ProdOrderComponent.Next() = 0;
        end;
        exit(false);
    end;

    local procedure ShowDocument()
    var
        SubcPurchFactboxMgmt: Codeunit "Subc. Purch. Factbox Mgmt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDocument(TransferHeader, IsHandled);
        if IsHandled then
            exit;

        Commit(); // Used for following call of Transfer Pages

        SubcPurchFactboxMgmt.ShowTransferOrdersFromPurchaseOrder("Purchase Header", true);
    end;

    local procedure TransferLineAlreadyExists(PurchaseLine: Record "Purchase Line"): Boolean
    var
        TransferLine2: Record "Transfer Line";
    begin
        TransferLine2.ReadIsolation := IsolationLevel::UpdLock;
        if PurchaseLine."Document No." = '' then
            exit(false);
        TransferLine2.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        TransferLine2.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        TransferLine2.SetRange("Subc. Prod. Order No.", PurchaseLine."Prod. Order No.");
        TransferLine2.SetRange("Subc. Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        TransferLine2.SetRange("Derived From Line No.", 0);
        TransferLine2.SetRange("Subc. Return Order", true);
        exit(not TransferLine2.IsEmpty());
    end;

    local procedure GetTransferFromLocationCode(var SubcLocationCode: Code[10])
    begin
        SubcLocationCode := "Purchase Header"."Subc. Location Code";
        if SubcLocationCode = '' then begin
            SubcLocationCode := Vendor."Subc. Location Code";
            if SubcLocationCode = '' then
                Error(SubcLocationCodeMissingErr, Vendor."No.");
        end;
    end;

    local procedure HandleWIPReturnForPurchLine(PurchaseLine: Record "Purchase Line"; InsertLine: Boolean): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if not ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);
        if not ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.",
                PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.")
        then
            exit(false);
        TempWIPPlan.Reset();
        TempWIPPlan.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        TempWIPPlan.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        if not InsertLine then
            exit(not TempWIPPlan.IsEmpty());
        if TempWIPPlan.FindSet() then
            repeat
                SubcontractingManagement.CheckWIPSelection(PurchaseLine, TempSelectedPurchaseLine, TempProductionLine, TempRouting, SourceVersions);
                TempWIPPlan.TestField("Transfer-to Code", ProdOrderLine."Location Code");
                TempWIPPlan.TestField("Item No.", ProdOrderLine."Item No.");
                TempWIPPlan.TestField("Variant Code", ProdOrderLine."Variant Code");
                TempWIPPlan.TestField("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
                if SubcontractingManagement.WIPQuantityBase(ProdOrderLine, TempWIPPlan."Unit of Measure Code", TempWIPPlan.Quantity) <> TempWIPPlan."Quantity (Base)" then
                    Error(WIPSourceEvidenceErr, ProdOrderRoutingLine."Operation No.", ProdOrderLine."Prod. Order No.", TempWIPPlan."Transfer-from Code", '');
                InsertTransferHeader(TempWIPPlan."Transfer-from Code", TempWIPPlan."Transfer-to Code");
                InsertWIPReturnTransferLine(PurchaseLine, ProdOrderLine, ProdOrderRoutingLine, TempWIPPlan.Quantity, TempWIPPlan."Quantity (Base)");
            until TempWIPPlan.Next() = 0;
        exit(false);
    end;

    local procedure PlanWIPReturn(PurchaseLine: Record "Purchase Line"): Boolean
    var
        ProductionLine: Record "Prod. Order Line";
        Routing: Record "Prod. Order Routing Line";
        Header: Record "Purchase Header";
        PurchaseVendor: Record Vendor;
        Entry, LocationEntry: Record "Subcontractor WIP Ledger Entry";
        PlannedLine: Record "Transfer Line" temporary;
        SubcontractingManagement: Codeunit "Subcontracting Management";
        Locations: List of [Code[10]];
        LocationCode: Code[10];
        Available, ActualBase, DocumentQuantity: Decimal;
        Planned: Boolean;
    begin
        if not ProductionLine.Get(ProductionLine.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);
        if not Routing.Get(Routing.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.") then
            exit(false);
        if not Routing."Transfer WIP Item" or WIPReturnTransferLineAlreadyExists(PurchaseLine) then
            exit(false);
        Header.ReadIsolation := IsolationLevel::UpdLock;
        Header.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        if Header.SystemRowVersion <> SourceVersions.Get(Format(Header.RecordId)) then
            Error(WIPSourceEvidenceErr, Routing."Operation No.", ProductionLine."Prod. Order No.", '', Header."No.");
        PurchaseVendor.ReadIsolation := IsolationLevel::UpdLock;
        PurchaseVendor.Get(Header."Buy-from Vendor No.");
        SubcontractingManagement.FilterWIPSourceIdentity(Entry, ProductionLine, Routing);
        Entry.SetRange("In Transit", false);
        if Entry.FindSet() then
            repeat
                LocationCode := Entry."Location Code";
                if not Locations.Contains(LocationCode) then begin
                    Locations.Add(LocationCode);
                    LocationEntry.CopyFilters(Entry);
                    LocationEntry.ReadIsolation := IsolationLevel::UpdLock;
                    LocationEntry.SetRange("Location Code", LocationCode);
                    LocationEntry.CalcSums("Quantity (Base)");
                    Available := LocationEntry."Quantity (Base)";
                    if Available > 0 then begin
                        Available -= SubcontractingManagement.CheckWIPSourceEvidence(ProductionLine, Routing, Routing."Operation No.", LocationCode);
                        // Return spends current-operation stock and includes every forward writer, including the same order.
                        Available -= SubcontractingManagement.GetWIPSourceCommitment(ProductionLine, Routing, Routing."Operation No.", LocationCode, PurchaseLine, false);
                        PlannedLine.Copy(TempWIPPlan, true);
                        PlannedLine.Reset();
                        PlannedLine.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
                        PlannedLine.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
                        PlannedLine.SetRange("Subc. Routing No.", Routing."Routing No.");
                        PlannedLine.SetRange("Subc. Routing Reference No.", Routing."Routing Reference No.");
                        PlannedLine.SetRange("Subc. Operation No.", Routing."Operation No.");
                        PlannedLine.SetRange("Item No.", ProductionLine."Item No.");
                        PlannedLine.SetRange("Variant Code", ProductionLine."Variant Code");
                        PlannedLine.SetRange("Transfer-from Code", LocationCode);
                        PlannedLine.CalcSums("Quantity (Base)");
                        Available -= PlannedLine."Quantity (Base)";
                        if Available > 0 then begin
                            DocumentQuantity := SubcontractingManagement.RoundWIPPlanQuantity(ProductionLine, ProductionLine."Unit of Measure Code", Available, Available, Routing."Operation No.", LocationCode, ActualBase);
                            if DocumentQuantity > 0 then begin
                                WIPPlanLineNo += 1;
                                TempWIPPlan.Reset();
                                TempWIPPlan.Init();
                                TempWIPPlan."Line No." := WIPPlanLineNo;
                                TempWIPPlan."Subc. Purch. Order No." := PurchaseLine."Document No.";
                                TempWIPPlan."Subc. Purch. Order Line No." := PurchaseLine."Line No.";
                                TempWIPPlan."Subc. Prod. Order No." := ProductionLine."Prod. Order No.";
                                TempWIPPlan."Subc. Prod. Order Line No." := ProductionLine."Line No.";
                                TempWIPPlan."Subc. Routing No." := Routing."Routing No.";
                                TempWIPPlan."Subc. Routing Reference No." := Routing."Routing Reference No.";
                                TempWIPPlan."Subc. Operation No." := Routing."Operation No.";
                                TempWIPPlan."Subc. Work Center No." := Routing."Work Center No.";
                                TempWIPPlan."Item No." := ProductionLine."Item No.";
                                TempWIPPlan."Variant Code" := ProductionLine."Variant Code";
                                TempWIPPlan."Unit of Measure Code" := ProductionLine."Unit of Measure Code";
                                TempWIPPlan."Transfer-from Code" := LocationCode;
                                TempWIPPlan."Transfer-to Code" := ProductionLine."Location Code";
                                TempWIPPlan."Subc. Return Order" := true;
                                TempWIPPlan.Quantity := DocumentQuantity;
                                TempWIPPlan."Quantity (Base)" := ActualBase;
                                TempWIPPlan.Insert();
                                Planned := true;
                            end;
                        end;
                    end;
                end;
            until Entry.Next() = 0;
        exit(Planned);
    end;

    local procedure InsertWIPReturnTransferLine(PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WIPQty: Decimal; PlannedBase: Decimal)
    begin
        TransferHeader.TestField("Transfer-from Code", TempWIPPlan."Transfer-from Code");
        TransferHeader.TestField("Transfer-to Code", TempWIPPlan."Transfer-to Code");
        LineNo := LineNo + 10000;

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := LineNo;
        TransferLine.Validate("Item No.", ProdOrderLine."Item No.");
        if ProdOrderLine."Variant Code" <> '' then
            TransferLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        TransferLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        TransferLine.Validate("Transfer WIP Item", true);
        TransferLine.Validate(Quantity, WIPQty);
        TransferLine.TestField(Quantity, WIPQty);
        if TransferLine.CalcBaseQty(TransferLine.Quantity) <> PlannedBase then
            Error(WIPSourceEvidenceErr, ProdOrderRoutingLine."Operation No.", ProdOrderLine."Prod. Order No.", TransferHeader."Transfer-from Code", '');

        if ProdOrderRoutingLine."Transfer Description" <> '' then
            TransferLine.Description := ProdOrderRoutingLine."Transfer Description";

        if ProdOrderRoutingLine."Transfer Description 2" <> '' then
            TransferLine."Description 2" := ProdOrderRoutingLine."Transfer Description 2";

        TransferLine."Subc. Purch. Order No." := PurchaseLine."Document No.";
        TransferLine."Subc. Purch. Order Line No." := PurchaseLine."Line No.";
        TransferLine."Subc. Prod. Order No." := ProdOrderLine."Prod. Order No.";
        TransferLine."Subc. Prod. Order Line No." := ProdOrderLine."Line No.";
        TransferLine."Subc. Routing No." := ProdOrderRoutingLine."Routing No.";
        TransferLine."Subc. Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        TransferLine."Subc. Work Center No." := ProdOrderRoutingLine."Work Center No.";
        TransferLine."Subc. Operation No." := ProdOrderRoutingLine."Operation No.";
        TransferLine."Subc. Return Order" := true;

        TransferLine.Insert();
    end;

    local procedure WIPReturnTransferLineAlreadyExists(PurchaseLine: Record "Purchase Line"): Boolean
    var
        TransferLineToCheck: Record "Transfer Line";
    begin
        TransferLineToCheck.ReadIsolation := IsolationLevel::UpdLock;
        TransferLineToCheck.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        TransferLineToCheck.SetRange("Subc. Prod. Order No.", PurchaseLine."Prod. Order No.");
        TransferLineToCheck.SetRange("Subc. Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        TransferLineToCheck.SetRange("Subc. Routing No.", PurchaseLine."Routing No.");
        TransferLineToCheck.SetRange("Subc. Routing Reference No.", PurchaseLine."Routing Reference No.");
        TransferLineToCheck.SetRange("Subc. Operation No.", PurchaseLine."Operation No.");
        TransferLineToCheck.SetRange("Item No.", PurchaseLine."No.");
        TransferLineToCheck.SetRange("Variant Code", PurchaseLine."Variant Code");
        TransferLineToCheck.SetRange("Derived From Line No.", 0);
        TransferLineToCheck.SetRange("Transfer WIP Item", true);
        TransferLineToCheck.SetRange("Subc. Return Order", true);
        exit(not TransferLineToCheck.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransferHeader(var TransferHeader: Record "Transfer Header"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocument(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;
}