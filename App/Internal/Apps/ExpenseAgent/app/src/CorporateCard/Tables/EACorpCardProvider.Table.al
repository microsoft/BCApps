// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;

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
            ToolTip = 'Specifies the code of the corporate card provider.';
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the corporate card provider.';
        }
        field(3; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'Specifies whether the corporate card provider is enabled.';
        }
        field(4; "Feed Type"; Enum EACorpCardFeedType)
        {
            Caption = 'Feed Type';
            ToolTip = 'Specifies the feed type for the corporate card provider.';
        }
        field(5; "Auth Type"; Enum EACorpCardAuthType)
        {
            Caption = 'Authentication Type';
            ToolTip = 'Specifies the authentication type for the corporate card provider.';
        }
        field(6; "Data Exch Def Code"; Code[20])
        {
            Caption = 'Data Exchange Definition Code';
            TableRelation = "Data Exch. Def";
            ToolTip = 'Specifies the data exchange definition code for the corporate card provider.';
        }
        field(7; "Data Exch Map Code"; Code[20])
        {
            Caption = 'Data Exchange Mapping Code';
            ToolTip = 'Specifies the data exchange mapping code for the corporate card provider.';
        }
        field(8; "API Endpoint"; Text[250])
        {
            Caption = 'API Endpoint';
            ToolTip = 'Specifies the API endpoint for the corporate card provider.';
        }
        field(9; "Secret Ref"; Text[250])
        {
            Caption = 'Secret Reference';
            ToolTip = 'Specifies the secret reference for the corporate card provider.';
        }
        field(10; "Import Frequency (Min)"; Integer)
        {
            Caption = 'Import Frequency (Min.)';
            MinValue = 0;
            ToolTip = 'Specifies the import frequency in minutes for the corporate card provider.';
        }
        field(11; "Last Import DT"; DateTime)
        {
            Caption = 'Last Import Date-Time';
            Editable = false;
            ToolTip = 'Specifies the date and time of the last import for the corporate card provider.';
        }
        field(12; "Last Batch No."; Integer)
        {
            Caption = 'Last Batch No.';
            Editable = false;
            ToolTip = 'Specifies the last batch number for the corporate card provider.';
        }
        field(13; "Source File Name"; Text[250])
        {
            Caption = 'Source File Name';
            ToolTip = 'Specifies the source file name for the corporate card provider.';
        }
        field(14; "Source Payload"; Blob)
        {
            Caption = 'Source Payload';
            Subtype = Memo;
            ToolTip = 'Specifies the source payload for the corporate card provider.';
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