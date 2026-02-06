// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Table Shpfy Payment Method Mapping (ID 30134).
/// </summary>
table 30134 "Shpfy Payment Method Mapping"
{
    Access = Internal;
    Caption = 'Shopify Payment Method';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Shop Code"; Code[20])
        {
            Caption = 'Shop Code';
            DataClassification = SystemMetadata;
            TableRelation = "Shpfy Shop";
        }
        field(2; Gateway; Text[30])
        {
            Caption = 'Gateway';
            DataClassification = CustomerContent;
            TableRelation = "Shpfy Transaction Gateway";
        }
        field(3; "Credit Card Company"; Text[30])
        {
            Caption = 'Credit Card Company';
            DataClassification = CustomerContent;
            TableRelation = "Shpfy Credit Card Company";
        }
        field(4; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            DataClassification = CustomerContent;
            TableRelation = "Payment Method";
        }
#if not CLEANSCHEMA28
        field(5; Priority; Integer)
        {
            Caption = 'Priority';
            DataClassification = CustomerContent;
            MinValue = 0;
            ObsoleteReason = 'Priority is no longer used.';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
        }
#endif
        field(6; "Manual Payment Gateway"; Boolean)
        {
            Caption = 'Manual Payment Gateway';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(7; "Post Automatically"; Boolean)
        {
            Caption = 'Post Automatically';
            DataClassification = CustomerContent;
        }
        field(8; "Auto-Post Jnl. Template"; Code[10])
        {
            Caption = 'Auto-Post Journal Template';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Journal Template";
        }
        field(9; "Auto-Post Jnl. Batch"; Code[10])
        {
            Caption = 'Auto-Post Journal Batch';
            DataClassification = CustomerContent;
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Auto-Post Jnl. Template"));

            trigger OnValidate()
            var
                GenJournalBatch: Record "Gen. Journal Batch";
            begin
                if "Auto-Post Jnl. Batch" <> '' then begin
                    GenJournalBatch.Get("Auto-Post Jnl. Template", "Auto-Post Jnl. Batch");
                    GenJournalBatch.TestField("Bal. Account No.");
                end;
            end;
        }
    }
    keys
    {
        key(PK; "Shop Code", Gateway, "Credit Card Company")
        {
            Clustered = true;
        }
    }

}