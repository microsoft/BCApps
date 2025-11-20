// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Journal;

table 56 "Invoice Posting Parameters"
{
    Caption = 'Invoice Posting Parameters';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(2; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(4; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Auto Document No."; Code[20])
        {
            Caption = 'Auto Document No.';
            DataClassification = SystemMetadata;
        }
        field(6; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            DataClassification = SystemMetadata;
        }
        field(10; "Tax Type"; Option)
        {
            Caption = 'Tax Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'None,VAT,Sales Tax';
            OptionMembers = "None","VAT","Sales Tax";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }
}

