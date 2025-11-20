// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank.Reconciliation;
using Microsoft.CRM.Contact;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Comment;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Setup;
using System.Automation;
using System.Email;
using System.Integration.PowerBI;
using System.Integration.Word;
using System.Text;

page 27 "Vendor List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vendors';
    CardPageID = "Vendor Card";
    Editable = false;
    PageType = List;
    QueryCategory = 'Vendor List';
    SourceTable = Vendor;
    UsageCategory = Lists;
    AdditionalSearchTerms = 'Supplier Profile, Vendor Profile, Supplier Data, Vendor View, Provider Details';

    AboutTitle = 'About vendors';
    AboutText = 'Here you overview all registered vendors that you purchase goods and services from. With [Vendor Templates](?page=1385 "Opens the Vendor Templates") you can quickly register new vendors having common details defined by the template.';

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
                    ToolTip = 'Specifies the unique number that identifies the vendor. You can assign numbers automatically based on a number series or assign them manually.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the vendor''s name that appears on all related documents. For companies, specify the company''s name here, and then add the relevant people as contacts that you link to this vendor.';
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies an additional part of the name.';
                    Visible = false;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor street address.';
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s city.';
                    Visible = false;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the warehouse location where items from the vendor must be received by default.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s telephone number.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s fax number.';
                    Visible = false;
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the vendor''s intercompany partner code.';
                    Visible = false;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the person you regularly contact when you do business with this vendor.';
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                    Visible = false;
                }
                field("Vendor Posting Group"; Rec."Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                    Visible = false;
                }
                field("Allow Multiple Posting Groups"; Rec."Allow Multiple Posting Groups")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if multiple posting groups can be used for posting business transactions for this vendor.';
                    Visible = IsAllowMultiplePostingGroupsVisible;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s trade type to link transactions made for this vendor with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    Visible = false;
                }
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the involved finance charges in case of late payment.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency code that is inserted by default when you create purchase documents or journal lines for the vendor.';
                    Visible = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                    Visible = false;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether transactions with this vendor are restricted. Use this field to control vendor activity, such as temporarily halting payments or fully blocking a vendor due to compliance or business decisions. The field can have one of the following values: (blank) - No restrictions, all transactions are allowed. All - All transactions with this vendor are blocked. You cannot create or post any documents or journals with the vendor. Payment - Only payment transactions are blocked. You can still create and post purchase documents, but you cannot make payments to the vendor.';
                    Visible = false;
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';
                    Visible = false;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the vendor card was last modified.';
                    Visible = false;
                }
                field("Application Method"; Rec."Application Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how to apply payments to entries for this vendor.';
                    Visible = false;
                }
                field("Location Code2"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the warehouse location where items from the vendor must be received by default.';
                    Visible = false;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                    Visible = false;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
                    Visible = false;
                }
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a customizable calendar for delivery planning that holds the vendor''s working days and holidays.';
                    Visible = false;
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total value of your completed purchases from the vendor in the current fiscal year. It is calculated from amounts including VAT on all completed purchase invoices and credit memos.';

                    trigger OnDrillDown()
                    begin
                        Rec.OpenVendorLedgerEntries(false);
                    end;
                }
                field("Balance Due (LCY)"; Rec."Balance Due (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total value of your unpaid purchases from the vendor in the current fiscal year. It is calculated from amounts including VAT on all open purchase invoices and credit memos.';

                    trigger OnDrillDown()
                    begin
                        Rec.OpenVendorLedgerEntries(true);
                    end;
                }
                field("Payments (LCY)"; Rec."Payments (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum of payments paid to the vendor.';
                }
                field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies that the vendor is coupled to an account in Dataverse.';
                    Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                }
            }
        }
        area(factboxes)
        {
            part(PowerBIEmbeddedReportPart; "Power BI Embedded Report Part")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
#if not CLEAN25
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ObsoleteTag = '25.0';
                ObsoleteState = Pending;
                ObsoleteReason = 'The "Document Attachment FactBox" has been replaced by "Doc. Attachment List Factbox", which supports multiple files upload.';
                ApplicationArea = All;
                Visible = false;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::Vendor), "No." = field("No.");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::Vendor), "No." = field("No.");
            }
            part(VendorDetailsFactBox; "Vendor Details FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No."),
                              "Currency Filter" = field("Currency Filter"),
                              "Date Filter" = field("Date Filter"),
                              "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                Visible = false;
            }
            part(VendorStatisticsFactBox; "Vendor Statistics FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No."),
                              "Currency Filter" = field("Currency Filter"),
                              "Date Filter" = field("Date Filter"),
                              "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
            }
            part(VendorHistBuyFromFactBox; "Vendor Hist. Buy-from FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No."),
                              "Currency Filter" = field("Currency Filter"),
                              "Date Filter" = field("Date Filter"),
                              "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
            }
            part(VendorHistPayToFactBox; "Vendor Hist. Pay-to FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Currency Filter" = field("Currency Filter"),
                              "Date Filter" = field("Date Filter"),
                              "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
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
            group("Ven&dor")
            {
                Caption = 'Ven&dor';
                Image = Vendor;
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action(DimensionsSingle)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = const(23),
                                      "No." = field("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action(DimensionsMultiple)
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            Vend: Record Vendor;
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Vend);
                            DefaultDimMultiple.SetMultiRecord(Vend, Rec.FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    RunObject = Page "Vendor Bank Account List";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'Open the list of the vendor''s bank accounts';
                }
                action("C&ontact")
                {
                    AccessByPermission = TableData Contact = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&ontact';
                    Image = ContactPerson;
                    ToolTip = 'View or edit detailed information about the contact person at the vendor.';

                    trigger OnAction()
                    begin
                        Rec.ShowContact();
                    end;
                }
                separator(Action55)
                {
                }
                action(OrderAddresses)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Order &Addresses';
                    Image = Addresses;
                    RunObject = Page "Order Address List";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'View or edit alternate addresses for the vendor.';
                }
                action(RemitAddresses)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remit Addresses';
                    Image = Addresses;
                    RunObject = Page "Remit Address List";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'View or edit alternate remit addresses for the vendor.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Vendor),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Item Refe&rences")
                {
                    AccessByPermission = TableData "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                    Caption = 'Item Refe&rences';
                    Image = Change;
                    RunObject = Page "Item References";
                    RunPageLink = "Reference Type" = const(Vendor),
                                  "Reference Type No." = field("No.");
                    RunPageView = sorting("Reference Type", "Reference Type No.");
                    ToolTip = 'Set up a customer''s or vendor''s own identification of the selected item. references to the customer''s item number means that the item number is automatically shown on sales documents instead of the number that you use.';
                }
                action(ApprovalEntries)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(Rec.RecordId);
                    end;
                }
            }
            group("&Purchases")
            {
                Caption = '&Purchases';
                Image = Purchasing;
                action(Items)
                {
                    ApplicationArea = Planning;
                    Caption = 'Items';
                    Image = Item;
                    RunObject = Page "Vendor Item Catalog";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ToolTip = 'Open the list of items that you trade in.';
                }
                action("Invoice &Discounts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Invoice &Discounts';
                    Image = CalculateInvoiceDiscount;
                    RunObject = Page "Vend. Invoice Discounts";
                    RunPageLink = Code = field("Invoice Disc. Code");
                    ToolTip = 'Set up different discounts that are applied to invoices for the vendor. An invoice discount is automatically granted to the vendor when the total on a sales invoice exceeds a certain amount.';
                }
                action(PriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Price Lists';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up purchase price lists for products that you buy from the vendor. An product price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, Enum::"Price Amount Type"::Any);
                    end;
                }
                action(PriceLines)
                {
                    AccessByPermission = TableData "Purchase Price Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Prices';
                    Image = Price;
                    Scope = Repeater;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up purchase price lines for products that you buy from the vendor. A product price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, Enum::"Price Amount Type"::Price);
                    end;
                }
                action(DiscountLines)
                {
                    AccessByPermission = TableData "Purchase Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Discounts';
                    Image = LineDiscount;
                    Scope = Repeater;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up different discounts for products that you buy from the vendor. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, Enum::"Price Amount Type"::Discount);
                    end;
                }
                action(PriceListsDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Lists (Discounts)';
                    Image = LineDiscount;
                    Visible = false;
                    ToolTip = 'View or set up different discounts for products that you buy from the vendor. An product discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                        AmountType: Enum "Price Amount Type";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, AmountType::Discount);
                    end;
                }
                action(Prices)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Prices';
                    Image = Price;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Purchase Prices";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ToolTip = 'View or set up different prices for items that you buy from the vendor. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action("Line Discounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Line Discounts';
                    Image = LineDiscount;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Purchase Line Discounts";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ToolTip = 'View or set up different discounts for items that you buy from the vendor. An item discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action("Prepa&yment Percentages")
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Prepa&yment Percentages';
                    Image = PrepaymentPercentages;
                    RunObject = Page "Purchase Prepmt. Percentages";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.");
                    ToolTip = 'View or edit the percentages of the price that can be paid as a prepayment. ';
                }
                action("Recurring Purchase Lines")
                {
                    ApplicationArea = Suite;
                    Caption = 'Recurring Purchase Lines';
                    Image = CodesList;
                    RunObject = Page "Standard Vendor Purchase Codes";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'View or edit recurring purchase lines for the vendor.';
                }
                action("Mapping Text to Account")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mapping Text to Account';
                    Image = MapAccounts;
                    RunObject = Page "Text-to-Account Mapping Wksh.";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'Page mapping text to account';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Administration;
                action(Quotes)
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                    Image = Quote;
                    RunObject = Page "Purchase Quotes";
                    RunPageLink = "Buy-from Vendor No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.");
                    ToolTip = 'View a list of ongoing purchase quotes.';
                }
                action(Orders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Orders';
                    Image = Document;
                    RunObject = Page "Purchase Order List";
                    RunPageLink = "Buy-from Vendor No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.");
                    ToolTip = 'View a list of ongoing purchase orders for the vendor.';
                }
                action("Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Purchase Return Order List";
                    RunPageLink = "Buy-from Vendor No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.");
                    ToolTip = 'Open the list of ongoing return orders.';
                }
                action("Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    Image = BlanketOrder;
                    RunObject = Page "Blanket Purchase Orders";
                    RunPageLink = "Buy-from Vendor No." = field("No.");
                    RunPageView = sorting("Document Type", "Buy-from Vendor No.");
                    ToolTip = 'Open the list of ongoing blanket orders.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Ledger E&ntries")
                {
                    ApplicationArea = Suite;
                    Caption = 'Ledger E&ntries';
                    Image = VendorLedger;
                    RunObject = Page "Vendor Ledger Entries";
                    RunPageLink = "Vendor No." = field("No.");
                    RunPageView = sorting("Vendor No.")
                                  order(descending);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Vendor Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action(Purchases)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchases';
                    Image = Purchase;
                    RunObject = Page "Vendor Purchases";
                    RunPageLink = "No." = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ToolTip = 'Shows a summary of vendor ledger entries. You select the time interval in the View by field. The Period column on the left contains a series of dates that are determined by the time interval you have selected.';
                }
                action("Entry Statistics")
                {
                    ApplicationArea = Suite;
                    Caption = 'Entry Statistics';
                    Image = EntryStatistics;
                    RunObject = Page "Vendor Entry Statistics";
                    RunPageLink = "No." = field("No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
                    ToolTip = 'View entry statistics for the record.';
                }
                action("Statistics by C&urrencies")
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics by C&urrencies';
                    Image = Currencies;
                    RunObject = Page "Vend. Stats. by Curr. Lines";
                    RunPageLink = "Vendor Filter" = field("No."),
                                  "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                  "Date Filter" = field("Date Filter");
                    ToolTip = 'View statistics for vendors that use multiple currencies.';
                }
                action("Item &Tracking Entries")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Entries';
                    Image = ItemTrackingLedger;
                    ToolTip = 'View serial, lot or package numbers that are assigned to items.';

                    trigger OnAction()
                    var
                        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                    begin
                        ItemTrackingDocMgt.ShowItemTrackingForEntity(2, Rec."No.", '', '', '');
                    end;
                }
                action("Sent Emails")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sent Emails';
                    Image = ShowList;
                    ToolTip = 'View a list of emails that you have sent to this vendor.';

                    trigger OnAction()
                    var
                        Email: Codeunit Email;
                    begin
                        Email.OpenSentEmails(Database::Vendor, Rec.SystemId);
                    end;
                }
            }
            group(ActionGroupCDS)
            {
                Caption = 'Dataverse';
                Image = Administration;
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;
                Enabled = (BlockedFilterApplied and (Rec.Blocked = Rec.Blocked::" ")) or not BlockedFilterApplied;
                action(CDSGotoAccount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Account';
                    Image = CoupledCustomer;
                    ToolTip = 'Open the coupled Dataverse account.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Rec.RecordId);
                    end;
                }
                action(CDSSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send or get updated data to or from Dataverse.';

                    trigger OnAction()
                    var
                        Vendor: Record Vendor;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        VendorRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Vendor);
                        Vendor.Next();

                        if Vendor.Count = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Vendor.RecordId)
                        else begin
                            VendorRecordRef.GetTable(Vendor);
                            CRMIntegrationManagement.UpdateMultipleNow(VendorRecordRef);
                        end
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dataverse record.';
                    action(ManageCDSCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dataverse account.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(MatchBasedCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Match-Based Coupling';
                        Image = CoupledCustomer;
                        ToolTip = 'Couple vendors to accounts in Dataverse based on criteria.';

                        trigger OnAction()
                        var
                            Vendor: Record Vendor;
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Vendor);
                            RecRef.GetTable(Vendor);
                            CRMIntegrationManagement.MatchBasedCoupling(RecRef);
                        end;
                    }
                    action(DeleteCDSCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dataverse account.';

                        trigger OnAction()
                        var
                            Vendor: Record Vendor;
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Vendor);
                            RecRef.GetTable(Vendor);
                            CRMCouplingManagement.RemoveCoupling(RecRef);
                        end;
                    }
                }
                group(Create)
                {
                    Caption = 'Create';
                    Image = "Report";
                    action(CreateInCRM)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Create Account in Dataverse';
                        Image = "Report";
                        ToolTip = 'Generate the account in the coupled Dataverse account.';

                        trigger OnAction()
                        var
                            Vendor: Record Vendor;
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CurrPage.SetSelectionFilter(Vendor);
                            CRMIntegrationManagement.CreateNewRecordsInCRM(Vendor);
                        end;
                    }
                    action(CreateFromCRM)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Create Vendor in Business Central';
                        Image = "Report";
                        ToolTip = 'Generate the vendor in the coupled Dataverse account.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.CreateNewVendorFromCRM();

                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for vendors.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
        }
        area(creation)
        {
            action(NewBlanketPurchaseOrder)
            {
                ApplicationArea = Suite;
                Caption = 'Blanket Purchase Order';
                Image = BlanketOrder;
                RunObject = Page "Blanket Purchase Order";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new blanket purchase order for the vendor.';
            }
            action(NewPurchaseQuote)
            {
                ApplicationArea = Suite;
                Caption = 'Purchase Quote';
                Image = Quote;
                RunObject = Page "Purchase Quote";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new purchase quote for the vendor.';
            }
            action(NewPurchaseInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Invoice';
                Image = NewPurchaseInvoice;
                RunObject = Page "Purchase Invoice";
                RunPageLink = "Buy-from Vendor No." = field("No."), "Document Type" = const(Invoice);
                RunPageMode = Create;
                ToolTip = 'Create a new purchase invoice for items or services.';
            }
            action(NewPurchaseOrder)
            {
                ApplicationArea = Suite;
                Caption = 'Purchase Order';
                Image = Document;
                RunObject = Page "Purchase Order";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new purchase order.';
            }
            action(NewPurchaseCrMemo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Credit Memo';
                Image = CreditMemo;
                RunObject = Page "Purchase Credit Memo";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new purchase credit memo to revert a posted purchase invoice.';
                AboutTitle = 'Create a new document';
                AboutText = 'Get started on a new credit memo, order, or other document for the vendor selected in the list';
            }
            action(NewPurchaseReturnOrder)
            {
                ApplicationArea = PurchReturnOrder;
                Caption = 'Purchase Return Order';
                Image = ReturnOrder;
                RunObject = Page "Purchase Return Order";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new purchase return order for the vendor.';
            }
        }
        area(processing)
        {
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = not OpenApprovalEntriesExist and CanRequestApprovalForFlow;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval to change the record.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckVendorApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendVendorForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = CanCancelApprovalForRecord or CanCancelApprovalForFlow;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.OnCancelVendorApprovalRequest(Rec);
                        WorkflowWebhookManagement.FindAndCancel(Rec.RecordId);
                    end;
                }
            }
            action("Payment Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment Journal';
                Image = PaymentJournal;
                RunObject = Page "Payment Journal";
                ToolTip = 'View or edit the payment journal where you can register payments to vendors.';
            }
            action("Purchase Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Journal';
                Image = Journals;
                RunObject = Page "Purchase Journal";
                ToolTip = 'Post any purchase transaction for the vendor. ';
            }
            action(ApplyTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Apply Template';
                Image = ApplyTemplate;
                ToolTip = 'Apply a template to update one or more entities with your standard settings for a certain type of entity.';

                trigger OnAction()
                var
                    Vendor: Record Vendor;
                    VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
                begin
                    CurrPage.SetSelectionFilter(Vendor);
                    VendorTemplMgt.UpdateVendorsFromTemplate(Vendor);
                end;
            }
            action(PayVendor)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Pay Vendor';
                Image = SuggestVendorPayments;
                RunObject = Page "Vendor Ledger Entries";
                RunPageLink = "Vendor No." = field("No."),
                              "Remaining Amount" = filter(< 0),
                              "Applies-to ID" = filter(''),
                              "Document Type" = filter(Invoice);
                ToolTip = 'Opens vendor ledger entries for the selected vendor with invoices that have not been paid yet.';
            }
            action(WordTemplate)
            {
                ApplicationArea = All;
                Caption = 'Apply Word Template';
                ToolTip = 'Apply a Word template on the selected records.';
                Image = Word;

                trigger OnAction()
                var
                    Vendor: Record Vendor;
                    WordTemplateSelectionWizard: Page "Word Template Selection Wizard";
                begin
                    CurrPage.SetSelectionFilter(Vendor);
                    WordTemplateSelectionWizard.SetData(Vendor);
                    WordTemplateSelectionWizard.RunModal();
                end;
            }
            action(Email)
            {
                ApplicationArea = All;
                Caption = 'Send Email';
                Image = Email;
                ToolTip = 'Send an email to this vendor.';
                Enabled = CanSendEmail;

                trigger OnAction()
                var
                    TempEmailItem: Record "Email Item" temporary;
                    EmailScenario: Enum "Email Scenario";
                begin
                    TempEmailItem.AddSourceDocument(Database::Vendor, Rec.SystemId);
                    TempEmailitem."Send to" := Rec."E-Mail";
                    TempEmailItem.Send(false, EmailScenario::Default);
                end;
            }
            group(OCR)
            {
                Caption = 'OCR';
                action(Resync)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resync all Vendors';
                    Image = CopyFromChartOfAccounts;
                    ToolTip = 'Synchronize vendors and vendor bank accounts with the OCR service.';
                    Visible = ResyncVisible;

                    trigger OnAction()
                    begin
                        ReadSoftOCRMasterDataSync.SyncMasterData(true, false);
                    end;
                }
            }
        }
        area(reporting)
        {
            group(General)
            {
                Caption = 'General';
                Image = "Report";
                action("Vendor - List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - List';
                    Image = "Report";
                    RunObject = Report "Vendor - List";
                    ToolTip = 'View various kinds of basic information for vendors, such as vendor posting group, discount and payment information, priority level and the vendor''s default currency, and the vendor''s current balance (in LCY). The report can be used, for example, to maintain the information in the Vendor table.';
                }
                action("Vendor Register")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Register';
                    Image = "Report";
                    RunObject = Report "Vendor Register";
                    ToolTip = 'View vendor ledger entries that have been posted in connection with a general ledger register. The entries are divided into, and sorted according to, G/L registers. By using a filter, you can select exactly the entries in the registers that you need to see. The report can be used to document the contents of the various registers for internal or external audits.';
                }
                action("Vendor Item Catalog")
                {
                    ApplicationArea = Suite;
                    Caption = 'Vendor Item Catalog';
                    Image = "Report";
                    RunObject = Report "Vendor Item Catalog";
                    ToolTip = 'View a list of the items that your vendors supply.';
                }
                action("Vendor - Labels")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Labels';
                    Image = "Report";
                    RunObject = Report "Vendor - Labels";
                    ToolTip = 'View mailing labels with the vendors'' names and addresses.';
                }
                action("Vendor - Top 10 List")
                {
                    ApplicationArea = Suite;
                    Caption = 'Vendor - Top 10 List';
                    Image = "Report";
                    RunObject = Report "Vendor - Top 10 List";
                    ToolTip = 'View a list of the vendors from whom you purchase the most or to whom you owe the most.';
                }
            }
            group(Action5)
            {
                Caption = 'Orders';
                Image = "Report";
                action("Vendor - Order Summary")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Order Summary';
                    Image = "Report";
                    RunObject = Report "Vendor - Order Summary";
                    ToolTip = 'View the order detail (the quantity not yet received) for each vendor in three periods of 30 days each, starting from a selected date. There are also columns with orders before and after the three periods and a column with the total order detail for each vendor. The report can be used to analyze a company''s expected purchase volume.';
                }
                action("Vendor - Order Detail")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Order Detail';
                    Image = "Report";
                    RunObject = Report "Vendor - Order Detail";
                    ToolTip = 'View a list of items that have been ordered, but not yet received, from each vendor. The order amounts are totaled for each vendor and for the entire list. The report can be used, for example, to obtain an overview of purchases over the short term or to analyze possible receipt problems.';
                }
            }
            group(Purchase)
            {
                Caption = 'Purchase';
                Image = Purchase;
                action("Vendor - Purchase List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Purchase List';
                    Image = "Report";
                    RunObject = Report "Vendor - Purchase List";
                    ToolTip = 'View a list of vendor purchases for a selected period.';
                }
                action("Vendor/Item Purchases")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor/Item Purchases';
                    Image = "Report";
                    RunObject = Report "Vendor/Item Purchases";
                    ToolTip = 'View a list of item entries for each vendor in a selected period.';
                }
                action("Purchase Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Purchase Statistics';
                    Image = "Report";
                    RunObject = Report "Purchase Statistics";
                    ToolTip = 'View a list of amounts for purchases, invoice discount and payment discount in $ for each vendor.';
                }
            }
            group("Financial Management")
            {
                Caption = 'Financial Management';
                Image = "Report";
                action("Payments on Hold")
                {
                    ApplicationArea = Suite;
                    Caption = 'Payments on Hold';
                    Image = "Report";
                    RunObject = Report "Payments on Hold";
                    ToolTip = 'View a list of all vendor ledger entries on which the On Hold field is marked.';
                }
                action("Vendor - Summary Aging")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Summary Aging';
                    Image = "Report";
                    RunObject = Report "Vendor - Summary Aging";
                    ToolTip = 'View, print, or save a summary of the payables owed to each vendor, divided into three time periods.';
                }
                action("Aged Accounts Payable")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Aged Accounts Payable';
                    Image = "Report";
                    RunObject = Report "Aged Accounts Payable";
                    ToolTip = 'View a list of aged remaining balances for each vendor.';
                }
                action("Vendor - Balance to Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Balance to Date';
                    Image = "Report";
                    RunObject = Report "Vendor - Balance to Date";
                    ToolTip = 'View, print, or save a detail balance to date for selected vendors.';
                }
                action("Vendor - Trial Balance")
                {
                    ApplicationArea = Suite;
                    Caption = 'Vendor - Trial Balance';
                    Image = "Report";
                    RunObject = Report "Vendor - Trial Balance";
                    ToolTip = 'View the beginning and ending balance for vendors with entries within a specified period. The report can be used to verify that the balance for a vendor posting group is equal to the balance on the corresponding general ledger account on a certain date.';
                }
                action("Vendor - Detail Trial Balance")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Detail Trial Balance';
                    Image = "Report";
                    RunObject = Report "Vendor - Detail Trial Balance";
                    ToolTip = 'View a detail trial balance for selected vendors.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(PayVendor_Promoted; PayVendor)
                {
                }
                actionref(ApplyTemplate_Promoted; ApplyTemplate)
                {
                }
                actionref(Email_Promoted; Email)
                {
                }
                actionref(Resync_Promoted; Resync)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'New Document', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(NewPurchaseInvoice_Promoted; NewPurchaseInvoice)
                {
                }
                actionref(NewPurchaseOrder_Promoted; NewPurchaseOrder)
                {
                }
                actionref(NewPurchaseCrMemo_Promoted; NewPurchaseCrMemo)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Vendor', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                group(Category_Dimensions)
                {
                    Caption = 'Dimensions';
                    ShowAs = SplitButton;

                    actionref(DimensionsMultiple_Promoted; DimensionsMultiple)
                    {
                    }
                    actionref(DimensionsSingle_Promoted; DimensionsSingle)
                    {
                    }
                }
                actionref(ApprovalEntries_Promoted; ApprovalEntries)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref("C&ontact_Promoted"; "C&ontact")
                {
                }
                actionref("Sent Emails_Promoted"; "Sent Emails")
                {
                }
                actionref("Item &Tracking Entries_Promoted"; "Item &Tracking Entries")
                {
                }
                actionref(Orders_Promoted; Orders)
                {
                }
                actionref("Item Refe&rences_Promoted"; "Item Refe&rences")
                {
                }
                actionref(Quotes_Promoted; Quotes)
                {
                }
                actionref("Return Orders_Promoted"; "Return Orders")
                {
                }
            }
            group("Category_Prices & Discounts")
            {
                Caption = 'Prices & Discounts';

                actionref(PriceLists_Promoted; PriceLists)
                {
                }
                actionref(PriceLines_Promoted; PriceLines)
                {
                }
                actionref(DiscountLines_Promoted; DiscountLines)
                {
                }
                actionref(Prices_Promoted; Prices)
                {
                }
                actionref("Line Discounts_Promoted"; "Line Discounts")
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
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';
                Visible = CRMIntegrationEnabled or CDSIntegrationEnabled;

                group(Category_Coupling)
                {
                    Caption = 'Coupling';
                    ShowAs = SplitButton;

                    actionref(ManageCDSCoupling_Promoted; ManageCDSCoupling)
                    {
                    }
                    actionref(DeleteCDSCoupling_Promoted; DeleteCDSCoupling)
                    {
                    }
                    actionref(MatchBasedCoupling_Promoted; MatchBasedCoupling)
                    {
                    }
                }
                actionref(CDSSynchronizeNow_Promoted; CDSSynchronizeNow)
                {
                }
                actionref(CDSGotoAccount_Promoted; CDSGotoAccount)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        Vendor: Record Vendor;
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);

        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId);

        WorkflowWebhookManagement.GetCanRequestAndCanCancel(Rec.RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);

        CRMIsCoupledToRecord := CRMIntegrationEnabled or CDSIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);

        CurrPage.SetSelectionFilter(Vendor);
        CanSendEmail := Vendor.Count() = 1;

        CurrPage.PowerBIEmbeddedReportPart.PAGE.SetFilterToMultipleValues(Vendor, Vendor.FieldNo("No."));
    end;

    trigger OnInit()
    begin
        CurrPage.PowerBIEmbeddedReportPart.PAGE.SetPageContext(CurrPage.ObjectId(false));
    end;

    trigger OnOpenPage()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Rec.SetRange("Date Filter", 0D, WorkDate());
        ResyncVisible := ReadSoftOCRMasterDataSync.IsSyncEnabled();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        if CRMIntegrationEnabled or CDSIntegrationEnabled then
            if IntegrationTableMapping.Get('VENDOR') then
                BlockedFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field39=1(0)');
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();

        PurchasesPayablesSetup.GetRecordOnce();
        IsAllowMultiplePostingGroupsVisible := PurchasesPayablesSetup."Allow Multiple Posting Groups";
    end;

    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        CanSendEmail: Boolean;
        OpenApprovalEntriesExist: Boolean;
        CanCancelApprovalForRecord: Boolean;
        ResyncVisible: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        BlockedFilterApplied: Boolean;
        ExtendedPriceEnabled: Boolean;
        IsAllowMultiplePostingGroupsVisible: Boolean;

    procedure GetSelectionFilter(): Text
    var
        Vendor: Record Vendor;
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(Vendor);
        exit(SelectionFilterManagement.GetSelectionFilterForVendor(Vendor));
    end;

    procedure SetSelection(var Vendor: Record Vendor)
    begin
        CurrPage.SetSelectionFilter(Vendor);
    end;
}

