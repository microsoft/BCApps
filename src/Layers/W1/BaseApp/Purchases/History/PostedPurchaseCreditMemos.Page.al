// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Vendor;

page 147 "Posted Purchase Credit Memos"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Purchase Credit Memos';
    CardPageID = "Posted Purchase Credit Memo";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Posted Purchase Credit Memos';
    AboutText = 'Review and track posted purchase credit memos, including vendor details, amounts, payment status, and related documents, to manage supplier returns and corrections in your purchasing process.';
    QueryCategory = 'Posted Purchase Credit Memos';
    SourceTable = "Purch. Cr. Memo Hdr.";
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
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DoDrillDown();
                    end;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    begin
                        DoDrillDown();
                    end;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Paid; Rec.Paid)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Cancelled; Rec.Cancelled)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Posted Purchase Invoices";
                    Editable = false;
                    HideValue = not Rec.Cancelled;
                    LookupPageID = "Posted Purchase Invoices";
                    Style = Unfavorable;
                    StyleExpr = Rec.Cancelled;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowCorrectiveInvoice();
                    end;
                }
                field(Corrective; Rec.Corrective)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Posted Purchase Invoices";
                    Editable = false;
                    HideValue = not Rec.Corrective;
                    LookupPageID = "Posted Purchase Invoices";
                    Style = Unfavorable;
                    StyleExpr = Rec.Corrective;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowCancelledInvoice();
                    end;
                }
                field("Buy-from Post Code"; Rec."Buy-from Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Buy-from Country/Region Code"; Rec."Buy-from Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the vendor who delivered the items.';
                    Visible = false;
                }
                field("Buy-from Contact"; Rec."Buy-from Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Pay-to Name"; Rec."Pay-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor who you received the invoice from.';
                    Visible = false;
                }
                field("Pay-to Post Code"; Rec."Pay-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Pay-to Country/Region Code"; Rec."Pay-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the address.';
                    Visible = false;
                }
                field("Pay-to Contact"; Rec."Pay-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Suite;
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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Purch. Cr. Memo Hdr."),
                              "No." = field("No.");
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = not IsOfficeAddin;
            }
            part(GLEntriesPart; "G/L Entries Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Related G/L Entries';
                ShowFilter = false;
                SubPageLink = "Posting Date" = field("Posting Date"), "Document No." = field("No.");
            }
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
            group("&Cr. Memo")
            {
                Caption = '&Cr. Memo';
                Image = CreditMemo;
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Purch. Credit Memo Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = const("Posted Credit Memo"),
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
            action(Vendor)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor';
                Image = Vendor;
                RunObject = Page "Vendor Card";
                RunPageLink = "No." = field("Buy-from Vendor No.");
                Scope = Repeater;
                ShortCutKey = 'Shift+F7';
                ToolTip = 'View or edit detailed information about the vendor on the purchase document.';
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';
                Visible = not IsOfficeAddin;

                trigger OnAction()
                var
                    PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                begin
                    PurchCrMemoHdr := Rec;
                    CurrPage.SetSelectionFilter(PurchCrMemoHdr);
                    OnBeforePrintRecords(PurchCrMemoHdr);
                    PurchCrMemoHdr.PrintRecords(true);
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
                    PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
                begin
                    PurchCrMemoHdr := Rec;
                    CurrPage.SetSelectionFilter(PurchCrMemoHdr);
                    Rec.PrintToDocumentAttachment(PurchCrMemoHdr);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                Visible = not IsOfficeAddin;

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action("Update Document")
            {
                ApplicationArea = Suite;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PstdPurchCrMemoUpdate: Page "Pstd. Purch. Cr.Memo - Update";
                begin
                    PstdPurchCrMemoUpdate.LookupMode := true;
                    PstdPurchCrMemoUpdate.SetRec(Rec);
                    PstdPurchCrMemoUpdate.RunModal();
                end;
            }
            group(Cancel)
            {
                Caption = 'Cancel';
                action(CancelCrMemo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel';
                    Image = Cancel;
                    Scope = Repeater;
                    ToolTip = 'Create and post a purchase invoice that reverses this posted purchase credit memo. This posted purchase credit memo will be canceled.';
                    Visible = not Rec.Cancelled and Rec.Corrective;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Cancel PstdPurchCrM (Yes/No)", Rec);
                    end;
                }
                action(ShowInvoice)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Canceled/Corrective Invoice';
                    Image = Invoice;
                    Scope = Repeater;
                    ToolTip = 'Open the posted purchase invoice that was created when you canceled the posted purchase credit memo. If the posted purchase credit memo is the result of a canceled purchase invoice, then canceled invoice will open.';
                    Visible = Rec.Cancelled or Rec.Corrective;

                    trigger OnAction()
                    begin
                        Rec.ShowCanceledOrCorrInvoice();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref(CancelCrMemo_Promoted; CancelCrMemo)
                {
                }
                actionref(ShowInvoice_Promoted; ShowInvoice)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref(AttachAsPDF_Promoted; AttachAsPDF)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Cancel', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Category7)
            {
                Caption = 'Credit Memo', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(Vendor_Promoted; Vendor)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
    end;

    trigger OnOpenPage()
    var
        OfficeMgt: Codeunit "Office Management";
        HasFilters: Boolean;
    begin
        HasFilters := Rec.GetFilters() <> '';
        Rec.SetSecurityFilterOnRespCenter();
        if HasFilters and not Rec.Find() then
            if Rec.FindFirst() then;
        IsOfficeAddin := OfficeMgt.IsAvailable();
    end;

    local procedure DoDrillDown()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.Copy(Rec);
        PurchCrMemoHdr.SetRange("No.");
        PAGE.Run(PAGE::"Posted Purchase Credit Memo", PurchCrMemoHdr);
    end;

    var
        IsOfficeAddin: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.")
    begin
    end;
}
