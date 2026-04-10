// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.CRM.Campaign;
using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;

/// <summary>
/// Stores sales line discounts by item or item discount group, customer type, and validity period.
/// </summary>
table 7004 "Sales Line Discount"
{
    Caption = 'Sales Line Discount';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the item number or item discount group code that the line discount applies to.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies one of two values, depending on the value in the Type field.';
            NotBlank = true;
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const("Item Disc. Group")) "Item Discount Group";

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if xRec.Code <> Code then begin
                    "Unit of Measure Code" := '';
                    "Variant Code" := '';

                    if Type = Type::Item then
                        if Item.Get(Code) then
                            "Unit of Measure Code" := Item."Sales Unit of Measure"
                end;
            end;
        }
        /// <summary>
        /// Specifies the customer, customer discount group, or campaign that the line discount applies to.
        /// </summary>
        field(2; "Sales Code"; Code[20])
        {
            Caption = 'Sales Code';
            ToolTip = 'Specifies one of the following values, depending on the value in the Sales Type field.';
            TableRelation = if ("Sales Type" = const("Customer Disc. Group")) "Customer Discount Group"
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
        /// Specifies the currency that the line discount is valid for. A blank value indicates the local currency.
        /// </summary>
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code of the sales line discount price.';
            TableRelation = Currency;
        }
        /// <summary>
        /// Specifies the date from which the line discount is valid.
        /// </summary>
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date from which the sales line discount is valid.';

            trigger OnValidate()
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
                    Error(Text000, FieldCaption("Starting Date"), FieldCaption("Ending Date"));

                if CurrFieldNo = 0 then
                    exit;
                if "Sales Type" = "Sales Type"::Campaign then
                    Error(Text003, FieldCaption("Starting Date"), FieldCaption("Ending Date"), FieldCaption("Sales Type"), "Sales Type");
            end;
        }
        /// <summary>
        /// Specifies the discount percentage to apply to the sales line.
        /// </summary>
        field(5; "Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Line Discount %';
            ToolTip = 'Specifies the discount percentage to use to calculate the sales line discount.';
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the type of sales target for the discount, such as customer, customer discount group, all customers, or campaign.
        /// </summary>
        field(13; "Sales Type"; Option)
        {
            Caption = 'Sales Type';
            ToolTip = 'Specifies the sales type of the sales line discount. The sales type defines whether the sales price is for an individual customer, customer discount group, all customers, or for a campaign.';
            OptionCaption = 'Customer,Customer Disc. Group,All Customers,Campaign';
            OptionMembers = Customer,"Customer Disc. Group","All Customers",Campaign;

            trigger OnValidate()
            begin
                if "Sales Type" <> xRec."Sales Type" then
                    Validate("Sales Code", '');
            end;
        }
        /// <summary>
        /// Specifies the minimum quantity that must be ordered to qualify for the line discount.
        /// </summary>
        field(14; "Minimum Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Minimum Quantity';
            ToolTip = 'Specifies the minimum quantity that the customer must purchase in order to gain the agreed discount.';
            MinValue = 0;
        }
        /// <summary>
        /// Specifies the last date on which the line discount is valid.
        /// </summary>
        field(15; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Specifies the date to which the sales line discount is valid.';

            trigger OnValidate()
            begin
                Validate("Starting Date");

                if CurrFieldNo = 0 then
                    exit;
                if "Sales Type" = "Sales Type"::Campaign then
                    Error(Text003, FieldCaption("Starting Date"), FieldCaption("Ending Date"), FieldCaption("Sales Type"), "Sales Type");
            end;
        }
        /// <summary>
        /// Specifies whether the line discount applies to an item or an item discount group.
        /// </summary>
        field(21; Type; Enum "Sales Line Discount Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of item that the sales discount line is valid for. That is, either an item or an item discount group.';

            trigger OnValidate()
            begin
                if xRec.Type <> Type then
                    Validate(Code, '');
            end;
        }
        /// <summary>
        /// Specifies the unit of measure that the line discount applies to for the item.
        /// </summary>
        field(5400; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field(Code));
        }
        /// <summary>
        /// Specifies the item variant that the line discount applies to.
        /// </summary>
        field(5700; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field(Code));

            trigger OnValidate()
            begin
                TestField(Type, Type::Item);
            end;
        }
    }

    keys
    {
        key(Key1; Type, "Code", "Sales Type", "Sales Code", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
            Clustered = true;
        }
        key(Key2; "Sales Type", "Sales Code", Type, "Code", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Sales Type", "Sales Code", "Line Discount %", Type, "Code", "Starting Date", "Ending Date")
        {
        }
    }

    trigger OnInsert()
    begin
        if "Sales Type" = "Sales Type"::"All Customers" then
            "Sales Code" := ''
        else
            TestField("Sales Code");
        TestField(Code);
    end;

    trigger OnRename()
    begin
        if "Sales Type" <> "Sales Type"::"All Customers" then
            TestField("Sales Code");
        TestField(Code);
    end;

    var
        Campaign: Record Campaign;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cannot be after %2';
        Text001: Label '%1 must be blank.';
        Text003: Label 'You can only change the %1 and %2 from the Campaign Card when %3 = %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074

}
