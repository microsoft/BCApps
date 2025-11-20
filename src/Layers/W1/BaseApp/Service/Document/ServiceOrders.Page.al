// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Email;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Service.Posting;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using System.Text;

page 9318 "Service Orders"
{
    ApplicationArea = Service;
    Caption = 'Service Orders';
    CardPageID = "Service Order";
    DataCaptionFields = "Customer No.";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Service Orders';
    AboutText = 'Create, track, and manage service orders for customer repairs and maintenance, including scheduling, item allocation, and monitoring order status, invoicing, and shipping details. View customer information, check item availability, and analyze service order statistics to ensure efficient service delivery.';
    SourceTable = "Service Header";
    SourceTableView = where("Document Type" = const(Order));
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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order status, which reflects the repair or maintenance status of all service items on the service order.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the order was created.';
                }
                field("Order Time"; Rec."Order Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when the service order was created.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the items in the service document.';
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer to whom the items on the document will be shipped.';
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
                    ToolTip = 'Specifies the code of the location (for example, warehouse or distribution center) of the items specified on the service item lines.';
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated date when work on the order should start, that is, when the service order status changes from Pending, to In Process.';
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated time when work on the order starts, that is, when the service order status changes from Pending, to In Process.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the priority of the service order.';
                }
                field("Release Status"; Rec."Release Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if items in the Service Lines window are ready to be handled in warehouse activities.';
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
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Notify Customer"; Rec."Notify Customer")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how the customer wants to receive notifications about service completion.';
                    Visible = false;
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of this service order.';
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contract associated with the order.';
                    Visible = false;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies when the invoice is due.';
                    Visible = false;
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of payment discount given, if the customer pays by the date entered in the Pmt. Discount Date field.';
                    Visible = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                    Visible = false;
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies information about whether the customer will accept a partial shipment of the order.';
                    Visible = false;
                }
                field("Warning Status"; Rec."Warning Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the response time warning status for the order.';
                    Visible = false;
                }
                field("Allocated Hours"; Rec."Allocated Hours")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours allocated to the items in this service order.';
                    Visible = false;
                }
                field("Expected Finishing Date"; Rec."Expected Finishing Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when service on the order is expected to be finished.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the service, that is, the date when the order status changes from Pending, to In Process for the first time.';
                    Visible = false;
                }
                field("Finishing Date"; Rec."Finishing Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the finishing date of the service, that is, the date when the Status field changes to Finished.';
                    Visible = false;
                }
                field("Service Time (Hours)"; Rec."Service Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total time in hours that the service specified in the order has taken.';
                    Visible = false;
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a customer reference, which will be used when printing service documents.';
                }
            }
        }
        area(factboxes)
        {
#if not CLEAN25
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ObsoleteTag = '25.0';
                ObsoleteState = Pending;
                ObsoleteReason = 'The "Document Attachment FactBox" has been replaced by "Doc. Attachment List Factbox", which supports multiple files upload.';
                ApplicationArea = Service;
                Caption = 'Attachments';
                Visible = false;
                SubPageLink = "Table ID" = const(Database::"Service Header"),
                              "No." = field("No."),
                              "Document Type" = field("Document Type");
            }
#endif
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
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action("&Customer Card")
                {
                    ApplicationArea = Service;
                    Caption = '&Customer Card';
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about the customer.';
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
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Order No." = field("No.");
                    RunPageView = sorting("Service Order No.", "Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open, Type);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("Email &Queue")
                {
                    ApplicationArea = Service;
                    Caption = 'Email &Queue';
                    Image = Email;
                    RunObject = Page "Service Email Queue";
                    RunPageLink = "Document Type" = const("Service Order"),
                                  "Document No." = field("No.");
                    RunPageView = sorting("Document Type", "Document No.");
                    ToolTip = 'View the list of emails that are waiting to be sent automatically to notify customers about their service item.';
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
            }
            group(Action17)
            {
                Caption = 'Statistics';
                Image = Statistics;
#if not CLEAN27
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    ObsoleteReason = 'The statistics action will be replaced with the ServiceOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';

                    trigger OnAction()
                    begin
                        Rec.OpenOrderStatistics();
                    end;
                }
#endif
                action(ServiceOrderStatistics)
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
                    RunObject = Page "Service Order Statistics";
                    RunPageOnRec = true;
                }

            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("S&hipments")
                {
                    ApplicationArea = Service;
                    Caption = 'S&hipments';
                    Image = Shipment;
                    RunObject = Page "Posted Service Shipments";
                    RunPageLink = "Order No." = field("No.");
                    RunPageView = sorting("Order No.");
                    ToolTip = 'View related posted service shipments.';
                }
                action(Invoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Invoices';
                    Image = Invoice;
                    ToolTip = 'View a list of ongoing service invoices for the order.';

                    trigger OnAction()
                    var
                        TempServiceInvoiceHeader: Record "Service Invoice Header" temporary;
                        ServiceGetShipment: Codeunit "Service-Get Shipment";
                    begin
                        ServiceGetShipment.GetServiceOrderInvoices(TempServiceInvoiceHeader, Rec."No.");
                        Page.Run(Page::"Posted Service Invoices", TempServiceInvoiceHeader);
                    end;
                }
            }
            group("W&arehouse")
            {
                Caption = 'W&arehouse';
                Image = Warehouse;
                action("Warehouse Shipment Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Shipment Lines';
                    Image = ShipmentLines;
                    RunObject = Page "Whse. Shipment Lines";
                    RunPageLink = "Source Type" = const(5902),
#pragma warning disable AL0603
                                  "Source Subtype" = field("Document Type"),
#pragma warning restore
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View ongoing warehouse shipments for the document, in advanced warehouse configurations.';
                }
                action("Whse. Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Pick Lines';
                    Image = PickLines;
                    RunObject = page "Warehouse Activity Lines";
                    RunPageLink = "Source Document" = const("Service Order"), "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.");
                    ToolTip = 'View ongoing warehouse picks for the document, in advanced warehouse configurations.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Service Document Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Document Lo&g';
                    Image = Log;
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';

                    trigger OnAction()
                    var
                        ServDocLog: Record "Service Document Log";
                    begin
                        ServDocLog.ShowServDocLog(Rec);
                    end;
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Order No." = field("No.");
                    RunPageView = sorting("Service Order No.", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
                action("&Job Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Project Ledger Entries';
                    Image = JobLedger;
                    RunObject = Page "Job Ledger Entries";
                    RunPageLink = "Service Order No." = field("No.");
                    RunPageView = sorting("Service Order No.", "Posting Date")
                                  where("Entry Type" = const(Usage));
                    ToolTip = 'View all the project ledger entries that result from posting transactions in the service document that involve a project.';
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Service;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    var
                        ServTestReportPrint: Codeunit "Serv. Test Report Print";
                    begin
                        ServTestReportPrint.PrintServiceHeader(Rec);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Service;
                    Caption = 'P&ost';
                    Ellipsis = true;
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
                        ServHeader.Get(Rec."Document Type", Rec."No.");
                        ServPostYesNo.PreviewDocument(ServHeader);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Service;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        Rec.SendToPost(Codeunit::"Service-Post+Print");
                    end;
                }
                action(PostBatch)
                {
                    ApplicationArea = Service;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    var
                        ServSelectionFilterMgt: Codeunit "Serv. Selection Filter Mgt.";
                    begin
                        Clear(ServHeader);

                        if Rec.GetFilters() <> '' then
                            ServHeader.CopyFilters(Rec)
                        else begin
                            CurrPage.SetSelectionFilter(ServHeader);
                            ServHeader.SetFilter("No.", ServSelectionFilterMgt.GetSelectionFilterForServiceHeader(ServHeader));
                        end;

                        ServHeader.SetRange(Status, ServHeader.Status::Finished);
                        REPORT.RunModal(REPORT::"Batch Post Service Orders", true, true, ServHeader);
                        CurrPage.Update(false);
                    end;
                }
                action("&Print")
                {
                    ApplicationArea = Service;
                    Caption = '&Print';
                    Ellipsis = true;
                    Image = Print;
                    ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        ServDocumentPrint: Codeunit "Serv. Document Print";
                    begin
                        CurrPage.Update(true);
                        ServDocumentPrint.PrintServiceHeader(Rec);
                    end;
                }
                action(AttachAsPDF)
                {
                    ApplicationArea = Service;
                    Caption = 'Attach as PDF';
                    Ellipsis = true;
                    Image = PrintAttachment;
                    ToolTip = 'Create a PDF file and attach it to the document.';

                    trigger OnAction()
                    var
                        ServiceHeader: Record "Service Header";
                        ServDocumentPrint: Codeunit "Serv. Document Print";
                    begin
                        ServiceHeader := Rec;
                        ServiceHeader.SetRecFilter();
                        ServDocumentPrint.PrintServiceHeaderToDocumentAttachment(ServiceHeader);
                    end;
                }
            }
            group(Action13)
            {
                Caption = 'W&arehouse';
                Image = Warehouse;
                action("Release to Ship")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Release to Ship';
                    Image = ReleaseShipment;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Signal to warehouse workers that the service item is ready to be picked and shipped to the customer''s address.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Reactivate the service order after it has been released for warehouse handling.';

                    trigger OnAction()
                    var
                        ReleaseServiceDocument: Codeunit "Release Service Document";
                    begin
                        ReleaseServiceDocument.PerformManualReopen(Rec);
                    end;
                }
                action("Create Whse Shipment")
                {
                    AccessByPermission = TableData "Warehouse Shipment Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Warehouse Shipment';
                    Image = NewShipment;
                    ToolTip = 'Prepare to pick and ship the service item.';

                    trigger OnAction()
                    var
                        ServGetSourceDocOutbound: Codeunit "Serv. Get Source Doc. Outbound";
                    begin
                        Rec.PerformManualRelease();
                        ServGetSourceDocOutbound.CreateFromServiceOrder(Rec);
                        if not Rec.Find('=><') then
                            Rec.Init();
                    end;
                }
            }
            action("Delete Invoiced Orders")
            {
                ApplicationArea = Service;
                Caption = 'Delete Invoiced Orders';
                Image = Delete;
                RunObject = Report "Delete Invoiced Service Orders";
                ToolTip = 'Delete orders that were not automatically deleted after completion. For example, when several service orders were completed by a single invoice.';
            }
        }
        area(Promoted)
        {
            group(Category_Category5)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 4.';
                ShowAs = SplitButton;

                actionref(Post_Promoted; Post)
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
                actionref(Preview_Promoted; Preview)
                {
                }
                actionref(PostBatch_Promoted; PostBatch)
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
                Caption = 'Warehouse', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Reopen_Promoted; Reopen)
                {
                }
                actionref("Release to Ship_Promoted"; "Release to Ship")
                {
                }
                actionref("Create Whse Shipment_Promoted"; "Create Whse Shipment")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Order', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref("&Dimensions_Promoted"; "&Dimensions")
                {
                }
#if not CLEAN27
                actionref(Statistics_Promoted; Statistics)
                {
                    ObsoleteReason = 'The statistics action will be replaced with the ServiceOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#else
                actionref(ServiceOrderStatistics_Promoted; ServiceOrderStatistics)
                {
                }
#endif
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("Service Document Lo&g_Promoted"; "Service Document Lo&g")
                {
                }
                actionref("S&hipments_Promoted"; "S&hipments")
                {
                }
                actionref(Invoices_Promoted; Invoices)
                {
                }
                actionref("Warehouse Shipment Lines_Promoted"; "Warehouse Shipment Lines")
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 7.';

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

    var
        ServHeader: Record "Service Header";
}
