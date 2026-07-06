// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Bank.BankAccount;

page 10810 "Generate EFT Files"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Generate EFT Files';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPlus;
    RefreshOnActivate = true;
    SourceTable = "EFT Export Workset";
    DataCaptionExpression = CurrPage.GenerateEFTFileLines.PAGE.GetFirstColumn();
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field("Bank Account"; BankAccountNo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account';
                TableRelation = "Bank Account";
                ToolTip = 'Specifies the number of the bank account.';

                trigger OnValidate()
                begin
                    BankAccount.SetRange("No.", BankAccountNo);
                    if BankAccount.FindFirst() then begin
                        BankAccountDescription := BankAccount.Name;
                        if (BankAccount."Export Format" = 0) or (BankAccount."Export Format" = BankAccount."Export Format"::Other) then
                            Message(NotSetupMsg);
                    end;

                    OnAfterOpenPage(SettlementDate, BankAccountNo);
                    UpdateSubForm();
                end;
            }
            field(BankAccountDescription; BankAccountDescription)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Description';
                Editable = false;
                ToolTip = 'Specifies the name of the bank.';
            }
            field(SettlementDate; SettlementDate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Settlement Date';
                ToolTip = 'Specifies the settlement date for the electronic funds transfer.';
            }
            part(GenerateEFTFileLines; "Generate EFT File Lines")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Lines';
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Delete)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Delete the selected file.';

                trigger OnAction()
                var
                    EFTExportWorkset: Record "EFT Export Workset";
                    EFTExport: Record "EFT Export";
                begin
                    CurrPage.GenerateEFTFileLines.PAGE.GetColumns(EFTExportWorkset);
                    if EFTExportWorkset.Find('-') then begin
                        if DIALOG.Confirm(DeleteQst) then
                            repeat
                                EFTExport.Reset();
                                EFTExport.SetRange("Journal Template Name", EFTExportWorkset."Journal Template Name");
                                EFTExport.SetRange("Journal Batch Name", EFTExportWorkset."Journal Batch Name");
                                EFTExport.SetRange("Line No.", EFTExportWorkset."Line No.");
                                EFTExport.SetRange("Sequence No.", EFTExportWorkset."Sequence No.");
                                if EFTExport.FindFirst() then
                                    EFTExport.Delete(true);
                            until EFTExportWorkset.Next() = 0;
                        UpdateSubForm();
                    end else
                        Message(NoLineMsg);
                end;
            }
            action(GenerateEFTFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Generate EFT Files';
                Ellipsis = true;
                Image = ExportFile;
                ShortCutKey = 'Ctrl+G';
                ToolTip = 'Export payments on journal lines that are set to electronic payment to a file prior to transmitting the file to your bank.';

                trigger OnAction()
                var
                    EFTExportWorkset: Record "EFT Export Workset";
                    GenerateEFT: Codeunit "Generate EFT";
                begin
                    CurrPage.GenerateEFTFileLines.PAGE.GetColumns(EFTExportWorkset);
                    if EFTExportWorkset.FindFirst() then
                        GenerateEFT.ProcessAndGenerateEFTFile(BankAccountNo, SettlementDate, EFTExportWorkset, EFTValues);
                    UpdateSubForm();
                end;
            }
            action("Mark All")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark All';
                Image = Apply;
                ShortCutKey = 'Ctrl+M';
                ToolTip = 'Select all lines to be generated.';

                trigger OnAction()
                begin
                    CurrPage.GenerateEFTFileLines.PAGE.MarkUnmarkInclude(true, BankAccountNo);
                    CurrPage.Update(false);
                end;
            }
            action("Unmark All")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Unmark All';
                Image = UnApply;
                ShortCutKey = 'Ctrl+U';
                ToolTip = 'View a trial balance with amounts shown in separate columns for each time period.';

                trigger OnAction()
                begin
                    CurrPage.GenerateEFTFileLines.PAGE.MarkUnmarkInclude(false, BankAccountNo);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Delete_Promoted; Delete)
                {
                }
                actionref(GenerateEFTFile_Promoted; GenerateEFTFile)
                {
                }
                actionref("Mark All_Promoted"; "Mark All")
                {
                }
                actionref("Unmark All_Promoted"; "Unmark All")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        SettlementDate := Today;

        if (BankAccountNoFilter <> '') and (BankAccountNoFilter <> BankAccountNo) then begin
            BankAccountNo := BankAccountNoFilter;
            BankAccount.SetRange("No.", BankAccountNo);
            if BankAccount.FindFirst() then
                BankAccountDescription := BankAccount.Name;
        end;

        OnOpenPageOnBeforeUpdateSubForm(SettlementDate, BankAccountNo);

        UpdateSubForm();
    end;

    var
        BankAccount: Record "Bank Account";
        EFTValues: Codeunit "EFT Values";
        BankAccountNo: Code[20];
        BankAccountDescription: Text[100];
        SettlementDate: Date;
        BankAccountNoFilter: Code[20];
        DeleteQst: Label 'Deleting these marked payments will remove them from the EFT file, do you want to continue?';
        NoLineMsg: Label 'There are no lines selected to delete.';
        NotSetupMsg: Label 'This bank account is not setup for EFT payments.';

    local procedure UpdateSubForm()
    begin
        CurrPage.GenerateEFTFileLines.PAGE.Set(BankAccountNo);
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure SetBalanceAccount(BankAccountNumber: Code[20])
    begin
        BankAccountNoFilter := BankAccountNumber;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenPage(var SettlementDate: date; var BankAccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeUpdateSubForm(var SettlementDate: date; var BankAccountNo: Code[20])
    begin
    end;
}

