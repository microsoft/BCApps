// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.Setup;

using Microsoft.QualityManagement.Integration.Manufacturing;

pageextension 20422 "Qlty. Mgmt. Setup - Mfg" extends "Qlty. Management Setup"
{
    layout
    {
        addbefore(SettingsForReceiving)
        {
            group(SettingsForProduction)
            {
                Caption = 'Production';
                InstructionalText = 'Production related settings are configured in this group. For example, you can choose to automatically create tests when output is created.';

                group(SettingsForProductionAutomation)
                {
                    Caption = 'Automation';
                    InstructionalText = 'Define the default automation settings for test generation rules related to production output. Different triggers can be changed on the test generation rules.';
                    AboutTitle = 'Production Related Automation Settings';
                    AboutText = 'Production related settings are configured in this group. You can choose to automatically create tests when output is created, whether or not to update the source, and other automatic features.';

                    field("Assembly Trigger"; Rec."Assembly Trigger")
                    {
                        Caption = 'Assembly - Create Test';
                        ApplicationArea = Assembly;
                        ShowCaption = true;
                        AboutTitle = 'Assembly related trigger';
                        AboutText = 'Optionally choose an assembly-related trigger to try and create a test.';
                    }
                    field("Production Trigger"; Rec."Production Trigger")
                    {
                        Caption = 'Production - Create Test';
                        ApplicationArea = Manufacturing;
                        ShowCaption = true;
                        AboutTitle = 'Production related trigger';
                        AboutText = 'Optionally choose a production-related trigger to try and create a test.';
                    }
                    field("Auto Output Configuration"; Rec."Auto Output Configuration")
                    {
                        Caption = 'Auto Output Configuration';
                        ApplicationArea = Manufacturing;
                        ShowCaption = true;
                        AboutTitle = 'Auto Output Configuration';
                        AboutText = 'Provides granular options for when a test should be created automatically during the production process.';
                    }
                    field(ChooseCreateNewRule_Production; 'Click here to create a new generation rule...')
                    {
                        ShowCaption = false;
                        ApplicationArea = Assembly, Manufacturing;

                        trigger OnDrillDown()
                        var
                            QltyProdGenRuleWizard: Page "Qlty. Prod. Gen. Rule Wizard";
                        begin
                            CurrPage.Update(true);
                            QltyProdGenRuleWizard.RunModal();
                            CurrPage.Update(false);
                        end;
                    }
                    field("Production Update Control"; Rec."Production Update Control")
                    {
                        ApplicationArea = Manufacturing;
                        ShowCaption = true;
                        Caption = 'Control Source';
                        Importance = Additional;
                        Visible = false;
                        AboutTitle = 'When to update on production related changes.';
                        AboutText = 'Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do Not Update" to prevent updating the original source that created the test.';
                    }
                }
            }
        }
    }
}
