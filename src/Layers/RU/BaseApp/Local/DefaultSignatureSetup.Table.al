#pragma warning disable AA0247
table 12428 "Default Signature Setup"
{
    Caption = 'Default Signature Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            begin
                if not
                   ("Table ID" in [
                                   DATABASE::"Sales Header", DATABASE::"Purchase Header", DATABASE::"Transfer Header",
                                   DATABASE::"Invt. Document Header", DATABASE::"FA Document Header"])
                then
                    Error(Text001, "Table ID");
            end;
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9";
        }
        field(4; "Employee Type"; Option)
        {
            Caption = 'Employee Type';
            OptionCaption = 'Director,Accountant,Cashier,ApprovedBy,ReleasedBy,ReceivedBy,PassedBy,RequestedBy,Chairman,Comm1,Comm2,Comm3,StoredBy';
            OptionMembers = Director,Accountant,Cashier,ApprovedBy,ReleasedBy,ReceivedBy,PassedBy,RequestedBy,Chairman,Comm1,Comm2,Comm3,StoredBy;
        }
        field(5; Mandatory; Boolean)
        {
            Caption = 'Mandatory';
            InitValue = true;
        }
        field(6; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;
        }
        field(7; "Warrant Description"; Text[30])
        {
            Caption = 'Warrant Description';
        }
        field(8; "Table Name"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table ID")));
            Caption = 'Table Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Warrant No."; Text[20])
        {
            Caption = 'Warrant No.';
        }
        field(10; "Warrant Date"; Date)
        {
            Caption = 'Warrant Date';
        }
    }

    keys
    {
        key(Key1; "Table ID", "Document Type", "Employee Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Table %1 is not supported.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

