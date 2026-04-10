// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.ReceivablesPayables;

table 5606 "FA Posting Group"
{
    Caption = 'FA Posting Group';
    DrillDownPageID = "FA Posting Groups";
    LookupPageID = "FA Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code for the G/L account that fixed asset expenses and costs are posted to when the fixed asset card contains this code.';
            NotBlank = true;
        }
        field(2; "Acquisition Cost Account"; Code[20])
        {
            Caption = 'Acquisition Cost Account';
            ToolTip = 'Specifies the general ledger account number to post acquisition cost for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Acquisition Cost Account", false);
            end;
        }
        field(3; "Accum. Depreciation Account"; Code[20])
        {
            Caption = 'Accum. Depreciation Account';
            ToolTip = 'Specifies the general ledger account number to post accumulated depreciation to when you post depreciation for fixed assets.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Accum. Depreciation Account", false);
            end;
        }
        field(4; "Write-Down Account"; Code[20])
        {
            Caption = 'Write-Down Account';
            ToolTip = 'Specifies the general ledger account number to post any write-downs for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Write-Down Account", false);
            end;
        }
        field(5; "Appreciation Account"; Code[20])
        {
            Caption = 'Appreciation Account';
            ToolTip = 'Specifies the general ledger account number to post appreciation transactions for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Appreciation Account", false);
            end;
        }
        field(6; "Custom 1 Account"; Code[20])
        {
            Caption = 'Custom 1 Account';
            ToolTip = 'Specifies the general ledger account number to post Custom-1 transactions for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Custom 1 Account", false);
            end;
        }
        field(7; "Custom 2 Account"; Code[20])
        {
            Caption = 'Custom 2 Account';
            ToolTip = 'Specifies the general ledger account number to post Custom-2 transactions for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Custom 2 Account", false);
            end;
        }
        field(8; "Acq. Cost Acc. on Disposal"; Code[20])
        {
            Caption = 'Acq. Cost Acc. on Disposal';
            ToolTip = 'Specifies the general ledger account number to post acquisition cost to when you dispose of fixed assets in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Acq. Cost Acc. on Disposal", false);
            end;
        }
        field(9; "Accum. Depr. Acc. on Disposal"; Code[20])
        {
            Caption = 'Accum. Depr. Acc. on Disposal';
            ToolTip = 'Specifies the general ledger account number to post accumulated depreciation to when you dispose of fixed assets in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Accum. Depr. Acc. on Disposal", false);
            end;
        }
        field(10; "Write-Down Acc. on Disposal"; Code[20])
        {
            Caption = 'Write-Down Acc. on Disposal';
            ToolTip = 'Specifies the general ledger account number to post write-downs of fixed assets to when you dispose of fixed assets in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Write-Down Acc. on Disposal", false);
            end;
        }
        field(11; "Appreciation Acc. on Disposal"; Code[20])
        {
            Caption = 'Appreciation Acc. on Disposal';
            ToolTip = 'Specifies the general ledger account number to post appreciation to when you dispose of fixed assets in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Appreciation Acc. on Disposal", false);
            end;
        }
        field(12; "Custom 1 Account on Disposal"; Code[20])
        {
            Caption = 'Custom 1 Account on Disposal';
            ToolTip = 'Specifies the general ledger account number to post Custom-1 transactions to when you dispose of fixed assets in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Custom 1 Account on Disposal", false);
            end;
        }
        field(13; "Custom 2 Account on Disposal"; Code[20])
        {
            Caption = 'Custom 2 Account on Disposal';
            ToolTip = 'Specifies the general ledger account number to post Custom-2 transactions to when you dispose of fixed assets in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Custom 2 Account on Disposal", false);
            end;
        }
        field(14; "Gains Acc. on Disposal"; Code[20])
        {
            Caption = 'Gains Acc. on Disposal';
            ToolTip = 'Specifies the general ledger account number to post any gains to when you dispose of fixed assets in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Gains Acc. on Disposal", false);
            end;
        }
        field(15; "Losses Acc. on Disposal"; Code[20])
        {
            Caption = 'Losses Acc. on Disposal';
            ToolTip = 'Specifies the general ledger account number to post any losses to when you dispose of fixed assets in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Losses Acc. on Disposal", false);
            end;
        }
        field(16; "Book Val. Acc. on Disp. (Gain)"; Code[20])
        {
            Caption = 'Book Val. Acc. on Disp. (Gain)';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Book Val. Acc. on Disp. (Gain)", false);
            end;
        }
        field(17; "Sales Acc. on Disp. (Gain)"; Code[20])
        {
            Caption = 'Sales Acc. on Disp. (Gain)';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Acc. on Disp. (Gain)", false);
            end;
        }
        field(18; "Write-Down Bal. Acc. on Disp."; Code[20])
        {
            Caption = 'Write-Down Bal. Acc. on Disp.';
            ToolTip = 'Specifies the general ledger balancing account number to post write-downs of fixed assets to when you dispose of fixed assets.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Write-Down Bal. Acc. on Disp.", false);
            end;
        }
        field(19; "Apprec. Bal. Acc. on Disp."; Code[20])
        {
            Caption = 'Apprec. Bal. Acc. on Disp.';
            ToolTip = 'Specifies the general ledger balancing account number to post appreciation transactions of fixed assets to when you dispose of fixed assets.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Apprec. Bal. Acc. on Disp.", false);
            end;
        }
        field(20; "Custom 1 Bal. Acc. on Disposal"; Code[20])
        {
            Caption = 'Custom 1 Bal. Acc. on Disposal';
            ToolTip = 'Specifies the general ledger balancing account number to post custom-1 transactions of fixed assets to when you dispose of fixed assets.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Custom 1 Bal. Acc. on Disposal", false);
            end;
        }
        field(21; "Custom 2 Bal. Acc. on Disposal"; Code[20])
        {
            Caption = 'Custom 2 Bal. Acc. on Disposal';
            ToolTip = 'Specifies the general ledger balancing account number to post custom-2 transactions of fixed assets to when you dispose of fixed assets.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Custom 2 Bal. Acc. on Disposal", false);
            end;
        }
        field(22; "Maintenance Expense Account"; Code[20])
        {
            Caption = 'Maintenance Expense Account';
            ToolTip = 'Specifies the general ledger account number to post maintenance expenses for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Maintenance Expense Account", false);
            end;
        }
        field(23; "Maintenance Bal. Acc."; Code[20])
        {
            Caption = 'Maintenance Bal. Acc.';
            ToolTip = 'Specifies the general ledger balancing account number to post maintenance expenses for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Maintenance Bal. Acc.", true);
            end;
        }
        field(24; "Acquisition Cost Bal. Acc."; Code[20])
        {
            Caption = 'Acquisition Cost Bal. Acc.';
            ToolTip = 'Specifies the general ledger balancing account number to post acquisition cost for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Acquisition Cost Bal. Acc.", true);
            end;
        }
        field(25; "Depreciation Expense Acc."; Code[20])
        {
            Caption = 'Depreciation Expense Acc.';
            ToolTip = 'Specifies the general ledger account number to post depreciation expense for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Depreciation Expense Acc.", true);
            end;
        }
        field(26; "Write-Down Expense Acc."; Code[20])
        {
            Caption = 'Write-Down Expense Acc.';
            ToolTip = 'Specifies the general ledger balancing account number to post write-downs for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Write-Down Expense Acc.", true);
            end;
        }
        field(27; "Appreciation Bal. Account"; Code[20])
        {
            Caption = 'Appreciation Bal. Account';
            ToolTip = 'Specifies the general ledger balancing account number to post appreciation for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Appreciation Bal. Account", true);
            end;
        }
        field(28; "Custom 1 Expense Acc."; Code[20])
        {
            Caption = 'Custom 1 Expense Acc.';
            ToolTip = 'Specifies the general ledger balancing account number to post custom-1 transactions for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Custom 1 Expense Acc.", true);
            end;
        }
        field(29; "Custom 2 Expense Acc."; Code[20])
        {
            Caption = 'Custom 2 Expense Acc.';
            ToolTip = 'Specifies the general ledger balancing account number to post custom-2 transactions for fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Custom 2 Expense Acc.", true);
            end;
        }
        field(30; "Sales Bal. Acc."; Code[20])
        {
            Caption = 'Sales Bal. Acc.';
            ToolTip = 'Specifies the general ledger balancing account to post sales when you dispose of fixed assets to in this posting group.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Bal. Acc.", true);
            end;
        }
        field(31; "Allocated Acquisition Cost %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const(Acquisition)));
            Caption = 'Allocated Acquisition Cost %';
            ToolTip = 'Specifies the total percentage of acquisition cost that can be allocated when acquisition cost is posted.';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Allocated Depreciation %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const(Depreciation)));
            Caption = 'Allocated Depreciation %';
            ToolTip = 'Specifies the total percentage of depreciation that can be allocated when depreciation is posted.';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Allocated Write-Down %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const("Write-Down")));
            Caption = 'Allocated Write-Down %';
            ToolTip = 'Specifies the total percentage for write-down transactions that can be allocated when write-down transactions are posted.';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(34; "Allocated Appreciation %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const(Appreciation)));
            Caption = 'Allocated Appreciation %';
            ToolTip = 'Specifies the total percentage for appreciation transactions that can be allocated when appreciation transactions are posted.';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(35; "Allocated Custom 1 %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const("Custom 1")));
            Caption = 'Allocated Custom 1 %';
            ToolTip = 'Specifies the total percentage for custom-1 transactions that can be allocated when custom-1 transactions are posted.';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(36; "Allocated Custom 2 %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const("Custom 2")));
            Caption = 'Allocated Custom 2 %';
            ToolTip = 'Specifies the total percentage for custom-2 transactions that can be allocated when custom-2 transactions are posted.';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(37; "Allocated Sales Price %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const(Disposal)));
            Caption = 'Allocated Sales Price %';
            ToolTip = 'Specifies the total percentage of sales price that can be allocated when sales are posted.';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(38; "Allocated Maintenance %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const(Maintenance)));
            Caption = 'Allocated Maintenance %';
            ToolTip = 'Specifies the total percentage for maintenance transactions that can be allocated when maintenance transactions are posted.';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(39; "Allocated Gain %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const(Gain)));
            Caption = 'Allocated Gain %';
            ToolTip = 'Specifies the total percentage of gains on fixed assets that can be allocated, when gains are involved in the disposal of fixed assets.';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Allocated Loss %"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const(Loss)));
            Caption = 'Allocated Loss %';
            ToolTip = 'Specifies the total percentage for losses on fixed assets that can be allocated when losses are involved in the disposal of fixed assets.';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(41; "Allocated Book Value % (Gain)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const("Book Value (Gain)")));
            Caption = 'Allocated Book Value % (Gain)';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(42; "Allocated Book Value % (Loss)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("FA Allocation"."Allocation %" where(Code = field(Code),
                                                                    "Allocation Type" = const("Book Value (Loss)")));
            Caption = 'Allocated Book Value % (Loss)';
            DecimalPlaces = 1 : 1;
            Editable = false;
            FieldClass = FlowField;
        }
        field(43; "Sales Acc. on Disp. (Loss)"; Code[20])
        {
            Caption = 'Sales Acc. on Disp. (Loss)';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Sales Acc. on Disp. (Loss)", false);
            end;
        }
        field(44; "Book Val. Acc. on Disp. (Loss)"; Code[20])
        {
            Caption = 'Book Val. Acc. on Disp. (Loss)';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("Book Val. Acc. on Disp. (Loss)", false);
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code")
        {
        }
    }

    trigger OnDelete()
    begin
        FAAlloc.SetRange(Code, Code);
        FAAlloc.DeleteAll(true);
    end;

    var
        FAAlloc: Record "FA Allocation";
        GLAcc: Record "G/L Account";
        PostingSetupMgt: Codeunit PostingSetupManagement;

    procedure CheckGLAcc(AccNo: Code[20]; DirectPosting: Boolean)
    begin
        if AccNo = '' then
            exit;
        GLAcc.Get(AccNo);
        GLAcc.CheckGLAcc();
        OnCheckGLAccOnBeforeTestfieldDirectPosting(Rec, AccNo, DirectPosting);
        if DirectPosting then
            GLAcc.TestField("Direct Posting");

        OnAfterCheckGLAcc(AccNo, DirectPosting, Rec);
    end;

    procedure IsReadyForAcqusition(): Boolean
    begin
        exit("Acquisition Cost Account" <> '');
    end;

    procedure GetAcquisitionCostAccount(): Code[20]
    begin
        if "Acquisition Cost Account" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Acquisition Cost Account"));

        exit("Acquisition Cost Account");
    end;

    procedure GetAcquisitionCostAccountOnDisposal(): Code[20]
    begin
        if "Acq. Cost Acc. on Disposal" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Acq. Cost Acc. on Disposal"));

        exit("Acq. Cost Acc. on Disposal");
    end;

    procedure GetAcquisitionCostBalanceAccount(): Code[20]
    begin
        if "Acquisition Cost Bal. Acc." = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Acquisition Cost Bal. Acc."));

        exit("Acquisition Cost Bal. Acc.");
    end;

    procedure GetAccumDepreciationAccount(): Code[20]
    begin
        if "Accum. Depreciation Account" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Accum. Depreciation Account"));

        exit("Accum. Depreciation Account");
    end;

    procedure GetAccumDepreciationAccountOnDisposal(): Code[20]
    begin
        if "Accum. Depr. Acc. on Disposal" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Accum. Depr. Acc. on Disposal"));

        exit("Accum. Depr. Acc. on Disposal");
    end;

    procedure GetAppreciationAccount(): Code[20]
    begin
        if "Appreciation Account" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Appreciation Account"));

        exit("Appreciation Account");
    end;

    procedure GetAppreciationAccountOnDisposal(): Code[20]
    begin
        if "Appreciation Acc. on Disposal" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Appreciation Acc. on Disposal"));

        exit("Appreciation Acc. on Disposal");
    end;

    procedure GetAppreciationBalanceAccount(): Code[20]
    begin
        if "Appreciation Bal. Account" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Appreciation Bal. Account"));

        exit("Appreciation Bal. Account");
    end;

    procedure GetAppreciationBalAccountOnDisposal(): Code[20]
    begin
        if "Apprec. Bal. Acc. on Disp." = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Apprec. Bal. Acc. on Disp."));

        exit("Apprec. Bal. Acc. on Disp.");
    end;

    procedure GetBookValueAccountOnDisposalGain(): Code[20]
    begin
        if "Book Val. Acc. on Disp. (Gain)" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Book Val. Acc. on Disp. (Gain)"));

        exit("Book Val. Acc. on Disp. (Gain)");
    end;

    procedure GetBookValueAccountOnDisposalLoss(): Code[20]
    begin
        if "Book Val. Acc. on Disp. (Loss)" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Book Val. Acc. on Disp. (Loss)"));

        exit("Book Val. Acc. on Disp. (Loss)");
    end;

    procedure GetCustom1Account(): Code[20]
    begin
        if "Custom 1 Account" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Custom 1 Account"));

        exit("Custom 1 Account");
    end;

    procedure GetCustom2Account(): Code[20]
    begin
        if "Custom 2 Account" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Custom 2 Account"));

        exit("Custom 2 Account");
    end;

    procedure GetCustom1AccountOnDisposal(): Code[20]
    begin
        if "Custom 1 Account on Disposal" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Custom 1 Account on Disposal"));

        exit("Custom 1 Account on Disposal");
    end;

    procedure GetCustom2AccountOnDisposal(): Code[20]
    begin
        if "Custom 2 Account on Disposal" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Custom 2 Account on Disposal"));

        exit("Custom 2 Account on Disposal");
    end;

    procedure GetCustom1BalAccountOnDisposal(): Code[20]
    begin
        if "Custom 1 Bal. Acc. on Disposal" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Custom 1 Bal. Acc. on Disposal"));

        exit("Custom 1 Bal. Acc. on Disposal");
    end;

    procedure GetCustom2BalAccountOnDisposal(): Code[20]
    begin
        if "Custom 2 Bal. Acc. on Disposal" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Custom 2 Bal. Acc. on Disposal"));

        exit("Custom 2 Bal. Acc. on Disposal");
    end;

    procedure GetCustom1ExpenseAccount(): Code[20]
    begin
        if "Custom 1 Expense Acc." = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Custom 1 Expense Acc."));

        exit("Custom 1 Expense Acc.");
    end;

    procedure GetCustom2ExpenseAccount(): Code[20]
    begin
        if "Custom 2 Expense Acc." = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Custom 2 Expense Acc."));

        exit("Custom 2 Expense Acc.");
    end;

    procedure GetDepreciationExpenseAccount(): Code[20]
    begin
        if "Depreciation Expense Acc." = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Depreciation Expense Acc."));

        exit("Depreciation Expense Acc.");
    end;

    procedure GetGainsAccountOnDisposal(): Code[20]
    begin
        if "Gains Acc. on Disposal" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Gains Acc. on Disposal"));

        exit("Gains Acc. on Disposal");
    end;

    procedure GetLossesAccountOnDisposal(): Code[20]
    begin
        if "Losses Acc. on Disposal" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Losses Acc. on Disposal"));

        exit("Losses Acc. on Disposal");
    end;

    procedure GetMaintenanceExpenseAccount(): Code[20]
    begin
        if "Maintenance Expense Account" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Maintenance Expense Account"));

        exit("Maintenance Expense Account");
    end;

    procedure GetMaintenanceBalanceAccount(): Code[20]
    begin
        if "Maintenance Bal. Acc." = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Maintenance Bal. Acc."));

        exit("Maintenance Bal. Acc.");
    end;

    procedure GetSalesBalanceAccount(): Code[20]
    begin
        if "Sales Bal. Acc." = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Sales Bal. Acc."));

        exit("Sales Bal. Acc.");
    end;

    procedure GetSalesAccountOnDisposalGain(): Code[20]
    begin
        if "Sales Acc. on Disp. (Gain)" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Sales Acc. on Disp. (Gain)"));

        exit("Sales Acc. on Disp. (Gain)");
    end;

    procedure GetSalesAccountOnDisposalLoss(): Code[20]
    begin
        if "Sales Acc. on Disp. (Loss)" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Sales Acc. on Disp. (Loss)"));

        exit("Sales Acc. on Disp. (Loss)");
    end;

    procedure GetWriteDownAccount(): Code[20]
    begin
        if "Write-Down Account" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Write-Down Account"));

        exit("Write-Down Account");
    end;

    procedure GetWriteDownAccountOnDisposal(): Code[20]
    begin
        if "Write-Down Acc. on Disposal" = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Write-Down Acc. on Disposal"));

        exit("Write-Down Acc. on Disposal");
    end;

    procedure GetWriteDownBalAccountOnDisposal(): Code[20]
    begin
        if "Write-Down Bal. Acc. on Disp." = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Write-Down Bal. Acc. on Disp."));

        exit("Write-Down Bal. Acc. on Disp.");
    end;

    procedure GetWriteDownExpenseAccount(): Code[20]
    begin
        if "Write-Down Expense Acc." = '' then
            PostingSetupMgt.LogFAPostingGroupFieldError(Rec, FieldNo("Write-Down Expense Acc."));

        exit("Write-Down Expense Acc.");
    end;

    procedure GetPostingGroup(PostingGroupCode: Code[20]; DepreciationBookCode: Code[10]) Result: Boolean
    begin
        Result := Get(PostingGroupCode);

        OnAfterGetPostingGroup(Rec, DepreciationBookCode, Result);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPostingGroup(var FAPostingGroup: Record "FA Posting Group"; DepreciationBookCode: Code[10]; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckGLAccOnBeforeTestfieldDirectPosting(var FAPostingGroup: Record "FA Posting Group"; AccNo: Code[20]; var DirectPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGLAcc(AccNo: Code[20]; DirectPosting: Boolean; FAPostingGroup: Record "FA Posting Group")
    begin
    end;
}

