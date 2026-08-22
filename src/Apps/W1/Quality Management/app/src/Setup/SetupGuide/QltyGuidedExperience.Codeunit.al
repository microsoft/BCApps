// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.GuidedExperience;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.RoleCenters;
using Microsoft.QualityManagement.Setup;
using System.Environment;
using System.Environment.Configuration;
using System.Reflection;

codeunit 20419 "Qlty. Guided Experience"
{
    Access = Internal;

    var
        QualityManagerRoleCenterTourShortTitleTxt: Label 'A first look around';
        QualityManagerRoleCenterTourTitleTxt: Label 'Take a first look around';
        QualityManagerRoleCenterTourDescriptionTxt: Label 'The Quality Manager home page offers metrics and activities that help run a business. We`ll also show you how to explore all Business Central features.';
        DemoDataShortTitleTxt: Label 'Demo data';
        DemoDataTitleTxt: Label 'Explore with demo data';
        DemoDataDescriptionTxt: Label 'Install or explore Contoso demo data for Quality Management with sample quality tests, templates, generation rules, and inspections. This lets you learn how quality checks work without setting up your own data.';
        QualityResultsShortTitleTxt: Label 'Inspection results';
        QualityResultsTitleTxt: Label 'Set up quality inspection results';
        QualityResultsDescriptionTxt: Label 'Define custom grades for quality inspections, to match your organization''s standards. You can decide evaluation priorities and set conditions for allowed transactions.';
        QualityTestsShortTitleTxt: Label 'Quality tests';
        QualityTestsTitleTxt: Label 'Understand quality tests';
        QualityTestsDescriptionTxt: Label 'Quality tests define what is measured. Visit the Quality Tests list to see available tests, then open a test card to review parameters, limits, and expected values used during inspections.';
        QualityTemplatesShortTitleTxt: Label 'Quality templates';
        QualityTemplatesTitleTxt: Label 'Reuse inspection templates';
        QualityTemplatesDescriptionTxt: Label 'With templates you can group and reuse quality tests to ensure consistent inspection standards. Try creating a new template card to understand its structure and purpose.';
        GenerationRulesShortTitleTxt: Label 'Generation rules';
        GenerationRulesTitleTxt: Label 'Set up inspection generation rules';
        GenerationRulesDescriptionTxt: Label 'Inspection generation rules define when quality inspections are created automatically, such as during receiving, production, or assembly.';
        QualityInspectionsShortTitleTxt: Label 'Quality inspections';
        QualityInspectionsTitleTxt: Label 'Track and create inspections';
        QualityInspectionsDescriptionTxt: Label 'Browse the Quality Inspections list to see inspections created by rules or manually. Process items that fail inspection by relocating, quarantining, or returning them to suppliers.';
        DefaultSetupShortTitleTxt: Label 'Default setup';
        DefaultSetupTitleTxt: Label 'Quality management default settings';
        DefaultSetupDescriptionTxt: Label 'Manage default settings for when inspections are created. Set up test generation rule triggers for production, inventory, and warehouse scenarios.';
        MicrosoftLearnShortTitleTxt: Label 'Microsoft Learn';
        MicrosoftLearnTitleTxt: Label 'Discover more capabilities';
        MicrosoftLearnDescriptionTxt: Label 'Discover what else you can do in your role. Explore Business Central''s quality capabilities to reach your needs, from manual or automated inspections on Microsoft Learn.';
        MicrosoftLearnLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2338953', Locked = true;
        NewHeaderTxt: Label 'Explore Quality Management!';
        NewTitleTxt: Label 'Get started';
        NewDescriptionTxt: Label 'We''ve prepared a short list of guided tours to help you discover key pages and default setup steps.';
        InProgressHeaderTxt: Label 'Here are a few things you can try out';
        InProgressTitleTxt: Label 'Get started';
        InProgressDescriptionTxt: Label 'The Contoso demo data is for demonstration, evaluation, and training purposes only.';

    /// <summary>
    /// Registers the Quality Management guided experience items.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterGuidedExperienceItem', '', false, false)]
    local procedure OnRegisterGuidedExperienceItem()
    begin
        RegisterGuidedExperienceItems();
    end;

    /// <summary>
    /// Registers guided experience and checklist items once after an eligible client login.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure InitializeChecklistOnAfterLogIn()
    var
        Company: Record Company;
        QltyManagementSetup: Record "Qlty. Management Setup";
        SetupExists: Boolean;
    begin
        if not (Session.CurrentClientType() in [ClientType::Web, ClientType::Windows, ClientType::Desktop]) then
            exit;

        if not (QltyManagementSetup.ReadPermission() and QltyManagementSetup.WritePermission()) then
            exit;

        if not Company.Get(CompanyName()) then
            exit;

        SetupExists := QltyManagementSetup.Get();
        if not SetupExists then
            QltyManagementSetup.Insert();

        // Register guided experience items only once
        if not QltyManagementSetup."Guided Experience Registered" then begin
            RegisterGuidedExperienceItems();
            QltyManagementSetup."Guided Experience Registered" := true;
            QltyManagementSetup.Modify();
        end;

        // Register checklist items only once
        if not QltyManagementSetup."Checklist Items Registered" then begin
            InitializeChecklist();
            QltyManagementSetup."Checklist Items Registered" := true;
            QltyManagementSetup.Modify();
        end;
    end;

    /// <summary>
    /// Replaces checklist banner labels for the Quality Manager role center.
    /// </summary>
    /// <param name="IsHandled">Set to true when the banner labels are supplied by this subscriber.</param>
    /// <param name="IsEvaluationCompany">Indicates whether the current company is an evaluation company.</param>
    /// <param name="TitleTxt">The expanded banner title to update.</param>
    /// <param name="TitleCollapsedTxt">The collapsed banner title to update.</param>
    /// <param name="HeaderTxt">The expanded banner header to update.</param>
    /// <param name="HeaderCollapsedTxt">The collapsed banner header to update.</param>
    /// <param name="DescriptionTxt">The banner description to update.</param>
    /// <param name="IsSetupStarted">Indicates whether checklist setup has started.</param>
    /// <param name="AreAllItemsSkippedOrCompleted">Indicates whether all checklist items are skipped or completed.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Checklist Banner", 'OnBeforeUpdateBannerLabels', '', false, false)]
    local procedure OnBeforeUpdateBannerLabels(var IsHandled: Boolean; IsEvaluationCompany: Boolean; var TitleTxt: Text; var TitleCollapsedTxt: Text; var HeaderTxt: Text; var HeaderCollapsedTxt: Text; var DescriptionTxt: Text; IsSetupStarted: Boolean; AreAllItemsSkippedOrCompleted: Boolean)

    begin
        if not IsQualityManagerRoleCenter() then
            exit;

        IsHandled := true;

        if IsSetupStarted then begin
            TitleTxt := InProgressTitleTxt;
            HeaderTxt := InProgressHeaderTxt;
            DescriptionTxt := InProgressDescriptionTxt;
        end else begin
            TitleTxt := NewTitleTxt;
            HeaderTxt := NewHeaderTxt;
            DescriptionTxt := NewDescriptionTxt;
        end;
    end;

    /// <summary>
    /// Determines whether the current user has the Quality Manager role center.
    /// </summary>
    /// <returns>True if the current profile uses the Quality Manager role center; otherwise, false.</returns>
    local procedure IsQualityManagerRoleCenter(): Boolean
    var
        UserPersonalization: Record "User Personalization";
        AllProfile: Record "All Profile";
    begin
        if not UserPersonalization.Get(UserSecurityId()) then
            exit(false);

        AllProfile.SetRange("Profile ID", UserPersonalization."Profile ID");
        AllProfile.SetRange("App ID", UserPersonalization."App ID");
        AllProfile.SetRange(Scope, UserPersonalization.Scope);
        if not AllProfile.FindFirst() then
            exit(false);

        exit(AllProfile."Role Center ID" = Page::"Qlty. Manager Role Center");
    end;

    /// <summary>
    /// Registers Quality Management tours, application features, and the learn link.
    /// </summary>
    local procedure RegisterGuidedExperienceItems()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        // Register all guided experience items for Quality Management
        GuidedExperience.InsertTour(QualityManagerRoleCenterTourTitleTxt, QualityManagerRoleCenterTourShortTitleTxt,
            QualityManagerRoleCenterTourDescriptionTxt, 2, Page::"Qlty. Manager Role Center");

        GuidedExperience.InsertApplicationFeature(DemoDataTitleTxt, DemoDataShortTitleTxt, DemoDataDescriptionTxt, 3, ObjectType::Codeunit,
            Codeunit::"Qlty. Demo Data Runner");
        GuidedExperience.InsertApplicationFeature(QualityResultsTitleTxt, QualityResultsShortTitleTxt, QualityResultsDescriptionTxt, 4, ObjectType::Page,
            Page::"Qlty. Inspection Result List");
        GuidedExperience.InsertApplicationFeature(QualityTestsTitleTxt, QualityTestsShortTitleTxt, QualityTestsDescriptionTxt, 3, ObjectType::Page,
            Page::"Qlty. Tests");
        GuidedExperience.InsertApplicationFeature(QualityTemplatesTitleTxt, QualityTemplatesShortTitleTxt, QualityTemplatesDescriptionTxt, 3, ObjectType::Page,
            Page::"Qlty. Inspection Template List");
        GuidedExperience.InsertApplicationFeature(GenerationRulesTitleTxt, GenerationRulesShortTitleTxt, GenerationRulesDescriptionTxt, 3, ObjectType::Page,
            Page::"Qlty. Inspection Gen. Rules");
        GuidedExperience.InsertApplicationFeature(QualityInspectionsTitleTxt, QualityInspectionsShortTitleTxt, QualityInspectionsDescriptionTxt, 3, ObjectType::Page,
            Page::"Qlty. Inspection List");
        GuidedExperience.InsertApplicationFeature(DefaultSetupTitleTxt, DefaultSetupShortTitleTxt, DefaultSetupDescriptionTxt, 3, ObjectType::Page,
            Page::"Qlty. Management Setup");

        GuidedExperience.InsertLearnLink(MicrosoftLearnTitleTxt, MicrosoftLearnShortTitleTxt, MicrosoftLearnDescriptionTxt, 5, MicrosoftLearnLinkTxt);
    end;

    /// <summary>
    /// Adds the Quality Management checklist entries for the Quality Manager profile.
    /// </summary>
    local procedure InitializeChecklist()
    var
        TempAllProfileQualityManager: Record "All Profile" temporary;
        Checklist: Codeunit Checklist;
    begin
        GetQualityManagerRole(TempAllProfileQualityManager);

        Checklist.Insert("Guided Experience Type"::"Application Feature", ObjectType::Codeunit, Codeunit::"Qlty. Demo Data Runner", 1000, TempAllProfileQualityManager, true);
        Checklist.Insert("Guided Experience Type"::"Application Feature", ObjectType::Page, Page::"Qlty. Inspection Result List", 2000, TempAllProfileQualityManager, true);
        Checklist.Insert("Guided Experience Type"::"Application Feature", ObjectType::Page, Page::"Qlty. Tests", 3000, TempAllProfileQualityManager, true);
        Checklist.Insert("Guided Experience Type"::"Application Feature", ObjectType::Page, Page::"Qlty. Inspection Template List", 4000, TempAllProfileQualityManager, true);
        Checklist.Insert("Guided Experience Type"::"Application Feature", ObjectType::Page, Page::"Qlty. Inspection Gen. Rules", 5000, TempAllProfileQualityManager, true);
        Checklist.Insert("Guided Experience Type"::"Application Feature", ObjectType::Page, Page::"Qlty. Inspection List", 6000, TempAllProfileQualityManager, true);
        Checklist.Insert("Guided Experience Type"::"Application Feature", ObjectType::Page, Page::"Qlty. Management Setup", 7000, TempAllProfileQualityManager, true);
        Checklist.Insert("Guided Experience Type"::Learn, MicrosoftLearnLinkTxt, 8000, TempAllProfileQualityManager, true);

        Checklist.MarkChecklistSetupAsDone();
    end;

    /// <summary>
    /// Adds the Quality Manager profile to a temporary profile collection.
    /// </summary>
    /// <param name="TempAllProfile">The temporary profile collection to populate.</param>
    local procedure GetQualityManagerRole(var TempAllProfile: Record "All Profile" temporary)
    begin
        AddRoleToList(TempAllProfile, Page::"Qlty. Manager Role Center");
    end;

    /// <summary>
    /// Finds a profile by role center and adds it to a temporary profile collection.
    /// </summary>
    /// <param name="TempAllProfile">The temporary profile collection to populate.</param>
    /// <param name="RoleCenterID">The role center page identifier to find.</param>
    local procedure AddRoleToList(var TempAllProfile: Record "All Profile" temporary; RoleCenterID: Integer)
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Role Center ID", RoleCenterID);
        AddRoleToList(AllProfile, TempAllProfile);
    end;

    /// <summary>
    /// Adds the first filtered profile to a temporary profile collection.
    /// </summary>
    /// <param name="AllProfile">The filtered profile record to read.</param>
    /// <param name="TempAllProfile">The temporary profile collection to populate.</param>
    local procedure AddRoleToList(var AllProfile: Record "All Profile"; var TempAllProfile: Record "All Profile" temporary)
    begin
        if AllProfile.FindFirst() then begin
            TempAllProfile.TransferFields(AllProfile);
            TempAllProfile.Insert();
        end;
    end;


}
