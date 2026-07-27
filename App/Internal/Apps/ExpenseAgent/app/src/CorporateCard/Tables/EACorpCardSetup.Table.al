// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7217 EACorpCardSetup
{
    Access = Internal;
    Caption = 'Corp Card Setup';
    DataClassification = CustomerContent;
    LookupPageId = EACorpCardSetupPage;
    DrillDownPageId = EACorpCardSetupPage;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Create Mode"; Enum EACorpCardCreateMode)
        {
            Caption = 'Create Mode';
        }
        field(3; "Date Match Window"; Integer)
        {
            Caption = 'Date Match Window (Days)';
            MinValue = 0;
        }
        field(4; "Amount Tolerance"; Decimal)
        {
            Caption = 'Amount Tolerance';
            MinValue = 0;
        }
        field(5; "Auto Create Draft"; Boolean)
        {
            Caption = 'Auto Create Draft';
        }
        field(6; "Default Provider Code"; Code[20])
        {
            Caption = 'Default Provider Code';
            TableRelation = EACorpCardProvider.Code;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if "Primary Key" = '' then
            "Primary Key" := 'SETUP';
    end;
}