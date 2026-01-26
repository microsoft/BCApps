// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using System.Telemetry;

page 15000010 "Remittance Agreement Overview"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Remittance Agreement Overview';
    CardPageID = "Remittance Agreement Card";
    Editable = false;
    PageType = List;
    SourceTable = "Remittance Agreement";
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
                    ToolTip = 'Sets a unique ID for the remittance agreement.';

                    trigger OnValidate()
                    begin
                        FeatureTelemetry.LogUptake('1000HU2', NORemittanceAgreementTok, Enum::"Feature Uptake Status"::"Set up");
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the remittance agreement.';
                }
                field("Payment System"; Rec."Payment System")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the available payment systems.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('1000HU1', NORemittanceAgreementTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        NORemittanceAgreementTok: Label 'NO Set Up Remittance Agreement', Locked = true;
}

