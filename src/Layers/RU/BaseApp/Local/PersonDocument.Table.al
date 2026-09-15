#pragma warning disable AA0247
table 17352 "Person Document"
{
    Caption = 'Person Document';
    LookupPageID = "Person Documents";
    DataClassification = CustomerContent;

    fields
    {
#pragma warning disable AS0005
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;
        }
#pragma warning restore AS0005
        field(2; "Document Type"; Code[2])
        {
            Caption = 'Document Type';
            TableRelation = "Taxpayer Document Type";
        }
        field(3; "Valid from Date"; Date)
        {
            Caption = 'Valid from Date';
        }
        field(4; "Valid to Date"; Date)
        {
            Caption = 'Valid to Date';
        }
        field(5; "Document Series"; Text[10])
        {
            Caption = 'Document Series';
        }
        field(6; "Document No."; Text[30])
        {
            Caption = 'Document No.';
        }
        field(7; "Issue Authority"; Text[100])
        {
            Caption = 'Issue Authority';
        }
        field(8; "Issue Date"; Date)
        {
            Caption = 'Issue Date';
        }
    }

    keys
    {
        key(Key1; "Employee No.", "Document Type", "Valid from Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

