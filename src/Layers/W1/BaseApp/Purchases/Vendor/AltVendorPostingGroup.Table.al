// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

table 961 "Alt. Vendor Posting Group"
{
    Caption = 'Alternative Vendor Posting Group';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor Posting Group"; Code[20])
        {
            Caption = 'Vendor Posting Group';
            TableRelation = "Vendor Posting Group";
        }
        field(2; "Alt. Vendor Posting Group"; Code[20])
        {
            Caption = 'Alternative Vendor Posting Group';
            TableRelation = "Vendor Posting Group";

            trigger OnValidate()
            begin
                if "Vendor Posting Group" = "Alt. Vendor Posting Group" then
                    Error(PostingGroupReplaceErr);
            end;
        }
    }

    keys
    {
        key(Key1; "Vendor Posting Group", "Alt. Vendor Posting Group")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PostingGroupReplaceErr: Label 'Posting Group cannot replace itself.';
}

