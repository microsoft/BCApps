table 103313 "WMS Whse. Activity Line Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'Warehouse Activity Line Ref';
    DrillDownPageID = "Warehouse Activity Lines";
    LookupPageID = "Warehouse Activity Lines";
    PasteIsValid = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Activity Type"; Enum "Warehouse Activity Type")
        {
            Caption = 'Activity Type';
            Editable = false;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(4; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(5; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        field(7; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(8; "Source Subline No."; Integer)
        {
            Caption = 'Source Subline No.';
            Editable = false;
        }
        field(9; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            Caption = 'Source Document';
            Editable = false;
        }
        field(11; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(12; "Shelf/Bin No."; Code[10])
        {
            Caption = 'Shelf/Bin No.';
        }
        field(13; "Sorting Sequence No."; Integer)
        {
            Caption = 'Sorting Sequence No.';
            Editable = false;
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(15; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(16; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(17; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
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
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(21; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(24; "Qty. Outstanding"; Decimal)
        {
            Caption = 'Qty. Outstanding';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(25; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(26; "Qty. to Handle"; Decimal)
        {
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(27; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(28; "Qty. Handled"; Decimal)
        {
            Caption = 'Qty. Handled';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(29; "Qty. Handled (Base)"; Decimal)
        {
            Caption = 'Qty. Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(31; "Shipping Advice"; Option)
        {
            Caption = 'Shipping Advice';
            Editable = false;
            FieldClass = Normal;
            OptionCaption = 'Partial,Complete';
            OptionMembers = Partial,Complete;
        }
        field(34; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(39; "Destination Type"; Option)
        {
            Caption = 'Destination Type';
            Editable = false;
            OptionCaption = ' ,Customer,Vendor,Location';
            OptionMembers = " ",Customer,Vendor,Location;
        }
        field(40; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            Editable = false;
            TableRelation = if ("Destination Type" = const(Customer)) Customer."No."
            else
            if ("Destination Type" = const(Vendor)) Vendor."No."
            else
            if ("Destination Type" = const(Location)) Location.Code;
        }
        field(42; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(43; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(44; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(47; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
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
        }
        field(7301; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
        }
        field(7305; "Action Type"; Enum "Warehouse Action Type")
        {
            Caption = 'Action Type';
            Editable = false;
        }
        field(7306; "Whse. Document Type"; Enum "Warehouse Activity Document Type")
        {
            Caption = 'Whse. Document Type';
            Editable = true;
        }
        field(7307; "Whse. Document No."; Code[20])
        {
            Editable = true;
        }
        field(7308; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
            Editable = true;
        }
        field(7309; "Bin Ranking"; Integer)
        {
            Caption = 'Bin Ranking';
            Editable = false;
        }
        field(7310; Cubage; Decimal)
        {
            Caption = 'Cubage';
            AutoFormatType = 0;
        }
        field(7311; Weight; Decimal)
        {
            Caption = 'Weight';
            AutoFormatType = 0;
        }
        field(7312; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            TableRelation = "Special Equipment";
        }
        field(7313; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
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
        key(Key1; "Project Code", "Use Case No.", "Test Case No.", "Iteration No.", "Activity Type", "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
