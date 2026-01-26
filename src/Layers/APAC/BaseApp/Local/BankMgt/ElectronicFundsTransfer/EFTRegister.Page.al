// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Bank.BankAccount;
using Microsoft.Purchases.Payables;

page 11615 "EFT Register"
{
    ApplicationArea = Basic, Suite;
    Caption = 'EFT Registers';
    Editable = false;
    PageType = List;
    SourceTable = "EFT Register";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1500000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number for an electronic funds transfer (EFT) file.';
                }
                field("EFT Payment"; Rec."EFT Payment")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an electronic funds transfer (EFT) file has been created.';
                }
                field("File Created"; Rec."File Created")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when an electronic funds transfer (EFT) file was created.';
                }
                field("Total Amount (LCY)"; Rec."Total Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount paid in an electronic funds transfer (EFT).';
                }
                field(Time; Rec.Time)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the time when an electronic funds transfer (EFT) file was created.';
                }
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the register has been canceled.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Vendor)
            {
                Caption = 'Vendor';
                Image = Vendor;
                action(Entries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entries';
                    Image = Entries;
                    RunObject = Page "Vendor Ledger Entries";
                    RunPageLink = "EFT Register No." = field("No.");
                    RunPageView = sorting("EFT Register No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the list of entries.';
                }
            }
        }
        area(processing)
        {
            action(CreateFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Create File';
                Image = CreateDocument;
                ToolTip = 'Start the process of generating the file.';

                trigger OnAction()
                var
                    BankAcc: Record "Bank Account";
                    EFTManagement: Codeunit "EFT Management";
                begin
                    if not Confirm(ConfirmExportQst, false, Rec."No.") then
                        Error('');

                    if BankAcc.Get(Rec."Bank Account Code") then
                        EFTManagement.CreateFileFromEFTRegister(Rec, Rec."File Description", BankAcc);
                end;
            }
            action(CancelExport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancel Export';
                Image = Cancel;
                ToolTip = 'Cancel the export of the EFT payment. The link to the related EFT register will be removed and the exported journal lines can be deleted.';

                trigger OnAction()
                var
                    EFTManagement: Codeunit "EFT Management";
                begin
                    EFTManagement.CancelExport(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CreateFile_Promoted; CreateFile)
                {
                }
                actionref(CancelExport_Promoted; CancelExport)
                {
                }
            }
        }
    }

    var
        ConfirmExportQst: Label 'The file for EFT payment number %1 has already been created.\\Do you want to create the file again?', Comment = '%1 - register number';
}

