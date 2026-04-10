// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;

page 9317 "Service Quotes"
{
    ApplicationArea = Service;
    Caption = 'Service Quotes';
    CardPageID = "Service Quote";
    DataCaptionFields = "Customer No.";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Service Quotes';
    AboutText = 'Create and manage preliminary service quotes by entering customer details, service order types, and estimated costs, with the option to convert quotes into service orders for billing and fulfillment.';
    SourceTable = "Service Header";
    SourceTableView = where("Document Type" = const(Quote));
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
                field("Notify Customer"; Rec."Notify Customer")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
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
                field("Warning Status"; Rec."Warning Status")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Allocated Hours"; Rec."Allocated Hours")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Finishing Date"; Rec."Finishing Date")
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
            group("&Quote")
            {
                Caption = '&Quote';
                Image = Quote;
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
                action("Customer Card")
                {
                    ApplicationArea = Service;
                    Caption = 'Customer Card';
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information for the customer.';
                }
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
            }
        }
        area(processing)
        {
            action("Make &Order")
            {
                ApplicationArea = Service;
                Caption = 'Make &Order';
                Image = MakeOrder;
                ToolTip = 'Convert the service quote to a service order. The service order will contain the service quote number.';

                trigger OnAction()
                begin
                    CurrPage.Update();
                    Codeunit.Run(Codeunit::"Serv-Quote to Order (Yes/No)", Rec);
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Make &Order_Promoted"; "Make &Order")
                {
                }
                group(Category_CategoryPrint)
                {
                    ShowAs = SplitButton;

                    actionref("&Print_Promoted"; "&Print")
                    {
                    }
                    actionref(AttachAsPDF_Promoted; AttachAsPDF)
                    {
                    }
                }
                group(Category_Quote)
                {
                    Caption = 'Quote';

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
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();

        Rec.CopyCustomerFilter();
    end;
}