#pragma warning disable AA0247
table 26568 "Statutory Report Buffer"
{
    Caption = 'Statutory Report Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Table Code"; Code[20])
        {
            Caption = 'Table Code';
            DataClassification = SystemMetadata;
        }
        field(4; "Excel Sheet Name"; Text[30])
        {
            Caption = 'Excel Sheet Name';
            DataClassification = SystemMetadata;
        }
        field(6; "Parent Excel Sheet Name"; Text[30])
        {
            Caption = 'Parent Excel Sheet Name';
            DataClassification = SystemMetadata;
        }
        field(7; "Section Excel Cell Name"; Code[10])
        {
            Caption = 'Section Excel Cell Name';
            DataClassification = SystemMetadata;
        }
        field(8; Separator; Boolean)
        {
            Caption = 'Separator';
            DataClassification = SystemMetadata;
        }
        field(9; "Section No."; Code[10])
        {
            Caption = 'Section No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
            DataClassification = SystemMetadata;
        }
        field(11; "Table Sequence No."; Integer)
        {
            Caption = 'Table Sequence No.';
            DataClassification = SystemMetadata;
        }
        field(12; "New Page"; Boolean)
        {
            Caption = 'New Page';
            DataClassification = SystemMetadata;
        }
        field(13; "Group End"; Boolean)
        {
            Caption = 'Group End';
            DataClassification = SystemMetadata;
        }
        field(14; "Fragment End"; Boolean)
        {
            Caption = 'Fragment End';
            DataClassification = SystemMetadata;
        }
        field(15; "Page Indic. Requisite Value"; Text[100])
        {
            Caption = 'Page Indic. Requisite Value';
            DataClassification = SystemMetadata;
        }
        field(16; "Scalable Table Row No."; Integer)
        {
            Caption = 'Scalable Table Row No.';
            DataClassification = SystemMetadata;
        }
        field(17; "Report Data No."; Code[20])
        {
            Caption = 'Report Data No.';
            DataClassification = SystemMetadata;
        }
        field(18; Value; Text[150])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;
        }
        field(19; "XML Element Line No."; Integer)
        {
            Caption = 'XML Element Line No.';
            DataClassification = SystemMetadata;
        }
        field(20; "Calculation Values Mode"; Boolean)
        {
            Caption = 'Calculation Values Mode';
            DataClassification = SystemMetadata;
        }
        field(21; "Excel Cell Name"; Code[10])
        {
            Caption = 'Excel Cell Name';
            DataClassification = SystemMetadata;
        }
        field(22; "Template Data"; Boolean)
        {
            Caption = 'Template Data';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Excel Sheet Name", "Table Code")
        {
        }
        key(Key3; "Section No.", "Sequence No.", "Table Sequence No.")
        {
        }
    }

    fieldgroups
    {
    }
}
