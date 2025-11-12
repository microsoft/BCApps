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
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.Reports;
using Microsoft.Utilities;
using System.Security.User;
using System.Utilities;

page 6053 "Service Contract Quote"
{
    Caption = 'Service Contract Quote';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Service Contract Header";
    SourceTableView = where("Contract Type" = filter(Quote));

    layout
    {
        area(content)
        {
            group(General)
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
                group("Sell-to")
                {
                    Caption = 'Sell-to';
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
                    group(Control13)
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
                        ToolTip = 'Specifies the name of the person you regularly contact when you do business with the customer in this service contract.';
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the customer phone number.';
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
                field("Quote Type"; Rec."Quote Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service contract quote.';
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
                    Editable = true;
                    Importance = Promoted;
#pragma warning disable AL0600
                    OptionCaption = ' ,,Canceled';
#pragma warning restore AL0600
                    ToolTip = 'Specifies the status of the service contract or contract quote.';

                    trigger OnValidate()
                    begin
                        StatusOnAfterValidate();
                    end;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("Change Status"; Rec."Change Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if a service contract or contract quote is locked or open for changes.';
                }
            }
            part(ServContractLines; "Service Contract Quote Subform")
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
                group(Control14)
                {
                    ShowCaption = false;
                    field("Bill-to Name"; Rec."Bill-to Name")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    }
                    field("Bill-to Address"; Rec."Bill-to Address")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address of the customer to whom you will send the invoice.';
                    }
                    field("Bill-to Address 2"; Rec."Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    field("Bill-to City"; Rec."Bill-to City")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control23)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; Rec."Bill-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Bill-to Country/Region Code";
                            QuickEntry = false;
                            ToolTip = 'Specifies the county code of the customer''s billing address.';
                        }
                    }
                    field("Bill-to Post Code"; Rec."Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the country/region code of the customer''s billing address.';

                        trigger OnValidate()
                        begin
                            IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
                        end;
                    }
                    field("Bill-to Contact"; Rec."Bill-to Contact")
                    {
                        ApplicationArea = Service;
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
                group(Control25)
                {
                    ShowCaption = false;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                }
                field("Ship-to Name 2"; Rec."Ship-to Name 2")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name of the customer that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Address"; Rec."Ship-to Address")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the address that the items are shipped to.';
                }
                field("Ship-to Address 2"; Rec."Ship-to Address 2")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the city of the address that the items are shipped to.';
                }
                group(Control33)
                {
                    ShowCaption = false;
                    Visible = IsShipToCountyVisible;
                    field("Ship-to County"; Rec."Ship-to County")
                    {
                        ApplicationArea = Service;
                        CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                        ToolTip = 'Specifies the county of the address.';
                    }
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region code of the address.';
                }
                field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the telephone number of the company''s shipping address.';
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
                    Importance = Promoted;
                    ToolTip = 'Specifies a default service period for the items in the contract.';

                    trigger OnValidate()
                    begin
                        ServicePeriodOnAfterValidate();
                    end;
                }
                field("First Service Date"; Rec."First Service Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date of the first expected service for the service items in the contract.';
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
                field("Invoice Period"; Rec."Invoice Period")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the invoice period for the service contract.';
                }
                field("Next Invoice Date"; Rec."Next Invoice Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date of the next invoice for this service contract.';
                }
                field("Amount per Period"; Rec."Amount per Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount that will be invoiced for each invoice period for the service contract.';
                }
                field(NextInvoicePeriod; Rec.NextInvoicePeriod())
                {
                    ApplicationArea = Service;
                    Caption = 'Next Invoice Period';
                    ToolTip = 'Specifies the next invoice period for the filed service contract quote: the first date of the period and the ending date.';
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
                    ToolTip = 'Specifies the date when the service contract expires.';

                    trigger OnValidate()
                    begin
                        ExpirationDateOnAfterValidate();
                    end;
                }
                field("Max. Labor Unit Price"; Rec."Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the maximum unit price that can be set for a resource on all service orders and lines for the service contract.';
                }
                field("Accept Before"; Rec."Accept Before")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date before which the customer must accept this contract quote.';
                }
                field(Probability; Rec.Probability)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the probability of the customer approving the service contract quote.';
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
                              "Document Type" = const("Service Contract Quote"),
                              "No." = field("Contract No.");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Service Contract Header"),
                              "Document Type" = const("Service Contract Quote"),
                              "No." = field("Contract No.");
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
                                  "Service Contract Type" = filter(Quote);
                    ToolTip = 'View the service hours that are valid for the service contract. This window displays the starting and ending service hours for the contract for each weekday.';
                }
                action("&Filed Contract Quotes")
                {
                    ApplicationArea = Service;
                    Caption = '&Filed Contract Quotes';
                    Image = Quote;
                    RunObject = Page "Filed Service Contract List";
                    RunPageLink = "Contract Type Relation" = field("Contract Type"),
                                  "Contract No. Relation" = field("Contract No.");
                    RunPageView = sorting("Contract Type Relation", "Contract No. Relation", "File Date", "File Time")
                                  order(descending);
                    ToolTip = 'View filed contract quotes.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Select Contract Quote Lines")
                {
                    ApplicationArea = Service;
                    Caption = '&Select Contract Quote Lines';
                    Image = CalculateLines;
                    ToolTip = 'Open the list of all the service items that are registered to the customer and select which to include in the contract quote. ';

                    trigger OnAction()
                    begin
                        CheckRequiredFields();
                        GetServItemLine();
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
                action("&File Contract Quote")
                {
                    ApplicationArea = Service;
                    Caption = '&File Contract Quote';
                    Image = FileContract;
                    ToolTip = 'Record and archive a copy of the contract quote. Service contract quotes are automatically filed when you convert contract quotes to service contracts or cancel service contracts.';

                    trigger OnAction()
                    var
                        FiledServiceContractHeader: Record "Filed Service Contract Header";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if ConfirmManagement.GetResponseOrDefault(Text001, true) then
                            FiledServiceContractHeader.FileContract(Rec);
                    end;
                }
                action("Update &Discount % on All Lines")
                {
                    ApplicationArea = Service;
                    Caption = 'Update &Discount % on All Lines';
                    Image = Refresh;
                    ToolTip = 'Update the quote discount on all the service items in a service contract quote. You need to specify the number that you want to add to or subtract from the quote discount percentage that you have specified in the Contract/Service Discount table. The batch job then updates the quote amounts accordingly.';

                    trigger OnAction()
                    begin
                        ServContractLine.Reset();
                        ServContractLine.SetRange("Contract Type", Rec."Contract Type");
                        ServContractLine.SetRange("Contract No.", Rec."Contract No.");
                        REPORT.RunModal(REPORT::"Upd. Disc.% on Contract", true, true, ServContractLine);
                    end;
                }
                action("Update with Contract &Template")
                {
                    ApplicationArea = Service;
                    Caption = 'Update with Contract &Template';
                    Image = Refresh;
                    ToolTip = 'Implement template information on the contract.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if not ConfirmManagement.GetResponseOrDefault(Text002, true) then
                            exit;
                        CurrPage.Update(true);
                        Clear(ServContrQuoteTmplUpd);
                        ServContrQuoteTmplUpd.Run(Rec);
                        CurrPage.Update(true);
                    end;
                }
                action("Loc&k")
                {
                    ApplicationArea = Service;
                    Caption = 'Loc&k';
                    Image = Lock;
                    ToolTip = 'Make sure that the contract cannot be changed.';

                    trigger OnAction()
                    begin
                        LockOpenServContract.LockServContract(Rec);
                        CurrPage.Update();
                    end;
                }
                action("&Open")
                {
                    ApplicationArea = Service;
                    Caption = '&Open';
                    Image = Edit;
                    ShortCutKey = 'Return';
                    ToolTip = 'Open the service contract quote.';

                    trigger OnAction()
                    begin
                        LockOpenServContract.OpenServContract(Rec);
                        CurrPage.Update();
                    end;
                }
            }
            action("&Make Contract")
            {
                ApplicationArea = Service;
                Caption = '&Make Contract';
                Image = MakeAgreement;
                ToolTip = 'Prepare to create a service contract.';

                trigger OnAction()
                var
                    SignServContractDoc: Codeunit SignServContractDoc;
                begin
                    CurrPage.Update(true);
                    SignServContractDoc.SignContractQuote(Rec);
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
        area(reporting)
        {
            action("Service Quote Details")
            {
                ApplicationArea = Service;
                Caption = 'Service Quote Details';
                Image = "Report";
                RunObject = Report "Service Contract Quote-Detail";
                ToolTip = 'View details information for the quote.';
            }
            action("Contract Quotes to be Signed")
            {
                ApplicationArea = Service;
                Caption = 'Contract Quotes to be Signed';
                Image = "Report";
                RunObject = Report "Contract Quotes to Be Signed";
                ToolTip = 'View the contract number, customer name and address, salesperson code, starting date, probability, quoted amount, and forecast. You can print all your information about contract quotes to be signed.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Make Contract_Promoted"; "&Make Contract")
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
                group(Category_Lock)
                {
                    Caption = 'Lock';
                    ShowAs = SplitButton;

                    actionref("Loc&k_Promoted"; "Loc&k")
                    {
                    }
                    actionref("&Open_Promoted"; "&Open")
                    {
                    }
                }
                actionref("Copy &Document..._Promoted"; "Copy &Document...")
                {
                }
                actionref("&File Contract Quote_Promoted"; "&File Contract Quote")
                {
                }
            }
            group(Category_Quote)
            {
                Caption = 'Quote';

                actionref(Dimensions_Promoted; Dimensions)
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
                Caption = 'Reports';

                actionref("Service Quote Details_Promoted"; "Service Quote Details")
                {
                }
                actionref("Contract Quotes to be Signed_Promoted"; "Contract Quotes to be Signed")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Calcd. Annual Amount");
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
        Text001: Label 'Do you want to file the contract quote?';
        Text002: Label 'Do you want to update the contract quote using a contract template?';
#pragma warning restore AA0074
        ServContractLine: Record "Service Contract Line";
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        CopyServDoc: Report "Copy Service Document";
        UserMgt: Codeunit "User Setup Management";
        ServContrQuoteTmplUpd: Codeunit "ServContractQuote-Tmpl. Upd.";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 must not be %2 in %3 %4', Comment = 'Status must not be blank in Signed SC00001';
#pragma warning restore AA0470
#pragma warning restore AA0074
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        FormatAddress: Codeunit "Format Address";
        PrepaidEnable: Boolean;
        InvoiceAfterServiceEnable: Boolean;
        IsShipToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsBillToCountyVisible: Boolean;
        DocNoVisible: Boolean;

    local procedure ActivateFields()
    begin
        PrepaidEnable := (not Rec."Invoice after Service" or Rec.Prepaid);
        InvoiceAfterServiceEnable := (not Rec.Prepaid or Rec."Invoice after Service");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
    end;

    local procedure SetDocNoVisible()
    var
        ServDocumentNoVisibility: Codeunit "Serv. Document No. Visibility";
        DocType: Option Quote,"Order",Invoice,"Credit Memo",Contract;
    begin
        DocNoVisible := ServDocumentNoVisibility.ServiceDocumentNoIsVisible(DocType::Contract, Rec."Contract No.");
    end;

    local procedure CheckRequiredFields()
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
            Error(Text003, Rec.FieldCaption(Status), Format(Rec.Status), Rec.TableCaption(), Rec."Contract No.");
        if Rec."Change Status" = Rec."Change Status"::Locked then
            Error(Text003, Rec.FieldCaption("Change Status"), Format(Rec."Change Status"), Rec.TableCaption(), Rec."Contract No.");
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

    local procedure StatusOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure CustomerNoOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure StartingDateOnAfterValidate()
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

    local procedure ServicePeriodOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

