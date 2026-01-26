#if not CLEANSCHEMA25 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Finance.Currency;

table 262 "Intrastat Jnl. Batch"
{
    Caption = 'Intrastat Jnl. Batch';
    DataCaptionFields = Name, Description;
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; Reported; Boolean)
        {
            Caption = 'Reported';
        }
        field(14; "Statistics Period"; Code[10])
        {
            Caption = 'Statistics Period';
            Numeric = true;
        }
        field(15; "Amounts in Add. Currency"; Boolean)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Amounts in Add. Currency';
        }
        field(16; "Currency Identifier"; Code[10])
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Identifier';
        }
        field(12100; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Purchases,Sales';
            OptionMembers = Purchases,Sales;
        }
        field(12101; Periodicity; Option)
        {
            Caption = 'Periodicity';
            OptionCaption = 'Month,Quarter,Year';
            OptionMembers = Month,Quarter,Year;

            trigger OnValidate()
            begin
                "Statistics Period" := '';   //IT
            end;
        }
        field(12103; "File Disk No."; Code[20])
        {
            Caption = 'File Disk No.';
            Numeric = true;
        }
        field(12110; "Corrective Entry"; Boolean)
        {
            Caption = 'Corrective Entry';
        }
        field(12111; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", Name)
        {
            Clustered = true;
        }
        key(Key2; "File Disk No.")
        {
        }
    }

    fieldgroups
    {
    }
}

 
#endif
