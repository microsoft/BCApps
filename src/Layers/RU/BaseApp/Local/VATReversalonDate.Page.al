#pragma warning disable AA0247
page 14924 "VAT Reversal on Date"
{
    Caption = 'VAT Reversal on Date';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    InstructionalText = 'Do you want to post reversal with following date?';
    PageType = ConfirmationDialog;
    SourceTable = "Reversal Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field(PostingDate; PostingDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Enter Posting Date:';
            }
        }
    }

    actions
    {
    }

    var
        PostingDate: Date;

    [Scope('OnPrem')]
    procedure SetDate(NewPostingDate: Date)
    begin
        PostingDate := NewPostingDate;
    end;

    [Scope('OnPrem')]
    procedure GetDate(): Date
    begin
        exit(PostingDate);
    end;
}

