#pragma warning disable AA0247
page 17333 "Future Expense Journal"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Future Expense Journal';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "FA Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    FEJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    FEJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("FA Posting Date"; Rec."FA Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the related fixed asset transaction, such as a depreciation.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the entry''s posting date.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related fixed asset. ';

                    trigger OnValidate()
                    begin
                        FEJnlManagement.GetFA(Rec."FA No.", FEDescription);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                }
                field("FA Posting Type"; Rec."FA Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting type, if Account Type field contains Fixed Asset.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warehouse or other place where the involved items are handled or stored.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';
                }
                field("Depr. Amount w/o Normalization"; Rec."Depr. Amount w/o Normalization")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the depreciation amount without normalization associated with the fixed asset journal line.';
                }
                field("Actual Quantity"; Rec."Actual Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the actual quantity associated with the fixed asset journal line.';
                }
                field("Calc. Quantity"; Rec."Calc. Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated quantity associated with the fixed asset journal line.';
                }
                field("Actual Amount"; Rec."Actual Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the actual amount of the fixed asset journal line.';
                }
                field("Calc. Amount"; Rec."Calc. Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated amount of the fixed asset journal line.';
                }
                field("Actual  Remaining Amount"; Rec."Actual  Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the actual remaining amount associated with the fixed asset journal line.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
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
                field("Salvage Value"; Rec."Salvage Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the estimated residual value of a fixed asset when it can no longer be used.';
                }
                field("No. of Depreciation Days"; Rec."No. of Depreciation Days")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of depreciation days that were used for calculating depreciation for the fixed asset entry.';
                }
                field("Depr. until FA Posting Date"; Rec."Depr. until FA Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if depreciation was calculated until the FA posting date of the line.';
                }
                field("Depr. Acquisition Cost"; Rec."Depr. Acquisition Cost")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if, when this line was posted, the additional acquisition cost posted on the line was depreciated in proportion to the amount by which the fixed asset had already been depreciated.';
                }
                field("Duplicate in Depreciation Book"; Rec."Duplicate in Depreciation Book")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a depreciation book code if you want the journal line to be posted to that depreciation book, as well as to the depreciation book in the Depreciation Book Code field.';
                }
                field("Use Duplication List"; Rec."Use Duplication List")
                {
                    ToolTip = 'Specifies, if the type is Fixed Asset, that information on the line is to be posted to all the assets defined depreciation books. ';
                    Visible = false;
                }
                field("FA Error Entry No."; Rec."FA Error Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of a posted FA ledger entry to mark as an error entry.';
                }
            }
            group(Control2)
            {
                ShowCaption = false;
                field(FEDescription; FEDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'FE Description';
                    Editable = false;
                }
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.Update();
                    end;
                }
            }
            group("Future Expense")
            {
                Caption = 'Future Expense';
                action("&Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Card';
                    Image = EditLines;
                    RunObject = Page "Future Period Expense Card";
                    RunPageLink = "No." = field("FA No.");
                    ShortCutKey = 'Shift+F7';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = GLRegisters;
                    RunObject = Codeunit "FA Jnl.-Show Entries";
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("Calculate Depreciation by Norm")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate Depreciation by Norm';
                    Image = CalculateDepreciation;
                    RunObject = Report "Calculate FE Depr. with Norm";
                }
                action("C&alculate Future Expences")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'C&alculate Future Expences';
                    Image = CalculateLines;

                    trigger OnAction()
                    var
                        FA: Record "Fixed Asset";
                    begin
                        FA.SetRange("FA Type", FA."FA Type"::"Future Expense");
                        REPORT.Run(REPORT::"Calc. FA Inventory", true, false, FA);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"FA. Jnl.-Post", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Image = Print;

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintFAJnlDoc(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("Calculate Depreciation by Norm_Promoted"; "Calculate Depreciation by Norm")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("Ledger E&ntries_Promoted"; "Ledger E&ntries")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        FEJnlManagement.GetFA(Rec."FA No.", FEDescription);
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
        OpenedFromBatch := (Rec."Journal Batch Name" <> '') and (Rec."Journal Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            FEJnlManagement.OpenJournal(CurrentJnlBatchName, Rec);
            exit;
        end;
        FEJnlManagement.TemplateSelection(PAGE::"Future Expense Journal", 1, false, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        FEJnlManagement.OpenJournal(CurrentJnlBatchName, Rec);
    end;

    var
        FEJnlManagement: Codeunit FAJnlManagement;
        CurrentJnlBatchName: Code[10];
        FEDescription: Text[30];
        ShortcutDimCode: array[8] of Code[20];
        OpenedFromBatch: Boolean;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        FEJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;
}

