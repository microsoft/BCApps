// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;

page 31025 "VAT LCY Correction CZL"
{
    Caption = 'VAT LCY Correction';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    SourceTable = "VAT LCY Correction Buffer CZL";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {

            group(Control1)
            {
                ShowCaption = false;

                field(DisplayDocumentNo; DocumentNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies a document number for the journal line.';
                    ShowMandatory = true;
                    Editable = false;
                }
                field(DisplayPostingDate; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ClosingDates = true;
                    ToolTip = 'Specifies the entry''s posting date.';
                    ShowMandatory = true;
                    Editable = false;
                }
            }
            repeater(Control2)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the VAT entry''s posting date.';
                }
                field("VAT Date"; Rec."VAT Date")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the VAT date. This date must be shown on the VAT statement.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the document type that the VAT entry belongs to.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the document number on the VAT entry.';
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the relevant VAT rate for the particular combination of VAT business posting group and VAT product posting group.';
                }
                field("VAT Base"; Rec."VAT Base")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the amount that the VAT amount (the amount shown in the Amount field) is calculated from.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Specifies the amount of the VAT entry in LCY.';
                }
                field("Corrected VAT Amount"; Rec."Corrected VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'Enter the correct VAT amount in the field.';
                    Editable = CorrectedVATAmountEditable;

                    trigger OnValidate()
                    begin
                        CheckMaxVATDifferenceAllowed();
                        Rec.Modify();
                        CalcTotals();
                        CurrPage.Update(false);
                    end;
                }
                field("VAT Correction Amount"; Rec."VAT Correction Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    StyleExpr = NameStyleExpr;
                    ToolTip = 'The difference between the values of the fields "VAT Amount" and "Corrected VAT Amount", which will be posted as a deviation of VAT from the original VAT amount.';
                }
            }
            group(Control3)
            {
                ShowCaption = false;
                fixed(Control1901776101)
                {
                    ShowCaption = false;
                    group("Total VAT Base")
                    {
                        Caption = 'Total VAT Base';
                        field(DisplayTotalVATBase; TotalVATBase)
                        {
                            AutoFormatExpression = '';
                            AutoFormatType = 1;
                            ApplicationArea = Basic, Suite;
                            Caption = 'Total VAT Base';
                            ShowCaption = false;
                            Editable = false;
                            ToolTip = 'Specifies the total debit amount in the general journal.';
                        }
                    }
                    group("Total VAT Amount")
                    {
                        Caption = 'Total VAT Amount';
                        field(DisplayTotalVATAmount; TotalVATAmount)
                        {
                            AutoFormatExpression = '';
                            AutoFormatType = 1;
                            ApplicationArea = Basic, Suite;
                            Caption = 'Total VAT Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total credit amount in the general journal.';
                        }
                    }
                    group("Total Corrected VAT Amount")
                    {
                        Caption = 'Total Corrected VAT Amount';
                        field(DisplayTotalCorrectedVATAmount; TotalCorrectedVATAmount)
                        {
                            AutoFormatExpression = '';
                            AutoFormatType = 1;
                            ApplicationArea = Basic, Suite;
                            Caption = 'Corrected VAT Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total credit amount in the general journal.';
                        }
                    }
                    group("Total VAT Correction Amount")
                    {
                        Caption = 'Total VAT Correction Amount';
                        field(DisplayTotalVATCorrectionAmount; TotalVATCorrectionAmount)
                        {
                            AutoFormatExpression = '';
                            AutoFormatType = 1;
                            ApplicationArea = Basic, Suite;
                            Caption = 'Total VAT Amount';
                            Editable = false;
                            ToolTip = 'Specifies the total credit amount in the general journal.';
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
            part("VAT Amount Summary FactBox CZL"; "VAT Amount Summary FactBox CZL")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(Post)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'P&ost VAT correction in LCY';
                Image = Post;
                ShortcutKey = 'F9';
                ToolTip = 'Post value from field "VAT Correction Amount" to general and VAT ledger entries.';

                trigger OnAction()
                var
                    VATLCYCorrPostYesNoCZL: Codeunit "VAT LCY Corr.-Post(Yes/No) CZL";
                begin
                    VATLCYCorrPostYesNoCZL.Run(Rec);
                    CurrPage.Close();
                end;
            }
            action(Preview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview Posting';
                Image = ViewPostedOrder;
                ShortcutKey = 'Ctrl+Alt+F9';
                ToolTip = 'Review the result of the posting lines before the actual posting.';

                trigger OnAction()
                begin
                    ShowPreview();
                end;
            }
            action("VAT Posting Setup Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Posting Setup Card';
                Image = Setup;
                RunObject = page "VAT Posting Setup Card";
                RunPageLink = "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"), "VAT Prod. Posting Group" = field("VAT Prod. Posting Group");
                ToolTip = 'Open the VAT posting setup card for the selected record.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Post_Promoted; Post)
                {
                }
                actionref(Preview_Promoted; Preview)
                {
                }
                actionref("VAT Posting Setup Card_Promoted"; "VAT Posting Setup Card")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        SourceCodeSetup.Get();
        if VATLCYCorrectionMgtCZL.GetVATLCYCorrectionBuffer(SourceDocument, Rec) then begin
            DocumentNo := Rec."Document No.";
            PostingDate := Rec."Posting Date";
        end;
        CalcTotals();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Source Code" = SourceCodeSetup."VAT LCY Correction CZL" then begin
            CorrectedVATAmountEditable := false;
            NameStyleExpr := 'Subordinate';
        end else begin
            CorrectedVATAmountEditable := true;
            NameStyleExpr := '';
        end;
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        VATLCYCorrectionMgtCZL: Codeunit "VAT LCY Correction Mgt. CZL";
        SourceDocument: Variant;
        DocumentNo: Code[20];
        PostingDate: Date;
        CorrectedVATAmountEditable: Boolean;
        TotalVATBase: Decimal;
        TotalVATAmount: Decimal;
        TotalCorrectedVATAmount: Decimal;
        TotalVATCorrectionAmount: Decimal;
        NameStyleExpr: Text;

    procedure InitGlobals(Variant: Variant)
    begin
        SourceDocument := Variant;
        VATLCYCorrectionMgtCZL.CheckSourceDocument(SourceDocument);
    end;

    local procedure CheckMaxVATDifferenceAllowed()
    var
        TempVATLCYCorrectionBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary;
    begin
        TempVATLCYCorrectionBufferCZL.Copy(Rec, true);
        TempVATLCYCorrectionBufferCZL.SetRange("Source Code", SourceCodeSetup."VAT LCY Correction CZL");
        TempVATLCYCorrectionBufferCZL.CalcSums("Corrected VAT Amount");
        TempVATLCYCorrectionBufferCZL."Corrected VAT Amount" += Rec."Corrected VAT Amount";
        TempVATLCYCorrectionBufferCZL."VAT Amount" := Rec."VAT Amount";
        TempVATLCYCorrectionBufferCZL.CalcVATCorrectionAmount();
    end;

    local procedure CalcTotals()
    var
        TempVATLCYCorrectionBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary;
    begin
        TempVATLCYCorrectionBufferCZL.Copy(Rec, true);
        TempVATLCYCorrectionBufferCZL.CalcSums("VAT Base", "VAT Amount", "Corrected VAT Amount", "VAT Correction Amount");
        TotalVATBase := TempVATLCYCorrectionBufferCZL."VAT Base";
        TotalVATAmount := TempVATLCYCorrectionBufferCZL."VAT Amount";
        TotalCorrectedVATAmount := TempVATLCYCorrectionBufferCZL."Corrected VAT Amount";
        TotalVATCorrectionAmount := TempVATLCYCorrectionBufferCZL."VAT Correction Amount";
        CurrPage."VAT Amount Summary FactBox CZL".Page.UpdateVATAmountTotals(TempVATLCYCorrectionBufferCZL);
    end;

    local procedure ShowPreview()
    var
        VATLCYCorrPostYesNoCZL: Codeunit "VAT LCY Corr.-Post(Yes/No) CZL";
    begin
        VATLCYCorrPostYesNoCZL.Preview(Rec);
    end;
#if not CLEAN29
    internal procedure RaiseOnInitGlobals(DocRecordRef: RecordRef; var NewDocumentNo: Code[20]; var NewPostingDate: Date; var NewTransactionNo: Integer; var IsHandled: Boolean)
    begin
#pragma warning disable AL0432
        OnInitGlobals(DocRecordRef, NewDocumentNo, NewPostingDate, NewTransactionNo, IsHandled);
#pragma warning restore AL0432
    end;

    internal procedure RaiseOnAfterGetDocumentVATEntries(var VATLCYCorrectionBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary; DocumentNo: Code[20]; PostingDate: Date; TransactionNo: Integer; DimensionSetID: Integer)
    begin
#pragma warning disable AL0432
        OnAfterGetDocumentVATEntries(VATLCYCorrectionBufferCZL, DocumentNo, PostingDate, TransactionNo, DimensionSetID);
#pragma warning restore AL0432
    end;

    [Obsolete('This event will be removed in future versions. Please use OnCheckSourceDocumentElse and OnAfterGetVATLCYCorrectionBuffer events from codeunit 11769 "VAT LCY Correction Mgt. CZL" instead.', '29.0')]
    [IntegrationEvent(false, false)]
    local procedure OnInitGlobals(DocRecordRef: RecordRef; var NewDocumentNo: Code[20]; var NewPostingDate: Date; var NewTransactionNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('This event will be removed in future versions. Please use OnCheckSourceDocumentElse and OnAfterGetVATLCYCorrectionBuffer events from codeunit 11769 "VAT LCY Correction Mgt. CZL" instead.', '29.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetDocumentVATEntries(var VATLCYCorrectionBufferCZL: Record "VAT LCY Correction Buffer CZL" temporary; DocumentNo: Code[20]; PostingDate: Date; TransactionNo: Integer; DimensionSetID: Integer)
    begin
    end;
#endif
}
