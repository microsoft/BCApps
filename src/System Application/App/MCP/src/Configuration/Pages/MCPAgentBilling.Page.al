// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8380 "MCP Agent Billing"
{
    ApplicationArea = All;
    Caption = 'Activate Agent Tools';
    Extensible = false;
    PageType = ConfirmationDialog;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            label(BillingNotice)
            {
                ApplicationArea = All;
                Caption = 'Use of Agent Tools will incur additional charges. By activating Agent Tools, you acknowledge that charges will apply according to the applicable pricing and terms.';
                MultiLine = true;
                ShowCaption = false;
            }
            field(LearnMore; LearnMoreLbl)
            {
                ApplicationArea = All;
                DrillDown = true;
                Editable = false;
                ShowCaption = false;
                Style = StandardAccent;
                StyleExpr = true;
                ToolTip = 'Open documentation about Agent Tools pricing and terms.';

                trigger OnDrillDown()
                begin
                    Hyperlink(LearnMoreUrlLbl);
                end;
            }
            label(ConfirmationQuestion)
            {
                ApplicationArea = All;
                Caption = 'Do you want to activate Agent Tools?';
                MultiLine = true;
                ShowCaption = false;
            }
        }
    }

    var
        LearnMoreLbl: Label 'Learn more';
        LearnMoreUrlLbl: Label 'https://go.microsoft.com/fwlink/?LinkId=2383165', Locked = true;
}
