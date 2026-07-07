#pragma warning disable AA0247
page 26561 "Report Data Card"
{
    Caption = 'Report Data Card';
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Statutory Report Data Header";

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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the statutory report data header information.';
                }
                field("Date Filter"; Rec."Date Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data filter of the statutory report data header.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the statutory report data header.';
                }
                field(Period; Rec.Period)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period of the statutory report data header.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Correction Number"; Rec."Correction Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the correction number of the statutory report data header.';
                }
                field(OKEI; Rec.OKEI)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unit of measure for amounts that are associated with the statutory report data header.';
                }
                field("Period Type"; Rec."Period Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period type of the statutory report data header.';
                }
                field("Period No."; Rec."Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period number of the statutory report data header.';
                }
                field("No. in Year"; Rec."No. in Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number in year associated with the statutory report data header.';
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
            group("&Electronic File")
            {
                Caption = '&Electronic File';
                action("Create preview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create preview';
                    Image = PreviewChecks;

                    trigger OnAction()
                    begin
                        Rec.TestField(Status, Rec.Status::Open);
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Overview")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Overview';
                Image = ViewDetails;
                RunObject = Page "Statutory Report Data Overview";
                RunPageLink = "No." = field("No."),
                              "Report Code" = field("Report Code");
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Export to &Excel")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export to &Excel';
                    Image = ExportToExcel;

                    trigger OnAction()
                    var
                        StatutoryReportDataHeader: Record "Statutory Report Data Header";
                    begin
                        StatutoryReportDataHeader := Rec;
                        StatutoryReportDataHeader.ExportResultsToExcel();
                    end;
                }
                action("Export Electronic &File")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export Electronic &File';
                    Ellipsis = true;
                    Image = InsertStartingFee;

                    trigger OnAction()
                    begin
                        Rec.ExportResultsToXML();
                    end;
                }
                separator(Action1210023)
                {
                }
                action("&Update Report Data")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Update Report Data';
                    Image = Refresh;

                    trigger OnAction()
                    begin
                        Rec.UpdateData();
                    end;
                }
                separator(Action1210035)
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
                        StatutoryReportMgt.ReleaseDataHeader(Rec);
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
                        StatutoryReportMgt.ReopenDataHeader(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Overview_Promoted"; "&Overview")
                {
                }
                actionref("Export to &Excel_Promoted"; "Export to &Excel")
                {
                }
                actionref("Export Electronic &File_Promoted"; "Export Electronic &File")
                {
                }
                actionref(Release_Promoted; Release)
                {
                }
            }
        }
    }

    var
        StatutoryReportMgt: Codeunit "Statutory Report Management";
}

