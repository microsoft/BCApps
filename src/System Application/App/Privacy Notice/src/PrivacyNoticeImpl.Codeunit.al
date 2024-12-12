// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Privacy;

using System.Environment;

codeunit 1565 "Privacy Notice Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Company = r,
                  tabledata "Privacy Notice" = im;

    var
        EmptyGuid: Guid;
        PrivacyAgreementTxt: Label 'By using %1, you consent to your data being shared with Microsoft services that might be outside of your organization''s selected geographic boundaries and might have different compliance and security standards than %2. Your privacy is important to us, and you can choose whether to share data with the service. To learn more, follow the link below.', Comment = '%1 = the integration service name, ex. Microsoft Sharepoint, %2 = the full marketing name, such as Microsoft Dynamics 365 Business Central.';
        MicrosoftPrivacyLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=521839';
        AdminDisabledIntegrationMsg: Label 'Your admin has disabled the integration with %1, please contact your administrator to approve this integration.', Comment = '%1 = a service name such as Microsoft Teams';
        MissingLinkErr: Label 'No privacy notice link was specified';
        PrivacyNoticeDoesNotExistErr: Label 'The privacy notice %1 does not exist.', Comment = '%1 = Identifier of a privacy notice';
        TelemetryCategoryTxt: Label 'Privacy Notice', Locked = true;
        CreatePrivacyNoticeTelemetryTxt: Label 'Creating privacy notice %1', Comment = '%1 = Identifier of a privacy notice', Locked = true;
        ConfirmPrivacyNoticeTelemetryTxt: Label 'Confirming privacy notice %1', Comment = '%1 = Identifier of a privacy notice', Locked = true;
        PrivacyNoticeAutoApprovedByAdminTelemetryTxt: Label 'The privacy notice %1 was auto-approved by the admin', Comment = '%1 = Identifier of a privacy notice', Locked = true;
        PrivacyNoticeAutoRejectedByAdminTelemetryTxt: Label 'The privacy notice %1 was auto-rejected by the admin', Comment = '%1 = Identifier of a privacy notice', Locked = true;
        PrivacyNoticeAutoApprovedByUserTelemetryTxt: Label 'The privacy notice %1 was auto-approved by the user', Comment = '%1 = Identifier of a privacy notice', Locked = true;
        ShowingPrivacyNoticeTelemetryTxt: Label 'Showing privacy notice %1', Comment = '%1 = Identifier of a privacy notice', Locked = true;
        PrivacyNoticeApprovalResultTelemetryTxt: Label 'Approval State after showing privacy notice %1: %2', Comment = '%1 = Identifier of a privacy notice, %2 = Approval state of a privacy notice', Locked = true;
        CheckPrivacyNoticeApprovalStateTelemetryTxt: Label 'Checking privacy approval state for privacy notice %1', Comment = '%1 = Identifier of a privacy notice', Locked = true;
        AdminPrivacyApprovalStateTelemetryTxt: Label 'Admin privacy approval state for privacy notice %1: %2', Comment = '%1 = Identifier of a privacy notice, %2 = Approval state of a privacy notice', Locked = true;
        UserPrivacyApprovalStateTelemetryTxt: Label 'User privacy approval state for privacy notice %1: %2', Comment = '%1 = Identifier of a privacy notice, %2 = Approval state of a privacy notice', Locked = true;
        RegisteringPrivacyNoticesFailedTelemetryErr: Label 'Privacy notices could not be registered', Locked = true;
        PrivacyNoticeNotCreatedTelemetryErr: Label 'A privacy notice %1 could not be created', Comment = '%1 = Identifier of a privacy notice', Locked = true;
        PrivacyNoticeDoesNotExistTelemetryTxt: Label 'The Privacy Notice %1 does not exist.', Comment = '%1 = Identifier of a privacy notice', Locked = true;
        SystemEventPrivacyNoticeNotCreatedTelemetryErr: Label 'System event privacy notice %1 could not be created.', Comment = '%1 = Identifier of a privacy notice', Locked = true;

    trigger OnRun()
    begin
        CreateDefaultPrivacyNotices();
    end;

    procedure CreatePrivacyNotice(Id: Code[50]; IntegrationName: Text[250]; Link: Text[2048]): Boolean
    var
        PrivacyNotice: Record "Privacy Notice";
    begin
        exit(CreatePrivacyNotice(PrivacyNotice, Id, IntegrationName, Link));
    end;

    procedure CreatePrivacyNotice(Id: Code[50]; IntegrationName: Text[250]): Boolean
    begin
        exit(CreatePrivacyNotice(Id, IntegrationName, MicrosoftPrivacyLinkTxt));
    end;

    procedure GetDefaultPrivacyAgreementTxt(): Text
    begin
        exit(PrivacyAgreementTxt);
    end;

    procedure ConfirmPrivacyNoticeApproval(PrivacyNoticeId: Code[50]): Boolean
    begin
        exit(ConfirmPrivacyNoticeApproval(PrivacyNoticeId, true));
    end;

    procedure ConfirmPrivacyNoticeApproval(PrivacyNoticeId: Code[50]; SkipCheckInEval: Boolean): Boolean
    var
        Company: Record Company;
        PrivacyNotice: Record "Privacy Notice";
    begin
        Session.LogMessage('0000GK8', StrSubstNo(ConfirmPrivacyNoticeTelemetryTxt, PrivacyNoticeId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);

        PrivacyNotice.SetAutoCalcFields(Enabled, Disabled);
        PrivacyNotice.SetRange("User SID Filter", EmptyGuid);

        // If the Privacy Notice does not exist then re-initialize all Privacy Notices
        if not PrivacyNotice.Get(PrivacyNoticeId) then begin
            CreateDefaultPrivacyNoticesInSeparateThread();
            if not PrivacyNotice.Get(PrivacyNoticeId) then
                Error(PrivacyNoticeDoesNotExistErr, PrivacyNoticeId);
        end;

        // First check if admin has made decision on this privacy notice and return that
        if PrivacyNotice.Enabled then begin
            Session.LogMessage('0000GK9', StrSubstNo(PrivacyNoticeAutoApprovedByAdminTelemetryTxt, PrivacyNoticeId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            exit(true);
        end;
        if PrivacyNotice.Disabled then begin
            Session.LogMessage('0000GKA', StrSubstNo(PrivacyNoticeAutoRejectedByAdminTelemetryTxt, PrivacyNoticeId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            if CanCurrentUserApproveForOrganization() then
                exit(ShowPrivacyNotice(PrivacyNotice)); // User is admin so show the privacy notice again for them to re-approve
            Message(AdminDisabledIntegrationMsg, PrivacyNotice."Integration Service Name");
            exit(false);
        end;

        // Admin did not make any decision
        if SkipCheckInEval and Company.Get(CompanyName()) and Company."Evaluation Company" then
            exit(true); // Auto-agree for evaluation companies if admin has not explicitly disagreed

        // Check if user made a decision and if so, return that
        PrivacyNotice.SetRange("User SID Filter", UserSecurityId());
        PrivacyNotice.CalcFields(Enabled, Disabled);
        if PrivacyNotice.Enabled then begin
            Session.LogMessage('0000GKB', StrSubstNo(PrivacyNoticeAutoApprovedByUserTelemetryTxt, PrivacyNoticeId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            exit(true); // If user clicked no, they will still be notified until admin makes a decision
        end;

        // Show privacy notice and store user decision
        // if the user is admin then show an approval message for everyone
        // if the user is not admin then show an approval message for this specific user
        exit(ShowPrivacyNotice(PrivacyNotice));
    end;

    procedure CheckPrivacyNoticeApprovalState(PrivacyNoticeId: Code[50]): Enum "Privacy Notice Approval State"
    begin
        exit(CheckPrivacyNoticeApprovalState(PrivacyNoticeId, true));
    end;

    procedure CheckPrivacyNoticeApprovalState(PrivacyNoticeId: Code[50]; SkipCheckInEval: Boolean): Enum "Privacy Notice Approval State"
    var
        Company: Record Company;
        PrivacyNotice: Record "Privacy Notice";
    begin
        Session.LogMessage('0000GKC', StrSubstNo(CheckPrivacyNoticeApprovalStateTelemetryTxt, PrivacyNoticeId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);

        PrivacyNotice.SetAutoCalcFields(Enabled, Disabled);
        PrivacyNotice.SetRange("User SID Filter", EmptyGuid);

        if not PrivacyNotice.Get(PrivacyNoticeId) then begin
            Session.LogMessage('0000GN7', StrSubstNo(PrivacyNoticeDoesNotExistTelemetryTxt, PrivacyNoticeId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            if ShouldApproveByDefault(PrivacyNoticeId) or (SkipCheckInEval and Company.Get(CompanyName()) and Company."Evaluation Company") then
                exit("Privacy Notice Approval State"::Agreed); // Auto-agree for evaluation companies if admin has not explicitly disagreed or approve by default
            exit("Privacy Notice Approval State"::"Not set"); // If there are no Privacy Notice then it is by default "Not set".
        end;

        // First check if admin has made decision on this privacy notice and return that
        if PrivacyNotice.Enabled then begin
            Session.LogMessage('0000GKD', StrSubstNo(AdminPrivacyApprovalStateTelemetryTxt, PrivacyNoticeId, "Privacy Notice Approval State"::Agreed), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            exit("Privacy Notice Approval State"::Agreed);
        end;
        if PrivacyNotice.Disabled then begin
            Session.LogMessage('0000GKE', StrSubstNo(AdminPrivacyApprovalStateTelemetryTxt, PrivacyNoticeId, "Privacy Notice Approval State"::Disagreed), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            exit("Privacy Notice Approval State"::Disagreed);
        end;

        // Admin did not make any decision
        if SkipCheckInEval and Company.Get(CompanyName()) and Company."Evaluation Company" then
            exit("Privacy Notice Approval State"::Agreed); // Auto-agree for evaluation companies if admin has not explicitly disagreed

        // Check if user made a decision and if so, return that
        PrivacyNotice.SetRange("User SID Filter", UserSecurityId());
        PrivacyNotice.CalcFields(Enabled);
        if PrivacyNotice.Enabled then begin
            Session.LogMessage('0000GKF', StrSubstNo(UserPrivacyApprovalStateTelemetryTxt, "Privacy Notice Approval State"::Agreed, PrivacyNoticeId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            exit("Privacy Notice Approval State"::Agreed); // If user clicked no, they will still be notified until admin makes a decision
        end;
        Session.LogMessage('0000GKG', StrSubstNo(UserPrivacyApprovalStateTelemetryTxt, "Privacy Notice Approval State"::"Not set", PrivacyNoticeId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
        exit("Privacy Notice Approval State"::"Not set");
    end;

    procedure CanCurrentUserApproveForOrganization(): Boolean
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        PrivacyNoticeApproval: Record "Privacy Notice Approval";
    begin
        exit(PrivacyNoticeApproval.WritePermission());
    end;

    procedure SetApprovalState(PrivacyNoticeId: Code[50]; PrivacyNoticeApprovalState: Enum "Privacy Notice Approval State")
    var
        PrivacyNoticeApproval: Codeunit "Privacy Notice Approval";
    begin
        CreateDefaultPrivacyNotices(); // Ensure all default Privacy Notices are created
        if CanCurrentUserApproveForOrganization() then
            PrivacyNoticeApproval.SetApprovalState(PrivacyNoticeId, EmptyGuid, PrivacyNoticeApprovalState)
        else
            if not IsApprovalStateDisagreed(PrivacyNoticeApprovalState) then // We do not store rejected user approvals
                PrivacyNoticeApproval.SetApprovalState(PrivacyNoticeId, UserSecurityId(), PrivacyNoticeApprovalState)
    end;

    procedure ShowOneTimePrivacyNotice(IntegrationName: Text[250]): Enum "Privacy Notice Approval State"
    begin
        exit(ShowOneTimePrivacyNotice(IntegrationName, MicrosoftPrivacyLinkTxt));
    end;

    procedure ShowOneTimePrivacyNotice(IntegrationName: Text[250]; Link: Text[2048]): Enum "Privacy Notice Approval State"
    var
        TempPrivacyNotice: Record "Privacy Notice" temporary;
        PrivacyNoticePage: Page "Privacy Notice";
    begin
        CreatePrivacyNotice(TempPrivacyNotice, '', IntegrationName, Link);

        PrivacyNoticePage.SetRecord(TempPrivacyNotice);
        PrivacyNoticePage.RunModal();
        PrivacyNoticePage.GetRecord(TempPrivacyNotice);
        exit(PrivacyNoticePage.GetUserApprovalState());
    end;

    procedure CreateDefaultPrivacyNoticesInSeparateThread()
    begin
        if Codeunit.Run(Codeunit::"Privacy Notice Impl.") then;
    end;

    procedure CreateDefaultPrivacyNotices()
    var
        TempPrivacyNotice: Record "Privacy Notice" temporary;
        PrivacyNotice: Record "Privacy Notice";
    begin
        if not TryGetAllPrivacyNotices(TempPrivacyNotice) then begin
            Session.LogMessage('0000GME', RegisteringPrivacyNoticesFailedTelemetryErr, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
            exit;
        end;

        TempPrivacyNotice.Reset();
        if TempPrivacyNotice.FindSet() then
            repeat
                PrivacyNotice.SetRange(ID, TempPrivacyNotice.ID);
                if PrivacyNotice.IsEmpty() then begin
                    PrivacyNotice := TempPrivacyNotice;
                    if PrivacyNotice.Link = '' then
                        PrivacyNotice.Link := MicrosoftPrivacyLinkTxt;
                    if not PrivacyNotice.Insert() then
                        Session.LogMessage('0000GMF', StrSubstNo(PrivacyNoticeNotCreatedTelemetryErr, TempPrivacyNotice.ID), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', this.TelemetryCategoryTxt)
                    else
                        TryCreateDefaultApproval(PrivacyNotice);
                end;
            until TempPrivacyNotice.Next() = 0;
    end;

    /// <summary>
    /// Creates a default approval for the given privacy notice if it can be approved by default and there is not already an approval record for it.
    /// </summary>
    /// <param name="PrivacyNotice">The notice to save approval under.</param>
    local procedure TryCreateDefaultApproval(PrivacyNotice: Record "Privacy Notice")
    var
        PrivacyNoticeApproval: Codeunit "Privacy Notice Approval";
    begin
        if ShouldApproveByDefault(PrivacyNotice.ID) then begin
            PrivacyNoticeApproval.SetApprovalState(PrivacyNotice.ID, EmptyGuid, "Privacy Notice Approval State"::Agreed);
            PrivacyNotice.CalcFields(Enabled);
        end;
    end;

    [TryFunction]
    local procedure TryGetAllPrivacyNotices(var PrivacyNotice: Record "Privacy Notice" temporary)
    var
        PrivacyNoticeInterface: Codeunit "Privacy Notice";
    begin
        PrivacyNoticeInterface.OnRegisterPrivacyNotices(PrivacyNotice);
    end;

    local procedure CreatePrivacyNotice(var PrivacyNotice: Record "Privacy Notice"; Id: Code[50]; IntegrationName: Text[250]; Link: Text[2048]): Boolean
    begin
        Session.LogMessage('0000GK7', StrSubstNo(CreatePrivacyNoticeTelemetryTxt, Id), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);

        if Link = '' then
            Error(MissingLinkErr);

        PrivacyNotice.Id := Id;
        PrivacyNotice."Integration Service Name" := IntegrationName;
        PrivacyNotice.Link := Link;

        if PrivacyNotice.Insert() then begin
            TryCreateDefaultApproval(PrivacyNotice);

            exit(true);
        end;

        exit(false);
    end;

    local procedure ShowPrivacyNotice(PrivacyNotice: Record "Privacy Notice"): Boolean
    var
        PrivacyNoticeCodeunit: Codeunit "Privacy Notice";
        PrivacyNoticePage: Page "Privacy Notice";
        Handled: Boolean;
    begin
        Session.LogMessage('0000GKH', StrSubstNo(ShowingPrivacyNoticeTelemetryTxt, PrivacyNotice.Id), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
        // Allow overriding of the privacy notice
        PrivacyNoticeCodeunit.OnBeforeShowPrivacyNotice(PrivacyNotice, Handled);
        if Handled then begin
            PrivacyNotice.CalcFields(Enabled); // Refresh the enabled field from the database
            exit(PrivacyNotice.Enabled); // The user either accepted, rejected or cancelled the privacy notice. No matter the case we only return true if the privacy notice was accepted.
        end;

        PrivacyNoticePage.SetRecord(PrivacyNotice);
        PrivacyNoticePage.RunModal();
        PrivacyNoticePage.GetRecord(PrivacyNotice);
        Session.LogMessage('0000GKI', StrSubstNo(PrivacyNoticeApprovalResultTelemetryTxt, PrivacyNotice.ID, PrivacyNoticePage.GetUserApprovalState()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
        exit(PrivacyNoticePage.GetUserApprovalState() = "Privacy Notice Approval State"::Agreed); // The user either accepted, rejected or cancelled the privacy notice. No matter the case we only return true if the privacy notice was accepted.
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", ConfirmPrivacyNoticeApproval, '', false, false)]
    local procedure ConfirmSystemPrivacyNoticeApproval(PrivacyNoticeIntegrationName: Text; var IsApproved: Boolean)
    var
        PrivacyNotice: Record "Privacy Notice";
        PrivacyNoticeId: Code[50];
        PrivacyNoticeName: Text[250];
    begin
        if IsApproved then
            exit;

        PrivacyNoticeId := CopyStr(PrivacyNoticeIntegrationName, 1, 50);
        PrivacyNoticeName := CopyStr(PrivacyNoticeIntegrationName, 1, 250);
        PrivacyNotice.SetRange(ID, PrivacyNoticeId);
        if not PrivacyNotice.IsEmpty() then begin
            IsApproved := ConfirmPrivacyNoticeApproval(PrivacyNoticeId);
            exit;
        end;

        CreateDefaultPrivacyNoticesInSeparateThread(); // First attempt creating the system privacy notice by creating default privacy notices
        if not PrivacyNotice.IsEmpty() then begin
            IsApproved := ConfirmPrivacyNoticeApproval(PrivacyNoticeId);
            exit;
        end;

        if CreatePrivacyNotice(PrivacyNoticeId, PrivacyNoticeName) then begin // Manually create the privacy notice.
            Commit(); // Below may show a privacy notice, so make sure we are not in a write transaction.
            IsApproved := ConfirmPrivacyNoticeApproval(PrivacyNoticeId);
            exit;
        end;

        Session.LogMessage('0000GP9', StrSubstNo(SystemEventPrivacyNoticeNotCreatedTelemetryErr, PrivacyNoticeId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTxt);
        IsApproved := false;
    end;

    /// <summary>
    /// Checks if the IDs are equal.
    /// </summary>
    /// <param name="ID">The first ID.</param>
    /// <param name="IDToCheck">The ID to check against the first ID parameter.</param>
    /// <returns>true if equal; otherwise false.</returns>
    local procedure CheckIntegrationIDEquality(ID: Text; IDToCheck: Text): Boolean
    begin
        exit(CopyStr(UpperCase(ID), 1, 50) = CopyStr(UpperCase(IDToCheck), 1, 50));
    end;

    /// <summary>
    /// Indicates if the integration should be enabled by default.
    /// </summary>
    /// <param name="IntegrationID">The integration ID/</param>
    /// <returns>true if it should be approved by default; otherwise false.</returns>
    local procedure ShouldApproveByDefault(IntegrationID: Text): Boolean
    var
        SystemPrivacyNoticeReg: Codeunit "System Privacy Notice Reg.";
    begin
        if CheckIntegrationIDEquality(SystemPrivacyNoticeReg.GetMicrosoftLearnID(), IntegrationID) then
            exit(true);

        exit(false);
    end;

    /// <summary>
    /// Determines whether the admin or user has disagreed with the Privacy Notice.
    /// </summary>
    /// <param name="Id">Identification of an existing privacy notice.</param>
    /// <returns>Whether the Privacy Notice was disagreed to.</returns>
    procedure IsApprovalStateDisagreed(Id: Code[50]): Boolean
    var
        State: Enum "Privacy Notice Approval State";
    begin
        State := CheckPrivacyNoticeApprovalState(Id);
        exit(IsApprovalStateDisagreed(State));
    end;

    /// <summary>
    /// Determines whether the admin or user has disagreed with the Privacy Notice.
    /// </summary>
    /// <param name="State">The approval state.</param>
    /// <returns>Whether the Privacy Notice was disagreed to.</returns>
    procedure IsApprovalStateDisagreed(State: Enum "Privacy Notice Approval State"): Boolean
    begin
        exit(State = "Privacy Notice Approval State"::Disagreed);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", GetPrivacyNoticeApprovalState, '', true, true)]
    local procedure GetPrivacyNoticeApprovalState(PrivacyNoticeIntegrationName: Text; var PrivacyNoticeApprovalState: Integer)
    var
        PrivacyNoticeId: Code[50];
    begin
        PrivacyNoticeId := CopyStr(PrivacyNoticeIntegrationName, 1, 50);
        PrivacyNoticeApprovalState := CheckPrivacyNoticeApprovalState(PrivacyNoticeId).AsInteger();
    end;
}
