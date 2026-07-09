// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8373 "Fin. Report Package Schedules"
{
    AnalysisModeEnabled = false;
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Package Schedules';
    DataCaptionFields = "Package Code";
    PageType = List;
    SourceTable = "Fin. Report Package Schedule";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Package Code"; Rec."Package Code")
                {
                    Visible = false;
                }
                field("Schedule Code"; Rec."Schedule Code")
                {
                    ShowMandatory = true;
                }
                field(Name; Rec.Name) { }
                field("Send Email"; Rec."Send Email") { }
                field("No. of Recipients"; Rec."No. of Recipients") { }
                field("Next Run Date/Time"; Rec."Next Run Date/Time")
                {
                    ShowMandatory = true;
                }
                field("Recurrence Run Date Formula"; Rec."Recurrence Run Date Formula") { }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Recipients)
            {
                Caption = 'Recipients';
                Image = Users;
                RunObject = page "Fin. Report Package Recipients";
                RunPageLink = "Package Code" = field("Package Code"), "Schedule Code" = field("Schedule Code");
                RunPageMode = Edit;
            }
            action(Logs)
            {
                Caption = 'Logs';
                Image = Log;
                RunObject = page "Fin. Rep. Package Export Logs";
                RunPageLink = "Package Code" = field("Package Code"), "Schedule Code" = field("Schedule Code");
                RunPageMode = View;
            }
        }
        area(Promoted)
        {
            actionref(Recipients_Promoted; Recipients) { }
            actionref(Logs_Promoted; Logs) { }
        }
    }
}