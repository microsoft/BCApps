namespace Microsoft.CRM.Outlook;
using Microsoft.CRM.Contact;

table 7013 "Contact Sync Queue"
{
    DataClassification = CustomerContent;
    InherentPermissions = rimd; // or 
    Caption = 'Contact Sync Queue';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
            ToolTip = 'Specifies the entry number.';
            AutoIncrement = true;
        }
        field(2; "Sync Direction"; Option)
        {
            DataClassification = SystemMetadata;
            Caption = 'Sync Direction';
            ToolTip = 'Specifies the sync direction.';
            OptionMembers = "To M365","To BC";
            OptionCaption = 'To M365,To BC';
        }
        field(3; "Contact ID"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Contact ID';
            ToolTip = 'Specifies the contact ID from Business Central.';
        }
        field(4; "Display Name"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Display Name';
            ToolTip = 'Specifies the display name.';
        }
        field(5; "Given Name"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Given Name';
            ToolTip = 'Specifies the first name.';
        }
        field(6; Surname; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Surname';
            ToolTip = 'Specifies the surname.';
        }
        field(7; "Job Title"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Job Title';
            ToolTip = 'Specifies the job title.';
        }
        field(8; "Company Name"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Company Name';
            ToolTip = 'Specifies the company name.';
        }
        field(9; "Department"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Department';
        }
        field(10; "Mobile Phone"; Text[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Mobile Phone';
            ToolTip = 'Specifies the mobile phone.';
        }
        field(11; "Business Phone"; Text[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Business Phone';
            ToolTip = 'Specifies the business phone.';
        }
        field(12; "Home Phone"; Text[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Home Phone';
        }
        field(13; "Email Address"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Email Address';
            ToolTip = 'Specifies the email address.';
        }
        field(14; "Email 2"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Email 2';
        }
        field(15; Address; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Address';
        }
        field(16; City; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'City';
            ToolTip = 'Specifies the city.';
        }
        field(17; County; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'County';
        }
        field(18; "Post Code"; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'Post Code';
        }
        field(19; "Country/Region Code"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Country/Region Code';
            ToolTip = 'Specifies the country/region code.';
        }
        field(20; "Middle Name"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Middle Name';
        }
        field(21; Initials; Text[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Initials';
        }
#if not CLEANSCHEMA29
        field(22; "Office Location"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Office Location';
        }
        field(23; "Assistant Name"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Assistant Name';
        }
        field(24; Manager; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Manager';
        }
        field(25; "Home Page"; Text[255])
        {
            DataClassification = SystemMetadata;
            Caption = 'Home Page';
        }
        field(26; "Personal Notes"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Personal Notes';
        }
        field(27; Categories; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Categories';
        }
#endif
        field(28; "Created DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Created DateTime';
            ToolTip = 'Specifies when the queue entry was created.';
        }
        field(29; "Last Modified DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Last Modified DateTime';
            ToolTip = 'Specifies when the contact was last modified.';
        }
        field(30; "BC Contact No."; Code[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'BC Contact No.';
            ToolTip = 'Specifies the BC contact number.';
            TableRelation = Contact."No." where(Type = const(Person));
        }
        field(31; "Sync Status"; Option)
        {
            DataClassification = SystemMetadata;
            Caption = 'Sync Status';
            ToolTip = 'Specifies the sync status.';
            OptionMembers = Pending,Processed,Error;
            OptionCaption = 'Pending,Processed,Error';
        }
        field(32; "Error Message"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Error Message';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Email; "Email Address")
        {
        }
        key(Status; "Sync Status")
        {
        }
    }
#if not CLEAN29
    [Obsolete('Removed due to Contact Sync redesign, will be deleted in future release.', '29.0')]
    procedure CopyFromO365Contact(GraphContact: Record "O365 Contact"; Direction: Option "To Graph","To Local")
    begin
        "Sync Direction" := Direction;
        "Contact ID" := GraphContact."Contact ID";
        "Display Name" := GraphContact."Display Name";
        "Given Name" := GraphContact."Given Name";
        Surname := GraphContact.Surname;
        "Job Title" := GraphContact."Job Title";
        "Company Name" := GraphContact."Company Name";
        "Mobile Phone" := GraphContact."Mobile Phone";
        "Business Phone" := GraphContact."Business Phone";
        "Home Phone" := GraphContact."Home Phone";
        "Email Address" := GraphContact."Email Address";
        "Email 2" := GraphContact."Email 2";
        Address := GraphContact.Address;
        City := GraphContact.City;
        "Post Code" := GraphContact."Post Code";
        "Country/Region Code" := GraphContact."Country/Region Code";
        "Middle Name" := GraphContact."Middle Name";
        Initials := GraphContact.Initials;
        "Home Page" := GraphContact."Home Page";
        Categories := GraphContact.Categories;
        "Created DateTime" := GraphContact."Created DateTime";
        "Last Modified DateTime" := GraphContact."Last Modified DateTime";
        "Sync Status" := "Sync Status"::Pending;
    end;
#endif
    procedure CopyFromO365Contact(GraphContact: Record "Outlook Contacts"; Direction: Option "To Graph","To Local")
    begin
        "Sync Direction" := Direction;
        "Contact ID" := GraphContact."Contact ID";
        "Display Name" := GraphContact."Display Name";
        "Given Name" := GraphContact."Given Name";
        Surname := GraphContact.Surname;
        "Job Title" := GraphContact."Job Title";
        "Company Name" := GraphContact."Company Name";
        "Mobile Phone" := GraphContact."Mobile Phone";
        "Business Phone" := GraphContact."Business Phone";
        "Home Phone" := GraphContact."Home Phone";
        "Email Address" := GraphContact."Email Address";
        "Email 2" := GraphContact."Email 2";
        Address := GraphContact.Address;
        City := GraphContact.City;
        "Post Code" := GraphContact."Post Code";
        County := GraphContact.County;
        "Country/Region Code" := GraphContact."Country/Region Code";
        "Middle Name" := GraphContact."Middle Name";
        Initials := GraphContact.Initials;
        "Home Page" := GraphContact."Home Page";
        Categories := GraphContact.Categories;
        "Created DateTime" := GraphContact."Created DateTime";
        "Last Modified DateTime" := GraphContact."Last Modified DateTime";
        "Sync Status" := "Sync Status"::Pending;
    end;

    procedure CopyFromBCContact(Contact: Record Contact; Direction: Option "To Graph","To Local")
    begin
        "Sync Direction" := Direction;
        "BC Contact No." := Contact."No.";
        "Display Name" := Contact.Name;
        "Given Name" := Contact."First Name";
        Surname := Contact.Surname;
        "Job Title" := Contact."Job Title";
        "Company Name" := Contact."Company Name";
        "Mobile Phone" := Contact."Mobile Phone No.";
        "Business Phone" := Contact."Phone No.";
        "Email Address" := Contact."E-Mail";
        Address := Contact.Address;
        City := Contact.City;
        County := Contact.County;
        "Post Code" := Contact."Post Code";
        "Country/Region Code" := Contact."Country/Region Code";
        "Middle Name" := Contact."Middle Name";
        Initials := Contact.Initials;
        "Home Page" := Contact."Home Page";
        "Last Modified DateTime" := Contact.SystemModifiedAt;
        "Sync Status" := "Sync Status"::Pending;
    end;
}
