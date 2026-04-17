// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// A line on a Performance Analysis: either a captured profile row (kept with a
/// relevance score decided by the AI filter) or a gathered signal finding.
/// </summary>
table 5471 "Performance Analysis Line"
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
        field(3; "Line Type"; Option)
        {
            Caption = 'Line Type';
            OptionMembers = Profile,Signal;
            OptionCaption = 'Profile,Signal';
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
        field(20; "Signal Source"; Enum "Perf. Analysis Signal Source")
        {
            Caption = 'Signal Source';
        }
        field(21; "Severity"; Enum "Perf. Analysis Severity")
        {
            Caption = 'Severity';
        }
        field(22; "Title"; Text[250])
        {
            Caption = 'Title';
        }
        field(23; "Description"; Text[2048])
        {
            Caption = 'Description';
        }
        field(24; "Link"; Text[2048])
        {
            Caption = 'Link';
            ExtendedDatatype = Url;
        }
    }

    keys
    {
        key(PK; "Analysis Id", "Line No.") { Clustered = true; }
        key(Relevance; "Analysis Id", "Line Type", "Ai Relevance Score") { }
        key(Severity; "Analysis Id", "Line Type", "Severity") { }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Line Type", "Title", "Severity", "Ai Relevance Score") { }
    }
}
