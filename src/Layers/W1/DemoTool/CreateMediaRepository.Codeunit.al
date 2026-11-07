codeunit 101980 "Create Media Repository"
{

    trigger OnRun()
    begin
        ImportMediaToRepository();
        ImportInvoicingEmailMedia();
    end;

    local procedure ImportMediaToRepository()
    var
        DemoDataSetup: Record "Demo Data Setup";
        MediaRepository: Record "Media Repository";
        MediaPath: Text;
    begin
        DemoDataSetup.Get();

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\AssistedSetup-NoText-400px.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Web));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\AssistedSetupDone-NoText-400px.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Web));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\ExternalSync-NoText.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Phone));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\FirstInvoice1.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Phone));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\FirstInvoice2.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Phone));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\FirstInvoice3.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Phone));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\FirstInvoiceSplash.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Phone));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\ImageAnalysis-Setup-NoText.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Web));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\AssistedSetupInfo-NoText.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Web));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\PowerBi-OptIn-480px.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Web));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\PowerBi-OptIn-480px.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Tablet));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\PowerBi-OptIn-480px.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Phone));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\WhatsNewWizard-Banner-First.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Web));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\WhatsNewWizard-Banner-Second.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Web));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\OutlookAddinIllustration.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Web));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\TeamsAppIllustration.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Web));

        MediaPath := DemoDataSetup."Path to Picture Folder" + 'Images\System\CopilotNotAvailable.png';
        MediaRepository.ImportMedia(MediaPath, Format(CLIENTTYPE::Web));
    end;

    local procedure ImportInvoicingEmailMedia()
    var
        DemoDataSetup: Record "Demo Data Setup";
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
        FilePath: Text;
    begin
        DemoDataSetup.Get();
        FilePath := DemoDataSetup."Path to Picture Folder"; // '' = server temp folder

        MediaResourcesMgt.InsertBLOBFromFile(FilePath + 'HTMLTemplates\', 'Invoicing - SalesMail.html');

        MediaResourcesMgt.InsertBLOBFromFile(FilePath, 'Payment service - PayPal-logo.png');
        MediaResourcesMgt.InsertBLOBFromFile(FilePath, 'Payment service - Microsoft-logo.png');
        MediaResourcesMgt.InsertBLOBFromFile(FilePath, 'Payment service - WorldPay-logo.png');

        MediaResourcesMgt.InsertBLOBFromFile(FilePath, 'Social - FACEBOOK.png');
        MediaResourcesMgt.InsertBLOBFromFile(FilePath, 'Social - TWITTER.png');
        MediaResourcesMgt.InsertBLOBFromFile(FilePath, 'Social - YOUTUBE.png');
        MediaResourcesMgt.InsertBLOBFromFile(FilePath, 'Social - LINKEDIN.png');
        MediaResourcesMgt.InsertBLOBFromFile(FilePath, 'Social - PINTEREST.png');
        MediaResourcesMgt.InsertBLOBFromFile(FilePath, 'Social - YELP.png');
        MediaResourcesMgt.InsertBLOBFromFile(FilePath, 'Social - INSTAGRAM.png');
    end;
}

