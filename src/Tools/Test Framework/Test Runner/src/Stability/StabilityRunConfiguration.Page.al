// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Lets the user review and edit the stability preset combinations that are executed for a base
/// test suite. Each line is a configuration string, for example SEED-2+WORKDATEFUTURE-1YEAR.
/// </summary>
page 130476 "Stability Run Configuration"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Stability Run Configuration";
    Caption = 'Stability Run Configuration';
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Configurations)
            {
                field("Base Suite"; Rec."Base Suite")
                {
                    ToolTip = 'Specifies the base test suite the combination applies to.';
                }
                field("Configuration"; Rec."Configuration")
                {
                    ToolTip = 'Specifies the stability preset combination, for example SEED-2+WORKDATEFUTURE-1YEAR. Combine tokens with ''+''. Tokens: SEED-<n>, WORKDATEFUTURE-<n>YEAR, WORKDATEFUTURE-<n>MONTH, ONEBYONE, REVERSE-CODEUNITS, REVERSE-METHODS, BASELINE.';
                }
                field("Enabled"; Rec."Enabled")
                {
                    ToolTip = 'Specifies whether the combination is executed when the stability run starts.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        StabilityRunConfiguration: Record "Stability Run Configuration";
        BaseSuiteFilter: Code[10];
    begin
        BaseSuiteFilter := CopyStr(Rec.GetFilter("Base Suite"), 1, MaxStrLen(BaseSuiteFilter));
        if BaseSuiteFilter <> '' then begin
            Rec."Base Suite" := BaseSuiteFilter;
            StabilityRunConfiguration.SetRange("Base Suite", BaseSuiteFilter);
        end;
        if StabilityRunConfiguration.FindLast() then
            Rec."Line No." := StabilityRunConfiguration."Line No." + 10000
        else
            Rec."Line No." := 10000;
    end;
}
