// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

codeunit 99000809 "Planning Line Management"
{
#if not CLEAN28
    Permissions = TableData Microsoft.Manufacturing.Setup."Manufacturing Setup" = rm,
                  TableData Microsoft.Manufacturing.Routing."Routing Header" = r,
                  TableData Microsoft.Manufacturing.ProductionBOM."Production BOM Header" = r,
                  TableData Microsoft.Manufacturing.ProductionBOM."Production BOM Line" = r,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Capacity Need" = rd,
                  TableData "Planning Component" = rimd,
                  TableData Microsoft.Manufacturing.Routing."Planning Routing Line" = rimd;
#else
    Permissions = tabledata "Planning Component" = rimd;
#endif

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ReqLine: Record "Requisition Line";
        AsmBOMComp: array[50] of Record "BOM Component";
        PlanningComponent: Record "Planning Component";
        TempPlanningComponent: Record "Planning Component" temporary;
        TempPlanningErrorLog: Record "Planning Error Log" temporary;
        UOMMgt: Codeunit "Unit of Measure Management";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        LeadTimeMgt: Codeunit "Lead-Time Management";

        LineSpacing: array[50] of Integer;
        NextPlanningCompLineNo: Integer;
        Blocked: Boolean;
        PlanningResiliency: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'BOM phantom structure for %1 is higher than 50 levels.';
        Text002: Label 'There is not enough space to insert lower level Make-to-Order lines.';
        Text014: Label 'Production BOM Header No. %1 used by Item %2 has BOM levels that exceed 50.';
        Text015: Label 'There is no more space to insert another line in the worksheet.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure TransferAsmBOM(ParentItemNo: Code[20]; Level: Integer; Quantity: Decimal)
    var
        ParentItem: Record Item;
        CompSKU: Record "Stockkeeping Unit";
        Item2: Record Item;
        ReqQty: Decimal;
    begin
        PlanningComponent.LockTable();

        if Level > 50 then begin
            if PlanningResiliency then begin
                Item.Get(ReqLine."No.");
                TempPlanningErrorLog.SetError(
                  StrSubstNo(Text014, ReqLine."No.", ReqLine."No."),
                  Database::Item, Item.GetPosition());
            end;
            Error(
              Text000,
              ParentItemNo);
        end;

        if NextPlanningCompLineNo = 0 then begin
            PlanningComponent.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
            PlanningComponent.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
            PlanningComponent.SetRange("Worksheet Line No.", ReqLine."Line No.");
            if PlanningComponent.Find('+') then
                NextPlanningCompLineNo := PlanningComponent."Line No.";
            PlanningComponent.Reset();
        end;

        ParentItem.Get(ParentItemNo);

        AsmBOMComp[Level].SetRange("Parent Item No.", ParentItemNo);
        if AsmBOMComp[Level].Find('-') then
            repeat
                ReqQty := Quantity * AsmBOMComp[Level]."Quantity per";
                case AsmBOMComp[Level].Type of
                    AsmBOMComp[Level].Type::Item:
                        if ReqQty <> 0 then begin
                            if not IsPlannedAsmComp(PlanningComponent, ReqLine, AsmBOMComp[Level]) then begin
                                NextPlanningCompLineNo := NextPlanningCompLineNo + 10000;

                                PlanningComponent.Reset();
                                PlanningComponent.Init();
                                PlanningComponent.BlockDynamicTracking(Blocked);
                                PlanningComponent.SetRequisitionLine(ReqLine);
                                PlanningComponent."Worksheet Template Name" := ReqLine."Worksheet Template Name";
                                PlanningComponent."Worksheet Batch Name" := ReqLine."Journal Batch Name";
                                PlanningComponent."Worksheet Line No." := ReqLine."Line No.";
                                PlanningComponent."Line No." := NextPlanningCompLineNo;
                                PlanningComponent.Validate("Item No.", AsmBOMComp[Level]."No.");
                                PlanningComponent."Variant Code" := AsmBOMComp[Level]."Variant Code";
                                PlanningComponent."Location Code" := SKU."Components at Location";
                                PlanningComponent.Description := CopyStr(AsmBOMComp[Level].Description, 1, MaxStrLen(PlanningComponent.Description));
                                PlanningComponent."Planning Line Origin" := ReqLine."Planning Line Origin";
                                PlanningComponent.Validate("Unit of Measure Code", AsmBOMComp[Level]."Unit of Measure Code");
                                PlanningComponent."Quantity per" := Quantity * AsmBOMComp[Level]."Quantity per";
                                OnTransferAsmBOMOnBeforeGetDefaultBin(PlanningComponent, AsmBOMComp[Level], ReqLine);
                                PlanningComponent.GetDefaultBin();
                                PlanningComponent.Quantity := AsmBOMComp[Level]."Quantity per";
                                PlanningComponent.Position := AsmBOMComp[Level].Position;
                                PlanningComponent."Position 2" := AsmBOMComp[Level]."Position 2";
                                PlanningComponent."Position 3" := AsmBOMComp[Level]."Position 3";
                                PlanningComponent."Lead-Time Offset" := AsmBOMComp[Level]."Lead-Time Offset";
                                OnTransferASMBOMOnAfterSetAsmBOMComp(PlanningComponent);
                                PlanningComponent.Validate("Calculation Formula", PlanningComponent."Calculation Formula"::" ");
                                GetPlanningParameters.AtSKU(
                                  CompSKU,
                                  PlanningComponent."Item No.",
                                  PlanningComponent."Variant Code",
                                  PlanningComponent."Location Code");
                                if Item2.Get(PlanningComponent."Item No.") then
                                    PlanningComponent.Critical := Item2.Critical;

                                PlanningComponent."Flushing Method" := CompSKU."Flushing Method";
                                PlanningComponent."Ref. Order Type" := ReqLine."Ref. Order Type";
                                PlanningComponent."Ref. Order Status" := ReqLine."Ref. Order Status";
                                PlanningComponent."Ref. Order No." := ReqLine."Ref. Order No.";
                                OnBeforeInsertAsmPlanningComponent(ReqLine, AsmBOMComp[Level], PlanningComponent);
                                PlanningComponent.Insert();
                            end else begin
                                PlanningComponent.Reset();
                                PlanningComponent.BlockDynamicTracking(Blocked);
                                PlanningComponent.SetRequisitionLine(ReqLine);
                                PlanningComponent.Validate(
                                  "Quantity per",
                                  PlanningComponent."Quantity per" +
                                  Quantity *
                                  AsmBOMComp[Level]."Quantity per");
                                OnTransferAsmBOMOnBeforePlanningComponentModify(PlanningComponent);
                                PlanningComponent.Modify();
                            end;

                            // A temporary list of Planning Components handled is sustained:
                            TempPlanningComponent := PlanningComponent;
                            if not TempPlanningComponent.Insert() then
                                TempPlanningComponent.Modify();
                        end;
                    AsmBOMComp[Level].Type::" ":
                        begin
                            NextPlanningCompLineNo := NextPlanningCompLineNo + 10;
                            PlanningComponent.Reset();
                            PlanningComponent.Init();
                            PlanningComponent."Worksheet Template Name" := ReqLine."Worksheet Template Name";
                            PlanningComponent."Worksheet Batch Name" := ReqLine."Journal Batch Name";
                            PlanningComponent."Worksheet Line No." := ReqLine."Line No.";
                            PlanningComponent."Line No." := NextPlanningCompLineNo;
                            PlanningComponent.Description := CopyStr(AsmBOMComp[Level].Description, 1, MaxStrLen(PlanningComponent.Description));
                            PlanningComponent.Insert();
                            // A temporary list of Planning Components handled is sustained:
                            TempPlanningComponent := PlanningComponent;
                            if not TempPlanningComponent.Insert() then
                                TempPlanningComponent.Modify();
                        end;
                end;
            until AsmBOMComp[Level].Next() = 0;
    end;

    local procedure CalculateComponents()
    var
        PlanningAssignment: Record "Planning Assignment";
    begin
        PlanningComponent.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", ReqLine."Line No.");

        if PlanningComponent.Find('-') then
            repeat
                PlanningComponent.BlockDynamicTracking(Blocked);
                PlanningComponent.SetRequisitionLine(ReqLine);
                OnCalculateComponentsOnbeforePlanningComponentModify(PlanningComponent);
                PlanningComponent.Modify();
                PlanningAssignment.ChkAssignOne(PlanningComponent."Item No.", PlanningComponent."Variant Code", PlanningComponent."Location Code", PlanningComponent."Due Date");
            until PlanningComponent.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit Planning Routing Management', '27.0')]
    procedure CalculateRoutingFromActual(PlanningRtngLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; Direction: Option Forward,Backward; CalcStartEndDate: Boolean)
    var
        PlanningRoutingManagement: Codeunit Microsoft.Manufacturing.Routing.PlanningRoutingManagement;
    begin
        PlanningRoutingManagement.CalculateRoutingFromActual(ReqLine, PlanningRtngLine, Direction, CalcStartEndDate, PlanningResiliency);
    end;
#endif

#if not CLEAN27
    [Obsolete('Moved to codeunit Planning Routing Management', '27.0')]
    procedure CalculatePlanningLineDates(var ReqLine2: Record "Requisition Line")
    var
        PlanningRoutingManagement: Codeunit Microsoft.Manufacturing.Routing.PlanningRoutingManagement;
    begin
        PlanningRoutingManagement.CalculatePlanningLineDates(ReqLine2);
    end;
#endif

    procedure Calculate(var ReqLine2: Record "Requisition Line"; Direction: Option Forward,Backward; CalcRouting: Boolean; CalcComponents: Boolean; PlanningLevel: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculate(ReqLine2, Direction, CalcRouting, CalcComponents, PlanningLevel, IsHandled);
        if IsHandled then
            exit;

        ReqLine := ReqLine2;
        if ReqLine."Action Message" <> ReqLine."Action Message"::Cancel then
            ReqLine.TestField(Quantity);
        if Direction = Direction::Backward then
            ReqLine.TestField("Ending Date")
        else
            ReqLine.TestField("Starting Date");

        if CalcRouting then
            OnCalculateRouting(ReqLine, TempPlanningErrorLog, PlanningResiliency);

        if CalcComponents then begin
            PlanningComponent.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
            PlanningComponent.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
            PlanningComponent.SetRange("Worksheet Line No.", ReqLine."Line No.");
            if PlanningComponent.Find('-') then
                repeat
                    PlanningComponent.BlockDynamicTracking(Blocked);
                    PlanningComponent.Delete(true);
                until PlanningComponent.Next() = 0;
            if ReqLine."Planning Level" = 0 then
                ReqLine.DeleteMultiLevel();
            if (ReqLine."Replenishment System" = ReqLine."Replenishment System"::Assembly) or
               ((ReqLine."Replenishment System" = ReqLine."Replenishment System"::"Prod. Order") and ReqLine.IsProductionBOM())
            then begin
                Item.Get(ReqLine."No.");
                GetPlanningParameters.AtSKU(SKU, ReqLine."No.", ReqLine."Variant Code", ReqLine."Location Code");

                if ReqLine."Replenishment System" = ReqLine."Replenishment System"::Assembly then
                    TransferAsmBOM(Item."No.", 1, ReqLine."Qty. per Unit of Measure")
                else begin
                    IsHandled := false;
                    OnCalculateOnBeforeTransferBOM(ReqLine, SKU, PlanningResiliency, IsHandled);
                    if not IsHandled then
                        OnCalculateOnTransferBOM(
                            ReqLine, Item, PlanningComponent, TempPlanningErrorLog, TempPlanningComponent, SKU,
                            PlanningResiliency, NextPlanningCompLineNo, Blocked);
                end;
            end;
        end;
        Recalculate(ReqLine, Direction);
        ReqLine2 := ReqLine;
        if CalcComponents and
           (SKU."Manufacturing Policy" = SKU."Manufacturing Policy"::"Make-to-Order")
        then
            CheckMultiLevelStructure(ReqLine, CalcRouting, CalcComponents, PlanningLevel);

        OnAfterCalculate(CalcComponents, SKU, ReqLine2);
    end;

    procedure Recalculate(var ReqLine2: Record "Requisition Line"; Direction: Option Forward,Backward)
    begin
        RecalculateWithOptionalModify(ReqLine2, Direction, true);
    end;

    procedure RecalculateWithOptionalModify(var ReqLine2: Record "Requisition Line"; Direction: Option Forward,Backward; ModifyRec: Boolean)
    begin
        OnBeforeRecalculateWithOptionalModify(ReqLine2, Direction);

        ReqLine := ReqLine2;

        if ModifyRec then
            ReqLine.Modify(true);
        CalculateComponents();
        if ReqLine."Planning Level" > 0 then begin
            if Direction = Direction::Forward then
                ReqLine."Due Date" := ReqLine."Ending Date"
        end else
            if (ReqLine."Due Date" < ReqLine."Ending Date") or
               (Direction = Direction::Forward)
            then
                ReqLine."Due Date" :=
                  LeadTimeMgt.GetPlannedDueDate(
                    ReqLine."No.",
                    ReqLine."Location Code",
                    ReqLine."Variant Code",
                    ReqLine."Ending Date",
                    ReqLine."Vendor No.",
                    ReqLine."Ref. Order Type");
        ReqLine.UpdateDatetime();
        ReqLine2 := ReqLine;

        OnAfterRecalculateWithOptionalModify(ReqLine2, Direction);
    end;

    procedure CheckMultiLevelStructure(ReqLine2: Record "Requisition Line"; CalcRouting: Boolean; CalcComponents: Boolean; PlanningLevel: Integer)
    var
        ReqLine3: Record "Requisition Line";
        Item3: Record Item;
        PlanningComp: Record "Planning Component";
        TrackingSpecification: Record "Tracking Specification";
        PlngComponentReserve: Codeunit "Plng. Component-Reserve";
        PlanningLineNo: Integer;
        NoOfComponents: Integer;
        ShouldExit: Boolean;
        ThrowLineSpacingError: Boolean;
    begin
        if PlanningLevel < 0 then
            exit;

        if not Item3.Get(ReqLine2."No.") then
            exit;

        ShouldExit := Item3."Manufacturing Policy" <> Item3."Manufacturing Policy"::"Make-to-Order";
        OnCheckMultiLevelStructureOnAfterCalcShouldExitManufacturingPolicy(ReqLine2, ShouldExit, PlanningLevel, LineSpacing, PlanningResiliency, Blocked, CalcRouting, CalcComponents, TempPlanningErrorLog);
        if ShouldExit then
            exit;

        PlanningLineNo := ReqLine2."Line No.";

        PlanningComp.SetRange("Worksheet Line No.", ReqLine2."Line No.");
        PlanningComp.SetFilter("Item No.", '<>%1', '');
        PlanningComp.SetFilter("Expected Quantity", '<>0');
        PlanningComp.SetFilter("Planning Level Code", '>0');
        OnCheckMultiLevelStructureOnAfterPlanningCompSetFilters(PlanningComp, ReqLine2);
        NoOfComponents := PlanningComp.Count();
        if PlanningLevel = 0 then begin
            ReqLine3.Reset();
            ReqLine3.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
            ReqLine3.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
            ReqLine3 := ReqLine2;
            if ReqLine3.Find('>') then
                LineSpacing[1] := (ReqLine3."Line No." - ReqLine."Line No.") div (1 + NoOfComponents)
            else
                LineSpacing[1] := 10000;
        end else
            if (PlanningLevel > 0) and (PlanningLevel < 50) then
                LineSpacing[PlanningLevel + 1] := LineSpacing[PlanningLevel] div (1 + NoOfComponents);

        if PlanningComp.Find('-') then
            repeat
                ThrowLineSpacingError := LineSpacing[PlanningLevel + 1] = 0;
                OnCheckMultiLevelStructureOnAfterCalcThrowLineSpacingError(ReqLine2, LineSpacing, PlanningLineNo, ThrowLineSpacingError);
                if ThrowLineSpacingError then begin
                    if PlanningResiliency then
                        TempPlanningErrorLog.SetError(Text015, Database::"Requisition Line", ReqLine.GetPosition());
                    Error(Text002);
                end;
                ReqLine3.Init();
                ReqLine3.BlockDynamicTracking(Blocked);
                ReqLine3."Worksheet Template Name" := ReqLine2."Worksheet Template Name";
                ReqLine3."Journal Batch Name" := ReqLine2."Journal Batch Name";
                PlanningLineNo := PlanningLineNo + LineSpacing[PlanningLevel + 1];
                ReqLine3."Line No." := PlanningLineNo;
                ReqLine3."Ref. Order Type" := ReqLine2."Ref. Order Type";
                ReqLine3."Ref. Order Status" := ReqLine2."Ref. Order Status";
                ReqLine3."Ref. Order No." := ReqLine2."Ref. Order No.";

                ReqLine3."Planning Line Origin" := ReqLine2."Planning Line Origin";
                ReqLine3.Level := ReqLine2.Level;
                ReqLine3."Demand Type" := ReqLine2."Demand Type";
                ReqLine3."Demand Subtype" := ReqLine2."Demand Subtype";
                ReqLine3."Demand Order No." := ReqLine2."Demand Order No.";
                ReqLine3."Demand Line No." := ReqLine2."Demand Line No.";
                ReqLine3."Demand Ref. No." := ReqLine2."Demand Ref. No.";
                ReqLine3."Demand Ref. No." := ReqLine2."Demand Ref. No.";
                ReqLine3."Demand Date" := ReqLine2."Demand Date";
                ReqLine3.Status := ReqLine2.Status;
                ReqLine3."User ID" := ReqLine2."User ID";

                ReqLine3.Type := ReqLine3.Type::Item;
                ReqLine3.Validate("No.", PlanningComp."Item No.");
                ReqLine3."Action Message" := ReqLine2."Action Message";
                ReqLine3."Accept Action Message" := ReqLine2."Accept Action Message";
                ReqLine3.Description := PlanningComp.Description;
                ReqLine3."Variant Code" := PlanningComp."Variant Code";
                ReqLine3."Unit of Measure Code" := PlanningComp."Unit of Measure Code";
                ReqLine3."Location Code" := PlanningComp."Location Code";
                ReqLine3."Bin Code" := PlanningComp."Bin Code";
                ReqLine3."Ending Date" := PlanningComp."Due Date";
                ReqLine3.Validate("Ending Time", PlanningComp."Due Time");
                ReqLine3."Due Date" := PlanningComp."Due Date";
                ReqLine3."Demand Date" := PlanningComp."Due Date";
                OnCheckMultiLevelStructureOnBeforeValidateQuantity(ReqLine3, PlanningComp);
                ReqLine3.Validate(Quantity, PlanningComp."Expected Quantity");
                ReqLine3.Validate("Needed Quantity", PlanningComp."Expected Quantity");
                ReqLine3.Validate("Demand Quantity", PlanningComp."Expected Quantity");
                ReqLine3."Demand Qty. Available" := 0;

                ReqLine3."Planning Level" := PlanningLevel + 1;
                ReqLine3."Related to Planning Line" := ReqLine2."Line No.";
                ReqLine3."Order Promising ID" := ReqLine2."Order Promising ID";
                ReqLine3."Order Promising Line ID" := ReqLine2."Order Promising Line ID";
                OnCheckMultiLevelStructureOnBeforeInsertPlanningLine(ReqLine3, PlanningComp);
                InsertPlanningLine(ReqLine3);
                ReqLine3.Quantity :=
                  Round(
                    ReqLine3."Quantity (Base)" /
                    ReqLine3."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                ReqLine3."Net Quantity (Base)" :=
                  (ReqLine3.Quantity -
                   ReqLine3."Original Quantity") *
                  ReqLine3."Qty. per Unit of Measure";
                ReqLine3.Modify();
                if PlanningComp."Location Code" = ReqLine3."Location Code" then begin
                    TrackingSpecification.InitTrackingSpecification(
                        DATABASE::"Requisition Line", 0,
                        ReqLine3."Worksheet Template Name", ReqLine3."Journal Batch Name", 0, ReqLine3."Line No.",
                        ReqLine3."Variant Code", ReqLine3."Location Code", ReqLine3."Qty. per Unit of Measure");
                    PlngComponentReserve.BindToTracking(
                        PlanningComp, TrackingSpecification, ReqLine3.Description, ReqLine3."Ending Date",
                        PlanningComp."Expected Quantity", PlanningComp."Expected Quantity (Base)");
                end;
                PlanningComp."Supplied-by Line No." := ReqLine3."Line No.";
                PlanningComp.Modify();
                OnCheckMultiLevelStructureOnBeforeReqLineModify(ReqLine3);
                ReqLine3.Modify();
                Calculate(ReqLine3, 1, CalcRouting, CalcComponents, PlanningLevel + 1);
                ReqLine3.Modify();
            until PlanningComp.Next() = 0;
    end;

    local procedure InsertPlanningLine(var ReqLine: Record "Requisition Line")
    var
        ReqLine2: Record "Requisition Line";
    begin
        ReqLine2 := ReqLine;
        ReqLine2.SetCurrentKey("Worksheet Template Name", "Journal Batch Name", Type, "No.");
        ReqLine2.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        ReqLine2.SetRange("Journal Batch Name", ReqLine."Journal Batch Name");
        ReqLine2.SetRange(Type, ReqLine.Type::Item);
        ReqLine2.SetRange("No.", ReqLine."No.");
        ReqLine2.SetRange("Variant Code", ReqLine."Variant Code");
        ReqLine2.SetRange("Ref. Order Type", ReqLine."Ref. Order Type");
        ReqLine2.SetRange("Ref. Order Status", ReqLine."Ref. Order Status");
        ReqLine2.SetRange("Ref. Order No.", ReqLine."Ref. Order No.");
        ReqLine2.SetFilter("Planning Level", '>%1', 0);
        OnInsertPlanningLineOnAfterReqLine2SetFilters(ReqLine2, ReqLine);

        if ReqLine2.FindFirst() then begin
            ReqLine2.BlockDynamicTracking(Blocked);
            ReqLine2.Validate(Quantity, ReqLine2.Quantity + ReqLine.Quantity);

            if ReqLine2."Due Date" > ReqLine."Due Date" then
                ReqLine2."Due Date" := ReqLine."Due Date";

            if ReqLine2."Ending Date" > ReqLine."Ending Date" then begin
                ReqLine2."Ending Date" := ReqLine."Ending Date";
                ReqLine2."Ending Time" := ReqLine."Ending Time";
            end else
                if (ReqLine2."Ending Date" = ReqLine."Ending Date") and
                   (ReqLine2."Ending Time" > ReqLine."Ending Time")
                then
                    ReqLine2."Ending Time" := ReqLine."Ending Time";

            if ReqLine2."Planning Level" < ReqLine."Planning Level" then
                ReqLine2."Planning Level" := ReqLine."Planning Level";

            ReqLine2.Modify();
            ReqLine := ReqLine2;
        end else
            ReqLine.Insert();

        OnAfterInsertPlanningLine(ReqLine);
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        Blocked := SetBlock;
    end;

    procedure GetPlanningCompList(var PlanningCompList: Record "Planning Component" temporary)
    begin
        // The procedure returns a list of the Planning Components handled.
        if TempPlanningComponent.Find('-') then
            repeat
                PlanningCompList := TempPlanningComponent;
                if not PlanningCompList.Insert() then
                    PlanningCompList.Modify();
                TempPlanningComponent.Delete();
            until TempPlanningComponent.Next() = 0;
    end;

    local procedure IsPlannedAsmComp(var PlanningComp: Record "Planning Component"; ReqLine: Record "Requisition Line"; AsmBOMComp: Record "BOM Component"): Boolean
    var
        PlanningComp2: Record "Planning Component";
    begin
        PlanningComp2 := PlanningComp;

        PlanningComp.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Item No.");
        PlanningComp.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningComp.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningComp.SetRange("Worksheet Line No.", ReqLine."Line No.");
        PlanningComp.SetRange("Item No.", AsmBOMComp."No.");
        if PlanningComp.Find('-') then
            repeat
                if IsPlannedAsmCompFound(PlanningComp, AsmBOMComp) then
                    exit(true);
            until PlanningComp.Next() = 0;

        PlanningComp := PlanningComp2;
        exit(false);
    end;

    local procedure IsPlannedAsmCompFound(PlanningComp: Record "Planning Component"; AsmBOMComp: Record "BOM Component"): Boolean
    var
        IsFound: Boolean;
    begin
        IsFound :=
            (PlanningComp."Variant Code" = AsmBOMComp."Variant Code") and
            (PlanningComp.Position = AsmBOMComp.Position) and
            (PlanningComp."Position 2" = AsmBOMComp."Position 2") and
            (PlanningComp."Position 3" = AsmBOMComp."Position 3") and
            (PlanningComp."Unit of Measure Code" = AsmBOMComp."Unit of Measure Code");
        OnAfterIsPlannedAsmCompFound(PlanningComp, AsmBOMComp, IsFound);
        exit(IsFound);
    end;

    procedure SetResiliencyOn(WkshTemplName: Code[10]; JnlBatchName: Code[10]; ItemNo: Code[20])
    begin
        PlanningResiliency := true;
        TempPlanningErrorLog.SetJnlBatch(WkshTemplName, JnlBatchName, ItemNo);
    end;

    procedure GetResiliencyError(var PlanningErrorLog: Record "Planning Error Log"): Boolean
    var
        ShouldExit: Boolean;
    begin
        TempPlanningComponent.DeleteAll();
        OnGetResiliencyErrorOnRouting(PlanningErrorLog, ShouldExit);
        if ShouldExit then
            exit(true);
        exit(TempPlanningErrorLog.GetError(PlanningErrorLog));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPlanningLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterIsPlannedCompFound(var PlanningComp: Record "Planning Component"; var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var IsFound: Boolean; var SKU2: Record "Stockkeeping Unit")
    begin
        OnAfterIsPlannedCompFound(PlanningComp, ProdBOMLine, IsFound, SKU2);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPlannedCompFound(var PlanningComp: Record "Planning Component"; var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var IsFound: Boolean; var SKU: Record "Stockkeeping Unit")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPlannedAsmCompFound(PlanningComp: Record "Planning Component"; AsmBOMComp: Record "BOM Component"; var IsFound: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterTransferBOM(RequisitionLine: Record "Requisition Line"; ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
        OnAfterTransferBOM(RequisitionLine, ProdBOMNo, Level, LineQtyPerUOM, ItemQtyPerUOM);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferBOM(RequisitionLine: Record "Requisition Line"; ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateWithOptionalModify(var RequisitionLine: Record "Requisition Line"; Direction: Option Forward,Backward)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterTransferRouting(var RequisitionLine: Record "Requisition Line")
    begin
        OnAfterTransferRouting(RequisitionLine);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRouting(var RequisitionLine: Record "Requisition Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnAfterTransferRtngLine(var ReqLine2: Record "Requisition Line"; var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line")
    begin
        OnAfterTransferRtngLine(ReqLine2, RoutingLine, PlanningRoutingLine);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRtngLine(var ReqLine: Record "Requisition Line"; var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnTransferBOMOnAfterProdBOMLineSetFilters(var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; RequisitionLine: Record "Requisition Line")
    begin
        OnTransferBOMOnAfterProdBOMLineSetFilters(ProdBOMLine, RequisitionLine);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnAfterProdBOMLineSetFilters(var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnTransferBOMOnBeforeGetDefaultBin(var PlanningComponent2: Record "Planning Component"; var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; RequisitionLine: Record "Requisition Line"; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
        OnTransferBOMOnBeforeGetDefaultBin(PlanningComponent2, ProductionBOMLine, RequisitionLine, StockkeepingUnit);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeGetDefaultBin(var PlanningComponent: Record "Planning Component"; var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; RequisitionLine: Record "Requisition Line"; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnTransferRoutingLineOnBeforeValidateDirectUnitCost(var ReqLine2: Record "Requisition Line"; var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line")
    begin
        OnTransferRoutingLineOnBeforeValidateDirectUnitCost(ReqLine2, RoutingLine, PlanningRoutingLine);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferRoutingLineOnBeforeValidateDirectUnitCost(var ReqLine: Record "Requisition Line"; var RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnTransferRoutingLineOnBeforeCalcRoutingCostPerUnit(var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; ReqLine2: Record "Requisition Line"; RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line")
    begin
        OnTransferRoutingLineOnBeforeCalcRoutingCostPerUnit(PlanningRoutingLine, ReqLine2, RoutingLine);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferRoutingLineOnBeforeCalcRoutingCostPerUnit(var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; ReqLine: Record "Requisition Line"; RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculate(var ReqLine2: Record "Requisition Line"; Direction: Option Forward,Backward; CalcRouting: Boolean; CalcComponents: Boolean; PlanningLevel: Integer; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeInsertPlanningComponent(var ReqLine2: Record "Requisition Line"; var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var PlanningComponent2: Record "Planning Component"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
        OnBeforeInsertPlanningComponent(ReqLine2, ProductionBOMLine, PlanningComponent2, LineQtyPerUOM, ItemQtyPerUOM);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPlanningComponent(var ReqLine: Record "Requisition Line"; var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var PlanningComponent: Record "Planning Component"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeModifyPlanningComponent(var ReqLine2: Record "Requisition Line"; var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var PlanningComponent2: Record "Planning Component"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
        OnBeforeModifyPlanningComponent(ReqLine2, ProductionBOMLine, PlanningComponent2, LineQtyPerUOM, ItemQtyPerUOM);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPlanningComponent(var ReqLine: Record "Requisition Line"; var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var PlanningComponent: Record "Planning Component"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAsmPlanningComponent(var ReqLine: Record "Requisition Line"; var BOMComponent: Record "BOM Component"; var PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculateWithOptionalModify(var RequisitionLine: Record "Requisition Line"; Direction: Option Forward,Backward)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeTransferBOM(ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; var RequisitionLine: Record "Requisition Line"; Blocked2: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeTransferBOM(ProdBOMNo, Level, LineQtyPerUOM, ItemQtyPerUOM, RequisitionLine, Blocked2, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferBOM(ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; var RequisitionLine: Record "Requisition Line"; Blocked: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeTransferRouting(var RequisitionLine: Record "Requisition Line"; PlanningResilency: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeTransferRouting(RequisitionLine, PlanningResilency, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRouting(var RequisitionLine: Record "Requisition Line"; PlanningResilency: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnBeforeTransferBOM(var RequisitionLine: Record "Requisition Line"; var StockkeepingUnit: Record "Stockkeeping Unit"; PlanningResilency: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnCalculateRoutingOnAfterUpdateReqLine(var RequisitionLine: Record "Requisition Line"; Direction: Option Forward,Backward)
    begin
        OnCalculateRoutingOnAfterUpdateReqLine(RequisitionLine, Direction);
    end;

    [Obsolete('Moved to codeunit PlanningRoutingManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingOnAfterUpdateReqLine(var RequisitionLine: Record "Requisition Line"; Direction: Option Forward,Backward)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnBeforeInsertPlanningLine(var ReqLine: Record "Requisition Line"; var PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnAfterPlanningCompSetFilters(var PlanningComponent: Record "Planning Component"; RequisitionLine2: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnAfterCalcThrowLineSpacingError(RequisitionLine: Record "Requisition Line"; var LineSpacing: array[50] of Integer; var PlanningLineNo: Integer; var ThrowLineSpacingError: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnTransferBOMOnBeforeTransferPlanningComponent(var RequisitionLine: Record "Requisition Line"; var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; Blocked2: Boolean; var IsHandled: Boolean; Level: Integer)
    begin
        OnTransferBOMOnBeforeTransferPlanningComponent(RequisitionLine, ProductionBOMLine, Blocked2, IsHandled, Level);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeTransferPlanningComponent(var RequisitionLine: Record "Requisition Line"; var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; Blocked: Boolean; var IsHandled: Boolean; Level: Integer)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnTransferBOMOnBeforeTransferProductionBOM(var ReqQty: Decimal; ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; RequisitionLine: Record "Requisition Line")
    begin
        OnTransferBOMOnBeforeTransferProductionBOM(ReqQty, ProductionBOMLine, LineQtyPerUOM, ItemQtyPerUOM, RequisitionLine);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeTransferProductionBOM(var ReqQty: Decimal; ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; RequisitionLine: Record "Requisition Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnTransferBOMOnBeforeUpdatePlanningComp(var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var UpdateCondition: Boolean; var IsHandled: Boolean)
    begin
        OnTransferBOMOnBeforeUpdatePlanningComp(ProductionBOMLine, UpdateCondition, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeUpdatePlanningComp(var ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var UpdateCondition: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnTransferBOMOnAfterCalculateReqQty(var ReqQty: Decimal; ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal);
    begin
        OnTransferBOMOnAfterCalculateReqQty(ReqQty, ProductionBOMLine, PlanningRoutingLine, LineQtyPerUOM, ItemQtyPerUOM);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnAfterCalculateReqQty(var ReqQty: Decimal; ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal);
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnTransferAsmBOMOnBeforeGetDefaultBin(var PlanningComponent: Record "Planning Component"; var AsmBOMComponent: Record "BOM Component"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnBeforeValidateQuantity(var RequisitionLine: Record "Requisition Line"; var PlanningComponent: Record "Planning Component");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPlanningLineOnAfterReqLine2SetFilters(var ReqLine2: Record "Requisition Line"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnAfterCalcShouldExitManufacturingPolicy(var RequisitionLine: Record "Requisition Line"; var ShouldExit: Boolean; PlanningLevel: Integer; var LineSpacing: array[50] of Integer; PlanningResiliency: Boolean; Blocked: Boolean; CalcRouting: Boolean; CalcComponents: Boolean; var TempPlanningErrorLog: Record "Planning Error Log" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculate(var CalcComponents: Boolean; var SKU: Record "Stockkeeping Unit"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterSetPlanningLevelCode(var PlanningComponent2: Record "Planning Component"; var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var SKU2: Record "Stockkeeping Unit"; var ComponentSKU: Record "Stockkeeping Unit"; var Result: Boolean)
    begin
        OnAfterSetPlanningLevelCode(PlanningComponent2, ProdBOMLine, SKU2, ComponentSKU, Result);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPlanningLevelCode(var PlanningComponent: Record "Planning Component"; var ProdBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; var SKU: Record "Stockkeeping Unit"; var ComponentSKU: Record "Stockkeeping Unit"; var Result: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeTransferRoutingLine(var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; RequisitionLine: Record "Requisition Line"; RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var IsHandled: Boolean)
    begin
        OnBeforeTransferRoutingLine(PlanningRoutingLine, RequisitionLine, RoutingLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRoutingLine(var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; RequisitionLine: Record "Requisition Line"; RoutingLine: Record Microsoft.Manufacturing.Routing."Routing Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnTransferBOMOnBeforePlanningRtngLineFind(var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; RequisitionLine: Record "Requisition Line")
    begin
        OnTransferBOMOnBeforePlanningRtngLineFind(PlanningRoutingLine, ProductionBOMLine, RequisitionLine);
    end;

    [Obsolete('Moved to codeunit MfgPlanningLineManagement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforePlanningRtngLineFind(var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; ProductionBOMLine: Record Microsoft.Manufacturing.ProductionBOM."Production BOM Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetResiliencyErrorOnRouting(var PlanningErrorLog: Record "Planning Error Log"; var ShouldExit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRouting(var RequisitionLine: Record "Requisition Line"; var TempPlanningErrorLog: Record "Planning Error Log" temporary; PlanningResiliency: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnTransferBOM(
        var RequisitionLine: Record "Requisition Line"; Item: Record Item; var PlanningComponent: Record "Planning Component";
        var TempPlanningErrorLog: Record "Planning Error Log" temporary; var TempPlanningComponent: Record "Planning Component" temporary;
        SKU: Record "Stockkeeping Unit"; PlanningResiliency: Boolean; var NextPlanningCompLineNo: Integer; Blocked: Boolean)
    begin
    end;

    [InternalEvent(false)]
    local procedure OnTransferASMBOMOnAfterSetAsmBOMComp(var PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateComponentsOnbeforePlanningComponentModify(var PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMultiLevelStructureOnBeforeReqLineModify(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferAsmBOMOnBeforePlanningComponentModify(var PlanningComponent: Record "Planning Component")
    begin
    end;
}

