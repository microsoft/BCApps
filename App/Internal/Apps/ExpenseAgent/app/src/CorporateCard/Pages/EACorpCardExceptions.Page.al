// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7222 EACorpCardExceptions
{
    Caption = 'Corp Card Exceptions';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = EACorpCardException;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the exception entry number.';
                }
                field("Batch No."; Rec."Batch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the batch where this exception was raised.';
                }
                field("Trans Entry No."; Rec."Trans Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction entry linked to this exception.';
                }
                field("Exception Type"; Rec."Exception Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the exception type.';
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies details about the exception.';
                }
                field(Resolved; Rec.Resolved)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the exception has been resolved.';
                }
                field("Resolved By"; Rec."Resolved By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who resolved the exception.';
                }
                field("Resolved DT"; Rec."Resolved DT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the exception was resolved.';
                }
            }
        }
    }
}