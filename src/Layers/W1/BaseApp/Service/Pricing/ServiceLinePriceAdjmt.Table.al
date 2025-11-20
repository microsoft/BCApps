// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;
using Microsoft.Service.Item;

table 6084 "Service Line Price Adjmt."
{
    Caption = 'Service Line Price Adjmt.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Service Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Service Line No."; Integer)
        {
            Caption = 'Service Line No.';
        }
        field(4; "Service Item Line No."; Integer)
        {
            Caption = 'Service Item Line No.';
        }
        field(5; "Service Item No."; Code[20])
        {
            Caption = 'Service Item No.';
            TableRelation = "Service Item";
        }
        field(6; "Serv. Price Adjmt. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Price Adjmt. Gr. Code';
            TableRelation = "Service Price Adjustment Group";
        }
        field(7; Type; Enum "Service Line Type")
        {
            Caption = 'Type';
            Editable = false;
        }
        field(8; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const(Cost)) "Service Cost";
        }
        field(9; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            Editable = false;
        }
        field(14; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        field(15; "New Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 1;
            Caption = 'New Amount';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                GetServHeader();

                IsHandled := false;
                OnValidateNewAmountOnAfterGetServHeader(Rec, Currency, ServHeader, IsHandled);
                if IsHandled then
                    exit;

                "New Unit Price" :=
                  Round(("New Amount" * 100 / (100 - "Discount %")) / Quantity, Currency."Unit-Amount Rounding Precision");
                if ServHeader."Prices Including VAT" then
                    "New Amount incl. VAT" := "New Amount"
                else
                    "New Amount incl. VAT" := Round("New Amount" + "New Amount" * "Vat %" / 100, Currency."Amount Rounding Precision");
                "Discount Amount" :=
                  Round("New Unit Price" * Quantity * "Discount %" / 100, Currency."Amount Rounding Precision");
                "New Amount Excl. VAT" := Round("New Amount incl. VAT" / (1 + "Vat %" / 100), Currency."Amount Rounding Precision");
            end;
        }
        field(16; "Unit Price"; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 2;
            Caption = 'Unit Price';
            Editable = false;
        }
        field(17; "New Unit Price"; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 2;
            Caption = 'New Unit Price';

            trigger OnValidate()
            begin
                GetServHeader();
                "Discount Amount" :=
                  Round("New Unit Price" * Quantity * "Discount %" / 100, Currency."Amount Rounding Precision");
                "New Amount" := Round("New Unit Price" * Quantity - "Discount Amount", Currency."Amount Rounding Precision");
                if ServHeader."Prices Including VAT" then
                    "New Amount incl. VAT" := "New Amount"
                else
                    "New Amount incl. VAT" := Round("New Amount" + "New Amount" * "Vat %" / 100, Currency."Amount Rounding Precision");
                "New Amount Excl. VAT" := Round("New Amount incl. VAT" / (1 + "Vat %" / 100), Currency."Amount Rounding Precision");
            end;
        }
        field(18; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            Editable = false;
        }
        field(19; "Discount %"; Decimal)
        {
            Caption = 'Discount %';
            Editable = false;
        }
        field(20; "Discount Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 1;
            Caption = 'Discount Amount';
            Editable = false;
        }
        field(21; "Amount incl. VAT"; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 1;
            Caption = 'Amount incl. VAT';
            Editable = false;
        }
        field(22; "New Amount incl. VAT"; Decimal)
        {
            AutoFormatExpression = GetCurrency();
            AutoFormatType = 1;
            Caption = 'New Amount incl. VAT';

            trigger OnValidate()
            begin
                GetServHeader();
                if ServHeader."Prices Including VAT" then
                    "New Amount" := "New Amount incl. VAT"
                else
                    "New Amount" := Round("New Amount incl. VAT" / (1 + "Vat %" / 100), Currency."Amount Rounding Precision");
                "New Unit Price" :=
                  Round(("New Amount" * 100 / (100 - "Discount %")) / Quantity, Currency."Unit-Amount Rounding Precision");
                "Discount Amount" :=
                  Round("New Unit Price" * Quantity * "Discount %" / 100, Currency."Amount Rounding Precision");
                "New Amount Excl. VAT" := Round("New Amount incl. VAT" / (1 + "Vat %" / 100), Currency."Amount Rounding Precision");
            end;
        }
        field(24; Weight; Decimal)
        {
            Caption = 'Weight';
            Editable = false;
        }
        field(25; "Adjustment Type"; Option)
        {
            Caption = 'Adjustment Type';
            Editable = false;
            OptionCaption = 'Fixed,Maximum,Minimum';
            OptionMembers = "Fixed",Maximum,Minimum;
        }
        field(26; "Service Price Group Code"; Code[10])
        {
            Caption = 'Service Price Group Code';
            Editable = false;
            TableRelation = "Service Price Group";
        }
        field(27; "Manually Adjusted"; Boolean)
        {
            Caption = 'Manually Adjusted';
            Editable = false;
        }
        field(28; "Vat %"; Decimal)
        {
            Caption = 'Vat %';
            Editable = false;
        }
        field(29; "New Amount Excl. VAT"; Decimal)
        {
            Caption = 'New Amount Excl. VAT';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.", "Service Item Line No.", "Service Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        "Manually Adjusted" := true;
    end;

    var
        ServHeader: Record "Service Header";
        Currency: Record Currency;

    local procedure GetServHeader()
    begin
        if ("Document Type" <> ServHeader."Document Type") or
           ("Document No." <> ServHeader."No.")
        then begin
            ServHeader.Get(Rec."Document Type", Rec."Document No.");
            if ServHeader."Currency Code" = '' then
                Currency.InitRoundingPrecision()
            else begin
                ServHeader.TestField("Currency Factor");
                Currency.Get(ServHeader."Currency Code");
                Currency.TestField("Amount Rounding Precision");
            end;
        end;
    end;

    local procedure GetCurrency(): Code[10]
    begin
        GetServHeader();
        exit(ServHeader."Currency Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNewAmountOnAfterGetServHeader(var ServiceLinePriceAdjmt: Record "Service Line Price Adjmt."; Currency: Record Currency; ServHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
}

