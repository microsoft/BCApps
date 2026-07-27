// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

table 7216 EACorpCardProvider
{
    Access = Internal;
    Caption = 'Corp Card Provider';
    DataClassification = CustomerContent;
    LookupPageId = EACorpCardProviders;
    DrillDownPageId = EACorpCardProviders;
    ReplicateData = false;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
        }
        field(4; "Feed Type"; Enum EACorpCardFeedType)
        {
            Caption = 'Feed Type';
        }
        field(5; "Auth Type"; Enum EACorpCardAuthType)
        {
            Caption = 'Authentication Type';
        }
        field(6; "Data Exch Def Code"; Code[20])
        {
            Caption = 'Data Exchange Definition Code';
        }
        field(7; "Data Exch Map Code"; Code[20])
        {
            Caption = 'Data Exchange Mapping Code';
        }
        field(8; "API Endpoint"; Text[250])
        {
            Caption = 'API Endpoint';
        }
        field(9; "Secret Ref"; Text[250])
        {
            Caption = 'Secret Reference';
        }
        field(10; "Import Frequency (Min)"; Integer)
        {
            Caption = 'Import Frequency (Min.)';
            MinValue = 0;
        }
        field(11; "Last Import DT"; DateTime)
        {
            Caption = 'Last Import Date-Time';
            Editable = false;
        }
        field(12; "Last Batch No."; Integer)
        {
            Caption = 'Last Batch No.';
            Editable = false;
        }
        field(13; "Source File Name"; Text[250])
        {
            Caption = 'Source File Name';
        }
        field(14; "Source Payload"; Blob)
        {
            Caption = 'Source Payload';
            Subtype = Memo;
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }
}