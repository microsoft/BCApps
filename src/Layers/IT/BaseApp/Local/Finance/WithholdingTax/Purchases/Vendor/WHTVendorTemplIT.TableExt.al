// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank.Payment;
using Microsoft.CRM.Contact;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Foundation.Address;

tableextension 12202 "WHT VEndor Templ. IT" extends "Vendor Templ."
{
    fields
    {
        field(12101; "Fiscal Code"; Code[20])
        {
            Caption = 'Fiscal Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12102; "Withholding Tax Code"; Code[20])
        {
            Caption = 'Withholding Tax Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Withhold Code";
        }
        field(12103; "Social Security Code"; Code[20])
        {
            Caption = 'Social Security Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Contribution Code".Code where("Contribution Type" = filter(INPS));
        }
        field(12105; "Soc. Sec. 3 Parties Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Soc. Sec. 3 Parties Base';
            DataClassification = CustomerContent;
        }
        field(12106; Resident; Option)
        {
            Caption = 'Resident';
            DataClassification = CustomerContent;
            OptionCaption = 'Resident,Non-Resident';
            OptionMembers = Resident,"Non-Resident";
        }
        field(12108; "Individual Person"; Boolean)
        {
            Caption = 'Individual Person';
            DataClassification = CustomerContent;
        }
        field(12109; "Date of Birth"; Date)
        {
            Caption = 'Date of Birth';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12110; "Birth City"; Text[30])
        {
            Caption = 'Birth City';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Birth Country/Region Code" = const('')) "Post Code".City
            else
            if ("Birth Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Birth Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(12111; "Birth Post Code"; Code[20])
        {
            Caption = 'Birth Post Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Birth Country/Region Code" = const('')) "Post Code"
            else
            if ("Birth Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Birth Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(12112; "Birth County"; Text[30])
        {
            Caption = 'Birth County';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12113; Gender; Option)
        {
            Caption = 'Gender';
            DataClassification = EndUserIdentifiableInformation;
            OptionCaption = ' ,Male,Female';
            OptionMembers = " ",Male,Female;
        }
        field(12114; "Residence Address"; Text[50])
        {
            Caption = 'Residence Address';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12115; "Residence Post Code"; Code[20])
        {
            Caption = 'Residence Post Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Residence Country/Region Code" = const('')) "Post Code"
            else
            if ("Residence Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Residence Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(12116; "Residence City"; Text[30])
        {
            Caption = 'Residence City';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Residence Country/Region Code" = const('')) "Post Code".City
            else
            if ("Residence Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Residence Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(12117; "Country of Fiscal Domicile"; Code[10])
        {
            Caption = 'Country/Region of Fiscal Domicile';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Country/Region";
        }
        field(12118; "Contribution Fiscal Code"; Code[20])
        {
            Caption = 'Contribution Fiscal Code';
            DataClassification = CustomerContent;
        }
        field(12119; "Tax Exempt Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Tax Exempt Amount (LCY)';
            DataClassification = CustomerContent;
        }
        field(12120; "INAIL Code"; Code[20])
        {
            Caption = 'INAIL Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12122; "INAIL 3 Parties Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'INAIL 3 Parties Base';
            DataClassification = CustomerContent;
        }
        field(12126; "Tax Representative Type"; Option)
        {
            Caption = 'Tax Representative Type';
            OptionCaption = ' ,Vendor,Contact';
            OptionMembers = " ",Vendor,Contact;
            DataClassification = CustomerContent;
        }
        field(12127; "Tax Representative No."; Code[20])
        {
            Caption = 'Tax Representative No.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = if ("Tax Representative Type" = filter(Vendor)) Vendor
            else
            if ("Tax Representative Type" = filter(Contact)) Contact;
        }
        field(12129; "Birth Country/Region Code"; Code[10])
        {
            Caption = 'Birth Country/Region Code';
            TableRelation = "Country/Region";
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12130; "Residence County"; Text[30])
        {
            Caption = 'Residence County';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12131; "Residence Country/Region Code"; Code[10])
        {
            Caption = 'Residence Country/Region Code';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "Country/Region";
        }
    }
}

