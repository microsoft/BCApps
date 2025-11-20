// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Setup;

report 5753 "Get Source Documents"
{
    Caption = 'Get Source Documents';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Warehouse Request"; "Warehouse Request")
        {
            DataItemTableView = where("Document Status" = const(Released), "Completely Handled" = filter(false));
            RequestFilterFields = "Source Document", "Source No.";
            dataitem("Sales Header"; "Sales Header")
            {
                DataItemLink = "Document Type" = field("Source Subtype"), "No." = field("Source No.");
                DataItemTableView = sorting("Document Type", "No.");
                dataitem("Sales Line"; "Sales Line")
                {
                    DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        SalesWarehouseMgt: Codeunit "Sales Warehouse Mgt.";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeSalesLineOnAfterGetRecord("Sales Line", "Warehouse Request", RequestType, IsHandled, SkipBlockedItem);
                        if IsHandled then
                            CurrReport.Skip();

                        VerifySalesItemNotBlocked("Sales Header", "Sales Line");
                        if not SkipWarehouseRequest("Sales Line", "Warehouse Request") then
                            case RequestType of
                                RequestType::Receive:
                                    if SalesWarehouseMgt.CheckIfSalesLine2ReceiptLine("Sales Line") then begin
                                        OnSalesLineOnAfterGetRecordOnBeforeCreateRcptHeader(
                                          "Sales Line", "Warehouse Request", WhseReceiptHeader, WhseHeaderCreated, OneHeaderCreated);
                                        if not OneHeaderCreated and not WhseHeaderCreated then begin
                                            CreateReceiptHeader();
                                            OnSalesLineOnAfterCreateRcptHeader(WhseReceiptHeader, WhseHeaderCreated, "Sales Header", "Sales Line", "Warehouse Request");
                                        end;
                                        if not SalesWarehouseMgt.SalesLine2ReceiptLine(WhseReceiptHeader, "Sales Line") then
                                            ErrorOccured := true;
                                        LineCreated := true;
                                    end;
                                RequestType::Ship:
                                    if SalesWarehouseMgt.CheckIfFromSalesLine2ShptLine("Sales Line", ReservedFromStock) then begin
                                        IsHandled := false;
                                        OnSalesLineOnAfterGetRecordOnBeforeCheckCustBlocked(Customer, IsHandled);
                                        if not IsHandled then
                                            if Customer.Blocked <> Customer.Blocked::" " then begin
                                                if not SalesHeaderCounted then begin
                                                    SkippedSourceDoc += 1;
                                                    SalesHeaderCounted := true;
                                                end;
                                                CurrReport.Skip();
                                            end;
                                        IsHandled := false;
                                        OnSalesLineOnAfterGetRecordOnBeforeCreateShptHeader(
                                          "Sales Line", "Warehouse Request", WhseShptHeader, WhseHeaderCreated, OneHeaderCreated, IsHandled, ErrorOccured, LineCreated);
                                        if not IsHandled then begin
                                            if not OneHeaderCreated and not WhseHeaderCreated then begin
                                                CreateShptHeader();
                                                WhseShptHeader."Shipment Date" := "Sales Header"."Shipment Date";
                                                WhseShptHeader.Modify();
                                                OnSalesLineOnAfterCreateShptHeader(WhseShptHeader, WhseHeaderCreated, "Sales Header", "Sales Line", "Warehouse Request");
                                            end;
                                            if not CreateActivityFromSalesLine2ShptLine(WhseShptHeader, "Sales Line") then
                                                ErrorOccured := true;
                                            LineCreated := true;
                                        end;
                                    end;
                            end;
                    end;

                    trigger OnPostDataItem()
                    var
                        ShouldUpdate: Boolean;
                    begin
                        ShouldUpdate := OneHeaderCreated or WhseHeaderCreated;
                        OnBeforeOnPostDataItemSalesLine(WhseReceiptHeader, RequestType, OneHeaderCreated, WhseHeaderCreated, LineCreated, HideDialog, ShouldUpdate);
                        if ShouldUpdate then begin
                            UpdateReceiptHeaderStatus();
                            CheckFillQtyToHandle();
                        end;

                        OnAfterProcessDocumentLine(WhseShptHeader, "Warehouse Request", LineCreated, WhseReceiptHeader, OneHeaderCreated, WhseHeaderCreated);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetSalesLineFilters("Sales Line", "Warehouse Request");

                        OnAfterSalesLineOnPreDataItem("Sales Line", OneHeaderCreated, WhseShptHeader, WhseReceiptHeader);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    SkipRecord: Boolean;
                    BreakReport: Boolean;
                    IsHandled: Boolean;
                begin
                    IsHandled := false;
                    OnBeforeSalesHeaderOnAfterGetRecord("Sales Header", SalesHeaderCounted, IsHandled);
                    if IsHandled then
                        CurrReport.Skip();

                    TestField("Sell-to Customer No.");
                    Customer.Get("Sell-to Customer No.");
                    if not SkipBlockedCustomer then
                        Customer.CheckBlockedCustOnDocs(Customer, "Document Type", false, false);
                    SalesHeaderCounted := false;

                    BreakReport := false;
                    SkipRecord := false;
                    OnAfterSalesHeaderOnAfterGetRecord("Sales Header", SkipRecord, BreakReport, "Warehouse Request");
                    if BreakReport then
                        CurrReport.Break();
                    if SkipRecord then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if "Warehouse Request"."Source Type" <> Database::"Sales Line" then
                        CurrReport.Break();

                    OnAfterSalesHeaderOnPreDataItem("Sales Header");
                end;

                trigger OnPostDataItem()
                begin
                    OnAfterPostDataItemSalesHeader("Warehouse Request", "Sales Header");
                end;
            }
            dataitem("Purchase Header"; "Purchase Header")
            {
                DataItemLink = "Document Type" = field("Source Subtype"), "No." = field("Source No.");
                DataItemTableView = sorting("Document Type", "No.");
                dataitem("Purchase Line"; "Purchase Line")
                {
                    DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                    DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        PurchasesWarehouseMgt: Codeunit "Purchases Warehouse Mgt.";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforePurchaseLineOnAfterGetRecord("Purchase Line", "Warehouse Request", RequestType, IsHandled, SkipBlockedItem);
                        if IsHandled then
                            CurrReport.Skip();

                        VerifyPurchaseItemNotBlocked("Purchase Header", "Purchase Line");
                        if "Purchase Line"."Document Type" in ["Purchase Line"."Document Type"::Order] then
                            "Purchase Line".TestPurchaseJobFields();
                        if "Location Code" = "Warehouse Request"."Location Code" then
                            case RequestType of
                                RequestType::Receive:
                                    if PurchasesWarehouseMgt.CheckIfPurchLine2ReceiptLine("Purchase Line") then begin
                                        OnPurchaseLineOnAfterGetRecordOnBeforeCreateRcptHeader(
                                          "Purchase Line", "Warehouse Request", WhseReceiptHeader, WhseHeaderCreated, OneHeaderCreated);
                                        if not OneHeaderCreated and not WhseHeaderCreated then begin
                                            CreateReceiptHeader();
                                            OnPurchaseLineOnAfterCreateRcptHeader(WhseReceiptHeader, WhseHeaderCreated, "Purchase Header", "Purchase Line", "Warehouse Request");
                                        end;
                                        if not PurchasesWarehouseMgt.PurchLine2ReceiptLine(WhseReceiptHeader, "Purchase Line") then
                                            ErrorOccured := true;
                                        LineCreated := true;
                                        OnPurchaseLineOnAfterGetRecordOnAfterCreateRcptHeader("Purchase Line", "Warehouse Request", WhseReceiptHeader, WhseHeaderCreated, OneHeaderCreated, ErrorOccured, LineCreated);
                                    end;
                                RequestType::Ship:
                                    if PurchasesWarehouseMgt.CheckIfFromPurchLine2ShptLine("Purchase Line", ReservedFromStock) then begin
                                        IsHandled := false;
                                        OnPurchaseLineOnAfterGetRecordOnBeforeCreateShptHeader(
                                          "Purchase Line", "Warehouse Request", WhseShptHeader, WhseHeaderCreated, OneHeaderCreated, IsHandled);
                                        if not IsHandled then begin
                                            if not OneHeaderCreated and not WhseHeaderCreated then begin
                                                CreateShptHeader();
                                                OnPurchaseLineOnAfterCreateShptHeader(WhseShptHeader, WhseHeaderCreated, "Purchase Header", "Purchase Line", "Warehouse Request");
                                            end;
                                            if not PurchasesWarehouseMgt.FromPurchLine2ShptLine(WhseShptHeader, "Purchase Line") then
                                                ErrorOccured := true;
                                            LineCreated := true;
                                        end;
                                    end;
                            end;
                    end;

                    trigger OnPostDataItem()
                    var
                        ShouldUpdate: Boolean;
                    begin
                        ShouldUpdate := OneHeaderCreated or WhseHeaderCreated;
                        OnBeforeOnPostDataItemPurchaseLine(WhseReceiptHeader, RequestType, OneHeaderCreated, WhseHeaderCreated, LineCreated, HideDialog, ShouldUpdate);
                        if ShouldUpdate then begin
                            UpdateReceiptHeaderStatus();
                            CheckFillQtyToHandle();
                        end;

                        OnAfterProcessDocumentLine(WhseShptHeader, "Warehouse Request", LineCreated, WhseReceiptHeader, OneHeaderCreated, WhseHeaderCreated);
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetPurchLineFilters("Purchase Line", "Warehouse Request");

                        OnAfterPurchaseLineOnPreDataItem("Purchase Line", OneHeaderCreated, WhseShptHeader, WhseReceiptHeader, RequestType);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    BreakReport: Boolean;
                    SkipRecord: Boolean;
                begin
                    BreakReport := false;
                    SkipRecord := false;
                    OnAfterPurchaseHeaderOnAfterGetRecord("Purchase Header", SkipRecord, BreakReport, "Warehouse Request", WhseReceiptHeader, OneHeaderCreated);
                    if BreakReport then
                        CurrReport.Break();
                    if SkipRecord then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if "Warehouse Request"."Source Type" <> Database::"Purchase Line" then
                        CurrReport.Break();

                    OnAfterOnPreDataItemPurchaseLine("Purchase Header");
                end;

                trigger OnPostDataItem()
                begin
                    OnAfterPostDataItemPurchaseHeader("Purchase Header", "Purchase Line", "Warehouse Request", WhseReceiptHeader);
                end;
            }
            dataitem("Transfer Header"; "Transfer Header")
            {
                DataItemLink = "No." = field("Source No.");
                DataItemTableView = sorting("No.");
                dataitem("Transfer Line"; "Transfer Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemTableView = sorting("Document No.", "Line No.");

                    trigger OnAfterGetRecord()
                    var
                        TransferWarehouseMgt: Codeunit "Transfer Warehouse Mgt.";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeTransferLineOnAfterGetRecord("Transfer Line", "Warehouse Request", RequestType, IsHandled);
                        if IsHandled then
                            CurrReport.Skip();

                        case RequestType of
                            RequestType::Receive:
                                if TransferWarehouseMgt.CheckIfTransLine2ReceiptLine("Transfer Line") then begin
                                    OnTransferLineOnAfterGetRecordOnBeforeCreateRcptHeader(
                                      "Transfer Line", "Warehouse Request", WhseReceiptHeader, WhseHeaderCreated, OneHeaderCreated);
                                    if not OneHeaderCreated and not WhseHeaderCreated then begin
                                        CreateReceiptHeader();
                                        OnTransferLineOnAfterCreateRcptHeader(WhseReceiptHeader, WhseHeaderCreated, "Transfer Header", "Transfer Line", "Warehouse Request");
                                    end;
                                    if not TransferWarehouseMgt.TransLine2ReceiptLine(WhseReceiptHeader, "Transfer Line") then
                                        ErrorOccured := true;
                                    LineCreated := true;
                                end;
                            RequestType::Ship:
                                if TransferWarehouseMgt.CheckIfFromTransLine2ShptLine("Transfer Line", ReservedFromStock) then begin
                                    IsHandled := false;
                                    OnTransferLineOnAfterGetRecordOnBeforeCreateShptHeader(
                                      "Transfer Line", "Warehouse Request", WhseShptHeader, WhseHeaderCreated, OneHeaderCreated, IsHandled);
                                    if not IsHandled then begin
                                        if not OneHeaderCreated and not WhseHeaderCreated then begin
                                            CreateShptHeader();
                                            OnTransferLineOnAfterCreateShptHeader(WhseShptHeader, WhseHeaderCreated, "Transfer Header", "Transfer Line");
                                        end;
                                        if not TransferWarehouseMgt.FromTransLine2ShptLine(WhseShptHeader, "Transfer Line") then
                                            ErrorOccured := true;
                                        LineCreated := true;
                                    end;
                                end;
                        end;
                    end;

                    trigger OnPostDataItem()
                    var
                        ShouldUpdate: Boolean;
                    begin
                        ShouldUpdate := OneHeaderCreated or WhseHeaderCreated;
                        OnBeforeOnPostDataItemTransferLine(WhseReceiptHeader, RequestType, OneHeaderCreated, WhseHeaderCreated, LineCreated, HideDialog, ShouldUpdate);
                        if ShouldUpdate then begin
                            UpdateReceiptHeaderStatus();
                            CheckFillQtyToHandle();
                        end;

                        OnAfterProcessDocumentLine(WhseShptHeader, "Warehouse Request", LineCreated, WhseReceiptHeader, OneHeaderCreated, WhseHeaderCreated);
                    end;

                    trigger OnPreDataItem()
                    begin
                        case "Warehouse Request"."Source Subtype" of
                            0:
                                SetFilter("Outstanding Quantity", '>0');
                            1:
                                SetFilter("Qty. in Transit", '>0');
                        end;

                        OnAfterTransferLineOnPreDataItem("Transfer Line", OneHeaderCreated, WhseShptHeader, WhseReceiptHeader);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    BreakReport: Boolean;
                    SkipRecord: Boolean;
                begin
                    BreakReport := false;
                    SkipRecord := false;
                    OnAfterTransHeaderOnAfterGetRecord("Transfer Header", SkipRecord, BreakReport, "Warehouse Request");
                    if BreakReport then
                        CurrReport.Break();
                    if SkipRecord then
                        CurrReport.Skip();
                end;

                trigger OnPreDataItem()
                begin
                    if "Warehouse Request"."Source Type" <> Database::"Transfer Line" then
                        CurrReport.Break();

                    OnAfterOnPreDataItemTransferLine("Transfer Header");
                end;
            }

            trigger OnAfterGetRecord()
            var
                WhseSetup: Record "Warehouse Setup";
                SkipRecord: Boolean;
                BreakReport: Boolean;
            begin
                WhseHeaderCreated := false;
                OnBeforeWarehouseRequestOnAfterGetRecord(
                  "Warehouse Request", WhseHeaderCreated, SkipRecord, BreakReport, RequestType, WhseReceiptHeader, WhseShptHeader, OneHeaderCreated);
                if BreakReport then
                    CurrReport.Break();
                if SkipRecord then
                    CurrReport.Skip();

                case Type of
                    Type::Inbound:
                        begin
                            if not Location.RequireReceive("Location Code") then begin
                                if "Location Code" = '' then
                                    WhseSetup.TestField("Require Receive");
                                Location.Get("Location Code");
                                Location.TestField("Require Receive");
                            end;
                            if not OneHeaderCreated then
                                RequestType := RequestType::Receive;
                        end;
                    Type::Outbound:
                        begin
                            if not Location.RequireShipment("Location Code") then begin
                                if "Location Code" = '' then
                                    WhseSetup.TestField("Require Shipment");
                                Location.Get("Location Code");
                                Location.TestField("Require Shipment");
                            end;
                            if not OneHeaderCreated then
                                RequestType := RequestType::Ship;
                        end;
                end;
            end;

            trigger OnPostDataItem()
            var
                IsHandled: Boolean;
            begin
                IsHandled := not (WhseHeaderCreated or OneHeaderCreated);
                OnBeforeCreateWhseDocuments(WhseReceiptHeader, WhseShptHeader, IsHandled, "Warehouse Request");
                if not IsHandled then begin
                    OnAfterCreateWhseDocuments(WhseReceiptHeader, WhseShptHeader, WhseHeaderCreated, "Warehouse Request");
                    WhseShptHeader.SortWhseDoc();
                    WhseReceiptHeader.SortWhseDoc();
                end;

                OnWarehouseRequestOnAfterOnPostDataItem(WhseShptHeader);
            end;

            trigger OnPreDataItem()
            begin
                if OneHeaderCreated then begin
                    case RequestType of
                        RequestType::Receive:
                            Type := Type::Inbound;
                        RequestType::Ship:
                            Type := Type::Outbound;
                    end;
                    SetRange(Type, Type);
                end;

                OnAfterWarehouseRequestOnPreDataItem("Warehouse Request", WhseReceiptHeader, OneHeaderCreated);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DoNotFillQtytoHandle; DoNotFillQuantityToHandle)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Do Not Fill Qty. to Handle';
                        ToolTip = 'Specifies if the Quantity to Handle field in the warehouse document is prefilled according to the source document quantities.';
                    }
                    field("Reserved From Stock"; ReservedFromStock)
                    {
                        ApplicationArea = Warehouse;
                        Caption = 'Reserved stock only';
                        ToolTip = 'Specifies if you want to include only source document lines that are fully or partially reserved from current stock.';
                        ValuesAllowed = " ", "Full and Partial", Full;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        OnBeforePostReport("Warehouse Request", RequestType, OneHeaderCreated, WhseShptHeader, WhseHeaderCreated, ErrorOccured, LineCreated, ActivitiesCreated, Location, WhseShptLine, WhseReceiptHeader, HideDialog, WhseReceiptLine);
        if not HideDialog then begin
            case RequestType of
                RequestType::Receive:
                    ShowReceiptDialog();
                RequestType::Ship:
                    ShowShipmentDialog();
            end;
            if SkippedSourceDoc > 0 then
                Message(CustomerIsBlockedMsg, SkippedSourceDoc);
        end;
        Completed := true;

        OnAfterPostReport("Warehouse Request", RequestType, OneHeaderCreated, WhseShptHeader, WhseHeaderCreated, ErrorOccured, LineCreated, ActivitiesCreated, Location, WhseShptLine);
    end;

    trigger OnPreReport()
    begin
        ActivitiesCreated := 0;
        LineCreated := false;
        WhseShptHeader.ClearMarks();
        WhseReceiptHeader.ClearMarks();
    end;

    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        Location: Record Location;
        ActivitiesCreated: Integer;
        Completed: Boolean;
        DoNotFillQuantityToHandle: Boolean;
        SalesHeaderCounted: Boolean;
        SkippedSourceDoc: Integer;
        SuppressCommit: Boolean;

        Text000Err: Label 'There are no warehouse receipt lines created.';
        Text001Msg: Label '%1 %2 has been created.', comment = '%1 = ActivitiesCreated %2 = WhseReceiptHeader.TableCaption() + SpecialHandlingMessage';
        Text002Msg: Label '%1 warehouse receipts have been created.', comment = '%1 = ActivitiesCreated + SpecialHandlingMessage';
        Text003Err: Label 'There are no warehouse shipment lines created.';
        Text004Msg: Label '%1 warehouse shipments have been created.', comment = '%1 = ActivitiesCreated + SpecialHandlingMessage';
        Text005Err: Label 'One or more of the lines on this %1 require special warehouse handling. The %2 for such lines has been set to blank.', comment = '%1 = WhseReceiptHeader.TableCaption, %2 = WhseReceiptLine.FieldCaption("Bin Code")';
        NoNewReceiptLinesForPurchaseOrderErr: Label 'This usually happens when warehouse receipt lines have already been created for a purchase order. Or if there were no changes to the purchase order quantities since you last created the warehouse receipt lines.';
        NoNewReceiptLinesForPurchaseReturnErr: Label 'This usually happens when warehouse receipt lines have already been created for a purchase return order. Or if there were no changes to the purchase return order quantities since you last created the warehouse receipt lines.';
        Text007Err: Label 'There are no new warehouse receipt lines to create';
        NoNewShipmentLinesForSalesOrderErr: Label 'This usually happens when warehouse shipment lines have already been created for a sales order. Or there were no changes to sales order quantities since you last created the warehouse shipment lines.';
        NoNewShipmentLinesForSalesReturnErr: Label 'This usually happens when warehouse shipment lines have already been created for a sales return order. Or there were no changes to sales return order quantities since you last created the warehouse shipment lines.';
        Text010Err: Label 'There are no new warehouse shipment lines to create';
        ShowOpenLinesTxt: Label 'Show open lines';
        CustomerIsBlockedMsg: Label '%1 source documents were not included because the customer is blocked.', Comment = '%1 = no. of source documents.';
        ShowOpenShipmentLinesTooltipTxt: Label 'Shows open warehouse shipment lines already created for this document.';
        ShowOpenReceiptLinesTooltipTxt: Label 'Shows open warehouse receipt lines already created for this document.';

    protected var
        Customer: Record Customer;
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseShptHeader: Record "Warehouse Shipment Header";
        ErrorOccured: Boolean;
        LineCreated: Boolean;
        OneHeaderCreated: Boolean;
        WhseHeaderCreated: Boolean;
        RequestType: Option Receive,Ship;
        SkipBlockedCustomer: Boolean;
        SkipBlockedItem: Boolean;
        HideDialog: Boolean;
        ReservedFromStock: Enum "Reservation From Stock";

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure SetOneCreatedShptHeader(WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        RequestType := RequestType::Ship;
        WhseShptHeader := WhseShptHeader2;
        if WhseShptHeader.Find() then
            OneHeaderCreated := true;
    end;

    procedure SetOneCreatedReceiptHeader(WhseReceiptHeader2: Record "Warehouse Receipt Header")
    begin
        RequestType := RequestType::Receive;
        WhseReceiptHeader := WhseReceiptHeader2;
        if WhseReceiptHeader.Find() then
            OneHeaderCreated := true;
    end;

    procedure SetDoNotFillQtytoHandle(DoNotFillQtytoHandleToSet: Boolean)
    begin
        DoNotFillQuantityToHandle := DoNotFillQtytoHandleToSet;
    end;

    procedure SetReservedFromStock(NewReservedFromStock: Enum "Reservation From Stock")
    begin
        ReservedFromStock := NewReservedFromStock;
    end;

    procedure SetSalesLineFilters(var SalesLine: Record "Sales Line"; WarehouseRequest: Record "Warehouse Request")
    begin
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if ((WarehouseRequest.Type = WarehouseRequest.Type::Outbound) and
            (WarehouseRequest."Source Document" = WarehouseRequest."Source Document"::"Sales Order")) or
            ((WarehouseRequest.Type = "Warehouse Request".Type::Inbound) and
            (WarehouseRequest."Source Document" = WarehouseRequest."Source Document"::"Sales Return Order"))
        then
            SalesLine.SetFilter("Outstanding Quantity", '>0')
        else
            SalesLine.SetFilter("Outstanding Quantity", '<0');
        SalesLine.SetRange("Drop Shipment", false);
        SalesLine.SetRange("Job No.", '');

        OnAfterSetSalesLineFilters(SalesLine, WarehouseRequest);
    end;

    procedure SetPurchLineFilters(var PurchLine: Record "Purchase Line"; WarehouseRequest: Record "Warehouse Request")
    begin
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        if ((WarehouseRequest.Type = WarehouseRequest.Type::Inbound) and (WarehouseRequest."Source Document" = WarehouseRequest."Source Document"::"Purchase Order")) or
           ((WarehouseRequest.Type = WarehouseRequest.Type::Outbound) and (WarehouseRequest."Source Document" = WarehouseRequest."Source Document"::"Purchase Return Order"))
        then
            PurchLine.SetFilter("Outstanding Quantity", '>0')
        else
            PurchLine.SetFilter("Outstanding Quantity", '<0');
        PurchLine.SetRange("Drop Shipment", false);
        if WarehouseRequest."Source Document" = WarehouseRequest."Source Document"::"Purchase Return Order" then
            PurchLine.SetRange("Job No.", '');

        OnAfterSetPurchLineFilters(PurchLine, WarehouseRequest);
    end;

    procedure GetLastShptHeader(var WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        RequestType := RequestType::Ship;
        WhseShptHeader2 := WhseShptHeader;
    end;

    procedure GetCreatedShptHeaders(var WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        RequestType := RequestType::Ship;
        WhseShptHeader2.Copy(WhseShptHeader);
    end;

    procedure GetLastReceiptHeader(var WhseReceiptHeader2: Record "Warehouse Receipt Header")
    begin
        RequestType := RequestType::Receive;
        WhseReceiptHeader2 := WhseReceiptHeader;
    end;

    procedure GetCreatedReceiptHeaders(var WhseReceiptHeader2: Record "Warehouse Receipt Header")
    begin
        RequestType := RequestType::Receive;
        WhseReceiptHeader2.Copy(WhseReceiptHeader);
    end;

    procedure NotCancelled(): Boolean
    begin
        exit(Completed);
    end;

    procedure CreateActivityFromSalesLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"): Boolean
    var
        SalesWarehouseMgt: Codeunit "Sales Warehouse Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateActivityFromSalesLine2ShptLine(WarehouseShipmentHeader, SalesLine, IsHandled);
        if IsHandled then
            exit(true);

        exit(SalesWarehouseMgt.FromSalesLine2ShptLine(WarehouseShipmentHeader, SalesLine));
    end;

    procedure CreateShptHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateShptHeader(WhseShptHeader, "Warehouse Request", "Sales Line", IsHandled, Location, WhseShptLine, ActivitiesCreated, WhseHeaderCreated, RequestType);
        if IsHandled then
            exit;

        WhseShptHeader.Init();
        WhseShptHeader."No." := '';
        WhseShptHeader."Location Code" := "Warehouse Request"."Location Code";
        if Location.Code = WhseShptHeader."Location Code" then
            WhseShptHeader."Bin Code" := Location."Shipment Bin Code";
        WhseShptHeader."External Document No." := "Warehouse Request"."External Document No.";
        WhseShptHeader."Shipment Method Code" := "Warehouse Request"."Shipment Method Code";
        WhseShptHeader."Shipping Agent Code" := "Warehouse Request"."Shipping Agent Code";
        WhseShptHeader."Shipping Agent Service Code" := "Warehouse Request"."Shipping Agent Service Code";
        WhseShptLine.LockTable();
        OnBeforeWhseShptHeaderInsert(WhseShptHeader, "Warehouse Request", "Sales Line", "Transfer Line", "Sales Header");
        WhseShptHeader.Insert(true);
        WhseShptHeader.Mark(true);
        ActivitiesCreated := ActivitiesCreated + 1;
        WhseHeaderCreated := true;

        OnAfterCreateShptHeader(WhseShptHeader, "Warehouse Request", "Sales Line", "Purchase Line");
    end;

    procedure CreateReceiptHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateRcptHeader(WhseReceiptHeader, "Warehouse Request", "Purchase Line", IsHandled, SuppressCommit);
        if IsHandled then
            exit;

        WhseReceiptHeader.Init();
        WhseReceiptHeader."No." := '';
        WhseReceiptHeader."Location Code" := "Warehouse Request"."Location Code";
        if Location.Code = WhseReceiptHeader."Location Code" then
            WhseReceiptHeader."Bin Code" := Location."Receipt Bin Code";
        WhseReceiptHeader."Vendor Shipment No." := "Warehouse Request"."External Document No.";
        WhseReceiptLine.LockTable();
        OnBeforeWhseReceiptHeaderInsert(WhseReceiptHeader, "Warehouse Request");
        WhseReceiptHeader.Insert(true);
        OnCreateReceiptHeaderOnAfterWhseReceiptHeaderInsert(WhseReceiptHeader, ActivitiesCreated, RequestType);
        WhseReceiptHeader.Mark(true);
        ActivitiesCreated := ActivitiesCreated + 1;
        WhseHeaderCreated := true;
        if not SuppressCommit then
            Commit();

        OnAfterCreateRcptHeader(WhseReceiptHeader, "Warehouse Request", "Purchase Line");
    end;

    local procedure UpdateReceiptHeaderStatus()
    begin
        OnBeforeUpdateReceiptHeaderStatus(WhseReceiptHeader);
        if WhseReceiptHeader."No." = '' then
            exit;
        WhseReceiptHeader.Validate("Document Status", WhseReceiptHeader.GetHeaderStatus(0));
        WhseReceiptHeader.Modify(true);
    end;

    procedure SetSkipBlocked(Skip: Boolean)
    begin
        SkipBlockedCustomer := Skip;
    end;

    procedure SetSkipBlockedItem(Skip: Boolean)
    begin
        SkipBlockedItem := Skip;
    end;

    procedure SkipWarehouseRequest(SalesLine: Record "Sales Line"; WarehouseRequest: Record "Warehouse Request") SkipLine: Boolean;
    begin
        SkipLine := SalesLine."Location Code" <> WarehouseRequest."Location Code";
        OnAfterSkipWarehouseRequest(SalesLine, WarehouseRequest, SkipLine);
    end;

    local procedure VerifySalesItemNotBlocked(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeVerifySalesItemNotBlocked(SalesHeader, SalesLine, IsHandled, SkipBlockedItem);
        if not IsHandled then
            VerifyItemNotBlocked(SalesLine."No.", SalesLine."Variant Code");
    end;

    local procedure VerifyPurchaseItemNotBlocked(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeVerifyPurchaseItemNotBlocked(PurchaseHeader, PurchaseLine, SkipBlockedItem, IsHandled);
        if IsHandled then
            exit;

        VerifyItemNotBlocked(PurchaseLine."No.", PurchaseLine."Variant Code");
    end;

    local procedure VerifyItemNotBlocked(ItemNo: Code[20]; VariantCode: Code[10])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        Item.Get(ItemNo);
        if SkipBlockedItem and Item.Blocked then
            CurrReport.Skip();

        Item.TestField(Blocked, false);

        if VariantCode = '' then
            exit;
        ItemVariant.SetLoadFields(Blocked);
        ItemVariant.Get(ItemNo, VariantCode);
        if SkipBlockedItem and ItemVariant.Blocked then
            CurrReport.Skip();

        ItemVariant.TestField(Blocked, false);
    end;

    procedure ShowReceiptDialog()
    var
        SpecialHandlingMessage: Text[1024];
        IsHandled: Boolean;
        ErrorNoLinesToCreate: ErrorInfo;
    begin
        IsHandled := false;
        OnBeforeShowReceiptDialog(IsHandled, ErrorOccured, ActivitiesCreated, LineCreated);
        if IsHandled then
            exit;

        if not LineCreated then begin
            ErrorNoLinesToCreate.Title := Text007Err;
            if "Purchase Header"."Document Type" = "Purchase Header"."Document Type"::Order then
                ErrorNoLinesToCreate.Message := NoNewReceiptLinesForPurchaseOrderErr
            else
                ErrorNoLinesToCreate.Message := NoNewReceiptLinesForPurchaseReturnErr;
            ErrorNoLinesToCreate.PageNo := Page::"Whse. Receipt Lines";
            ErrorNoLinesToCreate.CustomDimensions.Add('Source Type', Format(Database::"Purchase Line"));
            ErrorNoLinesToCreate.CustomDimensions.Add('Source Subtype', Format("Purchase Header"."Document Type"));
            ErrorNoLinesToCreate.CustomDimensions.Add('Source No.', Format("Purchase Header"."No."));
            ErrorNoLinesToCreate.AddAction(ShowOpenLinesTxt, 5753, 'ReturnListofPurchaseReceipts', ShowOpenReceiptLinesTooltipTxt);
            WhseReceiptLine.SetRange("Source No.", "Purchase Header"."No.");
            if WhseReceiptLine.FindFirst() then begin
                ErrorNoLinesToCreate.RecordId(WhseReceiptLine.RecordId());
                Error(ErrorNoLinesToCreate);
            end else
                Error(Text000Err);
        end;

        if ErrorOccured then
            SpecialHandlingMessage :=
              ' ' + StrSubstNo(Text005Err, WhseReceiptHeader.TableCaption(), WhseReceiptLine.FieldCaption("Bin Code"));
        if (ActivitiesCreated = 0) and LineCreated and ErrorOccured then
            Message(SpecialHandlingMessage);
        if ActivitiesCreated = 1 then
            ShowSingleWhseReceiptHeaderCreatedMessage(SpecialHandlingMessage);
        if ActivitiesCreated > 1 then
            ShowMultipleWhseReceiptHeaderCreatedMessage(SpecialHandlingMessage);
    end;

    procedure ShowShipmentDialog()
    var
        SpecialHandlingMessage: Text[1024];
        ErrorNoLinesToCreate: ErrorInfo;
    begin
        if not LineCreated then begin
            ErrorNoLinesToCreate.Title := Text010Err;
            if "Sales Header"."Document Type" = "Sales Header"."Document Type"::Order then
                ErrorNoLinesToCreate.Message := NoNewShipmentLinesForSalesOrderErr
            else
                ErrorNoLinesToCreate.Message := NoNewShipmentLinesForSalesReturnErr;
            ErrorNoLinesToCreate.PageNo := Page::"Warehouse Shipment List";
            WhseShptLine.SetRange("Source No.", "Sales Header"."No.");
            ErrorNoLinesToCreate.CustomDimensions.Add('Source Type', Format(Database::"Sales Line"));
            ErrorNoLinesToCreate.CustomDimensions.Add('Source Subtype', Format("Sales Header"."Document Type"));
            ErrorNoLinesToCreate.CustomDimensions.Add('Source No.', Format("Sales Header"."No."));
            ErrorNoLinesToCreate.AddAction(ShowOpenLinesTxt, 5753, 'ReturnListofWhseShipments', ShowOpenShipmentLinesTooltipTxt);
            if WhseShptLine.FindFirst() then begin
                ErrorNoLinesToCreate.PageNo := Page::"Warehouse Shipment List";
                Error(ErrorNoLinesToCreate);
            end else
                Error(Text003Err);
        end;

        if ErrorOccured then
            SpecialHandlingMessage :=
              ' ' + StrSubstNo(Text005Err, WhseShptHeader.TableCaption(), WhseShptLine.FieldCaption("Bin Code"));
        if (ActivitiesCreated = 0) and LineCreated and ErrorOccured then
            Message(SpecialHandlingMessage);
        if ActivitiesCreated = 1 then
            ShowSingleWhseShptHeaderCreatedMessage(SpecialHandlingMessage);
        if ActivitiesCreated > 1 then
            ShowMultipleWhseShptHeaderCreatedMessage(SpecialHandlingMessage);
    end;

    local procedure CheckFillQtyToHandle()
    begin
        OnBeforeCheckFillQtyToHandle(DoNotFillQuantityToHandle, RequestType);

        if not DoNotFillQuantityToHandle then
            exit;

        case RequestType of
            RequestType::Receive:
                begin
                    WhseReceiptLine.Reset();
                    WhseReceiptLine.SetRange("No.", WhseReceiptHeader."No.");
                    WhseReceiptLine.DeleteQtyToReceive(WhseReceiptLine);
                end;
            RequestType::Ship:
                begin
                    WhseShptLine.Reset();
                    WhseShptLine.SetRange("No.", WhseShptHeader."No.");
                    WhseShptLine.DeleteQtyToHandle(WhseShptLine);
                end;
        end;
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure ShowSingleWhseReceiptHeaderCreatedMessage(SpecialHandlingMessage: Text[1024])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSingleWhseReceiptHeaderCreatedMessage(ActivitiesCreated, SpecialHandlingMessage, IsHandled);
        if IsHandled then
            exit;

        Message(StrSubstNo(Text001Msg, ActivitiesCreated, WhseReceiptHeader.TableCaption()) + SpecialHandlingMessage);
    end;

    local procedure ShowMultipleWhseReceiptHeaderCreatedMessage(SpecialHandlingMessage: Text[1024])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowMultipleWhseReceiptHeaderCreatedMessage(ActivitiesCreated, SpecialHandlingMessage, IsHandled);
        if IsHandled then
            exit;

        Message(StrSubstNo(Text002Msg, ActivitiesCreated) + SpecialHandlingMessage);
    end;

    local procedure ShowSingleWhseShptHeaderCreatedMessage(SpecialHandlingMessage: Text[1024])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowSingleWhseShptHeaderCreatedMessage(ActivitiesCreated, SpecialHandlingMessage, IsHandled);
        if IsHandled then
            exit;

        Message(StrSubstNo(Text001Msg, ActivitiesCreated, WhseShptHeader.TableCaption()) + SpecialHandlingMessage);
    end;

    local procedure ShowMultipleWhseShptHeaderCreatedMessage(SpecialHandlingMessage: Text[1024])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowMultipleWhseShptHeaderCreatedMessage(ActivitiesCreated, SpecialHandlingMessage, IsHandled);
        if IsHandled then
            exit;

        Message(StrSubstNo(Text004Msg, ActivitiesCreated) + SpecialHandlingMessage);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateRcptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; WarehouseRequest: Record "Warehouse Request"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WarehouseRequest: Record "Warehouse Request"; SalesLine: Record "Sales Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseDocuments(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseShipmentHeader: Record "Warehouse Shipment Header"; WhseHeaderCreated: Boolean; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreDataItemPurchaseLine(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreDataItemTransferLine(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessDocumentLine(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request"; var LineCreated: Boolean; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; OneHeaderCreated: Boolean; WhseHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesHeaderOnAfterGetRecord(SalesHeader: Record "Sales Header"; var SkipRecord: Boolean; var BreakReport: Boolean; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransHeaderOnAfterGetRecord(TransferHeader: Record "Transfer Header"; var SkipRecord: Boolean; var BreakReport: Boolean; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseHeaderOnAfterGetRecord(PurchaseHeader: Record "Purchase Header"; var SkipRecord: Boolean; var BreakReport: Boolean; var WarehouseRequest: Record "Warehouse Request"; var WhseReceiptHeader: Record "Warehouse Receipt Header"; OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesHeaderOnPreDataItem(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSalesLineOnPreDataItem(var SalesLine: Record "Sales Line"; OneHeaderCreated: Boolean; WhseShptHeader: Record "Warehouse Shipment Header"; WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSkipWarehouseRequest(SalesLine: Record "Sales Line"; WarehouseRequest: Record "Warehouse Request"; var SkipLine: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPurchaseLineOnPreDataItem(var PurchaseLine: Record "Purchase Line"; OneHeaderCreated: Boolean; WhseShptHeader: Record "Warehouse Shipment Header"; WhseReceiptHeader: Record "Warehouse Receipt Header"; RequestType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferLineOnPreDataItem(var TransferLine: Record "Transfer Line"; OneHeaderCreated: Boolean; WhseShptHeader: Record "Warehouse Shipment Header"; WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterWarehouseRequestOnPreDataItem(var WarehouseRequest: Record "Warehouse Request"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckFillQtyToHandle(var DoNotFillQtytoHandle: Boolean; var RequestType: Option);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateActivityFromSalesLine2ShptLine(WhseShptHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateRcptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseRequest: Record "Warehouse Request"; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean; var SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request"; SalesLine: Record "Sales Line"; var IsHandled: Boolean; Location: Record Location; var WhseShptLine: Record "Warehouse Shipment Line"; var ActivitiesCreated: Integer; var WhseHeaderCreated: Boolean; var RequestType: Option Receive,Ship)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseDocuments(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePurchaseLineOnAfterGetRecord(PurchaseLine: Record "Purchase Line"; WarehouseRequest: Record "Warehouse Request"; RequestType: Option; var IsHandled: Boolean; SkipBlockedItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderOnAfterGetRecord(var SalesHeader: Record "Sales Header"; var SalesHeaderCounted: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineOnAfterGetRecord(SalesLine: Record "Sales Line"; WarehouseRequest: Record "Warehouse Request"; RequestType: Option; var IsHandled: Boolean; SkipBlockedItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferLineOnAfterGetRecord(TransferLine: Record "Transfer Line"; WarehouseRequest: Record "Warehouse Request"; RequestType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyPurchaseItemNotBlocked(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; SkipBlockedItem: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifySalesItemNotBlocked(SalesHeaer: Record "Sales Header"; SalesLine: Record "Sales Line"; var IsHandled: Boolean; SkipBlockedItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarehouseRequestOnAfterGetRecord(var WarehouseRequest: Record "Warehouse Request"; var WhseHeaderCreated: Boolean; var SkipRecord: Boolean; var BreakReport: Boolean; RequestType: Option Receive,Ship; var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeWhseReceiptHeaderInsert(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShptHeaderInsert(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request"; SalesLine: Record "Sales Line"; TransferLine: Record "Transfer Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseLineOnAfterCreateRcptHeader(var WhseReceiptHeader: Record "Warehouse Receipt Header"; WhseHeaderCreated: Boolean; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; WarehouseRequest: Record "Warehouse Request");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseLineOnAfterCreateShptHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; WhseHeaderCreated: Boolean; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; WarehouseRequest: Record "Warehouse Request");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineOnAfterCreateRcptHeader(var WhseReceiptHeader: Record "Warehouse Receipt Header"; WhseHeaderCreated: Boolean; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; WarehouseRequest: Record "Warehouse Request");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineOnAfterCreateShptHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; WhseHeaderCreated: Boolean; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; WarehouseRequest: Record "Warehouse Request");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineOnAfterGetRecordOnBeforeCreateRcptHeader(SalesLine: Record "Sales Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnSalesLineOnAfterGetRecordOnBeforeCreateShptHeader(SalesLine: Record "Sales Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean; var IsHandled: Boolean; var ErrorOccured: Boolean; var LinesCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseLineOnAfterGetRecordOnBeforeCreateRcptHeader(PurchaseLine: Record "Purchase Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseLineOnAfterGetRecordOnBeforeCreateShptHeader(PurchaseLine: Record "Purchase Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchaseLineOnAfterGetRecordOnAfterCreateRcptHeader(var PurchaseLine: Record "Purchase Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean; var ErrorOccured: Boolean; var LineCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineOnAfterCreateRcptHeader(var WhseReceiptHeader: Record "Warehouse Receipt Header"; WhseHeaderCreated: Boolean; TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line"; WarehouseRequest: Record "Warehouse Request");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineOnAfterCreateShptHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; WhseHeaderCreated: Boolean; TransferHeader: Record "Transfer Header"; TransferLine: Record "Transfer Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineOnAfterGetRecordOnBeforeCreateRcptHeader(TransferLine: Record "Transfer Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferLineOnAfterGetRecordOnBeforeCreateShptHeader(TransferLine: Record "Transfer Line"; var WarehouseRequest: Record "Warehouse Request"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseHeaderCreated: Boolean; var OneHeaderCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostReport(WhseRequest: Record "Warehouse Request"; RequestType: Option; OneHeaderCreated: Boolean; var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseHeaderCreated: Boolean; var ErrorOccured: Boolean; var LineCreated: Boolean; var ActivitiesCreated: Integer; Location: record Location; var WhseShptLine: record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDataItemSalesHeader(WarehouseRequest: Record "Warehouse Request"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostDataItemPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var WarehouseRequest: Record "Warehouse Request"; var WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReceiptHeaderOnAfterWhseReceiptHeaderInsert(WhseReceiptHeader: Record "Warehouse Receipt Header"; ActivitiesCreated: Integer; var RequestType: Option Receive,Ship)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostReport(var WhseRequest: Record "Warehouse Request"; RequestType: Option; OneHeaderCreated: Boolean; var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseHeaderCreated: Boolean; var ErrorOccured: Boolean; var LineCreated: Boolean; var ActivitiesCreated: Integer; Location: record Location; var WhseShptLine: record "Warehouse Shipment Line"; var WhseReceiptHeader: Record "Warehouse Receipt Header"; var HideDialog: Boolean; var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReceiptDialog(var IsHandled: Boolean; ErrorOccured: Boolean; ActivitiesCreated: Integer; LineCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSingleWhseReceiptHeaderCreatedMessage(ActivitiesCreated: Integer; SpecialHandlingMessage: Text[1024]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMultipleWhseReceiptHeaderCreatedMessage(ActivitiesCreated: Integer; SpecialHandlingMessage: Text[1024]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSingleWhseShptHeaderCreatedMessage(ActivitiesCreated: Integer; SpecialHandlingMessage: Text[1024]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMultipleWhseShptHeaderCreatedMessage(ActivitiesCreated: Integer; SpecialHandlingMessage: Text[1024]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPostDataItemTransferLine(var WhseReceiptHeader: Record "Warehouse Receipt Header"; RequestType: Option Receive,Ship; OneHeaderCreated: Boolean; WhseHeaderCreated: Boolean; LineCreated: Boolean; HideDialog: Boolean; var ShouldUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReceiptHeaderStatus(var WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWarehouseRequestOnAfterOnPostDataItem(WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLineOnAfterGetRecordOnBeforeCheckCustBlocked(var Customer: Record Customer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPostDataItemSalesLine(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; RequestType: Option Receive,Ship; OneHeaderCreated: Boolean; WhseHeaderCreated: Boolean; LineCreated: Boolean; HideDialog: Boolean; var ShouldUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnPostDataItemPurchaseLine(var WhseReceiptHeader: Record "Warehouse Receipt Header"; RequestType: Option Receive,Ship; OneHeaderCreated: Boolean; WhseHeaderCreated: Boolean; LineCreated: Boolean; HideDialog: Boolean; var ShouldUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPurchLineFilters(var PurchaseLine: Record "Purchase Line"; WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSalesLineFilters(var SalesLine: Record "Sales Line"; WarehouseRequest: Record "Warehouse Request")
    begin
    end;
}

