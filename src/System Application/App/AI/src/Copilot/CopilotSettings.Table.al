// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Privacy;

/// <summary>
/// Table to keep track of each Copilot Capability settings.
/// </summary>
table 7775 "Copilot Settings"
{
    Access = Internal;
    DataPerCompany = false;
    InherentEntitlements = rimdX;
    InherentPermissions = rimdX;
    ReplicateData = false;

    fields
    {
        field(1; Capability; Enum "Copilot Capability")
        {
            DataClassification = SystemMetadata;
        }
        field(2; "App Id"; Guid)
        {
            DataClassification = SystemMetadata;
        }
        field(3; Availability; Enum "Copilot Availability")
        {
            DataClassification = SystemMetadata;
        }
        field(4; Publisher; Text[2048])
        {
            DataClassification = SystemMetadata;
        }
        field(5; Status; Enum "Copilot Status")
        {
            DataClassification = SystemMetadata;
            InitValue = Active;
        }
        field(6; "Learn More Url"; Text[2048])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Capability, "App Id")
        {
            Clustered = true;
        }
    }

    procedure EvaluateStatus(): Enum "Copilot Status"
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if Rec.Status <> Rec.Status::Active then
            exit(Rec.Status);

        if CopilotCapability.IsCapabilityActive(Rec.Capability, Rec."App Id") then
            exit(Rec.Status::Active)
        else
            exit(Rec.Status::Inactive);
    end;

    procedure EnsurePrivacyNoticesApproved(): Boolean
    var
        CopilotCapability: Codeunit "Copilot Capability";
        PrivacyNotice: Codeunit "Privacy Notice";
        RequiredPrivacyNotices: List of [Code[50]];
        RequiredPrivacyNotice: Code[50];
    begin
        CopilotCapability.OnGetRequiredPrivacyNotices(Rec.Capability, Rec."App Id", RequiredPrivacyNotices);

        if RequiredPrivacyNotices.Count() <= 0 then
            exit(true);

        foreach RequiredPrivacyNotice in RequiredPrivacyNotices do
            if not PrivacyNotice.ConfirmPrivacyNoticeApproval(RequiredPrivacyNotice, true) then
                exit(false);

        exit(true);
    end;
}