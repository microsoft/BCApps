// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

using Microsoft.Warehouse.Setup;
using System;
using System.Reflection;
using System.Xml;

codeunit 7701 "ADCS Communication"
{

    trigger OnRun()
    begin
    end;

    var
        ADCSUser: Record "ADCS User";
        XMLDOMMgt: Codeunit "XML DOM Management";
        RecRef: RecordRef;
        XMLDOM: DotNet XmlDocument;
#pragma warning disable AA0074
        Text000: Label 'Failed to add a node.';
#pragma warning disable AA0470
        Text001: Label 'Failed to add the element: %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Comment: Text[250];
        TableNo: Text[250];
        RecID: Text[250];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'Failed to add the attribute: %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ActiveInput: Integer;
        InputCounter: Integer;
        RecRefRunning: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 is not a valid value for the %2 field.';
        Text004: Label 'The field %2 in the record %1 can only contain %3 characters. (%4).', Comment = 'The field [Field Caption] in the record [Record Caption] [Field Caption] can only contain [Field Length] characters. ([Attempted value to set]).';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InputIsHidden: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'Miniform %1 not found.';
        Text006: Label 'There must be one miniform that is set to %1.';
#pragma warning restore AA0470
        Text007: Label '<%1> not used.', Locked = true;
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure EncodeMiniForm(MiniFormHdr: Record "Miniform Header"; StackCode: Code[250]; var XMLDOMin: DotNet XmlDocument; ActiveInputField: Integer; cMessage: Text[250]; ADCSUserId: Text[250])
    var
        CurrNode: DotNet XmlNode;
        NewChild: DotNet XmlNode;
        FunctionNode: DotNet XmlNode;
        ReturnedNode: DotNet XmlNode;
        oAttributes: DotNet XmlNamedNodeMap;
        AttributeNode: DotNet XmlNode;
        iAttributeCounter: Integer;
        iCounter: Integer;
    begin
        XMLDOM := XMLDOMin;
        ActiveInput := ActiveInputField;
        InputCounter := 0;
        Comment := cMessage;

        // get the incoming header before we create the empty Container..
        XMLDOMMgt.FindNode(XMLDOM.DocumentElement, 'Header', ReturnedNode);

        // Now create an empty root node... this must always be done before we use this object!!
        XMLDOMMgt.LoadXMLDocumentFromText('<ADCS/>', XMLDOM);

        // Set the current node to the root node
        CurrNode := XMLDOM.DocumentElement;

        // add a header node to the ADCS node
        if XMLDOMMgt.AddElement(CurrNode, 'Header', '', '', NewChild) > 0 then
            Error(Text000);

        // Add all the header fields from the incoming XMLDOM
        oAttributes := ReturnedNode.Attributes;
        iAttributeCounter := oAttributes.Count();
        iCounter := 0;
        while iCounter < iAttributeCounter do begin
            AttributeNode := oAttributes.Item(iCounter);
            AddAttribute(NewChild, AttributeNode.Name, AttributeNode.Value);

            iCounter := iCounter + 1;
        end;

        // Now add the UserId to the Header
        if ADCSUserId <> '' then begin
            AddAttribute(NewChild, 'LoginID', ADCSUserId);
            SetUserNo(ADCSUserId);
        end else
            Clear(ADCSUser);

        // now add the input to the Header

        AddAttribute(NewChild, 'UseCaseCode', MiniFormHdr.Code);
        AddAttribute(NewChild, 'StackCode', StackCode);
        AddAttribute(NewChild, 'RunReturn', '0');
        AddAttribute(NewChild, 'FormTypeOpt', Format(MiniFormHdr."Form Type"));
        AddAttribute(NewChild, 'NoOfLines', Format(MiniFormHdr."No. of Records in List"));
        AddAttribute(NewChild, 'InputIsHidden', '0');
        InputIsHidden := false;

        XMLDOMMgt.AddElement(NewChild, 'Comment', Comment, '', FunctionNode);

        // add the Function List to the Mini Form
        if XMLDOMMgt.AddElement(NewChild, 'Functions', '', '', FunctionNode) = 0 then
            EncodeFunctions(MiniFormHdr, FunctionNode);

        EncodeLines(MiniFormHdr, CurrNode);

        if InputIsHidden then begin
            XMLDOMMgt.FindNode(XMLDOM.DocumentElement, 'Header', ReturnedNode);
            SetNodeAttribute(ReturnedNode, 'InputIsHidden', '1');
        end;

        XMLDOMin := XMLDOM;
    end;

    local procedure EncodeFunctions(MiniFormHdr: Record "Miniform Header"; var CurrNode: DotNet XmlNode)
    var
        FunctionLine: Record "Miniform Function";
        NewChild: DotNet XmlNode;
    begin
        // Add the Function List to the XML Document
        FunctionLine.Reset();
        FunctionLine.SetRange("Miniform Code", MiniFormHdr.Code);

        if FunctionLine.Find('-') then
            repeat
                XMLDOMMgt.AddElement(CurrNode, 'Function', Format(FunctionLine."Function Code"), '', NewChild);
            until FunctionLine.Next() = 0
    end;

    local procedure EncodeLines(MiniFormHdr: Record "Miniform Header"; var CurrNode: DotNet XmlNode)
    var
        MiniFormLine: Record "Miniform Line";
        MiniFormLine2: Record "Miniform Line";
        LinesNode: DotNet XmlNode;
        AreaNode: DotNet XmlNode;
        DataLineNode: DotNet XmlNode;
        CurrentOption: Integer;
        LineCounter: Integer;
    begin
        // add a lines node to the ADCS node
        if XMLDOMMgt.AddElement(CurrNode, 'Lines', '', '', LinesNode) > 0 then
            Error(Text000);

        CurrentOption := -1;
        LineCounter := 0;

        MiniFormLine.Reset();
        MiniFormLine.SetCurrentKey(Area);
        MiniFormLine.SetRange("Miniform Code", MiniFormHdr.Code);
        if MiniFormLine.Find('-') then
            repeat
                if CurrentOption <> MiniFormLine.Area then begin
                    CurrentOption := MiniFormLine.Area;
                    if XMLDOMMgt.AddElement(LinesNode, Format(MiniFormLine.Area), '', '', AreaNode) > 0 then
                        Error(Text000);
                end;

                if MiniFormLine.Area = MiniFormLine.Area::Body then
                    if MiniFormHdr."Form Type" <> MiniFormHdr."Form Type"::Card then
                        while MiniFormHdr."No. of Records in List" > LineCounter do begin
                            if ((MiniFormHdr."Form Type" = MiniFormHdr."Form Type"::"Data List") or
                                (MiniFormHdr."Form Type" = MiniFormHdr."Form Type"::"Data List Input"))
                            then begin
                                MiniFormLine2.SetCurrentKey(Area);
                                MiniFormLine2.SetRange("Miniform Code", MiniFormLine."Miniform Code");
                                MiniFormLine2.SetRange(Area, MiniFormLine.Area);
                                if MiniFormLine2.Find('-') then begin
                                    SendLineNo(MiniFormLine2, AreaNode, DataLineNode, LineCounter);
                                    repeat
                                        SendComposition(MiniFormLine2, DataLineNode);
                                    until MiniFormLine2.Next() = 0;
                                    if GetNextRecord() = 0 then
                                        LineCounter := MiniFormHdr."No. of Records in List";
                                end;
                            end else begin
                                SendLineNo(MiniFormLine, AreaNode, DataLineNode, LineCounter);
                                SendComposition(MiniFormLine, DataLineNode);
                                if MiniFormLine.Next() = 0 then
                                    LineCounter := MiniFormHdr."No. of Records in List"
                                else
                                    if MiniFormLine.Area <> MiniFormLine.Area::Body then begin
                                        MiniFormLine.Find('<');
                                        LineCounter := MiniFormHdr."No. of Records in List";
                                    end;
                            end;
                            LineCounter := LineCounter + 1;
                        end
                    else
                        SendComposition(MiniFormLine, AreaNode)
                else
                    SendComposition(MiniFormLine, AreaNode);
            until MiniFormLine.Next() = 0;
    end;

    local procedure SendComposition(MiniFormLine: Record "Miniform Line"; var CurrNode: DotNet XmlNode)
    var
        NewChild: DotNet XmlNode;
    begin
        // add a data node to the area node

        AddElement(CurrNode, 'Field', GetFieldValue(MiniFormLine), '', NewChild);

        // add the field name as an attribute..
        if MiniFormLine."Field Type" <> MiniFormLine."Field Type"::Text then
            AddAttribute(NewChild, 'FieldID', Format(MiniFormLine."Field No."));

        // What type of field is this ?
        if MiniFormLine."Field Type" in [MiniFormLine."Field Type"::Input, MiniFormLine."Field Type"::Asterisk] then begin
            InputCounter := InputCounter + 1;
            if InputCounter = ActiveInput then begin
                AddAttribute(NewChild, 'Type', 'Input');
                InputIsHidden := MiniFormLine."Field Type" = MiniFormLine."Field Type"::Asterisk;
            end else
                AddAttribute(NewChild, 'Type', 'OutPut');
        end else
            AddAttribute(NewChild, 'Type', Format(MiniFormLine."Field Type"));

        if MiniFormLine."Field Type" = MiniFormLine."Field Type"::Text then
            MiniFormLine."Field Length" := StrLen(MiniFormLine.Text);
        AddAttribute(NewChild, 'MaxLen', Format(MiniFormLine."Field Length"));

        // The Data Description
        if MiniFormLine."Field Type" <> MiniFormLine."Field Type"::Text then
            AddAttribute(NewChild, 'Descrip', MiniFormLine.Text);
    end;

    local procedure SendLineNo(MiniFormLine: Record "Miniform Line"; var CurrNode: DotNet XmlNode; var RetNode: DotNet XmlNode; LineNo: Integer)
    var
        NewChild: DotNet XmlNode;
    begin
        if MiniFormLine.Area = MiniFormLine.Area::Body then
            AddElement(CurrNode, 'Line', '', '', NewChild)
        else
            NewChild := CurrNode;

        if RecRefRunning then begin
            TableNo := Format(RecRef.Number);
            RecID := Format(RecRef.RecordId);
        end;
        AddAttribute(NewChild, 'No', Format(LineNo));
        AddAttribute(NewChild, 'TableNo', TableNo);
        AddAttribute(NewChild, 'RecordID', RecID);

        RetNode := NewChild;
    end;

    local procedure AddElement(var CurrNode: DotNet XmlNode; ElemName: Text[30]; ElemValue: Text[250]; NameSpace: Text[30]; var NewChild: DotNet XmlNode)
    begin
        if XMLDOMMgt.AddElement(CurrNode, ElemName, ElemValue, NameSpace, NewChild) > 0 then
            Error(Text001, ElemName);
    end;

    local procedure AddAttribute(var NewChild: DotNet XmlNode; AttribName: Text[250]; AttribValue: Text[250])
    begin
        if XMLDOMMgt.AddAttribute(NewChild, AttribName, AttribValue) > 0 then
            Error(Text002, AttribName);
    end;

    procedure SetRecRef(var NewRecRef: RecordRef)
    begin
        RecRef := NewRecRef.Duplicate();
        RecRefRunning := true;
    end;

    local procedure GetNextRecord(): Integer
    begin
        exit(RecRef.Next());
    end;

    procedure FindRecRef(SelectOption: Integer; NoOfLines: Integer): Boolean
    var
        i: Integer;
    begin
        case SelectOption of
            0:
                exit(RecRef.Find('-'));
            1:
                exit(RecRef.Find('>'));
            2:
                exit(RecRef.Find('<'));
            3:
                exit(RecRef.Find('+'));
            4:
                begin
                    for i := 0 to NoOfLines - 1 do
                        if not RecRef.Find('>') then
                            exit(false);
                    exit(true);
                end;
            5:
                begin
                    for i := 0 to NoOfLines - 1 do
                        if not RecRef.Find('<') then
                            exit(false);
                    exit(true);
                end;
            else
                exit(false);
        end;
    end;

    local procedure GetFieldValue(MiniFormLine: Record "Miniform Line"): Text[250]
    var
        "Field": Record "Field";
        FldRef: FieldRef;
    begin
        if (MiniFormLine."Table No." = 0) or (MiniFormLine."Field No." = 0) then
            exit(MiniFormLine.Text);

        Field.Get(MiniFormLine."Table No.", MiniFormLine."Field No.");

        if RecRefRunning then begin
            FldRef := RecRef.Field(MiniFormLine."Field No.");
            if Field.Class = Field.Class::FlowField then
                FldRef.CalcField();

            exit(Format(FldRef));
        end;
        exit('');
    end;

    [Scope('OnPrem')]
    procedure FieldSetvalue(var NewRecRef: RecordRef; FldNo: Integer; Text: Text[80]): Boolean
    var
        FldRef: FieldRef;
    begin
        FldRef := NewRecRef.Field(FldNo);

        if not FieldHandleEvaluate(FldRef, Text) then
            Error(Text003, Text, FldRef.Caption);

        FldRef.Validate();
        exit(true);
    end;

    local procedure FieldHandleEvaluate(var FldRef: FieldRef; Text: Text[250]): Boolean
    var
        "Field": Record "Field";
        DateFormula: DateFormula;
        RecordRef: RecordRef;
        OptionNo: Option;
        OptionString: Text[1024];
        CurrOptionString: Text[1024];
        Date: Date;
        DateTime: DateTime;
        "Integer": Integer;
        BigInteger: BigInteger;
        Duration: Duration;
        Decimal: Decimal;
        "Code": Code[250];
        Boolean: Boolean;
    begin
        if Text = '' then
            exit(true);

        case FldRef.Type of
            FieldType::Option:
                begin
                    if Text = '' then begin
                        FldRef.Value := 0;
                        exit(true);
                    end;
                    OptionString := FldRef.OptionCaption;
                    while OptionString <> '' do begin
                        if StrPos(OptionString, ',') = 0 then begin
                            CurrOptionString := OptionString;
                            OptionString := '';
                        end else begin
                            CurrOptionString := CopyStr(OptionString, 1, StrPos(OptionString, ',') - 1);
                            OptionString := CopyStr(OptionString, StrPos(OptionString, ',') + 1);
                        end;
                        if Text = CurrOptionString then begin
                            FldRef.Value := OptionNo;
                            exit(true);
                        end;
                        OptionNo := OptionNo + 1;
                    end;
                end;
            FieldType::Text:
                begin
                    RecordRef := FldRef.Record();
                    if StrLen(Text) > FldRef.Length then
                        Error(Text004, FldRef.Record().Caption(), FldRef.Caption, FldRef.Length, Text);
                    FldRef.Value := Text;
                    exit(true);
                end;
            FieldType::Code:
                begin
                    Code := Text;
                    RecordRef := FldRef.Record();
                    if StrLen(Code) > FldRef.Length then
                        Error(Text004, FldRef.Record().Caption(), FldRef.Caption, FldRef.Length, Code);
                    FldRef.Value := Code;
                    exit(true);
                end;
            FieldType::Date:
                begin
                    if Text <> '' then begin
                        Evaluate(Date, Text);
                        FldRef.Value := Date;
                    end;
                    exit(true);
                end;
            FieldType::DateTime:
                begin
                    Evaluate(DateTime, Text);
                    FldRef.Value := DateTime;
                    exit(true);
                end;
            FieldType::Integer:
                begin
                    Evaluate(Integer, Text);
                    FldRef.Value := Integer;
                    exit(true);
                end;
            FieldType::BigInteger:
                begin
                    Evaluate(BigInteger, Text);
                    FldRef.Value := BigInteger;
                    exit(true);
                end;
            FieldType::Duration:
                begin
                    Evaluate(Duration, Text);
                    FldRef.Value := Duration;
                    exit(true);
                end;
            FieldType::Decimal:
                begin
                    Evaluate(Decimal, Text);
                    FldRef.Value := Decimal;
                    exit(true);
                end;
            FieldType::DateFormula:
                begin
                    Evaluate(DateFormula, Text);
                    FldRef.Value := DateFormula;
                    exit(true);
                end;
            FieldType::Boolean:
                begin
                    Evaluate(Boolean, Text);
                    FldRef.Value := Boolean;
                    exit(true);
                end;
            FieldType::BLOB:
                begin
                    Field.Get(FldRef.Record().Number, FldRef.Number);
                    Field.FieldError(Type);
                end;
            else begin
                Field.Get(FldRef.Record().Number, FldRef.Number);
                Field.FieldError(Type);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetXMLDOMS(var oXMLDOM: DotNet XmlDocument)
    begin
        XMLDOM := oXMLDOM;
    end;

    [Scope('OnPrem')]
    procedure GetReturnXML(var xmlout: DotNet XmlDocument)
    begin
        xmlout := XMLDOM;
    end;

    [Scope('OnPrem')]
    procedure GetNodeAttribute(CurrNode: DotNet XmlNode; AttributeName: Text[250]) AttribValue: Text[250]
    var
        oTempNode: DotNet XmlNode;
        NodeAttributes: DotNet XmlNamedNodeMap;
    begin
        NodeAttributes := CurrNode.Attributes;
        oTempNode := NodeAttributes.GetNamedItem(AttributeName);

        if not IsNull(oTempNode) then
            AttribValue := oTempNode.Value
        else
            AttribValue := '';
    end;

    [Scope('OnPrem')]
    procedure SetNodeAttribute(CurrNode: DotNet XmlNode; AttributeName: Text[250]; AttribValue: Text[250])
    var
        oTempNode: DotNet XmlNode;
        NodeAttributes: DotNet XmlNamedNodeMap;
    begin
        NodeAttributes := CurrNode.Attributes;
        oTempNode := NodeAttributes.GetNamedItem(AttributeName);
        oTempNode.Value := AttribValue;
    end;

    procedure SetUserNo(uNo: Text[250])
    begin
        ADCSUser.Get(uNo)
    end;

    procedure GetWhseEmployee(ADCSLoginId: Text[250]; var WhseEmpId: Text[250]; var LocationFilter: Text[250]): Boolean
    var
        WhseEmployee: Record "Warehouse Employee";
        ADCSUserRec: Record "ADCS User";
    begin
        if ADCSLoginId <> '' then begin
            WhseEmpId := '';
            LocationFilter := '';

            if not ADCSUserRec.Get(ADCSLoginId) then
                exit(false);

            WhseEmployee.SetRange("ADCS User", ADCSUserRec.Name);
            if not WhseEmployee.Find('-') then
                exit(false);

            WhseEmpId := WhseEmployee."User ID";
            repeat
                LocationFilter := LocationFilter + WhseEmployee."Location Code" + '|';
            until WhseEmployee.Next() = 0;
            LocationFilter := CopyStr(LocationFilter, 1, (StrLen(LocationFilter) - 1));
            exit(true);
        end;
        exit(false);
    end;

    procedure GetNextMiniForm(ActualMiniFormHeader: Record "Miniform Header"; var MiniformHeader2: Record "Miniform Header")
    begin
        if not MiniformHeader2.Get(ActualMiniFormHeader."Next Miniform") then
            Error(Text005, ActualMiniFormHeader.Code);
    end;

    procedure GetCallMiniForm(MiniFormCode: Code[20]; var MiniformHeader2: Record "Miniform Header"; ReturnTextValue: Text[250])
    var
        MiniformLine: Record "Miniform Line";
    begin
        MiniformLine.Reset();
        MiniformLine.SetRange("Miniform Code", MiniFormCode);
        MiniformLine.SetRange(Text, ReturnTextValue);
        MiniformLine.FindFirst();
        MiniformLine.TestField("Call Miniform");
        MiniformHeader2.Get(MiniformLine."Call Miniform");
    end;

    [Scope('OnPrem')]
    procedure RunPreviousMiniform(var DOMxmlin: DotNet XmlDocument)
    var
        MiniformHeader2: Record "Miniform Header";
        PreviousCode: Text[20];
    begin
        DecreaseStack(DOMxmlin, PreviousCode);
        MiniformHeader2.Get(PreviousCode);
        MiniformHeader2.SaveXMLin(DOMxmlin);
        CODEUNIT.Run(MiniformHeader2."Handling Codeunit", MiniformHeader2);
    end;

    [Scope('OnPrem')]
    procedure IncreaseStack(var DOMxmlin: DotNet XmlDocument; NextElement: Text[250])
    var
        ReturnedNode: DotNet XmlNode;
        RootNode: DotNet XmlNode;
        StackCode: Text[250];
    begin
        RootNode := DOMxmlin.DocumentElement;
        XMLDOMMgt.FindNode(RootNode, 'Header', ReturnedNode);
        StackCode := GetNodeAttribute(ReturnedNode, 'StackCode');

        if StackCode = '' then
            StackCode := NextElement
        else
            StackCode := StrSubstNo('%1|%2', StackCode, NextElement);

        SetNodeAttribute(ReturnedNode, 'StackCode', StackCode);
        SetNodeAttribute(ReturnedNode, 'RunReturn', '0');
    end;

    [Scope('OnPrem')]
    procedure DecreaseStack(var DOMxmlin: DotNet XmlDocument; var PreviousElement: Text[250])
    var
        ReturnedNode: DotNet XmlNode;
        RootNode: DotNet XmlNode;
        StackCode: Text[250];
        p: Integer;
        pos: Integer;
    begin
        RootNode := DOMxmlin.DocumentElement;
        XMLDOMMgt.FindNode(RootNode, 'Header', ReturnedNode);
        StackCode := GetNodeAttribute(ReturnedNode, 'StackCode');

        if StackCode = '' then begin
            PreviousElement := GetNodeAttribute(ReturnedNode, 'UseCaseCode');
            exit;
        end;

        for p := StrLen(StackCode) downto 1 do
            if StackCode[p] = '|' then begin
                pos := p;
                p := 1;
            end;

        if pos > 1 then begin
            PreviousElement := CopyStr(StackCode, pos + 1, StrLen(StackCode) - pos);
            StackCode := CopyStr(StackCode, 1, pos - 1);
        end else begin
            PreviousElement := StackCode;
            StackCode := '';
        end;

        SetNodeAttribute(ReturnedNode, 'StackCode', StackCode);
        SetNodeAttribute(ReturnedNode, 'RunReturn', '1');
    end;

    procedure GetFunctionKey(MiniformCode: Code[20]; InputValue: Text[250]): Integer
    var
        MiniformFunction: Record "Miniform Function";
        MiniformFunctionGroup: Record "Miniform Function Group";
    begin
        if StrLen(InputValue) > MaxStrLen(MiniformFunctionGroup.Code) then
            exit(0);
        if MiniformFunctionGroup.Get(InputValue) then begin
            if not MiniformFunction.Get(MiniformCode, InputValue) then
                Error(Text007, InputValue);

            exit(MiniformFunctionGroup.KeyDef);
        end;
        exit(0);
    end;

    procedure GetActiveInputNo(MiniformCode: Code[20]; FieldID: Integer): Integer
    var
        MiniFormLine: Record "Miniform Line";
        CurrField: Integer;
    begin
        if FieldID = 0 then
            exit(1);

        MiniFormLine.SetRange("Miniform Code", MiniformCode);
        MiniFormLine.SetRange("Field Type", MiniFormLine."Field Type"::Input);
        if MiniFormLine.Find('-') then
            repeat
                CurrField += 1;
                if MiniFormLine."Field No." = FieldID then
                    exit(CurrField);
            until MiniFormLine.Next() = 0;

        exit(1);
    end;

    procedure LastEntryField(MiniformCode: Code[20]; FieldID: Integer): Boolean
    var
        MiniFormLine: Record "Miniform Line";
    begin
        if FieldID = 0 then
            exit(false);

        MiniFormLine.SetRange("Miniform Code", MiniformCode);
        MiniFormLine.SetFilter("Field Type", '%1|%2', MiniFormLine."Field Type"::Input, MiniFormLine."Field Type"::Asterisk);
        if MiniFormLine.FindLast() and (MiniFormLine."Field No." = FieldID) then
            exit(true);

        exit(false);
    end;

    procedure GetLoginFormCode(): Code[20]
    var
        MiniformHeader: Record "Miniform Header";
    begin
        MiniformHeader.SetRange("Start Miniform", true);
        if MiniformHeader.FindFirst() then
            exit(MiniformHeader.Code);
        Error(Text006, MiniformHeader.FieldCaption("Start Miniform"));
    end;
}

