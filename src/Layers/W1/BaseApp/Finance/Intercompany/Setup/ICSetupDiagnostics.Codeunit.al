// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Setup;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;

codeunit 440 "IC Setup Diagnostics"
{
    var
        PartnerSetupIdTok: Label 'PARTNERSETUP', Locked = true;
        PartnerSetupDescriptionTxt: Label 'IC Partner Configuration';
        PartnerSetupICNotFoundErr: Label 'Intercompany setup for current company not found.';
        PartnerSetupUnconfiguredCustomerOrVendorErr: Label 'IC Partner %1 has not configured neither a customer nor a vendor.', Comment = '%1 - Intercompany Partner Code';
        PartnerSetupVendorNoPayablesErr: Label 'IC Partner %1 has configured a vendor without a Payables account.', Comment = '%1 - Intercompany Partner Code';
        PartnerSetupCustomerNoReceivablesErr: Label 'IC Partner %1 has configured a customer without a Receivables account.', Comment = '%1 - Intercompany Partner Code';
        PartnerSetupPartnerNoCompanyErr: Label 'IC Partner %1 has not configured a company.', Comment = '%1 - Intercompany Partner Code';
        PartnerSetupPartnerNoICErr: Label 'IC Partner company %1 has not configured intercompany.', Comment = '%1 - Intercompany Partner Code';
        PartnerSetupMissmatchCodesErr: Label 'IC Partner %1 has a different code than the one you configured.', Comment = '%1 - Intercompany Partner Code';

        MappingSetupIdTok: Label 'MAPPINGSETUP', Locked = true;
        MappingSetupDescriptionTxt: Label 'IC Mappings';
        MappingSetupICCoAEmptyErr: Label 'IC Chart of Accounts is empty';
        MappingSetupNoGLAccountWithICErr: Label 'No G/L Account has configured an IC G/L Account';


    procedure GetPartnerSetupId(): Code[20]
    begin
        exit(PartnerSetupIdTok);
    end;

    procedure InsertPartnerSetupDiagnostics(var TempParentSetupDiagnostic: Record "Intercompany Setup Diagnostic" temporary; var TempChildrenSetupDiagnostic: Record "Intercompany Setup Diagnostic" temporary)
    var
        ICSetup: Record "IC Setup";
        ICPartner: Record "IC Partner";
        Status: Option Ok,Warning,Error;
    begin
        if not ICSetup.Get() then begin
            InsertPartnerSetupDiagnostic(TempChildrenSetupDiagnostic, PartnerSetupICNotFoundErr, Status::Error);
            InsertPartnerSetupParentDiagnostic(TempParentSetupDiagnostic, Status::Error);
            exit;
        end;
        ICPartner.SetRange("Inbox Type", ICPartner."Inbox Type"::Database);
        Status := Status::Ok;
        if not ICPartner.FindSet() then begin
            InsertPartnerSetupParentDiagnostic(TempParentSetupDiagnostic, Status);
            exit;
        end;
        repeat
            InsertICPartnerPartnerSetupDiagnostics(ICPartner, TempChildrenSetupDiagnostic, Status);
        until ICPartner.Next() = 0;
        InsertPartnerSetupParentDiagnostic(TempParentSetupDiagnostic, Status);
    end;

    procedure InsertICPartnerPartnerSetupDiagnostics(ICPartner: Record "IC Partner"; var TempChildrenSetupDiagnostic: Record "Intercompany Setup Diagnostic" temporary; var Status: Option)
    var
        TempICSetup: Record "IC Setup" temporary;
        ICDataExchange: Interface "IC Data Exchange";
    begin
        if (ICPartner."Vendor No." = '') and (ICPartner."Customer No." = '') then begin
            UpdateStatus(Status, TempChildrenSetupDiagnostic.Status::Warning);
            InsertPartnerSetupDiagnostic(TempChildrenSetupDiagnostic, StrSubstNo(PartnerSetupUnconfiguredCustomerOrVendorErr, ICPartner.Code), TempChildrenSetupDiagnostic.Status::Warning);
        end;
        if (ICPartner."Vendor No." <> '') and (ICPartner."Payables Account" = '') then begin
            UpdateStatus(Status, TempChildrenSetupDiagnostic.Status::Warning);
            InsertPartnerSetupDiagnostic(TempChildrenSetupDiagnostic, StrSubstNo(PartnerSetupVendorNoPayablesErr, ICPartner.Code), TempChildrenSetupDiagnostic.Status::Warning);
        end;
        if (ICPartner."Customer No." <> '') and (ICPartner."Receivables Account" = '') then begin
            UpdateStatus(Status, TempChildrenSetupDiagnostic.Status::Warning);
            InsertPartnerSetupDiagnostic(TempChildrenSetupDiagnostic, StrSubstNo(PartnerSetupCustomerNoReceivablesErr, ICPartner.Code), TempChildrenSetupDiagnostic.Status::Warning);
        end;
        if ICPartner."Inbox Details" = '' then begin
            UpdateStatus(Status, TempChildrenSetupDiagnostic.Status::Error);
            InsertPartnerSetupDiagnostic(TempChildrenSetupDiagnostic, StrSubstNo(PartnerSetupPartnerNoCompanyErr, ICPartner.Code), TempChildrenSetupDiagnostic.Status::Error);
            exit;
        end;
        ICDataExchange := ICPartner."Data Exchange Type";
        ICDataExchange.GetICPartnerICSetup(ICPartner, TempICSetup);
        if not TempICSetup.Get() then begin
            UpdateStatus(Status, TempChildrenSetupDiagnostic.Status::Warning);
            InsertPartnerSetupDiagnostic(TempChildrenSetupDiagnostic, StrSubstNo(PartnerSetupPartnerNoICErr, ICPartner.Code), TempChildrenSetupDiagnostic.Status::Warning);
            exit;
        end;
        if TempICSetup."IC Partner Code" = ICPartner.Code then
            exit;
        UpdateStatus(Status, TempChildrenSetupDiagnostic.Status::Warning);
        InsertPartnerSetupDiagnostic(TempChildrenSetupDiagnostic, StrSubstNo(PartnerSetupMissmatchCodesErr, ICPartner.Code), TempChildrenSetupDiagnostic.Status::Warning);
    end;

    local procedure InsertPartnerSetupParentDiagnostic(var ParentSetupDiagnostic: Record "Intercompany Setup Diagnostic"; Status: Option)
    begin
        InsertPartnerSetupDiagnostic(ParentSetupDiagnostic, PartnerSetupDescriptionTxt, Status);
    end;

    local procedure InsertPartnerSetupDiagnostic(var TempIntercompanySetupDiagnostic: Record "Intercompany Setup Diagnostic" temporary; Description: Text[250]; Status: Option)
    begin
        InsertDiagnostic(TempIntercompanySetupDiagnostic, PartnerSetupIdTok, Description, Status);
    end;

    procedure GetMappingSetupId(): Code[20]
    begin
        exit(MappingSetupIdTok);
    end;

    procedure InsertMappingSetupDiagnostics(var ParentSetupDiagnostic: Record "Intercompany Setup Diagnostic" temporary; var ChildrenSetupDiagnostic: Record "Intercompany Setup Diagnostic" temporary)
    var
        ICGLAccount: Record "IC G/L Account";
        GLAccount: Record "G/L Account";
        Status: Option Ok,Warning,Error;
    begin
        Status := Status::Ok;
        if ICGLAccount.IsEmpty() then begin
            UpdateStatus(Status, Status::Warning);
            InsertMappingSetupDiagnostic(ChildrenSetupDiagnostic, MappingSetupICCoAEmptyErr, Status::Error);
        end;
        GLAccount.SetFilter("Default IC Partner G/L Acc. No", '<>%1', '');
        if GLAccount.IsEmpty() then begin
            UpdateStatus(Status, Status::Warning);
            InsertMappingSetupDiagnostic(ChildrenSetupDiagnostic, MappingSetupNoGLAccountWithICErr, Status::Warning);
        end;

        InsertMappingSetupParentDiagnostic(ParentSetupDiagnostic, Status);
    end;

    local procedure InsertMappingSetupParentDiagnostic(var ParentSetupDiagnostic: Record "Intercompany Setup Diagnostic"; Status: Option Ok,Warning,Error)
    begin
        InsertMappingSetupDiagnostic(ParentSetupDiagnostic, MappingSetupDescriptionTxt, Status);
    end;

    local procedure InsertMappingSetupDiagnostic(var TempIntercompanySetupDiagnostic: Record "Intercompany Setup Diagnostic" temporary; Description: Text[250]; Status: Option)
    begin
        InsertDiagnostic(TempIntercompanySetupDiagnostic, MappingSetupIdTok, Description, Status);
    end;

    local procedure InsertDiagnostic(var TempIntercompanySetupDiagnostic: Record "Intercompany Setup Diagnostic" temporary; Id: Code[20]; Description: Text[250]; Status: Option)
    begin
        TempIntercompanySetupDiagnostic.Init();
        TempIntercompanySetupDiagnostic.Id := Id;
        TempIntercompanySetupDiagnostic.Description := Description;
        TempIntercompanySetupDiagnostic.Status := Status;
        TempIntercompanySetupDiagnostic.Insert();
    end;

    procedure UpdateStatus(var OldStatus: Option; NewStatus: Option)
    var
        IntercompanySetupDiagnostic: Record "Intercompany Setup Diagnostic";
    begin
        if NewStatus = IntercompanySetupDiagnostic.Status::Ok then
            exit;
        if OldStatus = IntercompanySetupDiagnostic.Status::Error then
            exit;
        OldStatus := NewStatus;
    end;
}
