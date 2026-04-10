// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;

page 1386 "Vendor Templ. Card"
{
    Caption = 'Vendor Template';
    PageType = Card;
    SourceTable = "Vendor Templ.";

    layout
    {
        area(content)
        {
            group(Template)
            {
                Caption = 'General';
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Contact Type"; Rec."Contact Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Disable Search by Name"; Rec."Disable Search by Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Statistics Group"; Rec."Statistics Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
            group(AddressAndContact)
            {
                Caption = 'Address & Contact';
                field(Address; Rec.Address)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Address 2"; Rec."Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
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
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                group(CountyGroup)
                {
                    ShowCaption = false;
                    Visible = IsCountyVisible;
                    field(County; Rec.County)
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(MobilePhoneNo; Rec."Mobile Phone No.")
                {
                    Caption = 'Mobile Phone No.';
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = PhoneNo;
                    Visible = false;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    Importance = Promoted;
                    Visible = false;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Our Account No."; Rec."Our Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                group(Contact)
                {
                    Caption = 'Contact';
                    field("Language Code"; Rec."Language Code")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Format Region"; Rec."Format Region")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Document Sending Profile"; Rec."Document Sending Profile")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    Visible = false;
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
                    Visible = false;
                }
                field("Copy Buy-from Add. to Qte From"; Rec."Copy Buy-from Add. to Qte From")
                {
                    Visible = false;
                    ApplicationArea = Basic, Suite;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    Visible = false;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    Visible = false;
                }
                field("Validate EU Vat Reg. No."; Rec."Validate EU Vat Reg. No.")
                {
                    ApplicationArea = Basic, Suite;
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
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Price Calculation Method"; Rec."Price Calculation Method")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    Visible = false;
                }
                group(PostingDetails)
                {
                    Caption = 'Posting details';
                    field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
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
                        Importance = Promoted;
                        ShowMandatory = true;
                    }
                }
                group(ForeignTrade)
                {
                    Caption = 'Foreign Trade';
                    field("Currency Code"; Rec."Currency Code")
                    {
                        ApplicationArea = Suite;
                    }
                }
            }
            group(Payments)
            {
                Caption = 'Payments';
                field("Prepayment %"; Rec."Prepayment %")
                {
                    ApplicationArea = Prepayments;
                    Importance = Additional;
                    Visible = false;
                }
                field("Application Method"; Rec."Application Method")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Block Payment Tolerance"; Rec."Block Payment Tolerance")
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
                    Visible = false;
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
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Visible = false;
                }
                field("Over-Receipt Code"; Rec."Over-Receipt Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Dimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Image = Dimensions;
                RunObject = Page "Default Dimensions";
                RunPageLink = "Table ID" = const(1383),
                              "No." = field(Code);
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
            }
            action(CopyTemplate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Template';
                Image = Copy;
                ToolTip = 'Copies all information to the current template from the selected one.';

                trigger OnAction()
                var
                    VendorTempl: Record "Vendor Templ.";
                    VendorTemplList: Page "Vendor Templ. List";
                begin
                    Rec.TestField(Code);
                    VendorTempl.SetFilter(Code, '<>%1', Rec.Code);
                    VendorTemplList.LookupMode(true);
                    VendorTemplList.SetTableView(VendorTempl);
                    if VendorTemplList.RunModal() = Action::LookupOK then begin
                        VendorTemplList.GetRecord(VendorTempl);
                        Rec.CopyFromTemplate(VendorTempl);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopyTemplate_Promoted; CopyTemplate)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsCountyVisible: Boolean;
}
