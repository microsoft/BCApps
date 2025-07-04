namespace Microsoft.EServices.EDocumentConnector.ForNAV;
table 6411 "Fornav Peppol Role"
{
    DataClassification = SystemMetadata;
    Caption = 'ForNAV Peppol Roles';
    Access = Internal;

    fields
    {
        field(1; "Role"; Code[20])
        {
            Caption = 'Role';
            ToolTip = 'Specifies the roles that you have on the ForNAV Peppol network.';
        }
    }

    keys
    {
        key(Key1; Role)
        {
            Clustered = true;
        }
    }
}