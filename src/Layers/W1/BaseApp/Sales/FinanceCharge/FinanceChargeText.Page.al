// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Displays and manages beginning and ending text lines for finance charge memos.
/// </summary>
page 445 "Finance Charge Text"
{
    AutoSplitKey = true;
    Caption = 'Finance Charge Text';
    DataCaptionFields = "Fin. Charge Terms Code", Position;
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "Finance Charge Text";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Fin. Charge Terms Code"; Rec."Fin. Charge Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Text; Rec.Text)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

