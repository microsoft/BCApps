// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.CRM.Team;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;
using System.Email;

/// <summary>
/// Stores alternate shipping addresses for customers with location and shipping method settings.
/// </summary>
table 222 "Ship-to Address"
{
    Caption = 'Ship-to Address';
    DataCaptionFields = "Customer No.", Name, "Code";
    LookupPageID = "Ship-to Address List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the customer that this ship-to address belongs to.
        /// </summary>
        field(1; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;
            ToolTip = 'Specifies the customer number.';
        }
        /// <summary>
        /// Specifies a unique code to identify this ship-to address for the customer.
        /// </summary>
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
            ToolTip = 'Specifies a ship-to address code.';
        }
        /// <summary>
        /// Specifies the name of the recipient or location for this ship-to address.
        /// </summary>
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name associated with the ship-to address.';
        }
        /// <summary>
        /// Specifies additional name information for the ship-to address.
        /// </summary>
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
            ToolTip = 'Specifies an additional part of the name.';
        }
        /// <summary>
        /// Specifies the street address for shipping.
        /// </summary>
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the ship-to address.';
        }
        /// <summary>
        /// Specifies additional address details for the shipping location.
        /// </summary>
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        /// <summary>
        /// Specifies the city for the shipping destination.
        /// </summary>
        field(7; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;
            ToolTip = 'Specifies the city the items are being shipped to.';

            trigger OnLookup()
            begin
                OnBeforeLookupCity(Rec, PostCode);

                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");

                OnAfterLookupCity(Rec, PostCode, xRec);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                OnAfterValidateCity(Rec, PostCode);
            end;
        }
        /// <summary>
        /// Specifies the contact person at the ship-to address.
        /// </summary>
        field(8; Contact; Text[100])
        {
            Caption = 'Contact';
            ToolTip = 'Specifies the name of the person you contact about orders shipped to this address.';
        }
        /// <summary>
        /// Specifies the telephone number for the ship-to address.
        /// </summary>
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
            ToolTip = 'Specifies the recipient''s telephone number.';
        }
        /// <summary>
        /// Specifies the telex number for the ship-to address.
        /// </summary>
        field(10; "Telex No."; Text[30])
        {
            Caption = 'Telex No.';
        }
        /// <summary>
        /// Specifies the salesperson responsible for orders to this ship-to address.
        /// </summary>
        field(29; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
            ToolTip = 'Specifies a code for the salesperson who normally handles this customer''s recipient.';

            trigger OnValidate()
            begin
                ValidateSalesPersonCode();
            end;
        }
        /// <summary>
        /// Specifies the default shipment method for orders to this address.
        /// </summary>
        field(30; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
            ToolTip = 'Specifies a code for the shipment method to be used for the recipient.';
        }
        /// <summary>
        /// Specifies the shipping agent responsible for deliveries to this address.
        /// </summary>
        field(31; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
            ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';

            trigger OnValidate()
            begin
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
        }
        /// <summary>
        /// Specifies the place of export for customs purposes.
        /// </summary>
        field(32; "Place of Export"; Code[20])
        {
            Caption = 'Place of Export';
        }
        /// <summary>
        /// Specifies the country or region for the ship-to address.
        /// </summary>
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country/region of the address.';

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
                AltCustVATRegFacade.HandleCountryChangeInShipToAddress(Rec);
            end;
        }
        /// <summary>
        /// Indicates when this ship-to address record was last modified.
        /// </summary>
        field(54; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
            ToolTip = 'Specifies when the ship-to address was last modified.';
        }
        /// <summary>
        /// Specifies the default inventory location for shipments to this address.
        /// </summary>
        field(83; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
            ToolTip = 'Specifies the location code to be used for the recipient.';
        }
        /// <summary>
        /// Specifies the fax number for the ship-to address.
        /// </summary>
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
            ToolTip = 'Specifies the recipient''s fax number.';
        }
        /// <summary>
        /// Specifies the telex answer back code for the ship-to address.
        /// </summary>
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        /// <summary>
        /// Specifies the Global Location Number for this ship-to address.
        /// </summary>
        field(90; GLN; Code[13])
        {
            Caption = 'GLN';
            ToolTip = 'Specifies the recipient''s GLN code.';

            trigger OnValidate()
            var
                GLNCalculator: Codeunit "GLN Calculator";
            begin
                if GLN <> '' then
                    GLNCalculator.AssertValidCheckDigit13(GLN);
            end;
        }
        /// <summary>
        /// Specifies the postal code for the ship-to address.
        /// </summary>
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;
            ToolTip = 'Specifies the postal code.';

            trigger OnLookup()
            begin
                OnBeforeLookupPostCode(Rec, PostCode);

                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");

                OnAfterLookupPostCode(Rec, PostCode, xRec);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
                OnAfterValidatePostCode(Rec, PostCode);
            end;
        }
        /// <summary>
        /// Specifies the state, province, or county for the ship-to address.
        /// </summary>
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
            ToolTip = 'Specifies the state, province, or county as a part of the address.';
        }
        /// <summary>
        /// Specifies the email address for the ship-to address.
        /// </summary>
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;
            ToolTip = 'Specifies the recipient''s email address.';

            trigger OnValidate()
            begin
                ValidateEmail()
            end;
        }
        /// <summary>
        /// Specifies the website URL for the ship-to address.
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
            ToolTip = 'Specifies the recipient''s web site.';
        }
        /// <summary>
        /// Specifies the tax area code for calculating sales tax at this ship-to address.
        /// </summary>
        field(108; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates whether sales to this ship-to address are subject to sales tax.
        /// </summary>
        field(109; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        /// <summary>
        /// Specifies the shipping agent service level for deliveries to this address.
        /// </summary>
        field(5792; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
            ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
        }
    }

    keys
    {
        key(Key1; "Customer No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name, Address, City, "Post Code")
        {
        }
    }

    trigger OnInsert()
    begin
        Cust.Get("Customer No.");
        Name := Cust.Name;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        "Last Date Modified" := Today;
    end;

    var
        Cust: Record Customer;
        PostCode: Record "Post Code";
        AltCustVATRegFacade: Codeunit "Alt. Cust. VAT. Reg. Facade";

#pragma warning disable AA0074
        Text000: Label 'untitled';
#pragma warning restore AA0074

    /// <summary>
    /// Generates a caption text for the ship-to address including customer and address information.
    /// </summary>
    /// <returns>The formatted caption string.</returns>
    procedure Caption(): Text
    begin
        if "Customer No." = '' then
            exit(Text000);
        Cust.Get("Customer No.");
        exit(StrSubstNo('%1 %2 %3 %4', Cust."No.", Cust.Name, Code, Name));
    end;

    /// <summary>
    /// Displays the ship-to address on an online map service.
    /// </summary>
    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::"Ship-to Address", GetPosition());
    end;

    /// <summary>
    /// Gets the customer number from the current filter if a single value is specified.
    /// </summary>
    /// <returns>The filtered customer number or empty if not applicable.</returns>
    procedure GetFilterCustNo(): Code[20]
    begin
        if GetFilter("Customer No.") <> '' then
            if GetRangeMin("Customer No.") = GetRangeMax("Customer No.") then
                exit(GetRangeMax("Customer No."));
    end;


    local procedure ValidateEmail()
    var
        MailManagement: Codeunit "Mail Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateEmail(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        MailManagement.ValidateEmailAddressField("E-Mail");
    end;

    local procedure ValidateSalesPersonCode()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if "Salesperson Code" = '' then
            exit;

        if not SalespersonPurchaser.Get("Salesperson Code") then
            exit;

        if SalespersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalespersonPurchaser) then
            Error(SalespersonPurchaser.GetPrivacyBlockedGenericText(SalespersonPurchaser, true))
    end;

    /// <summary>
    /// Raised after looking up the post code.
    /// </summary>
    /// <param name="ShipToAddress">The ship-to address record.</param>
    /// <param name="PostCodeRec">The post code record used in the lookup.</param>
    /// <param name="xShipToAddress">The previous ship-to address record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupPostCode(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code"; xShipToAddress: Record "Ship-to Address");
    begin
    end;

    /// <summary>
    /// Raised after looking up the city.
    /// </summary>
    /// <param name="ShipToAddress">The ship-to address record.</param>
    /// <param name="PostCodeRec">The post code record used in the lookup.</param>
    /// <param name="xShipToAddress">The previous ship-to address record.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupCity(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code"; xShipToAddress: Record "Ship-to Address");
    begin
    end;

    /// <summary>
    /// Raised after validating the city field.
    /// </summary>
    /// <param name="ShipToAddress">The ship-to address record after validation.</param>
    /// <param name="PostCode">The post code record used in validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCity(var ShipToAddress: Record "Ship-to Address"; var PostCode: Record "Post Code");
    begin
    end;

    /// <summary>
    /// Raised after validating the post code field.
    /// </summary>
    /// <param name="ShipToAddress">The ship-to address record after validation.</param>
    /// <param name="PostCode">The post code record used in validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostCode(var ShipToAddress: Record "Ship-to Address"; var PostCode: Record "Post Code");
    begin
    end;

    /// <summary>
    /// Raised before looking up the city.
    /// </summary>
    /// <param name="ShipToAddress">The ship-to address record.</param>
    /// <param name="PostCodeRec">The post code record for the lookup.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupCity(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code");
    begin
    end;

    /// <summary>
    /// Raised before looking up the post code.
    /// </summary>
    /// <param name="ShipToAddress">The ship-to address record.</param>
    /// <param name="PostCodeRec">The post code record for the lookup.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostCode(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code");
    begin
    end;

    /// <summary>
    /// Raised before validating the city field.
    /// </summary>
    /// <param name="ShipToAddress">The ship-to address record.</param>
    /// <param name="PostCodeRec">The post code record for validation.</param>
    /// <param name="CurrentFieldNo">The current field number being validated.</param>
    /// <param name="IsHandled">Set to true to skip the default validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Raised before validating the email field.
    /// </summary>
    /// <param name="ShiptoAddress">The ship-to address record.</param>
    /// <param name="xShiptoAddress">The previous ship-to address record.</param>
    /// <param name="IsHandled">Set to true to skip the default validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEmail(var ShiptoAddress: Record "Ship-to Address"; xShiptoAddress: Record "Ship-to Address"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raised before validating the post code field.
    /// </summary>
    /// <param name="ShipToAddress">The ship-to address record.</param>
    /// <param name="PostCodeRec">The post code record for validation.</param>
    /// <param name="CurrentFieldNo">The current field number being validated.</param>
    /// <param name="IsHandled">Set to true to skip the default validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var ShipToAddress: Record "Ship-to Address"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;
}
