// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank.Reconciliation;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Reporting;
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
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Automation;
using System.Email;
using System.Environment;
using System.Integration.Word;
using System.Privacy;
using System.Utilities;

page 26 "Vendor Card"
{
    Caption = 'Vendor Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = Vendor;
    AdditionalSearchTerms = 'Supplier Profile, Vendor Profile, Supplier Data, Vendor View, Provider Details';

    AboutTitle = 'About vendor details';
    AboutText = 'With the **Vendor Card** you manage information about a vendor. Including the agreed terms of business for your trade with this vendor, such as payment terms, prices and discounts.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Name 2"; Rec."Name 2")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    Visible = false;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
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
                field(BalanceAsCustomer; BalanceAsCustomer)
                {
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Balance (LCY) As Customer';
                    Editable = false;
                    Enabled = BalanceAsCustomerEnabled;
                    ToolTip = 'Specifies the amount that this company owes you. This is relevant when your vendor is also your customer. Vendor and customer are linked together through their contact record. Using vendor''s contact record you can create linked customer or link contact with existing customer to enable calculation of Balance As Customer amount.';

                    trigger OnDrillDown()
                    var
                        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                    begin
                        if LinkedCustomerNo = '' then
                            exit;
                        DetailedCustLedgEntry.SetRange("Customer No.", LinkedCustomerNo);
                        Rec.CopyFilter("Global Dimension 1 Filter", DetailedCustLedgEntry."Initial Entry Global Dim. 1");
                        Rec.CopyFilter("Global Dimension 2 Filter", DetailedCustLedgEntry."Initial Entry Global Dim. 2");
                        Rec.CopyFilter("Currency Filter", DetailedCustLedgEntry."Currency Code");
                        CustLedgerEntry.DrillDownOnEntries(DetailedCustLedgEntry);
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
                field("Document Sending Profile"; Rec."Document Sending Profile")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the vendor''s IC partner code, if the vendor is one of your intercompany partners.';
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Disable Search by Name"; Rec."Disable Search by Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Company Size Code"; Rec."Company Size Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Statistics Group"; Rec."Statistics Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
            group("Address & Contact")
            {
                Caption = 'Address & Contact';
                group(AddressDetails)
                {
                    Caption = 'Address';
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the vendor''s address.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        begin
                            IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                        end;
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    group(Control199)
                    {
                        ShowCaption = false;
                        Visible = IsCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Basic, Suite;
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                    }
                    field(ShowMap; ShowMapLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;
                        Style = StrongAccent;
                        StyleExpr = true;
                        ToolTip = 'Specifies you can view the vendor''s address on your preferred map website.';

                        trigger OnDrillDown()
                        begin
                            CurrPage.Update(true);
                            Rec.DisplayMap();
                        end;
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(MobilePhoneNo; Rec."Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = PhoneNo;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Importance = Promoted;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Our Account No."; Rec."Our Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Format Region"; Rec."Format Region")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                group(Contact)
                {
                    Caption = 'Contact';
                    field("Primary Contact No."; Rec."Primary Contact No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Primary Contact Code';
                    }
                    field(Control16; Rec.Contact)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = ContactEditable;
                        Importance = Promoted;

                        trigger OnValidate()
                        begin
                            ContactOnAfterValidate();
                        end;
                    }
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                AboutTitle = 'Manage invoicing from the vendor';
                AboutText = 'Choose tax and other settings for the invoices you receive from this vendor. Assign posting groups to control how transactions with this vendor are grouped and posted, based on type of trade or market.';

                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = VAT;

                    trigger OnDrillDown()
                    var
                        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                    begin
                        VATRegistrationLogMgt.AssistEditVendorVATReg(Rec);
                    end;
                }
                field("EORI Number"; Rec."EORI Number")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(GLN; Rec.GLN)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Copy Buy-from Add. to Qte From"; Rec."Copy Buy-from Add. to Qte From")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                }
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Invoice Disc. Code"; Rec."Invoice Disc. Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    NotBlank = true;
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = VAT;
                }
                field("Self-Billing Agreement"; Rec."Self-Billing Agreement")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Price Calculation Method"; Rec."Price Calculation Method")
                {
                    Visible = ExtendedPriceEnabled;
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Registration Number"; Rec."Registration Number")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                group("Posting Details")
                {
                    Caption = 'Posting Details';
                    field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ShowMandatory = true;
                    }
                    field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                    }
                    field("Vendor Posting Group"; Rec."Vendor Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ShowMandatory = true;
                    }
                    field("Allow Multiple Posting Groups"; Rec."Allow Multiple Posting Groups")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ToolTip = 'Specifies if multiple posting groups can be used for posting business transactions for this customer.';
                        Visible = IsAllowMultiplePostingGroupsVisible;
                    }
                }
                group("Foreign Trade")
                {
                    Caption = 'Foreign Trade';
                    field("Currency Code"; Rec."Currency Code")
                    {
                        ApplicationArea = Suite;
                        Importance = Additional;
                    }
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                AboutTitle = 'Manage payments to the vendor';
                AboutText = 'Choose the payments terms, payment method, priority, and other settings used when processing and suggesting payments to this vendor.';

                field("Prepayment %"; Rec."Prepayment %")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                }
                field("Application Method"; Rec."Application Method")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Block Payment Tolerance"; Rec."Block Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if Rec."Block Payment Tolerance" then begin
                            if ConfirmManagement.GetResponseOrDefault(Text002, true) then
                                PaymentToleranceMgt.DelTolVendLedgEntry(Rec);
                        end else
                            if ConfirmManagement.GetResponseOrDefault(Text001, true) then
                                PaymentToleranceMgt.CalcTolVendLedgEntry(Rec);
                    end;
                }
                field("Preferred Bank Account Code"; Rec."Preferred Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Partner Type"; Rec."Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Intrastat Partner Type"; Rec."Intrastat Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Cash Flow Payment Terms Code"; Rec."Cash Flow Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Creditor No."; Rec."Creditor No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Exclude from Pmt. Practices"; Rec."Exclude from Pmt. Practices")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
            }
            group(Receiving)
            {
                Caption = 'Receiving';
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                }
                field("Customized Calendar"; format(CalendarMgmt.CustomizedChangesExist(Rec)))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customized Calendar';
                    Editable = false;
                    ToolTip = 'Specifies if you have set up a customized calendar for the vendor.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord();
                        Rec.TestField("Base Calendar Code");
                        CalendarMgmt.ShowCustomizedCalendar(Rec);
                    end;
                }
                field("Over-Receipt Code"; Rec."Over-Receipt Code")
                {
                    ApplicationArea = All;
                    Visible = OverReceiptAllowed;
                }
            }
        }
        area(factboxes)
        {
            part(Control82; "Vendor Picture")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = not IsOfficeAddin;
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::Vendor),
                              "No." = field("No.");
            }
            part(VendorStatisticsFactBox; "Vendor Statistics FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No."),
                              "Currency Filter" = field("Currency Filter"),
                              "Date Filter" = field("Date Filter"),
                              "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                              "Global Dimension 2 Filter" = field("Global Dimension 2 Filter");
            }
            part(AgedAccPayableChart; "Aged Acc. Payable Chart")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = IsOfficeAddin;
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
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = All;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatus;
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
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(23),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Accounts';
                    Image = BankAccount;
                    RunObject = Page "Vendor Bank Account List";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'View or set up the vendor''s bank accounts. You can set up any number of bank accounts for each vendor.';
                }
                action(ContactBtn)
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
                action(OrderAddresses)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Order &Addresses';
                    Image = Addresses;
                    RunObject = Page "Order Address List";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'View a list of alternate order addresses for the vendor.';
                }
                action(RemitAddresses)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remit Addresses';
                    Image = Addresses;
                    RunObject = Page "Remit Address List";
                    RunPageLink = "Vendor No." = field("No.");
                    ToolTip = 'View a list of alternate remit addresses for the vendor.';
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
                action("Item References")
                {
                    AccessByPermission = TableData "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                    Caption = 'Item References';
                    Image = Change;
                    RunObject = Page "Item References";
                    RunPageLink = "Reference Type" = const(Vendor),
                                  "Reference Type No." = field("No.");
                    RunPageView = sorting("Reference Type", "Reference Type No.");
                    ToolTip = 'Set up a customer''s or vendor''s own identification of the selected item. Item references to the customer''s item number means that the item number is automatically shown on sales documents instead of the number that you use.';
                }
                action(VendorReportSelections)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Layouts';
                    Image = Quote;
                    ToolTip = 'Set up a layout for different types of documents such as invoices, quotes, and credit memos.';

                    trigger OnAction()
                    var
                        CustomReportSelection: Record "Custom Report Selection";
                    begin
                        CustomReportSelection.SetRange("Source Type", DATABASE::Vendor);
                        CustomReportSelection.SetRange("Source No.", Rec."No.");
                        PAGE.RunModal(PAGE::"Vendor Report Selections", CustomReportSelection);
                    end;
                }
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
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
                    RunPageView = sorting("Vendor No.", "Item No.");
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
                    ApplicationArea = Basic, Suite;
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
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(Rec.RecordId);
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
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(Rec.RecordId);
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
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category6;
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
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category6;
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
                Visible = not IsOfficeAddin;
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
                Visible = not IsOfficeAddin;
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
                Visible = not IsOfficeAddin;
            }
            action(NewPurchaseReturnOrder)
            {
                ApplicationArea = PurchReturnOrder;
                Caption = 'Purchase Return Order';
                Image = ReturnOrder;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Category6;
                RunObject = Page "Purchase Return Order";
                RunPageLink = "Buy-from Vendor No." = field("No.");
                RunPageMode = Create;
                ToolTip = 'Create a new purchase return order for the vendor.';
            }
            action(NewPurchaseInvoiceAddin)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Invoice';
                Image = NewPurchaseInvoice;
                ToolTip = 'Create a new purchase invoice for items or services.';
                Visible = IsOfficeAddin;

                trigger OnAction()
                begin
                    Rec.CreateAndShowNewInvoice();
                end;
            }
            action(NewPurchaseOrderAddin)
            {
                ApplicationArea = Suite;
                Caption = 'Purchase Order';
                Image = Document;
                ToolTip = 'Create a new purchase order.';
                Visible = IsOfficeAddin;

                trigger OnAction()
                begin
                    Rec.CreateAndShowNewPurchaseOrder();
                end;
            }
            action(NewPurchaseCrMemoAddin)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Credit Memo';
                Image = CreditMemo;
                ToolTip = 'Create a new purchase credit memo to revert a posted purchase invoice.';
                Visible = IsOfficeAddin;

                trigger OnAction()
                begin
                    Rec.CreateAndShowNewCreditMemo();
                end;
            }
        }
        area(processing)
        {
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject the approval request.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    ToolTip = 'Delegate the approval to a substitute approver.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
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
                group(Flow)
                {
                    Caption = 'Power Automate';

                    customaction(CreateFlowFromTemplate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create approval flow';
                        ToolTip = 'Create a new flow in Power Automate from a list of relevant flow templates.';
                        Visible = IsSaaS and IsPowerAutomatePrivacyNoticeApproved;
                        CustomActionType = FlowTemplateGallery;
                        FlowTemplateCategoryName = 'd365bc_approval_vendor';
                    }
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Templates)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Templates';
                    Image = Template;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    ToolTip = 'View or edit vendor templates.';

                    trigger OnAction()
                    var
                        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
                    begin
                        VendorTemplMgt.ShowTemplates();
                    end;
                }
                action(ApplyTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Template';
                    Image = ApplyTemplate;
                    ToolTip = 'Apply a template to update the entity with your standard settings for a certain type of entity.';

                    trigger OnAction()
                    var
                        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
                    begin
                        VendorTemplMgt.UpdateVendorFromTemplate(Rec);
                    end;
                }
                action(SaveAsTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Save as Template';
                    Image = Save;
                    ToolTip = 'Save the vendor card as a template that can be reused to create new vendor cards. Vendor templates contain preset information to help you fill fields on vendor cards.';

                    trigger OnAction()
                    var
                        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
                    begin
                        VendorTemplMgt.SaveAsTemplate(Rec);
                    end;
                }
                action(MergeDuplicate)
                {
                    AccessByPermission = TableData "Merge Duplicates Buffer" = RIMD;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Merge With';
                    Ellipsis = true;
                    Image = ItemSubstitution;
                    ToolTip = 'Merge two vendor records into one. Before merging, review which field values you want to keep or override. The merge action cannot be undone.';

                    trigger OnAction()
                    var
                        TempMergeDuplicatesBuffer: Record "Merge Duplicates Buffer" temporary;
                    begin
                        TempMergeDuplicatesBuffer.Show(DATABASE::Vendor, Rec."No.");
                    end;
                }
            }
            action("Create Payments")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create Payments';
                Ellipsis = true;
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
                ToolTip = 'Opens vendor ledger entries with invoices that have not been paid yet.';
            }
            action(WordTemplate)
            {
                ApplicationArea = All;
                Caption = 'Apply Word Template';
                ToolTIp = 'Apply a Word template on the vendor.';
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
            group("Incoming Documents")
            {
                Caption = 'Incoming Documents';
                Image = SendApprovalRequest;
                action(SendToIncomingDocuments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send to Incoming Documents';
                    Ellipsis = true;
                    Enabled = SendToIncomingDocEnabled;
                    Image = SendElectronicDocument;
                    ToolTip = 'Send to Incoming Documents';
                    Visible = SendToIncomingDocumentVisible;

                    trigger OnAction()
                    begin
                        OfficeMgt.InitiateSendToIncomingDocuments(Rec."No.");
                    end;
                }
                action(SendToOCR)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send To OCR';
                    Ellipsis = true;
                    Enabled = SendToOCREnabled;
                    Image = SendElectronicDocument;
                    ToolTip = 'Send To OCR';
                    Visible = SendToOCRVisible;

                    trigger OnAction()
                    begin
                        OfficeMgt.InitiateSendToOCR(Rec."No.");
                    end;
                }
                action(SendIncomingDocApprovalRequest)
                {
                    AccessByPermission = TableData "Approval Entry" = I;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval to change the record.';
                    Visible = SendIncomingDocApprovalRequestVisible;

                    trigger OnAction()
                    begin
                        OfficeMgt.InitiateSendApprovalRequest(Rec."No.");
                    end;
                }
            }
        }
        area(reporting)
        {
#if not CLEAN28
            action("Vendor - Summary Aging")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - Summary Aging (Obsolete)';
                Image = "Report";
                ToolTip = 'View a summary of the payables owed to each vendor, divided into three time periods.';
                ObsoleteState = Pending;
                ObsoleteReason = 'This report is obsolete and will be removed in a future release. See the documentation for alternative options.';
                ObsoleteTag = '28.0';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Vendor - Summary Aging");
                end;
            }
#endif
            action("Vendor - Labels")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - Labels';
                Image = "Report";
                ToolTip = 'View mailing labels with the vendors'' names and addresses.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Vendor - Labels");
                end;
            }
            action("Vendor - Balance to Date")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor - Balance to Date';
                Image = "Report";
                ToolTip = 'View a detail balance for selected vendors.';

                trigger OnAction()
                begin
                    RunReport(REPORT::"Vendor - Balance to Date");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ContactBtn_Promoted; ContactBtn)
                {
                }
                actionref(MergeDuplicate_Promoted; MergeDuplicate)
                {
                }
                actionref(ApplyTemplate_Promoted; ApplyTemplate)
                {
                }
                actionref(Email_Promoted; Email)
                {
                }
                actionref(PayVendor_Promoted; PayVendor)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(Comment_Promoted; Comment)
                {
                }
                actionref(Delegate_Promoted; Delegate)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(SendApprovalRequest_Promoted; SendApprovalRequest)
                {
                }
                actionref(CancelApprovalRequest_Promoted; CancelApprovalRequest)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'New Document', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(NewPurchaseInvoiceAddin_Promoted; NewPurchaseInvoiceAddin)
                {
                }
                actionref(NewPurchaseInvoice_Promoted; NewPurchaseInvoice)
                {
                }
                actionref(NewPurchaseOrderAddin_Promoted; NewPurchaseOrderAddin)
                {
                }
                actionref(NewPurchaseOrder_Promoted; NewPurchaseOrder)
                {
                }
                actionref(NewPurchaseCrMemoAddin_Promoted; NewPurchaseCrMemoAddin)
                {
                }
                actionref(NewPurchaseCrMemo_Promoted; NewPurchaseCrMemo)
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Incoming Documents', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref(SendToIncomingDocuments_Promoted; SendToIncomingDocuments)
                {
                }
                actionref(SendToOCR_Promoted; SendToOCR)
                {
                }
                actionref(SendIncomingDocApprovalRequest_Promoted; SendIncomingDocApprovalRequest)
                {
                }
            }
            group(Category_Category9)
            {
                Caption = 'Vendor', Comment = 'Generated from the PromotedActionCategories property index 8.';

                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref(Attachments_Promoted; Attachments)
                {
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

                actionref(VendorReportSelections_Promoted; VendorReportSelections)
                {
                }
                actionref("Sent Emails_Promoted"; "Sent Emails")
                {
                }
                actionref("Bank Accounts_Promoted"; "Bank Accounts")
                {
                }
                actionref("Item References_Promoted"; "Item References")
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
            group(Category_Category7)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 6.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Vendor - Balance to Date_Promoted"; "Vendor - Balance to Date")
                {
                }
#if not CLEAN28
                actionref("Vendor - Summary Aging_Promoted"; "Vendor - Summary Aging")
                {
                    ObsoleteState = Pending;
                    ObsoleteReason = 'This report is obsolete and will be removed in a future release. See the documentation for alternative options.';
                    ObsoleteTag = '28.0';
                }
#endif
                actionref(Purchases_Promoted; Purchases)
                {
                }
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
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if GuiAllowed() then
            OnAfterGetCurrRecordFunc()
        else
            if not (ClientTypeManagement.GetCurrentClientType() in [ClientType::ODataV4, ClientType::Api]) then
                StartBackgroundCalculations();
    end;

    local procedure OnAfterGetCurrRecordFunc()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        OnBeforeOnAfterGetCurrRecordFunc(Rec);
        if NewMode then
            CreateVendorFromTemplate()
        else
            StartBackgroundCalculations();
        ActivateFields();
        OpenApprovalEntriesExistCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);
        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(Rec.RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId);
        WorkflowWebhookManagement.GetCanRequestAndCanCancel(Rec.RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);

        if Rec."No." <> '' then
            CurrPage.AgedAccPayableChart.PAGE.UpdateChartForVendor(Rec."No.");
        if Rec.GetFilter("Date Filter") = '' then
            Rec.SetRange("Date Filter", 0D, WorkDate());
        CRMIsCoupledToRecord := CRMIntegrationEnabled or CDSIntegrationEnabled;
        if CRMIsCoupledToRecord then
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    trigger OnInit()
    begin
        ContactEditable := true;

        IsPowerAutomatePrivacyNoticeApproved := PrivacyNotice.GetPrivacyNoticeApprovalState(FlowServiceManagement.GetPowerAutomatePrivacyNoticeId()) = "Privacy Notice Approval State"::Agreed;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        if GuiAllowed then
            if Rec."No." = '' then
                if DocumentNoVisibility.VendorNoSeriesIsDefault() then
                    NewMode := true;
    end;

    trigger OnOpenPage()
    begin
        if GuiAllowed() then
            OnOpenPageFunc();
    end;

    local procedure OnOpenPageFunc()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        EnvironmentInfo: Codeunit "Environment Information";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        ActivateFields();
        IsOfficeAddin := OfficeMgt.IsAvailable();
        SetNoFieldVisible();
        IsSaaS := EnvironmentInfo.IsSaaS();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
        if CRMIntegrationEnabled or CDSIntegrationEnabled then
            if IntegrationTableMapping.Get('VENDOR') then
                BlockedFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field39=1(0)');
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();

        PurchasesPayablesSetup.GetRecordOnce();
        IsAllowMultiplePostingGroupsVisible := PurchasesPayablesSetup."Allow Multiple Posting Groups";

        SetOverReceiptControlsVisibility();
    end;

    local procedure StartBackgroundCalculations()
    var
        VendorCardCalculations: Codeunit "Vendor Card Calculations";
        Args: Dictionary of [Text, Text];
    begin
        if BackgroundTaskId <> 0 then
            CurrPage.CancelBackgroundTask(BackgroundTaskId);

        LinkedCustomerNo := '';
        BalanceAsCustomer := 0;
        BalanceAsCustomerEnabled := false;

        Args.Add(VendorCardCalculations.GetVendorNoLabel(), Rec."No.");
        Args.Add(VendorCardCalculations.GetFiltersLabel(), Rec.GetView());
        Args.Add(VendorCardCalculations.GetWorkDateLabel(), Format(WorkDate()));

        CurrPage.EnqueueBackgroundTask(BackgroundTaskId, Codeunit::"Vendor Card Calculations", Args);

        Session.LogMessage('0000GC4', StrSubstNo(PageBckGrndTaskStartedTxt, Rec.SystemId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VendorCardServiceCategoryTxt);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        VendorCardCalculations: Codeunit "Vendor Card Calculations";
        DictionaryValue: Text;
    begin
        if TaskId = BackgroundTaskId then begin
            if Results.Count() = 0 then
                exit;

            if TryGetDictionaryValueFromKey(Results, VendorCardCalculations.GetLinkedCustomerNoLabel(), DictionaryValue) then
                LinkedCustomerNo := CopyStr(DictionaryValue, 1, MaxStrLen(LinkedCustomerNo));
            BalanceAsCustomerEnabled := LinkedCustomerNo <> '';
            if BalanceAsCustomerEnabled then
                if TryGetDictionaryValueFromKey(Results, VendorCardCalculations.GetBalanceAsCustomerLabel(), DictionaryValue) then
                    Evaluate(BalanceAsCustomer, DictionaryValue);

            Session.LogMessage('0000GC5', PageBckGrndTaskCompletedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', VendorCardServiceCategoryTxt);
        end;
    end;

    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        OfficeMgt: Codeunit "Office Management";
        CalendarMgmt: Codeunit "Calendar Management";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        FormatAddress: Codeunit "Format Address";
        PrivacyNotice: Codeunit "Privacy Notice";
        FlowServiceManagement: Codeunit "Flow Service Management";
#pragma warning disable AA0074
        Text001: Label 'Do you want to allow payment tolerance for entries that are currently open?';
        Text002: Label 'Do you want to remove payment tolerance from entries that are currently open?';
#pragma warning restore AA0074
        PageBckGrndTaskStartedTxt: Label 'Page Background Task to calculate vendor statistics for vendor %1 started.', Locked = true, Comment = '%1 = Customer No.';
        PageBckGrndTaskCompletedTxt: Label 'Page Background Task to calculate vendor statistics completed successfully.', Locked = true;
        VendorCardServiceCategoryTxt: Label 'Vendor Card', Locked = true;
        LinkedCustomerNo: Code[20];
        BalanceAsCustomer: Decimal;
        OpenApprovalEntriesExistCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        ShowMapLbl: Label 'Show on Map';
        CanCancelApprovalForRecord: Boolean;
        SendToOCREnabled: Boolean;
        SendToOCRVisible: Boolean;
        SendToIncomingDocEnabled: Boolean;
        SendIncomingDocApprovalRequestVisible: Boolean;
        IsPowerAutomatePrivacyNoticeApproved: Boolean;
        SendToIncomingDocumentVisible: Boolean;
        NoFieldVisible: Boolean;
        NewMode: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        IsSaaS: Boolean;
        IsCountyVisible: Boolean;
        IsAllowMultiplePostingGroupsVisible: Boolean;
        CRMIntegrationEnabled: Boolean;
        CDSIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        BlockedFilterApplied: Boolean;
        ExtendedPriceEnabled: Boolean;
        OverReceiptAllowed: Boolean;
        BalanceAsCustomerEnabled: Boolean;
        BackgroundTaskId: Integer;

    protected var
        ContactEditable: Boolean;
        IsOfficeAddin: Boolean;

    [TryFunction]
    local procedure TryGetDictionaryValueFromKey(var DictionaryToLookIn: Dictionary of [Text, Text]; KeyToSearchFor: Text; var ReturnValue: Text)
    begin
        ReturnValue := DictionaryToLookIn.Get(KeyToSearchFor);
    end;

    local procedure ActivateFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeActivateFields(IsCountyVisible, FormatAddress, IsHandled);
        if IsHandled then
            exit;

        ContactEditable := Rec."Primary Contact No." = '';
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        if OfficeMgt.IsAvailable() then
            ActivateIncomingDocumentsFields();
    end;

    local procedure ContactOnAfterValidate()
    begin
        ActivateFields();
    end;

    procedure RunReport(ReportNumber: Integer)
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetRange("No.", Rec."No.");
        REPORT.RunModal(ReportNumber, true, true, Vendor);
    end;

    local procedure ActivateIncomingDocumentsFields()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        if OfficeMgt.OCRAvailable() then begin
            SendToIncomingDocumentVisible := true;
            SendToIncomingDocEnabled := OfficeMgt.EmailHasAttachments();
            SendToOCREnabled := OfficeMgt.EmailHasAttachments();
            SendToOCRVisible := IncomingDocument.OCRIsEnabled() and not IsIncomingDocApprovalsWorkflowEnabled();
            SendIncomingDocApprovalRequestVisible := IsIncomingDocApprovalsWorkflowEnabled();
        end;
    end;

    local procedure IsIncomingDocApprovalsWorkflowEnabled(): Boolean
    var
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowDefinition: Query "Workflow Definition";
    begin
        WorkflowDefinition.SetRange(Table_ID, DATABASE::"Incoming Document");
        WorkflowDefinition.SetRange(Entry_Point, true);
        WorkflowDefinition.SetRange(Enabled, true);
        WorkflowDefinition.SetRange(Type, WorkflowDefinition.Type::"Event");
        WorkflowDefinition.SetRange(Function_Name, WorkflowEventHandling.RunWorkflowOnSendIncomingDocForApprovalCode());
        WorkflowDefinition.Open();
        while WorkflowDefinition.Read() do
            exit(true);

        exit(false);
    end;

    local procedure CreateVendorFromTemplate()
    var
        Vendor: Record Vendor;
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
    begin
        OnBeforeCreateVendorFromTemplate(NewMode, Vendor);

        if not NewMode then
            exit;
        NewMode := false;

        if VendorTemplMgt.InsertVendorFromTemplate(Vendor) then begin
            VerifyVatRegNo(Vendor);
            Rec.Copy(Vendor);
            OnCreateVendorFromTemplateOnBeforeCurrPageUpdate(Rec);
            CurrPage.Update();
        end else
            if VendorTemplMgt.TemplatesAreNotEmpty() then
                if not VendorTemplMgt.IsOpenBlankCardConfirmed() then
                    CurrPage.Close();
    end;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.VendorNoIsVisible();
    end;

    local procedure SetOverReceiptControlsVisibility()
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        OverReceiptAllowed := OverReceiptMgt.IsOverReceiptAllowed();
    end;

    local procedure VerifyVatRegNo(var Vendor: Record Vendor)
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        EUVATRegistrationNoCheck: Page "EU VAT Registration No Check";
        VendorRecRef: RecordRef;
    begin
        if VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then
            if Vendor."Validate EU Vat Reg. No." then begin
                EUVATRegistrationNoCheck.SetRecordRef(Vendor);
                Commit();
                EUVATRegistrationNoCheck.RunModal();
                EUVATRegistrationNoCheck.GetRecordRef(VendorRecRef);
                VendorRecRef.SetTable(Vendor);
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateVendorFromTemplate(var NewMode: Boolean; var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeActivateFields(var IsCountyVisible: Boolean; var FormatAddress: Codeunit "Format Address"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendorFromTemplateOnBeforeCurrPageUpdate(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterGetCurrRecordFunc(var Vendor: Record Vendor)
    begin
    end;
}