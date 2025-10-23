// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------
// namespace Microsoft.Peppol;

// using Microsoft.Service.Document;
// using Microsoft.Service.History;

// codeunit 37209 "PEPPOL30 Service Validation"
// {
//     TableNo = "Service Header";

//     trigger OnRun()
//     begin
//         CheckServiceHeader(Rec);
//     end;

//     procedure CheckServiceHeader(ServiceHeader: Record "Service Header")
//     var
//         PEPPOL30ServValidImpl: Codeunit "PEPPOL30 Serv. Valid. Impl.";
//     begin
//         PEPPOL30ServValidImpl.CheckServiceHeader(ServiceHeader);
//     end;

//     procedure CheckServiceInvoice(ServiceInvoiceHeader: Record "Service Invoice Header")
//     var
//         PEPPOL30ServValidImpl: Codeunit "PEPPOL30 Serv. Valid. Impl.";
//     begin
//         PEPPOL30ServValidImpl.CheckServiceInvoice(ServiceInvoiceHeader);
//     end;

//     procedure CheckServiceCreditMemo(ServiceCrMemoHeader: Record "Service Cr.Memo Header")
//     var
//         PEPPOL30ServValidImpl: Codeunit "PEPPOL30 Serv. Valid. Impl.";
//     begin
//         PEPPOL30ServValidImpl.CheckServiceCreditMemo(ServiceCrMemoHeader);
//     end;
// }