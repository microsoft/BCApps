// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

using Microsoft.Upgrade;

/// <summary>
/// Configuration page for setting up bank file import/export formats and processing rules.
/// Provides interface for managing electronic banking data exchange definitions and processing logic.
/// </summary>
/// <remarks>
/// Source Table: Bank Export/Import Setup (1200). Supports configuration of import, export, and positive pay formats.
/// Integrates with Data Exchange Framework for flexible file format handling.
/// </remarks>
page 1200 "Bank Export/Import Setup"
{
    AdditionalSearchTerms = 'data exchange definition setup,bank file import setup,bank file export setup,bank transfer setup,amc yodlee feed stream setup';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Export/Import Setup';
    PageType = List;
    SourceTable = "Bank Export/Import Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                }
                field("Processing Codeunit ID"; Rec."Processing Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Processing Codeunit Name"; Rec."Processing Codeunit Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Processing XMLport ID"; Rec."Processing XMLport ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Processing XMLport Name"; Rec."Processing XMLport Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Data Exch. Def. Code"; Rec."Data Exch. Def. Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Preserve Non-Latin Characters"; Rec."Preserve Non-Latin Characters")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Check Export Codeunit"; Rec."Check Export Codeunit")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Check Export Codeunit Name"; Rec."Check Export Codeunit Name")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control12; Notes)
            {
                ApplicationArea = Notes;
            }
            systempart(Control13; Links)
            {
                ApplicationArea = RecordLinks;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SEPACAMT5300108)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'SEPA CAMT 053.001.08', Locked = true;
                Enabled = true;
                Image = SetupLines;
                ToolTip = 'Sets up a bank import format for SEPA CAMT 053.001.08 files';

                trigger OnAction()
                begin
                    UpgradeSEPACAMT05300108();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Setup';

                actionref(SEPACAMT5300108_Promoted; SEPACAMT5300108)
                {
                }
            }
        }
    }

    var
        ProceedWithSetupSEPACAMTQst: Label 'Do you want to set up the %1 bank import format?', Comment = '%1 - SEPA CAMT 053.001.08';
        SetupCompletedMsg: Label 'Setup of data exchange definition and bank import setup  %1 is completed.', Comment = '%1 - SEPA CAMT 053.001.08';

    local procedure UpgradeSEPACAMT05300108()
    var
        UpgradeBaseApp: Codeunit "Upgrade - BaseApp";
    begin
        if not Confirm(StrSubstNo(ProceedWithSetupSEPACAMTQst, SEPACAMT05300108())) then
            exit;

        UpgradeBaseApp.UpgradeSEPACAMT05300108();

        CurrPage.Update();
        Message(SetupCompletedMsg, SEPACAMT05300108());
    end;

    local procedure SEPACAMT05300108(): Code[20]
    begin
        exit('SEPA CAMT 053-08');
    end;
}

