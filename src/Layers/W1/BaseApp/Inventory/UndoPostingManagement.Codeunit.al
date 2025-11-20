// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

codeunit 5817 "Undo Posting Management"
{
    Permissions = TableData "Reservation Entry" = i;

    trigger OnRun()
    begin
    end;

    var
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
#pragma warning disable AA0470
        InsufficientBinContentErr: Label 'You cannot undo line %1 because there is not sufficient content in the receiving bins.';
        PutAwayLinesCreatedErr: Label 'You cannot undo line %1 because warehouse put-away lines have already been created.';
        ActivityLinesCreatedErr: Label 'You cannot undo line %1 because warehouse activity lines have already been created.';
        DeleteRelatedErr: Label 'You must delete the related %1 before you undo line %2.';
        ReceiptLinesCreatedErr: Label 'You cannot undo line %1 because warehouse receipt lines have already been created.';
        ShipmentLinesCreatedErr: Label 'You cannot undo line %1 because warehouse shipment lines have already been created.';
        ItemsPickedQst: Label 'The items have been picked. If you undo line %1, the items will remain in the shipping area until you put them away.\Do you still want to undo the shipment?';
        WorksheetLinesExistErr: Label 'You cannot undo line %1 because warehouse worksheet lines exist for this line.';
        PutAwayLinesPostedErr: Label 'You cannot undo line %1 because warehouse put-away lines have already been posted.';
        InventoryPickPostedErr: Label 'You cannot undo line %1 because inventory pick lines have already been posted.';
        ItemChargeAssignedErr: Label 'You cannot undo line %1 because there is an item charge assigned to it on %2 Doc No. %3 Line %4.';
        ItemChargeInvoicedErr: Label 'You cannot undo line %1 because an item charge has already been invoiced.';
        MissingItemLedgerErr: Label 'Item ledger entries are missing for line %1.';
        RevaluationPostedErr: Label 'You cannot undo line %1, because a revaluation has already been posted.';
        ItemNotAvailableErr: Label 'You cannot undo posting of item %1 with variant ''%2'' and unit of measure %3 because it is not available at location %4, bin code %5. The required quantity is %6. The available quantity is %7.';
#pragma warning restore AA0470
        NonSurplusResEntriesErr: Label 'You cannot undo transfer shipment line %1 because this line is Reserved. Reservation Entry No. %2', Comment = '%1 = Line No., %2 = Entry No.';

    procedure TestTransferShptLine(TransferShptLine: Record "Transfer Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestTransferShptLine(TransferShptLine, IsHandled);
        if IsHandled then
            exit;

        TestAllTransactions(
            DATABASE::"Transfer Shipment Line", TransferShptLine."Document No.", TransferShptLine."Line No.",
            DATABASE::"Transfer Line", 0, TransferShptLine."Transfer Order No.", TransferShptLine."Line No.");
    end;

    procedure TestSalesShptLine(SalesShptLine: Record "Sales Shipment Line")
    var
        SalesLine: Record "Sales Line";
    begin
        TestAllTransactions(
            DATABASE::"Sales Shipment Line", SalesShptLine."Document No.", SalesShptLine."Line No.",
            DATABASE::"Sales Line", SalesLine."Document Type"::Order.AsInteger(), SalesShptLine."Order No.", SalesShptLine."Order Line No.");
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Undo Posting Mgt.', '25.0')]
    procedure TestServShptLine(ServShptLine: Record Microsoft.Service.History."Service Shipment Line")
    var
        ServUndoPostingMgt: Codeunit "Serv. Undo Posting Mgt.";
    begin
        ServUndoPostingMgt.TestServShptLine(ServShptLine);
    end;
#endif

    procedure TestPurchRcptLine(PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        TestAllTransactions(
            DATABASE::"Purch. Rcpt. Line", PurchRcptLine."Document No.", PurchRcptLine."Line No.",
            DATABASE::"Purchase Line", PurchLine."Document Type"::Order.AsInteger(), PurchRcptLine."Order No.", PurchRcptLine."Order Line No.");
    end;

    procedure TestReturnShptLine(ReturnShptLine: Record "Return Shipment Line")
    var
        PurchLine: Record "Purchase Line";
    begin
        TestAllTransactions(
            DATABASE::"Return Shipment Line", ReturnShptLine."Document No.", ReturnShptLine."Line No.",
            DATABASE::"Purchase Line", PurchLine."Document Type"::"Return Order".AsInteger(), ReturnShptLine."Return Order No.", ReturnShptLine."Return Order Line No.");
    end;

    procedure TestReturnRcptLine(ReturnRcptLine: Record "Return Receipt Line")
    var
        SalesLine: Record "Sales Line";
    begin
        TestAllTransactions(
            DATABASE::"Return Receipt Line", ReturnRcptLine."Document No.", ReturnRcptLine."Line No.",
            DATABASE::"Sales Line", SalesLine."Document Type"::"Return Order".AsInteger(), ReturnRcptLine."Return Order No.", ReturnRcptLine."Return Order Line No.");
    end;

    procedure TestAsmHeader(PostedAsmHeader: Record "Posted Assembly Header")
    var
        AsmHeader: Record "Assembly Header";
    begin
        TestAllTransactions(
            DATABASE::"Posted Assembly Header", PostedAsmHeader."No.", 0,
            DATABASE::"Assembly Header", AsmHeader."Document Type"::Order.AsInteger(), PostedAsmHeader."Order No.", 0);
    end;

    procedure TestAsmLine(PostedAsmLine: Record "Posted Assembly Line")
    var
        AsmLine: Record "Assembly Line";
    begin
        TestAllTransactions(
            DATABASE::"Posted Assembly Line", PostedAsmLine."Document No.", PostedAsmLine."Line No.",
            DATABASE::"Assembly Line", AsmLine."Document Type"::Order.AsInteger(), PostedAsmLine."Order No.", PostedAsmLine."Order Line No.");
    end;

    procedure RunTestAllTransactions(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
        TestAllTransactions(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
    end;

    procedure TestAllTransactions(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        IsHandled: Boolean;
    begin
        OnBeforeTestAllTransactions(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        if not TestPostedWhseReceiptLine(
             UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo)
        then begin
            IsHandled := false;
            OnTestAllTransactionsOnBeforeTestWarehouseActivityLine(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
            if not IsHandled then
                TestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
            TestRgstrdWhseActivityLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
            TestWhseWorksheetLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        end;

        if not (UndoType in [DATABASE::"Purch. Rcpt. Line", DATABASE::"Return Receipt Line"]) then
            TestWarehouseReceiptLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        if not SkipTestWarehouseShipmentLine(UndoType) then
            TestWarehouseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);

        TestPostedWhseShipmentLine(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        TestPostedInvtPutAwayLine(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
        TestPostedInvtPickLine(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);

        TestItemChargeAssignmentPurch(UndoType, UndoLineNo, SourceID, SourceRefNo);
        TestItemChargeAssignmentSales(UndoType, UndoLineNo, SourceID, SourceRefNo);

        OnAfterTestAllTransactions(UndoType, UndoID, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
    end;

    local procedure SkipTestWarehouseShipmentLine(UndoType: Integer) SkipTest: Boolean
    begin
        SkipTest := UndoType in [DATABASE::"Sales Shipment Line", DATABASE::"Return Shipment Line"];

        OnSkipTestWarehouseShipmentLine(UndoType, SkipTest);
    end;

    local procedure TestPostedWhseReceiptLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer): Boolean
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        PostedAsmHeader: Record "Posted Assembly Header";
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
    begin
        case UndoType of
            DATABASE::"Posted Assembly Line":
                begin
                    TestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo);
                    exit(true);
                end;
            DATABASE::"Posted Assembly Header":
                begin
                    PostedAsmHeader.Get(UndoID);
                    if not PostedAsmHeader.IsAsmToOrder() then
                        TestWarehouseBinContent(SourceType, SourceSubtype, SourceID, SourceRefNo, PostedAsmHeader."Quantity (Base)");
                    exit(true);
                end;
        end;

        if not WhseUndoQty.FindPostedWhseRcptLine(
             PostedWhseReceiptLine, UndoType, UndoID, SourceType, SourceSubtype, SourceID, SourceRefNo)
        then
            exit(false);

        TestWarehouseEntry(UndoLineNo, PostedWhseReceiptLine);
        TestWarehouseActivityLine2(UndoLineNo, PostedWhseReceiptLine);
        TestRgstrdWhseActivityLine2(UndoLineNo, PostedWhseReceiptLine);
        TestWhseWorksheetLine2(UndoLineNo, PostedWhseReceiptLine);
        exit(true);
    end;

    local procedure TestWarehouseEntry(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WarehouseEntry: Record "Warehouse Entry";
        Location: Record Location;
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseEntry(UndoLineNo, PostedWhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        if PostedWhseReceiptLine."Location Code" = '' then
            exit;

        if PostedWhseReceiptLine."Bin Code" <> '' then
            if WhsePostReceipt.IsReceiptForJob(PostedWhseReceiptLine) then
                exit;

        Location.Get(PostedWhseReceiptLine."Location Code");
        if Location."Bin Mandatory" then begin
            WarehouseEntry.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code");
            WarehouseEntry.SetRange("Item No.", PostedWhseReceiptLine."Item No.");
            WarehouseEntry.SetRange("Location Code", PostedWhseReceiptLine."Location Code");
            WarehouseEntry.SetRange("Variant Code", PostedWhseReceiptLine."Variant Code");
            if Location."Directed Put-away and Pick" then
                WarehouseEntry.SetFilter(WarehouseEntry."Bin Type Code", GetBinTypeFilter(0));
            // Receiving area
            OnTestWarehouseEntryOnAfterSetFilters(WarehouseEntry, PostedWhseReceiptLine);
            WarehouseEntry.CalcSums(WarehouseEntry."Qty. (Base)");
            if WarehouseEntry."Qty. (Base)" < PostedWhseReceiptLine."Qty. (Base)" then
                Error(InsufficientBinContentErr, UndoLineNo);
        end;
    end;

    local procedure TestWarehouseBinContent(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; UndoQtyBase: Decimal)
    var
        WhseEntry: Record "Warehouse Entry";
        BinContent: Record "Bin Content";
        QtyAvailToTake: Decimal;
    begin
        WhseEntry.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WhseEntry.FindFirst() then
            exit;

        BinContent.Get(WhseEntry."Location Code", WhseEntry."Bin Code", WhseEntry."Item No.", WhseEntry."Variant Code", WhseEntry."Unit of Measure Code");
        QtyAvailToTake := BinContent.CalcQtyAvailToTake(0);
        if QtyAvailToTake < UndoQtyBase then
            Error(ItemNotAvailableErr,
              WhseEntry."Item No.",
              WhseEntry."Variant Code",
              WhseEntry."Unit of Measure Code",
              WhseEntry."Location Code",
              WhseEntry."Bin Code",
              UndoQtyBase,
              QtyAvailToTake);
    end;

    local procedure TestWarehouseActivityLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseActivityLine2(WarehouseActivityLine, IsHandled);
        if IsHandled then
            exit;

        WarehouseActivityLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Receipt);
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
        if not WarehouseActivityLine.IsEmpty() then
            Error(PutAwayLinesCreatedErr, UndoLineNo);
    end;

    local procedure TestRgstrdWhseActivityLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestRgstrdWhseActivityLine2(PostedWhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        RegisteredWhseActivityLine.SetRange("Whse. Document Type", RegisteredWhseActivityLine."Whse. Document Type"::Receipt);
        RegisteredWhseActivityLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        RegisteredWhseActivityLine.SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
        if not RegisteredWhseActivityLine.IsEmpty() then
            Error(ActivityLinesCreatedErr, UndoLineNo);
    end;

    local procedure TestWhseWorksheetLine2(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Receipt);
        WhseWorksheetLine.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        WhseWorksheetLine.SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
        if not WhseWorksheetLine.IsEmpty() then
            Error(DeleteRelatedErr, WhseWorksheetLine.TableCaption(), UndoLineNo);
    end;

    local procedure TestWarehouseActivityLine(UndoType: Integer; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseActivityLine(UndoType, UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        WarehouseActivityLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, -1, true);
        if not WarehouseActivityLine.IsEmpty() then begin
            if UndoType = DATABASE::"Assembly Line" then
                Error(PutAwayLinesCreatedErr, UndoLineNo);
            Error(ActivityLinesCreatedErr, UndoLineNo);
        end;
    end;

    local procedure TestRgstrdWhseActivityLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestRgstrdWhseActivityLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        RegisteredWhseActivityLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, -1, true);
        RegisteredWhseActivityLine.SetRange("Activity Type", RegisteredWhseActivityLine."Activity Type"::"Put-away");
        if not RegisteredWhseActivityLine.IsEmpty() then
            Error(PutAwayLinesCreatedErr, UndoLineNo);
    end;

    local procedure TestWarehouseReceiptLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseReceiptLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        WhseManagement.SetSourceFilterForWhseRcptLine(WarehouseReceiptLine, SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WarehouseReceiptLine.IsEmpty() then
            Error(ReceiptLinesCreatedErr, UndoLineNo);
    end;

    local procedure TestWarehouseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWarehouseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        WarehouseShipmentLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WarehouseShipmentLine.IsEmpty() then
            Error(ShipmentLinesCreatedErr, UndoLineNo);
    end;

    local procedure TestPostedWhseShipmentLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPostedWhseShipmentLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled, UndoType, UndoID);
        if IsHandled then
            exit;

        WhseManagement.SetSourceFilterForPostedWhseShptLine(PostedWhseShipmentLine, SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not PostedWhseShipmentLine.IsEmpty() then
            if not Confirm(ItemsPickedQst, true, UndoLineNo) then
                Error('');
    end;

    local procedure TestWhseWorksheetLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestWhseWorksheetLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled);
        if IsHandled then
            exit;

        WhseWorksheetLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not WhseWorksheetLine.IsEmpty() then
            Error(WorksheetLinesExistErr, UndoLineNo);
    end;

    local procedure TestPostedInvtPutAwayLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPostedInvtPutAwayLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled, UndoType, UndoID);
        if IsHandled then
            exit;

        PostedInvtPutAwayLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if not PostedInvtPutAwayLine.IsEmpty() then
            Error(PutAwayLinesPostedErr, UndoLineNo);
    end;

    local procedure TestPostedInvtPickLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestPostedInvtPickLine(UndoLineNo, SourceType, SourceSubtype, SourceID, SourceRefNo, IsHandled, UndoType, UndoID);
        if IsHandled then
            exit;

        PostedInvtPickLine.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        if ShouldThrowErrorForPostedInvtPickLine(PostedInvtPickLine, UndoType, UndoID) then
            Error(InventoryPickPostedErr, UndoLineNo);
    end;

    local procedure ShouldThrowErrorForPostedInvtPickLine(var PostedInvtPickLine: Record "Posted Invt. Pick Line"; UndoType: Integer; UndoID: Code[20]): Boolean
    var
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
        CheckedPostedInvtPickHeaderList: List of [Text];
    begin
        if PostedInvtPickLine.IsEmpty() then
            exit(false);

        if not (UndoType in [Database::"Sales Shipment Line"]) then
            exit(true);

        PostedInvtPickLine.SetLoadFields("No.");
        if PostedInvtPickLine.FindSet() then
            repeat
                if not CheckedPostedInvtPickHeaderList.Contains(PostedInvtPickLine."No.") then begin
                    CheckedPostedInvtPickHeaderList.Add(PostedInvtPickLine."No.");

                    PostedInvtPickHeader.SetLoadFields("Source Type", "Source No.");
                    if not PostedInvtPickHeader.Get(PostedInvtPickLine."No.") then
                        exit(true);

                    case UndoType of
                        Database::"Sales Shipment Line":
                            begin
                                if PostedInvtPickHeader."Source Type" <> Database::"Sales Shipment Header" then
                                    exit(true);

                                if PostedInvtPickHeader."Source No." = UndoID then
                                    exit(true);
                            end;
                        else
                            exit(true);
                    end;
                end;
            until PostedInvtPickLine.Next() = 0;

        exit(false);
    end;

    local procedure TestItemChargeAssignmentPurch(UndoType: Integer; UndoLineNo: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        case UndoType of
            DATABASE::"Purch. Rcpt. Line":
                ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt);
            DATABASE::"Return Shipment Line":
                ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Type", ItemChargeAssignmentPurch."Applies-to Doc. Type"::"Return Shipment");
            else
                exit;
        end;
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. No.", SourceID);
        ItemChargeAssignmentPurch.SetRange("Applies-to Doc. Line No.", SourceRefNo);
        if not ItemChargeAssignmentPurch.IsEmpty() then
            if ItemChargeAssignmentPurch.FindFirst() then
                Error(ItemChargeAssignedErr, UndoLineNo, ItemChargeAssignmentPurch."Document Type", ItemChargeAssignmentPurch."Document No.", ItemChargeAssignmentPurch."Line No.");
    end;

    local procedure TestItemChargeAssignmentSales(UndoType: Integer; UndoLineNo: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    var
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
    begin
        ItemChargeAssignmentSales.SetCurrentKey("Applies-to Doc. Type", "Applies-to Doc. No.", "Applies-to Doc. Line No.");
        case UndoType of
            DATABASE::"Sales Shipment Line":
                ItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", ItemChargeAssignmentSales."Applies-to Doc. Type"::Shipment);
            DATABASE::"Return Receipt Line":
                ItemChargeAssignmentSales.SetRange("Applies-to Doc. Type", ItemChargeAssignmentSales."Applies-to Doc. Type"::"Return Receipt");
            else
                exit;
        end;
        ItemChargeAssignmentSales.SetRange("Applies-to Doc. No.", SourceID);
        ItemChargeAssignmentSales.SetRange("Applies-to Doc. Line No.", SourceRefNo);
        if not ItemChargeAssignmentSales.IsEmpty() then
            if ItemChargeAssignmentSales.FindFirst() then
                Error(ItemChargeAssignedErr, UndoLineNo, ItemChargeAssignmentSales."Document Type", ItemChargeAssignmentSales."Document No.", ItemChargeAssignmentSales."Line No.");
    end;

    local procedure GetBinTypeFilter(Type: Option Receive,Ship,"Put Away",Pick): Text[1024]
    var
        BinType: Record "Bin Type";
        "Filter": Text[1024];
    begin
        case Type of
            Type::Receive:
                BinType.SetRange(BinType.Receive, true);
            Type::Ship:
                BinType.SetRange(BinType.Ship, true);
            Type::"Put Away":
                BinType.SetRange(BinType."Put Away", true);
            Type::Pick:
                BinType.SetRange(BinType.Pick, true);
        end;
        if BinType.Find('-') then
            repeat
                Filter := StrSubstNo('%1|%2', Filter, BinType.Code);
            until BinType.Next() = 0;
        if Filter <> '' then
            Filter := CopyStr(Filter, 2);
        exit(Filter);
    end;

    procedure CheckItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; LineRef: Integer)
    begin
        CheckItemLedgEntries(TempItemLedgEntry, LineRef, false);
    end;

    procedure CheckItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; LineRef: Integer; InvoicedEntry: Boolean)
    var
        ItemRec: Record Item;
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemLedgEntries(TempItemLedgEntry, LineRef, InvoicedEntry, IsHandled);
        if IsHandled then
            exit;

        TempItemLedgEntry.Find('-');
        // Assertion: will fail if not found.
        ItemRec.Get(TempItemLedgEntry."Item No.");
        if ItemRec.IsNonInventoriableType() then
            exit;

        repeat
            IsHandled := false;
            OnCheckItemLedgEntriesOnBeforeCheckTempItemLedgEntry(TempItemLedgEntry, IsHandled);
            if not IsHandled then
                if TempItemLedgEntry.Positive then begin
                    if (TempItemLedgEntry."Job No." = '') and
                    not ((TempItemLedgEntry."Order Type" = TempItemLedgEntry."Order Type"::Assembly) and
                            PostedATOLink.Get(PostedATOLink."Assembly Document Type"::Assembly, TempItemLedgEntry."Document No."))
                    then
                        if InvoicedEntry then
                            TempItemLedgEntry.TestField("Remaining Quantity", TempItemLedgEntry.Quantity - TempItemLedgEntry."Invoiced Quantity")
                        else
                            TempItemLedgEntry.TestField("Remaining Quantity", TempItemLedgEntry.Quantity);
                end else
                    if TempItemLedgEntry."Entry Type" <> TempItemLedgEntry."Entry Type"::Transfer then
                        if InvoicedEntry then
                            TempItemLedgEntry.TestField("Shipped Qty. Not Returned", TempItemLedgEntry.Quantity - TempItemLedgEntry."Invoiced Quantity")
                        else
                            TempItemLedgEntry.TestField("Shipped Qty. Not Returned", TempItemLedgEntry.Quantity);

            TempItemLedgEntry.CalcFields(TempItemLedgEntry."Reserved Quantity");
            TempItemLedgEntry.TestField("Reserved Quantity", 0);

            CheckValueEntries(TempItemLedgEntry, LineRef, InvoicedEntry);

            if ItemRec."Costing Method" = ItemRec."Costing Method"::Specific then
                TempItemLedgEntry.TestField("Serial No.");
        until TempItemLedgEntry.Next() = 0; // WITH
    end;

    local procedure CheckValueEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; LineRef: Integer; InvoicedEntry: Boolean)
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckValueEntries(TempItemLedgEntry, LineRef, InvoicedEntry, IsHandled);
        if IsHandled then
            exit;

        ValueEntry.SetRange("Item Ledger Entry No.", TempItemLedgEntry."Entry No.");
        ValueEntry.SetFilter("Item Charge No.", '<> %1', '');
        if not ValueEntry.IsEmpty() then
            Error(ItemChargeInvoicedErr, LineRef);

        ValueEntry.SetRange("Item Charge No.");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        if not ValueEntry.IsEmpty() then
            Error(RevaluationPostedErr, LineRef);
    end;

    procedure PostItemJnlLineAppliedToList(ItemJnlLine: Record "Item Journal Line"; var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary; UndoQty: Decimal; UndoQtyBase: Decimal; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempItemEntryRelation: Record "Item Entry Relation" temporary)
    begin
        PostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToItemLedgEntry, UndoQty, UndoQtyBase, TempItemLedgEntry, TempItemEntryRelation, false);
    end;

    procedure PostItemJnlLineAppliedToList(ItemJnlLine: Record "Item Journal Line"; var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary; UndoQty: Decimal; UndoQtyBase: Decimal; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempItemEntryRelation: Record "Item Entry Relation" temporary; InvoicedEntry: Boolean)
    var
        ItemApplicationEntry: Record "Item Application Entry";
        NonDistrQuantity: Decimal;
        NonDistrQuantityBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLineAppliedToList(ItemJnlLine, TempApplyToItemLedgEntry, UndoQty, UndoQtyBase, TempItemLedgEntry, TempItemEntryRelation, InvoicedEntry, IsHandled);
        if IsHandled then
            exit;

        if InvoicedEntry then begin
            TempApplyToItemLedgEntry.SetRange("Completely Invoiced", false);
            if AreAllItemEntriesCompletelyInvoiced(TempApplyToItemLedgEntry) then begin
                TempApplyToItemLedgEntry.SetRange("Completely Invoiced");
                exit;
            end;
        end;
        TempApplyToItemLedgEntry.Find('-'); // Assertion: will fail if not found.
        if ItemJnlLine."Job No." = '' then
            ItemJnlLine.TestField(Correction, true);
        NonDistrQuantity := -UndoQty;
        NonDistrQuantityBase := -UndoQtyBase;
        repeat
            if ItemJnlLine."Job No." = '' then
                ItemJnlLine."Applies-to Entry" := TempApplyToItemLedgEntry."Entry No."
            else
                ItemJnlLine."Applies-to Entry" := 0;

            ItemJnlLine."Item Shpt. Entry No." := 0;
            ItemJnlLine."Quantity (Base)" := -TempApplyToItemLedgEntry.Quantity;
            ItemJnlLine."Invoiced Qty. (Base)" := -TempApplyToItemLedgEntry."Invoiced Quantity";
            OnPostItemJnlLineAppliedToListOnAfterSetInvoicedQty(ItemJnlLine, TempApplyToItemLedgEntry);
            ItemJnlLine.CopyTrackingFromItemLedgEntry(TempApplyToItemLedgEntry);
            if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then
                ItemJnlLine.CopyNewTrackingFromOldItemLedgerEntry(TempApplyToItemLedgEntry);

            // Quantity is filled in according to UOM:
            AdjustQuantityRounding(ItemJnlLine, NonDistrQuantity, NonDistrQuantityBase);

            NonDistrQuantity := NonDistrQuantity - ItemJnlLine.Quantity;
            NonDistrQuantityBase := NonDistrQuantityBase - ItemJnlLine."Quantity (Base)";

            OnBeforePostItemJnlLine(ItemJnlLine, TempApplyToItemLedgEntry);
            PostItemJnlLine(ItemJnlLine);
            OnPostItemJnlLineAppliedToListOnAfterPostItemJnlLine(ItemJnlLine, TempApplyToItemLedgEntry);

            UndoValuePostingFromJob(ItemJnlLine, ItemApplicationEntry, TempApplyToItemLedgEntry);

            TempItemEntryRelation."Item Entry No." := ItemJnlLine."Item Shpt. Entry No.";
            TempItemEntryRelation.CopyTrackingFromItemJnlLine(ItemJnlLine);
            OnPostItemJnlLineAppliedToListOnBeforeTempItemEntryRelationInsert(TempItemEntryRelation, ItemJnlLine);
            TempItemEntryRelation.Insert();
            TempItemLedgEntry := TempApplyToItemLedgEntry;
            TempItemLedgEntry.Insert();
        until TempApplyToItemLedgEntry.Next() = 0;
    end;

    procedure AreAllItemEntriesCompletelyInvoiced(var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary): Boolean
    var
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
    begin
        TempItemLedgerEntry.Copy(TempApplyToItemLedgEntry, true);
        TempItemLedgerEntry.SetRange("Completely Invoiced", false);
        exit(TempItemLedgerEntry.IsEmpty());
    end;

    local procedure AdjustQuantityRounding(var ItemJnlLine: Record "Item Journal Line"; var NonDistrQuantity: Decimal; NonDistrQuantityBase: Decimal)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAdjustQuantityRounding(ItemJnlLine, NonDistrQuantity, NonDistrQuantityBase, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingMgt.AdjustQuantityRounding(
          NonDistrQuantity, ItemJnlLine.Quantity,
          NonDistrQuantityBase, ItemJnlLine."Quantity (Base)");

        ItemTrackingMgt.AdjustQuantityRounding(
         ItemJnlLine.Quantity, ItemJnlLine."Invoiced Quantity",
         ItemJnlLine."Quantity (Base)", ItemJnlLine."Invoiced Qty. (Base)");
    end;

    procedure CollectItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SourceType: Integer; DocumentNo: Code[20]; LineNo: Integer; BaseQty: Decimal; EntryRef: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        TempItemLedgEntry.Reset();
        if not TempItemLedgEntry.IsEmpty() then
            TempItemLedgEntry.DeleteAll();
        if EntryRef <> 0 then begin
            ItemLedgEntry.Get(EntryRef); // Assertion: will fail if no entry exists.
            TempItemLedgEntry := ItemLedgEntry;
            TempItemLedgEntry.Insert();
        end else begin
            if ShouldRevertBaseQtySign(SourceType) then
                BaseQty := BaseQty * -1;
            CheckMissingItemLedgers(TempItemLedgEntry, SourceType, DocumentNo, LineNo, BaseQty);
        end;
    end;

    internal procedure CollectOutputItemLedgEntriesForSubcontructingPurcReceiptLine(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; PurchRcptLine: Record "Purch. Rcpt. Line") Result: Boolean
    begin
        OnCollectOutputItemLedgEntriesForSubcontructingPurcReceiptLine(TempItemLedgEntry, PurchRcptLine, Result);
    end;

    local procedure ShouldRevertBaseQtySign(SourceType: Integer) RevertSign: Boolean
    begin
        RevertSign :=
            SourceType in [DATABASE::"Sales Shipment Line",
                            DATABASE::"Return Shipment Line",
                            DATABASE::"Posted Assembly Line",
                            DATABASE::"Transfer Shipment Line"];

        OnShouldRevertBaseQtySign(SourceType, RevertSign);
    end;

    local procedure CheckMissingItemLedgers(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SourceType: Integer; DocumentNo: Code[20]; LineNo: Integer; BaseQty: Decimal)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMissingItemLedgers(TempItemLedgEntry, SourceType, DocumentNo, LineNo, BaseQty, IsHandled);
        if IsHandled then
            exit;

        if not ItemTrackingMgt.CollectItemEntryRelation(TempItemLedgEntry, SourceType, 0, DocumentNo, '', 0, LineNo, BaseQty) then
            Error(MissingItemLedgerErr, LineNo);
    end;

    local procedure UndoValuePostingFromJob(ItemJnlLine: Record "Item Journal Line"; ItemApplicationEntry: Record "Item Application Entry"; var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUndoValuePostingFromJob(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        if ItemJnlLine."Job No." = '' then
            exit;

        Clear(ItemJnlPostLine);
        if TempApplyToItemLedgEntry.Positive then begin
            FindItemReceiptApplication(ItemApplicationEntry, TempApplyToItemLedgEntry."Entry No.");
            ItemJnlPostLine.UndoValuePostingWithJob(TempApplyToItemLedgEntry."Entry No.", ItemApplicationEntry."Outbound Item Entry No.");
            FindItemShipmentApplication(ItemApplicationEntry, ItemJnlLine."Item Shpt. Entry No.");
            ItemJnlPostLine.UndoValuePostingWithJob(ItemApplicationEntry."Inbound Item Entry No.", ItemJnlLine."Item Shpt. Entry No.");
        end else begin
            FindItemShipmentApplication(ItemApplicationEntry, TempApplyToItemLedgEntry."Entry No.");
            ItemJnlPostLine.UndoValuePostingWithJob(ItemApplicationEntry."Inbound Item Entry No.", TempApplyToItemLedgEntry."Entry No.");
            FindItemReceiptApplication(ItemApplicationEntry, ItemJnlLine."Item Shpt. Entry No.");
            ItemJnlPostLine.UndoValuePostingWithJob(ItemJnlLine."Item Shpt. Entry No.", ItemApplicationEntry."Outbound Item Entry No.");
        end;
    end;

    procedure UpdatePurchLine(PurchLine: Record "Purchase Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        xPurchLine: Record "Purchase Line";
        PurchSetup: Record "Purchases & Payables Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePurchLine(PurchLine, UndoQty, UndoQtyBase, TempUndoneItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        PurchSetup.Get();
        xPurchLine := PurchLine;
        case PurchLine."Document Type" of
            PurchLine."Document Type"::"Return Order":
                begin
                    PurchLine."Return Qty. Shipped" := PurchLine."Return Qty. Shipped" - UndoQty;
                    PurchLine."Return Qty. Shipped (Base)" := PurchLine."Return Qty. Shipped (Base)" - UndoQtyBase;
                    PurchLine.InitOutstanding();
                    if PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank then
                        PurchLine."Qty. to Receive" := 0
                    else
                        PurchLine.InitQtyToShip();
                    OnUpdatePurchLineOnAfterSetQtyToShip(PurchLine);
                    PurchLine.UpdateWithWarehouseReceive();
                end;
            PurchLine."Document Type"::Order:
                begin
                    PurchLine."Quantity Received" := PurchLine."Quantity Received" - UndoQty;
                    PurchLine."Qty. Received (Base)" := PurchLine."Qty. Received (Base)" - UndoQtyBase;
                    PurchLine.InitOutstanding();
                    if PurchSetup."Default Qty. to Receive" = PurchSetup."Default Qty. to Receive"::Blank then
                        PurchLine."Qty. to Receive" := 0
                    else
                        PurchLine.InitQtyToReceive();
                    OnUpdatePurchLineOnAfterSetQtyToReceive(PurchLine);
                    PurchLine.UpdateWithWarehouseReceive();
                end;
            else
                PurchLine.FieldError(PurchLine."Document Type");
        end;
        OnUpdatePurchLineOnBeforePurchLineModify(PurchLine);
        PurchLine.Modify();
        if not PurchLine.IsProdOrder() then
            RevertPostedItemTrackingFromPurchLine(PurchLine, TempUndoneItemLedgEntry);
        xPurchLine."Quantity (Base)" := 0;
        PurchLineReserveVerifyQuantity(PurchLine, xPurchLine);

        UpdateWarehouseRequest(DATABASE::"Purchase Line", PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Location Code");

        OnAfterUpdatePurchline(PurchLine);
    end;

    local procedure RevertPostedItemTrackingFromPurchLine(PurchLine: Record "Purchase Line"; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRevertPostedItemTrackingFromPurchLine(PurchLine, TempUndoneItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        RevertPostedItemTracking(TempUndoneItemLedgEntry, PurchLine."Expected Receipt Date", false);
    end;

    local procedure PurchLineReserveVerifyQuantity(PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line")
    var
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePurchLineReserveVerifyQuantity(PurchLine, xPurchLine, IsHandled);
        if IsHandled then
            exit;

        PurchLineReserve.VerifyQuantity(PurchLine, xPurchLine);
    end;

    procedure UpdateSalesLine(SalesLine: Record "Sales Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        xSalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateSalesLine(SalesLine, UndoQty, UndoQtyBase, TempUndoneItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        xSalesLine := SalesLine;
        case SalesLine."Document Type" of
            SalesLine."Document Type"::"Return Order":
                begin
                    SalesLine."Return Qty. Received" := SalesLine."Return Qty. Received" - UndoQty;
                    SalesLine."Return Qty. Received (Base)" := SalesLine."Return Qty. Received (Base)" - UndoQtyBase;
                    OnUpdateSalesLineOnBeforeInitOustanding(SalesLine, UndoQty, UndoQtyBase);
                    SalesLine.InitOutstanding();
                    if SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Blank then
                        SalesLine."Qty. to Ship" := 0
                    else
                        SalesLine.InitQtyToReceive();
                    SalesLine.UpdateWithWarehouseShip();
                    OnUpdateSalesLineOnAfterUpdateWithWarehouseShipForReturnOrder(SalesLine);
                end;
            SalesLine."Document Type"::Order:
                begin
                    SalesLine."Quantity Shipped" := SalesLine."Quantity Shipped" - UndoQty;
                    SalesLine."Qty. Shipped (Base)" := SalesLine."Qty. Shipped (Base)" - UndoQtyBase;
                    OnUpdateSalesLineOnBeforeInitOustanding(SalesLine, UndoQty, UndoQtyBase);
                    SalesLine.InitOutstanding();
                    if SalesSetup."Default Quantity to Ship" = SalesSetup."Default Quantity to Ship"::Blank then
                        SalesLine."Qty. to Ship" := 0
                    else
                        SalesLine.InitQtyToShip();
                    SalesLine.UpdateWithWarehouseShip();
                end;
            else
                SalesLine.FieldError(SalesLine."Document Type");
        end;
        OnUpdateSalesLineOnBeforeSalesLineModify(SalesLine);
        SalesLine.Modify();
        RevertPostedItemTrackingFromSalesLine(SalesLine, TempUndoneItemLedgEntry);
        xSalesLine."Quantity (Base)" := 0;
        SalesLineReserveVerifyQuantity(SalesLine, xSalesLine);

        UpdateWarehouseRequest(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Location Code");

        OnAfterUpdateSalesLine(SalesLine);
    end;

    internal procedure UpdateDerivedTransferLine(var TransferLine: Record "Transfer Line"; var TransferShptLine: Record "Transfer Shipment Line")
    var
        DerivedTransferLine: Record "Transfer Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        // Find the derived line
        DerivedTransferLine.SetRange("Document No.", TransferShptLine."Transfer Order No.");
        DerivedTransferLine.SetRange("Line No.", TransferShptLine."Derived Trans. Order Line No.");
        DerivedTransferLine.FindFirst();
        DerivedTransferLine.TestField("Derived From Line No.", TransferLine."Line No.");

        // Move tracking information from the derived line to the original line
        TransferTracking(DerivedTransferLine, TransferLine, TransferShptLine);
        OnUpdateDerivedTransferLineOnAfterTransferTracking(TransferLine, TransferShptLine, DerivedTransferLine);

        // Update any Transfer Shipment Lines that are pointing to this Derived Transfer Order Line
        TransferShipmentLine.SetRange("Transfer Order No.", DerivedTransferLine."Document No.");
        TransferShipmentLine.SetRange("Derived Trans. Order Line No.", DerivedTransferLine."Line No.");
        if TransferShipmentLine.FindSet() then
            TransferShipmentLine.ModifyAll("Derived Trans. Order Line No.", 0);

        // Reload the TransShptLine now that it has changed
        TransferShptLine.Get(TransferShptLine."Document No.", TransferShptLine."Line No.");

        // Delete the derived line - a new one gets created for each shipment
        DerivedTransferLine.Delete();
    end;

    local procedure TransferTracking(var FromTransLine: Record "Transfer Line"; var ToTransLine: Record "Transfer Line"; var TransferShptLine: Record "Transfer Shipment Line")
    var
        ReservationEntry: Record "Reservation Entry";
        ReserveTransLine: Codeunit "Transfer Line-Reserve";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        FromReservationEntryRowID: Text[250];
        ToReservationEntryRowID: Text[250];
        TransferQtyBase: Decimal;
    begin
        TransferQtyBase := FromTransLine."Quantity (Base)";
        ReserveTransLine.FindReservEntrySet(FromTransLine, ReservationEntry, "Transfer Direction"::Inbound);
        if ReservationEntry.IsEmpty() then
            exit;

        CheckReservationEntryStatus(ReservationEntry, TransferShptLine);

        FromReservationEntryRowID := ItemTrackingMgt.ComposeRowID( // From invisible TransferLine holding tracking
                    DATABASE::"Transfer Line", 1, ReservationEntry."Source ID", '', ReservationEntry."Source Prod. Order Line", ReservationEntry."Source Ref. No.");
        ToReservationEntryRowID := ItemTrackingMgt.ComposeRowID( // To original TransferLine
              DATABASE::"Transfer Line", 0, ReservationEntry."Source ID", '', 0, ReservationEntry."Source Prod. Order Line");

        ToTransLine.TestField("Variant Code", FromTransLine."Variant Code");

        // Recreate reservation entries on from-location which were deleted on posting shipment
        ItemTrackingMgt.CopyItemTracking(FromReservationEntryRowID, ToReservationEntryRowID, true); // Switch sign on quantities

        if not ReservationEntry.IsEmpty() then
            repeat
                ReservationEntry.TestItemFields(FromTransLine."Item No.", FromTransLine."Variant Code", FromTransLine."Transfer-to Code");
                UpdateTransferQuantity(TransferQtyBase, ToTransLine, ReservationEntry);
            until (ReservationEntry.Next() = 0) or (TransferQtyBase = 0);
    end;

    local procedure CheckReservationEntryStatus(var ReservationEntry: Record "Reservation Entry"; var TransferShipmentLine: Record "Transfer Shipment Line")
    begin
        ReservationEntry.SetFilter("Reservation Status", '<>%1', "Reservation Status"::Surplus);
        if ReservationEntry.FindFirst() then
            Error(NonSurplusResEntriesErr, TransferShipmentLine."Line No.", ReservationEntry."Entry No.");
        ReservationEntry.SetRange("Reservation Status");
        ReservationEntry.FindSet();
    end;

    local procedure UpdateTransferQuantity(var TransferQtyBase: Decimal; var NewTransLine: Record "Transfer Line"; var OldReservEntry: Record "Reservation Entry")
    var
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        TransferQtyBase :=
            CreateReservEntry.TransferReservEntry(DATABASE::"Transfer Line",
            "Transfer Direction"::Inbound.AsInteger(), NewTransLine."Document No.", '', NewTransLine."Derived From Line No.",
            NewTransLine."Line No.", NewTransLine."Qty. per Unit of Measure", OldReservEntry, TransferQtyBase);
    end;

    procedure UpdateTransLine(TransferLine: Record "Transfer Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        xTransferLine: Record "Transfer Line";
        SalesSetup: Record "Sales & Receivables Setup";
        Direction: Enum "Transfer Direction";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTransLine(TransferLine, UndoQty, UndoQtyBase, TempUndoneItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        xTransferLine := TransferLine;
        TransferLine."Quantity Shipped" := TransferLine."Quantity Shipped" - UndoQty;
        TransferLine."Qty. Shipped (Base)" := TransferLine."Qty. Shipped (Base)" - UndoQtyBase;
        TransferLine."Qty. to Receive" := Maximum(TransferLine."Qty. to Receive" - UndoQty, 0);
        TransferLine."Qty. to Receive (Base)" := Maximum(TransferLine."Qty. to Receive (Base)" - UndoQtyBase, 0);
        TransferLine.InitOutstandingQty();
        TransferLine.InitQtyToShip();
        TransferLine.InitQtyInTransit();

        TransferLine.Modify();
        xTransferLine."Quantity (Base)" := 0;
        TransferLineReserveVerifyQuantity(TransferLine, xTransferLine);

        UpdateWarehouseRequest(DATABASE::"Transfer Line", Direction::Outbound.AsInteger(), TransferLine."Document No.", TransferLine."Transfer-from Code");

        OnAfterUpdateTransLine(TransferLine);
    end;

    local procedure TransferLineReserveVerifyQuantity(TransferLine: Record "Transfer Line"; xTransferLine: Record "Transfer Line")
    var
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
    begin
        TransferLineReserve.VerifyQuantity(TransferLine, xTransferLine);
    end;

    local procedure RevertPostedItemTrackingFromSalesLine(SalesLine: Record "Sales Line"; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRevertPostedItemTrackingFromSalesLine(SalesLine, TempUndoneItemLedgEntry, IsHandled);
        if IsHandled then
            exit;

        RevertPostedItemTracking(TempUndoneItemLedgEntry, SalesLine."Shipment Date", false);
    end;

    local procedure SalesLineReserveVerifyQuantity(SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLineReserveVerifyQuantity(SalesLine, xSalesLine, IsHandled);
        if IsHandled then
            exit;

        SalesLineReserve.VerifyQuantity(SalesLine, xSalesLine);
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Undo Posting Mgt.', '25.0')]
    procedure UpdateServLine(ServLine: Record Microsoft.Service.Document."Service Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        ServUndoPostingMgt: Codeunit "Serv. Undo Posting Mgt.";
    begin
        ServUndoPostingMgt.UpdateServLine(ServLine, UndoQty, UndoQtyBase, TempUndoneItemLedgEntry);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit Serv. Undo Posting Mgt.', '25.0')]
    procedure UpdateServLineCnsm(var ServLine: Record Microsoft.Service.Document."Service Line"; UndoQty: Decimal; UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        ServUndoPostingMgt: Codeunit "Serv. Undo Posting Mgt.";
    begin
        ServUndoPostingMgt.UpdateServLineCnsm(ServLine, UndoQty, UndoQtyBase, TempUndoneItemLedgEntry);
    end;
#endif

    procedure RevertPostedItemTracking(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; AvailabilityDate: Date; RevertInvoiced: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        QtyToRevert: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRevertPostedItemTracking(TempItemLedgEntry, AvailabilityDate, RevertInvoiced, IsHandled);
        if not IsHandled then
            if TempItemLedgEntry.Find('-') then begin
                repeat
                    IsHandled := false;
                    OnRevertPostedItemTrackingOnBeforeGetTrackingSpecification(TempItemLedgEntry, IsHandled);
                    if not IsHandled then begin
                        TrackingSpecification.Get(TempItemLedgEntry."Entry No.");
                        QtyToRevert := TrackingSpecification."Quantity Invoiced (Base)";

                        IsHandled := false;
                        OnRevertPostedItemTrackingOnBeforeUpdateReservEntry(TempItemLedgEntry, TrackingSpecification, IsHandled);
                        if not IsHandled then
                            if not TrackingIsATO(TrackingSpecification) then begin
                                ReservEntry.Init();
                                ReservEntry.TransferFields(TrackingSpecification);
                                if RevertInvoiced then begin
                                    ReservEntry."Quantity (Base)" := QtyToRevert;
                                    ReservEntry."Quantity Invoiced (Base)" -= QtyToRevert;
                                end;
                                ReservEntry.Validate("Quantity (Base)");
                                ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus;
                                if ReservEntry.Positive then
                                    ReservEntry."Expected Receipt Date" := AvailabilityDate
                                else
                                    ReservEntry."Shipment Date" := AvailabilityDate;

                                ReservEntry."Warranty Date" := 0D;
                                ReservEntry."Entry No." := 0;
                                ReservEntry.UpdateItemTracking();
                                OnRevertPostedItemTrackingOnBeforeReservEntryInsert(ReservEntry, TempItemLedgEntry);
                                ReservEntry.Insert();

                                TempReservEntry := ReservEntry;
                                TempReservEntry.Insert();
                            end;

                        if RevertInvoiced and (TrackingSpecification."Quantity (Base)" <> QtyToRevert) then begin
                            TrackingSpecification."Quantity (Base)" -= QtyToRevert;
                            TrackingSpecification."Quantity Handled (Base)" -= QtyToRevert;
                            TrackingSpecification."Quantity Invoiced (Base)" := 0;
                            TrackingSpecification."Buffer Value1" -= QtyToRevert;
                            TrackingSpecification.Modify();
                        end else
                            TrackingSpecification.Delete();
                    end;
                until TempItemLedgEntry.Next() = 0;
                ReservEngineMgt.UpdateOrderTracking(TempReservEntry);
            end;
        OnAfterRevertPostedItemTracking(TempReservEntry);
    end;

    procedure PostItemJnlLine(var ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlLine2: Record "Item Journal Line";
        PostJobConsumptionBeforePurch: Boolean;
        IsHandled: Boolean;
    begin
        Clear(ItemJnlLine2);
        ItemJnlLine2 := ItemJnlLine;

        if ItemJnlLine2."Job No." <> '' then begin
            IsHandled := false;
            OnPostItemJnlLineOnBeforePostItemJnlLineForJob(ItemJnlLine2, IsHandled, ItemJnlLine, PostJobConsumptionBeforePurch);
            if not IsHandled then
                PostJobConsumptionBeforePurch := PostItemJnlLineForJob(ItemJnlLine, ItemJnlLine2);
        end;

        ItemJnlPostLine.Run(ItemJnlLine);

        IsHandled := false;
        OnPostItemJnlLineOnBeforePostJobConsumption(ItemJnlLine2, IsHandled);
        if not IsHandled then
            if ItemJnlLine2."Job No." <> '' then
                if not PostJobConsumptionBeforePurch then begin
                    SetItemJnlLineAppliesToEntry(ItemJnlLine2, ItemJnlLine."Item Shpt. Entry No.");
                    ItemJnlPostLine.Run(ItemJnlLine2);
                end;
    end;

    local procedure PostItemJnlLineForJob(var ItemJnlLine: Record "Item Journal Line"; var ItemJnlLine2: Record "Item Journal Line"): Boolean
    var
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostItemJnlLineForJob(ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ItemJnlLine2."Entry Type" := ItemJnlLine2."Entry Type"::"Negative Adjmt.";
        Job.Get(ItemJnlLine2."Job No.");
        ItemJnlLine2."Source No." := Job."Bill-to Customer No.";
        ItemJnlLine2."Source Type" := ItemJnlLine2."Source Type"::Customer;
        ItemJnlLine2."Discount Amount" := 0;
        if ItemJnlLine2.IsPurchaseReturn() then begin
            ItemJnlPostLine.Run(ItemJnlLine2);
            SetItemJnlLineAppliesToEntry(ItemJnlLine, ItemJnlLine2."Item Shpt. Entry No.");
            exit(true);
        end;
        exit(false);
    end;

    local procedure SetItemJnlLineAppliesToEntry(var ItemJnlLine: Record "Item Journal Line"; AppliesToEntry: Integer)
    var
        Item: Record Item;
    begin
        Item.Get(ItemJnlLine."Item No.");
        if Item.Type = Item.Type::Inventory then
            ItemJnlLine."Applies-to Entry" := AppliesToEntry;
    end;

    local procedure TrackingIsATO(TrackingSpecification: Record "Tracking Specification"): Boolean
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        if TrackingSpecification."Source Type" <> DATABASE::"Sales Line" then
            exit(false);
        if not TrackingSpecification."Prohibit Cancellation" then
            exit(false);

        ATOLink.SetRange(Type, ATOLink.Type::Sale);
        ATOLink.SetRange("Document Type", TrackingSpecification."Source Subtype");
        ATOLink.SetRange("Document No.", TrackingSpecification."Source ID");
        ATOLink.SetRange("Document Line No.", TrackingSpecification."Source Ref. No.");
        exit(not ATOLink.IsEmpty());
    end;

    procedure TransferSourceValues(var ItemJnlLine: Record "Item Journal Line"; EntryNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        ItemLedgEntry.Get(EntryNo);
        ItemJnlLine."Source Type" := ItemLedgEntry."Source Type";
        ItemJnlLine."Source No." := ItemLedgEntry."Source No.";
        ItemJnlLine."Country/Region Code" := ItemLedgEntry."Country/Region Code";

        ValueEntry.SetRange("Item Ledger Entry No.", EntryNo);
        ValueEntry.FindFirst();
        ItemJnlLine."Source Posting Group" := ValueEntry."Source Posting Group";
        ItemJnlLine."Salespers./Purch. Code" := ValueEntry."Salespers./Purch. Code";
    end;

    procedure ReapplyJobConsumption(ItemRcptEntryNo: Integer)
    var
        ItemApplnEntry: Record "Item Application Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReapplyJobConsumption(ItemRcptEntryNo, IsHandled);
        if IsHandled then
            exit;

        // Purchase receipt and job consumption are reapplied with with fixed cost application
        FindItemReceiptApplication(ItemApplnEntry, ItemRcptEntryNo);
        ItemJnlPostLine.UnApply(ItemApplnEntry);
        ItemLedgEntry.Get(ItemApplnEntry."Inbound Item Entry No.");
        ItemJnlPostLine.ReApply(ItemLedgEntry, ItemApplnEntry."Outbound Item Entry No.");
    end;

    procedure FindItemReceiptApplication(var ItemApplnEntry: Record "Item Application Entry"; ItemRcptEntryNo: Integer)
    begin
        ItemApplnEntry.Reset();
        ItemApplnEntry.SetRange("Inbound Item Entry No.", ItemRcptEntryNo);
        ItemApplnEntry.SetFilter("Item Ledger Entry No.", '<>%1', ItemRcptEntryNo);
        ItemApplnEntry.FindFirst();
    end;

    procedure FindItemShipmentApplication(var ItemApplnEntry: Record "Item Application Entry"; ItemShipmentEntryNo: Integer)
    begin
        ItemApplnEntry.Reset();
        ItemApplnEntry.SetRange("Item Ledger Entry No.", ItemShipmentEntryNo);
        ItemApplnEntry.FindFirst();
    end;

    procedure UpdatePurchaseLineOverRcptQty(PurchaseLine: Record "Purchase Line"; OverRcptQty: Decimal)
    begin
        PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine."Over-Receipt Quantity" += OverRcptQty;
        PurchaseLine.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRevertPostedItemTracking(var TempReservEntry: Record "Reservation Entry" temporary)
    begin
    end;

    procedure UpdateWarehouseRequest(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetSourceFilter(SourceType, SourceSubtype, SourceNo);
        WarehouseRequest.SetRange("Location Code", LocationCode);
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.ModifyAll("Completely Handled", false);
    end;

    local procedure Maximum(A: Decimal; B: Decimal): Decimal
    begin
        if A < B then
            exit(B);

        exit(A);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTransLine(var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSalesLine(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePurchline(var PurchLine: Record "Purchase Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterUpdateServLine(var ServLine: Record Microsoft.Service.Document."Service Line")
    begin
        OnAfterUpdateServLine(ServLine);
    end;

    [Obsolete('Moved to codeunit Serv. Undo Posting Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateServLine(var ServLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustQuantityRounding(var ItemJnlLine: Record "Item Journal Line"; var NonDistrQuantity: Decimal; NonDistrQuantityBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMissingItemLedgers(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SourceType: Integer; DocumentNo: Code[20]; LineNo: Integer; BaseQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemLedgEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; LineRef: Integer; InvoicedEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckValueEntries(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; LineRef: Integer; InvoicedEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLineForJob(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLineAppliedToList(ItemJnlLine: Record "Item Journal Line"; var TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary; UndoQty: Decimal; UndoQtyBase: Decimal; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempItemEntryRelation: Record "Item Entry Relation" temporary; InvoicedEntry: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReapplyJobConsumption(ItemRcptEntryNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRevertPostedItemTracking(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; AvailabilityDate: Date; RevertInvoiced: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRevertPostedItemTrackingFromPurchLine(PurchLine: Record "Purchase Line"; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchLineReserveVerifyQuantity(PurchLine: Record "Purchase Line"; xPurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRevertPostedItemTrackingFromSalesLine(SalesLine: Record "Sales Line"; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineReserveVerifyQuantity(SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeRevertPostedItemTrackingFromServiceLine(ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
        OnBeforeRevertPostedItemTrackingFromServiceLine(ServiceLine, TempUndoneItemLedgEntry, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Undo Posting Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRevertPostedItemTrackingFromServiceLine(ServiceLine: Record Microsoft.Service.Document."Service Line"; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeServiceLineReserveVerifyQuantity(ServiceLine: Record Microsoft.Service.Document."Service Line"; xServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
        OnBeforeServiceLineReserveVerifyQuantity(ServiceLine, xServiceLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Undo Posting Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineReserveVerifyQuantity(ServiceLine: Record Microsoft.Service.Document."Service Line"; xServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnBeforeServiceLineCnsmReserveVerifyQuantity(ServiceLine: Record Microsoft.Service.Document."Service Line"; xServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
        OnBeforeServiceLineCnsmReserveVerifyQuantity(ServiceLine, xServiceLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Undo Posting Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineCnsmReserveVerifyQuantity(ServiceLine: Record Microsoft.Service.Document."Service Line"; xServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestAllTransactions(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestTransferShptLine(var TransferShipmentLine: Record "Transfer Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPostedInvtPickLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean; UndoType: Integer; UndoID: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPostedInvtPutAwayLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean; UndoType: Integer; UndoID: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestPostedWhseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean; UndoType: Integer; UndoID: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestRgstrdWhseActivityLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseActivityLine(UndoType: Option; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseEntry(UndoLineNo: Integer; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseReceiptLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseShipmentLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWhseWorksheetLine(UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUndoValuePostingFromJob(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemLedgEntriesOnBeforeCheckTempItemLedgEntry(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineAppliedToListOnBeforeTempItemEntryRelationInsert(var TempItemEntryRelation: Record "Item Entry Relation" temporary; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineAppliedToListOnAfterPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineAppliedToListOnAfterSetInvoicedQty(var ItemJournalLine: Record "Item Journal Line"; TempApplyToItemLedgEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnBeforeInitOustanding(var SalesLine: Record "Sales Line"; var UndoQty: Decimal; var UndoQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforePostJobConsumption(var ItemJnlLine2: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostItemJnlLineOnBeforePostItemJnlLineForJob(var ItemJnlLine2: Record "Item Journal Line"; var IsHandled: Boolean; var ItemJnlLine: Record "Item Journal Line"; var PostJobConsumptionBeforePurch: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestWarehouseActivityLine2(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRevertPostedItemTrackingOnBeforeReservEntryInsert(var ReservationEntry: Record "Reservation Entry"; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestWarehouseEntryOnAfterSetFilters(var WarehouseEntry: Record "Warehouse Entry"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLineOnAfterSetQtyToShip(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLineOnAfterSetQtyToReceive(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdatePurchLineOnBeforePurchLineModify(var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnBeforeSalesLineModify(var SalesLine: Record "Sales Line")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeUpdateServLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var UndoQty: Decimal; var UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
        OnBeforeUpdateServLine(ServiceLine, UndoQty, UndoQtyBase, TempUndoneItemLedgEntry, IsHandled);
    end;

    [Obsolete('Moved to codeunit Serv. Undo Posting Mgt.', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateServLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var UndoQty: Decimal; var UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePurchLine(PurchaseLine: Record "Purchase Line"; var UndoQty: Decimal; var UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestAllTransactions(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTransLine(TransLine: Record "Transfer Line"; var UndoQty: Decimal; var UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSalesLine(SalesLine: Record "Sales Line"; var UndoQty: Decimal; var UndoQtyBase: Decimal; var TempUndoneItemLedgEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRevertPostedItemTrackingOnBeforeUpdateReservEntry(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TrackingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestAllTransactionsOnBeforeTestWarehouseActivityLine(UndoType: Integer; UndoID: Code[20]; UndoLineNo: Integer; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSalesLineOnAfterUpdateWithWarehouseShipForReturnOrder(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestRgstrdWhseActivityLine2(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShouldRevertBaseQtySign(SourceType: Integer; var RevertSign: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSkipTestWarehouseShipmentLine(UndoType: Integer; var SkipTest: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRevertPostedItemTrackingOnBeforeGetTrackingSpecification(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateDerivedTransferLineOnAfterTransferTracking(var TransferLine: Record "Transfer Line"; var TransferShipmentLine: Record "Transfer Shipment Line"; var DerivedTransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectOutputItemLedgEntriesForSubcontructingPurcReceiptLine(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; PurchRcptLine: Record "Purch. Rcpt. Line"; var Result: Boolean)
    begin
    end;
}
