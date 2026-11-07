#pragma warning disable AA0247
page 12441 "VAT Sales Ledger Card"
{
    Caption = 'VAT Sales Ledger Card';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "VAT Ledger";
    SourceTableView = where(Type = const(Sales));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
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
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the first entry number in the VAT ledger.';
                }
                field("To No."; Rec."To No.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the end number associated with this VAT ledger.';
                }
                field("Accounting Period"; Rec."Accounting Period")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the accounting period associated with this VAT ledger.';
                }
                field("Start Page No."; Rec."Start Page No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the starting page number associated with this VAT ledger.';
                }
            }
            part(SalesSubform; "VAT Sales Ledger Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = Type = field(Type),
                              Code = field(Code);
            }
            group(Options)
            {
                Caption = 'Options';
                field("C/V Filter"; Rec."C/V Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer filter or vendor filter associated with this VAT ledger.';
                }
                field("VAT Product Group Filter"; Rec."VAT Product Group Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product group filter associated with this VAT ledger.';
                }
                field("VAT Business Group Filter"; Rec."VAT Business Group Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT business group filter associated with this VAT ledger.';
                }
                field("Sales Sorting"; Rec."Sales Sorting")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sales sorts that are associated with this VAT ledger.';
                }
                field("Clear Lines"; Rec."Clear Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the lines that are associated with this VAT ledger are cleared.';
                }
                field("Show Realized VAT"; Rec."Show Realized VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the realized VAT associated with this VAT ledger is displayed.';
                }
                field("Show Unrealized VAT"; Rec."Show Unrealized VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the unrealized VAT associated with this VAT ledger is displayed.';
                }
                field("Show Customer Prepayments"; Rec."Show Customer Prepayments")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies if the customer prepayments associated with this VAT ledger are displayed.';
                }
                field("Show Amount Differences"; Rec."Show Amount Differences")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the amount differences associated with this VAT ledger are displayed.';
                }
                field("Show Vendor Prepayments"; Rec."Show Vendor Prepayments")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies if the vendor prepayments associated with this VAT ledger are displayed.';
                }
                field("Show VAT Reinstatement"; Rec."Show VAT Reinstatement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT reinstatement associated with this VAT ledger is displayed.';
                }
            }
            group(AddSheetSubForm)
            {
                Caption = 'Additional Sheet';
                field("Tot Base20 Amt VAT Sales Ledg"; Rec."Tot Base20 Amt VAT Sales Ledg")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Base20 Amount from VAT Sales Ledger';
                }
                field("Tot Base18 Amt VAT Sales Ledg"; Rec."Tot Base18 Amt VAT Sales Ledg")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Base18 Amount from VAT Sales Ledger';
                }
                field("Tot Base 10 Amt VAT Sales Ledg"; Rec."Tot Base 10 Amt VAT Sales Ledg")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Base10 Amount from VAT Sales Ledger';
                }
                field("Tot Base 0 Amt VAT Sales Ledg"; Rec."Tot Base 0 Amt VAT Sales Ledg")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Base0 Amount from VAT Sales Ledger';
                }
                field("Total VAT20 Amt VAT Sales Ledg"; Rec."Total VAT20 Amt VAT Sales Ledg")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total VAT20 Amount from VAT Sales Ledger';
                }
                field("Total VAT18 Amt VAT Sales Ledg"; Rec."Total VAT18 Amt VAT Sales Ledg")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total VAT18 Amount from VAT Sales Ledger';
                }
                field("Total VAT10 Amt VAT Sales Ledg"; Rec."Total VAT10 Amt VAT Sales Ledg")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total VAT10 Amount from VAT Sales Ledger';
                }
                field("Total VATExempt Amt VAT S Ledg"; Rec."Total VATExempt Amt VAT S Ledg")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total VAT Exempt Amount from VAT Sales Ledger';
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
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    CurrPage.SalesSubform.PAGE.NavigateDocument();
                end;
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

                actionref("&Create Ledger_Promoted"; "&Create Ledger")
                {
                }
                actionref("Create Additional Sheet_Promoted"; "Create Additional Sheet")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Export Ledger_Promoted"; "Export Ledger")
                {
                }
                actionref("Export Add. Sheet_Promoted"; "Export Add. Sheet")
                {
                }
                actionref("Export Ledger XML Format_Promoted"; "Export Ledger XML Format")
                {
                }
                actionref("Export Add. Sheet XML Format_Promoted"; "Export Add. Sheet XML Format")
                {
                }
            }
        }
    }
}

