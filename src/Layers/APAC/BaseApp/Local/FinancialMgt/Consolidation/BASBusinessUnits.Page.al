// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Telemetry;

page 11604 "BAS Business Units"
{
    ApplicationArea = Basic, Suite;
    Caption = 'BAS Business Units';
    PageType = List;
    SourceTable = "BAS Business Unit";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company, which will be added to the Group Company''s BAS.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BAS document that you want to consolidate.';
                }
                field("BAS Version"; Rec."BAS Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BAS version number that the transaction was included in, and operates in conjunction with the BAS Doc. No.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Import Subsidiary")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import Subsidiary';
                Image = Import;
                RunObject = Codeunit "Import Subsidiary";
                ToolTip = 'Import Subsidiary';
            }
        }
    }

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('0000HK8', APACBASTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    trigger OnInit()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        APACBASTok: Label 'APAC Business Activity Statement', Locked = true;
}

