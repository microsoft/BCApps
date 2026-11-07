#pragma warning disable AA0247
page 14910 "Invent. Act Card"
{
    Caption = 'Invent. Act Card';
    PageType = Document;
    SourceTable = "Invent. Act Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEdit();
                    end;
                }
                field("Act Date"; Rec."Act Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the inventory act date, and is filled with the work date.';
                }
                field("Inventory Date"; Rec."Inventory Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of inventory, and is filled with the work date.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the inventory act.';
                }
                field("Reason Document Type"; Rec."Reason Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of reason document.';
                }
                field("Reason Document No."; Rec."Reason Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason document number.';
                }
                field("Reason Document Date"; Rec."Reason Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the reason document.';
                }
            }
            part(Control1210014; "Invent. Act Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Act No." = field("No.");
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
            group(Act)
            {
                Caption = 'Act';
                action("Employee Si&gnatures")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Si&gnatures';
                    Image = Signature;
                    RunObject = Page "Document Signatures";
                    RunPageLink = "Table ID" = const(14908),
                                  "Document No." = field("No.");
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Suggest Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggest Lines';
                    Ellipsis = true;
                    Image = SuggestLines;
                    ToolTip = 'Use a function to fill in lines for auditing of the fixed asset inventory in accordance with legal requirements.';

                    trigger OnAction()
                    var
                        InventActHeader: Record "Invent. Act Header";
                    begin
                        Rec.TestStatus();
                        InventActHeader := Rec;
                        InventActHeader.SetRecFilter();
                        REPORT.RunModal(REPORT::"Create Invent. Act Lines", true, false, InventActHeader);
                    end;
                }
                separator(Action1210020)
                {
                }
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Shift+F9';
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
                group(Print)
                {
                    Caption = 'Print';
                    Image = Print;
                    action("Invent. Act INV-17")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Invent. Act INV-17';
                        ToolTip = 'View an inventory of contractor payables and receivables.';

                        trigger OnAction()
                        var
                            InventActHeader: Record "Invent. Act Header";
                        begin
                            InventActHeader := Rec;
                            InventActHeader.SetRecFilter();
                            REPORT.Run(REPORT::"Invent. Act INV-17", true, false, InventActHeader);
                        end;
                    }
                    action("Supplement to INV-17")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Supplement to INV-17';
                        ToolTip = 'View an inventory of contractor payables and receivables.';

                        trigger OnAction()
                        var
                            InventActHeader: Record "Invent. Act Header";
                        begin
                            InventActHeader := Rec;
                            InventActHeader.SetRecFilter();
                            REPORT.Run(REPORT::"Supplement to INV-17", true, false, InventActHeader);
                        end;
                    }
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Suggest Lines_Promoted"; "Suggest Lines")
                {
                }
                actionref(Release_Promoted; Release)
                {
                }
                actionref("Employee Si&gnatures_Promoted"; "Employee Si&gnatures")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Invent. Act INV-17_Promoted"; "Invent. Act INV-17")
                {
                }
                actionref("Supplement to INV-17_Promoted"; "Supplement to INV-17")
                {
                }
            }
        }
    }
}

