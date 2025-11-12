table 103337 "BW Warehouse Receipt Line Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DrillDownPageID = "Whse. Receipt Lines";
    LookupPageID = "Whse. Receipt Lines";
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
        field(19; "Qty. Outstanding"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(20; "Qty. Outstanding (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(21; "Qty. to Receive"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(22; "Qty. to Receive (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(23; "Qty. Received"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(24; "Qty. Received (Base)"; Decimal)
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
        field(34; Status; Option)
        {
            Editable = false;
            OptionMembers = " ","Partially Received","Completely Received";
        }
        field(35; "Sorting Sequence No."; Integer)
        {
            Editable = false;
        }
        field(36; "Due Date"; Date)
        {
        }
        field(37; "Starting Date"; Date)
        {
        }
        field(38; Cubage; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(39; Weight; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(48; "Not upd. by Src. Doc. Post."; Boolean)
        {
            Editable = false;
        }
        field(49; "Posting from Whse. Ref."; Integer)
        {
            Editable = false;
        }
        field(50; "Qty. to Cross-Dock"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(51; "Qty. to Cross-Dock (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(52; "Cross-Dock Zone Code"; Code[10])
        {
            TableRelation = Zone.Code where("Location Code" = FIELD("Location Code"),
                                             "Cross-Dock Bin Zone" = const(true));
        }
        field(53; "Cross-Dock Bin Code"; Code[20])
        {
            TableRelation = if ("Cross-Dock Zone Code" = FILTER('')) Bin.Code where("Location Code" = FIELD("Location Code"),
                                                                                   "Cross-Dock Bin" = const(true))
            else
            if ("Cross-Dock Zone Code" = FILTER(<> '')) Bin.Code where("Location Code" = FIELD("Location Code"),
                                                                                                                                                 "Zone Code" = FIELD("Cross-Dock Zone Code"),
                                                                                                                                                 "Cross-Dock Bin" = const(true));
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
            MaintainSIFTIndex = false;
        }
    }

    fieldgroups
    {
    }
}
