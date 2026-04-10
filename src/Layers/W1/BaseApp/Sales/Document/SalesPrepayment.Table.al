// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;

/// <summary>
/// Stores prepayment percentage configurations by item and customer for sales orders.
/// </summary>
table 459 "Sales Prepayment %"
{
    Caption = 'Sales Prepayment %';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the item number for which the prepayment percentage applies.
        /// </summary>
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item for which the prepayment percentage is valid.';
            NotBlank = true;
            TableRelation = Item;
        }
        /// <summary>
        /// Specifies whether the prepayment percentage applies to a customer, customer price group, or all customers.
        /// </summary>
        field(2; "Sales Type"; Option)
        {
            Caption = 'Sales Type';
            ToolTip = 'Specifies the sales type of the prepayment percentage.';
            OptionCaption = 'Customer,Customer Price Group,All Customers';
            OptionMembers = Customer,"Customer Price Group","All Customers";

            trigger OnValidate()
            begin
                if "Sales Type" <> xRec."Sales Type" then
                    Validate("Sales Code", '');
            end;
        }
        /// <summary>
        /// Specifies the customer number or customer price group code for which the prepayment percentage applies.
        /// </summary>
        field(3; "Sales Code"; Code[20])
        {
            Caption = 'Sales Code';
            ToolTip = 'Specifies the code that belongs to the sales type.';
            TableRelation = if ("Sales Type" = const(Customer)) Customer
            else
            if ("Sales Type" = const("Customer Price Group")) "Customer Price Group";

            trigger OnValidate()
            begin
                if "Sales Code" = '' then
                    exit;

                if "Sales Type" = "Sales Type"::"All Customers" then
                    Error(Text001, FieldCaption("Sales Code"));
            end;
        }
        /// <summary>
        /// Specifies the date from which the prepayment percentage is valid.
        /// </summary>
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date from which the prepayment percentage is valid.';

            trigger OnValidate()
            begin
                CheckDate();
            end;
        }
        /// <summary>
        /// Specifies the date until which the prepayment percentage is valid.
        /// </summary>
        field(5; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Specifies the date to which the prepayment percentage is valid.';

            trigger OnValidate()
            begin
                CheckDate();
            end;
        }
        /// <summary>
        /// Specifies the prepayment percentage required for the item before delivery.
        /// </summary>
        field(6; "Prepayment %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Prepayment %';
            ToolTip = 'Specifies the prepayment percentage to use to calculate the prepayment for sales.';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Sales Type", "Sales Code", "Starting Date")
        {
            Clustered = true;
        }
        key(Key2; "Sales Type", "Sales Code")
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

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cannot be after %2.';
        Text001: Label '%1 must be blank.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CheckDate()
    begin
        if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
            Error(Text000, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
    end;
}
