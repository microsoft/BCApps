// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Reporting;
using Microsoft.Utilities;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Threading;

/// <summary>
/// Recurring general journal page for entering automated recurring transactions with various recurring methods.
/// Provides specialized interface for setting up recurring entries including fixed, variable, and balance-based methods.
/// </summary>
/// <remarks>
/// Specialized recurring journal interface for automated periodic transaction generation.
/// Supports all recurring methods: Fixed, Variable, Balance, Reversing variants, and dimension-based balancing.
/// Key capabilities: Recurring frequency setup, allocation support, automated reversal entries, balance calculations.
/// Integration: Automated posting via job queue, recurring method processing, dimension allocation support.
/// </remarks>
page 283 "Recurring General Journal"
{
    AdditionalSearchTerms = 'accruals';
    ApplicationArea = Suite, FixedAssets;
    AutoSplitKey = true;
    Caption = 'Recurring General Journals';
    DataCaptionExpression = Rec.DataCaption();
    DelayedInsert = true;
    PageType = Worksheet;
    AboutTitle = 'About Recurring General Journals';
    AboutText = 'Automate and manage recurring general journal entries for transactions such as rent, subscriptions, or accruals by defining posting frequency, allocation rules, expiration dates, and reversal methods to streamline regular financial processes.';
    SaveValues = true;
    SourceTable = "Gen. Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Suite;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    GenJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                    SetControlAppearanceFromBatch();
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    GenJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Recurring Method"; Rec."Recurring Method")
                {
                    ApplicationArea = Suite;

                    trigger OnValidate()
                    begin
                        IsDimensionBalanceLine();
                    end;
                }
                field("Recurring Frequency"; Rec."Recurring Frequency")
                {
                    ApplicationArea = Suite;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                }
                field("VAT Reporting Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                    Editable = VATDateEnabled;
                    Visible = VATDateEnabled;
                    ToolTip = 'Specifies the date used to include entries on VAT reports in a VAT period. This is either the date that the document was created or posted, depending on your setting on the General Ledger Setup page.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Suite;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Suite;

                    trigger OnValidate()
                    var
                        GenJournalAllocAccMgt: Codeunit "Gen. Journal Alloc. Acc. Mgt.";
                    begin
                        GenJournalAllocAccMgt.PreventAllocationAccountsFromThisPage(Rec."Account Type");
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                        CurrPage.SaveRecord();
                    end;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Suite;

                    trigger OnValidate()
                    begin
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        CurrPage.SaveRecord();
                    end;
                }
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("FA Posting Type"; Rec."FA Posting Type")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field("Business Unit Code"; Rec."Business Unit Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
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
                    Visible = false;

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
                    ApplicationArea = Suite;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this vendor with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
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
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Suite;
                    Visible = AmountVisible;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount in local currency (including VAT) that the journal line consists of.';
                    Visible = AmountVisible;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Suite;
                    Visible = DebitCreditVisible;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Suite;
                    Visible = DebitCreditVisible;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("VAT Difference"; Rec."VAT Difference")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("On Hold"; Rec."On Hold")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Bank Payment Type"; Rec."Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Allocated Amt. (LCY)"; Rec."Allocated Amt. (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount that has been allocated when you have used the Allocations function in the Gen. Jnl. Allocation table.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        GenJnlAlloc.Reset();
                        GenJnlAlloc.SetRange("Journal Template Name", Rec."Journal Template Name");
                        GenJnlAlloc.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        GenJnlAlloc.SetRange("Journal Line No.", Rec."Line No.");
                        PAGE.RunModal(PAGE::Allocations, GenJnlAlloc);
                        CurrPage.Update(false);
                    end;
                }
                field("Bill-to/Pay-to No."; Rec."Bill-to/Pay-to No.")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Ship-to/Order Address Code"; Rec."Ship-to/Order Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = Suite;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    Visible = false;
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

                    trigger OnValidate()
                    begin
                        Rec.CheckShortcutDimCodeRecurringMethod(Rec."Shortcut Dimension 1 Code");
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible2;

                    trigger OnValidate()
                    begin
                        Rec.CheckShortcutDimCodeRecurringMethod(Rec."Shortcut Dimension 2 Code");
                    end;
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
                        Rec.CheckShortcutDimCodeRecurringMethod(ShortcutDimCode[3]);
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
                        Rec.CheckShortcutDimCodeRecurringMethod(ShortcutDimCode[4]);
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
                        Rec.CheckShortcutDimCodeRecurringMethod(ShortcutDimCode[5]);
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
                        Rec.CheckShortcutDimCodeRecurringMethod(ShortcutDimCode[6]);
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
                        Rec.CheckShortcutDimCodeRecurringMethod(ShortcutDimCode[7]);
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
                        Rec.CheckShortcutDimCodeRecurringMethod(ShortcutDimCode[8]);
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);

                        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, 8);
                    end;
                }
                field("Reverse Date Calculation"; Rec."Reverse Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
            group(Control28)
            {
                ShowCaption = false;
                fixed(Control1902205001)
                {
                    ShowCaption = false;
                    group("Account Name")
                    {
                        Caption = 'Account Name';
                        Visible = false;
                        field(AccName; AccName)
                        {
                            ApplicationArea = Suite;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the name of the account.';
                        }
                    }
                    group("Number of Lines")
                    {
                        Caption = 'Number of Lines';
                        field(NumberOfJournalRecords; NumberOfRecords)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Number of Lines';
                            ShowCaption = false;
                            Editable = false;
                            ToolTip = 'Specifies the number of lines in the current journal batch.';
                        }
                    }
                    group(Control1903866901)
                    {
                        Caption = 'Balance';
                        field(Balance; Balance)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Balance';
                            Editable = false;
                            ToolTip = 'Specifies the balance that has accumulated in the recurring general journal on the line where the cursor is.';
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
                            ToolTip = 'Specifies the total balance in the recurring general journal.';
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
                ShowFilter = false;
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
                action(Allocations)
                {
                    ApplicationArea = Suite;
                    Caption = 'Allocations';
                    Image = Allocations;
                    RunObject = Page Allocations;
                    RunPageLink = "Journal Template Name" = field("Journal Template Name"),
                                  "Journal Batch Name" = field("Journal Batch Name"),
                                  "Journal Line No." = field("Line No.");
                    ToolTip = 'Allocate the amount on the selected journal line to the accounts that you specify.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    Enabled = not DimensionBalanceLine;
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history. The action is disabled for BD Balance by Dimension and RBD Reversing Balance by Dimension recurring methods.';

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
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Codeunit "Gen. Jnl.-Show Card";
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    RunObject = Codeunit "Gen. Jnl.-Show Entries";
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Insert Conv. LCY Rndg. Lines")
                {
                    ApplicationArea = Suite;
                    Caption = 'Insert Conv. LCY Rndg. Lines';
                    Image = InsertCurrency;
                    RunObject = Codeunit "Adjust Gen. Journal Balance";
                    ToolTip = 'Insert a rounding correction line in the journal. This rounding correction line will balance in LCY when amounts in the foreign currency also balance. You can then post the journal.';
                }
                action(SetDimFilters)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Image = Filter;
                    Enabled = DimensionBalanceLine;
                    ToolTip = 'Set a filter that can be used with the BD Balance by Dimension or RBD Reversing Balance by Dimension recurring methods. When applied, it will get the balance by dimensions from general ledger entries. The action is disabled for all recurring methods except BD Balance by Dimension and RBD Reversing Balance by Dimension options.';

                    trigger OnAction()
                    begin
                        Rec.ShowRecurringDimFilter();
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintGenJnlLine(Rec);
                    end;
                }
                action(Post)
                {
                    ApplicationArea = Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    var
                    begin
                        Rec.SendToPosting(Codeunit::"Gen. Jnl.-Post");
                        CurrPage.Update(false);
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = Suite;
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
                    ApplicationArea = Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    RunObject = Codeunit "Gen. Jnl.-Post+Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';
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
                        ODataUtility.EditJournalWorksheetInExcel(CopyStr(CurrPage.Caption, 1, 240), CurrPage.ObjectId(false), Rec."Journal Batch Name", Rec."Journal Template Name");
                    end;
                }
                group(Errors)
                {
                    Caption = 'Issues';
                    Image = ErrorLog;
                    Visible = BackgroundErrorCheck;
                    action(ShowLinesWithErrors)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Lines with Issues';
                        Image = Error;
                        Visible = BackgroundErrorCheck;
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
                        Visible = BackgroundErrorCheck;
                        Enabled = ShowAllLinesEnabled;
                        ToolTip = 'View all journal lines, including lines with and without issues.';

                        trigger OnAction()
                        begin
                            Rec.SwitchLinesWithErrorsFilter(ShowAllLinesEnabled);
                        end;
                    }
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                group(Category_Category4)
                {
                    Caption = 'Post/Print', Comment = 'Generated from the PromotedActionCategories property index 3.';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(Preview_Promoted; Preview)
                    {
                    }
                    actionref("Test Report_Promoted"; "Test Report")
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                }
                actionref(Allocations_Promoted; Allocations)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(SetDimFilters_Promoted; SetDimFilters)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Account', Comment = 'Generated from the PromotedActionCategories property index 5.';

            }
            group(Category_Category7)
            {
                Caption = 'Page', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(EditInExcel_Promoted; EditInExcel)
                {
                }
                actionref(ShowLinesWithErrors_Promoted; ShowLinesWithErrors)
                {
                }
                actionref(ShowAllLines_Promoted; ShowAllLines)
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
    begin
        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
        UpdateBalance();
        CurrPage.IncomingDocAttachFactBox.PAGE.SetCurrentRecordID(Rec.RecordId);
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
        SetJobQueueVisibility();
        IsDimensionBalanceLine();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        TotalBalanceVisible := true;
        BalanceVisible := true;
        AmountVisible := true;
        GeneralLedgerSetup.Get();
        SetJobQueueVisibility();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateBalance();
        Rec.SetUpNewLine(xRec, Balance, BelowxRec);
        Clear(ShortcutDimCode);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage.IncomingDocAttachFactBox.PAGE.SetCurrentRecordID(Rec.RecordId);
    end;

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        OnBeforeOnOpenPage();

        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();

        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;

        SetControlVisibility();
        SetDimensionsVisibility();
        SetControlAppearanceFromBatch();

        if Rec.IsOpenedFromBatch() then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            GenJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
            exit;
        end;

        SelectJournalWithError();
        GenJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
        OnAfterOnOpenPage(CurrentJnlBatchName);
    end;

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        ReportPrint: Codeunit "Test Report-Print";
        ClientTypeManagement: Codeunit "Client Type Management";
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        BackgroundErrorHandlingMgt: Codeunit "Background Error Handling Mgt.";
        ChangeExchangeRate: Page "Change Exchange Rate";
        Balance: Decimal;
        TotalBalance: Decimal;
        NumberOfRecords: Integer;
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
        BalanceVisible: Boolean;
        TotalBalanceVisible: Boolean;
        AmountVisible: Boolean;
        DebitCreditVisible: Boolean;
        JobQueuesUsed: Boolean;
        JobQueueVisible: Boolean;
        DimensionBalanceLine: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;
        VATDateEnabled: Boolean;
        BackgroundErrorCheck: Boolean;
        ShowAllLinesEnabled: Boolean;

    protected var
        GenJnlManagement: Codeunit GenJnlManagement;
        CurrentJnlBatchName: Code[10];
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;
        AccName: Text[100];
        BalAccName: Text[100];

    local procedure UpdateBalance()
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
    end;

    local procedure SelectJournalWithError()
    var
        JnlSelected: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectJournalWithError(CurrentJnlBatchName, GenJnlManagement, IsHandled);
        if IsHandled then
            exit;

        GenJnlManagement.TemplateSelection(PAGE::"Recurring General Journal", "Gen. Journal Template Type"::General, true, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        GenJnlManagement.SetName(CurrentJnlBatchName, Rec);
        SetControlAppearanceFromBatch();
        CurrPage.Update(false);
    end;

    local procedure SetControlAppearanceFromBatch()
    begin
        BackgroundErrorCheck := BackgroundErrorHandlingMgt.BackgroundValidationFeatureEnabled();
        ShowAllLinesEnabled := true;
        Rec.SwitchLinesWithErrorsFilter(ShowAllLinesEnabled);
        JournalErrorsMgt.SetFullBatchCheck(true);
    end;

    local procedure SetControlVisibility()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        AmountVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Debit/Credit Only");
        DebitCreditVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Amount Only");
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;

    local procedure SetJobQueueVisibility()
    begin
        JobQueueVisible := Rec."Job Queue Status" = Rec."Job Queue Status"::"Scheduled for Posting";
        JobQueuesUsed := GeneralLedgerSetup.JobQueueActive();
    end;

    local procedure IsDimensionBalanceLine()
    begin
        DimensionBalanceLine := Rec."Recurring Method" in [Rec."Recurring Method"::"BD Balance by Dimension", Rec."Recurring Method"::"RBD Reversing Balance by Dimension"];
    end;

    /// <summary>
    /// Integration event that occurs after validating shortcut dimension codes in the recurring journal.
    /// Allows custom processing of dimension validation for recurring journal entries.
    /// </summary>
    /// <param name="GenJournalLine">The journal line being validated for dimension codes.</param>
    /// <param name="ShortcutDimCode">Array of shortcut dimension codes being validated.</param>
    /// <param name="DimIndex">Index of the dimension code being validated (1-8).</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var GenJournalLine: Record "Gen. Journal Line"; var ShortcutDimCode: array[8] of Code[20]; DimIndex: Integer)
    begin
    end;

    /// <summary>
    /// Integration event that occurs before selecting a journal batch when an error occurs.
    /// Allows custom handling of journal batch selection errors during recurring journal operations.
    /// </summary>
    /// <param name="CurrentJnlBatchName">The current journal batch name being processed.</param>
    /// <param name="GenJnlManagement">General journal management codeunit for batch operations.</param>
    /// <param name="IsHandled">Set to true to skip standard error handling for journal selection.</param>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeSelectJournalWithError(var CurrentJnlBatchName: Code[10]; GenJnlManagement: Codeunit GenJnlManagement; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that occurs after opening the recurring general journal page.
    /// Allows custom initialization and setup after the page is loaded and batches are selected.
    /// </summary>
    /// <param name="CurrentJnlBatchName">The current journal batch name after page opening.</param>
    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var CurrentJnlBatchName: Code[10])
    begin
    end;

    /// <summary>
    /// Integration event that occurs before opening the recurring general journal page initialization.
    /// Allows custom processing before standard page opening procedures for recurring journals.
    /// </summary>
    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage()
    begin
    end;

    /// <summary>
    /// Integration event that occurs before updating balance display for recurring journal lines.
    /// Allows customization of balance calculation and display behavior in recurring journals.
    /// </summary>
    /// <param name="GenJournalLine">The journal line being processed for balance update.</param>
    /// <param name="xGenJournalLine">The previous version of the journal line for comparison.</param>
    /// <param name="Balance">Current balance amount to be displayed.</param>
    /// <param name="TotalBalance">Total balance amount across all lines.</param>
    /// <param name="ShowBalance">Boolean indicating whether to show balance information.</param>
    /// <param name="ShowTotalBalance">Boolean indicating whether to show total balance information.</param>
    /// <param name="IsHandled">Set to true to skip standard balance update processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBalance(var GenJournalLine: Record "Gen. Journal Line"; xGenJournalLine: Record "Gen. Journal Line"; var Balance: Decimal; var TotalBalance: Decimal; var ShowBalance: Boolean; var ShowTotalBalance: Boolean; var IsHandled: Boolean)
    begin
    end;
}
