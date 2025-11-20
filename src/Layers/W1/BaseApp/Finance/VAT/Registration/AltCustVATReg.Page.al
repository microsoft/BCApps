// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using System.Telemetry;

page 212 "Alt. Cust. VAT Reg."
{
    Caption = 'Alternative Customer VAT Registration';
    DataCaptionExpression = '';
    PageType = List;
    SourceTable = "Alt. Cust. VAT Reg.";
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Country/Region Code"; Rec."VAT Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    var
        FeatureNameTxt: Label 'Alternative Customer VAT Registration', Locked = true;

    trigger OnOpenPage();
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000NFG', FeatureNameTxt, Enum::"Feature Uptake Status"::Discovered);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec.GetFilter("Customer No.") <> '' then
            Rec."Customer No." := CopyStr(Rec.GetFilter("Customer No."), 1, MaxStrLen(Rec."Customer No."));
    end;
}