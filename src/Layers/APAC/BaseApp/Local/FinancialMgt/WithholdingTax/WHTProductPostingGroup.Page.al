// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using System.Telemetry;

page 28041 "WHT Product Posting Group"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WHT Product Posting Group';
    PageType = List;
    SourceTable = "WHT Product Posting Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1500000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code for the posting group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the WHT Product posting group.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Setup';
                Image = Setup;
                RunObject = Page "WHT Posting Setup";
                RunPageLink = "WHT Product Posting Group" = field(Code);
                ToolTip = 'View or edit the withholding tax (WHT) posting setup information. This includes posting groups, revenue types, and accounts.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Setup_Promoted"; "&Setup")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('0000HH3', APACWHTTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        APACWHTTok: Label 'APAC Set Up Withholding Tax', Locked = true;
}

