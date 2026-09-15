codeunit 101975 "Create Getting Started Data"
{

    trigger OnRun()
    var
        O365GettingStartedPageData: Record "O365 Getting Started Page Data";
    begin
        DemoDataSetup.Get();
        O365GettingStartedPageData.DeleteAll();
        ImportO365GettingStartedPageImageData();
        ImportO365SetupDeviceInstructions();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        NotSupprotedFileTypeErr: Label 'File type %1, from file %2 is not supported.', Comment = '%1 - arbitrary name,%2 - arbitrary name';

    local procedure ImportO365GettingStartedPageImageData()
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        O365GettingStartedPageData: Record "O365 Getting Started Page Data";
        FileManagement: Codeunit "File Management";
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
        Extension: Text;
        FileName: Text;
        SeparationCharacter: Text;
        MediaResourcesCode: Code[50];
    begin
        if DemoDataSetup."Path to Picture Folder" = '' then
            FileManagement.GetServerDirectoryFilesList(TempNameValueBuffer, TemporaryPath() + '..\WalkMeTour')
        else
            FileManagement.GetServerDirectoryFilesList(TempNameValueBuffer, DemoDataSetup."Path to Picture Folder" + 'WalkMeTour');

        TempNameValueBuffer.SetFilter(Name, '*.jpg|*.jpeg|*.png|*.bmp');

        if TempNameValueBuffer.FindSet() then
            repeat
                Clear(O365GettingStartedPageData);
                FileName := FileManagement.GetFileNameWithoutExtension(TempNameValueBuffer.Name);

                SeparationCharacter := '-';
                Evaluate(O365GettingStartedPageData."Wizard ID", GetPartOfTheName(FileName, SeparationCharacter, 1));
                Evaluate(O365GettingStartedPageData."No.", GetPartOfTheName(FileName, SeparationCharacter, 2));
                O365GettingStartedPageData."Display Target" :=
                  CopyStr(GetPartOfTheName(FileName, SeparationCharacter, 3), 1, MaxStrLen(O365GettingStartedPageData."Display Target"));

                Extension := FileManagement.GetExtension(TempNameValueBuffer.Name);
                case Extension of
                    'bmp', 'png', 'jpg', 'jpeg':
                        begin
                            MediaResourcesCode := CopyStr(FileManagement.GetFileName(TempNameValueBuffer.Name), 1, MaxStrLen(MediaResourcesCode));
                            if MediaResourcesMgt.InsertMediaFromFile(MediaResourcesCode, TempNameValueBuffer.Name) then
                                O365GettingStartedPageData.Validate("Media Resources Ref", MediaResourcesCode);
                            O365GettingStartedPageData.Type := O365GettingStartedPageData.Type::Image;
                        end
                    else
                        Error(NotSupprotedFileTypeErr, Extension);
                end;

                O365GettingStartedPageData.Insert();
            until TempNameValueBuffer.Next() = 0;
    end;

    local procedure ImportO365SetupDeviceInstructions()
    var
        O365DeviceSetupInstructions: Record "O365 Device Setup Instructions";
        FileManagement: Codeunit "File Management";
        RootFolder: Text;
    begin
        O365DeviceSetupInstructions.DeleteAll();
        O365DeviceSetupInstructions.Init();

        if DemoDataSetup."Path to Picture Folder" = '' then
            RootFolder := TemporaryPath() + '..\WalkMeTour\SetupDevice'
        else
            RootFolder := DemoDataSetup."Path to Picture Folder" + 'WalkMeTour\SetupDevice';
        O365DeviceSetupInstructions."QR Code".Import(FileManagement.CombinePath(RootFolder, 'QRCode.png'));
        O365DeviceSetupInstructions.Insert();
    end;

    local procedure GetPartOfTheName(CommaSeparatedText: Text; SeparationCharacter: Text; Index: Integer): Text
    var
        CurrentIndex: Integer;
        PositionOfSeparationCharacter: Integer;
    begin
        CurrentIndex := 0;
        repeat
            CurrentIndex += 1;
            PositionOfSeparationCharacter := StrPos(CommaSeparatedText, SeparationCharacter);
            if PositionOfSeparationCharacter < 1 then
                exit(CommaSeparatedText);

            if CurrentIndex = Index then
                exit(CopyStr(CommaSeparatedText, 1, PositionOfSeparationCharacter - 1));

            CommaSeparatedText := CopyStr(CommaSeparatedText, PositionOfSeparationCharacter + StrLen(SeparationCharacter));
        until Index = CurrentIndex;

        exit('');
    end;

}

