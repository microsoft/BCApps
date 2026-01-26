// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.CRM.Contact;
using Microsoft.eServices.EDocument;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Comment;
using Microsoft.Utilities;
using System.Automation;

page 130 "Posted Sales Shipment"
{
    Caption = 'Posted Sales Shipment';
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Sales Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the record.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer No.';
                    Editable = false;
                    Visible = false;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ToolTip = 'Specifies the name of customer at the sell-to address.';
                }
                field("Sell-to Customer Name 2"; Rec."Sell-to Customer Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Name 2';
                    Editable = false;
                    Visible = false;
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field("Sell-to Address"; Rec."Sell-to Address")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the customer''s sell-to address.';
                    }
                    field("Sell-to Address 2"; Rec."Sell-to Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address 2';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the customer''s extended sell-to address.';
                    }
                    field("Sell-to City"; Rec."Sell-to City")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'City';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the city of the customer on the sales document.';
                    }
                    group(Control15)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field("Sell-to County"; Rec."Sell-to County")
                        {
                            ApplicationArea = Basic, Suite;
                            CaptionClass = '5,1,' + Rec."Sell-to Country/Region Code";
                            Editable = false;
                            Importance = Additional;
                            ToolTip = 'Specifies the state, province or county as a part of the address.';
                        }
                    }
                    field("Sell-to Post Code"; Rec."Sell-to Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the post code of the customer''s sell-to address.';
                    }
                    field("Sell-to Country/Region Code"; Rec."Sell-to Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country/Region';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the country/region of the customer on the sales document.';
                    }
                    field("Sell-to Contact No."; Rec."Sell-to Contact No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact No.';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the contact number.';
                    }
                    field(SellToPhoneNo; SellToContact."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the contact person at the customer''s sell-to address.';
                    }
                    field(SellToMobilePhoneNo; SellToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact person at the customer''s sell-to address.';
                    }
                    field(SellToEmail; SellToContact."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact person at the customer''s sell-to address.';
                    }
                }
                field("Sell-to Contact"; Rec."Sell-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact';
                    Editable = false;
                    ToolTip = 'Specifies the name of the contact at the customer''s sell-to address.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the posting date for the entry.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the posting date of the document.';
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date that the customer has asked for the order to be delivered.';
                }
                field("Promised Delivery Date"; Rec."Promised Delivery Date")
                {
                    ApplicationArea = OrderPromising;
                    Editable = false;
                    ToolTip = 'Specifies the date that you have promised to deliver the order, as a result of the Order Promising function.';
                }
                field("Quote No."; Rec."Quote No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the sales quote document if a quote was used to start the sales process.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the sales order that this invoice was posted from.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the number that the customer uses in their own system to refer to this sales document.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies a code for the salesperson who normally handles this customer''s account.';
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for the responsibility center that serves the customer on this sales document.';
                }
                group("Work Description")
                {
                    Caption = 'Work Description';
                    field(GetWorkDescription; Rec.GetWorkDescription())
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specifies the products or services being offered.';
                    }
                }
            }
            part(SalesShipmLines; "Posted Sales Shpt. Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address Code';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the customer''s additional shipment address.';
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that you delivered the items to.';
                }
                field("Ship-to Name 2"; Rec."Ship-to Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the the name of the customer that you delivered the items to.';
                    Visible = false;
                }
                field("Ship-to Address"; Rec."Ship-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address';
                    Editable = false;
                    ToolTip = 'Specifies the address that you delivered the items to.';
                }
                field("Ship-to Address 2"; Rec."Ship-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address 2';
                    Editable = false;
                    ToolTip = 'Specifies the extended address that you delivered the items to.';
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'City';
                    Editable = false;
                    ToolTip = 'Specifies the city of the customer on the sales document.';
                }
                group(Control21)
                {
                    ShowCaption = false;
                    Visible = IsShipToCountyVisible;
                    field("Ship-to County"; Rec."Ship-to County")
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                        Editable = false;
                        ToolTip = 'Specifies the state, province or county as a part of the address.';
                    }
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code';
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the post code of the customer''s ship-to address.';
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Country/Region';
                    Editable = false;
                    ToolTip = 'Specifies the customer''s country/region.';
                }
                field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Phone No.';
                    Editable = false;
                    ToolTip = 'Specifies the telephone number of the company''s shipping address.';
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact';
                    Editable = false;
                    ToolTip = 'Specifies the name of the person you regularly contact at the address that the items were shipped to.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                }
                field("Outbound Whse. Handling Time"; Rec."Outbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies a date formula for the time it takes to get items ready to ship from this location. The time element is used in the calculation of the delivery date as follows: Shipment Date + Outbound Warehouse Handling Time = Planned Shipment Date + Shipping Time = Planned Delivery Date.';
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
                }
                group("Shipment Method")
                {
                    Caption = 'Shipment Method';
                    field("Shipment Method Code"; Rec."Shipment Method Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Code';
                        Editable = false;
                        ToolTip = 'Specifies the shipment method for the shipment.';
                    }
                    field("Shipping Agent Code"; Rec."Shipping Agent Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Agent';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
                    }
                    field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Agent Service';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies which shipping agent service is used to transport the items on the sales document to the customer.';
                    }
                    field("Package Tracking No."; Rec."Package Tracking No.")
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the shipping agent''s package number.';
                    }
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
            }
            group(Billing)
            {
                Caption = 'Billing';
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer No.';
                    Editable = false;
                    Importance = Additional;
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the customer that you sent the invoice to.';
                }
                field("Bill-to Name 2"; Rec."Bill-to Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name 2';
                    Editable = false;
                    Importance = Additional;
                    Visible = false;
                }
                field("Bill-to Address"; Rec."Bill-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the address that you sent the invoice to.';
                }
                field("Bill-to Address 2"; Rec."Bill-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Address 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the extended address that you sent the invoice to.';
                }
                field("Bill-to City"; Rec."Bill-to City")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'City';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the city of the customer on the sales document.';
                }
                group(Control29)
                {
                    ShowCaption = false;
                    Visible = IsBillToCountyVisible;
                    field("Bill-to County"; Rec."Bill-to County")
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = '5,1,' + Rec."Bill-to Country/Region Code";
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the state, province or county as a part of the address.';
                    }
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post Code';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the post code of the customer''s bill-to address.';
                }
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Country/Region Code';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the country or region of the address.';
                }
                field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact No.';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of the contact person at the customer''s bill-to address.';
                }
                field(BillToContactPhoneNo; BillToContact."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Phone No.';
                    Editable = false;
                    Importance = Additional;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the telephone number of the contact person at the customer''s bill-to address.';
                }
                field(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Mobile Phone No.';
                    Editable = false;
                    Importance = Additional;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the mobile telephone number of the contact person at the customer''s bill-to address.';
                }
                field(BillToContactEmail; BillToContact."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Email';
                    Editable = false;
                    Importance = Additional;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the contact at the customer''s bill-to address.';
                }
                field("Bill-to Contact"; Rec."Bill-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact';
                    Editable = false;
                    ToolTip = 'Specifies the name of the person you regularly contact at the customer to whom you sent the invoice.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            group(ElectronicDocument)
            {
                Caption = 'Electronic Document';
                field("CFDI Export Code"; Rec."CFDI Export Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a code to indicate if the document is used for exports to other countries.';
                }
                field("SAT Address ID"; Rec."SAT Address ID")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the SAT address that the goods or merchandise are moved to.';
                    BlankZero = true;
                }
                field("Transport Operators"; Rec."Transport Operators")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the operator of the vehicle that transports the goods or merchandise.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Transit-from Date/Time"; Rec."Transit-from Date/Time")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the estimated date and time at which the goods or merchandise leave the start address.';
                }
                field("Transit Hours"; Rec."Transit Hours")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the estimated time in hours that it will take to transit from the start address to the temporary or final destination.';
                }
                field("Transit Distance"; Rec."Transit Distance")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the distance travelled in kilometers from the start address to the temporary or final destination as a combination of the distances that are travelled by the different means of transport that move the goods or merchandise.';
                }
                field("Vehicle Code"; Rec."Vehicle Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the vehicle that transports the goods or merchandise.';
                }
                field("Trailer 1"; Rec."Trailer 1")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the trailer or semi-trailer that is used with the vehicle for the transfer of goods or merchandise.';
                }
                field("Trailer 2"; Rec."Trailer 2")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the second trailer or semi-trailer that is used with the vehicle for the transfer of goods or merchandise.';
                }
                field("Foreign Trade"; Rec."Foreign Trade")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies whether the goods or merchandise that are transported enter or leave the national territory.';
                }
                field("SAT International Trade Term"; Rec."SAT International Trade Term")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies an international commercial terms code that are used in international sale contracts according to the SAT internatoinal trade terms definition.';
                }
                field("SAT Certificate Name"; SATCertificateName)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'SAT Certificate Name';
                    ToolTip = 'Specifies the name of the certificate that is used to sign the e-document.';
                    Visible = SATCertInLocationEnabled;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        EInvoiceMgt.DrillDownSATCertificate(SATCertificateCode);
                    end;
                }
                field("SAT Certificate Source"; SATCertificateSource)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'SAT Certificate Source';
                    ToolTip = 'Specifies the record with which the certificate is associated, such as General Ledger Setup or a specific Location (e.g., Location BLUE).';
                    Visible = SATCertInLocationEnabled;
                    Editable = false;
                }
                field("Exchange Rate USD"; Rec."Exchange Rate USD")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the USD to MXN exchange rate that is used to report foreign trade transfers to Mexican SAT authorities. This rate must match the rate used by the Mexican National Bank.';
                }
                field("SAT Customs Regime"; Rec."SAT Customs Regime")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the system that regulates the transfer of goods of foreign origin when it enters or exits the country. This information is required by Carte Porte in Mexico.';
                }
                field("SAT Transfer Reason"; Rec."SAT Transfer Reason")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the reason that is associated with the transfer of goods and merchandise in exports. This information is required by Carte Porte in Mexico.';
                }
                field("Insurer Name"; Rec."Insurer Name")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the name of the insurer that covers the risks of the motor transport used for the transfer of goods or merchandise.';
                }
                field("Insurer Policy Number"; Rec."Insurer Policy Number")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the policy number assigned by the insurer, which covers the risks of the motor transport used for the transfer of goods or merchandise.';
                }
                field("Medical Insurer Name"; Rec."Medical Insurer Name")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the insurer that covers potential damage to the environment if the transport includes materials, residues or remnants, or hazardous waste.';
                }
                field("Medical Ins. Policy Number"; Rec."Medical Ins. Policy Number")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the insurance policy number if the transport includes materials, residues or remnants, or hazardous waste.';
                }
                field("SAT Weight Unit Of Measure"; Rec."SAT Weight Unit Of Measure")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the unit of measurement of the weight of the goods and / or merchandise that are moved in this transport.';
                }
                field("Electronic Document Status"; Rec."Electronic Document Status")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Date/Time Stamped"; Rec."Date/Time Stamped")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document received a digital stamp from the authorized service provider.';
                }
                field("Date/Time Canceled"; Rec."Date/Time Canceled")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document was canceled.';
                }
                field("Error Code"; Rec."Error Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the error code that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("Error Description"; Rec."Error Description")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the error message that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("PAC Web Service Name"; Rec."PAC Web Service Name")
                {
                    ApplicationArea = BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the authorized service provider, PAC, which has processed the electronic document.';
                }
                field("Fiscal Invoice Number PAC"; Rec."Fiscal Invoice Number PAC")
                {
                    ApplicationArea = BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the official invoice number for the electronic document.';
                }
                field("Identifier IdCCP"; Rec."Identifier IdCCP")
                {
                    ApplicationArea = BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the complement identifier (IdCCP) required for Carta Porte in Mexico. The IdCCP identifier is based on the guidelines defined in the RFC 4122 standard.';
                }
                field("CFDI Cancellation Reason Code"; Rec."CFDI Cancellation Reason Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the reason for the cancellation as a code.';
                }
                field("Substitution Document No."; Rec."Substitution Document No.")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the document number that replaces the canceled one. It is required when the cancellation reason is 01.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Sales Shipment Header"),
                              "No." = field("No.");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Shipment")
            {
                Caption = '&Shipment';
                Image = Shipment;
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Sales Shipment Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = const(Shipment),
                                  "No." = field("No."),
                                  "Document Line No." = const(0);
                    ToolTip = 'View or add comments for the record.';
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
                    end;
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Posted Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ShowPostedApprovalEntries(Rec.RecordId);
                    end;
                }
                action(CertificateOfSupplyDetails)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Certificate of Supply Details';
                    Image = Certificate;
                    RunObject = Page "Certificates of Supply";
                    RunPageLink = "Document Type" = filter("Sales Shipment"),
                                  "Document No." = field("No.");
                    ToolTip = 'View the certificate of supply that you must send to your customer for signature as confirmation of receipt. You must print a certificate of supply if the shipment uses a combination of VAT business posting group and VAT product posting group that have been marked to require a certificate of supply in the VAT Posting Setup window.';
                }
                action(PrintCertificateofSupply)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Certificate of Supply';
                    Image = PrintReport;
                    ToolTip = 'Print the certificate of supply that you must send to your customer for signature as confirmation of receipt.';

                    trigger OnAction()
                    var
                        CertificateOfSupply: Record "Certificate of Supply";
                    begin
                        CertificateOfSupply.SetRange("Document Type", CertificateOfSupply."Document Type"::"Sales Shipment");
                        CertificateOfSupply.SetRange("Document No.", Rec."No.");
                        CertificateOfSupply.Print();
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
                action("&Track Package")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Track Package';
                    Image = ItemTracking;
                    ToolTip = 'Open the shipping agent''s tracking page to track the package. ';

                    trigger OnAction()
                    begin
                        Rec.StartTrackingSite();
                    end;
                }
            }
            group("Electronic Document")
            {
                Caption = '&Electronic Document';
                action("S&end")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic invoice attached as an XML file.';

                    trigger OnAction()
                    begin
                        Rec.RequestStampEDocument();
                    end;
                }
                action("Export E-Document as &XML")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Export E-Document as &XML';
                    Image = ExportElectronicDocument;
                    ToolTip = 'Export the posted sales invoice as an electronic invoice, and XML file, and save it to a specified location.';

                    trigger OnAction()
                    begin
                        Rec.ExportEDocument();
                    end;
                }
                action("&Cancel")
                {
                    ApplicationArea = BasicMX;
                    Caption = '&Cancel';
                    Image = Cancel;
                    ToolTip = 'Cancel the sending of the electronic sales invoice.';

                    trigger OnAction()
                    begin
                        Rec.CancelEDocument();
                    end;
                }
                action("Print Carta Porte Document")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Print Carta Porte Document';
                    Image = PrintForm;
                    ToolTip = 'Prepare to print the Carta Porte document so that it can be shown upon request from inspectors or other authorities.';

                    trigger OnAction()
                    var
                        ElectronicCartaPorteMX: Report "Electronic Carta Porte MX";
                    begin
                        ElectronicCartaPorteMX.SetRecord(Rec);
                        ElectronicCartaPorteMX.Run();
                    end;
                }
            }
            action(SendCustom)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send';
                Ellipsis = true;
                Image = SendToMultiple;
                ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                trigger OnAction()
                var
                    SalesShipmentHeader: Record "Sales Shipment Header";
                begin
                    SalesShipmentHeader := Rec;
                    CurrPage.SetSelectionFilter(SalesShipmentHeader);
                    SalesShipmentHeader.SendRecords();
                end;
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Print the shipping notice.';

                trigger OnAction()
                begin
                    SalesShptHeader := Rec;
                    OnBeforePrintRecords(Rec, SalesShptHeader);
                    CurrPage.SetSelectionFilter(SalesShptHeader);
                    SalesShptHeader.PrintRecords(true);
                end;
            }
            action(Email)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Email';
                Image = Email;
                ToolTip = 'Prepare to email the document. The Send Email window opens prefilled with the customer''s email address so you can add or edit information.';

                trigger OnAction()
                begin
                    SalesShptHeader := Rec;
                    CurrPage.SetSelectionFilter(SalesShptHeader);
                    SalesShptHeader.EmailRecords(true);
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
                    SalesShipmentHeader: Record "Sales Shipment Header";
                begin
                    SalesShipmentHeader := Rec;
                    SalesShipmentHeader.SetRecFilter();
                    Rec.PrintToDocumentAttachment(SalesShipmentHeader);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action("Update Document")
            {
                ApplicationArea = Suite;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document, such as information from the shipping agent. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedSalesShipmentUpdate: Page "Posted Sales Shipment - Update";
                begin
                    PostedSalesShipmentUpdate.LookupMode := true;
                    PostedSalesShipmentUpdate.SetRec(Rec);
                    PostedSalesShipmentUpdate.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

            }
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Update Document_Promoted"; "Update Document")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("&Track Package_Promoted"; "&Track Package")
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';
                }
            }
            group(Category_Category6)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(Print_Promoted; "&Print")
                {
                }
                actionref(Email_Promoted; Email)
                {
                }
                actionref(AttachAsPDF_Promoted; AttachAsPDF)
                {
                }
                actionref(SendCustom_Promoted; SendCustom)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Shipment', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group("Category_Certificate of Supply")
            {
                Caption = 'Certificate of Supply';

                actionref(PrintCertificateofSupply_Promoted; PrintCertificateofSupply)
                {
                }
                actionref(CertificateOfSupplyDetails_Promoted; CertificateOfSupplyDetails)
                {
                }
            }
            group("Category_Electronic Document")
            {
                Caption = 'Electronic Document';

                actionref("S&end_Promoted"; "S&end")
                {
                }
                actionref("Export E-Document as &XML_Promoted"; "Export E-Document as &XML")
                {
                }
                actionref("&Cancel_Promoted"; "&Cancel")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        Rec.SetSecurityFilterOnRespCenter();
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Sell-to Country/Region Code");

        GLSetup.SetLoadFields("Multiple SAT Certificates");
        GLSetup.Get();
        SATCertInLocationEnabled := EInvoiceMgt.IsPACEnvironmentEnabled() and GLSetup."Multiple SAT Certificates";
    end;

    trigger OnAfterGetRecord()
    begin
        SellToContact.GetOrClear(Rec."Sell-to Contact No.");
        BillToContact.GetOrClear(Rec."Bill-to Contact No.");

        if SATCertInLocationEnabled then
            UpdateSATCertificateFields();
    end;

    var
        SalesShptHeader: Record "Sales Shipment Header";
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        FormatAddress: Codeunit "Format Address";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        SATCertInLocationEnabled: Boolean;
        SATCertificateCode: Text;
        SATCertificateName: Text;
        SATCertificateSource: Text;

    local procedure UpdateSATCertificateFields()
    var
        DocumentRecRef: RecordRef;
    begin
        DocumentRecRef.GetTable(Rec);
        EInvoiceMgt.GetSATCertificateInfoForDocument(DocumentRecRef, SATCertificateCode, SATCertificateName, SATCertificateSource);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(SalesShptHeaderRec: Record "Sales Shipment Header"; var SalesShptHeaderToPrint: Record "Sales Shipment Header")
    begin
    end;
}

