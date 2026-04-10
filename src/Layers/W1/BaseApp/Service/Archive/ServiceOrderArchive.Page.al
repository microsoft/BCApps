// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using System.Security.User;

page 6271 "Service Order Archive"
{
    Caption = 'Service Order Archive';
    PageType = Document;
    DeleteAllowed = false;
    Editable = false;
    SourceTable = "Service Header Archive";
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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = Service;
                }
                group(Quote)
                {
                    ShowCaption = false;
                    Visible = ShowQuoteNo;
                    field("Quote No."; Rec."Service Quote No.")
                    {
                        ApplicationArea = Service;
                    }
                }
                group("Sell-To")
                {
                    Caption = 'Sell-To';
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Service;
                    }
                    field("Name 2"; Rec."Name 2")
                    {
                        ApplicationArea = Service;
                        Importance = Additional;
                        Visible = false;
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Service;
                        Importance = Additional;
                        QuickEntry = false;
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                    }
                    group(CountyGroup)
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
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                    }
                    field("Contact Name"; Rec."Contact Name")
                    {
                        ApplicationArea = Service;
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Service;
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
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Service;
                    ExtendedDatatype = EMail;
                }
                field("Notify Customer"; Rec."Notify Customer")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = Service;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                }
                field("Release Status"; Rec."Release Status")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                group("Work Description")
                {
                    Caption = 'Work Description';
                    field(WorkDescription; WorkDescription)
                    {
                        ApplicationArea = Service;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specifies the products or service being offered.';
                    }
                }
            }
            part(ServItemLines; "Service Order Archive Subform")
            {
                ApplicationArea = Service;
                Enabled = IsServiceLinesEditable;
                Editable = IsServiceLinesEditable;
                SubPageLink = "Document No." = field("No."),
                            "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                            "Version No." = field("Version No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = Service;
                }
                group("Bill-To")
                {
                    Caption = 'Bill-To';
                    field("Bill-to Name"; Rec."Bill-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                    }
                    field("Bill-to Name 2"; Rec."Bill-to Name 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name 2';
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Bill-to Address"; Rec."Bill-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        QuickEntry = false;
                    }
                    field("Bill-to Address 2"; Rec."Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Importance = Additional;
                        QuickEntry = false;
                    }
                    field("Bill-to City"; Rec."Bill-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        QuickEntry = false;
                    }
                    group(BillCounty)
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
                    }
                    field("Bill-to Contact"; Rec."Bill-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
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
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Service;
                }
                field("Max. Labor Unit Price"; Rec."Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
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
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Service;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ShowMandatory = ExternalDocNoMandatory;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = Service;
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
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Service;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Service;
                }
                field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
                {
                    ApplicationArea = Service;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;

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
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = VAT;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Service;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                group("Ship-To")
                {
                    Caption = 'Ship-To';
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                    }
                    field("Ship-to Name 2"; Rec."Ship-to Name 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name 2';
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        QuickEntry = false;
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        Importance = Additional;
                        QuickEntry = false;
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        QuickEntry = false;
                    }
                    group(ShipCounty)
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
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        QuickEntry = false;
                        ToolTip = 'Specifies the customer''s country/region.';
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Importance = Promoted;
                    }
                }
                field("Ship-to Phone"; Rec."Ship-to Phone")
                {
                    ApplicationArea = Service;
                    Caption = 'Ship-to Phone';
                }
                field("Ship-to Phone 2"; Rec."Ship-to Phone 2")
                {
                    ApplicationArea = Service;
                    Importance = Additional;
                }
                field("Ship-to E-Mail"; Rec."Ship-to E-Mail")
                {
                    ApplicationArea = Service;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Service;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Service;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Service;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Service;
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Service;
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field("Warning Status"; Rec."Warning Status")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Link Service to Service Item"; Rec."Link Service to Service Item")
                {
                    ApplicationArea = Service;
                }
                field("Allocated Hours"; Rec."Allocated Hours")
                {
                    ApplicationArea = Service;
                }
                field("No. of Allocations"; Rec."No. of Allocations")
                {
                    ApplicationArea = Service;
                }
                field("No. of Unallocated Items"; Rec."No. of Unallocated Items")
                {
                    ApplicationArea = Service;
                }
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Service;

                }
                field("Order Time"; Rec."Order Time")
                {
                    ApplicationArea = Service;
                }
                field("Expected Finishing Date"; Rec."Expected Finishing Date")
                {
                    ApplicationArea = Service;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Service;
                }
                field("Actual Response Time (Hours)"; Rec."Actual Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours from order creation, to when the service order status changes from Pending, to In Process.';
                }
                field("Finishing Date"; Rec."Finishing Date")
                {
                    ApplicationArea = Service;
                }
                field("Finishing Time"; Rec."Finishing Time")
                {
                    ApplicationArea = Service;
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
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU;
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU;
                }
                field("Exit Point"; Rec."Exit Point")
                {
                    ApplicationArea = BasicEU;
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = BasicEU;
                }
            }
            group(Version)
            {
                Caption = 'Version';
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = Service;
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = Service;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Archived By");
                    end;
                }
                field("Date Archived"; Rec."Date Archived")
                {
                    ApplicationArea = Service;
                }
                field("Time Archived"; Rec."Time Archived")
                {
                    ApplicationArea = Service;
                }
                field("Interaction Exist"; Rec."Interaction Exist")
                {
                    ApplicationArea = RelationshipMgmt;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ver&sion")
            {
                Caption = 'Ver&sion';
                Image = Versions;

                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about the record on the document or journal line.';
                }
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
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Archive Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Header"),
                                  "Table Subtype" = field("Document Type"),
                                  "No." = field("No."),
                                  Type = const(General),
                                  "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                  "Version No." = field("Version No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            action(Restore)
            {
                ApplicationArea = Suite;
                Caption = '&Restore';
                Ellipsis = true;
                Image = Restore;
                ToolTip = 'Transfer the contents of this archived version to the original document. This is only possible if the original is not posted or deleted. ';

                trigger OnAction()
                var
                    ServiceArchiveManagement: Codeunit "Service Document Archive Mgmt.";
                begin
                    ServiceArchiveManagement.RestoreServiceDocument(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Restore_Promoted; Restore)
                {
                }
            }
            group(Category_Order)
            {
                Caption = 'Order';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        ActivateFields();
        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    end;

    trigger OnAfterGetRecord()
    begin
        ActivateFields();
        BillToContact.GetOrClear(Rec."Bill-to Contact No.");
        SellToContact.GetOrClear(Rec."Contact No.");
        ActivateFields();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        WorkDescription := Rec.GetWorkDescription();
    end;

    var
        BillToContact: Record Contact;
        SellToContact: Record Contact;
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        WorkDescription: Text;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        IsServiceLinesEditable: Boolean;
        ShowQuoteNo: Boolean;
        ExternalDocNoMandatory: Boolean;
        VATDateEnabled: Boolean;

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        ShowQuoteNo := Rec."Service Quote No." <> '';
    end;
}