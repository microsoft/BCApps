table 103343 "BW P. Invt. Put-away Line Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DrillDownPageID = "Warehouse Activity Lines";
    LookupPageID = "Warehouse Activity Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "No."; Code[20])
        {
        }
        field(3; "Line No."; Integer)
        {
        }
        field(4; "Source Type"; Integer)
        {
        }
        field(5; "Source Subtype"; Option)
        {
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
        }
        field(7; "Source Line No."; Integer)
        {
            BlankZero = true;
        }
        field(8; "Source Subline No."; Integer)
        {
            BlankZero = true;
        }
        field(9; "Source Document"; Option)
        {
            BlankZero = true;
            OptionMembers = ,"Sales Order",,,"Sales Return Order","Purchase Order",,,"Purchase Return Order","Inbound Transfer","Outbound Transfer","Prod. Consumption","Prod. Output";
        }
        field(11; "Location Code"; Code[10])
        {
            TableRelation = Location;
        }
        field(12; "Shelf No."; Code[10])
        {
        }
        field(13; "Sorting Sequence No."; Integer)
        {
        }
        field(14; "Item No."; Code[20])
        {
            TableRelation = Item;
        }
        field(15; "Variant Code"; Code[10])
        {
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(16; "Unit of Measure Code"; Code[10])
        {
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(17; "Qty. per Unit of Measure"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            AutoFormatType = 0;
        }
        field(18; Description; Text[50])
        {
        }
        field(19; "Description 2"; Text[50])
        {
        }
        field(20; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(21; "Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(31; "Shipping Advice"; Option)
        {
            OptionMembers = Partial,Complete;
        }
        field(34; "Due Date"; Date)
        {
        }
        field(39; "Destination Type"; Option)
        {
            OptionMembers = " ",Customer,Vendor,Location;
        }
        field(40; "Destination No."; Code[20])
        {
            TableRelation = if ("Destination Type" = const(Customer)) Customer."No."
            else
            if ("Destination Type" = const(Vendor)) Vendor."No."
            else
            if ("Destination Type" = const(Location)) Location.Code;
        }
        field(41; "Whse. Activity No."; Code[20])
        {
        }
        field(42; "Shipping Agent Code"; Code[10])
        {
            TableRelation = "Shipping Agent";
        }
        field(43; "Shipping Agent Service Code"; Code[10])
        {
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
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
            TableRelation = if ("Action Type" = filter(<> Take)) Bin.Code where("Location Code" = field("Location Code"),
                                                                              "Zone Code" = field("Zone Code"))
            else
            if ("Action Type" = filter(<> Take),
                                                                                       "Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Action Type" = const(Take)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                                           "Zone Code" = field("Zone Code"))
            else
            if ("Action Type" = const(Take),
                                                                                                                                                                    "Zone Code" = filter('')) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"));
        }
        field(7301; "Zone Code"; Code[10])
        {
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(7305; "Action Type"; Option)
        {
            Editable = false;
            OptionMembers = " ",Take,Place;
        }
        field(7312; "Special Equipment Code"; Code[10])
        {
            TableRelation = "Special Equipment";
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
