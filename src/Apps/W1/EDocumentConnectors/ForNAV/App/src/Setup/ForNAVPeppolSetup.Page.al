// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Azure.Identity;
using System.EMail;
using System.Environment;
using System.Utilities;

page 6413 "ForNAV Peppol Setup"
{
    PageType = Card;
    Caption = 'ForNAV E-Document Connector Setup';
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "ForNAV Peppol Setup";
    DataCaptionExpression = Rec.Authorized ? Format(Rec.Status) : AuthorizeLbl;
    AdditionalSearchTerms = 'ForNAV Peppol Setup';
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Identification)
            {
                Caption = 'Identification';
                Editable = Rec.Status <> Rec.Status::Published;
                field(Code; Rec."Identification Code")
                {
                    ApplicationArea = All;
                }
                field(Value; Rec."Identification Value")
                {
                    ApplicationArea = All;
                }
                field(Test; Rec.Test)
                {
                    Caption = 'Test';
                    ApplicationArea = All;
                    Editable = not Rec."Demo Company";
                }
            }
            group("Business Card")
            {
                Editable = Rec.Status <> Rec.Status::Published;
                Caption = 'Business Card';
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }

                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                }

                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                }

                field(Language; Rec.Language)
                {
                    ApplicationArea = All;
                }

                field("Home Page"; Rec."Home Page")
                {
                    ApplicationArea = All;
                }
            }
            group(Defaults)
            {
                Caption = 'Defaults';
                field("E-Document Service"; Rec."E-Document Service")
                {
                    ApplicationArea = All;
                }
                field("Document Sending Profile"; Rec."Document Sending Profile")
                {
                    ApplicationArea = All;
                }
            }
            group(ConnectionSetup)
            {
                Caption = 'Connection Setup';
                field(ClientId; ClientId)
                {
                    Caption = 'Client Id';
                    ToolTip = 'Specifies the Oauth Client Id. You can get this from your ForNAV partner.';
                    ApplicationArea = All;
                    Editable = ShowConnectionSetup;

                    trigger OnValidate()
                    begin
                        PeppolOauth.ValidateClientID(ClientId);
                    end;
                }
                field(PeppolEndpoint; PeppolEndpoint)
                {
                    Caption = 'Peppol Endpoint';
                    ToolTip = 'Specifies the Peppol Endpoint. You can get this from your ForNAV partner.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        PeppolOauth.ValidateEndpoint(PeppolEndpoint, true);
                    end;
                }
                field(ForNAVTenantId; ForNAVTenantId)
                {
                    Caption = 'ForNAV Tenant Id';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Oauth Tenant Id. You can get this from your ForNAV partner.';
                    Visible = ShowConnectionSetup;
                    Editable = ShowConnectionSetup;

                    trigger OnValidate()
                    begin
                        PeppolOauth.ValidateForNAVTenantID(ForNAVTenantId);
                    end;
                }
                field(ClientSecret; ClientSecret)
                {
                    Caption = 'Client Secret';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Oauth Client Secret. You can get this from your ForNAV partner.';
                    ExtendedDatatype = Masked;
                    Visible = ShowConnectionSetup;
                    Editable = ShowConnectionSetup;

                    trigger OnValidate()
                    begin
                        PeppolOauth.ValidateSecret(ClientSecret);
                    end;
                }
                field(Scope; Scope)
                {
                    Caption = 'Scope';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Oauth Scope. You can get this from your ForNAV partner.';
                    ExtendedDatatype = Masked;
                    Visible = ShowConnectionSetup;
                    Editable = ShowConnectionSetup;

                    trigger OnValidate()
                    begin
                        PeppolOauth.ValidateScope(Scope);
                    end;
                }
                field(SecretValidFrom; SecretValidFrom)
                {
                    Caption = 'Secret Valid From';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Oauth Secret Valid From. The secret will renew automatically, if a secret is expired please contact your ForNAV partner.';
                    Editable = false;
                }
                field(SecretValidTo; SecretValidTo)
                {
                    Caption = 'Secret Expiration';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Oauth Secret Expiration. The secret will renew automatically, if a secret is expired please contact your ForNAV partner.';
                    Editable = false;
                    trigger OnValidate()
                    begin
                        PeppolOauth.ValidateSecretValidTo(SecretValidTo);
                    end;
                }

            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(PromoteAuthorize; Authorize)
            {
            }
            actionref(PromotePublish; Publish)
            {
            }
        }
        area(Processing)
        {
            action(Authorize)
            {
                ApplicationArea = All;
                Enabled = not Rec.Authorized;
                Caption = 'Authorize';
                Image = ApprovalSetup;
                ToolTip = 'Authorize the company to use the ForNAV Peppol endpoints.';
                trigger OnAction()
                var
                    SMP: Codeunit "ForNAV Peppol SMP";
                begin
                    Page.RunModal(Page::"ForNAV Peppol Setup Wizard", Rec);
                    Rec.InitSetup();
                    if Rec.Authorized then begin
                        SMP.ParticipantExists(Rec);
                        ShowNotification();
                    end;

                    SetGlobals();
                    CurrPage.Update();
                end;
            }
            action(Publish)
            {
                ApplicationArea = All;
                Enabled = Rec.Authorized and (Rec.Status = Rec.Status::"Not published");
                Caption = 'Publish';
                Image = Approve;
                ToolTip = 'Publish the company to the ForNAV Peppol SMP.';
                trigger OnAction()
                var
                    SMP: Codeunit "ForNAV Peppol SMP";
                    PeppolJobQueue: Codeunit "ForNAV Peppol Job Queue";
                begin
                    if not Rec.TermsAccepted and Rec.PublishMsg.HasValue then
                        if not Confirm(Rec.GetPublishMsg(), true) then
                            exit;

                    Rec.TermsAccepted := true;
                    SMP.CreateParticipant(Rec);
                    PeppolJobQueue.SetupJobQueue();
                end;
            }
            action(CompanyInformationFld)
            {
                Enabled = Rec.Status <> Rec.Status::Published;
                ApplicationArea = All;
                Image = CompanyInformation;
                Caption = 'Edit Company Information';
                ToolTip = 'Edit company information';
                trigger OnAction()
                begin
                    if Page.RunModal(Page::"Company Information") = Action::LookupOK then begin
                        Rec.UpdateFromCompanyInformation();
                        Rec.Modify();
                        Update();
                    end;
                end;
            }
            action(TestConnection)
            {
                Caption = 'Test Connection';
                Visible = ShowConnectionSetup;
                ApplicationArea = All;
                Image = TestDatabase;
                ToolTip = 'Test the connection to the ForNAV Peppol endpoints.';
                trigger OnAction()
                var
                    ConnectionFailedErr: Label 'Connection failed';
                    ConnectionOkMsg: Label 'Connection succeeded';
                begin
                    if not PeppolOauth.TestOAuth() then
                        Error(ConnectionFailedErr);

                    Rec.Authorized := true;
                    Message(ConnectionOkMsg);
                end;
            }
            action(RotateSecret)
            {
                Caption = 'Rotate Client Secret';
                Visible = ShowConnectionSetup;
                ApplicationArea = All;
                Image = RedoFluent;
                ToolTip = 'Gets a new client secret and deletes the old one. May take a long time to run.';
                trigger OnAction()
                var
                    SureQst: Label 'Are you sure you want to rotate the client secret? This process may run a long time and will delete the old secret.';
                    CannotRotateErr: Label 'Cannot rotate secret if it is less than one week old.';
                begin
                    if PeppolOauth.GetSecretValidFrom() > CreateDateTime(CalcDate('<-1w>', Today), Time) then
                        Error(CannotRotateErr);

                    if not Confirm(SureQst) then
                        exit;
                    Rec.RotateClientSecret();
                    CurrPage.Update();
                end;
            }
            action(ServiceSetup)
            {
                ApplicationArea = All;
                Image = ServiceSetup;
                Caption = 'Service Setup';
                ToolTip = 'Setup the E-Document service for the company.';

                trigger OnAction()
                var
                    EDocumentService: Record "E-Document Service";
                    Setup: Record "ForNAV Peppol Setup";
                begin
                    if not Setup.GetEDocumentService(EDocumentService) then
                        exit;

                    EDocumentService.SetRecFilter();
                    Page.Run(Page::"E-Document Service", EDocumentService);
                end;
            }
            action(OrderLicense)
            {
                ApplicationArea = All;
                Visible = Rec.Status = Rec.Status::Unlicensed;
                Image = MakeOrder;
                Caption = 'Order License';
                ToolTip = 'Send mail to order a license from ForNAV';
                trigger OnAction()
                begin
                    SendEmail();
                end;
            }
            action(Roles)
            {
                ApplicationArea = All;
                Visible = false;
                Image = Permission;
                Caption = 'Roles';
                ToolTip = 'Setup the roles for the ForNAV Peppol setup.';
                RunObject = page "ForNAV Peppol Roles";
            }
            action(RecreateJobQueue)
            {
                ApplicationArea = All;
                Visible = Rec.Authorized;
                Image = Task;
                Caption = 'Recreate Job Queue';
                ToolTip = 'Recreate the job queue for the ForNAV Peppol setup.';
                trigger OnAction()
                var
                    PeppolJobQueue: Codeunit "ForNAV Peppol Job Queue";
                begin
                    PeppolJobQueue.SetupJobQueue();
                end;
            }
            action(Unpublish)
            {
                ApplicationArea = All;
                Enabled = (Rec.Status = Rec.Status::Published) or (Rec.Status = Rec.Status::"Published in another company or installation");
                Caption = 'Unpublish';
                Image = Undo;
                ToolTip = 'Unpublish the company from the ForNAV Peppol SMP.';
                trigger OnAction()
                var
                    SMP: Codeunit "ForNAV Peppol SMP";
                begin
                    SMP.DeleteParticipant(Rec);
                end;
            }
            action(Unauthorize)
            {
                Caption = 'Unauthorize';
                Visible = EnableUnauthorize;
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Unauthorize the company to use the ForNAV Peppol endpoints.';
                trigger OnAction()
                var
                    SureQst: Label 'Are you sure you want to reset the setup request? You will need to redo the authorization setup. Too many setup requests may result in blocked service.';
                begin
                    if not Confirm(SureQst) then
                        exit;

                    Rec.ResetForSetup();
                    SetGlobals();
                    CurrPage.Update();
                end;
            }
        }
    }
    var
        Setup: Codeunit "ForNAV Peppol Setup";
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
        ClientId: Text;
        PeppolEndpoint: Text;
        ForNAVTenantId: Text;
        [NonDebuggable]
        ClientSecret: Text;
        Scope: Text;
        SecretValidFrom: DateTime;
        SecretValidTo: DateTime;
        ShowConnectionSetup: Boolean;
        EnableUnauthorize: Boolean;
        AuthorizeLbl: Label 'Please Authorize';

    trigger OnInit()
    begin
        Setup.Init(Rec);
    end;

    trigger OnClosePage()
    begin
        Setup.Close();
    end;

    trigger OnOpenPage()
    var
    begin
        ShowNotification();
        SetGlobals();
    end;

    local procedure ShowNotification()
    var
        Notification: Notification;
        Info: ModuleInfo;
    begin
        if Rec.SetupNotification.HasValue and not NavApp.GetModuleInfo('9a217e38-6091-4d50-9169-672a2896b5d4', Info) then begin// Peppol app
            Notification.Message := Rec.GetSetupNotification();
            Notification.Scope := NotificationScope::LocalScope;
            Notification.AddAction('Link', Codeunit::"ForNAV Peppol Setup", 'NotificationLink');
            Notification.Send();
        end;
    end;

    procedure SendEmail()
    var
        TempEmailItem: Record "Email Item" temporary;
        CompanyInformation: Record "Company Information";
        Country: Record "Country/Region";
        TempBlob: Codeunit "Temp Blob";
        AzureADTenant: Codeunit "Azure AD Tenant";
        EnvironmentInformation: Codeunit "Environment Information";
        BodyText: TextBuilder;
        OutStr: OutStream;
        InStr: InStream;
        CRLF: Text;
        BodyTextLbl: Label 'Please order a license for %1 %2', Comment = '%1 = AadTenantId %2 = SerialNumber';
        AttachmentObject: JsonObject;
    begin
        CompanyInformation.Get();
        if not Country.Get(CompanyInformation.GetCompanyCountryRegionCode()) then
            Country.Name := CompanyInformation.GetCompanyCountryRegionCode();
        TempEmailItem."Send to" := '';
        TempEmailItem.Subject := 'ForNAV License for ' + CompanyName;
        TempEmailItem."Plaintext Formatted" := true;

        CRLF := '</br></br>';
        BodyText.AppendLine('Hi' + CRLF);

        if EnvironmentInformation.IsSaaSInfrastructure() then
            BodyText.AppendLine(StrSubstNo(BodyTextLbl, 'AadTenantId', AzureADTenant.GetAadTenantId()) + CRLF)
        else
            BodyText.AppendLine(StrSubstNo(BodyTextLbl, 'SerialNumber', Database.SerialNumber) + CRLF);

        BodyText.AppendLine('Participant ID ' + Rec.PeppolId() + CRLF);
        BodyText.AppendLine(CompanyInformation.Name + CRLF);
        BodyText.AppendLine(CompanyInformation.Address + CRLF);
        BodyText.AppendLine(CompanyInformation."Post Code" + ' ' + CompanyInformation.City + CRLF);
        BodyText.AppendLine(Country.Name + CRLF);
        BodyText.AppendLine(CompanyInformation.GetVATRegistrationNumber() + CRLF);

        TempEmailItem.SetBodyText(Format(BodyText));

        AttachmentObject.Add('BusinessEntity', Rec.CreateBusinessEntity());
        AttachmentObject.Add('License', Setup.GetJLicense());
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        AttachmentObject.WriteTo(OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        TempEmailItem.AddAttachment(InStr, 'license.json');

        TempEmailItem.Send(false, "Email Scenario"::Default);
    end;

    local procedure SetGlobals()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        ShowConnectionSetup := not EnvironmentInformation.IsSaaSInfrastructure();
        EnableUnauthorize := Rec.Authorized or (Rec."Oauth Setup Request Sent" <> 0D);
        ClientId := PeppolOauth.GetClientID();
        PeppolEndpoint := PeppolOauth.GetEndpoint();
        ForNAVTenantId := PeppolOauth.GetForNAVTenantID();
        ClientSecret := GetSecret();
        Scope := GetSecret();
        SecretValidFrom := PeppolOauth.GetSecretValidFrom();
        SecretValidTo := PeppolOauth.GetSecretValidTo();
    end;

    local procedure GetSecret(): Text
    begin
        if Rec.Authorized then
            exit('********');
    end;
}
