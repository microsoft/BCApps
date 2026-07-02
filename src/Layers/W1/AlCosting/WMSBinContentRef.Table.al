table 103314 "WMS Bin Content Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'Bin Content Ref';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
        }
        field(2; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            NotBlank = true;
        }
        field(3; "Bin Code"; Code[20])
        {
            NotBlank = true;
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
        }
        field(10; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
        }
        field(11; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            Editable = false;
        }
        field(12; "Block Movement"; Option)
        {
            Caption = 'Block Movement';
            OptionCaption = ' ,Inbound,Outbound,All';
            OptionMembers = " ",Inbound,Outbound,All;
        }
        field(15; "Min. Qty."; Decimal)
        {
            Caption = 'Min. Qty.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(16; "Max. Qty."; Decimal)
        {
            Caption = 'Max. Qty.';
            DecimalPlaces = 0 : 5;
            MinValue = 1;
            AutoFormatType = 0;
        }
        field(21; "Bin Ranking"; Integer)
        {
            Caption = 'Bin Ranking';
        }
        field(26; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(29; "Pick Qty."; Decimal)
        {
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(30; "Neg. Adjmt. Qty."; Decimal)
        {
            Caption = 'Neg. Adjmt. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(31; "Put-away Qty."; Decimal)
        {
            Caption = 'Put-away Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(32; "Pos. Adjmt. Qty."; Decimal)
        {
            Caption = 'Pos. Adjmt. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(37; "Fixed"; Boolean)
        {
            Caption = 'Fixed';
            InitValue = true;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = true;
            InitValue = 1;
            AutoFormatType = 0;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            NotBlank = true;
        }
        field(103200; "Project Code"; Code[10])
        {
        }
        field(103201; "Use Case No."; Integer)
        {
        }
        field(103202; "Test Case No."; Integer)
        {
        }
        field(103204; "Iteration No."; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Project Code", "Use Case No.", "Test Case No.", "Iteration No.", "Location Code", "Zone Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
