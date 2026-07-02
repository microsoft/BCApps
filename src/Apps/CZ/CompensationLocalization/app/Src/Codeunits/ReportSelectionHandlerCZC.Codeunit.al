// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Compensations;

using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;
using System.EMail;

codeunit 11765 "Report Selection Handler CZC"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Page, Page::"Customer Report Selections", 'OnAfterOnMapTableUsageValueToPageValue', '', false, false)]
    local procedure AddCompensationReportsOnAfterOnMapTableUsageValueToPageValue(var Usage2: Enum "Custom Report Selection Sales"; CustomReportSelection: Record "Custom Report Selection")
    begin
        case CustomReportSelection.Usage of
            "Report Selection Usage"::"Compensation CZC":
                Usage2 := Usage2::"Compensation CZC";
            "Report Selection Usage"::"Posted Compensation CZC":
                Usage2 := Usage2::"Posted Compensation CZC";
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Customer Report Selections", 'OnValidateUsage2OnCaseElse', '', false, false)]
    local procedure AddCompensationReportsOnValidateUsage2OnCaseElse(var CustomReportSelection: Record "Custom Report Selection"; ReportUsage: Option)
    begin
        case ReportUsage of
            "Custom Report Selection Sales"::"Compensation CZC".AsInteger():
                CustomReportSelection.Usage := "Report Selection Usage"::"Compensation CZC";
            "Custom Report Selection Sales"::"Posted Compensation CZC".AsInteger():
                CustomReportSelection.Usage := "Report Selection Usage"::"Posted Compensation CZC";
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Customer Report Selections", 'OnAfterFilterCustomerUsageReportSelections', '', false, false)]
    local procedure AddCompensationReportsOnAfterFilterCustomerUsageReportSelections(var ReportSelections: Record "Report Selections")
    begin
        ReportSelections.SetFilter(Usage, GetUsageFilter(ReportSelections));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Vendor Report Selections", 'OnMapTableUsageValueToPageValueOnCaseElse', '', false, false)]
    local procedure AddCompensationReportsOnMapTableUsageValueToPageValueOnCaseElse(var ReportUsage: Enum "Report Selection Usage Vendor"; Rec: Record "Custom Report Selection")
    begin
        case Rec.Usage of
            "Report Selection Usage"::"Compensation CZC":
                ReportUsage := ReportUsage::"Compensation CZC";
            "Report Selection Usage"::"Posted Compensation CZC":
                ReportUsage := ReportUsage::"Posted Compensation CZC";
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Vendor Report Selections", 'OnValidateUsage2OnCaseElse', '', false, false)]
    local procedure AddCompensationReportsForVendorOnValidateUsage2OnCaseElse(var CustomReportSelection: Record "Custom Report Selection"; ReportUsage: Enum "Report Selection Usage Vendor")
    begin
        case ReportUsage of
            ReportUsage::"Compensation CZC":
                CustomReportSelection.Usage := "Report Selection Usage"::"Compensation CZC";
            ReportUsage::"Posted Compensation CZC":
                CustomReportSelection.Usage := "Report Selection Usage"::"Posted Compensation CZC";
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Vendor Report Selections", 'OnAfterFilterVendorUsageReportSelections', '', false, false)]
    local procedure AddCompensationReportsOnAfterFilterVendorUsageReportSelections(var ReportSelections: Record "Report Selections")
    begin
        ReportSelections.SetFilter(Usage, GetUsageFilter(ReportSelections));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnGetFullDocumentTypeTextElseCase', '', false, false)]
    local procedure AddCompensationReportsOnGetFullDocumentTypeTextElseCase(DocumentRecordRef: RecordRef; var DocumentTypeText: Text[50])
    var
        CompensationTxt: Label 'Compensation';
    begin
        case DocumentRecordRef.Number of
            Database::"Compensation Header CZC",
            Database::"Posted Compensation Header CZC":
                DocumentTypeText := CompensationTxt;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnGetDocumentLanguageCodeCaseElse', '', false, false)]
    local procedure GetLanguageCodeFromCompensationOnGetDocumentLanguageCodeCaseElse(DocumentRecordRef: RecordRef; var LanguageCode: Code[10])
    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
        PostedCompensationHeaderCZC: Record "Posted Compensation Header CZC";
    begin
        case DocumentRecordRef.Number of
            Database::"Compensation Header CZC":
                begin
                    DocumentRecordRef.SetTable(CompensationHeaderCZC);
                    LanguageCode := CompensationHeaderCZC."Language Code";
                end;
            Database::"Posted Compensation Header CZC":
                begin
                    DocumentRecordRef.SetTable(PostedCompensationHeaderCZC);
                    LanguageCode := PostedCompensationHeaderCZC."Language Code";
                end;
        end;
    end;

    local procedure GetUsageFilter(var ReportSelections: Record "Report Selections") UsageFilter: Text
    begin
        UsageFilter := StrSubstNo('%1|%2', "Report Selection Usage"::"Compensation CZC", "Report Selection Usage"::"Posted Compensation CZC");
        if ReportSelections.GetFilter(Usage) <> '' then
            UsageFilter := StrSubstNo('%1|%2', ReportSelections.GetFilter(Usage), UsageFilter);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Email Scenario Mapping", 'OnAfterFromReportSelectionUsage', '', false, false)]
    local procedure AddCompensationReportsOnAfterFromReportSelectionUsage(ReportSelectionUsage: Enum "Report Selection Usage"; var EmailScenario: Enum "Email Scenario")
    begin
        case ReportSelectionUsage of
            ReportSelectionUsage::"Compensation CZC":
                EmailScenario := EmailScenario::"Compensation CZC";
            ReportSelectionUsage::"Posted Compensation CZC":
                EmailScenario := EmailScenario::"Posted Compensation CZC";
        end;
    end;
}
