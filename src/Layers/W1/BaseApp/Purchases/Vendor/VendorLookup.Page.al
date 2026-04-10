// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

page 34 "Vendor Lookup"
{
    Caption = 'Vendors';
    CardPageID = "Vendor Card";
    Editable = false;
    PageType = List;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Advanced;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the post code.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the phone number.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("E-Mail"; Rec."E-mail")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s pay-to vendor (who should receive invoices).';
                    Visible = false;
                }
                field("Registration Number"; Rec."Registration Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s registration number.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Visible = false;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Suite;
                }
                field("Vendor Posting Group"; Rec."Vendor Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Privacy Blocked"; Rec."Privacy Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Application Method"; Rec."Application Method")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Location Code2"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the warehouse location where items from the vendor must be received by default.';
                    Visible = false;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(VendorList)
            {
                ApplicationArea = All;
                Caption = 'Advanced View';
                Image = CustomerList;
                ToolTip = 'Open the Vendors page showing all possible columns. ';

                trigger OnAction()
                var
                    VendorList: Page "Vendor List";
                begin
                    VendorList.SetTableView(Rec);
                    VendorList.SetRecord(Rec);
                    VendorList.LookupMode := true;
                    if VendorList.RunModal() = ACTION::LookupOK then begin
                        VendorList.GetRecord(Rec);
                        CurrPage.Close();
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(VendorList_Promoted; VendorList)
                {
                }
            }
        }
    }
}

