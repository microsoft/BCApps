page 3321 "MX PAC Web Service Details"
{
    Caption = 'PAC Web Service Details';
    PageType = ListPart;
    SourceTable = "MX PAC Web Service Detail";
    ApplicationArea = All;
    DelayedInsert = true;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                ShowCaption = false;

                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies whether the operation is for stamping, cancelation, or cancellation status.';
                }
                field("Method Name"; Rec."Method Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the web method to invoke for this operation.';
                }
                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the endpoint URL used for this operation and mode.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditSelectedLine)
            {
                ApplicationArea = All;
                Caption = 'Edit';
                Image = EditLines;
                ToolTip = 'Edits Method Name and Address for the selected operation.';

                trigger OnAction()
                begin
                    EditSelectedPACWebServiceDetail();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        MXConnectionSetup: Record "MX Connection Setup";
    begin
        MXConnectionSetup.Reset();
        if not MXConnectionSetup.Get() then begin
            MXConnectionSetup.Init();
            MXConnectionSetup.Insert(true);
        end;

        if MXConnectionSetup.Get() then begin
            EnsureDefaultRows(MXConnectionSetup);
            Rec.SetRange("Setup Id", MXConnectionSetup.Id);
        end;
    end;

    local procedure EnsureDefaultRows(var MXConnectionSetup: Record "MX Connection Setup")
    var
        MXPACWebServiceDetail: Record "MX PAC Web Service Detail";
        MethodName: Text[50];
        ServiceUrl: Text[250];
    begin
        GetDefaultServiceConfig(MXConnectionSetup."Send Mode", MXPACWebServiceDetail.Type::"Request Stamp", ServiceUrl, MethodName);
        UpsertDefaultRow(MXConnectionSetup.Id, MXPACWebServiceDetail.Type::"Request Stamp", MethodName, ServiceUrl);

        GetDefaultServiceConfig(MXConnectionSetup."Send Mode", MXPACWebServiceDetail.Type::Cancel, ServiceUrl, MethodName);
        UpsertDefaultRow(MXConnectionSetup.Id, MXPACWebServiceDetail.Type::Cancel, MethodName, ServiceUrl);

        GetDefaultServiceConfig(MXConnectionSetup."Send Mode", MXPACWebServiceDetail.Type::CancelRequest, ServiceUrl, MethodName);
        UpsertDefaultRow(MXConnectionSetup.Id, MXPACWebServiceDetail.Type::CancelRequest, MethodName, ServiceUrl);
    end;

    local procedure GetDefaultServiceConfig(SendMode: Option Test,Production; RequestType: Option "Request Stamp",Cancel,CancelRequest; var ServiceUrl: Text[250]; var MethodName: Text[50])
    begin
        case SendMode of
            SendMode::Test:
                ServiceUrl := InterfacturaServiceUrlLbl;
            SendMode::Production:
                ServiceUrl := InterfacturaServiceUrlLbl;
        end;

        case RequestType of
            RequestType::"Request Stamp":
                MethodName := GeneraTimbreMethodLbl;
            RequestType::Cancel:
                MethodName := CancelaTimbreMethodLbl;
            RequestType::CancelRequest:
                MethodName := ConsultaEstatusMethodLbl;
        end;
    end;

    local procedure UpsertDefaultRow(SetupId: Code[10]; RequestType: Option "Request Stamp",Cancel,CancelRequest; MethodName: Text[50]; Address: Text[250])
    var
        MXPACWebServiceDetail: Record "MX PAC Web Service Detail";
    begin
        if not MXPACWebServiceDetail.Get(SetupId, RequestType) then begin
            MXPACWebServiceDetail.Init();
            MXPACWebServiceDetail."Setup Id" := SetupId;
            MXPACWebServiceDetail.Type := RequestType;
            MXPACWebServiceDetail.Insert(true);
        end;

        MXPACWebServiceDetail."Method Name" := MethodName;
        MXPACWebServiceDetail.Address := Address;
        MXPACWebServiceDetail.Modify(true);
    end;

    local procedure EditSelectedPACWebServiceDetail()
    var
        SelectedPACWebServiceDetail: Record "MX PAC Web Service Detail";
        MXPACWebServiceDetailEditDialog: Page "MX PAC WS Detail Edit Dlg";
        NewMethodName: Text[50];
        NewAddress: Text[250];
    begin
        CurrPage.SetSelectionFilter(SelectedPACWebServiceDetail);
        if SelectedPACWebServiceDetail.Count <> 1 then
            Error(SelectSingleLineErr);

        SelectedPACWebServiceDetail.FindFirst();

        if not Confirm(EditWarningQst, false) then
            exit;

        MXPACWebServiceDetailEditDialog.SetValues(SelectedPACWebServiceDetail.Type, SelectedPACWebServiceDetail."Method Name", SelectedPACWebServiceDetail.Address);
        if MXPACWebServiceDetailEditDialog.RunModal() <> Action::OK then
            exit;

        MXPACWebServiceDetailEditDialog.GetValues(NewMethodName, NewAddress);

        SelectedPACWebServiceDetail.Validate("Method Name", NewMethodName);
        SelectedPACWebServiceDetail.Validate(Address, NewAddress);
        SelectedPACWebServiceDetail.Modify(true);
        CurrPage.Update(false);
    end;

    var
        EditWarningQst: Label 'Changing PAC web service values may break the integration if values are incorrect. Do you want to continue?';
        SelectSingleLineErr: Label 'Select exactly one PAC Web Service Detail line to edit.';
        InterfacturaServiceUrlLbl: Label 'https://qaservicios.interfactura.com/TimbreServicios/TimbreServicios.asmx', Locked = true;
        GeneraTimbreMethodLbl: Label 'GeneraTimbre', Locked = true;
        CancelaTimbreMethodLbl: Label 'CancelaTimbre', Locked = true;
        ConsultaEstatusMethodLbl: Label 'ConsultaEstatusCancelacion', Locked = true;
}