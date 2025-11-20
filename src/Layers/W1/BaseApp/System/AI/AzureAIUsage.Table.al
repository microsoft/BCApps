namespace System.AI;

table 2004 "Azure AI Usage"
{
    // // This table is used for Azure Machine Learning related features to control that amount of time used by all
    // // these features in total does not exceed the limit defined by Azure ML.The table is singleton and used only in SaaS.

    ReplicateData = false;
    Caption = 'Azure AI Usage';
    Permissions = TableData "Azure AI Usage" = rimd;
    Access = Internal;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Service; Option)
        {
            Caption = 'Service';
            OptionCaption = 'Machine Learning,Computer Vision';
            OptionMembers = "Machine Learning","Computer Vision";
        }
        field(2; "Total Resource Usage"; Decimal)
        {
            Caption = 'Total Resource Usage';
            Editable = false;
            MinValue = 0;
        }
        field(3; "Original Resource Limit"; Decimal)
        {
            Caption = 'Original Resource Limit';
            Editable = false;
            MinValue = 0;
        }
        field(4; "Limit Period"; Option)
        {
            Caption = 'Limit Period';
            Editable = false;
            OptionCaption = 'Year,Month,Day,Hour';
            OptionMembers = Year,Month,Day,Hour;
        }
        field(5; "Last DateTime Updated"; DateTime)
        {
            Caption = 'Last DateTime Updated';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Service)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

