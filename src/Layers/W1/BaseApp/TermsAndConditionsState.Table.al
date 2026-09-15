// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Privacy;

using System.Security.AccessControl;

table 9191 "Terms And Conditions State"
{
    Caption = 'Terms And Conditions State';
    DataPerCompany = false;
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Terms And Conditions Code"; Code[20])
        {
            Caption = 'Terms And Conditions Code';
            TableRelation = "Terms And Conditions";
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User;
            ValidateTableRelation = false;
        }
        field(3; Accepted; Boolean)
        {
            Caption = 'Accepted';
        }
        field(4; "Date Accepted"; DateTime)
        {
            Caption = 'Date Accepted';
        }
    }

    keys
    {
        key(Key1; "Terms And Conditions Code", "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

