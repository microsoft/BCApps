// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 11404 "Audit File Buffer"
{
    Caption = 'Audit File Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Rectype; Option)
        {
            Caption = 'Rectype';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,G/L Account,Customer,Vendor,Bank Account,Transaction';
            OptionMembers = " ","G/L Account",Customer,Vendor,"Bank Account",Transaction;
        }
        field(5; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(10; JournalID; Text[20])
        {
            Caption = 'JournalID';
            DataClassification = SystemMetadata;
        }
        field(15; JournalDescription; Text[100])
        {
            Caption = 'JournalDescription';
            DataClassification = SystemMetadata;
        }
        field(20; TransactionID; Text[20])
        {
            Caption = 'TransactionID';
            DataClassification = SystemMetadata;
        }
        field(25; TransactionDescription; Text[100])
        {
            Caption = 'TransactionDescription';
            DataClassification = SystemMetadata;
        }
        field(30; Period; Text[5])
        {
            Caption = 'Period';
            DataClassification = SystemMetadata;
        }
        field(35; TransactionDate; Date)
        {
            Caption = 'TransactionDate';
            DataClassification = SystemMetadata;
        }
        field(40; RecordID; Text[20])
        {
            Caption = 'RecordID';
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA28
        field(45; AccountID; Text[15])
        {
            Caption = 'AccountID';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced with Account ID';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
        }
#endif
#if not CLEANSCHEMA28
        field(50; CustSupID; Text[15])
        {
            Caption = 'CustSupID';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced with Source ID';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
        }
#endif
#if not CLEANSCHEMA28
        field(55; DocumentID; Text[15])
        {
            Caption = 'DocumentID';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced with Document ID';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
        }
#endif
        field(60; EffectiveDate; Date)
        {
            Caption = 'EffectiveDate';
            DataClassification = SystemMetadata;
        }
        field(65; LineDescription; Text[100])
        {
            Caption = 'LineDescription';
            DataClassification = SystemMetadata;
        }
        field(70; DebitAmount; Decimal)
        {
            Caption = 'DebitAmount';
            DataClassification = SystemMetadata;
        }
        field(75; CreditAmount; Decimal)
        {
            Caption = 'CreditAmount';
            DataClassification = SystemMetadata;
        }
        field(76; CostDescription; Text[100])
        {
            Caption = 'CostDescription';
            DataClassification = SystemMetadata;
        }
        field(77; ProductDescription; Text[100])
        {
            Caption = 'ProductDescription';
            DataClassification = SystemMetadata;
        }
        field(80; VATCode; Code[20])
        {
            Caption = 'VATCode';
            DataClassification = SystemMetadata;
        }
        field(81; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(82; VATAmount; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'VATAmount';
            DataClassification = SystemMetadata;
        }
        field(90; "Account ID"; Text[20])
        {
            DataClassification = SystemMetadata;
        }
        field(91; "Source ID"; Code[35])
        {
            DataClassification = SystemMetadata;
        }
        field(92; "Document ID"; Text[20])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Rectype, "Code", JournalID, TransactionID, RecordID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
