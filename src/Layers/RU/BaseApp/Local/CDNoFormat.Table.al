#pragma warning disable AA0247
#if not CLEANSCHEMA28 
table 14917 "CD No. Format"
{
    Caption = 'CD No. Format';
    ObsoleteReason = 'Moved to CD Tracking extension table CD Number Header.';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; Format; Code[50])
        {
            Caption = 'Format';
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

}

 
#endif