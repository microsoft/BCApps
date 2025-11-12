// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Planning;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Reflection;
using System.Text;

codeunit 5520 "Get Unplanned Demand"
{
#if not CLEAN28
    Permissions = TableData Microsoft.Manufacturing.Document."Production Order" = r,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Component" = r,
                  TableData Microsoft.Manufacturing.Document."Prod. Order Capacity Need" = r;
#endif
    TableNo = "Unplanned Demand";

    trigger OnRun()
#if not CLEAN27
    var
        ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component";
#endif
    begin
        if IncludeMetDemandForSpecificSalesOrderNo <> '' then
            SetFilterToSpecificSalesOrder();

        if IncludeMetDemandForSpecificJobNo <> '' then
            SetFilterToSpecificJob();

        Rec.DeleteAll();
        SalesLine.SetFilter("Document Type", '%1|%2', SalesLine."Document Type"::Order, SalesLine."Document Type"::"Return Order");
        JobPlanningLine.SetRange(Status, JobPlanningLine.Status::Order);
        RecordCounter := SalesLine.Count() + JobPlanningLine.Count();
#if not CLEAN27
        ProdOrderComp.SetFilter(
            Status, '%1|%2|%3', ProdOrderComp.Status::Planned, ProdOrderComp.Status::"Firm Planned", ProdOrderComp.Status::Released);
        OnBeforeOpenPlanningWindow(RecordCounter, ProdOrderComp);
#endif
        OnBeforeOpenWindow(RecordCounter);
        OpenWindow(ProgressMsg, RecordCounter);

        GetUnplannedSalesLine(Rec);
        GetUnplannedJobPlanningLine(Rec);

        OnAfterGetUnplanned(Rec, ItemFilter);

        OnBeforeClosePlanningWindow(Rec, Window, NoOfRecords);
        Window.Close();

        Rec.Reset();
        Rec.SetCurrentKey("Demand Date", Level);
        Rec.SetRange(Level, 1);
        OpenWindow(ProgressMsg, Rec.Count());
        CalcNeededDemands(Rec);
        Window.Close();
    end;

    var
        SalesLine: Record "Sales Line";
        JobPlanningLine: Record "Job Planning Line";
        ItemFilter: TextBuilder;
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        NoOfRecords: Integer;
        i: Integer;
        DemandQtyBase: Decimal;
        IncludeMetDemandForSpecificSalesOrderNo: Code[20];
        IncludeMetDemandForSpecificJobNo: Code[20];
        RecordCounter: Integer;
        ProgressMsg: Label 'Determining Unplanned Orders @1@@@@@@@';

    procedure SetIncludeMetDemandForSpecificSalesOrderNo(SalesOrderNo: Code[20])
    begin
        IncludeMetDemandForSpecificSalesOrderNo := SalesOrderNo;
    end;

    procedure SetIncludeMetDemandForSpecificJobNo(JobNo: Code[20])
    begin
        IncludeMetDemandForSpecificJobNo := JobNo;
    end;

    local procedure SetFilterToSpecificSalesOrder()
    var
        SalesOrderLine: Record "Sales Line";
        TempItem: Record Item temporary;
        TypeHelper: Codeunit "Type Helper";
        ItemNoList: List of [Code[20]];
    begin
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);

        SalesOrderLine.SetRange("Document No.", IncludeMetDemandForSpecificSalesOrderNo);
        SalesOrderLine.SetRange("Document Type", SalesOrderLine."Document Type"::Order);
        SalesOrderLine.SetRange(Type, SalesOrderLine.Type::Item);
        SalesOrderLine.SetLoadFields("No.");

        if SalesOrderLine.FindSet() then begin
            repeat
                // Find all the items needed to be planned and add it to a temp item bufffer
                OnSetFilterToSpecificSalesOrderOnBeforeTempItemGet(TempItem, SalesOrderLine);
                if not ItemNoList.Contains(SalesOrderLine."No.") then
                    ItemNoList.Add(SalesOrderLine."No.");
                TempItem."No." := SalesOrderLine."No."; // only to preserve same behavior regards to event OnSetFilterToSpecificSalesOrderOnBeforeTempItemGet() 
            until SalesOrderLine.Next() = 0;

            if ItemNoList.Count() >= (TypeHelper.GetMaxNumberOfParametersInSQLQuery() - 100) then
                exit;

            // Build a filter string from the temporary item buffer
            if ItemNoList.Count() = 0 then
                exit;

            CreateItemFilter(ItemNolist);
            SalesLine.SetFilter("No.", ItemFilter.ToText());
            JobPlanningLine.SetFilter("No.", ItemFilter.ToText());

            OnAfterSetFilterToSpecificSalesOrder(ItemFilter.ToText())
        end;
    end;

    local procedure SetFilterToSpecificJob()
    var
        ItemPlanningLine: Record "Job Planning Line";
        TempItem: Record Item temporary;
        TypeHelper: Codeunit "Type Helper";
        ItemNoList: List of [Code[20]];
    begin
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);

        ItemPlanningLine.SetRange("Job No.", IncludeMetDemandForSpecificJobNo);
        ItemPlanningLine.SetRange(Status, ItemPlanningLine.Status::Order);
        ItemPlanningLine.SetRange(Type, ItemPlanningLine.Type::Item);
        ItemPlanningLine.SetFilter("No.", '<>%1', '');
        ItemPlanningLine.SetLoadFields("No.");

        if ItemPlanningLine.FindSet() then begin
            repeat
                // Find all the items needed to be planned and add it to a temp item bufffer
                if not ItemNoList.Contains(ItemPlanningLine."No.") then
                    ItemNoList.Add(ItemPlanningLine."No.");
                TempItem."No." := ItemPlanningLine."No."; // only to preserve same behavior regards to event OnSetFilterToSpecificSalesOrderOnBeforeTempItemGet() 
            until ItemPlanningLine.Next() = 0;

            if ItemNoList.Count() >= (TypeHelper.GetMaxNumberOfParametersInSQLQuery() - 100) then
                exit;

            // Build a filter string from the temporary item buffer
            if ItemNoList.Count() = 0 then
                exit;

            CreateItemFilter(ItemNolist);
            JobPlanningLine.SetFilter("No.", ItemFilter.ToText());
            SalesLine.SetFilter("No.", ItemFilter.ToText());
        end;
    end;

    local procedure CreateItemFilter(ItemNoList: List of [Code[20]])
    var
        SelectionFilterMgt: Codeunit SelectionFilterManagement;
        ItemNo: Code[20];
    begin
        foreach ItemNo in ItemNolist do begin
            if ItemFilter.Length > 0 then
                ItemFilter.Append('|');
            ItemFilter.Append(SelectionFilterMgt.AddQuotes(ItemNo));
        end;
    end;

    local procedure GetUnplannedSalesLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        OnBeforeGetUnplannedSalesLine(UnplannedDemand, SalesLine);

        if SalesLine.FindSet() then
            repeat
                UpdateWindow();
                DemandQtyBase := GetSalesLineNeededQty(SalesLine);
                OnGetUnplannedSalesLineOnBeforeCheckDemandQtyBase(SalesLine, IsHandled);
                if not IsHandled then
                    if DemandQtyBase > 0 then begin
                        if not ((SalesLine."Document Type".AsInteger() = UnplannedDemand."Demand SubType") and
                                (SalesLine."Document No." = UnplannedDemand."Demand Order No."))
                        then begin
                            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                            InsertUnplannedDemand(
                            UnplannedDemand, UnplannedDemand."Demand Type"::Sales, SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesHeader.Status.AsInteger());
                            OnGetUnplannedSalesLineOnAfterInsertUnplannedDemand(SalesLine, UnplannedDemand);
                        end;
                        InsertSalesLine(UnplannedDemand);
                        OnGetUnplannedDemandOnAfterInsertSalesLine(UnplannedDemand, SalesLine);
                    end;
            until SalesLine.Next() = 0;
    end;

    local procedure GetUnplannedJobPlanningLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        Job: Record Job;
    begin
        OnBeforeGetUnplannedJobPlanningLine(UnplannedDemand, JobPlanningLine);

        if JobPlanningLine.FindSet() then
            repeat
                UpdateWindow();
                DemandQtyBase := GetJobPlanningLineNeededQty(JobPlanningLine);
                if DemandQtyBase > 0 then begin
                    if not ((JobPlanningLine.Status.AsInteger() = UnplannedDemand."Demand SubType") and
                            (JobPlanningLine."Job No." = UnplannedDemand."Demand Order No."))
                    then begin
                        Job.Get(JobPlanningLine."Job No.");
                        InsertUnplannedDemand(
                          UnplannedDemand, UnplannedDemand."Demand Type"::Job, JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", Job.Status.AsInteger());
                        OnGetUnplannedJobPlanningLineOnAfterInsertUnplannedDemand(UnplannedDemand);
                    end;
                    InsertJobPlanningLine(UnplannedDemand);
                end;
            until JobPlanningLine.Next() = 0;
    end;

    local procedure GetSalesLineNeededQty(SalesLine: Record "Sales Line") NeededQty: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSalesLineNeededQty(SalesLine, NeededQty, IsHandled);
        if IsHandled then
            exit(NeededQty);

        if SalesLine.Planned or (SalesLine."No." = '') or (SalesLine.Type <> SalesLine.Type::Item) or SalesLine."Special Order" then
            exit(0);

        SalesLine.CalcFields("Reserved Qty. (Base)");
        exit(-SalesLine.SignedXX(SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)"));
    end;

    local procedure GetJobPlanningLineNeededQty(JobPlanningLine: Record "Job Planning Line") NeededQty: Decimal
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetJobPlanningLineNeededQty(JobPlanningLine, NeededQty, IsHandled);
        if IsHandled then
            exit(NeededQty);

        if JobPlanningLine.Planned or (JobPlanningLine."No." = '') or (JobPlanningLine.Type <> JobPlanningLine.Type::Item) or JobPlanningLine.IsNonInventoriableItem() then
            exit(0);

        JobPlanningLine.CalcFields(JobPlanningLine."Reserved Qty. (Base)");
        NeededQty := JobPlanningLine."Remaining Qty. (Base)" - JobPlanningLine."Reserved Qty. (Base)";

        if NeededQty > 0 then begin
            PurchaseLine.SetLoadFields("Outstanding Qty. (Base)");
            PurchaseLine.SetRange("Job No.", JobPlanningLine."Job No.");
            PurchaseLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
            PurchaseLine.SetRange("Job Planning Line No.", JobPlanningLine."Line No.");
            if PurchaseLine.FindFirst() then
                NeededQty -= PurchaseLine."Outstanding Qty. (Base)";
        end;
        if NeededQty < 0 then
            NeededQty := 0;
        exit(NeededQty);
    end;

    local procedure InsertSalesLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        UnplannedDemand2.Copy(UnplannedDemand);
        UnplannedDemand.InitRecord(
          SalesLine."Line No.", 0, SalesLine."No.", SalesLine.Description, SalesLine."Variant Code", SalesLine."Location Code",
          SalesLine."Bin Code", SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure",
          DemandQtyBase, SalesLine."Shipment Date");
        OnInsertSalesLineOnAfterInitRecord(UnplannedDemand, SalesLine);
        UnplannedDemand.Reserve := SalesLine.Reserve = SalesLine.Reserve::Always;
        UnplannedDemand."Special Order" := SalesLine."Special Order";
        UnplannedDemand."Purchasing Code" := SalesLine."Purchasing Code";
        UnplannedDemand."Drop Shipment" := SalesLine."Drop Shipment";
        OnInsertSalesLineOnBeforeInsert(UnplannedDemand, SalesLine);
        UnplannedDemand.Insert();
        UnplannedDemand.Copy(UnplannedDemand2);
    end;

    local procedure InsertJobPlanningLine(var UnplannedDemand: Record "Unplanned Demand")
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        UnplannedDemand2.Copy(UnplannedDemand);
        UnplannedDemand.InitRecord(
          JobPlanningLine."Job Contract Entry No.", 0, JobPlanningLine."No.", JobPlanningLine.Description, JobPlanningLine."Variant Code",
          JobPlanningLine."Location Code", JobPlanningLine."Bin Code", JobPlanningLine."Unit of Measure Code",
          JobPlanningLine."Qty. per Unit of Measure", DemandQtyBase, JobPlanningLine."Planning Date");
        UnplannedDemand.Reserve := JobPlanningLine.Reserve = JobPlanningLine.Reserve::Always;
        OnInsertJobPlanningLineOnBeforeInsert(UnplannedDemand, JobPlanningLine);
        UnplannedDemand.Insert();
        UnplannedDemand.Copy(UnplannedDemand2);
    end;

    procedure InsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; DemandType: Enum "Unplanned Demand Type"; DemandSubtype: Integer; DemandOrderNo: Code[20]; DemandStatus: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertUnplannedDemand(UnplannedDemand, DemandType, DemandSubtype, DemandOrderNo, DemandStatus, IsHandled);
        if IsHandled then
            exit;

        UnplannedDemand.Init();
        UnplannedDemand."Demand Type" := DemandType;
        UnplannedDemand."Demand SubType" := DemandSubtype;
        UnplannedDemand.Validate("Demand Order No.", DemandOrderNo);
        UnplannedDemand.Status := DemandStatus;
        UnplannedDemand.Level := 0;
        UnplannedDemand.Insert();
    end;

    local procedure CalcNeededDemands(var UnplannedDemand: Record "Unplanned Demand")
    var
        TempUnplannedDemand: Record "Unplanned Demand" temporary;
        JobPlanningLine: Record "Job Planning Line";
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
        HeaderExists: Boolean;
        ForceIncludeDemand: Boolean;
        NeededQtyBase: Decimal;
        TotalNeedQuantityBase: Decimal;
        ReducedJobQtyReceivedNotInvoiced: Decimal;
        IsHandled: Boolean;
    begin
        UnplannedDemand.Reset();
        MoveUnplannedDemand(UnplannedDemand, TempUnplannedDemand);

        TempUnplannedDemand.SetCurrentKey("Demand Date", Level);
        TempUnplannedDemand.SetRange(Level, 1);
        while TempUnplannedDemand.Find('-') do begin
            HeaderExists := false;
            repeat
                UpdateWindow();
                UnplannedDemand := TempUnplannedDemand;

                IsHandled := false;
                OnCalcNeededDemandsOnBeforeCalcNeededQtyBase(UnplannedDemand, IsHandled);
                if not IsHandled then
                    if UnplannedDemand."Special Order" or UnplannedDemand."Drop Shipment" then
                        UnplannedDemand."Needed Qty. (Base)" := TempUnplannedDemand."Quantity (Base)"
                    else
                        UnplannedDemand."Needed Qty. (Base)" :=
                          OrderPlanningMgt.CalcNeededQty(
                            OrderPlanningMgt.CalcATPQty(TempUnplannedDemand."Item No.", TempUnplannedDemand."Variant Code", TempUnplannedDemand."Location Code", TempUnplannedDemand."Demand Date") +
                            CalcDemand(TempUnplannedDemand, false) + CalcDemand(UnplannedDemand, true),
                            TempUnplannedDemand."Quantity (Base)");

                if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Job then begin
                    GetJobTask(UnplannedDemand, JobPlanningLine);
                    NeededQtyBase := UnplannedDemand."Needed Qty. (Base)";
                    ReducedJobQtyReceivedNotInvoiced := ReduceJobRealtedQtyReceivedNotInvoiced(UnplannedDemand."Demand Order No.", JobPlanningLine."Job Task No.", TempUnplannedDemand."Item No.", TempUnplannedDemand."Variant Code", TempUnplannedDemand."Location Code", TempUnplannedDemand."Demand Date");
                    UnplannedDemand."Needed Qty. (Base)" -= ReducedJobQtyReceivedNotInvoiced;
                    TotalNeedQuantityBase += NeededQtyBase;

                    if (UnplannedDemand."Needed Qty. (Base)" < 0) and ((ReducedJobQtyReceivedNotInvoiced - TotalNeedQuantityBase) < 0) then
                        UnplannedDemand."Needed Qty. (Base)" := NeededQtyBase;

                    UnplannedDemand."Quantity (Base)" := JobPlanningLine."Remaining Qty. (Base)" - JobPlanningLine."Reserved Qty. (Base)";
                end;

                ForceIncludeDemand :=
                  (UnplannedDemand."Demand Order No." = IncludeMetDemandForSpecificSalesOrderNo) and
                  (UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Sales) and
                  (UnplannedDemand."Demand SubType" = SalesLine."Document Type"::Order.AsInteger());

                OnCalcNeededDemandsOnAfterCalcForceIncludeDemand(UnplannedDemand, ForceIncludeDemand);
                if ForceIncludeDemand or (UnplannedDemand."Needed Qty. (Base)" > 0)
                then begin
                    UnplannedDemand.Insert();
                    if not HeaderExists then begin
                        InsertUnplannedDemandHeader(TempUnplannedDemand, UnplannedDemand);
                        HeaderExists := true;
                        TempUnplannedDemand.SetRange("Demand Type", TempUnplannedDemand."Demand Type");
                        TempUnplannedDemand.SetRange("Demand SubType", TempUnplannedDemand."Demand SubType");
                        TempUnplannedDemand.SetRange("Demand Order No.", TempUnplannedDemand."Demand Order No.");
                    end;
                end;
                TempUnplannedDemand.Delete();
            until TempUnplannedDemand.Next() = 0;
            TempUnplannedDemand.SetRange("Demand Type");
            TempUnplannedDemand.SetRange("Demand SubType");
            TempUnplannedDemand.SetRange("Demand Order No.");
        end;
    end;

    local procedure GetJobTask(var UnplannedDemand: Record "Unplanned Demand"; var JobPlanningLine: Record "Job Planning Line")
    begin
        Clear(JobPlanningLine);

        JobPlanningLine.SetLoadFields("Job Task No.", "Remaining Qty. (Base)", Status, "Job Contract Entry No.");
        JobPlanningLine.SetRange("Job No.", UnplannedDemand."Demand Order No.");
        JobPlanningLine.SetRange("Job Contract Entry No.", UnplannedDemand."Demand Line No.");
        if not JobPlanningLine.FindFirst() then
            exit;

        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
    end;

    local procedure ReduceJobRealtedQtyReceivedNotInvoiced(JobNo: Code[20]; JobTaskNo: Code[20]; ItemNo: Text[250]; VariantFilter: Text[250]; LocationFilter: Text[250]; DemandDate: Date): Decimal
    var
        Item: Record Item;
    begin
        if ItemNo = '' then
            exit(0);

        Item.Get(ItemNo);
        Item.SetRange("Variant Filter", VariantFilter);
        Item.SetRange("Location Filter", LocationFilter);
        Item.SetRange("Date Filter", 0D, DemandDate);
        Item.SetRange("Drop Shipment Filter", false);
        exit(QtyOnPurchReceiptNotInvoiced(Item, JobNo, JobTaskNo));
    end;

    local procedure QtyOnPurchReceiptNotInvoiced(var Item: Record Item; JobNo: Code[20]; JobTaskNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetLoadFields("Qty. Rcd. Not Invoiced (Base)");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.SetRange("Job No.", JobNo);
        if JobTaskNo <> '' then
            PurchaseLine.SetRange("Job Task No.", JobTaskNo);
        PurchaseLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        PurchaseLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        PurchaseLine.SetFilter("Drop Shipment", Item.GetFilter("Drop Shipment Filter"));
        PurchaseLine.SetFilter("Expected Receipt Date", Item.GetFilter("Date Filter"));
        PurchaseLine.SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        PurchaseLine.SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        PurchaseLine.SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));
        PurchaseLine.CalcSums("Qty. Rcd. Not Invoiced (Base)");
        exit(PurchaseLine."Qty. Rcd. Not Invoiced (Base)");
    end;

    local procedure CalcDemand(var UnplannedDemand: Record "Unplanned Demand"; Planned: Boolean) DemandQty: Decimal
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        UnplannedDemand2.Copy(UnplannedDemand);
        UnplannedDemand.Reset();
        UnplannedDemand.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Demand Date");
        UnplannedDemand.SetRange("Item No.", UnplannedDemand."Item No.");
        UnplannedDemand.SetRange("Variant Code", UnplannedDemand."Variant Code");
        UnplannedDemand.SetRange("Location Code", UnplannedDemand."Location Code");

        if Planned then begin
            UnplannedDemand.SetRange("Demand Date", 0D, UnplannedDemand."Demand Date");
            UnplannedDemand.CalcSums("Needed Qty. (Base)");
            DemandQty := UnplannedDemand."Needed Qty. (Base)";
        end else begin
            UnplannedDemand.SetRange("Demand Date", UnplannedDemand."Demand Date");
            UnplannedDemand.CalcSums("Quantity (Base)");
            DemandQty := UnplannedDemand."Quantity (Base)";
        end;
        UnplannedDemand.Copy(UnplannedDemand2);
    end;

    local procedure MoveUnplannedDemand(var FromUnplannedDemand: Record "Unplanned Demand"; var ToUnplannedDemand: Record "Unplanned Demand")
    begin
        ToUnplannedDemand.DeleteAll();
        if FromUnplannedDemand.Find('-') then
            repeat
                ToUnplannedDemand := FromUnplannedDemand;
                ToUnplannedDemand.Insert();
                FromUnplannedDemand.Delete();
            until FromUnplannedDemand.Next() = 0;
    end;

    local procedure InsertUnplannedDemandHeader(var FromUnplannedDemand: Record "Unplanned Demand"; var ToUnplannedDemand: Record "Unplanned Demand")
    var
        UnplannedDemand2: Record "Unplanned Demand";
    begin
        UnplannedDemand2.Copy(FromUnplannedDemand);

        FromUnplannedDemand.Reset();
        FromUnplannedDemand.SetRange("Demand Type", FromUnplannedDemand."Demand Type");
        FromUnplannedDemand.SetRange("Demand SubType", FromUnplannedDemand."Demand SubType");
        FromUnplannedDemand.SetRange("Demand Order No.", FromUnplannedDemand."Demand Order No.");
        FromUnplannedDemand.SetRange(Level, 0);
        FromUnplannedDemand.Find('-');
        ToUnplannedDemand := FromUnplannedDemand;
        ToUnplannedDemand."Demand Date" := UnplannedDemand2."Demand Date";
        ToUnplannedDemand.Insert();

        FromUnplannedDemand.Copy(UnplannedDemand2);
    end;

    local procedure OpenWindow(DisplayText: Text[250]; NoOfRecords2: Integer)
    begin
        i := 0;
        NoOfRecords := NoOfRecords2;
        WindowUpdateDateTime := CurrentDateTime;
        Window.Open(DisplayText);
    end;

    procedure UpdateWindow()
    begin
        i := i + 1;
        if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, Round(i / NoOfRecords * 10000, 1));
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetUnplanned(var UnplannedDemand: Record "Unplanned Demand"; var ItemFilter: TextBuilder);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesLineNeededQty(SalesLine: Record "Sales Line"; var NeededQty: Decimal; var IsHandled: Boolean);
    begin
    end;

#if not CLEAN27
    [Obsolete('Replaced by event OnBeforeOpenWindow', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenPlanningWindow(var RecordCounter: Integer; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenWindow(var RecordCounter: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClosePlanningWindow(UnplannedDemand: Record "Unplanned Demand"; var Window: Dialog; NoOfRecords: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedSalesLine(var UnplannedDemand: Record "Unplanned Demand"; var SalesLine: Record "Sales Line");
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeGetUnplannedProdOrderComp(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component");
    begin
        OnBeforeGetUnplannedProdOrderComp(UnplannedDemand, ProdOrderComponent);
    end;

    [Obsolete('Moved to codeunit ProdOrderLinePlanning', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedProdOrderComp(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component");
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeGetUnplannedAsmLine(var UnplannedDemand: Record "Unplanned Demand"; var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line");
    begin
        OnBeforeGetUnplannedAsmLine(UnplannedDemand, AssemblyLine);
    end;

    [Obsolete('Moved to codeunit AssemblyLinePlanning', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedAsmLine(var UnplannedDemand: Record "Unplanned Demand"; var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line");
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeGetUnplannedServLine(var UnplannedDemand: Record "Unplanned Demand"; var ServiceLine: Record Microsoft.Service.Document."Service Line");
    begin
        OnBeforeGetUnplannedServLine(UnplannedDemand, ServiceLine);
    end;

    [Obsolete('Moved to codeunit ServiceLinePlanning', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedServLine(var UnplannedDemand: Record "Unplanned Demand"; var ServiceLine: Record Microsoft.Service.Document."Service Line");
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedJobPlanningLine(var UnplannedDemand: Record "Unplanned Demand"; var JobPlanningLine: Record "Job Planning Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; DemandType: Enum "Unplanned Demand Type"; DemandSubtype: Integer; DemandOrderNo: Code[20]; DemandStatus: Integer; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeGetProdOrderCompNeededQty(ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var NeededQty: Decimal; var IsHandled: Boolean);
    begin
        OnBeforeGetProdOrderCompNeededQty(ProdOrderComponent, NeededQty, IsHandled);
    end;

    [Obsolete('Moved to codeunit ProdOrderLinePlanning', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetProdOrderCompNeededQty(ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var NeededQty: Decimal; var IsHandled: Boolean);
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCalcNeededDemandsOnAfterCalcForceIncludeDemand(var UnplannedDemand: Record "Unplanned Demand"; var ForceIncludeDemand: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnGetUnplannedAsmLineOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
        OnGetUnplannedAsmLineOnAfterInsertUnplannedDemand(UnplannedDemand);
    end;

    [Obsolete('Moved to codeunit AssemblyLinePlanning', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedAsmLineOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedSalesLineOnBeforeCheckDemandQtyBase(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedJobPlanningLineOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnGetUnplannedServLineOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
        OnGetUnplannedServLineOnAfterInsertUnplannedDemand(UnplannedDemand);
    end;

    [Obsolete('Moved to codeunit ServiceLinePlanning', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedServLineOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedSalesLineOnAfterInsertUnplannedDemand(var SalesLine: Record "Sales Line"; var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnGetUnplannedProdOrderCompOnAfterCalcNeedInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComp2: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var NeedInsertUnplannedDemand: Boolean)
    begin
        OnGetUnplannedProdOrderCompOnAfterCalcNeedInsertUnplannedDemand(UnplannedDemand, ProdOrderComp2, NeedInsertUnplannedDemand);
    end;

    [Obsolete('Moved to codeunit ProdOrderLinePlanning', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedProdOrderCompOnAfterCalcNeedInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var NeedInsertUnplannedDemand: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnGetUnplannedProdOrderCompOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComp2: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnGetUnplannedProdOrderCompOnAfterInsertUnplannedDemand(UnplannedDemand, ProdOrderComp2);
    end;

    [Obsolete('Moved to codeunit ProdOrderLinePlanning', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedProdOrderCompOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnGetUnplannedProdOrderCompOnAfterInsertProdOrderCompLine(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComp2: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnGetUnplannedProdOrderCompOnAfterInsertProdOrderCompLine(UnplannedDemand, ProdOrderComp2);
    end;

    [Obsolete('Moved to codeunit ProdOrderLinePlanning', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedProdOrderCompOnAfterInsertProdOrderCompLine(var UnplannedDemand: Record "Unplanned Demand"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterToSpecificSalesOrder(ItemFilter: Text)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnInsertAsmLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
        OnInsertAsmLineOnBeforeInsert(UnplannedDemand, AssemblyLine);
    end;

    [Obsolete('Moved to codeunit AssemblyLinePlanning', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInsertAsmLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnInsertProdOrderCompLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnInsertProdOrderCompLineOnBeforeInsert(UnplannedDemand, ProdOrderComponent);
    end;

    [Obsolete('Moved to codeunit ProdOrderLinePlanning', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderCompLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnInsertSalesLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; SalesLine: Record "Sales Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnInsertServLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnInsertServLineOnBeforeInsert(UnplannedDemand, ServiceLine);
    end;

    [Obsolete('Moved to codeunit ServiceLinePlanning', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInsertServLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnInsertJobPlanningLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertSalesLineOnAfterInitRecord(var UnplannedDemand: Record "Unplanned Demand"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFilterToSpecificSalesOrderOnBeforeTempItemGet(var TempItem: Record Item temporary; SalesOrderLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetJobPlanningLineNeededQty(JobPlanningLine: Record "Job Planning Line"; var NeededQty: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcNeededDemandsOnBeforeCalcNeededQtyBase(var UnplannedDemand: Record "Unplanned Demand"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedDemandOnAfterInsertSalesLine(var UnplannedDemand: Record "Unplanned Demand"; var SalesLine: Record "Sales Line")
    begin
    end;
}

