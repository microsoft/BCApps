// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 10051 "IRS 1099 Form Statement"
{
    ApplicationArea = BasicCA, BasicUS;
    AutoSplitKey = true;
    MultipleNewLines = true;
    PageType = List;
    SaveValues = true;
    SourceTable = "IRS 1099 Form Statement Line";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Row No."; Rec."Row No.")
                {
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a description of the line.';
                }
                field("Value Source"; Rec."Value Source")
                {
                    ToolTip = 'Specifies whether the statement row uses document lines selected by the filter expression or the selected supplemental box.';
                }
                field("Supplemental Box No."; Rec."Supplemental Box No.")
                {
                    Enabled = Rec."Value Source" = Rec."Value Source"::"Supplemental Line";
                    ToolTip = 'Specifies the supplemental box for this period and form. Its definition determines whether an amount or text occupation codes are printed.';
                }
                field("Print Value Type"; Rec."Print Value Type")
                {
                    Enabled = Rec."Value Source" = Rec."Value Source"::"Document Line";
                    Tooltip = 'Specifies the print value type of the statement. If the Amount is selected then the amount calculated by the filter expression is printed. If the Yes/No option is selected, then either Yes or No is printed based on the Yes/No condition.';
                }
                field("Filter Expression"; Rec."Filter Expression")
                {
                    Enabled = Rec."Value Source" = Rec."Value Source"::"Document Line";
                    ToolTip = 'Specifies the filter expression of the statement.';
                }
                field("Row Totaling"; Rec."Row Totaling")
                {
                    ToolTip = 'Specifies a row-number interval or a series of row numbers.';
                }
                field("Print with"; Rec."Print with")
                {
                    ToolTip = 'Specifies whether amounts on the Form statement will be printed with their original sign or with the sign reversed.';
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

}
