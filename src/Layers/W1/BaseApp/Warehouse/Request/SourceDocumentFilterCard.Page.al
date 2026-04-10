// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Warehouse.Document;

page 5786 "Source Document Filter Card"
{
    Caption = 'Source Document Filter Card';
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Warehouse Source Filter";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Source No. Filter"; Rec."Source No. Filter")
                {
                    ApplicationArea = Warehouse;
                }
                field("Item No. Filter"; Rec."Item No. Filter")
                {
                    ApplicationArea = Warehouse;
                }
                field("Variant Code Filter"; Rec."Variant Code Filter")
                {
                    ApplicationArea = Planning;
                }
                field("Unit of Measure Filter"; Rec."Unit of Measure Filter")
                {
                    ApplicationArea = Warehouse;
                }
                field("Shipment Method Code Filter"; Rec."Shipment Method Code Filter")
                {
                    ApplicationArea = Warehouse;
                }
                field("Show Filter Request"; Rec."Show Filter Request")
                {
                    ApplicationArea = Warehouse;
                }
                field("Sales Return Orders"; Rec."Sales Return Orders")
                {
                    ApplicationArea = Warehouse;
                    Enabled = SalesReturnOrdersEnable;
                }
                field("Purchase Orders"; Rec."Purchase Orders")
                {
                    ApplicationArea = Warehouse;
                    Enabled = PurchaseOrdersEnable;
                }
                field("Inbound Transfers"; Rec."Inbound Transfers")
                {
                    ApplicationArea = Warehouse;
                    Enabled = InboundTransfersEnable;

                    trigger OnValidate()
                    begin
                        EnableControls();
                    end;
                }
                field("Shipping Agent Code Filter"; Rec."Shipping Agent Code Filter")
                {
                    ApplicationArea = Warehouse;
                    Enabled = ShippingAgentCodeFilterEnable;
                }
                field("Shipping Agent Service Filter"; Rec."Shipping Agent Service Filter")
                {
                    ApplicationArea = Warehouse;
                    Enabled = ShippingAgentServiceFilterEnable;
                }
                field("Do Not Fill Qty. to Handle"; Rec."Do Not Fill Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                }
                group("Source Document:")
                {
                    Caption = 'Source Document:';
                    field("Sales Orders"; Rec."Sales Orders")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = SalesOrdersEnable;

                        trigger OnValidate()
                        begin
                            EnableControls();
                        end;
                    }
                    field("Purchase Return Orders"; Rec."Purchase Return Orders")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = PurchaseReturnOrdersEnable;
                    }
                    field("Outbound Transfers"; Rec."Outbound Transfers")
                    {
                        ApplicationArea = Warehouse;
                        Enabled = OutboundTransfersEnable;

                        trigger OnValidate()
                        begin
                            EnableControls();
                        end;
                    }
                }
                group("Shipping Advice Filter:")
                {
                    Caption = 'Shipping Advice Filter:';
                    field(Partial; Rec.Partial)
                    {
                        ApplicationArea = Warehouse;
                    }
                    field(Complete; Rec.Complete)
                    {
                        ApplicationArea = Warehouse;
                    }
                }
            }
            group(Sales)
            {
                Caption = 'Sales';
                field("Sell-to Customer No. Filter"; Rec."Sell-to Customer No. Filter")
                {
                    ApplicationArea = Warehouse;
                }
            }
            group(Purchase)
            {
                Caption = 'Purchase';
                field("Buy-from Vendor No. Filter"; Rec."Buy-from Vendor No. Filter")
                {
                    ApplicationArea = Warehouse;
                }
            }
            group(Transfer)
            {
                Caption = 'Transfer';
                field("In-Transit Code Filter"; Rec."In-Transit Code Filter")
                {
                    ApplicationArea = Location;
                }
                field("Transfer-from Code Filter"; Rec."Transfer-from Code Filter")
                {
                    ApplicationArea = Location;
                }
                field("Transfer-to Code Filter"; Rec."Transfer-to Code Filter")
                {
                    ApplicationArea = Location;
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Customer No. Filter"; Rec."Customer No. Filter")
                {
                    ApplicationArea = Warehouse;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Run)
            {
                ApplicationArea = Warehouse;
                Caption = '&Run';
                Image = Start;
                ToolTip = 'Get the specified source documents.';

                trigger OnAction()
                var
                    GetSourceBatch: Report "Get Source Documents";
                begin
                    Rec."Planned Delivery Date" := CopyStr(Rec.GetFilter("Planned Delivery Date Filter"), 1, MaxStrLen(Rec."Planned Delivery Date"));
                    Rec."Planned Shipment Date" := CopyStr(Rec.GetFilter("Planned Shipment Date Filter"), 1, MaxStrLen(Rec."Planned Shipment Date"));
                    Rec."Sales Shipment Date" := CopyStr(Rec.GetFilter("Sales Shipment Date Filter"), 1, MaxStrLen(Rec."Sales Shipment Date"));
                    Rec."Planned Receipt Date" := CopyStr(Rec.GetFilter("Planned Receipt Date Filter"), 1, MaxStrLen(Rec."Planned Receipt Date"));
                    Rec."Expected Receipt Date" := CopyStr(Rec.GetFilter("Expected Receipt Date Filter"), 1, MaxStrLen(Rec."Expected Receipt Date"));
                    Rec."Shipment Date" := CopyStr(Rec.GetFilter("Shipment Date Filter"), 1, MaxStrLen(Rec."Shipment Date"));
                    Rec."Receipt Date" := CopyStr(Rec.GetFilter("Receipt Date Filter"), 1, MaxStrLen(Rec."Receipt Date"));

                    case RequestType of
                        RequestType::Receive:
                            begin
                                GetSourceBatch.SetOneCreatedReceiptHeader(WhseReceiptHeader);
                                Rec.SetFilters(GetSourceBatch, WhseReceiptHeader."Location Code");
                            end;
                        RequestType::Ship:
                            begin
                                GetSourceBatch.SetOneCreatedShptHeader(WhseShptHeader);
                                Rec.SetFilters(GetSourceBatch, WhseShptHeader."Location Code");
                            end;
                    end;

                    GetSourceBatch.UseRequestPage(Rec."Show Filter Request");
                    OnActionRunOnBeforeGetSourceBatchRunModal(Rec, GetSourceBatch);
                    GetSourceBatch.RunModal();
                    OnActionRunOnAfterGetSourceBatchRunModal(Rec, GetSourceBatch);
                    if GetSourceBatch.NotCancelled() then
                        CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Run_Promoted; Run)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
    end;

    trigger OnOpenPage()
    begin
        InitializeControls();

        DataCaption := CurrPage.Caption();
        Rec.FilterGroup := 2;
        if Rec.GetFilter(Type) <> '' then
            DataCaption := DataCaption + ' - ' + Rec.GetFilter(Type);
        Rec.FilterGroup := 0;
        CurrPage.Caption(DataCaption);

        EnableControls();
    end;

    protected var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        DataCaption: Text;
        RequestType: Option Receive,Ship;
        SalesOrdersEnable: Boolean;
        PurchaseReturnOrdersEnable: Boolean;
        OutboundTransfersEnable: Boolean;
        PurchaseOrdersEnable: Boolean;
        SalesReturnOrdersEnable: Boolean;
        InboundTransfersEnable: Boolean;
        ShippingAgentCodeFilterEnable: Boolean;
        ShippingAgentServiceFilterEnable: Boolean;

    procedure SetOneCreatedShptHeader(WhseShptHeader2: Record "Warehouse Shipment Header")
    begin
        RequestType := RequestType::Ship;
        WhseShptHeader := WhseShptHeader2;
    end;

    procedure SetOneCreatedReceiptHeader(WhseReceiptHeader2: Record "Warehouse Receipt Header")
    begin
        RequestType := RequestType::Receive;
        WhseReceiptHeader := WhseReceiptHeader2;
    end;

    protected procedure EnableControls()
    begin
        OnBeforeEnableControls();
        case Rec.Type of
            Rec.Type::Inbound:
                begin
                    SalesOrdersEnable := false;
                    PurchaseReturnOrdersEnable := false;
                    OutboundTransfersEnable := false;
                end;
            Rec.Type::Outbound:
                begin
                    PurchaseOrdersEnable := false;
                    SalesReturnOrdersEnable := false;
                    InboundTransfersEnable := false;
                end;
        end;
        if Rec."Sales Orders" or Rec."Inbound Transfers" or Rec."Outbound Transfers" then begin
            ShippingAgentCodeFilterEnable := true;
            ShippingAgentServiceFilterEnable := true;
        end else begin
            ShippingAgentCodeFilterEnable := false;
            ShippingAgentServiceFilterEnable := false;
        end;
    end;

    protected procedure InitializeControls()
    begin
        ShippingAgentServiceFilterEnable := true;
        ShippingAgentCodeFilterEnable := true;
        InboundTransfersEnable := true;
        SalesReturnOrdersEnable := true;
        PurchaseOrdersEnable := true;
        OutboundTransfersEnable := true;
        PurchaseReturnOrdersEnable := true;
        SalesOrdersEnable := true;

        OnAfterInitializeControls();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitializeControls()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnActionRunOnBeforeGetSourceBatchRunModal(var WhseSourceFilter: Record "Warehouse Source Filter"; var GetSourceBatch: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeEnableControls()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnActionRunOnAfterGetSourceBatchRunModal(var WhseSourceFilter: Record "Warehouse Source Filter"; var GetSourceBatch: Report "Get Source Documents")
    begin
    end;
}

