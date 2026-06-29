#pragma warning disable AA0247
#if not CLEANSCHEMA28 
table 12408 "CD No. Information"
{
    Caption = 'CD No. Information';
    DataCaptionFields = Type, "No.", "Variant Code", "CD No.", Description;
    ObsoleteReason = 'Replaced by Package No. Information and FA CD No. Information tables.';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const("Fixed Asset")) "Fixed Asset";
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("No."));
        }
        field(3; "CD No."; Code[50])
        {
            Caption = 'Package No.';
            NotBlank = true;

        }
        field(4; "CD Line No."; Integer)
        {
            Caption = 'CD Line No.';
            Description = 'Not used';
        }
        field(5; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(6; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Item,Fixed Asset';
            OptionMembers = Item,"Fixed Asset";
        }
        field(7; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
        }
#if not CLEANSCHEMA28
        field(9; "CD Header No."; Code[30])
        {
            Caption = 'CD Header No.';
            TableRelation = "CD No. Header";
            ObsoleteReason = 'CD No. Header has been moved to CD Tracking extension.';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
        }
#endif
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; "Temporary CD No."; Boolean)
        {
            Caption = 'Temporary CD No.';
        }
        field(12; "Certificate Number"; Code[20])
        {
            Caption = 'Certificate Number';
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(14; Comment; Boolean)
        {
            CalcFormula = exist("Item Tracking Comment" where(Type = const("Lot No."),
                                                               "Item No." = field("No."),
                                                               "Variant Code" = field("Variant Code"),
                                                               "Serial/Lot No." = field("CD No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Stockout Warning"; Boolean)
        {
            Caption = 'Stockout Warning';
            Description = 'Not used';
        }
        field(21; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(22; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(23; "Bin Filter"; Code[20])
        {
            Caption = 'Bin Filter';
            FieldClass = FlowFilter;
            TableRelation = Bin.Code where("Location Code" = field("Location Filter"));
        }
        field(30; Inventory; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."),
                                                                  "Variant Code" = field("Variant Code"),
                                                                  "Package No." = field("CD No."),
                                                                  "Location Code" = field("Location Filter")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Positive Adjmt."; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."),
                                                                  "Variant Code" = field("Variant Code"),
                                                                  "Package No." = field("CD No."),
                                                                  "Location Code" = field("Location Filter"),
                                                                  "Entry Type" = const("Positive Adjmt.")));
            Caption = 'Positive Adjmt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; Purchases; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("No."),
                                                                  "Variant Code" = field("Variant Code"),
                                                                  "Package No." = field("CD No."),
                                                                  "Location Code" = field("Location Filter"),
                                                                  "Entry Type" = const(Purchase)));
            Caption = 'Purchases';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Negative Adjmt."; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = - sum("Item Ledger Entry".Quantity where("Item No." = field("No."),
                                                                   "Variant Code" = field("Variant Code"),
                                                                   "Package No." = field("CD No."),
                                                                   "Location Code" = field("Location Filter"),
                                                                   "Entry Type" = const("Negative Adjmt.")));
            Caption = 'Negative Adjmt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; Sales; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = - sum("Item Ledger Entry".Quantity where("Item No." = field("No."),
                                                                   "Variant Code" = field("Variant Code"),
                                                                   "Package No." = field("CD No."),
                                                                   "Location Code" = field("Location Filter"),
                                                                   "Entry Type" = const(Sale)));
            Caption = 'Sales';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Current No."; Code[6])
        {
            Caption = 'Current No.';
            Description = 'Not used';
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Variant Code", "CD No.")
        {
            Clustered = true;
        }
        key(Key2; "CD No.")
        {
            Enabled = false;
        }
        key(Key3; "CD Header No.", "CD No.")
        {
        }
    }
}

#endif