table 101904 "Temporary Currency Data"
{
    Caption = 'Temporary Currency Data';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(2; "Local Precision Factor"; Decimal)
        {
            Caption = 'Local Precision Factor';
            DecimalPlaces = 2 : 5;
            AutoFormatType = 0;
        }
        field(3; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
            DecimalPlaces = 2 : 5;
            AutoFormatType = 0;
        }
        field(4; "Unit-Amount Rounding Precision"; Decimal)
        {
            Caption = 'Unit-Amount Rounding Precision';
            DecimalPlaces = 0 : 9;
            AutoFormatType = 0;
        }
        field(5; "Invoice Rounding Precision"; Decimal)
        {
            Caption = 'Invoice Rounding Precision';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(6; "Invoice Rounding Type"; Option)
        {
            Caption = 'Invoice Rounding Type';
            OptionCaption = 'Nearest,Up,Down';
            OptionMembers = Nearest,Up,Down;
        }
        field(7; "Exchange Rate Amount"; Integer)
        {
            Caption = 'Exchange Rate Amount';
        }
        field(8; "Relational Exch. Rate Amount"; Decimal)
        {
            Caption = 'Relational Exch. Rate Amount';
            DecimalPlaces = 1 : 6;
            AutoFormatType = 0;
        }
        field(9; "EMU Currency"; Boolean)
        {
            Caption = 'EMU Currency';
        }
        field(10; "Amount Decimal Places"; Text[5])
        {
            Caption = 'Amount Decimal Places';
        }
        field(11; "Unit-Amount Decimal Places"; Text[5])
        {
            Caption = 'Unit-Amount Decimal Places';
        }
        field(12; "ISO Numeric Code"; Code[3])
        {
            Caption = 'ISO Numeric Code';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Currency Code")
        {
            MaintainSIFTIndex = false;
        }
    }

    fieldgroups
    {
    }
}
