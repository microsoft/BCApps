namespace Microsoft.Sustainability.Journal;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Sustainability.Account;

table 6260 "Sust. Jnl. Line G/L Entry"
{
    Caption = 'Sustainability Journal Line G/L Entry';
    DataClassification = CustomerContent;
    DataPerCompany = true;
    Extensible = true;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Sustainability Jnl. Template";
            Editable = false;
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Sustainability Jnl. Batch".Name where("Journal Template Name" = field("Journal Template Name"));
            Editable = false;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(4; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            TableRelation = "G/L Entry";
            Editable = false;
        }
        field(5; "Account Category"; Code[20])
        {
            Caption = 'Account Category';
            TableRelation = "Sustain. Account Category";
            Editable = false;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(7; "Collected Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Collected Amount';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Journal Template Name", "Journal Batch Name", "Line No.", "G/L Entry No.")
        {
            Clustered = true;
        }
        key(AccountCategory; "Account Category", "G/L Entry No.")
        {
        }
    }

    internal procedure SetJournalLineFilter(SustainabilityJnlLine: Record "Sustainability Jnl. Line")
    begin
        Rec.SetRange("Journal Template Name", SustainabilityJnlLine."Journal Template Name");
        Rec.SetRange("Journal Batch Name", SustainabilityJnlLine."Journal Batch Name");
        Rec.SetRange("Line No.", SustainabilityJnlLine."Line No.");
    end;

    internal procedure BelongsToJournalLine(SustainabilityJnlLine: Record "Sustainability Jnl. Line"): Boolean
    begin
        exit(
            (Rec."Journal Template Name" = SustainabilityJnlLine."Journal Template Name") and
            (Rec."Journal Batch Name" = SustainabilityJnlLine."Journal Batch Name") and
            (Rec."Line No." = SustainabilityJnlLine."Line No."));
    end;

    internal procedure StoreCollectedGLEntries(SustainabilityJnlLine: Record "Sustainability Jnl. Line"; var GLEntry: Record "G/L Entry")
    var
        SustJnlLineGLEntry: Record "Sust. Jnl. Line G/L Entry";
    begin
        DeleteCollectedGLEntries(SustainabilityJnlLine);

        if not GLEntry.FindSet() then
            exit;

        repeat
            SustJnlLineGLEntry.Init();
            SustJnlLineGLEntry."Journal Template Name" := SustainabilityJnlLine."Journal Template Name";
            SustJnlLineGLEntry."Journal Batch Name" := SustainabilityJnlLine."Journal Batch Name";
            SustJnlLineGLEntry."Line No." := SustainabilityJnlLine."Line No.";
            SustJnlLineGLEntry."G/L Entry No." := GLEntry."Entry No.";
            SustJnlLineGLEntry."Account Category" := SustainabilityJnlLine."Account Category";
            SustJnlLineGLEntry."Posting Date" := GLEntry."Posting Date";
            SustJnlLineGLEntry."Collected Amount" := GLEntry.Amount;
            SustJnlLineGLEntry.Insert();
        until GLEntry.Next() = 0;
    end;

    internal procedure DeleteCollectedGLEntries(SustainabilityJnlLine: Record "Sustainability Jnl. Line")
    var
        SustJnlLineGLEntry: Record "Sust. Jnl. Line G/L Entry";
    begin
        SustJnlLineGLEntry.SetJournalLineFilter(SustainabilityJnlLine);
        SustJnlLineGLEntry.DeleteAll();
    end;

    internal procedure MoveCollectedGLEntries(FromSustainabilityJnlLine: Record "Sustainability Jnl. Line"; ToSustainabilityJnlLine: Record "Sustainability Jnl. Line")
    var
        SustJnlLineGLEntry: Record "Sust. Jnl. Line G/L Entry";
        MovedSustJnlLineGLEntry: Record "Sust. Jnl. Line G/L Entry";
    begin
        SustJnlLineGLEntry.SetJournalLineFilter(FromSustainabilityJnlLine);
        if not SustJnlLineGLEntry.FindSet() then
            exit;

        repeat
            MovedSustJnlLineGLEntry := SustJnlLineGLEntry;
            MovedSustJnlLineGLEntry."Journal Template Name" := ToSustainabilityJnlLine."Journal Template Name";
            MovedSustJnlLineGLEntry."Journal Batch Name" := ToSustainabilityJnlLine."Journal Batch Name";
            MovedSustJnlLineGLEntry."Line No." := ToSustainabilityJnlLine."Line No.";
            MovedSustJnlLineGLEntry.Insert();
        until SustJnlLineGLEntry.Next() = 0;

        SustJnlLineGLEntry.DeleteAll();
    end;
}
