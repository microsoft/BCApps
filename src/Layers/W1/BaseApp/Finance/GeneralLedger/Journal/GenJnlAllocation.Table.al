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

/// <summary>
/// Table for storing allocation lines that distribute general journal line amounts across multiple G/L accounts.
/// Enables splitting journal line amounts using percentages, amounts, or quantities for cost allocation and distribution.
/// </summary>
/// <remarks>
/// Core allocation functionality for general journal lines enabling multi-account distribution.
/// Supports percentage-based, amount-based, and quantity-based allocation methods.
/// Key fields: Account No., Allocation %, Amount, VAT handling for proper tax distribution.
/// Integration: Links to parent journal line via template, batch, and line number references.
/// </remarks>
table 221 "Gen. Jnl. Allocation"
{
    Caption = 'Gen. Jnl. Allocation';
    Permissions = tabledata "Gen. Jnl. Allocation" = R;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Journal template name that defines the type and behavior of the journal containing this allocation line.
        /// </summary>
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Journal batch name that groups related journal lines for this allocation.
        /// </summary>
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        /// <summary>
        /// Line number of the parent general journal line to which this allocation applies.
        /// </summary>
        field(3; "Journal Line No."; Integer)
        {
            Caption = 'Journal Line No.';
            TableRelation = "Gen. Journal Line"."Line No." where("Journal Template Name" = field("Journal Template Name"),
                                                                  "Journal Batch Name" = field("Journal Batch Name"));
        }
        /// <summary>
        /// Sequential line number for this allocation entry within the parent journal line.
        /// </summary>
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// G/L account number to which the allocated amount will be posted.
        /// </summary>
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            ToolTip = 'Specifies the account number that the allocation will be posted to.';
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
        /// <summary>
        /// First shortcut dimension code for this allocation line, typically used for department or project classification.
        /// </summary>
        field(6; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify();
            end;
        }
        /// <summary>
        /// Second shortcut dimension code for this allocation line, typically used for cost center or area classification.
        /// </summary>
        field(7; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify();
            end;
        }
        /// <summary>
        /// Allocation quantity used for quantity-based distribution of journal line amounts.
        /// When specified, amounts are distributed proportionally based on quantities rather than percentages.
        /// </summary>
        field(8; "Allocation Quantity"; Decimal)
        {
            Caption = 'Allocation Quantity';
            ToolTip = 'Specifies the quantity that will be used to calculate the amount in the allocation journal line.';
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
        /// <summary>
        /// Percentage of the parent journal line amount to allocate to this account.
        /// Used for percentage-based distribution where total percentages across allocation lines should equal 100%.
        /// </summary>
        field(9; "Allocation %"; Decimal)
        {
            Caption = 'Allocation %';
            ToolTip = 'Specifies the percentage that will be used to calculate the amount in the allocation journal line.';
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
        /// <summary>
        /// Fixed allocation amount to be posted to this account.
        /// Used for amount-based distribution where specific amounts are allocated rather than percentages or quantities.
        /// </summary>
        field(10; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the amount that will be posted from the allocation journal line.';

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
        /// <summary>
        /// General posting type that determines how this allocation line affects general ledger posting.
        /// Controls whether the allocation creates purchase, sale, or other general ledger entries.
        /// </summary>
        field(11; "Gen. Posting Type"; Enum "General Posting Type")
        {
            Caption = 'Gen. Posting Type';
            ToolTip = 'Specifies the type of transaction.';

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// General business posting group used for determining posting accounts and VAT treatment for this allocation line.
        /// Links to general posting setup for proper account determination during posting.
        /// </summary>
        field(12; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Bus. Posting Group" <> "Gen. Bus. Posting Group" then
                    if GenBusPostingGrp.ValidateVatBusPostingGroup(GenBusPostingGrp, "Gen. Bus. Posting Group") then
                        Validate("VAT Bus. Posting Group", GenBusPostingGrp."Def. VAT Bus. Posting Group");
            end;
        }
        /// <summary>
        /// General product posting group used for determining posting accounts and VAT treatment for this allocation line.
        /// Links to general posting setup for proper account determination during posting.
        /// </summary>
        field(13; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                if xRec."Gen. Prod. Posting Group" <> "Gen. Prod. Posting Group" then
                    if GenProdPostingGrp.ValidateVatProdPostingGroup(GenProdPostingGrp, "Gen. Prod. Posting Group") then
                        Validate("VAT Prod. Posting Group", GenProdPostingGrp."Def. VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// VAT calculation method used for this allocation line to determine VAT amount computation.
        /// </summary>
        field(14; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            Caption = 'VAT Calculation Type';
            Editable = false;
        }
        /// <summary>
        /// VAT amount calculated for this allocation line based on the allocation amount and VAT percentage.
        /// </summary>
        field(15; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            Editable = false;
        }
        /// <summary>
        /// VAT percentage rate applied to this allocation line for VAT amount calculation.
        /// </summary>
        field(16; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
            AutoFormatType = 0;
        }
        /// <summary>
        /// Name of the G/L account specified for this allocation line, automatically populated when Account No. is selected.
        /// </summary>
        field(17; "Account Name"; Text[100])
        {
            CalcFormula = lookup("G/L Account".Name where("No." = field("Account No.")));
            Caption = 'Account Name';
            ToolTip = 'Specifies the name of the account that the allocation will be posted to.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Tax area code for sales tax calculation when tax functionality is enabled for this allocation line.
        /// </summary>
        field(18; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// Indicates whether this allocation line is subject to sales tax liability when tax functionality is enabled.
        /// </summary>
        field(19; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// Tax group code for sales tax calculation when tax functionality is enabled for this allocation line.
        /// </summary>
        field(20; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// Indicates whether this allocation line uses reverse charge VAT (use tax) when tax functionality is enabled.
        /// </summary>
        field(21; "Use Tax"; Boolean)
        {
            Caption = 'Use Tax';

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// VAT business posting group code for VAT calculation setup applicable to this allocation line.
        /// </summary>
        field(22; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                Validate("VAT Prod. Posting Group");
            end;
        }
        /// <summary>
        /// VAT product posting group code for VAT calculation setup applicable to this allocation line.
        /// </summary>
        field(23; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                GenJnlLine.Get("Journal Template Name", "Journal Batch Name", "Journal Line No.");
                CheckVAT(GenJnlLine);
                UpdateVAT(GenJnlLine);
            end;
        }
        /// <summary>
        /// Allocation amount expressed in the additional reporting currency when ACY functionality is enabled.
        /// </summary>
        field(24; "Additional-Currency Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            Editable = false;
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
        }
        /// <summary>
        /// Unique identifier for the dimension set associated with this allocation line for financial analysis and reporting.
        /// </summary>
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

    /// <summary>
    /// Updates allocation amounts and distributions for all allocation lines associated with the specified journal line.
    /// Recalculates allocation percentages and amounts to ensure total allocation equals journal line amount.
    /// </summary>
    /// <param name="GenJnlLine">General journal line record for which allocations should be updated.</param>
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

    /// <summary>
    /// Updates allocation amounts in additional reporting currency for all allocation lines associated with the specified journal line.
    /// Converts allocation amounts to additional currency using current exchange rates.
    /// </summary>
    /// <param name="GenJnlLine">General journal line record for which additional currency allocations should be updated.</param>
    /// <param name="AddCurrAmount">Total additional currency amount to distribute across allocation lines.</param>
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

    /// <summary>
    /// Validates VAT setup and calculations for this allocation line based on the associated journal line context.
    /// Ensures VAT posting groups and calculation types are compatible with journal line requirements.
    /// </summary>
    /// <param name="GenJnlLine">General journal line record providing VAT validation context for this allocation.</param>
    procedure CheckVAT(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if ("Gen. Posting Type" <> "Gen. Posting Type"::" ") and (GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" ") then
            Error(
              Text000,
              GenJnlLine.FieldCaption("Gen. Posting Type"));
    end;

    /// <summary>
    /// Updates VAT amounts and percentages for this allocation line based on current VAT setup and allocation amount.
    /// Calculates VAT amount using VAT posting group configuration and allocation base amount.
    /// </summary>
    /// <param name="GenJnlLine">General journal line record providing VAT calculation context for this allocation.</param>
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

    /// <summary>
    /// Retrieves the currency code applicable to this allocation line based on the associated journal line.
    /// Returns the journal line's currency code or LCY if no specific currency is defined.
    /// </summary>
    /// <returns>Currency code for this allocation line's amounts and VAT calculations.</returns>
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

    /// <summary>
    /// Creates dimension set for this allocation line from the specified default dimension sources.
    /// Builds dimension combinations for financial analysis and reporting requirements.
    /// </summary>
    /// <param name="DefaultDimSource">List of default dimension sources to use for dimension set creation.</param>
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

    /// <summary>
    /// Validates shortcut dimension code for the specified dimension and updates the allocation line's dimension set.
    /// Ensures dimension values are valid and updates the dimension set ID accordingly.
    /// </summary>
    /// <param name="FieldNumber">Field number indicating which shortcut dimension is being validated.</param>
    /// <param name="ShortcutDimCode">Shortcut dimension code value to validate and assign.</param>
    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    /// <summary>
    /// Opens lookup for shortcut dimension code selection and updates the allocation line's dimension set.
    /// Provides user interface for selecting valid dimension values for the specified dimension.
    /// </summary>
    /// <param name="FieldNumber">Field number indicating which shortcut dimension lookup should be opened.</param>
    /// <param name="ShortcutDimCode">Current shortcut dimension code value, updated with user selection.</param>
    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    /// <summary>
    /// Retrieves and displays shortcut dimension codes for this allocation line in the provided array.
    /// Populates shortcut dimension code array with current dimension values for display purposes.
    /// </summary>
    /// <param name="ShortcutDimCode">Array to populate with current shortcut dimension codes from this allocation.</param>
    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// Opens the dimensions page to display and allow editing of all dimensions for this allocation line.
    /// Provides comprehensive dimension management interface for detailed financial analysis setup.
    /// </summary>
    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(Rec, "Dimension Set ID",
            StrSubstNo('%1 %2 %3', "Journal Template Name", "Journal Batch Name", "Journal Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec, xRec);
    end;

    /// <summary>
    /// Creates dimension set for this allocation line from default dimension setup for the G/L account.
    /// Automatically applies standard dimension configuration based on account and posting group defaults.
    /// </summary>
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

    /// <summary>
    /// Integration event raised after initializing default dimension sources for allocation line dimension creation.
    /// Enables custom modification of dimension sources before dimension set creation for allocation lines.
    /// </summary>
    /// <param name="GenJnlAllocation">General journal allocation record for which dimension sources are being initialized.</param>
    /// <param name="DefaultDimSource">List of default dimension sources that can be modified for custom dimension logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    /// <summary>
    /// Integration event raised before creating dimension set for allocation line.
    /// Enables custom logic to completely override standard dimension creation processing for allocations.
    /// </summary>
    /// <param name="GenJnlAllocation">General journal allocation record for which dimensions are being created.</param>
    /// <param name="IsHandled">Set to true to skip standard dimension creation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised after completing dimension creation procedure for allocation line.
    /// Enables custom processing and validation after standard dimension set creation is completed.
    /// </summary>
    /// <param name="GenJnlAllocation">General journal allocation record for which dimensions were created.</param>
    /// <param name="CurrFieldNo">Field number that triggered the dimension creation process.</param>
    /// <param name="DefaultDimSource">List of default dimension sources used in dimension creation.</param>
    /// <param name="xGenJnlAllocation">Previous version of allocation record before dimension changes.</param>
    /// <param name="OldDimSetID">Previous dimension set ID before changes were applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimProcedure(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; CurrFieldNo: Integer; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; xGenJnlAllocation: Record "Gen. Jnl. Allocation"; OldDimSetID: Integer);
    begin
    end;

    /// <summary>
    /// Integration event raised after displaying dimensions page for allocation line.
    /// Enables custom processing after user interaction with allocation line dimensions.
    /// </summary>
    /// <param name="GenJnlAllocation">General journal allocation record for which dimensions were displayed.</param>
    /// <param name="xGenJnlAllocation">Previous version of allocation record before dimension display interaction.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; xGenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    /// <summary>
    /// Integration event raised after validating shortcut dimension code for allocation line.
    /// Enables custom processing after shortcut dimension validation and dimension set updates.
    /// </summary>
    /// <param name="GenJnlAllocation">General journal allocation record for which shortcut dimension was validated.</param>
    /// <param name="xGenJnlAllocation">Previous version of allocation record before shortcut dimension validation.</param>
    /// <param name="FieldNumber">Field number indicating which shortcut dimension was validated.</param>
    /// <param name="ShortcutDimCode">Shortcut dimension code value that was validated and applied.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var xGenJnlAllocation: Record "Gen. Jnl. Allocation"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event raised before validating shortcut dimension code for allocation line.
    /// Enables custom logic to override standard shortcut dimension validation processing.
    /// </summary>
    /// <param name="GenJnlAllocation">General journal allocation record for which shortcut dimension is being validated.</param>
    /// <param name="xGenJnlAllocation">Previous version of allocation record before shortcut dimension validation.</param>
    /// <param name="FieldNumber">Field number indicating which shortcut dimension is being validated.</param>
    /// <param name="ShortcutDimCode">Shortcut dimension code value being validated (can be modified).</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; var xGenJnlAllocation: Record "Gen. Jnl. Allocation"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event that occurs after modifying a general journal allocation line during update process.
    /// Allows customization of allocation line processing after standard modification logic.
    /// </summary>
    /// <param name="GenJnlAlloc">The general journal allocation record that was modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllocationsOnAfterGenJnlAllocModify(var GenJnlAlloc: Record "Gen. Jnl. Allocation")
    begin
    end;

    /// <summary>
    /// Integration event that occurs before modifying a general journal allocation line during update process.
    /// Allows customization of allocation line values before standard modification logic.
    /// </summary>
    /// <param name="GenJournalLine">The source general journal line being processed.</param>
    /// <param name="GenJnlAlloc">The general journal allocation record being modified.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllocationsOnBeforeGenJnlAllocModify(GenJournalLine: Record "Gen. Journal Line"; var GenJnlAlloc: Record "Gen. Jnl. Allocation")
    begin
    end;

    /// <summary>
    /// Integration event raised after modifying allocation line during additional currency allocation updates.
    /// Enables custom processing after allocation line changes during ACY amount distribution.
    /// </summary>
    /// <param name="GenJnlAlloc">General journal allocation record that was modified during ACY update process.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateAllocationsAddCurrOnAfterGenJnlAllocModify(var GenJnlAlloc: Record "Gen. Jnl. Allocation")
    begin
    end;

    /// <summary>
    /// Integration event raised before validating G/L account setup for allocation line.
    /// Enables custom logic to override standard G/L account validation processing for allocations.
    /// </summary>
    /// <param name="GLAccount">G/L Account record being validated for allocation line usage.</param>
    /// <param name="IsHandled">Set to true to skip standard G/L account validation logic.</param>
    /// <param name="GenJnlAllocation">General journal allocation record providing context for G/L account validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccount(GLAccount: Record "G/L Account"; var IsHandled: Boolean; var GenJnlAllocation: Record "Gen. Jnl. Allocation");
    begin
    end;

    /// <summary>
    /// Integration event raised after validating G/L account setup for allocation line.
    /// Enables custom processing and validation after standard G/L account checks are completed.
    /// </summary>
    /// <param name="GLAccount">G/L Account record that was validated for allocation line usage.</param>
    /// <param name="GenJnlAllocation">General journal allocation record providing context for G/L account validation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAccount(var GLAccount: Record "G/L Account"; GenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    /// <summary>
    /// Integration event raised before updating VAT amounts for allocation line.
    /// Enables custom logic to completely override standard VAT update processing for allocations.
    /// </summary>
    /// <param name="GenJournalLine">General journal line record providing VAT update context.</param>
    /// <param name="IsHandled">Set to true to skip standard VAT update logic.</param>
    /// <param name="GenJnlAllocation">General journal allocation record for which VAT is being updated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateVAT(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean; var GenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    /// <summary>
    /// Integration event raised after updating VAT amounts for allocation line.
    /// Enables custom processing after standard VAT calculation and update is completed.
    /// </summary>
    /// <param name="GenJournalLine">General journal line record that provided VAT update context.</param>
    /// <param name="GenJournalLine2">Additional journal line record used during VAT update process.</param>
    /// <param name="GenJnlAllocation">General journal allocation record for which VAT was updated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateVAT(var GenJournalLine: Record "Gen. Journal Line"; GenJournalLine2: Record "Gen. Journal Line"; var GenJnlAllocation: Record "Gen. Jnl. Allocation")
    begin
    end;

    /// <summary>
    /// Integration event raised before validating account number for allocation line.
    /// Enables custom logic to completely override standard account number validation processing.
    /// </summary>
    /// <param name="GenJnlAllocation">General journal allocation record for which account number is being validated.</param>
    /// <param name="xGenJnlAllocation">Previous version of allocation record before account number validation.</param>
    /// <param name="IsHandled">Set to true to skip standard account number validation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAccountNo(var GenJnlAllocation: Record "Gen. Jnl. Allocation"; xGenJnlAllocation: Record "Gen. Jnl. Allocation"; var IsHandled: Boolean)
    begin
    end;
}
