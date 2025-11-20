// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.GLAccount;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.Partner;
using System.Telemetry;

codeunit 428 "IC Mapping"
{
    trigger OnRun()
    begin
    end;

    procedure GetFeatureTelemetryName(): Text
    begin
        exit('Intercompany');
    end;

    #region Mapping Accounts
    procedure MapICAccounts(var ICAccounts: Record "IC G/L Account")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IIS', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICAccounts.IsEmpty() then
            exit;

        repeat
            MapAccounts(ICAccounts);
        until ICAccounts.Next() = 0;
    end;

    procedure MapCompanyAccounts(var GLAccounts: Record "G/L Account")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IV9', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if GLAccounts.IsEmpty() then
            exit;

        GLAccounts.FindSet();
        repeat
            MapAccounts(GLAccounts);
        until GLAccounts.Next() = 0;
    end;

    procedure RemoveICMapping(var ICAccounts: Record "IC G/L Account")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IVA', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICAccounts.IsEmpty() then
            exit;

        ICAccounts.FindSet();
        repeat
            RemoveMapAccounts(ICAccounts);
        until ICAccounts.Next() = 0;
    end;

    procedure RemoveCompanyMapping(var GLAccounts: Record "G/L Account")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IVB', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if GLAccounts.IsEmpty() then
            exit;

        GLAccounts.FindSet();
        repeat
            RemoveMapAccounts(GLAccounts);
        until GLAccounts.Next() = 0;
    end;

    procedure MapAccounts(ICAccount: Record "IC G/L Account")
    var
        GLAccount: Record "G/L Account";
    begin
        if not GLAccount.Get(ICAccount."No.") then
            exit;

        if ICAccount."Account Type" = GLAccount."Account Type" then begin
            ICAccount."Map-to G/L Acc. No." := GLAccount."No.";
            ICAccount.Modify();
        end;
    end;

    procedure MapAccounts(GLAccount: Record "G/L Account")
    var
        ICAccount: Record "IC G/L Account";
    begin
        if not ICAccount.Get(GLAccount."No.") then
            exit;

        if GLAccount."Account Type" = ICAccount."Account Type" then begin
            GLAccount."Default IC Partner G/L Acc. No" := ICAccount."No.";
            GLAccount.Modify();
        end;
    end;

    procedure RemoveMapAccounts(ICAccount: Record "IC G/L Account")
    begin
        if ICAccount."Map-to G/L Acc. No." = '' then
            exit;
        Clear(ICAccount."Map-to G/L Acc. No.");
        ICAccount.Modify();
    end;

    procedure RemoveMapAccounts(GLAccount: Record "G/L Account")
    begin
        if GLAccount."Default IC Partner G/L Acc. No" = '' then
            exit;
        Clear(GLAccount."Default IC Partner G/L Acc. No");
        GLAccount.Modify();
    end;

    procedure SynchronizeAccounts(DeleteExistingEntries: Boolean; PartnerCode: Code[20])
    var
        TempICPartnerAccount: Record "IC G/L Account" temporary;
        ICAccounts: Record "IC G/L Account";
        ICPartner: Record "IC Partner";
        GLAccount: Record "G/L Account";
        ICDataExchange: Interface "IC Data Exchange";
        IsChangeCompanyAllowed: Boolean;
    begin
        if not ICPartner.Get(PartnerCode) then
            Error(FailedToFindPartnerErr, PartnerCode);

        if ICPartner."Inbox Type" <> ICPartner."Inbox Type"::Database then
            Error(SyncInboxTypeNotDatabaseErr, PartnerCode, ICPartner."Inbox Type");

        IsChangeCompanyAllowed := true;
        OnAllowChangeCompanyForTempICAccounts(IsChangeCompanyAllowed, TempICPartnerAccount);
        if IsChangeCompanyAllowed then begin
            // Delete existing IC Accounts if the syncronization points to a company with no IC Accounts and remove the G/L account mapping.
            ICDataExchange := ICPartner."Data Exchange Type";
            ICDataExchange.GetICPartnerICGLAccount(ICPartner, TempICPartnerAccount);
            if TempICPartnerAccount.IsEmpty() then begin
                if not ICAccounts.IsEmpty() then begin
                    ICAccounts.DeleteAll();
                    GLAccount.SetFilter("Default IC Partner G/L Acc. No", '<> ''''');
                    if not GLAccount.IsEmpty() then
                        GLAccount.ModifyAll("Default IC Partner G/L Acc. No", '');
                end;
                exit;
            end;
            TempICPartnerAccount.FindSet();
        end;

        if DeleteExistingEntries then
            if not ICAccounts.IsEmpty() then
                ICAccounts.DeleteAll();

        TransferICMappingsAndDeletedICAccounts(ICAccounts, TempICPartnerAccount);
        TempICPartnerAccount.Reset();
        TempICPartnerAccount.FindSet();
        ICAccounts.LockTable();
        repeat
            ICAccounts.TransferFields(TempICPartnerAccount);
            ICAccounts.Indentation := 0;
            ICAccounts.Insert();
        until TempICPartnerAccount.Next() = 0;
    end;

    local procedure TransferICMappingsAndDeletedICAccounts(var ICAccounts: Record "IC G/L Account"; var TempICPartnerAccount: Record "IC G/L Account" temporary)
    var
        GLAccount: Record "G/L Account";
    begin
        ICAccounts.Reset();
        TempICPartnerAccount.Reset();
        if ICAccounts.IsEmpty() then
            exit;
        if not TempICPartnerAccount.IsEmpty() then
            TempICPartnerAccount.ModifyAll("Map-to G/L Acc. No.", '');

        ICAccounts.FindSet();
        repeat
            TempICPartnerAccount.SetRange("No.", ICAccounts."No.");
            TempICPartnerAccount.SetRange("Account Type", ICAccounts."Account Type");
            if TempICPartnerAccount.FindFirst() then begin
                TempICPartnerAccount."Map-to G/L Acc. No." := ICAccounts."Map-to G/L Acc. No.";
                TempICPartnerAccount.Modify();
            end
            else begin
                GLAccount.SetRange("Default IC Partner G/L Acc. No", ICAccounts."No.");
                if not GLAccount.IsEmpty() then
                    GLAccount.ModifyAll("Default IC Partner G/L Acc. No", '');
            end
        until ICAccounts.Next() = 0;

        ICAccounts.Reset();
        if not ICAccounts.IsEmpty() then
            ICAccounts.DeleteAll();
    end;
    #endregion

    #region Mapping Dimensions
    procedure MapICDimensions(var ICDimensions: Record "IC Dimension")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IIT', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICDimensions.IsEmpty() then
            exit;

        ICDimensions.FindSet();
        repeat
            MapIncomingICDimensions(ICDimensions);
        until ICDimensions.Next() = 0;
    end;

    procedure MapCompanyDimensions(var Dimensions: Record Dimension)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IIU', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if Dimensions.IsEmpty() then
            exit;

        Dimensions.FindSet();
        repeat
            MapOutgoingICDimensions(Dimensions);
        until Dimensions.Next() = 0;
    end;

    procedure RemoveICMapping(var ICDimension: Record "IC Dimension")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IVW', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICDimension.IsEmpty() then
            exit;

        ICDimension.FindSet();
        repeat
            RemoveMapDimensions(ICDimension);
        until ICDimension.Next() = 0;
    end;

    procedure RemoveCompanyMapping(var Dimensions: Record Dimension)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IVX', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if Dimensions.IsEmpty() then
            exit;

        Dimensions.FindSet();
        repeat
            RemoveMapDimensions(Dimensions);
        until Dimensions.Next() = 0;
    end;

    procedure MapICDimensionValues(var ICDimensionValues: Record "IC Dimension Value")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000J35', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICDimensionValues.IsEmpty() then
            exit;

        ICDimensionValues.FindSet();
        repeat
            MapIncomingICDimensionValues(ICDimensionValues);
        until ICDimensionValues.Next() = 0;
    end;

    procedure MapCompanyDimensionValues(var DimensionValues: Record "Dimension Value")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000J36', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if DimensionValues.IsEmpty() then
            exit;

        DimensionValues.FindSet();
        repeat
            MapOutgoingICDimensionValues(DimensionValues);
        until DimensionValues.Next() = 0;
    end;

    procedure RemoveICMapping(var ICDimensionValue: Record "IC Dimension Value")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000J37', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if ICDimensionValue.IsEmpty() then
            exit;

        ICDimensionValue.FindSet();
        repeat
            RemoveMapDimensionValues(ICDimensionValue);
            ICDimensionValue.Modify();
        until ICDimensionValue.Next() = 0;
    end;

    procedure RemoveCompanyMapping(var DimensionValues: Record "Dimension Value")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000J38', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");

        if DimensionValues.IsEmpty() then
            exit;

        DimensionValues.FindSet();
        repeat
            RemoveMapDimensionValues(DimensionValues);
            DimensionValues.Modify();
        until DimensionValues.Next() = 0;
    end;

    procedure MapIncomingICDimensions(ICDimension: Record "IC Dimension")
    var
        Dimension: Record Dimension;
        ICDimensionValue: Record "IC Dimension Value";
    begin

        if Dimension.Get(ICDimension.Code) then begin
            ICDimension."Map-to Dimension Code" := Dimension.Code;
            ICDimension.Modify();
            ICDimensionValue.SetRange("Dimension Code", ICDimension.Code);
            if not ICDimensionValue.IsEmpty() then begin
                ICDimensionValue.ModifyAll("Map-to Dimension Code", ICDimension."Map-to Dimension Code");
                ICDimensionValue.FindSet();
                repeat
                    MapIncomingICDimensionValues(ICDimensionValue);
                until ICDimensionValue.Next() = 0;
            end;
        end;
    end;

    procedure MapOutgoingICDimensions(Dimension: Record Dimension)
    var
        ICDimension: Record "IC Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        if ICDimension.Get(Dimension.Code) then begin
            Dimension."Map-to IC Dimension Code" := ICDimension.Code;
            Dimension.Modify();
            DimensionValue.SetRange("Dimension Code", Dimension.Code);
            if not DimensionValue.IsEmpty() then begin
                DimensionValue.ModifyAll("Map-to IC Dimension Code", Dimension."Map-to IC Dimension Code");
                DimensionValue.FindSet();
                repeat
                    MapOutgoingICDimensionValues(DimensionValue);
                until DimensionValue.Next() = 0;
            end;
        end;
    end;

    procedure MapIncomingICDimensionValues(var ICDimensionValue: Record "IC Dimension Value")
    var
        DimensionValue: Record "Dimension Value";
    begin
        if not DimensionValue.Get(ICDimensionValue."Dimension Code", ICDimensionValue.Code) then
            exit;

        if DimensionValue."Dimension Code" <> ICDimensionValue."Map-to Dimension Code" then
            exit;

        if DimensionValue."Dimension Value Type" = ICDimensionValue."Dimension Value Type" then begin
            ICDimensionValue.Validate("Map-to Dimension Value Code", DimensionValue.Code);
            ICDimensionValue.Modify();
        end;
    end;

    procedure MapOutgoingICDimensionValues(var DimensionValue: Record "Dimension Value")
    var
        ICDimensionValue: Record "IC Dimension Value";
    begin
        if not ICDimensionValue.Get(DimensionValue."Dimension Code", DimensionValue.Code) then
            exit;

        if ICDimensionValue."Dimension Code" <> DimensionValue."Map-to IC Dimension Code" then
            exit;

        if ICDimensionValue."Dimension Value Type" = DimensionValue."Dimension Value Type" then begin
            DimensionValue.Validate("Map-to IC Dimension Value Code", ICDimensionValue.Code);
            DimensionValue.Modify();
        end;
    end;

    procedure RemoveMapDimensions(ICDimensions: Record "IC Dimension")
    var
        ICDimensionValue: Record "IC Dimension Value";
    begin
        if ICDimensions."Map-to Dimension Code" <> '' then begin
            Clear(ICDimensions."Map-to Dimension Code");
            ICDimensions.Modify();
        end;

        ICDimensionValue.SetRange("Dimension Code", ICDimensions.Code);
        if not ICDimensionValue.IsEmpty() then begin
            ICDimensionValue.FindSet();
            repeat
                ICDimensionValue."Map-to Dimension Code" := '';
                RemoveMapDimensionValues(ICDimensionValue);
                ICDimensionValue.Modify();
            until ICDimensionValue.Next() = 0;
        end;
    end;

    procedure RemoveMapDimensions(CompanyDimension: Record Dimension)
    var
        DimensionValue: Record "Dimension Value";
    begin
        if CompanyDimension."Map-to IC Dimension Code" <> '' then begin
            Clear(CompanyDimension."Map-to IC Dimension Code");
            CompanyDimension.Modify();
        end;

        DimensionValue.SetRange("Dimension Code", CompanyDimension.Code);
        if not DimensionValue.IsEmpty() then begin
            DimensionValue.FindSet();
            repeat
                DimensionValue."Map-to IC Dimension Code" := '';
                RemoveMapDimensionValues(DimensionValue);
                DimensionValue.Modify();
            until DimensionValue.Next() = 0;
        end;
    end;

    procedure RemoveMapDimensionValues(var ICDimensionValues: Record "IC Dimension Value")
    begin
        if ICDimensionValues."Map-to Dimension Value Code" = '' then
            exit;
        Clear(ICDimensionValues."Map-to Dimension Value Code");
    end;

    procedure RemoveMapDimensionValues(var CompanyDimensionValue: Record "Dimension Value")
    begin
        if CompanyDimensionValue."Map-to IC Dimension Value Code" = '' then
            exit;
        Clear(CompanyDimensionValue."Map-to IC Dimension Value Code");
    end;

    procedure SynchronizeDimensions(DeleteExistingEntries: Boolean; PartnerCode: Code[20])
    var
        TempPartnersICDimension: Record "IC Dimension" temporary;
        TempPartnersICDimensionValue: Record "IC Dimension Value" temporary;
        ICDimensions: Record "IC Dimension";
        ICDimensionValues: Record "IC Dimension Value";
        ICPartner: Record "IC Partner";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        ICDataExchange: Interface "IC Data Exchange";
        IsChangeCompanyAllowed: Boolean;
    begin
        if not ICPartner.Get(PartnerCode) then
            Error(FailedToFindPartnerErr, PartnerCode);

        if ICPartner."Inbox Type" <> ICPartner."Inbox Type"::Database then
            Error(SyncInboxTypeNotDatabaseErr, PartnerCode, ICPartner."Inbox Type");

        IsChangeCompanyAllowed := true;
        OnAllowChangeCompanyForTempICDimensions(IsChangeCompanyAllowed, TempPartnersICDimension, TempPartnersICDimensionValue);
        if IsChangeCompanyAllowed then begin
            // Delete existing IC Dimensions if the syncronization points to a company with no IC Dimensions 
            // and remove the dimensions and dimensions values mapping.
            ICDataExchange := ICPartner."Data Exchange Type";
            ICDataExchange.GetICPartnerICDimension(ICPartner, TempPartnersICDimension);
            ICDataExchange.GetICPartnerICDimensionValue(ICPartner, TempPartnersICDimensionValue);
            if TempPartnersICDimension.IsEmpty() then begin
                if not ICDimensions.IsEmpty() then begin
                    ICDimensions.DeleteAll();
                    Dimension.SetFilter("Map-to IC Dimension Code", '<> ''''');
                    if not Dimension.IsEmpty() then
                        Dimension.ModifyAll("Map-to IC Dimension Code", '');
                end;
                if not ICDimensionValues.IsEmpty() then begin
                    ICDimensionValues.DeleteAll();
                    DimensionValue.SetFilter("Map-to IC Dimension Value Code", '<> ''''');
                    if not DimensionValue.IsEmpty() then begin
                        DimensionValue.ModifyAll("Map-to IC Dimension Code", '');
                        DimensionValue.ModifyAll("Map-to IC Dimension Value Code", '');
                    end;
                end;
                exit;
            end;
            TempPartnersICDimension.FindSet();
        end;

        if DeleteExistingEntries then begin
            if not ICDimensions.IsEmpty() then
                ICDimensions.DeleteAll();
            if not ICDimensionValues.IsEmpty() then
                ICDimensionValues.DeleteAll();
        end;

        TransferICMappingsAndDeletedICDimensions(ICDimensions, TempPartnersICDimension);
        TempPartnersICDimension.Reset();
        TempPartnersICDimension.FindSet();
        ICDimensions.LockTable();
        repeat
            ICDimensions.TransferFields(TempPartnersICDimension);
            ICDimensions.Insert();
        until TempPartnersICDimension.Next() = 0;

        TransferICMappingsAndDeletedICDimensionValues(ICDimensionValues, TempPartnersICDimensionValue);
        TempPartnersICDimensionValue.Reset();
        TempPartnersICDimensionValue.FindSet();
        ICDimensionValues.LockTable();
        repeat
            ICDimensionValues.TransferFields(TempPartnersICDimensionValue);
            ICDimensionValues.Insert();
        until TempPartnersICDimensionValue.Next() = 0;
    end;

    local procedure TransferICMappingsAndDeletedICDimensions(var ICDimensions: Record "IC Dimension"; var TempPartnersICDimension: Record "IC Dimension" temporary)
    var
        Dimension: Record Dimension;
    begin
        ICDimensions.Reset();
        TempPartnersICDimension.Reset();
        if ICDimensions.IsEmpty() then
            exit;
        if not TempPartnersICDimension.IsEmpty() then
            TempPartnersICDimension.ModifyAll("Map-to Dimension Code", '');

        ICDimensions.FindSet();
        repeat
            if TempPartnersICDimension.Get(ICDimensions.Code) then begin
                TempPartnersICDimension."Map-to Dimension Code" := ICDimensions."Map-to Dimension Code";
                TempPartnersICDimension.Modify();
            end
            else begin
                Dimension.SetRange("Map-to IC Dimension Code", ICDimensions.Code);
                if not Dimension.IsEmpty() then
                    Dimension.ModifyAll("Map-to IC Dimension Code", '');
            end;
        until ICDimensions.Next() = 0;

        ICDimensions.Reset();
        if not ICDimensions.IsEmpty() then
            ICDimensions.DeleteAll();
    end;

    local procedure TransferICMappingsAndDeletedICDimensionValues(var ICDimensionValues: Record "IC Dimension Value"; var TempPartnersICDimensionValue: Record "IC Dimension Value" temporary)
    var
        DimensionValue: Record "Dimension Value";
    begin
        ICDimensionValues.Reset();
        TempPartnersICDimensionValue.Reset();
        if ICDimensionValues.IsEmpty() then
            exit;
        if not TempPartnersICDimensionValue.IsEmpty() then begin
            TempPartnersICDimensionValue.ModifyAll("Map-to Dimension Code", '');
            TempPartnersICDimensionValue.ModifyAll("Map-to Dimension Value Code", '');
        end;

        ICDimensionValues.FindSet();
        repeat
            if TempPartnersICDimensionValue.Get(ICDimensionValues."Dimension Code", ICDimensionValues.Code) then begin
                TempPartnersICDimensionValue."Map-to Dimension Code" := ICDimensionValues."Map-to Dimension Code";
                TempPartnersICDimensionValue."Map-to Dimension Value Code" := ICDimensionValues."Map-to Dimension Value Code";
                TempPartnersICDimensionValue.Modify();
            end
            else begin
                DimensionValue.SetRange("Map-to IC Dimension Value Code", ICDimensionValues.Code);
                if not DimensionValue.IsEmpty() then begin
                    DimensionValue.ModifyAll("Map-to IC Dimension Code", '');
                    DimensionValue.ModifyAll("Map-to IC Dimension Value Code", '');
                end;
            end;
        until ICDimensionValues.Next() = 0;

        ICDimensionValues.Reset();
        if not ICDimensionValues.IsEmpty() then
            ICDimensionValues.DeleteAll();
    end;
    #endregion

    internal procedure CopyBankAccountsFromPartner(PartnerCode: Code[20])
    var
        TempPartnersBankAccounts: Record "Bank Account" temporary;
        ICBankAccounts: Record "IC Bank Account";
        ICPartner: Record "IC Partner";
        ICDataExchange: Interface "IC Data Exchange";
        IsChangeCompanyAllowed: Boolean;
    begin
        if not ICPartner.Get(PartnerCode) then
            Error(FailedToFindPartnerErr, PartnerCode);

        if ICPartner."Inbox Type" <> ICPartner."Inbox Type"::Database then
            Error(CopyInboxTypeNotDatabaseErr, PartnerCode, ICPartner."Inbox Type");

        IsChangeCompanyAllowed := true;
        OnAllowChangeCompanyForTempBankAccounts(IsChangeCompanyAllowed, TempPartnersBankAccounts);
        if IsChangeCompanyAllowed then begin
            // Delete existing IC Bank Accounts if the syncronization points to a company with no IC Bank Accounts.
            ICDataExchange := ICPartner."Data Exchange Type";
            ICDataExchange.GetICPartnerBankAccount(ICPartner, TempPartnersBankAccounts);
            TempPartnersBankAccounts.SetRange(IntercompanyEnable, true);
            if TempPartnersBankAccounts.IsEmpty() then begin
                Message(NoBankAccountsWithICEnableMsg, ICPartner.Code);
                ICBankAccounts.SetRange("IC Partner Code", PartnerCode);
                if not ICBankAccounts.IsEmpty() then
                    ICBankAccounts.DeleteAll();
                exit;
            end;
            TempPartnersBankAccounts.FindSet();
        end;

        ICBankAccounts.Reset();
        repeat
            ICBankAccounts."No." := TempPartnersBankAccounts."No.";
            ICBankAccounts."IC Partner Code" := PartnerCode;
            ICBankAccounts.Name := TempPartnersBankAccounts.Name;
            ICBankAccounts."Bank Account No." := TempPartnersBankAccounts."Bank Account No.";
            ICBankAccounts.Blocked := TempPartnersBankAccounts.Blocked;
            ICBankAccounts."Currency Code" := TempPartnersBankAccounts."Currency Code";
            ICBankAccounts.IBAN := TempPartnersBankAccounts.IBAN;
            ICBankAccounts.Insert();
        until TempPartnersBankAccounts.Next() = 0;
    end;

    var
        FailedToFindPartnerErr: Label 'There is no partner with code %1 in the list of your intercompany partners.', Comment = '%1 = Partner code';
        SyncInboxTypeNotDatabaseErr: Label 'Syncronization is only available for partners using database as their intercompany inbox type. Partner %1 inbox type is %2', Comment = '%1 = Partner code, %2 = Partner inbox type';
        CopyInboxTypeNotDatabaseErr: Label 'Copy is only available for partners using database as their intercompany inbox type. Partner %1 inbox type is %2', Comment = '%1 = Partner code, %2 = Partner inbox type';
        NoBankAccountsWithICEnableMsg: Label 'The bank accounts for IC Partner %1 are not set up for intercompany copying. Enable bank accounts to be copied on IC Partner %1 by visiting the bank account card and selecting Enable for Intercompany transactions.', Comment = '%1 = Partner Code';

    [IntegrationEvent(false, false)]
    local procedure OnAllowChangeCompanyForTempICAccounts(var IsChangeCompanyAllowed: Boolean; var TempPartnersICAccounts: Record "IC G/L Account" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAllowChangeCompanyForTempICDimensions(var IsChangeCompanyAllowed: Boolean; var TempPartnersICDimensions: Record "IC Dimension" temporary; var TempPartnersICDimensionValues: Record "IC Dimension Value" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAllowChangeCompanyForTempBankAccounts(var IsChangeCompanyAllowed: Boolean; var TempPartnersBankAccounts: Record "Bank Account" temporary)
    begin
    end;
}
