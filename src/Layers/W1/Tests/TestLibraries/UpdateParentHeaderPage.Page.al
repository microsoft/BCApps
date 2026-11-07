page 139141 "Update Parent Header Page"
{
    SourceTable = "Update Parent Header";

    layout
    {
        area(content)
        {
            field(ID; Rec.ID)
            {
            }
            field(Description; Rec.Description)
            {
            }
            field(LinesAmount; LinesAmount)
            {
                Caption = 'Amount';
                AutoFormatType = 1;
                AutoFormatExpression = '';
            }
            field(LinesQuantity; LinesQuantity)
            {
                Caption = 'Quantity';
            }
            part(Lines; "Update Parent Line Page")
            {
                SubPageLink = "Header Id" = field(Id);
            }
            part(LinesUpdateParent; "Update Parent Line Page")
            {
                SubPageLink = "Header Id" = field(Id);
                UpdatePropagation = Both;
            }
        }
        area(factboxes)
        {
            part(FactLines; "Update Parent Fact Box")
            {
                SubPageLink = "Header Id" = field(Id);
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateParentRegisterMgt.RegistrateVisit(HeaderPageId, UpdateParentRegisterLine.Method::AfterGetCurrRecord);
    end;

    trigger OnAfterGetRecord()
    var
        UpdateParentLine: Record "Update Parent Line";
    begin
        UpdateParentLine.SetFilter("Header Id", Id);
        LinesAmount := 0;
        LinesQuantity := 0;
        if UpdateParentLine.Find('-') then
            repeat
                LinesAmount := LinesAmount + UpdateParentLine.Amount * UpdateParentLine.Quantity;
                LinesQuantity := LinesQuantity + UpdateParentLine.Quantity;
            until UpdateParentLine.Next() = 0;
        UpdateParentRegisterMgt.RegistrateVisit(HeaderPageId, UpdateParentRegisterLine.Method::AfterGetRecord);
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Lines.PAGE.SetUseUpdateParent(SaveOnUpdateParent, SubPageId);
        CurrPage.LinesUpdateParent.PAGE.SetUseUpdateParent(SaveOnUpdateParent, SubPageUpdateParentId);
        CurrPage.FactLines.PAGE.SetSubPageId(FactLineId);
        HeaderPageId := 139141;
    end;

    var
        UpdateParentRegisterLine: Record "Update Parent Register Line";
        UpdateParentRegisterMgt: Codeunit "Update Parent Register Mgt";
        LinesAmount: Decimal;
        LinesQuantity: Integer;
        SaveOnUpdateParent: Boolean;
        SubPageId: Integer;
        SubPageUpdateParentId: Integer;
        HeaderPageId: Integer;
        FactLineId: Integer;

    [Scope('OnPrem')]
    procedure GetValues(var ParmAmount: Decimal; var ParmQuantity: Integer)
    begin
        ParmAmount := LinesAmount;
        ParmQuantity := LinesQuantity;
    end;

    [Scope('OnPrem')]
    procedure SetSubPagesToSave()
    begin
        SaveOnUpdateParent := true;
    end;

    [Scope('OnPrem')]
    procedure SetSubPagesToNotSave()
    begin
        SaveOnUpdateParent := false;
    end;

    [Scope('OnPrem')]
    procedure SetSubPageIds(ParmSubPageId: Integer; ParmSubPageUpdateParentId: Integer; ParmFactLineId: Integer)
    begin
        SubPageId := ParmSubPageId;
        SubPageUpdateParentId := ParmSubPageUpdateParentId;
        FactLineId := ParmFactLineId;
    end;
}
