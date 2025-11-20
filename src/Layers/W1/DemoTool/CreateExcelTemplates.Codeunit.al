codeunit 101405 "Create Excel Templates"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertDataToSystemTable('ExcelTemplateBalanceSheet.xltm');
        InsertDataToSystemTable('ExcelTemplateIncomeStatement.xltm');
        InsertDataToSystemTable('ExcelTemplateAgedAccountsPayable.xltm');
        InsertDataToSystemTable('ExcelTemplateAgedAccountsReceivable.xltm');
        InsertDataToSystemTable('ExcelTemplateCashFlowStatement.xltm');
        InsertDataToSystemTable('ExcelTemplateRetainedEarnings.xltm');
        InsertDataToSystemTable('ExcelTemplateTrialBalance.xltm');
    end;

    var
        MediaResources: Record "Media Resources";
        DemoDataSetup: Record "Demo Data Setup";

    local procedure InsertDataToSystemTable(FileName: Text[50])
    var
        File: File;
        LayoutInStream: InStream;
        LayoutOutStream: OutStream;
        FilePath: Text;
    begin
        // Clean out any existing template records for each statement type
        if MediaResources.Get(FileName) then begin
            MediaResources.Delete();
            Commit();
        end;

        MediaResources.Init();
        MediaResources.Code := FileName;

        if not MediaResources.Insert(true) then
            exit;

        if MediaResources.Get(FileName) then begin
            FilePath := DemoDataSetup."Path to Picture Folder" + 'ExcelTemplates\' + FileName;

            File.Open(FilePath);
            File.CreateInStream(LayoutInStream);
            MediaResources.Blob.CreateOutStream(LayoutOutStream);
            CopyStream(LayoutOutStream, LayoutInStream);
            File.Close();

            MediaResources.Modify();
        end
    end;
}

