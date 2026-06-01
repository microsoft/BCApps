namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Enums;

table 8020 "Sales Service Commitment Buff."
{
    DataClassification = CustomerContent;
    Caption = 'Sales Subscription Line Buffer';
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Rhythm Identifier"; Code[20])
        {
            Caption = 'Rhythm Identifier';
        }
        field(3; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(4; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(5; "Line Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Line Amount';
        }
        field(6; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(7; "VAT Base"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'VAT Base';
        }
        field(8; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'VAT Amount';
        }
        field(9; "Amount Including VAT"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            Caption = 'Amount Including VAT';
        }
        field(10; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            Editable = false;
            TableRelation = "Tax Group";
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
    internal procedure GetNextEntryNo(): Integer
    begin
        Reset();
        if FindLast() then
            exit("Entry No." + 1)
        else
            exit(1);
    end;
}
