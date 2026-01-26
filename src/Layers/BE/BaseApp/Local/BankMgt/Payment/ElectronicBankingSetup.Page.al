// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Telemetry;

page 11308 "Electronic Banking Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Electronic Banking Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Electronic Banking Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Summarize Gen. Jnl. Lines"; Rec."Summarize Gen. Jnl. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to summarize the payment journal lines by vendor, when you transfer the electronic banking journal lines.';
                }
                field("Cut off Payment Message Texts"; Rec."Cut off Payment Message Texts")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want the payment message text to be truncated.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        BEElecBankTok: Label 'BE Electronic Banking', Locked = true;
    begin
        FeatureTelemetry.LogUptake('1000HL4', BEElecBankTok, Enum::"Feature Uptake Status"::Discovered);
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

