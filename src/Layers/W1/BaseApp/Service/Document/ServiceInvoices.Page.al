// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Posting;

page 9319 "Service Invoices"
{
    ApplicationArea = Service;
    Caption = 'Service Invoices';
    CardPageID = "Service Invoice";
    DataCaptionFields = "Customer No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Header";
    SourceTableView = where("Document Type" = const(Invoice));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Service;
                }
                field("Order Time"; Rec."Order Time")
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a document number that refers to the customer''s numbering system.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
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
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Service;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Service;
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Service Header"),
                              "No." = field("No."),
                              "Document Type" = field("Document Type");
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = true;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
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
            group("&Invoice")
            {
                Caption = '&Invoice';
                Image = Invoice;
#if not CLEAN27
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    ObsoleteReason = 'The statistics action will be replaced with the ServiceStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';

                    trigger OnAction()
                    begin
                        Rec.OpenStatistics();
                    end;
                }
#endif
                action(ServiceStatistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
#if CLEAN27
                    Visible = true;
#else
                    Visible = false;
#endif
                    RunObject = Page "Service Statistics";
                    RunPageOnRec = true;
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Header"),
                                  "Table Subtype" = field("Document Type"),
                                  "No." = field("No."),
                                  Type = const(General);
                    ToolTip = 'View or add comments for the record.';
                }
                action("&Dimensions")
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = '&Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                    end;
                }
                action("Service Document Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Document Lo&g';
                    Image = Log;
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';

                    trigger OnAction()
                    var
                        TempServDocLog: Record "Service Document Log" temporary;
                    begin
                        TempServDocLog.Reset();
                        TempServDocLog.DeleteAll();
                        TempServDocLog.CopyServLog(TempServDocLog."Document Type"::Invoice.AsInteger(), Rec."No.");

                        TempServDocLog.Reset();
                        TempServDocLog.SetCurrentKey("Change Date", "Change Time");
                        TempServDocLog.Ascending(false);

                        PAGE.Run(0, TempServDocLog);
                    end;
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Service;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        Rec.SendToPost(Codeunit::"Service-Post (Yes/No)");
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = Service;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    var
                        SelectedServiceHeader: Record "Service Header";
                        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
                    begin
                        CurrPage.SetSelectionFilter(SelectedServiceHeader);
                        ServPostYesNo.MessageIfPostingPreviewMultipleDocuments(SelectedServiceHeader, Rec."No.");
                        ServPostYesNo.PreviewDocument(Rec);
                    end;
                }
                action(PostAndSend)
                {
                    ApplicationArea = Service;
                    Caption = 'Post and &Send';
                    Ellipsis = true;
                    Image = PostSendTo;
                    ToolTip = 'Finalize and prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                    trigger OnAction()
                    begin
                        Rec.SendToPost(Codeunit::"Service-Post and Send");
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Service;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        Rec.SendToPost(Codeunit::"Service-Post+Print");
                    end;
                }
                action("Post &Batch")
                {
                    ApplicationArea = Service;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Service Invoices", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 3.';
                ShowAs = SplitButton;

                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref(PostAndSend_Promoted; PostAndSend)
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
                actionref("Post &Batch_Promoted"; "Post &Batch")
                {
                }
                actionref(Preview_Promoted; Preview)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Invoice', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("&Dimensions_Promoted"; "&Dimensions")
                {
                }
#if not CLEAN27
                actionref(Statistics_Promoted; Statistics)
                {
                    ObsoleteReason = 'The statistics action will be replaced with the ServiceStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#else
                actionref(ServiceStatistics_Promoted; ServiceStatistics)
                {
                }
#endif
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("Service Document Lo&g_Promoted"; "Service Document Lo&g")
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
        Rec.SetSecurityFilterOnRespCenter();

        Rec.CopyCustomerFilter();
    end;
}