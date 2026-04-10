// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using System.Environment.Configuration;
using System.Integration;

codeunit 5466 "Graph Mgt - In. Services Setup"
{

    trigger OnRun()
    begin
    end;

    var
        BusinessSetupTitleTxt: Label 'Set up integration services';
        BusinessSetupShortTitleTxt: Label 'Integration services setup';
        BusinessSetupDescriptionTxt: Label 'Specify the data that you want to expose in integration services.';
        BusinessSetupKeywordsTxt: Label 'Integration, Service, Expose, Setup';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure HandleAPISetup(var Sender: Codeunit "Guided Experience")
    var
        Info: ModuleInfo;
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Sender.InsertManualSetup(
          BusinessSetupTitleTxt, BusinessSetupShortTitleTxt, BusinessSetupDescriptionTxt, 5, ObjectType::Page,
          PAGE::"Integration Services Setup", ManualSetupCategory::Service, BusinessSetupKeywordsTxt);
    end;
}

