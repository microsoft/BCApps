// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Comment;

page 5745 "Posted Transfer Receipt"
{
    Caption = 'Posted Transfer Receipt';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Transfer Receipt Header";

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
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Direct Transfer"; Rec."Direct Transfer")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("In-Transit Code"; Rec."In-Transit Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Transfer Order No."; Rec."Transfer Order No.")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    Lookup = false;
                }
                field("Transfer Order Date"; Rec."Transfer Order Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Importance = Additional;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Importance = Additional;
                }
            }
            part(TransferReceiptLines; "Posted Transfer Rcpt. Subform")
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
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
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
                }
                field("Transfer-from Name 2"; Rec."Transfer-from Name 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Name 2';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-from Address"; Rec."Transfer-from Address")
                {
                    ApplicationArea = Location;
                    Caption = 'Address';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-from Address 2"; Rec."Transfer-from Address 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Address 2';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-from City"; Rec."Transfer-from City")
                {
                    ApplicationArea = Location;
                    Caption = 'City';
                    Editable = false;
                    Importance = Additional;
                }
                group(Control21)
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
                }
                field("Transfer-to Name 2"; Rec."Transfer-to Name 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Name 2';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-to Address"; Rec."Transfer-to Address")
                {
                    ApplicationArea = Location;
                    Caption = 'Address';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-to Address 2"; Rec."Transfer-to Address 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Address 2';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-to City"; Rec."Transfer-to City")
                {
                    ApplicationArea = Location;
                    Caption = 'City';
                    Editable = false;
                    Importance = Additional;
                }
                group(Control19)
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
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                }
                field("Entry/Exit Point"; Rec."Entry/Exit Point")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                }
                field("Partner VAT ID"; Rec."Partner VAT ID")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
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
            group("&Receipt")
            {
                Caption = '&Receipt';
                Image = Receipt;
                action(Statistics)
                {
                    ApplicationArea = Location;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Transfer Receipt Statistics";
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
                    RunPageLink = "Document Type" = const("Posted Transfer Receipt"),
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
                    TransRcptHeader: Record "Transfer Receipt Header";
                begin
                    CurrPage.SetSelectionFilter(TransRcptHeader);
                    TransRcptHeader.PrintRecords(true);
                end;
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
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Receipt', Comment = 'Generated from the PromotedActionCategories property index 3.';

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

