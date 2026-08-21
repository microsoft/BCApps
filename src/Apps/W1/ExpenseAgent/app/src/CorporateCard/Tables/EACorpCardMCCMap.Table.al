// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.VAT.Setup;

table 7214 "EA Corp Card MCC Map"
{
    Access = Internal;
    Caption = 'Corp Card MCC Map';
    DataClassification = CustomerContent;
    LookupPageId = "EA Corp Card MCC Map";
    DrillDownPageId = "EA Corp Card MCC Map";
    ReplicateData = false;

    fields
    {
        field(1; MCC; Code[4])
        {
            Caption = 'MCC';
            ToolTip = 'Specifies the Merchant Category Code.';
        }
        field(2; "Expense Category"; Code[20])
        {
            Caption = 'Expense Category';
            TableRelation = "Expense Category".Code;
            ToolTip = 'Specifies the Expense Category to which the MCC is mapped.';
        }
        field(3; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group".Code;
            ToolTip = 'Specifies the VAT Business Posting Group to which the MCC is mapped.';
        }
        field(4; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies whether the MCC is blocked for use.';
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the MCC.';
        }
        field(6; Active; Boolean)
        {
            Caption = 'Active';
            ToolTip = 'Specifies whether the MCC is active.';
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