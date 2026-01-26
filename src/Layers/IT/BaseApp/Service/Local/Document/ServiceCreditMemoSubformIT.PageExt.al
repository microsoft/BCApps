// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 12445 "Service Credit Memo Subform IT" extends "Service Credit Memo Subform"
{
    layout
    {
        modify(Control1)
        {
            Editable = Rec."Automatically Generated" = false;
        }
        modify(Type)
        {
            trigger OnAfterValidate()
            begin
                UpdateSplitVATLinesPage(CopyStr(Rec.FieldCaption(Type), 1, 100));
            end;
        }
        modify("No.")
        {
            trigger OnAfterValidate()
            begin
                UpdateSplitVATLinesPage(CopyStr(Rec.FieldCaption("No."), 1, 100));
            end;
        }
        modify(Quantity)
        {
            trigger OnAfterValidate()
            begin
                UpdateSplitVATLinesPage(CopyStr(Rec.FieldCaption(Quantity), 1, 100));
            end;
        }
        modify("Unit of Measure Code")
        {
            trigger OnAfterValidate()
            begin
                UpdateSplitVATLinesPage(CopyStr(Rec.FieldCaption("Unit of Measure Code"), 1, 100));
            end;
        }
        modify("VAT Prod. Posting Group")
        {
            trigger OnAfterValidate()
            begin
                UpdateSplitVATLinesPage(CopyStr(Rec.FieldCaption("VAT Prod. Posting Group"), 1, 100));
            end;
        }
        modify("Unit Price")
        {
            trigger OnAfterValidate()
            begin
                UpdateSplitVATLinesPage(CopyStr(Rec.FieldCaption("Unit Price"), 1, 100));
            end;
        }
        modify("Line Amount")
        {
            trigger OnAfterValidate()
            begin
                UpdateSplitVATLinesPage(CopyStr(Rec.FieldCaption("Line Amount"), 1, 100));
            end;
        }
        modify("Line Discount %")
        {
            trigger OnAfterValidate()
            begin
                UpdateSplitVATLinesPage(CopyStr(Rec.FieldCaption("Line Discount %"), 1, 100));
            end;
        }
        modify("Line Discount Amount")
        {
            trigger OnAfterValidate()
            begin
                UpdateSplitVATLinesPage(CopyStr(Rec.FieldCaption("Line Discount Amount"), 1, 100));
            end;
        }
        addafter("VAT Prod. Posting Group")
        {
            field("Include in VAT Transac. Rep."; Rec."Include in VAT Transac. Rep.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies if the entry must be included in the VAT transaction report.';
            }
            field("Refers to Period"; Rec."Refers to Period")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the time period that is used to process and filter the transactions.';
            }
        }
        addafter("ShortcutDimCode[8]")
        {
            field("Automatically Generated"; Rec."Automatically Generated")
            {
                ApplicationArea = Service;
                Editable = false;
                ToolTip = 'Specifies if the document has been automatically generated.';
                Visible = false;
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.UpdateSplitVATLines(Rec.TableCaption);
    end;

    local procedure UpdateSplitVATLinesPage(ChangedFieldName: Text[100])
    begin
        CurrPage.SaveRecord();
        Rec.UpdateSplitVATLines(ChangedFieldName);
    end;
}

