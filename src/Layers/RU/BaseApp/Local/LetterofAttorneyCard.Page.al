#pragma warning disable AA0247
page 14905 "Letter of Attorney Card"
{
    Caption = 'Letter of Attorney Card';
    PageType = Document;
    SourceTable = "Letter of Attorney Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Letter of Attorney No."; Rec."Letter of Attorney No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the printed document.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Employee Full Name"; Rec."Employee Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the employee who is being authorized by this Letter of Attorney.';
                }
                field("Employee Job Title"; Rec."Employee Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee job title.';
                }
                field("Source Document Type"; Rec."Source Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of source document.';
                }
                field("Source Document No."; Rec."Source Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source document number.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Document Description"; Rec."Document Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about the source document.';
                }
                field("Realization Check"; Rec."Realization Check")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document that is realized.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Validity Date"; Rec."Validity Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the validity date of the document.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies whether the Letter of Attorney is open for revisions or is released.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEdit();
                    end;
                }
            }
            part(Subform; "Letter of Attorney Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Letter of Attorney No." = field("No.");
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Letter of Attorney")
            {
                Caption = 'Letter of Attorney';
                action("Document Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document Card';
                    Image = Document;

                    trigger OnAction()
                    var
                        PurchaseHeader: Record "Purchase Header";
                    begin
                        if Rec."Source Document Type" = Rec."Source Document Type"::" " then
                            exit;

                        if not PurchaseHeader.Get(Rec."Source Document Type" - 1, Rec."Source Document No.") then
                            exit;

                        case PurchaseHeader."Document Type" of
                            PurchaseHeader."Document Type"::Quote:
                                PAGE.Run(PAGE::"Purchase Quote", PurchaseHeader);
                            PurchaseHeader."Document Type"::"Blanket Order":
                                PAGE.Run(PAGE::"Blanket Purchase Order", PurchaseHeader);
                            PurchaseHeader."Document Type"::Order:
                                PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);
                            PurchaseHeader."Document Type"::Invoice:
                                if PurchaseHeader."Empl. Purchase" then
                                    PAGE.Run(PAGE::"Advance Statement", PurchaseHeader)
                                else
                                    PAGE.Run(PAGE::"Purchase Invoice", PurchaseHeader);
                            PurchaseHeader."Document Type"::"Return Order":
                                PAGE.Run(PAGE::"Purchase Return Order", PurchaseHeader);
                            PurchaseHeader."Document Type"::"Credit Memo":
                                PAGE.Run(PAGE::"Purchase Credit Memo", PurchaseHeader);
                        end;
                    end;
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Copy Lines from Source Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Lines from Source Document';
                    Image = Copy;

                    trigger OnAction()
                    begin
                        CopyLinesFromSrcDoc();
                    end;
                }
                separator(Action1210021)
                {
                }
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Enable the record for the next stage of processing. ';

                    trigger OnAction()
                    begin
                        Rec.Release();
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    begin
                        Rec.Reopen();
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print';
                Image = Print;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    Rec.Print();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Release_Promoted; Release)
                {
                }
                actionref("Copy Lines from Source Document_Promoted"; "Copy Lines from Source Document")
                {
                }
                actionref(Reopen_Promoted; Reopen)
                {
                }
                actionref(Print_Promoted; Print)
                {
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if SourceDocNo <> '' then
            Rec.Validate("Source Document No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if SourceDocType <> 0 then
            Rec."Source Document Type" := SourceDocType;

        if SourceDocNo <> '' then
            Rec."Source Document No." := SourceDocNo;
    end;

    var
        SourceDocType: Integer;
        SourceDocNo: Code[20];

    [Scope('OnPrem')]
    procedure SetSourceDocument(DocType: Integer; DocNo: Code[20])
    begin
        SourceDocType := DocType + 1;
        SourceDocNo := DocNo;
    end;

    [Scope('OnPrem')]
    procedure CopyLinesFromSrcDoc()
    begin
        Rec.TestField("Source Document No.");
        Rec.CreateAttorneyLetterLines();
        CurrPage.Subform.PAGE.UpdateForm(false);
    end;
}

