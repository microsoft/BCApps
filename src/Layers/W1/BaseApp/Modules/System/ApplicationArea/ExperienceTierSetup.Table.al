namespace System.Environment.Configuration;

using System.Environment;

table 9176 "Experience Tier Setup"
{
    Caption = 'Experience Tier Setup';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company;
        }
        field(100; Basic; Boolean)
        {
            Caption = 'Basic';
        }
        field(200; Essential; Boolean)
        {
            Caption = 'Essential';
        }
        field(225; Premium; Boolean)
        {
            Caption = 'Premium';
        }
        field(250; Preview; Boolean)
        {
            Caption = 'Preview';
        }
        field(300; Advanced; Boolean)
        {
            Caption = 'Advanced';
        }
        field(400; Custom; Boolean)
        {
            Caption = 'Custom';
        }
    }

    keys
    {
        key(Key1; "Company Name")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
