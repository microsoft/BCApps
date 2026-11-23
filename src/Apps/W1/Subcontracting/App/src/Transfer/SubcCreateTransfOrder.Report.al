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
using Microsoft.Manufacturing.WorkCenter;
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
                begin
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

                if not CheckTransferCreated() then begin
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
            end;
        }
    }
    requestpage
    {
        SaveValues = false;
        layout
        {
            area(Content)
            {
                group(Context)
                {
                    Caption = 'Subcontracting Order';
                    field(PurchaseOrderNo; PurchOrderNo) { ApplicationArea = Subcontracting; Caption = 'Purchase Order No.'; Editable = false; ToolTip = 'Specifies the purchase order used to calculate the transfer.'; }
                    field(VendorNo; ContextVendorNo) { ApplicationArea = Subcontracting; Caption = 'Vendor No.'; Editable = false; ToolTip = 'Specifies the subcontracting vendor on the purchase order.'; }
                    field(SubcontractorLocation; ContextLocation) { ApplicationArea = Subcontracting; Caption = 'Subcontractor Location Code'; Editable = false; ToolTip = 'Specifies the subcontractor location used by the transfer.'; }
                }
                group(Options)
                {
                    Caption = 'Include';
                    field(IncludeComponents; IncludeComponents) { ApplicationArea = Subcontracting; Caption = 'Include Components'; ToolTip = 'Specifies whether to include component quantities that must be sent to the subcontractor.'; }
                    field(IncludeWIP; IncludeWIP) { ApplicationArea = Subcontracting; Caption = 'Include WIP'; ToolTip = 'Specifies whether to include WIP quantity that must be sent or moved to the subcontractor.'; }
                }
                group(Filters)
                {
                    Caption = 'Filters';
                    field(ProductionOrderNo; OrderFilter) { ApplicationArea = Subcontracting; Caption = 'Production Order No.'; ToolTip = 'Specifies a filter on the production order number.'; }
                    field(ProductionOrderLineNo; LineFilter) { ApplicationArea = Subcontracting; Caption = 'Production Order Line No.'; ToolTip = 'Specifies a filter on the production order line number.'; }
                    field(OperationNo; OperationFilter) { ApplicationArea = Subcontracting; Caption = 'Operation No.'; ToolTip = 'Specifies a filter on the operation number.'; }
                    field(WorkCenterNo; WorkCenterFilter) { ApplicationArea = Subcontracting; Caption = 'Work Center No.'; ToolTip = 'Specifies a filter on the work center number.'; }
                    field(ItemNo; ItemFilter) { ApplicationArea = Subcontracting; Caption = 'Item No.'; ToolTip = 'Specifies a filter on the item being transferred.'; }
                    field(VariantCode; VariantFilter) { ApplicationArea = Subcontracting; Caption = 'Variant Code'; ToolTip = 'Specifies a filter on the transferred item variant.'; }
                }
            }
        }
        trigger OnOpenPage()
        begin
            LoadProposalContext();
            IncludeComponents := true;
            IncludeWIP := true;
            RequestShown := true;
        end;
    }

    trigger OnPreReport()
    var
        ProductionLine: Record "Prod. Order Line";
        RoutingLine: Record "Prod. Order Routing Line";
        CreatedLines: Integer;
        PreviousLineID: Guid;
    begin
        CreatedOrders := 0;
        if not RequestShown then
            Error(RequestRequiredErr);
        LoadProposalContext();
        ProposalMgt.Configure(false, IncludeComponents, IncludeWIP, false, OrderFilter, LineFilter, OperationFilter, WorkCenterFilter, ItemFilter, VariantFilter);
        CollectProposal();
        if not ProposalMgt.SelectRows(CurrentProposal) then
            CurrReport.Quit();
        "Purchase Header".LockTable();
        LoadProposalContext();
        ProposalMgt.LockSources(CurrentProposal);
        ProposalMgt.ClearRows();
        CollectProposal();
        ProposalMgt.Revalidate(CurrentProposal);
        if CurrentProposal.IsEmpty() then
            CurrReport.Quit();
        ApplyingProposal := true;
        if CurrentProposal.FindSet() then
            repeat
                "Purchase Line".Get("Purchase Line"."Document Type"::Order, PurchOrderNo, CurrentProposal."Purchase Line No.");
                PreviousLineID := TransferLine.SystemId;
                if CurrentProposal."WIP Item" then begin
                    ProductionLine.Get(ProductionLine.Status::Released, CurrentProposal."Production Order No.", CurrentProposal."Production Order Line No.");
                    RoutingLine.Get(RoutingLine.Status::Released, CurrentProposal."Production Order No.", CurrentProposal."Routing Reference No.", CurrentProposal."Routing No.", CurrentProposal."Operation No.");
                    InsertTransferHeader(CurrentProposal."Transfer-from Code");
                    InsertWIPTransferLine("Purchase Line", ProductionLine, RoutingLine, CurrentProposal."Quantity to Transfer", CurrentProposal."Previous Operation No.");
                end else
                    HandleComponentsForPurchLine("Purchase Line", true);
                if TransferLine.SystemId <> PreviousLineID then begin
                    CreatedLines += 1;
                end else
                    Error(QuantityChangedErr);
            until CurrentProposal.Next() = 0;
        ProposalMgt.ShowResult(CreatedOrders, CreatedLines);
        ShowDocument();
        CurrReport.Quit();
    end;

    local procedure LoadProposalContext()
    var
        CurrentLocation: Code[10];
    begin
        if ("Purchase Header".GetRangeMin("Document Type") <> "Purchase Header"."Document Type"::Order) or
           ("Purchase Header".GetRangeMax("Document Type") <> "Purchase Header"."Document Type"::Order)
        then
            Error(WarningToSpecifyPurchOrderErr);
        PurchOrderNo := "Purchase Header".GetRangeMin("No.");
        if (PurchOrderNo = '') or (PurchOrderNo <> "Purchase Header".GetRangeMax("No.")) then
            Error(WarningToSpecifyPurchOrderErr);
        "Purchase Header".Get("Purchase Header"."Document Type"::Order, PurchOrderNo);
        "Purchase Header".CalcFields("Subc. Order");
        if not "Purchase Header"."Subc. Order" then
            Error(OrderNoIsNotSubcontractorErr, PurchOrderNo);
        Vendor.Get("Purchase Header"."Buy-from Vendor No.");
        GetTransferToLocationCode(CurrentLocation);
        if RequestShown and ((ContextVendorNo <> Vendor."No.") or (ContextLocation <> CurrentLocation)) then
            Error(ContextChangedErr);
        ContextVendorNo := Vendor."No.";
        ContextLocation := CurrentLocation;
    end;

    local procedure CollectProposal()
    var
        Line: Record "Purchase Line";
    begin
        CollectingProposal := true;
        Line.SetRange("Document Type", Line."Document Type"::Order);
        Line.SetRange("Document No.", PurchOrderNo);
        Line.SetFilter("Prod. Order No.", '<>%1', '');
        Line.SetFilter("Operation No.", '<>%1', '');
        OnCheckTransferCreatedOnAfterPurchaseLineSetFilters(Line, "Purchase Header");
        if Line.FindSet() then
            repeat
                HandleComponentsForPurchLine(Line, false);
                HandleWIPTransferForPurchLine(Line, false);
            until Line.Next() = 0;
        CollectingProposal := false;
    end;

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
        CurrentProposal: Record "Subc. Transfer Proposal" temporary;
        ProposalMgt: Codeunit "Subc. Transfer Proposal Mgt.";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        CollectingProposal: Boolean;
        ApplyingProposal: Boolean;
        CreatedOrders: Integer;
        IncludeComponents: Boolean;
        IncludeWIP: Boolean;
        RequestShown: Boolean;
        ContextVendorNo: Code[20];
        ContextLocation: Code[10];
        OrderFilter: Text;
        LineFilter: Text;
        OperationFilter: Text;
        WorkCenterFilter: Text;
        ItemFilter: Text;
        VariantFilter: Text;
        RequestRequiredErr: Label 'Open the request page before creating a subcontracting transfer.';
        ContextChangedErr: Label 'The subcontracting order context has changed. Close the proposal and calculate it again.';
        QuantityChangedErr: Label 'The available quantity has changed. Close the proposal and calculate it again.';
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Vendor: Record Vendor;
        HasCoveredDemand: Boolean;
        PurchOrderNo: Code[20];
        LineNo: Integer;
        ExcessReservationsErr: Label 'The transfer quantity (%1) is less than the reserved quantity (%2) on the production order component for item %3. Cancel existing reservations on the component before creating a partial transfer.', Comment = '%1=Transfer Quantity, %2=Reserved Quantity, %3=Item No.';
        NothingToCreateErr: Label 'Nothing to create. No components or WIP to transfer for the specified subcontracting order.';
        OrderNoDoesNotExistInProdOrderErr: Label 'Operation %1 in the subcontracting order %2 does not exist in the routing %3 of the production order %4.', Comment = '%1=Operation No., %2=Purchase Order No., %3=Routing No., %4=Production Order No.';
        OrderNoIsNotSubcontractorErr: Label 'Order %1 is not a Subcontractor work.', Comment = '%1=Purchase Order No.';
        WarningToSpecifyPurchOrderErr: Label 'Warning. Specify a Purchase Order No. for the Subcontractor work.';

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
            CreatedOrders += 1;
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
    begin
        HasCoveredDemand := false;
        PurchaseLine.SetCurrentKey("Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchaseLine.SetRange("Document No.", PurchOrderNo);
        PurchaseLine.SetFilter("Prod. Order No.", '<>''''');
        PurchaseLine.SetFilter("Prod. Order Line No.", '<>0');
        PurchaseLine.SetFilter("Operation No.", '<>0');
        OnCheckTransferCreatedOnAfterPurchaseLineSetFilters(PurchaseLine, "Purchase Header");
        if PurchaseLine.FindSet() then
            repeat
                if HandleComponentsForPurchLine(PurchaseLine, false) then
                    exit(true);
                if HandleWIPTransferForPurchLine(PurchaseLine, false) then
                    exit(true);
            until PurchaseLine.Next() = 0;

        exit(false);
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
        if ApplyingProposal then
            ProdOrderComponent.SetRange("Line No.", CurrentProposal."Component Line No.");
        if ProdOrderComponent.FindSet() then
            repeat
                Item.SetLoadFields("Rounding Precision", "Order Tracking Policy");
                Item.Get(ProdOrderComponent."Item No.");
                QtyToPost := MfgCostCalculationMgt.CalcActNeededQtyBase(ProdOrderLine, ProdOrderComponent, Round(PurchaseLine.Quantity * QtyPerUom, UnitofMeasureManagement.QtyRndPrecision()));
                ProdOrderComponent.CalcFields("Subc. Qty.on TransOrder (Base)", "Subc. Qty. in Transit (Base)", "Subc. Qty. transf. to Subcontr");
                if ApplyingProposal then
                    if CurrentProposal."Quantity to Transfer" >
                       Round((QtyToPost - ProdOrderComponent."Subc. Qty.on TransOrder (Base)" -
                           ProdOrderComponent."Subc. Qty. in Transit (Base)" -
                           Abs(ProdOrderComponent."Subc. Qty. transf. to Subcontr")) /
                           ProdOrderComponent."Qty. per Unit of Measure", Item."Rounding Precision", '>')
                    then
                        Error(QuantityChangedErr);
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

                        if ApplyingProposal then
                            TransferLine.Validate(Quantity, CurrentProposal."Quantity to Transfer")
                        else
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
                        if CollectingProposal then begin
                            TransferFromLocationCode := GetTransferFromLocationForComponent(ProdOrderComponent);
                            ProposalMgt.AddComponent(PurchaseLine, ProdOrderComponent, TransferFromLocationCode, ContextLocation,
                                QtyToPost - ProdOrderComponent."Subc. Qty.on TransOrder (Base)" - ProdOrderComponent."Subc. Qty. in Transit (Base)" -
                                Abs(ProdOrderComponent."Subc. Qty. transf. to Subcontr"), ProdOrderComponent."Subc. Qty.on TransOrder (Base)");
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
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        UOMManagement: Codeunit "Unit of Measure Management";
        TransferFromLoc: Code[10];
        TransferToLocCode: Code[10];
        WIPPreviousOperationNo: Code[10];
        PostedWIPQtyBase: Decimal;
        PurchLineQtyBase: Decimal;
        QtyPerPurchUom: Decimal;
        WIPQtyBase: Decimal;
        WIPQtyInUOM: Decimal;
        WIPPreviousOperationNoDict: Dictionary of [Code[10], Code[10]];
        WIPSourceQtyDict: Dictionary of [Code[10], Decimal];
        WIPSourceLocationList: List of [Code[10]];
        OpenWIPLineQtyBase: Decimal;
    begin
        if not ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.") then
            exit(false);

        if not ProdOrderRoutingLine."Transfer WIP Item" then
            exit(false);

        if not CheckCreateWIPTransfer(PurchaseLine, OpenWIPLineQtyBase) then
            exit(false);

        PurchLineQtyBase := CalcPurchLineQtyBase(PurchaseLine, ProdOrderLine);

        if CollectingProposal and (ProdOrderRoutingLine."Previous Operation No." <> '') then
            if CollectPreviousWIPSources(PurchaseLine, ProdOrderLine, ProdOrderRoutingLine, PurchLineQtyBase, OpenWIPLineQtyBase) then
                exit(false);

        GetWIPTransferFromLocations(ProdOrderLine, ProdOrderRoutingLine, WIPSourceLocationList, WIPSourceQtyDict, WIPPreviousOperationNoDict, PurchLineQtyBase);

        if WIPSourceLocationList.Count() = 0 then
            exit(false);

        if not InsertLine and not CollectingProposal then
            exit(true);

        if WIPSourceLocationList.Count() = 1 then begin
            GetTransferToLocationCodeForPurchaseHeader("Purchase Header", Vendor, TransferToLocCode);
            PostedWIPQtyBase := GetWIPQtyBase(PurchaseLine, TransferToLocCode) + OpenWIPLineQtyBase;
        end;

        Item.SetLoadFields("Base Unit of Measure");
        Item.Get(ProdOrderLine."Item No.");
        QtyPerPurchUom := UOMManagement.GetQtyPerUnitOfMeasure(Item, PurchaseLine."Unit of Measure Code");

        foreach TransferFromLoc in WIPSourceLocationList do begin
            WIPQtyBase := WIPSourceQtyDict.Get(TransferFromLoc);
            WIPPreviousOperationNoDict.Get(TransferFromLoc, WIPPreviousOperationNo);
            if WIPSourceLocationList.Count() = 1 then
                if WIPQtyBase > PurchLineQtyBase - PostedWIPQtyBase then
                    WIPQtyBase := PurchLineQtyBase - PostedWIPQtyBase;
            if QtyPerPurchUom <> 0 then
                WIPQtyInUOM := Round(WIPQtyBase / QtyPerPurchUom, UOMManagement.QtyRndPrecision())
            else
                WIPQtyInUOM := Round(WIPQtyBase, UOMManagement.QtyRndPrecision());
            if (WIPQtyInUOM > 0) and CollectingProposal then
                ProposalMgt.AddWIP(PurchaseLine, ProdOrderLine, TransferFromLoc, ContextLocation, WIPPreviousOperationNo, WIPQtyBase, PurchaseLine."Unit of Measure Code");
            if (WIPQtyInUOM > 0) and InsertLine then begin
                InsertTransferHeader(TransferFromLoc);
                InsertWIPTransferLine(PurchaseLine, ProdOrderLine, ProdOrderRoutingLine, WIPQtyInUOM, WIPPreviousOperationNo);
            end;
        end;

        exit(false);
    end;

    local procedure InsertWIPTransferLine(PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WIPQty: Decimal; WIPPreviousOperationNo: Code[10])
    begin
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
        if ApplyingProposal then begin
            TransferLine."Subc. WIP State" := CurrentProposal."WIP State";
            TransferLine."Subc. Source Position No." := CurrentProposal."Source Position No.";
            TransferLine."Subc. Supply Lot ID" := CurrentProposal."Supply Lot ID";
        end;

        TransferLine.Modify();

        OnAfterInsertWIPTransferLine(TransferHeader, TransferLine, PurchaseLine, ProdOrderLine, ProdOrderRoutingLine);
    end;

    local procedure CollectPreviousWIPSources(PurchaseLine: Record "Purchase Line"; ProductionLine: Record "Prod. Order Line"; RoutingLine: Record "Prod. Order Routing Line"; QuantityBase: Decimal; OpenQuantityBase: Decimal): Boolean
    var
        PreviousRouting: Record "Prod. Order Routing Line";
        FromLocation: Code[10];
        ToLocation: Code[10];
        SourceQuantityBase: Decimal;
        RemainingBase: Decimal;
        BeforeBase: Decimal;
    begin
        PreviousRouting.SetRange(Status, RoutingLine.Status);
        PreviousRouting.SetRange("Prod. Order No.", RoutingLine."Prod. Order No.");
        PreviousRouting.SetRange("Routing Reference No.", RoutingLine."Routing Reference No.");
        PreviousRouting.SetRange("Routing No.", RoutingLine."Routing No.");
        PreviousRouting.SetFilter("Operation No.", RoutingLine."Previous Operation No.");
        if not PreviousRouting.FindSet() then
            exit(false);
        GetTransferToLocationCodeForPurchaseHeader("Purchase Header", Vendor, ToLocation);
        RemainingBase := QuantityBase - GetWIPQtyBase(PurchaseLine, ToLocation) - OpenQuantityBase;
        repeat
            GetWIPLocationAndQtyForPreviousOp(ProductionLine, PreviousRouting, RoutingLine.IsSerial(), QuantityBase, FromLocation, SourceQuantityBase);
            if SourceQuantityBase > RemainingBase then
                SourceQuantityBase := RemainingBase;
            BeforeBase := ProposalMgt.ProposedWIPBase(PurchaseLine);
            ProposalMgt.AddWIP(PurchaseLine, ProductionLine, FromLocation, ToLocation,
                PreviousRouting."Operation No.", SourceQuantityBase, PurchaseLine."Unit of Measure Code");
            RemainingBase -= ProposalMgt.ProposedWIPBase(PurchaseLine) - BeforeBase;
        until (PreviousRouting.Next() = 0) or (RemainingBase <= 0);
        exit(true);
    end;

    local procedure GetWIPTransferFromLocations(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var WIPSourceLocationList: List of [Code[10]]; var WIPSourceQtyDict: Dictionary of [Code[10], Decimal]; var WIPPreviousOperationNoDict: Dictionary of [Code[10], Code[10]]; PurchLineQtyBase: Decimal)
    var
        PrevProdOrderRoutingLine: Record "Prod. Order Routing Line";
        LocCode: Code[10];
        WIPQtyBase: Decimal;
        IsSerial, TransferWIPItem, FoundSubcontractingPrevOp : Boolean;
        WIPItemTransferDifferentErr: Label 'Field ''''%1'''' must have the same value for all previous operations of the routing.', Comment = '%1=Transfer WIP Item';
    begin
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
        PrevVendor: Record Vendor;
        PrevWorkCenter: Record "Work Center";
    begin
        LocationCode := ProdOrderLine."Location Code";
        WIPQtyBase := PurchLineQtyBase;

        if PrevProdOrderRoutingLine."Transfer WIP Item" then begin
            // Previous op has a subcontracting WIP transfer
            PrevWorkCenter.SetLoadFields("Subcontractor No.");
            if PrevWorkCenter.Get(PrevProdOrderRoutingLine."Work Center No.") then
                if PrevWorkCenter."Subcontractor No." <> '' then begin
                    PrevVendor.SetLoadFields("Subc. Location Code");
                    if PrevVendor.Get(PrevWorkCenter."Subcontractor No.") then
                        if PrevVendor."Subc. Location Code" <> '' then
                            LocationCode := PrevVendor."Subc. Location Code";
                end;

            if LocationCode <> '' then begin
                WIPLedgerEntry.SetRange("Prod. Order Status", "Production Order Status"::Released);
                WIPLedgerEntry.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                WIPLedgerEntry.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                WIPLedgerEntry.SetRange("Routing No.", PrevProdOrderRoutingLine."Routing No.");
                WIPLedgerEntry.SetRange("Routing Reference No.", PrevProdOrderRoutingLine."Routing Reference No.");
                WIPLedgerEntry.SetRange("Operation No.", PrevProdOrderRoutingLine."Operation No.");
                WIPLedgerEntry.SetRange("Location Code", LocationCode);
                WIPLedgerEntry.SetRange("In Transit", false);
                CohortMgt.FilterLedger(WIPLedgerEntry, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
                WIPLedgerEntry.CalcSums("Quantity (Base)");
            end;
        end;

        // Parallel routings always use Prod. Order Line quantity as preset
        if IsSerial and (WIPLedgerEntry."Quantity (Base)" <> 0) then
            WIPQtyBase := WIPLedgerEntry."Quantity (Base)";
    end;

    local procedure CheckCreateWIPTransfer(PurchaseLine: Record "Purchase Line"; var OpenWIPLineQtyBase: Decimal): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchaseHeader: Record "Purchase Header";
        VendorFromPurchOrder: Record Vendor;
        LocCode: Code[10];
        PurchLineQtyBase: Decimal;
        TransferToLocationCode: Code[10];
        ExpectedQtyBase: Decimal;
        PostedWIPQtyBase: Decimal;
        WIPPreviousOperationNoDict: Dictionary of [Code[10], Code[10]];
        WIPSourceQtyDict: Dictionary of [Code[10], Decimal];
        WIPSourceLocationList: List of [Code[10]];
    begin
        OpenWIPLineQtyBase := 0;
        if not ProdOrderLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Prod. Order Line No.") then
            exit(false);

        if not ProdOrderRoutingLine.Get("Production Order Status"::Released, PurchaseLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.") then
            exit(false);

        if not ProdOrderRoutingLine."Transfer WIP Item" then
            exit(false);

        PurchLineQtyBase := CalcPurchLineQtyBase(PurchaseLine, ProdOrderLine);

        GetWIPTransferFromLocations(ProdOrderLine, ProdOrderRoutingLine, WIPSourceLocationList, WIPSourceQtyDict, WIPPreviousOperationNoDict, PurchLineQtyBase);

        ExpectedQtyBase := 0;
        foreach LocCode in WIPSourceLocationList do
            ExpectedQtyBase += WIPSourceQtyDict.Get(LocCode);

        if ExpectedQtyBase = 0 then
            exit(false);

        if not PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.") then
            exit(false);

        if not VendorFromPurchOrder.Get(PurchaseHeader."Buy-from Vendor No.") then
            exit(false);

        GetTransferToLocationCodeForPurchaseHeader(PurchaseHeader, VendorFromPurchOrder, TransferToLocationCode);

        if TransferToLocationCode = '' then
            VendorFromPurchOrder.TestField("Subc. Location Code");

        PostedWIPQtyBase := GetWIPQtyBase(PurchaseLine, TransferToLocationCode);
        OpenWIPLineQtyBase := GetOpenWIPTransferLineQtyBase(PurchaseLine, ProdOrderLine);

        if (ExpectedQtyBase > 0) and ((PostedWIPQtyBase + OpenWIPLineQtyBase) >= ExpectedQtyBase) then
            HasCoveredDemand := true;

        exit((PostedWIPQtyBase + OpenWIPLineQtyBase) < ExpectedQtyBase);
    end;

    local procedure GetOpenWIPTransferLineQtyBase(PurchaseLine: Record "Purchase Line"; ProdOrderLine: Record "Prod. Order Line"): Decimal
    var
        TransferLineToCheck: Record "Transfer Line";
        OpenQuantityBase: Decimal;
    begin
        TransferLineToCheck.SetCurrentKey("Subc. Prod. Order No.", "Subc. Prod. Order Line No.", "Subc. Routing Reference No.", "Subc. Routing No.", "Subc. Operation No.");
        TransferLineToCheck.SetRange("Subc. Prod. Order No.", PurchaseLine."Prod. Order No.");
        TransferLineToCheck.SetRange("Subc. Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        TransferLineToCheck.SetRange("Subc. Routing Reference No.", PurchaseLine."Routing Reference No.");
        TransferLineToCheck.SetRange("Subc. Routing No.", PurchaseLine."Routing No.");
        TransferLineToCheck.SetRange("Subc. Operation No.", PurchaseLine."Operation No.");
        TransferLineToCheck.SetRange("Derived From Line No.", 0);
        TransferLineToCheck.SetRange("Transfer WIP Item", true);
        TransferLineToCheck.SetRange("Subc. Return Order", false);
        CohortMgt.FilterTransfers(TransferLineToCheck, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        if TransferLineToCheck.FindSet() then
            repeat
                if TransferLineToCheck.Quantity > TransferLineToCheck."Quantity Shipped" then
                    OpenQuantityBase += TransferLineToCheck.CalcBaseQty(TransferLineToCheck.Quantity - TransferLineToCheck."Quantity Shipped");
            until TransferLineToCheck.Next() = 0;
        exit(OpenQuantityBase);
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
        SubcontractorWIPLedgerEntry.SetRange("Location Code", LocationCode);
        SubcontractorWIPLedgerEntry.SetRange("In Transit", false);
        CohortMgt.FilterLedger(SubcontractorWIPLedgerEntry, "Production Order Status"::Released, PurchaseLine."Prod. Order No.");
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
