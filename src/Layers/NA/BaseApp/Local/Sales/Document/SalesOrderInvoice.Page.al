// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Setup;
using System.Automation;
using System.Security.User;

page 10028 "Sales Order Invoice"
{
    Caption = 'Sales Order Invoice';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = filter(Order));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the customer that you invoiced the items to.';

                    trigger OnValidate()
                    begin
                        SelltoCustomerNoOnAfterValidat();
                    end;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that you invoiced the items to.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the sales order was invoiced.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the related sales order was created.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you created the sales document.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number that the customer uses in their own system to refer to this sales document. You can fill this field to use it later to search for sales lines using the customer''s order number.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the salesperson that is assigned to the order.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of amounts on the sales document. By default, the field is filled with the value in the Currency Code field on the customer card.';

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());
                            CurrPage.Update();
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the document.';
                }
            }
            part(SalesLines; "Sales Order Invoice Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer that the invoice is sent to.';

                    trigger OnValidate()
                    begin
                        BilltoCustomerNoOnAfterValidat();
                    end;
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer that the items are shipped to.';
                }
                field("Bill-to Address"; Rec."Bill-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the customer that the invoice is sent to.';
                }
                field("Bill-to Address 2"; Rec."Bill-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional part of the address of the customer that the invoice is sent to.';
                }
                field("Bill-to City"; Rec."Bill-to City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city of the customer that the invoice is sent to.';
                }
                field("Bill-to County"; Rec."Bill-to County")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'State / ZIP Code';
                    ToolTip = 'Specifies the state or province code, and postal code, as a part of the address.';
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the post code of the of the customer that the invoice is sent to.';
                }
                field("Bill-to Contact"; Rec."Bill-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the contact at the customer that the invoice is sent to.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code that the sales line is associated with.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV();
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code that the sales line is associated with.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension2CodeOnAfterV();
                    end;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount on sales documents. By default, the payment term from the customer card is entered.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the sales invoice must be paid';
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment discount percent that is granted if the customer pays on or before the date entered in the Pmt. Discount Date field. The percentage is calculated from the Payment Terms Code field.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date the customer can pay the invoice and still receive a payment discount.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the customer must pay for products on the sales document. By default, the payment method is copied from the customer card.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Editable = false;
                Visible = false;
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        SalesSetup.Get();
                        if SalesSetup."Calc. Inv. Discount" then begin
                            CurrPage.SalesLines.PAGE.CalcInvDisc();
                            Commit()
                        end;
                        OnBeforeCalculateSalesTaxStatistics(Rec, true);
                        if Rec."Tax Area Code" = '' then
                            PAGE.RunModal(PAGE::"Sales Order Statistics", Rec)
                        else
                            PAGE.RunModal(PAGE::"Sales Order Stats.", Rec)
                    end;
                }
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Sell-to Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the card for the customer.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "No." = field("No.");
                    ToolTip = 'View comments that apply.';
                }
                action("S&hipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'S&hipments';
                    Image = Shipment;
                    RunObject = Page "Posted Sales Shipments";
                    RunPageLink = "Order No." = field("No.");
                    RunPageView = sorting("Order No.");
                    ToolTip = 'View posted sales shipments for the customer.';
                }
                action(Invoices)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    Image = Invoice;
                    RunObject = Page "Posted Sales Invoices";
                    RunPageLink = "Order No." = field("No.");
                    RunPageView = sorting("Order No.");
                    ToolTip = 'View the history of posted sales invoices that have been posted for the document.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
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
                action("Calculate &Invoice Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount for the entire document.';

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc();
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.Reopen(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        OnBeforeCalculateSalesTaxStatistics(Rec, false);
                        ReportPrint.PrintSalesHeader(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        PrepaymentMgt: Codeunit "Prepayment Mgt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then begin
                            if PrepaymentMgt.TestSalesPrepayment(Rec) then
                                Error(Text001, Rec."Document Type", Rec."No.");

                            if PrepaymentMgt.TestSalesPayment(Rec) then
                                Error(Text002, Rec."Document Type", Rec."No.");

                            CODEUNIT.Run(CODEUNIT::"Invoice-Post (Yes/No)", Rec);
                        end;
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        PrepaymentMgt: Codeunit "Prepayment Mgt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then begin
                            if PrepaymentMgt.TestSalesPrepayment(Rec) then
                                Error(Text001, Rec."Document Type", Rec."No.");

                            if PrepaymentMgt.TestSalesPayment(Rec) then
                                Error(Text002, Rec."Document Type", Rec."No.");

                            CODEUNIT.Run(CODEUNIT::"Invoice-Post + Print", Rec);
                        end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
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
        Rec."Responsibility Center" := UserMgt.GetSalesFilter();
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetSalesFilter() <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetRange("Responsibility Center", UserMgt.GetSalesFilter());
            Rec.FilterGroup(0);
        end;

        Rec.SetRange("Date Filter", 0D, WorkDate() - 1);
    end;

    var
        Text000: Label 'Unable to run this function while in View mode.';
        ReportPrint: Codeunit "Test Report-Print";
        SalesSetup: Record "Sales & Receivables Setup";
        ChangeExchangeRate: Page "Change Exchange Rate";
        UserMgt: Codeunit "User Setup Management";
        Text001: Label 'There are non posted Prepayment Amounts on %1 %2.';
        Text002: Label 'There are unpaid Prepayment Invoices related to %1 %2.';

    procedure UpdateAllowed(): Boolean
    begin
        if CurrPage.Editable = false then
            Error(Text000);
        exit(true);
    end;

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.SalesLines.PAGE.ApproveCalcInvDisc();
    end;

    local procedure SelltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update();
    end;

    local procedure BilltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update();
    end;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
    end;
}

