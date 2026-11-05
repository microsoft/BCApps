// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Foundation;

using Microsoft.Finance;
using System.Visualization;

codeunit 11792 "Create Cue Setup CZ"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()

    begin
        CreateEETCue();
    end;

    procedure CreateEETCue()
    var
        EETCue: Record "EET Cue CZL";
        CuesAndKPIs: Codeunit "Cues And KPIs";
    begin
        CuesAndKPIs.InsertData(Database::"EET Cue CZL", EETCue.FieldNo("Failed Amount"), Enum::"Cues And KPIs Style"::Unfavorable, -1, Enum::"Cues And KPIs Style"::Favorable, 0, Enum::"Cues And KPIs Style"::Unfavorable);
        CuesAndKPIs.InsertData(Database::"EET Cue CZL", EETCue.FieldNo("Registered Amount"), Enum::"Cues And KPIs Style"::Favorable, -1, Enum::"Cues And KPIs Style"::None, 0, Enum::"Cues And KPIs Style"::Favorable);
        CuesAndKPIs.InsertData(Database::"EET Cue CZL", EETCue.FieldNo("Failed Entries"), Enum::"Cues And KPIs Style"::None, -1, Enum::"Cues And KPIs Style"::Favorable, 0, Enum::"Cues And KPIs Style"::Unfavorable);
        CuesAndKPIs.InsertData(Database::"EET Cue CZL", EETCue.FieldNo("Pending Entries"), Enum::"Cues And KPIs Style"::None, 25, Enum::"Cues And KPIs Style"::Ambiguous, 50, Enum::"Cues And KPIs Style"::Unfavorable);
        CuesAndKPIs.InsertData(Database::"EET Cue CZL", EETCue.FieldNo("Entries with Warnings"), Enum::"Cues And KPIs Style"::None, -1, Enum::"Cues And KPIs Style"::None, 0, Enum::"Cues And KPIs Style"::Ambiguous);
        CuesAndKPIs.InsertData(Database::"EET Cue CZL", EETCue.FieldNo("Successful Entries"), Enum::"Cues And KPIs Style"::None, -1, Enum::"Cues And KPIs Style"::None, 0, Enum::"Cues And KPIs Style"::Favorable);
    end;
}
