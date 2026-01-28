// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Integration.Manufacturing;
using Microsoft.QualityManagement.Integration.Receiving;
using Microsoft.QualityManagement.Integration.Warehouse;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using System.Telemetry;

page 20400 "Qlty. Management Setup"
{
    Caption = 'Quality Management Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTable = "Qlty. Management Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    AboutTitle = 'Setup';
    AboutText = 'This setup page will let you define the behavior of how and when inspections are created.';

    layout
    {
        area(Content)
        {
            group(SettingsForDefaults)
            {
                Caption = 'General';
                group(SettingsForNumbering)
                {
                    Caption = 'Number Series';

                    field("Quality Inspection Nos."; Rec."Quality Inspection Nos.")
                    {
                        ApplicationArea = All;
                        ShowCaption = true;
                        AboutTitle = 'No. Series';
                        AboutText = 'The default number series for quality inspection documents is used when there isn''t a number series defined on the quality inspection template.';
                    }
                }
                group(SettingsForBehaviors)
                {
                    Caption = 'Creating and finding inspections';

                    field("Create Inspection Behavior"; Rec."Create Inspection Behavior")
                    {
                        ApplicationArea = All;
                        ShowCaption = true;
                        AboutTitle = 'Create Inspection Behavior';
                        AboutText = 'Defines the behavior of when to create a new Quality Inspection when existing inspections occur.';
                    }
                    field("Find Existing Behavior"; Rec."Find Existing Behavior")
                    {
                        ApplicationArea = All;
                        ShowCaption = true;
                        AboutTitle = 'Find Existing Inspection Behavior';
                        AboutText = 'When looking for existing inspections, this defines what it looks for.';
                    }
                    field("Conditional Lot Find Behavior"; Rec."Conditional Lot Find Behavior")
                    {
                        ApplicationArea = All;
                        ShowCaption = true;
                        AboutTitle = 'Which inspections to inspect when analyzing document specific lot blocking.';
                        AboutText = 'When evaluating if a document specific transactions are blocked, this determines which inspection(s) are considered.';
                    }
                }
                group(SettingsForMiscellaneous)
                {
                    Caption = 'Miscellaneous';

                    field("CoA Contact No."; Rec."Certificate Contact No.")
                    {
                        ApplicationArea = All;
                        AboutTitle = 'Certificate of Analysis Contact';
                        AboutText = 'When supplied, these contact details will appear on the Certificate of Analysis report.';
                    }
                    field("Max Rows Field Lookups"; Rec."Max Rows Field Lookups")
                    {
                        Importance = Additional;
                        ApplicationArea = All;
                        ShowCaption = true;
                        AboutTitle = 'Maximum Rows To Fetch In Lookups';
                        AboutText = 'This is the maximum number of rows to fetch on data lookups. Keeping the number as low as possible will increase usability and performance.';

                    }
                    field("Picture Upload Behavior"; Rec."Picture Upload Behavior")
                    {
                        ApplicationArea = All;
                        Caption = 'Picture Upload Behavior';
                        ShowCaption = true;
                        AboutTitle = 'Picture Upload Behavior';
                        AboutText = 'When a picture has been taken, this value defines what to do with that picture.';
                    }
                    group(Workflow)
                    {
                        Caption = 'Workflow and Approval Requests';
                        field("Workflow Integration Enabled"; Rec."Workflow Integration Enabled")
                        {
                            Importance = Additional;
                            ApplicationArea = All;
                            Caption = 'Workflow Integration';
                            AboutTitle = 'Business Central Workflow integration.';
                            AboutText = 'Workflows can be used to trigger dispositions, such as negative adjustments, transfers, moves, and more.';
                        }
                    }

                }
            }
            group(SettingsForReceiving)
            {
                Caption = 'Receiving';
                InstructionalText = 'Manage receiving options here, such as automatically creating inspections when receipts are posted.';

                group(SettingsForReceiveAutomation)
                {
                    Caption = 'Automation';
                    InstructionalText = 'Set up default automation for creating inspections from receipt tasks. Create inspection generation rules to choose templates and adjust triggers as needed.';
                    AboutTitle = 'Receiving Related Automation Settings';
                    AboutText = 'Receiving related settings are configured in this group. For example, you can choose to automatically create an inspection when a receipt is posted.';

                    field("Warehouse Receive Trigger"; Rec."Warehouse Receive Trigger")
                    {
                        ApplicationArea = All;
                        Caption = 'Warehouse Receipts';
                    }
                    field("Purchase Trigger"; Rec."Purchase Trigger")
                    {
                        ApplicationArea = All;
                        Caption = 'Purchase Orders';
                    }
                    field("Sales Return Trigger"; Rec."Sales Return Trigger")
                    {
                        ApplicationArea = All;
                        Caption = 'Sales Returns';
                    }
                    field("Transfer Trigger"; Rec."Transfer Trigger")
                    {
                        ApplicationArea = All;
                        Caption = 'Transfer Orders';
                    }
                    field(ChooseCreateNewRule_Receiving; 'Create receipt inspection rule')
                    {
                        ShowCaption = false;
                        ApplicationArea = All;

                        trigger OnDrillDown()
                        var
                            QltyRecGenRuleWizard: Page "Qlty. Rec. Gen. Rule Wizard";
                        begin
                            CurrPage.Update(true);
                            QltyRecGenRuleWizard.RunModal();
                            CurrPage.Update(false);
                        end;
                    }
                    field("Receive Update Control"; Rec."Receive Update Control")
                    {
                        ApplicationArea = All;
                        ShowCaption = true;
                        Caption = 'Control Source';
                        Importance = Additional;
                        Visible = false;
                        AboutTitle = 'When to update on receiving related changes.';
                        AboutText = 'Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Purchase Order is posted). Set to "Do Not Update" to prevent updating the original source that created the inspection.';
                    }
                }
            }
            group(SettingsForProduction)
            {
                Caption = 'Production';
                InstructionalText = 'Manage production options here, such as automatically creating inspections when output is posted';

                group(SettingsForProductionAutomation)
                {
                    Caption = 'Automation';
                    InstructionalText = 'Define the default automation for inspection generation in production. You can change triggers for inspection rules as needed in the Inspection Generation Rules.';
                    AboutTitle = 'Production Related Automation Settings';
                    AboutText = 'Production related settings are configured in this group. You can choose to automatically create inspections when output is created, whether or not to update the source, and other automatic features.';

                    field("Production Trigger"; Rec."Production Trigger")
                    {
                        Caption = 'Production - Create Inspection';
                        ApplicationArea = Manufacturing;
                        ShowCaption = true;
                        AboutTitle = 'Production related trigger';
                        AboutText = 'Optionally choose a production-related trigger to try and create an inspection.';
                    }
                    field("Auto Output Configuration"; Rec."Auto Output Configuration")
                    {
                        Caption = 'Auto Output Configuration';
                        ApplicationArea = Manufacturing;
                        ShowCaption = true;
                        AboutTitle = 'Auto Output Configuration';
                        AboutText = 'Provides granular options for when an inspection should be created automatically during the production process.';
                    }
                    field("Assembly Trigger"; Rec."Assembly Trigger")
                    {
                        Caption = 'Assembly - Create Inspection';
                        ApplicationArea = Assembly;
                        ShowCaption = true;
                        AboutTitle = 'Assembly related trigger';
                        AboutText = 'Optionally choose an assembly-related trigger to try and create an inspection.';
                    }
                    field(ChooseCreateNewRule_Production; 'Create production inspection rule')
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
                        AboutText = 'Set to "Update when Source Changes" to alter source information as the source record changes (for example, such as when a Production Order changes status to Finished). Set to "Do Not Update" to prevent updating the original source that created the inspection.';
                    }
                }
            }
            group(SettingsForInventory)
            {
                Caption = 'Inventory and Warehousing';

                group(SettingsForWarehouseAutomation)
                {
                    Caption = 'Automation';
                    InstructionalText = 'Define the default automation settings for inspection generation rules related to warehousing. Different triggers can be changed on the inspection generation rules.';
                    AboutTitle = 'Warehousing Related Automation Settings';
                    AboutText = 'Warehousing related settings are configured in this group. For example, you can choose to automatically create an inspection when a lot is moved to a specific bin.';

                    field("Warehouse Trigger"; Rec."Warehouse Trigger")
                    {
                        Caption = 'Create Inspection';
                        ApplicationArea = All;
                        ShowCaption = true;
                        AboutTitle = 'Warehouse related trigger';
                        AboutText = 'Optionally choose a warehousing related trigger to try and create an inspection.';
                    }
                    field("Whse. Move Related Triggers"; Rec."Whse. Move Related Triggers")
                    {
                        Caption = 'Related Generation Rules';
                        ApplicationArea = All;
                    }
                    field(ChooseCreateNewRule_WhseMovement; 'Create warehouse inspection rule')
                    {
                        ShowCaption = false;
                        ApplicationArea = All;

                        trigger OnDrillDown()
                        var
                            QltyWhseGenRuleWizard: Page "Qlty. Whse. Gen. Rule Wizard";
                        begin
                            CurrPage.Update(true);
                            QltyWhseGenRuleWizard.RunModal();
                            CurrPage.Update(false);
                        end;
                    }
                }
                group(SettingsForBinMovements)
                {
                    Caption = 'Bin Movements and Reclassifications';
                    InstructionalText = 'Set up the batch that will be used when moving inventory to a different bin or when changing item tracking information. The batch applies to manual Move to Bin actions, Power Automate flows, and reclassification journals.';

                    field("Bin Move Batch Name"; Rec."Bin Move Batch Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Batch Name';
                        AboutTitle = 'Batch Name (Non-Directed Pick and Put-away location)';
                        AboutText = 'The batch to use for bin movements and reclassifications for non-directed pick and put-away locations';
                    }
                    field("Bin Whse. Move Batch Name"; Rec."Bin Whse. Move Batch Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Whse. Batch Name';
                        AboutTitle = 'Batch Name (Directed Pick and Put-away location)';
                        AboutText = 'The batch to use for bin movements and reclassifications for directed pick and put-away locations';
                    }
                    field("Whse. Wksh. Name"; Rec."Whse. Wksh. Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Whse. Worksheet Name';
                        AboutTitle = 'Warehouse Worksheet Name (Directed Pick and Put-away location)';
                        AboutText = 'The warehouse worksheet name for warehouse movements for directed pick and put-away locations';
                    }
                }
                group(SettingsForAdjustments)
                {
                    Caption = 'Inventory Adjustments';
                    InstructionalText = 'The batch to use when reducing inventory quantity, such as when disposing of samples after destructive testing or writing off stock due to damage or spoilage.';

                    field("Item Adjustment Batch Name"; Rec."Adjustment Batch Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Batch Name';
                        AboutTitle = 'Batch Name (Non-Directed Pick and Put-away location)';
                        AboutText = 'The batch to use for negative inventory adjustments for non-directed pick and put-away locations';
                    }
                    field("Whse. Adjustment Batch Name"; Rec."Whse. Adjustment Batch Name")
                    {
                        ApplicationArea = All;
                        Caption = 'Whse. Batch Name';
                        AboutTitle = 'Batch Name (Directed Pick and Put-away location)';
                        AboutText = 'The batch to use for negative inventory adjustments for directed pick and put-away locations';
                    }
                }
            }
            group(SettingsForTracking)
            {
                Caption = 'Item Tracking';
                InstructionalText = 'Will your lot numbers always be posted when performing quality inspections?';

                field("Tracking Before Finishing"; Rec."Item Tracking Before Finishing")
                {
                    ApplicationArea = All;
                    AboutTitle = 'Item Tracking';
                    AboutText = 'Will your lot numbers always be posted when performing quality inspections?';
                }
                group(SettingsForTrackingInstruction1)
                {
                    Caption = 'Allow Missing Item Tracking';
                    InstructionalText = 'Use this if you do not use lot or serial numbers, or if you use them but have processes that will have inspections that will not have known lot or serial numbers. For example if you have inspections created in production that prevents the product from being produced then there may not be a lot/serial. Inspections with no lot/serial will be permitted.';
                }
                group(SettingsForTrackingInstruction2)
                {
                    Caption = 'Posted Item Tracking Only';
                    InstructionalText = 'Use this if all lot/serial numbers must be posted in the system before an inspection can be finished. For example if you are doing inspections on finished goods then the lot/serial should exist, or if you are doing inspections when lots are moved to a bin then the lot/serial must exist.';
                }
                group(SettingsForTrackingInstruction3)
                {
                    Caption = 'Reservation or Posted';
                    InstructionalText = 'Use this if lot/serial numbers need to be in the system, but might not yet be posted. An example could be lots that are being received or being produced, have not yet been received or produced yet, but do exist on your item tracking lines.';
                }
                group(SettingsForTrackingInstruction4)
                {
                    Caption = 'Any Non Empty Value';
                    InstructionalText = 'Use this if you want to track lot/serial numbers that do not enter the system but need inspections to document why they did not enter the system. For example if you reject a lot during the receiving process and a failed lot is never put-away. Alternatively if you are producing and know the intended lot/serial but the in-progress item is discarded before it is posted to inventory. Inspections with lot/serials that are not in your inventory will be permitted.';
                }
            }
            group(SettingsForMobileAndBricks)
            {
                Caption = 'Personal Device Interface';
                InstructionalText = 'Use this section to configure the available fields when looking at inspections on a mobile interface.';

                field("Brick Top Left Header"; Rec."Brick Top Left Header")
                {
                    ApplicationArea = All;
                }
                field("Brick Top Left Expression"; Rec."Brick Top Left Expression")
                {
                    ApplicationArea = All;

                    trigger OnAssistEdit()
                    begin
                        CurrPage.Update(true);
                        Rec.AssistEditBrickField(Rec.FieldNo("Brick Top Left Expression"));
                        CurrPage.Update(false);
                    end;
                }
                field("Brick Middle Left Header"; Rec."Brick Middle Left Header")
                {
                    ApplicationArea = All;
                }
                field("Brick Middle Left Expression"; Rec."Brick Middle Left Expression")
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        CurrPage.Update(true);
                        Rec.AssistEditBrickField(Rec.FieldNo("Brick Middle Left Expression"));
                        CurrPage.Update(false);
                    end;
                }
                field("Brick Middle Right Header"; Rec."Brick Middle Right Header")
                {
                    ApplicationArea = All;
                }
                field("Brick Middle Right Expression"; Rec."Brick Middle Right Expression")
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        CurrPage.Update(true);
                        Rec.AssistEditBrickField(Rec.FieldNo("Brick Middle Right Expression"));
                        CurrPage.Update(false);
                    end;
                }
                field("Brick Bottom Left Header"; Rec."Brick Bottom Left Header")
                {
                    ApplicationArea = All;
                }
                field("Brick Bottom Left Expression"; Rec."Brick Bottom Left Expression")
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        CurrPage.Update(true);
                        Rec.AssistEditBrickField(Rec.FieldNo("Brick Bottom Left Expression"));
                        CurrPage.Update(false);
                    end;
                }
                field("Brick Bottom Right Header"; Rec."Brick Bottom Right Header")
                {
                    ApplicationArea = All;
                }
                field("Brick Bottom Right Expression"; Rec."Brick Bottom Right Expression")
                {
                    ApplicationArea = All;
                    trigger OnAssistEdit()
                    begin
                        CurrPage.Update(true);
                        Rec.AssistEditBrickField(Rec.FieldNo("Brick Bottom Right Expression"));
                        CurrPage.Update(false);
                    end;
                }
                field(ChooseBrickRevertToDefaults; 'Revert To Defaults')
                {
                    ApplicationArea = All;
                    Caption = ' ';
                    ToolTip = 'Click this to use defaults for this Personal Device Interface group.';
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Rec.GetBrickHeaders(Rec."Brick Top Left Header", Rec."Brick Middle Left Header", Rec."Brick Middle Right Header", Rec."Brick Bottom Left Header", Rec."Brick Bottom Right Header");
                        Rec.GetBrickExpressions(Rec."Brick Top Left Expression", Rec."Brick Middle Left Expression", Rec."Brick Middle Right Expression", Rec."Brick Bottom Left Expression", Rec."Brick Bottom Right Expression");
                        Rec.Modify();
                    end;
                }
                field(ChooseBrickUpdateExistingInspection; 'Update Existing Inspections')
                {
                    ApplicationArea = All;
                    Caption = ' ';
                    ToolTip = 'Click this to update existing inspections with your new brick expressions.';
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown()
                    begin
                        Rec.UpdateBrickFieldsOnAllExistingInspection();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Templates)
            {
                ApplicationArea = All;
                Caption = 'Inspection Templates';
                ToolTip = 'View a list of Quality Inspection Templates. A Quality Inspection Template is an inspection plan containing a set of questions and data points that you want to collect.';
                Image = TaskQualityMeasure;
                AboutTitle = 'Quality Inspection Template';
                AboutText = 'A Quality Inspection Template is a set of questions and data points that you want to collect.';
                RunObject = Page "Qlty. Inspection Template List";
                RunPageMode = Edit;
            }
            action(GenerationRules)
            {
                ApplicationArea = All;
                Caption = 'Inspection Generation Rules';
                ToolTip = 'Specifies a Quality Inspection generation rule defines when you want to ask a set of questions defined in a template. You connect it to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template. When there are multiple matches, it will use the first template it finds, based on the sort order.';
                Image = EditFilter;
                AboutTitle = 'Quality Inspection Generation Rule';
                AboutText = 'A Quality Inspection generation rule defines when you want to ask a set of questions defined in a template. You connect it to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template. When there are multiple matches, it will use the first template it finds, based on the sort order.';
                RunObject = Page "Qlty. Inspection Gen. Rules";
                RunPageMode = Edit;
            }
            action(Results)
            {
                ApplicationArea = All;
                Caption = 'Results';
                ToolTip = 'View the Quality Inspection Results. Results are effectively the incomplete/pass/fail state of an inspection. It is typical to have three results (incomplete, fail, pass), however you can configure as many results as you want, and in what circumstances. The results with a lower number for the priority field are evaluated first. If you are not sure what to configure here then use the three defaults.';
                Image = Permission;
                AboutTitle = 'Results';
                AboutText = 'Results are effectively the incomplete/pass/fail state of an inspection. It is typical to have three results (incomplete, fail, pass), however you can configure as many results as you want, and in what circumstances. The results with a lower number for the priority field are evaluated first. If you are not sure what to configure here then use the three defaults.';
                RunObject = Page "Qlty. Inspection Result List";
                RunPageMode = Edit;
            }
        }
    }

    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        QualityManagementTok: Label 'Quality Management', Locked = true;

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('0000QID', QualityManagementTok, Enum::"Feature Uptake Status"::Discovered);
        if not Rec.Get() then begin
            QltyAutoConfigure.EnsureBasicSetupExists(false);
            if Rec.Get() then;
            FeatureTelemetry.LogUptake('0000QIE', QualityManagementTok, Enum::"Feature Uptake Status"::"Set up");
        end;

        Rec.GetBrickHeaders(Rec."Brick Top Left Header", Rec."Brick Middle Left Header", Rec."Brick Middle Right Header", Rec."Brick Bottom Left Header", Rec."Brick Bottom Right Header");
        Rec.GetBrickExpressions(Rec."Brick Top Left Expression", Rec."Brick Middle Left Expression", Rec."Brick Middle Right Expression", Rec."Brick Bottom Left Expression", Rec."Brick Bottom Right Expression");
    end;

    trigger OnClosePage()
    var
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";
    begin
        QltyApplicationAreaMgmt.RefreshExperienceTierCurrentCompany();
    end;
}
