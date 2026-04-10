#pragma warning disable AA0247
table 17237 "Gen. Template Profile"
{
    Caption = 'Gen. Template Profile';
    LookupPageID = "Tax Register Templates";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Template Line Table No."; Integer)
        {
            Caption = 'Template Line Table No.';
        }
        field(2; "Template Header Table No."; Integer)
        {
            Caption = 'Template Header Table No.';
        }
        field(3; "Term Header Table No."; Integer)
        {
            Caption = 'Term Header Table No.';
        }
        field(4; "Term Line Table No."; Integer)
        {
            Caption = 'Term Line Table No.';
        }
        field(5; "Dim. Filter Table No."; Integer)
        {
            Caption = 'Dim. Filter Table No.';
        }
        field(6; "Section Code (Hdr)"; Integer)
        {
            Caption = 'Section Code (Hdr)';
        }
        field(7; "Code (Hdr)"; Integer)
        {
            Caption = 'Code (Hdr)';
        }
        field(8; "Check (Hdr)"; Integer)
        {
            Caption = 'Check (Hdr)';
        }
        field(9; "Level (Hdr)"; Integer)
        {
            Caption = 'Level (Hdr)';
        }
        field(10; "Section Code"; Integer)
        {
            Caption = 'Section Code';
        }
        field(11; "Code"; Integer)
        {
            Caption = 'Code';
        }
        field(12; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(13; "Expression Type"; Integer)
        {
            Caption = 'Expression Type';
        }
        field(14; Expression; Integer)
        {
            Caption = 'Expression';
        }
        field(15; "Line Code (Line)"; Integer)
        {
            Caption = 'Line Code (Line)';
        }
        field(16; "Norm Jurisd. Code (Line)"; Integer)
        {
            Caption = 'Norm Jurisd. Code (Line)';
        }
        field(17; "Link Code"; Integer)
        {
            Caption = 'Link Code';
        }
        field(18; "Date Filter"; Integer)
        {
            Caption = 'Date Filter';
        }
        field(19; Period; Integer)
        {
            Caption = 'Period';
        }
        field(20; Description; Integer)
        {
            Caption = 'Description';
        }
        field(21; "Rounding Precision"; Integer)
        {
            Caption = 'Rounding Precision';
        }
        field(22; "Storing Method (Hdr)"; Integer)
        {
            Caption = 'Storing Method (Hdr)';
        }
        field(23; "Header Code (Link)"; Integer)
        {
            Caption = 'Header Code (Link)';
        }
        field(24; "Line Code (Link)"; Integer)
        {
            Caption = 'Line Code (Link)';
        }
        field(25; "Value (Link)"; Integer)
        {
            Caption = 'Value (Link)';
        }
        field(26; "Section Code (Dim)"; Integer)
        {
            Caption = 'Section Code (Dim)';
            NotBlank = true;
        }
        field(27; "Tax Register No. (Dim)"; Integer)
        {
            Caption = 'Tax Register No. (Dim)';
            NotBlank = true;
        }
        field(28; "Define (Dim)"; Integer)
        {
            Caption = 'Define (Dim)';
        }
        field(29; "Line No. (Dim)"; Integer)
        {
            Caption = 'Line No. (Dim)';
        }
        field(30; "Dimension Code (Dim)"; Integer)
        {
            Caption = 'Dimension Code (Dim)';
            NotBlank = true;
        }
        field(31; "Dimension Value Filter (Dim)"; Integer)
        {
            Caption = 'Dimension Value Filter (Dim)';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "Template Line Table No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

