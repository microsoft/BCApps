table 103331 "BW Warehouse Journal Line Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    DrillDownPageID = "Warehouse Journal Lines";
    LookupPageID = "Warehouse Journal Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            TableRelation = "Warehouse Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            TableRelation = "Warehouse Journal Batch".Name where("Journal Template Name" = FIELD("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
        }
        field(4; "Registering Date"; Date)
        {
        }
        field(5; "Location Code"; Code[10])
        {
            TableRelation = Location;
        }
        field(6; "From Zone Code"; Code[10])
        {
            TableRelation = Zone.Code where("Location Code" = FIELD("Location Code"));
        }
        field(7; "From Bin Code"; Code[20])
        {
            TableRelation = if ("Phys. Inventory" = const(false),
                                "Item No." = FILTER(''),
                                "From Zone Code" = FILTER('')) "Bin Content"."Bin Code" where("Location Code" = FIELD("Location Code"))
            else
            if ("Phys. Inventory" = const(false),
                                         "Item No." = FILTER(<> ''),
                                         "From Zone Code" = FILTER('')) "Bin Content"."Bin Code" where("Location Code" = FIELD("Location Code"),
                                                                                                      "Item No." = FIELD("Item No."))
            else
            if ("Phys. Inventory" = const(false),
                                                                                                               "Item No." = FILTER(''),
                                                                                                               "From Zone Code" = FILTER(<> '')) "Bin Content"."Bin Code" where("Location Code" = FIELD("Location Code"),
                                                                                                                                                                              "Zone Code" = FIELD("From Zone Code"))
            else
            if ("Phys. Inventory" = const(false),
                                                                                                                                                                                       "Item No." = FILTER(<> ''),
                                                                                                                                                                                       "From Zone Code" = FILTER(<> '')) "Bin Content"."Bin Code" where("Location Code" = FIELD("Location Code"),
                                                                                                                                                                                                                                                      "Item No." = FIELD("Item No."),
                                                                                                                                                                                                                                                      "Zone Code" = FIELD("From Zone Code"))
            else
            if ("Phys. Inventory" = const(true),
                                                                                                                                                                                                                                                               "From Zone Code" = FILTER('')) Bin.Code where("Location Code" = FIELD("Location Code"))
            else
            if ("Phys. Inventory" = const(true),
                                                                                                                                                                                                                                                                        "From Zone Code" = FILTER(<> '')) Bin.Code where("Location Code" = FIELD("Location Code"),
                                                                                                                                                                                                                                                                                                                       "Zone Code" = FIELD("From Zone Code"));
        }
        field(8; Description; Text[50])
        {
        }
        field(9; "Item No."; Code[20])
        {
            TableRelation = Item;
        }
        field(10; Quantity; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(11; "Qty. (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(12; "Qty. (Absolute)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(13; "Qty. (Absolute, Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(14; "Zone Code"; Code[10])
        {
            TableRelation = Zone.Code where("Location Code" = FIELD("Location Code"));
        }
        field(15; "Bin Code"; Code[20])
        {
            TableRelation = if ("Zone Code" = FILTER('')) Bin.Code where("Location Code" = FIELD("Location Code"))
            else
            if ("Zone Code" = FILTER(<> '')) Bin.Code where("Location Code" = FIELD("Location Code"),
                                                                               "Zone Code" = FIELD("Zone Code"));
        }
        field(20; "Source Type"; Integer)
        {
            Editable = false;
        }
        field(21; "Source Subtype"; Option)
        {
            Editable = false;
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(22; "Source No."; Code[20])
        {
            Editable = false;
        }
        field(23; "Source Line No."; Integer)
        {
            BlankZero = true;
            Editable = false;
        }
        field(24; "Source Subline No."; Integer)
        {
            BlankZero = true;
            Editable = false;
        }
        field(25; "Source Document"; Option)
        {
            BlankZero = true;
            Editable = false;
            OptionMembers = ,"S. Order","S. Invoice","S. Credit Memo","S. Return Order","P. Order","P. Invoice","P. Credit Memo","P. Return Order","Inb. Transfer","Outb. Transfer","Prod. Consumption","Item Jnl.","Phys. Invt. Jnl.","Reclass. Jnl.","Consumption Jnl.","Output Jnl.";
        }
        field(26; "Source Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Source Code";
        }
        field(27; "To Zone Code"; Code[10])
        {
            TableRelation = Zone.Code where("Location Code" = FIELD("Location Code"));
        }
        field(28; "To Bin Code"; Code[20])
        {
            TableRelation = if ("To Zone Code" = FILTER('')) Bin.Code where("Location Code" = FIELD("Location Code"))
            else
            if ("To Zone Code" = FILTER(<> '')) Bin.Code where("Location Code" = FIELD("Location Code"),
                                                                                  "Zone Code" = FIELD("To Zone Code"));
        }
        field(29; "Reason Code"; Code[10])
        {
            TableRelation = "Reason Code";
        }
        field(33; "Registering No. Series"; Code[20])
        {
            TableRelation = "No. Series";
        }
        field(35; "From Bin Type Code"; Code[10])
        {
            TableRelation = "Bin Type";
        }
        field(40; Cubage; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(41; Weight; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(50; "Whse. Document No."; Code[20])
        {
        }
        field(51; "Whse. Document Type"; Option)
        {
            OptionMembers = "Whse. Journal",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Whse. Phys. Inventory"," ";
        }
        field(52; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
        }
        field(53; "Qty. (Calculated)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(54; "Qty. (Phys. Inventory)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(55; "Entry Type"; Option)
        {
            OptionMembers = "Negative Adjmt.","Positive Adjmt.",Movement;
        }
        field(56; "Phys. Inventory"; Boolean)
        {
            Editable = false;
        }
        field(60; "Reference Document"; Option)
        {
            OptionMembers = " ","Posted Rcpt.","Posted P. Inv.","Posted Rtrn. Rcpt.","Posted P. Cr. Memo","Posted Shipment","Posted S. Inv.","Posted Rtrn. Shipment","Posted S. Cr. Memo","Posted T. Receipt","Posted T. Shipment","Item Journal","Prod.","Put-away",Pick,Movement;
        }
        field(61; "Reference No."; Code[20])
        {
        }
        field(67; "User ID"; Code[20])
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
            TableRelation = "Item Unit of Measure".Code where("Item No." = FIELD("Item No."));
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
            Editable = false;
        }
        field(6503; "Expiration Date"; Date)
        {
            Editable = false;
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            Editable = false;
            OptionMembers = " ",Item,SKU;
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
        key(Key1; "Use Case No.", "Test Case No.", "Iteration No.", "Journal Template Name", "Journal Batch Name", "Location Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
