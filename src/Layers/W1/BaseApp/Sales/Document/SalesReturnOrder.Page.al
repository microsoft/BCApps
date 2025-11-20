// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Intercompany;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Request;
using System.Automation;
using System.Security.User;
using System.Threading;

page 6630 "Sales Return Order"
{
    Caption = 'Sales Return Order';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = filter("Return Order"));

    AboutTitle = 'About sales return order details';
    AboutText = 'When you receive items back from the customer, you post the quantity received and the quantity you choose to credit the customer. Posting issues a related sales credit memo and return-related documents.';

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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Customer No.';
                    Importance = Additional;
                    NotBlank = true;
                    ToolTip = 'Specifies the number of the customer associated with the sales return.';

                    trigger OnValidate()
                    begin
                        Rec.SelltoCustomerNoOnAfterValidate(Rec, xRec);
                        IsSalesLinesEditable := Rec.SalesLinesEditable();
                        CurrPage.Update();
                    end;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Customer Name';
                    Importance = Promoted;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the name of the customer.';

                    AboutTitle = 'Who''s returning the items?';
                    AboutText = 'This is the customer that bought the items now being returned, and who will be credited if you choose to accept the return.';

                    trigger OnAfterLookup(Selected: RecordRef)
                    var
                        Customer: Record Customer;
                    begin
                        Selected.SetTable(Customer);
                        if Rec."Sell-to Customer No." <> Customer."No." then begin
                            Rec.Validate("Sell-to Customer No.", Customer."No.");
                            if Rec."Sell-to Customer No." <> Customer."No." then
                                error('');
                            IsSalesLinesEditable := Rec.SalesLinesEditable();
                            CurrPage.Update();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        Rec.SelltoCustomerNoOnAfterValidate(Rec, xRec);
                        CurrPage.Update();
                    end;
                }
                field("Sell-to Customer Name 2"; Rec."Sell-to Customer Name 2")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Customer Name 2';
                    QuickEntry = false;
                    Visible = false;
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field("Sell-to Address"; Rec."Sell-to Address")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address';
                        Importance = Additional;
                        ToolTip = 'Specifies the customer''s address.';
                    }
                    field("Sell-to Address 2"; Rec."Sell-to Address 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address 2';
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the customer''s address.';
                    }
                    field("Sell-to City"; Rec."Sell-to City")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'City';
                        Importance = Additional;
                        ToolTip = 'Specifies the city of the customer''s address.';
                    }
                    group(Control170)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field("Sell-to County"; Rec."Sell-to County")
                        {
                            ApplicationArea = SalesReturnOrder;
                            CaptionClass = '5,1,' + Rec."Sell-to Country/Region Code";
                            Importance = Additional;
                            ToolTip = 'Specifies the county of the address.';
                        }
                    }
                    field("Sell-to Post Code"; Rec."Sell-to Post Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Post Code';
                        Importance = Additional;
                        ToolTip = 'Specifies the postal code of the customer''s address.';
                    }
                    field("Sell-to Country/Region Code"; Rec."Sell-to Country/Region Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Sell-to Country/Region Code");
                        end;
                    }
                    field("Sell-to Contact No."; Rec."Sell-to Contact No.")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact No.';
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the contact person at the customer.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if not Rec.SelltoContactLookup() then
                                exit(false);
                            Text := Rec."Sell-to Contact No.";
                            CurrPage.Update();
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            if Rec.GetFilter("Sell-to Contact No.") = xRec."Sell-to Contact No." then
                                if Rec."Sell-to Contact No." <> xRec."Sell-to Contact No." then
                                    Rec.SetRange("Sell-to Contact No.");
                            if Rec."Sell-to Contact No." <> xRec."Sell-to Contact No." then
                                CurrPage.Update();
                        end;
                    }
                    field(SellToPhoneNo; SellToContact."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the contact person that the sales document will be sent to.';
                    }
                    field(SellToMobilePhoneNo; SellToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact person that the sales document will be sent to.';
                    }
                    field(SellToEmail; SellToContact."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact person that the sales document will be sent to.';
                    }
                }
                field("Sell-to Contact"; Rec."Sell-to Contact")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Contact';
                    Editable = Rec."Sell-to Customer No." <> '';
                    ToolTip = 'Specifies the name of the contact person at the customer.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the sales document was posted.';

                    trigger OnValidate()
                    begin
                        SaveInvoiceDiscountAmount();
                    end;
                }
                field("VAT Reporting Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                    Importance = Promoted;
                    Editable = VATDateEnabled;
                    Visible = VATDateEnabled;
                    ToolTip = 'Specifies the date used to include entries on VAT reports in a VAT period. This is either the date that the document was created or posted, depending on your setting on the General Ledger Setup page.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    QuickEntry = false;
                    ToolTip = 'Specifies the date when the order was created.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
                }
                field("No. of Archived Versions"; Rec."No. of Archived Versions")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of archived versions for this document.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Additional;
                    QuickEntry = false;
                    ToolTip = 'Specifies the name of the salesperson who is assigned to the customer.';

                    trigger OnValidate()
                    begin
                        SalespersonCodeOnAfterValidate();
                    end;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the campaign number the document is linked to.';
                    trigger OnValidate()
                    begin
                        if Rec."Campaign No." <> xRec."Campaign No." then
                            CurrPage.Update();
                    end;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Job Queue Status"; Rec."Job Queue Status")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Specifies the status of a job queue entry or task that handles the posting of sales return orders.';
                    Visible = JobQueueUsed;

                    trigger OnDrillDown()
                    var
                        JobQueueEntry: Record "Job Queue Entry";
                    begin
                        if Rec."Job Queue Status" = Rec."Job Queue Status"::" " then
                            exit;
                        JobQueueEntry.ShowStatusMsg(Rec."Job Queue Entry ID");
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    StyleExpr = StatusStyleTxt;
                    QuickEntry = false;
                    ToolTip = 'Specifies whether the document is open, waiting to be approved, has been invoiced for prepayment, or has been released to the next stage of processing.';
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language to be used on printouts for this document.';
                    Visible = false;
                }
                field("Format Region"; Rec."Format Region")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format to be used on printouts for this document.';
                    Visible = false;
                }
            }
            part(SalesLines; "Sales Return Order Subform")
            {
                ApplicationArea = SalesReturnOrder;
                Editable = IsSalesLinesEditable;
                Enabled = IsSalesLinesEditable;
                SubPageLink = "Document No." = field("No.");
                UpdatePropagation = Both;
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency that is used on the entry.';

                    trigger OnAssistEdit()
                    begin
                        if Rec."Posting Date" <> 0D then
                            ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date")
                        else
                            ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", WorkDate());
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());
                            SaveInvoiceDiscountAmount();
                        end;
                        Clear(ChangeExchangeRate);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Company Bank Account Code"; Rec."Company Bank Account Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the bank account to use for bank information when the document is printed.';
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';

                    trigger OnValidate()
                    begin
                        PricesIncludingVATOnAfterValid();
                    end;
                }
                field("VAT Country/Region Code"; Rec."VAT Country/Region Code")
                {
                    ApplicationArea = VAT;
                    Importance = Additional;
                    ToolTip = 'Specifies the country or region code for the VAT.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s VAT registration number for customers.';
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the general business posting group that the sales document is linked to. The general business posting group is used to link the sales document to the appropriate general ledger account.';
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsPostingGroupEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s market type to link business transactions to.';
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                    Visible = IsPaymentMethodCodeVisible;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV();
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';

                    trigger OnValidate()
                    begin
                        ShortcutDimension2CodeOnAfterV();
                    end;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                }
                field("Journal Templ. Name"; Rec."Journal Templ. Name")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the name of the journal template in which the sales header is to be posted.';
                    Visible = IsJournalTemplNameVisible;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area code for the customer.';

                    trigger OnValidate()
                    begin
                        CurrPage.SalesLines.PAGE.RedistributeTotalsOnAfterValidate();
                    end;
                }
            }
            group("Shipping and Billing")
            {
                Caption = 'Shipping and Billing';
                group("Shipment Method")
                {
                    Caption = 'Shipment Method';
                    field("Shipping Agent Code"; Rec."Shipping Agent Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Agent';
                        Importance = Additional;
                        ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
                    }
                    field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Agent Service';
                        Importance = Additional;
                        ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer.';
                    }
                    field("Package Tracking No."; Rec."Package Tracking No.")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Importance = Additional;
                        ToolTip = 'Specifies the shipping agent''s package number.';
                    }
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Location Code"; Rec."Location Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Location';
                        Importance = Promoted;
                        ToolTip = 'Specifies the location where the items are to be placed when they are received. This field acts as the default location for new lines. You can update the location code for individual lines as needed.';
                    }
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name that products on the sales document will be shipped to.';
                    }
                    field("Ship-to Name 2"; Rec."Ship-to Name 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Name 2';
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the name of the customer at the address that the items are shipped to.';
                        Visible = false;
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address';
                        ToolTip = 'Specifies the address that products on the sales document will be shipped to.';
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address 2';
                        ToolTip = 'Specifies an additional part of the shipping address.';
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'City';
                        ToolTip = 'Specifies the city of the shipping address.';
                    }
                    group(Control76)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = SalesReturnOrder;
                            CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                            ToolTip = 'Specifies the county of the address.';
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Post Code';
                        ToolTip = 'Specifies the postal code of the shipping address.';
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
                        end;
                    }
                    field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Phone No.';
                        ToolTip = 'Specifies the telephone number of the company''s shipping address.';
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person at the shipping address.';
                    }
                }
                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    field("Bill-to Name"; Rec."Bill-to Name")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Name';
                        Importance = Promoted;
                        ToolTip = 'Specifies the customer to whom you will send the sales invoice, when different from the customer that you are selling to.';

                        trigger OnValidate()
                        begin
                            if Rec.GetFilter("Bill-to Customer No.") = xRec."Bill-to Customer No." then
                                if Rec."Bill-to Customer No." <> xRec."Bill-to Customer No." then
                                    Rec.SetRange("Bill-to Customer No.");

                            CurrPage.Update();
                        end;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            Customer: Record Customer;
                        begin
                            OnBeforeLookupBillToName(Customer, Rec);
                            if Customer.SelectCustomer(Customer) then begin
                                xRec := Rec;
                                Rec."Bill-to Name" := Customer.Name;
                                Rec.Validate("Bill-to Customer No.", Customer."No.");
                            end;

                            if Rec.GetFilter("Bill-to Customer No.") = xRec."Bill-to Customer No." then
                                if Rec."Bill-to Customer No." <> xRec."Bill-to Customer No." then
                                    Rec.SetRange("Bill-to Customer No.");

                            CurrPage.Update();
                        end;
                    }
                    field("Bill-to Name 2"; Rec."Bill-to Name 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Name 2';
                        Editable = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Enabled = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Importance = Additional;
                        QuickEntry = false;
                        Visible = false;
                    }
                    field("Bill-to Address"; Rec."Bill-to Address")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address';
                        Editable = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Enabled = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the address of the customer that you will send the invoice to.';
                    }
                    field("Bill-to Address 2"; Rec."Bill-to Address 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address 2';
                        Editable = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Enabled = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the billing address.';
                    }
                    field("Bill-to City"; Rec."Bill-to City")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'City';
                        Editable = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Enabled = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the city of the billing address.';
                    }
                    group(Control80)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; Rec."Bill-to County")
                        {
                            ApplicationArea = SalesReturnOrder;
                            CaptionClass = '5,1,' + Rec."Bill-to Country/Region Code";
                            Editable = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                            Enabled = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                            Importance = Additional;
                            ToolTip = 'Specifies the county of the address.';
                        }
                    }
                    field("Bill-to Post Code"; Rec."Bill-to Post Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Post Code';
                        Editable = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Enabled = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the postal code of the billing address.';
                    }
                    field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Country/Region';
                        Editable = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Enabled = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the country or region of the address.';

                        trigger OnValidate()
                        begin
                            IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
                        end;
                    }
                    field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact No.';
                        Editable = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Enabled = Rec."Bill-to Customer No." <> Rec."Sell-to Customer No.";
                        Importance = Additional;
                        ToolTip = 'Specifies the number of the contact person at the billing address.';
                    }
                    field("Bill-to Contact"; Rec."Bill-to Contact")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person at the billing address.';
                    }
                    field(BillToContactPhoneNo; BillToContact."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the person you should contact at the customer you are sending the invoice to.';
                    }
                    field(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the person you should contact at the customer you are sending the invoice to.';
                    }
                    field(BillToContactEmail; BillToContact."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the person you should contact at the customer you are sending the invoice to.';
                    }
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Exit Point"; Rec."Exit Point")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the point of exit through which you ship the items out of your country/region, for reporting to Intrastat.';
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the country or region of origin for the purpose of Intrastat reporting.';
                }
                field("Rcvd-from Country/Region Code"; Rec."Rcvd.-from Count./Region Code")
                {
                    ApplicationArea = BasicEU, BasicCH, BasicNO;
                    ToolTip = 'Specifies the country or region from which the items are returned for the purpose of Intrastat reporting.';
                }
            }
        }
        area(factboxes)
        {
            part(SalesDocCheckFactbox; "Sales Doc. Check Factbox")
            {
                ApplicationArea = All;
                Caption = 'Document Check';
                Visible = SalesDocCheckFactboxVisible;
                SubPageLink = "No." = field("No."),
                              "Document Type" = field("Document Type");
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
                SubPageLink = "Table ID" = const(Database::"Sales Header"),
                              "No." = field("No."),
                              "Document Type" = field("Document Type");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Sales Header"),
                              "No." = field("No."),
                              "Document Type" = field("Document Type");
            }
            part(Control19; "Pending Approval FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "Table ID" = const(36),
                              "Document Type" = field("Document Type"),
                              "Document No." = field("No."),
                              Status = const(Open);
                Visible = OpenApprovalEntriesExistForCurrUser;
            }
            part(Control1903720907; "Sales Hist. Sell-to FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "No." = field("Sell-to Customer No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1907234507; "Sales Hist. Bill-to FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "No." = field("Sell-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "No." = field("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "No." = field("Sell-to Customer No."),
                              "Date Filter" = field("Date Filter");
            }
            part(Control1906127307; "Sales Line FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                Provider = SalesLines;
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Line No." = field("Line No.");
                Visible = false;
            }
            part(ApprovalFactBox; "Approval FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                Visible = false;
            }
            part(Control1907012907; "Resource Details FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                Provider = SalesLines;
                SubPageLink = "No." = field("No.");
                Visible = false;
            }
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = SalesReturnOrder;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatus;
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
            group("&Return Order")
            {
                Caption = '&Return Order';
                Image = Return;
#if not CLEAN26
                action(Statistics)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    ObsoleteReason = 'The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '26.0';

                    trigger OnAction()
                    var
                        Handled: Boolean;
                    begin
                        OnBeforeStatisticsAction(Rec, Handled);
                        if Handled then
                            exit;

                        Rec.OpenSalesOrderStatistics();
                    end;
                }
#endif
                action(SalesOrderStatistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Enabled = Rec."No." <> '';
                    Image = Statistics;
                    ShortCutKey = 'F7';
#if CLEAN26
                    Visible = true;
#else
                    Visible = false;
#endif
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    RunObject = Page "Sales Order Statistics";
                    RunPageOnRec = true;
                }
                action(Customer)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Customer';
                    Enabled = IsCustomerOrContactNotEmpty;
                    Image = EditLines;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Sell-to Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the customer on the sales document.';
                }
                action(CustomerStatistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Statistics';
                    Enabled = IsCustomerOrContactNotEmpty;
                    Image = Statistics;
                    RunObject = Page "Customer Statistics";
                    RunPageLink = "No." = field("Sell-to Customer No."),
                                  "Date Filter" = field("Date Filter");
                    ToolTip = 'View statistical information, such as the value of posted entries, for the sell-to customer on the sales document.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Enabled = Rec."No." <> '';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
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
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = const("Return Order"),
                                  "No." = field("No."),
                                  "Document Line No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("Return Receipts")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Return Receipts';
                    Image = ReturnReceipt;
                    RunObject = Page "Posted Return Receipts";
                    RunPageLink = "Return Order No." = field("No.");
                    RunPageView = sorting("Return Order No.");
                    ToolTip = 'View a list of posted return receipts for the order.';
                }
                action("Cred&it Memos")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Cred&it Memos';
                    Image = CreditMemo;
                    ToolTip = 'View a list of ongoing credit memos for the order.';

                    trigger OnAction()
                    var
                        TempSalesCrMemoHeader: Record "Sales Cr.Memo Header" temporary;
                        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
                    begin
                        SalesGetReturnReceipts.GetSalesRetOrderCrMemos(TempSalesCrMemoHeader, Rec."No.");
                        Page.Run(Page::"Posted Sales Credit Memos", TempSalesCrMemoHeader);
                    end;
                }
                separator(Action131)
                {
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("In&vt. Put-away/Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'In&vt. Put-away/Pick Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity List";
                    RunPageLink = "Source Document" = const("Sales Return Order"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Document", "Source No.", "Location Code");
                    ToolTip = 'View items that are inbound or outbound on inventory put-away or inventory pick documents for the sales return order.';
                }
                action("Whse. Receipt Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Whse. Receipt Lines';
                    Image = ReceiptLines;
                    RunObject = Page "Whse. Receipt Lines";
                    RunPageLink = "Source Type" = const(37),
#pragma warning disable AL0603
                                  "Source Subtype" = field("Document Type"),
#pragma warning restore
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View ongoing warehouse receipts for the document, in advanced warehouse configurations.';
                }
                action("Whse. Put-away Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Put-away Lines';
                    Image = PutawayLines;
                    RunObject = page "Warehouse Activity Lines";
                    RunPageLink = "Source Document" = const("Sales Return Order"), "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.");
                    ToolTip = 'View ongoing warehouse put-aways for the document, in advanced warehouse configurations.';
                }
            }
        }
        area(processing)
        {
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject the approval request.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Delegate';
                    Image = Delegate;
                    ToolTip = 'Delegate the approval to a substitute approver.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

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
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = SalesReturnOrder;
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
                begin
                    SalesHeader := Rec;
                    SalesHeader.SetRecFilter();
                    DocPrint.PrintSalesHeaderToDocumentAttachment(SalesHeader);
                end;
            }
            group(Action7)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Re&lease';
                    Enabled = Rec.Status <> Rec.Status::Released;
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                        CurrPage.SalesLines.PAGE.ClearTotalSalesHeader();
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Re&open';
                    Enabled = Rec.Status <> Rec.Status::Open;
                    Image = ReOpen;
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed';

                    trigger OnAction()
                    var
                        ReleaseSalesDoc: Codeunit "Release Sales Document";
                    begin
                        ReleaseSalesDoc.PerformManualReopen(Rec);
                        CurrPage.SalesLines.PAGE.ClearTotalSalesHeader();
                    end;
                }
                separator(Action600)
                {
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CalculateInvoiceDiscount)
                {
                    AccessByPermission = TableData "Cust. Invoice Disc." = R;
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount that applies to the sales return order.';

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc();
                        SalesCalcDiscByType.ResetRecalculateInvoiceDisc(Rec);
                    end;
                }
                separator(Action132)
                {
                }
                action("Apply Entries")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Apply Entries';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Select one or more ledger entries that you want to apply this record to so that the related posted documents are closed as paid or refunded.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Sales Header Apply", Rec);
                    end;
                }
                action("Create Return-Related &Documents")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Create Return-Related &Documents';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    ToolTip = 'Prepare to automatically create related documents, such as a replacement sales order, a purchase return order, or a replacement purchase order.';

                    trigger OnAction()
                    begin
                        Clear(CreateRetRelDocs);
                        CreateRetRelDocs.SetSalesHeader(Rec);
                        CreateRetRelDocs.RunModal();
                        CreateRetRelDocs.ShowDocuments();
                    end;
                }
                separator(Action133)
                {
                }
                action(CopyDocument)
                {
                    ApplicationArea = Suite;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Enabled = Rec."No." <> '';
                    Image = CopyDocument;
                    ToolTip = 'Copy document lines and header information from another sales document to this document. You can copy a posted sales invoice into a new sales invoice to quickly create a similar document.';

                    trigger OnAction()
                    begin
                        Rec.CopyDocument();
                        if Rec.Get(Rec."Document Type", Rec."No.") then;
                        CurrPage.SalesLines.Page.ForceTotalsCalculation();
                        CurrPage.Update();
                    end;
                }
                action(MoveNegativeLines)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Move Negative Lines';
                    Ellipsis = true;
                    Image = MoveNegativeLines;
                    ToolTip = 'Prepare to create a replacement sales order in a sales return process.';

                    trigger OnAction()
                    begin
                        Clear(MoveNegSalesLines);
                        MoveNegSalesLines.SetSalesHeader(Rec);
                        MoveNegSalesLines.RunModal();
                        MoveNegSalesLines.ShowDocument();
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Post and &Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        PostDocument(CODEUNIT::"Sales-Post + Print");
                    end;
                }
                action(GetPostedDocumentLinesToReverse)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Get Posted Doc&ument Lines to Reverse';
                    Ellipsis = true;
                    Image = ReverseLines;
                    ToolTip = 'Copy one or more posted sales document lines in order to reverse the original order.';

                    AboutTitle = 'Choosing what is returned';
                    AboutText = 'To create lines for the sales return order, you can overview and select lines from the documents posted for a certain customer, and have the information copied here.';

                    trigger OnAction()
                    begin
                        Rec.GetPstdDocLinesToReverse();
                        CurrPage.SalesLines.Page.SalesDocTotalsNotUpToDate();
                        CurrPage.SalesLines.Page.Update(false);
                    end;
                }
                action("Archive Document")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Archive Document';
                    Image = Archive;
                    ToolTip = 'Send the document to the archive, for example because it is too soon to delete it. Later, you delete or reprocess the archived document.';

                    trigger OnAction()
                    begin
                        ArchiveManagement.ArchiveSalesDocument(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action("Send IC Return Order Cnfmn.")
                {
                    AccessByPermission = TableData "IC G/L Account" = R;
                    ApplicationArea = Intercompany;
                    Caption = 'Send IC Return Order Cnfmn.';
                    Image = IntercompanyOrder;
                    ToolTip = 'Prepare to send the return order confirmation to an intercompany partner.';

                    trigger OnAction()
                    var
                        ICInOutboxMgt: Codeunit ICInboxOutboxMgt;
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.PrePostApprovalCheckSales(Rec) then
                            ICInOutboxMgt.SendSalesDoc(Rec, false);
                    end;
                }
                separator(Action135)
                {
                }
                action(Post)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    AboutTitle = 'Post the quantities you''ve set';
                    AboutText = 'Choose one of the post actions to trigger receipt and/or crediting of the quantities you entered on the lines. You can post multiple times from the same return order if the items are not received at once.';

                    trigger OnAction()
                    begin
                        PostDocument(CODEUNIT::"Sales-Post (Yes/No)");
                    end;
                }
                action("Preview Posting")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        ShowPreview();
                    end;
                }
                action(DocAttach)
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
            group(Action13)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                separator(Action136)
                {
                }
                action("Create &Whse. Receipt")
                {
                    AccessByPermission = TableData "Warehouse Receipt Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create &Whse. Receipt';
                    Image = NewReceipt;
                    ToolTip = 'Create a warehouse receipt to start a receive and put-away process according to an advanced warehouse configuration.';

                    trigger OnAction()
                    var
                        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
                    begin
                        Rec.PerformManualRelease();
                        CurrPage.SalesLines.PAGE.ClearTotalSalesHeader();

                        GetSourceDocInbound.CreateFromSalesReturnOrder(Rec);
                    end;
                }
                action("Create Inventor&y Put-away/Pick")
                {
                    AccessByPermission = TableData "Posted Invt. Put-away Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Inventor&y Put-away/Pick';
                    Ellipsis = true;
                    Image = CreateInventoryPickup;
                    ToolTip = 'Create an inventory put-away or inventory pick to handle items on the document according to a basic warehouse configuration that does not require warehouse receipt or shipment documents.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                        CurrPage.SalesLines.PAGE.ClearTotalSalesHeader();

                        Rec.CreateInvtPutAwayPick();
                    end;
                }
                separator(Action30)
                {
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintSalesHeader(Rec);
                    end;
                }
                action("Post &Batch")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    //The property 'PromotedOnly' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedOnly = false;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Sales Return Orders", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
                action("Remove From Job Queue")
                {
                    ApplicationArea = All;
                    Caption = 'Remove From Job Queue';
                    Image = RemoveLine;
                    ToolTip = 'Remove the scheduled processing of this record from the job queue.';
                    Visible = JobQueueVisible;

                    trigger OnAction()
                    begin
                        Rec.CancelBackgroundPosting();
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                action(SendApprovalRequest)
                {
                    ApplicationArea = SalesReturnOrder;
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
                    ApplicationArea = SalesReturnOrder;
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

                group(Category_Category6)
                {
                    Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 5.';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                    actionref("Preview Posting_Promoted"; "Preview Posting")
                    {
                    }
                    actionref("Post &Batch_Promoted"; "Post &Batch")
                    {
                    }
                }
                group(Category_Category5)
                {
                    Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 4.';
                    ShowAs = SplitButton;

                    actionref(Release_Promoted; Release)
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
                }
                actionref("Create &Whse. Receipt_Promoted"; "Create &Whse. Receipt")
                {
                }
                actionref("Create Return-Related &Documents_Promoted"; "Create Return-Related &Documents")
                {
                }
                actionref("Apply Entries_Promoted"; "Apply Entries")
                {
                }
                actionref("Archive Document_Promoted"; "Archive Document")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Prepare', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(CopyDocument_Promoted; CopyDocument)
                {
                }
                actionref(GetPostedDocumentLinesToReverse_Promoted; GetPostedDocumentLinesToReverse)
                {
                }
                actionref(CalculateInvoiceDiscount_Promoted; CalculateInvoiceDiscount)
                {
                }
                actionref(MoveNegativeLines_Promoted; MoveNegativeLines)
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
            group(Category_Category10)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 9.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref(AttachAsPDF_Promoted; AttachAsPDF)
                {
                }
            }
            group(Category_Category9)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 8.';

                actionref(SendApprovalRequest_Promoted; SendApprovalRequest)
                {
                }
                actionref(CancelApprovalRequest_Promoted; CancelApprovalRequest)
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Invoice', Comment = 'Generated from the PromotedActionCategories property index 7.';
            }
            group(Category_Category11)
            {
                Caption = 'Return Order', Comment = 'Generated from the PromotedActionCategories property index 10.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
#if not CLEAN26
                actionref(Statistics_Promoted; Statistics)
                {
                    ObsoleteReason = 'The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '26.0';
                }
#else
                actionref(SalesOrderStatistics_Promoted; SalesOrderStatistics)
                {
                }
#endif
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(DocAttach_Promoted; DocAttach)
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
                separator(Navigate_Separator)
                {
                }
                actionref(Customer_Promoted; Customer)
                {
                }
                actionref("Return Receipts_Promoted"; "Return Receipts")
                {
                }
                actionref("Cred&it Memos_Promoted"; "Cred&it Memos")
                {
                }
            }
            group(Category_Category12)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 11.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetControlAppearance();
        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(Rec.RecordId());
        CurrPage.ApprovalFactBox.PAGE.UpdateApprovalEntriesFromSourceRecord(Rec.RecordId());
        StatusStyleTxt := Rec.GetStatusStyleText();
    end;

    trigger OnAfterGetRecord()
    begin
        SellToContact.GetOrClear(Rec."Sell-to Contact No.");
        BillToContact.GetOrClear(Rec."Bill-to Contact No.");

        OnAfterOnAfterGetRecord(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord();
        exit(Rec.ConfirmDeletion());
    end;

    trigger OnInit()
    begin
        JobQueueUsed := SalesSetup.JobQueueActive();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if DocNoVisible then
            Rec.CheckCreditMaxBeforeInsert();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Responsibility Center" := UserMgt.GetSalesFilter();
        if (not DocNoVisible) and (Rec."No." = '') then
            Rec.SetSellToCustomerFromFilter();
    end;

    trigger OnOpenPage()
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        Rec.SetSecurityFilterOnRespCenter();

        ActivateFields();

        SetDocNoVisible();
        if (Rec."No." <> '') and (Rec."Sell-to Customer No." = '') then
            DocumentIsPosted := (not Rec.Get(Rec."Document Type", Rec."No."));

        CheckShowBackgrValidationNotification();
        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnQueryClosePage(Rec, CloseAction, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not DocumentIsPosted then
            exit(Rec.ConfirmCloseUnposted());
    end;

    var
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        SalesSetup: Record "Sales & Receivables Setup";
        GLSetup: Record "General Ledger Setup";
        MoveNegSalesLines: Report "Move Negative Sales Lines";
        CreateRetRelDocs: Report "Create Ret.-Related Documents";
        ReportPrint: Codeunit "Test Report-Print";
        DocPrint: Codeunit "Document-Print";
        UserMgt: Codeunit "User Setup Management";
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        JobQueueVisible: Boolean;
        JobQueueUsed: Boolean;
        StatusStyleTxt: Text;
        DocNoVisible: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        ShowWorkflowStatus: Boolean;
        CanCancelApprovalForRecord: Boolean;
        DocumentIsPosted: Boolean;
        OpenPostedSalesReturnOrderQst: Label 'The return order is posted as number %1 and moved to the Posted Sales Credit Memos window.\\Do you want to open the posted credit memo?', Comment = '%1 = posted document number';
        IsCustomerOrContactNotEmpty: Boolean;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        SalesDocCheckFactboxVisible: Boolean;
        IsJournalTemplNameVisible: Boolean;
        IsPaymentMethodCodeVisible: Boolean;
        IsSalesLinesEditable: Boolean;
        VATDateEnabled: Boolean;

    protected var
        IsPostingGroupEditable: Boolean;

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Sell-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        GLSetup.Get();
        IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
        IsPaymentMethodCodeVisible := not GLSetup."Hide Payment Method Code";
        IsSalesLinesEditable := Rec.SalesLinesEditable();
    end;

    procedure CallPostDocument(PostingCodeunitID: Integer)
    begin
        PostDocument(PostingCodeunitID);
    end;

    local procedure PostDocument(PostingCodeunitID: Integer)
    var
        SalesHeader: Record "Sales Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
        LinesInstructionMgt: Codeunit "Lines Instruction Mgt.";
        DocumentIsScheduledForPosting: Boolean;
        IsHandled: Boolean;
    begin
        LinesInstructionMgt.SalesCheckAllLinesHaveQuantityAssigned(Rec);
        Rec.SendToPosting(PostingCodeunitID);

        SalesHeader.SetRange("Document Type", Rec."Document Type");
        SalesHeader.SetRange("No.", Rec."No.");
        DocumentIsPosted := SalesHeader.IsEmpty();

        DocumentIsScheduledForPosting := Rec."Job Queue Status" = Rec."Job Queue Status"::"Scheduled for Posting";
        OnPostDocumentOnAfterCalcDocumentIsScheduledForPosting(Rec, DocumentIsScheduledForPosting, DocumentIsPosted);
        if DocumentIsScheduledForPosting then
            CurrPage.Close();
        CurrPage.Update(false);

        IsHandled := false;
        OnPostDocumentBeforeNavigateAfterPosting(Rec, PostingCodeunitID, DocumentIsPosted, IsHandled);
        if IsHandled then
            exit;

        if PostingCodeunitID <> CODEUNIT::"Sales-Post (Yes/No)" then
            exit;

        if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode()) then
            ShowPostedConfirmationMessage();
    end;

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.SalesLines.PAGE.ApproveCalcInvDisc();
    end;

    local procedure SaveInvoiceDiscountAmount()
    var
        DocumentTotals: Codeunit "Document Totals";
    begin
        CurrPage.SaveRecord();
        DocumentTotals.SalesRedistributeInvoiceDiscountAmountsOnDocument(Rec);
        CurrPage.Update(false);
    end;

    local procedure SalespersonCodeOnAfterValidate()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.SalesLines.PAGE.UpdateForm(true);
    end;

    local procedure PricesIncludingVATOnAfterValid()
    begin
        CurrPage.SalesLines.Page.ForceTotalsCalculation();
        CurrPage.Update();
    end;

    local procedure SetDocNoVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Reminder,FinChMemo;
    begin
        DocNoVisible := DocumentNoVisibility.SalesDocumentNoIsVisible(DocType::"Return Order", Rec."No.");
    end;

    procedure SetPostingGroupEditable()
    var
        BillToCustomer: Record Customer;
    begin
        if BillToCustomer.Get(Rec."Bill-to Customer No.") then
            IsPostingGroupEditable := BillToCustomer."Allow Multiple Posting Groups";
    end;

    procedure ShowPreview()
    var
        SalesPostYesNo: Codeunit "Sales-Post (Yes/No)";
    begin
        SalesPostYesNo.Preview(Rec);
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        JobQueueVisible := Rec."Job Queue Status" = Rec."Job Queue Status"::"Scheduled for Posting";

        OpenApprovalEntriesExistForCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);
        CanCancelApprovalForRecord := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId);
        IsCustomerOrContactNotEmpty := (Rec."Sell-to Customer No." <> '') or (Rec."Sell-to Contact No." <> '');
        IsSalesLinesEditable := Rec.SalesLinesEditable();
        SalesDocCheckFactboxVisible := DocumentErrorsMgt.BackgroundValidationEnabled();
        SetPostingGroupEditable();
    end;

    procedure RunBackgroundCheck()
    begin
        CurrPage.SalesDocCheckFactbox.Page.CheckErrorsInBackground(Rec);
    end;

    local procedure CheckShowBackgrValidationNotification()
    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        if DocumentErrorsMgt.CheckShowEnableBackgrValidationNotification() then
            SetControlAppearance();
    end;

    local procedure ShowPostedConfirmationMessage()
    var
        ReturnOrderSalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if not ReturnOrderSalesHeader.Get(Rec."Document Type", Rec."No.") then begin
            SalesCrMemoHeader.SetRange("No.", Rec."Last Posting No.");
            if SalesCrMemoHeader.FindFirst() then
                if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedSalesReturnOrderQst, SalesCrMemoHeader."No."),
                     InstructionMgt.ShowPostedConfirmationMessageCode())
                then
                    InstructionMgt.ShowPostedDocument(SalesCrMemoHeader, Page::"Sales Return Order");
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnAfterGetRecord(var SalesHeader: Record "Sales Header")
    begin
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeStatisticsAction(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;
#endif
    [IntegrationEvent(true, false)]
    local procedure OnPostDocumentBeforeNavigateAfterPosting(var SalesHeader: Record "Sales Header"; var PostingCodeunitID: Integer; DocumentIsPosted: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnQueryClosePage(var SalesHeader: Record "Sales Header"; CloseAction: Action; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDocumentOnAfterCalcDocumentIsScheduledForPosting(var SalesHeader: Record "Sales Header"; var DocumentIsScheduledForPosting: Boolean; var DocumentIsPosted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupBillToName(var Customer: Record Customer; SalesHeader: Record "Sales Header")
    begin
    end;
}
