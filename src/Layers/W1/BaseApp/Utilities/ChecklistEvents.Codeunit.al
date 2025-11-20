// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using System.Environment.Configuration;
using System.Environment;
using System.Reflection;
using Microsoft.Finance.RoleCenters;
using Microsoft.Sales.Customer;
using Microsoft.Inventory.Item;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.RoleCenters;
using System.Azure.Identity;
using System.Integration;
using System.Security.User;
using System.Email;

codeunit 1997 "Checklist Events"
{
    var
        YourSalesWithinOutlookVideoLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2170901', Locked = true;
        ReadyToGoLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2198402', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogIn()
    var
        Company: Record Company;
        SignupContextValues: Record "Signup Context Values";
        Checklist: Codeunit Checklist;
        SystemInitialization: Codeunit "System Initialization";
    begin
        if not (Session.CurrentClientType() in [ClientType::Web, ClientType::Windows, ClientType::Desktop]) then
            exit;

        if not Checklist.ShouldInitializeChecklist(false) then
            exit;

        if not Company.Get(CompanyName()) then
            exit;

        if SystemInitialization.ShouldCheckSignupContext() then
            if SignupContextValues.Get() then
                if not (SignupContextValues."Signup Context" in [SignupContextValues."Signup Context"::" ", SignupContextValues."Signup Context"::"Viral Signup"]) then
                    exit;

        Checklist.InitializeGuidedExperienceItems();

        if Company."Evaluation Company" then
            InitializeChecklistForEvaluationCompanies()
        else
            InitializeChecklistForNonEvaluationCompanies();

        Checklist.MarkChecklistSetupAsDone();
    end;

    local procedure InitializeChecklistForEvaluationCompanies()
    var
        TempAllProfiles: Record "All Profile" temporary;
        TempAllProfileBusinessManagerEval: Record "All Profile" temporary;
        TempAllProfileAccountant: Record "All Profile" temporary;
        TempAllProfileSalesOrderProcessor: Record "All Profile" temporary;
        Checklist: Codeunit Checklist;
        TenantLicenseState: Codeunit "Tenant License State";
        GuidedExperienceType: Enum "Guided Experience Type";
        SpotlightTourType: Enum "Spotlight Tour Type";
    begin
        // Business Manager Evaluation
        GetRolesForEvaluationCompany(TempAllProfileBusinessManagerEval);

        Checklist.Insert(GuidedExperienceType::Tour, ObjectType::Page, Page::"Business Manager Role Center", 1000, TempAllProfileBusinessManagerEval, true);
        Checklist.Insert(Page::"Customer List", SpotlightTourType::"Open in Excel", 2000, TempAllProfileBusinessManagerEval, true);

        Checklist.Insert(Page::"Item Card", SpotlightTourType::"Share to Teams", 3000, TempAllProfileBusinessManagerEval, true);

        Checklist.Insert(GuidedExperienceType::Video, YourSalesWithinOutlookVideoLinkTxt, 4000, TempAllProfileBusinessManagerEval, true);

        Checklist.Insert(Page::"Item Card", SpotlightTourType::Copilot, 5000, TempAllProfileBusinessManagerEval, true);

        if not TenantLicenseState.IsPaidMode() then
            Checklist.Insert(enum::"Guided Experience Type"::Learn, ReadyToGoLinkTxt, 9000, TempAllProfileBusinessManagerEval, true);

        // Accountant
        GetAccountantRole(TempAllProfileAccountant);
        Checklist.Insert(GuidedExperienceType::Tour, ObjectType::Page, Page::"Accountant Role Center", 1000, TempAllProfileAccountant, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Chart of Accounts", 3000, TempAllProfileAccountant, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Bank Account List", 4000, TempAllProfileAccountant, true);

        // Sales Order Processor
        GetSalesOrderProcessorRole(TempAllProfileSalesOrderProcessor);
        Checklist.Insert(GuidedExperienceType::Tour, ObjectType::Page, Page::"Order Processor Role Center", 1000, TempAllProfileSalesOrderProcessor, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Sales Quotes", 3000, TempAllProfileSalesOrderProcessor, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Sales Order List", 4000, TempAllProfileSalesOrderProcessor, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Sales Invoice List", 5000, TempAllProfileSalesOrderProcessor, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Posted Sales Invoices", 6000, TempAllProfileSalesOrderProcessor, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Sales Return Order List", 7000, TempAllProfileSalesOrderProcessor, true);

        // all roles
        GetAllRoles(TempAllProfiles);
        Checklist.Insert(GuidedExperienceType::Learn, 'https://go.microsoft.com/fwlink/?linkid=2152979', 8000, TempAllProfiles, true);
    end;

    local procedure InitializeChecklistForNonEvaluationCompanies()
    var
        TempAllProfiles: Record "All Profile" temporary;
        TempAllProfileBusinessManager: Record "All Profile" temporary;
        TempAllProfileAccountant: Record "All Profile" temporary;
        TempAllProfileSalesOrderProcessor: Record "All Profile" temporary;
        Checklist: Codeunit Checklist;
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        // Business Manager
        GetBussinesManagerRole(TempAllProfileBusinessManager);
        Checklist.Insert(GuidedExperienceType::Tour, ObjectType::Page, Page::"Business Manager Role Center", 500, TempAllProfileBusinessManager, true);
        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Assisted Company Setup Wizard", 1000, TempAllProfileBusinessManager, false);
        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Azure AD User Update Wizard", 2000, TempAllProfileBusinessManager, false);
        Checklist.Insert(GuidedExperienceType::"Manual Setup", ObjectType::Page, Page::Users, 3000, TempAllProfileBusinessManager, false);
        Checklist.Insert(GuidedExperienceType::"Manual Setup", ObjectType::Page, Page::"User Settings List", 4000, TempAllProfileBusinessManager, false);
        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Email Account Wizard", 5000, TempAllProfileBusinessManager, false);
        Checklist.Insert(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Data Migration Wizard", 6000, TempAllProfileBusinessManager, false);

        // Accountant
        GetAccountantRole(TempAllProfileAccountant);
        Checklist.Insert(GuidedExperienceType::Tour, ObjectType::Page, Page::"Accountant Role Center", 1000, TempAllProfileAccountant, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Chart of Accounts", 3000, TempAllProfileAccountant, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Bank Account List", 4000, TempAllProfileAccountant, true);

        // Sales Order Processor
        GetSalesOrderProcessorRole(TempAllProfileSalesOrderProcessor);
        Checklist.Insert(GuidedExperienceType::Tour, ObjectType::Page, Page::"Order Processor Role Center", 1000, TempAllProfileSalesOrderProcessor, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Sales Quotes", 3000, TempAllProfileSalesOrderProcessor, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Sales Order List", 4000, TempAllProfileSalesOrderProcessor, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Sales Invoice List", 5000, TempAllProfileSalesOrderProcessor, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Posted Sales Invoices", 6000, TempAllProfileSalesOrderProcessor, true);
        Checklist.Insert(GuidedExperienceType::"Application Feature", ObjectType::Page, Page::"Sales Return Order List", 7000, TempAllProfileSalesOrderProcessor, true);

        // all roles
        GetAllRoles(TempAllProfiles);
        Checklist.Insert(GuidedExperienceType::Learn, 'https://go.microsoft.com/fwlink/?linkid=2152979', 8000, TempAllProfiles, true);
    end;

    local procedure GetAllRoles(var TempAllProfiles: Record "All Profile" temporary)
    begin
        AddRoleToList(TempAllProfiles, Page::"Business Manager Role Center");
        AddRoleToList(TempAllProfiles, Page::"Accountant Role Center");
        AddRoleToList(TempAllProfiles, Page::"Order Processor Role Center");
    end;

    local procedure GetBussinesManagerRole(var TempAllProfile: Record "All Profile" temporary)
    begin
        AddRoleToList(TempAllProfile, Page::"Business Manager Role Center");
    end;

    local procedure GetAccountantRole(var TempAllProfileAccountant: Record "All Profile" temporary)
    begin
        AddRoleToList(TempAllProfileAccountant, Page::"Accountant Role Center");
    end;

    local procedure GetSalesOrderProcessorRole(var TempAllProfileSalesOrderProcessor: Record "All Profile" temporary)
    begin
        AddRoleToList(TempAllProfileSalesOrderProcessor, Page::"Order Processor Role Center");
    end;

    local procedure GetRolesForEvaluationCompany(var TempAllProfile: Record "All Profile" temporary)
    begin
        AddRoleToList(TempAllProfile, 'Business Manager Evaluation');
    end;

    local procedure AddRoleToList(var TempAllProfile: Record "All Profile" temporary; RoleCenterID: Integer)
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Role Center ID", RoleCenterID);
        AddRoleToList(AllProfile, TempAllProfile);
    end;

    local procedure AddRoleToList(var TempAllProfile: Record "All Profile" temporary; ProfileID: Code[30])
    var
        AllProfile: Record "All Profile";
    begin
        AllProfile.SetRange("Profile ID", ProfileID);
        AddRoleToList(AllProfile, TempAllProfile);
    end;

    local procedure AddRoleToList(var AllProfile: Record "All Profile"; var TempAllProfile: Record "All Profile" temporary)
    begin
        if AllProfile.FindFirst() then begin
            TempAllProfile.TransferFields(AllProfile);
            TempAllProfile.Insert();
        end;
    end;
}