// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Comment;

/// <summary>
/// Lists all posted sales return receipts for viewing and navigation.
/// </summary>
page 6662 "Posted Return Receipts"
{
    ApplicationArea = SalesReturnOrder;
    Caption = 'Posted Return Receipt';
    CardPageID = "Posted Return Receipt";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Posted Return Receipt';
    AboutText = 'View and manage posted sales return receipts, track package shipments, and combine receipts to create sales credit memos for efficient processing and invoicing of returned items.';
    SourceTable = "Return Receipt Header";
    SourceTableView = sorting("Posting Date")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Sell-to Post Code"; Rec."Sell-to Post Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Sell-to Country/Region Code"; Rec."Sell-to Country/Region Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Sell-to Contact"; Rec."Sell-to Contact")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Bill-to Contact"; Rec."Bill-to Contact")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies which salesperson is associated with the posted return receipts.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                    Visible = false;
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Visible = false;
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
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Return Receipt Header"),
                              "No." = field("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Return Rcpt.")
            {
                Caption = '&Return Rcpt.';
                Image = Receipt;
                action(Statistics)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Return Receipt Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = const("Posted Return Receipt"),
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
                ApplicationArea = SalesReturnOrder;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    ReturnRcptHeader := Rec;
                    OnBeforePrintRecords(Rec, ReturnRcptHeader);
                    CurrPage.SetSelectionFilter(ReturnRcptHeader);
                    ReturnRcptHeader.PrintRecords(true);
                end;
            }
            action(SendCustom)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send';
                Ellipsis = true;
                Image = SendToMultiple;
                ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens where you can confirm or select a sending profile.';

                trigger OnAction()
                var
                    ReturnRcptHeader: Record "Return Receipt Header";
                begin
                    ReturnRcptHeader := Rec;
                    CurrPage.SetSelectionFilter(ReturnRcptHeader);
                    ReturnRcptHeader.SendRecords();
                end;
            }
            action(Email)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send by &Email';
                Image = Email;
                ToolTip = 'Prepare to send the document by email. The Send Email window opens prefilled for the customer where you can add or change information before you send the email.';

                trigger OnAction()
                var
                    ReturnRcptHeader: Record "Return Receipt Header";
                begin
                    ReturnRcptHeader := Rec;
                    CurrPage.SetSelectionFilter(ReturnRcptHeader);
                    ReturnRcptHeader.EmailRecords(true);
                end;
            }
            action(AttachAsPDF)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attach as PDF';
                Image = PrintAttachment;
                ToolTip = 'Create a PDF file and attach it to the document.';

                trigger OnAction()
                var
                    ReturnRcptHeader: Record "Return Receipt Header";
                begin
                    ReturnRcptHeader := Rec;
                    CurrPage.SetSelectionFilter(ReturnRcptHeader);
                    Rec.PrintToDocumentAttachment(ReturnRcptHeader);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = SalesReturnOrder;
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
                ApplicationArea = SalesReturnOrder;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document, such as information from the shipping agent. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedReturnReceiptUpdate: Page "Posted Return Receipt - Update";
                begin
                    PostedReturnReceiptUpdate.LookupMode := true;
                    PostedReturnReceiptUpdate.SetRec(Rec);
                    PostedReturnReceiptUpdate.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("Update Document_Promoted"; "Update Document")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(Print_Promoted; "&Print")
                {
                }
                actionref(Email_Promoted; Email)
                {
                }
                actionref(SendCustom_Promoted; SendCustom)
                {
                }
                actionref(AttachAsPDF_Promoted; AttachAsPDF)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        HasFilters: Boolean;
    begin
        HasFilters := Rec.GetFilters() <> '';
        Rec.SetSecurityFilterOnRespCenter();
        if HasFilters and not Rec.Find() then
            if Rec.FindFirst() then;
    end;

    var
        ReturnRcptHeader: Record "Return Receipt Header";

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(ReturnReceiptHeaderRec: Record "Return Receipt Header"; var ReturnReceiptHeaderToPrint: Record "Return Receipt Header")
    begin
    end;
}

