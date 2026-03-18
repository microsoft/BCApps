// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Journal;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

codeunit 5510 "Production Journal Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        MfgSetup: Record "Manufacturing Setup";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        UOMMgt: Codeunit "Unit of Measure Management";
        PostingDate: Date;
        CalcBasedOn: Option "Actual Output","Expected Output";
        PresetOutputQuantity: Option "Expected Quantity","Zero on All Operations","Zero on Last Operation";
        ToTemplateName: Code[10];
        ToBatchName: Code[10];
        NextLineNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 journal';
#pragma warning restore AA0470
        Text001: Label 'Do you want to leave the Production Journal?';
#pragma warning restore AA0074
        BlockedMsg: Label '%2 %1 is blocked and therefore, no journal line is created for this %2.', Comment = '%1 - Entity No, %2 - Table caption';
#pragma warning disable AA0074
        Text003: Label 'DEFAULT';
        Text004: Label 'Production Journal';
#pragma warning disable AA0470
        Text005: Label '%1 %2 for operation %3 is blocked and therefore, no journal line is created for this operation.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        GeneratingJnlLinesMsg: Label 'Generating journal lines.';

    procedure Handling(ProdOrder: Record "Production Order"; ActualLineNo: Integer)
    var
        ProductionJnl: Page "Production Journal";
        ProgressBar: Dialog;
        LeaveForm: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeHandling(ProdOrder, ActualLineNo, IsHandled);
        if not IsHandled then begin
            MfgSetup.Get();

            SetTemplateAndBatchName();

            InitSetupValues();

            ProgressBar.Open(GeneratingJnlLinesMsg);
            DeleteJnlLines(ToTemplateName, ToBatchName, ProdOrder."No.", ActualLineNo);
            CreateJnlLines(ProdOrder, ActualLineNo);
            ProgressBar.Close();

            IsHandled := false;
            OnBeforeRunProductionJnl(ToTemplateName, ToBatchName, ProdOrder, ActualLineNo, PostingDate, IsHandled);
            if not IsHandled then begin
                repeat
                    // Commit before running Production Journal page
                    Commit();

                    LeaveForm := true;
                    Clear(ProductionJnl);
                    ProductionJnl.Setup(ToTemplateName, ToBatchName, ProdOrder, ActualLineNo, PostingDate);
                    ProductionJnl.RunModal();
                    if DataHasChanged(ToTemplateName, ToBatchName, ProdOrder."No.", ActualLineNo) then
                        LeaveForm := Confirm(Text001, true);
                until LeaveForm;

                DeleteJnlLines(ToTemplateName, ToBatchName, ProdOrder."No.", ActualLineNo);
            end;
        end;
    end;

    procedure CreateJnlLines(ProdOrder: Record "Production Order"; ProdOrderLineNo: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        ProdOrderComp: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        SetNextLineNo(ItemJnlLine);

        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLineNo <> 0 then
            ProdOrderLine.SetRange("Line No.", ProdOrderLineNo);
        OnCreateJnlLinesOnAfterSetProdOrderLineFilters(ProdOrderLine);
        if ProdOrderLine.Find('-') then
            repeat
                OnCreateJnlLinesOnBeforeCheckProdOrderLine(ProdOrderLine);

                ProdOrderRtngLine.Reset();
                ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
                ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                OnCreateJnlLinesOnAfterProdOrderRtngLineSetFilters(ProdOrderRtngLine);
                if ProdOrderRtngLine.Find('-') then begin
                    IsHandled := false;
                    OnCreateJnlLinesOnBeforeInsertComponents(ProdOrderRtngLine, ProdOrder, ProdOrderLine, IsHandled);
                    if not IsHandled then
                        InsertComponents(ProdOrderLine, true, 0); // With no Routing Link or illegal Routing Link
                    repeat
                        IsHandled := false;
                        OnCreateJnlLinesOnAfterFindProdOrderRtngLine(ProdOrderRtngLine, IsHandled, ItemJnlLine, NextLineNo);
                        if not IsHandled then begin
                            InsertOutputItemJnlLine(ProdOrderRtngLine, ProdOrderLine);
                            if ProdOrderRtngLine."Routing Link Code" <> '' then begin
                                ProdOrderComp.Reset();
                                ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Routing Link Code");
                                ProdOrderComp.SetRange(Status, ProdOrder.Status);
                                ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                                ProdOrderComp.SetRange("Routing Link Code", ProdOrderRtngLine."Routing Link Code");
                                ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
                                ProdOrderComp.SetFilter("Item No.", '<>%1', '');
                                if ProdOrderComp.FindSet() then
                                    repeat
                                        InsertConsumptionItemJnlLine(ProdOrderComp, ProdOrderLine, 1);
                                    until ProdOrderComp.Next() = 0;
                            end;
                        end;
                    until ProdOrderRtngLine.Next() = 0;
                end else begin
                    // Insert All Components - No Routing Link Check
                    InsertComponents(ProdOrderLine, false, 0);

                    // Create line for Output Qty
                    Clear(ProdOrderRtngLine);
                    InsertOutputItemJnlLine(ProdOrderRtngLine, ProdOrderLine);
                end;
            until ProdOrderLine.Next() = 0;
    end;

    procedure InsertComponents(ProdOrderLine: Record "Prod. Order Line"; CheckRoutingLink: Boolean; Level: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertComponents(ProdOrderLine, CheckRoutingLink, Level, IsHandled);
        if IsHandled then
            exit;

        // Components with no Routing Link or illegal Routing Link
        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComp.SetFilter("Item No.", '<>%1', '');
        OnInsertComponentsOnAfterProdOrderCompSetFilters(ProdOrderComp);
        if ProdOrderComp.Find('-') then
            repeat
                if not CheckRoutingLink then
                    InsertConsumptionItemJnlLine(ProdOrderComp, ProdOrderLine, Level)
                else
                    if not RoutingLinkValid(ProdOrderComp, ProdOrderLine) then
                        InsertConsumptionItemJnlLine(ProdOrderComp, ProdOrderLine, Level);
            until ProdOrderComp.Next() = 0;
    end;

    procedure RoutingLinkValid(ProdOrderComp: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoutingLinkValid(ProdOrderComp, ProdOrderLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ProdOrderComp."Routing Link Code" = '' then
            exit(false);

        ProdOrderRtngLine.Reset();
        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange("Routing Link Code", ProdOrderComp."Routing Link Code");
        exit(not ProdOrderRtngLine.IsEmpty());
    end;

    procedure InsertConsumptionItemJnlLine(ProdOrderComp: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; Level: Integer)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
#if not CLEAN26
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        NeededQty: Decimal;
        OriginalNeededQty: Decimal;
        IsHandled: Boolean;
        ShouldAdjustQty: Boolean;
        ItemItemVariantLbl: Label '%1 %2', Comment = '%1 - Item No., %2 - Variant Code';
    begin
        Item.Get(ProdOrderComp."Item No.");
        if Item.Blocked then begin
            Message(BlockedMsg, ProdOrderComp."Item No.", Item.TableCaption());
            exit;
        end;

        if ProdOrderComp."Variant Code" <> '' then begin
            ItemVariant.SetLoadFields(Blocked);
            ItemVariant.Get(ProdOrderComp."Item No.", ProdOrderComp."Variant Code");
            if ItemVariant.Blocked then begin
                Message(BlockedMsg, StrSubstNo(ItemItemVariantLbl, ProdOrderComp."Item No.", ProdOrderComp."Variant Code"), ItemVariant.TableCaption());
                exit;
            end;
        end;

        IsHandled := false;
        OnInsertConsumptionJnlLineOnBeforeCheck(ProdOrderComp, ProdOrderLine, Item, IsHandled);
        if IsHandled then
            exit;

        if not (ProdOrderComp."Flushing Method" in [ProdOrderComp."Flushing Method"::Manual, ProdOrderComp."Flushing Method"::"Pick + Manual"]) then
            NeededQty := 0
        else
            NeededQty := ProdOrderComp.GetNeededQty(CalcBasedOn, true);

        OriginalNeededQty := NeededQty;

#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            ShouldAdjustQty := ProdOrderComp."Flushing Method" in [ProdOrderComp."Flushing Method"::Manual, ProdOrderComp."Flushing Method"::"Pick + Manual"]
        else
#endif
            ShouldAdjustQty := ProdOrderComp."Flushing Method" = ProdOrderComp."Flushing Method"::"Pick + Manual";
        if ShouldAdjustQty then begin
            if ProdOrderComp."Location Code" <> Location.Code then
                if not Location.GetLocationSetup(ProdOrderComp."Location Code", Location) then
                    Clear(Location);

            ShouldAdjustQty := Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
            OnInsertConsumptionItemJnlLineOnAfterCalcShouldAdjustQty(ProdOrderComp, Location, NeededQty, ShouldAdjustQty);
            if ShouldAdjustQty then
                ProdOrderComp.AdjustQtyToQtyPicked(NeededQty);
        end;

        ItemJnlLine.Init();
        OnInsertConsumptionJnlLineOnAfterItemJnlLineInit(ItemJnlLine, ItemJnlTemplate, ItemJnlBatch);
        ItemJnlLine."Journal Template Name" := ToTemplateName;
        ItemJnlLine."Journal Batch Name" := ToBatchName;
        ItemJnlLine."Line No." := NextLineNo;
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderComp."Prod. Order No.");
        ItemJnlLine.Validate("Source No.", ProdOrderLine."Item No.");
        ItemJnlLine.Validate("Item No.", ProdOrderComp."Item No.");
        ItemJnlLine.Validate("Unit of Measure Code", ProdOrderComp."Unit of Measure Code");
        ItemJnlLine.Description := ProdOrderComp.Description;
        ConsumptionItemJnlLineValidateQuantity(ProdOrderComp, NeededQty, Item, NeededQty < OriginalNeededQty);

        ItemJnlLine.Validate("Location Code", ProdOrderComp."Location Code");
        ItemJnlLine.Validate("Dimension Set ID", ProdOrderComp."Dimension Set ID");
        if ProdOrderComp."Bin Code" <> '' then
            ItemJnlLine."Bin Code" := ProdOrderComp."Bin Code";

        ItemJnlLine."Variant Code" := ProdOrderComp."Variant Code";
        ItemJnlLine.Validate("Order Line No.", ProdOrderComp."Prod. Order Line No.");
        ItemJnlLine.Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");

        ItemJnlLine.Level := Level;
        ItemJnlLine."Flushing Method" := ProdOrderComp."Flushing Method";
        ItemJnlLine."Source Code" := ItemJnlTemplate."Source Code";
        ItemJnlLine."Reason Code" := ItemJnlBatch."Reason Code";
        ItemJnlLine."Posting No. Series" := ItemJnlBatch."Posting No. Series";

        OnBeforeInsertConsumptionJnlLine(ItemJnlLine, ProdOrderComp, ProdOrderLine, Level);
        ItemJnlLine.Insert();
        OnAfterInsertConsumptionJnlLine(ItemJnlLine);

        if Item."Item Tracking Code" <> '' then
            ItemTrackingMgt.CopyItemTracking(ProdOrderComp.RowID1(), ItemJnlLine.RowID1(), false);
        OnInsertConsumptionItemJnlLineOnAfterCopyItemTracking(ItemJnlLine, Item."Item Tracking Code", NextLineNo);

        NextLineNo += 10000;

        OnAfterInsertConsumptionJnlLine(ItemJnlLine);
    end;

    local procedure ConsumptionItemJnlLineValidateQuantity(ProdOrderComp: Record "Prod. Order Component"; NeededQty: Decimal; Item: Record Item; IgnoreRoundingPrecision: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnInsertConsumptionItemJnlLineOnBeforeValidateQuantity(ItemJnlLine, ProdOrderComp, NeededQty, IsHandled);
        if IsHandled then
            exit;

        if NeededQty <> 0 then
            if (Item."Rounding Precision" > 0) and not IgnoreRoundingPrecision then
                ItemJnlLine.Validate(Quantity, UOMMgt.RoundToItemRndPrecision(NeededQty, Item."Rounding Precision"))
            else
                ItemJnlLine.Validate(Quantity, Round(NeededQty, UOMMgt.QtyRndPrecision()));
    end;

    procedure InsertOutputItemJnlLine(ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        QtyToPost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertOutputItemJnlLine(ProdOrderRtngLine, ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderRtngLine."Prod. Order No." <> '' then
            // Operation exist
            case ProdOrderRtngLine.Type of
                ProdOrderRtngLine.Type::"Work Center":
                    begin
                        WorkCenter.Get(ProdOrderRtngLine."No.");
                        if WorkCenter.Blocked then begin
                            Message(Text005, WorkCenter.TableCaption(), WorkCenter."No.", ProdOrderRtngLine."Operation No.");
                            exit;
                        end;
                    end;
                ProdOrderRtngLine.Type::"Machine Center":
                    begin
                        MachineCenter.Get(ProdOrderRtngLine."No.");
                        if MachineCenter.Blocked then begin
                            Message(Text005, MachineCenter.TableCaption(), MachineCenter."No.", ProdOrderRtngLine."Operation No.");
                            exit;
                        end;

                        WorkCenter.Get(ProdOrderRtngLine."Work Center No.");
                        if WorkCenter.Blocked then begin
                            Message(Text005, WorkCenter.TableCaption(), WorkCenter."No.", ProdOrderRtngLine."Operation No.");
                            exit;
                        end;
                    end;
            end;

        if (ProdOrderRtngLine."Flushing Method" <> ProdOrderRtngLine."Flushing Method"::Manual) or
           (PresetOutputQuantity = PresetOutputQuantity::"Zero on All Operations") or
           ((PresetOutputQuantity = PresetOutputQuantity::"Zero on Last Operation") and
            IsLastOperation(ProdOrderRtngLine)) or
           ((ProdOrderRtngLine."Prod. Order No." = '') and
            (PresetOutputQuantity <> PresetOutputQuantity::"Expected Quantity")) or
           (ProdOrderRtngLine."Routing Status" = ProdOrderRtngLine."Routing Status"::Finished)
        then
            QtyToPost := 0
        else
            if ProdOrderRtngLine."Prod. Order No." <> '' then
                CalculateQtyToPostForProdOrder(ProdOrderLine, ProdOrderRtngLine, QtyToPost)
            else
                // No Routing Line
                QtyToPost := ProdOrderLine."Remaining Quantity";

        if QtyToPost < 0 then
            QtyToPost := 0;

        ItemJnlLine.Init();
        OnInsertOutputItemJnlLineOnAfterItemJnlLineInit(ItemJnlLine, ProdOrderLine, ItemJnlTemplate, ItemJnlBatch);
        ItemJnlLine."Journal Template Name" := ToTemplateName;
        ItemJnlLine."Journal Batch Name" := ToBatchName;
        ItemJnlLine."Line No." := NextLineNo;
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderLine."Prod. Order No.");
        ItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJnlLine.Validate("Item No.", ProdOrderLine."Item No.");
        ItemJnlLine.Validate("Variant Code", ProdOrderLine."Variant Code");
        ItemJnlLine.Validate("Location Code", ProdOrderLine."Location Code");
        ItemJnlLine.Validate("Dimension Set ID", ProdOrderLine."Dimension Set ID");
        if ProdOrderLine."Bin Code" <> '' then
            ItemJnlLine.Validate("Bin Code", ProdOrderLine."Bin Code");
        ItemJnlLine.Validate("Routing No.", ProdOrderLine."Routing No.");
        ItemJnlLine.Validate("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        if ProdOrderRtngLine."Prod. Order No." <> '' then
            ItemJnlLine.Validate("Operation No.", ProdOrderRtngLine."Operation No.");
        ItemJnlLine.Validate("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        ItemJnlLine.Validate("Setup Time", 0);
        ItemJnlLine.Validate("Run Time", 0);
        OnInsertOutputItemJnlLineOnAfterAssignTimes(ItemJnlLine, ProdOrderLine, ProdOrderRtngLine, QtyToPost);
        if (ProdOrderLine."Location Code" <> '') and IsLastOperation(ProdOrderRtngLine) then
            ItemJnlLine.CheckWhse(ProdOrderLine."Location Code", QtyToPost);
        OnInsertOutputItemJnlLineOnBeforeSubcontractingWorkCenterUsed(ItemJnlLine, ProdOrderLine);
        if ItemJnlLine.SubcontractingWorkCenterUsed() then
            ItemJnlLine.Validate("Output Quantity", 0)
        else begin
            if not IsLastOperation(ProdOrderRtngLine) then begin
                ItemJnlLine."Qty. Rounding Precision" := 0;
                ItemJnlLine."Qty. Rounding Precision (Base)" := 0;
            end;
            QtyToPost := UOMMgt.RoundQty(QtyToPost, ItemJnlLine."Qty. Rounding Precision (Base)");
            ItemJnlLine.Validate("Output Quantity", QtyToPost);
        end;


        if ProdOrderRtngLine."Routing Status" = ProdOrderRtngLine."Routing Status"::Finished then
            ItemJnlLine.Finished := true;
        ItemJnlLine."Flushing Method" := ProdOrderRtngLine."Flushing Method";
        ItemJnlLine."Source Code" := ItemJnlTemplate."Source Code";
        ItemJnlLine."Reason Code" := ItemJnlBatch."Reason Code";
        ItemJnlLine."Posting No. Series" := ItemJnlBatch."Posting No. Series";

        OnBeforeInsertOutputJnlLine(ItemJnlLine, ProdOrderRtngLine, ProdOrderLine);
        ItemJnlLine.Insert();
        OnAfterInsertOutputJnlLine(ItemJnlLine);

        if IsLastOperation(ProdOrderRtngLine) then
            ItemTrackingMgt.CopyItemTracking(ProdOrderLine.RowID1(), ItemJnlLine.RowID1(), false);
        OnInsertOutputItemJnlLineOnAfterCopyItemTracking(ItemJnlLine, ProdOrderRtngLine, NextLineNo);

        NextLineNo += 10000;

        RecursiveInsertOutputJnlLine(ProdOrderRtngLine, ProdOrderLine);
    end;

    local procedure CalculateQtyToPostForProdOrder(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var QtyToPost: Decimal)
    var
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
    begin
        QtyToPost :=
            MfgCostCalcMgt.CalcQtyAdjdForRoutingScrap(
                ProdOrderLine."Quantity (Base)",
                ProdOrderRoutingLine."Scrap Factor % (Accumulated)",
                ProdOrderRoutingLine."Fixed Scrap Qty. (Accum.)") -
            MfgCostCalcMgt.CalcActOutputQtyBase(ProdOrderLine, ProdOrderRoutingLine);
        QtyToPost := QtyToPost / ProdOrderLine."Qty. per Unit of Measure";

        OnAfterCalculateQtyToPostForProdOrder(ProdOrderLine, ProdOrderRoutingLine, QtyToPost);
    end;

    local procedure RecursiveInsertOutputJnlLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    var
        AdditionalProdOrderLine: Record "Prod. Order Line";
        DoRecursion: Boolean;
    begin
        DoRecursion := false;
        OnBeforeRecursiveInsertOutputJnlLine(ProdOrderRoutingLine, ProdOrderLine, DoRecursion, AdditionalProdOrderLine);
        if DoRecursion and AdditionalProdOrderLine.HasFilter then
            if AdditionalProdOrderLine.FindSet() then
                repeat
                    InsertOutputItemJnlLine(ProdOrderRoutingLine, AdditionalProdOrderLine);
                until AdditionalProdOrderLine.Next() = 0;
    end;

    procedure InitSetupValues()
    begin
        MfgSetup.Get();
        PostingDate := WorkDate();
        CalcBasedOn := MfgSetup."Default Consum. Calc. Based on";
        PresetOutputQuantity := MfgSetup."Preset Output Quantity";

        OnAfterInitSetupValues(PostingDate, CalcBasedOn)
    end;

    local procedure IsLastOperation(ProdOrderRoutingLine: Record "Prod. Order Routing Line") Result: Boolean
    begin
        Result := ProdOrderRoutingLine."Next Operation No." = '';
        OnAfterIsLastOperation(ProdOrderRoutingLine, Result);
    end;

    procedure SetTemplateAndBatchName()
    var
        PageTemplate: Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod. Order";
        User: Text;
        IsHandled: Boolean;
        PageID: Integer;
    begin
        PageID := Page::"Production Journal";
        PageTemplate := PageTemplate::"Prod. Order";

        IsHandled := false;
        OnBeforeSetTemplateAndBatchName(ToTemplateName, ToBatchName, IsHandled, PageID, PageTemplate);
        if IsHandled then
            exit;

        ItemJnlTemplate.Reset();
        ItemJnlTemplate.SetRange("Page ID", PageID);
        ItemJnlTemplate.SetRange(Recurring, false);
        ItemJnlTemplate.SetRange(Type, PageTemplate);
        if not ItemJnlTemplate.FindFirst() then begin
            ItemJnlTemplate.Init();
            ItemJnlTemplate.Recurring := false;
            ItemJnlTemplate.Validate(Type, PageTemplate);
            ItemJnlTemplate.Validate("Page ID");

            ItemJnlTemplate.Name := Format(ItemJnlTemplate.Type, MaxStrLen(ItemJnlTemplate.Name));
            ItemJnlTemplate.Description := StrSubstNo(Text000, ItemJnlTemplate.Type);
            ItemJnlTemplate.Insert();
        end;

        ToTemplateName := ItemJnlTemplate.Name;

        ToBatchName := '';
        User := UpperCase(UserId); // Uppercase in case of Windows Login

        OnAfterSetTemplateAndBatchName(ItemJnlTemplate, User);

        if User <> '' then
            if (StrLen(User) < MaxStrLen(ItemJnlLine."Journal Batch Name")) and (ItemJnlLine."Journal Batch Name" <> '') then
                ToBatchName := CopyStr(ItemJnlLine."Journal Batch Name", 1, MaxStrLen(ItemJnlLine."Journal Batch Name") - 1) + 'A'
            else
                ToBatchName := DelChr(CopyStr(User, 1, MaxStrLen(ItemJnlLine."Journal Batch Name")), '>', '0123456789');

        if ToBatchName = '' then
            ToBatchName := Text003;

        if not ItemJnlBatch.Get(ToTemplateName, ToBatchName) then begin
            ItemJnlBatch.Init();
            ItemJnlBatch."Journal Template Name" := ItemJnlTemplate.Name;
            ItemJnlBatch.SetupNewBatch();
            ItemJnlBatch.Name := ToBatchName;
            ItemJnlBatch.Description := Text004;
            ItemJnlBatch.Insert(true);
        end;
    end;

    procedure SetJnlTemplateAndBatchName(TemplateName: Code[10]; BatchName: Code[10])
    begin
        ToTemplateName := TemplateName;
        ToBatchName := BatchName;
    end;

    procedure DeleteJnlLines(TemplateName: Code[10]; BatchName: Code[10]; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer)
    var
        ItemJnlLine2: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteJnlLines(TemplateName, BatchName, ProdOrderNo, ProdOrderLineNo, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine2.Reset();
        ItemJnlLine2.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine2.SetRange("Journal Batch Name", BatchName);
        ItemJnlLine2.SetRange("Order Type", ItemJnlLine2."Order Type"::Production);
        ItemJnlLine2.SetRange("Order No.", ProdOrderNo);
        if ProdOrderLineNo <> 0 then
            ItemJnlLine2.SetRange("Order Line No.", ProdOrderLineNo);
        OnDeleteJnlLinesOnAfterSetFilters(ItemJnlLine2);
        if ItemJnlLine2.Find('-') then begin
            repeat
                if ReservEntryExist(ItemJnlLine2, ReservEntry) then
                    ReservEntry.DeleteAll(true);
            until ItemJnlLine2.Next() = 0;

            OnBeforeDeleteAllItemJnlLine(ItemJnlLine2);
            ItemJnlLine2.DeleteAll(true);
        end;
    end;

    local procedure DataHasChanged(TemplateName: Code[10]; BatchName: Code[10]; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer): Boolean
    var
        ItemJnlLine2: Record "Item Journal Line";
        ReservEntry: Record "Reservation Entry";
        HasChanged: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDataHasChanged(TemplateName, BatchName, ProdOrderNo, ProdOrderLineNo, HasChanged, IsHandled);
        if IsHandled then
            exit(HasChanged);

        ItemJnlLine2.Reset();
        ItemJnlLine2.SetRange("Journal Template Name", TemplateName);
        ItemJnlLine2.SetRange("Journal Batch Name", BatchName);
        ItemJnlLine2.SetRange("Order Type", ItemJnlLine2."Order Type"::Production);
        ItemJnlLine2.SetRange("Order No.", ProdOrderNo);
        if ProdOrderLineNo <> 0 then
            ItemJnlLine2.SetRange("Order Line No.", ProdOrderLineNo);
        if ItemJnlLine2.Find('-') then
            repeat
                if ItemJnlLine2."Changed by User" then
                    exit(true);
                if ReservEntryExist(ItemJnlLine2, ReservEntry) then
                    exit(true);
            until ItemJnlLine2.Next() = 0;

        HasChanged := false;
        OnAfterDataHasChanged(ItemJnlLine2, ProdOrderLineNo, HasChanged);
        exit(HasChanged);
    end;

    procedure ReservEntryExist(ItemJnlLine2: Record "Item Journal Line"; var ReservEntry: Record "Reservation Entry"): Boolean
    begin
        ReservEntry.Reset();
        ReservEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line");
        ReservEntry.SetRange("Source ID", ItemJnlLine2."Journal Template Name");
        ReservEntry.SetRange("Source Ref. No.", ItemJnlLine2."Line No.");
        ReservEntry.SetRange("Source Type", DATABASE::"Item Journal Line");
        ReservEntry.SetRange("Source Subtype", ItemJnlLine2."Entry Type");
        ReservEntry.SetRange("Source Batch Name", ItemJnlLine2."Journal Batch Name");
        ReservEntry.SetRange("Source Prod. Order Line", 0);
        if not ReservEntry.IsEmpty() then
            exit(true);

        exit(false);
    end;

    procedure SetNextLineNo(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.LockTable();
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Journal Template Name", ToTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", ToBatchName);
        if ItemJournalLine.FindLast() then
            NextLineNo := ItemJournalLine."Line No." + 10000
        else
            NextLineNo := 10000;
    end;

    procedure GetJnlTemplateAndBatchName(var TemplateName: Code[10]; var BatchName: Code[10])
    begin
        TemplateName := ToTemplateName;
        BatchName := ToBatchName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateQtyToPostForProdOrder(ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var QtyToPost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDataHasChanged(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLineNo: Integer; var HasChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSetupValues(var PostingDate: Date; var CalcBasedOn: Option "Actual Output","Expected Output")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertConsumptionJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertOutputJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsLastOperation(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsLastOperation: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTemplateAndBatchName(var ItemJournalTemplate: Record "Item Journal Template"; var User: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertConsumptionJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderComp: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; Level: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOutputJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAllItemJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandling(ProdOrder: Record "Production Order"; ActualLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecursiveInsertOutputJnlLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; var DoRecursion: Boolean; var AdditionalProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunProductionJnl(ToTemplateName: Code[10]; ToBatchName: Code[10]; ProdOrder: Record "Production Order"; ActualLineNo: Integer; var PostingDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJnlLinesOnAfterFindProdOrderRtngLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJnlLinesOnBeforeCheckProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJnlLinesOnAfterProdOrderRtngLineSetFilters(var ProdOrderRtngLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumptionJnlLineOnBeforeCheck(ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumptionItemJnlLineOnAfterCalcShouldAdjustQty(ProdOrderComp: Record "Prod. Order Component"; Location: Record Location; var NeededQty: Decimal; var ShouldAdjustQty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumptionJnlLineOnAfterItemJnlLineInit(var ItemJournalLine: Record "Item Journal Line"; ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumptionItemJnlLineOnAfterCopyItemTracking(var ItemJournalLine: Record "Item Journal Line"; ItemTrackingCode: Code[10]; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOutputItemJnlLine(ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteJnlLines(TemplateName: Code[10]; BatchName: Code[10]; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTemplateAndBatchName(var ToTemplateName: Code[10]; var ToBatchName: Code[10]; var IsHandled: Boolean; var PageID: Integer; var PageTemplate: Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod. Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertConsumptionItemJnlLineOnBeforeValidateQuantity(var ItemJnlLine: Record "Item Journal Line"; ProdOrderComp: Record "Prod. Order Component"; NeededQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOutputItemJnlLineOnBeforeSubcontractingWorkCenterUsed(var ItemJnlLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOutputItemJnlLineOnAfterCopyItemTracking(var ItemJnlLine: Record "Item Journal Line"; ProdOrderRtngLine: Record "Prod. Order Routing Line"; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOutputItemJnlLineOnAfterItemJnlLineInit(var ItemJnlLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJnlLinesOnBeforeInsertComponents(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertComponentsOnAfterProdOrderCompSetFilters(var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoutingLinkValid(ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOutputItemJnlLineOnAfterAssignTimes(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var QtyToPost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertComponents(ProdOrderLine: Record "Prod. Order Line"; CheckRoutingLink: Boolean; Level: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJnlLinesOnAfterSetProdOrderLineFilters(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteJnlLinesOnAfterSetFilters(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDataHasChanged(TemplateName: Code[10]; BatchName: Code[10]; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; var HasChanged: Boolean; var IsHandled: Boolean)
    begin
    end;
}

