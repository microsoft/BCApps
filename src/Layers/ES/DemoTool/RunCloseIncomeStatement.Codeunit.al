codeunit 161000 "Run Close Income Statement"
{

    trigger OnRun()
    begin
        GLEntry.Reset();
        GLEntry.Find('+');

        Clear(CloseIncStmt);
        CloseIncStmt.InitializeRequest(
          GLEntry."Posting Date", XGENERAL, XDEFAULT,
          'CLOS' + Format(Date2DMY(GLEntry."Posting Date", 3)),
          'Income Statement Closing', false, false, false, '1170001');
        CloseIncStmt.UseRequestPage(false);
        CloseIncStmt.RunModal();
    end;

    var
        CloseIncStmt: Report "Close Income Statement";
        GLEntry: Record "G/L Entry";
        XGENERAL: Label 'GENERAL';
        XDEFAULT: Label 'DEFAULT';
}

