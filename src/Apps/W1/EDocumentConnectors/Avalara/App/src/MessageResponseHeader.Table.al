namespace Microsoft.EServices.EDocumentConnector.Avalara;

table 6379 "Message Response Header"
{
    Caption = 'Message Response Header';
    DataClassification = OrganizationIdentifiableInformation;

    fields
    {
        field(1; Id; Text[50])
        {
            Caption = 'Id';
        }
        field(2; CompanyId; Text[50])
        {
            Caption = 'Company Id';
        }
        field(3; Status; Text[20])
        {
            Caption = 'Status';
        }
    }
    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}
