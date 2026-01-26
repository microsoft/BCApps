#pragma warning disable AA0247
page 784 "VAT Report Lines"
{
    Caption = 'VAT Report Lines';
    PageType = List;
    SourceTable = "VAT Report Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("VAT Report No."; Rec."VAT Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number that identifies the line.';
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the line in the VAT report.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("EU Service"; Rec."EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Indicates whether the line is associated with a EU Service.';
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that the VAT amount in the amount is calculated from.';
                }
            }
        }
    }

    actions
    {
    }

    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";

    [Scope('OnPrem')]
    procedure SetToDeclaration(NewVATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader := NewVATReportHeader;
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");

        Rec.SetRange("VAT Report to Correct", VATReportHeader."Original Report No.");
        Rec.SetRange("Able to Correct Line", true);
    end;

    [Scope('OnPrem')]
    procedure CopyLineToDeclaration()
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
        TempVATReportLineRelation: Record "VAT Report Line Relation" temporary;
    begin
        CurrPage.SetSelectionFilter(VATReportLine);
        if VATReportLine.FindSet() then
            repeat
                TempVATReportLineRelation.DeleteAll();
                VATReportLineRelation.SetRange("VAT Report No.", VATReportLine."VAT Report No.");
                VATReportLineRelation.SetRange("VAT Report Line No.", VATReportLine."Line No.");
                if VATReportLineRelation.FindSet() then
                    repeat
                        TempVATReportLineRelation := VATReportLineRelation;
                        TempVATReportLineRelation."VAT Report No." := VATReportHeader."No.";
                        TempVATReportLineRelation.Insert();
                    until VATReportLineRelation.Next() = 0;
                VATReportLine.InsertCorrLine(VATReportHeader, VATReportLine, VATReportLine, TempVATReportLineRelation);
            until VATReportLine.Next() = 0;
    end;
}