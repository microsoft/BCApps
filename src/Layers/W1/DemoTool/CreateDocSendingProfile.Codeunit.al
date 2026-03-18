codeunit 101402 "Create Doc. Sending Profile"
{

    trigger OnRun()
    var
        Printer: Option No,"Yes (Prompt for Settings)","Yes (Use Default Settings)";
    begin
        DemoDataSetup.Get();
        InsertDataPrinter('DIRECTFILE', 'Direct to File', Printer::"Yes (Use Default Settings)");
        InsertLocalData();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        DocumentSendingProfile: Record "Document Sending Profile";

    procedure InsertDataPrinter("Code": Code[20]; Description: Text[50]; Printer: Option No,"Yes (Prompt for Settings)","Yes (Use Default Settings)")
    begin
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Validate(Code, Code);
        DocumentSendingProfile.Validate(Description, Description);
        DocumentSendingProfile.Validate(Printer, Printer);
        DocumentSendingProfile.Insert();
    end;

    procedure InsertDataDisk("Code": Code[20]; Description: Text[50]; Disk: Enum "Doc. Sending Profile Disk")
    begin
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Validate(Code, Code);
        DocumentSendingProfile.Validate(Description, Description);
        DocumentSendingProfile.Validate(Disk, Disk);
        DocumentSendingProfile.Validate(Default, true);
        DocumentSendingProfile.Insert();
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertDataDisk('DIRECTFILE', 'Direct to File', DocumentSendingProfile.Disk::PDF);
    end;

    local procedure InsertLocalData()
    begin
    end;
}

