// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

table 960 "Alt. Customer Posting Group"
{
    Caption = 'Alternative Customer Posting Group';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer. Posting Group';
            TableRelation = "Customer Posting Group";
        }
        field(2; "Alt. Customer Posting Group"; Code[20])
        {
            Caption = 'Alternative Customer Posting Group';
            TableRelation = "Customer Posting Group";
            ToolTip = 'Specifies the customer group for posting business transactions to general ledger accounts.';

            trigger OnValidate()
            begin
                if "Customer Posting Group" = "Alt. Customer Posting Group" then
                    Error(PostingGroupReplaceErr);
            end;
        }
    }

    keys
    {
        key(Key1; "Customer Posting Group", "Alt. Customer Posting Group")
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

