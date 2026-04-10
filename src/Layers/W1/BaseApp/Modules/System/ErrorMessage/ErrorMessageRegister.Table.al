namespace System.Utilities;

using System.Security.AccessControl;

table 701 "Error Message Register"
{
    Caption = 'Error Message Register';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Created On"; DateTime)
        {
            Caption = 'Created On';
            DataClassification = SystemMetadata;
        }
        field(3; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
#if not CLEANSCHEMA25
        field(4; "Description"; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
            ObsoleteReason = 'Replaced by "Message"';
        }
#endif
        field(5; Errors; Integer)
        {
            CalcFormula = count("Error Message" where("Register ID" = field(ID),
                                                       "Message Type" = const(Error)));
            Caption = 'Errors';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; Warnings; Integer)
        {
            CalcFormula = count("Error Message" where("Register ID" = field(ID),
                                                       "Message Type" = const(Warning)));
            Caption = 'Warnings';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; Information; Integer)
        {
            CalcFormula = count("Error Message" where("Register ID" = field(ID),
                                                       "Message Type" = const(Information)));
            Caption = 'Information';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Message"; Text[2048])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Created On")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetRange("Register ID", ID);
        ErrorMessage.DeleteAll(true);
    end;

    procedure New(NewDescription: Text[250]): Guid
    begin
        Init();
        ID := CreateGuid();
        "Created On" := CurrentDateTime;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "Message" := NewDescription;
        Insert();
        exit(ID);
    end;
}

