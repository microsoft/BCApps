#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Currency;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using System.Security.User;

page 12152 "Subcontracting Order"
{
    Caption = 'Subcontracting Order';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Purchase Header";
    SourceTableView = where("Document Type" = filter(Order),
                            "Subcontracting Order" = const(true));
    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the document number.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the vendor.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Buy-from Contact No."; Rec."Buy-from Contact No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies your contact person.';
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the company name of the vendor.';
                }
                field("Buy-from Address"; Rec."Buy-from Address")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address of the vendor''s residence.';
                }
                field("Buy-from Address 2"; Rec."Buy-from Address 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address of the vendor''s residence.';
                }
                field("Buy-from Post Code"; Rec."Buy-from Post Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the post code of the vendor.';
                }
                field("Buy-from City"; Rec."Buy-from City")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the city of the vendor.';
                }
                field("Buy-from Contact"; Rec."Buy-from Contact")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies your contact person.';
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the purchaser.';
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the responsibility center.';
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address.';
                }
                field("No. of Archived Versions"; Rec."No. of Archived Versions")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of archived versions.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the posting date of the document.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the order was registered.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the transaction date of the document.';
                }
                field("Operation Occurred Date"; Rec."Operation Occurred Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date when the VAT operation occurred on the transaction.';
                }
                field("Vendor Order No."; Rec."Vendor Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the external order number.';
                }
                field("Vendor Shipment No."; Rec."Vendor Shipment No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the external shipment number.';
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the external invoice number.';
                }
                field("Operation Type"; Rec."Operation Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the operation type that is assigned to the purchase invoice.';
                }
                field("Activity Code"; Rec."Activity Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for the company''s primary activity.';
                }
                field("Check Total"; Rec."Check Total")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the total amount including VAT on the purchase document from the vendor.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Subcontracting Order"; Rec."Subcontracting Order")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the subcontracting orders that have been created.';
                }
                field("Subcontracting Location Code"; Rec."Subcontracting Location Code")
                {
                    ApplicationArea = Manufacturing;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the location where the subcontracted items are stored for pickup and delivery.';
                }
            }
            part(PurchLines; "Subcontracting Order Subform")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Document No." = field("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the vendor.';

                    trigger OnValidate()
                    begin
                        PaytoVendorNoOnAfterValidate();
                    end;
                }
                field("Pay-to Contact No."; Rec."Pay-to Contact No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies your contact person.';
                }
                field("Pay-to Name"; Rec."Pay-to Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the company name of the vendor.';
                }
                field("Pay-to Address"; Rec."Pay-to Address")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address of the vendor''s residence.';
                }
                field("Pay-to Address 2"; Rec."Pay-to Address 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address of the vendor''s residence.';
                }
                field("Pay-to Post Code"; Rec."Pay-to Post Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the post code of the vendor.';
                }
                field("Pay-to City"; Rec."Pay-to City")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the city of the vendor.';
                }
                field("Pay-to Contact"; Rec."Pay-to Contact")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies your contact person.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV();
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension2CodeOnAfterV();
                    end;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the payment terms for the document.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the payment method code for the document.';
                }
                field("Bank Account"; Rec."Bank Account")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the vendor''s bank account that is associated with the purchase invoice.';
                }
                field("On Hold"; Rec."On Hold")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies if the order is on hold.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the name of the company.';
                }
                field("Ship-to Address"; Rec."Ship-to Address")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address.';
                }
                field("Ship-to Address 2"; Rec."Ship-to Address 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address.';
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the post code.';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the city.';
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the contact person.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the warehouse location.';
                }
                field("Inbound Whse. Handling Time"; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date formula for the inbound warehouse handling time for the location.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the shipment method.';
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a date formula for the amount of time that it takes to replenish the item. This field is used to calculate the date fields on order and order proposal lines.';
                }
                field("Requested Receipt Date"; Rec."Requested Receipt Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the wanted date of receipt.';
                }
                field("Promised Receipt Date"; Rec."Promised Receipt Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date of receipt that the vendor has promised.';
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the expected date of receipt.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the customer.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the company.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency that is associated with the document.';

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Document Date");
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());
                            CurrPage.Update();
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the type of transaction that is the source of the entry.';
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a code for the document''s transaction specification.';
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for the transport method used for the item on this line.';
                }
                field("Entry Point"; Rec."Entry Point")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the point of entry.';
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the area that the transaction takes place in.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
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
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistics about the document.';

                    trigger OnAction()
                    begin
                        Rec.CalcInvDiscForHeader();
                        Commit();
                        PAGE.RunModal(PAGE::"Purchase Order Statistics", Rec);
                    end;
                }
                action(Card)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Vendor Card";
                    RunPageLink = "No." = field("Buy-from Vendor No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the card.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "No." = field("No.");
                    ToolTip = 'View or edit comments about the document.';
                }
                action(Receipts)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Receipts';
                    Image = PostedReceipts;
                    RunObject = Page "Posted Purchase Receipts";
                    RunPageLink = "Order No." = field("No.");
                    RunPageView = sorting("Order No.");
                    ToolTip = 'View the related receipts.';
                }
                action(Invoices)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Invoices';
                    Image = Invoice;
                    RunObject = Page "Posted Purchase Invoices";
                    RunPageLink = "Order No." = field("No.");
                    RunPageView = sorting("Order No.");
                    ToolTip = 'View the related invoices.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Pa&yments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Pa&yments';
                    RunObject = Page "Payment Date Lines";
                    RunPageLink = "Sales/Purchase" = const(Purchase),
                                  Type = field("Document Type"),
                                  Code = field("No.");
                    ToolTip = 'View the related payments.';
                }
                action("Copy Document")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Image = CopyDocument;
                    ToolTip = 'Create a copy of this document.';

                    trigger OnAction()
                    begin
                        CopyPurchDoc.SetPurchHeader(Rec);
                        CopyPurchDoc.RunModal();
                        Clear(CopyPurchDoc);
                    end;
                }
                action("Archi&ve Document")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Archi&ve Document';
                    Image = Archive;
                    ToolTip = 'Specifies if the document is archived after you print it.';

                    trigger OnAction()
                    begin
                        ArchiveManagement.ArchivePurchDocument(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action("Move Negative Lines")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Move Negative Lines';
                    Ellipsis = true;
                    Image = MoveNegativeLines;
                    ToolTip = 'Move negative lines.';

                    trigger OnAction()
                    begin
                        Clear(MoveNegPurchLines);
                        MoveNegPurchLines.SetPurchHeader(Rec);
                        MoveNegPurchLines.RunModal();
                        MoveNegPurchLines.ShowDocument();
                    end;
                }
                group("Drop Shipment")
                {
                    Caption = 'Drop Shipment';
                    Image = Delivery;
                    action("Get &Sales Order")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Get &Sales Order';
                        Ellipsis = true;
                        Image = "Order";
                        RunObject = Codeunit "Purch.-Get Drop Shpt.";
                        ToolTip = 'View the related sales order.';
                    }
                }
                group("Speci&al Order")
                {
                    Caption = 'Speci&al Order';
                    Image = SpecialOrder;
                    action(Action1130163)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Get &Sales Order';
                        Image = "Order";
                        ToolTip = 'View the related sales order.';

                        trigger OnAction()
                        var
                            PurchHeader: Record "Purchase Header";
                            DistIntegration: Codeunit "Dist. Integration";
                        begin
                            PurchHeader.Copy(Rec);
                            DistIntegration.GetSpecialOrders(PurchHeader);
                            Rec := PurchHeader;
                        end;
                    }
                }
                group(Warehouse)
                {
                    Caption = 'Warehouse';
                    Image = Warehouse;
                    action("Receipt Lines")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Receipt Lines';
                        RunObject = Page "Whse. Receipt Lines";
                        RunPageLink = "Source Type" = const(39),
#pragma warning disable AL0603
                                      "Source Subtype" = field("Document Type"),
#pragma warning restore AL0603
                                      "Source No." = field("No.");
                        RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                        ToolTip = 'View the related receipt lines.';
                    }
                    action("Create Receipt")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Create Receipt';
                        ToolTip = 'Create a receipt for the order.';

                        trigger OnAction()
                        var
                            GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
                        begin
                            GetSourceDocInbound.CreateFromPurchOrder(Rec);
                        end;
                    }
                }
                action("Re&lease")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    RunObject = Codeunit "Release Purchase Document";
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document.';
                }
                action("Re&open")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document.';

                    trigger OnAction()
                    var
                        ReleasePurchDoc: Codeunit "Release Purchase Document";
                    begin
                        ReleasePurchDoc.Reopen(Rec);
                    end;
                }
                separator(Action1130173)
                {
                }
                action(CreateTransfOrdToSubcontractor)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Create Trans&f. Ord. to Subcontractor';
                    Image = NewDocument;
                    ToolTip = 'Create a transfer order to send to the subcontractor.';

                    trigger OnAction()
                    var
                        PurchHeader: Record "Purchase Header";
                    begin
                        PurchHeader := Rec;
                        PurchHeader.SetRecFilter();
                        REPORT.Run(REPORT::"Create Subcontr.Transf. Order", false, false, PurchHeader);
                    end;
                }
                action(CreateReturnFromSubcontractor)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Create Return from Su&bcontractor';
                    Image = ReturnRelated;
                    ToolTip = 'Create a return document from the subcontractor.';

                    trigger OnAction()
                    var
                        PurchHeader: Record "Purchase Header";
                    begin
                        PurchHeader := Rec;
                        PurchHeader.SetRecFilter();
                        REPORT.Run(REPORT::"Create Subcontr. Return Order", false, false, PurchHeader);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report for the document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintPurchHeader(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    RunObject = Codeunit "Purch.-Post (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the document.';
                }
                action("Post and &Print")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    RunObject = Codeunit "Purch.-Post + Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Post the document and also print it.';
                }
                action("Post &Batch")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post the document as part of a bulk operation.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Purchase Orders", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Manufacturing;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Print the subcontracting order.';

                trigger OnAction()
                begin
                    DocPrint.PrintPurchHeader(Rec);
                end;
            }
            action("New Subcontr. Transfer Order")
            {
                ApplicationArea = Manufacturing;
                Caption = 'New Subcontr. Transfer Order';
                RunObject = Page "Subcontr. Transfer Order";
                ToolTip = 'Create a new subcontracting transfer order.';
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref("New Subcontr. Transfer Order_Promoted"; "New Subcontr. Transfer Order")
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
                actionref("Copy Document_Promoted"; "Copy Document")
                {
                }
                actionref("Re&lease_Promoted"; "Re&lease")
                {
                }
                actionref(CreateTransfOrdToSubcontractor_Promoted; CreateTransfOrdToSubcontractor)
                {
                }
                actionref(CreateReturnFromSubcontractor_Promoted; CreateReturnFromSubcontractor)
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord();
        exit(Rec.ConfirmDeletion());
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Responsibility Center" := UserMgt.GetPurchasesFilter();
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetPurchasesFilter() <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetRange("Responsibility Center", UserMgt.GetPurchasesFilter());
            Rec.FilterGroup(0);
        end;
    end;

    var
        CopyPurchDoc: Report "Copy Purchase Document";
        MoveNegPurchLines: Report "Move Negative Purchase Lines";
        ReportPrint: Codeunit "Test Report-Print";
        DocPrint: Codeunit "Document-Print";
        UserMgt: Codeunit "User Setup Management";
        ArchiveManagement: Codeunit ArchiveManagement;
        ChangeExchangeRate: Page "Change Exchange Rate";

    local procedure PaytoVendorNoOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.PurchLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.PurchLines.PAGE.UpdateForm(true);
    end;
}
#endif
