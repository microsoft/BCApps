namespace System.AI;

table 7767 "AOAIAccountVerificationLog"
{
    Caption = 'AOAI Account Verification Log';
    Access = Internal;
    Extensible = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = X;
    DataPerCompany = false;
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