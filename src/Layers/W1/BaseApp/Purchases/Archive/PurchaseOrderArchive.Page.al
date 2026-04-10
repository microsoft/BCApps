// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

using Microsoft.CRM.Contact;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Vendor;
using System.Environment;
using System.Security.User;

page 5167 "Purchase Order Archive"
{
    Caption = 'Purchase Order Archive';
    DeleteAllowed = false;
    Editable = false;
    PageType = Document;
    SourceTable = "Purchase Header Archive";
    SourceTableView = where("Document Type" = const(Order));

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
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Suite;
                }
                field("Buy-from Contact No."; Rec."Buy-from Contact No.")
                {
                    ApplicationArea = Suite;
                }
                group("Buy-from")
                {
                    Caption = 'Buy-from';
                    field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name';
                    }
                    field("Buy-from Vendor Name 2"; Rec."Buy-from Vendor Name 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name 2';
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Buy-from Address"; Rec."Buy-from Address")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address';
                    }
                    field("Buy-from Address 2"; Rec."Buy-from Address 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address 2';
                    }
                    field("Buy-from City"; Rec."Buy-from City")
                    {
                        ApplicationArea = Suite;
                        Caption = 'City';
                    }
                    group(Control23)
                    {
                        ShowCaption = false;
                        Visible = IsBuyFromCountyVisible;
                        field("Buy-from County"; Rec."Buy-from County")
                        {
                            ApplicationArea = Suite;
                            CaptionClass = '5,1,' + Rec."Buy-from Country/Region Code";
                        }
                    }
                    field("Buy-from Post Code"; Rec."Buy-from Post Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Post Code';
                    }
                    field("Buy-from Country/Region Code"; Rec."Buy-from Country/Region Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country or region of your vendor.';
                    }
                    field("Buy-from Contact"; Rec."Buy-from Contact")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Contact';
                    }
                    field(BuyFromContactPhoneNo; BuyFromContact."Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the vendor contact person.';
                    }
                    field(BuyFromContactMobilePhoneNo; BuyFromContact."Mobile Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the vendor contact person.';
                    }
                    field(BuyFromContactEmail; BuyFromContact."E-Mail")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Email';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the vendor contact person.';
                    }
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                }
                field("VAT Reporting Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                    Editable = false;
                    Visible = VATDateEnabled;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date the order was created. The order date is also used to determine the prices and discounts on the document.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Suite;
                }
                field("Vendor Order No."; Rec."Vendor Order No.")
                {
                    ApplicationArea = Suite;
                }
                field("Vendor Shipment No."; Rec."Vendor Shipment No.")
                {
                    ApplicationArea = Suite;
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = Suite;
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = Suite;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Suite;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                }
            }
            part(PurchLinesArchive; "Purchase Order Archive Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Document No." = field("No."),
                              "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                              "Version No." = field("Version No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = Suite;
                }
                field("Pay-to Contact No."; Rec."Pay-to Contact No.")
                {
                    ApplicationArea = Suite;
                }
                group("Pay-to")
                {
                    Caption = 'Pay-to';
                    field("Pay-to Name"; Rec."Pay-to Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name';
                    }
                    field("Pay-to Name 2"; Rec."Pay-to Name 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name 2';
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Pay-to Address"; Rec."Pay-to Address")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address';
                    }
                    field("Pay-to Address 2"; Rec."Pay-to Address 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address 2';
                    }
                    field("Pay-to City"; Rec."Pay-to City")
                    {
                        ApplicationArea = Suite;
                        Caption = 'City';
                    }
                    group(Control27)
                    {
                        ShowCaption = false;
                        Visible = IsPayToCountyVisible;
                        field("Pay-to County"; Rec."Pay-to County")
                        {
                            ApplicationArea = Suite;
                            CaptionClass = '5,1,' + Rec."Pay-to Country/Region Code";
                        }
                    }
                    field("Pay-to Post Code"; Rec."Pay-to Post Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Post Code';
                    }
                    field("Pay-to Country/Region Code"; Rec."Pay-to Country/Region Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country or region of the vendor on the purchase document.';
                    }
                    field("Pay-to Contact"; Rec."Pay-to Contact")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Contact';
                    }
                    field(PayToContactPhoneNo; PayToContact."Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the person to contact about an order from this vendor.';
                    }
                    field(PayToContactMobilePhoneNo; PayToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the person to contact about an order from this vendor.';
                    }
                    field(PayToContactEmail; PayToContact."E-Mail")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = Email;
                        ToolTip = 'Specifies the email address of the person to contact about an order from this vendor.';
                    }
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
                    ApplicationArea = Suite;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Suite;
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Suite;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Suite;
                }
                field("On Hold"; Rec."On Hold")
                {
                    ApplicationArea = Suite;
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = VAT;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name';
                    }
                    field("Ship-to Name 2"; Rec."Ship-to Name 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name 2';
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address';
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address 2';
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = Suite;
                        Caption = 'City';
                    }
                    group(Control31)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = Suite;
                            CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Post Code';
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Country/Region';
                        ToolTip = 'Specifies the country or region of the ship-to address.';
                    }
                    field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Phone No.';
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Contact';
                    }
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Inbound Whse. Handling Time"; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Suite;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Suite;
                }
                field("Requested Receipt Date"; Rec."Requested Receipt Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date you want the vendor to deliver your order. ';
                }
                field("Promised Receipt Date"; Rec."Promised Receipt Date")
                {
                    ApplicationArea = OrderPromising;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Suite;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Suite;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Suite;
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Entry Point"; Rec."Entry Point")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
            }
            group(Version)
            {
                Caption = 'Version';
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = Suite;
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = Suite;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Archived By");
                    end;
                }
                field("Date Archived"; Rec."Date Archived")
                {
                    ApplicationArea = Suite;
                }
                field("Time Archived"; Rec."Time Archived")
                {
                    ApplicationArea = Suite;
                }
                field("Interaction Exist"; Rec."Interaction Exist")
                {
                    ApplicationArea = RelationshipMgmt;
                }
            }
        }
        area(factboxes)
        {
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Suite;
                ShowFilter = false;
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                group(IncomingDocument)
                {
                    Caption = 'Incoming Document';
                    Image = Documents;

                    action(IncomingDocCard)
                    {
                        ApplicationArea = Suite;
                        Caption = 'View Incoming Document';
                        Enabled = HasIncomingDocument;
                        Image = ViewOrder;
                        ToolTip = 'View any incoming document records and file attachments that exist for the entry or document, for example for auditing purposes';

                        trigger OnAction()
                        var
                            IncomingDocument: Record "Incoming Document";
                        begin
                            IncomingDocument.ShowCardFromEntryNo(Rec."Incoming Document Entry No.");
                        end;
                    }
                }
            }
        }
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
                    RunObject = Page "Vendor Card";
                    RunPageLink = "No." = field("Buy-from Vendor No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
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
                    RunObject = Page "Purch. Archive Comment Sheet";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "No." = field("No."),
                                  "Document Line No." = const(0),
                                  "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                  "Version No." = field("Version No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Print)
                {
                    ApplicationArea = Suite;
                    Caption = 'Print';
                    Image = Print;
                    ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        DocPrint.PrintPurchHeaderArch(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Print_Promoted; Print)
                {
                }
            }
            group(Category_Order)
            {
                Caption = 'Order';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(IncomingDocCard_Promoted; IncomingDocCard)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        IsBuyFromCountyVisible := FormatAddress.UseCounty(Rec."Buy-from Country/Region Code");
        IsPayToCountyVisible := FormatAddress.UseCounty(Rec."Pay-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        SetControlAppearance();
        if not (ClientTypeManagement.GetCurrentClientType() in [ClientType::SOAP, ClientType::OData, ClientType::ODataV4]) then
            CurrPage.IncomingDocAttachFactBox.Page.LoadDataFromRecord(Rec);
    end;

    trigger OnAfterGetRecord()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if not (ClientTypeManagement.GetCurrentClientType() in [ClientType::SOAP, ClientType::OData, ClientType::ODataV4]) then begin
            BuyFromContact.GetOrClear(Rec."Buy-from Contact No.");
            PayToContact.GetOrClear(Rec."Pay-to Contact No.");
            CurrPage.IncomingDocAttachFactBox.Page.SetCurrentRecordID(Rec.RecordId);
        end;
    end;

    var
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        DocPrint: Codeunit "Document-Print";
        FormatAddress: Codeunit "Format Address";
        IsBuyFromCountyVisible: Boolean;
        IsPayToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        VATDateEnabled: Boolean;
        HasIncomingDocument: Boolean;

    local procedure SetControlAppearance()
    begin
        HasIncomingDocument := Rec."Incoming Document Entry No." <> 0;
    end;
}

