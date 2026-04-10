// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Setup;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.WIP;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Pricing;
using System.Telemetry;

table 315 "Jobs Setup"
{
    Caption = 'Projects Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Jobs Setup";
    LookupPageID = "Jobs Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Job Nos."; Code[20])
        {
            Caption = 'Project Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to projects. To see the number series that have been set up in the No. Series table, click the drop-down arrow in the field.';
            TableRelation = "No. Series";
        }
        field(3; "Apply Usage Link by Default"; Boolean)
        {
            Caption = 'Apply Usage Link by Default';
            ToolTip = 'Specifies whether project ledger entries are linked to project planning lines by default. Select this check box if you want to apply this setting to all new projects that you create.';
            InitValue = true;
        }
        field(4; "Default WIP Method"; Code[20])
        {
            Caption = 'Default WIP Method';
            ToolTip = 'Specifies the default method to be used for calculating work in process (WIP). It is applied whenever you create a new project, but you can modify the value on the project card.';
            TableRelation = "Job WIP Method".Code;
        }
        field(5; "Default Job Posting Group"; Code[20])
        {
            Caption = 'Default Project Posting Group';
            ToolTip = 'Specifies the default posting group to be applied when you create a new project. This group is used whenever you create a project, but you can modify the value on the project card.';
            TableRelation = "Job Posting Group".Code;
        }
        field(6; "Default WIP Posting Method"; Option)
        {
            Caption = 'Default WIP Posting Method';
            ToolTip = 'Specifies how the default WIP method is to be applied when posting Work in Process (WIP) to the general ledger. By default, it is applied per project.';
            OptionCaption = 'Per Project,Per Project Ledger Entry';
            OptionMembers = "Per Job","Per Job Ledger Entry";
        }
        field(7; "Allow Sched/Contract Lines Def"; Boolean)
        {
            Caption = 'Allow Sched/Contract Lines Def';
            ToolTip = 'Specifies whether project lines can be of type Both Budget and Billable by default. Select this check box if you want to apply this setting to all new projects that you create.';
            InitValue = true;
        }
        field(9; "Document No. Is Job No."; Boolean)
        {
            Caption = 'Document No. Is Project No.';
            ToolTip = 'Specifies that the project number is also the document number in the ledger entries posted for the project.';
            InitValue = true;
        }
        field(10; "Default Task Billing Method"; Enum "Task Billing Method")
        {
            Caption = 'Default Task Billing Method';
            ToolTip = 'Specify whether to use the customer specified for the project for all tasks or allow people to specify different customers. One customer lets you invoice only the customer specified for the project. Multiple customers lets you invoice customers specified on each task, which can be different customers.';
            DataClassification = CustomerContent;
        }
        field(31; "Logo Position on Documents"; Option)
        {
            Caption = 'Logo Position on Documents';
            ToolTip = 'Specifies the position of your company logo on business letters and documents.';
            OptionCaption = 'No Logo,Left,Center,Right';
            OptionMembers = "No Logo",Left,Center,Right;
        }
        field(40; "Job WIP Nos."; Code[20])
        {
            Caption = 'Project WIP Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to project WIP documents. To see the number series that have been set up in the No. Series table, click the drop-down arrow in the field.';
            TableRelation = "No. Series";
        }
        field(50; "Archive Jobs"; Option)
        {
            Caption = 'Archive Projects';
            ToolTip = 'Specifies if you want to automatically archive projects when: deleted, status changed, when project or project task quote sent to customer or related sales invoice posted.';
            OptionCaption = 'Never,Question,Always';
            OptionMembers = Never,Question,Always;
            DataClassification = CustomerContent;
        }
        field(1001; "Automatic Update Job Item Cost"; Boolean)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Automatic Update Project Item Cost';
            ToolTip = 'Specifies in the Projects Setup window that cost changes are automatically adjusted each time the Adjust Cost - Item Entries batch job is run. The adjustment process and its results are the same as when you run the Update Project Item Cost batch job.';
        }
        field(7000; "Price List Nos."; Code[20])
        {
            Caption = 'Price List Nos.';
            ToolTip = 'Specifies the code for the number series that will be used to assign numbers to project price lists.';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
        field(7003; "Default Sales Price List Code"; Code[20])
        {
            Caption = 'Default Sales Price List Code';
            ToolTip = 'Specifies the code of the existing sales price list that stores all new price lines created in the price worksheet page.';
            TableRelation = "Price List Header" where("Price Type" = const(Sale), "Source Group" = const(Job), "Allow Updating Defaults" = const(true));
            DataClassification = CustomerContent;
            trigger OnLookup()
            var
                PriceListHeader: Record "Price List Header";
            begin
                if Page.RunModal(Page::"Sales Job Price Lists", PriceListHeader) = Action::LookupOK then begin
                    PriceListHeader.TestField("Allow Updating Defaults");
                    Validate("Default Sales Price List Code", PriceListHeader.Code);
                end;
            end;

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
            begin
                if ("Default Sales Price List Code" <> xRec."Default Sales Price List Code") or (CurrFieldNo = 0) then
                    FeatureTelemetry.LogUptake('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
            end;
        }
        field(7004; "Default Purch Price List Code"; Code[20])
        {
            Caption = 'Default Purchase Price List Code';
            ToolTip = 'Specifies the code of the existing purchase price list that stores all new price lines created in the price worksheet page.';
            TableRelation = "Price List Header" where("Price Type" = const(Purchase), "Source Group" = const(Job), "Allow Updating Defaults" = const(true));
            DataClassification = CustomerContent;
            trigger OnLookup()
            var
                PriceListHeader: Record "Price List Header";
            begin
                if Page.RunModal(Page::"Purchase Job Price Lists", PriceListHeader) = Action::LookupOK then begin
                    PriceListHeader.TestField("Allow Updating Defaults");
                    Validate("Default Purch Price List Code", PriceListHeader.Code);
                end;
            end;

            trigger OnValidate()
            var
                FeatureTelemetry: Codeunit "Feature Telemetry";
                PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
            begin
                if ("Default Purch Price List Code" <> xRec."Default Purch Price List Code") or (CurrFieldNo = 0) then
                    FeatureTelemetry.LogUptake('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
            end;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure UseLegacyPosting(): Boolean
    var
        FeatureKeyManagement: Codeunit System.Environment.Configuration."Feature Key Management";
    begin
        exit(not FeatureKeyManagement.IsConcurrentJobPostingEnabled());
    end;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    var
        RecordHasBeenRead: Boolean;
}

