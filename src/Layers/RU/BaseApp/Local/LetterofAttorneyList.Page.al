#pragma warning disable AA0247
page 14906 "Letter of Attorney List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Letters of Attorney';
    CardPageID = "Letter of Attorney Card";
    DelayedInsert = true;
    Editable = false;
    PageType = List;
    SourceTable = "Letter of Attorney Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Letter of Attorney No."; Rec."Letter of Attorney No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the printed document.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
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
                    ToolTip = 'Specifies whether the Letter of Attorney is open for revisions or is released.';
                }
                field("Employee No."; Rec."Employee No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved employee.';
                }
                field("Employee Full Name"; Rec."Employee Full Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the employee who is being authorized by this Letter of Attorney.';
                }
                field("Employee Job Title"; Rec."Employee Job Title")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the employee job title.';
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
                field("Realization Check"; Rec."Realization Check")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document that is realized.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
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
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
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
        }
        area(reporting)
        {
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Release_Promoted; Release)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref(Print_Promoted; Print)
                {
                }
            }
        }
    }
}

