// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7441 "EA Corp Card Dashboard Fact"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Recent Statements';
    PageType = ListPart;
    SourceTable = "EA Corp Card Statement";
    SourceTableTemporary = true;
    SourceTableView = sorting("Statement Entry No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Statements)
            {
                ShowCaption = false;
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    ToolTip = 'Specifies the statement identifier assigned by the provider. Select the value to open the statement.';

                    trigger OnDrillDown()
                    begin
                        OpenSelectedStatement();
                    end;
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider code.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement import or validation status.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the provider statement.';
                }
                field(Imported; Rec.Imported)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of imported transactions.';
                }
                field(Matched; (Rec.Imported - Rec.Rejected))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Processed';
                    ToolTip = 'Specifies the number of successfully processed transactions.';
                }
                field(Exceptions; Rec.Exceptions)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of exceptions.';
                }
                field(Duplicates; Rec.Duplicates)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of duplicate transactions.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenStatement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Statement';
                Image = Document;
                ToolTip = 'Open the selected corporate card statement.';

                trigger OnAction()
                begin
                    OpenSelectedStatement();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        StatementCount: Integer;
    begin
        CorpCardStatement.SetCurrentKey("Statement Entry No.");
        CorpCardStatement.Ascending := false;
        if CorpCardStatement.Find('-') then
            repeat
                Rec := CorpCardStatement;
                Rec.Insert();
                StatementCount += 1;
            until (CorpCardStatement.Next() = 0) or (StatementCount = 50);
    end;

    local procedure OpenSelectedStatement()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        CorpCardStatement.Get(Rec."Statement Entry No.");
        Page.Run(Page::"EA Corp Card Statement", CorpCardStatement);
    end;
}
