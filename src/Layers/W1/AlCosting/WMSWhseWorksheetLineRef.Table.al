table 103320 "WMS Whse. Worksheet Line Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'Whse. Worksheet Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            NotBlank = true;
            TableRelation = "Whse. Worksheet Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(4; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
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
            Editable = false;
        }
        field(7; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            Editable = false;
        }
        field(8; "Source Subline No."; Integer)
        {
            Caption = 'Source Subline No.';
            Editable = false;
        }
        field(9; "Source Document"; Option)
        {
            Caption = 'Source Document';
            Editable = false;
            OptionCaption = ',Sales Order,,,,,,,Purchase Return Order,,Outbound Transfer,Prod. Consumption';
            OptionMembers = ,"Sales Order",,,,,,,"Purchase Return Order",,"Outbound Transfer","Prod. Consumption";
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(11; "Shelf/Bin No."; Code[10])
        {
            Caption = 'Shelf/Bin No.';
        }
        field(12; "From Zone Code"; Code[10])
        {
            Caption = 'From Zone Code';
        }
        field(13; "From Bin Code"; Code[20])
        {
        }
        field(14; "To Bin Code"; Code[20])
        {
        }
        field(15; "To Zone Code"; Code[10])
        {
            Caption = 'To Zone Code';
        }
        field(16; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(17; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(18; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(19; "Qty. Outstanding"; Decimal)
        {
            Caption = 'Qty. Outstanding';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(20; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(21; "Qty. to Handle"; Decimal)
        {
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(22; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(23; "Qty. Handled"; Decimal)
        {
            Caption = 'Qty. Handled';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(24; "Qty. Handled (Base)"; Decimal)
        {
            Caption = 'Qty. Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = true;
            AutoFormatType = 0;
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            NotBlank = true;
        }
        field(30; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
            AutoFormatType = 0;
        }
        field(31; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
        }
        field(32; Description; Text[50])
        {
        }
        field(33; "Description 2"; Text[50])
        {
        }
        field(35; "Sorting Sequence No."; Integer)
        {
            Caption = 'Sorting Sequence No.';
            Editable = false;
        }
        field(36; "Due Date"; Date)
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
        }
        field(41; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
        }
        field(42; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
        }
        field(43; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
        }
        field(44; "Shipping Advice"; Option)
        {
            Caption = 'Shipping Advice';
            Editable = false;
            OptionCaption = 'Partial,Complete';
            OptionMembers = Partial,Complete;
        }
        field(45; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(46; "Whse. Document Type"; Option)
        {
            Caption = 'Whse. Document Type';
            Editable = false;
            OptionCaption = ' ,Receipt,Shipment,Internal Put-away,Internal Pick,Production,Whse. Mov.-Worksheet';
            OptionMembers = " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Whse. Mov.-Worksheet";
        }
        field(47; "Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
            Editable = false;
        }
        field(48; "Whse. Document Line No."; Integer)
        {
            Caption = 'Whse. Document Line No.';
            Editable = false;
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
        key(Key1; "Project Code", "Use Case No.", "Test Case No.", "Iteration No.", "Worksheet Template Name", Name, "Location Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
