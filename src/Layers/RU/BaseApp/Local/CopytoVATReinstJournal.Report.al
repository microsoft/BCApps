#pragma warning disable AA0247
report 14973 "Copy to VAT Reinst. Journal"
{
    Caption = 'Copy to VAT Reinst. Journal';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Factor; Factor)
                    {
                        AutoFormatType = 0;
                        ApplicationArea = Basic, Suite;
                        Caption = 'VAT Amount Factor';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the description that will be added to the resulting posting.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            // default values
            Factor := 1;
            PostingDescription := Text004;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        VATReinstMgt.CopyToJnl(EntryToPost, VATEntry, Factor, PostingDate, PostingDescription);
    end;

    trigger OnPreReport()
    begin
        if Factor = 0 then
            Error(Text001);

        if Factor < 0 then
            Error(Text002);

        if PostingDate = 0D then
            Error(Text003);
    end;

    var
        EntryToPost: Record "VAT Document Entry Buffer" temporary;
        VATEntry: Record "VAT Entry";
        VATReinstMgt: Codeunit "VAT Reinstatement Management";
        Factor: Decimal;
#pragma warning disable AA0074
        Text001: Label 'Factor cannot be zero.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'Factor cannot be negative.';
#pragma warning restore AA0074
        PostingDate: Date;
        PostingDescription: Text[50];
#pragma warning disable AA0074
        Text003: Label 'You must specify Posting Date.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'VAT Reinstatement';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure SetParameters(var NewEntryToPost: Record "VAT Document Entry Buffer"; var NewVATEntry: Record "VAT Entry"; NewPostingDate: Date)
    begin
        if NewEntryToPost.FindFirst() then
            repeat
                EntryToPost := NewEntryToPost;
                EntryToPost.Insert();
            until NewEntryToPost.Next() = 0;

        EntryToPost.CopyFilters(NewEntryToPost);
        VATEntry.CopyFilters(NewVATEntry);
        PostingDate := NewPostingDate;
    end;
}

