// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

codeunit 8143 "Report Filename Defaults"
{
    Access = Internal;
    // The two Company-Initialize events must share the pre-initialization state.
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Report Filename Setup" = ri,
                  tabledata "Report Filename Pattern" = ri;

    var
        CompanyWasInitialized: Boolean;
        DefaultPatternTok: Label '[Kind of Document]-[No.]', Locked = true;

    internal procedure InitializeSetup(EnableForNewCompany: Boolean)
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        if not ReportFilenameSetup.Get() then begin
            ReportFilenameSetup.Init();
            ReportFilenameSetup.Enabled := EnableForNewCompany;
            ReportFilenameSetup.Insert(true);
        end;

        InsertDefaultPattern(Database::"Sales Invoice Header");
        InsertDefaultPattern(Database::"Sales Cr.Memo Header");
        InsertDefaultPattern(Database::"Purch. Inv. Header");
        InsertDefaultPattern(Database::"Purch. Cr. Memo Hdr.");
    end;

    internal procedure InitializeExistingCompany()
    begin
        // Installation only visits companies that already exist, including empty ones.
        InitializeSetup(false);
    end;

    local procedure InsertDefaultPattern(TableNo: Integer)
    var
        Pattern: Record "Report Filename Pattern";
    begin
        // Even a disabled, filtered or report-specific pattern is an existing choice.
        Pattern.SetRange("Table No.", TableNo);
        if not Pattern.IsEmpty() then
            exit;

        Pattern.Init();
        Pattern.Validate("Table No.", TableNo);
        Pattern.Validate("File Name Pattern", DefaultPatternTok);
        Pattern.Validate(Enabled, true);
        Pattern.Insert(true);
    end;

    internal procedure OnBeforeCompanyInitialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // A manual rerun in an existing company is not a new-company signal.
        CompanyWasInitialized := GeneralLedgerSetup.Get();
    end;

    internal procedure OnCompanyInitialize()
    var
        ReportFilenameSetup: Record "Report Filename Setup";
        EnableForNewCompany: Boolean;
    begin
        EnableForNewCompany := not CompanyWasInitialized;
        CompanyWasInitialized := true;
        // Copied settings and subsequent initialization must retain the user's choices.
        if ReportFilenameSetup.Get() then
            exit;
        InitializeSetup(EnableForNewCompany);
    end;
}
