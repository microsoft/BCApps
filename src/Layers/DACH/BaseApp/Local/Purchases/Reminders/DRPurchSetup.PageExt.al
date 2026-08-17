// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Setup;

using System.Telemetry;

pageextension 5005272 DRPurchSetup extends "Purchases & Payables Setup"
{
    layout
    {
        addafter("Check Prepmt. when Posting")
        {
            field("Default Del. Rem. Date Field"; Rec."Default Del. Rem. Date Field")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the date field of the purchase order line corresponding to the creation of delivery reminders.';

                trigger OnValidate()
                var
                    FeatureTelemetry: Codeunit "Feature Telemetry";
                    DeliverTok: Label 'DACH Delivery Reminder', Locked = true;
                begin
                    FeatureTelemetry.LogUptake('0001Q0Q', DeliverTok, Enum::"Feature Uptake Status"::Discovered);
                end;
            }
        }
        addafter("Price List Nos.")
        {
            field("Delivery Reminder Nos."; Rec."Delivery Reminder Nos.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number series code used to assign numbers to delivery reminders.';
            }
            field("Issued Delivery Reminder Nos."; Rec."Issued Delivery Reminder Nos.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number series code used to assign numbers to delivery reminders when they are issued.';
            }
        }
    }
}
