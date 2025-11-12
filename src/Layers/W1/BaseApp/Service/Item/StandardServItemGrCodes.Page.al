// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Service.Document;

page 5959 "Standard Serv. Item Gr. Codes"
{
    Caption = 'Standard Serv. Item Gr. Codes';
    DataCaptionExpression = FormCaption;
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Standard Service Item Gr. Code";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrServItemGroupCodeCtrl; CurrentServiceItemGroupCode)
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item Group Code';
                    Editable = CurrServItemGroupCodeCtrlEdita;
                    TableRelation = "Service Item Group".Code;
                    ToolTip = 'Specifies the filter that can be applied to sort a list of standard service codes.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord();
                        LookupServItemGroupCode();
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    begin
                        CurrentServiceItemGroupCodeOnA();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a standard service code assigned to the specified service item group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies a description of service denoted by the standard service code.';
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
        area(navigation)
        {
            group("&Service")
            {
                Caption = '&Service';
                Image = Tools;
                action(Card)
                {
                    ApplicationArea = Service;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    var
                        StandardServiceCode: Record "Standard Service Code";
                    begin
                        Rec.TestField(Code);

                        StandardServiceCode.Get(Rec.Code);
                        PAGE.Run(PAGE::"Standard Service Code Card", StandardServiceCode);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetServItemGroupCode(Rec.GetFilter("Service Item Group Code"), false);
    end;

    trigger OnAfterGetRecord()
    begin
        SetServItemGroupCode(Rec.GetFilter("Service Item Group Code"), false);
    end;

    trigger OnInit()
    begin
        CurrServItemGroupCodeCtrlEdita := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        NotCloseForm2: Boolean;
    begin
        NotCloseForm2 := NotCloseForm;
        NotCloseForm := false;
        if CurrPage.LookupMode then
            exit(not NotCloseForm2);
    end;

    var
        ServiceItemGroup: Record "Service Item Group";
        CurrentServiceItemGroupCode: Code[10];
        NotCloseForm: Boolean;
        FormCaption: Text[250];
        CurrServItemGroupCodeCtrlEdita: Boolean;

    local procedure LookupServItemGroupCode()
    begin
        Commit();
        if PAGE.RunModal(0, ServiceItemGroup) = ACTION::LookupOK then begin
            CurrentServiceItemGroupCode := ServiceItemGroup.Code;
            SetServItemGroupCode(CurrentServiceItemGroupCode, true);
        end;
    end;

    procedure SetServItemGroupCode(NewCode: Code[10]; Forced: Boolean)
    begin
        if Forced or (NewCode = '') or (NewCode <> CurrentServiceItemGroupCode) then begin
            CurrentServiceItemGroupCode := NewCode;
            ComposeFormCaption(NewCode);

            if CurrentServiceItemGroupCode = '' then begin
                Rec.Reset();
                Rec.FilterGroup := 2;
                Rec.SetFilter("Service Item Group Code", '''''');
                Rec.FilterGroup := 0;
            end else begin
                Rec.Reset();
                Rec.SetRange("Service Item Group Code", CurrentServiceItemGroupCode);
            end;
        end;
    end;

    local procedure ComposeFormCaption(NewCode: Code[10])
    begin
        if NewCode <> '' then begin
            ServiceItemGroup.Get(NewCode);
            FormCaption := NewCode + ' ' + ServiceItemGroup.Description;
        end else
            FormCaption := '';
    end;

    local procedure CurrentServiceItemGroupCodeOnA()
    begin
        SetServItemGroupCode(CurrentServiceItemGroupCode, true);
        CurrPage.Update(false);
        NotCloseForm := true;
    end;
}

