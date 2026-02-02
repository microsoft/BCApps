table 6380 "Message Event"
{
    Caption = 'Message Event';
    DataClassification = ToBeClassified;
    fields
    {
        field(1; id; Text[50])
        {
            Caption = 'id';
        }
        field(2; MessageRow; Integer)
        {
            Caption = 'Row';
        }
        field(3; eventDateTime; DateTime)
        {
            Caption = 'eventDateTime';
        }
        field(4; message; Text[256])
        {
            Caption = 'message';
        }
        field(5; responseKey; Text[256])
        {
            Caption = 'responseKey';
        }
        field(6; responseValue; Text[256])
        {
            Caption = 'responseValue';
        }
        field(7; PostedDocument; Text[40])
        {
            Caption = 'Posted Document';
        }
        field(8; EDocEntryNo; Integer)
        {
            Caption = 'EDoc Entry No';
        }
    }
    keys
    {
        key(PK; id, MessageRow)
        {
            Clustered = true;
        }
    }
}
