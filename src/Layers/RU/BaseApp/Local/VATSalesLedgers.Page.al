#pragma warning disable AA0247
page 35629 "VAT Sales Ledgers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Sales Ledgers';
    CardPageID = "VAT Sales Ledger Card";
    PageType = List;
    SourceTable = "VAT Ledger";
    SourceTableView = where(Type = const(Sales));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
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
            systempart(Control1210004; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1210002; Links)
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
                    Image = VATLedger;
                    RunObject = Page "VAT Sales Ledger Card";
                    RunPageLink = Type = field(Type),
                                  Code = field(Code);
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';
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
                    ToolTip = 'Export the data in the additional VAT ledger sheet to Excel.';

                    trigger OnAction()
                    var
                        VATLedgerExport: Report "VAT Ledger Export";
                    begin
                        VATLedgerExport.InitializeReport(Rec.Type, Rec.Code, true);
                        VATLedgerExport.RunModal();
                    end;
                }
                action("Export Ledger XML Format")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Ledger XML Format';
                    Image = XMLFile;
                    ToolTip = 'Export the data in the VAT ledger to an XML file.';

                    trigger OnAction()
                    var
                        VATLedgerExportXML: Report "VAT Ledger Export XML";
                    begin
                        VATLedgerExportXML.InitializeReport(Rec.Type, Rec.Code, false);
                        VATLedgerExportXML.RunModal();
                    end;
                }
                action("Export Add. Sheet XML Format")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Add. Sheet XML Format';
                    Image = XMLFile;
                    ToolTip = 'Export the data in the additional VAT ledger sheet to an XML file.';

                    trigger OnAction()
                    var
                        VATLedgerExportXML: Report "VAT Ledger Export XML";
                    begin
                        VATLedgerExportXML.InitializeReport(Rec.Type, Rec.Code, true);
                        VATLedgerExportXML.RunModal();
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
}

