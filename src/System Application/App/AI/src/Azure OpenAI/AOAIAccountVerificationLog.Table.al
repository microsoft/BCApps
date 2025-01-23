namespace System.AI;

table 7767 "AOAI Account Verification Log"
{
    Access = Internal;
    Caption = 'AOAI Account Verification Log';
    DataPerCompany = false;
    Extensible = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = X;
    ReplicateData = false;

    fields
    {
        field(1; AccountName; Text[100])
        {
            Caption = 'Account Name';
            DataClassification = CustomerContent;
        }

        field(2; LastSuccessfulVerification; DateTime)
        {
            Caption = 'Access Verified';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PrimaryKey; AccountName)
        {
            Clustered = false;
        }
    }
}