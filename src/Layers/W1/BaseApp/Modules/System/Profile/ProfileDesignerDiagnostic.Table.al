namespace System.Environment.Configuration;

using System.Tooling;

table 9197 "Profile Designer Diagnostic"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Import ID"; Guid)
        {
            Caption = 'Import ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Diagnostics ID"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Diagnostics ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Profile App ID"; Guid)
        {
            Caption = 'Application ID';
            DataClassification = CustomerContent;
        }
        field(4; "Profile ID"; Code[30])
        {
            Caption = 'Profile ID';
            DataClassification = CustomerContent;
        }
        field(5; Severity; Enum Severity)
        {
            Caption = 'Severity';
            DataClassification = SystemMetadata;
        }
        field(6; Message; Text[2048])
        {
            Caption = 'Message';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Import ID", "Diagnostics ID")
        {
            Clustered = true;
        }
    }

}