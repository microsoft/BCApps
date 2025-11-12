// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;

table 5813 "Inventory Posting Setup"
{
    Caption = 'Inventory Posting Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Inventory Posting Setup";
    LookupPageID = "Inventory Posting Setup";

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(2; "Invt. Posting Group Code"; Code[20])
        {
            Caption = 'Invt. Posting Group Code';
            NotBlank = true;
            TableRelation = "Inventory Posting Group";
        }
        field(6; "Inventory Account"; Code[20])
        {
            Caption = 'Inventory Account';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Inventory Account")
                else
                    LookupGLAccount(
                      "Inventory Account", GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetInventory());

                Validate("Inventory Account");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Inventory Account", false, false)
                else
                    CheckGLAccount(
                      FieldNo("Inventory Account"), "Inventory Account", false, false, GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetInventory());
            end;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(21; "View All Accounts on Lookup"; Boolean)
        {
            Caption = 'View All Accounts on Lookup';
        }
        field(5800; "Inventory Account (Interim)"; Code[20])
        {
            Caption = 'Inventory Account (Interim)';
            TableRelation = "G/L Account";

            trigger OnLookup()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.LookupGLAccountWithoutCategory("Inventory Account (Interim)")
                else
                    LookupGLAccount(
                      "Inventory Account (Interim)", GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetInventory());

                Validate("Inventory Account (Interim)");
            end;

            trigger OnValidate()
            begin
                if "View All Accounts on Lookup" then
                    GLAccountCategoryMgt.CheckGLAccountWithoutCategory("Inventory Account (Interim)", false, false)
                else
                    CheckGLAccount(
                      FieldNo("Inventory Account (Interim)"), "Inventory Account (Interim)", false, false, GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetInventory());
            end;
        }
        field(99000750; "WIP Account"; Code[20])
        {
            Caption = 'WIP Account';
            TableRelation = "G/L Account";
        }
        field(99000753; "Material Variance Account"; Code[20])
        {
            Caption = 'Material Variance Account';
            TableRelation = "G/L Account";
        }
        field(99000754; "Capacity Variance Account"; Code[20])
        {
            Caption = 'Capacity Variance Account';
            TableRelation = "G/L Account";
        }
        field(99000755; "Mfg. Overhead Variance Account"; Code[20])
        {
            Caption = 'Mfg. Overhead Variance Account';
            TableRelation = "G/L Account";
        }
        field(99000756; "Cap. Overhead Variance Account"; Code[20])
        {
            Caption = 'Cap. Overhead Variance Account';
            TableRelation = "G/L Account";
        }
        field(99000757; "Subcontracted Variance Account"; Code[20])
        {
            Caption = 'Subcontracted Variance Account';
            TableRelation = "G/L Account";
        }
        field(99000758; "Mat. Non-Inv. Variance Acc."; Code[20])
        {
            Caption = 'Material Non-Inventory Variance Account';
            ToolTip = 'Specifies the general ledger account number to which to post material non-inventory variance transactions for items in this combination.';
            TableRelation = "G/L Account";
        }
    }

    keys
    {
        key(Key1; "Location Code", "Invt. Posting Group Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckSetupUsage();
    end;

    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        AccountSuggested: Boolean;

        YouCannotDeleteErr: Label 'You cannot delete %1 %2.', Comment = '%1 = Location Code; %2 = Posting Group';
        NoAccountSuggestedMsg: Label 'Cannot suggest G/L accounts as there is nothing to base suggestion on.';

    protected var
        PostingSetupMgt: Codeunit PostingSetupManagement;

    local procedure CheckSetupUsage()
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Location Code", "Location Code");
        ValueEntry.SetRange("Inventory Posting Group", "Invt. Posting Group Code");
        if not ValueEntry.IsEmpty() then
            Error(YouCannotDeleteErr, "Location Code", "Invt. Posting Group Code");
    end;

    procedure GetInventoryAccount(): Code[20]
    begin
        if "Inventory Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Inventory Account"));

        exit("Inventory Account");
    end;

    procedure GetInventoryAccountInterim(): Code[20]
    begin
        if "Inventory Account (Interim)" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Inventory Account (Interim)"));

        exit("Inventory Account (Interim)");
    end;

    procedure GetCapacityVarianceAccount(): Code[20]
    begin
        if "Capacity Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Capacity Variance Account"));

        exit("Capacity Variance Account");
    end;

    procedure GetCapOverheadVarianceAccount(): Code[20]
    begin
        if "Cap. Overhead Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Cap. Overhead Variance Account"));

        exit("Cap. Overhead Variance Account");
    end;

    procedure GetMaterialVarianceAccount(): Code[20]
    begin
        if "Material Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Material Variance Account"));

        exit("Material Variance Account");
    end;

    procedure GetMaterialNonInventoryVarianceAccount(): Code[20]
    begin
        if "Mat. Non-Inv. Variance Acc." = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Mat. Non-Inv. Variance Acc."));

        exit("Mat. Non-Inv. Variance Acc.");
    end;

    procedure GetMfgOverheadVarianceAccount(): Code[20]
    begin
        if "Mfg. Overhead Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Mfg. Overhead Variance Account"));

        exit("Mfg. Overhead Variance Account");
    end;

    procedure GetSubcontractedVarianceAccount(): Code[20]
    begin
        if "Subcontracted Variance Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("Subcontracted Variance Account"));

        exit("Subcontracted Variance Account");
    end;

    procedure GetWIPAccount(): Code[20]
    begin
        if "WIP Account" = '' then
            PostingSetupMgt.LogInventoryPostingSetupFieldError(Rec, FieldNo("WIP Account"));

        exit("WIP Account");
    end;

    procedure SuggestSetupAccounts()
    var
        RecRef: RecordRef;
    begin
        AccountSuggested := false;
        RecRef.GetTable(Rec);
        if "Inventory Account" = '' then
            SuggestAccount(RecRef, FieldNo("Inventory Account"));
        if "Inventory Account" = '' then
            SuggestAccount(RecRef, FieldNo("Inventory Account (Interim)"));
        OnAfterSuggestSetupAccount(Rec, RecRef);
        if AccountSuggested then
            RecRef.Modify()
        else
            Message(NoAccountSuggestedMsg);
    end;

    procedure SuggestAccount(var RecRef: RecordRef; AccountFieldNo: Integer)
    var
        TempAccountUseBuffer: Record "Account Use Buffer" temporary;
        RecFieldRef: FieldRef;
        InvtPostingSetupRecRef: RecordRef;
        InvtPostingSetupFieldRef: FieldRef;
    begin
        InvtPostingSetupRecRef.Open(DATABASE::"Inventory Posting Setup");

        InvtPostingSetupRecRef.Reset();
        InvtPostingSetupFieldRef := InvtPostingSetupRecRef.Field(FieldNo("Invt. Posting Group Code"));
        InvtPostingSetupFieldRef.SetRange("Invt. Posting Group Code", "Invt. Posting Group Code");
        InvtPostingSetupFieldRef := InvtPostingSetupRecRef.Field(FieldNo("Location Code"));
        InvtPostingSetupFieldRef.SetFilter('<>%1', "Location Code");
        TempAccountUseBuffer.UpdateBuffer(InvtPostingSetupRecRef, AccountFieldNo);

        InvtPostingSetupRecRef.Close();

        TempAccountUseBuffer.Reset();
        TempAccountUseBuffer.SetCurrentKey("No. of Use");
        if TempAccountUseBuffer.FindLast() then begin
            RecFieldRef := RecRef.Field(AccountFieldNo);
            RecFieldRef.Value(TempAccountUseBuffer."Account No.");
            AccountSuggested := true;
        end;
    end;

    local procedure CheckGLAccount(ChangedFieldNo: Integer; AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; AccountCategory: Option; AccountSubcategory: Text)
    begin
        GLAccountCategoryMgt.CheckGLAccount(Database::"Inventory Posting Group", ChangedFieldNo, AccNo, CheckProdPostingGroup, CheckDirectPosting, AccountCategory, AccountSubcategory);
    end;

    local procedure LookupGLAccount(var AccountNo: Code[20]; AccountCategory: Option; AccountSubcategoryFilter: Text)
    begin
        GLAccountCategoryMgt.LookupGLAccount(Database::"Inventory Posting Setup", CurrFieldNo, AccountNo, AccountCategory, AccountSubcategoryFilter);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSuggestSetupAccount(var InventoryPostingSetup: Record "Inventory Posting Setup"; RecRef: RecordRef)
    begin
    end;
}

