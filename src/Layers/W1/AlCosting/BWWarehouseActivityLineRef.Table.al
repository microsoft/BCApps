table 103335 "BW Warehouse Activity Line Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DrillDownPageID = "Warehouse Activity Lines";
    LookupPageID = "Warehouse Activity Lines";
    PasteIsValid = false;
    Permissions = TableData "Whse. Item Tracking Line" = rm;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Activity Type"; Option)
        {
            Editable = false;
            OptionMembers = " ","Put-away",Pick,Movement;
        }
        field(2; "No."; Code[20])
        {
            Editable = false;
        }
        field(3; "Line No."; Integer)
        {
            Editable = false;
        }
        field(4; "Source Type"; Integer)
        {
            Editable = false;
        }
        field(5; "Source Subtype"; Option)
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
            BlankZero = true;
            Editable = false;
        }
        field(8; "Source Subline No."; Integer)
        {
            BlankZero = true;
            Editable = false;
        }
        field(9; "Source Document"; Option)
        {
            BlankZero = true;
            Editable = false;
            OptionMembers = ,"Sales Order",,,"Sales Return Order","Purchase Order",,,"Purchase Return Order","Inbound Transfer","Outbound Transfer","Prod. Consumption";
        }
        field(11; "Location Code"; Code[10])
        {
            Editable = false;
            TableRelation = Location;
        }
        field(12; "Shelf/Bin No."; Code[10])
        {
        }
        field(13; "Sorting Sequence No."; Integer)
        {
            Editable = false;
        }
        field(14; "Item No."; Code[20])
        {
            Editable = false;
            TableRelation = Item;
        }
        field(15; "Variant Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = FIELD("Item No."));
        }
        field(16; "Unit of Measure Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = FIELD("Item No."));
        }
        field(17; "Qty. per Unit of Measure"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
            AutoFormatType = 0;
        }
        field(18; Description; Text[50])
        {
            Editable = false;
        }
        field(19; "Description 2"; Text[50])
        {
            Editable = false;
        }
        field(20; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(21; "Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(24; "Qty. Outstanding"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(25; "Qty. Outstanding (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(26; "Qty. to Handle"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(27; "Qty. to Handle (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(28; "Qty. Handled"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(29; "Qty. Handled (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(31; "Shipping Advice"; Option)
        {
            Editable = false;
            FieldClass = Normal;
            OptionMembers = Partial,Complete;
        }
        field(34; "Due Date"; Date)
        {
        }
        field(39; "Destination Type"; Option)
        {
            Editable = false;
            OptionMembers = " ",Customer,Vendor,Location;
        }
        field(40; "Destination No."; Code[20])
        {
            Editable = false;
            TableRelation = if ("Destination Type" = const(Customer)) Customer."No."
            else
            if ("Destination Type" = const(Vendor)) Vendor."No."
            else
            if ("Destination Type" = const(Location)) Location.Code;
        }
        field(42; "Shipping Agent Code"; Code[10])
        {
            TableRelation = "Shipping Agent";
        }
        field(43; "Shipping Agent Service Code"; Code[10])
        {
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = FIELD("Shipping Agent Code"));
        }
        field(44; "Shipment Method Code"; Code[10])
        {
            TableRelation = "Shipment Method";
        }
        field(47; "Starting Date"; Date)
        {
        }
        field(6500; "Serial No."; Code[50])
        {
        }
        field(6501; "Lot No."; Code[50])
        {
        }
        field(6502; "Warranty Date"; Date)
        {
        }
        field(6503; "Expiration Date"; Date)
        {
        }
        field(7300; "Bin Code"; Code[20])
        {
            TableRelation = if ("Action Type" = FILTER(<> Take),
                                "Zone Code" = FILTER(<> '')) Bin.Code where("Location Code" = FIELD("Location Code"),
                                                                          "Zone Code" = FIELD("Zone Code"))
            else
            if ("Action Type" = FILTER(<> Take),
                                                                                   "Zone Code" = FILTER('')) Bin.Code where("Location Code" = FIELD("Location Code"))
            else
            if ("Action Type" = FILTER(Take),
                                                                                            "Zone Code" = FILTER(<> '')) "Bin Content"."Bin Code" where("Location Code" = FIELD("Location Code"),
                                                                                                                                                      "Item No." = FIELD("Item No."),
                                                                                                                                                      "Variant Code" = FIELD("Variant Code"),
                                                                                                                                                      "Zone Code" = FIELD("Zone Code"))
            else
            if ("Action Type" = FILTER(Take),
                                                                                                                                                               "Zone Code" = FILTER('')) "Bin Content"."Bin Code" where("Location Code" = FIELD("Location Code"),
                                                                                                                                                                                                                       "Item No." = FIELD("Item No."),
                                                                                                                                                                                                                       "Variant Code" = FIELD("Variant Code"));

        }
        field(7301; "Zone Code"; Code[10])
        {
            TableRelation = Zone.Code where("Location Code" = FIELD("Location Code"));
        }
        field(7305; "Action Type"; Option)
        {
            Editable = false;
            OptionMembers = " ",Take,Place;
        }
        field(7306; "Whse. Document Type"; Option)
        {
            Editable = false;
            OptionMembers = " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Movement Worksheet";
        }
        field(7307; "Whse. Document No."; Code[20])
        {
            Editable = false;
            TableRelation = if ("Whse. Document Type" = const(Receipt)) "Posted Whse. Receipt Header"."No." where("No." = FIELD("Whse. Document No."))
            else
            if ("Whse. Document Type" = const(Shipment)) "Warehouse Shipment Header"."No." where("No." = FIELD("Whse. Document No."))
            else
            if ("Whse. Document Type" = const("Internal Put-away")) "Whse. Internal Put-away Header"."No." where("No." = FIELD("Whse. Document No."))
            else
            if ("Whse. Document Type" = const("Internal Pick")) "Whse. Internal Pick Header"."No." where("No." = FIELD("Whse. Document No."))
            else
            if ("Whse. Document Type" = const(Production)) "Production Order"."No." where("No." = FIELD("Whse. Document No."));
        }
        field(7308; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
            Editable = false;
            TableRelation = if ("Whse. Document Type" = const(Receipt)) "Posted Whse. Receipt Line"."Line No." where("No." = FIELD("Whse. Document No."),
                                                                                                                    "Line No." = FIELD("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const(Shipment)) "Warehouse Shipment Line"."Line No." where("No." = FIELD("Whse. Document No."),
                                                                                                                                                                                                                "Line No." = FIELD("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const("Internal Put-away")) "Whse. Internal Put-away Line"."Line No." where("No." = FIELD("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                            "Line No." = FIELD("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const("Internal Pick")) "Whse. Internal Pick Line"."Line No." where("No." = FIELD("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                                                                                                                                "Line No." = FIELD("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const(Production)) "Prod. Order Line"."Line No." where("Prod. Order No." = FIELD("No."),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       "Line No." = FIELD("Line No."));
        }
        field(7309; "Bin Ranking"; Integer)
        {
            Editable = false;
        }
        field(7310; Cubage; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(7311; Weight; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(7312; "Special Equipment Code"; Code[10])
        {
            TableRelation = "Special Equipment";
        }
        field(7313; "Bin Type Code"; Code[10])
        {
            TableRelation = "Bin Type";
        }
        field(7314; "Breakbulk No."; Integer)
        {
            BlankZero = true;
        }
        field(7315; "Original Breakbulk"; Boolean)
        {
        }
        field(7316; Breakbulk; Boolean)
        {
        }
        field(7317; "Cross-Dock Information"; Option)
        {
            OptionMembers = " ","Cross-Dock Items","Some Items Cross-Docked";
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
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "Activity Type", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
