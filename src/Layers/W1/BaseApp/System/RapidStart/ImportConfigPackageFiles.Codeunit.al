#if not CLEAN26
#pragma warning disable AS0018, AS0049, AS0072
namespace System.IO;

using Microsoft.Foundation.Company;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Threading;

codeunit 1805 "Import Config. Package Files"
{
    // // This code unit is executed in a separate session. Messages and errors will be output to the event log.

    TableNo = "Configuration Package File";
    ObsoleteTag = '25.2';
    ObsoleteReason = 'Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084';
    ObsoleteState = Pending;
    Access = Internal;

    trigger OnRun()
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        UserPersonalization: Record "User Personalization";
        CompanyInitialize: Codeunit "Company-Initialize";
        CurrentLanguageID: Integer;
    begin
        AssistedCompanySetupStatus.Get(CompanyName);
        AssistedCompanySetupStatus."Server Instance ID" := ServiceInstanceId();
        AssistedCompanySetupStatus."Company Setup Session ID" := SessionId();
        AssistedCompanySetupStatus.Modify();
        Commit();

        UserPersonalization.Get(UserSecurityId());
        CurrentLanguageID := GlobalLanguage;
        if (UserPersonalization."Language ID" <> Rec."Language ID") and (Rec."Language ID" <> 0) then
            if not TrySetGlobalLanguage(Rec."Language ID") then
                Error(InvalidLanguageIDErr, Rec."Language ID");

        CompanyInitialize.InitializeCompany();
        ImportConfigurationPackageFiles(Rec);

        OnAfterImportConfigurationPackage();

        GlobalLanguage(CurrentLanguageID);
    end;

    var
        NoPackDefinedMsg: Label 'Critical Error: No configuration package file is defined within the specified filter %1. Please contact your system administrator.', Comment = '%1 = Filter String';
        ImportStartedMsg: Label 'The import of the %1 configuration package to the %2 company has started.', Comment = '%1 = Configuration Package Code, %2 = Company Name';
        ImportSuccessfulMsg: Label 'The configuration package %1 was successfully imported to the %2 company.', Comment = '%1 = Configuration Package Code, %2 = Company Name';
        ApplicationStartedMsg: Label 'Application of the %1 configuration package to the %2 company has started.', Comment = '%1 = Configuration Package Code, %2 = Company Name';
        ApplicationSuccessfulMsg: Label 'The configuration package %1 was successfully applied to the %2 company.', Comment = '%1 = Configuration Package Code, %2 = Company Name';
        ApplicationFailedMsg: Label 'Critical Error: %1 errors occurred during the package application. Please contact your system administrator.', Comment = '%1 = No. of errors, %2 = Package Code, %3 = Company Name';
        PackageLbl: Label 'Package';
        CompanyLbl: Label 'Company';
        InvalidLanguageIDErr: Label 'Cannot set the language to %1. The language pack ID number is invalid.', Comment = '%1 is the language code, tried to be set';

    local procedure ImportConfigurationPackageFiles(var ConfigurationPackageFile: Record "Configuration Package File")
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        TempConfigSetupSystemRapidStart: Record "Config. Setup" temporary;
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ConfigPackageImport: Codeunit "Config. Package - Import";
        // AssistedCompanySetup: Codeunit "Assisted Company Setup";
        MessageText: Text;
        ServerTempFileName: Text;
        ErrorCount: Integer;
        TotalNoOfErrors: Integer;
    begin
        OnBeforeImportConfigurationFile(ConfigurationPackageFile);

        AssistedCompanySetupStatus.Get(CompanyName);

        ConfigurationPackageFile.SetCurrentKey("Processing Order");
        if ConfigurationPackageFile.FindSet() then
            repeat
                MessageText := StrSubstNo(ImportStartedMsg, ConfigurationPackageFile.Code, CompanyName);
                InitVirtualJobQueueEntry(JobQueueEntry, AssistedCompanySetupStatus."Task ID");
                UpdateVirtualJobQueueEntry(JobQueueEntry, MessageText);
                JobQueueEntry.InsertLogEntry(JobQueueLogEntry);
                Message(MessageText);

                ServerTempFileName := GetConfigurationPackageFile(ConfigurationPackageFile);
                ConfigPackageImport.ImportRapidStartPackage(ServerTempFileName, TempConfigSetupSystemRapidStart);
                MessageText := StrSubstNo(ImportSuccessfulMsg, ConfigurationPackageFile.Code, CompanyName);
                JobQueueLogEntry.Description := CopyStr(MessageText, 1, MaxStrLen(JobQueueLogEntry.Description));
                JobQueueEntry.FinalizeLogEntry(JobQueueLogEntry);
                Message(MessageText);

                MessageText := StrSubstNo(ApplicationStartedMsg, ConfigurationPackageFile.Code, CompanyName);
                UpdateVirtualJobQueueEntry(JobQueueEntry, MessageText);
                JobQueueEntry.InsertLogEntry(JobQueueLogEntry);
                Message(MessageText);

                ErrorCount := TempConfigSetupSystemRapidStart.ApplyPackages();
                TotalNoOfErrors += ErrorCount;

                Erase(ServerTempFileName);

                if ErrorCount > 0 then begin
                    MessageText :=
                      GetApplicationErrorSourceText(
                        CompanyName, TempConfigSetupSystemRapidStart."Package Code") + ' ' +
                      StrSubstNo(ApplicationFailedMsg, ErrorCount);
                    JobQueueEntry.Status := JobQueueEntry.Status::Error;
                    JobQueueEntry."Error Message" := CopyStr(MessageText, 1, 2048);
                end else begin
                    MessageText := StrSubstNo(ApplicationSuccessfulMsg, ConfigurationPackageFile.Code, CompanyName);
                    JobQueueLogEntry.Description := CopyStr(MessageText, 1, MaxStrLen(JobQueueLogEntry.Description));
                    TempConfigSetupSystemRapidStart.Delete();
                end;
                JobQueueEntry.FinalizeLogEntry(JobQueueLogEntry);
                Message(MessageText);

            until ConfigurationPackageFile.Next() = 0
        else begin
            MessageText := StrSubstNo(NoPackDefinedMsg, ConfigurationPackageFile.GetFilters);
            InitVirtualJobQueueEntry(JobQueueEntry, AssistedCompanySetupStatus."Task ID");
            UpdateVirtualJobQueueEntry(JobQueueEntry, MessageText);
            JobQueueEntry.InsertLogEntry(JobQueueLogEntry);
            JobQueueEntry.Status := JobQueueEntry.Status::Error;
            JobQueueEntry."Error Message" := CopyStr(MessageText, 1, 2048);
            JobQueueEntry.FinalizeLogEntry(JobQueueLogEntry);
            Message(MessageText);
        end;
        AssistedCompanySetupStatus."Company Setup Session ID" := 0;
        AssistedCompanySetupStatus."Server Instance ID" := 0;
        AssistedCompanySetupStatus.Modify();
        Commit();

        OnAfterImportConfigurationFile(ConfigurationPackageFile);
    end;

    procedure GetConfigurationPackageFile(ConfigurationPackageFile: Record "Configuration Package File") ServerTempFileName: Text
    var
        FileManagement: Codeunit "File Management";
        TempFile: File;
        OutStream: OutStream;
        InStream: InStream;
    begin
        ServerTempFileName := FileManagement.ServerTempFileName('rapidstart');
        TempFile.Create(ServerTempFileName);
        TempFile.CreateOutStream(OutStream);
        ConfigurationPackageFile.CalcFields(Package);
        ConfigurationPackageFile.Package.CreateInStream(InStream);
        CopyStream(OutStream, InStream);
        TempFile.Close();
    end;

    local procedure InitVirtualJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; TaskID: Guid)
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := TaskID;
        JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Import Config. Package Files";
    end;

    local procedure UpdateVirtualJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; TaskDescription: Text)
    begin
        JobQueueEntry."User Session Started" := CurrentDateTime;
        JobQueueEntry.Description := CopyStr(TaskDescription, 1, MaxStrLen(JobQueueEntry.Description));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Queue Log Entries", 'OnShowDetails', '', false, false)]
    local procedure OnShowDetailedLog(JobQueueLogEntry: Record "Job Queue Log Entry")
    var
        ConfigPackageError: Record "Config. Package Error";
        ApplCompanyName: Text;
        PackageCode: Text;
    begin
        if (JobQueueLogEntry."Object ID to Run" = CODEUNIT::"Import Config. Package Files") and
           (JobQueueLogEntry.Status = JobQueueLogEntry.Status::Error) and
           ParseApplicationErrorText(ApplCompanyName, PackageCode, JobQueueLogEntry."Error Message")
        then begin
            ConfigPackageError.ChangeCompany(ApplCompanyName);
            ConfigPackageError.SetRange("Package Code", PackageCode);
            PAGE.RunModal(0, ConfigPackageError);
        end;
    end;

    local procedure ParseApplicationErrorText(var ApplCompanyName: Text; var PackageCode: Text; ErrorText: Text): Boolean
    begin
        ApplCompanyName := ExtractSubstring(ErrorText);
        PackageCode := ExtractSubstring(ErrorText);
        exit((ApplCompanyName <> '') and (PackageCode <> ''));
    end;

    local procedure GetApplicationErrorSourceText(ApplCompanyName: Text; PackageCode: Text): Text
    begin
        exit(
          StrSubstNo(
            '%1 <%2>, %3 <%4>.', CompanyLbl, ApplCompanyName, PackageLbl, PackageCode));
    end;

    local procedure ExtractSubstring(var ErrorText: Text) Substring: Text
    var
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartPos := StrPos(ErrorText, '<');
        EndPos := StrPos(ErrorText, '>');
        if (StartPos <> 0) and (EndPos <> 0) then begin
            Substring := CopyStr(ErrorText, StartPos + 1, EndPos - StartPos - 1);
            ErrorText := CopyStr(ErrorText, EndPos + 1);
        end;
    end;

    [TryFunction]
    local procedure TrySetGlobalLanguage(LanguageId: Integer)
    begin
        // <summary>
        // TryFunction for setting the global language.
        // </summary>
        // <param name="LanguageId">The id of the language to be set as global</param>

        GlobalLanguage(LanguageId);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeImportConfigurationFile(var ConfigurationPackageFile: Record "Configuration Package File")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportConfigurationFile(var ConfigurationPackageFile: Record "Configuration Package File")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportConfigurationPackage()
    begin
    end;
}
#pragma warning restore AS0018, AS0049, AS0072
#endif