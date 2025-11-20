// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Service.Reports;
using Microsoft.Utilities;
using System.Security.User;
using System.Utilities;

page 6050 "Service Contract"
{
    Caption = 'Service Contract';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Service Contract Header";
    SourceTableView = where("Contract Type" = filter(Contract));

    layout
    {
        area(content)
        {
            group(Control1)
            {
                Caption = 'General';
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    Visible = DocNoVisible;
                    ToolTip = 'Specifies the number of the service contract or service contract quote.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service contract.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer who owns the service items in the service contract/contract quote.';

                    trigger OnValidate()
                    begin
                        CustomerNoOnAfterValidate();
                    end;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the contact who will receive the service delivery.';
                }
                group(Control13)
                {
                    ShowCaption = false;
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the customer in the service contract.';
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the customer''s address.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the name of the city in where the customer is located.';
                    }
                    group(Control24)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Service;
                            QuickEntry = false;
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the country/region of the address.';

                        trigger OnValidate()
                        begin
                            IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                        end;
                    }
                    field("Contact Name"; Rec."Contact Name")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the person you regularly contact when you do business with the customer in this service contract.';
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the customer telephone number.';
                }
                field(SellToMobilePhoneNo; SellToContact."Mobile Phone No.")
                {
                    ApplicationArea = Service;
                    Caption = 'Mobile Phone No.';
                    Importance = Additional;
                    Editable = false;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the customer''s mobile telephone number.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Service;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the customer''s email address.';
                }
                field("Contract Group Code"; Rec."Contract Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contract group code assigned to the service contract.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the salesperson assigned to this service contract.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the starting date of the service contract.';

                    trigger OnValidate()
                    begin
                        StartingDateOnAfterValidate();
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the service contract or contract quote.';

                    trigger OnValidate()
                    begin
                        ActivateFields();
                        StatusOnAfterValidate();
                    end;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Change Status"; Rec."Change Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if a service contract or contract quote is locked or open for changes.';
                }
            }
            part(ServContractLines; "Service Contract Subform")
            {
                ApplicationArea = Service;
                SubPageLink = "Contract No." = field("Contract No.");
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
                group(Control27)
                {
                    ShowCaption = false;
                    field("Bill-to Name"; Rec."Bill-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    }
                    field("Bill-to Address"; Rec."Bill-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address of the customer to whom you sent the invoice.';
                    }
                    field("Bill-to Address 2"; Rec."Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    field("Bill-to City"; Rec."Bill-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control33)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; Rec."Bill-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Bill-to Country/Region Code";
                            QuickEntry = false;
                        }
                    }
                    field("Bill-to Post Code"; Rec."Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        QuickEntry = false;

                        trigger OnValidate()
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
                        ToolTip = 'Specifies the telephone number of the person at the customer''s billing address.';
                    }
                    field(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the person at the customer''s billing address.';
                    }
                    field(BillToContactEmail; BillToContact."E-Mail")
                    {
                        ApplicationArea = Service;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the person at the customer''s billing address.';
                    }
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the customer''s reference number.';
                }
                field("Serv. Contract Acc. Gr. Code"; Rec."Serv. Contract Acc. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code associated with the service contract account group.';
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
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies how to make payment, such as with bank transfer, cash, or check.';
                }
                field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies the direct-debit mandate that the customer has signed to allow direct-debit collection of payments.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency used to calculate the amounts in the documents related to this contract.';
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
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Name 2"; Rec."Ship-to Name 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name 2';
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the name of the customer that the items are shipped to.';
                        QuickEntry = false;
                        Visible = false;
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control38)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                            QuickEntry = false;
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        DrillDown = false;
                        Importance = Promoted;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        QuickEntry = false;
                    }
                    field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Phone No.';
                        ToolTip = 'Specifies the telephone number of the company''s shipping address.';
                    }
                }
            }
            group(Service)
            {
                Caption = 'Service';
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the service zone of the customer ship-to address.';
                }
                field("Service Period"; Rec."Service Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a default service period for the items in the contract.';

                    trigger OnValidate()
                    begin
                        ServicePeriodOnAfterValidate();
                    end;
                }
                field("First Service Date"; Rec."First Service Date")
                {
                    ApplicationArea = Service;
                    Editable = FirstServiceDateEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date of the first expected service for the service items in the contract.';

                    trigger OnValidate()
                    begin
                        FirstServiceDateOnAfterValidat();
                    end;
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the response time for the service contract.';

                    trigger OnValidate()
                    begin
                        ResponseTimeHoursOnAfterValida();
                    end;
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order type assigned to service orders linked to this contract.';
                }
            }
            group("Invoice Details")
            {
                Caption = 'Invoice Details';
                field("Annual Amount"; Rec."Annual Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount that will be invoiced annually for the service contract or contract quote.';

                    trigger OnValidate()
                    begin
                        AnnualAmountOnAfterValidate();
                    end;
                }
                field("Allow Unbalanced Amounts"; Rec."Allow Unbalanced Amounts")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the contents of the Calcd. Annual Amount field are copied into the Annual Amount field in the service contract or contract quote.';

                    trigger OnValidate()
                    begin
                        AllowUnbalancedAmountsOnAfterV();
                    end;
                }
                field("Calcd. Annual Amount"; Rec."Calcd. Annual Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the sum of the Line Amount field values on all contract lines associated with the service contract or contract quote.';
                }
                field(InvoicePeriod; Rec."Invoice Period")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the invoice period for the service contract.';
                }
                field(NextInvoiceDate; Rec."Next Invoice Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date of the next invoice for this service contract.';
                }
                field(AmountPerPeriod; Rec."Amount per Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount that will be invoiced for each invoice period for the service contract.';
                }
                field(NextInvoicePeriod; Rec.NextInvoicePeriod())
                {
                    ApplicationArea = Service;
                    Caption = 'Next Invoice Period';
                    ToolTip = 'Specifies the ending date of the next invoice period for the service contract.';
                }
                field("Last Invoice Date"; Rec."Last Invoice Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when this service contract was last invoiced.';
                }
                field(Prepaid; Rec.Prepaid)
                {
                    ApplicationArea = Service;
                    Enabled = PrepaidEnable;
                    ToolTip = 'Specifies that this service contract is prepaid.';

                    trigger OnValidate()
                    begin
                        PrepaidOnAfterValidate();
                    end;
                }
                field("Automatic Credit Memos"; Rec."Automatic Credit Memos")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a credit memo is created when you remove a contract line.';
                }
                field("Invoice after Service"; Rec."Invoice after Service")
                {
                    ApplicationArea = Service;
                    Enabled = InvoiceAfterServiceEnable;
                    ToolTip = 'Specifies that you can only invoice the contract if you have posted a service order since last time you invoiced the contract.';

                    trigger OnValidate()
                    begin
                        InvoiceafterServiceOnAfterVali();
                    end;
                }
                field("Combine Invoices"; Rec."Combine Invoices")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies you want to combine invoices for this service contract with invoices for other service contracts with the same bill-to customer.';
                }
                field("Contract Lines on Invoice"; Rec."Contract Lines on Invoice")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that you want the lines for this contract to appear as text on the invoice.';
                }
                field("No. of Unposted Invoices"; Rec."No. of Unposted Invoices")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of unposted service invoices linked to the service contract.';
                }
                field("No. of Unposted Credit Memos"; Rec."No. of Unposted Credit Memos")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of unposted credit memos linked to the service contract.';
                }
                field("No. of Posted Invoices"; Rec."No. of Posted Invoices")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of posted service invoices linked to the service contract.';
                }
                field("No. of Posted Credit Memos"; Rec."No. of Posted Credit Memos")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of posted credit memos linked to this service contract.';
                }
            }
            group("Price Update")
            {
                Caption = 'Price Update';
                field("Price Update Period"; Rec."Price Update Period")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the price update period for this service contract.';
                }
                field("Next Price Update Date"; Rec."Next Price Update Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the next date you want contract prices to be updated.';
                }
                field("Last Price Update %"; Rec."Last Price Update %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the price update percentage you used the last time you updated the contract prices.';
                }
                field("Last Price Update Date"; Rec."Last Price Update Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date you last updated the contract prices.';
                }
                field("Print Increase Text"; Rec."Print Increase Text")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the standard text code printed on service invoices, informing the customer which prices have been updated since the last invoice.';
                }
                field("Price Inv. Increase Code"; Rec."Price Inv. Increase Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the standard text code printed on service invoices, informing the customer which prices have been updated since the last invoice.';
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service contract expires, which is when the service contract is no longer valid. The date is copied to the Contract Expiration Date field for a newly added service contract line. The date in this field must not be earlier than the value in the Starting Date field.';

                    trigger OnValidate()
                    begin
                        ExpirationDateOnAfterValidate();
                    end;
                }
                field("Cancel Reason Code"; Rec."Cancel Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a reason code for canceling the service contract.';
                }
                field("Max. Labor Unit Price"; Rec."Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the maximum unit price that can be set for a resource on all service orders and lines for the service contract.';
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
                SubPageLink = "Table ID" = const(Database::"Service Contract Header"),
                              "Document Type" = const("Service Contract"),
                              "No." = field("Contract No.");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Service Contract Header"),
                              "Document Type" = const("Service Contract"),
                              "No." = field("Contract No.");
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
            group(Overview)
            {
                Caption = 'Overview';
                group("Ser&vice Overview")
                {
                    Caption = 'Ser&vice Overview';
                    Image = Tools;
                    action("Service Orders")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Orders';
                        Image = Document;
                        RunObject = Page "Service List";
                        RunPageLink = "Document Type" = const(Order),
                                      "Contract No." = field("Contract No.");
                        RunPageView = sorting("Contract No.");
                        ToolTip = 'Open the list of ongoing service orders.';
                    }
                    action("Posted Service Shipments")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Shipments';
                        Image = PostedShipment;
                        ToolTip = 'Open the list of posted service shipments.';

                        trigger OnAction()
                        var
                            TempServShptHeader: Record "Service Shipment Header" temporary;
                        begin
                            CollectShpmntsByLineContractNo(TempServShptHeader);
                            PAGE.RunModal(PAGE::"Posted Service Shipments", TempServShptHeader);
                        end;
                    }
                    action("Posted Service Invoices")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Invoices';
                        Image = PostedServiceOrder;
                        RunObject = Page "Service Document Registers";
                        RunPageLink = "Source Document No." = field("Contract No.");
                        RunPageView = sorting("Source Document Type", "Source Document No.", "Destination Document Type", "Destination Document No.")
                                      where("Source Document Type" = const(Contract),
                                            "Destination Document Type" = const("Posted Invoice"));
                        ToolTip = 'Open the list of posted service invoices.';
                    }
                }
            }
            group("&Contract")
            {
                Caption = '&Contract';
                Image = Agreement;
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
                        CurrPage.SaveRecord();
                    end;
                }
                action("Service Dis&counts")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Dis&counts';
                    Image = Discount;
                    RunObject = Page "Contract/Service Discounts";
                    RunPageLink = "Contract Type" = field("Contract Type"),
                                  "Contract No." = field("Contract No.");
                    ToolTip = 'View or edit the discounts that you grant for the contract on spare parts in particular service item groups, the discounts on resource hours for resources in particular resource groups, and the discounts on particular service costs.';
                }
                action("Service &Hours")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Hours';
                    Image = ServiceHours;
                    RunObject = Page "Service Hours";
                    RunPageLink = "Service Contract No." = field("Contract No."),
                                  "Service Contract Type" = filter(Contract);
                    ToolTip = 'View the service hours that are valid for the service contract. This window displays the starting and ending service hours for the contract for each weekday.';
                }
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Action178)
                    {
                        ApplicationArea = Service;
                        Caption = 'Statistics';
                        Image = Statistics;
                        RunObject = Page "Contract Statistics";
                        RunPageLink = "Contract Type" = const(Contract),
                                      "Contract No." = field("Contract No.");
                        ShortCutKey = 'F7';
                        ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    }
                    action("Tr&endscape")
                    {
                        ApplicationArea = Service;
                        Caption = 'Tr&endscape';
                        Image = Trendscape;
                        RunObject = Page "Contract Trendscape";
                        RunPageLink = "Contract Type" = const(Contract),
                                      "Contract No." = field("Contract No.");
                        ToolTip = 'View a detailed account of service item transactions by time intervals.';
                    }
                }
                action("Filed Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Filed Contracts';
                    Image = Agreement;
                    RunObject = Page "Filed Service Contract List";
                    RunPageLink = "Contract Type Relation" = field("Contract Type"),
                                  "Contract No. Relation" = field("Contract No.");
                    RunPageView = sorting("Contract Type Relation", "Contract No. Relation", "File Date", "File Time")
                                  order(descending);
                    ToolTip = 'View service contracts that are filed.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Contract"),
                                  "Table Subtype" = field("Contract Type"),
                                  "No." = field("Contract No."),
                                  "Table Line No." = const(0);
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
                action("&Gain/Loss Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Gain/Loss Entries';
                    Image = GainLossEntries;
                    RunObject = Page "Contract Gain/Loss Entries";
                    RunPageLink = "Contract No." = field("Contract No.");
                    RunPageView = sorting("Contract No.", "Change Date")
                                  order(descending);
                    ToolTip = 'View the contract number, reason code, contract group code, responsibility center, customer number, ship-to code, customer name, and type of change, as well as the contract gain and loss. You can print all your service contract gain/loss entries.';
                }
            }
            group(History)
            {
                Caption = 'History';
                action("C&hange Log")
                {
                    ApplicationArea = Service;
                    Caption = 'C&hange Log';
                    Image = ChangeLog;
                    RunObject = Page "Contract Change Log";
                    RunPageLink = "Contract No." = field("Contract No.");
                    RunPageView = sorting("Contract No.")
                                  order(descending);
                    ToolTip = 'View all changes that have been made to the service contract.';
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Contract No." = field("Contract No.");
                    RunPageView = sorting("Service Contract No.", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Contract No." = field("Contract No.");
                    RunPageView = sorting("Service Contract No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
            }
        }
        area(processing)
        {
            group(General)
            {
                Caption = 'General';
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
                        ServDocumentPrint.PrintServiceContract(Rec);
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
                        ServiceContractHeader: Record "Service Contract Header";
                        ServDocumentPrint: Codeunit "Serv. Document Print";
                    begin
                        ServiceContractHeader := Rec;
                        ServiceContractHeader.SetRecFilter();
                        ServDocumentPrint.PrintServiceContractToDocumentAttachment(ServiceContractHeader);
                    end;
                }
            }
            group("New Documents")
            {
                Caption = 'New Documents';
                action("Create Service Credit &Memo")
                {
                    ApplicationArea = Service;
                    Caption = 'Create Service Credit &Memo';
                    Image = CreateCreditMemo;
                    ToolTip = 'Create a new credit memo for the related service invoice.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        W1: Dialog;
                        CreditNoteNo: Code[20];
                        i: Integer;
                        j: Integer;
                        LineFound: Boolean;
                        IsHandled: Boolean;
                    begin
                        CurrPage.Update();

                        IsHandled := false;
                        OnCreateServiceCreditMemoOnBeforeAction(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        Rec.TestField(Status, Rec.Status::Signed);
                        if Rec."No. of Unposted Credit Memos" <> 0 then
                            if not ConfirmManagement.GetResponseOrDefault(Text009, true) then
                                exit;

                        ServContractMgt.CopyCheckSCDimToTempSCDim(Rec);

                        if not ConfirmManagement.GetResponseOrDefault(Text010, true) then
                            exit;

                        ServContractLine.Reset();
                        ServContractLine.SetCurrentKey("Contract Type", "Contract No.", Credited, "New Line");
                        ServContractLine.SetRange("Contract Type", Rec."Contract Type");
                        ServContractLine.SetRange("Contract No.", Rec."Contract No.");
                        ServContractLine.SetRange(Credited, false);
                        ServContractLine.SetFilter("Credit Memo Date", '>%1&<=%2', 0D, WorkDate());
                        i := ServContractLine.Count();
                        j := 0;
                        if ServContractLine.Find('-') then begin
                            LineFound := true;
                            W1.Open(
                              Text011 +
                              '@1@@@@@@@@@@@@@@@@@@@@@');
                            Clear(ServContractMgt);
                            ServContractMgt.InitCodeUnit();
                            OnCreateServiceCreditMemoOnAfterInitCodeunit(Rec, ServContractLine, ServContractMgt);
                            repeat
                                ServContractLine1 := ServContractLine;
                                CreditNoteNo := ServContractMgt.CreateContractLineCreditMemo(ServContractLine1, false);
                                j := j + 1;
                                W1.Update(1, Round(j / i * 10000, 1));
                            until ServContractLine.Next() = 0;
                            ServContractMgt.FinishCodeunit();
                            W1.Close();
                            CurrPage.Update(false);
                        end;
                        ServContractLine.SetFilter("Credit Memo Date", '>%1', WorkDate());
                        if CreditNoteNo <> '' then
                            Message(StrSubstNo(Text012, CreditNoteNo))
                        else
                            if not ServContractLine.Find('-') or LineFound then
                                Message(Text013)
                            else
                                Message(Text016, ServContractLine.FieldCaption("Credit Memo Date"), ServContractLine."Credit Memo Date");
                    end;
                }
                action(CreateServiceInvoice)
                {
                    ApplicationArea = Service;
                    Caption = 'Create Service &Invoice';
                    Image = NewInvoice;
                    ToolTip = 'Create a service invoice for a service contract that is due for invoicing. ';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        CurrPage.Update();
                        Rec.TestField(Status, Rec.Status::Signed);
                        Rec.TestField("Change Status", Rec."Change Status"::Locked);

                        if Rec."No. of Unposted Invoices" <> 0 then
                            if not ConfirmManagement.GetResponseOrDefault(Text003, true) then
                                exit;

                        if Rec."Invoice Period" = Rec."Invoice Period"::None then
                            Error(
                              Text004,
                              Rec.TableCaption, Rec."Contract No.", Rec.FieldCaption("Invoice Period"), Format(Rec."Invoice Period"));

                        if Rec."Next Invoice Date" > WorkDate() then
                            if (Rec."Last Invoice Date" = 0D) and
                               (Rec."Starting Date" < Rec."Next Invoice Period Start")
                            then begin
                                Clear(ServContractMgt);
                                ServContractMgt.InitCodeUnit();
                                if ServContractMgt.CreateRemainingPeriodInvoice(Rec) <> '' then
                                    Message(Text006);
                                ServContractMgt.FinishCodeunit();
                                exit;
                            end else
                                Error(Text005);

                        ServContractMgt.CopyCheckSCDimToTempSCDim(Rec);

                        if ConfirmManagement.GetResponseOrDefault(Text007, true) then begin
                            Clear(ServContractMgt);
                            ServContractMgt.InitCodeUnit();
                            ServContractMgt.CreateInvoice(Rec);
                            ServContractMgt.FinishCodeunit();
                            Message(Text008);
                        end;
                    end;
                }
            }
            group(Lock)
            {
                Caption = 'Lock';
                action(LockContract)
                {
                    ApplicationArea = Service;
                    Caption = '&Lock Contract';
                    Image = Lock;
                    ToolTip = 'Make sure that the changes will be part of the contract.';

                    trigger OnAction()
                    var
                        LockOpenServContract: Codeunit "Lock-OpenServContract";
                    begin
                        CurrPage.Update();
                        LockOpenServContract.LockServContract(Rec);
                        CurrPage.Update();
                    end;
                }
                action(OpenContract)
                {
                    ApplicationArea = Service;
                    Caption = '&Open Contract';
                    Image = ReOpen;
                    ToolTip = 'Open the service contract.';

                    trigger OnAction()
                    var
                        LockOpenServContract: Codeunit "Lock-OpenServContract";
                    begin
                        CurrPage.Update();
                        LockOpenServContract.OpenServContract(Rec);
                        CurrPage.Update();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(SelectContractLines)
                {
                    ApplicationArea = Service;
                    Caption = '&Select Contract Lines';
                    Image = CalculateLines;
                    ToolTip = 'Open the list of all the service items that are registered to the customer and select which to include in the contract. ';

                    trigger OnAction()
                    begin
                        CheckRequiredFields();
                        GetServItemLine();
                    end;
                }
                action("&Remove Contract Lines")
                {
                    ApplicationArea = Service;
                    Caption = '&Remove Contract Lines';
                    Image = RemoveLine;
                    ToolTip = 'Remove the selected contract lines from the service contract, for example because you remove the corresponding service items as they are expired or broken.';

                    trigger OnAction()
                    begin
                        ServContractLine.Reset();
                        ServContractLine.SetRange("Contract Type", Rec."Contract Type");
                        ServContractLine.SetRange("Contract No.", Rec."Contract No.");
                        REPORT.RunModal(REPORT::"Remove Lines from Contract", true, true, ServContractLine);
                        CurrPage.Update();
                    end;
                }
                action(SignContract)
                {
                    ApplicationArea = Service;
                    Caption = 'Si&gn Contract';
                    Image = Signature;
                    ToolTip = 'Confirm the contract.';

                    trigger OnAction()
                    var
                        SignServContractDoc: Codeunit SignServContractDoc;
                    begin
                        CurrPage.Update();
                        SignServContractDoc.SignContract(Rec);
                        CurrPage.Update();
                    end;
                }
                action("C&hange Customer")
                {
                    ApplicationArea = Service;
                    Caption = 'C&hange Customer';
                    Image = ChangeCustomer;
                    ToolTip = 'Change the customer in a service contract. If a service item that is subject to a service contract is registered in other contracts owned by the customer, the owner is automatically changed for all service item-related contracts and all contract-related service items.';

                    trigger OnAction()
                    begin
                        Clear(ChangeCustomerinContract);
                        ChangeCustomerinContract.SetRecord(Rec."Contract No.");
                        ChangeCustomerinContract.RunModal();
                    end;
                }
                action("Copy &Document...")
                {
                    ApplicationArea = Service;
                    Caption = 'Copy &Document...';
                    Image = CopyDocument;
                    ToolTip = 'Copy document lines and header information from another service contractor to this contract to quickly create a similar document.';

                    trigger OnAction()
                    begin
                        CheckRequiredFields();
                        Clear(CopyServDoc);
                        CopyServDoc.SetServContractHeader(Rec);
                        CopyServDoc.RunModal();
                    end;
                }
                action("&File Contract")
                {
                    ApplicationArea = Service;
                    Caption = '&File Contract';
                    Image = Agreement;
                    ToolTip = 'Record and archive a copy of the contract. Service contracts are automatically filed when you convert contract quotes to service contracts or cancel service contracts.';

                    trigger OnAction()
                    var
                        FiledServiceContractHeader: Record "Filed Service Contract Header";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if ConfirmManagement.GetResponseOrDefault(Text014, true) then
                            FiledServiceContractHeader.FileContract(Rec);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Contract Details")
            {
                ApplicationArea = Service;
                Caption = 'Contract Details';
                Image = "Report";
                RunObject = Report "Service Contract-Detail";
                ToolTip = 'Specifies billable prices for the project task that are related to items.';
            }
            action("Contract Gain/Loss Entries")
            {
                ApplicationArea = Service;
                Caption = 'Contract Gain/Loss Entries';
                Image = "Report";
                RunObject = Report "Contract Gain/Loss Entries";
                ToolTip = 'Specifies billable prices for the project task that are related to G/L accounts, expressed in the local currency.';
            }
            action("Contract Invoicing")
            {
                ApplicationArea = Service;
                Caption = 'Contract Invoicing';
                Image = "Report";
                RunObject = Report "Contract Invoicing";
                ToolTip = 'Specifies all billable profits for the project task.';
            }
            action("Contract Price Update - Test")
            {
                ApplicationArea = Service;
                Caption = 'Contract Price Update - Test';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Contract Price Update - Test";
                ToolTip = 'View the contracts numbers, customer numbers, contract amounts, price update percentages, and any errors that occur. You can test which service contracts need price updates up to the date that you have specified.';
            }
            action("Prepaid Contract")
            {
                ApplicationArea = Prepayments;
                Caption = 'Prepaid Contract';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Prepaid Contr. Entries - Test";
                ToolTip = 'View the prepaid service contract.';
            }
            action("Expired Contract Lines")
            {
                ApplicationArea = Service;
                Caption = 'Expired Contract Lines';
                Image = "Report";
                RunObject = Report "Expired Contract Lines - Test";
                ToolTip = 'View the service contract, the service items to be removed, the contract expiration dates, and the line amounts.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(OpenContract_Promoted; OpenContract)
                {
                }
                actionref(LockContract_Promoted; LockContract)
                {
                }
                actionref(SignContract_Promoted; SignContract)
                {
                }
                actionref(CreateServiceInvoice_Promoted; CreateServiceInvoice)
                {
                }
                actionref("Create Service Credit &Memo_Promoted"; "Create Service Credit &Memo")
                {
                }
            }
            group(Category_Prepare)
            {
                Caption = 'Prepare';

                actionref("Copy &Document..._Promoted"; "Copy &Document...")
                {
                }
                actionref(SelectContractLines_Promoted; SelectContractLines)
                {
                }
                actionref("C&hange Customer_Promoted"; "C&hange Customer")
                {
                }
                actionref("&File Contract_Promoted"; "&File Contract")
                {
                }
                actionref("&Remove Contract Lines_Promoted"; "&Remove Contract Lines")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref(AttachAsPDF_Promoted; AttachAsPDF)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Contract', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Action178_Promoted; Action178)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(DocAttach_Promoted; DocAttach)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Contract Details_Promoted"; "Contract Details")
                {
                }
                actionref("Contract Gain/Loss Entries_Promoted"; "Contract Gain/Loss Entries")
                {
                }
                actionref("Contract Invoicing_Promoted"; "Contract Invoicing")
                {
                }
                actionref("Expired Contract Lines_Promoted"; "Expired Contract Lines")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Calcd. Annual Amount", "No. of Posted Invoices", "No. of Unposted Invoices");
        ActivateFields();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.UpdateShiptoCode();
        SellToContact.GetOrClear(Rec."Contact No.");
        BillToContact.GetOrClear(Rec."Bill-to Contact No.");
    end;

    trigger OnInit()
    begin
        InvoiceAfterServiceEnable := true;
        PrepaidEnable := true;
        FirstServiceDateEditable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Responsibility Center" := UserMgt.GetServiceFilter();
    end;

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();

        ActivateFields();
        SetDocNoVisible();
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 must not be blank in %2 %3', Comment = 'Contract No. must not be blank in Service Contract Header SC00004';
#pragma warning restore AA0470
        Text003: Label 'There are unposted invoices associated with this contract.\\Do you want to continue?';
#pragma warning disable AA0470
        Text004: Label 'You cannot create an invoice for %1 %2 because %3 is %4.', Comment = 'You cannot create an invoice for Service Contract Header Contract No. because Invoice Period is Month.';
#pragma warning restore AA0470
        Text005: Label 'The next invoice date has not expired.';
        Text006: Label 'An invoice was created successfully.';
        Text007: Label 'Do you want to create an invoice for the contract?';
        Text008: Label 'The invoice was created successfully.';
        Text009: Label 'There are unposted credit memos associated with this contract.\\Do you want to continue?';
        Text010: Label 'Do you want to create a credit note for the contract?';
        Text011: Label 'Processing...        \\';
#pragma warning disable AA0470
        Text012: Label 'Contract lines have been credited.\\Credit memo %1 was created.';
#pragma warning restore AA0470
        Text013: Label 'A credit memo cannot be created. There must be at least one invoiced and expired service contract line which has not yet been credited.';
        Text014: Label 'Do you want to file the contract?';
#pragma warning restore AA0074
        ServContractLine: Record "Service Contract Line";
        ServContractLine1: Record "Service Contract Line";
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        ChangeCustomerinContract: Report "Change Customer in Contract";
        CopyServDoc: Report "Copy Service Document";
        ServContractMgt: Codeunit ServContractManagement;
        UserMgt: Codeunit "User Setup Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text015: Label '%1 must not be %2 in %3 %4', Comment = 'Status must not be Locked in Service Contract Header SC00005';
        Text016: Label 'A credit memo cannot be created, because the %1 %2 is after the work date.', Comment = 'A credit memo cannot be created, because the Credit Memo Date 03-02-11 is after the work date.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        FormatAddress: Codeunit "Format Address";
        FirstServiceDateEditable: Boolean;
        PrepaidEnable: Boolean;
        InvoiceAfterServiceEnable: Boolean;
        IsShipToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsBillToCountyVisible: Boolean;
        DocNoVisible: Boolean;

    local procedure CollectShpmntsByLineContractNo(var TempServShptHeader: Record "Service Shipment Header" temporary)
    var
        ServShptHeader: Record "Service Shipment Header";
        ServShptLine: Record "Service Shipment Line";
    begin
        TempServShptHeader.Reset();
        TempServShptHeader.DeleteAll();
        ServShptLine.Reset();
        ServShptLine.SetCurrentKey("Contract No.");
        ServShptLine.SetRange("Contract No.", Rec."Contract No.");
        if ServShptLine.Find('-') then
            repeat
                if ServShptHeader.Get(ServShptLine."Document No.") then begin
                    TempServShptHeader.Copy(ServShptHeader);
                    if TempServShptHeader.Insert() then;
                end;
            until ServShptLine.Next() = 0;
    end;

    local procedure ActivateFields()
    begin
        FirstServiceDateEditable := Rec.Status <> Rec.Status::Signed;
        PrepaidEnable := (not Rec."Invoice after Service" or Rec.Prepaid);
        InvoiceAfterServiceEnable := (not Rec.Prepaid or Rec."Invoice after Service");
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
    end;

    local procedure SetDocNoVisible()
    var
        ServDocumentNoVisibility: Codeunit "Serv. Document No. Visibility";
        DocType: Option Quote,"Order",Invoice,"Credit Memo",Contract;
    begin
        DocNoVisible := ServDocumentNoVisibility.ServiceDocumentNoIsVisible(DocType::Contract, Rec."Contract No.");
    end;

    procedure CheckRequiredFields()
    begin
        if Rec."Contract No." = '' then
            Error(Text000, Rec.FieldCaption("Contract No."), Rec.TableCaption(), Rec."Contract No.");
        if Rec."Customer No." = '' then
            Error(Text000, Rec.FieldCaption("Customer No."), Rec.TableCaption(), Rec."Contract No.");
        if Format(Rec."Service Period") = '' then
            Error(Text000, Rec.FieldCaption("Service Period"), Rec.TableCaption(), Rec."Contract No.");
        if Rec."First Service Date" = 0D then
            Error(Text000, Rec.FieldCaption("First Service Date"), Rec.TableCaption(), Rec."Contract No.");
        if Rec.Status = Rec.Status::Cancelled then
            Error(Text015, Rec.FieldCaption(Rec.Status), Format(Rec.Status), Rec.TableCaption(), Rec."Contract No.");
        if Rec."Change Status" = Rec."Change Status"::Locked then
            Error(Text015, Rec.FieldCaption("Change Status"), Format(Rec."Change Status"), Rec.TableCaption(), Rec."Contract No.");
    end;

    local procedure GetServItemLine()
    var
        ContractLineSelection: Page "Contract Line Selection";
    begin
        Clear(ContractLineSelection);
        ContractLineSelection.SetSelection(Rec."Customer No.", Rec."Ship-to Code", Rec."Contract Type".AsInteger(), Rec."Contract No.");
        ContractLineSelection.RunModal();
        CurrPage.Update(false);
    end;

    local procedure StartingDateOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure StatusOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure CustomerNoOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure BilltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update();
    end;

    local procedure ShiptoCodeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure ResponseTimeHoursOnAfterValida()
    begin
        CurrPage.Update(true);
    end;

    local procedure ServicePeriodOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure AnnualAmountOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure InvoiceafterServiceOnAfterVali()
    begin
        ActivateFields();
    end;

    local procedure AllowUnbalancedAmountsOnAfterV()
    begin
        CurrPage.Update();
    end;

    local procedure PrepaidOnAfterValidate()
    begin
        ActivateFields();
    end;

    local procedure ExpirationDateOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure FirstServiceDateOnAfterValidat()
    begin
        CurrPage.Update();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateServiceCreditMemoOnBeforeAction(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateServiceCreditMemoOnAfterInitCodeunit(var ServiceContractHeader: Record "Service Contract Header"; var ServiceContractLine: Record "Service Contract Line"; var ServContractManagement: Codeunit ServContractManagement)
    begin
    end;
}

