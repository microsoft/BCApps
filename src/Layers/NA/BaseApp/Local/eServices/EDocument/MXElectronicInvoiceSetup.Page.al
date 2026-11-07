// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using System.Email;
using System.Environment;

page 10457 "MX Electronic Invoice Setup"
{
    ApplicationArea = BasicMX;
    Caption = 'Electronic Invoicing Setup for Mexico';
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTable = "MX Electronic Invoicing Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            part(Control1310001; "MX Electroninc - CompanyInfo")
            {
                ApplicationArea = Basic, Suite;
            }
            part(Control1310002; "MX Electroninc - GLSetup")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Download XML with Requests"; Rec."Download XML with Requests")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Download the XML document when sending a request to an electronic invoicing authority.';
            }
            field("Download SaaS Request"; Rec."Download SaaS Request")
            {
                Visible = IsSaaS;
                ApplicationArea = Basic, Suite;
                ToolTip = 'Download the txt request.';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        MailManagement: Codeunit "Mail Management";
        Notify: Notification;
        IsEmailEnabled: Boolean;
    begin
        IsEmailEnabled := MailManagement.IsEnabled();
        IsSaaS := EnvironmentInfo.IsSaaS();

        if not IsEmailEnabled then begin
            Notify.Message(EmailSetupMissingMsg);
            Notify.AddAction(SetupEmailMsg, CODEUNIT::"E-Invoice Mgt.", 'OpenAssistedSetup');
            Notify.Send();
        end;
        EInvoiceMgt.SetupService();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        CompanyInformation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PACWebService: Record "PAC Web Service";
    begin
        if CompanyInformation.CheckIfMissingMXEInvRequiredFields() and
           PACWebService.CheckIfMissingMXEInvRequiredFields() and
           GeneralLedgerSetup.CheckIfMissingMXEInvRequiredFields()
        then
            Rec.Enabled := false
        else
            Rec.Enabled := true;

        Rec.Modify();
    end;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        IsSaaS: Boolean;
        EmailSetupMissingMsg: Label 'You must set up email in Business Central before you can send electronic invoices.';
        SetupEmailMsg: Label 'Go to Set Up Email.';
}

