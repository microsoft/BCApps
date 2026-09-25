// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7441 "EA Corp Card Dashboard Fact"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Recent Import Batches';
    PageType = ListPart;
    SourceTable = "EA Corp Card Batch";
    SourceTableTemporary = true;
    SourceTableView = sorting("Batch No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Batches)
            {
                ShowCaption = false;
                field("Batch No."; Rec."Batch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the batch number.';
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider code.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the batch status.';
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
                field("Started DT"; Rec."Started DT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the batch start date-time.';
                }
                field("Ended DT"; Rec."Ended DT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the batch end date-time.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        CorpCardBatch: Record "EA Corp Card Batch";
        BatchCount: Integer;
    begin
        CorpCardBatch.SetCurrentKey("Batch No.");
        CorpCardBatch.Ascending := false;
        if CorpCardBatch.Find('-') then
            repeat
                Rec := CorpCardBatch;
                Rec.Insert();
                BatchCount += 1;
            until (CorpCardBatch.Next() = 0) or (BatchCount = 50);
    end;
}
