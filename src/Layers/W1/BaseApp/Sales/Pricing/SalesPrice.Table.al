// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.CRM.Campaign;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;

/// <summary>
/// Stores sales prices for items by customer type, currency, and validity period with support for quantity breaks.
/// </summary>
table 7002 "Sales Price"
{
    Caption = 'Sales Price';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the item that the sales price applies to.
        /// </summary>
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item for which the sales price is valid.';
            NotBlank = true;
            TableRelation = Item;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeItemNoOnValidate(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Item No." <> xRec."Item No." then begin
                    Item.Get("Item No.");
                    "Unit of Measure Code" := Item."Sales Unit of Measure";
                    "Variant Code" := '';
                end;

                if "Sales Type" = "Sales Type"::"Customer Price Group" then
                    if CustPriceGr.Get("Sales Code") and
                       (CustPriceGr."Allow Invoice Disc." = "Allow Invoice Disc.")
                    then
                        exit;

                UpdateValuesFromItem();
            end;
        }
        /// <summary>
        /// Specifies the customer, customer price group, or campaign that the sales price applies to.
        /// </summary>
        field(2; "Sales Code"; Code[20])
        {
            Caption = 'Sales Code';
            ToolTip = 'Specifies the code that belongs to the Sales Type.';
            TableRelation = if ("Sales Type" = const("Customer Price Group")) "Customer Price Group"
            else
            if ("Sales Type" = const(Customer)) Customer
            else
            if ("Sales Type" = const(Campaign)) Campaign;

            trigger OnValidate()
            begin
                if "Sales Code" <> '' then
                    case "Sales Type" of
                        "Sales Type"::"All Customers":
                            Error(Text001, FieldCaption("Sales Code"));
                        "Sales Type"::"Customer Price Group":
                            begin
                                CustPriceGr.Get("Sales Code");
                                OnValidateSalesCodeOnAfterGetCustomerPriceGroup(Rec, CustPriceGr);
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
                                "VAT Bus. Posting Gr. (Price)" := Cust."VAT Bus. Posting Group";
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
        /// Specifies the currency that the sales price is valid for. A blank value indicates the local currency.
        /// </summary>
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the code for the currency of the sales price.';
            TableRelation = Currency;
        }
        /// <summary>
        /// Specifies the date from which the sales price is valid.
        /// </summary>
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date from which the sales price is valid.';

            trigger OnValidate()
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
                    Error(Text000, FieldCaption("Starting Date"), FieldCaption("Ending Date"));

                if CurrFieldNo = 0 then
                    exit;

                if "Starting Date" <> 0D then
                    if "Sales Type" = "Sales Type"::Campaign then
                        Error(Text002, "Sales Type");
            end;
        }
        /// <summary>
        /// Specifies the unit price for the item when sold under this pricing agreement.
        /// </summary>
        field(5; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
            MinValue = 0;
        }
        /// <summary>
        /// Indicates whether the unit price includes VAT.
        /// </summary>
        field(7; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
            ToolTip = 'Specifies if the sales price includes VAT.';
        }
        /// <summary>
        /// Indicates whether invoice discounts can be applied when this sales price is used.
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
        /// Specifies the type of sales target for the price, such as customer, customer price group, all customers, or campaign.
        /// </summary>
        field(13; "Sales Type"; Enum "Sales Price Type")
        {
            Caption = 'Sales Type';
            ToolTip = 'Specifies the sales price type, which defines whether the price is for an individual, group, all customers, or a campaign.';

            trigger OnValidate()
            begin
                if "Sales Type" <> xRec."Sales Type" then begin
                    Validate("Sales Code", '');
                    UpdateValuesFromItem();
                end;
            end;
        }
        /// <summary>
        /// Specifies the minimum quantity that must be ordered to qualify for this sales price.
        /// </summary>
        field(14; "Minimum Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Minimum Quantity';
            ToolTip = 'Specifies the minimum sales quantity required to warrant the sales price.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the last date on which the sales price is valid.
        /// </summary>
        field(15; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Specifies the calendar date when the sales price agreement ends.';

            trigger OnValidate()
            begin
                if CurrFieldNo = 0 then
                    exit;

                Validate("Starting Date");

                if "Ending Date" <> 0D then
                    if "Sales Type" = "Sales Type"::Campaign then
                        Error(Text002, "Sales Type");
            end;
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        /// <summary>
        /// Indicates whether the sales price is coupled to a record in Dynamics 365 Sales.
        /// </summary>
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dynamics 365 Sales';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(7002)));
        }
        /// <summary>
        /// Specifies the unit of measure that the sales price applies to for the item.
        /// </summary>
        field(5400; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        /// <summary>
        /// Specifies the item variant that the sales price applies to.
        /// </summary>
        field(5700; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        /// <summary>
        /// Indicates whether line discounts can be applied when this sales price is used.
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
        key(Key1; "Item No.", "Sales Type", "Sales Code", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
            Clustered = true;
        }
        key(Key2; "Sales Type", "Sales Code", "Item No.", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
        }
        key(Key3; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Sales Type", "Sales Code", "Item No.", "Starting Date", "Unit Price", "Ending Date")
        {
        }
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

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 must be blank.';
        Text000: Label '%1 cannot be after %2';
        Text002: Label 'If Sales Type = %1, then you can only change Starting Date and Ending Date from the Campaign Card.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected var
        Item: Record Item;

    local procedure UpdateValuesFromItem()
    begin
        if Item.Get("Item No.") then begin
            "Allow Invoice Disc." := Item."Allow Invoice Disc.";
            if "Sales Type" = "Sales Type"::"All Customers" then begin
                "Price Includes VAT" := Item."Price Includes VAT";
                "VAT Bus. Posting Gr. (Price)" := Item."VAT Bus. Posting Gr. (Price)";
            end;
        end;
    end;

    /// <summary>
    /// Copies sales prices to a specific customer by creating customer-specific price records.
    /// </summary>
    /// <param name="SalesPrice">The sales price records to copy.</param>
    /// <param name="CustNo">The customer number to assign to the new sales price records.</param>
    procedure CopySalesPriceToCustomersSalesPrice(var SalesPrice: Record "Sales Price"; CustNo: Code[20])
    var
        NewSalesPrice: Record "Sales Price";
    begin
        if SalesPrice.FindSet() then
            repeat
                NewSalesPrice := SalesPrice;
                NewSalesPrice."Sales Type" := NewSalesPrice."Sales Type"::Customer;
                NewSalesPrice."Sales Code" := CustNo;
                OnBeforeNewSalesPriceInsert(NewSalesPrice, SalesPrice);
                if NewSalesPrice.Insert() then;
            until SalesPrice.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeItemNoOnValidate(var SalesPrice: Record "Sales Price"; var xSalesPrice: Record "Sales Price"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewSalesPriceInsert(var NewSalesPrice: Record "Sales Price"; SalesPrice: Record "Sales Price")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSalesCodeOnAfterGetCustomerPriceGroup(var Salesprice: Record "Sales Price"; CustPriceGroup: Record "Customer Price Group")
    begin
    end;
}
