// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Reporting;
using Microsoft.Integration.Graph;
using Microsoft.Sales.Customer;
using System.EMail;
using System.Utilities;

codeunit 5445 "Cust. St. PDF Doc.Handler" implements IPdfDocumentHandler
{
    var
        CannotFindContactErr: Label 'The Contact cannot be found with SystemId %1.', Comment = '%1 - Contact System id';
        CustomerStatementLbl: Label 'Customer Statement';

    /// <summary>
    /// Generates a PDF blob for Customer Statement
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary): Boolean
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactBusinessRelation: Record "Contact Business Relation";
        ReportSelections: Record "Report Selections";
        DocumentMailing: Codeunit "Document-Mailing";
        PDFDocumentManagement: Codeunit "PDF Document Management";
        TempBlob: Codeunit "Temp Blob";
        Name: Text[250];
        ReportUsage: Enum "Report Selection Usage";
    begin
        if not Contact.GetBySystemId(DocumentId) then
            Error(CannotFindContactErr, DocumentId);

        Clear(Customer);
        ContactBusinessRelation.SetRange("Contact No.", Contact."Company No.");
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        if not ContactBusinessRelation.FindFirst() then
            exit(false);

        Customer.Get(ContactBusinessRelation."No.");
        Customer.SetRange("No.", Customer."No.");
        ReportUsage := "Report Selection Usage"::"C.Statement";
        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, Customer, Customer."No.");
        DocumentMailing.GetAttachmentFileName(Name, Customer."No.", CustomerStatementLbl, ReportUsage.AsInteger());
        exit(PDFDocumentManagement.AddToTempAttachmentEntityBuffer(DocumentId, DocumentType, TempBlob, Name, TempAttachmentEntityBuffer));
    end;
}