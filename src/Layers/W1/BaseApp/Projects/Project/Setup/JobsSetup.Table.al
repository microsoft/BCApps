// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Setup;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.WIP;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Pricing;
using System.Telemetry;
using Microsoft.Pricing.Calculation;

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
            TableRelation = "No. Series";
        }
        field(3; "Apply Usage Link by Default"; Boolean)
        {
            Caption = 'Apply Usage Link by Default';
            InitValue = true;
        }
        field(4; "Default WIP Method"; Code[20])
        {
            Caption = 'Default WIP Method';
            TableRelation = "Job WIP Method".Code;
        }
        field(5; "Default Job Posting Group"; Code[20])
        {
            Caption = 'Default Project Posting Group';
            TableRelation = "Job Posting Group".Code;
        }
        field(6; "Default WIP Posting Method"; Option)
        {
            Caption = 'Default WIP Posting Method';
            OptionCaption = 'Per Project,Per Project Ledger Entry';
            OptionMembers = "Per Job","Per Job Ledger Entry";
        }
        field(7; "Allow Sched/Contract Lines Def"; Boolean)
        {
            Caption = 'Allow Sched/Contract Lines Def';
            InitValue = true;
        }
        field(9; "Document No. Is Job No."; Boolean)
        {
            Caption = 'Document No. Is Project No.';
            InitValue = true;
        }
        field(10; "Default Task Billing Method"; Enum "Task Billing Method")
        {
            Caption = 'Default Task Billing Method';
            DataClassification = CustomerContent;
        }
        field(31; "Logo Position on Documents"; Option)
        {
            Caption = 'Logo Position on Documents';
            OptionCaption = 'No Logo,Left,Center,Right';
            OptionMembers = "No Logo",Left,Center,Right;
        }
        field(40; "Job WIP Nos."; Code[20])
        {
            Caption = 'Project WIP Nos.';
            TableRelation = "No. Series";
        }
        field(50; "Archive Jobs"; Option)
        {
            Caption = 'Archive Projects';
            OptionCaption = 'Never,Question,Always';
            OptionMembers = Never,Question,Always;
            DataClassification = CustomerContent;
        }
        field(1001; "Automatic Update Job Item Cost"; Boolean)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Automatic Update Project Item Cost';
        }
        field(7000; "Price List Nos."; Code[20])
        {
            Caption = 'Price List Nos.';
            TableRelation = "No. Series";
            DataClassification = CustomerContent;
        }
        field(7003; "Default Sales Price List Code"; Code[20])
        {
            Caption = 'Default Sales Price List Code';
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

