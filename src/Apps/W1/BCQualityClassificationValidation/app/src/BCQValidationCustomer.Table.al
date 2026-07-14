table 50100 "BCQ Validation Customer"
{
    Caption = 'BCQ Validation Customer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = CustomerContent;
        }
        field(2; "Full Name"; Text[100])
        {
            Caption = 'Full Name';
            // Personal PII left unreviewed.
            DataClassification = ToBeClassified;
        }
        field(3; "Email Address"; Text[80])
        {
            Caption = 'Email Address';
            // Real personal PII silenced by classifying it as platform metadata.
            DataClassification = SystemMetadata;
        }
        field(4; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            // Company VAT / registration number.
            DataClassification = ToBeClassified;
        }
        field(5; "IBAN"; Text[50])
        {
            Caption = 'IBAN';
            // Bank account / IBAN.
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
