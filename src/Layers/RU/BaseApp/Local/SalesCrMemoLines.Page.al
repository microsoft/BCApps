#pragma warning disable AA0247
page 14976 "Sales Cr. Memo Lines"
{
    Caption = 'Sales Cr. Memo Lines';
    Editable = false;
    PageType = Card;
    SourceTable = "Sales Cr.Memo Line";

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
                    ToolTip = 'Specifies the type of the record.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Original Type"; Rec."Original Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the corrected document.';
                }
                field("Original No."; Rec."Original No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Quantity (After)"; Rec."Quantity (After)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit Price (After)"; Rec."Unit Price (After)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Amount (After)"; Rec."Amount (After)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount after the correction.';
                }
                field("Amount Including VAT (After)"; Rec."Amount Including VAT (After)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount, including VAT, after the correction.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            OKOnPush();
        if CloseActionOk then begin
            CloseActionOk := false;
            CreateCorrDocLines();
        end;
    end;

    var
        SalesHeader: Record "Sales Header";
        CloseActionOk: Boolean;
#pragma warning disable AA0074
        Text001: Label 'Quantity,Unit Price';
#pragma warning restore AA0074
        Selection: Integer;

    [Scope('OnPrem')]
    procedure SetSalesHeader(DocType: Option; DocNo: Code[20])
    begin
        SalesHeader.Get(DocType, DocNo);
    end;

    [Scope('OnPrem')]
    procedure CreateCorrDocLines()
    var
        CorrDocMgt: Codeunit "Corrective Document Mgt.";
    begin
        Selection := StrMenu(Text001, 1);
        if Selection = 0 then
            exit;

        CurrPage.SetSelectionFilter(Rec);
        CorrDocMgt.SetSalesHeader(SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        CorrDocMgt.SetCorrectionType(Selection - 1);
        CorrDocMgt.CreateSalesLinesFromPstdCrMemo(Rec);
    end;

    local procedure OKOnPush()
    begin
        CloseActionOk := true;
    end;
}

