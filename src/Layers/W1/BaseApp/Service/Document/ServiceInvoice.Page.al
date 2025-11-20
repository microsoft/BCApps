// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Service.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.EServices.EDocument;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.History;
using Microsoft.Service.Posting;
using Microsoft.Utilities;
using System.Security.User;

page 5933 "Service Invoice"
{
    Caption = 'Service Invoice';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Service Header";
    SourceTableView = where("Document Type" = filter(Invoice));

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
                    Visible = DocNoVisible;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
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
                group("Sell-to")
                {
                    Caption = 'Sell-to';
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
                        QuickEntry = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    group(Control13)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Service;
                            QuickEntry = false;
                            ToolTip = 'Specifies the county in the customer''s address.';
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Service;
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
                        ToolTip = 'Specifies the name of the contact who will receive the service.';
                    }
                    field(SellToPhoneNo; SellToContact."Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the contact person who will receive the service.';
                    }
                    field(SellToMobilePhoneNo; SellToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact person who will receive the service.';
                    }
                    field(SellToEmail; SellToContact."E-Mail")
                    {
                        ApplicationArea = Service;
                        Caption = 'Email';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact person who will receive the service.';
                    }
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
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the salesperson assigned to this service document.';

                    trigger OnValidate()
                    begin
                        SalespersonCodeOnAfterValidate();
                    end;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';

                    trigger OnValidate()
                    begin
                        ResponsibilityCenterOnAfterVal();
                    end;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
            }
            part(ServLines; "Service Invoice Subform")
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
                group("Bill-to")
                {
                    Caption = 'Bill-to';
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
                    group(Control21)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; Rec."Bill-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Bill-to Country/Region Code";
                            QuickEntry = false;
                            ToolTip = 'Specifies the county in the customer''s address.';
                        }
                    }
                    field("Bill-to Post Code"; Rec."Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    }
                    field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        QuickEntry = false;
                        ToolTip = 'Specifies the country/region in the customer''s address.';

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
                        ToolTip = 'Specifies the telephone number of the contact person at the customer''s billing address.';
                    }
                    field(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact person at the customer''s billing address.';
                    }
                    field(BillToContactEmail; BillToContact."E-Mail")
                    {
                        ApplicationArea = Service;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact person at the customer''s billing address.';
                    }
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a customer reference, which will be used when printing service documents.';
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
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsPostingGroupEditable;
                    Importance = Additional;
                    ToolTip = 'Specifies the customer''s market type to link business transactions to.';
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Service;
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the direct-debit mandate that the customer has signed to allow direct debit collection of payments.';
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
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
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
                    group(Control29)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                            QuickEntry = false;
                            ToolTip = 'Specifies the county in the customer''s address.';
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region Code';
                        QuickEntry = false;
                        ToolTip = 'Specifies the country/region in the customer''s address.';

                        trigger OnValidate()
                        begin
                            IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
                        end;
                    }
                    field("Ship-to Phone"; Rec."Ship-to Phone")
                    {
                        ApplicationArea = Service;
                        Caption = 'Phone No.';
                        ToolTip = 'Specifies the telephone number of the company''s shipping address.';
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location (for example, warehouse or distribution center) of the items specified on the service item lines.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
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
                Visible = true;
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
                Visible = false;
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
                Provider = ServLines;
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("No."),
                              "Line No." = field("Line No.");
                Visible = false;
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
            group("&Invoice")
            {
                Caption = '&Invoice';
                Image = Invoice;
#if not CLEAN27
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    ObsoleteReason = 'The statistics action will be replaced with the ServiceStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';

                    trigger OnAction()
                    begin
                        Rec.OpenStatistics();
                    end;
                }
#endif
                action(ServiceStatistics)
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
                    RunObject = Page "Service Statistics";
                    RunPageOnRec = true;
                }
                action(Card)
                {
                    ApplicationArea = Service;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
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
                        CurrPage.SaveRecord();
                    end;
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
                action("Service Document Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Document Lo&g';
                    Image = Log;
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';

                    trigger OnAction()
                    var
                        TempServDocLog: Record "Service Document Log" temporary;
                    begin
                        TempServDocLog.Reset();
                        TempServDocLog.DeleteAll();
                        TempServDocLog.CopyServLog(TempServDocLog."Document Type"::Invoice.AsInteger(), Rec."No.");

                        TempServDocLog.Reset();
                        TempServDocLog.SetCurrentKey("Change Date", "Change Time");
                        TempServDocLog.Ascending(false);

                        PAGE.Run(0, TempServDocLog);
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
                action("Calculate Invoice Discount")
                {
                    ApplicationArea = Service;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount that applies to the service order.';

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc();
                    end;
                }
                action("Get St&d. Service Codes")
                {
                    ApplicationArea = Service;
                    Caption = 'Get St&d. Service Codes';
                    Ellipsis = true;
                    Image = ServiceCode;
                    ToolTip = 'Insert service order lines that you have set up for recurring services. ';

                    trigger OnAction()
                    var
                        StdServCode: Record "Standard Service Code";
                    begin
                        StdServCode.InsertServiceLines(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
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
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    var
                        InstructionMgt: Codeunit "Instruction Mgt.";
                        PreAssignedNo: Code[20];
                        xLastPostingNo: Code[20];
                    begin
                        PreAssignedNo := Rec."No.";
                        xLastPostingNo := Rec."Last Posting No.";

                        DocumentIsPosted := Rec.SendToPost(Codeunit::"Service-Post (Yes/No)");

                        if InstructionMgt.IsEnabled(InstructionMgt.ShowPostedConfirmationMessageCode()) then
                            ShowPostedConfirmationMessage(PreAssignedNo, xLastPostingNo);
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
                        ServPostYesNo.PreviewDocument(Rec);
                    end;
                }
                action(PostAndSend)
                {
                    ApplicationArea = Service;
                    Caption = 'Post and &Send';
                    Ellipsis = true;
                    Image = PostSendTo;
                    ToolTip = 'Finalize and prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                    trigger OnAction()
                    begin
                        DocumentIsPosted := Rec.SendToPost(Codeunit::"Service-Post and Send");
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Service;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        DocumentIsPosted := Rec.SendToPost(Codeunit::"Service-Post+Print");
                    end;
                }
                action("Post &Batch")
                {
                    ApplicationArea = Service;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Service Invoices", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Category4)
                {
                    Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 3.';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(PostAndSend_Promoted; PostAndSend)
                    {
                    }
                    actionref(Preview_Promoted; Preview)
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                    actionref("Post &Batch_Promoted"; "Post &Batch")
                    {
                    }
                }
            }
            group(Category_Prepare)
            {
                Caption = 'Prepare';

                actionref("Get St&d. Service Codes_Promoted"; "Get St&d. Service Codes")
                {
                }
                actionref("Calculate Invoice Discount_Promoted"; "Calculate Invoice Discount")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Invoice', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("&Dimensions_Promoted"; "&Dimensions")
                {
                }
#if not CLEAN27
                actionref(Statistics_Promoted; Statistics)
                {
                    ObsoleteReason = 'The statistics action will be replaced with the ServiceStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#else
                actionref(ServiceStatistics_Promoted; ServiceStatistics)
                {
                }
#endif
                actionref("Service Document Lo&g_Promoted"; "Service Document Lo&g")
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
        ServLogManagement: Codeunit ServLogManagement;
    begin
        CurrPage.SaveRecord();
        Clear(ServLogManagement);
        ServLogManagement.ServHeaderManualDelete(Rec);
        exit(Rec.ConfirmDeletion());
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Rec.Find(Which) then
            exit(true);

        Rec.SetRange("No.");
        exit(Rec.Find(Which));
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        UserSetupManagement: Codeunit "User Setup Management";
    begin
        Rec."Responsibility Center" := UserSetupManagement.GetServiceFilter();
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
        SellToContact.GetOrClear(Rec."Contact No.");
        BillToContact.GetOrClear(Rec."Bill-to Contact No.");
        CurrPage.IncomingDocAttachFactBox.Page.SetCurrentRecordID(Rec.RecordId);

        OnAfterOnAfterGetRecord(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not DocumentIsPosted then
            exit(Rec.ConfirmCloseUnposted());
    end;

    var
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        ServiceMgtSetup: Record "Service Mgt. Setup";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        DocumentIsPosted: Boolean;
        OpenPostedServiceInvQst: Label 'The invoice is posted as number %1 and moved to the Posted Service Invoices window.\\Do you want to open the posted invoice?', Comment = '%1 = posted document number';
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        ServiceDocCheckFactboxVisible: Boolean;
        IsServiceLinesEditable: Boolean;
        ExternalDocNoMandatory: Boolean;
        VATDateEnabled: Boolean;
        DocNoVisible: Boolean;

    protected var
        IsPostingGroupEditable: Boolean;

    local procedure ActivateFields()
    begin
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        ServiceDocCheckFactboxVisible := DocumentErrorsMgt.BackgroundValidationEnabled();
        IsServiceLinesEditable := Rec.ServiceLinesEditable();
        SetExtDocNoMandatoryCondition();
    end;

    local procedure SetDocNoVisible()
    var
        ServDocumentNoVisibility: Codeunit "Serv. Document No. Visibility";
        DocType: Option Quote,"Order",Invoice,"Credit Memo",Contract;
    begin
        DocNoVisible := ServDocumentNoVisibility.ServiceDocumentNoIsVisible(DocType::Invoice, Rec."No.");
    end;

    local procedure SetControlAppearance()
    begin
        IsServiceLinesEditable := Rec.ServiceLinesEditable();
        SetPostingGroupEditable();
    end;

    procedure RunBackgroundCheck()
    begin
        CurrPage.ServiceDocCheckFactbox.Page.CheckErrorsInBackground(Rec);
    end;

    local procedure CheckShowBackgrValidationNotification()
    begin
        if DocumentErrorsMgt.CheckShowEnableBackgrValidationNotification() then
            ActivateFields();
    end;

    local procedure SetExtDocNoMandatoryCondition()
    begin
        ServiceMgtSetup.GetRecordOnce();
        ExternalDocNoMandatory := ServiceMgtSetup."Ext. Doc. No. Mandatory";
    end;

    procedure SetPostingGroupEditable()
    var
        BillToCustomer: Record Customer;
    begin
        if BillToCustomer.Get(Rec."Bill-to Customer No.") then
            IsPostingGroupEditable := BillToCustomer."Allow Multiple Posting Groups";
    end;

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.ServLines.PAGE.ApproveCalcInvDisc();
    end;

    local procedure CustomerNoOnAfterValidate()
    begin
        if Rec.GetFilter("Customer No.") = xRec."Customer No." then
            if Rec."Customer No." <> xRec."Customer No." then
                Rec.SetRange("Customer No.");
        IsServiceLinesEditable := Rec.ServiceLinesEditable();
        CurrPage.Update();
    end;

    local procedure SalespersonCodeOnAfterValidate()
    begin
        CurrPage.ServLines.PAGE.UpdateForm(true);
    end;

    local procedure ResponsibilityCenterOnAfterVal()
    begin
        CurrPage.ServLines.PAGE.UpdateForm(true);
    end;

    local procedure BilltoCustomerNoOnAfterValidat()
    begin
        CurrPage.Update();
    end;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.Update();
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.Update();
    end;

    local procedure PricesIncludingVATOnAfterValid()
    begin
        CurrPage.Update();
    end;

    local procedure ShiptoCodeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure ShowPostedConfirmationMessage(PreAssignedNo: Code[20]; xLastPostingNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        if (Rec."Last Posting No." <> '') and (Rec."Last Posting No." <> xLastPostingNo) then
            ServiceInvoiceHeader.SetRange("No.", Rec."Last Posting No.")
        else begin
            ServiceInvoiceHeader.SetCurrentKey("Pre-Assigned No.");
            ServiceInvoiceHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        end;
        if ServiceInvoiceHeader.FindFirst() then
            if InstructionMgt.ShowConfirm(StrSubstNo(OpenPostedServiceInvQst, ServiceInvoiceHeader."No."),
                 InstructionMgt.ShowPostedConfirmationMessageCode())
            then
                InstructionMgt.ShowPostedDocument(ServiceInvoiceHeader, Page::"Service Invoice");
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnAfterGetRecord(var ServiceHeader: Record "Service Header")
    begin
    end;
}
