#if not CLEANSCHEMA28
#pragma warning disable AA0247
table 12459 "Direct Transfer Line"
{
    Caption = 'Direct Transfer Line';
    LookupPageID = "Posted Transfer Receipt Lines";
    ObsoleteState = Removed;
    ObsoleteReason = 'Direct Transfer feature merge to W1.';
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(4; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(5; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(9; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(10; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(12; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(15; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(16; "Gross Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Net Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Unit Volume"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(22; "Units per Parcel"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(23; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(24; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            TableRelation = "Transfer Header";
            ValidateTableRelation = false;
        }
        field(25; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(29; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            Editable = false;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(30; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            Editable = false;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(31; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
        }
        field(33; "Item Rcpt. Entry No."; Integer)
        {
            Caption = 'Item Rcpt. Entry No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            TableRelation = "Dimension Set Entry";
        }
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
#if not CLEANSCHEMA28
        field(5707; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            ObsoleteReason = 'Product Groups became first level children of Item Categories.';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
        }
#endif
        field(7300; "Transfer-from Bin Code"; Code[20])
        {
            Caption = 'Transfer-from Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Transfer-from Code"),
                                            "Item Filter" = field("Item No."),
                                            "Variant Filter" = field("Variant Code"));
        }
        field(7301; "Transfer-To Bin Code"; Code[20])
        {
            Caption = 'Transfer-To Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Transfer-to Code"),
                                            "Item Filter" = field("Item No."),
                                            "Variant Filter" = field("Variant Code"));
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Transfer Order No.", "Item No.", "Posting Date")
        {
        }
    }
}
#endif