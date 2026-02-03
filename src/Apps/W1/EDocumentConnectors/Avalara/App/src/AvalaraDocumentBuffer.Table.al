namespace Microsoft.EServices.EDocumentConnector.Avalara;

table 6378 "Avalara Document Buffer"
{
    Caption = 'Avalara Document Buffer';
    DataClassification = ToBeClassified;
    TableType = Temporary;

    fields
    {
        field(1; Id; Text[50])
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Company Id"; Text[50])
        {
            Caption = 'Company Id';
            DataClassification = SystemMetadata;
        }
        field(3; "Process DateTime"; DateTime)
        {
            Caption = 'Process DateTime';
        }
        field(4; Status; Text[30])
        {
            Caption = 'Status';
        }
        field(5; "Document Number"; Code[50])
        {
            Caption = 'Document Number';
        }
        field(6; "Document Type"; Text[40])
        {
            Caption = 'Document Type';
        }
        field(7; "Document Version"; Text[10])
        {
            Caption = 'Document Version';
        }
        field(8; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(9; Flow; Text[10])
        {
            Caption = 'Flow';
        } // "in" / "out"
        field(10; "Country Code"; Code[10])
        {
            Caption = 'Country Code';
        }
        field(11; "Country Mandate"; Code[40])
        {
            Caption = 'Country Mandate';
        }
        field(12; Receiver; Text[64])
        {
            Caption = 'Receiver';
        }
        field(13; "Supplier Name"; Text[100])
        {
            Caption = 'Supplier Name';
        }
        field(14; "Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(15; "Interface"; Text[30])
        {
            Caption = 'Interface';
        }
    }

    keys
    {
        key(PK; Id, "Process DateTime") { Clustered = true; }
    }
}
