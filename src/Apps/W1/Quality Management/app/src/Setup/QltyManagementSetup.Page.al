// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

using Microsoft.QualityManagement.Configuration;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.SourceConfiguration;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.QualityManagement.Telemetry;
using System.Environment;

page 20400 "Qlty. Management Setup"
{
    Caption = 'Quality Management Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTable = "Qlty. Management Setup";
    UsageCategory = Administration;
    ApplicationArea = QualityManagement;
    AboutTitle = 'About Quality Management Setup';
    AboutText = 'Manage default settings for when and how inspections are created. Set up test generation rule triggers for production, inventory, and warehouse scenarios.';

    layout
    {
        area(Content)
        {
            group(Defaults)
            {
                Caption = 'General';
                group(Numbering)
                {
                    Caption = 'Number Series';

                    field("Quality Inspection Nos."; Rec."Quality Inspection Nos.")
                    {
                        ApplicationArea = All;
                    }
                }
                group(Inspections)
                {
                    Caption = 'Creating and finding inspections';

                    field("Inspection Creation Option"; Rec."Inspection Creation Option")
                    {
                        ApplicationArea = All;
                        AboutTitle = 'Inspection creation option';
                        AboutText = 'Control if new quality inspections should be created when similar inspections already exist.';
                    }
                    field("Inspection Search Criteria"; Rec."Inspection Search Criteria")
                    {
                        ApplicationArea = All;
                    }
                }
                group(Miscellaneous)
                {
                    Caption = 'Miscellaneous';

                    field("CoA Contact No."; Rec."Certificate Contact No.")
                    {
                        ApplicationArea = All;
                    }
                    field("Max Rows Field Lookups"; Rec."Max Rows Field Lookups")
                    {
                        Importance = Additional;
                        ApplicationArea = All;
                    }
                    field("Additional Picture Handling"; Rec."Additional Picture Handling")
                    {
                        ApplicationArea = All;
                        Caption = 'Additional Picture Handling';
                    }
                }
            }
            group(GenerationRuleTriggerDefaults)
            {
                Caption = 'Generation Rule Trigger Defaults';
                InstructionalText = 'Manage receiving, production, and warehousing options here, such as automatically creating inspections when receipts or output are posted, and defining default automation and trigger settings for inspection generation rules.';

                group(ReceiveAutomation)
                {
                    Caption = 'Receiving';
                    AboutTitle = 'Receiving automation settings';
                    AboutText = 'Receiving related settings are configured in this group. For example, you can choose to automatically create an inspection when a receipt is posted.';

                    field("Warehouse Receipt Trigger"; Rec."Warehouse Receipt Trigger")
                    {
                        ApplicationArea = All;
                        Caption = 'Warehouse Receipts Trigger';
                    }
                    field("Purchase Order Trigger"; Rec."Purchase Order Trigger")
                    {
                        ApplicationArea = All;
                        Caption = 'Purchase Orders Trigger';
                    }
                    field("Sales Return Trigger"; Rec."Sales Return Trigger")
                    {
                        ApplicationArea = All;
                        Caption = 'Sales Returns Trigger';
                    }
                    field("Transfer Order Trigger"; Rec."Transfer Order Trigger")
                    {
                        ApplicationArea = All;
                        Caption = 'Transfer Orders Trigger';
                    }
                }
                group(ProductionAutomation)
                {
                    Caption = 'Production';
                    AboutTitle = 'Production automation settings';
                    AboutText = 'Production related settings are configured in this group. You can choose to automatically create inspections when output is created, whether or not to update the source, and other automatic features.';

                    field("Production Order Trigger"; Rec."Production Order Trigger")
                    {
                        Caption = 'Production Order Trigger';
                        ApplicationArea = Manufacturing;
                    }
                    field("Prod. trigger output condition"; Rec."Prod. trigger output condition")
                    {
                        Caption = 'Prod. trigger output condition';
                        ApplicationArea = Manufacturing;
                    }
                    field("Assembly Trigger"; Rec."Assembly Trigger")
                    {
                        Caption = 'Assembly Trigger';
                        ApplicationArea = Assembly;
                    }
                    field("Production Update Control"; Rec."Production Update Control")
                    {
                        ApplicationArea = Manufacturing;
                        Importance = Additional;
                        Visible = false;
                    }
                }
                group(WarehouseAutomation)
                {
                    Caption = 'Inventory and Warehousing';
                    AboutTitle = 'Warehouse automation settings';
                    AboutText = 'Warehousing related settings are configured in this group. For example, you can choose to automatically create an inspection when a lot is moved to a specific bin.';

                    field("Warehouse Trigger"; Rec."Warehouse Trigger")
                    {
                        Caption = 'Warehouse Movement Trigger';
                        ApplicationArea = All;
                    }
                }
            }
            group(BinMovements)
            {
                Caption = 'Bin Movements and Reclassifications';
                InstructionalText = 'Set up the batch that will be used when moving inventory to a different bin or when changing item tracking information. The batch applies to manual Move to Bin actions, Power Automate flows, and reclassification journals.';

                field("Item Reclass. Batch Name"; Rec."Item Reclass. Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Item Reclass. Batch Name';
                }
                field("Whse. Reclass. Batch Name"; Rec."Whse. Reclass. Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Batch Name';
                }
                field("Movement Worksheet Name"; Rec."Movement Worksheet Name")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Worksheet Name';
                }
            }
            group(Adjustments)
            {
                Caption = 'Inventory Adjustments';
                InstructionalText = 'The batch to use when reducing inventory quantity, such as when disposing of samples after destructive testing or writing off stock due to damage or spoilage.';

                field("Item Item Journal Batch Name"; Rec."Item Journal Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Batch Name';
                }
                field("Whse. Item Journal Batch Name"; Rec."Whse. Item Journal Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Batch Name';
                }
            }

            group(Tracking)
            {
                Caption = 'Item Tracking';
                InstructionalText = 'Will your item tracking numbers always be posted when performing quality inspections?';

                field("Tracking Before Finishing"; Rec."Item Tracking Before Finishing")
                {
                    ApplicationArea = All;
                }
                field("Inspection Selection Criteria"; Rec."Inspection Selection Criteria")
                {
                    ApplicationArea = All;
                    AboutTitle = 'Inspections for document-specific blocking';
                    AboutText = 'Define how to select the quality inspections the system uses to decide whether a document transaction should be blocked for a lot or serial number.';
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
                ToolTip = 'Quality inspection templates are inspection plans that contain a set of tests to perform.';
                Image = BreakpointsList;
                RunObject = Page "Qlty. Inspection Template List";
                RunPageMode = Edit;
            }
            action(GenerationRules)
            {
                ApplicationArea = All;
                Caption = 'Inspection Generation Rules';
                ToolTip = 'Quality inspection generation rules specify when quality inspections are automatically generated and which template is used, such as during receiving, production, or warehouse activities. You link a template to a source table and define filter criteria that determine when an inspection is created. When the criteria are met, the system generates a quality inspection based on the linked template. If multiple rules match, the system uses the first rule according to the sort order.';
                Image = CopyFromTask;
                RunObject = Page "Qlty. Inspection Gen. Rules";
                RunPageMode = Edit;
            }
            action(Results)
            {
                ApplicationArea = All;
                Caption = 'Results';
                ToolTip = 'Quality inspection results represent the outcome of an inspection or test, such as incomplete, fail, or pass. You can configure multiple results and define their evaluation order based on priority. The system evaluates results with lower priority numbers first.';
                Image = ViewRegisteredOrder;
                RunObject = Page "Qlty. Inspection Result List";
                RunPageMode = Edit;
            }
            action(Tests)
            {
                ApplicationArea = All;
                Caption = 'Tests';
                ToolTip = 'Quality tests are defined data points, checks, questions or measurements used to evaluate quality. Tests can be configured with allowable values and default passing thresholds, and are used in quality inspection templates.';
                Image = TaskQualityMeasure;
                RunObject = Page "Qlty. Tests";
                RunPageMode = Edit;
            }
            group(Advanced)
            {
                Caption = 'Advanced';

                action(SourceConfigurations)
                {
                    ApplicationArea = QualityManagement;
                    Caption = 'Source Configurations';
                    ToolTip = 'View the quality inspection source configurations. This page defines how data is automatically populated into quality inspections from other tables, including how records are linked between source and target tables.';
                    Image = Relationship;
                    RunObject = Page "Qlty. Ins. Source Config. List";
                    RunPageMode = View;
                }
            }
        }
        area(Processing)
        {
            action(InstallDemoData)
            {
                ApplicationArea = QualityManagement;
                Caption = 'Install Demo Data';
                ToolTip = 'Install the Quality Management Contoso Coffee Demo Dataset app to explore Quality Management with sample data.';
                Image = Database;
                Visible = IsSaaS;

                trigger OnAction()
                var
                    QltyDemoDataMgmt: Codeunit "Qlty. Demo Data Mgmt.";
                begin
                    QltyDemoDataMgmt.InstallOrOpenDemoData();
                end;
            }
        }
    }

    var
        QltyAutoConfigure: Codeunit "Qlty. Auto Configure";
        IsSaaS: Boolean;

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        QltyMgmtFeatureTelemetry: Codeunit "Qlty. Mgmt. Feature Telemetry";
    begin
        IsSaaS := EnvironmentInformation.IsSaaS();

        QltyMgmtFeatureTelemetry.LogFeatureUptakeDiscovered(ObjectType::Page, Page::"Qlty. Management Setup");

        if not Rec.Get() then begin
            QltyAutoConfigure.EnsureBasicSetupExists(false);
            if Rec.Get() then;
            QltyMgmtFeatureTelemetry.LogFeatureUptakeSetUp(ObjectType::Page, Page::"Qlty. Management Setup");
        end;
    end;

    trigger OnClosePage()
    var
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";
    begin
        QltyApplicationAreaMgmt.RefreshExperienceTierCurrentCompany();
    end;
}
