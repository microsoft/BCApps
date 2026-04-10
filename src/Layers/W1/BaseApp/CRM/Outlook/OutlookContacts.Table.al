namespace Microsoft.CRM.Outlook;

table 7122 "Outlook Contacts"
{
    Caption = 'O365 Contacts';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contact ID"; Text[250])
        {
            Caption = 'Contact ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Given Name"; Text[50])
        {
            Caption = 'Given Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(4; "Surname"; Text[50])
        {
            Caption = 'Surname';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(5; "Email Address"; Text[250])
        {
            Caption = 'Email Address';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(6; "Business Phone"; Text[30])
        {
            Caption = 'Business Phone';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(7; "Mobile Phone"; Text[30])
        {
            Caption = 'Mobile Phone';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Job Title"; Text[100])
        {
            Caption = 'Job Title';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(9; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
            DataClassification = OrganizationIdentifiableInformation;
        }
        field(11; "Created DateTime"; DateTime)
        {
            Caption = 'Created Date Time';
            DataClassification = SystemMetadata;
        }
        field(12; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            DataClassification = SystemMetadata;
        }
        field(14; "Categories"; Text[250])
        {
            Caption = 'Categories';
            DataClassification = SystemMetadata;
        }
        field(15; "Middle Name"; Text[50])
        {
            Caption = 'Middle Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(16; "Initials"; Text[10])
        {
            Caption = 'Initials';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(17; "Home Phone"; Text[30])
        {
            Caption = 'Home Phone';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(19; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(20; "Email 2"; Text[250])
        {
            Caption = 'Email 2';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; "Address"; Text[100])
        {
            Caption = 'Address';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(23; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(24; "City"; Text[50])
        {
            Caption = 'City';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "Post Code"; Text[20])
        {
            Caption = 'Post Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(27; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(28; "Display Name"; Text[50])
        {
            Caption = 'Display Name';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(29; "County"; Text[50])
        {
            Caption = 'County/State';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(30; "Folder Id"; Text[250])
        {
            Caption = 'FolderId';
            DataClassification = SystemMetadata;
        }
        field(31; "Outlook Id"; Text[500])
        {
            Caption = 'OutlookId';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Outlook Id")
        {
            Clustered = true;
        }
        key(EmailAddress; "Email Address")
        {
        }
        key(FolderKey; "Folder Id")
        {
        }
        key(FolderIdEmail; "Folder Id", "Email Address")
        {
        }
    }
}