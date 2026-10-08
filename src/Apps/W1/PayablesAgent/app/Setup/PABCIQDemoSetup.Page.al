// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

page 3327 "PA BC IQ Demo Setup"
{
    PageType = Card;
    Caption = 'BC IQ Payables Agent Demo Setup';
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Business Central IQ, Payables Agent, GB demo';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'GB demo company setup';
                InstructionalText = 'Creates only the records required by the four GB Payables Agent scenarios in CRONUS W1. Cleanup restores the vendor fields captured during setup and removes only unchanged, unused records created by this page.';

                field(CurrentCompany; CurrentCompanyName)
                {
                    Caption = 'Current Company';
                    ToolTip = 'Specifies the company in which setup or cleanup will run.';
                    Editable = false;
                }
                field(Status; StatusText)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the GB demo setup is currently configured.';
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetupCompany)
            {
                Caption = 'Setup Company';
                ToolTip = 'Create the vendors, G/L accounts, UK 20% VAT setup, and four company-scoped Business Central IQ skills required by the GB demo.';
                Image = Setup;
                Enabled = not SetupConfigured;

                trigger OnAction()
                begin
                    DemoSetupMgt.SetupCompany();
                    RefreshStatus();
                    Message(SetupCompletedMsg);
                end;
            }
            action(CleanupCompany)
            {
                Caption = 'Clean Up';
                ToolTip = 'Restore the captured vendor fields and remove only unchanged, unused records and exact Business Central IQ skill IDs created by Setup Company.';
                Image = Delete;
                Enabled = SetupConfigured;

                trigger OnAction()
                begin
                    if not Confirm(CleanupQst, false) then
                        exit;
                    DemoSetupMgt.CleanupCompany();
                    RefreshStatus();
                    Message(CleanupCompletedMsg);
                end;
            }
        }
        area(Promoted)
        {
            actionref(SetupCompanyPromoted; SetupCompany)
            {
            }
            actionref(CleanupCompanyPromoted; CleanupCompany)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        RefreshStatus();
    end;

    local procedure RefreshStatus()
    begin
        CurrentCompanyName := CompanyName();
        SetupConfigured := DemoSetupMgt.IsConfigured();
        StatusText := DemoSetupMgt.GetStatusText();
        CurrPage.Update(false);
    end;

    var
        DemoSetupMgt: Codeunit "PA BC IQ Demo Mgt.";
        CurrentCompanyName: Text[30];
        StatusText: Text;
        SetupConfigured: Boolean;
        SetupCompletedMsg: Label 'The GB Payables Agent demo setup is ready.';
        CleanupCompletedMsg: Label 'The GB Payables Agent demo setup was removed and the captured vendor fields were restored.';
        CleanupQst: Label 'Clean up the GB Payables Agent demo setup? Cleanup stops without deleting anything if a demo record was edited or used.';
}
