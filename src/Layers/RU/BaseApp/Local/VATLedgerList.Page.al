#pragma warning disable AA0247
page 12412 "VAT Ledger List"
{
    Caption = 'VAT Ledger List';
    Editable = true;
    PageType = List;
    SourceTable = "VAT Ledger";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT ledger type.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT ledger code.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this VAT ledger.';
                }
                field("Accounting Period"; Rec."Accounting Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the accounting period associated with this VAT ledger.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the first day of the activity in question. ';
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last day of the activity in question. ';
                }
                field("From No."; Rec."From No.")
                {
                    DrillDown = false;
                    ToolTip = 'Specifies the first entry number in the VAT ledger.';
                    Visible = false;
                }
                field("To No."; Rec."To No.")
                {
                    DrillDown = false;
                    ToolTip = 'Specifies the end number associated with this VAT ledger.';
                    Visible = false;
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
        area(navigation)
        {
            group("&Ledger")
            {
                Caption = '&Ledger';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';

                    trigger OnAction()
                    begin
                        case Rec.Type of
                            Rec.Type::Purchase:
                                PAGE.Run(PAGE::"VAT Purchase Ledger Card", Rec);
                            Rec.Type::Sales:
                                PAGE.Run(PAGE::"VAT Sales Ledger Card", Rec);
                        end;
                    end;
                }
            }
        }
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("&Create Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Ledger';
                    Image = CreateForm;
                    ToolTip = 'Create an additional VAT ledger sheet. ';

                    trigger OnAction()
                    begin
                        Rec.CreateVATLedger();
                    end;
                }
                action("Create Additional Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Additional Sheet';
                    Image = CreateDocument;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;

                    trigger OnAction()
                    begin
                        Rec.CreateAddSheet();
                    end;
                }
            }
            group(Print)
            {
                Caption = 'Print';
                Image = Print;
                action("Export Ledger")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Ledger';
                    Image = ExportToExcel;
                    ToolTip = 'Export the data in the VAT ledger to Excel.';

                    trigger OnAction()
                    var
                        VATLedgerExport: Report "VAT Ledger Export";
                    begin
                        VATLedgerExport.InitializeReport(Rec.Type, Rec.Code, false);
                        VATLedgerExport.RunModal();
                    end;
                }
                action("Export Add. Sheet")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Add. Sheet';
                    Image = ExportToExcel;
                    ToolTip = 'Export the additional VAT ledger sheet.';

                    trigger OnAction()
                    var
                        VATLedgerExport: Report "VAT Ledger Export";
                    begin
                        VATLedgerExport.InitializeReport(Rec.Type, Rec.Code, true);
                        VATLedgerExport.RunModal();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Create Ledger_Promoted"; "&Create Ledger")
                {
                }
                actionref(Card_Promoted; Card)
                {
                }
            }
        }
    }

    var
}

