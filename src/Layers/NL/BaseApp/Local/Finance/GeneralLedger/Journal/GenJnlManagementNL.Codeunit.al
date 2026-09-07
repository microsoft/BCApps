// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Journal;
using Microsoft.Bank.Statement;

codeunit 11421 GenJnlManagementNL
{
    Access = Internal;

    [Scope('OnPrem')]
    procedure TemplateSelectionCBG(PageID: Integer; PageTemplate: Option General,Sales,Purchases,"Cash Receipts",Payments,Assets,Intercompany,,,,,Cash,Bank; var CBGStatement: Record "CBG Statement"; var JnlSelected: Boolean)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        JnlSelected := true;

        GenJnlTemplate.Reset();
        GenJnlTemplate.SetRange("Page ID", PageID);
        GenJnlTemplate.SetRange(Type, PageTemplate);

        case GenJnlTemplate.Count of
            0:
                begin
                    GenJnlTemplate.Init();
                    GenJnlTemplate.Type := "Gen. Journal Template Type".FromInteger(PageTemplate);
                    GenJnlTemplate.Name := Format(GenJnlTemplate.Type, MaxStrLen(GenJnlTemplate.Name));
                    GenJnlTemplate.Description := StrSubstNo(JournalLbl, GenJnlTemplate.Type);
                    GenJnlTemplate.Validate(Type);
                    GenJnlTemplate.Insert();
                    Commit();
                end;
            1:
                GenJnlTemplate.Find('-');
            else
                if PageTemplate in [PageTemplate::Bank, PageTemplate::Cash] then
                    JnlSelected := PAGE.RunModal(PAGE::"Gen. Journal Templ. List (CBG)", GenJnlTemplate) = ACTION::LookupOK
                else
                    JnlSelected := PAGE.RunModal(0, GenJnlTemplate) = ACTION::LookupOK;
        end;

        if JnlSelected then begin
            CBGStatement.FilterGroup(2);
            CBGStatement.SetRange("Journal Template Name", GenJnlTemplate.Name);
            CBGStatement.FilterGroup(0);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckTemplateNameCBG(CurrentJnlTemplateName: Code[10])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if not GenJnlBatch.Get(CurrentJnlTemplateName, DefaultBatchNameLbl) then begin
            GenJnlBatch.Init();
            GenJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
            GenJnlBatch.SetupNewBatch();
            GenJnlBatch.Name := DefaultBatchNameLbl;
            GenJnlBatch.Description := DefaultJournalLbl;
            GenJnlBatch.Insert(true);
            Commit();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GenJnlManagement, 'OnBeforeOpenJournalPageFromBatch', '', false, false)]
    local procedure OnBeforeOpenJournalPageFromBatch(var GenJnlBatch: Record "Gen. Journal Batch"; var GenJnlTemplate: Record "Gen. Journal Template"; var IsHandled: Boolean)
    begin
        if not (GenJnlTemplate."Page ID" in [PAGE::"Cash Journal", PAGE::"Bank/Giro Journal"]) then
            exit;

        IsHandled := true;
        EditCBGStatementPage(GenJnlTemplate);
    end;

    [Scope('OnPrem')]
    local procedure InsertCBGStatement(GenJnlTemplate: Record "Gen. Journal Template")
    var
        CBGStatement: Record "CBG Statement";
    begin
        CBGStatement.Init();
        CBGStatement."Journal Template Name" := GenJnlTemplate.Name;
        CBGStatement.Insert(true);
        if GenJnlTemplate."Page ID" = PAGE::"Bank/Giro Journal" then
            CBGStatement.Type := CBGStatement.Type::"Bank/Giro"
        else
            CBGStatement.Type := CBGStatement.Type::Cash;
        CBGStatement.Modify();
        PAGE.Run(GenJnlTemplate."Page ID", CBGStatement);
    end;

    [Scope('OnPrem')]
    local procedure EditCBGStatementPage(GenJnlTemplate: Record "Gen. Journal Template")
    var
        CBGStatement: Record "CBG Statement";
    begin
        CBGStatement.FilterGroup := 2;
        CBGStatement.SetRange("Journal Template Name", GenJnlTemplate.Name);
        if GenJnlTemplate."Page ID" = PAGE::"Bank/Giro Journal" then
            CBGStatement.SetFilter(CBGStatement.Type, '=%1', CBGStatement.Type::"Bank/Giro")
        else
            CBGStatement.SetFilter(CBGStatement.Type, '=%1', CBGStatement.Type::Cash);
        if CBGStatement.Count > 0 then begin
            CBGStatement.FilterGroup := 0;
            CBGStatement."Journal Template Name" := '';
            PAGE.Run(GenJnlTemplate."Page ID", CBGStatement);
        end else
            InsertCBGStatement(GenJnlTemplate);
    end;

    var
        JournalLbl: Label '%1 journal', Comment = '%1 = journal template type';
        DefaultBatchNameLbl: Label 'DEFAULT';
        DefaultJournalLbl: Label 'Default Journal';
}