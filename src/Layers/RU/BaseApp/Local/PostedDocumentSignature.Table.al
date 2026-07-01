#pragma warning disable AA0247
table 12421 "Posted Document Signature"
{
    Caption = 'Posted Document Signature';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = '0,1,2,3,4';
            OptionMembers = "0","1","2","3","4";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Employee Type"; Option)
        {
            Caption = 'Employee Type';
            OptionCaption = 'Director,Accountant,Cashier,Responsible,ReleasedBy,ReceivedBy,PassedBy,RequestedBy,Chairman,Member1,Member2,Member3,StoredBy';
            OptionMembers = Director,Accountant,Cashier,Responsible,ReleasedBy,ReceivedBy,PassedBy,RequestedBy,Chairman,Member1,Member2,Member3,StoredBy;
        }
        field(5; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;
        }
        field(6; "Employee Name"; Text[100])
        {
            Caption = 'Employee Name';
        }
        field(7; "Employee Job Title"; Text[50])
        {
            Caption = 'Employee Job Title';
        }
        field(8; "Employee Org. Unit"; Text[50])
        {
            Caption = 'Employee Org. Unit';
        }
        field(9; "Warrant Description"; Text[30])
        {
            Caption = 'Warrant Description';
        }
        field(10; "Warrant No."; Text[20])
        {
            Caption = 'Warrant No.';
        }
        field(11; "Warrant Date"; Date)
        {
            Caption = 'Warrant Date';
        }
    }

    keys
    {
        key(Key1; "Table ID", "Document Type", "Document No.", "Employee Type")
        {
            Clustered = true;
        }
        key(Key2; "Employee Type", "Employee No.")
        {
        }
    }

    fieldgroups
    {
    }
}

