// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Transfer;
using Microsoft.QualityManagement.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;

page 20480 "Qlty. Related Transfer Orders"
{
    ApplicationArea = QualityManagement;
    Caption = 'Quality Related Transfer Orders';
    PageType = List;
    Editable = false;
    SourceTable = "Qlty. Related Transfers Buffer";
    SourceTableTemporary = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("No."; Rec."Transfer Document No.")
                {
                    trigger OnDrillDown()
                    var
                        TransferHeader: Record "Transfer Header";
                        TransferShipmentHeader: Record "Transfer Shipment Header";
                        TransferReceiptHeader: Record "Transfer Receipt Header";
                        DirectTransHeader: Record "Direct Trans. Header";
                    begin
                        case Rec."Table No." of
                            Database::"Transfer Header":
                                begin
                                    TransferHeader.Get(Rec."Transfer Document No.");
                                    Page.Run(Page::"Transfer Order", TransferHeader);
                                end;
                            Database::"Direct Trans. Header":
                                begin
                                    DirectTransHeader.Get(Rec."Transfer Document No.");
                                    Page.Run(Page::"Posted Direct Transfer", DirectTransHeader);
                                end;
                            Database::"Transfer Shipment Header":
                                begin
                                    TransferShipmentHeader.Get(Rec."Transfer Document No.");
                                    Page.Run(Page::"Posted Transfer Shipment", TransferShipmentHeader);
                                end;
                            Database::"Transfer Receipt Header":
                                begin
                                    TransferReceiptHeader.Get(Rec."Transfer Document No.");
                                    Page.Run(Page::"Posted Transfer Receipt", TransferReceiptHeader);
                                end;
                        end;
                    end;
                }
                field("Transfer Document Type"; Rec."Transfer Document Type")
                {
                }
                field("Transfer From"; Rec."Transfer-from Code")
                {
                }
                field("Transfer To"; Rec."Transfer-to Code")
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Posting Date"; Rec."Posting Date")
                {
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(OrderStatistics)
            {
                Visible = IsTransferOrder;
                Caption = 'Statistics';
                Image = Statistics;
                RunObject = Page "Transfer Statistics";
                RunPageLink = "No." = field("Transfer Document No.");
                ShortCutKey = 'F7';
                ToolTip = 'View statistical information about the transfer order, such as the quantity and total weight transferred.';
            }
            action(OrderComments)
            {
                Visible = IsTransferOrder;
                Caption = 'Comments';
                Image = ViewComments;
                RunObject = Page "Inventory Comment Sheet";
                RunPageLink = "Document Type" = const("Transfer Order"),
                                  "No." = field("Transfer Document No.");
                ToolTip = 'View or add comments for the record.';
            }
            action(ReceiptStatistics)
            {
                Visible = IsTransferReceipt;
                Caption = 'Statistics';
                Image = Statistics;
                RunObject = Page "Transfer Receipt Statistics";
                RunPageLink = "No." = field("Transfer Document No.");
                ShortCutKey = 'F7';
                ToolTip = 'View statistical information about the transfer order, such as the quantity and total weight transferred.';
            }
            action(ReceiptComments)
            {
                Visible = IsTransferReceipt;
                Caption = 'Comments';
                Image = ViewComments;
                RunObject = Page "Inventory Comment Sheet";
                RunPageLink = "Document Type" = const("Posted Transfer Receipt"),
                                  "No." = field("Transfer Document No.");
                ToolTip = 'View or add comments for the record.';
            }
            action(ShipmentStatistics)
            {
                Visible = IsDirectTransfer or IsTransferShipment;
                Caption = 'Statistics';
                Image = Statistics;
                RunObject = Page "Transfer Shipment Statistics";
                RunPageLink = "No." = field("Transfer Document No.");
                ShortCutKey = 'F7';
                ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
            }
            action(ShipmentComments)
            {
                Visible = IsDirectTransfer or IsTransferShipment;
                Caption = 'Comments';
                Image = ViewComments;
                RunObject = Page "Inventory Comment Sheet";
                RunPageLink = "Document Type" = const("Posted Transfer Shipment"),
                                  "No." = field("Transfer Document No.");
                ToolTip = 'View or add comments for the record.';
            }
            action(Dimensions)
            {
                AccessByPermission = tabledata Dimension = R;
                Caption = 'Dimensions';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                trigger OnAction()
                var
                    TransferHeader: Record "Transfer Header";
                    TransferShipmentHeader: Record "Transfer Shipment Header";
                    TransferReceiptHeader: Record "Transfer Receipt Header";
                    DirectTransHeader: Record "Direct Trans. Header";
                begin
                    case Rec."Transfer Document Type" of
                        Rec."Transfer Document Type"::"Transfer Order":
                            if TransferHeader.Get(Rec."Transfer Document No.") then
                                TransferHeader.ShowDocDim();
                        Rec."Transfer Document Type"::"Transfer Shipment":
                            if TransferShipmentHeader.Get(Rec."Transfer Document No.") then
                                TransferShipmentHeader.ShowDimensions();
                        Rec."Transfer Document Type"::"Transfer Receipt":
                            if TransferReceiptHeader.Get(Rec."Transfer Document No.") then
                                TransferReceiptHeader.ShowDimensions();
                        Rec."Transfer Document Type"::"Direct Transfer":
                            if DirectTransHeader.Get(Rec."Transfer Document No.") then
                                DirectTransHeader.ShowDimensions();
                    end;
                end;
            }
            group(OrderDocuments)
            {
                Caption = 'Documents';
                Image = Documents;

                action(Shipments)
                {
                    Visible = IsTransferOrder;
                    Caption = 'Shipments';
                    Image = PostedShipment;
                    RunObject = Page "Posted Transfer Shipments";
                    RunPageLink = "Transfer Order No." = field("Transfer Document No.");
                    ToolTip = 'View related posted transfer shipments.';
                }
                action(Receipts)
                {
                    Visible = IsTransferOrder;
                    Caption = 'Receipts';
                    Image = PostedReceipts;
                    RunObject = Page "Posted Transfer Receipts";
                    RunPageLink = "Transfer Order No." = field("Transfer Document No.");
                    ToolTip = 'View related posted transfer receipts.';
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;

                action("Whse. Shipments")
                {
                    Visible = IsTransferOrder;
                    Caption = 'Whse. Shipments';
                    Image = Shipment;
                    RunObject = Page "Whse. Shipment Lines";
                    RunPageLink = "Source Type" = const(5741),
                                  "Source Subtype" = const("0"),
                                  "Source No." = field("Transfer Document No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View outbound items that have been shipped with warehouse activities for the transfer order.';
                }
                action("Whse. Receipts")
                {
                    Visible = IsTransferOrder;
                    Caption = 'Whse. Receipts';
                    Image = Receipt;
                    RunObject = Page "Whse. Receipt Lines";
                    RunPageLink = "Source Type" = const(5741),
                                  "Source Subtype" = const("1"),
                                  "Source No." = field("Transfer Document No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View inbound items that have been received with warehouse activities for the transfer order.';
                }
                action("Invt. Put-away/Pick Lines")
                {
                    Visible = IsTransferOrder;
                    Caption = 'Invt. Put-away/Pick Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity List";
                    RunPageLink = "Source Document" = filter("Inbound Transfer" | "Outbound Transfer"),
                                  "Source No." = field("Transfer Document No.");
                    RunPageView = sorting("Source Document", "Source No.", "Location Code");
                    ToolTip = 'View items that are inbound or outbound on inventory put-away or inventory pick documents for the transfer order.';
                }
                action("Whse. Put-away/Pick Lines")
                {
                    Visible = IsTransferOrder;
                    Caption = 'Warehouse Put-away/Pick Lines';
                    Image = PutawayLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Source Document" = filter("Inbound Transfer" | "Outbound Transfer"), "Source No." = field("Transfer Document No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.");
                    ToolTip = 'View items that are inbound or outbound on warehouse put-away or warehouse pick documents for the transfer order.';
                }
                action("Transfer Routes")
                {
                    Caption = 'Transfer Routes';
                    Image = Setup;
                    RunObject = Page "Transfer Routes";
                    ToolTip = 'View the list of transfer routes that are set up to transfer items from one location to another.';
                }
            }
        }
        area(Processing)
        {
            action(Print)
            {
                Caption = 'Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    TransferHeader: Record "Transfer Header";
                    TransferShipmentHeader: Record "Transfer Shipment Header";
                    TransferReceiptHeader: Record "Transfer Receipt Header";
                    DirectTransHeader: Record "Direct Trans. Header";
                    DocumentPrint: Codeunit "Document-Print";
                begin
                    case Rec."Transfer Document Type" of
                        Rec."Transfer Document Type"::"Transfer Order":
                            if TransferHeader.Get(Rec."Transfer Document No.") then
                                DocumentPrint.PrintTransferHeader(TransferHeader);
                        Rec."Transfer Document Type"::"Transfer Shipment":
                            if TransferShipmentHeader.Get(Rec."Transfer Document No.") then
                                TransferShipmentHeader.PrintRecords(true);
                        Rec."Transfer Document Type"::"Transfer Receipt":
                            if TransferReceiptHeader.Get(Rec."Transfer Document No.") then
                                TransferReceiptHeader.PrintRecords(true);
                        Rec."Transfer Document Type"::"Direct Transfer":
                            if DirectTransHeader.Get(Rec."Transfer Document No.") then
                                DirectTransHeader.PrintRecords(true);
                    end;
                end;
            }
            action(Navigate)
            {
                Visible = not IsTransferOrder;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                var
                    TransferShipmentHeader: Record "Transfer Shipment Header";
                    TransferReceiptHeader: Record "Transfer Receipt Header";
                    DirectTransHeader: Record "Direct Trans. Header";
                begin
                    case Rec."Transfer Document Type" of
                        Rec."Transfer Document Type"::"Transfer Shipment":
                            if TransferShipmentHeader.Get(Rec."Transfer Document No.") then
                                TransferShipmentHeader.Navigate();
                        Rec."Transfer Document Type"::"Transfer Receipt":
                            if TransferReceiptHeader.Get(Rec."Transfer Document No.") then
                                TransferReceiptHeader.Navigate();
                        Rec."Transfer Document Type"::"Direct Transfer":
                            if DirectTransHeader.Get(Rec."Transfer Document No.") then
                                DirectTransHeader.Navigate();
                    end;
                end;
            }
        }
        area(Reporting)
        {
            action("Inventory - Inbound Transfer")
            {
                ApplicationArea = Location;
                Caption = 'Inventory - Inbound Transfer';
                Image = Report;
                RunObject = Report "Inventory - Inbound Transfer";
                ToolTip = 'View which items are currently on inbound transfer orders.';
            }
        }
    }

    var
        InspectionNo: Code[20];
        ReinspectionNo: Integer;
        IsTransferOrder: Boolean;
        IsTransferShipment: Boolean;
        IsTransferReceipt: Boolean;
        IsDirectTransfer: Boolean;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ReloadBuffer();
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    begin
        case Rec."Transfer Document Type" of
            Rec."Transfer Document Type"::"Transfer Order":
                begin
                    IsTransferOrder := true;
                    IsDirectTransfer := false;
                    IsTransferShipment := false;
                    IsTransferReceipt := false;
                end;
            Rec."Transfer Document Type"::"Transfer Shipment":
                begin
                    IsTransferOrder := false;
                    IsDirectTransfer := false;
                    IsTransferShipment := true;
                    IsTransferReceipt := false;
                end;
            Rec."Transfer Document Type"::"Direct Transfer":
                begin
                    IsTransferOrder := false;
                    IsDirectTransfer := true;
                    IsTransferShipment := false;
                    IsTransferReceipt := false;
                end;
            Rec."Transfer Document Type"::"Transfer Receipt":
                begin
                    IsTransferOrder := false;
                    IsDirectTransfer := false;
                    IsTransferShipment := false;
                    IsTransferReceipt := true;
                end;
        end;
    end;

    /// <summary>
    /// Initializes the page with the provided Quality Inspection
    /// </summary>
    /// <param name="QltyInspectionHeader"></param>
    procedure InitializeWithInspection(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        InspectionNo := QltyInspectionHeader."No.";
        ReinspectionNo := QltyInspectionHeader."Re-inspection No.";
    end;

    local procedure ReloadBuffer()
    var
        LastBufferEntryNo: Integer;
    begin
        ClearBuffer(LastBufferEntryNo);

        PopulateBuffer_TransferHeader(LastBufferEntryNo);
        PopulateBuffer_TransferShipmentHeader(LastBufferEntryNo);
        PopulateBuffer_TransferReceiptHeader(LastBufferEntryNo);
        PopulateBuffer_DirectTransferHeader(LastBufferEntryNo);
    end;

    local procedure ClearBuffer(var LastBufferEntryNo: Integer)
    begin
        Rec.DeleteAll();
        LastBufferEntryNo := 0;
    end;

    local procedure PopulateBuffer_TransferHeader(var LastBufferEntryNo: Integer)
    var
        TransferHeader: Record "Transfer Header";
        QltyTransferBufferStatus: Enum "Qlty. Transfer Buffer Status";
    begin
        TransferHeader.SetLoadFields(Status, "Transfer-from Code", "Transfer-to Code", "Posting Date");
        TransferHeader.SetRange("Qlty. Inspection No.", InspectionNo);
        TransferHeader.SetRange("Qlty. Re-inspection No.", ReinspectionNo);
        if TransferHeader.FindSet() then
            repeat
                if TransferHeader.Status = TransferHeader.Status::Open then
                    QltyTransferBufferStatus := QltyTransferBufferStatus::Open
                else
                    QltyTransferBufferStatus := QltyTransferBufferStatus::Released;

                AddToBuffer(TransferHeader."No.",
                    Database::"Transfer Header",
                    QltyTransferBufferStatus,
                    TransferHeader."Transfer-from Code",
                    TransferHeader."Transfer-to Code",
                    TransferHeader."Posting Date",
                    LastBufferEntryNo);
            until TransferHeader.Next() = 0;
    end;

    local procedure PopulateBuffer_TransferShipmentHeader(var LastBufferEntryNo: Integer)
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        QltyTransferBufferStatus: Enum "Qlty. Transfer Buffer Status";
    begin
        TransferShipmentHeader.SetLoadFields("Transfer-from Code", "Transfer-to Code", "Posting Date");
        TransferShipmentHeader.SetRange("Qlty. Inspection No.", InspectionNo);
        TransferShipmentHeader.SetRange("Qlty. Re-inspection No.", ReinspectionNo);
        if TransferShipmentHeader.FindSet() then
            repeat
                AddToBuffer(TransferShipmentHeader."No.",
                    Database::"Transfer Shipment Header",
                    QltyTransferBufferStatus::Posted,
                    TransferShipmentHeader."Transfer-from Code",
                    TransferShipmentHeader."Transfer-to Code",
                    TransferShipmentHeader."Posting Date",
                    LastBufferEntryNo);
            until TransferShipmentHeader.Next() = 0;
    end;

    local procedure PopulateBuffer_TransferReceiptHeader(var LastBufferEntryNo: Integer)
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        QltyTransferBufferStatus: Enum "Qlty. Transfer Buffer Status";
    begin
        TransferReceiptHeader.SetLoadFields("Transfer-from Code", "Transfer-to Code", "Posting Date");
        TransferReceiptHeader.SetRange("Qlty. Inspection No.", InspectionNo);
        TransferReceiptHeader.SetRange("Qlty. Re-inspection No.", ReinspectionNo);
        if TransferReceiptHeader.FindSet() then
            repeat
                AddToBuffer(TransferReceiptHeader."No.",
                    Database::"Transfer Receipt Header",
                    QltyTransferBufferStatus::Posted,
                    TransferReceiptHeader."Transfer-from Code",
                    TransferReceiptHeader."Transfer-to Code",
                    TransferReceiptHeader."Posting Date",
                    LastBufferEntryNo);
            until TransferReceiptHeader.Next() = 0;
    end;

    local procedure PopulateBuffer_DirectTransferHeader(var LastBufferEntryNo: Integer)
    var
        DirectTransHeader: Record "Direct Trans. Header";
        QltyTransferBufferStatus: Enum "Qlty. Transfer Buffer Status";
    begin
        DirectTransHeader.SetLoadFields("Transfer-from Code", "Transfer-to Code", "Posting Date");
        DirectTransHeader.SetRange("Qlty. Inspection No.", InspectionNo);
        DirectTransHeader.SetRange("Qlty. Re-inspection No.", ReinspectionNo);
        if DirectTransHeader.FindSet() then
            repeat
                AddToBuffer(DirectTransHeader."No.",
                    Database::"Direct Trans. Header",
                    QltyTransferBufferStatus::Posted,
                    DirectTransHeader."Transfer-from Code",
                    DirectTransHeader."Transfer-to Code",
                    DirectTransHeader."Posting Date",
                    LastBufferEntryNo);
            until DirectTransHeader.Next() = 0;
    end;

    local procedure AddToBuffer(DocumentNoToAdd: Code[20]; TableNoToAdd: Integer; QltyTransferBufferStatusToAdd: Enum "Qlty. Transfer Buffer Status"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; PostingDate: Date; var LastBufferEntryNo: Integer)
    begin
        LastBufferEntryNo += 1;

        Clear(Rec);
        Rec."Buffer Entry No." := LastBufferEntryNo;
        Rec."Transfer Document No." := DocumentNoToAdd;
        Rec."Table No." := TableNoToAdd;
        case Rec."Table No." of
            Database::"Transfer Header":
                Rec."Transfer Document Type" := Rec."Transfer Document Type"::"Transfer Order";
            Database::"Transfer Shipment Header":
                Rec."Transfer Document Type" := Rec."Transfer Document Type"::"Transfer Shipment";
            Database::"Transfer Receipt Header":
                Rec."Transfer Document Type" := Rec."Transfer Document Type"::"Transfer Receipt";
            Database::"Direct Trans. Header":
                Rec."Transfer Document Type" := Rec."Transfer Document Type"::"Direct Transfer";
        end;
        Rec.Status := QltyTransferBufferStatusToAdd;
        Rec."Transfer-from Code" := FromLocationCode;
        Rec."Transfer-to Code" := ToLocationCode;
        Rec."Posting Date" := PostingDate;
        Rec.Insert();
    end;
}
