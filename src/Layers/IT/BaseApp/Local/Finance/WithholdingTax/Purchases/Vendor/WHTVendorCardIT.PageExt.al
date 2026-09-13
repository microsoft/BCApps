// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

pageextension 12201 "WHT Vendor Card IT" extends "Vendor Card"
{
    layout
    {
        addafter("Last Date Modified")
        {
            field("Fiscal Code"; Rec."Fiscal Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the customer''s identification code assigned by the Finance and Economics Government Department.';
            }
        }
        addafter("Foreign Trade")
        {
            field("Tax Representative Type"; Rec."Tax Representative Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the tax representative is a vendor or a contact.';
            }
            field("Tax Representative No."; Rec."Tax Representative No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the identification number of the vendor''s tax representative.';
            }
        }
        addafter(Invoicing)
        {
            group("Free Lance Fee")
            {
                Caption = 'Free Lance Fee';
                field(Resident; Rec.Resident)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the individual is a resident or non-resident of Italy.';
                }
                field("Residence Address"; Rec."Residence Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the vendor''s residence.';
                }
                field("Residence Post Code"; Rec."Residence Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the vendor''s residence.';
                }
                field("Residence City"; Rec."Residence City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city where the vendor resides.';
                }
                field("First Name"; Rec."First Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first name of the individual person.';
                }
                field("Last Name"; Rec."Last Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surname of the individual person.';
                }
                field("Residence County"; Rec."Residence County")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county where the vendor resides.';
                }
                field("Date of Birth"; Rec."Date of Birth")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the vendor''s birth.';
                }
                field("Birth Post Code"; Rec."Birth Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code of the city where the vendor was born.';
                }
                field("Birth City"; Rec."Birth City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the city where the vendor was born.';
                }
                field("Birth County"; Rec."Birth County")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the county where the vendor was born.';
                }
                field(Gender; Rec.Gender)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the vendor is male or female.';
                }
                field("Individual Person"; Rec."Individual Person")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies if the vendor is an individual person.';
                }
                field("Withholding Tax Code"; Rec."Withholding Tax Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withholding tax code that is applied to a purchase. ';
                }
                field("Social Security Code"; Rec."Social Security Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Social Security code that is applied to the payment.';
                }
                field("Soc. Sec. Company Base"; Rec."Soc. Sec. Company Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to Social Security withholding tax.';
                }
                field("Soc. Sec. 3 Parties Base"; Rec."Soc. Sec. 3 Parties Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the Social Security tax liability that is the responsibility of the independent contractor or vendor.';
                }
                field("Country of Fiscal Domicile"; Rec."Country of Fiscal Domicile")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country of the vendor''s permanent residence.';
                }
                field("Contribution Fiscal Code"; Rec."Contribution Fiscal Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code assigned to contribution taxes that have been applied to a purchase invoice from an independent contractor or consultant.';
                }
                field("INAIL Code"; Rec."INAIL Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the INAIL withholding tax code that is applied to this purchase for workers compensation insurance.';
                }
                field("INAIL Company Base"; Rec."INAIL Company Base")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the Italian Workers'' Compensation Authority (INAIL) tax amount that your company is liable for.';
                }
                field("INAIL 3 Parties Base"; Rec."INAIL 3 Parties Base")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the INAIL tax liability that is the responsibility of the independent contractor or vendor.';
                }
            }
            group(Individual)
            {
                Caption = 'Individual';
                field("First Name2"; Rec."First Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first name of the individual person.';
                }
                field("Last Name2"; Rec."Last Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the surname of the individual person.';
                }
            }
        }
    }
}