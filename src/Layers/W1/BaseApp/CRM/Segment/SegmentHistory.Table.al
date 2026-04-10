// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Segment;

using Microsoft.CRM.Contact;

table 5078 "Segment History"
{
    Caption = 'Segment History';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Segment No."; Code[20])
        {
            Caption = 'Segment No.';
            TableRelation = "Segment Header";
        }
        field(2; "Segment Action No."; Integer)
        {
            Caption = 'Segment Action No.';
        }
        field(3; "Segment Line No."; Integer)
        {
            Caption = 'Segment Line No.';
        }
        field(4; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;
        }
        field(5; "Action Taken"; Option)
        {
            Caption = 'Action Taken';
            OptionCaption = 'Insertion,Deletion';
            OptionMembers = Insertion,Deletion;
        }
    }

    keys
    {
        key(Key1; "Segment No.", "Segment Action No.", "Segment Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

