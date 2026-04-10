// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.CRM.Campaign;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;

/// <summary>
/// Stores temporary sales price entries for batch price updates before applying them to the Sales Price table.
/// </summary>
table 7023 "Sales Price Worksheet"
{
    Caption = 'Sales Price Worksheet';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the item that the worksheet price entry applies to.
        /// </summary>
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item for which sales prices are being changed or set up.';
            NotBlank = true;
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then begin
                    "Unit of Measure Code" := '';
                    "Variant Code" := '';
                end;

                if "Sales Type" = "Sales Type"::"Customer Price Group" then
                    if CustPriceGr.Get("Sales Code") and
                       (CustPriceGr."Allow Invoice Disc." <> "Allow Invoice Disc.")
                    then
                        if Item.Get("Item No.") then
                            "Allow Invoice Disc." := Item."Allow Invoice Disc.";

                CalcCurrentPrice(PriceAlreadyExists);
            end;
        }
        /// <summary>
        /// Specifies the customer, customer price group, or campaign that the worksheet price entry applies to.
        /// </summary>
        field(2; "Sales Code"; Code[20])
        {
            Caption = 'Sales Code';
            ToolTip = 'Specifies the Sales Type code.';
            TableRelation = if ("Sales Type" = const("Customer Price Group")) "Customer Price Group"
            else
            if ("Sales Type" = const(Customer)) Customer
            else
            if ("Sales Type" = const(Campaign)) Campaign;

            trigger OnValidate()
            begin
                if ("Sales Code" <> '') and ("Sales Type" = "Sales Type"::"All Customers") then
                    Error(Text001, FieldCaption("Sales Code"));

                SetSalesDescription();
                CalcCurrentPrice(PriceAlreadyExists);

                if ("Sales Code" = '') and ("Sales Type" <> "Sales Type"::"All Customers") then
                    exit;

                if not PriceAlreadyExists and ("Sales Code" <> '') then
                    case "Sales Type" of
                        "Sales Type"::"Customer Price Group":
                            begin
                                CustPriceGr.Get("Sales Code");
                                "Price Includes VAT" := CustPriceGr."Price Includes VAT";
                                "VAT Bus. Posting Gr. (Price)" := CustPriceGr."VAT Bus. Posting Gr. (Price)";
                                "Allow Line Disc." := CustPriceGr."Allow Line Disc.";
                                "Allow Invoice Disc." := CustPriceGr."Allow Invoice Disc.";
                            end;
                        "Sales Type"::Customer:
                            begin
                                Cust.Get("Sales Code");
                                "Currency Code" := Cust."Currency Code";
                                "Price Includes VAT" := Cust."Prices Including VAT";
                                "Allow Line Disc." := Cust."Allow Line Disc.";
                            end;
                        "Sales Type"::Campaign:
                            begin
                                Campaign.Get("Sales Code");
                                "Starting Date" := Campaign."Starting Date";
                                "Ending Date" := Campaign."Ending Date";
                            end;
                    end;
            end;
        }
        /// <summary>
        /// Specifies the currency that the worksheet price entry is valid for. A blank value indicates the local currency.
        /// </summary>
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code of the sales price.';
            TableRelation = Currency;

            trigger OnValidate()
            begin
                CalcCurrentPrice(PriceAlreadyExists);
            end;
        }
        /// <summary>
        /// Specifies the date from which the worksheet price entry is valid.
        /// </summary>
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the earliest date on which the item can be sold at the sales price.';

            trigger OnValidate()
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
                    Error(Text000, FieldCaption("Starting Date"), FieldCaption("Ending Date"));

                if CurrFieldNo <> 0 then
                    if "Sales Type" = "Sales Type"::Campaign then
                        Error(Text002, FieldCaption("Starting Date"), FieldCaption("Ending Date"), FieldCaption("Sales Type"), "Sales Type");

                CalcCurrentPrice(PriceAlreadyExists);
            end;
        }
        /// <summary>
        /// Contains the existing unit price from the sales price table for reference during price updates.
        /// </summary>
        field(5; "Current Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Current Unit Price';
            ToolTip = 'Specifies the unit price of the item.';
            Editable = false;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the new unit price to be applied when the worksheet entries are implemented.
        /// </summary>
        field(6; "New Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'New Unit Price';
            ToolTip = 'Specifies the new unit price that is valid for the selected combination of Sales Code, Currency Code and/or Starting Date.';
            MinValue = 0;
        }
        /// <summary>
        /// Indicates whether the new unit price includes VAT.
        /// </summary>
        field(7; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
            ToolTip = 'Specifies if the sales price includes VAT.';
        }
        /// <summary>
        /// Indicates whether invoice discounts can be applied when this price is used.
        /// </summary>
        field(10; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            ToolTip = 'Specifies if an invoice discount will be calculated when the sales price is offered.';
            InitValue = true;
        }
        /// <summary>
        /// Specifies the VAT business posting group used for price calculations when the price includes VAT.
        /// </summary>
        field(11; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// Specifies the type of sales target for the worksheet price entry, such as customer, customer price group, all customers, or campaign.
        /// </summary>
        field(13; "Sales Type"; Enum "Sales Price Type")
        {
            Caption = 'Sales Type';
            ToolTip = 'Specifies the type of sale that the price is based on, such as All Customers or Campaign.';

            trigger OnValidate()
            begin
                if "Sales Type" <> xRec."Sales Type" then
                    Validate("Sales Code", '');
            end;
        }
        /// <summary>
        /// Specifies the minimum quantity that must be ordered to qualify for this price.
        /// </summary>
        field(14; "Minimum Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Minimum Quantity';
            ToolTip = 'Specifies the minimum sales quantity that must be met to warrant the sales price.';
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcCurrentPrice(PriceAlreadyExists);
            end;
        }
        /// <summary>
        /// Specifies the last date on which the worksheet price entry is valid.
        /// </summary>
        field(15; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Specifies the date on which the sales price agreement ends.';

            trigger OnValidate()
            begin
                Validate("Starting Date");

                if CurrFieldNo <> 0 then
                    if "Sales Type" = "Sales Type"::Campaign then
                        Error(Text002, FieldCaption("Starting Date"), FieldCaption("Ending Date"), FieldCaption("Sales Type"), "Sales Type");
            end;
        }
        /// <summary>
        /// Contains the description of the item from the item table for display purposes.
        /// </summary>
        field(20; "Item Description"; Text[100])
        {
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Caption = 'Item Description';
            ToolTip = 'Specifies the description of the item on the worksheet line.';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Contains the name or description of the customer, customer price group, or campaign for display purposes.
        /// </summary>
        field(21; "Sales Description"; Text[100])
        {
            Caption = 'Sales Description';
            ToolTip = 'Specifies the description of the sales type, such as Campaign, on the worksheet line.';
        }
        /// <summary>
        /// Specifies the unit of measure that the worksheet price entry applies to for the item.
        /// </summary>
        field(5400; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                CalcCurrentPrice(PriceAlreadyExists);
            end;
        }
        /// <summary>
        /// Specifies the item variant that the worksheet price entry applies to.
        /// </summary>
        field(5700; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                CalcCurrentPrice(PriceAlreadyExists);
            end;
        }
        /// <summary>
        /// Indicates whether line discounts can be applied when this price is used.
        /// </summary>
        field(7001; "Allow Line Disc."; Boolean)
        {
            Caption = 'Allow Line Disc.';
            ToolTip = 'Specifies if a line discount will be calculated when the sales price is offered.';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Starting Date", "Ending Date", "Sales Type", "Sales Code", "Currency Code", "Item No.", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Variant Code", "Unit of Measure Code", "Minimum Quantity", "Starting Date", "Ending Date", "Sales Type", "Sales Code", "Currency Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if "Sales Type" = "Sales Type"::"All Customers" then
            "Sales Code" := ''
        else
            TestField("Sales Code");
        TestField("Item No.");
    end;

    trigger OnRename()
    begin
        if "Sales Type" <> "Sales Type"::"All Customers" then
            TestField("Sales Code");
        TestField("Item No.");
    end;

    var
        CustPriceGr: Record "Customer Price Group";
        Cust: Record Customer;
        Campaign: Record Campaign;
        PriceAlreadyExists: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cannot be after %2';
        Text001: Label '%1 must be blank.';
        Text002: Label '%1 and %2 can only be altered from the Campaign Card when %3 = %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        Item: Record Item;

    /// <summary>
    /// Calculates and retrieves the current price for the worksheet item based on matching sales price records.
    /// </summary>
    /// <param name="PriceAlreadyExists">Returns true if a sales price record with the same starting date already exists.</param>
    procedure CalcCurrentPrice(var PriceAlreadyExists: Boolean)
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice.SetRange("Item No.", "Item No.");
        SalesPrice.SetRange("Sales Type", "Sales Type");
        SalesPrice.SetRange("Sales Code", "Sales Code");
        SalesPrice.SetRange("Currency Code", "Currency Code");
        SalesPrice.SetRange("Unit of Measure Code", "Unit of Measure Code");
        SalesPrice.SetRange("Starting Date", 0D, "Starting Date");
        SalesPrice.SetRange("Minimum Quantity", 0, "Minimum Quantity");
        SalesPrice.SetRange("Variant Code", "Variant Code");
        OnCalcCurrentPriceOnAfterSetFilters(SalesPrice, Rec);
        if SalesPrice.FindLast() then begin
            "Current Unit Price" := SalesPrice."Unit Price";
            "Price Includes VAT" := SalesPrice."Price Includes VAT";
            "Allow Line Disc." := SalesPrice."Allow Line Disc.";
            "Allow Invoice Disc." := SalesPrice."Allow Invoice Disc.";
            "VAT Bus. Posting Gr. (Price)" := SalesPrice."VAT Bus. Posting Gr. (Price)";
            PriceAlreadyExists := SalesPrice."Starting Date" = "Starting Date";
            OnAfterCalcCurrentPriceFound(Rec, SalesPrice);
        end else begin
            "Current Unit Price" := 0;
            PriceAlreadyExists := false;
            OnCalcCurrentPriceOnPriceNotFound(Rec);
        end;
    end;

    /// <summary>
    /// Sets the Sales Description field based on the sales type and code.
    /// </summary>
    procedure SetSalesDescription()
    var
        Customer: Record Customer;
        CustomerPriceGroup: Record "Customer Price Group";
        Campaign: Record Campaign;
    begin
        "Sales Description" := '';
        if "Sales Code" = '' then
            exit;
        case "Sales Type" of
            "Sales Type"::Customer:
                if Customer.Get("Sales Code") then
                    "Sales Description" := Customer.Name;
            "Sales Type"::"Customer Price Group":
                if CustomerPriceGroup.Get("Sales Code") then
                    "Sales Description" := CustomerPriceGroup.Description;
            "Sales Type"::Campaign:
                if Campaign.Get("Sales Code") then
                    "Sales Description" := Campaign.Description;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCurrentPriceFound(var SalesPriceWorksheet: Record "Sales Price Worksheet"; SalesPrice: Record "Sales Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCurrentPriceOnAfterSetFilters(var SalesPrice: Record "Sales Price"; SalesPriceWorksheet: Record "Sales Price Worksheet")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCurrentPriceOnPriceNotFound(var SalesPriceWorksheet: Record "Sales Price Worksheet")
    begin
    end;
}
