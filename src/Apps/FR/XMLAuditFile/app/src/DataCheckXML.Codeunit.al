// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Company;

codeunit 10805 "Data Check XML" implements "Audit File Export Data Check"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure CheckDataToExport(var AuditFileExportHeader: Record "Audit File Export Header"): Enum "Audit Data Check Status"
    var
        Contact: Record Contact;
    begin
        Contact.Get(AuditFileExportHeader.Contact);
        Contact.TestField(Address);
    end;

    procedure CheckAuditDocReadyToExport(var AuditFileExportHeader: Record "Audit File Export Header"): Enum "Audit Data Check Status"
    var
        CompanyInformation: Record "Company Information";
    begin
        AuditFileExportHeader.TestField("Starting Date");
        AuditFileExportHeader.TestField("Ending Date");

        CompanyInformation.Get();
        CompanyInformation.TestField("Registration No.");

        exit("Audit Data Check Status"::Passed);
    end;
}
