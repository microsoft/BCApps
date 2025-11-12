// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.CRM.Contact;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Availability;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Service.Archive;
using Microsoft.Service.Comment;
using Microsoft.Service.Email;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Service.Posting;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using System.Security.User;

page 5900 "Service Order"
{
    Caption = 'Service Order';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Service Header";
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
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = DocNoVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a short description of the service document, such as Order 2001.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer who owns the items in the service document.';

                    trigger OnValidate()
                    begin
                        CustomerNoOnAfterValidate();
                    end;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contact to whom you will deliver the service.';

                    trigger OnValidate()
                    begin
                        if Rec.GetFilter("Contact No.") = xRec."Contact No." then
                            if Rec."Contact No." <> xRec."Contact No." then
                                Rec.SetRange("Contact No.");
                    end;
                }
                group(Control114)
                {
                    ShowCaption = false;
                    Visible = ShowQuoteNo;
                    field("Quote No."; Rec."Quote No.")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the number of the service quote that the service order was created from. You can track the number to service quote documents that you have printed, saved, or emailed.';
                    }
                }
                group("Sell-To")
                {
                    Caption = 'Sell-To';
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the name of the customer to whom the items on the document will be shipped.';
                    }
                    field("Name 2"; Rec."Name 2")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        Visible = false;
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address of the customer to whom the service will be shipped.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Service;
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control45)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Service;
                            QuickEntry = false;
                            ToolTip = 'Specifies the state, province or county related to the service order.';
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the country/region of the address.';

                        trigger OnValidate()
                        var
                            FormatAddress: Codeunit "Format Address";
                        begin
                            IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                        end;
                    }
                    field("Contact Name"; Rec."Contact Name")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies the name of the contact who will receive the service.';
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the phone number of the customer in this service order.';
                }
                field(ContactMobilePhoneNo; SellToContact."Mobile Phone No.")
                {
                    ApplicationArea = Service;
                    Caption = 'Mobile Phone No.';
                    Importance = Additional;
                    Editable = false;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the mobile telephone number of the contact person that the sevice order will be sent to.';
                }
                field("Phone No. 2"; Rec."Phone No. 2")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies your customer''s alternate phone number.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Service;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the customer in this service order.';
                }
                field("Notify Customer"; Rec."Notify Customer")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies how the customer wants to receive notifications about service completion.';
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of this service order.';
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contract associated with the order.';
                }
                field("No. of Archived Versions"; Rec."No. of Archived Versions")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of archived versions for this document.';

                    trigger OnDrillDown()
                    var
                        ServiceHeaderArchive: Record "Service Header Archive";
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        ServiceHeaderArchive.SetRange("Document Type", Rec."Document Type"::Order);
                        ServiceHeaderArchive.SetRange("No.", Rec."No.");
                        ServiceHeaderArchive.SetRange("Doc. No. Occurrence", Rec."Doc. No. Occurrence");
                        Page.RunModal(Page::"Service List Archive", ServiceHeaderArchive);
                        CurrPage.Update(false);
                    end;
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
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
                    Importance = Promoted;
                    ToolTip = 'Specifies the priority of the service order.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order status, which reflects the repair or maintenance status of all service items on the service order.';
                }
                group("Work Description")
                {
                    Caption = 'Work Description';
                    field(WorkDescription; WorkDescription)
                    {
                        ApplicationArea = Service;
                        Caption = 'Work Description';
                        ShowCaption = false;
                        ToolTip = 'Specifies the products or service being offered.';
                        MultiLine = true;
                        Importance = Additional;

                        trigger OnValidate()
                        begin
                            Rec.SetWorkDescription(WorkDescription);
                        end;
                    }
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Release Status"; Rec."Release Status")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies if items in the Service Lines window are ready to be handled in warehouse activities.';
                }
            }
            part(ServItemLines; "Service Order Subform")
            {
                ApplicationArea = Service;
                Enabled = IsServiceLinesEditable;
                Editable = IsServiceLinesEditable;
                SubPageLink = "Document No." = field("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';

                    trigger OnValidate()
                    begin
                        BilltoCustomerNoOnAfterValidat();
                    end;
                }
                field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
                }
                group("Bill-To")
                {
                    Caption = 'Bill-To';
                    field("Bill-to Name"; Rec."Bill-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    }
                    field("Bill-to Name 2"; Rec."Bill-to Name 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name 2';
                        Importance = Additional;
                        QuickEntry = false;
                        Visible = false;
                    }
                    field("Bill-to Address"; Rec."Bill-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        QuickEntry = false;
                        ToolTip = 'Specifies the address of the customer to whom you will send the invoice.';
                    }
                    field("Bill-to Address 2"; Rec."Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    field("Bill-to City"; Rec."Bill-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control48)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; Rec."Bill-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Bill-to Country/Region Code";
                            QuickEntry = false;
                            ToolTip = 'Specifies the state, province or county of the bill-to customer related to the service order.';
                        }
                    }
                    field("Bill-to Post Code"; Rec."Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        QuickEntry = false;
                        ToolTip = 'Specifies the post code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region Code';
                        QuickEntry = false;
                        ToolTip = 'Specifies the customer''s country/region.';

                        trigger OnValidate()
                        var
                            FormatAddress: Codeunit "Format Address";
                        begin
                            IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
                        end;
                    }
                    field("Bill-to Contact"; Rec."Bill-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    }
                    field(BillToContactPhoneNo; BillToContact."Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the person you should contact at the customer you are sending the order to.';
                    }
                    field(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the person you should contact at the customer you are sending the order to.';
                    }
                    field(BillToContactEmail; BillToContact."E-Mail")
                    {
                        ApplicationArea = Service;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the person you should contact at the customer you are sending the order to.';
                    }
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies a customer reference, which will be used when printing service documents.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the salesperson assigned to this service document.';
                }
                field("Max. Labor Unit Price"; Rec."Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies the maximum unit price that can be set for a resource (for example, a technician) on all service lines linked to this order.';

                    trigger OnValidate()
                    begin
                        MaxLaborUnitPriceOnAfterValida();
                    end;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service document should be posted.';
                }
                field("VAT Reporting Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                    Editable = VATDateEnabled;
                    Visible = VATDateEnabled;
                    ToolTip = 'Specifies the date used to include entries on VAT reports in a VAT period. This is either the date that the document was created or posted, depending on your setting on the General Ledger Setup page.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ShowMandatory = ExternalDocNoMandatory;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the transaction is related to trade with a third party within the EU.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of payment discount given, if the customer pays by the date entered in the Pmt. Discount Date field.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the direct-debit mandate that the customer has signed to allow direct debit collection of payments.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for various amounts on the service lines.';

                    trigger OnAssistEdit()
                    begin
                        Clear(ChangeExchangeRate);
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());
                            CurrPage.Update();
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Company Bank Account Code"; Rec."Company Bank Account Code")
                {
                    ApplicationArea = Service;
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
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';

                    trigger OnValidate()
                    begin
                        ShiptoCodeOnAfterValidate();
                    end;
                }
                group("Ship-To")
                {
                    Caption = 'Ship-To';
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Name 2"; Rec."Ship-to Name 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name 2';
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of thethe name of the customer at the address that the items are shipped to.';
                        Visible = false;
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        QuickEntry = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Importance = Additional;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control49)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                            QuickEntry = false;
                            ToolTip = 'Specifies the state, province or county related to the service order.';
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        Importance = Promoted;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        QuickEntry = false;
                        ToolTip = 'Specifies the customer''s country/region.';

                        trigger OnValidate()
                        var
                            FormatAddress: Codeunit "Format Address";
                        begin
                            IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
                        end;
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Importance = Promoted;
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Ship-to Phone"; Rec."Ship-to Phone")
                {
                    ApplicationArea = Service;
                    Caption = 'Ship-to Phone';
                    ToolTip = 'Specifies the phone number of the address where the service items in the order are located.';
                }
                field("Ship-to Phone 2"; Rec."Ship-to Phone 2")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional phone number at address that the items are shipped to.';
                }
                field("Ship-to E-Mail"; Rec."Ship-to E-Mail")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the email address at the address that the items are shipped to.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location (for example, warehouse or distribution center) of the items specified on the service item lines.';
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies information about whether the customer will accept a partial shipment of the order.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
                }
                field("Combine Shipments"; Rec."Combine Shipments")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies whether the order will be included when you use the Combine Shipments function.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field("Warning Status"; Rec."Warning Status")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the response time warning status for the order.';
                }
                field("Link Service to Service Item"; Rec."Link Service to Service Item")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that service lines for items and resources must be linked to a service item line.';
                }
                field("Allocated Hours"; Rec."Allocated Hours")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours allocated to the items in this service order.';
                }
                field("No. of Allocations"; Rec."No. of Allocations")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of resource allocations to service items in this order.';
                }
                field("No. of Unallocated Items"; Rec."No. of Unallocated Items")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of service items in this order that are not allocated to resources.';
                }
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service zone code of the customer''s ship-to address in the service order.';
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the order was created.';

                    trigger OnValidate()
                    begin
                        OrderDateOnAfterValidate();
                    end;
                }
                field("Order Time"; Rec."Order Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the time when the service order was created.';

                    trigger OnValidate()
                    begin
                        OrderTimeOnAfterValidate();
                    end;
                }
                field("Expected Finishing Date"; Rec."Expected Finishing Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when service on the order is expected to be finished.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the starting date of the service, that is, the date when the order status changes from Pending, to In Process for the first time.';
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting time of the service, that is, the time when the order status changes from Pending, to In Process for the first time.';
                }
                field("Actual Response Time (Hours)"; Rec."Actual Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours from order creation, to when the service order status changes from Pending, to In Process.';
                }
                field("Finishing Date"; Rec."Finishing Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the finishing date of the service, that is, the date when the Status field changes to Finished.';
                }
                field("Finishing Time"; Rec."Finishing Time")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the finishing time of the service, that is, the time when the Status field changes to Finished.';

                    trigger OnValidate()
                    begin
                        FinishingTimeOnAfterValidate();
                    end;
                }
                field("Service Time (Hours)"; Rec."Service Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total time in hours that the service specified in the order has taken.';
                }
            }
            group(" Foreign Trade")
            {
                Caption = ' Foreign Trade';
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
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
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                }
            }
        }
        area(factboxes)
        {
            part(ServiceDocCheckFactbox; "Service Doc. Check Factbox")
            {
                ApplicationArea = All;
                Caption = 'Document Check';
                Visible = ServiceDocCheckFactboxVisible;
                SubPageLink = "No." = field("No."),
                              "Document Type" = field("Document Type");
            }
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
                Visible = false;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Service;
                ShowFilter = false;
                Visible = false;
            }
            part(Control1907829707; "Service Hist. Sell-to FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = true;
            }
            part(Control1902613707; "Service Hist. Bill-to FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(Control1906530507; "Service Item Line FactBox")
            {
                ApplicationArea = Service;
                Provider = ServItemLines;
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Line No." = field("Line No.");
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
                action("Demand Overview")
                {
                    ApplicationArea = Planning;
                    Caption = 'Demand Overview';
                    Image = Forecast;
                    ToolTip = 'Get an overview of demand for your items when planning sales, production, projects, or service management and when they will be available.';

                    trigger OnAction()
                    var
                        DemandOverview: Page "Demand Overview";
                    begin
                        DemandOverview.SetCalculationParameter(true);
                        DemandOverview.SetParameters(0D, Microsoft.Inventory.Requisition."Demand Order Source Type"::"Service Demand", Rec."No.", '', '');
                        DemandOverview.RunModal();
                    end;
                }
                action("<Action7>")
                {
                    AccessByPermission = TableData "Order Promising Line" = R;
                    ApplicationArea = OrderPromising;
                    Caption = 'Order Promising';
                    Image = OrderPromising;
                    ToolTip = 'Calculate the shipment and delivery dates based on the item''s known and expected availability dates, and then promise the dates to the customer.';

                    trigger OnAction()
                    var
                        OrderPromisingLine: Record "Order Promising Line";
                        OrderPromisingLines: Page "Order Promising Lines";
                    begin
                        Clear(OrderPromisingLines);
                        OrderPromisingLines.SetSource(OrderPromisingLine."Source Type"::"Service Order");
                        Clear(OrderPromisingLine);
                        OrderPromisingLine.SetRange("Source Type", OrderPromisingLine."Source Type"::"Service Order");
                        OrderPromisingLine.SetRange("Source ID", Rec."No.");
                        OrderPromisingLines.SetTableView(OrderPromisingLine);
                        OrderPromisingLines.RunModal();
                    end;
                }
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
                    Enabled = Rec."No." <> '';
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
                        ServDocLog: Record "Service Document Log";
                    begin
                        ServDocLog.ShowServDocLog(Rec);
                    end;
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
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Header"),
                                  "Table Subtype" = field("Document Type"),
                                  "No." = field("No."),
                                  Type = const(General);
                    ToolTip = 'View or add comments for the record.';
                }
                action(DocAttach)
                {
                    ApplicationArea = Service;
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
            group("<Action36>")
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
                    ToolTip = 'View a list of ongoing sales invoices for the order.';

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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Customer")
                {
                    ApplicationArea = Service;
                    Caption = '&Create Customer';
                    Image = NewCustomer;
                    ToolTip = 'Create a new customer card for the customer on the service document.';

                    trigger OnAction()
                    var
                        ServOrderMgt: Codeunit ServOrderManagement;
                    begin
                        ServOrderMgt.CreateNewCustomer(Rec);
                        CurrPage.Update(true);
                    end;
                }
                action("Archive Document")
                {
                    ApplicationArea = Service;
                    Caption = 'Archi&ve Document';
                    Image = Archive;
                    ToolTip = 'Send the document to the archive, for example because it is too soon to delete it. Later, you delete or reprocess the archived document.';

                    trigger OnAction()
                    var
                        ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
                    begin
                        ServiceDocumentArchiveMgmt.ArchiveServiceDocument(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            group(Action27)
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
                        ReleaseServiceDoc: Codeunit "Release Service Document";
                    begin
                        ReleaseServiceDoc.PerformManualReopen(Rec);
                    end;
                }
                action("Create Whse Shipment")
                {
                    AccessByPermission = TableData "Warehouse Shipment Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Warehouse Shipment';
                    Image = NewShipment;
                    ToolTip = 'Prepare to pick and ship the service item. ';

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
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(TestReport)
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
                    var
                        InstructionMgt: Codeunit "Instruction Mgt.";
                    begin
                        DocumentIsPosted := Rec.SendToPost(Codeunit::"Service-Post (Yes/No)");
                        if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode()) then
                            ShowPostedConfirmationMessage();
                        CurrPage.Update(false);
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
                        ServPostYesNo: Codeunit "Service-Post (Yes/No)";
                    begin
                        ServHeader.Get(Rec."Document Type", Rec."No.");
                        ServPostYesNo.PreviewDocument(ServHeader);
                        DocumentIsPosted := not ServHeader.Get(Rec."Document Type", Rec."No.");
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
                        DocumentIsPosted := Rec.SendToPost(Codeunit::"Service-Post+Print");
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
                    begin
                        Clear(ServHeader);
                        ServHeader.CopyFilters(Rec);
                        ServHeader.SetRange(Status, ServHeader.Status::Finished);
                        REPORT.RunModal(REPORT::"Batch Post Service Orders", true, true, ServHeader);
                        CurrPage.Update(false);
                    end;
                }
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
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Category7)
                {
                    Caption = 'Posting';
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
                actionref("Archive Document_Promoted"; "Archive Document")
                {
                }
                group(Category_Category6)
                {
                    Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 5.';
                    ShowAs = SplitButton;

                    actionref("Release to Ship_Promoted"; "Release to Ship")
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
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
                actionref("Create Whse Shipment_Promoted"; "Create Whse Shipment")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Category4)
            {
                Caption = 'Warehouse', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Category8)
            {
                Caption = 'Order', Comment = 'Generated from the PromotedActionCategories property index 7.';

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
                actionref(DocAttach_Promoted; DocAttach)
                {
                }
                separator(Navigate_Separator)
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
            group(Category_Category9)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 8.';
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
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ServLogMgt: Codeunit ServLogManagement;
    begin
        CurrPage.SaveRecord();
        Clear(ServLogMgt);
        ServLogMgt.ServHeaderManualDelete(Rec);
        exit(Rec.ConfirmDeletion());
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        UserMgt: Codeunit "User Setup Management";
    begin
        Rec."Document Type" := Rec."Document Type"::Order;
        Rec."Responsibility Center" := UserMgt.GetServiceFilter();
        if (not DocNoVisible) and (Rec."No." = '') then
            Rec.SetCustomerFromFilter();
    end;

    trigger OnOpenPage()
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        Rec.SetSecurityFilterOnRespCenter();

        if (Rec."No." <> '') and (Rec."Customer No." = '') then
            DocumentIsPosted := (not Rec.Get(Rec."Document Type", Rec."No."));

        ActivateFields();
        SetDocNoVisible();
        CheckShowBackgrValidationNotification();
        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    end;

    trigger OnAfterGetRecord()
    begin
        ActivateFields();
        BillToContact.GetOrClear(Rec."Bill-to Contact No.");
        SellToContact.GetOrClear(Rec."Contact No.");
        ActivateFields();
        WorkDescription := Rec.GetWorkDescription();
        CurrPage.IncomingDocAttachFactBox.Page.SetCurrentRecordID(Rec.RecordId);

        OnAfterOnAfterGetRecord(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnQueryClosePage(Rec, DocumentIsPosted, IsHandled);
        if not IsHandled then
            if not DocumentIsPosted then
                exit(Rec.ConfirmCloseUnposted());
    end;

    var
        ServHeader: Record "Service Header";
        BillToContact: Record Contact;
        SellToContact: Record Contact;
        ServiceMgtSetup: Record "Service Mgt. Setup";
        ChangeExchangeRate: Page "Change Exchange Rate";
        WorkDescription: Text;
        DocumentIsPosted: Boolean;
        OpenPostedServiceOrderQst: Label 'The order is posted as number %1 and moved to the Posted Service Invoices window.\\Do you want to open the posted invoice?', Comment = '%1 = posted document number';
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        ServiceDocCheckFactboxVisible: Boolean;
        IsServiceLinesEditable: Boolean;
        ShowQuoteNo: Boolean;
        ExternalDocNoMandatory: Boolean;
        VATDateEnabled: Boolean;
        DocNoVisible: Boolean;

    local procedure ActivateFields()
    var
        FormatAddress: Codeunit "Format Address";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        ServiceDocCheckFactboxVisible := DocumentErrorsMgt.BackgroundValidationEnabled();
        IsServiceLinesEditable := Rec.ServiceLinesEditable();
        ShowQuoteNo := Rec."Quote No." <> '';
        SetExtDocNoMandatoryCondition();
    end;

    local procedure SetDocNoVisible()
    var
        ServDocumentNoVisibility: Codeunit "Serv. Document No. Visibility";
        DocType: Option Quote,"Order",Invoice,"Credit Memo",Contract;
    begin
        DocNoVisible := ServDocumentNoVisibility.ServiceDocumentNoIsVisible(DocType::"Order", Rec."No.");
    end;

    local procedure SetControlAppearance()
    begin
        IsServiceLinesEditable := Rec.ServiceLinesEditable();
    end;

    procedure RunBackgroundCheck()
    begin
        CurrPage.ServiceDocCheckFactbox.Page.CheckErrorsInBackground(Rec);
    end;

    local procedure CheckShowBackgrValidationNotification()
    var
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
    begin
        if DocumentErrorsMgt.CheckShowEnableBackgrValidationNotification() then
            ActivateFields();
    end;

    local procedure CustomerNoOnAfterValidate()
    begin
        if Rec.GetFilter("Customer No.") = xRec."Customer No." then
            if Rec."Customer No." <> xRec."Customer No." then
                Rec.SetRange("Customer No.");
        IsServiceLinesEditable := Rec.ServiceLinesEditable();
        CurrPage.Update();
    end;

    local procedure SetExtDocNoMandatoryCondition()
    begin
        ServiceMgtSetup.GetRecordOnce();
        ExternalDocNoMandatory := ServiceMgtSetup."Ext. Doc. No. Mandatory";
    end;

    local procedure BilltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update();
    end;

    local procedure MaxLaborUnitPriceOnAfterValida()
    begin
        CurrPage.SaveRecord();
    end;

    local procedure PricesIncludingVATOnAfterValid()
    begin
        CurrPage.Update();
    end;

    local procedure ShiptoCodeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure OrderTimeOnAfterValidate()
    begin
        Rec.UpdateResponseDateTime();
        CurrPage.Update();
    end;

    local procedure OrderDateOnAfterValidate()
    begin
        Rec.UpdateResponseDateTime();
        CurrPage.Update();
    end;

    local procedure FinishingTimeOnAfterValidate()
    begin
        CurrPage.Update(true);
    end;

    local procedure ShowPostedConfirmationMessage()
    var
        OrderServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if not OrderServiceHeader.Get(Rec."Document Type", Rec."No.") then begin
            ServiceInvoiceHeader.SetRange("No.", Rec."Last Posting No.");
            if ServiceInvoiceHeader.FindFirst() then
                if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedServiceOrderQst, ServiceInvoiceHeader."No."),
                     InstructionMgt.ShowPostedConfirmationMessageCode())
                then
                    InstructionMgt.ShowPostedDocument(ServiceInvoiceHeader, Page::"Service Order");
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnAfterGetRecord(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnQueryClosePage(var ServiceHeader: Record "Service Header"; var DocumentIsPosted: Boolean; var IsHandled: Boolean);
    begin
    end;
}
