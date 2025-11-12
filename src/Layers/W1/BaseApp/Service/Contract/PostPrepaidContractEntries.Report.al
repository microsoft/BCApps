// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Setup;
using Microsoft.Service.Ledger;
using Microsoft.Service.Reports;
using Microsoft.Service.Setup;

report 6032 "Post Prepaid Contract Entries"
{
    ApplicationArea = Service;
    Caption = 'Post Prepaid Service Contract Entries';
    Permissions = TableData "Service Ledger Entry" = rm;
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Service Ledger Entry"; "Service Ledger Entry")
        {
            DataItemTableView = sorting("Service Contract No.") where(Type = const("Service Contract"), "Moved from Prepaid Acc." = const(false), Open = const(false));
            RequestFilterFields = "Service Contract No.";

            trigger OnAfterGetRecord()
            begin
                Counter := Counter + 1;
                Window.Update(1, "Service Contract No.");
                Window.Update(2, Round(Counter / NoOfContracts * 10000, 1));

                ServLedgEntry.Get("Entry No.");
                ServLedgEntry."Moved from Prepaid Acc." := true;
                ServLedgEntry.Modify();

                if (LastContract <> '') and (LastContract <> "Service Contract No.") then begin
                    TempServLedgEntry.Reset();
                    TempServLedgEntry.SetRange("Service Contract No.", LastContract);
                    TempServLedgEntry.CalcSums("Amount (LCY)");
                    if TempServLedgEntry."Amount (LCY)" <> 0 then
                        PostGenJnlLine()
                    else
                        TempServLedgEntry.DeleteAll();
                    TempServLedgEntry.SetRange("Service Contract No.", "Service Contract No.");
                end;

                LastContract := "Service Contract No.";

                if SalesSetup."Discount Posting" in
                   [SalesSetup."Discount Posting"::"Line Discounts", SalesSetup."Discount Posting"::"All Discounts"]
                then
                    AmtInclDisc := Round(("Amount (LCY)" / (1 - ("Discount %" / 100))))
                else
                    AmtInclDisc := "Amount (LCY)";

                TempServLedgEntry.SetRange("Dimension Set ID", "Dimension Set ID");
                if TempServLedgEntry.FindFirst() then begin
                    TempServLedgEntry."Amount (LCY)" += AmtInclDisc;
                    TempServLedgEntry.Modify();
                end else begin
                    TempServLedgEntry := "Service Ledger Entry";
                    TempServLedgEntry."Amount (LCY)" := AmtInclDisc;
                    TempServLedgEntry.Insert();
                end;
            end;

            trigger OnPostDataItem()
            var
                UpdateAnalysisView: Codeunit "Update Analysis View";
            begin
                if PostPrepaidContracts = PostPrepaidContracts::"Post Prepaid Transactions" then begin
                    TempServLedgEntry.SetRange("Dimension Set ID");
                    TempServLedgEntry.CalcSums("Amount (LCY)");
                    if TempServLedgEntry."Amount (LCY)" <> 0 then begin
                        PostGenJnlLine();
                        UpdateAnalysisView.UpdateAll(0, true);
                    end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if PostPrepaidContracts = PostPrepaidContracts::"Print Only" then begin
                    Clear(PrepaidContractEntriesTest);
                    PrepaidContractEntriesTest.InitVariables(UntilDate, PostingDate);
                    PrepaidContractEntriesTest.SetTableView("Service Ledger Entry");
                    PrepaidContractEntriesTest.RunModal();
                    CurrReport.Break();
                end;

                if PostPrepaidContracts = PostPrepaidContracts::"Post Prepaid Transactions" then begin
                    ServContractHdr.SetFilter("Contract No.", GetFilter("Service Contract No."));
                    if ServContractHdr.Find('-') then
                        repeat
                            ServContractHdr.CalcFields("No. of Unposted Credit Memos");
                            if ServContractHdr."No. of Unposted Credit Memos" <> 0 then
                                Error(Text005Err, Text007Txt, Text008Txt, ServContractHdr."Contract No.", Text006Txt);
                        until ServContractHdr.Next() = 0;
                end;

                LastContract := '';
                if UntilDate = 0D then
                    Error(Text000Err);
                if PostingDate = 0D then
                    Error(Text001Err);

                SetRange("Posting Date", 0D, UntilDate);

                NoOfContracts := Count;

                Window.Open(
                  Text002Txt +
                  Text003Txt +
                  '@2@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@');

                GLSetup.GetRecordOnce();
                if not GLSetup."Journal Templ. Name Mandatory" then begin
                    ServMgtSetup.Get();
                    ServMgtSetup.TestField("Prepaid Posting Document Nos.");
                end;
                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Service Management");
                SalesSetup.Get();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(UntilDate; UntilDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Post until Date';
                        MultiLine = true;
                        ToolTip = 'Specifies the date up to which you want to post prepaid entries. The batch job includes service ledger entries with posting dates on or before this date.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Service;
                        Caption = 'Posting Date';
                        MultiLine = true;
                        ToolTip = 'Specifies the date that you want to use as the posting date on the service ledger entries.';
                    }
                    field(JournalTemplateName; GenJnlLineReq."Journal Template Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template Name';
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnValidate()
                        begin
                            GenJnlLineReq."Journal Batch Name" := '';
                        end;
                    }
                    field(JournalBatchName; GenJnlLineReq."Journal Batch Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch Name';
                        Lookup = true;
                        ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                        Visible = IsJournalTemplNameVisible;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJnlManagement: Codeunit GenJnlManagement;
                        begin
                            GenJnlManagement.SetJnlBatchName(GenJnlLineReq);
                            if GenJnlLineReq."Journal Batch Name" <> '' then
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                        end;

                        trigger OnValidate()
                        begin
                            if GenJnlLineReq."Journal Batch Name" <> '' then begin
                                GenJnlLineReq.TestField("Journal Template Name");
                                GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
                            end;
                        end;
                    }
                    field(PostPrepaidContracts; PostPrepaidContracts)
                    {
                        ApplicationArea = Service;
                        Caption = 'Action';
                        OptionCaption = 'Post Prepaid Transactions,Print Only';
                        ToolTip = 'Specifies the desired action relating to prepaid contract entries.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            GLSetup.GetRecordOnce();
            IsJournalTemplNameVisible := GLSetup."Journal Templ. Name Mandatory";
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        PostingDate := WorkDate();
        Clear(GenJnlPostLine);
    end;

    trigger OnPostReport()
    begin
        if PostPrepaidContracts = PostPrepaidContracts::"Post Prepaid Transactions" then
            Window.Close();
    end;

    trigger OnPreReport()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if PostPrepaidContracts = PostPrepaidContracts::"Post Prepaid Transactions" then begin
            GLSetup.GetRecordOnce();
            if not GLSetup."Journal Templ. Name Mandatory" then
                exit;

            if GenJnlLineReq."Journal Template Name" = '' then
                Error(PleaseEnterErr, GenJnlLineReq.FieldCaption("Journal Template Name"));
            if GenJnlLineReq."Journal Batch Name" = '' then
                Error(PleaseEnterErr, GenJnlLineReq.FieldCaption("Journal Batch Name"));

            Clear(DocNo);
            GenJnlBatch.Get(GenJnlLineReq."Journal Template Name", GenJnlLineReq."Journal Batch Name");
            GenJnlBatch.TestField("No. Series");
            DocNo := NoSeries.GetNextNo(GenJnlBatch."No. Series", WorkDate());
        end;
    end;

    var
        Text000Err: Label 'You must fill in the Post Until Date field.';
        Text001Err: Label 'You must fill in the Posting Date field.';
        Text002Txt: Label 'Posting prepaid contract entries...\';
#pragma warning disable AA0470
        Text003Txt: Label 'Service Contract: #1###############\\';
#pragma warning restore AA0470
        Text004Txt: Label 'Service Contract';
        GLSetup: Record "General Ledger Setup";
        GenJnlLine: Record "Gen. Journal Line";
        ServLedgEntry: Record "Service Ledger Entry";
        TempServLedgEntry: Record "Service Ledger Entry" temporary;
        ServContractAccGr: Record "Service Contract Account Group";
        ServMgtSetup: Record "Service Mgt. Setup";
        SourceCodeSetup: Record "Source Code Setup";
        ServContractHdr: Record "Service Contract Header";
        SalesSetup: Record "Sales & Receivables Setup";
        GenJnlLineReq: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        PrepaidContractEntriesTest: Report "Prepaid Contr. Entries - Test";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        PostPrepaidContracts: Option "Post Prepaid Transactions","Print Only";
        DocNo: Code[20];
        UntilDate: Date;
        PostingDate: Date;
        NoOfContracts: Integer;
        Counter: Integer;
        AmtInclDisc: Decimal;
        LastContract: Code[20];
        IsJournalTemplNameVisible: Boolean;
#pragma warning disable AA0470
        Text005Err: Label 'You cannot post %1 because %2 %3 has at least one %4 linked to it.';
#pragma warning restore AA0470
        Text006Txt: Label 'Unposted Credit Memo';
        Text007Txt: Label 'Prepaid Contract Entries';
#pragma warning disable AA0074
        Text008txt: Label 'Service Contract';
#pragma warning restore AA0074
        PleaseEnterErr: Label 'Please enter a %1.', Comment = '%1 - field caption';

    local procedure PostGenJnlLine()
    var
        NoSeries: Codeunit "No. Series";
        IsPrepaidAccountPostingHandled: Boolean;
        IsNonPrepaidAccountPostingHandled: Boolean;
    begin
        TempServLedgEntry.Reset();
        if not TempServLedgEntry.FindSet() then
            exit;

        GLSetup.GetRecordOnce();
        if not GLSetup."Journal Templ. Name Mandatory" then
            DocNo := NoSeries.GetNextNo(ServMgtSetup."Prepaid Posting Document Nos.", WorkDate());

        repeat
            IsNonPrepaidAccountPostingHandled := false;
            OnBeforePostNonPrepaidAccount(GenJnlLine, TempServLedgEntry, IsNonPrepaidAccountPostingHandled);
            if not IsNonPrepaidAccountPostingHandled then begin
                GenJnlLine.Reset();
                GenJnlLine.Init();
                GenJnlLine."Document No." := DocNo;
                GenJnlLine."Journal Template Name" := GenJnlLineReq."Journal Template Name";
                GenJnlLine."Journal Batch Name" := GenJnlLineReq."Journal Batch Name";
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                GenJnlLine."VAT Posting" := GenJnlLine."VAT Posting"::"Manual VAT Entry";
                ServContractAccGr.Get(TempServLedgEntry."Serv. Contract Acc. Gr. Code");
                ServContractAccGr.TestField("Non-Prepaid Contract Acc.");
                GenJnlLine.Validate("Account No.", ServContractAccGr."Non-Prepaid Contract Acc.");
                GenJnlLine."Posting Date" := PostingDate;
                GenJnlLine.Description := Text004Txt;
                GenJnlLine."External Document No." := TempServLedgEntry."Service Contract No.";
                GenJnlLine.Validate(Amount, TempServLedgEntry."Amount (LCY)");
                GenJnlLine."Shortcut Dimension 1 Code" := TempServLedgEntry."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := TempServLedgEntry."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := TempServLedgEntry."Dimension Set ID";
                GenJnlLine."Source Code" := SourceCodeSetup."Service Management";
                GenJnlLine."System-Created Entry" := true;
                GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
                GenJnlLine."Gen. Bus. Posting Group" := '';
                GenJnlLine."Gen. Prod. Posting Group" := '';
                GenJnlLine."VAT Bus. Posting Group" := '';
                GenJnlLine."VAT Prod. Posting Group" := '';
                RunGenJnlPostLine();
            end;

            IsPrepaidAccountPostingHandled := false;
            OnBeforePostPrepaidAccount(GenJnlLine, TempServLedgEntry, IsPrepaidAccountPostingHandled);
            if not IsPrepaidAccountPostingHandled then begin
                ServContractAccGr.Get(TempServLedgEntry."Serv. Contract Acc. Gr. Code");
                ServContractAccGr.TestField("Prepaid Contract Acc.");
                GenJnlLine.Validate("Account No.", ServContractAccGr."Prepaid Contract Acc.");
                GenJnlLine.Validate(Amount, -TempServLedgEntry."Amount (LCY)");
                GenJnlLine."Shortcut Dimension 1 Code" := TempServLedgEntry."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := TempServLedgEntry."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := TempServLedgEntry."Dimension Set ID";
                GenJnlLine."Gen. Posting Type" := GenJnlLine."Gen. Posting Type"::" ";
                GenJnlLine."Gen. Bus. Posting Group" := '';
                GenJnlLine."Gen. Prod. Posting Group" := '';
                GenJnlLine."VAT Bus. Posting Group" := '';
                GenJnlLine."VAT Prod. Posting Group" := '';
                RunGenJnlPostLine();
            end;
        until TempServLedgEntry.Next() = 0;

        TempServLedgEntry.Reset();
        TempServLedgEntry.DeleteAll();
    end;

    local procedure RunGenJnlPostLine()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunGenJnlPostLine(GenJnlLine, TempServLedgEntry, IsHandled);
        if IsHandled then
            exit;

        GenJnlPostLine.Run(GenJnlLine);
    end;

    procedure InitializeRequest(UntilDateFrom: Date; PostingDateFrom: Date; PostPrepaidContractsFrom: Option "Post Prepaid Transactions","Print Only")
    begin
        UntilDate := UntilDateFrom;
        PostingDate := PostingDateFrom;
        PostPrepaidContracts := PostPrepaidContractsFrom;
    end;

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch");
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostNonPrepaidAccount(var GenJnlLine: Record "Gen. Journal Line"; var TempServLedgEntry: Record "Service Ledger Entry"; var IsNonPrepaidAccountPostingHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostPrepaidAccount(var GenJnlLine: Record "Gen. Journal Line"; var TempServLedgEntry: Record "Service Ledger Entry"; var IsPrepaidAccountPostingHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var TempServLedgEntry: Record "Service Ledger Entry" temporary; var IsHandled: Boolean)
    begin
    end;
}

