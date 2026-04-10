// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using System.Automation;

/// <summary>
/// Displays a list of blanket sales orders for managing long-term customer agreements.
/// </summary>
page 9303 "Blanket Sales Orders"
{
    ApplicationArea = Suite;
    Caption = 'Blanket Sales Orders';
    CardPageID = "Blanket Sales Order";
    DataCaptionFields = "Sell-to Customer No.";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Blanket Sales Orders';
    AboutText = 'Manage long-term sales agreements with customers by tracking blanket sales orders, scheduling multiple shipments over time, and converting order lines into individual sales orders for fulfillment and invoicing.';
    QueryCategory = 'Blanket Sales Orders';
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const("Blanket Order"));
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
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the customer.';
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Suite;
                }
                field("Sell-to Post Code"; Rec."Sell-to Post Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Sell-to Country/Region Code"; Rec."Sell-to Country/Region Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Sell-to Contact"; Rec."Sell-to Contact")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bill-to Contact"; Rec."Bill-to Contact")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
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
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the sales person who is assigned to the customer.';
                    Visible = false;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether the record is open, waiting to be approved, invoiced for prepayment, or released to the next stage of processing.';
                    StyleExpr = StatusStyleTxt;
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
                SubPageLink = "Table ID" = const(Database::"Sales Header"),
                              "No." = field("No."),
                              "Document Type" = field("Document Type");
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Suite;
                SubPageLink = "No." = field("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Suite;
                SubPageLink = "No." = field("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
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
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action(SalesOrderStatistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Enabled = Rec."No." <> '';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    Visible = true;
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    RunObject = Page "Sales Order Statistics";
                    RunPageOnRec = true;
                }
                action(CustomerStatistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Statistics';
                    Image = Statistics;
                    RunObject = Page "Customer Statistics";
                    RunPageLink = "No." = field("Sell-to Customer No."),
                                  "Date Filter" = field("Date Filter");
                    ToolTip = 'View statistical information, such as the value of posted entries, for the sell-to customer on the sales document.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = const("Blanket Order"),
                                  "No." = field("No."),
                                  "Document Line No." = const(0);
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
                        Rec.ShowDocDim();
                    end;
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OpenApprovalsSales(Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Re&lease")
                {
                    ApplicationArea = Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(SalesHeader);
                        Rec.PerformManualRelease(SalesHeader);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(SalesHeader);
                        Rec.PerformManualReopen(SalesHeader);
                    end;
                }
                action("Delete Invoiced Blanket")
                {
                    ApplicationArea = Suite;
                    Caption = 'Delete Invoiced Blanket Sales Orders';
                    Image = Delete;
                    RunObject = Report "Delete Invd Blnkt Sales Orders";
                    ToolTip = 'Delete orders that were not automatically deleted after completion. For example, when several sales orders were completed by a single invoice.';
                }
            }
            action("Make &Order")
            {
                ApplicationArea = Suite;
                Caption = 'Make &Order';
                Image = MakeOrder;
                ToolTip = 'Convert the blanket sales order to a sales order.';

                trigger OnAction()
                var
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then
                        CODEUNIT.Run(CODEUNIT::"Blnkt Sales Ord. to Ord. (Y/N)", Rec);
                end;
            }
            action(Print)
            {
                ApplicationArea = Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    DocPrint.PrintSalesHeader(Rec);
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
                    SalesHeader: Record "Sales Header";
                    DocPrint: Codeunit "Document-Print";
                begin
                    SalesHeader := Rec;
                    CurrPage.SetSelectionFilter(SalesHeader);
                    DocPrint.PrintSalesHeaderToDocumentAttachment(SalesHeader);
                end;
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                action(SendApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = not OpenApprovalEntriesExist;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval of the document.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckSalesApprovalPossible(Rec) then
                            ApprovalsMgmt.OnSendSalesDocForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelSalesApprovalRequest(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Make &Order_Promoted"; "Make &Order")
                {
                }
            }
            group(Category_Release)
            {
                Caption = 'Release';
                ShowAs = SplitButton;

                actionref("Re&lease_Promoted"; "Re&lease")
                {
                }
                actionref("Re&open_Promoted"; "Re&open")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Print_Promoted; Print)
                {
                }
                actionref(AttachAsPDF_Promoted; AttachAsPDF)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category6)
            {
                Caption = 'Order', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(SalesOrderStatistics_Promoted; SalesOrderStatistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StatusStyleTxt := Rec.GetStatusStyleText();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetControlAppearance();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();

        Rec.CopySellToCustomerFilter();
    end;

    var
        DocPrint: Codeunit "Document-Print";
        OpenApprovalEntriesExist: Boolean;
        CanCancelApprovalForRecord: Boolean;
        StatusStyleTxt: Text;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);

        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId);
    end;
}