table 103341 "BW Whse. Worksheet Line Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            NotBlank = true;
            TableRelation = "Whse. Worksheet Template";
        }
        field(2; Name; Code[10])
        {
            NotBlank = true;
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
        field(10; "Location Code"; Code[10])
        {
            Editable = false;
            TableRelation = Location;
        }
        field(11; "Shelf/Bin No."; Code[10])
        {
        }
        field(12; "From Zone Code"; Code[10])
        {
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(13; "From Bin Code"; Code[20])
        {
            TableRelation = if ("Item No." = filter(''),
                                "From Zone Code" = filter('')) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"))
            else
            if ("Item No." = filter(<> ''),
                                         "From Zone Code" = filter('')) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                      "Item No." = field("Item No."),
                                                                                                      "Variant Code" = field("Variant Code"))
            else
            if ("Item No." = filter(''),
                                                                                                               "From Zone Code" = filter(<> '')) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                                                              "Zone Code" = field("From Zone Code"))
            else
            if ("Item No." = filter(<> ''),
                                                                                                                                                                                       "From Zone Code" = filter(<> '')) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                                                                                                                                      "Item No." = field("Item No."),
                                                                                                                                                                                                                                                      "Variant Code" = field("Variant Code"),
                                                                                                                                                                                                                                                      "Zone Code" = field("From Zone Code"));
        }
        field(14; "To Bin Code"; Code[20])
        {
            TableRelation = if ("To Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"),
                                                                           Code = field("To Bin Code"))
            else
            if ("To Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                                                                                 "Zone Code" = field("To Zone Code"),
                                                                                                                                 Code = field("To Bin Code"));
        }
        field(15; "To Zone Code"; Code[10])
        {
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(16; "Item No."; Code[20])
        {
            TableRelation = Item;
        }
        field(17; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(18; "Qty. (Base)"; Decimal)
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
        field(21; "Qty. to Handle"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(22; "Qty. to Handle (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(23; "Qty. Handled"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(24; "Qty. Handled (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(27; "From Unit of Measure Code"; Code[10])
        {
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(28; "Qty. per From Unit of Measure"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
            AutoFormatType = 0;
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
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
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(32; Description; Text[50])
        {
        }
        field(33; "Description 2"; Text[50])
        {
        }
        field(35; "Sorting Sequence No."; Integer)
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
            TableRelation = if ("Destination Type" = const(Customer)) Customer."No."
            else
            if ("Destination Type" = const(Vendor)) Vendor."No."
            else
            if ("Destination Type" = const(Location)) Location.Code;
        }
        field(41; "Shipping Agent Code"; Code[10])
        {
            TableRelation = "Shipping Agent";
        }
        field(42; "Shipping Agent Service Code"; Code[10])
        {
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(43; "Shipment Method Code"; Code[10])
        {
            TableRelation = "Shipment Method";
        }
        field(44; "Shipping Advice"; Option)
        {
            Editable = false;
            OptionMembers = Partial,Complete;
        }
        field(45; "Shipment Date"; Date)
        {
        }
        field(46; "Whse. Document Type"; Option)
        {
            Editable = false;
            OptionMembers = " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Whse. Mov.-Worksheet";
        }
        field(47; "Whse. Document No."; Code[20])
        {
            Editable = false;
            TableRelation = if ("Whse. Document Type" = const(Receipt)) "Posted Whse. Receipt Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const(Shipment)) "Warehouse Shipment Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const("Internal Put-away")) "Whse. Internal Put-away Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const("Internal Pick")) "Whse. Internal Pick Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const(Production)) "Production Order"."No." where("No." = field("Whse. Document No."));
        }
        field(48; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
            Editable = false;
            TableRelation = if ("Whse. Document Type" = const(Receipt)) "Posted Whse. Receipt Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                                    "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const(Shipment)) "Warehouse Shipment Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                                                                                                                                "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const("Internal Put-away")) "Whse. Internal Put-away Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                            "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const("Internal Pick")) "Whse. Internal Pick Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                                                                                                                                "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const(Production)) "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       "Prod. Order No." = field("Whse. Document No."),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       "Line No." = field("Line No."));
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
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "Worksheet Template Name", Name, "Location Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
