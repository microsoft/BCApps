// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Reporting;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Posting;

page 289 "Recurring Job Jnl."
{
    AdditionalSearchTerms = 'Recurring Job Journal';
    ApplicationArea = Jobs;
    AutoSplitKey = true;
    Caption = 'Recurring Project Journal';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Job Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Jobs;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    JobJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    JobJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Recurring Method"; Rec."Recurring Method")
                {
                    ApplicationArea = Jobs;
                }
                field("Recurring Frequency"; Rec."Recurring Frequency")
                {
                    ApplicationArea = Jobs;
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Jobs;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project.';

                    trigger OnValidate()
                    begin
                        JobJnlManagement.GetNames(Rec, JobDescription, AccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Jobs;

                    trigger OnValidate()
                    begin
                        JobJnlManagement.GetNames(Rec, JobDescription, AccName);
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;

                    trigger OnValidate()
                    begin
                        JobJnlManagement.GetNames(Rec, JobDescription, AccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
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
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = true;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to (when applicable).';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Jobs;
                }
                field("Direct Unit Cost (LCY)"; Rec."Direct Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost, in the local currency, of one unit of the selected item or resource.';
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Jobs;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                }
                field("Total Cost"; Rec."Total Cost")
                {
                    ApplicationArea = Jobs;
                }
                field("Total Cost (LCY)"; Rec."Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total cost for this journal line. The amount is in the local currency.';
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Jobs;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Jobs;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Jobs;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Jobs;
                }
                field("Total Price"; Rec."Total Price")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Unit Price (LCY)"; Rec."Unit Price (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the price, in LCY, of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                    Visible = false;
                }
                field("Total Price (LCY)"; Rec."Total Price (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total price for the journal line. The amount is in the local currency.';
                    Visible = false;
                }
                field("Applies-to Entry"; Rec."Applies-to Entry")
                {
                    ApplicationArea = Jobs;
                }
                field("Applies-from Entry"; Rec."Applies-from Entry")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = Jobs;
                }
            }
            group(Control73)
            {
                ShowCaption = false;
                fixed(Control1902114901)
                {
                    ShowCaption = false;
                    group("Job Description")
                    {
                        Caption = 'Project Description';
                        field(JobDescription; JobDescription)
                        {
                            ApplicationArea = Jobs;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    group("Account Name")
                    {
                        Caption = 'Account Name';
                        field(AccName; AccName)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Account Name';
                            Editable = false;
                            ToolTip = 'Specifies the name of the related G/L account. ';
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
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
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines(false);
                    end;
                }
            }
            group("&Job")
            {
                Caption = '&Project';
                Image = Job;
                action(Card)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Job Card";
                    RunPageLink = "No." = field("Job No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    RunObject = Page "Job Ledger Entries";
                    RunPageLink = "Job No." = field("Job No.");
                    RunPageView = sorting("Job No.", "Posting Date");
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
                action("Calc. Remaining Usage")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Calc. Remaining Usage';
                    Ellipsis = true;
                    Image = CalculateRemainingUsage;
                    ToolTip = 'Calculate the remaining usage for the project. The batch job calculates, for each project task, the difference between scheduled usage of items, resources, and expenses and actual usage posted in project ledger entries. The remaining usage is then displayed in the project journal from where you can post it.';

                    trigger OnAction()
                    var
                        JTScheduleToJournal: Report "Job Calc. Remaining Usage";
                    begin
                        Rec.TestField("Journal Template Name");
                        Rec.TestField("Journal Batch Name");
                        Clear(JTScheduleToJournal);
                        JTScheduleToJournal.SetBatch(Rec."Journal Template Name", Rec."Journal Batch Name");
                        JTScheduleToJournal.SetDocNo(Rec."Document No.");
                        JTScheduleToJournal.RunModal();
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Reconcile)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Reconcile';
                    Image = Reconcile;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'View the balances on bank accounts that are marked for reconciliation, usually liquid accounts.';

                    trigger OnAction()
                    begin
                        JobJnlReconcile.SetJobJnlLine(Rec);
                        JobJnlReconcile.Run();
                    end;
                }
                action("Test Report")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintJobJnlLine(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Jobs;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Job Jnl.-Post", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
                action(PreviewPosting)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        ShowPreview();
                        CurrPage.Update(false);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Job Jnl.-Post+Print", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_Posting)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref("P&ost_Promoted"; "P&ost")
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                    actionref(PreviewPosting_Promoted; PreviewPosting)
                    {
                    }
                }
                actionref("Calc. Remaining Usage_Promoted"; "Calc. Remaining Usage")
                {
                }
                actionref(Reconcile_Promoted; Reconcile)
                {
                }
            }
            group(Category_Line)
            {
                Caption = 'Line';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        JobJnlManagement.GetNames(Rec, JobDescription, AccName);
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine(xRec);
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        if Rec.IsOpenedFromBatch() then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            JobJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
            exit;
        end;
        JobJnlManagement.TemplateSelection(PAGE::"Recurring Job Jnl.", true, Rec, JnlSelected);
        JobJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        JobJnlManagement: Codeunit JobJnlManagement;
        ReportPrint: Codeunit "Test Report-Print";
        JobJnlReconcile: Page "Job Journal Reconcile";
        CurrentJnlBatchName: Code[10];

    protected var
        ShortcutDimCode: array[8] of Code[20];
        JobDescription: Text[100];
        AccName: Text[100];

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        JobJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure ShowPreview()
    var
        JobJnlPost: Codeunit "Job Jnl.-Post";
    begin
        JobJnlPost.Preview(Rec);
    end;
}

