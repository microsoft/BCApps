// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Configuration interface for VAT report types and processing codeunits.
/// Manages codeunit assignments for suggest lines, validation, and submission processes.
/// </summary>
page 746 "VAT Reports Configuration"
{
    ApplicationArea = VAT;
    Caption = 'VAT Reports Configuration';
    PageType = List;
    SourceTable = "VAT Reports Configuration";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("VAT Report Type"; Rec."VAT Report Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Report Version"; Rec."VAT Report Version")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Suggest Lines Codeunit ID"; Rec."Suggest Lines Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Suggest Lines Codeunit Caption"; Rec."Suggest Lines Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Content Codeunit ID"; Rec."Content Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Content Codeunit Caption"; Rec."Content Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Submission Codeunit ID"; Rec."Submission Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Submission Codeunit Caption"; Rec."Submission Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Response Handler Codeunit ID"; Rec."Response Handler Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Resp. Handler Codeunit Caption"; Rec."Resp. Handler Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Validate Codeunit ID"; Rec."Validate Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Validate Codeunit Caption"; Rec."Validate Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }
}

