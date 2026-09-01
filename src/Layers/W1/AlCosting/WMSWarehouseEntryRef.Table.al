table 103310 "WMS Warehouse Entry Ref"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution

    Caption = 'Warehouse Entry Ref';
    DrillDownPageID = "Warehouse Entries";
    LookupPageID = "Warehouse Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(3; "Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Line No.';
        }
        field(4; "Registering Date"; Date)
        {
            Caption = 'Registering Date';
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
        }
        field(6; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
        }
        field(7; "Bin Code"; Code[20])
        {
        }
        field(8; Description; Text[50])
        {
        }
        field(9; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(11; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(20; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(21; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(22; "Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        field(23; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
        }
        field(24; "Source Subline No."; Integer)
        {
            Caption = 'Source Subline No.';
        }
        field(25; "Source Document"; Option)
        {
            Caption = 'Source Document';
            OptionCaption = ',Sales Order,Sales Invoice,Sales Credit Memo,Sales Return Order,Purchase Order,Purchase Invoice,Purchase Credit Memo,Purchase Return Order,Inbound Transfer,Outbound Transfer,Prod. Consumption,Item Journal,Phys. Invt. Journal,Reclass. Journal,Consumption Journal,Output Journal';
            OptionMembers = ,"Sales Order","Sales Invoice","Sales Credit Memo","Sales Return Order","Purchase Order","Purchase Invoice","Purchase Credit Memo","Purchase Return Order","Inbound Transfer","Outbound Transfer","Prod. Consumption","Item Journal","Phys. Invt. Journal","Reclass. Journal","Consumption Journal","Output Journal";
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(29; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(33; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(35; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            TableRelation = "Bin Type";
        }
        field(40; Cubage; Decimal)
        {
            Caption = 'Cubage';
            AutoFormatType = 0;
        }
        field(41; Weight; Decimal)
        {
            Caption = 'Weight';
            AutoFormatType = 0;
        }
        field(45; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(50; "Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
        }
        field(51; "Whse. Document Type"; Option)
        {
            Caption = 'Whse. Document Type';
            OptionCaption = 'Whse. Journal,Receipt,Shipment,Internal Put-away,Internal Pick,Production,Whse. Phys. Inventory, ';
            OptionMembers = "Whse. Journal",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Whse. Phys. Inventory"," ";
        }
        field(52; "Whse. Document Line No."; Integer)
        {
            Caption = 'Whse. Document Line No.';
        }
        field(55; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Negative Adjmt.,Positive Adjmt.,Movement';
            OptionMembers = "Negative Adjmt.","Positive Adjmt.",Movement;
        }
        field(60; "Reference Document"; Option)
        {
            Caption = 'Posted Source Document';
            OptionCaption = ' ,Posted Receipt,Posted Purchase Invoice,Posted Return Receipt,Posted Purchase Credit Memo,Posted Shipment,Posted Sales Invoice,Posted Return Shipment,Posted Sales Credit Memo,Posted Transfer Receipt,Posted Transfer Shipment';
            OptionMembers = " ","Posted Receipt","Posted Purchase Invoice","Posted Return Receipt","Posted Purchase Credit Memo","Posted Shipment","Posted Sales Invoice","Posted Return Shipment","Posted Sales Credit Memo","Posted Transfer Receipt","Posted Transfer Shipment";
        }
        field(61; "Reference No."; Code[20])
        {
            Caption = 'Posted Source No.';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
            AutoFormatType = 0;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(6500; "Serial No."; Code[50])
        {
        }
        field(6501; "Lot No."; Code[50])
        {
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            Editable = false;
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            Caption = 'Phys Invt Counting Period Type';
            Editable = false;
            OptionCaption = ' ,Item,SKU';
            OptionMembers = " ",Item,SKU;
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
        key(Key1; "Project Code", "Use Case No.", "Test Case No.", "Iteration No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
