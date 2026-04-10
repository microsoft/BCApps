namespace System.Environment.Configuration;

table 9171 "Profile Import"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "App ID"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Profile ID"; Code[30])
        {
            DataClassification = CustomerContent;
        }
        field(3; Exists; Boolean)
        {
            DataClassification = SystemMetadata;
        }
        field(4; Selected; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "App ID", "Profile ID")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if not IsTemporary() then
            error(DevMsgNotTemporaryErr);
    end;

    var
        DevMsgNotTemporaryErr: Label 'This table should only be used for temporary data.';

}
