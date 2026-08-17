// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using System;
using System.Xml;

codeunit 7705 "Miniform Logon"
{
    TableNo = "Miniform Header";

    trigger OnRun()
    var
        MiniformMgmt: Codeunit "Miniform Management";
    begin
        MiniformMgmt.Initialize(
          MiniformHeader, Rec, DOMxmlin, ReturnedNode,
          RootNode, XMLDOMMgt, ADCSCommunication, ADCSUserId,
          CurrentCode, StackCode, WhseEmpId, LocationFilter);

        if ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RunReturn') = '0' then begin
            if Rec.Code <> CurrentCode then
                PrepareData()
            else
                ProcessInput();
        end else
            PrepareData();

        Clear(DOMxmlin);
    end;

    var
        MiniformHeader: Record "Miniform Header";
        MiniformHeader2: Record "Miniform Header";
        ADCSUser: Record "ADCS User";
        XMLDOMMgt: Codeunit "XML DOM Management";
        ADCSCommunication: Codeunit "ADCS Communication";
        ADCSMgt: Codeunit "ADCS Management";
        RecRef: RecordRef;
        DOMxmlin: DotNet XmlDocument;
        ReturnedNode: DotNet XmlNode;
        RootNode: DotNet XmlNode;
        ADCSUserId: Text[250];
        WhseEmpId: Text[250];
        LocationFilter: Text[250];
        InvalidUserIDErr: Label 'Invalid User ID.';
        InvalidPasswordErr: Label 'Invalid Password.';
        NoInputNodeErr: Label 'No input Node found.';
        RecordNotFoundErr: Label 'Record not found.';
        CurrentCode: Text[250];
        StackCode: Text[250];
        ActiveInputField: Integer;

    local procedure ProcessInput()
    var
        FuncGroup: Record "Miniform Function Group";
        RecId: RecordID;
        TableNo: Integer;
        FldNo: Integer;
        TextValue: Text[250];
    begin
        if XMLDOMMgt.FindNode(RootNode, 'Header/Input', ReturnedNode) then
            TextValue := ReturnedNode.InnerText
        else
            Error(NoInputNodeErr);

        if Evaluate(TableNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'TableNo')) then begin
            RecRef.Open(TableNo);
            Evaluate(RecId, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'RecordID'));
            if RecRef.Get(RecId) then begin
                RecRef.SetTable(ADCSUser);
                ADCSCommunication.SetRecRef(RecRef);
            end else
                Error(RecordNotFoundErr);
        end;

        FuncGroup.KeyDef := ADCSCommunication.GetFunctionKey(MiniformHeader.Code, TextValue);

        case FuncGroup.KeyDef of
            FuncGroup.KeyDef::Esc:
                PrepareData();
            FuncGroup.KeyDef::Input:
                begin
                    Evaluate(FldNo, ADCSCommunication.GetNodeAttribute(ReturnedNode, 'FieldID'));
                    case FldNo of
                        ADCSUser.FieldNo(Name):
                            if not GetUser(UpperCase(TextValue)) then
                                exit;
                        ADCSUser.FieldNo(Password):
                            if not CheckPassword(TextValue) then
                                exit;
                        else begin
                            ADCSCommunication.FieldSetvalue(RecRef, FldNo, TextValue);
                            RecRef.SetTable(ADCSUser);
                        end;
                    end;

                    ActiveInputField := ADCSCommunication.GetActiveInputNo(CurrentCode, FldNo);
                    if ADCSCommunication.LastEntryField(CurrentCode, FldNo) then begin
                        ADCSCommunication.GetNextMiniForm(MiniformHeader, MiniformHeader2);
                        MiniformHeader2.SaveXMLin(DOMxmlin);
                        CODEUNIT.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
                    end else
                        ActiveInputField += 1;

                    RecRef.GetTable(ADCSUser);
                    ADCSCommunication.SetRecRef(RecRef);
                end;
        end;

        if not (FuncGroup.KeyDef in [FuncGroup.KeyDef::Esc]) and
           not ADCSCommunication.LastEntryField(CurrentCode, FldNo)
        then
            SendForm(ActiveInputField);
    end;

    local procedure GetUser(TextValue: Text[250]) ReturnValue: Boolean
    begin
        if ADCSUser.Get(TextValue) then begin
            ADCSUserId := ADCSUser.Name;
            ADCSUser.Password := '';
            if not ADCSCommunication.GetWhseEmployee(ADCSUserId, WhseEmpId, LocationFilter) then begin
                ADCSMgt.SendError(InvalidUserIDErr);
                ReturnValue := false;
                exit;
            end;
        end else begin
            ADCSMgt.SendError(InvalidUserIDErr);
            ReturnValue := false;
            exit;
        end;
        ReturnValue := true;
    end;

    local procedure CheckPassword(TextValue: Text[250]) ReturnValue: Boolean
    begin
        ADCSUser.Get(ADCSUserId);
        if ADCSUser.Password <> ADCSUser.CalculatePassword(CopyStr(TextValue, 1, 30)) then begin
            ADCSMgt.SendError(InvalidPasswordErr);
            ReturnValue := false;
            exit;
        end;
        ReturnValue := true;
    end;

    local procedure PrepareData()
    begin
        ActiveInputField := 1;
        SendForm(ActiveInputField);
    end;

    local procedure SendForm(InputField: Integer)
    begin
        ADCSCommunication.EncodeMiniForm(MiniformHeader, StackCode, DOMxmlin, InputField, '', ADCSUserId);
        ADCSCommunication.GetReturnXML(DOMxmlin);
        ADCSMgt.SendXMLReply(DOMxmlin);
    end;
}

