#pragma warning disable AA0247
page 26572 "Copy Statutory Report"
{
    Caption = 'Copy Statutory Report';
    PageType = Card;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(StatReportCopyFromCode; StatReportCopyFromCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy From Report Code';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        StatutoryReport.SetFilter(Code, '<>%1', StatReportCopyToCode);
                        if PAGE.RunModal(0, StatutoryReport) = ACTION::LookupOK then
                            StatReportCopyFromCode := StatutoryReport.Code;
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        StatutoryReport: Record "Statutory Report";
        StatReportCopyFromCode: Code[20];
        StatReportCopyToCode: Code[20];

    [Scope('OnPrem')]
    procedure SetParameters(NewStatRepCodeCopyTo: Code[20])
    begin
        StatReportCopyToCode := NewStatRepCodeCopyTo;
    end;

    [Scope('OnPrem')]
    procedure GetParameters(var NewStatReportCopyFromCode: Code[20])
    begin
        NewStatReportCopyFromCode := StatReportCopyFromCode;
    end;
}

