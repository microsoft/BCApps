// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using System.Telemetry;

/// <summary>
/// List page for browsing and managing deferral templates.
/// Provides overview of all available deferral templates and navigation to the template card.
/// </summary>
page 1701 "Deferral Template List"
{
    ApplicationArea = Suite;
    Caption = 'Deferral Templates';
    CardPageID = "Deferral Template Card";
    Editable = false;
    PageType = List;
    SourceTable = "Deferral Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control6)
            {
                ShowCaption = false;
                field("Deferral Code"; Rec."Deferral Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Deferral Code';
                    ToolTip = 'Specifies the code for the deferral template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the record.';
                }
                field("Deferral Account"; Rec."Deferral Account")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the G/L account that the deferred expenses are posted to.';
                }
                field("Deferral %"; Rec."Deferral %")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how much of the total amount will be deferred.';
                }
                field("Calc. Method"; Rec."Calc. Method")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how the Amount field for each period is calculated. Straight-Line: Calculated per the number of periods, distributed by period length. Equal Per Period: Calculated per the number of periods, distributed evenly on periods. Days Per Period: Calculated per the number of days in the period. User-Defined: Not calculated. You must manually fill the Amount field for each period.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when to start calculating deferral amounts.';
                }
                field("No. of Periods"; Rec."No. of Periods")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how many accounting periods the total amounts will be deferred to.';
                }
                field("Period Description"; Rec."Period Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Period Desc.';
                    ToolTip = 'Specifies a description that will be shown on entries for the deferral posting.';
                }
            }
        }
    }

    actions
    {
    }
    trigger OnOpenPage();
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000KLD', 'Deferral', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000KMS', 'Deferral', Enum::"Feature Uptake Status"::"Set up");
    end;
}

