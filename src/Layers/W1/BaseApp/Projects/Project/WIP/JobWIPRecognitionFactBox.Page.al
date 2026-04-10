// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Projects.Project.Job;

page 9099 "Job WIP/Recognition FactBox"
{
    Caption = 'Project Details - WIP/Recognition';
    PageType = CardPart;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Jobs;
                Caption = 'Project No.';
                ToolTip = 'Specifies the project number.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("WIP Posting Date"; Rec."WIP Posting Date")
            {
                ApplicationArea = Jobs;
            }
            field("Total WIP Cost Amount"; Rec."Total WIP Cost Amount")
            {
                ApplicationArea = Jobs;
            }
            field("Applied Costs G/L Amount"; Rec."Applied Costs G/L Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the sum of all applied costs of the selected project.';
                Visible = false;
            }
            field("Total WIP Sales Amount"; Rec."Total WIP Sales Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the total WIP Sales amount that was last calculated for the project. The WIP Sales Amount for the project is the value WIP Sales Project WIP Entries less the value of the Recognized Sales Project WIP Entries. For projects with WIP Methods of Cost Value or Cost of Sales, the WIP Sales Amount is normally 0.';
            }
            field("Applied Sales G/L Amount"; Rec."Applied Sales G/L Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the sum of all applied costs of the selected project.';
                Visible = false;
            }
            field("Recog. Costs Amount"; Rec."Recog. Costs Amount")
            {
                ApplicationArea = Jobs;
            }
            field("Recog. Sales Amount"; Rec."Recog. Sales Amount")
            {
                ApplicationArea = Jobs;
            }
            field("Recog. Profit Amount"; Rec.CalcRecognizedProfitAmount())
            {
                AutoFormatType = 1;
                AutoFormatExpression = Rec."Currency Code";
                ApplicationArea = Jobs;
                Caption = 'Recog. Profit Amount';
                ToolTip = 'Specifies the recognized profit amount for the project.';
            }
            field("Recog. Profit %"; Rec.CalcRecognizedProfitPercentage())
            {
                AutoFormatType = 0;
                ApplicationArea = Jobs;
                Caption = 'Recog. Profit %';
                ToolTip = 'Specifies the recognized profit percentage for the project.';
            }
            field("Acc. WIP Costs Amount"; Rec.CalcAccWIPCostsAmount())
            {
                AutoFormatType = 1;
                AutoFormatExpression = Rec."Currency Code";
                ApplicationArea = Jobs;
                Caption = 'Acc. WIP Costs Amount';
                ToolTip = 'Specifies the total WIP costs for the project.';
                Visible = false;
            }
            field("Acc. WIP Sales Amount"; Rec.CalcAccWIPSalesAmount())
            {
                AutoFormatType = 1;
                AutoFormatExpression = Rec."Currency Code";
                ApplicationArea = Jobs;
                Caption = 'Acc. WIP Sales Amount';
                ToolTip = 'Specifies the total WIP sales for the project.';
                Visible = false;
            }
            field("Calc. Recog. Sales Amount"; Rec."Calc. Recog. Sales Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the sum of the recognized costs of the involved project tasks.';
                Visible = false;
            }
            field("Calc. Recog. Costs Amount"; Rec."Calc. Recog. Costs Amount")
            {
                ApplicationArea = Jobs;
                ToolTip = 'Specifies the sum of the recognized costs of the involved project tasks.';
                Visible = false;
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Job Card", Rec);
    end;
}

