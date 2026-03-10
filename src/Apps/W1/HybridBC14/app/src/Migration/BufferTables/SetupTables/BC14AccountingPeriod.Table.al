// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

table 50195 "BC14 Accounting Period"
{
    Caption = 'BC14 Accounting Period';
    DataClassification = CustomerContent;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(2; "Name"; Text[10])
        {
            Caption = 'Name';
        }
        field(3; "New Fiscal Year"; Boolean)
        {
            Caption = 'New Fiscal Year';
        }
        field(4; "Closed"; Boolean)
        {
            Caption = 'Closed';
        }
        field(5; "Date Locked"; Boolean)
        {
            Caption = 'Date Locked';
        }
        field(6; "Average Cost Calc. Type"; Option)
        {
            Caption = 'Average Cost Calc. Type';
            OptionMembers = " ",Item,"Item & Location & Variant";
            OptionCaption = ' ,Item,Item & Location & Variant';
        }
        field(7; "Average Cost Period"; Option)
        {
            Caption = 'Average Cost Period';
            OptionMembers = " ",Day,Week,Month,Quarter,Year,"Accounting Period";
            OptionCaption = ' ,Day,Week,Month,Quarter,Year,Accounting Period';
        }
    }

    keys
    {
        key(Key1; "Starting Date")
        {
            Clustered = true;
        }
    }
}
