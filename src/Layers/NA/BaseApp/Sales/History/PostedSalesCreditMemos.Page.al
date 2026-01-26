// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Reports;
using Microsoft.Utilities;

page 144 "Posted Sales Credit Memos"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Sales Credit Memos';
    CardPageID = "Posted Sales Credit Memo";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Posted Sales Credit Memos';
    AboutText = 'Review posted sales credit memos, including details of amounts, customer information, payment status, and related documents, to track reversals of sales invoices, returns, and cancellations. Filter and analyze credit memos by contract or other criteria to support financial reconciliation and customer account management.';
    QueryCategory = 'Posted Sales Credit Memos';
    SourceTable = "Sales Cr.Memo Header";
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
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Name';
                    ToolTip = 'Specifies the name of the customer that you shipped the items on the credit memo to.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code of the credit memo.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the shipment is due for payment.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the amounts on all the credit memo lines, in the currency of the credit memo. The amount does not include VAT.';

                    trigger OnDrillDown()
                    begin
                        DoDrillDown();
                    end;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the amounts, including VAT, on all the lines on the document.';

                    trigger OnDrillDown()
                    begin
                        DoDrillDown();
                    end;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be paid for the posted sales invoice.';
                }
                field(Paid; Rec.Paid)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the posted sales invoice that relates to this sales credit memo is paid.';
                }
                field(Cancelled; Rec.Cancelled)
                {
                    ApplicationArea = Basic, Suite;
                    HideValue = not Rec.Cancelled;
                    Style = Unfavorable;
                    StyleExpr = Rec.Cancelled;
                    ToolTip = 'Specifies if the posted sales invoice that relates to this sales credit memo has been either corrected or canceled.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowCorrectiveInvoice();
                    end;
                }
                field(Corrective; Rec.Corrective)
                {
                    ApplicationArea = Basic, Suite;
                    HideValue = not Rec.Corrective;
                    Style = Unfavorable;
                    StyleExpr = Rec.Corrective;
                    ToolTip = 'Specifies if the posted sales invoice has been either corrected or canceled by this sales credit memo.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowCancelledInvoice();
                    end;
                }
                field("Sell-to Post Code"; Rec."Sell-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the customer''s main address.';
                    Visible = false;
                }
                field("Sell-to Country/Region Code"; Rec."Sell-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the customer''s main address.';
                    Visible = false;
                }
                field("Sell-to Contact"; Rec."Sell-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the customer''s main address.';
                    Visible = false;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    Visible = false;
                }
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the customer''s billing address.';
                    Visible = false;
                }
                field("Bill-to Contact"; Rec."Bill-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
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
                    ToolTip = 'Specifies the date when the credit memo was posted.';
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which salesperson is associated with the credit memo.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location where the credit memo was registered.';
                }
                field("Electronic Document Status"; Rec."Electronic Document Status")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Date/Time Stamped"; Rec."Date/Time Stamped")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document received a digital stamp from the authorized service provider.';
                    Visible = false;
                }
                field("Date/Time Sent"; Rec."Date/Time Sent")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document was sent to the customer.';
                    Visible = false;
                }
                field("Date/Time Canceled"; Rec."Date/Time Canceled")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document was canceled.';
                    Visible = false;
                }
                field("Error Code"; Rec."Error Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the error code that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("Error Description"; Rec."Error Description")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the error message that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the document has been printed.';
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
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
                field("Document Exchange Status"; Rec."Document Exchange Status")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = DocExchStatusStyle;
                    ToolTip = 'Specifies the status of the document if you are using a document exchange service to send it as an electronic document. The status values are reported by the document exchange service.';
                    Visible = DocExchStatusVisible;

                    trigger OnDrillDown()
                    var
                        DocExchServDocStatus: Codeunit "Doc. Exch. Serv.- Doc. Status";
                    begin
                        DocExchServDocStatus.DocExchStatusDrillDown(Rec);
                    end;
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
                SubPageLink = "Table ID" = const(Database::"Sales Cr.Memo Header"), "No." = field("No.");
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Electronic Document")
            {
                Caption = '&Electronic Document';
                action("S&end")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic credit memo attached as an XML file.';

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                        ProgressWindow: Dialog;
                    begin
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        ProgressWindow.Open(ProcessingInvoiceMsg);
                        if SalesCrMemoHeader.FindSet() then
                            repeat
                                SalesCrMemoHeader.RequestStampEDocument();
                                ProgressWindow.Update(1, SalesCrMemoHeader."No.");
                            until SalesCrMemoHeader.Next() = 0;
                        ProgressWindow.Close();
                    end;
                }
                action("Export E-Document as &XML")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Export E-Document as &XML';
                    Image = ExportElectronicDocument;
                    ToolTip = 'Export the posted sales credit memo as an electronic credit memo, an XML file, and save it to a specified location.';

                    trigger OnAction()
                    begin
                        Rec.ExportEDocument();
                    end;
                }
                action(ExportEDocumentPDF)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Export E-Document as PDF';
                    Image = ExportToBank;
                    ToolTip = 'Export the posted sales credit memo as an electronic credit memo, a PDF document, when the stamp is received.';

                    trigger OnAction()
                    begin
                        Rec.ExportEDocumentPDF();
                    end;
                }
                action(CFDIRelationDocuments)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'CFDI Relation Documents';
                    Image = Allocations;
                    RunObject = Page "CFDI Relation Documents";
                    RunPageLink = "Document Table ID" = const(114),
                                  "Document No." = field("No."),
                                  "Customer No." = field("Bill-to Customer No.");
                    RunPageMode = View;
                    ToolTip = 'View or add CFDI relation documents for the record.';
                }
                action("&Cancel")
                {
                    ApplicationArea = BasicMX;
                    Caption = '&Cancel';
                    Image = Cancel;
                    ToolTip = 'Cancel the sending of the electronic credit memo invoice.';

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                        ProgressWindow: Dialog;
                    begin
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        ProgressWindow.Open(ProcessingInvoiceMsg);
                        if SalesCrMemoHeader.FindSet() then
                            repeat
                                SalesCrMemoHeader.CancelEDocument();
                                ProgressWindow.Update(1, SalesCrMemoHeader."No.");
                            until SalesCrMemoHeader.Next() = 0;
                        ProgressWindow.Close();
                    end;
                }
            }
            group("&Credit Memo")
            {
                Caption = '&Credit Memo';
                Image = CreditMemo;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the posted sales credit memo.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        PageManagement.PageRun(Rec);
                    end;
                }
#if not CLEAN27
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    ObsoleteReason = 'The statistics action will be replaced with the SalesCrMemoStatistics and SalesCrMemoStats actions. The new actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';

                    trigger OnAction()
                    begin
                        OnBeforeCalculateSalesTaxStatistics(Rec);
                        if Rec."Tax Area Code" = '' then
                            PAGE.RunModal(PAGE::"Sales Credit Memo Statistics", Rec, Rec."No.")
                        else
                            PAGE.RunModal(PAGE::"Sales Credit Memo Stats.", Rec, Rec."No.");
                    end;
                }
#endif
                action(SalesCrMemoStatistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
#if CLEAN27
                    Visible = not SalesCrMemoStatsVisible;
#else
                    Visible = false;
#endif
                    RunObject = PAGE "Sales Credit Memo Statistics";
                    RunPageOnRec = true;
                }
                action(SalesCrMemoStats)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
#if CLEAN27
                    Visible = SalesCrMemoStatsVisible;
#else
                    Visible = false;
#endif
                    RunObject = PAGE "Sales Credit Memo Stats.";
                    RunPageOnRec = true;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
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
                action(IncomingDoc)
                {
                    AccessByPermission = TableData "Incoming Document" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Incoming Document';
                    Image = Document;
                    ToolTip = 'View or create an incoming document record that is linked to the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        IncomingDocument.ShowCard(Rec."No.", Rec."Posting Date");
                    end;
                }
                action(Customer)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Sell-to Customer No.");
                    Scope = Repeater;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the customer.';
                }
                action("&Navigate")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    Scope = Repeater;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                    Visible = not IsOfficeAddin;

                    trigger OnAction()
                    begin
                        Rec.Navigate();
                    end;
                }
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
                    ToolTip = 'Create and post a sales invoice that reverses this posted sales credit memo. This posted sales credit memo will be canceled.';
                    Visible = not Rec.Cancelled and Rec.Corrective;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Cancel PstdSalesCrM (Yes/No)", Rec);
                    end;
                }
                action(ShowInvoice)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Canceled/Corrective Invoice';
                    Image = Invoice;
                    Scope = Repeater;
                    ToolTip = 'Open the posted sales invoice that was created when you canceled the posted sales credit memo. If the posted sales credit memo is the result of a canceled sales invoice, then canceled invoice will open.';
                    Visible = Rec.Cancelled or Rec.Corrective;

                    trigger OnAction()
                    begin
                        Rec.ShowCanceledOrCorrInvoice();
                    end;
                }
            }
            action("Sales - Credit Memo")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales - Credit Memo';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Report "Sales Credit Memo NA";
                ToolTip = 'View all sales credit memos. You can print on pre-printed credit memo forms, generic forms or on plain paper. The unit price quoted on this form is the direct price adjusted by any line discounts or other adjustments.';
            }
        }
        area(reporting)
        {
            action("Outstanding Sales Order Aging")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Outstanding Sales Order Aging';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Outstanding Sales Order Aging";
                ToolTip = 'View customer orders aged by their target shipping date. Only orders that have not been shipped appear on the report.';
            }
            action("Outstanding Sales Order Status")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Outstanding Sales Order Status';
                Image = "Report";
                RunObject = Report "Outstanding Sales Order Status";
                ToolTip = 'View detailed outstanding order information for each customer. This report includes shipping information, quantities ordered, and the amount that is back ordered.';
            }
            action("Daily Invoicing Report")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Daily Invoicing Report';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Daily Invoicing Report";
                ToolTip = 'View the total invoice or credit memo activity, or both. This report can be run for a particular day, or range of dates. The report shows one line for each invoice or credit memo. You can view the bill-to customer number, name, payment terms, salesperson code, amount, sales tax, amount including tax, and total of all invoices or credit memos.';
            }
            group(Send)
            {
                Caption = 'Send';
                action(SendCustom)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send';
                    Ellipsis = true;
                    Image = SendToMultiple;
                    Scope = Repeater;
                    ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens where you can confirm or select a sending profile.';

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    begin
                        SalesCrMemoHeader := Rec;
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        SalesCrMemoHeader.SendRecords();
                    end;
                }
                action("&Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Print';
                    Ellipsis = true;
                    Image = Print;
                    Scope = Repeater;
                    ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';
                    Visible = not IsOfficeAddin;

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    begin
                        SalesCrMemoHeader := Rec;
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        OnBeforePrintRecords(SalesCrMemoHeader);
                        SalesCrMemoHeader.PrintRecords(true);
                    end;
                }
                action("Send by &Email")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send by &Email';
                    Image = Email;
                    Scope = Repeater;
                    ToolTip = 'Prepare to send the document by email. The Send Email window opens prefilled for the customer where you can add or change information before you send the email.';

                    trigger OnAction()
                    var
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    begin
                        SalesCrMemoHeader := Rec;
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        SalesCrMemoHeader.EmailRecords(true);
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
                        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    begin
                        SalesCrMemoHeader := Rec;
                        CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                        Rec.PrintToDocumentAttachment(SalesCrMemoHeader);
                    end;
                }
            }
            action(ActivityLog)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Activity Log';
                Image = Log;
                ToolTip = 'View the status and any errors if the document was sent as an electronic document or OCR file through the document exchange service.';

                trigger OnAction()
                begin
                    Rec.ShowActivityLog();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("Send by &Email_Promoted"; "Send by &Email")
                {
                }
                actionref(SendCustom_Promoted; SendCustom)
                {
                }
                actionref(AttachAsPDF_Promoted; AttachAsPDF)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Credit Memo', Comment = 'Generated from the PromotedActionCategories property index 3.';
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
#if not CLEAN27
                actionref(Statistics_Promoted; Statistics)
                {
                    ObsoleteReason = 'The statistics action will be replaced with the SalesCrMemoStatistics and SalesCrMemoStats actions. The new actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#else
                actionref(SalesCrMemoStatistics_Promoted; SalesCrMemoStatistics)
                {
                }
                actionref(SalesCrMemoStats_Promoted; SalesCrMemoStats)
                {
                }
#endif
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(ActivityLog_Promoted; ActivityLog)
                {
                }
                separator(Navigate_Separator)
                {
                }
                actionref(IncomingDoc_Promoted; IncomingDoc)
                {
                }
                actionref(Customer_Promoted; Customer)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Cancel', Comment = 'Generated from the PromotedActionCategories property index 4.';
                ShowAs = SplitButton;

                actionref(CancelCrMemo_Promoted; CancelCrMemo)
                {
                }
                actionref(ShowInvoice_Promoted; ShowInvoice)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Outstanding Sales Order Status_Promoted"; "Outstanding Sales Order Status")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        if DocExchStatusVisible then
            DocExchStatusStyle := Rec.GetDocExchStatusStyle();
    end;

    trigger OnOpenPage()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OfficeMgt: Codeunit "Office Management";
        HasFilters: Boolean;
    begin
        HasFilters := Rec.GetFilters() <> '';
        Rec.SetSecurityFilterOnRespCenter();
        if HasFilters and not Rec.Find() then
            if Rec.FindFirst() then;
        IsOfficeAddin := OfficeMgt.IsAvailable();
        SalesCrMemoHeader.CopyFilters(Rec);
        SalesCrMemoHeader.SetFilter("Document Exchange Status", '<>%1', Rec."Document Exchange Status"::"Not Sent");
        DocExchStatusVisible := not SalesCrMemoHeader.IsEmpty();
        SalesCrMemoStatsVisible := Rec."Tax Area Code" <> '';
    end;

    local procedure DoDrillDown()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PageManagement: Codeunit "Page Management";
    begin
        SalesCrMemoHeader.Copy(Rec);
        SalesCrMemoHeader.SetRange("No.");
        PageManagement.PageRun(SalesCrMemoHeader);
    end;

    var
        DocExchStatusStyle: Text;
        DocExchStatusVisible: Boolean;
        IsOfficeAddin: Boolean;
        ProcessingInvoiceMsg: Label 'Processing record #1#######', Comment = '%1 = Record no';

    protected var
        SalesCrMemoStatsVisible: Boolean;

#if not CLEAN27
    [Obsolete('The statistics action will be replaced with the SalesCrMemoStatistics and SalesCrMemoStats actions. The new actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
    end;
}