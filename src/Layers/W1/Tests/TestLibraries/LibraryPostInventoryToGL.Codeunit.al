codeunit 132211 "Library - Post Inventory To GL"
{
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