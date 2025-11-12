// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using System.Utilities;

table 221 "Gen. Jnl. Allocation"
{
    Caption = 'Gen. Jnl. Allocation';
    Permissions = tabledata "Gen. Jnl. Allocation" = R;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(3; "Journal Line No."; Integer)
        {
            Caption = 'Journal Line No.';
            TableRelation = "Gen. Journal Line"."Line No." where("Journal Template Name" = field("Journal Template Name"),
                                                                  "Journal Batch Name" = field("Journal Batch Name"));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateAccountNo(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if "Account No." = '' then begin
                    GLAcc.Init();
                    CreateDimFromDefaultDim();
                end else begin
                    GLAcc.Get("Account No.");
                    GLAcc.CheckGLAcc();
                    CheckGLAccount(GLAcc);
                end;
                "Account Name" := GLAcc.Name;

                if CopyVATSetupToJnlLines() then begin
                    "Gen. Posting Type" := GLAcc."Gen. Posting Type";
                    "Gen. Bus. Posting Group" := GLAcc."Gen. Bus. Posting Group";
                    "Gen. Prod. Posting Group" := GLAcc."Gen. Prod. Posting Group";
                    "VAT Bus. Posting Group" := GLAcc."VAT Bus. Posting Group";
                    "VAT Prod. Posting Group" := GLAcc."VAT Prod. Posting Group";
                    Validate("VAT Prod. Posting Group");
                end;

                CreateDimFromDefaultDim();
            end;
        }
        field(6; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify();
            end;
        }
        field(7; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify();
            end;
        }
        field(8; "Allocation Quantity"; Decimal)
        {
            Caption = 'Allocation Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                if "Allocation Quantity" = 0 then begin
                    "Allocation %" := 0;
                    Amount := 0;
                end;
                UpdateAllocations(GenJnlLine);
                GenJnlLine.UpdateLineBalance();
            end;
        }
        field(9; "Allocation %"; Decimal)
        {
            Caption = 'Allocation %';
            DecimalPlaces = 2 : 2;
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                "Allocation Quantity" := 0;
                if "Allocation %" = 0 then
                    Amount := 0;
                UpdateAllocations(GenJnlLine);
                GenJnlLine.UpdateLineBalance();
            end;
        }
        field(10; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                if ("Allocation Quantity" <> 0) or ("Allocation %" <> 0) then begin
                    "Allocation Quantity" := 0;
                    "Allocation %" := 0;
                    UpdateAllocations(GenJnlLine);
                end else begin
                    Validate("VAT Prod. Posting Group");
                    Modify();
                    GenJnlLine.UpdateLineBalance();
                    UpdateJnlBalance(GenJnlLine);
                end;
            end;
        }
        field(11; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(12; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        field(13; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        field(14; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        field(15; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            Editable = false;
        }
        field(16; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(17; "Account Name"; Text[100])
        {
            CalcFormula = lookup("G/L Account".Name where("No." = field("Account No.")));
            Caption = 'Account Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(19; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(20; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(21; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(22; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        field(23; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                GenJnlLine.Get("Journal Template Name", "Journal Batch Name", "Journal Line No.");
                CheckVAT(GenJnlLine);
                UpdateVAT(GenJnlLine);
            end;
        }
        field(24; "Additional-Currency Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            Editable = false;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Journal Line No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        Validate(Amount, 0);
    end;

    trigger OnInsert()
    begin
        LockTable();
        GenJnlLine.Get("Journal Template Name", "Journal Batch Name", "Journal Line No.");

        Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
    end;

    var
        GLAcc: Record "G/L Account";
        GenJnlLine: Record "Gen. Journal Line";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        GenProdPostingGrp: Record "Gen. Product Posting Group";
        DimMgt: Codeunit DimensionManagement;
        AllocAccountImportWrongAccTypeErr: Label 'Import from Allocation Account is only allowed for G/L Account Destination account type.';
        ImportDeletesExistingLinesQst: Label 'Importing from Allocation Account will delete all existing allocations. Do you want to continue?';

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cannot be used in allocations when they are completed on the general journal line.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    protected procedure CopyVATSetupToJnlLines(): Boolean
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if ("Journal Template Name" <> '') and ("Journal Batch Name" <> '') then
            if GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                exit(GenJournalBatch."Copy VAT Setup to Jnl. Lines");

        exit(true);
    end;

    procedure UpdateAllocations(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        GenJnlAlloc2: Record "Gen. Jnl. Allocation";
        FromAllocations: Boolean;
        TotalQty: Decimal;
        TotalPct: Decimal;
        TotalPctRnded: Decimal;
        TotalAmountLCY: Decimal;
        TotalAmountLCY2: Decimal;
        TotalAmountLCYRnded: Decimal;
        TotalAmountLCYRnded2: Decimal;
        UpdateGenJnlLine: Boolean;
    begin
        TotalQty := 0;
        TotalPct := 0;
        TotalPctRnded := 0;
        TotalAmountLCYRnded := 0;
        TotalAmountLCYRnded2 := 0;

        if "Line No." <> 0 then begin
            FromAllocations := true;
            GenJnlAlloc.UpdateVAT(GenJnlLine);
            Modify();
            GenJnlLine.Get("Journal Template Name", "Journal Batch Name", "Journal Line No.");
            CheckVAT(GenJnlLine);
        end;

        GenJnlAlloc.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlAlloc.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlAlloc.SetRange("Journal Line No.", GenJnlLine."Line No.");
        if FromAllocations then
            UpdateGenJnlLine := true
        else
            if not GenJnlAlloc.IsEmpty() then begin
                GenJnlAlloc.LockTable();
                UpdateGenJnlLine := true;
            end;

        if GenJnlAlloc.FindSet() then
            repeat
                if (GenJnlAlloc."Allocation Quantity" <> 0) or (GenJnlAlloc."Allocation %" <> 0) then begin
                    if not FromAllocations then
                        GenJnlAlloc.CheckVAT(GenJnlLine);
                    if GenJnlAlloc."Allocation Quantity" = 0 then begin
                        TotalAmountLCY2 := TotalAmountLCY2 - GenJnlLine."Amount (LCY)" * GenJnlAlloc."Allocation %" / 100;
                        GenJnlAlloc.Amount := Round(TotalAmountLCY2) - TotalAmountLCYRnded2;
                        TotalAmountLCYRnded2 := TotalAmountLCYRnded2 + GenJnlAlloc.Amount;
                    end else begin
                        if TotalQty = 0 then begin
                            GenJnlAlloc2.Copy(GenJnlAlloc);
                            GenJnlAlloc2.SetFilter("Allocation Quantity", '<>0');
                            GenJnlAlloc2.CalcSums("Allocation Quantity");
                            TotalQty := GenJnlAlloc2."Allocation Quantity";
                            if TotalQty = 0 then
                                TotalQty := 1;
                        end;
                        TotalPct := TotalPct + GenJnlAlloc."Allocation Quantity" / TotalQty * 100;
                        GenJnlAlloc."Allocation %" := Round(TotalPct, 0.01) - TotalPctRnded;
                        TotalPctRnded := TotalPctRnded + GenJnlAlloc."Allocation %";
                        TotalAmountLCY := TotalAmountLCY - GenJnlLine."Amount (LCY)" * GenJnlAlloc."Allocation Quantity" / TotalQty;
                        GenJnlAlloc.Amount := Round(TotalAmountLCY) - TotalAmountLCYRnded;
                        TotalAmountLCYRnded := TotalAmountLCYRnded + GenJnlAlloc.Amount;
                    end;
                    GenJnlAlloc.UpdateVAT(GenJnlLine);
                    OnUpdateAllocationsOnBeforeGenJnlAllocModify(GenJnlLine, GenJnlAlloc);
                    GenJnlAlloc.Modify();
                    OnUpdateAllocationsOnAfterGenJnlAllocModify(GenJnlAlloc);
                end;
            until GenJnlAlloc.Next() = 0;

        if UpdateGenJnlLine then
            UpdateJnlBalance(GenJnlLine);

        if FromAllocations then
            Find();
    end;

    procedure UpdateAllocationsAddCurr(var GenJnlLine: Record "Gen. Journal Line"; AddCurrAmount: Decimal)
    var
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        GenJnlAlloc2: Record "Gen. Jnl. Allocation";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        TotalQty: Decimal;
        TotalPct: Decimal;
        TotalPctRnded: Decimal;
        TotalAmountAddCurr: Decimal;
        TotalAmountAddCurr2: Decimal;
        TotalAmountAddCurrRnded: Decimal;
        TotalAmountAddCurrRnded2: Decimal;
    begin
        TotalQty := 0;
        TotalPct := 0;
        TotalPctRnded := 0;
        TotalAmountAddCurr := 0;
        TotalAmountAddCurr2 := 0;
        TotalAmountAddCurrRnded := 0;
        TotalAmountAddCurrRnded2 := 0;

        GenJnlAlloc.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlAlloc.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlAlloc.SetRange("Journal Line No.", GenJnlLine."Line No.");
        GenJnlAlloc.LockTable();
        if GenJnlAlloc.FindSet() then begin
            GLSetup.Get();
            Currency.Get(GLSetup."Additional Reporting Currency");
            Currency.TestField("Amount Rounding Precision");
            repeat
                if (GenJnlAlloc."Allocation Quantity" <> 0) or (GenJnlAlloc."Allocation %" <> 0) then begin
                    if GenJnlAlloc."Allocation Quantity" = 0 then begin
                        TotalAmountAddCurr2 :=
                          TotalAmountAddCurr2 - AddCurrAmount * GenJnlAlloc."Allocation %" / 100;
                        GenJnlAlloc."Additional-Currency Amount" :=
                          Round(TotalAmountAddCurr2, Currency."Amount Rounding Precision") -
                          TotalAmountAddCurrRnded2;
                        TotalAmountAddCurrRnded2 :=
                          TotalAmountAddCurrRnded2 + GenJnlAlloc."Additional-Currency Amount";
                    end else begin
                        if TotalQty = 0 then begin
                            GenJnlAlloc2.Copy(GenJnlAlloc);
                            GenJnlAlloc2.SetFilter("Allocation Quantity", '<>0');
                            repeat
                                TotalQty := TotalQty + GenJnlAlloc2."Allocation Quantity";
                            until GenJnlAlloc2.Next() = 0;
                            if TotalQty = 0 then
                                TotalQty := 1;
                        end;
                        TotalPct := TotalPct + GenJnlAlloc."Allocation Quantity" / TotalQty * 100;
                        GenJnlAlloc."Allocation %" := Round(TotalPct, 0.01) - TotalPctRnded;
                        TotalPctRnded := TotalPctRnded + GenJnlAlloc."Allocation %";
                        TotalAmountAddCurr :=
                          TotalAmountAddCurr -
                          AddCurrAmount * GenJnlAlloc."Allocation Quantity" / TotalQty;
                        GenJnlAlloc."Additional-Currency Amount" :=
                          Round(TotalAmountAddCurr, Currency."Amount Rounding Precision") -
                          TotalAmountAddCurrRnded;
                        TotalAmountAddCurrRnded :=
                          TotalAmountAddCurrRnded + GenJnlAlloc."Additional-Currency Amount";
                    end;
                    GenJnlAlloc.Modify();
                    OnUpdateAllocationsAddCurrOnAfterGenJnlAllocModify(GenJnlAlloc);
                end;
            until GenJnlAlloc.Next() = 0;
        end;
    end;

    local procedure UpdateJnlBalance(var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.CalcFields("Allocated Amt. (LCY)");
        if GenJnlLine."Bal. Account No." = '' then
            GenJnlLine."Balance (LCY)" := GenJnlLine."Amount (LCY)" + GenJnlLine."Allocated Amt. (LCY)"
        else
            GenJnlLine."Balance (LCY)" := GenJnlLine."Allocated Amt. (LCY)";
        GenJnlLine.Modify();
    end;

    procedure CheckVAT(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if ("Gen. Posting Type" <> "Gen. Posting Type"::" ") and (GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" ") then
            Error(
              Text000,
              GenJnlLine.FieldCaption("Gen. Posting Type"));
    end;

    procedure UpdateVAT(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlLine2: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateVAT(GenJnlLine, IsHandled, Rec);
        if not IsHandled then begin
            GenJnlLine2.CopyFromGenJnlAllocation(Rec);
            GenJnlLine2."Posting Date" := GenJnlLine."Posting Date";
            GenJnlLine2.Validate("VAT Prod. Posting Group");
            Amount := GenJnlLine2."Amount (LCY)";
            "VAT Calculation Type" := GenJnlLine2."VAT Calculation Type";
            "VAT Amount" := GenJnlLine2."VAT Amount";
            "VAT %" := GenJnlLine2."VAT %";
        end;
        OnAfterUpdateVAT(GenJnlLine, GenJnlLine2, Rec);
    end;

    procedure GetCurrencyCode(): Code[10]
    var
        GenJnlLine3: Record "Gen. Journal Line";
    begin
        GenJnlLine3.SetRange("Journal Template Name", "Journal Template Name");
        GenJnlLine3.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJnlLine3.SetRange("Line No.", "Journal Line No.");
        if GenJnlLine3.FindFirst() then
            exit(GenJnlLine3."Currency Code");

        exit('');
    end;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if GLSetup.Get() then
            exit(GLSetup."Additional Reporting Currency");
        exit('');
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
        OldDimSetID: Integer;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, IsHandled);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        OldDimSetID := Rec."Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(Rec, CurrFieldNo, DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDimProcedure(Rec, CurrFieldNo, DefaultDimSource, xRec, OldDimSetID);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(Rec, "Dimension Set ID",
            StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Journal Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec, xRec);
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", Rec."Account No.");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    internal procedure ChooseAndImportFromAllocationAccount()
    var
        AllocationAccount: Record "Allocation Account";
    begin
        if ChooseAllocationAccount(AllocationAccount) then
            ImportFromAllocationAccount(AllocationAccount);
    end;

    local procedure ChooseAllocationAccount(var AllocationAccount: Record "Allocation Account") AccountChosen: Boolean
    var
        AllocationAccountList: Page "Allocation Account List";
    begin
        AllocationAccount.SetRange("Account Type", AllocationAccount."Account Type"::Fixed);
        AllocationAccountList.SetTableView(AllocationAccount);
        AllocationAccountList.LookupMode(true);
        if AllocationAccountList.RunModal() = Action::LookupOK then begin
            AccountChosen := true;
            AllocationAccountList.GetRecord(AllocationAccount);
        end;
    end;

    local procedure ImportFromAllocationAccount(AllocationAccount: Record "Allocation Account")
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
        ConfirmManagement: Codeunit "Confirm Management";
        NextLineNo: Integer;
    begin
        if not Rec.IsEmpty() then
            if not ConfirmManagement.GetResponse(ImportDeletesExistingLinesQst) then
                exit;

        Rec.DeleteAll();

        AllocationAccount.TestField("Account Type", AllocationAccount."Account Type"::Fixed);
        AllocAccountDistribution.SetRange("Allocation Account No.", AllocationAccount."No.");
        NextLineNo := 10000;
        CheckAccountType(AllocAccountDistribution);
        if AllocAccountDistribution.FindSet() then
            repeat
                Rec.Init();
                Rec."Line No." := NextLineNo;
                Rec.Insert();
                NextLineNo += 10000;
                CopyFieldsFromAllocationAccountDistribution(AllocAccountDistribution);
            until AllocAccountDistribution.Next() = 0;
    end;

    local procedure CheckAccountType(var AllocAccountDistribution: Record "Alloc. Account Distribution")
    begin
        AllocAccountDistribution.SetFilter("Destination Account Type", '<>%1', AllocAccountDistribution."Destination Account Type"::"G/L Account");
        if not AllocAccountDistribution.IsEmpty() then
            Error(AllocAccountImportWrongAccTypeErr);
        AllocAccountDistribution.SetRange("Destination Account Type");
    end;

    local procedure CopyFieldsFromAllocationAccountDistribution(AllocAccountDistribution: Record "Alloc. Account Distribution")
    begin
        Rec.Validate("Account No.", AllocAccountDistribution."Destination Account Number");
        Rec.Validate("Allocation %", AllocAccountDistribution.Percent);
        Rec.Validate("Shortcut Dimension 1 Code", AllocAccountDistribution."Global Dimension 1 Code");
        Rec.Validate("Shortcut Dimension 2 Code", AllocAccountDistribution."Global Dimension 2 Code");
        Rec.Validate("Dimension Set ID", AllocAccountDistribution."Dimension Set ID");
        Rec.Modify(true);
    end;

    local procedure CheckGLAccount(var GLAccount: Record "G/L Account")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccount(GLAccount, IsHandled, Rec);
        if IsHandled then
            exit;

        GLAccount.TestField("Direct Posting", true);

        OnAfterCheckGLAccount(GLAccount, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimProcedure(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; CurrFieldNo: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; xGenJnlAllocation: Record "Gen. Jnl. Allocation"; OldDimSetID: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; xGenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var xGenJnlAllocation: Record "Gen. Jnl. Allocation"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var xGenJnlAllocation: Record "Gen. Jnl. Allocation"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllocationsOnAfterGenJnlAllocModify(var GenJnlAlloc: Record "Gen. Jnl. Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllocationsOnBeforeGenJnlAllocModify(GenJournalLine: Record "Gen. Journal Line"; var GenJnlAlloc: Record "Gen. Jnl. Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllocationsAddCurrOnAfterGenJnlAllocModify(var GenJnlAlloc: Record "Gen. Jnl. Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccount(GLAccount: Record "G/L Account"; var IsHandled: Boolean; var GenJnlAllocation: Record "Gen. Jnl. Allocation");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAccount(var GLAccount: Record "G/L Account"; GenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVAT(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; var GenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVAT(var GenJournalLine: Record "Gen. Journal Line"; GenJournalLine2: Record "Gen. Journal Line"; var GenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAccountNo(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; xGenJnlAllocation: Record "Gen. Jnl. Allocation"; var IsHandled: Boolean)
    begin
    end;
}
