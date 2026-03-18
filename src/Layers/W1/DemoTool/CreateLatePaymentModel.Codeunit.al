codeunit 119301 "Create Late Payment Model"
{

    trigger OnRun()
    begin
        InsertDataToSystemTable('LatePaymentStandardModel.txt');
    end;

    local procedure InsertDataToSystemTable(FileName: Text[50])
    var
        DemoDataSetup: Record "Demo Data Setup";
        MediaResources: Record "Media Resources";
        File: File;
        ModelInStream: InStream;
        ModelOutStream: OutStream;
        FilePath: Text;
    begin
        DemoDataSetup.Get();
        // Clean out any existing records for each fileName
        if MediaResources.Get(FileName) then begin
            MediaResources.Delete();
            Commit();
        end;

        MediaResources.Init();
        MediaResources.Code := FileName;

        if not MediaResources.Insert(true) then
            exit;

        if MediaResources.Get(FileName) then begin
            FilePath := DemoDataSetup."Path to Picture Folder" + 'MachineLearning\' + FileName;

            File.Open(FilePath);
            File.CreateInStream(ModelInStream);
            MediaResources.Blob.CreateOutStream(ModelOutStream);
            CopyStream(ModelOutStream, ModelInStream);
            File.Close();

            MediaResources.Modify();
        end
    end;
}

