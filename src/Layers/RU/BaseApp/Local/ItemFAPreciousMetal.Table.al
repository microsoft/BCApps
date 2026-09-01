#pragma warning disable AA0247
table 12474 "Item/FA Precious Metal"
{
    Caption = 'Item/FA Precious Metal';
    DrillDownPageID = "Item/FA Precious Metal";
    LookupPageID = "Item/FA Precious Metal";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item Type"; Option)
        {
            Caption = 'Item Type';
            OptionCaption = 'Item,FA';
            OptionMembers = Item,FA;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Precious Metals Code"; Code[10])
        {
            Caption = 'Precious Metals Code';
            TableRelation = "Precious Metal";
        }
        field(4; Name; Text[100])
        {
            CalcFormula = lookup("Precious Metal".Name where(Code = field("Precious Metals Code")));
            Caption = 'Name';
            FieldClass = FlowField;
        }
        field(5; Kind; Text[30])
        {
            Caption = 'Kind';
        }
        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(7; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
        }
        field(8; "Nomenclature No."; Text[30])
        {
            Caption = 'Nomenclature No.';
        }
        field(9; "Document No."; Text[30])
        {
            Caption = 'Document No.';
        }
        field(10; Mass; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Mass';
        }
    }

    keys
    {
        key(Key1; "Item Type", "No.", "Precious Metals Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

