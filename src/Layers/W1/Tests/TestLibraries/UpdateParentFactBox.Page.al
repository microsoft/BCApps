page 139143 "Update Parent Fact Box"
{
    PageType = ListPart;
    SourceTable = "Update Parent Fact Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Line Id"; "Line Id")
                {
                }
                field(Name; Name)
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

    var
        UpdateParentRegisterLine: Record "Update Parent Register Line";
        UpdateParentRegisterMgt: Codeunit "Update Parent Register Mgt";
        SubPageId: Integer;

    [Scope('OnPrem')]
    procedure SetSubPageId(ParmSubPageId: Integer)
    begin
        SubPageId := ParmSubPageId;
    end;

    local procedure DoUpdate(Method: Option Validate,Insert,Modify,Delete,AfterGetCurrRecord,AfterGetRecord)
    begin
        UpdateParentRegisterMgt.RegistratePreUpdate(SubPageId, Method);
        CurrPage.Update();
        UpdateParentRegisterMgt.RegistratePostUpdate(SubPageId, Method);
    end;
}

