// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

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
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Reminder;
using System.Globalization;

/// <summary>
/// Stores customer template definitions with predefined field values for creating new customers.
/// </summary>
table 1381 "Customer Templ."
{
    Caption = 'Customer Template';
    LookupPageID = "Customer Templ. List";
    DrillDownPageID = "Customer Templ. List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique identifier code for this customer template.
        /// </summary>
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies the code of the template.';
        }
        /// <summary>
        /// Specifies a description to help identify the purpose of this customer template.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the template.';
        }
        /// <summary>
        /// Specifies the default address for customers created from this template.
        /// </summary>
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the customer''s address. This address will appear on all sales documents for the customer.';
        }
        /// <summary>
        /// Specifies additional default address information for customers created from this template.
        /// </summary>
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        /// <summary>
        /// Specifies the default city for customers created from this template.
        /// </summary>
        field(7; City; Text[30])
        {
            Caption = 'City';
            ToolTip = 'Specifies the customer''s city.';

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
        /// <summary>
        /// Specifies the default phone number for customers created from this template.
        /// </summary>
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
            ToolTip = 'Specifies the customer''s telephone number.';
        }
        /// <summary>
        /// Specifies the default telex number for customers created from this template.
        /// </summary>
        field(10; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        /// <summary>
        /// Specifies the default document sending profile for customers created from this template.
        /// </summary>
        field(11; "Document Sending Profile"; Code[20])
        {
            Caption = 'Document Sending Profile';
            TableRelation = "Document Sending Profile".Code;
            ToolTip = 'Specifies the preferred method of sending documents to this customer.';
        }
        /// <summary>
        /// Specifies your account number at the customer's organization.
        /// </summary>
        field(14; "Our Account No."; Text[20])
        {
            Caption = 'Our Account No.';
        }
        /// <summary>
        /// Specifies the default territory code for customers created from this template.
        /// </summary>
        field(15; "Territory Code"; Code[10])
        {
            Caption = 'Territory Code';
            TableRelation = Territory;
        }
        /// <summary>
        /// Specifies the default global dimension 1 value for customers created from this template.
        /// </summary>
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
        /// <summary>
        /// Specifies the default global dimension 2 value for customers created from this template.
        /// </summary>
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
        /// <summary>
        /// Specifies the default chain or franchise name for customers created from this template.
        /// </summary>
        field(18; "Chain Name"; Code[10])
        {
            Caption = 'Chain Name';
        }
        /// <summary>
        /// Specifies the default budgeted amount for customers created from this template.
        /// </summary>
        field(19; "Budgeted Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Budgeted Amount';
        }
        /// <summary>
        /// Specifies the default credit limit in local currency for customers created from this template.
        /// </summary>
        field(20; "Credit Limit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Credit Limit (LCY)';
            ToolTip = 'Specifies the maximum amount of credit that you extend to the customer for their purchases before you issue warnings. The value 0 represents unlimited credit.';
        }
        /// <summary>
        /// Specifies the default customer posting group for customers created from this template.
        /// </summary>
        field(21; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
            TableRelation = "Customer Posting Group";
            ToolTip = 'Specifies the customer''s market type to link business transactions to.';
        }
        /// <summary>
        /// Specifies the default currency for customers created from this template.
        /// </summary>
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
            ToolTip = 'Specifies the default currency for the customer.';
        }
        /// <summary>
        /// Specifies the default customer price group for customers created from this template.
        /// </summary>
        field(23; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
            ToolTip = 'Specifies the customer price group code, which you can use to set up special sales prices in the Sales Prices page.';
        }
        /// <summary>
        /// Specifies the default language code for customers created from this template.
        /// </summary>
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
            ToolTip = 'Specifies the language to be used on printouts for this customer.';
        }
        /// <summary>
        /// Specifies the default statistics group for customers created from this template.
        /// </summary>
        field(26; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
            ToolTip = 'Specifies the statistics group.';
        }
        /// <summary>
        /// Specifies the default payment terms for customers created from this template.
        /// </summary>
        field(27; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
            ToolTip = 'Specifies a code that indicates the payment terms that you require of the customer.';
        }
        /// <summary>
        /// Specifies the default finance charge terms for customers created from this template.
        /// </summary>
        field(28; "Fin. Charge Terms Code"; Code[10])
        {
            Caption = 'Fin. Charge Terms Code';
            TableRelation = "Finance Charge Terms";
            ToolTip = 'Specifies whether to calculate finance charges for the customer.';
        }
        /// <summary>
        /// Specifies the default salesperson for customers created from this template.
        /// </summary>
        field(29; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
            ToolTip = 'Specifies a code for the salesperson who normally handles this customer''s account.';
        }
        /// <summary>
        /// Specifies the default shipment method for customers created from this template.
        /// </summary>
        field(30; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
            ToolTip = 'Specifies which shipment method to use when you ship items to the customer.';
        }
        /// <summary>
        /// Specifies the default shipping agent for customers created from this template.
        /// </summary>
        field(31; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
            ToolTip = 'Specifies which shipping company is used when you ship items to the customer.';
        }
        /// <summary>
        /// Specifies the default place of export for customers created from this template.
        /// </summary>
        field(32; "Place of Export"; Code[20])
        {
            Caption = 'Place of Export';
        }
        /// <summary>
        /// Specifies the default invoice discount code for customers created from this template.
        /// </summary>
        field(33; "Invoice Disc. Code"; Code[20])
        {
            Caption = 'Invoice Disc. Code';
            TableRelation = Customer;
            ValidateTableRelation = false;
            ToolTip = 'Specifies a code for the invoice discount terms that you have defined for the customer.';
        }
        /// <summary>
        /// Specifies the default customer discount group for customers created from this template.
        /// </summary>
        field(34; "Customer Disc. Group"; Code[20])
        {
            Caption = 'Customer Disc. Group';
            TableRelation = "Customer Discount Group";
            ToolTip = 'Specifies the customer discount group code, which you can use as a criterion to set up special discounts in the Sales Line Discounts page.';
        }
        /// <summary>
        /// Specifies the default country or region for customers created from this template.
        /// </summary>
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country/region of the address.';

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
        /// <summary>
        /// Specifies the default collection method for customers created from this template.
        /// </summary>
        field(36; "Collection Method"; Code[20])
        {
            Caption = 'Collection Method';
        }
        /// <summary>
        /// Specifies a default amount for customers created from this template.
        /// </summary>
        field(37; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        /// <summary>
        /// Specifies the default blocked status for customers created from this template.
        /// </summary>
        field(39; Blocked; Enum "Customer Blocked")
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies which transactions with the customer that cannot be processed, for example, because the customer is insolvent.';
        }
        /// <summary>
        /// Indicates whether to include customers created from this template in printed statements.
        /// </summary>
        field(42; "Print Statements"; Boolean)
        {
            Caption = 'Print Statements';
            ToolTip = 'Specifies whether to include this customer when you print the Statement report.';
        }
        /// <summary>
        /// Specifies the default bill-to customer for customers created from this template.
        /// </summary>
        field(45; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;
            ToolTip = 'Specifies a different customer who will be invoiced for products that you sell to the customer in the Name field on the customer card.';
        }
        /// <summary>
        /// Specifies the default payment method for customers created from this template.
        /// </summary>
        field(47; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
            ToolTip = 'Specifies how the customer usually submits payment, such as bank transfer or check.';
        }
        /// <summary>
        /// Specifies the default regional format for customers created from this template.
        /// </summary>
        field(48; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
            ToolTip = 'Specifies the region format to be used on printouts for this customer.';
        }
        /// <summary>
        /// Specifies the default application method for customers created from this template.
        /// </summary>
        field(80; "Application Method"; Enum "Application Method")
        {
            Caption = 'Application Method';
            ToolTip = 'Specifies how to apply payments to entries for this customer.';
        }
        /// <summary>
        /// Indicates whether prices include VAT for customers created from this template.
        /// </summary>
        field(82; "Prices Including VAT"; Boolean)
        {
            Caption = 'Prices Including VAT';
            ToolTip = 'Specifies whether to show VAT in the Unit Price and Line Amount fields on document lines.';
        }
        /// <summary>
        /// Specifies the default inventory location for customers created from this template.
        /// </summary>
        field(83; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
            ToolTip = 'Specifies from which location sales to this customer will be processed by default.';
        }
        /// <summary>
        /// Specifies the default fax number for customers created from this template.
        /// </summary>
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
            ToolTip = 'Specifies the customer''s fax number.';
        }
        /// <summary>
        /// Specifies the default telex answer back code for customers created from this template.
        /// </summary>
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        /// <summary>
        /// Specifies the default VAT registration number for customers created from this template.
        /// </summary>
        field(86; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            ToolTip = 'Specifies the customer''s VAT registration number for customers in EU countries/regions.';
        }
        /// <summary>
        /// Indicates whether to combine shipments by default for customers created from this template.
        /// </summary>
        field(87; "Combine Shipments"; Boolean)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Combine Sales Shipments';
            ToolTip = 'Specifies if several orders delivered to the customer can appear on the same sales invoice.';
        }
        /// <summary>
        /// Specifies the default general business posting group for customers created from this template.
        /// </summary>
        field(88; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
            ToolTip = 'Specifies the customer''s trade type to link transactions made for this customer with the appropriate general ledger account according to the general posting setup.';
        }
        /// <summary>
        /// Specifies the default Global Location Number for customers created from this template.
        /// </summary>
        field(90; GLN; Code[13])
        {
            Caption = 'GLN';
            Numeric = true;
            ToolTip = 'Specifies the customer in connection with electronic document sending.';
        }
        /// <summary>
        /// Specifies the default postal code for customers created from this template.
        /// </summary>
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
        /// <summary>
        /// Specifies the default state, province, or county for customers created from this template.
        /// </summary>
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
            ToolTip = 'Specifies the state, province or county as a part of the address.';
        }
        /// <summary>
        /// Specifies the default EORI number for customs purposes for customers created from this template.
        /// </summary>
        field(93; "EORI Number"; Text[40])
        {
            Caption = 'EORI Number';
            ToolTip = 'Specifies the Economic Operators Registration and Identification number that is used when you exchange information with the customs authorities due to trade into or out of the European Union.';
        }
        /// <summary>
        /// Indicates whether to use the GLN in electronic documents for customers created from this template.
        /// </summary>
        field(95; "Use GLN in Electronic Document"; Boolean)
        {
            Caption = 'Use GLN in Electronic Documents';
            ToolTip = 'Specifies whether the GLN is used in electronic documents as a party identification number.';
        }
        /// <summary>
        /// Specifies the default email address for customers created from this template.
        /// </summary>
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
            ToolTip = 'Specifies the customer''s email address.';
        }
        /// <summary>
        /// Specifies the default website URL for customers created from this template.
        /// </summary>
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
            ToolTip = 'Specifies the customer''s home page address.';
        }
        /// <summary>
        /// Specifies the default reminder terms for customers created from this template.
        /// </summary>
        field(104; "Reminder Terms Code"; Code[10])
        {
            Caption = 'Reminder Terms Code';
            TableRelation = "Reminder Terms";
            ToolTip = 'Specifies how reminders about late payments are handled for this customer.';
        }
        /// <summary>
        /// Specifies the number series used for assigning customer numbers when using this template.
        /// </summary>
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
            ToolTip = 'Specifies the number series that will be used to assign numbers to customers.';
        }
        /// <summary>
        /// Specifies the default tax area for customers created from this template.
        /// </summary>
        field(108; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
            ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
        }
        /// <summary>
        /// Indicates whether customers created from this template are liable for sales tax.
        /// </summary>
        field(109; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            ToolTip = 'Specifies if the customer or vendor is liable for sales tax.';
        }
        /// <summary>
        /// Specifies the default VAT business posting group for customers created from this template.
        /// </summary>
        field(110; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
            ToolTip = 'Specifies the customer''s VAT specification to link transactions made for this customer to.';
        }
        /// <summary>
        /// Specifies the default reservation method for customers created from this template.
        /// </summary>
        field(115; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Reserve';
            InitValue = Optional;
            ToolTip = 'Specifies whether items will never, automatically (Always), or optionally be reserved for this customer.';
        }
        /// <summary>
        /// Indicates whether payment tolerance is blocked for customers created from this template.
        /// </summary>
        field(116; "Block Payment Tolerance"; Boolean)
        {
            Caption = 'Block Payment Tolerance';
            ToolTip = 'Specifies that the customer is not allowed a payment tolerance.';
        }
        /// <summary>
        /// Specifies the default intercompany partner for customers created from this template.
        /// </summary>
        field(119; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            TableRelation = "IC Partner";
            ToolTip = 'Specifies the customer''s intercompany partner code.';
        }
        /// <summary>
        /// Specifies the default prepayment percentage for customers created from this template.
        /// </summary>
        field(124; "Prepayment %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
            ToolTip = 'Specifies a prepayment percentage that applies to all orders for this customer, regardless of the items or services on the order lines.';
        }
        /// <summary>
        /// Specifies the default partner type for direct debit collections for customers created from this template.
        /// </summary>
        field(132; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';
            ToolTip = 'Specifies for direct debit collections if the customer that the payment is collected from is a person or a company.';
        }
        /// <summary>
        /// Specifies the default partner type for Intrastat reporting for customers created from this template.
        /// </summary>
        field(133; "Intrastat Partner Type"; Enum "Partner Type")
        {
            Caption = 'Intrastat Partner Type';
            ToolTip = 'Specifies for Intrastat reporting if the customer is a person or a company.';
        }
        /// <summary>
        /// Indicates whether data access is blocked for privacy reasons for customers created from this template.
        /// </summary>
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
        /// <summary>
        /// Indicates whether search by name is disabled for customers created from this template.
        /// </summary>
        field(160; "Disable Search by Name"; Boolean)
        {
            Caption = 'Disable Search by Name';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies that you can change customer name in the document, because the name is not used in search.';
        }
        /// <summary>
        /// Indicates whether multiple posting groups are allowed for customers created from this template.
        /// </summary>
        field(175; "Allow Multiple Posting Groups"; Boolean)
        {
            Caption = 'Allow Multiple Posting Groups';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies if multiple posting groups can be used for posting business transactions for this customer.';
        }
        /// <summary>
        /// Specifies the default cash flow payment terms for customers created from this template.
        /// </summary>
        field(840; "Cash Flow Payment Terms Code"; Code[10])
        {
            Caption = 'Cash Flow Payment Terms Code';
            TableRelation = "Payment Terms";
            ToolTip = 'Specifies a payment term that will be used to calculate cash flow for the customer.';
        }
        /// <summary>
        /// Specifies the default contact type for customers created from this template.
        /// </summary>
        field(5050; "Contact Type"; Enum "Contact Type")
        {
            Caption = 'Contact Type';
            ToolTip = 'Specifies the type of contact that will be used to create a customer with the template.';
        }
        /// <summary>
        /// Specifies the default mobile phone number for customers created from this template.
        /// </summary>
        field(5061; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            ExtendedDatatype = PhoneNo;
            ToolTip = 'Specifies the customer''s mobile telephone number.';
        }
        /// <summary>
        /// Specifies the default responsibility center for customers created from this template.
        /// </summary>
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
            ToolTip = 'Specifies the code for the responsibility center that will administer this customer by default.';
        }
        /// <summary>
        /// Specifies the default shipping advice for customers created from this template.
        /// </summary>
        field(5750; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Shipping Advice';
            ToolTip = 'Specifies if the customer accepts partial shipment of orders.';
        }
        /// <summary>
        /// Specifies the default shipping time for customers created from this template.
        /// </summary>
        field(5790; "Shipping Time"; DateFormula)
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Time';
            ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
        }
        /// <summary>
        /// Specifies the default shipping agent service for customers created from this template.
        /// </summary>
        field(5792; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
            ToolTip = 'Specifies the code for the shipping agent service to use for this customer.';
        }
        /// <summary>
        /// Specifies the default price calculation method for customers created from this template.
        /// </summary>
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            ToolTip = 'Specifies the default price calculation method.';
            trigger OnValidate()
            var
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
                PriceType: Enum "Price Type";
            begin
                if Rec."Price Calculation Method" <> Rec."Price Calculation Method"::" " then
                    PriceCalculationMgt.VerifyMethodImplemented(Rec."Price Calculation Method", PriceType::Sale);
            end;
        }
        /// <summary>
        /// Indicates whether line discounts are allowed for customers created from this template.
        /// </summary>
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            InitValue = true;
            ToolTip = 'Specifies whether to calculate a sales line discount when a special sales price is offered, according to setup in the Sales Prices page.';
        }
        /// <summary>
        /// Specifies the default base calendar for customers created from this template.
        /// </summary>
        field(7600; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            TableRelation = "Base Calendar";
            ToolTip = 'Specifies a customizable calendar for shipment planning that holds the customer''s working days and holidays.';
        }
        /// <summary>
        /// Specifies the default source for copying sell-to address on quotes for customers created from this template.
        /// </summary>
        field(7601; "Copy Sell-to Addr. to Qte From"; Enum "Contact Type")
        {
            AccessByPermission = TableData Contact = R;
            Caption = 'Copy Sell-to Addr. to Qte From';
            ToolTip = 'Specifies which customer address is inserted on sales quotes that you create for the customer.';
        }
        /// <summary>
        /// Indicates whether to validate EU VAT registration numbers for customers created from this template.
        /// </summary>
        field(7602; "Validate EU Vat Reg. No."; Boolean)
        {
            Caption = 'Validate EU VAT Reg. No.';
            ToolTip = 'Specifies if the VAT registration number will be specified in the EU VAT Registration No. Check page so that it is validated against the VAT registration number validation service.';
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
        DefaultDimension.SetRange("Table ID", Database::"Customer Templ.");
        DefaultDimension.SetRange("No.", Code);
        DefaultDimension.DeleteAll();
    end;

    trigger OnRename()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.RenameDefaultDim(Database::"Customer Templ.", xRec.Code, Code);
    end;

    local procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(Database::"Customer Templ.", Code, FieldNumber, ShortcutDimCode);
            Modify();
        end;
    end;

    /// <summary>
    /// Copies all fields and dimensions from another customer template.
    /// </summary>
    /// <param name="SourceCustomerTempl">The source template to copy from.</param>
    procedure CopyFromTemplate(SourceCustomerTempl: Record "Customer Templ.")
    begin
        CopyTemplate(SourceCustomerTempl);
        CopyDimensions(SourceCustomerTempl);
        OnAfterCopyFromTemplate(SourceCustomerTempl, Rec);
    end;

    local procedure CopyTemplate(SourceCustomerTempl: Record "Customer Templ.")
    var
        SavedCustomerTempl: Record "Customer Templ.";
    begin
        SavedCustomerTempl := Rec;
        TransferFields(SourceCustomerTempl, false);
        Code := SavedCustomerTempl.Code;
        Description := SavedCustomerTempl.Description;
        OnCopyTemplateOnBeforeModify(SourceCustomerTempl, SavedCustomerTempl, Rec);
        Modify();
    end;

    local procedure CopyDimensions(SourceCustomerTempl: Record "Customer Templ.")
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        DestDefaultDimension.SetRange("Table ID", Database::"Customer Templ.");
        DestDefaultDimension.SetRange("No.", Code);
        DestDefaultDimension.DeleteAll(true);

        SourceDefaultDimension.SetRange("Table ID", Database::"Customer Templ.");
        SourceDefaultDimension.SetRange("No.", SourceCustomerTempl.Code);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", Database::"Customer Templ.");
                DestDefaultDimension.Validate("No.", Code);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if DestDefaultDimension.Insert(true) then;
            until SourceDefaultDimension.Next() = 0;
    end;

    /// <summary>
    /// Raises an event after copying field values from a source customer template.
    /// </summary>
    /// <param name="SourceCustomerTempl">The source customer template record that values were copied from.</param>
    /// <param name="CustomerTempl">The destination customer template record that was updated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTemplate(SourceCustomerTempl: Record "Customer Templ."; var CustomerTempl: Record "Customer Templ.")
    begin
    end;

    /// <summary>
    /// Raises an event before modifying the customer template during the copy operation.
    /// </summary>
    /// <param name="SourceCustomerTempl">The source customer template record being copied from.</param>
    /// <param name="SavedCustomerTempl">The original customer template record before transfer.</param>
    /// <param name="CustomerTempl">The customer template record being modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCopyTemplateOnBeforeModify(SourceCustomerTempl: Record "Customer Templ."; SavedCustomerTempl: Record "Customer Templ."; var CustomerTempl: Record "Customer Templ.")
    begin
    end;
}