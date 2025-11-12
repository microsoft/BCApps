// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Journal;

using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000843 "Undo Prod. Posting Mgmt."
{
    var
        SourceCodeSetup: Record "Source Code Setup";
        ReverseEntriesMsg: Label 'To reverse these entries, correcting entries will be posted.';
        ReverseEntriesQst: Label 'Do you want to reverse the entries?';
        PostedSuccessfullyMsg: Label 'The journal lines were successfully posted.';
        CannotHandleEntryTypeErr: Label 'Cannot handle entry type %1 for correction posting of production.', Comment = '%1 - Entry Type';
        InvalidEntryTypeErr: Label 'Entry Type must be either Consumption or Output.';
        SubContractingErr: Label 'Entry cannot be reversed as it is linked to the subcontracting work center.';
        QuantityMustBeGreaterThanZeroErr: Label 'Quantity must be greater than 0 on %1 No. %2 to reverse the entry.', Comment = '%1 = Table Caption , %2 = Entry No.';
        QuantityMustBeLessThanZeroErr: Label 'Quantity must be less than 0 on %1 No. %2 to reverse the entry. ', Comment = '%1 = Table Caption , %2 = Entry No.';
        MissingReleasedProductionErr: Label 'Production Order %1 is already Finished, you cannot reverse this entry.', Comment = '%1 = Production Order No.';
        CannotReverseLastOperationErr: Label '%1 %2 is the last operation of Production Order %3. Reversal of this operation can only be performed from the %4.', Comment = '%1 - Field Caption, %2 - Entry No., %3 - Production Order No., %4 - Item Ledger Entry table caption';

    procedure ReverseProdItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        Processed: Boolean;
    begin
        if not CanPostReversal() then
            Error('');

        ItemLedgerEntry.SetBaseLoadFields();
        if ItemLedgerEntry.FindSet() then
            repeat
                ProcessItemLedgEntry(ItemLedgerEntry);
                OnReverseProdItemLedgerEntryOnAfterProcessItemLedgerEntry(ItemLedgerEntry);
                Processed := true;
            until ItemLedgerEntry.Next() = 0;

        if Processed then
            Message(PostedSuccessfullyMsg);
    end;

    procedure ReverseCapacityLedgerEntry(var CapacityLedgEntry: Record "Capacity Ledger Entry")
    var
        Processed: Boolean;
    begin
        if not CanPostReversal() then
            Error('');

        CapacityLedgEntry.SetBaseLoadFields();
        if CapacityLedgEntry.FindSet() then
            repeat
                ReverseOutputCapacityLedgerEntry(CapacityLedgEntry);
                OnReverseCapacityLedgerEntryOnAfterReverseOutputCapacityLedgerEntry(CapacityLedgEntry);
                Processed := true;
            until CapacityLedgEntry.Next() = 0;

        if Processed then
            Message(PostedSuccessfullyMsg);
    end;

    local procedure ProcessItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        SourceCodeSetup.Get();

        case ItemLedgerEntry."Entry Type" of
            Enum::"Item Ledger Entry Type"::Output:
                ReverseOutputItemLedgerEntry(ItemLedgerEntry);
            Enum::"Item Ledger Entry Type"::Consumption:
                ReverseConsumptionItemLedgerEntry(ItemLedgerEntry);
            else
                Error(CannotHandleEntryTypeErr, ItemLedgerEntry."Entry Type");
        end;
    end;

    local procedure ReverseOutputItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemJnlLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        OperationNo: Code[20];
        SetupTime: Decimal;
        RunTime: Decimal;
        StopTime: Decimal;
        ScrapValue: Decimal;
        IsHandled: Boolean;
        CapacityLedgerEntryNo: Integer;
    begin
        ProductionOrder.SetLoadFields(Status, "No.");
        if not ProductionOrder.Get(ProductionOrder.Status::Released, ItemLedgerEntry."Order No.") then
            Error(MissingReleasedProductionErr, ItemLedgerEntry."Order No.");

        ValidateProdOrder(ItemLedgerEntry);

        ItemJnlLine.Init();
        ItemJnlLine."Source Code" := SourceCodeSetup."Output Journal";
        ItemJnlLine.Validate("Posting Date", ItemLedgerEntry."Posting Date");
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ItemLedgerEntry."Order No.");
        ItemJnlLine.Validate("Order Line No.", ItemLedgerEntry."Order Line No.");
        ItemJnlLine.Validate("Item No.", ItemLedgerEntry."Item No.");
        ItemJnlLine.Validate("Variant Code", ItemLedgerEntry."Variant Code");
        ItemJnlLine.Validate("Document No.", ItemLedgerEntry."Document No.");
        ItemJnlLine.Validate("Location Code", ItemLedgerEntry."Location Code");
        ItemJnlLine.Validate("Unit of Measure Code", ItemLedgerEntry."Unit of Measure Code");
        ItemJnlLine."Dimension Set ID" := ItemLedgerEntry."Dimension Set ID";
        ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";
        GetLastOperationInformation(ItemLedgerEntry, CapacityLedgerEntryNo, OperationNo, SetupTime, RunTime, StopTime, ScrapValue);
        if OperationNo <> '' then begin
            ItemJnlLine.Validate("Rev. Capacity Ledger Entry No.", CapacityLedgerEntryNo);
            ItemJnlLine.Validate("Operation No.", OperationNo);
            ItemJnlLine.Validate("Setup Time", -SetupTime);
            ItemJnlLine.Validate("Run Time", -RunTime);
            ItemJnlLine.Validate("Stop Time", -StopTime);
            ItemJnlLine.Validate("Scrap Quantity", -ScrapValue);
        end;

        IsHandled := false;
        OnReverseOutputItemLedgerEntryOnBeforeValidateOutputQuantity(ItemJnlLine, ItemLedgerEntry, IsHandled);
        if not IsHandled then
            ItemJnlLine.Validate("Output Quantity", -Abs(ItemLedgerEntry.Quantity));

        ItemJnlLine.Validate(Description, ItemLedgerEntry.Description);

        if ItemLedgerEntry.TrackingExists() then
            CreateOutputReservationEntry(ItemJnlLine, ItemLedgerEntry)
        else
            ItemJnlLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");

        OnReverseOutputItemLedgerEntryOnBeforeItemJnlPostLine(ItemJnlLine, ItemLedgerEntry, ProductionOrder);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure ReverseOutputCapacityLedgerEntry(CapacityLedgEntry: Record "Capacity Ledger Entry")
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        IsHandled: Boolean;
    begin
        if CapacityLedgEntry."Order Type" <> CapacityLedgEntry."Order Type"::Production then
            exit;

        ValidateProdOrder(CapacityLedgEntry);

        ItemJnlLine.Init();
        ItemJnlLine."Source Code" := SourceCodeSetup."Output Journal";
        ItemJnlLine.Validate("Posting Date", CapacityLedgEntry."Posting Date");
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", CapacityLedgEntry."Order No.");
        ItemJnlLine.Validate("Order Line No.", CapacityLedgEntry."Order Line No.");
        ItemJnlLine.Validate("Routing No.", CapacityLedgEntry."Routing No.");
        ItemJnlLine.Validate("Routing Reference No.", CapacityLedgEntry."Routing Reference No.");
        ItemJnlLine.Validate("Item No.", CapacityLedgEntry."Item No.");
        ItemJnlLine.Validate("Variant Code", CapacityLedgEntry."Variant Code");
        ItemJnlLine.Validate("Document No.", CapacityLedgEntry."Document No.");
        ItemJnlLine.Validate("Operation No.", CapacityLedgEntry."Operation No.");
        ItemJnlLine.Validate(Type, CapacityLedgEntry.Type);
        ItemJnlLine.Validate("No.", CapacityLedgEntry."No.");
        ItemJnlLine.Validate("Unit of Measure Code", CapacityLedgEntry."Unit of Measure Code");
        ItemJnlLine."Dimension Set ID" := CapacityLedgEntry."Dimension Set ID";
        ItemJnlLine."Shortcut Dimension 1 Code" := CapacityLedgEntry."Global Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := CapacityLedgEntry."Global Dimension 2 Code";
        ItemJnlLine.Validate(Description, CapacityLedgEntry.Description);

        ItemJnlLine.Validate("Rev. Capacity Ledger Entry No.", CapacityLedgEntry."Entry No.");
        ItemJnlLine.Validate("Setup Time", -Abs(CapacityLedgEntry."Setup Time"));
        ItemJnlLine.Validate("Run Time", -Abs(CapacityLedgEntry."Run Time"));
        ItemJnlLine.Validate("Stop Time", -Abs(CapacityLedgEntry."Stop Time"));
        if not IsLastOperation(CapacityLedgEntry) then
            ItemJnlLine.Validate("Output Quantity", -Abs(CapacityLedgEntry."Output Quantity"));

        IsHandled := false;
        OnReverseOutputCapacityLedgerEntryOnBeforeValidateQuantity(ItemJnlLine, CapacityLedgEntry, IsHandled);
        if not IsHandled then begin
            ItemJnlLine.Validate(Quantity, -Abs(CapacityLedgEntry.Quantity));
            ItemJnlLine.Validate("Scrap Code", CapacityLedgEntry."Scrap Code");
            ItemJnlLine.Validate("Scrap Quantity", -Abs(CapacityLedgEntry."Scrap Quantity"));
        end;

        OnReverseOutputCapacityLedgerEntryOnBeforeItemJnlPostLine(ItemJnlLine, CapacityLedgEntry);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure IsLastOperation(CapacityLedgerEntry: Record "Capacity Ledger Entry"): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderLine.Get(ProdOrderLine.Status::Released, CapacityLedgerEntry."Order No.", CapacityLedgerEntry."Order Line No.");

        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange(Type, CapacityLedgerEntry.Type);
        ProdOrderRoutingLine.SetRange("Operation No.", CapacityLedgerEntry."Operation No.");
        ProdOrderRoutingLine.SetFilter("Next Operation No.", '%1', '');
        exit(not ProdOrderRoutingLine.IsEmpty());
    end;

    local procedure GetLastOperationInformation(ItemLedgEntry: Record "Item Ledger Entry"; var CapacityLedgerEntryNo: Integer; var OperationNo: Code[20]; var SetupTime: Decimal; var RunTime: Decimal; var StopTime: Decimal; var ScrapValue: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemRegister: Record "Item Register";
        CapacityLedgEntry: Record "Capacity Ledger Entry";
    begin
        ProdOrderLine.SetLoadFields(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.");
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemLedgEntry."Order No.", ItemLedgEntry."Order Line No.");

        FilterProdOrderRoutingLineFromProdOrderLine(ProdOrderRoutingLine, ProdOrderLine);
        if not ProdOrderRoutingLine.FindFirst() then
            exit;

        OperationNo := ProdOrderRoutingLine."Operation No.";
        if OperationNo = '' then
            exit;

        ItemRegister.SetFilter("From Entry No.", '<=%1', ItemLedgEntry."Entry No.");
        ItemRegister.SetFilter("To Entry No.", '>=%1', ItemLedgEntry."Entry No.");
        if not ItemRegister.FindFirst() then
            exit;

        FilterCapacityLedgEntryForLastOperation(CapacityLedgEntry, ItemLedgEntry, ItemRegister, ProdOrderLine, OperationNo);
        if not CapacityLedgEntry.IsEmpty() then
            exit;

        CapacityLedgEntry.SetRange("Output Quantity");
        if CapacityLedgEntry.FindFirst() then begin
            CapacityLedgerEntryNo := CapacityLedgEntry."Entry No.";
            SetupTime := CapacityLedgEntry."Setup Time";
            RunTime := CapacityLedgEntry."Run Time";
            StopTime := CapacityLedgEntry."Stop Time";
            ScrapValue := CapacityLedgEntry."Scrap Quantity";
        end;
    end;

    local procedure FilterProdOrderRoutingLineFromProdOrderLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderRoutingLine.SetLoadFields("Operation No.");
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetFilter("Next Operation No.", '%1', '');
    end;

    local procedure FilterCapacityLedgEntryForLastOperation(var CapacityLedgEntry: Record "Capacity Ledger Entry"; ItemLedgEntry: Record "Item Ledger Entry"; ItemRegister: Record "Item Register"; ProdOrderLine: Record "Prod. Order Line"; OperationNo: Code[20])
    begin
        CapacityLedgEntry.SetLoadFields("Item Register No.", "Entry No.", "Item No.", "Order Type", "Order No.", "Order Line No.", "Operation No.", "Routing No.", "Routing Reference No.", "Setup Time", "Run Time", "Stop Time", "Scrap Quantity", Quantity);
        CapacityLedgEntry.SetRange("Item Register No.", ItemRegister."No.");
        CapacityLedgEntry.SetRange("Entry No.", ItemRegister."From Capacity Entry No.", ItemRegister."To Capacity Entry No.");
        CapacityLedgEntry.SetRange("Item No.", ItemLedgEntry."Item No.");
        CapacityLedgEntry.SetRange("Order Type", CapacityLedgEntry."Order Type"::Production);
        CapacityLedgEntry.SetRange("Order No.", ItemLedgEntry."Order No.");
        CapacityLedgEntry.SetRange("Order Line No.", ItemLedgEntry."Order Line No.");
        CapacityLedgEntry.SetRange("Operation No.", OperationNo);
        CapacityLedgEntry.SetRange("Routing No.", ProdOrderLine."Routing No.");
        CapacityLedgEntry.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        CapacityLedgEntry.SetRange("Output Quantity", 0);
    end;

    local procedure ReverseConsumptionItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ItemJnlLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        IsHandled: Boolean;
    begin
        ProductionOrder.SetLoadFields(Status, "No.");
        if not ProductionOrder.Get(ProductionOrder.Status::Released, ItemLedgerEntry."Order No.") then
            Error(MissingReleasedProductionErr, ItemLedgerEntry."Order No.");

        ValidateProdOrder(ItemLedgerEntry);

        ItemJnlLine.Init();
        ItemJnlLine."Source Code" := SourceCodeSetup."Consumption Journal";
        ItemJnlLine.Validate("Posting Date", ItemLedgerEntry."Posting Date");
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ItemLedgerEntry."Order No.");
        ItemJnlLine.Validate("Order Line No.", ItemLedgerEntry."Order Line No.");
        ItemJnlLine.Validate("Prod. Order Comp. Line No.", ItemLedgerEntry."Prod. Order Comp. Line No.");
        ItemJnlLine.Validate("Item No.", ItemLedgerEntry."Item No.");
        ItemJnlLine.Validate("Variant Code", ItemLedgerEntry."Variant Code");
        ItemJnlLine.Validate("Document No.", ItemLedgerEntry."Document No.");
        ItemJnlLine.Validate(Description, ItemLedgerEntry.Description);
        ItemJnlLine.Validate("Location Code", ItemLedgerEntry."Location Code");
        ItemJnlLine.Validate("Unit of Measure Code", ItemLedgerEntry."Unit of Measure Code");
        ItemJnlLine."Dimension Set ID" := ItemLedgerEntry."Dimension Set ID";
        ItemJnlLine."Shortcut Dimension 1 Code" := ItemLedgerEntry."Global Dimension 1 Code";
        ItemJnlLine."Shortcut Dimension 2 Code" := ItemLedgerEntry."Global Dimension 2 Code";
        IsHandled := false;
        OnReverseConsumptionItemLedgerEntryOnBeforeValidateQuantity(ItemJnlLine, ItemLedgerEntry, IsHandled);
        if not IsHandled then
            ItemJnlLine.Validate(Quantity, -Abs(ItemLedgerEntry.Quantity));

        if ItemJnlLine."Unit of Measure Code" = ItemLedgerEntry."Unit of Measure Code" then begin
            ItemJnlLine."Quantity (Base)" := ItemLedgerEntry.Quantity;
            ItemJnlLine."Invoiced Qty. (Base)" := ItemLedgerEntry.Quantity;
        end;

        if ItemLedgerEntry.TrackingExists() then
            CreateConsumptionReservationEntry(ItemJnlLine, ItemLedgerEntry)
        else
            ItemJnlLine.Validate("Applies-from Entry", ItemLedgerEntry."Entry No.");
        OnReverseConsumptionItemLedgerEntryOnBeforeItemJnlPostLine(ItemJnlLine, ItemLedgerEntry, ProductionOrder);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
    end;

    local procedure CanPostReversal(): Boolean
    var
        QuestionTxt: Text;
    begin
        if not GuiAllowed() then
            exit(true);

        QuestionTxt := ReverseEntriesMsg + '\' + ReverseEntriesQst;
        exit(Confirm(QuestionTxt));
    end;

    local procedure ValidateProdOrder(ItemLedgEntry: Record "Item Ledger Entry")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not (ItemLedgEntry."Entry Type" in [ItemLedgEntry."Entry Type"::Output, ItemLedgEntry."Entry Type"::Consumption]) then
            Error(InvalidEntryTypeErr);

        ProdOrderLine.SetBaseLoadFields();
        ProdOrderLine.Get(ProdOrderLine.Status::Released, ItemLedgEntry."Order No.", ItemLedgEntry."Order Line No.");

        if ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Output then
            ItemLedgEntry.TestField("Remaining Quantity", ItemLedgEntry.Quantity);

        ItemLedgEntry.CalcFields("Reserved Quantity");
        ItemLedgEntry.TestField("Reserved Quantity", 0);
        ItemLedgEntry.TestField(Correction, false);

        case ItemLedgEntry."Entry Type" of
            Enum::"Item Ledger Entry Type"::Consumption:
                if ItemLedgEntry.Quantity > 0 then
                    Error(QuantityMustBeLessThanZeroErr, ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.");
            Enum::"Item Ledger Entry Type"::Output:
                if ItemLedgEntry.Quantity < 0 then
                    Error(QuantityMustBeGreaterThanZeroErr, ItemLedgEntry.TableCaption, ItemLedgEntry."Entry No.");
        end;

        if ItemLedgEntry."Entry Type" = ItemLedgEntry."Entry Type"::Output then
            ValidateSubcontracting(ProdOrderLine);

        OnAfterValidateProdOrder(ItemLedgEntry, ProdOrderLine);
    end;

    local procedure ValidateSubcontracting(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetLoadFields(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", Type, "No.");
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetRange(Type, ProdOrderRoutingLine.Type::"Work Center");
        ProdOrderRoutingLine.SetFilter("No.", '<>%1', '');
        if ProdOrderRoutingLine.FindSet() then
            repeat
                ValidateSubcontractingLink(ProdOrderRoutingLine);
            until ProdOrderRoutingLine.Next() = 0;
    end;

    local procedure ValidateSubcontractingLink(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetLoadFields("No.", "Subcontractor No.");
        WorkCenter.Get(ProdOrderRoutingLine."No.");
        if WorkCenter."Subcontractor No." <> '' then
            Error(SubContractingErr);
    end;

    local procedure ValidateProdOrder(CapacityLedgerEntry: Record "Capacity Ledger Entry")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        ReversalEntry: Record "Reversal Entry";
    begin
        CapacityLedgerEntry.TestField("Order Type", CapacityLedgerEntry."Order Type"::Production);
        if CapacityLedgerEntry.Quantity < 0 then
            Error(QuantityMustBeGreaterThanZeroErr, CapacityLedgerEntry.TableCaption, CapacityLedgerEntry."Entry No.");

        ProductionOrder.SetLoadFields(Status, "No.");
        ProductionOrder.Get(ProductionOrder.Status::Released, CapacityLedgerEntry."Order No.");

        if CapacityLedgerEntry.Reversed then
            ReversalEntry.AlreadyReversedEntry(CapacityLedgerEntry.TableCaption(), CapacityLedgerEntry."Entry No.");

        if CapacityLedgerEntry.Subcontracting then
            Error(SubContractingErr);

        if IsLastOperation(CapacityLedgerEntry) then
            Error(CannotReverseLastOperationErr, CapacityLedgerEntry.FieldCaption("Entry No."), CapacityLedgerEntry."Entry No.", CapacityLedgerEntry."Order No.", ItemLedgEntry.TableCaption());
    end;

    local procedure CreateOutputReservationEntry(ItemJnlLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Init();
        ReservationEntry."Item No." := ItemLedgerEntry."Item No.";
        ReservationEntry."Variant Code" := ItemLedgerEntry."Variant Code";
        ReservationEntry."Location Code" := ItemLedgerEntry."Location Code";
        ReservationEntry.Quantity := -Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Quantity (Base)" := -Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
        ReservationEntry."Creation Date" := ItemLedgerEntry."Posting Date";
        ReservationEntry."Source Type" := Database::"Item Journal Line";
        ReservationEntry."Source Subtype" := ItemJnlLine."Entry Type".AsInteger();
        ReservationEntry."Source ID" := ItemJnlLine."Journal Template Name";
        ReservationEntry."Source Batch Name" := ItemJnlLine."Journal Batch Name";
        ReservationEntry."Expected Receipt Date" := ItemLedgerEntry."Posting Date";
        ReservationEntry."Created By" := UserId();
        ReservationEntry."Qty. per Unit of Measure" := ItemLedgerEntry."Qty. per Unit of Measure";
        ReservationEntry."Qty. to Handle (Base)" := -Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Qty. to Invoice (Base)" := -Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Lot No." := ItemLedgerEntry."Lot No.";
        ReservationEntry."Serial No." := ItemLedgerEntry."Serial No.";
        ReservationEntry."Item Tracking" := ItemLedgerEntry."Item Tracking";
        ReservationEntry."Expiration Date" := ItemLedgerEntry."Expiration Date";
        ReservationEntry."Package No." := ItemLedgerEntry."Package No.";
        ReservationEntry."Appl.-to Item Entry" := ItemLedgerEntry."Entry No.";

        OnCreateOutputReservationEntryOnBeforeInsert(ReservationEntry, ItemLedgerEntry);
        ReservationEntry.Insert();
    end;

    local procedure CreateConsumptionReservationEntry(ItemJnlLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Init();
        ReservationEntry."Item No." := ItemLedgerEntry."Item No.";
        ReservationEntry."Variant Code" := ItemLedgerEntry."Variant Code";
        ReservationEntry."Location Code" := ItemLedgerEntry."Location Code";
        ReservationEntry.Quantity := Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Quantity (Base)" := Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Prospect;
        ReservationEntry."Creation Date" := ItemLedgerEntry."Posting Date";
        ReservationEntry."Source Type" := Database::"Item Journal Line";
        ReservationEntry."Source Subtype" := ItemJnlLine."Entry Type".AsInteger();
        ReservationEntry."Source ID" := ItemJnlLine."Journal Template Name";
        ReservationEntry."Source Batch Name" := ItemJnlLine."Journal Batch Name";
        ReservationEntry."Shipment Date" := ItemLedgerEntry."Posting Date";
        ReservationEntry."Created By" := UserId();
        ReservationEntry."Qty. per Unit of Measure" := Abs(ItemLedgerEntry."Qty. per Unit of Measure");
        ReservationEntry."Qty. to Handle (Base)" := Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Qty. to Invoice (Base)" := Abs(ItemLedgerEntry.Quantity);
        ReservationEntry."Lot No." := ItemLedgerEntry."Lot No.";
        ReservationEntry."Serial No." := ItemLedgerEntry."Serial No.";
        ReservationEntry."Item Tracking" := ItemLedgerEntry."Item Tracking";
        ReservationEntry."Expiration Date" := ItemLedgerEntry."Expiration Date";
        ReservationEntry."Package No." := ItemLedgerEntry."Package No.";
        ReservationEntry."Appl.-from Item Entry" := ItemLedgerEntry."Entry No.";
        OnCreateConsumptionReservationEntryOnBeforeInsert(ReservationEntry, ItemLedgerEntry);
        ReservationEntry.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseConsumptionItemLedgerEntryOnBeforeValidateQuantity(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateOutputReservationEntryOnBeforeInsert(var ReservationEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOutputCapacityLedgerEntryOnBeforeValidateQuantity(var ItemJournalLine: Record "Item Journal Line"; CapacityLedgerEntry: Record "Capacity Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOutputItemLedgerEntryOnBeforeValidateOutputQuantity(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOutputCapacityLedgerEntryOnBeforeItemJnlPostLine(var ItemJournalLine: Record "Item Journal Line"; CapacityLedgerEntry: Record "Capacity Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseOutputItemLedgerEntryOnBeforeItemJnlPostLine(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseConsumptionItemLedgerEntryOnBeforeItemJnlPostLine(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry"; ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseProdItemLedgerEntryOnAfterProcessItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReverseCapacityLedgerEntryOnAfterReverseOutputCapacityLedgerEntry(CapacityLedgerEntry: Record "Capacity Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateProdOrder(ItemLedgerEntry: Record "Item Ledger Entry"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateConsumptionReservationEntryOnBeforeInsert(var ReservationEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;
}