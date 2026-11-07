// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Comment;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;

page 36629 "Customer List - Collections"
{
    Caption = 'Customer List - Collections';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the record.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer.';
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    Editable = false;
                    ToolTip = 'Specifies the responsibility center.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the location code relating to the customer.';
                    Visible = false;
                }
                field("Post Code"; Rec."Post Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the postal code relating to the customer.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies a country/region code for the customer. This field is mostly used for registering EU VAT and reporting INTRASTAT.';
                    Visible = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ToolTip = 'Specifies the code for the payment method.';
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount on sales documents. By default, the payment term from the customer card is entered.';
                }
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    ToolTip = 'Specifies the code for the reminder terms.';
                    Visible = false;
                }
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ToolTip = 'Specifies the code for the finance charge terms calculated for the customer.';
                    Visible = false;
                }
                field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum credit (in LCY) that can be extended to the customer.';
                }
                field("Balance Due (LCY)"; Rec."Balance Due (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies payments from the customer that are overdue per today''s date.';
                }
                field("Balance on Date (LCY)"; Rec."Balance on Date (LCY)")
                {
                    Editable = false;
                    ToolTip = 'Specifies a balance amount in local currency.';
                    Visible = false;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the customer is blocked from posting.';
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer''s phone number.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ToolTip = 'Specifies the email address.';
                    Visible = false;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact person at the customer.';
                }
                field("Collection Method"; Rec."Collection Method")
                {
                    ToolTip = 'Specifies the method you normally use to collect payment from this customer, such as bank transfer or check.';
                    Visible = false;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ToolTip = 'Specifies the fax number for the customer.';
                    Visible = false;
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the code for the company''s intercompany (IC) partner.';
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the code for the salesperson.';
                    Visible = false;
                }
                field("Customer Price Group"; Rec."Customer Price Group")
                {
                    Editable = false;
                    ToolTip = 'Specifies the bill-to customer''s customer discount group. When you enter an item on the sales line, the code is used to check whether the bill-to customer should receive a sales line discount on the item.';
                    Visible = false;
                }
                field("Customer Disc. Group"; Rec."Customer Disc. Group")
                {
                    Editable = false;
                    ToolTip = 'Specifies the bill-to customer''s customer discount group. When you enter an item on the sales line, the code is used to check whether the bill-to customer should receive a sales line discount on the item.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the customer''s default currency.';
                    Visible = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    Editable = false;
                    ToolTip = 'Specifies the code for the language.';
                    Visible = false;
                }
                field("Sales (LCY)"; Rec."Sales (LCY)")
                {
                    Editable = false;
                    ToolTip = 'Specifies the sales, in local currency.';
                    Visible = false;
                }
                field("Profit (LCY)"; Rec."Profit (LCY)")
                {
                    Editable = false;
                    ToolTip = 'Specifies the profit, in local currency.';
                    Visible = false;
                }
                field("Search Name"; Rec."Search Name")
                {
                    Editable = false;
                    ToolTip = 'Specifies the search name.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(Control1904036507; "Customer Credit FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part(Control1901235907; "Comment Sheet Part")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Table Name" = const(Customer),
                              "No." = field("No.");
                Visible = true;
            }
            part(Control1904036707; "Order Header Status Factbox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = field("No.");
                Visible = true;
            }
            part(Control1904036807; "Order Lines Status Factbox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "Bill-to Customer No." = field("No.");
                Visible = true;
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
            part(Control1903720907; "Sales Hist. Sell-to FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
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
            group("&Customer")
            {
                Caption = '&Customer';
                Image = Customer;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    RunObject = Page "Customer Ledger Entries";
                    RunPageLink = "Customer No." = field("No."),
                                  "Posting Date" = field(upperlimit("Date Filter")),
                                  "Date Filter" = field("Date Filter");
                    RunPageView = sorting("Customer No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                group("Issued Documents")
                {
                    Caption = 'Issued Documents';
                    Image = History;
                    action("Issued &Reminders")
                    {
                        Caption = 'Issued &Reminders';
                        Image = OrderReminder;
                        RunObject = Page "Issued Reminder List";
                        RunPageLink = "Customer No." = field("No."),
                                      "Document Date" = field("Date Filter");
                        RunPageView = sorting("Customer No.", "Posting Date");
                        ToolTip = 'View the list of issued reminders.';
                    }
                    action("Issued &Finance Charge Memos")
                    {
                        Caption = 'Issued &Finance Charge Memos';
                        Image = FinChargeMemo;
                        RunObject = Page "Issued Fin. Charge Memo List";
                        RunPageLink = "Customer No." = field("No."),
                                      "Document Date" = field("Date Filter");
                        RunPageView = sorting("Customer No.", "Posting Date");
                        ToolTip = 'View the list of issued finance charge memos.';
                    }
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Customer),
                                  "No." = field("No.");
                    ToolTip = 'View comments that apply.';
                }
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    RunObject = Page "Customer Bank Account List";
                    RunPageLink = "Customer No." = field("No.");
                    ToolTip = 'View or set up the customer''s bank accounts. You can set up any number of bank accounts for each customer.';
                }
                action("C&ontact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    ToolTip = 'Open the card for the contact person at the customer.';

                    trigger OnAction()
                    begin
                        Rec.ShowContact();
                    end;
                }
                separator(Action59)
                {
                }
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Customer Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the customer collections list, for the record.';
                }
                action("Statistics by C&urrencies")
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics by C&urrencies';
                    Image = Currencies;
                    RunObject = Page "Cust. Stats. by Curr. Lines";
                    RunPageLink = "Customer Filter" = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Date Filter" = field("Date Filter");
                    ToolTip = 'View the customer''s statistics for each currency for which there are transactions.';
                }
                action("Entry Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry Statistics';
                    Image = EntryStatistics;
                    RunObject = Page "Customer Entry Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ToolTip = 'View statistics for customer ledger entries.';
                }
                action("S&ales")
                {
                    ApplicationArea = Suite;
                    Caption = 'S&ales';
                    Image = Sales;
                    RunObject = Page "Customer Sales";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Date Filter" = field("Date Filter");
                    ToolTip = 'View your sales to the customer by different periods.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange("Date Filter", 0D, WorkDate() - 1);
    end;

    procedure GetSelectionFilter(): Code[80]
    var
        Cust: Record Customer;
        FirstCust: Code[30];
        LastCust: Code[30];
        SelectionFilter: Code[250];
        CustCount: Integer;
        More: Boolean;
    begin
        CurrPage.SetSelectionFilter(Cust);
        CustCount := Cust.Count();
        if CustCount > 0 then begin
            Cust.Find('-');
            while CustCount > 0 do begin
                CustCount := CustCount - 1;
                Cust.MarkedOnly(false);
                FirstCust := Cust."No.";
                LastCust := FirstCust;
                More := (CustCount > 0);
                while More do
                    if Cust.Next() = 0 then
                        More := false
                    else
                        if not Cust.Mark() then
                            More := false
                        else begin
                            LastCust := Cust."No.";
                            CustCount := CustCount - 1;
                            if CustCount = 0 then
                                More := false;
                        end;
                if SelectionFilter <> '' then
                    SelectionFilter := SelectionFilter + '|';
                if FirstCust = LastCust then
                    SelectionFilter := SelectionFilter + FirstCust
                else
                    SelectionFilter := SelectionFilter + FirstCust + '..' + LastCust;
                if CustCount > 0 then begin
                    Cust.MarkedOnly(true);
                    Cust.Next();
                end;
            end;
        end;
        exit(SelectionFilter);
    end;

    procedure SetSelection(var Cust: Record Customer)
    begin
        CurrPage.SetSelectionFilter(Cust);
    end;
}

