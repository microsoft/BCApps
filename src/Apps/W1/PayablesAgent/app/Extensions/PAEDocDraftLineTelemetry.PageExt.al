// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;

pageextension 3329 "PA EDoc Draft Line Telemetry" extends "E-Doc. Purchase Draft Subform"
{
    layout
    {
        addafter(Description)
        {
            field(PAMatchingLineSystemId; GetMatchingLineSystemId())
            {
                ApplicationArea = All;
                Caption = 'E-Document Line System Id';
                ToolTip = 'Specifies the source draft line identifier used to correlate matching telemetry.';
                Editable = false;
                Visible = false;
            }
        }
    }

    trigger OnOpenPage()
    var
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
    begin
        AgentDrivenLineMatchingEnabled := PayablesAgentSetup.IsAgentDrivenLineMatchingEnabled();
    end;

    local procedure GetMatchingLineSystemId(): Text
    var
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";
    begin
        if not AgentDrivenLineMatchingEnabled then
            exit('');
        exit(EDocImpSessionTelemetry.CreateSystemIdText(Rec.SystemId));
    end;

    var
        AgentDrivenLineMatchingEnabled: Boolean;
}
