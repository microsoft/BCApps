namespace System.Diagnostics;

using System.Email;
using System.Security.AccessControl;

table 1366 "Field Monitoring Setup"
{
    LookupPageId = "Field Monitoring Setup";
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            DataClassification = SystemMetadata;
        }
        field(2; "Monitor Status"; Boolean)
        {
            Caption = 'Monitor Status';
            DataClassification = SystemMetadata;
        }
        field(4; "Notification Count"; Integer)
        {
            // Contains the count of change entries since the last time the user opened the entries page.
            Caption = 'Notification Count';
            DataClassification = SystemMetadata;
        }
        field(5; "User Id"; Code[50])
        {
            Caption = 'Notification Recipient';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            NotBlank = true;

            trigger OnValidate()
            begin
                MonitorSensitiveField.CheckUserHasValidContactEmail("User Id");
            end;
        }
        field(7; "Email Account Id"; GUID)
        {
            DataClassification = SystemMetadata;
        }
        field(8; "Email Account Name"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Email Connector"; enum "Email Connector")
        {
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
    var
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
}