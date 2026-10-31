// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using System.Environment.Configuration;

codeunit 8435 "IC Business Setup Subscribers"
{
    var
        ICSetupTitleTxt: Label 'Set up intercompany postings';
        ICSetupShortTitleTxt: Label 'Intercompany setup';
        ICSetupDescriptionTxt: Label 'Set up how you want to electronically transfer transactions between the current company and partner companies.';
        ICSetupKeywordsTxt: Label 'Intercompany';
        ICPartnersTitleTxt: Label 'Intercompany partners';
        ICPartnersShortTitleTxt: Label 'Intercompany partners';
        ICPartnersDescriptionTxt: Label 'View or edit the codes for partners that you have intercompany transactions with.';
        ICPartnersKeywordsTxt: Label 'Intercompany, Partners';
        ICChartOfAccountsTitleTxt: Label 'Intercompany chart of accounts';
        ICChartOfAccountsShortTitleTxt: Label 'Intercompany chart of accounts';
        ICChartOfAccountsDescriptionTxt: Label 'Specify how you want to map the current company''s chart of accounts to the charts of accounts of your intercompany partners.';
        ICChartOfAccountsKeywordsTxt: Label 'Intercompany, Ledger, Finance';
        ICDimensionsTitleTxt: Label 'Intercompany dimensions';
        ICDimensionsShortTitleTxt: Label 'Intercompany dimensions';
        ICDimensionsDescriptionTxt: Label 'Specify how you want to map the current company''s dimension codes to the dimension codes of your intercompany partners.';
        ICDimensionsKeywordsTxt: Label 'Intercompany, Dimensions';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure InsertSetupOnRegisterManualSetup(var Sender: Codeunit "Guided Experience")
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        if ApplicationAreaMgmtFacade.IsIntercompanyEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then begin
            Sender.InsertManualSetup(
                ICSetupTitleTxt, ICSetupShortTitleTxt, ICSetupDescriptionTxt, 2, ObjectType::Page,
                Page::"Intercompany Setup", ManualSetupCategory::Intercompany, ICSetupKeywordsTxt);

            Sender.InsertManualSetup(ICPartnersTitleTxt, ICPartnersShortTitleTxt, ICPartnersDescriptionTxt, 5, ObjectType::Page,
              Page::"IC Partner List", ManualSetupCategory::Intercompany, ICPartnersKeywordsTxt);

            Sender.InsertManualSetup(ICChartOfAccountsTitleTxt, ICChartOfAccountsShortTitleTxt, ICChartOfAccountsDescriptionTxt, 10, ObjectType::Page,
              Page::"IC Chart of Accounts", ManualSetupCategory::Intercompany, ICChartOfAccountsKeywordsTxt);

            Sender.InsertManualSetup(ICDimensionsTitleTxt, ICDimensionsShortTitleTxt, ICDimensionsDescriptionTxt, 3, ObjectType::Page,
              Page::"IC Dimension List", ManualSetupCategory::Intercompany, ICDimensionsKeywordsTxt);
        end;
    end;
}
