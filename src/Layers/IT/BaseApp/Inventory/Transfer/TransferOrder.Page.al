// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Comment;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using System.Text;

page 5740 "Transfer Order"
{
    Caption = 'Transfer Order';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Transfer Header";
    SourceTableView = sorting("No.")
                      where("Subcontracting Order" = const(false));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                    ShowMandatory = true;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';

                    trigger OnValidate()
                    begin
                        IsTransferLinesEditable := Rec.TransferLinesEditable();
                        CurrPage.Update();
                    end;
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Location;
                    Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                    ShowMandatory = true;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location that the items are transferred to.';

                    trigger OnValidate()
                    begin
                        IsTransferLinesEditable := Rec.TransferLinesEditable();
                        CurrPage.Update();
                    end;
                }
                field("Direct Transfer"; Rec."Direct Transfer")
                {
                    ApplicationArea = Location;
                    Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                    Importance = Promoted;
                    ToolTip = 'Specifies that the transfer does not use an in-transit location. When you transfer directly, the Qty. to Receive field will be locked with the same value as the quantity to ship.';

                    trigger OnValidate()
                    begin
                        IsTransferLinesEditable := Rec.TransferLinesEditable();
                        CurrPage.Update();
                    end;
                }
                field("In-Transit Code"; Rec."In-Transit Code")
                {
                    ApplicationArea = Location;
                    Editable = EnableTransferFields;
                    ShowMandatory = not Rec."Direct Transfer";
                    Enabled = (not Rec."Direct Transfer") and (Rec.Status = Rec.Status::Open);
                    ToolTip = 'Specifies the in-transit code for the transfer order, such as a shipping agent.';

                    trigger OnValidate()
                    begin
                        IsTransferLinesEditable := Rec.TransferLinesEditable();
                        CurrPage.Update();
                    end;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the posting date of the transfer order.';

                    trigger OnValidate()
                    begin
                        PostingDateOnAfterValidate();
                    end;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = EnableTransferFields;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = EnableTransferFields;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Location;
                    Editable = EnableTransferFields;
                    Importance = Additional;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether the transfer order is open or has been released for warehouse handling.';
                }
            }
            part(TransferLines; "Transfer Order Subform")
            {
                ApplicationArea = Location;
                Editable = IsTransferLinesEditable;
                Enabled = IsTransferLinesEditable;
                SubPageLink = "Document No." = field("No."),
                              "Derived From Line No." = const(0);
                UpdatePropagation = Both;
            }
            group(Shipment)
            {
                Caption = 'Shipment';
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Location;
                    Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';

                    trigger OnValidate()
                    begin
                        ShipmentDateOnAfterValidate();
                    end;
                }
                field("Outbound Whse. Handling Time"; Rec."Outbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                    ToolTip = 'Specifies a date formula for the time it takes to get items ready to ship from this location. The time element is used in the calculation of the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';

                    trigger OnValidate()
                    begin
                        OutboundWhseHandlingTimeOnAfte();
                    end;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Location;
                    Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Location;
                    Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';

                    trigger OnValidate()
                    begin
                        ShippingAgentCodeOnAfterValida();
                    end;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Location;
                    Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';

                    trigger OnValidate()
                    begin
                        ShippingAgentServiceCodeOnAfte();
                    end;
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Location;
                    Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                    ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';

                    trigger OnValidate()
                    begin
                        ShippingTimeOnAfterValidate();
                    end;
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Location;
                    Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                    Importance = Additional;
                    ToolTip = 'Specifies an instruction to the warehouse that ships the items, for example, that it is acceptable to do partial shipment.';

                    trigger OnValidate()
                    begin
                        if Rec."Shipping Advice" <> xRec."Shipping Advice" then
                            if not Confirm(Text000, false, Rec.FieldCaption("Shipping Advice")) then
                                Error('');
                    end;
                }
                field("3rd Party Loader Type"; Rec."3rd Party Loader Type")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
                }
                field("3rd Party Loader No."; Rec."3rd Party Loader No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the ID of the vendor or contact that is responsible for loading the items for this document.';
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
                    Editable = Rec.Status = Rec.Status::Open;
                    ToolTip = 'Specifies the date that you expect the transfer-to location to receive the shipment.';

                    trigger OnValidate()
                    begin
                        ReceiptDateOnAfterValidate();
                    end;
                }
            }
            group("Transfer-from")
            {
                Caption = 'Transfer-from';
                Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                field("Transfer-from Name"; Rec."Transfer-from Name")
                {
                    ApplicationArea = Location;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the sender at the location that the items are transferred from.';
                }
                field("Transfer-from Name 2"; Rec."Transfer-from Name 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Name 2';
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name of the sender at the location that the items are transferred from.';
                }
                field("Transfer-from Address"; Rec."Transfer-from Address")
                {
                    ApplicationArea = Location;
                    Caption = 'Address';
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the address of the location that the items are transferred from.';
                }
                field("Transfer-from Address 2"; Rec."Transfer-from Address 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Address 2';
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies an additional part of the address of the location that items are transferred from.';
                }
                field("Transfer-from City"; Rec."Transfer-from City")
                {
                    ApplicationArea = Location;
                    Caption = 'City';
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the city of the location that the items are transferred from.';
                }
                group(Control17)
                {
                    ShowCaption = false;
                    Visible = IsFromCountyVisible;
                    field("Transfer-from County"; Rec."Transfer-from County")
                    {
                        ApplicationArea = Location;
                        CaptionClass = '5,1,' + Rec."Trsf.-from Country/Region Code";
                        Importance = Additional;
                        QuickEntry = false;
                    }
                }
                field("Transfer-from Post Code"; Rec."Transfer-from Post Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Post Code';
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the postal code of the location that the items are transferred from.';
                }
                field("Trsf.-from Country/Region Code"; Rec."Trsf.-from Country/Region Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Country/Region';
                    Importance = Additional;
                    QuickEntry = false;

                    trigger OnValidate()
                    begin
                        IsFromCountyVisible := FormatAddress.UseCounty(Rec."Trsf.-from Country/Region Code");
                    end;
                }
                field("Transfer-from Contact"; Rec."Transfer-from Contact")
                {
                    ApplicationArea = Location;
                    Caption = 'Contact';
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the contact person at the location that the items are transferred from.';
                }
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies additional declaration information that is needed for this shipment.';
                }
                field("Additional Notes"; Rec."Additional Notes")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies additional notes that are needed for this shipment.';
                }
                field("Additional Instructions"; Rec."Additional Instructions")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies additional instructions that are needed for this shipment.';
                }
                field("TDD Prepared By"; Rec."TDD Prepared By")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the transfer order.';
                }
            }
            group("Transfer-to")
            {
                Caption = 'Transfer-to';
                Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                field("Transfer-to Name"; Rec."Transfer-to Name")
                {
                    ApplicationArea = Location;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the recipient at the location that the items are transferred to.';
                }
                field("Transfer-to Name 2"; Rec."Transfer-to Name 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Name 2';
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name of the recipient at the location that the items are transferred to.';
                }
                field("Transfer-to Address"; Rec."Transfer-to Address")
                {
                    ApplicationArea = Location;
                    Caption = 'Address';
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the address of the location that the items are transferred to.';
                }
                field("Transfer-to Address 2"; Rec."Transfer-to Address 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Address 2';
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies an additional part of the address of the location that the items are transferred to.';
                }
                field("Transfer-to City"; Rec."Transfer-to City")
                {
                    ApplicationArea = Location;
                    Caption = 'City';
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the city of the location that items are transferred to.';
                }
                group(Control24)
                {
                    ShowCaption = false;
                    Visible = IsToCountyVisible;
                    field("Transfer-to County"; Rec."Transfer-to County")
                    {
                        ApplicationArea = Location;
                        CaptionClass = '5,1,' + Rec."Trsf.-to Country/Region Code";
                        Importance = Additional;
                        QuickEntry = false;
                    }
                }
                field("Transfer-to Post Code"; Rec."Transfer-to Post Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Post Code';
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the postal code of the location that the items are transferred to.';
                }
                field("Trsf.-to Country/Region Code"; Rec."Trsf.-to Country/Region Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Country/Region';
                    Importance = Additional;
                    QuickEntry = false;

                    trigger OnValidate()
                    begin
                        IsToCountyVisible := FormatAddress.UseCounty(Rec."Trsf.-to Country/Region Code");
                    end;
                }
                field("Transfer-to Contact"; Rec."Transfer-to Contact")
                {
                    ApplicationArea = Location;
                    Caption = 'Contact';
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the contact person at the location that items are transferred to.';
                }
            }
            group(Control19)
            {
                Caption = 'Warehouse';
                field("Inbound Whse. Handling Time"; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the time it takes to make items part of available inventory, after the items have been posted as received.';

                    trigger OnValidate()
                    begin
                        InboundWhseHandlingTimeOnAfter();
                    end;
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                Editable = (Rec.Status = Rec.Status::Open) and EnableTransferFields;
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Importance = Promoted;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                }
                field("Entry/Exit Point"; Rec."Entry/Exit Point")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies the code of either the port of entry at which the items passed into your country/region, or the port of exit.';
                }
                field("Partner VAT ID"; Rec."Partner VAT ID")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies the counter party''s VAT number.';
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the gross weight of an item in the Transfer Header table.';
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the net weight of the item.';
                }
                field("Parcel Units"; Rec."Parcel Units")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of packages on a subcontractor order.';
                }
                field("Freight Type"; Rec."Freight Type")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the freight type that is associated with the documents in the Transfer Header table.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action(Statistics)
                {
                    ApplicationArea = Location;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Transfer Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information about the transfer order, such as the quantity and total weight transferred.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Inventory Comment Sheet";
                    RunPageLink = "Document Type" = const("Transfer Order"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("S&hipments")
                {
                    ApplicationArea = Location;
                    Caption = 'S&hipments';
                    Image = Shipment;
                    RunObject = Page "Posted Transfer Shipments";
                    RunPageLink = "Transfer Order No." = field("No.");
                    ToolTip = 'View related posted transfer shipments.';
                }
                action("Re&ceipts")
                {
                    ApplicationArea = Location;
                    Caption = 'Re&ceipts';
                    Image = PostedReceipts;
                    RunObject = Page "Posted Transfer Receipts";
                    RunPageLink = "Transfer Order No." = field("No.");
                    ToolTip = 'View related posted transfer receipts.';
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("Whse. Shi&pments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Whse. Shi&pments';
                    Image = Shipment;
                    RunObject = Page "Whse. Shipment Lines";
                    RunPageLink = "Source Type" = const(5741),
                                  "Source Subtype" = const("0"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View outbound items that have been shipped with warehouse activities for the transfer order.';
                }
                action("&Whse. Receipts")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Whse. Receipts';
                    Image = Receipt;
                    RunObject = Page "Whse. Receipt Lines";
                    RunPageLink = "Source Type" = const(5741),
                                  "Source Subtype" = const("1"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View inbound items that have been received with warehouse activities for the transfer order.';
                }
                action("In&vt. Put-away/Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'In&vt. Put-away/Pick Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity List";
                    RunPageLink = "Source Document" = filter("Inbound Transfer" | "Outbound Transfer"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Document", "Source No.", "Location Code");
                    ToolTip = 'View items that are inbound or outbound on inventory put-away or inventory pick documents for the transfer order.';
                }
                action("Whse. Put-away/Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Put-away/Pick Lines';
                    Image = PutawayLines;
                    RunObject = page "Warehouse Activity Lines";
                    RunPageLink = "Source Document" = filter("Inbound Transfer" | "Outbound Transfer"), "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.");
                    ToolTip = 'View items that are inbound or outbound on warehouse put-away or warehouse pick documents for the transfer order.';
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Location;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintTransferHeader(Rec);
                end;
            }
            group(Release)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action("Re&lease")
                {
                    ApplicationArea = Location;
                    Caption = 'Re&lease';
                    Enabled = Rec.Status <> Rec.Status::Released;
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                    end;
                }
                action("Reo&pen")
                {
                    ApplicationArea = Location;
                    Caption = 'Reo&pen';
                    Enabled = Rec.Status <> Rec.Status::Open;
                    Image = ReOpen;
                    ToolTip = 'Reopen the transfer order after being released for warehouse handling.';

                    trigger OnAction()
                    var
                        ReleaseTransferDoc: Codeunit "Release Transfer Document";
                    begin
                        ReleaseTransferDoc.Reopen(Rec);
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Whse. S&hipment")
                {
                    AccessByPermission = TableData "Warehouse Shipment Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Whse. S&hipment';
                    Image = NewShipment;
                    ToolTip = 'Create a warehouse shipment to start a pick a ship process according to an advanced warehouse configuration.';

                    trigger OnAction()
                    var
                        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
                    begin
                        Rec.PerformManualRelease();
                        GetSourceDocOutbound.CreateFromOutbndTransferOrder(Rec);
                    end;
                }
                action("Create &Whse. Receipt")
                {
                    AccessByPermission = TableData "Warehouse Receipt Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create &Whse. Receipt';
                    Image = NewReceipt;
                    ToolTip = 'Create a warehouse receipt to start a receive and put-away process according to an advanced warehouse configuration.';

                    trigger OnAction()
                    var
                        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
                    begin
                        Rec.PerformManualRelease();
                        GetSourceDocInbound.CreateFromInbndTransferOrder(Rec);
                    end;
                }
                action("Create Inventor&y Put-away/Pick")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Inventor&y Put-away/Pick';
                    Ellipsis = true;
                    Image = CreateInventoryPickup;
                    ToolTip = 'Create an inventory put-away or inventory pick to handle items on the document with a basic warehouse process that does not require warehouse receipt or shipment documents.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                        Rec.CreateInvtPutAwayPick();
                    end;
                }
                action("Get Bin Content")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Get Bin Content';
                    Ellipsis = true;
                    Image = GetBinContent;
                    ToolTip = 'Use a function to create transfer lines with items to put away or pick based on the actual content in the specified bin.';

                    trigger OnAction()
                    var
                        BinContent: Record "Bin Content";
                        GetBinContent: Report "Whse. Get Bin Content";
                    begin
                        BinContent.SetRange("Location Code", Rec."Transfer-from Code");
                        GetBinContent.SetTableView(BinContent);
                        GetBinContent.InitializeTransferHeader(Rec);
                        GetBinContent.RunModal();
                    end;
                }
                action(GetReceiptLines)
                {
                    ApplicationArea = Location;
                    Caption = 'Get Receipt Lines';
                    Image = Receipt;
                    ToolTip = 'Add transfer order lines from posted purchase receipt lines.';

                    trigger OnAction()
                    begin
                        Rec.GetReceiptLines();
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Location;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"TransferOrder-Post (Yes/No)", Rec);
                    end;
                }
                action(PreviewPosting)
                {
                    ApplicationArea = Location;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        ShowPreview();
                        CurrPage.Update(false);
                    end;
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Location;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"TransferOrder-Post + Print", Rec);
                    end;
                }
                action(BatchPost)
                {
                    ApplicationArea = Location;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    var
                        TransferHeader: Record "Transfer Header";
                        SelectionFilterManagement: Codeunit SelectionFilterManagement;
                    begin
                        CurrPage.SetSelectionFilter(TransferHeader);
                        TransferHeader.SetFilter("No.", SelectionFilterManagement.GetSelectionFilterForTransferHeader(TransferHeader));
                        REPORT.RunModal(REPORT::"Batch Post Transfer Orders", true, true, TransferHeader);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Inventory - Inbound Transfer")
            {
                ApplicationArea = Warehouse;
                Caption = 'Inventory - Inbound Transfer';
                Image = "Report";
                RunObject = Report "Inventory - Inbound Transfer";
                ToolTip = 'View which items are currently on inbound transfer orders.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Category5)
                {
                    Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 4.';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(PreviewPosting_Promoted; PreviewPosting)
                    {
                    }
                    actionref(PostAndPrint_Promoted; PostAndPrint)
                    {
                    }
                }
                actionref("Create Whse. S&hipment_Promoted"; "Create Whse. S&hipment")
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 3.';
                    ShowAs = SplitButton;

                    actionref("Re&lease_Promoted"; "Re&lease")
                    {
                    }
                    actionref("Reo&pen_Promoted"; "Reo&pen")
                    {
                    }
                }
                actionref("Create &Whse. Receipt_Promoted"; "Create &Whse. Receipt")
                {
                }
                actionref("Create Inventor&y Put-away/Pick_Promoted"; "Create Inventor&y Put-away/Pick")
                {
                }
            }
            group(Category_Prepare)
            {
                Caption = 'Prepare';

                actionref(GetReceiptLines_Promoted; GetReceiptLines)
                {
                }
                actionref("Get Bin Content_Promoted"; "Get Bin Content")
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Order', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref("S&hipments_Promoted"; "S&hipments")
                {
                }
                actionref("Re&ceipts_Promoted"; "Re&ceipts")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Documents', Comment = 'Generated from the PromotedActionCategories property index 6.';
            }
            group(Category_Category9)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 8.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        EnableTransferFields := not IsPartiallyShipped();
        ActivateFields();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Rec.TestField(Status, Rec.Status::Open);
    end;

    trigger OnOpenPage()
    begin
        SetDocNoVisible();
        EnableTransferFields := not IsPartiallyShipped();
        ActivateFields();
    end;

    var
        FormatAddress: Codeunit "Format Address";
        DocNoVisible: Boolean;
        IsFromCountyVisible: Boolean;
        IsToCountyVisible: Boolean;
        IsTransferLinesEditable: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Do you want to change %1 in all related records in the warehouse?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        EnableTransferFields: Boolean;

    local procedure ActivateFields()
    begin
        IsFromCountyVisible := FormatAddress.UseCounty(Rec."Trsf.-from Country/Region Code");
        IsToCountyVisible := FormatAddress.UseCounty(Rec."Trsf.-to Country/Region Code");
        IsTransferLinesEditable := Rec.TransferLinesEditable();
    end;

    local procedure PostingDateOnAfterValidate()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(true);
    end;

    local procedure ShipmentDateOnAfterValidate()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(false);
    end;

    local procedure ShippingAgentServiceCodeOnAfte()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(false);
    end;

    local procedure ShippingAgentCodeOnAfterValida()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(false);
    end;

    local procedure ShippingTimeOnAfterValidate()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(false);
    end;

    local procedure OutboundWhseHandlingTimeOnAfte()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(false);
    end;

    local procedure ReceiptDateOnAfterValidate()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(false);
    end;

    local procedure InboundWhseHandlingTimeOnAfter()
    begin
        CurrPage.TransferLines.PAGE.UpdateForm(false);
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        DocNoVisible := DocumentNoVisibility.TransferOrderNoIsVisible();
    end;

    local procedure IsPartiallyShipped(): Boolean
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", Rec."No.");
        TransferLine.SetFilter("Quantity Shipped", '> 0');
        exit(not TransferLine.IsEmpty);
    end;

    local procedure ShowPreview()
    var
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
    begin
        TransferOrderPostYesNo.Preview(Rec);
    end;
}

