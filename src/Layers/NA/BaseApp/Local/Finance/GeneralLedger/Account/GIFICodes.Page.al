// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Reports;
using System.Telemetry;

page 10017 "GIFI Codes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'GIFI Codes';
    PageType = List;
    SourceTable = "GIFI Code";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1020000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = BasicCA;
                    ToolTip = 'Specifies a General Index of Financial Information (GIFI) code. This code can be associated with records in the G/L Account table.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = BasicCA;
                    ToolTip = 'Specifies the name (or description) of a General Index of Financial Information (GIFI) code.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Export GIFI Info. to Excel")
            {
                ApplicationArea = BasicCA;
                Caption = 'Export GIFI Info. to Excel';
                RunObject = Report "Export GIFI Info. to Excel";
                ToolTip = 'Export balance information using General Index of Financial Information (GIFI) codes and save the exported file in Excel. You can use the file to transfer information to your tax preparation software.';

                trigger OnAction()
                begin
                    FeatureTelemetry.LogUptake('1000HM8', CanGIFITok, Enum::"Feature Uptake Status"::"Used");
                    FeatureTelemetry.LogUsage('1000HM9', CanGIFITok, 'Canada GIDI Codes Infro Exported');
                end;
            }
        }
        area(reporting)
        {
            action("Account Balances by GIFI Code")
            {
                ApplicationArea = BasicCA;
                Caption = 'Account Balances by GIFI Code';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Account Balances by GIFI Code";
                ToolTip = 'Review your account balances by General Index of Financial Information (GIFI) code using the Account Balances by GIFI Code report.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Export GIFI Info. to Excel_Promoted"; "Export GIFI Info. to Excel")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('1000HM6', CanGIFITok, Enum::"Feature Uptake Status"::Discovered);
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        CanGIFITok: Label 'Canada GIDI Codes', Locked = true;
}

