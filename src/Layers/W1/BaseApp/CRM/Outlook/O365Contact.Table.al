#if not CLEAN29
namespace Microsoft.CRM.Outlook;

table 7107 "O365 Contact"
{
    Caption = 'O365 Contacts';
    TableType = Temporary;
    ObsoleteReason = 'Removed due to Contact Sync redesign, will be deleted in future release.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contact ID"; Text[250])
        {
            Caption = 'Contact ID';
        }
        field(3; "Given Name"; Text[50])
        {
            Caption = 'Given Name';
        }
        field(4; "Surname"; Text[50])
        {
            Caption = 'Surname';
        }
        field(5; "Email Address"; Text[250])
        {
            Caption = 'Email Address';
        }
        field(6; "Business Phone"; Text[30])
        {
            Caption = 'Business Phone';
        }
        field(7; "Mobile Phone"; Text[30])
        {
            Caption = 'Mobile Phone';
        }
        field(8; "Job Title"; Text[100])
        {
            Caption = 'Job Title';
        }
        field(9; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
        }
        field(11; "Created DateTime"; DateTime)
        {
            Caption = 'Created Date Time';
        }
        field(12; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified Date Time';
        }
        field(14; "Categories"; Text[250])
        {
            Caption = 'Categories';
        }
        field(15; "Middle Name"; Text[50])
        {
            Caption = 'Middle Name';
        }
        field(16; "Initials"; Text[10])
        {
            Caption = 'Initials';
        }
        field(17; "Home Phone"; Text[30])
        {
            Caption = 'Home Phone';
        }
        field(18; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(19; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
        }
        field(20; "Email 2"; Text[250])
        {
            Caption = 'Email 2';
        }
        field(22; "Address"; Text[100])
        {
            Caption = 'Address';
        }
        field(23; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(24; "City"; Text[50])
        {
            Caption = 'City';
        }
        field(26; "Post Code"; Text[20])
        {
            Caption = 'Post Code';
        }
        field(27; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
        }
        field(28; "Display Name"; Text[50])
        {
            Caption = 'Display Name';
        }
    }

    keys
    {
        key(PK; "Contact ID")
        {
            Clustered = true;
        }
    }
}
#endif
