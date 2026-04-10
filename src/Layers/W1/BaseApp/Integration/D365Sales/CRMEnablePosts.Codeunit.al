// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

codeunit 5353 "CRM Enable Posts"
{

    trigger OnRun()
    begin
        if EnableActivityFeedsOnCRMOrders() then;
    end;

    var
        CRMOrderEntityNameTxt: Label 'salesorder', Locked = true;

    [TryFunction]
    local procedure EnableActivityFeedsOnCRMOrders()
    var
        CRMPostConfiguration: Record "CRM Post Configuration";
    begin
        CRMPostConfiguration.SetRange(msdyn_EntityName, CRMOrderEntityNameTxt);
        if CRMPostConfiguration.FindFirst() then begin
            if (CRMPostConfiguration.statecode = CRMPostConfiguration.statecode::Active) and (CRMPostConfiguration.statuscode = CRMPostConfiguration.statuscode::Active) and CRMPostConfiguration.msdyn_ConfigureWall then
                exit;
            CRMPostConfiguration.statecode := CRMPostConfiguration.statecode::Active;
            CRMPostConfiguration.statuscode := CRMPostConfiguration.statuscode::Active;
            CRMPostConfiguration.msdyn_ConfigureWall := true;
            if CRMPostConfiguration.Modify() then;
        end
    end;
}

