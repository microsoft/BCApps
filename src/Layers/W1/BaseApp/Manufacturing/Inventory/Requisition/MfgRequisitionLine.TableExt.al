// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Inventory.Location;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Planning;

tableextension 99000860 "Mfg. Requisition Line" extends "Requisition Line"
{
    fields
    {
        field(5401; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Order"."No." where(Status = const(Released));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateProdOrderOnReqLine(Rec);
                Validate("Unit of Measure Code");
            end;
        }
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";

            trigger OnValidate()
            var
                RoutingHeader: Record "Routing Header";
                RoutingDate: Date;
            begin
                CheckActionMessageNew();
                "Routing Version Code" := '';

                if "Routing No." = '' then
                    exit;

                if CurrFieldNo = FieldNo("Starting Date") then
                    RoutingDate := "Starting Date"
                else
                    RoutingDate := "Ending Date";
                if RoutingDate = 0D then
                    RoutingDate := "Order Date";

                Validate("Routing Version Code", VersionMgt.GetRtngVersion("Routing No.", RoutingDate, true));
                if "Routing Version Code" = '' then begin
                    RoutingHeader.Get("Routing No.");
                    if PlanningResiliency and (RoutingHeader.Status <> RoutingHeader.Status::Certified) then
                        TempPlanningErrorLog.SetError(
                          StrSubstNo(RoutingNotCertifiedErr, RoutingHeader.TableCaption(), RoutingHeader.FieldCaption("No."), RoutingHeader."No."),
                          Database::"Routing Header", CopyStr(RoutingHeader.GetPosition(), 1, 250));
                    RoutingHeader.TestField(Status, RoutingHeader.Status::Certified);
                    "Routing Type" := RoutingHeader.Type;
                end;
            end;
        }
        field(99000751; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Routing No."));

            trigger OnValidate()
            var
                ProdOrderRtngLine: Record "Prod. Order Routing Line";
            begin
                if "Operation No." = '' then
                    exit;

                TestField(Type, Type::Item);
                TestField("Prod. Order No.");
                TestField("Routing No.");

                ProdOrderRtngLine.Get(
                  ProdOrderRtngLine.Status::Released,
                  "Prod. Order No.",
                  "Routing Reference No.",
                  "Routing No.", "Operation No.");

                ProdOrderRtngLine.TestField(
                  Type,
                  ProdOrderRtngLine.Type::"Work Center");

                "Due Date" := ProdOrderRtngLine."Ending Date";
                CheckDueDateToDemandDate();

                Validate("Work Center No.", ProdOrderRtngLine."No.");

                Validate("Direct Unit Cost", ProdOrderRtngLine."Direct Unit Cost");
            end;
        }
        field(99000752; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center";

            trigger OnValidate()
            begin
                GetWorkCenter();
                Validate("Vendor No.", WorkCenter."Subcontractor No.");
            end;
        }
        field(99000754; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Line"."Line No." where(Status = const(Finished),
                                                                 "Prod. Order No." = field("Prod. Order No."));
        }
        field(99000885; "Production BOM Version Code"; Code[20])
        {
            Caption = 'Production BOM Version Code';
            DataClassification = CustomerContent;
            TableRelation = "Production BOM Version"."Version Code" where("Production BOM No." = field("Production BOM No."));

            trigger OnValidate()
            var
                ProdBOMVersion: Record "Production BOM Version";
            begin
                CheckActionMessageNew();
                if "Production BOM Version Code" = '' then
                    exit;

                ProdBOMVersion.Get("Production BOM No.", "Production BOM Version Code");
                if PlanningResiliency and (ProdBOMVersion.Status <> ProdBOMVersion.Status::Certified) then
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(
                        VersionNotCertifiedErr, ProdBOMVersion.TableCaption(),
                        ProdBOMVersion.FieldCaption("Production BOM No."), ProdBOMVersion."Production BOM No.",
                        ProdBOMVersion.FieldCaption("Version Code"), ProdBOMVersion."Version Code"),
                      Database::"Production BOM Version", CopyStr(ProdBOMVersion.GetPosition(), 1, 250));
                ProdBOMVersion.TestField(Status, ProdBOMVersion.Status::Certified);
                OnAfterValidateProductionBOMVersionCode(Rec, xRec, ProdBOMVersion);
            end;
        }
        field(99000886; "Routing Version Code"; Code[20])
        {
            Caption = 'Routing Version Code';
            DataClassification = CustomerContent;
            TableRelation = "Routing Version"."Version Code" where("Routing No." = field("Routing No."));

            trigger OnValidate()
            var
                RoutingVersion: Record "Routing Version";
            begin
                CheckActionMessageNew();
                if "Routing Version Code" = '' then
                    exit;

                RoutingVersion.Get("Routing No.", "Routing Version Code");
                if PlanningResiliency and (RoutingVersion.Status <> RoutingVersion.Status::Certified) then
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(
                        VersionNotCertifiedErr, RoutingVersion.TableCaption(),
                        RoutingVersion.FieldCaption("Routing No."), RoutingVersion."Routing No.",
                        RoutingVersion.FieldCaption("Version Code"), RoutingVersion."Version Code"),
                      Database::"Routing Version", CopyStr(RoutingVersion.GetPosition(), 1, 250));
                RoutingVersion.TestField(Status, RoutingVersion.Status::Certified);
                "Routing Type" := RoutingVersion.Type;
            end;
        }
        field(99000887; "Routing Type"; Option)
        {
            Caption = 'Routing Type';
            DataClassification = CustomerContent;
            OptionCaption = 'Serial,Parallel';
            OptionMembers = Serial,Parallel;
        }
        field(99000892; "Scrap %"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Scrap %';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(99000898; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            DataClassification = CustomerContent;
            TableRelation = "Production BOM Header"."No.";

            trigger OnValidate()
            var
                ProdBOMHeader: Record "Production BOM Header";
                BOMDate: Date;
            begin
                TestField(Type, Type::Item);
                CheckActionMessageNew();
                "Production BOM Version Code" := '';
                if "Production BOM No." = '' then
                    exit;

                if CurrFieldNo = FieldNo("Starting Date") then
                    BOMDate := "Starting Date"
                else begin
                    BOMDate := "Ending Date";
                    if BOMDate = 0D then
                        BOMDate := "Order Date";
                end;

                Validate("Production BOM Version Code", VersionMgt.GetBOMVersion("Production BOM No.", BOMDate, true));
                if "Production BOM Version Code" = '' then begin
                    ProdBOMHeader.Get("Production BOM No.");
                    if PlanningResiliency and (ProdBOMHeader.Status <> ProdBOMHeader.Status::Certified) then
                        TempPlanningErrorLog.SetError(
                          StrSubstNo(RoutingNotCertifiedErr, ProdBOMHeader.TableCaption(), ProdBOMHeader.FieldCaption("No."), ProdBOMHeader."No."),
                          Database::"Production BOM Header", CopyStr(ProdBOMHeader.GetPosition(), 1, 250));
                    ProdBOMHeader.TestField(Status, ProdBOMHeader.Status::Certified);
                end;
                OnAfterValidateProductionBOMNo(Rec, xRec, ProdBOMHeader);
            end;
        }
#pragma warning disable AA0232
        field(99000909; "Expected Operation Cost Amt."; Decimal)
#pragma warning restore AA0232
        {
            AutoFormatType = 1;
            CalcFormula = sum("Planning Routing Line"."Expected Operation Cost Amt." where("Worksheet Template Name" = field("Worksheet Template Name"),
                                                                                            "Worksheet Batch Name" = field("Journal Batch Name"),
                                                                                            "Worksheet Line No." = field("Line No.")));
            Caption = 'Expected Operation Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        modify("Ref. Order No.")
        {
#pragma warning disable AL0603
            TableRelation = if ("Ref. Order Type" = const("Prod. Order")) "Production Order"."No." where(Status = field("Ref. Order Status"));
#pragma warning restore AL0603
        }
    }

    var
        ManufacturingSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        VersionMgt: Codeunit VersionManagement;

        ReplenishmentErr: Label 'Requisition Worksheet cannot be used to create Prod. Order replenishment.';
        RoutingNotCertifiedErr: Label '%1 %2 %3 is not certified.', Comment = '%1 %2 %3 - routing fields';
        VersionNotCertifiedErr: Label '%1 %2 %3 %4 %5 is not certified.', Comment = '%1 %2 %3 %4 %5 - version fields';

    /// <summary>
    /// Prepares and transfers relevant field values from provided production order line to the current requisition line.
    /// </summary>
    /// <param name="ProdOrderLine">Source production order line record. </param>
    /// <remarks>In case no production order is found for the provided 'ProdOrderLine', error will be invoked. </remarks>
    procedure GetProdOrderLine(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrder: Record "Production Order";
    begin
        ProdOrderLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        ProdOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        Item.Get(ProdOrderLine."Item No.");

        TransferFromProdOrderLine(ProdOrderLine);
    end;

    /// <summary>
    /// Populates fields of the current requisition line based on reservation entry related to the provided action message entry. 
    /// </summary>
    /// <param name="ActionMessageEntry">Provided action message entry record. </param>
    procedure TransferFromProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrder: Record "Production Order";
    begin
        ProdOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");

        Type := Type::Item;
        "No." := ProdOrderLine."Item No.";
        "Variant Code" := ProdOrderLine."Variant Code";
        Description := ProdOrderLine.Description;
        "Description 2" := ProdOrderLine."Description 2";
        "Location Code" := ProdOrderLine."Location Code";
        "Dimension Set ID" := ProdOrderLine."Dimension Set ID";
        "Shortcut Dimension 1 Code" := ProdOrderLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ProdOrderLine."Shortcut Dimension 2 Code";
        "Bin Code" := ProdOrderLine."Bin Code";
        "Gen. Prod. Posting Group" := ProdOrder."Gen. Prod. Posting Group";
        "Gen. Business Posting Group" := ProdOrder."Gen. Bus. Posting Group";
        "Scrap %" := ProdOrderLine."Scrap %";
        "Order Date" := ProdOrder."Creation Date";
        "Starting Time" := ProdOrderLine."Starting Time";
        "Starting Date" := ProdOrderLine."Starting Date";
        "Ending Time" := ProdOrderLine."Ending Time";
        "Ending Date" := ProdOrderLine."Ending Date";
        "Due Date" := ProdOrderLine."Due Date";
        "Production BOM No." := ProdOrderLine."Production BOM No.";
        "Routing No." := ProdOrderLine."Routing No.";
        "Production BOM Version Code" := ProdOrderLine."Production BOM Version Code";
        "Routing Version Code" := ProdOrderLine."Routing Version Code";
        "Routing Type" := ProdOrderLine."Routing Type";
        "Replenishment System" := "Replenishment System"::"Prod. Order";
        Quantity := ProdOrderLine.Quantity;
        "Finished Quantity" := ProdOrderLine."Finished Quantity";
        "Remaining Quantity" := ProdOrderLine."Remaining Quantity";
        "Unit Cost" := ProdOrderLine."Unit Cost";
        "Cost Amount" := ProdOrderLine."Cost Amount";
        "Low-Level Code" := ProdOrder."Low-Level Code";
        "Planning Level" := ProdOrderLine."Planning Level Code";
        "Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        "Qty. per Unit of Measure" := ProdOrderLine."Qty. per Unit of Measure";
        "Quantity (Base)" := ProdOrderLine."Quantity (Base)";
        "Finished Qty. (Base)" := ProdOrderLine."Finished Qty. (Base)";
        "Remaining Qty. (Base)" := ProdOrderLine."Remaining Qty. (Base)";
        "Indirect Cost %" := ProdOrderLine."Indirect Cost %";
        "Overhead Rate" := ProdOrderLine."Overhead Rate";
        "Expected Operation Cost Amt." := ProdOrderLine."Expected Operation Cost Amt.";
        "Expected Component Cost Amt." := ProdOrderLine."Expected Component Cost Amt.";
        "MPS Order" := ProdOrderLine."MPS Order";
        "Planning Flexibility" := ProdOrderLine."Planning Flexibility";
        "Ref. Order No." := ProdOrderLine."Prod. Order No.";
        "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
        "Ref. Order Status" := ProdOrderLine.Status;
        "Ref. Line No." := ProdOrderLine."Line No.";

        OnAfterTransferFromProdOrderLine(Rec, ProdOrderLine);

        GetDimFromRefOrderLine(false);
    end;

    procedure GetWorkCenter()
    begin
        if WorkCenter."No." = "Work Center No." then
            exit;

        Clear(WorkCenter);
        if WorkCenter.Get("Work Center No.") then
            SetSubcontracting(WorkCenter."Subcontractor No." <> '')
        else
            SetSubcontracting(false);
    end;

    procedure RoutingLineExists(): Boolean
    var
        RoutingLine: Record "Routing Line";
    begin
        if "Routing No." <> '' then begin
            RoutingLine.SetRange("Routing No.", "Routing No.");
            exit(not RoutingLine.IsEmpty);
        end;

        exit(false);
    end;

    procedure SetReplenishmentSystemFromProdOrder(StockkeepingUnit: Record "Stockkeeping Unit")
    var
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
        ProductionBOMNo: Code[20];
        RoutingNo: Code[20];
    begin
        OnBeforeSetReplenishmentSystemFromProdOrder(Rec);

        CheckReqWkshTemplate();

        if PlanningResiliency and (Item."Base Unit of Measure" = '') then
            TempPlanningErrorLog.SetError(
              StrSubstNo(MissingFieldValueErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Base Unit of Measure")),
              Database::Item, CopyStr(Item.GetPosition(), 1, 250));

        Item.TestField("Base Unit of Measure");
        IsHandled := false;
        OnSetReplenishmentSystemFromProdOrderOnBeforeProcessPlannedOrderNosField(Rec, IsHandled, xRec);
        if not IsHandled then
            if "Ref. Order No." = '' then begin
                "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
                "Ref. Order Status" := "Ref. Order Status"::Planned;
                ManufacturingSetup.Get();
                if PlanningResiliency and (ManufacturingSetup."Planned Order Nos." = '') then
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(MissingFieldValueErr, ManufacturingSetup.TableCaption(), '',
                        ManufacturingSetup.FieldCaption("Planned Order Nos.")),
                      Database::"Manufacturing Setup", CopyStr(ManufacturingSetup.GetPosition(), 1, 250));
                ManufacturingSetup.TestField("Planned Order Nos.");
                if PlanningResiliency then
                    NoSeries.PeekNextNo(ManufacturingSetup."Planned Order Nos.", "Due Date");
                if not Subcontracting then begin
                    if NoSeries.AreRelated(ManufacturingSetup."Planned Order Nos.", xRec."No. Series") then
                        "No. Series" := xRec."No. Series"
                    else
                        "No. Series" := ManufacturingSetup."Planned Order Nos.";
                    "Ref. Order No." := NoSeries.GetNextNo("No. Series", "Due Date");
                end;
            end;
        Validate("Vendor No.", '');

        IsHandled := false;
        OnSetReplenishmentSystemFromProdOrderOnBeforeAssignProdFields(Rec, IsHandled);
        if not IsHandled then begin
            // If needed field is '' on SKU, then fall back to values from Item
            if StockkeepingUnit."Production BOM No." <> '' then
                ProductionBOMNo := StockkeepingUnit."Production BOM No."
            else
                ProductionBOMNo := Item."Production BOM No.";

            if StockkeepingUnit."Routing No." <> '' then
                RoutingNo := StockkeepingUnit."Routing No."
            else
                RoutingNo := Item."Routing No.";

            if not Subcontracting then begin
                OnSetReplenishmentSystemFromProdOrderOnBeforeSetProdFields(
                    Rec, Item, Subcontracting, PlanningResiliency, TempPlanningErrorLog);

                // Get SKU and use that. If needed field is '' on SKU, then fall back to values from Item 
                Validate("Production BOM No.", ProductionBOMNo);
                Validate("Routing No.", RoutingNo);
            end else begin
                "Production BOM No." := ProductionBOMNo;
                "Routing No." := RoutingNo;
            end;
        end;

        OnSetReplenishmentSystemFromProdOrderOnAfterSetProdFields(Rec, Item, Subcontracting);

        Validate("Transfer-from Code", '');
        UpdateUnitOfMeasureCodeFromItemBaseUnitOfMeasure();

        if ("Planning Line Origin" = "Planning Line Origin"::"Order Planning") and ValidateFields() then
            PlanningLineMgt.Calculate(Rec, 1, true, true, 0);

        OnAfterSetReplenishmentSystemFromProdOrder(Rec, Item);
    end;

    local procedure CheckReqWkshTemplate()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckReqWkshTmpl(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        if ReqWkshTemplate.Get("Worksheet Template Name") and
           (ReqWkshTemplate.Type = ReqWkshTemplate.Type::"Req.") and (ReqWkshTemplate.Name <> '') and not "Drop Shipment"
        then
            Error(ReplenishmentErr);
    end;

    procedure UpdateWorkCenterDescription(): Boolean
    var
        WorkCenterForDescription: Record "Work Center";
    begin
        if ("Ref. Order Type" <> "Ref. Order Type"::"Prod. Order") or ("Work Center No." = '') then
            exit(false);

        WorkCenterForDescription.SetLoadFields(Name, "Name 2", "Subcontractor No.");
        WorkCenterForDescription.Get("Work Center No.");

        if WorkCenterForDescription."Subcontractor No." = '' then
            exit(false);

        Description := WorkCenterForDescription.Name;
        "Description 2" := WorkCenterForDescription."Name 2";

        exit(true);
    end;

    procedure ValidateProdOrderOnReqLine(var ReqLine: Record "Requisition Line")
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ReqLine.TestField(Type, ReqLine.Type::Item);

        if ProdOrder.Get(ProdOrder.Status::Released, ReqLine."Prod. Order No.") then begin
            ProdOrder.TestField(Blocked, false);
            ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
            ProdOrderLine.SetRange("Prod. Order No.", ReqLine."Prod. Order No.");
            ProdOrderLine.SetRange("Item No.", ReqLine."No.");
            if ProdOrderLine.FindFirst() then begin
                ReqLine."Routing No." := ProdOrderLine."Routing No.";
                ReqLine."Routing Reference No." := ProdOrderLine."Line No.";
                ReqLine."Prod. Order Line No." := ProdOrderLine."Line No.";
                ReqLine."Requester ID" := CopyStr(UserId(), 1, MaxStrLen(ReqLine."Requester ID"));
            end;
            Item.Get(ReqLine."No.");
            ReqLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdOrderLine(var ReqLine: Record "Requisition Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateProductionBOMNo(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; ProductionBOMHeader: Record "Production BOM Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateProductionBOMVersionCode(var RequisitionLine: Record "Requisition Line"; xRequisitionLine: Record "Requisition Line"; ProductionBOMVersion: Record "Production BOM Version")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReplenishmentSystemFromProdOrder(var RequisitionLine: Record "Requisition Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetReplenishmentSystemFromProdOrderOnAfterSetProdFields(var RequisitionLine: Record "Requisition Line"; Item: Record Item; Subcontracting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetReplenishmentSystemFromProdOrderOnBeforeSetProdFields(var RequisitionLine: Record "Requisition Line"; Item: Record Item; Subcontracting: Boolean; PlanningResiliency: Boolean; var TempPlanningErrorLog: Record "Planning Error Log")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetReplenishmentSystemFromProdOrderOnBeforeProcessPlannedOrderNosField(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean; xRequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetReplenishmentSystemFromProdOrderOnBeforeAssignProdFields(var RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReqWkshTmpl(var RequisitionLine: Record "Requisition Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetReplenishmentSystemFromProdOrder(var RequisitionLine: Record "Requisition Line")
    begin
    end;
}