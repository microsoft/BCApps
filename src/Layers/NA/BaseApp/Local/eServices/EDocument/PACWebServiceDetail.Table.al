// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

table 10001 "PAC Web Service Detail"
{
    Caption = 'PAC Web Service Detail';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "PAC Code"; Code[10])
        {
            Caption = 'PAC Code';
            TableRelation = "PAC Web Service".Code;
        }
        field(2; Environment; Option)
        {
            Caption = 'Environment';
            OptionCaption = ' ,Test,Production';
            OptionMembers = " ",Test,Production;
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Request Stamp,Cancel,Cancel Request';
            OptionMembers = "Request Stamp",Cancel,CancelRequest;
        }
        field(21; "Method Name"; Text[50])
        {
            Caption = 'Method Name';
        }
        field(22; Address; Text[250])
        {
            Caption = 'Address';
        }
    }

    keys
    {
        key(Key1; "PAC Code", Environment, Type)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

