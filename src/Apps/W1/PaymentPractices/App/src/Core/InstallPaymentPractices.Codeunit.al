// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Foundation.Company;
using System.Environment;
using System.Privacy;

codeunit 687 "Install Payment Practices"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        if (AppInfo.DataVersion() <> Version.Create('0.0.0.0')) then
            exit;

        SetupPaymentPractices();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure CompanyInitialize()
    begin
        SetupPaymentPractices();
    end;

    local procedure SetupPaymentPractices()
    var
        PaymentPeriod: Record "Payment Period";
    begin
        ApplyEvaluationClassificationsForPrivacy();
        CreateDefaultPaymentPeriodTemplate();
#pragma warning disable AL0432
        PaymentPeriod.SetupDefaults();
#pragma warning restore AL0432
    end;

    local procedure CreateDefaultPaymentPeriodTemplate()
    var
        PaymentPeriodHeader: Record "Payment Period Header";
        PaymentPeriodMgt: Codeunit "Payment Period Mgt.";
    begin
        if not PaymentPeriodHeader.IsEmpty() then
            exit;

        PaymentPeriodMgt.InsertDefaultTemplate();
    end;

    local procedure ApplyEvaluationClassificationsForPrivacy()
    var
        Company: Record Company;
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        Company.Get(CompanyName());
        if not Company."Evaluation Company" then
            exit;

        DataClassificationMgt.SetTableFieldsToNormal(Database::"Payment Period");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Payment Practice Data");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Payment Practice Header");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Payment Practice Line");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Payment Period Header");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Payment Period Line");
    end;
}
