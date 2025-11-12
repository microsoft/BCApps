// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using System.Utilities;

page 7213 "CRM BC Virtual Table Config."
{
    Editable = false;
    Caption = 'Virtual Table Configuration - Dataverse';
    DataCaptionExpression = Rec.msdyn_name;
    SourceTable = "CRM BC Virtual Table Config.";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            field("Target Host"; Rec.msdyn_targethost)
            {
                ApplicationArea = Suite;
                Caption = 'Target Host';
                ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
            }
            field("Environment Name"; Rec.msdyn_environment)
            {
                ApplicationArea = Suite;
                Caption = 'Environment Name';
                ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
            }
            field("Default Company"; DefaultCompany)
            {
                ApplicationArea = Suite;
                Editable = false;
                Enabled = false;
                Caption = 'Default Company';
                ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
            }
            field("Tenant ID"; Rec.msdyn_tenantid)
            {
                ApplicationArea = Suite;
                Caption = 'Tenant ID';
                ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                Visible = IsPPE;
            }
            field("AAD User ID"; Rec.msdyn_aadUserId)
            {
                ApplicationArea = Suite;
                Caption = 'Microsoft Entra user ID';
                ToolTip = 'Specifies data from a corresponding field in a Dataverse entity. For more information about Dataverse, see Dataverse Help Center.';
                Visible = IsPPE;
            }
        }
    }
    actions
    {
        area(navigation)
        {
            action("Open in Dataverse")
            {
                ApplicationArea = Suite;
                Caption = 'Open in Dataverse';
                Image = Setup;
                ToolTip = 'Manage configuration settings for virtual tables in your Dataverse environment.';

                trigger OnAction()
                begin
                    CDSIntegrationImpl.ShowVirtualTablesConfig(CDSConnectionSetup);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Open in Dataverse_Promoted"; "Open in Dataverse")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        CDSConnectionSetup.Get();
        CDSIntegrationImpl.CheckConnectionRequiredFields(CDSConnectionSetup, false);
        if not TryInitAsUser() then
            InitAsAdmin();
        IsPPE := UrlHelper.IsPPE();
    end;

    [TryFunction]
    local procedure TryInitAsUser()
    begin
        Initialize(CDSConnectionSetup);
    end;

    local procedure InitAsAdmin()
    var
        TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        AccessToken: SecretText;
    begin
        CDSIntegrationImpl.GetAccessToken(CDSConnectionSetup."Server Address", true, AccessToken);
        CDSIntegrationImpl.GetTempConnectionSetup(TempCDSConnectionSetup, CDSConnectionSetup, AccessToken);
        Initialize(TempCDSConnectionSetup);
    end;

    local procedure Initialize(var InitCDSConnectionSetup: Record "CDS Connection Setup")
    var
        CRMBCVirtualTableConfig: Record "CRM BC Virtual Table Config.";
        CRMCompany: Record "CRM Company";
    begin
        TempConnectionName := CDSIntegrationImpl.GetTempConnectionName();
        CDSIntegrationImpl.RegisterConnection(InitCDSConnectionSetup, TempConnectionName);
        SetDefaultTableConnection(TableConnectionType::CRM, TempConnectionName, true);

        CRMBCVirtualTableConfig.SetRange(msdyn_name, 'Business Central');
        if CRMBCVirtualTableConfig.FindFirst() then begin
            Rec.Init();
            Rec.TransferFields(CRMBCVirtualTableConfig);
            Rec.Insert();
        end;

        if CRMCompany.Get(Rec.msdyn_DefaultCompanyId) then
            DefaultCompany := CRMCompany.cdm_Name;

        UnregisterTableConnection(TableConnectionType::CRM, TempConnectionName);
    end;

    var
        CDSConnectionSetup: Record "CDS Connection Setup";
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        UrlHelper: Codeunit "Url Helper";
        TempConnectionName: Text;
        DefaultCompany: Text[100];
        IsPPE: Boolean;
}