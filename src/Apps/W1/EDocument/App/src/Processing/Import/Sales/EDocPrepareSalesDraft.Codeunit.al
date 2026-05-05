// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Sales;

using Microsoft.eServices.EDocument;
using System.Log;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.Foundation.UOM;
using Microsoft.Sales.Customer;

/// <summary>
/// Shared logic for preparing sales order drafts. Resolves customer and sales lines
/// from staging data populated by the PEPPOL handler.
/// </summary>
codeunit 50002 "EDoc Prepare Sales Draft"
{
    Access = Internal;

    var
        EDocImpSessionTelemetry: Codeunit "E-Doc. Imp. Session Telemetry";

    procedure PrepareDraft(EDocument: Record "E-Document"; EDocImportParameters: Record "E-Doc. Import Parameters")
    var
        EDocumentSalesHeader: Record "E-Document Sales Header";
        EDocumentSalesLine: Record "E-Document Sales Line";
        UnitOfMeasure: Record "Unit of Measure";
        Customer: Record Customer;
        EDocActivityLogSession: Codeunit "E-Doc. Activity Log Session";
        IUnitOfMeasureProvider: Interface IUnitOfMeasureProvider;
        ISalesLineProvider: Interface ISalesLineProvider;
        ICustomerProvider: Interface ICustomerProvider;
    begin
        IUnitOfMeasureProvider := EDocImportParameters."Processing Customizations";
        ISalesLineProvider := EDocImportParameters."Processing Customizations";
        ICustomerProvider := EDocImportParameters."Processing Customizations";

        if EDocActivityLogSession.CreateSession() then;

        EDocumentSalesHeader.GetFromEDocument(EDocument);
        EDocumentSalesHeader.TestField("E-Document Entry No.");
        if EDocumentSalesHeader."[BC] Customer No." = '' then begin
            Customer := ICustomerProvider.GetCustomer(EDocument);
            EDocumentSalesHeader."[BC] Customer No." := Customer."No.";
        end;
        EDocumentSalesHeader.Modify();

        EDocImpSessionTelemetry.SetBool('Customer', EDocumentSalesHeader."[BC] Customer No." <> '');

        EDocumentSalesLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentSalesLine.FindSet() then
            repeat
                UnitOfMeasure := IUnitOfMeasureProvider.GetUnitOfMeasure(EDocument, EDocumentSalesLine."Line No.", EDocumentSalesLine."Unit of Measure");
                EDocumentSalesLine."[BC] Unit of Measure" := UnitOfMeasure.Code;
                ISalesLineProvider.GetSalesLine(EDocumentSalesLine);
                EDocumentSalesLine.Modify();
            until EDocumentSalesLine.Next() = 0;

        Clear(EDocumentSalesLine);
        EDocumentSalesLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        if EDocumentSalesLine.FindSet() then
            repeat
                EDocImpSessionTelemetry.SetLine(EDocumentSalesLine.SystemId);
            until EDocumentSalesLine.Next() = 0;

        LogAllActivitySessionChanges(EDocActivityLogSession);

        if EDocActivityLogSession.EndSession() then;
    end;

    local procedure LogAllActivitySessionChanges(EDocActivityLogSession: Codeunit "E-Doc. Activity Log Session")
    begin
        Log(EDocActivityLogSession, EDocActivityLogSession.SellerItemIdTok());
        Log(EDocActivityLogSession, EDocActivityLogSession.GtinTok());
        Log(EDocActivityLogSession, EDocActivityLogSession.StandardItemIdTok());
        Log(EDocActivityLogSession, EDocActivityLogSession.BuyerItemRefTok());
    end;

    local procedure Log(EDocActivityLogSession: Codeunit "E-Doc. Activity Log Session"; ActivityLogName: Text)
    var
        ActivityLog: Codeunit "Activity Log Builder";
        ActivityLogList: List of [Codeunit "Activity Log Builder"];
        Found: Boolean;
    begin
        Clear(ActivityLogList);
        EDocActivityLogSession.GetAll(ActivityLogName, ActivityLogList, Found);
        foreach ActivityLog in ActivityLogList do
            ActivityLog.Log();
    end;
}
