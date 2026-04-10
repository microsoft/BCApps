namespace System.Threading;
using System.Security.AccessControl;

table 9067 "Job Queue Notified Admin"
{
    Caption = 'Job Queue Admin';
    DataClassification = CustomerContent;
    ReplicateData = false;
    Extensible = false;
    Access = Internal;

    fields
    {
        field(1; "User Name"; Code[50])
        {
            Caption = 'User Name';
            TableRelation = User."User Name" where("License Type" = filter(<> "External User" & <> "Application" & <> "AAD Group"));
            ValidateTableRelation = false;
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
        }
    }
}