// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Registration;

table 7404 "Registration No. Migration"
{
    Caption = 'Registration No. Migration';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
            Editable = false;
            ToolTip = 'Specifies the master record to review.';
        }
        field(2; "Record Type"; Text[250])
        {
            Caption = 'Record Type';
            Editable = false;
            ToolTip = 'Specifies the type of master record.';
        }
        field(3; "Local Registration No."; Text[50])
        {
            Caption = 'Local Registration No.';
            Editable = false;
            ToolTip = 'Specifies the existing localized registration number. This value is not changed by migration.';
        }
        field(4; "Registration Number"; Text[50])
        {
            Caption = 'W1 Registration No.';
            Editable = false;
            ToolTip = 'Specifies the current global registration number.';
        }
        field(5; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
            TableRelation = Microsoft.Foundation.Address."Country/Region";
            ToolTip = 'Specifies the country or region of the master record.';
        }
        field(6; "Local Field No."; Integer)
        {
            Caption = 'Local Field No.';
            Editable = false;
        }
        field(7; "Registration Field No."; Integer)
        {
            Caption = 'Registration Field No.';
            Editable = false;
        }
        field(8; Resolution; Option)
        {
            Caption = 'Resolution';
            OptionMembers = Pending,"Use Local","Keep W1";
            OptionCaption = 'Pending,Use Local,W1 Value Is Intentional';
            ToolTip = 'Specifies whether to explicitly copy the local value into W1 or retain the existing W1 value, including a deliberate blank. Pending records prevent activation.';
        }
        field(9; "Country Field No."; Integer)
        {
            Caption = 'Country Field No.';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Record ID")
        {
            Clustered = true;
        }
    }
}
