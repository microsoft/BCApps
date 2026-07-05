// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Setup;
using System.EMail;

codeunit 11770 "Report Selection Handler CZP"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Page, Page::"Customer Report Selections", OnAfterOnMapTableUsageValueToPageValue, '', false, false)]
    local procedure AddCashDeskReportsOnAfterOnMapTableUsageValueToPageValue(var Usage2: Enum "Custom Report Selection Sales"; CustomReportSelection: Record "Custom Report Selection")
    begin
        case CustomReportSelection.Usage of
            "Report Selection Usage"::"Cash Receipt CZP":
                Usage2 := Usage2::"Cash Receipt CZP";
            "Report Selection Usage"::"Posted Cash Receipt CZP":
                Usage2 := Usage2::"Posted Cash Receipt CZP";
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Customer Report Selections", OnValidateUsage2OnCaseElse, '', false, false)]
    local procedure AddCashDeskReportsOnValidateUsage2OnCaseElse(var CustomReportSelection: Record "Custom Report Selection"; ReportUsage: Option)
    begin
        case ReportUsage of
            "Custom Report Selection Sales"::"Cash Receipt CZP".AsInteger():
                CustomReportSelection.Usage := "Report Selection Usage"::"Cash Receipt CZP";
            "Custom Report Selection Sales"::"Posted Cash Receipt CZP".AsInteger():
                CustomReportSelection.Usage := "Report Selection Usage"::"Posted Cash Receipt CZP";
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Customer Report Selections", OnAfterFilterCustomerUsageReportSelections, '', false, false)]
    local procedure AddCashDeskReportsOnAfterFilterCustomerUsageReportSelections(var ReportSelections: Record "Report Selections")
    begin
        ReportSelections.SetFilter(Usage, GetUsageFilter(ReportSelections));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", OnGetFullDocumentTypeTextElseCase, '', false, false)]
    local procedure AddCashDeskReportsOnGetFullDocumentTypeTextElseCase(DocumentRecordRef: RecordRef; var DocumentTypeText: Text[50])
    var
        CashDocumentHeaderCZP: Record "Cash Document Header CZP";
        PostedCashDocumentHdrCZP: Record "Posted Cash Document Hdr. CZP";
        ReceiptCashDocumentTxt: Label 'Receipt Cash Document';
        WithdrawalCashDocumentTxt: Label 'Withdrawal Cash Document';
    begin
        case DocumentRecordRef.Number of
            Database::"Cash Document Header CZP":
                begin
                    DocumentRecordRef.SetTable(CashDocumentHeaderCZP);
                    case CashDocumentHeaderCZP."Document Type" of
                        CashDocumentHeaderCZP."Document Type"::Receipt:
                            DocumentTypeText := ReceiptCashDocumentTxt;
                        CashDocumentHeaderCZP."Document Type"::Withdrawal:
                            DocumentTypeText := WithdrawalCashDocumentTxt;
                    end;
                end;
            Database::"Posted Cash Document Hdr. CZP":
                begin
                    DocumentRecordRef.SetTable(PostedCashDocumentHdrCZP);
                    case PostedCashDocumentHdrCZP."Document Type" of
                        PostedCashDocumentHdrCZP."Document Type"::Receipt:
                            DocumentTypeText := ReceiptCashDocumentTxt;
                        PostedCashDocumentHdrCZP."Document Type"::Withdrawal:
                            DocumentTypeText := WithdrawalCashDocumentTxt;
                    end;
                end;
        end;
    end;

    local procedure GetUsageFilter(var ReportSelections: Record "Report Selections") UsageFilter: Text
    begin
        UsageFilter := StrSubstNo('%1|%2', "Report Selection Usage"::"Cash Receipt CZP", "Report Selection Usage"::"Posted Cash Receipt CZP");
        if ReportSelections.GetFilter(Usage) <> '' then
            UsageFilter := StrSubstNo('%1|%2', ReportSelections.GetFilter(Usage), UsageFilter);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email Scenario Mapping", OnAfterFromReportSelectionUsage, '', false, false)]
    local procedure AddCashDeskReportsOnAfterFromReportSelectionUsage(ReportSelectionUsage: Enum "Report Selection Usage"; var EmailScenario: Enum "Email Scenario")
    begin
        case ReportSelectionUsage of
            ReportSelectionUsage::"Cash Receipt CZP":
                EmailScenario := EmailScenario::"Cash Receipt CZP";
            ReportSelectionUsage::"Posted Cash Receipt CZP":
                EmailScenario := EmailScenario::"Posted Cash Receipt CZP";
        end;
    end;
}
