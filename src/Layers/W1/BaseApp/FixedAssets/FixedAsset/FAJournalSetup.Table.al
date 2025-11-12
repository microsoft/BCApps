// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Insurance;
using Microsoft.Foundation.NoSeries;
using System.Security.AccessControl;
using System.Security.User;

table 5605 "FA Journal Setup"
{
    Caption = 'FA Journal Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "FA Journal Setup";
    LookupPageID = "FA Journal Setup";

    fields
    {
        field(1; "Depreciation Book Code"; Code[10])
        {
            Caption = 'Depreciation Book Code';
            NotBlank = true;
            TableRelation = "Depreciation Book";
        }
        field(2; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(3; "FA Jnl. Template Name"; Code[10])
        {
            Caption = 'FA Jnl. Template Name';
            Editable = true;
            TableRelation = "FA Journal Template";

            trigger OnValidate()
            begin
                "FA Jnl. Batch Name" := '';
            end;
        }
        field(4; "FA Jnl. Batch Name"; Code[10])
        {
            Caption = 'FA Jnl. Batch Name';
            TableRelation = "FA Journal Batch".Name where("Journal Template Name" = field("FA Jnl. Template Name"));
        }
        field(5; "Gen. Jnl. Template Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Template Name';
            TableRelation = "Gen. Journal Template";

            trigger OnValidate()
            begin
                "Gen. Jnl. Batch Name" := '';
            end;
        }
        field(6; "Gen. Jnl. Batch Name"; Code[10])
        {
            Caption = 'Gen. Jnl. Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Gen. Jnl. Template Name"));
        }
        field(7; "Insurance Jnl. Template Name"; Code[10])
        {
            Caption = 'Insurance Jnl. Template Name';
            TableRelation = "Insurance Journal Template";

            trigger OnValidate()
            begin
                "Insurance Jnl. Batch Name" := '';
            end;
        }
        field(8; "Insurance Jnl. Batch Name"; Code[10])
        {
            Caption = 'Insurance Jnl. Batch Name';
            TableRelation = "Insurance Journal Batch".Name where("Journal Template Name" = field("Insurance Jnl. Template Name"));
        }
    }

    keys
    {
        key(Key1; "Depreciation Book Code", "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        DeprBook.LockTable();
        DeprBook.Get("Depreciation Book Code");
    end;

    var
        DeprBook: Record "Depreciation Book";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must specify %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure GenJnlName(var DeprBook: Record "Depreciation Book"; var GenJnlLine: Record "Gen. Journal Line"; var NextLineNo: Integer)
    var
        FAJnlSetup: Record "FA Journal Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        FAGetJnl: Codeunit "FA Get Journal";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        if not FAJnlSetup.Get(DeprBook.Code, UserId) then
            FAJnlSetup.Get(DeprBook.Code, '');
        FAJnlSetup.TestField("Gen. Jnl. Template Name");
        FAJnlSetup.TestField("Gen. Jnl. Batch Name");
        TemplateName := FAJnlSetup."Gen. Jnl. Template Name";
        BatchName := FAJnlSetup."Gen. Jnl. Batch Name";
        OnGenJnlNameOnBeforeGenJnlTemplateGet(DeprBook, GenJnlLine, NextLineNo, TemplateName, BatchName);
        GenJnlTemplate.Get(TemplateName);
        GenJnlBatch.Get(TemplateName, BatchName);
        FAGetJnl.SetGenJnlRange(GenJnlLine, TemplateName, BatchName);
        NextLineNo := GenJnlLine."Line No.";
    end;

    procedure FAJnlName(var DeprBook: Record "Depreciation Book"; var FAJnlLine: Record "FA Journal Line"; var NextLineNo: Integer)
    var
        FAJnlSetup: Record "FA Journal Setup";
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
        FAGetJnl: Codeunit "FA Get Journal";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        if not FAJnlSetup.Get(DeprBook.Code, UserId) then
            FAJnlSetup.Get(DeprBook.Code, '');
        FAJnlSetup.TestField("FA Jnl. Template Name");
        FAJnlSetup.TestField("FA Jnl. Batch Name");
        TemplateName := FAJnlSetup."FA Jnl. Template Name";
        BatchName := FAJnlSetup."FA Jnl. Batch Name";
        OnFAJnlNameOnBeforeFAJnlTemplateGet(DeprBook, FAJnlLine, NextLineNo, TemplateName, BatchName);
        FAJnlTemplate.Get(TemplateName);
        FAJnlBatch.Get(TemplateName, BatchName);
        FAGetJnl.SetFAJnlRange(FAJnlLine, TemplateName, BatchName);
        NextLineNo := FAJnlLine."Line No.";
    end;

    procedure InsuranceJnlName(var DeprBook: Record "Depreciation Book"; var InsuranceJnlLine: Record "Insurance Journal Line"; var NextLineNo: Integer)
    var
        FAJnlSetup: Record "FA Journal Setup";
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlBatch: Record "Insurance Journal Batch";
        FAGetJnl: Codeunit "FA Get Journal";
        TemplateName: Code[10];
        BatchName: Code[10];
    begin
        if not FAJnlSetup.Get(DeprBook.Code, UserId) then
            FAJnlSetup.Get(DeprBook.Code, '');
        FAJnlSetup.TestField("Insurance Jnl. Template Name");
        FAJnlSetup.TestField("Insurance Jnl. Batch Name");
        TemplateName := FAJnlSetup."Insurance Jnl. Template Name";
        BatchName := FAJnlSetup."Insurance Jnl. Batch Name";
        InsuranceJnlTempl.Get(TemplateName);
        InsuranceJnlBatch.Get(TemplateName, BatchName);
        FAGetJnl.SetInsuranceJnlRange(InsuranceJnlLine, TemplateName, BatchName);
        NextLineNo := InsuranceJnlLine."Line No.";
    end;

    procedure SetGenJnlTrailCodes(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        IsHandled: Boolean;
    begin
        OnBeforeSetGenJnlTrailCodes(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        GenJnlLine."Source Code" := GenJnlTemplate."Source Code";
        GenJnlLine."Reason Code" := GenJnlBatch."Reason Code";
        GenJnlBatch.TestField("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        GenJnlBatch.TestField("Bal. Account No.", '');
    end;

    procedure GetFAJnlDocumentNo(var FAJnlLine: Record "FA Journal Line"; PostingDate: Date; CreateError: Boolean): Code[20]
    var
        FAJnlBatch: Record "FA Journal Batch";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetFAJnlDocumentNo(FAJnlLine, IsHandled);
        if IsHandled then
            exit;

        FAJnlBatch.Get(FAJnlLine."Journal Template Name", FAJnlLine."Journal Batch Name");
        if (FAJnlBatch."No. Series" <> '') and not FAJnlLine.Find('=><') then
            DocumentNo := NoSeries.PeekNextNo(FAJnlBatch."No. Series", PostingDate);
        if (DocumentNo = '') and CreateError then
            Error(Text000, FAJnlLine.FieldCaption("Document No."));
        exit(DocumentNo);
    end;

    procedure GetGenJnlDocumentNo(var GenJnlLine: Record "Gen. Journal Line"; PostingDate: Date; CreateError: Boolean): Code[20]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetGenJnlDocumentNo(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        if (GenJnlBatch."No. Series" <> '') and not GenJnlLine.Find('=><') then
            DocumentNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", PostingDate);
        if (DocumentNo = '') and CreateError then
            Error(Text000, GenJnlLine.FieldCaption("Document No."));
        exit(DocumentNo);
    end;

    procedure GetInsuranceJnlDocumentNo(var InsuranceJnlLine: Record "Insurance Journal Line"; PostingDate: Date): Code[20]
    var
        InsuranceJnlBatch: Record "Insurance Journal Batch";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        InsuranceJnlBatch.Get(InsuranceJnlLine."Journal Template Name", InsuranceJnlLine."Journal Batch Name");
        if (InsuranceJnlBatch."No. Series" <> '') and not InsuranceJnlLine.Find('=><') then
            DocumentNo := NoSeries.PeekNextNo(InsuranceJnlBatch."No. Series", PostingDate);
        if DocumentNo = '' then
            Error(Text000, InsuranceJnlLine.FieldCaption("Document No."));
        exit(DocumentNo);
    end;

    procedure GetFANoSeries(var FAJnlLine: Record "FA Journal Line"): Code[20]
    var
        FAJnlBatch: Record "FA Journal Batch";
    begin
        FAJnlBatch.Get(FAJnlLine."Journal Template Name", FAJnlLine."Journal Batch Name");
        if FAJnlBatch."No. Series" <> FAJnlBatch."Posting No. Series" then
            exit(FAJnlBatch."Posting No. Series");
        exit('');
    end;

    procedure GetGenNoSeries(var GenJnlLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
        if GenJnlBatch."No. Series" <> GenJnlBatch."Posting No. Series" then
            exit(GenJnlBatch."Posting No. Series");
        exit('');
    end;

    procedure GetInsuranceNoSeries(var InsuranceJnlLine: Record "Insurance Journal Line"): Code[20]
    var
        InsuranceJnlBatch: Record "Insurance Journal Batch";
    begin
        InsuranceJnlBatch.Get(InsuranceJnlLine."Journal Template Name", InsuranceJnlLine."Journal Batch Name");
        if InsuranceJnlBatch."No. Series" <> InsuranceJnlBatch."Posting No. Series" then
            exit(InsuranceJnlBatch."Posting No. Series");
        exit('');
    end;

    procedure SetFAJnlTrailCodes(var FAJnlLine: Record "FA Journal Line")
    var
        FAJnlTemplate: Record "FA Journal Template";
        FAJnlBatch: Record "FA Journal Batch";
        IsHandled: Boolean;
    begin
        OnBeforeSetFAJnlTrailCodes(FAJnlLine, IsHandled);
        if IsHandled then
            exit;

        FAJnlTemplate.Get(FAJnlLine."Journal Template Name");
        FAJnlBatch.Get(FAJnlLine."Journal Template Name", FAJnlLine."Journal Batch Name");
        FAJnlLine."Source Code" := FAJnlTemplate."Source Code";
        FAJnlLine."Reason Code" := FAJnlBatch."Reason Code";
    end;

    procedure SetInsuranceJnlTrailCodes(var InsuranceJnlLine: Record "Insurance Journal Line")
    var
        InsuranceJnlTempl: Record "Insurance Journal Template";
        InsuranceJnlBatch: Record "Insurance Journal Batch";
    begin
        InsuranceJnlTempl.Get(InsuranceJnlLine."Journal Template Name");
        InsuranceJnlBatch.Get(InsuranceJnlLine."Journal Template Name", InsuranceJnlLine."Journal Batch Name");
        InsuranceJnlLine."Source Code" := InsuranceJnlTempl."Source Code";
        InsuranceJnlLine."Reason Code" := InsuranceJnlBatch."Reason Code";
    end;

    procedure IncFAJnlBatchName(var FAJnlBatch: Record "FA Journal Batch")
    var
        FAJnlSetup: Record "FA Journal Setup";
    begin
        if FAJnlSetup.Find('-') then
            repeat
                if (FAJnlSetup."FA Jnl. Template Name" = FAJnlBatch."Journal Template Name") and
                   (FAJnlSetup."FA Jnl. Batch Name" = FAJnlBatch.Name)
                then begin
                    FAJnlSetup."FA Jnl. Batch Name" := IncStr(FAJnlSetup."FA Jnl. Batch Name");
                    FAJnlSetup.Modify();
                end;
            until FAJnlSetup.Next() = 0;
        OnAfterIncFAJnlBatchName(FAJnlBatch);
    end;

    procedure IncGenJnlBatchName(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        FAJnlSetup: Record "FA Journal Setup";
    begin
        if FAJnlSetup.Find('-') then
            repeat
                if (FAJnlSetup."Gen. Jnl. Template Name" = GenJnlBatch."Journal Template Name") and
                   (FAJnlSetup."Gen. Jnl. Batch Name" = GenJnlBatch.Name)
                then begin
                    FAJnlSetup."Gen. Jnl. Batch Name" := IncStr(FAJnlSetup."Gen. Jnl. Batch Name");
                    FAJnlSetup.Modify();
                end;
            until FAJnlSetup.Next() = 0;
        OnAfterIncGenJnlBatchName(GenJnlBatch);
    end;

    procedure IncInsuranceJnlBatchName(var InsuranceJnlBatch: Record "Insurance Journal Batch")
    var
        FAJnlSetup: Record "FA Journal Setup";
    begin
        if FAJnlSetup.Find('-') then
            repeat
                if (FAJnlSetup."Insurance Jnl. Template Name" = InsuranceJnlBatch."Journal Template Name") and
                   (FAJnlSetup."Insurance Jnl. Batch Name" = InsuranceJnlBatch.Name)
                then begin
                    FAJnlSetup."Insurance Jnl. Batch Name" := IncStr(FAJnlSetup."Insurance Jnl. Batch Name");
                    FAJnlSetup.Modify();
                end;
            until FAJnlSetup.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetGenJnlTrailCodes(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetFAJnlTrailCodes(var FAJnlLine: Record "FA Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFAJnlNameOnBeforeFAJnlTemplateGet(var DepreciationBook: Record "Depreciation Book"; var FAJournalLine: Record "FA Journal Line"; NextLineNo: Integer; var TemplateName: Code[10]; var BatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenJnlNameOnBeforeGenJnlTemplateGet(var DepreciationBook: Record "Depreciation Book"; var GenJournalLine: Record "Gen. Journal Line"; NextLineNo: Integer; var TemplateName: Code[10]; var BatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetFAJnlDocumentNo(var FAJournalLine: Record "FA Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncGenJnlBatchName(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncFAJnlBatchName(var FAJournalBatch: Record "FA Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGenJnlDocumentNo(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

