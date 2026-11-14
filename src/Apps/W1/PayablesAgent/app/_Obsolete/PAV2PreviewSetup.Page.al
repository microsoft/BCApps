#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AL0432
namespace Microsoft.Agent.PayablesAgent;

page 3315 "PA V2 Preview Setup"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'Payables Agent preview', Comment = 'Payables Agent is a term, and should not be translated.';
    SourceTable = "Payables Agent Setup";
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'Temporary V2 preview selector, removed once version 2 no longer needs a preview opt-in.';
    ObsoleteTag = '30.0';

    layout
    {
        area(Content)
        {
            group(Preview)
            {
                Caption = 'Preview';
                InstructionalText = 'The selected preview is only used in the designated preview environment.';

                field(PreviewVersion; Rec."Preview Version")
                {
                    ToolTip = 'Specifies the Payables Agent preview to use for new work in the designated preview environment.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetOrCreateSetup();
    end;
}
#pragma warning restore AL0432
#endif
