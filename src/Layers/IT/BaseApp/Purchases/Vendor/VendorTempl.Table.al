// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Document;
using Microsoft.Sales.FinanceCharge;
using System.Globalization;

table 1383 "Vendor Templ."
{
    Caption = 'Vendor Template';
    LookupPageID = "Vendor Templ. List";
    DrillDownPageID = "Vendor Templ. List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';

            trigger OnLookup()
            var
                PostCode: Record "Post Code";
                CityText: Text;
                CountyText: Text;
            begin
                PostCode.LookupPostCode(CityText, "Post Code", CountyText, "Country/Region Code");
                City := CopyStr(CityText, 1, MaxStrLen(City));
                County := CopyStr(CountyText, 1, MaxStrLen(County));
            end;

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(10; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(14; "Our Account No."; Text[20])
        {
            Caption = 'Our Account No.';
        }
        field(15; "Territory Code"; Code[10])
        {
            Caption = 'Territory Code';
            TableRelation = Territory;
        }
        field(16; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(17; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(19; "Budgeted Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Budgeted Amount';
        }
        field(21; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(26; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
            ToolTip = 'Specifies the statistics group.';
        }
        field(27; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(28; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            TableRelation = "Finance Charge Terms";
        }
        field(29; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
        }
        field(30; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(31; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(33; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
            TableRelation = Vendor;
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
                CityText: Text;
                CountyText: Text;
            begin
                PostCode.CheckClearPostCodeCityCounty(CityText, "Post Code", CountyText, "Country/Region Code", xRec."Country/Region Code");
                City := CopyStr(CityText, 1, MaxStrLen(City));
                County := CopyStr(CountyText, 1, MaxStrLen(County));
            end;
        }
        field(39; Blocked; Enum "Vendor Blocked")
        {
            Caption = 'Blocked';
        }
        field(45; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            TableRelation = Vendor;
        }
        field(46; Priority; Integer)
        {
            Caption = 'Priority';
        }
        field(47; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(48; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(80; "Application Method"; Enum "Application Method")
        {
            Caption = 'Application Method';
        }
        field(82; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(86; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(88; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(90; GLN; Code[13])
        {
            Caption = 'GLN';
            Numeric = true;
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';

            trigger OnLookup()
            var
                PostCode: Record "Post Code";
                CityText: Text;
                CountyText: Text;
            begin
                PostCode.LookupPostCode(CityText, "Post Code", CountyText, "Country/Region Code");
                City := CopyStr(CityText, 1, MaxStrLen(City));
                County := CopyStr(CountyText, 1, MaxStrLen(County));
            end;

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(93; "EORI Number"; Text[40])
        {
            Caption = 'EORI Number';
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
        }
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(103; "Home Page"; Text[255])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(108; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(109; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(110; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(116; "Block Payment Tolerance"; Boolean)
        {
            Caption = 'Block Payment Tolerance';
        }
        field(124; "Prepayment %"; Decimal)
        {
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(150; "Privacy Blocked"; Boolean)
        {
            Caption = 'Privacy Blocked';

            trigger OnValidate()
            begin
                if "Privacy Blocked" then
                    Blocked := Blocked::All
                else
                    Blocked := Blocked::" ";
            end;
        }
        field(160; "Disable Search by Name"; Boolean)
        {
            Caption = 'Disable Search by Name';
            DataClassification = SystemMetadata;
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
        }
        field(840; "Cash Flow Payment Terms Code"; Code[10])
        {
            Caption = 'Cash Flow Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(132; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
        }
        field(133; "Intrastat Partner Type"; Enum "Partner Type")
        {
            Caption = 'Intrastat Partner Type';
        }
        field(5050; "Contact Type"; Enum "Contact Type")
        {
            Caption = 'Contact Type';
        }
        field(5061; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            ExtendedDatatype = PhoneNo;
        }

        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(5701; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';

            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                if "Price Calculation Method" <> "Price Calculation Method"::" " then
                    PriceCalculationMgt.VerifyMethodImplemented("Price Calculation Method", PriceType::Purchase);
            end;
        }
        field(7600; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            TableRelation = "Base Calendar";
        }
        field(7601; "Document Sending Profile"; Code[20])
        {
            Caption = 'Document Sending Profile';
            TableRelation = "Document Sending Profile".Code;
        }
        field(7602; "Validate EU Vat Reg. No."; Boolean)
        {
            Caption = 'Validate EU VAT Reg. No.';
        }
        field(7603; "Copy Buy-from Add. to Qte From"; Enum "Contact Type")
        {
            AccessByPermission = TableData Contact = R;
            Caption = 'Copy Buy-from Addr. to Qte From';
            ToolTip = 'Specifies which vendor address is inserted on purchase quotes that you create for the vendor.';
        }
        field(8510; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";
        }
        field(12100; "Int. on Arrears Code"; Code[10])
        {
            Caption = 'Int. on Arrears Code';
            TableRelation = "Finance Charge Terms";
        }
        field(12101; "Fiscal Code"; Code[20])
        {
            Caption = 'Fiscal Code';
        }
        field(12102; "Withholding Tax Code"; Code[20])
        {
            Caption = 'Withholding Tax Code';
            TableRelation = "Withhold Code";
        }
        field(12103; "Social Security Code"; Code[20])
        {
            Caption = 'Social Security Code';
            TableRelation = "Contribution Code".Code where("Contribution Type" = filter(INPS));
        }
        field(12105; "Soc. Sec. 3 Parties Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Soc. Sec. 3 Parties Base';
        }
        field(12106; Resident; Option)
        {
            Caption = 'Resident';
            OptionCaption = 'Resident,Non-Resident';
            OptionMembers = Resident,"Non-Resident";
        }
        field(12108; "Individual Person"; Boolean)
        {
            Caption = 'Individual Person';
        }
        field(12109; "Date of Birth"; Date)
        {
            Caption = 'Date of Birth';
        }
        field(12110; "Birth City"; Text[30])
        {
            Caption = 'Birth City';
            TableRelation = if ("Birth Country/Region Code" = const('')) "Post Code".City
            else
            if ("Birth Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Birth Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(12111; "Birth Post Code"; Code[20])
        {
            Caption = 'Birth Post Code';
            TableRelation = if ("Birth Country/Region Code" = const('')) "Post Code"
            else
            if ("Birth Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Birth Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(12112; "Birth County"; Text[30])
        {
            Caption = 'Birth County';
        }
        field(12113; Gender; Option)
        {
            Caption = 'Gender';
            OptionCaption = ' ,Male,Female';
            OptionMembers = " ",Male,Female;
        }
        field(12114; "Residence Address"; Text[50])
        {
            Caption = 'Residence Address';
        }
        field(12115; "Residence Post Code"; Code[20])
        {
            Caption = 'Residence Post Code';
            TableRelation = if ("Residence Country/Region Code" = const('')) "Post Code"
            else
            if ("Residence Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Residence Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(12116; "Residence City"; Text[30])
        {
            Caption = 'Residence City';
            TableRelation = if ("Residence Country/Region Code" = const('')) "Post Code".City
            else
            if ("Residence Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Residence Country/Region Code"));
            ValidateTableRelation = false;
        }
        field(12117; "Country of Fiscal Domicile"; Code[10])
        {
            Caption = 'Country/Region of Fiscal Domicile';
            TableRelation = "Country/Region";
        }
        field(12118; "Contribution Fiscal Code"; Code[20])
        {
            Caption = 'Contribution Fiscal Code';
        }
        field(12119; "Tax Exempt Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Tax Exempt Amount (LCY)';
        }
        field(12120; "INAIL Code"; Code[20])
        {
            Caption = 'INAIL Code';
        }
        field(12122; "INAIL 3 Parties Base"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'INAIL 3 Parties Base';
        }
        field(12126; "Tax Representative Type"; Option)
        {
            Caption = 'Tax Representative Type';
            OptionCaption = ' ,Vendor,Contact';
            OptionMembers = " ",Vendor,Contact;
        }
        field(12127; "Tax Representative No."; Code[20])
        {
            Caption = 'Tax Representative No.';
            TableRelation = if ("Tax Representative Type" = filter(Vendor)) Vendor
            else
            if ("Tax Representative Type" = filter(Contact)) Contact;
        }
        field(12129; "Birth Country/Region Code"; Code[10])
        {
            Caption = 'Birth Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(12130; "Residence County"; Text[30])
        {
            Caption = 'Residence County';
        }
        field(12131; "Residence Country/Region Code"; Code[10])
        {
            Caption = 'Residence Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(12170; "Apply Company Payment days"; Boolean)
        {
            Caption = 'Apply Company Payment days';
            InitValue = true;
        }
        field(12180; "Subcontracting Location Code"; Code[10])
        {
            Caption = 'Subcontracting Location Code';
            TableRelation = Location;
        }
        field(12181; "Subcontractor Procurement"; Boolean)
        {
            Caption = 'Subcontractor Procurement';
        }
        field(12183; Subcontractor; Boolean)
        {
            Caption = 'Subcontractor';
        }
        field(12184; "First Name"; Text[30])
        {
            Caption = 'First Name';
        }
        field(12185; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
        }
        field(12186; "Prepmt. Payment Terms Code"; Code[10])
        {
            Caption = 'Prepmt. Payment Terms Code';
            TableRelation = "Payment Terms" where("Payment Nos." = const(1));
        }
        field(12187; "Special Category"; Option)
        {
            Caption = 'Special Category';
            OptionCaption = ' ,A,B,C,D,E,F,G,H,K,L,M,N,P,Q,R,S,T,T1,T2,T3,T4,U,V,W,Y,Z,Z2';
            OptionMembers = " ",A,B,C,D,E,F,G,H,K,L,M,N,P,Q,R,S,T,T1,T2,T3,T4,U,V,W,Y,Z,Z2;
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", Database::"Vendor Templ.");
        DefaultDimension.SetRange("No.", Code);
        DefaultDimension.DeleteAll();
    end;

    trigger OnRename()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.RenameDefaultDim(Database::"Vendor Templ.", xRec.Code, Code);
    end;

    local procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(Database::"Vendor Templ.", Code, FieldNumber, ShortcutDimCode);
            Modify();
        end;
    end;

    procedure CopyFromTemplate(SourceVendorTempl: Record "Vendor Templ.")
    begin
        CopyTemplate(SourceVendorTempl);
        CopyDimensions(SourceVendorTempl);
        OnAfterCopyFromTemplate(SourceVendorTempl, Rec);
    end;

    local procedure CopyTemplate(SourceVendorTempl: Record "Vendor Templ.")
    var
        SavedVendorTempl: Record "Vendor Templ.";
    begin
        SavedVendorTempl := Rec;
        TransferFields(SourceVendorTempl, false);
        Code := SavedVendorTempl.Code;
        Description := SavedVendorTempl.Description;
        OnCopyTemplateOnBeforeModify(SourceVendorTempl, SavedVendorTempl, Rec);
        Modify();
    end;

    local procedure CopyDimensions(SourceVendorTempl: Record "Vendor Templ.")
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        DestDefaultDimension.SetRange("Table ID", Database::"Vendor Templ.");
        DestDefaultDimension.SetRange("No.", Code);
        DestDefaultDimension.DeleteAll(true);

        SourceDefaultDimension.SetRange("Table ID", Database::"Vendor Templ.");
        SourceDefaultDimension.SetRange("No.", SourceVendorTempl.Code);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", Database::"Vendor Templ.");
                DestDefaultDimension.Validate("No.", Code);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if DestDefaultDimension.Insert(true) then;
            until SourceDefaultDimension.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTemplate(SourceVendorTempl: Record "Vendor Templ."; var VendorTempl: Record "Vendor Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyTemplateOnBeforeModify(SourceVendorTempl: Record "Vendor Templ."; SavedVendorTempl: Record "Vendor Templ."; var VendorTempl: Record "Vendor Templ.")
    begin
    end;
}
