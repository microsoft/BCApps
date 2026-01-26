// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using System.Telemetry;

page 2000001 "EB Payment Journal"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'EB Payment Journals';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Payment Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentJnlBatchName; CurrentJnlBatchName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batch Name';
                    Lookup = true;
                    ToolTip = 'Specifies the batch name of the payment journal.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        DoLookup := PmtJrnlMgt.LookupName(Rec.GetRangeMax("Journal Template Name"), CurrentJnlBatchName, Text);
                        CurrPage.Update();
                        exit(DoLookup);
                    end;

                    trigger OnValidate()
                    begin
                        PmtJrnlMgt.CheckName(CurrentJnlBatchName, Rec);
                        CurrentJnlBatchNameOnAfterVali();
                    end;
                }
                field(BankAccountCodeFilter; BankAccountCodeFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account';
                    Lookup = true;
                    ToolTip = 'Specifies the bank account from which the payment is made.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        BankAccList: Page "Bank Account List";
                    begin
                        BankAccList.LookupMode(true);
                        if not (BankAccList.RunModal() = ACTION::LookupOK) then
                            exit(false);

                        Text := BankAccList.GetSelectionFilter();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        BankAccountCodeFilterOnAfterVa();
                    end;
                }
                field(ExportProtocolCode; ExportProtocolCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Protocol';
                    Lookup = true;
                    TableRelation = "Export Protocol".Code;
                    ToolTip = 'Specifies the payment journal line export protocol code, which controls what payment file will be generated in the payment journal.';

                    trigger OnValidate()
                    begin
                        ExportProtocolCodeOnAfterValid();
                        GetExportProtocol();
                        EnablePaymentExportErrors := ExportProtocol."Export Object Type" = ExportProtocol."Export Object Type"::XMLPort;
                        EnableCheckPaymentLines := not EnablePaymentExportErrors;
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Export Protocol Code"; Rec."Export Protocol Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that identifies the protocol to use for exporting the payment history.';
                }
                field("Separate Line"; Rec."Separate Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the payment message is formatted using separate lines.';
                }
                field("ISO Currency Code"; Rec."ISO Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ISO code that defines the currency associated with the payment journal entry.';
                }
                field("Standard Format Message"; Rec."Standard Format Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the message in the Payment Message field is a standard format message or not.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which you want the payment to be posted.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that the entry on the journal line will be posted to.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer or vendor number that the entry on the journal line will be posted to.';

                    trigger OnValidate()
                    begin
                        PmtJrnlMgt.GetAccount(Rec, AccName, BankAccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Payment Message"; Rec."Payment Message")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment message that is to be included in this payment.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the outstanding amount.';
                }
                field("Pmt. Disc. Possible"; Rec."Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment discount that is subtracted from the remaining amount of the outstanding entry.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the payment.';
                    Visible = true;
                }
                field("Currency Factor"; Rec."Currency Factor")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency exchange factor that is based on the date of the payment.';
                    Visible = false;
                }
                field("Bank Account"; Rec."Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account that the payment will be posted to.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Beneficiary Bank Account"; Rec."Beneficiary Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the beneficiary bank account.';
                }
                field("Beneficiary Bank Account No."; Rec."Beneficiary Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account that the payment will be posted to.';
                }
                field("Beneficiary IBAN"; Rec."Beneficiary IBAN")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the International Bank Account Number (IBAN) for the recipient of the payment.';
                }
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT code for the bank account that the payment is made from.';
                }
                field("Bank Country/Region Code"; Rec."Bank Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the country/region code of the bank account.';
                }
                field("Instruction Priority"; Rec."Instruction Priority")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order of importance for processing the payment.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("IBLC/BLWI Code"; Rec."IBLC/BLWI Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the IBLC/BLWI code, regarding the kind of payment.';
                    Visible = false;
                }
                field("IBLC/BLWI Justification"; Rec."IBLC/BLWI Justification")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the IBLC/BLWI justification, describing the kind of payment.';
                    Visible = false;
                }
                field("Code Payment Method"; Rec."Code Payment Method")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify the payment method.';
                    Visible = false;
                }
                field("Code Expenses"; Rec."Code Expenses")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code expense that was defined in the export protocol.';
                    Visible = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the export protocol that is associated with the payment journal.';
                }
            }
            group(Control60)
            {
                ShowCaption = false;
                fixed(Control1901775801)
                {
                    ShowCaption = false;
                    group("Bank Account Name")
                    {
                        Caption = 'Bank Account Name';
                        field(BankAccName; BankAccName)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                        }
                    }
                    group("Remittee Name")
                    {
                        Caption = 'Remittee Name';
                        field(AccName; AccName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Remittee Name';
                            Editable = false;
                            ToolTip = 'Specifies the name of the customer or vendor who has been entered on the payment journal.';
                        }
                    }
                    group("Total Remittee (LCY)")
                    {
                        Caption = 'Total Remittee (LCY)';
                        field(BalanceRem; (Balance + Rec."Amount (LCY)" - xRec."Amount (LCY)"))
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Total Remittee (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the amount of the payments of the customer or vendor that has been entered on the payment journal line.';
                            Visible = BalanceRemVisible;
                        }
                    }
                    group("Total Balance (LCY)")
                    {
                        Caption = 'Total Balance (LCY)';
                        field(TotalBalance; (TotalBalance + Rec."Amount (LCY)" - xRec."Amount (LCY)"))
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Total Balance (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the total balance in the payment journal.';
                            Visible = TotalBalanceVisible;
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part("Payment File Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment File Errors';
                Enabled = EnablePaymentExportErrors;
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "Journal Batch Name" = field("Journal Batch Name"),
                              "Journal Line No." = field("Line No.");
            }
            part(Control1900919607; "Dimension Set Entries FactBox")
            {
                ApplicationArea = Dimensions;
                SubPageLink = "Dimension Set ID" = field("Dimension Set ID");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        PmtJrnlMgt.ShowCard(Rec);
                    end;
                }
                action(LedgerEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';

                    trigger OnAction()
                    begin
                        PmtJrnlMgt.ShowEntries(Rec);
                    end;
                }
            }
            group("Pay&ment")
            {
                Caption = 'Pay&ment';
                action(SuggestVendorPayments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Vendor Payments...';
                    Image = SuggestVendorPayments;
                    ToolTip = 'Create payment suggestions as lines in the payment journal.';

                    trigger OnAction()
                    begin
                        SuggestPayments.SetJournal(Rec);
                        SuggestPayments.RunModal();
                        Clear(SuggestPayments);
                    end;
                }
                action(CheckPaymentLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Check Payment Lines';
                    Enabled = EnableCheckPaymentLines;
                    Image = Export;
                    ToolTip = 'Test the payment journal lines to validate the payment journal lines. The validation that is performed on the journal lines depends on the type of check that is specified in the Export Protocols window.';

                    trigger OnAction()
                    begin
                        GetExportProtocol();
                        if ExportProtocol.CheckPaymentLines(Rec) then
                            Message(Text002);
                    end;
                }
                action(ExportPaymentLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Payment Lines';
                    Image = Export;
                    ToolTip = 'Export the payments to a file. An export protocol defines the payment file format that you want to use for the electronic banking payments. Each journal line contains all the information needed for payment of an outstanding entry.';

                    trigger OnAction()
                    var
                        FeatureTelemetry: Codeunit "Feature Telemetry";
                        BEElecBankTok: Label 'BE Electronic Banking', Locked = true;
                    begin
                        FeatureTelemetry.LogUptake('1000HL6', BEElecBankTok, Enum::"Feature Uptake Status"::"Used");
                        GetExportProtocol();
                        ExportProtocol.ExportPaymentLines(Rec);
                        CurrPage.Update(false);
                        FeatureTelemetry.LogUsage('1000HL7', BEElecBankTok, 'BE Electronic Banking Payment Lines Exported');
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(SuggestVendorPayments_Promoted; SuggestVendorPayments)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(CheckPaymentLines_Promoted; CheckPaymentLines)
                {
                }
                actionref(ExportPaymentLines_Promoted; ExportPaymentLines)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        PmtJrnlMgt.GetAccount(Rec, AccName, BankAccName);
        UpdateAmount();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        UpdateAmount();
    end;

    trigger OnInit()
    begin
        TotalBalanceVisible := true;
        BalanceRemVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        PmtJrnlMgt.SetUpNewLine(Rec, xRec);
        Clear(ShortcutDimCode);
        Clear(AccName);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
        OpenedFromBatch: Boolean;
        IsHandled: Boolean;
    begin
        OpenedFromBatch := (Rec."Journal Batch Name" <> '') and (Rec."Journal Template Name" = '');
        EnablePaymentExportErrors := false;
        EnableCheckPaymentLines := true;
        if OpenedFromBatch then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            PmtJrnlMgt.OpenJournal(CurrentJnlBatchName, Rec);
            exit;
        end;

        IsHandled := false;
        OnOpenPageOnBeforeTemplateSelection(Rec, PmtJrnlMgt, CurrentJnlBatchName, IsHandled);
        if not IsHandled then begin
            PmtJrnlMgt.TemplateSelection(Rec, JnlSelected);
            if not JnlSelected then
                Error('');
        end;
        PmtJrnlMgt.OpenJournal(CurrentJnlBatchName, Rec);
        ClearVariables();
    end;

    var
        PmtJrnlMgt: Codeunit PmtJrnlManagement;
        CurrentJnlBatchName: Code[10];
        AccName: Text[100];
        BankAccName: Text[100];
        Balance: Decimal;
        TotalBalance: Decimal;
        ShowAmount: Boolean;
        ShowTotalAmount: Boolean;
        DoLookup: Boolean;
        ShortcutDimCode: array[8] of Code[20];
        Text001: Label 'Please set an Export Protocol filter on the payment journal.';
        Text002: Label 'Payment lines have been validated successfully.';
        BalanceRemVisible: Boolean;
        TotalBalanceVisible: Boolean;

    protected var
        ExportProtocol: Record "Export Protocol";
        ExportProtocolCode: Code[20];
        BankAccountCodeFilter: Code[1024];
        SuggestPayments: Report "Suggest Vendor Payments EB";
        EnablePaymentExportErrors: Boolean;
        EnableCheckPaymentLines: Boolean;

    local procedure UpdateAmount()
    begin
        PmtJrnlMgt.CalculateTotals(Rec, xRec, Balance, TotalBalance, ShowAmount, ShowTotalAmount);
        BalanceRemVisible := ShowAmount;
        TotalBalanceVisible := ShowTotalAmount;
    end;

    procedure GetExportProtocol()
    begin
        if ExportProtocolCode = '' then
            Error(Text001);
        ExportProtocol.Get(ExportProtocolCode);
    end;

    local procedure BankAccountCodeFilterOnAfterVa()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Bank Account", BankAccountCodeFilter);
        Rec.FilterGroup(0);
        CurrPage.Update(false);
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        PmtJrnlMgt.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure ExportProtocolCodeOnAfterValid()
    begin
        Rec.FilterGroup(2);
        Rec.SetFilter("Export Protocol Code", ExportProtocolCode);
        Rec.FilterGroup(0);
        CurrPage.Update(false);
    end;

    local procedure ClearVariables()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearVariables(Rec, BankAccountCodeFilter, ExportProtocolCode, IsHandled);
        if IsHandled then
            exit;

        Clear(ExportProtocolCode);
        Clear(BankAccountCodeFilter);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeTemplateSelection(var PaymentJournalLine: Record "Payment Journal Line"; var PmtJrnlMgt: Codeunit PmtJrnlManagement; var CurrentJnlBatchName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearVariables(var PaymentJournalLine: Record "Payment Journal Line"; var BankAccountCodeFilter: Code[1024]; var ExportProtocolCode: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

