table 103338 "BW Posted Whse. Rcpt Line Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    LookupPageID = "Posted Whse. Receipt Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Editable = false;
        }
        field(3; "Source Type"; Integer)
        {
            Editable = false;
        }
        field(4; "Source Subtype"; Option)
        {
            Editable = false;
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Editable = false;
        }
        field(7; "Source Line No."; Integer)
        {
            Editable = false;
        }
        field(9; "Source Document"; Option)
        {
            Editable = false;
            OptionMembers = ,,,,"Sales Return Order","Purchase Order",,,,"Inbound Transfer";
        }
        field(10; "Location Code"; Code[10])
        {
            Editable = false;
            TableRelation = Location;
        }
        field(11; "Shelf/Bin No."; Code[10])
        {
        }
        field(12; "Bin Code"; Code[20])
        {
            TableRelation = if ("Zone Code" = FILTER('')) Bin.Code where("Location Code" = FIELD("Location Code"))
            else
            if ("Zone Code" = FILTER(<> '')) Bin.Code where("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));
        }
        field(13; "Zone Code"; Code[10])
        {
            TableRelation = Zone.Code where("Location Code" = FIELD("Location Code"));
        }
        field(14; "Item No."; Code[20])
        {
            Editable = false;
            TableRelation = Item;
        }
        field(15; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(16; "Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(25; "Qty. Put Away"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(26; "Qty. Put Away (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(27; "Put-away Qty."; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(28; "Put-away Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = FIELD("Item No."));
        }
        field(30; "Qty. per Unit of Measure"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
            AutoFormatType = 0;
        }
        field(31; "Variant Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = FIELD("Item No."));
        }
        field(32; Description; Text[50])
        {
            Editable = false;
        }
        field(33; "Description 2"; Text[50])
        {
            Editable = false;
        }
        field(36; "Due Date"; Date)
        {
        }
        field(37; "Starting Date"; Date)
        {
        }
        field(50; "Qty. Cross-Docked"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(51; "Qty. Cross-Docked (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(52; "Cross-Dock Zone Code"; Code[10])
        {
            TableRelation = Zone.Code where("Location Code" = FIELD("Location Code"));
        }
        field(53; "Cross-Dock Bin Code"; Code[20])
        {
            TableRelation = Bin.Code where("Location Code" = FIELD("Location Code"));
        }
        field(60; "Posted Source Document"; Option)
        {
            OptionMembers = " ","Posted Receipt",,"Posted Return Receipt",,,,,,"Posted Transfer Receipt";
        }
        field(61; "Posted Source No."; Code[20])
        {
        }
        field(62; "Posting Date"; Date)
        {
        }
        field(63; "Vendor Shipment No."; Code[20])
        {
        }
        field(64; "Whse. Receipt No."; Code[20])
        {
            Editable = false;
        }
        field(65; "Whse Receipt Line No."; Integer)
        {
            Editable = false;
        }
        field(66; Status; Option)
        {
            Editable = false;
            OptionMembers = " ","Partially Put Away","Completely Put Away";
        }
        field(6500; "Serial No."; Code[50])
        {
            Editable = false;
        }
        field(6501; "Lot No."; Code[50])
        {
            Editable = false;
        }
        field(6502; "Warranty Date"; Date)
        {
        }
        field(6503; "Expiration Date"; Date)
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
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
