// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Document;
using System.Telemetry;

page 15000301 "Recurring Group Overview"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Recurring Groups';
    CardPageID = "Recurring Groups Card";
    Editable = false;
    PageType = List;
    SourceTable = "Recurring Group";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code to identify the recurring group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description to identify the recurring group.';
                }
                field("Date formula"; Rec."Date formula")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date formula to calculate the time interval between orders.';
                }
                field("Starting date"; Rec."Starting date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first date of the recurring group.';
                }
                field("Closing date"; Rec."Closing date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last date of the recurring group.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('1000HV0', NORecurringOrderTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NORecurringOrderTok: Label 'NO Recurring Order', Locked = true;
}

