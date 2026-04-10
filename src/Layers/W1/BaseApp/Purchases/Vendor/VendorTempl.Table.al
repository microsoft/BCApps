// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
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
            ToolTip = 'Specifies the code of the template.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the template.';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the vendor''s address.';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            ToolTip = 'Specifies the vendor''s city.';

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
            ToolTip = 'Specifies the vendor''s telephone number.';
            ExtendedDatatype = PhoneNo;
        }
        field(10; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(14; "Our Account No."; Text[20])
        {
            Caption = 'Our Account No.';
            ToolTip = 'Specifies your account number with the vendor, if you have one.';
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
            ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
            TableRelation = "Vendor Posting Group";
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the default currency on purchase documents or journal lines that you create for the vendor.';
            TableRelation = Currency;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
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
            ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
            TableRelation = "Payment Terms";
        }
        field(28; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            ToolTip = 'Specifies how the vendor calculates finance charges.';
            TableRelation = "Finance Charge Terms";
        }
        field(29; "Purchaser Code"; Code[20])
        {
            Caption = 'Purchaser Code';
            ToolTip = 'Specifies which purchaser is assigned to the vendor.';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
        }
        field(30; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
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
            ToolTip = 'Specifies the vendor''s invoice discount code. When you set up a new vendor card, the number you have entered in the No. field is automatically inserted.';
            TableRelation = Vendor;
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            ToolTip = 'Specifies the country/region of the address.';
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
            ToolTip = 'Specifies whether transactions with this vendor are restricted. Use this field to control vendor activity, such as temporarily halting payments or fully blocking a vendor due to compliance or business decisions. The field can have one of the following values: (blank) - No restrictions, all transactions are allowed. All - All transactions with this vendor are blocked. You cannot create or post any documents or journals with the vendor. Payment - Only payment transactions are blocked. You can still create and post purchase documents, but you cannot make payments to the vendor.';
        }
        field(45; "Pay-to Vendor No."; Code[20])
        {
            Caption = 'Pay-to Vendor No.';
            ToolTip = 'Specifies the number of a different vendor whom you pay for products delivered by the vendor on the vendor card.';
            TableRelation = Vendor;
        }
        field(46; Priority; Integer)
        {
            Caption = 'Priority';
            ToolTip = 'Specifies the importance of the vendor when suggesting payments using the Suggest Vendor Payments function.';
        }
        field(47; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            ToolTip = 'Specifies how to make payments, such as with bank transfers or by cash or check.';
            TableRelation = "Payment Method";
        }
        field(48; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            ToolTip = 'Specifies the region format to be used on printouts for this vendor.';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(80; "Application Method"; Enum "Application Method")
        {
            Caption = 'Application Method';
            ToolTip = 'Specifies how to apply payments to entries for this vendor.';
        }
        field(82; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
            ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
            ToolTip = 'Specifies the vendor''s fax number.';
        }
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(86; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            ToolTip = 'Specifies the vendor''s VAT registration number.';
        }
        field(88; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s trade type to link transactions made for this vendor with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";
        }
        field(90; GLN; Code[13])
        {
            Caption = 'GLN';
            ToolTip = 'Specifies the vendor in connection with electronic document receiving.';
            Numeric = true;
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            ToolTip = 'Specifies the postal code.';

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
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        field(93; "EORI Number"; Text[40])
        {
            Caption = 'EORI Number';
            ToolTip = 'Specifies the Economic Operators Registration and Identification number that is used when you exchange information with the customs authorities due to trade into or out of the European Union.';
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ToolTip = 'Specifies the vendor''s email address.';
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
            ToolTip = 'Specifies the vendor''s web site.';
            ExtendedDatatype = URL;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the number series that will be used to assign numbers to vendors.';
            TableRelation = "No. Series";
        }
        field(108; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            ToolTip = 'Specifies a tax area code for the company.';
            TableRelation = "Tax Area";
        }
        field(109; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if the customer is liable for sales tax.';
        }
        field(110; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Business Posting Group";
        }
        field(116; "Block Payment Tolerance"; Boolean)
        {
            Caption = 'Block Payment Tolerance';
            ToolTip = 'Specifies whether to allow a payment tolerance for the vendor.';
        }
        field(124; "Prepayment %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment %';
            ToolTip = 'Specifies a prepayment percentage that applies to all orders for this vendor, regardless of the items or services on the order lines.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(150; "Privacy Blocked"; Boolean)
        {
            Caption = 'Privacy Blocked';
            ToolTip = 'Specifies whether to limit access to data for the data subject during daily operations. This is useful, for example, when protecting data from changes while it is under privacy review.';

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
            ToolTip = 'Specifies that you can change vendor name in the document.';
            DataClassification = SystemMetadata;
        }
        field(170; "Creditor No."; Code[20])
        {
            Caption = 'Creditor No.';
            ToolTip = 'Specifies the number of the vendor.';
        }
        field(840; "Cash Flow Payment Terms Code"; Code[10])
        {
            Caption = 'Cash Flow Payment Terms Code';
            ToolTip = 'Specifies a payment term that will be used for calculating cash flow.';
            TableRelation = "Payment Terms";
        }
        field(132; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
            ToolTip = 'Specifies if the vendor is a person or a company.';
        }
        field(133; "Intrastat Partner Type"; Enum "Partner Type")
        {
            Caption = 'Intrastat Partner Type';
            ToolTip = 'Specifies for Intrastat reporting if the vendor is a person or a company.';
        }
        field(5050; "Contact Type"; Enum "Contact Type")
        {
            Caption = 'Contact Type';
            ToolTip = 'Specifies the type of contact that will be used to create a vendor with the template.';
        }
        field(5061; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            ToolTip = 'Specifies the vendor''s mobile telephone number.';
            ExtendedDatatype = PhoneNo;
        }

        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
            TableRelation = "Responsibility Center";
        }
        field(5701; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the warehouse location where items from the vendor must be received by default.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            ToolTip = 'Specifies the default price calculation method.';

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
            ToolTip = 'Specifies a customizable calendar for delivery planning that holds the vendor''s working days and holidays.';
            TableRelation = "Base Calendar";
        }
        field(7601; "Document Sending Profile"; Code[20])
        {
            Caption = 'Document Sending Profile';
            ToolTip = 'Specifies the preferred method of sending documents to this vendor.';
            TableRelation = "Document Sending Profile".Code;
        }
        field(7602; "Validate EU Vat Reg. No."; Boolean)
        {
            Caption = 'Validate EU VAT Reg. No.';
            ToolTip = 'Specifies if the VAT registration number will be specified in the EU VAT Registration No. Check page so that it is validated against the VAT registration number validation service.';
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
            ToolTip = 'Specifies the policy that will be used for the vendor if more items than ordered are received.';
            TableRelation = "Over-Receipt Code";
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
