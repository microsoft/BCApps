namespace Microsoft.EServices.EDocumentConnector.Avalara;
table 6380 "Message Event"
{
    Caption = 'Message Event';
    DataClassification = OrganizationIdentifiableInformation;
    fields
    {
        field(1; Id; Text[50])
        {
            Caption = 'Id';
        }
        field(2; MessageRow; Integer)
        {
            Caption = 'Row';
        }
        field(3; EventDateTime; DateTime)
        {
            Caption = 'Event Date Time';
        }
        field(4; Message; Text[256])
        {
            Caption = 'Message';
        }
        field(5; ResponseKey; Text[256])
        {
            Caption = 'Response Key';
        }
        field(6; ResponseValue; Text[256])
        {
            Caption = 'Response Value';
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
        key(PK; Id, MessageRow)
        {
            Clustered = true;
        }
    }
}
