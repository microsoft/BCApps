// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using System.Environment;
using System.Privacy;
using System.Telemetry;

page 248 "VAT Registration Config"
{
    ApplicationArea = Basic, Suite;
    Caption = 'EU VAT Registration No. Validation Service Setup';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    PopulateAllFields = false;
    ShowFilter = false;
    SourceTable = "VAT Reg. No. Srv Config";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                InstructionalText = 'VAT Information Exchange System is an electronic means of validating VAT identification numbers of economic operators registered in the European Union for cross-border transactions on goods and services.';
                field(ServiceEndpoint; Rec."Service Endpoint")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = not Rec.Enabled;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    trigger OnValidate()
                    var
                        AuditLog: Codeunit "Audit Log";
                        CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
                        VATRegServiceEnabledLbl: Label 'VAT Registration Service enabled by UserSecurityId %1.', Locked = true;
                    begin
                        if Rec.Enabled = xRec.Enabled then
                            exit;

                        if Rec.Enabled then begin
                            if not CustomerConsentMgt.ConfirmUserConsent() then begin
                                Rec.Enabled := false;
                                exit;
                            end else
                                AuditLog.LogAuditMessage(StrSubstNo(VATRegServiceEnabledLbl, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0);

                            Rec.TestField("Service Endpoint");
                            Message(TermsAndAgreementMsg);
                        end;
                    end;
                }
                field(TermsOfServiceLbl; TermsOfServiceLbl)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies a hyperlink to disclaimer information for the service.';

                    trigger OnDrillDown()
                    var
                        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                    begin
                        HyperLink(VATRegistrationLogMgt.GetServiceDisclaimerUR());
                    end;
                }
                field(DefaultTemplate; Rec."Default Template Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Enabled;
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            group(Action7)
            {
                Caption = 'General';
                action(SettoDefault)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Default Endpoint';
                    Image = Default;
                    ToolTip = 'Set the default URL in the Service Endpoint field.';

                    trigger OnAction()
                    var
                        VATLookupExtDataHndl: Codeunit "VAT Lookup Ext. Data Hndl";
                    begin
                        if Rec.Enabled then
                            if Confirm(DisableServiceQst) then
                                Rec.Enabled := false
                            else
                                exit;

                        Rec."Service Endpoint" := VATLookupExtDataHndl.GetVATRegNrValidationWebServiceURL();
                        Rec.Modify(true);
                    end;
                }
                action(VATRegNoValidationTemplates)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Show VAT Reg. No. Service Templates';
                    Image = Default;
                    ToolTip = 'View the VAT Registration No. Service Templates.';

                    trigger OnAction()
                    var
                        VATRegNoSrvTemplates: Page "VAT Reg. No. Srv. Templates";
                    begin
                        VATRegNoSrvTemplates.RunModal();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SettoDefault_Promoted; SettoDefault)
                {
                }
                actionref(VATRegNoValidationTemplates_Promoted; VATRegNoValidationTemplates)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
    begin
        if not Rec.Get() then
            InitVATRegNrValidationSetup();

        VATRegNoSrvTemplate.CheckInitDefaultTemplate(Rec);
    end;

    var
        DisableServiceQst: Label 'You must turn off the service while you set default values. Should we turn it off for you?';
        TermsAndAgreementMsg: Label 'You are accessing a third-party website and service. Review the disclaimer before you continue.';
        TermsOfServiceLbl: Label 'VAT registration service (VIES) disclaimer';

    local procedure InitVATRegNrValidationSetup()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        VATLookupExtDataHndl: Codeunit "VAT Lookup Ext. Data Hndl";
    begin
        if Rec.FindFirst() then
            exit;

        Rec.Init();
        Rec."Service Endpoint" := VATLookupExtDataHndl.GetVATRegNrValidationWebServiceURL();
        Rec.Enabled := not EnvironmentInfo.IsSaaS();
        Rec.Insert();
    end;
}

