// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;

/// <summary>
/// Provides the user interface for exporting positive pay files for bank accounts.
/// This page allows users to configure export parameters and generate positive pay files for bank validation.
/// </summary>
/// <remarks>
/// The Positive Pay Export page serves as the main interface for users to export positive pay data to banks.
/// Users can specify date ranges, review check details, and initiate the export process. The page displays
/// available checks in a subform and provides options for filtering by upload dates and cutoff criteria.
/// The export functionality integrates with the data exchange framework to generate files in the format
/// required by the bank. All export activities are logged for audit and reprocessing purposes.
/// </remarks>
page 1233 "Positive Pay Export"
{
    Caption = 'Positive Pay Export';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPlus;
    ShowFilter = false;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(LastUploadDateEntered; LastUploadDateEntered)
                {
                    ApplicationArea = Suite;
                    Caption = 'Last Upload Date';
                    ToolTip = 'Specifies the day when a positive pay file was last exported.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm();
                    end;
                }
                field(LastUploadTime; LastUploadTime)
                {
                    ApplicationArea = Suite;
                    Caption = 'Last Upload Time';
                    Editable = false;
                    ToolTip = 'Specifies the time when a positive pay file was last exported.';
                }
                field(CutoffUploadDate; CutoffUploadDate)
                {
                    ApplicationArea = Suite;
                    Caption = 'Cutoff Upload Date';
                    ToolTip = 'Specifies a date before which payments are not included in the exported file.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm();
                    end;
                }
                field(BankPaymentType; BankPaymentType)
                {
                    ApplicationArea = Suite;
                    Caption = 'Bank Payment Type';
                    ToolTip = 'Specifies the type of bank payment to include in a positive pay file that you can submit to your bank. For example, this is useful if your bank allows the file to include only check payments.';

                    trigger OnValidate()
                    begin
                        UpdateSubForm();
                    end;
                }
            }
            part(PosPayExportDetail; "Positive Pay Export Detail")
            {
                ApplicationArea = Suite;
                Caption = 'Positive Pay Export Detail';
                SubPageLink = "Bank Account No." = field("No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Export)
            {
                ApplicationArea = Suite;
                Caption = 'Export';
                Image = Export;
                ToolTip = 'Export Positive Pay data to a file that you can send to the bank when processing payments to make sure that the bank only clears validated checks and amounts.';

                trigger OnAction()
                var
                    CheckLedgerEntry: Record "Check Ledger Entry";
                    ExpPositivePayHandler: Codeunit "Exp. Positive Pay Handler";
                begin
                    CheckLedgerEntry.SetCurrentKey("Bank Account No.", "Check Date");
                    CheckLedgerEntry.SetRange("Bank Account No.", Rec."No.");
                    CheckLedgerEntry.SetRange("Check Date", LastUploadDateEntered, CutoffUploadDate);
                    if BankPaymentType <> Enum::"Bank Payment Type"::" " then
                        CheckLedgerEntry.SetRange("Bank Payment Type", BankPaymentType);

                    ExpPositivePayHandler.SetCheckLedgerEntryView(CheckLedgerEntry.GetView(false));
                    BindSubscription(ExpPositivePayHandler);
                    CheckLedgerEntry.ExportCheckFile();
                    UnbindSubscription(ExpPositivePayHandler);
                    UpdateSubForm();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Export_Promoted; Export)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateSubForm();
    end;

    trigger OnOpenPage()
    begin
        PositivePayEntry.SetRange("Bank Account No.", Rec."No.");
        if PositivePayEntry.FindLast() then begin
            LastUploadDateEntered := DT2Date(PositivePayEntry."Upload Date-Time");
            LastUploadTime := DT2Time(PositivePayEntry."Upload Date-Time");
        end;
        CutoffUploadDate := WorkDate();
        UpdateSubForm();
    end;

    var
        PositivePayEntry: Record "Positive Pay Entry";
        BankPaymentType: Enum "Bank Payment Type";
        LastUploadDateEntered: Date;
        LastUploadTime: Time;
        CutoffUploadDate: Date;

    [Scope('OnPrem')]
    procedure UpdateSubForm()
    begin
        CurrPage.PosPayExportDetail.PAGE.Set(LastUploadDateEntered, CutoffUploadDate, Rec."No.");
        CurrPage.PosPayExportDetail.PAGE.SetBankPaymentType(BankPaymentType);
    end;
}

