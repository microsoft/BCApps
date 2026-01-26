codeunit 163546 "Create Document Footer CZL"
{
    trigger OnRun()
    var
        DocumentFooterCZL: Record "Document Footer CZL";
    begin
        DocumentFooterCZL.Init();
        DocumentFooterCZL."Language Code" := 'CSY';
        DocumentFooterCZL."Footer Text" := XFooterText;
        DocumentFooterCZL.Insert();
    end;

    var
        XFooterText: Label 'Registered at the Municipal Court in Prague, Section B, File 6970789';
}
