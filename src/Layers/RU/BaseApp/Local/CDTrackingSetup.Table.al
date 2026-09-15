#pragma warning disable AA0247
#if not CLEANSCHEMA28 
table 12410 "CD Tracking Setup"
{
    Caption = 'CD Tracking Setup';
    ObsoleteReason = 'Moved to CD Tracking extension table CD Number Header.';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item Tracking Code"; Code[10])
        {
            Caption = 'Item Tracking Code';
            NotBlank = true;
            TableRelation = "Item Tracking Code";
        }
        field(2; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location;
        }
        field(3; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(21; "CD Info. Must Exist"; Boolean)
        {
            Caption = 'CD Info. Must Exist';
        }
        field(23; "CD Sales Check on Release"; Boolean)
        {
            Caption = 'CD Sales Check on Release';
        }
        field(24; "CD Purchase Check on Release"; Boolean)
        {
            Caption = 'CD Purchase Check on Release';
        }
        field(25; "Allow Temporary CD No."; Boolean)
        {
            Caption = 'Allow Temporary CD No.';
        }
    }

    keys
    {
        key(Key1; "Item Tracking Code", "Location Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif