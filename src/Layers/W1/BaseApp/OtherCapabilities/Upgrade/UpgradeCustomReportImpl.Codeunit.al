// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.Foundation.Reporting;
using System.Environment.Configuration;
using System.Reflection;
using System.Upgrade;

codeunit 104057 "Upgrade Custom Report Impl."
{

    // to allow test or manual upgrade
    trigger OnRun()
    begin
        UpgradeCompany();
    end;

    local procedure UpgradeCompany()
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayout: Record "Report Layout";
        ReportLayoutList: Record "Report Layout List";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinations: Codeunit "Upgrade Tag Definitions";
        CustomReportLayoutName: Text[250];
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinations.GetCustomReportLayoutUpgradeTag()) then begin
            CustomReportLayout.SetRange("Built-In", true);
            if CustomReportLayout.FindSet(true) then
                repeat
                    if not ReportLayout.Get(CustomReportLayout.Code) then begin
                        CustomReportLayoutName := GetCustomLayoutToName(CustomReportLayout.Code);
                        if CustomReportLayoutName = '' then begin
                            ReportLayoutList.SetRange("Report ID", CustomReportLayout."Report ID");
                            if ReportLayoutList.FindFirst() then
                                CustomReportLayoutName := ReportLayoutList.Name;
                        end;
                        UpdateReportSelections(CustomReportLayout.Code, CustomReportLayoutName);
                        UpdateReportLayoutSelection(CustomReportLayout.Code, CustomReportLayoutName);
                        UpdateCustomReportSelection(CustomReportLayout.Code, CustomReportLayoutName);
                    end;
                until CustomReportLayout.Next() = 0;
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinations.GetCustomReportLayoutUpgradeTag());
        end;
    end;

    local procedure UpdateReportSelections(CustomReportLayoutCode: Code[20]; CustomReportLayoutName: Text[250])
    var
        ReportSelections: Record "Report Selections";
    begin
        if CustomReportLayoutName = '' then
            exit;

        ReportSelections.SetRange("Custom Report Layout Code", CustomReportLayoutCode);
        ReportSelections.ModifyAll("Custom Report Layout Code", '');
        ReportSelections.SetRange("Custom Report Layout Code");

        ReportSelections.SetRange("Email Body Layout Code", CustomReportLayoutCode);
        ReportSelections.ModifyAll("Email Body Layout Name", CustomReportLayoutName);
        ReportSelections.ModifyAll("Email Body Layout Code", '');
    end;

    local procedure UpdateReportLayoutSelection(CustomReportLayoutCode: Code[20]; CustomReportLayoutName: Text[250])
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        ReportLayoutList: Record "Report Layout List";
        EmptyGuid: Guid;
    begin
        if CustomReportLayoutName = '' then
            exit;
        ReportLayoutList.SetRange(Name, CustomReportLayoutName);
        if not ReportLayoutList.FindFirst() then
            exit;

        ReportLayoutSelection.SetRange("Custom Report Layout Code", CustomReportLayoutCode);
        if ReportLayoutSelection.FindSet(true) then
            repeat
                TenantReportLayoutSelection."App ID" := ReportLayoutList."Application ID";
                TenantReportLayoutSelection."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutSelection."Company Name"));
                TenantReportLayoutSelection."Layout Name" := ReportLayoutList.Name;
                TenantReportLayoutSelection."Report ID" := ReportLayoutSelection."Report ID";
                TenantReportLayoutSelection."User ID" := EmptyGuid;
                if not TenantReportLayoutSelection.Insert(true) then;
            until ReportLayoutSelection.Next() = 0;
        ReportLayoutSelection.ModifyAll("Custom Report Layout Code", '');
    end;

    local procedure UpdateCustomReportSelection(CustomReportLayoutCode: Code[20]; CustomReportLayoutName: Text[250])
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        if CustomReportLayoutName = '' then
            exit;

        CustomReportSelection.SetRange("Custom Report Layout Code", CustomReportLayoutCode);
        CustomReportSelection.ModifyAll("Email Attachment Layout Name", CustomReportLayoutName);
        CustomReportSelection.ModifyAll("Custom Report Layout Code", '');
        CustomReportSelection.SetRange("Custom Report Layout Code");

        CustomReportSelection.SetRange("Email Body Layout Code", CustomReportLayoutCode);
        CustomReportSelection.ModifyAll("Email Body Layout Name", CustomReportLayoutName);
        CustomReportSelection.ModifyAll("Email Body Layout Code", '');
    end;

    local procedure GetCustomLayoutToName(CustomReportLayoutCode: Code[20]): Text[250]
    begin
        case CustomReportLayoutCode of
            Uppercase('MS-1016-DEFAULT'):
                exit('JobQuote.docx');
            Uppercase('MS-117-EMAIL_DEF'):
                exit('DefaultReminderEmail.docx');
            Uppercase('MS-1302-DEFAULT'):
                exit('StandardSalesProFormaInv.docx');
            Uppercase('MS-1303-BLUESIMPLE'):
                exit('StandardDraftSalesInvoiceBlue.docx');
            Uppercase('MS-1303-S_EMAIL_DEF'), Uppercase('MS-1303-EMAIL_INV'), Uppercase('MS-1303-S_EMAIL_SMPL'):
                exit('StandardDraftSalesInvoiceEmail.docx');
            Uppercase('MS-1303-INVOICING'):
                exit('StandardDraftSalesInvoiceBlue.docx');
            Uppercase('MS-1304-EMAIL_BLUE'):
                exit('StandardSalesEstimateBlueEmail.docx');
            Uppercase('MS-1304-BLUEESTIMATE'), Uppercase('MS-1304-BLUESIMPLE'):
                exit('StandardSalesQuoteBlue.docx');
            Uppercase('MS-1304-EMAIL_DEF'), Uppercase('MS-1304-EMAIL_INV'):
                exit('StandardSalesQuoteEmail.docx');
            Uppercase('MS-1304-INVOICING'):
                exit('StandardSalesQuote.docx');
            Uppercase('MS-1305-EMAIL_DEF'):
                exit('StandardOrderConfirmationEmail.docx');
            Uppercase('MS-1306-BLUESIMPLE'), Uppercase('MS-1306-INVOICING'),
            Uppercase('MS-1306-MODERN'), Uppercase('MS-1306-RED'),
            Uppercase('MS-1306-TIMELESS'):
                exit('StandardSalesInvoiceBlueSimple.docx');
            Uppercase('MS-1306-BLUE-VATSPEC'):
                exit('StandardSalesInvoiceVatSpec.docx');
            Uppercase('MS-1306-EMAIL_DEF'), Uppercase('MS-1306-S_EMAIL_SMPL'),
            Uppercase('MS-1306-EMAIL_INV'), Uppercase('MS-1306-EMAIL_MODERN'),
            Uppercase('MS-1306-EMAIL_RED'), Uppercase('MS-1306-EMAIL_TIM'):
                exit('StandardSalesInvoiceDefEmail.docx');
            Uppercase('MS-1307-EMAIL_DEF'):
                exit('StandardSalesCreditMemoEmail.docx');
            Uppercase('MS-1308-BLUESIMPLE'):
                exit('StandardSalesShipmentBlue.docx');
            Uppercase('MS-1309-BLUESIMPLE'):
                exit('StandardSalesReturnRcptBlue.docx');
            Uppercase('MS-1316-EMAIL_DEF'):
                exit('StandardCustomerStatementEmail.docx');
            Uppercase('MS-1322-EMAIL_DEF'):
                exit('StandardPurchaseOrderEmail.docx');
            Uppercase('MS-5084-EMAIL_DEFMRG'):
                exit('DefaultEmailMergeDoc.docx');
            else
                exit('');
        end;
    end;
}