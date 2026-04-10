// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using System.Automation;
using System.Upgrade;

codeunit 104056 "Upgrade Workflow"
{
    Subtype = Upgrade;
    EventSubscriberInstance = Manual;

    trigger OnUpgradePerCompany()
    begin
        UpdateWorkflowWithDelegatedAdminTemplate();
    end;

    local procedure UpdateWorkflowWithDelegatedAdminTemplate()
    var
        WorkflowSetup: Codeunit "Workflow Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
        UpgradeWorkflow: Codeunit "Upgrade Workflow";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetWorkflowDelegatedAdminSetupTemplateUpgradeTag()) then
            exit;

        BindSubscription(UpgradeWorkflow);
        WorkflowSetup.ResetWorkflowTemplates();
        UnbindSubscription(UpgradeWorkflow);

        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetWorkflowDelegatedAdminSetupTemplateUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Setup", 'OnAllowEditOfWorkflowTemplates', '', false, false)]
    local procedure AllowDeletionOfWorkflowTemplates(var Allow: Boolean)
    begin
        Allow := true;
    end;
}