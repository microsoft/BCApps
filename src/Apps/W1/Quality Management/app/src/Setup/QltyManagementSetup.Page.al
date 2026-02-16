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
using System.Telemetry;

page 20400 "Qlty. Management Setup"
{
    Caption = 'Quality Management Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTable = "Qlty. Management Setup";
    UsageCategory = Administration;
    ApplicationArea = QualityManagement;
    AboutTitle = 'Setup';
    AboutText = 'This setup page will let you define the behavior of how and when inspections are created.';

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
                        ShowCaption = true;
                        AboutTitle = 'No. Series';
                        AboutText = 'The default number series for quality inspection documents.';
                    }
                }
                group(Inspections)
                {
                    Caption = 'Creating and finding inspections';

                    field("Inspection Creation Option"; Rec."Inspection Creation Option")
                    {
                        ApplicationArea = All;
                        ShowCaption = true;
                        AboutTitle = 'Inspection Creation Option';
                        AboutText = 'Specifies whether and how a new quality inspection is created if existing inspections are found.';

                    }
                    field("Inspection Search Criteria"; Rec."Inspection Search Criteria")
                    {
                        ApplicationArea = All;
                        ShowCaption = true;
                        AboutTitle = 'Inspection Search Criteria';
                        AboutText = 'Specifies the criteria the system uses to search for existing inspections.';
                    }
                }
                group(Miscellaneous)
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
                    field("Additional Picture Handling"; Rec."Additional Picture Handling")
                    {
                        ApplicationArea = All;
                        Caption = 'Additional Picture Handling';
                        ShowCaption = true;
                        AboutTitle = 'Additional Picture Handling';
                        AboutText = 'When a picture has been taken, this value defines what to do with that picture.';
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
                    AboutTitle = 'Receiving Related Automation Settings';
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
                    AboutTitle = 'Production Related Automation Settings';
                    AboutText = 'Production related settings are configured in this group. You can choose to automatically create inspections when output is created, whether or not to update the source, and other automatic features.';

                    field("Production Order Trigger"; Rec."Production Order Trigger")
                    {
                        Caption = 'Production Order Trigger';
                        ApplicationArea = Manufacturing;
                        ShowCaption = true;
                        AboutTitle = 'Production Order related trigger';
                        AboutText = 'Optionally choose a production order related trigger to try and create an inspection.';
                    }
                    field("Prod. trigger output condition"; Rec."Prod. trigger output condition")
                    {
                        Caption = 'Prod. trigger output condition';
                        ApplicationArea = Manufacturing;
                        ShowCaption = true;
                        AboutTitle = 'Prod. trigger output condition';
                        AboutText = 'Provides granular options for when an inspection should be created automatically during the production process.';
                    }
                    field("Assembly Trigger"; Rec."Assembly Trigger")
                    {
                        Caption = 'Assembly Trigger';
                        ApplicationArea = Assembly;
                        ShowCaption = true;
                        AboutTitle = 'Assembly related trigger';
                        AboutText = 'Optionally choose an assembly-related trigger to try and create an inspection.';
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
                group(WarehouseAutomation)
                {
                    Caption = 'Inventory and Warehousing';
                    AboutTitle = 'Warehousing Related Automation Settings';
                    AboutText = 'Warehousing related settings are configured in this group. For example, you can choose to automatically create an inspection when a lot is moved to a specific bin.';

                    field("Warehouse Trigger"; Rec."Warehouse Trigger")
                    {
                        Caption = 'Warehouse Movement Trigger';
                        ApplicationArea = All;
                        ShowCaption = true;
                        AboutTitle = 'Warehouse related trigger';
                        AboutText = 'Optionally choose a warehousing related trigger to try and create an inspection.';
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
                    AboutTitle = 'Item Reclass. Batch Name (Non-Directed Pick and Put-away location)';
                    AboutText = 'The batch to use for bin movements and reclassifications for non-directed pick and put-away locations';
                }
                field("Whse. Reclass. Batch Name"; Rec."Whse. Reclass. Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Batch Name';
                    AboutTitle = 'Batch Name (Directed Pick and Put-away location)';
                    AboutText = 'The batch to use for bin movements and reclassifications for directed pick and put-away locations';
                }
                field("Movement Worksheet Name"; Rec."Movement Worksheet Name")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Worksheet Name';
                    AboutTitle = 'Warehouse Worksheet Name (Directed Pick and Put-away location)';
                    AboutText = 'The warehouse worksheet name for warehouse movements for directed pick and put-away locations';
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
                    AboutTitle = 'Batch Name (Non-Directed Pick and Put-away location)';
                    AboutText = 'The batch to use for negative inventory adjustments for non-directed pick and put-away locations';
                }
                field("Whse. Item Journal Batch Name"; Rec."Whse. Item Journal Batch Name")
                {
                    ApplicationArea = All;
                    Caption = 'Whse. Batch Name';
                    AboutTitle = 'Batch Name (Directed Pick and Put-away location)';
                    AboutText = 'The batch to use for negative inventory adjustments for directed pick and put-away locations';
                }
            }

            group(Tracking)
            {
                Caption = 'Item Tracking';
                InstructionalText = 'Will your item tracking numbers always be posted when performing quality inspections?';

                field("Tracking Before Finishing"; Rec."Item Tracking Before Finishing")
                {
                    ApplicationArea = All;
                    AboutTitle = 'Item Tracking';
                    AboutText = 'Will your item tracking numbers always be posted when performing quality inspections?';
                }
                field("Inspection Selection Criteria"; Rec."Inspection Selection Criteria")
                {
                    ApplicationArea = All;
                    ShowCaption = true;
                    AboutTitle = 'Which inspections to inspect when analyzing document specific item tracking blocking.';
                    AboutText = 'Specifies the tests the system uses to decide if a document-specific transaction should be blocked.';
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
                Image = BreakpointsList;
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
                Image = FilterLines;
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
                Image = ViewRegisteredOrder;
                AboutTitle = 'Results';
                AboutText = 'Results are effectively the incomplete/pass/fail state of an inspection. It is typical to have three results (incomplete, fail, pass), however you can configure as many results as you want, and in what circumstances. The results with a lower number for the priority field are evaluated first. If you are not sure what to configure here then use the three defaults.';
                RunObject = Page "Qlty. Inspection Result List";
                RunPageMode = Edit;
            }
            action(Tests)
            {
                ApplicationArea = All;
                Caption = 'Tests';
                ToolTip = 'View the Quality Tests. Tests define data points, questions, measurements, and entries with their allowable values and default passing thresholds. You can later use these tests in Quality Inspection Templates.';
                Image = Task;
                AboutTitle = 'Tests';
                AboutText = 'Tests define data points, questions, measurements, and entries with their allowable values and default passing thresholds. You can later use these tests in Quality Inspection Templates.';
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
                    ToolTip = 'View the Quality Inspection Source Configurations. This page defines how data is automatically populated into quality inspections from other tables, including how records are linked between source and target tables. It is read-only in most scenarios and intended for advanced configuration.';
                    Image = Relationship;
                    AboutTitle = 'Source Configurations';
                    AboutText = 'Quality inspection source configurations define how data is automatically populated into quality inspections from other tables, including how records are linked between source and target tables. It is read-only in most scenarios and intended for advanced configuration.';
                    RunObject = Page "Qlty. Ins. Source Config. List";
                    RunPageMode = View;
                }
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
    end;

    trigger OnClosePage()
    var
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";
    begin
        QltyApplicationAreaMgmt.RefreshExperienceTierCurrentCompany();
    end;
}
