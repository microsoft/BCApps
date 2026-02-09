// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Apps;
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
#if not CLEANSCHEMA31
        field(4; Publisher; Text[2048])
        {
            DataClassification = SystemMetadata;
#if not CLEAN28
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#endif
            ObsoleteReason = 'Replaced by "App Publisher" field which is populated from NAV App Installed table based on the App Id.';
        }
#endif
        field(5; Status; Enum "Copilot Status")
        {
            DataClassification = SystemMetadata;
            InitValue = Active;
        }
        field(6; "Learn More Url"; Text[2048])
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Service Type"; Enum "Azure AI Service Type")
        {
            DataClassification = SystemMetadata;
        }
        field(8; "Billing Type"; Enum "Copilot Billing Type")
        {
            DataClassification = SystemMetadata;
            ValuesAllowed = "Not Billed", "Microsoft Billed", "Custom Billed";
        }
        field(9; "App Installed"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("NAV App Installed App" where("App ID" = field("App Id")));
        }
        field(10; "App Publisher"; Text[250])
        {
            FieldClass = FlowField;
            CalcFormula = lookup("NAV App Installed App".Publisher where("App ID" = field("App Id")));
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