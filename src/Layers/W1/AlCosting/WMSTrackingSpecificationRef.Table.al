table 103323 "WMS Tracking Specification Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
        }
        field(2; "Item No."; Code[20])
        {
            TableRelation = Item;
        }
        field(3; "Location Code"; Code[10])
        {
            TableRelation = Location;
        }
        field(4; "Quantity (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(7; Description; Text[50])
        {
        }
        field(8; "Creation Date"; Date)
        {
        }
        field(10; "Source Type"; Integer)
        {
        }
        field(11; "Source Subtype"; Option)
        {
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(12; "Source ID"; Code[20])
        {
        }
        field(13; "Source Batch Name"; Code[10])
        {
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
        }
        field(15; "Source Ref. No."; Integer)
        {
        }
        field(16; "Appl.-to Item Entry"; Integer)
        {
            TableRelation = "Item Ledger Entry";
        }
        field(17; "Transfer Item Entry No."; Integer)
        {
            TableRelation = "Item Ledger Entry";
        }
        field(24; "Serial No."; Code[50])
        {
        }
        field(28; Positive; Boolean)
        {
        }
        field(29; "Qty. per Unit of Measure"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(40; "Warranty Date"; Date)
        {
        }
        field(41; "Expiration Date"; Date)
        {
        }
        field(50; "Qty. to Handle (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(51; "Qty. to Invoice (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(52; "Quantity Handled (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(53; "Quantity Invoiced (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(60; "Qty. to Handle"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(61; "Qty. to Invoice"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(70; "Buffer Status"; Option)
        {
            Editable = false;
            OptionMembers = " ",MODIFY;
        }
        field(80; "New Serial No."; Code[50])
        {
        }
        field(81; "New Lot No."; Code[50])
        {
        }
        field(5400; "Lot No."; Code[50])
        {
        }
        field(5401; "Variant Code"; Code[10])
        {
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5402; "Bin Code"; Code[20])
        {
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5817; Correction; Boolean)
        {
        }
        field(7300; "Quantity actual Handled (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(103200; "Project Code"; Code[10])
        {
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
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
