// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
#if not CLEAN27
using Microsoft.Sales.Setup;
#endif
using Microsoft.Warehouse.Setup;
using System.Automation;
using System.Security.User;

page 10026 "Sales Order Shipment"
{
    Caption = 'Sales Order Shipment';
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
                    ToolTip = 'Specifies the number of the customer that you shipped the items to.';

                    trigger OnValidate()
                    begin
                        SelltoCustomerNoOnAfterValidat();
                    end;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that you shipped the items to.';
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the customer that the items are shipped to.';
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that the items are shipped to.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Posting DateEditable";
                    ToolTip = 'Specifies the date when the sales order was shipped.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Order DateEditable";
                    ToolTip = 'Specifies the date on which the related sales order was created.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Document DateEditable";
                    ToolTip = 'Specifies the date on which you created the sales document.';
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that your customer has requested to have the items delivered. The value in this field is used to calculate the shipment date, which is the date when the items must be available in inventory. If the customer does not request a date, leave the field blank, and the earliest possible date.';
                }
                field("Promised Delivery Date"; Rec."Promised Delivery Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the delivery date that you promised the customer for the items on this line as a result of the Order Promising function.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Salesperson CodeEditable";
                    ToolTip = 'Specifies the salesperson that is assigned to the order.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code that the sales line is associated with.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the dimension value code that the sales line is associated with.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("On Hold"; Rec."On Hold")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the document was put on hold when it was posted, for example because payment of the resulting customer ledger entries is overdue.';
                }
            }
            part(SalesLines; "Sales Order Shipment Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Ship-to CodeEditable";
                    ToolTip = 'Specifies the address that items were shipped to. This field is used when multiple the customer has multiple ship-to addresses.';
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Ship-to NameEditable";
                    ToolTip = 'Specifies the name of the customer at the address that the items were shipped to.';
                }
                field("Ship-to Address"; Rec."Ship-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Ship-to AddressEditable";
                    ToolTip = 'Specifies the address that the items were shipped to.';
                }
                field("Ship-to Address 2"; Rec."Ship-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Ship-to Address 2Editable";
                    ToolTip = 'Specifies an additional part of the address that the items were shipped to.';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Ship-to CityEditable";
                    ToolTip = 'Specifies the city that the items were shipped to.';
                }
                field("Ship-to County"; Rec."Ship-to County")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ship-to State / ZIP Code';
                    Editable = "Ship-to CountyEditable";
                    ToolTip = 'Specifies the ship-state, ZIP code, ship-to province code, state code, postal code, or ZIP code as a part of the address.';
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Ship-to Post CodeEditable";
                    ToolTip = 'Specifies the post code at the address that the items were shipped to.';
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Ship-to ContactEditable";
                    ToolTip = 'Specifies the contact person at the address that the items were shipped to.';
                }
                field("Ship-to UPS Zone"; Rec."Ship-to UPS Zone")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a UPS Zone code for this document, if UPS is used for shipments.';
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Tax Area CodeEditable";
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                }
                field(FreightAmount; FreightAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Freight Amount';
                    ToolTip = 'Specifies the freight amount for the shipment. When you create a sales order, you can specify freight charges as item charges on the sales order, or you can specify the freight charges in the Sales Order Shipment window.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Location CodeEditable";
                    ToolTip = 'Specifies the location from where inventory items are to be shipped by default, to the customer on the sales document.';
                }
                field("Outbound Whse. Handling Time"; Rec."Outbound Whse. Handling Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the outbound warehouse handling time, which is used to calculate the planned shipment date.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Shipment Method CodeEditable";
                    ToolTip = 'Specifies how items on the sales document are shipped to the customer. By default, the field is filled with the value in the Shipment Method Code field on the customer card.';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Shipping Agent CodeEditable";
                    ToolTip = 'Specifies which shipping company will be used when you ship items to the customer.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the shipping agent service to use for this customer.';
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the shipping time of the order. That is, the time it takes from when the order is shipped from the warehouse to when the order is delivered to the customer''s address.';
                }
                field("Late Order Shipping"; Rec."Late Order Shipping")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the shipment of one or more lines has been delayed, or that the shipment date is before the work date.';
                }
                field("Package Tracking No."; Rec."Package Tracking No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Package Tracking No.Editable";
                    ToolTip = 'Specifies the shipping agent''s package number.';
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = "Shipment DateEditable";
                    ToolTip = 'Specifies the date when the items were shipped.';
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the customer accepts partial shipment of orders. If you select Partial, then the Qty. To Ship field can be lower than the Quantity field on sales lines.  ';
                }
            }
        }
        area(factboxes)
        {
            part(Control1903720907; "Sales Hist. Sell-to FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "No." = field("Sell-to Customer No.");
                Visible = true;
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "No." = field("Bill-to Customer No.");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "No." = field("Sell-to Customer No.");
                Visible = true;
            }
            part(Control1906127307; "Sales Line FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Provider = SalesLines;
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Line No." = field("Line No.");
                Visible = true;
            }
            part(Control1901314507; "Item Invoicing FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Provider = SalesLines;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part(Control1906354007; "Approval FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Table ID" = const(36),
                              "Document Type" = field("Document Type"),
                              "Document No." = field("No."),
                              Status = const(Open);
                Visible = true;
            }
            part(Control1901796907; "Item Warehouse FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Provider = SalesLines;
                SubPageLink = "No." = field("No.");
                Visible = false;
            }
            part(Control1907234507; "Sales Hist. Bill-to FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "No." = field("Bill-to Customer No.");
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Editable = true;
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
#if not CLEAN27
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    ObsoleteReason = 'The statistics action will be replaced with the SalesOrderStatistics and SalesOrderStats actions. The new actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';


                    trigger OnAction()
                    begin
                        SalesSetup.Get();
                        if SalesSetup."Calc. Inv. Discount" then begin
                            CurrPage.SalesLines.PAGE.CalcInvDisc();
                            Commit();
                        end;
                        OnBeforeCalculateSalesTaxStatistics(Rec, true);
                        if Rec."Tax Area Code" = '' then
                            PAGE.RunModal(PAGE::"Sales Order Statistics", Rec)
                        else
                            PAGE.RunModal(PAGE::"Sales Order Stats.", Rec)
                    end;
                }
#endif
                action(SalesOrderStatistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
#if CLEAN27
                    Visible = not SalesOrderStatsVisible;
#else
                    Visible = false;
#endif
                    RunObject = Page "Sales Order Statistics";
                    RunPageOnRec = true;
                }
                action(SalesOrderStats)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
#if CLEAN27
                    Visible = not SalesOrderStatsVisible;
#else
                    Visible = false;
#endif
                    RunObject = Page "Sales Order Stats.";
                    RunPageOnRec = true;
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
                action("Order &Promising")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Order &Promising';
                    Image = OrderPromising;
                    ToolTip = 'View any order promising lines that are related to the shipment.';

                    trigger OnAction()
                    var
                        OrderPromisingLine: Record "Order Promising Line" temporary;
                    begin
                        OrderPromisingLine.SetRange("Source Type", Rec."Document Type");
                        OrderPromisingLine.SetRange("Source ID", Rec."No.");
                        PAGE.RunModal(PAGE::"Order Promising Lines", OrderPromisingLine);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Sales Shipment per Package")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Shipment per Package';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Sales Shipment per Package";
                ToolTip = 'View sales shipment information for each package. Information includes shipment number, shipment date, number of units, items shipped, items ordered, and items placed on back order.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
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
#if not CLEAN27
                        OnBeforeCalculateSalesTaxStatistics(Rec, false);
#endif
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

                            SalesLine.Validate("Document Type", Rec."Document Type");
                            SalesLine.Validate("Document No.", Rec."No.");
                            SalesLine.InsertFreightLine(FreightAmount);
                            CODEUNIT.Run(CODEUNIT::"Ship-Post (Yes/No)", Rec);
                            if Rec."Shipping No." = '-1' then
                                Error('');
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

                            SalesLine.Validate("Document Type", Rec."Document Type");
                            SalesLine.Validate("Document No.", Rec."No.");
                            SalesLine.InsertFreightLine(FreightAmount);
                            CODEUNIT.Run(CODEUNIT::"Ship-Post + Print", Rec);
                            if Rec."Shipping No." = '-1' then
                                Error('');
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
#if not CLEAN27
                actionref(Statistics_Promoted; Statistics)
                {
                    ObsoleteReason = 'The statistics action will be replaced with the SalesOrderStatistics and SalesOrderStats actions. The new actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif
                actionref(SalesOrderStatistics_Promoted; SalesOrderStatistics)
                {
                }
                actionref(SalesOrderStats_Promoted; SalesOrderStats)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord();
        exit(Rec.ConfirmDeletion());
    end;

    trigger OnInit()
    begin
        "Tax Area CodeEditable" := true;
        "Package Tracking No.Editable" := true;
        "Shipment Method CodeEditable" := true;
        "Shipping Agent CodeEditable" := true;
        "Shipment DateEditable" := true;
        "Location CodeEditable" := true;
        "Ship-to CountyEditable" := true;
        "Ship-to CodeEditable" := true;
        "Ship-to Post CodeEditable" := true;
        "Ship-to ContactEditable" := true;
        "Ship-to CityEditable" := true;
        "Ship-to Address 2Editable" := true;
        "Ship-to AddressEditable" := true;
        "Ship-to NameEditable" := true;
        "Document DateEditable" := true;
        "Salesperson CodeEditable" := true;
        "Posting DateEditable" := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Responsibility Center" := UserMgt.GetSalesFilter();
        AfterGetCurrentRecord();
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetSalesFilter() <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetRange("Responsibility Center", UserMgt.GetSalesFilter());
            Rec.FilterGroup(0);
        end;

        Rec.SetRange("Date Filter", 0D, WorkDate() - 1);
        SalesOrderStatsVisible := Rec."Tax Area Code" <> '';
    end;

    var
        Text000: Label 'Unable to run this function while in View mode.';
        SalesLine: Record "Sales Line";
        ReportPrint: Codeunit "Test Report-Print";
#if not CLEAN27
        SalesSetup: Record "Sales & Receivables Setup";
#endif
        UserMgt: Codeunit "User Setup Management";
        Text001: Label 'There are non posted Prepayment Amounts on %1 %2.';
        Text002: Label 'There are unpaid Prepayment Invoices related to %1 %2.';
        "Posting DateEditable": Boolean;
        "Order DateEditable": Boolean;
        "Salesperson CodeEditable": Boolean;
        "Document DateEditable": Boolean;
        "Ship-to NameEditable": Boolean;
        "Ship-to AddressEditable": Boolean;
        "Ship-to Address 2Editable": Boolean;
        "Ship-to CityEditable": Boolean;
        "Ship-to ContactEditable": Boolean;
        "Ship-to Post CodeEditable": Boolean;
        "Ship-to CodeEditable": Boolean;
        "Ship-to CountyEditable": Boolean;
        "Location CodeEditable": Boolean;
        "Shipment DateEditable": Boolean;
        "Shipping Agent CodeEditable": Boolean;
        "Shipment Method CodeEditable": Boolean;
        "Package Tracking No.Editable": Boolean;
        "Tax Area CodeEditable": Boolean;

    protected var
        FreightAmount: Decimal;
        SalesOrderStatsVisible: Boolean;

    procedure UpdateAllowed(): Boolean
    begin
        if CurrPage.Editable = false then
            Error(Text000);
        exit(true);
    end;

    procedure OrderOnHold(OnHold: Boolean)
    begin
        "Posting DateEditable" := not OnHold;
        "Order DateEditable" := not OnHold;
        "Salesperson CodeEditable" := not OnHold;
        "Document DateEditable" := not OnHold;
        "Ship-to NameEditable" := not OnHold;
        "Ship-to AddressEditable" := not OnHold;
        "Ship-to Address 2Editable" := not OnHold;
        "Ship-to CityEditable" := not OnHold;
        "Ship-to ContactEditable" := not OnHold;
        "Ship-to Post CodeEditable" := not OnHold;
        "Ship-to CodeEditable" := not OnHold;
        "Ship-to CountyEditable" := not OnHold;
        // CurrForm."Ship-to UPS Zone".EDITABLE := NOT OnHold;
        "Location CodeEditable" := not OnHold;
        "Shipment DateEditable" := not OnHold;
        "Shipping Agent CodeEditable" := not OnHold;
        "Shipment Method CodeEditable" := not OnHold;
        "Package Tracking No.Editable" := not OnHold;
        "Tax Area CodeEditable" := not OnHold;

        CurrPage.SalesLines.PAGE.OrderOnHold(OnHold);
    end;

    local procedure SelltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update();
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        Rec.SetRange("Date Filter", 0D, WorkDate() - 1);

        OrderOnHold(Rec."On Hold" <> '');
    end;
#if not CLEAN27
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics and SalesOrderStats actions. The new actions use RunObject and do not run the action trigger. Use a page extension to modify the behaviour.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var SalesHeader: Record "Sales Header"; ShowDialog: Boolean)
    begin
    end;
#endif
}
