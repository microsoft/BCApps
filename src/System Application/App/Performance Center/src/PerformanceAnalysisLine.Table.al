// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// A line on a Performance Analysis: a captured profile row, kept with a relevance
/// score decided by the AI filter.
/// </summary>
table 8404 "Performance Analysis Line"
{
    Access = Public;
    DataClassification = SystemMetadata;
    Caption = 'Performance Analysis Line';

    fields
    {
        field(1; "Analysis Id"; Guid)
        {
            Caption = 'Analysis Id';
            TableRelation = "Performance Analysis".Id;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Profile Schedule Id"; Guid)
        {
            Caption = 'Profile Schedule Id';
        }
        field(11; "Profile Created At"; DateTime)
        {
            Caption = 'Profile Created At';
        }
        field(12; "Ai Relevance Score"; Decimal)
        {
            Caption = 'AI Relevance Score';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
            MaxValue = 1;
            AutoFormatType = 0;
        }
        field(13; "Ai Reason"; Text[2048])
        {
            Caption = 'AI Reason';
        }
        field(14; "Marked Relevant"; Boolean)
        {
            Caption = 'Marked Relevant';
        }
    }

    keys
    {
        key(PK; "Analysis Id", "Line No.") { Clustered = true; }
        key(Relevance; "Analysis Id", "Ai Relevance Score") { }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Profile Created At", "Ai Relevance Score") { }
    }
}
