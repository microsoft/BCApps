table 6374 "AvalaraInput Field"
{
    Caption = 'Input Field';
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    fields
    {
        field(1; fieldId; Integer)
        {
            Caption = 'Field ID';
        }
        field(2; documentType; Text[30])
        {
            Caption = 'Document Type';
        }
        field(3; documentVersion; Text[30])
        {
            Caption = 'Document Version';
        }
        field(4; path; Text[256])
        {
            Caption = 'Path';
        }
        field(5; pathType; Text[20])
        {
            Caption = 'Path Type';
        }
        field(6; fieldName; Text[50])
        {
            Caption = 'Field Name';
        }
        field(7; namespace_prefix; Text[20])
        {
            Caption = 'Namespace prefix';
        }
        field(8; namespace_value; Text[512])
        {
            Caption = 'name space Value';
        }
        field(9; exampleOrFixedValue; Text[256])
        {
            Caption = 'Example Or FixedValue';
        }
        field(10; acceptedValues; Text[256])
        {
            Caption = 'Accepted Values';
        }
        field(11; DocumentationLink; Text[160])
        {
            Caption = 'Documentation Link';
        }
        field(12; dataType; Text[40])
        {
            Caption = 'Data Type';
        }
        field(13; Description; Text[256])
        {
            Caption = 'Description';
        }
        field(14; optionality; Text[30])
        {
            Caption = 'optionality';
        }
        field(15; cardinality; Text[30])
        {
            Caption = 'optionality';
        }
        field(16; "Data Exch. Line Def Code"; Text[20])
        {
            Caption = 'DED Line';
        }
        field(17; DEDColumnNo; Integer)
        {
            Caption = 'Column No.';
        }
        field(18; "Data Exch. Def Code"; Code[20])
        {
            Caption = 'Data Exch. Def Code';
        }
        field(19; Mandate; Code[40])
        {
            Caption = 'Mandate';
        }
    }

    keys
    {
        key(PK; fieldId, Mandate, documentType, documentVersion)
        {
            Clustered = true;
        }
        key(PathIdx; path) { }
    }
}