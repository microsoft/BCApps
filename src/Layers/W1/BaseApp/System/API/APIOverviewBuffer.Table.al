namespace Microsoft.API;

table 812 "API Overview Buffer"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Name';
        }
        field(3; "Object Type"; Option)
        {
            Caption = 'Type';
            OptionMembers = ,Page,Query;
            OptionCaption = ' ,Page,Query';
        }
        field(4; "Object ID"; Integer)
        {
            Caption = 'ID';
            BlankZero = true;
        }
        field(5; "Entity Name"; Text[250])
        {
            Caption = 'Entity';
        }
        field(6; "API Publisher"; Text[40])
        {
            Caption = 'API Publisher';
        }
        field(7; "API Group"; Text[40])
        {
            Caption = 'API Group';
        }
        field(8; "API Version"; Text[250])
        {
            Caption = 'API Version';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "API Publisher", "API Group", Description)
        {
        }
    }
}
