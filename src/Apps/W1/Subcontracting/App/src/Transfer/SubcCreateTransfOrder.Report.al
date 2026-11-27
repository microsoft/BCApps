// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

report 20501 "Subc. Create Transf. Order"
{
    ApplicationArea = Subcontracting;
    Caption = 'Create Subcontracting Transfer Order';
    ProcessingOnly = true;
    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") order(ascending);
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") order(ascending) where("Prod. Order No." = filter(<> ''), "Operation No." = filter(<> ''));
                trigger OnAfterGetRecord()
                var
                    SubcontractingManagement: Codeunit "Subcontracting Management";
                begin
                    if not TempSelectedPurchaseLine.Get("Document Type", "Document No.", "Line No.") then begin
                        CurrReport.Skip();
                        exit;
                    end;
                    SubcontractingManagement.CheckWIPSelection("Purchase Line", TempSelectedPurchaseLine, TempProductionLine, TempRouting, SourceVersions);
                    HandleComponentsForPurchLine("Purchase Line", true);
                    HandleWIPTransferForPurchLine("Purchase Line", true);
                end;
            }
            trigger OnAfterGetRecord()
            var
                SubcPurchaseHeaderExt: Codeunit "Subc. Purchase Header Ext";
            begin
                "Purchase Header".CalcFields("Subc. Order");
                if not "Subc. Order" then
                    Error(OrderNoIsNotSubcontractorErr, PurchOrderNo);

                if not CanCreateHeaders.Get("No.") then begin
                    if HasCoveredDemand then
                        Error(SubcPurchaseHeaderExt.CreateCoveredTransferErrorInfo("Purchase Header"));
                    Error(NothingToCreateErr);
                end;

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
                CheckTransferCreated();
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
        TempWIPPlan: Record "Transfer Line" temporary;
        TempProductionLine: Record "Prod. Order Line" temporary;
        TempRouting: Record "Prod. Order Routing Line" temporary;
        CanCreateHeaders: Dictionary of [Code[20], Boolean];
        SourceVersions: Dictionary of [Text, BigInteger];
        SelectionViews: List of [Text];
        WIPPlanLineNo: Integer;
        HasCoveredDemand: Boolean;
        PurchOrderNo: Code[20];
        LineNo: Integer;
        ExcessReservationsErr: Label 'The transfer quantity (%1) is less than the reserved quantity (%2) on the production order component for item %3. Cancel existing reservations on the component before creating a partial transfer.', Comment = '%1=Transfer Quantity, %2=Reserved Quantity, %3=Item No.';
        NothingToCreateErr: Label 'Nothing to create. No components or WIP to transfer for the specified subcontracting order.';
        OrderNoDoesNotExistInProdOrderErr: Label 'Operation %1 in the subcontracting order %2 does not exist in the routing %3 of the production order %4.', Comment = '%1=Operation No., %2=Purchase Order No., %3=Routing No., %4=Production Order No.';
        OrderNoIsNotSubcontractorErr: Label 'Order %1 is not a Subcontractor work.', Comment = '%1=Purchase Order No.';
        WarningToSpecifyPurchOrderErr: Label 'Warning. Specify a Purchase Order No. for the Subcontractor work.';
        WIPSourceEvidenceErr: Label 'Cannot verify WIP availability for operation %1 of production order %2 at location %3, document %4. Retain the source documents and reconcile the WIP evidence before creating another transfer.', Comment = '%1 = predecessor operation, %2 = production order, %3 = source location, %4 = evidence document';
        WIPCoverageEvidenceErr: Label 'Cannot attribute WIP coverage for operation %1 of production order %2 at location %3. Reconcile the posted transfer evidence before creating another transfer.', Comment = '%1 = destination operation, %2 = production order, %3 = source location';

    local procedure IsOneStepDirectTransfer(var TransferRoute: Record "Transfer Route"; TransferRouteExists: Boolean): Boolean
    var
        InventorySetup: Record "Inventory Setup";
        DirectTransferPostingType: Enum "Direct Transfer Posting Type";
    begin
        if TransferRouteExists and TransferRoute."Direct Transfer" then
            DirectTransferPostingType := TransferRoute."Direct Transfer Posting"
        else begin
            InventorySetup.SetLoadFields("Direct Transfer Posting Type");
            InventorySetup.GetRecordOnce();
            DirectTransferPostingType := InventorySetup."Direct Transfer Posting Type";
        end;
        exit(DirectTransferPostingType = DirectTransferPostingType::"Direct Transfer");
    end;

    local procedure InsertTransferHeader(TransferFromLocation: Code[10])
    var
        TransferRoute: Record "Transfer Route";
        TransferToLocationCode: Code[10];
        TransferRouteExists: Boolean;
    begin
        GetTransferToLocationCode(TransferToLocationCode);

        TransferHeader.Reset();
        TransferHeader.SetRange("Subc. Source Type", TransferHeader."Subc. Source Type"::Subcontracting);
        TransferHeader.SetRange("Source ID", "Purchase Header"."Buy-from Vendor No.");
        TransferHeader.SetRange(Status, TransferHeader.Status::Open);
        TransferHeader.SetRange("Completely Shipped", false);
        TransferHeader.SetRange("Transfer-from Code", TransferFromLocation);
        TransferHeader.SetRange("Transfer-to Code", TransferToLocationCode);
        TransferHeader.SetRange("Subc. Return Order", false);
        TransferHeader.SetRange("Subcontr. Purch. Order No.", "Purchase Header"."No.");
        if not TransferHeader.FindFirst() then begin
            TransferHeader.Init();
            TransferHeader."No." := '';
            TransferHeader.Insert(true);
            TransferHeader.Validate("Transfer-from Code", TransferFromLocation);
            TransferHeader.Validate("Transfer-to Code", TransferToLocationCode);
            TransferRouteExists := TransferRoute.Get(TransferFromLocation, TransferToLocationCode);
            if not TransferRouteExists or (TransferRoute."In-Transit Code" = '') then
                TransferHeader.Validate("Direct Transfer", true)
            else
                if not IsOneStepDirectTransfer(TransferRoute, TransferRouteExists) then
                    TransferHeader.Validate("In-Transit Code", TransferRoute."In-Transit Code");

            TransferHeader."Subc. Source Type" := TransferHeader."Subc. Source Type"::Subcontracting;
            TransferHeader."Source ID" := "Purchase Header"."Buy-from Vendor No.";
            TransferHeader."Subcontr. Purch. Order No." := "Purchase Header"."No.";
            TransferHeader."Subcontr. PO Line No." := "Purchase Line"."Line No.";

            TransferHeader."Transfer-to Name" := Vendor.Name;
            TransferHeader."Transfer-to Name 2" := Vendor."Name 2";
            TransferHeader."Transfer-to Address" := Vendor.Address;
            TransferHeader."Transfer-to Address 2" := Vendor."Address 2";
            TransferHeader."Transfer-to Post Code" := Vendor."Post Code";
            TransferHeader."Transfer-to City" := Vendor.City;
            TransferHeader."Transfer-to County" := Vendor.County;
            TransferHeader."Trsf.-to Country/Region Code" := Vendor."Country/Region Code";

            OnInsertTransferHeaderOnBeforeModify(TransferHeader, Vendor, "Purchase Header");
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

    local procedure CheckTransferCreated(): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        SelectedHeader: Record "Purchase Header";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        CanCreate: Boolean;
    begin
        HasCoveredDemand := false;
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
                OnCheckTransferCreatedOnAfterPurchaseLineSetFilters(PurchaseLine, SelectedHeader);
                SelectionViews.Add(PurchaseLine.GetView(false));
                if PurchaseLine.FindSet() then
                    repeat
                        SubcontractingManagement.RememberWIPSelection(PurchaseLine, TempSelectedPurchaseLine, SourceVersions);
                    until PurchaseLine.Next() = 0;
            until SelectedHeader.Next() = 0;
        SubcontractingManagement.ProtectWIPSelection(TempSelectedPurchaseLine, TempProductionLine, TempRouting, SourceVersions);
        SubcontractingManagement.CheckWIPSelectedKeys(TempSelectedPurchaseLine, SelectionViews, SourceVersions);
        if TempSelectedPurchaseLine.FindSet() then
            repeat
                if PlanWIPTransfer(TempSelectedPurchaseLine) then begin
                    CanCreate := true;
                    CanCreateHeaders.Set(TempSelectedPurchaseLine."Document No.", true);
                end;
            until TempSelectedPurchaseLine.Next() = 0;
        if TempSelectedPurchaseLine.FindSet() then
            repeat
                if HandleComponentsForPurchLine(TempSelectedPurchaseLine, false) then begin
                    CanCreate := true;
                    CanCreateHeaders.Set(TempSelectedPurchaseLine."Document No.", true);
                end;
            until TempSelectedPurchaseLine.Next() = 0;
        exit(CanCreate);
    end;

    local procedure HandleComponentsForPurchLine(PurchaseLine: Record "Purchase Line"; InsertLine: Boolean): Boolean
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        MfgCostCalculationMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        SubcProdOrdCompRes: Codeunit "Subc. Prod. Ord. Comp. Res.";
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        UnitofMeasureManagement: Codeunit "Unit of Measure Management";
        TransferFromLocationCode: Code[10];
        QtyPerUom: Decimal;
        QtyToPost: Decimal;
    begin
        if not ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.",
             PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.")
        then
            Error(OrderNoDoesNotExistInProdOrderErr, PurchaseLine."Operation No.", PurchOrderNo, PurchaseLine."Routing No.", PurchaseLine."Prod. Order No.");

        Item.SetLoadFields("Base Unit of Measure", "Rounding Precision");
        Item.Get(PurchaseLine."No.");
        QtyPerUom := UnitofMeasureManagement.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
        ProdOrderComponent.SetRange(Status, "Production Order Status"::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        ProdOrderComponent.SetRange("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.SetRange("Subc. Purchase Order Filter", PurchaseLine."Document No.");
        ProdOrderComponent.SetRange("Component Supply Method", ProdOrderComponent."Component Supply Method"::"Transfer to Vendor");
        OnHandleComponentsForPurchLineOnAfterProdOrderComponentSetFilters(ProdOrderComponent, PurchaseLine);
        if ProdOrderComponent.FindSet() then
            repeat
                Item.SetLoadFields("Rounding Precision", "Order Tracking Policy");
                Item.Get(ProdOrderComponent."Item No.");
                QtyToPost := MfgCostCalculationMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComponent, Round(PurchaseLine.Quantity * QtyPerUom, UnitofMeasureManagement.QtyRndPrecision()));
                ProdOrderComponent.CalcFields("Subc. Qty.on TransOrder (Base)", "Subc. Qty. in Transit (Base)", "Subc. Qty. transf. to Subcontr");
                if (QtyToPost > 0) and
                   (QtyToPost <= (ProdOrderComponent."Subc. Qty.on TransOrder (Base)" +
                                 ProdOrderComponent."Subc. Qty. in Transit (Base)" +
                                 Abs(ProdOrderComponent."Subc. Qty. transf. to Subcontr")))
                then
                    HasCoveredDemand := true;
                if QtyToPost > (ProdOrderComponent."Subc. Qty.on TransOrder (Base)" +
                                ProdOrderComponent."Subc. Qty. in Transit (Base)" +
                                Abs(ProdOrderComponent."Subc. Qty. transf. to Subcontr"))
                then
                    if InsertLine then begin
                        TransferFromLocationCode := GetTransferFromLocationForComponent(ProdOrderComponent);
                        InsertTransferHeader(TransferFromLocationCode);

                        LineNo := LineNo + 10000;

                        TransferLine.Init();
                        TransferLine."Document No." := TransferHeader."No.";
                        TransferLine."Line No." := LineNo;

                        TransferLine.Insert();

                        TransferLine.Validate("Item No.", ProdOrderComponent."Item No.");
                        TransferLine.Validate("Variant Code", ProdOrderComponent."Variant Code");

                        TransferLine."Unit of Measure Code" := ProdOrderComponent."Unit of Measure Code";
                        TransferLine."Qty. per Unit of Measure" := ProdOrderComponent."Qty. per Unit of Measure";

                        QtyToPost := QtyToPost -
                            (ProdOrderComponent."Subc. Qty.on TransOrder (Base)" +
                             ProdOrderComponent."Subc. Qty. in Transit (Base)" +
                             Abs(ProdOrderComponent."Subc. Qty. transf. to Subcontr"));

                        TransferLine.Validate(Quantity, Round(QtyToPost / ProdOrderComponent."Qty. per Unit of Measure", Item."Rounding Precision", '>'));

                        if ProdOrderComponent."Due Date" <> 0D then
                            TransferLine.Validate("Receipt Date", SubcTransferManagement.CalcReceiptDateFromProdCompDueDateWithCompTransferLeadTime(ProdOrderComponent));

                        TransferLine."Subc. Purch. Order No." := PurchaseLine."Document No.";
                        TransferLine."Subc. Purch. Order Line No." := PurchaseLine."Line No.";
                        TransferLine."Subc. Prod. Order No." := PurchaseLine."Prod. Order No.";
                        TransferLine."Subc. Prod. Order Line No." := PurchaseLine."Prod. Order Line No.";
                        TransferLine."Subc. Prod. Ord. Comp Line No." := ProdOrderComponent."Line No.";
                        TransferLine."Subc. Routing No." := PurchaseLine."Routing No.";
                        TransferLine."Subc. Routing Reference No." := PurchaseLine."Routing Reference No.";
                        TransferLine."Subc. Work Center No." := PurchaseLine."Work Center No.";
                        TransferLine."Subc. Operation No." := PurchaseLine."Operation No.";
                        TransferLine.Modify();

                        if ProdOrderComponent."Subc. Original Location Code" = '' then
                            ProdOrderComponent."Subc. Original Location Code" := ProdOrderComponent."Location Code";
                        if ProdOrderComponent."Subc. Orig. Bin Code" = '' then
                            ProdOrderComponent."Subc. Orig. Bin Code" := ProdOrderComponent."Bin Code";

                        if SubcTransferManagement.ComponentHasExcessReservations(ProdOrderComponent, TransferLine."Quantity (Base)") then
                            Error(ExcessReservationsErr, TransferLine."Quantity (Base)", SubcTransferManagement.GetComponentReservedQtyBase(ProdOrderComponent), ProdOrderComponent."Item No.");

                        SubcTransferManagement.TransferReservationEntryFromProdOrderCompToTransferOrder(TransferLine, ProdOrderComponent);
                        if TransferHeader."Transfer-to Code" <> ProdOrderComponent."Location Code" then
                            if Item."Order Tracking Policy" = Item."Order Tracking Policy"::None then
                                SubcontractingManagement.ValidateProdOrderCompLocationPreservingFlushingMethod(ProdOrderComponent, TransferHeader."Transfer-to Code")
                            else begin
                                BindSubscription(SubcProdOrdCompRes);
                                SubcontractingManagement.ValidateProdOrderCompLocationPreservingFlushingMethod(ProdOrderComponent, TransferHeader."Transfer-to Code");
                                UnbindSubscription(SubcProdOrdCompRes);
                            end;
                        ProdOrderComponent.Modify();

                        SubcTransferManagement.CreateReservEntryForTransferReceiptToProdOrderComp(TransferLine, ProdOrderComponent);

                        OnAfterInsertTransferLine(TransferHeader, TransferLine, PurchaseLine, ProdOrderComponent);
                    end else
                        exit(true);
            until ProdOrderComponent.Next() = 0;

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
        SubcPurchFactboxMgmt.ShowTransferOrdersFromPurchaseOrder("Purchase Header", false);
    end;

    local procedure GetTransferFromLocationForComponent(ProdOrderComponent: Record "Prod. Order Component"): Code[10]
    var
        ResultLocationCode: Code[10];
        SubcontrLocationCode: Code[10];
    begin
        SubcontrLocationCode := "Purchase Header"."Subc. Location Code";
        if SubcontrLocationCode = '' then
            SubcontrLocationCode := Vendor."Subc. Location Code";

        if (ProdOrderComponent."Location Code" = SubcontrLocationCode) and
           (ProdOrderComponent."Subc. Original Location Code" <> '')
        then
            ResultLocationCode := ProdOrderComponent."Subc. Original Location Code"
        else
            ResultLocationCode := ProdOrderComponent."Location Code";
        exit(ResultLocationCode);
    end;

    local procedure GetTransferToLocationCode(var TransferToLocationCode: Code[10])
    begin
        GetTransferToLocationCodeForPurchaseHeader("Purchase Header", Vendor, TransferToLocationCode);
        if TransferToLocationCode = '' then
            Vendor.TestField("Subc. Location Code");
    end;

    local procedure GetTransferToLocationCodeForPurchaseHeader(PurchaseHeader: Record "Purchase Header"; VendorFromPurchaseHeader: Record Vendor; var TransferToLocationCode: Code[10])
    begin
        TransferToLocationCode := PurchaseHeader."Subc. Location Code";
        if TransferToLocationCode = '' then
            TransferToLocationCode := VendorFromPurchaseHeader."Subc. Location Code";
    end;

    local procedure HandleWIPTransferForPurchLine(PurchaseLine: Record "Purchase Line"; InsertLine: Boolean): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcontractingManagement: Codeunit "Subcontracting Management";
        Destination: Code[10];
    begin
        if not ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.") then
            exit(false);

        if not ProdOrderRoutingLine."Transfer WIP Item" then
            exit(false);

        TempWIPPlan.Reset();
        TempWIPPlan.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        TempWIPPlan.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        if not InsertLine then
            exit(not TempWIPPlan.IsEmpty());
        if TempWIPPlan.FindSet() then
            repeat
                SubcontractingManagement.CheckWIPSelection(PurchaseLine, TempSelectedPurchaseLine, TempProductionLine, TempRouting, SourceVersions);
                GetTransferToLocationCode(Destination);
                TempWIPPlan.TestField("Transfer-to Code", Destination);
                TempWIPPlan.TestField("Item No.", ProdOrderLine."Item No.");
                TempWIPPlan.TestField("Variant Code", ProdOrderLine."Variant Code");
                TempWIPPlan.TestField("Unit of Measure Code", PurchaseLine."Unit of Measure Code");
                if WIPQuantityBase(ProdOrderLine, TempWIPPlan."Unit of Measure Code", TempWIPPlan.Quantity) <> TempWIPPlan."Quantity (Base)" then
                    Error(WIPSourceEvidenceErr, TempWIPPlan."Prev. Operation No.", ProdOrderLine."Prod. Order No.", TempWIPPlan."Transfer-from Code", '');
                InsertTransferHeader(TempWIPPlan."Transfer-from Code");
                InsertWIPTransferLine(PurchaseLine, ProdOrderLine, ProdOrderRoutingLine, TempWIPPlan.Quantity, TempWIPPlan."Quantity (Base)", TempWIPPlan."Prev. Operation No.");
            until TempWIPPlan.Next() = 0;
        exit(false);
    end;

    local procedure PlanWIPTransfer(PurchaseLine: Record "Purchase Line"): Boolean
    var
        ProductionLine: Record "Prod. Order Line";
        Routing: Record "Prod. Order Routing Line";
        TempPredecessor: Record "Prod. Order Routing Line" temporary;
        TempSource: Record "Transfer Line" temporary;
        Header: Record "Purchase Header";
        PurchaseVendor: Record Vendor;
        SubcontractingManagement: Codeunit "Subcontracting Management";
        NativeLocations: List of [Code[10]];
        NativeQuantities: Dictionary of [Code[10], Decimal];
        NativePredecessors: Dictionary of [Code[10], Code[10]];
        NetByPredecessor: Dictionary of [Code[10], Decimal];
        Compatible: Boolean;
        LocationCode, Destination: Code[10];
        Demand, DestinationNet, OpenQuantity, Expected, Remaining, Available, SourceQuantity, SourceTotal, MissingDebit, SourceCommitment: Decimal;
        Planned: Boolean;
    begin
        if not ProductionLine.Get(ProductionLine.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);
        if not Routing.Get(Routing.Status::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.") then
            exit(false);
        if not Routing."Transfer WIP Item" then
            exit(false);
        Header.ReadIsolation := IsolationLevel::UpdLock;
        Header.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        if Header.SystemRowVersion <> SourceVersions.Get(Format(Header.RecordId)) then
            Error(WIPSourceEvidenceErr, Routing."Operation No.", ProductionLine."Prod. Order No.", '', Header."No.");
        PurchaseVendor.ReadIsolation := IsolationLevel::UpdLock;
        PurchaseVendor.Get(Header."Buy-from Vendor No.");
        GetTransferToLocationCodeForPurchaseHeader(Header, PurchaseVendor, Destination);
        if Destination = '' then
            PurchaseVendor.TestField("Subc. Location Code");
        Demand := CalcPurchLineQtyBase(PurchaseLine, ProductionLine);
        if Demand <= 0 then
            exit(false);
        DestinationNet := GetWIPQtyBase(PurchaseLine, Destination);
        OpenQuantity := GetOpenWIPTransferLineQtyBase(PurchaseLine, ProductionLine);
        Compatible := CollectWIPSources(ProductionLine, Routing, TempPredecessor, TempSource, Demand);
        if Compatible then begin
            GetWIPTransferFromLocations(ProductionLine, Routing, NativeLocations, NativeQuantities, NativePredecessors, Demand);
            foreach LocationCode in NativeLocations do
                Expected += NativeQuantities.Get(LocationCode);
        end else
            Expected := Demand * TempPredecessor.Count();

        if (Expected > 0) and (DestinationNet + OpenQuantity >= Expected) then begin
            HasCoveredDemand := true;
            exit(false);
        end;

        if Compatible then begin
            foreach LocationCode in NativeLocations do begin
                TempSource.Reset();
                TempSource.SetRange("Transfer-from Code", LocationCode);
                if TempSource.FindFirst() then begin
                    SourceQuantity := NativeQuantities.Get(LocationCode);
                    Available := SourceQuantity;
                    if NativeLocations.Count() = 1 then begin
                        Remaining := Demand - DestinationNet - OpenQuantity;
                        if SourceQuantity > Remaining then
                            SourceQuantity := Remaining;
                    end;
                    if TempSource."Transfer WIP Item" and (SourceQuantity > 0) then begin
                        MissingDebit := SubcontractingManagement.CheckWIPSourceEvidence(ProductionLine, Routing, TempSource."Prev. Operation No.", LocationCode);
                        SourceCommitment := GetUnshippedSourceCommitment(ProductionLine, Routing, TempSource, PurchaseLine, true);
                        // Only the own-only parallel preset may exclude the current line's unshipped claim.
                        if (NativeLocations.Count() = 1) or (SourceCommitment <> 0) then
                            SourceCommitment := GetUnshippedSourceCommitment(ProductionLine, Routing, TempSource, PurchaseLine, false);
                        Available := TempSource."Quantity (Base)" - MissingDebit - SourceCommitment;
                        if Available <= 0 then
                            Error(WIPSourceEvidenceErr, TempSource."Prev. Operation No.", ProductionLine."Prod. Order No.", LocationCode, '');
                        if (NativeLocations.Count() = 1) or (MissingDebit <> 0) or (SourceCommitment <> 0) then
                            if SourceQuantity > Available then
                                SourceQuantity := Available;
                    end;
                    if SourceQuantity > 0 then begin
                        AddWIPPlan(PurchaseLine, ProductionLine, LocationCode, Destination, NativePredecessors.Get(LocationCode), SourceQuantity, Available);
                        Planned := true;
                    end;
                end else
                    Error(WIPSourceEvidenceErr, NativePredecessors.Get(LocationCode), ProductionLine."Prod. Order No.", LocationCode, '');
            end;
            exit(Planned);
        end;

        AttributeDestinationNet(ProductionLine, Routing, TempPredecessor, TempSource, Destination, DestinationNet, NetByPredecessor);
        if TempPredecessor.FindSet() then
            repeat
                Remaining := Demand - NetByPredecessor.Get(TempPredecessor."Operation No.") -
                    GetOpenWIPForPredecessor(PurchaseLine, ProductionLine, Routing, TempPredecessor."Operation No.");
                if Remaining > 0 then begin
                    TempSource.Reset();
                    TempSource.SetRange("Prev. Operation No.", TempPredecessor."Operation No.");
                    if not TempSource.FindSet() then
                        Error(WIPSourceEvidenceErr, TempPredecessor."Operation No.", ProductionLine."Prod. Order No.",
                            PlannedSourceLocation(ProductionLine, TempPredecessor), '');
                    SourceTotal := 0;
                    repeat
                        Available := TempSource."Quantity (Base)";
                        if TempSource."Transfer WIP Item" then begin
                            Available -= SubcontractingManagement.CheckWIPSourceEvidence(ProductionLine, Routing, TempSource."Prev. Operation No.", TempSource."Transfer-from Code");
                            Available -= GetUnshippedSourceCommitment(ProductionLine, Routing, TempSource, PurchaseLine, false);
                        end;
                        if Available < 0 then
                            Available := 0;
                        TempSource.Quantity := Available;
                        TempSource.Modify();
                        SourceTotal += Available;
                    until TempSource.Next() = 0;
                    if (TempSource.Count() > 1) and (SourceTotal > Remaining) then begin
                        TempSource.FindFirst();
                        Error(WIPSourceEvidenceErr, TempPredecessor."Operation No.", ProductionLine."Prod. Order No.", TempSource."Transfer-from Code", '');
                    end;
                    TempSource.FindSet();
                    repeat
                        SourceQuantity := TempSource.Quantity;
                        if SourceQuantity > Remaining then
                            SourceQuantity := Remaining;
                        if SourceQuantity > 0 then begin
                            SourceQuantity := AddWIPPlan(PurchaseLine, ProductionLine, TempSource."Transfer-from Code", Destination, TempPredecessor."Operation No.", SourceQuantity, TempSource.Quantity);
                            Planned := true;
                            Remaining -= SourceQuantity;
                        end;
                    until TempSource.Next() = 0;
                    if (SourceTotal = 0) and (Remaining > 0) then begin
                        TempSource.FindFirst();
                        Error(WIPSourceEvidenceErr, TempPredecessor."Operation No.", ProductionLine."Prod. Order No.", TempSource."Transfer-from Code", '');
                    end;
                end;
            until TempPredecessor.Next() = 0;
        exit(Planned);
    end;

    local procedure CollectWIPSources(ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; var TempPredecessor: Record "Prod. Order Routing Line" temporary; var TempSource: Record "Transfer Line" temporary; Demand: Decimal): Boolean
    var
        Predecessor: Record "Prod. Order Routing Line";
        Entry, LocationEntry: Record "Subcontractor WIP Ledger Entry";
        Locations: List of [Code[10]];
        UsedLocations: List of [Code[10]];
        LocationCode, PlannedLocation: Code[10];
        Net: Decimal;
        SourceNo, SourceCount: Integer;
        Compatible, HasHistory, FirstPredecessor, TransferWIP: Boolean;
        DifferentWIPFlagsErr: Label 'Field ''''%1'''' must have the same value for all previous operations of the routing.', Comment = '%1 = Transfer WIP Item';
    begin
        Predecessor.ReadIsolation := IsolationLevel::UpdLock;
        Compatible := true;
        if Routing."Previous Operation No." = '' then begin
            Predecessor := Routing;
            Predecessor."Operation No." := '';
            TempPredecessor := Predecessor;
            TempPredecessor.Insert();
            AddWIPSource(TempSource, SourceNo, '', ProductionLine."Location Code", Demand, false);
            exit(true);
        end;
        Predecessor.SetRange(Status, Routing.Status);
        Predecessor.SetRange("Prod. Order No.", Routing."Prod. Order No.");
        Predecessor.SetRange("Routing Reference No.", Routing."Routing Reference No.");
        Predecessor.SetRange("Routing No.", Routing."Routing No.");
        Predecessor.SetFilter("Operation No.", Routing."Previous Operation No.");
        FirstPredecessor := true;
        if Predecessor.FindSet() then
            repeat
                if FirstPredecessor then begin
                    TransferWIP := Predecessor."Transfer WIP Item";
                    FirstPredecessor := false;
                end else
                    if TransferWIP <> Predecessor."Transfer WIP Item" then
                        Error(DifferentWIPFlagsErr, Predecessor.FieldCaption("Transfer WIP Item"));
                TempPredecessor := Predecessor;
                TempPredecessor.Insert();
                PlannedLocation := PlannedSourceLocation(ProductionLine, Predecessor);
                SourceCount := 0;
                HasHistory := false;
                Clear(Locations);
                if Predecessor."Transfer WIP Item" then begin
                    FilterWIPIdentity(Entry, ProductionLine, Predecessor);
                    HasHistory := not Entry.IsEmpty();
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
                                Net := LocationEntry."Quantity (Base)";
                                if Net > 0 then begin
                                    SourceCount += 1;
                                    AddWIPSource(TempSource, SourceNo, Predecessor."Operation No.", LocationCode, Net, true);
                                    if (LocationCode <> PlannedLocation) or UsedLocations.Contains(LocationCode) then
                                        Compatible := false;
                                    UsedLocations.Add(LocationCode);
                                end;
                            end;
                        until Entry.Next() = 0;
                end;
                if not HasHistory and not HasPrecursorCommitment(ProductionLine, Predecessor) then begin
                    AddWIPSource(TempSource, SourceNo, Predecessor."Operation No.", PlannedLocation, Demand, false);
                    SourceCount := 1;
                end;
                if SourceCount <> 1 then
                    Compatible := false;
            until Predecessor.Next() = 0;
        exit(Compatible);
    end;

    local procedure PlannedSourceLocation(ProductionLine: Record "Prod. Order Line"; Predecessor: Record "Prod. Order Routing Line"): Code[10]
    var
        SourceVendor: Record Vendor;
    begin
        if Predecessor."Transfer WIP Item" then
            if SourceVendor.Get(Predecessor.GetEffectiveSubcontractorNo()) then
                if SourceVendor."Subc. Location Code" <> '' then
                    exit(SourceVendor."Subc. Location Code");
        exit(ProductionLine."Location Code");
    end;

    local procedure AddWIPSource(var TempSource: Record "Transfer Line" temporary; var SourceNo: Integer; PreviousOperation: Code[10]; LocationCode: Code[10]; QuantityBase: Decimal; Physical: Boolean)
    begin
        if LocationCode = '' then
            exit;
        SourceNo += 1;
        TempSource.Init();
        TempSource."Line No." := SourceNo;
        TempSource."Prev. Operation No." := PreviousOperation;
        TempSource."Transfer-from Code" := LocationCode;
        TempSource."Quantity (Base)" := QuantityBase;
        TempSource."Transfer WIP Item" := Physical;
        TempSource.Insert();
    end;

    local procedure FilterWIPIdentity(var Entry: Record "Subcontractor WIP Ledger Entry"; ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line")
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        SubcontractingManagement.FilterWIPSourceIdentity(Entry, ProductionLine, Routing);
    end;

    local procedure FilterWIPTransferIdentity(var Line: Record "Transfer Line"; ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line")
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        SubcontractingManagement.FilterWIPTransferSourceIdentity(Line, ProductionLine, Routing);
    end;

    local procedure HasPrecursorCommitment(ProductionLine: Record "Prod. Order Line"; Predecessor: Record "Prod. Order Routing Line"): Boolean
    var
        Line: Record "Transfer Line";
        Shipment: Record "Transfer Shipment Line";
        Receipt: Record "Transfer Receipt Line";
        DirectLine: Record "Direct Trans. Line";
    begin
        FilterWIPTransferIdentity(Line, ProductionLine, Predecessor);
        Line.SetRange("Subc. Operation No.", Predecessor."Operation No.");
        if not Line.IsEmpty() then
            exit(true);
        Shipment.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
        Shipment.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
        Shipment.SetRange("Subc. Routing No.", Predecessor."Routing No.");
        Shipment.SetRange("Subc. Routing Reference No.", Predecessor."Routing Reference No.");
        Shipment.SetRange("Subc. Operation No.", Predecessor."Operation No.");
        Shipment.SetRange("Item No.", ProductionLine."Item No.");
        Shipment.SetRange("Variant Code", ProductionLine."Variant Code");
        Shipment.SetRange("Transfer WIP Item", true);
        if not Shipment.IsEmpty() then
            exit(true);
        Receipt.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
        Receipt.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
        Receipt.SetRange("Subc. Routing No.", Predecessor."Routing No.");
        Receipt.SetRange("Subc. Routing Reference No.", Predecessor."Routing Reference No.");
        Receipt.SetRange("Subc. Operation No.", Predecessor."Operation No.");
        Receipt.SetRange("Item No.", ProductionLine."Item No.");
        Receipt.SetRange("Variant Code", ProductionLine."Variant Code");
        Receipt.SetRange("Transfer WIP Item", true);
        if not Receipt.IsEmpty() then
            exit(true);
        DirectLine.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
        DirectLine.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
        DirectLine.SetRange("Routing No.", Predecessor."Routing No.");
        DirectLine.SetRange("Routing Reference No.", Predecessor."Routing Reference No.");
        DirectLine.SetRange("Operation No.", Predecessor."Operation No.");
        DirectLine.SetRange("Item No.", ProductionLine."Item No.");
        DirectLine.SetRange("Variant Code", ProductionLine."Variant Code");
        DirectLine.SetRange("Transfer WIP Item", true);
        exit(not DirectLine.IsEmpty());
    end;

    local procedure GetOpenWIPForPredecessor(PurchaseLine: Record "Purchase Line"; ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; PreviousOperation: Code[10]): Decimal
    var
        Line: Record "Transfer Line";
        Total: Decimal;
    begin
        FilterWIPTransferIdentity(Line, ProductionLine, Routing);
        Line.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        Line.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        Line.SetRange("Subc. Operation No.", Routing."Operation No.");
        Line.SetRange("Derived From Line No.", 0);
        Line.SetRange("Subc. Return Order", false);
        Line.SetRange("Prev. Operation No.", PreviousOperation);
        if Line.FindSet() then
            repeat
                Total += WIPQuantityBase(ProductionLine, Line."Unit of Measure Code", Line.Quantity);
            until Line.Next() = 0;
        exit(Total);
    end;

    local procedure GetUnshippedSourceCommitment(ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; Source: Record "Transfer Line"; PurchaseLine: Record "Purchase Line"; ExcludeCurrentPurchaseLine: Boolean): Decimal
    var
        PlannedLine: Record "Transfer Line" temporary;
        SubcontractingManagement: Codeunit "Subcontracting Management";
        Total: Decimal;
    begin
        Total := SubcontractingManagement.GetWIPSourceCommitment(ProductionLine, Routing, Source."Prev. Operation No.", Source."Transfer-from Code", PurchaseLine, ExcludeCurrentPurchaseLine);
        PlannedLine.Copy(TempWIPPlan, true);
        PlannedLine.Reset();
        PlannedLine.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
        PlannedLine.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
        PlannedLine.SetRange("Subc. Routing No.", Routing."Routing No.");
        PlannedLine.SetRange("Subc. Routing Reference No.", Routing."Routing Reference No.");
        PlannedLine.SetRange("Item No.", ProductionLine."Item No.");
        PlannedLine.SetRange("Variant Code", ProductionLine."Variant Code");
        PlannedLine.SetRange("Prev. Operation No.", Source."Prev. Operation No.");
        PlannedLine.SetRange("Transfer-from Code", Source."Transfer-from Code");
        PlannedLine.CalcSums("Quantity (Base)");
        Total += PlannedLine."Quantity (Base)";
        exit(Total);
    end;

    local procedure AddWIPPlan(PurchaseLine: Record "Purchase Line"; ProductionLine: Record "Prod. Order Line"; LocationCode: Code[10]; Destination: Code[10]; PreviousOperation: Code[10]; QuantityBase: Decimal; PhysicalCap: Decimal): Decimal
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
        ActualBase, DocumentQuantity: Decimal;
    begin
        DocumentQuantity := SubcontractingManagement.RoundWIPPlanQuantity(ProductionLine, PurchaseLine."Unit of Measure Code", QuantityBase, PhysicalCap, PreviousOperation, LocationCode, ActualBase);
        WIPPlanLineNo += 1;
        TempWIPPlan.Reset();
        TempWIPPlan.Init();
        TempWIPPlan."Line No." := WIPPlanLineNo;
        TempWIPPlan."Subc. Purch. Order No." := PurchaseLine."Document No.";
        TempWIPPlan."Subc. Purch. Order Line No." := PurchaseLine."Line No.";
        TempWIPPlan."Subc. Prod. Order No." := ProductionLine."Prod. Order No.";
        TempWIPPlan."Subc. Prod. Order Line No." := ProductionLine."Line No.";
        TempWIPPlan."Subc. Routing No." := PurchaseLine."Routing No.";
        TempWIPPlan."Subc. Routing Reference No." := PurchaseLine."Routing Reference No.";
        TempWIPPlan."Subc. Operation No." := PurchaseLine."Operation No.";
        TempWIPPlan."Subc. Work Center No." := PurchaseLine."Work Center No.";
        TempWIPPlan."Item No." := ProductionLine."Item No.";
        TempWIPPlan."Variant Code" := ProductionLine."Variant Code";
        TempWIPPlan."Unit of Measure Code" := PurchaseLine."Unit of Measure Code";
        TempWIPPlan."Quantity (Base)" := ActualBase;
        TempWIPPlan."Prev. Operation No." := PreviousOperation;
        TempWIPPlan."Transfer-from Code" := LocationCode;
        TempWIPPlan."Transfer-to Code" := Destination;
        TempWIPPlan.Quantity := DocumentQuantity;
        if TempWIPPlan.Quantity > 0 then
            TempWIPPlan.Insert();
        exit(ActualBase);
    end;

    local procedure WIPQuantityBase(ProductionLine: Record "Prod. Order Line"; UOMCode: Code[10]; Quantity: Decimal): Decimal
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        exit(SubcontractingManagement.WIPQuantityBase(ProductionLine, UOMCode, Quantity));
    end;

    local procedure ResolvePostedSource(ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; SourceLocation: Code[10]; DocumentNo: Code[20]; DocumentLineNo: Integer; TransferOrderNo: Code[20]; OriginalLineNo: Integer; DerivedLineNo: Integer; CurrentOperation: Code[10]; IsReturn: Boolean; QuantityBase: Decimal; var PreviousOperation: Code[10]; var Debited: Boolean): Boolean
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        exit(SubcontractingManagement.ResolveWIPPostedSource(ProductionLine, Routing, SourceLocation, DocumentNo, DocumentLineNo, TransferOrderNo, OriginalLineNo, DerivedLineNo, CurrentOperation, IsReturn, QuantityBase, PreviousOperation, Debited));
    end;

    local procedure AttributeDestinationNet(ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; var TempPredecessor: Record "Prod. Order Routing Line" temporary; var TempSource: Record "Transfer Line" temporary; Destination: Code[10]; DestinationNet: Decimal; var NetByPredecessor: Dictionary of [Code[10], Decimal])
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
        Known: Dictionary of [Code[10], Boolean];
        PreviousOperation, UnknownOperation, EvidenceLocation: Code[10];
        Assigned: Decimal;
        UnknownCount: Integer;
        HasUnknownEntries, HasUnknownNegative: Boolean;
    begin
        TempPredecessor.FindSet();
        if TempPredecessor.Count() = 1 then begin
            NetByPredecessor.Add(TempPredecessor."Operation No.", DestinationNet);
            exit;
        end;
        repeat
            NetByPredecessor.Add(TempPredecessor."Operation No.", 0);
        until TempPredecessor.Next() = 0;
        FilterWIPIdentity(Entry, ProductionLine, Routing);
        Entry.SetRange("Location Code", Destination);
        Entry.SetRange("In Transit", false);
        if Entry.FindSet() then
            repeat
                if (Entry."Quantity (Base)" > 0) and
                   ResolveDestinationPredecessor(ProductionLine, Routing, Entry, PreviousOperation) and
                   NetByPredecessor.ContainsKey(PreviousOperation)
                then begin
                    NetByPredecessor.Set(PreviousOperation, NetByPredecessor.Get(PreviousOperation) + Entry."Quantity (Base)");
                    Known.Set(PreviousOperation, true);
                    Assigned += Entry."Quantity (Base)";
                end else
                    if Entry."Quantity (Base)" <> 0 then begin
                        HasUnknownEntries := true;
                        if Entry."Quantity (Base)" < 0 then
                            HasUnknownNegative := true;
                    end;
            until Entry.Next() = 0;
        TempPredecessor.FindSet();
        repeat
            if not Known.ContainsKey(TempPredecessor."Operation No.") then begin
                UnknownCount += 1;
                UnknownOperation := TempPredecessor."Operation No.";
            end;
        until TempPredecessor.Next() = 0;
        if (DestinationNet = Assigned) and not HasUnknownEntries then
            exit;
        // An unresolved return can belong to a known predecessor, not just the sole unknown one.
        if (UnknownCount = 1) and not HasUnknownNegative then begin
            NetByPredecessor.Set(UnknownOperation, DestinationNet - Assigned);
            exit;
        end;
        TempSource.Reset();
        if TempSource.FindFirst() then
            EvidenceLocation := TempSource."Transfer-from Code";
        Error(WIPCoverageEvidenceErr, Routing."Operation No.", ProductionLine."Prod. Order No.", EvidenceLocation);
    end;

    local procedure ResolveDestinationPredecessor(ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; Entry: Record "Subcontractor WIP Ledger Entry"; var PreviousOperation: Code[10]): Boolean
    var
        Receipt: Record "Transfer Receipt Line";
        Shipment: Record "Transfer Shipment Line";
        DirectLine: Record "Direct Trans. Line";
        DirectHeader: Record "Direct Trans. Header";
        Debited: Boolean;
        Resolved: Boolean;
        FoundOperation: Code[10];
        QuantityBase: Decimal;
    begin
        if Entry."Document Type" <> Entry."Document Type"::"Transfer Order" then
            exit(false);
        if Receipt.Get(Entry."Document No.", Entry."Document Line No.") then begin
            if (Receipt."Subc. Prod. Order No." <> ProductionLine."Prod. Order No.") or
               (Receipt."Subc. Prod. Order Line No." <> ProductionLine."Line No.") or
               (Receipt."Subc. Routing No." <> Routing."Routing No.") or
               (Receipt."Subc. Routing Reference No." <> Routing."Routing Reference No.") or
               (Receipt."Subc. Operation No." <> Routing."Operation No.") or
               (Receipt."Item No." <> ProductionLine."Item No.") or
               (Receipt."Variant Code" <> ProductionLine."Variant Code") or not Receipt."Transfer WIP Item" or
               (Receipt."Transfer-to Code" <> Entry."Location Code")
            then
                exit(false);
            Shipment.SetRange("Transfer Order No.", Receipt."Transfer Order No.");
            Shipment.SetRange("Derived Trans. Order Line No.", Receipt."Line No.");
            if Shipment.IsEmpty() then begin
                Shipment.SetRange("Derived Trans. Order Line No.");
                Shipment.SetRange("Trans. Order Line No.", Receipt."Line No.");
            end;
            Shipment.SetRange("Transfer WIP Item", true);
            Shipment.SetRange("Item No.", ProductionLine."Item No.");
            Shipment.SetRange("Variant Code", ProductionLine."Variant Code");
            Shipment.SetRange("Transfer-from Code", Receipt."Transfer-from Code");
            Shipment.SetRange("Transfer-to Code", Receipt."Transfer-to Code");
            Shipment.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
            Shipment.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
            Shipment.SetRange("Subc. Routing No.", Routing."Routing No.");
            Shipment.SetRange("Subc. Routing Reference No.", Routing."Routing Reference No.");
            Shipment.SetRange("Subc. Operation No.", Routing."Operation No.");
            if Shipment.FindSet() then
                repeat
                    QuantityBase := WIPQuantityBase(ProductionLine, Shipment."Unit of Measure Code", Shipment.Quantity);
                    if not ResolvePostedSource(ProductionLine, Routing, Shipment."Transfer-from Code",
                         Shipment."Document No.", Shipment."Line No.", Shipment."Transfer Order No.",
                         Shipment."Trans. Order Line No.", Shipment."Derived Trans. Order Line No.",
                         Shipment."Subc. Operation No.", Shipment."Subc. Return Order", QuantityBase, FoundOperation, Debited)
                    then
                        exit(false);
                    if Resolved and (FoundOperation <> PreviousOperation) then
                        exit(false);
                    PreviousOperation := FoundOperation;
                    Resolved := true;
                until Shipment.Next() = 0;
            exit(Resolved);
        end;
        if DirectLine.Get(Entry."Document No.", Entry."Document Line No.") then begin
            if (DirectLine."Prod. Order No." <> ProductionLine."Prod. Order No.") or
               (DirectLine."Prod. Order Line No." <> ProductionLine."Line No.") or
               (DirectLine."Routing No." <> Routing."Routing No.") or
               (DirectLine."Routing Reference No." <> Routing."Routing Reference No.") or
               (DirectLine."Operation No." <> Routing."Operation No.") or
               (DirectLine."Item No." <> ProductionLine."Item No.") or
               (DirectLine."Variant Code" <> ProductionLine."Variant Code") or not DirectLine."Transfer WIP Item" or
               (DirectLine."Transfer-to Code" <> Entry."Location Code")
            then
                exit(false);
            DirectHeader.Get(DirectLine."Document No.");
            QuantityBase := WIPQuantityBase(ProductionLine, DirectLine."Unit of Measure Code", DirectLine.Quantity);
            exit(ResolvePostedSource(ProductionLine, Routing, DirectLine."Transfer-from Code",
                 DirectLine."Document No.", DirectLine."Line No.", DirectHeader."Transfer Order No.",
                 DirectLine."Line No.", 0, DirectLine."Operation No.", DirectLine."Subc. Return Order",
                 QuantityBase, PreviousOperation, Debited));
        end;
        exit(false);
    end;

    local procedure InsertWIPTransferLine(PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WIPQty: Decimal; PlannedBase: Decimal; WIPPreviousOperationNo: Code[10])
    begin
        TransferHeader.TestField("Transfer-from Code", TempWIPPlan."Transfer-from Code");
        TransferHeader.TestField("Transfer-to Code", TempWIPPlan."Transfer-to Code");
        LineNo := LineNo + 10000;

        TransferLine.Init();
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := LineNo;
        TransferLine.Insert();

        TransferLine.Validate("Item No.", ProdOrderLine."Item No.");
        if ProdOrderLine."Variant Code" <> '' then
            TransferLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        TransferLine.Validate("Unit of Measure Code", PurchaseLine."Unit of Measure Code");
        TransferLine.Validate("Transfer WIP Item", true);
        TransferLine.Validate(Quantity, WIPQty);
        TransferLine.TestField(Quantity, WIPQty);
        if TransferLine.CalcBaseQty(TransferLine.Quantity) <> PlannedBase then
            Error(WIPSourceEvidenceErr, WIPPreviousOperationNo, ProdOrderLine."Prod. Order No.", TransferHeader."Transfer-from Code", '');

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
        TransferLine."Prev. Operation No." := WIPPreviousOperationNo;

        TransferLine.Modify();

        OnAfterInsertWIPTransferLine(TransferHeader, TransferLine, PurchaseLine, ProdOrderLine, ProdOrderRoutingLine);
    end;

    local procedure GetWIPTransferFromLocations(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var WIPSourceLocationList: List of [Code[10]]; var WIPSourceQtyDict: Dictionary of [Code[10], Decimal]; var WIPPreviousOperationNoDict: Dictionary of [Code[10], Code[10]]; PurchLineQtyBase: Decimal)
    var
        PrevProdOrderRoutingLine: Record "Prod. Order Routing Line";
        LocCode: Code[10];
        WIPQtyBase: Decimal;
        IsSerial, TransferWIPItem, FoundSubcontractingPrevOp : Boolean;
        WIPItemTransferDifferentErr: Label 'Field ''''%1'''' must have the same value for all previous operations of the routing.', Comment = '%1=Transfer WIP Item';
    begin
        PrevProdOrderRoutingLine.ReadIsolation := IsolationLevel::UpdLock;
        // No previous operation: initial transfer directly from Prod. Order Line location
        if ProdOrderRoutingLine."Previous Operation No." = '' then begin
            LocCode := ProdOrderLine."Location Code";
            if LocCode <> '' then begin
                WIPSourceLocationList.Add(LocCode);
                WIPSourceQtyDict.Add(LocCode, PurchLineQtyBase);
                WIPPreviousOperationNoDict.Add(LocCode, '');
            end;
            exit;
        end;

        IsSerial := ProdOrderRoutingLine.IsSerial();

        PrevProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        PrevProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        PrevProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        PrevProdOrderRoutingLine.SetFilter("Operation No.", ProdOrderRoutingLine."Previous Operation No.");
        PrevProdOrderRoutingLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        PrevProdOrderRoutingLine.SetLoadFields("Operation No.", "Transfer WIP Item");
        PrevProdOrderRoutingLine.SetAutoCalcFields(Subcontracting);
        if PrevProdOrderRoutingLine.FindSet() then
            repeat
                if not FoundSubcontractingPrevOp then begin
                    TransferWIPItem := PrevProdOrderRoutingLine."Transfer WIP Item";
                    FoundSubcontractingPrevOp := true;
                end else
                    if TransferWIPItem <> PrevProdOrderRoutingLine."Transfer WIP Item" then
                        Error(WIPItemTransferDifferentErr, PrevProdOrderRoutingLine.FieldCaption("Transfer WIP Item"));

                GetWIPLocationAndQtyForPreviousOp(
                    ProdOrderLine, PrevProdOrderRoutingLine, IsSerial, PurchLineQtyBase, LocCode, WIPQtyBase);

                if (LocCode <> '') and (WIPQtyBase > 0) and (not WIPSourceQtyDict.ContainsKey(LocCode)) then begin
                    WIPSourceLocationList.Add(LocCode);
                    WIPSourceQtyDict.Add(LocCode, WIPQtyBase);
                    WIPPreviousOperationNoDict.Add(LocCode, PrevProdOrderRoutingLine."Operation No.");
                end;
            until PrevProdOrderRoutingLine.Next() = 0;

        if WIPSourceLocationList.Count() = 0 then begin
            LocCode := ProdOrderLine."Location Code";
            if LocCode <> '' then begin
                WIPSourceLocationList.Add(LocCode);
                WIPSourceQtyDict.Add(LocCode, PurchLineQtyBase);
                WIPPreviousOperationNoDict.Add(LocCode, '');
            end;
        end;
    end;

    local procedure GetWIPLocationAndQtyForPreviousOp(ProdOrderLine: Record "Prod. Order Line"; PrevProdOrderRoutingLine: Record "Prod. Order Routing Line"; IsSerial: Boolean; PurchLineQtyBase: Decimal; var LocationCode: Code[10]; var WIPQtyBase: Decimal)
    var
        WIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        LocationCode := ProdOrderLine."Location Code";
        WIPQtyBase := PurchLineQtyBase;

        if PrevProdOrderRoutingLine."Transfer WIP Item" then begin
            // Previous op has a subcontracting WIP transfer
            LocationCode := PlannedSourceLocation(ProdOrderLine, PrevProdOrderRoutingLine);

            if LocationCode <> '' then begin
                WIPLedgerEntry.SetRange("Prod. Order Status", "Production Order Status"::Released);
                WIPLedgerEntry.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                WIPLedgerEntry.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                WIPLedgerEntry.SetRange("Routing No.", PrevProdOrderRoutingLine."Routing No.");
                WIPLedgerEntry.SetRange("Routing Reference No.", PrevProdOrderRoutingLine."Routing Reference No.");
                WIPLedgerEntry.SetRange("Operation No.", PrevProdOrderRoutingLine."Operation No.");
                WIPLedgerEntry.SetRange("Item No.", ProdOrderLine."Item No.");
                WIPLedgerEntry.SetRange("Variant Code", ProdOrderLine."Variant Code");
                WIPLedgerEntry.SetRange("Location Code", LocationCode);
                WIPLedgerEntry.SetRange("In Transit", false);
                WIPLedgerEntry.ReadIsolation := IsolationLevel::UpdLock;
                WIPLedgerEntry.CalcSums("Quantity (Base)");
            end;
        end;

        // Parallel routings always use Prod. Order Line quantity as preset
        if IsSerial and (WIPLedgerEntry."Quantity (Base)" <> 0) then
            WIPQtyBase := WIPLedgerEntry."Quantity (Base)";
    end;

    local procedure GetOpenWIPTransferLineQtyBase(PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"): Decimal
    var
        TransferLineToCheck: Record "Transfer Line";
        Total: Decimal;
    begin
        TransferLineToCheck.ReadIsolation := IsolationLevel::UpdLock;
        TransferLineToCheck.SetCurrentKey("Subc. Prod. Order No.", "Subc. Prod. Order Line No.", "Subc. Routing Reference No.", "Subc. Routing No.", "Subc. Operation No.");
        TransferLineToCheck.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        TransferLineToCheck.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        TransferLineToCheck.SetRange("Subc. Prod. Order No.", PurchaseLine."Prod. Order No.");
        TransferLineToCheck.SetRange("Subc. Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        TransferLineToCheck.SetRange("Subc. Routing No.", PurchaseLine."Routing No.");
        TransferLineToCheck.SetRange("Subc. Routing Reference No.", PurchaseLine."Routing Reference No.");
        TransferLineToCheck.SetRange("Item No.", ProdOrderLine."Item No.");
        TransferLineToCheck.SetRange("Variant Code", ProdOrderLine."Variant Code");
        TransferLineToCheck.SetRange("Subc. Operation No.", PurchaseLine."Operation No.");
        TransferLineToCheck.SetRange("Derived From Line No.", 0);
        TransferLineToCheck.SetRange("Transfer WIP Item", true);
        TransferLineToCheck.SetRange("Subc. Return Order", false);
        // Full originals retain native N+O coverage; WIP's stored base quantity is intentionally zero.
        if TransferLineToCheck.FindSet() then
            repeat
                Total += WIPQuantityBase(ProdOrderLine, TransferLineToCheck."Unit of Measure Code", TransferLineToCheck.Quantity);
            until TransferLineToCheck.Next() = 0;
        exit(Total);
    end;

    local procedure CalcPurchLineQtyBase(PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"): Decimal
    var
        Item: Record Item;
        UOMManagement: Codeunit "Unit of Measure Management";
        QtyPerUom: Decimal;
    begin
        Item.SetLoadFields("Base Unit of Measure");
        Item.Get(ProdOrderLine."Item No.");
        QtyPerUom := UOMManagement.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");
        exit(UOMManagement.CalcBaseQty(PurchaseLine.Quantity, QtyPerUom));
    end;

    local procedure GetWIPQtyBase(PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]): Decimal
    var
        SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        SubcontractorWIPLedgerEntry.SetRange("Prod. Order Status", "Production Order Status"::Released);
        SubcontractorWIPLedgerEntry.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        SubcontractorWIPLedgerEntry.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        SubcontractorWIPLedgerEntry.SetRange("Routing No.", PurchaseLine."Routing No.");
        SubcontractorWIPLedgerEntry.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
        SubcontractorWIPLedgerEntry.SetRange("Operation No.", PurchaseLine."Operation No.");
        SubcontractorWIPLedgerEntry.SetRange("Item No.", PurchaseLine."No.");
        SubcontractorWIPLedgerEntry.SetRange("Variant Code", PurchaseLine."Variant Code");
        SubcontractorWIPLedgerEntry.SetRange("Location Code", LocationCode);
        SubcontractorWIPLedgerEntry.SetRange("In Transit", false);
        SubcontractorWIPLedgerEntry.ReadIsolation := IsolationLevel::UpdLock;
        SubcontractorWIPLedgerEntry.CalcSums("Quantity (Base)");
        exit(SubcontractorWIPLedgerEntry."Quantity (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransferHeaderOnBeforeModify(var TransferHeader: Record "Transfer Header"; Vendor: Record Vendor; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransferHeader(var TransferHeader: Record "Transfer Header"; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransferLine(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; PurchaseLine: Record "Purchase Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertWIPTransferLine(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTransferCreatedOnAfterPurchaseLineSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleComponentsForPurchLineOnAfterProdOrderComponentSetFilters(var ProdOrderComponent: Record "Prod. Order Component"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDocument(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;
}
