table 103322 "WMS Reservation Entry Ref"
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
        field(5; "Reservation Status"; Option)
        {
            OptionMembers = Reservation,Tracking,Surplus,Prospect;
        }
        field(7; Description; Text[50])
        {
        }
        field(8; "Creation Date"; Date)
        {
        }
        field(9; "Transferred from Entry No."; Integer)
        {
            TableRelation = "Reservation Entry";
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
            Editable = false;
            TableRelation = "Item Ledger Entry";
        }
        field(22; "Expected Receipt Date"; Date)
        {
        }
        field(23; "Shipment Date"; Date)
        {
        }
        field(24; "Serial No."; Code[50])
        {
        }
        field(25; "Created By"; Code[20])
        {
        }
        field(27; "Changed By"; Code[20])
        {
        }
        field(28; Positive; Boolean)
        {
            Editable = false;
        }
        field(29; "Qty. per Unit of Measure"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(30; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(31; "Action Message Adjustment"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(32; Binding; Option)
        {
            Editable = false;
            OptionMembers = " ","Order-to-Order";
        }
        field(33; "Suppressed Action Msg."; Boolean)
        {
        }
        field(34; "Planning Flexibility"; Option)
        {
            OptionMembers = Unlimited,"None";
        }
        field(40; "Warranty Date"; Date)
        {
            Editable = false;
        }
        field(41; "Expiration Date"; Date)
        {
            Editable = false;
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
        field(53; "Quantity Invoiced (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(55; "Reserved Pick & Ship Qty."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(80; "New Serial No."; Code[50])
        {
            Editable = false;
        }
        field(81; "New Lot No."; Code[50])
        {
            Editable = false;
        }
        field(5400; "Lot No."; Code[50])
        {
        }
        field(5401; "Variant Code"; Code[10])
        {
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5817; Correction; Boolean)
        {
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
        key(Key1; "Project Code", "Use Case No.", "Test Case No.", "Iteration No.", "Entry No.", Positive)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
