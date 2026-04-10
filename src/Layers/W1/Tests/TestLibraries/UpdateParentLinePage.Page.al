page 139142 "Update Parent Line Page"
{
    PageType = ListPart;
    SourceTable = "Update Parent Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Header Id"; "Header Id")
                {
                }
                field("Line Id"; "Line Id")
                {
                }
                field(Amount; Rec.Amount)
                {

                    trigger OnValidate()
                    begin
                        DoUpdate(UpdateParentRegisterLine.Method::Validate);
                    end;
                }
                field(Quantity; Rec.Quantity)
                {

                    trigger OnValidate()
                    begin
                        DoUpdate(UpdateParentRegisterLine.Method::Validate);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateParentRegisterMgt.RegistrateVisit(SubPageId, UpdateParentRegisterLine.Method::AfterGetCurrRecord);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        UpdateParentRegisterMgt.RegistrateVisit(SubPageId, UpdateParentRegisterLine.Method::Delete);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        UpdateParentRegisterMgt.RegistrateVisit(SubPageId, UpdateParentRegisterLine.Method::Insert);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        UpdateParentRegisterMgt.RegistrateVisit(SubPageId, UpdateParentRegisterLine.Method::Modify);
    end;

    var
        UpdateParentRegisterLine: Record "Update Parent Register Line";
        UpdateParentRegisterMgt: Codeunit "Update Parent Register Mgt";
        SaveOnUpdate: Boolean;
        SubPageId: Integer;

    [Scope('OnPrem')]
    procedure SetUseUpdateParent(ParmSave: Boolean; ParmSubPageId: Integer)
    begin
        SaveOnUpdate := ParmSave;
        SubPageId := ParmSubPageId;
    end;

    local procedure DoUpdate(Method: Option Validate,Insert,Modify,Delete,AfterGetCurrRecord,AfterGetRecord)
    begin
        UpdateParentRegisterMgt.RegistratePreUpdate(SubPageId, Method);
        CurrPage.Update(SaveOnUpdate);
        UpdateParentRegisterMgt.RegistratePostUpdate(SubPageId, Method);
    end;
}

