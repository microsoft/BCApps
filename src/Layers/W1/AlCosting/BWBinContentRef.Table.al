table 103336 "BW Bin Content Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DrillDownPageID = "Bin Contents List";
    LookupPageID = "Bin Contents List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Editable = false;
            NotBlank = true;
            TableRelation = Location;
        }
        field(2; "Zone Code"; Code[10])
        {
            Editable = false;
            NotBlank = false;
            TableRelation = Zone.Code where("Location Code" = FIELD("Location Code"));
        }
        field(3; "Bin Code"; Code[20])
        {
            NotBlank = true;
            TableRelation = if ("Zone Code" = FILTER('')) Bin.Code where("Location Code" = FIELD("Location Code"))
            else
            IF ("Zone Code" = FILTER(<> '')) Bin.Code where("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));
        }
        field(4; "Item No."; Code[20])
        {
            NotBlank = true;
            TableRelation = Item;
        }
        field(10; "Bin Type Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Bin Type";
        }
        field(11; "Warehouse Class Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Warehouse Class";
        }
        field(12; "Block Movement"; Option)
        {
            OptionMembers = " ",Inbound,Outbound,All;
        }
        field(15; "Min. Qty."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(16; "Max. Qty."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(21; "Bin Ranking"; Integer)
        {
            Editable = false;
        }
        field(26; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = Normal;
            AutoFormatType = 0;
        }
        field(29; "Pick Qty."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = Normal;
            AutoFormatType = 0;
        }
        field(30; "Neg. Adjmt. Qty."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(31; "Put-away Qty."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(32; "Pos. Adjmt. Qty."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(37; "Fixed"; Boolean)
        {
        }
        field(40; "Cross-Dock Bin"; Boolean)
        {
        }
        field(5402; "Variant Code"; Code[10])
        {
            TableRelation = "Item Variant".Code where("Item No." = FIELD("Item No."));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
            AutoFormatType = 0;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code where("Item No." = FIELD("Item No."));
        }
        field(6500; "Lot No. Filter"; Code[20])
        {
            FieldClass = Normal;
        }
        field(6501; "Serial No. Filter"; Code[20])
        {
            FieldClass = Normal;
        }
        field(103231; "Use Case No."; Integer)
        {
        }
        field(103232; "Test Case No."; Integer)
        {
        }
        field(103233; "Iteration No."; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
