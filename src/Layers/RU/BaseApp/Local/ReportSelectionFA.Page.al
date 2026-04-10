#pragma warning disable AA0247
page 12484 "Report Selection - FA"
{
    AboutTitle = 'About report selection for fixed assets';
    AboutText = 'On this page, you set up the default reports that are used when printing fixed asset documents such as writeoffs, releases, and movements. Use the Usage field to select the type of document, then specify which reports to use in the list below.';
    Caption = 'Report Selection - Fixed Asset';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = FixedAssets;
                Caption = 'Usage';
                OptionCaption = 'Unposted FA Writeoff,Unposted FA Release,Unposted FA Movement,FA Writeoff,FA Release,FA Movement,FA Jnl.,FA Rec.Jnl';

                trigger OnValidate()
                begin
                    SetUsageFilter();
                    ReportUsage2OnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = FixedAssets;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if the report ID is the default for the report selection.';
                }
                field("Excel Export"; Rec."Excel Export")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies if the report selection will be exported.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    begin
        SetUsageFilter();
    end;

    var
        ReportUsage2: Option "Unposted FA Writeoff","Unposted FA Release","Unposted FA Movement","FA Writeoff","FA Release","FA Movement","FA Jnl.","FA Rec.Jnl";

    local procedure SetUsageFilter()
    begin
        Rec.FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"Unposted FA Writeoff":
                Rec.SetRange(Usage, Rec.Usage::UFAW);
            ReportUsage2::"Unposted FA Release":
                Rec.SetRange(Usage, Rec.Usage::UFAR);
            ReportUsage2::"Unposted FA Movement":
                Rec.SetRange(Usage, Rec.Usage::UFAM);
            ReportUsage2::"FA Writeoff":
                Rec.SetRange(Usage, Rec.Usage::FAW);
            ReportUsage2::"FA Release":
                Rec.SetRange(Usage, Rec.Usage::FAR);
            ReportUsage2::"FA Movement":
                Rec.SetRange(Usage, Rec.Usage::FAM);
            ReportUsage2::"FA Jnl.":
                Rec.SetRange(Usage, Rec.Usage::FAJ);
            ReportUsage2::"FA Rec.Jnl":
                Rec.SetRange(Usage, Rec.Usage::FARJ);
        end;
        Rec.FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

