// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Period;

page 188 "Posted Docs. With No Inc. Doc."
{
    Caption = 'Posted Documents without Incoming Document';
    DataCaptionFields = "Document No.", "Posting Date", "First Posting Description";
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Posted Docs. With No Inc. Buf.";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Filters)
            {
                Caption = 'Filters';
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the posting date of the posted purchase and sales documents without incoming document records that are shown. By default, the filter is the first day of the current accounting period until the work date.';

                    trigger OnValidate()
                    begin
                        SearchForDocNos();
                    end;
                }
                field(DocNoFilter; DocNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No. Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the document number on the posted purchase and sales documents without incoming document records that are shown.';

                    trigger OnValidate()
                    begin
                        SearchForDocNos();
                    end;
                }
                field(GLAccFilter; GLAccFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Account No. Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the G/L account whose posted purchase and sales documents without incoming document records are shown. By default, the G/L account for which you opened the Posted Documents without Incoming Document window is inserted.';

                    trigger OnValidate()
                    begin
                        SearchForDocNos();
                    end;
                }
                field(ExternalDocNoFilter; ExternalDocNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'External Doc. No. Filter';
                    Importance = Promoted;
                    ToolTip = 'Specifies a filter for the external document number on the posted purchase and sales documents without incoming document records that are shown.';

                    trigger OnValidate()
                    begin
                        SearchForDocNos();
                    end;
                }
            }
            repeater(Group)
            {
                Caption = 'Documents';
                Editable = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the posted purchase and sales document that does not have an incoming document record.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the posted purchase and sales document that does not have an incoming document record.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("First Posting Description"; Rec."First Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of the first posting transaction on the posted purchase and sales document that does not have an incoming document record.';
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                }
            }
        }
        area(factboxes)
        {
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(IncomingDocument)
            {
                Caption = 'Incoming Document';
                Image = Documents;
                action(IncomingDocCard)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View Incoming Document';
                    Enabled = HasIncomingDocument;
                    Image = ViewOrder;
                    ToolTip = 'View any incoming document records and file attachments that exist for the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        IncomingDocument.ShowCard(Rec."Document No.", Rec."Posting Date");
                    end;
                }
                action(SelectIncomingDoc)
                {
                    AccessByPermission = TableData "Incoming Document" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Select Incoming Document';
                    Image = SelectLineToApply;
                    ToolTip = 'Select an incoming document record and file attachment that you want to link to the entry or document.';

                    trigger OnAction()
                    begin
                        Rec.UpdateIncomingDocuments();
                    end;
                }
                action(IncomingDocAttachFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Incoming Document from File';
                    Ellipsis = true;
                    Enabled = not HasIncomingDocument;
                    Image = Attach;
                    ToolTip = 'Create an incoming document record by selecting a file to attach, and then link the incoming document record to the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocumentAttachment: Record "Incoming Document Attachment";
                    begin
                        IncomingDocumentAttachment.SetRange("Document No.", Rec."Document No.");
                        IncomingDocumentAttachment.SetRange("Posting Date", Rec."Posting Date");
                        IncomingDocumentAttachment.NewAttachment();
                    end;
                }
            }
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New', Comment = 'Generated from the PromotedActionCategories property index 0.';

                actionref(IncomingDocAttachFile_Promoted; IncomingDocAttachFile)
                {
                }
            }
            group(Category_Process)
            {
                Caption = 'Incoming Document', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(IncomingDocCard_Promoted; IncomingDocCard)
                {
                }
                actionref(SelectIncomingDoc_Promoted; SelectIncomingDoc)
                {
                }
                actionref(Navigate_Promoted; Navigate)
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
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        HasIncomingDocument := IncomingDocumentExists();
    end;

    trigger OnOpenPage()
    var
        AccountingPeriod: Record "Accounting Period";
        FiscalStartDate: Date;
        FilterGroupNo: Integer;
    begin
        if DateFilter = '' then begin
            FiscalStartDate := AccountingPeriod.GetFiscalYearStartDate(WorkDate());
            if FiscalStartDate <> 0D then
                Rec.SetRange("Posting Date", FiscalStartDate, WorkDate())
            else
                Rec.SetRange("Posting Date", CalcDate('<CY>', WorkDate()), WorkDate());
            DateFilter := CopyStr(Rec.GetFilter("Posting Date"), 1, MaxStrLen(DateFilter));
            Rec.SetRange("Posting Date");
        end;
        FilterGroupNo := 0;
        while (FilterGroupNo <= 4) and (GLAccFilter = '') do begin
            GLAccFilter := CopyStr(Rec.GetFilter("G/L Account No. Filter"), 1, MaxStrLen(GLAccFilter));
            FilterGroupNo += 2;
        end;
        SearchForDocNos();
    end;

    var
        DateFilter: Text;
        DocNoFilter: Code[250];
        GLAccFilter: Code[250];
        ExternalDocNoFilter: Code[250];
        HasIncomingDocument: Boolean;

    local procedure SearchForDocNos()
    var
        PostedDocsWithNoIncBuf: Record "Posted Docs. With No Inc. Buf.";
    begin
        PostedDocsWithNoIncBuf := Rec;
        Rec.GetDocNosWithoutIncomingDoc(Rec, DateFilter, DocNoFilter, GLAccFilter, ExternalDocNoFilter);
        Rec := PostedDocsWithNoIncBuf;
        if Rec.Find('=<>') then;
        CurrPage.Update(false);
    end;

    local procedure IncomingDocumentExists(): Boolean
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.SetRange(Posted, true);
        IncomingDocument.SetRange("Document No.", Rec."Document No.");
        IncomingDocument.SetRange("Posting Date", Rec."Posting Date");
        exit(not IncomingDocument.IsEmpty);
    end;
}

