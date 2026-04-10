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
#if not CLEAN27
                field("Content Max Lines"; Rec."Content Max Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Max. No. of Lines';
                    ToolTip = 'Specifies the maximum number of lines in each message.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Moved to GovTalk app';
                    ObsoleteTag = '27.0';

                    trigger OnValidate()
                    begin
                        if
                           (Rec."VAT Report Type" = Rec."VAT Report Type"::"VAT Return") and
                           (Rec."Content Max Lines" <> 0)
                        then
                            Error(NotApplicableErr);

                        if Rec."Content Max Lines" < 0 then
                            Error(MinValueErr);
                    end;
                }
#endif
            }
        }
    }

    actions
    {
    }

#if not CLEAN27
    var
        NotApplicableErr: Label 'This value is only applicable for EC Sales list report.';
        MinValueErr: Label 'The value of Max. No. of Lines must be bigger than zero.';
#endif
}

