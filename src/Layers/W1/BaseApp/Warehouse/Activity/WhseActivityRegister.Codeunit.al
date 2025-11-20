// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Utilities;

codeunit 7307 "Whse.-Activity-Register"
{
    Permissions = TableData "Registered Whse. Activity Hdr." = ri,
                  TableData "Registered Whse. Activity Line" = ri,
                  TableData "Whse. Item Tracking Line" = rim,
                  TableData "Warehouse Journal Batch" = rimd,
                  TableData "Posted Whse. Receipt Header" = rm,
                  TableData "Posted Whse. Receipt Line" = rm,
                  TableData "Registered Invt. Movement Hdr." = ri,
                  TableData "Registered Invt. Movement Line" = ri;
    TableNo = "Warehouse Activity Line";

    trigger OnRun()
    begin
        GlobalWhseActivLine.Copy(Rec);
        GlobalWhseActivLine.SetAutoCalcFields();
        Code();
        Rec := GlobalWhseActivLine;
    end;

    var
        Location: Record Location;
        Item: Record Item;
        GlobalWhseActivHeader: Record "Warehouse Activity Header";
        GlobalWhseActivLine: Record "Warehouse Activity Line";
        RegisteredWhseActivHeader: Record "Registered Whse. Activity Hdr.";
        RegisteredWhseActivLine: Record "Registered Whse. Activity Line";
        RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
        WhseShptHeader: Record "Warehouse Shipment Header";
        PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        JobPlanningLine: Record "Job Planning Line";
        Job: Record "Job";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TempBinContentBuffer: Record "Bin Content Buffer" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        Cust: Record Customer;
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
        Window: Dialog;
        NoOfRecords: Integer;
        LineCount: Integer;
        HideDialog: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Warehouse Activity    #1##########\\';
        Text001: Label 'Checking lines        #2######\';
        Text002: Label 'Registering lines     #3###### @4@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'There is nothing to register.';
#pragma warning restore AA0074
        InsufficientQtyItemTrkgErr: Label 'Item tracking defined for source line %1 of %2 %3 amounts to more than the quantity you have entered.\\You must adjust the existing item tracking specification and then reenter a new quantity.', Comment = '%1=Source Line No.,%2=Source Document,%3=Source No.';
#pragma warning disable AA0470
        InventoryNotAvailableErr: Label '%1 %2 is not available on inventory or it has already been reserved for another document.';
#pragma warning restore AA0470
        ItemAlreadyConsumedErr: Label 'Cannot register pick for more than %1 %2 for %3 %4. %5 %6 is partially or completely consumed in %7 of %8 %9 %10.', Comment = 'Cannot Register Pick for more than %1=3 %2=BOX for %3=Line No %4=10000. %5=Item, %6=Item No. is partially or completely consumed in the %7=Project Usage of %8=Project No. %9=Source Line No. %10=Project Contract Entry No.';
        OrderToOrderBindingOnSalesLineQst: Label 'Registering the pick will remove the existing order-to-order reservation for the sales order.\Do you want to continue?';
        RegisterInterruptedErr: Label 'The action has been interrupted to respect the warning.';
        SuppressCommit: Boolean;

    local procedure "Code"()
    var
        OldWhseActivLine: Record "Warehouse Activity Line";
        TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary;
        TempWhseActivityLineGrouped: Record "Warehouse Activity Line" temporary;
        SkipDelete: Boolean;
        ShouldDeleteOldLine: Boolean;
    begin
        OnBeforeCode(GlobalWhseActivLine);

        GlobalWhseActivLine.SetRange("Activity Type", GlobalWhseActivLine."Activity Type");
        GlobalWhseActivLine.SetRange("No.", GlobalWhseActivLine."No.");
        GlobalWhseActivLine.SetFilter("Qty. to Handle (Base)", '<>0');

        CheckWhseActivLineIsEmpty(GlobalWhseActivLine);

        MaintainZeroLines(GlobalWhseActivLine);

        CheckWhseItemTrkgLine(GlobalWhseActivLine);

        GlobalWhseActivHeader.Get(GlobalWhseActivLine."Activity Type", GlobalWhseActivLine."No.");
        LocationGet(GlobalWhseActivHeader."Location Code");

        UpdateWindow(1, GlobalWhseActivHeader."No.");
        // Check Lines
        CheckLines();
        OnCodeOnAfterCheckLines(GlobalWhseActivHeader);
        // Register lines
        SourceCodeSetup.Get();
        LineCount := 0;
        CreateRegActivHeader(GlobalWhseActivHeader);

        TempWhseActivLineToReserve.DeleteAll();
        TempWhseActivityLineGrouped.DeleteAll();

        GlobalWhseActivLine.ReadIsolation(IsolationLevel::UpdLock);

        // breakbulk first to provide quantity for pick lines in smaller UoM
        GlobalWhseActivLine.SetFilter("Breakbulk No.", '<>0');
        RegisterWhseActivityLines(GlobalWhseActivLine, TempWhseActivLineToReserve, TempWhseActivityLineGrouped);

        GlobalWhseActivLine.SetRange("Breakbulk No.", 0);
        RegisterWhseActivityLines(GlobalWhseActivLine, TempWhseActivLineToReserve, TempWhseActivityLineGrouped);
        GlobalWhseActivLine.SetRange("Breakbulk No.");

        OnCodeOnBeforeTempWhseActivityLineGroupedLoop(GlobalWhseActivHeader, GlobalWhseActivLine, RegisteredWhseActivHeader, TempWhseActivityLineGrouped);
        TempWhseActivityLineGrouped.Reset();
        if TempWhseActivityLineGrouped.FindSet() then
            repeat
                if GlobalWhseActivHeader.Type <> GlobalWhseActivHeader.Type::Movement then
                    UpdateWhseSourceDocLine(TempWhseActivityLineGrouped);
                UpdateWhseDocHeader(TempWhseActivityLineGrouped);
                TempWhseActivityLineGrouped.DeleteBinContent(Enum::"Warehouse Action Type"::Take.AsInteger());
            until TempWhseActivityLineGrouped.Next() = 0;

        SyncItemTrackingAndReserveSourceDocument(TempWhseActivLineToReserve);

        if Location."Bin Mandatory" then begin
            LineCount := 0;
            Clear(OldWhseActivLine);
            GlobalWhseActivLine.Reset();
            GlobalWhseActivLine.SetCurrentKey(
              "Activity Type", "No.", "Whse. Document Type", "Whse. Document No.");
            GlobalWhseActivLine.SetRange("Activity Type", GlobalWhseActivHeader.Type);
            GlobalWhseActivLine.SetRange("No.", GlobalWhseActivHeader."No.");
            if GlobalWhseActivLine.Find('-') then
                repeat
                    ShouldDeleteOldLine := (LineCount = 1) and
                        ((OldWhseActivLine."Whse. Document Type" <> GlobalWhseActivLine."Whse. Document Type") or
                         (OldWhseActivLine."Whse. Document No." <> GlobalWhseActivLine."Whse. Document No."));
                    OnCodeOnAfterCalcShouldDeleteOldLine(OldWhseActivLine, GlobalWhseActivLine, ShouldDeleteOldLine, LineCount);
                    if ShouldDeleteOldLine then begin
                        LineCount := 0;
                        OldWhseActivLine.Delete();
                    end;
                    OldWhseActivLine := GlobalWhseActivLine;
                    LineCount := LineCount + 1;
                until GlobalWhseActivLine.Next() = 0;
            if LineCount = 1 then
                OldWhseActivLine.Delete();
        end;
        OnBeforeUpdWhseActivHeader(GlobalWhseActivHeader, GlobalWhseActivLine);
        GlobalWhseActivLine.Reset();
        GlobalWhseActivLine.SetRange("Activity Type", GlobalWhseActivHeader.Type);
        GlobalWhseActivLine.SetRange("No.", GlobalWhseActivHeader."No.");
        GlobalWhseActivLine.SetFilter("Qty. Outstanding", '<>%1', 0);
        if not GlobalWhseActivLine.Find('-') then begin
            SkipDelete := false;
            OnBeforeWhseActivHeaderDelete(GlobalWhseActivHeader, SkipDelete);
            if not SkipDelete then
                GlobalWhseActivHeader.Delete(true);
        end else begin
            GlobalWhseActivHeader."Last Registering No." := GlobalWhseActivHeader."Registering No.";
            GlobalWhseActivHeader."Registering No." := '';
            OnCodeOnBeforeModifyGlobalWhseActivHeader(GlobalWhseActivHeader);
            GlobalWhseActivHeader.Modify();
            if not GlobalWhseActivHeader."Do Not Fill Qty. to Handle" then
                AutofillQtyToHandle(GlobalWhseActivLine);
        end;
        if not HideDialog then
            Window.Close();

        OnCodeOnBeforeCommit(RegisteredWhseActivHeader, RegisteredWhseActivLine, SuppressCommit);
        if not SuppressCommit then begin
            OnBeforeCommit(GlobalWhseActivHeader);
            Commit();
        end;
        Clear(WhseJnlRegisterLine);

        OnAfterRegisterWhseActivity(GlobalWhseActivHeader);
    end;

    local procedure RegisterWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var TempWhseActivityLineGrouped: Record "Warehouse Activity Line" temporary)
    var
        QtyDiff: Decimal;
        QtyBaseDiff: Decimal;
        SkipDelete: Boolean;
    begin
        OnBeforeRegisterWhseActivityLines(WarehouseActivityLine);

        if not WarehouseActivityLine.FindSet() then
            exit;

        repeat
            LineCount := LineCount + 1;
            UpdateWindow(3, '');
            UpdateWindow(4, '');
            if Location."Bin Mandatory" then
                RegisterWhseJnlLine(WarehouseActivityLine);
            CreateRegActivLine(WarehouseActivityLine);
            OnAfterCreateRegActivLine(WarehouseActivityLine, RegisteredWhseActivLine, RegisteredInvtMovementLine);

            CopyWhseActivityLineToReservBuf(TempWhseActivLineToReserve, WarehouseActivityLine);
            GroupWhseActivLinesByWhseDocAndSource(TempWhseActivityLineGrouped, WarehouseActivityLine);

            if WarehouseActivityLine."Activity Type" <> WarehouseActivityLine."Activity Type"::Movement then
                RegisterWhseItemTrkgLine(WarehouseActivityLine);
            OnAfterFindWhseActivLine(WarehouseActivityLine);

            if TempWhseActivityLineGrouped."Source Document" in [TempWhseActivityLineGrouped."Source Document"::"Prod. Consumption", TempWhseActivityLineGrouped."Source Document"::"Job Usage"] then
                CheckSourceDocumentForAvailableQty(TempWhseActivityLineGrouped);

            if WarehouseActivityLine."Qty. Outstanding" = WarehouseActivityLine."Qty. to Handle" then begin
                SkipDelete := false;
                OnBeforeWhseActivLineDelete(WarehouseActivityLine, SkipDelete);
                if not SkipDelete then
                    WarehouseActivityLine.Delete();
            end else begin
                QtyDiff := WarehouseActivityLine."Qty. Outstanding" - WarehouseActivityLine."Qty. to Handle";
                QtyBaseDiff := WarehouseActivityLine."Qty. Outstanding (Base)" - WarehouseActivityLine."Qty. to Handle (Base)";
                UpdateWhseActivLineQtyOutstanding(WarehouseActivityLine, QtyDiff, QtyBaseDiff);
                UpdateWarehouseActivityLineQtyToHandle(WarehouseActivityLine, QtyDiff, QtyBaseDiff);
                OnBeforeWhseActivLineModify(WarehouseActivityLine);
                WarehouseActivityLine.Modify();
            end;
        until WarehouseActivityLine.Next() = 0;

        OnAfterRegisterWhseActivityLines(WarehouseActivityLine);
    end;

    local procedure UpdateWhseActivLineQtyOutstanding(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyDiff: Decimal; QtyBaseDiff: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWhseActivLineQtyOutstanding(WarehouseActivityLine, QtyDiff, QtyBaseDiff, HideDialog, IsHandled);
        if IsHandled then
            exit;

        WarehouseActivityLine.Validate("Qty. Outstanding", QtyDiff);
        if WarehouseActivityLine."Qty. Outstanding (Base)" > QtyBaseDiff then
            // round off error- qty same, not base qty
            WarehouseActivityLine."Qty. Outstanding (Base)" := QtyBaseDiff;
    end;

    local procedure UpdateWarehouseActivityLineQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyDiff: Decimal; QtyBaseDiff: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWarehouseActivityLineQtyToHandle(WarehouseActivityLine, QtyDiff, QtyBaseDiff, HideDialog, IsHandled);
        if IsHandled then
            exit;

        WarehouseActivityLine.Validate("Qty. to Handle", QtyDiff);
        if WarehouseActivityLine."Qty. to Handle (Base)" > QtyBaseDiff then
            // round off error- qty same, not base qty
            WarehouseActivityLine."Qty. to Handle (Base)" := QtyBaseDiff;
        if HideDialog then
            WarehouseActivityLine.Validate(WarehouseActivityLine."Qty. to Handle", 0);
        WarehouseActivityLine.Validate(WarehouseActivityLine."Qty. Handled", WarehouseActivityLine.Quantity - WarehouseActivityLine."Qty. Outstanding");
    end;

    local procedure RegisterWhseJnlLine(WhseActivLine: Record "Warehouse Activity Line")
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        WMSMgt: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRegisterWhseJnlLine(WhseActivLine, RegisteredWhseActivHeader, IsHandled);
        if IsHandled then
            exit;

        WhseJnlLine.Init();
        WhseJnlLine."Location Code" := WhseActivLine."Location Code";
        WhseJnlLine."Item No." := WhseActivLine."Item No.";
        WhseJnlLine."Registering Date" := WorkDate();
        WhseJnlLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(WhseJnlLine."User ID"));
        WhseJnlLine."Variant Code" := WhseActivLine."Variant Code";
        WhseJnlLine."Entry Type" := WhseJnlLine."Entry Type"::Movement;
        if WhseActivLine."Action Type" = WhseActivLine."Action Type"::Take then begin
            WhseJnlLine."From Zone Code" := WhseActivLine."Zone Code";
            WhseJnlLine."From Bin Code" := WhseActivLine."Bin Code";
        end else begin
            WhseJnlLine."To Zone Code" := WhseActivLine."Zone Code";
            WhseJnlLine."To Bin Code" := WhseActivLine."Bin Code";
        end;
        WhseJnlLine.Description := WhseActivLine.Description;

        LocationGet(WhseActivLine."Location Code");
        if Location."Directed Put-away and Pick" then begin
            WhseJnlLine.Quantity := WhseActivLine."Qty. to Handle";
            WhseJnlLine."Unit of Measure Code" := WhseActivLine."Unit of Measure Code";
            WhseJnlLine."Qty. per Unit of Measure" := WhseActivLine."Qty. per Unit of Measure";
            WhseJnlLine."Qty. Rounding Precision" := WhseActivLine."Qty. Rounding Precision";
            WhseJnlLine."Qty. Rounding Precision (Base)" := WhseActivLine."Qty. Rounding Precision (Base)";

            GetItemUnitOfMeasure(WhseActivLine."Item No.", WhseActivLine."Unit of Measure Code");
            WhseJnlLine.Cubage :=
              Abs(WhseJnlLine.Quantity) * ItemUnitOfMeasure.Cubage;
            WhseJnlLine.Weight :=
              Abs(WhseJnlLine.Quantity) * ItemUnitOfMeasure.Weight;
        end else begin
            WhseJnlLine.Quantity := WhseActivLine."Qty. to Handle (Base)";
            WhseJnlLine."Unit of Measure Code" := WMSMgt.GetBaseUOM(WhseActivLine."Item No.");
            WhseJnlLine."Qty. per Unit of Measure" := 1;
        end;
        WhseJnlLine."Qty. (Base)" := WhseActivLine."Qty. to Handle (Base)";
        WhseJnlLine."Qty. (Absolute)" := WhseJnlLine.Quantity;
        WhseJnlLine."Qty. (Absolute, Base)" := WhseActivLine."Qty. to Handle (Base)";

        WhseJnlLine.SetSource(WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.");
        WhseJnlLine."Source Document" := WhseActivLine."Source Document";
        WhseJnlLine."Reference No." := RegisteredWhseActivHeader."No.";
        case WhseActivLine."Activity Type" of
            WhseActivLine."Activity Type"::"Put-away":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup."Whse. Put-away";
                    WhseJnlLine.SetWhseDocument(WhseActivLine."Whse. Document Type", WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.");
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Put-away";
                end;
            WhseActivLine."Activity Type"::Pick:
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup."Whse. Pick";
                    WhseJnlLine.SetWhseDocument(WhseActivLine."Whse. Document Type", WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.");
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::Pick;
                end;
            WhseActivLine."Activity Type"::Movement:
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup."Whse. Movement";
                    WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::" ";
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::Movement;
                end;
            WhseActivLine."Activity Type"::"Invt. Put-away",
          WhseActivLine."Activity Type"::"Invt. Pick",
          WhseActivLine."Activity Type"::"Invt. Movement":
                WhseJnlLine."Whse. Document Type" := WhseJnlLine."Whse. Document Type"::" ";
        end;
        WhseActivLine.ValidateQtyWhenSNDefined();
        WhseJnlLine.CopyTrackingFromWhseActivityLine(WhseActivLine);
        WhseJnlLine."Warranty Date" := WhseActivLine."Warranty Date";
        WhseJnlLine."Expiration Date" := WhseActivLine."Expiration Date";
        OnBeforeWhseJnlRegisterLine(WhseJnlLine, WhseActivLine);
        WhseJnlRegisterLine.Run(WhseJnlLine);
    end;

    local procedure CreateRegActivHeader(WhseActivHeader: Record "Warehouse Activity Header")
    var
        WhseCommentLine: Record "Warehouse Comment Line";
        WhseCommentLine2: Record "Warehouse Comment Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        TableNameFrom: Option;
        TableNameTo: Option;
        RegisteredType: Enum "Warehouse Activity Type";
        RegisteredNo: Code[20];
        IsHandled: Boolean;
    begin
        OnBeforeCreateRegActivHeader(WhseActivHeader, IsHandled, RegisteredWhseActivHeader, RegisteredInvtMovementHdr);
        if IsHandled then
            exit;

        TableNameFrom := WhseCommentLine."Table Name"::"Whse. Activity Header";
        if WhseActivHeader.Type = WhseActivHeader.Type::"Invt. Movement" then begin
            RegisteredInvtMovementHdr.Init();
            RegisteredInvtMovementHdr.TransferFields(WhseActivHeader);
            RegisteredInvtMovementHdr."No." := WhseActivHeader."Registering No.";
            RegisteredInvtMovementHdr."Invt. Movement No." := WhseActivHeader."No.";
            RegisteredInvtMovementHdr."Registering Date" := WorkDate();
            OnBeforeRegisteredInvtMovementHdrInsert(RegisteredInvtMovementHdr, WhseActivHeader);
            RegisteredInvtMovementHdr.Insert();
            RecordLinkManagement.CopyLinks(WhseActivHeader, RegisteredInvtMovementHdr);
            OnAfterRegisteredInvtMovementHdrInsert(RegisteredInvtMovementHdr, WhseActivHeader);

            TableNameTo := WhseCommentLine."Table Name"::"Registered Invt. Movement";
            RegisteredType := RegisteredType::" ";
            RegisteredNo := RegisteredInvtMovementHdr."No.";
        end else begin
            RegisteredWhseActivHeader.Init();
            RegisteredWhseActivHeader.TransferFields(WhseActivHeader);
            RegisteredWhseActivHeader.Type := WhseActivHeader.Type;
            RegisteredWhseActivHeader."No." := WhseActivHeader."Registering No.";
            RegisteredWhseActivHeader."Whse. Activity No." := WhseActivHeader."No.";
            RegisteredWhseActivHeader."Registering Date" := WorkDate();
            RegisteredWhseActivHeader."No. Series" := WhseActivHeader."Registering No. Series";
            OnBeforeRegisteredWhseActivHeaderInsert(RegisteredWhseActivHeader, WhseActivHeader);
            RegisteredWhseActivHeader.Insert();
            RecordLinkManagement.CopyLinks(WhseActivHeader, RegisteredWhseActivHeader);
            OnAfterRegisteredWhseActivHeaderInsert(RegisteredWhseActivHeader, WhseActivHeader);

            TableNameTo := WhseCommentLine2."Table Name"::"Rgstrd. Whse. Activity Header";
            RegisteredType := RegisteredWhseActivHeader.Type;
            RegisteredNo := RegisteredWhseActivHeader."No.";
        end;

        WhseCommentLine.SetRange("Table Name", TableNameFrom);
        WhseCommentLine.SetRange(Type, WhseActivHeader.Type);
        WhseCommentLine.SetRange("No.", WhseActivHeader."No.");
        WhseCommentLine.LockTable();

        if WhseCommentLine.Find('-') then
            repeat
                WhseCommentLine2.Init();
                WhseCommentLine2 := WhseCommentLine;
                WhseCommentLine2."Table Name" := TableNameTo;
                WhseCommentLine2.Type := RegisteredType;
                WhseCommentLine2."No." := RegisteredNo;
                WhseCommentLine2.Insert();
            until WhseCommentLine.Next() = 0;

        OnAfterCreateRegActivHeader(WhseActivHeader);
    end;

    local procedure CreateRegActivLine(WhseActivLine: Record "Warehouse Activity Line")
    begin
        if WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement" then begin
            RegisteredInvtMovementLine.Init();
            RegisteredInvtMovementLine.TransferFields(WhseActivLine);
            RegisteredInvtMovementLine."No." := RegisteredInvtMovementHdr."No.";
            OnAfterInitRegInvtMovementLine(WhseActivLine, RegisteredInvtMovementLine);
            RegisteredInvtMovementLine.Validate(Quantity, WhseActivLine."Qty. to Handle");
            OnBeforeRegisteredInvtMovementLineInsert(RegisteredInvtMovementLine, WhseActivLine);
            RegisteredInvtMovementLine.Insert();
            OnAfterRegisteredInvtMovementLineInsert(RegisteredInvtMovementLine, WhseActivLine);
        end else begin
            RegisteredWhseActivLine.Init();
            RegisteredWhseActivLine.TransferFields(WhseActivLine);
            RegisteredWhseActivLine."Activity Type" := RegisteredWhseActivHeader.Type;
            RegisteredWhseActivLine."No." := RegisteredWhseActivHeader."No.";
            OnAfterInitRegActLine(WhseActivLine, RegisteredWhseActivLine);
            RegisteredWhseActivLine.Quantity := WhseActivLine."Qty. to Handle";
            RegisteredWhseActivLine."Qty. (Base)" := WhseActivLine."Qty. to Handle (Base)";
            OnBeforeRegisteredWhseActivLineInsert(RegisteredWhseActivLine, WhseActivLine);
            RegisteredWhseActivLine.Insert();
            OnAfterRegisteredWhseActivLineInsert(RegisteredWhseActivLine, WhseActivLine);
        end;
    end;

    /// <summary>
    /// Updates the source document line quantity information based on a provided warehouse activity line.
    /// </summary>
    /// <param name="WhseActivLineGrouped">Provided warehouse activity line.</param>
    procedure UpdateWhseSourceDocLine(WhseActivLineGrouped: Record "Warehouse Activity Line")
    var
        WhseDocType2: Enum "Warehouse Activity Document Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWhseSourceDocLine(WhseActivLineGrouped, IsHandled);
        if IsHandled then
            exit;

        if WhseActivLineGrouped."Original Breakbulk" then
            exit;

        if (WhseActivLineGrouped."Whse. Document Type" in [WhseActivLineGrouped."Whse. Document Type"::Shipment, WhseActivLineGrouped."Whse. Document Type"::Job]) and WhseActivLineGrouped."Assemble to Order" then
            WhseDocType2 := WhseActivLineGrouped."Whse. Document Type"::Assembly
        else
            WhseDocType2 := WhseActivLineGrouped."Whse. Document Type";
        case WhseDocType2 of
            WhseActivLineGrouped."Whse. Document Type"::Shipment:
                if (WhseActivLineGrouped."Action Type" <> WhseActivLineGrouped."Action Type"::Take) and (WhseActivLineGrouped."Breakbulk No." = 0) then
                    UpdateWhseShipmentLine(
                      WhseActivLineGrouped, WhseActivLineGrouped."Whse. Document No.", WhseActivLineGrouped."Whse. Document Line No.",
                      WhseActivLineGrouped."Qty. to Handle", WhseActivLineGrouped."Qty. to Handle (Base)", WhseActivLineGrouped."Qty. per Unit of Measure");
            WhseActivLineGrouped."Whse. Document Type"::"Internal Pick":
                if (WhseActivLineGrouped."Action Type" <> WhseActivLineGrouped."Action Type"::Take) and (WhseActivLineGrouped."Breakbulk No." = 0) then
                    UpdateWhseIntPickLine(WhseActivLineGrouped);
            WhseActivLineGrouped."Whse. Document Type"::Receipt:
                if WhseActivLineGrouped."Action Type" <> WhseActivLineGrouped."Action Type"::Place then
                    UpdatePostedWhseRcptLine(WhseActivLineGrouped);
            WhseActivLineGrouped."Whse. Document Type"::"Internal Put-away":
                if WhseActivLineGrouped."Action Type" <> WhseActivLineGrouped."Action Type"::Take then
                    UpdateWhseIntPutAwayLine(WhseActivLineGrouped);
            WhseActivLineGrouped."Whse. Document Type"::Job:
                if (WhseActivLineGrouped."Action Type" <> WhseActivLineGrouped."Action Type"::Take) and (WhseActivLineGrouped."Breakbulk No." = 0) then
                    UpdateJobPlanningLine(WhseActivLineGrouped);
            else
                OnUpdateWhseSourceDocLineByDocumentType(WhseActivLineGrouped, WhseDocType2);
        end;

        if WhseActivLineGrouped."Activity Type" = WhseActivLineGrouped."Activity Type"::"Invt. Movement" then
            UpdateSourceDocForInvtMovement(WhseActivLineGrouped);

        OnAfterUpdateWhseSourceDocLine(WhseActivLineGrouped, WhseDocType2.AsInteger());
    end;

    /// <summary>
    /// Updates the warehouse document status based on the provided warehouse activity line.
    /// </summary>
    /// <param name="WhseActivLine">Provided warehouse activity line.</param>
    procedure UpdateWhseDocHeader(WhseActivLine: Record "Warehouse Activity Line")
    var
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        WhsePickRequest: Record "Whse. Pick Request";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWhseDocHeader(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        case WhseActivLine."Whse. Document Type" of
            WhseActivLine."Whse. Document Type"::Shipment:
                if WhseActivLine."Action Type" <> WhseActivLine."Action Type"::Take then begin
                    WhseShptHeader.Get(WhseActivLine."Whse. Document No.");
                    WhseShptHeader.Validate("Document Status", WhseShptHeader.GetShipmentStatus(0));
                    WhseShptHeader.Modify();
                end;
            WhseActivLine."Whse. Document Type"::Receipt:
                if WhseActivLine."Action Type" <> WhseActivLine."Action Type"::Place then begin
                    PostedWhseRcptHeader.Get(WhseActivLine."Whse. Document No.");
                    PostedWhseRcptLine.Reset();
                    PostedWhseRcptLine.SetRange("No.", PostedWhseRcptHeader."No.");
                    if PostedWhseRcptLine.FindFirst() then begin
                        PostedWhseRcptHeader."Document Status" := PostedWhseRcptHeader.GetHeaderStatus(0);
                        PostedWhseRcptHeader.Modify();
                    end;
                    if PostedWhseRcptHeader."Document Status" =
                       PostedWhseRcptHeader."Document Status"::"Completely Put Away"
                    then begin
                        WhsePutAwayRequest.SetRange("Document Type", WhsePutAwayRequest."Document Type"::Receipt);
                        WhsePutAwayRequest.SetRange("Document No.", PostedWhseRcptHeader."No.");
                        WhsePutAwayRequest.DeleteAll();
                        ItemTrackingMgt.DeleteWhseItemTrkgLines(
                          Database::"Posted Whse. Receipt Line", 0, PostedWhseRcptHeader."No.", '', 0, 0, '', false);
                    end;
                end;
            WhseActivLine."Whse. Document Type"::"Internal Pick":
                if WhseActivLine."Action Type" <> WhseActivLine."Action Type"::Take then begin
                    WhseInternalPickHeader.Get(WhseActivLine."Whse. Document No.");
                    WhseInternalPickLine.Reset();
                    WhseInternalPickLine.SetRange("No.", WhseActivLine."Whse. Document No.");
                    if WhseInternalPickLine.FindFirst() then begin
                        WhseInternalPickHeader."Document Status" :=
                          WhseInternalPickHeader.GetDocumentStatus(0);
                        WhseInternalPickHeader.Modify();
                        if WhseInternalPickHeader."Document Status" =
                           WhseInternalPickHeader."Document Status"::"Completely Picked"
                        then begin
                            WhseInternalPickHeader.DeleteRelatedLines();
                            WhseInternalPickHeader.Delete();
                        end;
                    end else begin
                        WhseInternalPickHeader.DeleteRelatedLines();
                        WhseInternalPickHeader.Delete();
                    end;
                end;
            WhseActivLine."Whse. Document Type"::"Internal Put-away":
                if WhseActivLine."Action Type" <> WhseActivLine."Action Type"::Take then begin
                    WhseInternalPutAwayHeader.Get(WhseActivLine."Whse. Document No.");
                    WhseInternalPutAwayLine.Reset();
                    WhseInternalPutAwayLine.SetRange("No.", WhseActivLine."Whse. Document No.");
                    if WhseInternalPutAwayLine.FindFirst() then begin
                        WhseInternalPutAwayHeader."Document Status" :=
                          WhseInternalPutAwayHeader.GetDocumentStatus(0);
                        WhseInternalPutAwayHeader.Modify();
                        if WhseInternalPutAwayHeader."Document Status" =
                           WhseInternalPutAwayHeader."Document Status"::"Completely Put Away"
                        then begin
                            WhseInternalPutAwayHeader.DeleteRelatedLines();
                            WhseInternalPutAwayHeader.Delete();
                        end;
                    end else begin
                        WhseInternalPutAwayHeader.DeleteRelatedLines();
                        WhseInternalPutAwayHeader.Delete();
                    end;
                end;
            WhseActivLine."Whse. Document Type"::Job:
                if WhseActivLine."Action Type" <> WhseActivLine."Action Type"::Take then begin
                    Job.Get(WhseActivLine."Whse. Document No.");
                    Job.CalcFields("Completely Picked");
                    if Job."Completely Picked" then begin
                        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Job);
                        WhsePickRequest.SetRange("Document No.", Job."No.");
                        WhsePickRequest.ModifyAll("Completely Picked", true);
                        ItemTrackingMgt.DeleteWhseItemTrkgLines(
                          Database::"Job Planning Line", WhseActivLine."Source Subtype", WhseActivLine."Source No.", '', 0, 0, '', false);
                    end;
                end;
            else
                OnUpdateWhseDocHeaderByWhseDocumentType(WhseActivLine);
        end;
        OnAfterUpdateWhseDocHeader(WhseActivLine);
    end;

    /// <summary>
    /// Updates the warehouse shipment line based on the provided warehouse activity line, with the provided quantities.
    /// </summary>
    /// <param name="WhseActivityLineGrouped">Provided warehouse activity line.</param>
    /// <param name="WhseDocNo">Warehouse document number.</param>
    /// <param name="WhseDocLineNo">Warehouse document line number.</param>
    /// <param name="QtyToHandle">Quantity to handle.</param>
    /// <param name="QtyToHandleBase">Quantity to handle in base unit.</param>
    /// <param name="QtyPerUOM">Quantity per unit of measure.</param>
    procedure UpdateWhseShipmentLine(WhseActivityLineGrouped: Record "Warehouse Activity Line"; WhseDocNo: Code[20]; WhseDocLineNo: Integer; QtyToHandle: Decimal; QtyToHandleBase: Decimal; QtyPerUOM: Decimal)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.Get(WhseDocNo, WhseDocLineNo);
        OnBeforeUpdateWhseShptLine(WhseShptLine, QtyToHandle, QtyToHandleBase, QtyPerUOM);
        WhseShptLine."Qty. Picked (Base)" :=
          WhseShptLine."Qty. Picked (Base)" + QtyToHandleBase;
        if QtyPerUOM = WhseShptLine."Qty. per Unit of Measure" then
            WhseShptLine."Qty. Picked" := WhseShptLine."Qty. Picked" + QtyToHandle
        else
            WhseShptLine."Qty. Picked" :=
              Round(WhseShptLine."Qty. Picked" + QtyToHandleBase / QtyPerUOM);

        OnUpdateWhseShptLineOnAfterAssignQtyPicked(WhseShptLine, QtyPerUOM, QtyToHandleBase);

        WhseShptLine."Completely Picked" :=
          (WhseShptLine."Qty. Picked" = WhseShptLine.Quantity) or (WhseShptLine."Qty. Picked (Base)" = WhseShptLine."Qty. (Base)");

        // Handle rounding residual when completely picked
        if WhseShptLine."Completely Picked" and (WhseShptLine."Qty. Picked" <> WhseShptLine.Quantity) then
            WhseShptLine."Qty. Picked" := WhseShptLine.Quantity;

        WhseShptLine.Validate("Qty. to Ship", WhseShptLine."Qty. Picked" - WhseShptLine."Qty. Shipped");
        WhseShptLine."Qty. to Ship (Base)" := WhseShptLine."Qty. Picked (Base)" - WhseShptLine."Qty. Shipped (Base)";
        WhseShptLine.Status := WhseShptLine.GetShipmentLineStatus();
        OnBeforeWhseShptLineModify(WhseShptLine, GlobalWhseActivLine, WhseActivityLineGrouped);
        WhseShptLine.Modify();
        OnAfterWhseShptLineModify(WhseShptLine);
    end;

    local procedure UpdatePostedWhseRcptLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        PostedWhseRcptHeader.LockTable();
        PostedWhseRcptHeader.Get(WhseActivityLine."Whse. Document No.");
        PostedWhseRcptLine.LockTable();
        PostedWhseRcptLine.Get(WhseActivityLine."Whse. Document No.", WhseActivityLine."Whse. Document Line No.");
        PostedWhseRcptLine."Qty. Put Away (Base)" :=
          PostedWhseRcptLine."Qty. Put Away (Base)" + WhseActivityLine."Qty. to Handle (Base)";
        if WhseActivityLine."Qty. per Unit of Measure" = PostedWhseRcptLine."Qty. per Unit of Measure" then
            PostedWhseRcptLine."Qty. Put Away" :=
              PostedWhseRcptLine."Qty. Put Away" + WhseActivityLine."Qty. to Handle"
        else
            PostedWhseRcptLine."Qty. Put Away" :=
              Round(
                PostedWhseRcptLine."Qty. Put Away" +
                WhseActivityLine."Qty. to Handle (Base)" / PostedWhseRcptLine."Qty. per Unit of Measure");
        PostedWhseRcptLine.Status := PostedWhseRcptLine.GetLineStatus();
        OnBeforePostedWhseRcptLineModify(PostedWhseRcptLine, WhseActivityLine);
        PostedWhseRcptLine.Modify();
        OnAfterPostedWhseRcptLineModify(PostedWhseRcptLine);
    end;

    local procedure UpdateWhseIntPickLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        WhseInternalPickLine.Get(WhseActivityLine."Whse. Document No.", WhseActivityLine."Whse. Document Line No.");
        if WhseInternalPickLine."Qty. (Base)" =
           WhseInternalPickLine."Qty. Picked (Base)" + WhseActivityLine."Qty. to Handle (Base)"
        then
            WhseInternalPickLine.Delete()
        else begin
            WhseInternalPickLine."Qty. Picked (Base)" :=
              WhseInternalPickLine."Qty. Picked (Base)" + WhseActivityLine."Qty. to Handle (Base)";
            if WhseActivityLine."Qty. per Unit of Measure" = WhseInternalPickLine."Qty. per Unit of Measure" then
                WhseInternalPickLine."Qty. Picked" :=
                  WhseInternalPickLine."Qty. Picked" + WhseActivityLine."Qty. to Handle"
            else
                WhseInternalPickLine."Qty. Picked" :=
                  Round(
                    WhseInternalPickLine."Qty. Picked" + WhseActivityLine."Qty. to Handle (Base)" / WhseActivityLine."Qty. per Unit of Measure");
            WhseInternalPickLine.Validate(
              "Qty. Outstanding", WhseInternalPickLine."Qty. Outstanding" - WhseActivityLine."Qty. to Handle");
            WhseInternalPickLine.Status := WhseInternalPickLine.CalcStatusPickLine();
            OnBeforeWhseInternalPickLineModify(WhseInternalPickLine, WhseActivityLine);
            WhseInternalPickLine.Modify();
            OnAfterWhseInternalPickLineModify(WhseInternalPickLine);
        end;
    end;

    local procedure UpdateWhseIntPutAwayLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        WhseInternalPutAwayLine.Get(WhseActivityLine."Whse. Document No.", WhseActivityLine."Whse. Document Line No.");
        if WhseInternalPutAwayLine."Qty. (Base)" =
           WhseInternalPutAwayLine."Qty. Put Away (Base)" + WhseActivityLine."Qty. to Handle (Base)"
        then
            WhseInternalPutAwayLine.Delete()
        else begin
            WhseInternalPutAwayLine."Qty. Put Away (Base)" :=
              WhseInternalPutAwayLine."Qty. Put Away (Base)" + WhseActivityLine."Qty. to Handle (Base)";
            if WhseActivityLine."Qty. per Unit of Measure" = WhseInternalPutAwayLine."Qty. per Unit of Measure" then
                WhseInternalPutAwayLine."Qty. Put Away" :=
                  WhseInternalPutAwayLine."Qty. Put Away" + WhseActivityLine."Qty. to Handle"
            else
                WhseInternalPutAwayLine."Qty. Put Away" :=
                  Round(
                    WhseInternalPutAwayLine."Qty. Put Away" +
                    WhseActivityLine."Qty. to Handle (Base)" / WhseInternalPutAwayLine."Qty. per Unit of Measure");
            WhseInternalPutAwayLine.Validate(
              "Qty. Outstanding", WhseInternalPutAwayLine."Qty. Outstanding" - WhseActivityLine."Qty. to Handle");
            WhseInternalPutAwayLine.Status := WhseInternalPutAwayLine.CalcStatusPutAwayLine();
            OnBeforeWhseInternalPutAwayLineModify(WhseInternalPutAwayLine, WhseActivityLine);
            WhseInternalPutAwayLine.Modify();
            OnAfterWhseInternalPutAwayLineModify(WhseInternalPutAwayLine);
        end;
    end;

    local procedure UpdateJobPlanningLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        JobPlanningLine.SetRange("Job Contract Entry No.", WhseActivityLine."Source Line No.");
        if JobPlanningLine.FindFirst() then begin
            JobPlanningLine."Qty. Picked (Base)" := JobPlanningLine."Qty. Picked (Base)" + WhseActivityLine."Qty. to Handle (Base)";
            if WhseActivityLine."Qty. per Unit of Measure" = JobPlanningLine."Qty. per Unit of Measure" then
                JobPlanningLine."Qty. Picked" := JobPlanningLine."Qty. Picked" + WhseActivityLine."Qty. to Handle"
            else
                JobPlanningLine."Qty. Picked" := Round(JobPlanningLine."Qty. Picked" + WhseActivityLine."Qty. to Handle (Base)" / WhseActivityLine."Qty. per Unit of Measure");

            JobPlanningLine."Completely Picked" := JobPlanningLine."Qty. Picked" = JobPlanningLine.Quantity;
            JobPlanningLine.Modify();
            OnAfterJobPlanningLineModify(JobPlanningLine);
        end
    end;

    /// <summary>
    /// Retrieves the global location record based on the 'LocationCode' parameter. In case that the blank 'LocationCode' is passed record instance will be cleared.
    /// </summary>
    /// <param name="LocationCode">Specified location code.</param>
    procedure LocationGet(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    /// <summary>
    /// Retrieves the item unit of measure record for the provided item number and unit of measure code.
    /// </summary>
    /// <param name="ItemNo">Item number.</param>
    /// <param name="UOMCode">Unit of measure code.</param>
    procedure GetItemUnitOfMeasure(ItemNo: Code[20]; UOMCode: Code[10])
    begin
        if (ItemUnitOfMeasure."Item No." <> ItemNo) or
           (ItemUnitOfMeasure.Code <> UOMCode)
        then
            if not ItemUnitOfMeasure.Get(ItemNo, UOMCode) then
                ItemUnitOfMeasure.Init();
    end;

    local procedure UpdateTempBinContentBuffer(WhseActivLine: Record "Warehouse Activity Line")
    var
        WMSMgt: Codeunit "WMS Management";
        UOMCode: Code[10];
        Sign: Integer;
    begin
        if Location."Directed Put-away and Pick" then
            UOMCode := WhseActivLine."Unit of Measure Code"
        else
            UOMCode := WMSMgt.GetBaseUOM(WhseActivLine."Item No.");
        if not TempBinContentBuffer.Get(
            WhseActivLine."Location Code", WhseActivLine."Bin Code", WhseActivLine."Item No.", WhseActivLine."Variant Code", UOMCode, WhseActivLine."Lot No.", WhseActivLine."Serial No.", WhseActivLine."Package No.")
        then begin
            TempBinContentBuffer.Init();
            TempBinContentBuffer."Location Code" := WhseActivLine."Location Code";
            TempBinContentBuffer."Zone Code" := WhseActivLine."Zone Code";
            TempBinContentBuffer."Bin Code" := WhseActivLine."Bin Code";
            TempBinContentBuffer."Item No." := WhseActivLine."Item No.";
            TempBinContentBuffer."Variant Code" := WhseActivLine."Variant Code";
            TempBinContentBuffer."Unit of Measure Code" := UOMCode;
            TempBinContentBuffer.CopyTrackingFromWhseActivityLine(WhseActivLine);
            OnUpdateTempBinContentBufferOnBeforeInsert(TempBinContentBuffer, WhseActivLine);
            TempBinContentBuffer.Insert();
        end;
        Sign := 1;
        if WhseActivLine."Action Type" = WhseActivLine."Action Type"::Take then
            Sign := -1;

        TempBinContentBuffer."Base Unit of Measure" := WMSMgt.GetBaseUOM(WhseActivLine."Item No.");
        TempBinContentBuffer."Qty. to Handle (Base)" := TempBinContentBuffer."Qty. to Handle (Base)" + Sign * WhseActivLine."Qty. to Handle (Base)";
        TempBinContentBuffer."Qty. Outstanding (Base)" :=
          TempBinContentBuffer."Qty. Outstanding (Base)" + Sign * WhseActivLine."Qty. Outstanding (Base)";
        TempBinContentBuffer.Cubage := TempBinContentBuffer.Cubage + Sign * WhseActivLine.Cubage;
        TempBinContentBuffer.Weight := TempBinContentBuffer.Weight + Sign * WhseActivLine.Weight;
        OnUpdateTempBinContentBufferOnBeforeModifyTempBinContentBuffer(TempBinContentBuffer, WhseActivLine);
        TempBinContentBuffer.Modify();
    end;

    local procedure CheckBin()
    var
        Bin: Record Bin;
    begin
        TempBinContentBuffer.SetFilter("Qty. to Handle (Base)", '>0');
        if TempBinContentBuffer.Find('-') then
            repeat
                TempBinContentBuffer.SetRange("Qty. to Handle (Base)");
                TempBinContentBuffer.SetRange("Bin Code", TempBinContentBuffer."Bin Code");
                TempBinContentBuffer.CalcSums(Cubage, Weight);
                Bin.Get(TempBinContentBuffer."Location Code", TempBinContentBuffer."Bin Code");
                CheckIncreaseBin(Bin);
                TempBinContentBuffer.SetFilter("Qty. to Handle (Base)", '>0');
                TempBinContentBuffer.Find('+');
                TempBinContentBuffer.SetRange("Bin Code");
            until TempBinContentBuffer.Next() = 0;
    end;

    local procedure CheckIncreaseBin(var Bin: Record Bin)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIncreaseBin(TempBinContentBuffer, Bin, IsHandled);
        if IsHandled then
            exit;

        Bin.CheckIncreaseBin(
            TempBinContentBuffer."Bin Code", '', TempBinContentBuffer."Qty. to Handle (Base)", TempBinContentBuffer.Cubage, TempBinContentBuffer.Weight, TempBinContentBuffer.Cubage, TempBinContentBuffer.Weight, true, false);
    end;

    local procedure CheckBinContent()
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseLocation: Record Location;
        BreakBulkQtyBaseToPlace: Decimal;
        IsHandled: Boolean;
    begin
        OnBeforeCheckBinContent(TempBinContentBuffer, IsHandled);
        if IsHandled then
            exit;

        TempBinContentBuffer.SetFilter("Qty. to Handle (Base)", '<>0');
        if TempBinContentBuffer.Find('-') then
            repeat
                if TempBinContentBuffer."Qty. to Handle (Base)" < 0 then begin
                    BinContent.Get(TempBinContentBuffer."Location Code", TempBinContentBuffer."Bin Code", TempBinContentBuffer."Item No.", TempBinContentBuffer."Variant Code", TempBinContentBuffer."Unit of Measure Code");
                    ItemTrackingMgt.GetWhseItemTrkgSetup(BinContent."Item No.", WhseItemTrackingSetup);
                    OnCheckBinContentOnAfterGetWhseItemTrkgSetup(BinContent, WhseItemTrackingSetup);

                    BinContent.ClearTrackingFilters();
                    BinContent.SetTrackingFilterFromBinContentBufferIfRequired(WhseItemTrackingSetup, TempBinContentBuffer);

                    BreakBulkQtyBaseToPlace := CalcBreakBulkQtyToPlace(TempBinContentBuffer);
                    GetItem(TempBinContentBuffer."Item No.");

                    CheckBinContentQtyToHandle(TempBinContentBuffer, BinContent, BreakBulkQtyBaseToPlace);
                end else begin
                    Bin.Get(TempBinContentBuffer."Location Code", TempBinContentBuffer."Bin Code");
                    WhseLocation.Get(TempBinContentBuffer."Location Code");
                    if WhseLocation."Check Whse. Class" then
                        Bin.CheckWhseClass(TempBinContentBuffer."Item No.", false);
                end;
                OnCheckBinContentOnAfterTempBinContentBufferLoop(TempBinContentBuffer, Bin);
            until TempBinContentBuffer.Next() = 0;
    end;

    local procedure CheckBinContentQtyToHandle(var TempBinContentBuffer: Record "Bin Content Buffer" temporary; var BinContent: Record "Bin Content"; BreakBulkQtyBaseToPlace: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
        AbsQtyToHandle: Decimal;
        AbsQtyToHandleBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBinContentQtyToHandle(TempBinContentBuffer, BinContent, Item, IsHandled, BreakBulkQtyBaseToPlace, GlobalWhseActivHeader);
        if IsHandled then
            exit;

        AbsQtyToHandleBase := Abs(TempBinContentBuffer."Qty. to Handle (Base)");
        AbsQtyToHandle :=
            Round(AbsQtyToHandleBase / UOMMgt.GetQtyPerUnitOfMeasure(Item, TempBinContentBuffer."Unit of Measure Code"), UOMMgt.QtyRndPrecision());
        if BreakBulkQtyBaseToPlace > 0 then
            BinContent.CheckDecreaseBinContent(AbsQtyToHandle, AbsQtyToHandleBase, BreakBulkQtyBaseToPlace - TempBinContentBuffer."Qty. to Handle (Base)")
        else
            BinContent.CheckDecreaseBinContent(AbsQtyToHandle, AbsQtyToHandleBase, Abs(TempBinContentBuffer."Qty. Outstanding (Base)"));
        if AbsQtyToHandleBase <> Abs(TempBinContentBuffer."Qty. to Handle (Base)") then begin
            TempBinContentBuffer."Qty. to Handle (Base)" := AbsQtyToHandleBase * TempBinContentBuffer."Qty. to Handle (Base)" / Abs(TempBinContentBuffer."Qty. to Handle (Base)");
            TempBinContentBuffer.Modify();
        end;
    end;

    local procedure CalcBreakBulkQtyToPlace(TempBinContentBuffer: Record "Bin Content Buffer") QtyBase: Decimal
    var
        BreakBulkWhseActivLine: Record "Warehouse Activity Line";
    begin
        BreakBulkWhseActivLine.SetCurrentKey(
            "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code",
            "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.");
        BreakBulkWhseActivLine.SetRange("Item No.", TempBinContentBuffer."Item No.");
        BreakBulkWhseActivLine.SetRange("Bin Code", TempBinContentBuffer."Bin Code");
        BreakBulkWhseActivLine.SetRange("Location Code", TempBinContentBuffer."Location Code");
        BreakBulkWhseActivLine.SetRange("Action Type", BreakBulkWhseActivLine."Action Type"::Place);
        BreakBulkWhseActivLine.SetRange("Variant Code", TempBinContentBuffer."Variant Code");
        BreakBulkWhseActivLine.SetRange("Unit of Measure Code", TempBinContentBuffer."Unit of Measure Code");
        BreakBulkWhseActivLine.SetFilter("Breakbulk No.", '<>0');
        BreakBulkWhseActivLine.SetRange("Activity Type", GlobalWhseActivHeader.Type);
        BreakBulkWhseActivLine.SetRange("No.", GlobalWhseActivHeader."No.");
        BreakBulkWhseActivLine.SetTrackingFilterFromBinContentBuffer(TempBinContentBuffer);
        if BreakBulkWhseActivLine.Find('-') then
            repeat
                QtyBase := QtyBase + BreakBulkWhseActivLine."Qty. to Handle (Base)";
            until BreakBulkWhseActivLine.Next() = 0;
        exit(QtyBase);
    end;

    local procedure CheckWhseActivLineIsEmpty(var WhseActivLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseActivLineIsEmpty(WhseActivLine, IsHandled, HideDialog);
        if not IsHandled then
            if WhseActivLine.IsEmpty() then
                Error(Text003);
    end;

    local procedure CheckSourceDocumentForAvailableQty(var GroupedWhseActivLine: Record "Warehouse Activity Line")
    var
        SourceJobPlanningLine: Record "Job Planning Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        RemainingQtyBase: Decimal;
        RemainingQtyUoM: Code[10];
        AllowWhseOverpick: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSourceDocumentForAvailableQty(GroupedWhseActivLine, IsHandled);
        if IsHandled then
            exit;

        GroupedWhseActivLine.SetRange("Breakbulk No.", 0);
        if GroupedWhseActivLine.FindSet() then
            repeat
                AllowWhseOverpick := false;
                case GroupedWhseActivLine."Source Document" of
                    "Warehouse Activity Source Document"::"Job Usage":
                        begin
                            SourceJobPlanningLine.SetCurrentKey("Job Contract Entry No.");
                            SourceJobPlanningLine.SetRange("Job Contract Entry No.", GroupedWhseActivLine."Source Line No.");
                            SourceJobPlanningLine.SetLoadFields("Remaining Qty. (Base)", "Unit of Measure Code");
                            SourceJobPlanningLine.FindFirst();
                            RemainingQtyBase := SourceJobPlanningLine."Remaining Qty. (Base)";
                            RemainingQtyUoM := SourceJobPlanningLine."Unit of Measure Code";
                        end;
                    else
                        OnCheckSourceDocumentForAvailabilityBySourceDocument(GroupedWhseActivLine, RemainingQtyBase, RemainingQtyUoM, AllowWhseOverpick);
                end;
                if (GroupedWhseActivLine."Source Document" <> GroupedWhseActivLine."Source Document"::"Prod. Consumption") or (not AllowWhseOverpick) then
                    if UOMMgt.CalcBaseQty(GroupedWhseActivLine."Qty. to Handle", GroupedWhseActivLine."Qty. per Unit of Measure") > RemainingQtyBase then
                        Error(ItemAlreadyConsumedErr, RemainingQtyBase, RemainingQtyUoM, GroupedWhseActivLine.FieldCaption("Line No."), GroupedWhseActivLine."Line No.", GroupedWhseActivLine.FieldCaption("Item No."), GroupedWhseActivLine."Item No.", GroupedWhseActivLine."Source Document", GroupedWhseActivLine."Source No.", GroupedWhseActivLine.FieldCaption("Source Line No."), GroupedWhseActivLine."Source Line No.");
            until GroupedWhseActivLine.Next() = 0;
        GroupedWhseActivLine.SetRange("Breakbulk No.");

        OnAfterCheckSourceDocumentForAvailableQty(GroupedWhseActivLine);
    end;

    /// <summary>
    /// Checks warehouse item trackings for the provided warehouse activity line.
    /// </summary>
    /// <param name="WhseActivLine">Warehouse activity line to check.</param>
    procedure CheckWhseItemTrkgLine(var WhseActivLine: Record "Warehouse Activity Line")
    var
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        QtyAvailToRegisterBase: Decimal;
        QtyAvailToInsertBase: Decimal;
        QtyToRegisterBase: Decimal;
        AllowWhseOverpick: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCheckWhseItemTrkgLine(WhseActivLine);

        if not
           ((WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::Pick) or
            (WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement"))
        then
            exit;

        if WhseActivLine.Find('-') then
            repeat
                TempWhseActivLine := WhseActivLine;
                if not (TempWhseActivLine."Action Type" = TempWhseActivLine."Action Type"::Place) then
                    TempWhseActivLine.Insert();
            until WhseActivLine.Next() = 0;

        TempWhseActivLine.SetCurrentKey("Item No.");
        if TempWhseActivLine.Find('-') then
            repeat
                IsHandled := false;
                OnCheckWhseItemTrkgLineOnAfterTempWhseActivLineFind(TempWhseActivLine, IsHandled);
                if not IsHandled then begin
                    TempWhseActivLine.SetRange("Item No.", TempWhseActivLine."Item No.");
                    if ItemTrackingMgt.GetWhseItemTrkgSetup(TempWhseActivLine."Item No.", WhseItemTrackingSetup) then
                        repeat
                            OnCheckWhseItemTrkgLineOnBeforeTestTracking(TempWhseActivLine, WhseItemTrackingSetup);
                            TempWhseActivLine.TestNonSpecificItemTracking();
                            TempWhseActivLine.TestTrackingIfRequired(WhseItemTrackingSetup);
                        until TempWhseActivLine.Next() = 0
                    else begin
                        TempWhseActivLine.Find('+');
                        TempWhseActivLine.DeleteAll();
                    end;
                    TempWhseActivLine.SetRange("Item No.");
                end;
            until TempWhseActivLine.Next() = 0;

        TempWhseActivLine.Reset();
        TempWhseActivLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.");
        TempWhseActivLine.SetRange("Breakbulk No.", 0);
        OnCheckWhseItemTrkgLineOnAfterTempWhseActivLineSetFilters(TempWhseActivLine);
        if TempWhseActivLine.Find('-') then
            repeat
                ItemTrackingMgt.GetWhseItemTrkgSetup(TempWhseActivLine."Item No.", WhseItemTrackingSetup);
                OnCheckWhseItemTrkgLineOnAfterGetWhseItemTrkgSetup(TempWhseActivLine, WhseItemTrackingSetup);
                // Per document
                TempWhseActivLine.SetSourceFilter(
                  TempWhseActivLine."Source Type", TempWhseActivLine."Source Subtype", TempWhseActivLine."Source No.",
                  TempWhseActivLine."Source Line No.", TempWhseActivLine."Source Subline No.", false);
                repeat
                    // Per Lot/SN
                    TempWhseActivLine.SetRange("Item No.", TempWhseActivLine."Item No.");
                    QtyAvailToInsertBase := CalcQtyAvailToInsertBase(TempWhseActivLine);
                    TempWhseActivLine.SetTrackingFilterFromWhseActivityLine(TempWhseActivLine);
                    OnCheckWhseItemTrkgLineOnBeforeCalcQtyToRegisterBase(TempWhseActivLine, WhseActivLine, QtyAvailToInsertBase);
                    QtyToRegisterBase := 0;
                    repeat
                        QtyToRegisterBase := QtyToRegisterBase + TempWhseActivLine."Qty. to Handle (Base)";
                    until TempWhseActivLine.Next() = 0;

                    QtyAvailToRegisterBase := CalcQtyAvailToRegisterBase(TempWhseActivLine);
                    if QtyToRegisterBase > QtyAvailToRegisterBase then
                        QtyAvailToInsertBase -= QtyToRegisterBase - QtyAvailToRegisterBase;
                    AllowWhseOverpick := false;
                    OnBeforeCheckQtyAvailToInsertBase(TempWhseActivLine, QtyAvailToInsertBase, AllowWhseOverpick);
                    if not AllowWhseOverpick then
                        if QtyAvailToInsertBase < 0 then
                            Error(
                              InsufficientQtyItemTrkgErr, TempWhseActivLine."Source Line No.", TempWhseActivLine."Source Document",
                              TempWhseActivLine."Source No.");

                    if TempWhseActivLine.TrackingExists() then begin
                        WhseItemTrackingSetup.CopyTrackingFromWhseActivityLine(TempWhseActivLine);
                        if not IsQtyAvailToPickNonSpecificReservation(TempWhseActivLine, WhseItemTrackingSetup, QtyToRegisterBase) then
                            AvailabilityError(TempWhseActivLine);
                    end;

                    // Clear filters, Lot/SN
                    TempWhseActivLine.ClearTrackingFilter();
                    TempWhseActivLine.SetRange("Item No.");
                    OnCheckWhseItemTrkgLineOnAfterClearFilters(TempWhseActivLine, WhseActivLine);
                until TempWhseActivLine.Next() = 0; // Per Lot/SN
                                                    // Clear filters, document
                TempWhseActivLine.ClearSourceFilter();
            until TempWhseActivLine.Next() = 0;   // Per document
    end;

    local procedure RegisterWhseItemTrkgLine(WhseActivLine2: Record "Warehouse Activity Line")
    var
        JobPlanningLineRec: Record "Job Planning Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        QtyToRegisterBase: Decimal;
        DueDate: Date;
        NextEntryNo: Integer;
        WhseDocType2: Enum "Warehouse Activity Document Type";
        NeedRegisterWhseItemTrkgLine: Boolean;
        WhseItemTrkgSetupExists: Boolean;
    begin
        if ((WhseActivLine2."Whse. Document Type" in
            [WhseActivLine2."Whse. Document Type"::Shipment, WhseActivLine2."Whse. Document Type"::"Internal Pick",
            WhseActivLine2."Whse. Document Type"::Production, WhseActivLine2."Whse. Document Type"::Assembly, WhseActivLine2."Whse. Document Type"::"Internal Put-away", WhseActivLine2."Whse. Document Type"::Job]) and
            (WhseActivLine2."Action Type" <> WhseActivLine2."Action Type"::Take) and (WhseActivLine2."Breakbulk No." = 0)) or
            ((WhseActivLine2."Whse. Document Type" = WhseActivLine2."Whse. Document Type"::Receipt) and (WhseActivLine2."Action Type" <> WhseActivLine2."Action Type"::Place) and (WhseActivLine2."Breakbulk No." = 0)) or
            ((WhseActivLine2."Source Document" = WhseActivLine2."Source Document"::"Prod. Output") and (WhseActivLine2."Action Type" <> WhseActivLine2."Action Type"::Place) and (WhseActivLine2."Breakbulk No." = 0))
        then
            NeedRegisterWhseItemTrkgLine := true;

        if (WhseActivLine2."Activity Type" = WhseActivLine2."Activity Type"::"Invt. Movement") and (WhseActivLine2."Action Type" <> WhseActivLine2."Action Type"::Take) and
           (WhseActivLine2."Source Document" in [WhseActivLine2."Source Document"::"Prod. Consumption", WhseActivLine2."Source Document"::"Assembly Consumption", WhseActivLine2."Source Document"::"Job Usage"])
        then
            NeedRegisterWhseItemTrkgLine := true;

        if not NeedRegisterWhseItemTrkgLine then
            exit;

        WhseItemTrkgSetupExists := ItemTrackingMgt.GetWhseItemTrkgSetup(WhseActivLine2."Item No.");
        OnRegisterWhseItemTrkgLineOnAfterCalcWhseItemTrkgSetupExists(WhseActivLine2, ItemTrackingMgt, WhseItemTrkgSetupExists);
        if not WhseItemTrkgSetupExists then
            exit;

        QtyToRegisterBase := InitTempTrackingSpecification(WhseActivLine2, TempTrackingSpecification);

        TempTrackingSpecification.Reset();

        if WhseActivLine2."Source Document" = WhseActivLine2."Source Document"::"Prod. Output" then
            exit;

        if QtyToRegisterBase > 0 then begin
            if (WhseActivLine2."Activity Type" = WhseActivLine2."Activity Type"::Pick) or
               (WhseActivLine2."Activity Type" = WhseActivLine2."Activity Type"::"Invt. Movement")
            then
                InsertRegWhseItemTrkgLine(WhseActivLine2, QtyToRegisterBase);

            if (WhseActivLine2."Whse. Document Type" in
                [WhseActivLine2."Whse. Document Type"::Shipment,
                 WhseActivLine2."Whse. Document Type"::Production,
                 WhseActivLine2."Whse. Document Type"::Assembly,
                 WhseActivLine2."Whse. Document Type"::Job]) or
               ((WhseActivLine2."Activity Type" = WhseActivLine2."Activity Type"::"Invt. Movement") and
                (WhseActivLine2."Source Type" > 0))
            then begin
                OnRegisterWhseItemTrkgLineOnBeforeCreateSpecification(WhseActivLine2, DueDate);

                if (WhseActivLine2."Whse. Document Type" = WhseActivLine2."Whse. Document Type"::Shipment) and
                   WhseActivLine2."Assemble to Order"
                then
                    WhseDocType2 := WhseActivLine2."Whse. Document Type"::Assembly
                else
                    WhseDocType2 := WhseActivLine2."Whse. Document Type";
                case WhseDocType2 of
                    WhseActivLine2."Whse. Document Type"::Shipment:
                        begin
                            WhseShptLine.SetLoadFields("Shipment Date");
                            WhseShptLine.Get(WhseActivLine2."Whse. Document No.", WhseActivLine2."Whse. Document Line No.");
                            DueDate := WhseShptLine."Shipment Date";
                        end;
                    WhseActivLine2."Whse. Document Type"::Job:
                        begin
                            JobPlanningLineRec.SetRange("Job Contract Entry No.", WhseActivLine2."Source Line No.");
                            JobPlanningLineRec.SetLoadFields("Planning Due Date");
                            if JobPlanningLineRec.FindFirst() then
                                DueDate := JobPlanningLineRec."Planning Due Date";
                        end;
                    else
                        OnRegisterWhseItemTrkgLineOnSetDueDate(WhseActivLine2, DueDate, QtyToRegisterBase, WhseDocType2);
                end;

                OnRegisterWhseItemTrkgLineOnAfterSetDueDate(WhseActivLine2, DueDate, QtyToRegisterBase, WhseDocType2);

                if WhseActivLine2."Activity Type" = WhseActivLine2."Activity Type"::"Invt. Movement" then
                    OnRegisterWhseItemTrkgLineOnAfterSetDueDateForInvtMovement(WhseActivLine2, DueDate);

                NextEntryNo := TempTrackingSpecification.GetLastEntryNo() + 1;

                TempTrackingSpecification.Init();
                TempTrackingSpecification."Entry No." := NextEntryNo;
                case WhseActivLine2."Source Type" of
                    5407: // Database::"Prod. Order Component"
                        TempTrackingSpecification.SetSource(
                          WhseActivLine2."Source Type", WhseActivLine2."Source Subtype", WhseActivLine2."Source No.",
                          WhseActivLine2."Source Subline No.", '', WhseActivLine2."Source Line No.");
                    Database::Job:
                        TempTrackingSpecification.SetSource(
                              Database::"Job Planning Line", 2, WhseActivLine2."Source No.", WhseActivLine2."Source Line No.", '', 0);
                    else
                        TempTrackingSpecification.SetSource(
                          WhseActivLine2."Source Type", WhseActivLine2."Source Subtype", WhseActivLine2."Source No.",
                          WhseActivLine2."Source Line No.", '', 0);
                end;
                TempTrackingSpecification."Creation Date" := DueDate;
                TempTrackingSpecification."Qty. to Handle (Base)" := QtyToRegisterBase;
                TempTrackingSpecification."Item No." := WhseActivLine2."Item No.";
                TempTrackingSpecification."Variant Code" := WhseActivLine2."Variant Code";
                TempTrackingSpecification."Location Code" := WhseActivLine2."Location Code";
                TempTrackingSpecification.Description := WhseActivLine2.Description;
                TempTrackingSpecification."Qty. per Unit of Measure" := WhseActivLine2."Qty. per Unit of Measure";
                TempTrackingSpecification.CopyTrackingFromWhseActivityLine(WhseActivLine2);
                TempTrackingSpecification."Warranty Date" := WhseActivLine2."Warranty Date";
                TempTrackingSpecification."Expiration Date" := WhseActivLine2."Expiration Date";
                TempTrackingSpecification."Quantity (Base)" := QtyToRegisterBase;
                OnBeforeRegWhseItemTrkgLine(WhseActivLine2, TempTrackingSpecification);
                TempTrackingSpecification.Insert();
                OnAfterRegWhseItemTrkgLine(WhseActivLine2, TempTrackingSpecification);
            end;
        end;
    end;

    local procedure InitTempTrackingSpecification(WhseActivLine2: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary) QtyToRegisterBase: Decimal
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        QtyToHandleBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitTempTrackingSpecification(WhseActivLine2, QtyToRegisterBase, IsHandled);
        if IsHandled then
            exit(QtyToRegisterBase);

        QtyToRegisterBase := WhseActivLine2."Qty. to Handle (Base)";
        SetPointerFilter(WhseActivLine2, WhseItemTrkgLine);

        WhseItemTrkgLine.SetTrackingFilterFromWhseActivityLine(WhseActivLine2);
        if WhseItemTrkgLine.FindSet() then
            repeat
                if WhseItemTrkgLine."Quantity (Base)" > WhseItemTrkgLine."Qty. Registered (Base)" then begin
                    if QtyToRegisterBase > (WhseItemTrkgLine."Quantity (Base)" - WhseItemTrkgLine."Qty. Registered (Base)") then begin
                        QtyToHandleBase := WhseItemTrkgLine."Quantity (Base)" - WhseItemTrkgLine."Qty. Registered (Base)";
                        QtyToRegisterBase := QtyToRegisterBase - QtyToHandleBase;
                        WhseItemTrkgLine."Qty. Registered (Base)" := WhseItemTrkgLine."Quantity (Base)";
                    end else begin
                        WhseItemTrkgLine."Qty. Registered (Base)" += QtyToRegisterBase;
                        QtyToHandleBase := QtyToRegisterBase;
                        QtyToRegisterBase := 0;
                    end;
                    if not UpdateTempTracking(WhseActivLine2, QtyToHandleBase, TempTrackingSpecification) then begin
                        TempTrackingSpecification.SetTrackingKey();
                        TempTrackingSpecification.SetTrackingFilterFromWhseActivityLine(WhseActivLine2);
                        if TempTrackingSpecification.FindFirst() then begin
                            TempTrackingSpecification."Qty. to Handle (Base)" += QtyToHandleBase;
                            OnInitTempTrackingSpecificationOnBeforeTempTrackingSpecificationModify(WhseItemTrkgLine, WhseActivLine2, TempTrackingSpecification);
                            TempTrackingSpecification.Modify();
                        end;
                    end;
                    ItemTrackingMgt.SetRegistering(true);
                    ItemTrackingMgt.CalcWhseItemTrkgLine(WhseItemTrkgLine);
                    WhseItemTrkgLine.Modify();
                end;
            until (WhseItemTrkgLine.Next() = 0) or (QtyToRegisterBase = 0);
    end;

    local procedure CalcQtyAvailToRegisterBase(WhseActivLine: Record "Warehouse Activity Line"): Decimal
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        SetPointerFilter(WhseActivLine, WhseItemTrackingLine);
        WhseItemTrackingLine.SetTrackingFilterFromWhseActivityLine(WhseActivLine);
        WhseItemTrackingLine.CalcSums("Quantity (Base)", "Qty. Registered (Base)");
        exit(WhseItemTrackingLine."Quantity (Base)" - WhseItemTrackingLine."Qty. Registered (Base)");
    end;

    local procedure SourceLineQtyBase(WhseActivLine: Record "Warehouse Activity Line"): Decimal
    var
        WhsePostedRcptLine: Record "Posted Whse. Receipt Line";
        WhseShipmentLine: Record "Warehouse Shipment Line";
        WhseIntPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseIntPickLine: Record "Whse. Internal Pick Line";
        JobPlanningLineRec: Record "Job Planning Line";
        WhseMovementWksh: Record "Whse. Worksheet Line";
        WhseActivLine2: Record "Warehouse Activity Line";
        QtyBase: Decimal;
        WhseDocType2: Enum "Warehouse Activity Document Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSourceLineQtyBase(WhseActivLine, QtyBase, IsHandled);
        if IsHandled then
            exit(QtyBase);

        if (WhseActivLine."Whse. Document Type" = WhseActivLine."Whse. Document Type"::Shipment) and
           WhseActivLine."Assemble to Order"
        then
            WhseDocType2 := WhseActivLine."Whse. Document Type"::Assembly
        else
            WhseDocType2 := WhseActivLine."Whse. Document Type";

        case WhseDocType2 of
            WhseActivLine."Whse. Document Type"::Receipt:
                if WhsePostedRcptLine.Get(
                     WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.")
                then
                    exit(WhsePostedRcptLine."Qty. (Base)");
            WhseActivLine."Whse. Document Type"::Shipment:
                if WhseShipmentLine.Get(
                     WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.")
                then
                    exit(WhseShipmentLine."Qty. (Base)");
            WhseActivLine."Whse. Document Type"::"Internal Put-away":
                if WhseIntPutAwayLine.Get(
                     WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.")
                then
                    exit(WhseIntPutAwayLine."Qty. (Base)");
            WhseActivLine."Whse. Document Type"::"Internal Pick":
                if WhseIntPickLine.Get(
                     WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.")
                then
                    exit(WhseIntPickLine."Qty. (Base)");
            WhseActivLine."Whse. Document Type"::Production:
                exit(GetSourceLineBaseQtyByWhseActivityDocumentType(WhseActivLine, WhseDocType2));
            WhseActivLine."Whse. Document Type"::Assembly:
                exit(GetSourceLineBaseQtyByWhseActivityDocumentType(WhseActivLine, WhseDocType2));
            WhseActivLine."Whse. Document Type"::Job:
                begin
                    JobPlanningLineRec.SetRange("Job Contract Entry No.", WhseActivLine."Source Line No.");
                    JobPlanningLineRec.SetLoadFields("Quantity (Base)");
                    if JobPlanningLineRec.FindFirst() then
                        exit(JobPlanningLineRec."Quantity (Base)");
                end;
            WhseActivLine."Whse. Document Type"::"Movement Worksheet":
                if WhseMovementWksh.Get(
                     WhseActivLine."Whse. Document No.", WhseActivLine."Source No.",
                     WhseActivLine."Location Code", WhseActivLine."Source Line No.")
                then
                    exit(WhseMovementWksh."Qty. (Base)");
        end;

        if WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement" then
            case WhseActivLine."Source Document" of
                WhseActivLine."Source Document"::"Prod. Consumption":
                    exit(GetSourceLineBaseQtyByWhseActivitySourceType(WhseActivLine));
                WhseActivLine."Source Document"::"Assembly Consumption":
                    exit(GetSourceLineBaseQtyByWhseActivitySourceType(WhseActivLine));
                WhseActivLine."Source Document"::" ":
                    begin
                        QtyBase := 0;
                        WhseActivLine2.SetCurrentKey("No.", "Line No.", "Activity Type");
                        WhseActivLine2.SetRange("Activity Type", WhseActivLine."Activity Type");
                        WhseActivLine2.SetRange("No.", WhseActivLine."No.");
                        WhseActivLine2.SetFilter("Action Type", '<%1', WhseActivLine2."Action Type"::Place);
                        WhseActivLine2.SetFilter("Qty. to Handle (Base)", '<>0');
                        WhseActivLine2.SetRange("Breakbulk No.", 0);
                        if WhseActivLine2.Find('-') then
                            repeat
                                QtyBase += WhseActivLine2."Qty. (Base)";
                            until WhseActivLine2.Next() = 0;
                        exit(QtyBase);
                    end;
            end;
    end;

    local procedure GetSourceLineBaseQtyByWhseActivitySourceType(var WhseActivLine: Record "Warehouse Activity Line") QtyBase: Decimal
    begin
        OnGetSourceLineBaseQtyByWhseActivitySourceType(WhseActivLine, QtyBase);
    end;

    local procedure GetSourceLineBaseQtyByWhseActivityDocumentType(var WhseActivLine: Record "Warehouse Activity Line"; WhseDocType: Enum "Warehouse Activity Document Type") QtyBase: Decimal
    begin
        OnGetSourceLineBaseQtyByWhseActivityDocumentType(WhseActivLine, WhseDocType, QtyBase);
    end;

    local procedure CalcQtyAvailToInsertBase(WhseActivLine: Record "Warehouse Activity Line"): Decimal
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        SetPointerFilter(WhseActivLine, WhseItemTrkgLine);
        WhseItemTrkgLine.CalcSums(WhseItemTrkgLine."Quantity (Base)");
        exit(SourceLineQtyBase(WhseActivLine) - WhseItemTrkgLine."Quantity (Base)");
    end;

    local procedure CalcQtyReservedOnInventory(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        GetItem(WhseActivLine."Item No.");
        Item.SetRange("Location Filter", WhseActivLine."Location Code");
        Item.SetRange("Variant Filter", WhseActivLine."Variant Code");
        WhseActivLine.SetTrackingFilterToItemIfRequired(Item, WhseItemTrackingSetup);
        Item.CalcFields("Reserved Qty. on Inventory");
    end;

    local procedure InsertRegWhseItemTrkgLine(WhseActivLine: Record "Warehouse Activity Line"; QtyToRegisterBase: Decimal)
    var
        WhseItemTrkgLine2: Record "Whse. Item Tracking Line";
        NextEntryNo: Integer;
    begin
        NextEntryNo := WhseItemTrkgLine2.GetLastEntryNo() + 1;

        WhseItemTrkgLine2.Init();
        WhseItemTrkgLine2."Entry No." := NextEntryNo;
        WhseItemTrkgLine2."Item No." := WhseActivLine."Item No.";
        WhseItemTrkgLine2.Description := WhseActivLine.Description;
        WhseItemTrkgLine2."Variant Code" := WhseActivLine."Variant Code";
        WhseItemTrkgLine2."Location Code" := WhseActivLine."Location Code";
        SetPointer(WhseActivLine, WhseItemTrkgLine2);
        WhseItemTrkgLine2.CopyTrackingFromWhseActivityLine(WhseActivLine);
        WhseItemTrkgLine2."Warranty Date" := WhseActivLine."Warranty Date";
        WhseItemTrkgLine2."Expiration Date" := WhseActivLine."Expiration Date";
        WhseItemTrkgLine2."Quantity (Base)" := QtyToRegisterBase;
        WhseItemTrkgLine2."Qty. per Unit of Measure" := WhseActivLine."Qty. per Unit of Measure";
        WhseItemTrkgLine2."Qty. Registered (Base)" := QtyToRegisterBase;
        WhseItemTrkgLine2."Created by Whse. Activity Line" := true;
        OnInsertRegWhseItemTrkgLineOnAfterCopyFields(WhseItemTrkgLine2, WhseActivLine);

        ItemTrackingMgt.SetRegistering(true);
        ItemTrackingMgt.CalcWhseItemTrkgLine(WhseItemTrkgLine2);
        WhseItemTrkgLine2.Insert();
        OnAfterInsRegWhseItemTrkgLine(WhseActivLine, WhseItemTrkgLine2);
    end;

    /// <summary>
    /// Sets the warehouse item tracking source based on the provided warehouse activity line warehouse document type.
    /// </summary>
    /// <param name="WhseActivLine">Warehouse activity line.</param>
    /// <param name="WhseItemTrkgLine">Warehouse item tracking line to set the source for.</param>
    procedure SetPointer(WhseActivLine: Record "Warehouse Activity Line"; var WhseItemTrkgLine: Record "Whse. Item Tracking Line")
    var
        WhseDocType2: Enum "Warehouse Activity Document Type";
    begin
        if (WhseActivLine."Whse. Document Type" = WhseActivLine."Whse. Document Type"::Shipment) and WhseActivLine."Assemble to Order" then
            WhseDocType2 := WhseActivLine."Whse. Document Type"::Assembly
        else
            WhseDocType2 := WhseActivLine."Whse. Document Type";
        case WhseDocType2 of
            WhseActivLine."Whse. Document Type"::Receipt:
                WhseItemTrkgLine.SetSource(
                  Database::"Posted Whse. Receipt Line", 0, WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.", '', 0);
            WhseActivLine."Whse. Document Type"::Shipment:
                WhseItemTrkgLine.SetSource(
                  Database::"Warehouse Shipment Line", 0, WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.", '', 0);
            WhseActivLine."Whse. Document Type"::"Internal Put-away":
                WhseItemTrkgLine.SetSource(
                  Database::"Whse. Internal Put-away Line", 0, WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.", '', 0);
            WhseActivLine."Whse. Document Type"::"Internal Pick":
                WhseItemTrkgLine.SetSource(
                  Database::"Whse. Internal Pick Line", 0, WhseActivLine."Whse. Document No.", WhseActivLine."Whse. Document Line No.", '', 0);
            WhseActivLine."Whse. Document Type"::Production:
                WhseItemTrkgLine.SetSource(
                  5407, WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Subline No.", '', WhseActivLine."Source Line No."); // Database::"Prod. Order Component"
            WhseActivLine."Whse. Document Type"::Assembly:
                WhseItemTrkgLine.SetSource(
                  901, WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", '', 0); // Database::"Assembly Line"
            WhseActivLine."Whse. Document Type"::Job:
                WhseItemTrkgLine.SetSource(
                  Database::"Job Planning Line", 2, WhseActivLine."Source No.", WhseActivLine."Source Line No.", '', 0);
            WhseActivLine."Whse. Document Type"::"Movement Worksheet":
                WhseItemTrkgLine.SetSource(
                  Database::"Whse. Worksheet Line", 0, WhseActivLine."Source No.", WhseActivLine."Whse. Document Line No.",
                  CopyStr(WhseActivLine."Whse. Document No.", 1, MaxStrLen(WhseItemTrkgLine."Source Batch Name")), 0);
        end;
        OnSetPointerOnAfterWhseDocTypeSetSource(WhseActivLine, WhseDocType2.AsInteger(), WhseItemTrkgLine);
        WhseItemTrkgLine."Location Code" := WhseActivLine."Location Code";
        if WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement" then begin
            WhseItemTrkgLine.SetSource(WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", '', 0);
            if WhseActivLine."Source Type" = 5407 then // Database::"Prod. Order Component"
                WhseItemTrkgLine.SetSource(WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Subline No.", '', WhseActivLine."Source Line No.")
            else
                WhseItemTrkgLine.SetSource(WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", '', 0);
            WhseItemTrkgLine."Location Code" := WhseActivLine."Location Code";
        end;
    end;

    /// <summary>
    /// Sets filters on the warehouse item tracking line based on the provided warehouse activity line.
    /// </summary>
    /// <param name="WhseActivLine">Warehouse activity line source information.</param>
    /// <param name="WhseItemTrkgLine">Warehouse item tracking line to filter.</param>
    procedure SetPointerFilter(WhseActivLine: Record "Warehouse Activity Line"; var WhseItemTrkgLine: Record "Whse. Item Tracking Line")
    var
        WhseItemTrkgLine2: Record "Whse. Item Tracking Line";
    begin
        SetPointer(WhseActivLine, WhseItemTrkgLine2);
        WhseItemTrkgLine.SetSourceFilter(
          WhseItemTrkgLine2."Source Type", WhseItemTrkgLine2."Source Subtype",
          WhseItemTrkgLine2."Source ID", WhseItemTrkgLine2."Source Ref. No.", true);
        WhseItemTrkgLine.SetSourceFilter(WhseItemTrkgLine2."Source Batch Name", WhseItemTrkgLine2."Source Prod. Order Line");
        WhseItemTrkgLine.SetRange("Location Code", WhseItemTrkgLine2."Location Code");
    end;

    /// <summary>
    /// Shows or hides a dialog based on the provided value.
    /// </summary>
    /// <param name="HideDialog2">Indicates whether  the dialog should be show hidden 'true' or shown 'false'</param>
    procedure ShowHideDialog(HideDialog2: Boolean)
    begin
        HideDialog := HideDialog2;
    end;

    /// <summary>
    /// Calculates the total available quantity to pick based on the provided warehouse activity line and item tracking setup.
    /// </summary>
    /// <param name="WhseActivLine">Warehouse activity line.</param>
    /// <param name="WhseItemTrackingSetup">Item tracking setup.</param>
    /// <returns>Returns total available quantity to pick in base units.</returns>
    procedure CalcTotalAvailQtyToPick(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        TempWhseActivLine2: Record "Warehouse Activity Line" temporary;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseActivLineItemTrackingSetup: Record "Item Tracking Setup";
        CreatePick: Codeunit "Create Pick";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        BinTypeFilter: Text;
        TotalAvailQtyBase: Decimal;
        QtyInWhseBase: Decimal;
        QtyOnPickBinsBase: Decimal;
        QtyOnOutboundBinsBase: Decimal;
        QtyOnDedicatedBinsBase: Decimal;
        SubTotalBase: Decimal;
        QtyReservedOnPickShipBase: Decimal;
        LineReservedQtyBase: Decimal;
        QtyPickedNotShipped: Decimal;
    begin
        CalcQtyReservedOnInventory(WhseActivLine, WhseItemTrackingSetup);

        LocationGet(WhseActivLine."Location Code");
        if Location."Directed Put-away and Pick" or
           (WhseActivLine."Activity Type" = WhseActivLine."Activity Type"::"Invt. Movement")
        then begin
            WhseEntry.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code");
            WhseEntry.SetRange("Item No.", WhseActivLine."Item No.");
            WhseEntry.SetRange("Location Code", WhseActivLine."Location Code");
            WhseEntry.SetRange("Variant Code", WhseActivLine."Variant Code");
            WhseActivLine.SetTrackingFilterToWhseEntryIfRequired(WhseEntry, WhseItemTrackingSetup);
            WhseEntry.CalcSums("Qty. (Base)");
            QtyInWhseBase := WhseEntry."Qty. (Base)";
            OnCalcTotalAvailQtyToPickOnAfterCalcQtyInWhseBase(WhseEntry, QtyInWhseBase, WhseActivLine."Location Code");

            BinTypeFilter := CreatePick.GetBinTypeFilter(0);
            if BinTypeFilter <> '' then
                WhseEntry.SetFilter("Bin Type Code", '<>%1', BinTypeFilter);
            // Pick from all but Receive area
            WhseEntry.CalcSums("Qty. (Base)");
            QtyOnPickBinsBase := WhseEntry."Qty. (Base)";

            QtyOnOutboundBinsBase :=
                WhseAvailMgt.CalcQtyOnOutboundBins(WhseActivLine."Location Code", WhseActivLine."Item No.", WhseActivLine."Variant Code", WhseItemTrackingSetup, true);

            if WhseActivLine."Activity Type" <> WhseActivLine."Activity Type"::"Invt. Movement" then begin// Invt. Movement from Dedicated Bin is allowed
                WhseActivLineItemTrackingSetup.CopyTrackingFromWhseActivityLine(WhseActivLine);
                QtyOnDedicatedBinsBase :=
                    WhseAvailMgt.CalcQtyOnDedicatedBins(WhseActivLine."Location Code", WhseActivLine."Item No.", WhseActivLine."Variant Code", WhseActivLineItemTrackingSetup);
            end;

            SubTotalBase :=
              QtyInWhseBase -
              QtyOnPickBinsBase - QtyOnOutboundBinsBase - QtyOnDedicatedBinsBase;

            if (WhseActivLine."Action Type" = WhseActivLine."Action Type"::Take) and (WhseActivLine."Bin Code" = Location."Shipment Bin Code") then
                SubTotalBase += QtyOnOutboundBinsBase;

            if WhseActivLine."Activity Type" <> WhseActivLine."Activity Type"::"Invt. Movement" then
                SubTotalBase -= Abs(Item."Reserved Qty. on Inventory");

            if SubTotalBase < 0 then begin
                WhseItemTrackingSetup.CopyTrackingFromWhseActivityLine(WhseActivLine);
                CreatePick.FilterWhsePickLinesWithUndefinedBin(
                  WarehouseActivityLine, WhseActivLine."Item No.", WhseActivLine."Location Code", WhseActivLine."Variant Code", WhseItemTrackingSetup);
                if WarehouseActivityLine.FindSet() then
                    repeat
                        TempWhseActivLine2 := WarehouseActivityLine;
                        TempWhseActivLine2."Qty. Outstanding (Base)" *= -1;
                        TempWhseActivLine2.Insert();
                    until WarehouseActivityLine.Next() = 0;

                QtyReservedOnPickShipBase :=
                  WhseAvailMgt.CalcReservQtyOnPicksShips(WhseActivLine."Location Code", WhseActivLine."Item No.", WhseActivLine."Variant Code", TempWhseActivLine2);

                LineReservedQtyBase :=
                  WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.", true, TempWhseActivLine2);

                if Abs(SubTotalBase) < QtyReservedOnPickShipBase + LineReservedQtyBase then
                    QtyReservedOnPickShipBase := Abs(SubTotalBase) - LineReservedQtyBase;

                TotalAvailQtyBase :=
                  QtyOnPickBinsBase +
                  SubTotalBase +
                  QtyReservedOnPickShipBase +
                  LineReservedQtyBase;
            end else
                TotalAvailQtyBase := QtyOnPickBinsBase;
        end else begin
            ItemLedgEntry.SetRange("Item No.", WhseActivLine."Item No.");
            ItemLedgEntry.SetRange("Variant Code", WhseActivLine."Variant Code");
            ItemLedgEntry.SetRange(Open, true);
            ItemLedgEntry.SetRange("Location Code", WhseActivLine."Location Code");
            WhseActivLine.SetTrackingFilterToItemLedgEntryIfRequired(ItemLedgEntry, WhseItemTrackingSetup);
            ItemLedgEntry.CalcSums("Remaining Quantity");
            OnCalcTotalAvailQtyToPickOnAfterItemLedgEntryCalcSums(WhseActivLine);
            QtyInWhseBase := ItemLedgEntry."Remaining Quantity";

            QtyPickedNotShipped := CalcQtyPickedNotShipped(WhseActivLine, WhseItemTrackingSetup);

            LineReservedQtyBase :=
                WhseAvailMgt.CalcLineReservedQtyOnInvt(
                    WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", WhseActivLine."Source Subline No.", false, WhseItemTrackingSetup, WhseActivLine);

            TotalAvailQtyBase :=
              QtyInWhseBase -
              QtyPickedNotShipped -
              Abs(Item."Reserved Qty. on Inventory") +
              LineReservedQtyBase;
        end;

        exit(TotalAvailQtyBase);
    end;

    local procedure IsQtyAvailToPickNonSpecificReservation(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyToRegister: Decimal): Boolean
    var
        QtyAvailToPick: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsQtyAvailToPickNonSpecificReservation(WhseActivLine, QtyAvailToPick, QtyToRegister, IsHandled);
        if not IsHandled then begin
            QtyAvailToPick := CalcTotalAvailQtyToPick(WhseActivLine, WhseItemTrackingSetup);
            if QtyAvailToPick < QtyToRegister then
                if ReleaseNonSpecificReservations(WhseActivLine, WhseItemTrackingSetup, QtyToRegister - QtyAvailToPick) then
                    QtyAvailToPick := CalcTotalAvailQtyToPick(WhseActivLine, WhseItemTrackingSetup);
        end;
        exit(QtyAvailToPick >= QtyToRegister);
    end;

    local procedure CalcQtyPickedNotShipped(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup") QtyBasePicked: Decimal
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.Reset();
        ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
        ReservEntry.SetRange("Item No.", WhseActivLine."Item No.");
        ReservEntry.SetRange("Variant Code", WhseActivLine."Variant Code");
        ReservEntry.SetRange("Location Code", WhseActivLine."Location Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Surplus);
        ReservEntry.SetTrackingFilterFromWhseActivityLineIfRequired(WhseActivLine, WhseItemTrackingSetup);
        OnCalcQtyPickedNotShippedOnAfterReservEntrySetFilters(ReservEntry, WhseActivLine);
        if ReservEntry.Find('-') then
            repeat
                if WhseActivLine."Source Type" = Database::Job then begin
                    if not ((ReservEntry."Source Type" = Database::"Job Planning Line") and
                                                    (ReservEntry."Source Subtype" = 2) and
                                                    (ReservEntry."Source ID" = WhseActivLine."Source No.") and
                                                    ((ReservEntry."Source Ref. No." = WhseActivLine."Source Line No.") or
                                                     (ReservEntry."Source Ref. No." = WhseActivLine."Source Subline No."))) and
                                               not ReservEntry.Positive
                                            then
                        QtyBasePicked := QtyBasePicked + Abs(ReservEntry."Quantity (Base)");
                end else
                    if not ((ReservEntry."Source Type" = WhseActivLine."Source Type") and
                            (ReservEntry."Source Subtype" = WhseActivLine."Source Subtype") and
                            (ReservEntry."Source ID" = WhseActivLine."Source No.") and
                            ((ReservEntry."Source Ref. No." = WhseActivLine."Source Line No.") or
                             (ReservEntry."Source Ref. No." = WhseActivLine."Source Subline No."))) and
                       not ReservEntry.Positive
                    then
                        QtyBasePicked := QtyBasePicked + Abs(ReservEntry."Quantity (Base)");
            until ReservEntry.Next() = 0;

        CalcQtyBasePicked(WhseActivLine, WhseItemTrackingSetup, QtyBasePicked);

        exit(QtyBasePicked);
    end;

    local procedure CalcQtyBasePicked(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var QtyBasePicked: Decimal)
    var
        RegWhseActivLine: Record "Registered Whse. Activity Line";
        QtyHandled: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyBasePicked(WhseActivLine, WhseItemTrackingSetup, QtyBasePicked, IsHandled);
        if IsHandled then
            exit;

        if WhseItemTrackingSetup."Serial No. Required" or WhseItemTrackingSetup."Lot No. Required" or WhseItemTrackingSetup."Package No. Required" then begin
            RegWhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type");
            RegWhseActivLine.SetRange("No.", WhseActivLine."No.");
            RegWhseActivLine.SetRange("Line No.", WhseActivLine."Line No.");
            RegWhseActivLine.SetTrackingFilterFromWhseActivityLine(WhseActivLine);
            RegWhseActivLine.SetRange("Bin Code", WhseActivLine."Bin Code");
            if RegWhseActivLine.FindSet() then
                repeat
                    QtyHandled := QtyHandled + RegWhseActivLine."Qty. (Base)";
                until RegWhseActivLine.Next() = 0;
            QtyBasePicked := QtyBasePicked + QtyHandled;
        end else
            QtyBasePicked := QtyBasePicked + WhseActivLine."Qty. Handled (Base)";
    end;

    /// <summary>
    /// Retrieves the global Item record based on the 'ItemNo' parameter.
    /// </summary>
    /// <param name="ItemNo">Specified itme number.</param>
    procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> Item."No." then
            Item.Get(ItemNo);
    end;

    local procedure UpdateTempTracking(WhseActivLine2: Record "Warehouse Activity Line"; QtyToHandleBase: Decimal; var TempTrackingSpecification: Record "Tracking Specification" temporary): Boolean
    var
        NextEntryNo: Integer;
        Inserted: Boolean;
    begin
        NextEntryNo := TempTrackingSpecification.GetLastEntryNo() + 1;
        TempTrackingSpecification.Init();
        if WhseActivLine2."Source Type" = 5407 then // Database::"Prod. Order Component"
            TempTrackingSpecification.SetSource(WhseActivLine2."Source Type", WhseActivLine2."Source Subtype", WhseActivLine2."Source No.", WhseActivLine2."Source Subline No.", '', WhseActivLine2."Source Line No.")
        else
            TempTrackingSpecification.SetSource(WhseActivLine2."Source Type", WhseActivLine2."Source Subtype", WhseActivLine2."Source No.", WhseActivLine2."Source Line No.", '', 0);

        ItemTrackingMgt.SetPointerFilter(TempTrackingSpecification);
        TempTrackingSpecification.SetTrackingFilterFromWhseActivityLine(WhseActivLine2);
        if TempTrackingSpecification.IsEmpty() then begin
            TempTrackingSpecification."Entry No." := NextEntryNo;
            TempTrackingSpecification."Creation Date" := Today;
            TempTrackingSpecification."Qty. to Handle (Base)" := QtyToHandleBase;
            TempTrackingSpecification."Item No." := WhseActivLine2."Item No.";
            TempTrackingSpecification."Variant Code" := WhseActivLine2."Variant Code";
            TempTrackingSpecification."Location Code" := WhseActivLine2."Location Code";
            TempTrackingSpecification.Description := WhseActivLine2.Description;
            TempTrackingSpecification."Qty. per Unit of Measure" := WhseActivLine2."Qty. per Unit of Measure";
            TempTrackingSpecification.CopyTrackingFromWhseActivityLine(WhseActivLine2);
            TempTrackingSpecification."Warranty Date" := WhseActivLine2."Warranty Date";
            TempTrackingSpecification."Expiration Date" := WhseActivLine2."Expiration Date";
            TempTrackingSpecification.Correction := true;
            OnBeforeTempTrackingSpecificationInsert(TempTrackingSpecification, WhseActivLine2);
            TempTrackingSpecification.Insert();
            Inserted := true;
            TempTrackingSpecification.Reset();
            OnAfterRegWhseItemTrkgLine(WhseActivLine2, TempTrackingSpecification);
        end;
        exit(Inserted);
    end;

    local procedure CheckItemTrackingInfoBlocked(WhseActivityLine: Record "Warehouse Activity Line")
    var
        SerialNoInfo: Record "Serial No. Information";
        LotNoInfo: Record "Lot No. Information";
    begin
        if not WhseActivityLine.TrackingExists() then
            exit;

        if WhseActivityLine."Serial No." <> '' then
            if SerialNoInfo.Get(WhseActivityLine."Item No.", WhseActivityLine."Variant Code", WhseActivityLine."Serial No.") then
                SerialNoInfo.TestField(Blocked, false);

        if WhseActivityLine."Lot No." <> '' then
            if LotNoInfo.Get(WhseActivityLine."Item No.", WhseActivityLine."Variant Code", WhseActivityLine."Lot No.") then
                LotNoInfo.TestField(Blocked, false);

        OnAfterCheckItemTrackingInfoBlocked(WhseActivityLine);
    end;

    local procedure UpdateWindow(ControlNo: Integer; Value: Code[20])
    begin
        if not HideDialog then
            case ControlNo of
                1:
                    begin
                        Window.Open(Text000 + Text001 + Text002);
                        Window.Update(1, Value);
                    end;
                2:
                    Window.Update(2, LineCount);
                3:
                    Window.Update(3, LineCount);
                4:
                    Window.Update(4, Round(LineCount / NoOfRecords * 10000, 1));
            end;
    end;

    local procedure CheckLines()
    var
        NoSeries: Codeunit "No. Series";
    begin
        OnBeforeCheckLines(GlobalWhseActivHeader, GlobalWhseActivLine, TempBinContentBuffer);

        TempBinContentBuffer.DeleteAll();
        LineCount := 0;
        if GlobalWhseActivLine.Find('-') then
            repeat
                LineCount := LineCount + 1;
                UpdateWindow(2, '');
                GlobalWhseActivLine.CheckBinInSourceDoc();
                GlobalWhseActivLine.TestField("Item No.");
                if (GlobalWhseActivLine."Activity Type" = GlobalWhseActivLine."Activity Type"::Pick) and
                   (GlobalWhseActivLine."Destination Type" = GlobalWhseActivLine."Destination Type"::Customer)
                then begin
                    GlobalWhseActivLine.TestField("Destination No.");
                    CheckBlockedCustOnDocs();
                end;
                if Location."Bin Mandatory" then
                    CheckBinRelatedFields(GlobalWhseActivLine);

                OnAfterCheckWhseActivLine(GlobalWhseActivLine);

                if ((GlobalWhseActivLine."Activity Type" = GlobalWhseActivLine."Activity Type"::Pick) or
                    (GlobalWhseActivLine."Activity Type" = GlobalWhseActivLine."Activity Type"::"Invt. Pick") or
                    (GlobalWhseActivLine."Activity Type" = GlobalWhseActivLine."Activity Type"::"Invt. Movement")) and
                   (GlobalWhseActivLine."Action Type" = GlobalWhseActivLine."Action Type"::Take)
                then
                    CheckItemTrackingInfoBlocked(GlobalWhseActivLine);
            until GlobalWhseActivLine.Next() = 0;
        NoOfRecords := LineCount;

        if Location."Bin Mandatory" then begin
            CheckBinContent();
            CheckBin();
        end;

        if GlobalWhseActivHeader."Registering No." = '' then begin
            GlobalWhseActivHeader.TestField(GlobalWhseActivHeader."Registering No. Series");
            GlobalWhseActivHeader."Registering No." := NoSeries.GetNextNo(GlobalWhseActivHeader."Registering No. Series", GlobalWhseActivHeader."Assignment Date");
            GlobalWhseActivHeader.Modify();
            OnCheckLinesOnBeforeCommit(RegisteredWhseActivHeader, RegisteredWhseActivLine, SuppressCommit);
            if not SuppressCommit then
                Commit();
        end;

        OnAfterCheckLines(GlobalWhseActivHeader, GlobalWhseActivLine);
    end;

    local procedure CheckBlockedCustOnDocs()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBlockedCustOnDocs(GlobalWhseActivLine, IsHandled);
        if IsHandled then
            exit;

        Cust.Get(GlobalWhseActivLine."Destination No.");
        Cust.CheckBlockedCustOnDocs(Cust, GlobalWhseActivHeader."Source Document", false, false);
    end;

    local procedure CheckBinRelatedFields(WhseActivLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBinRelatedFields(WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        WhseActivLine.TestField("Unit of Measure Code");
        WhseActivLine.TestField("Bin Code");
        WhseActivLine.CheckWhseDocLine();

        UpdateTempBinContentBuffer(WhseActivLine);
    end;

    local procedure UpdateSourceDocForInvtMovement(WhseActivityLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSourceDocForInvtMovement(WhseActivityLine, IsHandled);
        if IsHandled then
            exit;

        if (WhseActivityLine."Action Type" = WhseActivityLine."Action Type"::Take) or
           (WhseActivityLine."Source Document" = WhseActivityLine."Source Document"::" ")
        then
            exit;

        OnAfterUpdateSourceDocumentForInvtMovement(WhseActivityLine);
    end;

    local procedure AutoReserveForSalesLine(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var TempReservEntryBefore: Record "Reservation Entry" temporary; var TempReservEntryAfter: Record "Reservation Entry" temporary)
    var
        SalesLine: Record "Sales Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        IsHandled: Boolean;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
    begin
        IsHandled := false;
        OnBeforeAutoReserveForSalesLine(TempWhseActivLineToReserve, IsHandled);
        if IsHandled then
            exit;

        if TempWhseActivLineToReserve.FindSet() then
            repeat
                ItemTrackingMgt.GetWhseItemTrkgSetup(TempWhseActivLineToReserve."Item No.", WhseItemTrackingSetup);
                if TempWhseActivLineToReserve.HasRequiredTracking(WhseItemTrackingSetup) then begin
                    SalesLine.Get(TempWhseActivLineToReserve."Source Subtype", TempWhseActivLineToReserve."Source No.", TempWhseActivLineToReserve."Source Line No.");

                    TempReservEntryBefore.SetSourceFilter(TempWhseActivLineToReserve."Source Type", TempWhseActivLineToReserve."Source Subtype", TempWhseActivLineToReserve."Source No.", TempWhseActivLineToReserve."Source Line No.", true);
                    TempReservEntryBefore.SetTrackingFilterFromWhseActivityLine(TempWhseActivLineToReserve);
                    TempReservEntryBefore.CalcSums(Quantity, "Quantity (Base)");

                    TempReservEntryAfter.CopyFilters(TempReservEntryBefore);
                    TempReservEntryAfter.CalcSums(Quantity, "Quantity (Base)");

                    QtyToReserve :=
                      TempWhseActivLineToReserve."Qty. to Handle" + (TempReservEntryAfter.Quantity - TempReservEntryBefore.Quantity);
                    QtyToReserveBase :=
                      TempWhseActivLineToReserve."Qty. to Handle (Base)" + (TempReservEntryAfter."Quantity (Base)" - TempReservEntryBefore."Quantity (Base)");

                    if not IsSalesLineCompletelyReserved(SalesLine) and (QtyToReserve > 0) then begin
                        ReservMgt.SetReservSource(SalesLine);
                        ReservMgt.SetTrackingFromWhseActivityLine(TempWhseActivLineToReserve);
                        OnAutoReserveForSalesLineOnBeforeRunAutoReserve(TempWhseActivLineToReserve);
                        ReservMgt.AutoReserve(FullAutoReservation, '', SalesLine."Shipment Date", QtyToReserve, QtyToReserveBase);
                    end;
                end;
            until TempWhseActivLineToReserve.Next() = 0;
    end;

    local procedure CheckAndRemoveOrderToOrderBinding(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary)
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ReservMgt: Codeunit "Reservation Management";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        IsConfirmed: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAndRemoveOrderToOrderBinding(TempWhseActivLineToReserve, IsHandled);
        if IsHandled then
            exit;

        if TempWhseActivLineToReserve.FindSet() then
            repeat
                SalesLine.Get(
                  SalesLine."Document Type"::Order, TempWhseActivLineToReserve."Source No.", TempWhseActivLineToReserve."Source Line No.");
                ReservationEntry.SetSourceFilter(
                  Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", true);
                ReservationEntry.SetFilter("Item Tracking", '<>%1', ReservationEntry."Item Tracking"::None);
                ReservationEntry.SetRange(Binding, ReservationEntry.Binding::"Order-to-Order");

                if ReservationEntry.FindSet() then
                    if not ReservMgt.ReservEntryPositiveTypeIsItemLedgerEntry(ReservationEntry."Entry No.") then begin
                        if not IsConfirmed and GuiAllowed then
                            if not Confirm(OrderToOrderBindingOnSalesLineQst) then
                                Error(RegisterInterruptedErr);
                        IsConfirmed := true;
                        repeat
                            ReservationEngineMgt.CancelReservation(ReservationEntry);
                            ReservMgt.SetReservSource(SalesLine);
                            ReservMgt.SetItemTrackingHandling(1);
                            ReservMgt.ClearSurplus();
                        until ReservationEntry.Next() = 0;
                    end;
            until TempWhseActivLineToReserve.Next() = 0;
    end;

    local procedure SyncItemTrackingAndReserveSourceDocument(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary)
    var
        TempReservEntryBeforeSync: Record "Reservation Entry" temporary;
        TempReservEntryAfterSync: Record "Reservation Entry" temporary;
    begin
        if not TempWhseActivLineToReserve.FindFirst() then begin
            SyncItemTracking();
            exit;
        end;

        case TempWhseActivLineToReserve."Source Document" of
            "Warehouse Activity Source Document"::"Sales Order":
                begin
                    CheckAndRemoveOrderToOrderBinding(TempWhseActivLineToReserve);
                    CollectReservEntries(TempReservEntryBeforeSync, TempWhseActivLineToReserve);
                    SyncItemTracking();
                    CollectReservEntries(TempReservEntryAfterSync, TempWhseActivLineToReserve);
                    AutoReserveForSalesLine(TempWhseActivLineToReserve, TempReservEntryBeforeSync, TempReservEntryAfterSync);
                end;
        end;

        OnAfterSyncItemTrackingAndReserveSourceDocument(TempWhseActivLineToReserve);
    end;

    procedure SyncItemTracking()
    begin
        ItemTrackingMgt.SetPick(GlobalWhseActivLine."Activity Type" = GlobalWhseActivLine."Activity Type"::Pick);
        ItemTrackingMgt.SynchronizeWhseItemTracking(TempTrackingSpecification, RegisteredWhseActivLine."No.", false);
    end;

    procedure CollectReservEntries(var TempReservEntry: Record "Reservation Entry" temporary; var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if TempWhseActivLineToReserve.FindSet() then
            repeat
                ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
                ReservEntry.SetSourceFilter(TempWhseActivLineToReserve."Source Type", TempWhseActivLineToReserve."Source Subtype", TempWhseActivLineToReserve."Source No.", TempWhseActivLineToReserve."Source Line No.", true);
                if ReservEntry.FindSet() then
                    repeat
                        TempReservEntry := ReservEntry;
                        if TempReservEntry.Insert() then;
                    until ReservEntry.Next() = 0;
            until TempWhseActivLineToReserve.Next() = 0;
    end;

    local procedure CopyWhseActivityLineToReservBuf(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; WhseActivLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyWhseActivityLineToReservBuf(TempWhseActivLineToReserve, WhseActivLine, IsHandled);
        if IsHandled then
            exit;

        if IsPickPlaceForSalesOrderTrackedItem(WhseActivLine) or
           IsInvtMovementForAssemblyOrderTrackedItem(WhseActivLine)
        then begin
            TempWhseActivLineToReserve.TransferFields(WhseActivLine);
            TempWhseActivLineToReserve.Insert();
        end;
    end;

    local procedure GroupWhseActivLinesByWhseDocAndSource(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        TempWarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type");
        TempWarehouseActivityLine.SetRange("Whse. Document No.", WarehouseActivityLine."Whse. Document No.");
        TempWarehouseActivityLine.SetRange("Whse. Document Line No.", WarehouseActivityLine."Whse. Document Line No.");
        TempWarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document");
        TempWarehouseActivityLine.SetSourceFilter(
          WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
          WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.", false);
        TempWarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type");
        TempWarehouseActivityLine.SetRange("Original Breakbulk", WarehouseActivityLine."Original Breakbulk");
        TempWarehouseActivityLine.SetRange("Breakbulk No.", WarehouseActivityLine."Breakbulk No.");
        TempWarehouseActivityLine.SetRange("Unit of Measure Code", WarehouseActivityLine."Unit of Measure Code");
        if TempWarehouseActivityLine.FindFirst() then begin
            TempWarehouseActivityLine."Qty. to Handle" += WarehouseActivityLine."Qty. to Handle";
            TempWarehouseActivityLine."Qty. to Handle (Base)" += WarehouseActivityLine."Qty. to Handle (Base)";
            OnGroupWhseActivLinesByWhseDocAndSourceOnBeforeTempWarehouseActivityLineModify(TempWarehouseActivityLine, WarehouseActivityLine);
            TempWarehouseActivityLine.Modify();
        end else begin
            TempWarehouseActivityLine := WarehouseActivityLine;
            TempWarehouseActivityLine.Insert();
        end;
    end;

    procedure ReleaseNonSpecificReservations(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyToRelease: Decimal): Boolean
    var
        WhseActivityItemTrackingSetup: Record "Item Tracking Setup";
        LateBindingMgt: Codeunit "Late Binding Management";
        xReservedQty: Decimal;
    begin
        if QtyToRelease <= 0 then
            exit;

        CalcQtyReservedOnInventory(WhseActivLine, WhseItemTrackingSetup);

        if WhseItemTrackingSetup.TrackingRequired() then
            if Item."Reserved Qty. on Inventory" > 0 then begin
                xReservedQty := Item."Reserved Qty. on Inventory";
                WhseActivityItemTrackingSetup.CopyTrackingFromWhseActivityLine(WhseActivLine);
                RemoveNonSpecificreservations(WhseActivLine, WhseItemTrackingSetup, QtyToRelease);
                LateBindingMgt.ReleaseForReservation(
                  WhseActivLine."Item No.", WhseActivLine."Variant Code", WhseActivLine."Location Code",
                  WhseActivityItemTrackingSetup, QtyToRelease);
                Item.CalcFields("Reserved Qty. on Inventory");
            end;

        exit(xReservedQty > Item."Reserved Qty. on Inventory");
    end;

    local procedure AutofillQtyToHandle(var WhseActivLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutofillQtyToHandle(WhseActivLine, IsHandled);
        if not IsHandled then
            if not HideDialog then
                WhseActivLine.AutofillQtyToHandle(WhseActivLine);

        OnAfterAutofillQtyToHandle(WhseActivLine);
    end;

    local procedure AvailabilityError(WhseActivLine: Record "Warehouse Activity Line")
    begin
        if WhseActivLine."Serial No." <> '' then
            Error(InventoryNotAvailableErr, WhseActivLine.FieldCaption("Serial No."), WhseActivLine."Serial No.");
        if WhseActivLine."Lot No." <> '' then
            Error(InventoryNotAvailableErr, WhseActivLine.FieldCaption("Lot No."), WhseActivLine."Lot No.");

        OnAfterAvailabilityError(WhseActivLine);
    end;

    local procedure IsPickPlaceForSalesOrderTrackedItem(WhseActivityLine: Record "Warehouse Activity Line"): Boolean
    begin
        exit(
          (WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::Pick) and
          (WhseActivityLine."Action Type" in [WhseActivityLine."Action Type"::Place, WhseActivityLine."Action Type"::" "]) and
          (WhseActivityLine."Source Document" = WhseActivityLine."Source Document"::"Sales Order") and
          (WhseActivityLine."Breakbulk No." = 0) and
          WhseActivityLine.TrackingExists());
    end;

    local procedure IsInvtMovementForAssemblyOrderTrackedItem(WhseActivityLine: Record "Warehouse Activity Line"): Boolean
    begin
        exit(
          (WhseActivityLine."Activity Type" = WhseActivityLine."Activity Type"::"Invt. Movement") and
          (WhseActivityLine."Action Type" in [WhseActivityLine."Action Type"::Place, WhseActivityLine."Action Type"::" "]) and
          (WhseActivityLine."Source Document" = WhseActivityLine."Source Document"::"Assembly Consumption") and
          (WhseActivityLine."Breakbulk No." = 0) and
          WhseActivityLine.TrackingExists());
    end;

    local procedure IsSalesLineCompletelyReserved(SalesLine: Record "Sales Line"): Boolean
    begin
        SalesLine.CalcFields("Reserved Quantity");
        exit(SalesLine.Quantity = SalesLine."Reserved Quantity");
    end;

    /// <summary>
    /// Sets the option to suppress committing transactions to the database.
    /// </summary>
    /// <param name="NewSuppressCommit">Boolean flag indicating whether to suppress commit.</param>
    /// <remarks>
    /// When 'SuppressCommit' is set to true, it indicates that transaction committed to the
    /// database should be suppressed. This can be useful in scenarios where batch processing or
    /// testing requires transactions to be rolled back rather than committed permanently.
    /// </remarks>
    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure MaintainZeroLines(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type");
        WarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityLine.SetRange("Qty. to Handle", 0);
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.ResetQtyToHandleOnReservation();
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure RemoveNonSpecificreservations(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyToRelease: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        QtyToPick: Decimal;
    begin
        if not WhseItemTrackingSetup.TrackingRequired() then
            exit;
        if not (WhseActivLine."Source Type" = Database::"Sales Line") then
            exit;

        QtyToPick := QtyToRelease;
        SalesLine.Get(WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.");
        ReservationEntry.SetSourceFilter(WhseActivLine."Source Type", WhseActivLine."Source Subtype", WhseActivLine."Source No.", WhseActivLine."Source Line No.", true);
        ReservationEntry.SetRange(Positive, false);
        if ReservationEntry.FindSet() then
            repeat
                DeleteNonSpecificReservationEntries(ReservationEntry, SalesLine, QtyToPick);
            until (ReservationEntry.Next() = 0) or (QtyToPick >= 0);
    end;

    local procedure DeleteNonSpecificReservationEntries(ReservationEntry: Record "Reservation Entry"; SalesLine: Record "Sales Line"; var QtyToPick: Decimal)
    var
        ReservationManagement: Codeunit "Reservation Management";
    begin
        if ReservationEntry.TrackingExists() then
            exit;

        ReservationManagement.SetReservSource(SalesLine);
        ReservationManagement.DeleteReservEntries(false, ReservationEntry."Quantity (Base)");
        QtyToPick += ReservationEntry."Quantity (Base)"
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeCode(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBlockedCustOnDocs(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivLineDelete(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SkipDelete: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterAssemblyLineModify(var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
        OnAfterAssemblyLineModify(AssemblyLine);
    end;

    [Obsolete('Moved to codeunit AsmWhseActivityRegister', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterAssemblyLineModify(var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterAvailabilityError(WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseShptLineModify(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRegActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRegActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RegisteredWhseActivLine: Record "Registered Whse. Activity Line"; var RegisteredInvtMovementLine: Record "Registered Invt. Movement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutofillQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutofillQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLines(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempBinContentBuffer: Record "Bin Content Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckItemTrackingInfoBlocked(WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegWhseItemTrkgLine(var WhseActivLine2: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsRegWhseItemTrkgLine(var WhseActivLine2: Record "Warehouse Activity Line"; var WhseItemTrkgLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostedWhseRcptLineModify(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnAfterProdCompLineModify(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnAfterProdCompLineModify(ProdOrderComponent);
    end;

    [Obsolete('Moved to codeunit MfgWhseActivityRegister', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterProdCompLineModify(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisterWhseActivity(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisterWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisteredInvtMovementHdrInsert(var RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr."; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisteredInvtMovementLineInsert(var RegisteredInvtMovementLine: Record "Registered Invt. Movement Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisteredWhseActivHeaderInsert(var RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr."; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRegisteredWhseActivLineInsert(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseInternalPickLineModify(var WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseInternalPutAwayLineModify(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoReserveForSalesLineOnBeforeRunAutoReserve(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeAssemblyLineModify(var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        OnBeforeAssemblyLineModify(AssemblyLine, WarehouseActivityLine);
    end;

    [Obsolete('Moved to codeunit AsmWhseActivityRegister', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssemblyLineModify(var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveForSalesLine(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeAutoReserveForAssemblyLine(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean)
    begin
        OnBeforeAutoReserveForAssemblyLine(TempWhseActivLineToReserve, IsHandled);
    end;

    [Obsolete('Moved to codeunit AsmWhseActivityRegister', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserveForAssemblyLine(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinRelatedFields(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedWhseRcptLineModify(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeProdCompLineModify(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        OnBeforeProdCompLineModify(ProdOrderComponent, WarehouseActivityLine);
    end;

    [Obsolete('Moved to codeunit MfgWhseActivityRegister', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdCompLineModify(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegWhseItemTrkgLine(var WhseActivLine2: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisteredInvtMovementHdrInsert(var RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr."; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitTempTrackingSpecification(WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyToRegisterBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisteredInvtMovementLineInsert(var RegisteredInvtMovementLine: Record "Registered Invt. Movement Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisteredWhseActivHeaderInsert(var RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr."; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisteredWhseActivLineInsert(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyWhseActivityLineToReservBuf(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyAvailToInsertBase(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var QtyAvailToInsertBase: Decimal; var AllowWhseOverpick: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdWhseActivHeader(var WhseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; QtyToHandle: Decimal; QtyToHandleBase: Decimal; QtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivHeaderDelete(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var SkipDelete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRegActLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitRegInvtMovementLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RegisteredInvtMovementLine: Record "Registered Invt. Movement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseDocHeader(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckLines(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyBasePicked(WhseActivLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var QtyBasePicked: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAndRemoveOrderToOrderBinding(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIncreaseBin(var TempBinContentBuffer: Record "Bin Content Buffer" temporary; var Bin: Record Bin; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseItemTrkgLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCommit(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRegActivHeader(var WhseActivityHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean; var RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr."; var RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsQtyAvailToPickNonSpecificReservation(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyAvailToPick: Decimal; var QtyToRegister: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterWhseJnlLine(WarehouseActivityLine: Record "Warehouse Activity Line"; RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRegisterWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSourceLineQtyBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseActivLineModify(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseJnlRegisterLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempTrackingSpecificationInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSourceDocForInvtMovement(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseDocHeader(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseSourceDocLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseActivLineQtyOutstanding(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyDiff: Decimal; var QtyBaseDiff: Decimal; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWarehouseActivityLineQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyDiff: Decimal; var QtyBaseDiff: Decimal; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseInternalPickLineModify(var WhseInternalPickLine: Record "Whse. Internal Pick Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseInternalPutAwayLineModify(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyPickedNotShippedOnAfterReservEntrySetFilters(var ReservEntry: Record "Reservation Entry"; WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalAvailQtyToPickOnAfterItemLedgEntryCalcSums(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalAvailQtyToPickOnAfterCalcQtyInWhseBase(var WarehouseEntry: Record "Warehouse Entry"; var QtyInWhseBase: Decimal; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCheckLines(var WhseActivHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCalcShouldDeleteOldLine(OldWarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; var ShouldDeleteOldLine: Boolean; var LineCount: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRegWhseItemTrkgLineOnAfterCopyFields(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetPointerOnAfterWhseDocTypeSetSource(WhseActivLine: Record "Warehouse Activity Line"; WhseDocType2: Option; var WhseItemTrkgLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTempBinContentBufferOnBeforeInsert(var TempBinContentBuffer: Record "Bin Content Buffer" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWhseShptLineOnAfterAssignQtyPicked(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; QtyPerUOM: Decimal; QtyToHandleBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShptLineModify(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; WhseActivityLineGrouped: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitTempTrackingSpecificationOnBeforeTempTrackingSpecificationModify(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; var TrackingSpecificationtemporary: Record "Tracking Specification" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGroupWhseActivLinesByWhseDocAndSourceOnBeforeTempWarehouseActivityLineModify(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterWhseItemTrkgLineOnBeforeCreateSpecification(var WhseActivLine2: Record "Warehouse Activity Line"; var DueDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterWhseItemTrkgLineOnAfterSetDueDate(WarehouseActivityLine: Record "Warehouse Activity Line"; var DueDate: Date; var QtyToRegisterBase: Decimal; WhseDocType: Enum "Warehouse Activity Document Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterWhseItemTrkgLineOnSetDueDate(WarehouseActivityLine: Record "Warehouse Activity Line"; var DueDate: Date; var QtyToRegisterBase: Decimal; WhseDocType: Enum "Warehouse Activity Document Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterWhseItemTrkgLineOnAfterSetDueDateForInvtMovement(WarehouseActivityLine: Record "Warehouse Activity Line"; var DueDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRegisterWhseItemTrkgLineOnAfterCalcWhseItemTrkgSetupExists(WarehouseActivityLine2: Record "Warehouse Activity Line"; var ItemTrackingManagement: Codeunit "Item Tracking Management"; var WhseItemTrkgSetupExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeCommit(RegisteredWhseActivHeader: Record "Registered Whse. Activity Hdr."; RegisteredWhseActivLine: Record "Registered Whse. Activity Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseActivLineIsEmpty(var WhseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinContentQtyToHandle(var TempBinContentBuffer: Record "Bin Content Buffer" temporary; var BinContent: Record "Bin Content"; Item: Record Item; var IsHandled: Boolean; BreakBulkQtyBaseToPlace: Decimal; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseSourceDocLine(var WhseActivityLine: Record "Warehouse Activity Line"; WhseDocType2: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinContentOnAfterTempBinContentBufferLoop(var TempBinContentBuffer: Record "Bin Content Buffer"; var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinContentOnAfterGetWhseItemTrkgSetup(BinContent: Record "Bin Content"; var WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckLinesOnBeforeCommit(RegisteredWhseActivHeader: Record "Registered Whse. Activity Hdr."; RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseItemTrkgLineOnAfterClearFilters(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; WhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseItemTrkgLineOnAfterTempWhseActivLineFind(var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseItemTrkgLineOnBeforeTestTracking(WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseItemTrkgLineOnBeforeCalcQtyToRegisterBase(var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyAvailToInsertBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseItemTrkgLineOnAfterTempWhseActivLineSetFilters(var TempWhseActivLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckWhseItemTrkgLineOnAfterGetWhseItemTrkgSetup(TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeTempWhseActivityLineGroupedLoop(var WhseActivHeader: Record "Warehouse Activity Header"; var WhseActivLine: Record "Warehouse Activity Line"; var RegisteredWhseActivHeader: Record "Registered Whse. Activity Hdr."; var TempWarehouseActivityLineGrouped: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSourceDocumentForAvailableQty(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobPlanningLineModify(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnBeforeModifyGlobalWhseActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckSourceDocumentForAvailableQty(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWhseDocHeaderByWhseDocumentType(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocumentForAvailabilityBySourceDocument(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RemainingQtyBase: Decimal; var RemainingQtyUoM: Code[10]; var AllowWhseOverpick: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWhseSourceDocLineByDocumentType(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseDocType: Enum "Warehouse Activity Document Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceLineBaseQtyByWhseActivitySourceType(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceLineBaseQtyByWhseActivityDocumentType(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseDocType: Enum "Warehouse Activity Document Type"; var QtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSourceDocumentForInvtMovement(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSyncItemTrackingAndReserveSourceDocument(var TempWhseActivLineToReserve: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinContent(var TempBinContentBuffer: Record "Bin Content Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateTempBinContentBufferOnBeforeModifyTempBinContentBuffer(var TempBinContentBuffer: Record "Bin Content Buffer" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;
}

