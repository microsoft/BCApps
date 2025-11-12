// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using System.Environment;
using System.Threading;
using System.Upgrade;
using System.Telemetry;

report 357 "Copy Company"
{
    Caption = 'Copy Company';
    Permissions = tabledata "Feature Data Update Status" = ri;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Company; Company)
        {
            DataItemTableView = sorting(Name);
            dataitem("Experience Tier Setup"; "Experience Tier Setup")
            {
                DataItemLink = "Company Name" = field(Name);
                DataItemTableView = sorting("Company Name");

                trigger OnAfterGetRecord()
                var
                    ExperienceTierSetup: Record "Experience Tier Setup";
                    ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
                begin
                    ExperienceTierSetup := "Experience Tier Setup";
                    ExperienceTierSetup."Company Name" := NewCompanyName;
                    if ExperienceTierSetup.Insert() then;
                    ApplicationAreaMgmt.SetExperienceTierOtherCompany(ExperienceTierSetup, NewCompanyName);
                end;
            }
            dataitem("Report Layout Selection"; "Report Layout Selection")
            {
                DataItemLink = "Company Name" = field(Name);
                DataItemTableView = sorting("Report ID", "Company Name");

                trigger OnAfterGetRecord()
                var
                    ReportLayoutSelection: Record "Report Layout Selection";
                begin
                    ReportLayoutSelection := "Report Layout Selection";
                    ReportLayoutSelection."Report ID" := "Report ID";
                    ReportLayoutSelection."Company Name" := NewCompanyName;
                    if ReportLayoutSelection.Insert() then;
                end;
            }
            dataitem("Custom Report Layout"; "Custom Report Layout")
            {
                DataItemLink = "Company Name" = field(Name);
                DataItemTableView = sorting("Report ID", "Company Name", Type);

                trigger OnAfterGetRecord()
                var
                    CustomReportLayout: Record "Custom Report Layout";
                begin
                    CustomReportLayout := "Custom Report Layout";
                    CustomReportLayout.Code := '';
                    CustomReportLayout."Company Name" := NewCompanyName;
                    if CustomReportLayout.Insert(true) then;
                end;
            }
            dataitem("Feature Data Update Status"; "Feature Data Update Status")
            {
                DataItemLink = "Company Name" = field(Name);
                DataItemTableView = sorting("Feature Key", "Company Name");

                trigger OnAfterGetRecord()
                var
                    FeatureDataUpdateStatus: Record "Feature Data Update Status";
                begin
                    FeatureDataUpdateStatus := "Feature Data Update Status";
                    FeatureDataUpdateStatus."Company Name" := NewCompanyName;
                    if FeatureDataUpdateStatus.Insert() then;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ProgressWindow.Open(StrSubstNo(ProgressMsg, NewCompanyName));

                if BreakReport then
                    CurrReport.Break();
                CopyCompany(Name, NewCompanyName);
                BreakReport := true;
            end;

            trigger OnPostDataItem()
            var
                AuditLog: Codeunit "Audit Log";
                JobQueueManagement: Codeunit "Job Queue Management";
                CopiedCompanyLbl: Label 'Copied company with the new name %1 by UserSecurityId %2.', Locked = true;
            begin
                ProgressWindow.Close();
                SetNewNameToNewCompanyInfo();
                JobQueueManagement.SetRecurringJobsOnHold(NewCompanyName);
                OnAfterCreatedNewCompanyByCopyCompany(NewCompanyName, Company);
                RegisterUpgradeTags(NewCompanyName);
                Message(CopySuccessMsg, Name);
                AuditLog.LogAuditMessage(StrSubstNo(CopiedCompanyLbl, NewCompanyName, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
            end;
        }
    }

    requestpage
    {
        ShowFilter = false;

        layout
        {
            area(content)
            {
                group(Control2)
                {
                    ShowCaption = false;
                    field("New Company Name"; NewCompanyName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Company Name';
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the new company. The name can have a maximum of 30 characters. If the database collation is case-sensitive, you can have one company called COMPANY and another called Company. However, if the database is case-insensitive, you cannot create companies with names that differ only by case.';

                        trigger OnValidate()
                        begin
                            NewCompanyName := DelChr(NewCompanyName, '<>');
                            OnValidateNewCompanyName(NewCompanyName);
                        end;
                    }

                    label(CopyInformation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'The new company will include all data, including transactions, from the selected company.';
                    }

                    group(CopyWarning)
                    {
                        Caption = 'IMPORTANT';
                        label(CopyWarningDescription)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Copying a company can take time, and people working in the company will not be able to use Business Central during the process. We recommend that you perform this action at a time of day that will have the least impact, for example, outside of business hours.';
                        }

                        field("Confirm Copy Warning"; ConfirmCopyWarning)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'I understand';
                            ShowCaption = true;
                            ToolTip = 'Indicates that you understand that copying a company will impact performance. Before you can copy a company you must turn on the I understand toggle.';
                        }
                    }

                    label(BackupTip)
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = IsSaaS;
                        Caption = 'Tip: If you just want to work with the data, there are other ways to do that. For example, you can create a sandbox environment based on production data, or do a data backup.';
                    }

                    field(ReadMoreSandboxLbl; ReadMoreSandboxLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Editable = false;
                        Visible = IsSaaS;
                        Style = StandardAccent;

                        trigger OnDrillDown()
                        begin
                            Hyperlink('https://go.microsoft.com/fwlink/?linkid=2111002');
                        end;
                    }

                    field(ReadMoreDataBackupLbl; ReadMoreDataBackupLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        ShowCaption = false;
                        Editable = false;
                        Visible = IsSaaS;
                        Style = StandardAccent;

                        trigger OnDrillDown()
                        begin
                            Hyperlink('https://go.microsoft.com/fwlink/?linkid=2111001');
                        end;
                    }
                }
            }
        }

        trigger OnInit()
        var
            EnvironmentInformation: Codeunit "Environment Information";
        begin
            IsSaaS := EnvironmentInformation.IsSaaS();
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        begin
            if (CloseAction = Action::OK) and (not ConfirmCopyWarning) then begin
                Message(ConfirmCopyWarningMsg);
                exit(false);
            end;

            exit(true);
        end;
    }

    labels
    {
    }

    var
        IsSaaS: Boolean;
        ProgressWindow: Dialog;
        BreakReport: Boolean;
        NewCompanyName: Text[30];
#pragma warning disable AA0470
        ProgressMsg: Label 'Creating new company %1.', Comment = 'Creating new company Contoso Corporation.';
        CopySuccessMsg: Label 'Company %1 has been copied successfully.', Comment = 'Company CRONUS International Ltd. has been copied successfully.';
#pragma warning restore AA0470
        ReadMoreSandboxLbl: Label 'Read more about sandboxes';
        ReadMoreDataBackupLbl: Label 'Read more about data backup';
        ConfirmCopyWarning: Boolean;
        ConfirmCopyWarningMsg: Label 'Before you can continue, you must acknowledge that you understand that copying a company will impact performance. Additional setup for integration features will be required in the new company.';

    procedure GetCompanyName(): Text[30]
    begin
        exit(NewCompanyName);
    end;

    local procedure RegisterUpgradeTags(NewCompanyName: Code[30])
    var
        UpgradeTag: codeunit "Upgrade Tag";
    begin
        UpgradeTag.CopyUpgradeTags(CopyStr(CompanyName(), 1, MaxStrLen(NewCompanyName)), NewCompanyName);
    end;

    local procedure SetNewNameToNewCompanyInfo()
    var
        CompanyInformation: Record "Company Information";
        Company: Record Company;
    begin
        if Company.Get(NewCompanyName) then;
        Company."Display Name" := NewCompanyName;
        Company.Modify();

        if CompanyInformation.ChangeCompany(NewCompanyName) then
            if CompanyInformation.Get() then begin
                CompanyInformation.Name := NewCompanyName;
                CompanyInformation.Modify(true);
            end;

        OnAfterSetNewNameToNewCompanyInfo(NewCompanyName);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNewNameToNewCompanyInfo(NewCompanyName: Text[30])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatedNewCompanyByCopyCompany(NewCompanyName: Text[30]; Company: Record Company)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateNewCompanyName(var NewCompanyName: Text[30])
    begin
    end;
}
