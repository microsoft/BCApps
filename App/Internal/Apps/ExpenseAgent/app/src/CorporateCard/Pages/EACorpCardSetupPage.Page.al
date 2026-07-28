// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7226 EACorpCardSetupPage
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card Setup';
    PageType = Card;
    UsageCategory = Administration;
    SourceTable = EACorpCardSetup;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Create Mode"; Rec."Create Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how expense entries are created from imported transactions.';
                }
                field("Auto Create Draft"; Rec."Auto Create Draft")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether draft expenses should be created automatically.';
                }
                field("Date Match Window"; Rec."Date Match Window")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date tolerance used for matching.';
                }
                field("Amount Tolerance"; Rec."Amount Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount tolerance used for matching.';
                }
                field("Default Provider Code"; Rec."Default Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the default provider for corporate card imports.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get('SETUP') then begin
            Rec.Init();
            Rec."Primary Key" := 'SETUP';
            Rec.Insert();
        end;
    end;
}