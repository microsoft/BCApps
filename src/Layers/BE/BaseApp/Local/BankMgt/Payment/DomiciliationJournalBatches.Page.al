// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 2000021 "Domiciliation Journal Batches"
{
    Caption = 'Domiciliation Journal Batches';
    DataCaptionExpression = DataCaption();
    PageType = List;
    SourceTable = "Domiciliation Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the journal batch you are creating.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the journal batch you are creating.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that to see the available status, click the AssistButton.';
                }
                field("Partner Type"; Rec."Partner Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the domiciliation journal batch is of type person or company.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Edit Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Journal';
                Image = OpenJournal;
                ShortCutKey = 'Return';
                ToolTip = 'Open a journal based on the journal batch.';

                trigger OnAction()
                begin
                    DomJnlManagement.TemplateSelectionFromBatch(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Edit Journal_Promoted"; "Edit Journal")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        DomJnlManagement.OpenJnlBatch(Rec);
    end;

    var
        DomJnlManagement: Codeunit DomiciliationJnlManagement;

    local procedure DataCaption(): Text[250]
    var
        DomJnlTemplate: Record "Domiciliation Journal Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Journal Template Name") <> '' then
                if Rec.GetRangeMin("Journal Template Name") = Rec.GetRangeMax("Journal Template Name") then
                    if DomJnlTemplate.Get(Rec.GetRangeMin("Journal Template Name")) then
                        exit(DomJnlTemplate.Name + ' ' + DomJnlTemplate.Description);
    end;
}

