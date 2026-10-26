// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using System.Email;
using System.Environment;

codeunit 3309 "PA Demo Guide"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure DemoExperienceAvailable(): Boolean
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName);
        exit(Company."Evaluation Company");
    end;

    procedure OpenGuidePage(PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        PADemoGuidePage: Page "PA Demo Guide";
    begin
        PADemoGuidePage.SetSetupConfiguration(PASetupUpdateParameters);
        PADemoGuidePage.Run();
    end;

    procedure SendDemoInvoicesByEmail(PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"): Boolean
    var
        EDocSamplePurchInvFile: Record "E-Doc Sample Purch. Inv File";
    begin
        EDocSamplePurchInvFile.ModifyAll("Send By Email", true);
        exit(SendDemoEmail(PASetupUpdateParameters));
    end;

    procedure SendDemoEmail(PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"): Boolean
    var
        EDocSamplePurchInvFile: Record "E-Doc Sample Purch. Inv File";
        TempEmailAccount: Record "Email Account";
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        DraftBasedTelemetry: Codeunit "PA Draft Based Telemetry";
        FileInStream: InStream;
        EmailSendingFailedErr: Label 'Email sending failed: %1.\\Verify that you have access to send emails from %2', Comment = '%1 - error message from the email management codeunit, %2 = sender email address';
        SubjectTxt: Label 'Sample email from Payables Agent', MaxLength = 255, Comment = 'Payables Agent is a term, and should not be translated.';
        BodyTextTxt: Label 'This is a sample email from Payables Agent.', MaxLength = 255, Comment = 'Payables Agent is a term, and should not be translated.';
    begin
        if not DemoExperienceAvailable() then
            exit(false);
        if not IsEmailConfiguredForDemoEmail(PASetupUpdateParameters) then
            exit(false);
        if PASetupUpdateParameters.GetAgentSetupBuffer().State = PASetupUpdateParameters.GetAgentSetupBuffer().State::Disabled then
            exit(false);
        EDocSamplePurchInvFile.SetRange("Send By Email", true);
        if EDocSamplePurchInvFile.IsEmpty() then
            exit(false);
        TempEmailAccount := PASetupUpdateParameters.GetEmailAccount();

        EmailMessage.Create(TempEmailAccount."Email Address", SubjectTxt, BodyTextTxt, true);
        EDocSamplePurchInvFile.FindSet();
        repeat
            EDocSamplePurchInvFile.CalcFields("File Content");
            EDocSamplePurchInvFile."File Content".CreateInStream(FileInStream);
            EmailMessage.AddAttachment(EDocSamplePurchInvFile."File Name", 'application/pdf', FileInStream);
        until EDocSamplePurchInvFile.Next() = 0;

        ClearLastError();
        if not Email.Send(EmailMessage, TempEmailAccount) then begin
            DraftBasedTelemetry.LogDemoEmailSendingFailed(GetLastErrorText());
            error(EmailSendingFailedErr, GetLastErrorText(), TempEmailAccount."Email Address");
        end;
        EDocSamplePurchInvFile.SetRange("Send By Email");
        EDocSamplePurchInvFile.ModifyAll("Send By Email", false);
        exit(true);
    end;

    procedure IsEmailConfiguredForDemoEmail(PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"): Boolean
    begin
        if not PASetupUpdateParameters.MonitorEmail() then
            exit(false);
        if IsNullGuid(PASetupUpdateParameters.GetEmailAccount()."Account Id") then
            exit(false);
        exit(true);
    end;

    procedure GetDemoFilesToDownloadCount(): Integer
    var
        EDocSamplePurchInvFile: Record "E-Doc Sample Purch. Inv File";
    begin
        exit(EDocSamplePurchInvFile.Count());
    end;

    procedure ShowDemoFilesToDownload()
    begin
        Page.Run(Page::"E-Doc Sample Purch. Inv. Files");
    end;

#if not CLEAN28
#pragma warning disable AL0432
    [Obsolete('Sample files are now downloaded from E-Doc Sample Purch. Inv. Files page', '28.0')]
    procedure DownloadDemoFile(PADemoFile: Record "PA Demo File")
    begin
    end;
#pragma warning restore AL0432
#endif
}