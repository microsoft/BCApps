// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Vendor;
using System.Security.User;

page 6623 "Blanket Purchase Order Archive"
{
    Caption = 'Blanket Purchase Order Archive';
    Editable = false;
    PageType = Document;
    SourceTable = "Purchase Header Archive";
    SourceTableView = where("Document Type" = const("Blanket Order"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the archived purchase order.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = Suite;
                }
                field("Buy-from Vendor Name 2"; Rec."Buy-from Vendor Name 2")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Buy-from Address"; Rec."Buy-from Address")
                {
                    ApplicationArea = Suite;
                }
                field("Buy-from Address 2"; Rec."Buy-from Address 2")
                {
                    ApplicationArea = Suite;
                }
                field("Buy-from Post Code"; Rec."Buy-from Post Code")
                {
                    ApplicationArea = Suite;
                }
                field("Buy-from City"; Rec."Buy-from City")
                {
                    ApplicationArea = Suite;
                }
                field("Buy-from Contact"; Rec."Buy-from Contact")
                {
                    ApplicationArea = Suite;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the document was posted.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date the document was created.';
                }
                field("Vendor Order No."; Rec."Vendor Order No.")
                {
                    ApplicationArea = Suite;
                }
                field("Vendor Shipment No."; Rec."Vendor Shipment No.")
                {
                    ApplicationArea = Suite;
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = Suite;
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = Suite;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Suite;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center (for example, a distribution center) assigned to the vendor or associated with the order.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the order.';
                }
            }
            part(PurchLinesArchive; "Blanket Purch. Order Arch.Sub.")
            {
                ApplicationArea = Suite;
                SubPageLink = "Document No." = field("No."),
                              "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                              "Version No." = field("Version No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Pay-to Name"; Rec."Pay-to Name")
                {
                    ApplicationArea = Suite;
                }
                field("Pay-to Name 2"; Rec."Pay-to Name 2")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Pay-to Address"; Rec."Pay-to Address")
                {
                    ApplicationArea = Suite;
                }
                field("Pay-to Address 2"; Rec."Pay-to Address 2")
                {
                    ApplicationArea = Suite;
                }
                field("Pay-to Post Code"; Rec."Pay-to Post Code")
                {
                    ApplicationArea = Suite;
                }
                field("Pay-to City"; Rec."Pay-to City")
                {
                    ApplicationArea = Suite;
                }
                field("Pay-to Contact"; Rec."Pay-to Contact")
                {
                    ApplicationArea = Suite;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount on the purchase document.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the payment discount percentage that is granted if you pay on or before the date entered in the Pmt. Discount Date field. The discount percentage is specified in the Payment Terms Code field.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the method of payment for payments to vendors.';
                }
                field("On Hold"; Rec."On Hold")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when an entry for an unpaid invoice has been posted and you create a finance charge memo or reminder.';
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = Suite;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the company at the address to which the items were shipped.';
                }
                field("Ship-to Address"; Rec."Ship-to Address")
                {
                    ApplicationArea = Suite;
                }
                field("Ship-to Address 2"; Rec."Ship-to Address 2")
                {
                    ApplicationArea = Suite;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the postal code of the address.';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ApplicationArea = Suite;
                }
                field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                {
                    ApplicationArea = Suite;
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of a contact person at the address that the items were shipped to.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                }
                field("Inbound Whse. Handling Time"; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Suite;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Suite;
                }
                field("Requested Receipt Date"; Rec."Requested Receipt Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date that you want the vendor to deliver your order. The field is used to calculate the latest date you can order, as follows: requested receipt date - lead time calculation = order date. If you do not need delivery on a specific date, you can leave the field blank.';
                }
                field("Promised Receipt Date"; Rec."Promised Receipt Date")
                {
                    ApplicationArea = Suite;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date you expect the items to be available in your warehouse. If you leave the field blank, it will be calculated as follows: Planned Receipt Date + Safety Lead Time + Inbound Warehouse Handling Time = Expected Receipt Date.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the customer who will receive the products and be billed by default.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Suite;
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for the amount on the line.';
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies the number for the transaction type, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies a code for the purchase document''s transaction specification, for the purpose of reporting to INTRASTAT.';
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Entry Point"; Rec."Entry Point")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = BasicEU, BasicNO;
                    ToolTip = 'Specifies the area in which your company has to pay sales tax.';
                }
            }
            group(Version)
            {
                Caption = 'Version';
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the user who archived the document.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Archived By");
                    end;
                }
                field("Date Archived"; Rec."Date Archived")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Time Archived"; Rec."Time Archived")
                {
                    ApplicationArea = Suite;
                }
                field("Interaction Exist"; Rec."Interaction Exist")
                {
                    ApplicationArea = RelationshipMgmt;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control74; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control73; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ver&sion")
            {
                Caption = 'Ver&sion';
                Image = Versions;
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Vendor Card";
                    RunPageLink = "No." = field("Buy-from Vendor No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the vendor on the purchase document.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Archive Comment Sheet";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "No." = field("No."),
                                  "Document Line No." = const(0),
                                  "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                  "Version No." = field("Version No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Print)
                {
                    ApplicationArea = Suite;
                    Caption = 'Print';
                    Image = Print;
                    ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        DocPrint.PrintPurchHeaderArch(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Print_Promoted; Print)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
        }
    }

    var
        DocPrint: Codeunit "Document-Print";
}

