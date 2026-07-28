// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.VAT.Setup;

table 7214 EACorpCardMCCMap
{
    Access = Internal;
    Caption = 'Corp Card MCC Map';
    DataClassification = CustomerContent;
    LookupPageId = EACorpCardMCCMap;
    DrillDownPageId = EACorpCardMCCMap;
    ReplicateData = false;

    fields
    {
        field(1; MCC; Code[4])
        {
            Caption = 'MCC';
        }
        field(2; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code;
        }
        field(3; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group".Code;
        }
        field(4; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; Active; Boolean)
        {
            Caption = 'Active';
        }
    }

    keys
    {
        key(PK; MCC)
        {
            Clustered = true;
        }
    }
}