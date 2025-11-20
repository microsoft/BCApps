// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Sales.Setup;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Reports;

codeunit 6461 "Serv. Document Print"
{
    var
#if not CLEAN25
        DocumentPrint: Codeunit "Document-Print";
#endif

        MissingReportSelectionErr: Label 'Report Selections is missing for %1 %2.', Comment = '%1 - Contract Type, %2 - Contract No.';
        MissingReportSelection2Err: Label '%1 for %2 is missing in Report Selections.', Comment = '%1 - Document Type, %2 - Service Header';

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnAfterIsCustomerAccount', '', false, false)]
    local procedure OnAfterIsCustomerAccount(DocumentTableId: Integer; var IsCustomer: Boolean);
    begin
        if DocumentTableId = Database::"Service Invoice Header" then
            IsCustomer := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendEmailDirectlyOnAfterSetFieldName', '', false, false)]
    local procedure OnSendEmailDirectlyOnAfterSetFieldName(DocumentTableId: Integer; var FieldName: Text);
    begin
        if DocumentTableId = Database::"Service Invoice Header" then
            FieldName := 'Customer No.';
    end;

    procedure PrintServiceHeader(ServiceHeader: Record "Service Header")
    var
        ReportSelection: Record "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
        IsPrinted: Boolean;
    begin
        ReportUsage := GetServHeaderDocTypeUsage(ServiceHeader);
        ServiceHeader.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceHeader.SetRange("No.", ServiceHeader."No.");
        CalcServDisc(ServiceHeader);
        OnBeforePrintServiceHeader(ServiceHeader, ReportUsage.AsInteger(), IsPrinted);
#if not CLEAN25
        DocumentPrint.RunOnBeforePrintServiceHeader(ServiceHeader, ReportUsage.AsInteger(), IsPrinted);
#endif
        if IsPrinted then
            exit;

        ReportSelection.Reset();
        ReportSelection.SetRange(Usage, ReportUsage);
        if ReportSelection.IsEmpty() then
            Error(MissingReportSelection2Err, ReportSelection.FieldCaption("Report ID"), ServiceHeader.TableCaption());

        ReportSelection.PrintForCust(ReportUsage, ServiceHeader, ServiceHeader.FieldNo("Customer No."));
    end;

    procedure PrintServiceItemWorksheet(ServiceItemLine: Record "Service Item Line")
    var
        ReportSelection: Record "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
        IsPrinted: Boolean;
    begin
        ReportUsage := ReportSelection.Usage::"SM.Item Worksheet";
        ServiceItemLine.SetRecFilter();
        OnBeforePrintServiceItemWorksheet(ServiceItemLine, ReportUsage, IsPrinted);
        if IsPrinted then
            exit;

        ReportSelection.Reset();
        ReportSelection.SetRange(Usage, ReportUsage);
        if ReportSelection.IsEmpty() then
            Error(MissingReportSelection2Err, ReportSelection.FieldCaption("Report ID"), ServiceItemLine.TableCaption());

        ReportSelection.PrintForCust(ReportUsage, ServiceItemLine, ServiceItemLine.FieldNo("Customer No."));
    end;

    procedure PrintServiceContract(ServiceContractHeader: Record "Service Contract Header")
    var
        ReportSelections: Record "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
        IsPrinted: Boolean;
    begin
        ReportUsage := GetServContractTypeUsage(ServiceContractHeader);

        ServiceContractHeader.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        OnBeforePrintServiceContract(ServiceContractHeader, ReportUsage.AsInteger(), IsPrinted);
#if not CLEAN25
        DocumentPrint.RunOnBeforePrintServiceContract(ServiceContractHeader, ReportUsage.AsInteger(), IsPrinted);
#endif
        if IsPrinted then
            exit;

        ReportSelections.Reset();
        ReportSelections.SetRange(Usage, ReportUsage);
        if ReportSelections.IsEmpty() then
            Error(MissingReportSelectionErr, Format(ServiceContractHeader."Contract Type"), ServiceContractHeader."Contract No.");

        ReportSelections.PrintForCust(ReportUsage, ServiceContractHeader, ServiceContractHeader.FieldNo("Bill-to Customer No."));
    end;

    procedure CalcServDisc(var ServHeader: Record "Service Header")
    var
        SalesSetup: Record "Sales & Receivables Setup";
        ServLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcServDisc(ServHeader, IsHandled);
#if not CLEAN25
        DocumentPrint.RunOnBeforeCalcServDisc(ServHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        SalesSetup.Get();
        if SalesSetup."Calc. Inv. Discount" then begin
            ServLine.Reset();
            ServLine.SetRange("Document Type", ServHeader."Document Type");
            ServLine.SetRange("Document No.", ServHeader."No.");
            ServLine.FindFirst();
            CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServLine);
            ServHeader.Get(ServHeader."Document Type", ServHeader."No.");
            Commit();
        end;
    end;

    procedure GetServContractTypeUsage(ServiceContractHeader: Record "Service Contract Header"): Enum "Report Selection Usage"
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case ServiceContractHeader."Contract Type" of
            ServiceContractHeader."Contract Type"::Quote:
                exit(ReportSelections.Usage::"SM.Contract Quote");
            ServiceContractHeader."Contract Type"::Contract:
                exit(ReportSelections.Usage::"SM.Contract");
            else begin
                IsHandled := false;
                OnGetServContractTypeUsageElseCase(ServiceContractHeader, TypeUsage, IsHandled);
#if not CLEAN25
                DocumentPrint.RunOnGetServContractTypeUsageElseCase(ServiceContractHeader, TypeUsage, IsHandled);
#endif
                if IsHandled then
                    exit("Report Selection Usage".FromInteger(TypeUsage));
                Error('');
            end;
        end;
    end;

    procedure GetServHeaderDocTypeUsage(ServiceHeader: Record "Service Header"): Enum "Report Selection Usage"
    var
        ReportSelections: Record "Report Selections";
        TypeUsage: Integer;
        IsHandled: Boolean;
    begin
        case ServiceHeader."Document Type" of
            ServiceHeader."Document Type"::Quote:
                exit(ReportSelections.Usage::"SM.Quote");
            ServiceHeader."Document Type"::Order:
                exit(ReportSelections.Usage::"SM.Order");
            ServiceHeader."Document Type"::Invoice:
                exit(ReportSelections.Usage::"SM.Invoice");
            ServiceHeader."Document Type"::"Credit Memo":
                exit(ReportSelections.Usage::"SM.Credit Memo");
            else begin
                IsHandled := false;
                OnGetServHeaderDocTypeUsageElseCase(ServiceHeader, TypeUsage, IsHandled);
#if not CLEAN25
                DocumentPrint.RunOnGetServHeaderDocTypeUsageElseCase(ServiceHeader, TypeUsage, IsHandled);
#endif
                if IsHandled then
                    exit("Report Selection Usage".FromInteger(TypeUsage));
                Error('');
            end;
        end;
    end;

    procedure PrintServiceHeaderToDocumentAttachment(var ServiceHeader: Record "Service Header");
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := ServiceHeader.Count() = 1;
        if ServiceHeader.FindSet() then
            repeat
                DoPrintServiceHeaderToDocumentAttachment(ServiceHeader, ShowNotificationAction);
            until ServiceHeader.Next() = 0;
    end;

    local procedure DoPrintServiceHeaderToDocumentAttachment(ServiceHeader: Record "Service Header"; ShowNotificationAction: Boolean);
    var
        ReportSelections: REcord "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
    begin
        ReportUsage := GetServHeaderDocTypeUsage(ServiceHeader);

        ServiceHeader.SetRecFilter();
        CalcServDisc(ServiceHeader);

        ReportSelections.SaveAsDocumentAttachment(ReportUsage.AsInteger(), ServiceHeader, ServiceHeader."No.", ServiceHeader."Customer No.", ShowNotificationAction);
    end;

    procedure PrintServiceContractToDocumentAttachment(var ServiceContractHeader: Record "Service Contract Header");
    var
        ShowNotificationAction: Boolean;
    begin
        ShowNotificationAction := ServiceContractHeader.Count() = 1;
        if ServiceContractHeader.FindSet() then
            repeat
                DoPrintServiceContractToDocumentAttachment(ServiceContractHeader, ShowNotificationAction);
            until ServiceContractHeader.Next() = 0;
    end;

    local procedure DoPrintServiceContractToDocumentAttachment(ServiceContractHeader: Record "Service Contract Header"; ShowNotificationAction: Boolean);
    var
        ReportSelections: REcord "Report Selections";
        ReportUsage: Enum "Report Selection Usage";
    begin
        ReportUsage := GetServContractTypeUsage(ServiceContractHeader);

        ServiceContractHeader.SetRecFilter();

        ReportSelections.SaveAsDocumentAttachment(ReportUsage.AsInteger(), ServiceContractHeader, ServiceContractHeader."Contract No.", ServiceContractHeader."Bill-to Customer No.", ShowNotificationAction);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcServDisc(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintServiceHeader(var ServiceHeader: Record "Service Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintServiceItemWorksheet(var ServiceItemLine: Record "Service Item Line"; ReportUsage: Enum "Report Selection Usage"; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintServiceContract(var ServiceContractHeader: Record "Service Contract Header"; ReportUsage: Integer; var IsPrinted: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetServHeaderDocTypeUsageElseCase(ServiceHeader: Record "Service Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetServContractTypeUsageElseCase(ServiceContractHeader: Record "Service Contract Header"; var TypeUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Selection Mgt.", 'OnInitReportUsage', '', false, false)]
    local procedure InitReportSelection(ReportUsage: Integer)
    begin
        case "Report Selection Usage".FromInteger(ReportUsage) of
            "Report Selection Usage"::"SM.Quote":
                InsertRepSelection("Report Selection Usage"::"SM.Quote", '1', REPORT::"Service Quote");
            "Report Selection Usage"::"SM.Order":
                InsertRepSelection("Report Selection Usage"::"SM.Order", '1', REPORT::"Service Order");
            "Report Selection Usage"::"SM.Invoice":
                InsertRepSelection("Report Selection Usage"::"SM.Invoice", '1', REPORT::"Service - Invoice");
            "Report Selection Usage"::"SM.Credit Memo":
                InsertRepSelection("Report Selection Usage"::"SM.Credit Memo", '1', REPORT::"Service - Credit Memo");
            "Report Selection Usage"::"SM.Shipment":
                InsertRepSelection("Report Selection Usage"::"SM.Shipment", '1', REPORT::"Service - Shipment");
            "Report Selection Usage"::"SM.Contract Quote":
                InsertRepSelection("Report Selection Usage"::"SM.Contract Quote", '1', REPORT::"Service Contract Quote");
            "Report Selection Usage"::"SM.Contract":
                InsertRepSelection("Report Selection Usage"::"SM.Contract", '1', REPORT::"Service Contract");
            "Report Selection Usage"::"SM.Test":
                InsertRepSelection("Report Selection Usage"::"SM.Test", '1', REPORT::"Service Document - Test");
            "Report Selection Usage"::"SM.Item Worksheet":
                InsertRepSelection("Report Selection Usage"::"SM.Item Worksheet", '1', REPORT::"Service Item Worksheet");
        end;
    end;

    local procedure InsertRepSelection(ReportUsage: Enum "Report Selection Usage"; Sequence: Code[10]; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        if not ReportSelections.Get(ReportUsage, Sequence) then begin
            ReportSelections.Init();
            ReportSelections.Usage := ReportUsage;
            ReportSelections.Sequence := Sequence;
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Insert();
        end;
    end;
}