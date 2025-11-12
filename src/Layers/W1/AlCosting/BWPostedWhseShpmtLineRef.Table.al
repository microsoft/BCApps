table 103340 "BW Posted Whse. Shpmt Line Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    LookupPageID = "Posted Whse. Shipment Lines";
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
            OptionMembers = ,"Sales Order",,,,,,,"Purchase Return Order",,"Outbound Transfer";
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
            TableRelation = if ("Zone Code" = FILTER('')) Bin.Code WHERE("Location Code" = FIELD("Location Code"))
            else if ("Zone Code" = FILTER(<> '')) Bin.Code WHERE("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));
        }
        field(13; "Zone Code"; Code[10])
        {
            TableRelation = Zone.Code WHERE("Location Code" = FIELD("Location Code"));
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
        field(29; "Unit of Measure Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));
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
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));
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
        field(39; "Destination Type"; Option)
        {
            Editable = false;
            OptionMembers = " ",Customer,Vendor,Location;
        }
        field(40; "Destination No."; Code[20])
        {
            Editable = false;
            TableRelation = if ("Destination Type" = CONST(Customer)) Customer."No."
            else if ("Destination Type" = CONST(Vendor)) Vendor."No."
            else if ("Destination Type" = CONST(Location)) Location.Code;
        }
        field(44; "Shipping Advice"; Option)
        {
            Editable = false;
            OptionMembers = Partial,Complete;
        }
        field(45; "Shipment Date"; Date)
        {
        }
        field(60; "Posted Source Document"; Option)
        {
            OptionMembers = " ",,,,,"Posted Shipment",,"Posted Return Shipment",,,"Posted Transfer Shipment";
        }
        field(61; "Posted Source No."; Code[20])
        {
        }
        field(62; "Posting Date"; Date)
        {
        }
        field(63; "Whse. Shipment No."; Code[20])
        {
            Editable = false;
        }
        field(64; "Whse Shipment Line No."; Integer)
        {
            Editable = false;
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
