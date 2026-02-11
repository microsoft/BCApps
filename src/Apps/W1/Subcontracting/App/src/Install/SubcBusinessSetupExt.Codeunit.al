// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Company;
using System.Environment.Configuration;

codeunit 99001502 "Subc. Business Setup Ext."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", OnRegisterManualSetup, '', false, false)]
    local procedure OnRegisterManualSetup(sender: Codeunit "Guided Experience")
    var
        ManualSetupCategory: Enum "Manual Setup Category";
        SubcontractingDescriptionLbl: Label 'Make manual Subcontracting Setup';
        SubcontractingKeyWordsLbl: Label 'Subcontracting, Management';
        SubcontractingLbl: Label 'Subcontracting App';
    begin
        sender.InsertManualSetup(SubcontractingLbl, SubcontractingLbl, SubcontractingDescriptionLbl, 0, ObjectType::Page, Page::"Subc. Management Setup", ManualSetupCategory::Uncategorized, SubcontractingKeyWordsLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", OnCompanyInitialize, '', false, false)]
    local procedure OnCompanyInitialize()
    var
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
    end;
}