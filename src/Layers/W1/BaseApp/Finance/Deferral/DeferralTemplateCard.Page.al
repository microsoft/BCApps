// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

/// <summary>
/// Card page for creating and editing deferral templates.
/// Provides interface for defining deferral calculation methods, accounts, and schedule parameters.
/// </summary>
page 1700 "Deferral Template Card"
{
    Caption = 'Deferral Template Card';
    SourceTable = "Deferral Template";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Deferral Code"; Rec."Deferral Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a code for deferral template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field("Deferral Account"; Rec."Deferral Account")
                {
                    ApplicationArea = Suite;
                    ShowMandatory = true;
                }
            }
            group("Deferral Schedule")
            {
                Caption = 'Deferral Schedule';
                field("Deferral %"; Rec."Deferral %")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ShowMandatory = true;
                }
                field("Calc. Method"; Rec."Calc. Method")
                {
                    ApplicationArea = Suite;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Suite;
                }
                field("No. of Periods"; Rec."No. of Periods")
                {
                    ApplicationArea = Suite;
                    ShowMandatory = true;
                }
                field("Period Description"; Rec."Period Description")
                {
                    ApplicationArea = Suite;
                    Caption = 'Period Desc.';
                }
            }
        }
    }

    actions
    {
    }
}

