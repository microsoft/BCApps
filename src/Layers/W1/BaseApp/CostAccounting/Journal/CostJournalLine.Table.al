// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Journal;

using Microsoft.CostAccounting.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Finance.GeneralLedger.Setup;

table 1101 "Cost Journal Line"
{
    Caption = 'Cost Journal Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Cost Journal Template";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Cost Type No."; Code[20])
        {
            Caption = 'Cost Type No.';
            TableRelation = "Cost Type";

            trigger OnValidate()
            begin
                if CostType.Get("Cost Type No.") then begin
                    CostType.TestField(Blocked, false);
                    CostType.TestField(Type, CostType.Type::"Cost Type");
                    "Cost Center Code" := CostType."Cost Center Code";
                    "Cost Object Code" := CostType."Cost Object Code";
                    Description := CostType.Name;
                end;

                CalcBalance();
            end;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Cost Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(11; "Bal. Cost Type No."; Code[20])
        {
            Caption = 'Bal. Cost Type No.';
            TableRelation = "Cost Type";

            trigger OnValidate()
            begin
                if CostType.Get("Bal. Cost Type No.") then begin
                    CostType.TestField(Blocked, false);
                    CostType.TestField(Type, CostType.Type::"Cost Type");
                    "Bal. Cost Center Code" := CostType."Cost Center Code";
                    "Bal. Cost Object Code" := CostType."Cost Object Code";
                end;

                CalcBalance();
            end;
        }
        field(16; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';

            trigger OnValidate()
            begin
                CalcBalance();
                UpdateDebitCreditAmounts();
            end;
        }
        field(17; Balance; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Balance';
            Editable = false;
        }
        field(18; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Debit Amount';

            trigger OnValidate()
            begin
                Validate(Amount, "Debit Amount");
            end;
        }
        field(19; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Credit Amount';

            trigger OnValidate()
            begin
                Validate(Amount, -"Credit Amount");
            end;
        }
        field(20; "Cost Center Code"; Code[20])
        {
            Caption = 'Cost Center Code';
            TableRelation = "Cost Center";

            trigger OnValidate()
            begin
                CheckCostCenter("Cost Center Code");
            end;
        }
        field(21; "Cost Object Code"; Code[20])
        {
            Caption = 'Cost Object Code';
            TableRelation = "Cost Object";

            trigger OnValidate()
            begin
                CheckCostObject("Cost Object Code");
            end;
        }
        field(22; "Bal. Cost Center Code"; Code[20])
        {
            Caption = 'Bal. Cost Center Code';
            TableRelation = "Cost Center";

            trigger OnValidate()
            begin
                CheckCostCenter("Bal. Cost Center Code");
            end;
        }
        field(23; "Bal. Cost Object Code"; Code[20])
        {
            Caption = 'Bal. Cost Object Code';
            TableRelation = "Cost Object";

            trigger OnValidate()
            begin
                CheckCostObject("Bal. Cost Object Code");
            end;
        }
        field(27; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(29; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            Editable = false;
            TableRelation = "G/L Entry";
        }
        field(30; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(31; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            Editable = false;
        }
        field(32; "Cost Entry No."; Integer)
        {
            Caption = 'Cost Entry No.';
            Editable = false;
        }
        field(33; Allocated; Boolean)
        {
            Caption = 'Allocated';
        }
        field(50; "Allocation Description"; Text[80])
        {
            Caption = 'Allocation Description';
        }
        field(51; "Allocation ID"; Code[10])
        {
            Caption = 'Allocation ID';
        }
        field(68; "Additional-Currency Amount"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Additional-Currency Amount';
            Editable = false;
        }
        field(69; "Add.-Currency Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Debit Amount';
            Editable = false;
        }
        field(70; "Add.-Currency Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Add.-Currency Credit Amount';
            Editable = false;
        }
        field(100; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Cost Type No.", "Cost Center Code", "Cost Object Code")
        {
        }
        key(Key3; "G/L Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        LockTable();
        CostJournalTemplate.Get("Journal Template Name");
        CostJournalBatch.Get("Journal Template Name", "Journal Batch Name");
        "Reason Code" := CostJournalBatch."Reason Code";

        if "Source Code" = '' then begin
            SourceCodeSetup.Get();
            "Source Code" := SourceCodeSetup."Cost Journal";
        end;
    end;

    trigger OnModify()
    begin
        "System-Created Entry" := false;
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        CostType: Record "Cost Type";
        CostJournalBatch: Record "Cost Journal Batch";
        CostJournalTemplate: Record "Cost Journal Template";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Line Type must be %1 or Begin-Total in %2 %3.', Comment = '%2 = Cost Center or Cost Object; %3 = Cost Center or Cost Object Code';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CalcBalance()
    begin
        case true of
            ("Cost Type No." <> '') and ("Bal. Cost Type No." <> ''):
                Balance := 0;
            "Bal. Cost Type No." <> '':
                Balance := -Amount;
            else
                Balance := Amount;
        end;
    end;

    local procedure CheckCostCenter(CostCenterCode: Code[20])
    var
        CostCenter: Record "Cost Center";
    begin
        if CostCenter.Get(CostCenterCode) then begin
            if not (CostCenter."Line Type" in [CostCenter."Line Type"::"Cost Center", CostCenter."Line Type"::"Begin-Total"]) then
                Error(Text000, CostCenter."Line Type"::"Cost Center", CostCenter.TableCaption(), CostCenter.Code);
            CostCenter.TestField(Blocked, false);
        end;
    end;

    local procedure CheckCostObject(CostObjectCode: Code[20])
    var
        CostObject: Record "Cost Object";
    begin
        if CostObject.Get(CostObjectCode) then begin
            if not (CostObject."Line Type" in [CostObject."Line Type"::"Cost Object", CostObject."Line Type"::"Begin-Total"]) then
                Error(Text000, CostObject."Line Type"::"Cost Object", CostObject.TableCaption(), CostObject.Code);
            CostObject.TestField(Blocked, false);
        end;
    end;

    procedure SetUpNewLine(LastCostJournalLine: Record "Cost Journal Line")
    var
        CostJournalLine: Record "Cost Journal Line";
    begin
        CostJournalTemplate.Get("Journal Template Name");
        CostJournalBatch.Get("Journal Template Name", "Journal Batch Name");
        CostJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        CostJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        if CostJournalLine.FindFirst() then begin
            "Posting Date" := LastCostJournalLine."Posting Date";
            "Document No." := LastCostJournalLine."Document No.";
        end else
            "Posting Date" := WorkDate();

        "Source Code" := CostJournalTemplate."Source Code";
        "Reason Code" := CostJournalBatch."Reason Code";
        "Bal. Cost Type No." := CostJournalBatch."Bal. Cost Type No.";
        "Bal. Cost Center Code" := CostJournalBatch."Bal. Cost Center Code";
        "Bal. Cost Object Code" := CostJournalBatch."Bal. Cost Object Code";

        OnAfterSetUpNewLine(Rec, CostJournalTemplate, CostJournalBatch, LastCostJournalLine);
    end;

    procedure EmptyLine(): Boolean
    begin
        exit(Amount = 0);
    end;

    local procedure UpdateDebitCreditAmounts()
    begin
        case true of
            Amount > 0:
                begin
                    "Debit Amount" := Amount;
                    "Credit Amount" := 0;
                end;
            Amount < 0:
                begin
                    "Debit Amount" := 0;
                    "Credit Amount" := -Amount;
                end;
            Amount = 0:
                begin
                    "Debit Amount" := 0;
                    "Credit Amount" := 0;
                end;
        end;
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        CostJournalBatch: Record "Cost Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                CostJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            CostJournalBatch.SetFilter(Name, BatchFilter);
            CostJournalBatch.FindFirst();
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var CostJournalLine: Record "Cost Journal Line"; CostJournalTemplate: Record "Cost Journal Template"; CostJournalBatch: Record "Cost Journal Batch"; LastCostJournalLine: Record "Cost Journal Line")
    begin
    end;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Additional Reporting Currency");
    end;
}
