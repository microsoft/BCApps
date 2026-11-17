// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DemoData.Sales;

using Microsoft.DemoData.Foundation;
using Microsoft.Sales.Setup;
using System.Environment.Configuration;

codeunit 13456 "Create Sales Recv. Setup FI"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    trigger OnRun()
    begin
        UpdateSalesReceivablesSetup();
    end;

    local procedure UpdateSalesReceivablesSetup()
    var
        CreateJobQueueCategory: Codeunit "Create Job Queue Category";
    begin
        ValidateRecordFields(CreateJobQueueCategory.SalesPurchasePosting(), true, true, true);
    end;

    local procedure ValidateRecordFields(JobQueueCategoryCode: Code[10]; InvoiceNo: Boolean; CustomerNo: Boolean; PrintReferenceNo: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
#if not CLEAN30
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#endif
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Job Queue Category Code", JobQueueCategoryCode);
#if not CLEAN30
        if not FeatureManagementFacade.IsEnabled('BankingAndPaymentsFI') then begin
#pragma warning disable AL0432
            SalesReceivablesSetup.Validate("Invoice No.", InvoiceNo);
            SalesReceivablesSetup.Validate("Customer No.", CustomerNo);
            SalesReceivablesSetup.Validate("Print Reference No.", PrintReferenceNo);
#pragma warning restore AL0432
        end else
#endif
        begin
            SalesReceivablesSetup.Validate("Use Invoice No. in Reference", InvoiceNo);
            SalesReceivablesSetup.Validate("Use Customer No. in Reference", CustomerNo);
            SalesReceivablesSetup.Validate("Print Payment Reference", PrintReferenceNo);
        end;
        SalesReceivablesSetup.Modify(true);
    end;
}
