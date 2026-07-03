// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

page 10811 "Generate EFT File Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "EFT Export Workset";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Include; Rec.Include)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies to either include or exclude this line.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date on the document that provides the basis for the entry on the journal line.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a document number for the journal line.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the account number that the journal line entry will be posted to.';
                }
                field(Amount; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total amount that the journal line consists of.';
                }
            }
        }
    }

    actions
    {
    }

    [Scope('OnPrem')]
    procedure Set(BankAccountNumber: Code[20])
    var
        EFTExport: Record "EFT Export";
    begin
        Rec.DeleteAll();
        EFTExport.SetCurrentKey("Bank Account No.", Transmitted);
        EFTExport.SetRange("Bank Account No.", BankAccountNumber);
        EFTExport.SetRange(Transmitted, false);
        if EFTExport.Find('-') then
            repeat
                EFTExport.Description := CopyStr(EFTExport.Description, 1, MaxStrLen(Rec.Description));
                Rec.TransferFields(EFTExport);
                Rec.Include := true;
                Rec.Insert();
            until EFTExport.Next() = 0;
        CurrPage.Update(false);
    end;

    [Scope('OnPrem')]
    procedure GetFirstColumn(): Text[50]
    begin
        if Rec.FindFirst() then
            exit(Rec."Journal Template Name" + ' · ' + Rec."Journal Batch Name" + ' · ' + Format(Rec."Line No.") + ' · ' + Format(Rec."Sequence No."))
        else
            exit('');
    end;

    [Scope('OnPrem')]
    procedure GetColumns(var TempEFTExportWorkset: Record "EFT Export Workset" temporary)
    begin
        TempEFTExportWorkset.DeleteAll();
        Rec.SetRange(Include, true);
        if Rec.FindFirst() then
            repeat
                TempEFTExportWorkset.TransferFields(Rec);
                TempEFTExportWorkset.Insert();
            until Rec.Next() = 0;
        Rec.Reset();
    end;

    [Scope('OnPrem')]
    procedure MarkUnmarkInclude(SetInclude: Boolean; BankAccountNumber: Code[20])
    begin
        Rec.SetCurrentKey("Bal. Account No.");
        Rec.SetRange("Bal. Account No.", BankAccountNumber);
        if Rec.FindFirst() then
            repeat
                Rec.Include := SetInclude;
                Rec.Modify();
            until Rec.Next() = 0;
    end;
}

