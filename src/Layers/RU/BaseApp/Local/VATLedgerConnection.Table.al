#pragma warning disable AA0247
table 12406 "VAT Ledger Connection"
{
    Caption = 'VAT Ledger Connection';
    DrillDownPageID = "VAT Ledger Connection";
    LookupPageID = "VAT Ledger Connection";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Connection Type"; Option)
        {
            Caption = 'Connection Type';
            OptionCaption = 'Line,Purchase,Sales';
            OptionMembers = Line,Purchase,Sales;
        }
        field(2; "Sales Ledger Code"; Code[20])
        {
            Caption = 'Sales Ledger Code';
            TableRelation = "VAT Ledger".Code where(Type = const(Sales));
        }
        field(3; "Sales Ledger Line No."; Integer)
        {
            Caption = 'Sales Ledger Line No.';
            TableRelation = "VAT Ledger Line"."Line No." where(Type = const(Sales),
                                                                Code = field("Sales Ledger Code"));
        }
        field(4; "Purch. Ledger Code"; Code[20])
        {
            Caption = 'Purch. Ledger Code';
            TableRelation = "VAT Ledger".Code where(Type = const(Purchase));
        }
        field(5; "Purch. Ledger Line No."; Integer)
        {
            Caption = 'Purch. Ledger Line No.';
            TableRelation = "VAT Ledger Line"."Line No." where(Type = const(Purchase),
                                                                Code = field("Purch. Ledger Code"));
        }
        field(6; "VAT Entry No."; Integer)
        {
            Caption = 'VAT Entry No.';
#pragma warning disable AL0603
            TableRelation = "VAT Entry"."Entry No." where(Type = field("Connection Type"));
#pragma warning restore AL0603
        }
    }

    keys
    {
        key(Key1; "Connection Type", "Sales Ledger Code", "Sales Ledger Line No.", "Purch. Ledger Code", "Purch. Ledger Line No.", "VAT Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Connection Type", "Purch. Ledger Code", "Purch. Ledger Line No.", "Sales Ledger Code", "Sales Ledger Line No.")
        {
        }
        key(Key3; "Connection Type", "Sales Ledger Code", "Sales Ledger Line No.", "VAT Entry No.")
        {
        }
        key(Key4; "Connection Type", "Purch. Ledger Code", "Purch. Ledger Line No.", "VAT Entry No.")
        {
        }
    }

    fieldgroups
    {
    }
}

