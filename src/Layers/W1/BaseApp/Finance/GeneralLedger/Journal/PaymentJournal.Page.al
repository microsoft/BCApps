// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Payment;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Reporting;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Privacy;
using System.Threading;
using System.Utilities;

/// <summary>
/// Specialized journal interface for vendor payments, employee reimbursements, and outbound cash transactions.
/// Provides comprehensive payment processing capabilities including check printing, electronic payments, and bank export functionality.
/// </summary>
/// <remarks>
/// Primary data source: Gen. Journal Line with payment-specific filtering and validation.
/// Key features: Check printing, electronic payment export, payment application, positive pay integration, and payment method validation.
/// Extensibility: Integration events support custom payment processing, export formats, and validation workflows.
/// </remarks>
page 256 "Payment Journal"
{
    AdditionalSearchTerms = 'print check,payment file export,electronic payment';
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Payment Journals';
    DataCaptionExpression = Rec.DataCaption();
    DelayedInsert = true;
    PageType = Worksheet;
    AboutTitle = 'About Payment Journals';
    AboutText = 'Record and process payments to vendors and refunds to customers, apply payments to invoices or credit memos, and manage payment methods including printing checks and exporting electronic payment files.';
    SaveValues = true;
    SourceTable = "Gen. Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                field(CurrentJnlBatchName; CurrentJnlBatchName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batch Name';
                    Lookup = true;
                    ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord();
                        GenJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                        SetControlAppearanceFromBatch();
                        OnLookupCurrentJnlBatchNameOnAfterSetControlAppearanceFromBatch(CurrentJnlBatchName);

                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        GenJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                        CurrentJnlBatchNameOnAfterValidate();
                        OnAfterValidateCurrentJnlBatchName(CurrentJnlBatchName);
                    end;
                }
                field(GenJnlBatchApprovalStatus; GenJnlBatchApprovalStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approval Status';
                    Editable = false;
                    Visible = EnabledGenJnlBatchWorkflowsExist;
                    ToolTip = 'Specifies the approval status for general journal batch.';
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = HasPmtFileErr;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = HasPmtFileErr;
                    Visible = false;
                }
                field("Invoice Received Date"; Rec."Invoice Received Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = HasPmtFileErr;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = HasPmtFileErr;
                    ShowMandatory = true;
                }
                field("Incoming Document Entry No."; Rec."Incoming Document Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        if Rec."Incoming Document Entry No." > 0 then
                            HyperLink(Rec.GetIncomingDocumentURL());
                    end;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Applies-to Ext. Doc. No."; Rec."Applies-to Ext. Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                        EnableApplyEntriesAction();
                        CurrPage.SaveRecord();
                    end;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Style = Attention;
                    StyleExpr = HasPmtFileErr;

                    trigger OnValidate()
                    begin
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        CurrPage.SaveRecord();
                        OnAfterValidateAccountNo(Rec, xRec, Balance, TotalBalance, ShowBalance, ShowTotalBalance, BalanceVisible, TotalBalanceVisible, NumberOfRecords);
                    end;
                }
                field("Recipient Bank Account"; Rec."Recipient Bank Account")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = RecipientBankAccountMandatory;
                }
                field("Message to Recipient"; Rec."Message to Recipient")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(GenJnlLineApprovalStatus; GenJnlLineApprovalStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approval Status';
                    Editable = false;
                    Visible = EnabledGenJnlLineWorkflowsExist;
                    ToolTip = 'Specifies the approval status for general journal line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = HasPmtFileErr;
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    AssistEdit = true;

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        if ChangeExchangeRate.RunModal() = ACTION::OK then
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());

                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsPostingGroupEditable;
                    Visible = IsPostingGroupEditable;
                }
                field("Allocation Account No."; Rec."Selected Alloc. Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Allocation Account No.';
                    Visible = UseAllocationAccountNumber;
                    trigger OnValidate()
                    var
                        GenJournalAllocAccMgt: Codeunit "Gen. Journal Alloc. Acc. Mgt.";
                    begin
                        GenJournalAllocAccMgt.VerifySelectedAllocationAccountNo(Rec);
                    end;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                }
                field("Payment Reference"; Rec."Payment Reference")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Creditor No."; Rec."Creditor No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    Style = Attention;
                    StyleExpr = HasPmtFileErr;
                    Visible = AmountVisible;

                    trigger OnValidate()
                    begin
                        CheckAmountMatchedToAppliedLines();
                    end;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount in local currency (including VAT) that the journal line consists of.';
                    Visible = AmountVisible;

                    trigger OnValidate()
                    begin
                        CheckAmountMatchedToAppliedLines();
                    end;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = DebitCreditVisible;

                    trigger OnValidate()
                    begin
                        CheckAmountMatchedToAppliedLines();
                    end;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = DebitCreditVisible;

                    trigger OnValidate()
                    begin
                        CheckAmountMatchedToAppliedLines();
                    end;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("VAT Difference"; Rec."VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Bal. VAT Amount"; Rec."Bal. VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Bal. VAT Difference"; Rec."Bal. VAT Difference")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        EnableApplyEntriesAction();
                    end;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        CurrPage.SaveRecord();
                    end;
                }
                field("Bal. Gen. Posting Type"; Rec."Bal. Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Bal. Gen. Bus. Posting Group"; Rec."Bal. Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bal. Gen. Prod. Posting Group"; Rec."Bal. Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Bal. VAT Bus. Posting Group"; Rec."Bal. VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Bal. VAT Prod. Posting Group"; Rec."Bal. VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Applied (Yes/No)"; Rec.IsApplied())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied (Yes/No)';
                    ToolTip = 'Specifies if the payment has been applied.';
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(AppliesToDocNo; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                }
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    Visible = false;
                }
                field(GetAppliesToDocDueDate; Rec.GetAppliesToDocDueDate())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applies-to Doc. Due Date';
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the due date from the Applies-to Doc. on the journal line.';
                }
                field("Bank Payment Type"; Rec."Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Check Printed"; Rec."Check Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Correction; Rec.Correction)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(CommentField; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    Visible = false;
                }
                field("Exported to Payment File"; Rec."Exported to Payment File")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(TotalExportedAmount; Rec.TotalExportedAmount())
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Exported Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the amount for the payment journal line that has been exported to payment files that are not canceled.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownExportedAmount();
                    end;
                }
                field("Has Payment Export Error"; Rec."Has Payment Export Error")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job Queue Status"; Rec."Job Queue Status")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    Visible = JobQueuesUsed;

                    trigger OnDrillDown()
                    var
                        JobQueueEntry: Record "Job Queue Entry";
                    begin
                        if Rec."Job Queue Status" = Rec."Job Queue Status"::" " then
                            exit;
                        JobQueueEntry.ShowStatusMsg(Rec."Job Queue Entry ID");
                    end;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible2;
                }
                field(ShortcutDimCode3; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 3);
                    end;
                }
                field(ShortcutDimCode4; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 4);
                    end;
                }
                field(ShortcutDimCode5; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 5);
                    end;
                }
                field(ShortcutDimCode6; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 6);
                    end;
                }
                field(ShortcutDimCode7; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 7);
                    end;
                }
                field(ShortcutDimCode8; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 8);
                    end;
                }
                field("Remit-to Code"; Rec."Remit-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                    TableRelation = "Remit Address".Code where("Vendor No." = field("Account No."));
                }
            }
            group(Control24)
            {
                ShowCaption = false;
                fixed(Control1903561801)
                {
                    ShowCaption = false;
                    group("Number of Lines")
                    {
                        Caption = 'Number of Lines';
                        field(NumberOfJournalRecords; NumberOfRecords)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            ShowCaption = false;
                            Editable = false;
                            ToolTip = 'Specifies the number of lines in the current journal batch.';
                        }
                    }
                    group("Account Name")
                    {
                        Caption = 'Account Name';
                        Visible = false;
                        field(AccName; AccName)
                        {
                            ApplicationArea = Basic, Suite;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the name of the account.';
                        }
                    }
                    group("Bal. Account Name")
                    {
                        Caption = 'Bal. Account Name';
                        Visible = false;
                        field(BalAccName; BalAccName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Bal. Account Name';
                            Editable = false;
                            ToolTip = 'Specifies the name of the balancing account that has been entered on the journal line.';
                        }
                    }
                    group(Control1900545401)
                    {
                        Caption = 'Balance';
                        field(Balance; Balance)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Balance';
                            Editable = false;
                            ToolTip = 'Specifies the balance that has accumulated in the payment journal on the line where the cursor is.';
                            Visible = BalanceVisible;
                        }
                    }
                    group("Total Balance")
                    {
                        Caption = 'Total Balance';
                        field(TotalBalance; TotalBalance)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Total Balance';
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
            part(JournalErrorsFactBox; "Journal Errors FactBox")
            {
                ApplicationArea = Basic, Suite;
                Visible = BackgroundErrorCheck;
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "Journal Batch Name" = field("Journal Batch Name"),
                              "Line No." = field("Line No.");
            }
            part(JournalLineDetails; "Journal Line Details FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "Journal Batch Name" = field("Journal Batch Name"),
                              "Line No." = field("Line No.");
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
            }
            part("Payment File Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Payment File Errors';
                SubPageLink = "Journal Template Name" = field("Journal Template Name"),
                              "Journal Batch Name" = field("Journal Batch Name"),
                              "Journal Line No." = field("Line No.");
            }
            part(Control1900919607; "Dimension Set Entries FactBox")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Dimension Set ID" = field("Dimension Set ID");
                Visible = false;
            }
            part(WorkflowStatusBatch; "Workflow Status FactBox")
            {
                ApplicationArea = Suite;
                Caption = 'Batch Workflows';
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatusOnBatch;
            }
            part(WorkflowStatusLine; "Workflow Status FactBox")
            {
                ApplicationArea = Suite;
                Caption = 'Line Workflows';
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatusOnLine;
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
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
                action(IncomingDoc)
                {
                    AccessByPermission = TableData "Incoming Document" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Incoming Document';
                    Image = Document;
                    Scope = Repeater;
                    ToolTip = 'View or create an incoming document record that is linked to the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        Rec.Validate("Incoming Document Entry No.", IncomingDocument.SelectIncomingDocument(Rec."Incoming Document Entry No.", Rec.RecordId()));
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Codeunit "Gen. Jnl.-Show Card";
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    RunObject = Codeunit "Gen. Jnl.-Show Entries";
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
            group("&Payments")
            {
                Caption = '&Payments';
                Image = Payment;
                action(SuggestVendorPayments)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Vendor Payments';
                    Ellipsis = true;
                    Image = SuggestVendorPayments;
                    ToolTip = 'Create payment suggestions as lines in the payment journal.';

                    trigger OnAction()
                    var
                        SuggestVendorPayments: Report "Suggest Vendor Payments";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeSuggestVendorPaymentsAction(Rec, IsHandled);
                        if IsHandled then
                            exit;
                        Clear(SuggestVendorPayments);
                        SuggestVendorPayments.SetGenJnlLine(Rec);
                        SuggestVendorPayments.RunModal();
                    end;
                }
                action(SuggestEmployeePayments)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Suggest Employee Payments';
                    Ellipsis = true;
                    Image = SuggestVendorPayments;
                    ToolTip = 'Create payment suggestions as lines in the payment journal.';

                    trigger OnAction()
                    var
                        SuggestEmployeePayments: Report "Suggest Employee Payments";
                    begin
                        Clear(SuggestEmployeePayments);
                        SuggestEmployeePayments.SetGenJnlLine(Rec);
                        SuggestEmployeePayments.RunModal();
                    end;
                }
                action(PreviewCheck)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&review Check';
                    Image = ViewCheck;
                    RunObject = Page "Check Preview";
                    RunPageLink = "Journal Template Name" = field("Journal Template Name"),
                                  "Journal Batch Name" = field("Journal Batch Name"),
                                  "Line No." = field("Line No.");
                    ToolTip = 'Preview the check before printing it.';
                }
                action(PrintCheck)
                {
                    AccessByPermission = TableData "Check Ledger Entry" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Check';
                    Ellipsis = true;
                    Image = PrintCheck;
                    ToolTip = 'Prepare to print the check.';

                    trigger OnAction()
                    var
                        GenJournalLine: Record "Gen. Journal Line";
                        DocumentPrint: Codeunit "Document-Print";
                    begin
                        GenJournalLine.Reset();
                        GenJournalLine.Copy(Rec);
                        GenJournalLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                        GenJournalLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        DocumentPrint.PrintCheck(GenJournalLine);
                        CODEUNIT.Run(CODEUNIT::"Adjust Gen. Journal Balance", Rec);
                    end;
                }
                group("Electronic Payments")
                {
                    Caption = 'Electronic Payments';
                    Image = ElectronicPayment;
                    action(ExportPaymentsToFile)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'E&xport';
                        Ellipsis = true;
                        Image = ExportFile;
                        ToolTip = 'Export a file with the payment information on the journal lines.';

                        trigger OnAction()
                        var
                            GenJournalLine: Record "Gen. Journal Line";
                            Window: Dialog;
                        begin
                            Rec.CheckIfPrivacyBlocked();

                            Window.Open(GeneratingPaymentsMsg);
                            GenJournalLine.CopyFilters(Rec);
                            if GenJournalLine.FindFirst() then
                                GenJournalLine.ExportPaymentFile();
                            Window.Close();
                        end;
                    }
                    action(VoidPayments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Void';
                        Ellipsis = true;
                        Image = VoidElectronicDocument;
                        ToolTip = 'Void the exported electronic payment file.';

                        trigger OnAction()
                        var
                            GenJournalLine: Record "Gen. Journal Line";
                        begin
                            GenJournalLine.CopyFilters(Rec);
                            if GenJournalLine.FindFirst() then
                                GenJournalLine.VoidPaymentFile();
                        end;
                    }
                    action(TransmitPayments)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Transmit';
                        Ellipsis = true;
                        Image = TransmitElectronicDoc;
                        ToolTip = 'Transmit the exported electronic payment file to the bank.';

                        trigger OnAction()
                        var
                            GenJournalLine: Record "Gen. Journal Line";
                        begin
                            GenJournalLine.CopyFilters(Rec);
                            if GenJournalLine.FindFirst() then
                                GenJournalLine.TransmitPaymentFile();
                        end;
                    }
                }
                action("Void Check")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Void Check';
                    Image = VoidCheck;
                    ToolTip = 'Void the check if, for example, the check is not cashed by the bank.';

                    trigger OnAction()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        Rec.TestField("Bank Payment Type", Rec."Bank Payment Type"::"Computer Check");
                        Rec.TestField("Check Printed", true);
                        if ConfirmManagement.GetResponseOrDefault(StrSubstNo(VoidCheckQst, Rec."Document No."), true) then
                            CheckManagement.VoidCheck(Rec);
                    end;
                }
                action("Void &All Checks")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Void &All Checks';
                    Image = VoidAllChecks;
                    ToolTip = 'Void all checks if, for example, the checks are not cashed by the bank.';

                    trigger OnAction()
                    var
                        GenJournalLine: Record "Gen. Journal Line";
                        GenJournalLine2: Record "Gen. Journal Line";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if ConfirmManagement.GetResponseOrDefault(VoidAllPrintedChecksQst, true) then begin
                            GenJournalLine.Reset();
                            GenJournalLine.Copy(Rec);
                            GenJournalLine.SetRange("Bank Payment Type", Rec."Bank Payment Type"::"Computer Check");
                            GenJournalLine.SetRange("Check Printed", true);
                            if GenJournalLine.Find('-') then
                                repeat
                                    GenJournalLine2 := GenJournalLine;
                                    CheckManagement.VoidCheck(GenJournalLine2);
                                until GenJournalLine.Next() = 0;
                        end;
                    end;
                }
                action(CreditTransferRegEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Transfer Reg. Entries';
                    Image = ExportReceipt;
                    RunObject = Codeunit "Gen. Jnl.-Show CT Entries";
                    ToolTip = 'View or edit the credit transfer entries that are related to file export for credit transfers.';
                }
                action(CreditTransferRegisters)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Transfer Registers';
                    Image = ExportElectronicDocument;
                    RunObject = Page "Credit Transfer Registers";
                    ToolTip = 'View or edit the payment files that have been exported in connection with credit transfers.';
                }
                action(NetCustomerVendorBalances)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Customer/Vendor Balances';
                    Image = Balance;
                    ToolTip = 'Create journal lines to consolidate customer and vendor balances as of a specified date. This is relevant when you do business with a company that is both a customer and a vendor. Depending on which is larger, the balance will be netted for either the payable or receivable amount.';

                    trigger OnAction()
                    var
                        NetCustomerVendorBalances: Report "Net Customer/Vendor Balances";
                    begin
                        NetCustomerVendorBalances.SetGenJnlLine(Rec);
                        NetCustomerVendorBalances.RunModal();
                    end;
                }
            }
            action(Approvals)
            {
                AccessByPermission = TableData "Approval Entry" = R;
                ApplicationArea = Suite;
                Caption = 'Approvals';
                Image = Approvals;
                ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                trigger OnAction()
                var
                    GenJournalLine: Record "Gen. Journal Line";
                    ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                begin
                    GetCurrentlySelectedLines(GenJournalLine);
                    ApprovalsMgmt.ShowJournalApprovalEntries(GenJournalLine);
                end;
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Renumber Document Numbers")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Renumber Document Numbers';
                    Image = EditLines;
                    ToolTip = 'Resort the numbers in the Document No. column to avoid posting errors because the document numbers are not in sequence. Entry applications and line groupings are preserved.';

                    trigger OnAction()
                    begin
                        Rec.RenumberDocumentNo();
                    end;
                }
                action(ApplyEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Entries';
                    Ellipsis = true;
                    Enabled = ApplyEntriesActionEnabled;
                    Image = ApplyEntries;
                    RunObject = Codeunit "Gen. Jnl.-Apply";
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Apply the payment amount on a journal line to a sales or purchase document that was already posted for a customer or vendor. This updates the amount on the posted document, and the document can either be partially paid, or closed as paid or refunded.';
                }
                action(CalculatePostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate Posting Date';
                    Image = CalcWorkCenterCalendar;
                    ToolTip = 'Calculate the date that will appear as the posting date on the journal lines.';

                    trigger OnAction()
                    begin
                        Rec.CalculatePostingDate();
                    end;
                }
                action("Insert Conv. LCY Rndg. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert Conv. LCY Rndg. Lines';
                    Image = InsertCurrency;
                    RunObject = Codeunit "Adjust Gen. Journal Balance";
                    ToolTip = 'Insert a rounding correction line in the journal. This rounding correction line will balance in LCY when amounts in the foreign currency also balance. You can then post the journal.';
                }
                action(PositivePayExport)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Positive Pay Export';
                    Image = Export;
                    ToolTip = 'Export a Positive Pay file that contains vendor information, check number, and payment amount, which you send to the bank to make sure that your bank only clears validated checks and amounts when you process payments.';
                    Visible = false;

                    trigger OnAction()
                    var
                        GenJnlBatch: Record "Gen. Journal Batch";
                        BankAcc: Record "Bank Account";
                    begin
                        GenJnlBatch.Get(Rec."Journal Template Name", CurrentJnlBatchName);
                        if GenJnlBatch."Bal. Account Type" = GenJnlBatch."Bal. Account Type"::"Bank Account" then begin
                            BankAcc."No." := GenJnlBatch."Bal. Account No.";
                            PAGE.Run(PAGE::"Positive Pay Export", BankAcc);
                        end;
                    end;
                }
            }
            group(Errors)
            {
                Image = ErrorLog;
                Visible = BackgroundErrorCheck;
                action(ShowLinesWithErrors)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Lines with Issues';
                    Image = Error;
                    Visible = BackgroundErrorCheck and not ShowAllLinesEnabled;
                    Enabled = not ShowAllLinesEnabled;
                    ToolTip = 'View a list of journal lines that have issues before you post the journal.';

                    trigger OnAction()
                    begin
                        Rec.SwitchLinesWithErrorsFilter(ShowAllLinesEnabled);
                    end;
                }
                action(ShowAllLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show All Lines';
                    Image = ExpandAll;
                    Visible = BackgroundErrorCheck and ShowAllLinesEnabled;
                    Enabled = ShowAllLinesEnabled;
                    ToolTip = 'View all journal lines, including lines with and without issues.';

                    trigger OnAction()
                    begin
                        Rec.SwitchLinesWithErrorsFilter(ShowAllLinesEnabled);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Reconcile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reconcile';
                    Image = Reconcile;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'View the balances on bank accounts that are marked for reconciliation, usually liquid accounts.';

                    trigger OnAction()
                    var
                        GLReconciliation: Page Reconciliation;
                    begin
                        GLReconciliation.SetGenJnlLine(Rec);
                        GLReconciliation.Run();
                    end;
                }
                action(PreCheck)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Pre-Payment Journal';
                    Image = PreviewChecks;
                    ToolTip = 'View journal line entries, payment discounts, discount tolerance amounts, payment tolerance, and any errors associated with the entries. You can use the results of the report to review payment journal lines and to review the results of posting before you actually post.';

                    trigger OnAction()
                    var
                        GenJournalBatch: Record "Gen. Journal Batch";
                    begin
                        GenJournalBatch.Init();
                        GenJournalBatch.SetRange("Journal Template Name", Rec."Journal Template Name");
                        GenJournalBatch.SetRange(Name, Rec."Journal Batch Name");
                        REPORT.Run(REPORT::"Vendor Pre-Payment Journal", true, false, GenJournalBatch);
                    end;
                }
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    var
                        TestReportPrint: Codeunit "Test Report-Print";
                    begin
                        TestReportPrint.PrintGenJnlLine(Rec);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        Rec.SendToPosting(Codeunit::"Gen. Jnl.-Post");
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        SetJobQueueVisibility();
                        CurrPage.Update(false);
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    var
                        GenJnlPost: Codeunit "Gen. Jnl.-Post";
                    begin
                        GenJnlPost.Preview(Rec);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        Rec.SendToPosting(Codeunit::"Gen. Jnl.-Post+Print");
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        SetJobQueueVisibility();
                        CurrPage.Update(false);
                    end;
                }
                action("Remove From Job Queue")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove From Job Queue';
                    Image = RemoveLine;
                    ToolTip = 'Remove the scheduled processing of this record from the job queue.';
                    Visible = JobQueueVisible;

                    trigger OnAction()
                    begin
                        Rec.CancelBackgroundPosting();
                        SetJobQueueVisibility();
                        CurrPage.Update(false);
                    end;
                }
                action(RedistributeAccAllocations)
                {
                    ApplicationArea = All;
                    Caption = 'Redistribute Account Allocations';
                    Image = EditList;
#pragma warning disable AA0219
                    ToolTip = 'Use this action to redistribute the account allocations for this line.';
#pragma warning restore AA0219

                    trigger OnAction()
                    var
                        AllocAccManualOverride: Page "Redistribute Acc. Allocations";
                    begin
                        if (Rec."Account Type" <> Rec."Account Type"::"Allocation Account") and (Rec."Bal. Account Type" <> Rec."Bal. Account Type"::"Allocation Account") and (Rec."Selected Alloc. Account No." = '') then
                            Error(ActionOnlyAllowedForAllocationAccountsErr);
                        AllocAccManualOverride.SetParentSystemId(Rec.SystemId);
                        AllocAccManualOverride.SetParentTableId(Database::"Gen. Journal Line");
                        AllocAccManualOverride.RunModal();
                    end;
                }
                action(ReplaceAllocationAccountWithLines)
                {
                    ApplicationArea = All;
                    Caption = 'Generate lines from Allocation Account Line';
                    Image = CreateLinesFromJob;
#pragma warning disable AA0219
                    ToolTip = 'Use this action to replace the Allocation Account line with the actual lines that would be generated from the line itself.';
#pragma warning restore AA0219

                    trigger OnAction()
                    var
                        BackupRec: Record "Gen. Journal Line";
                        GenJournalAllocAccMgt: Codeunit "Gen. Journal Alloc. Acc. Mgt.";
                    begin
                        if (Rec."Account Type" <> Rec."Account Type"::"Allocation Account") and (Rec."Bal. Account Type" <> Rec."Bal. Account Type"::"Allocation Account") and (Rec."Selected Alloc. Account No." = '') then
                            Error(ActionOnlyAllowedForAllocationAccountsErr);

                        BackupRec.Copy(Rec);
                        BackupRec.SetRecFilter();
                        GenJournalAllocAccMgt.CreateLines(BackupRec);
                        Rec.Delete();
                        CurrPage.Update(false);
                    end;
                }
            }
            group("Request Approval")
            {
                Caption = 'Request Approval';
                group(SendApprovalRequest)
                {
                    Caption = 'Send Approval Request';
                    Image = SendApprovalRequest;
                    action(SendApprovalRequestJournalBatch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch';
                        Enabled = not OpenApprovalEntriesOnBatchOrAnyJnlLineExist and CanRequestFlowApprovalForBatchAndAllLines;
                        Image = SendApprovalRequest;
                        ToolTip = 'Send all journal lines for approval, also those that you may not see because of filters.';

                        trigger OnAction()
                        var
                            ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        begin
                            ApprovalsMgmt.TrySendJournalBatchApprovalRequest(Rec);
                            SetControlAppearanceFromBatch();
                            SetControlAppearance();
                        end;
                    }
                    action(SendApprovalRequestJournalLine)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Selected Journal Lines';
                        Enabled = not OpenApprovalEntriesOnBatchOrCurrJnlLineExist and CanRequestFlowApprovalForBatchAndCurrentLine;
                        Image = SendApprovalRequest;
                        ToolTip = 'Send selected journal lines for approval.';

                        trigger OnAction()
                        var
                            GenJournalLine: Record "Gen. Journal Line";
                            ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        begin
                            GetCurrentlySelectedLines(GenJournalLine);
                            ApprovalsMgmt.TrySendJournalLineApprovalRequests(GenJournalLine);
                        end;
                    }
                }
                group(CancelApprovalRequest)
                {
                    Caption = 'Cancel Approval Request';
                    Image = Cancel;
                    action(CancelApprovalRequestJournalBatch)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Batch';
                        Enabled = CanCancelApprovalForJnlBatch or CanCancelFlowApprovalForBatch;
                        Image = CancelApprovalRequest;
                        ToolTip = 'Cancel sending all journal lines for approval, also those that you may not see because of filters.';

                        trigger OnAction()
                        var
                            ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        begin
                            ApprovalsMgmt.TryCancelJournalBatchApprovalRequest(Rec);
                            SetControlAppearanceFromBatch();
                            SetControlAppearance();
                        end;
                    }
                    action(CancelApprovalRequestJournalLine)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Selected Journal Lines';
                        Enabled = CanCancelApprovalForJnlLine or CanCancelFlowApprovalForLine;
                        Image = CancelApprovalRequest;
                        ToolTip = 'Cancel sending selected journal lines for approval.';

                        trigger OnAction()
                        var
                            GenJournalLine: Record "Gen. Journal Line";
                            ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        begin
                            GetCurrentlySelectedLines(GenJournalLine);
                            ApprovalsMgmt.TryCancelJournalLineApprovalRequests(GenJournalLine);
                        end;
                    }
                }
                group(Flow)
                {
                    Caption = 'Power Automate';
                    Image = Flow;

                    customaction(CreateApprovalFlowFromTemplate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create approval flow';
                        ToolTip = 'Create a new flow in Power Automate from a list of relevant flow templates.';
                        Visible = IsSaaS and IsPowerAutomatePrivacyNoticeApproved;
                        CustomActionType = FlowTemplateGallery;
                        FlowTemplateCategoryName = 'd365bc_approval_generalJournal';
                    }
                }
            }
            group(Workflow)
            {
                Caption = 'Workflow';
                action(CreateApprovalWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Create Approval Workflow';
                    Enabled = not EnabledApprovalWorkflowsExist;
                    Image = CreateWorkflow;
                    ToolTip = 'Set up an approval workflow for payment journal lines, by going through a few pages that will guide you.';

                    trigger OnAction()
                    var
                        TempApprovalWorkflowWizard: Record "Approval Workflow Wizard" temporary;
                    begin
                        TempApprovalWorkflowWizard."Journal Batch Name" := Rec."Journal Batch Name";
                        TempApprovalWorkflowWizard."Journal Template Name" := Rec."Journal Template Name";
                        TempApprovalWorkflowWizard."For All Batches" := false;
                        TempApprovalWorkflowWizard.Insert();

                        PAGE.RunModal(PAGE::"Pmt. App. Workflow Setup Wzrd.", TempApprovalWorkflowWizard);
                    end;
                }
                action(ManageApprovalWorkflows)
                {
                    ApplicationArea = Suite;
                    Caption = 'Manage Approval Workflows';
                    Enabled = EnabledApprovalWorkflowsExist;
                    Image = WorkflowSetup;
                    ToolTip = 'View or edit existing approval workflows for payment journal lines.';

                    trigger OnAction()
                    var
                        WorkflowManagement: Codeunit "Workflow Management";
                    begin
                        WorkflowManagement.NavigateToWorkflows(DATABASE::"Gen. Journal Line", EventFilter);
                    end;
                }
            }
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveGenJournalLineRequest(Rec);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject the approval request.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectGenJournalLineRequest(Rec);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    ToolTip = 'Delegate the approval to a substitute approver.';
                    Visible = OpenApprovalEntriesExistForCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateGenJournalLineRequest(Rec);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';
                    Visible = OpenApprovalEntriesExistForCurrUser or ApprovalEntriesExistSentByCurrentUser;

                    trigger OnAction()
                    var
                        GenJournalBatch: Record "Gen. Journal Batch";
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if OpenApprovalEntriesOnJnlLineExist then
                            ApprovalsMgmt.GetApprovalComment(Rec)
                        else
                            if OpenApprovalEntriesOnJnlBatchExist then
                                if GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then
                                    ApprovalsMgmt.GetApprovalComment(GenJournalBatch);
                    end;
                }
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                    begin
                        ODataUtility.EditJournalWorksheetInExcel(CurrPage.Caption(), CurrPage.ObjectId(false), Rec."Journal Batch Name", Rec."Journal Template Name");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Category8)
                {
                    Caption = 'Post/Print', Comment = 'Generated from the PromotedActionCategories property index 7.';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(Preview_Promoted; Preview)
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                    actionref("Test Report_Promoted"; "Test Report")
                    {
                    }
                }
                actionref("Renumber Document Numbers_Promoted"; "Renumber Document Numbers")
                {
                }
                actionref(ApplyEntries_Promoted; ApplyEntries)
                {
                }
                actionref(Reconcile_Promoted; Reconcile)
                {
                }
                group(ShowLinesWithErrors_Group)
                {
                    ShowAs = SplitButton;
                    Caption = 'Filter lines with issues';

                    actionref(ShowLinesWithErrors_Promoted; ShowLinesWithErrors)
                    {
                    }
                    actionref(ShowAllLines_Promoted; ShowAllLines)
                    {
                    }
                }
            }
            group(Category_Category5)
            {
                Caption = 'Prepare', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(SuggestVendorPayments_Promoted; SuggestVendorPayments)
                {
                }
                actionref(SuggestEmployeePayments_Promoted; SuggestEmployeePayments)
                {
                }
                actionref(NetCustomerVendorBalances_Promoted; NetCustomerVendorBalances)
                {
                }
                actionref(CalculatePostingDate_Promoted; CalculatePostingDate)
                {
                }
            }
            group(Category_Category11)
            {
                Caption = 'Check', Comment = 'Generated from the PromotedActionCategories property index 10.';

                actionref(PrintCheck_Promoted; PrintCheck)
                {
                }
                actionref("Void Check_Promoted"; "Void Check")
                {
                }
                actionref("Void &All Checks_Promoted"; "Void &All Checks")
                {
                }
                actionref(PreviewCheck_Promoted; PreviewCheck)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(Comment_Promoted; Comment)
                {
                }
                actionref(Delegate_Promoted; Delegate)
                {
                }
            }
            group("Category_Request Approval")
            {
                Caption = 'Request Approval';

                group("Category_Send Approval Request")
                {
                    Caption = 'Send Approval Request';

                    actionref(SendApprovalRequestJournalBatch_Promoted; SendApprovalRequestJournalBatch)
                    {
                    }
                    actionref(SendApprovalRequestJournalLine_Promoted; SendApprovalRequestJournalLine)
                    {
                    }
                }
                group("Category_Cancel Approval Request")
                {
                    Caption = 'Cancel Approval Request';

                    actionref(CancelApprovalRequestJournalBatch_Promoted; CancelApprovalRequestJournalBatch)
                    {
                    }
                    actionref(CancelApprovalRequestJournalLine_Promoted; CancelApprovalRequestJournalLine)
                    {
                    }
                }
            }
            group(Category_Category4)
            {
                Caption = 'Bank', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(ExportPaymentsToFile_Promoted; ExportPaymentsToFile)
                {
                }
                actionref(VoidPayments_Promoted; VoidPayments)
                {
                }
                actionref(CreditTransferRegEntries_Promoted; CreditTransferRegEntries)
                {
                }
                actionref(CreditTransferRegisters_Promoted; CreditTransferRegisters)
                {
                }
            }
            group(Category_Category9)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 8.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
                actionref(IncomingDoc_Promoted; IncomingDoc)
                {
                }
            }
            group(Category_Category10)
            {
                Caption = 'Account', Comment = 'Generated from the PromotedActionCategories property index 9.';

            }
            group(Category_Category7)
            {
                Caption = 'Page', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(EditInExcel_Promoted; EditInExcel)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowManagement: Codeunit "Workflow Management";
    begin
        StyleTxt := Rec.GetOverdueDateInteractions(OverdueWarningText);
        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
        UpdateBalance();
        EnableApplyEntriesAction();
        SetControlAppearance();
        SetApprovalStateForBatch();
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);

        if GenJournalBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name") then begin
            ShowWorkflowStatusOnBatch := CurrPage.WorkflowStatusBatch.PAGE.SetFilterOnWorkflowRecord(GenJournalBatch.RecordId);
            IsAllowPaymentExport := GenJournalBatch."Allow Payment Export";
        end;
        ShowWorkflowStatusOnLine := CurrPage.WorkflowStatusLine.PAGE.SetFilterOnWorkflowRecord(Rec.RecordId);

        EventFilter := WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode();
        EnabledApprovalWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(DATABASE::"Gen. Journal Line", EventFilter);
        SetJobQueueVisibility();
        ApprovalMgmt.GetGenJnlBatchApprovalStatus(Rec, GenJnlBatchApprovalStatus, EnabledGenJnlBatchWorkflowsExist);

        OnAfterOnAfterGetRecord(Rec, GenJnlManagement, AccName, BalAccName);
    end;

    trigger OnAfterGetRecord()
    begin
        StyleTxt := Rec.GetOverdueDateInteractions(OverdueWarningText);
        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        HasPmtFileErr := Rec.HasPaymentFileErrors();
        RecipientBankAccountMandatory := IsAllowPaymentExport and
          ((Rec."Bal. Account Type" = Rec."Bal. Account Type"::Vendor) or (Rec."Bal. Account Type" = Rec."Bal. Account Type"::Customer));
        CurrPage.IncomingDocAttachFactBox.PAGE.SetCurrentRecordID(Rec.RecordId);
        ApprovalMgmt.GetGenJnlLineApprovalStatus(Rec, GenJnlLineApprovalStatus, EnabledGenJnlLineWorkflowsExist);
    end;

    trigger OnInit()
    var
        PrivacyNotice: Codeunit "Privacy Notice";
        FlowServiceManagement: Codeunit "Flow Service Management";
    begin
        TotalBalanceVisible := true;
        BalanceVisible := true;
        AmountVisible := true;
        GeneralLedgerSetup.Get();
        IsPowerAutomatePrivacyNoticeApproved := PrivacyNotice.GetPrivacyNoticeApprovalState(FlowServiceManagement.GetPowerAutomatePrivacyNoticeId()) = "Privacy Notice Approval State"::Agreed;

        SetJobQueueVisibility();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.SetCurrentRecordID(Rec.RecordId);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CheckForPmtJnlErrors();
        ApprovalMgmt.CleanGenJournalApprovalStatus(Rec, GenJnlBatchApprovalStatus, GenJnlLineApprovalStatus);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        HasPmtFileErr := false;
        UpdateBalance();
        EnableApplyEntriesAction();
        Rec.SetUpNewLine(xRec, Balance, BelowxRec);
        Clear(ShortcutDimCode);
        Clear(GenJnlLineApprovalStatus);

        OnAfterOnNewRecord(Rec, xRec, GenJnlManagement, AccName, AccName);
    end;

    trigger OnOpenPage()
    var
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
        ServerSetting: Codeunit "Server Setting";
        EnvironmentInformation: Codeunit "Environment Information";
        JnlSelected: Boolean;
    begin
        OnBeforeOnOpenPage(Rec);

        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        IsSaaS := EnvironmentInformation.IsSaaS();
        UseAllocationAccountNumber := AllocationAccountMgt.UseAllocationAccountNoField();

        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;

        BalAccName := '';
        SetControlVisibility();
        SetDimensionsVisibility();

        if Rec.IsOpenedFromBatch() then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            GenJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
            SetControlAppearanceFromBatch();
            exit;
        end;
        GenJnlManagement.TemplateSelection(PAGE::"Payment Journal", Enum::"Gen. Journal Template Type"::Payments, false, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        GenJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
        SetControlAppearanceFromBatch();

        OnAfterOnOpenPage(CurrentJnlBatchName);
    end;

    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        CheckManagement: Codeunit CheckManagement;
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        ApprovalMgmt: Codeunit "Approvals Mgmt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        ChangeExchangeRate: Page "Change Exchange Rate";
        GenJnlBatchApprovalStatus: Text[20];
        GenJnlLineApprovalStatus: Text[20];
        Balance: Decimal;
        TotalBalance: Decimal;
        NumberOfRecords: Integer;
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
        HasPmtFileErr: Boolean;
        BalanceVisible: Boolean;
        TotalBalanceVisible: Boolean;
        IsPostingGroupEditable: Boolean;
        StyleTxt: Text;
        OverdueWarningText: Text;
        EventFilter: Text;
        IsPowerAutomatePrivacyNoticeApproved: Boolean;
        OpenApprovalEntriesExistForCurrUser: Boolean;
        OpenApprovalEntriesExistForCurrUserBatch: Boolean;
        OpenApprovalEntriesOnJnlBatchExist: Boolean;
        OpenApprovalEntriesOnJnlLineExist: Boolean;
        OpenApprovalEntriesOnBatchOrCurrJnlLineExist: Boolean;
        OpenApprovalEntriesOnBatchOrAnyJnlLineExist: Boolean;
        ShowWorkflowStatusOnBatch: Boolean;
        ShowWorkflowStatusOnLine: Boolean;
        CanCancelApprovalForJnlBatch: Boolean;
        CanCancelApprovalForJnlLine: Boolean;
        EnabledApprovalWorkflowsExist: Boolean;
        IsAllowPaymentExport: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;
        RecipientBankAccountMandatory: Boolean;
        CanRequestFlowApprovalForBatch: Boolean;
        CanRequestFlowApprovalForBatchAndAllLines: Boolean;
        CanRequestFlowApprovalForBatchAndCurrentLine: Boolean;
        CanCancelFlowApprovalForBatch: Boolean;
        CanCancelFlowApprovalForLine: Boolean;
        AmountVisible: Boolean;
        IsSaaS: Boolean;
        DebitCreditVisible: Boolean;
        JobQueuesUsed: Boolean;
        JobQueueVisible: Boolean;
        BackgroundErrorCheck: Boolean;
        ShowAllLinesEnabled: Boolean;
        EnabledGenJnlLineWorkflowsExist: Boolean;
        EnabledGenJnlBatchWorkflowsExist: Boolean;
        ApprovalEntriesExistSentByCurrentUser: Boolean;
        UseAllocationAccountNumber: Boolean;
        ActionOnlyAllowedForAllocationAccountsErr: Label 'This action is only available for lines that have Allocation Account set as Account Type or Balancing Account Type.';
        VoidCheckQst: Label 'Void Check %1?', Comment = '%1 - check number';
        VoidAllPrintedChecksQst: Label 'Void all printed checks?';
        GeneratingPaymentsMsg: Label 'Generating Payment file...';
        AmountToApplyMissMatchMsg: Label 'Amount assigned on Apply Entries (%1) is bigger then the amount on the line (%2). System will remove all related Applies-to ID. Do you want to proceed?', Comment = '%1 - Amount to apply, %2 - Amount on the line';

    protected var
        GenJnlManagement: Codeunit GenJnlManagement;
        ShortcutDimCode: array[8] of Code[20];
        CurrentJnlBatchName: Code[10];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;
        ApplyEntriesActionEnabled: Boolean;
        AccName: Text[100];
        BalAccName: Text[100];

    local procedure CheckForPmtJnlErrors()
    var
        BankAccount: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        if HasPmtFileErr then
            if (Rec."Bal. Account Type" = Rec."Bal. Account Type"::"Bank Account") and BankAccount.Get(Rec."Bal. Account No.") then
                if BankExportImportSetup.Get(BankAccount."Payment Export Format") then
                    if BankExportImportSetup."Check Export Codeunit" > 0 then
                        CODEUNIT.Run(BankExportImportSetup."Check Export Codeunit", Rec);
    end;

    /// <summary>
    /// Updates balance amounts and visibility for payment journal display and calculations.
    /// Recalculates balance totals and configures balance field visibility based on current journal settings.
    /// </summary>
    procedure UpdateBalance()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBalance(Rec, xRec, Balance, TotalBalance, ShowBalance, ShowTotalBalance, IsHandled);
        if not IsHandled then
            GenJnlManagement.CalcBalance(
              Rec, xRec, Balance, TotalBalance, ShowBalance, ShowTotalBalance);
        BalanceVisible := ShowBalance;
        TotalBalanceVisible := ShowTotalBalance;
        if ShowTotalBalance then
            NumberOfRecords := Rec.Count();

        OnAfterUpdateBalance(TotalBalanceVisible);
    end;

    local procedure EnableApplyEntriesAction()
    begin
        ApplyEntriesActionEnabled :=
          (Rec."Account Type" in [Rec."Account Type"::Customer, Rec."Account Type"::Vendor, Rec."Account Type"::Employee]) or
          (Rec."Bal. Account Type" in [Rec."Bal. Account Type"::Customer, Rec."Bal. Account Type"::Vendor, Rec."Bal. Account Type"::Employee]);

        OnAfterEnableApplyEntriesAction(Rec, ApplyEntriesActionEnabled);
    end;

    protected procedure CurrentJnlBatchNameOnAfterValidate()
    begin
        CurrPage.SaveRecord();
        GenJnlManagement.SetName(CurrentJnlBatchName, Rec);
        SetControlAppearanceFromBatch();
        CurrPage.Update(false);
    end;

    local procedure GetCurrentlySelectedLines(var GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        CurrPage.SetSelectionFilter(GenJournalLine);
        exit(GenJournalLine.FindSet());
    end;

    /// <summary>
    /// Sets control appearance and visibility based on current journal batch configuration.
    /// Configures page controls and field visibility according to batch settings and journal template properties.
    /// </summary>
    procedure SetControlAppearanceFromBatch()
    begin
        SetApprovalStateForBatch();
        BackgroundErrorCheck := BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled();
        ShowAllLinesEnabled := true;
        Rec.SwitchLinesWithErrorsFilter(ShowAllLinesEnabled);
        JournalErrorsMgt.SetFullBatchCheck(true);
    end;

    internal procedure SetApprovalStateForBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        CanRequestFlowApprovalForAllLines: Boolean;
    begin
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;

        if not GenJournalBatch.Get(Rec.GetRangeMax("Journal Template Name"), CurrentJnlBatchName) then
            exit;

        CheckOpenApprovalEntries(GenJournalBatch.RecordId);

        CanCancelApprovalForJnlBatch := ApprovalsMgmt.CanCancelApprovalForRecord(GenJournalBatch.RecordId);

        WorkflowWebhookManagement.GetCanRequestAndCanCancelJournalBatch(
          GenJournalBatch, CanRequestFlowApprovalForBatch, CanCancelFlowApprovalForBatch, CanRequestFlowApprovalForAllLines);
        CanRequestFlowApprovalForBatchAndAllLines := CanRequestFlowApprovalForBatch and CanRequestFlowApprovalForAllLines;
        ApprovalEntriesExistSentByCurrentUser := ApprovalsMgmt.HasApprovalEntriesSentByCurrentUser(GenJournalBatch.RecordId) or ApprovalsMgmt.HasApprovalEntriesSentByCurrentUser(Rec.RecordId);

        EnabledGenJnlLineWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(DATABASE::"Gen. Journal Line", WorkflowEventHandling.RunWorkflowOnSendGeneralJournalLineForApprovalCode());
        EnabledGenJnlBatchWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(DATABASE::"Gen. Journal Batch", WorkflowEventHandling.RunWorkflowOnSendGeneralJournalBatchForApprovalCode());

        OnAfterSetControlAppearanceFromBatch(Rec, GenJournalBatch);
    end;

    local procedure CheckOpenApprovalEntries(BatchRecordId: RecordID)
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        OpenApprovalEntriesExistForCurrUserBatch := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(BatchRecordId);

        OpenApprovalEntriesOnJnlBatchExist := ApprovalsMgmt.HasOpenApprovalEntries(BatchRecordId);

        OpenApprovalEntriesOnBatchOrAnyJnlLineExist :=
          OpenApprovalEntriesOnJnlBatchExist or
          ApprovalsMgmt.HasAnyOpenJournalLineApprovalEntries(Rec."Journal Template Name", Rec."Journal Batch Name");
    end;

    local procedure SetControlAppearance()
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
        CanRequestFlowApprovalForLine: Boolean;
    begin
        OpenApprovalEntriesExistForCurrUser :=
          OpenApprovalEntriesExistForCurrUserBatch or ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);

        OpenApprovalEntriesOnJnlLineExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);
        OpenApprovalEntriesOnBatchOrCurrJnlLineExist := OpenApprovalEntriesOnJnlBatchExist or OpenApprovalEntriesOnJnlLineExist;

        CanCancelApprovalForJnlLine := ApprovalsMgmt.CanCancelApprovalForRecord(Rec.RecordId);

        WorkflowWebhookManagement.GetCanRequestAndCanCancel(Rec.RecordId, CanRequestFlowApprovalForLine, CanCancelFlowApprovalForLine);
        CanRequestFlowApprovalForBatchAndCurrentLine := CanRequestFlowApprovalForBatch and CanRequestFlowApprovalForLine;
    end;

    local procedure SetControlVisibility()
    begin
        GeneralLedgerSetup.GetRecordOnce();
        AmountVisible := not (GeneralLedgerSetup."Show Amounts" = GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");
        DebitCreditVisible := not (GeneralLedgerSetup."Show Amounts" = GeneralLedgerSetup."Show Amounts"::"Amount Only");

        PurchasesPayablesSetup.GetRecordOnce();
        IsPostingGroupEditable := PurchasesPayablesSetup."Allow Multiple Posting Groups";
    end;

    local procedure SetDimensionsVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimensionManagement.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimensionManagement);
    end;

    local procedure SetJobQueueVisibility()
    begin
        JobQueueVisible := Rec."Job Queue Status" = Rec."Job Queue Status"::"Scheduled for Posting";
        JobQueuesUsed := GeneralLedgerSetup.JobQueueActive();
    end;

    local procedure CheckAmountMatchedToAppliedLines()
    var
        VendorLedgerEntryMarkedToApply: Record "Vendor Ledger Entry";
        CustLedgEntryMarkedToApply: Record "Cust. Ledger Entry";
        CustEntrySetApplId: Codeunit "Cust. Entry-SetAppl.ID";
        VendEntrySetApplId: Codeunit "Vend. Entry-SetAppl.ID";
        SmallestLineAmountToApply: Decimal;
        JournalAmount: Decimal;
        AmountToApply: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        CurrPage.SaveRecord();
        OnBeforeCheckAmountMatchedToAppliedLines(Rec, IsHandled);
        if isHandled then
            exit;

        if Rec."Document Type" <> Rec."Document Type"::"Payment" then
            exit;

        if not (((xRec.Amount <> 0) and (xRec.Amount <> Rec.Amount) and (Rec.Amount <> 0))
            or ((xRec."Amount (LCY)" <> 0) and (xRec."Amount (LCY)" <> Rec."Amount (LCY)") and (Rec."Amount (LCY)" <> 0))) then
            if AmountZeroConfirmation() then
                exit;

        AmountToApply := 0;
        SmallestLineAmountToApply := 0;

        case Rec."Account Type" of
            Rec."Account Type"::Customer:
                begin
                    JournalAmount := -Rec.Amount;
                    CustLedgEntryMarkedToApply.Reset();
                    CustLedgEntryMarkedToApply.SetLoadFields("Applies-to ID", "Amount to Apply", "Accepted Pmt. Disc. Tolerance", "Accepted Payment Tolerance");
                    CustLedgEntryMarkedToApply.SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive, "Due Date");
                    CustLedgEntryMarkedToApply.SetRange("Customer No.", Rec."Account No.");
                    CustLedgEntryMarkedToApply.SetRange("Applies-to ID", Rec."Applies-to ID");
                    if CustLedgEntryMarkedToApply.FindSet() then
                        repeat
                            if SmallestLineAmountToApply = 0 then
                                SmallestLineAmountToApply := CustLedgEntryMarkedToApply."Amount to Apply"
                            else
                                if SmallestLineAmountToApply > CustLedgEntryMarkedToApply."Amount to Apply" then
                                    SmallestLineAmountToApply := CustLedgEntryMarkedToApply."Amount to Apply";
                            AmountToApply += CustLedgEntryMarkedToApply."Amount to Apply";
                        until CustLedgEntryMarkedToApply.Next() = 0;
                end;
            Rec."Account Type"::Vendor:
                begin
                    JournalAmount := Rec.Amount;
                    VendorLedgerEntryMarkedToApply.Reset();
                    VendorLedgerEntryMarkedToApply.SetLoadFields("Applies-to ID", "Amount to Apply");
                    VendorLedgerEntryMarkedToApply.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
                    VendorLedgerEntryMarkedToApply.SetRange("Vendor No.", Rec."Account No.");
                    VendorLedgerEntryMarkedToApply.SetRange("Applies-to ID", Rec."Applies-to ID");
                    if VendorLedgerEntryMarkedToApply.FindSet() then
                        repeat
                            if SmallestLineAmountToApply = 0 then
                                SmallestLineAmountToApply := -VendorLedgerEntryMarkedToApply."Amount to Apply"
                            else
                                if SmallestLineAmountToApply > -VendorLedgerEntryMarkedToApply."Amount to Apply" then
                                    SmallestLineAmountToApply := -VendorLedgerEntryMarkedToApply."Amount to Apply";
                            AmountToApply -= VendorLedgerEntryMarkedToApply."Amount to Apply";
                        until VendorLedgerEntryMarkedToApply.Next() = 0;
                end;
        end;

        if AmountToApply = 0 then
            exit;

        if AmountToApply <= JournalAmount then
            exit;

        if (AmountToApply - JournalAmount) < SmallestLineAmountToApply then
            exit;

        if not Confirm(AmountToApplyMissMatchMsg, false, AmountToApply, JournalAmount) then
            Error('');

        case Rec."Account Type" of
            Rec."Account Type"::Customer:
                begin
                    CustEntrySetApplId.RemoveApplId(CustLedgEntryMarkedToApply, Rec."Applies-to ID");
                    Rec.Validate("Applies-to ID", '');
                end;
            Rec."Account Type"::Vendor:
                begin
                    VendEntrySetApplId.RemoveApplId(VendorLedgerEntryMarkedToApply, Rec."Applies-to ID");
                    Rec.Validate("Applies-to ID", '');
                end;
        end;
    end;

    local procedure AmountZeroConfirmation(): Boolean
    begin
        if (xRec."Applies-to ID" <> '') then
            if not Confirm(AmountToApplyMissMatchMsg, false, xRec.Amount, Rec.Amount) then
                Error('');

        exit(true);
    end;

    /// <summary>
    /// Integration event raised after retrieving record information during OnAfterGetRecord trigger.
    /// Enables custom processing of journal line data after standard record retrieval and field population.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record that was retrieved and processed.</param>
    /// <param name="GenJnlManagement">Journal management codeunit used for record processing.</param>
    /// <param name="AccName">Account name populated from account number lookup.</param>
    /// <param name="BalAccName">Balancing account name populated from balancing account number lookup.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterOnAfterGetRecord(var GenJournalLine: Record "Gen. Journal Line"; var GenJnlManagement: Codeunit GenJnlManagement; var AccName: Text[100]; var BalAccName: Text[100])
    begin
    end;

    /// <summary>
    /// Integration event raised after opening the payment journal page.
    /// Enables custom initialization and setup logic after standard page opening procedures.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Current journal batch name that was opened.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var CurrentJnlBatchName: Code[10])
    begin
    end;

    /// <summary>
    /// Integration event raised after creating a new journal line record during OnNewRecord trigger.
    /// Enables custom initialization of new journal line fields and default values.
    /// </summary>
    /// <param name="GenJournalLine">New journal line record that was created.</param>
    /// <param name="xGenJournalLine">Previous journal line record used for reference.</param>
    /// <param name="GenJnlManagement">Journal management codeunit used for record initialization.</param>
    /// <param name="AccName">Account name variable for account lookup display.</param>
    /// <param name="BalAccName">Balancing account name variable for balancing account lookup display.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterOnNewRecord(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var GenJnlManagement: Codeunit GenJnlManagement; var AccName: Text[100]; var BalAccName: Text[100])
    begin
    end;

    /// <summary>
    /// Integration event raised after updating balance calculations and visibility for payment journal.
    /// Enables custom balance display logic and total balance visibility control.
    /// </summary>
    /// <param name="TotalBalanceVisible">Boolean indicating if total balance should be visible (can be modified).</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateBalance(var TotalBalanceVisible: Boolean);
    begin
    end;

    /// <summary>
    /// Integration event raised after validating shortcut dimension code changes for payment journal lines.
    /// Enables custom processing after dimension validation and dimension set updates.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record for which shortcut dimension was validated.</param>
    /// <param name="ShortcutDimCode">Array of shortcut dimension codes with updated values.</param>
    /// <param name="DimIndex">Index indicating which shortcut dimension was validated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; var ShortcutDimCode: array[8] of Code[20]; DimIndex: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised before opening the payment journal page.
    /// Enables custom setup and initialization logic before standard page opening procedures.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record providing context for page opening.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before updating balance calculations for payment journal.
    /// Enables custom balance calculation logic and modification of balance values.
    /// </summary>
    /// <param name="GenJournalLine">Current journal line record for balance calculation.</param>
    /// <param name="xGenJournalLine">Previous version of journal line record for comparison.</param>
    /// <param name="Balance">Current balance amount (can be modified).</param>
    /// <param name="TotalBalance">Total balance amount (can be modified).</param>
    /// <param name="ShowBalance">Boolean indicating if balance should be shown (can be modified).</param>
    /// <param name="ShowTotalBalance">Boolean indicating if total balance should be shown (can be modified).</param>
    /// <param name="IsHandled">Set to true to skip standard balance update logic.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateBalance(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var Balance: Decimal; var TotalBalance: Decimal; var ShowBalance: Boolean; var ShowTotalBalance: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after enabling or disabling apply entries action for payment journal.
    /// Enables custom control of apply entries action availability based on journal line context.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record providing context for apply entries action.</param>
    /// <param name="ApplyEntriesActionEnabled">Boolean indicating if apply entries action should be enabled (can be modified).</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterEnableApplyEntriesAction(GenJournalLine: Record "Gen. Journal Line"; var ApplyEntriesActionEnabled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after validating account number for payment journal line.
    /// Enables custom processing after account number validation and balance updates.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record for which account number was validated.</param>
    /// <param name="LastGenJournalLine">Previous journal line record used for comparison and calculations.</param>
    /// <param name="Balance">Current balance amount after account validation.</param>
    /// <param name="TotalBalance">Total balance amount after account validation.</param>
    /// <param name="ShowBalance">Boolean indicating if balance should be shown.</param>
    /// <param name="ShowTotalBalance">Boolean indicating if total balance should be shown.</param>
    /// <param name="BalanceVisible">Boolean indicating if balance field should be visible.</param>
    /// <param name="TotalBalanceVisible">Boolean indicating if total balance field should be visible.</param>
    /// <param name="NumberOfRecords">Count of records in the current journal batch.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateAccountNo(var GenJournalLine: Record "Gen. Journal Line"; LastGenJournalLine: Record "Gen. Journal Line"; var Balance: Decimal; var TotalBalance: Decimal; var ShowBalance: Boolean; var ShowTotalBalance: Boolean; var BalanceVisible: Boolean; var TotalBalanceVisible: Boolean; var NumberOfRecords: Integer)
    begin
    end;

    /// <summary>
    /// Integration event raised after setting control appearance based on journal batch configuration.
    /// Enables custom control appearance and field visibility logic after batch-specific settings are applied.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record providing context for control appearance.</param>
    /// <param name="GenJournalBatch">Journal batch record with settings used for control configuration.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterSetControlAppearanceFromBatch(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting control appearance during journal batch name lookup.
    /// Enables custom control configuration after batch lookup and selection processes.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Current journal batch name after lookup and selection.</param>
    [IntegrationEvent(false, false)]
    local procedure OnLookupCurrentJnlBatchNameOnAfterSetControlAppearanceFromBatch(CurrentJnlBatchName: Code[10])
    begin
    end;

    /// <summary>
    /// Integration event raised after validating current journal batch name changes.
    /// Enables custom processing after batch name validation and batch switching operations.
    /// </summary>
    /// <param name="CurrentJnlBatchName">Current journal batch name that was validated and set.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCurrentJnlBatchName(CurrentJnlBatchName: Code[10])
    begin
    end;

    /// <summary>
    /// Integration event raised before executing suggest vendor payments action in payment journal.
    /// Enables custom logic to override or extend standard vendor payment suggestion functionality.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record providing context for payment suggestion.</param>
    /// <param name="IsHanlded">Set to true to skip standard vendor payment suggestion logic.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeSuggestVendorPaymentsAction(var GenJournalLine: Record "Gen. Journal Line"; var IsHanlded: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before checking if payment amounts match applied ledger entries.
    /// Enables custom validation logic for payment application amount matching.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record being validated for amount matching.</param>
    /// <param name="IsHanlded">Set to true to skip standard amount matching validation logic.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckAmountMatchedToAppliedLines(var GenJournalLine: Record "Gen. Journal Line"; var IsHanlded: Boolean)
    begin
    end;
}