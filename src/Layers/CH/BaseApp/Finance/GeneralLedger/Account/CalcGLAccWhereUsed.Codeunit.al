// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Bank.BankAccount;
using Microsoft.CashFlow.Setup;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using System.Reflection;
using System.Utilities;

/// <summary>
/// Calculates and displays all setup locations where a general ledger account is referenced or used.
/// Provides comprehensive analysis of account dependencies before deletion or modification operations.
/// </summary>
/// <remarks>
/// Key functions: Account usage analysis, dependency checking, setup reference validation.
/// Scans multiple setup tables including posting groups, journal templates, currency setup, and VAT configuration.
/// Used to prevent deletion of accounts that are actively referenced in system configuration.
/// Provides navigation to setup forms where accounts are used for easy maintenance.
/// </remarks>
codeunit 100 "Calc. G/L Acc. Where-Used"
{

    trigger OnRun()
    begin
    end;

    var
        TempGLAccWhereUsed: Record "G/L Account Where-Used" temporary;
        NextEntryNo: Integer;
#pragma warning disable AA0074
        Text000: Label 'The update has been interrupted to respect the warning.';
#pragma warning restore AA0074
        ShowWhereUsedQst: Label 'You cannot delete a %1 that is used in one or more setup windows.\Do you want to open the G/L Account No. Where-Used List Window?', Comment = '%1 -  Table Caption';

    /// <summary>
    /// Opens the appropriate setup form for the table referenced in the where-used entry.
    /// Navigates directly to the configuration page where the G/L account is being used.
    /// </summary>
    /// <param name="GLAccWhereUsed">Where-used record containing table and key information</param>
    procedure ShowSetupForm(GLAccWhereUsed: Record "G/L Account Where-Used")
    var
        Currency: Record Currency;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        CustPostingGr: Record "Customer Posting Group";
        VendPostingGr: Record "Vendor Posting Group";
        JobPostingGr: Record "Job Posting Group";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        GenPostingSetup: Record "General Posting Setup";
        BankAccPostingGr: Record "Bank Account Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        FAPostingGr: Record "FA Posting Group";
        FAAlloc: Record "FA Allocation";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ICPartner: Record "IC Partner";
        PaymentMethod: Record "Payment Method";
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        case GLAccWhereUsed."Table ID" of
            Database::Currency:
                begin
                    Currency.Code := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(Currency.Code));
                    PAGE.Run(0, Currency);
                end;
            Database::"Gen. Journal Template":
                begin
                    GenJnlTemplate.Name := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(GenJnlTemplate.Name));
                    PAGE.Run(PAGE::"General Journal Templates", GenJnlTemplate);
                end;
            Database::"Gen. Journal Batch":
                begin
                    GenJnlBatch."Journal Template Name" := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(GenJnlBatch."Journal Template Name"));
                    GenJnlBatch.Name := CopyStr(GLAccWhereUsed."Key 2", 1, MaxStrLen(GenJnlBatch.Name));
                    GenJnlBatch.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
                    PAGE.Run(0, GenJnlBatch);
                end;
            Database::"Customer Posting Group":
                begin
                    CustPostingGr.Code := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(CustPostingGr.Code));
                    PAGE.Run(0, CustPostingGr);
                end;
            Database::"Vendor Posting Group":
                begin
                    VendPostingGr.Code := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(VendPostingGr.Code));
                    PAGE.Run(0, VendPostingGr);
                end;
            Database::"Job Posting Group":
                begin
                    JobPostingGr.Code := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(JobPostingGr.Code));
                    PAGE.Run(0, JobPostingGr);
                end;
            Database::"Gen. Jnl. Allocation":
                begin
                    GenJnlAlloc."Journal Template Name" := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(GenJnlAlloc."Journal Template Name"));
                    GenJnlAlloc."Journal Batch Name" := CopyStr(GLAccWhereUsed."Key 2", 1, MaxStrLen(GenJnlAlloc."Journal Batch Name"));
                    Evaluate(GenJnlAlloc."Journal Line No.", GLAccWhereUsed."Key 3");
                    Evaluate(GenJnlAlloc."Line No.", GLAccWhereUsed."Key 4");
                    GenJnlAlloc.SetRange("Journal Template Name", GenJnlAlloc."Journal Template Name");
                    GenJnlAlloc.SetRange("Journal Batch Name", GenJnlAlloc."Journal Batch Name");
                    GenJnlAlloc.SetRange("Journal Line No.", GenJnlAlloc."Journal Line No.");
                    PAGE.Run(PAGE::Allocations, GenJnlAlloc);
                end;
            Database::"General Posting Setup":
                begin
                    GenPostingSetup."Gen. Bus. Posting Group" :=
                      CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(GenPostingSetup."Gen. Bus. Posting Group"));
                    GenPostingSetup."Gen. Prod. Posting Group" :=
                      CopyStr(GLAccWhereUsed."Key 2", 1, MaxStrLen(GenPostingSetup."Gen. Prod. Posting Group"));
                    PAGE.Run(0, GenPostingSetup);
                end;
            Database::"Bank Account Posting Group":
                begin
                    BankAccPostingGr.Code := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(BankAccPostingGr.Code));
                    PAGE.Run(0, BankAccPostingGr);
                end;
            Database::"VAT Posting Setup":
                begin
                    VATPostingSetup."VAT Bus. Posting Group" :=
                      CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(VATPostingSetup."VAT Bus. Posting Group"));
                    VATPostingSetup."VAT Prod. Posting Group" :=
                      CopyStr(GLAccWhereUsed."Key 2", 1, MaxStrLen(VATPostingSetup."VAT Prod. Posting Group"));
                    PAGE.Run(0, VATPostingSetup);
                end;
            Database::"FA Posting Group":
                begin
                    FAPostingGr.Code := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(FAPostingGr.Code));
                    PAGE.Run(PAGE::"FA Posting Group Card", FAPostingGr);
                end;
            Database::"FA Allocation":
                begin
                    FAAlloc.Code := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(FAAlloc.Code));
                    Evaluate(FAAlloc."Allocation Type", GLAccWhereUsed."Key 2");
                    Evaluate(FAAlloc."Line No.", GLAccWhereUsed."Key 3");
                    FAAlloc.SetRange(Code, FAAlloc.Code);
                    FAAlloc.SetRange("Allocation Type", FAAlloc."Allocation Type");
                    OnShowSetupFormOnBeforeFAAllocationRunPage(FAAlloc, GLAccWhereUsed);
                    PAGE.Run(0, FAAlloc);
                end;
            Database::"Inventory Posting Setup":
                begin
                    InventoryPostingSetup."Location Code" := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(InventoryPostingSetup."Location Code"));
                    InventoryPostingSetup."Invt. Posting Group Code" :=
                      CopyStr(GLAccWhereUsed."Key 2", 1, MaxStrLen(InventoryPostingSetup."Invt. Posting Group Code"));
                    PAGE.Run(PAGE::"Inventory Posting Setup", InventoryPostingSetup);
                end;
            Database::"IC Partner":
                begin
                    ICPartner.Code := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(ICPartner.Code));
                    PAGE.Run(0, ICPartner);
                end;
            Database::"Payment Method":
                begin
                    PaymentMethod.Code := CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(PaymentMethod.Code));
                    PAGE.Run(0, PaymentMethod);
                end;
            Database::"Sales & Receivables Setup":
                PAGE.Run(PAGE::"Sales & Receivables Setup");
            Database::"Purchases & Payables Setup":
                PAGE.Run(PAGE::"Purchases & Payables Setup");
            DATABASE::"Vendor Bank Account":
                begin
                    VendorBankAccount."Vendor No." :=
                      CopyStr(GLAccWhereUsed."Key 1", 1, MaxStrLen(VendorBankAccount."Vendor No."));
                    VendorBankAccount.Code :=
                      CopyStr(GLAccWhereUsed."Key 2", 1, MaxStrLen(VendorBankAccount.Code));
                    PAGE.Run(0, VendorBankAccount);
                end;
            else
                OnShowExtensionPage(GLAccWhereUsed);
        end;
    end;

    /// <summary>
    /// Validates if a G/L account can be deleted by checking for usage in setup tables.
    /// Displays where-used information if account is referenced, preventing deletion.
    /// </summary>
    /// <param name="GLAccNo">G/L account number to validate for deletion</param>
    /// <returns>True if account can be deleted, false if validation fails</returns>
    procedure DeleteGLNo(GLAccNo: Code[20]): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        GLAcc: Record "G/L Account";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        GLSetup.Get();
        if GLSetup."Check G/L Account Usage" then begin
            CheckPostingGroups(GLAccNo);
            OnDeleteGLNoOnBeforeTempGLAccWhereUsedFindFirst(TempGLAccWhereUsed);
            if TempGLAccWhereUsed.FindFirst() then begin
                Commit();
                if ConfirmManagement.GetResponse(StrSubstNo(ShowWhereUsedQst, GLAcc.TableCaption()), true) then
                    ShowGLAccWhereUsed();
                Error(Text000);
            end;
        end;
        exit(true);
    end;

    /// <summary>
    /// Analyzes where a G/L account is used and displays the results in the where-used list.
    /// Provides comprehensive analysis of account dependencies across all setup tables.
    /// </summary>
    /// <param name="GLAccNo">G/L account number to analyze for usage</param>
    procedure CheckGLAcc(GLAccNo: Code[20])
    begin
        CheckPostingGroups(GLAccNo);
        ShowGLAccWhereUsed();
    end;

    local procedure ShowGLAccWhereUsed()
    begin
        OnBeforeShowGLAccWhereUsed(TempGLAccWhereUsed);

        TempGLAccWhereUsed.SetCurrentKey("Table Name");
        PAGE.RunModal(0, TempGLAccWhereUsed);
    end;

    /// <summary>
    /// Inserts a where-used entry group for a specific record using table metadata.
    /// Creates standardized entries for account usage tracking with table and field information.
    /// </summary>
    /// <param name="TempGLAccountWhereUsed">Temporary where-used record to populate</param>
    /// <param name="TableID">Database table ID being analyzed</param>
    /// <param name="TableCaption">Display caption for the table</param>
    /// <param name="GLAccNo">G/L account number found in the record</param>
    /// <param name="GLAccNo2">G/L account number to compare against</param>
    /// <param name="FieldCaption">Caption of the field containing the account</param>
    /// <param name="Key">Array of key field names and values for record identification</param>
    procedure InsertGroupForRecord(var TempGLAccountWhereUsed: Record "G/L Account Where-Used" temporary; TableID: Integer; TableCaption: Text[80]; GLAccNo: Code[20]; GLAccNo2: Code[20]; FieldCaption: Text[80]; "Key": array[8] of Text[80])
    begin
        TempGLAccountWhereUsed."Table ID" := TableID;
        TempGLAccountWhereUsed."Table Name" := TableCaption;
        TempGLAccWhereUsed.Copy(TempGLAccountWhereUsed, true);
        InsertGroup(GLAccNo, GLAccNo2, FieldCaption, Key);
    end;

    local procedure InsertGroup(GLAccNo: Code[20]; GLAccNo2: Code[20]; FieldCaption: Text[80]; "Key": array[8] of Text[80])
    begin
        if GLAccNo = GLAccNo2 then begin
            if NextEntryNo = 0 then
                NextEntryNo := TempGLAccWhereUsed.GetLastEntryNo() + 1;

            TempGLAccWhereUsed."Field Name" := FieldCaption;
            if Key[1] <> '' then
                TempGLAccWhereUsed.Line := Key[1] + '=' + Key[4]
            else
                TempGLAccWhereUsed.Line := '';
            if Key[2] <> '' then
                TempGLAccWhereUsed.Line := TempGLAccWhereUsed.Line + ', ' + Key[2] + '=' + Key[5];
            if Key[3] <> '' then
                TempGLAccWhereUsed.Line := TempGLAccWhereUsed.Line + ', ' + Key[3] + '=' + Key[6];
            if Key[7] <> '' then
                TempGLAccWhereUsed.Line := TempGLAccWhereUsed.Line + ', ' + Key[7] + '=' + Key[8];
            TempGLAccWhereUsed."Entry No." := NextEntryNo;
            TempGLAccWhereUsed."Key 1" := CopyStr(Key[4], 1, MaxStrLen(TempGLAccWhereUsed."Key 1"));
            TempGLAccWhereUsed."Key 2" := CopyStr(Key[5], 1, MaxStrLen(TempGLAccWhereUsed."Key 2"));
            TempGLAccWhereUsed."Key 3" := CopyStr(Key[6], 1, MaxStrLen(TempGLAccWhereUsed."Key 3"));
            TempGLAccWhereUsed."Key 4" := CopyStr(Key[8], 1, MaxStrLen(TempGLAccWhereUsed."Key 4"));
            NextEntryNo := NextEntryNo + 1;
            TempGLAccWhereUsed.Insert();
        end;
    end;

    local procedure InsertGroupFromRecRef(var RecRef: RecordRef; FieldCaption: Text[80])
    var
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        KeyFieldCount: Integer;
        FieldCaptionAndValue: Text;
    begin
        if NextEntryNo = 0 then
            NextEntryNo := TempGLAccWhereUsed.GetLastEntryNo() + 1;

        TempGLAccWhereUsed."Entry No." := NextEntryNo;
        TempGLAccWhereUsed."Field Name" := FieldCaption;
        TempGLAccWhereUsed.Line := '';
        KeyRef := RecRef.KeyIndex(1);
        for KeyFieldCount := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(KeyFieldCount);
            FieldCaptionAndValue := StrSubstNo('%1=%2', FieldRef.Caption, FieldRef.Value);
            if TempGLAccWhereUsed.Line = '' then
                TempGLAccWhereUsed.Line := CopyStr(FieldCaptionAndValue, 1, MaxStrLen(TempGLAccWhereUsed.Line))
            else
                TempGLAccWhereUsed.Line :=
                  CopyStr(TempGLAccWhereUsed.Line + ', ' + FieldCaptionAndValue, 1, MaxStrLen(TempGLAccWhereUsed.Line));

            case KeyFieldCount of
                1:
                    TempGLAccWhereUsed."Key 1" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(TempGLAccWhereUsed."Key 1"));
                2:
                    TempGLAccWhereUsed."Key 2" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(TempGLAccWhereUsed."Key 2"));
                3:
                    TempGLAccWhereUsed."Key 3" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(TempGLAccWhereUsed."Key 3"));
                4:
                    TempGLAccWhereUsed."Key 4" := CopyStr(Format(FieldRef.Value), 1, MaxStrLen(TempGLAccWhereUsed."Key 4"));
            end;
        end;
        NextEntryNo := NextEntryNo + 1;
        TempGLAccWhereUsed.Insert();
    end;

    /// <summary>
    /// Performs comprehensive analysis of posting group tables to identify where a G/L account is used.
    /// Scans all relevant setup tables using metadata relationships to build complete usage report.
    /// </summary>
    /// <param name="GLAccNo">G/L account number to analyze for posting group usage</param>
    procedure CheckPostingGroups(GLAccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
        TempTableBuffer: Record "Integer" temporary;
    begin
        NextEntryNo := 0;
        Clear(TempGLAccWhereUsed);
        TempGLAccWhereUsed.DeleteAll();
        GLAcc.Get(GLAccNo);
        TempGLAccWhereUsed."G/L Account No." := GLAccNo;
        TempGLAccWhereUsed."G/L Account Name" := GLAcc.Name;

        if FillTableBuffer(TempTableBuffer) then
            repeat
                CheckTable(GLAccNo, TempTableBuffer.Number);
            until TempTableBuffer.Next() = 0;

        OnAfterCheckPostingGroups(TempGLAccWhereUsed, GLAccNo);
    end;

    local procedure FillTableBuffer(var TableBuffer: Record "Integer"): Boolean
    begin
        AddTable(TableBuffer, Database::Currency);
        AddTable(TableBuffer, Database::"Gen. Journal Template");
        AddTable(TableBuffer, Database::"Gen. Journal Batch");
        AddTable(TableBuffer, Database::"Customer Posting Group");
        AddTable(TableBuffer, Database::"Vendor Posting Group");
        AddTable(TableBuffer, Database::"Job Posting Group");
        AddTable(TableBuffer, Database::"Gen. Jnl. Allocation");
        AddTable(TableBuffer, Database::"General Posting Setup");
        AddTable(TableBuffer, Database::"Bank Account Posting Group");
        AddTable(TableBuffer, Database::"VAT Posting Setup");
        AddTable(TableBuffer, Database::"FA Posting Group");
        AddTable(TableBuffer, Database::"FA Allocation");
        AddTable(TableBuffer, Database::"Inventory Posting Setup");
        AddTable(TableBuffer, Database::"IC Partner");
        AddTable(TableBuffer, Database::"Payment Method");
        AddTable(TableBuffer, Database::"Sales & Receivables Setup");
        AddTable(TableBuffer, Database::"Purchases & Payables Setup");
        AddTable(TableBuffer, Database::"Employee Posting Group");
        AddTable(TableBuffer, Database::"Business Unit");
        AddTable(TableBuffer, Database::"Cash Flow Setup");

        AddCountryTables(TableBuffer);

        OnAfterFillTableBuffer(TableBuffer);

        exit(TableBuffer.FindSet());
    end;

    /// <summary>
    /// Adds a table to the buffer of tables to be checked for G/L account usage.
    /// Prevents duplicate entries when building the list of tables to analyze.
    /// </summary>
    /// <param name="TableBuffer">Integer buffer containing table IDs to check</param>
    /// <param name="TableID">Database table ID to add to the analysis list</param>
    procedure AddTable(var TableBuffer: Record "Integer"; TableID: Integer)
    begin
        if not TableBuffer.Get(TableID) then begin
            TableBuffer.Number := TableID;
            TableBuffer.Insert();
        end;
    end;

    local procedure AddCountryTables(var TableBuffer: Record "Integer")
    begin
        TableBuffer.Reset();
        AddTable(TableBuffer, DATABASE::"Vendor Bank Account");
    end;

    local procedure CheckTable(GLAccNo: Code[20]; TableID: Integer)
    var
        TableRelationsMetadata: Record "Table Relations Metadata";
        "Field": Record "Field";
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        TempGLAccWhereUsed.Init();
        TempGLAccWhereUsed."Table ID" := TableID;
        TempGLAccWhereUsed."Table Name" := RecRef.Caption;

        TableRelationsMetadata.SetRange("Table ID", TableID);
        TableRelationsMetadata.SetRange("Related Table ID", Database::"G/L Account");
        if TableRelationsMetadata.FindSet() then
            repeat
                Field.Get(TableRelationsMetadata."Table ID", TableRelationsMetadata."Field No.");
                if (Field.Class = Field.Class::Normal) and (Field.ObsoleteState <> Field.ObsoleteState::Removed) then
                    CheckField(RecRef, TableRelationsMetadata, GLAccNo);
            until TableRelationsMetadata.Next() = 0;
    end;

    local procedure CheckField(var RecRef: RecordRef; TableRelationsMetadata: Record "Table Relations Metadata"; GLAccNo: Code[20])
    var
        FieldRef: FieldRef;
    begin
        RecRef.Reset();
        FieldRef := RecRef.Field(TableRelationsMetadata."Field No.");
        FieldRef.SetRange(GLAccNo);
        SetConditionFilter(RecRef, TableRelationsMetadata);
        if RecRef.FindSet() then
            repeat
                InsertGroupFromRecRef(RecRef, FieldRef.Caption);
            until RecRef.Next() = 0;
    end;

    local procedure SetConditionFilter(var RecRef: RecordRef; TableRelationsMetadata: Record "Table Relations Metadata")
    var
        FieldRef: FieldRef;
    begin
        if TableRelationsMetadata."Condition Field No." <> 0 then begin
            FieldRef := RecRef.Field(TableRelationsMetadata."Condition Field No.");
            FieldRef.SetFilter(TableRelationsMetadata."Condition Value");
        end;
    end;

    /// <summary>
    /// Integration event raised to allow extensions to handle custom setup page navigation.
    /// Enables custom object types to be included in the where-used analysis with specialized page handling.
    /// </summary>
    /// <param name="GLAccountWhereUsed">Where-used record containing table and key information for custom navigation</param>
    [IntegrationEvent(false, false)]
    local procedure OnShowExtensionPage(GLAccountWhereUsed: Record "G/L Account Where-Used")
    begin
    end;

    /// <summary>
    /// Integration event raised after completing posting group analysis for a G/L account.
    /// Allows extensions to add custom table checks or modify the where-used results before display.
    /// </summary>
    /// <param name="TempGLAccountWhereUsed">Temporary buffer containing all where-used entries found</param>
    /// <param name="GLAccNo">G/L account number that was analyzed</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckPostingGroups(var TempGLAccountWhereUsed: Record "G/L Account Where-Used" temporary; GLAccNo: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event raised after building the list of tables to check for G/L account usage.
    /// Enables extensions to add custom tables to the where-used analysis scope.
    /// </summary>
    /// <param name="TableBuffer">Integer buffer containing table IDs to be analyzed</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFillTableBuffer(var TableBuffer: Record "Integer")
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying the where-used list to the user.
    /// Allows extensions to filter or modify the results before presentation.
    /// </summary>
    /// <param name="GLAccountWhereUsed">Where-used records to be displayed</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowGLAccWhereUsed(var GLAccountWhereUsed: Record "G/L Account Where-Used")
    begin
    end;

    /// <summary>
    /// Integration event raised before opening the FA Allocation page from where-used navigation.
    /// Enables extensions to customize FA allocation page behavior or apply additional filters.
    /// </summary>
    /// <param name="FAAllocation">FA allocation record being navigated to</param>
    /// <param name="GLAccountWhereUsed">Where-used record containing the source reference information</param>
    [IntegrationEvent(false, false)]
    local procedure OnShowSetupFormOnBeforeFAAllocationRunPage(var FAAllocation: Record "FA Allocation"; var GLAccountWhereUsed: Record "G/L Account Where-Used")
    begin
    end;

    /// <summary>
    /// Integration event raised before checking if where-used entries exist during G/L account deletion validation.
    /// Allows extensions to perform custom where-used checks or modify validation logic.
    /// </summary>
    /// <param name="TempGLAccountWhereUsed">Temporary where-used buffer to check for account references</param>
    [IntegrationEvent(false, false)]
    local procedure OnDeleteGLNoOnBeforeTempGLAccWhereUsedFindFirst(var TempGLAccountWhereUsed: Record "G/L Account Where-Used" temporary)
    begin
    end;
}

