namespace Microsoft.Sustainability.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Sustainability.Account;

table 6261 "Sust. G/L - Sust. Ledger Rel."
{
    Caption = 'G/L - Sustainability Entry Relation';
    DataClassification = CustomerContent;
    DataPerCompany = true;
    DrillDownPageId = "Sust. G/L - Sust. Ledger Rel.";
    LookupPageId = "Sust. G/L - Sust. Ledger Rel.";
    Extensible = true;
    Permissions = tabledata "G/L Entry" = rm;

    fields
    {
        field(1; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            TableRelation = "G/L Entry";
            Editable = false;
        }
        field(2; "Sust. Ledger Entry No."; Integer)
        {
            Caption = 'Sustainability Ledger Entry No.';
            TableRelation = "Sustainability Ledger Entry";
            Editable = false;
        }
        field(3; "Account Category"; Code[20])
        {
            Caption = 'Account Category';
            TableRelation = "Sustain. Account Category";
            Editable = false;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(5; "Collected Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Collected Amount';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "G/L Entry No.", "Sust. Ledger Entry No.")
        {
            Clustered = true;
        }
        key(SustLedgerEntryNo; "Sust. Ledger Entry No.")
        {
        }
        key(AccountCategory; "Account Category", "G/L Entry No.")
        {
        }
    }

    internal procedure CreateRelation(GLEntry: Record "G/L Entry"; SustLedgerEntryNo: Integer; AccountCategoryCode: Code[20])
    var
        SustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
    begin
        if SustGLSustLedgerRel.Get(GLEntry."Entry No.", SustLedgerEntryNo) then
            exit;

        SustGLSustLedgerRel.Init();
        SustGLSustLedgerRel."G/L Entry No." := GLEntry."Entry No.";
        SustGLSustLedgerRel."Sust. Ledger Entry No." := SustLedgerEntryNo;
        SustGLSustLedgerRel."Account Category" := AccountCategoryCode;
        SustGLSustLedgerRel."Posting Date" := GLEntry."Posting Date";
        SustGLSustLedgerRel."Collected Amount" := GLEntry.Amount;
        SustGLSustLedgerRel.Insert(true);

        SetGLEntryCollected(GLEntry."Entry No.", true);
    end;

    internal procedure RemoveRelations(SustLedgerEntryNo: Integer)
    var
        SustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
        RemainingSustGLSustLedgerRel: Record "Sust. G/L - Sust. Ledger Rel.";
        GLEntryNo: Integer;
    begin
        SustGLSustLedgerRel.SetCurrentKey("Sust. Ledger Entry No.");
        SustGLSustLedgerRel.SetRange("Sust. Ledger Entry No.", SustLedgerEntryNo);
        if not SustGLSustLedgerRel.FindSet() then
            exit;

        repeat
            GLEntryNo := SustGLSustLedgerRel."G/L Entry No.";

            RemainingSustGLSustLedgerRel.SetRange("G/L Entry No.", GLEntryNo);
            RemainingSustGLSustLedgerRel.SetFilter("Sust. Ledger Entry No.", '<>%1', SustLedgerEntryNo);
            if RemainingSustGLSustLedgerRel.IsEmpty() then
                SetGLEntryCollected(GLEntryNo, false);
        until SustGLSustLedgerRel.Next() = 0;

        SustGLSustLedgerRel.DeleteAll(true);
    end;

    local procedure SetGLEntryCollected(GLEntryNo: Integer; Collected: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        if not GLEntry.Get(GLEntryNo) then
            exit;

        if GLEntry."Sust. Collected" = Collected then
            exit;

        GLEntry."Sust. Collected" := Collected;
        GLEntry.Modify();
    end;
}
