codeunit 132211 "Library - Post Inventory To GL"
{
    procedure PostInvtCostToGL(ItemNo: Code[20]; PostingDate: Date)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        PostInventoryCostToGL: Report "Post Inventory Cost to G/L";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Journal Templ. Name Mandatory" then begin
            LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
            GenJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
            GenJournalBatch.Modify(true);
            PostInventoryCostToGL.SetGenJnlBatch(GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        end;
        Commit();
        PostValueEntryToGL.SetRange("Item No.", ItemNo);
        PostValueEntryToGL.SetRange("Posting Date", PostingDate);
        PostInventoryCostToGL.InitializeRequest(PostMethod::"per Entry", '', true);
        PostInventoryCostToGL.SetTableView(PostValueEntryToGL);
        PostInventoryCostToGL.UseRequestPage(false);
        PostInventoryCostToGL.SaveAsPdf(TemporaryPath + DelChr(Format(CreateGuid()), '=', '{}') + '.pdf');
    end;

    procedure PostInvtCostToGL(PerPostingGroup: Boolean; PostingDate: Date; DocNo: Code[20])
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        PostInventoryCosttoGL: Report "Post Inventory Cost to G/L";
        PostMethod: Option "per Posting Group","per Entry";
        TempPathTxt: Label '%1%2.html', Comment = '%1 = Temporary Path, %2 = Document No.';
    begin
        Commit();

        PostValueEntryToGL.SetFilter("Posting Date", '=%1', PostingDate);
        if PerPostingGroup then begin
            PostMethod := PostMethod::"per Posting Group";
            PostInventoryCosttoGL.InitializeRequest(PostMethod, DocNo, true);
        end else begin
            PostMethod := PostMethod::"per Entry";
            PostInventoryCosttoGL.InitializeRequest(PostMethod, '', true);
        end;
        PostInventoryCosttoGL.SetTableView(PostValueEntryToGL);
        PostInventoryCosttoGL.UseRequestPage(false);
        PostInventoryCosttoGL.SaveAsPdf(StrSubstNo(TempPathTxt, TemporaryPath, DocNo));
    end;

    procedure PostInvtCostToGL(PerPostingGroup: Boolean; ItemNo: Code[20]; DocNo: Code[20]; PreviewDumpFilePath: Text[1024])
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
        PostInventoryCostToGL: Report "Post Inventory Cost to G/L";
        PostMethod: Option "per Posting Group","per Entry";
    begin
        Commit();
        PostValueEntryToGL.SetFilter("Item No.", '>=%1', ItemNo);

        if PerPostingGroup then
            PostMethod := PostMethod::"per Posting Group"
        else
            PostMethod := PostMethod::"per Entry";
        PostInventoryCostToGL.InitializeRequest(PostMethod, DocNo, true);
        PostInventoryCostToGL.SetTableView(PostValueEntryToGL);
        PostInventoryCostToGL.UseRequestPage(false);
        PostInventoryCostToGL.SaveAsPdf(PreviewDumpFilePath);
    end;
}