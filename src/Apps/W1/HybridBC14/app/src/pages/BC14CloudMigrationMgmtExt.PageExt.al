// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.DataMigration;

pageextension 50170 "BC14 Cloud Migration Mgmt Ext" extends "Cloud Migration Management"
{
    actions
    {
        addafter(RunDataUpgrade)
        {
            action(BC14MigrationConfiguration)
            {
                ApplicationArea = All;
                Caption = 'BC14 Migration Settings';
                ToolTip = 'Open BC14 migration configuration.';
                Image = Setup;
                Visible = BC14MigrationEnabled;

                trigger OnAction()
                begin
                    Page.Run(Page::"BC14 Migration Configuration");
                end;
            }

            action(BC14MigrationErrors)
            {
                ApplicationArea = All;
                Caption = 'BC14 Migration Errors';
                ToolTip = 'View BC14 migration errors.';
                Image = ErrorLog;
                Visible = BC14MigrationEnabled;

                trigger OnAction()
                begin
                    Page.Run(Page::"BC14 Migration Error Overview");
                end;
            }

            action(BC14BalanceValidation)
            {
                ApplicationArea = All;
                Caption = 'Validate Balances';
                ToolTip = 'Compare BC14 source balances with BC Online balances to verify migration accuracy.';
                Image = Balance;
                Visible = BC14MigrationEnabled;

                trigger OnAction()
                begin
                    Page.Run(Page::"BC14 Balance Validation");
                end;
            }
        }

        addlast(Promoted)
        {
            actionref(BC14MigrationErrors_Promoted; BC14MigrationErrors)
            {
            }
            actionref(BC14MigrationConfiguration_Promoted; BC14MigrationConfiguration)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        BC14Wizard: Codeunit "BC14 Wizard";
    begin
        BC14MigrationEnabled := BC14Wizard.GetBC14MigrationEnabled();
    end;

    var
        BC14MigrationEnabled: Boolean;
}