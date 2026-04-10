namespace System.Integration;

table 1738 "OData Initialized Status"
{
    Access = Internal;
    DataPerCompany = false;
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; Id; Guid)
        {
        }
        field(2; "Initialized version"; Text[250])
        {
        }
    }
}