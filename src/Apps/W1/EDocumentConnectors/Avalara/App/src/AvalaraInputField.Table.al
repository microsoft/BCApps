namespace Microsoft.EServices.EDocumentConnector.Avalara;

table 6374 "Avalara Input Field"
{
    Caption = 'Input Field';
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    fields
    {
        field(1; FieldId; Integer)
        {
            Caption = 'Field ID';
        }
        field(2; DocumentType; Text[30])
        {
            Caption = 'Document Type';
        }
        field(3; DocumentVersion; Text[30])
        {
            Caption = 'Document Version';
        }
        field(4; Path; Text[256])
        {
            Caption = 'Path';
        }
        field(5; PathType; Text[20])
        {
            Caption = 'Path Type';
        }
        field(6; FieldName; Text[50])
        {
            Caption = 'Field Name';
        }
        field(7; NamespacePrefix; Text[20])
        {
            Caption = 'Namespace Prefix';
        }
        field(8; NamespaceValue; Text[512])
        {
            Caption = 'Namespace Value';
        }
        field(9; ExampleOrFixedValue; Text[256])
        {
            Caption = 'Example Or Fixed Value';
        }
        field(10; AcceptedValues; Text[256])
        {
            Caption = 'Accepted Values';
        }
        field(11; DocumentationLink; Text[160])
        {
            Caption = 'Documentation Link';
        }
        field(12; DataType; Text[40])
        {
            Caption = 'Data Type';
        }
        field(13; Description; Text[256])
        {
            Caption = 'Description';
        }
        field(14; Optionality; Text[30])
        {
            Caption = 'Optionality';
        }
        field(15; Cardinality; Text[30])
        {
            Caption = 'Cardinality';
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
        key(PK; FieldId, Mandate, DocumentType, DocumentVersion)
        {
            Clustered = true;
        }
        key(PathIdx; Path) { }
    }
}