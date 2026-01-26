// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Comment;

page 5743 "Posted Transfer Shipment"
{
    Caption = 'Posted Transfer Shipment';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Transfer Shipment Header";

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
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location that the items are transferred to.';
                }
                field("Direct Transfer"; Rec."Direct Transfer")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies that the transfer does not use an in-transit location.';
                }
                field("In-Transit Code"; Rec."In-Transit Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the in-transit code for the transfer order, such as a shipping agent.';
                }
                field("Transfer Order No."; Rec."Transfer Order No.")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the related transfer order.';
                }
                field("Transfer Order Date"; Rec."Transfer Order Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the date when the transfer order was created.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for this document.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            part(TransferShipmentLines; "Posted Transfer Shpt. Subform")
            {
                ApplicationArea = Location;
                SubPageLink = "Document No." = field("No.");
            }
            group(Shipment)
            {
                Caption = 'Shipment';
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the receipt date of the transfer order.';
                }
            }
            group("Transfer-from")
            {
                Caption = 'Transfer-from';
                field("Transfer-from Name"; Rec."Transfer-from Name")
                {
                    ApplicationArea = Location;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the sender at the location that the items are transferred from.';
                }
                field("Transfer-from Name 2"; Rec."Transfer-from Name 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Name 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name of the sender at the location that the items are transferred from.';
                }
                field("Transfer-from Address"; Rec."Transfer-from Address")
                {
                    ApplicationArea = Location;
                    Caption = 'Address';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the address of the location that the items are transferred from.';
                }
                field("Transfer-from Address 2"; Rec."Transfer-from Address 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Address 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the address of the location that items are transferred from.';
                }
                field("Transfer-from City"; Rec."Transfer-from City")
                {
                    ApplicationArea = Location;
                    Caption = 'City';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the city of the location that the items are transferred from.';
                }
                group(Control13)
                {
                    ShowCaption = false;
                    Visible = IsFromCountyVisible;
                    field("Transfer-from County"; Rec."Transfer-from County")
                    {
                        ApplicationArea = Location;
                        CaptionClass = '5,1,' + Rec."Trsf.-from Country/Region Code";
                        Editable = false;
                        Importance = Additional;
                    }
                }
                field("Transfer-from Post Code"; Rec."Transfer-from Post Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Post Code';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the postal code of the location that the items are transferred from.';
                }
                field("Trsf.-from Country/Region Code"; Rec."Trsf.-from Country/Region Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Country/Region';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-from Contact"; Rec."Transfer-from Contact")
                {
                    ApplicationArea = Location;
                    Caption = 'Contact';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the contact person at the location that the items are transferred from.';
                }
            }
            group("Transfer-to")
            {
                Caption = 'Transfer-to';
                field("Transfer-to Name"; Rec."Transfer-to Name")
                {
                    ApplicationArea = Location;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the recipient at the location that the items are transferred to.';
                }
                field("Transfer-to Name 2"; Rec."Transfer-to Name 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Name 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name of the recipient at the location that the items are transferred to.';
                }
                field("Transfer-to Address"; Rec."Transfer-to Address")
                {
                    ApplicationArea = Location;
                    Caption = 'Address';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the address of the location that the items are transferred to.';
                }
                field("Transfer-to Address 2"; Rec."Transfer-to Address 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Address 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the address of the location that items are transferred to.';
                }
                field("Transfer-to City"; Rec."Transfer-to City")
                {
                    ApplicationArea = Location;
                    Caption = 'City';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the city of the location that items are transferred to.';
                }
                group(Control21)
                {
                    ShowCaption = false;
                    Visible = IsToCountyVisible;
                    field("Transfer-to County"; Rec."Transfer-to County")
                    {
                        ApplicationArea = Location;
                        CaptionClass = '5,1,' + Rec."Trsf.-to Country/Region Code";
                        Editable = false;
                        Importance = Additional;
                    }
                }
                field("Transfer-to Post Code"; Rec."Transfer-to Post Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Post Code';
                    Editable = false;
                    Importance = Additional;
                }
                field("Trsf.-to Country/Region Code"; Rec."Trsf.-to Country/Region Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Country/Region';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-to Contact"; Rec."Transfer-to Contact")
                {
                    ApplicationArea = Location;
                    Caption = 'Contact';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the contact person at the location that items are transferred to.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                }
                field("Entry/Exit Point"; Rec."Entry/Exit Point")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    ToolTip = 'Specifies the code of either the port of entry at which the items passed into your country/region, or the port of exit.';
                }
                field("Partner VAT ID"; Rec."Partner VAT ID")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    ToolTip = 'Specifies the counter party''s VAT number.';
                }
            }
            group(Reporting)
            {
                Caption = 'Reporting';
                field("Transport Reason Code"; Rec."Transport Reason Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the transport reason codes in the Transfer Shipment Header table.';
                }
                field("Goods Appearance"; Rec."Goods Appearance")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies a goods appearance code.';
                }
                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the gross weight of an item in the Transfer Shipment Header table.';
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the net weight of the item.';
                }
                field("Parcel Units"; Rec."Parcel Units")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the number of packages on a subcontractor transfer shipment order.';
                }
                field(Volume; Rec.Volume)
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the volume of one unit of the item.';
                }
                field("Shipping Notes"; Rec."Shipping Notes")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the product''s shipping notes on a subcontractor transfer order.';
                }
                field("3rd Party Loader Type"; Rec."3rd Party Loader Type")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the type of third party that is responsible for loading the items for this document.';
                }
                field("3rd Party Loader No."; Rec."3rd Party Loader No.")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the vendor or contact that is responsible for loading the items for this document.';
                }
                field("Shipping Starting Date"; Rec."Shipping Starting Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the date that the transfer shipment order is expected to ship.';
                }
                field("Shipping Starting Time"; Rec."Shipping Starting Time")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the time that the transfer shipment order is expected to ship.';
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the tracking number of a package on a subcontractor order.';
                }
                field("Additional Information"; Rec."Additional Information")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies additional declaration information that is needed for the shipment.';
                }
                field("Additional Notes"; Rec."Additional Notes")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies additional notes that are needed for the shipment.';
                }
                field("Additional Instructions"; Rec."Additional Instructions")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies additional instructions that are needed for the shipment.';
                }
                field("TDD Prepared By"; Rec."TDD Prepared By")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the user ID of the transport delivery document (TDD) for the transfer shipment.';
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
            group("&Shipment")
            {
                Caption = '&Shipment';
                Image = Shipment;
                action(Statistics)
                {
                    ApplicationArea = Location;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Transfer Shipment Statistics";
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
                    RunPageLink = "Document Type" = const("Posted Transfer Shipment"),
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
                        Rec.ShowDimensions();
                    end;
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
                    TransShptHeader: Record "Transfer Shipment Header";
                begin
                    CurrPage.SetSelectionFilter(TransShptHeader);
                    TransShptHeader.PrintRecords(true);
                end;
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Track Package")
                {
                    ApplicationArea = Location;
                    Caption = '&Track Package';
                    Image = ItemTracking;
                    ToolTip = 'View the progress of the transfer shipment.';

                    trigger OnAction()
                    begin
                        Rec.StartTrackingSite();
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Location;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action("Update Document")
            {
                ApplicationArea = Location;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedTransferShptUpdate: Page "Posted Transfer Shpt. - Update";
                begin
                    PostedTransferShptUpdate.LookupMode := true;
                    PostedTransferShptUpdate.SetRec(Rec);
                    PostedTransferShptUpdate.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Update Document_Promoted"; "Update Document")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Shipment', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsFromCountyVisible := FormatAddress.UseCounty(Rec."Trsf.-from Country/Region Code");
        IsToCountyVisible := FormatAddress.UseCounty(Rec."Trsf.-to Country/Region Code");
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsFromCountyVisible: Boolean;
        IsToCountyVisible: Boolean;
}

