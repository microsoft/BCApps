#pragma warning disable AA0247
page 17209 "Tax Register Accumulation"
{
    Caption = 'Tax Register Accumulation';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Tax Register";

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
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    OptionCaption = ',,Month,Quarter,Year';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                    end;
                }
                field(DateFilter; DateFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date Filter';
                    Editable = false;
                    ToolTip = 'Specifies the dates that will be used to filter the amounts in the window.';
                }
            }
            part(TaxRegAccLines; "Tax Register Accum. Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Section Code" = field("Section Code"),
                              "Tax Register No." = field("No."),
                              "Date Filter" = field("Date Filter");
                SubPageView = sorting("Section Code", "Tax Register No.", "Template Line No.", "Starting Date", "Ending Date");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Previous Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Set';
                Image = PreviousSet;
                ToolTip = 'Previous Set';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                end;
            }
            action("Next Set")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Set';
                Image = NextSet;
                ToolTip = 'Next Set';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                end;
            }
            action(Entries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Entries';
                Image = Entries;
                ShortCutKey = 'Ctrl+F7';
                ToolTip = 'View the entries for the tax register.';

                trigger OnAction()
                begin
                    ShowTaxRegEntries();
                end;
            }
        }
        area(reporting)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Image = Print;

                trigger OnAction()
                begin
                    Rec.PrintReport(DateFilter);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Previous Set_Promoted"; "Previous Set")
                {
                }
                actionref("Next Set_Promoted"; "Next Set")
                {
                }
                actionref(Entries_Promoted; Entries)
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

    trigger OnOpenPage()
    begin
        PeriodType := PeriodType::Month;
        FindPeriod('');
    end;

    var
        PeriodType: Option ,,Month,Quarter,Year;
        DateFilter: Text[250];

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
#pragma warning disable AL0603
        if DateFilter <> '' then begin
            Calendar.SetFilter("Period Start", DateFilter);
            if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                PeriodPageManagement.FindDate('+', Calendar, PeriodType::Month);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
#pragma warning restore AL0603
        DateFilter := StrSubstNo('%1..%2', Calendar."Period Start", Calendar."Period End");
        Rec.SetFilter("Date Filter", '%1..%2', CalcDate('<-CM>', Calendar."Period End"), Calendar."Period End");
        CurrPage.TaxRegAccLines.PAGE.UpdatePage(DateFilter);
    end;

    local procedure ShowTaxRegEntries()
    var
        TaxRegGLEntry: Record "Tax Register G/L Entry";
        TaxRegCVEntry: Record "Tax Register CV Entry";
        TaxRegItemEntry: Record "Tax Register Item Entry";
        TaxRegFAEntry: Record "Tax Register FA Entry";
        TaxRegFEEntry: Record "Tax Register FE Entry";
    begin
        if (Rec."Page ID" = 0) or (Rec."Table ID" = 0) or
           (Rec."Storing Method" = Rec."Storing Method"::Calculation)
        then
            exit;

        case Rec."Table ID" of
            DATABASE::"Tax Register G/L Entry":
                begin
                    TaxRegGLEntry.SetFilter("Where Used Register IDs", '*~' + Rec."Register ID" + '~*');
                    PAGE.RunModal(Rec."Page ID", TaxRegGLEntry);
                end;
            DATABASE::"Tax Register CV Entry":
                begin
                    TaxRegCVEntry.SetFilter("Where Used Register IDs", '*~' + Rec."Register ID" + '~*');
                    PAGE.RunModal(Rec."Page ID", TaxRegCVEntry);
                end;
            DATABASE::"Tax Register Item Entry":
                begin
                    TaxRegItemEntry.SetFilter("Where Used Register IDs", '*~' + Rec."Register ID" + '~*');
                    PAGE.RunModal(Rec."Page ID", TaxRegItemEntry);
                end;
            DATABASE::"Tax Register FA Entry":
                begin
                    TaxRegFAEntry.SetFilter("Where Used Register IDs", '*~' + Rec."Register ID" + '~*');
                    PAGE.RunModal(Rec."Page ID", TaxRegFAEntry);
                end;
            DATABASE::"Tax Register FE Entry":
                begin
                    TaxRegFEEntry.SetFilter("Where Used Register IDs", '*~' + Rec."Register ID" + '~*');
                    PAGE.RunModal(Rec."Page ID", TaxRegFEEntry);
                end;
        end;
    end;
}

