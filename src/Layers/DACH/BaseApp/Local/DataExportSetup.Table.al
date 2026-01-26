// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
table 11009 "Data Export Setup"
{
    Caption = 'Data Export Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Data Export 2022 G/L Acc. Code"; Code[10])
        {
            Caption = 'Data Export 2022 G/L Accounting Code';
        }
        field(3; "Data Export 2022 FA Acc. Code"; Code[10])
        {
            Caption = 'Data Export 2022 FA Accounting Code';
        }
        field(4; "Data Export 2022 Item Acc Code"; Code[10])
        {
            Caption = 'Data Export 2022 Item Accounting Code';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
