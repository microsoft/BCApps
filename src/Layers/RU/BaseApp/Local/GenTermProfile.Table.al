#pragma warning disable AA0247
table 17238 "Gen. Term Profile"
{
    Caption = 'Gen. Term Profile';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; "Section Code (Hdr)"; Integer)
        {
            Caption = 'Section Code (Hdr)';
        }
        field(3; "Term Code (Hdr)"; Integer)
        {
            Caption = 'Term Code (Hdr)';
        }
        field(4; "Expression Type (Hdr)"; Integer)
        {
            Caption = 'Expression Type (Hdr)';
        }
        field(5; "Expression (Hdr)"; Integer)
        {
            Caption = 'Expression (Hdr)';
        }
        field(6; "Description (Hdr)"; Integer)
        {
            Caption = 'Description (Hdr)';
        }
        field(7; "Check (Hdr)"; Integer)
        {
            Caption = 'Check (Hdr)';
        }
        field(8; "Process Sign (Hdr)"; Integer)
        {
            Caption = 'Process Sign (Hdr)';
        }
        field(9; "Rounding Precision (Hdr)"; Integer)
        {
            Caption = 'Rounding Precision (Hdr)';
        }
        field(10; "Date Filter (Hdr)"; Integer)
        {
            Caption = 'Date Filter (Hdr)';
        }
        field(11; "Section Code (Line)"; Integer)
        {
            Caption = 'Section Code (Line)';
        }
        field(12; "Term Code (Line)"; Integer)
        {
            Caption = 'Term Code (Line)';
        }
        field(13; "Line No. (Line)"; Integer)
        {
            Caption = 'Line No. (Line)';
        }
        field(14; "Expression Type (Line)"; Integer)
        {
            Caption = 'Expression Type (Line)';
        }
        field(15; "Operation (Line)"; Integer)
        {
            Caption = 'Operation (Line)';
        }
        field(16; "Account Type (Line)"; Integer)
        {
            Caption = 'Account Type (Line)';
        }
        field(17; "Account No. (Line)"; Integer)
        {
            Caption = 'Account No. (Line)';
        }
        field(18; "Amount Type (Line)"; Integer)
        {
            Caption = 'Amount Type (Line)';
        }
        field(19; "Bal. Account No. (Line)"; Integer)
        {
            Caption = 'Bal. Account No. (Line)';
        }
        field(20; "Norm Jurisd. Code (Line)"; Integer)
        {
            Caption = 'Norm Jurisd. Code (Line)';
        }
        field(21; "Process Sign (Line)"; Integer)
        {
            Caption = 'Process Sign (Line)';
        }
        field(22; "Process Division by Zero(Line)"; Integer)
        {
            Caption = 'Process Division by Zero(Line)';
        }
    }

    keys
    {
        key(Key1; "Table No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

