// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

page 5636 "FA Reclass. Journal"
{
    AdditionalSearchTerms = 'move fixed asset,split fixed asset';
    ApplicationArea = FixedAssets;
    AutoSplitKey = true;
    Caption = 'Fixed Asset Reclassification Journals';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "FA Reclass. Journal Line";
    UsageCategory = Tasks;
    AboutTitle = 'About FA Reclass Journal';
    AboutText = 'With the **FA Reclass Journal** you can transfer, split, or combine fixed assets. It is also used to transfer posted entries from one asset to another. The entries are calculated in this journal and then inserted in either the Fixed Asset G/L journal or the Fixed Asset journal.';

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    FAReclassJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    FAReclassJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("FA Posting Date"; Rec."FA Posting Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = FixedAssets;
                    ShowMandatory = true;
                }
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';

                    trigger OnValidate()
                    begin
                        FAReclassJnlManagement.GetFAS(Rec, FADescription, NewFADescription);
                    end;
                }
                field("New FA No."; Rec."New FA No.")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Update FA Numbers';
                    AboutText = 'Specify the FA and New FA number of the fixed asset you want to reclassify to.';

                    trigger OnValidate()
                    begin
                        FAReclassJnlManagement.GetFAS(Rec, FADescription, NewFADescription);
                    end;
                }
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Reclassify Acq. Cost Amount"; Rec."Reclassify Acq. Cost Amount")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reclassify Acq. Cost %"; Rec."Reclassify Acq. Cost %")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Reclassify Acq. Cost %';
                    AboutText = 'Specifies the percentage of the acquisition cost you want to reclassify.';
                }
                field("Reclassify Acquisition Cost"; Rec."Reclassify Acquisition Cost")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Reclassify Acquisition Cost';
                    AboutText = 'Specifies the reclassification of the acquisition cost for the fixed asset entered in the FA No. field, to the fixed asset entered in the New FA No. field.';
                }
                field("Reclassify Depreciation"; Rec."Reclassify Depreciation")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Reclassify Write-Down"; Rec."Reclassify Write-Down")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reclassify Appreciation"; Rec."Reclassify Appreciation")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reclassify Custom 1"; Rec."Reclassify Custom 1")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reclassify Custom 2"; Rec."Reclassify Custom 2")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reclassify Salvage Value"; Rec."Reclassify Salvage Value")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Insert Bal. Account"; Rec."Insert Bal. Account")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Calc. DB1 Depr. Amount"; Rec."Calc. DB1 Depr. Amount")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
            }
            group(Control33)
            {
                ShowCaption = false;
                fixed(Control1902115301)
                {
                    ShowCaption = false;
                    group("FA Description")
                    {
                        Caption = 'FA Description';
                        field(FADescription; FADescription)
                        {
                            ApplicationArea = FixedAssets;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies a description of the fixed asset.';
                        }
                    }
                    group("New FA Description")
                    {
                        Caption = 'New FA Description';
                        field(NewFADescription; NewFADescription)
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'New FA Description';
                            Editable = false;
                            ToolTip = 'Specifies a description of the fixed asset that is entered in the New FA No. field on the line.';
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
        area(processing)
        {
            action(Reclassify)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Recl&assify';
                Image = PostOrder;
                AboutTitle = 'Reclassify Assets';
                AboutText = 'Use the Reclassify option to create lines automatically in the fixed asset G/L journal or fixed asset journal.';
                ToolTip = 'Reclassify the fixed asset information on the journal lines.';

                trigger OnAction()
                begin
                    CODEUNIT.Run(CODEUNIT::"FA Reclass. Jnl.-Transfer", Rec);
                    CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Reclassify_Promoted; Reclassify)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        FAReclassJnlManagement.GetFAS(Rec, FADescription, NewFADescription);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine(xRec);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        if Rec.IsOpenedFromBatch() then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            FAReclassJnlManagement.OpenJournal(CurrentJnlBatchName, Rec);
            exit;
        end;
        FAReclassJnlManagement.TemplateSelection(PAGE::"FA Reclass. Journal", Rec, JnlSelected);
        if not JnlSelected then
            Error('');

        FAReclassJnlManagement.OpenJournal(CurrentJnlBatchName, Rec);
    end;

    protected var
        FAReclassJnlManagement: Codeunit FAReclassJnlManagement;
        CurrentJnlBatchName: Code[10];
        FADescription: Text[100];
        NewFADescription: Text[100];

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        FAReclassJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;
}

