#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007, AL0432
namespace Microsoft.Agent.PayablesAgent;

page 3311 "PA MLLM Setup"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'The MLLM Payables Agent feature is fully rolled out; the setup page used to roll it out is no longer needed.';
    ObsoleteTag = '29.0';
    PageType = Card;
    Extensible = false;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'PA MLLM Setup';
    SourceTable = "Payables Agent Setup";
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'MLLM Processing';
                field(UseMLLMProcessing; Rec."Use MLLM Processing")
                {
                    Caption = 'Use MLLM Processing';
                    ToolTip = 'Specifies whether the agent should use MLLM for document processing.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
#endif
