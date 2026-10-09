// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.FixedAsset;

using Microsoft.DemoTool;

codeunit 13486 "Dep. Diff. Demo Data FI"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnBeforeGeneratingDemoData', '', false, false)]
    local procedure OnBeforeGeneratingDemoData(Module: Enum "Contoso Demo Data Module"; ContosoDemoDataLevel: Enum "Contoso Demo Data Level")
    var
        CreateDeprDiffFAPostGrp: Codeunit "Create Depr. Diff. FA Post Grp";
    begin
        if not IsFixedAssetSetupData(Module, ContosoDemoDataLevel) then
            exit;

        BindSubscription(CreateDeprDiffFAPostGrp);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnAfterGeneratingDemoData', '', false, false)]
    local procedure OnAfterGeneratingDemoData(Module: Enum "Contoso Demo Data Module"; ContosoDemoDataLevel: Enum "Contoso Demo Data Level")
    var
        CreateDeprDiffFAPostGrp: Codeunit "Create Depr. Diff. FA Post Grp";
    begin
        if not IsFixedAssetSetupData(Module, ContosoDemoDataLevel) then
            exit;

        UnBindSubscription(CreateDeprDiffFAPostGrp);
    end;

    local procedure IsFixedAssetSetupData(Module: Enum "Contoso Demo Data Module"; ContosoDemoDataLevel: Enum "Contoso Demo Data Level"): Boolean
    begin
        exit((Module = Enum::"Contoso Demo Data Module"::"Fixed Asset Module") and
            (ContosoDemoDataLevel = Enum::"Contoso Demo Data Level"::"Setup Data"));
    end;
}
