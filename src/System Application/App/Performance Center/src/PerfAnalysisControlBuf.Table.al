// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Temporary buffer used to render the scenario lookup for the wizard. Each row is one
/// natural-language sentence describing a user action on a page, for example
/// <c>"Invoke the 'Post' action."</c> or <c>"Change the value of the 'Name' field of the Lines."</c>.
/// Additional fields identify which page the scenario targets and what kind of interaction
/// it describes, so the lookup page can present two-section filtering.
/// </summary>
table 8405 "Perf. Analysis Control Buf"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Performance Analysis Scenario Buffer';
    TableType = Temporary;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Line No."; Integer) { Caption = 'Line No.'; }
        field(2; "Sort Group"; Integer) { Caption = 'Sort Group'; }
        field(3; "Scenario"; Text[500]) { Caption = 'Scenario'; }
        field(4; "Target Page Id"; Integer) { Caption = 'Target Page Id'; }
        field(5; "Target Page Name"; Text[250]) { Caption = 'Target Page Name'; }
        field(6; "Scenario Type"; Option)
        {
            Caption = 'Scenario type';
            OptionMembers = Field,Action,Close;
            OptionCaption = 'Change a field value,Invoke an action,Close the page';
        }
    }

    keys
    {
        key(PK; "Line No.") { Clustered = true; }
        key(Sort; "Sort Group", "Scenario") { }
    }
}
